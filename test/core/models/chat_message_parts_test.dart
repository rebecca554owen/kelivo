import 'package:flutter_test/flutter_test.dart';

import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/core/models/message_part.dart';

void main() {
  group('ChatMessage.parts as source of truth', () {
    test(
      'content-only constructor yields single TextPart and identical content',
      () {
        const body = 'hello\nworld';
        final message = ChatMessage(
          role: 'user',
          content: body,
          conversationId: 'c1',
        );

        expect(message.parts, hasLength(1));
        expect(message.parts.single, isA<TextPart>());
        expect((message.parts.single as TextPart).text, body);
        expect(message.content, body);
      },
    );

    test('content getter joins only TextPart payloads in order', () {
      final message = ChatMessage(
        role: 'user',
        conversationId: 'c1',
        parts: const [
          TextPart('a'),
          ImagePart(uri: '/tmp/a.png'),
          TextPart('b'),
          FilePart(uri: '/tmp/f.pdf', name: 'f.pdf'),
          TextPart('c'),
        ],
      );

      expect(message.content, 'abc');
    });

    test(
      'content has no independent storage — copyWith(content) rewrites parts',
      () {
        final original = ChatMessage(
          role: 'assistant',
          content: 'old',
          conversationId: 'c1',
        );
        final updated = original.copyWith(content: 'new');

        expect(updated.content, 'new');
        expect(updated.parts, hasLength(1));
        expect((updated.parts.single as TextPart).text, 'new');
        expect(identical(updated.parts, original.parts), isFalse);
      },
    );

    test('copyWith(content) rewrites text but keeps ImagePart attachments', () {
      final original = ChatMessage(
        role: 'user',
        conversationId: 'c1',
        parts: const [
          TextPart('old caption'),
          ImagePart(uri: '/tmp/a.png', mime: 'image/png'),
          FilePart(
            uri: '/tmp/spec.pdf',
            name: 'spec.pdf',
            mime: 'application/pdf',
          ),
        ],
      );
      final updated = original.copyWith(content: 'new caption');

      expect(updated.content, 'new caption');
      expect(updated.parts, hasLength(3));
      expect(updated.parts[0], isA<TextPart>());
      expect((updated.parts[0] as TextPart).text, 'new caption');
      expect(updated.parts[1], isA<ImagePart>());
      expect((updated.parts[1] as ImagePart).uri, '/tmp/a.png');
      expect(updated.parts[2], isA<FilePart>());
      expect((updated.parts[2] as FilePart).name, 'spec.pdf');
    });

    test('copyWith(content) preserves Image-before-Text ordinal', () {
      final original = ChatMessage(
        role: 'user',
        conversationId: 'c1',
        parts: const [
          ImagePart(uri: '/tmp/a.png', mime: 'image/png'),
          TextPart('old caption'),
        ],
      );
      final updated = original.copyWith(content: 'new caption');

      expect(updated.content, 'new caption');
      expect(updated.parts, hasLength(2));
      expect(updated.parts[0], isA<ImagePart>());
      expect((updated.parts[0] as ImagePart).uri, '/tmp/a.png');
      expect(updated.parts[1], isA<TextPart>());
      expect((updated.parts[1] as TextPart).text, 'new caption');
    });

    test(
      'partsWithReplacedText collapses later TextParts and prepends when absent',
      () {
        final withExtras = ChatMessage.partsWithReplacedText(const [
          ImagePart(uri: '/tmp/a.png', mime: 'image/png'),
          TextPart('a'),
          FilePart(
            uri: '/tmp/b.bin',
            name: 'b.bin',
            mime: 'application/octet-stream',
          ),
          TextPart('b'),
        ], 'merged');
        expect(withExtras, hasLength(3));
        expect(withExtras[0], isA<ImagePart>());
        expect(withExtras[1], isA<TextPart>());
        expect((withExtras[1] as TextPart).text, 'merged');
        expect(withExtras[2], isA<FilePart>());

        final noText = ChatMessage.partsWithReplacedText(const [
          ImagePart(uri: '/tmp/a.png', mime: 'image/png'),
        ], 'added');
        expect(noText, hasLength(2));
        expect(noText[0], isA<TextPart>());
        expect((noText[0] as TextPart).text, 'added');
        expect(noText[1], isA<ImagePart>());
      },
    );

    test('copyWith without content/parts keeps existing parts', () {
      final original = ChatMessage(
        role: 'user',
        conversationId: 'c1',
        parts: const [
          TextPart('keep'),
          ImagePart(uri: '/tmp/a.png'),
        ],
      );
      final updated = original.copyWith(isStreaming: true);

      expect(updated.isStreaming, isTrue);
      expect(updated.content, 'keep');
      expect(updated.parts, hasLength(2));
      expect(updated.parts[0], isA<TextPart>());
      expect((updated.parts[0] as TextPart).text, 'keep');
      expect(updated.parts[1], isA<ImagePart>());
    });

    test('parts list is unmodifiable', () {
      final message = ChatMessage(
        role: 'user',
        content: 'x',
        conversationId: 'c1',
      );
      expect(
        () => message.parts.add(const TextPart('y')),
        throwsUnsupportedError,
      );
    });

    test(
      'toJson/fromJson preserves structured parts via encodePayload contract',
      () {
        final original = ChatMessage(
          id: 'm1',
          role: 'user',
          conversationId: 'c1',
          parts: const [
            TextPart('hello'),
            ImagePart(uri: '/tmp/a.png', mime: 'image/png'),
            FilePart(
              uri: '/tmp/spec.pdf',
              name: 'spec.pdf',
              mime: 'application/pdf',
            ),
          ],
        );

        final json = original.toJson();
        expect(json['content'], 'hello');
        expect(json['parts'], isA<List>());
        final encodedParts = json['parts'] as List;
        expect(encodedParts, hasLength(3));
        expect(encodedParts[0], {'kind': 'text', 'payload': 'hello'});
        expect(encodedParts[1]['kind'], 'image');
        expect(encodedParts[2]['kind'], 'file');

        final restored = ChatMessage.fromJson(json);
        expect(restored.parts, hasLength(3));
        expect(restored.parts[0], isA<TextPart>());
        expect((restored.parts[0] as TextPart).text, 'hello');
        expect(restored.parts[1], isA<ImagePart>());
        expect((restored.parts[1] as ImagePart).uri, '/tmp/a.png');
        expect((restored.parts[1] as ImagePart).mime, 'image/png');
        expect(restored.parts[2], isA<FilePart>());
        final file = restored.parts[2] as FilePart;
        expect(file.uri, '/tmp/spec.pdf');
        expect(file.name, 'spec.pdf');
        expect(file.mime, 'application/pdf');
        // No marker strings in payloads.
        for (final part in restored.parts) {
          expect(part.encodePayload().contains('[image:'), isFalse);
          expect(part.encodePayload().contains('[file:'), isFalse);
        }
      },
    );

    test(
      'fromJson without parts keeps legacy content for import-boundary decode',
      () {
        final restored = ChatMessage.fromJson({
          'id': 'm2',
          'role': 'user',
          'content': 'hi\n[image:/tmp/a.png]',
          'timestamp': DateTime.utc(2026, 1, 1).toIso8601String(),
          'conversationId': 'c1',
        });
        expect(restored.parts, hasLength(1));
        expect(restored.parts.single, isA<TextPart>());
        expect(restored.content, contains('[image:/tmp/a.png]'));
      },
    );

    test(
      'fromJson reports message and part context for malformed backup data',
      () {
        const payload =
            '{"uri":"/tmp/spec.pdf","name":"spec.pdf","mime":["/private/spec.pdf"]}';
        expect(
          () => ChatMessage.fromJson({
            'id': 'message-malformed-backup',
            'role': 'user',
            'parts': const [
              {'kind': 'text', 'payload': 'before'},
              {'kind': 'file', 'payload': payload},
            ],
            'timestamp': DateTime.utc(2026, 8, 10).toIso8601String(),
            'conversationId': 'conversation-backup',
          }),
          throwsA(
            isA<FormatException>()
                .having(
                  (error) => error.message,
                  'message context',
                  allOf(
                    contains('messageId=message-malformed-backup'),
                    contains('ordinal=1'),
                    contains('kind=file'),
                    contains('parseError=invalid_mime'),
                  ),
                )
                .having(
                  (error) => error.message,
                  'redacted payload',
                  isNot(contains('/private/spec.pdf')),
                ),
          ),
        );
      },
    );
  });
}
