# ASHEN VOW

A playable top-down action RPG / hack-and-slasher vertical slice built in Godot 4.5.1.

The current slice contains a ten-room cathedral run, optional treasury, room-specific encounter identities and telegraphed hazards, affixed elite enemies, rotating post-victory Ascension Vows, a persistent title-screen Chronicle, randomized loot, equipment comparison and salvage, level-up blessings, save/resume including restart-safe post-victory checkpoints, touch controls, gamepad menu navigation, a two-phase boss, victory rewards, and an installable Web/PWA export.

## Current regression gates

The repository keeps the vertical slice reproducible in GitHub Actions.

- 55 gameplay/save checks: combat, elite affixes, Ascension Vows, persistent Chronicle records, loot, equip/salvage, growth, save/resume, restart-safe victory checkpoints, boss rewards.
- Deterministic full-run campaign: visits all 10 rooms including the optional treasury and defeats the boss using movement + normal attacks for combat while using collected gear and level growth.
- Rendered UI smoke: title, settings, help, gameplay, map, inventory comparison/equip, pause, upgrades, boss HUD, victory, touch HUD, and 4:3 coverage.
- Shutdown leak gate: Godot resource/object leak warnings fail CI.
- Web export gate: produces HTML/WASM/PCK and verifies the bundle over HTTP.
- Chromium runtime gate: boots the exported game, starts a run, sends movement input, and captures screenshots.
- PWA/touch gate: verifies manifest + active service worker and exercises the game in a 1024×768 touch-enabled browser, including touch start and DASH.

## Play locally

Install Godot 4.5.1 and open this repository as a project, then run `main.tscn`.

### Keyboard / mouse

| Action | Input |
| --- | --- |
| Move | WASD / Arrow keys |
| Aim | Mouse |
| Normal attack | Hold LMB / J |
| Dash | Space / Shift |
| Judgement | Q / RMB |
| Soul Nova | E |
| Spirit Lance | R |
| Mend | F |
| Open / collect | C |
| Reliquary | I / Tab |
| Cathedral map | M |
| Pause | Esc |
| Fullscreen toggle | F11 |

Gamepad and touch controls are also supported. Touch mode exposes a virtual movement stick plus STRIKE, DASH, COLLECT, skill, Reliquary, and Pause controls.

## Web / iPad build

Every successful **Web build** workflow run uploads an `ashen-vow-web` artifact.

1. Open the repository's **Actions** tab.
2. Open the latest successful **Web build** run for `main`.
3. Download the `ashen-vow-web` artifact.
4. Serve the contents of the `web/` directory from an HTTP/HTTPS static server.

The Web build is single-threaded for broad browser/iOS compatibility and is exported as a standalone, landscape PWA. Once hosted over HTTPS, it can be added to a device home screen and its service worker provides the generated offline-capable PWA behavior.

Do not rely on opening `index.html` directly with `file://`; the WASM/PCK bundle should be served over HTTP/HTTPS.

## Main project structure

- `actors/` — player, enemies, projectiles
- `world/` — dungeon, drops, combat overlay, effects
- `data/` — enemies and item generation
- `ui/interface.gd` — HUD, menus, inventory comparison, touch UI
- `scripts/` — game orchestration, profile/save, sound
- `tests/` — gameplay QA, deterministic campaign, rendered UI smoke
- `tools/web_runtime_smoke.mjs` — exported Web/PWA browser verification
- `.github/workflows/` — regression and Web build CI

## CI expectations

A change is ready to merge only when the relevant Visual smoke and Web build workflows are green. The full campaign is intentionally a real simulation rather than a mocked boss kill, so changes to combat, navigation, loot, progression, or enemy behavior can surface as end-to-end failures.
