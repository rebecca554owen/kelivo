import 'package:flutter/material.dart';
import '../../core/services/haptics.dart';

class IosTileButton extends StatefulWidget {
  const IosTileButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.fontSize = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double fontSize;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  State<IosTileButton> createState() => _IosTileButtonState();
}

class _IosTileButtonState extends State<IosTileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final baseBg = widget.backgroundColor ?? (isDark ? Colors.white10 : const Color(0xFFF2F3F5));
    final overlay = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);
    final pressedBg = Color.alphaBlend(overlay, baseBg);
    final defaultFg = widget.backgroundColor == null
        ? cs.onSurface.withOpacity(0.9)
        : (widget.foregroundColor ?? cs.onPrimary);
    final iconColor = defaultFg;
    final textColor = defaultFg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        Haptics.light();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _pressed ? pressedBg : baseBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Icon(widget.icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
