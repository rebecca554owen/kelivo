import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../../core/database/chat_database_repository.dart';
import '../../../core/models/assistant.dart';
import '../../../core/models/chat_input_data.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/conversation.dart';
import '../../../core/models/instruction_injection.dart';
import '../../../core/models/memory_entry.dart';
import '../../../core/models/world_book.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/chat/chat_service.dart';
import '../../../core/services/chat/document_text_extractor.dart';
import '../../../core/services/chat/prompt_transformer.dart';
import '../../../core/services/memory/memory_block_builder.dart';
import '../../../core/services/memory/memory_prompts.dart';
import '../../../core/services/search/search_tool_service.dart';
import '../../../core/providers/instruction_injection_provider.dart';
import '../../../core/providers/world_book_provider.dart';
import '../../../core/services/api/builtin_tools.dart';
import '../../../core/models/assistant_regex.dart';
import '../../../core/utils/multimodal_input_utils.dart';
import '../../../utils/assistant_regex.dart';
import '../../../utils/markdown_media_sanitizer.dart';
import 'ocr_service.dart';

/// Result of §7.6 memory-prefix resolution.
typedef MemoryPrefixResolution = ({String prefix, String? hash});

/// Service for building API messages from conversation state.
///
/// This service handles:
/// - Building API messages list from chat history
/// - Processing user messages (documents, OCR, templates)
/// - Injecting system prompts
/// - Injecting memory and recent chats context
/// - Injecting search prompts
/// - Injecting instruction prompts
/// - Applying context limits
/// - Inlining local images for model context
class MessageBuilderService {
  static const String internalMediaPathsKey = multimodalInternalMediaPathsKey;
  static const String internalRevisionIdKey = multimodalInternalRevisionIdKey;

  MessageBuilderService({
    required this.chatService,
    required this.contextProvider,
    this.chatRepository,
    this.ocrHandler,
    this.ocrPrefetch,
    this.geminiThoughtSignatureHandler,
  });

  final ChatService chatService;

  /// Optional override for `promptContent` freeze and §7.6 injection.
  /// When null, falls back to [ChatService.chatRepositoryOrNull].
  final ChatDatabaseRepository? chatRepository;

  ChatDatabaseRepository? get _repo =>
      chatRepository ?? chatService.chatRepositoryOrNull;

  /// Build context (used for accessing providers via context.read)
  final BuildContext contextProvider;

  /// OCR handler for processing images (optional, injected from home_page)
  final Future<String?> Function(
    List<String> imagePaths, {
    String? revisionId,
    OcrPrepareSession? session,
  })?
  ocrHandler;

  /// Optional batch prefetch of persisted OCR before per-message processing.
  final Future<OcrPrepareSession> Function({
    required List<String> revisionIds,
    required List<String> imagePaths,
  })?
  ocrPrefetch;

  /// OCR text wrapper function
  String Function(String ocrText)? ocrTextWrapper;

  /// Handler to append Gemini thought signatures for API calls
  final String Function(ChatMessage message, String content)?
  geminiThoughtSignatureHandler;

  /// Cache for document text extraction to avoid re-reading files on every message
  /// Keyed by path, validated with (modified + size) to avoid stale reuse.
  final Map<String, _DocTextCacheEntry> _docTextCache =
      <String, _DocTextCacheEntry>{};

  /// Collapse message versions to show only selected version per group.
  List<ChatMessage> collapseVersions(
    List<ChatMessage> items,
    Map<String, int> versionSelections,
  ) {
    final Map<String, List<ChatMessage>> byGroup =
        <String, List<ChatMessage>>{};
    final List<String> order = <String>[];

    for (final m in items) {
      final gid = (m.groupId ?? m.id);
      final list = byGroup.putIfAbsent(gid, () {
        order.add(gid);
        return <ChatMessage>[];
      });
      list.add(m);
    }

    // Sort each group by version
    for (final e in byGroup.entries) {
      e.value.sort((a, b) => a.version.compareTo(b.version));
    }

    // Select the appropriate version from each group
    final out = <ChatMessage>[];
    for (final gid in order) {
      final vers = byGroup[gid]!;
      final sel = versionSelections[gid];
      ChatMessage? selected;
      if (sel != null) {
        for (final candidate in vers) {
          if (candidate.version == sel) {
            selected = candidate;
            break;
          }
        }
      }
      out.add(selected ?? vers.last);
    }

    return out;
  }

  /// Build API messages list from current conversation state.
  ///
  /// Applies truncation, version collapsing, and strips [image:] / [file:] markers.
  List<Map<String, dynamic>> buildApiMessages({
    required List<ChatMessage> messages,
    required Map<String, int> versionSelections,
    required Conversation? currentConversation,
    bool includeToolMessages = false,
  }) {
    final tIndex = currentConversation?.truncateIndex ?? -1;
    final List<ChatMessage> sourceAll =
        (tIndex >= 0 && tIndex <= messages.length)
        ? messages.sublist(tIndex)
        : List.of(messages);
    final List<ChatMessage> source = collapseVersions(
      sourceAll,
      versionSelections,
    );

    final out = <Map<String, dynamic>>[];

    for (final m in source) {
      String? toolContinuationReasoningContent;
      dynamic reasoningDetails;
      if (m.role == 'assistant') {
        reasoningDetails = _reasoningDetailsForApi(m);
      }
      if (includeToolMessages && m.role == 'assistant') {
        final events = chatService.getToolEvents(m.id);
        if (events.isNotEmpty) {
          // Tool-call history is only valid once every call has a result.
          final hasPendingToolEvent = events.any((e) => e['content'] == null);
          if (!hasPendingToolEvent) {
            toolContinuationReasoningContent =
                _reasoningContentForToolContinuation(m);
            final calls = <Map<String, dynamic>>[];
            final toolMessages = <Map<String, dynamic>>[];

            for (int i = 0; i < events.length; i++) {
              final e = events[i];
              final name = (e['name'] ?? '').toString().trim();
              if (name.isEmpty) continue;
              final rawId = (e['id'] ?? '').toString().trim();
              final id = rawId.isNotEmpty
                  ? rawId
                  : 'call_${m.id.substring(0, m.id.length < 8 ? m.id.length : 8)}_$i';

              Map<String, dynamic> args = const <String, dynamic>{};
              final a = e['arguments'];
              if (a is Map) {
                args = a.map((k, v) => MapEntry(k.toString(), v));
              }
              String argumentsJson = '{}';
              try {
                argumentsJson = jsonEncode(args);
              } catch (_) {}

              calls.add({
                'id': id,
                'type': 'function',
                'function': {'name': name, 'arguments': argumentsJson},
                if (e['metadata'] is Map)
                  'metadata': (e['metadata'] as Map).cast<String, dynamic>(),
              });

              final c = e['content'];
              toolMessages.add({
                'role': 'tool',
                'name': name,
                'tool_call_id': id,
                'content': c.toString(),
                if (e['metadata'] is Map)
                  'metadata': (e['metadata'] as Map).cast<String, dynamic>(),
              });
            }

            if (calls.isNotEmpty) {
              final assistantToolMessage = <String, dynamic>{
                'role': 'assistant',
                'content': '\n\n',
                'tool_calls': calls,
              };
              if (toolContinuationReasoningContent.isNotEmpty) {
                assistantToolMessage['reasoning_content'] =
                    toolContinuationReasoningContent;
              }
              // The persisted reasoning_details belong to the final round of
              // this message; attaching them to this synthetic pre-tool
              // assistant message as well would replay the same reasoning
              // twice, which OpenRouter/Anthropic reject. Only the final
              // assistant message below carries them.
              out.add(assistantToolMessage);
              out.addAll(toolMessages);
            }
          }
        }
      }

      var content = m.content;
      if (m.role == 'assistant' && geminiThoughtSignatureHandler != null) {
        content = geminiThoughtSignatureHandler!(m, content);
      }
      if (content.isEmpty) continue;
      final role = m.role == 'assistant' ? 'assistant' : 'user';
      final message = <String, dynamic>{'role': role, 'content': content};
      if (role == 'user') {
        message[internalRevisionIdKey] = m.id;
      }
      if (toolContinuationReasoningContent?.isNotEmpty == true) {
        message['reasoning_content'] = toolContinuationReasoningContent;
      }
      if (reasoningDetails != null) {
        message['reasoning_details'] = reasoningDetails;
      }
      out.add(message);
    }

    return out;
  }

  /// Remove internal user revision IDs before provider requests.
  void stripInternalRevisionIds(List<Map<String, dynamic>> apiMessages) {
    for (final message in apiMessages) {
      message.remove(internalRevisionIdKey);
    }
  }

  ChatMessage? _latestPersistedMessage(ChatMessage message) {
    final persisted = chatService.getMessages(message.conversationId);
    for (final candidate in persisted) {
      if (candidate.id == message.id) return candidate;
    }
    return null;
  }

  String _reasoningContentForToolContinuation(ChatMessage message) {
    String pick(ChatMessage candidate) {
      final direct = (candidate.reasoningText ?? '').trim();
      if (direct.isNotEmpty) return direct;

      final raw = (candidate.reasoningSegmentsJson ?? '').trim();
      if (raw.isEmpty) return '';
      try {
        final decoded = jsonDecode(raw);
        final segmentsRaw = switch (decoded) {
          Map<String, dynamic> map => map['segments'],
          List<dynamic> list => list,
          _ => null,
        };
        if (segmentsRaw is! List) return '';
        final parts = <String>[];
        for (final item in segmentsRaw) {
          if (item is! Map) continue;
          final text = (item['text'] ?? '').toString().trim();
          if (text.isNotEmpty) parts.add(text);
        }
        return parts.join('\n').trim();
      } catch (_) {
        return '';
      }
    }

    final fromMessage = pick(message);
    if (fromMessage.isNotEmpty) return fromMessage;

    final persisted = _latestPersistedMessage(message);
    if (persisted == null) return '';
    return pick(persisted);
  }

  /// Extract persisted vendor reasoning details (OpenRouter-style
  /// `reasoning_details`, may carry thinking signatures) so they can be
  /// echoed back to the provider on later turns.
  dynamic _reasoningDetailsForApi(ChatMessage message) {
    dynamic pick(ChatMessage candidate) {
      final raw = (candidate.reasoningSegmentsJson ?? '').trim();
      if (raw.isEmpty) return null;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return null;
        final details = decoded['reasoningDetails'];
        if (details is List && details.isNotEmpty) return details;
      } catch (_) {}
      return null;
    }

    final fromMessage = pick(message);
    if (fromMessage != null) return fromMessage;

    final persisted = _latestPersistedMessage(message);
    if (persisted == null) return null;
    return pick(persisted);
  }

  /// Parse input data from raw message content (extracts images and documents).
  ChatInputData parseInputFromRaw(
    String raw, {
    bool includeMediaFilePathsAsImages = true,
  }) {
    final imgRe = RegExp(r"\[image:(.+?)\]");
    final fileRe = RegExp(r"\[file:(.+?)\|(.+?)\|(.+?)\]");
    final images = <String>[];
    final docs = <DocumentAttachment>[];
    final buffer = StringBuffer();
    int idx = 0;
    while (idx < raw.length) {
      final imgMatch = imgRe.matchAsPrefix(raw, idx);
      final fileMatch = fileRe.matchAsPrefix(raw, idx);
      if (imgMatch != null) {
        final p = imgMatch.group(1)?.trim();
        if (p != null && p.isNotEmpty) images.add(p);
        idx = imgMatch.end;
        continue;
      }
      if (fileMatch != null) {
        final path = fileMatch.group(1)?.trim() ?? '';
        final name = fileMatch.group(2)?.trim() ?? 'file';
        final mime = fileMatch.group(3)?.trim() ?? 'text/plain';
        final doc = DocumentAttachment(path: path, fileName: name, mime: mime);
        docs.add(doc);
        // Treat media attachments as image-style attachments for downstream API builders.
        final effectiveMime = _effectiveAttachmentMime(doc);
        if (includeMediaFilePathsAsImages &&
            (isVideoMime(effectiveMime) || isAudioMime(effectiveMime)) &&
            path.isNotEmpty) {
          images.add(path);
        }
        idx = fileMatch.end;
        continue;
      }
      buffer.write(raw[idx]);
      idx++;
    }
    return ChatInputData(
      text: buffer.toString().trim(),
      imagePaths: images,
      documents: docs,
    );
  }

  String _effectiveAttachmentMime(DocumentAttachment attachment) {
    return resolveDocumentAttachmentMime(attachment);
  }

  /// Process user messages in apiMessages: prefer frozen `promptContent`, else
  /// assemble (docs/OCR → memory prefix → template → time) and freeze (§8).
  ///
  /// Returns the image paths from the last user message (for API call).
  Future<List<String>> processUserMessagesForApi(
    List<Map<String, dynamic>> apiMessages,
    SettingsProvider settings,
    Assistant? assistant, {
    Conversation? conversation,
    List<ChatMessage>? sourceMessages,
  }) async {
    final bool ocrActive =
        settings.ocrEnabled &&
        settings.ocrModelProvider != null &&
        settings.ocrModelId != null;

    List<String>? lastUserImagePaths;

    // Only real persisted user messages carry an internal revision ID.
    // WorldBook lore may also use role=user and must not be treated as chat input.
    bool isPersistedUserMessage(Map<String, dynamic> message) {
      if (message['role'] != 'user') return false;
      return (message[internalRevisionIdKey] ?? '')
          .toString()
          .trim()
          .isNotEmpty;
    }

    // Find last real user message index (skip injected lore).
    int lastUserIdx = -1;
    for (int i = apiMessages.length - 1; i >= 0; i--) {
      if (isPersistedUserMessage(apiMessages[i])) {
        lastUserIdx = i;
        break;
      }
    }

    // Prefetch OCR only for messages that still need generation (no freeze yet).
    OcrPrepareSession? ocrSession;
    if (ocrActive && ocrPrefetch != null) {
      final revisionIds = <String>[];
      final allImagePaths = <String>{};
      for (final message in apiMessages) {
        if (!isPersistedUserMessage(message)) continue;
        final revisionId = (message[internalRevisionIdKey] ?? '')
            .toString()
            .trim();
        if (revisionId.isNotEmpty && _repo != null) {
          final existing = await _repo!.getMessagePrompt(revisionId);
          if (existing != null) continue;
        }
        final parsedUser = parseInputFromRaw(
          (message['content'] ?? '').toString(),
        );
        final videoPaths = <String>{
          for (final d in parsedUser.documents)
            if (isVideoMime(_effectiveAttachmentMime(d))) d.path.trim(),
        }..removeWhere((p) => p.isEmpty);
        final audioPaths = <String>{
          for (final d in parsedUser.documents)
            if (isAudioMime(_effectiveAttachmentMime(d))) d.path.trim(),
        }..removeWhere((p) => p.isEmpty);
        final ocrTargets = parsedUser.imagePaths
            .map((p) => p.trim())
            .where(
              (p) =>
                  p.isNotEmpty &&
                  !videoPaths.contains(p) &&
                  !audioPaths.contains(p),
            )
            .toSet();
        if (ocrTargets.isEmpty) continue;
        if (revisionId.isNotEmpty) revisionIds.add(revisionId);
        allImagePaths.addAll(ocrTargets);
      }
      if (allImagePaths.isNotEmpty) {
        try {
          ocrSession = await ocrPrefetch!(
            revisionIds: revisionIds,
            imagePaths: allImagePaths.toList(growable: false),
          );
        } catch (_) {
          ocrSession = null;
        }
      }
    }

    Future<String?> readDocument(DocumentAttachment d) async {
      // Use file stat to detect content changes without hashing.
      FileStat? stat;
      try {
        stat = await File(d.path).stat();
      } catch (_) {
        stat = null;
      }
      if (stat != null) {
        final cached = _docTextCache[d.path];
        if (cached != null &&
            cached.modifiedMs == stat.modified.millisecondsSinceEpoch &&
            cached.size == stat.size) {
          return cached.text;
        }
      }
      try {
        final text = await DocumentTextExtractor.extract(
          path: d.path,
          mime: d.mime,
        );
        // Cache only when stat is available; otherwise avoid staleness.
        if (stat != null) {
          _docTextCache[d.path] = _DocTextCacheEntry(
            text: text,
            modifiedMs: stat.modified.millisecondsSinceEpoch,
            size: stat.size,
          );
        }
        return text;
      } catch (_) {
        if (stat != null) {
          _docTextCache[d.path] = _DocTextCacheEntry(
            text: null,
            modifiedMs: stat.modified.millisecondsSinceEpoch,
            size: stat.size,
          );
        }
        return null;
      }
    }

    // Revision ids that received a snapshot during this very pass. Reading it
    // back from message_prompt_rows would work for persisted conversations but
    // not for temporary ones, which never get a row.
    final snapshotCarriersThisPass = <String>{};

    for (int i = 0; i < apiMessages.length; i++) {
      if (!isPersistedUserMessage(apiMessages[i])) continue;
      final revisionId = (apiMessages[i][internalRevisionIdKey] ?? '')
          .toString()
          .trim();
      final rawUser = (apiMessages[i]['content'] ?? '').toString();
      final parsedUser = parseInputFromRaw(rawUser);
      final videoPaths = <String>{
        for (final d in parsedUser.documents)
          if (isVideoMime(_effectiveAttachmentMime(d))) d.path.trim(),
      }..removeWhere((p) => p.isEmpty);
      final audioPaths = <String>{
        for (final d in parsedUser.documents)
          if (isAudioMime(_effectiveAttachmentMime(d))) d.path.trim(),
      }..removeWhere((p) => p.isEmpty);

      final messageMediaPaths = parsedUser.imagePaths
          .map((p) => p.trim())
          .where(
            (p) =>
                p.isNotEmpty &&
                (!ocrActive ||
                    videoPaths.contains(p) ||
                    audioPaths.contains(p)),
          )
          .toSet()
          .toList(growable: false);
      if (messageMediaPaths.isEmpty) {
        apiMessages[i].remove(internalMediaPathsKey);
      } else {
        apiMessages[i][internalMediaPathsKey] = messageMediaPaths;
      }

      // Capture image paths from last user message (from raw markers).
      if (i == lastUserIdx &&
          lastUserImagePaths == null &&
          parsedUser.imagePaths.isNotEmpty) {
        lastUserImagePaths = List<String>.of(parsedUser.imagePaths);
      }

      // Prefer frozen promptContent — never recompute (§8.3).
      if (revisionId.isNotEmpty && _repo != null) {
        final existing = await _repo!.getMessagePrompt(revisionId);
        if (existing != null) {
          apiMessages[i]['content'] = existing.payload;
          continue;
        }
      }

      final inlineImagePaths = parsedUser.imagePaths
          .map((p) => p.trim())
          .where(
            (p) =>
                p.isNotEmpty &&
                !videoPaths.contains(p) &&
                !audioPaths.contains(p),
          )
          .toList(growable: false);

      // Apply replace-only regexes at send-time on user text (exclude markers).
      final replacedUserText = applyAssistantRegexes(
        parsedUser.text,
        assistant: assistant,
        scope: AssistantRegexScope.user,
        target: AssistantRegexTransformTarget.send,
      );

      final imageMarkers = (!ocrActive && inlineImagePaths.isNotEmpty)
          ? inlineImagePaths.map((p) => '\n[image:$p]').join()
          : '';
      final cleanedUser = (replacedUserText + imageMarkers).trim();

      final filePrompts = StringBuffer();
      for (final d in parsedUser.documents) {
        final effectiveMime = _effectiveAttachmentMime(d);
        if (isVideoMime(effectiveMime) || isAudioMime(effectiveMime)) {
          continue;
        }
        final text = await readDocument(d);
        if (text == null || text.trim().isEmpty) continue;
        filePrompts.writeln('## user sent a file: ${d.fileName}');
        filePrompts.writeln('<content>');
        filePrompts.writeln('```');
        filePrompts.writeln(text);
        filePrompts.writeln('```');
        filePrompts.writeln('</content>');
        filePrompts.writeln();
      }

      String merged = (filePrompts.toString() + cleanedUser).trim();

      if (ocrActive && ocrHandler != null) {
        final ocrTargets = parsedUser.imagePaths
            .map((p) => p.trim())
            .where(
              (p) =>
                  p.isNotEmpty &&
                  !videoPaths.contains(p) &&
                  !audioPaths.contains(p),
            )
            .toSet()
            .toList();
        if (ocrTargets.isNotEmpty) {
          final ocrText = await ocrHandler!(
            ocrTargets,
            revisionId: revisionId.isEmpty ? null : revisionId,
            session: ocrSession,
          );
          if (ocrText != null && ocrText.trim().isNotEmpty) {
            final wrapped = ocrTextWrapper != null
                ? ocrTextWrapper!(ocrText)
                : _defaultWrapOcrBlock(ocrText);
            merged = (wrapped + merged).trim();
          }
        }
      }

      final processedBody = merged.isEmpty ? cleanedUser : merged;
      final chatMessage = _resolveChatMessage(
        revisionId: revisionId,
        conversation: conversation,
        sourceMessages: sourceMessages,
      );

      if (conversation != null && chatMessage != null) {
        apiMessages[i]['content'] = await resolvePromptContent(
          message: chatMessage,
          processedUserBody: processedBody,
          assistant: assistant,
          conversation: conversation,
          settings: settings,
          apiMessages: apiMessages,
          snapshotCarriers: snapshotCarriersThisPass,
        );
      } else {
        // No conversation or no matching stored message: nothing to freeze
        // against, so render the template without a memory prefix.
        final templ =
            (assistant?.messageTemplate ?? '{{ message }}').trim().isEmpty
            ? '{{ message }}'
            : (assistant?.messageTemplate ?? '{{ message }}');
        final now = chatMessage?.timestamp ?? DateTime.now();
        var content = PromptTransformer.applyMessageTemplate(
          templ,
          role: 'user',
          message: processedBody,
          now: now,
        );
        if (assistant?.appendCurrentTimeToUserMessage == true) {
          content = '$content\n\n${MemoryPrompts.formatCurrentTimeTag(now)}';
        }
        apiMessages[i]['content'] = content;
      }
    }

    return lastUserImagePaths ?? <String>[];
  }

  /// The stored message behind an api payload, or null when it cannot be
  /// found.
  ///
  /// [sourceMessages] is the list this request's api payloads were built from
  /// and is checked first. `ChatService.getMessages` only serves conversations
  /// already in its cache, so on a freshly created conversation it returns
  /// nothing and the new message would silently skip memory injection and
  /// freezing — then pick both up a turn later, rewriting history and losing
  /// the prompt cache.
  ///
  /// A synthesized stand-in would have to invent a timestamp, and freezing that
  /// would bake the wrong `{{ time }}` into the prompt forever, so a genuine
  /// miss returns null and stays on the unfrozen render path.
  ChatMessage? _resolveChatMessage({
    required String revisionId,
    required Conversation? conversation,
    required List<ChatMessage>? sourceMessages,
  }) {
    if (revisionId.isEmpty || conversation == null) return null;
    if (sourceMessages != null) {
      for (final candidate in sourceMessages) {
        if (candidate.id == revisionId) return candidate;
      }
    }
    for (final candidate in chatService.getMessages(conversation.id)) {
      if (candidate.id == revisionId) return candidate;
    }
    return null;
  }

  /// §8.3 immutability contract: return frozen payload or assemble + freeze.
  Future<String> resolvePromptContent({
    required ChatMessage message,
    required String processedUserBody,
    required Assistant? assistant,
    required Conversation conversation,
    required SettingsProvider settings,
    required List<Map<String, dynamic>> apiMessages,
    Set<String>? snapshotCarriers,
  }) async {
    final repo = _repo;
    final persist =
        repo != null &&
        !chatService.isTemporaryConversation(message.conversationId);
    if (persist) {
      final existing = await repo.getMessagePrompt(message.id);
      if (existing != null) return existing.payload;
    }

    final memory = assistant == null
        ? (prefix: '', hash: null)
        : await resolveMemoryPrefix(
            conversation: conversation,
            assistant: assistant,
            apiMessages: apiMessages,
            currentMessageId: message.id,
            lang: settings.resolvedMemoryPromptLang,
            snapshotCarriers: snapshotCarriers,
          );
    if (memory.prefix.isNotEmpty) {
      snapshotCarriers?.add(message.id);
    }

    final templ = (assistant?.messageTemplate ?? '{{ message }}').trim().isEmpty
        ? '{{ message }}'
        : (assistant!.messageTemplate);
    final templated = PromptTransformer.applyMessageTemplate(
      templ,
      role: 'user',
      message: processedUserBody,
      now: message.timestamp,
    );
    final timeSuffix = (assistant?.appendCurrentTimeToUserMessage ?? false)
        ? '\n\n${MemoryPrompts.formatCurrentTimeTag(message.timestamp)}'
        : '';
    final finalContent = '${memory.prefix}$templated$timeSuffix';

    // Temporary drafts never land in message_rows; freezing would violate the
    // message_prompt_rows FK. Assemble in-memory only for those.
    if (persist) {
      await repo.freezeMessagePrompt(
        revisionId: message.id,
        conversationId: message.conversationId,
        payload: finalContent,
        carriesMemorySnapshot: memory.prefix.isNotEmpty,
        injectedMemoryHash: memory.hash,
      );
    }

    return finalContent;
  }

  /// §7.6 hash gating + self-healing. Compare hash **before** writing it.
  Future<MemoryPrefixResolution> resolveMemoryPrefix({
    required Conversation conversation,
    required Assistant assistant,
    required List<Map<String, dynamic>> apiMessages,
    required String currentMessageId,
    required MemoryPromptLang lang,
    Set<String>? snapshotCarriers,
  }) async {
    if (!assistant.enableMemory) {
      return (prefix: '', hash: null);
    }

    final repo = _repo;
    if (repo == null) {
      return (prefix: '', hash: null);
    }

    final fields = await repo.readProfileFields();
    final totalByType = await repo.countVisibleMemoriesByType(
      assistantId: assistant.id,
    );
    final hasAnyMemory = totalByType.values.any((count) => count > 0);
    final hasProfile = fields.any((f) => f.value.trim().isNotEmpty);

    // Fully empty: inject nothing and do not write hash.
    if (!hasProfile && !hasAnyMemory) {
      return (prefix: '', hash: null);
    }

    final visible = hasAnyMemory
        ? await repo.queryVisibleMemories(assistantId: assistant.id)
        : const <MemoryEntry>[];
    final profileBlock = MemoryBlockBuilder.buildProfileBlock(
      fields: fields,
      lang: lang,
    );
    final memoryBlock = MemoryBlockBuilder.buildMemoryBlock(
      visible: visible,
      totalByType: totalByType,
      lang: lang,
    );

    final currentHash = MemoryBlockBuilder.hashBlocks(
      profileBlock,
      memoryBlock,
    );

    // Self-healing: any history user message in *this* request carrying a
    // snapshot? Read revision ids before stripInternalRevisionIds; exclude
    // the message being assembled now.
    final historyUserIds = <String>[];
    for (final message in apiMessages) {
      if ((message['role'] ?? '').toString() != 'user') continue;
      final revisionId = (message[internalRevisionIdKey] ?? '')
          .toString()
          .trim();
      if (revisionId.isEmpty || revisionId == currentMessageId) continue;
      historyUserIds.add(revisionId);
    }
    final hasSnapshot =
        historyUserIds.any((id) => snapshotCarriers?.contains(id) ?? false) ||
        await repo.anyPromptCarriesMemorySnapshot(historyUserIds);

    // CRITICAL: compare against the prior hash BEFORE any write (appendix §6).
    // Writing first makes currentHash == injectedMemoryHash and the update
    // branch is permanently unreachable.
    //
    // Read from the database, not from [conversation]: callers hand us
    // `conversation.copyWith(...)` and nothing ever loads this column back into
    // the model, so the cached value is stale forever and every turn would look
    // like a change.
    final previousHash = await repo.getConversationInjectedMemoryHash(
      conversation.id,
    );

    final String prefix;
    if (!hasSnapshot) {
      prefix = MemoryBlockBuilder.buildFullSnapshotPrefix(
        profileBlock,
        memoryBlock,
        lang,
      );
    } else if (currentHash != previousHash) {
      prefix = MemoryBlockBuilder.buildUpdatePrefix(
        profileBlock,
        memoryBlock,
        lang,
      );
    } else {
      return (prefix: '', hash: null);
    }

    // The hash lands in the database through freezeMessagePrompt, in the same
    // transaction as the prompt row.
    return (prefix: prefix, hash: currentHash);
  }

  /// Default OCR text wrapper
  String _defaultWrapOcrBlock(String ocrText) {
    final buf = StringBuffer();
    buf.writeln(
      "The image_file_ocr tag contains a description of an image that the user uploaded to you, not the user's prompt.",
    );
    buf.writeln('<image_file_ocr>');
    buf.writeln(ocrText.trim());
    buf.writeln('</image_file_ocr>');
    buf.writeln();
    return buf.toString();
  }

  /// Inject system prompt into apiMessages.
  void injectSystemPrompt(
    List<Map<String, dynamic>> apiMessages,
    Assistant? assistant,
    String modelId,
  ) {
    if ((assistant?.systemPrompt.trim().isNotEmpty ?? false)) {
      final vars = PromptTransformer.buildPlaceholders(
        context: contextProvider,
        assistant: assistant!,
        modelId: modelId,
        modelName: modelId,
        userNickname: contextProvider.read<UserProvider>().name,
      );
      final sys = PromptTransformer.replacePlaceholders(
        assistant.systemPrompt,
        vars,
      );
      apiMessages.insert(0, {'role': 'system', 'content': sys});
    }
  }

  /// Inject §11 memory rules into the system message.
  ///
  /// Pure function of `(enableMemory, allowPastConversationRecall, lang,
  /// user template)` — must not vary with memory content or the clock (§11.1).
  /// Relative order among remaining system injections is preserved by the
  /// caller (`injectSystemPrompt` → this → `injectSearchPrompt` →
  /// `injectInstructionPrompts` → `injectWorldBookPrompts`).
  Future<void> injectMemoryAndRecentChats(
    List<Map<String, dynamic>> apiMessages,
    Assistant? assistant, {
    SettingsProvider? settings,
  }) async {
    try {
      if (assistant?.enableMemory != true) return;
      final resolved = settings ?? contextProvider.read<SettingsProvider>();
      final lang = resolved.resolvedMemoryPromptLang;
      final rules = lang == MemoryPromptLang.zh
          ? resolved.memoryRulesPromptZh
          : resolved.memoryRulesPromptEn;
      final buf = StringBuffer(rules.trim());
      if (assistant!.allowPastConversationRecall) {
        buf.write('\n\n');
        buf.write(MemoryPrompts.rulesPastConversationRecallFor(lang));
      }
      _appendToSystemMessage(apiMessages, buf.toString());
    } catch (_) {}
  }

  /// Inject search tool usage prompt into apiMessages.
  void injectSearchPrompt(
    List<Map<String, dynamic>> apiMessages,
    SettingsProvider settings,
    Assistant? assistant,
    bool hasBuiltInSearch,
  ) {
    if (assistant?.searchEnabled == true && !hasBuiltInSearch) {
      final prompt = SearchToolService.getSystemPrompt();
      _appendToSystemMessage(apiMessages, prompt);
    }
  }

  /// Inject instruction injection prompts into apiMessages.
  Future<void> injectInstructionPrompts(
    List<Map<String, dynamic>> apiMessages,
    String? assistantId,
  ) async {
    try {
      List<InstructionInjection> actives = const <InstructionInjection>[];
      try {
        final ip = contextProvider.read<InstructionInjectionProvider>();
        await ip.initialize();
        actives = ip.activesFor(assistantId);
      } catch (_) {}
      final prompts = actives
          .map((e) => e.prompt.trim())
          .where((p) => p.isNotEmpty)
          .toList(growable: false);
      if (prompts.isNotEmpty) {
        final lp = prompts.join('\n\n');
        _appendToSystemMessage(apiMessages, lp);
      }
    } catch (_) {}
  }

  /// Inject world book (lorebook) entries into apiMessages.
  Future<void> injectWorldBookPrompts(
    List<Map<String, dynamic>> apiMessages,
    String? assistantId,
  ) async {
    try {
      List<WorldBook> all = const <WorldBook>[];
      List<String> activeBookIds = const <String>[];

      try {
        final wb = contextProvider.read<WorldBookProvider>();
        await wb.initialize();
        all = wb.books;
        activeBookIds = wb.activeBookIdsFor(assistantId);
      } catch (_) {}

      if (all.isEmpty || activeBookIds.isEmpty) return;

      final activeSet = activeBookIds.toSet();
      final books = all
          .where((b) => b.enabled && activeSet.contains(b.id))
          .toList(growable: false);
      if (books.isEmpty) return;

      String extractContextForDepth(int scanDepth) {
        final depth = scanDepth <= 0 ? 1 : scanDepth;
        final parts = <String>[];
        for (
          int i = apiMessages.length - 1;
          i >= 0 && parts.length < depth;
          i--
        ) {
          final role = (apiMessages[i]['role'] ?? '').toString();
          if (role != 'user' && role != 'assistant') continue;
          final content = (apiMessages[i]['content'] ?? '').toString().trim();
          if (content.isEmpty) continue;
          parts.add(content);
        }
        return parts.reversed.join('\n');
      }

      bool isTriggered(WorldBookEntry entry, String context) {
        if (!entry.enabled) return false;
        if (entry.constantActive) return true;
        if (entry.keywords.isEmpty) return false;

        for (final raw in entry.keywords) {
          final keyword = raw.trim();
          if (keyword.isEmpty) continue;

          if (entry.useRegex) {
            try {
              final re = RegExp(keyword, caseSensitive: entry.caseSensitive);
              if (re.hasMatch(context)) return true;
            } catch (_) {}
          } else {
            if (entry.caseSensitive) {
              if (context.contains(keyword)) return true;
            } else {
              if (context.toLowerCase().contains(keyword.toLowerCase())) {
                return true;
              }
            }
          }
        }
        return false;
      }

      final contextCache = <int, String>{};
      final triggered = <({WorldBookEntry entry, int seq})>[];
      int seq = 0;

      for (final book in books) {
        for (final entry in book.entries) {
          final depth = (entry.scanDepth <= 0 ? 1 : entry.scanDepth)
              .clamp(1, 200)
              .toInt();
          final ctx = contextCache.putIfAbsent(
            depth,
            () => extractContextForDepth(depth),
          );
          if (isTriggered(entry, ctx)) {
            triggered.add((entry: entry, seq: seq));
          }
          seq++;
        }
      }

      if (triggered.isEmpty) return;

      triggered.sort((a, b) {
        final pa = a.entry.priority;
        final pb = b.entry.priority;
        if (pb != pa) return pb.compareTo(pa);
        return a.seq.compareTo(b.seq);
      });

      String wrapSystemTag(String content) => '<system>\n$content\n</system>';

      String joinContents(Iterable<WorldBookEntry> items) {
        return items
            .map((e) => e.content.trim())
            .where((c) => c.isNotEmpty)
            .join('\n');
      }

      List<Map<String, dynamic>> createMergedInjectionMessages(
        List<WorldBookEntry> injections,
      ) {
        final byRole = <WorldBookInjectionRole, List<WorldBookEntry>>{};
        for (final e in injections) {
          if (e.content.trim().isEmpty) continue;
          byRole.putIfAbsent(e.role, () => <WorldBookEntry>[]).add(e);
        }

        final result = <Map<String, dynamic>>[];
        for (final role in byRole.keys) {
          final group = byRole[role]!;
          final merged = joinContents(group);
          if (merged.isEmpty) continue;
          if (role == WorldBookInjectionRole.assistant) {
            result.add({'role': 'assistant', 'content': merged});
          } else {
            result.add({'role': 'user', 'content': wrapSystemTag(merged)});
          }
        }
        return result;
      }

      int findSafeInsertIndex(List<Map<String, dynamic>> messages, int target) {
        var index = target.clamp(0, messages.length);
        while (index > 0 && index < messages.length) {
          final role = (messages[index]['role'] ?? '').toString();
          if (role != 'tool') break;
          index--;
        }
        return index;
      }

      final byPosition = <WorldBookInjectionPosition, List<WorldBookEntry>>{};
      for (final t in triggered) {
        byPosition
            .putIfAbsent(t.entry.position, () => <WorldBookEntry>[])
            .add(t.entry);
      }

      // BEFORE/AFTER_SYSTEM_PROMPT: merge into system message.
      final beforeContent = joinContents(
        byPosition[WorldBookInjectionPosition.beforeSystemPrompt] ??
            const <WorldBookEntry>[],
      );
      final afterContent = joinContents(
        byPosition[WorldBookInjectionPosition.afterSystemPrompt] ??
            const <WorldBookEntry>[],
      );

      if (beforeContent.isNotEmpty || afterContent.isNotEmpty) {
        final systemIndex = apiMessages.indexWhere(
          (m) => (m['role'] ?? '').toString() == 'system',
        );
        if (systemIndex >= 0) {
          final original = (apiMessages[systemIndex]['content'] ?? '')
              .toString();
          final sb = StringBuffer();
          if (beforeContent.isNotEmpty) {
            sb.write(beforeContent);
            sb.write('\n');
          }
          sb.write(original);
          if (afterContent.isNotEmpty) {
            sb.write('\n');
            sb.write(afterContent);
          }
          apiMessages[systemIndex]['content'] = sb.toString();
        } else {
          final sb = StringBuffer();
          if (beforeContent.isNotEmpty) sb.write(beforeContent);
          if (afterContent.isNotEmpty) {
            if (sb.isNotEmpty) sb.write('\n');
            sb.write(afterContent);
          }
          if (sb.isNotEmpty) {
            apiMessages.insert(0, {'role': 'system', 'content': sb.toString()});
          }
        }
      }

      // TOP_OF_CHAT: insert before first user message.
      final topInjections = byPosition[WorldBookInjectionPosition.topOfChat];
      if (topInjections != null && topInjections.isNotEmpty) {
        var insertIndex = apiMessages.indexWhere(
          (m) => (m['role'] ?? '').toString() == 'user',
        );
        if (insertIndex < 0) insertIndex = apiMessages.length;
        insertIndex = findSafeInsertIndex(apiMessages, insertIndex);
        apiMessages.insertAll(
          insertIndex,
          createMergedInjectionMessages(topInjections),
        );
      }

      // BOTTOM_OF_CHAT: insert before last message.
      final bottomInjections =
          byPosition[WorldBookInjectionPosition.bottomOfChat];
      if (bottomInjections != null && bottomInjections.isNotEmpty) {
        var insertIndex = apiMessages.isEmpty ? 0 : (apiMessages.length - 1);
        insertIndex = findSafeInsertIndex(apiMessages, insertIndex);
        apiMessages.insertAll(
          insertIndex,
          createMergedInjectionMessages(bottomInjections),
        );
      }

      // AT_DEPTH: insert at depth from end (depth=1 means before last message).
      final atDepthInjections = byPosition[WorldBookInjectionPosition.atDepth];
      if (atDepthInjections != null && atDepthInjections.isNotEmpty) {
        final byDepth = <int, List<WorldBookEntry>>{};
        for (final e in atDepthInjections) {
          final depth = (e.injectDepth <= 0 ? 1 : e.injectDepth)
              .clamp(1, 200)
              .toInt();
          byDepth.putIfAbsent(depth, () => <WorldBookEntry>[]).add(e);
        }

        final depths = byDepth.keys.toList(growable: false)
          ..sort((a, b) => b.compareTo(a));

        for (final depth in depths) {
          final injections = byDepth[depth] ?? const <WorldBookEntry>[];
          var insertIndex = (apiMessages.length - depth).clamp(
            0,
            apiMessages.length,
          );
          insertIndex = findSafeInsertIndex(apiMessages, insertIndex);
          apiMessages.insertAll(
            insertIndex,
            createMergedInjectionMessages(injections),
          );
        }
      }
    } catch (_) {}
  }

  /// Helper to append content to the system message (or create one if missing).
  void _appendToSystemMessage(
    List<Map<String, dynamic>> apiMessages,
    String content,
  ) {
    if (apiMessages.isNotEmpty && apiMessages.first['role'] == 'system') {
      apiMessages[0]['content'] =
          '${(apiMessages[0]['content'] ?? '') as String}\n\n$content';
    } else {
      apiMessages.insert(0, {'role': 'system', 'content': content});
    }
  }

  /// Apply context message limit based on assistant settings.
  void applyContextLimit(
    List<Map<String, dynamic>> apiMessages,
    Assistant? assistant,
  ) {
    if ((assistant?.limitContextMessages ?? false) &&
        (assistant?.contextMessageSize ?? 0) > 0) {
      final int keep = (assistant!.contextMessageSize).clamp(
        Assistant.minContextMessageSize,
        Assistant.maxContextMessageSize,
      );
      int startIdx = 0;
      if (apiMessages.isNotEmpty && apiMessages.first['role'] == 'system') {
        startIdx = 1;
      }
      final tail = apiMessages.sublist(startIdx);
      if (tail.length > keep) {
        final trimmed = tail.sublist(tail.length - keep);
        apiMessages
          ..removeRange(startIdx, apiMessages.length)
          ..addAll(trimmed);
      }
      // Context trimming can cut in the middle of a tool-call triplet; avoid sending dangling tool messages.
      while (apiMessages.length > startIdx &&
          (apiMessages[startIdx]['role'] ?? '').toString() == 'tool') {
        apiMessages.removeAt(startIdx);
      }
    }
  }

  /// Convert local Markdown image links to inline base64 for model context.
  Future<void> inlineLocalImages(List<Map<String, dynamic>> apiMessages) async {
    for (int i = 0; i < apiMessages.length; i++) {
      final s = (apiMessages[i]['content'] ?? '').toString();
      if (s.isNotEmpty) {
        apiMessages[i]['content'] =
            await MarkdownMediaSanitizer.inlineLocalImagesToBase64(s);
      }
    }
  }

  /// Check if built-in search is enabled for the given provider/model.
  bool hasBuiltInSearch(
    SettingsProvider settings,
    String providerKey,
    String modelId,
  ) {
    try {
      final cfg = settings.getProviderConfig(providerKey);
      return BuiltInToolsHelper.isBuiltInSearchEnabled(
        cfg: cfg,
        modelId: modelId,
      );
    } catch (_) {
      return false;
    }
  }
}

class _DocTextCacheEntry {
  const _DocTextCacheEntry({
    required this.text,
    required this.modifiedMs,
    required this.size,
  });

  final String? text;
  final int modifiedMs;
  final int size;
}
