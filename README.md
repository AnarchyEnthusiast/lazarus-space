# Lazarus Space

End-game Technic mod for Minetest featuring dimensional manipulation through fusion reactors and interdimensional portals.

## Dependencies

- **Technic** — HV power network, uranium fuel, energy crystals, stainless steel
- **Jumpdrive** — Warp device nodes, jump mechanics
- **Default** — Standard nodes, sounds, items

## Features

### Magnetic Fusion Reactor

Multi-block fusion reactor in 3 tiers for extreme power generation.

| Tier | Size | Output | Fuel Slots |
|------|------|--------|------------|
| 1 | 9x9x5 | 140,000 EU/tick | 3 |
| 2 | 13x13x5 | 240,000 EU/tick | 6 |
| 3 | 17x17x5 | 600,000 EU/tick | 12 |

**Structure blocks:** Pole Field, Toroid Field, Plasma Field, Pole Corrector, Stainless Steel. Place the Pole Corrector first to define the structure center.

**Control blocks** (must border the structure):
- **Fusion Control Panel** — Tier selection, fuel monitoring, startup controls
- **Plasma Jumpstarter** — Provides startup energy from HV network, shows plasma diagnostic display
- **Fusion Power Output** — Connects to HV cable network, supplies generated EU

Each fuel rod lasts 8 hours. Reactor states cycle through Offline → Charging → Running → Burndown → Complete.

### Continuum Disrupter & Stasis Field

HV-powered machine that deploys a temporal stasis field (radius 9-18 blocks). Requires 168,000 EU to charge at 36,000 EU/tick demand.

Inside the field:
- All ABMs and node timers are suppressed
- Entities are frozen in temporal stasis
- 3-layer parallax starfield particles fill the interior
- Reactor cores transmute to Decaying Uranium when dug
- 20 disrupted space shell variants with perlin-noise opacity blending

### Lazarus Portal

One-way dimensional gate opened through ritual activation:

1. Power and charge the Continuum Disrupter (deploys stasis field)
2. Right-click any Warp Device with Decaying Uranium in hand
3. Warp device glows through 4 stages over 3 seconds
4. Portal grows via flood-fill, coating all surfaces contacting solid blocks
5. After 2-second delay, portal activates for teleportation
6. Touching a portal face teleports the player to a random surface location (within +/-10,000 blocks X/Z, 85-120Y)
7. Field collapses with an explosion destroying 50% of terrain in a 15-block radius

63 portal surface variants cover all face combinations as thin slabs.

### Dimensional Jumpdrive

Enhanced jumpdrive with independent X/Y/Z radius control (1-15 each).

- Asymmetric jump zones (e.g., 5x10x3)
- HV powered with 1,000,000 EU base storage
- Upgrade slots: Red (+10%), Green (+20%), Blue (+50%) energy crystals increase max storage
- Book system: save/load coordinates to written books
- Show button runs full preflight checks (overlap, blacklist, protection, power) with particle box visualization (30 particles per edge)
- Punch with empty hand to see current radius outline

### Advanced Crafting Machine

5x5 crafting grid powered by HV. Costs 10,000 EU per craft. Falls back to standard 3x3 crafting when no 5x5 recipe matches. Register custom recipes via `lazarus_space.register_6x6_craft()`.

### Guide Books

- **Reactor Guide** — Interactive book with 3D model previews for each build layer, tabbed for all 3 tiers, 7 pages covering intro through startup procedure
- **Portal Guide** — 4-page guide covering setup, activation, and safety warnings

## Gameplay Loop

1. Build a Fusion Reactor for power
2. Place Continuum Disrupter on HV network and charge it
3. Dig reactor cores inside the stasis field for Decaying Uranium
4. Use uranium on a Warp Device to open a portal
5. Step through to teleport — field collapses behind you

## File Structure

| File | Purpose |
|------|---------|
| `init.lua` | Mod init, global constants, file loading |
| `nodes.lua` | All node registrations |
| `field.lua` | Stasis field deployment and terrain suppression |
| `portal.lua` | Portal growth, warp interaction, teleportation |
| `reactor.lua` | Reactor structures, tiers, control UI, power gen |
| `formspec.lua` | Disrupter UI builder |
| `crafting3d.lua` | Advanced crafting machine |
| `jumpdrive.lua` | Enhanced jumpdrive |
| `guide.lua` | Reactor guide book with 3D models |
| `portal_guide.lua` | Portal guide book |
| `generate_textures.py` | Texture generation script |
| `generate_models.py` | OBJ model generation for guide books |
