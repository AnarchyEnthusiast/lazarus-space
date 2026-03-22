# PROMPTS_005_UPDATE_043 — Livable Asteroid Noise Crop Fix, Tungsten Ore

SpecSwarm command: `/modify`

This update fixes livable asteroids being chopped flat by the asteroid field edge noise, and adds tungsten as a new ore with full crafting chain.

---

## Prompt 1 of 2 — Livable Asteroids Respect Edge Noise

### Files: `bio_mapgen.lua`

The hollow livable asteroids (the spheres with dirt, grass, and water inside) are being cut flat by the asteroid field edge noise displacement added in UPDATE_042. When a livable asteroid extends past the displaced edge boundary, it gets cleanly sliced off instead of tapering naturally. This looks terrible — half-spheres with flat exposed cross-sections.

#### Fix: Livable Asteroids Override Edge Noise

Livable asteroids must be treated as complete structures that are NOT cropped by the edge noise. When generating the asteroid field:

1. **Identify livable asteroid volumes first**: Before applying the edge noise crop, determine the full bounding sphere of every livable asteroid (center position + outer radius).

2. **Exempt livable asteroid volumes from edge cropping**: When the edge noise displacement would remove a block that falls within a livable asteroid's bounding sphere, skip the removal. The livable asteroid's generation takes priority over the edge noise crop.

3. **Apply to BOTH edges**: This exemption applies to both the bottom edge noise (±30 blocks) and the top edge noise (±25 blocks). A livable asteroid near either edge should remain fully intact.

4. **Allow partial barren asteroids**: Regular barren asteroids CAN still be cropped by the edge noise — only livable (hollow, spherical) asteroids are protected. Barren asteroids being sliced at the edges is fine and looks natural.

#### Implementation Approach

The simplest approach is to check during the edge crop pass:
- For each position that the edge noise would convert to air, check if that position falls within any livable asteroid's radius
- If yes, keep the block (don't crop it)
- If no, proceed with the crop normally

Since livable asteroids use a cell-based system, checking neighboring cells for livable asteroid centers is already part of the generation logic. Reuse that cell lookup during the edge crop pass.

---

## Prompt 2 of 2 — Tungsten Ore, Ingots, Lumps, and Blocks

### Files: `bio_nodes.lua`, `bio_mapgen.lua`, `bio_generate_textures.py`

Add tungsten as a new minable ore that generates in the biological dimension, with a full crafting chain: ore → raw lump → ingot → block.

#### New Nodes (4 nodes)

Register in `bio_nodes.lua`:

**`lazarus_space:tungsten_ore`**
- **Description**: "Tungsten Ore"
- **Drawtype**: `normal`
- **Texture**: Generate in `bio_generate_textures.py` — dark grey base matching the host rock, with visible metallic blue-grey ore veins/specks. Base (70, 70, 75) with bright metallic specks (140, 145, 160). 16×16 pixels.
- **Groups**: `cracky=2`
- **Sounds**: stone sounds
- **Drop**: `lazarus_space:tungsten_lump` (1 lump per ore block)

**`lazarus_space:tungsten_lump`**
- **Description**: "Tungsten Lump"
- **Inventory image**: Generate — small rough metallic blue-grey nugget. Dark steel color (100, 105, 115) with lighter highlights (160, 165, 175). 16×16 pixels.
- **This is a craftitem, NOT a node** — register with `minetest.register_craftitem()`

**`lazarus_space:tungsten_ingot`**
- **Description**: "Tungsten Ingot"
- **Inventory image**: Generate — refined metallic bar, polished steel blue-grey. Base (140, 145, 155) with bright highlight stripe (180, 185, 195). 16×16 pixels.
- **This is a craftitem** — register with `minetest.register_craftitem()`

**`lazarus_space:tungsten_block`**
- **Description**: "Tungsten Block"
- **Drawtype**: `normal`
- **Texture**: Generate — solid polished metallic surface, dense steel blue-grey with subtle grid/tile pattern. Base (130, 135, 145) with lighter edges (160, 165, 175). 16×16 pixels.
- **Groups**: `cracky=1` (very hard — tungsten is one of the hardest metals)
- **Sounds**: metal sounds
- **Light source**: 0

#### Crafting Recipes

```lua
-- Tungsten Lump → Tungsten Ingot (smelting)
minetest.register_craft({
    type = "cooking",
    output = "lazarus_space:tungsten_ingot",
    recipe = "lazarus_space:tungsten_lump",
    cooktime = 10,
})

-- 9 Tungsten Ingots → Tungsten Block
minetest.register_craft({
    output = "lazarus_space:tungsten_block",
    recipe = {
        {"lazarus_space:tungsten_ingot", "lazarus_space:tungsten_ingot", "lazarus_space:tungsten_ingot"},
        {"lazarus_space:tungsten_ingot", "lazarus_space:tungsten_ingot", "lazarus_space:tungsten_ingot"},
        {"lazarus_space:tungsten_ingot", "lazarus_space:tungsten_ingot", "lazarus_space:tungsten_ingot"},
    },
})

-- Tungsten Block → 9 Tungsten Ingots (reverse)
minetest.register_craft({
    output = "lazarus_space:tungsten_ingot 9",
    recipe = {
        {"lazarus_space:tungsten_block"},
    },
})
```

#### Ore Generation

Register tungsten ore generation in `bio_mapgen.lua` using Minetest's built-in ore registration system:

```lua
minetest.register_ore({
    ore_type = "scatter",
    ore = "lazarus_space:tungsten_ore",
    wherein = {"lazarus_space:flesh", "lazarus_space:bone", "lazarus_space:cartilage"},
    clust_scarcity = 14 * 14 * 14,
    clust_num_ores = 3,
    clust_size = 3,
    y_min = 26927,
    y_max = 29200,
})
```

This generates tungsten in small clumps of ~3 ore blocks within a 3-block cluster, scattered throughout the biological dimension wherever flesh, bone, or cartilage exists. The scarcity of `14*14*14` (2744) means roughly 1 cluster per 2744-block volume — moderately rare but findable with exploration.

**If `minetest.register_ore` doesn't work well with custom mapgen** (because the biological dimension uses VoxelManip-based generation rather than the engine's built-in mapgen), implement ore placement manually in the VoxelManip pass:

- During mapgen, after placing all terrain blocks, scan for `flesh`, `bone`, and `cartilage` blocks
- At each qualifying position, use the improved hash function with a unique seed to determine if tungsten ore spawns
- Rate: approximately 1 in 2500 qualifying blocks triggers an ore cluster
- When triggered, place 2-4 `tungsten_ore` blocks in a tight clump (the trigger block plus 1-3 random neighbors that are also flesh/bone/cartilage)
- Apply to the entire dimension height range (y=26927 to y=29200)

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Livable asteroids exempt from edge noise cropping — full spheres preserved at both field edges, barren asteroids still cropped normally |
| 2 | Tungsten ore system: ore block (generates in flesh/bone/cartilage, small clumps), raw lump (drop), ingot (smelted from lump), block (9 ingots). Full crafting chain with reverse recipe. |

## Nodes Added (2 placeable + 2 craftitems)

| New Node/Item | Type | Purpose |
|---------------|------|---------|
| `tungsten_ore` | Node, cracky=2 | Ore block, drops lump |
| `tungsten_lump` | Craftitem | Raw material, smelts to ingot |
| `tungsten_ingot` | Craftitem | Refined material, crafts to block |
| `tungsten_block` | Node, cracky=1 | Storage block, very hard |

## Node Count: 40 + 2 placeable nodes = **42** (craftitems don't count as terrain nodes)
