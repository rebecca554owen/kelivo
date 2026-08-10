import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/core/services/api/builtin_tools.dart';
import 'package:flutter_test/flutter_test.dart';

ProviderConfig _cfg({
  required String baseUrl,
  required bool useResponseApi,
  required String modelId,
}) {
  return ProviderConfig(
    id: 'Test',
    enabled: true,
    name: 'Test',
    apiKey: 'k',
    baseUrl: baseUrl,
    providerType: ProviderKind.openai,
    useResponseApi: useResponseApi,
    modelOverrides: {
      modelId: {
        'builtInTools': [BuiltInToolNames.search],
      },
    },
  );
}

void main() {
  group('DashScope Responses search whitelist 3.7/3.8', () {
    test('enables 3.7 max/plus and 3.8-max-preview only', () {
      expect(
        BuiltInToolsHelper.isDashScopeResponsesBuiltInSearchSupportedModel(
          'qwen3.7-plus',
        ),
        isTrue,
      );
      expect(
        BuiltInToolsHelper.isDashScopeResponsesBuiltInSearchSupportedModel(
          'qwen3.7-max',
        ),
        isTrue,
      );
      expect(
        BuiltInToolsHelper.isDashScopeResponsesBuiltInSearchSupportedModel(
          'qwen3.8-max-preview',
        ),
        isTrue,
      );
      expect(
        BuiltInToolsHelper.isDashScopeResponsesBuiltInSearchSupportedModel(
          'qwen3.8-max',
        ),
        isFalse,
      );
      expect(
        BuiltInToolsHelper.isDashScopeResponsesBuiltInSearchSupportedModel(
          'qwen3.7-flash',
        ),
        isFalse,
      );
    });

    test('supportsBuiltInSearchForModel routes Ark/MiMo/Zhipu/Kimi', () {
      final ark = _cfg(
        baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
        useResponseApi: true,
        modelId: 'doubao-seed-2.0-pro',
      );
      final mimo = _cfg(
        baseUrl: 'https://api.xiaomimimo.com/v1',
        useResponseApi: false,
        modelId: 'mimo-v2.5-pro',
      );
      final zhipu = _cfg(
        baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
        useResponseApi: false,
        modelId: 'glm-5',
      );
      final kimi = _cfg(
        baseUrl: 'https://api.moonshot.cn/v1',
        useResponseApi: false,
        modelId: 'kimi-k3',
      );

      expect(
        BuiltInToolsHelper.supportsBuiltInSearchForModel(
          cfg: ark,
          modelId: 'doubao-seed-2.0-pro',
        ),
        isTrue,
      );
      expect(
        BuiltInToolsHelper.supportsBuiltInSearchForModel(
          cfg: mimo,
          modelId: 'mimo-v2.5-pro',
        ),
        isTrue,
      );
      expect(
        BuiltInToolsHelper.supportsBuiltInSearchForModel(
          cfg: zhipu,
          modelId: 'glm-5',
        ),
        isTrue,
      );
      expect(
        BuiltInToolsHelper.supportsBuiltInSearchForModel(
          cfg: kimi,
          modelId: 'kimi-k3',
        ),
        isTrue,
      );
    });
  });
}
