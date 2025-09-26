import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MermaidViewHandle {
  final Widget widget;
  final Future<bool> Function() exportPng;
  MermaidViewHandle({required this.widget, required this.exportPng});
}

/// Mobile/desktop (non-web) Mermaid renderer using webview_flutter.
/// Returns a handle with the widget and an export-to-PNG action.
MermaidViewHandle? createMermaidView(String code, bool dark, {Map<String, String>? themeVars}) {
  final key = GlobalKey<_MermaidInlineWebViewState>();
  final widget = _MermaidInlineWebView(key: key, code: code, dark: dark, themeVars: themeVars);
  Future<bool> doExport() async => await key.currentState?.exportPng() ?? false;
  return MermaidViewHandle(widget: widget, exportPng: doExport);
}

class _MermaidInlineWebView extends StatefulWidget {
  final String code;
  final bool dark;
  final Map<String, String>? themeVars;
  const _MermaidInlineWebView({Key? key, required this.code, required this.dark, this.themeVars}) : super(key: key);

  @override
  State<_MermaidInlineWebView> createState() => _MermaidInlineWebViewState();
}

class _MermaidInlineWebViewState extends State<_MermaidInlineWebView> {
  late final WebViewController _controller;
  double _height = 160;
  Completer<String?>? _exportCompleter;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('HeightChannel', onMessageReceived: (JavaScriptMessage msg) {
        final v = double.tryParse(msg.message);
        if (v != null && mounted) {
          setState(() {
            _height = max(120, v + 16);
          });
        }
      })
      ..addJavaScriptChannel('ExportChannel', onMessageReceived: (JavaScriptMessage msg) {
        if (_exportCompleter != null && !(_exportCompleter!.isCompleted)) {
          final b64 = msg.message;
          _exportCompleter!.complete(b64.isEmpty ? null : b64);
        }
      });
    _loadHtml();
  }

  @override
  void didUpdateWidget(covariant _MermaidInlineWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.code != widget.code || oldWidget.dark != widget.dark) {
      _loadHtml();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      height: _height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  Future<void> _loadHtml() async {
    // Load mermaid script from assets and inline it to avoid external requests.
    final mermaidJs = await rootBundle.loadString('assets/mermaid.min.js');
    final html = _buildHtml(widget.code, widget.dark, mermaidJs, widget.themeVars);
    await _controller.loadHtmlString(html);
  }

  String _buildHtml(String code, bool dark, String mermaidJs, Map<String, String>? themeVars) {
    final bg = dark ? '#111111' : '#ffffff';
    final fg = dark ? '#eaeaea' : '#222222';
    final escaped = code
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    // Build themeVariables JSON
    String themeVarsJson = '{}';
    if (themeVars != null && themeVars.isNotEmpty) {
      final entries = themeVars.entries.map((e) => '"${e.key}": "${e.value}"').join(',');
      themeVarsJson = '{' + entries + '}';
    }
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes, maximum-scale=5.0">
    <title>Mermaid</title>
    <script>${mermaidJs}</script>
    <style>
      html,body{margin:0;padding:0;background:${bg};color:${fg};}
      .wrap{padding:8px;}
      .mermaid{width:100%; text-align:center;}
    </style>
  </head>
  <body>
    <div class="wrap">
      <div class="mermaid">${escaped}</div>
    </div>
    <script>
      function postHeight(){
        try{
          const el = document.querySelector('.mermaid');
          const r = el.getBoundingClientRect();
          const scale = window.visualViewport ? window.visualViewport.scale : 1;
          const h = Math.ceil((r.height + 8) * scale);
          HeightChannel.postMessage(String(h));
        }catch(e){/*ignore*/}
      }
      window.exportSvgToPng = function(){
        try{
          const svg = document.querySelector('.mermaid svg');
          if(!svg){ ExportChannel.postMessage(''); return; }
          const rect = svg.getBoundingClientRect();
          const w = Math.ceil(rect.width);
          const h = Math.ceil(rect.height);
          const scale = (window.devicePixelRatio || 1) * 2;
          const canvas = document.createElement('canvas');
          canvas.width = Math.max(1, Math.floor(w * scale));
          canvas.height = Math.max(1, Math.floor(h * scale));
          const ctx = canvas.getContext('2d');
          const xml = new XMLSerializer().serializeToString(svg);
          const img = new Image();
          img.onload = function(){
            ctx.fillStyle = '${bg}';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
            const data = canvas.toDataURL('image/png');
            const b64 = data.split(',')[1] || '';
            ExportChannel.postMessage(b64);
          };
          img.onerror = function(){ ExportChannel.postMessage(''); };
          img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(xml)));
        }catch(e){
          ExportChannel.postMessage('');
        }
      };
      mermaid.initialize({ startOnLoad:false, theme: '${dark ? 'dark' : 'default'}', securityLevel:'loose', fontFamily: 'inherit', themeVariables: ${themeVarsJson} });
      mermaid.run({ querySelector: '.mermaid' }).then(postHeight).catch(postHeight);
      window.addEventListener('resize', postHeight);
      document.addEventListener('DOMContentLoaded', postHeight);
      setTimeout(postHeight, 200);
    </script>
  </body>
</html>
''';
  }

  Future<bool> exportPng() async {
    try {
      _exportCompleter = Completer<String?>();
      await _controller.runJavaScript('exportSvgToPng();');
      final b64 = await _exportCompleter!.future.timeout(const Duration(seconds: 8));
      if (b64 == null || b64.isEmpty) return false;
      final bytes = base64Decode(b64);
      final dir = await getTemporaryDirectory();
      final filename = 'mermaid_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      // iPad requires a non-zero popover source rect within the source view.
      final ro = context.findRenderObject();
      Rect rect;
      if (ro is RenderBox && ro.hasSize && ro.size.width > 0 && ro.size.height > 0) {
        final origin = ro.localToGlobal(Offset.zero);
        rect = origin & ro.size;
      } else {
        final size = MediaQuery.of(context).size;
        rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 1, height: 1);
      }
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Mermaid diagram',
        sharePositionOrigin: rect,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _exportCompleter = null;
    }
  }
}
