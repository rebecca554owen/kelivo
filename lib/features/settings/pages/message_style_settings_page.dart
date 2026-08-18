import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../icons/reasoning_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../../../shared/widgets/ios_tile_button.dart';
import '../../../theme/app_font_weights.dart';
import '../../../theme/app_semantic_colors.dart';
import '../../../theme/chat_bubble_style.dart';
import '../../../theme/custom_theme.dart';
import '../../../theme/palettes.dart';
import '../../../theme/theme_factory.dart';
import '../../home/pages/home_mobile_layout.dart';
import '../widgets/custom_theme_widgets.dart';

class MessageStyleSettingsPage extends StatefulWidget {
  const MessageStyleSettingsPage({super.key});

  @override
  State<MessageStyleSettingsPage> createState() =>
      _MessageStyleSettingsPageState();
}

class _MessageStyleSettingsPageState extends State<MessageStyleSettingsPage> {
  bool? _editingDark;

  bool get _isEditingDark =>
      _editingDark ?? Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final style = settings.chatMessageBackgroundStyle;
    final overrides = settings.chatBubbleStyleOverrides;
    final editingDark = _isEditingDark;
    final previewTheme = _previewTheme(context, editingDark);
    final previewCs = previewTheme.colorScheme;
    final resolved = resolveBubbleStyle(
      previewCs,
      previewTheme.brightness,
      style,
      overrides,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: Tooltip(
          message: l10n.settingsPageBackButton,
          child: IosIconButton(
            icon: Lucide.ArrowLeft,
            color: cs.onSurface,
            size: 22,
            minSize: 44,
            semanticLabel: l10n.settingsPageBackButton,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(l10n.messageStyleSettingsPageTitle),
        actions: [
          Tooltip(
            message: l10n.messageStyleSettingsPageReset,
            child: IosIconButton(
              icon: Lucide.RotateCcw,
              color: cs.onSurface,
              size: 20,
              minSize: 44,
              semanticLabel: l10n.messageStyleSettingsPageReset,
              onTap: () => _reset(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _iosSectionCard(
                  children: [
                    _StyleRow(
                      label:
                          l10n.displaySettingsPageChatMessageBackgroundDefault,
                      selected:
                          style == ChatMessageBackgroundStyle.defaultStyle,
                      onTap: () => settings.setChatMessageBackgroundStyle(
                        ChatMessageBackgroundStyle.defaultStyle,
                      ),
                    ),
                    _iosDivider(context),
                    _StyleRow(
                      label:
                          l10n.displaySettingsPageChatMessageBackgroundFrosted,
                      selected: style == ChatMessageBackgroundStyle.frosted,
                      onTap: () => settings.setChatMessageBackgroundStyle(
                        ChatMessageBackgroundStyle.frosted,
                      ),
                    ),
                    _iosDivider(context),
                    _StyleRow(
                      label: l10n.displaySettingsPageChatMessageBackgroundSolid,
                      selected: style == ChatMessageBackgroundStyle.solid,
                      onTap: () => settings.setChatMessageBackgroundStyle(
                        ChatMessageBackgroundStyle.solid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _LightDarkToggle(
                  editingDark: editingDark,
                  onChanged: (v) => setState(() => _editingDark = v),
                ),
                if (style != ChatMessageBackgroundStyle.defaultStyle) ...[
                  const SizedBox(height: 12),
                  _iosSectionCard(
                    children: [
                      if (style == ChatMessageBackgroundStyle.frosted) ...[
                        _SliderRow(
                          label: l10n.messageStyleSettingsPageBlur,
                          valueText: resolved.blurSigma.round().toString(),
                          child: _ThemedSlider(
                            value: resolved.blurSigma,
                            min: 0,
                            max: 30,
                            stepSize: 1,
                            onChanged: (v) =>
                                settings.setChatBubbleStyleOverrides(
                                  overrides.copyWith(blurSigma: () => v),
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Text(
                            l10n.messageStyleSettingsPageBlurHint,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: cs.onSurface.withValues(alpha: 0.58),
                            ),
                          ),
                        ),
                        _iosDivider(context, indent: 14),
                      ],
                      _ColorRow(
                        label: l10n.messageStyleSettingsPageBackgroundColor,
                        color: resolved.background.withValues(alpha: 1),
                        onTap: () => _pickColor(
                          context,
                          title: l10n.messageStyleSettingsPageBackgroundColor,
                          initial: resolved.background.withValues(alpha: 1),
                          onPicked: (color) {
                            final argb = _opaqueArgb(color);
                            settings.setChatBubbleStyleOverrides(
                              editingDark
                                  ? overrides.copyWith(
                                      backgroundArgbDark: () => argb,
                                    )
                                  : overrides.copyWith(
                                      backgroundArgbLight: () => argb,
                                    ),
                            );
                          },
                        ),
                      ),
                      _iosDivider(context, indent: 14),
                      _SliderRow(
                        label: l10n.messageStyleSettingsPageBackgroundOpacity,
                        valueText:
                            '${((_styleOpacity(style, overrides) * 100).round())}%',
                        child: _ThemedSlider(
                          value: _styleOpacity(style, overrides) * 100,
                          min: 0,
                          max: 100,
                          stepSize: 1,
                          onChanged: (v) {
                            final opacity = (v / 100).clamp(0.0, 1.0);
                            settings.setChatBubbleStyleOverrides(
                              style == ChatMessageBackgroundStyle.frosted
                                  ? overrides.copyWith(
                                      frostedOpacity: () => opacity,
                                    )
                                  : overrides.copyWith(
                                      solidOpacity: () => opacity,
                                    ),
                            );
                          },
                        ),
                      ),
                      _iosDivider(context, indent: 14),
                      _ColorRow(
                        label: l10n.messageStyleSettingsPageBorderColor,
                        color: resolved.border.withValues(alpha: 1),
                        onTap: () => _pickColor(
                          context,
                          title: l10n.messageStyleSettingsPageBorderColor,
                          initial: resolved.border.withValues(alpha: 1),
                          onPicked: (color) {
                            final argb = _opaqueArgb(color);
                            settings.setChatBubbleStyleOverrides(
                              editingDark
                                  ? overrides.copyWith(
                                      borderArgbDark: () => argb,
                                    )
                                  : overrides.copyWith(
                                      borderArgbLight: () => argb,
                                    ),
                            );
                          },
                        ),
                      ),
                      _iosDivider(context, indent: 14),
                      _SliderRow(
                        label: l10n.messageStyleSettingsPageBorderOpacity,
                        valueText: '${((resolved.border.a * 100).round())}%',
                        child: _ThemedSlider(
                          value: resolved.border.a * 100,
                          min: 0,
                          max: 100,
                          stepSize: 1,
                          onChanged: (v) =>
                              settings.setChatBubbleStyleOverrides(
                                overrides.copyWith(
                                  borderOpacity: () =>
                                      (v / 100).clamp(0.0, 1.0),
                                ),
                              ),
                        ),
                      ),
                      _iosDivider(context, indent: 14),
                      _SliderRow(
                        label: l10n.messageStyleSettingsPageBorderWidth,
                        valueText: resolved.borderWidth.toStringAsFixed(1),
                        child: _ThemedSlider(
                          value: resolved.borderWidth,
                          min: 0,
                          max: 3,
                          stepSize: 0.1,
                          onChanged: (v) =>
                              settings.setChatBubbleStyleOverrides(
                                overrides.copyWith(borderWidth: () => v),
                              ),
                        ),
                      ),
                      _iosDivider(context, indent: 14),
                      _ColorRow(
                        label: l10n.messageStyleSettingsPageTextColor,
                        color: resolved.text.withValues(alpha: 1),
                        onTap: () => _pickColor(
                          context,
                          title: l10n.messageStyleSettingsPageTextColor,
                          initial: resolved.text.withValues(alpha: 1),
                          onPicked: (color) {
                            final argb = _opaqueArgb(color);
                            settings.setChatBubbleStyleOverrides(
                              editingDark
                                  ? overrides.copyWith(textArgbDark: () => argb)
                                  : overrides.copyWith(
                                      textArgbLight: () => argb,
                                    ),
                            );
                          },
                        ),
                      ),
                      _iosDivider(context, indent: 14),
                      _SliderRow(
                        label: l10n.messageStyleSettingsPageCornerRadius,
                        valueText: resolved.radius.round().toString(),
                        child: _ThemedSlider(
                          value: resolved.radius,
                          min: 0,
                          max: 28,
                          stepSize: 1,
                          onChanged: (v) =>
                              settings.setChatBubbleStyleOverrides(
                                overrides.copyWith(cornerRadius: () => v),
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _PreviewPanel(
                theme: previewTheme,
                style: style,
                overrides: overrides,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await _confirmReset(context);
    if (!ok || !context.mounted) return;
    await context.read<SettingsProvider>().setChatBubbleStyleOverrides(
      const ChatBubbleStyleOverrides(),
    );
  }

  Future<void> _pickColor(
    BuildContext context, {
    required String title,
    required Color initial,
    required ValueChanged<Color> onPicked,
  }) async {
    final result = await showAppColorPicker(
      context,
      title: title,
      initial: initial,
    );
    if (!mounted || result == null) return;
    onPicked(result);
  }
}

ThemeData _previewTheme(BuildContext context, bool editingDark) {
  final current = Theme.of(context);
  if ((current.brightness == Brightness.dark) == editingDark) {
    return current;
  }
  final settings = context.read<SettingsProvider>();
  final custom = settings.selectedCustomTheme;
  final palette =
      settings.themePaletteId == ThemePalettes.customPaletteId && custom != null
      ? buildCustomThemePalette(custom)
      : ThemePalettes.byId(settings.themePaletteId);
  return editingDark
      ? buildDarkThemeForScheme(
          palette.dark,
          pureBackground: settings.usePureBackground,
        )
      : buildLightThemeForScheme(
          palette.light,
          pureBackground: settings.usePureBackground,
        );
}

double _styleOpacity(
  ChatMessageBackgroundStyle style,
  ChatBubbleStyleOverrides overrides,
) {
  return switch (style) {
    ChatMessageBackgroundStyle.frosted => overrides.frostedOpacity ?? 0.66,
    ChatMessageBackgroundStyle.solid => overrides.solidOpacity ?? 1.0,
    ChatMessageBackgroundStyle.defaultStyle => overrides.solidOpacity ?? 1.0,
  };
}

int _opaqueArgb(Color color) => color.withValues(alpha: 1).toARGB32();

Future<bool> _confirmReset(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: cs.scrim.withValues(alpha: 0.25),
    pageBuilder: (ctx, _, __) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).maybePop(false),
        child: Material(
          type: MaterialType.transparency,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: cs.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: isDark
                            ? cs.onSurface.withValues(alpha: 0.08)
                            : cs.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.messageStyleSettingsPageResetConfirm,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: AppFontWeights.medium,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: IosTileButton(
                                icon: Lucide.X,
                                label: l10n.messageStyleSettingsPageCancel,
                                onTap: () => Navigator.of(ctx).maybePop(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: IosTileButton(
                                icon: Lucide.RotateCcw,
                                label: l10n.messageStyleSettingsPageReset,
                                backgroundColor: cs.primary,
                                foregroundColor: cs.primary,
                                onTap: () => Navigator.of(ctx).maybePop(true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return ok ?? false;
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IosCardPress(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      baseColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (selected)
              Icon(Lucide.Check, size: 18, color: cs.primary)
            else
              const SizedBox(width: 18, height: 18),
          ],
        ),
      ),
    );
  }
}

class _LightDarkToggle extends StatelessWidget {
  const _LightDarkToggle({required this.editingDark, required this.onChanged});

  final bool editingDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.06),
          width: 0.6,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: l10n.messageStyleSettingsPageLight,
              icon: Lucide.Sun,
              selected: !editingDark,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _Segment(
              label: l10n.messageStyleSettingsPageDark,
              icon: Lucide.Moon,
              selected: editingDark,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IosCardPress(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      baseColor: selected
          ? (isDark ? Colors.white10 : Colors.white)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected
                  ? AppFontWeights.semibold
                  : AppFontWeights.regular,
              color: selected
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IosCardPress(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      padding: EdgeInsets.zero,
      baseColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                  width: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueText,
    required this.child,
  });

  final String label;
  final String valueText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _ThemedSlider extends StatelessWidget {
  const _ThemedSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.stepSize,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final double stepSize;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SfSliderTheme(
      data: SfSliderThemeData(
        activeTrackHeight: 8,
        inactiveTrackHeight: 8,
        overlayRadius: 14,
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.onSurface.withValues(
          alpha: isDark ? 0.25 : 0.20,
        ),
        tooltipBackgroundColor: cs.primary,
        tooltipTextStyle: TextStyle(
          color: cs.onPrimary,
          fontWeight: AppFontWeights.semibold,
        ),
        activeTickColor: cs.onSurface.withValues(alpha: isDark ? 0.45 : 0.35),
        inactiveTickColor: cs.onSurface.withValues(alpha: isDark ? 0.30 : 0.25),
        activeMinorTickColor: cs.onSurface.withValues(
          alpha: isDark ? 0.34 : 0.28,
        ),
        inactiveMinorTickColor: cs.onSurface.withValues(
          alpha: isDark ? 0.24 : 0.20,
        ),
      ),
      child: SfSlider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        stepSize: stepSize,
        enableTooltip: true,
        shouldAlwaysShowTooltip: false,
        tooltipShape: const SfPaddleTooltipShape(),
        thumbIcon: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        ),
        onChanged: (v) => onChanged((v as double).clamp(min, max)),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.theme,
    required this.style,
    required this.overrides,
  });

  final ThemeData theme;
  final ChatMessageBackgroundStyle style;
  final ChatBubbleStyleOverrides overrides;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 232,
        child: Theme(
          data: theme,
          child: Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              final l10n = AppLocalizations.of(context)!;
              final resolved = resolveBubbleStyle(
                cs,
                Theme.of(context).brightness,
                style,
                overrides,
              );
              return Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: cs.surface)),
                  const MobileBackgroundLayer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 240),
                            child: _PreviewSurface(
                              style: style,
                              resolved: resolved,
                              defaultColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? cs.primary.withValues(alpha: 0.15)
                                  : cs.primary.withValues(alpha: 0.08),
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                l10n.messageStyleSettingsPagePreviewUser,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color:
                                      style ==
                                          ChatMessageBackgroundStyle
                                              .defaultStyle
                                      ? cs.onSurface
                                      : resolved.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _PreviewSurface(
                          style: style,
                          resolved: resolved,
                          defaultColor: cs.primaryContainer.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.25
                                : 0.30,
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            children: [
                              ReasoningIcons.thinkingCardIcon(
                                size: 16,
                                color: _previewStrong(context, resolved),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.messageStyleSettingsPagePreviewThinking,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: AppFontWeights.emphasis,
                                    color: _previewStrong(context, resolved),
                                  ),
                                ),
                              ),
                              Icon(
                                Lucide.ChevronRight,
                                size: 16,
                                color: _previewStrong(context, resolved),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: _PreviewSurface(
                              style: style,
                              resolved: resolved,
                              bareOnDefault: true,
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                l10n.messageStyleSettingsPagePreviewAssistant,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color:
                                      style ==
                                          ChatMessageBackgroundStyle
                                              .defaultStyle
                                      ? cs.onSurface
                                      : resolved.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Color _previewStrong(BuildContext context, ResolvedBubbleStyle resolved) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final style = context.read<SettingsProvider>().chatMessageBackgroundStyle;
  if (style == ChatMessageBackgroundStyle.defaultStyle) {
    return cs.secondary;
  }
  final isDark = theme.brightness == Brightness.dark;
  return resolved.text.withValues(alpha: isDark ? 0.88 : 0.78);
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    required this.style,
    required this.resolved,
    required this.padding,
    required this.child,
    this.defaultColor,
    this.bareOnDefault = false,
  });

  final ChatMessageBackgroundStyle style;
  final ResolvedBubbleStyle resolved;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final Color? defaultColor;
  final bool bareOnDefault;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(padding: padding, child: child);
    switch (style) {
      case ChatMessageBackgroundStyle.frosted:
        final radius = BorderRadius.circular(resolved.radius);
        return ClipRRect(
          borderRadius: radius,
          child: BackdropFilter.grouped(
            filter: ui.ImageFilter.blur(
              sigmaX: resolved.blurSigma,
              sigmaY: resolved.blurSigma,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resolved.background,
                borderRadius: radius,
                border: Border.all(
                  color: resolved.border,
                  width: resolved.borderWidth,
                ),
              ),
              child: padded,
            ),
          ),
        );
      case ChatMessageBackgroundStyle.solid:
        final radius = BorderRadius.circular(resolved.radius);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: resolved.background,
            borderRadius: radius,
            border: Border.all(
              color: resolved.border,
              width: resolved.borderWidth,
            ),
          ),
          child: padded,
        );
      case ChatMessageBackgroundStyle.defaultStyle:
        if (bareOnDefault) return child;
        if (defaultColor == null) return padded;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: defaultColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: padded,
        );
    }
  }
}

Widget _iosSectionCard({required List<Widget> children}) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.06),
            width: 0.6,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: children),
        ),
      );
    },
  );
}

Widget _iosDivider(BuildContext context, {double indent = 14}) {
  final cs = Theme.of(context).colorScheme;
  return Divider(
    height: 6,
    thickness: 0.6,
    indent: indent,
    endIndent: 12,
    color: cs.outlineVariant.withValues(alpha: 0.18),
  );
}
