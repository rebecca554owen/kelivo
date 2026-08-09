part of 'chat_api_service.dart';

// Top-level shims so provider-specific implementations (split into parts)
// can keep calling the existing helper names without qualifying `ChatApiService.`.

String _apiModelId(ProviderConfig cfg, String modelId) =>
    ChatApiService._apiModelId(cfg, modelId);

String _apiKeyForRequest(ProviderConfig cfg, String modelId) =>
    ChatApiService._apiKeyForRequest(cfg, modelId);

String _effectiveApiKey(ProviderConfig cfg) =>
    ChatApiService._effectiveApiKey(cfg);

Set<String> _builtInTools(ProviderConfig cfg, String modelId) =>
    ChatApiService._builtInTools(cfg, modelId);

Map<String, String> _customHeaders(ProviderConfig cfg, String modelId) =>
    ChatApiService._customHeaders(cfg, modelId);

dynamic _parseOverrideValue(String v) => ChatApiService._parseOverrideValue(v);

Map<String, dynamic> _customBody(ProviderConfig cfg, String modelId) =>
    ChatApiService._customBody(cfg, modelId);

ModelInfo _effectiveModelInfo(ProviderConfig cfg, String modelId) =>
    ChatApiService._effectiveModelInfo(cfg, modelId);

String _mimeFromPath(String path) => ChatApiService._mimeFromPath(path);

String _mimeFromDataUrl(String dataUrl) =>
    ChatApiService._mimeFromDataUrl(dataUrl);

Future<_ParsedTextAndImages> _parseTextAndImages(
  String raw, {
  required bool allowRemoteImages,
  required bool allowLocalImages,
  bool allowDataImages = true,
  bool keepRemoteMarkdownText = true,
  bool keepDisallowedImageText = true,
}) => ChatApiService._parseTextAndImages(
  raw,
  allowRemoteImages: allowRemoteImages,
  allowLocalImages: allowLocalImages,
  allowDataImages: allowDataImages,
  keepRemoteMarkdownText: keepRemoteMarkdownText,
  keepDisallowedImageText: keepDisallowedImageText,
);

Future<String?> _tryEncodeBase64File(String path, {bool withPrefix = false}) =>
    ChatApiService._tryEncodeBase64File(path, withPrefix: withPrefix);

/// Prefer explicit MIME from a media-ref map; fall back to path/data-URL inference.
String _mimeForInternalMediaRef(InternalMediaRef ref) {
  final explicit = ref.mime?.trim() ?? '';
  if (explicit.isNotEmpty) return explicit;
  final path = ref.uri;
  if (path.startsWith('data:')) return _mimeFromDataUrl(path);
  return _mimeFromPath(path);
}

/// Merge `_kelivo_media_paths` (String|Map) with optional plain-string user paths.
List<InternalMediaRef> _supplementalMediaRefs({
  required dynamic internalRaw,
  List<String>? userPaths,
  bool includeUserPaths = false,
}) {
  final refs = List<InternalMediaRef>.of(parseInternalMediaRefs(internalRaw));
  if (!includeUserPaths || userPaths == null || userPaths.isEmpty) {
    return refs;
  }
  final seen = <String>{for (final ref in refs) ref.uri};
  for (final path in userPaths) {
    final trimmed = path.trim();
    if (trimmed.isEmpty || !seen.add(trimmed)) continue;
    refs.add((uri: trimmed, mime: null, unavailable: false));
  }
  return refs;
}

/// Encode a local file as a data URL, preferring [explicitMime] when present.
/// Returns null when the file is missing/unreadable.
Future<String?> _tryEncodeBase64DataUrl(
  String path, {
  String? explicitMime,
}) async {
  final b64 = await _tryEncodeBase64File(path, withPrefix: false);
  if (b64 == null) return null;
  final mime = (explicitMime != null && explicitMime.trim().isNotEmpty)
      ? explicitMime.trim()
      : _mimeFromPath(path);
  return 'data:$mime;base64,$b64';
}

bool _isOff(int? budget) => ChatApiService._isOff(budget);

String _effortForBudget(int? budget) => ChatApiService._effortForBudget(budget);

bool _isClaudeReasoningEnabled(int? budget) =>
    ChatApiService._isClaudeReasoningEnabled(budget);

Map<String, dynamic>? _claudeThinkingConfig(
  String modelId,
  int? budget, {
  ProviderConfig? config,
}) => ChatApiService._claudeThinkingConfig(modelId, budget, config: config);

Map<String, dynamic>? _claudeOutputConfig(
  String modelId,
  int? budget, {
  ProviderConfig? config,
}) => ChatApiService._claudeOutputConfig(modelId, budget, config: config);

bool _claudeShouldOmitSamplingParams(String modelId, int? budget) =>
    ChatApiService._claudeShouldOmitSamplingParams(modelId, budget);

double? _claudeCompatibleTopP(String modelId, int? budget, double? topP) =>
    ChatApiService._claudeCompatibleTopP(modelId, budget, topP);

Map<String, dynamic> _cleanSchemaForGemini(Map<String, dynamic> schema) =>
    ChatApiService._cleanSchemaForGemini(schema);
