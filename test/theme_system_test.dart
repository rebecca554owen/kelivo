import 'package:Kelivo/theme/app_semantic_colors.dart';
import 'package:Kelivo/theme/palettes.dart';
import 'package:Kelivo/theme/theme_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every built-in palette builds themes with semantic colors attached',
      () {
    for (final p in ThemePalettes.all) {
      final light = buildLightThemeForScheme(p.light);
      final dark = buildDarkThemeForScheme(p.dark);
      final l = light.extension<AppSemanticColors>();
      final d = dark.extension<AppSemanticColors>();
      expect(l, isNotNull, reason: '${p.id} light');
      expect(d, isNotNull, reason: '${p.id} dark');
      expect(l!.chartSeries.length, 8);
      expect(d!.chartSeries.length, 8);
    }
  });

  test('surfaceContainer roles are derived from palette surface, not M3 '
      'defaults', () {
    // docTheme has a green primary; its containers must not keep the
    // purple-tinted M3 static defaults.
    final theme = buildLightThemeForScheme(ThemePalettes.docTheme.light);
    final cs = theme.colorScheme;
    expect(cs.surfaceContainerHigh, isNot(const Color(0xFFECE6F0)));
    // Light containers stay close to the surface (neutral gray family).
    final hsl = HSLColor.fromColor(cs.surfaceContainerHighest);
    expect(hsl.saturation, lessThan(0.2));
  });

  test('buildCustomPalette generates light/dark schemes from seed', () {
    final p = buildCustomPalette(seed: const Color(0xFF00897B));
    expect(p.id, ThemePalettes.customPaletteId);
    expect(p.light.brightness, Brightness.light);
    expect(p.dark.brightness, Brightness.dark);
    // Seed hue should be reflected in primary.
    final seedHsl = HSLColor.fromColor(const Color(0xFF00897B));
    final primaryHsl = HSLColor.fromColor(p.light.primary);
    expect((primaryHsl.hue - seedHsl.hue).abs(), lessThan(30));
  });

  test('buildCustomPalette applies primary/surface overrides', () {
    const primary = Color(0xFFE53935);
    const surface = Color(0xFFFAFAFA);
    final p = buildCustomPalette(
      seed: const Color(0xFF1E88E5),
      primaryOverride: primary,
      surfaceOverride: surface,
    );
    expect(p.light.primary, primary);
    expect(p.light.surface, surface);
    expect(p.light.surfaceTint, primary);
    // onPrimary must contrast with the overridden primary.
    expect(p.light.onPrimary, const Color(0xFFFFFFFF));
  });

  test('appColors falls back to derivation when extension is missing', () {
    final cs = ThemeData.light().colorScheme;
    final derived = AppSemanticColors.light(cs);
    expect(derived.chartSeries.length, 8);
    // surfaceFill is a subtle blend over surface, not pure surface.
    expect(derived.surfaceFill, isNot(cs.surface));
  });
}
