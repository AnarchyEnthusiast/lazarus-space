# Lazarus Space

End-game Technic mod for Minetest — fusion reactors, interdimensional portals, a biological dimension, and an enhanced jumpdrive.

## Dependencies

- **Technic** — HV power network
- **Jumpdrive** — Warp device base
- **Default** — Standard nodes and items

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

Full terrain generation layer (y=26927–29200) with organic caves, a plasma ocean, 7 surface biomes, upper asteroid fields, ceiling caves, stalactites, and a tungsten ore system.

**Biomes:** Abscess Marsh, Coral Cliffs, Follicle Forest, Molar Peaks, Nerve Thicket, Rib Fields, Vein Flats.

~40 custom nodes including flesh, bone, cartilage, nerve, bile/pus/marrow liquids, glowing mushrooms, and more. Custom skybox and fog.

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
