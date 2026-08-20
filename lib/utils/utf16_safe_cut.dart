/// Surrogate-safe UTF-16 cut helpers.
///
/// Truncating a Dart `String` with a plain `substring` can split a UTF-16
/// surrogate pair, leaving a lone high/low surrogate behind. A lone surrogate
/// cannot be serialized by `jsonEncode` (and breaks any UTF-8/JSON boundary),
/// so every cross-process truncation site in this repo uses these helpers
/// instead of raw `substring`.
library;

/// Returns an end index suitable for `value.substring(0, result)` that never
/// ends on the middle of a UTF-16 surrogate pair. When [end] falls exactly
/// between a high surrogate (at `end - 1`) and its low surrogate (at `end`),
/// the cut moves one code unit back so the whole pair is dropped from the
/// head instead of being torn.
int utf16SafeHeadEnd(String value, int end) {
  if (end <= 0 || end >= value.length) return end;
  final prev = value.codeUnitAt(end - 1);
  final cur = value.codeUnitAt(end);
  if (!_isHighSurrogate(prev) || !_isLowSurrogate(cur)) return end;
  return end - 1;
}

/// Returns a start index suitable for `value.substring(result)` that never
/// starts on the middle of a UTF-16 surrogate pair. When [start] falls
/// exactly between a high surrogate (at `start - 1`) and its low surrogate
/// (at `start`), the cut moves one code unit forward so the whole pair is
/// dropped from the tail instead of being torn.
int utf16SafeTailStart(String value, int start) {
  if (start <= 0 || start >= value.length) return start;
  final prev = value.codeUnitAt(start - 1);
  final cur = value.codeUnitAt(start);
  if (!_isHighSurrogate(prev) || !_isLowSurrogate(cur)) return start;
  return start + 1;
}

/// Truncates [value] to at most [maxLength] code units, keeping the head.
/// A UTF-16 surrogate pair straddling the cut is dropped whole, never split.
String truncateHeadUtf16Safe(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return value.substring(0, utf16SafeHeadEnd(value, maxLength));
}

/// Bounds [value] to [maxLength] code units, keeping a head/tail preview
/// joined by [marker]. Cut points are adjusted so a UTF-16 surrogate pair is
/// never split; the output length stays at or below [maxLength].
String truncateHeadTailUtf16Safe(
  String value,
  int maxLength, {
  required String marker,
}) {
  if (value.length <= maxLength) return value;
  final available = maxLength - marker.length;
  if (available <= 0) return truncateHeadUtf16Safe(value, maxLength);
  final head = available ~/ 2;
  final tail = available - head;
  final headEnd = utf16SafeHeadEnd(value, head);
  final tailStart = utf16SafeTailStart(value, value.length - tail);
  return '${value.substring(0, headEnd)}$marker'
      '${value.substring(tailStart)}';
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
