@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:mcp_client/mcp_client.dart';
import 'package:mcp_client/src/transport/event_source.dart';
import 'package:test/test.dart';

void main() {
  group('Native SSE transport', () {
    test(
      'keeps an event intact when its fields arrive in separate chunks',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final eventSource = EventSource();
        final endpoint = Completer<String?>();

        addTearDown(() async {
          eventSource.close();
          await server.close(force: true);
        });

        server.listen((request) async {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.write('event: endpoint\r\n');
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 25));
          request.response.write(
            'data: /messages/?session_id=server-session\n',
          );
          await request.response.flush();
          await Future<void>.delayed(const Duration(milliseconds: 25));
          request.response.write('\r\n');
          await request.response.close();
        });

        await eventSource.connect(
          'http://${server.address.address}:${server.port}/sse',
          onEndpoint: (value) {
            if (!endpoint.isCompleted) {
              endpoint.complete(value);
            }
          },
        );

        expect(
          await endpoint.future.timeout(const Duration(seconds: 1)),
          '/messages/?session_id=server-session',
        );
      },
    );

    test('sends legacy SSE messages as exact application/json', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final receivedContentType = Completer<String?>();
      SseClientTransport? transport;

      addTearDown(() async {
        transport?.close();
        await server.close(force: true);
      });

      server.listen((request) async {
        if (request.method == 'GET') {
          request.response.headers.contentType = ContentType(
            'text',
            'event-stream',
          );
          request.response.write(
            'event: endpoint\n'
            'data: /messages/?session_id=server-session\n\n',
          );
          await request.response.close();
          return;
        }

        receivedContentType.complete(
          request.headers.value(HttpHeaders.contentTypeHeader),
        );
        await request.drain<void>();
        request.response.statusCode = HttpStatus.accepted;
        await request.response.close();
      });

      transport = await SseClientTransport.create(
        serverUrl: 'http://${server.address.address}:${server.port}/sse',
      );
      transport.send({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'});

      expect(
        await receivedContentType.future.timeout(const Duration(seconds: 1)),
        'application/json',
      );
    });
  });
}
