-- Lazarus Space: Dimensional Crafting Station (6×6 Grid)
-- 36-slot crafting grid for advanced recipes.

-- ============================================================
-- REGISTERED 6×6 RECIPES
-- ============================================================

local recipes_6x6 = {}

lazarus_space.register_6x6_craft = function(def)
	recipes_6x6[#recipes_6x6 + 1] = {
		output = def.output,
		recipe = def.recipe,  -- flat table of 36 strings (6 rows × 6 cols)
	}
end

-- ============================================================
-- RECIPE MATCHING
-- ============================================================

local function item_matches(pattern, item_name)
	if pattern == "" then
		return item_name == ""
	end
	if pattern:sub(1, 6) == "group:" then
		local group = pattern:sub(7)
		local def = minetest.registered_items[item_name]
		if def and def.groups and def.groups[group] and def.groups[group] > 0 then
			return true
		end
		return false
	end
	return pattern == item_name
end

lazarus_space.find_6x6_craft = function(grid)
	for _, recipe in ipairs(recipes_6x6) do
		local match = true
		for i = 1, 36 do
			if not item_matches(recipe.recipe[i] or "", grid[i]) then
				match = false
				break
			end
		end
		if match then
			return recipe.output
		end
	end
	return nil
end

-- ============================================================
-- CRAFTING OUTPUT UPDATE
-- ============================================================

local function build_crafting_formspec(pos)  -- forward declaration
end

local function update_craft(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local grid = {}
	for i = 1, 36 do
		local stack = inv:get_stack("craft", i)
		grid[i] = stack:get_name()
	end

	local result = lazarus_space.find_6x6_craft(grid)
	if result then
		inv:set_stack("output", 1, result)
	else
		inv:set_stack("output", 1, "")
	end

	-- Refresh formspec for all nearby players viewing it
	local fs = build_crafting_formspec(pos)
	local formname = "lazarus_space:crafting6x6_" .. minetest.pos_to_string(pos)
	local players = minetest.get_connected_players()
	for _, p in ipairs(players) do
		if vector.distance(p:get_pos(), pos) < 8 then
			minetest.show_formspec(p:get_player_name(), formname, fs)
		end
	end
end

-- ============================================================
-- FORMSPEC BUILDER
-- ============================================================

build_crafting_formspec = function(pos)
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z

	local fs = "formspec_version[4]"
		.. "size[14.4,13.6]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Title bar
	fs = fs .. "box[0,0;14.4,0.8;#1a1a2e]"
		.. "label[4.2,0.16;" .. minetest.colorize("#00ccaa",
		"Dimensional Crafting Station") .. "]"

	-- Background panel for crafting area
	fs = fs .. "box[0.3,1.2;8.4,8.0;#0a0a12]"

	-- 6×6 crafting grid
	local grid_x = 0.6
	local grid_y = 1.5
	fs = fs .. "list[nodemeta:" .. pos_str .. ";craft;"
		.. grid_x .. "," .. grid_y .. ";6,6;]"

	-- Arrow
	fs = fs .. "image[9.2,4.4;1.2,1.2;gui_furnace_arrow_bg.png^[transformR270]"

	-- Output slot
	fs = fs .. "list[nodemeta:" .. pos_str .. ";output;10.8,4.4;1,1;]"

	-- Player inventory
	fs = fs .. "list[current_player;main;0.6,9.8;8,1;]"
		.. "list[current_player;main;0.6,11.05;8,3;8]"

	-- Shift-click targets
	fs = fs .. "listring[nodemeta:" .. pos_str .. ";craft]"
		.. "listring[current_player;main]"
		.. "listring[nodemeta:" .. pos_str .. ";output]"
		.. "listring[current_player;main]"

	return fs
end

-- ============================================================
-- NODE REGISTRATION
-- ============================================================

minetest.register_node("lazarus_space:crafting_station_3d", {
	description = "Dimensional Crafting Station",
	tiles = {"lazarus_space_crafting_station_3d.png"},
	groups = {cracky = 2},
	sounds = default.node_sound_metal_defaults(),
	paramtype2 = "facedir",

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("craft", 36)
		inv:set_size("output", 1)
		meta:set_string("formspec", "")
		meta:set_string("infotext", "Dimensional Crafting Station")
	end,

	on_rightclick = function(pos, node, clicker)
		if not clicker:is_player() then return end
		local fs = build_crafting_formspec(pos)
		minetest.show_formspec(clicker:get_player_name(),
			"lazarus_space:crafting6x6_" .. minetest.pos_to_string(pos), fs)
	end,

	on_metadata_inventory_move = function(pos) update_craft(pos) end,
	on_metadata_inventory_put = function(pos) update_craft(pos) end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "output" then
			local inv = minetest.get_meta(pos):get_inventory()
			for i = 1, 36 do
				local s = inv:get_stack("craft", i)
				if not s:is_empty() then
					s:take_item(1)
					inv:set_stack("craft", i, s)
				end
			end
		end
		update_craft(pos)
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "output" then return 0 end
		return stack:get_count()
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if to_list == "output" then return 0 end
		return count
	end,
})

-- ============================================================
-- CRAFTING RECIPE FOR THE STATION
-- ============================================================

minetest.register_craft({
	output = "lazarus_space:crafting_station_3d",
	recipe = {
		{"default:steelblock", "lazarus_space:pole_field", "default:steelblock"},
		{"lazarus_space:pole_field", "default:diamondblock", "lazarus_space:pole_field"},
		{"default:steelblock", "lazarus_space:pole_field", "default:steelblock"},
	},
})

-- ============================================================
-- 6×6 CRAFTING RECIPES
-- ============================================================

-- Diamond cross: 2×2 diamonds in center → diamond block
lazarus_space.register_6x6_craft({
	output = "default:diamondblock",
	recipe = {
		-- Row 1
		"", "", "", "", "", "",
		-- Row 2
		"", "", "", "", "", "",
		-- Row 3
		"", "", "default:diamond", "default:diamond", "", "",
		-- Row 4
		"", "", "default:diamond", "default:diamond", "", "",
		-- Row 5
		"", "", "", "", "", "",
		-- Row 6
		"", "", "", "", "", "",
	},
})

-- Steel frame: steel ingots forming outer ring of 4×4 area → 2 steel blocks
lazarus_space.register_6x6_craft({
	output = "default:steelblock 2",
	recipe = {
		-- Row 1
		"", "", "", "", "", "",
		-- Row 2
		"", "default:steel_ingot", "default:steel_ingot", "default:steel_ingot", "default:steel_ingot", "",
		-- Row 3
		"", "default:steel_ingot", "",                    "",                    "default:steel_ingot", "",
		-- Row 4
		"", "default:steel_ingot", "",                    "",                    "default:steel_ingot", "",
		-- Row 5
		"", "default:steel_ingot", "default:steel_ingot", "default:steel_ingot", "default:steel_ingot", "",
		-- Row 6
		"", "", "", "", "", "",
	},
})

-- Pole field assembly: corrector in center with steel plus pattern → 4 pole field
lazarus_space.register_6x6_craft({
	output = "lazarus_space:pole_field 4",
	recipe = {
		-- Row 1
		"", "", "", "", "", "",
		-- Row 2
		"", "", "", "default:steelblock", "", "",
		-- Row 3
		"", "", "default:steelblock", "lazarus_space:pole_corrector", "default:steelblock", "",
		-- Row 4
		"", "", "", "default:steelblock", "", "",
		-- Row 5
		"", "", "", "", "", "",
		-- Row 6
		"", "", "", "", "", "",
	},
})
