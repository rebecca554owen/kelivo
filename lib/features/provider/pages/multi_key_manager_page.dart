import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/model_provider.dart';
import '../../../core/models/api_keys.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/snackbar.dart';
import '../../model/widgets/model_select_sheet.dart';

class MultiKeyManagerPage extends StatefulWidget {
  const MultiKeyManagerPage({super.key, required this.providerKey, required this.providerDisplayName});
  final String providerKey;
  final String providerDisplayName;

  @override
  State<MultiKeyManagerPage> createState() => _MultiKeyManagerPageState();
}

class _MultiKeyManagerPageState extends State<MultiKeyManagerPage> {
  String? _detectModelId;
  bool _detecting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final cfg = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final apiKeys = List<ApiKeyConfig>.from(cfg.apiKeys ?? const <ApiKeyConfig>[]);
    final total = apiKeys.length;
    final normal = apiKeys.where((k) => k.status == ApiKeyStatus.active).length;
    final errors = apiKeys.where((k) => k.status == ApiKeyStatus.error).length;
    final accuracy = total == 0 ? 0 : ((normal / total) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.multiKeyPageTitle),
        actions: [
          IconButton(
            onPressed: _detecting ? null : _onDetect,
            onLongPress: _onPickDetectModel,
            tooltip: l10n.multiKeyPageDetect,
            icon: _detecting
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                : Icon(Lucide.Cable, color: cs.onSurface),
          ),
          IconButton(
            onPressed: _onAddKeys,
            tooltip: l10n.multiKeyPageAdd,
            icon: Icon(Lucide.Plus, color: cs.onSurface),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _statsCard(context, total: total, normal: normal, errors: errors, accuracy: accuracy),
          const SizedBox(height: 12),
          _strategyCard(context, cfg),
          const SizedBox(height: 12),
          _keysList(context, apiKeys),
        ],
      ),
    );
  }

  Widget _statsCard(BuildContext context, {required int total, required int normal, required int errors, required int accuracy}) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _chooseDetectModel,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _metric(l10n.multiKeyPageTotal, total.toString(), cs.onSurface),
            _metric(l10n.multiKeyPageNormal, normal.toString(), Colors.green),
            _metric(l10n.multiKeyPageError, errors.toString(), cs.error),
            _metric(l10n.multiKeyPageAccuracy, '$accuracy%', cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
      ],
    );
  }

  Widget _strategyCard(BuildContext context, ProviderConfig cfg) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final current = cfg.keyManagement?.strategy ?? LoadBalanceStrategy.roundRobin;
    String labelFor(LoadBalanceStrategy s) {
      switch (s) {
        case LoadBalanceStrategy.priority:
          return l10n.multiKeyPageStrategyPriority;
        case LoadBalanceStrategy.leastUsed:
          return l10n.multiKeyPageStrategyLeastUsed;
        case LoadBalanceStrategy.random:
          return l10n.multiKeyPageStrategyRandom;
        case LoadBalanceStrategy.roundRobin:
        default:
          return l10n.multiKeyPageStrategyRoundRobin;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showStrategySheet,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Lucide.Shuffle, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.multiKeyPageStrategyTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(labelFor(current), style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Icon(Lucide.ChevronDown, size: 16, color: cs.onSurface.withOpacity(0.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keysList(BuildContext context, List<ApiKeyConfig> keys) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    if (keys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
        ),
        child: Center(child: Text(l10n.multiKeyPageNoKeys)),
      );
    }

    String mask(String key) {
      if (key.length <= 8) return key;
      return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
    }

    Color statusColor(ApiKeyStatus st) {
      switch (st) {
        case ApiKeyStatus.active:
          return Colors.green;
        case ApiKeyStatus.disabled:
          return cs.onSurface.withOpacity(0.6);
        case ApiKeyStatus.error:
          return cs.error;
        case ApiKeyStatus.rateLimited:
          return cs.tertiary;
      }
    }

    String statusText(ApiKeyStatus st) {
      switch (st) {
        case ApiKeyStatus.active:
          return l10n.multiKeyPageStatusActive;
        case ApiKeyStatus.disabled:
          return l10n.multiKeyPageStatusDisabled;
        case ApiKeyStatus.error:
          return l10n.multiKeyPageStatusError;
        case ApiKeyStatus.rateLimited:
          return l10n.multiKeyPageStatusRateLimited;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final k in keys)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.name?.isNotEmpty == true ? k.name! : mask(k.key),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor(k.status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(statusText(k.status), style: TextStyle(color: statusColor(k.status), fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          Text(mask(k.key), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async { await _editKey(k); },
                  icon: Icon(Lucide.Pencil, size: 16, color: cs.primary),
                  label: Text(l10n.multiKeyPageEdit, style: TextStyle(color: cs.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.primary.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async { await _deleteKey(k); },
                  icon: Icon(Lucide.Trash2, size: 16, color: cs.error),
                  label: Text(l10n.multiKeyPageDelete, style: TextStyle(color: cs.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: cs.error.withOpacity(0.35)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: k.isEnabled,
                  onChanged: (v) async {
                    await _updateKey(k.copyWith(isEnabled: v));
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _updateKey(ApiKeyConfig updated) async {
    final settings = context.read<SettingsProvider>();
    final old = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final list = List<ApiKeyConfig>.from(old.apiKeys ?? const <ApiKeyConfig>[]);
    final idx = list.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) {
      list[idx] = updated;
      await settings.setProviderConfig(widget.providerKey, old.copyWith(apiKeys: list));
    }
  }

  Future<void> _deleteKey(ApiKeyConfig k) async {
    final settings = context.read<SettingsProvider>();
    final old = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final list = List<ApiKeyConfig>.from(old.apiKeys ?? const <ApiKeyConfig>[]);
    list.removeWhere((e) => e.id == k.id);
    await settings.setProviderConfig(widget.providerKey, old.copyWith(apiKeys: list));
  }

  Future<void> _editKey(ApiKeyConfig k) async {
    final updated = await _showEditKeySheet(k);
    if (updated == null) return;
    // Optional: prevent duplicate keys if key changed
    final settings = context.read<SettingsProvider>();
    final cfg = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final list = List<ApiKeyConfig>.from(cfg.apiKeys ?? const <ApiKeyConfig>[]);
    final duplicate = list.any((e) => e.id != k.id && e.key.trim() == updated.key.trim());
    if (duplicate) {
      showAppSnackBar(context, message: AppLocalizations.of(context)!.multiKeyPageDuplicateKeyWarning, type: NotificationType.warning);
      return;
    }
    await _updateKey(updated);
  }

  Future<void> _onAddKeys() async {
    final l10n = AppLocalizations.of(context)!;
    final added = await _showAddKeysSheet();
    if (added == null) return;
    final settings = context.read<SettingsProvider>();
    final cfg = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final existing = (cfg.apiKeys ?? const <ApiKeyConfig>[]);
    final existingSet = existing.map((e) => e.key.trim()).toSet();
    final unique = <String>[];
    for (final k in added) {
      if (k.isEmpty) continue;
      if (!existingSet.contains(k)) unique.add(k);
    }
    if (unique.isEmpty) {
      showAppSnackBar(context, message: l10n.multiKeyPageImportedSnackbar(0));
      return;
    }
    final newKeys = [
      ...existing,
      for (final s in unique) ApiKeyConfig.create(s),
    ];
    await settings.setProviderConfig(widget.providerKey, cfg.copyWith(apiKeys: newKeys, multiKeyEnabled: true));
    if (!mounted) return;
    showAppSnackBar(context, message: l10n.multiKeyPageImportedSnackbar(unique.length), type: NotificationType.success);

    // Auto-detect imported keys
    await _detectOnly(keys: unique);
  }

  List<String> _splitKeys(String raw) {
    final s = raw.replaceAll(',', ' ').trim();
    return s.split(RegExp(r'\s+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _onDetect() async {
    if (_detecting) return;
    final settings = context.read<SettingsProvider>();
    final cfg = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final models = cfg.models;
    if (_detectModelId == null) {
      if (models.isEmpty) {
        if (!mounted) return;
        showAppSnackBar(context, message: AppLocalizations.of(context)!.multiKeyPagePleaseAddModel, type: NotificationType.warning);
        return;
      }
      _detectModelId = models.first;
    }
    setState(() => _detecting = true);
    try {
      await _detectAllForModel(_detectModelId!);
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  Future<void> _onPickDetectModel() async {
    final sel = await showModelSelector(context, limitProviderKey: widget.providerKey);
    if (sel != null) {
      setState(() => _detectModelId = sel.modelId);
    }
  }

  Future<void> _chooseDetectModel() async {
    final sel = await showModelSelector(context, limitProviderKey: widget.providerKey);
    if (sel != null) setState(() => _detectModelId = sel.modelId);
  }

  Future<void> _showStrategySheet() async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final old = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final current = old.keyManagement?.strategy ?? LoadBalanceStrategy.roundRobin;
    String labelFor(LoadBalanceStrategy s) {
      switch (s) {
        case LoadBalanceStrategy.priority:
          return l10n.multiKeyPageStrategyPriority;
        case LoadBalanceStrategy.leastUsed:
          return l10n.multiKeyPageStrategyLeastUsed;
        case LoadBalanceStrategy.random:
          return l10n.multiKeyPageStrategyRandom;
        case LoadBalanceStrategy.roundRobin:
        default:
          return l10n.multiKeyPageStrategyRoundRobin;
      }
    }

    final selected = await showModalBottomSheet<LoadBalanceStrategy>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                for (final s in LoadBalanceStrategy.values)
                  ListTile(
                    title: Text(labelFor(s)),
                    trailing: s == current ? Icon(Icons.check, color: cs.primary) : null,
                    onTap: () => Navigator.of(ctx).pop(s),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null && selected != current) {
      final km = (old.keyManagement ?? const KeyManagementConfig()).copyWith(strategy: selected);
      await settings.setProviderConfig(widget.providerKey, old.copyWith(keyManagement: km));
    }
  }

  Future<List<String>?> _showAddKeysSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputCtrl = TextEditingController();
    final result = await showModalBottomSheet<List<String>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.multiKeyPageAdd, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: inputCtrl,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: l10n.multiKeyPageAddHint,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.multiKeyPageCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(_splitKeys(inputCtrl.text)),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.multiKeyPageAdd),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result;
  }

  Future<ApiKeyConfig?> _showEditKeySheet(ApiKeyConfig k) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aliasCtrl = TextEditingController(text: k.name ?? '');
    final keyCtrl = TextEditingController(text: k.key);
    final priCtrl = TextEditingController(text: k.priority.toString());
    final updated = await showModalBottomSheet<ApiKeyConfig?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.multiKeyPageEdit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: aliasCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.multiKeyPageAlias,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: keyCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.multiKeyPageKey,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.multiKeyPagePriority,
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.multiKeyPageCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final p = int.tryParse(priCtrl.text.trim()) ?? k.priority;
                          final clamped = p.clamp(1, 10) as int;
                          Navigator.of(ctx).pop(
                            k.copyWith(
                              name: aliasCtrl.text.trim().isEmpty ? null : aliasCtrl.text.trim(),
                              key: keyCtrl.text.trim(),
                              priority: clamped,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.multiKeyPageSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return updated;
  }

  Future<void> _detectOnly({required List<String> keys}) async {
    final cfg = context.read<SettingsProvider>().getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final models = cfg.models;
    if (_detectModelId == null) {
      if (models.isEmpty) {
        showAppSnackBar(context, message: AppLocalizations.of(context)!.multiKeyPagePleaseAddModel, type: NotificationType.warning);
        return;
      }
      _detectModelId = models.first;
    }
    final list = List<ApiKeyConfig>.from(cfg.apiKeys ?? const <ApiKeyConfig>[]);
    final toTest = list.where((e) => keys.contains(e.key)).toList();
    await _testKeysAndSave(list, toTest, _detectModelId!);
  }

  Future<void> _detectAllForModel(String modelId) async {
    final settings = context.read<SettingsProvider>();
    final cfg = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final list = List<ApiKeyConfig>.from(cfg.apiKeys ?? const <ApiKeyConfig>[]);
    await _testKeysAndSave(list, list, modelId);
  }

  Future<void> _testKeysAndSave(List<ApiKeyConfig> fullList, List<ApiKeyConfig> toTest, String modelId) async {
    final settings = context.read<SettingsProvider>();
    final base = settings.getProviderConfig(widget.providerKey, defaultName: widget.providerDisplayName);
    final out = List<ApiKeyConfig>.from(fullList);
    for (int i = 0; i < toTest.length; i++) {
      final k = toTest[i];
      final ok = await _testSingleKey(base, modelId, k);
      final idx = out.indexWhere((e) => e.id == k.id);
      if (idx >= 0) out[idx] = k.copyWith(
        status: ok ? ApiKeyStatus.active : ApiKeyStatus.error,
        usage: k.usage.copyWith(
          totalRequests: k.usage.totalRequests + 1,
          successfulRequests: k.usage.successfulRequests + (ok ? 1 : 0),
          failedRequests: k.usage.failedRequests + (ok ? 0 : 1),
          consecutiveFailures: ok ? 0 : (k.usage.consecutiveFailures + 1),
          lastUsed: DateTime.now().millisecondsSinceEpoch,
        ),
        lastError: ok ? null : 'Test failed',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      // Small delay between tests for UX
      await Future.delayed(const Duration(milliseconds: 120));
    }
    await settings.setProviderConfig(widget.providerKey, base.copyWith(apiKeys: out));
  }

  Future<bool> _testSingleKey(ProviderConfig baseCfg, String modelId, ApiKeyConfig key) async {
    try {
      final cfg2 = baseCfg.copyWith(apiKey: key.key);
      await ProviderManager.testConnection(cfg2, modelId);
      return true;
    } catch (_) {
      return false;
    }
  }
}
