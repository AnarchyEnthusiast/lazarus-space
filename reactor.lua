-- Lazarus Space: Magnetic Fusion Reactor
-- 13x13x5 multiblock structure with jump start sequence and power output.

-- ============================================================
-- CONSTANTS
-- ============================================================

local FUEL_SLOTS = 6
local FUEL_ITEM = "technic:uranium_fuel"
local FUEL_DURATION = 30 * 60 -- 30 minutes total for 6 rods
local CHARGE_TIME = 5 -- 5-second countdown
local POWER_OUTPUT = 140000 -- 140,000 EU
local JUMPSTART_ENERGY = 50000 -- HV energy needed to jumpstart
local STRUCTURE_CHECK_INTERVAL = 3 -- seconds between integrity checks

-- ============================================================
-- HELPER: check neighbor for node name
-- ============================================================

local function has_neighbor(pos, target_name)
	local dirs = {
		{x=1,y=0,z=0}, {x=-1,y=0,z=0},
		{x=0,y=1,z=0}, {x=0,y=-1,z=0},
		{x=0,y=0,z=1}, {x=0,y=0,z=-1},
	}
	for _, d in ipairs(dirs) do
		local p = vector.add(pos, d)
		local node = minetest.get_node(p)
		if node.name == target_name then
			return true, p
		end
	end
	return false
end

local function find_neighbor(pos, target_name)
	local dirs = {
		{x=1,y=0,z=0}, {x=-1,y=0,z=0},
		{x=0,y=1,z=0}, {x=0,y=-1,z=0},
		{x=0,y=0,z=1}, {x=0,y=0,z=-1},
	}
	for _, d in ipairs(dirs) do
		local p = vector.add(pos, d)
		local node = minetest.get_node(p)
		if node.name == target_name then
			return p
		end
	end
	return nil
end

-- ============================================================
-- MULTIBLOCK STRUCTURE DEFINITION
-- ============================================================
-- Generated from /home/dev/MGMT/reference/reactor2.mts schematic.
-- 13x13x5 cross shape. Offsets relative to the pole_corrector at (0,0,0).
-- Floor at y=-2, Roof at y=+2, middle layers y=-1,0,+1.
-- 314 total blocks: 120 PF, 96 TF, 65 SB, 28 PLF, 4 PLC, 1 PC, + 3 enforced air.

local STRUCTURE = {}

local function S(dx, dy, dz, node)
	STRUCTURE[#STRUCTURE+1] = {x=dx, y=dy, z=dz, node=node}
end

local PF  = "lazarus_space:pole_field"
local TF  = "lazarus_space:toroid_field"
local PLF = "lazarus_space:plasma_field"
local PLC = "lazarus_space:plasma_field_corner"
local PC  = "lazarus_space:pole_corrector"
local SB  = "default:steelblock"
local AIR = "air"

-- ---- FLOOR (y = -2): pole_field border, steelblock interior grid ----
-- Outer ring of pole_field
for i = -6, 6 do S(i,-2,-6, PF); S(i,-2, 6, PF) end  -- north/south rows
for i = -5, 5 do S(-6,-2, i, PF); S( 6,-2, i, PF) end -- west/east columns
-- Steelblock cross at arm positions (center row/col z=0, and arm edges)
S( 0,-2, 0, SB)
-- z=0 row: full steelblock spine
for i = -5, 5 do S(i,-2, 0, SB) end
-- x=0 column: full steelblock spine
for i = -5, 5 do if i ~= 0 then S(0,-2, i, SB) end end
-- Corner steelblock pairs at (+-5, +-5) and 3x3 center steelblock ring
for _, c in ipairs({{-5,-5},{-5,5},{5,-5},{5,5}}) do S(c[1],-2,c[2], SB) end
-- 3x3 steelblock ring around center at z=+-1, x=+-1
S(-1,-2,-1, SB); S( 0,-2,-1, SB); S( 1,-2,-1, SB)
S(-1,-2, 1, SB); S( 0,-2, 1, SB); S( 1,-2, 1, SB)

-- ---- ROOF (y = +2): pole_field border, steelblock corners, air center ----
for i = -6, 6 do S(i, 2,-6, PF); S(i, 2, 6, PF) end
for i = -5, 5 do S(-6, 2, i, PF); S( 6, 2, i, PF) end
for _, c in ipairs({{-5,-5},{-5,5},{5,-5},{5,5}}) do S(c[1], 2,c[2], SB) end
S(0, 2, 0, AIR) -- air above pole corrector

-- ---- MIDDLE LAYERS y=-1 and y=+1 (symmetric): toroid walls, steelblock transitions ----
for _, dy in ipairs({-1, 1}) do
	-- Corner steelblocks
	for _, c in ipairs({{-5,-5},{-5,5},{5,-5},{5,5}}) do S(c[1],dy,c[2], SB) end
	-- North/South arm toroid walls (3 columns: x=-2, 0, +2)
	for _, dz in ipairs({-5,-4,-3, 3,4,5}) do
		S(-2,dy,dz, TF); S(0,dy,dz, TF); S(2,dy,dz, TF)
	end
	-- East/West arm toroid walls (3 rows: z=-2, 0, +2)
	-- But NOT overlapping the N/S arm ranges
	S(-5,dy,-2, TF); S(-4,dy,-2, TF); S(-3,dy,-2, TF)
	S( 3,dy,-2, TF); S( 4,dy,-2, TF); S( 5,dy,-2, TF)
	S(-5,dy, 0, TF); S(-4,dy, 0, TF); S(-3,dy, 0, TF)
	S( 3,dy, 0, TF); S( 4,dy, 0, TF); S( 5,dy, 0, TF)
	S(-5,dy, 2, TF); S(-4,dy, 2, TF); S(-3,dy, 2, TF)
	S( 3,dy, 2, TF); S( 4,dy, 2, TF); S( 5,dy, 2, TF)
	-- Steel block transitions at arm-to-center boundary
	S(-2,dy, 0, SB); S( 2,dy, 0, SB)
	S( 0,dy,-2, SB); S( 0,dy, 2, SB)
	-- Center 3x3: pole field ring with air at (0,0)
	S(-1,dy,-1, PF); S( 0,dy,-1, PF); S( 1,dy,-1, PF)
	S(-1,dy, 0, PF);                   S( 1,dy, 0, PF)
	S(-1,dy, 1, PF); S( 0,dy, 1, PF); S( 1,dy, 1, PF)
	-- Air above/below pole corrector
	S(0,dy, 0, AIR)
end

-- ---- MIDDLE LAYER y=0: the main layer with plasma ring, pole corrector ----
-- Corner steelblocks (doubled at plasma ring junction)
S(-5, 0,-5, SB); S(-4, 0,-5, SB); S( 4, 0,-5, SB); S( 5, 0,-5, SB)
S(-5, 0, 5, SB); S(-4, 0, 5, SB); S( 4, 0, 5, SB); S( 5, 0, 5, SB)
S(-5, 0,-4, SB); S( 5, 0,-4, SB)
S(-5, 0, 4, SB); S( 5, 0, 4, SB)
-- Plasma field ring (straight pieces)
S(-4, 0,-4, PLF); S(-2, 0,-4, PLF); S(-1, 0,-4, PLF); S( 0, 0,-4, PLF)
S( 1, 0,-4, PLF); S( 2, 0,-4, PLF); S( 3, 0,-4, PLF)
S(-4, 0,-3, PLF); S( 4, 0,-3, PLF)
S(-4, 0,-2, PLF); S( 4, 0,-2, PLF)
S(-4, 0,-1, PLF); S( 4, 0,-1, PLF)
S(-4, 0, 0, PLF); S( 4, 0, 0, PLF)
S(-4, 0, 1, PLF); S( 4, 0, 1, PLF)
S(-4, 0, 2, PLF); S( 4, 0, 2, PLF)
S( 4, 0, 3, PLF)
S(-4, 0, 4, PLF); S(-3, 0, 4, PLF); S(-2, 0, 4, PLF); S(-1, 0, 4, PLF)
S( 0, 0, 4, PLF); S( 1, 0, 4, PLF); S( 3, 0, 4, PLF); S( 4, 0, 4, PLF)
-- Plasma field corners (4 corners of the ring)
S(-3, 0,-4, PLC)  -- NW corner
S( 4, 0,-4, PLC)  -- NE corner
S(-4, 0, 3, PLC)  -- SW corner
S( 2, 0, 4, PLC)  -- SE corner
-- Toroid walls inside the plasma ring (arm walls)
S(-2, 0,-5, TF); S( 0, 0,-5, TF); S( 2, 0,-5, TF)
S(-2, 0,-3, TF); S( 0, 0,-3, TF); S( 2, 0,-3, TF)
S(-5, 0,-2, TF); S(-3, 0,-2, TF); S( 3, 0,-2, TF); S( 5, 0,-2, TF)
S(-5, 0, 0, TF); S(-3, 0, 0, TF); S( 3, 0, 0, TF); S( 5, 0, 0, TF)
S(-5, 0, 2, TF); S(-3, 0, 2, TF); S( 3, 0, 2, TF); S( 5, 0, 2, TF)
S(-2, 0, 3, TF); S( 0, 0, 3, TF); S( 2, 0, 3, TF)
S(-2, 0, 5, TF); S( 0, 0, 5, TF); S( 2, 0, 5, TF)
-- Steel block transitions at arm-to-center boundary
S(-2, 0, 0, SB); S( 2, 0, 0, SB); S( 0, 0,-2, SB); S( 0, 0, 2, SB)
-- Center 3x3: pole field ring with pole corrector
S(-1, 0,-1, PF); S( 0, 0,-1, PF); S( 1, 0,-1, PF)
S(-1, 0, 0, PF); S( 0, 0, 0, PC); S( 1, 0, 0, PF)
S(-1, 0, 1, PF); S( 0, 0, 1, PF); S( 1, 0, 1, PF)

-- ============================================================
-- STRUCTURE VALIDATION
-- ============================================================

--- Find the pole corrector near a given position.
local function find_pole_corrector(pos)
	local range = 8
	for dx = -range, range do
		for dy = -range, range do
			for dz = -range, range do
				local p = {x=pos.x+dx, y=pos.y+dy, z=pos.z+dz}
				if minetest.get_node(p).name == PC then
					return p
				end
			end
		end
	end
	return nil
end

--- Validate the reactor structure.
-- Returns true on success, or false + list of error strings.
function lazarus_space.validate_reactor_structure(panel_pos)
	local center = find_pole_corrector(panel_pos)
	if not center then
		return false, {"No pole corrector detected nearby."}
	end

	local errors = {}

	-- Check each defined structure position
	for _, entry in ipairs(STRUCTURE) do
		local wp = {
			x = center.x + entry.x,
			y = center.y + entry.y,
			z = center.z + entry.z,
		}
		local node = minetest.get_node(wp)
		local expected = entry.node

		-- For plasma field positions, accept both straight and corner variants
		if expected == PLF or expected == PLC then
			if node.name ~= PLF and node.name ~= PLC then
				errors[#errors+1] = string.format(
					"Offset (%d,%d,%d): expected plasma field, found %s",
					entry.x, entry.y, entry.z, node.name)
			end
		elseif node.name ~= expected then
			errors[#errors+1] = string.format(
				"Offset (%d,%d,%d): expected %s, found %s",
				entry.x, entry.y, entry.z, expected, node.name)
		end

		if #errors >= 10 then break end
	end

	-- Check that control panel exists touching a toroid field
	local panel_ok = has_neighbor(panel_pos, TF)
	if not panel_ok then
		errors[#errors+1] = "Control panel is not touching a toroid field block."
	end

	-- Check for jumpstarter touching control panel
	local has_js = has_neighbor(panel_pos, "lazarus_space:plasma_jumpstarter")
	if not has_js then
		errors[#errors+1] = "No plasma jumpstarter found touching the control panel."
	end

	-- Check for power output touching control panel
	local has_po = has_neighbor(panel_pos, "lazarus_space:fusion_power_output")
	if not has_po then
		errors[#errors+1] = "No fusion power output found touching the control panel."
	end

	if #errors > 0 then
		return false, errors
	end

	return true, center
end

-- ============================================================
-- FORMSPEC BUILDERS
-- ============================================================

-- Helper: render a button with a thin border outline (no filled backdrop)
local function btn(fs, x, y, w, h, name, label, color)
	local t = 0.05
	-- Top edge
	fs = fs .. "box[" .. (x-t) .. "," .. (y-t) .. ";" .. (w+t*2) .. "," .. t .. ";" .. color .. "]"
	-- Bottom edge
	fs = fs .. "box[" .. (x-t) .. "," .. (y+h) .. ";" .. (w+t*2) .. "," .. t .. ";" .. color .. "]"
	-- Left edge
	fs = fs .. "box[" .. (x-t) .. "," .. (y-t) .. ";" .. t .. "," .. (h+t*2) .. ";" .. color .. "]"
	-- Right edge
	fs = fs .. "box[" .. (x+w) .. "," .. (y-t) .. ";" .. t .. "," .. (h+t*2) .. ";" .. color .. "]"
	fs = fs .. "button[" .. x .. "," .. y .. ";" .. w .. "," .. h .. ";" .. name .. ";" .. label .. "]"
	return fs
end

-- Helper: render a gradient progress bar (3-strip: bright top, base middle, dark bottom)
-- Strips overlap by 0.02 units to prevent black lines from floating point gaps.
local function gradient_bar(fs, x, y, w, h, fill_pct)
	-- Background
	fs = fs .. "box[" .. x .. "," .. y .. ";" .. w .. "," .. h .. ";#1a1a1a]"
	if fill_pct > 0 then
		local fw = w * fill_pct / 100
		local fws = string.format("%.1f", fw)
		local strip_h = h / 3
		local overlap = 0.02
		local sh = string.format("%.2f", strip_h + overlap)
		local sh_last = string.format("%.2f", strip_h)
		-- Top strip: bright (extends 0.02 into middle strip)
		fs = fs .. "box[" .. x .. "," .. y .. ";" .. fws .. "," .. sh .. ";#00eebb]"
		-- Middle strip: base (extends 0.02 into bottom strip)
		fs = fs .. "box[" .. x .. "," .. string.format("%.2f", y + strip_h)
			.. ";" .. fws .. "," .. sh .. ";#00ccaa]"
		-- Bottom strip: dark (no overlap needed — sits at bottom)
		fs = fs .. "box[" .. x .. "," .. string.format("%.2f", y + strip_h * 2)
			.. ";" .. fws .. "," .. sh_last .. ";#009988]"
	end
	return fs
end

local function build_unchecked_formspec()
	local fs = "size[9,4]"
		.. "bgcolor[#080808;true]"
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[2.5,0.2;Magnetic Fusion Reactor]"
		.. "box[0,1;8.8,0.6;#0a0a15]"
		.. "label[2.5,1.1;Structure Check Required]"
	fs = btn(fs, 2.5, 2.2, 4, 0.7, "check_structure", "Check Structure", "#00ccaa")
	return fs
end

local function build_error_formspec(errors)
	local fs = "size[9,7]"
		.. "bgcolor[#080808;true]"
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[2.5,0.2;Magnetic Fusion Reactor]"
		.. "box[0,1;8.8,0.6;#0a0a15]"
		.. "label[0.3,1.1;" .. minetest.colorize("#ff3333", "Structure Check Failed") .. "]"

	local y = 2.0
	for i, err in ipairs(errors) do
		if i > 6 then break end
		fs = fs .. "label[0.5," .. y .. ";" .. minetest.colorize("#ff8888",
			"- " .. minetest.formspec_escape(err)) .. "]"
		y = y + 0.5
	end

	fs = btn(fs, 2.5, y + 0.3, 4, 0.7, "check_structure", "Retry Check", "#00ccaa")
	return fs
end

local function build_reactor_formspec(pos)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("reactor_state")
	if state == "" then state = "standby" end
	local charge_timer = meta:get_int("charge_timer")
	local fuel_time = meta:get_int("fuel_time")
	-- Count fuel rods
	local inv = meta:get_inventory()
	local fuel_count = 0
	for i = 1, FUEL_SLOTS do
		local stack = inv:get_stack("fuel", i)
		if stack:get_name() == FUEL_ITEM then
			fuel_count = fuel_count + stack:get_count()
		end
	end

	-- Check jumpstarter power
	local js_pos = find_neighbor(pos, "lazarus_space:plasma_jumpstarter")
	local hv_ready = false
	if js_pos then
		local js_meta = minetest.get_meta(js_pos)
		local stored = js_meta:get_int("stored_energy")
		if stored >= JUMPSTART_ENERGY then
			hv_ready = true
		end
	end

	-- Status text with color
	local status_text
	if state == "standby" then
		status_text = minetest.colorize("#ffcc00", "STANDBY")
	elseif state == "jump_starting" then
		status_text = minetest.colorize("#ff8800", "JUMP STARTING")
	elseif state == "jump_started" then
		status_text = minetest.colorize("#00ccff", "JUMP START COMPLETE")
	elseif state == "active" then
		status_text = minetest.colorize("#00ff66", "ACTIVE")
	elseif state == "shutdown" then
		status_text = minetest.colorize("#ff3333", "SHUTDOWN")
	else
		status_text = state
	end

	-- Jump start progress
	local js_progress = 0
	if state == "jump_starting" then
		js_progress = math.floor((CHARGE_TIME - charge_timer) / CHARGE_TIME * 100)
	elseif state == "jump_started" or state == "active" then
		js_progress = 100
	end

	local fs = "size[9,10.5]"
		.. "bgcolor[#080808;true]"
		.. "listcolors[#1a1a2e;#2a2a3e;#333355]"
		-- Header
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[2.5,0.2;Magnetic Fusion Reactor]"
		-- Status
		.. "box[0,1;8.8,0.6;#0a0a15]"
		.. "label[0.3,1.1;Status: " .. status_text .. "]"
	-- Progress bar with gradient
	fs = gradient_bar(fs, 0.5, 1.8, 7.8, 0.5, js_progress)
	fs = fs .. "label[8.5,1.9;" .. js_progress .. "%]"

	-- Fuel section
	fs = fs .. "box[0,2.5;8.8,1.8;#0d0d1a]"
		.. "label[0.3,2.6;Fuel Rods (" .. fuel_count .. "/" .. FUEL_SLOTS .. ")]"
		.. "list[context;fuel;1.5,3;6,1;]"

	-- Power section
	fs = fs .. "box[0,4.5;8.8,1.2;#0d0d1a]"
	if hv_ready then
		fs = fs .. "label[0.3,4.6;HV Power: " .. minetest.colorize("#00ff66", "READY") .. "]"
	else
		fs = fs .. "label[0.3,4.6;HV Power: " .. minetest.colorize("#ff3333", "INSUFFICIENT") .. "]"
	end

	if state == "active" then
		local mins = math.floor(fuel_time / 60)
		local secs = fuel_time % 60
		-- Get output tier from power output block
		local output_tier = "HV"
		local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
		if po_pos then
			local po_meta = minetest.get_meta(po_pos)
			local t = po_meta:get_string("output_tier")
			if t ~= "" then output_tier = t end
		end
		fs = fs .. "label[0.3,5.1;Output: " .. minetest.colorize("#00ccaa", "140,000 EU")
			.. " (" .. output_tier .. ")]"
		-- Fuel remaining with gradient drain bar
		fs = fs .. "label[0.3,5.8;Fuel Remaining: " .. string.format("%d:%02d", mins, secs) .. "]"
		local fuel_pct = math.floor(fuel_time / FUEL_DURATION * 100)
		fs = gradient_bar(fs, 0.5, 6.3, 7.8, 0.4, fuel_pct)
	end

	-- Control buttons
	if state == "standby" then
		if hv_ready then
			fs = btn(fs, 2.5, 5.8, 4, 0.7, "jump_start", "Jump Start", "#00ccaa")
		else
			fs = fs .. "label[2.8,5.9;" .. minetest.colorize("#666666", "Jump Start (HV not ready)") .. "]"
		end
	elseif state == "jump_starting" then
		fs = fs .. "label[2.8,5.9;" .. minetest.colorize("#ff8800",
			"Jump Starting... " .. charge_timer .. "s") .. "]"
	elseif state == "jump_started" then
		if fuel_count >= FUEL_SLOTS then
			fs = btn(fs, 1.5, 5.8, 6, 0.7, "inject", "Inject Fuel & Start", "#00ff66")
		else
			fs = fs .. "label[1.5,5.9;" .. minetest.colorize("#666666",
				"Inject Fuel & Start (need " .. (FUEL_SLOTS - fuel_count) .. " more rods)") .. "]"
		end
	end

	-- Player inventory
	fs = fs .. "list[current_player;main;0.5,7;8,1;]"
		.. "list[current_player;main;0.5,8.2;8,3;8]"
		.. "listring[context;fuel]"
		.. "listring[current_player;main]"

	return fs
end

-- ============================================================
-- CONTROL PANEL: on_receive_fields
-- ============================================================

local function panel_on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)

	if fields.check_structure then
		local ok, result = lazarus_space.validate_reactor_structure(pos)
		if ok then
			meta:set_string("reactor_state", "standby")
			meta:set_string("validated", "true")
			meta:set_string("center_x", tostring(result.x))
			meta:set_string("center_y", tostring(result.y))
			meta:set_string("center_z", tostring(result.z))
			-- Start integrity check timer
			local timer = minetest.get_node_timer(pos)
			timer:start(1)
			meta:set_string("formspec", build_reactor_formspec(pos))
		else
			meta:set_string("formspec", build_error_formspec(result))
		end
		return
	end

	if fields.jump_start then
		local state = meta:get_string("reactor_state")
		if state ~= "standby" then return end

		-- Verify HV power (fuel not required for jump start)
		local js_pos = find_neighbor(pos, "lazarus_space:plasma_jumpstarter")
		if not js_pos then return end
		local js_meta = minetest.get_meta(js_pos)
		if js_meta:get_int("stored_energy") < JUMPSTART_ENERGY then return end

		-- Start jump start sequence
		meta:set_string("reactor_state", "jump_starting")
		meta:set_int("charge_timer", CHARGE_TIME)

		-- Drain jumpstarter energy
		local stored = js_meta:get_int("stored_energy")
		js_meta:set_int("stored_energy", math.max(0, stored - JUMPSTART_ENERGY))

		-- Timer is already running from validation
		meta:set_string("formspec", build_reactor_formspec(pos))
		return
	end

	if fields.inject then
		local state = meta:get_string("reactor_state")
		if state ~= "jump_started" then return end

		-- Verify all fuel rods are loaded
		local inv = meta:get_inventory()
		local fuel_count = 0
		for i = 1, FUEL_SLOTS do
			local stack = inv:get_stack("fuel", i)
			if stack:get_name() == FUEL_ITEM then
				fuel_count = fuel_count + stack:get_count()
			end
		end
		if fuel_count < FUEL_SLOTS then return end

		-- Consume fuel rods
		for i = 1, FUEL_SLOTS do
			inv:set_stack("fuel", i, "")
		end

		-- Activate reactor
		meta:set_string("reactor_state", "active")
		meta:set_int("fuel_time", FUEL_DURATION)

		-- Notify power output — update infotext immediately
		local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
		if po_pos then
			local po_meta = minetest.get_meta(po_pos)
			local tier = po_meta:get_string("output_tier")
			if tier == "" then tier = "HV" end
			po_meta:set_string("infotext", "Fusion Power Output - "
				.. POWER_OUTPUT .. " EU (" .. tier .. ")")
		end

		meta:set_string("formspec", build_reactor_formspec(pos))
		return
	end

	if fields.quit then return end
end

-- ============================================================
-- CONTROL PANEL: node timer
-- ============================================================

local function panel_on_timer(pos, elapsed)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("reactor_state")

	-- Periodic structure integrity check
	if meta:get_string("validated") == "true" then
		local check_acc = meta:get_float("check_accumulator") + elapsed
		if check_acc >= STRUCTURE_CHECK_INTERVAL then
			check_acc = 0
			local ok = lazarus_space.validate_reactor_structure(pos)
			if not ok then
				-- Structure broken — invalidate
				meta:set_string("validated", "")
				meta:set_string("reactor_state", "")
				meta:set_int("charge_timer", 0)

				-- Shut down power output — update infotext
				local po_pos = find_neighbor(pos,
					"lazarus_space:fusion_power_output")
				if po_pos then
					local po_meta = minetest.get_meta(po_pos)
					po_meta:set_string("infotext", "Fusion Power Output - Offline")
				end
				meta:set_string("formspec", build_unchecked_formspec())
				return false -- stop timer
			end
		end
		meta:set_float("check_accumulator", check_acc)
	end

	-- Jump start countdown (fuel not required during jump start)
	if state == "jump_starting" then
		local ct = meta:get_int("charge_timer") - 1

		if ct <= 0 then
			meta:set_string("reactor_state", "jump_started")
			meta:set_int("charge_timer", 0)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Jump Start Complete")
		else
			meta:set_int("charge_timer", ct)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Jump Starting... " .. ct .. "s")
		end
		meta:set_string("formspec", build_reactor_formspec(pos))
		return true
	end

	-- Active reactor: decrement fuel time
	if state == "active" then
		local ft = meta:get_int("fuel_time") - 1
		if ft <= 0 then
			-- Fuel depleted — shutdown
			meta:set_string("reactor_state", "standby")
			meta:set_int("fuel_time", 0)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Standby")

			-- Notify power output — update infotext
			local po_pos = find_neighbor(pos,
				"lazarus_space:fusion_power_output")
			if po_pos then
				local po_meta = minetest.get_meta(po_pos)
				po_meta:set_string("infotext", "Fusion Power Output - Offline")
			end
		else
			meta:set_int("fuel_time", ft)
			local mins = math.floor(ft / 60)
			local secs = ft % 60
			meta:set_string("infotext", "Magnetic Fusion Reactor — Active ("
				.. string.format("%d:%02d", mins, secs) .. ")")
		end
		meta:set_string("formspec", build_reactor_formspec(pos))
		return true
	end

	-- Standby or jump_started: refresh formspec for live HV status polling
	if meta:get_string("validated") == "true" then
		meta:set_string("formspec", build_reactor_formspec(pos))
		return true
	end

	return false
end

-- ============================================================
-- NODE REGISTRATIONS
-- ============================================================

-- ---- Pole Field ----
minetest.register_node("lazarus_space:pole_field", {
	description = "Pole Field",
	tiles = {"lazarus_space_pole_field.png"},
	groups = {cracky = 2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

-- ---- Toroid Field ----
minetest.register_node("lazarus_space:toroid_field", {
	description = "Toroid Field",
	drawtype = "glasslike",
	tiles = {"lazarus_space_toroid_field.png"},
	paramtype = "light",
	use_texture_alpha = "blend",
	groups = {cracky = 2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),
})

-- ---- Plasma Field (straight) ----
local plasma_box = {
	type = "fixed",
	fixed = {-0.5, -0.3, -0.3, 0.5, 0.3, 0.3},
}

minetest.register_node("lazarus_space:plasma_field", {
	description = "Plasma Field",
	drawtype = "nodebox",
	tiles = {"lazarus_space_plasma_field.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = plasma_box,
	selection_box = plasma_box,
	groups = {cracky = 2},
	is_ground_content = false,
	light_source = 5,
	sounds = default.node_sound_metal_defaults(),

	after_place_node = function(pos, placer, itemstack, pointed_thing)
		-- Auto-corner logic: if the newly placed piece has two perpendicular
		-- plasma field neighbors, convert it to a corner piece.
		local PF = "lazarus_space:plasma_field"
		local PFC = "lazarus_space:plasma_field_corner"
		local horiz = {
			{x=1,y=0,z=0}, {x=-1,y=0,z=0},
			{x=0,y=0,z=1}, {x=0,y=0,z=-1},
		}

		-- Collect which directions have plasma field neighbors
		local has_x_pos, has_x_neg, has_z_pos, has_z_neg = false, false, false, false
		for _, d in ipairs(horiz) do
			local npos = vector.add(pos, d)
			local nn = minetest.get_node(npos).name
			if nn == PF or nn == PFC then
				if d.x == 1 then has_x_pos = true
				elseif d.x == -1 then has_x_neg = true
				elseif d.z == 1 then has_z_pos = true
				elseif d.z == -1 then has_z_neg = true
				end
			end
		end

		-- Need at least one X-axis and one Z-axis neighbor for a corner
		local has_x = has_x_pos or has_x_neg
		local has_z = has_z_pos or has_z_neg
		if has_x and has_z then
			-- Pick the first X and Z neighbor to determine corner orientation
			-- Corner nodebox arms: one arm along -X, other along +Z (at facedir 0)
			-- facedir rotations: 0=arms(-X,+Z), 1=arms(-Z,-X), 2=arms(+X,-Z), 3=arms(+Z,+X)
			local corner_param2 = 0
			if has_x_neg and has_z_pos then corner_param2 = 0      -- -X, +Z
			elseif has_x_neg and has_z_neg then corner_param2 = 1  -- -X, -Z
			elseif has_x_pos and has_z_neg then corner_param2 = 2  -- +X, -Z
			elseif has_x_pos and has_z_pos then corner_param2 = 3  -- +X, +Z
			end

			minetest.set_node(pos, {
				name = PFC,
				param2 = corner_param2,
			})
		end
	end,
})

-- ---- Plasma Field Corner ----
local corner_box = {
	type = "fixed",
	fixed = {
		{-0.5, -0.3, -0.3, 0.3, 0.3, 0.3}, -- one arm
		{-0.3, -0.3, -0.3, 0.3, 0.3, 0.5}, -- other arm
	},
}

minetest.register_node("lazarus_space:plasma_field_corner", {
	description = "Plasma Field Corner",
	drawtype = "nodebox",
	tiles = {"lazarus_space_plasma_field.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = corner_box,
	selection_box = corner_box,
	groups = {cracky = 2, not_in_creative_inventory = 1},
	is_ground_content = false,
	light_source = 5,
	drop = "lazarus_space:plasma_field",
	sounds = default.node_sound_metal_defaults(),
})

-- ---- Pole Corrector ----
minetest.register_node("lazarus_space:pole_corrector", {
	description = "Pole Corrector",
	tiles = {"lazarus_space_pole_corrector.png"},
	groups = {cracky = 2},
	is_ground_content = false,
	light_source = 4,
	sounds = default.node_sound_metal_defaults(),
})

-- ---- Fusion Control Panel ----
minetest.register_node("lazarus_space:fusion_control_panel", {
	description = "Fusion Control Panel",
	tiles = {"lazarus_space_fusion_control_panel.png"},
	paramtype2 = "facedir",
	groups = {cracky = 2},
	is_ground_content = false,
	sounds = default.node_sound_metal_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("fuel", FUEL_SLOTS)
		meta:set_string("reactor_state", "")
		meta:set_string("validated", "")
		meta:set_string("infotext", "Magnetic Fusion Reactor — Not Validated")
		meta:set_string("formspec", build_unchecked_formspec())
	end,

	after_place_node = function(pos, placer)
		if not has_neighbor(pos, TF) then
			minetest.remove_node(pos)
			if placer and placer:is_player() then
				local inv = placer:get_inventory()
				inv:add_item("main", "lazarus_space:fusion_control_panel")
				minetest.chat_send_player(placer:get_player_name(),
					"Control panel must be placed touching a toroid field block.")
			end
			return
		end
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		panel_on_receive_fields(pos, formname, fields, sender)
	end,

	on_timer = function(pos, elapsed)
		return panel_on_timer(pos, elapsed)
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack)
		if listname == "fuel" and stack:get_name() == FUEL_ITEM then
			return stack:get_count()
		end
		return 0
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index,
			to_list, to_index, count)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack)
		return stack:get_count()
	end,

	on_metadata_inventory_put = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", build_reactor_formspec(pos))
	end,

	on_metadata_inventory_take = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", build_reactor_formspec(pos))
	end,
})

-- ---- Plasma Jumpstarter ----
minetest.register_node("lazarus_space:plasma_jumpstarter", {
	description = "Plasma Jumpstarter",
	tiles = {"lazarus_space_plasma_jumpstarter.png"},
	paramtype2 = "facedir",
	groups = {
		cracky = 2,
		technic_machine = 1,
		technic_hv = 1,
	},
	is_ground_content = false,
	connect_sides = {"top", "bottom", "front", "back", "left", "right"},
	sounds = default.node_sound_metal_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
		meta:set_int("stored_energy", 0)
		meta:set_string("infotext", "Plasma Jumpstarter")
	end,

	after_place_node = function(pos, placer)
		if not has_neighbor(pos, "lazarus_space:fusion_control_panel") then
			minetest.remove_node(pos)
			if placer and placer:is_player() then
				local inv = placer:get_inventory()
				inv:add_item("main", "lazarus_space:plasma_jumpstarter")
				minetest.chat_send_player(placer:get_player_name(),
					"Jumpstarter must be placed touching the control panel.")
			end
			return
		end
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local stored = meta:get_int("stored_energy")

		if stored < JUMPSTART_ENERGY then
			-- Demand power to charge up
			meta:set_int("HV_EU_demand", 10000)
			local input = meta:get_int("HV_EU_input")
			stored = math.min(JUMPSTART_ENERGY, stored + input)
			meta:set_int("stored_energy", stored)
		else
			meta:set_int("HV_EU_demand", 0)
		end

		local pct = math.floor(stored / JUMPSTART_ENERGY * 100)
		meta:set_string("infotext", "Plasma Jumpstarter — " .. pct .. "% charged")
	end,

	technic_on_disable = function(pos, node)
		local meta = minetest.get_meta(pos)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("HV_EU_input", 0)
	end,
})

technic.register_machine("HV", "lazarus_space:plasma_jumpstarter", technic.receiver)

-- ---- Fusion Power Output ----
minetest.register_node("lazarus_space:fusion_power_output", {
	description = "Fusion Power Output",
	tiles = {"lazarus_space_fusion_power_output.png"},
	paramtype2 = "facedir",
	groups = {
		cracky = 2,
		technic_machine = 1,
		technic_hv = 1,
		technic_mv = 1,
		technic_lv = 1,
	},
	is_ground_content = false,
	connect_sides = {"top", "bottom", "front", "back", "left", "right"},
	sounds = default.node_sound_metal_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("output_tier", "HV")
		meta:set_int("LV_EU_supply", 0)
		meta:set_int("MV_EU_supply", 0)
		meta:set_int("HV_EU_supply", 0)
		meta:set_string("infotext", "Fusion Power Output - Offline")
	end,

	after_place_node = function(pos, placer)
		if not has_neighbor(pos, "lazarus_space:fusion_control_panel") then
			minetest.remove_node(pos)
			if placer and placer:is_player() then
				local inv = placer:get_inventory()
				inv:add_item("main", "lazarus_space:fusion_power_output")
				minetest.chat_send_player(placer:get_player_name(),
					"Power output must be placed touching the control panel.")
			end
			return
		end
	end,

	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		local tier = meta:get_string("output_tier")
		if tier == "" then tier = "HV" end

		-- Check reactor state from neighboring control panel
		local panel_pos = find_neighbor(pos, "lazarus_space:fusion_control_panel")
		local active = false
		if panel_pos then
			local panel_meta = minetest.get_meta(panel_pos)
			active = panel_meta:get_string("reactor_state") == "active"
		end

		-- Build polished formspec
		local fs = "size[6,4.5]"
			.. "bgcolor[#080808;true]"
			-- Header
			.. "box[0,0;5.8,0.8;#1a1a2e]"
			.. "label[1.5,0.2;Fusion Power Output]"
			-- Status
			.. "box[0,1;5.8,0.6;#0a0a15]"

		if active then
			fs = fs .. "label[0.3,1.1;" .. minetest.colorize("#00ff66", "ONLINE")
				.. "  140,000 EU]"
		else
			fs = fs .. "label[0.3,1.1;" .. minetest.colorize("#ff3333", "OFFLINE")
				.. "  0 EU]"
		end

		-- Tier selection
		fs = fs .. "box[0,1.8;5.8,1.5;#0d0d1a]"
			.. "label[0.3,1.9;Output Tier]"

		local tiers = {{"LV", 0.3}, {"MV", 2.1}, {"HV", 3.9}}
		for _, t in ipairs(tiers) do
			local name, x = t[1], t[2]
			local color = tier == name and "#00ccaa" or "#1a1a2e"
			fs = btn(fs, x, 2.4, 1.5, 0.7, "set_" .. name:lower(), name, color)
		end

		-- Output info
		fs = fs .. "box[0,3.5;5.8,0.8;#0d0d1a]"
		if active then
			fs = fs .. "label[0.3,3.7;Supplying: " .. minetest.colorize("#00ccaa", "140,000 EU")
				.. " on " .. tier .. "]"
		else
			fs = fs .. "label[0.3,3.7;" .. minetest.colorize("#666666",
				"No output - Reactor offline") .. "]"
		end

		minetest.show_formspec(clicker:get_player_name(),
			"lazarus_space:power_output_" .. minetest.pos_to_string(pos), fs)
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local tier = meta:get_string("output_tier")
		if tier == "" then tier = "HV" end

		-- Check reactor state from neighboring control panel
		local panel_pos = find_neighbor(pos, "lazarus_space:fusion_control_panel")
		local active = false
		if panel_pos then
			local panel_meta = minetest.get_meta(panel_pos)
			active = panel_meta:get_string("reactor_state") == "active"
		end

		if active then
			meta:set_int("HV_EU_supply", tier == "HV" and POWER_OUTPUT or 0)
			meta:set_int("MV_EU_supply", tier == "MV" and POWER_OUTPUT or 0)
			meta:set_int("LV_EU_supply", tier == "LV" and POWER_OUTPUT or 0)
			meta:set_string("infotext", "Fusion Power Output - "
				.. POWER_OUTPUT .. " EU (" .. tier .. ")")
		else
			meta:set_int("HV_EU_supply", 0)
			meta:set_int("MV_EU_supply", 0)
			meta:set_int("LV_EU_supply", 0)
			meta:set_string("infotext", "Fusion Power Output - Offline")
		end
	end,
})

-- Register power output as producer on all three tiers
technic.register_machine("HV", "lazarus_space:fusion_power_output", technic.producer)
technic.register_machine("MV", "lazarus_space:fusion_power_output", technic.producer)
technic.register_machine("LV", "lazarus_space:fusion_power_output", technic.producer)

-- Power output tier selection handler
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:find("^lazarus_space:power_output_") then return false end
	local pos_str = formname:sub(#"lazarus_space:power_output_" + 1)
	local pos = minetest.string_to_pos(pos_str)
	if not pos then return false end
	local node = minetest.get_node(pos)
	if node.name ~= "lazarus_space:fusion_power_output" then return false end

	local meta = minetest.get_meta(pos)
	local changed = false
	if fields.set_lv then
		meta:set_string("output_tier", "LV")
		changed = true
	elseif fields.set_mv then
		meta:set_string("output_tier", "MV")
		changed = true
	elseif fields.set_hv then
		meta:set_string("output_tier", "HV")
		changed = true
	end

	if changed then
		-- Reopen the formspec to show the update
		local def = minetest.registered_nodes[node.name]
		if def and def.on_rightclick then
			def.on_rightclick(pos, node, player)
		end
	end

	return true
end)

-- ============================================================
-- CRAFTING RECIPES
-- ============================================================

-- Pole Field (cheap — needed in bulk)
minetest.register_craft({
	output = "lazarus_space:pole_field 4",
	recipe = {
		{"technic:stainless_steel_ingot", "technic:stainless_steel_ingot", ""},
		{"technic:stainless_steel_ingot", "technic:stainless_steel_ingot", ""},
		{"", "", ""},
	},
})

-- Toroid Field (moderate — energy containment)
minetest.register_craft({
	output = "lazarus_space:toroid_field 2",
	recipe = {
		{"default:glass", "default:mese_crystal", "default:glass"},
		{"default:mese_crystal", "technic:stainless_steel_ingot", "default:mese_crystal"},
		{"default:glass", "default:mese_crystal", "default:glass"},
	},
})

-- Plasma Field (moderate — conductor/plasma)
minetest.register_craft({
	output = "lazarus_space:plasma_field 4",
	recipe = {
		{"default:copper_ingot", "default:mese_crystal", "default:copper_ingot"},
		{"technic:stainless_steel_ingot", "default:copper_ingot", "technic:stainless_steel_ingot"},
		{"default:copper_ingot", "default:mese_crystal", "default:copper_ingot"},
	},
})

-- Pole Corrector (expensive — one per reactor)
minetest.register_craft({
	output = "lazarus_space:pole_corrector",
	recipe = {
		{"technic:stainless_steel_ingot", "default:diamond", "technic:stainless_steel_ingot"},
		{"default:diamond", "default:mese_block", "default:diamond"},
		{"technic:stainless_steel_ingot", "default:diamond", "technic:stainless_steel_ingot"},
	},
})

-- Fusion Control Panel (expensive — one per reactor)
minetest.register_craft({
	output = "lazarus_space:fusion_control_panel",
	recipe = {
		{"technic:stainless_steel_ingot", "default:mese_crystal", "technic:stainless_steel_ingot"},
		{"technic:hv_cable", "default:mese_block", "technic:hv_cable"},
		{"technic:stainless_steel_ingot", "technic:hv_transformer", "technic:stainless_steel_ingot"},
	},
})

-- Plasma Jumpstarter (expensive — one per reactor)
minetest.register_craft({
	output = "lazarus_space:plasma_jumpstarter",
	recipe = {
		{"default:copper_ingot", "technic:hv_transformer", "default:copper_ingot"},
		{"technic:hv_cable", "technic:stainless_steel_ingot", "technic:hv_cable"},
		{"default:copper_ingot", "technic:stainless_steel_ingot", "default:copper_ingot"},
	},
})

-- Fusion Power Output (expensive — one per reactor)
minetest.register_craft({
	output = "lazarus_space:fusion_power_output",
	recipe = {
		{"technic:hv_cable", "technic:stainless_steel_ingot", "technic:hv_cable"},
		{"default:copper_ingot", "technic:hv_transformer", "default:copper_ingot"},
		{"technic:hv_cable", "technic:stainless_steel_ingot", "technic:hv_cable"},
	},
})
