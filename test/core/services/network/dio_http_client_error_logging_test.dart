import 'dart:convert';
import 'dart:io';

import 'package:Kelivo/core/services/network/dio_http_client.dart';
import 'package:Kelivo/core/services/network/request_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform previousPathProvider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kelivo_dio_error_logs_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
    RequestLogger.saveOutput = false;
    await RequestLogger.setEnabled(true);
  });

  tearDown(() async {
    await RequestLogger.setEnabled(false);
    PathProviderPlatform.instance = previousPathProvider;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<String> waitForLog(List<String> expected) async {
    final file = File('${tempDir.path}/logs/logs.txt');
    for (var attempt = 0; attempt < 50; attempt++) {
      if (await file.exists()) {
        final content = await file.readAsString();
        if (expected.every(content.contains)) return content;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    return file.existsSync() ? file.readAsStringSync() : '';
  }

  test('HTTP error body is logged when saveOutput is off', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).drain<void>();
      request.response.statusCode = 401;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'error': {'message': 'invalid api key'},
        }),
      );
      await request.response.close();
    });

    await HttpOverrides.runZoned(
      () async {
        final client = DioHttpClient();
        addTearDown(client.close);
        final uri = Uri.parse('http://127.0.0.1:${server.port}/chat');
        final response = await client.send(http.Request('POST', uri));
        await response.stream.bytesToString();
      },
      createHttpClient: (context) =>
          _RealHttpOverrides().createHttpClient(context),
    );

    final log = await waitForLog(const ['status=401', 'invalid api key']);
    expect(log, contains('status=401'));
    expect(log, contains('invalid api key'));
    expect(log, isNot(contains('chunk=')));
  });

  test('successful stream body is not logged when saveOutput is off', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).drain<void>();
      request.response.statusCode = 200;
      request.response.write('data: unique-success-chunk-xyz\n\n');
      await request.response.close();
    });

    await HttpOverrides.runZoned(
      () async {
        final client = DioHttpClient();
        addTearDown(client.close);
        final uri = Uri.parse('http://127.0.0.1:${server.port}/chat');
        final response = await client.send(http.Request('POST', uri));
        await response.stream.bytesToString();
      },
      createHttpClient: (context) =>
          _RealHttpOverrides().createHttpClient(context),
    );

    final log = await waitForLog(const ['status=200', 'done']);
    expect(log, contains('status=200'));
    expect(log, isNot(contains('unique-success-chunk-xyz')));
    expect(log, isNot(contains('chunk=')));
  });

  test('Authorization and query keys are redacted before write', () async {
    const rawKey = 'sk-test-redact-unique-key-zzzz';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      await utf8.decoder.bind(request).drain<void>();
      request.response.statusCode = 401;
      request.response.headers.set('set-cookie', 'sid=$rawKey; Path=/');
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'error': {'message': 'invalid api key'},
        }),
      );
      await request.response.close();
    });

    await HttpOverrides.runZoned(
      () async {
        final client = DioHttpClient();
        addTearDown(client.close);
        final uri = Uri.parse(
          'http://127.0.0.1:${server.port}/chat?key=$rawKey',
        );
        final request = http.Request('POST', uri);
        request.headers['Authorization'] = 'Bearer $rawKey';
        request.headers['x-goog-api-key'] = rawKey;
        request.body = jsonEncode({'api_key': rawKey, 'prompt': 'hi'});
        final response = await client.send(request);
        await response.stream.bytesToString();
      },
      createHttpClient: (context) =>
          _RealHttpOverrides().createHttpClient(context),
    );

    final log = await waitForLog(const ['status=401', 'headers=']);
    expect(log, contains('status=401'));
    expect(log, isNot(contains(rawKey)));
    expect(log, contains('***'));
  });
}
