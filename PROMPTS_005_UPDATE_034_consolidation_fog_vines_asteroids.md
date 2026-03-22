# PROMPTS_005_UPDATE_034 — Node Consolidation Round 2, Fog Fix, Cave Vines, Asteroids, Mushrooms

SpecSwarm command: `/modify`

This update consolidates 5 more redundant nodes, fixes the fog color that broke with the skybox change, adds a new growing cave vine plant, adjusts the upper asteroid field to hang lower with bigger smoother asteroids, and dramatically increases glowing mushroom density in caves.

---

## Prompt 1 of 5 — Node Consolidation Round 2

### Files: `bio_nodes.lua`, `bio_schematics.lua`, `bio_mapgen.lua`, `biomes/*.lua`, `bio_generate_textures.py`

Remove 5 more redundant nodes by merging them into existing ones. Update ALL references throughout the entire codebase — node registrations, schematics, mapgen placement, biome generation, content ID caches, texture generation.

#### Group A: Plant Variants (remove 2 nodes)

| Remove | Replace With | Rationale |
|--------|-------------|-----------|
| `cave_shroom_tall` | `cave_shroom_small` | Same mushroom, just taller. Use `visual_scale = 2.0` on `cave_shroom_small` placements where `cave_shroom_tall` was used, OR simply use `cave_shroom_small` everywhere since height variation isn't critical underground. If visual_scale isn't practical for placement logic, just replace all `cave_shroom_tall` with `cave_shroom_small`. Keep `cave_shroom_bright` — it has a distinct higher light level. |
| `bio_grass_2` | `bio_grass_1` | Three short grass variants (1, 2, 3) plus tall grass is excessive. Remove the middle variant. Replace all `bio_grass_2` placements with `bio_grass_1`. This leaves bio_grass_1 (short), bio_grass_3 (medium), and bio_grass_tall (tall) — still three heights of grass variety. |

#### Group B: Terrain Materials (remove 3 nodes)

| Remove | Replace With | Rationale |
|--------|-------------|-----------|
| `vein_intersection` | `vein_block` | Both are vein wall materials with nearly identical purpose and appearance. Use `vein_block` for all vein terrain. |
| `bone_spur` | `bone` | Both are cream-white bone material. Bone spurs in the rib fields can just be `bone` — the shape of the structure communicates "spur," not the block type. |
| `myelin_sheath` | `nerve_fiber` | Both are pale grey-white neural tissue. Consolidate to `nerve_fiber` for all neural terrain in the Nerve Thicket biome. |

#### Cleanup Checklist

After all consolidation:
- Remove all `minetest.register_node` calls for the 5 removed nodes
- Update or remove every `minetest.get_content_id()` call referencing removed nodes
- Update or remove every content ID variable (`c_cave_shroom_tall`, `c_bio_grass_2`, `c_vein_intersection`, `c_bone_spur`, `c_myelin_sheath`)
- Search the ENTIRE codebase for any remaining string references to the removed node names and replace them
- Remove texture generation entries for removed nodes from `bio_generate_textures.py`
- In `biomes/rib_fields.lua`: replace all `bone_spur` with `bone`
- In `biomes/vein_flats.lua`: replace all `vein_intersection` with `vein_block`
- In `biomes/nerve_thicket.lua`: replace all `myelin_sheath` with `nerve_fiber`

**Total this round: 5 nodes removed** (70 → 65)

---

## Prompt 2 of 5 — Fix Fog Color

### Files: `bio_mapgen.lua`

The skybox added in UPDATE_033 works correctly, but the fog color has turned white. The fog must be dark red to match the blood-red twilight atmosphere.

Find the fog override in the globalstep function that applies to the biological dimension (y=27006 to y=30907). The fog settings were likely reset or overridden when the skybox type was changed from the previous sky setup.

Explicitly set the fog to dark red whenever the skybox is active:

```lua
player:set_fog({
    fog_start = 0.0,
    fog_distance = 200,
    fog_color = {r = 60, g = 10, b = 10}
})
```

If the fog is currently being set elsewhere in the globalstep with different values, update those values. If the fog isn't being set at all (which would explain why it defaulted to white), add the `set_fog` call immediately after the `set_sky` skybox call.

The fog color should be a deep dark red — `{r=60, g=10, b=10}` or similar. Adjust the exact values if the codebase already had a specific red fog color defined previously (before the skybox change broke it) — match whatever dark red was used before. The key requirement is: dark red fog, NOT white.

Also verify that when the player leaves the bio dimension, the fog is properly cleared:
```lua
player:set_fog({})
```

This resets fog to engine defaults (no custom fog) outside the dimension.

---

## Prompt 3 of 5 — New Hanging Cave Vine with Slow Growth

### Files: `bio_nodes.lua`, `bio_mapgen.lua`, `bio_generate_textures.py`

Replace the hanging ceiling plant placement from UPDATE_033 (which reused existing nodes) with a brand new cave vine node that grows slowly downward over time.

#### New Node: `lazarus_space:cave_vine`

Register in `bio_nodes.lua`:

- **Description**: "Cave Vine"
- **Drawtype**: `plantlike` (or `plantlike_rooted` if appropriate for ceiling attachment — if `plantlike` works better, use that)
- **Visual scale**: 1.0
- **Tiles/texture**: Generate in `bio_generate_textures.py` — dark red-green tendril texture. Base color (50, 70, 40) with red veins/streaks (100, 30, 20). 16×16 pixels. The visual should suggest a fleshy organic vine.
- **Paramtype**: "light"
- **Paramtype2**: "wallmounted" (so it can be ceiling-attached with param2=0)
- **Light source**: 2 (very faint bioluminescence)
- **Walkable**: false
- **Climbable**: true (players can climb up/down the vine)
- **Groups**: `snappy=3, flora=1`
- **Sounds**: leaves sounds
- **Selection box**: thin vertical box `{-0.15, -0.5, -0.15, 0.15, 0.5, 0.15}`
- **Drop**: itself (1 vine)

#### Growth ABM

Register an ABM that makes cave vines grow downward:

```lua
minetest.register_abm({
    label = "Cave vine growth",
    nodenames = {"lazarus_space:cave_vine"},
    interval = 30,
    chance = 8,
    action = function(pos, node)
        local below = {x = pos.x, y = pos.y - 1, z = pos.z}
        local below_node = minetest.get_node(below)

        -- Only grow into air
        if below_node.name ~= "air" then
            return
        end

        -- Count vine length above (don't grow forever)
        local max_length = 4 + math.floor(math.random() * 5)  -- 4-8 blocks max
        local check_pos = {x = pos.x, y = pos.y, z = pos.z}
        local length = 0
        while true do
            local n = minetest.get_node(check_pos)
            if n.name == "lazarus_space:cave_vine" then
                length = length + 1
                check_pos.y = check_pos.y + 1
            else
                break
            end
            if length > 10 then break end
        end

        if length >= max_length then
            return
        end

        -- Place new vine segment below
        minetest.set_node(below, {name = "lazarus_space:cave_vine", param2 = 0})
    end,
})
```

The `interval = 30` with `chance = 8` means each vine has roughly a 1-in-8 chance every 30 seconds of growing one block downward. This creates varied growth speeds — some vines grow quickly, others slowly, producing natural-looking varied lengths over time. Maximum vine length is randomized between 4-8 blocks per chain.

#### Initial Placement in Caves

In `bio_mapgen.lua`, place `cave_vine` seed blocks on cave ceilings across ALL three organic cave biomes:

- Place at 1 in 60 ceiling positions (an air block with a solid non-liquid block directly above)
- Set param2=0 for ceiling wallmounted attachment
- Only place where the block is air (not liquid)
- Use the improved hash function with a unique seed

The ABM handles all subsequent growth — mapgen only places the initial seed block on the ceiling. Over time, vines will grow down to varied lengths, creating a living cave ceiling that evolves as players explore.

#### Remove UPDATE_033 Hanging Plant Placement

The hanging plant placement from UPDATE_033 Prompt 3 (which placed bio_tendril, cave_shroom_small, and bio_polyp_plant on ceilings) should be replaced entirely by this cave_vine system. Remove those ceiling placements. Floor-placed plants remain unchanged.

---

## Prompt 4 of 5 — Asteroids Lower, Bigger, Smoother

### Files: `bio_mapgen.lua`

The upper asteroid field needs to extend further down toward the surface biomes, and the asteroids themselves need to be larger with smoother surfaces.

#### Lower the Asteroid Field Bottom

Move the bottom boundary of the upper asteroid field downward by 400 blocks:

- **Old bottom**: y=28200
- **New bottom**: y=27800

This brings asteroids closer to the surface biome terrain (surface biomes peak around y=27775+), so players on the ground can look up and see asteroid shapes looming not too far overhead.

Update the asteroid density gradient for the new range:
- At y=27800 (new bottom): threshold 0.60 (sparse — just a few asteroids at the lowest extent)
- At y=28500 (lower-mid): threshold 0.50
- At y=29500 (upper-mid): threshold 0.40
- At y=30500 (top): threshold 0.30

Interpolate linearly between these points. The density should feel like a gradual transition from scattered low-hanging asteroids near the surface to a dense field above.

#### Make Asteroids Bigger

Increase the size of individual asteroids by approximately 50%:

- If asteroid size is controlled by a noise spread or radius parameter, multiply it by 1.5
- If asteroids use a cell-based system with size ranges, increase both the minimum and maximum radius by 50%
- If asteroid shape is determined by a distance-from-center calculation with a radius threshold, increase the radius by 50%

Example: if asteroids currently range from 5-15 blocks radius, change to 8-22 blocks radius.

#### Make Asteroids Less Gnarly (Smoother)

The asteroid surfaces are too rough and chaotic — they should have smoother, rounder profiles.

- **Increase the shape noise spread** by 50-100%. If the noise that displaces asteroid surfaces currently has a spread of N, change to N×1.75. Larger spread = broader, gentler bumps instead of jagged spikes.
- **Reduce the displacement amplitude** by 30%. If the noise displacement is currently ±A blocks, reduce to ±A×0.7. Less extreme surface variation = smoother silhouettes.
- **If there's a secondary/detail noise** on asteroid surfaces, reduce its contribution by 50% or remove it entirely. The asteroids should read as large smooth organic masses, not rough craggy rocks.

These changes apply to barren asteroids, hollow livable asteroids, and any other asteroid variant in the upper field.

---

## Prompt 5 of 5 — More Glowing Mushrooms in Caves

### Files: `bio_mapgen.lua`

The `lazarus_space:glowing_mushroom` is already placed on organic cave floors but is far too rare. Make them much more common — they should be a prominent feature of the cave ecosystem providing significant ambient lighting.

Find all glowing mushroom placement in the organic caves (y=27006-27697) and the ceiling caves (y=30500-30900):

#### Increase Placement Rate

- **Current rate**: likely 1 in 100 floor positions or similar
- **New rate**: 1 in 15 floor positions

This is roughly a 6-7× increase. Glowing mushrooms should appear in clusters and patches across cave floors, making the caves feel bioluminescent and alive.

#### Apply to All Cave Biomes

Ensure glowing mushrooms appear on floors in:
- All 3 lower organic cave biomes (marrow caves, and the other two)
- The ceiling cave system (UPDATE_032)
- At cave floor positions where there's a solid block below and air at the placement position

If different cave biomes currently have different mushroom rates, normalize them all to the new 1-in-15 rate. The mushrooms are a universal cave feature, not biome-specific.

#### Verify Light Level

Confirm that `glowing_mushroom` has a reasonable `light_source` value (at least 6-8). With the increased density, the caves should have a warm ambient glow from mushroom clusters rather than being dark voids. If the current light_source is lower than 6, increase it to 8.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Consolidate 5 nodes: cave_shroom_tall→cave_shroom_small, bio_grass_2→bio_grass_1, vein_intersection→vein_block, bone_spur→bone, myelin_sheath→nerve_fiber |
| 2 | Fix fog color from white back to dark red ({r=60, g=10, b=10}), ensure fog set alongside skybox in globalstep |
| 3 | New `cave_vine` node with growth ABM (grows down 4-8 blocks at random speeds), replaces UPDATE_033 ceiling plant reuse, placed at 1/60 ceiling positions |
| 4 | Asteroid field bottom lowered 28200→27800, asteroids 50% bigger, shape noise spread +75% and displacement -30% for smoother profiles |
| 5 | Glowing mushroom placement rate increased ~7× (1/100→1/15), all cave biomes normalized, verify light_source ≥ 8 |

## Nodes Removed (5)

| Removed Node | Replaced By |
|-------------|-------------|
| `cave_shroom_tall` | `cave_shroom_small` |
| `bio_grass_2` | `bio_grass_1` |
| `vein_intersection` | `vein_block` |
| `bone_spur` | `bone` |
| `myelin_sheath` | `nerve_fiber` |

## Nodes Added (1)

| New Node | Type | Purpose |
|----------|------|---------|
| `cave_vine` | Plantlike, wallmounted, climbable | Grows slowly downward from cave ceilings via ABM |

## Running Totals

| Metric | Value |
|--------|-------|
| Nodes after UPDATE_033 | 70 |
| Removed this update | -5 |
| Added this update | +1 |
| **New total** | **66** |
