import 'package:Kelivo/utils/brand_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandAssets', () {
    test('mapped Metaso icon is selectable as a built-in provider avatar', () {
      final asset = BrandAssets.assetForName('metaso');

      expect(asset, 'assets/icons/metaso-color.svg');
      expect(BrandAssets.selectableAssetOrNull(asset!), asset);
    });

    test('distinguishes monochrome SVGs from colored brand assets', () {
      expect(
        BrandAssets.assetNeedsDarkInvert('assets/icons/openai.svg'),
        isTrue,
      );
      expect(
        BrandAssets.assetNeedsDarkInvert('assets/icons/linkup.svg'),
        isTrue,
      );
      expect(
        BrandAssets.assetNeedsDarkInvert('assets/icons/serper.svg'),
        isFalse,
      );
      expect(
        BrandAssets.assetNeedsDarkInvert('assets/icons/gemini-color.svg'),
        isFalse,
      );
      expect(
        BrandAssets.assetNeedsDarkInvert('assets/icons/kelivo.png'),
        isFalse,
      );
    });
  });
}
