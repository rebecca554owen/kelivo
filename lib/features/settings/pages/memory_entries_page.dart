import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Kelivo/theme/app_font_weights.dart';
import 'package:Kelivo/theme/app_semantic_colors.dart';

import '../../../core/models/memory_entry.dart';
import '../../../core/providers/assistant_provider.dart';
import '../../../core/providers/memory_provider_v2.dart';
import '../../../core/services/memory/memory_tools.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../widgets/memory_ui.dart';

/// Global memory list with search, filters, batch delete, orphan cleanup (§14.4).
class MemoryEntriesPage extends StatelessWidget {
  const MemoryEntriesPage({super.key});

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
        title: Text(l10n.memoryEntriesPageTitle),
      ),
      body: const MemoryEntriesContent(),
    );
  }
}

class MemoryEntriesContent extends StatefulWidget {
  const MemoryEntriesContent({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  State<MemoryEntriesContent> createState() => _MemoryEntriesContentState();
}

enum _ScopeFilter { all, global, assistant }

enum _StatusFilter { all, active, archived }

class _MemoryEntriesContentState extends State<MemoryEntriesContent> {
  final _search = TextEditingController();
  _ScopeFilter _scope = _ScopeFilter.all;
  MemoryType? _type;
  _StatusFilter _status = _StatusFilter.all;
  String? _assistantFilterId;
  final Set<String> _selected = {};
  bool _selecting = false;
  List<MemoryEntry>? _searchResults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MemoryProviderV2>().initialize(loadAll: true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    final tokens = MemoryTools.searchTokens(q);
    if (tokens.isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    final results = await context.read<MemoryProviderV2>().search(
      tokens: tokens,
      acrossAll: true,
      includeArchived: true,
      type: _type,
    );
    if (!mounted) return;
    setState(() => _searchResults = results);
  }

  List<MemoryEntry> _filtered(List<MemoryEntry> source) {
    return source
        .where((e) {
          if (_type != null && e.type != _type) return false;
          switch (_scope) {
            case _ScopeFilter.all:
              break;
            case _ScopeFilter.global:
              if (e.scope != MemoryScope.global) return false;
            case _ScopeFilter.assistant:
              if (e.scope != MemoryScope.assistant) return false;
              if (_assistantFilterId != null &&
                  e.assistantId != _assistantFilterId) {
                return false;
              }
          }
          switch (_status) {
            case _StatusFilter.all:
              break;
            case _StatusFilter.active:
              if (e.status != MemoryStatus.active) return false;
            case _StatusFilter.archived:
              if (e.status != MemoryStatus.archived) return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  Future<void> _showEditSheet({MemoryEntry? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    var type = existing?.type ?? MemoryType.identity;
    var scope = existing?.scope ?? MemoryScope.global;
    String? assistantId = existing?.assistantId;
    final assistants = context.read<AssistantProvider>().assistants;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? l10n.memoryEntryCreateTitle
                    : l10n.memoryEntryEditTitle,
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: contentCtrl,
                      minLines: 3,
                      maxLines: 8,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.memoryEntryContentHint,
                        filled: true,
                        fillColor: ctx.appColors.surfaceFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.memoryEntryTypeLabel, style: _labelStyle(cs)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in MemoryType.values)
                          ChoiceChip(
                            label: Text(memoryTypeLabel(l10n, t)),
                            selected: type == t,
                            onSelected: existing != null
                                ? null
                                : (_) => setLocal(() => type = t),
                          ),
                      ],
                    ),
                    if (existing == null) ...[
                      const SizedBox(height: 12),
                      Text(l10n.memoryEntryScopeLabel, style: _labelStyle(cs)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.memoryEntryScopeGlobal),
                            selected: scope == MemoryScope.global,
                            onSelected: (_) => setLocal(() {
                              scope = MemoryScope.global;
                              assistantId = null;
                            }),
                          ),
                          ChoiceChip(
                            label: Text(l10n.memoryEntryScopeAssistant),
                            selected: scope == MemoryScope.assistant,
                            onSelected: (_) => setLocal(() {
                              scope = MemoryScope.assistant;
                              assistantId ??= assistants.isNotEmpty
                                  ? assistants.first.id
                                  : null;
                            }),
                          ),
                        ],
                      ),
                      if (scope == MemoryScope.assistant) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: assistantId,
                          items: [
                            for (final a in assistants)
                              DropdownMenuItem(
                                value: a.id,
                                child: Text(a.name),
                              ),
                          ],
                          onChanged: (v) => setLocal(() => assistantId = v),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.assistantEditEmojiDialogCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text(l10n.assistantEditEmojiDialogSave),
                ),
              ],
            );
          },
        );
      },
    );

    final text = contentCtrl.text.trim();
    contentCtrl.dispose();
    if (saved != true || text.isEmpty || !mounted) return;
    final mp = context.read<MemoryProviderV2>();
    if (existing == null) {
      if (scope == MemoryScope.assistant &&
          (assistantId == null || assistantId!.isEmpty)) {
        return;
      }
      await mp.create(
        scope: scope,
        assistantId: scope == MemoryScope.assistant ? assistantId : null,
        type: type,
        content: text,
        source: MemorySource.manual,
      );
    } else {
      await mp.updateContent(existing.id, text);
    }
  }

  TextStyle _labelStyle(ColorScheme cs) => TextStyle(
    fontSize: 12.5,
    fontWeight: AppFontWeights.semibold,
    color: cs.onSurface.withValues(alpha: 0.7),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final mp = context.watch<MemoryProviderV2>();
    final ap = context.watch<AssistantProvider>();
    final source = _searchResults ?? mp.entries;
    final filtered = _filtered(source);
    final active = filtered
        .where((e) => e.status == MemoryStatus.active)
        .toList();
    final archived = filtered
        .where((e) => e.status == MemoryStatus.archived)
        .toList();

    return Column(
      children: [
        Padding(
          padding: widget.padding == null
              ? const EdgeInsets.fromLTRB(16, 8, 16, 4)
              : const EdgeInsets.fromLTRB(0, 0, 0, 4),
          child: TextField(
            controller: _search,
            onChanged: _runSearch,
            decoration: InputDecoration(
              hintText: l10n.memorySearchHint,
              prefixIcon: Icon(Lucide.Search, size: 18, color: cs.onSurface),
              filled: true,
              fillColor: context.appColors.surfaceFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: switch (_scope) {
                  _ScopeFilter.all => l10n.memoryFilterScopeAll,
                  _ScopeFilter.global => l10n.memoryFilterScopeGlobal,
                  _ScopeFilter.assistant => l10n.memoryFilterScopeAssistant,
                },
                onTap: () async {
                  final next = await showModalBottomSheet<_ScopeFilter>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final v in _ScopeFilter.values)
                            ListTile(
                              title: Text(switch (v) {
                                _ScopeFilter.all => l10n.memoryFilterScopeAll,
                                _ScopeFilter.global =>
                                  l10n.memoryFilterScopeGlobal,
                                _ScopeFilter.assistant =>
                                  l10n.memoryFilterScopeAssistant,
                              }),
                              onTap: () => Navigator.pop(ctx, v),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (next != null) setState(() => _scope = next);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _type == null
                    ? l10n.memoryFilterTypeAll
                    : memoryTypeLabel(l10n, _type!),
                onTap: () async {
                  final next = await showModalBottomSheet<MemoryType?>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(l10n.memoryFilterTypeAll),
                            onTap: () => Navigator.pop(ctx, null),
                          ),
                          for (final t in MemoryType.values)
                            ListTile(
                              title: Text(memoryTypeLabel(l10n, t)),
                              onTap: () => Navigator.pop(ctx, t),
                            ),
                        ],
                      ),
                    ),
                  );
                  setState(() => _type = next);
                  if (_search.text.trim().isNotEmpty) {
                    await _runSearch(_search.text);
                  }
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: switch (_status) {
                  _StatusFilter.all => l10n.memoryFilterStatusAll,
                  _StatusFilter.active => l10n.memoryFilterStatusActive,
                  _StatusFilter.archived => l10n.memoryFilterStatusArchived,
                },
                onTap: () async {
                  final next = await showModalBottomSheet<_StatusFilter>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final v in _StatusFilter.values)
                            ListTile(
                              title: Text(switch (v) {
                                _StatusFilter.all => l10n.memoryFilterStatusAll,
                                _StatusFilter.active =>
                                  l10n.memoryFilterStatusActive,
                                _StatusFilter.archived =>
                                  l10n.memoryFilterStatusArchived,
                              }),
                              onTap: () => Navigator.pop(ctx, v),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (next != null) setState(() => _status = next);
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: _selecting
                    ? l10n.memoryEntryActionBatchDelete
                    : l10n.providersPageMultiSelectTooltip,
                emphasized: _selecting,
                onTap: () async {
                  if (!_selecting) {
                    setState(() => _selecting = true);
                    return;
                  }
                  if (_selected.isEmpty) {
                    setState(() {
                      _selecting = false;
                      _selected.clear();
                    });
                    return;
                  }
                  final mp = context.read<MemoryProviderV2>();
                  final ids = _selected.toList();
                  if (!await confirmBatchHardDelete(
                    context,
                    count: ids.length,
                  )) {
                    return;
                  }
                  if (!mounted) return;
                  await mp.hardDeleteMany(ids);
                  setState(() {
                    _selected.clear();
                    _selecting = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: l10n.memoryEntryActionAdd,
                emphasized: true,
                onTap: () => _showEditSheet(),
              ),
            ],
          ),
        ),
        if (_scope == _ScopeFilter.assistant)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: DropdownButtonFormField<String?>(
              initialValue: _assistantFilterId,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: context.appColors.surfaceFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.memoryFilterScopeAll),
                ),
                for (final a in ap.assistants)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
              ],
              onChanged: (v) => setState(() => _assistantFilterId = v),
            ),
          ),
        const MemoryOrphanBanner(),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _searchResults != null
                        ? l10n.memorySearchEmpty
                        : l10n.memoryEntryEmpty,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                )
              : ListView(
                  padding: widget.padding ?? const EdgeInsets.only(bottom: 24),
                  children: [
                    ...active.map(
                      (e) => MemoryEntryCard(
                        entry: e,
                        assistantName: resolveAssistantName(
                          context,
                          e.assistantId,
                        ),
                        selectable: _selecting,
                        selected: _selected.contains(e.id),
                        onSelectedChanged: (v) {
                          setState(() {
                            if (v) {
                              _selected.add(e.id);
                            } else {
                              _selected.remove(e.id);
                            }
                          });
                        },
                        onEdit: () => _showEditSheet(existing: e),
                      ),
                    ),
                    if (archived.isNotEmpty &&
                        (_status == _StatusFilter.all ||
                            _status == _StatusFilter.archived)) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          l10n.memoryEntryArchivedSection,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: AppFontWeights.emphasis,
                          ),
                        ),
                      ),
                      ...archived.map(
                        (e) => MemoryEntryCard(
                          entry: e,
                          assistantName: resolveAssistantName(
                            context,
                            e.assistantId,
                          ),
                          selectable: _selecting,
                          selected: _selected.contains(e.id),
                          onSelectedChanged: (v) {
                            setState(() {
                              if (v) {
                                _selected.add(e.id);
                              } else {
                                _selected.remove(e.id);
                              }
                            });
                          },
                          onEdit: () => _showEditSheet(existing: e),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IosCardPress(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      baseColor: emphasized
          ? cs.primary.withValues(alpha: 0.12)
          : context.appColors.surfaceFill,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: AppFontWeights.semibold,
              color: emphasized
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Lucide.ChevronDown,
            size: 14,
            color: emphasized
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
