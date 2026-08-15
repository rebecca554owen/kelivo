/// A stable source block in an append-only streaming Markdown document.
final class IncrementalMarkdownBlock {
  const IncrementalMarkdownBlock({
    required this.start,
    required this.text,
    this.isList = false,
  });

  final int start;
  final String text;

  /// Whether this block is a list. A whole-document render already ends a list
  /// with its own line break, so the caller must not add a separator after it.
  final bool isList;
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
      _rescannedCodeUnits += source.length;
    } else {
      _rescannedCodeUnits += source.length - _source.length;
    }
    _source = source;
    _scanCompletedLines();
    final tail = IncrementalMarkdownBlock(
      start: _blockStart,
      text: source.substring(_blockStart),
    );
    _blocks = List<IncrementalMarkdownBlock>.unmodifiable([
      ..._stableBlocks,
      tail,
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
      if (!protected && isBlank && _lineStart > _blockStart) {
        final end = newline + 1;
        if (_currentBlockIsList()) {
          _pendingListBlankEnd = end;
        } else {
          _emitStableBlock(end);
        }
      } else if (!protected && !isBlank && _pendingListBlankEnd != null) {
        if (_isListContinuation(rawLine, line)) {
          _pendingListBlankEnd = null;
        } else {
          _emitStableBlock(_pendingListBlankEnd!);
          _pendingListBlankEnd = null;
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
        isList: _currentBlockIsList(),
      ),
    );
    _blockStart = end;
  }

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
