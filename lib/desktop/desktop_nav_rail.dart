import 'dart:io' show Platform, File;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:characters/characters.dart';
import '../l10n/app_localizations.dart';
import '../core/providers/user_provider.dart';
import '../core/providers/settings_provider.dart';
import 'desktop_context_menu.dart';
import '../icons/lucide_adapter.dart' as lucide;

/// A compact left rail for desktop with avatar, primary actions, and bottom system toggles.
class DesktopNavRail extends StatelessWidget {
  const DesktopNavRail({
    super.key,
    required this.onTapChat,
    required this.onTapTranslate,
    required this.onTapSettings,
  });

  final VoidCallback onTapChat;
  final VoidCallback onTapTranslate;
  final VoidCallback onTapSettings;

  static const double width = 52.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: width,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _UserAvatarButton(),
          const SizedBox(height: 12),
          _CircleAction(tooltip: l10n.desktopNavChatTooltip, icon: lucide.Lucide.MessageCircle, onTap: onTapChat, size: 40, iconSize: 18),
          const SizedBox(height: 8),
          _CircleAction(tooltip: l10n.desktopNavTranslateTooltip, icon: lucide.Lucide.Languages, onTap: onTapTranslate, size: 40, iconSize: 18),
          const Spacer(),
          _ThemeCycleButton(),
          const SizedBox(height: 8),
          _CircleAction(tooltip: l10n.desktopNavSettingsTooltip, icon: lucide.Lucide.Settings, onTap: onTapSettings, size: 40, iconSize: 18),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _UserAvatarButton extends StatefulWidget {
  @override
  State<_UserAvatarButton> createState() => _UserAvatarButtonState();
}

class _UserAvatarButtonState extends State<_UserAvatarButton> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final up = context.watch<UserProvider>();
    final cs = Theme.of(context).colorScheme;
    Widget avatar;
    final type = up.avatarType;
    final value = up.avatarValue;
    if (type == 'emoji' && value != null && value.isNotEmpty) {
      avatar = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(value, style: const TextStyle(fontSize: 20, decoration: TextDecoration.none)),
      );
    } else if (type == 'url' && value != null && value.isNotEmpty) {
      avatar = ClipOval(
        child: Image.network(value, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
          return _initialAvatar(up.name, cs);
        }),
      );
    } else if (type == 'file' && value != null && value.isNotEmpty) {
      // Local file path
      avatar = ClipOval(
        child: Image(image: FileImage(File(value)), width: 40, height: 40, fit: BoxFit.cover),
      );
    } else {
      avatar = _initialAvatar(up.name, cs);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        key: _key,
        onTapDown: (d) {
          _openMenu(context, d.globalPosition);
        },
        onSecondaryTapDown: (d) {
          _openMenu(context, d.globalPosition);
        },
        child: _HoverCircle(child: avatar, size: 44),
      ),
    );
  }

  Widget _initialAvatar(String name, ColorScheme cs) {
    final letter = name.isNotEmpty ? name.characters.first : '?';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: cs.primary.withOpacity(0.15), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(letter, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, decoration: TextDecoration.none)),
    );
  }

  void _openMenu(BuildContext context, Offset globalPos) async {
    final up = context.read<UserProvider>();
    final l10n = AppLocalizations.of(context)!;
    await showDesktopContextMenuAt(
      context,
      globalPosition: globalPos,
      items: [
        DesktopContextMenuItem(
          icon: lucide.Lucide.User,
          label: l10n.desktopAvatarMenuUseEmoji,
          onTap: () async {
            // Lightweight quick defaults for now
            await up.setAvatarEmoji('😄');
          },
        ),
        DesktopContextMenuItem(
          icon: lucide.Lucide.Image,
          label: l10n.desktopAvatarMenuChangeFromImage,
          onTap: () async {
            // Keep simple: open native file picker via FilePicker not available here without extra deps.
            // As a placeholder, reset to default to keep UX consistent for now.
            await up.resetAvatar();
          },
        ),
        DesktopContextMenuItem(
          icon: lucide.Lucide.RotateCw,
          label: l10n.desktopAvatarMenuReset,
          onTap: () async {
            await up.resetAvatar();
          },
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap, required this.tooltip, this.size = 44, this.iconSize = 20});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onTap,
        child: _HoverCircle(
          size: size,
          child: Icon(icon, size: iconSize, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _HoverCircle extends StatefulWidget {
  const _HoverCircle({required this.child, this.size = 44});
  final Widget child;
  final double size;
  @override
  State<_HoverCircle> createState() => _HoverCircleState();
}

class _HoverCircleState extends State<_HoverCircle> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _hovered ? cs.primary.withOpacity(0.10) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

class _ThemeCycleButton extends StatefulWidget {
  @override
  State<_ThemeCycleButton> createState() => _ThemeCycleButtonState();
}

class _ThemeCycleButtonState extends State<_ThemeCycleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final icon = _iconFor(sp.themeMode);
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.desktopNavThemeToggleTooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => _cycleTheme(context),
        child: _HoverCircle(
          size: 40,
          child: Icon(icon, size: 20, color: cs.onSurface),
        ),
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return lucide.Lucide.Sun;
      case ThemeMode.dark:
        return lucide.Lucide.Moon;
      case ThemeMode.system:
      default:
        return lucide.Lucide.Monitor;
    }
  }

  void _cycleTheme(BuildContext context) {
    final sp = context.read<SettingsProvider>();
    final current = sp.themeMode;
    final next = () {
      switch (current) {
        case ThemeMode.system:
          return ThemeMode.light;
        case ThemeMode.light:
          return ThemeMode.dark;
        case ThemeMode.dark:
          return ThemeMode.system;
      }
    }();
    sp.setThemeMode(next);
  }
}
