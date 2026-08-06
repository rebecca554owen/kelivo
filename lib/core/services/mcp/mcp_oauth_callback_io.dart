import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'mcp_oauth_callback_types.dart';

const _oauthReturnUri = 'kelivo://oauth-return';
const _iosOAuthChannel = MethodChannel('app.mcp_oauth');

Future<McpOAuthCallback> openMcpOAuthCallback(Uri authorizationServer) async {
  if (Platform.isIOS) return _IosMcpOAuthCallback(authorizationServer);
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  return _IoMcpOAuthCallback(server);
}

final class _IosMcpOAuthCallback implements McpOAuthCallback {
  _IosMcpOAuthCallback(Uri authorizationServer)
    : redirectUri = Uri(
        scheme: 'psyche.kelivo',
        path:
            '/oauth/callback/${base64UrlEncode(sha256.convert(utf8.encode(authorizationServer.toString())).bytes).replaceAll('=', '')}',
      );

  @override
  final Uri redirectUri;

  @override
  Future<Uri> authorize(
    Uri authorizationUrl,
    Duration timeout,
    McpOAuthUrlLauncher launchAuthorizationUrl,
  ) async {
    try {
      final value = await _iosOAuthChannel
          .invokeMethod<String>('authenticate', {
            'url': authorizationUrl.toString(),
            'callbackScheme': redirectUri.scheme,
          })
          .timeout(timeout);
      if (value == null) {
        throw const McpOAuthCallbackException(
          'authorization session returned no callback URL',
        );
      }
      return Uri.parse(value);
    } on TimeoutException {
      await _iosOAuthChannel.invokeMethod<void>('cancel');
      rethrow;
    } on PlatformException catch (error) {
      throw McpOAuthCallbackException(
        error.message ?? 'authorization session failed',
        cancelled: error.code == 'authorization_cancelled',
      );
    }
  }

  @override
  Future<Uri> waitForCallback(Duration timeout) {
    throw UnsupportedError('iOS OAuth callbacks are handled by the system');
  }

  @override
  Future<void> close() => _iosOAuthChannel.invokeMethod<void>('cancel');
}

final class _IoMcpOAuthCallback implements McpOAuthCallback {
  _IoMcpOAuthCallback(HttpServer server)
    : _server = server,
      _redirectUri = Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        path: '/oauth/callback',
      ) {
    _subscription = _server.listen(_handleRequest);
  }

  final HttpServer _server;
  final Uri _redirectUri;
  final Completer<Uri> _callback = Completer<Uri>();
  late final StreamSubscription<HttpRequest> _subscription;
  bool _closed = false;

  @override
  Uri get redirectUri => _redirectUri;

  @override
  Future<Uri> authorize(
    Uri authorizationUrl,
    Duration timeout,
    McpOAuthUrlLauncher launchAuthorizationUrl,
  ) async {
    if (!await launchAuthorizationUrl(authorizationUrl)) {
      throw const McpOAuthCallbackException(
        'could not open the authorization URL',
      );
    }
    return waitForCallback(timeout);
  }

  @override
  Future<Uri> waitForCallback(Duration timeout) =>
      _callback.future.timeout(timeout);

  Future<void> _handleRequest(HttpRequest request) async {
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
      ..write(_callbackPage(returnToApp: Platform.isAndroid || Platform.isIOS));
    await request.response.close();
    if (!_callback.isCompleted) {
      _callback.complete(redirectUri.replace(query: request.uri.query));
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
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
