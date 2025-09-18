import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../icons/lucide_adapter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/snackbar.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';
  String _buildNumber = '';
  String _systemInfo = '';
  int _versionTapCount = 0;
  DateTime? _lastVersionTap;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final pkg = await PackageInfo.fromPlatform();
    String sys;
    if (Platform.isAndroid) {
      sys = 'Android';
    } else if (Platform.isIOS) {
      sys = 'iOS';
    } else if (Platform.isMacOS) {
      sys = 'macOS';
    } else if (Platform.isWindows) {
      sys = 'Windows';
    } else if (Platform.isLinux) {
      sys = 'Linux';
    } else {
      sys = Platform.operatingSystem;
    }
    setState(() {
      _version = pkg.version;
      _buildNumber = pkg.buildNumber;
      _systemInfo = sys;
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Fallback: try in-app web view
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _onVersionTap() {
    final now = DateTime.now();
    // Reset the counter if taps are spaced too far apart
    if (_lastVersionTap == null || now.difference(_lastVersionTap!) > const Duration(seconds: 2)) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount++;

    const threshold = 7;
    if (_versionTapCount < threshold) return;

    _versionTapCount = 0; // reset after unlock
    _showEasterEgg();
  }

  void _showEasterEgg() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            int testCounter = 0;
            
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.7,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Lucide.Sparkles, size: 28, color: cs.primary),
                      const SizedBox(height: 10),
                      Text(
                        l10n.aboutPageEasterEggTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                l10n.aboutPageEasterEggMessage,
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75), height: 1.3),
                              ),
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              Text(
                                'Toast Notification Test Area',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  _TestButton(
                                    label: 'Success',
                                    color: const Color(0xFF34C759),
                                    onTap: () {
                                      testCounter++;
                                      showAppSnackBar(
                                        context,
                                        message: 'Operation completed successfully! #$testCounter',
                                        type: NotificationType.success,
                                      );
                                    },
                                  ),
                                  _TestButton(
                                    label: 'Error',
                                    color: const Color(0xFFFF3B30),
                                    onTap: () {
                                      testCounter++;
                                      showAppSnackBar(
                                        context,
                                        message: 'An error occurred. Please try again. #$testCounter',
                                        type: NotificationType.error,
                                      );
                                    },
                                  ),
                                  _TestButton(
                                    label: 'Warning',
                                    color: const Color(0xFFFF9500),
                                    onTap: () {
                                      testCounter++;
                                      showAppSnackBar(
                                        context,
                                        message: 'Warning: Low battery detected #$testCounter',
                                        type: NotificationType.warning,
                                      );
                                    },
                                  ),
                                  _TestButton(
                                    label: 'Info',
                                    color: cs.primary,
                                    onTap: () {
                                      testCounter++;
                                      showAppSnackBar(
                                        context,
                                        message: 'New message received #$testCounter',
                                        type: NotificationType.info,
                                      );
                                    },
                                  ),
                                  _TestButton(
                                    label: 'With Action',
                                    color: cs.secondary,
                                    onTap: () {
                                      testCounter++;
                                      showAppSnackBar(
                                        context,
                                        message: 'File downloaded #$testCounter',
                                        type: NotificationType.success,
                                        actionLabel: 'Open',
                                        onAction: () {
                                          showAppSnackBar(
                                            context,
                                            message: 'Opening file...',
                                            type: NotificationType.info,
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  _TestButton(
                                    label: 'Long Message',
                                    color: cs.tertiary,
                                    onTap: () {
                                      testCounter++;
                                      showAppSnackBar(
                                        context,
                                        message: 'This is a very long message that demonstrates how the toast notification handles multiline text gracefully #$testCounter',
                                        type: NotificationType.info,
                                        duration: const Duration(seconds: 5),
                                      );
                                    },
                                  ),
                                  _TestButton(
                                    label: 'Quick Burst',
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                    onTap: () {
                                      for (int i = 0; i < 5; i++) {
                                        Future.delayed(Duration(milliseconds: i * 100), () {
                                          if (mounted) {
                                            showAppSnackBar(
                                              context,
                                              message: 'Rapid notification ${i + 1}',
                                              type: NotificationType.info,
                                              duration: const Duration(seconds: 2),
                                            );
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  _TestButton(
                                    label: 'Dismiss All',
                                    color: cs.error,
                                    onTap: () {
                                      AppSnackBarManager().dismissAll();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        child: Text(l10n.aboutPageEasterEggButton),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Lucide.ArrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: l10n.settingsPageBackButton,
        ),
        title: Text(l10n.settingsPageAbout),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Kelivo', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    l10n.aboutPageAppDescription,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _SvgChipButton(
                        assetPath: 'assets/icons/tencent-qq.svg',
                        label: 'Tencent',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.aboutPageNoQQGroup)),
                        ),
                      ),
                      _SvgChipButton(
                        assetPath: 'assets/icons/discord.svg',
                        label: 'Discord',
                        onTap: () => _openUrl('https://discord.gg/Tb8DyvvV5T'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverList.list(
            children: [
              const SizedBox(height: 8),
              _AboutItem(
                icon: Lucide.Code,
                title: l10n.aboutPageVersion,
                subtitle: _version.isEmpty ? '...' : '$_version / $_buildNumber',
                onTap: _onVersionTap,
              ),
              _AboutItem(
                icon: Lucide.Phone,
                title: l10n.aboutPageSystem,
                subtitle: _systemInfo.isEmpty ? '...' : _systemInfo,
              ),
              _AboutItem(
                icon: Lucide.Earth,
                title: l10n.aboutPageWebsite,
                subtitle: 'https://kelivo.psycheas.top/',
                onTap: () async {
                  final uri = Uri.parse('https://kelivo.psycheas.top/');
                  if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _AboutItem(
                icon: Lucide.Github,
                title: 'GitHub',
                subtitle: 'https://github.com/Chevey339/kelivo',
                onTap: () => _openUrl('https://github.com/Chevey339/kelivo'),
              ),
              _AboutItem(
                icon: Lucide.FileText,
                title: l10n.aboutPageLicense,
                subtitle: 'https://github.com/Chevey339/kelivo/blob/master/LICENSE',
                onTap: () => _openUrl('https://github.com/Chevey339/kelivo/blob/master/LICENSE'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.18 : 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 12),
                  child: Icon(icon, size: 20, color: cs.primary),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)),
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
  }
}

class _SvgChipButton extends StatelessWidget {
  const _SvgChipButton({required this.assetPath, required this.label, required this.onTap});
  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? Colors.white10 : cs.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                assetPath,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(cs.primary, BlendMode.srcIn),
              ),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? color : color.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
