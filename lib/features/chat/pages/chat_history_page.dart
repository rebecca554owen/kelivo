import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../icons/lucide_adapter.dart';
import '../../../core/services/chat/chat_service.dart';
import '../../../core/models/conversation.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key, this.assistantId});
  final String? assistantId;

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final fmt = zh ? DateFormat('yyyy年M月d日 HH:mm:ss') : DateFormat('yyyy-MM-dd HH:mm:ss');
    return fmt.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final chatService = context.watch<ChatService>();
    final List<Conversation> all = chatService
        .getAllConversations()
        .where((c) => widget.assistantId == null || c.assistantId == widget.assistantId || c.assistantId == null)
        .toList();

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty ? all : all.where((c) => c.title.toLowerCase().contains(q)).toList();
    final pinned = filtered.where((c) => c.isPinned).toList();
    final others = filtered.where((c) => !c.isPinned).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Lucide.ArrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(zh ? '聊天历史' : 'Chat History'),
        actions: [
          IconButton(
            tooltip: zh ? '搜索' : 'Search',
            icon: Icon(_searching ? Lucide.X : Lucide.Search),
            onPressed: () {
              setState(() {
                if (_searching) _searchCtrl.clear();
                _searching = !_searching;
              });
            },
          ),
          IconButton(
            tooltip: zh ? '删除全部' : 'Delete All',
            icon: const Icon(Lucide.Trash2),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(zh ? '删除全部对话' : 'Delete All Conversations'),
                  content: Text(zh ? '确定要删除全部对话吗？此操作不可撤销。' : 'Are you sure you want to delete all conversations? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(zh ? '取消' : 'Cancel')),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(zh ? '删除' : 'Delete', style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<ChatService>().clearAllData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(zh ? '已删除全部对话' : 'All conversations deleted')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searching)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: zh ? '搜索对话' : 'Search conversations',
                    filled: true,
                    fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide(color: cs.primary.withOpacity(0.3)),
                    ),
                    prefixIcon: Icon(Lucide.Search, color: cs.onSurface.withOpacity(0.7), size: 18),
                    suffixIcon: (q.isNotEmpty)
                        ? IconButton(
                            icon: Icon(Lucide.X, size: 16, color: cs.onSurface.withOpacity(0.7)),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        zh ? '暂无对话' : 'No conversations',
                        style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                      ),
                    )
                  : ListView(
                      children: [
                        if (pinned.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                            child: Text(
                              zh ? '置顶' : 'Pinned',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary),
                            ),
                          ),
                          for (final c in pinned)
                            _ConversationCard(
                              conversation: c,
                              onTap: () => Navigator.of(context).pop(c.id),
                            ),
                          const SizedBox(height: 8),
                        ],
                        for (final c in others)
                          _ConversationCard(
                            conversation: c,
                            onTap: () => Navigator.of(context).pop(c.id),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, this.onTap});
  final Conversation conversation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white12 : const Color(0xFFF7F7F9);
    final border = cs.outlineVariant.withOpacity(0.16);
    final pinned = conversation.isPinned;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              children: [
                // Leading icon/avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Lucide.MessageCircle, size: 18, color: cs.primary),
                ),
                const SizedBox(width: 10),
                // Title and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Lucide.History, size: 14, color: cs.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 6),
                          Text(
                            _format(context, conversation.updatedAt),
                            style: TextStyle(fontSize: 12.5, color: cs.onSurface.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Pin toggle
                _PinButton(conversation: conversation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _format(BuildContext context, DateTime dt) {
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final fmt = zh ? DateFormat('yyyy年M月d日 HH:mm:ss') : DateFormat('yyyy-MM-dd HH:mm:ss');
    return fmt.format(dt);
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pinned = conversation.isPinned;
    return InkResponse(
      onTap: () async {
        await context.read<ChatService>().togglePinConversation(conversation.id);
      },
      radius: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: pinned ? cs.primary.withOpacity(0.12) : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(pinned ? Lucide.PinOff : Lucide.Pin, size: 16, color: pinned ? cs.primary : cs.onSurface.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(
              pinned ? (Localizations.localeOf(context).languageCode == 'zh' ? '已置顶' : 'Pinned') : (Localizations.localeOf(context).languageCode == 'zh' ? '置顶' : 'Pin'),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: pinned ? cs.primary : cs.onSurface.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
