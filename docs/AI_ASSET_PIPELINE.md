# AI Asset Production Pipeline

ASHEN VOW can now treat art, motion, BGM, and SFX as first-class Codex production tasks instead of manual files added after programming.

The repository-level instructions are in `AGENTS.md`. The detailed asset workflow is implemented as the repo-local Codex skill at `.codex/skills/ashen-vow-asset-studio/SKILL.md` with dedicated art and audio/motion references.

## What a normal asset request should mean

A request such as:

> 新ボス「灰玻璃の司祭」を追加。見た目、攻撃モーション、VFX、BGM、SEまでAIで作成し、ゲームへ統合してテストまで行う。

should be interpreted as a complete production task:

1. inspect current main/open PRs and affected systems;
2. read the ASHEN VOW asset skill and references;
3. design the asset around current gameplay constraints;
4. generate original art/audio or use the repository fallback generators;
5. normalize and place files under the correct asset directory;
6. wire them into Godot/runtime data;
7. run automated gameplay and visual checks;
8. render/play the affected flow and inspect the result;
9. verify Web/iPad/touch behavior when relevant;
10. update `assets/ai/asset_backlog.json`;
11. create a PR containing the implementation and validation results.

A generated PNG/WAV that is not used by the game is not considered complete.

## Visual assets

For item art, use the existing shared ItemArt pipeline rather than adding one-off loader logic:

```sh
python tools/import_item_art.py generated_weapon.webp legend_some_effect
python tools/import_item_art.py generated_weapon_alt.webp legend_some_effect --variant awakened
```

The importer updates `assets/items/manifest.json`. Item save identity remains independent from the image file, so visual iteration does not need to invalidate existing saves.

For characters, inspect the renderer before replacement. In particular, the player currently uses a 128x128 atlas contract with upper and lower body regions, while enemies use whole textures. A richer AI-generated player image therefore needs either an atlas-compatible deliverable or a renderer/animation migration in the same PR.

For environment/background art, avoid flattening navigation and telegraph information into a decorative image. Floor hazards, paths, enemy attacks, and the player silhouette take priority over detail.

## Image generation strategy

When Codex image generation is available, prefer it for raster concept/final art and iterative edits. Create a stable approved reference for recurring characters before producing multiple poses or frames. Keep isolated item/character components transparent.

If image generation is unavailable in the current environment, the task should not stop: create original SVG/vector fallback art, integrate and validate it, and leave the target clearly represented in the backlog for a later raster polish pass.

Do not copy existing game assets or ask for close imitation of a named commercial game's visual style. Use the project's own art-direction description.

## Motion

Motion can be produced either as generated sprite animation or as procedural Godot animation. The current game already has procedural differentiation for the seven weapon families, so a sprite-animation migration should only be made when it improves readability without reducing responsiveness.

Normal attacks should remain fast and dodge-cancel friendly. Validate motion against actual damage/VFX timing and test full three-weapon chains rather than viewing an animation in isolation.

## BGM and SFX

The current `Soundscape` contract loads WAV files. Generated audio should therefore remain WAV until the loader is deliberately changed and Web-export behavior is tested.

When an audio-generation tool is available, Codex can create original tracks/effects and integrate them. Without one, the repository can synthesize original audio deterministically in Python. Existing examples are:

- `tools/create_assets.py`
- `tools/create_expansion_audio.py`

This fallback keeps the game build reproducible and prevents art/audio work from depending on one external service.

For music, record context, BPM/rhythmic density, tonal center, timbre plan, loop length, intensity curve, and transition behavior. For SFX, design transient, body, and tail around the gameplay event.

## Backlog and provenance

`assets/ai/asset_backlog.json` is the source of truth for the production state of major visual/audio targets.

Status meanings:

- `baseline`: current usable asset exists but is still a candidate for AI production/polish;
- `planned`: target is identified but production work has not started;
- `generated`: candidate asset exists but is not yet fully integrated;
- `integrated`: used by the runtime but still awaiting final gameplay/render validation;
- `validated`: integrated and checked in its intended runtime context;
- `deferred`: intentionally postponed with an explanatory note.

Every asset task should update its entry with the final runtime path, generation method, status, and concise validation note. Do not store API keys, credentials, or private prompt material in the backlog.

Run the validator locally with:

```sh
python tools/validate_ai_assets.py
```

The GitHub workflow `.github/workflows/ai-asset-validation.yml` runs the same check without network calls or generation cost. CI validates bookkeeping and runtime paths; it never triggers paid image/audio generation automatically.

## Required validation for broad asset changes

Use the closest relevant tests plus the existing visual/gameplay suites. For visual/item/VFX changes the Phase 6 runners are the minimum useful baseline:

```sh
godot --headless --path . --script res://tests/phase6_runner.gd -- --test
xvfb-run -a godot --audio-driver Dummy --path . --script res://tests/phase6_visual.gd -- --test
godot --headless --path . -- --test --campaign
```

The actual CI Godot path may differ. For Web-facing changes, also run the repository Web build/runtime smoke flow.

Exit code alone is insufficient for visual work. Inspect rendered captures for silhouette, contrast, clipping, text legibility, touch targets, VFX clutter, and weapon-chain readability. Audio changes should be auditioned with gameplay SFX/music together and checked for loop seams/crossfade behavior.

## Recommended next production sequence

The pipeline itself does not force a visual rewrite all at once. A practical order is:

1. create a final player reference and compatible player art/animation contract;
2. create distinct final art for the three bosses rather than sharing one base texture;
3. replace the seven weapon/item families with coherent generated artwork;
4. expand enemy silhouettes while keeping role readability;
5. replace the main dungeon/boss music set as one coherent musical family;
6. rebuild combat SFX as a weapon-specific layered set;
7. add environment/background art after the combat silhouettes and telegraphs are stable.

This order gives visible quality improvements early without destabilizing combat or save data.
