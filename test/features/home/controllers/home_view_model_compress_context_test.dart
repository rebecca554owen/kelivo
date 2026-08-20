import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:Kelivo/core/models/chat_message.dart';
import 'package:Kelivo/features/home/controllers/home_view_model.dart';

ChatMessage _message({
  required String id,
  required String role,
  required String content,
  String? groupId,
  int version = 0,
}) {
  return ChatMessage(
    id: id,
    role: role,
    content: content,
    conversationId: 'conversation-1',
    groupId: groupId ?? id,
    version: version,
  );
}

void main() {
  group('buildCompressContextContent', () {
    test('短内容在限制内保持原样', () {
      const joined = 'User: hello\n\nAssistant: hi';

      expect(
        buildCompressContextContent(
          joined,
          const CompressContextOptions(
            mode: CompressContextLimitMode.start,
            maxChars: 6000,
          ),
        ),
        joined,
      );
    });

    test('超长内容可保留开头', () {
      final early = 'User: first round\n\nAssistant: early answer\n\n';
      final middle = 'x' * 6000;
      final latest = '\n\nUser: thirtieth round\n\nAssistant: latest answer';
      final joined = '$early$middle$latest';

      final content = buildCompressContextContent(
        joined,
        const CompressContextOptions(
          mode: CompressContextLimitMode.start,
          maxChars: 6000,
        ),
      );

      expect(content.length, 6000);
      expect(content, contains('first round'));
      expect(content, isNot(contains('thirtieth round')));
    });

    test('超长内容可保留最近尾部', () {
      final early = 'User: first round\n\nAssistant: early answer\n\n';
      final middle = 'x' * 6000;
      final latest = '\n\nUser: thirtieth round\n\nAssistant: latest answer';
      final joined = '$early$middle$latest';

      final content = buildCompressContextContent(
        joined,
        const CompressContextOptions(
          mode: CompressContextLimitMode.recent,
          maxChars: 6000,
        ),
      );

      expect(content.length, 6000);
      expect(content, isNot(contains('first round')));
      expect(content, contains('thirtieth round'));
    });

    test('无限制保留完整内容', () {
      final joined = 'a' * 7000;

      final content = buildCompressContextContent(
        joined,
        const CompressContextOptions(mode: CompressContextLimitMode.unlimited),
      );

      expect(content, joined);
    });

    test('keepRecent 直通原文，不按字符窗截断', () {
      final joined = 'a' * 7000;

      final content = buildCompressContextContent(
        joined,
        const CompressContextOptions(
          mode: CompressContextLimitMode.keepRecent,
          keepUserMessages: 2,
        ),
      );

      expect(content, joined);
    });

    test('截断不劈开 emoji 代理对', () {
      // '😀' occupies two UTF-16 code units. A raw cut at 4 would tear it.
      const joined = 'abc😀def';

      final start = buildCompressContextContent(
        joined,
        const CompressContextOptions(
          mode: CompressContextLimitMode.start,
          maxChars: 4,
        ),
      );
      expect(start, 'abc');
      expect(() => jsonEncode(start), returnsNormally);

      final recent = buildCompressContextContent(
        joined,
        const CompressContextOptions(
          mode: CompressContextLimitMode.recent,
          maxChars: 4,
        ),
      );
      expect(recent, 'def');
      expect(() => jsonEncode(recent), returnsNormally);
    });
  });

  group('buildConversationTextForCompression', () {
    test('使用完整历史生成压缩文本', () {
      final visibleWindow = [
        _message(id: 'u80', role: 'user', content: 'visible user'),
        _message(id: 'a81', role: 'assistant', content: 'visible assistant'),
      ];
      final completeHistory = [
        _message(id: 'u0', role: 'user', content: 'earliest user'),
        _message(id: 'a1', role: 'assistant', content: 'earliest assistant'),
        ...visibleWindow,
      ];

      final text = buildConversationTextForCompression(completeHistory);

      expect(text, contains('User: earliest user'));
      expect(text, contains('Assistant: earliest assistant'));
      expect(text, contains('User: visible user'));
      expect(text, contains('Assistant: visible assistant'));
    });

    test('压缩文本会忽略空内容消息', () {
      final text = buildConversationTextForCompression([
        _message(id: 'u1', role: 'user', content: '  '),
        _message(id: 'a1', role: 'assistant', content: 'answer'),
      ]);

      expect(text, 'Assistant: answer');
    });
  });

  group('HomeViewModel.computeClearContextRemainingMessageCount', () {
    test('计数来自持久化总数，与窗口缓存无关', () {
      final count = HomeViewModel.computeClearContextRemainingMessageCount(
        totalMessages: 100,
        truncateIndex: -1,
      );

      expect(count, 100);
    });

    test('已有清空点时从持久化截断位置开始计数', () {
      final count = HomeViewModel.computeClearContextRemainingMessageCount(
        totalMessages: 100,
        truncateIndex: 90,
      );

      expect(count, 10);
    });

    test('截断位置越界时按未清空处理', () {
      final beyond = HomeViewModel.computeClearContextRemainingMessageCount(
        totalMessages: 100,
        truncateIndex: 101,
      );
      final atEnd = HomeViewModel.computeClearContextRemainingMessageCount(
        totalMessages: 100,
        truncateIndex: 100,
      );

      expect(beyond, 100);
      expect(atEnd, 0);
    });
  });

  group('selectKeepRecentMessages', () {
    test('保留最近 N 条用户消息及其后的全部消息，边界以用户消息开始', () {
      final messages = <ChatMessage>[
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: 'a1'),
        _message(id: 'u2', role: 'user', content: 'q2'),
        _message(id: 'a2', role: 'assistant', content: 'a2'),
        _message(id: 'u3', role: 'user', content: 'q3'),
        _message(id: 'a3', role: 'assistant', content: 'a3'),
      ];

      final kept = selectKeepRecentMessages(messages, 2);

      expect(kept.map((m) => m.id).toList(), ['u2', 'a2', 'u3', 'a3']);
    });

    test('保留区可包含未答复的尾部用户消息', () {
      final messages = <ChatMessage>[
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: 'a1'),
        _message(id: 'u2', role: 'user', content: 'q2'),
      ];

      final kept = selectKeepRecentMessages(messages, 1);

      expect(kept.map((m) => m.id).toList(), ['u2']);
    });

    test('N 覆盖全部用户消息时返回完整列表（无可压缩内容）', () {
      final messages = <ChatMessage>[
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: 'a1'),
        _message(id: 'u2', role: 'user', content: 'q2'),
      ];

      final kept = selectKeepRecentMessages(messages, 3);

      expect(kept.length, messages.length);
    });

    test('空内容的用户消息不参与计数', () {
      final messages = <ChatMessage>[
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: 'a1'),
        _message(id: 'u2', role: 'user', content: '   '),
        _message(id: 'u3', role: 'user', content: 'q3'),
        _message(id: 'a3', role: 'assistant', content: 'a3'),
      ];

      final kept = selectKeepRecentMessages(messages, 1);

      expect(kept.map((m) => m.id).toList(), ['u3', 'a3']);
    });

    test('保留区内的空内容助手消息（纯工具调用）严格保留为空气泡', () {
      final messages = <ChatMessage>[
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: ''),
        _message(id: 'u2', role: 'user', content: 'q2'),
        _message(id: 'a2', role: 'assistant', content: ''),
      ];

      final kept = selectKeepRecentMessages(messages, 1);

      expect(kept.map((m) => m.id).toList(), ['u2', 'a2']);
    });

    test('空输入 / 无 user / N ≤ 0 返回空', () {
      expect(
        selectKeepRecentMessages([
          _message(id: 'a1', role: 'assistant', content: 'a1'),
        ], 1),
        isEmpty,
      );
      expect(selectKeepRecentMessages(const [], 1), isEmpty);

      final messages = [
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: 'a1'),
      ];
      expect(selectKeepRecentMessages(messages, 0), isEmpty);
      expect(selectKeepRecentMessages(messages, -1), isEmpty);
    });
  });

  group('countUserMessages', () {
    test('只统计内容非空的用户消息', () {
      final messages = <ChatMessage>[
        _message(id: 'u1', role: 'user', content: 'q1'),
        _message(id: 'a1', role: 'assistant', content: 'a1'),
        _message(id: 'u2', role: 'user', content: '   '),
        _message(id: 'u3', role: 'user', content: 'q3'),
      ];

      expect(countUserMessages(messages), 2);
    });
  });

  group('defaultKeepUserMessageCountFor', () {
    test('少于 5 条用户消息时默认 1', () {
      expect(defaultKeepUserMessageCountFor(0), 1);
      expect(defaultKeepUserMessageCountFor(1), 1);
      expect(defaultKeepUserMessageCountFor(2), 1);
      expect(defaultKeepUserMessageCountFor(4), 1);
    });

    test('5-9 条用户消息时默认 2', () {
      expect(defaultKeepUserMessageCountFor(5), 2);
      expect(defaultKeepUserMessageCountFor(9), 2);
    });

    test('10 条及以上用户消息时默认 3', () {
      expect(defaultKeepUserMessageCountFor(10), 3);
      expect(defaultKeepUserMessageCountFor(100), 3);
    });
  });

  group('estimateCompressionTokens', () {
    test('保留区按长度占比折算 token', () {
      final est = estimateCompressionTokens(
        totalText: 'a' * 1000,
        keptText: 'b' * 250,
      );

      // 1000 ascii chars → 250 tokens；保留 250 字符 → 62.5 → 63
      expect(est.totalTokens, 250);
      expect(est.keptTokens, 63);
      // 总结区 187 tokens，10%-30% → 19..56 → 合计 82..119
      expect(est.minResultTokens, 82);
      expect(est.maxResultTokens, 119);
    });

    test('CJK 按 1.6 字符/token 估算', () {
      final est = estimateCompressionTokens(
        totalText: '中' * 400,
        keptText: '中' * 100,
      );

      expect(est.totalTokens, 250);
      expect(est.keptTokens, 63);
    });

    test('混合文本按 CJK 与非 CJK 分段估算', () {
      final est = estimateCompressionTokens(
        totalText: '中' * 200 + 'a' * 400,
        keptText: '',
      );

      expect(est.totalTokens, 225);
    });

    test('空文本返回全零', () {
      final est = estimateCompressionTokens(totalText: '', keptText: '');

      expect(est.totalTokens, 0);
      expect(est.keptTokens, 0);
      expect(est.minResultTokens, 0);
      expect(est.maxResultTokens, 0);
    });

    test('区间上界不低于下界', () {
      final est = estimateCompressionTokens(
        totalText: 'a' * 5000,
        keptText: 'b' * 100,
      );

      expect(est.minResultTokens, lessThanOrEqualTo(est.maxResultTokens));
      expect(est.keptTokens, lessThanOrEqualTo(est.totalTokens));
    });
  });

  group('resolveCompressContextModel', () {
    test('优先使用显式压缩模型', () {
      final resolved = resolveCompressContextModel(
        compressProvider: 'OpenAI',
        compressModelId: 'gpt-4o-mini',
        summaryProvider: 'Gemini',
        summaryModelId: 'gemini-2.5-flash',
        currentProvider: 'DeepSeek',
        currentModelId: 'deepseek-chat',
      );

      expect(resolved.providerKey, 'OpenAI');
      expect(resolved.modelId, 'gpt-4o-mini');
    });

    test('未设置压缩模型时按 summary → title → assistant → current 回退', () {
      expect(
        resolveCompressContextModel(
          summaryProvider: 'Gemini',
          summaryModelId: 'gemini-2.5-flash',
          titleProvider: 'OpenAI',
          titleModelId: 'gpt-4o-mini',
          currentProvider: 'DeepSeek',
          currentModelId: 'deepseek-chat',
        ),
        (providerKey: 'Gemini', modelId: 'gemini-2.5-flash'),
      );
      expect(
        resolveCompressContextModel(
          titleProvider: 'OpenAI',
          titleModelId: 'gpt-4o-mini',
          assistantProvider: 'Claude',
          assistantModelId: 'claude-sonnet',
          currentProvider: 'DeepSeek',
          currentModelId: 'deepseek-chat',
        ),
        (providerKey: 'OpenAI', modelId: 'gpt-4o-mini'),
      );
      expect(
        resolveCompressContextModel(
          assistantProvider: 'Claude',
          assistantModelId: 'claude-sonnet',
          currentProvider: 'DeepSeek',
          currentModelId: 'deepseek-chat',
        ),
        (providerKey: 'Claude', modelId: 'claude-sonnet'),
      );
      expect(
        resolveCompressContextModel(
          currentProvider: 'DeepSeek',
          currentModelId: 'deepseek-chat',
        ),
        (providerKey: 'DeepSeek', modelId: 'deepseek-chat'),
      );
    });

    test('全部未设置时返回空', () {
      final resolved = resolveCompressContextModel();

      expect(resolved.providerKey, isNull);
      expect(resolved.modelId, isNull);
    });
  });
}
