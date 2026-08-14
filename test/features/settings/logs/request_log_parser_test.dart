import 'package:Kelivo/features/settings/logs/request_log_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses error response body into the viewer entry', () {
    const content = '''
[2026-08-13 20:40:00.000] [REQ 1] POST https://api.example.com/v1/chat
[2026-08-13 20:40:00.010] [RES 1] status=401
[2026-08-13 20:40:00.011] [RES 1] body={"error":{"message":"invalid api key"}}
[2026-08-13 20:40:00.012] [RES 1] done
''';

    final entries = RequestLogParser.parse(content);
    expect(entries, hasLength(1));
    expect(entries.single.statusCode, 401);
    expect(entries.single.responseBody, contains('invalid api key'));
    expect(entries.single.errors.single, contains('invalid api key'));
    expect(entries.single.hasError, isTrue);
  });
}
