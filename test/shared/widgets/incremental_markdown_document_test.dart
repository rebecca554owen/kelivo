import 'package:Kelivo/shared/widgets/incremental_markdown_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('append-only updates retain completed block identities', () {
    final document = IncrementalMarkdownDocument();
    final initial = document.update('first paragraph\n\nsecond');
    final firstBlock = initial.first;

    final updated = document.update('first paragraph\n\nsecond grows');

    expect(identical(updated.first, firstBlock), isTrue);
    expect(updated.last.text, 'second grows');
  });

  test('blank lines inside fences do not split source blocks', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update('before\n\n```dart\na\n\nb\n```\n\nafter');

    expect(blocks, hasLength(3));
    expect(blocks[1].text, contains('a\n\nb'));
  });

  test('blank lines inside display math do not split source blocks', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update(
      'before\n\n\$\$\na + b\n\nc + d\n\$\$\n\nafter',
    );

    expect(blocks, hasLength(3));
    expect(blocks[1].text, contains('a + b\n\nc + d'));
    expect(blocks[1].text, contains('\$\$'));
  });

  test(
    'blank lines inside bracket display math do not split source blocks',
    () {
      final document = IncrementalMarkdownDocument();
      final blocks = document.update(
        'before\n\n\\[\na + b\n\nc + d\n\\]\n\nafter',
      );

      expect(blocks, hasLength(3));
      expect(blocks[1].text, contains('a + b\n\nc + d'));
    },
  );

  test('blank lines inside details html do not split source blocks', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update(
      'before\n\n<details>\n<summary>s</summary>\n\nbody\n\n</details>\n\nafter',
    );

    expect(blocks, hasLength(3));
    expect(blocks[1].text, contains('body'));
    expect(blocks[1].text, contains('</details>'));
  });

  test('blank lines inside a loose list do not split source blocks', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update('- first\n\n- second\n\nnext paragraph\n');

    expect(blocks, hasLength(2));
    expect(blocks.first.text, contains('- first\n\n- second'));
    expect(blocks.last.text, 'next paragraph\n');
  });

  test('indented list continuation stays in the same source block', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update('- item\n\n  still the item\n\nnext\n');

    expect(blocks, hasLength(2));
    expect(blocks.first.text, contains('still the item'));
    expect(blocks.last.text, 'next\n');
  });

  test('single-line display math does not swallow the next paragraph', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update('\$\$ a + b \$\$\n\nnext');

    expect(blocks, hasLength(2));
    expect(blocks.first.text, '\$\$ a + b \$\$\n\n');
    expect(blocks.last.text, 'next');
  });

  test('mid-paragraph display math keeps blank lines in the same block', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update('说明文字 \$\$\na + b\n\nc + d\n\$\$\n\nafter');

    expect(blocks, hasLength(2));
    expect(blocks.first.text, contains('说明文字'));
    expect(blocks.first.text, contains('a + b\n\nc + d'));
    expect(blocks.last.text, 'after');
  });

  test(
    'mid-paragraph bracket display math keeps blank lines in the same block',
    () {
      final document = IncrementalMarkdownDocument();
      final blocks = document.update('说明文字 \\[\na + b\n\nc + d\n\\]\n\nafter');

      expect(blocks, hasLength(2));
      expect(blocks.first.text, contains('a + b\n\nc + d'));
      expect(blocks.last.text, 'after');
    },
  );

  test('list-item display math keeps blank lines in the same block', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update(
      '- see \$\$\na + b\n\nc + d\n\$\$\n\nafter\n',
    );

    expect(blocks, hasLength(2));
    expect(blocks.first.text, contains('- see'));
    expect(blocks.first.text, contains('a + b\n\nc + d'));
    expect(blocks.last.text, 'after\n');
  });

  test('inline code dollars do not start display math protection', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update(
      'Use `\$\$` as currency.\n\nFirst paragraph.\n\nSecond paragraph.',
    );

    expect(blocks, hasLength(3));
    expect(blocks[1].text, startsWith('First paragraph.'));
    expect(blocks.last.text, 'Second paragraph.');
  });

  test(
    'closed display math on a line can still open a later bracket block',
    () {
      final document = IncrementalMarkdownDocument();
      final blocks = document.update(
        'text \$\$ a \$\$ \\[\nb\n\nc\n\\]\n\nafter',
      );

      expect(blocks, hasLength(2));
      expect(blocks.first.text, contains('b\n\nc'));
      expect(blocks.last.text, 'after');
    },
  );

  test('inline code details tags do not freeze later paragraph splits', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update(
      'Use `<details>` to create a collapsible section.\n\n'
      'First paragraph.\n\n'
      'Second paragraph.',
    );

    expect(blocks, hasLength(3));
    expect(blocks[1].text, startsWith('First paragraph.'));
    expect(blocks.last.text, 'Second paragraph.');
  });

  test('prose details mention does not freeze later paragraph splits', () {
    final document = IncrementalMarkdownDocument();
    final blocks = document.update(
      'Use <details> to create a collapsible section.\n\n'
      'First paragraph.\n\n'
      'Second paragraph.',
    );

    expect(blocks, hasLength(3));
  });

  test(
    'inline details tags inside a details summary do not freeze later splits',
    () {
      final document = IncrementalMarkdownDocument();
      final blocks = document.update(
        '<details><summary>Use `<details>`</summary>\n\n'
        'body\n'
        '</details>\n\n'
        'after',
      );

      expect(blocks, hasLength(2));
      expect(blocks.first.text, contains('</details>'));
      expect(blocks.last.text, 'after');
    },
  );

  test('1 MiB append stream scans each source code unit once', () {
    final document = IncrementalMarkdownDocument();
    var source = '';
    final chunk = List<String>.filled(256, '0123456789abcdef').join();
    for (var index = 0; index < 256; index++) {
      source += chunk;
      document.update(source);
    }

    expect(source.length, 1 << 20);
    expect(document.rescannedCodeUnits, source.length);
    expect(document.blocks, hasLength(1));
  });
}
