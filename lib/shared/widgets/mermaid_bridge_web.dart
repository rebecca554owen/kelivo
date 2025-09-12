// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui' as ui; // ignore: uri_does_not_exist
import 'package:flutter/widgets.dart';

class MermaidViewHandle {
  final Widget widget;
  final Future<bool> Function() exportPng;
  MermaidViewHandle({required this.widget, required this.exportPng});
}

final Map<String, html.DivElement> _containers = {};

/// Web-only Mermaid renderer using JS injection (no extra Dart packages).
/// Returns a handle with the widget and an export-to-PNG action.
MermaidViewHandle? createMermaidView(String code, bool dark) {
  final container = html.DivElement()
    ..style.width = '100%'
    ..style.height = '120px' // initial minimal height to avoid zero-sized box
    ..style.display = 'block';

  final mermaidDiv = html.DivElement()
    ..classes.add('mermaid')
    ..style.width = '100%'
    ..style.display = 'block'
    ..text = code; // keep content escaped/safe

  // Center and margin similar to preview styles
  final style = html.StyleElement()
    ..text = '.mermaid{ text-align:center; margin: 12px 0; }';

  container.append(style);
  container.append(mermaidDiv);

  final viewType = 'mermaid-view-${DateTime.now().microsecondsSinceEpoch}-${_viewSeq++}';
  container.id = viewType;
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewType, (int id) => container);
  _containers[viewType] = container;

  // Ensure Mermaid script is present, then initialize and render this node.
  _ensureMermaidLoaded().then((_) async {
    try {
      final theme = dark ? 'dark' : 'default';
      final mermaid = js_util.getProperty(html.window, 'mermaid');
      js_util.callMethod(mermaid, 'initialize', [js_util.jsify({
        'startOnLoad': false,
        'theme': theme,
        'securityLevel': 'loose',
        'fontFamily': 'inherit',
      })]);

      // Render only this node and set explicit height to fit content
      await js_util.promiseToFuture(js_util.callMethod(mermaid, 'run', [js_util.jsify({
        'nodes': [mermaidDiv],
      })]));

      // After rendering, set container height to the SVG bbox height
      final svg = mermaidDiv.querySelector('svg');
      if (svg != null) {
        final rect = svg.getBoundingClientRect();
        final h = rect.height.ceil();
        container.style.height = '${h + 16}px';
      }
    } catch (_) {
      // ignore; caller will still see the code content
    }
  });

  Future<bool> export() async {
    try {
      final c = _containers[viewType];
      if (c == null) return false;
      final svg = c.querySelector('.mermaid svg');
      if (svg == null) return false;
      final rect = svg.getBoundingClientRect();
      final w = rect.width.ceil();
      final h = rect.height.ceil();
      final scale = (html.window.devicePixelRatio ?? 1) * 2;
      final canvas = html.CanvasElement(width: (w * scale).floor(), height: (h * scale).floor());
      final ctx = canvas.context2D;
      final cloned = (html.DocumentFragment.html('')..append(svg.clone(true))).children.first;
      final xmlRaw = (cloned?.outerHtml ?? svg.outerHtml) ?? '';
      final img = html.ImageElement();
      final completer = Completer<void>();
      img.onLoad.listen((_) => completer.complete());
      img.onError.listen((_) => completer.complete());
      img.src = 'data:image/svg+xml;charset=utf-8,' + Uri.encodeComponent(xmlRaw);
      await completer.future;
      ctx.fillStyle = '#ffffff';
      ctx.fillRect(0, 0, canvas.width!.toDouble(), canvas.height!.toDouble());
      ctx.drawImageScaled(img, 0, 0, canvas.width!, canvas.height!);
      final dataUrl = canvas.toDataUrl('image/png');
      final a = html.AnchorElement(href: dataUrl)
        ..download = 'mermaid_${DateTime.now().millisecondsSinceEpoch}.png'
        ..style.display = 'none';
      html.document.body?.append(a);
      a.click();
      a.remove();
      return true;
    } catch (_) {
      return false;
    }
  }

  return MermaidViewHandle(widget: HtmlElementView(viewType: viewType), exportPng: export);
}

int _viewSeq = 0;
Completer<void>? _loader;

Future<void> _ensureMermaidLoaded() {
  // If already available, return immediately.
  final has = js_util.hasProperty(html.window, 'mermaid');
  if (has) return Future.value();

  if (_loader != null) return _loader!.future;
  _loader = Completer<void>();

  // Inject script tag to load local mermaid asset (offline)
  final script = html.ScriptElement()
    ..src = 'assets/mermaid.min.js'
    ..defer = true
    ..async = true
    ..type = 'text/javascript';
  void complete() {
    if (!(_loader?.isCompleted ?? true)) {
      _loader!.complete();
    }
  }
  script.onLoad.listen((_) => complete());
  script.onError.listen((_) => complete());
  html.document.head?.append(script);
  return _loader!.future;
}
