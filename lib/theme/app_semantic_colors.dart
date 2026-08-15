import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// Semantic colors that have no dedicated role in [ColorScheme].
///
/// All values are derived from (or harmonized with) the active [ColorScheme]
/// so custom/seed-generated themes get sensible values automatically.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color surfaceFill;
  final Color surfaceCard;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color searchHighlight;
  final List<Color> chartSeries;

  const AppSemanticColors({
    required this.surfaceFill,
    required this.surfaceCard,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.searchHighlight,
    required this.chartSeries,
  });

  /// Subtle fill for text fields, chips, small cards and tag containers.
  /// Replaces the old `isDark ? Colors.white10 : Color(0xFFF2F3F5/F7F7F9)` idiom.
  ///
  /// Dark mode uses a stronger alpha (0.14) than the historical white10/white12
  /// because these fills most often sit on [surfaceCard] (white@0.10 over
  /// surface) — at 0.10 the two were indistinguishable (e.g. input fields in
  /// section cards became invisible).
  static Color _deriveSurfaceFill(ColorScheme cs) {
    final alpha = cs.brightness == Brightness.dark ? 0.16 : 0.05;
    return Color.alphaBlend(cs.onSurface.withValues(alpha: alpha), cs.surface);
  }

  /// iOS-style section card background.
  /// Replaces the old `isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.96)` idiom.
  static Color _deriveSurfaceCard(ColorScheme cs) {
    return cs.brightness == Brightness.dark
        ? Color.alphaBlend(
            const Color(0xFFFFFFFF).withValues(alpha: 0.10),
            cs.surface,
          )
        : Color.alphaBlend(
            const Color(0xFFFFFFFF).withValues(alpha: 0.96),
            cs.surface,
          );
  }

  factory AppSemanticColors.light(ColorScheme cs) {
    const successBase = Color(0xFF2E7D32);
    const warningBase = Color(0xFFF57C00);
    return AppSemanticColors(
      surfaceFill: _deriveSurfaceFill(cs),
      surfaceCard: _deriveSurfaceCard(cs),
      success: successBase.harmonizeWith(cs.primary),
      successContainer: const Color(0xFFA5D6A7).harmonizeWith(cs.primary),
      onSuccessContainer: const Color(0xFF1B5E20),
      warning: warningBase.harmonizeWith(cs.primary),
      warningContainer: const Color(0xFFFFE0B2).harmonizeWith(cs.primary),
      onWarningContainer: const Color(0xFF4E2600),
      searchHighlight: const Color(0xFFFFD700).withValues(alpha: 0.55),
      chartSeries: const [
        Color(0xFF2563EB),
        Color(0xFF0F8F83),
        Color(0xFFEA580C),
        Color(0xFF8B5CF6),
        Color(0xFFE11D48),
        Color(0xFF16A34A),
        Color(0xFFCA8A04),
        Color(0xFF0891B2),
      ],
    );
  }

  factory AppSemanticColors.dark(ColorScheme cs) {
    const successBase = Color(0xFF81C784);
    const warningBase = Color(0xFFFFB74D);
    return AppSemanticColors(
      surfaceFill: _deriveSurfaceFill(cs),
      surfaceCard: _deriveSurfaceCard(cs),
      success: successBase.harmonizeWith(cs.primary),
      successContainer: const Color(0xFF1B5E20).harmonizeWith(cs.primary),
      onSuccessContainer: const Color(0xFFC8E6C9),
      warning: warningBase.harmonizeWith(cs.primary),
      warningContainer: const Color(0xFF8D4E00).harmonizeWith(cs.primary),
      onWarningContainer: const Color(0xFFFFE8CC),
      searchHighlight: const Color(0xFFB8860B).withValues(alpha: 0.55),
      chartSeries: const [
        Color(0xFF60A5FA),
        Color(0xFF5EEAD4),
        Color(0xFFFB923C),
        Color(0xFFA78BFA),
        Color(0xFFFB7185),
        Color(0xFF86EFAC),
        Color(0xFFFACC15),
        Color(0xFF67E8F9),
      ],
    );
  }

  @override
  AppSemanticColors copyWith({
    Color? surfaceFill,
    Color? surfaceCard,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? searchHighlight,
    List<Color>? chartSeries,
  }) {
    return AppSemanticColors(
      surfaceFill: surfaceFill ?? this.surfaceFill,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      searchHighlight: searchHighlight ?? this.searchHighlight,
      chartSeries: chartSeries ?? this.chartSeries,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    final len = chartSeries.length < other.chartSeries.length
        ? chartSeries.length
        : other.chartSeries.length;
    return AppSemanticColors(
      surfaceFill: Color.lerp(surfaceFill, other.surfaceFill, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      searchHighlight: Color.lerp(searchHighlight, other.searchHighlight, t)!,
      chartSeries: List.generate(
        len,
        (i) => Color.lerp(chartSeries[i], other.chartSeries[i], t)!,
      ),
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  /// The ambient [AppSemanticColors]. Falls back to deriving values from the
  /// ambient [ColorScheme] when the extension is not attached (e.g. in widget
  /// tests that pump a plain MaterialApp).
  AppSemanticColors get appColors {
    final theme = Theme.of(this);
    final ext = theme.extension<AppSemanticColors>();
    if (ext != null) return ext;
    return theme.brightness == Brightness.dark
        ? AppSemanticColors.dark(theme.colorScheme)
        : AppSemanticColors.light(theme.colorScheme);
  }
}
