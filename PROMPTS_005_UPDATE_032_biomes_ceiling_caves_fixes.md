# PROMPTS_005_UPDATE_032 — Biome Scaling, Ceiling Caves, Grass Fix, Opacity Fixes, Ruins

SpecSwarm command: `/modify`

This update fixes grass diagonal row patterns, removes remaining transparent blocks, drastically cuts cave liquid sources, triples biome size, adds ruined structures to flesh plains, lowers the asteroid field ceiling, and adds a 400-block ceiling cave system with giant stalactites.

---

## Prompt 1 of 5 — Grass Randomization, Opacity Fixes, and Liquid Source Reduction

### Files: `bio_schematics.lua`, `bio_mapgen.lua`, `bio_nodes.lua`

#### Fix Grass Diagonal Rows

Grass patches and tall grass are spawning in visible diagonal row patterns. This is caused by the position hash function `(x * 73856093 + z * 19349663) % N` — the linear combination of two primes produces regular diagonal alignment in 2D.

Replace the grass placement hash everywhere it is used (in `bio_schematics.lua` and any biome files that place grass) with a better hash that breaks diagonal patterns. Use a multi-step hash with XOR and bit mixing:

```
local function pos_hash(x, z, seed)
    local h = x * 374761393 + z * 668265263 + seed
    h = (h ~ (h >> 13)) * 1274126177
    h = h ~ (h >> 16)
    return h
end
```

Where `~` is Lua's bitwise XOR (Lua 5.3+, which Luanti uses) and `>>` is right shift. If the codebase targets Lua 5.1 (older Minetest), use `bit.bxor` and `bit.rshift` from the bit library, or use this arithmetic alternative that avoids bit operations:

```
local function pos_hash(x, z, seed)
    local h = (x * 374761393 + z * 668265263 + seed) % 2147483647
    h = ((h * 1103515245) + 12345) % 2147483647
    h = ((h * 1103515245) + 12345) % 2147483647
    return h
end
```

Use this hash for ALL placement decisions: grass patches, tall grass, mushroom placement, skeleton placement, and any other position-based random choice that currently uses the old hash. Pass a different `seed` value for each decoration type so they don't correlate (e.g., seed 1 for grass, seed 2 for mushrooms, seed 3 for skeletons).

Also replace the hash used in `bio_mapgen.lua` for plant placement (bio_sprout, bio_tendril, bio_polyp_plant) and cave mushroom placement (cave_shroom_small, cave_shroom_tall, cave_shroom_bright) with the same improved hash function.

#### Make Cyst Wall Opaque

In `bio_nodes.lua`, change `lazarus_space:cyst_wall`:
- Change drawtype from `glasslike` to `normal`
- Remove `use_texture_alpha = "blend"`
- Update the texture in `bio_generate_textures.py` to generate at alpha=255 (fully opaque)
- Keep all other properties (groups, sounds, breakability)

After this change, only `lazarus_space:jelly` and `lazarus_space:jelly_glow` remain transparent in the entire dimension.

#### Make Bile and Marrow Liquids Fully Opaque

In `bio_nodes.lua`, update the `post_effect_color` for bile and marrow liquids to be fully opaque so players submerged in them cannot see:

- `lazarus_space:bile_source` and `lazarus_space:bile_flowing`: change `post_effect_color` alpha from 200 to 255. `post_effect_color = {a=255, r=120, g=130, b=10}`.
- `lazarus_space:marrow_source` and `lazarus_space:marrow_flowing`: change `post_effect_color` alpha from 180 to 255. `post_effect_color = {a=255, r=160, g=100, b=30}`.
- Also update `lazarus_space:bile_static` and `lazarus_space:marrow_static` (the non-liquid fill variants) to match the same fully opaque post_effect_color.

#### Reduce Bile and Marrow Sources to 2% of Current

In `bio_mapgen.lua`, the organic cave layer generation places bile source blocks in intestinal caves and marrow source blocks in marrow caves. Reduce to approximately 2% of the current placement rate.

The current placement uses a noise band of 0.005 near the cave carving threshold. Reduce this band to 0.0001. This makes qualifying positions extremely rare.

Additionally, add a per-chunk counter for each liquid type. Maximum 3 bile source blocks per chunk. Maximum 3 marrow source blocks per chunk. Once the limit is hit, stop placing that liquid type for the rest of the chunk. This hard cap ensures no chunk ever generates excessive liquid.

All bile sources in a chunk must be at the same y-level (the lowest qualifying y found). Same for marrow sources. This prevents multi-level flow.

---

## Prompt 2 of 5 — Triple Biome Size

### Files: `bio_mapgen.lua`

All surface biomes and cave biomes are too small — players transition between biomes too quickly. Triple the size of all biome regions.

#### Surface Biome Noise Spread

Change the `surface_biome_noise` spread from 300 to 900. This makes surface biome regions approximately three times larger horizontally (roughly 600-1800 blocks across instead of 200-600).

The surface biome noise range divisions (-0.6, -0.25, -0.05, 0.15, 0.5) stay the same — the noise values don't change, just the spatial scale at which they vary.

#### Cave Biome Noise Spread

Change the `cave_biome_noise` spread from 200 to 600. Cave biome regions become three times larger.

The cave biome boundaries (-0.3, 0.3) stay the same.

#### Transition Zone Scaling

The surface biome transition zone width is currently 0.05 noise units on each side of a boundary. With the tripled spread, the same noise width covers a proportionally larger physical area (transition bands become ~60-120 blocks wide instead of ~20-40). This is fine — wider transitions look more natural at the larger biome scale. No change needed to the transition noise width.

Similarly, cave biome transition zones (0.1 noise units) will cover wider physical bands. This is acceptable.

---

## Prompt 3 of 5 — Ruined Structure Schematics on Flesh Plains

### Files: `bio_nodes.lua` (add nodes), `bio_schematics.lua` (add schematics and placement)

Large flat areas of `flesh` blocks (especially in Rib Fields between ribs, Abscess Marsh on mounds, and Nerve Thicket between trees) look empty and monotonous. Add ruined structure schematics built from existing biological materials.

#### New Nodes

Register in `bio_nodes.lua`:

- `lazarus_space:bone_pillar` — A cracked pillar block. Use the `lazarus_space_bone.png` texture. Drawtype: `nodebox` with a slightly narrowed column shape (0.35 block radius cylinder approximation: box {-0.35, -0.5, -0.35, 0.35, 0.5, 0.35}). Groups: cracky=2, crumbly=1. Stone sounds.
- `lazarus_space:bone_slab` — A flat bone slab. Use `lazarus_space_bone.png`. Drawtype: `nodebox` with a half-height slab ({-0.5, -0.5, -0.5, 0.5, 0.0, 0.5}). Groups: cracky=2. Stone sounds.
- `lazarus_space:ruin_wall` — Crumbling wall block. Use `lazarus_space_dentin.png`. Normal drawtype. Groups: cracky=2, crumbly=2. Stone sounds.
- `lazarus_space:ruin_arch` — Arch keystone block. Use `lazarus_space_cartilage.png`. Drawtype: `nodebox` with an arch shape (top half is solid, bottom half is the arch opening: two pillars on the sides with air in the middle — approximate as box {-0.5, 0.0, -0.5, 0.5, 0.5, 0.5} for the top half, {-0.5, -0.5, -0.5, -0.25, 0.0, 0.5} for left pillar, {0.25, -0.5, -0.5, 0.5, 0.0, 0.5} for right pillar). Groups: cracky=2. Stone sounds.

Generate textures for bone_pillar and bone_slab in `bio_generate_textures.py` — they can reuse the bone color (245, 240, 220) since they use the same texture file. ruin_wall uses dentin texture, ruin_arch uses cartilage texture — already generated.

#### Ruin Schematics (4 variants, all placeholder)

Define in `bio_schematics.lua`:

- **`ruin_small_wall`** — Size: 5x3x2. A short crumbling wall segment. Bottom row: 5 ruin_wall blocks in a line. Middle row: 3 ruin_wall blocks (gaps at ends, 60% probability). Top row: 1-2 bone_slab blocks scattered (40% probability each). Represents a broken wall fragment.

- **`ruin_pillar_pair`** — Size: 3x5x3. Two bone_pillar columns (3 blocks tall each) standing 2 blocks apart, with a bone_slab bridging the top. Some blocks at 50% probability for asymmetric weathering. One pillar can be shorter (top block at 30% probability).

- **`ruin_archway`** — Size: 5x4x3. Two bone_pillar columns (3 tall) on the outer edges, ruin_arch block bridging the top, with ruin_wall filling the sides at 40% probability. Represents a collapsed archway or doorway.

- **`ruin_foundation`** — Size: 7x2x7. A square foundation outline: bone_slab blocks forming a 7x7 border on the ground layer (only the perimeter, center is air), with occasional ruin_wall blocks rising 1 block above the border at corners and midpoints (50% probability each). Represents the remains of a structure floor plan.

All schematics use `force_placement = false`. Generous use of probability values (30-60%) so every instance looks different.

#### Placement

Add ruin placement to the schematic placement pass in `bio_schematics.lua` / `bio_mapgen.lua`:

- **Rib Fields**: 1 in 3000 surface positions — any ruin variant. Placed on flat flesh ground between ribs.
- **Abscess Marsh**: 1 in 4000 surface positions — `ruin_foundation` and `ruin_small_wall` only (corroded, half-dissolved).
- **Nerve Thicket**: 1 in 3500 surface positions — `ruin_pillar_pair` and `ruin_archway` (overgrown with nerve roots).
- **Vein Flats**: 1 in 5000 surface positions — `ruin_foundation` only (sunken into the flat terrain).
- **Molar Peaks and Coral Cliffs**: no ruins.

Use the new improved hash function from Prompt 1 with a unique seed for ruin placement.

These are placeholder schematics — user will replace them with hand-built designs later. Make the Lua table definitions clearly commented and easy to edit.

---

## Prompt 4 of 5 — Lower Asteroid Ceiling, Ceiling Cave System, and Stalactites

### File: `bio_mapgen.lua` (major changes to upper layers)

#### Restructure Upper Layer Boundaries

Change the upper portion of the dimension layout. The new layer boundaries:

- Upper Asteroid Field: y=28200 to y=30500 (was y=28200 to y=30920 — lowered top by 420 blocks)
- Ceiling Cave System: y=30500 to y=30900 (NEW — 400 blocks of organic caves)
- Ceiling Membrane: y=30900 to y=30907 (was y=30920 to y=30927 — shifted down 20 blocks to sit directly above ceiling caves)

Update all layer boundary constants to reflect these new values. The old constants for the asteroid field top (30920) and ceiling membrane (30920-30927) must be changed everywhere they appear.

#### Ceiling Cave System (y=30500 to y=30900)

Generate an organic cave system in this 400-block-tall zone using the same cave generation approach as the lower organic caves (y=27006-27697) but with some differences:

**Cave shape**: Reuse the `cave_shape_noise` (spread 60, from UPDATE_031). The noise produces different shapes at these y-coordinates since it's 3D noise sampled at different positions — no additional noise objects needed.

**Single biome**: The ceiling caves do NOT use the cave biome selector. They are a single cave type throughout — a mix of materials rather than three distinct biomes. Wall materials:
- Where cave_detail_noise > 0.2: `bone` (skeletal ceiling structure)
- Where cave_detail_noise -0.2 to 0.2: `flesh_dark` (fleshy cave walls)
- Where cave_detail_noise < -0.2: `muscle` (muscular tissue)

**Carving threshold**: Use 0.0 (50% open, same as tumor caves). This creates large open chambers with plenty of solid structure for stalactites to hang from.

**Floor features**: Cave floor positions (solid block with air above) get occasional `glowing_mushroom` (1 in 100 positions using the new hash) for minimal lighting.

**No liquids**: No liquid sources in the ceiling caves. Keep it simple and lag-free.

**Connection to ceiling membrane**: At y=30900, the ceiling caves end and the ceiling membrane begins. The ceiling membrane (now y=30900-30907) still fills completely with `ceiling_membrane` blocks, with `ceiling_vein` blocks where cave_detail_noise > 0.3.

**Connection to asteroid field below**: At y=30500, the ceiling caves transition into the asteroid field. The lowest ~20 blocks of the ceiling cave zone (y=30500-30520) should have a gradually increasing carving threshold (from 0.0 at y=30520 to 0.4 at y=30500) so the caves become increasingly solid and eventually merge into the asteroid field. This creates a rough, pockmarked underside rather than an abrupt flat boundary.

#### Giant Stalactites (y=30200 to y=30500)

Giant stalactites hang down from the bottom of the ceiling cave system into the upper asteroid field. They are massive vertical formations — not thin spikes, but broad organic columns tapering to points.

**Placement**: Use a cell-based system with cells of 60x60 blocks (in x,z). Each cell's coordinates are hashed to determine:
- Whether a stalactite exists (roughly 1 in 3 cells, so ~33% chance)
- Center position within the cell (x, z)
- Length: 100-300 blocks hanging down from y=30500
- Base radius at the ceiling attachment point: 8-15 blocks
- Tip radius: 1-3 blocks

**Shape**: Each stalactite is a tapered cone. At the top (y=30500), the radius is the full base radius. At the tip (y = 30500 - length), the radius narrows to the tip radius. The radius at any height interpolates linearly between base and tip.

**Noise displacement**: Apply the `asteroid_shape_noise` to displace the stalactite surface by ±3-5 blocks, creating organic irregularity rather than perfect cones.

**Materials**:
- Outer 30% of radius: `bone` (hard exterior shell)
- Inner 70%: `flesh_dark` with patches of `muscle` (determined by cave_detail_noise)
- Rare `asteroid_glow` blocks (1 in 300 surface positions) for faint luminescence

**Hollow cores**: Stalactites longer than 200 blocks have a hollow core — if the distance from the stalactite center axis is less than 2 blocks AND the position is in the middle 50% of the stalactite's length, place air instead of solid material. This creates a tunnel running through the center of the largest stalactites.

**Integration with asteroids**: Stalactites pass through the asteroid field. They override barren asteroid generation at positions where they exist (similar to how hollow livable asteroids override barren asteroids). Where a stalactite position coincides with a barren asteroid, the stalactite material takes priority.

**Check neighboring cells**: For each position, check the current cell and 8 surrounding cells for stalactites, since stalactites with large base radii can extend into adjacent cells.

#### Update Asteroid Density Gradient

The asteroid density gradient control points must be updated for the new top boundary:
- At y=28200 (bottom): threshold stays at 0.55
- At y=29350 (new middle): threshold 0.42
- At y=30500 (new top): threshold 0.30

Interpolate linearly between these points.

---

## Prompt 5 of 5 — Frozen Asteroid Field Uses Regular World Fog

### File: `bio_mapgen.lua` (fog globalstep section)

UPDATE_031 added a dark space sky for the frozen asteroid field (y=26927-26997). Change this so the frozen asteroid field uses the regular overworld sky and fog instead of a custom dark void.

Replace the frozen asteroid field sky condition with a simple default restore:

When a player is in the frozen asteroid field range (y >= 26927 and y < 27006 — covering both the asteroid field and death space), set:
```
player:set_sky({type = "regular"})
player:set_sun({visible = true})
player:set_moon({visible = true})
player:set_stars({visible = true})
player:set_clouds({density = 0.4})
```

And clear any fog override:
```
player:set_fog({})
```

This gives the frozen asteroid field the same sky, clouds, sun, moon, and stars as the regular overworld. The death space blocks still override the visual with opaque black post_effect_color when players are inside them, so that zone is unaffected.

The globalstep zone check order becomes:
1. y >= 27006 and y <= 30907: Red fog (biological interior — note upper bound changed from 30927 to 30907 to match new ceiling membrane top)
2. y >= 26927 and y < 27006: Regular world sky (frozen asteroids + death space)
3. Outside all ranges: Regular world sky (restore defaults if previously overridden)

Zones 2 and 3 both result in the same "regular" sky — they can share the same restore logic. The tracking table should now only track two states: "bio_fog" and "default". If the player is not in the bio fog range, they get default sky.

---

## Summary

| Prompt | Change |
|--------|--------|
| 1 | Fix grass diagonal rows with better hash, cyst_wall opaque, bile/marrow fully opaque post-effect, liquid sources to 2% with 3-per-chunk cap |
| 2 | Surface biome noise spread 300→900, cave biome noise 200→600 (triple biome size) |
| 3 | 4 ruined structure schematics (wall, pillars, archway, foundation) placed in rib fields, marsh, thicket, flats |
| 4 | Asteroid field top lowered to y=30500, 400-block ceiling cave system y=30500-30900, giant stalactites (100-300 blocks) hanging into asteroid field, ceiling membrane shifted to y=30900-30907 |
| 5 | Frozen asteroid field uses regular overworld sky/fog instead of custom dark void |

## Updated Layer Boundaries (after this update)

| Layer | Y Range | Height |
|-------|---------|--------|
| Frozen Asteroid Field | 26927-26997 | 70 |
| Death Space Barrier | 26997-27006 | 9 |
| Organic Caves | 27006-27697 | 691 |
| Jelly/Plasma Membrane | 27697-27712 | 15 |
| Red Sea | 27712-27775 | 63 |
| Surface Biomes | 27775+ (varies) | varies |
| Upper Asteroid Field | 28200-30500 | 2300 |
| **Giant Stalactites** | **30200-30500** | **300 (overlap with asteroids)** |
| **Ceiling Cave System** | **30500-30900** | **400 (NEW)** |
| Ceiling Membrane | 30900-30907 | 7 (shifted) |

## New Nodes Added

| Node | Type | Used In |
|------|------|---------|
| lazarus_space:bone_pillar | Nodebox pillar | Ruin schematics |
| lazarus_space:bone_slab | Nodebox half-slab | Ruin schematics |
| lazarus_space:ruin_wall | Normal block | Ruin schematics |
| lazarus_space:ruin_arch | Nodebox arch | Ruin schematics |
