# ASHEN VOW repository instructions

This repository is a Godot 4.5.1 hack-and-slash game. Preserve the existing fast combat feel, three-weapon chain core, save compatibility, Japanese UI, Web export, and iPad/touch support.

Do not use subagents or spawn parallel worker agents. Complete the work in the primary agent session.

For any task involving character art, item art, icons, backgrounds, VFX, animation/motion, BGM, or sound effects, read and follow `.codex/skills/ashen-vow-asset-studio/SKILL.md` before editing assets.

For broad continuation requests such as `続けて`, `次へ`, or requests to proceed with the next implementation phase, read `docs/AI_ASSET_ROADMAP.md` and follow its phase-progression protocol. Inspect current `main`, open PRs, and `assets/ai/asset_backlog.json` before deciding what remains. Continue the earliest incomplete phase unless the user explicitly requests a different feature or phase. When a phase is completed, update the roadmap's Current position and the asset backlog in the same PR.

Asset work is not complete when a file merely exists. Integrate it into the game, run the relevant automated tests, render or play the affected scene, inspect the result, fix regressions, verify Web/touch behavior when relevant, and create a PR with the validation results.

Generated visual/audio assets must be original for this project. Do not copy identifiable third-party game assets, music, logos, or characters. Keep generated source/specification files when useful for iteration. Do not bake rarity frames, loot beams, or UI chrome into item artwork; the game adds those at runtime.

Prefer reversible, data-driven asset integration. Preserve stable item `art_id` values and save identities. New reviewed item art should use `tools/import_item_art.py` rather than ad-hoc filename changes.
