# PROMPTS_005_UPDATE_041 — Major Node Consolidation (69 → 37)

SpecSwarm command: `/modify`

This is a massive node consolidation pass. 34 nodes are removed, 9 nodes are renamed with new textures, 2 new nodes are created, and 3 crafting recipes are added. The total custom node count drops from 69 to 37.

**IMPORTANT**: This update must be applied in order — renames and new nodes first (Prompts 1-2), then removals (Prompt 3), then liquid cleanup (Prompt 4), then verification (Prompt 5). Renames create the target nodes that removals reference.

---

## Prompt 1 of 5 — Rename 9 Nodes with New Textures

### Files: `bio_nodes.lua`, `bio_generate_textures.py`, all files referencing these nodes

Rename the following 9 nodes. For each: change the registered name, update the description, generate a new texture that matches the new identity, and update ALL references throughout the codebase (content ID variables, mapgen placement, biome files, schematics).

#### 1. `flesh_dark` → `rotten_flesh`
- **New description**: "Rotten Flesh"
- **New texture**: Sickly dark red-brown with grey-green discoloration patches. Base (80, 30, 25) with rot spots (50, 55, 35). Looks like decaying organic tissue.
- **Keeps**: Same hardness, groups, sounds

#### 2. `membrane` → `congealed_plasma`
- **New description**: "Congealed Plasma"
- **New texture**: Translucent pinkish-red with a glossy, coagulated look. Base (180, 80, 90) with darker clot streaks (140, 50, 60). Looks like solidified blood plasma.
- **Keeps**: Same transparency properties (if it had use_texture_alpha, keep it)

#### 3. `ceiling_membrane` → `congealed_rotten_plasma`
- **New description**: "Congealed Rotten Plasma"
- **New texture**: Dark murky red-brown with yellowish decay. Base (100, 45, 40) with yellow-green patches (90, 80, 35). Like old, degraded coagulated plasma.
- **Keeps**: Same hardness, groups

#### 4. `blood_clot` → `congealed_blood`
- **New description**: "Congealed Blood"
- **New texture**: Very dark crimson-red, dense and solid. Base (90, 15, 15) with darker near-black veins (40, 8, 8). Like a solid mass of clotted blood.
- **Keeps**: Same hardness, groups

#### 5. `nerve_fiber` → `fatty_nerve`
- **New description**: "Fatty Nerve"
- **New texture**: Pale cream-yellow with white fatty streaks. Base (200, 185, 140) with white-yellow streaks (230, 220, 180). Like nerve tissue wrapped in fatty myelin.
- **Keeps**: Same hardness, groups

#### 6. `node_of_ranvier` → `glowing_nerve`
- **New description**: "Glowing Nerve"
- **New texture**: Pale blue-white with bright bioluminescent glow. Base (160, 180, 220) with bright spots (200, 220, 255). Like electrically active nerve tissue.
- **Keeps**: Light source value, groups

#### 7. `follicle_sheath` → `fat_tissue`
- **New description**: "Fat Tissue"
- **New texture**: Pale yellow with soft lumpy appearance. Base (220, 200, 130) with lighter patches (240, 225, 160). Like adipose/fatty tissue.
- **Keeps**: Same hardness, groups

#### 8. `hair_strand` → `keratin`
- **New description**: "Keratin"
- **New texture**: Dark amber-brown, fibrous and hard. Base (80, 55, 30) with lighter grain lines (110, 80, 45). Like hardened keratin protein.
- **Keeps**: Climbable, plantlike drawtype, walkable=false

#### 9. `polyp` → `nerve_block`
- **New description**: "Nerve Block"
- **New texture**: Pale pink-grey, dense neural tissue. Base (180, 160, 165) with subtle darker veins (150, 130, 140). Like a solid mass of nerve tissue.
- **Keeps**: Same hardness, groups

#### Rename Procedure for Each

For each rename:
1. Change the node registration name in the appropriate `.lua` file
2. Update the `description` field
3. Generate the new texture in `bio_generate_textures.py` with the new filename
4. Find and replace ALL occurrences of the old name string throughout the entire codebase:
   - `lazarus_space:old_name` → `lazarus_space:new_name`
   - `c_old_name` → `c_new_name`
   - Variable names, comments, any string literal

---

## Prompt 2 of 5 — New Nodes and Crafting Recipes

### Files: `bio_nodes.lua`, `bio_generate_textures.py`

#### New Node: `lazarus_space:bone_block`

Register a new solid bone block. This will replace dentin, bone_pillar, and skeleton_skull (all consolidated into this one block).

- **Description**: "Bone Block"
- **Drawtype**: `normal` (solid cube, NOT a nodebox — replaces the pillar/skull nodeboxes with a simple solid block)
- **Texture**: Generate — polished bone surface, slightly yellowed. Base (235, 225, 195) with faint cracks (210, 200, 170). Like processed/carved bone. Name: `lazarus_space_bone_block.png`
- **Groups**: `cracky=2`
- **Sounds**: stone sounds

#### New Node: `lazarus_space:brain_coral_block`

Register a solid coral block. Replaces lung_coral.

- **Description**: "Brain Coral Block"
- **Drawtype**: `normal`
- **Texture**: Generate — dense coral pink-orange, compressed. Base (200, 130, 110) with fold patterns (180, 100, 85). Like brain coral pressed into a block. Name: `lazarus_space_brain_coral_block.png`
- **Groups**: `cracky=2, crumbly=1`
- **Sounds**: stone sounds

#### Crafting Recipes

Register 3 crafting recipes in `bio_nodes.lua` (or a dedicated crafting section):

```lua
-- Bone Block: 2 bone → 1 bone_block
minetest.register_craft({
    output = "lazarus_space:bone_block",
    recipe = {
        {"lazarus_space:bone", "lazarus_space:bone"},
    },
})

-- Bone Slab: 3 bone_block → 1 bone_slab
minetest.register_craft({
    output = "lazarus_space:bone_slab",
    recipe = {
        {"lazarus_space:bone_block", "lazarus_space:bone_block", "lazarus_space:bone_block"},
    },
})

-- Brain Coral Block: 3 brain_coral → 1 brain_coral_block
minetest.register_craft({
    output = "lazarus_space:brain_coral_block",
    recipe = {
        {"lazarus_space:brain_coral", "lazarus_space:brain_coral", "lazarus_space:brain_coral"},
    },
})
```

---

## Prompt 3 of 5 — Mass Node Removal (34 Nodes)

### Files: `bio_nodes.lua`, `bio_mapgen.lua`, `bio_schematics.lua`, `biomes/*.lua`, `bio_generate_textures.py`

Remove the following 34 nodes. For each removed node, replace ALL occurrences throughout the entire codebase with the specified replacement. This includes: node registrations, `minetest.get_content_id()` calls, content ID variables, mapgen placement, schematic definitions, biome generation code, texture generation.

### Master Removal Table

| # | Remove | Replace With | Notes |
|---|--------|-------------|-------|
| 1 | `flesh_wet` | `congealed_blood` | Was glossy tissue, now congealed blood |
| 2 | `muscle` | `flesh` | Merge into base flesh |
| 3 | `muscle_beam` | `default:cobblestone` | Outpost beams use default cobble |
| 4 | `spongy_bone` | `rotten_bone` | Porous bone → decayed bone |
| 5 | `dentin` | `bone_block` | Tooth interior → processed bone |
| 6 | `bone_pillar` | `bone_block` | Pillar nodebox → solid bone block |
| 7 | `skeleton_skull` | `bone_block` | Skull nodebox → solid bone block |
| 8 | `skeleton_rib` | `bone` | Rib decoration → plain bone |
| 9 | `jelly` | `congealed_plasma` | Translucent jelly → congealed plasma |
| 10 | `jelly_glow` | `congealed_plasma` | Glowing jelly → congealed plasma (light removed) |
| 11 | `cyst_wall` | `congealed_rotten_plasma` | Cyst wall → degraded plasma |
| 12 | `ceiling_vein` | `congealed_blood` | Ceiling vein → congealed blood |
| 13 | `asteroid_shell` | `default:stone` | Custom asteroid → default stone |
| 14 | `asteroid_glow` | `default:cobblestone` | Glowing asteroid → default cobblestone |
| 15 | `capillary_surface` | `congealed_blood` | Capillary surface → congealed blood |
| 16 | `nerve_channel` | `cartilage` | Nerve channel → cartilage |
| 17 | `nerve_root` | `fatty_nerve` | Nerve root → fatty nerve |
| 18 | `lung_coral` | `brain_coral_block` | Lung coral → brain coral block |
| 19 | `infected_tissue` | `rotten_flesh` | Infected tissue → rotten flesh |
| 20 | `necrotic_tissue` | `congealed_rotten_plasma` | Dead tissue → degraded plasma |
| 21 | `wbc_debris` | `rotten_bone` | WBC debris → rotten bone |
| 22 | `glow_infected` | `glowing_nerve` | Glowing infection → glowing nerve |
| 23 | `gristle` | `cartilage` | Gristle → cartilage |
| 24 | `pulp` | `congealed_plasma` | Tooth pulp → congealed plasma |
| 25 | `gum_tissue` | `flesh` | Gum tissue → flesh |
| 26 | `bacterial_mat` | `rotten_flesh` | Bacterial growth → rotten flesh |
| 27 | `sebum` | `congealed_rotten_plasma` | Oily ground → degraded plasma |
| 28 | `bio_sprout` | `bio_grass_3` | Fleshy sprout → medium grass |
| 29 | `plasma_static` | `plasma_source` | Non-flowing fill → use source |
| 30 | `bile_static` | `bile_source` | Non-flowing fill → use source |
| 31 | `marrow_static` | `marrow_source` | Non-flowing fill → use source |
| 32 | `ruin_wall` | `default:cobblestone` | Ruin wall → default cobblestone |
| 33 | `ruin_arch` | `default:dirt` | Ruin arch → default dirt |
| 34 | `marrow` (solid) | `cartilage` | Bouncy marrow → cartilage (remove bouncy) |

### Removal Procedure

For EACH of the 34 nodes above:

1. **Delete** the `minetest.register_node()` call from the appropriate `.lua` file
2. **Find and replace** every occurrence of `"lazarus_space:removed_name"` with `"lazarus_space:replacement_name"` (or `"default:xxx"` for default block replacements)
3. **Delete or update** the content ID variable (`c_removed_name`) — either remove it and replace with the replacement's content ID, or rename it to point to the replacement
4. **Delete** texture generation for the removed node from `bio_generate_textures.py`
5. **Check schematics** in `bio_schematics.lua` — replace removed nodes in all schematic definitions
6. **Check biome files** in `biomes/*.lua` — replace removed nodes in biome generation code

### Special Cases

- **jelly_glow → congealed_plasma**: The jelly_glow node had a light_source value. The replacement (congealed_plasma) does NOT glow. This intentionally removes light from the jelly membrane layer.
- **bone_pillar and skeleton_skull → bone_block**: These were nodeboxes (pillar shape, skull shape). The replacement bone_block is a normal solid cube. Schematics that used these decorative shapes will now use solid blocks — this is intentional (simplification).
- **marrow (solid) → cartilage**: The solid marrow block had `bouncy=1`. Cartilage does NOT have bouncy. The bounce mechanic is intentionally removed.
- **Static liquid variants → source**: Wherever `plasma_static`, `bile_static`, or `marrow_static` was placed by mapgen as a non-flowing fill, use the corresponding `_source` block instead. The source blocks will flow if adjacent to air, but this is acceptable.

---

## Prompt 4 of 5 — Liquid Variant Cleanup

### Files: `bio_nodes.lua`, `bio_mapgen.lua`

#### Keep Flowing Variants (Engine Required)

The following liquid flowing variants MUST remain registered — Minetest requires them for liquid source blocks to function:

- `lazarus_space:plasma_flowing` — keep as-is
- `lazarus_space:bile_flowing` — keep as-is
- `lazarus_space:marrow_flowing` — keep as-is

These are auto-generated by the engine when source blocks flow into air. They must exist as registered nodes even though mapgen never places them directly.

#### Rename Flowing Variants to Match Sources

Update the flowing variant registrations to ensure their internal references point to the correct source nodes (in case the liquid_alternative_source fields reference old names):

```lua
-- Each flowing node must reference its source
liquid_alternative_source = "lazarus_space:plasma_source",
liquid_alternative_flowing = "lazarus_space:plasma_flowing",
```

Verify this is correct for all 3 liquid types. If any flowing variant referenced a `_static` variant that no longer exists, remove that reference.

#### Verify Liquid Behavior

After removing the static variants, verify that:
- Plasma still fills the plasma ocean layer (y=27712-27775) using `plasma_source`
- Bile source blocks in caves still work normally
- Marrow source blocks in caves still work normally
- No Lua errors from missing node references

---

## Prompt 5 of 5 — Codebase-Wide Verification

### Files: ALL `.lua` files, `bio_generate_textures.py`

#### Search for Orphaned References

Search the ENTIRE codebase for ANY remaining string references to the 34 removed node names. Check for:

- `"lazarus_space:flesh_wet"`, `"lazarus_space:muscle"`, `"lazarus_space:muscle_beam"`, `"lazarus_space:spongy_bone"`, `"lazarus_space:dentin"`, `"lazarus_space:bone_pillar"`, `"lazarus_space:skeleton_skull"`, `"lazarus_space:skeleton_rib"`
- `"lazarus_space:jelly"`, `"lazarus_space:jelly_glow"`, `"lazarus_space:cyst_wall"`, `"lazarus_space:ceiling_vein"`
- `"lazarus_space:asteroid_shell"`, `"lazarus_space:asteroid_glow"`
- `"lazarus_space:capillary_surface"`, `"lazarus_space:nerve_channel"`, `"lazarus_space:nerve_root"`, `"lazarus_space:lung_coral"`
- `"lazarus_space:infected_tissue"`, `"lazarus_space:necrotic_tissue"`, `"lazarus_space:wbc_debris"`, `"lazarus_space:glow_infected"`
- `"lazarus_space:gristle"`, `"lazarus_space:pulp"`, `"lazarus_space:gum_tissue"`, `"lazarus_space:bacterial_mat"`
- `"lazarus_space:sebum"`, `"lazarus_space:bio_sprout"`
- `"lazarus_space:plasma_static"`, `"lazarus_space:bile_static"`, `"lazarus_space:marrow_static"`
- `"lazarus_space:ruin_wall"`, `"lazarus_space:ruin_arch"`, `"lazarus_space:marrow"` (the solid block, NOT marrow_source/flowing)

Also search for old names from the 9 renames:
- `"lazarus_space:flesh_dark"`, `"lazarus_space:membrane"`, `"lazarus_space:ceiling_membrane"`, `"lazarus_space:blood_clot"`, `"lazarus_space:nerve_fiber"`, `"lazarus_space:node_of_ranvier"`, `"lazarus_space:follicle_sheath"`, `"lazarus_space:hair_strand"`, `"lazarus_space:polyp"`

If ANY reference is found, replace it with the correct new name.

#### Search for Orphaned Content IDs

Search for content ID variable patterns: `c_flesh_wet`, `c_muscle`, `c_spongy_bone`, `c_dentin`, `c_bone_pillar`, `c_skeleton_skull`, `c_skeleton_rib`, `c_jelly`, `c_jelly_glow`, `c_cyst_wall`, `c_ceiling_vein`, `c_asteroid_shell`, `c_asteroid_glow`, etc.

Remove any that reference deleted nodes. Ensure no `minetest.get_content_id()` calls reference non-existent nodes (this would cause runtime errors).

#### Verify Texture Cleanup

In `bio_generate_textures.py`, verify that:
- All 34 removed node textures are no longer generated
- All 9 renamed node textures use the new filenames
- The 2 new node textures (bone_block, brain_coral_block) are generated
- No orphaned texture references remain

---

## Summary

| Prompt | Changes |
|--------|---------|
| 1 | 9 nodes renamed with new textures: flesh_dark→rotten_flesh, membrane→congealed_plasma, ceiling_membrane→congealed_rotten_plasma, blood_clot→congealed_blood, nerve_fiber→fatty_nerve, node_of_ranvier→glowing_nerve, follicle_sheath→fat_tissue, hair_strand→keratin, polyp→nerve_block |
| 2 | 2 new nodes (bone_block, brain_coral_block) + 3 crafting recipes (bone→bone_block, bone_block→bone_slab, brain_coral→brain_coral_block) |
| 3 | 34 nodes removed with full replacement mapping across entire codebase |
| 4 | Liquid flowing variants kept (engine-required), static variants removed, liquid references verified |
| 5 | Full codebase search for any orphaned references to removed/renamed nodes |

## Final Node List (37 nodes)

| # | Node Name | Type | Origin |
|---|-----------|------|--------|
| 1 | `flesh` | Structural | Original |
| 2 | `rotten_flesh` | Structural | Renamed from flesh_dark |
| 3 | `sinew` | Structural | Original |
| 4 | `bone` | Skeletal | Original |
| 5 | `enamel` | Skeletal | Original |
| 6 | `bone_block` | Skeletal | **NEW** |
| 7 | `rotten_bone` | Skeletal | Renamed (UPDATE_035) |
| 8 | `cartilage` | Skeletal | Original |
| 9 | `bone_slab` | Skeletal | Original |
| 10 | `congealed_plasma` | Barrier | Renamed from membrane |
| 11 | `congealed_rotten_plasma` | Barrier | Renamed from ceiling_membrane |
| 12 | `congealed_blood` | Barrier | Renamed from blood_clot |
| 13 | `vein_block` | Vascular | Original |
| 14 | `fatty_nerve` | Neural | Renamed from nerve_fiber |
| 15 | `glowing_nerve` | Neural | Renamed from node_of_ranvier |
| 16 | `brain_coral` | Coral | Original |
| 17 | `brain_coral_block` | Coral | **NEW** |
| 18 | `nerve_block` | Coral | Renamed from polyp |
| 19 | `fat_tissue` | Follicle Forest | Renamed from follicle_sheath |
| 20 | `keratin` | Follicle Forest | Renamed from hair_strand |
| 21 | `bio_tendril` | Plant | Original |
| 22 | `bio_polyp_plant` | Plant | Original |
| 23 | `bio_grass_1` | Plant | Original |
| 24 | `bio_grass_3` | Plant | Original |
| 25 | `bio_grass_tall` | Plant | Original |
| 26 | `cave_vine` | Plant | UPDATE_034 |
| 27 | `glowing_mushroom` | Mushroom | Original |
| 28 | `cave_shroom_small` | Mushroom | Original |
| 29 | `cave_shroom_bright` | Mushroom | Original |
| 30 | `flesh_mushroom_stem` | Mushroom | Original |
| 31 | `plasma_source` | Liquid | Renamed (UPDATE_033) |
| 32 | `plasma_flowing` | Liquid | Engine-required |
| 33 | `bile_source` | Liquid | Original |
| 34 | `bile_flowing` | Liquid | Engine-required |
| 35 | `marrow_source` | Liquid | Original |
| 36 | `marrow_flowing` | Liquid | Engine-required |
| 37 | `death_space` | Special | Original |

## Change Statistics

| Metric | Count |
|--------|-------|
| Nodes before | 69 |
| Removed | -34 |
| Added | +2 |
| **Nodes after** | **37** |
| Renamed | 9 |
| New crafting recipes | 3 |
| Default blocks now used | 3 (stone, cobblestone, dirt) |
