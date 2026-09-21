"""Build the bundled Noto Sans JP subset from a supplied upstream variable font.
Source: https://github.com/google/fonts/tree/main/ofl/notosansjp (SIL OFL).
Usage: python tools/build_japanese_subset.py /path/to/NotoSansJP[wght].ttf
Requires fonttools; the built font is committed so normal builds remain offline.
"""
from pathlib import Path
import sys
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
root = Path(__file__).resolve().parent.parent
chars = set(chr(i) for i in range(32, 127))
for directory in ('actors', 'data', 'scripts', 'systems', 'ui', 'world', 'tests'):
    for path in (root / directory).rglob('*'):
        if path.suffix in ('.gd', '.json'):
            chars.update(path.read_text())
font = TTFont(sys.argv[1])
if 'fvar' in font:
    font = instantiateVariableFont(font, {'wght': 400}, inplace=True)
options = subset.Options()
options.layout_features = ['*']
subsetter = subset.Subsetter(options=options)
subsetter.populate(unicodes=sorted(map(ord, chars)))
subsetter.subset(font)
font.save(root / 'assets/fonts/NotoSansJP-Regular.subset.ttf')
missing = sorted(c for c in chars if 0x3000 <= ord(c) <= 0x9fff and ord(c) not in font.getBestCmap())
if missing:
    raise SystemExit('Missing glyphs: ' + ''.join(missing))
print('Japanese glyph coverage complete')
