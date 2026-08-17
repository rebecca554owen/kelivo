import 'package:Kelivo/core/models/message_part.dart';
import 'package:Kelivo/features/home/controllers/streaming_content_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StreamingContentData treats equal part values as equal', () {
    const a = StreamingContentData(
      content: 'hi',
      totalTokens: 1,
      parts: [TextPart('hi'), ReasoningPart('plan')],
    );
    const b = StreamingContentData(
      content: 'hi',
      totalTokens: 1,
      parts: [TextPart('hi'), ReasoningPart('plan')],
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
