import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/lucide_adapter.dart' as lucide;
import '../../l10n/app_localizations.dart';
import '../../core/providers/tts_provider.dart';

/// Desktop: TTS (语音服务) right-side pane
/// Adapts mobile TTS page to desktop with hoverable list card style
/// similar to DesktopSearchServicesPane.
class DesktopTtsServicesPane extends StatefulWidget {
  const DesktopTtsServicesPane({super.key});
  @override
  State<DesktopTtsServicesPane> createState() => _DesktopTtsServicesPaneState();
}

class _DesktopTtsServicesPaneState extends State<DesktopTtsServicesPane> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsProvider>();

    return Container(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.ttsServicesPageTitle,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: cs.onSurface.withOpacity(0.9)),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // System TTS card
              SliverToBoxAdapter(
                child: _SystemTtsCard(),
              ),

              // (Removed) extra settings card; settings available via dialog only
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemTtsCard extends StatefulWidget {
  @override
  State<_SystemTtsCard> createState() => _SystemTtsCardState();
}

class _SystemTtsCardState extends State<_SystemTtsCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final tts = context.watch<TtsProvider>();

    final baseBg = isDark ? Colors.white10 : Colors.white.withOpacity(0.96);
    final borderColor = _hover
        ? cs.primary.withOpacity(isDark ? 0.35 : 0.45)
        : cs.outlineVariant.withOpacity(isDark ? 0.12 : 0.08);

    final available = tts.isAvailable && (tts.error == null);
    final titleText = l10n.ttsServicesPageSystemTtsTitle;
    final subText = available
        ? l10n.ttsServicesPageSystemTtsAvailableSubtitle
        : l10n.ttsServicesPageSystemTtsUnavailableSubtitle(tts.error ?? l10n.ttsServicesPageSystemTtsUnavailableNotInitialized);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            color: baseBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            children: [
              // Brand-like circular badge with a speaker icon
              _CircleIconBadge(icon: lucide.Lucide.Volume2, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titleText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.ttsServicesPageTestVoiceTooltip,
                child: _SmallIconBtn(
                  icon: tts.isSpeaking ? lucide.Lucide.CircleStop : lucide.Lucide.Volume2,
                  onTap: available
                      ? () async {
                          if (!tts.isSpeaking) {
                            final demo = l10n.ttsServicesPageTestSpeechText;
                            await context.read<TtsProvider>().speak(demo);
                          } else {
                            await context.read<TtsProvider>().stop();
                          }
                        }
                      : () {},
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.ttsServicesPageSystemTtsSettingsTitle,
                child: _SmallIconBtn(
                  icon: lucide.Lucide.Settings2,
                  onTap: () => _showSettingsDialog(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tts = context.read<TtsProvider>();
    double rate = tts.speechRate;
    double pitch = tts.pitch;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(l10n.ttsServicesPageSystemTtsSettingsTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                      _SmallIconBtn(icon: lucide.Lucide.X, onTap: () => Navigator.of(ctx).maybePop()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _deskDivider(context),
                  const SizedBox(height: 10),
                  // Engine selection
                  FutureBuilder<List<String>>(
                    future: tts.listEngines(),
                    builder: (context, snap) {
                      final engines = snap.data ?? const <String>[];
                      final cur = tts.engineId ?? (engines.isNotEmpty ? engines.first : '');
                      return _SelectRow(
                        label: l10n.ttsServicesPageEngineLabel,
                        value: cur.isEmpty ? l10n.ttsServicesPageAutoLabel : cur,
                        options: engines,
                        onSelected: (picked) async {
                          await tts.setEngineId(picked);
                          if (ctx.mounted) (ctx as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  // Language selection
                  FutureBuilder<List<String>>(
                    future: tts.listLanguages(),
                    builder: (context, snap) {
                      final langs = snap.data ?? const <String>[];
                      final cur = tts.languageTag ?? (langs.contains('zh-CN')
                          ? 'zh-CN'
                          : (langs.contains('en-US')
                              ? 'en-US'
                              : (langs.isNotEmpty ? langs.first : '')));
                      return _SelectRow(
                        label: l10n.ttsServicesPageLanguageLabel,
                        value: cur.isEmpty ? l10n.ttsServicesPageAutoLabel : cur,
                        options: langs,
                        onSelected: (picked) async {
                          await tts.setLanguageTag(picked);
                          if (ctx.mounted) (ctx as Element).markNeedsBuild();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.ttsServicesPageSpeechRateLabel, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
                  Slider(
                    value: rate,
                    min: 0.1,
                    max: 1.0,
                    onChanged: (v) {
                      rate = v;
                      if (ctx.mounted) (ctx as Element).markNeedsBuild();
                    },
                    onChangeEnd: (v) async => tts.setSpeechRate(v),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.ttsServicesPagePitchLabel, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
                  Slider(
                    value: pitch,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (v) {
                      pitch = v;
                      if (ctx.mounted) (ctx as Element).markNeedsBuild();
                    },
                    onChangeEnd: (v) async => tts.setPitch(v),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(lucide.Lucide.Check, size: 16),
                      label: Text(l10n.ttsServicesPageDoneButton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


// --------- Small UI helpers (local to this file) ---------

class _CircleIconBadge extends StatelessWidget {
  const _CircleIconBadge({required this.icon, this.size = 24});
  final IconData icon;
  final double size;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white12 : Colors.black.withOpacity(0.06);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.62, color: cs.onSurface.withOpacity(0.9)),
    );
  }
}

class _SmallIconBtn extends StatefulWidget {
  const _SmallIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<_SmallIconBtn> createState() => _SmallIconBtnState();
}

class _SmallIconBtnState extends State<_SmallIconBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _hover ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)) : Colors.transparent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 18, color: cs.onSurface),
        ),
      ),
    );
  }
}

Widget _sectionCard({required List<Widget> children}) {
  return Builder(builder: (context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? Colors.white10 : Colors.white.withOpacity(0.96);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(isDark ? 0.08 : 0.06), width: 0.6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
  });
}

Widget _deskDivider(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Divider(height: 6, thickness: 0.6, indent: 12, endIndent: 12, color: cs.outlineVariant.withOpacity(0.18));
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({required this.label, required this.value, required this.options, required this.onSelected});
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.9)))),
          _SelectButton(value: value, options: options, onSelected: onSelected),
        ],
      ),
    );
  }
}


class _SelectButton extends StatefulWidget {
  const _SelectButton({required this.value, required this.options, required this.onSelected});
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  @override
  State<_SelectButton> createState() => _SelectButtonState();
}

class _SelectButtonState extends State<_SelectButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = _hover ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)) : Colors.transparent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () async {
          final picked = await _showOptionsDialog(context, widget.options, widget.value);
          if (picked != null) widget.onSelected(picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.12), width: 0.6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.value, style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.9))),
              const SizedBox(width: 6),
              Icon(lucide.Lucide.ChevronDown, size: 16, color: cs.onSurface.withOpacity(0.8)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> _showOptionsDialog(BuildContext context, List<String> options, String current) async {
  if (options.isEmpty) return null;
  final cs = Theme.of(context).colorScheme;
  String? result;
  await showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < options.length; i++) ...[
                      _DialogOption(
                        label: options[i],
                        selected: options[i] == current,
                        onTap: () => Navigator.of(ctx).pop(options[i]),
                      ),
                      if (i != options.length - 1)
                        Divider(height: 10, thickness: 0.6, indent: 4, endIndent: 4, color: cs.outlineVariant.withOpacity(0.12)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  ).then((v) => result = v);
  return result;
}

class _DialogOption extends StatefulWidget {
  const _DialogOption({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_DialogOption> createState() => _DialogOptionState();
}

class _DialogOptionState extends State<_DialogOption> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.selected
        ? cs.primary.withOpacity(0.08)
        : (_hover ? (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)) : Colors.transparent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: Text(widget.label, style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.9)))),
            if (widget.selected) Icon(lucide.Lucide.Check, size: 16, color: cs.primary),
          ]),
        ),
      ),
    );
  }
}
