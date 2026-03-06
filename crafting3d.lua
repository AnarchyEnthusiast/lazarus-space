-- Lazarus Space: Dimensional Crafting Station (3x3x3 Cube)
-- 27-slot crafting grid across 3 layers with live 3D cube preview.

-- ============================================================
-- REGISTERED 3D RECIPES
-- ============================================================

local recipes_3d = {}

lazarus_space.register_3d_craft = function(def)
	recipes_3d[#recipes_3d + 1] = {
		output = def.output,
		recipe = def.recipe,
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

lazarus_space.find_3d_craft = function(grid)
	for _, recipe in ipairs(recipes_3d) do
		local match = true
		for layer = 1, 3 do
			if not match then break end
			local r = recipe.recipe[layer]
			if not r then
				-- Recipe has no layer defined; all slots must be empty
				for i = 1, 9 do
					if grid[layer][i] ~= "" then
						match = false
						break
					end
				end
			else
				for i = 1, 9 do
					if not item_matches(r[i] or "", grid[layer][i]) then
						match = false
						break
					end
				end
			end
		end
		if match then
			return recipe.output
		end
	end
	return nil
end

-- ============================================================
-- STYLED BUTTON HELPER (local copy)
-- ============================================================

local function styled_btn(fs, x, y, w, h, name, label, bg, bg_hover, bg_press, text)
	text = text or "#ffffff"
	bg_hover = bg_hover or bg
	bg_press = bg_press or bg
	fs = fs .. "style[" .. name .. ";bgcolor=" .. bg
		.. ";bgcolor_hovered=" .. bg_hover
		.. ";bgcolor_pressed=" .. bg_press
		.. ";textcolor=" .. text .. "]"
	fs = fs .. "button[" .. x .. "," .. y .. ";" .. w .. "," .. h
		.. ";" .. name .. ";" .. label .. "]"
	return fs
end

-- ============================================================
-- 3D CUBE PREVIEW
-- ============================================================

local function add_cube_preview(fs, pos, active_layer)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local textures = {}

	for layer = 1, 3 do
		local list_name = "layer" .. layer
		for row = 1, 3 do
			for col = 1, 3 do
				local idx = (row - 1) * 3 + col
				local stack = inv:get_stack(list_name, idx)
				if stack:is_empty() then
					if layer == active_layer then
						textures[#textures + 1] = "lazarus_space_grid_active.png"
					else
						textures[#textures + 1] = "lazarus_space_grid_empty.png"
					end
				else
					local item_name = stack:get_name()
					local def = minetest.registered_items[item_name]
					if def then
						local tex = def.inventory_image or ""
						if tex == "" and def.tiles and def.tiles[1] then
							tex = def.tiles[1]
							if type(tex) == "table" then tex = tex.name or "" end
						end
						textures[#textures + 1] = tex ~= "" and tex or "unknown_item.png"
					else
						textures[#textures + 1] = "unknown_item.png"
					end
				end
			end
		end
	end

	local tex_str = table.concat(textures, ",")
	fs = fs .. "model[7.3,1.5;5.9,5.2;craft3d_preview;"
		.. "crafting3d_grid.obj;" .. tex_str
		.. ";20,-30;false;true]"
	return fs
end

-- ============================================================
-- CRAFTING OUTPUT UPDATE
-- ============================================================

local function build_crafting3d_formspec(pos)  -- forward declaration
end

local function update_3d_craft(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local grid = {}
	for layer = 1, 3 do
		grid[layer] = {}
		for i = 1, 9 do
			local stack = inv:get_stack("layer" .. layer, i)
			grid[layer][i] = stack:get_name()
		end
	end

	local result = lazarus_space.find_3d_craft(grid)
	if result then
		inv:set_stack("output", 1, result)
	else
		inv:set_stack("output", 1, "")
	end

	meta:set_string("formspec", build_crafting3d_formspec(pos))
end

-- ============================================================
-- FORMSPEC BUILDER
-- ============================================================

build_crafting3d_formspec = function(pos)
	local meta = minetest.get_meta(pos)
	local layer = meta:get_int("active_layer")
	if layer < 1 or layer > 3 then layer = 1 end

	local inv_name = "layer" .. layer

	local fs = "formspec_version[4]"
		.. "size[14,10]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Title
	fs = fs .. "box[0,0;14,0.8;#1a1a2e]"
		.. "label[4.5,0.2;Dimensional Crafting Station]"

	-- Layer selection buttons
	fs = fs .. "label[0.5,1.2;Layer:]"
	for i = 1, 3 do
		local btn_name = "layer_" .. i
		if i == layer then
			fs = styled_btn(fs, 0.5 + (i - 1) * 1.3, 1.5, 1.1, 0.7,
				btn_name, tostring(i), "#00ccaa", "#00ddbb", "#009988")
		else
			fs = styled_btn(fs, 0.5 + (i - 1) * 1.3, 1.5, 1.1, 0.7,
				btn_name, tostring(i), "#2a2a3e", "#3a3a4e", "#1a1a2e", "#aaaaaa")
		end
	end

	-- Layer label
	fs = fs .. "label[0.5,2.5;" .. minetest.colorize("#aaaaaa",
		"Editing Layer " .. layer .. " (Y=" .. layer .. ")") .. "]"

	-- 3x3 crafting grid for the active layer
	fs = fs .. "list[context;" .. inv_name .. ";0.5,2.8;3,3;]"

	-- Arrow + output slot
	fs = fs .. "image[3.9,3.8;1,1;gui_furnace_arrow_bg.png^[transformR270]"
	fs = fs .. "list[context;output;5.2,3.6;1,1;]"

	-- Player inventory
	fs = fs .. "list[current_player;main;0.5,7.5;8,1;]"
		.. "list[current_player;main;0.5,8.7;8,3;8]"

	-- Shift-click targets
	fs = fs .. "listring[context;" .. inv_name .. "]"
		.. "listring[current_player;main]"
		.. "listring[context;output]"
		.. "listring[current_player;main]"

	-- 3D cube preview (right side)
	fs = fs .. "box[7,1;6.5,6;#0a0a12]"
	fs = fs .. "label[8.5,1.1;" .. minetest.colorize("#aaaaaa",
		"3D Preview \xe2\x80\x94 click & drag to rotate") .. "]"
	fs = add_cube_preview(fs, pos, layer)

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
		inv:set_size("layer1", 9)
		inv:set_size("layer2", 9)
		inv:set_size("layer3", 9)
		inv:set_size("output", 1)
		meta:set_int("active_layer", 1)
		meta:set_string("formspec", build_crafting3d_formspec(pos))
		meta:set_string("infotext", "Dimensional Crafting Station")
	end,

	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", build_crafting3d_formspec(pos))
	end,

	on_metadata_inventory_move = function(pos) update_3d_craft(pos) end,
	on_metadata_inventory_put = function(pos) update_3d_craft(pos) end,
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if listname == "output" then
			local inv = minetest.get_meta(pos):get_inventory()
			for layer = 1, 3 do
				for i = 1, 9 do
					local s = inv:get_stack("layer" .. layer, i)
					if not s:is_empty() then
						s:take_item(1)
						inv:set_stack("layer" .. layer, i, s)
					end
				end
			end
		end
		update_3d_craft(pos)
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
-- LAYER SWITCHING HANDLER
-- ============================================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then return end
	-- Node formspec — check if any layer button was pressed
	local dominated = false
	for i = 1, 3 do
		if fields["layer_" .. i] then
			dominated = true
			break
		end
	end
	if not dominated then return end

	-- Find the node the player is interacting with
	local pos = nil
	local inv = player:get_inventory()
	-- Use player's current formspec interaction position
	-- For node formspecs, we need to find the crafting station
	local player_pos = player:get_pos()
	-- Search nearby for the crafting station
	local radius = 6
	local found = minetest.find_node_near(player_pos, radius, {"lazarus_space:crafting_station_3d"})
	if not found then return end
	pos = found

	for i = 1, 3 do
		if fields["layer_" .. i] then
			local meta = minetest.get_meta(pos)
			meta:set_int("active_layer", i)
			meta:set_string("formspec", build_crafting3d_formspec(pos))
			return
		end
	end
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
