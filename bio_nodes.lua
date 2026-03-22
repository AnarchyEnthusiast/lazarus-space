-- Biological Dimension: Shared Node Registrations
-- All nodes shared across multiple biomes or layers.
-- Biome-specific nodes are registered in their own files under biomes/.

-- =============================================================================
-- Structural Blocks
-- =============================================================================

minetest.register_node("lazarus_space:flesh", {
	description = "Flesh",
	tiles = {"lazarus_space_flesh.png"},
	groups = {crumbly = 2, choppy = 2},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("lazarus_space:rotten_flesh", {
	description = "Rotten Flesh",
	tiles = {"lazarus_space_rotten_flesh.png"},
	groups = {crumbly = 2, choppy = 2},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("lazarus_space:sinew", {
	description = "Sinew",
	tiles = {"lazarus_space_sinew.png"},
	groups = {choppy = 2, snappy = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("lazarus_space:bone", {
	description = "Bone",
	tiles = {"lazarus_space_bone.png"},
	groups = {cracky = 1, level = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:enamel", {
	description = "Enamel",
	tiles = {"lazarus_space_enamel.png"},
	groups = {cracky = 1, level = 3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:bone_block", {
	description = "Bone Block",
	tiles = {"lazarus_space_bone_block.png"},
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:rotten_bone", {
	description = "Rotten Bone",
	tiles = {"lazarus_space_rotten_bone.png"},
	groups = {crumbly = 2, bouncy = 1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("lazarus_space:cartilage", {
	description = "Cartilage",
	tiles = {"lazarus_space_cartilage.png"},
	groups = {cracky = 2, choppy = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:bone_slab", {
	description = "Bone Slab",
	tiles = {"lazarus_space_bone.png"},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0.0, 0.5},
	},
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
})

-- =============================================================================
-- Barrier / Congealed Blocks
-- =============================================================================

minetest.register_node("lazarus_space:congealed_plasma", {
	description = "Congealed Plasma",
	tiles = {"lazarus_space_congealed_plasma.png"},
	groups = {cracky = 3, oddly_breakable_by_hand = 2},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("lazarus_space:congealed_rotten_plasma", {
	description = "Congealed Rotten Plasma",
	tiles = {"lazarus_space_congealed_rotten_plasma.png"},
	groups = {cracky = 2, crumbly = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:congealed_blood", {
	description = "Congealed Blood",
	tiles = {"lazarus_space_congealed_blood.png"},
	groups = {crumbly = 1, choppy = 2},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("lazarus_space:death_space", {
	description = "Death Space",
	tiles = {"lazarus_space_death_space.png"},
	walkable = false,
	pointable = false,
	diggable = false,
	damage_per_second = 20,
	post_effect_color = {a = 255, r = 0, g = 0, b = 0},
	drowning = 1,
	groups = {},
	on_blast = function() end,
})

-- =============================================================================
-- Vascular / Neural / Coral
-- =============================================================================

minetest.register_node("lazarus_space:vein_block", {
	description = "Vein Block",
	tiles = {"lazarus_space_vein_block.png"},
	groups = {cracky = 2, choppy = 2},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("lazarus_space:brain_coral", {
	description = "Brain Coral",
	tiles = {"lazarus_space_brain_coral.png"},
	groups = {cracky = 2, crumbly = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:brain_coral_block", {
	description = "Brain Coral Block",
	tiles = {"lazarus_space_brain_coral_block.png"},
	groups = {cracky = 2, crumbly = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:nerve_block", {
	description = "Nerve Block",
	tiles = {"lazarus_space_nerve_block.png"},
	groups = {cracky = 3, crumbly = 2},
	sounds = default.node_sound_stone_defaults(),
})

-- =============================================================================
-- Fat / Follicle Forest
-- =============================================================================

minetest.register_node("lazarus_space:fat_tissue", {
	description = "Fat Tissue",
	tiles = {"lazarus_space_fat_tissue.png"},
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:keratin", {
	description = "Keratin",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.1, -0.5, -0.1, 0.1, 0.5, 0.1},
	},
	tiles = {"lazarus_space_keratin.png"},
	paramtype = "light",
	walkable = false,
	climbable = true,
	groups = {snappy = 3, choppy = 3},
	sounds = default.node_sound_leaves_defaults(),
})

-- =============================================================================
-- Decorative / Shared
-- =============================================================================

minetest.register_node("lazarus_space:glowing_mushroom", {
	description = "Glowing Mushroom",
	drawtype = "plantlike",
	tiles = {"lazarus_space_glowing_mushroom.png"},
	paramtype = "light",
	light_source = 8,
	walkable = false,
	groups = {snappy = 3, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:flesh_mushroom_stem", {
	description = "Flesh Mushroom Stem",
	tiles = {"lazarus_space_flesh_mushroom_stem.png"},
	groups = {choppy = 2, crumbly = 2},
	sounds = default.node_sound_wood_defaults(),
})

-- =============================================================================
-- Surface Plants
-- =============================================================================

minetest.register_node("lazarus_space:bio_tendril", {
	description = "Bio Tendril",
	drawtype = "plantlike",
	tiles = {"lazarus_space_bio_tendril.png"},
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 4,
	walkable = false,
	groups = {snappy = 3, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:bio_polyp_plant", {
	description = "Bio Polyp Plant",
	drawtype = "plantlike",
	tiles = {"lazarus_space_bio_polyp_plant.png"},
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 2,
	walkable = false,
	groups = {snappy = 3, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:bio_grass_1", {
	description = "Short Bio Grass",
	drawtype = "plantlike",
	tiles = {"lazarus_space_bio_grass_1.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, attached_node = 1, flora = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:bio_grass_3", {
	description = "Tall Bio Grass",
	drawtype = "plantlike",
	tiles = {"lazarus_space_bio_grass_3.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, attached_node = 1, flora = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:bio_grass_tall", {
	description = "Very Tall Bio Grass",
	drawtype = "plantlike",
	tiles = {"lazarus_space_bio_grass_tall.png"},
	paramtype = "light",
	sunlight_propagates = true,
	visual_scale = 2.0,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 1.0, 0.3},
	},
	groups = {snappy = 3, attached_node = 1, flora = 1},
	sounds = default.node_sound_leaves_defaults(),
})

-- =============================================================================
-- Cave Mushrooms and Vines
-- =============================================================================

minetest.register_node("lazarus_space:cave_shroom_small", {
	description = "Small Cave Mushroom",
	drawtype = "plantlike",
	tiles = {"lazarus_space_cave_shroom_small.png"},
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 4,
	walkable = false,
	groups = {snappy = 3, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:cave_shroom_bright", {
	description = "Bright Bioluminescent Mushroom",
	drawtype = "plantlike",
	tiles = {"lazarus_space_cave_shroom_bright.png"},
	paramtype = "light",
	sunlight_propagates = true,
	light_source = 8,
	walkable = false,
	groups = {snappy = 3, attached_node = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("lazarus_space:cave_vine", {
	description = "Cave Vine",
	drawtype = "plantlike",
	tiles = {"lazarus_space_cave_vine.png"},
	paramtype = "light",
	paramtype2 = "wallmounted",
	light_source = 2,
	walkable = false,
	climbable = true,
	selection_box = {
		type = "fixed",
		fixed = {-0.15, -0.5, -0.15, 0.15, 0.5, 0.15},
	},
	groups = {snappy = 3, flora = 1},
	sounds = default.node_sound_leaves_defaults(),
	drop = "lazarus_space:cave_vine",
})

-- =============================================================================
-- Cave-specific Shared Nodes
-- =============================================================================

minetest.register_node("lazarus_space:mucus", {
	description = "Mucus",
	tiles = {"lazarus_space_mucus.png"},
	groups = {crumbly = 3, slippery = 3},
	sounds = default.node_sound_dirt_defaults(),
})

-- =============================================================================
-- Custom Liquids
-- =============================================================================

-- Plasma Liquid
minetest.register_node("lazarus_space:plasma_source", {
	description = "Plasma Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "lazarus_space_plasma_source_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	special_tiles = {
		{
			name = "lazarus_space_plasma_source_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "lazarus_space:plasma_flowing",
	liquid_alternative_source = "lazarus_space:plasma_source",
	liquid_viscosity = 4,
	liquid_range = 8,
	post_effect_color = {a = 245, r = 60, g = 0, b = 0},
	groups = {liquid = 3, water = 3},
})

minetest.register_node("lazarus_space:plasma_flowing", {
	description = "Flowing Plasma",
	drawtype = "flowingliquid",
	tiles = {"lazarus_space_plasma_flowing_animated.png"},
	special_tiles = {
		{
			name = "lazarus_space_plasma_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
		{
			name = "lazarus_space_plasma_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "lazarus_space:plasma_flowing",
	liquid_alternative_source = "lazarus_space:plasma_source",
	liquid_viscosity = 4,
	liquid_range = 8,
	post_effect_color = {a = 245, r = 60, g = 0, b = 0},
	groups = {liquid = 3, water = 3, not_in_creative_inventory = 1},
})

-- Bile Liquid
minetest.register_node("lazarus_space:bile_source", {
	description = "Bile Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "lazarus_space_bile_source_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	special_tiles = {
		{
			name = "lazarus_space_bile_source_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 2,
	liquidtype = "source",
	liquid_alternative_flowing = "lazarus_space:bile_flowing",
	liquid_alternative_source = "lazarus_space:bile_source",
	liquid_viscosity = 4,
	liquid_range = 4,
	post_effect_color = {a = 255, r = 120, g = 130, b = 10},
	groups = {liquid = 3},
})

minetest.register_node("lazarus_space:bile_flowing", {
	description = "Flowing Bile",
	drawtype = "flowingliquid",
	tiles = {"lazarus_space_bile_flowing_animated.png"},
	special_tiles = {
		{
			name = "lazarus_space_bile_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
		{
			name = "lazarus_space_bile_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 2,
	liquidtype = "flowing",
	liquid_alternative_flowing = "lazarus_space:bile_flowing",
	liquid_alternative_source = "lazarus_space:bile_source",
	liquid_viscosity = 4,
	liquid_range = 4,
	post_effect_color = {a = 255, r = 120, g = 130, b = 10},
	groups = {liquid = 3, not_in_creative_inventory = 1},
})

-- Pus Liquid
minetest.register_node("lazarus_space:pus_source", {
	description = "Pus Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "lazarus_space_pus_source_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	special_tiles = {
		{
			name = "lazarus_space_pus_source_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 3,
	liquidtype = "source",
	liquid_alternative_flowing = "lazarus_space:pus_flowing",
	liquid_alternative_source = "lazarus_space:pus_source",
	liquid_viscosity = 7,
	liquid_range = 2,
	post_effect_color = {a = 230, r = 180, g = 170, b = 50},
	groups = {liquid = 3},
})

minetest.register_node("lazarus_space:pus_flowing", {
	description = "Flowing Pus",
	drawtype = "flowingliquid",
	tiles = {"lazarus_space_pus_flowing_animated.png"},
	special_tiles = {
		{
			name = "lazarus_space_pus_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
		{
			name = "lazarus_space_pus_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 3,
	liquidtype = "flowing",
	liquid_alternative_flowing = "lazarus_space:pus_flowing",
	liquid_alternative_source = "lazarus_space:pus_source",
	liquid_viscosity = 7,
	liquid_range = 2,
	post_effect_color = {a = 230, r = 180, g = 170, b = 50},
	groups = {liquid = 3, not_in_creative_inventory = 1},
})

-- Marrow Liquid
minetest.register_node("lazarus_space:marrow_source", {
	description = "Marrow Liquid Source",
	drawtype = "liquid",
	tiles = {
		{
			name = "lazarus_space_marrow_source_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	special_tiles = {
		{
			name = "lazarus_space_marrow_source_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "lazarus_space:marrow_flowing",
	liquid_alternative_source = "lazarus_space:marrow_source",
	liquid_viscosity = 6,
	liquid_range = 3,
	post_effect_color = {a = 255, r = 160, g = 100, b = 30},
	groups = {liquid = 3},
})

minetest.register_node("lazarus_space:marrow_flowing", {
	description = "Flowing Marrow Liquid",
	drawtype = "flowingliquid",
	tiles = {"lazarus_space_marrow_flowing_animated.png"},
	special_tiles = {
		{
			name = "lazarus_space_marrow_flowing_animated.png",
			backface_culling = false,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
		{
			name = "lazarus_space_marrow_flowing_animated.png",
			backface_culling = true,
			animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0},
		},
	},
	use_texture_alpha = "blend",
	paramtype = "light",
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "lazarus_space:marrow_flowing",
	liquid_alternative_source = "lazarus_space:marrow_source",
	liquid_viscosity = 6,
	liquid_range = 3,
	post_effect_color = {a = 255, r = 160, g = 100, b = 30},
	groups = {liquid = 3, not_in_creative_inventory = 1},
})

-- =============================================================================
-- Crafting Recipes
-- =============================================================================

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

-- =============================================================================
-- Tungsten Ore, Lump, Ingot, and Block
-- =============================================================================

minetest.register_node("lazarus_space:tungsten_ore", {
	description = "Tungsten Ore",
	tiles = {"lazarus_space_tungsten_ore.png"},
	groups = {cracky = 2},
	drop = "lazarus_space:tungsten_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("lazarus_space:tungsten_block", {
	description = "Tungsten Block",
	tiles = {"lazarus_space_tungsten_block.png"},
	groups = {cracky = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_craftitem("lazarus_space:tungsten_lump", {
	description = "Tungsten Lump",
	inventory_image = "lazarus_space_tungsten_lump.png",
})

minetest.register_craftitem("lazarus_space:tungsten_ingot", {
	description = "Tungsten Ingot",
	inventory_image = "lazarus_space_tungsten_ingot.png",
})

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

-- =============================================================================
-- Cave Vine Growth ABM
-- =============================================================================

minetest.register_abm({
	label = "Cave vine growth",
	nodenames = {"lazarus_space:cave_vine"},
	interval = 30,
	chance = 8,
	action = function(pos, node)
		local below = {x = pos.x, y = pos.y - 1, z = pos.z}
		local below_node = minetest.get_node(below)

		-- Only grow into air
		if below_node.name ~= "air" then
			return
		end

		-- Count vine length above (don't grow forever)
		local max_length = 4 + math.floor(math.random() * 5)  -- 4-8 blocks max
		local check_pos = {x = pos.x, y = pos.y, z = pos.z}
		local length = 0
		while true do
			local n = minetest.get_node(check_pos)
			if n.name == "lazarus_space:cave_vine" then
				length = length + 1
				check_pos.y = check_pos.y + 1
			else
				break
			end
			if length > 10 then break end
		end

		if length >= max_length then
			return
		end

		-- Place new vine segment below
		minetest.set_node(below, {name = "lazarus_space:cave_vine", param2 = 0})
	end,
})
