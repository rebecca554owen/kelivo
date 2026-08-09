import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:Kelivo/core/database/chat_database_repository.dart';
import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/core/models/conversation.dart';
import 'package:Kelivo/core/models/message_part.dart';

void main() {
  late Directory root;
  late ChatDatabaseRepository repository;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('chat_parts_roundtrip_');
    repository = ChatDatabaseRepository.open(
      file: File('${root.path}/parts.sqlite'),
    );
    await repository.ensureReady();
  });

  tearDown(() async {
    await repository.close();
    await root.delete(recursive: true);
  });

  test('text+image+file parts roundtrip preserves order and payload', () async {
    final now = DateTime.utc(2026, 8, 9, 12);
    const conversationId = 'conversation-parts';
    const messageId = 'message-parts';
    final conversation = Conversation(
      id: conversationId,
      title: 'Parts',
      createdAt: now,
      updatedAt: now,
      messageIds: const [messageId],
    );
    final message = ChatMessage(
      id: messageId,
      role: 'user',
      conversationId: conversationId,
      timestamp: now,
      parts: const [
        TextPart('帮我看看'),
        ImagePart(
          uri: '/tmp/a.png',
          mime: 'image/png',
          assetId: 'asset-image',
        ),
        FilePart(
          uri: '/tmp/spec.pdf',
          name: 'spec.pdf',
          mime: 'application/pdf',
          assetId: 'asset-file',
        ),
        TextPart('谢谢'),
      ],
    );

    await repository.putMigrationBatch(
      conversations: [conversation],
      messages: [(message: message, messageOrder: 0)],
      toolEventsByMessageId: const {},
      geminiSignaturesByMessageId: const {},
    );

    final reloaded = await repository.getMessage(messageId);
    expect(reloaded, isNotNull);
    expect(reloaded!.content, '帮我看看谢谢');
    expect(reloaded.parts, hasLength(4));

    expect(reloaded.parts[0], isA<TextPart>());
    expect((reloaded.parts[0] as TextPart).text, '帮我看看');

    expect(reloaded.parts[1], isA<ImagePart>());
    final image = reloaded.parts[1] as ImagePart;
    expect(image.uri, '/tmp/a.png');
    expect(image.mime, 'image/png');
    expect(image.assetId, 'asset-image');
    expect(image.unavailable, isFalse);

    expect(reloaded.parts[2], isA<FilePart>());
    final file = reloaded.parts[2] as FilePart;
    expect(file.uri, '/tmp/spec.pdf');
    expect(file.name, 'spec.pdf');
    expect(file.mime, 'application/pdf');
    expect(file.assetId, 'asset-file');
    expect(file.unavailable, isFalse);

    expect(reloaded.parts[3], isA<TextPart>());
    expect((reloaded.parts[3] as TextPart).text, '谢谢');

    // Encode payloads must match the domain model contract exactly.
    for (var i = 0; i < message.parts.length; i++) {
      expect(
        reloaded.parts[i].encodePayload(),
        message.parts[i].encodePayload(),
      );
      expect(reloaded.parts[i].kind, message.parts[i].kind);
    }
  });

  test('attachment parts mark asset references dirty without marker strings', () async {
    final now = DateTime.utc(2026, 8, 9, 13);
    const conversationId = 'conversation-dirty';
    const messageId = 'message-dirty';
    await repository.putMigrationBatch(
      conversations: [
        Conversation(
          id: conversationId,
          title: 'Dirty',
          createdAt: now,
          updatedAt: now,
          messageIds: const [messageId],
        ),
      ],
      messages: [
        (
          message: ChatMessage(
            id: messageId,
            role: 'user',
            conversationId: conversationId,
            timestamp: now,
            parts: const [
              TextPart('plain text only — no markers'),
              ImagePart(uri: '/tmp/b.png', mime: 'image/png'),
            ],
          ),
          messageOrder: 0,
        ),
      ],
      toolEventsByMessageId: const {},
      geminiSignaturesByMessageId: const {},
    );

    expect(await repository.hasPendingAssetReferenceSync(), isTrue);
  });
  test('appendMessageVersion content-only keeps prior ImagePart', () async {
    final now = DateTime.utc(2026, 8, 9, 14);
    const conversationId = 'conversation-append-parts';
    const messageId = 'message-append-parts';
    await repository.putMigrationBatch(
      conversations: [
        Conversation(
          id: conversationId,
          title: 'Append',
          createdAt: now,
          updatedAt: now,
          messageIds: const [messageId],
        ),
      ],
      messages: [
        (
          message: ChatMessage(
            id: messageId,
            role: 'user',
            conversationId: conversationId,
            timestamp: now,
            groupId: messageId,
            version: 0,
            parts: const [
              ImagePart(uri: '/tmp/keep.png', mime: 'image/png'),
              TextPart('original caption'),
            ],
          ),
          messageOrder: 0,
        ),
      ],
      toolEventsByMessageId: const {},
      geminiSignaturesByMessageId: const {},
    );

    final result = await repository.appendMessageVersion(
      messageId: messageId,
      content: 'edited caption',
    );
    expect(result, isNotNull);
    final persisted = await repository.getMessage(result!.message.id);
    expect(persisted, isNotNull);
    expect(persisted!.content, 'edited caption');
    expect(persisted.parts, hasLength(2));
    expect(persisted.parts[0], isA<ImagePart>());
    expect((persisted.parts[0] as ImagePart).uri, '/tmp/keep.png');
    expect((persisted.parts[0] as ImagePart).mime, 'image/png');
    expect(persisted.parts[1], isA<TextPart>());
    expect((persisted.parts[1] as TextPart).text, 'edited caption');
  });

  test('unknown future_widget part persists and writes back unchanged', () async {
    final now = DateTime.utc(2026, 8, 9, 14);
    const conversationId = 'conversation-unknown';
    const messageId = 'message-unknown';
    const unknownPayload = '{"widget":"chart","v":2}';
    final message = ChatMessage(
      id: messageId,
      role: 'assistant',
      conversationId: conversationId,
      timestamp: now,
      parts: const [
        TextPart('hello'),
        UnknownPart(rawKind: 'future_widget', payload: unknownPayload),
      ],
    );

    await repository.putMigrationBatch(
      conversations: [
        Conversation(
          id: conversationId,
          title: 'Unknown',
          createdAt: now,
          updatedAt: now,
          messageIds: const [messageId],
        ),
      ],
      messages: [(message: message, messageOrder: 0)],
      toolEventsByMessageId: const {},
      geminiSignaturesByMessageId: const {},
    );

    final reloaded = await repository.getMessage(messageId);
    expect(reloaded, isNotNull);
    expect(reloaded!.parts, hasLength(2));
    expect(reloaded.parts[1], isA<UnknownPart>());
    final unknown = reloaded.parts[1] as UnknownPart;
    expect(unknown.kind, 'future_widget');
    expect(unknown.rawKind, 'future_widget');
    expect(unknown.payload, unknownPayload);
    expect(unknown.encodePayload(), unknownPayload);

    // Write back unchanged.
    await repository.putMigrationBatch(
      conversations: [
        Conversation(
          id: conversationId,
          title: 'Unknown',
          createdAt: now,
          updatedAt: now,
          messageIds: const [messageId],
        ),
      ],
      messages: [(message: reloaded, messageOrder: 0)],
      toolEventsByMessageId: const {},
      geminiSignaturesByMessageId: const {},
    );

    final again = await repository.getMessage(messageId);
    expect(again, isNotNull);
    expect(again!.parts[1], isA<UnknownPart>());
    expect(again.parts[1].kind, 'future_widget');
    expect(again.parts[1].encodePayload(), unknownPayload);

    final raw = sqlite.sqlite3.open('${root.path}/parts.sqlite');
    try {
      final rows = raw.select(
        "SELECT kind, payload FROM message_part_rows "
        "WHERE revision_id = '$messageId' ORDER BY ordinal;",
      );
      expect(rows.map((row) => row['kind']).toList(), ['text', 'future_widget']);
      expect(rows[1]['payload'], unknownPayload);
    } finally {
      raw.close();
    }
  });

}
