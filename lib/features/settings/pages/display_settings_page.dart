import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../icons/lucide_adapter.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../../../core/providers/settings_provider.dart';
import 'theme_settings_page.dart';
import '../../../theme/palettes.dart';

class DisplaySettingsPage extends StatefulWidget {
  const DisplaySettingsPage({super.key});

  @override
  State<DisplaySettingsPage> createState() => _DisplaySettingsPageState();
}

class _DisplaySettingsPageState extends State<DisplaySettingsPage> {

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    context.watch<SettingsProvider>(); // keep theme reactivity

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              )),
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Lucide.ArrowLeft, size: 22),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: zh ? '返回' : 'Back',
        ),
        title: Text(zh ? '显示设置' : 'Display Settings'),
      ),
      body: ListView(
        children: [
          // Theme settings entry card at the very top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _ThemeEntryCard(),
          ),
          const SizedBox(height: 4),
          _SwitchTile(
            icon: Lucide.User,
            title: zh ? '显示用户头像' : 'Show User Avatar',
            subtitle: zh
                ? '是否在聊天消息中显示用户头像'
                : 'Display user avatar in chat messages',
            value: context.watch<SettingsProvider>().showUserAvatar,
            onChanged: (v) => context.read<SettingsProvider>().setShowUserAvatar(v),
          ),
          const SizedBox(height: 6),
          _SwitchTile(
            icon: Lucide.Bot,
            title: zh ? '聊天列表模型图标' : 'Chat Model Icon',
            subtitle: zh
                ? '是否在聊天消息中显示模型图标'
                : 'Show model icon in chat messages',
            value: context.watch<SettingsProvider>().showModelIcon,
            onChanged: (v) => context.read<SettingsProvider>().setShowModelIcon(v),
          ),
          const SizedBox(height: 6),
          _SwitchTile(
            icon: Lucide.Type,
            title: zh ? '显示Token和上下文统计' : 'Show Token & Context Stats',
            subtitle: zh
                ? '显示 token 用量与消息数量'
                : 'Show token usage and message count',
            value: context.watch<SettingsProvider>().showTokenStats,
            onChanged: (v) => context.read<SettingsProvider>().setShowTokenStats(v),
          ),
          _SwitchTile(
            icon: Lucide.Brain,
            title: zh ? '自动折叠思考' : 'Auto-collapse Thinking',
            subtitle: zh
                ? '思考完成后自动折叠，保持界面简洁'
                : 'Collapse reasoning after finish',
            value: context.watch<SettingsProvider>().autoCollapseThinking,
            onChanged: (v) => context.read<SettingsProvider>().setAutoCollapseThinking(v),
          ),
          _SwitchTile(
            icon: Lucide.BadgeInfo,
            title: zh ? '显示更新' : 'Show Updates',
            subtitle: zh
                ? '显示应用更新通知'
                : 'Show app update notifications',
            value: context.watch<SettingsProvider>().showAppUpdates,
            onChanged: (v) => context.read<SettingsProvider>().setShowAppUpdates(v),
          ),
          _SwitchTile(
            icon: Lucide.ChevronRight,
            title: zh ? '消息导航按钮' : 'Message Navigation Buttons',
            subtitle: zh
                ? '滚动时显示快速跳转按钮'
                : 'Show quick jump buttons when scrolling',
            value: context.watch<SettingsProvider>().showMessageNavButtons,
            onChanged: (v) => context.read<SettingsProvider>().setShowMessageNavButtons(v),
          ),
          _SwitchTile(
            icon: Lucide.Vibrate,
            title: zh ? '消息生成触觉反馈' : 'Haptics on Generate',
            subtitle: zh
                ? '生成消息时启用触觉反馈'
                : 'Enable haptic feedback during generation',
            value: context.watch<SettingsProvider>().hapticsOnGenerate,
            onChanged: (v) => context.read<SettingsProvider>().setHapticsOnGenerate(v),
          ),
          _SwitchTile(
            icon: Lucide.MessageCirclePlus,
            title: zh ? '启动时新建对话' : 'New Chat on Launch',
            subtitle: zh
                ? '应用启动时自动创建新对话'
                : 'Automatically create a new chat on launch',
            value: context.watch<SettingsProvider>().newChatOnLaunch,
            onChanged: (v) => context.read<SettingsProvider>().setNewChatOnLaunch(v),
          ),

          sectionTitle(zh ? '聊天字体大小' : 'Chat Font Size'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (context) {
                      final theme = Theme.of(context);
                      final cs = theme.colorScheme;
                      final isDark = theme.brightness == Brightness.dark;
                      final scale = context.watch<SettingsProvider>().chatFontScale;
                      return Row(
                        children: [
                          Text('80%', style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SfSliderTheme(
                              data: SfSliderThemeData(
                                activeTrackHeight: 8,
                                inactiveTrackHeight: 8,
                                overlayRadius: 14,
                                activeTrackColor: cs.primary,
                                inactiveTrackColor: cs.onSurface.withOpacity(isDark ? 0.25 : 0.20),
                                tooltipBackgroundColor: cs.primary,
                                tooltipTextStyle: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600),
                                activeTickColor: cs.onSurface.withOpacity(isDark ? 0.45 : 0.35),
                                inactiveTickColor: cs.onSurface.withOpacity(isDark ? 0.30 : 0.25),
                                activeMinorTickColor: cs.onSurface.withOpacity(isDark ? 0.34 : 0.28),
                                inactiveMinorTickColor: cs.onSurface.withOpacity(isDark ? 0.24 : 0.20),
                              ),
                              child: SfSlider(
                                value: scale,
                                min: 0.8,
                                max: 1.5,
                                stepSize: 0.05,
                                showTicks: true,
                                showLabels: true,
                                interval: 0.1,
                                minorTicksPerInterval: 1,
                                enableTooltip: true,
                                shouldAlwaysShowTooltip: false,
                                tooltipShape: const SfPaddleTooltipShape(),
                                labelFormatterCallback: (value, text) => (value as double).toStringAsFixed(1),
                                thumbIcon: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: isDark ? [] : [
                                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 2)),
                                    ],
                                  ),
                                ),
                                onChanged: (v) => context.read<SettingsProvider>().setChatFontScale((v as double).clamp(0.8, 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(scale * 100).round()}%', style: TextStyle(color: cs.onSurface, fontSize: 12)),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        zh ? '这是一个示例的聊天文本' : 'This is a sample chat text',
                        style: TextStyle(fontSize: 16 * context.watch<SettingsProvider>().chatFontScale),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
                    ],
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeEntryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final zh = Localizations.localeOf(context).languageCode == 'zh';
    final settings = context.watch<SettingsProvider>();
    final palette = ThemePalettes.byId(settings.themePaletteId);
    final subtitleText = zh ? palette.displayNameZh : palette.displayNameEn;
    return Material(
      color: cs.surfaceVariant.withOpacity(isDark ? 0.18 : 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ThemeSettingsPage()),
        ),
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
                child: Icon(Lucide.Palette, size: 20, color: cs.primary),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(zh ? '主题设置' : 'Theme Settings',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitleText, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Icon(Lucide.ChevronRight, size: 18, color: cs.onSurface.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
