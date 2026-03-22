# PROMPTS_005_UPDATE_028 — Biological Dimension Tuning Pass

SpecSwarm command: `/modify`

This update addresses visual issues and gameplay tuning for the biological dimension terrain generation added in UPDATE_027. Changes include halving surface biome heights, fixing vertical line artifacts in tall structures, adding glowing plant life to all biomes and caves, adding a dimension-wide red fog, and reworking asteroid sizes and shapes.

---

## Prompt 1 of 5 — Halve Surface Biome Heights

### Files: All 6 biome files in `biomes/` and the framework height computation in `bio_mapgen.lua`

All surface biome terrain is currently too tall. Reduce the effective height of every surface biome by approximately half.

For each registered surface biome, reduce the `height_amplitude` and `detail_amplitude` values to roughly 50% of their current values. The specific biomes and their target ranges:

- **Rib Fields**: Rib arch peak heights should be 40-75 blocks instead of 80-150. Rib half-span should remain the same (the arches get shorter, not narrower). Terrain height variation should be 3-8 blocks instead of 5-15.
- **Molar Peaks**: Major tooth heights should be 100-200 blocks instead of 200-400. Base radii stay the same. Minor teeth scale proportionally. Terrain height variation 3-10 blocks instead of 5-20.
- **Vein Flats**: Already very flat — reduce only slightly. Terrain variation 3-5 blocks instead of 5-8.
- **Coral Cliffs**: Maximum terrain height should be ~150 blocks instead of ~300. Shelf step size should be 10-25 blocks instead of 20-50. This keeps the dramatic vertical character but at a more playable scale.
- **Nerve Thicket**: Nerve tree heights should be 20-40 blocks instead of 40-80. Terrain variation 3-8 blocks instead of 5-15. Canopy start percentage stays at 70%.
- **Abscess Marsh**: Terrain variation 2-6 blocks instead of 3-12. Mound heights 5-10 blocks instead of 10-20.

Update the `height_amplitude` and `detail_amplitude` in each biome's registration call, AND update any hardcoded structure dimensions (rib heights, tooth heights, tree heights) inside the biome's `generate_column` function to match the halved values.

Do NOT change `base_height_offset` values — the base ground level stays the same.

---

## Prompt 2 of 5 — Fix Vertical Line Artifacts in Tall Structures

### Files: `biomes/rib_fields.lua`, `biomes/molar_peaks.lua`, `biomes/coral_cliffs.lua`, `biomes/nerve_thicket.lua`, `bio_mapgen.lua`

There is a visual bug where thin vertical lines of blocks appear at regular intervals in tall generated structures (ribs, teeth, cliffs, nerve trees). The lines are one block wide and appear every other block, creating a striped pattern visible on tall vertical surfaces.

This is most likely caused by an integer math error in the cell-based structure generation or in the main mapgen loop. Common causes of this pattern:

1. **Integer division rounding**: When computing whether a position is inside a structure (e.g. checking if horizontal distance from an arch centerline is less than thickness/2), integer division can produce alternating in/out results at boundaries. Fix by using floating-point math for all distance comparisons and structure profile calculations. Ensure radius, thickness, and distance values are never truncated to integers before the comparison.

2. **Off-by-one in coordinate math**: If the cell grid position is computed with `math.floor(x / cell_size)` but the structure center uses a different rounding, positions at cell boundaries can produce artifacts. Ensure consistent rounding throughout.

3. **Noise index miscalculation**: If the 3D noise index formula `(z - minp.z) * ylen * sidelen + (y - minp.y) * sidelen + (x - minp.x) + 1` has a wrong `sidelen` or `ylen` value, noise sampling can be offset by one position in alternating columns, causing striped artifacts. Verify that `sidelen` equals `maxp.x - minp.x + 1` and `ylen` equals `maxp.y - minp.y + 1`.

4. **VoxelArea index vs noise index mismatch**: The VoxelArea `vi` index and the noise buffer index must advance in lockstep. If the loop iterates z-y-x but the noise was generated with a different dimension order, every other column could sample the wrong noise value.

Audit all structure generation code in the four biome files listed above and the main loop in `bio_mapgen.lua`. Ensure all geometric distance checks use floating-point arithmetic, all noise indices are correct, and the VoxelArea index advances consistently with the noise buffer indices. Add explicit `+ 0.0` or use floating-point literals where integer truncation could occur in distance/radius comparisons.

---

## Prompt 3 of 5 — Scatter Glowing Plants Across All Biomes and Caves

### Files: `bio_nodes.lua`, `bio_mapgen.lua`, all 6 biome files in `biomes/`

Add glowing plant-like decorations throughout the entire biological dimension — both on the surface biomes and in the organic cave layer.

#### New Nodes (register in `bio_nodes.lua`)

Register these new plantlike nodes. All use `drawtype = "plantlike"`, `walkable = false`, `paramtype = "light"`, `sunlight_propagates = true`, and group `attached_node = 1` (so they break if the block below is removed). All textures use colorized default plant textures (e.g. `default_grass_1.png`, `default_fern_1.png`, `default_bush_stem.png`, `default_dry_shrub.png`).

- `lazarus_space:bio_sprout` — Small fleshy sprout. Use `default_grass_1.png` colorized dark red (#A02020:160). `light_source = 3`. Groups: snappy=3, attached_node=1. Appears in all surface biomes.
- `lazarus_space:bio_tendril` — Taller curling tendril. Use `default_fern_1.png` colorized deep pink (#C04060:150). `light_source = 4`. Groups: snappy=3, attached_node=1. Appears in all surface biomes.
- `lazarus_space:bio_polyp_plant` — Stubby polyp growth. Use `default_dry_shrub.png` colorized orange-pink (#D06040:140). `light_source = 2`. Groups: snappy=3, attached_node=1. Appears in all surface biomes.
- `lazarus_space:cave_shroom_small` — Small cave mushroom. Use `default_grass_1.png` colorized yellow-green (#A0C040:140). `light_source = 4`. Groups: snappy=3, attached_node=1. Appears in all three cave biomes.
- `lazarus_space:cave_shroom_tall` — Taller cave mushroom. Use `default_fern_1.png` colorized green-blue (#60B080:130). `light_source = 6`. Groups: snappy=3, attached_node=1. Appears in all three cave biomes.
- `lazarus_space:cave_shroom_bright` — Bright bioluminescent mushroom. Use `default_dry_shrub.png` colorized bright cyan-green (#40E0A0:100). `light_source = 8`. Groups: snappy=3, attached_node=1. Rarer than the others but provides significant light.

#### Surface Biome Plant Placement

In each of the 6 surface biome `generate_column` functions, after the ground surface is generated, scatter plants on the topmost solid surface block. For each surface position (the first air block above solid ground):

- Roughly 1 in 12 surface positions: place `bio_sprout` (most common)
- Roughly 1 in 25 surface positions: place `bio_tendril`
- Roughly 1 in 40 surface positions: place `bio_polyp_plant` (least common)

Use a position hash (e.g. `(x * 73856093 + z * 19349663) % N`) to determine placement deterministically. Only one plant per position — check in order from rarest to most common (polyp, then tendril, then sprout) so rarer plants are not overwritten.

Plants should only be placed on solid ground blocks, not on liquid surfaces, not inside structures (teeth, ribs, nerve trees), and not in the air. Check that the block below the plant position is a solid node before placing.

Each biome can optionally adjust the density. For example, Abscess Marsh (the darkest biome with no light sources currently) should have slightly higher plant density (1 in 8 for sprouts) to provide minimal navigation light.

#### Cave Mushroom Placement

In the organic cave layer generation (bio_mapgen.lua, y=27006-27697), scatter glowing mushrooms on cave floor positions in all three cave biomes. A floor position is a solid block with air directly above it.

- Roughly 1 in 15 floor positions: place `cave_shroom_small` (most common — provides baseline visibility)
- Roughly 1 in 40 floor positions: place `cave_shroom_tall`
- Roughly 1 in 100 floor positions: place `cave_shroom_bright` (rare but illuminates a larger area)

Use position hash for deterministic placement. Place the mushroom in the air block directly above the floor block (the floor block stays solid beneath it).

This replaces the existing `glowing_mushroom` placement if it exists (the one from UPDATE_027 prompt 4 at 1 in 300-500 rate). The new rate is much higher because cave visibility is important for playability.

Cache the content IDs for all six new plant nodes in the content ID caching step.

---

## Prompt 4 of 5 — Dimension-Wide Red Fog

### File: `bio_mapgen.lua` (add new section)

Add a red fog effect that applies to all players inside the biological dimension (y=26927 to y=30927). This creates an oppressive, fleshy atmosphere throughout the entire dimension.

#### Implementation

Register a `minetest.register_globalstep` callback that runs every 2 seconds (accumulate dtime and check). On each tick, iterate through all connected players and check their y-coordinate:

**If the player is within y=26927 to y=30927** (the biological dimension), set their sky and fog:

```
player:set_sky({
    type = "plain",
    base_color = {r=40, g=5, b=5},  -- very dark red
    clouds = false,
})
player:set_sun({visible = false})
player:set_moon({visible = false})
player:set_stars({visible = false})
player:set_clouds({density = 0})
```

For the fog effect, use `player:set_fog()` (available in Luanti 5.9+):
```
player:set_fog({
    fog_start = 0.0,
    fog_distance = 120,
    fog_color = {r=50, g=8, b=8},  -- dark red fog
})
```

If `set_fog` is not available (older engine versions), the `base_color` of the sky combined with `type = "plain"` will still give a reddish atmosphere, just without distance-based fog falloff. Wrap the `set_fog` call in a `pcall` or check if the method exists before calling it.

**If the player is outside the biological dimension** and they previously had the bio sky applied, restore defaults:

```
player:set_sky({type = "regular"})
player:set_sun({visible = true})
player:set_moon({visible = true})
player:set_stars({visible = true})
player:set_clouds({density = 0.4})
```

And clear the fog override if `set_fog` is available:
```
player:set_fog({})  -- empty table restores defaults
```

Track which players currently have the bio sky active using a local table keyed by player name, so you only call the set functions when the player transitions in or out of the dimension (not every 2 seconds). This prevents unnecessary API calls.

Also hook `minetest.register_on_leaveplayer` to clean up the tracking table when a player disconnects.

The fog distance of 120 blocks means players can see roughly 120 blocks ahead before everything fades to dark red. This is far enough to navigate but close enough to feel oppressive and limit visibility of distant terrain features. The dark red color (50, 8, 8) tints everything with a bloody hue. These values are tunable.

---

## Prompt 5 of 5 — Asteroid Rework (Smaller Barren Asteroids, Displaced Hollow Asteroids)

### File: `bio_mapgen.lua` (modify upper asteroid field section)

Two changes to the upper asteroid field (y=28200-30920):

#### Reduce Barren Asteroid Size and Thickness

The barren asteroids generated by the `asteroid_shape_noise` are currently too large and too dense. Make the following changes:

1. **Increase the noise threshold** at all three control points to make asteroids sparser and smaller:
   - At y=28200 (bottom): threshold from 0.65 to 0.75 (even sparser at bottom)
   - At y=29560 (middle): threshold from 0.50 to 0.62
   - At y=30920 (top): threshold from 0.35 to 0.48 (still denser at top, but less so)

2. **Reduce the biological crusting surface band** from 0.03 to 0.02 (thinner surface layer of flesh/sinew on asteroid surfaces).

3. The noise spread stays at 15 — the asteroids will be fewer in number and smaller because more of the noise field falls below the higher thresholds. Individual asteroid forms that do exceed the threshold will be smaller because only the peaks of the noise reach above it.

#### Displace Hollow Livable Asteroids from Perfect Spheres

The hollow livable asteroids currently use a simple distance-from-center check to determine shell vs interior, producing perfectly spherical chambers. Make them irregular by adding noise displacement to the sphere boundary.

For each position being checked against a hollow asteroid:

1. Calculate the base distance from the asteroid center as before.
2. Sample the `asteroid_shape_noise` (already available) at the position and use it to offset the effective radius: `effective_radius = base_radius + noise_value * displacement_amount` where `displacement_amount` is roughly 20-30% of the base radius (e.g. for a radius-30 asteroid, the displacement is ±6-9 blocks).
3. Use `effective_radius` instead of `base_radius` for all shell/interior zone checks.

This means the shell boundary undulates in and out based on the noise field, creating an organic, lumpy shape instead of a perfect sphere. The interior cavity follows the same displaced boundary (inner cavity is `effective_radius - 7` from center), so the interior space is also irregular.

The grass floor, glow ceiling, and water features inside the hollow asteroid should adapt to the displaced shape:
- The grass floor fills the bottom third of the interior based on the actual displaced interior boundary at each column, not a fixed y-level. For each x,z column within the asteroid, find the lowest interior y (where distance < effective_radius - 7) and fill upward for roughly 1/3 of the interior height at that column.
- The glow ceiling follows the top of the displaced interior boundary.
- Entry tunnels stay as cylindrical bores through the shell — they do not need displacement.

Also reduce hollow asteroid shell thickness from 7 blocks to 5 blocks (`effective_radius - 5` for interior boundary instead of `effective_radius - 7`) to keep the interiors reasonably sized given the displacement can eat into the shell.

---

## Summary

| Prompt | Change | Primary Files |
|--------|--------|---------------|
| 1 | Halve all surface biome heights and structure dimensions | All 6 `biomes/*.lua` files |
| 2 | Fix vertical line artifacts in tall structures | `biomes/*.lua`, `bio_mapgen.lua` |
| 3 | Add glowing plants to all surface biomes and caves | `bio_nodes.lua`, `bio_mapgen.lua`, all `biomes/*.lua` |
| 4 | Red fog for entire biological dimension | `bio_mapgen.lua` |
| 5 | Smaller barren asteroids, lumpy hollow asteroids | `bio_mapgen.lua` |
