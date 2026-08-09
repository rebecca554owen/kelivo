import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:Kelivo/theme/app_font_weights.dart';
import 'package:Kelivo/theme/app_semantic_colors.dart';

import '../../../core/models/assistant_memory.dart';
import '../../../core/providers/assistant_provider.dart';
import '../../../core/providers/memory_provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../../../shared/widgets/snackbar.dart';
import '../widgets/memory_ui.dart';

/// Read-only legacy memories from [MemoryProvider] (§14.5 / D-29).
class LegacyMemoryPage extends StatelessWidget {
  const LegacyMemoryPage({super.key, this.assistantId});

  /// When set, only legacy memories of that assistant are listed and exported.
  final String? assistantId;

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
        title: Text(l10n.legacyMemoryPageTitle),
        actions: [
          Tooltip(
            message: l10n.legacyMemoryExport,
            child: IosIconButton(
              icon: Lucide.Share2,
              color: cs.onSurface,
              size: 20,
              minSize: 44,
              onTap: () => LegacyMemoryContent.exportAll(
                context,
                assistantId: assistantId,
              ),
            ),
          ),
        ],
      ),
      body: LegacyMemoryContent(assistantId: assistantId),
    );
  }
}

class LegacyMemoryContent extends StatefulWidget {
  const LegacyMemoryContent({super.key, this.padding, this.assistantId});

  final EdgeInsetsGeometry? padding;

  /// When set, only legacy memories of that assistant are listed.
  final String? assistantId;

  static String buildExportText({
    required AppLocalizations l10n,
    required List<AssistantMemory> memories,
    required String Function(String assistantId) assistantName,
    DateTime? now,
  }) {
    final stamp = DateFormat('yyyy-MM-dd HH:mm').format(now ?? DateTime.now());
    final buf = StringBuffer()
      ..writeln('# ${l10n.legacyMemoryExportTitle}')
      ..writeln('# $stamp')
      ..writeln();
    final byAssistant = <String, List<AssistantMemory>>{};
    for (final m in memories) {
      byAssistant.putIfAbsent(m.assistantId, () => []).add(m);
    }
    for (final entry in byAssistant.entries) {
      buf.writeln(
        '## ${l10n.legacyMemoryAssistantHeader(assistantName(entry.key))}',
      );
      for (final m in entry.value) {
        buf.writeln('- ${m.content}');
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  static Future<void> exportAll(
    BuildContext context, {
    String? assistantId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final mp = context.read<MemoryProvider>();
    final ap = context.read<AssistantProvider>();
    await mp.initialize();
    if (!context.mounted) return;
    final memories = assistantId == null
        ? mp.memories
        : mp.memories.where((m) => m.assistantId == assistantId).toList();
    final text = buildExportText(
      l10n: l10n,
      memories: memories,
      assistantName: (id) => ap.getById(id)?.name ?? id,
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/kelivo-legacy-memory-${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    await file.writeAsString(text);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  @override
  State<LegacyMemoryContent> createState() => _LegacyMemoryContentState();
}

class _LegacyMemoryContentState extends State<LegacyMemoryContent> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MemoryProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mp = context.watch<MemoryProvider>();
    final ap = context.watch<AssistantProvider>();
    final q = _search.text.trim().toLowerCase();
    final assistantFilter = widget.assistantId;
    final memories = mp.memories.where((m) {
      if (assistantFilter != null && m.assistantId != assistantFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return m.content.toLowerCase().contains(q);
    }).toList();
    final byAssistant = <String, List<AssistantMemory>>{};
    for (final m in memories) {
      byAssistant.putIfAbsent(m.assistantId, () => []).add(m);
    }

    return ListView(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Lucide.BadgeInfo, size: 18, color: cs.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.legacyMemoryBanner,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        MemorySearchField(
          controller: _search,
          hintText: l10n.legacyMemorySearchHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        if (byAssistant.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.legacyMemoryEmpty,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              ),
            ),
          )
        else
          for (final entry in byAssistant.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Text(
                l10n.legacyMemoryAssistantHeader(
                  ap.getById(entry.key)?.name ?? entry.key,
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
            ),
            for (final m in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(
                        alpha: isDark ? 0.08 : 0.06,
                      ),
                      width: 0.6,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            m.content,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Tooltip(
                          message: l10n.legacyMemoryCopy,
                          child: IosIconButton(
                            icon: Lucide.Copy,
                            size: 18,
                            color: cs.primary,
                            minSize: 32,
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: m.content),
                              );
                              if (!context.mounted) return;
                              showAppSnackBar(
                                context,
                                message: l10n.legacyMemoryCopied,
                                type: NotificationType.success,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}
