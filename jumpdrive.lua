-- Lazarus Space: Dimensional Jumpdrive
-- Independent X/Y/Z radius control (1-15 each)
-- Compatible with jumpdrive mod API (powerstorage, radius meta fields)

local MAX_RADIUS = 15

-- ============================================================
-- UPGRADE SYSTEM
-- ============================================================

local BASE_MAX_POWER = 1000000  -- 1M EU base storage

local UPGRADE_ITEMS = {
	["technic:red_energy_crystal"]   = 0.10,  -- +10% storage per crystal
	["technic:green_energy_crystal"] = 0.20,  -- +20% storage per crystal
	["technic:blue_energy_crystal"]  = 0.50,  -- +50% storage per crystal
}

local function recalculate_upgrades(pos)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()

	local multiplier = 1.0
	for i = 1, inv:get_size("upgrade") do
		local stack = inv:get_stack("upgrade", i)
		local bonus = UPGRADE_ITEMS[stack:get_name()]
		if bonus then
			multiplier = multiplier + bonus
		end
	end

	local max_power = math.floor(BASE_MAX_POWER * multiplier)
	meta:set_int("max_powerstorage", max_power)

	-- Clamp current storage if it exceeds new max
	local stored = meta:get_int("powerstorage")
	if stored > max_power then
		meta:set_int("powerstorage", max_power)
	end
end

-- ============================================================
-- BOOK COORDINATE SYSTEM
-- ============================================================

local function write_coordinates_to_book(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local pname = player:get_player_name()

	-- Find a blank book in the main inventory
	local book_item = "default:book"
	local book_slot = nil
	for i = 1, inv:get_size("main") do
		local stack = inv:get_stack("main", i)
		if stack:get_name() == book_item then
			book_slot = i
			break
		end
	end

	if not book_slot then
		minetest.chat_send_player(pname, "No blank book found in inventory")
		return false
	end

	-- Create written book with coordinates
	local target = {
		x = meta:get_int("x"),
		y = meta:get_int("y"),
		z = meta:get_int("z"),
	}

	local written = ItemStack("default:book_written")
	local stack_meta = written:get_meta()
	stack_meta:set_string("owner", pname)
	stack_meta:set_string("title", "Jumpdrive Coordinates")
	stack_meta:set_string("text", minetest.serialize(target))
	stack_meta:set_string("description", "Jumpdrive: ("
		.. target.x .. ", " .. target.y .. ", " .. target.z .. ")")

	-- Remove blank book, add written book
	local old_stack = inv:get_stack("main", book_slot)
	old_stack:take_item(1)
	inv:set_stack("main", book_slot, old_stack)

	if inv:room_for_item("main", written) then
		inv:add_item("main", written)
	else
		minetest.add_item(pos, written)  -- drop on ground if full
	end

	minetest.chat_send_player(pname, "Coordinates saved to book: ("
		.. target.x .. ", " .. target.y .. ", " .. target.z .. ")")
	return true
end

local function read_coordinates_from_book(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local pname = player:get_player_name()

	-- Search for a written book in the main inventory (search backwards like original)
	for i = inv:get_size("main"), 1, -1 do
		local stack = inv:get_stack("main", i)
		if stack:get_name() == "default:book_written" then
			local stack_meta = stack:get_meta()
			local text = stack_meta:get_string("text")
			if text and text ~= "" then
				local data = minetest.deserialize(text)
				if data and data.x and data.y and data.z then
					meta:set_int("x", math.floor(data.x))
					meta:set_int("y", math.floor(data.y))
					meta:set_int("z", math.floor(data.z))
					minetest.chat_send_player(pname,
						"Coordinates loaded: ("
						.. data.x .. ", " .. data.y .. ", " .. data.z .. ")")
					return true
				else
					minetest.chat_send_player(pname, "Invalid coordinates in book")
					return false
				end
			end
		end
	end

	minetest.chat_send_player(pname, "No written book found in inventory")
	return false
end

-- ============================================================
-- FORMSPEC BUILDER
-- ============================================================

local function build_jumpdrive_formspec(pos)
	local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
	local meta = minetest.get_meta(pos)
	local stored = meta:get_int("powerstorage")
	local max_store = meta:get_int("max_powerstorage")
	if max_store == 0 then max_store = BASE_MAX_POWER end
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
		.. "size[12.4,14.8]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Title bar
	fs = fs .. "box[0,0;12.4,0.8;#1a1a2e]"
		.. "label[3.2,0.16;" .. minetest.colorize("#00ccaa",
		"Dimensional Jumpdrive") .. "]"

	-- Target coordinates
	fs = fs .. "field[0.4,1.2;3.4,0.8;x;Target X;" .. meta:get_int("x") .. "]"
	fs = fs .. "field[4.2,1.2;3.4,0.8;y;Target Y;" .. meta:get_int("y") .. "]"
	fs = fs .. "field[8.0,1.2;3.4,0.8;z;Target Z;" .. meta:get_int("z") .. "]"

	-- Radius controls
	fs = fs .. "field[0.4,2.6;3.4,0.8;radius_x;Radius X (1-" .. MAX_RADIUS .. ");" .. rx .. "]"
	fs = fs .. "field[4.2,2.6;3.4,0.8;radius_y;Radius Y;" .. ry .. "]"
	fs = fs .. "field[8.0,2.6;3.4,0.8;radius_z;Radius Z;" .. rz .. "]"

	-- Action buttons (row 1)
	fs = fs .. "button[0.4,3.8;2.6,0.8;jump;Jump]"
	fs = fs .. "button[3.4,3.8;2.6,0.8;show;Show]"
	fs = fs .. "button[6.4,3.8;2.6,0.8;save;Save]"
	fs = fs .. "button[9.4,3.8;2.6,0.8;reset;Reset]"

	-- Book buttons (row 2)
	fs = fs .. "button[0.4,4.8;5.4,0.8;write_book;Write to Book]"
	fs = fs .. "button[6.2,4.8;5.4,0.8;read_book;Read from Book]"

	-- Power status
	local power_color = stored >= power_needed and "#00ff66" or "#ff3333"
	fs = fs .. "label[0.4,5.6;" .. minetest.colorize("#aaaaaa",
		"Power: ") .. minetest.colorize(power_color,
		stored .. " / " .. power_needed .. " EU") .. "]"
	fs = fs .. "label[0.4,5.96;" .. minetest.colorize("#aaaaaa",
		"Storage: " .. stored .. " / " .. max_store .. " EU"
		.. " | Radius: " .. rx .. "x" .. ry .. "x" .. rz) .. "]"
	fs = fs .. "label[0.4,6.32;" .. minetest.colorize("#aaaaaa",
		"Owner: " .. meta:get_string("owner")) .. "]"

	-- Books (4 slots) and Upgrades (4 slots) on one line with gap
	fs = fs .. "label[0.4,6.8;" .. minetest.colorize("#aaaaaa", "Books:") .. "]"
	fs = fs .. "label[6.8,6.8;" .. minetest.colorize("#aaaaaa", "Upgrades:") .. "]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";main;0.4,7.1;4,1;]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";upgrade;6.8,7.1;4,1;]"

	-- Player inventory — all 4 rows
	fs = fs .. "list[current_player;main;0.4,8.4;8,1;]"
		.. "list[current_player;main;0.4,9.65;8,3;8]"

	-- Shift-click targets
	fs = fs .. "listring[nodemeta:" .. pos_str .. ";main]"
		.. "listring[current_player;main]"
		.. "listring[nodemeta:" .. pos_str .. ";upgrade]"
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
-- VISUALIZATION: particle box outline
-- ============================================================

local function draw_particle_box(pos1, pos2, color, player_name, duration)
	duration = duration or 5
	local particles_per_edge = 30

	local x1, y1, z1 = pos1.x - 0.5, pos1.y - 0.5, pos1.z - 0.5
	local x2, y2, z2 = pos2.x + 0.5, pos2.y + 0.5, pos2.z + 0.5

	local edges = {
		-- Bottom face (y1)
		{{x1,y1,z1}, {x2,y1,z1}},
		{{x2,y1,z1}, {x2,y1,z2}},
		{{x2,y1,z2}, {x1,y1,z2}},
		{{x1,y1,z2}, {x1,y1,z1}},
		-- Top face (y2)
		{{x1,y2,z1}, {x2,y2,z1}},
		{{x2,y2,z1}, {x2,y2,z2}},
		{{x2,y2,z2}, {x1,y2,z2}},
		{{x1,y2,z2}, {x1,y2,z1}},
		-- Vertical edges
		{{x1,y1,z1}, {x1,y2,z1}},
		{{x2,y1,z1}, {x2,y2,z1}},
		{{x2,y1,z2}, {x2,y2,z2}},
		{{x1,y1,z2}, {x1,y2,z2}},
	}

	for _, edge in ipairs(edges) do
		local a, b = edge[1], edge[2]
		for i = 0, particles_per_edge do
			local t = i / particles_per_edge
			minetest.add_particle({
				pos = {
					x = a[1] + (b[1] - a[1]) * t,
					y = a[2] + (b[2] - a[2]) * t,
					z = a[3] + (b[3] - a[3]) * t,
				},
				velocity = {x = 0, y = 0, z = 0},
				acceleration = {x = 0, y = 0, z = 0},
				expirationtime = duration,
				size = 2,
				glow = 14,
				texture = "lazarus_space_particle_white.png^[colorize:" .. color .. ":255",
				playername = player_name,
			})
		end
	end
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
		inv:set_size("main", 4)      -- books only (no fuel)
		inv:set_size("upgrade", 4)   -- technic energy crystals
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
		meta:set_int("radius_x", 5)
		meta:set_int("radius_y", 5)
		meta:set_int("radius_z", 5)
		meta:set_int("radius", 5)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
		meta:set_int("powerstorage", 0)
		meta:set_int("max_powerstorage", BASE_MAX_POWER)
		meta:set_string("owner", "")
		meta:set_string("infotext", "Dimensional Jumpdrive (not owned)")
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

	on_punch = function(pos, node, puncher, pointed_thing)
		if not puncher or not puncher:is_player() then return end
		local meta = minetest.get_meta(pos)
		local pname = puncher:get_player_name()

		if meta:get_string("owner") ~= pname then return end

		local wielded = puncher:get_wielded_item()
		if not wielded:is_empty() then return end

		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")

		local source_pos1 = {x = pos.x - rx, y = pos.y - ry, z = pos.z - rz}
		local source_pos2 = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}

		draw_particle_box(source_pos1, source_pos2, "#00ff66", pname, 5)

		minetest.chat_send_player(pname,
			"Radius: " .. rx .. "x" .. ry .. "x" .. rz
			.. " | Area: " .. (rx*2+1) .. "x" .. (ry*2+1) .. "x" .. (rz*2+1) .. " blocks")
	end,

	on_metadata_inventory_put = function(pos, listname)
		if listname == "upgrade" then
			recalculate_upgrades(pos)
		end
	end,

	on_metadata_inventory_take = function(pos, listname)
		if listname == "upgrade" then
			recalculate_upgrades(pos)
		end
	end,

	on_metadata_inventory_move = function(pos, from_list, from_index, to_list)
		if from_list == "upgrade" or to_list == "upgrade" then
			recalculate_upgrades(pos)
		end
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") ~= player:get_player_name() then
			return 0
		end
		if listname == "upgrade" then
			-- Only allow registered upgrade items
			if UPGRADE_ITEMS[stack:get_name()] then
				return stack:get_count()
			end
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
		if to_list == "upgrade" then
			-- Check if the item being moved is a valid upgrade
			local inv = meta:get_inventory()
			local stack = inv:get_stack(from_list, from_index)
			if not UPGRADE_ITEMS[stack:get_name()] then
				return 0
			end
		end
		return count
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local stored = meta:get_int("powerstorage")
		local max_store = meta:get_int("max_powerstorage")
		if max_store == 0 then max_store = BASE_MAX_POWER end

		if stored < max_store then
			meta:set_int("HV_EU_demand", 10000)
			local input = meta:get_int("HV_EU_input")
			stored = math.min(max_store, stored + input)
			meta:set_int("powerstorage", stored)
		else
			meta:set_int("HV_EU_demand", 0)
		end

		meta:set_string("infotext", "Dimensional Jumpdrive — "
			.. stored .. " / " .. max_store .. " EU"
			.. " [" .. meta:get_int("radius_x")
			.. "x" .. meta:get_int("radius_y")
			.. "x" .. meta:get_int("radius_z") .. "]")
	end,

	on_movenode = function(from_pos, to_pos, info)
		-- Destroy technic network cache at source so switching station rebuilds
		if technic.pos2network and technic.remove_network then
			local src_net_id = technic.pos2network(from_pos)
			if src_net_id then
				technic.remove_network(src_net_id)
			end
			-- Also destroy network cache at edges near destination
			if info and info.edge then
				for axis, value in pairs(info.edge) do
					if value ~= 0 then
						local axis_dir = {x = 0, y = 0, z = 0}
						axis_dir[axis] = value
						local edge_pos = vector.add(to_pos, axis_dir)
						local dst_net_id = technic.pos2network(edge_pos)
						if dst_net_id then
							technic.remove_network(dst_net_id)
						end
					end
				end
			end
		end
	end,

	technic_on_disable = function(pos, node)
		local meta = minetest.get_meta(pos)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
	end,
})

-- Register as HV machine
technic.register_machine("HV", "lazarus_space:jumpdrive", technic.receiver)

-- Force technic network rebuild after any jump that might include our node
if jumpdrive and jumpdrive.register_after_jump then
	jumpdrive.register_after_jump(function(from_area, to_area)
		-- Invalidate networks at both source and destination areas
		if technic.pos2network and technic.remove_network then
			local from_center = {
				x = math.floor((from_area.x + to_area.x) / 2),
				y = math.floor((from_area.y + to_area.y) / 2),
				z = math.floor((from_area.z + to_area.z) / 2),
			}
			local net_id = technic.pos2network(from_center)
			if net_id then
				technic.remove_network(net_id)
			end
		end
	end)
end

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

	elseif fields.write_book then
		save_fields(pos, fields)
		write_coordinates_to_book(pos, player)
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.read_book then
		read_coordinates_from_book(pos, player)
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.show then
		save_fields(pos, fields)
		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		local max_radius = math.max(rx, ry, rz)
		meta:set_int("radius", max_radius)

		local tx = meta:get_int("x")
		local ty = meta:get_int("y")
		local tz = meta:get_int("z")

		-- Run full preflight checks via jumpdrive API
		if jumpdrive and jumpdrive.simulate_jump then
			local success, msg = jumpdrive.simulate_jump(pos, player, true)
			if msg and msg ~= "" then
				-- simulate_jump returns multi-line messages with all check results
				for line in msg:gmatch("[^\n]+") do
					minetest.chat_send_player(pname, line)
				end
			end
			if success then
				minetest.chat_send_player(pname,
					minetest.colorize("#00ff66", "Preflight OK — ready to jump"))
			else
				minetest.chat_send_player(pname,
					minetest.colorize("#ff3333", "Preflight FAILED — see warnings above"))
			end
		else
			-- Fallback: basic info only (no jumpdrive mod)
			local distance = vector.distance(pos, {x = tx, y = ty, z = tz})
			local power_needed = math.floor(10 * distance * max_radius)
			local stored = meta:get_int("powerstorage")
			local power_status = stored >= power_needed and "OK" or "INSUFFICIENT"
			minetest.chat_send_player(pname,
				"Distance: " .. math.floor(distance) .. " blocks | "
				.. "Power: " .. stored .. "/" .. power_needed .. " EU (" .. power_status .. ") | "
				.. "Radius: " .. rx .. "x" .. ry .. "x" .. rz)
		end

		-- Always draw our own particle visualization for the XYZ radii
		-- (vizlib only draws cubic areas, ours shows the actual rectangular bounds)
		local source_pos1 = {x = pos.x - rx, y = pos.y - ry, z = pos.z - rz}
		local source_pos2 = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}
		local target = {x = tx, y = ty, z = tz}
		local offset = vector.subtract(target, pos)
		local target_pos1 = vector.add(source_pos1, offset)
		local target_pos2 = vector.add(source_pos2, offset)
		draw_particle_box(source_pos1, source_pos2, "#00ff66", pname, 8)
		draw_particle_box(target_pos1, target_pos2, "#4488ff", pname, 8)

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
