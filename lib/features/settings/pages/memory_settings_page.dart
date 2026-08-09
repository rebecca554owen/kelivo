import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Kelivo/theme/app_font_weights.dart';
import 'package:Kelivo/theme/app_semantic_colors.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/memory/memory_prompts.dart';
import '../../../desktop/setting/memory_dialogs.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_switch.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../../../utils/platform_utils.dart';
import '../../model/widgets/model_select_sheet.dart';
import '../widgets/memory_ui.dart';
import 'legacy_memory_page.dart';
import 'memory_about_page.dart';
import 'memory_entries_page.dart';
import 'memory_trace_page.dart';
import 'user_profile_page.dart';

/// Global memory settings (§4.2 / §14.4): model, thinking, prompt lang, templates.
class MemorySettingsPage extends StatelessWidget {
  const MemorySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
        title: Text(l10n.memorySettingsPageTitle),
      ),
      body: const MemorySettingsContent(),
    );
  }
}

class MemorySettingsContent extends StatelessWidget {
  const MemorySettingsContent({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final modelSet =
        settings.memoryModelProvider != null && settings.memoryModelId != null;

    final modelLabel = () {
      final p = settings.memoryModelProvider;
      final m = settings.memoryModelId;
      if (p == null || m == null) return l10n.memorySettingsModelUnset;
      final cfg = settings.getProviderConfig(p);
      final providerName = cfg.name.trim().isNotEmpty ? cfg.name.trim() : p;
      return '$providerName / $m';
    }();

    return ListView(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (!modelSet) ...[
          MemoryInfoBanner(body: l10n.memorySettingsModelTip),
          const SizedBox(height: 12),
        ],
        _SettingsSection(
          title: l10n.memorySettingsModelSection,
          titleTrailing: modelSet
              ? _ModelTipInfoIcon(tip: l10n.memorySettingsModelTip)
              : null,
          children: [
            _NavRow(
              title: l10n.memorySettingsModelTitle,
              subtitle: modelLabel,
              onTap: () async {
                final navigator = Navigator.of(context);
                final settingsApi = context.read<SettingsProvider>();
                final sel = await showModelSelector(
                  context,
                  initialProviderKey: settings.memoryModelProvider,
                  initialModelId: settings.memoryModelId,
                );
                if (sel == null) return;
                if (!navigator.mounted) return;
                await settingsApi.setMemoryModel(sel.providerKey, sel.modelId);
              },
            ),
            _SettingsRow(
              title: l10n.memorySettingsThinkingTitle,
              subtitle: l10n.memorySettingsThinkingSubtitle,
              trailing: IosSwitch(
                value: settings.memoryModelThinkingEnabled,
                semanticLabel: l10n.memorySettingsThinkingTitle,
                onChanged: (v) => context
                    .read<SettingsProvider>()
                    .setMemoryModelThinkingEnabled(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: l10n.memorySettingsPromptLangSection,
          children: [
            for (final lang in const ['auto', 'zh', 'en'])
              _LangRow(
                lang: lang,
                selected: settings.memoryPromptLang == lang,
                onTap: () =>
                    context.read<SettingsProvider>().setMemoryPromptLang(lang),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: l10n.memorySettingsPromptsSection,
          children: [
            for (final entry in _promptEntries(l10n))
              _NavRow(
                title: entry.title,
                subtitle: entry.subtitle,
                onTap: () => _openPromptEditor(context, entry),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsSection(
          title: l10n.memorySettingsEntriesSection,
          children: [
            _NavRow(
              title: l10n.memorySettingsEntriesTitle,
              subtitle: l10n.memorySettingsEntriesSubtitle,
              onTap: () => _openMemoryEntries(context),
            ),
            _NavRow(
              title: l10n.memorySettingsProfileTitle,
              subtitle: l10n.memorySettingsProfileSubtitle,
              onTap: () => _openUserProfile(context),
            ),
            _NavRow(
              title: l10n.memorySettingsLegacyTitle,
              subtitle: l10n.memorySettingsLegacySubtitle,
              onTap: () => _openLegacyMemory(context),
            ),
            _NavRow(
              title: l10n.memoryTraceSettingsTitle,
              subtitle: l10n.memoryTraceSettingsSubtitle,
              onTap: () => _openMemoryTrace(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        MemorySectionCard(
          padding: EdgeInsets.zero,
          children: [
            _NavRow(
              title: l10n.memorySettingsAboutTitle,
              subtitle: l10n.memorySettingsAboutSubtitle,
              onTap: () => _openMemoryAbout(context),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> _openMemoryEntries(BuildContext context) async {
  if (PlatformUtils.isDesktopTarget) {
    await showDesktopMemoryEntriesDialog(context);
    return;
  }
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MemoryEntriesPage()));
}

Future<void> _openUserProfile(BuildContext context) async {
  if (PlatformUtils.isDesktopTarget) {
    await showDesktopUserProfileMemoryDialog(context);
    return;
  }
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const UserProfilePage()));
}

Future<void> _openLegacyMemory(BuildContext context) async {
  if (PlatformUtils.isDesktopTarget) {
    await showDesktopLegacyMemoryDialog(context);
    return;
  }
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const LegacyMemoryPage()));
}

Future<void> _openMemoryTrace(BuildContext context) async {
  if (PlatformUtils.isDesktopTarget) {
    await showDesktopMemoryTraceDialog(context);
    return;
  }
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MemoryTracePage()));
}

Future<void> _openMemoryAbout(BuildContext context) async {
  if (PlatformUtils.isDesktopTarget) {
    await showDesktopMemoryAboutDialog(context);
    return;
  }
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MemoryAboutPage()));
}

class _PromptEntry {
  const _PromptEntry({
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String title;
  final String subtitle;
  final _PromptKind kind;
}

enum _PromptKind { rules, gate, extract, smartAdd, distill }

List<_PromptEntry> _promptEntries(AppLocalizations l10n) => [
  _PromptEntry(
    title: l10n.memoryPromptEditRulesTitle,
    subtitle: l10n.memoryPromptEditRulesSubtitle,
    kind: _PromptKind.rules,
  ),
  _PromptEntry(
    title: l10n.memoryPromptEditGateTitle,
    subtitle: l10n.memoryPromptEditGateSubtitle,
    kind: _PromptKind.gate,
  ),
  _PromptEntry(
    title: l10n.memoryPromptEditExtractTitle,
    subtitle: l10n.memoryPromptEditExtractSubtitle,
    kind: _PromptKind.extract,
  ),
  _PromptEntry(
    title: l10n.memoryPromptEditSmartAddTitle,
    subtitle: l10n.memoryPromptEditSmartAddSubtitle,
    kind: _PromptKind.smartAdd,
  ),
  _PromptEntry(
    title: l10n.memoryPromptEditDistillTitle,
    subtitle: l10n.memoryPromptEditDistillSubtitle,
    kind: _PromptKind.distill,
  ),
];

Future<void> _openPromptEditor(BuildContext context, _PromptEntry entry) async {
  if (PlatformUtils.isDesktopTarget) {
    final cs = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: cs.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 660),
          child: _MemoryPromptEditPage(entry: entry, desktopDialog: true),
        ),
      ),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => _MemoryPromptEditPage(entry: entry)),
  );
}

class _MemoryPromptEditPage extends StatefulWidget {
  const _MemoryPromptEditPage({
    required this.entry,
    this.desktopDialog = false,
  });

  final _PromptEntry entry;
  final bool desktopDialog;

  @override
  State<_MemoryPromptEditPage> createState() => _MemoryPromptEditPageState();
}

class _MemoryPromptEditPageState extends State<_MemoryPromptEditPage> {
  /// The prompt this editor writes.
  ///
  /// Templates are stored per language, but only the one matching
  /// [SettingsProvider.resolvedMemoryPromptLang] is ever sent to the model, so
  /// editing the other one is busywork on a string the user will never see.
  late final MemoryPromptLang _lang;
  late final TextEditingController _main;

  /// Smart Add runs a second, genuinely different prompt for batch candidates.
  TextEditingController? _batch;

  bool _hydrated = false;

  bool get _isSmartAdd => widget.entry.kind == _PromptKind.smartAdd;
  bool get _isZh => _lang == MemoryPromptLang.zh;

  @override
  void initState() {
    super.initState();
    _main = TextEditingController();
    if (_isSmartAdd) _batch = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final settings = context.read<SettingsProvider>();
    _lang = settings.resolvedMemoryPromptLang;
    _main.text = _load(settings);
    if (_isSmartAdd) {
      _batch!.text = _isZh
          ? settings.memorySmartAddBatchPromptZh
          : settings.memorySmartAddBatchPromptEn;
    }
  }

  String _load(SettingsProvider s) {
    switch (widget.entry.kind) {
      case _PromptKind.rules:
        return _isZh ? s.memoryRulesPromptZh : s.memoryRulesPromptEn;
      case _PromptKind.gate:
        return _isZh ? s.memoryGatePromptZh : s.memoryGatePromptEn;
      case _PromptKind.extract:
        return _isZh ? s.memoryExtractPromptZh : s.memoryExtractPromptEn;
      case _PromptKind.smartAdd:
        return _isZh ? s.memorySmartAddPromptZh : s.memorySmartAddPromptEn;
      case _PromptKind.distill:
        return _isZh
            ? s.memoryProfileDistillPromptZh
            : s.memoryProfileDistillPromptEn;
    }
  }

  Future<void> _save() async {
    final s = context.read<SettingsProvider>();
    final text = _main.text;
    switch (widget.entry.kind) {
      case _PromptKind.rules:
        await (_isZh
            ? s.setMemoryRulesPromptZh(text)
            : s.setMemoryRulesPromptEn(text));
        break;
      case _PromptKind.gate:
        await (_isZh
            ? s.setMemoryGatePromptZh(text)
            : s.setMemoryGatePromptEn(text));
        break;
      case _PromptKind.extract:
        await (_isZh
            ? s.setMemoryExtractPromptZh(text)
            : s.setMemoryExtractPromptEn(text));
        break;
      case _PromptKind.smartAdd:
        await (_isZh
            ? s.setMemorySmartAddPromptZh(text)
            : s.setMemorySmartAddPromptEn(text));
        await (_isZh
            ? s.setMemorySmartAddBatchPromptZh(_batch!.text)
            : s.setMemorySmartAddBatchPromptEn(_batch!.text));
        break;
      case _PromptKind.distill:
        await (_isZh
            ? s.setMemoryProfileDistillPromptZh(text)
            : s.setMemoryProfileDistillPromptEn(text));
        break;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _reset() async {
    final s = context.read<SettingsProvider>();
    switch (widget.entry.kind) {
      case _PromptKind.rules:
        await (_isZh
            ? s.resetMemoryRulesPromptZh()
            : s.resetMemoryRulesPromptEn());
        _main.text = _isZh ? MemoryPrompts.rulesZh : MemoryPrompts.rulesEn;
        break;
      case _PromptKind.gate:
        await (_isZh
            ? s.resetMemoryGatePromptZh()
            : s.resetMemoryGatePromptEn());
        _main.text = _isZh ? MemoryPrompts.gateZh : MemoryPrompts.gateEn;
        break;
      case _PromptKind.extract:
        await (_isZh
            ? s.resetMemoryExtractPromptZh()
            : s.resetMemoryExtractPromptEn());
        _main.text = _isZh ? MemoryPrompts.extractZh : MemoryPrompts.extractEn;
        break;
      case _PromptKind.smartAdd:
        await (_isZh
            ? s.resetMemorySmartAddPromptZh()
            : s.resetMemorySmartAddPromptEn());
        await (_isZh
            ? s.resetMemorySmartAddBatchPromptZh()
            : s.resetMemorySmartAddBatchPromptEn());
        _main.text = _isZh
            ? MemoryPrompts.smartAddZh
            : MemoryPrompts.smartAddEn;
        _batch!.text = _isZh
            ? MemoryPrompts.smartAddBatchZh
            : MemoryPrompts.smartAddBatchEn;
        break;
      case _PromptKind.distill:
        await (_isZh
            ? s.resetMemoryProfileDistillPromptZh()
            : s.resetMemoryProfileDistillPromptEn());
        _main.text = _isZh
            ? MemoryPrompts.profileDistillZh
            : MemoryPrompts.profileDistillEn;
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _main.dispose();
    _batch?.dispose();
    super.dispose();
  }

  Widget _buildEditorBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        widget.desktopDialog ? 20 : 16,
        12,
        widget.desktopDialog ? 20 : 16,
        widget.desktopDialog ? 24 : 32,
      ),
      children: [
        Text(
          widget.entry.subtitle,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: cs.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 14),
        if (_isSmartAdd) ...[
          _PromptFieldLabel(text: l10n.memoryPromptEditSectionPerItem),
          const SizedBox(height: 6),
        ],
        _PromptField(controller: _main),
        if (_isSmartAdd) ...[
          const SizedBox(height: 18),
          _PromptFieldLabel(text: l10n.memoryPromptEditSectionBatch),
          const SizedBox(height: 6),
          _PromptField(controller: _batch!),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (widget.desktopDialog) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: AppFontWeights.emphasis,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: l10n.memoryPromptEditReset,
                    child: IosIconButton(
                      icon: Lucide.RotateCcw,
                      color: cs.onSurface,
                      size: 18,
                      minSize: 36,
                      semanticLabel: l10n.memoryPromptEditReset,
                      onTap: _reset,
                    ),
                  ),
                  Tooltip(
                    message: l10n.memoryPromptEditSave,
                    child: IosIconButton(
                      icon: Lucide.Check,
                      color: cs.primary,
                      size: 18,
                      minSize: 36,
                      semanticLabel: l10n.memoryPromptEditSave,
                      onTap: _save,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Lucide.X, size: 18),
                    color: cs.onSurface,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: cs.outlineVariant.withValues(alpha: 0.12),
          ),
          Expanded(child: _buildEditorBody(context)),
        ],
      );
    }

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
        title: Text(widget.entry.title),
        actions: [
          Tooltip(
            message: l10n.memoryPromptEditReset,
            child: IosIconButton(
              icon: Lucide.RotateCcw,
              color: cs.onSurface,
              size: 20,
              minSize: 44,
              semanticLabel: l10n.memoryPromptEditReset,
              onTap: _reset,
            ),
          ),
          Tooltip(
            message: l10n.memoryPromptEditSave,
            child: IosIconButton(
              icon: Lucide.Check,
              color: cs.primary,
              size: 20,
              minSize: 44,
              semanticLabel: l10n.memoryPromptEditSave,
              onTap: _save,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildEditorBody(context),
    );
  }
}

class _PromptFieldLabel extends StatelessWidget {
  const _PromptFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: AppFontWeights.semibold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _PromptField extends StatelessWidget {
  const _PromptField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: 12,
        textAlignVertical: TextAlignVertical.top,
        style: TextStyle(fontSize: 13.5, height: 1.5, color: cs.onSurface),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _ModelTipInfoIcon extends StatelessWidget {
  const _ModelTipInfoIcon({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tip,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            Lucide.BadgeInfo,
            size: 16,
            color: cs.onSurface.withValues(alpha: 0.45),
            semanticLabel: tip,
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.titleTrailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = context.appColors.surfaceCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: AppFontWeights.semibold,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              if (titleTrailing != null) titleTrailing!,
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.06),
              width: 0.6,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const _SettingsDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: _RowText(title: title, subtitle: subtitle),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: _RowText(title: title, subtitle: subtitle),
            ),
            const SizedBox(width: 8),
            Icon(
              Lucide.ChevronRight,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final String lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final title = switch (lang) {
      'zh' => l10n.memorySettingsPromptLangZh,
      'en' => l10n.memorySettingsPromptLangEn,
      _ => l10n.memorySettingsPromptLangAuto,
    };
    final subtitle = switch (lang) {
      'zh' => l10n.memorySettingsPromptLangZhSubtitle,
      'en' => l10n.memorySettingsPromptLangEnSubtitle,
      _ => l10n.memorySettingsPromptLangAutoSubtitle,
    };
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
              child: _RowText(title: title, subtitle: subtitle),
            ),
            const SizedBox(width: 12),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Icon(Lucide.Check, size: 18, color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: AppFontWeights.semibold,
            color: cs.onSurface.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            height: 1.25,
            color: cs.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 14,
      endIndent: 12,
      color: cs.outlineVariant.withValues(alpha: 0.18),
    );
  }
}
