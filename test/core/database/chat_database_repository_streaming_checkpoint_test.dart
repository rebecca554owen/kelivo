import 'dart:io';

import 'package:Kelivo/core/database/chat_database_repository.dart';
import 'package:Kelivo/core/database/generation_run.dart';
import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/core/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('ChatDatabaseRepository streaming checkpoint', () {
    late Directory directory;
    late ChatDatabaseRepository repository;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'kelivo_streaming_checkpoint_test_',
      );
      repository = ChatDatabaseRepository.open(
        file: File('${directory.path}/chat.sqlite'),
      );
      await repository.ensureReady();
      await repository.putMigrationBatch(
        conversations: [
          Conversation(
            id: 'conversation',
            title: 'Conversation',
            messageIds: const ['first', 'streaming'],
          ),
        ],
        messages: [
          (
            message: ChatMessage(
              id: 'first',
              role: 'user',
              content: 'question',
              conversationId: 'conversation',
            ),
            messageOrder: 0,
          ),
          (
            message: ChatMessage(
              id: 'streaming',
              role: 'assistant',
              content: '',
              conversationId: 'conversation',
              isStreaming: true,
            ),
            messageOrder: 1,
          ),
        ],
        toolEventsByMessageId: const {},
        geminiSignaturesByMessageId: const {},
      );
    });

    tearDown(() async {
      await repository.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('一次事务写入完整消息快照和 tool events 且不改变顺序', () async {
      final snapshot = ChatMessage(
        id: 'streaming',
        role: 'assistant',
        content: 'partial answer',
        conversationId: 'conversation',
        isStreaming: true,
        totalTokens: 12,
        reasoningText: 'thinking',
      );

      await repository.updateStreamingCheckpoint(snapshot, const [
        {
          'id': 'tool-1',
          'name': 'search',
          'arguments': {'q': 'kelivo'},
          'content': 'result',
        },
      ]);

      final messages = await repository.getMessagesByIds(const [
        'first',
        'streaming',
      ]);
      expect(messages.map((message) => message.id), const [
        'first',
        'streaming',
      ]);
      expect(messages.last.content, 'partial answer');
      expect(messages.last.totalTokens, 12);
      expect(messages.last.reasoningText, 'thinking');
      expect(await repository.getToolEvents('streaming'), const [
        {
          'id': 'tool-1',
          'name': 'search',
          'arguments': {'q': 'kelivo'},
          'content': 'result',
        },
      ]);

      final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        final parts = raw.select(
          "SELECT kind FROM message_part_rows WHERE revision_id = "
          "'streaming' ORDER BY ordinal;",
        );
        expect(parts.map((row) => row['kind']), const [
          'reasoning',
          'tool_call',
          'text',
        ]);
        expect(
          raw
              .select(
                "SELECT COUNT(*) AS c FROM message_part_rows "
                "WHERE kind = 'tool_result';",
              )
              .single['c'],
          0,
        );
      } finally {
        raw.close();
      }

      final authoritative = await repository.getMessage('streaming');
      expect(authoritative?.content, 'partial answer');
      expect(authoritative?.reasoningText, 'thinking');
    });

    test('已 finalize 的消息不会被迟到的流式 checkpoint 复活', () async {
      // Terminal write commits the finalized (non-streaming) content.
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'streaming',
          role: 'assistant',
          content: 'final answer',
          conversationId: 'conversation',
          isStreaming: false,
        ),
        const [],
      );

      // A late flush replays a stale streaming snapshot for the same revision.
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'streaming',
          role: 'assistant',
          content: 'stale partial',
          conversationId: 'conversation',
          isStreaming: true,
        ),
        const [],
      );

      final message = await repository.getMessage('streaming');
      expect(message?.content, 'final answer');
      expect(message?.isStreaming, isFalse);

      final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        expect(
          raw
              .select(
                "SELECT is_streaming FROM message_rows WHERE id = 'streaming';",
              )
              .single['is_streaming'],
          0,
        );
      } finally {
        raw.close();
      }
    });

    test('不存在的消息不会被 checkpoint 意外插入', () async {
      await expectLater(
        repository.updateStreamingCheckpoint(
          ChatMessage(
            id: 'missing',
            role: 'assistant',
            content: 'orphan',
            conversationId: 'conversation',
            isStreaming: true,
          ),
          const [],
        ),
        throwsA(anything),
      );

      expect(await repository.getMessagesByIds(const ['missing']), isEmpty);
    });

    test('cold start 一次事务清理未登记 flag 和孤儿 tracking metadata', () async {
      final createdAt = DateTime.now().toUtc();
      await repository.createGenerationRun(
        id: 'abandoned-run',
        conversationId: 'conversation',
        targetRevisionId: 'streaming',
        createdAt: createdAt,
      );
      await repository.transitionGenerationRun(
        id: 'abandoned-run',
        expectedState: GenerationRunState.preparing,
        expectedStateRevision: 0,
        nextState: GenerationRunState.requesting,
        updatedAt: createdAt.add(const Duration(milliseconds: 1)),
      );
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'streaming',
          role: 'assistant',
          content: 'preserved partial',
          conversationId: 'conversation',
          isStreaming: true,
        ),
        const [],
        generationRunId: 'abandoned-run',
        checkpointSeq: 1,
      );

      expect(await repository.resetStaleStreamingState(), 1);

      final message = await repository.getMessage('streaming');
      expect(message?.isStreaming, isFalse);
      expect(message?.content, 'preserved partial');
      final run = await repository.getGenerationRun('abandoned-run');
      expect(run?.state, GenerationRunState.interrupted);
      expect(run?.stateRevision, 2);
      expect(run?.checkpointSeq, 1);
      expect(run?.errorCode, 'app_restart');
      expect(await repository.getActiveStreamingIds(), isEmpty);
    });

    test('active generation projection comes only from run rows', () async {
      final createdAt = DateTime.now().toUtc();
      await repository.createGenerationRun(
        id: 'first-run',
        conversationId: 'conversation',
        targetRevisionId: 'first',
        createdAt: createdAt,
      );
      await repository.createGenerationRun(
        id: 'streaming-run',
        conversationId: 'conversation',
        targetRevisionId: 'streaming',
        createdAt: createdAt,
      );

      expect(
        await repository.getActiveStreamingIds(),
        containsAll(['first', 'streaming']),
      );
      final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        expect(
          raw.select(
            "SELECT value FROM chat_storage_meta_rows "
            "WHERE key = 'active_streaming_ids';",
          ),
          isEmpty,
        );
      } finally {
        raw.close();
      }
    });

    test('tool parts 未变化时 checkpoint 跳过重写且内容等价', () async {
      const toolEvents = [
        {
          'id': 'tool-1',
          'name': 'search',
          'arguments': {'q': 'kelivo'},
          'content': 'result',
        },
      ];
      ChatMessage snapshot(String content) => ChatMessage(
        id: 'streaming',
        role: 'assistant',
        content: content,
        conversationId: 'conversation',
        isStreaming: true,
        reasoningText: 'thinking',
      );

      await repository.updateStreamingCheckpoint(
        snapshot('draft one'),
        toolEvents,
      );
      List<Map<String, Object?>> toolPartRows() {
        final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
        try {
          return raw
              .select(
                "SELECT kind, payload, ordinal, updated_at FROM "
                "message_part_rows WHERE revision_id = 'streaming' AND "
                "kind = 'tool_call' ORDER BY ordinal;",
              )
              .map(
                (row) => <String, Object?>{
                  'kind': row['kind'],
                  'payload': row['payload'],
                  'ordinal': row['ordinal'],
                  'updated_at': row['updated_at'],
                },
              )
              .toList();
        } finally {
          raw.close();
        }
      }

      final before = toolPartRows();
      expect(before.map((row) => row['kind']), const ['tool_call']);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repository.updateStreamingCheckpoint(
        snapshot('draft two is longer'),
        toolEvents,
      );

      // Unchanged tool parts keep their rows (updated_at untouched); only the
      // text part is rewritten.
      expect(toolPartRows(), before);
      final persisted = await repository.getMessage('streaming');
      expect(persisted?.content, 'draft two is longer');
      expect(persisted?.reasoningText, 'thinking');
      expect(await repository.getToolEvents('streaming'), toolEvents);
    });

    test('tool events 变化时回退全量重建', () async {
      ChatMessage snapshot(String content) => ChatMessage(
        id: 'streaming',
        role: 'assistant',
        content: content,
        conversationId: 'conversation',
        isStreaming: true,
      );

      await repository.updateStreamingCheckpoint(snapshot('draft'), const [
        {'id': 'tool-1', 'content': 'first'},
      ]);
      int firstToolUpdatedAt() {
        final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
        try {
          return raw
                  .select(
                    "SELECT updated_at FROM message_part_rows WHERE "
                    "revision_id = 'streaming' AND kind = 'tool_call' "
                    "ORDER BY ordinal LIMIT 1;",
                  )
                  .single['updated_at']
              as int;
        } finally {
          raw.close();
        }
      }

      final before = firstToolUpdatedAt();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await repository.updateStreamingCheckpoint(snapshot('draft two'), const [
        {'id': 'tool-1', 'content': 'first'},
        {'id': 'tool-2', 'content': 'second'},
      ]);

      expect(firstToolUpdatedAt(), isNot(before));
      expect(await repository.getToolEvents('streaming'), const [
        {'id': 'tool-1', 'content': 'first'},
        {'id': 'tool-2', 'content': 'second'},
      ]);
      expect((await repository.getMessage('streaming'))?.content, 'draft two');
    });

    test('message_rows 不再包含 content / reasoning_text 影子列', () async {
      final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        final columns = raw
            .select('PRAGMA table_info(message_rows);')
            .map((row) => row['name'] as String)
            .toSet();
        expect(columns.contains('content'), isFalse);
        expect(columns.contains('reasoning_text'), isFalse);
      } finally {
        raw.close();
      }
    });

    test('任何写入路径都不会产生 tool_result part', () async {
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'streaming',
          role: 'assistant',
          content: 'with tools',
          conversationId: 'conversation',
          isStreaming: true,
          reasoningText: 'think',
        ),
        const [
          {
            'id': 'tool-1',
            'name': 'search',
            'arguments': {'q': 'x'},
            'content': 'result body',
          },
        ],
      );
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'streaming',
          role: 'assistant',
          content: 'final with tools',
          conversationId: 'conversation',
          isStreaming: false,
          reasoningText: 'think',
        ),
        const [
          {
            'id': 'tool-1',
            'name': 'search',
            'arguments': {'q': 'x'},
            'content': 'result body',
          },
        ],
      );
      await repository.updateMessageFields(
        'streaming',
        content: 'edited with tools',
      );

      final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        expect(
          raw
              .select(
                "SELECT COUNT(*) AS c FROM message_part_rows "
                "WHERE kind = 'tool_result';",
              )
              .single['c'],
          0,
        );
        expect(
          raw
              .select(
                "SELECT kind FROM message_part_rows "
                "WHERE revision_id = 'streaming' ORDER BY ordinal;",
              )
              .map((row) => row['kind']),
          const ['reasoning', 'tool_call', 'text'],
        );
      } finally {
        raw.close();
      }
    });

    test('崩溃恢复后 parts 可读且 FTS 可搜索', () async {
      final createdAt = DateTime.now().toUtc();
      await repository.createGenerationRun(
        id: 'crashed-run',
        conversationId: 'conversation',
        targetRevisionId: 'streaming',
        createdAt: createdAt,
      );
      await repository.transitionGenerationRun(
        id: 'crashed-run',
        expectedState: GenerationRunState.preparing,
        expectedStateRevision: 0,
        nextState: GenerationRunState.requesting,
        updatedAt: createdAt.add(const Duration(milliseconds: 1)),
      );
      final requesting = await repository.getGenerationRun('crashed-run');
      await repository.transitionGenerationRun(
        id: 'crashed-run',
        expectedState: GenerationRunState.requesting,
        expectedStateRevision: requesting!.stateRevision,
        nextState: GenerationRunState.streaming,
        updatedAt: createdAt.add(const Duration(milliseconds: 2)),
      );
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'streaming',
          role: 'assistant',
          content: 'interrupted crash-recovery-token partial',
          conversationId: 'conversation',
          isStreaming: true,
          reasoningText: 'interrupted reasoning trail',
        ),
        const [],
        generationRunId: 'crashed-run',
        checkpointSeq: 1,
      );

      // Simulate process kill: message still streaming with checkpointed parts.
      final midCrash = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        expect(
          midCrash
              .select(
                "SELECT is_streaming FROM message_rows WHERE id = 'streaming';",
              )
              .single['is_streaming'],
          1,
        );
        expect(
          midCrash
              .select(
                "SELECT payload FROM message_part_rows "
                "WHERE revision_id = 'streaming' AND kind = 'text';",
              )
              .single['payload'],
          'interrupted crash-recovery-token partial',
        );
      } finally {
        midCrash.close();
      }

      expect(await repository.resetStaleStreamingState(), 1);

      final message = await repository.getMessage('streaming');
      expect(message?.isStreaming, isFalse);
      expect(message?.content, 'interrupted crash-recovery-token partial');
      expect(message?.reasoningText, 'interrupted reasoning trail');
      final run = await repository.getGenerationRun('crashed-run');
      expect(run?.state, GenerationRunState.interrupted);

      expect(
        (await repository.searchConversationMatches(
          tokens: const ['crash-recovery-token'],
        )).single.messageId,
        'streaming',
      );

      await repository.close();
      final raw = sqlite.sqlite3.open('${directory.path}/chat.sqlite');
      try {
        raw.execute(
          "INSERT INTO message_search_fts(message_search_fts) "
          "VALUES('integrity-check');",
        );
      } finally {
        raw.close();
      }
      // Re-open so tearDown can close a live repository handle.
      repository = ChatDatabaseRepository.open(
        file: File('${directory.path}/chat.sqlite'),
      );
      await repository.ensureReady();
    });

    test('reasoning finishing mid-stream keeps earlier tool parts', () async {
      // Gemini pattern: reasoning streams first and stops updating once tool
      // calls begin. The reasoning part must not be treated as "gone" just
      // because the checkpoint message still carries the pre-allocated
      // reasoningStartAt timestamp with null text.
      await repository.putMigrationBatch(
        conversations: [
          Conversation(
            id: 'conv-gemini',
            title: 'Gemini',
            messageIds: const ['assistant-1'],
          ),
        ],
        messages: [
          (
            message: ChatMessage(
              id: 'assistant-1',
              conversationId: 'conv-gemini',
              role: 'assistant',
              content: '',
              isStreaming: true,
            ),
            messageOrder: 0,
          ),
        ],
        toolEventsByMessageId: const {},
        geminiSignaturesByMessageId: const {},
      );

      // Checkpoint 1: reasoning actively streaming.
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'assistant-1',
          conversationId: 'conv-gemini',
          role: 'assistant',
          content: '',
          isStreaming: true,
          reasoningText: 'let me think',
          reasoningStartAt: DateTime.utc(2026, 7, 28, 10),
        ),
        const [],
      );

      // Checkpoint 2: reasoning done, tool call arrives.
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'assistant-1',
          conversationId: 'conv-gemini',
          role: 'assistant',
          content: '',
          isStreaming: true,
          reasoningText: 'let me think',
          reasoningStartAt: DateTime.utc(2026, 7, 28, 10),
          reasoningFinishedAt: DateTime.utc(2026, 7, 28, 10, 0, 3),
        ),
        const [
          {'id': 'call-1', 'name': 'search', 'arguments': '{"q":"x"}'},
        ],
      );

      // Checkpoint 3 (the Gemini regression): reasoning text null but the
      // pre-allocated reasoningStartAt timestamp still set; tool result in.
      await repository.updateStreamingCheckpoint(
        ChatMessage(
          id: 'assistant-1',
          conversationId: 'conv-gemini',
          role: 'assistant',
          content: '',
          isStreaming: true,
          reasoningText: null,
          reasoningStartAt: DateTime.utc(2026, 7, 28, 10),
          reasoningFinishedAt: DateTime.utc(2026, 7, 28, 10, 0, 3),
        ),
        const [
          {'id': 'call-1', 'name': 'search', 'arguments': '{"q":"x"}'},
          {'id': 'call-1', 'name': 'search', 'content': 'result payload'},
        ],
      );

      expect(await repository.getToolEvents('assistant-1'), hasLength(2));
      final message = await repository.getMessage('assistant-1');
      expect(message?.reasoningText, 'let me think');
    });
  });
}
