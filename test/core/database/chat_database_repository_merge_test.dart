import 'dart:io';

import 'package:Kelivo/core/database/chat_database_repository.dart';
import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/core/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('ChatDatabaseRepository merge snapshot', () {
    late Directory directory;
    late ChatDatabaseRepository live;
    late ChatDatabaseRepository source;
    late File sourceFile;
    var sourceClosed = false;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('kelivo_merge_test_');
      live = ChatDatabaseRepository.open(
        file: File('${directory.path}/live.sqlite'),
      );
      sourceFile = File('${directory.path}/source.sqlite');
      source = ChatDatabaseRepository.open(file: sourceFile);
      sourceClosed = false;
      await live.ensureReady();
      await source.ensureReady();
    });

    tearDown(() async {
      await live.close();
      if (!sourceClosed) await source.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    Future<void> putConversation(
      ChatDatabaseRepository repository, {
      required String conversationId,
      required String title,
      required String messageId,
      required String content,
    }) {
      // Fixed instants: the fingerprint truncates timestamps to whole seconds,
      // so two DateTime.now() writes straddling a second boundary would stop
      // identical conversations from deduplicating.
      final anchor = DateTime.utc(2026, 8, 7, 12);
      return repository.putMigrationBatch(
        conversations: [
          Conversation(
            id: conversationId,
            title: title,
            createdAt: anchor,
            updatedAt: anchor,
            messageIds: [messageId],
            mcpServerIds: const ['server'],
            versionSelections: {messageId: 0},
          ),
        ],
        messages: [
          (
            message: ChatMessage(
              id: messageId,
              role: 'assistant',
              content: content,
              conversationId: conversationId,
              timestamp: anchor,
            ),
            messageOrder: 0,
          ),
        ],
        toolEventsByMessageId: {
          messageId: [
            {'id': 'tool', 'content': content},
          ],
        },
        geminiSignaturesByMessageId: {messageId: 'sig-$content'},
      );
    }

    /// Two messages whose text, reasoning and tool payloads differ. Both carry
    /// the same thought signature on purpose: a swapped-body variant must then
    /// differ only in which revision owns which part, leaving part grouping as
    /// the sole thing the fingerprint can tell them apart by.
    Future<void> putTwoMessageConversation(
      ChatDatabaseRepository repository, {
      required String conversationId,
      required String firstMessageId,
      required String secondMessageId,
      required String firstBody,
      required String secondBody,
    }) {
      final anchor = DateTime.utc(2026, 8, 7, 12);
      ChatMessage message(String id, String body, int index) => ChatMessage(
        id: id,
        role: 'assistant',
        content: '$body content',
        reasoningText: '$body reasoning',
        conversationId: conversationId,
        timestamp: anchor.add(Duration(minutes: index)),
      );
      return repository.putMigrationBatch(
        conversations: [
          Conversation(
            id: conversationId,
            title: 'Two messages',
            createdAt: anchor,
            updatedAt: anchor,
            messageIds: [firstMessageId, secondMessageId],
            mcpServerIds: const ['server'],
            versionSelections: {firstMessageId: 0, secondMessageId: 0},
          ),
        ],
        messages: [
          (message: message(firstMessageId, firstBody, 0), messageOrder: 0),
          (message: message(secondMessageId, secondBody, 1), messageOrder: 1),
        ],
        toolEventsByMessageId: {
          firstMessageId: [
            {'id': 'tool', 'content': '$firstBody tool'},
          ],
          secondMessageId: [
            {'id': 'tool', 'content': '$secondBody tool'},
          ],
        },
        geminiSignaturesByMessageId: {
          firstMessageId: 'sig-shared',
          secondMessageId: 'sig-shared',
        },
      );
    }

    Future<void> reopenLive() async {
      await live.close();
      live = ChatDatabaseRepository.open(
        file: File('${directory.path}/live.sqlite'),
      );
      await live.ensureReady();
    }

    test('无冲突 conversation 原 ID 导入且 order/关联数据完整', () async {
      await putConversation(
        source,
        conversationId: 'source-conversation',
        title: 'Source',
        messageId: 'source-message',
        content: 'answer',
      );
      await source.close();
      sourceClosed = true;

      final report = await live.mergeBackupSnapshot(sourceFile);

      expect(report.importedConversations, 1);
      expect(report.remappedConversations, 0);
      final conversation = await live.getConversation('source-conversation');
      expect(conversation?.messageIds, const ['source-message']);
      expect(
        (await live.getMessagesRange(
          'source-conversation',
          start: 0,
          limit: 10,
        )).single.content,
        'answer',
      );
      expect(await live.getToolEvents('source-message'), const [
        {'id': 'tool', 'content': 'answer'},
      ]);
      expect(
        await live.getGeminiThoughtSignature('source-message'),
        'sig-answer',
      );
    });

    test('相同 ID 与内容按 hash 去重，重复导入保持幂等', () async {
      for (final repository in [live, source]) {
        await putConversation(
          repository,
          conversationId: 'same-conversation',
          title: 'Same',
          messageId: 'same-message',
          content: 'same',
        );
      }
      await source.close();
      sourceClosed = true;

      final first = await live.mergeBackupSnapshot(sourceFile);
      final second = await live.mergeBackupSnapshot(sourceFile);

      expect(first.deduplicatedConversations, 1);
      expect(second.deduplicatedConversations, 1);
      expect(await live.getAllConversations(), hasLength(1));
    });

    test('多消息会话 parts 按 revision 分组后指纹一致，重复导入去重', () async {
      for (final repository in [live, source]) {
        await putTwoMessageConversation(
          repository,
          conversationId: 'multi',
          firstMessageId: 'multi-a',
          secondMessageId: 'multi-b',
          firstBody: 'alpha',
          secondBody: 'beta',
        );
      }
      await source.close();
      sourceClosed = true;

      final report = await live.mergeBackupSnapshot(sourceFile);

      expect(report.deduplicatedConversations, 1);
      expect(await live.getAllConversations(), hasLength(1));
    });

    test('多消息会话正文互换后指纹不同，不会被误判为重复', () async {
      // Both sides hold the same multiset of text/reasoning/tool payloads, the
      // same signature and the same per-position timestamps, and differ only in
      // which message owns which payload. A fingerprint that pooled parts per
      // conversation instead of per revision would hash these equal and
      // silently drop the imported conversation as a duplicate.
      await putTwoMessageConversation(
        live,
        conversationId: 'swap',
        firstMessageId: 'swap-a',
        secondMessageId: 'swap-b',
        firstBody: 'alpha',
        secondBody: 'beta',
      );
      await putTwoMessageConversation(
        source,
        conversationId: 'swap',
        firstMessageId: 'swap-a',
        secondMessageId: 'swap-b',
        firstBody: 'beta',
        secondBody: 'alpha',
      );
      await source.close();
      sourceClosed = true;

      final report = await live.mergeBackupSnapshot(sourceFile);

      expect(report.deduplicatedConversations, 0);
      expect(report.importedConversations, 1);
      final remappedId = report.remappedConversationIds['swap'];
      expect(remappedId, isNotNull);
      expect(await live.getAllConversations(), hasLength(2));

      expect(
        (await live.getMessagesRange('swap', start: 0, limit: 10))
            .map((message) => message.content)
            .toList(),
        const ['alpha content', 'beta content'],
      );
      final imported = await live.getMessagesRange(
        remappedId!,
        start: 0,
        limit: 10,
      );
      expect(
        imported.map((message) => message.content).toList(),
        const ['beta content', 'alpha content'],
      );
      expect(
        imported.map((message) => message.reasoningText).toList(),
        const ['beta reasoning', 'alpha reasoning'],
      );
      expect(await live.getToolEvents(imported.first.id), const [
        {'id': 'tool', 'content': 'beta tool'},
      ]);
    });

    test('同 conversation ID 异内容时整会话 remap 并可重复去重', () async {
      await putConversation(
        live,
        conversationId: 'collision',
        title: 'Local',
        messageId: 'local-message',
        content: 'local',
      );
      await putConversation(
        source,
        conversationId: 'collision',
        title: 'Imported',
        messageId: 'imported-message',
        content: 'imported',
      );
      await source.close();
      sourceClosed = true;

      final first = await live.mergeBackupSnapshot(sourceFile);
      final remappedId = first.remappedConversationIds['collision'];
      expect(remappedId, isNotNull);
      final remapped = await live.getConversation(remappedId!);
      expect(remapped?.title, 'Imported');
      expect(remapped?.messageIds.single, startsWith('merge-'));
      expect(remapped?.versionSelections.keys.single, startsWith('merge-'));
      expect(await live.getToolEvents(remapped!.messageIds.single), const [
        {'id': 'tool', 'content': 'imported'},
      ]);

      final second = await live.mergeBackupSnapshot(sourceFile);
      expect(second.importedConversations, 0);
      expect(second.deduplicatedConversations, 1);
      expect(await live.getAllConversations(), hasLength(2));
    });

    test('conversation ID 可用但 message ID 冲突时整会话 remap', () async {
      await putConversation(
        live,
        conversationId: 'local-conversation',
        title: 'Local',
        messageId: 'shared-message',
        content: 'local',
      );
      await putConversation(
        source,
        conversationId: 'source-conversation',
        title: 'Imported',
        messageId: 'shared-message',
        content: 'imported',
      );
      await source.close();
      sourceClosed = true;

      final report = await live.mergeBackupSnapshot(sourceFile);
      final remappedId = report.remappedConversationIds['source-conversation'];

      expect(remappedId, isNotNull);
      expect(await live.getConversation('source-conversation'), isNull);
      final remapped = await live.getConversation(remappedId!);
      expect(remapped?.messageIds.single, startsWith('merge-'));
      expect(
        (await live.getMessagesRange(
          remappedId,
          start: 0,
          limit: 1,
        )).single.content,
        'imported',
      );
    });

    test('迁移批写入后工具事件与签名物化进 parts/artifacts 可读', () async {
      await putConversation(
        live,
        conversationId: 'materialized',
        title: 'Materialized',
        messageId: 'materialized-message',
        content: 'answer',
      );

      await reopenLive();

      expect(await live.getToolEvents('materialized-message'), const [
        {'id': 'tool', 'content': 'answer'},
      ]);
      expect(
        await live.getGeminiThoughtSignature('materialized-message'),
        'sig-answer',
      );
    });

    test('merge 拷贝 parts/artifacts，无 legacy 表时仍可读', () async {
      await putConversation(
        source,
        conversationId: 'artifact-conversation',
        title: 'Artifacts',
        messageId: 'artifact-message',
        content: 'answer',
      );
      await source.upsertImageOcrArtifactItems(
        revisionId: 'artifact-message',
        items: const {'hash-1': 'ocr text'},
      );
      await source.close();
      sourceClosed = true;

      final report = await live.mergeBackupSnapshot(sourceFile);
      expect(report.importedConversations, 1);

      await reopenLive();

      expect(await live.getToolEvents('artifact-message'), const [
        {'id': 'tool', 'content': 'answer'},
      ]);
      expect(
        await live.getGeminiThoughtSignature('artifact-message'),
        'sig-answer',
      );
      expect(await live.getImageOcrArtifacts(const ['artifact-message']), {
        'artifact-message': {'hash-1': 'ocr text'},
      });
    });

    test('remap 时 group_id 为 null 的 v0 与后续版本仍属同一版本组', () async {
      await putConversation(
        live,
        conversationId: 'versioned',
        title: 'Local',
        messageId: 'local-message',
        content: 'local',
      );

      // 生产形态：v0 不显式传 id，因此 group_id 落库为 NULL。
      final v0 = ChatMessage(
        role: 'assistant',
        content: 'v0',
        conversationId: 'versioned',
      );
      await source.putMigrationBatch(
        conversations: [
          Conversation(
            id: 'versioned',
            title: 'Imported',
            messageIds: [v0.id],
          ),
        ],
        messages: [(message: v0, messageOrder: 0)],
        toolEventsByMessageId: const {},
        geminiSignaturesByMessageId: const {},
      );
      final appended = await source.appendMessageVersion(
        messageId: v0.id,
        content: 'v1',
      );
      expect(appended, isNotNull);
      await source.close();
      sourceClosed = true;

      final report = await live.mergeBackupSnapshot(sourceFile);
      final remappedId = report.remappedConversationIds['versioned'];
      expect(remappedId, isNotNull);

      final projections = await live.getSelectedMessageProjections(remappedId!);
      expect(projections, hasLength(1));
      expect(projections.single.content, 'v1');
      expect(
        await live.getMaxMessageVersionForGroup(
          remappedId,
          projections.single.groupId!,
        ),
        1,
      );

      final second = await live.mergeBackupSnapshot(sourceFile);
      expect(second.importedConversations, 0);
      expect(second.deduplicatedConversations, 1);
      expect(await live.getAllConversations(), hasLength(2));
    });

    test('非法 order 在事务写入前拒绝且 live 不变', () async {
      await putConversation(
        live,
        conversationId: 'local',
        title: 'Local',
        messageId: 'local-message',
        content: 'local',
      );
      await putConversation(
        source,
        conversationId: 'invalid',
        title: 'Invalid',
        messageId: 'invalid-message',
        content: 'invalid',
      );
      await source.close();
      sourceClosed = true;
      final raw = sqlite.sqlite3.open(sourceFile.path);
      try {
        raw.execute(
          'UPDATE message_rows SET message_order = 2 '
          "WHERE id = 'invalid-message';",
        );
      } finally {
        raw.close();
      }

      await expectLater(
        live.mergeBackupSnapshot(sourceFile),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'conversation_message_order',
          ),
        ),
      );

      expect(await live.getConversation('local'), isNotNull);
      expect(await live.getConversation('invalid'), isNull);
      expect(await live.getAllConversations(), hasLength(1));
    });
  });
}
