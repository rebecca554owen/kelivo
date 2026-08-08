import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:Kelivo/theme/app_font_weights.dart';
import 'package:Kelivo/theme/app_semantic_colors.dart';

import '../../../core/models/memory_entry.dart';
import '../../../core/providers/assistant_provider.dart';
import '../../../core/providers/memory_provider_v2.dart';
import '../../../desktop/desktop_context_menu.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_tactile.dart';

final DateFormat memoryEntryDateFormat = DateFormat('yyyy-MM-dd');

String memoryTypeLabel(AppLocalizations l10n, MemoryType type) {
  switch (type) {
    case MemoryType.identity:
      return l10n.memoryEntryTypeIdentity;
    case MemoryType.workflow:
      return l10n.memoryEntryTypeWorkflow;
    case MemoryType.voice:
      return l10n.memoryEntryTypeVoice;
    case MemoryType.instruction:
      return l10n.memoryEntryTypeInstruction;
  }
}

String memorySourceLabel(AppLocalizations l10n, MemorySource source) {
  switch (source) {
    case MemorySource.manual:
      return l10n.memoryEntrySourceManual;
    case MemorySource.tool:
      return l10n.memoryEntrySourceTool;
    case MemorySource.extracted:
      return l10n.memoryEntrySourceExtracted;
    case MemorySource.distilled:
      return l10n.memoryEntrySourceDistilled;
  }
}

Color memoryTypeColor(ColorScheme cs, MemoryType type) {
  switch (type) {
    case MemoryType.identity:
      return cs.primary;
    case MemoryType.workflow:
      return cs.tertiary;
    case MemoryType.voice:
      return cs.secondary;
    case MemoryType.instruction:
      return cs.error;
  }
}

String memoryScopeLabel(
  AppLocalizations l10n,
  MemoryEntry entry, {
  String? assistantName,
  bool useThisAssistant = false,
}) {
  if (entry.scope == MemoryScope.global) {
    return l10n.memoryEntryScopeGlobal;
  }
  if (useThisAssistant || assistantName == null || assistantName.isEmpty) {
    return l10n.memoryEntryScopeAssistant;
  }
  return l10n.memoryEntryScopeAssistantNamed(assistantName);
}

Future<bool> confirmHardDeleteMemory(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.memoryEntryDeleteConfirmTitle),
      content: Text(l10n.memoryEntryDeleteConfirmContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.homePageCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.memoryEntryActionDelete),
        ),
      ],
    ),
  );
  return result == true;
}

Future<bool> confirmBatchHardDelete(
  BuildContext context, {
  required int count,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.memoryEntryBatchDeleteConfirmTitle(count)),
      content: Text(l10n.memoryEntryBatchDeleteConfirmContent),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.homePageCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.memoryEntryActionDelete),
        ),
      ],
    ),
  );
  return result == true;
}

Future<bool> confirmOrphanCleanup(
  BuildContext context, {
  required int count,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.memoryOrphanConfirmTitle),
      content: Text(l10n.memoryOrphanConfirmContent(count)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.homePageCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.memoryOrphanCleanupButton),
        ),
      ],
    ),
  );
  return result == true;
}

Future<bool> confirmScopeSwitch(
  BuildContext context, {
  required bool toGlobal,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.memoryEntrySwitchScopeConfirmTitle),
      content: Text(
        toGlobal
            ? l10n.memoryEntrySwitchScopeToGlobal
            : l10n.memoryEntrySwitchScopeToAssistant,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.homePageCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.memoryEntryActionSwitchScope),
        ),
      ],
    ),
  );
  return result == true;
}

class MemoryBadge extends StatelessWidget {
  const MemoryBadge({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: AppFontWeights.semibold,
          color: color,
          height: 1.1,
        ),
      ),
    );
    if (onTap == null) return child;
    return IosCardPress(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      padding: EdgeInsets.zero,
      baseColor: Colors.transparent,
      child: child,
    );
  }
}

class MemoryEntryCard extends StatelessWidget {
  const MemoryEntryCard({
    super.key,
    required this.entry,
    this.assistantName,
    this.useThisAssistantLabel = false,
    this.selectable = false,
    this.selected = false,
    this.onSelectedChanged,
    this.scopeToggleAssistantId,
    this.onEdit,
  });

  final MemoryEntry entry;
  final String? assistantName;
  final bool useThisAssistantLabel;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  /// When non-null, scope badge toggles between global and this assistant.
  final String? scopeToggleAssistantId;
  final VoidCallback? onEdit;

  Future<void> _archive(BuildContext context) async {
    await context.read<MemoryProviderV2>().archive(entry.id);
  }

  Future<void> _restore(BuildContext context) async {
    await context.read<MemoryProviderV2>().restore(entry.id);
  }

  Future<void> _hardDelete(BuildContext context) async {
    if (!await confirmHardDeleteMemory(context)) return;
    if (!context.mounted) return;
    await context.read<MemoryProviderV2>().hardDelete(entry.id);
  }

  Future<void> _toggleScope(BuildContext context) async {
    final assistantId = scopeToggleAssistantId;
    if (assistantId == null) return;
    final toGlobal = entry.scope == MemoryScope.assistant;
    if (!await confirmScopeSwitch(context, toGlobal: toGlobal)) return;
    if (!context.mounted) return;
    final mp = context.read<MemoryProviderV2>();
    if (toGlobal) {
      await mp.updateScope(entry.id, scope: MemoryScope.global);
    } else {
      await mp.updateScope(
        entry.id,
        scope: MemoryScope.assistant,
        assistantId: assistantId,
      );
    }
  }

  Future<void> _showContextMenu(BuildContext context, Offset global) async {
    final l10n = AppLocalizations.of(context)!;
    final items = <DesktopContextMenuItem>[
      if (entry.status == MemoryStatus.active)
        DesktopContextMenuItem(
          icon: Lucide.Bookmark,
          label: l10n.memoryEntryActionArchive,
          onTap: () => _archive(context),
        )
      else
        DesktopContextMenuItem(
          icon: Lucide.RotateCcw,
          label: l10n.memoryEntryActionRestore,
          onTap: () => _restore(context),
        ),
      DesktopContextMenuItem(
        icon: Lucide.Trash2,
        label: l10n.memoryEntryActionDelete,
        danger: true,
        onTap: () => _hardDelete(context),
      ),
    ];
    await showDesktopContextMenuAt(
      context,
      globalPosition: global,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeColor = memoryTypeColor(cs, entry.type);
    final scopeColor = entry.scope == MemoryScope.global
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.65);
    final date = memoryEntryDateFormat.format(entry.updatedAt.toLocal());
    final meta =
        '${l10n.memoryEntryUpdatedAt(date)} · ${memorySourceLabel(l10n, entry.source)}';

    final card = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.45)
                : cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.06),
            width: 0.6,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (selectable) ...[
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: selected,
                        onChanged: (v) => onSelectedChanged?.call(v ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  MemoryBadge(
                    label: memoryTypeLabel(l10n, entry.type),
                    color: typeColor,
                  ),
                  const SizedBox(width: 6),
                  MemoryBadge(
                    label: memoryScopeLabel(
                      l10n,
                      entry,
                      assistantName: assistantName,
                      useThisAssistant: useThisAssistantLabel,
                    ),
                    color: scopeColor,
                    onTap: scopeToggleAssistantId == null
                        ? null
                        : () => _toggleScope(context),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    _IconAction(
                      icon: Lucide.Pencil,
                      color: cs.primary,
                      tooltip: l10n.memoryEntryActionEdit,
                      onTap: onEdit!,
                    ),
                  const SizedBox(width: 4),
                  _IconAction(
                    icon: Lucide.Trash2,
                    color: cs.error,
                    tooltip: l10n.memoryEntryActionDelete,
                    onTap: () => _hardDelete(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.content,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.35),
              ),
              const SizedBox(height: 6),
              Text(
                meta,
                style: TextStyle(
                  fontSize: 11.5,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onLongPressStart: (details) {
        HapticFeedback.mediumImpact();
        unawaited(_showContextMenu(context, details.globalPosition));
      },
      onSecondaryTapDown: (details) {
        unawaited(_showContextMenu(context, details.globalPosition));
      },
      child: card,
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IosIconButton(
        icon: icon,
        color: color,
        size: 18,
        minSize: 32,
        onTap: onTap,
      ),
    );
  }
}

class MemoryModelMissingNotice extends StatelessWidget {
  const MemoryModelMissingNotice({super.key, required this.onGoSelect});

  final VoidCallback onGoSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Material(
        color: cs.errorContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Lucide.MessageCircleWarning, size: 18, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.memoryModelMissingNotice,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IosCardPress(
                      onTap: onGoSelect,
                      borderRadius: BorderRadius.circular(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      baseColor: cs.primary.withValues(alpha: 0.12),
                      child: Text(
                        l10n.memoryModelMissingGoSelect,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: AppFontWeights.semibold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryOrphanBanner extends StatelessWidget {
  const MemoryOrphanBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final count = context.watch<MemoryProviderV2>().orphanCount;
    if (count <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: cs.errorContainer.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Icon(Lucide.TriangleAlert, size: 18, color: cs.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.memoryOrphanBanner(count),
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  if (!await confirmOrphanCleanup(context, count: count)) {
                    return;
                  }
                  if (!context.mounted) return;
                  await context
                      .read<MemoryProviderV2>()
                      .deleteOrphanAssistantMemories();
                },
                child: Text(l10n.memoryOrphanCleanupButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? resolveAssistantName(BuildContext context, String? assistantId) {
  if (assistantId == null) return null;
  return context.read<AssistantProvider>().getById(assistantId)?.name;
}
