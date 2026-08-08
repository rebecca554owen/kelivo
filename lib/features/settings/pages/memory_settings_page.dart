import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Kelivo/theme/app_font_weights.dart';
import 'package:Kelivo/theme/app_semantic_colors.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/services/memory/memory_prompts.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_switch.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../../model/widgets/model_select_sheet.dart';
import 'legacy_memory_page.dart';
import 'memory_entries_page.dart';
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

    final modelLabel = () {
      final p = settings.memoryModelProvider;
      final m = settings.memoryModelId;
      if (p == null || m == null) return l10n.memorySettingsModelUnset;
      return '$p / $m';
    }();

    return ListView(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SettingsSection(
          title: l10n.memorySettingsModelSection,
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
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MemoryEntriesPage()),
                );
              },
            ),
            _NavRow(
              title: l10n.memorySettingsProfileTitle,
              subtitle: l10n.memorySettingsProfileSubtitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const UserProfilePage()),
                );
              },
            ),
            _NavRow(
              title: l10n.memorySettingsLegacyTitle,
              subtitle: l10n.memorySettingsLegacySubtitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LegacyMemoryPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
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
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => _MemoryPromptEditPage(entry: entry)),
  );
}

class _MemoryPromptEditPage extends StatefulWidget {
  const _MemoryPromptEditPage({required this.entry});

  final _PromptEntry entry;

  @override
  State<_MemoryPromptEditPage> createState() => _MemoryPromptEditPageState();
}

class _MemoryPromptEditPageState extends State<_MemoryPromptEditPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _zh;
  late final TextEditingController _en;
  TextEditingController? _batchZh;
  TextEditingController? _batchEn;
  bool _hydrated = false;

  bool get _isSmartAdd => widget.entry.kind == _PromptKind.smartAdd;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _isSmartAdd ? 4 : 2, vsync: this);
    _zh = TextEditingController();
    _en = TextEditingController();
    if (_isSmartAdd) {
      _batchZh = TextEditingController();
      _batchEn = TextEditingController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final settings = context.read<SettingsProvider>();
    final pair = _load(settings);
    _zh.text = pair.$1;
    _en.text = pair.$2;
    if (_isSmartAdd) {
      _batchZh!.text = settings.memorySmartAddBatchPromptZh;
      _batchEn!.text = settings.memorySmartAddBatchPromptEn;
    }
  }

  (String, String) _load(SettingsProvider s) {
    switch (widget.entry.kind) {
      case _PromptKind.rules:
        return (s.memoryRulesPromptZh, s.memoryRulesPromptEn);
      case _PromptKind.gate:
        return (s.memoryGatePromptZh, s.memoryGatePromptEn);
      case _PromptKind.extract:
        return (s.memoryExtractPromptZh, s.memoryExtractPromptEn);
      case _PromptKind.smartAdd:
        return (s.memorySmartAddPromptZh, s.memorySmartAddPromptEn);
      case _PromptKind.distill:
        return (s.memoryProfileDistillPromptZh, s.memoryProfileDistillPromptEn);
    }
  }

  Future<void> _save() async {
    final s = context.read<SettingsProvider>();
    switch (widget.entry.kind) {
      case _PromptKind.rules:
        await s.setMemoryRulesPromptZh(_zh.text);
        await s.setMemoryRulesPromptEn(_en.text);
        break;
      case _PromptKind.gate:
        await s.setMemoryGatePromptZh(_zh.text);
        await s.setMemoryGatePromptEn(_en.text);
        break;
      case _PromptKind.extract:
        await s.setMemoryExtractPromptZh(_zh.text);
        await s.setMemoryExtractPromptEn(_en.text);
        break;
      case _PromptKind.smartAdd:
        await s.setMemorySmartAddPromptZh(_zh.text);
        await s.setMemorySmartAddPromptEn(_en.text);
        await s.setMemorySmartAddBatchPromptZh(_batchZh!.text);
        await s.setMemorySmartAddBatchPromptEn(_batchEn!.text);
        break;
      case _PromptKind.distill:
        await s.setMemoryProfileDistillPromptZh(_zh.text);
        await s.setMemoryProfileDistillPromptEn(_en.text);
        break;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _reset() async {
    final s = context.read<SettingsProvider>();
    switch (widget.entry.kind) {
      case _PromptKind.rules:
        await s.resetMemoryRulesPromptZh();
        await s.resetMemoryRulesPromptEn();
        _zh.text = MemoryPrompts.rulesZh;
        _en.text = MemoryPrompts.rulesEn;
        break;
      case _PromptKind.gate:
        await s.resetMemoryGatePromptZh();
        await s.resetMemoryGatePromptEn();
        _zh.text = MemoryPrompts.gateZh;
        _en.text = MemoryPrompts.gateEn;
        break;
      case _PromptKind.extract:
        await s.resetMemoryExtractPromptZh();
        await s.resetMemoryExtractPromptEn();
        _zh.text = MemoryPrompts.extractZh;
        _en.text = MemoryPrompts.extractEn;
        break;
      case _PromptKind.smartAdd:
        await s.resetMemorySmartAddPromptZh();
        await s.resetMemorySmartAddPromptEn();
        await s.resetMemorySmartAddBatchPromptZh();
        await s.resetMemorySmartAddBatchPromptEn();
        _zh.text = MemoryPrompts.smartAddZh;
        _en.text = MemoryPrompts.smartAddEn;
        _batchZh!.text = MemoryPrompts.smartAddBatchZh;
        _batchEn!.text = MemoryPrompts.smartAddBatchEn;
        break;
      case _PromptKind.distill:
        await s.resetMemoryProfileDistillPromptZh();
        await s.resetMemoryProfileDistillPromptEn();
        _zh.text = MemoryPrompts.profileDistillZh;
        _en.text = MemoryPrompts.profileDistillEn;
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _zh.dispose();
    _en.dispose();
    _batchZh?.dispose();
    _batchEn?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final labels = _isSmartAdd
        ? [
            l10n.memoryPromptEditTabPerItemZh,
            l10n.memoryPromptEditTabPerItemEn,
            l10n.memoryPromptEditTabBatchZh,
            l10n.memoryPromptEditTabBatchEn,
          ]
        : [l10n.memoryPromptEditTabZh, l10n.memoryPromptEditTabEn];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.entry.title),
        actions: [
          TextButton(
            onPressed: _reset,
            child: Text(l10n.memoryPromptEditReset),
          ),
          TextButton(onPressed: _save, child: Text(l10n.memoryPromptEditSave)),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [for (final t in labels) Tab(text: t)],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PromptField(controller: _zh),
          _PromptField(controller: _en),
          if (_isSmartAdd) ...[
            _PromptField(controller: _batchZh!),
            _PromptField(controller: _batchEn!),
          ],
        ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          filled: true,
          fillColor: context.appColors.surfaceFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: AppFontWeights.semibold,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
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
