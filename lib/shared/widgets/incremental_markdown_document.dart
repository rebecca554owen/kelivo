/// A stable source block in an append-only streaming Markdown document.
final class IncrementalMarkdownBlock {
  const IncrementalMarkdownBlock({required this.start, required this.text});

  final int start;

  /// The block's source, the blank run that ends it included. The run holds
  /// nothing but line breaks — a run carrying whitespace is never a boundary —
  /// so a whole-document render lays it out as exactly one blank line.
  final String text;
}

/// Splits streaming Markdown at safe blank-line boundaries and only rescans
/// the last (possibly incomplete) block when content is appended.
final class IncrementalMarkdownDocument {
  static final _listMarker = RegExp(
    r'^(?:[*+-](?:\s+\[[ xX]\])?|\d{1,9}[.)])(?:\s|$)',
  );
  static final _detailsOpen = RegExp(r'<details\b', caseSensitive: false);
  static final _detailsClose = RegExp(r'</details>', caseSensitive: false);

  String _source = '';
  List<IncrementalMarkdownBlock> _blocks = const [];
  final List<IncrementalMarkdownBlock> _stableBlocks = [];
  int _rescannedCodeUnits = 0;
  int _scanCursor = 0;
  int _lineStart = 0;
  int _blockStart = 0;
  String? _fence;
  String? _math;
  int _detailsDepth = 0;
  int? _pendingListBlankEnd;
  bool _blankRunCarriesWhitespace = false;

  List<IncrementalMarkdownBlock> get blocks => _blocks;
  int get rescannedCodeUnits => _rescannedCodeUnits;

  List<IncrementalMarkdownBlock> update(String source) {
    if (source == _source) return _blocks;
    if (!source.startsWith(_source)) {
      _stableBlocks.clear();
      _scanCursor = 0;
      _lineStart = 0;
      _blockStart = 0;
      _fence = null;
      _math = null;
      _detailsDepth = 0;
      _pendingListBlankEnd = null;
      _blankRunCarriesWhitespace = false;
      _rescannedCodeUnits += source.length;
    } else {
      _rescannedCodeUnits += source.length - _source.length;
    }
    _source = source;
    _scanCompletedLines();
    final tailText = source.substring(_blockStart);
    // A tail of nothing but whitespace — the reply pausing on a paragraph break
    // — is not a block: a whole-document render trims the end of the document,
    // so there is nothing there to lay out.
    _blocks = List<IncrementalMarkdownBlock>.unmodifiable([
      ..._stableBlocks,
      if (tailText.trim().isNotEmpty)
        IncrementalMarkdownBlock(start: _blockStart, text: tailText),
    ]);
    return _blocks;
  }

  void _scanCompletedLines() {
    while (_scanCursor < _source.length) {
      final newline = _source.indexOf('\n', _scanCursor);
      if (newline < 0) {
        _scanCursor = _source.length;
        return;
      }
      final rawLine = _source.substring(_lineStart, newline);
      final line = rawLine.trimLeft();
      _updateFence(line);
      if (_fence == null) {
        if (_math == null) _updateDetails(line);
        if (_detailsDepth == 0) _updateMath(line);
      }
      final protected = _fence != null || _math != null || _detailsDepth > 0;
      final isBlank = line.trim().isEmpty;
      if (!protected && isBlank) {
        final end = newline + 1;
        if (_hasWhitespaceContent(rawLine)) _blankRunCarriesWhitespace = true;
        if (_blankRunCarriesWhitespace) {
          // A blank line carrying whitespace is content to the renderers around
          // it: a rule, a heading and a display-math block each absorb it into
          // their own match, and plain text lays it out as a line of its own.
          // Rather than model all of that, refuse the boundary and leave the
          // run inside one block, which renders the way the document reads.
          _pendingListBlankEnd = null;
          if (_lineStart == _blockStart) _mergeLastBlockBack();
        } else if (_lineStart > _blockStart) {
          if (_currentBlockIsList()) {
            _pendingListBlankEnd = end;
          } else if (_endsOnCrossLineHeadingClose()) {
            // The hashes closing this heading sit on a line of their own from
            // the ones opening it, and a whole-document render reads the next
            // line of hashes as part of the same heading, across the blank line.
            // Keep the region in one block so the renderer sees it whole.
            _pendingListBlankEnd = null;
          } else {
            _emitStableBlock(end);
          }
        } else {
          // A blank line with no content behind it continues the run that ended
          // the block before it, which is one gap in a whole-document render,
          // not a block of its own.
          _extendLastBlock(end);
        }
      } else if (!protected && !isBlank) {
        _blankRunCarriesWhitespace = false;
        if (_pendingListBlankEnd != null) {
          if (_isListContinuation(rawLine, line)) {
            _pendingListBlankEnd = null;
          } else {
            _emitStableBlock(_pendingListBlankEnd!);
            _pendingListBlankEnd = null;
          }
        } else if (_lineStart == _blockStart &&
            (_isIndented(rawLine) || _isBareHashRun(line))) {
          // Indentation is part of the syntax — four spaces stop a heading from
          // being one — and a block-by-block render trims the leading
          // whitespace off every block. A bare run of hashes is worse: a
          // whole-document render reads it as the closing hashes of the heading
          // before it, across the blank line. Keep either with the block above
          // so both reach the renderer the way they read in the document.
          _mergeLastBlockBack();
        }
      }
      _lineStart = newline + 1;
      _scanCursor = newline + 1;
    }
  }

  void _emitStableBlock(int end) {
    _stableBlocks.add(
      IncrementalMarkdownBlock(
        start: _blockStart,
        text: _source.substring(_blockStart, end),
      ),
    );
    _blockStart = end;
  }

  /// Grows the last block's blank run out to [end].
  void _extendLastBlock(int end) {
    if (_stableBlocks.isEmpty) {
      // Nothing but blank lines so far: leave them out of the first block, the
      // way both render paths trim the head of the document.
      _blockStart = end;
      return;
    }
    final last = _stableBlocks.removeLast();
    _stableBlocks.add(
      IncrementalMarkdownBlock(
        start: last.start,
        text: _source.substring(last.start, end),
      ),
    );
    _blockStart = end;
  }

  /// Reopens the last block so the line just scanned joins it.
  void _mergeLastBlockBack() {
    if (_stableBlocks.isEmpty) return;
    _blockStart = _stableBlocks.removeLast().start;
  }

  static bool _isIndented(String rawLine) =>
      rawLine.isNotEmpty && _isWhitespace(rawLine.codeUnitAt(0));

  /// Whether a blank [rawLine] carries whitespace rather than only the line
  /// breaks a source can leave behind, a lone CR among them.
  static bool _hasWhitespaceContent(String rawLine) {
    for (var i = 0; i < rawLine.length; i++) {
      final unit = rawLine.codeUnitAt(i);
      if (unit != 0x0A && unit != 0x0D && unit != 0x2028 && unit != 0x2029) {
        return true;
      }
    }
    return false;
  }

  /// Whether the block ends on a line that closes an ATX heading with hashes
  /// without opening one, which means the hashes opening it are on an earlier
  /// line — the one spelling a whole-document render can carry across a blank
  /// line into the heading that follows.
  bool _endsOnCrossLineHeadingClose() {
    var end = _lineStart;
    while (end > _blockStart && _isWhitespace(_source.codeUnitAt(end - 1))) {
      end--;
    }
    if (end == _blockStart || _source.codeUnitAt(end - 1) != 0x23) return false;
    var lineStart = end;
    while (lineStart > _blockStart &&
        !_isLineBreakUnit(_source.codeUnitAt(lineStart - 1))) {
      lineStart--;
    }
    var first = lineStart;
    while (first < end && _isWhitespace(_source.codeUnitAt(first))) {
      first++;
    }
    return first < end && _source.codeUnitAt(first) != 0x23;
  }

  static bool _isLineBreakUnit(int unit) =>
      unit == 0x0A || unit == 0x0D || unit == 0x2028 || unit == 0x2029;

  /// Whether [line] is a bare run of one to six hashes.
  static bool _isBareHashRun(String line) {
    final run = line.trimRight();
    if (run.isEmpty || run.length > 6) return false;
    for (var i = 0; i < run.length; i++) {
      if (run.codeUnitAt(i) != 0x23) return false;
    }
    return true;
  }

  static bool _isWhitespace(int unit) =>
      unit == 0x20 ||
      (unit >= 0x09 && unit <= 0x0D) ||
      (unit >= 0x80 && _isWideWhitespace(unit));

  static bool _isWideWhitespace(int unit) =>
      unit == 0x85 ||
      unit == 0xA0 ||
      unit == 0x1680 ||
      (unit >= 0x2000 && unit <= 0x200A) ||
      unit == 0x2028 ||
      unit == 0x2029 ||
      unit == 0x202F ||
      unit == 0x205F ||
      unit == 0x3000 ||
      unit == 0xFEFF;

  void _updateFence(String line) {
    final marker = line.startsWith('```')
        ? '```'
        : line.startsWith('~~~')
        ? '~~~'
        : null;
    if (marker == null) return;
    _fence = _fence == null
        ? marker
        : _fence == marker
        ? null
        : _fence;
  }

  void _updateMath(String line) {
    var i = 0;
    while (i < line.length) {
      if (line.codeUnitAt(i) == 0x60) {
        i = _advancePastInlineCodeOrBackticks(line, i);
        continue;
      }
      if (_math == r'$$') {
        if (_atDoubleDollar(line, i)) {
          _math = null;
          i += 2;
        } else {
          i++;
        }
        continue;
      }
      if (_math == r'\[') {
        if (_atEscaped(line, i, 0x5D)) {
          _math = null;
          i += 2;
        } else {
          i++;
        }
        continue;
      }
      if (_atDoubleDollar(line, i)) {
        _math = r'$$';
        i += 2;
        continue;
      }
      if (_atEscaped(line, i, 0x5B)) {
        _math = r'\[';
        i += 2;
        continue;
      }
      i++;
    }
  }

  void _updateDetails(String line) {
    if (_detailsOpen.matchAsPrefix(line) == null &&
        _detailsClose.matchAsPrefix(line) == null) {
      return;
    }
    var i = 0;
    while (i < line.length) {
      if (line.codeUnitAt(i) == 0x60) {
        i = _advancePastInlineCodeOrBackticks(line, i);
        continue;
      }
      if (line.codeUnitAt(i) != 0x3C) {
        i++;
        continue;
      }
      final open = _detailsOpen.matchAsPrefix(line, i);
      if (open != null) {
        _detailsDepth++;
        i = open.end;
        continue;
      }
      final close = _detailsClose.matchAsPrefix(line, i);
      if (close != null) {
        if (_detailsDepth > 0) _detailsDepth--;
        i = close.end;
        continue;
      }
      i++;
    }
  }

  int _advancePastInlineCodeOrBackticks(String line, int start) {
    var n = 0;
    while (start + n < line.length && line.codeUnitAt(start + n) == 0x60) {
      n++;
    }
    var i = start + n;
    while (i < line.length) {
      if (line.codeUnitAt(i) != 0x60) {
        i++;
        continue;
      }
      var m = 0;
      while (i + m < line.length && line.codeUnitAt(i + m) == 0x60) {
        m++;
      }
      if (m == n) return i + m;
      i += m;
    }
    return start + n;
  }

  bool _atDoubleDollar(String line, int i) {
    return i + 1 < line.length &&
        line.codeUnitAt(i) == 0x24 &&
        line.codeUnitAt(i + 1) == 0x24;
  }

  bool _atEscaped(String line, int i, int unit) {
    return i + 1 < line.length &&
        line.codeUnitAt(i) == 0x5C &&
        line.codeUnitAt(i + 1) == unit;
  }

  bool _currentBlockIsList() {
    var i = _blockStart;
    while (i < _source.length) {
      final nl = _source.indexOf('\n', i);
      final end = nl < 0 ? _source.length : nl;
      final raw = _source.substring(i, end);
      if (raw.trim().isNotEmpty) {
        return _listMarker.hasMatch(raw.trimLeft());
      }
      if (nl < 0) break;
      i = nl + 1;
    }
    return false;
  }

  bool _isListContinuation(String rawLine, String trimmedLeft) {
    if (rawLine.isNotEmpty &&
        (rawLine.codeUnitAt(0) == 0x20 || rawLine.codeUnitAt(0) == 0x09)) {
      return true;
    }
    return _listMarker.hasMatch(trimmedLeft);
  }
}
