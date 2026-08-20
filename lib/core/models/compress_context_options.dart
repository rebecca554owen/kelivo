import 'chat_message.dart';
import '../../utils/utf16_safe_cut.dart';

enum CompressContextLimitMode { start, recent, unlimited, keepRecent }

class CompressContextOptions {
  const CompressContextOptions({
    required this.mode,
    this.maxChars,
    this.keepUserMessages,
  });

  static const int defaultMaxChars = 6000;
  static const int defaultKeepUserMessages = 3;

  final CompressContextLimitMode mode;
  final int? maxChars;
  final int? keepUserMessages;
}

/// Resolve the model that [HomeViewModel.compressContext] will call.
///
/// Chain: compress → summary → title → assistant chat → global default.
/// Provider and model id are resolved independently (same as the existing
/// `??` chain) so a half-set pair can still mix with a later fallback.
({String? providerKey, String? modelId}) resolveCompressContextModel({
  String? compressProvider,
  String? compressModelId,
  String? summaryProvider,
  String? summaryModelId,
  String? titleProvider,
  String? titleModelId,
  String? assistantProvider,
  String? assistantModelId,
  String? currentProvider,
  String? currentModelId,
}) {
  return (
    providerKey:
        compressProvider ??
        summaryProvider ??
        titleProvider ??
        assistantProvider ??
        currentProvider,
    modelId:
        compressModelId ??
        summaryModelId ??
        titleModelId ??
        assistantModelId ??
        currentModelId,
  );
}

String buildCompressContextContent(
  String joined,
  CompressContextOptions options,
) {
  if (options.mode == CompressContextLimitMode.unlimited ||
      options.mode == CompressContextLimitMode.keepRecent) {
    return joined;
  }
  final maxChars = options.maxChars ?? CompressContextOptions.defaultMaxChars;
  if (maxChars <= 0 || joined.length <= maxChars) return joined;
  return switch (options.mode) {
    CompressContextLimitMode.start => truncateHeadUtf16Safe(joined, maxChars),
    CompressContextLimitMode.recent => joined.substring(
      utf16SafeTailStart(joined, joined.length - maxChars),
    ),
    CompressContextLimitMode.unlimited ||
    CompressContextLimitMode.keepRecent => joined,
  };
}

String buildConversationTextForCompression(List<ChatMessage> messages) {
  return messages
      .where((m) => m.content.trim().isNotEmpty)
      .map(
        (m) => '${m.role == "assistant" ? "Assistant" : "User"}: ${m.content}',
      )
      .join('\n\n');
}

/// Select the trailing messages starting at the last [keepUserMessages]
/// user messages (user messages = role 'user' with non-empty content), so
/// the kept region always starts with a user message. When the requested
/// count covers all user messages, returns the full list (nothing left to
/// summarize).
List<ChatMessage> selectKeepRecentMessages(
  List<ChatMessage> messages,
  int keepUserMessages,
) {
  if (keepUserMessages <= 0) return const <ChatMessage>[];
  final userIndices = <int>[];
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    if (m.role == 'user' && m.content.trim().isNotEmpty) {
      userIndices.add(i);
    }
  }
  if (userIndices.isEmpty) return const <ChatMessage>[];
  if (userIndices.length <= keepUserMessages) return List.of(messages);
  return messages.sublist(userIndices[userIndices.length - keepUserMessages]);
}

/// Number of user messages in a collapsed list (role 'user', non-empty
/// content) — the count that [selectKeepRecentMessages] counts against.
int countUserMessages(List<ChatMessage> messages) {
  return messages
      .where((m) => m.role == 'user' && m.content.trim().isNotEmpty)
      .length;
}

/// Default keep count for the keep-recent mode, scaling with conversation
/// size (<5 user messages → 1, <10 → 2, ≥10 → 3) so a small conversation's
/// default never covers all of its user messages.
int defaultKeepUserMessageCountFor(int userMessageCount) {
  if (userMessageCount < 5) return 1;
  if (userMessageCount < 10) return 2;
  return 3;
}

class CompressionTokenEstimate {
  const CompressionTokenEstimate({
    required this.totalTokens,
    required this.keptTokens,
    required this.minResultTokens,
    required this.maxResultTokens,
  });

  final int totalTokens;
  final int keptTokens;
  final int minResultTokens;
  final int maxResultTokens;
}

bool _isCjkRune(int rune) {
  return (rune >= 0x2E80 && rune <= 0x9FFF) ||
      (rune >= 0xF900 && rune <= 0xFAFF) ||
      (rune >= 0xFF00 && rune <= 0xFFEF);
}

int _estimateCharsToTokens(String text) {
  var cjk = 0;
  var other = 0;
  for (final rune in text.runes) {
    if (_isCjkRune(rune)) {
      cjk++;
    } else {
      other++;
    }
  }
  return (cjk / 1.6 + other / 4).round();
}

/// Estimate the token budget of a keep-recent compression result.
///
/// Assumptions (documented in CONTEXT.md): kept tokens = totalTokens ×
/// (kept chars / total chars) — length ratio equals token ratio; the
/// summarized-away part is estimated at 10%–30% of its own tokens, exposed
/// as a [minResultTokens]–[maxResultTokens] band.
CompressionTokenEstimate estimateCompressionTokens({
  required String totalText,
  required String keptText,
}) {
  final totalTokens = _estimateCharsToTokens(totalText);
  final totalChars = totalText.length;
  if (totalChars == 0) {
    return const CompressionTokenEstimate(
      totalTokens: 0,
      keptTokens: 0,
      minResultTokens: 0,
      maxResultTokens: 0,
    );
  }
  final keptTokens = (totalTokens * keptText.length / totalChars).round();
  final oldTokens = totalTokens - keptTokens;
  return CompressionTokenEstimate(
    totalTokens: totalTokens,
    keptTokens: keptTokens,
    minResultTokens: keptTokens + (oldTokens * 0.10).round(),
    maxResultTokens: keptTokens + (oldTokens * 0.30).round(),
  );
}
