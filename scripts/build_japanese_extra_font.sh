#!/usr/bin/env bash
set -euo pipefail

# Regenerate the small supplemental Japanese font used by the 0.3 UI.
# Requires: curl, Python, and fonttools (pyftsubset).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="/tmp/NotoSansJP.ttf"
DEST="$ROOT/assets/fonts/NotoSansJP-Extra.ttf"
CHARS="$ROOT/scripts/japanese_extra_chars.txt"

python -m pip install --disable-pip-version-check fonttools
curl -L --fail --retry 3 -o "$SOURCE"   'https://raw.githubusercontent.com/google/fonts/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf'

pyftsubset "$SOURCE"   --text-file="$CHARS"   --output-file="$DEST"   --layout-features='*'   --name-IDs='*'   --name-legacy   --name-languages='*'

sha256sum "$DEST"
ls -lh "$DEST"
