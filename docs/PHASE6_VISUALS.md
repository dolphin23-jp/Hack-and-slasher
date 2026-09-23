# Phase 6 — Item Art and combat visuals

Shared, bounded ItemArt resolution now covers cards, details, comparison, Vault, Forge, world Loot and rare-loot notifications. Manifest variants and filename fallback both work, invalid paths fall back safely, and rectangular images retain aspect ratio. The importer and example art document the installation pipeline. Missing item art uses a coherent type-specific placeholder instead of a generic chest.

Seven weapon trails distinguish sword arcs, circular scythes, spear arrows, parallel staff rays, fist bursts, mace cracks and hybrid spellblade arcs/rays. The player weapon motion distinguishes thrusts, heavy swings, rotations and hybrid movement. Weapon Art, Chain Skill and Finisher add increasingly prominent action rings; recipe sigils encode individual transitions. Existing Legendary/Mythic sounds and world beams remain; distinct frames and shared-art loot notices extend the same rarity language to UI.

VFX allocation is capped (48 weapon trails, 16 sigils, 64 rings/slashes, 48 lightning arcs, 450 particles), and effects expire normally. Combat timing and damage are unchanged. No continuous texture loading or new full-screen shader is introduced.

Validation: 35 art/lookup/effect-budget/attack-and-dash checks, importer success/path/overwrite checks, and 10 rendered iPad-proportion captures. The normal branching campaign verifies combat through victory. Web export and touch runtime checks run in PR CI. Physical iPad Safari remains untested.
