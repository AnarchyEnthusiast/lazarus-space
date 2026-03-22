# PROMPTS_005_UPDATE_029 — Textures, Amplitude Reduction, and Schematic Decorations

SpecSwarm command: `/modify`

This update replaces all colorized placeholder textures with generated single-color PNG files, further reduces surface biome heights, fixes thin noise artifacts and floating blocks, and adds schematic-based decorations (dead bone skeletons, fleshy mushrooms, tall thick grasses) across biomes.

---

## Prompt 1 of 5 — Texture Generation Script

### File: `bio_generate_textures.py` (new file)

Create a Python script using Pillow (PIL) that generates all textures for the biological dimension nodes. Run this script once to produce PNG files in the `textures/` directory. The script should be self-contained and runnable with `python3 bio_generate_textures.py` from the mod directory.

#### Static Block Textures (16x16 solid color PNGs)

Generate a single 16x16 PNG for each of the following nodes. Each texture is a flat solid fill of the specified color with very subtle noise variation (randomly perturb each pixel's RGB by ±5-10 to avoid perfectly flat appearance). Name each file `lazarus_space_NODENAME.png`.

**Structural blocks:**
| Node | Color (RGB) | Notes |
|------|-------------|-------|
| flesh | (139, 0, 0) | Dark red |
| flesh_dark | (74, 0, 0) | Very dark red |
| flesh_wet | (107, 0, 0) | Mid dark red, slightly glossy — add a few lighter pixels scattered at 10% frequency |
| bone | (245, 240, 220) | Off-white cream |
| enamel | (255, 255, 240) | Bright white-yellow |
| dentin | (245, 230, 184) | Pale yellow |
| spongy_bone | (232, 220, 200) | Cream with darker pores — scatter dark spots (200, 190, 170) at 15% frequency |
| cartilage | (216, 232, 240) | Blue-white |
| membrane | (255, 208, 208) | Pale pink, alpha=140 for semi-transparency |
| frozen_rock | (58, 58, 79) | Dark blue-grey |
| frozen_ice | (200, 216, 240) | Blue-white, alpha=200 |
| death_space | (0, 0, 0) | Pure black |
| jelly | (255, 136, 136) | Pink-red, alpha=160 |
| jelly_glow | (255, 170, 170) | Brighter pink, alpha=140 |
| ceiling_membrane | (90, 10, 10) | Dark fleshy red |
| ceiling_vein | (106, 26, 42) | Dark purple-red |
| asteroid_shell | (74, 58, 48) | Dark brown-grey |
| asteroid_glow | (106, 74, 48) | Warmer brown |
| asteroid_glow_ceiling | (224, 208, 160) | Warm white-yellow |
| muscle | (160, 16, 16) | Deep red |
| sinew | (224, 192, 176) | Off-white pinkish |
| blood_clot | (58, 0, 0) | Very dark red |
| fibrous_strand | (192, 160, 144) | Pale red-brown |
| mucus | (160, 176, 48) | Yellow-green |
| necrotic_tissue | (90, 74, 58) | Grey-brown |
| cyst_wall | (232, 224, 160) | Pale yellow, alpha=140 |
| glow_infected | (160, 160, 32) | Sickly yellow-green |
| marrow | (192, 128, 48) | Yellow-red |
| glowing_marrow | (208, 160, 80) | Brighter yellow |
| gristle | (192, 168, 160) | Grey-pink |
| bone_spur | (232, 224, 208) | Cream-white |
| pulp | (192, 48, 48) | Deep pink-red |
| gum_tissue | (208, 128, 128) | Pink |
| nerve_channel | (224, 192, 192) | Pale pink-white |
| capillary_surface | (176, 32, 32) | Dark red |
| vein_block | (128, 0, 16) | Deep crimson |
| vein_intersection | (160, 32, 48) | Brighter crimson |
| brain_coral | (208, 128, 96) | Pink-orange |
| lung_coral | (192, 112, 112) | Pink |
| polyp | (224, 128, 128) | Bright pink |
| nerve_fiber | (208, 208, 216) | Pale grey-white |
| myelin_sheath | (232, 224, 208) | Off-white |
| nerve_root | (200, 184, 184) | Pale grey-pink |
| node_of_ranvier | (160, 192, 255) | Bright blue-white |
| infected_tissue | (160, 112, 48) | Sickly yellow-red |
| necrotic_patch | (74, 58, 42) | Dark grey-brown |
| bacterial_mat | (96, 112, 80) | Green-grey |
| wbc_debris | (224, 216, 192) | Pale yellow-white |

#### Plantlike Textures (16x16 with transparency)

For plantlike nodes, generate a 16x16 PNG with a transparent background and a simple colored silhouette shape. These are placeholder sprites the user can refine later.

| Node | Shape | Color (RGB) | Notes |
|------|-------|-------------|-------|
| glowing_mushroom | Mushroom cap (dome top half, thin stem bottom half) | (170, 255, 128) | Green-yellow |
| bio_sprout | Single blade, 2px wide, 10px tall, centered | (160, 32, 32) | Dark red |
| bio_tendril | Curving tendril, 2px wide, 14px tall, slight S-curve | (192, 64, 96) | Deep pink |
| bio_polyp_plant | Stubby Y-shape, 4px wide base splitting to 2 arms | (208, 96, 64) | Orange-pink |
| cave_shroom_small | Small mushroom cap, 8px wide cap, 6px stem | (160, 192, 64) | Yellow-green |
| cave_shroom_tall | Taller mushroom, 6px wide cap, 10px stem | (96, 176, 128) | Green-blue |
| cave_shroom_bright | Wide mushroom, 10px wide cap, 4px stem, bright | (64, 224, 160) | Cyan-green |

For each plantlike texture, every pixel not part of the silhouette should have alpha=0 (fully transparent). The silhouette pixels should have alpha=255.

#### Animated Liquid Textures (16x128 vertical frame strips, 8 frames)

Generate refined animated textures for the four liquid types. Each texture is a 16-pixel wide, 128-pixel tall vertical strip containing 8 frames of 16x16 each. The frames should show subtle color variation to simulate liquid movement — shift hue slightly between frames and add moving highlight/dark spots.

| Liquid | Base Color (RGB) | Frame Variation |
|--------|-----------------|-----------------|
| red_sea (source) | (96, 0, 0) | Shift brightness ±10 per frame in a wave pattern, add 2-3 dark spots that move down 1-2px per frame |
| red_sea (flowing) | (96, 0, 0) | Same base, add directional streaks (2px lines) that shift down 2px per frame |
| bile (source) | (128, 138, 0) | Shift green channel ±15 per frame, add bubbling spots (lighter pixels) that appear/disappear |
| bile (flowing) | (128, 138, 0) | Directional streaks shifting down |
| pus (source) | (176, 168, 48) | Minimal movement — shift brightness ±5 only (thick, barely moves), thick cloudy spots |
| pus (flowing) | (176, 168, 48) | Very slow directional streaks |
| marrow (source) | (160, 100, 32) | Shift red/orange ±10 per frame, slow swirl pattern |
| marrow (flowing) | (160, 100, 32) | Slow directional streaks |

Name source textures `lazarus_space_LIQUIDNAME_source_animated.png` and flowing textures `lazarus_space_LIQUIDNAME_flowing_animated.png`.

#### Schematic Decoration Textures (generated in Prompt 4, listed here for completeness)

The script should also generate textures for the new schematic decoration nodes added in Prompt 4. These are included in the same script run so all textures are produced together. See Prompt 4 for the specific nodes and colors.

---

## Prompt 2 of 5 — Update All Node Registrations to Use Generated Textures

### Files: `bio_nodes.lua`, all 6 `biomes/*.lua` files

Replace every `tiles` entry that currently uses a `default_*.png^[colorize:...` string with the corresponding generated texture filename from the `textures/` directory.

For every static block node, the tile becomes simply `"lazarus_space_NODENAME.png"` instead of the colorized default texture. For example:

- `lazarus_space:flesh` tiles change from `"default_dirt.png^[colorize:#8B0000:180"` to `"lazarus_space_flesh.png"`
- `lazarus_space:bone` tiles change from `"default_stone.png^[colorize:#F5F0DC:160"` to `"lazarus_space_bone.png"`

For plantlike nodes, the tile becomes `"lazarus_space_NODENAME.png"` with no colorize modifier.

For liquid nodes, update source tiles to `lazarus_space_LIQUIDNAME_source_animated.png` and flowing tiles to `lazarus_space_LIQUIDNAME_flowing_animated.png`, keeping the existing `animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0}` block.

Nodes that use `use_texture_alpha = "blend"` (membrane, jelly, jelly_glow, cyst_wall, frozen_ice) should keep that property. The alpha is now baked into the PNG file itself.

Update every node registration across all files. Do not miss any. The complete list of files to update:
- `bio_nodes.lua` — all shared nodes
- `biomes/rib_fields.lua` — gristle, bone_spur
- `biomes/molar_peaks.lua` — pulp, gum_tissue, nerve_channel
- `biomes/vein_flats.lua` — capillary_surface, vein_block, vein_intersection
- `biomes/coral_cliffs.lua` — brain_coral, lung_coral, polyp
- `biomes/nerve_thicket.lua` — nerve_fiber, myelin_sheath, nerve_root, node_of_ranvier
- `biomes/abscess_marsh.lua` — infected_tissue, necrotic_patch, bacterial_mat, wbc_debris

---

## Prompt 3 of 5 — Halve Surface Amplitudes Again and Fix Noise Artifacts

### Files: All 6 `biomes/*.lua` files, `bio_mapgen.lua`

#### Halve All Surface Biome Heights

Reduce the `height_amplitude` and `detail_amplitude` of every surface biome registration to approximately half of its current value. Also halve any hardcoded structure dimensions inside each biome's generation function.

Target values (halved from current):

| Biome | height_amplitude | detail_amplitude | Structure changes |
|-------|-----------------|------------------|-------------------|
| rib_fields | 2.5 | 0.75 | Rib arch heights → 20-37 blocks. Half-span stays same. |
| molar_peaks | 3.5 | 1 | Major tooth heights → 50-100 blocks. Base radii → 8-18. Minor teeth scale proportionally. |
| vein_flats | 1 | 0.5 | Ridge heights cap at 2 instead of 3. |
| coral_cliffs | 72 | 2 | Shelf step size → 5-12 blocks. Tube formation threshold stays the same. |
| nerve_thicket | 2.5 | 0.75 | Nerve tree heights → 10-20 blocks. Trunk radii → 1-2. Canopy starts at 70% still. |
| abscess_marsh | 2 | 0.5 | Mound heights → 3-5 blocks. Festering pit depths → 3-8 blocks. |

#### Fix Thin Noise Patterns

Thin vertical or horizontal lines of single blocks appearing in generated terrain are caused by noise values oscillating rapidly around a threshold boundary. At positions where the noise is very close to the threshold, alternating blocks can be solid/air/solid/air creating a one-block-thick stripe pattern.

Apply the following fixes in `bio_mapgen.lua` and all biome files:

1. **Minimum feature thickness enforcement**: After the main generation pass, add a cleanup pass (or integrate into the main pass) that checks for isolated thin features. For any solid block that has air on both opposing sides in any axis (left+right both air, or front+back both air, or above+below both air), remove it (set to air). This eliminates single-block-thick walls and pillars.

2. **Noise threshold hysteresis**: Where a noise value is compared against a threshold to decide solid vs air, add a small dead zone. If the noise is within ±0.02 of the threshold, bias toward the same result as the majority of the 6 face neighbors. This can be implemented by checking: if `abs(noise - threshold) < 0.02`, then look at the node already placed at y-1 (which was processed before in the z-y-x loop) and use the same solid/air result. This smooths rapid oscillations near thresholds.

3. **Cell-based structure edge smoothing**: For structures generated by cell-based systems (ribs, teeth, nerve trees), ensure the distance-from-structure-center calculation uses floating-point math everywhere. Replace any `math.floor` in distance checks with direct floating-point comparison. Add 0.5-block soft edges: at the boundary of a structure (where distance is within 0.5 blocks of the structure radius), use a position hash to probabilistically include or exclude the block, creating a dithered edge instead of a hard aliased boundary.

#### Fix Floating Blocks

Floating single blocks or small clusters appear when noise generates isolated solid pockets disconnected from the main terrain surface.

After the main VoxelManip generation for surface biomes, add a simple connectivity check for the surface layer: for each solid block above the continuous ground fill (i.e., blocks placed as part of structure features, not the base ground fill), check if it has at least 2 solid face-neighbors. If it has 0 or 1 solid neighbors, remove it (set to air). This removes isolated floaters while preserving connected structures.

This check should run AFTER the main generation but BEFORE writing back to the VoxelManip. Since the data array is in memory, neighbor checks are just index arithmetic on the flat array.

Do NOT apply the floating block check to: plantlike nodes (mushrooms, sprouts), liquid nodes, or nodes inside cell-based structures (ribs, teeth, trees — these are structurally intentional). Only apply it to noise-generated terrain fill.

---

## Prompt 4 of 5 — Schematic Decoration Nodes and Definitions

### Files: `bio_nodes.lua` (add nodes), `bio_schematics.lua` (new file), `bio_generate_textures.py` (add textures), `init.lua` (add dofile)

#### New Nodes for Schematic Decorations

Add the following nodes to `bio_nodes.lua`. These are the building blocks for the schematic decorations. Generate their textures in `bio_generate_textures.py` as simple single-color 16x16 PNGs (with subtle ±5 pixel noise like all other static textures).

**Skeleton nodes:**
- `lazarus_space:skeleton_bone` — Aged bone for skeleton structures. Color: (220, 210, 185). Texture: `lazarus_space_skeleton_bone.png`. Groups: cracky=2, crumbly=1. Stone sounds. Slightly darker and more yellowed than regular bone.
- `lazarus_space:skeleton_skull` — Skull block for skeleton heads. Color: (230, 220, 195). Texture: `lazarus_space_skeleton_skull.png`. Groups: cracky=2. Stone sounds.
- `lazarus_space:skeleton_rib` — Thin rib bone. Color: (215, 205, 180). Texture: `lazarus_space_skeleton_rib.png`. Drawtype: `nodebox` with a thin vertical slab (0.25 block thick, centered). Groups: cracky=2, crumbly=1. Stone sounds.

**Fleshy mushroom nodes:**
- `lazarus_space:flesh_mushroom_stem` — Thick fleshy mushroom trunk. Color: (180, 60, 60). Texture: `lazarus_space_flesh_mushroom_stem.png`. Groups: choppy=2, crumbly=2. Wood sounds.
- `lazarus_space:flesh_mushroom_cap` — Mushroom cap block. Color: (200, 40, 40). Texture: `lazarus_space_flesh_mushroom_cap.png`. Groups: choppy=2, crumbly=2. Wood sounds.
- `lazarus_space:flesh_mushroom_cap_edge` — Outer cap with slight overhang. Color: (190, 50, 50). Texture: `lazarus_space_flesh_mushroom_cap_edge.png`. Drawtype: `nodebox` with a slightly wider box (extends 2/16 past the block on each horizontal side). Groups: choppy=2, crumbly=2. Wood sounds.
- `lazarus_space:flesh_mushroom_glow` — Glowing underside of cap. Color: (220, 80, 80). Texture: `lazarus_space_flesh_mushroom_glow.png`. `light_source = 6`. Groups: choppy=2, crumbly=2. Wood sounds.

**Tall grass nodes:**
- `lazarus_space:bio_grass_1` — Short bio grass (1 block). Color: (140, 30, 30). Texture: `lazarus_space_bio_grass_1.png` (plantlike, transparent background, single thick blade shape, 4px wide). Drawtype: `plantlike`. `walkable = false`, `paramtype = "light"`. Groups: snappy=3, attached_node=1, flora=1.
- `lazarus_space:bio_grass_2` — Medium bio grass (1 block, taller visual). Color: (150, 35, 25). Texture: `lazarus_space_bio_grass_2.png` (plantlike, 2 blades, 12px tall). Same properties.
- `lazarus_space:bio_grass_3` — Tall bio grass (1 block, tallest visual). Color: (130, 25, 35). Texture: `lazarus_space_bio_grass_3.png` (plantlike, 3 blades, fills full 16px height). Same properties.
- `lazarus_space:bio_grass_tall` — Very tall thick grass (2-block visual). Color: (120, 20, 20). Texture: `lazarus_space_bio_grass_tall.png` (plantlike, thick bundle of blades filling 16px). Drawtype: `plantlike`. `visual_scale = 2.0` (makes it render at 2x size, appearing 2 blocks tall). `selection_box = {type = "fixed", fixed = {-0.3, -0.5, -0.3, 0.3, 1.0, 0.3}}`. Groups: snappy=3, attached_node=1, flora=1.

#### Modify `init.lua`

Add `dofile(modpath .. "/bio_schematics.lua")` after the `bio_mapgen.lua` dofile line.

#### Schematic Definitions

Create `bio_schematics.lua` containing Lua table schematic definitions and decoration registrations. Store schematics in `lazarus_space.schematics` table.

**Skeleton Schematics (3 variants):**

All skeletons are small, meant to look like dead creatures. They lie on the ground as environmental storytelling.

- `skeleton_small` — A small curled-up skeleton. Size: 5 wide x 3 tall x 3 deep. Arrangement: skeleton_rib blocks forming a curved spine along the x-axis (3 blocks long), skeleton_bone blocks as 2 limbs extending from the middle, skeleton_skull at one end. All other positions are air. This represents a small creature lying on its side. The schematic sits on the ground surface (yoffset = 0, the bottom row is at ground level).

- `skeleton_ribcage` — An exposed ribcage partially buried. Size: 5 wide x 4 tall x 5 deep. Arrangement: A row of skeleton_rib blocks arching upward in the center (3 blocks tall in the middle, 2 on the sides), with skeleton_bone blocks as a spine along the z-axis at the base. Bottom layer is mostly air (skeleton sinks into the ground 1 block, so set yoffset to -1 in the decoration registration). Skeleton_skull at one end of the spine.

- `skeleton_large` — A larger fallen skeleton. Size: 7 wide x 3 tall x 4 deep. A longer spine of skeleton_bone (5 blocks), 4 skeleton_rib arches rising from the spine, skeleton_skull block at one end, skeleton_bone limbs extending from the spine at 2 positions. Bottom row is at ground level.

All skeleton schematics should have `force_placement = false` so they don't overwrite existing structures. Use probability (`param1`) on some blocks to add randomness — set about 30% of the non-essential blocks (limbs, outer ribs) to 50% placement probability so each instance looks slightly different.

**Fleshy Mushroom Schematics (3 variants):**

- `flesh_mushroom_small` — Size: 3 wide x 5 tall x 3 deep. A single flesh_mushroom_stem column (1 block wide, 3 blocks tall) centered, topped by a 3x1x3 cap of flesh_mushroom_cap, with the 4 edge blocks being flesh_mushroom_cap_edge. The block directly under the cap center is flesh_mushroom_glow.

- `flesh_mushroom_medium` — Size: 5 wide x 8 tall x 5 deep. Stem is 1 block wide, 5 blocks tall, centered. Cap is 5x2x5 — bottom layer of cap is flesh_mushroom_glow (center 3x3) surrounded by flesh_mushroom_cap_edge. Top layer is flesh_mushroom_cap (center 3x3) with flesh_mushroom_cap_edge around it. A few random cap blocks at 70% probability for irregular edges.

- `flesh_mushroom_cluster` — Size: 7 wide x 6 tall x 7 deep. Three mushrooms of different heights (3, 5, 6 blocks) clustered together with stems offset from each other. Each has its own small cap (3x1x3). Creates a natural-looking mushroom grouping. Bottom row at ground level.

**Tall Grass Schematics (2 variants):**

- `grass_patch` — Size: 3 wide x 1 tall x 3 deep. A 3x3 arrangement of bio_grass_1, bio_grass_2, and bio_grass_3 with randomized placement — each position has 70% probability of being grass (random variant) and 30% probability of being air. Creates irregular grass clumps.

- `grass_tall_patch` — Size: 5 wide x 1 tall x 5 deep. A 5x5 arrangement with bio_grass_tall in the center 3x3 (each at 60% probability), surrounded by a ring of bio_grass_2 and bio_grass_3 (each at 50% probability). Creates a dense tall grass feature with shorter grasses around the edges.

All schematics are defined as Lua table schematics in `bio_schematics.lua` using the standard `{size = {x=W, y=H, z=D}, data = {...}}` format where each entry in the data array is `{name = "node_name", prob = 0-254}` (prob 254 = always, 127 = 50%, 0 = never). Air entries use `{name = "air", prob = 0}` (probability 0 means "do not place, leave existing node").

---

## Prompt 5 of 5 — Place Schematics as Decorations Across Biomes

### Files: `bio_schematics.lua` (add decoration registrations), `bio_mapgen.lua` (integrate placement)

Register the schematic decorations for placement during terrain generation. There are two approaches and both should be used:

#### Approach A: Mapgen Decoration Registration

For grass patches (which should appear frequently and uniformly), use `minetest.register_decoration`:

- `grass_patch` decoration: Place on any biological dimension surface node (flesh, gum_tissue, infected_tissue, nerve_root, capillary_surface) in the y range 27775-28200. Use noise-based placement with a fill ratio of approximately 0.03 (3% of eligible surface positions). Set `biomes` parameter if the biome system is registered with Minetest's biome API — if not, constrain by y-range and rely on the surface node restriction.

- `grass_tall_patch` decoration: Same surface nodes, same y-range, but lower fill ratio of 0.008 (less common than regular grass). These provide vertical visual variety.

However, because the biological dimension uses a custom mapgen (not Minetest's built-in biome system), `minetest.register_decoration` may not work automatically in this y-range. If the decorations don't appear because the custom mapgen overrides them, use Approach B instead.

#### Approach B: Placement in the Mapgen Callback

Add schematic placement directly into the terrain generation code. After the main VoxelManip pass is written and calc_lighting is called, do a second pass to place schematics using `minetest.place_schematic`.

For each surface biome column that was generated:

**Grass placement (all surface biomes):**
- After terrain generation, for each surface position (the first air block above solid ground):
  - 1 in 30 chance: place `grass_patch` schematic at this position
  - 1 in 80 chance: place `grass_tall_patch` schematic (overrides grass_patch if both trigger)
- Use a position hash for deterministic placement.

**Skeleton placement (specific biomes):**
- Rib Fields: 1 in 400 surface positions — place a random skeleton variant. Thematically appropriate: old bones among the ribs.
- Abscess Marsh: 1 in 500 surface positions — place `skeleton_small` only (corroded remains).
- Molar Peaks: 1 in 600 surface positions — place `skeleton_ribcage` among the teeth.
- Vein Flats: 1 in 800 surface positions — place `skeleton_small` (rare).
- Nerve Thicket and Coral Cliffs: no skeletons.

**Fleshy mushroom placement (specific biomes):**
- Nerve Thicket: 1 in 100 surface positions — place a random mushroom variant. Dense fungal undergrowth beneath the nerve canopy.
- Coral Cliffs: 1 in 200 surface positions on shelf surfaces — place `flesh_mushroom_small` or `flesh_mushroom_medium`.
- Abscess Marsh: 1 in 150 surface positions — place `flesh_mushroom_small` (stunted growth in toxic environment).
- Rib Fields: 1 in 250 surface positions — place random mushroom variant between ribs.
- Vein Flats: 1 in 300 surface positions — place `flesh_mushroom_small` only.
- Molar Peaks: no mushrooms.

**Cave mushroom/skeleton placement (cave layer):**
- In the organic cave layer (y=27006-27697), on cave floor positions:
  - 1 in 200 floor positions: place `flesh_mushroom_small` (they grow in caves too)
  - 1 in 800 floor positions: place `skeleton_small` (ancient remains in the caves)

When placing schematics via `minetest.place_schematic`, use the position hash to select which variant to place (e.g., `hash % 3` picks one of 3 skeleton variants). Set `force_placement = false` and `replacements = nil`.

Important: `minetest.place_schematic` must be called AFTER the VoxelManip has been written back (after `vm:write_to_map()` and `vm:update_liquids()`), because place_schematic works on the map directly, not on VoxelManip data. This means schematic placement is a separate pass after the main terrain generation.

To avoid excessive place_schematic calls per chunk (which could cause lag), limit total schematic placements to a maximum of 15-20 per chunk. Track the count and stop placing once the limit is reached. Prioritize by: grass first (most common, cheapest), then mushrooms, then skeletons (rarest).

---

## Summary

| Prompt | Change | Primary Files |
|--------|--------|---------------|
| 1 | Python script generates all textures (static + animated + plantlike) | `bio_generate_textures.py` (new) |
| 2 | Update all node tile references to use generated textures | `bio_nodes.lua`, all `biomes/*.lua` |
| 3 | Halve surface amplitudes again + fix thin noise lines + fix floating blocks | All `biomes/*.lua`, `bio_mapgen.lua` |
| 4 | New decoration nodes + Lua table schematics (skeletons, mushrooms, grasses) | `bio_nodes.lua`, `bio_schematics.lua` (new), `init.lua` |
| 5 | Place schematics in biomes via post-VoxelManip pass | `bio_schematics.lua`, `bio_mapgen.lua` |

## New Files Created

| File | Purpose |
|------|---------|
| `bio_generate_textures.py` | Python/Pillow script generating all bio dimension textures |
| `bio_schematics.lua` | Schematic definitions + decoration placement logic |

## New Nodes Added

| Node | Type | Used In |
|------|------|---------|
| lazarus_space:skeleton_bone | Structural | Skeleton schematics |
| lazarus_space:skeleton_skull | Structural | Skeleton schematics |
| lazarus_space:skeleton_rib | Nodebox | Skeleton schematics |
| lazarus_space:flesh_mushroom_stem | Structural | Mushroom schematics |
| lazarus_space:flesh_mushroom_cap | Structural | Mushroom schematics |
| lazarus_space:flesh_mushroom_cap_edge | Nodebox | Mushroom schematics |
| lazarus_space:flesh_mushroom_glow | Light source (6) | Mushroom schematics |
| lazarus_space:bio_grass_1 | Plantlike | Grass schematics |
| lazarus_space:bio_grass_2 | Plantlike | Grass schematics |
| lazarus_space:bio_grass_3 | Plantlike | Grass schematics |
| lazarus_space:bio_grass_tall | Plantlike (2x scale) | Tall grass schematics |

## Key Notes for SpecSwarm

- All placeholder textures are simple single-color PNGs with subtle pixel noise — user will hand-edit later.
- Plantlike textures have transparent backgrounds with simple silhouette shapes.
- Animated liquid textures are 16x128 vertical strips (8 frames of 16x16).
- Schematics use Lua table format (human-readable, editable) with probability values for variety.
- Schematic placement happens AFTER VoxelManip write-back, using minetest.place_schematic.
- Maximum 15-20 schematic placements per chunk to prevent lag.
- Surface biome amplitudes are halved for the SECOND time (total reduction to ~25% of UPDATE_027 values).
