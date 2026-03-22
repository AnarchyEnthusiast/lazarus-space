# PROMPTS_005_UPDATE_027 — Biological Dimension Terrain Generation

SpecSwarm command: `/build`

This update adds a complete biological dimension with terrain generation at y=26927 to y=30927. The implementation adds shared node registrations, a mapgen framework with a modular biome registration system, non-biome layer generation (frozen asteroids, death space barrier, organic caves, jelly membrane, red sea, upper asteroids, ceiling membrane), and six individually modular surface biomes each in their own file under a `biomes/` subdirectory.

No mobs. No mob spawning. Terrain generation only.

---

## Prompt 1 of 12 — Mapgen Framework, Biome Registration API, and Init Changes

### File: `bio_mapgen.lua` (new file) and `init.lua` (modify)

Create the file `bio_mapgen.lua` containing the main terrain generation framework for the biological dimension. Also modify `init.lua` to load the new files.

#### Init Changes

Add two `dofile` lines at the end of `init.lua`, after the existing `dofile` calls:
- First: load `bio_nodes.lua` (shared node registrations — this file is created in prompt 2)
- Second: load `bio_mapgen.lua`

The `bio_mapgen.lua` file itself is responsible for loading individual biome files from the `biomes/` subdirectory after the framework is set up.

#### Layer Boundary Constants

Define named local constants for every layer boundary in the biological dimension:
- Frozen Asteroid Field: y=26927 to y=26997 (70 blocks)
- Death Space Barrier: y=26997 to y=27006 (9 blocks)
- Organic Caves: y=27006 to y=27697 (691 blocks)
- Jelly/Plasma Membrane: y=27697 to y=27712 (15 blocks)
- Red Sea: y=27712 to y=27775 (63 blocks)
- Surface Biomes: base at y=27775, heights vary per biome
- Upper Asteroid Field: y=28200 to y=30920
- Ceiling Membrane: y=30920 to y=30927 (7 blocks)

#### Surface Biome Registration API

Create a registration table `lazarus_space.bio_surface_biomes` (initially empty). Create a registration function `lazarus_space.register_surface_biome(definition)` that biome files call to register themselves. Each biome definition is a table containing:
- `name`: string identifier (e.g. `"rib_fields"`)
- `noise_min`: lower bound of the 2D surface biome noise range where this biome is active
- `noise_max`: upper bound of the 2D surface biome noise range where this biome is active
- `base_height_offset`: how many blocks above y=27775 the biome's base ground sits
- `height_amplitude`: multiplier for the large-scale terrain height noise
- `detail_amplitude`: multiplier for the small-scale detail noise
- `get_content_ids`: a function called once during content ID caching that receives the content ID table and populates it with biome-specific content IDs
- `generate_column`: a function called once per x,z column within this biome, receiving a context table with the column's x, z, terrain height (already computed by the framework using two-layer Perlin with erosion), raw noise values, detail weight, the VoxelManip data array, the VoxelArea, and the content ID table. The function fills in voxels for this column from the surface base up to whatever height the biome needs. It is responsible for everything above the red sea ceiling (y=27775) in its noise range.
- `transition_blend`: optional function for blending materials at biome boundaries

The registration function validates the definition and inserts it into the biome table sorted by `noise_min`.

#### Noise System

Create the following Perlin noise objects, initialized lazily on first mapgen call and cached for reuse. All noise map flat buffers are reused across calls.

**2D Noises** (sampled once per x,z column):
- `cave_biome_noise`: spread 200, octaves 3, persistence 0.5. Selects which of the three cave biomes applies at each column.
- `surface_biome_noise`: spread 300, octaves 3, persistence 0.5. Selects which surface biome applies at each column.
- `terrain_height_noise`: spread 100, octaves 4, persistence 0.5. The large-scale terrain shape layer — this is the first of the two Perlin layers for surface terrain.
- `terrain_detail_noise`: spread 30, octaves 3, persistence 0.5. The small-scale detail layer — this is the second of the two Perlin layers for surface terrain. Its contribution is attenuated by the erosion system.

**3D Noises** (sampled per voxel):
- `cave_shape_noise`: spread 30, octaves 4, persistence 0.5. Determines solid vs void in the organic cave layer.
- `cave_detail_noise`: spread 10, octaves 2, persistence 0.5. Adds fine variation to cave wall materials and features.
- `asteroid_shape_noise`: spread 15, octaves 3, persistence 0.5. Defines asteroid forms in both asteroid fields.
- `jelly_shape_noise`: spread 8, octaves 2, persistence 0.5. Creates bubbly jelly formations in the membrane layer.
- `red_sea_debris_noise`: spread 20, octaves 2, persistence 0.5. Places debris clusters in the red sea.

The 2D noise index formula is: `(z - minp.z) * sidelen + (x - minp.x) + 1`. The 3D noise index formula is: `(z - minp.z) * ylen * sidelen + (y - minp.y) * sidelen + (x - minp.x) + 1`.

#### Two-Layer Perlin Surface Height with Erosion Attenuation

When computing the terrain height for a surface biome column, the framework uses a two-layer approach:

1. Sample the `terrain_height_noise` at the current x,z position to get the large-scale height value.
2. Compute the gradient (steepness) of the large-scale noise by also sampling it at x-1, x+1, z-1, z+1. Calculate the gradient magnitude as `sqrt(((h_east - h_west) / 2)^2 + ((h_north - h_south) / 2)^2)`.
3. Convert the gradient magnitude into a detail weight. When the gradient is zero (flat terrain), the detail weight is 1.0 (full detail). As the gradient increases, the detail weight decreases toward 0.0. Use a smooth falloff: `detail_weight = max(0, 1 - gradient_magnitude * erosion_factor)` where `erosion_factor` is a tuning constant (start with a value around 2.0-3.0 and note it as tunable).
4. Sample the `terrain_detail_noise` at the current x,z position.
5. The final terrain height for the column is: `y=27775 + biome.base_height_offset + terrain_height_value * biome.height_amplitude + terrain_detail_value * biome.detail_amplitude * detail_weight`.

This makes steep slopes smoother (less micro-detail) and flat areas more textured, resembling natural erosion patterns where sediment accumulates on flats and washes off slopes.

Important: The neighbor samples for gradient computation (x±1, z±1) should use the same noise object, not a separate noise map. Since the 2D noise is sampled as a flat map for the chunk, the neighbor values may be directly adjacent in the flat buffer for interior positions. For columns on chunk edges, sample the noise object directly at the neighbor coordinates.

The framework computes terrain height per-column and passes it to the active biome's `generate_column` function. The biome does NOT need to recompute height — it receives the final value.

#### Content ID Caching

Register a `minetest.register_on_mods_loaded` callback that:
1. Resolves all shared node content IDs (from bio_nodes.lua) via `minetest.get_content_id()` and stores them in a local table `c` (e.g. `c.flesh`, `c.bone`, `c.air`, `c.death_space`, etc.).
2. Iterates through all registered surface biomes and calls each one's `get_content_ids(c)` function so biomes can add their own IDs to the shared table.
3. Also caches `c.air`, `c.ignore`, and any default nodes needed by non-biome layers.

#### Main `register_on_generated` Callback

Register a single `minetest.register_on_generated` callback that:
1. Early-exits if the chunk's y-range does not overlap y=26927 to y=30927.
2. Acquires the VoxelManip and data array.
3. Generates all needed noise maps for this chunk (2D maps using `get_2d_map_flat`, 3D maps using `get_3d_map_flat`).
4. Determines which layers overlap this chunk using boolean flags.
5. Iterates through every position in z-y-x order (x innermost) for sequential index advancement.
6. For each position, checks which layer it belongs to by y-coordinate and delegates to the appropriate layer generation logic.
7. For positions in the surface biome range (y >= 27775): determines the biome from the 2D surface biome noise for that column, looks up the registered biome, and calls its `generate_column` function (once per column, not per voxel — the biome function handles all y values in the column).
8. After all positions are processed, writes the modified data back to the VoxelManip and calls `calc_lighting`.

The main loop should determine the biome once per x,z column (when y is at its starting value for that column) and reuse the result for all y positions in the column. Similarly, the two-layer terrain height with erosion is computed once per column.

#### Biome File Loading

After all framework code is defined, load each biome file from the `biomes/` subdirectory using `dofile`. The loading order does not matter since biomes self-register. Load all `.lua` files found in the `biomes/` directory. This allows adding or removing a biome by simply adding or removing its file from the directory.

To enumerate files in the `biomes/` subdirectory, use `minetest.get_dir_list(modpath .. "/biomes", false)` to get a list of files, filter for `.lua` extension, and `dofile` each one.

---

## Prompt 2 of 12 — Shared Node Registrations

### File: `bio_nodes.lua` (new file)

Create the file `bio_nodes.lua` that registers all node types shared across multiple biomes or layers. Nodes that are unique to a single surface biome are NOT registered here — those go in the individual biome files under `biomes/`.

All nodes use Minetest's texture modifier system to colorize existing default textures instead of custom texture files. This means tiles use strings like `"default_stone.png^[colorize:#RRGGBB:alpha"` to overlay color on existing textures.

#### Structural Blocks

Register the following structural nodes:

- `lazarus_space:flesh` — The universal base ground material. Use `default_dirt.png` colorized dark red (#8B0000:180). Groups: crumbly=2, choppy=2. Standard dirt sounds.
- `lazarus_space:flesh_dark` — Darker variant. Use `default_dirt.png` colorized very dark red (#4A0000:200). Same groups and sounds as flesh.
- `lazarus_space:flesh_wet` — Slippery variant. Use `default_dirt.png` colorized dark red (#6B0000:180) with a slight gloss. Same groups. Add `slippery=2` to groups.
- `lazarus_space:bone` — Hard skeletal material. Use `default_stone.png` colorized off-white/cream (#F5F0DC:160). Groups: cracky=1, level=2. Stone sounds.
- `lazarus_space:enamel` — Hardest biological material. Use `default_stone.png` colorized bright white (#FFFFF0:140). Groups: cracky=1, level=3 (very hard). Stone sounds.
- `lazarus_space:dentin` — Tooth interior material. Use `default_stone.png` colorized pale yellow (#F5E6B8:160). Groups: cracky=2. Stone sounds.
- `lazarus_space:spongy_bone` — Porous bone. Use `default_stone.png` colorized cream (#E8DCC8:150). Groups: cracky=2, crumbly=1. Stone sounds.
- `lazarus_space:cartilage` — Flexible structural material. Use `default_stone.png` colorized blue-white (#D8E8F0:140). Groups: cracky=2, choppy=2. A mix of stone and wood sounds.
- `lazarus_space:membrane` — Semi-transparent thin floor material. Drawtype `glasslike`. Use `default_glass.png` colorized pale pink (#FFD0D0:80). `use_texture_alpha = "blend"`. Groups: cracky=3, oddly_breakable_by_hand=2. Glass sounds.
- `lazarus_space:frozen_rock` — Asteroid material. Use `default_stone.png` colorized dark blue-grey (#3A3A4F:180). Groups: cracky=1, level=2. Stone sounds.
- `lazarus_space:frozen_ice` — Asteroid surface ice. Use `default_ice.png` colorized blue-white (#C8D8F0:60). Groups: cracky=2, slippery=3. Ice/glass sounds.
- `lazarus_space:death_space` — Absolute barrier. **Indestructible**, non-walkable, maximum movement resistance, lethal. `walkable = false`, `pointable = false`, `diggable = false`, `damage_per_second = 20`, `post_effect_color = {a=255, r=0, g=0, b=0}` (fully opaque black — players inside see nothing), `drowning = 1`. Use `default_obsidian.png` colorized pure black (#000000:255). Empty groups. No sounds. `on_blast = function() end` to be immune to explosions.
- `lazarus_space:jelly` — Gelatinous membrane material. Drawtype `glasslike`. Use `default_glass.png` colorized translucent pink-red (#FF8888:120). `use_texture_alpha = "blend"`. Groups: cracky=3, crumbly=2. Glass sounds.
- `lazarus_space:jelly_glow` — Glowing jelly variant. Same as jelly but with `light_source = 5`. Colorize slightly brighter (#FFAAAA:100).
- `lazarus_space:ceiling_membrane` — Indestructible ceiling boundary. Use `default_stone.png` colorized dark fleshy red (#5A0A0A:200). `diggable = false`, `pointable = false`. Empty groups. `on_blast = function() end`.
- `lazarus_space:ceiling_vein` — Barely glowing ceiling accent. Same as ceiling_membrane but with `light_source = 2` and colorized dark purple-red (#6A1A2A:180).
- `lazarus_space:asteroid_shell` — Upper asteroid material. Use `default_stone.png` colorized dark brown-grey (#4A3A30:180). Groups: cracky=1, level=2. Stone sounds.
- `lazarus_space:asteroid_glow` — Rare glowing asteroid spot. Same as asteroid_shell but with `light_source = 3` and slightly warmer colorize (#6A4A30:160).

#### Shared Decorative/Feature Blocks

- `lazarus_space:muscle` — Muscular tissue. Use `default_dirt.png` colorized deep red (#A01010:180). Groups: crumbly=2, choppy=2. Dirt sounds.
- `lazarus_space:sinew` — Connective tissue strands. Use `default_wood.png` colorized off-white/pinkish (#E0C0B0:160). Groups: choppy=2, snappy=2. Wood sounds.
- `lazarus_space:blood_clot` — Dense clot material for red sea debris. Use `default_dirt.png` colorized very dark red (#3A0000:200). Groups: crumbly=1, choppy=2. Dirt sounds.
- `lazarus_space:fibrous_strand` — Thin organic connectors. Use `default_wood.png` colorized pale red-brown (#C0A090:140). Groups: choppy=2, snappy=3. Wood sounds.
- `lazarus_space:glowing_mushroom` — Cave floor light source. Drawtype `plantlike`. Use `default_grass_1.png` (or similar plant texture) colorized green-yellow (#AAFF80:140). `light_source = 4`. `walkable = false`. Groups: snappy=3, attached_node=1.

#### Custom Liquids

Register four liquid types. Each requires a source and flowing node pair following Minetest's standard liquid registration pattern. Use animated default water textures with colorize overlays.

- **Red Sea Liquid** (`lazarus_space:red_sea_source` and `lazarus_space:red_sea_flowing`):
  - Normal viscosity (1)
  - No damage
  - `post_effect_color = {a=245, r=60, g=0, b=0}` — extremely opaque dark crimson, near-total vision block
  - Standard drowning
  - Liquid range: 8 (default)
  - Use `default_water_source_animated.png` colorized dark red (#600000:200) for source, `default_water_flowing_animated.png` colorized matching for flowing
  - `liquid_alternative_source` and `liquid_alternative_flowing` cross-references

- **Bile Liquid** (`lazarus_space:bile_source` and `lazarus_space:bile_flowing`):
  - Moderate viscosity (4)
  - `damage_per_second = 2`
  - `post_effect_color = {a=200, r=120, g=130, b=10}` — murky yellow-green
  - `liquid_viscosity = 4`
  - `liquid_range = 4` (short flow)
  - Use `default_water_source_animated.png` colorized yellow-green (#808A00:180)

- **Pus Liquid** (`lazarus_space:pus_source` and `lazarus_space:pus_flowing`):
  - High viscosity (7), barely flows
  - `damage_per_second = 3`
  - `post_effect_color = {a=230, r=180, g=170, b=50}` — thick yellow
  - `liquid_viscosity = 7`
  - `liquid_range = 2` (very short flow)
  - Use `default_water_source_animated.png` colorized thick yellow (#B0A830:200)

- **Marrow Liquid** (`lazarus_space:marrow_source` and `lazarus_space:marrow_flowing`):
  - High viscosity (6)
  - No damage
  - `post_effect_color = {a=180, r=160, g=100, b=30}` — yellow-red tint
  - `liquid_viscosity = 6`
  - `liquid_range = 3`
  - Use `default_water_source_animated.png` colorized yellow-red (#A06420:170)

All liquid nodes should have `is_ground_content = false` and be in `group:liquid`. Both source and flowing variants need the standard animated texture setup with `animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0}`.

---

## Prompt 3 of 12 — Simple Layer Generation (Frozen Asteroids, Death Space, Jelly Membrane, Red Sea, Ceiling Membrane)

### File: `bio_mapgen.lua` (add to existing)

Add generation logic for the five simplest layers directly in the main mapgen callback in `bio_mapgen.lua`. These are non-biome layers that do not use the modular biome registration system.

#### Frozen Asteroid Field (y=26927 to y=26997)

Use the 3D `asteroid_shape_noise`. Where the noise value exceeds 0.4, place `frozen_rock`. Where the noise is between 0.35 and 0.4 (the surface fringe), place `frozen_ice` to create ice-crusted asteroid exteriors. Everything else in this range is air. The noise spread of 15 creates asteroids ranging from roughly 3 to 25 blocks. No light sources in this layer.

#### Death Space Barrier (y=26997 to y=27006)

Every position in this y-range is filled with `death_space` blocks unconditionally. No noise, no variation, no gaps. The barrier is absolute.

#### Jelly/Plasma Membrane (y=27697 to y=27712)

Use the 3D `jelly_shape_noise` combined with a vertical gradient that transitions from solid jelly at the bottom to open space at the top. The noise threshold at each height is: `base_threshold + (y - 27697) * gradient_factor`, where `base_threshold` is -0.3 and `gradient_factor` is 0.06 per block. This means the bottom 3-4 blocks are almost entirely solid jelly and the top 3-4 blocks are almost entirely open.

Where jelly is placed, roughly 1 in 8 blocks is the `jelly_glow` variant (use a position hash modulo 8 to determine this). This provides dim reddish-pink illumination.

Gaps in the membrane where positions are air allow red sea liquid from above to flow down naturally into the uppermost cave areas.

#### Red Sea (y=27712 to y=27775)

The primary fill is `red_sea_source` blocks. Every position in this y-range that is not occupied by debris is filled with red sea liquid.

Debris placement uses the 3D `red_sea_debris_noise`:
- Noise above 0.6: `blood_clot` blocks (dense dark red clusters)
- Noise above 0.55 but at or below 0.6: `fibrous_strand` blocks
- Noise above 0.5 but at or below 0.55 AND position is in the bottom third of the sea (y < 27733): `flesh` and `muscle` blocks (organ chunks, alternate based on position hash)

This creates the correct distribution: sparse enough to swim through, denser near the bottom, sparser near the top.

#### Ceiling Membrane (y=30920 to y=30927)

All positions in this range are filled with `ceiling_membrane` blocks. Positions where the `cave_detail_noise` (reused from the cave layer, evaluated at ceiling heights) exceeds 0.3 are replaced with `ceiling_vein` blocks (barely glowing, light level 2).

Below the membrane (y=30915 to y=30920), stalactite-like growths hang down: where the 3D `asteroid_shape_noise` value exceeds 0.5 at the position, place `flesh_dark` or `muscle` blocks (alternate based on position hash). The threshold increases by 0.08 per block of distance below the membrane (so formations taper off: 0.5 at y=30919, 0.58 at y=30918, 0.66 at y=30917, etc.), creating stalactites of varying length that are most dense right at the ceiling and sparse further down.

---

## Prompt 4 of 12 — Organic Cave Layer

### File: `bio_mapgen.lua` (add to existing)

Add the organic cave layer generation logic (y=27006 to y=27697) to `bio_mapgen.lua`. This is the most complex non-biome layer. The three cave biomes (intestinal, tumor, marrow) are NOT modular — they are all implemented directly in this file.

#### Cave Biome Selection

Use the 2D `cave_biome_noise` value at each x,z column to select the cave biome:
- Values below -0.3: Intestinal Caves
- Values from -0.3 to 0.3: Tumor Caves
- Values above 0.3: Marrow Caves

In transition zones (within 0.1 of each boundary at -0.3 or 0.3), blocks are randomly assigned to either adjacent biome probabilistically. Compute the fractional distance from the noise value to the boundary, hash the full 3D position (not just x,z), and compare the hash modulo 100 against the fractional distance scaled to 0-100. This creates a 20-40 block wide gradual material blend between cave biomes.

#### Cave Carving

The 3D `cave_shape_noise` determines whether each position is solid wall or open cave void. The carving threshold varies by biome:
- Intestinal: threshold 0.15 (more solid, tight tunnels, roughly 35% open)
- Tumor: threshold 0.0 (irregular, roughly 50% open)
- Marrow: threshold -0.15 (more open, roughly 65% open)

Where the noise value exceeds the biome's threshold, the position is solid (wall material). Below the threshold, the position is air (cave void).

A "floor position" is defined as: the current position is solid AND the position directly above (y+1) is air/void. A "ceiling position" is: the current position is solid AND the position directly below (y-1) is air/void.

#### Intestinal Caves — Wall Materials and Features

Solid positions alternate between `flesh_wet` and `muscle` based on the `cave_detail_noise`: detail noise above 0 places `flesh_wet`, at or below 0 places `muscle`.

`mucus` blocks (defined below) are placed on floor positions with moderate frequency: roughly 1 in 4 floor positions, determined by position hash.

Bile liquid source blocks fill depressions in the lower third of the cave layer (y < 27237). Where the 3D cave shape noise is just barely below the carving threshold (within 0.02 below it), place `bile_source` instead of air. This creates shallow caustic pools at the lowest points of intestinal chambers.

Register the `lazarus_space:mucus` node in this section of bio_mapgen.lua (or better: register it in bio_nodes.lua as a shared cave node since it is only used in caves). Mucus: use `default_dirt.png` colorized yellow-green (#A0B030:160), groups: crumbly=3, slippery=3. Dirt sounds.

#### Tumor Caves — Wall Materials and Features

Solid positions use `flesh`, `flesh_dark`, and `necrotic_tissue` (defined below) with noise-driven variation. Use the cave detail noise: below -0.3 is `necrotic_tissue`, -0.3 to 0.3 is `flesh`, above 0.3 is `flesh_dark`.

Cyst formations: where the cave shape noise is in a narrow band between the threshold and threshold + 0.05 (i.e. just barely solid), place `cyst_wall` blocks instead of normal wall material. This creates hollow pockets at cave boundaries since the air side of the threshold is right next to these cyst wall blocks.

`glow_infected` blocks appear rarely (roughly 1 in 200 floor positions, determined by position hash) as small light sources.

Register in bio_nodes.lua:
- `lazarus_space:necrotic_tissue` — Use `default_dirt.png` colorized grey-brown (#5A4A3A:180). Groups: crumbly=2. Dirt sounds.
- `lazarus_space:cyst_wall` — Semi-transparent, breakable. Drawtype `glasslike`. Use `default_glass.png` colorized pale yellow (#E8E0A0:100). `use_texture_alpha = "blend"`. Groups: cracky=3, oddly_breakable_by_hand=1. Glass sounds.
- `lazarus_space:glow_infected` — Infected fluid pool light source. Use `default_dirt.png` colorized sickly yellow-green (#A0A020:160). `light_source = 4`. Groups: crumbly=2.

#### Marrow Caves — Wall Materials and Features

Walls are `spongy_bone` and `bone` with noise-driven variation. Cave detail noise above 0 places `spongy_bone`, at or below 0 places `bone`.

Floor positions use `marrow` blocks (defined below). `glowing_marrow` blocks appear rarely on floors (roughly 1 in 150 floor positions).

Marrow liquid pools: where the 3D cave shape noise is just barely below the carving threshold (within 0.02 below it), place `marrow_source` instead of air. This creates shallow pools and slow rivers at the lowest points of marrow chambers.

Register in bio_nodes.lua:
- `lazarus_space:marrow` — Bouncy floor material. Use `default_dirt.png` colorized yellow-red (#C08030:160). Groups: crumbly=2, bouncy=70 (high bounce). Dirt sounds.
- `lazarus_space:glowing_marrow` — Light-emitting marrow. Same as marrow but with `light_source = 5` and colorize slightly brighter (#D0A050:140).

#### Shared Cave Features

Glowing mushrooms (`glowing_mushroom` from bio_nodes.lua) are placed on cave floor positions in all three biomes at a rate of roughly 1 per 300-500 floor positions, determined by a hash of the position. Only place them where the position above is air and the floor position itself would otherwise be a solid block — replace the would-be solid block's top with the mushroom by placing air at the floor position and the mushroom at that same position (plantlike nodes sit on the block below, so place the mushroom in the air space above the floor and ensure the block below remains solid).

Actually, correction: plantlike nodes with `attached_node` group need a solid block below them. So place the glowing mushroom in the air position directly above a floor block. The floor block stays solid, the mushroom occupies the first air block above it.

---

## Prompt 5 of 12 — Upper Asteroid Field

### File: `bio_mapgen.lua` (add to existing)

Add the upper asteroid field generation logic (y=28200 to y=30920) to `bio_mapgen.lua`.

#### Barren Asteroids with Density Gradient

The `asteroid_shape_noise` determines asteroid placement. The noise threshold varies linearly with altitude to create a bottom-sparse, top-dense gradient:
- At y=28200 (bottom): threshold 0.65 (very sparse, only strongest noise peaks form asteroids)
- At y=29560 (middle): threshold 0.50 (moderate density)
- At y=30920 (top): threshold 0.35 (dense field)

Interpolate the threshold linearly between these control points based on the current y position.

Where the noise exceeds the threshold, place `asteroid_shell`. Asteroid surfaces (where the noise is within 0.03 above the threshold) occasionally get biological crusting: `flesh` or `sinew` blocks at a rate of roughly 1 in 20 surface positions (determined by position hash).

Rare `asteroid_glow` nodes replace `asteroid_shell` at about 1 in 500 positions (determined by position hash).

#### Hollow Livable Asteroids

These are generated using a cell-based placement system with cells of 200x200x200 blocks. For each cell:
1. Hash the cell's grid coordinates (cell_x, cell_y, cell_z) with a fixed seed to produce a deterministic PcgRandom generator.
2. Use the generator to determine if this cell contains a hollow asteroid (roughly 1 in 10 chance).
3. If yes, the generator determines the center position (random within the cell but at least 50 blocks from any cell edge) and radius (20-40 blocks).

For each position in the mapgen, check the current cell and all 26 neighboring cells for hollow asteroids. If any hollow asteroid sphere contains the position:
- Outer shell (distance from center > radius - 7 and distance <= radius): `asteroid_shell` blocks. From the outside these look identical to barren asteroids.
- Inner cavity (distance from center < radius - 7):
  - Bottom third of interior (y < center.y - radius/3): `default:dirt` blocks, with the top layer being `default:dirt_with_grass`
  - Top dome (distance from center between radius - 10 and radius - 7): `asteroid_glow` with `light_source` boosted to 12 (register a separate node `lazarus_space:asteroid_glow_ceiling` with light_source=12 in bio_nodes.lua for this purpose, using the same texture as asteroid_glow but with warm white colorize). This simulates warm sky light inside the hollow.
  - Positions between the grass layer and the dome: air
  - Small water features: where a secondary check (use cave_detail_noise evaluated at the position, below -0.4) is true AND the position is within the bottom quarter of the interior AND at the same y level as the grass layer, place `default:water_source` instead of dirt/grass. This creates 1-2 small ponds per hollow asteroid.

Entry tunnels: for each hollow asteroid, carve 2-3 block wide tunnels through the shell along two opposing cardinal directions (determined by the cell hash) at the equator height (y = center.y). Tunnels are carved by setting positions to air where they fall within the tunnel cylinder (radius 1.5 blocks from the tunnel axis) AND within the shell zone.

The hollow asteroid check runs BEFORE the barren asteroid noise check, so hollow asteroids override noise-based generation.

#### Tissue Bridges

After asteroid placement for a position, check if it could be a bridge location: the position is currently air, but there is high asteroid noise (above threshold + 0.1) at positions roughly 15-30 blocks away in at least two opposing cardinal directions. If so, place `fibrous_strand` or `sinew` (alternate by position hash) at a rate of about 1 in 3 qualifying positions. This creates organic connections between nearby asteroids.

Note: this check is computationally expensive if done naively. Limit it to positions where the local noise is in a specific narrow range (e.g. between threshold - 0.15 and threshold - 0.05, meaning "almost but not quite an asteroid") to avoid checking every air block.

---

## Prompt 6 of 12 — Surface Biome: Rib Fields

### File: `biomes/rib_fields.lua` (new file)

Create a new file `biomes/rib_fields.lua` that registers the Rib Fields surface biome using the `lazarus_space.register_surface_biome()` API.

#### Biome Registration

Register with:
- `name`: `"rib_fields"`
- `noise_min`: -1.0 (captures everything below -0.6 plus the full lower tail)
- `noise_max`: -0.6
- `base_height_offset`: 5
- `height_amplitude`: 10 (5-15 blocks of variation)
- `detail_amplitude`: 3

#### Biome-Specific Nodes

Register in this file:
- `lazarus_space:gristle` — Cartilage-like ground accent. Use `default_stone.png` colorized grey-pink (#C0A8A0:150). Groups: cracky=2, crumbly=1. Stone sounds.
- `lazarus_space:bone_spur` — Jagged bone protrusion for rib bases. Use `default_stone.png` colorized cream-white (#E8E0D0:160). Groups: cracky=1, level=2. Stone sounds.

#### Content ID Registration

The `get_content_ids` function caches IDs for: `gristle`, `bone_spur`, plus shared nodes `flesh`, `bone`, `cartilage`, `sinew`, `muscle`.

#### Column Generation

The `generate_column` function:

**Ground fill**: From y=27775 up to the computed terrain height, fill with `flesh`. The top 1-2 blocks of the ground surface alternate between `flesh` and `cartilage` based on the detail noise, with occasional `gristle` patches (roughly 1 in 6 surface positions).

**Rib structures**: Ribs use a cell-based system along the x-axis. The world is divided into cells 50 blocks wide. Each cell's x-coordinate (floored to the cell grid) is hashed with a fixed seed to produce a PcgRandom. The generator determines:
- Exact rib center x-position within the cell
- Rib peak height: 80-150 blocks above the local ground level
- Rib half-span at ground level: 15-25 blocks

Each rib is an arch: at ground level, the two legs are at `x = rib_center ± half_span`. At the peak, both legs meet at `x = rib_center`. The arch profile curves inward with height — use a parabolic or cosine curve so the arch narrows smoothly from base to peak. Rib thickness is about 4 blocks.

For each x,z position, check the nearest 2-3 rib cells. If the position falls within a rib's arch profile (the horizontal distance from the arch centerline at this height is less than the rib thickness / 2), place `bone`.

At the base of each rib (lowest 5 blocks), create a joint cluster of `cartilage` and `bone_spur` blocks spreading 2-3 blocks around the rib base.

**Sinew connective tissue**: Between ribs at specific heights (roughly 30%, 50%, and 70% of the rib height), horizontal spans of `sinew` blocks connect adjacent rib arches. These are thin (1 block tall, 1-2 blocks wide) and span from one rib to the next along the z-axis.

The biome should check nearby cells when the column is first processed, cache the rib parameters for the current column, and reuse them for all y values.

---

## Prompt 7 of 12 — Surface Biome: Molar Peaks

### File: `biomes/molar_peaks.lua` (new file)

Create a new file `biomes/molar_peaks.lua` that registers the Molar Peaks surface biome.

#### Biome Registration

Register with:
- `name`: `"molar_peaks"`
- `noise_min`: -0.6
- `noise_max`: -0.25
- `base_height_offset`: 5
- `height_amplitude`: 15 (5-20 blocks of undulating base terrain)
- `detail_amplitude`: 4

#### Biome-Specific Nodes

Register in this file:
- `lazarus_space:pulp` — Soft tooth interior. Use `default_dirt.png` colorized deep pink-red (#C03030:170). Groups: crumbly=2, choppy=2. Dirt sounds.
- `lazarus_space:gum_tissue` — Ground material. Use `default_dirt.png` colorized pink (#D08080:160). Groups: crumbly=2. Dirt sounds.

#### Content ID Registration

Cache IDs for: `pulp`, `gum_tissue`, plus shared nodes `bone`, `enamel`, `dentin`, `flesh`, and `nerve_fiber` (nerve_fiber is from the nerve thicket biome — if nerve_thicket.lua has not been loaded, use `flesh` as fallback for interior root channels; however, register `lazarus_space:nerve_channel` as a local node for tooth interiors instead, using `default_wood.png` colorized pale pink-white (#E0C0C0:140), groups choppy=2 crumbly=2).

Actually, to avoid cross-biome dependencies, register `lazarus_space:nerve_channel` in this file specifically for tooth root interiors. Use `default_wood.png` colorized pale pink-white (#E0C0C0:140). Groups: choppy=2, crumbly=2. Wood sounds.

#### Column Generation

**Ground fill**: From y=27775 up to terrain height, fill with `gum_tissue`.

**Tooth structures**: Use a 2D cell grid of 100x100 blocks. Each cell's (cell_x, cell_z) coordinates are hashed with a fixed seed. The generator determines:
- Whether a tooth exists (roughly 70% chance)
- Tooth center position within the cell (x, z)
- Tooth height: 200-400 blocks above ground
- Base radius: 15-35 blocks

The tooth profile varies with height (where `frac` is the fraction of total height from bottom to top):
- Root zone (frac 0 to 0.30): radius = base_radius * (1.0 - frac * 0.5) — widest at bottom, narrowing upward
- Neck (frac 0.30 to 0.50): radius = base_radius * 0.65 — narrowest zone
- Crown (frac 0.50 to 0.90): radius = base_radius * (0.65 + (frac - 0.5) * 0.5) — widens slightly
- Grinding surface (frac 0.90 to 1.0): flat top, radius = crown radius at frac 0.9

Material selection based on horizontal distance from tooth center (`dist`) and height fraction (`frac`):
- Outer 15% of radius at frac > 0.85: `enamel`
- Outer 30% of radius elsewhere: `dentin`
- Inner core at frac > 0.50: `pulp`
- Inner core at frac <= 0.50: either `nerve_channel` or air. Use the `cave_detail_noise` (from the framework's noise system) evaluated at the position: if the noise is below -0.2, place air to create winding tunnels through the root system. Otherwise place `nerve_channel`. This makes explorable nerve channels in the roots.

**Smaller teeth**: A finer cell grid of 50x50 blocks generates minor teeth at 20-60% the dimensions of major molars. Same logic, scaled down. Only generate a minor tooth if no major tooth from the 100x100 grid already occupies that area (check if the distance from any nearby major tooth center is greater than the major tooth's base radius + 10).

For each column, check the current cell and 8 surrounding cells in both the major and minor grids. Cache tooth parameters per column.

---

## Prompt 8 of 12 — Surface Biome: Vein Flats

### File: `biomes/vein_flats.lua` (new file)

Create a new file `biomes/vein_flats.lua` that registers the Vein Flats surface biome.

#### Biome Registration

Register with:
- `name`: `"vein_flats"`
- `noise_min`: -0.25
- `noise_max`: -0.05
- `base_height_offset`: 3
- `height_amplitude`: 3 (only 5-8 blocks total variation — the flattest biome)
- `detail_amplitude`: 1.5

#### Biome-Specific Nodes

Register in this file:
- `lazarus_space:capillary_surface` — Ground surface. Use `default_stone.png` colorized dark red with vein-like appearance (#B02020:160). Groups: cracky=2, crumbly=1. Stone sounds.
- `lazarus_space:vein_block` — Raised vessel material. Use `default_stone.png` colorized deep crimson (#800010:180). Groups: cracky=2. Stone sounds.
- `lazarus_space:vein_intersection` — Glowing junction. Same as vein_block but `light_source = 4` and colorized slightly brighter (#A02030:150).

#### Content ID Registration

Cache IDs for: `capillary_surface`, `vein_block`, `vein_intersection`, plus shared nodes `flesh`, `membrane`, `red_sea_source`.

#### Column Generation

**Ground fill**: From y=27775 up to terrain height, fill with `flesh`. The topmost block is `capillary_surface`.

**Semi-transparent floor effect**: At y=27775 (the very base), place `membrane` blocks instead of `flesh` at positions where the terrain detail noise is below -0.3. This creates patches where the red sea is visible below through the semi-transparent membrane.

**Raised vessel ridges**: Where the terrain detail noise exceeds 0.4 at the surface, place 1-3 blocks of `vein_block` stacked above the ground surface. The ridge height is 1 + floor((detail_noise - 0.4) * 5), capped at 3.

**Vein intersections**: Where both the terrain height noise AND the terrain detail noise both exceed 0.3 at the same x,z column, replace the topmost `vein_block` with `vein_intersection` (glowing). This represents branching points where capillaries meet.

**Rupture points**: Where the terrain height noise drops below -0.4 AND the column's y equals the base surface level (27775 + base_height_offset), do NOT place any ground material in this column. Instead leave air (or place `red_sea_source` if the position is at y=27775) so the red sea is exposed from below through the floor.

---

## Prompt 9 of 12 — Surface Biome: Coral Cliffs

### File: `biomes/coral_cliffs.lua` (new file)

Create a new file `biomes/coral_cliffs.lua` that registers the Coral Cliffs surface biome.

#### Biome Registration

Register with:
- `name`: `"coral_cliffs"`
- `noise_min`: -0.05
- `noise_max`: 0.15
- `base_height_offset`: 10
- `height_amplitude`: 290 (dramatic vertical terrain from near-flat to 300 blocks tall)
- `detail_amplitude`: 8

Note: because this biome has such extreme height variation, the erosion attenuation system is especially important here. Steep cliff faces will have minimal detail noise, keeping them clean vertical walls, while flat shelf surfaces will have full detail texture.

#### Biome-Specific Nodes

Register in this file:
- `lazarus_space:brain_coral` — Ridged organic cliff material. Use `default_stone.png` colorized pink-orange (#D08060:160). Groups: cracky=2. Stone sounds.
- `lazarus_space:lung_coral` — Spongy porous coral. Use `default_stone.png` colorized pink (#C07070:150). Groups: cracky=2, crumbly=1. Stone sounds.
- `lazarus_space:polyp` — Small coral growth. Use `default_stone.png` colorized bright pink (#E08080:130). Groups: cracky=3, crumbly=2. Stone sounds.

#### Content ID Registration

Cache IDs for: `brain_coral`, `lung_coral`, `polyp`, plus shared nodes `flesh`, `bone`.

#### Column Generation

**Shelf/cliff terrain**: The raw terrain height for this biome can be very tall (up to 300 blocks). Before using it, process it through a step function to create distinct shelf ledges: quantize the raw height to intervals of 20-50 blocks (use a step size of 30 as default). The quantized height creates flat shelves with abrupt vertical transitions between them.

The framework already computes the terrain height using the two-layer Perlin with erosion. This biome takes that height and applies the quantization step.

At each shelf level, the horizontal extent of the shelf varies with the terrain detail noise: shelves extend further where the detail noise is high, creating ledges of 5-20 blocks of depth.

**Ground fill**: From y=27775 up to the quantized shelf height at each column:
- Use `brain_coral`, `lung_coral`, and `polyp` with noise-driven distribution. Use the cave detail noise (from the framework) evaluated at each position:
  - Detail noise below -0.2: `brain_coral`
  - Detail noise -0.2 to 0.2: `lung_coral`
  - Detail noise above 0.2: `polyp`
- Shelf surfaces (the top 1-2 blocks of each quantized step): always `polyp` and `lung_coral` alternating.

**Overhangs**: Where a column's shelf height is lower than an adjacent column's shelf height by more than the step size, the higher shelf creates an overhang. The framework's terrain height naturally creates this. No special code needed — the fill-up-to-height logic automatically creates overhangs when adjacent columns have different quantized heights.

**Tube formations**: Reuse the 3D `cave_shape_noise` (from the framework) evaluated at positions within the coral cliff volume. Where the noise exceeds 0.65 (a high threshold so only occasional formations appear), carve the position to air. This creates winding tube-like voids through the cliff mass.

---

## Prompt 10 of 12 — Surface Biome: Nerve Thicket

### File: `biomes/nerve_thicket.lua` (new file)

Create a new file `biomes/nerve_thicket.lua` that registers the Nerve Thicket surface biome.

#### Biome Registration

Register with:
- `name`: `"nerve_thicket"`
- `noise_min`: 0.15
- `noise_max`: 0.5
- `base_height_offset`: 5
- `height_amplitude`: 10 (gentle rolling terrain, 5-15 blocks)
- `detail_amplitude`: 3

#### Biome-Specific Nodes

Register in this file:
- `lazarus_space:nerve_fiber` — Nerve trunk and branch material. Use `default_wood.png` colorized pale grey-white (#D0D0D8:140). Groups: choppy=2, cracky=2. Wood sounds.
- `lazarus_space:myelin_sheath` — Insulating wrapping. Use `default_wood.png` colorized off-white (#E8E0D0:120). Groups: choppy=2. Wood sounds.
- `lazarus_space:nerve_root` — Ground cover near trunks. Use `default_dirt.png` colorized pale grey-pink (#C8B8B8:150). Groups: crumbly=2, choppy=3. Dirt sounds.
- `lazarus_space:node_of_ranvier` — Glowing gap in myelin. Use `default_wood.png` colorized bright blue-white (#A0C0FF:100). `light_source = 5`. Groups: choppy=2. Wood sounds.

#### Content ID Registration

Cache IDs for: `nerve_fiber`, `myelin_sheath`, `nerve_root`, `node_of_ranvier`, plus shared nodes `flesh`.

#### Column Generation

**Ground fill**: From y=27775 up to terrain height, fill with `flesh`. The top 1 block of the ground surface uses `nerve_root` if the column is within 3 blocks horizontally of any nerve tree trunk (see below), otherwise `flesh`.

**Nerve tree structures**: Use a cell grid of 15x15 blocks. Each cell's (cell_x, cell_z) coordinates are hashed with a fixed seed. The generator determines:
- Tree center position within the cell (x, z)
- Tree height: 40-80 blocks above ground level
- Trunk radius: 2-4 blocks

For each column, check the current cell and 8 surrounding cells.

The trunk is a column of `nerve_fiber` blocks from ground level up to tree height, with the specified radius (circular cross-section). Myelin sheath wraps the trunk: at regular intervals of 6-10 blocks of height (interval determined by cell hash), a ring of `myelin_sheath` blocks replaces the outermost layer of the trunk for a span of 4-8 blocks vertically. Between myelin segments, there is a 1-block gap where the outermost layer uses `node_of_ranvier` (glowing, light_source=5).

The canopy starts at about 70% of the tree height. Above the canopy start, the effective trunk radius increases with height: for each block above canopy start, radius grows by roughly 0.3-0.5 blocks. In the canopy zone, `nerve_fiber` blocks are placed where the horizontal distance from the trunk center is less than the expanded radius AND the cave detail noise at the position is above -0.3. This creates tangled, irregular branching rather than a solid dome. The noise check ensures gaps and voids in the canopy.

The canopy should be dense enough that positions below it (between trees) are in near-total darkness — this means canopy blocks should fill enough volume to block light from above.

**Ground cover**: Within 1-2 blocks horizontally of a trunk's footprint, the surface block is `nerve_root`. Beyond that, it remains `flesh`.

---

## Prompt 11 of 12 — Surface Biome: Abscess Marsh

### File: `biomes/abscess_marsh.lua` (new file)

Create a new file `biomes/abscess_marsh.lua` that registers the Abscess Marsh surface biome.

#### Biome Registration

Register with:
- `name`: `"abscess_marsh"`
- `noise_min`: 0.5
- `noise_max`: 1.0 (captures everything above 0.5 plus the full upper tail)
- `base_height_offset`: 3
- `height_amplitude`: 9 (low terrain, 3-12 blocks)
- `detail_amplitude`: 2

#### Biome-Specific Nodes

Register in this file:
- `lazarus_space:infected_tissue` — Default ground. Use `default_dirt.png` colorized sickly yellow-red (#A07030:170). Groups: crumbly=2 with movement penalty. Add `liquid_viscosity`-like slowdown by adding `slippery=-1` — actually Minetest does not support negative slippery for slowdown on solid blocks. Instead, note in the node description that this biome is treacherous terrain. For actual movement resistance, set `move_resistance = 2` if the engine version supports it (Luanti 5.x added move_resistance to node definitions). If not available, just register it as a normal crumbly block.
- `lazarus_space:necrotic_patch` — Dead tissue accent. Use `default_dirt.png` colorized dark grey-brown (#4A3A2A:190). Groups: crumbly=2. Dirt sounds.
- `lazarus_space:bacterial_mat` — Pool-edge surface. Use `default_dirt.png` colorized green-grey (#607050:160). Groups: crumbly=3, slippery=2. Dirt sounds.
- `lazarus_space:wbc_debris` — White blood cell remains. Use `default_dirt.png` colorized pale yellow-white (#E0D8C0:130). Groups: crumbly=3. Dirt sounds.

#### Content ID Registration

Cache IDs for: `infected_tissue`, `necrotic_patch`, `bacterial_mat`, `wbc_debris`, plus shared nodes `flesh`, `pus_source`.

#### Column Generation

**Ground fill**: From y=27775 up to terrain height, fill with `infected_tissue`. Surface variation:
- Where the cave detail noise is below -0.2: replace the top block with `necrotic_patch`
- Default surface: `infected_tissue`

**Pus pools**: Where the terrain height (the two-layer Perlin result) dips below the biome's mean height (roughly the 30th percentile of heights), place `pus_source` blocks instead of solid ground. Fill from y=27775 + base_height_offset up to the terrain height with `pus_source`. This creates pools and drainage channels in the low areas.

Larger festering pits: where the terrain height noise drops below an even lower threshold (roughly the 10th percentile), place `pus_source` down to 5-15 blocks below the normal surface level (but not below y=27775). These are deep pits of pus.

**Pool edges**: Within 2-3 blocks horizontally of a pus pool edge (where the terrain transitions from solid to liquid), replace surface blocks with `bacterial_mat` and `wbc_debris` (alternate by position hash). This creates the crusted, infected border around each pool.

**No natural light sources**: This biome has zero light-emitting blocks. It should be completely dark unless players bring their own light. This is intentional and oppressive.

---

## Prompt 12 of 12 — Surface Biome Transitions and Dispatch Integration

### File: `bio_mapgen.lua` (modify existing framework section)

Ensure the surface biome dispatch logic in the main mapgen callback correctly handles transitions between adjacent registered biomes.

#### Biome Transition Blending

When the 2D surface biome noise value for a column falls within 0.05 noise units of a boundary between two registered biomes, the column is in a transition zone. In this zone:

1. Identify the two adjacent biomes (the one below the boundary and the one above).
2. Compute the blend factor: how far the noise value is from the boundary, normalized to 0-1 within the 0.05 transition half-width. At the boundary itself, the factor is 0.5. At the edge of the transition zone nearest biome A, the factor favors biome A heavily. At the edge nearest biome B, it favors biome B.
3. For each x,z column in the transition zone, hash the position (x * 73856093 + z * 19349663, or similar large-prime hash) and compare the hash modulo 100 against the blend factor scaled to 0-100. This determines which biome "wins" for this column.
4. Call the winning biome's `generate_column` function for that column.

This creates a stochastic blend where columns near the boundary alternate between biome A and biome B materials, with the probability shifting smoothly across the transition zone. Over a 20-40 block wide band, the visual effect is a gradual, natural-looking transition.

#### Terrain Height Blending in Transitions

In the transition zone, the terrain height should also blend between the two biomes' height parameters to prevent abrupt height jumps at biome boundaries. Compute the terrain height using BOTH biomes' parameters (base_height_offset, height_amplitude, detail_amplitude) and linearly interpolate between the two results based on the continuous blend factor (not the stochastic per-column choice). This means the terrain surface is always smooth across transitions even though the surface materials switch stochastically.

The material choice (which biome's generate_column runs) is stochastic, but the height those materials are placed at is the interpolated blend. Pass the interpolated height to whichever biome's generate_column wins for that column.

#### Edge Cases

- If a column's biome noise is outside the range of any registered biome (e.g. if a biome file is removed), fill the column with the default `flesh` block up to a minimal height (base_height_offset of 5 blocks). Log a warning once per mapgen call noting the unregistered noise range.
- If only one biome is registered, it handles the entire surface with no transitions.
- The transition logic should work with any number of registered biomes and any noise range assignments, not just the specific six defined in this update. This keeps the system modular — adding a seventh biome later just requires a new file in `biomes/` with the appropriate noise range.

#### Final Integration Check

Ensure the biome file loading (from prompt 1) happens after `bio_nodes.lua` is loaded but before the content ID caching in `register_on_mods_loaded`. The load order should be:
1. `bio_nodes.lua` — registers shared nodes
2. `bio_mapgen.lua` — sets up framework, then loads all biome files from `biomes/` which register their own nodes and biome definitions
3. In `register_on_mods_loaded`: cache all content IDs (shared + biome-specific)

This ordering ensures all nodes exist before any content ID resolution happens.

---

## Summary of Files Created/Modified

| File | Action | Prompt |
|------|--------|--------|
| `init.lua` | Modify — add 2 dofile lines | 1 |
| `bio_mapgen.lua` | New — mapgen framework, layer generation, biome dispatch | 1, 3, 4, 5, 12 |
| `bio_nodes.lua` | New — shared node registrations | 2 (with additions noted in 4) |
| `biomes/rib_fields.lua` | New — modular biome | 6 |
| `biomes/molar_peaks.lua` | New — modular biome | 7 |
| `biomes/vein_flats.lua` | New — modular biome | 8 |
| `biomes/coral_cliffs.lua` | New — modular biome | 9 |
| `biomes/nerve_thicket.lua` | New — modular biome | 10 |
| `biomes/abscess_marsh.lua` | New — modular biome | 11 |

## Key Technical Notes for SpecSwarm

- **No mobs.** No mob spawning, no entity spawning, no creature registration. This is terrain generation only.
- **No custom texture files.** All visuals use `default_*.png` textures with `^[colorize:#RRGGBB:alpha` modifiers.
- **Two-layer Perlin with erosion** is the surface terrain height system. The detail noise contribution is attenuated where the large-scale noise has a steep gradient, computed by neighbor sampling. This applies to ALL surface biomes through the framework — biomes do not implement their own height computation.
- **Modular biomes** are surface biomes only. Cave biomes and non-biome layers are in the main `bio_mapgen.lua`.
- **Cell-based structures** (ribs, teeth, nerve trees, hollow asteroids) are deterministic, stateless, and produce identical results regardless of chunk generation order.
- **Content IDs** are cached integers, never string lookups in the inner loop.
- **VoxelManip** is used for all terrain generation. No `minetest.set_node()` calls in the mapgen.
- **Loop order** is z-y-x (x innermost) for sequential VoxelArea and noise index advancement.
- **Performance**: the mapgen must complete quickly. Cache per-column values (biome, terrain height, structure lookups). Avoid per-voxel string operations or table allocations.
