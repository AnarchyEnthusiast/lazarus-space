-- Lazarus Space: Advanced Crafting Machine (6×6 Grid)
-- 36-slot crafting grid for advanced recipes.
-- Also functions as a normal 3×3 crafting table.
-- 6×6 recipes require 10,000 EU from HV network.

local CRAFT_COST = 10000

-- Track which players have the formspec open, keyed by player_name
local open_formspecs = {}  -- [player_name] = pos_string

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
-- NORMAL 3×3 CRAFTING FALLBACK
-- ============================================================

local function try_normal_craft(inv)
	-- Find bounding box of non-empty slots in the 6×6 grid
	local min_row, max_row, min_col, max_col = 7, 0, 7, 0
	for row = 1, 6 do
		for col = 1, 6 do
			local idx = (row - 1) * 6 + col
			local stack = inv:get_stack("craft", idx)
			if not stack:is_empty() then
				min_row = math.min(min_row, row)
				max_row = math.max(max_row, row)
				min_col = math.min(min_col, col)
				max_col = math.max(max_col, col)
			end
		end
	end

	-- Nothing in grid
	if min_row > max_row then return nil end

	local width = max_col - min_col + 1
	local height = max_row - min_row + 1

	-- Must fit in 3×3
	if width > 3 or height > 3 then return nil end

	-- Extract sub-grid as ItemStack list
	local items = {}
	for row = min_row, min_row + height - 1 do
		for col = min_col, min_col + width - 1 do
			local idx = (row - 1) * 6 + col
			items[#items + 1] = inv:get_stack("craft", idx)
		end
	end

	local result, decremented = minetest.get_craft_result({
		method = "normal",
		width = width,
		items = items,
	})

	if result and result.item and not result.item:is_empty() then
		return result.item:to_string(), decremented, min_row, min_col, width, height
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

	-- Build flat grid for 6×6 recipe check
	local grid = {}
	for i = 1, 36 do
		local stack = inv:get_stack("craft", i)
		grid[i] = stack:get_name()
	end

	-- Try 6×6 custom recipes first (requires EU)
	local result = lazarus_space.find_6x6_craft(grid)
	if result then
		local stored = meta:get_int("stored_energy")
		if stored >= CRAFT_COST then
			inv:set_stack("output", 1, result)
			meta:set_string("craft_type", "6x6")
		else
			inv:set_stack("output", 1, "")
			meta:set_string("craft_type", "")
		end
	else
		-- Try normal 3×3 crafting (no EU needed)
		local normal_result = try_normal_craft(inv)
		if normal_result then
			inv:set_stack("output", 1, normal_result)
			meta:set_string("craft_type", "normal")
		else
			inv:set_stack("output", 1, "")
			meta:set_string("craft_type", "")
		end
	end

	-- Refresh formspec ONLY for players who have it open
	local pos_str = minetest.pos_to_string(pos)
	local fs = build_crafting_formspec(pos)
	local formname = "lazarus_space:crafting6x6_" .. pos_str
	for pname, open_pos in pairs(open_formspecs) do
		if open_pos == pos_str then
			local player = minetest.get_player_by_name(pname)
			if player then
				minetest.show_formspec(pname, formname, fs)
			end
		end
	end
end

-- ============================================================
-- FORMSPEC BUILDER
-- ============================================================

build_crafting_formspec = function(pos)
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
	local meta = minetest.get_meta(pos)
	local stored = meta:get_int("stored_energy")

	local fs = "formspec_version[4]"
		.. "size[14.4,15.6]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Title bar
	fs = fs .. "box[0,0;14.4,0.8;#1a1a2e]"
		.. "label[4.0,0.16;" .. minetest.colorize("#00ccaa",
		"Advanced Crafting Machine") .. "]"

	-- Background panel for crafting area
	fs = fs .. "box[0.3,1.1;8.4,8.2;#0a0a12]"

	-- 6×6 crafting grid
	local grid_x = 0.6
	local grid_y = 1.4
	fs = fs .. "list[nodemeta:" .. pos_str .. ";craft;"
		.. grid_x .. "," .. grid_y .. ";6,6;]"

	-- EU status display (between grid and output)
	local eu_color = stored >= CRAFT_COST and "#00ff66" or "#ff3333"
	local eu_label = stored >= CRAFT_COST and "CHARGED" or (stored .. " / " .. CRAFT_COST .. " EU")
	fs = fs .. "label[9.2,3.6;" .. minetest.colorize("#aaaaaa", "HV Power:") .. "]"
	fs = fs .. "label[9.2,3.96;" .. minetest.colorize(eu_color, eu_label) .. "]"

	-- Arrow
	fs = fs .. "image[9.2,4.6;1.2,1.2;gui_furnace_arrow_bg.png^[transformR270]"

	-- Output slot
	fs = fs .. "list[nodemeta:" .. pos_str .. ";output;10.8,4.6;1,1;]"

	-- Normal crafting label
	fs = fs .. "label[9.2,6.4;" .. minetest.colorize("#aaaaaa",
		"Also accepts") .. "]"
	fs = fs .. "label[9.2,6.76;" .. minetest.colorize("#aaaaaa",
		"normal recipes") .. "]"

	-- Player inventory — all 4 rows must be visible
	fs = fs .. "list[current_player;main;0.6,10.0;8,1;]"
		.. "list[current_player;main;0.6,11.25;8,3;8]"

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
	description = "Advanced Crafting Machine",
	tiles = {"lazarus_space_crafting_station_3d.png"},
	groups = {
		cracky = 2,
		technic_machine = 1,
		technic_hv = 1,
	},
	connect_sides = {"top", "bottom", "front", "back", "left", "right"},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	paramtype2 = "facedir",

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("craft", 36)
		inv:set_size("output", 1)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
		meta:set_int("stored_energy", 0)
		meta:set_string("formspec", "")
		meta:set_string("infotext", "Advanced Crafting Machine — 0 EU")
	end,

	on_rightclick = function(pos, node, clicker)
		if not clicker:is_player() then return end
		local fs = build_crafting_formspec(pos)
		local pname = clicker:get_player_name()
		open_formspecs[pname] = minetest.pos_to_string(pos)
		minetest.show_formspec(pname,
			"lazarus_space:crafting6x6_" .. minetest.pos_to_string(pos), fs)
	end,

	on_metadata_inventory_move = function(pos) update_craft(pos) end,
	on_metadata_inventory_put = function(pos) update_craft(pos) end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "output" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			local craft_type = meta:get_string("craft_type")

			if craft_type == "6x6" then
				-- Consume 10,000 EU
				local stored = meta:get_int("stored_energy")
				meta:set_int("stored_energy", math.max(0, stored - CRAFT_COST))
				-- Consume one of each input
				for i = 1, 36 do
					local s = inv:get_stack("craft", i)
					if not s:is_empty() then
						s:take_item(1)
						inv:set_stack("craft", i, s)
					end
				end
			elseif craft_type == "normal" then
				-- Normal recipe: use decremented_input from minetest
				local normal_result, decremented, start_row, start_col, width, height = try_normal_craft(inv)
				if decremented then
					local dec_idx = 1
					for row = start_row, start_row + height - 1 do
						for col = start_col, start_col + width - 1 do
							local grid_idx = (row - 1) * 6 + col
							inv:set_stack("craft", grid_idx, decremented.items[dec_idx])
							dec_idx = dec_idx + 1
						end
					end
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

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local stored = meta:get_int("stored_energy")

		if stored < CRAFT_COST then
			meta:set_int("HV_EU_demand", CRAFT_COST)
			local input = meta:get_int("HV_EU_input")
			stored = math.min(CRAFT_COST, stored + input)
			meta:set_int("stored_energy", stored)
		else
			meta:set_int("HV_EU_demand", 0)
		end

		meta:set_string("infotext", "Advanced Crafting Machine — "
			.. stored .. " / " .. CRAFT_COST .. " EU"
			.. (stored >= CRAFT_COST and " (Ready)" or ""))

		-- Re-check craft output in case EU status changed
		update_craft(pos)
	end,

	technic_on_disable = function(pos, node)
		local meta = minetest.get_meta(pos)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
	end,
})

-- Register as HV machine
technic.register_machine("HV", "lazarus_space:crafting_station_3d", technic.receiver)

-- ============================================================
-- FORMSPEC TRACKING CLEANUP
-- ============================================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pos_str = formname:match("^lazarus_space:crafting6x6_(.+)$")
	if not pos_str then return end
	if fields.quit then
		open_formspecs[player:get_player_name()] = nil
	end
end)

minetest.register_on_leaveplayer(function(player)
	open_formspecs[player:get_player_name()] = nil
end)

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

-- ============================================================
-- TEST RECIPE (placeholder for development)
-- ============================================================

-- 6×6 dirt ring → mese block
-- Ring of dirt around the border of the 6×6 grid
lazarus_space.register_6x6_craft({
	output = "default:mese",
	recipe = {
		-- Row 1: full top row
		"default:dirt", "default:dirt", "default:dirt", "default:dirt", "default:dirt", "default:dirt",
		-- Row 2: sides only
		"default:dirt", "", "", "", "", "default:dirt",
		-- Row 3: sides only
		"default:dirt", "", "", "", "", "default:dirt",
		-- Row 4: sides only
		"default:dirt", "", "", "", "", "default:dirt",
		-- Row 5: sides only
		"default:dirt", "", "", "", "", "default:dirt",
		-- Row 6: full bottom row
		"default:dirt", "default:dirt", "default:dirt", "default:dirt", "default:dirt", "default:dirt",
	},
})
