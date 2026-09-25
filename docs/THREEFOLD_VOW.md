# ASHEN VOW 0.3 — 三連の誓い

The 0.2 cathedral, contracts, blessings, Chronicle, Ascension, Japanese font,
controller/touch controls and Web/PWA remain the foundation. No save path is renamed.

## Combat

Hold the existing attack input to cycle weapon slots 1 → 2 → 3 → 1. Pausing does
not reset the order. A short uninterrupted chain now gives meaning to the transition
itself: slash→blunt can create 断甲, blunt→pierce creates 破砕貫通, magic→slash
creates 魔力纏刃, and scythe→staff creates 収束魔撃. Three distinct primary
attributes trigger 三相連環; three identical weapon families trigger 同型極撃.
Every family still cancels into dodge.

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
range metadata. Affixes use weighted weapon/slot pools instead of flat random choice:
spears favor pierce/penetration, staves favor magic/skill/CDR, hands favor haste/crit,
feet favor movement/dodge, armor favors HP/armor/barrier, while low-weight off-theme
rolls remain possible. The detail view shows rolled/current upper values.

Tier behavior is family-specific rather than one shared template. Examples: T3 scythe
rewards three-target contact with an extra rotation, T3 spear increases damage after
the first pierced target, T4 staff gains a wall bounce, T4 scythe pulls enemies,
T5 fist creates a circular finisher, T5 spear emits side lances, and T5 spellblade
converts the finisher into barrier. Head, armor, hands, feet and accessories now also
follow separate offensive, defensive, mobility and utility tier paths.

Six grades use multipliers 1, 1.24, 1.54, 1.91, 2.37, 2.94. Enhancement +0…+10
adds 3% per step. At equal rarity/roll, each grade +10 is slightly stronger than
the next grade +0. Different rarity and roll quality still matter.

Historical legendary discovery IDs remain. Seven explicit weapon relics keep their
family-specific uniques, and new armor-slot legendaries can alter chain rules directly:
critical hits can repeat the current weapon once, dodge can skip the next weapon,
full barrier can duplicate magic attacks, chain completion can convert barrier into
area damage or shorten skill cooldowns. Mythic behavior is family-specific instead
of a universal "legendary + three-way projectile" rule. Effects are bounded with
guards against recursive repeats.

## Forge and oaths

Inventory contains equipment, forge and persistent vault tabs. The bag cap is 80,
with 40-item pages, filters, junk marks, optional automatic Common/Rare salvage and a
120-item profile vault. A selected item can open a large detail mode suitable for
the 4:3 iPad layout. Forge the selected equipped slot: enhance, fuse an unprotected
item of the same family/grade (lowest rarity first), raise Tier with fusion progress,
or evolve +10 equipment. Evolution preserves the roll percentile of every base stat
and affix when mapping into the next grade range; the selected inherited affix then
receives a further 8% bonus. Salvage yields materials and a small heal. Lock/favorite
protects against salvage and fusion; bulk salvage can also consume explicit junk.

Six permanent paths: 戦舞, 秘術, 城塞, 紅蓮, 雷霆, 探究. Select one primary and up to
two distinct secondary paths before departure; at least one primary is always
required. Each path now owns a seven-node permanent tree with prerequisite nodes,
a mutually exclusive middle branch and a final capstone. Legacy rank data maps into
the first nodes so existing saves remain useful. Secondary paths contribute half
their node stats; branch effects and capstones are primary-path behavior.
Elite/boss kills still award oath fragments.

Every branch/capstone effect has live behavior (`tests/integrity_runner.gd` fails if an
advertised effect id has no handler):

| Node | Effect |
|---|---|
| 無拍子 `flow_chain` | Linked (in-window) normal strikes attack 12% faster |
| 破拍子 `impact_chain` | Linked melee strikes deal 30% more knockback/stagger |
| 無窮穿ち `arcane_pierce` | Magic bolts (normal attacks and staff/spellblade skills) pierce 2 more |
| 帰還律 `arcane_echo` | Normal-attack magic bolts return once at 60% damage |
| 星界回路 `arcane_cap` | Linked magic strikes and magic chain-skill/finisher stages +20% |
| 恒久障壁 `shield_sustain` | Barrier regeneration +60% |

Fire and lightning procs come from active oaths **or** from the equipped legendary
that carries the relic effect (e.g. シンダーウェイク grants the fire dash while worn).
Two equipped relics of the same family (storm / cinder / echo) also activate that
family's two-piece synergy, matching the comparison screen. Non-weapon legendaries
without a chain-rule unique carry `chain_aegis`: each completed three-chain grants
4 barrier (Mythic 8), capped at max(25, barrier max) and never reducing a larger barrier.
Old elemental discoveries receive two fragments per discovery on version-1 migration.
Equipment stats and IDs are retained; legacy items receive compatible behavior.
Drop Rate scales drop frequency, capped at 90%; Rarity Find separately scales
non-Common weights, capped at +200%. Fractional Material Find is probabilistic rather
than rounded away: +30% means one guaranteed material plus a 30% chance for another.
Salvage affects its own yield.


## Encounter composition and Run blessings

Level-up choices now inspect the currently equipped three weapons. At least one offer
comes from the live chain pool when available: weapon-family mastery, transition
power, slot-2 reach, three-attribute mastery, same-family mastery, or specific links
such as scythe→staff. Legacy Spirit Lance branches remain selectable but are no longer
forced at level 2.

Rooms can spawn authored tactical formations before falling back to random fill:
depth lanes reward line penetration, circular surrounds reward 360-degree control,
shield lines protect ranged backliners, arcane courts spread casters at range, rush
crosses create intersecting charge lanes, and combined-arms waves mix wardens,
summoners, cantors and hounds. The encounter problem is therefore intended to make
weapon order and shape selection matter rather than simply increasing enemy count.

## Persistence and limits

Save version 2, same `ashen_vow_v1.json` path. Before upgrading version 1, preserve
`.v1.bak`. Preserve records, settings, Chronicle, discoveries, contracts, map version,
checkpoint, equipment and inventory; fill six missing slots. Infer the active elemental oath for an old in-progress Run from its equipped sets. Migration is idempotent.
Invalid Run data is rejected without crashing, with a recovery backup and title notice.
A mid-combat resume uses the existing cleared-sanctuary checkpoint policy.

Projectile cap 192, delayed blasts 64, hazards 96. Existing visual-effect and
chain-lightning limits remain. Weapon T5, Mythic extras and same-weapon repeat logic
do not recursively trigger themselves. UI stays on the existing touch/gamepad input routing.

## Validation

Existing gameplay and expansion assertions remain, with the obsolete mandatory
level-2 lance choice replaced by a chain-native blessing expectation while the three
legacy lance branches keep dedicated behavior tests. `v03_runner.gd` additionally
covers transition bonuses, weighted affixes, percentile-preserving evolution, distinct
Tier identities, oath-tree branching, chain-rule legendaries, multidimensional item
comparison, probabilistic material find, persistent vault storage, auto-salvage and
tactical encounter formations.

CI retains the original ten-room campaign, southern campaign, rendered UI, resource
leak gate, Web export, Chromium runtime and touch/PWA smoke. It additionally runs
four explicit weapon-chain campaigns and the 0.3 regression. Visual coverage includes
40 captures, including four-finger move/attack/skill/dodge assertions, with forge, evolution, Tier upgrade, reordered chain, oath board and Mythic.

Physical iPad Safari testing requires a real device. Desktop Chromium touch emulation
and native 4:3 viewport tests do not establish device-specific Safari performance.
The visual style remains the existing procedural 2D presentation, with seven distinct
weapon silhouettes, new loot beams/rings and an original Mythic chime.

The bundled Noto Sans JP subset is regenerated from the OFL upstream font for all current source text. A native glyph-coverage assertion prevents new Japanese labels from silently becoming missing-glyph boxes; the font verification script pins its SHA-256.
