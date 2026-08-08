import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../database/chat_database_repository.dart';
import '../../models/assistant.dart';
import '../../models/chat_message.dart';
import '../../models/memory_entry.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/memory_provider_v2.dart';
import '../../providers/settings_provider.dart';
import '../api/chat_api_service.dart';
import '../chat/chat_service.dart';
import 'memory_block_builder.dart';
import 'memory_extractor.dart';
import 'memory_gatekeeper.dart';
import 'memory_profile_distiller.dart';
import 'memory_prompts.dart';
import 'memory_repository.dart';
import 'memory_smart_add.dart';

/// Result of a background organize run (§12 / §13.6).
class MemoryOrganizeResult {
  const MemoryOrganizeResult({
    required this.advanced,
    required this.gate,
    this.extractedCount = 0,
    this.error,
    this.forcedAdvance = false,
    this.windowSize = 0,
  });

  final bool advanced;
  final MemoryGateParseResult? gate;
  final int extractedCount;
  final String? error;
  final bool forcedAdvance;

  /// Messages in the processed window; 0 when the run stopped before building
  /// one.
  final int windowSize;
}

class MemoryOrganizeStatus {
  const MemoryOrganizeStatus({this.lastAt, this.lastResult});

  final DateTime? lastAt;
  final MemoryOrganizeResult? lastResult;
}

class MemoryOrganizeRecord {
  MemoryOrganizeRecord({
    required this.at,
    required this.conversationId,
    required this.windowSize,
    required this.result,
  });

  final DateTime at;
  final String conversationId;
  final int windowSize;
  final MemoryOrganizeResult result;
}

class _PipelineJob {
  _PipelineJob({
    required this.conversationId,
    required this.assistantId,
    required this.force,
    this.completer,
  });

  final String conversationId;
  final String assistantId;
  final bool force;
  final Completer<MemoryOrganizeResult>? completer;
}

/// Background memory pipeline: Gatekeeper → Extract → Smart Add → Distiller.
///
/// Process-wide single-concurrency queue (max 8; drop oldest when full) (§12.8).
class MemoryPipelineService {
  MemoryPipelineService({
    required this.chatService,
    required this.repository,
    required this.chatRepository,
    required this._settings,
    required this._assistants,
    required this._memoryV2,
    Future<String> Function({
      required ProviderConfig config,
      required String modelId,
      required String prompt,
      int? thinkingBudget,
    })?
    generateText,
  }) : _generateText = generateText ?? _defaultGenerateText,
       smartAdd = MemorySmartAdd(
         repository: repository,
         chatRepository: chatRepository,
       ),
       distiller = MemoryProfileDistiller(
         repository: repository,
         chatRepository: chatRepository,
       );

  static Future<String> _defaultGenerateText({
    required ProviderConfig config,
    required String modelId,
    required String prompt,
    int? thinkingBudget,
  }) {
    return ChatApiService.generateText(
      config: config,
      modelId: modelId,
      prompt: prompt,
      thinkingBudget: thinkingBudget,
    );
  }

  final ChatService chatService;
  final MemoryRepository repository;
  final ChatDatabaseRepository chatRepository;
  final MemorySmartAdd smartAdd;
  final MemoryProfileDistiller distiller;

  final SettingsProvider Function() _settings;
  final AssistantProvider Function() _assistants;
  final MemoryProviderV2 Function() _memoryV2;
  final Future<String> Function({
    required ProviderConfig config,
    required String modelId,
    required String prompt,
    int? thinkingBudget,
  })
  _generateText;

  static const int queueLimit = 8;
  static const int firstWindowCap = 20;
  static const int maxWindowFailures = 3;

  final Queue<_PipelineJob> _queue = Queue<_PipelineJob>();
  bool _running = false;

  /// Failures keyed by `(conversationId, watermark, windowEndOrder)`.
  final Map<String, int> _windowFailures = {};

  MemoryOrganizeStatus _lastStatus = const MemoryOrganizeStatus();
  MemoryOrganizeStatus get lastStatus => _lastStatus;

  final List<MemoryOrganizeRecord> _recentRecords = [];
  List<MemoryOrganizeRecord> get recentRecords =>
      List<MemoryOrganizeRecord>.unmodifiable(_recentRecords);

  static final RegExp _imageMarkerRe = RegExp(r'\[image:[^\]]*\]');
  static final RegExp _fileMarkerRe = RegExp(r'\[file:[^\]]*\]');

  /// Strip `[image:…]` / `[file:…]` markers (§12.3).
  static String stripAttachmentMarkers(String text) {
    return text
        .replaceAll(_imageMarkerRe, '')
        .replaceAll(_fileMarkerRe, '')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .trim();
  }

  /// Collapse to the selected version chain (same rules as title generation).
  static List<ChatMessage> collapseSelectedVersions(
    List<ChatMessage> messages,
    Map<String, int> selections,
  ) {
    final byGroup = <String, List<ChatMessage>>{};
    final order = <String>[];
    for (final message in messages) {
      final groupId = message.groupId ?? message.id;
      byGroup
          .putIfAbsent(groupId, () {
            order.add(groupId);
            return <ChatMessage>[];
          })
          .add(message);
    }
    for (final list in byGroup.values) {
      list.sort((a, b) => a.version.compareTo(b.version));
    }
    return [
      for (final groupId in order)
        () {
          final versions = byGroup[groupId]!;
          final sel = selections[groupId];
          if (sel != null) {
            for (final c in versions) {
              if (c.version == sel) return c;
            }
          }
          return versions.last;
        }(),
    ];
  }

  /// Build `buildConversationText(window)` (§12.3).
  static String buildConversationText(
    List<ChatMessage> window,
    MemoryPromptLang lang,
  ) {
    final userPrefix = lang == MemoryPromptLang.zh ? '用户：' : 'User: ';
    final assistantPrefix = lang == MemoryPromptLang.zh ? '助手：' : 'Assistant: ';
    final lines = <String>[];
    for (final m in window) {
      String prefix;
      if (m.role == 'user') {
        prefix = userPrefix;
      } else if (m.role == 'assistant') {
        prefix = assistantPrefix;
      } else {
        continue;
      }
      var text = stripAttachmentMarkers(m.content).trim();
      if (text.isEmpty) continue;
      if (text.length > 2000) {
        text = '${text.substring(0, 2000)}…';
      }
      lines.add('$prefix$text');
    }
    var out = lines.join('\n\n');
    if (out.length > 12000) {
      out = '…${out.substring(out.length - 12000)}';
    }
    return out;
  }

  /// Whether conversation summary generation is allowed (§12.10 / D-27).
  static bool shouldGenerateConversationSummary({
    required bool allowPastConversationRecall,
    required bool generateConversationSummary,
  }) {
    return allowPastConversationRecall && generateConversationSummary;
  }

  /// Schedule after an assistant finalize. Never awaits; never throws to chat.
  void scheduleIfNeeded({
    required String conversationId,
    required String assistantId,
  }) {
    try {
      _enqueue(
        _PipelineJob(
          conversationId: conversationId,
          assistantId: assistantId,
          force: false,
        ),
      );
    } catch (e, st) {
      debugPrint('MemoryPipeline.scheduleIfNeeded: $e\n$st');
    }
  }

  /// Manual "整理记忆" — bypasses autoOrganize + N-turns; still needs model.
  Future<MemoryOrganizeResult> runNow({
    required String conversationId,
    required String assistantId,
  }) {
    final completer = Completer<MemoryOrganizeResult>();
    _enqueue(
      _PipelineJob(
        conversationId: conversationId,
        assistantId: assistantId,
        force: true,
        completer: completer,
      ),
    );
    return completer.future;
  }

  void _enqueue(_PipelineJob job) {
    // Coalesce pending (not running) jobs for the same conversation.
    _queue.removeWhere(
      (j) =>
          j.conversationId == job.conversationId &&
          j.completer == null &&
          job.completer == null,
    );
    _queue.addLast(job);
    while (_queue.length > queueLimit) {
      final dropped = _queue.removeFirst();
      dropped.completer?.complete(
        const MemoryOrganizeResult(
          advanced: false,
          gate: null,
          error: 'queue_overflow',
        ),
      );
    }
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeFirst();
        MemoryOrganizeResult result;
        try {
          result = await _runJob(job);
        } catch (e, st) {
          debugPrint('MemoryPipeline job failed: $e\n$st');
          result = MemoryOrganizeResult(
            advanced: false,
            gate: null,
            error: e.toString(),
          );
        }
        _lastStatus = MemoryOrganizeStatus(
          lastAt: DateTime.now(),
          lastResult: result,
        );
        _recentRecords.insert(
          0,
          MemoryOrganizeRecord(
            at: DateTime.now(),
            conversationId: job.conversationId,
            windowSize: result.windowSize,
            result: result,
          ),
        );
        if (_recentRecords.length > 20) {
          _recentRecords.removeLast();
        }
        job.completer?.complete(result);
      }
    } finally {
      _running = false;
    }
  }

  Future<MemoryOrganizeResult> _runJob(_PipelineJob job) async {
    final settings = _settings();
    final assistants = _assistants();
    final assistant = assistants.getById(job.assistantId);
    if (assistant == null) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'assistant_missing',
      );
    }
    if (!assistant.enableMemory) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'memory_disabled',
      );
    }
    if (!job.force && !assistant.autoOrganizeMemory) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'auto_organize_off',
      );
    }

    final provKey = settings.memoryModelProvider;
    final mdlId = settings.memoryModelId;
    if (provKey == null || mdlId == null) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'memory_model_unset',
      );
    }
    // Provider/model must still exist (D-20).
    final cfg = settings.getProviderConfig(provKey);
    if (cfg.models.isNotEmpty &&
        !cfg.models.contains(mdlId) &&
        cfg.modelOverrides[mdlId] == null) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'memory_model_missing',
      );
    }

    final convo = chatService.getConversation(job.conversationId);
    if (convo == null) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'conversation_missing',
      );
    }

    // Skip while this conversation still has a streaming message (§12.1).
    // Finalize already ran after the turn; a racing stream is rare — the next
    // successful finalize will re-trigger, so do not re-enqueue here (avoids
    // draining the same job forever).
    if (chatService.getMessages(job.conversationId).any((m) => m.isStreaming)) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'streaming',
      );
    }

    final all = await chatService.loadMessages(job.conversationId);
    final selected = collapseSelectedVersions(
      all,
      chatService.getVersionSelections(job.conversationId),
    );

    final watermark = convo.lastMemoryExtractedOrder;
    final withOrder = <({ChatMessage message, int order})>[];
    for (final m in selected) {
      if (m.isStreaming) continue;
      final order = chatService.getMessageIndex(job.conversationId, m.id);
      if (order < 0) continue;
      if (order <= watermark) continue;
      withOrder.add((message: m, order: order));
    }
    withOrder.sort((a, b) => a.order.compareTo(b.order));

    final pendingTurns = withOrder
        .where((e) => e.message.role == 'assistant')
        .length;
    if (!job.force &&
        pendingTurns < assistant.memoryOrganizeEveryNTurns.clamp(1, 20)) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'below_threshold',
      );
    }
    if (withOrder.isEmpty) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'empty_window',
      );
    }

    var window = withOrder;
    if (watermark == -1 && window.length > firstWindowCap) {
      window = window.sublist(window.length - firstWindowCap);
    }
    final thinkingBudget = settings.memoryModelThinkingEnabled
        ? (assistant.thinkingBudget ?? settings.thinkingBudget)
        : 0;

    return processWindow(
      conversationId: job.conversationId,
      assistant: assistant,
      settings: settings,
      watermark: watermark,
      window: window,
      llmCall: (prompt) => _generateText(
        config: cfg,
        modelId: mdlId,
        prompt: prompt,
        thinkingBudget: thinkingBudget,
      ),
    );
  }

  /// Gatekeeper → Extract → Smart Add → Distiller for a prepared window.
  ///
  /// Exposed for tests (§18.1 / watermark / short-circuit).
  @visibleForTesting
  Future<MemoryOrganizeResult> processWindow({
    required String conversationId,
    required Assistant assistant,
    required SettingsProvider settings,
    required int watermark,
    required List<({ChatMessage message, int order})> window,
    required Future<String> Function(String prompt) llmCall,
  }) async {
    if (window.isEmpty) {
      return const MemoryOrganizeResult(
        advanced: false,
        gate: null,
        error: 'empty_window',
      );
    }
    final windowEnd = window.last.order;
    final failureKey = '$conversationId|$watermark|$windowEnd';
    final lang = settings.resolvedMemoryPromptLang;
    final conversationText = buildConversationText([
      for (final e in window) e.message,
    ], lang);

    // ── Gatekeeper ────────────────────────────────────────────────────────
    final gatePrompt = MemoryGatekeeper.buildPrompt(
      lang: lang,
      conversation: conversationText,
      overrideZh: settings.memoryGatePromptZh,
      overrideEn: settings.memoryGatePromptEn,
    );
    final String gateRaw;
    try {
      gateRaw = await llmCall(gatePrompt);
    } catch (e) {
      return _failWindow(
        failureKey: failureKey,
        conversationId: conversationId,
        windowEnd: windowEnd,
        assistantId: assistant.id,
        windowSize: window.length,
        gate: null,
        error: 'gate_request_failed:$e',
      );
    }
    final gate = MemoryGatekeeper.parse(gateRaw);
    if (gate == MemoryGateParseResult.malformed) {
      return _failWindow(
        failureKey: failureKey,
        conversationId: conversationId,
        windowEnd: windowEnd,
        assistantId: assistant.id,
        windowSize: window.length,
        gate: gate,
        error: 'gate_parse_failed',
      );
    }
    if (gate == MemoryGateParseResult.skip) {
      await _advance(conversationId, windowEnd, assistantId: assistant.id);
      _windowFailures.remove(failureKey);
      return MemoryOrganizeResult(
        advanced: true,
        gate: gate,
        extractedCount: 0,
        windowSize: window.length,
      );
    }

    // ── Extract ───────────────────────────────────────────────────────────
    final visible = await chatRepository.queryVisibleMemories(
      assistantId: assistant.id,
    );
    final totals = await chatRepository.countVisibleMemoriesByType(
      assistantId: assistant.id,
    );
    final existingMemory = MemoryBlockBuilder.buildMemoryBlock(
      visible: visible,
      totalByType: totals,
      lang: lang,
    );
    final extractPrompt = MemoryExtractor.buildPrompt(
      lang: lang,
      conversation: conversationText,
      existingMemory: existingMemory,
      writeScope: assistant.memoryWriteScope,
      overrideZh: settings.memoryExtractPromptZh,
      overrideEn: settings.memoryExtractPromptEn,
    );
    final String extractRaw;
    try {
      extractRaw = await llmCall(extractPrompt);
    } catch (e) {
      return _failWindow(
        failureKey: failureKey,
        conversationId: conversationId,
        windowEnd: windowEnd,
        assistantId: assistant.id,
        windowSize: window.length,
        gate: gate,
        error: 'extract_request_failed:$e',
      );
    }
    final extracted = MemoryExtractor.parse(extractRaw);
    if (!extracted.ok) {
      return _failWindow(
        failureKey: failureKey,
        conversationId: conversationId,
        windowEnd: windowEnd,
        assistantId: assistant.id,
        windowSize: window.length,
        gate: gate,
        error: 'extract_parse_failed',
      );
    }
    if (extracted.items.isEmpty) {
      await _advance(conversationId, windowEnd, assistantId: assistant.id);
      _windowFailures.remove(failureKey);
      return MemoryOrganizeResult(
        advanced: true,
        gate: gate,
        extractedCount: 0,
        windowSize: window.length,
      );
    }

    // ── Smart Add ─────────────────────────────────────────────────────────
    final smartItems = <SmartAddItem>[
      for (final item in extracted.items)
        () {
          final scope = MemorySmartAdd.resolveScopeForExtracted(
            policy: assistant.memoryWriteScope,
            scopeAttr: item.scopeAttr,
          );
          return SmartAddItem(
            type: item.type,
            content: item.content,
            scope: scope,
            assistantId: scope == MemoryScope.assistant ? assistant.id : null,
          );
        }(),
    ];

    final smart = await smartAdd.addMany(
      items: smartItems,
      visibilityAssistantId: assistant.id,
      source: MemorySource.extracted,
      lang: lang,
      mode: assistant.memorySmartAddMode,
      llmCall: llmCall,
      perItemOverrideZh: settings.memorySmartAddPromptZh,
      perItemOverrideEn: settings.memorySmartAddPromptEn,
      batchOverrideZh: settings.memorySmartAddBatchPromptZh,
      batchOverrideEn: settings.memorySmartAddBatchPromptEn,
    );

    // ── Profile Distiller (identity changes only) ─────────────────────────
    if (smart.identityChanged) {
      try {
        await distiller.run(
          lang: lang,
          assistantId: assistant.id,
          llmCall: llmCall,
          overrideZh: settings.memoryProfileDistillPromptZh,
          overrideEn: settings.memoryProfileDistillPromptEn,
        );
      } catch (e) {
        debugPrint('MemoryPipeline distiller failed: $e');
      }
    }

    // Smart Add (including degraded) and Distiller failure both advance (§12.8).
    await _advance(conversationId, windowEnd, assistantId: assistant.id);
    _windowFailures.remove(failureKey);
    return MemoryOrganizeResult(
      advanced: true,
      gate: gate,
      extractedCount: extracted.items.length,
      windowSize: window.length,
    );
  }

  Future<MemoryOrganizeResult> _failWindow({
    required String failureKey,
    required String conversationId,
    required int windowEnd,
    required String assistantId,
    required int windowSize,
    required MemoryGateParseResult? gate,
    required String error,
  }) async {
    final count = (_windowFailures[failureKey] ?? 0) + 1;
    _windowFailures[failureKey] = count;
    if (count >= maxWindowFailures) {
      await _advance(conversationId, windowEnd, assistantId: assistantId);
      _windowFailures.remove(failureKey);
      return MemoryOrganizeResult(
        advanced: true,
        gate: gate,
        error: error,
        forcedAdvance: true,
        windowSize: windowSize,
      );
    }
    return MemoryOrganizeResult(
      advanced: false,
      gate: gate,
      error: error,
      windowSize: windowSize,
    );
  }

  Future<void> _advance(
    String conversationId,
    int order, {
    String? assistantId,
  }) async {
    await chatRepository.setConversationLastMemoryExtractedOrder(
      conversationId,
      order,
    );
    // Keep in-memory Conversation in sync when present.
    final convo = chatService.getConversation(conversationId);
    if (convo != null) {
      convo.lastMemoryExtractedOrder = order;
    }
    try {
      await _memoryV2().refresh(assistantId: assistantId);
    } catch (_) {}
  }
}
