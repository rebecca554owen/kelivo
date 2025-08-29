import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../icons/lucide_adapter.dart';
import '../../../core/models/backup.dart';
import '../../../core/providers/backup_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/chat/chat_service.dart';

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
    final cs = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
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
            leading: IconButton(
              icon: const Icon(Lucide.ArrowLeft),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(zh ? '备份与恢复' : 'Backup & Restore'),
          ),
          body: PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: [
              _buildWebDavTab(context, cs, settings, vm, cfg, zh),
              _buildImportExportTab(context, cs, vm, zh),
            ],
          ),
          bottomNavigationBar: Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) {
                setState(() => _currentIndex = i);
                _pageCtrl.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                );
              },
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              indicatorColor: cs.primary.withOpacity(0.12),
              height: 80, // 底部tab高度
              destinations: [
                NavigationDestination(
                  icon: const Icon(Lucide.databaseBackup),
                  selectedIcon: Icon(Lucide.databaseBackup, color: cs.primary),
                  label: zh ? 'WebDAV 备份' : 'WebDAV',
                ),
                NavigationDestination(
                  icon: const Icon(Lucide.Import2),
                  selectedIcon: Icon(Lucide.Import2, color: cs.primary),
                  label: zh ? '导入和导出' : 'Import/Export',
                ),
              ],
            );
          }),
        );
      }),
    );
  }

  Widget _buildWebDavTab(BuildContext context, ColorScheme cs, SettingsProvider settings, BackupProvider vm, WebDavConfig cfg, bool zh) {
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
        // Form card
        Material(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InputRow(
                  label: zh ? 'WebDAV 服务器地址' : 'WebDAV Server URL',
                  controller: _urlCtrl,
                  hint: 'https://example.com/dav',
                  onChanged: (v) => persist(cfg.copyWith(url: v.trim())),
                ),
                const SizedBox(height: 12),
                _InputRow(
                  label: zh ? '用户名' : 'Username',
                  controller: _userCtrl,
                  onChanged: (v) => persist(cfg.copyWith(username: v.trim())),
                ),
                const SizedBox(height: 12),
                _InputRow(
                  label: zh ? '密码' : 'Password',
                  controller: _passCtrl,
                  obscure: !_showPassword,
                  onChanged: (v) => persist(cfg.copyWith(password: v)),
                  suffix: IconButton(
                    icon: Icon(_showPassword ? Lucide.EyeOff : Lucide.Eye),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                const SizedBox(height: 12),
                _InputRow(
                  label: zh ? '路径' : 'Path',
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
                label: zh ? '聊天记录' : 'Chats',
                selected: cfg.includeChats,
                onTap: () => persist(cfg.copyWith(includeChats: !cfg.includeChats)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleCard(
                label: zh ? '文件' : 'Files',
                selected: cfg.includeFiles,
                onTap: () => persist(cfg.copyWith(includeFiles: !cfg.includeFiles)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Actions (each on its own row)
        OutlinedButton.icon(
          onPressed: vm.busy ? null : () async {
            await vm.test();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vm.message ?? (zh ? '测试完成' : 'Test done'))),
            );
          },
          icon: Icon(Lucide.Cable, size: 18, color: cs.primary),
          label: Text(zh ? '测试连接' : 'Test', style: TextStyle(color: cs.primary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: cs.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
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
                  await vm.restoreFromItem(item);
                  if (!mounted) return;
                  await showDialog(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: Text(zh ? '需要重启应用' : 'Restart Required'),
                      content: Text(zh ? '恢复完成，需要重启以完全生效。' : 'Restore completed. Please restart the app.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dctx).pop(), child: Text(zh ? '好的' : 'OK')),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          icon: Icon(Lucide.Import, size: 18, color: cs.primary),
          label: Text(zh ? '恢复' : 'Restore', style: TextStyle(color: cs.primary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: cs.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: vm.busy ? null : () async {
            await vm.backup();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vm.message ?? (zh ? '已上传备份' : 'Backup uploaded'))),
            );
          },
          icon: const Icon(Lucide.Upload, size: 18),
          label: Text(zh ? '立即备份' : 'Backup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }

  Widget _buildImportExportTab(BuildContext context, ColorScheme cs, BackupProvider vm, bool zh) {
    final cardColor = Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9);

    Future<void> doExport() async {
      final file = await vm.exportToFile();
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    }

    Future<void> doImportLocal() async {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      final path = result?.files.single.path;
      if (path == null) return;
      await vm.restoreFromLocalFile(File(path));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dctx) => AlertDialog(
          title: Text(zh ? '需要重启应用' : 'Restart Required'),
          content: Text(zh ? '恢复完成，需要重启以完全生效。' : 'Restore completed. Please restart the app.'),
          actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(), child: Text(zh ? '好的' : 'OK'))],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _ActionCard(
          color: cardColor,
          icon: Lucide.Export,
          title: zh ? '导出为文件' : 'Export to File',
          subtitle: zh ? '导出APP数据为文件' : 'Export app data to a file',
          onTap: doExport,
        ),
        const SizedBox(height: 10),
        _ActionCard(
          color: cardColor,
          icon: Lucide.Import2,
          title: zh ? '备份文件导入' : 'Import Backup File',
          subtitle: zh ? '导入本地备份文件' : 'Import a local backup file',
          onTap: doImportLocal,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(zh ? '从其他APP导入' : 'Import from Other Apps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
        ),
        const SizedBox(height: 8),
        _ActionCard(
          color: cardColor,
          icon: Lucide.Box,
          title: zh ? '从 RikkaHub 导入' : 'Import from RikkaHub',
          subtitle: zh ? '暂不支持' : 'Not supported yet',
          onTap: () async {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(zh ? '暂不支持' : 'Not supported yet')));
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

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected ? cs.primary.withOpacity(0.12) : (isDark ? Colors.white10 : const Color(0xFFF7F7F9));
    final border = selected ? cs.primary.withOpacity(0.50) : cs.outlineVariant.withOpacity(0.16);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
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
        ),
      ),
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
    final cs = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
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
              Container(width: 42, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(zh ? '远端备份' : 'Remote Backups', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: (items.isEmpty)
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(zh ? '暂无备份' : 'No backups', style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                      )
                    : ListView.builder(
                        controller: controller,
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final it = items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Material(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                title: Text(it.displayName, maxLines: 3, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${it.size} bytes'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Lucide.Import, size: 18),
                                      tooltip: zh ? '恢复' : 'Restore',
                                      onPressed: () => onRestore(it),
                                    ),
                                    IconButton(
                                      icon: const Icon(Lucide.Trash2, size: 18),
                                      tooltip: zh ? '删除' : 'Delete',
                                      onPressed: () => onDelete(it),
                                    ),
                                  ],
                                ),
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
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
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
        ),
      ),
    );
  }
}
