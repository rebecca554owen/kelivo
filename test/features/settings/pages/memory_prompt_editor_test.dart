import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/core/services/memory/memory_prompts.dart';
import 'package:Kelivo/features/settings/pages/memory_settings_page.dart';
import 'package:Kelivo/l10n/app_localizations.dart';

import '../../../support/business_test_harness.dart';

Future<SettingsProvider> _createSettings() async {
  SharedPreferences.setMockInitialValues({});
  final harness = await createBusinessTestHarness();
  final settings = SettingsProvider(harness.preferences);
  await settings.loaded;
  return settings;
}

Widget _wrap(SettingsProvider settings, {required Locale locale}) {
  return ChangeNotifierProvider.value(
    value: settings,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: MemorySettingsContent()),
    ),
  );
}

/// Opens the "memory rules" template editor from the settings list.
Future<void> _openRulesEditor(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editor shows one field, in the language the model is sent', (
    tester,
  ) async {
    final settings = await _createSettings();
    await settings.setMemoryPromptLang('zh');

    await tester.pumpWidget(_wrap(settings, locale: const Locale('zh')));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    await _openRulesEditor(tester, l10n.memoryPromptEditRulesTitle);

    // A single editor, holding the Chinese template — no language tabs.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(TabBar), findsNothing);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, MemoryPrompts.rulesZh);
  });

  testWidgets('editor follows an explicit English prompt language', (
    tester,
  ) async {
    final settings = await _createSettings();
    await settings.setMemoryPromptLang('en');

    // Interface is Chinese, but prompts were pinned to English, so the editor
    // must edit the template that actually reaches the model.
    await tester.pumpWidget(_wrap(settings, locale: const Locale('zh')));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    await _openRulesEditor(tester, l10n.memoryPromptEditRulesTitle);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, MemoryPrompts.rulesEn);
  });

  testWidgets('saving writes only the active language template', (
    tester,
  ) async {
    final settings = await _createSettings();
    await settings.setMemoryPromptLang('zh');

    await tester.pumpWidget(_wrap(settings, locale: const Locale('zh')));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    await _openRulesEditor(tester, l10n.memoryPromptEditRulesTitle);

    await tester.enterText(find.byType(TextField), '自定义规则');
    await tester.tap(find.byTooltip(l10n.memoryPromptEditSave));
    await tester.pumpAndSettle();

    expect(settings.memoryRulesPromptZh, '自定义规则');
    expect(settings.memoryRulesPromptEn, MemoryPrompts.rulesEn);
  });
}
