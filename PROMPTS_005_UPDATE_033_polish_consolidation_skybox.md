# PROMPTS_005_UPDATE_033 — Polish: Node Consolidation, Cave Smoothing, Skybox, Rib Fields, Plasma, Grass

SpecSwarm command: `/modify`

This update consolidates redundant nodes, smooths noisy cave walls, adds hanging ceiling plants, shrinks rib field structures, renames red sea to plasma with slower pull, fixes floating marsh grass, reduces marrow bounciness, and adds a custom red twilight skybox for the biological dimension.

---

## Prompt 1 of 5 — Node Consolidation

### Files: `bio_nodes.lua`, `bio_schematics.lua`, `bio_mapgen.lua`, `biomes/*.lua`, `bio_generate_textures.py`

Remove redundant nodes by merging them into existing ones. Update ALL references throughout the entire codebase — node registrations, schematics, mapgen placement, biome generation, content ID caches, texture generation.

#### Group A: Flesh Mushroom Parts (remove 3 nodes)

The flesh mushroom schematics currently use 4 dedicated nodes. Consolidate to 1:

| Remove | Replace With | Rationale |
|--------|-------------|-----------|
| `flesh_mushroom_cap` | `flesh` | Same fleshy material |
| `flesh_mushroom_cap_edge` | `cartilage` | Similar translucent edge material |
| `flesh_mushroom_glow` | `glowing_marrow` | Both are glowing organic blocks |

Keep `flesh_mushroom_stem` — it provides the distinct vertical pillar visual for mushroom structures.

Remove the node registrations for these 3 nodes from `bio_nodes.lua`. Update the mushroom schematics in `bio_schematics.lua` to use the replacement nodes everywhere the removed nodes appeared. Remove texture generation for the removed nodes from `bio_generate_textures.py` if present.

#### Group B: Tissue Duplicates (remove 2 nodes)

| Remove | Replace With | Rationale |
|--------|-------------|-----------|
| `necrotic_patch` (marsh biome) | `necrotic_tissue` (bio_nodes.lua) | Identical material, redundant names |
| `fibrous_strand` | `sinew` | Both are fibrous connective tissue |

Remove the `necrotic_patch` registration from `biomes/abscess_marsh.lua` and use `necrotic_tissue` (already registered in bio_nodes.lua) everywhere `necrotic_patch` appeared. Remove `fibrous_strand` from `bio_nodes.lua` and replace all references with `sinew`.

#### Group C: Skeleton Decorations (remove 1 node)

| Remove | Replace With | Rationale |
|--------|-------------|-----------|
| `skeleton_bone` | `bone` | Identical material |

Remove `skeleton_bone` from `bio_nodes.lua`. Update skeleton schematics in `bio_schematics.lua` to use `bone` for skeleton body blocks. Keep `skeleton_skull` and `skeleton_rib` — they have distinct nodebox shapes.

#### Cleanup Checklist

After all consolidation:
- Remove all `minetest.register_node` calls for the 6 removed nodes
- Update or remove every `minetest.get_content_id()` call referencing removed nodes
- Update or remove every content ID variable (`c_flesh_mushroom_cap`, `c_necrotic_patch`, `c_fibrous_strand`, `c_skeleton_bone`, etc.)
- Search the ENTIRE codebase for any remaining string references to the removed node names (e.g. `"lazarus_space:flesh_mushroom_cap"`) and replace them
- Remove texture generation entries for removed nodes from `bio_generate_textures.py`

**Total: 6 nodes removed** (76 → 70)

---

## Prompt 2 of 5 — Marrow Bounciness, Plasma Rename, and Liquid Speed

### Files: `bio_nodes.lua`, `bio_mapgen.lua`, and all files referencing `red_sea`

#### Reduce Marrow Bounciness

The solid `lazarus_space:marrow` block is too bouncy — players get launched when walking on it.

- If `marrow` has `bouncy` in its groups, reduce it to `bouncy=1` (minimal springiness without launching the player).
- If `glowing_marrow` also has a `bouncy` group, apply the same reduction to `bouncy=1`.
- If either block has `fall_damage_add_percent` set to a negative value (which cushions falls), that can stay — only reduce the bounce.

#### Rename Red Sea to Plasma

Rename all red sea liquid nodes throughout the codebase:

| Old Name | New Name |
|----------|----------|
| `lazarus_space:red_sea_source` | `lazarus_space:plasma_source` |
| `lazarus_space:red_sea_flowing` | `lazarus_space:plasma_flowing` |
| `lazarus_space:red_sea_static` | `lazarus_space:plasma_static` |

In `bio_nodes.lua`:
- Change the node registration names
- Update `description` fields to say "Plasma" instead of "Red Sea"
- Keep all other properties (textures, liquid behavior, groups, sounds) identical

Update ALL references across the entire codebase:
- `bio_mapgen.lua` — content ID variables (rename `c_red_sea_source` → `c_plasma_source` etc.), placement logic, layer comments, any string references
- All biome files in `biomes/` that reference red sea nodes
- `bio_schematics.lua` if referenced
- `bio_generate_textures.py` — update texture names if the red sea textures are named after the node
- Any globalstep code that checks for red sea nodes

#### Reduce Plasma Pull-Down Speed to 25%

The plasma liquid (formerly red sea) pulls the player down too fast when submerged. Reduce the downward pull to approximately 25% of the current speed.

Find the mechanism that applies downward force to players in the plasma:
- If it uses `liquid_viscosity`: increase the value (higher viscosity = slower sinking). Multiply the current viscosity by 4 to achieve ~25% sinking speed.
- If there's a custom globalstep or ABM that applies downward velocity/acceleration to players submerged in the liquid: multiply the force/velocity value by 0.25.
- If controlled by `move_resistance`: increase it proportionally to slow downward movement to 25%.
- If multiple mechanisms contribute, adjust each one so the combined effect is approximately 25% of the current pull-down speed.

The player should still sink in plasma, just much more slowly — a gentle pull rather than a rapid drag to the bottom.

---

## Prompt 3 of 5 — Marrow Cave Smoothing and Hanging Ceiling Plants

### Files: `bio_mapgen.lua`, `bio_schematics.lua` or biome files as appropriate

#### Smooth Marrow Cave Walls

The organic cave biome that uses `marrow`, `glowing_marrow`, and `spongy_bone` for its walls has surfaces that are too noisy — small floating blocks, rough jagged surfaces, and overly chaotic detail. Smooth this specific cave biome only (do NOT change the other two cave biomes).

Find the cave biome that generates walls using marrow/spongy_bone materials and apply these changes:

1. **Increase cave detail noise spread by 50%**: If the current noise spread for wall material selection in this biome is N, change it to N×1.5. This makes surface features larger and broader rather than small and speckled.

2. **Floating block cleanup pass**: After cave carving for this biome's region, run a cleanup pass. For each non-air block in the marrow cave zone, count how many of its 6 neighbors (up, down, north, south, east, west) are air. If 5 or more neighbors are air, replace the block with air. This removes isolated floating single blocks and small protrusions. Run this cleanup once (single pass is sufficient).

3. **Widen wall material bands**: The noise thresholds that select between marrow, spongy_bone, and glowing_marrow likely use tight noise ranges, producing a speckled appearance. Widen these ranges so each material forms larger contiguous patches. For example, if the current bands are something like `noise > 0.3: marrow, -0.3 to 0.3: spongy_bone, < -0.3: glowing_marrow`, widen them or use a separate lower-frequency noise for material selection so patches are bigger.

The goal is cave walls that look like smooth organic tissue surfaces with broad material zones, not a chaotic mess of single-block bumps.

#### Hanging Ceiling Plants in Organic Caves

Add hanging vegetation from organic cave ceilings across ALL three cave biomes (not just the marrow cave). Use existing plant nodes — no new nodes.

For cave ceiling positions (an air block with a solid, non-liquid block directly above it), place hanging plants using the improved hash function with unique seeds per plant type:

| Node | Rate | Placement |
|------|------|-----------|
| `bio_tendril` | 1 in 80 ceiling positions | Place at the air position directly below the ceiling block. If bio_tendril supports wallmounted param2, set param2 to ceiling-attached value (param2=0 in Minetest wallmounted = +Y ceiling). |
| `cave_shroom_small` | 1 in 120 ceiling positions | Place at the air position below ceiling. |
| `bio_polyp_plant` | 1 in 150 ceiling positions | Place at the air position below ceiling. |

Placement rules:
- Only place at positions where the target air block is actually `air` (not liquid, not another node)
- Do not place if the block TWO positions below the ceiling is also solid (insufficient headroom — skip cramped spots)
- Use different hash seeds than floor plants to avoid spatial correlation

---

## Prompt 4 of 5 — Rib Fields Structure Size and Marsh Grass Fixes

### Files: `biomes/rib_fields.lua`, `bio_schematics.lua`, `biomes/abscess_marsh.lua`, all biome files with grass placement

#### Reduce Rib Fields Structures

The rib-like structures in the Rib Fields biome are far too long and too large. They need to be dramatically smaller — short exposed bone fragments, not sweeping arches.

**Length reduction: ~80%**. If a rib structure currently extends N blocks in its longest axis (the span/arc length), reduce to approximately N×0.2. A 50-block rib becomes ~10 blocks. A 100-block rib becomes ~20 blocks.

**Overall size reduction: ~25%**. Reduce the height (how tall the rib rises above the surface) and width/thickness (cross-section) by about 25%. If a rib currently peaks at 12 blocks tall with a 6-block-wide cross section, reduce to ~9 tall and ~4-5 wide.

Find the rib generation code — likely in `biomes/rib_fields.lua` or `bio_schematics.lua`. The ribs may be generated via:
- **Procedural arches** with length/radius/span parameters → multiply length/span by 0.2 and height/width by 0.75
- **Schematic definitions** with explicit dimensions → scale down the schematic arrays
- **Noise-driven curved structures** with arc radius values → reduce the arc radius by 80% and cross-section radius by 25%

Apply the size reduction to ALL rib variants and types. After the change, ribs should feel like small exposed bone fragments poking up from the flesh ground — not massive cathedral-scale arches spanning the landscape.

#### Fix Floating Grass Everywhere (Ground Check)

Grass blocks (bio_grass_1, bio_grass_2, bio_grass_3, bio_grass_tall) are spawning at positions with no solid ground beneath them, creating visible floating grass — particularly bad in Abscess Marsh.

Add a universal ground check to ALL grass placement throughout the codebase (all biome files, bio_schematics.lua, bio_mapgen.lua — anywhere grass is placed):

Before placing any grass node, verify that the block directly below (y-1) is a solid, walkable surface block (flesh, bone, infected_tissue, necrotic_tissue, cartilage, gristle, capillary_surface, or any other solid terrain block). If the block below is air, liquid, or another non-solid node, skip placement.

This ground check must be applied in every biome that places grass, not just the marsh.

#### Cut Marsh Grass to 50%

In addition to the ground check, reduce the total grass quantity in Abscess Marsh specifically to 50% of current amounts:

- If grass placement uses a probability like `1 in N positions`, change to `1 in 2N`
- If it uses a noise threshold, tighten the qualifying range to admit ~50% as many positions
- Apply this reduction to ALL grass types (bio_grass_1 through bio_grass_tall) in the marsh biome
- This 50% reduction applies ONLY to `biomes/abscess_marsh.lua` — other biomes keep their current grass density

---

## Prompt 5 of 5 — Red Twilight Skybox

### Files: `bio_generate_textures.py` (add skybox generation), `bio_mapgen.lua` (update sky override)

#### Generate Skybox Textures

Add skybox texture generation to `bio_generate_textures.py`. Generate 6 PNG images at 128×128 pixels each (placeholder resolution — will be replaced with hand-painted textures later):

| Texture File | Description |
|-------------|-------------|
| `lazarus_space_sky_top.png` | Deep dark red, nearly black. Base color (30, 5, 5) with subtle per-pixel noise variation ±5 RGB to avoid banding. |
| `lazarus_space_sky_bottom.png` | Very dark red-brown. Base color (25, 8, 3) with subtle per-pixel noise ±5 RGB. |
| `lazarus_space_sky_front.png` | Vertical gradient: dark red (40, 8, 8) at top → dim red-orange glow (80, 25, 10) at horizon (vertical center) → dark red-brown (35, 10, 5) at bottom. Add 5-10 subtle horizontal streaks of slightly brighter red (±10 RGB, 1-2 pixels tall, partial width) at random y-positions for a hazy/cloudy atmospheric look. |
| `lazarus_space_sky_back.png` | Same gradient as front but with different random streak positions. |
| `lazarus_space_sky_left.png` | Same gradient pattern as front/back but with different random streak positions. |
| `lazarus_space_sky_right.png` | Same gradient pattern as front/back but with different random streak positions. |

Use `random.seed(42)` for reproducible streak patterns. Each side texture should use a different derived seed (e.g., 42, 43, 44, 45) so the streaks vary between faces but remain deterministic.

The overall effect: a permanent blood-red twilight — dim, oppressive, no visible sun, moon, or stars. The horizon has a faint glow like a crimson sunset that never ends.

#### Update Sky Override in bio_mapgen.lua

In `bio_mapgen.lua`, update the globalstep sky override for the biological dimension range (y=27006 to y=30907).

Replace the current sky type with a skybox using the generated textures:

```lua
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
player:set_sun({visible = false})
player:set_moon({visible = false})
player:set_stars({visible = false})
player:set_clouds({density = 0})
```

Keep the existing red fog settings intact — the fog provides atmospheric depth and distance fade on top of the skybox. The fog color, density, and distance values should remain unchanged.

The sky override zone structure stays the same:
1. **y=27006 to y=30907**: Red twilight skybox + red fog (biological interior)
2. **y=26927 to y<27006**: Regular world sky (frozen asteroids + death space)
3. **Outside all ranges**: Regular world sky (restore defaults)

When a player leaves the bio dimension, restore to normal:
```lua
player:set_sky({type = "regular"})
player:set_sun({visible = true})
player:set_moon({visible = true})
player:set_stars({visible = true})
player:set_clouds({density = 0.4})
```

Ensure the state tracking table properly distinguishes between "skybox" and "default" states to avoid unnecessary `set_sky` calls every globalstep tick.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Consolidate 6 redundant nodes: mushroom cap→flesh, cap edge→cartilage, mushroom glow→glowing_marrow, necrotic_patch→necrotic_tissue, fibrous_strand→sinew, skeleton_bone→bone |
| 2 | Reduce marrow bounce to 1, rename red_sea→plasma (3 liquid nodes), reduce plasma pull-down to 25% speed |
| 3 | Smooth marrow cave biome (larger noise spread, floating block cleanup, wider material bands), add hanging ceiling plants (tendril, cave_shroom, polyp) to all 3 cave biomes |
| 4 | Shrink rib field structures (80% shorter, 25% smaller overall), fix floating grass with universal ground check, cut marsh grass to 50% |
| 5 | Generate 6 red twilight skybox textures (128×128 placeholders), update sky override to skybox type, keep fog |

## Nodes Removed (6)

| Removed Node | Replaced By |
|-------------|-------------|
| `flesh_mushroom_cap` | `flesh` |
| `flesh_mushroom_cap_edge` | `cartilage` |
| `flesh_mushroom_glow` | `glowing_marrow` |
| `necrotic_patch` | `necrotic_tissue` |
| `fibrous_strand` | `sinew` |
| `skeleton_bone` | `bone` |

## Nodes Renamed (3)

| Old Name | New Name |
|----------|----------|
| `red_sea_source` | `plasma_source` |
| `red_sea_flowing` | `plasma_flowing` |
| `red_sea_static` | `plasma_static` |
