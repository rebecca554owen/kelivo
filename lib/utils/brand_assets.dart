import 'package:flutter/foundation.dart';

/// Centralized brand icon resolver.
/// Returns an asset path like `assets/icons/openai.svg` for a given name/model.
class BrandAssets {
  BrandAssets._();

  /// Resolve an icon asset path for a provider/model name.
  /// Returns null if no known mapping matches.
  static String? assetForName(String name) {
    final lower = name.toLowerCase();
    for (final e in _mapping) {
      if (e.key.hasMatch(lower)) return 'assets/icons/${e.value}';
    }
    return null;
  }

  // Keep order-specific matching using a list of entries.
  static final List<MapEntry<RegExp, String>> _mapping = <MapEntry<RegExp, String>>[
    MapEntry(RegExp(r'openai|gpt|o\d'), 'openai.svg'),
    MapEntry(RegExp(r'gemini'), 'gemini-color.svg'),
    MapEntry(RegExp(r'google'), 'google-color.svg'),
    MapEntry(RegExp(r'claude'), 'claude-color.svg'),
    MapEntry(RegExp(r'anthropic'), 'anthropic.svg'),
    MapEntry(RegExp(r'deepseek'), 'deepseek-color.svg'),
    MapEntry(RegExp(r'grok'), 'grok.svg'),
    MapEntry(RegExp(r'qwen|qwq|qvq'), 'qwen-color.svg'),
    MapEntry(RegExp(r'doubao'), 'doubao-color.svg'),
    MapEntry(RegExp(r'openrouter'), 'openrouter.svg'),
    MapEntry(RegExp(r'zhipu|智谱|glm'), 'zhipu-color.svg'),
    MapEntry(RegExp(r'mistral'), 'mistral-color.svg'),
    MapEntry(RegExp(r'(?<!o)llama|meta'), 'meta-color.svg'),
    MapEntry(RegExp(r'hunyuan|tencent'), 'hunyuan-color.svg'),
    MapEntry(RegExp(r'gemma'), 'gemma-color.svg'),
    MapEntry(RegExp(r'perplexity'), 'perplexity-color.svg'),
    MapEntry(RegExp(r'aliyun|阿里云|百炼'), 'alibabacloud-color.svg'),
    MapEntry(RegExp(r'bytedance|火山'), 'bytedance-color.svg'),
    MapEntry(RegExp(r'silicon|硅基'), 'siliconflow-color.svg'),
    MapEntry(RegExp(r'aihubmix'), 'aihubmix-color.svg'),
    MapEntry(RegExp(r'ollama'), 'ollama.svg'),
    MapEntry(RegExp(r'github'), 'github.svg'),
    MapEntry(RegExp(r'cloudflare'), 'cloudflare-color.svg'),
    MapEntry(RegExp(r'minimax'), 'minimax-color.svg'),
    MapEntry(RegExp(r'xai'), 'xai.svg'),
    MapEntry(RegExp(r'juhenext'), 'juhenext.png'),
    MapEntry(RegExp(r'kimi'), 'kimi-color.svg'),
    MapEntry(RegExp(r'302'), '302ai-color.svg'),
    MapEntry(RegExp(r'step|阶跃'), 'stepfun-color.svg'),
    MapEntry(RegExp(r'internlm|书生'), 'internlm-color.svg'),
    MapEntry(RegExp(r'cohere|command-.+'), 'cohere-color.svg'),
    MapEntry(RegExp(r'kelivo'), 'kelivo.png'),
  ];
}

