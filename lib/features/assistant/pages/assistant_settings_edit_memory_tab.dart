part of 'assistant_settings_edit_page.dart';

class _MemoryTab extends StatefulWidget {
  const _MemoryTab({required this.assistantId});
  final String assistantId;

  @override
  State<_MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<_MemoryTab> {
  bool _organizing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MemoryProviderV2>().initialize(
        assistantId: widget.assistantId,
      );
    });
  }

  Future<void> _showAddEditSheet({MemoryEntry? existing}) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: existing?.content ?? '');
    var type = existing?.type ?? MemoryType.identity;
    var scope = existing?.scope ?? MemoryScope.global;

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
                      controller: controller,
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
                    if (existing == null) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.memoryEntryTypeLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: AppFontWeights.semibold,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in MemoryType.values)
                            ChoiceChip(
                              label: Text(memoryTypeLabel(l10n, t)),
                              selected: type == t,
                              onSelected: (_) => setLocal(() => type = t),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.memoryEntryScopeLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: AppFontWeights.semibold,
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.memoryEntryScopeGlobal),
                            selected: scope == MemoryScope.global,
                            onSelected: (_) =>
                                setLocal(() => scope = MemoryScope.global),
                          ),
                          ChoiceChip(
                            label: Text(l10n.memoryEntryScopeAssistant),
                            selected: scope == MemoryScope.assistant,
                            onSelected: (_) =>
                                setLocal(() => scope = MemoryScope.assistant),
                          ),
                        ],
                      ),
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

    final text = controller.text.trim();
    controller.dispose();
    if (saved != true || text.isEmpty || !mounted) return;
    final mp = context.read<MemoryProviderV2>();
    if (existing == null) {
      await mp.create(
        scope: scope,
        assistantId: scope == MemoryScope.assistant ? widget.assistantId : null,
        type: type,
        content: text,
        source: MemorySource.manual,
      );
    } else {
      await mp.updateContent(existing.id, text);
    }
  }

  Future<void> _runOrganize() async {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    if (settings.memoryModelProvider == null ||
        settings.memoryModelId == null) {
      showAppSnackBar(
        context,
        message: l10n.memoryOrganizeNeedsModel,
        type: NotificationType.warning,
      );
      return;
    }
    final chat = context.read<ChatService>();
    final convId = chat.currentConversationId;
    final conv = convId == null ? null : chat.getConversation(convId);
    if (conv == null || conv.assistantId != widget.assistantId) {
      showAppSnackBar(
        context,
        message: l10n.memoryOrganizeNeedsConversation,
        type: NotificationType.warning,
      );
      return;
    }
    setState(() => _organizing = true);
    try {
      final pipeline = context.read<MemoryPipelineService>();
      await pipeline.runNow(
        conversationId: conv.id,
        assistantId: widget.assistantId,
      );
      if (mounted) {
        await context.read<MemoryProviderV2>().refresh(
          assistantId: widget.assistantId,
        );
      }
    } finally {
      if (mounted) setState(() => _organizing = false);
    }
  }

  String _statusLine(AppLocalizations l10n, MemoryOrganizeStatus status) {
    final lastAt = status.lastAt;
    final result = status.lastResult;
    if (lastAt == null || result == null) {
      return l10n.memoryOrganizeStatusNever;
    }
    final when = _formatRelative(l10n, lastAt);
    final parts = <String>[l10n.memoryOrganizeStatusLast(when)];
    if (result.error != null && result.error!.isNotEmpty) {
      parts.add(l10n.memoryOrganizeStatusFailed(result.error!));
    } else if (result.gate == MemoryGateParseResult.skip ||
        (result.extractedCount == 0 && result.advanced)) {
      parts.add(l10n.memoryOrganizeStatusSkipped);
    } else {
      parts.add(l10n.memoryOrganizeStatusExtracted(result.extractedCount));
    }
    return parts.join(' · ');
  }

  String _formatRelative(AppLocalizations l10n, DateTime at) {
    final delta = DateTime.now().difference(at);
    if (delta.inMinutes < 1) return l10n.memoryOrganizeJustNow;
    if (delta.inHours < 1) {
      return l10n.memoryOrganizeMinutesAgo(delta.inMinutes);
    }
    if (delta.inDays < 1) {
      return l10n.memoryOrganizeHoursAgo(delta.inHours);
    }
    return l10n.memoryOrganizeDaysAgo(delta.inDays);
  }

  void _goMemorySettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MemorySettingsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ap = context.watch<AssistantProvider>();
    final a = ap.getById(widget.assistantId)!;
    final settings = context.watch<SettingsProvider>();
    final mp = context.watch<MemoryProviderV2>();
    final pipeline = context.read<MemoryPipelineService>();
    final modelMissing =
        settings.memoryModelProvider == null || settings.memoryModelId == null;

    final visible = mp.visibleFor(widget.assistantId);
    final archived = mp.archivedFor(widget.assistantId);
    final chat = context.watch<ChatService>();
    final convId = chat.currentConversationId;
    final conv = convId == null ? null : chat.getConversation(convId);
    final canOrganize =
        !modelMissing &&
        conv != null &&
        conv.assistantId == widget.assistantId &&
        !_organizing;

    Widget sectionCard({
      required Widget child,
      EdgeInsets padding = const EdgeInsets.symmetric(vertical: 6),
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.06),
            width: 0.6,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      children: [
        sectionCard(
          child: Column(
            children: [
              _iosSwitchRow(
                context,
                icon: Lucide.bookHeart,
                label: l10n.assistantEditMemorySwitchTitle,
                value: a.enableMemory,
                onChanged: (v) async {
                  await context.read<AssistantProvider>().updateAssistant(
                    a.copyWith(enableMemory: v),
                  );
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: a.enableMemory
                    ? Column(
                        children: [
                          _iosDivider(context),
                          _iosSwitchRow(
                            context,
                            icon: Lucide.Sparkles,
                            label: l10n.assistantEditAutoOrganizeTitle,
                            value: a.autoOrganizeMemory,
                            onChanged: (v) async {
                              await context
                                  .read<AssistantProvider>()
                                  .updateAssistant(
                                    a.copyWith(autoOrganizeMemory: v),
                                  );
                            },
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: a.autoOrganizeMemory
                                ? Column(
                                    children: [
                                      _iosDivider(context),
                                      if (modelMissing)
                                        MemoryModelMissingNotice(
                                          onGoSelect: _goMemorySettings,
                                        ),
                                      _MemoryOrganizeFrequencySection(
                                        assistant: a,
                                      ),
                                      _iosDivider(context),
                                      _MemoryDedupeModeSection(assistant: a),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          _iosDivider(context),
                          _MemoryWriteScopeSection(assistant: a),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              _iosDivider(context),
              _iosSwitchRow(
                context,
                icon: Lucide.History,
                label: l10n.assistantEditAllowPastRecallTitle,
                value: a.allowPastConversationRecall,
                onChanged: (v) async {
                  await context.read<AssistantProvider>().updateAssistant(
                    a.copyWith(
                      allowPastConversationRecall: v,
                      generateConversationSummary: v
                          ? a.generateConversationSummary
                          : false,
                    ),
                  );
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: a.allowPastConversationRecall
                    ? Column(
                        children: [
                          _iosDivider(context),
                          _iosSwitchRow(
                            context,
                            icon: Lucide.FileText,
                            label: l10n.assistantEditGenerateSummaryTitle,
                            value: a.generateConversationSummary,
                            onChanged: (v) async {
                              await context
                                  .read<AssistantProvider>()
                                  .updateAssistant(
                                    a.copyWith(generateConversationSummary: v),
                                  );
                            },
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: a.generateConversationSummary
                                ? Column(
                                    children: [
                                      _iosDivider(context),
                                      _RecentChatsSummaryFrequencySection(
                                        assistant: a,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.assistantEditManageMemoryTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: AppFontWeights.emphasis,
                  ),
                ),
              ),
              Tooltip(
                message: modelMissing
                    ? l10n.memoryOrganizeNeedsModel
                    : (!canOrganize && !_organizing
                          ? l10n.memoryOrganizeNeedsConversation
                          : l10n.memoryOrganizeButton),
                child: _TactileRow(
                  onTap: canOrganize ? _runOrganize : null,
                  pressedScale: 0.97,
                  builder: (pressed) {
                    final enabled = canOrganize;
                    final color = !enabled
                        ? cs.onSurface.withValues(alpha: 0.35)
                        : (pressed
                              ? cs.primary.withValues(alpha: 0.7)
                              : cs.primary);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_organizing)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        else
                          Icon(Lucide.Sparkles, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(
                          l10n.memoryOrganizeButton,
                          style: TextStyle(
                            color: color,
                            fontWeight: AppFontWeights.semibold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              _TactileRow(
                onTap: () => _showAddEditSheet(),
                pressedScale: 0.97,
                builder: (pressed) {
                  final color = pressed
                      ? cs.primary.withValues(alpha: 0.7)
                      : cs.primary;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Lucide.Plus, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        l10n.memoryEntryActionAdd,
                        style: TextStyle(
                          color: color,
                          fontWeight: AppFontWeights.semibold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            _statusLine(l10n, pipeline.lastStatus),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),

        if (!a.enableMemory)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.memoryEntryEmptyDisabled,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          )
        else if (visible.isEmpty && archived.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.memoryEntryEmpty,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),

        ...visible.map(
          (m) => MemoryEntryCard(
            entry: m,
            useThisAssistantLabel: true,
            scopeToggleAssistantId: widget.assistantId,
            onEdit: () => _showAddEditSheet(existing: m),
          ),
        ),
        if (archived.isNotEmpty) ...[
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
            (m) => MemoryEntryCard(
              entry: m,
              useThisAssistantLabel: true,
              scopeToggleAssistantId: widget.assistantId,
              onEdit: () => _showAddEditSheet(existing: m),
            ),
          ),
        ],

        if (a.allowPastConversationRecall && a.generateConversationSummary) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: Text(
              l10n.assistantEditManageSummariesTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: AppFontWeights.emphasis,
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final chatService = context.watch<ChatService>();
              final summaries = chatService
                  .getConversationsWithSummaryForAssistant(widget.assistantId);
              if (summaries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    l10n.assistantEditSummaryEmpty,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return Column(
                children: summaries.map((conv) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.6),
                                fontWeight: AppFontWeights.medium,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.summary ?? '',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                _TactileIconButton(
                                  icon: Lucide.Pencil,
                                  size: 18,
                                  color: cs.primary,
                                  onTap: () => _showEditSummarySheet(
                                    context,
                                    conv,
                                    chatService,
                                  ),
                                ),
                                _TactileIconButton(
                                  icon: Lucide.Trash2,
                                  size: 18,
                                  color: cs.error,
                                  onTap: () => _confirmDeleteSummary(
                                    context,
                                    conv.id,
                                    chatService,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _showEditSummarySheet(
    BuildContext context,
    Conversation conversation,
    ChatService chatService,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: conversation.summary ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assistantEditSummaryDialogTitle),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: l10n.assistantEditSummaryDialogHint,
            filled: true,
            fillColor: ctx.appColors.surfaceFill,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.assistantEditEmojiDialogCancel),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                await chatService.clearConversationSummary(conversation.id);
              } else {
                await chatService.updateConversationSummary(
                  conversation.id,
                  text,
                  conversation.lastSummarizedMessageCount,
                );
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(l10n.assistantEditEmojiDialogSave),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> _confirmDeleteSummary(
    BuildContext context,
    String conversationId,
    ChatService chatService,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.assistantEditDeleteSummaryTitle),
        content: Text(l10n.assistantEditDeleteSummaryContent),
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
            child: Text(l10n.assistantEditClearButton),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await chatService.clearConversationSummary(conversationId);
    }
  }
}

class _MemoryOrganizeFrequencySection extends StatelessWidget {
  const _MemoryOrganizeFrequencySection({required this.assistant});

  final Assistant assistant;

  static const _options = [1, 3, 5, 10];

  Future<void> _showCustom(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: assistant.memoryOrganizeEveryNTurns.toString(),
    );
    final ap = context.read<AssistantProvider>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.assistantEditOrganizeFrequencyCustomTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.assistantEditOrganizeFrequencyCustomLabel,
              hintText: l10n.assistantEditOrganizeFrequencyCustomHint,
              helperText: l10n.assistantEditOrganizeFrequencyCustomDescription,
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
    final parsed = int.tryParse(controller.text.trim());
    controller.dispose();
    if (saved != true || parsed == null) return;
    if (parsed < Assistant.minMemoryOrganizeEveryNTurns ||
        parsed > Assistant.maxMemoryOrganizeEveryNTurns) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          message: l10n.assistantEditOrganizeFrequencyCustomInvalid,
          type: NotificationType.error,
        );
      }
      return;
    }
    await ap.updateAssistant(
      assistant.copyWith(memoryOrganizeEveryNTurns: parsed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ap = context.read<AssistantProvider>();
    final selected = assistant.memoryOrganizeEveryNTurns;
    final options = <int>{..._options, selected}.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  Lucide.FileClock,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assistantEditOrganizeFrequencyTitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.assistantEditOrganizeFrequencySubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...options.map((count) {
                  final isSelected = count == selected;
                  return _FrequencyChipButton(
                    label: l10n.assistantEditOrganizeFrequencyOption(count),
                    selected: isSelected,
                    onTap: isSelected
                        ? null
                        : () async {
                            await ap.updateAssistant(
                              assistant.copyWith(
                                memoryOrganizeEveryNTurns: count,
                              ),
                            );
                          },
                  );
                }),
                _FrequencyChipButton(
                  label: l10n.assistantEditOrganizeFrequencyCustomButton,
                  icon: Lucide.Pencil,
                  emphasized: true,
                  onTap: () => _showCustom(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryDedupeModeSection extends StatelessWidget {
  const _MemoryDedupeModeSection({required this.assistant});

  final Assistant assistant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ap = context.read<AssistantProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  Lucide.Layers,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assistantEditDedupeModeTitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.assistantEditDedupeModeSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FrequencyChipButton(
                  label: l10n.assistantEditDedupeModeBatched,
                  selected:
                      assistant.memorySmartAddMode ==
                      MemorySmartAddMode.batched,
                  onTap: () async {
                    await ap.updateAssistant(
                      assistant.copyWith(
                        memorySmartAddMode: MemorySmartAddMode.batched,
                      ),
                    );
                  },
                ),
                _FrequencyChipButton(
                  label: l10n.assistantEditDedupeModePerItem,
                  selected:
                      assistant.memorySmartAddMode ==
                      MemorySmartAddMode.perItem,
                  onTap: () async {
                    await ap.updateAssistant(
                      assistant.copyWith(
                        memorySmartAddMode: MemorySmartAddMode.perItem,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryWriteScopeSection extends StatelessWidget {
  const _MemoryWriteScopeSection({required this.assistant});

  final Assistant assistant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ap = context.read<AssistantProvider>();

    final items = <(MemoryWriteScope, String)>[
      (MemoryWriteScope.alwaysGlobal, l10n.assistantEditWriteScopeAlwaysGlobal),
      (
        MemoryWriteScope.alwaysAssistant,
        l10n.assistantEditWriteScopeAlwaysAssistant,
      ),
      (
        MemoryWriteScope.toolDefaultGlobal,
        l10n.assistantEditWriteScopeToolDefaultGlobal,
      ),
      (
        MemoryWriteScope.toolDefaultAssistant,
        l10n.assistantEditWriteScopeToolDefaultAssistant,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  Lucide.Globe,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assistantEditWriteScopeTitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.assistantEditWriteScopeSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items)
                  _FrequencyChipButton(
                    label: item.$2,
                    selected: assistant.memoryWriteScope == item.$1,
                    onTap: () async {
                      await ap.updateAssistant(
                        assistant.copyWith(memoryWriteScope: item.$1),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentChatsSummaryFrequencySection extends StatelessWidget {
  const _RecentChatsSummaryFrequencySection({required this.assistant});

  final Assistant assistant;

  Future<void> _showCustomCountInput(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: assistant.recentChatsSummaryMessageCount.toString(),
    );
    final ap = context.read<AssistantProvider>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.assistantEditRecentChatsSummaryFrequencyCustomTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText:
                  l10n.assistantEditRecentChatsSummaryFrequencyCustomLabel,
              hintText: l10n.assistantEditRecentChatsSummaryFrequencyCustomHint,
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
    final parsed = int.tryParse(controller.text.trim());
    controller.dispose();
    if (saved != true || parsed == null || parsed < 1) return;
    await ap.updateAssistant(
      assistant.copyWith(recentChatsSummaryMessageCount: parsed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ap = context.read<AssistantProvider>();
    final selected = assistant.recentChatsSummaryMessageCount;
    final options = <int>{
      ...Assistant.recentChatsSummaryMessageCountOptions,
      selected,
    }.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Icon(
                  Lucide.FileClock,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.assistantEditRecentChatsSummaryFrequencyTitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.assistantEditRecentChatsSummaryFrequencyDescription,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...options.map((count) {
                  final isSelected = count == selected;
                  return _FrequencyChipButton(
                    label: l10n.assistantEditRecentChatsSummaryFrequencyOption(
                      count,
                    ),
                    selected: isSelected,
                    onTap: isSelected
                        ? null
                        : () async {
                            await ap.updateAssistant(
                              assistant.copyWith(
                                recentChatsSummaryMessageCount: count,
                              ),
                            );
                          },
                  );
                }),
                _FrequencyChipButton(
                  label:
                      l10n.assistantEditRecentChatsSummaryFrequencyCustomButton,
                  icon: Lucide.Pencil,
                  emphasized: true,
                  onTap: () => _showCustomCountInput(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyChipButton extends StatelessWidget {
  const _FrequencyChipButton({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.emphasized = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final bool emphasized;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBackground = selected
        ? cs.primary.withValues(alpha: isDark ? 0.22 : 0.12)
        : (context.appColors.surfaceFill);
    final borderColor = selected
        ? cs.primary.withValues(alpha: 0.38)
        : (emphasized
              ? cs.primary.withValues(alpha: isDark ? 0.24 : 0.18)
              : cs.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.14));
    final foregroundColor = selected || emphasized
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.8);

    return MouseRegion(
      cursor: onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: _TactileRow(
        onTap: onTap,
        haptics: true,
        pressedScale: 0.985,
        releaseDelayMs: 0,
        builder: (pressed) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            opacity: pressed ? (selected ? 0.94 : 0.82) : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: baseBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: foregroundColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: AppFontWeights.semibold,
                      color: foregroundColor,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
