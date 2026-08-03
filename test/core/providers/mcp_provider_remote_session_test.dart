import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Kelivo/core/providers/mcp_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

import '../../support/business_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test(
    'safe refresh retries once and merges notification bursts',
    () async {
      final server = await _MockMcpServer.start(
        failFirstToolsList: true,
        sendToolsChangedBurst: true,
      );
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'initial tools: ${server._counts}',
        );
        await _waitUntil(() => server.burstSent, label: 'notification burst');
        await _waitUntil(
          () => server.count('tools/list') >= 3,
          label: 'coalesced refresh: ${server._counts}',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(server.count('initialize'), 1);
        expect(server.count('tools/list'), 3);
        expect(server.maxConcurrentToolsList, 1);
        expect(
          server.toolsListRequestTimes[1].difference(
            server.toolsListRequestTimes[0],
          ),
          greaterThanOrEqualTo(const Duration(milliseconds: 1900)),
        );

        server.coordinateCooldown = true;
        final olderSuccess = provider.callTool(id, 'slow-success', const {});
        await _waitUntil(
          () => server.count('tools/call') == 1,
          label: 'older tool call',
        );
        final limited = await provider.callTool(id, 'limited', const {});
        final callsAfterLimit = server.count('tools/call');
        expect((await olderSuccess)?.isError, isFalse);
        expect(provider.isInCooldown(id), isTrue);
        final blocked = await provider.callTool(id, 'echo', const {});

        expect(limited?.isError, isTrue);
        expect(blocked?.isError, isTrue);
        expect(provider.isInCooldown(id), isTrue);
        expect(server.count('tools/call'), callsAfterLimit);
        expect(server.count('initialize'), 1);
      } finally {
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 12)),
  );

  test(
    'unknown tool result is never replayed after a socket drop',
    () async {
      final server = await _MockMcpServer.start(dropFirstToolResponse: true);
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'initial tools: ${server._counts}',
        );

        final result = await provider.callTool(id, 'side-effect', const {});

        expect(result?.isError, isTrue);
        expect(
          (result!.content.single as mcp.TextContent).text,
          contains('result is unknown'),
        );
        expect(server.count('tools/call'), 1);
        expect(server.count('initialize'), 1);
      } finally {
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );

  test(
    'connect and manual reconnect are single-flight',
    () async {
      final firstInitializeGate = Completer<void>();
      final server = await _MockMcpServer.start(
        firstInitializeGate: firstInitializeGate,
      );
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => server.count('initialize') == 1,
          label: 'first initialize: ${server._counts}',
        );

        final reconnect = provider.reconnect(id);
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(server.count('initialize'), 1);
        firstInitializeGate.complete();

        expect(
          await reconnect.timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw StateError(
              'reconnect stuck: initialize=${server.count('initialize')} '
              'delete=${server.deleteCount} status=${provider.statusFor(id)}',
            ),
          ),
          isTrue,
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'reconnected tools: ${server._counts}',
        );
        expect(server.count('initialize'), 2);
        expect(server.maxConcurrentInitialize, 1);
        expect(server.deleteCount, 1);
      } finally {
        if (!firstInitializeGate.isCompleted) firstInitializeGate.complete();
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );

  test(
    'GET 404 replaces the expired session once',
    () async {
      final server = await _MockMcpServer.start(expireFirstGet: true);
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => server.count('initialize') == 2,
          label: 'replacement initialize',
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'replacement tools',
        );

        expect(server.count('initialize'), 2);
        expect(server.deleteCount, 0);
      } finally {
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );

  test(
    'concurrent session 404 responses share one replacement connection',
    () async {
      final server = await _MockMcpServer.start(
        rejectFirstSessionToolCalls: true,
      );
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'initial tools',
        );

        final results = await Future.wait([
          provider.callTool(id, 'echo', const {'value': 'a'}),
          provider.callTool(id, 'echo', const {'value': 'b'}),
        ]);

        expect(results, everyElement(isNotNull));
        expect(results.map((result) => result!.isError), everyElement(isFalse));
        expect(server.count('initialize'), 2);
        expect(server.count('tools/call'), 4);
      } finally {
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );

  test(
    'server without tools capability stays connected with an empty list',
    () async {
      final server = await _MockMcpServer.start(supportsTools: false);
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Resources only',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => provider.statusFor(id) == McpStatus.connected,
          label: 'resources-only connection',
        );

        expect(provider.getById(id)?.tools, isEmpty);
        expect(provider.errorFor(id), isNull);
        expect(server.count('tools/list'), 0);
      } finally {
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );

  test(
    'disabling returns before remote session termination finishes',
    () async {
      final deleteRelease = Completer<void>();
      final server = await _MockMcpServer.start(deleteRelease: deleteRelease);
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'initial tools',
        );

        final disabling = provider.updateServerMetadata(
          provider.getById(id)!.copyWith(enabled: false),
        );
        await _waitUntil(
          () => server.deleteCount == 1,
          label: 'session termination request',
        );
        await disabling.timeout(const Duration(milliseconds: 500));

        expect(provider.getById(id)?.enabled, isFalse);
        expect(provider.statusFor(id), McpStatus.idle);
        expect(deleteRelease.isCompleted, isFalse);
      } finally {
        if (!deleteRelease.isCompleted) deleteRelease.complete();
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );

  test(
    'cached tools reconnect lazily and preserve validation errors',
    () async {
      final server = await _MockMcpServer.start();
      final harness = await BusinessTestHarness.create();
      final provider = McpProvider(preferences: harness.preferences);

      try {
        await _waitUntil(
          () => provider.servers.isNotEmpty,
          label: 'provider load',
        );
        final id = await provider.addServer(
          enabled: true,
          name: 'Remote',
          transport: McpTransportType.http,
          url: server.url,
        );
        await _waitUntil(
          () => provider.getById(id)?.tools.length == 1,
          label: 'initial tools',
        );
        await provider.setToolNeedsApproval(id, 'echo', true);

        final invalid = await provider.callTool(id, 'invalid', const {});
        expect(invalid?.isError, isTrue);
        expect(
          (invalid!.content.single as mcp.TextContent).text,
          contains('missing value'),
        );

        await provider.disconnect(id, terminateSession: false);
        expect(provider.getEnabledToolsForServers({id}), hasLength(1));
        expect(provider.toolNeedsApproval('echo'), isTrue);

        final reconnected = await provider.callTool(id, 'echo', const {});
        expect(reconnected?.isError, isFalse);
        expect(server.count('initialize'), 2);
      } finally {
        provider.dispose();
        await harness.close();
        await server.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 8)),
  );
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String label = 'condition',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('$label was not met');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _MockMcpServer {
  final HttpServer _server;
  final bool failFirstToolsList;
  final bool sendToolsChangedBurst;
  final bool dropFirstToolResponse;
  final bool expireFirstGet;
  final bool rejectFirstSessionToolCalls;
  final bool supportsTools;
  final Completer<void>? firstInitializeGate;
  final Completer<void>? deleteRelease;
  final Map<String, int> _counts = {};
  final List<HttpResponse> _openStreams = [];
  late final Future<void> _serving;
  HttpResponse? _publicStream;
  bool _toolsListSucceeded = false;
  bool _burstSent = false;
  int _activeInitialize = 0;
  int _activeToolsList = 0;
  int maxConcurrentInitialize = 0;
  int maxConcurrentToolsList = 0;
  int deleteCount = 0;
  int _getCount = 0;
  final List<HttpResponse> _expiredToolResponses = [];
  final List<DateTime> toolsListRequestTimes = [];
  bool coordinateCooldown = false;

  bool get burstSent => _burstSent;

  _MockMcpServer._(
    this._server, {
    required this.failFirstToolsList,
    required this.sendToolsChangedBurst,
    required this.dropFirstToolResponse,
    required this.expireFirstGet,
    required this.rejectFirstSessionToolCalls,
    required this.supportsTools,
    required this.firstInitializeGate,
    required this.deleteRelease,
  }) {
    _serving = _serve();
  }

  static Future<_MockMcpServer> start({
    bool failFirstToolsList = false,
    bool sendToolsChangedBurst = false,
    bool dropFirstToolResponse = false,
    bool expireFirstGet = false,
    bool rejectFirstSessionToolCalls = false,
    bool supportsTools = true,
    Completer<void>? firstInitializeGate,
    Completer<void>? deleteRelease,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _MockMcpServer._(
      server,
      failFirstToolsList: failFirstToolsList,
      sendToolsChangedBurst: sendToolsChangedBurst,
      dropFirstToolResponse: dropFirstToolResponse,
      expireFirstGet: expireFirstGet,
      rejectFirstSessionToolCalls: rejectFirstSessionToolCalls,
      supportsTools: supportsTools,
      firstInitializeGate: firstInitializeGate,
      deleteRelease: deleteRelease,
    );
  }

  String get url => 'http://${_server.address.address}:${_server.port}/mcp';

  int count(String method) => _counts[method] ?? 0;

  Future<void> close() async {
    for (final response in _openStreams) {
      unawaited(response.close());
    }
    await _server.close(force: true);
    await _serving.timeout(const Duration(seconds: 1), onTimeout: () {});
  }

  Future<void> _serve() async {
    await for (final request in _server) {
      if (request.method == 'GET') {
        _getCount++;
        if (expireFirstGet && _getCount == 1) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }
        request.response.bufferOutput = false;
        request.response.headers.contentType = ContentType(
          'text',
          'event-stream',
        );
        request.response.write(': connected\n\n');
        await request.response.flush();
        _publicStream = request.response;
        _openStreams.add(request.response);
        unawaited(_maybeSendBurst());
        continue;
      }
      if (request.method == 'DELETE') {
        deleteCount++;
        await request.drain<void>();
        await deleteRelease?.future;
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        continue;
      }

      final body = await utf8.decoder.bind(request).join();
      final message = jsonDecode(body) as Map<String, dynamic>;
      final method = message['method']?.toString();
      if (method != null) _counts[method] = count(method) + 1;

      switch (method) {
        case 'initialize':
          await _handleInitialize(request, message);
        case 'tools/list':
          await _handleToolsList(request, message);
        case 'tools/call':
          await _handleToolCall(request, message);
        default:
          request.response.statusCode = HttpStatus.accepted;
          await request.response.close();
      }
    }
  }

  Future<void> _handleInitialize(
    HttpRequest request,
    Map<String, dynamic> message,
  ) async {
    _activeInitialize++;
    if (_activeInitialize > maxConcurrentInitialize) {
      maxConcurrentInitialize = _activeInitialize;
    }
    if (count('initialize') == 1 && firstInitializeGate != null) {
      await firstInitializeGate!.future;
    }
    request.response.headers.set(
      'MCP-Session-Id',
      'session-${count('initialize')}',
    );
    _writeJson(request.response, {
      'jsonrpc': '2.0',
      'id': message['id'],
      'result': {
        'protocolVersion': mcp.McpProtocol.defaultVersion,
        'serverInfo': {'name': 'Mock', 'version': '1.0.0'},
        'capabilities': supportsTools
            ? {'tools': <String, dynamic>{}}
            : {'resources': <String, dynamic>{}},
      },
    });
    await request.response.close();
    _activeInitialize--;
  }

  Future<void> _handleToolsList(
    HttpRequest request,
    Map<String, dynamic> message,
  ) async {
    toolsListRequestTimes.add(DateTime.now());
    _activeToolsList++;
    if (_activeToolsList > maxConcurrentToolsList) {
      maxConcurrentToolsList = _activeToolsList;
    }
    try {
      if (failFirstToolsList && count('tools/list') == 1) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        request.response.headers.set(HttpHeaders.retryAfterHeader, '2');
        await request.response.close();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _toolsListSucceeded = true;
      await _maybeSendBurst();
      _writeJson(request.response, {
        'jsonrpc': '2.0',
        'id': message['id'],
        'result': {
          'tools': [
            {
              'name': 'echo',
              'description': 'echo',
              'inputSchema': {'type': 'object'},
            },
          ],
        },
      });
      await request.response.close();
    } finally {
      _activeToolsList--;
    }
  }

  Future<void> _handleToolCall(
    HttpRequest request,
    Map<String, dynamic> message,
  ) async {
    final toolName = (message['params'] as Map?)?['name']?.toString();
    if (rejectFirstSessionToolCalls &&
        request.headers.value('MCP-Session-Id') == 'session-1') {
      _expiredToolResponses.add(request.response);
      if (_expiredToolResponses.length == 2) {
        for (final response in _expiredToolResponses) {
          response.statusCode = HttpStatus.notFound;
          await response.close();
        }
      }
      return;
    }
    if (toolName == 'invalid') {
      _writeJson(request.response, {
        'jsonrpc': '2.0',
        'id': message['id'],
        'error': {'code': -32602, 'message': 'missing value'},
      });
      await request.response.close();
      return;
    }
    if (coordinateCooldown && toolName == 'limited') {
      request.response.statusCode = HttpStatus.tooManyRequests;
      request.response.headers.set(HttpHeaders.retryAfterHeader, '1');
      await request.response.close();
      return;
    }
    if (coordinateCooldown && toolName == 'slow-success') {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (dropFirstToolResponse && count('tools/call') == 1) {
      final socket = await request.response.detachSocket(writeHeaders: false);
      socket.destroy();
      return;
    }
    _writeJson(request.response, {
      'jsonrpc': '2.0',
      'id': message['id'],
      'result': {
        'content': [
          {'type': 'text', 'text': 'ok'},
        ],
        'isError': false,
      },
    });
    await request.response.close();
  }

  Future<void> _maybeSendBurst() async {
    final stream = _publicStream;
    if (!sendToolsChangedBurst ||
        !_toolsListSucceeded ||
        _burstSent ||
        stream == null) {
      return;
    }
    _burstSent = true;
    for (var index = 0; index < 10; index++) {
      stream.write(
        'data: ${jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/tools/list_changed'})}\n\n',
      );
    }
    await stream.flush();
  }

  void _writeJson(HttpResponse response, Object value) {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(value));
  }
}
