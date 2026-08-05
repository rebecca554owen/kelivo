import 'dart:async';
import 'dart:io';

import 'mcp_oauth_callback_types.dart';

const _oauthReturnUri = 'kelivo://oauth-return';

Future<McpOAuthCallback> openMcpOAuthCallback() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  return _IoMcpOAuthCallback(server);
}

final class _IoMcpOAuthCallback implements McpOAuthCallback {
  _IoMcpOAuthCallback(HttpServer server)
    : _server = server,
      _redirectUri = Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        path: '/oauth/callback',
      );

  final HttpServer _server;
  final Uri _redirectUri;
  bool _closed = false;

  @override
  Uri get redirectUri => _redirectUri;

  @override
  Future<Uri> waitForCallback(Duration timeout) async {
    final callback = Completer<Uri>();
    late final StreamSubscription<HttpRequest> subscription;
    subscription = _server.listen((request) async {
      if (request.uri.path != redirectUri.path) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found');
        await request.response.close();
        return;
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
        ..write(
          _callbackPage(returnToApp: Platform.isAndroid || Platform.isIOS),
        );
      await request.response.close();
      if (!callback.isCompleted) {
        callback.complete(redirectUri.replace(query: request.uri.query));
      }
    });

    try {
      return await callback.future.timeout(timeout);
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _server.close(force: true);
  }
}

String _callbackPage({required bool returnToApp}) =>
    '''<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Kelivo</title></head>
<body><p>${returnToApp ? 'Authorization received. Returning to Kelivo...' : 'Authorization received. You may close this window and return to Kelivo.'}</p>
${returnToApp ? '<p><a href="$_oauthReturnUri">Return to Kelivo</a></p>' : ''}
${returnToApp ? "<script>window.close(); setTimeout(function () { window.location.replace('$_oauthReturnUri'); }, 50);</script>" : ''}
</body></html>''';
