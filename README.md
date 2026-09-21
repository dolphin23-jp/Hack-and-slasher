# ASHEN VOW — 灰冠の再誓 (0.2)

A playable top-down action RPG / hack-and-slasher vertical slice built in Godot 4.5.1.

Japanese-first, playable cathedral action RPG. **Cathedral Reborn** expands the existing slice across combat, builds, exploration, and iPad controls.

- Three distinct sword strikes (fast opener, wide sweep, guard-breaking finisher), stagger, weighted hit-stop, and dodge-cancel. Evading an incoming hit grants one counterattack; screen shake and hit-stop are configurable.
- Seven enemy types: swarm melee, spread shooters, charging hounds, directional shields, interruptible summoners, affixed elites, and the Bellless King.
- Boss awakening at half health with an altered silhouette and music, telegraphed chained charges, a visible safe sector in the projectile ring, and vulnerable recovery windows.
- **16 legendary items**, three two-piece synergies (storm / cinder / echo), and three mutually exclusive Spirit Lance paths with follow-up evolutions. Nova, finishers and dodge also receive behavioral blessings.
- Original ten-room route plus **two optional contract rooms** forming a southern shortcut. Seeded obstacle layouts and encounter variants; blood, danger and equipment-wager decisions have explicit costs and rewards.
- Persistent legendary discovery, enemy bestiary, five achievements and unlockable starting oaths / blessings. Starting oaths have tradeoffs instead of accumulating permanent stat bonuses.
- Touch hold-to-attack, simultaneous stick + attack, button feedback, adjustable control size/inset, and touch cancellation on modal changes or focus loss.
- Original generated elite / awakened-boss / victory music, with crossfades. Japanese font bundled for offline imports and Web builds.

**既存セーブはそのまま続行できます。旧セーブのマップは10部屋のまま保持されます。南の契約ルートと新しい地形を遊ぶ場合は「探索を始める」または次のアセンションを選んでください。**

See [the update and design notes](docs/CATHEDRAL_REBORN.md) for rules, controls and validation.

## Current regression gates

- 67 existing gameplay/save checks, updated for the twelve-room world.
- 51 expansion behavior checks covering real combat, skill/equipment interactions, contracts, legacy saves, disk restart and discovery.
- Original ten-room campaign, including treasury and boss, using movement and normal attacks for combat.
- Southern-route campaign using normal attacks, skills, dodge and healing; both paid contracts must complete before the boss.
- 33 rendered UI captures with click/gamepad/touch checks, including journal, contracts, awakened boss, equipment synergy and simultaneous stick/attack at iPad-class aspect ratio.
- Script errors and resource leaks fail CI. Web export and Chromium / touch / PWA runtime gates remain required before merging.

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


## Japanese UI font

The game UI is Japanese-first. CI and Web builds fetch a pinned Noto Sans JP subset before Godot import so the Web export contains Japanese glyphs.

For a local checkout, run:

```bash
bash scripts/fetch_japanese_font.sh
```

The pinned font is now bundled. If it is removed, the project still boots and native platforms may use system fallback fonts, but Web exports must include the bundled Japanese font.
