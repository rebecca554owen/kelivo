import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/snackbar.dart';
import 'package:cross_file/cross_file.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../icons/lucide_adapter.dart';
import '../../../shared/animations/widgets.dart';
import '../../../core/services/haptics.dart';
import '../../../core/models/backup.dart';
import '../../../core/providers/backup_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/chat/chat_service.dart';

// File size formatter (B, KB, MB, GB)
String _fmtBytes(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes >= gb) return (bytes / gb).toStringAsFixed(2) + ' GB';
  if (bytes >= mb) return (bytes / mb).toStringAsFixed(2) + ' MB';
  if (bytes >= kb) return (bytes / kb).toStringAsFixed(2) + ' KB';
  return '$bytes B';
}

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  int _currentIndex = 0;
  late final PageController _pageCtrl;
  bool _showPassword = false;
  List<BackupFileItem> _remote = const <BackupFileItem>[];
  bool _loadingRemote = false;
  bool _initedControllers = false;
  final _urlCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pathCtrl = TextEditingController(text: 'kelivo_backups');

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: _currentIndex);
  }

  Future<RestoreMode?> _chooseImportModeDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cardColor = Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9);

    return showDialog<RestoreMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupPageSelectImportMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionCard(
              color: cardColor,
              icon: Lucide.RotateCw,
              title: l10n.backupPageOverwriteMode,
              subtitle: l10n.backupPageOverwriteModeDescription,
              onTap: () => Navigator.of(ctx).pop(RestoreMode.overwrite),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              color: cardColor,
              icon: Lucide.GitFork,
              title: l10n.backupPageMergeMode,
              subtitle: l10n.backupPageMergeModeDescription,
              onTap: () => Navigator.of(ctx).pop(RestoreMode.merge),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.backupPageCancel),
          ),
        ],
      ),
    );
  }

  Future<T> _runWithExportingOverlay<T>(BuildContext context, Future<T> Function() task) async {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(radius: 16),
                const SizedBox(height: 12),
                Text(
                  l10n.backupPageExporting,
                  style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final res = await task();
      return res;
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<T> _runWithImportingOverlay<T>(BuildContext context, Future<T> Function() task) async {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CupertinoActivityIndicator(radius: 14),
          ),
        ),
      ),
    );
    try {
      final res = await task();
      return res;
    } finally {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _pathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    return ChangeNotifierProvider(
      create: (_) => BackupProvider(
        chatService: context.read<ChatService>(),
        initialConfig: settings.webDavConfig,
      ),
      child: Builder(builder: (context) {
        final vm = context.watch<BackupProvider>();
        final cfg = vm.config;
        if (!_initedControllers) {
          _urlCtrl.text = cfg.url;
          _userCtrl.text = cfg.username;
          _passCtrl.text = cfg.password;
          _pathCtrl.text = cfg.path.isEmpty ? 'kelivo_backups' : cfg.path;
          _initedControllers = true;
        }
        return Scaffold(
          appBar: AppBar(
            leading: Tooltip(
              message: l10n.settingsPageBackButton,
              child: _TactileIconButton(
                icon: Lucide.ArrowLeft,
                color: cs.onSurface,
                size: 22,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            title: Text(l10n.backupPageTitle),
          ),
          body: PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: [
              _buildWebDavTab(context, cs, settings, vm, cfg, l10n),
              _buildImportExportTab(context, cs, vm, l10n),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: _BottomTabs(
                index: _currentIndex,
                leftIcon: Lucide.databaseBackup,
                leftLabel: l10n.backupPageWebDavTab,
                rightIcon: Lucide.Import2,
                rightLabel: l10n.backupPageImportExportTab,
                onSelect: (i) {
                  setState(() => _currentIndex = i);
                  _pageCtrl.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildWebDavTab(BuildContext context, ColorScheme cs, SettingsProvider settings, BackupProvider vm, WebDavConfig cfg, AppLocalizations l10n) {
    final cardColor = Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9);

    Future<void> reloadRemote() async {
      setState(() => _loadingRemote = true);
      try {
        final list = await vm.listRemote();
        setState(() => _remote = list);
      } finally {
        setState(() => _loadingRemote = false);
      }
    }

    Future<void> persist(WebDavConfig c) async {
      await settings.setWebDavConfig(c);
      vm.updateConfig(c);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        // Form card (no ripple, iOS style)
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InputRow(
                  label: l10n.backupPageWebDavServerUrl,
                  controller: _urlCtrl,
                  hint: 'https://example.com/dav',
                  onChanged: (v) => persist(cfg.copyWith(url: v.trim())),
                ),
                const SizedBox(height: 12),
                _InputRow(
                  label: l10n.backupPageUsername,
                  controller: _userCtrl,
                  onChanged: (v) => persist(cfg.copyWith(username: v.trim())),
                ),
                const SizedBox(height: 12),
                _InputRow(
                  label: l10n.backupPagePassword,
                  controller: _passCtrl,
                  obscure: !_showPassword,
                  onChanged: (v) => persist(cfg.copyWith(password: v)),
                  suffix: IconButton(
                    icon: AnimatedIconSwap(
                      child: Icon(
                        _showPassword ? Lucide.EyeOff : Lucide.Eye,
                        key: ValueKey(_showPassword ? 'hide' : 'show'),
                      ),
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 12),
                _InputRow(
                  label: l10n.backupPagePath,
                  controller: _pathCtrl,
                  hint: 'kelivo_backups',
                  onChanged: (v) => persist(cfg.copyWith(path: v.trim().isEmpty ? 'kelivo_backups' : v.trim())),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Items selection
        Row(
          children: [
            Expanded(
              child: _ToggleCard(
                label: l10n.backupPageChatsLabel,
                selected: cfg.includeChats,
                onTap: () => persist(cfg.copyWith(includeChats: !cfg.includeChats)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleCard(
                label: l10n.backupPageFilesLabel,
                selected: cfg.includeFiles,
                onTap: () => persist(cfg.copyWith(includeFiles: !cfg.includeFiles)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Actions (each on its own row)
        _IosOutlineButton(
          icon: Lucide.Cable,
          onPressed: vm.busy ? null : () async {
            await vm.test();
            if (!mounted) return;
            final rawMessage = vm.message;
            final message = rawMessage ?? l10n.backupPageTestDone;
            showAppSnackBar(
              context,
              message: message,
              type: rawMessage != null && rawMessage != 'OK'
                  ? NotificationType.error
                  : NotificationType.success,
            );
          },
          label: l10n.backupPageTestConnection,
        ),
        const SizedBox(height: 8),
        _IosOutlineButton(
          icon: Lucide.Import,
          onPressed: vm.busy ? null : () async {
            await reloadRemote();
            if (!mounted) return;
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (ctx) => _RemoteListSheet(
                items: _remote,
                loading: _loadingRemote,
                onDelete: (item) async {
                  final list = await vm.deleteAndReload(item);
                  setState(() => _remote = list);
                },
                onRestore: (item) async {
                  Navigator.of(ctx).pop();
                  
                  // Show import mode selection dialog (refined iOS-like options)
                  if (!mounted) return;
                  final mode = await _chooseImportModeDialog(context);
                  
                  if (mode == null) return;
                  
                  await _runWithImportingOverlay(context, () => vm.restoreFromItem(item, mode: mode));
                  if (!mounted) return;
                  await showDialog(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: Text(l10n.backupPageRestartRequired),
                      content: Text(l10n.backupPageRestartContent),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dctx).pop(), child: Text(l10n.backupPageOK)),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          label: l10n.backupPageRestore,
        ),
        const SizedBox(height: 8),
        _IosFilledButton(
          onPressed: vm.busy ? null : () async {
            await _runWithExportingOverlay(context, () => vm.backup());
            if (!mounted) return;
            final rawMessage = vm.message;
            final message = rawMessage ?? l10n.backupPageBackupUploaded;
            showAppSnackBar(
              context,
              message: message,
              type: NotificationType.info,
            );
          },
          icon: Lucide.Upload,
          label: l10n.backupPageBackup,
        ),
      ],
    );
  }

  Widget _buildImportExportTab(BuildContext context, ColorScheme cs, BackupProvider vm, AppLocalizations l10n) {
    final cardColor = Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9);

    Future<void> doExport() async {
      final file = await _runWithExportingOverlay(context, () => vm.exportToFile());
      if (!mounted) return;
      // iPad: anchor popover to the overlay's center to ensure valid coordinate space
      Rect rect;
      final overlay = Overlay.of(context);
      final ro = overlay?.context.findRenderObject();
      if (ro is RenderBox && ro.hasSize) {
        final center = ro.size.center(Offset.zero);
        final global = ro.localToGlobal(center);
        rect = Rect.fromCenter(center: global, width: 1, height: 1);
      } else {
        final size = MediaQuery.of(context).size;
        rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 1, height: 1);
      }
      // Give a short delay to ensure the exporting overlay is fully dismissed
      await Future.delayed(const Duration(milliseconds: 50));
      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: rect,
      );
    }

    Future<void> doImportLocal() async {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      final path = result?.files.single.path;
      if (path == null) return;
      
      // Show import mode selection dialog (refined iOS-like options)
      if (!mounted) return;
      final mode = await _chooseImportModeDialog(context);
      
      if (mode == null) return;
      
      await _runWithImportingOverlay(context, () => vm.restoreFromLocalFile(File(path), mode: mode));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dctx) => AlertDialog(
          title: Text(l10n.backupPageRestartRequired),
          content: Text(l10n.backupPageRestartContent),
          actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(), child: Text(l10n.backupPageOK))],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _ActionCard(
          color: cardColor,
          icon: Lucide.Export,
          title: l10n.backupPageExportToFile,
          subtitle: l10n.backupPageExportToFileSubtitle,
          onTap: doExport,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          color: cardColor,
          icon: Lucide.Import2,
          title: l10n.backupPageImportBackupFile,
          subtitle: l10n.backupPageImportBackupFileSubtitle,
          onTap: doImportLocal,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l10n.backupPageImportFromOtherApps, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        ),
        const SizedBox(height: 8),
        _ActionCard(
          color: cardColor,
          icon: Lucide.Box,
          title: l10n.backupPageImportFromRikkaHub,
          subtitle: l10n.backupPageNotSupportedYet,
          onTap: () async {
            if (!mounted) return;
            showAppSnackBar(
              context,
              message: l10n.backupPageNotSupportedYet,
              type: NotificationType.warning,
            );
          },
        ),
      ],
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.enabled = true,
    this.suffix,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final bool enabled;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.8))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withOpacity(0.4))),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

// --- iOS tactile widgets: buttons, rows, bottom tabs ---

class _TactileIconButton extends StatefulWidget {
  const _TactileIconButton({required this.icon, required this.color, required this.onTap, this.size = 22});
  final IconData icon; final Color color; final VoidCallback onTap; final double size;
  @override State<_TactileIconButton> createState() => _TactileIconButtonState();
}

class _TactileIconButtonState extends State<_TactileIconButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final base = widget.color; final press = base.withOpacity(0.7);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(()=>_pressed=true),
      onTapUp: (_) => setState(()=>_pressed=false),
      onTapCancel: () => setState(()=>_pressed=false),
      onTap: () { Haptics.light(); widget.onTap(); },
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(widget.icon, size: widget.size, color: _pressed ? press : base)),
    );
  }
}

class _TactileRow extends StatefulWidget {
  const _TactileRow({required this.builder, this.onTap, this.pressedScale = 1.0});
  final Widget Function(bool pressed) builder; final VoidCallback? onTap; final double pressedScale;
  @override State<_TactileRow> createState() => _TactileRowState();
}

class _TactileRowState extends State<_TactileRow> {
  bool _pressed = false; void _set(bool v){ if(_pressed!=v) setState(()=>_pressed=v);} 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap==null?null:(_)=>_set(true),
      onTapUp: widget.onTap==null?null:(_)=>Future.delayed(const Duration(milliseconds: 120), ()=>_set(false)),
      onTapCancel: widget.onTap==null?null:()=>_set(false),
      onTap: widget.onTap==null?null:(){ Haptics.soft(); widget.onTap!.call(); },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110), curve: Curves.easeOutCubic,
        child: widget.builder(_pressed),
      ),
    );
  }
}

class _IosOutlineButton extends StatelessWidget {
  const _IosOutlineButton({required this.onPressed, required this.label, this.icon});
  final VoidCallback? onPressed; final String label; final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; final enabled = onPressed != null;
    final textColor = enabled ? cs.primary : cs.onSurface.withOpacity(0.35);
    return _TactileRow(
      pressedScale: 0.98,
      onTap: enabled ? onPressed : null,
      builder: (pressed) {
        final overlay = pressed ? (Theme.of(context).brightness==Brightness.dark ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.04)) : Colors.transparent;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: overlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (enabled ? cs.primary.withOpacity(0.5) : cs.outlineVariant.withOpacity(0.35))),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 16, color: textColor), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }
}

class _IosFilledButton extends StatelessWidget {
  const _IosFilledButton({required this.onPressed, required this.label, this.icon});
  final VoidCallback? onPressed; final String label; final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; final enabled = onPressed != null;
    final bg = enabled ? cs.primary : cs.onSurface.withOpacity(0.12);
    final fg = enabled ? cs.onPrimary : cs.onSurface.withOpacity(0.5);
    return _TactileRow(
      pressedScale: 0.98,
      onTap: enabled ? onPressed : null,
      builder: (pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ]),
        );
      },
    );
  }
}

class _SmallTactileIcon extends StatefulWidget {
  const _SmallTactileIcon({required this.icon, required this.onTap, this.baseColor});
  final IconData icon; final VoidCallback onTap; final Color? baseColor;
  @override State<_SmallTactileIcon> createState() => _SmallTactileIconState();
}

class _SmallTactileIconState extends State<_SmallTactileIcon> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? Theme.of(context).colorScheme.onSurface;
    final c = _pressed ? base.withOpacity(0.7) : base;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(()=>_pressed=true),
      onTapUp: (_) => setState(()=>_pressed=false),
      onTapCancel: () => setState(()=>_pressed=false),
      onTap: () { Haptics.soft(); widget.onTap(); },
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(widget.icon, size: 18, color: c)),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.index, required this.leftIcon, required this.leftLabel, required this.rightIcon, required this.rightLabel, required this.onSelect});
  final int index; final IconData leftIcon; final String leftLabel; final IconData rightIcon; final String rightLabel; final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(isDark ? 0.18 : 0.12), width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(children: [
        Expanded(child: _BottomTabItem(icon: leftIcon, label: leftLabel, selected: index==0, onTap: ()=>onSelect(0))),
        Expanded(child: _BottomTabItem(icon: rightIcon, label: rightLabel, selected: index==1, onTap: ()=>onSelect(1))),
      ]),
    );
  }
}

class _BottomTabItem extends StatefulWidget {
  const _BottomTabItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  @override State<_BottomTabItem> createState() => _BottomTabItemState();
}

class _BottomTabItemState extends State<_BottomTabItem> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; final base = cs.onSurface.withOpacity(0.7); final sel = cs.primary; final target = widget.selected ? sel : base;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(()=>_pressed=true),
      onTapUp: (_) => setState(()=>_pressed=false),
      onTapCancel: () => setState(()=>_pressed=false),
      onTap: () { Haptics.soft(); widget.onTap(); },
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: target), duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic,
        builder: (context, color, _) {
          final c = color ?? base;
          return AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 110), curve: Curves.easeOutCubic,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(widget.icon, size: 20, color: c),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c), child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = selected ? cs.primary.withOpacity(0.12) : (isDark ? Colors.white10 : const Color(0xFFF7F7F9));
    final border = selected ? cs.primary.withOpacity(0.50) : cs.outlineVariant.withOpacity(0.16);
    return _TactileRow(
      pressedScale: 0.98,
      onTap: onTap,
      builder: (pressed) {
        final overlay = pressed ? (isDark ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.05)) : Colors.transparent;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Color.alphaBlend(overlay, baseBg),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) Icon(Lucide.Check, size: 16, color: cs.primary),
              if (selected) const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? cs.primary : cs.onSurface.withOpacity(0.8))),
            ],
          ),
        );
      },
    );
  }
}

class _RemoteListSheet extends StatelessWidget {
  const _RemoteListSheet({required this.items, required this.loading, required this.onDelete, required this.onRestore});
  final List<BackupFileItem> items;
  final bool loading;
  final Future<void> Function(BackupFileItem) onDelete;
  final Future<void> Function(BackupFileItem) onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          child: Column(
            children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: cs.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(l10n.backupPageRemoteBackups, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: (items.isEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(l10n.backupPageNoBackups, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final it = items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant.withOpacity(0.18)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(it.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text(_fmtBytes(it.size), style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
                                      ],
                                    ),
                                  ),
                                  _SmallTactileIcon(icon: Lucide.Import, onTap: () => onRestore(it)),
                                  const SizedBox(width: 6),
                                  _SmallTactileIcon(icon: Lucide.Trash2, onTap: () => onDelete(it), baseColor: cs.error),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.color, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TactileRow(
      pressedScale: 0.98,
      onTap: onTap,
      builder: (pressed) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlay = pressed ? (isDark ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.05)) : Colors.transparent;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Color.alphaBlend(overlay, color),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.18)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: cs.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
                  ],
                ),
              ),
              const Icon(Lucide.ChevronRight, size: 18),
            ],
          ),
        );
      },
    );
  }
}
