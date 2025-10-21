import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/backup.dart';
import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../providers/assistant_provider.dart';
import '../../providers/settings_provider.dart';
import '../chat/chat_service.dart';

class CherryImportResult {
  final int providers;
  final int assistants;
  final int conversations;
  final int messages;
  final int files;
  const CherryImportResult({
    required this.providers,
    required this.assistants,
    required this.conversations,
    required this.messages,
    required this.files,
  });
}

class CherryImporter {
  CherryImporter._();

  // Persisted keys used by SettingsProvider/AssistantProvider
  static const String _providersKey = 'provider_configs_v1';
  static const String _providersOrderKey = 'providers_order_v1';
  static const String _assistantsKey = 'assistants_v1';

  static Future<CherryImportResult> importFromCherryStudio({
    required File file,
    required RestoreMode mode,
    required SettingsProvider settings,
    required ChatService chatService,
  }) async {
    // 1) Load JSON from ZIP/BAK (best-effort)
    final Map<String, dynamic> root = await _readCherryBackupFile(file);

    // 2) Basic validation
    final version = (root['version'] as num?)?.toInt() ?? 0;
    if (version < 2) {
      throw Exception('Unsupported Cherry backup version: $version');
    }

    // 3) Parse localStorage persist:cherry-studio (Redux persist)
    final localStorage = (root['localStorage'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? const <String, dynamic>{};
    final persistStr = (localStorage['persist:cherry-studio'] ?? '') as String;
    if (persistStr.isEmpty) {
      throw Exception('Missing localStorage["persist:cherry-studio"]');
    }
    late Map<String, dynamic> persistObj;
    try {
      persistObj = jsonDecode(persistStr) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid persist:cherry-studio JSON');
    }

    // slices in persist are also JSON-encoded strings
    Map<String, dynamic> assistantsSlice = const {};
    Map<String, dynamic> llmSlice = const {};
    try {
      final aStr = (persistObj['assistants'] ?? '') as String;
      if (aStr.isNotEmpty) {
        assistantsSlice = jsonDecode(aStr) as Map<String, dynamic>;
      }
    } catch (_) {}
    try {
      final lStr = (persistObj['llm'] ?? '') as String;
      if (lStr.isNotEmpty) {
        llmSlice = jsonDecode(lStr) as Map<String, dynamic>;
      }
    } catch (_) {}

    final List<dynamic> cherryProviders = (llmSlice['providers'] as List?) ?? const <dynamic>[];
    final Map<String, dynamic> assistantsRoot = assistantsSlice;
    final List<dynamic> cherryAssistants = (assistantsRoot['assistants'] as List?) ?? const <dynamic>[];

    // 4) IndexedDB
    final indexedDB = (root['indexedDB'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? const <String, dynamic>{};
    final List<dynamic> cherryFiles = (indexedDB['files'] as List?) ?? const <dynamic>[];
    final List<dynamic> cherryTopicsWithMessages = (indexedDB['topics'] as List?) ?? const <dynamic>[];
    final List<dynamic> cherryMessageBlocks = (indexedDB['message_blocks'] as List?) ?? const <dynamic>[];

    // Build a map of topic metadata from assistants[].topics[]
    final Map<String, Map<String, dynamic>> topicMeta = <String, Map<String, dynamic>>{};
    for (final a in cherryAssistants) {
      if (a is! Map) continue;
      final topics = (a['topics'] as List?) ?? const <dynamic>[];
      for (final t in topics) {
        if (t is Map && t['id'] != null) {
          final id = t['id'].toString();
          topicMeta[id] = t.map((k, v) => MapEntry(k.toString(), v));
          // Ensure assistantId is present (avoid null index warning by using local var)
          final tm = topicMeta[id]!;
          final dynamic cand = t['assistantId'] ?? a['id'];
          if (cand != null) tm['assistantId'] = cand.toString();
        }
      }
    }

    // Build a map of topicId -> messages
    final Map<String, List<Map<String, dynamic>>> topicMessages = <String, List<Map<String, dynamic>>>{};
    for (final e in cherryTopicsWithMessages) {
      if (e is! Map) continue;
      final id = (e['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final msgs = (e['messages'] as List?) ?? const <dynamic>[];
      topicMessages[id] = [
        for (final m in msgs)
          if (m is Map) m.map((k, v) => MapEntry(k.toString(), v))
      ];
    }

    // Build a map of messageId -> reconstructed text from message_blocks (for cases where message.content is empty)
    final Map<String, String> blockTextByMessageId = <String, String>{};
    for (final b in cherryMessageBlocks) {
      if (b is! Map) continue;
      final type = (b['type'] ?? '').toString();
      final messageId = (b['messageId'] ?? '').toString();
      if (messageId.isEmpty) continue;
      // Only include readable blocks
      if (type == 'main_text') {
        final content = (b['content'] ?? '').toString();
        if (content.isNotEmpty) {
          final prev = blockTextByMessageId[messageId];
          blockTextByMessageId[messageId] = prev == null || prev.isEmpty ? content : '$prev\n$content';
        }
      } else if (type == 'code') {
        final code = (b['content'] ?? '').toString();
        final lang = (b['language'] ?? '').toString();
        if (code.isNotEmpty) {
          final fenced = '```' + (lang.isNotEmpty ? lang : '') + "\n" + code + "\n```";
          final prev = blockTextByMessageId[messageId];
          blockTextByMessageId[messageId] = prev == null || prev.isEmpty ? fenced : '$prev\n$fenced';
        }
      } else if (type == 'error') {
        final err = (b['content'] ?? '').toString();
        if (err.isNotEmpty) {
          final tagged = '> Error\n> ' + err.replaceAll('\n', '\n> ');
          final prev = blockTextByMessageId[messageId];
          blockTextByMessageId[messageId] = prev == null || prev.isEmpty ? tagged : '$prev\n$tagged';
        }
      } else if (type == 'thinking') {
        // Optional: include as a collapsible-like section in plain text
        final think = (b['content'] ?? '').toString();
        if (think.isNotEmpty) {
          final wrapped = '<think>\n' + think + '\n</think>';
          final prev = blockTextByMessageId[messageId];
          blockTextByMessageId[messageId] = prev == null || prev.isEmpty ? wrapped : '$prev\n$wrapped';
        }
      }
    }

    // 5) Import providers into Settings (SharedPreferences)
    final importedProviders = await _importProviders(cherryProviders, settings, mode);

    // 6) Import assistants (persist to SharedPreferences, restart recommended)
    final importedAssistants = await _importAssistants(cherryAssistants, mode);

    // 7) Prepare files (only if referenced by messages)
    final filesById = <String, Map<String, dynamic>>{
      for (final f in cherryFiles)
        if (f is Map && f['id'] != null) f['id'].toString(): f.map((k, v) => MapEntry(k.toString(), v))
    };

    // Precompute used file ids
    final usedFileIds = <String>{};
    for (final entry in topicMessages.entries) {
      for (final m in entry.value) {
        final files = (m['files'] as List?) ?? const <dynamic>[];
        for (final rf in files) {
          if (rf is Map && rf['id'] != null) usedFileIds.add(rf['id'].toString());
        }
      }
    }

    // Write referenced files into Documents/upload and build path map
    final pathsByFileId = await _materializeFiles(filesById, usedFileIds);

    // 8) Import topics & messages into ChatService
    final convCountAndMsgCount = await _importConversations(
      topicMeta: topicMeta,
      topicMessages: topicMessages,
      filePaths: pathsByFileId,
      chatService: chatService,
      mode: mode,
      blockTexts: blockTextByMessageId,
    );

    return CherryImportResult(
      providers: importedProviders,
      assistants: importedAssistants,
      conversations: convCountAndMsgCount.$1,
      messages: convCountAndMsgCount.$2,
      files: pathsByFileId.length,
    );
  }

  // ---------- helpers ----------

  static Future<Map<String, dynamic>> _readCherryBackupFile(File file) async {
    final bytes = await file.readAsBytes();

    Map<String, dynamic>? parsed;

    // Helper to verify structure looks like Cherry backup
    Map<String, dynamic>? _tryParseBackupJson(String text) {
      try {
        final obj = jsonDecode(text) as Map<String, dynamic>;
        if (obj.containsKey('localStorage') && obj.containsKey('indexedDB')) {
          return obj;
        }
      } catch (_) {}
      return null;
    }

    // 1) Try as plain JSON text
    try {
      final content = await file.readAsString();
      final obj = _tryParseBackupJson(content);
      if (obj != null) return obj;
    } catch (_) {}

    // 2) Try ZIP: scan all file entries and pick the one that parses to expected JSON
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final entry in archive) {
        if (!entry.isFile) continue;
        try {
          final content = utf8.decode(entry.content as List<int>, allowMalformed: true);
          final obj = _tryParseBackupJson(content);
          if (obj != null) return obj;
        } catch (_) {
          // skip non-text entries
        }
      }
    } catch (_) {}

    // 3) Try GZIP (some .bak may be gzip-compressed JSON)
    try {
      final gunzipped = GZipDecoder().decodeBytes(bytes, verify: false);
      final content = utf8.decode(gunzipped, allowMalformed: true);
      final obj = _tryParseBackupJson(content);
      if (obj != null) return obj;
    } catch (_) {}

    throw Exception('Unable to read Cherry backup file');
  }

  static Future<int> _importProviders(List<dynamic> cherryProviders, SettingsProvider settings, RestoreMode mode) async {
    // Build imported map id -> ProviderConfig JSON-like
    final imported = <String, Map<String, dynamic>>{};

    for (final p in cherryProviders) {
      if (p is! Map) continue;
      final id = (p['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final type = (p['type'] ?? '').toString().toLowerCase();
      final name = (p['name'] ?? id).toString();
      final apiKey = (p['apiKey'] ?? '').toString();
      final apiHost = (p['apiHost'] ?? '').toString();
      // normalize base url (trim trailing slash)
      final base = apiHost.endsWith('/') ? apiHost.substring(0, apiHost.length - 1) : apiHost;

      // Determine provider kind mapping
      String? kind;
      switch (type) {
        case 'openai':
          kind = 'openai';
          break;
        case 'anthropic':
          kind = 'claude';
          break;
        case 'gemini':
          kind = 'google';
          break;
        default:
          // default to OpenAI-compatible
          kind = 'openai';
      }

      // models list (ids only)
      final models = <String>[];
      final mlist = (p['models'] as List?) ?? const <dynamic>[];
      for (final m in mlist) {
        if (m is Map && m['id'] != null) models.add(m['id'].toString());
      }

      // Compose ProviderConfig json
      final map = <String, dynamic>{
        'id': id,
        'enabled': (p['enabled'] as bool?) ?? apiKey.isNotEmpty,
        'name': name,
        'apiKey': apiKey,
        'baseUrl': base.isNotEmpty
            ? base
            : (kind == 'google' ? 'https://generativelanguage.googleapis.com/v1beta' : (kind == 'claude' ? 'https://api.anthropic.com/v1' : 'https://api.openai.com/v1')),
        'providerType': kind == 'openai'
            ? 'openai'
            : kind == 'google'
                ? 'google'
                : 'claude',
        'chatPath': kind == 'openai' ? '/chat/completions' : null,
        'useResponseApi': kind == 'openai' ? false : null,
        'vertexAI': kind == 'google' ? false : null,
        'location': null,
        'projectId': null,
        'serviceAccountJson': null,
        'models': models,
        'modelOverrides': const <String, dynamic>{},
        'proxyEnabled': false,
        'proxyHost': '',
        'proxyPort': '8080',
        'proxyUsername': '',
        'proxyPassword': '',
        'multiKeyEnabled': false,
        'apiKeys': const <dynamic>[],
        'keyManagement': const <String, dynamic>{},
      };
      imported[id] = map;
    }

    final prefs = await SharedPreferences.getInstance();

    if (mode == RestoreMode.overwrite) {
      await prefs.setString(_providersKey, jsonEncode(imported));
      await prefs.setStringList(_providersOrderKey, imported.keys.toList());
      return imported.length;
    }

    // merge mode: merge into existing providers without removing any
    Map<String, dynamic> current = const <String, dynamic>{};
    try {
      final raw = prefs.getString(_providersKey);
      if (raw != null && raw.isNotEmpty) {
        current = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}

    final merged = <String, dynamic>{}..addAll(current);
    for (final entry in imported.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      } else {
        // Update with non-empty fields from imported
        final cur = (merged[entry.key] as Map).map((k, v) => MapEntry(k.toString(), v));
        final inc = entry.value;
        final next = Map<String, dynamic>.from(cur);
        void putIfNotEmpty(String k) {
          final v = inc[k];
          if (v == null) return;
          if (v is String && v.trim().isEmpty) return;
          next[k] = v;
        }
        for (final k in inc.keys) {
          putIfNotEmpty(k);
        }
        merged[entry.key] = next;
      }
    }

    await prefs.setString(_providersKey, jsonEncode(merged));

    // Merge providers order: append new ids at end, keep existing order
    final existedOrder = prefs.getStringList(_providersOrderKey) ?? const <String>[];
    final orderSet = existedOrder.toList();
    for (final id in imported.keys) {
      if (!orderSet.contains(id)) orderSet.add(id);
    }
    await prefs.setStringList(_providersOrderKey, orderSet);

    return imported.length;
  }

  static Future<int> _importAssistants(List<dynamic> cherryAssistants, RestoreMode mode) async {
    // Map to our Assistant JSON list (as stored by Assistant.encodeList)
    final out = <Map<String, dynamic>>[];
    for (final a in cherryAssistants) {
      if (a is! Map) continue;
      final id = (a['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final name = (a['name'] ?? id).toString();
      final prompt = (a['prompt'] ?? '').toString();
      final settings = (a['settings'] as Map?)?.map((k, v) => MapEntry(k.toString(), v));
      final model = (a['model'] as Map?)?.map((k, v) => MapEntry(k.toString(), v));

      final temperature = (settings?['temperature'] as num?)?.toDouble();
      final topP = (settings?['topP'] as num?)?.toDouble();
      final ctxCount = (settings?['contextCount'] as num?)?.toInt();
      final streamOutput = settings?['streamOutput'] as bool?;
      final enableMaxTokens = settings?['enableMaxTokens'] as bool? ?? false;
      final maxTokens = enableMaxTokens ? (settings?['maxTokens'] as num?)?.toInt() : null;

      final json = <String, dynamic>{
        'id': id,
        'name': name,
        'avatar': null,
        'useAssistantAvatar': false,
        'chatModelProvider': model?['provider']?.toString(),
        'chatModelId': model?['id']?.toString(),
        'temperature': temperature,
        'topP': topP,
        'contextMessageSize': ctxCount ?? 64,
        'limitContextMessages': true,
        'streamOutput': streamOutput ?? true,
        'thinkingBudget': null,
        'maxTokens': maxTokens,
        'systemPrompt': prompt,
        'messageTemplate': '{{ message }}',
        'mcpServerIds': const <String>[],
        'background': null,
        'deletable': true,
        'customHeaders': const <Map<String, String>>[],
        'customBody': const <Map<String, String>>[],
        'enableMemory': false,
        'enableRecentChatsReference': false,
      };
      out.add(json);
    }

    final prefs = await SharedPreferences.getInstance();
    if (mode == RestoreMode.overwrite) {
      await prefs.setString(_assistantsKey, jsonEncode(out));
      return out.length;
    }

    // merge: merge by id; update systemPrompt if provided, keep other local values
    List<dynamic> existing = const <dynamic>[];
    try {
      final raw = prefs.getString(_assistantsKey);
      if (raw != null && raw.isNotEmpty) existing = jsonDecode(raw) as List<dynamic>;
    } catch (_) {}
    final byId = <String, Map<String, dynamic>>{
      for (final e in existing)
        if (e is Map && e['id'] != null) e['id'].toString(): e.map((k, v) => MapEntry(k.toString(), v))
    };
    for (final a in out) {
      final id = a['id'] as String;
      if (!byId.containsKey(id)) {
        byId[id] = a;
      } else {
        final local = byId[id]!;
        // Update prompt if incoming has non-empty
        final incPrompt = (a['systemPrompt'] as String?)?.trim() ?? '';
        if (incPrompt.isNotEmpty) local['systemPrompt'] = incPrompt;
        // Update model fields if provided
        if (a['chatModelProvider'] != null) local['chatModelProvider'] = a['chatModelProvider'];
        if (a['chatModelId'] != null) local['chatModelId'] = a['chatModelId'];
      }
    }
    final merged = byId.values.toList();
    await prefs.setString(_assistantsKey, jsonEncode(merged));
    return out.length;
  }

  static Future<Map<String, String>> _materializeFiles(
    Map<String, Map<String, dynamic>> filesById,
    Set<String> usedIds,
  ) async {
    final docs = await getApplicationDocumentsDirectory();
    final uploadDir = Directory(p.join(docs.path, 'upload'));
    if (!await uploadDir.exists()) await uploadDir.create(recursive: true);

    final result = <String, String>{};
    for (final id in usedIds) {
      final meta = filesById[id];
      if (meta == null) continue;
      final name = (meta['origin_name'] ?? meta['name'] ?? 'file').toString();
      final ext = (meta['ext'] ?? '').toString();
      final mime = (meta['type'] ?? '').toString();
      final safeName = name.replaceAll(RegExp(r'[/\\\0]'), '_');
      final fn = safeName.isNotEmpty ? safeName : (ext.isNotEmpty ? 'file.$ext' : 'file');
      final fileName = 'cherry_${id}_$fn';
      final outPath = p.join(uploadDir.path, fileName);

      // If already written, reuse path
      if (await File(outPath).exists()) {
        result[id] = outPath;
        continue;
      }

      // Prefer base64 -> content -> url (url not downloaded)
      final base64Str = (meta['base64'] ?? '') as String;
      final contentStr = (meta['content'] ?? '') as String;
      try {
        if (base64Str.isNotEmpty) {
          // Strip data URL prefix if present
          String b64 = base64Str;
          final idx = b64.indexOf('base64,');
          if (idx != -1) b64 = b64.substring(idx + 7);
          final bytes = base64.decode(b64);
          await File(outPath).writeAsBytes(bytes);
          result[id] = outPath;
          continue;
        }
      } catch (_) {}

      try {
        if (contentStr.isNotEmpty) {
          await File(outPath).writeAsString(contentStr);
          result[id] = outPath;
          continue;
        }
      } catch (_) {}

      // If neither available, we cannot materialize this file; skip (message will fall back to URL/none)
    }
    return result;
  }

  // Returns (conversations, messages)
  static Future<(int, int)> _importConversations({
    required Map<String, Map<String, dynamic>> topicMeta,
    required Map<String, List<Map<String, dynamic>>> topicMessages,
    required Map<String, String> filePaths,
    required ChatService chatService,
    required RestoreMode mode,
    required Map<String, String> blockTexts,
  }) async {
    if (!chatService.initialized) await chatService.init();

    if (mode == RestoreMode.overwrite) {
      await chatService.clearAllData();
    }

    // Build map of existing conv ids for merge
    final existingConvs = chatService.getAllConversations();
    final existingConvIds = existingConvs.map((c) => c.id).toSet();
    final existingMsgIds = <String>{};
    if (mode == RestoreMode.merge) {
      for (final c in existingConvs) {
        final msgs = chatService.getMessages(c.id);
        for (final m in msgs) existingMsgIds.add(m.id);
      }
    }

    int convCount = 0;
    int msgCount = 0;

    for (final entry in topicMessages.entries) {
      final topicId = entry.key;
      final msgsRaw = entry.value;
      final meta = topicMeta[topicId] ?? const <String, dynamic>{};
      final title = (meta['name'] ?? 'Imported').toString();
      final pinned = meta['pinned'] as bool? ?? false;
      final assistantId = (meta['assistantId'] ?? '').toString().trim().isEmpty ? null : meta['assistantId'].toString();
      // created/updated fallback from messages
      DateTime createdAt;
      DateTime updatedAt;
      try { createdAt = DateTime.parse((meta['createdAt'] ?? '').toString()); } catch (_) {
        createdAt = DateTime.now();
      }
      try { updatedAt = DateTime.parse((meta['updatedAt'] ?? '').toString()); } catch (_) {
        updatedAt = createdAt;
      }

      // Convert messages
      final messages = <ChatMessage>[];
      for (final m in msgsRaw) {
        final msgId = (m['id'] ?? '').toString();
        if (msgId.isEmpty) continue;
        if (mode == RestoreMode.merge && existingMsgIds.contains(msgId)) continue;
        final roleRaw = (m['role'] ?? 'user').toString();
        final role = (roleRaw == 'system') ? 'assistant' : roleRaw; // our schema only supports 'user'|'assistant'
        // Prefer message.content; if empty, fallback to reconstructed blocks
        String content = '';
        final rawContent = m['content'];
        if (rawContent is String) {
          content = rawContent;
        } else if (rawContent != null) {
          content = rawContent.toString();
        }
        if (content.trim().isEmpty) {
          content = (blockTexts[msgId] ?? '').toString();
        }
        DateTime ts;
        try { ts = DateTime.parse((m['createdAt'] ?? '').toString()); } catch (_) { ts = DateTime.now(); }

        final modelId = (m['modelId'] ?? (m['model'] is Map ? (m['model']['id'] ?? '').toString() : null)) as String?;
        final providerId = (m['model'] is Map ? (m['model']['provider'] ?? '').toString() : null);
        final usage = (m['usage'] as Map?)?.map((k, v) => MapEntry(k.toString(), v));
        final totalTokens = (usage?['total_tokens'] as num?)?.toInt();

        // Attachments -> inline markers appended to content
        final files = (m['files'] as List?) ?? const <dynamic>[];
        final attachmentMarkers = <String>[];
        for (final f in files) {
          if (f is! Map) continue;
          final fid = (f['id'] ?? '').toString();
          if (fid.isEmpty) continue;
          final name = (f['origin_name'] ?? f['name'] ?? 'file').toString();
          final mime = (f['type'] ?? '').toString();
          final savedPath = filePaths[fid];
          if (savedPath != null && savedPath.isNotEmpty) {
            final isImage = mime.startsWith('image/') || name.toLowerCase().contains('.') && RegExp(r"\.(png|jpg|jpeg|gif|webp)").hasMatch(name.toLowerCase());
            if (isImage) {
              attachmentMarkers.add('[image:${savedPath}]');
            } else {
              attachmentMarkers.add('[file:${savedPath}|${name}|${mime.isEmpty ? 'application/octet-stream' : mime}]');
            }
          } else {
            // Fallback to URL if present (no download)
            final url = (f['url'] ?? '').toString();
            if (url.isNotEmpty) {
              final isImage = url.toLowerCase().contains(RegExp(r"\.(png|jpg|jpeg|gif|webp)$"));
              if (isImage) {
                attachmentMarkers.add('[image:${url}]');
              } else {
                attachmentMarkers.add('[file:${url}|${name}|${mime.isEmpty ? 'application/octet-stream' : mime}]');
              }
            }
          }
        }
        final mergedContent = attachmentMarkers.isEmpty ? content : (content.isEmpty ? attachmentMarkers.join('\n') : '$content\n${attachmentMarkers.join('\n')}' );

        messages.add(ChatMessage(
          id: msgId,
          role: role,
          content: mergedContent,
          timestamp: ts,
          modelId: modelId,
          providerId: providerId,
          totalTokens: totalTokens,
          conversationId: topicId,
        ));
      }

      // Derive timestamps if missing
      if (messages.isNotEmpty) {
        final times = messages.map((m) => m.timestamp).toList()..sort();
        createdAt = times.first;
        updatedAt = times.last;
      }

      // Persist
      if (mode == RestoreMode.merge && existingConvIds.contains(topicId)) {
        // Only add new messages
        for (final m in messages) {
          await chatService.addMessageDirectly(topicId, m);
          msgCount += 1;
        }
      } else {
        final conv = Conversation(
          id: topicId,
          title: title,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isPinned: pinned,
          assistantId: assistantId,
        );
        await chatService.restoreConversation(conv, messages);
        convCount += 1;
        msgCount += messages.length;
      }
    }

    return (convCount, msgCount);
  }
}
