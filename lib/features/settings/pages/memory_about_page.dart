import 'package:flutter/material.dart';

import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ios_tactile.dart';

/// Full-screen "about memory" page (mobile). Desktop uses a dialog instead.
class MemoryAboutPage extends StatelessWidget {
  const MemoryAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        leading: Tooltip(
          message: l10n.settingsPageBackButton,
          child: IosIconButton(
            icon: Lucide.ArrowLeft,
            color: cs.onSurface,
            size: 22,
            minSize: 44,
            semanticLabel: l10n.settingsPageBackButton,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text(l10n.memorySettingsAboutTitle),
      ),
      body: const MemoryAboutContent(),
    );
  }
}

/// Shared body for the about page (mobile) and desktop dialog.
class MemoryAboutContent extends StatelessWidget {
  const MemoryAboutContent({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          l10n.memorySettingsAboutBody,
          style: TextStyle(
            fontSize: 14,
            height: 1.55,
            color: cs.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
