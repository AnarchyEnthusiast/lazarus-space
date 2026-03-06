-- Lazarus Space: Dimensional Crafting Station (3x3x3 Cube)
-- 27-slot crafting grid across 3 layers with per-layer 3D preview.

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
-- LAYER GRID VIEWS
-- ============================================================

local function add_layer_grid(fs, pos, layer_num)
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
	local inv_name = "layer" .. layer_num

	-- Background panel
	local panel_x = 1.0
	local panel_y = 2.8
	local panel_w = 9.6
	local panel_h = 6.4
	fs = fs .. "box[" .. panel_x .. "," .. panel_y .. ";"
		.. panel_w .. "," .. panel_h .. ";#0a0a12]"

	-- Layer label centered above grid
	fs = fs .. "label[" .. (panel_x + panel_w / 2 - 1.2) .. "," .. (panel_y + 0.2)
		.. ";" .. minetest.colorize("#00ccaa", "Layer " .. layer_num
		.. " (Y=" .. layer_num .. ")") .. "]"

	-- 3x3 inventory grid — large slots for direct item placement
	local slot_size = 1.5
	local slot_gap = 0.2
	local grid_w = 3 * slot_size + 2 * slot_gap  -- 4.9
	local grid_x = panel_x + (panel_w - grid_w) / 2
	local grid_y = panel_y + 1.0

	-- Draw slot backgrounds
	for row = 0, 2 do
		for col = 0, 2 do
			local sx = grid_x + col * (slot_size + slot_gap)
			local sy = grid_y + row * (slot_size + slot_gap)
			fs = fs .. "box[" .. sx .. "," .. sy .. ";"
				.. slot_size .. "," .. slot_size .. ";#111122]"
		end
	end

	-- Actual inventory list on top of the backgrounds
	fs = fs .. "list[nodemeta:" .. pos_str .. ";" .. inv_name .. ";"
		.. grid_x .. "," .. grid_y .. ";3,3;]"

	return fs
end

local function add_all_layers_view(fs, pos)
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	-- Background panel
	fs = fs .. "box[0.6,2.8;10.0,6.4;#0a0a12]"
	fs = fs .. "label[3.2,2.96;" .. minetest.colorize("#aaaaaa",
		"All Layers \xe2\x80\x94 switch to Layer 1/2/3 to edit") .. "]"

	-- Draw 3 layers stacked: layer 1 at bottom, layer 3 at top
	local slot_size = 0.9
	local slot_gap = 0.1
	local grid_w = 3 * slot_size + 2 * slot_gap  -- 2.9

	-- Base position for layer 1 (bottom-left)
	local base_x = 2.0
	local base_y = 7.0

	-- Per-layer offset for stacking effect
	local offset_x = 0.8
	local offset_y = -1.6

	for layer = 1, 3 do
		local lx = base_x + (layer - 1) * offset_x
		local ly = base_y + (layer - 1) * offset_y

		-- Layer background with slight color variation
		local bg_alpha = layer == 1 and "#0d0d1a" or (layer == 2 and "#0f0f1e" or "#111122")
		fs = fs .. "box[" .. (lx - 0.1) .. "," .. (ly - 0.3) .. ";"
			.. (grid_w + 0.2) .. "," .. (grid_w + 0.5) .. ";" .. bg_alpha .. "]"

		-- Layer number label
		fs = fs .. "label[" .. lx .. "," .. (ly - 0.2) .. ";"
			.. minetest.colorize("#00ccaa", "L" .. layer) .. "]"

		-- Show items using item_image[] (read-only visual)
		for row = 0, 2 do
			for col = 0, 2 do
				local idx = row * 3 + col + 1
				local sx = lx + col * (slot_size + slot_gap)
				local sy = ly + row * (slot_size + slot_gap)

				local stack = inv:get_stack("layer" .. layer, idx)

				-- Slot background
				local slot_color = stack:is_empty() and "#1a1a22" or "#0a2a25"
				fs = fs .. "box[" .. sx .. "," .. sy .. ";"
					.. slot_size .. "," .. slot_size .. ";" .. slot_color .. "]"

				-- Item image if slot is filled
				if not stack:is_empty() then
					fs = fs .. "item_image[" .. sx .. "," .. sy .. ";"
						.. slot_size .. "," .. slot_size .. ";"
						.. stack:get_name() .. "]"
				end
			end
		end
	end

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

	-- Refresh formspec for all nearby players viewing it
	local fs = build_crafting3d_formspec(pos)
	local formname = "lazarus_space:crafting3d_" .. minetest.pos_to_string(pos)
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

build_crafting3d_formspec = function(pos)
	local meta = minetest.get_meta(pos)
	local layer = meta:get_int("active_layer")
	if layer < 1 or layer > 4 then layer = 1 end
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z

	local fs = "formspec_version[4]"
		.. "size[16.8,15.5]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Title
	fs = fs .. "box[0,0;16.8,0.96;#1a1a2e]"
		.. "label[5.4,0.24;Dimensional Crafting Station]"

	-- Layer selection buttons
	fs = fs .. "label[0.6,1.44;Layer:]"
	for i = 1, 3 do
		local btn_name = "layer_" .. i
		if i == layer then
			fs = styled_btn(fs, 0.6 + (i - 1) * 1.56, 1.8, 1.32, 0.84,
				btn_name, tostring(i), "#00ccaa", "#00ddbb", "#009988")
		else
			fs = styled_btn(fs, 0.6 + (i - 1) * 1.56, 1.8, 1.32, 0.84,
				btn_name, tostring(i), "#2a2a3e", "#3a3a4e", "#1a1a2e", "#aaaaaa")
		end
	end
	-- "All" button
	if layer == 4 then
		fs = styled_btn(fs, 0.6 + 3 * 1.56, 1.8, 1.32, 0.84,
			"layer_4", "All", "#00ccaa", "#00ddbb", "#009988")
	else
		fs = styled_btn(fs, 0.6 + 3 * 1.56, 1.8, 1.32, 0.84,
			"layer_4", "All", "#2a2a3e", "#3a3a4e", "#1a1a2e", "#aaaaaa")
	end

	-- Main crafting area
	if layer >= 1 and layer <= 3 then
		fs = add_layer_grid(fs, pos, layer)
	else
		fs = add_all_layers_view(fs, pos)
	end

	-- Arrow + output slot (right of the crafting grid)
	fs = fs .. "image[9.8,4.64;1.2,1.2;gui_furnace_arrow_bg.png^[transformR270]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";output;11.4,4.64;1.2,1.2;]"

	-- Player inventory
	fs = fs .. "list[current_player;main;0.6,10;8,1;]"
		.. "list[current_player;main;0.6,11.25;8,3;8]"

	-- Shift-click targets (use current editing layer)
	local shift_layer = layer
	if shift_layer == 4 then shift_layer = 1 end
	fs = fs .. "listring[nodemeta:" .. pos_str .. ";layer" .. shift_layer .. "]"
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
		inv:set_size("layer1", 9)
		inv:set_size("layer2", 9)
		inv:set_size("layer3", 9)
		inv:set_size("output", 1)
		meta:set_int("active_layer", 1)
		meta:set_string("formspec", "")  -- no node meta formspec, use named
		meta:set_string("infotext", "Dimensional Crafting Station")
	end,

	on_rightclick = function(pos, node, clicker)
		if not clicker:is_player() then return end
		local fs = build_crafting3d_formspec(pos)
		minetest.show_formspec(clicker:get_player_name(),
			"lazarus_space:crafting3d_" .. minetest.pos_to_string(pos), fs)
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
	-- Parse position from formname: "lazarus_space:crafting3d_(x,y,z)"
	local pos_str = formname:match("^lazarus_space:crafting3d_(.+)$")
	if not pos_str then return end
	local pos = minetest.string_to_pos(pos_str)
	if not pos then return end

	-- Verify node still exists
	local node = minetest.get_node(pos)
	if node.name ~= "lazarus_space:crafting_station_3d" then return end

	for i = 1, 4 do
		if fields["layer_" .. i] then
			local meta = minetest.get_meta(pos)
			meta:set_int("active_layer", i)
			-- Push updated formspec to the player
			minetest.show_formspec(player:get_player_name(),
				formname, build_crafting3d_formspec(pos))
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

-- ============================================================
-- 3D CRAFTING RECIPES
-- ============================================================

-- Diamond pillar: 3 diamonds stacked vertically → diamond block
lazarus_space.register_3d_craft({
	output = "default:diamondblock",
	recipe = {
		-- Layer 1 (bottom)
		{"", "", "",  "", "default:diamond", "",  "", "", ""},
		-- Layer 2 (middle)
		{"", "", "",  "", "default:diamond", "",  "", "", ""},
		-- Layer 3 (top)
		{"", "", "",  "", "default:diamond", "",  "", "", ""},
	},
})

-- Steel cage: steel ingots forming cube frame → 2 steel blocks
lazarus_space.register_3d_craft({
	output = "default:steelblock 2",
	recipe = {
		-- Layer 1 (bottom): full 3x3 ring
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot",
		 "default:steel_ingot", "",                    "default:steel_ingot",
		 "default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		-- Layer 2 (middle): 4 corners only
		{"default:steel_ingot", "", "default:steel_ingot",
		 "",                    "", "",
		 "default:steel_ingot", "", "default:steel_ingot"},
		-- Layer 3 (top): full 3x3 ring
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot",
		 "default:steel_ingot", "",                    "default:steel_ingot",
		 "default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
	},
})

-- Pole field from pole corrector core: corrector centered with 6 steel → 4 pole field
lazarus_space.register_3d_craft({
	output = "lazarus_space:pole_field 4",
	recipe = {
		-- Layer 1: steel in center
		{"", "", "",  "", "default:steelblock", "",  "", "", ""},
		-- Layer 2: steel cross around pole corrector
		{"", "default:steelblock", "",
		 "default:steelblock", "lazarus_space:pole_corrector", "default:steelblock",
		 "", "default:steelblock", ""},
		-- Layer 3: steel in center
		{"", "", "",  "", "default:steelblock", "",  "", "", ""},
	},
})
