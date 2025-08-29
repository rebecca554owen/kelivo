import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../icons/lucide_adapter.dart';
import 'package:provider/provider.dart';
import '../../../core/services/chat/chat_service.dart';
import '../../../core/services/api/chat_api_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/models/chat_item.dart';
import '../../../core/providers/user_provider.dart';
import '../../settings/pages/settings_page.dart';
import '../../../core/providers/assistant_provider.dart';
import '../../../core/providers/update_provider.dart';
import '../../../core/models/assistant.dart';
import '../../assistant/pages/assistant_settings_edit_page.dart';
import '../../chat/pages/chat_history_page.dart';
import 'package:flutter/services.dart';
import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class SideDrawer extends StatefulWidget {
  const SideDrawer({
    super.key,
    required this.userName,
    required this.assistantName,
    this.onSelectConversation,
    this.onNewConversation,
  });

  final String userName;
  final String assistantName;
  final void Function(String id)? onSelectConversation;
  final VoidCallback? onNewConversation;

  @override
  State<SideDrawer> createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Assistant avatar renderer shared across drawer views
  Widget _assistantAvatar(BuildContext context, Assistant? a, {double size = 28}) {
    final cs = Theme.of(context).colorScheme;
    final av = a?.avatar?.trim() ?? '';
    final name = a?.name ?? '';
    if (av.isNotEmpty) {
      if (av.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            av,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => _assistantInitialAvatar(cs, name, size),
          ),
        );
      } else if (!kIsWeb && (av.startsWith('/') || av.contains(':'))) {
        return ClipOval(
          child: Image(
            image: FileImage(File(av)),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return _assistantEmojiAvatar(cs, av, size);
      }
    }
    return _assistantInitialAvatar(cs, name, size);
  }

  Widget _assistantInitialAvatar(ColorScheme cs, String name, double size) {
    final letter = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: cs.primary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _assistantEmojiAvatar(ColorScheme cs, String emoji, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(emoji.characters.take(1).toString(), style: TextStyle(fontSize: size * 0.5)),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_query != _searchController.text) {
        setState(() => _query = _searchController.text);
      }
    });
    // Update check moved to app startup (main.dart)
  }

  void _showChatMenu(BuildContext context, ChatItem chat) async {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final chatService = context.read<ChatService>();
    final isPinned = chatService.getConversation(chat.id)?.isPinned ?? false;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Lucide.Edit, size: 20),
                title: Text(zh ? '重命名' : 'Rename'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _renameChat(context, chat);
                },
              ),
              ListTile(
                leading: Icon(Lucide.Pin, size: 20),
                title: Text(isPinned ? (zh ? '取消置顶' : 'Unpin') : (zh ? '置顶' : 'Pin')),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await chatService.togglePinConversation(chat.id);
                },
              ),
              ListTile(
                leading: Icon(Lucide.RefreshCw, size: 20),
                title: Text(zh ? '重新生成标题' : 'Regenerate Title'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _regenerateTitle(context, chat.id);
                },
              ),
              ListTile(
                leading: Icon(Lucide.Trash, size: 20, color: Colors.redAccent),
                title: Text(zh ? '删除' : 'Delete', style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final deletingCurrent = chatService.currentConversationId == chat.id;
                  await chatService.deleteConversation(chat.id);
                  // Show simple snackbar (no undo)
                  final zh2 = Localizations.localeOf(context).languageCode == 'zh';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(zh2 ? '已删除“${chat.title}”' : 'Deleted "${chat.title}"'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // If the deleted one was the current selection, trigger host's new-topic (draft) flow
                  if (deletingCurrent || chatService.currentConversationId == null) {
                    widget.onNewConversation?.call();
                  }
                  // Close the drawer, return to main page
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameChat(BuildContext context, ChatItem chat) async {
    final controller = TextEditingController(text: chat.title);
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(zh ? '重命名' : 'Rename'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: zh ? '输入新名称' : 'Enter new name',
            ),
            onSubmitted: (_) => Navigator.of(ctx).pop(true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(zh ? '取消' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(zh ? '确定' : 'OK'),
            ),
          ],
        );
      },
    );
    if (ok == true) {
      await context.read<ChatService>().renameConversation(chat.id, controller.text.trim());
    }
  }

  Future<void> _regenerateTitle(BuildContext context, String conversationId) async {
    final settings = context.read<SettingsProvider>();
    final chatService = context.read<ChatService>();
    final convo = chatService.getConversation(conversationId);
    if (convo == null) return;
    // Decide model
    final provKey = settings.titleModelProvider ?? settings.currentModelProvider;
    final mdlId = settings.titleModelId ?? settings.currentModelId;
    if (provKey == null || mdlId == null) return;
    final cfg = settings.getProviderConfig(provKey);
    // Content
    final msgs = chatService.getMessages(conversationId);
    final joined = msgs.where((m) => m.content.isNotEmpty).map((m) => '${m.role == 'assistant' ? 'Assistant' : 'User'}: ${m.content}').join('\n\n');
    final content = joined.length > 3000 ? joined.substring(0, 3000) : joined;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final prompt = settings.titlePrompt.replaceAll('{locale}', locale).replaceAll('{content}', content);
    try {
      final title = (await ChatApiService.generateText(config: cfg, modelId: mdlId, prompt: prompt)).trim();
      if (title.isNotEmpty) {
        await chatService.renameConversation(conversationId, title);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    String base;
    if (zh) {
      if (hour < 11) base = '早上好';
      else if (hour < 13) base = '中午好';
      else if (hour < 18) base = '下午好';
      else base = '晚上好';
      return '$base 👋';
    }
    if (hour < 12) base = 'Good morning';
    else if (hour < 17) base = 'Good afternoon';
    else base = 'Good evening';
    return '$base 👋';
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(aDay).inDays;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    if (diff == 0) return zh ? '今天' : 'Today';
    if (diff == 1) return zh ? '昨天' : 'Yesterday';
    final sameYear = now.year == date.year;
    if (zh) {
      return sameYear
          ? '${date.month}月${date.day}日'
          : '${date.year}年${date.month}月${date.day}日';
    }
    // Simple English format like Aug 10, 2025
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return sameYear
        ? '${months[date.month - 1]} ${date.day}'
        : '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<_ChatGroup> _groupByDate(BuildContext context, List<ChatItem> source) {
    final items = [...source];
    // group by day (truncate time)
    final map = <DateTime, List<ChatItem>>{};
    for (final c in items) {
      final d = DateTime(c.created.year, c.created.month, c.created.day);
      map.putIfAbsent(d, () => []).add(c);
    }
    // sort groups by date desc (recent first)
    final keys = map.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return [
      for (final k in keys)
        _ChatGroup(
          label: _dateLabel(context, k),
          items: (map[k]!..sort((a, b) => b.created.compareTo(a.created)))!,
        )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textBase = isDark ? Colors.white : Colors.black; // 纯黑（白天），夜间自动适配
    final chatService = context.watch<ChatService>();
    final ap = context.watch<AssistantProvider>();
    final currentAssistantId = ap.currentAssistantId;
    final conversations = chatService
        .getAllConversations()
        .where((c) => c.assistantId == currentAssistantId || c.assistantId == null)
        .toList();
    final all = conversations
        .map((c) => ChatItem(id: c.id, title: c.title, created: c.createdAt))
        .toList();

    final base = _query.trim().isEmpty
        ? all
        : all.where((c) => c.title.toLowerCase().contains(_query.toLowerCase())).toList();
    final pinnedList = base
        .where((c) => (chatService.getConversation(c.id)?.isPinned ?? false))
        .toList()
      ..sort((a, b) => b.created.compareTo(a.created));
    final rest = base
        .where((c) => !(chatService.getConversation(c.id)?.isPinned ?? false))
        .toList();
    final groups = _groupByDate(context, rest);

    // Avatar renderer: emoji / url / file / default initial
    Widget avatarWidget(String name, UserProvider up, {double size = 40}) {
      final type = up.avatarType;
      final value = up.avatarValue;
      if (type == 'emoji' && value != null && value.isNotEmpty) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(fontSize: size * 0.5),
          ),
        );
      }
      if (type == 'url' && value != null && value.isNotEmpty) {
        return ClipOval(
          child: Image.network(
            value,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Text('?', style: TextStyle(color: cs.primary, fontSize: size * 0.42, fontWeight: FontWeight.w700)),
            ),
          ),
        );
      }
      if (type == 'file' && value != null && value.isNotEmpty && !kIsWeb) {
        return ClipOval(
          child: Image(
            image: FileImage(File(value)),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }
      // default: initial
      final letter = name.isNotEmpty ? name.characters.first : '?';
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            color: cs.primary,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Fixed header + search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 用户信息区（点击昵称可修改）
                  Row(
                    children: [
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _editAvatar(context),
                        child: avatarWidget(widget.userName, context.watch<UserProvider>(), size: 48),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _editUserName(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  widget.userName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textBase,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(_greeting(context),
                                style: TextStyle(color: textBase, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. 搜索框（固定头部下方）
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: Localizations.localeOf(context).languageCode == 'zh'
                          ? '搜索聊天记录'
                          : 'Search chat history',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5), // 非常浅的淡灰色（白天），夜间自适配
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50), // 胶囊
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                    ),
                    style: TextStyle(color: textBase, fontSize: 14), // 黑色（白天）
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Scrollable conversation list below fixed header
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // Update banner under search box
                  Builder(builder: (context) {
                    final settings = context.watch<SettingsProvider>();
                    final upd = context.watch<UpdateProvider>();
                    if (!settings.showAppUpdates) return const SizedBox.shrink();
                    final info = upd.available;
                    if (upd.checking && info == null) {
                      return const SizedBox.shrink();
                    }
                    if (info == null) return const SizedBox.shrink();
                    final url = info.bestDownloadUrl();
                    if (url == null || url.isEmpty) return const SizedBox.shrink();
                    final ver = info.version;
                    final build = info.build;
                    final title = Localizations.localeOf(context).languageCode == 'zh'
                        ? (build != null ? '发现新版本：$ver ($build)' : '发现新版本：$ver')
                        : (build != null ? 'New version: $ver ($build)' : 'New version: $ver');
                    final cs2 = Theme.of(context).colorScheme;
                    final isDark2 = Theme.of(context).brightness == Brightness.dark;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: isDark2 ? Colors.white10 : const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final uri = Uri.parse(url);
                            try {
                              // Defer to url_launcher
                              // ignore: deprecated_member_use
                              await launchUrl(uri);
                            } catch (_) {
                              // Fallback: copy to clipboard
                              Clipboard.setData(ClipboardData(text: url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'zh' ? '已复制下载链接' : 'Link copied')),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Lucide.BadgeInfo, size: 18, color: cs2.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                if ((info.notes ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    info.notes!,
                                    style: TextStyle(fontSize: 13, color: cs2.onSurface.withOpacity(0.8)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // 3. 聊天记录区（按日期分组，最近在前；垂直列表）
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      key: ValueKey('${_query}_${groups.length}_${pinnedList.length}'),
                      children: [
                        if (pinnedList.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                            child: Text(
                              Localizations.localeOf(context).languageCode == 'zh' ? '置顶' : 'Pinned',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                            ),
                          ),
                          Column(
                            children: [
                              for (final chat in pinnedList)
                                _ChatTile(
                                  chat: chat,
                                  textColor: textBase,
                                  selected: chat.id == chatService.currentConversationId,
                                  onTap: () => widget.onSelectConversation?.call(chat.id),
                                  onLongPress: () => _showChatMenu(context, chat),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        for (final group in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 0, 6),
                            child: Text(
                              group.label,
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                            ),
                          ),
                          Column(
                            children: [
                              for (final chat in group.items)
                                _ChatTile(
                                  chat: chat,
                                  textColor: textBase,
                                  selected: chat.id == chatService.currentConversationId,
                                  onTap: () => widget.onSelectConversation?.call(chat.id),
                                  onLongPress: () => _showChatMenu(context, chat),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 底部工具栏（固定）
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: cs.surface,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Material(
                        color: cs.surface,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            final id = context.read<AssistantProvider>().currentAssistantId;
                            if (id != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AssistantSettingsEditPage(assistantId: id)),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(Lucide.Bot, size: 22, color: cs.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 右：默认助手卡片（仅关闭抽屉）
                      Expanded(
                        child: Material(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showAssistantPicker(context),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  _assistantAvatar(context, ap.currentAssistant, size: 28),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      (ap.currentAssistant?.name ?? widget.assistantName),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textBase),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              Navigator.of(context).pop();
                              final selectedId = await Navigator.of(context).push<String>(
                                MaterialPageRoute(builder: (_) => ChatHistoryPage(assistantId: currentAssistantId)),
                              );
                              if (selectedId != null && selectedId.isNotEmpty) {
                                widget.onSelectConversation?.call(selectedId);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Lucide.History, size: 18, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    Localizations.localeOf(context).languageCode == 'zh' ? '聊天历史' : 'History',
                                    style: TextStyle(color: textBase),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Lucide.Settings, size: 18, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    Localizations.localeOf(context).languageCode == 'zh' ? '设置' : 'Settings',
                                    style: TextStyle(color: textBase),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssistantPicker(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final ap = context.read<AssistantProvider>();
    final list = ap.assistants;
    final currentId = ap.currentAssistantId;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(Lucide.Bot, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(zh ? '选择助手' : 'Choose Assistant', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              for (final a in list)
                ListTile(
                  leading: _assistantAvatar(context, a, size: 36),
                  title: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: (a.id == currentId) ? Icon(Lucide.Check, size: 18, color: cs.primary) : null,
                  onTap: () async {
                    final ap = context.read<AssistantProvider>();
                    final settings = context.read<SettingsProvider>();
                    await ap.setCurrentAssistant(a.id);
                    // Seed current model with assistant default if provided
                    if ((a.chatModelProvider ?? '').isNotEmpty && (a.chatModelId ?? '').isNotEmpty) {
                      await settings.setCurrentModel(a.chatModelProvider!, a.chatModelId!);
                    }
                    // Close the picker sheet
                    if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                    // Trigger host's new-chat flow instead of creating here
                    widget.onNewConversation?.call();
                    // Close the drawer without extra snackbars
                    Navigator.of(context).maybePop();
                  },
                  onLongPress: () {
                    // Long press opens settings quickly
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AssistantSettingsEditPage(assistantId: a.id)),
                    );
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

extension on _SideDrawerState {
  Future<void> _editAvatar(BuildContext context) async {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(zh ? '选择图片' : 'Choose Image'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickLocalImage(context);
                },
              ),
              ListTile(
                title: Text(zh ? '选择表情' : 'Choose Emoji'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final emoji = await _pickEmoji(context);
                  if (emoji != null) {
                    await context.read<UserProvider>().setAvatarEmoji(emoji);
                  }
                },
              ),
              ListTile(
                title: Text(zh ? '输入链接' : 'Enter Link'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _inputAvatarUrl(context);
                },
              ),
              ListTile(
                title: Text(zh ? 'QQ头像' : 'Import from QQ'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _inputQQAvatar(context);
                },
              ),
              ListTile(
                title: Text(zh ? '重置' : 'Reset'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await context.read<UserProvider>().resetAvatar();
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickEmoji(BuildContext context) async {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    // Provide input to allow any emoji via system emoji keyboard,
    // plus a large set of quick picks for convenience.
    final controller = TextEditingController();
    String value = '';
    bool validGrapheme(String s) {
      final trimmed = s.characters.take(1).toString().trim();
      return trimmed.isNotEmpty && trimmed == s.trim();
    }
    final List<String> quick = const [
      '😀','😁','😂','🤣','😃','😄','😅','😊','😍','😘','😗','😙','😚','🙂','🤗','🤩','🫶','🤝','👍','👎','👋','🙏','💪','🔥','✨','🌟','💡','🎉','🎊','🎈','🌈','☀️','🌙','⭐','⚡','☁️','❄️','🌧️','🍎','🍊','🍋','🍉','🍇','🍓','🍒','🍑','🥭','🍍','🥝','🍅','🥕','🌽','🍞','🧀','🍔','🍟','🍕','🌮','🌯','🍣','🍜','🍰','🍪','🍩','🍫','🍻','☕','🧋','🥤','⚽','🏀','🏈','🎾','🏐','🎮','🎧','🎸','🎹','🎺','📚','✏️','💼','💻','🖥️','📱','🛩️','✈️','🚗','🚕','🚙','🚌','🚀','🛰️','🧠','🫀','💊','🩺','🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯','🦁','🐮','🐷','🐸','🐵'
    ];
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return StatefulBuilder(builder: (ctx, setLocal) {
          // Revert to non-scrollable dialog but cap grid height
          // based on available height when keyboard is visible.
          final media = MediaQuery.of(ctx);
          final avail = media.size.height - media.viewInsets.bottom;
          final double gridHeight = (avail * 0.28).clamp(120.0, 220.0);
          return AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: cs.surface,
            title: Text(zh ? '选择表情' : 'Choose Emoji'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(value.isEmpty ? '🙂' : value.characters.take(1).toString(), style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    onChanged: (v) => setLocal(() => value = v),
                    onSubmitted: (_) {
                      if (validGrapheme(value)) Navigator.of(ctx).pop(value.characters.take(1).toString());
                    },
                    decoration: InputDecoration(
                      hintText: zh ? '输入或粘贴任意表情' : 'Type or paste any emoji',
                      filled: true,
                      fillColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary.withOpacity(0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: quick.length,
                      itemBuilder: (c, i) {
                        final e = quick[i];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(ctx).pop(e),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(zh ? '取消' : 'Cancel'),
              ),
              TextButton(
                onPressed: validGrapheme(value) ? () => Navigator.of(ctx).pop(value.characters.take(1).toString()) : null,
                child: Text(
                  zh ? '保存' : 'Save',
                  style: TextStyle(
                    color: validGrapheme(value) ? cs.primary : cs.onSurface.withOpacity(0.38),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _inputAvatarUrl(BuildContext context) async {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        bool valid(String s) => s.trim().startsWith('http://') || s.trim().startsWith('https://');
        String value = '';
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: cs.surface,
            title: Text(zh ? '输入图片链接' : 'Enter Image URL'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: zh ? '例如: https://example.com/avatar.png' : 'e.g. https://example.com/avatar.png',
                filled: true,
                fillColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary.withOpacity(0.4)),
                ),
              ),
              onChanged: (v) => setLocal(() => value = v),
              onSubmitted: (_) {
                if (valid(value)) Navigator.of(ctx).pop(true);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(zh ? '取消' : 'Cancel'),
              ),
              TextButton(
                onPressed: valid(value) ? () => Navigator.of(ctx).pop(true) : null,
                child: Text(
                  zh ? '保存' : 'Save',
                  style: TextStyle(
                    color: valid(value) ? cs.primary : cs.onSurface.withOpacity(0.38),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
    if (ok == true) {
      final url = controller.text.trim();
      if (url.isNotEmpty) {
        await context.read<UserProvider>().setAvatarUrl(url);
      }
    }
  }

  Future<void> _inputQQAvatar(BuildContext context) async {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        String value = '';
        bool valid(String s) => RegExp(r'^[0-9]{5,12}$').hasMatch(s.trim());
        String randomQQ() {
          final lengths = <int>[5, 6, 7, 8, 9, 10, 11];
          final weights = <int>[1, 20, 80, 100, 240, 3000, 80];
          final total = weights.fold<int>(0, (a, b) => a + b);
          final rnd = math.Random();
          int roll = rnd.nextInt(total) + 1;
          int chosenLen = lengths.last;
          int acc = 0;
          for (int i = 0; i < lengths.length; i++) {
            acc += weights[i];
            if (roll <= acc) {
              chosenLen = lengths[i];
              break;
            }
          }
          final sb = StringBuffer();
          final firstGroups = <List<int>>[
            [1, 2],
            [3, 4],
            [5, 6, 7, 8],
            [9],
          ];
          final firstWeights = <int>[8, 4, 2, 1]; // ratio only; ensures 1-2 > 3-4 > 5-8 > 9
          final firstTotal = firstWeights.fold<int>(0, (a, b) => a + b);
          int r2 = rnd.nextInt(firstTotal) + 1;
          int idx = 0;
          int a2 = 0;
          for (int i = 0; i < firstGroups.length; i++) {
            a2 += firstWeights[i];
            if (r2 <= a2) { idx = i; break; }
          }
          final group = firstGroups[idx];
          sb.write(group[rnd.nextInt(group.length)]);
          for (int i = 1; i < chosenLen; i++) {
            sb.write(rnd.nextInt(10));
          }
          return sb.toString();
        }
        return StatefulBuilder(builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: cs.surface,
            title: Text(zh ? '使用QQ头像' : 'Import from QQ'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: zh ? '输入QQ号码（5-12位）' : 'Enter QQ number (5-12 digits)',
                filled: true,
                fillColor: Theme.of(ctx).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary.withOpacity(0.4)),
                ),
              ),
              onChanged: (v) => setLocal(() => value = v),
              onSubmitted: (_) {
                if (valid(value)) Navigator.of(ctx).pop(true);
              },
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () async {
                  // Try multiple times until a valid avatar is fetched
                  const int maxTries = 20;
                  bool applied = false;
                  for (int i = 0; i < maxTries; i++) {
                    final qq = randomQQ();
                    // debugPrint(qq);
                    final url = 'http://q2.qlogo.cn/headimg_dl?dst_uin=' + qq + '&spec=100';
                    try {
                      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
                      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
                        await context.read<UserProvider>().setAvatarUrl(url);
                        applied = true;
                        break;
                      }
                    } catch (_) {}
                  }
                  if (applied) {
                    if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(zh ? '获取随机QQ头像失败，请重试' : 'Failed to fetch random QQ avatar. Please try again.')),
                    );
                  }
                },
                child: Text(zh ? '随机QQ' : 'Random QQ'),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(zh ? '取消' : 'Cancel'),
                  ),
                  TextButton(
                    onPressed: valid(value) ? () => Navigator.of(ctx).pop(true) : null,
                    child: Text(
                      zh ? '保存' : 'Save',
                      style: TextStyle(
                        color: valid(value) ? cs.primary : cs.onSurface.withOpacity(0.38),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
    if (ok == true) {
      final qq = controller.text.trim();
      if (qq.isNotEmpty) {
        final url = 'https://q2.qlogo.cn/headimg_dl?dst_uin=' + qq + '&spec=100';
        await context.read<UserProvider>().setAvatarUrl(url);
      }
    }
  }

  Future<void> _pickLocalImage(BuildContext context) async {
    if (kIsWeb) {
      await _inputAvatarUrl(context);
      return;
    }
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 90,
      );
      if (!mounted) return;
      if (file != null) {
        await context.read<UserProvider>().setAvatarFilePath(file.path);
        return;
      }
    } on PlatformException catch (e) {
      // Gracefully degrade when plugin channel isn't available or permission denied.
      if (!mounted) return;
      final zh = Localizations.localeOf(context).languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(zh ? '无法打开相册，试试输入图片链接' : 'Unable to open gallery. Try entering an image URL.')),
      );
      await _inputAvatarUrl(context);
      return;
    } catch (_) {
      if (!mounted) return;
      final zh = Localizations.localeOf(context).languageCode == 'zh';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(zh ? '发生错误，试试输入图片链接' : 'Something went wrong. Try entering an image URL.')),
      );
      await _inputAvatarUrl(context);
      return;
    }
  }
  Future<void> _editUserName(BuildContext context) async {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final initial = widget.userName;
    final controller = TextEditingController(text: initial);
    const maxLen = 24;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        String value = controller.text;
        bool valid(String v) => v.trim().isNotEmpty && v.trim() != initial;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: cs.surface,
              title: Text(zh ? '设置昵称' : 'Set Nickname'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: maxLen,
                    textInputAction: TextInputAction.done,
                    onChanged: (v) => setLocal(() => value = v),
                    onSubmitted: (_) {
                      if (valid(value)) Navigator.of(ctx).pop(true);
                    },
                    decoration: InputDecoration(
                      labelText: zh ? '昵称' : 'Nickname',
                      hintText: zh ? '输入新的昵称' : 'Enter new nickname',
                      filled: true,
                      fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.primary.withOpacity(0.4)),
                      ),
                    ),
                    style: TextStyle(fontSize: 15, color: Theme.of(ctx).textTheme.bodyMedium?.color),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${value.trim().length}/$maxLen',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.45), fontSize: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(zh ? '取消' : 'Cancel'),
                ),
                TextButton(
                  onPressed: valid(value) ? () => Navigator.of(ctx).pop(true) : null,
                  child: Text(
                    zh ? '保存' : 'Save',
                    style: TextStyle(
                      color: valid(value) ? cs.primary : cs.onSurface.withOpacity(0.38),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        await context.read<UserProvider>().setName(text);
      }
    }
  }
}

class _ChatGroup {
  final String label;
  final List<ChatItem> items;
  _ChatGroup({required this.label, required this.items});
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat, required this.textColor, this.onTap, this.onLongPress, this.selected = false});

  final ChatItem chat;
  final Color textColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? cs.primary.withOpacity(0.12) : cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Text(
              chat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
