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
