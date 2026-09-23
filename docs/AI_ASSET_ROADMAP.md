# ASHEN VOW — AI Asset Implementation Roadmap

This document is the canonical roadmap for the next implementation stages after the Phase 6 visual/item-art foundation. It is written for ChatGPT/Codex as an execution plan, not as a proposal document.

## Current position

- Phase 1–6: existing v0.3 implementation, gameplay systems, UI/equipment work, routes/encounters, shared ItemArt, weapon VFX and visual-regression foundation are already in `main`.
- AI asset production pipeline: installed in `main` via `AGENTS.md`, `.codex/skills/ashen-vow-asset-studio/`, `assets/ai/asset_backlog.json`, validation tooling and CI.
- **Current phase: Phase 7 — Player visual vertical slice.** The generated player atlas, seven strike motions, dodge/hit/death poses and iPad-proportion captures are implemented in the Phase 7 PR; Web/runtime CI and final review are the remaining completion gates. Phase 8 starts only after those gates pass.

The asset backlog is the source of truth for individual asset state. This roadmap is the source of truth for implementation order and phase completion.

## Rules that apply to every phase

At the start of every phase:

1. inspect the latest `main`, open PRs and recent merged work;
2. read `AGENTS.md`;
3. read `.codex/skills/ashen-vow-asset-studio/SKILL.md` and relevant references;
4. inspect `assets/ai/asset_backlog.json`;
5. inspect the actual runtime code and current rendered game before deciding implementation details.

Do not stop at planning, concept art, prompt writing, loose asset generation or TODOs. A phase is an implementation task and must proceed through:

**current-state inspection → design decision → asset generation/creation → Godot integration → automated tests → actual rendered/play inspection → fixes → Web/iPad/touch validation when relevant → backlog/roadmap update → PR → CI confirmation.**

Preserve throughout:

- the fast, dodge-cancel-friendly combat feel;
- the three-weapon chain as the combat core;
- Japanese UI and current equipment comparison flow;
- save compatibility and stable item identities;
- Web export and iPad/touch support;
- readable enemy telegraphs over decorative detail;
- bounded VFX/audio/runtime allocation;
- original project-specific art/audio rather than imitation of a named commercial game.

If a generation capability is unavailable, use the repo's fallback production method and still integrate/test the asset. Do not mark an asset `validated` merely because a file exists.

## Phase overview

| Phase | Theme | Main goal | Completion signal |
|---|---|---|---|
| 7 | Player visual vertical slice | Establish the final AI-art + motion production pattern on the player | Player is visually production-ready in normal play with all seven weapon families and dodge/hit states validated |
| 8 | Boss identity and presentation | Give each boss a unique visual identity, phase change and attack-language presentation | Forge, Thorn and final boss no longer depend on one shared visual identity and phase transitions are readable |
| 9 | Weapons, equipment and ItemArt | Make loot visually meaningful and consistent across world/UI | Seven weapon families and priority Legendary/Mythic items have coherent final art in loot, inventory, comparison and forge flows |
| 10 | Enemy roster and combat animation | Make enemy roles readable by silhouette and motion | Core enemy roles are visually distinct and attack tells remain readable under mixed encounters |
| 11 | BGM and combat sound | Replace placeholder/baseline audio with a coherent game-wide sound identity | Main music states and weapon/combat SFX form one coherent, loop-safe, Web-safe audio set |
| 12 | Cathedral environments and presentation polish | Raise world visual quality without harming gameplay readability | Main route, branches and boss arenas feel authored while hazards, loot and characters remain immediately readable |
| 13 | Full integration, performance and release-candidate QA | Validate the complete AI-asset pass as a playable product | Full campaign, Web/iPad/touch, save/load and visual/audio regressions pass with no high-priority baseline placeholder remaining |

---

# Phase 7 — Player visual vertical slice

## Purpose

Use the player as the first complete end-to-end AI asset production target. The goal is not only a better player sprite; it is to establish the production contract that later phases can reuse.

## Required work

- Inspect the current `actors/player.gd` drawing contract and the existing 128x128 upper/lower-body atlas behavior.
- Decide whether to preserve that atlas contract or migrate to a richer modular/sprite-sheet animation architecture. Choose based on runtime clarity, responsiveness and maintainability rather than asset-generation convenience.
- Establish a final player visual reference: silhouette, armor language, ash-crown/cathedral motifs, material palette and readable top-down proportions.
- Create final gameplay-ready player art with transparent backgrounds and safe framing.
- Implement motion for at least:
  - idle;
  - movement;
  - sword attack;
  - scythe spin;
  - spear thrust;
  - staff cast/thrust;
  - fist rapid strike;
  - mace heavy swing;
  - spellblade hybrid attack;
  - dodge;
  - hit reaction;
  - death or collapse state if currently represented in gameplay.
- Keep weapon-family differences obvious at gameplay zoom.
- Synchronize animation, hit timing and existing Phase 6 weapon VFX.
- Preserve immediate dodge cancel and current attack cadence unless an intentional gameplay improvement is independently justified and tested.
- Validate player readability against dark cathedral backgrounds, boss VFX and dense enemy packs.

## Done when

- The final player look is used in actual gameplay rather than only in a reference sheet.
- All seven weapon-family attacks can be identified visually without reading UI text.
- Attack/VFX timing remains aligned with damage timing.
- No obvious clipping, sprite-origin jitter, mirrored-weapon error or inconsistent scaling is visible.
- Full three-weapon chains have been played and visually reviewed.
- Phase 6 visual tests plus relevant campaign/Web tests pass.
- iPad-proportion capture and touch controls remain readable and unobstructed.
- Player-related backlog entries are updated to `validated` only after runtime inspection.

---

# Phase 8 — Boss identity and presentation

## Purpose

Turn the current bosses into distinct encounters visually, not merely different behaviors using a shared boss texture.

## Required work

Create unique gameplay art and presentation for:

- **炎冠の聖者 / Forge boss**
- **いばらの王 / Thorn boss**
- **鐘なき王 / final boss**

For each boss:

- create a unique base silhouette and material language;
- create a readable Phase 2 visual transformation rather than relying on tint alone;
- align major attack poses with existing telegraphs;
- give recovery/opening states clear visual language;
- keep arena hazards and attack gaps readable;
- add or refine boss-specific VFX only where it improves attack recognition;
- keep performance bounded during the most VFX-heavy phase transitions.

Do not change boss balance simply to fit an animation. The gameplay contract is authoritative unless testing shows a concrete UX problem.

## Done when

- A screenshot of each boss can be identified without its nameplate.
- Phase 1 and Phase 2 are visually distinguishable at gameplay zoom.
- Windup, danger and recovery states are readable during actual play.
- Boss art no longer depends on one shared final texture identity.
- Each full boss fight is completed in rendered testing.
- Web build and iPad-proportion captures show no clipping/performance regression.

---

# Phase 9 — Weapons, equipment and ItemArt

## Purpose

Make loot excitement visible. Equipment should communicate weapon family, rarity and identity before the player reads the stat block.

## Required work

- Produce coherent final art for all seven weapon families:
  - sword;
  - scythe;
  - spear;
  - staff;
  - fist;
  - mace;
  - spellblade.
- Preserve each family's silhouette language between held weapon, loot drop and inventory art.
- Use the existing shared `ItemArt` system and `tools/import_item_art.py` for reviewed item art.
- Prioritize bespoke art for Legendary/Mythic items and build-defining effects before generating every low-rarity permutation.
- Ensure art appears correctly in:
  - world drops;
  - rare-loot notice;
  - inventory cards;
  - selected-item detail;
  - equipped-vs-selected comparison;
  - Vault;
  - Forge;
  - any later equipment-management view that uses ItemArt.
- Keep rarity frame/beam/UI chrome runtime-driven; do not bake them into item art.
- Preserve stable `art_id` and save identity.

## Done when

- The seven families are distinguishable from their icons/art alone.
- Priority Legendary/Mythic items have bespoke art rather than generic family placeholders.
- Rectangular/square source art scales correctly without distortion.
- No item-art path or manifest regression exists.
- Inventory/comparison/forge views remain readable on iPad-sized layouts.
- ItemArt validator and Phase 6 visual tests pass.

---

# Phase 10 — Enemy roster and combat animation

## Purpose

Make encounter composition readable through enemy silhouettes, pose and motion rather than recolor alone.

## Required work

Review all current enemy runtime roles, including mappings where multiple behaviors reuse one texture. At minimum address:

- hollow/basic melee;
- hound;
- cantor/summoner;
- warden/shield role;
- lancer;
- weaver/ranged caster;
- brute/heavy melee;
- elite/champion;
- miniboss where it remains visually tied to boss art.

For each role:

- create or refine an identifiable silhouette;
- give its dangerous attack a recognizable anticipation pose/motion;
- keep movement language consistent with role;
- preserve elite-affix readability without allowing affix VFX to obscure the base enemy;
- validate mixed packs rather than only single-enemy showcase scenes.

Avoid increasing animation duration if it makes combat sluggish. Enemy motion should improve anticipation, not slow the encounter.

## Done when

- Core enemy roles are identifiable during motion at normal gameplay scale.
- Mixed encounters remain readable with elite affixes and player VFX active.
- Attack windups still match damage windows.
- Automated enemy/encounter and full-campaign tests pass.
- Rendered captures show no severe silhouette merging, telegraph occlusion or excessive VFX clutter.

---

# Phase 11 — BGM and combat sound

## Purpose

Give ASHEN VOW a coherent audio identity matching the cathedral/ash visual language and the speed of combat.

## Required work

Create, generate or substantially rebuild the main music family as a coherent set:

- menu/title;
- normal dungeon;
- elite/high-tension combat;
- boss;
- awakened/Phase 2 boss;
- victory.

Then rebuild the highest-value SFX layers:

- seven weapon-family attack identities;
- hit/crit/heavy impact differentiation;
- dash/perfect evade;
- player hurt/death;
- enemy death;
- skill/chain/finisher emphasis;
- rare/legendary/mythic loot;
- UI/equip/forge/chest where needed.

Keep the current `Soundscape` WAV contract unless there is a deliberate tested migration. Normalize perceived loudness so VFX-heavy combat does not become sonically muddy. Use variation/pitch/layering where useful but keep voice allocation bounded.

## Done when

- Each weapon family has a recognizable sound identity.
- Music state changes and crossfades do not click or expose obvious loop seams.
- Boss Phase 2 escalation is audible without overwhelming telegraphs/SFX.
- Menu, normal combat and boss combat have sensible loudness relationships.
- Web export plays music/SFX reliably.
- Gameplay has been auditioned with music and SFX together, not only as isolated files.

---

# Phase 12 — Cathedral environments and presentation polish

## Purpose

Raise world-production quality after character, enemy, weapon and audio identities are stable.

## Required work

- Define a coherent cathedral environment kit rather than a single flattened background image.
- Improve floor, wall, column, altar, gate, stained-glass/ash-light and prop language where appropriate.
- Give route types and major branches subtle environmental identity without confusing navigation.
- Differentiate boss arenas while preserving hazard readability.
- Add restrained ambient motion/particles/light accents only where they do not compete with attack telegraphs.
- Review room transitions, camera framing, loot visibility and UI contrast against the richer environment.
- Maintain Web/iPad performance budgets.

## Done when

- Screenshots from different route/arena contexts feel authored and intentionally distinct.
- Navigation boundaries and walkable space remain obvious.
- Player/enemy silhouettes remain readable against the environment.
- Hazard colors, loot beams and UI text retain contrast.
- No large background asset causes unacceptable Web download/runtime cost.
- Visual regression captures are manually inspected at desktop and iPad proportions.

---

# Phase 13 — Full integration, performance and release-candidate QA

## Purpose

Treat the completed AI-asset pass as a product-level release candidate rather than a collection of individually successful assets.

## Required work

- Audit `assets/ai/asset_backlog.json` and identify all remaining `baseline`, `planned`, `generated` or `integrated` items.
- Resolve all high-priority unfinished entries; explicitly defer only low-priority work with a reason.
- Run the full automated suite and full campaign.
- Test save creation, continue/resume, old-save migration and equipment persistence.
- Test multiple representative three-weapon loadouts so no animation/art assumes one weapon order.
- Check Forge, Vault, inventory, comparison and loot flows with final art.
- Check boss transitions and all major enemy roles in rendered gameplay.
- Audit VFX counts, audio voices, texture memory and Web export size/runtime behavior.
- Run Web build/runtime smoke and iPad/touch interaction checks.
- Review Japanese text layout after final assets change spacing/contrast.
- Remove dead placeholder assets/code only when no save/runtime compatibility depends on them.
- Update documentation and backlog to reflect the final production state.

## Done when

- Full campaign can be completed with final art/audio active.
- Save/resume and old-save compatibility are preserved.
- No high-priority visual/audio target remains an unexplained baseline placeholder.
- No major attack telegraph is obscured by final art/VFX.
- No critical UI control is clipped or unusable on iPad/touch layout.
- Web build/runtime smoke passes.
- CI is green.
- A final PR summary records remaining deferred polish separately from release-blocking issues.

---

# Phase progression protocol for ChatGPT/Codex

When the user says things such as **「続けて」**, **「次へ」**, **「ロードマップに沿って進めて」**, or asks to continue development without naming a feature:

1. read this roadmap;
2. inspect `main`, open PRs and `assets/ai/asset_backlog.json`;
3. determine the earliest phase whose completion criteria are not yet satisfied;
4. continue that phase from the actual repository state;
5. do not redo already-merged work;
6. do not advance to the next phase while a release-significant requirement of the current phase is still incomplete;
7. when a phase is completed, update this document's **Current position** line and the backlog in the same PR before moving on.

A phase may be split across several PRs if technically sensible, but each PR must leave the game playable and tested. The phase number describes product progress, not branch count.

If the user explicitly requests a later phase or a specific feature, follow that request, but still preserve dependency compatibility and document any intentionally skipped work.
