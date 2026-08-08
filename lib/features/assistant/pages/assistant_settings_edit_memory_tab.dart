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

  Future<void> _showAddEditSheet({MemoryEntry? existing}) {
    return showMemoryEntryEditor(
      context,
      existing: existing,
      defaultAssistantId: widget.assistantId,
    );
  }

  void _goLegacyMemory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegacyMemoryPage(assistantId: widget.assistantId),
      ),
    );
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

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: MemorySectionCard(
            padding: EdgeInsets.zero,
            children: [
              MemoryNavRow(
                title: l10n.memoryUiAssistantLegacyTitle,
                subtitle: l10n.memoryUiAssistantLegacySubtitle,
                onTap: _goLegacyMemory,
              ),
            ],
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
    final text = await _showMemoryTextSheet(
      context,
      title: l10n.assistantEditSummaryDialogTitle,
      label: l10n.assistantEditSummaryDialogTitle,
      hintText: l10n.assistantEditSummaryDialogHint,
      initialValue: conversation.summary ?? '',
      allowEmpty: true,
    );
    if (text == null) return;
    if (text.isEmpty) {
      await chatService.clearConversationSummary(conversation.id);
    } else {
      await chatService.updateConversationSummary(
        conversation.id,
        text,
        conversation.lastSummarizedMessageCount,
      );
    }
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

/// Text/number input sheet whose controller lives in a [State], so it survives
/// the sheet's exit transition.
Future<String?> _showMemoryTextSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
  String? hintText,
  String? description,
  int minLines = 3,
  int maxLines = 10,
  TextInputType? keyboardType,
  bool allowEmpty = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showCustomBottomSheet<String>(
    context: context,
    title: title,
    closeSemanticLabel: l10n.mcpPageClose,
    // Pinned footer: the panel must be fully visible from the start.
    partialHeightFactor: 0.55,
    expandedHeightFactor: 0.55,
    builder: (ctx, scrollController) => _MemoryTextInputForm(
      scrollController: scrollController,
      label: label,
      hintText: hintText,
      description: description,
      initialValue: initialValue,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      allowEmpty: allowEmpty,
    ),
  );
}

class _MemoryTextInputForm extends StatefulWidget {
  const _MemoryTextInputForm({
    required this.scrollController,
    required this.label,
    required this.initialValue,
    required this.minLines,
    required this.maxLines,
    required this.allowEmpty,
    this.hintText,
    this.description,
    this.keyboardType,
  });

  final ScrollController scrollController;
  final String label;
  final String initialValue;
  final String? hintText;
  final String? description;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool allowEmpty;

  @override
  State<_MemoryTextInputForm> createState() => _MemoryTextInputFormState();
}

class _MemoryTextInputFormState extends State<_MemoryTextInputForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                MemorySectionCard(
                  children: [
                    IosFormTextField(
                      label: widget.label,
                      controller: _controller,
                      hintText: widget.hintText,
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      inlineLabel: false,
                      autofocus: true,
                      textAlign: TextAlign.start,
                      keyboardType: widget.keyboardType,
                    ),
                  ],
                ),
                if (widget.description != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.description!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => MemorySheetActions(
                confirmLabel: l10n.userProfileSave,
                confirmEnabled:
                    widget.allowEmpty || value.text.trim().isNotEmpty,
                onCancel: () => Navigator.of(context).maybePop(),
                onConfirm: () =>
                    Navigator.of(context).pop(_controller.text.trim()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryOrganizeFrequencySection extends StatelessWidget {
  const _MemoryOrganizeFrequencySection({required this.assistant});

  final Assistant assistant;

  static const _options = [1, 3, 5, 10];

  Future<void> _showCustom(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ap = context.read<AssistantProvider>();
    final input = await _showMemoryTextSheet(
      context,
      title: l10n.assistantEditOrganizeFrequencyCustomTitle,
      label: l10n.assistantEditOrganizeFrequencyCustomLabel,
      hintText: l10n.assistantEditOrganizeFrequencyCustomHint,
      description: l10n.assistantEditOrganizeFrequencyCustomDescription,
      initialValue: assistant.memoryOrganizeEveryNTurns.toString(),
      minLines: 1,
      maxLines: 1,
      keyboardType: TextInputType.number,
    );
    final parsed = input == null ? null : int.tryParse(input);
    if (parsed == null) return;
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
                  return MemorySelectChip(
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
                MemorySelectChip(
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
                MemorySelectChip(
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
                MemorySelectChip(
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
                  MemorySelectChip(
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
    final ap = context.read<AssistantProvider>();
    final input = await _showMemoryTextSheet(
      context,
      title: l10n.assistantEditRecentChatsSummaryFrequencyCustomTitle,
      label: l10n.assistantEditRecentChatsSummaryFrequencyCustomLabel,
      hintText: l10n.assistantEditRecentChatsSummaryFrequencyCustomHint,
      initialValue: assistant.recentChatsSummaryMessageCount.toString(),
      minLines: 1,
      maxLines: 1,
      keyboardType: TextInputType.number,
    );
    final parsed = input == null ? null : int.tryParse(input);
    if (parsed == null || parsed < 1) return;
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
                  return MemorySelectChip(
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
                MemorySelectChip(
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
