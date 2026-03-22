# PROMPTS_005_UPDATE_045 — Tungsten in Stalactites, Sphere Noise Fix, Ice Asteroid Noise, Plasma Layer Overhaul

SpecSwarm command: `/modify`

This update makes tungsten ore very common in the giant stalactites, applies aggressive noise to the top and bottom of livable asteroid spheres so they aren't flat, dramatically strengthens the ice asteroid field bottom noise, and overhauls the plasma layer at the bottom of the ocean into a proper solid barrier with noise on both surfaces.

---

## Prompt 1 of 4 — Tungsten Ore Dense in Stalactites

### Files: `bio_mapgen.lua`

The giant stalactites that hang from the ceiling cave bottom cap into the gap above the asteroid field are made primarily of `bone` in their outer shell. Tungsten ore should spawn very commonly within the bone portions of these stalactites — they are the primary tungsten deposit in the dimension.

#### Dense Tungsten in Stalactite Bone

During stalactite generation, when placing `bone` blocks for the stalactite outer shell:

- **Replace 15-20% of bone blocks with `tungsten_ore`** using the improved hash function with a unique seed
- Use a noise-based selection (spread 4-6, small clusters) so the tungsten appears in visible veins and clumps within the bone, not randomly speckled individual blocks
- The tungsten veins should be 3-8 ore blocks in connected clusters

This makes stalactites the go-to mining target for tungsten. Players who climb or bridge to a stalactite will find rich ore veins running through the bone shell.

#### Do NOT Add Tungsten to Stalactite Interior

The interior materials (`rotten_flesh`, `flesh`, or whatever fills the stalactite core) should NOT contain tungsten. Only the `bone` outer shell gets tungsten deposits. This makes geological sense — tungsten deposited in the hard mineral bone structure.

#### Keep Existing Scatter Generation

The existing tungsten scatter generation in flesh/bone/cartilage terrain (from UPDATE_043, ~1 in 2500 blocks) stays unchanged. The stalactite tungsten is an additional, much denser deposit on top of the normal scatter.

---

## Prompt 2 of 4 — Aggressive Noise on Livable Asteroid Sphere Top/Bottom

### Files: `bio_mapgen.lua`

UPDATE_044 added 3D noise to the livable asteroid spheroid outer shells, but the top and bottom are STILL appearing flat or nearly flat. The noise displacement needs to be much more aggressive, particularly at the poles.

#### Increase Noise Amplitude

The current spheroid shell noise (UPDATE_044: spread 6-10, ±3-5 blocks, 1.5× at poles) is not strong enough. Increase dramatically:

- **Base displacement amplitude**: ±6-8 blocks (was ±3-5)
- **Polar multiplier**: 2.5× at top and bottom poles (was 1.5×)
- **Effective polar displacement**: ±15-20 blocks at the very top and bottom of each sphere

This means the top of a spheroid could be pushed up by 20 blocks or pushed down by 20 blocks from the geometric sphere surface, and the bottom similarly. The poles become extremely rough and irregular.

#### Decrease Noise Spread for Chunkier Features

- **Noise spread**: 4-6 (was 6-10)
- **Octaves**: 3 (was 2)
- **Persistence**: 0.6 (was 0.5)

Smaller spread with more octaves creates chunkier, more dramatic bumps rather than gentle rolling deformation. The top and bottom of each sphere should look like rough, craggy organic masses — NOT smooth curves.

#### Verify Implementation

The noise must affect the actual sphere boundary check. If the current code calculates `distance_from_center < radius` to determine the sphere shell, the noise must modify the radius at each position:

```
effective_radius = base_radius + noise3d(x, y, z) * amplitude * polar_multiplier
```

Where `polar_multiplier` interpolates from 1.0 at the equator to 2.5 at the poles based on the normalized vertical offset:

```
vertical_factor = math.abs(y - center_y) / base_radius
polar_multiplier = 1.0 + 1.5 * vertical_factor  -- 1.0 at equator, 2.5 at poles
```

If the previous implementation used a different method that doesn't properly affect the top/bottom, replace it with this approach.

#### Minimum Shell Thickness

Keep the 2-block minimum shell thickness from UPDATE_044. The noise can deform the outer surface aggressively but must never push the shell inward past the interior cavity.

---

## Prompt 3 of 4 — Much Stronger Ice Asteroid Bottom Noise

### Files: `bio_mapgen.lua`

The noise displacement on the bottom of the frozen ice asteroid field (y=26927 area) is not strong enough. The underside still looks too smooth and flat. Make it dramatically rougher.

#### Increase Noise Parameters

Find the bottom edge noise for the frozen asteroid field (added in UPDATE_040: spread 10-20, octaves 3, persistence 0.7, amplitude ±12).

Increase to:

- **Spread**: 8-15 (tighter, rougher features)
- **Octaves**: 4 (was 3)
- **Persistence**: 0.75 (was 0.7 — more aggressive high-frequency detail)
- **Amplitude**: ±30 blocks (was ±12 — 2.5× increase)

The bottom of the ice field should vary by up to 60 blocks total — some positions the ice hangs 30 blocks below the base, others are cut 30 blocks above. The underside should look like a jagged, icy cave ceiling with stalactite-like protrusions and deep pockets carved upward.

#### Verify Ice Materials

After UPDATE_040, the ice asteroids use `default:stone` and `default:ice`. Verify these are still the materials being placed. The noise displacement should affect the boundary — below the displaced bottom at each (x,z), no ice or stone generates (just air/void below the dimension).

---

## Prompt 4 of 4 — Plasma Layer Overhaul (Ocean Floor Barrier)

### Files: `bio_mapgen.lua`

The plasma layer at the bottom of the ocean needs to be reworked into a proper solid barrier layer with noise displacement on both the top and bottom surfaces. This layer separates the ocean above from the caves below and must NOT have holes that let the ocean drain.

#### Replace Current Plasma Layer

Remove the current plasma ocean bottom implementation (which was extended in UPDATE_044 to y=27702 with noise on the underside). Replace it entirely with this new approach:

#### New Plasma Barrier Layer

The plasma layer is a solid barrier of `congealed_plasma` blocks approximately 20 blocks thick at its maximum, with noise-displaced top and bottom surfaces.

**Center line**: y=27705 (positioned between the ocean above and caves below)

**Top Surface** (ocean floor, visible from above when diving):

- **Noise**: 2D Perlin sampled at (x, z)
  - Spread: 30-50 (medium-large scale, gentle rolling ocean floor)
  - Octaves: 2
  - Persistence: 0.4 (smooth)
  - Amplitude: ±6 blocks from y=27715 (base top)
- **Effect**: Top surface undulates between y=27709 and y=27721
- **Material**: `congealed_plasma` (the top face players see when diving to the ocean floor)

**Bottom Surface** (cave ceiling, visible from below):

- **Noise**: 2D Perlin sampled at (x, z), DIFFERENT SEED than top
  - Spread: 20-35 (slightly rougher than top)
  - Octaves: 3
  - Persistence: 0.5
  - Amplitude: ±5 blocks from y=27695 (base bottom)
- **Effect**: Bottom surface undulates between y=27690 and y=27700
- **Material**: `congealed_plasma` for the bottom face, with occasional patches of `bone` (15% of bottom surface positions, noise-based) for structural variety

**Interior Fill**: Everything between the displaced top and displaced bottom at each (x, z) is solid `congealed_plasma`. No air gaps, no holes.

#### Minimum Thickness Enforcement

At every (x, z) position, enforce a minimum barrier thickness of **8 blocks**. If the displaced top surface would be less than 8 blocks above the displaced bottom surface at any point, push the top surface up to maintain the 8-block minimum.

This is critical — the barrier must be completely watertight. The ocean (`plasma_source`) sits above this layer and must NOT leak through into the caves below.

#### NO Holes or Gaps

Unlike some other noisy layers in the dimension, this barrier must have **zero holes**:
- Do NOT apply any decay, probability, or carving to this layer
- Do NOT let cave carving from below penetrate into this barrier
- Do NOT let any other generation pass remove blocks from this barrier
- The barrier is solid at every (x, z) position with no exceptions

If the cave carving noise would carve into the barrier zone, clamp it — caves stop at the displaced bottom surface of the barrier. The barrier overrides all other generation.

#### Ocean Above

Above the displaced top surface: `plasma_source` fills up to y=27775 (the ocean surface / surface biome base level). This is unchanged from current behavior — the ocean sits on top of the barrier.

#### Caves Below

Below the displaced bottom surface: normal cave generation continues. The cave ceiling in the upper portion of the organic caves (near y=27690-27700) now has a wavy organic underside made of congealed plasma and bone, rather than a flat cutoff.

#### Remove Old Jelly Layer

The old jelly/membrane transition layer (y=27697-27712) is fully replaced by this plasma barrier. Since `jelly` and `jelly_glow` were already consolidated into `congealed_plasma` in UPDATE_041, this is just removing the old generation logic and replacing it with the new barrier approach.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | 15-20% of stalactite bone blocks replaced with tungsten_ore in noise-based veins (spread 4-6, clusters of 3-8). Stalactites become primary tungsten mining target. |
| 2 | Livable sphere noise dramatically increased: amplitude ±6-8 (was ±3-5), polar multiplier 2.5× (was 1.5×), spread tightened to 4-6 with 3 octaves. Effective ±15-20 blocks at poles. |
| 3 | Ice asteroid bottom noise increased: amplitude ±30 (was ±12), spread 8-15, 4 octaves, persistence 0.75. Underside becomes extremely rough and jagged. |
| 4 | Plasma layer overhauled: 20-block max solid `congealed_plasma` barrier centered at y=27705, noise on top (±6, smooth) and bottom (±5, rougher), min 8-block thickness enforced, zero holes. Replaces old jelly layer. Ocean cannot leak into caves. |
