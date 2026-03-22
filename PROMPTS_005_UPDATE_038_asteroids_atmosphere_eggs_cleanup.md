# PROMPTS_005_UPDATE_038 — Asteroid Cleanup, Atmosphere Lock, Egg Clusters, Livable Asteroids, Grass Fixes

SpecSwarm command: `/modify`

This update crops the asteroid field edges with noise, reworks livable asteroid interiors, locks the dimension to permanent dusk with short fog, increases abandoned structures with iron, adds egg cluster decorations across all biomes, fixes grass issues, increases coral cliff cutouts, embeds stalactites deeper, and makes upper asteroids sparser with patchy sinew.

---

## Prompt 1 of 5 — Asteroid Field Edge Noise, Sparsity, Sinew, and Stalactites

### Files: `bio_mapgen.lua`

#### Noisy Edges on Asteroid Field Top and Bottom

The upper asteroid field currently has flat horizontal boundaries at the top and bottom. Both edges need heavy noise displacement so they look organic and irregular, not like a flat plane was sliced through.

**Bottom edge** (approximately y=MAX_BIOME_Y+20, the asteroid field floor):

Apply a 2D Perlin noise layer sampled at (x, z) to displace the bottom boundary vertically:
- **Spread**: 15-25 (small scale — creates rough, choppy variation)
- **Octaves**: 3
- **Persistence**: 0.6 (aggressive detail)
- **Amplitude**: ±20 blocks of vertical displacement

At each (x, z) position, the effective bottom of the asteroid field = `base_bottom + noise_displacement`. Asteroids only generate above this displaced bottom. This creates a ragged, uneven lower edge — some spots hang lower, others are cut higher.

**Top edge** (approximately y=28693, the asteroid field ceiling):

Apply a separate 2D Perlin noise (different seed) to displace the top boundary:
- **Spread**: 20-30
- **Octaves**: 3
- **Persistence**: 0.6
- **Amplitude**: ±15 blocks of vertical displacement

Same principle — the effective top of the asteroid field varies per (x, z) position. This creates an irregular upper boundary instead of a clean horizontal cutoff.

#### Make Upper Asteroids More Sparse

Reduce asteroid density throughout the upper half of the asteroid field:

- In the upper 50% of the asteroid field height, increase the density threshold by 0.08 (making it harder for asteroids to qualify as solid). This thins out the upper asteroids noticeably.
- The lower 50% keeps its current density unchanged.

#### Sinew Covering — More Patchy, Less Noisy

The `sinew` blocks that cover asteroid surfaces need to be much more patchy (appearing in scattered islands rather than solid sheets) and the noise pattern needs to be smoother/less chaotic:

- **Increase the sinew noise spread** by 100% (double it). This makes sinew patches larger and smoother rather than small speckled noise.
- **Tighten the sinew noise threshold** — if sinew currently appears where noise > X, change to noise > X+0.2 (or equivalent). This dramatically reduces the total surface area covered by sinew, making it appear in scattered patches rather than near-continuous coverage.
- The result should be: most of the asteroid surface is `asteroid_shell`, with occasional larger patches of `sinew` rather than the current noisy full coverage.

#### Less Surface Detail on Upper Asteroids

The asteroid surface displacement noise that creates bumps and protrusions on individual asteroids:
- In the upper 50% of the field, reduce the displacement amplitude by 50%. Upper asteroids should be smoother and rounder.
- In the lower 50%, keep the current displacement (already smoothed in UPDATE_035 for the very bottom).

#### Embed Stalactites Deeper in Ceiling

The stalactites that hang from the ceiling cave bottom cap currently start at the displaced bottom surface of the cap. Embed them 3-5 blocks deeper into the cap so they appear to grow out of the solid material rather than being tacked onto the surface:

- Move the stalactite attachment point UP by 4 blocks (into the cap solid material)
- The stalactite's base radius carves into the cap, creating a smooth transition from cap to stalactite
- At the attachment point inside the cap, replace cap material with the stalactite's outer material (`bone`) for a seamless blend

---

## Prompt 2 of 5 — Livable Asteroid Interior Rework

### Files: `bio_mapgen.lua`, `bio_nodes.lua`

The hollow livable asteroids in the upper asteroid field need interior improvements.

#### More Aggressive Interior Deformation

The noise that deforms the interior cavity shape of livable asteroids needs to be more extreme so the interiors feel like organic chambers, not smooth spheres:

- **Increase interior deformation noise amplitude** by 60%. If the current amplitude is A, change to A×1.6.
- **Decrease the deformation noise spread** by 30% (spread × 0.7). Smaller spread = more detailed, aggressive deformation with tighter bumps and pockets.
- The interiors should feel like irregular organic cavities — bulging walls, narrow passages between chambers, uneven floors.

#### Replace asteroid_glow_ceiling

Remove `lazarus_space:asteroid_glow_ceiling` entirely. Replace all its uses:

- Where `asteroid_glow_ceiling` was used for the interior ceiling of hollow asteroids, use a mix of `cyst_wall` (60%) and `cartilage` (40%). Select between them using the existing interior detail noise.
- `cyst_wall` provides a pale yellowish ceiling look. `cartilage` provides blue-white structural variety.
- Both are already registered nodes — no new registrations needed.

Remove the `asteroid_glow_ceiling` node registration from `bio_nodes.lua`. Remove its texture generation from `bio_generate_textures.py`. Remove all content ID references (`c_asteroid_glow_ceiling`). Search the entire codebase for any remaining references.

**Node count: 67 → 66** (-1 removed)

#### Add Default Blocks to Livable Asteroid Interiors

Add familiar default blocks inside the livable asteroid cavities to make them feel habitable:

- **`default:dirt_with_grass`**: Place on the floor of the cavity (where there's a solid block below and air above). Rate: 40% of qualifying floor positions. This creates patches of grassy ground inside the asteroids.
- **`default:stone`**: Mix into the asteroid walls. Where the interior wall material would normally be `asteroid_shell`, replace 20% with `default:stone`. Use noise-based selection so stone appears in patches, not randomly speckled.
- **`default:dirt`**: Place as a 1-2 block layer beneath `default:dirt_with_grass` positions.

These default blocks make the livable asteroids feel like small habitable islands — patches of normal terrain trapped inside organic asteroid shells.

---

## Prompt 3 of 5 — Permanent Dusk Atmosphere

### Files: `bio_mapgen.lua`

Lock the biological dimension to a permanent dusk atmosphere with short fog distance and no visible sun.

#### Override Day/Night Ratio

When a player is in the biological dimension (y=27006 to y=29200), override their day/night lighting ratio to simulate permanent dusk:

```lua
player:override_day_night_ratio(0.35)
```

A ratio of 0.35 creates a dim twilight — dark enough to feel oppressive but bright enough to navigate without torches in open areas. The glowing mushrooms and other light sources become important for visibility in caves and enclosed spaces.

Add this call alongside the existing sky/fog override in the globalstep. When the player leaves the dimension, clear the override:

```lua
player:override_day_night_ratio(nil)
```

Passing `nil` restores the normal time-based day/night cycle.

#### Reduce Fog Distance

Change the fog distance from 200 to 100 blocks:

```lua
player:set_fog({
    fog_start = 0.0,
    fog_distance = 100,
    fog_color = {r = 60, g = 10, b = 10}
})
```

This significantly reduces visibility — the dark red fog closes in much tighter, making the world feel claustrophobic and oppressive. Players can only see about 100 blocks before everything fades to deep red.

#### No Sun or Sun Glow

Ensure the sun and its glow/halo are completely hidden:

```lua
player:set_sun({visible = false, sunrise_visible = false})
```

The `sunrise_visible = false` parameter specifically hides the sun glow effect that can appear even when the sun itself is hidden. Both must be explicitly set to false.

Also verify moon and stars are hidden (should already be set from previous updates):
```lua
player:set_moon({visible = false})
player:set_stars({visible = false})
player:set_clouds({density = 0})
```

#### Combined Override Block

The full atmosphere setup when entering the bio dimension should be:

```lua
-- Sky
player:set_sky({
    type = "plain",
    base_color = {r = 30, g = 5, b = 5},
    clouds = false,
})

-- Fog
player:set_fog({
    fog_start = 0.0,
    fog_distance = 100,
    fog_color = {r = 60, g = 10, b = 10}
})

-- Lighting
player:override_day_night_ratio(0.35)

-- Celestial
player:set_sun({visible = false, sunrise_visible = false})
player:set_moon({visible = false})
player:set_stars({visible = false})
player:set_clouds({density = 0})
```

And when leaving:
```lua
player:set_sky({type = "regular"})
player:set_fog({})
player:override_day_night_ratio(nil)
player:set_sun({visible = true, sunrise_visible = true})
player:set_moon({visible = true})
player:set_stars({visible = true})
player:set_clouds({density = 0.4})
```

---

## Prompt 4 of 5 — Structures More Common with Iron, and Egg Clusters

### Files: `bio_schematics.lua`, `bio_mapgen.lua`, `biomes/*.lua`

#### Increase Abandoned Structure Frequency

All existing abandoned structures (ruin schematics in rib fields, marsh, nerve thicket, vein flats + the new outposts in vein flats from UPDATE_037) need to be more common:

- **Double the placement rate** for all structure types. If a structure currently spawns at 1 in N positions, change to 1 in N/2.
- Apply this to every biome that has structure placement.

#### Add Default Iron to Structures

Add `default:steelblock` (iron/steel blocks) to all abandoned structure schematics. These represent materials brought by past visitors — tools, support beams, and supplies left behind.

For each existing schematic variant:
- **ruin_small_wall**: Add 1-2 `default:steelblock` embedded in the wall (30% probability each). Represents iron reinforcement.
- **ruin_pillar_pair**: Add 1 `default:steelblock` at the base of one pillar (50% probability). Represents a supply cache.
- **ruin_archway**: Add 1-2 `default:steelblock` in the foundation (40% probability). Represents structural reinforcement.
- **ruin_foundation**: Add 2-3 `default:steelblock` scattered inside the foundation perimeter (30% probability each). Represents abandoned equipment.
- **outpost_shelter**: Add 1-2 `default:steelblock` inside the shelter (40% probability). Represents stored supplies.
- **outpost_watchtower**: Add 1 `default:steelblock` at the base (50% probability). Represents an anchor point.
- **outpost_ruin**: Add 2-4 `default:steelblock` scattered in the debris (30% probability each). Represents the remains of a well-supplied camp.

#### Egg Clusters Across All Surface Biomes

Add large clusters of spheroid shapes partially embedded in the surface across all 6 surface biomes. These look like groups of organic eggs or cysts growing from the terrain.

**Cluster generation** (procedural, not schematics):

Each cluster consists of 3-6 spheroids grouped together:
- **Spheroid diameter**: 3-7 blocks each (randomized per spheroid)
- **Embedding**: Each spheroid is positioned so its bottom 30-50% is below the surface level (partially buried)
- **Spacing**: Spheroids in a cluster are placed 1-3 blocks apart, occasionally overlapping slightly
- **Cluster footprint**: approximately 10-20 blocks across

**Materials**:
- **Shell**: `membrane` (outer 1-block-thick layer of each spheroid)
- **Interior**: `mucus` (fills the inside of each spheroid)
- Where spheroids overlap, the overlapping interior merges (no double-shell at overlap points)

**Placement**:
- Rate: 1 in 5000 surface positions triggers a cluster
- Use improved hash with unique seed
- Place in ALL 6 surface biomes
- Require relatively flat ground (surface y within ±2 blocks of neighbors)

**Visual effect**: Groups of pale pink egg-like lumps protruding from the flesh ground, semi-translucent membrane shells with slimy mucus visible inside. Alien and unsettling.

---

## Prompt 5 of 5 — Grass Fixes, Coral Cliff Cutouts, and Tall Grass Lines

### Files: `biomes/coral_cliffs.lua`, `bio_schematics.lua`, `bio_mapgen.lua`, `biomes/*.lua`

#### Fix Floating Grass in Coral Cliffs

Where caves are carved into the coral cliff terrain, grass nodes sometimes remain floating in the air above the carved-out space. Fix this specifically in `biomes/coral_cliffs.lua`:

- After cave carving in the coral cliff biome, run a cleanup pass on grass nodes (bio_grass_1, bio_grass_3, bio_grass_tall, bio_sprout, bio_tendril, bio_polyp_plant)
- For each plant node in the coral cliff zone, check if the block directly below is air or has been carved away
- If the ground below was removed by cave carving, remove the plant node too

This should also apply the universal ground check from UPDATE_033 Prompt 4 if it isn't already applied to coral cliffs specifically.

#### Slightly More Coral Cliff Cutouts

The cave cutouts carved into the coral cliff faces look great. Increase their frequency slightly:

- Increase the cutout generation rate by 25%. If the current carving noise threshold is T, adjust it so approximately 25% more volume qualifies for carving.
- Do NOT change the cutout shape or size — just make them slightly more common so there are more interesting cave openings in the cliff faces.

#### Fix Tall Bio Grass Straight Lines

`bio_grass_tall` clusters are generating in visible straight lines instead of random-looking distributions. This is the same type of hash pattern issue that was fixed for regular grass in UPDATE_032.

Find the placement code for `bio_grass_tall` (likely in `bio_schematics.lua` or biome files). The straight line pattern is caused by a hash function that produces linear alignment:

- Replace the tall grass placement hash with the improved hash function (from UPDATE_032 Prompt 1) if it hasn't been applied to tall grass yet
- Use a DIFFERENT seed value than regular grass to avoid spatial correlation
- Verify that the placement is truly randomized by checking that the hash includes BOTH x and z coordinates with proper mixing (not just one axis)

If the improved hash IS already being used but the pattern persists, the issue may be that tall grass uses a secondary placement condition (like a noise threshold or modulo check) that creates alignment. Find and fix whatever secondary condition is causing the rows.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Asteroid field edges get ±15-20 block noise displacement (not flat), upper asteroids sparser + smoother, sinew coverage doubled in spread and tightened threshold (more patchy), stalactites embedded 4 blocks deeper in cap |
| 2 | Livable asteroid interiors: 60% more aggressive deformation, `asteroid_glow_ceiling` removed (→ cyst_wall 60% + cartilage 40%), default grass/dirt/stone added to floors and walls |
| 3 | Permanent dusk via `override_day_night_ratio(0.35)`, fog distance reduced to 100, sun glow hidden with `sunrise_visible=false` |
| 4 | All abandoned structures 2× more common, `default:steelblock` added to every schematic variant. New egg clusters (3-6 membrane/mucus spheroids) at 1/5000 across all surface biomes |
| 5 | Floating grass cleaned up in coral cliffs after cave carving, coral cliff cutouts increased 25%, tall bio_grass line pattern fixed |

## Nodes Removed (1)

| Removed Node | Replaced By |
|-------------|-------------|
| `asteroid_glow_ceiling` | `cyst_wall` (60%) + `cartilage` (40%) |

## Node Count: 67 → 66
