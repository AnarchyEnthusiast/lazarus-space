# PROMPTS_005_UPDATE_036 — Thick Wavy Cave Cap, Dimension Top 29200, Stalactite Density, Asteroid Shrink

SpecSwarm command: `/modify`

This update thickens the ceiling cave bottom cap to 30 blocks with waviness on both surfaces, sets the dimension top to y=29200 by shrinking the asteroid field, increases stalactite frequency, and adds a gap between the cave cap and asteroid field top.

---

## Prompt 1 of 3 — Set Dimension Top to 29200 and Recalculate All Upper Layers

### Files: `bio_mapgen.lua`

The dimension top must be exactly y=29200. Achieve this by shrinking the upper asteroid field. All layers below the asteroid field remain unchanged. All layers above it shift down to fit under the new ceiling.

#### New Layer Boundaries (Top-Down)

Working backwards from the new dimension top:

| Layer | Y Range | Height | Notes |
|-------|---------|--------|-------|
| Ceiling Membrane | 29193–29200 | 7 | Unchanged height, shifted to new top |
| Ceiling Cave System | 28793–29193 | 400 | Unchanged height, shifted down |
| Cave Bottom Cap | 28793–28823 | 30 | Part of ceiling caves, solid cap (see Prompt 2) |
| **Gap / Stalactite Zone** | **~28693–~28793** | **~100** | **NEW — open space between cave cap and asteroids** |
| Upper Asteroid Field | MAX_BIOME_Y+20 – 28693 | ~813 | Shortened to fit |
| Surface Biomes | 27775–~27860 | ~85 | Unchanged |
| Everything below | unchanged | — | No changes below surface biomes |

The asteroid field bottom remains at `MAX_BIOME_Y + 20` (as defined in UPDATE_035 — 20 blocks above the tallest surface biome feature). The asteroid field top is now y=28693, giving approximately 100 blocks of open space between the asteroid field top and the cave bottom cap.

#### Update All Boundary Constants

Find and update EVERY layer boundary constant, y-range check, gradient control point, and globalstep zone boundary in `bio_mapgen.lua`:

- Ceiling membrane top (dimension top): **29200** (was ~29487)
- Ceiling membrane bottom: **29193** (was ~29480)
- Ceiling cave top: **29193** (was ~29480)
- Ceiling cave bottom: **28793** (was ~29080)
- Asteroid field top: **28693** (was ~29080)
- Asteroid field bottom: unchanged (MAX_BIOME_Y + 20, approximately 27880)

Update the skybox/fog globalstep zone upper boundary to **29200**.

#### Update Asteroid Density Gradient

Recalculate for the shorter asteroid field (~813 blocks):

- At asteroid bottom (MAX_BIOME_Y+20): threshold 0.58 (sparse)
- At 1/3 height (~bottom+270): threshold 0.48
- At 2/3 height (~bottom+540): threshold 0.38
- At asteroid top (28693): threshold 0.30

Interpolate linearly between these points.

---

## Prompt 2 of 3 — Thick Wavy Cave Bottom Cap (30 Blocks, Both Surfaces)

### Files: `bio_mapgen.lua`

Replace the cave bottom cap from UPDATE_035 (which was 3-5 blocks thick with waviness only on the bottom) with a much thicker cap that has wavy displacement on BOTH the top and bottom surfaces.

#### Cap Dimensions

- **Thickness**: 30 blocks (y=28793 to y=28823)
- **Center line**: y=28808 (midpoint of the 30-block range)

#### Bottom Surface (Visible From Below, From Asteroid Field)

Apply 2D Perlin noise displacement to the bottom surface:

- **Noise**: Sample at (x, z) with spread 40-60, octaves 2, persistence 0.5
- **Amplitude**: ±10 blocks of vertical displacement from the base y=28793
- **Material**: `bone` for the bottom face (the visible underside)
- The bottom surface undulates between approximately y=28783 and y=28803

#### Top Surface (Visible From Inside Caves, the Cave Floor)

Apply a SEPARATE 2D Perlin noise to the top surface:

- **Noise**: Different seed than the bottom noise, spread 50-70 (slightly larger scale than bottom for variety), octaves 2, persistence 0.5
- **Amplitude**: ±8 blocks of vertical displacement from the base y=28823
- **Material**: `flesh_dark` for the top face (cave floor)
- The top surface undulates between approximately y=28815 and y=28831

#### Interior Fill

Everything between the bottom and top displaced surfaces is solid:
- Bottom 30% of thickness: `bone` (hard exterior layer continuous with bottom surface)
- Middle 40%: `flesh_dark` (fleshy interior)
- Top 30%: `flesh_dark` blending into normal cave floor material

At any given (x, z) position, compute both the displaced bottom y and displaced top y. Fill all blocks between them with solid material using the percentage-based material bands. The actual thickness at each position varies due to the independent noise on each surface (ranging from roughly 14 to 46 blocks depending on how the two surfaces align).

#### Minimum Thickness Constraint

At any (x, z) position, enforce a minimum cap thickness of 10 blocks. If the displaced top surface would be less than 10 blocks above the displaced bottom surface, push the top surface up to maintain the 10-block minimum. This prevents the two wavy surfaces from getting too close and creating paper-thin spots.

#### Replace Previous Cap

Remove the UPDATE_035 wavy cap implementation (which was 3-5 blocks thick, bottom-only waviness) and replace it entirely with this thicker dual-surface version.

---

## Prompt 3 of 3 — More Common Stalactites in the Gap Zone

### Files: `bio_mapgen.lua`

#### Increase Stalactite Density

Stalactites hang from the bottom of the cave cap down into the gap between the caves and the asteroid field. Increase their frequency:

- **Old rate**: approximately 1 in 3 cells (33% chance per cell)
- **New rate**: 1 in 2 cells (50% chance per cell)

Each stalactite cell should have a 50% probability of containing a stalactite.

#### Reposition Stalactite Origin

Stalactites now hang from the wavy bottom surface of the cave cap rather than from a flat boundary. Update the stalactite generation:

- **Attachment point**: The displaced bottom surface of the cave cap at each stalactite's center (x, z). Sample the bottom surface noise at the stalactite center position to find the actual y where the cap bottom is. The stalactite starts from this y and hangs downward.
- **Length**: 60-200 blocks (reduced from 100-300 to fit the shorter gap/asteroid zone). The longest stalactites should extend well into the upper portion of the asteroid field.
- **Base radius**: 8-15 blocks (unchanged)
- **Tip radius**: 1-3 blocks (unchanged)

#### Gap Zone Behavior

The ~100-block gap between the cave cap bottom (~28783-28803 with displacement) and the asteroid field top (28693) is open air with stalactites hanging through it. This zone should:
- NOT generate asteroids (it's above the asteroid field top)
- Allow stalactites to pass through freely
- Use the same skybox and fog as the rest of the bio dimension

Stalactites that extend below the gap into the asteroid field (below y=28693) should override asteroid material at those positions, same as the existing stalactite-asteroid priority system.

#### Stalactite Smoothing

Since the lower asteroids were made smoother in UPDATE_035, apply the same smoothing to stalactites for visual consistency:
- Reduce surface displacement noise amplitude by 30% (same reduction applied to lower asteroids)
- This makes stalactites look like smooth organic formations rather than noisy rough spikes

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Dimension top set to y=29200, asteroid field shrinks to ~813 blocks, all upper layers shift down, ~100-block gap added between cave cap and asteroid top |
| 2 | Cave bottom cap thickened to 30 blocks with independent wavy Perlin displacement on BOTH top (±8) and bottom (±10) surfaces, minimum 10-block thickness enforced |
| 3 | Stalactite density increased from 33% to 50% of cells, stalactites attach to displaced cave cap bottom, length reduced to 60-200 blocks for new gap size, surfaces smoothed |

## Updated Layer Boundaries

Assuming MAX_BIOME_Y ≈ 27860:

| Layer | Estimated Y Range | Height |
|-------|-------------------|--------|
| Frozen Asteroid Field | 26927–26997 | 70 |
| Death Space Barrier | 26997–27006 | 9 |
| Organic Caves (Lower) | 27006–27697 | 691 |
| Jelly/Plasma Membrane | 27697–27712 | 15 |
| Plasma | 27712–27775 | 63 |
| Surface Biomes | 27775–~27860 | ~85 |
| *Biome-Asteroid Gap* | ~27860–~27880 | ~20 |
| **Upper Asteroid Field** | **~27880–28693** | **~813** |
| ***Gap / Stalactite Zone*** | ***28693–~28793*** | ***~100 (NEW)*** |
| **Ceiling Cave Bottom Cap** | **28793–28823** | **30 (wavy ±10 bottom, ±8 top)** |
| **Ceiling Cave Interior** | **28823–29193** | **370** |
| Ceiling Membrane | 29193–29200 | 7 |
| **Dimension Top** | **29200** | — |

**Previous dimension top**: ~29487
**New dimension top**: 29200
**Reduction**: ~287 blocks (asteroid field absorbs the cut)
