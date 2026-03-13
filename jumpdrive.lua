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
		.. "size[12.4,14.96]"
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

	-- Action buttons row 1: Jump, Blanket, Show, Save
	fs = fs .. "button[0.4,3.8;2.7,0.8;jump;Jump]"
	fs = fs .. "button[3.3,3.8;2.7,0.8;blanket;Blanket]"
	fs = fs .. "button[6.2,3.8;2.7,0.8;show;Show]"
	fs = fs .. "button[9.1,3.8;2.7,0.8;save;Save]"

	-- Action buttons row 2: Write to Book, Read from Book, Reset
	fs = fs .. "button[0.4,4.8;3.6,0.8;write_book;Write to Book]"
	fs = fs .. "button[4.2,4.8;3.6,0.8;read_book;Read from Book]"
	fs = fs .. "button[8.0,4.8;3.4,0.8;reset;Reset]"

	-- Power status (y=6.0, well below buttons ending at 5.6)
	local power_color = stored >= power_needed and "#00ff66" or "#ff3333"
	fs = fs .. "label[0.4,6.0;" .. minetest.colorize("#aaaaaa",
		"Power: ") .. minetest.colorize(power_color,
		stored .. " / " .. power_needed .. " EU") .. "]"
	fs = fs .. "label[0.4,6.36;" .. minetest.colorize("#aaaaaa",
		"Storage: " .. stored .. " / " .. max_store .. " EU"
		.. " | Radius: " .. rx .. "x" .. ry .. "x" .. rz) .. "]"
	fs = fs .. "label[0.4,6.72;" .. minetest.colorize("#aaaaaa",
		"Owner: " .. meta:get_string("owner")) .. "]"

	-- Blanket status
	local blanket_active = meta:get_int("blanket_mode") == 1
	if blanket_active then
		local bcount = meta:get_int("blanket_count")
		fs = fs .. "label[0.4,7.08;" .. minetest.colorize("#ffaa00",
			"Blanket: ACTIVE (" .. bcount .. " blocks)") .. "]"
	else
		fs = fs .. "label[0.4,7.08;" .. minetest.colorize("#666666",
			"Blanket: OFF") .. "]"
	end

	-- Books (4 slots) and Upgrades (4 slots) on one line with gap
	fs = fs .. "label[0.4,7.56;" .. minetest.colorize("#aaaaaa", "Books:") .. "]"
	fs = fs .. "label[6.8,7.56;" .. minetest.colorize("#aaaaaa", "Upgrades:") .. "]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";main;0.4,7.86;4,1;]"
	fs = fs .. "list[nodemeta:" .. pos_str .. ";upgrade;6.8,7.86;4,1;]"

	-- Player inventory — all 4 rows
	fs = fs .. "list[current_player;main;0.4,9.16;8,1;]"
		.. "list[current_player;main;0.4,10.41;8,3;8]"

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
-- BLANKET SCAN: highlight non-air blocks in radius with particles
-- ============================================================

local function scan_blanket(pos, player_name)
	local meta = minetest.get_meta(pos)
	local rx = meta:get_int("radius_x")
	local ry = meta:get_int("radius_y")
	local rz = meta:get_int("radius_z")

	local src1 = {x = pos.x - rx, y = pos.y - ry, z = pos.z - rz}
	local src2 = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}

	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")

	local vm = minetest.get_voxel_manip(src1, src2)
	local emin, emax = vm:get_emerged_area()
	local data = vm:get_data()
	local va = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

	local count = 0
	for z = src1.z, src2.z do
	for y = src1.y, src2.y do
	for x = src1.x, src2.x do
		local i = va:index(x, y, z)
		if data[i] ~= c_air and data[i] ~= c_ignore then
			count = count + 1
			minetest.add_particle({
				pos = {x = x, y = y + 0.5, z = z},
				velocity = {x = 0, y = 0.1, z = 0},
				acceleration = {x = 0, y = 0, z = 0},
				expirationtime = 8,
				size = 3,
				glow = 14,
				texture = "lazarus_space_particle_white.png^[colorize:#ffaa00:200",
				playername = player_name,
			})
		end
	end end end

	meta:set_int("blanket_mode", 1)
	meta:set_int("blanket_count", count)

	return count
end

-- ============================================================
-- BLANKET JUMP: move non-air blocks only, preserve destination terrain
-- ============================================================

local function execute_blanket_jump(pos, player)
	local meta = minetest.get_meta(pos)
	local pname = player:get_player_name()
	local rx = meta:get_int("radius_x")
	local ry = meta:get_int("radius_y")
	local rz = meta:get_int("radius_z")
	local max_radius = math.max(rx, ry, rz)

	local target = {x = meta:get_int("x"), y = meta:get_int("y"), z = meta:get_int("z")}
	local offset = vector.subtract(target, pos)
	local distance = vector.distance(pos, target)

	-- Power check
	local power_needed
	if jumpdrive and jumpdrive.calculate_power then
		power_needed = jumpdrive.calculate_power(max_radius, distance)
	else
		power_needed = math.floor(10 * distance * max_radius)
	end
	local stored = meta:get_int("powerstorage")
	if stored < power_needed then
		minetest.chat_send_player(pname, minetest.colorize("#ff3333",
			"Not enough power: " .. stored .. "/" .. power_needed .. " EU"))
		return false
	end

	-- Source and destination areas
	local src1 = {x = pos.x - rx, y = pos.y - ry, z = pos.z - rz}
	local src2 = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}
	local dst1 = vector.add(src1, offset)
	local dst2 = vector.add(src2, offset)

	-- Overlap check — areas must not intersect
	if not (src2.x < dst1.x or dst2.x < src1.x or
	        src2.y < dst1.y or dst2.y < src1.y or
	        src2.z < dst1.z or dst2.z < src1.z) then
		minetest.chat_send_player(pname, minetest.colorize("#ff3333",
			"Source and target areas overlap — cannot blanket jump"))
		return false
	end

	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")

	-- Phase 1: Read source area, collect non-air node data and metadata
	local src_vm = minetest.get_voxel_manip(src1, src2)
	local src_emin, src_emax = src_vm:get_emerged_area()
	local src_data = src_vm:get_data()
	local src_p2 = src_vm:get_param2_data()
	local src_va = VoxelArea:new({MinEdge = src_emin, MaxEdge = src_emax})

	local move_list = {}
	for z = src1.z, src2.z do
	for y = src1.y, src2.y do
	for x = src1.x, src2.x do
		local si = src_va:index(x, y, z)
		if src_data[si] ~= c_air and src_data[si] ~= c_ignore then
			local from_pos = {x = x, y = y, z = z}
			local to_pos = {x = x + offset.x, y = y + offset.y, z = z + offset.z}

			-- Save metadata and timer before we clear the source
			local meta_table = minetest.get_meta(from_pos):to_table()
			local timer = minetest.get_node_timer(from_pos)
			local timer_data = nil
			if timer:is_started() then
				timer_data = {timeout = timer:get_timeout(), elapsed = timer:get_elapsed()}
			end

			table.insert(move_list, {
				from = from_pos,
				to = to_pos,
				id = src_data[si],
				p2 = src_p2[si],
				meta = meta_table,
				timer = timer_data,
			})

			-- Mark source as air
			src_data[si] = c_air
			src_p2[si] = 0
		end
	end end end

	if #move_list == 0 then
		minetest.chat_send_player(pname, minetest.colorize("#ff3333",
			"No blocks to move — area is empty"))
		return false
	end

	-- Phase 2: Write cleared source area
	src_vm:set_data(src_data)
	src_vm:set_param2_data(src_p2)
	src_vm:write_to_map(true)

	-- Phase 3: Read destination, overlay non-air nodes (preserve existing terrain)
	local dst_vm = minetest.get_voxel_manip(dst1, dst2)
	local dst_emin, dst_emax = dst_vm:get_emerged_area()
	local dst_data = dst_vm:get_data()
	local dst_p2 = dst_vm:get_param2_data()
	local dst_va = VoxelArea:new({MinEdge = dst_emin, MaxEdge = dst_emax})

	for _, entry in ipairs(move_list) do
		local di = dst_va:index(entry.to.x, entry.to.y, entry.to.z)
		dst_data[di] = entry.id
		dst_p2[di] = entry.p2
	end

	dst_vm:set_data(dst_data)
	dst_vm:set_param2_data(dst_p2)
	dst_vm:write_to_map(true)

	-- Phase 4: Transfer metadata and timers to destination, clear source metadata
	for _, entry in ipairs(move_list) do
		if entry.meta then
			minetest.get_meta(entry.to):from_table(entry.meta)
		end
		if entry.timer then
			minetest.get_node_timer(entry.to):set(entry.timer.timeout, entry.timer.elapsed)
		end
		-- Clear leftover source metadata
		minetest.get_meta(entry.from):from_table({fields = {}, inventory = {}})
		minetest.get_node_timer(entry.from):stop()
	end

	-- Phase 5: Move players and objects inside source area to destination
	local objects = minetest.get_objects_in_area(
		{x = src1.x - 0.5, y = src1.y - 0.5, z = src1.z - 0.5},
		{x = src2.x + 0.5, y = src2.y + 0.5, z = src2.z + 0.5}
	)
	for _, obj in ipairs(objects) do
		obj:set_pos(vector.add(obj:get_pos(), offset))
	end

	-- Phase 6: Deduct power from jumpdrive at its new position
	local new_pos = vector.add(pos, offset)
	local new_meta = minetest.get_meta(new_pos)
	new_meta:set_int("powerstorage", stored - power_needed)
	new_meta:set_int("blanket_mode", 0)
	new_meta:set_int("blanket_count", 0)

	-- Phase 7: Invalidate technic networks at both locations
	if technic.pos2network and technic.remove_network then
		local sn = technic.pos2network(pos)
		if sn then technic.remove_network(sn) end
		local dn = technic.pos2network(new_pos)
		if dn then technic.remove_network(dn) end
	end

	-- Sound effect
	if minetest.get_modpath("jumpdrive") then
		minetest.sound_play("jumpdrive_engine", {pos = new_pos, gain = 1.0, max_hear_distance = 50})
	end

	minetest.chat_send_player(pname, minetest.colorize("#00ff66",
		"Blanket jump complete — " .. #move_list .. " blocks moved"))
	return true
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
		meta:set_int("blanket_mode", 0)
		meta:set_int("blanket_count", 0)
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
		meta:set_int("blanket_mode", 0)
		meta:set_int("blanket_count", 0)
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.reset then
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
		meta:set_int("blanket_mode", 0)
		meta:set_int("blanket_count", 0)
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

	elseif fields.blanket then
		save_fields(pos, fields)
		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		meta:set_int("radius", math.max(rx, ry, rz))

		local count = scan_blanket(pos, pname)

		minetest.chat_send_player(pname, minetest.colorize("#ffaa00",
			"Blanket scan: " .. count .. " blocks selected — press Jump to move them"))

		-- Draw orange box outline around the full radius for reference
		local src1 = {x = pos.x - rx, y = pos.y - ry, z = pos.z - rz}
		local src2 = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}
		draw_particle_box(src1, src2, "#ffaa00", pname, 8)

		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.jump then
		save_fields(pos, fields)

		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		local max_radius = math.max(rx, ry, rz)
		meta:set_int("radius", max_radius)

		local blanket_active = meta:get_int("blanket_mode") == 1

		if blanket_active then
			-- Blanket jump: non-air blocks only
			local success = execute_blanket_jump(pos, player)
			if success then
				minetest.close_formspec(pname, formname)
			else
				minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))
			end
		else
			-- Normal jump via jumpdrive API
			if jumpdrive and jumpdrive.execute_jump then
				local success, result = jumpdrive.execute_jump(pos, player)
				if success then
					minetest.chat_send_player(pname,
						"Jump complete! (" .. (result or "?") .. " ms)")
				else
					minetest.chat_send_player(pname,
						"Jump failed: " .. tostring(result))
				end
			else
				minetest.chat_send_player(pname,
					"Jumpdrive mod not available — cannot execute jump")
			end
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
