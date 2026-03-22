# PROMPTS_005_UPDATE_042 — Cave Ceiling Noise, Asteroid Field Edge Noise

SpecSwarm command: `/modify`

This update adds noise displacement to the underside of the upper cave system ceiling so it isn't flat, and adds extreme noise layers to both the minimum and maximum height boundaries of the upper asteroid field.

---

## Prompt 1 of 2 — Upper Cave Ceiling Underside Noise

### Files: `bio_mapgen.lua`

The top ceiling inside the upper cave system (the underside of the ceiling membrane layer, visible when looking up from inside the caves) is completely flat. Add noise displacement to break it up and make it look like a natural organic ceiling.

#### Displaced Ceiling Surface

The ceiling membrane sits at the very top of the upper cave system. The underside of this membrane (the surface players see looking up from inside the caves) needs vertical noise displacement:

- **Noise**: 2D Perlin sampled at (x, z)
  - Spread: 25-40 (medium scale, visible but not too uniform)
  - Octaves: 3
  - Persistence: 0.6
  - Amplitude: ±12 blocks of vertical displacement

- **Effect**: At each (x, z) position, the ceiling drops down by 0-12 blocks or stays at its base height, creating an undulating organic ceiling with bumps, dips, and protrusions hanging down.

- **Material**: The displaced ceiling blocks use the same material as the ceiling membrane (`congealed_rotten_plasma` after UPDATE_041 renames). Where the ceiling extends downward into what would normally be cave air, fill with `congealed_rotten_plasma` for the top 2-3 blocks and `bone` for anything below that (creating bony protrusions hanging from the membrane ceiling).

- **Interaction with cave carving**: The displaced ceiling overrides cave carving in the top portion of the cave system. If cave carving would create air at a position that the displaced ceiling claims as solid, the ceiling wins. This means the ceiling intrudes into the cave space with irregular bumps.

- **Do NOT displace the top surface** of the ceiling membrane (the outside, facing up). Only the underside (facing down into the caves) gets displacement. The outer surface stays flat as the dimension boundary.

---

## Prompt 2 of 2 — Asteroid Field Min/Max Height Noise

### Files: `bio_mapgen.lua`

Both the minimum and maximum height boundaries of the upper asteroid field are cropped too cleanly. Add extreme noise displacement to both edges so the field has ragged, organic-looking top and bottom boundaries.

#### Bottom Edge Noise (Asteroid Field Floor)

The bottom boundary of the asteroid field (approximately MAX_BIOME_Y + 20) needs heavy noise displacement:

- **Noise**: 2D Perlin sampled at (x, z)
  - Spread: 12-20 (small scale — rough, aggressive variation)
  - Octaves: 4
  - Persistence: 0.7 (very aggressive detail)
  - Amplitude: ±30 blocks of vertical displacement

- **Effect**: The effective bottom of the asteroid field at each (x, z) = `base_bottom + noise_displacement`. Some spots hang 30 blocks lower than the base, others are cut 30 blocks higher. The underside of the field looks extremely ragged and uneven — dangling fingers of asteroid material with deep cut-ins between them.

- **Asteroid generation**: Only generate asteroid material above the displaced bottom at each position. Below the displaced bottom: air (gap between surface biomes and asteroids).

#### Top Edge Noise (Asteroid Field Ceiling)

The top boundary of the asteroid field (approximately y=28693) also needs heavy noise displacement:

- **Noise**: 2D Perlin sampled at (x, z), DIFFERENT SEED than bottom noise
  - Spread: 15-25 (slightly larger scale than bottom for variety)
  - Octaves: 4
  - Persistence: 0.65
  - Amplitude: ±25 blocks of vertical displacement

- **Effect**: The effective top of the asteroid field at each (x, z) = `base_top + noise_displacement`. The upper edge of the field is jagged and irregular — some columns of asteroids poke 25 blocks above the base top, others are cut short 25 blocks below it.

- **Asteroid generation**: Only generate asteroid material below the displaced top at each position. Above the displaced top: air (gap between asteroids and the cave bottom cap).

#### Combined Effect

With both edges displaced, the asteroid field has:
- A ragged, dripping bottom edge (±30 blocks, spread 12-20)
- A ragged, spiky top edge (±25 blocks, spread 15-25)
- The two noise patterns are independent (different seeds, different spreads) so they don't correlate — the field looks naturally chaotic rather than having matching top and bottom profiles

The extreme displacement values (±25-30 blocks) mean the edges vary by 50-60 blocks total. This creates dramatic visual variety — some x,z positions have a very thin asteroid band, others have a thick one.

#### Interaction with Existing Features

- **Stalactites**: Stalactites hang from the cave bottom cap (above the asteroid field top). With the top edge displaced, some stalactites may now hang into air where the asteroid top has been cut short, while others may overlap with asteroid material where the top is pushed higher. This is fine — stalactites should still override asteroid material where they overlap.
- **Density gradient**: The asteroid density gradient (sparse at edges, denser in middle) should be calculated based on the UNDISPLACED base boundaries (the original smooth top and bottom), not the displaced ones. The noise only affects the hard cutoff, not the density falloff.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Upper cave ceiling underside gets ±12 block noise displacement (congealed_rotten_plasma + bone protrusions), top surface stays flat |
| 2 | Asteroid field bottom edge: ±30 block displacement (spread 12-20, 4 octaves, very rough). Top edge: ±25 block displacement (spread 15-25, 4 octaves). Both extreme and independent. |
