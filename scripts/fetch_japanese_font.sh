#!/usr/bin/env bash
set -euo pipefail
# The subset is bundled for offline/native/Web builds. Do not replace it with
# the old upstream subset: that font omits several 0.3 weapon/oath glyphs.
DEST="assets/fonts/NotoSansJP-Regular.subset.ttf"
EXPECTED_SHA256="631e3b9873fb83ca5b4572991b7ceebe8189bd05914ae1340b2d7257b0d35e1e"
if [ ! -s "$DEST" ]; then
  echo "Bundled Japanese font missing. Restore $DEST from this repository." >&2
  exit 1
fi
actual="$(sha256sum "$DEST" | cut -d ' ' -f 1)"
if [ "$actual" != "$EXPECTED_SHA256" ]; then
  echo "Japanese subset changed. Verify glyph coverage and update its pinned hash." >&2
  exit 1
fi
