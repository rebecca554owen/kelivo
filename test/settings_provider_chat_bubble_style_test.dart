import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:Kelivo/core/database/business_settings_router.dart';
import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/theme/chat_bubble_style.dart';

import 'support/business_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bubble style overrides default to empty', () async {
    final harness = await createBusinessTestHarness(initial: {});
    final settings = SettingsProvider(harness.preferences);
    await settings.loaded;

    expect(settings.chatBubbleStyleOverrides, const ChatBubbleStyleOverrides());
    expect(settings.chatBubbleStyleOverrides.isDefault, isTrue);
  });

  test('persists and reloads bubble style overrides', () async {
    final harness = await createBusinessTestHarness(initial: {});
    final settings = SettingsProvider(harness.preferences);
    await settings.loaded;

    const next = ChatBubbleStyleOverrides(
      backgroundArgbLight: 0xFF112233,
      frostedOpacity: 0.4,
      blurSigma: 22,
      cornerRadius: 8,
    );
    await settings.setChatBubbleStyleOverrides(next);

    expect(settings.chatBubbleStyleOverrides, next);
    expect(
      harness.preferences.getString('chat_bubble_style_overrides_v1'),
      jsonEncode(next.toJson()),
    );

    final reloaded = SettingsProvider(harness.preferences);
    await reloaded.loaded;
    expect(reloaded.chatBubbleStyleOverrides, next);
  });

  test('reset persists an empty override object', () async {
    final harness = await createBusinessTestHarness(initial: {});
    final settings = SettingsProvider(harness.preferences);
    await settings.loaded;
    await settings.setChatBubbleStyleOverrides(
      const ChatBubbleStyleOverrides(blurSigma: 9),
    );
    await settings.setChatBubbleStyleOverrides(
      const ChatBubbleStyleOverrides(),
    );

    expect(settings.chatBubbleStyleOverrides.isDefault, isTrue);
    expect(
      harness.preferences.getString('chat_bubble_style_overrides_v1'),
      '{}',
    );
  });

  test('backup registry classifies the overrides key as a preference', () {
    expect(
      BusinessKeyRegistry.classify('chat_bubble_style_overrides_v1'),
      BusinessKeyDisposition.preference,
    );
    expect(
      BusinessKeyRegistry.preferenceKeys,
      contains('chat_bubble_style_overrides_v1'),
    );
  });
}
