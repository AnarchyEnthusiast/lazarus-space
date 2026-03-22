# PROMPTS_005_UPDATE_040 — Sinew Cleanup, Follicle Fix, Egg Tuning, Hollow Eggs, Ice Asteroids, Spheres

SpecSwarm command: `/modify`

This update removes floating sinew from asteroids, fixes follicle grounding, tunes egg cluster rarity, adds large decaying hollow egg structures, reworks ice asteroids with default blocks and rough bottom edge, and adjusts livable asteroid sphere frequency/variety.

---

## Prompt 1 of 6 — Remove Floating Sinew from Upper Asteroids

### Files: `bio_mapgen.lua`

Sinew blocks around upper asteroids are generating as floating detached blocks in the air, separate from the asteroid surfaces they're supposed to cover. Remove all floating sinew.

#### Approach: Post-Generation Cleanup

After the upper asteroid field is fully generated (all asteroid shapes, sinew placement, and surface detail are complete), run a sinew-specific cleanup pass across the entire asteroid field:

For every `sinew` block in the asteroid field zone:
1. Check all 6 neighbors (up, down, north, south, east, west)
2. Count how many neighbors are solid non-air, non-sinew blocks (i.e., `asteroid_shell`, `bone`, `flesh_dark`, `muscle`, or any other solid asteroid material)
3. If the sinew block has **fewer than 2 solid non-sinew neighbors**, replace it with air

This removes sinew blocks that are floating freely or only connected to other sinew blocks (sinew chains dangling in air). Sinew that is properly attached to asteroid surfaces (touching 2+ solid blocks) is preserved.

Run this cleanup once after all asteroid generation is complete.

#### Also: Prevent Future Floating Sinew

In the sinew placement logic itself, add a pre-check before placing each sinew block:
- Before placing sinew at any position, verify that at least 1 adjacent block (in 6 directions) is already a solid asteroid material block (not air, not sinew)
- If no adjacent solid material exists, skip the sinew placement

This prevents floating sinew from being generated in the first place, while the cleanup pass catches any that slip through.

---

## Prompt 2 of 6 — Fix Follicle Sheath Grounding

### Files: `biomes/follicle_forest.lua`

The follicle sheath structures in the Follicle Forest biome are too decayed-looking and most of them don't touch the ground. This needs to be fixed — follicles should be firmly rooted in the terrain.

#### Ensure Ground Contact

Every follicle trunk MUST connect to the ground surface. Find the follicle generation code and fix:

1. **Calculate ground level first**: For each follicle's center (x, z) position, determine the actual terrain surface y at that point (the topmost solid block). The follicle base MUST start at or below this surface y.

2. **Embed deeper**: Increase the follicle base embedding from 2-3 blocks below surface to **4-6 blocks below surface**. The follicle should be firmly rooted, not barely touching.

3. **Fill gaps below follicle**: After placing the follicle tube, check every column within the follicle's radius. If there are any air gaps between the follicle sheath blocks and the ground surface below, fill them with `follicle_sheath`. The tube must be continuously solid from its embedded base up to its full height with no missing blocks at the bottom.

4. **Ground-level flare**: At ground level (y = surface), widen the follicle outer radius by 1 block for the bottom 2 blocks of the above-ground portion. This creates a slight flare/bulge at the base where the follicle meets the ground, making it look naturally rooted rather than just a cylinder sitting on the surface.

#### Reduce Decay

The follicle trunks are too decayed with too many missing blocks:

- If the follicle wall blocks are placed with probability values (e.g., 70% chance per block), increase to **95% probability** for the lower 2/3 of the trunk height. Only the top 1/3 should have any decay/gaps, and even then at 85% probability.
- The bottom half of every follicle should be completely solid — no missing wall blocks at all.
- If there's a noise-based decay pattern, reduce its amplitude by 60% so holes are smaller and rarer.

The overall effect: follicles should look like sturdy organic tubes firmly growing from the ground, with slight weathering only at the tops.

---

## Prompt 3 of 6 — Egg Cluster Rarity and Livable Asteroid Spheres

### Files: `bio_mapgen.lua`, `bio_schematics.lua`

#### Reduce Egg Cluster Spawn Rate to 15%

The surface egg clusters (membrane/mucus spheroid groups from UPDATE_038, adjusted in UPDATE_039) are still too common. Reduce to 15% of the current rate:

- **Current rate**: 1 in 10000 surface positions
- **New rate**: 1 in 66666 surface positions (approximately 10000 / 0.15)

Round to **1 in 65000** for cleaner code. Egg clusters should be genuinely rare finds.

#### Livable Asteroid Spheres — More Common, More Size Variety

Increase frequency of hollow livable asteroid spheres by another 20% on top of the UPDATE_039 increase:
- If current probability is P, increase to P × 1.2

Increase size variation so the field has a mix of small and large spheres:
- **Current radius range**: whatever it is after UPDATE_039's 20% reduction
- **New radius range**: expand the range so the minimum is 30% smaller than current minimum and the maximum is 20% larger than current maximum
- Example: if current range is 12-24, new range would be ~8-29
- The size should be selected from a wider distribution so players encounter noticeably different sized spheres

---

## Prompt 4 of 6 — Large Decaying Hollow Egg Structures

### Files: `bio_mapgen.lua`, `bio_schematics.lua`

Add large hollow egg-shaped structures with decaying walls (holes) that spawn in three locations: on the plasma ocean floor, on the surface biomes, and inside the lower caves.

#### Egg Structure Shape

Each hollow egg is an elongated spheroid (taller than wide):
- **Aspect ratio**: height = width × 1.4 (egg-shaped, slightly pointy on top)
- **Wall material**: `membrane` (outer shell, 2 blocks thick)
- **Interior**: air (hollow)
- **Wall decay**: 20-35% of wall blocks are replaced with air, creating holes and gaps. Use noise-based decay (spread 3-5, small and chunky) so holes are grouped into larger openings rather than evenly distributed pinpricks. Holes should be bigger toward the bottom (more decay in lower 40% of the egg).
- **Floor interior**: scattered `mucus` blocks on the interior floor (30% coverage). Some `default:dirt` patches (15% coverage).

#### Variant A: Massive Ocean Floor Eggs

Spawn on the plasma ocean floor (y=27712 area, resting on whatever solid surface exists below the plasma layer):

- **Size**: 25-50 blocks wide, 35-70 blocks tall
- **Placement**: partially embedded in the ocean floor (bottom 20% buried)
- **Rate**: Use a cell system with 200×200 cells, 15% chance per cell
- **Filled with plasma**: The interior below the plasma surface level is filled with `plasma_static`. Above the plasma level (if the egg extends above), the interior is air. Players can swim into them through the decay holes.
- **Special**: 1 in 4 ocean floor eggs has a `default:steelblock` cluster (3-6 blocks) inside on the floor — abandoned equipment from past explorers.

#### Variant B: Medium Surface Eggs

Spawn on the surface biomes (all 7 biomes):

- **Size**: 8-16 blocks wide, 11-22 blocks tall
- **Placement**: partially embedded in ground (bottom 30% buried)
- **Rate**: 1 in 25000 surface positions
- **Interior**: air, with mucus floor and occasional `default:dirt` and `bio_grass_1`
- **Some eggs partially collapsed**: 30% chance that the top 25% of the egg is missing entirely (broken open), leaving a bowl-shaped ruin

#### Variant C: Medium Cave Eggs

Spawn inside the lower organic caves (y=27026-27697):

- **Size**: 6-12 blocks wide, 8-17 blocks tall
- **Placement**: sitting on cave floors (solid block below, air above)
- **Rate**: 1 in 400 qualifying cave floor positions (checked per-chunk, max 2 per chunk)
- **Interior**: air with mucus floor
- **Cave integration**: Where the egg wall intersects existing cave walls, the egg wall takes priority (carves into solid material). Where the egg extends into existing air, the wall blocks are placed normally.
- **Lighting**: Place 1-2 `glowing_mushroom` blocks on the interior floor of cave eggs for faint internal lighting

#### Shared Properties

All egg variants:
- Use the improved hash function with unique seeds per variant
- Wall decay noise uses different seeds per egg (so each egg has unique hole patterns)
- Eggs should NOT overlap with each other — check for minimum spacing (at least egg diameter × 2 between centers)

---

## Prompt 5 of 6 — Ice Asteroid Field Rework

### Files: `bio_mapgen.lua`, `bio_nodes.lua`

The frozen asteroid field (y=26927-26997) needs two changes: use default blocks instead of custom frozen blocks, and add a rough noise-cropped bottom edge.

#### Replace Frozen Blocks with Default Blocks

Replace the materials used in the frozen asteroid field:

- `lazarus_space:frozen_rock` → `default:stone` everywhere it appears in frozen asteroid generation
- `lazarus_space:frozen_ice` → `default:ice` everywhere it appears in frozen asteroid generation

After replacement, remove `lazarus_space:frozen_rock` and `lazarus_space:frozen_ice` from `bio_nodes.lua`. Remove their content ID caches. Remove their texture generation from `bio_generate_textures.py`. Search the entire codebase for any remaining references.

**2 nodes removed** (69 → 67)

The frozen asteroids now use standard Minetest blocks — stone and ice. They feel like natural icy space debris rather than custom biological material.

#### Rough Bottom Edge

The bottom of the frozen asteroid field (y=26927) is currently a flat horizontal cutoff. Add rough noise displacement:

Apply a 2D Perlin noise sampled at (x, z) to displace the bottom boundary:
- **Spread**: 10-20 (very small scale — rough, jagged)
- **Octaves**: 3
- **Persistence**: 0.7 (aggressive detail)
- **Amplitude**: ±12 blocks of vertical displacement

The effective bottom of the frozen asteroid field at each (x, z) = `26927 + noise_displacement`. Asteroids only generate above this displaced bottom. Below the displaced bottom: air (the void below the dimension).

This creates a ragged, icy underside — stalactite-like protrusions of stone and ice hanging down irregularly, rather than a clean flat floor.

---

## Prompt 6 of 6 — Node Removal Summary and Cleanup

### Files: `bio_nodes.lua`, `bio_generate_textures.py`

Verify that the following nodes removed in this update have NO remaining references anywhere in the codebase:

1. `lazarus_space:frozen_rock` — replaced by `default:stone`
2. `lazarus_space:frozen_ice` — replaced by `default:ice`

Search every `.lua` file for the string `frozen_rock` and `frozen_ice`. If any references remain (in comments, old variable names, etc.), remove or update them.

Also verify that `lazarus_space:asteroid_glow_ceiling` from UPDATE_038 was properly removed — search for any lingering references.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Floating sinew removed via post-gen cleanup (need 2+ solid non-sinew neighbors) + placement pre-check |
| 2 | Follicle sheaths: embed 4-6 blocks deep, fill gaps to ground, ground-level flare, 95% solid lower 2/3, decay only at tops |
| 3 | Egg clusters reduced to 1/65000 (15% of current), livable spheres +20% more common with wider size range (min -30%, max +20%) |
| 4 | New decaying hollow egg structures: massive on ocean floor (25-50 wide, 15% per 200×200 cell), medium on surface (8-16 wide, 1/25000), medium in caves (6-12 wide, 1/400 floor, 2/chunk max). Membrane walls with 20-35% noise decay holes, mucus/dirt interiors |
| 5 | Frozen asteroids use `default:stone` + `default:ice` instead of custom blocks. `frozen_rock` and `frozen_ice` removed. Bottom edge gets ±12 block rough noise displacement |
| 6 | Verify all removed node references are cleaned up |

## Nodes Removed (2)

| Removed Node | Replaced By |
|-------------|-------------|
| `frozen_rock` | `default:stone` |
| `frozen_ice` | `default:ice` |

## Node Count: 69 → 67
