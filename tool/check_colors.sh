#!/bin/bash
# Gate: list hardcoded colors outside theme definitions, whitelist and Colors.transparent.
# Should print nothing when the codebase is fully theme-driven.
# Per-line exemption: add `// color-gate: ignore` (with a reason) on the line.
cd "$(dirname "$0")/.." || exit 1
grep -rEn 'Color\(0x|Colors\.' lib --include='*.dart' \
  | grep -v '^lib/theme/' \
  | grep -v 'Colors\.transparent' \
  | grep -vFf tool/color_whitelist.txt \
  | grep -Ev '[a-zA-Z]Colors\.' \
  | grep -v 'appColors\.' \
  | grep -v 'color-gate: ignore'
