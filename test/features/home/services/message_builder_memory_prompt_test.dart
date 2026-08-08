import 'dart:convert';

import 'package:Kelivo/core/database/app_database.dart';
import 'package:Kelivo/core/database/business_data.dart';
import 'package:Kelivo/core/database/business_preferences.dart';
import 'package:Kelivo/core/database/business_repository.dart';
import 'package:Kelivo/core/database/chat_database_repository.dart';
import 'package:Kelivo/core/models/assistant.dart';
import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/core/models/conversation.dart';
import 'package:Kelivo/core/models/memory_entry.dart';
import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/core/services/chat/chat_service.dart';
import 'package:Kelivo/core/services/memory/memory_block_builder.dart';
import 'package:Kelivo/core/services/memory/memory_prompts.dart';
import 'package:Kelivo/features/home/services/message_builder_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChatService extends ChatService {
  _FakeChatService(this.persistedMessages);

  final List<ChatMessage> persistedMessages;

  @override
  List<ChatMessage> getMessages(String conversationId) {
    return persistedMessages
        .where((message) => message.conversationId == conversationId)
        .toList();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;
  late BusinessRepository businessRepository;
  late BusinessPreferences preferences;
  late ChatDatabaseRepository chatRepository;
  late SettingsProvider settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;'),
      ),
    );
    businessRepository = BusinessRepository(database);
    preferences = BusinessPreferences(businessRepository);
    chatRepository = ChatDatabaseRepository(database);
    await chatRepository.ensureReady();
    await preferences.load();
    settings = SettingsProvider(preferences);
    await settings.loaded;
    await settings.setMemoryPromptLang('zh');
  });

  tearDown(() => database.close());

  Future<void> seedAssistant(String id) async {
    final raw = preferences.getString(BusinessEntityKind.assistant.sourceKey);
    final list = <Map<String, dynamic>>[
      if (raw != null && raw.isNotEmpty)
        for (final item in jsonDecode(raw) as List)
          (item as Map).cast<String, dynamic>(),
    ];
    if (!list.any((item) => item['id'] == id)) {
      list.add({'id': id, 'name': id});
    }
    await preferences.setString(
      BusinessEntityKind.assistant.sourceKey,
      jsonEncode(list),
    );
  }

  Future<void> putEntry({
    required String id,
    required String content,
    MemoryType type = MemoryType.identity,
  }) {
    final created = DateTime.utc(2026, 8, 1).microsecondsSinceEpoch;
    return businessRepository.upsertEntity(
      BusinessEntityKind.memoryEntry,
      BusinessEntityValue(
        id: id,
        sortOrder: 0,
        payload: jsonEncode({
          'id': id,
          'scope': 'global',
          'assistantId': null,
          'type': MemoryEntry.typeToString(type),
          'status': 'active',
          'content': content,
          'source': 'manual',
          'relatedIds': <String>[],
          'createdAt': created,
          'updatedAt': created,
        }),
      ),
    );
  }

  Future<Conversation> seedConversation(
    String id, {
    String? injectedMemoryHash,
  }) async {
    final conversation = Conversation(
      id: id,
      title: id,
      injectedMemoryHash: injectedMemoryHash,
    );
    await chatRepository.putConversation(conversation);
    return conversation;
  }

  Future<ChatMessage> seedUserMessage({
    required String id,
    required String conversationId,
    String content = 'hi',
    DateTime? timestamp,
    int? messageOrder,
  }) async {
    final message = ChatMessage(
      id: id,
      role: 'user',
      content: content,
      conversationId: conversationId,
      timestamp: timestamp,
    );
    await chatRepository.putMessage(message, messageOrder: messageOrder);
    return message;
  }

  MessageBuilderService buildService({List<ChatMessage> messages = const []}) {
    return MessageBuilderService(
      chatService: _FakeChatService(messages),
      contextProvider: _FakeBuildContext(),
      chatRepository: chatRepository,
    );
  }

  const assistant = Assistant(
    id: 'assistant-1',
    name: 'Test',
    enableMemory: true,
    messageTemplate: '{{ message }}',
  );

  group('§18.1 item 6 — §7.6 decision table', () {
    test('enableMemory off returns empty and writes nothing', () async {
      await seedAssistant('assistant-1');
      await putEntry(id: 'mem_01', content: 'User likes Flutter.');
      final conversation = await seedConversation('conv-1');
      final service = buildService();

      final result = await service.resolveMemoryPrefix(
        conversation: conversation,
        assistant: assistant.copyWith(enableMemory: false),
        apiMessages: const [],
        currentMessageId: 'u-new',
        lang: MemoryPromptLang.zh,
      );

      expect(result.prefix, isEmpty);
      expect(result.hash, isNull);
      expect(conversation.injectedMemoryHash, isNull);
    });

    test(
      'empty profile and visible set returns empty without writing hash',
      () async {
        await seedAssistant('assistant-1');
        final conversation = await seedConversation('conv-1');
        final service = buildService();

        final result = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: const [],
          currentMessageId: 'u-new',
          lang: MemoryPromptLang.zh,
        );

        expect(result.prefix, isEmpty);
        expect(result.hash, isNull);
        expect(conversation.injectedMemoryHash, isNull);
      },
    );

    test('no snapshot in history → full snapshot', () async {
      await seedAssistant('assistant-1');
      await putEntry(id: 'mem_01', content: 'User likes Flutter.');
      final conversation = await seedConversation('conv-1');
      await seedUserMessage(id: 'u1', conversationId: 'conv-1');
      await seedUserMessage(
        id: 'u-new',
        conversationId: 'conv-1',
        content: 'next',
        messageOrder: 1,
      );
      final service = buildService();
      final apiMessages = [
        {
          'role': 'user',
          'content': 'hi',
          MessageBuilderService.internalRevisionIdKey: 'u1',
        },
        {'role': 'assistant', 'content': 'hello'},
        {
          'role': 'user',
          'content': 'next',
          MessageBuilderService.internalRevisionIdKey: 'u-new',
        },
      ];

      final result = await service.resolveMemoryPrefix(
        conversation: conversation,
        assistant: assistant,
        apiMessages: apiMessages,
        currentMessageId: 'u-new',
        lang: MemoryPromptLang.zh,
      );

      expect(result.prefix, contains(MemoryPrompts.introFullZh));
      expect(result.prefix, contains('<user_memory type="identity">'));
      expect(result.prefix, isNot(contains('<user_memory_update>')));
      expect(result.hash, isNotNull);
    });

    test('has snapshot + same hash → empty', () async {
      await seedAssistant('assistant-1');
      await putEntry(id: 'mem_01', content: 'User likes Flutter.');
      final fields = await chatRepository.readProfileFields();
      final visible = await chatRepository.queryVisibleMemories(
        assistantId: 'assistant-1',
      );
      final totals = await chatRepository.countVisibleMemoriesByType(
        assistantId: 'assistant-1',
      );
      final profileBlock = MemoryBlockBuilder.buildProfileBlock(
        fields: fields,
        lang: MemoryPromptLang.zh,
      );
      final memoryBlock = MemoryBlockBuilder.buildMemoryBlock(
        visible: visible,
        totalByType: totals,
        lang: MemoryPromptLang.zh,
      );
      final hash = MemoryBlockBuilder.hashBlocks(profileBlock, memoryBlock);

      final conversation = await seedConversation(
        'conv-1',
        injectedMemoryHash: hash,
      );
      await seedUserMessage(id: 'u1', conversationId: 'conv-1');
      await seedUserMessage(
        id: 'u-new',
        conversationId: 'conv-1',
        content: 'next',
        messageOrder: 1,
      );
      await chatRepository.freezeMessagePrompt(
        revisionId: 'u1',
        conversationId: 'conv-1',
        payload: 'frozen',
        carriesMemorySnapshot: true,
        injectedMemoryHash: hash,
      );

      final service = buildService();
      final apiMessages = [
        {
          'role': 'user',
          'content': 'hi',
          MessageBuilderService.internalRevisionIdKey: 'u1',
        },
        {
          'role': 'user',
          'content': 'next',
          MessageBuilderService.internalRevisionIdKey: 'u-new',
        },
      ];

      final result = await service.resolveMemoryPrefix(
        conversation: conversation,
        assistant: assistant,
        apiMessages: apiMessages,
        currentMessageId: 'u-new',
        lang: MemoryPromptLang.zh,
      );

      expect(result.prefix, isEmpty);
      expect(result.hash, isNull);
    });

    test('has snapshot + different hash → update block', () async {
      await seedAssistant('assistant-1');
      await putEntry(id: 'mem_01', content: 'User likes Flutter.');
      final conversation = await seedConversation(
        'conv-1',
        injectedMemoryHash: 'oldhash012345678',
      );
      await seedUserMessage(id: 'u1', conversationId: 'conv-1');
      await seedUserMessage(
        id: 'u-new',
        conversationId: 'conv-1',
        content: 'next',
        messageOrder: 1,
      );
      await chatRepository.freezeMessagePrompt(
        revisionId: 'u1',
        conversationId: 'conv-1',
        payload: 'frozen-old',
        carriesMemorySnapshot: true,
        injectedMemoryHash: 'oldhash012345678',
      );

      final service = buildService();
      final apiMessages = [
        {
          'role': 'user',
          'content': 'hi',
          MessageBuilderService.internalRevisionIdKey: 'u1',
        },
        {
          'role': 'user',
          'content': 'next',
          MessageBuilderService.internalRevisionIdKey: 'u-new',
        },
      ];

      final result = await service.resolveMemoryPrefix(
        conversation: conversation,
        assistant: assistant,
        apiMessages: apiMessages,
        currentMessageId: 'u-new',
        lang: MemoryPromptLang.zh,
      );

      expect(result.prefix, contains(MemoryPrompts.introUpdateZh));
      expect(result.prefix, contains('<user_memory_update>'));
      expect(result.hash, isNotNull);
      expect(result.hash, isNot('oldhash012345678'));
    });

    test(
      'the prior hash is read from the database, not from the model',
      () async {
        // Callers pass `conversation.copyWith(...)` and nothing ever loads this
        // column back into the model, so a stale copy must not be trusted:
        // doing so makes every turn look like a change and re-sends the same
        // update block forever.
        await seedAssistant('assistant-1');
        await putEntry(id: 'mem_01', content: 'User likes Flutter.');
        final fields = await chatRepository.readProfileFields();
        final visible = await chatRepository.queryVisibleMemories(
          assistantId: 'assistant-1',
        );
        final totals = await chatRepository.countVisibleMemoriesByType(
          assistantId: 'assistant-1',
        );
        final hash = MemoryBlockBuilder.hashBlocks(
          MemoryBlockBuilder.buildProfileBlock(
            fields: fields,
            lang: MemoryPromptLang.zh,
          ),
          MemoryBlockBuilder.buildMemoryBlock(
            visible: visible,
            totalByType: totals,
            lang: MemoryPromptLang.zh,
          ),
        );

        await seedConversation('conv-1');
        await seedUserMessage(id: 'u1', conversationId: 'conv-1');
        await seedUserMessage(
          id: 'u-new',
          conversationId: 'conv-1',
          content: 'next',
          messageOrder: 1,
        );
        await chatRepository.freezeMessagePrompt(
          revisionId: 'u1',
          conversationId: 'conv-1',
          payload: 'frozen',
          carriesMemorySnapshot: true,
          injectedMemoryHash: hash,
        );

        // The model still carries the pre-freeze value.
        final staleConversation = Conversation(id: 'conv-1', title: 'conv-1');
        expect(staleConversation.injectedMemoryHash, isNull);

        final apiMessages = [
          {
            'role': 'user',
            'content': 'hi',
            MessageBuilderService.internalRevisionIdKey: 'u1',
          },
          {
            'role': 'user',
            'content': 'next',
            MessageBuilderService.internalRevisionIdKey: 'u-new',
          },
        ];
        final result = await buildService().resolveMemoryPrefix(
          conversation: staleConversation,
          assistant: assistant,
          apiMessages: apiMessages,
          currentMessageId: 'u-new',
          lang: MemoryPromptLang.zh,
        );

        expect(result.prefix, isEmpty);
        expect(result.hash, isNull);
      },
    );

    test(
      'a hash injected earlier in the same request is not re-injected',
      () async {
        // Temporary conversations never reach the database, so the prior hash
        // has to come from the request itself. Without that, every message
        // after the first repeats a byte-identical update block.
        await seedAssistant('assistant-1');
        await putEntry(id: 'mem_01', content: 'User likes Flutter.');
        final conversation = await seedConversation('conv-1');
        await seedUserMessage(id: 'u1', conversationId: 'conv-1');
        await seedUserMessage(
          id: 'u2',
          conversationId: 'conv-1',
          content: 'next',
          messageOrder: 1,
        );

        final service = buildService();
        final apiMessages = [
          {
            'role': 'user',
            'content': 'hi',
            MessageBuilderService.internalRevisionIdKey: 'u1',
          },
          {
            'role': 'user',
            'content': 'next',
            MessageBuilderService.internalRevisionIdKey: 'u2',
          },
        ];
        final pass = MemoryInjectionPass();

        final first = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: apiMessages,
          currentMessageId: 'u1',
          lang: MemoryPromptLang.zh,
          pass: pass,
        );
        pass.snapshotCarriers.add('u1');

        final second = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: apiMessages,
          currentMessageId: 'u2',
          lang: MemoryPromptLang.zh,
          pass: pass,
        );

        expect(first.prefix, contains(MemoryPrompts.introFullZh));
        expect(second.prefix, isEmpty);
        expect(second.hash, isNull);
      },
    );
  });

  group('hash ordering regression (appendix item 6)', () {
    test(
      'compares prior hash before writing — update is not silently empty',
      () async {
        await seedAssistant('assistant-1');
        await putEntry(id: 'mem_01', content: 'Original content.');
        final fields = await chatRepository.readProfileFields();
        final visible = await chatRepository.queryVisibleMemories(
          assistantId: 'assistant-1',
        );
        final totals = await chatRepository.countVisibleMemoriesByType(
          assistantId: 'assistant-1',
        );
        final oldHash = MemoryBlockBuilder.hashBlocks(
          MemoryBlockBuilder.buildProfileBlock(
            fields: fields,
            lang: MemoryPromptLang.zh,
          ),
          MemoryBlockBuilder.buildMemoryBlock(
            visible: visible,
            totalByType: totals,
            lang: MemoryPromptLang.zh,
          ),
        );

        final conversation = await seedConversation(
          'conv-1',
          injectedMemoryHash: oldHash,
        );
        await seedUserMessage(id: 'u1', conversationId: 'conv-1');
        await seedUserMessage(
          id: 'u-new',
          conversationId: 'conv-1',
          content: 'next',
          messageOrder: 1,
        );
        await chatRepository.freezeMessagePrompt(
          revisionId: 'u1',
          conversationId: 'conv-1',
          payload: 'snap',
          carriesMemorySnapshot: true,
          injectedMemoryHash: oldHash,
        );

        // Change memory so currentHash != oldHash.
        await putEntry(
          id: 'mem_01',
          content: 'Changed content that alters hash.',
        );

        final service = buildService();
        final apiMessages = [
          {
            'role': 'user',
            'content': 'hi',
            MessageBuilderService.internalRevisionIdKey: 'u1',
          },
          {
            'role': 'user',
            'content': 'next',
            MessageBuilderService.internalRevisionIdKey: 'u-new',
          },
        ];

        // If someone writes conversation.injectedMemoryHash = currentHash BEFORE
        // comparing, this returns '' and the model never sees the update.
        final result = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: apiMessages,
          currentMessageId: 'u-new',
          lang: MemoryPromptLang.zh,
        );

        expect(
          result.prefix,
          contains('<user_memory_update>'),
          reason:
              'Writing injectedMemoryHash before comparing makes the update '
              'branch unreachable (appendix item 6).',
        );
        expect(result.hash, isNot(oldHash));
      },
    );
  });

  group('§18.4 item 29 — promptContent immutability', () {
    test(
      'building the same message twice returns identical bytes; retry matches',
      () async {
        await seedAssistant('assistant-1');
        await putEntry(id: 'mem_01', content: 'User likes Flutter.');

        final ts = DateTime(2026, 8, 7, 14, 3, 22);
        final conversation = await seedConversation('conv-1');
        final message = await seedUserMessage(
          id: 'u1',
          conversationId: 'conv-1',
          content: 'hello world',
          timestamp: ts,
        );
        final service = buildService(messages: [message]);
        final apiMessages = [
          {
            'role': 'user',
            'content': 'hello world',
            MessageBuilderService.internalRevisionIdKey: 'u1',
          },
        ];

        final first = await service.resolvePromptContent(
          message: message,
          processedUserBody: 'hello world',
          assistant: assistant.copyWith(appendCurrentTimeToUserMessage: true),
          conversation: conversation,
          settings: settings,
          apiMessages: apiMessages,
        );
        final second = await service.resolvePromptContent(
          message: message,
          processedUserBody: 'hello world CHANGED',
          assistant: assistant.copyWith(
            appendCurrentTimeToUserMessage: true,
            messageTemplate: 'IGNORE {{ message }}',
          ),
          conversation: conversation,
          settings: settings,
          apiMessages: apiMessages,
        );
        // Retry path: same frozen row.
        final retry = await service.resolvePromptContent(
          message: message,
          processedUserBody: 'retry body',
          assistant: assistant,
          conversation: conversation,
          settings: settings,
          apiMessages: apiMessages,
        );

        expect(second, first);
        expect(retry, first);
        expect(first, contains('hello world'));
        expect(first, contains(MemoryPrompts.formatCurrentTimeTag(ts)));
        expect(first, contains('<user_memory type="identity">'));
      },
    );

    test(
      'first message of a fresh conversation gets the snapshot even when the '
      'chat cache is empty',
      () async {
        // ChatService only serves conversations already in its cache, so on a
        // brand new conversation the lookup misses. Falling back to an
        // unfrozen render silently dropped memory from the first turn, then
        // added it a turn later — rewriting history and losing the cache.
        await seedAssistant('assistant-1');
        await putEntry(id: 'mem_01', content: 'User likes Flutter.');

        final conversation = await seedConversation('conv-fresh');
        final message = await seedUserMessage(
          id: 'u1',
          conversationId: 'conv-fresh',
          content: 'what is my name',
        );

        // Empty cache, exactly as for a conversation created this turn.
        final service = buildService();
        final apiMessages = [
          {
            'role': 'user',
            'content': 'what is my name',
            MessageBuilderService.internalRevisionIdKey: 'u1',
          },
        ];

        await service.processUserMessagesForApi(
          apiMessages,
          settings,
          assistant,
          conversation: conversation,
          sourceMessages: [message],
        );

        final content = apiMessages.single['content'] as String;
        expect(content, contains(MemoryPrompts.introFullZh));
        expect(content, contains('<user_memory type="identity">'));
        expect(content, endsWith('what is my name'));

        // And it is frozen, so the next turn replays the same bytes.
        final frozen = await chatRepository.getMessagePrompt('u1');
        expect(frozen, isNotNull);
        expect(frozen!.payload, content);
        expect(frozen.carriesMemorySnapshot, isTrue);
      },
    );
  });

  group('§18.4 item 30 — self-heal after truncateIndex advances', () {
    test(
      'dropping snapshot-carrying message yields full snapshot next turn',
      () async {
        await seedAssistant('assistant-1');
        await putEntry(id: 'mem_01', content: 'User likes Flutter.');

        final conversation = await seedConversation('conv-1');
        await seedUserMessage(id: 'u1', conversationId: 'conv-1');
        await seedUserMessage(
          id: 'u2',
          conversationId: 'conv-1',
          content: 'again',
          messageOrder: 1,
        );
        await seedUserMessage(
          id: 'u3',
          conversationId: 'conv-1',
          content: 'after truncate',
          messageOrder: 2,
        );
        final service = buildService();

        // First turn: no history snapshot → full snapshot, freeze u1.
        final first = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: [
            {
              'role': 'user',
              'content': 'hi',
              MessageBuilderService.internalRevisionIdKey: 'u1',
            },
          ],
          currentMessageId: 'u1',
          lang: MemoryPromptLang.zh,
        );
        expect(first.prefix, contains(MemoryPrompts.introFullZh));
        await chatRepository.freezeMessagePrompt(
          revisionId: 'u1',
          conversationId: 'conv-1',
          payload: '${first.prefix}hi',
          carriesMemorySnapshot: true,
          injectedMemoryHash: first.hash,
        );

        // Same hash, snapshot still in apiMessages → empty.
        final same = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: [
            {
              'role': 'user',
              'content': 'hi',
              MessageBuilderService.internalRevisionIdKey: 'u1',
            },
            {
              'role': 'user',
              'content': 'again',
              MessageBuilderService.internalRevisionIdKey: 'u2',
            },
          ],
          currentMessageId: 'u2',
          lang: MemoryPromptLang.zh,
        );
        expect(same.prefix, isEmpty);

        // truncateIndex advanced: u1 left apiMessages → full snapshot again.
        final healed = await service.resolveMemoryPrefix(
          conversation: conversation,
          assistant: assistant,
          apiMessages: [
            {
              'role': 'user',
              'content': 'after truncate',
              MessageBuilderService.internalRevisionIdKey: 'u3',
            },
          ],
          currentMessageId: 'u3',
          lang: MemoryPromptLang.zh,
        );

        expect(healed.prefix, contains(MemoryPrompts.introFullZh));
        expect(healed.prefix, isNot(contains('<user_memory_update>')));
      },
    );
  });

  group('§11.1 system message stability', () {
    test(
      'system message is byte-identical before and after a memory is created',
      () async {
        await seedAssistant('assistant-1');
        final service = buildService();
        final apiBefore = <Map<String, dynamic>>[
          {'role': 'system', 'content': 'base system'},
        ];
        await service.injectMemoryAndRecentChats(
          apiBefore,
          assistant.copyWith(allowPastConversationRecall: true),
          settings: settings,
        );
        final before = (apiBefore.first['content'] ?? '').toString();

        await putEntry(id: 'mem_01', content: 'Brand new memory.');

        final apiAfter = <Map<String, dynamic>>[
          {'role': 'system', 'content': 'base system'},
        ];
        await service.injectMemoryAndRecentChats(
          apiAfter,
          assistant.copyWith(allowPastConversationRecall: true),
          settings: settings,
        );
        final after = (apiAfter.first['content'] ?? '').toString();

        expect(after, before);
        expect(before, contains('## 长期记忆'));
        expect(before, contains(MemoryPrompts.rulesPastConversationRecallZh));
        expect(before, isNot(contains('<memories>')));
        expect(before, isNot(contains('<recent_chats>')));
        expect(before, isNot(contains('当前时间是')));
      },
    );
  });
}
