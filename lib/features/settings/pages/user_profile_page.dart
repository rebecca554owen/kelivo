import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Kelivo/theme/app_font_weights.dart';
import 'package:Kelivo/theme/app_semantic_colors.dart';

import '../../../core/models/memory_entry.dart';
import '../../../core/models/user_profile_field.dart';
import '../../../core/providers/memory_provider_v2.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../shared/widgets/ios_form_text_field.dart';
import '../../../shared/widgets/ios_tactile.dart';
import '../../../shared/widgets/ios_tile_button.dart';
import '../../../shared/widgets/snackbar.dart';
import '../widgets/memory_ui.dart';

/// Structured user profile fields (§14.4 / §5.7).
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

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
        title: Text(l10n.userProfilePageTitle),
      ),
      body: const UserProfileContent(),
    );
  }
}

class UserProfileContent extends StatefulWidget {
  const UserProfileContent({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  State<UserProfileContent> createState() => _UserProfileContentState();
}

class _UserProfileContentState extends State<UserProfileContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MemoryProviderV2>().initialize(loadAll: true);
    });
  }

  String _knownLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'preferred_name':
        return l10n.userProfilePreferredName;
      case 'gender':
        return l10n.userProfileGender;
      case 'pronouns':
        return l10n.userProfilePronouns;
      case 'preferred_language':
        return l10n.userProfilePreferredLanguage;
      case 'timezone':
        return l10n.userProfileTimezone;
      case 'occupation':
        return l10n.userProfileOccupation;
      case 'location':
        return l10n.userProfileLocation;
      default:
        return key;
    }
  }

  Future<void> _clearOrEdit({
    required String key,
    required String? current,
    bool isCustom = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final isNewCustom = isCustom && current == null;

    final result = await showCustomBottomSheet<_ProfileFieldResult>(
      context: context,
      title: isNewCustom
          ? l10n.userProfileAddCustom
          : (isCustom ? key : _knownLabel(l10n, key)),
      closeSemanticLabel: l10n.mcpPageClose,
      // Pinned footer: the panel must be fully visible from the start.
      partialHeightFactor: 0.55,
      expandedHeightFactor: 0.55,
      builder: (ctx, scrollController) => _ProfileFieldForm(
        scrollController: scrollController,
        fieldKey: key,
        initialValue: current ?? '',
        isNewCustom: isNewCustom,
        canClear: current != null && current.isNotEmpty,
        description: key == 'preferred_name'
            ? l10n.userProfilePreferredNameHint
            : null,
      ),
    );

    if (result == null || !mounted) return;

    final targetKey = isNewCustom ? result.key.trim() : key;
    final value = result.value.trim();
    final mp = context.read<MemoryProviderV2>();
    if (result.cleared || value.isEmpty) {
      if (UserProfileField.isValidKey(targetKey)) {
        await mp.removeProfileField(targetKey);
      }
      return;
    }
    if (!UserProfileField.isValidKey(targetKey)) {
      showAppSnackBar(
        context,
        message: l10n.userProfileInvalidKey,
        type: NotificationType.error,
      );
      return;
    }
    await mp.putProfileField(targetKey, value, MemorySource.manual);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fields = context.watch<MemoryProviderV2>().profileFields;
    final byKey = {for (final f in fields) f.key: f};
    final customKeys = fields
        .map((f) => f.key)
        .where((k) => k.startsWith('custom.'))
        .toList();

    Widget sectionCard(List<Widget> children) => Container(
      decoration: BoxDecoration(
        color: context.appColors.surfaceCard,
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
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 0.6,
                indent: 14,
                endIndent: 12,
                color: cs.outlineVariant.withValues(alpha: 0.18),
              ),
          ],
        ],
      ),
    );

    return ListView(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        sectionCard([
          for (final key in UserProfileField.knownKeys)
            _ProfileRow(
              title: _knownLabel(l10n, key),
              subtitle: key == 'preferred_name'
                  ? l10n.userProfilePreferredNameHint
                  : null,
              value: byKey[key]?.value,
              emptyLabel: l10n.userProfileEmptyValue,
              onTap: () => _clearOrEdit(key: key, current: byKey[key]?.value),
            ),
        ]),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: Text(
            l10n.userProfileCustomSection,
            style: TextStyle(
              fontSize: 13,
              fontWeight: AppFontWeights.semibold,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        sectionCard([
          for (final key in customKeys)
            _ProfileRow(
              title: key,
              value: byKey[key]?.value,
              emptyLabel: l10n.userProfileEmptyValue,
              onTap: () => _clearOrEdit(
                key: key,
                current: byKey[key]?.value,
                isCustom: true,
              ),
            ),
          IosCardPress(
            onTap: () => _clearOrEdit(key: '', current: null, isCustom: true),
            borderRadius: BorderRadius.zero,
            padding: EdgeInsets.zero,
            baseColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Icon(Lucide.Plus, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.userProfileAddCustom,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: AppFontWeights.semibold,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

class _ProfileFieldResult {
  const _ProfileFieldResult({
    required this.key,
    required this.value,
    this.cleared = false,
  });

  final String key;
  final String value;
  final bool cleared;
}

class _ProfileFieldForm extends StatefulWidget {
  const _ProfileFieldForm({
    required this.scrollController,
    required this.fieldKey,
    required this.initialValue,
    required this.isNewCustom,
    required this.canClear,
    this.description,
  });

  final ScrollController scrollController;
  final String fieldKey;
  final String initialValue;
  final bool isNewCustom;
  final bool canClear;
  final String? description;

  @override
  State<_ProfileFieldForm> createState() => _ProfileFieldFormState();
}

class _ProfileFieldFormState extends State<_ProfileFieldForm> {
  late final TextEditingController _key;
  late final TextEditingController _value;

  @override
  void initState() {
    super.initState();
    _key = TextEditingController(
      text: widget.isNewCustom ? 'custom.' : widget.fieldKey,
    );
    _value = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _key.dispose();
    _value.dispose();
    super.dispose();
  }

  void _pop({bool cleared = false}) {
    Navigator.of(context).pop(
      _ProfileFieldResult(
        key: _key.text,
        value: cleared ? '' : _value.text,
        cleared: cleared,
      ),
    );
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
                    if (widget.isNewCustom)
                      IosFormTextField(
                        label: l10n.memoryUiCustomKeyLabel,
                        controller: _key,
                        hintText: l10n.userProfileCustomKeyHint,
                        inlineLabel: false,
                        textAlign: TextAlign.start,
                        textInputAction: TextInputAction.next,
                      ),
                    IosFormTextField(
                      label: l10n.memoryUiValueLabel,
                      controller: _value,
                      hintText: l10n.userProfileCustomValueHint,
                      minLines: 1,
                      maxLines: 4,
                      inlineLabel: false,
                      autofocus: true,
                      textAlign: TextAlign.start,
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
            child: MemorySheetActions(
              confirmLabel: l10n.userProfileSave,
              onCancel: () => Navigator.of(context).maybePop(),
              onConfirm: _pop,
              extraAction: widget.canClear
                  ? IosTileButton(
                      label: l10n.userProfileClear,
                      icon: Lucide.Trash2,
                      backgroundColor: cs.error,
                      onTap: () => _pop(cleared: true),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.emptyLabel,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final String emptyLabel;
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
              child: Column(
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    (value == null || value!.isEmpty) ? emptyLabel : value!,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: (value == null || value!.isEmpty)
                          ? cs.onSurface.withValues(alpha: 0.4)
                          : cs.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
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
