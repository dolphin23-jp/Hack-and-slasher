# ASHEN VOW 0.3 — 三連の誓い

The 0.2 cathedral, contracts, blessings, Chronicle, Ascension, Japanese font,
controller/touch controls and Web/PWA remain the foundation. No save path is renamed.

## Combat

Hold the existing attack input to cycle weapon slots 1 → 2 → 3 → 1. Pausing does
not reset the order. Slot three gains 15% reach. Every family cancels into dodge.

| Family | Type | Attack | Base interval |
|---|---|---|---|
| Sword | Slash | Front fan | .24 s |
| Scythe | Slash | Full circle | .29 s |
| Spear | Pierce | 310 px line, hits every aligned target | .26 s |
| Staff | Magic | Fast piercing projectile | .27 s |
| Fist | Blunt | Two short hits, high stagger | .18 s |
| Mace | Blunt | Wide front fan, shield break | .28 s |
| Spellblade | Slash + magic | Wide piercing wave | .25 s |

Enemy type affinities range from -10% to +25%, separately from burning and lightning.
The bestiary shows them. Fatal resistance affects telegraphed elite/boss cone
attacks; enemies do not roll random critical hits.

## Items and loadout

Nine keys: `weapon`, `weapon2`, `weapon3`, `head`, `armor`, `hands`, `feet`,
`accessory`, `accessory2`. The three legacy keys deliberately retain their meaning.
Weapon instances can be assigned to any weapon slot; accessory instances to either
accessory slot. Adjacent swap buttons change the actual attack order.

Schema 3 keeps `id`, `name`, `slot`, `rarity`, `tier`, `base`, `affixes`, `effect`,
`description` and adds `weapon_type`, `grade`, `enhance`, `fusion`, `rolls`, `unique`,
`locked`, `favorite`, optional `inherited` and `legacy_effect`.

| Rarity | Base roll multiplier | Affix count |
|---|---|---|
| Common | .88–1.12 | 0 |
| Rare | 1.05–1.25 | 1 |
| Epic | 1.20–1.45 | 2 |
| Legendary | 1.40–1.70 | 3 |
| Mythic | 1.70–2.05 | 4 |

Rolls are sampled independently; base and affix keys do not overwrite each other's
range metadata. The detail view shows rolled/current upper values.

T1 is the base. T2 increases weapon reach; T3 rewards multiple contacts with a
shield; T4 opens stronger affixes and pull/piercing/guard-break behavior; T5 adds a
third-slot strike. Armor tiers grant shield regeneration, healing, and chain shields.

Six grades use multipliers 1, 1.24, 1.54, 1.91, 2.37, 2.94. Enhancement +0…+10
adds 3% per step. At equal rarity/roll, each grade +10 is slightly stronger than
the next grade +0. Different rarity and roll quality still matter.

The sixteen historical legendary discovery IDs remain. Seven explicit weapon
relics add obtainable family-specific uniques (23 catalogue entries total).
Mythic weapons add a third-slot strike and three-way projectiles; Mythic armor
increases its chain shield contribution. Effects are bounded, with no recursive proc.

## Forge and oaths

Inventory contains separate equipment/forge tabs. Forge the selected equipped slot:
enhance, fuse an unprotected item of the same family/grade (lowest rarity first),
raise Tier with fusion progress, or evolve +10 equipment. Evolution preserves all
affixes and boosts the selected inherited affix by 8%; it resets enhancement.
Salvage yields materials and a small heal. Lock/favorite protects against salvage
and fusion. Bulk salvage affects unprotected Common/Rare inventory only.

Six permanent paths: 戦舞, 秘術, 城塞, 紅蓮, 雷霆, 探究. Select one primary and up to
two distinct secondary paths before departure. Secondary stats are half strength
and grant only the first passive. Three capped ranks per path cost earned oath
fragments. Elite/boss kills award fragments. Active selections are saved per Run;
selection and rank editing are disabled from the in-Run board.

Fire and lightning procs come from active oaths, not the old equipment sets.
Old elemental discoveries receive two fragments per discovery on version-1 migration.
Equipment stats and IDs are retained; legacy items receive compatible behavior.
Drop Rate scales drop frequency, capped at 90%; Rarity Find separately scales
non-Common weights, capped at +200%. Material Find and Salvage affect their own yields.

## Persistence and limits

Save version 2, same `ashen_vow_v1.json` path. Before upgrading version 1, preserve
`.v1.bak`. Preserve records, settings, Chronicle, discoveries, contracts, map version,
checkpoint, equipment and inventory; fill six missing slots. Migration is idempotent.
Invalid Run data is rejected without crashing, with a recovery backup and title notice.
A mid-combat resume uses the existing cleared-sanctuary checkpoint policy.

Projectile cap 192, delayed blasts 64, hazards 96. Existing visual-effect and
chain-lightning limits remain. Weapon T5 and Mythic extra strikes do not recursively
trigger themselves. UI stays on the existing touch/gamepad input routing.

## Validation

Existing 67 gameplay and 51 expansion assertions remain, with obsolete fixed-sword
and elemental-set expectations updated for the new specification. Added `v03_runner.gd`
checks real family hit geometry, chain order, four damage types, dodge cancellation,
roll bounds, crafting, affix inheritance, grade balance, protection, uniques, oaths,
disk restoration, malformed values and actual version-1 migration.

CI retains the original ten-room campaign, southern campaign, rendered UI, resource
leak gate, Web export, Chromium runtime and touch/PWA smoke. It additionally runs
four explicit weapon-chain campaigns and the 0.3 regression. Visual coverage includes
40 captures with forge, evolution, Tier upgrade, reordered chain, oath board and Mythic.

Physical iPad Safari testing requires a real device. Desktop Chromium touch emulation
and native 4:3 viewport tests do not establish device-specific Safari performance.
The visual style remains the existing procedural 2D presentation, with seven distinct
weapon silhouettes, new loot beams/rings and an original Mythic chime.
