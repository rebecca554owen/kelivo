import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../../../core/models/quick_phrase.dart';

class QuickPhraseMenu extends StatelessWidget {
  const QuickPhraseMenu({
    super.key,
    required this.phrases,
    required this.onSelect,
    required this.anchorPosition,
  });

  final List<QuickPhrase> phrases;
  final ValueChanged<QuickPhrase> onSelect;
  final Offset anchorPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Calculate menu position - fixed at bottom above input bar
    final double menuWidth = 250;
    final double maxMenuHeight = size.height * 0.5; // Reduced from 400


    // double left = (size.width - menuWidth) / 2;
    // if (left < 16) left = 16;
    // if (left + menuWidth > size.width - 16) left = size.width - menuWidth - 16;

    // Position menu at bottom left, with margin from edges
    double left = 16; // Fixed left margin
    double bottom =
        anchorPosition.dy + 2 + bottomPadding; // 12px gap above input bar

    // Adjust if off-screen horizontally
    if (left + menuWidth > size.width - 16) left = size.width - menuWidth - 16;

    return Stack(
      children: [
        Positioned(
          left: left,
          bottom: bottom,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: menuWidth,
                  constraints: BoxConstraints(maxHeight: maxMenuHeight),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.7)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      //   child: Row(
                      //     children: [
                      //       Icon(Lucide.Zap, size: 18, color: cs.primary),
                      //       const SizedBox(width: 8),
                      //       Text(
                      //         l10n.quickPhraseMenuTitle,
                      //         style: const TextStyle(
                      //           fontSize: 15,
                      //           fontWeight: FontWeight.w600,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      // Divider(
                      //   height: 1,
                      //   thickness: 1,
                      //   color: cs.outlineVariant.withOpacity(0.2),
                      // ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: phrases.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: cs.outlineVariant.withOpacity(0.15),
                          ),
                          itemBuilder: (context, index) {
                            final phrase = phrases[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onSelect(phrase),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            phrase.isGlobal
                                                ? Lucide.Zap
                                                : Lucide.botMessageSquare,
                                            size: 14,
                                            color: cs.primary.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              phrase.title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        phrase.content,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface.withOpacity(0.6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
            ),
          ),
        ),
      ],
    );
  }
}

Future<QuickPhrase?> showQuickPhraseMenu({
  required BuildContext context,
  required List<QuickPhrase> phrases,
  required Offset position,
}) async {
  if (phrases.isEmpty) return null;

  return await showDialog<QuickPhrase>(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    builder: (ctx) {
      return GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Container(
          color: Colors.transparent,
          child: QuickPhraseMenu(
            phrases: phrases,
            onSelect: (phrase) => Navigator.of(ctx).pop(phrase),
            anchorPosition: position,
          ),
        ),
      );
    },
  );
}
