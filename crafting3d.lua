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
-- ATLAS TEXTURE BUILDER
-- ============================================================

local function build_atlas_texture(pos, active_layer)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	-- Start with pre-baked base atlas (9 tiles, all "active empty" style)
	local tex = "lazarus_space_crafting3d_atlas.png"
	-- Overlay solid teal fill for each occupied slot on the active layer
	for i = 1, 9 do
		local stack = inv:get_stack("layer" .. active_layer, i)
		if not stack:is_empty() then
			local x = (i - 1) * 16
			tex = tex .. "^[fill:16x16:" .. x .. "\\,0:#00ccaaff"
		end
	end
	return tex
end

-- ============================================================
-- 3D CUBE PREVIEW
-- ============================================================

local function add_cube_preview(fs, pos, active_layer)
	local atlas_tex = build_atlas_texture(pos, active_layer)
	-- Layer indicator above preview
	fs = fs .. "label[10.8,1.56;" .. minetest.colorize("#00ccaa",
		"Layer " .. active_layer) .. "]"
	fs = fs .. "model[8.76,1.8;7.08,6.24;craft3d_preview;"
		.. "crafting3d_grid.obj;" .. atlas_tex
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
	if layer < 1 or layer > 3 then layer = 1 end

	local inv_name = "layer" .. layer
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

	-- Layer label
	fs = fs .. "label[0.6,3.0;" .. minetest.colorize("#aaaaaa",
		"Editing Layer " .. layer .. " (Y=" .. layer .. ")") .. "]"

	-- 3x3 crafting grid for the active layer (nodemeta for named formspec)
	fs = fs .. "list[nodemeta:" .. pos_str .. ";" .. inv_name .. ";0.6,3.36;3.6,3.6;]"

	-- Arrow + output slot (vertically centered with middle row of grid)
	-- Grid middle row center Y = 3.36 + 1.25 + 0.625 = 5.235
	-- Arrow Y = 5.235 - 0.6 = 4.635, Output Y = 5.235 - 0.6 = 4.635
	fs = fs .. "image[4.68,4.64;1.2,1.2;gui_furnace_arrow_bg.png^[transformR270]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";output;6.24,4.64;1.2,1.2;]"

	-- Player inventory
	fs = fs .. "list[current_player;main;0.6,10;8,1;]"
		.. "list[current_player;main;0.6,11.25;8,3;8]"

	-- Shift-click targets
	fs = fs .. "listring[nodemeta:" .. pos_str .. ";" .. inv_name .. "]"
		.. "listring[current_player;main]"
		.. "listring[nodemeta:" .. pos_str .. ";output]"
		.. "listring[current_player;main]"

	-- 3D cube preview (right side)
	fs = fs .. "box[8.4,1.2;7.8,7.2;#0a0a12]"
	fs = fs .. "label[9.6,1.32;" .. minetest.colorize("#aaaaaa",
		"Layer Preview \xe2\x80\x94 click & drag to rotate") .. "]"
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

	for i = 1, 3 do
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
