import 'dart:io';

import 'package:Kelivo/core/database/chat_database_repository.dart';
import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/core/models/message_part.dart';
import 'package:Kelivo/core/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  group('sandbox path migration version', () {
    late Directory directory;
    late File dbFile;
    late ChatDatabaseRepository repository;
    var repositoryClosed = false;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'kelivo_sandbox_path_migration_',
      );
      dbFile = File('${directory.path}/chat.sqlite');
      repository = ChatDatabaseRepository.open(file: dbFile);
      repositoryClosed = false;
      await repository.ensureReady();
      await repository.putMigrationBatch(
        conversations: [
          Conversation(
            id: 'conversation',
            title: 'Paths',
            messageIds: const ['plain', 'path'],
          ),
        ],
        messages: [
          (
            message: ChatMessage(
              id: 'plain',
              conversationId: 'conversation',
              role: 'user',
              content: 'plain text',
            ),
            messageOrder: 0,
          ),
          (
            message: ChatMessage(
              id: 'path',
              conversationId: 'conversation',
              role: 'user',
              parts: const [
                ImagePart(uri: '/old/sandboxoldtoken/a.png'),
              ],
            ),
            messageOrder: 1,
          ),
        ],
        toolEventsByMessageId: const {},
        geminiSignaturesByMessageId: const {},
      );
    });

    tearDown(() async {
      if (!repositoryClosed) await repository.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('首次按批迁移并在同一事务写 version receipt', () async {
      final result = await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/new',
        batchSize: 1,
        rewriteUri: (uri) =>
            uri.replaceFirst('/old/sandboxoldtoken/', '/new/sandboxnewtoken/'),
      );

      expect(result.ran, isTrue);
      expect(result.scannedMessages, 1);
      expect(result.updatedMessages, 1);
      final migrated = (await repository.getMessagesRange(
        'conversation',
        start: 0,
        limit: 10,
      )).last;
      expect(migrated.parts.whereType<ImagePart>().single.uri,
          '/new/sandboxnewtoken/a.png');
    });

    test('同版本后续启动不读取候选消息', () async {
      await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/same',
        rewriteUri: (uri) => uri,
      );

      final result = await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/same',
        rewriteUri: (_) => throw StateError('must_not_scan'),
      );

      expect(result.ran, isFalse);
      expect(result.scannedMessages, 0);
    });

    test('rewrite 失败回滚内容且不写 receipt，可重试', () async {
      await expectLater(
        repository.migrateSandboxPaths(
          targetVersion: 1,
          targetRoot: '/new',
          rewriteUri: (_) => throw StateError('rewrite_failed'),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'rewrite_failed',
          ),
        ),
      );

      final retry = await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/new',
        rewriteUri: (uri) =>
            uri.replaceFirst('/old/sandboxoldtoken/', '/new/sandboxnewtoken/'),
      );
      expect(retry.ran, isTrue);
      expect(retry.updatedMessages, 1);
    });

    test('同版本目标根变化时重新执行一次', () async {
      await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/first',
        rewriteUri: (uri) => uri,
      );

      final result = await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/second',
        rewriteUri: (uri) => uri.replaceFirst(
          '/old/sandboxoldtoken/',
          '/second/sandboxnewtoken/',
        ),
      );

      expect(result.ran, isTrue);
      expect(result.updatedMessages, 1);
    });

    test('路径重写后 ImagePart URI 更新且 FTS 索引完整', () async {
      await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: '/new',
        rewriteUri: (uri) =>
            uri.replaceFirst('/old/sandboxoldtoken/', '/new/sandboxnewtoken/'),
      );

      final migrated = (await repository.getMessagesRange(
        'conversation',
        start: 0,
        limit: 10,
      )).last;
      expect(
        migrated.parts.whereType<ImagePart>().single.uri,
        '/new/sandboxnewtoken/a.png',
      );
      // Text remains searchable; attachment URIs live outside text FTS.
      expect(
        (await repository.searchConversationMatches(
          tokens: const ['plain'],
        )).single.messageId,
        'plain',
      );

      // Force FTS setup path, then integrity-check on a raw connection.
      await repository.searchConversationMatches(
        tokens: const ['__fts_integrity__'],
      );
      await repository.close();
      repositoryClosed = true;
      final database = sqlite.sqlite3.open(dbFile.path);
      try {
        database.execute(
          "INSERT INTO message_search_fts(message_search_fts) "
          "VALUES('integrity-check');",
        );
      } finally {
        database.close();
      }
    });


    test('stale unavailable cleared when rewritten local file exists', () async {
      final newFile = File('${directory.path}/sandboxnewtoken/a.png');
      await newFile.parent.create(recursive: true);
      await newFile.writeAsBytes(const <int>[0x89, 0x50, 0x4E, 0x47]);

      await repository.putMigrationBatch(
        conversations: [
          Conversation(
            id: 'unavailable-conversation',
            title: 'Unavailable',
            messageIds: const ['unavailable-path'],
          ),
        ],
        messages: [
          (
            message: ChatMessage(
              id: 'unavailable-path',
              conversationId: 'unavailable-conversation',
              role: 'user',
              parts: [
                ImagePart(
                  uri: '/old/sandboxoldtoken/a.png',
                  unavailable: true,
                ),
              ],
            ),
            messageOrder: 0,
          ),
        ],
        toolEventsByMessageId: const {},
        geminiSignaturesByMessageId: const {},
      );

      await repository.migrateSandboxPaths(
        targetVersion: 1,
        targetRoot: directory.path,
        rewriteUri: (uri) => uri.replaceFirst(
          '/old/sandboxoldtoken/',
          '${directory.path}/sandboxnewtoken/',
        ),
      );

      final migrated = (await repository.getMessagesRange(
        'unavailable-conversation',
        start: 0,
        limit: 10,
      )).single;
      final image = migrated.parts.whereType<ImagePart>().single;
      expect(image.uri, newFile.path);
      expect(image.unavailable, isFalse);
    });
    test('拒绝高于当前实现的已有 migration version', () async {
      await repository.migrateSandboxPaths(
        targetVersion: 2,
        targetRoot: '/future',
        rewriteUri: (uri) => uri,
      );

      await expectLater(
        repository.migrateSandboxPaths(
          targetVersion: 1,
          targetRoot: '/current',
          rewriteUri: (uri) => uri,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'sandbox_path_migration_version',
          ),
        ),
      );
    });
  });
}
