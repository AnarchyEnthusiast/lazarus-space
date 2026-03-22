# PROMPTS_005_UPDATE_039 — Cave Transitions, Asteroid Rework, Follicle Forest, Spine Trees, Egg Tuning

SpecSwarm command: `/modify`

This update cleans up noisy cave biome transitions, reworks the upper asteroid field balance, adds a 7th surface biome (Follicle Forest), adds large spine trees to flesh flats, and adjusts egg cluster frequency/size.

---

## Prompt 1 of 5 — Clean Up Cave Biome Transitions

### Files: `bio_mapgen.lua`

The transition zones between the three organic cave biomes (y=27026-27697) are generating noisy, chaotic terrain with floating blocks where biome materials blend. This needs to be smoothed out.

#### Identify the Transition Zones

The cave biome selector noise divides the caves into three biomes with boundaries at noise values -0.3 and 0.3. Transition zones exist around these boundaries (likely 0.1 noise units wide on each side, so -0.4 to -0.2 and 0.2 to 0.4).

#### Fix 1: Smooth Material Blending

In transition zones, the current blending likely intermixes materials from both adjacent biomes at a per-block level using noise, creating a speckled/chaotic appearance. Replace this with a smoother gradient:

- Instead of per-block random selection between biome materials, use a **single large-scale noise** (spread 30-50) to choose which biome's materials to use at each position in the transition zone.
- At the biome boundary midpoint: 50/50 chance of either biome
- Moving toward biome A: probability shifts linearly to 100% biome A
- Moving toward biome B: probability shifts linearly to 100% biome B
- The key difference: the noise that selects the biome at each position should have a LARGE spread (30-50 blocks), so the transition consists of large patches of biome A and large patches of biome B, NOT individual speckled blocks

This creates a transition that looks like biome A territory gradually giving way to biome B territory in large organic patches.

#### Fix 2: Floating Block Cleanup in Transition Zones

After cave generation in the transition zones (the noise ranges -0.4 to -0.2 and 0.2 to 0.4), run a floating block cleanup pass:

- For each non-air block in the transition zone, count air neighbors on all 6 sides
- If 5 or 6 neighbors are air, replace the block with air
- Run this cleanup pass TWICE (two iterations) in transition zones only — the second pass catches blocks that became floating after the first pass removed their neighbors

This is the same cleanup approach used for the marrow cave smoothing (UPDATE_033) and lower asteroid cleanup (UPDATE_035), but applied specifically to transition zones.

#### Fix 3: Match Cave Shape Across Transitions

If each cave biome uses slightly different cave carving parameters (different thresholds or noise contributions), the transition zone can create mismatched cave shapes — one biome's cave wall ending abruptly where the other biome's wall begins.

In transition zones, interpolate the cave carving threshold between the two adjacent biomes' values. If biome A carves at threshold 0.05 and biome B at 0.10, the transition zone should smoothly interpolate between them based on the blending weight. This ensures cave shape is continuous across biome boundaries.

---

## Prompt 2 of 5 — Upper Asteroid Field Rework

### Files: `bio_mapgen.lua`

The upper asteroid field needs a significant balance pass. General (barren) asteroids should be smoother and rarer. Hollow livable (spherical) asteroids should be slightly smaller but more common.

#### General (Barren) Asteroids — Smoother and Rarer

1. **Reduce density**: Increase the asteroid density threshold by 0.06 across the entire field. This means fewer positions qualify as "inside an asteroid," creating more open space between asteroids. The field should feel spacious with distinct individual asteroid bodies floating in air, not a dense packed mess.

2. **Smoother surfaces**: Increase the asteroid shape noise spread by 50% (spread × 1.5). This makes individual asteroids have broader, gentler surface features — smooth boulders rather than jagged rocks.

3. **Reduce surface displacement amplitude** by another 30% on top of previous reductions. The total effect across updates should be asteroids with gently undulating surfaces, not rough spiky noise.

4. **Minimum asteroid size**: If the noise-based generation creates very small asteroid fragments (1-3 blocks), suppress them. Add a check: after determining a block is "inside" an asteroid, verify that it has at least 3 other asteroid blocks within a 2-block radius. If not, skip it (replace with air). This eliminates tiny floating fragments.

#### Hollow Livable Asteroids — Smaller and More Common

1. **Reduce size by 20%**: If livable asteroids have a radius parameter, multiply it by 0.8. If they use a cell-based system with size ranges, reduce both min and max radius by 20%.

2. **Increase frequency by 40%**: If livable asteroids spawn with probability P per cell, increase to P × 1.4. If they use a spacing/cell system, reduce cell size by ~15% (more cells = more opportunities for livable asteroids).

3. **Keep interior changes from UPDATE_038**: The grass, stone, cyst_wall ceiling, and aggressive deformation should remain. Just make the exterior shell smaller and spawn more of them.

The overall asteroid field should feel like: large open void with scattered smooth floating rock masses, punctuated by relatively common smaller livable spheres that players can find and explore.

---

## Prompt 3 of 5 — New Biome: Follicle Forest

### Files: `biomes/follicle_forest.lua` (NEW), `bio_nodes.lua`, `bio_mapgen.lua`, `bio_generate_textures.py`

Add a 7th surface biome: the **Follicle Forest** — a dense, dark vertical forest of giant hair follicles growing from oily sebaceous terrain. Very low visibility, claustrophobic, players must navigate between and climb massive follicle trunks.

#### Biome Noise Range

Insert the Follicle Forest into the surface biome noise spectrum by splitting the Nerve Thicket range:

| Biome | Old Range | New Range |
|-------|-----------|-----------|
| Nerve Thicket | 0.15 to 0.5 | 0.15 to 0.35 |
| **Follicle Forest** | *(new)* | **0.35 to 0.5** |
| Abscess Marsh | > 0.5 | > 0.5 (unchanged) |

Update the biome dispatch noise boundaries in `bio_mapgen.lua`. Add transition zones at the new boundaries (0.35 ± 0.05).

#### New Nodes (3 nodes)

Register in `bio_nodes.lua`:

**`lazarus_space:follicle_sheath`**
- Description: "Follicle Sheath"
- Hard, keratin-like tube wall material
- Drawtype: `normal`
- Texture: Generate in `bio_generate_textures.py` — pale amber-yellow with vertical grain lines. Base color (180, 150, 80) with darker streaks (140, 110, 50). 16×16 pixels.
- Groups: `cracky=2`
- Sounds: stone sounds
- Light source: 0

**`lazarus_space:sebum`**
- Description: "Sebum"
- Oily, waxy ground material
- Drawtype: `normal`
- Texture: Generate — dark yellow-brown, greasy/glossy look. Base color (100, 85, 40) with oily sheen spots (120, 100, 55). 16×16 pixels.
- Groups: `crumbly=2, snappy=3`
- Sounds: dirt sounds
- Light source: 0

**`lazarus_space:hair_strand`**
- Description: "Hair Strand"
- The actual hair material extending above follicles
- Drawtype: `plantlike` (or `nodebox` with thin vertical box `{-0.1, -0.5, -0.1, 0.1, 0.5, 0.1}`)
- Texture: Generate — dark brown-black fibrous strand. Base color (40, 30, 20) with slight lighter streaks (60, 45, 30). 16×16 pixels.
- Paramtype: "light"
- Walkable: false
- Climbable: true (players can climb up the hair strands)
- Groups: `snappy=3, choppy=3`
- Sounds: leaves sounds
- Light source: 0 (this biome is DARK)

#### Terrain Generation

Register via `lazarus_space.register_surface_biome()` in `biomes/follicle_forest.lua`.

**Ground layer**:
- Base terrain at y=27775 with height amplitude of 2.0 (very flat, slight undulation)
- Top 2 blocks: `sebum` (oily ground surface)
- Below sebum: `flesh` (standard biological base)

**Giant Follicle Trunks** (the main feature):

Generate large vertical tube structures growing up from the ground:
- Use a cell-based system with cells of 8×8 blocks (in x, z)
- Each cell has a 40% chance of containing a follicle
- **Follicle outer radius**: 2-4 blocks
- **Follicle inner radius**: outer - 1 (hollow core, 1-3 blocks wide)
- **Follicle height**: 15-40 blocks tall (randomized per follicle)
- **Wall material**: `follicle_sheath`
- **Interior**: air (hollow tube players can climb inside)
- **Base**: embedded 2-3 blocks into the ground (rooted)

At each follicle's (x, z) center, for each y from ground-3 to ground+height:
- Calculate distance from center axis
- If distance ≤ outer_radius AND distance > inner_radius: place `follicle_sheath`
- If distance ≤ inner_radius: place air (hollow core)

**Hair Extensions** (above follicles):

Above each follicle trunk (from top of follicle to top + 5-15 blocks):
- Place `hair_strand` blocks in a scattered vertical column
- 1-3 strands per follicle, slightly offset from center
- These thin strands extend above the follicle tops into the air

**Ground Cover**:
- Between follicles: `sebum` ground with occasional `mucus` patches (1 in 20 surface positions)
- NO grass in this biome (too dark for growth)
- NO glowing mushrooms or light-emitting plants on the surface (this biome is deliberately dark)
- Very rare `bio_sprout` (1 in 300 positions) with light_source providing tiny pinpricks of light

**Low Visibility Design**:
- The dense follicle trunks block horizontal line of sight
- The hair strands above create a loose canopy that blocks vertical light
- No surface light sources except extremely rare bio_sprouts
- The overall effect: a dark, claustrophobic forest of giant organic tubes. Players navigate by feel and the distant glow of other biomes at the edges.

**Applying noise displacement to follicles**: Apply the same terrain detail noise to slightly lean/bend follicle positions — offset the center axis by ±1 block at the top relative to the base, based on a hash of the follicle position. This prevents a perfectly straight grid of tubes.

#### Check neighboring cells

When generating follicles, check the current cell and 8 surrounding cells to properly render follicles whose radius extends across cell boundaries.

---

## Prompt 4 of 5 — Spine Trees on Flesh Flats

### Files: `bio_schematics.lua`, `bio_mapgen.lua`, `biomes/rib_fields.lua`, `biomes/vein_flats.lua`

Add very large spine-like tree structures to flat flesh areas across the surface biomes. These resemble vertebral columns growing upward from the ground — stacked bone vertebrae with cartilage disc spacers, branching nerve fibers as "branches."

#### Spine Tree Generation (Procedural)

Generate spine trees procedurally in `bio_schematics.lua` or `bio_mapgen.lua`:

**Trunk** (vertebral column):
- Height: 20-45 blocks tall
- Built as repeating vertebra segments:
  - Each vertebra: 3 blocks of `bone` stacked vertically, with a cross-section of 3×3 blocks (with corners cut — forming an octagonal/rounded shape using the center block and 4 cardinal blocks, leaving diagonals as air)
  - Between each vertebra: 1 block of `cartilage` (the intervertebral disc), same cross-section
  - Segment height: 4 blocks (3 bone + 1 cartilage), repeating up the full height

**Branches** (nerve roots):
- At every 2nd or 3rd vertebra segment (every 8-12 blocks of height), extend 1-2 branches outward
- Each branch: a line of `nerve_fiber` blocks extending 3-8 blocks horizontally from the trunk
- Branches angle slightly upward (1 block up for every 2-3 blocks outward)
- Branch direction: random cardinal direction, but no two adjacent branches point the same way
- At the tip of each branch: 1-2 `nerve_root` blocks dangling down (hanging like leaves)

**Crown** (at the top):
- The topmost 2 segments narrow to a 1×1 cross-section (single column of bone + cartilage)
- 3-4 short `nerve_fiber` branches radiate outward from the top (3-5 blocks each)
- Creates a sparse crown silhouette

**Base** (roots):
- The bottom 2 blocks of the trunk widen to a 5×5 cross-section (with rounded corners)
- `bone` blocks extend 2-3 blocks outward along the ground in 2-3 directions as surface roots
- Roots are 1 block tall, tapering from 2 blocks wide to 1 block at the tip

#### Placement

- **Rib Fields**: 1 in 4000 surface positions on flat flesh ground (between ribs)
- **Vein Flats**: 1 in 3500 surface positions on flat terrain
- **Nerve Thicket**: 1 in 5000 surface positions (fewer, since it already has nerve tree structures)
- **Other biomes**: none (coral cliffs are too steep, marsh is too wet, follicle forest already has vertical structures, molar peaks already have tall features)
- Require flat terrain: surface y within ±1 of neighboring positions
- Use improved hash with unique seed

The spine trees should be dramatic landmarks visible from a distance — tall bone columns rising above the flesh terrain, with skeletal branches reaching outward.

---

## Prompt 5 of 5 — Egg Cluster Tuning

### Files: `bio_schematics.lua` or `bio_mapgen.lua` (wherever egg clusters from UPDATE_038 are generated)

#### Reduce Frequency by 50%

Change the egg cluster placement rate from 1 in 5000 to 1 in 10000 surface positions. They should be rare discoveries, not frequent terrain features.

#### Increase Size by 33%

Scale up all egg cluster spheroid dimensions by 33%:
- **Spheroid diameter**: was 3-7 blocks, now 4-9 blocks each
- **Cluster footprint**: was 10-20 blocks across, now 13-27 blocks across
- **Embedding depth**: still 30-50% below surface (proportionally deeper since spheroids are bigger)
- **Shell thickness**: still 1 block of `membrane` (don't scale shell thickness)
- **Interior**: still `mucus`

The clusters should feel like significant organic landmarks — large lumps of eggs partially buried in the terrain, visible from moderate distance.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Cave biome transitions: large-patch blending instead of per-block noise, 2-pass floating block cleanup in transition zones, interpolated cave carving thresholds |
| 2 | Barren asteroids: +0.06 density threshold (rarer), shape noise spread ×1.5 (smoother), displacement -30%, min size check eliminates fragments. Livable asteroids: radius ×0.8 (smaller), frequency ×1.4 (more common) |
| 3 | New Follicle Forest biome (noise 0.35-0.5): 3 new nodes (follicle_sheath, sebum, hair_strand). Giant hollow tube follicles (2-4 radius, 15-40 tall, 40% per cell), climbable hair extensions, sebum ground, deliberately dark/low visibility |
| 4 | Spine trees on flesh flats: vertebral column trunks (20-45 blocks, stacked bone+cartilage), nerve_fiber branches, placed in rib fields (1/4000), vein flats (1/3500), nerve thicket (1/5000) |
| 5 | Egg clusters: rate halved (1/5000 → 1/10000), size increased 33% (diameter 4-9, footprint 13-27) |

## Nodes Added (3)

| New Node | Type | Purpose |
|----------|------|---------|
| `follicle_sheath` | Normal block | Follicle tube walls (hard, amber-yellow) |
| `sebum` | Normal block | Oily ground surface in Follicle Forest |
| `hair_strand` | Plantlike/nodebox, climbable | Dark hair extensions above follicles |

## Node Count: 66 + 3 = **69**

## Updated Biome Noise Ranges

| Biome | Noise Range |
|-------|-------------|
| Rib Fields | < -0.6 |
| Molar Peaks | -0.6 to -0.25 |
| Vein Flats | -0.25 to -0.05 |
| Coral Cliffs | -0.05 to 0.15 |
| Nerve Thicket | 0.15 to 0.35 |
| **Follicle Forest** | **0.35 to 0.5** |
| Abscess Marsh | > 0.5 |
