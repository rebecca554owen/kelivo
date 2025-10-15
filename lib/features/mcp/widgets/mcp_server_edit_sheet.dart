import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/haptics.dart';
import '../../../icons/lucide_adapter.dart';
import '../../../core/providers/mcp_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/snackbar.dart';
import '../../../shared/widgets/ios_switch.dart';

class _HeaderEntry {
  final TextEditingController key;
  final TextEditingController value;
  _HeaderEntry(this.key, this.value);
  void dispose() {
    key.dispose();
    value.dispose();
  }
}

Future<void> showMcpServerEditSheet(BuildContext context, {String? serverId}) async {
  final cs = Theme.of(context).colorScheme;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _McpServerEditSheet(serverId: serverId),
  );
}

class _McpServerEditSheet extends StatefulWidget {
  const _McpServerEditSheet({this.serverId});
  final String? serverId;

  @override
  State<_McpServerEditSheet> createState() => _McpServerEditSheetState();
}

class _McpServerEditSheetState extends State<_McpServerEditSheet> with SingleTickerProviderStateMixin {
  late final bool isEdit = widget.serverId != null;
  TabController? _tab;

  bool _enabled = true;
  final _nameCtrl = TextEditingController();
  McpTransportType _transport = McpTransportType.http;
  final _urlCtrl = TextEditingController();
  final List<_HeaderEntry> _headers = [];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _tab = TabController(length: 2, vsync: this);
      final server = context.read<McpProvider>().getById(widget.serverId!)!;
      _enabled = server.enabled;
      _nameCtrl.text = server.name;
      _transport = server.transport;
      _urlCtrl.text = server.url;
      server.headers.forEach((k, v) {
        _headers.add(_HeaderEntry(TextEditingController(text: k), TextEditingController(text: v)));
      });
    }
  }

  @override
  void dispose() {
    _tab?.dispose();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    for (final h in _headers) {
      h.dispose();
    }
    super.dispose();
  }

  Widget _switchTile({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          IosSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _inputRow({required String label, required TextEditingController controller, String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.8))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.transparent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary.withOpacity(0.4))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _transportPicker() {
    return Row(
      children: [
        _segButton(
          label: 'Streamable HTTP',
          selected: _transport == McpTransportType.http,
          onTap: () => setState(() => _transport = McpTransportType.http),
        ),
        const SizedBox(width: 8),
        _segButton(
          label: 'SSE',
          selected: _transport == McpTransportType.sse,
          onTap: () => setState(() => _transport = McpTransportType.sse),
        ),
      ],
    );
  }

  Widget _segButton({required String label, required bool selected, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: _TactileRow(
        pressedScale: 0.98,
        onTap: onTap,
        builder: (pressed) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final baseBg = selected ? cs.primary.withOpacity(0.12) : Colors.transparent;
          // Use darker overlay in light mode to ensure visible press, lighter overlay in dark mode
          final overlay = pressed ? (isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07)) : Colors.transparent;
          final textColor = selected ? cs.primary : cs.onSurface.withOpacity(0.8);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Color.alphaBlend(overlay, baseBg),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? cs.primary : cs.outlineVariant.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          );
        },
      ),
    );
  }

  Widget _basicForm() {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _switchTile(label: l10n.mcpServerEditSheetEnabledLabel, value: _enabled, onChanged: (v) => setState(() => _enabled = v)),
        const SizedBox(height: 10),
        _inputRow(label: l10n.mcpServerEditSheetNameLabel, controller: _nameCtrl, hint: 'My MCP'),
        const SizedBox(height: 10),
        Text(l10n.mcpServerEditSheetTransportLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        _transportPicker(),
        const SizedBox(height: 10),
        if (_transport == McpTransportType.sse) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l10n.mcpServerEditSheetSseRetryHint, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
          ),
        ],
        _inputRow(label: l10n.mcpServerEditSheetUrlLabel, controller: _urlCtrl, hint: _transport == McpTransportType.sse ? 'http://localhost:3000/sse' : 'http://localhost:3000'),
        const SizedBox(height: 16),
        Text(l10n.mcpServerEditSheetCustomHeadersTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _headersEditor(),
      ],
    );
  }

  Widget _headersEditor() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _headers.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputRow(label: l10n.mcpServerEditSheetHeaderNameLabel, controller: _headers[i].key, hint: l10n.mcpServerEditSheetHeaderNameHint),
                const SizedBox(height: 10),
                _inputRow(label: l10n.mcpServerEditSheetHeaderValueLabel, controller: _headers[i].value, hint: l10n.mcpServerEditSheetHeaderValueHint),
                Align(
                  alignment: Alignment.centerRight,
                  child: _TactileIconButton(
                    icon: Lucide.Trash,
                    color: cs.error,
                    semanticLabel: l10n.mcpServerEditSheetRemoveHeaderTooltip,
                    onTap: () => setState(() => _headers.removeAt(i)),
                  ),
                ),
              ],
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: _TactileRow(
            pressedScale: 0.98,
            onTap: () => setState(() => _headers.add(_HeaderEntry(TextEditingController(), TextEditingController()))),
            builder: (pressed) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final bg = isDark ? Colors.white10 : const Color(0xFFF2F3F5);
              final border = cs.outlineVariant.withOpacity(0.3);
              final overlay = pressed ? (isDark ? Colors.black.withOpacity(0.06) : Colors.white.withOpacity(0.05)) : Colors.transparent;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(color: Color.alphaBlend(overlay, bg), borderRadius: BorderRadius.circular(999), border: Border.all(color: border)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Lucide.Plus, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(l10n.mcpServerEditSheetAddHeader, style: TextStyle(fontSize: 13, color: cs.primary, fontWeight: FontWeight.w600)),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    final mcp = context.read<McpProvider>();
    final name = _nameCtrl.text.trim().isEmpty ? 'MCP' : _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        message: l10n.mcpServerEditSheetUrlRequired,
        type: NotificationType.warning,
      );
      return;
    }
    final headers = <String, String>{
      for (final h in _headers)
        if (h.key.text.trim().isNotEmpty) h.key.text.trim(): h.value.text.trim(),
    };
    if (isEdit) {
      final old = mcp.getById(widget.serverId!)!;
      await mcp.updateServer(old.copyWith(enabled: _enabled, name: name, transport: _transport, url: url, headers: headers));
    } else {
      await mcp.addServer(enabled: _enabled, name: name, transport: _transport, url: url, headers: headers);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final mcp = context.watch<McpProvider>();
    final server = isEdit ? mcp.getById(widget.serverId!) : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: isEdit ? 0.85 : 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (c, controller) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text(isEdit ? l10n.mcpServerEditSheetTitleEdit : l10n.mcpServerEditSheetTitleAdd, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                    if (isEdit)
                      _TactileIconButton(
                        icon: Lucide.RefreshCw,
                        color: cs.primary,
                        semanticLabel: l10n.mcpServerEditSheetSyncToolsTooltip,
                        onTap: () => mcp.refreshTools(widget.serverId!),
                      ),
                  ],
                ),
              ),
              if (isEdit) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF7F7F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TabBar(
                      controller: _tab,
                      indicatorColor: cs.primary,
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurface.withOpacity(0.7),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        Tab(text: l10n.mcpServerEditSheetTabBasic),
                        Tab(text: l10n.mcpServerEditSheetTabTools),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    controller: controller,
                    children: [
                      if (!isEdit) _basicForm(),
                      if (isEdit) ...[
                        AnimatedBuilder(
                          animation: _tab!,
                          builder: (_, __) {
                            final idx = _tab!.index;
                            if (idx == 0) {
                              return _basicForm();
                            } else {
                              // Tools tab
                              final tools = server?.tools ?? const <McpToolConfig>[];
                              if (tools.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Center(
                                    child: Text(l10n.mcpServerEditSheetNoToolsHint, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (final tool in tools) ...[
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white10
                                            : const Color(0xFFF7F7F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: cs.outlineVariant.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(tool.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                if ((tool.description ?? '').isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(tool.description!, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.7))),
                                                ],
                                                if (tool.params.isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: tool.params.map((p) {
                                                      final color = p.required ? cs.primary : cs.onSurface.withOpacity(0.5);
                                                      final bg = p.required ? cs.primary.withOpacity(0.12) : cs.onSurface.withOpacity(0.06);
                                                      return Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: bg,
                                                          borderRadius: BorderRadius.circular(999),
                                                          border: Border.all(color: color.withOpacity(0.5)),
                                                        ),
                                                        child: Text(p.name, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IosSwitch(
                                            value: tool.enabled,
                                            onChanged: (v) => context.read<McpProvider>().setToolEnabled(server!.id, tool.name, v),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _IosOutlineButton(
                        label: l10n.mcpServerEditSheetCancel,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IosFilledButton(
                        label: l10n.mcpServerEditSheetSave,
                        icon: isEdit ? Lucide.Check : Lucide.Plus,
                        onTap: _onSave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- iOS tactile helpers (no ripple) ---

class _TactileIconButton extends StatefulWidget {
  const _TactileIconButton({required this.icon, required this.color, required this.onTap, this.semanticLabel, this.size = 20});
  final IconData icon; final Color color; final VoidCallback onTap; final String? semanticLabel; final double size;
  @override State<_TactileIconButton> createState() => _TactileIconButtonState();
}

class _TactileIconButtonState extends State<_TactileIconButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final base = widget.color; final press = base.withOpacity(0.7);
    return Semantics(
      button: true, label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(()=>_pressed=true),
        onTapUp: (_) => setState(()=>_pressed=false),
        onTapCancel: () => setState(()=>_pressed=false),
        onTap: () { Haptics.light(); widget.onTap(); },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(widget.icon, size: widget.size, color: _pressed ? press : base),
        ),
      ),
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
      onTapUp: widget.onTap==null?null:(_){ /* keep pressed a bit for better feel */ },
      onTapCancel: widget.onTap==null?null:()=>_set(false),
      onTap: widget.onTap==null?null:(){
        Haptics.soft();
        widget.onTap!.call();
        Future.delayed(const Duration(milliseconds: 120), () { if (mounted) _set(false); });
      },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110), curve: Curves.easeOutCubic,
        child: widget.builder(_pressed),
      ),
    );
  }
}

class _IosOutlineButton extends StatelessWidget {
  const _IosOutlineButton({required this.label, required this.onTap});
  final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TactileRow(
      pressedScale: 0.98,
      onTap: onTap,
      builder: (pressed) {
        final overlay = pressed ? (Theme.of(context).brightness==Brightness.dark ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.04)) : Colors.transparent;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: overlay,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
        );
      },
    );
  }
}

class _IosFilledButton extends StatelessWidget {
  const _IosFilledButton({required this.label, required this.onTap, this.icon});
  final String label; final VoidCallback onTap; final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _TactileRow(
      pressedScale: 0.98,
      onTap: onTap,
      builder: (pressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160), curve: Curves.easeOutCubic,
          decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: cs.onPrimary),
                const SizedBox(width: 6),
              ],
              Text(label, style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
