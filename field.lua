-- Lazarus Space: Field deployment, tracking, suppression, and teardown

-- ============================================================
-- CONSTANTS
-- ============================================================

local FIELD_RADIUS_MIN = 9
local FIELD_RADIUS_MAX = 18
local POWER_DEMAND = lazarus_space.POWER_DEMAND
local OBSERVATION_INTERVAL = 1.5 -- seconds between player checks
local URANIUM_CHECK_INTERVAL = 0.8 -- seconds between inventory checks
local EXPLOSION_RADIUS = 15

-- Known reactor core node names.
local REACTOR_CORES = {
	"technic:hv_nuclear_reactor_core_active",
}

-- ============================================================
-- HELPERS
-- ============================================================

--- Check whether a position falls within any active field interior.
function lazarus_space.pos_in_field(pos)
	if not next(lazarus_space.active_fields) then
		return false
	end
	for _, field in pairs(lazarus_space.active_fields) do
		local d = vector.distance(pos, field.pos)
		if d <= field.radius then
			return true
		end
	end
	return false
end

--- Check whether a position belongs to any active field,
--- including the shell (which extends up to radius + 0.5).
function lazarus_space.pos_belongs_to_field(pos)
	if not next(lazarus_space.active_fields) then
		return false
	end
	for _, field in pairs(lazarus_space.active_fields) do
		local d = vector.distance(pos, field.pos)
		if d <= field.radius + 1 then
			return true
		end
	end
	return false
end

--- Calculate the largest field radius that fits in loaded area.
function lazarus_space.calculate_field_radius(pos)
	for r = FIELD_RADIUS_MAX, FIELD_RADIUS_MIN, -1 do
		local all_loaded = true
		-- Sample axis-aligned extremes.
		local offsets = {
			{x = r, y = 0, z = 0}, {x = -r, y = 0, z = 0},
			{x = 0, y = r, z = 0}, {x = 0, y = -r, z = 0},
			{x = 0, y = 0, z = r}, {x = 0, y = 0, z = -r},
		}
		for _, off in ipairs(offsets) do
			local p = vector.add(pos, off)
			if minetest.get_node(p).name == "ignore" then
				all_loaded = false
				break
			end
		end
		if all_loaded then return r end
	end
	return FIELD_RADIUS_MIN
end

--- Trigger a terrain-destroying explosion at center with given radius.
local function explode(center, radius)
	-- Visual particle burst.
	minetest.add_particlespawner({
		amount = 300,
		time = 0.3,
		minpos = vector.subtract(center, 2),
		maxpos = vector.add(center, 2),
		minvel = {x = -30, y = -30, z = -30},
		maxvel = {x = 30, y = 30, z = 30},
		minacc = {x = 0, y = -5, z = 0},
		maxacc = {x = 0, y = -5, z = 0},
		minexptime = 0.5,
		maxexptime = 2.5,
		minsize = 6,
		maxsize = 16,
		texture = "lazarus_space_decaying_uranium.png",
		glow = 14,
	})

	-- Explosion sound (uses tnt sound if available).
	minetest.sound_play("tnt_explode", {
		pos = center,
		gain = 2.0,
		max_hear_distance = radius * 10,
	}, true)

	-- Destroy all nodes in sphere (except air and ignore) via VoxelManip.
	local count = 0
	local min_pos = {x = center.x - radius, y = center.y - radius, z = center.z - radius}
	local max_pos = {x = center.x + radius, y = center.y + radius, z = center.z + radius}
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(min_pos, max_pos)
	local va = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data()
	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local r_sq = radius * radius

	for dx = -radius, radius do
		for dy = -radius, radius do
			for dz = -radius, radius do
				if dx * dx + dy * dy + dz * dz <= r_sq then
					local vi = va:index(center.x + dx, center.y + dy, center.z + dz)
					if data[vi] ~= c_air and data[vi] ~= c_ignore then
						data[vi] = c_air
						count = count + 1
					end
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(true)

	-- Damage all entities in blast radius.
	local objects = minetest.get_objects_inside_radius(
		center, radius)
	for _, obj in ipairs(objects) do
		if obj:is_player() then
			obj:set_hp(0, {type = "set_hp"})
		else
			local ent = obj:get_luaentity()
			if ent then obj:remove() end
		end
	end

	minetest.log("action",
		"Lazarus Space: explosion at "
		.. minetest.pos_to_string(center)
		.. " radius " .. radius
		.. " destroyed " .. count .. " nodes")
end

--- Remove all decaying uranium from a player's inventory.
local function remove_uranium_from_inventory(player)
	local inv = player:get_inventory()
	for _, listname in ipairs({"main", "craft", "craftpreview"}) do
		local list = inv:get_list(listname)
		if list then
			for i, stack in ipairs(list) do
				if stack:get_name()
						== "lazarus_space:decaying_uranium" then
					stack:clear()
					inv:set_stack(listname, i, stack)
				end
			end
		end
	end
end

-- ============================================================
-- FIELD DEPLOYMENT
-- ============================================================

--- Deploy the disrupted space field around the device.
function lazarus_space.deploy_field(pos)
	local hash = minetest.hash_node_position(pos)

	-- Guard against double-deploy.
	if lazarus_space.active_fields[hash] then return end

	local meta = minetest.get_meta(pos)
	local radius = lazarus_space.calculate_field_radius(pos)
	local r_min = radius - 0.5
	local r_max = radius + 0.5

	-- Place shell with noise-based opacity variants and
	-- detect reactor cores in a single pass.
	local reactor_found = false
	local shell_count = 0

	-- Perlin noise for smooth opacity variation across the shell.
	local noise = minetest.get_perlin({
		offset = 0,
		scale = 1,
		spread = {x = 5, y = 5, z = 5},
		seed = hash + 42,
		octaves = 2,
		persist = 0.5,
	})

	-- VoxelManip for bulk shell placement
	local shell_min = {x = pos.x - radius - 1, y = pos.y - radius - 1, z = pos.z - radius - 1}
	local shell_max = {x = pos.x + radius + 1, y = pos.y + radius + 1, z = pos.z + radius + 1}
	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(shell_min, shell_max)
	local va = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
	local data = vm:get_data()

	local c_ds = {}
	for i = 1, 20 do
		c_ds[i] = minetest.get_content_id("lazarus_space:disrupted_space_" .. i)
	end

	for dx = -radius - 1, radius + 1 do
		for dy = -radius - 1, radius + 1 do
			for dz = -radius - 1, radius + 1 do
				local dist = math.sqrt(dx * dx + dy * dy
					+ dz * dz)
				if dist > r_max then goto next end

				-- Skip device position.
				if dx == 0 and dy == 0 and dz == 0 then
					goto next
				end

				if dist >= r_min then
					-- Shell: place disrupted space with
					-- noise-based opacity variant.
					local p = {
						x = pos.x + dx,
						y = pos.y + dy,
						z = pos.z + dz,
					}
					local nval = (noise:get_3d(p) + 1) / 2
					if nval < 0 then nval = 0 end
					if nval > 1 then nval = 1 end
					local variant
					if nval < 0.25 then
						variant = math.floor(
							nval / 0.25 * 9) + 1
						if variant > 9 then variant = 9 end
					else
						variant = math.floor(
							(nval - 0.25) / 0.75 * 11)
							+ 10
						if variant > 20 then
							variant = 20
						end
					end
					local vi = va:index(pos.x + dx, pos.y + dy, pos.z + dz)
					data[vi] = c_ds[variant]
					shell_count = shell_count + 1
				else
					-- Interior: check for reactor cores.
					local node = minetest.get_node({
						x = pos.x + dx,
						y = pos.y + dy,
						z = pos.z + dz,
					})
					for _, core_name in ipairs(REACTOR_CORES) do
						if node.name == core_name then
							reactor_found = true
						end
					end
				end

				::next::
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(true)

	minetest.log("action",
		"Lazarus Space: deployed " .. shell_count
		.. " shell nodes")

	-- Stop charging particle rings (fade out).
	local charging_entry = lazarus_space.charging_devices[hash]
	if charging_entry then
		charging_entry.fading = true
		charging_entry.fade_start = minetest.get_us_time() / 1e6
	end

	-- Swap device to active variant.
	technic.swap_node(pos,
		"lazarus_space:continuum_disrupter_active")

	-- Self-sustaining: no more power needed.
	meta:set_int("HV_EU_demand", 0)
	meta:set_string("state", "active")
	meta:set_string("infotext",
		"Continuum Disrupter (Field Active)")

	-- Spawn 3D starfield particle layers inside the sphere.
	local star_spawners = {}
	local spawn_r = radius - 1 -- keep particles inside shell
	local spawn_min = vector.subtract(pos, spawn_r)
	local spawn_max = vector.add(pos, spawn_r)

	-- Layer 1: Near stars — bright, small, moderate drift.
	star_spawners[#star_spawners + 1] = minetest.add_particlespawner({
		amount = 300,
		time = 0, -- infinite
		minpos = spawn_min,
		maxpos = spawn_max,
		minvel = {x = -0.2, y = -0.2, z = -0.2},
		maxvel = {x = 0.2, y = 0.2, z = 0.2},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 8,
		maxexptime = 14,
		minsize = 0.3,
		maxsize = 0.5,
		texture = "lazarus_space_star_near.png",
		glow = 14,
		collisiondetection = false,
	})

	-- Layer 2: Far stars — dimmer, slower, slightly larger.
	star_spawners[#star_spawners + 1] = minetest.add_particlespawner({
		amount = 120,
		time = 0,
		minpos = spawn_min,
		maxpos = spawn_max,
		minvel = {x = -0.05, y = -0.05, z = -0.05},
		maxvel = {x = 0.05, y = 0.05, z = 0.05},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 12,
		maxexptime = 20,
		minsize = 0.4,
		maxsize = 0.7,
		texture = "lazarus_space_star_far.png",
		glow = 10,
		collisiondetection = false,
	})

	-- Layer 3: Nebula — rare, faint colored glows.
	star_spawners[#star_spawners + 1] = minetest.add_particlespawner({
		amount = 15,
		time = 0,
		minpos = spawn_min,
		maxpos = spawn_max,
		minvel = {x = -0.03, y = -0.03, z = -0.03},
		maxvel = {x = 0.03, y = 0.03, z = 0.03},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 15,
		maxexptime = 25,
		minsize = 1.0,
		maxsize = 2.0,
		texture = "lazarus_space_star_nebula.png",
		glow = 8,
		collisiondetection = false,
	})

	-- Register in global tracking table.
	lazarus_space.active_fields[hash] = {
		pos = vector.new(pos),
		radius = radius,
		state = "active",
		reactor_found = reactor_found,
		portal_positions = {},
		portal_frontier = {},
		portal_origin = nil,
		portal_timer = 0,
		star_spawners = star_spawners,
	}

	-- Freeze entities inside the field.
	lazarus_space.freeze_entities(pos, radius)

	-- Persist active field to mod storage for crash recovery.
	lazarus_space.save_field_record(pos, radius)

	lazarus_space.build_formspec(pos)

	minetest.log("action",
		"Lazarus Space: field deployed at "
		.. minetest.pos_to_string(pos)
		.. " radius " .. radius)
end

-- ============================================================
-- FIELD CLEANUP HELPER
-- ============================================================

--- Shared cleanup: remove shell, portal, disrupted space nodes,
--- and randomly delete 50% of interior solid blocks.
local function cleanup_field_nodes(pos, radius)
	local r_min = radius
	local r_max = radius + 1
	local stats = {shell = 0, portal = 0, deleted = 0, kept = 0}

	for dx = -radius - 1, radius + 1 do
		for dy = -radius - 1, radius + 1 do
			for dz = -radius - 1, radius + 1 do
				local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
				if dist > r_max then goto next_cleanup end
				local p = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
				local current = minetest.get_node(p)
				if current.name == "air" or current.name == "ignore" then
					goto next_cleanup
				end

				if dist >= r_min then
					-- Shell zone
					minetest.set_node(p, {name = "air"})
					stats.shell = stats.shell + 1
				else
					-- Interior zone
					if lazarus_space.is_portal(current.name) then
						minetest.set_node(p, {name = "air"})
						stats.portal = stats.portal + 1
					elseif lazarus_space.is_disrupted_space(current.name) then
						minetest.set_node(p, {name = "air"})
						stats.shell = stats.shell + 1
					elseif math.random() < 0.5 then
						minetest.set_node(p, {name = "air"})
						stats.deleted = stats.deleted + 1
					else
						stats.kept = stats.kept + 1
					end
				end
				::next_cleanup::
			end
		end
	end

	-- Safety sweep for stragglers
	for dx = -radius - 1, radius + 1 do
		for dy = -radius - 1, radius + 1 do
			for dz = -radius - 1, radius + 1 do
				local p = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
				local n = minetest.get_node(p)
				if lazarus_space.is_disrupted_space(n.name) or lazarus_space.is_portal(n.name) then
					minetest.set_node(p, {name = "air"})
				end
			end
		end
	end

	return stats
end

-- ============================================================
-- FIELD TEARDOWN
-- ============================================================

--- Full field teardown: remove shell, portal, disrupted space,
--- and randomly delete 50% of interior blocks.
function lazarus_space.teardown_field(pos)
	local hash = minetest.hash_node_position(pos)
	local field = lazarus_space.active_fields[hash]
	if not field then return end

	-- Remove from tracking first to prevent re-entry
	-- when the device node is destroyed (on_destruct).
	lazarus_space.active_fields[hash] = nil
	lazarus_space.charging_devices[hash] = nil

	-- Clear persistent record from mod storage.
	lazarus_space.clear_field_record(pos)

	-- Cancel warp charge if in progress.
	if field.warp_charge_pos then
		local gp = field.warp_charge_pos
		local gnode = minetest.get_node(gp)
		if gnode.name:find("^lazarus_space:warp_glow_") then
			minetest.set_node(gp, {name = "air"})
		end
		field.warp_charge_pos = nil
		field.warp_charge_timer = nil
		field.warp_charge_stage = nil
	end

	-- Remove starfield particle spawners.
	if field.star_spawners then
		for _, sid in ipairs(field.star_spawners) do
			minetest.delete_particlespawner(sid)
		end
		field.star_spawners = nil
	end

	-- Remove portal blocks first.
	if field.portal_positions then
		for _, p in ipairs(field.portal_positions) do
			local node = minetest.get_node(p)
			if lazarus_space.is_portal(node.name) then
				minetest.set_node(p, {name = "air"})
			end
		end
	end

	-- Destroy the continuum disrupter device.
	minetest.set_node(pos, {name = "air"})

	local radius = field.radius

	-- Clean up field nodes
	local stats = cleanup_field_nodes(pos, radius)

	-- Unfreeze entities.
	lazarus_space.unfreeze_entities(pos, radius)

	minetest.log("action",
		"Lazarus Space: teardown complete — "
		.. stats.shell .. " shell, " .. stats.portal .. " portal, "
		.. stats.deleted .. " terrain deleted, " .. stats.kept .. " kept")
end

-- ============================================================
-- ENTITY FREEZING
-- ============================================================

function lazarus_space.freeze_entities(pos, radius)
	local objects = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in ipairs(objects) do
		if not obj:is_player() then
			local ent = obj:get_luaentity()
			if ent then
				obj:set_velocity({x = 0, y = 0, z = 0})
				obj:set_acceleration({x = 0, y = 0, z = 0})
				ent.stasis_frozen = true
			end
		end
	end
end

function lazarus_space.unfreeze_entities(pos, radius)
	local objects = minetest.get_objects_inside_radius(pos, radius)
	for _, obj in ipairs(objects) do
		if not obj:is_player() then
			local ent = obj:get_luaentity()
			if ent and ent.stasis_frozen then
				ent.stasis_frozen = false
			end
		end
	end
end

-- ============================================================
-- TECHNIC_RUN CALLBACK
-- ============================================================

function lazarus_space.technic_run(pos, node)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("state")
	if state == "" then state = "idle" end
	local eu_input = meta:get_int("HV_EU_input")

	-- Idle: no power draw.
	if state == "idle" then
		meta:set_int("HV_EU_demand", 0)
		lazarus_space.build_formspec(pos)
		return
	end

	-- Charging: accumulate power.
	if state == "charging" then
		meta:set_int("HV_EU_demand", POWER_DEMAND)
		if eu_input > 0 then
			local charge = meta:get_int("charge") + eu_input
			meta:set_int("charge", charge)
			if charge >= lazarus_space.CHARGE_REQUIRED then
				lazarus_space.deploy_field(pos)
				return
			end
		end
		lazarus_space.build_formspec(pos)
		return
	end

	-- Active / portal states: self-sustaining.
	meta:set_int("HV_EU_demand", 0)
	lazarus_space.build_formspec(pos)
end

-- ============================================================
-- CALLBACKS
-- ============================================================

function lazarus_space.on_construct(pos)
	local meta = minetest.get_meta(pos)
	meta:set_int("HV_EU_demand", 0)
	meta:set_int("HV_EU_input", 0)
	meta:set_int("enabled", 0)
	meta:set_int("charge", 0)
	meta:set_string("state", "idle")
	meta:set_string("infotext", "Continuum Disrupter (Idle)")
	lazarus_space.build_formspec(pos)
end

function lazarus_space.on_destruct(pos)
	lazarus_space.teardown_field(pos)
end

function lazarus_space.on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("state")

	if fields.activate and state == "idle" then
		local radius = lazarus_space.calculate_field_radius(pos)
		meta:set_string("state", "charging")
		meta:set_int("charge", 0)
		meta:set_int("enabled", 1)
		meta:set_int("anticipated_radius", radius)
		meta:set_string("infotext",
			"Continuum Disrupter (Charging)")

		-- Register for particle ring spawning.
		local hash = minetest.hash_node_position(pos)
		lazarus_space.charging_devices[hash] = {
			pos = vector.new(pos),
			radius = radius,
			start_time = minetest.get_us_time() / 1e6,
			fading = false,
			fade_start = 0,
		}

		lazarus_space.build_formspec(pos)
	elseif fields.deactivate and state ~= "idle" then
		if state == "charging" then
			-- Charging phase: no active_fields entry yet,
			-- just reset to idle.
			local hash = minetest.hash_node_position(pos)
			lazarus_space.charging_devices[hash] = nil
			meta:set_string("state", "idle")
			meta:set_int("charge", 0)
			meta:set_int("HV_EU_demand", 0)
			meta:set_int("enabled", 0)
			meta:set_string("infotext",
				"Continuum Disrupter (Idle)")
			lazarus_space.build_formspec(pos)
		else
			lazarus_space.teardown_field(pos)
		end
	end
end

function lazarus_space.technic_on_disable(pos, node)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("state")
	-- Network disconnect during charging: reset to idle.
	if state == "charging" then
		local hash = minetest.hash_node_position(pos)
		lazarus_space.charging_devices[hash] = nil
		meta:set_string("state", "idle")
		meta:set_int("charge", 0)
		meta:set_int("HV_EU_demand", 0)
		meta:set_int("enabled", 0)
		meta:set_string("infotext",
			"Continuum Disrupter (No Network)")
		technic.swap_node(pos,
			"lazarus_space:continuum_disrupter")
		lazarus_space.build_formspec(pos)
	end
	-- Active fields are self-sustaining; network disconnect
	-- does not collapse them.
end

-- ============================================================
-- ENVIRONMENTAL DAMAGE SUPPRESSION
-- ============================================================

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if hp_change >= 0 then return hp_change end
	-- Cancel environmental damage inside a field.
	if reason and (reason.type == "drown"
			or reason.type == "node_damage") then
		local pos = player:get_pos()
		if lazarus_space.pos_in_field(pos) then
			return 0
		end
	end
	return hp_change
end, true)

-- ============================================================
-- DECAYING URANIUM LETHALITY
-- ============================================================

-- Globalstep: check player inventories for uranium outside field.
local uranium_timer = 0
minetest.register_globalstep(function(dtime)
	uranium_timer = uranium_timer + dtime
	if uranium_timer < URANIUM_CHECK_INTERVAL then return end
	uranium_timer = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		local inv = player:get_inventory()
		local has_uranium = false
		for _, listname in ipairs({"main", "craft", "craftpreview"}) do
			local list = inv:get_list(listname)
			if list then
				for _, stack in ipairs(list) do
					if stack:get_name()
							== "lazarus_space:decaying_uranium" then
						has_uranium = true
						break
					end
				end
			end
			if has_uranium then break end
		end

		if has_uranium then
			local pos = player:get_pos()
			if not lazarus_space.pos_in_field(pos) then
				-- Store position before any state changes.
				local death_pos = vector.round(pos)

				-- Find the field this player just left so
				-- we can tear it down BEFORE the explosion.
				local nearby_field_pos = nil
				for _, field in pairs(
						lazarus_space.active_fields) do
					local d = vector.distance(
						pos, field.pos)
					if d <= field.radius + 5 then
						nearby_field_pos =
							vector.new(field.pos)
						break
					end
				end

				-- Remove uranium first to prevent item drops.
				remove_uranium_from_inventory(player)

				-- Teardown field FIRST so all disrupted_space
				-- nodes are removed before the explosion.
				if nearby_field_pos then
					lazarus_space.teardown_field(
						nearby_field_pos)
				end

				-- THEN explode on already-cleaned terrain.
				explode(death_pos, EXPLOSION_RADIUS)
				minetest.log("action",
					"Lazarus Space: uranium detonation by "
					.. player:get_player_name()
					.. " at "
					.. minetest.pos_to_string(death_pos))
			end
		end
	end
end)

-- ABM: decaying uranium block outside field detonates.
minetest.register_abm({
	label = "Lazarus Space decaying uranium detonation",
	nodenames = {"lazarus_space:decaying_uranium"},
	interval = 1,
	chance = 1,
	action = function(pos)
		if not lazarus_space.pos_in_field(pos) then
			minetest.set_node(pos, {name = "air"})
			explode(pos, EXPLOSION_RADIUS)
		end
	end,
})

-- ============================================================
-- ORPHANED NODE CLEANUP
-- ============================================================

-- Removes field-generated nodes that have no managing active field.
-- Uses pos_belongs_to_field which checks radius + 1 to cover
-- the shell (which extends up to radius + 0.5 from center).
-- Build orphan cleanup list with all 20 disrupted space variants.
local orphan_nodenames = {}
for name, _ in pairs(lazarus_space.PORTAL_LOOKUP) do
	orphan_nodenames[#orphan_nodenames + 1] = name
end
-- Also include disrupted space variants
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:disrupted_space"
for i = 1, 20 do
	orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:disrupted_space_" .. i
end
-- Other field-generated nodes
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:lazarus_portal"
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:decaying_uranium"
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:warp_glow_1"
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:warp_glow_2"
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:warp_glow_3"
orphan_nodenames[#orphan_nodenames + 1] = "lazarus_space:warp_glow_4"

minetest.register_abm({
	label = "Lazarus Space orphaned node cleanup",
	nodenames = orphan_nodenames,
	interval = 5,
	chance = 1,
	action = function(pos)
		if not lazarus_space.pos_belongs_to_field(pos) then
			minetest.set_node(pos, {name = "air"})
		end
	end,
})

-- ============================================================
-- PLAYER OBSERVATION AND ENTITY FREEZE SCAN
-- ============================================================

local observation_timer = 0
minetest.register_globalstep(function(dtime)
	observation_timer = observation_timer + dtime
	if observation_timer < OBSERVATION_INTERVAL then return end
	observation_timer = 0

	-- Check each active field for player presence and freeze
	-- any unfrozen entities found inside.
	local to_collapse = {}
	local players = minetest.get_connected_players()
	local MAX_OBSERVATION_DISTANCE = 200

	for hash, field in pairs(lazarus_space.active_fields) do
		-- Check all connected players against the sphere.
		-- Catches every way a player can leave: teleport,
		-- death, disconnect, admin commands, other mods.
		local has_player = false
		for _, player in ipairs(players) do
			local ppos = player:get_pos()
			local dist = vector.distance(ppos, field.pos)
			if dist > MAX_OBSERVATION_DISTANCE then
				goto next_player
			end
			if dist <= field.radius then
				has_player = true
				break
			end
			::next_player::
		end

		-- Freeze any unfrozen entities inside field.
		local objects = minetest.get_objects_inside_radius(
			field.pos, field.radius + 16)
		for _, obj in ipairs(objects) do
			if not obj:is_player() then
				local ent = obj:get_luaentity()
				if ent and not ent.stasis_frozen then
					local obj_pos = obj:get_pos()
					if obj_pos then
						local d = vector.distance(
							obj_pos, field.pos)
						if d <= field.radius then
							obj:set_velocity(
								{x = 0, y = 0, z = 0})
							obj:set_acceleration(
								{x = 0, y = 0, z = 0})
							ent.stasis_frozen = true
						end
					end
				end
			end
		end

		if not has_player then
			to_collapse[#to_collapse + 1] = field.pos
		end
	end

	for _, fpos in ipairs(to_collapse) do
		lazarus_space.teardown_field(fpos)
	end
end)

-- ============================================================
-- CHARGING PARTICLE RINGS
-- ============================================================

-- 16 rings at evenly spaced tilts (0 to ~168.75 degrees).
-- Each ring is a great circle around the sphere center.
-- Alternating CW/CCW rotation, black/white particles.

local RING_COUNT = 8
local RING_SPAWN_INTERVAL = 0.5 -- seconds between spawner creation
local RING_ROTATION_PERIOD = 3.5 -- seconds per full rotation
local RING_FADE_DURATION = 1.5 -- seconds to fade out
local PARTICLE_LIFETIME = 0.5
local PARTICLE_SIZE_MIN = 0.6
local PARTICLE_SIZE_MAX = 0.8
local PARTICLES_PER_SPAWNER = 60

local ring_timer = 0
minetest.register_globalstep(function(dtime)
	ring_timer = ring_timer + dtime
	if ring_timer < RING_SPAWN_INTERVAL then return end
	ring_timer = 0

	local now = minetest.get_us_time() / 1e6
	local to_remove = {}

	for hash, dev in pairs(lazarus_space.charging_devices) do
		-- Check if fading and expired.
		if dev.fading then
			local fade_elapsed = now - dev.fade_start
			if fade_elapsed >= RING_FADE_DURATION then
				to_remove[#to_remove + 1] = hash
				goto next_dev
			end
		end

		-- Calculate opacity for fade.
		local opacity = 255
		if dev.fading then
			local fade_elapsed = now - dev.fade_start
			local t = 1 - (fade_elapsed / RING_FADE_DURATION)
			if t < 0 then t = 0 end
			opacity = math.floor(255 * t)
			if opacity <= 0 then
				to_remove[#to_remove + 1] = hash
				goto next_dev
			end
		end

		local elapsed = now - dev.start_time
		local center = dev.pos
		local radius = dev.radius

		local base_angle = elapsed * (2 * math.pi / RING_ROTATION_PERIOD)

		for ring_i = 0, RING_COUNT - 1 do
			local ring_frac = ring_i / RING_COUNT
			local ring_angle = base_angle + ring_frac * math.pi * 2
			local ring_radius = radius * (0.85 + ring_frac * 0.15)
			local ring_y = center.y + radius * math.sin(ring_frac * math.pi * 2) * 0.3

			local cx = center.x + math.cos(ring_angle) * ring_radius * 0.3
			local cz = center.z + math.sin(ring_angle) * ring_radius * 0.3

			minetest.add_particlespawner({
				amount = PARTICLES_PER_SPAWNER,
				time = RING_SPAWN_INTERVAL,
				minpos = {x = cx - ring_radius * 0.5, y = ring_y - 0.5, z = cz - ring_radius * 0.5},
				maxpos = {x = cx + ring_radius * 0.5, y = ring_y + 0.5, z = cz + ring_radius * 0.5},
				minvel = {x = -0.2, y = -0.1, z = -0.2},
				maxvel = {x = 0.2, y = 0.1, z = 0.2},
				minacc = {x = 0, y = 0, z = 0},
				maxacc = {x = 0, y = 0, z = 0},
				minexptime = PARTICLE_LIFETIME * 0.5,
				maxexptime = PARTICLE_LIFETIME,
				minsize = PARTICLE_SIZE_MIN,
				maxsize = PARTICLE_SIZE_MAX,
				texture = "lazarus_space_particle_white.png",
				glow = 14,
			})
		end

		::next_dev::
	end

	for _, hash in ipairs(to_remove) do
		lazarus_space.charging_devices[hash] = nil
	end
end)

-- ============================================================
-- FIELD PERSISTENCE (CRASH / RESTART RECOVERY)
-- ============================================================

--- Save an active field record to mod storage.
function lazarus_space.save_field_record(pos, radius)
	local storage = lazarus_space.mod_storage
	local records = minetest.deserialize(
		storage:get_string("active_fields")) or {}
	local key = minetest.pos_to_string(pos)
	records[key] = {
		x = pos.x, y = pos.y, z = pos.z,
		radius = radius,
	}
	storage:set_string("active_fields",
		minetest.serialize(records))
end

--- Clear an active field record from mod storage.
function lazarus_space.clear_field_record(pos)
	local storage = lazarus_space.mod_storage
	local records = minetest.deserialize(
		storage:get_string("active_fields")) or {}
	local key = minetest.pos_to_string(pos)
	if records[key] then
		records[key] = nil
		storage:set_string("active_fields",
			minetest.serialize(records))
	end
end

--- Cold collapse: teardown a field from persisted state only.
--- Used on startup when active_fields table is empty.
local function cold_collapse(pos, radius)
	minetest.log("action",
		"Lazarus Space: cold collapse at "
		.. minetest.pos_to_string(pos)
		.. " radius " .. radius)

	-- Destroy the continuum disrupter device.
	minetest.set_node(pos, {name = "air"})

	-- Clean up field nodes
	local stats = cleanup_field_nodes(pos, radius)

	minetest.log("action",
		"Lazarus Space: cold collapse complete — "
		.. stats.shell .. " shell, " .. stats.portal .. " portal, "
		.. stats.deleted .. " terrain deleted, " .. stats.kept .. " kept")
end

--- Recover any fields that were active when the server stopped.
--- Emerge the area first, then run cold collapse.
local function recover_fields_on_startup()
	local storage = lazarus_space.mod_storage
	local records = minetest.deserialize(
		storage:get_string("active_fields")) or {}

	if not next(records) then return end

	local count = 0
	for _ in pairs(records) do count = count + 1 end
	minetest.log("action",
		"Lazarus Space: found " .. count
		.. " active field(s) to recover")

	for key, rec in pairs(records) do
		local pos = {x = rec.x, y = rec.y, z = rec.z}
		local radius = rec.radius

		-- Force-load the area around the field.
		local emerge_min = vector.subtract(pos, radius + 2)
		local emerge_max = vector.add(pos, radius + 2)

		minetest.emerge_area(emerge_min, emerge_max,
			function(blockpos, action,
					calls_remaining, param)
				if calls_remaining > 0 then return end

				-- Area fully loaded — run cold collapse.
				cold_collapse(param.pos, param.radius)

				-- Clear the record.
				lazarus_space.clear_field_record(param.pos)

				minetest.log("action",
					"Lazarus Space: startup recovery"
					.. " complete at "
					.. minetest.pos_to_string(param.pos))
			end,
			{pos = pos, radius = radius})
	end
end

-- ============================================================
-- PLAYER DISCONNECT COLLAPSE
-- ============================================================

minetest.register_on_leaveplayer(function(player)
	if not next(lazarus_space.active_fields) then return end

	-- Get remaining connected players (excluding the one leaving).
	local leaving_name = player:get_player_name()
	local remaining = {}
	for _, p in ipairs(minetest.get_connected_players()) do
		if p:get_player_name() ~= leaving_name then
			remaining[#remaining + 1] = p
		end
	end

	local to_collapse = {}
	for hash, field in pairs(lazarus_space.active_fields) do
		local has_player = false
		for _, p in ipairs(remaining) do
			local d = vector.distance(p:get_pos(), field.pos)
			if d <= field.radius then
				has_player = true
				break
			end
		end
		if not has_player then
			to_collapse[#to_collapse + 1] = field.pos
		end
	end

	for _, fpos in ipairs(to_collapse) do
		lazarus_space.teardown_field(fpos)
	end
end)

-- ============================================================
-- SERVER SHUTDOWN COLLAPSE
-- ============================================================

minetest.register_on_shutdown(function()
	-- Collapse all active fields on clean shutdown.
	local to_collapse = {}
	for hash, field in pairs(lazarus_space.active_fields) do
		to_collapse[#to_collapse + 1] = vector.new(field.pos)
	end

	for _, fpos in ipairs(to_collapse) do
		lazarus_space.teardown_field(fpos)
	end

	-- Clear any remaining mod storage records as safety net.
	lazarus_space.mod_storage:set_string("active_fields", "")

	if #to_collapse > 0 then
		minetest.log("action",
			"Lazarus Space: shutdown — collapsed "
			.. #to_collapse .. " active field(s)")
	end
end)

-- ============================================================
-- MOD LOAD HOOKS: ABM, NODE TIMER, AND ENTITY PATCHING
-- ============================================================

minetest.register_on_mods_loaded(function()

	-- Recover any fields left active from a previous session.
	recover_fields_on_startup()

	-- Universal ABM suppression.
	for _, abm_def in ipairs(minetest.registered_abms) do
		local original_action = abm_def.action
		if original_action then
			abm_def.action = function(pos, node,
					active_object_count,
					active_object_count_wider)
				if lazarus_space.pos_in_field(pos) then
					return
				end
				return original_action(pos, node,
					active_object_count,
					active_object_count_wider)
			end
		end
	end


	-- Universal node timer suppression.
	-- Skip all jumpdrive nodes (including jumpdrive:warp_device)
	-- to prevent interference with portal trigger interaction.
	for name, def in pairs(minetest.registered_nodes) do
		if def.on_timer and not name:find("^jumpdrive:") then
			local original_on_timer = def.on_timer
			minetest.override_item(name, {
				on_timer = function(pos, elapsed)
					if lazarus_space.pos_in_field(pos) then
						return true
					end
					return original_on_timer(pos, elapsed)
				end,
			})
		end
	end

	-- Reactor core on_dig override: transmute to decaying uranium
	-- when dug inside an active field.
	for _, core_name in ipairs(REACTOR_CORES) do
		local core_def = minetest.registered_nodes[core_name]
		if core_def then
			local original_on_dig = core_def.on_dig
			minetest.override_item(core_name, {
				on_dig = function(pos, node, digger)
					if lazarus_space.pos_in_field(pos) then
						-- Inside active field: transmute
						-- to decaying uranium block.
						minetest.set_node(pos, {name =
							"lazarus_space:decaying_uranium"})
						minetest.log("action",
							"Lazarus Space: reactor core"
							.. " transmuted at "
							.. minetest.pos_to_string(pos))
						return true
					end
					-- Outside field: normal dig behavior.
					if original_on_dig then
						return original_on_dig(
							pos, node, digger)
					end
					return minetest.node_dig(
						pos, node, digger)
				end,
			})
			minetest.log("action",
				"Lazarus Space: reactor core on_dig"
				.. " override installed for "
				.. core_name)
		end
	end

	-- Entity on_step monkey-patching.
	for name, def in pairs(minetest.registered_entities) do
		local original_on_step = def.on_step
		if original_on_step then
			def.on_step = function(self, dtime, moveresult)
				if self.stasis_frozen then
					local obj = self.object
					obj:set_velocity({x = 0, y = 0, z = 0})
					obj:set_acceleration(
						{x = 0, y = 0, z = 0})
					return
				end
				return original_on_step(
					self, dtime, moveresult)
			end
		else
			-- Entities without on_step still need stasis.
			def.on_step = function(self, dtime, moveresult)
				if self.stasis_frozen then
					local obj = self.object
					obj:set_velocity({x = 0, y = 0, z = 0})
					obj:set_acceleration(
						{x = 0, y = 0, z = 0})
				end
			end
		end
	end
end)
