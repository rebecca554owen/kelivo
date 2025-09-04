import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../core/providers/mcp_provider.dart';
import '../../../theme/design_tokens.dart';
import '../widgets/mcp_server_edit_sheet.dart';

class McpPage extends StatelessWidget {
  const McpPage({super.key});

  Color _statusColor(BuildContext context, McpStatus s) {
    final cs = Theme.of(context).colorScheme;
    switch (s) {
      case McpStatus.connected:
        return Colors.green;
      case McpStatus.connecting:
        return cs.primary;
      case McpStatus.error:
      case McpStatus.idle:
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final mcp = context.watch<McpProvider>();
    final servers = mcp.servers.toList();

    Widget tag(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
        );

    Future<void> _showErrorDetails(String serverId, String? message, String name) async {
      final cs = Theme.of(context).colorScheme;
      final zh = Localizations.localeOf(context).languageCode == 'zh';
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zh ? '连接错误' : 'Connection Error', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(name, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
                    ),
                    child: Text(message?.isNotEmpty == true ? message! : (zh ? '未提供错误详情' : 'No details')),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).maybePop(),
                          icon: Icon(Lucide.X, size: 16, color: cs.primary),
                          label: Text(zh ? '关闭' : 'Close', style: TextStyle(color: cs.primary)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white10
                                : const Color(0xFFF2F3F5),
                            side: BorderSide(color: cs.outlineVariant.withOpacity(0.35)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ctx.read<McpProvider>().reconnect(serverId);
                            if (context.mounted) Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Lucide.RefreshCw, size: 18),
                          label: Text(zh ? '重新连接' : 'Reconnect'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Lucide.ArrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: zh ? '返回' : 'Back',
        ),
        title: const Text('MCP'),
        actions: [
          IconButton(
            icon: Icon(Lucide.Plus, color: cs.onSurface),
            tooltip: zh ? '添加 MCP' : 'Add MCP',
            onPressed: () async {
              await showMcpServerEditSheet(context);
            },
          ),
        ],
      ),
      body: servers.isEmpty
          ? Center(
              child: Text(
                zh ? '暂无 MCP 服务器' : 'No MCP servers',
                style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final s = servers[index];
                final st = mcp.statusFor(s.id);
                final err = mcp.errorFor(s.id);

                Widget tagStyled(String text, {Color? color}) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (color ?? cs.primary).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: (color ?? cs.primary).withOpacity(0.35)),
                      ),
                      child: Text(text, style: TextStyle(fontSize: 11, color: color ?? cs.primary, fontWeight: FontWeight.w700)),
                    );

                final card = Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onTap: () async {
                      await showMcpServerEditSheet(context, serverId: s.id);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
                        boxShadow: Theme.of(context).brightness == Brightness.dark ? [] : AppShadows.soft,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF2F3F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(Lucide.Terminal, size: 20, color: cs.primary),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: st == McpStatus.connecting
                                      ? SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                                          ),
                                        )
                                      : Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: s.enabled ? _statusColor(context, st) : cs.outline,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: cs.surface, width: 1.5),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Icon(Lucide.Settings, size: 18, color: cs.onSurface.withOpacity(0.6)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      tagStyled(st == McpStatus.connected
                                          ? (zh ? '已连接' : 'Connected')
                                          : (st == McpStatus.connecting ? (zh ? '连接中…' : 'Connecting…') : (zh ? '未连接' : 'Disconnected')),
                                          color: st == McpStatus.connected
                                              ? Colors.green
                                              : (st == McpStatus.connecting ? cs.primary : Colors.redAccent)),
                                      tagStyled(s.transport == McpTransportType.sse ? 'SSE' : 'HTTP'),
                                      tagStyled(zh ? '工具: ${s.tools.where((t) => t.enabled).length}/${s.tools.length}' : 'Tools: ${s.tools.where((t) => t.enabled).length}/${s.tools.length}'),
                                      if (!s.enabled) tagStyled(zh ? '已禁用' : 'Disabled', color: cs.onSurface.withOpacity(0.7)),
                                    ],
                                  ),
                                  if (st == McpStatus.error && (err?.isNotEmpty ?? false)) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Lucide.MessageCircleWarning, size: 14, color: Colors.red),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            zh ? '连接失败' : 'Connection failed',
                                            style: const TextStyle(fontSize: 12, color: Colors.red),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => _showErrorDetails(s.id, err, s.name),
                                          child: Text(zh ? '详情' : 'Details'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Slidable(
                    key: ValueKey('mcp-${s.id}'),
                    endActionPane: ActionPane(
                      motion: const StretchMotion(),
                      extentRatio: 0.42,
                      children: [
                        CustomSlidableAction(
                          autoClose: true,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? cs.error.withOpacity(0.22) : cs.error.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.error.withOpacity(0.35)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Lucide.Trash2, color: cs.error, size: 18),
                                  const SizedBox(width: 6),
                                  Text(zh ? '删除' : 'Delete', style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                          onPressed: (_) async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dctx) => AlertDialog(
                                backgroundColor: cs.surface,
                                title: Text(zh ? '确认删除' : 'Confirm Delete'),
                                content: Text(zh ? '删除后可通过撤销恢复。是否删除？' : 'This can be undone via Undo. Delete?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(dctx).pop(false), child: Text(zh ? '取消' : 'Cancel')),
                                  TextButton(onPressed: () => Navigator.of(dctx).pop(true), child: Text(zh ? '删除' : 'Delete')),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            final prov = context.read<McpProvider>();
                            final prev = prov.getById(s.id);
                            await prov.removeServer(s.id);
                            if (!context.mounted) return;
                            final snack = SnackBar(
                              content: Text(zh ? '已删除服务器' : 'Server deleted'),
                              action: SnackBarAction(
                                label: zh ? '撤销' : 'Undo',
                                onPressed: () async {
                                  if (prev == null) return;
                                  final newId = await prov.addServer(
                                    enabled: prev.enabled,
                                    name: prev.name,
                                    transport: prev.transport,
                                    url: prev.url,
                                    headers: prev.headers,
                                  );
                                  // Try to refresh tools when back online
                                  try { await prov.refreshTools(newId); } catch (_) {}
                                },
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snack);
                          },
                        ),
                      ],
                    ),
                    child: card,
                  ),
                );
              },
            ),
    );
  }
}
