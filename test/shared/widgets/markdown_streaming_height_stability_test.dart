import "../../support/business_test_harness.dart";

import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/shared/widgets/markdown_with_highlight.dart';
import 'package:Kelivo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A long reply is rendered block by block while it streams and as one whole
/// document once it finishes. If the two render at different heights, the
/// timeline — which is pinned to the tail during generation — jumps by the
/// difference on the frame the reply ends. Every case here must measure the
/// same height on both paths.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('streaming and finished markdown are the same height', () {
    late WidgetTester boundTester;

    Future<double> heightFor(
      String text, {
      required bool streaming,
      required String tag,
      TextStyle? style,
    }) async {
      await boundTester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(createBusinessTestPreferences()),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: MarkdownWithCodeHighlight(
                  key: ValueKey<String>(tag),
                  text: text,
                  streaming: streaming,
                  baseStyle: style,
                ),
              ),
            ),
          ),
        ),
      );
      await boundTester.pump(const Duration(milliseconds: 300));
      return boundTester.getSize(find.byType(MarkdownWithCodeHighlight)).height;
    }

    Future<void> expectStableHeight(
      String label,
      List<String> blocks, {
      TextStyle? style,
    }) async {
      final text = blocks.join('\n\n');
      final streamingHeight = await heightFor(
        text,
        streaming: true,
        style: style,
        tag: '$label-streaming',
      );
      final finishedHeight = await heightFor(
        text,
        streaming: false,
        style: style,
        tag: '$label-finished',
      );
      expect(
        streamingHeight,
        finishedHeight,
        reason:
            '$label: the reply would jump ${finishedHeight - streamingHeight}px '
            'across ${blocks.length - 1} block boundaries when it finishes',
      );
    }

    // Only replies over 512 characters are rendered block by block, so every
    // block has to be padded past that threshold for the case to be meaningful.
    String pad(int index) =>
        'Body $index. ${'The rain kept falling on the quiet street. ' * 16}';

    testWidgets('across block shapes and base font sizes', (tester) async {
      boundTester = tester;
      tester.view.physicalSize = const Size(1170, 2100);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await expectStableHeight('two paragraphs', [pad(1), pad(2)]);
      await expectStableHeight('four paragraphs', [
        pad(1),
        pad(2),
        pad(3),
        pad(4),
      ]);
      await expectStableHeight('headings between paragraphs', [
        '# Heading one',
        pad(1),
        '## Heading two',
        pad(2),
      ]);
      await expectStableHeight('paragraph then list', [
        pad(1),
        '- one\n- two\n- three',
      ]);
      await expectStableHeight('list then paragraph', [
        '- one\n- two\n- three',
        pad(1),
      ]);
      await expectStableHeight('paragraph then code', [
        pad(1),
        '```dart\nvar a = 1;\n```',
      ]);
      await expectStableHeight('code then paragraph', [
        '```dart\nvar a = 1;\n```',
        pad(1),
      ]);
      await expectStableHeight('larger base font', [
        pad(1),
        pad(2),
        pad(3),
        pad(4),
      ], style: const TextStyle(fontSize: 20, height: 1.5));
      await expectStableHeight('smaller base font', [
        pad(1),
        pad(2),
        pad(3),
        pad(4),
      ], style: const TextStyle(fontSize: 12, height: 1.5));
    });

    testWidgets('for a long multi-paragraph reply', (tester) async {
      boundTester = tester;
      tester.view.physicalSize = const Size(1170, 2100);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await expectStableHeight(
        'thirty paragraphs',
        List<String>.generate(30, pad),
      );
    });
  });
}
