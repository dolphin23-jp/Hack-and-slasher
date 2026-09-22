# Phase 4 — Enemy / Elite / Mini Boss / Boss Expansion

Phase 4 expands combat variety without changing the existing dungeon graph. Route structure remains Phase 5 work.

## Design rules

- Keep the three-weapon chain as the combat core.
- Add enemies that reward different weapon shapes and damage types instead of only adding health.
- Every major boss attack must have a readable telegraph and a deliberate recovery window.
- Transformation is the only protected boss state; normal combat should remain fast and interruptible where appropriate.
- Existing saves remain valid. No save-schema change is required.

## Enemy roles

- `lancer`: narrow long charge. Lateral dodge creates a punish window. Blunt is favored.
- `weaver`: delayed floor control plus a follow-up projectile. Slash is favored.
- `brute`: slow radial close-range denial. Pierce and magic are favored.
- `elite`: existing affixed elite remains in the main route.
- `champion`: upper elite tier with affix plus cone / projectile / charge rotation.
- `echoing`: new elite affix that adds delayed projectile pressure after attacks.

## Major encounters

- Room 3 final wave: Champion.
- Room 4 final wave: Forge Boss.
- Room 5 final wave: retains a normal Elite so the elite tier and bestiary remain reachable.
- Room 6 final wave: Mini Boss.
- Room 8 final wave: Thorn Boss.
- Room 11 final wave: Champion.
- Room 9 remains the Bellless King and is still the only encounter that triggers run victory.

### Mini Boss

Cycles a heavy cone, a projectile ring with a safe angular gap, and a charge. Phase II adds a chained charge. Recovery receives a modest damage bonus so correct timing matters.

### Forge Boss

Uses a radial hammer, a five-cell delayed floor wall, a five-shot fan, and a charge. Phase II can chain the charge. Magic and pierce are favored; blunt is resisted. Recovery takes increased damage.

### Thorn Boss

Uses safe-gap projectile rings, cross floor pressure, mixed summons, and a sweeping fan. Slash is favored. Phase II adds additional summon pressure. Recovery takes increased damage.

### Bellless King

The existing final boss remains intact as the victory encounter, including its two phases, safe-gap projectile ring, chained charge, recovery window, and four boss rewards.

## Encounter formations

New roles are integrated into the existing lane, shield-line, arcane-court, rush-cross, and combined formations. Shield-line now uses a mixed front line of Warden / Brute / Lancer rather than duplicate Wardens.

Ambient room hazards are suspended during the major Phase 4 boss waves so boss telegraphs remain readable and difficulty comes from the boss itself.

## Rewards

- Forge Boss guarantees the Mace Legendary.
- Thorn Boss guarantees the Scythe Legendary.
- Champion has a Legendary plus higher-tier secondary drop.
- Mini Boss has an upgraded Rare/Epic-style reward package.
- Only the Bellless King sets the final victory state.

## UI / readability

- Combat HUD supports Champion, Mini Boss, Forge Boss, Thorn Boss, and Bellless King.
- Telegraph overlay distinguishes charge lanes, radial slams, safe angular gaps, floor hazards, and projectile fans.
- Expanded bestiary is paged at eight entries per screen for iPad-class layouts.

## Validation

Phase 4 is gated by the existing QA, expansion, campaign, 0.3, Skill 2.0, Forge, Equipment UI 2.0, and Build Management 2.0 suites plus a dedicated Phase 4 enemy/boss suite.

Visual smoke also renders Champion, Mini Boss, both new full bosses, and both pages of the expanded bestiary at the iPad-class viewport. Web export and browser runtime smoke remain required.
