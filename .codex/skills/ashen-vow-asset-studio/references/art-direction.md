# ASHEN VOW art direction

## Core identity

ASHEN VOW is a top-down dark-fantasy action game set around a ruined cathedral and ash-bound vows. The visual target is readable, elegant dark fantasy rather than muddy realism.

Use these recurring motifs:

- ash, cracked stone, scorched metal, old reliquaries, bells, thorns, ritual geometry
- oxidized teal / blue-green as the player's clarity color
- antique gold / warm bone for sacred accents
- restrained ember orange and crimson for danger, fire, and bosses
- violet only for occult or summoning language
- cool black/blue shadow instead of neutral flat black

Avoid generic high-saturation mobile-game art, photorealism, chibi proportions, modern military styling, sci-fi machinery, or decorative noise that reduces combat readability.

## Readability hierarchy

At gameplay zoom, the player must be identifiable first, dangerous telegraphs second, enemies third, then decorative environment/VFX.

Silhouettes matter more than surface detail. Important attacks should still read when the texture is viewed at roughly 64–140 px on screen. Keep the outer contour clean and reserve the brightest values for eyes, weapon edges, ritual cores, and telegraphs.

Do not put important information only in subtle hue differences. Reinforce weapon/enemy roles with shape, motion direction, scale, and timing.

## Player

The player is an ash-bound oath knight: compact armored silhouette, teal-blue cloth/energy accents, worn metal, disciplined rather than flamboyant. The player should read as the calm visual anchor against warmer hostile effects.

The current `assets/characters/player.svg` is a 128x128 atlas used non-trivially by `actors/player.gd`: upper body is read from the top region while the legs are drawn from split lower regions. Any replacement must either preserve this atlas contract or update and validate the renderer in the same change.

Keep hands/weapons visually separate enough that the currently equipped weapon family remains legible over the body.

## Enemies

Enemy types should be identifiable by silhouette before color:

- hollow: simple degraded melee humanoid
- hound: low, fast quadruped
- warden/lancer/brute: tall/heavy armored shapes with strong frontal language
- cantor/summoner/weaver: narrow ritual/caster silhouette and elevated focus object
- elite/champion: stronger shoulders/crown/outer contour, without relying only on an aura
- miniboss/boss: unmistakably larger and asymmetrical or crowned silhouette

Phase changes may add horns, crowns, wings, thorns, cracks, ritual halos, or exposed cores, but must not obscure floor telegraphs.

## Item and weapon art

Item art should be a single isolated object or tightly grouped equipment piece on transparent background.

Preferred production target:

- 512x512 PNG or WebP with alpha
- centered but not mechanically symmetrical unless the item design calls for it
- object occupies about 70–80% of the canvas
- crisp silhouette at 64px
- directional lighting from upper-left/front with restrained rim light
- no text, rarity frames, stars, price labels, loot beams, UI borders, or embedded stats

Weapon families need different silhouette grammar:

- sword: balanced straight blade, compact crossguard
- scythe: long crescent blade and sweeping negative space
- spear: very long axial silhouette and narrow tip
- staff: magical focus, ring/crystal/reliquary at one end
- fist: compact paired gauntlet or striking knuckle mass
- mace: dense weighted head with short broad visual center
- spellblade: readable blade plus a restrained magical channel/core

Legendary/Mythic identity should come from the object's construction, engraving, damage, material, glow source, or silhouette—not from a baked rarity border.

## UI and icons

Icons should use simple geometry, strong outline/contrast, and one focal symbol. At 32–48px they must remain recognizable. Do not put small text inside icons.

UI decoration should feel like dark metal, stone, vellum, or reliquary glass, with teal selection states and antique-gold hierarchy accents. Keep Japanese body text high-contrast and avoid textured backgrounds directly behind long text.

## VFX

Effects communicate gameplay first.

- teal/cyan: player timing, dodge, clean magic, successful defensive reads
- warm gold: sacred/finisher/rarity emphasis
- orange/red: damage, fire, dangerous hostile zones
- violet: occult/summon/curse

Use short-lived high-contrast cores with softer tails. Avoid large persistent bloom clouds over the player. Preserve the existing bounded VFX budget and keep floor danger shapes visible.

## Consistency workflow

When using image generation:

1. Start from the closest approved in-game asset or a deliberately created reference sheet.
2. Reuse that reference for later poses/variants instead of independently prompting each image.
3. Lock silhouette, material palette, light direction, and emblem language before adding detail.
4. Compare the generated result at actual gameplay size, not only at full resolution.
5. Iterate when the result is attractive but unreadable in motion.

Do not imitate or name another game's copyrighted art as the target style. Describe the visual properties directly.
