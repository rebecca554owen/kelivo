import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../icons/lucide_adapter.dart';

class BottomToolsSheet extends StatelessWidget {
  const BottomToolsSheet({super.key, this.onCamera, this.onPhotos, this.onUpload, this.onClear, this.clearLabel});

  final VoidCallback? onCamera;
  final VoidCallback? onPhotos;
  final VoidCallback? onUpload;
  final VoidCallback? onClear;
  final String? clearLabel;

  String _t(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final primary = Theme.of(context).colorScheme.primary;

    Widget roundedAction({required IconData icon, required String label, VoidCallback? onTap}) {
      return Expanded(
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              overlayColor: MaterialStateProperty.resolveWith(
                (states) => primary.withOpacity(states.contains(MaterialState.pressed) ? 0.14 : 0.08),
              ),
              splashColor: primary.withOpacity(0.18),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap?.call();
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: primary),
                    const SizedBox(height: 6),
                    Text(label, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              roundedAction(
                icon: Lucide.Camera,
                label: _t(context, '拍照', 'Camera'),
                onTap: onCamera,
              ),
              const SizedBox(width: 12),
              roundedAction(
                icon: Lucide.Image,
                label: _t(context, '照片', 'Photos'),
                onTap: onPhotos,
              ),
              const SizedBox(width: 12),
              roundedAction(
                icon: Lucide.Upload,
                label: _t(context, '上传文件', 'Upload'),
                onTap: onUpload,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                overlayColor: MaterialStateProperty.resolveWith(
                  (states) => primary.withOpacity(states.contains(MaterialState.pressed) ? 0.14 : 0.08),
                ),
                splashColor: primary.withOpacity(0.18),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onClear?.call();
                },
                child: Center(
                  child: Text(clearLabel ?? _t(context, '清空上下文', 'Clear Context'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
