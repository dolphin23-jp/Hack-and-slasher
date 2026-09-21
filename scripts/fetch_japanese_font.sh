#!/usr/bin/env bash
set -euo pipefail

DEST="assets/fonts/NotoSansJP-Regular.subset.ttf"
SOURCE="https://raw.githubusercontent.com/zakideee/boundsvg/67f22b683953035f4ecc7e8cc7cead595433dd4b/fixtures/fonts/NotoSansJP-Regular.subset.ttf"
EXPECTED_SIZE=1079300

mkdir -p "$(dirname "$DEST")"
if [ -s "$DEST" ] && [ "$(wc -c < "$DEST" | tr -d ' ')" = "$EXPECTED_SIZE" ]; then
  exit 0
fi

tmp="${DEST}.tmp"
rm -f "$tmp"
curl -L --fail --retry 3 --retry-delay 1 -o "$tmp" "$SOURCE"
actual="$(wc -c < "$tmp" | tr -d ' ')"
if [ "$actual" != "$EXPECTED_SIZE" ]; then
  echo "Unexpected Japanese font size: $actual (expected $EXPECTED_SIZE)" >&2
  rm -f "$tmp"
  exit 1
fi
mv "$tmp" "$DEST"
