-- Lazarus Space: Continuum Disrupter and Portal Opening
-- End-game HV Technic mod with multi-step ritual gameplay.

lazarus_space = {}
lazarus_space.active_fields = {}
lazarus_space.charging_devices = {}
lazarus_space.CHARGE_REQUIRED = 168000
lazarus_space.POWER_DEMAND = 36000
lazarus_space.mod_storage = minetest.get_mod_storage()

--- Check if a node name is any disrupted space variant.
function lazarus_space.is_disrupted_space(name)
	if name == "lazarus_space:disrupted_space" then return true end
	return name:find("^lazarus_space:disrupted_space_%d+$") ~= nil
end

--- Check if a node name is any portal variant.
function lazarus_space.is_portal(name)
	if name == "lazarus_space:lazarus_portal" then return true end
	return name:find("^lazarus_space:portal_") ~= nil
end

local modpath = minetest.get_modpath("lazarus_space")

dofile(modpath .. "/formspec.lua")
dofile(modpath .. "/field.lua")
dofile(modpath .. "/nodes.lua")
dofile(modpath .. "/reactor.lua")
dofile(modpath .. "/guide.lua")
dofile(modpath .. "/portal.lua")
dofile(modpath .. "/portal_guide.lua")
