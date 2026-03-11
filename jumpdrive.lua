-- Lazarus Space: Dimensional Jumpdrive
-- Independent X/Y/Z radius control (1-15 each)
-- Compatible with jumpdrive mod API (powerstorage, radius meta fields)

local MAX_RADIUS = 15

-- ============================================================
-- FORMSPEC BUILDER
-- ============================================================

local function build_jumpdrive_formspec(pos)
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
	local meta = minetest.get_meta(pos)
	local stored = meta:get_int("powerstorage")
	local rx = meta:get_int("radius_x")
	local ry = meta:get_int("radius_y")
	local rz = meta:get_int("radius_z")
	local max_radius = math.max(rx, ry, rz)
	local distance = vector.distance(pos, {
		x = meta:get_int("x"),
		y = meta:get_int("y"),
		z = meta:get_int("z"),
	})
	local power_needed
	if jumpdrive and jumpdrive.calculate_power then
		power_needed = jumpdrive.calculate_power(max_radius, distance)
	else
		power_needed = math.floor(10 * distance * max_radius)
	end

	local fs = "formspec_version[4]"
		.. "size[12.4,15.6]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Title bar
	fs = fs .. "box[0,0;12.4,0.8;#1a1a2e]"
		.. "label[3.2,0.16;" .. minetest.colorize("#00ccaa",
		"Dimensional Jumpdrive") .. "]"

	-- Target coordinates
	fs = fs .. "label[0.4,1.2;" .. minetest.colorize("#aaaaaa", "Target Coordinates:") .. "]"
	fs = fs .. "field[0.4,1.5;3.4,0.8;x;X;" .. meta:get_int("x") .. "]"
	fs = fs .. "field[4.2,1.5;3.4,0.8;y;Y;" .. meta:get_int("y") .. "]"
	fs = fs .. "field[8.0,1.5;3.4,0.8;z;Z;" .. meta:get_int("z") .. "]"

	-- Radius controls
	fs = fs .. "label[0.4,2.8;" .. minetest.colorize("#aaaaaa",
		"Jump Radius (1-" .. MAX_RADIUS .. "):") .. "]"
	fs = fs .. "field[0.4,3.1;3.4,0.8;radius_x;Radius X;" .. rx .. "]"
	fs = fs .. "field[4.2,3.1;3.4,0.8;radius_y;Radius Y;" .. ry .. "]"
	fs = fs .. "field[8.0,3.1;3.4,0.8;radius_z;Radius Z;" .. rz .. "]"

	-- Action buttons
	fs = fs .. "button[0.4,4.4;2.6,0.8;jump;Jump]"
	fs = fs .. "button[3.4,4.4;2.6,0.8;show;Show]"
	fs = fs .. "button[6.4,4.4;2.6,0.8;save;Save]"
	fs = fs .. "button[9.4,4.4;2.6,0.8;reset;Reset]"

	-- Power status
	local power_color = stored >= power_needed and "#00ff66" or "#ff3333"
	fs = fs .. "label[0.4,5.6;" .. minetest.colorize("#aaaaaa",
		"Power: ") .. minetest.colorize(power_color,
		stored .. " / " .. power_needed .. " EU") .. "]"
	fs = fs .. "label[0.4,5.96;" .. minetest.colorize("#aaaaaa",
		"Effective radius: " .. max_radius
		.. " (" .. rx .. "x" .. ry .. "x" .. rz .. ")") .. "]"
	fs = fs .. "label[0.4,6.32;" .. minetest.colorize("#aaaaaa",
		"Owner: " .. meta:get_string("owner")) .. "]"

	-- Fuel inventory (8 slots for burnable items)
	fs = fs .. "label[0.4,6.8;" .. minetest.colorize("#aaaaaa", "Fuel:") .. "]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";main;0.4,7.1;8,1;]"

	-- Player inventory
	fs = fs .. "list[current_player;main;0.4,8.4;8,1;]"
		.. "list[current_player;main;0.4,9.65;8,3;8]"

	-- Shift-click targets
	fs = fs .. "listring[nodemeta:" .. pos_str .. ";main]"
		.. "listring[current_player;main]"

	return fs
end

-- ============================================================
-- FIELD SAVE / CLAMP HELPER
-- ============================================================

local function save_fields(pos, fields)
	local meta = minetest.get_meta(pos)
	local function clamp_radius(val)
		local n = tonumber(val)
		if not n then return nil end
		return math.max(1, math.min(MAX_RADIUS, math.floor(n)))
	end

	if fields.x then
		local n = tonumber(fields.x)
		if n then meta:set_int("x", math.floor(n)) end
	end
	if fields.y then
		local n = tonumber(fields.y)
		if n then meta:set_int("y", math.floor(n)) end
	end
	if fields.z then
		local n = tonumber(fields.z)
		if n then meta:set_int("z", math.floor(n)) end
	end
	if fields.radius_x then
		local v = clamp_radius(fields.radius_x)
		if v then meta:set_int("radius_x", v) end
	end
	if fields.radius_y then
		local v = clamp_radius(fields.radius_y)
		if v then meta:set_int("radius_y", v) end
	end
	if fields.radius_z then
		local v = clamp_radius(fields.radius_z)
		if v then meta:set_int("radius_z", v) end
	end

	-- Sync single radius for jumpdrive API compatibility
	local rx = meta:get_int("radius_x")
	local ry = meta:get_int("radius_y")
	local rz = meta:get_int("radius_z")
	meta:set_int("radius", math.max(rx, ry, rz))
end

-- ============================================================
-- NODE REGISTRATION
-- ============================================================

minetest.register_node("lazarus_space:jumpdrive", {
	description = "Dimensional Jumpdrive",
	tiles = {"lazarus_space_crafting_station_3d.png"},  -- placeholder texture
	groups = {
		cracky = 2,
		technic_machine = 1,
		technic_hv = 1,
	},
	connect_sides = {"top", "bottom", "front", "back", "left", "right"},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
	paramtype2 = "facedir",
	light_source = 5,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("main", 8)
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
		meta:set_int("radius_x", 5)
		meta:set_int("radius_y", 5)
		meta:set_int("radius_z", 5)
		meta:set_int("radius", 5)  -- jumpdrive API reads this
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
		meta:set_int("powerstorage", 0)  -- jumpdrive API reads this
		meta:set_string("owner", "")
		meta:set_string("infotext", "Dimensional Jumpdrive (not owned)")
		minetest.get_node_timer(pos):start(1)
	end,

	after_place_node = function(pos, placer)
		if placer and placer:is_player() then
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name())
			meta:set_string("infotext", "Dimensional Jumpdrive (owned by "
				.. placer:get_player_name() .. ")")
		end
	end,

	on_rightclick = function(pos, node, clicker)
		if not clicker:is_player() then return end
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") ~= clicker:get_player_name() then
			minetest.chat_send_player(clicker:get_player_name(),
				"This jumpdrive belongs to " .. meta:get_string("owner"))
			return
		end
		minetest.show_formspec(clicker:get_player_name(),
			"lazarus_space:jumpdrive_" .. minetest.pos_to_string(pos),
			build_jumpdrive_formspec(pos))
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local stored = meta:get_int("powerstorage")
		local max_store = 1000000

		if stored >= max_store then return true end

		for i = 1, 8 do
			local stack = inv:get_stack("main", i)
			if not stack:is_empty() then
				local fuel = minetest.get_craft_result({
					method = "fuel",
					width = 1,
					items = {stack},
				})
				if fuel.time > 0 then
					stack:take_item(1)
					inv:set_stack("main", i, stack)
					local power_gain = fuel.time * 100
					stored = math.min(max_store, stored + power_gain)
					meta:set_int("powerstorage", stored)
					break  -- burn one item per tick
				end
			end
		end

		return true  -- keep timer running
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") ~= player:get_player_name() then
			return 0
		end
		return stack:get_count()
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") ~= player:get_player_name() then
			return 0
		end
		return stack:get_count()
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") ~= player:get_player_name() then
			return 0
		end
		return count
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local stored = meta:get_int("powerstorage")
		local max_store = 1000000

		if stored < max_store then
			meta:set_int("HV_EU_demand", 10000)
			local input = meta:get_int("HV_EU_input")
			stored = math.min(max_store, stored + input)
			meta:set_int("powerstorage", stored)
		else
			meta:set_int("HV_EU_demand", 0)
		end

		meta:set_string("infotext", "Dimensional Jumpdrive — "
			.. stored .. " EU stored"
			.. " [" .. meta:get_int("radius_x")
			.. "x" .. meta:get_int("radius_y")
			.. "x" .. meta:get_int("radius_z") .. "]")
	end,

	technic_on_disable = function(pos, node)
		local meta = minetest.get_meta(pos)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
	end,
})

-- Register as HV machine
technic.register_machine("HV", "lazarus_space:jumpdrive", technic.receiver)

-- ============================================================
-- FORMSPEC HANDLER
-- ============================================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pos_str = formname:match("^lazarus_space:jumpdrive_(.+)$")
	if not pos_str then return end
	if fields.quit then return end

	local pos = minetest.string_to_pos(pos_str)
	if not pos then return end

	local meta = minetest.get_meta(pos)
	local pname = player:get_player_name()

	-- Owner check
	if meta:get_string("owner") ~= pname then return end

	if fields.save then
		save_fields(pos, fields)
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.reset then
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.show then
		save_fields(pos, fields)
		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		local max_radius = math.max(rx, ry, rz)

		-- Sync single radius for jumpdrive API
		meta:set_int("radius", max_radius)

		if jumpdrive and jumpdrive.simulate_jump then
			jumpdrive.simulate_jump(pos, player, true)
		else
			local tx = meta:get_int("x")
			local ty = meta:get_int("y")
			local tz = meta:get_int("z")
			minetest.chat_send_player(pname,
				"Target: (" .. tx .. ", " .. ty .. ", " .. tz .. ") "
				.. "Radius: " .. rx .. "x" .. ry .. "x" .. rz)
		end
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.jump then
		-- Save fields first
		save_fields(pos, fields)

		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		local max_radius = math.max(rx, ry, rz)

		-- Set the single radius meta that jumpdrive API reads
		meta:set_int("radius", max_radius)

		if jumpdrive and jumpdrive.execute_jump then
			-- execute_jump reads target from meta x,y,z
			-- execute_jump reads radius from meta radius
			-- execute_jump reads and consumes power from meta powerstorage
			local success, result = jumpdrive.execute_jump(pos, player)

			if success then
				-- Node has MOVED to target position — pos is now stale
				minetest.chat_send_player(pname,
					"Jump complete! (" .. (result or "?") .. " ms)")
			else
				-- Jump failed — node is still at old pos, power was not consumed
				minetest.chat_send_player(pname,
					"Jump failed: " .. tostring(result))
			end
		else
			minetest.chat_send_player(pname,
				"Jumpdrive mod not available — cannot execute jump")
		end
	end
end)

-- ============================================================
-- CRAFTING RECIPE
-- ============================================================

minetest.register_craft({
	output = "lazarus_space:jumpdrive",
	recipe = {
		{"jumpdrive:warp_device", "technic:stainless_steel_block", "jumpdrive:warp_device"},
		{"technic:stainless_steel_block", "jumpdrive:engine", "technic:stainless_steel_block"},
		{"jumpdrive:warp_device", "technic:stainless_steel_block", "jumpdrive:warp_device"},
	},
})
