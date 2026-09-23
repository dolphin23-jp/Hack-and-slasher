---
name: ashen-vow-asset-studio
description: Create, replace, integrate, and validate ASHEN VOW game assets including character art, item art, icons, VFX, motion, BGM, and SFX. Use whenever a task changes the game's visual or audio presentation.
---

# ASHEN VOW Asset Studio

Work as the primary agent only. Do not spawn subagents.

## Goal

Turn an asset request into a finished in-game result, not a loose concept file. The required loop is:

1. Inspect current `main`, open PRs, the relevant game code, and `assets/ai/asset_backlog.json`.
2. Decide the smallest asset change that improves the game without weakening the current fast combat feel or three-weapon-chain readability.
3. Create the asset using AI-assisted generation.
4. Normalize and integrate it into Godot.
5. Run automated tests and a rendered visual pass.
6. Play the affected flow when practical.
7. Verify Web/iPad behavior for UI or runtime-facing changes.
8. Fix issues found in the rendered/gameplay pass.
9. Update the asset backlog/provenance entry and open a PR with concrete validation results.

Never stop at a prompt, TODO, mockup, or unreferenced asset.

## Visual generation

Prefer Codex's image-generation skill powered by GPT Image when available for raster concept/final art. Iterate from screenshots or generated references when consistency needs improvement. Use transparent backgrounds for isolated items, weapons, icons, and character components unless the scene specifically needs a background.

If image generation is unavailable, create original SVG/vector art directly in the repository and continue the integration instead of blocking.

Read `references/art-direction.md` before generating visual assets.

### Item art

The item-art pipeline already supports PNG, WebP, and SVG variants through `ItemArt`.

Use:

```sh
python tools/import_item_art.py <generated-file> <art_id>
python tools/import_item_art.py <generated-file> <art_id> --variant <variant>
```

Prefer square transparent 256px or 512px artwork with the silhouette inside an ~80% safe area. Do not bake rarity frames, Mythic corners, loot beams, labels, or stats into item art.

### Character/gameplay art

Current character assets live in `assets/characters/`. The player renderer depends on the existing 128x128 atlas convention: the upper body uses the top region and the two legs use the lower split regions. Do not replace `player.svg` with an incompatible full-body pose without changing and validating the renderer at the same time.

Enemy textures are drawn as whole textures, so silhouettes must remain readable at small top-down sizes. Bosses need a clearly distinct outer silhouette and phase-2 effects must remain readable over the base art.

When richer raster art is introduced, update the loader deliberately rather than silently breaking hard-coded SVG paths. Keep a safe fallback asset.

### Weapon/VFX readability

The seven weapon families must remain visually distinguishable at combat speed:

- sword: compact slash arc
- scythe: broad circular sweep
- spear: long thrust/line
- staff: straight magic projection
- fist: short rapid impact
- mace: heavy wide impact
- spellblade: hybrid slash + magic accent

Do not replace clear telegraphs with decorative effects. Preserve bounded VFX allocation and effect lifetimes.

## Motion and animation

Read `references/audio-motion.md` before changing motion.

Prefer motion that is data-driven or easy to tune. Preserve dodge canceling and avoid long recovery locks. Attack animation must communicate weapon direction, reach, timing, and impact without delaying gameplay responsiveness.

For sprite animation, keep a stable reference character and generate a coherent sequence from that reference rather than independently prompting every frame. For procedural Godot motion, edit the motion parameters/code, then validate with rendered captures.

## BGM and SFX

Use an available audio-generation tool when one is connected and can produce original game-ready audio. Otherwise, have the primary agent compose and synthesize original audio through repository Python tooling; `tools/create_assets.py` and `tools/create_expansion_audio.py` are valid deterministic fallbacks and may be extended.

Output game audio as WAV unless the runtime loader is changed and tested. Keep loops seamless. Music must support gameplay rather than dominate it; SFX must preserve attack timing cues.

For new music, define at minimum: gameplay context, BPM/rhythmic density, tonal center/palette, loop length, intensity curve, and transition behavior. For SFX, define transient, body, tail, and intended gameplay event.

## Validation

At minimum, run the closest relevant existing tests. For visual/item/VFX changes include Phase 6 tests and rendered captures. For broad changes also run campaign and Web smoke checks used by CI.

Useful commands in the existing CI environment include:

```sh
godot --headless --path . --script res://tests/phase6_runner.gd -- --test
xvfb-run -a godot --audio-driver Dummy --path . --script res://tests/phase6_visual.gd -- --test
godot --headless --path . -- --test --campaign
```

Use the repository's actual Godot binary path/CI invocation when it differs from these examples.

Inspect screenshots, not only exit codes. Specifically check silhouettes, overlap, text legibility, clipping, touch targets, contrast against the cathedral floor, VFX clutter, and whether weapon-chain states can still be read during movement.

## Asset bookkeeping

Update `assets/ai/asset_backlog.json` for every completed/replaced target. Record the final repository path, generation method, status, and a short note about what was validated. Do not store secrets, API keys, or private prompt data in the repository.

A task is complete only when the new asset is used by the game and the relevant tests/rendered checks pass.
