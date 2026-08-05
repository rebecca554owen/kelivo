abstract interface class McpOAuthCallback {
  Uri get redirectUri;

  Future<Uri> waitForCallback(Duration timeout);

  Future<void> close();
}

typedef McpOAuthCallbackFactory = Future<McpOAuthCallback> Function();
