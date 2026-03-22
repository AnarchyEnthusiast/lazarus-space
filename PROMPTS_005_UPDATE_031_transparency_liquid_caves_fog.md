# PROMPTS_005_UPDATE_031 — Transparency Reduction, Liquid Optimization, Cave Scaling, Fog Adjustment

SpecSwarm command: `/modify`

This update addresses major performance issues caused by transparent block rendering and liquid flow calculations, increases cave size, and adjusts the red fog boundary.

---

## Prompt 1 of 4 — Remove Most Transparent Blocks

### Files: `bio_nodes.lua`, `biomes/vein_flats.lua`

Transparent blocks with `use_texture_alpha = "blend"` cause significant rendering lag because the engine must sort and draw them with alpha blending. Reduce the number of transparent node types to only two — jelly and cyst_wall — and convert everything else to fully opaque.

#### Nodes to Make Opaque

Change the following nodes from transparent/blend to fully opaque:

- **`lazarus_space:membrane`** — Currently glasslike with blend alpha. Change drawtype from `glasslike` to `normal`. Remove `use_texture_alpha = "blend"`. Make the texture fully opaque (update `bio_generate_textures.py` to generate the membrane texture at alpha=255 instead of alpha=140). The node should look like a pale pink solid block. Keep all other properties (groups, sounds).

- **`lazarus_space:frozen_ice`** — Currently has alpha=200 texture. Make fully opaque. Remove `use_texture_alpha` if set. Update texture generation to alpha=255.

- **`lazarus_space:jelly`** — KEEP TRANSPARENT. This is one of the two nodes that stays translucent. Leave as-is with glasslike drawtype and blend alpha.

- **`lazarus_space:jelly_glow`** — KEEP TRANSPARENT. Same as jelly — leave as-is.

- **`lazarus_space:cyst_wall`** — KEEP TRANSPARENT. This is the other node that stays translucent. Leave as-is.

#### Vein Flats Floor Change

In `biomes/vein_flats.lua`, the biome uses `membrane` blocks at y=27775 to create a semi-transparent floor showing the red sea below. Since membrane is now opaque, this visual effect is lost. Replace the mechanic: instead of placing membrane blocks for "see-through floor" effect, just place the normal `capillary_surface` block everywhere. Remove the code that conditionally places membrane at the base level. The red sea below is no longer visible through the floor — this is an acceptable tradeoff for performance.

#### Summary of Transparent Nodes After This Change

Only 3 node types remain transparent in the entire biological dimension:
- `lazarus_space:jelly` (glasslike, blend)
- `lazarus_space:jelly_glow` (glasslike, blend)
- `lazarus_space:cyst_wall` (glasslike, blend)

Everything else is fully opaque.

---

## Prompt 2 of 4 — Reduce All Liquid Sources and Flatten Liquid Levels

### Files: `bio_mapgen.lua`, `biomes/abscess_marsh.lua`, `bio_nodes.lua`

Liquid source blocks cause lag because the engine runs liquid flow calculations for each one. Minimize source block count everywhere and ensure all liquid bodies sit at a single flat level to prevent flow.

#### Red Sea — Already Partially Fixed, Finish the Job

UPDATE_030 introduced `red_sea_static` for the ocean body. Verify and enforce:
- `red_sea_source` blocks are placed ONLY at exactly y=27774 (one single flat level)
- `red_sea_static` fills everything from y=27712 to y=27773
- There must be ZERO red_sea_source blocks at any y other than 27774
- Where debris blocks (blood_clot, fibrous_strand, flesh/muscle) are placed in the sea volume, they replace `red_sea_static`, not source blocks. If a debris block is at y=27774 (the source level), it replaces the source block — this is fine, it removes a source.

#### Jelly Membrane — Replace Liquid Seepage with Static Fill

The jelly membrane layer (y=27697-27712) currently allows gaps where red sea liquid seeps down. This creates flowing liquid in the cave ceiling area. Fix by:
- Where a gap exists in the jelly membrane (position is air), place `red_sea_static` instead of leaving air IF the position is in the upper half of the membrane (y >= 27705). This blocks liquid from flowing down while maintaining the visual of red sea bleeding into the membrane.
- Below y=27705 in the membrane, gaps remain as air (cave ceiling openings).

#### Bile Pools in Intestinal Caves — Drastic Reduction

Bile liquid pools in intestinal caves (where cave shape noise is within 0.02 below the threshold) place too many source blocks. Change:
- Reduce the noise band from 0.02 to 0.005. This creates much smaller, rarer pools.
- Cap bile source blocks to maximum 5 per x,z column in the cave layer.
- All bile source blocks in a given cave chamber must be at the SAME y-level (the lowest y where the noise qualifies). Do not place source blocks at multiple heights in the same column. Check the column from bottom up, find the first qualifying y, place a source there, and skip all other qualifying positions in that column.

#### Marrow Pools in Marrow Caves — Same Treatment

Marrow liquid pools have the same issue. Apply identical changes:
- Reduce noise band from 0.02 to 0.005.
- Cap marrow source blocks to maximum 5 per x,z column.
- All sources in a column at the same y-level (lowest qualifying y).

#### Abscess Marsh Pus — Further Reduction

UPDATE_030 already reduced pus pools to 1 block deep at the 10th percentile. Further reduce:
- Change threshold from 10th percentile to 5th percentile — only the absolute deepest depressions get pus.
- Maximum 3 pus source blocks per x,z column.
- All pus sources in a contiguous pool area must sit at the exact same y-level. When generating pus for the marsh, determine the pool y-level FIRST (the lowest terrain height in the local depression), then place all source blocks at that single y. This prevents any height variation in the pool surface which would cause flow.

#### Register New Static Liquid Fills (if not already done)

If `lazarus_space:bile_static` and `lazarus_space:marrow_static` do not already exist, register them in `bio_nodes.lua` using the same pattern as `red_sea_static`:
- Same visual appearance and animation as their liquid source counterparts
- Same `post_effect_color` and `drowning = 1`
- `walkable = false`, `pointable = false`, `diggable = false`
- NOT a liquid type — no `liquidtype`, no flow
- Groups: `not_in_creative_inventory = 1`

Where cave pools would be deeper than 1 block, fill the lower blocks with the corresponding static variant instead of source blocks. The source block sits only at the top surface of the pool.

---

## Prompt 3 of 4 — Increase Cave Size

### File: `bio_mapgen.lua` (organic cave layer section)

The organic caves (y=27006-27697) are too small and cramped. Make them significantly larger by adjusting the cave shape noise and thresholds.

#### Increase Cave Shape Noise Spread

Change the `cave_shape_noise` spread from 30 to 60. This doubles the scale of cave features — tunnels, chambers, and voids will all be roughly twice as wide and tall. Individual cave chambers will range from roughly 10-50 blocks across instead of 5-25.

#### Adjust Cave Carving Thresholds

The carving thresholds determine how much of the cave layer is solid vs open. With the larger noise spread, adjust thresholds to maintain similar open-to-solid ratios but with larger individual openings:

- Intestinal Caves: threshold from 0.15 to 0.10 (slightly more open to compensate for larger-scale noise, keeps tight tunnel character but tunnels are wider)
- Tumor Caves: threshold stays at 0.0 (50% open, now with bigger chambers)
- Marrow Caves: threshold from -0.15 to -0.10 (still the most open, now with very large chambers)

#### Adjust Cave Detail Noise

The `cave_detail_noise` (spread 10) is used for wall material variation. Keep it at spread 10 — with the larger caves, the detail noise now provides fine texture on bigger walls rather than being the same scale as the cave openings themselves. This is the desired effect.

#### Cyst Formation Band

The cyst formation band in tumor caves (cave shape noise between threshold and threshold + 0.05) should narrow slightly to 0.03 to prevent cyst walls from being too thick at the larger scale. Change from `threshold + 0.05` to `threshold + 0.03`.

#### Liquid Pool Interaction

The bile and marrow pool noise bands (already reduced in Prompt 2) work with the cave shape noise. Since the spread changed, the noise behavior near thresholds changes too. The 0.005 band from Prompt 2 is relative to the threshold, so it scales correctly with the new spread — no additional adjustment needed.

---

## Prompt 4 of 4 — Adjust Red Fog Start Level

### File: `bio_mapgen.lua` (fog globalstep section)

The red fog currently activates for players anywhere in y=26927-30927. Change the lower boundary so the fog starts at the bottom of the organic cave layer, not at the frozen asteroid field.

#### Change Fog Y-Range

Change the fog activation check from `y >= 26927` to `y >= 27006` (the bottom of the organic caves, above the death space barrier).

Players in the frozen asteroid field (y=26927-26997) and death space barrier (y=26997-27006) will NOT have the red fog effect. These areas should feel like cold empty space, not fleshy interior. The death space already has its own opaque black post_effect_color when inside the blocks. The frozen asteroid field should have the default sky (dark void of space).

#### Frozen Asteroid Field Sky

Add a second sky condition: if the player is in the frozen asteroid field range (y >= 26927 and y < 26997), set a different sky:
```
player:set_sky({
    type = "plain",
    base_color = {r=2, g=2, b=5},  -- near-black deep space
    clouds = false,
})
player:set_sun({visible = false})
player:set_moon({visible = false})
player:set_stars({visible = false})
```

No fog override for this zone — just dark empty void with full visibility distance. If `set_fog` is available, set a very long fog distance (e.g., 500) with near-black color so it doesn't interfere with visibility but still renders correctly.

#### Death Space Zone

Players in the death space barrier (y >= 26997 and y < 27006) get no sky override — the death space node's `post_effect_color` (fully opaque black) already handles the visual effect of being inside those blocks.

#### Updated Priority Order

The globalstep should check zones in this order:
1. y >= 27006 and y <= 30927: Red fog (biological interior)
2. y >= 26927 and y < 26997: Deep space sky (frozen asteroid field)
3. y >= 26997 and y < 27006: No override (death space handles itself)
4. Outside all ranges: Restore default sky

The tracking table that prevents redundant API calls should now track which zone the player is in (not just a boolean), so transitions between zones correctly update the sky.

---

## Summary

| Prompt | Change | Performance Impact |
|--------|--------|-------------------|
| 1 | Only jelly, jelly_glow, and cyst_wall remain transparent — all others made opaque | Major rendering improvement from reduced alpha blending |
| 2 | Bile/marrow pools: tiny, single-level. Pus: 5th percentile only, flat. Jelly gaps filled with static. Verify red sea single-level. | Major liquid flow reduction across all layers |
| 3 | Cave noise spread 30→60 for bigger caves, adjusted thresholds | Bigger caves (gameplay improvement, no perf change) |
| 4 | Red fog starts at y=27006 (caves) not y=26927 (asteroids). Frozen asteroids get dark space sky. | Visual improvement, no perf change |
