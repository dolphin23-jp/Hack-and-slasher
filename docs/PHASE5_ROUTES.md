# Phase 5 — Dungeon / Run 2.0

New runs use world version 3: three seeded choice stages, a guaranteed recovery room, and the final king. Commit to one room per stage; other branches close. Room IDs remain stable for southern contract behavior, but stage membership, services, and guardian identity vary with seed. Risk, reward, tier, and guardian are visible before commitment. Both guardian bosses retain their unique rewards.

Services include combat, Champion, treasure, recovery, forge materials with the existing forge UI, a Run blessing altar, life-for-Epic event, southern contracts, guardians, and the final boss. Rewards are granted once per room; commitment and service completion are saved. Unfinished rooms restart on resume. World versions 1 and 2 keep their original physical layouts, saves, and encounters. `--legacy-layout` explicitly exercises those compatibility paths in regression tests.

Route choices use large touch buttons and a full itinerary preview. Collect loot before leaving; travel is rejected during battle or pending blessings. No combat teleport is available.

Validation: Phase 5 regression covers 100 seeds, service variety, invalid travel, branch closure, once-only rewards, route persistence, and old-world resume. The campaign uses movement, attacks, skills, healing, equipment changes and actual reward interaction; it reached the king and won (149.4 simulated seconds, 141 normal attacks, 47 kills). Native UI rendering/taps exercise desktop and iPad proportions. Web smoke now asserts actual build confirmation, gameplay, route selection and encounter state on desktop and touch Chromium. Physical iPad/Safari testing remains distinct from emulation.
