import 'dart:convert';

import '../../database/chat_database_repository.dart';
import '../../models/assistant.dart';
import '../../models/memory_entry.dart';
import '../../models/user_profile_field.dart';
import '../chat/chat_service.dart';
import 'memory_block_builder.dart';
import 'memory_prompts.dart';
import 'memory_repository.dart';
import 'memory_tokenizer.dart';

/// Memory system V1 tool declarations + dispatch (§10).
///
/// Tool descriptions are model contracts (D-18 / §16.2): bilingual constants
/// here, never ARB/l10n. Chosen by [MemoryPromptLang].
abstract final class MemoryTools {
  MemoryTools._();

  static const String memoryRead = 'memory_read';
  static const String memoryUpdate = 'memory_update';
  static const String memorySearchProfile = 'memory_search_profile';
  static const String memoryEdit = 'memory_edit';
  static const String memoryDelete = 'memory_delete';
  static const String updateUserProfile = 'update_user_profile';
  static const String chatSearch = 'chat_search';

  static const Set<String> enableMemoryToolNames = {
    memoryRead,
    memoryUpdate,
    memorySearchProfile,
    memoryEdit,
    memoryDelete,
    updateUserProfile,
  };

  static const Set<String> allToolNames = {
    ...enableMemoryToolNames,
    chatSearch,
  };

  static const List<String> _legacyToolNames = [
    'create_memory',
    'edit_memory',
    'delete_memory',
  ];

  /// Names of the removed legacy tools (§10.11). Exposed for tests.
  static List<String> get legacyToolNames =>
      List<String>.unmodifiable(_legacyToolNames);

  // —— Definitions ——

  /// Build tool definitions gated by [enableMemory] / [allowPastConversationRecall]
  /// (§10.1). [writeScope] controls whether `scope` appears on `memory_update`
  /// (§10.2 / §4.3).
  static List<Map<String, dynamic>> buildDefinitions({
    required MemoryPromptLang lang,
    required MemoryWriteScope writeScope,
    required bool enableMemory,
    required bool allowPastConversationRecall,
  }) {
    final out = <Map<String, dynamic>>[];
    if (enableMemory) {
      out.add(_defMemoryRead(lang));
      out.add(_defMemoryUpdate(lang, writeScope));
      out.add(_defMemorySearchProfile(lang));
      out.add(_defMemoryEdit(lang));
      out.add(_defMemoryDelete(lang));
      out.add(_defUpdateUserProfile(lang));
    }
    if (allowPastConversationRecall) {
      out.add(_defChatSearch(lang));
    }
    return out;
  }

  // —— Dispatch ——

  /// Handle a memory / chat_search tool call.
  ///
  /// Returns `null` when the tool is not applicable for this assistant's
  /// gates (so the caller can fall through to other handlers).
  static Future<String?> handle({
    required String name,
    required Map<String, dynamic> args,
    required Assistant assistant,
    required MemoryRepository repository,
    required ChatDatabaseRepository chatRepository,
    ChatService? chatService,
    String? conversationId,
    Future<void> Function()? onMutated,
  }) async {
    if (name == chatSearch) {
      if (!assistant.allowPastConversationRecall) return null;
      try {
        return await _handleChatSearch(
          args: args,
          chatService: chatService,
          conversationId: conversationId,
        );
      } catch (e) {
        return toolError(
          error: 'memory_execution_error',
          message: e.toString(),
          tool: name,
          instruction:
              'The memory tool failed. Retry only after correcting the parameters, or inform the user about the issue.',
        );
      }
    }

    if (!assistant.enableMemory) return null;
    if (!enableMemoryToolNames.contains(name)) return null;

    try {
      switch (name) {
        case memoryRead:
          return await _handleMemoryRead(
            args: args,
            assistant: assistant,
            chatRepository: chatRepository,
          );
        case memoryUpdate:
          final result = await _handleMemoryUpdate(
            args: args,
            assistant: assistant,
            repository: repository,
            chatRepository: chatRepository,
          );
          await onMutated?.call();
          return result;
        case memorySearchProfile:
          return await _handleMemorySearchProfile(
            args: args,
            assistant: assistant,
            chatRepository: chatRepository,
          );
        case memoryEdit:
          final result = await _handleMemoryEdit(
            args: args,
            assistant: assistant,
            repository: repository,
            chatRepository: chatRepository,
          );
          await onMutated?.call();
          return result;
        case memoryDelete:
          final result = await _handleMemoryDelete(
            args: args,
            assistant: assistant,
            repository: repository,
            chatRepository: chatRepository,
          );
          await onMutated?.call();
          return result;
        case updateUserProfile:
          final result = await _handleUpdateUserProfile(
            args: args,
            repository: repository,
          );
          await onMutated?.call();
          return result;
        default:
          return null;
      }
    } catch (e) {
      return toolError(
        error: 'memory_execution_error',
        message: e.toString(),
        tool: name,
        instruction:
            'The memory tool failed. Retry only after correcting the parameters, or inform the user about the issue.',
      );
    }
  }

  static String toolError({
    required String error,
    required String message,
    required String tool,
    String? instruction,
  }) {
    return jsonEncode({
      'type': 'tool_error',
      'error': error,
      'message': message,
      'tool': tool,
      if (instruction != null) 'instruction': instruction,
    });
  }

  /// Resolve write [MemoryScope] from assistant policy + optional tool arg.
  static MemoryScope resolveWriteScope(
    MemoryWriteScope policy,
    String? scopeArg,
  ) {
    switch (policy) {
      case MemoryWriteScope.alwaysGlobal:
        return MemoryScope.global;
      case MemoryWriteScope.alwaysAssistant:
        return MemoryScope.assistant;
      case MemoryWriteScope.toolDefaultGlobal:
        if (scopeArg == 'assistant') return MemoryScope.assistant;
        return MemoryScope.global;
      case MemoryWriteScope.toolDefaultAssistant:
        if (scopeArg == 'global') return MemoryScope.global;
        return MemoryScope.assistant;
    }
  }

  /// Whitespace-split, lowercase, then [MemoryTokenizer.escapeLike] (§5.9).
  static List<String> searchTokens(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map(MemoryTokenizer.escapeLike)
        .toList(growable: false);
  }

  // —— Handlers ——

  static Future<String> _handleMemoryRead({
    required Map<String, dynamic> args,
    required Assistant assistant,
    required ChatDatabaseRepository chatRepository,
  }) async {
    final type = _parseMemoryType(args['type']);
    if (args.containsKey('type') && args['type'] != null && type == null) {
      return toolError(
        error: 'invalid_memory_type',
        message: 'type must be one of: identity, workflow, voice, instruction.',
        tool: memoryRead,
      );
    }
    final includeArchived = _asBool(args['include_archived']) ?? false;
    final limit = (_asInt(args['limit']) ?? 50).clamp(1, 100);

    final all = await chatRepository.queryVisibleMemories(
      assistantId: assistant.id,
      type: type,
      includeArchived: includeArchived,
    );
    final returned = all.length <= limit ? all : all.sublist(0, limit);
    return jsonEncode({
      'total': all.length,
      'returned': returned.length,
      'entries': [
        for (final e in returned) _entrySummary(e, includeStatus: true),
      ],
    });
  }

  static Future<String> _handleMemoryUpdate({
    required Map<String, dynamic> args,
    required Assistant assistant,
    required MemoryRepository repository,
    required ChatDatabaseRepository chatRepository,
  }) async {
    final type = _parseMemoryType(args['type']);
    if (type == null) {
      return toolError(
        error: 'invalid_memory_type',
        message:
            'type is required and must be one of: identity, workflow, voice, instruction.',
        tool: memoryUpdate,
      );
    }
    final content = (args['content'] ?? '').toString();
    if (content.trim().isEmpty) {
      return toolError(
        error: 'invalid_memory_content',
        message: 'Memory content must not be empty.',
        tool: memoryUpdate,
      );
    }

    final scopeArg = args['scope']?.toString();
    final scope = resolveWriteScope(assistant.memoryWriteScope, scopeArg);
    final assistantId = scope == MemoryScope.assistant ? assistant.id : null;

    // Degraded Smart Add (PR4 / §12.6): exact duplicate → SKIP, else NEW.
    final exact = await chatRepository.findExactMemory(
      assistantId: assistant.id,
      type: type,
      contentNormalized: MemoryEntry.normalizeContent(content),
    );
    if (exact != null) {
      return jsonEncode({
        'action': 'SKIP',
        'reason': 'duplicate',
        'id': exact.id,
      });
    }

    final entry = await repository.create(
      scope: scope,
      assistantId: assistantId,
      type: type,
      content: content,
      source: MemorySource.tool,
    );
    return jsonEncode({
      'action': 'NEW',
      'id': entry.id,
      'content': entry.content,
    });
  }

  static Future<String> _handleMemorySearchProfile({
    required Map<String, dynamic> args,
    required Assistant assistant,
    required ChatDatabaseRepository chatRepository,
  }) async {
    final query = (args['query'] ?? '').toString();
    if (query.trim().isEmpty) {
      return toolError(
        error: 'invalid_query',
        message: 'query must not be empty.',
        tool: memorySearchProfile,
      );
    }
    final type = _parseMemoryType(args['type']);
    if (args.containsKey('type') && args['type'] != null && type == null) {
      return toolError(
        error: 'invalid_memory_type',
        message: 'type must be one of: identity, workflow, voice, instruction.',
        tool: memorySearchProfile,
      );
    }
    final limit = (_asInt(args['limit']) ?? 10).clamp(1, 20);
    final tokens = searchTokens(query);
    if (tokens.isEmpty) {
      return jsonEncode({
        'query': query,
        'matched': <Map<String, dynamic>>[],
        'related': <Map<String, dynamic>>[],
      });
    }

    final matched = await chatRepository.searchMemories(
      assistantId: assistant.id,
      tokens: tokens,
      type: type,
      matchAll: true,
      limit: limit,
    );

    final matchedIds = {for (final e in matched) e.id};
    // relatedId → first via matched id (matched order).
    final viaByRelated = <String, String>{};
    for (final m in matched) {
      for (final rid in m.relatedIds) {
        if (matchedIds.contains(rid)) continue;
        viaByRelated.putIfAbsent(rid, () => m.id);
      }
    }

    final relatedEntries = await chatRepository.memoriesByIds(
      viaByRelated.keys.toList(growable: false),
    );
    final relatedFiltered = relatedEntries
        .where(
          (e) =>
              e.status == MemoryStatus.active &&
              _isVisible(e, assistant.id) &&
              !matchedIds.contains(e.id),
        )
        .toList();
    relatedFiltered.sort((a, b) {
      final byUpdated = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdated != 0) return byUpdated;
      return a.id.compareTo(b.id);
    });
    final relatedCapped = relatedFiltered.length <= 10
        ? relatedFiltered
        : relatedFiltered.sublist(0, 10);

    return jsonEncode({
      'query': query,
      'matched': [
        for (final e in matched) _entrySummary(e, includeStatus: false),
      ],
      'related': [
        for (final e in relatedCapped)
          {
            'id': e.id,
            'viaId': viaByRelated[e.id],
            'type': MemoryEntry.typeToString(e.type),
            'content': e.content,
            'updatedAt': MemoryBlockBuilder.fmtDate(e.updatedAt),
          },
      ],
    });
  }

  static Future<String> _handleMemoryEdit({
    required Map<String, dynamic> args,
    required Assistant assistant,
    required MemoryRepository repository,
    required ChatDatabaseRepository chatRepository,
  }) async {
    final id = (args['id'] ?? '').toString().trim();
    final content = (args['content'] ?? '').toString();
    if (id.isEmpty) {
      return toolError(
        error: 'invalid_memory_id',
        message: 'id is required (e.g. mem_a1b2c3d4).',
        tool: memoryEdit,
      );
    }
    if (content.trim().isEmpty) {
      return toolError(
        error: 'invalid_memory_content',
        message: 'Memory content must not be empty.',
        tool: memoryEdit,
      );
    }

    final found = await chatRepository.memoriesByIds([id]);
    final entry = found.isEmpty ? null : found.first;
    if (entry == null ||
        entry.status != MemoryStatus.active ||
        !_isVisible(entry, assistant.id)) {
      return toolError(
        error: 'memory_not_found',
        message: 'No active visible memory was found for id $id.',
        tool: memoryEdit,
        instruction:
            'Use memory_read or memory_search_profile to obtain a valid id, or call memory_update to write a new entry instead of editing a missing one.',
      );
    }

    final updated = await repository.updateContent(id, content);
    if (updated == null) {
      return toolError(
        error: 'memory_not_found',
        message: 'No active visible memory was found for id $id.',
        tool: memoryEdit,
        instruction:
            'Use memory_read or memory_search_profile to obtain a valid id, or call memory_update to write a new entry instead of editing a missing one.',
      );
    }
    return jsonEncode({
      'action': 'EDIT',
      'id': updated.id,
      'content': updated.content,
    });
  }

  static Future<String> _handleMemoryDelete({
    required Map<String, dynamic> args,
    required Assistant assistant,
    required MemoryRepository repository,
    required ChatDatabaseRepository chatRepository,
  }) async {
    final id = (args['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      return toolError(
        error: 'invalid_memory_id',
        message: 'id is required (e.g. mem_a1b2c3d4).',
        tool: memoryDelete,
      );
    }

    final found = await chatRepository.memoriesByIds([id]);
    final entry = found.isEmpty ? null : found.first;
    if (entry == null || !_isVisible(entry, assistant.id)) {
      return toolError(
        error: 'memory_not_found',
        message: 'No visible memory was found for id $id.',
        tool: memoryDelete,
        instruction:
            'Use memory_read or memory_search_profile to obtain a valid id, or skip archiving a missing memory.',
      );
    }

    final ok = await repository.archive(id);
    if (!ok) {
      return toolError(
        error: 'memory_not_found',
        message: 'No visible memory was found for id $id.',
        tool: memoryDelete,
        instruction:
            'Use memory_read or memory_search_profile to obtain a valid id, or skip archiving a missing memory.',
      );
    }
    return jsonEncode({'action': 'ARCHIVE', 'id': id});
  }

  static Future<String> _handleUpdateUserProfile({
    required Map<String, dynamic> args,
    required MemoryRepository repository,
  }) async {
    final rawFields = args['fields'];
    if (rawFields is! List) {
      return toolError(
        error: 'invalid_profile_fields',
        message: 'fields must be an array of {key, value} objects.',
        tool: updateUserProfile,
      );
    }

    final updated = <String>[];
    final cleared = <String>[];
    final rejected = <Map<String, String>>[];

    for (final item in rawFields) {
      if (item is! Map) {
        rejected.add({'key': '', 'reason': 'invalid_item'});
        continue;
      }
      final map = item.cast<String, dynamic>();
      final key = (map['key'] ?? '').toString();
      final value = (map['value'] ?? '').toString();
      if (!UserProfileField.isValidKey(key)) {
        rejected.add({'key': key, 'reason': 'unknown_key'});
        continue;
      }
      if (value.trim().isEmpty) {
        await repository.removeProfileField(key);
        cleared.add(key);
      } else {
        await repository.putProfileField(key, value, MemorySource.tool);
        updated.add(key);
      }
    }

    return jsonEncode({
      'action': 'PROFILE_UPDATE',
      'updated': updated,
      'cleared': cleared,
      'rejected': rejected,
    });
  }

  static Future<String> _handleChatSearch({
    required Map<String, dynamic> args,
    required ChatService? chatService,
    required String? conversationId,
  }) async {
    final query = (args['query'] ?? '').toString();
    if (query.trim().isEmpty) {
      return toolError(
        error: 'invalid_query',
        message: 'query must not be empty.',
        tool: chatSearch,
      );
    }
    if (chatService == null) {
      return toolError(
        error: 'chat_search_unavailable',
        message: 'Chat search service is unavailable.',
        tool: chatSearch,
      );
    }
    final limit = (_asInt(args['limit']) ?? 10).clamp(1, 20);
    final filterConversationId = args['conversation_id']?.toString().trim();
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return jsonEncode({'query': query, 'results': <Map<String, dynamic>>[]});
    }

    final matches = await chatService.searchConversationMatches(
      tokens: tokens,
      limit: limit * 8,
    );

    final results = <Map<String, dynamic>>[];
    for (final m in matches) {
      if (filterConversationId != null && filterConversationId.isNotEmpty) {
        if (m.conversationId != filterConversationId) continue;
      } else if (conversationId != null &&
          conversationId.isNotEmpty &&
          m.conversationId == conversationId) {
        continue;
      }
      final role = m.messageRole;
      if (role != 'user' && role != 'assistant') continue;
      final content = (m.messageContent ?? '').trim();
      if (content.isEmpty) continue;

      final conv = chatService.getConversation(m.conversationId);
      final summary = conv?.summary?.trim();
      results.add({
        'conversationId': m.conversationId,
        'title': m.conversationTitle,
        if (summary != null && summary.isNotEmpty) 'summary': summary,
        'role': role,
        'date': MemoryBlockBuilder.fmtDate(m.updatedAt),
        'snippet': _snippet(content, tokens),
      });
      if (results.length >= limit) break;
    }

    return jsonEncode({'query': query, 'results': results});
  }

  // —— Schema builders ——

  static Map<String, dynamic> _defMemoryRead(MemoryPromptLang lang) {
    final zh = lang == MemoryPromptLang.zh;
    return {
      'type': 'function',
      'function': {
        'name': memoryRead,
        'description': zh
            ? '读取用户的长期记忆。type 可选：identity（姓名、身边的人、职业等身份信息）、workflow（做事方式、工具偏好、调试习惯）、voice（行文风格、句式节奏、用词习惯）、instruction（用户对你的明确要求）。不传 type 则返回全部类型。对话中已经提供了记忆摘要，只有在摘要标了 mode="summary" 被截断、或需要拿到条目 id 时才需要调用。'
            : 'Read the user\'s long-term memory. Optional type: identity (name, people around them, occupation, etc.), workflow (ways of working, tool preferences, debugging habits), voice (writing style, rhythm, word choice), instruction (explicit requests to you). Omit type to return all types. A memory summary is already in the conversation; call this only when a block is marked mode="summary" (truncated) or you need entry ids.',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {
              'type': 'string',
              'enum': ['identity', 'workflow', 'voice', 'instruction'],
              'description': zh
                  ? '只返回该类型的记忆。省略则返回全部类型。'
                  : 'Return only memories of this type. Omit to return all types.',
            },
            'include_archived': {
              'type': 'boolean',
              'description': zh
                  ? '是否包含已归档的记忆。默认 false。'
                  : 'Whether to include archived memories. Default false.',
            },
            'limit': {
              'type': 'integer',
              'minimum': 1,
              'maximum': 100,
              'description': zh
                  ? '最多返回多少条，默认 50。'
                  : 'Maximum number of entries to return. Default 50.',
            },
          },
          'required': <String>[],
        },
      },
    };
  }

  static Map<String, dynamic> _defMemoryUpdate(
    MemoryPromptLang lang,
    MemoryWriteScope writeScope,
  ) {
    final zh = lang == MemoryPromptLang.zh;
    final properties = <String, dynamic>{
      'type': {
        'type': 'string',
        'enum': ['identity', 'workflow', 'voice', 'instruction'],
        'description': zh
            ? 'identity 身份信息；workflow 做事方式与工具偏好；voice 表达风格；instruction 用户对你的明确要求。'
            : 'identity: identity facts; workflow: ways of working and tool preferences; voice: expression style; instruction: explicit requests to you.',
      },
      'content': {
        'type': 'string',
        'description': zh
            ? '一条完整、自包含的第三人称陈述句，例如「用户偏好直接、可落地的中文说明」。不要使用「这个」「刚才」等指回本次对话的词。'
            : 'One complete, self-contained third-person statement, e.g. "The user prefers direct, actionable explanations in Chinese." Avoid deictic words that refer back to this conversation.',
      },
    };
    if (writeScope == MemoryWriteScope.toolDefaultGlobal ||
        writeScope == MemoryWriteScope.toolDefaultAssistant) {
      properties['scope'] = {
        'type': 'string',
        'enum': ['global', 'assistant'],
        'description': zh
            ? 'global 对所有助手可见；assistant 只对当前助手可见。省略时按用户设置的默认值。'
            : 'global is visible to all assistants; assistant is visible only to the current assistant. When omitted, uses the user\'s configured default.',
      };
    }
    return {
      'type': 'function',
      'function': {
        'name': memoryUpdate,
        'description': zh
            ? '写入一条用户长期记忆。系统会自动与已有记忆去重合并，不需要先读取再全文替换。只写下次新开对话时仍然成立的稳定信息；本次对话内的临时上下文不要写。'
            : 'Write one long-term user memory. The system deduplicates and merges with existing memories automatically; you do not need to read then replace. Only write stable facts that will still hold in a future conversation; do not write ephemeral context from this chat.',
        'parameters': {
          'type': 'object',
          'properties': properties,
          'required': ['type', 'content'],
        },
      },
    };
  }

  static Map<String, dynamic> _defMemorySearchProfile(MemoryPromptLang lang) {
    final zh = lang == MemoryPromptLang.zh;
    return {
      'type': 'function',
      'function': {
        'name': memorySearchProfile,
        'description': zh
            ? '搜索用户的长期记忆。当对话中提供的记忆摘要不够详细、被截断（标了 mode="summary"），或需要查找某个特定信息时使用。按关键词匹配，多个关键词之间是「且」关系。'
            : 'Search the user\'s long-term memory. Use when the in-conversation memory summary is incomplete, truncated (mode="summary"), or you need a specific fact. Keyword match; multiple keywords are ANDed.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': zh
                  ? '关键词，多个用空格分隔。中文可以直接写连续短语。'
                  : 'Keywords separated by spaces. Continuous Chinese phrases can be used as-is.',
            },
            'type': {
              'type': 'string',
              'enum': ['identity', 'workflow', 'voice', 'instruction'],
              'description': zh
                  ? '只在该类型内搜索。省略则搜索全部类型。'
                  : 'Search only within this type. Omit to search all types.',
            },
            'limit': {
              'type': 'integer',
              'minimum': 1,
              'maximum': 20,
              'description': zh
                  ? '最多返回多少条，默认 10。'
                  : 'Maximum number of entries to return. Default 10.',
            },
          },
          'required': ['query'],
        },
      },
    };
  }

  static Map<String, dynamic> _defMemoryEdit(MemoryPromptLang lang) {
    final zh = lang == MemoryPromptLang.zh;
    return {
      'type': 'function',
      'function': {
        'name': memoryEdit,
        'description': zh
            ? '修改一条已有记忆的内容。需要先用 memory_read 或 memory_search_profile 拿到条目 id（形如 mem_xxxxxxxx）。只在记忆内容确实过时或有错时使用；补充新信息请用 memory_update。'
            : 'Edit the content of an existing memory. First obtain the entry id (e.g. mem_xxxxxxxx) via memory_read or memory_search_profile. Use only when content is outdated or wrong; for new information use memory_update.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': zh
                  ? '条目 id，形如 mem_a1b2c3d4。'
                  : 'Entry id, e.g. mem_a1b2c3d4.',
            },
            'content': {
              'type': 'string',
              'description': zh
                  ? '修改后的完整内容，会整体替换原内容。'
                  : 'The full replacement content.',
            },
          },
          'required': ['id', 'content'],
        },
      },
    };
  }

  static Map<String, dynamic> _defMemoryDelete(MemoryPromptLang lang) {
    final zh = lang == MemoryPromptLang.zh;
    return {
      'type': 'function',
      'function': {
        'name': memoryDelete,
        'description': zh
            ? '归档一条记忆（软删除）。归档后不再出现在记忆摘要和搜索结果里，用户仍可以在设置中看到并恢复。需要先用 memory_read 或 memory_search_profile 拿到条目 id。只在用户明确表示某条记忆不再成立时使用。'
            : 'Archive a memory (soft delete). Archived entries disappear from the memory summary and search results, but the user can still see and restore them in settings. First obtain the entry id via memory_read or memory_search_profile. Use only when the user clearly says a memory no longer holds.',
        'parameters': {
          'type': 'object',
          'properties': {
            'id': {
              'type': 'string',
              'description': zh
                  ? '条目 id，形如 mem_a1b2c3d4。'
                  : 'Entry id, e.g. mem_a1b2c3d4.',
            },
          },
          'required': ['id'],
        },
      },
    };
  }

  static Map<String, dynamic> _defUpdateUserProfile(MemoryPromptLang lang) {
    final zh = lang == MemoryPromptLang.zh;
    return {
      'type': 'function',
      'function': {
        'name': updateUserProfile,
        'description': zh
            ? '更新用户画像字段。这些是最稳定的身份信息。不确定的时候不要写。'
            : 'Update user profile fields. These are the most stable identity facts. Do not write when uncertain.',
        'parameters': {
          'type': 'object',
          'properties': {
            'fields': {
              'type': 'array',
              'description': zh ? '要更新的字段列表。' : 'List of fields to update.',
              'items': {
                'type': 'object',
                'properties': {
                  'key': {
                    'type': 'string',
                    'description': zh
                        ? '可用字段：preferred_name（用户希望你怎么称呼他）、gender、pronouns、preferred_language、timezone、occupation、location。其他稳定字段用 custom.<名称>，名称只能是字母、数字、下划线或连字符。'
                        : 'Allowed keys: preferred_name (how the user wants to be addressed), gender, pronouns, preferred_language, timezone, occupation, location. Other stable fields use custom.<name> where name is letters, digits, underscore, or hyphen only.',
                  },
                  'value': {
                    'type': 'string',
                    'description': zh
                        ? '字段取值。传空字符串表示清除该字段。'
                        : 'Field value. An empty string clears the field.',
                  },
                },
                'required': ['key', 'value'],
              },
            },
          },
          'required': ['fields'],
        },
      },
    };
  }

  static Map<String, dynamic> _defChatSearch(MemoryPromptLang lang) {
    final zh = lang == MemoryPromptLang.zh;
    return {
      'type': 'function',
      'function': {
        'name': chatSearch,
        'description': zh
            ? '在历史对话中按关键词搜索消息内容（跨全部会话）。需要回忆之前聊过什么，或者用户提到「上次」「之前说的」「我们讨论过」时，优先使用这个工具。默认不搜索当前对话，因为当前对话的内容已经在上下文里。'
            : 'Search message content across past conversations by keywords. Prefer this when recalling prior discussion, or when the user mentions "last time", "earlier", or "we discussed". By default the current conversation is excluded because it is already in context.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': zh
                  ? '关键词，多个用空格分隔。'
                  : 'Keywords separated by spaces.',
            },
            'limit': {
              'type': 'integer',
              'minimum': 1,
              'maximum': 20,
              'description': zh
                  ? '最多返回多少条，默认 10。'
                  : 'Maximum number of results. Default 10.',
            },
            'conversation_id': {
              'type': 'string',
              'description': zh
                  ? '只在指定会话内搜索。省略则搜索除当前会话外的全部会话。'
                  : 'Search only within this conversation. Omit to search all conversations except the current one.',
            },
          },
          'required': ['query'],
        },
      },
    };
  }

  // —— Helpers ——

  static Map<String, dynamic> _entrySummary(
    MemoryEntry e, {
    required bool includeStatus,
  }) {
    return {
      'id': e.id,
      'type': MemoryEntry.typeToString(e.type),
      'scope': MemoryEntry.scopeToString(e.scope),
      if (includeStatus) 'status': MemoryEntry.statusToString(e.status),
      'content': e.content,
      'updatedAt': MemoryBlockBuilder.fmtDate(e.updatedAt),
    };
  }

  static bool _isVisible(MemoryEntry entry, String assistantId) {
    if (entry.scope == MemoryScope.global) return true;
    return entry.assistantId == assistantId;
  }

  static MemoryType? _parseMemoryType(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString();
    try {
      return MemoryEntry.typeFromString(s);
    } catch (_) {
      return null;
    }
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _snippet(String content, List<String> tokens) {
    final lower = content.toLowerCase();
    var idx = -1;
    var hitLen = 0;
    for (final t in tokens) {
      final i = lower.indexOf(t);
      if (i >= 0) {
        idx = i;
        hitLen = t.length;
        break;
      }
    }
    const radius = 40;
    if (idx < 0) {
      final cut = content.length <= 80 ? content : content.substring(0, 80);
      return '……$cut……';
    }
    final start = (idx - radius).clamp(0, content.length);
    final end = (idx + hitLen + radius).clamp(0, content.length);
    var snip = content.substring(start, end);
    if (start > 0) snip = '……$snip';
    if (end < content.length) snip = '$snip……';
    return snip;
  }
}
