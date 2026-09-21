# Equipment / Inventory UI 2.0

Phase 2 makes equipment decisions readable without collapsing them into a single score.

## Comparison model

Selecting an inventory item chooses the best compatible replacement slot as the initial comparison target. The player can then choose another compatible equipped slot manually.

The comparison panel shows:

- the current equipped item and candidate side by side
- each item's direct stat contribution
- total player stats before and after the swap
- exact signed deltas
- Weapon Art, Tier abilities, unique abilities, and set identity
- three-weapon order before and after a weapon replacement
- gained and lost Chain Recipes, triune/same-family finishers, and two-piece set effects

`EquipmentCompare` is UI-independent so Inventory, Vault, Forge, and later loot popups can share the same rules.

## Item art schema

Item schema 4 adds:

- `art_id`: stable asset key
- `art_variant`: reserved variant key, currently `default`

Artwork is resolved in this order:

1. `assets/items/<art_id>.png`
2. `assets/items/<art_id>.webp`
3. `assets/items/<art_id>.svg`
4. shared reliquary placeholder

Ordinary weapon art IDs are based on weapon family and grade. Legendary/Mythic IDs are based on their effect identity, so random item IDs do not create duplicate art requirements.

The same art is reused in equipped cards, Inventory cards, expanded item detail, Vault, and Forge.

## Save compatibility

`SaveMigration` upgrades Run equipment, Inventory, saved world drops, and Vault contents from older item schemas to schema 4. Existing item identity, rolls, rarity, Tier, grade, enhancement, fusion progress, protection state, and unique/effect data are retained.

## iPad layout

The base UI remains 1440×900 and scales to the existing iPad-class 1024×768 visual test. Inventory uses 20 larger cards per page and Vault uses 24 larger cards per page instead of dense tiny cells. Destructive Forge/Salvage confirmation flows remain modal and unchanged in safety behavior.
