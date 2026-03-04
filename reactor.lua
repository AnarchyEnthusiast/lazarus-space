-- Lazarus Space: Magnetic Fusion Reactor
-- 11x11x5 multiblock structure with charge sequence and power output.

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
-- Offsets relative to the pole_corrector at (0,0,0).
-- The structure is a cross/plus shape, 11x11x5.
-- Floor at y=-2, Roof at y=+2, middle layers y=-1,0,+1.

local STRUCTURE = {}

-- Helper to add an entry
local function S(dx, dy, dz, node)
	STRUCTURE[#STRUCTURE+1] = {x=dx, y=dy, z=dz, node=node}
end

-- Shorthand node names
local PF = "lazarus_space:pole_field"
local TF = "lazarus_space:toroid_field"
local SB = "default:steelblock"
local PC = "lazarus_space:pole_corrector"
local AIR = "air"

-- ---- FLOOR (y = -2): pole_field platform ----
-- The floor is a cross shape matching the overall footprint.
-- Center 3x3
for dx = -1, 1 do
	for dz = -1, 1 do
		S(dx, -2, dz, PF)
	end
end
-- Four arms extending from center, each arm is 3 wide and extends 4 blocks
-- North arm (z positive): z=2..5, x=-1..1
for dz = 2, 5 do
	for dx = -1, 1 do
		S(dx, -2, dz, PF)
	end
end
-- South arm (z negative): z=-5..-2, x=-1..1
for dz = -5, -2 do
	for dx = -1, 1 do
		S(dx, -2, dz, PF)
	end
end
-- East arm (x positive): x=2..5, z=-1..1
for dx = 2, 5 do
	for dz = -1, 1 do
		S(dx, -2, dz, PF)
	end
end
-- West arm (x negative): x=-5..-2, z=-1..1
for dx = -5, -2 do
	for dz = -1, 1 do
		S(dx, -2, dz, PF)
	end
end

-- ---- ROOF (y = +2): same pattern as floor ----
for dx = -1, 1 do
	for dz = -1, 1 do
		S(dx, 2, dz, PF)
	end
end
for dz = 2, 5 do
	for dx = -1, 1 do
		S(dx, 2, dz, PF)
	end
end
for dz = -5, -2 do
	for dx = -1, 1 do
		S(dx, 2, dz, PF)
	end
end
for dx = 2, 5 do
	for dz = -1, 1 do
		S(dx, 2, dz, PF)
	end
end
for dx = -5, -2 do
	for dz = -1, 1 do
		S(dx, 2, dz, PF)
	end
end

-- ---- MIDDLE LAYERS (y = -1, 0, +1) ----

-- Center 3x3 pole field column (all 3 middle layers)
-- except (0,0,0) which is the pole corrector
-- and (0,-1,0) and (0,+1,0) which are air
for dy = -1, 1 do
	for dx = -1, 1 do
		for dz = -1, 1 do
			if dx == 0 and dz == 0 then
				if dy == 0 then
					S(0, 0, 0, PC)
				else
					S(0, dy, 0, AIR)
				end
			else
				S(dx, dy, dz, PF)
			end
		end
	end
end

-- Steel blocks at arm-to-center transitions (y=-1,0,+1)
-- These are at the positions where arms meet the 3x3 center
-- North: (0, y, 2) is transition — but looking at screenshots,
-- steel blocks are at the inner edge of arms, bridging center to arm
-- Based on screenshots: steelblocks at x=+-2,z=0 and x=0,z=+-2
-- at the boundary between center 3x3 and arm start
for dy = -1, 1 do
	-- North transition
	S(0, dy, 2, SB)
	-- South transition
	S(0, dy, -2, SB)
	-- East transition
	S(2, dy, 0, SB)
	-- West transition
	S(-2, dy, 0, SB)
end

-- Arm walls: toroid field blocks form the outer walls of each arm
-- Each arm is 3 wide. The walls are the outer two rows (edges).
-- The interior of each arm is air.

for dy = -1, 1 do
	-- North arm: z=2..5, walls at x=-1 and x=1, interior at x=0
	for dz = 2, 5 do
		S(-1, dy, dz, TF)
		S(1, dy, dz, TF)
		-- Interior air (except z=2 which has steelblock at x=0)
		if dz > 2 then
			S(0, dy, dz, AIR)
		end
	end
	-- South arm: z=-5..-2
	for dz = -5, -2 do
		S(-1, dy, dz, TF)
		S(1, dy, dz, TF)
		if dz < -2 then
			S(0, dy, dz, AIR)
		end
	end
	-- East arm: x=2..5
	for dx = 2, 5 do
		S(dx, dy, -1, TF)
		S(dx, dy, 1, TF)
		if dx > 2 then
			S(dx, dy, 0, AIR)
		end
	end
	-- West arm: x=-5..-2
	for dx = -5, -2 do
		S(dx, dy, -1, TF)
		S(dx, dy, 1, TF)
		if dx < -2 then
			S(dx, dy, 0, AIR)
		end
	end
end

-- Plasma field ring connecting arm tips at the outer perimeter
-- This runs around the outside connecting the 4 arm ends.
-- Arm tips are at z=5 (north), z=-5 (south), x=5 (east), x=-5 (west)
-- The plasma field connects them at y=-1,0,+1 around the perimeter
-- Based on screenshots, plasma field is at the arm tips and corners

for dy = -1, 1 do
	-- North arm tip cap: z=5, x=-1,0,1 — already have TF walls at x=-1,1
	-- Plasma field at the end cap
	S(0, dy, 5, "lazarus_space:plasma_field")

	-- South arm tip cap
	S(0, dy, -5, "lazarus_space:plasma_field")

	-- East arm tip cap
	S(5, dy, 0, "lazarus_space:plasma_field")

	-- West arm tip cap
	S(-5, dy, 0, "lazarus_space:plasma_field")

	-- Corner connections between arm tips
	-- NE corner path: from (1,y,5) to (5,y,1)
	-- Plasma runs along the diagonal corners
	-- Based on screenshots: plasma at corners connecting arms
	-- NE: (2,y,5), (3,y,5), (4,y,5), (5,y,5), (5,y,4), (5,y,3), (5,y,2), (5,y,1)
	-- But that's outside the cross. Looking at screenshots more carefully,
	-- the plasma ring runs at the tips: straight sections along the arm ends
	-- and corners where perpendicular arms meet.
	-- Let me place plasma along outer edge of arm tips:

	-- North-East corner: connects north arm (z=5) east edge to east arm (x=5) north edge
	S(2, dy, 5, "lazarus_space:plasma_field")
	S(3, dy, 5, "lazarus_space:plasma_field")
	S(4, dy, 5, "lazarus_space:plasma_field")
	S(5, dy, 5, "lazarus_space:plasma_field") -- corner
	S(5, dy, 4, "lazarus_space:plasma_field")
	S(5, dy, 3, "lazarus_space:plasma_field")
	S(5, dy, 2, "lazarus_space:plasma_field")

	-- South-East corner
	S(2, dy, -5, "lazarus_space:plasma_field")
	S(3, dy, -5, "lazarus_space:plasma_field")
	S(4, dy, -5, "lazarus_space:plasma_field")
	S(5, dy, -5, "lazarus_space:plasma_field") -- corner
	S(5, dy, -4, "lazarus_space:plasma_field")
	S(5, dy, -3, "lazarus_space:plasma_field")
	S(5, dy, -2, "lazarus_space:plasma_field")

	-- North-West corner
	S(-2, dy, 5, "lazarus_space:plasma_field")
	S(-3, dy, 5, "lazarus_space:plasma_field")
	S(-4, dy, 5, "lazarus_space:plasma_field")
	S(-5, dy, 5, "lazarus_space:plasma_field") -- corner
	S(-5, dy, 4, "lazarus_space:plasma_field")
	S(-5, dy, 3, "lazarus_space:plasma_field")
	S(-5, dy, 2, "lazarus_space:plasma_field")

	-- South-West corner
	S(-2, dy, -5, "lazarus_space:plasma_field")
	S(-3, dy, -5, "lazarus_space:plasma_field")
	S(-4, dy, -5, "lazarus_space:plasma_field")
	S(-5, dy, -5, "lazarus_space:plasma_field") -- corner
	S(-5, dy, -4, "lazarus_space:plasma_field")
	S(-5, dy, -3, "lazarus_space:plasma_field")
	S(-5, dy, -2, "lazarus_space:plasma_field")
end

-- ============================================================
-- STRUCTURE VALIDATION
-- ============================================================

--- Find the pole corrector near a given position.
local function find_pole_corrector(pos)
	local range = 6
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
		if expected == "lazarus_space:plasma_field" then
			if node.name ~= "lazarus_space:plasma_field"
				and node.name ~= "lazarus_space:plasma_field_corner" then
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

local function build_unchecked_formspec()
	return "formspec_version[4]"
		.. "size[10,6]"
		.. "bgcolor[#00000000]"
		.. "background[0,0;10,6;lazarus_space_disrupter_top.png;true]"
		.. "box[0,0;10,6;#111111CC]"
		.. "label[2.2,1.5;Magnetic Fusion Reactor]"
		.. "label[1.8,2.3;Structure Check Required]"
		.. "button[3,3.5;4,0.8;check_structure;Check Structure]"
end

local function build_error_formspec(errors)
	local fs = "formspec_version[4]"
		.. "size[10,8]"
		.. "bgcolor[#00000000]"
		.. "box[0,0;10,8;#111111CC]"
		.. "label[2.2,0.8;Magnetic Fusion Reactor]"
		.. "label[1.5,1.5;\\#FF4444Structure Check Failed:]"

	local y = 2.2
	for i, err in ipairs(errors) do
		if i > 8 then break end
		fs = fs .. "label[0.5," .. y .. ";\\#FFAAAA- " ..
			minetest.formspec_escape(err) .. "]"
		y = y + 0.55
	end

	fs = fs .. "button[3," .. (y + 0.3) .. ";4,0.8;check_structure;Retry Check]"
	return fs
end

local function build_reactor_formspec(pos)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("reactor_state")
	if state == "" then state = "standby" end
	local charge_timer = meta:get_int("charge_timer")
	local fuel_time = meta:get_int("fuel_time")
	local power_tier = meta:get_string("power_tier")
	if power_tier == "" then power_tier = "HV" end

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

	-- Check power output tier
	local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
	if po_pos then
		local po_meta = minetest.get_meta(po_pos)
		local tier = po_meta:get_string("output_tier")
		if tier ~= "" then power_tier = tier end
	end

	-- State colors
	local state_color, state_label
	if state == "standby" then
		state_color = "\\#FFCC00"
		state_label = "Standby"
	elseif state == "charging" then
		state_color = "\\#FF8800"
		state_label = "Charging... " .. charge_timer .. "s"
	elseif state == "charged" then
		state_color = "\\#FF8800"
		state_label = "Charged — Ready to Inject"
	elseif state == "active" then
		state_color = "\\#44FF44"
		state_label = "Active"
	elseif state == "shutdown" then
		state_color = "\\#FF4444"
		state_label = "Shutdown"
	else
		state_color = "\\#AAAAAA"
		state_label = state
	end

	local fs = "formspec_version[4]"
		.. "size[10,11.5]"
		.. "bgcolor[#00000000]"
		.. "box[0,0;10,11.5;#111111CC]"
		-- Title
		.. "label[2.5,0.6;Magnetic Fusion Reactor]"
		-- Status
		.. "label[0.5,1.3;Status:]"
		.. "label[2.2,1.3;" .. state_color .. state_label .. "]"
		-- Fuel inventory
		.. "label[0.5,2.0;Fuel Rods]"
		.. "list[context;fuel;0.5,2.5;6,1;]"
		.. "label[0.5,3.7;Fuel: " .. fuel_count .. "/" .. FUEL_SLOTS .. "]"
		-- HV Power status
		.. "label[0.5,4.4;HV Power:]"

	if hv_ready then
		fs = fs .. "label[2.8,4.4;\\#44FF44Ready]"
	else
		fs = fs .. "label[2.8,4.4;\\#FF4444Insufficient]"
	end

	-- Control buttons
	if state == "standby" then
		if fuel_count >= FUEL_SLOTS and hv_ready then
			fs = fs .. "button[0.5,5.2;4,0.8;charge;Charge]"
		else
			fs = fs .. "box[0.5,5.2;4,0.8;#333333FF]"
				.. "label[1.5,5.55;\\#666666Charge (not ready)]"
		end
	elseif state == "charging" then
		fs = fs .. "box[0.5,5.2;4,0.8;#FF8800FF]"
			.. "label[1.2,5.55;Charging... " .. charge_timer .. "s]"
	elseif state == "charged" then
		fs = fs .. "button[0.5,5.2;4,0.8;inject;Inject Fuel & Start]"
	elseif state == "active" then
		-- Fuel remaining display
		local mins = math.floor(fuel_time / 60)
		local secs = fuel_time % 60
		fs = fs .. "label[0.5,5.3;Fuel Remaining: "
			.. string.format("%d:%02d", mins, secs) .. "]"
		fs = fs .. "label[0.5,6.0;Reactor Output: 140,000 EU]"
		fs = fs .. "label[0.5,6.6;Tier: " .. power_tier .. "]"
	end

	-- Player inventory
	fs = fs .. "list[current_player;main;0.5,7.5;8,4;]"
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
			minetest.show_formspec(sender:get_player_name(),
				"lazarus_space:fusion_panel_" .. minetest.pos_to_string(pos),
				build_reactor_formspec(pos))
		else
			minetest.show_formspec(sender:get_player_name(),
				"lazarus_space:fusion_panel_" .. minetest.pos_to_string(pos),
				build_error_formspec(result))
		end
		return
	end

	if fields.charge then
		local state = meta:get_string("reactor_state")
		if state ~= "standby" then return end

		-- Verify fuel
		local inv = meta:get_inventory()
		local fuel_count = 0
		for i = 1, FUEL_SLOTS do
			local stack = inv:get_stack("fuel", i)
			if stack:get_name() == FUEL_ITEM then
				fuel_count = fuel_count + stack:get_count()
			end
		end
		if fuel_count < FUEL_SLOTS then return end

		-- Verify HV power
		local js_pos = find_neighbor(pos, "lazarus_space:plasma_jumpstarter")
		if not js_pos then return end
		local js_meta = minetest.get_meta(js_pos)
		if js_meta:get_int("stored_energy") < JUMPSTART_ENERGY then return end

		-- Start charge sequence
		meta:set_string("reactor_state", "charging")
		meta:set_int("charge_timer", CHARGE_TIME)

		-- Drain jumpstarter energy
		local stored = js_meta:get_int("stored_energy")
		js_meta:set_int("stored_energy", math.max(0, stored - JUMPSTART_ENERGY))

		-- Timer is already running from validation
		minetest.show_formspec(sender:get_player_name(),
			"lazarus_space:fusion_panel_" .. minetest.pos_to_string(pos),
			build_reactor_formspec(pos))
		return
	end

	if fields.inject then
		local state = meta:get_string("reactor_state")
		if state ~= "charged" then return end

		-- Consume fuel rods
		local inv = meta:get_inventory()
		for i = 1, FUEL_SLOTS do
			inv:set_stack("fuel", i, "")
		end

		-- Activate reactor
		meta:set_string("reactor_state", "active")
		meta:set_int("fuel_time", FUEL_DURATION)

		-- Notify power output
		local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
		if po_pos then
			local po_meta = minetest.get_meta(po_pos)
			po_meta:set_int("active", 1)
		end

		minetest.show_formspec(sender:get_player_name(),
			"lazarus_space:fusion_panel_" .. minetest.pos_to_string(pos),
			build_reactor_formspec(pos))
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

				-- Shut down power output
				local po_pos = find_neighbor(pos,
					"lazarus_space:fusion_power_output")
				if po_pos then
					local po_meta = minetest.get_meta(po_pos)
					po_meta:set_int("active", 0)
				end
				return false -- stop timer
			end
		end
		meta:set_float("check_accumulator", check_acc)
	end

	-- Charging countdown
	if state == "charging" then
		local ct = meta:get_int("charge_timer") - 1

		-- Check fuel still present
		local inv = meta:get_inventory()
		local fuel_count = 0
		for i = 1, FUEL_SLOTS do
			local stack = inv:get_stack("fuel", i)
			if stack:get_name() == FUEL_ITEM then
				fuel_count = fuel_count + stack:get_count()
			end
		end
		if fuel_count < FUEL_SLOTS then
			meta:set_string("reactor_state", "standby")
			meta:set_int("charge_timer", 0)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Charge Failed: Fuel Removed")
			return true
		end

		if ct <= 0 then
			meta:set_string("reactor_state", "charged")
			meta:set_int("charge_timer", 0)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Charged")
		else
			meta:set_int("charge_timer", ct)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Charging... " .. ct .. "s")
		end
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

			-- Notify power output
			local po_pos = find_neighbor(pos,
				"lazarus_space:fusion_power_output")
			if po_pos then
				local po_meta = minetest.get_meta(po_pos)
				po_meta:set_int("active", 0)
			end
		else
			meta:set_int("fuel_time", ft)
			local mins = math.floor(ft / 60)
			local secs = ft % 60
			meta:set_string("infotext", "Magnetic Fusion Reactor — Active ("
				.. string.format("%d:%02d", mins, secs) .. ")")
		end
		return true
	end

	-- Standby or charged: keep timer alive for integrity checks
	if meta:get_string("validated") == "true" then
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
		-- Auto-corner logic: check perpendicular neighbors
		local node = minetest.get_node(pos)
		local dir = minetest.facedir_to_dir(node.param2)
		-- The tube runs along the axis defined by facedir
		-- facedir 0 = +Z, 1 = +X, 2 = -Z, 3 = -X
		local horiz_dirs = {
			{x=1,y=0,z=0}, {x=-1,y=0,z=0},
			{x=0,y=0,z=1}, {x=0,y=0,z=-1},
		}

		for _, d in ipairs(horiz_dirs) do
			local npos = vector.add(pos, d)
			local nnode = minetest.get_node(npos)
			if nnode.name == "lazarus_space:plasma_field"
				or nnode.name == "lazarus_space:plasma_field_corner" then
				-- Check if the neighbor runs on a different axis
				local ndir = minetest.facedir_to_dir(nnode.param2)
				-- If axes are perpendicular, convert the newly placed piece
				-- to a corner at the junction
				local my_axis = (node.param2 % 4) % 2 -- 0=Z-axis, 1=X-axis
				local n_axis = (nnode.param2 % 4) % 2

				if my_axis ~= n_axis and nnode.name == "lazarus_space:plasma_field" then
					-- Determine corner orientation
					-- The corner connects the two perpendicular directions
					-- We convert the current node to a corner piece
					-- Corner facedir: 0=NE, 1=SE, 2=SW, 3=NW (approximate)
					local corner_param2 = 0
					if d.x == 1 and my_axis == 0 then corner_param2 = 0
					elseif d.x == 1 and my_axis == 1 then corner_param2 = 1
					elseif d.x == -1 and my_axis == 0 then corner_param2 = 3
					elseif d.x == -1 and my_axis == 1 then corner_param2 = 2
					elseif d.z == 1 and my_axis == 1 then corner_param2 = 0
					elseif d.z == 1 and my_axis == 0 then corner_param2 = 3
					elseif d.z == -1 and my_axis == 1 then corner_param2 = 1
					elseif d.z == -1 and my_axis == 0 then corner_param2 = 2
					end

					minetest.set_node(pos, {
						name = "lazarus_space:plasma_field_corner",
						param2 = corner_param2,
					})
					break
				end
			end
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
		meta:set_string("power_tier", "HV")
		meta:set_string("infotext", "Magnetic Fusion Reactor — Not Validated")
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

	on_rightclick = function(pos, node, clicker)
		local meta = minetest.get_meta(pos)
		local validated = meta:get_string("validated")
		local name = clicker:get_player_name()
		local fs_name = "lazarus_space:fusion_panel_" .. minetest.pos_to_string(pos)

		if validated == "true" then
			minetest.show_formspec(name, fs_name, build_reactor_formspec(pos))
		else
			minetest.show_formspec(name, fs_name, build_unchecked_formspec())
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

	on_metadata_inventory_put = function(pos)
		-- Refresh formspec if someone has it open
	end,
})

-- Register formspec handler for the control panel
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:find("^lazarus_space:fusion_panel_") then return false end
	local pos_str = formname:sub(#"lazarus_space:fusion_panel_" + 1)
	local pos = minetest.string_to_pos(pos_str)
	if not pos then return false end
	local node = minetest.get_node(pos)
	if node.name ~= "lazarus_space:fusion_control_panel" then return false end
	panel_on_receive_fields(pos, formname, fields, player)
	return true
end)

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
	connect_sides = {"bottom", "back", "left", "right"},
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
	connect_sides = {"bottom", "back", "left", "right"},
	sounds = default.node_sound_metal_defaults(),

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("output_tier", "HV")
		meta:set_int("active", 0)
		meta:set_int("LV_EU_supply", 0)
		meta:set_int("MV_EU_supply", 0)
		meta:set_int("HV_EU_supply", 0)
		meta:set_string("infotext", "Fusion Power Output — Offline")
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
		local active = meta:get_int("active") == 1

		local output_label
		if active then
			output_label = "Output: 140,000 EU"
		else
			output_label = "Output: 0 EU (Reactor Offline)"
		end

		-- Highlight current tier
		local lv_style = ""
		local mv_style = ""
		local hv_style = ""
		if tier == "LV" then
			lv_style = "style[set_lv;bgcolor=#446644]"
		elseif tier == "MV" then
			mv_style = "style[set_mv;bgcolor=#444466]"
		else
			hv_style = "style[set_hv;bgcolor=#664444]"
		end

		local fs = "formspec_version[4]"
			.. "size[8,5]"
			.. "bgcolor[#00000000]"
			.. "box[0,0;8,5;#111111CC]"
			.. "label[2.2,0.7;Fusion Power Output]"
			.. "label[0.5,1.5;Current Tier: " .. tier .. "]"
			.. "label[0.5,2.1;" .. output_label .. "]"
			.. lv_style .. mv_style .. hv_style
			.. "button[0.5,3.0;2,0.8;set_lv;LV]"
			.. "button[3.0,3.0;2,0.8;set_mv;MV]"
			.. "button[5.5,3.0;2,0.8;set_hv;HV]"

		minetest.show_formspec(clicker:get_player_name(),
			"lazarus_space:power_output_" .. minetest.pos_to_string(pos), fs)
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local active = meta:get_int("active") == 1
		local tier = meta:get_string("output_tier")
		if tier == "" then tier = "HV" end

		-- Reset all supply values
		meta:set_int("LV_EU_supply", 0)
		meta:set_int("MV_EU_supply", 0)
		meta:set_int("HV_EU_supply", 0)

		if active then
			meta:set_int(tier .. "_EU_supply", POWER_OUTPUT)
			meta:set_string("infotext", "Fusion Power Output — "
				.. POWER_OUTPUT .. " EU (" .. tier .. ")")
		else
			meta:set_string("infotext", "Fusion Power Output — Offline")
		end
	end,
})

-- Register power output as supply on all three tiers
technic.register_machine("HV", "lazarus_space:fusion_power_output", technic.supply)
technic.register_machine("MV", "lazarus_space:fusion_power_output", technic.supply)
technic.register_machine("LV", "lazarus_space:fusion_power_output", technic.supply)

-- Power output formspec handler
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if not formname:find("^lazarus_space:power_output_") then return false end
	local pos_str = formname:sub(#"lazarus_space:power_output_" + 1)
	local pos = minetest.string_to_pos(pos_str)
	if not pos then return false end
	local node = minetest.get_node(pos)
	if node.name ~= "lazarus_space:fusion_power_output" then return false end

	local meta = minetest.get_meta(pos)
	if fields.set_lv then
		meta:set_string("output_tier", "LV")
	elseif fields.set_mv then
		meta:set_string("output_tier", "MV")
	elseif fields.set_hv then
		meta:set_string("output_tier", "HV")
	end

	if fields.set_lv or fields.set_mv or fields.set_hv then
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
