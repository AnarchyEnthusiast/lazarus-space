# PROMPTS_005_UPDATE_037 — Fog Fix (Engine Workaround), Vein Flats Outposts, Lower Cave Cap, Water and Stalactites

SpecSwarm command: `/modify`

This update fixes the persistent white fog using engine-compatible approaches, adds bone/muscle outpost structures to Vein Flats, adds a solid cap at the bottom of the lower organic caves, scatters water pools in the lower caves, and adds stalactites to the lower cave ceilings.

---

## Prompt 1 of 4 — Fix White Fog (Engine Workaround)

### Files: `bio_mapgen.lua`

The biological dimension fog has been white instead of dark red through three fix attempts (UPDATE_033, 034, 035). The code structure is correct — `set_fog()` is called after `set_sky()` with `fog_color = {r=60, g=10, b=10}` — but the fog remains white. This is almost certainly a Minetest/Luanti engine issue where `set_sky({type="skybox"})` overrides or ignores `set_fog()` fog color.

#### Fix Strategy: Multiple Approaches (Try in Order)

SpecSwarm must implement the **first approach that produces dark red fog**. Try them in order and use whichever one works:

##### Approach A: Embed Fog Tint in set_sky

Some Minetest/Luanti versions support fog tinting directly inside the `set_sky` call via `sky_color`:

```lua
player:set_sky({
    type = "skybox",
    textures = {
        "lazarus_space_sky_top.png",
        "lazarus_space_sky_bottom.png",
        "lazarus_space_sky_front.png",
        "lazarus_space_sky_back.png",
        "lazarus_space_sky_left.png",
        "lazarus_space_sky_right.png"
    },
    clouds = false,
    sky_color = {
        fog_tint_type = "custom",
        fog_sun_tint = {r = 60, g = 10, b = 10},
        fog_moon_tint = {r = 60, g = 10, b = 10},
    }
})
```

If the engine supports `fog_tint_type = "custom"`, this should tint the distance fog dark red. Still call `set_fog()` as well for the start/distance parameters.

##### Approach B: Abandon Skybox, Use Plain Sky

If Approach A doesn't work (fog is still white), abandon the skybox type entirely and switch to `type = "plain"`:

```lua
player:set_sky({
    type = "plain",
    base_color = {r = 30, g = 5, b = 5},
    clouds = false,
})

player:set_fog({
    fog_start = 0.0,
    fog_distance = 200,
    fog_color = {r = 60, g = 10, b = 10},
})
```

This loses the skybox textures but guarantees fog color control. The `base_color` creates a deep dark red sky background. Combined with `fog_color`, the entire atmosphere becomes oppressive dark red. The skybox textures were placeholder anyway — a solid dark red sky with matching fog creates the correct blood-red twilight atmosphere.

##### Approach C: Use Regular Sky with Custom Colors

If Approach B doesn't work either:

```lua
player:set_sky({
    type = "regular",
    sky_color = {
        day_sky = {r = 40, g = 8, b = 8},
        day_horizon = {r = 80, g = 15, b = 10},
        dawn_sky = {r = 40, g = 8, b = 8},
        dawn_horizon = {r = 80, g = 15, b = 10},
        night_sky = {r = 30, g = 5, b = 5},
        night_horizon = {r = 60, g = 10, b = 8},
        indoors = {r = 30, g = 5, b = 5},
        fog_tint_type = "custom",
        fog_sun_tint = {r = 60, g = 10, b = 10},
        fog_moon_tint = {r = 60, g = 10, b = 10},
    },
    clouds = false,
})
```

This uses the engine's built-in regular sky renderer with all color channels forced to dark red variants. The fog should inherit from the sky colors.

#### Implementation

Implement **Approach B** as the default (it's the most reliable). If the developer or user reports that Approach A works in their engine version, they can switch to it later to restore the skybox textures. Add a comment in the code explaining the three approaches and why Approach B was chosen:

```lua
-- FOG FIX: Using type="plain" because type="skybox" forces white fog
-- in some Minetest/Luanti versions, ignoring set_fog() color.
-- If your engine version supports skybox + fog_tint_type, switch to
-- type="skybox" with sky_color.fog_tint_type = "custom".
```

#### Keep All Other Sky Settings

Still disable sun, moon, stars, and clouds:
```lua
player:set_sun({visible = false})
player:set_moon({visible = false})
player:set_stars({visible = false})
player:set_clouds({density = 0})
```

Still clear fog when leaving the dimension:
```lua
player:set_sky({type = "regular"})
player:set_fog({})
```

---

## Prompt 2 of 4 — Vein Flats Outpost Structures

### Files: `bio_schematics.lua`, `bio_nodes.lua`, `biomes/vein_flats.lua`, `bio_generate_textures.py`

Add small outpost structures to the Vein Flats biome. These are primitive shelters and watchtowers built by past visitors using bone and muscle blocks — evidence of previous explorers or inhabitants who tried to survive in the biological dimension.

#### New Node: `lazarus_space:muscle_beam`

Register in `bio_nodes.lua`:
- **Description**: "Muscle Beam"
- **Drawtype**: `nodebox` — a horizontal/vertical beam shape: `{-0.25, -0.5, -0.25, 0.25, 0.5, 0.25}` (narrow pillar)
- **Tiles**: Use the existing `lazarus_space_muscle.png` texture
- **Paramtype2**: `facedir` (so beams can be rotated for horizontal placement)
- **Groups**: `cracky=2, choppy=2`
- **Sounds**: wood sounds (dried muscle feels woody)

No new texture needed — reuses the existing muscle texture.

#### Outpost Schematics (3 variants)

Define in `bio_schematics.lua`:

**`outpost_shelter`** — Size: 5×4×5. A simple roofed shelter:
- 4 corner posts of `bone` (3 blocks tall)
- Roof: single layer of `bone_slab` across the top
- One wall of `muscle` (3 blocks tall on one side, 80% probability per block for weathered gaps)
- Floor: `bone_slab` on ground level (60% probability per block)
- Interior: air
- Represents a basic lean-to or bivouac

**`outpost_watchtower`** — Size: 3×8×3. A tall narrow lookout:
- Central column of `bone_pillar` (6 blocks tall)
- Platform at top: 3×3 ring of `bone_slab` around the pillar top
- 2 `muscle_beam` cross-braces at half height (placed horizontally via facedir, 70% probability each)
- Scattered `bone` blocks at base (foundation, 50% probability)
- Represents a crude observation post

**`outpost_ruin`** — Size: 7×3×7. A collapsed larger structure:
- Perimeter outline of `bone_slab` on ground (the foundation, 70% probability per block)
- 2-3 partial walls of `muscle` rising 2 blocks (40% probability per block — heavily ruined)
- 1 intact corner post of `bone` (3 blocks tall, always present)
- Scattered `ruin_wall` debris inside the perimeter (30% probability)
- Interior has 1-2 `bone_slab` blocks as fallen roof pieces
- Represents a structure that was abandoned and collapsed long ago

All schematics use `force_placement = false` and generous probability values for varied weathering.

#### Placement in Vein Flats

Add outpost placement to `biomes/vein_flats.lua` or the schematic placement pass:

- **Rate**: 1 in 3500 qualifying surface positions
- **Surface requirement**: Place on flat terrain only — check that the y-coordinate of the surface is within ±1 of the two neighboring positions (avoid slopes)
- **Variant selection**: Equal probability for all 3 types (shelter, watchtower, ruin)
- Use the improved hash function with a unique seed

The outposts should feel rare and lonely — scattered evidence of previous habitation on the flat vein terrain.

---

## Prompt 3 of 4 — Lower Cave Bottom Cap

### Files: `bio_mapgen.lua`

Currently the organic caves (y=27006-27697) sit directly on the death space barrier (y=26997-27006) with no organic transition. Add a solid organic cap at the bottom of the lower caves, similar in concept to the upper cave cap but adapted for the bottom.

#### Cap Position and Thickness

- **Cap range**: y=27006 to y=27026 (20 blocks thick)
- **This replaces the lowest 20 blocks of the organic cave zone** — the cave interior now effectively starts at y=27026 instead of y=27006. Cave carving should NOT carve into this cap zone.

#### Bottom Surface (y=27006, sits on death space)

The bottom of the cap is flat at y=27006 — it rests directly on the death space barrier. No waviness needed on the bottom (it's not visible; death space is opaque black below).

#### Top Surface (Cave Floor, Wavy)

Apply 2D Perlin noise displacement to the top surface:
- **Noise**: spread 35-50, octaves 2, persistence 0.5
- **Amplitude**: ±6 blocks of vertical displacement from y=27026
- **Material**: `flesh` for the top face (cave floor surface)
- The top surface undulates between approximately y=27020 and y=27032

This creates a wavy organic cave floor that players walk on, rather than an abrupt flat boundary.

#### Interior Fill

Everything between y=27006 and the displaced top surface is solid:
- Bottom 40% of thickness: `bone` (structural base resting on death space)
- Middle 30%: `spongy_bone` (transitional)
- Top 30%: `flesh` (blending into cave floor surface)

#### Integration with Cave Carving

Modify the organic cave generation to respect this cap:
- Cave carving (cave_shape_noise) should NOT carve any blocks below y=27026 + displacement amplitude (effectively below y=27020 at the lowest)
- If the current cave carving extends all the way down to y=27006, add a check: `if y < 27020 then skip carving`
- This prevents caves from punching through the cap into death space

The visual effect: cave explorers at the bottom of the deepest caves find a solid, undulating bone-and-flesh floor. They cannot dig through it to reach death space (it's too thick and the bone layer is hard). The floor feels like the "bottom of the organism."

---

## Prompt 4 of 4 — Water Pools and Stalactites in Lower Caves

### Files: `bio_mapgen.lua`

Add two features to the lower organic caves (y=27006-27697): scattered water pools on the cave floor and stalactites hanging from the cave ceiling.

#### Water Pools

Place `default:water_source` in small pools on the lower cave floors. These represent groundwater that has seeped into the biological structure — clean water among the organic terrain.

**Placement**:
- Only in the bottom third of the cave zone (y=27026 to y=27256, approximately)
- At cave floor positions (solid block below, air at the placement position)
- Rate: 1 in 200 qualifying floor positions
- When placing water, also check 1 block below the placement position — if it's air (a deeper cave pocket), skip placement to avoid waterfalls cascading into lower chambers

**Pool formation**: When a water source is placed, also fill the 4 horizontal neighbors (x±1, z±1) with `default:water_source` IF those positions are also air-above-solid-floor. This creates small 3-5 block puddles rather than single-block water dots. Cap at 5 connected water source blocks per pool to prevent large floods.

**Per-chunk limit**: Maximum 3 water pools per chunk to prevent excessive water generation and flow lag.

#### Small Stalactites from Cave Ceiling

Add small stalactites hanging from the organic cave ceiling throughout all three lower cave biomes. These are smaller than the giant stalactites in the upper dimension — short organic protrusions.

**Stalactite node**: Use existing `bone` blocks to form small stalactite shapes. No new nodes needed.

**Placement via mapgen** (not schematics — generate procedurally):
- At cave ceiling positions (air block with solid non-liquid block directly above)
- Rate: 1 in 40 qualifying ceiling positions
- Use the improved hash function with a unique seed

**Shape**: Each stalactite is a simple vertical column of `bone` blocks hanging down from the ceiling:
- **Length**: 1-4 blocks (determined by hash: 50% chance of 1 block, 25% chance of 2, 15% chance of 3, 10% chance of 4)
- Place `bone` blocks downward from the ceiling position for the determined length
- Only place blocks into air — if a non-air block is encountered while building downward, stop

**Density variation**: In the marrow/spongy_bone cave biome (the one that was smoothed in UPDATE_033), increase the stalactite rate to 1 in 25 ceiling positions. This biome should feel like it has more skeletal protrusions.

These stalactites are small decorative features — nothing like the massive 60-200 block stalactites in the upper dimension. They're short bone fingers poking down from the cave ceiling, adding visual detail and variety.

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | Fix white fog by switching from `type="skybox"` to `type="plain"` with `base_color={r=30, g=5, b=5}` — skybox type forces white fog in the engine. Fog color set to `{r=60, g=10, b=10}`. Comment documents all 3 approach options for future engine versions. |
| 2 | New `muscle_beam` node + 3 outpost schematics (shelter, watchtower, ruin) placed in Vein Flats at 1/3500 rate. Bone/muscle construction representing past visitors. |
| 3 | 20-block solid cap at bottom of lower caves (y=27006-27026), wavy top surface ±6, bone base / spongy_bone middle / flesh top. Cave carving blocked below y=27020. |
| 4 | Small water pools (default:water_source, 3-5 blocks, bottom third of caves, 3 per chunk max) + small bone stalactites from ceiling (1-4 blocks long, 1/40 rate, 1/25 in marrow caves) |

## Nodes Added (1)

| New Node | Type | Purpose |
|----------|------|---------|
| `muscle_beam` | Nodebox pillar, facedir | Structural beam for outpost schematics |

## Updated Lower Cave Boundaries

| Layer | Y Range | Height | Notes |
|-------|---------|--------|-------|
| Death Space Barrier | 26997–27006 | 9 | Unchanged — absolute floor |
| **Lower Cave Bottom Cap** | **27006–27026** | **20 (NEW)** | Solid cap, wavy top ±6, bone/spongy_bone/flesh |
| **Organic Cave Interior** | **27026–27697** | **671** | Was 691, shortened by cap. Water pools in bottom third. Stalactites from ceiling. |
| Jelly/Plasma Membrane | 27697–27712 | 15 | Unchanged |
