# ASHEN VOW audio and motion direction

## Motion principles

ASHEN VOW is responsive first. Animation must make attacks understandable without making input feel delayed.

General rules:

- keep anticipation short for normal attacks
- impact should happen clearly and decisively
- recovery may sell weight visually, but normal combat should remain dodge-cancel friendly
- never add decorative animation locks that reduce the current fast feel
- weapon family, direction, reach, and impact timing should be readable from motion alone
- movement animation must not visually slide far away from collision/body movement

### Weapon motion language

- sword: compact diagonal/side arc with a crisp impact frame
- scythe: broad rotational sweep, body/weapon continuation through the target line
- spear: direct extension/thrust, minimal side drift, strong tip acceleration
- staff: controlled forward projection with a visible magic release point
- fist: short rapid punches/impacts with minimal weapon travel and fast reset
- mace: heavier overhead/side swing with a stronger impact settle but no long lock
- spellblade: sword-like physical arc followed or accompanied by a short magical extension

For sprite sequences, generate from one approved reference character and preserve armor, handedness, proportions, palette, and weapon identity across frames. Do not independently invent each frame.

For procedural animation in Godot, prefer explicit tunable values for anticipation, travel, impact, recovery, extension, rotation, and secondary VFX timing. Validate at gameplay speed.

## BGM identity

Music should feel ritualistic, ruined-sacred, tense, and propulsive without masking attack cues. Prefer an original tonal language built from low strings/synth drones, struck metal/bell colors, restrained choir-like pads, hand/percussive impacts, and sparse melodic cells.

Avoid recognizable melodies or close imitation of existing game/film music.

The existing runtime expects WAV tracks and crossfades them in `scripts/sound.gd`. Preserve seamless looping unless the loader is deliberately upgraded and tested.

### Music roles

`menu`
- restrained and spacious
- establishes cathedral/ash atmosphere
- low rhythmic density

`dungeon`
- exploration/combat bed
- moderate pulse with room for SFX
- should tolerate long looping without fatigue

`elite_music`
- higher rhythmic density and sharper transient layer
- feels like danger escalation, not a completely unrelated musical world

`boss_music`
- ritual weight, strong repeated pulse, clear escalation potential
- enough spectral space for telegraphs and impacts

`boss_awakened`
- phase-2 escalation of the boss language
- higher density/intensity, stronger upper percussion or harmonic pressure
- should transition naturally from `boss_music`

`victory_music`
- short release/resolution
- recognizable relationship to the game's tonal palette rather than a generic fanfare

For any generated track record: gameplay context, approximate BPM, tonal center/pitch collection, loop length, instrumentation/timbre plan, intensity curve, and whether the loop was auditioned in-game.

## SFX identity

Combat SFX should be layered conceptually into:

1. transient — immediate timing cue
2. body — material/weight information
3. tail — space/magic character

Examples:

- sword/scythe: edge transient + air cut + restrained metallic/body tail
- spear: narrow attack transient + thrust air + hit-specific body
- fist: dry fast transient + compact low-mid impact
- mace: blunt transient + heavier low body + short debris/metal tail
- staff/spellblade: clean transient + tonal/magical body + short synthetic/ritual tail
- rare/legendary/mythic loot: hierarchy should be audible even at low volume, but avoid excessively long fanfares

Keep important timing cues short. Random pitch variation can add life to repeated impacts but must not make the sound comical or detuned.

## Audio generation fallback

When a connected audio-generation tool is available, use it for original material and then normalize/integrate the result. If no such tool is available, compose/synthesize original material through Python. Existing `tools/create_assets.py` and `tools/create_expansion_audio.py` demonstrate deterministic standard-library synthesis and can be extended.

Do not block an otherwise complete feature solely because a third-party audio generator is unavailable.

## Validation

For motion:
- inspect rendered captures at actual gameplay scale
- play repeated three-weapon chains
- verify hit/VFX timing against damage timing
- verify dodge cancel behavior remains intact
- test extreme haste/attack-speed states when relevant

For audio:
- audition at gameplay volume with SFX and music together
- check loop seam and crossfade
- ensure no clipping/distortion unless intentionally designed
- ensure repeated SFX do not become fatiguing or mask telegraphs
- verify Web export loads and plays the chosen format when audio files or loader code change
