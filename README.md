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
- [x] **bio_nodes.lua** — Plasma source registered with `groups = {water = 3}`, bucket mods treat it as water. Removed water group.
- [x] **crafting3d.lua** — Test recipe (dirt ring → mese) left in production code. Removed.
- [x] **crafting3d.lua** — API named `register_6x6_craft` / `find_6x6_craft` but grid is actually 5x5. Renamed to 5x5.

### Critical Performance

- [x] **field.lua** — Charging particle rings: replaced 4,800 `add_particle()` calls with 8 `add_particlespawner()` calls.
- [x] **field.lua** — `explode()` and `deploy_field()` converted to VoxelManip bulk operations.
- [x] **bio_mapgen.lua** — Egg clusters and spine trees converted to `bulk_set_node()`.
- [x] **bio_mapgen.lua** — 5 floating block cleanup passes consolidated into one unified pass.
- [x] **reactor.lua** — `find_pole_corrector` converted to `find_nodes_in_area()`.

### Important Bugs

- [x] **jumpdrive.lua** — After-jump network invalidation now invalidates both source and destination independently.
- [x] **nodes.lua** — Added `use_texture_alpha = "blend"` to base `disrupted_space`.
- [x] **crafting3d.lua** — Functions named 6x6 but implement 5x5 grid. Renamed to 5x5.
- [x] **portal_guide.lua** — Page 1/2 swapped so overview comes before setup.
- [x] **bio_nodes.lua** — Cave vine ABM now uses deterministic position hash for max_length.

### Important Correctness

- [x] **portal.lua** — Teleportation now targets Lazarus Space (y=27775-27900) with air safety check and retry.
- [x] **jumpdrive.lua** — Added `minetest.is_protected()` checks on blanket jump source/destination corners.
- [ ] **reactor.lua** — Power output registered on LV/MV/HV simultaneously. Should register only HV.
- [x] **field.lua** — Extracted shared `cleanup_field_nodes()` helper from `cold_collapse` and `teardown_field`.
- [ ] **bio_mapgen.lua** — Column height neighbor lookups can go out of bounds at chunk edges. Document or restrict iteration range.

### Important Code Quality

- [x] **guide.lua + portal_guide.lua** — Moved `styled_btn` and `page_header` to formspec.lua as shared helpers.
- [x] **bio_mapgen.lua** — Extracted mapgen layers into separate helper functions.
- [ ] **Biome files** — Inconsistent content ID access patterns (upvalues vs ctx.c.xxx). Standardize.
- [ ] **generate_textures.py** — Plasma diagnostic texture is 205x8200px (40 frames). Consider reducing.

### Important Gameplay

- [x] **bio_nodes.lua** — `death_space` kept intentionally indestructible (impassable barrier by design).
- [ ] **Biological dimension** — No return mechanism after portal teleport. Players could be stranded.
- [ ] **reactor.lua** — No fuel consumption rate documentation in-game. Add to guide book.

### Important Compatibility

- [ ] **jumpdrive.lua** — Heavy dependency on optional jumpdrive mod API with no version checking. Add warnings for missing functions.
- [ ] **reactor.lua** — Uses technic mod internals that can change between versions. Document required version.
- [x] **mod.conf** — Added `optional_depends = vizlib`.

### Minor

- [x] Duplicated `pos_hash()` across biome files. Defined once in init.lua as `lazarus_space.pos_hash()`.
- [x] Duplicated `face_subsets` between nodes.lua and field.lua. Centralized via `PORTAL_LOOKUP`.
- [ ] Abscess marsh biome has no light sources — total darkness.
- [x] Magic numbers replaced with named constants in portal.lua and field.lua.
- [x] Player observation globalstep now has `MAX_OBSERVATION_DISTANCE = 200` check.
- [x] Dual time tracking in portal.lua removed. Uses only dtime accumulation.
- [x] Jumpdrive radius limit (1-15) now shown on all three radius fields.
- [x] bio_generate_textures.py dead code branches removed.
