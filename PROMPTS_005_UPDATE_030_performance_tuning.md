# PROMPTS_005_UPDATE_030 — Performance Tuning and Asteroid Scaling

SpecSwarm command: `/modify`

This update reduces lag from schematic placement and liquid flow, scales up upper asteroids, and applies general mapgen optimization.

---

## Prompt 1 of 4 — Reduce Schematic Placement Density

### Files: `bio_schematics.lua`, `bio_mapgen.lua`

The current schematic placement rate causes noticeable lag during terrain generation. Reduce all schematic placement frequencies to approximately one quarter of their current values.

#### Surface Biome Schematic Rates (new values)

**Grass placement (all surface biomes):**
- `grass_patch`: change from 1 in 30 to 1 in 120 surface positions
- `grass_tall_patch`: change from 1 in 80 to 1 in 320 surface positions

**Skeleton placement:**
- Rib Fields: change from 1 in 400 to 1 in 1600
- Abscess Marsh: change from 1 in 500 to 1 in 2000
- Molar Peaks: change from 1 in 600 to 1 in 2400
- Vein Flats: change from 1 in 800 to 1 in 3200

**Fleshy mushroom placement:**
- Nerve Thicket: change from 1 in 100 to 1 in 400
- Coral Cliffs: change from 1 in 200 to 1 in 800
- Abscess Marsh: change from 1 in 150 to 1 in 600
- Rib Fields: change from 1 in 250 to 1 in 1000
- Vein Flats: change from 1 in 300 to 1 in 1200

**Cave layer schematics:**
- Cave mushrooms: change from 1 in 200 to 1 in 800
- Cave skeletons: change from 1 in 800 to 1 in 3200

Also reduce the per-chunk schematic placement cap from 15-20 to 5-6 maximum. Once 5 schematics have been placed in a single chunk, stop processing further schematic placements for that chunk. This is the most important change for reducing lag — `minetest.place_schematic` is expensive because it operates on the live map after VoxelManip write-back.

---

## Prompt 2 of 4 — General Mapgen Optimization

### File: `bio_mapgen.lua`

Apply the following performance improvements to the main terrain generation callback:

#### Reduce Noise Object Count

Several noise maps may be sampled but rarely used in a given chunk. Only generate noise maps for layers that actually overlap the current chunk. Currently the code generates all noise maps on every call — wrap each `get_2d_map_flat` and `get_3d_map_flat` call in a conditional that checks the corresponding layer overlap flag before generating. For example, do not generate `jelly_shape_noise` if the chunk does not overlap y=27697-27712.

#### Cache math Functions Locally

At the top of `bio_mapgen.lua`, cache frequently used math functions as local variables:
- `local math_floor = math.floor`
- `local math_sqrt = math.sqrt`
- `local math_abs = math.abs`
- `local math_random = math.random`
- `local math_max = math.max`
- `local math_min = math.min`

Replace all calls to `math.floor`, `math.sqrt`, etc. in the mapgen callback and all helper functions with the local versions. Lua local function calls are significantly faster than global table lookups in tight loops.

#### Reduce Distance Calculation Cost

In places where `math.sqrt(dx*dx + dy*dy + dz*dz)` is used to compare against a radius (hollow asteroids, cell-based structure checks), replace with squared distance comparison where possible: `dx*dx + dy*dy + dz*dz` compared against `radius*radius`. This eliminates the sqrt entirely. Only use actual sqrt when the precise distance value is needed (e.g., for shell thickness zones where you need `distance - (radius - shell_thickness)`).

#### Avoid Table Allocation in Inner Loop

Audit the main z-y-x loop for any table creation (`{}`, `{x=..., y=..., z=...}`) happening per-voxel. Move position table creation outside the inner loops and reuse by mutating `.x`, `.y`, `.z` fields. If position tables are only needed for occasional checks (like cell lookups), create them once before the loop and reuse.

#### Skip Empty Columns Early

For surface biome generation, if a column's terrain height is below the chunk's `minp.y`, skip that column entirely — no surface features exist in this chunk for that column. Similarly, if the terrain height is above `maxp.y`, the column is entirely solid fill and can use a fast memset-style fill instead of per-voxel logic.

---

## Prompt 3 of 4 — Bigger Upper Asteroids

### File: `bio_mapgen.lua` (upper asteroid field section)

The upper asteroids (y=28200-30920) are currently too small. Make them significantly larger.

#### Increase Barren Asteroid Size

Change the `asteroid_shape_noise` spread from 15 to 40. This creates much larger asteroid forms — individual asteroids will range from roughly 10-80 blocks across instead of 3-25. The larger spread produces smoother, more massive shapes.

Adjust the noise thresholds to compensate for the changed spread (larger spread produces a different noise distribution). New threshold values:
- At y=28200 (bottom): threshold 0.55 (was 0.75)
- At y=29560 (middle): threshold 0.42 (was 0.62)
- At y=30920 (top): threshold 0.30 (was 0.48)

These lower thresholds combined with the larger spread produce fewer but much larger asteroids. The density gradient from sparse-at-bottom to dense-at-top is preserved.

The biological crusting surface band stays at 0.02 above the threshold.

#### Increase Hollow Livable Asteroid Size

Increase hollow asteroid radius range from 20-40 blocks to 35-60 blocks. The interior cavity (radius minus shell thickness) scales proportionally, giving much larger livable spaces.

Keep the cell size at 200x200x200 — this means hollow asteroids can now fill a larger portion of their cell, which is fine since they should feel like significant discoveries.

Keep the noise-based displacement from UPDATE_028 (the lumpy non-spherical shape). The displacement amount stays at 20-30% of radius, which now means ±7-18 blocks of displacement on the larger asteroids.

The entry tunnels should widen to 3-4 blocks (from 2-3) to match the larger scale.

---

## Prompt 4 of 4 — Reduce Liquid Lag (Pus and Red Sea)

### Files: `bio_mapgen.lua`, `biomes/abscess_marsh.lua`

Flowing liquids cause significant lag because the engine processes liquid flow for every source block. Reduce liquid source placement dramatically.

#### Abscess Marsh — Drastically Reduce Pus Sources

The pus pools in Abscess Marsh currently place `pus_source` blocks across large areas of terrain, creating massive liquid flow calculations. Make the following changes:

1. **Reduce pool frequency**: Change the pus pool threshold from the 30th percentile of terrain heights to the 10th percentile. Only the very deepest depressions become pools — most of the marsh is now solid infected_tissue ground with only occasional small pools.

2. **Cap pool size**: When filling a low area with pus, limit each contiguous pool to a maximum of roughly 20-30 source blocks. Track source block count during column generation and stop placing `pus_source` once the cap is reached for the current local depression. This prevents massive continuous pus lakes.

3. **Remove deep festering pits entirely**: The feature that places pus 5-15 blocks below the surface creates huge liquid volumes. Remove it. Pus pools should only exist at the surface level — a single layer of `pus_source` blocks at the terrain height in qualifying low spots, not deep filled basins.

4. **Use flowing pus as filler below surface pools**: Where `pus_source` is placed at the surface, fill the 1-2 blocks directly below it with `pus_flowing` instead of more source blocks. Flowing blocks do not trigger flow calculations but still provide visual depth. Actually, flowing blocks placed by mapgen will still be processed — instead, just place solid `infected_tissue` below the single surface layer of pus source. The pool is only 1 block deep.

#### Red Sea — Single Flat Level, No Flowing

The red sea (y=27712-27775) currently fills the entire 63-block-tall volume with `red_sea_source` blocks. This creates enormous liquid flow calculations wherever the sea meets air (at the jelly membrane boundary below and the surface above).

Change the red sea generation to:

1. **Single source level**: Place `red_sea_source` blocks ONLY at y=27774 (the topmost level, one block below the surface floor at y=27775). This is the single flat ocean surface layer.

2. **Fill below with a non-flowing solid**: From y=27712 to y=27773 (everything below the source level), fill with a new static block `lazarus_space:red_sea_static`. Register this node in `bio_nodes.lua`:
   - Same visual appearance as red_sea_source (same texture: `lazarus_space_red_sea_source_animated.png` with the same animation)
   - Same `post_effect_color` as red_sea (so being submerged looks identical)
   - `drowning = 1` (player drowns inside it)
   - `walkable = false` (player sinks into it)
   - `pointable = false`
   - `diggable = false`
   - NOT a liquid — no `liquidtype`, no `liquid_alternative_source`, no flow calculations
   - Groups: `not_in_creative_inventory = 1`
   - This block looks and feels like ocean but the engine does not process liquid flow for it

3. **Debris placement unchanged**: Blood clots, fibrous strands, and organ chunks still replace some of the red_sea_static blocks at their current noise thresholds. They just sit inside the static fill instead of inside liquid source blocks.

4. **Generate the texture** for `red_sea_static` in `bio_generate_textures.py` — it can simply be the same animated texture as red_sea_source (copy or symlink). Alternatively, reference the same texture file in the node definition (use `lazarus_space_red_sea_source_animated.png` directly).

This eliminates tens of thousands of liquid flow calculations per chunk in the red sea volume while maintaining identical visual and gameplay experience (player still drowns, still sees dark red, still encounters debris).

---

## Summary

| Prompt | Change | Impact |
|--------|--------|--------|
| 1 | Schematic density to 25%, cap 5 per chunk | Major lag reduction from place_schematic calls |
| 2 | Conditional noise gen, local math, squared distance, skip empty columns | General mapgen speed improvement |
| 3 | Asteroid noise spread 15→40, radius 20-40→35-60, adjusted thresholds | Much bigger asteroids |
| 4 | Pus pools 1 block deep + rare, red sea as static non-liquid fill with single source layer on top | Major lag reduction from liquid flow |

## New Node Added

| Node | Purpose |
|------|---------|
| `lazarus_space:red_sea_static` | Non-liquid ocean fill — looks/feels like liquid but no flow calculations |
