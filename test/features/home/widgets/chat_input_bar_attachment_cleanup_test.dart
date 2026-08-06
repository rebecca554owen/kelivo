import "../../../support/business_test_harness.dart";
import 'dart:async';
import 'dart:io';

import 'package:Kelivo/core/models/chat_input_data.dart';
import 'package:Kelivo/core/providers/assistant_provider.dart';
import 'package:Kelivo/core/providers/settings_provider.dart';
import 'package:Kelivo/features/home/widgets/chat_input_bar.dart';
import 'package:Kelivo/icons/lucide_adapter.dart';
import 'package:Kelivo/l10n/app_localizations.dart';
import 'package:Kelivo/utils/image_compressor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:super_native_extensions/src/native/context.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.path);

  final String path;
  Completer<void>? appDataGate;
  int startedAppDataRequests = 0;
  int completedAppDataRequests = 0;

  Future<String> _getAppDataPath() async {
    startedAppDataRequests++;
    await appDataGate?.future;
    completedAppDataRequests++;
    return path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() => _getAppDataPath();

  @override
  Future<String?> getApplicationSupportPath() => _getAppDataPath();

  @override
  Future<String?> getApplicationCachePath() async => '$path/cache';

  @override
  Future<String?> getTemporaryPath() async => '$path/tmp';
}

const _config = ImageCompressConfig(
  enabled: true,
  quality: 80,
  maxLongEdge: 1024,
  includeTransparent: false,
);

void main() {
  late PathProviderPlatform previousPathProvider;
  late _FakePathProviderPlatform fakePathProvider;
  late Directory appSupportDir;
  late Directory userDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    previousPathProvider = PathProviderPlatform.instance;
    appSupportDir = await Directory.systemTemp.createTemp(
      'kelivo_input_cleanup_app_',
    );
    userDir = await Directory.systemTemp.createTemp(
      'kelivo_input_cleanup_user_',
    );
    fakePathProvider = _FakePathProviderPlatform(appSupportDir.path);
    PathProviderPlatform.instance = fakePathProvider;
  });

  tearDown(() async {
    PathProviderPlatform.instance = previousPathProvider;
    await _forceDelete(appSupportDir);
    await _forceDelete(userDir);
  });

  Future<File> writeUserImage(
    String name, {
    int byteCount = 256,
    Directory? parent,
  }) async {
    final dir = parent ?? userDir;
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(List<int>.filled(byteCount, 7), flush: true);
    return file;
  }

  Future<bool> fileExists(WidgetTester tester, File file) async {
    final result = await tester.runAsync(() => file.exists());
    return result ?? false;
  }

  Future<bool> pumpUntil(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final result = await tester.runAsync(() async {
      final deadline = DateTime.now().add(timeout);
      while (!condition() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return condition();
    });
    return result ?? false;
  }

  Widget buildHarness({
    required TextEditingController controller,
    required FocusNode focusNode,
    required Future<ChatInputSubmissionResult> Function(ChatInputData input)
    onSend,
    ChatInputBarController? mediaController,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: SettingsProvider(createBusinessTestPreferences()),
        ),
        ChangeNotifierProvider.value(
          value: AssistantProvider(
            preferences: createBusinessTestPreferences(),
          ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ChatInputBar(
            controller: controller,
            focusNode: focusNode,
            mediaController: mediaController,
            onSend: onSend,
          ),
        ),
      ),
    );
  }

  testWidgets('超过 5000 个字符的粘贴内容转为文本附件', (tester) async {
    final nativeClipboardContext = MockMessageChannelContext()
      ..registerMockMethodCallHandler('ClipboardReader', (_) {
        throw PlatformException(code: 'unavailable-in-widget-test');
      });
    setContextOverride(nativeClipboardContext);

    var clipboardText = '';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': clipboardText};
      }
      return null;
    });
    const clipboardFilesChannel = MethodChannel('app.clipboard');
    messenger.setMockMethodCallHandler(
      clipboardFilesChannel,
      (_) async => null,
    );
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(clipboardFilesChannel, null);
    });

    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();
    ChatInputData? submitted;
    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        focusNode: focusNode,
        mediaController: mediaController,
        onSend: (input) async {
          submitted = input;
          return ChatInputSubmissionResult.rejected;
        },
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();

    clipboardText = List.filled(5000, 'a').join();
    await _invokePasteShortcut(tester, focusNode);
    expect(
      await pumpUntil(tester, () => controller.text == clipboardText),
      isTrue,
    );
    expect(mediaController.snapshotInput(controller.text).documents, isEmpty);

    controller.text = 'keep';
    final firstLongPaste = List.filled(5001, 'b').join();
    final secondLongPaste = List.filled(5001, 'c').join();
    clipboardText = firstLongPaste;
    final firstWriteGate = Completer<void>();
    fakePathProvider.appDataGate = firstWriteGate;
    final startedRequestsBeforePaste = fakePathProvider.startedAppDataRequests;
    await _invokePasteShortcut(tester, focusNode);
    expect(
      fakePathProvider.startedAppDataRequests,
      greaterThan(startedRequestsBeforePaste),
    );

    fakePathProvider.appDataGate = null;
    clipboardText = secondLongPaste;
    await _invokePasteShortcut(tester, focusNode);
    expect(mediaController.hasUnreadyImages, isTrue);
    expect(mediaController.snapshotInput(controller.text).documents, isEmpty);

    await tester.tap(find.byIcon(Lucide.ArrowUp));
    await tester.pump();
    expect(submitted, isNull);

    firstWriteGate.complete();
    expect(
      await pumpUntil(
        tester,
        () =>
            mediaController.snapshotInput(controller.text).documents.length ==
            2,
      ),
      isTrue,
    );

    final input = mediaController.snapshotInput(controller.text);
    final firstAttachment = input.documents[0];
    final secondAttachment = input.documents[1];
    expect(controller.text, 'keep');
    final pastedFileName = RegExp(r'^pasted_\d+(?:\(\d+\))?\.txt$');
    expect(firstAttachment.fileName, matches(pastedFileName));
    expect(secondAttachment.fileName, matches(pastedFileName));
    expect(firstAttachment.path, isNot(secondAttachment.path));
    expect(firstAttachment.mime, 'text/plain');
    expect(secondAttachment.mime, 'text/plain');
    expect(
      await tester.runAsync(() => File(firstAttachment.path).readAsString()),
      firstLongPaste,
    );
    expect(
      await tester.runAsync(() => File(secondAttachment.path).readAsString()),
      secondLongPaste,
    );

    final uploadDir = Directory('${appSupportDir.path}/upload');
    final existingPaths = await tester.runAsync(
      () => uploadDir.list().map((entry) => entry.path).toSet(),
    );

    final disposeGate = Completer<void>();
    fakePathProvider.appDataGate = disposeGate;
    final completedRequestsBeforeDispose =
        fakePathProvider.completedAppDataRequests;
    clipboardText = List.filled(5001, 'd').join();
    await _invokePasteShortcut(tester, focusNode);
    expect(mediaController.hasUnreadyImages, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      disposeGate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    expect(
      fakePathProvider.completedAppDataRequests,
      greaterThan(completedRequestsBeforeDispose),
    );
    final remainingPaths = await tester.runAsync(
      () => uploadDir.list().map((entry) => entry.path).toSet(),
    );
    expect(remainingPaths, existingPaths);

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('发送后保留用户源文件，提交的是压缩副本', (tester) async {
    late File source;
    await tester.runAsync(() async {
      source = await writeUserImage('user_photo.png');
    });
    final product = File('${appSupportDir.path}/upload/user_photo.png');
    final controller = TextEditingController(text: 'with image');
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();
    ChatInputData? submitted;

    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        focusNode: focusNode,
        mediaController: mediaController,
        onSend: (input) async {
          submitted = input;
          return ChatInputSubmissionResult.sent;
        },
      ),
    );

    await tester.runAsync(() async {
      mediaController.enqueueImages(
        [source.path],
        _config,
        deleteSourcesAfterProcessing: false,
      );
    });
    expect(
      await pumpUntil(tester, () => !mediaController.hasUnreadyImages),
      isTrue,
      reason: 'image processing did not finish in time',
    );
    await tester.pump();
    expect(await fileExists(tester, product), isTrue);

    await tester.tap(find.byIcon(Lucide.ArrowUp));
    await tester.pumpAndSettle();

    expect(submitted?.imagePaths.single, product.path);
    expect(await fileExists(tester, source), isTrue);

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('restoreInput 清空草稿后保留用户源文件', (tester) async {
    late File source;
    await tester.runAsync(() async {
      source = await writeUserImage('restore_user.png');
    });
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();

    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        focusNode: focusNode,
        mediaController: mediaController,
        onSend: (_) async => ChatInputSubmissionResult.rejected,
      ),
    );

    await tester.runAsync(() async {
      mediaController.enqueueImages(
        [source.path],
        _config,
        deleteSourcesAfterProcessing: false,
      );
    });
    expect(
      await pumpUntil(tester, () => !mediaController.hasUnreadyImages),
      isTrue,
    );
    await tester.pump();

    await tester.runAsync(() async {
      mediaController.restoreInput(const ChatInputData(text: ''));
    });
    await tester.pump();

    expect(await fileExists(tester, source), isTrue);

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('dispose 后保留用户源文件', (tester) async {
    late File source;
    await tester.runAsync(() async {
      source = await writeUserImage('dispose_user.png');
    });
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();

    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        focusNode: focusNode,
        mediaController: mediaController,
        onSend: (_) async => ChatInputSubmissionResult.rejected,
      ),
    );

    await tester.runAsync(() async {
      mediaController.enqueueImages(
        [source.path],
        _config,
        deleteSourcesAfterProcessing: false,
      );
    });
    expect(
      await pumpUntil(tester, () => !mediaController.hasUnreadyImages),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());

    expect(await fileExists(tester, source), isTrue);

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('处理中丢弃只清理压缩副本，保留用户源文件', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();

    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        focusNode: focusNode,
        mediaController: mediaController,
        onSend: (_) async => ChatInputSubmissionResult.rejected,
      ),
    );

    late File source;
    final cleanupObserved = await tester.runAsync(() async {
      source = await writeUserImage(
        'inflight_user.png',
        byteCount: 8 * 1024 * 1024,
      );
      final uploadDir = Directory('${appSupportDir.path}/upload');
      await uploadDir.create(recursive: true);
      final product = File('${uploadDir.path}/inflight_user.png');
      var sawProductCreated = false;
      final productDeleted = Completer<void>();
      final subscription = uploadDir
          .watch(events: FileSystemEvent.create | FileSystemEvent.delete)
          .listen((event) {
            if (event.path != product.path) return;
            if (event.type == FileSystemEvent.create) {
              sawProductCreated = true;
            } else if (event.type == FileSystemEvent.delete &&
                sawProductCreated &&
                !productDeleted.isCompleted) {
              productDeleted.complete();
            }
          });
      addTearDown(subscription.cancel);

      mediaController.enqueueImages(
        [source.path],
        _config,
        deleteSourcesAfterProcessing: false,
      );
      // Discard synchronously while the task is in flight.
      mediaController.clearImages();

      await productDeleted.future.timeout(const Duration(seconds: 10));
      return !await product.exists();
    });

    expect(
      cleanupObserved,
      isTrue,
      reason: 'discarded compressed copy was not cleaned up',
    );
    expect(await fileExists(tester, source), isTrue);

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('应用自有临时源在处理完成后被删除', (tester) async {
    late File tempSource;
    await tester.runAsync(() async {
      tempSource = await writeUserImage('pasted_temp.png');
    });
    final product = File('${appSupportDir.path}/upload/pasted_temp.png');
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();

    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        focusNode: focusNode,
        mediaController: mediaController,
        onSend: (_) async => ChatInputSubmissionResult.rejected,
      ),
    );

    await tester.runAsync(() async {
      mediaController.enqueueImages(
        [tempSource.path],
        _config,
        deleteSourcesAfterProcessing: true,
      );
    });
    expect(
      await pumpUntil(tester, () => !mediaController.hasUnreadyImages),
      isTrue,
    );

    expect(await fileExists(tester, tempSource), isFalse);
    expect(await fileExists(tester, product), isTrue);

    controller.dispose();
    focusNode.dispose();
  });

  testWidgets('源文件删除失败会记录日志且保留源文件', (tester) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();

    try {
      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          focusNode: focusNode,
          mediaController: mediaController,
          onSend: (_) async => ChatInputSubmissionResult.rejected,
        ),
      );

      late File source;
      await tester.runAsync(() async {
        final readOnlyDir = Directory('${userDir.path}/readonly');
        await readOnlyDir.create(recursive: true);
        source = await writeUserImage('locked_temp.png', parent: readOnlyDir);
        await Process.run('chmod', ['0555', readOnlyDir.path]);

        mediaController.enqueueImages(
          [source.path],
          _config,
          deleteSourcesAfterProcessing: true,
        );
      });
      addTearDown(() async {
        await Process.run('chmod', ['-R', '0755', userDir.path]);
      });
      expect(
        await pumpUntil(tester, () => !mediaController.hasUnreadyImages),
        isTrue,
      );

      expect(
        logs.any((line) => line.contains('[ChatInputBar] Failed to delete')),
        isTrue,
        reason: 'deletion failure must be diagnosable via logs',
      );
      expect(await fileExists(tester, source), isTrue);
    } finally {
      debugPrint = previousDebugPrint;
    }

    controller.dispose();
    focusNode.dispose();
  }, skip: !(Platform.isMacOS || Platform.isLinux));

  testWidgets('压缩失败会记录日志且保留用户源文件', (tester) async {
    final logs = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };

    final controller = TextEditingController();
    final focusNode = FocusNode();
    final mediaController = ChatInputBarController();

    try {
      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          focusNode: focusNode,
          mediaController: mediaController,
          onSend: (_) async => ChatInputSubmissionResult.rejected,
        ),
      );

      late File source;
      await tester.runAsync(() async {
        // Block the upload directory with a plain file so compression cannot
        // persist the copy and must fail.
        await File('${appSupportDir.path}/upload').writeAsBytes(const [0]);
        source = await writeUserImage('failing_user.png');

        mediaController.enqueueImages(
          [source.path],
          _config,
          deleteSourcesAfterProcessing: false,
        );
      });
      expect(
        await pumpUntil(
          tester,
          () => logs.any((line) => line.contains('[ImageCompressor]')),
        ),
        isTrue,
        reason: 'compression failure must be diagnosable via logs',
      );

      expect(await fileExists(tester, source), isTrue);
    } finally {
      debugPrint = previousDebugPrint;
    }

    controller.dispose();
    focusNode.dispose();
  });
}

Future<void> _invokePasteShortcut(
  WidgetTester tester,
  FocusNode focusNode,
) async {
  final focus = tester
      .widgetList<Focus>(
        find.ancestor(of: find.byType(TextField), matching: find.byType(Focus)),
      )
      .firstWhere((widget) => widget.onKeyEvent != null);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.runAsync(() async {
    expect(
      focus.onKeyEvent!(
        focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyV,
          logicalKey: LogicalKeyboardKey.keyV,
          timeStamp: Duration.zero,
        ),
      ),
      KeyEventResult.handled,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

Future<void> _forceDelete(Directory dir) async {
  try {
    if (await dir.exists()) {
      await Process.run('chmod', ['-R', '0755', dir.path]);
      await dir.delete(recursive: true);
    }
  } catch (_) {}
}
