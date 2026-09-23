# Shared item art

`art_id` identifies an item image and `art_variant` selects a variant (`default` when omitted). Inventory cards, comparison/detail, Vault, Forge, world drops and rare-loot notices share `ItemArt.texture()` and preserve the image aspect ratio.

Install reviewed PNG/WebP/SVG files:

```sh
python tools/import_item_art.py my_sword.webp legend_ash_edge
python tools/import_item_art.py frosted_sword.webp legend_ash_edge --variant frost
```

The importer writes `manifest.json` and a stable filename; existing art requires `--replace`. PNG/WebP dimensions are limited to 16–1024 pixels and files to 4 MiB. SVG must be self-contained. Commit the source and manifest, then let Godot import normally. No code change is needed. `example_sword` is a pipeline example using the existing sword icon, not final item artwork.

Resolution: manifest variant → manifest default → `<art_id>_<variant>.<extension>` → `<art_id>.<extension>` → uniform weapon/armor/accessory placeholder. Unknown or malformed IDs never escape the art directory. Caches are bounded to 96 textures. Use `ItemArt.clear()` after changing assets in a running editor session.

Prefer square transparent images at 256 or 512 pixels, with the silhouette inside an 80% safe area. Rarity frames, Mythic corners, loot beams and sound are supplied by the game and should not be baked into images. Full bespoke artwork can be added incrementally without altering saves.
