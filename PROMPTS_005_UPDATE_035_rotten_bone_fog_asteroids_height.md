# PROMPTS_005_UPDATE_035 — Rotten Bone, Fog Fix, Asteroid Cleanup, Cave Cap, Dimension Height Reduction

SpecSwarm command: `/modify`

This update renames glowing_marrow to rotten_bone (no glow), fixes the persistent white fog issue, repositions the asteroid field above the tallest biome with cleaner asteroids, adds a wavy cap to the ceiling cave bottom, and shrinks the dimension by 1500 blocks by cutting asteroid field height.

---

## Prompt 1 of 5 — Rename Glowing Marrow to Rotten Bone

### Files: `bio_nodes.lua`, `bio_mapgen.lua`, `bio_schematics.lua`, `biomes/*.lua`, `bio_generate_textures.py`

#### Rename and Remove Glow

Rename `lazarus_space:glowing_marrow` to `lazarus_space:rotten_bone` throughout the entire codebase.

Changes to the node registration in `bio_nodes.lua`:
- **Name**: `lazarus_space:rotten_bone` (was `lazarus_space:glowing_marrow`)
- **Description**: "Rotten Bone"
- **Light source**: Remove entirely — set `light_source = 0` or remove the field. This block no longer glows.
- **Texture**: Update in `bio_generate_textures.py` — change from the glowing marrow color to a sickly dark yellow-brown with dark patches. Base color (120, 100, 50) with dark rot spots (60, 45, 25). Name the texture `lazarus_space_rotten_bone.png`.
- **Groups**: Keep existing breakability groups. If it had a `glow` or `light` group, remove that.
- **Bouncy**: If it had `bouncy` from the marrow family, keep it at `bouncy=1` (matching the marrow bounce reduction from UPDATE_033).
- All other properties (sounds, hardness) stay the same.

#### Update All References

Search the ENTIRE codebase and replace every occurrence:
- `lazarus_space:glowing_marrow` → `lazarus_space:rotten_bone`
- `c_glowing_marrow` → `c_rotten_bone`
- `glowing_marrow` in content ID caches → `rotten_bone`
- Any comments referencing "glowing marrow" → update to "rotten bone"
- Texture references in `bio_generate_textures.py`

**Important**: In UPDATE_033, `flesh_mushroom_glow` was consolidated INTO `glowing_marrow`. Those references now need to point to `rotten_bone` instead. Verify that the mushroom schematics that were updated to use `glowing_marrow` now use `rotten_bone`.

This is a rename, not a consolidation — the node still exists with the same usage patterns, it just has a new name and no longer emits light.

---

## Prompt 2 of 5 — Fix White Fog (Persistent Issue)

### Files: `bio_mapgen.lua`

The biological dimension fog is showing as white instead of dark red. This has persisted through UPDATE_033 (skybox addition) and UPDATE_034 (attempted fix). The fog MUST be dark red. Debug and fix this properly.

#### Diagnosis

The white fog is likely caused by one of these issues:
1. The `set_fog` call is missing, commented out, or in the wrong code path
2. The `set_fog` call happens BEFORE `set_sky`, and `set_sky` with `type="skybox"` resets the fog color
3. The fog color table format is wrong (should use named fields `r`, `g`, `b`)
4. Another code path is overriding the fog (e.g., the default sky restore path runs when it shouldn't)
5. The state tracking prevents the fog from being re-applied after the skybox is set

#### Required Fix

In the globalstep function that manages sky/fog for the biological dimension, ensure the following happens in this EXACT order when a player is in the bio dimension range (y=27006 to the dimension top):

```lua
-- Step 1: Set the skybox FIRST
player:set_sky({
    type = "skybox",
    textures = {
        "lazarus_space_sky_top.png",
        "lazarus_space_sky_bottom.png",
        "lazarus_space_sky_front.png",
        "lazarus_space_sky_back.png",
        "lazarus_space_sky_left.png",
        "lazarus_space_sky_right.png"
    },
    clouds = false
})

-- Step 2: Set fog AFTER sky (so it isn't overridden)
player:set_fog({
    fog_start = 0.0,
    fog_distance = 200,
    fog_color = {r = 60, g = 10, b = 10}
})

-- Step 3: Hide celestial objects
player:set_sun({visible = false})
player:set_moon({visible = false})
player:set_stars({visible = false})
player:set_clouds({density = 0})
```

#### State Tracking Fix

The state tracking table that prevents redundant `set_sky` calls every tick may also be preventing `set_fog` from being called. Ensure that:
- When a player FIRST enters the bio dimension, ALL calls fire (sky, fog, sun, moon, stars, clouds)
- When a player is ALREADY in the bio dimension (state hasn't changed), the calls are skipped (this is correct)
- When a player LEAVES the bio dimension, fog is explicitly cleared: `player:set_fog({})`

If the state tracking currently only checks one state variable, it may be setting the skybox but skipping the fog on subsequent ticks. Make sure fog is set in the SAME code path as the skybox, not in a separate conditional.

#### Verification

After making the fix, the fog in the biological dimension should be a deep dark red matching `{r=60, g=10, b=10}`. When looking into the distance underground or in the asteroid field, everything should fade to dark red, not white.

---

## Prompt 3 of 5 — Asteroid Field Repositioning, Cleanup, and Dimension Height Reduction

### Files: `bio_mapgen.lua`

Three changes to the upper asteroid field: reposition the bottom edge, make asteroids cleaner/more solid, and reduce the asteroid field height by 1500 blocks. All upper layers shift down accordingly.

#### Step 1: Determine Tallest Surface Biome

Before repositioning, find the absolute maximum y-coordinate that any surface biome structure or terrain feature can reach. Check ALL surface biomes:
- Rib Fields: base terrain height + rib structure max height
- Molar Peaks: base terrain height + tallest tooth/molar structure
- Vein Flats: base terrain height + ridge caps
- Coral Cliffs: base terrain height + cliff amplitude + shelf structures (THIS IS LIKELY THE TALLEST)
- Nerve Thicket: base terrain height + tallest nerve tree
- Abscess Marsh: base terrain height + tallest mound

The base terrain level is y=27775. Add the maximum height each biome's terrain noise and structures can produce. Find the single highest possible y-coordinate across all biomes. Call this value `MAX_BIOME_Y`.

#### Step 2: Set New Asteroid Field Bottom

Set the asteroid field bottom to `MAX_BIOME_Y + 20`. This guarantees a 20-block gap between the tallest possible surface feature and the lowest asteroid, eliminating all clipping.

#### Step 3: Reduce Asteroid Field Height by 1500 Blocks

The asteroid field currently spans approximately 2700 blocks of height (y=27800 to y=30500 after UPDATE_034). Subtract 1500 blocks from this height:

- **New asteroid field height**: approximately 1200 blocks
- **New asteroid field top**: `(MAX_BIOME_Y + 20) + 1200`

Call the new asteroid top value `NEW_ASTEROID_TOP`.

#### Step 4: Shift All Upper Layers Down

Everything above the asteroid field shifts down to sit on top of the new, shorter asteroid field:

| Layer | Old Range | New Range | Height (unchanged) |
|-------|-----------|-----------|-------------------|
| Upper Asteroid Field | 27800–30500 | (MAX_BIOME_Y+20) – NEW_ASTEROID_TOP | 1200 |
| Giant Stalactites | 30200–30500 | Hang from NEW_ASTEROID_TOP down 100-300 blocks | 300 (overlap) |
| Ceiling Cave System | 30500–30900 | NEW_ASTEROID_TOP – (NEW_ASTEROID_TOP+400) | 400 |
| Ceiling Membrane | 30900–30907 | (NEW_ASTEROID_TOP+400) – (NEW_ASTEROID_TOP+407) | 7 |

Update ALL layer boundary constants, gradient control points, y-range checks, and globalstep zone boundaries throughout `bio_mapgen.lua` to use these new values.

Update the skybox/fog zone upper boundary in the globalstep to match the new dimension top (`NEW_ASTEROID_TOP + 407`).

#### Step 5: Update Asteroid Density Gradient

Recalculate the density gradient for the new, shorter asteroid field:
- At asteroid bottom: threshold 0.58 (sparse at the edges)
- At 1/3 height: threshold 0.48
- At 2/3 height: threshold 0.38
- At asteroid top: threshold 0.30

Interpolate linearly between these points.

#### Step 6: Make Lower Asteroids More Solid

The asteroids in the lower portion of the field (closest to the surface biomes) are too noisy and scattered with floating blocks. Fix this for the bottom third of the asteroid field (from asteroid bottom to asteroid bottom + 400 blocks):

1. **Increase the asteroid shape noise threshold** in the lower zone. If the current threshold for "solid asteroid" is T, increase to T + 0.1 in this zone. This makes asteroids denser with fewer thin protrusions and holes.

2. **Floating block cleanup pass**: After asteroid generation in this lower zone, check each solid block. If it has air on 5 or more of its 6 sides, replace it with air. This removes isolated floating single blocks. Apply this cleanup to the bottom 400 blocks of the asteroid field only.

3. **Reduce displacement noise amplitude** in the lower zone by 40%. The asteroids near the surface should be smoother, rounder shapes — not gnarly spiky masses. This makes them look like large hovering organic boulders.

These smoothing changes should taper off gradually above the lower 400 blocks, transitioning back to the normal asteroid roughness in the middle and upper field.

---

## Prompt 4 of 5 — Wavy Cap on Ceiling Cave Bottom

### Files: `bio_mapgen.lua`

The bottom of the ceiling cave system currently has an abrupt transition where the caves meet the asteroid field. Add a solid wavy cap at the bottom of the ceiling cave system so the underside looks natural and organic rather than a flat geometric boundary.

#### Wavy Floor Cap

At the bottom boundary of the ceiling cave system (currently the transition zone around the new `NEW_ASTEROID_TOP`), generate a solid floor cap with wavy vertical displacement:

1. **Base position**: The ceiling cave bottom boundary (NEW_ASTEROID_TOP).

2. **Displacement noise**: Use a 2D Perlin noise (sample at x, z) with:
   - Spread: 40-60 (medium-scale waves)
   - Octaves: 2
   - Persistence: 0.5
   - Amplitude: ±8 blocks of vertical displacement

   This means the actual bottom of the ceiling caves undulates between `NEW_ASTEROID_TOP - 8` and `NEW_ASTEROID_TOP + 8` depending on the x,z position.

3. **Cap thickness**: The solid cap should be 3-5 blocks thick. Below the displaced boundary: solid blocks (use `bone` for the cap surface, `flesh_dark` for the interior). Above the displaced boundary: cave carving begins normally.

4. **Material**: The cap surface (bottom face, visible from below) should be `bone`. The 2-4 blocks above the bone surface should be `flesh_dark` before transitioning to normal cave generation.

5. **Replace the old transition**: The previous gradual carving threshold transition (UPDATE_032: "carving threshold increases from 0.0 at y=30520 to 0.4 at y=30500") should be replaced by this wavy cap system. Remove the old gradual threshold approach and use the displaced solid cap instead.

The visual effect from below: looking up from the asteroid field, players see a wavy, undulating organic ceiling surface made of bone, with occasional dips and rises, rather than a flat plane or a messy noise-carved edge.

---

## Prompt 5 of 5 — More Glowing Mushrooms in Caves (Verification)

### Files: `bio_mapgen.lua`

UPDATE_034 requested glowing mushroom density increase to 1 in 15 floor positions. Verify this change was applied correctly and ensure it covers all cave zones.

#### Verify Placement Rate

Check that `lazarus_space:glowing_mushroom` is placed at approximately 1 in 15 qualifying floor positions (solid block below, air at placement position) in:
- All 3 lower organic cave biomes (y=27006-27697)
- The ceiling cave system (y=NEW_ASTEROID_TOP to NEW_ASTEROID_TOP+400)

If the rate is still lower than 1 in 15 anywhere, update it. If it was already correctly set in UPDATE_034, no change needed — just confirm.

#### Verify Light Level

Confirm `glowing_mushroom` has `light_source = 8` or higher. With the increased density, mushrooms should provide warm ambient lighting throughout the caves. If the value is lower than 8, increase it to 8.

#### Compensate for Rotten Bone

Since `glowing_marrow` (now `rotten_bone`) no longer emits light, caves that previously relied on glowing_marrow for illumination will be darker. The increased mushroom density should compensate for this light loss. If there are cave areas that had glowing_marrow as a significant light source but few mushroom placements, consider adding mushroom placement to those specific areas.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Rename `glowing_marrow` → `rotten_bone`, remove light_source, update texture to dark yellow-brown rot |
| 2 | Fix persistent white fog — ensure `set_fog({r=60, g=10, b=10})` is called AFTER `set_sky` in globalstep, fix state tracking |
| 3 | Asteroid field bottom = tallest biome + 20, asteroid field height reduced by 1500 blocks (~2700→1200), all upper layers shift down, lower asteroids get floating block cleanup + smoother shapes |
| 4 | Solid wavy cap on ceiling cave bottom with ±8 block Perlin displacement, bone surface, replaces old gradual threshold transition |
| 5 | Verify glowing mushroom rate at 1/15 in all caves, verify light_source ≥ 8, compensate for rotten_bone light loss |

## Nodes Renamed (1)

| Old Name | New Name | Change |
|----------|----------|--------|
| `glowing_marrow` | `rotten_bone` | No longer emits light, new texture |

## Estimated New Layer Boundaries

Assuming Coral Cliffs max height ≈ y=27860 (tallest biome):

| Layer | Estimated Y Range | Height |
|-------|-------------------|--------|
| Frozen Asteroid Field | 26927–26997 | 70 |
| Death Space Barrier | 26997–27006 | 9 |
| Organic Caves | 27006–27697 | 691 |
| Jelly/Plasma Membrane | 27697–27712 | 15 |
| Plasma | 27712–27775 | 63 |
| Surface Biomes | 27775–~27860 | ~85 |
| *Gap* | ~27860–~27880 | *~20* |
| **Upper Asteroid Field** | **~27880–~29080** | **~1200** |
| **Giant Stalactites** | **~28780–~29080** | **~300 (overlap)** |
| **Ceiling Cave System** | **~29080–~29480** | **400** |
| **Ceiling Membrane** | **~29480–~29487** | **7** |
| **Dimension Top** | **~29487** | — |

*Exact values depend on actual MAX_BIOME_Y calculated from code. SpecSwarm should compute this from the real terrain parameters.*

**Old dimension height**: 3980 blocks (26927–30907)
**New dimension height**: ~2560 blocks (26927–~29487)
**Reduction**: ~1420 blocks (asteroid field lost 1500, offset by asteroid bottom moving up ~80 blocks)
