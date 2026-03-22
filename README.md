# Lazarus Space

End-game Technic mod for Minetest — fusion reactors, interdimensional portals, a biological dimension, and an enhanced jumpdrive.

**This mod is a work in progress. Expect bugs, incomplete features, and breaking changes.**

## Dependencies

**Required:**
- **Technic** — HV power network
- **Jumpdrive** — Warp device base
- **Default** — Standard nodes and items

**Optional:**
- **Vizlib** — Enhanced box outline visualizations for jumpdrive preflight and radius display (falls back to particle outlines without it)

## Features

### Magnetic Fusion Reactor

Multi-block reactor in 3 tiers (9x9, 13x13, 17x17) producing 140K–600K EU/tick. Built from Pole Field, Toroid Field, Plasma Field, Pole Corrector, and Stainless Steel blocks. Controlled via a Fusion Control Panel, Plasma Jumpstarter, and Fusion Power Output node. Each fuel rod lasts 8 hours. Includes an interactive guide book with 3D model previews.

### Continuum Disrupter & Stasis Field

HV machine that deploys a temporal stasis field (radius 9–18). Freezes ABMs, node timers, and entities inside. Features a 3-layer parallax starfield, 20 disrupted space shell variants, and transmutes reactor cores to Decaying Uranium when dug.

### Lazarus Portal

One-way dimensional gate: charge the disrupter, use Decaying Uranium on a Warp Device, and a portal grows via flood-fill across all contacting surfaces. Touching a portal face teleports the player to a random surface location. The field then collapses with an explosion. 63 portal surface variants cover all face combinations. Includes a 4-page guide book.

### Dimensional Jumpdrive

Enhanced jumpdrive with independent X/Y/Z radius (1–15 each), HV powered with 1M EU base storage. Supports energy crystal upgrades (Red/Green/Blue), coordinate book save/load, full preflight visualization, and fleet controller compatibility.

**Blanket Jump Mode** — Select specific non-air blocks within the radius to move instead of the whole volume. Configurable via a dedicated tab with node exclusions, per-block selection via punch, and strict air-only destination checking.

### Advanced Crafting Machine

5×5 HV-powered crafting grid (10K EU per craft). Falls back to 3×3 when no 5×5 recipe matches.

### Biological Dimension

A massive organic interior dimension spanning y=26927–29200, accessed through the Lazarus Portal. The terrain is procedurally generated using layered Perlin noise with a modular biome system.

**Layers (bottom to top):**
- **Frozen Asteroid Field** (y=26927–26997) — Ice-encrusted asteroids drifting in void
- **Death Space** (y=26997–27006) — Thin empty buffer zone
- **Organic Caves** (y=27006–27697) — Vast cavern network carved from flesh and bone, with glowing mushrooms, cave vines, and stalactites. Bile and pus liquid pools on the floor
- **Jelly Membrane** (y=27697–27712) — Translucent barrier separating caves from the plasma ocean
- **Plasma Ocean** (y=27702–27775) — Liquid plasma sea with a noise-shaped barrier floor
- **Surface** (y=27775+) — 7 distinct biomes with varied terrain, vegetation, and resources
- **Upper Asteroid Field** (y=27904–28693) — Livable spheroid asteroids with their own ecosystems
- **Ceiling Caves** (y=28793–29193) — Inverted cave system with hanging stalactites
- **Ceiling Membrane** (y=29193–29200) — Top boundary cap

**Surface Biomes:**
- **Abscess Marsh** — Wet infected terrain with pus pools and necrotic patches
- **Coral Cliffs** — Brain coral formations and lung coral growths
- **Follicle Forest** — Hair strand trees with keratin trunks and follicle sheaths
- **Molar Peaks** — Towering enamel and dentin tooth-like mountains
- **Nerve Thicket** — Dense nerve fiber networks with glowing myelin sheaths
- **Rib Fields** — Exposed skeletal ribs jutting from flesh terrain
- **Vein Flats** — Flat vascular plains with vein intersections and capillary surfaces

~40 custom nodes (flesh, bone, cartilage, sinew, nerve, enamel, membrane, marrow, bile, pus, plasma liquids, glowing mushrooms, cave vines, tungsten ore, and more). Custom skybox and fog. Tungsten ore system for mining and smelting.

## File Structure

| File | Purpose |
|------|---------|
| `init.lua` | Mod init, globals, file loading |
| `nodes.lua` | Node registrations (disrupter, field, portal) |
| `field.lua` | Stasis field deployment |
| `portal.lua` | Portal growth and teleportation |
| `reactor.lua` | Fusion reactor structure and power |
| `formspec.lua` | Disrupter UI |
| `jumpdrive.lua` | Enhanced jumpdrive + blanket mode |
| `crafting3d.lua` | Advanced crafting machine |
| `guide.lua` | Reactor guide book |
| `portal_guide.lua` | Portal guide book |
| `bio_nodes.lua` | Biological dimension nodes |
| `bio_mapgen.lua` | Biological dimension terrain gen |
| `bio_schematics.lua` | Biological dimension schematics |
| `biomes/` | 7 surface biome modules |
| `generate_textures.py` | Texture generation |
| `bio_generate_textures.py` | Bio dimension texture generation |
| `generate_models.py` | Guide book 3D models |

## TODO

- [ ] Hazmat spacesuit for dimension survival
- [ ] Rover vehicle (maybe?)
- [ ] Tungsten uses — armor, tools, etc.
- [ ] Crafting recipes for reactor, jumpdrive, and crafting table
- [ ] Finish compatibility checks with Pandorabox
- [ ] Vacuum mechanics in space/dimension
- [ ] Hostile mobs / monsters
- [ ] Generated structures in the biological dimension
- [ ] Home portal — return gate from dimension
- [ ] MV/HV melt functionality
- [ ] Anti-teleportation within Lazarus dimension

## Known Issues & Optimization Backlog

### Critical Bugs

- [ ] **bio_mapgen.lua:1010-1013** — Dead if/else branch: both paths assign `c.stone`, hollow asteroid shells have no material variety. One branch should use a different material.
- [ ] **bio_nodes.lua** — Plasma source registered with `groups = {water = 3}`, bucket mods treat it as water. Remove water group, keep only `liquid = 3`.
- [ ] **crafting3d.lua** — Test recipe (dirt ring → mese) left in production code. Remove it.
- [ ] **crafting3d.lua** — API named `register_6x6_craft` / `find_6x6_craft` but grid is actually 5x5. Rename to match.

### Critical Performance

- [ ] **field.lua** — Charging particle rings spawn ~4,800 particles every 0.1s (48K/sec). Use `add_particlespawner()` instead of individual `add_particle()` calls.
- [ ] **field.lua** — `explode()` and `deploy_field()` use per-block `set_node()` instead of VoxelManip. Batch with VM for thousands of nodes.
- [ ] **bio_mapgen.lua** — Egg clusters and spine trees use `set_node()` per-block inside mapgen. Use `bulk_set_node()` or a second VoxelManip pass.
- [ ] **bio_mapgen.lua** — 5 separate floating block cleanup passes each iterate the full chunk (~2.5M voxel reads total). Consolidate into one pass.
- [ ] **reactor.lua:349-361** — `find_pole_corrector` iterates 9,261 positions with `get_node()`. Use `find_nodes_in_area()` instead.

### Important Bugs

- [ ] **jumpdrive.lua:1024-1028** — After-jump network invalidation averages source+destination positions, producing a midpoint in neither network. Invalidate both centers independently.
- [ ] **nodes.lua** — Base `disrupted_space` may lack `use_texture_alpha = "blend"` while all 20 variants have it.
- [ ] **crafting3d.lua** — Functions named 6x6 but implement 5x5 grid. Rename for clarity.
- [ ] **portal_guide.lua** — Page 1 (setup) and page 2 (overview) appear reversed. Overview should come first.
- [ ] **bio_nodes.lua** — Cave vine ABM recalculates random `max_length` every tick instead of storing in metadata.

### Important Correctness

- [ ] **portal.lua** — Teleportation picks random coordinates with no safety check (could land in solid terrain or lava). Add destination validation.
- [ ] **jumpdrive.lua** — No `minetest.is_protected()` checks on blanket jump source/destination.
- [ ] **reactor.lua** — Power output registered on LV/MV/HV simultaneously. Should register only HV.
- [ ] **field.lua** — `cold_collapse` and `teardown_field` have duplicated but slightly different cleanup code. Extract shared helper.
- [ ] **bio_mapgen.lua** — Column height neighbor lookups can go out of bounds at chunk edges. Document or restrict iteration range.

### Important Code Quality

- [ ] **guide.lua + portal_guide.lua** — Duplicated helper functions (`styled_btn`, `page_header`). Move to shared file.
- [ ] **bio_mapgen.lua** — Entire mapgen is one 2,585-line function. Extract layers into separate helpers.
- [ ] **Biome files** — Inconsistent content ID access patterns (upvalues vs ctx.c.xxx). Standardize.
- [ ] **generate_textures.py** — Plasma diagnostic texture is 205x8200px (40 frames). Consider reducing.

### Important Gameplay

- [ ] **bio_nodes.lua** — `death_space` has empty groups, making it indestructible with no escape if trapped.
- [ ] **Biological dimension** — No return mechanism after portal teleport. Players could be stranded.
- [ ] **reactor.lua** — No fuel consumption rate documentation in-game. Add to guide book.

### Important Compatibility

- [ ] **jumpdrive.lua** — Heavy dependency on optional jumpdrive mod API with no version checking. Add warnings for missing functions.
- [ ] **reactor.lua** — Uses technic mod internals that can change between versions. Document required version.
- [ ] **mod.conf** — Should list `optional_depends = vizlib`.

### Minor

- [ ] Duplicated `pos_hash()` across multiple biome files. Define once in init.lua.
- [ ] Duplicated `face_subsets` between nodes.lua and field.lua. Centralize.
- [ ] Abscess marsh biome has no light sources — total darkness.
- [ ] Magic numbers scattered without named constants.
- [ ] Player observation globalstep has no max distance check.
- [ ] Dual time tracking in portal.lua (get_us_time + dtime). Use one method.
- [ ] Jumpdrive radius limit (1-15) not explained in formspec.
- [ ] bio_generate_textures.py has dead code branches for unused special types.
