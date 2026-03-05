-- Lazarus Space: Magnetic Fusion Reactor
-- 13x13x5 multiblock structure with charge sequence and power output.

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

local function build_unchecked_formspec()
	return "size[8,4]"
		.. "bgcolor[#080808;true]"
		.. "label[3,0.5;Magnetic Fusion Reactor]"
		.. "label[2,1.5;Structure Check Required]"
		.. "button[2.5,2.5;3,1;check_structure;Check Structure]"
end

local function build_error_formspec(errors)
	local fs = "size[8,7]"
		.. "bgcolor[#080808;true]"
		.. "label[2.5,0.5;Magnetic Fusion Reactor]"
		.. "label[1.5,1;Structure Check Failed:]"

	local y = 1.5
	for i, err in ipairs(errors) do
		if i > 6 then break end
		fs = fs .. "label[0.5," .. y .. "; - " ..
			minetest.formspec_escape(err) .. "]"
		y = y + 0.5
	end

	fs = fs .. "button[2.5," .. (y + 0.5) .. ";3,1;check_structure;Retry Check]"
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

	-- State label
	local state_label
	if state == "standby" then
		state_label = "Standby"
	elseif state == "charging" then
		state_label = "Charging... " .. charge_timer .. "s"
	elseif state == "charged" then
		state_label = "Charged - Ready to Inject"
	elseif state == "active" then
		state_label = "Active"
	elseif state == "shutdown" then
		state_label = "Shutdown"
	else
		state_label = state
	end

	local fs = "size[8,9]"
		.. "bgcolor[#080808;true]"
		-- Title and status
		.. "label[2.5,0;Magnetic Fusion Reactor]"
		.. "label[0.5,0.5;Status: " .. state_label .. "]"
		-- Fuel inventory
		.. "label[1,1.5;Fuel Rods (" .. fuel_count .. "/" .. FUEL_SLOTS .. ")]"
		.. "list[context;fuel;1,2;6,1;]"
		-- HV Power status
		.. "label[0.5,3;HV Power: " .. (hv_ready and "Ready" or "Insufficient") .. "]"

	-- Control buttons and output info
	if state == "standby" then
		if fuel_count >= FUEL_SLOTS and hv_ready then
			fs = fs .. "button[2.5,3.5;3,1;charge;Charge]"
		else
			fs = fs .. "label[2.5,3.7;Charge (not ready)]"
		end
	elseif state == "charging" then
		fs = fs .. "label[2.5,3.7;Charging... " .. charge_timer .. "s]"
	elseif state == "charged" then
		fs = fs .. "button[2,3.5;4,1;inject;Inject Fuel & Start]"
	elseif state == "active" then
		local mins = math.floor(fuel_time / 60)
		local secs = fuel_time % 60
		fs = fs .. "label[0.5,3.5;Fuel Remaining: "
			.. string.format("%d:%02d", mins, secs) .. "]"
		fs = fs .. "label[0.5,4;Output: 140,000 EU (" .. power_tier .. ")]"
	end

	-- Player inventory
	fs = fs .. "list[current_player;main;0,5;8,1;]"
		.. "list[current_player;main;0,6;8,3;8]"
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
		meta:set_string("formspec", build_reactor_formspec(pos))
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

				-- Shut down power output
				local po_pos = find_neighbor(pos,
					"lazarus_space:fusion_power_output")
				if po_pos then
					local po_meta = minetest.get_meta(po_pos)
					po_meta:set_int("active", 0)
				end
				meta:set_string("formspec", build_unchecked_formspec())
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
			meta:set_string("formspec", build_reactor_formspec(pos))
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
		meta:set_string("formspec", build_reactor_formspec(pos))
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

		local fs = "size[8,4]"
			.. "bgcolor[#080808;true]"
			.. "label[2,0;Fusion Power Output]"
			.. "label[0.5,0.5;Current Tier: " .. tier .. "]"
			.. "label[0.5,1;" .. output_label .. "]"
			.. "button[0.5,2;2,1;set_lv;LV]"
			.. "button[3,2;2,1;set_mv;MV]"
			.. "button[5.5,2;2,1;set_hv;HV]"

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
