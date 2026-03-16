-- Lazarus Space: Dimensional Jumpdrive
-- Independent X/Y/Z radius control (1-15 each)
-- Compatible with jumpdrive mod API (powerstorage, radius meta fields)

local MAX_RADIUS = 15
local has_vizlib = minetest.get_modpath("vizlib")

-- Per-player blanket select mode state
-- player_select_mode[playername] = {pos = jumpdrive_pos} or nil
local player_select_mode = {}

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

local function build_jumpdrive_formspec(pos, tab_override)
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

	local current_tab = tab_override or meta:get_int("formspec_tab")
	if current_tab == 0 then current_tab = 1 end

	local fs = "formspec_version[4]"
		.. "size[12.4,14.96]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Tab header
	fs = fs .. "tabheader[0,0;12.4,0.7;formspec_tab;Jump,Blanket;" .. current_tab .. ";false;false]"

	if current_tab == 1 then
		-- ========================
		-- JUMP TAB (existing UI)
		-- ========================

		-- Title bar
		fs = fs .. "box[0,0.7;12.4,0.8;#1a1a2e]"
			.. "label[3.2,0.86;" .. minetest.colorize("#00ccaa",
			"Dimensional Jumpdrive") .. "]"

		-- Target coordinates
		fs = fs .. "field[0.4,1.9;3.4,0.8;x;Target X;" .. meta:get_int("x") .. "]"
		fs = fs .. "field[4.2,1.9;3.4,0.8;y;Target Y;" .. meta:get_int("y") .. "]"
		fs = fs .. "field[8.0,1.9;3.4,0.8;z;Target Z;" .. meta:get_int("z") .. "]"

		-- Radius controls
		fs = fs .. "field[0.4,3.3;3.4,0.8;radius_x;Radius X (1-" .. MAX_RADIUS .. ");" .. rx .. "]"
		fs = fs .. "field[4.2,3.3;3.4,0.8;radius_y;Radius Y;" .. ry .. "]"
		fs = fs .. "field[8.0,3.3;3.4,0.8;radius_z;Radius Z;" .. rz .. "]"

		-- Action buttons row 1: Jump, Show, Save
		fs = fs .. "button[0.4,4.5;3.6,0.8;jump;Jump]"
		fs = fs .. "button[4.2,4.5;3.6,0.8;show;Show]"
		fs = fs .. "button[8.0,4.5;3.4,0.8;save;Save]"

		-- Action buttons row 2: Write to Book, Read from Book, Reset
		fs = fs .. "button[0.4,5.5;3.6,0.8;write_book;Write to Book]"
		fs = fs .. "button[4.2,5.5;3.6,0.8;read_book;Read from Book]"
		fs = fs .. "button[8.0,5.5;3.4,0.8;reset;Reset]"

		-- Power status
		local power_color = stored >= power_needed and "#00ff66" or "#ff3333"
		fs = fs .. "label[0.4,6.7;" .. minetest.colorize("#aaaaaa",
			"Power: ") .. minetest.colorize(power_color,
			stored .. " / " .. power_needed .. " EU") .. "]"
		fs = fs .. "label[0.4,7.06;" .. minetest.colorize("#aaaaaa",
			"Storage: " .. stored .. " / " .. max_store .. " EU"
			.. " | Radius: " .. rx .. "x" .. ry .. "x" .. rz) .. "]"
		fs = fs .. "label[0.4,7.42;" .. minetest.colorize("#aaaaaa",
			"Owner: " .. meta:get_string("owner")) .. "]"

		-- Books (4 slots) and Upgrades (4 slots) on one line with gap
		fs = fs .. "label[0.4,7.9;" .. minetest.colorize("#aaaaaa", "Books:") .. "]"
		fs = fs .. "label[6.8,7.9;" .. minetest.colorize("#aaaaaa", "Upgrades:") .. "]"
		fs = fs .. "list[nodemeta:" .. pos_str .. ";main;0.4,8.2;4,1;]"
		fs = fs .. "list[nodemeta:" .. pos_str .. ";upgrade;6.8,8.2;4,1;]"

		-- Player inventory
		fs = fs .. "list[current_player;main;0.4,9.56;8,1;]"
			.. "list[current_player;main;0.4,10.81;8,3;8]"

		-- Shift-click targets
		fs = fs .. "listring[nodemeta:" .. pos_str .. ";main]"
			.. "listring[current_player;main]"
			.. "listring[nodemeta:" .. pos_str .. ";upgrade]"
			.. "listring[current_player;main]"

	else
		-- ========================
		-- BLANKET TAB
		-- ========================

		-- Title bar
		fs = fs .. "box[0,0.7;12.4,0.8;#1a1a2e]"
			.. "label[3.6,0.86;" .. minetest.colorize("#ffaa00",
			"Blanket Mode") .. "]"

		-- Blanket status
		local blanket_active = meta:get_int("blanket_mode") == 1
		local bcount = meta:get_int("blanket_count")

		-- Action buttons: Scan, Clear, Select Mode
		fs = fs .. "button[0.4,1.9;3.6,0.8;blanket_scan;Scan]"
		fs = fs .. "button[4.2,1.9;3.6,0.8;blanket_clear;Clear]"

		-- Select mode button — color indicates state
		-- Check if any player has select mode active for this drive
		local select_active = false
		for _, sdata in pairs(player_select_mode) do
			if sdata.pos and vector.equals(sdata.pos, pos) then
				select_active = true
				break
			end
		end
		if select_active then
			fs = fs .. "button[8.0,1.9;3.4,0.8;select_mode;" .. minetest.colorize("#00aaff", "Select: ON") .. "]"
		else
			fs = fs .. "button[8.0,1.9;3.4,0.8;select_mode;Select: OFF]"
		end

		-- Exclude nodes field
		local excludes = meta:get_string("blanket_excludes")
		fs = fs .. "field[0.4,3.3;11,0.8;blanket_excludes;Exclude Nodes (comma-separated);" .. minetest.formspec_escape(excludes) .. "]"

		-- Relative coordinate selection
		fs = fs .. "label[0.4,4.4;" .. minetest.colorize("#aaaaaa", "Relative Position (offset from drive):") .. "]"
		fs = fs .. "field[0.4,4.7;2.6,0.8;sel_rx;X;0]"
		fs = fs .. "field[3.2,4.7;2.6,0.8;sel_ry;Y;0]"
		fs = fs .. "field[6.0,4.7;2.6,0.8;sel_rz;Z;0]"
		fs = fs .. "button[8.8,4.7;1.6,0.8;sel_include;Include]"
		fs = fs .. "button[10.5,4.7;1.5,0.8;sel_exclude;Exclude]"

		-- Status
		if blanket_active then
			fs = fs .. "label[0.4,5.9;" .. minetest.colorize("#ffaa00",
				"Blanket: ACTIVE (" .. bcount .. " blocks)") .. "]"
		else
			fs = fs .. "label[0.4,5.9;" .. minetest.colorize("#666666",
				"Blanket: OFF") .. "]"
		end

		-- Show exclusion and selection counts
		local selections_str = meta:get_string("blanket_selections")
		local selections = {}
		if selections_str ~= "" then
			selections = minetest.deserialize(selections_str) or {}
		end
		local include_count = 0
		local exclude_count = 0
		for _, mode in pairs(selections) do
			if mode == "include" then include_count = include_count + 1
			elseif mode == "exclude" then exclude_count = exclude_count + 1
			end
		end

		local excl_list = {}
		for name in excludes:gmatch("[^,%s]+") do
			table.insert(excl_list, name)
		end

		fs = fs .. "label[0.4,6.26;" .. minetest.colorize("#aaaaaa",
			"Node exclusions: " .. #excl_list .. " | Pos includes: " .. include_count
			.. " | Pos excludes: " .. exclude_count) .. "]"

		-- Power status (compact)
		local power_color = stored >= power_needed and "#00ff66" or "#ff3333"
		fs = fs .. "label[0.4,6.72;" .. minetest.colorize("#aaaaaa",
			"Power: ") .. minetest.colorize(power_color,
			stored .. " / " .. power_needed .. " EU")
			.. "  " .. minetest.colorize("#aaaaaa",
			"Radius: " .. rx .. "x" .. ry .. "x" .. rz) .. "]"

		-- Jump blanket button (wide)
		fs = fs .. "button[0.4,7.2;11,0.8;jump_blanket;Jump Blanket]"

		-- Clear selections button
		fs = fs .. "button[0.4,8.2;5.3,0.8;clear_selections;Clear All Selections]"
		fs = fs .. "button[5.9,8.2;5.5,0.8;remove_excludes;Clear All Exclusions]"

		-- Player inventory
		fs = fs .. "list[current_player;main;0.4,9.56;8,1;]"
			.. "list[current_player;main;0.4,10.81;8,3;8]"
	end

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

-- Draw the 12 edges of a single block as a small wireframe
-- pts = subdivisions per edge (0 = corners only, 4 = 5 points per edge)
local function draw_block_outline(bx, by, bz, color, player_name, duration, pts)
	pts = pts or 4
	local x1, y1, z1 = bx - 0.5, by - 0.5, bz - 0.5
	local x2, y2, z2 = bx + 0.5, by + 0.5, bz + 0.5

	local edges = {
		{x1,y1,z1, x2,y1,z1}, {x2,y1,z1, x2,y1,z2},
		{x2,y1,z2, x1,y1,z2}, {x1,y1,z2, x1,y1,z1},
		{x1,y2,z1, x2,y2,z1}, {x2,y2,z1, x2,y2,z2},
		{x2,y2,z2, x1,y2,z2}, {x1,y2,z2, x1,y2,z1},
		{x1,y1,z1, x1,y2,z1}, {x2,y1,z1, x2,y2,z1},
		{x2,y1,z2, x2,y2,z2}, {x1,y1,z2, x1,y2,z2},
	}

	for _, e in ipairs(edges) do
		for i = 0, pts do
			local t = pts > 0 and (i / pts) or 0.5
			minetest.add_particle({
				pos = {
					x = e[1] + (e[4] - e[1]) * t,
					y = e[2] + (e[5] - e[2]) * t,
					z = e[3] + (e[6] - e[3]) * t,
				},
				velocity = {x = 0, y = 0, z = 0},
				acceleration = {x = 0, y = 0, z = 0},
				expirationtime = duration,
				size = 1.0,
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

	-- Parse exclusion list
	local excludes_str = meta:get_string("blanket_excludes")
	local exclude_set = {}
	for name in excludes_str:gmatch("[^,%s]+") do
		exclude_set[name] = true
	end

	-- Parse position selections
	local selections_str = meta:get_string("blanket_selections")
	local selections = {}
	if selections_str ~= "" then
		selections = minetest.deserialize(selections_str) or {}
	end

	-- Build content ID exclusion set for fast VM lookup
	local exclude_ids = {}
	for name, _ in pairs(exclude_set) do
		local cid = minetest.get_content_id(name)
		if cid then
			exclude_ids[cid] = true
		end
	end

	-- Pad by 1 to ensure mapblock-border blocks are fully emerged
	local pad1 = {x = src1.x - 1, y = src1.y - 1, z = src1.z - 1}
	local pad2 = {x = src2.x + 1, y = src2.y + 1, z = src2.z + 1}
	local vm = minetest.get_voxel_manip(pad1, pad2)
	local emin, emax = vm:get_emerged_area()
	local data = vm:get_data()
	local va = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

	-- First pass: categorize all non-air blocks
	local included = {}
	local excluded = {}
	for z = src1.z, src2.z do
	for y = src1.y, src2.y do
	for x = src1.x, src2.x do
		local i = va:index(x, y, z)
		if data[i] ~= c_air and data[i] ~= c_ignore then
			local rel_key = (x - pos.x) .. "," .. (y - pos.y) .. "," .. (z - pos.z)

			-- Check position selection override first
			local sel = selections[rel_key]
			if sel == "exclude" then
				table.insert(excluded, {x = x, y = y, z = z})
			elseif sel == "include" then
				table.insert(included, {x = x, y = y, z = z})
			elseif exclude_ids[data[i]] then
				-- Node type is in the exclusion list
				table.insert(excluded, {x = x, y = y, z = z})
			else
				-- Default: include
				table.insert(included, {x = x, y = y, z = z})
			end
		end
	end end end

	-- Scale particle density based on total block count
	local total = #included + #excluded
	local pts
	if total <= 200 then
		pts = 4
	elseif total <= 500 then
		pts = 2
	else
		pts = 0
	end

	-- Draw included blocks in green, excluded in red
	for _, b in ipairs(included) do
		draw_block_outline(b.x, b.y, b.z, "#00ff66", player_name, 8, pts)
	end
	for _, b in ipairs(excluded) do
		draw_block_outline(b.x, b.y, b.z, "#ff3333", player_name, 8, pts)
	end

	meta:set_int("blanket_mode", 1)
	meta:set_int("blanket_count", #included)

	return #included
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

	-- Check for source/destination overlap — if overlapping, we need a two-pass approach
	local areas_overlap = not (src2.x < dst1.x or dst2.x < src1.x or
	                           src2.y < dst1.y or dst2.y < src1.y or
	                           src2.z < dst1.z or dst2.z < src1.z)

	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")

	-- Phase 1: Read source area, collect non-air node data and metadata
	local src_vm = minetest.get_voxel_manip(src1, src2)
	local src_emin, src_emax = src_vm:get_emerged_area()
	local src_data = src_vm:get_data()
	local src_p2 = src_vm:get_param2_data()
	local src_va = VoxelArea:new({MinEdge = src_emin, MaxEdge = src_emax})

	-- Parse exclusion list
	local excludes_str = meta:get_string("blanket_excludes")
	local exclude_set = {}
	for name in excludes_str:gmatch("[^,%s]+") do
		exclude_set[name] = true
	end

	-- Build content ID exclusion set
	local exclude_ids = {}
	for name, _ in pairs(exclude_set) do
		local cid = minetest.get_content_id(name)
		if cid then
			exclude_ids[cid] = true
		end
	end

	-- Parse position selections
	local selections_str = meta:get_string("blanket_selections")
	local selections = {}
	if selections_str ~= "" then
		selections = minetest.deserialize(selections_str) or {}
	end

	local move_list = {}
	for z = src1.z, src2.z do
	for y = src1.y, src2.y do
	for x = src1.x, src2.x do
		local si = src_va:index(x, y, z)
		if src_data[si] ~= c_air and src_data[si] ~= c_ignore then
			local rel_key = (x - pos.x) .. "," .. (y - pos.y) .. "," .. (z - pos.z)

			-- Check if this block should be moved
			local sel = selections[rel_key]
			local should_move = true
			if sel == "exclude" then
				should_move = false
			elseif sel == "include" then
				should_move = true
			elseif exclude_ids[src_data[si]] then
				should_move = false
			end

			if should_move then
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
		end
	end end end

	-- Build lookup of all source positions being cleared to air
	local clearing = {}
	for _, entry in ipairs(move_list) do
		clearing[entry.from.x .. "," .. entry.from.y .. "," .. entry.from.z] = true
	end

	-- Per-block collision check: every non-air source block must land on air at destination
	-- Read a combined area covering both source and destination so we get correct data
	-- even when they're in the same mapblock
	local check_min = {
		x = math.min(src1.x, dst1.x), y = math.min(src1.y, dst1.y), z = math.min(src1.z, dst1.z)
	}
	local check_max = {
		x = math.max(src2.x, dst2.x), y = math.max(src2.y, dst2.y), z = math.max(src2.z, dst2.z)
	}
	local dst_vm_check = minetest.get_voxel_manip(check_min, check_max)
	local dst_check_emin, dst_check_emax = dst_vm_check:get_emerged_area()
	local dst_check_data = dst_vm_check:get_data()
	local dst_check_va = VoxelArea:new({MinEdge = dst_check_emin, MaxEdge = dst_check_emax})

	for _, entry in ipairs(move_list) do
		local di = dst_check_va:index(entry.to.x, entry.to.y, entry.to.z)
		if dst_check_data[di] ~= c_air and dst_check_data[di] ~= c_ignore then
			-- Check if this position is a source block being cleared
			local to_key = entry.to.x .. "," .. entry.to.y .. "," .. entry.to.z
			if not clearing[to_key] then
				minetest.chat_send_player(pname, minetest.colorize("#ff3333",
					"Blanket jump blocked — destination has non-air block at ("
					.. entry.to.x .. "," .. entry.to.y .. "," .. entry.to.z .. ")"))
				return false
			end
		end
	end

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
		meta:set_string("blanket_excludes", "")       -- comma-separated node names to exclude
		meta:set_string("blanket_selections", "")     -- serialized table of relative pos overrides
		meta:set_int("formspec_tab", 1)               -- 1=Jump, 2=Blanket
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

		-- Color depends on whether select mode is active
		local sdata = player_select_mode[pname]
		local in_select = sdata and sdata.pos and vector.equals(sdata.pos, pos)
		local color = in_select and "#00aaff" or "#00ff66"

		if has_vizlib then
			vizlib.draw_area(
				{x = source_pos1.x - 0.5, y = source_pos1.y - 0.5, z = source_pos1.z - 0.5},
				{x = source_pos2.x + 0.5, y = source_pos2.y + 0.5, z = source_pos2.z + 0.5},
				{color = color, player = puncher, time = 5})
		else
			draw_particle_box(source_pos1, source_pos2, color, pname, 5)
		end

		local msg = "Radius: " .. rx .. "x" .. ry .. "x" .. rz
			.. " | Area: " .. (rx*2+1) .. "x" .. (ry*2+1) .. "x" .. (rz*2+1) .. " blocks"
		if in_select then
			msg = msg .. " | " .. minetest.colorize("#00aaff", "SELECT MODE")
		end
		minetest.chat_send_player(pname, msg)
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

	-- Tab switching
	if fields.formspec_tab then
		local tab = tonumber(fields.formspec_tab)
		if tab then
			meta:set_int("formspec_tab", tab)
			minetest.show_formspec(pname,
				"lazarus_space:jumpdrive_" .. minetest.pos_to_string(pos),
				build_jumpdrive_formspec(pos, tab))
		end
		return
	end

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
		if has_vizlib then
			vizlib.draw_area(
				{x = source_pos1.x - 0.5, y = source_pos1.y - 0.5, z = source_pos1.z - 0.5},
				{x = source_pos2.x + 0.5, y = source_pos2.y + 0.5, z = source_pos2.z + 0.5},
				{color = "#00ff66", player = player, time = 8})
			vizlib.draw_area(
				{x = target_pos1.x - 0.5, y = target_pos1.y - 0.5, z = target_pos1.z - 0.5},
				{x = target_pos2.x + 0.5, y = target_pos2.y + 0.5, z = target_pos2.z + 0.5},
				{color = "#4488ff", player = player, time = 8})
		else
			draw_particle_box(source_pos1, source_pos2, "#00ff66", pname, 8)
			draw_particle_box(target_pos1, target_pos2, "#4488ff", pname, 8)
		end

		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos))

	elseif fields.jump then
		save_fields(pos, fields)

		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		local max_radius = math.max(rx, ry, rz)
		meta:set_int("radius", max_radius)

		-- Normal jump via jumpdrive API (blanket jump is on the Blanket tab)
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

	elseif fields.blanket_scan then
		save_fields(pos, fields)
		-- Save excludes field
		if fields.blanket_excludes then
			meta:set_string("blanket_excludes", fields.blanket_excludes)
		end
		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		meta:set_int("radius", math.max(rx, ry, rz))

		local count = scan_blanket(pos, pname)
		minetest.chat_send_player(pname, minetest.colorize("#ffaa00",
			"Blanket scan: " .. count .. " blocks selected"))

		-- Draw outer box outline
		local src1 = {x = pos.x - rx, y = pos.y - ry, z = pos.z - rz}
		local src2 = {x = pos.x + rx, y = pos.y + ry, z = pos.z + rz}
		if has_vizlib and vizlib and vizlib.draw_area then
			vizlib.draw_area(
				{x = src1.x - 0.5, y = src1.y - 0.5, z = src1.z - 0.5},
				{x = src2.x + 0.5, y = src2.y + 0.5, z = src2.z + 0.5},
				{color = "#ffaa00", player = player, time = 8})
		else
			draw_particle_box(src1, src2, "#ffaa00", pname, 8)
		end

		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))

	elseif fields.blanket_clear then
		meta:set_int("blanket_mode", 0)
		meta:set_int("blanket_count", 0)
		-- Also exit select mode for this player
		player_select_mode[pname] = nil
		minetest.chat_send_player(pname, minetest.colorize("#666666",
			"Blanket cleared"))
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))

	elseif fields.select_mode then
		if player_select_mode[pname] and player_select_mode[pname].pos
				and vector.equals(player_select_mode[pname].pos, pos) then
			-- Toggle OFF
			player_select_mode[pname] = nil
			minetest.chat_send_player(pname, minetest.colorize("#666666",
				"Select mode OFF — normal punch restored"))
		else
			-- Toggle ON
			player_select_mode[pname] = {pos = vector.new(pos)}
			minetest.chat_send_player(pname, minetest.colorize("#00aaff",
				"Select mode ON — punch blocks to include/exclude them"))
		end
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))

	elseif fields.sel_include or fields.sel_exclude then
		local rx_val = tonumber(fields.sel_rx)
		local ry_val = tonumber(fields.sel_ry)
		local rz_val = tonumber(fields.sel_rz)
		if rx_val and ry_val and rz_val then
			rx_val = math.floor(rx_val)
			ry_val = math.floor(ry_val)
			rz_val = math.floor(rz_val)
			local key = rx_val .. "," .. ry_val .. "," .. rz_val
			local selections_str = meta:get_string("blanket_selections")
			local selections = {}
			if selections_str ~= "" then
				selections = minetest.deserialize(selections_str) or {}
			end
			local mode = fields.sel_include and "include" or "exclude"
			selections[key] = mode
			meta:set_string("blanket_selections", minetest.serialize(selections))
			minetest.chat_send_player(pname, minetest.colorize(
				mode == "include" and "#00ff66" or "#ff3333",
				"Position (" .. key .. ") set to " .. mode))
		else
			minetest.chat_send_player(pname, minetest.colorize("#ff3333",
				"Invalid coordinates — enter numbers"))
		end
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))

	elseif fields.clear_selections then
		meta:set_string("blanket_selections", "")
		minetest.chat_send_player(pname, minetest.colorize("#666666",
			"All position selections cleared"))
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))

	elseif fields.remove_excludes then
		meta:set_string("blanket_excludes", "")
		minetest.chat_send_player(pname, minetest.colorize("#666666",
			"All node exclusions cleared"))
		minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))

	elseif fields.jump_blanket then
		-- Save excludes field if present
		if fields.blanket_excludes then
			meta:set_string("blanket_excludes", fields.blanket_excludes)
		end
		save_fields(pos, fields)
		local rx = meta:get_int("radius_x")
		local ry = meta:get_int("radius_y")
		local rz = meta:get_int("radius_z")
		meta:set_int("radius", math.max(rx, ry, rz))

		-- Force blanket mode on if not already (scan first if needed)
		if meta:get_int("blanket_mode") ~= 1 then
			scan_blanket(pos, pname)
		end

		local success = execute_blanket_jump(pos, player)
		if success then
			player_select_mode[pname] = nil  -- clear select mode after jump
			minetest.close_formspec(pname, formname)
		else
			minetest.show_formspec(pname, formname, build_jumpdrive_formspec(pos, 2))
		end
	end
end)

-- ============================================================
-- FLEET CONTROLLER COMPATIBILITY
-- ============================================================

-- Override fleet controller's engine discovery to include our jumpdrive
-- The original find_engines only searches for "jumpdrive:engine"
minetest.register_on_mods_loaded(function()
	if not jumpdrive or not jumpdrive.fleet then return end

	-- Store reference to original if it exists
	local orig_find_engines = jumpdrive.fleet.find_engines

	if orig_find_engines then
		jumpdrive.fleet.find_engines = function(pos, visited_hashes, engine_list)
			visited_hashes = visited_hashes or {}
			engine_list = engine_list or {}

			local hash = minetest.hash_node_position(pos)
			if visited_hashes[hash] then
				return engine_list
			end
			visited_hashes[hash] = true

			local pos1 = {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1}
			local pos2 = {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1}

			-- Search for both standard engines AND our dimensional jumpdrive
			local engine_nodes = minetest.find_nodes_in_area(pos1, pos2,
				{"jumpdrive:engine", "lazarus_space:jumpdrive"})
			for _, epos in ipairs(engine_nodes) do
				local ehash = minetest.hash_node_position(epos)
				if not visited_hashes[ehash] then
					visited_hashes[ehash] = true
					table.insert(engine_list, epos)
					-- Recurse from engine position to find more via backbone
					jumpdrive.fleet.find_engines(epos, visited_hashes, engine_list)
				end
			end

			-- Traverse backbone nodes
			local backbone_nodes = minetest.find_nodes_in_area(pos1, pos2,
				{"jumpdrive:backbone"})
			for _, bpos in ipairs(backbone_nodes) do
				local bhash = minetest.hash_node_position(bpos)
				if not visited_hashes[bhash] then
					jumpdrive.fleet.find_engines(bpos, visited_hashes, engine_list)
				end
			end

			return engine_list
		end

		minetest.log("action", "[lazarus_space] Patched fleet controller engine discovery")
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

-- ============================================================
-- SELECT MODE: punch blocks to toggle include/exclude
-- ============================================================

minetest.register_on_punchnode(function(punch_pos, node, puncher, pointed_thing)
	if not puncher or not puncher:is_player() then return end
	local pname = puncher:get_player_name()

	local sdata = player_select_mode[pname]
	if not sdata or not sdata.pos then return end

	local drive_pos = sdata.pos
	local drive_meta = minetest.get_meta(drive_pos)

	-- Verify the jumpdrive still exists and player owns it
	local drive_node = minetest.get_node(drive_pos)
	if drive_node.name ~= "lazarus_space:jumpdrive" then
		player_select_mode[pname] = nil
		return
	end
	if drive_meta:get_string("owner") ~= pname then
		player_select_mode[pname] = nil
		return
	end

	-- Check if punched position is within the drive's radius
	local rx = drive_meta:get_int("radius_x")
	local ry = drive_meta:get_int("radius_y")
	local rz = drive_meta:get_int("radius_z")

	local rel_x = punch_pos.x - drive_pos.x
	local rel_y = punch_pos.y - drive_pos.y
	local rel_z = punch_pos.z - drive_pos.z

	if math.abs(rel_x) > rx or math.abs(rel_y) > ry or math.abs(rel_z) > rz then
		minetest.chat_send_player(pname, minetest.colorize("#ff3333",
			"Block is outside radius — not toggled"))
		return
	end

	-- Toggle the selection for this relative position
	local key = rel_x .. "," .. rel_y .. "," .. rel_z
	local selections_str = drive_meta:get_string("blanket_selections")
	local selections = {}
	if selections_str ~= "" then
		selections = minetest.deserialize(selections_str) or {}
	end

	local new_mode
	if selections[key] == "exclude" then
		-- Was excluded → include (or remove override to use default)
		selections[key] = nil
		new_mode = "default"
	elseif selections[key] == "include" then
		-- Was explicitly included → exclude
		selections[key] = "exclude"
		new_mode = "exclude"
	else
		-- No override → exclude
		selections[key] = "exclude"
		new_mode = "exclude"
	end

	drive_meta:set_string("blanket_selections", minetest.serialize(selections))

	-- Visual feedback: color coded particle on the punched block
	if new_mode == "exclude" then
		draw_block_outline(punch_pos.x, punch_pos.y, punch_pos.z,
			"#ff3333", pname, 4, 2)
		minetest.chat_send_player(pname, minetest.colorize("#ff3333",
			"Excluded (" .. key .. ")"))
	else
		draw_block_outline(punch_pos.x, punch_pos.y, punch_pos.z,
			"#00ff66", pname, 4, 2)
		minetest.chat_send_player(pname, minetest.colorize("#00ff66",
			"Restored (" .. key .. ") to default"))
	end
end)

-- Clean up select mode when player leaves
minetest.register_on_leaveplayer(function(player)
	player_select_mode[player:get_player_name()] = nil
end)
