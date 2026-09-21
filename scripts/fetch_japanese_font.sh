#!/usr/bin/env bash
set -euo pipefail
# The subset is bundled for offline/native/Web builds. Do not replace it with
# the old upstream subset: that font omits several 0.3 weapon/oath glyphs.
DEST="assets/fonts/NotoSansJP-Regular.subset.ttf"
EXTRA="assets/fonts/NotoSansJP-Extra.ttf"
EXPECTED_SHA256="631e3b9873fb83ca5b4572991b7ceebe8189bd05914ae1340b2d7257b0d35e1e"
EXPECTED_EXTRA_SHA256="4654a566b8b8d6026cc3ca26c6db212017a9bf1d1865f5848558c33b5c9f30c1"
for file in "$DEST" "$EXTRA"; do
  if [ ! -s "$file" ]; then
    echo "Bundled Japanese font missing. Restore $file from this repository." >&2
    exit 1
  fi
done
actual="$(sha256sum "$DEST" | cut -d ' ' -f 1)"
extra_actual="$(sha256sum "$EXTRA" | cut -d ' ' -f 1)"
if [ "$actual" != "$EXPECTED_SHA256" ]; then
  echo "Japanese base subset changed. Verify glyph coverage and update its pinned hash." >&2
  exit 1
fi
if [ "$extra_actual" != "$EXPECTED_EXTRA_SHA256" ]; then
  echo "Japanese supplemental subset changed. Regenerate it from scripts/japanese_extra_chars.txt and update its pinned hash." >&2
  exit 1
fi
