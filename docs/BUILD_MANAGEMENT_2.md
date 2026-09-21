# Oath Board / Build Management 2.0

Phase 3 makes permanent progression reversible between runs while keeping the chosen build fixed during an active run.

## Respec

Respec is available only before departure.

- Respec one oath path: every node in that path is removed and its exact node cost is refunded.
- Respec all: every node is removed and all node costs are refunded.
- There is no extra currency fee. The meaningful restriction is timing: an active run cannot change permanent oath allocation.
- Main/secondary oath selection remains editable before departure and read-only during a run.

`OathBoard.total_points()` is the invariant used by respec and preset loading: unspent points + currently allocated node costs must not change.

## Exclusive branch switching

Clicking the opposite mutually-exclusive branch before departure performs an atomic switch.

The old branch node, nodes that depend on it, and a capstone that no longer has a valid prerequisite are refunded. The new branch node is then purchased from the resulting point pool.

This avoids forcing the player to manually clear the whole oath path just to test the other branch.

## Build presets

Up to five presets are stored in the profile.

Each preset stores:

- display name
- main/secondary oath order
- oath node allocation
- starting oath (`blade`, `lance`, or `ember`)
- the three currently observed weapon families as a build memo

Loading a preset actually restores oath order, node allocation, and starting oath. The recorded weapon families are deliberately not force-equipped: presets must never create gear, pull gear from the Vault, or replace current items behind the player's back.

Preset loading recomputes unspent oath points from the player's current total point budget. A preset that costs more points than the profile currently owns is rejected.

Preset names are always present. New saves receive an automatic descriptive name, and the touch-friendly rename action cycles through practical labels such as general, damage, defense, exploration, boss, and farming.

## Combined build view

The Build Management screen shows the three weapon families, main/secondary oaths, permanent oath allocation, starting oath, and current/most-recent Run blessings in one place.

When viewed from an active run, editing controls are blocked but the summary remains available.

## Departure confirmation

Choosing a new run from the title now opens a build confirmation screen before creating the run.

It shows:

- selected main/secondary oaths
- permanent node allocation and unspent points
- expected starting three-weapon order
- selected starting oath
- the role of Run blessings

The player can return to Build Management, adjust the build, or confirm departure. Once the run starts, oath selection and respec are frozen until the next departure.
