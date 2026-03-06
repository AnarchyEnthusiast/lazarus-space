-- Lazarus Space: Magnetic Fusion Reactor
-- Tiered multiblock structures (Tier 1: 9x9x5, Tier 2: 13x13x5, Tier 3: 17x17x5)
-- with jump start sequence and power output.

-- ============================================================
-- CONSTANTS
-- ============================================================

local FUEL_ITEM = "technic:uranium_fuel"
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
-- MULTIBLOCK STRUCTURE DEFINITIONS (3 tiers)
-- ============================================================
-- Offsets relative to the pole_corrector at (0,0,0).
-- Floor at y=-2, Roof at y=+2, middle layers y=-1,0,+1.

local PF  = "lazarus_space:pole_field"
local TF  = "lazarus_space:toroid_field"
local PLF = "lazarus_space:plasma_field"
local PLC = "lazarus_space:plasma_field_corner"
local PC  = "lazarus_space:pole_corrector"
local SB  = "default:steelblock"
local AIR = "air"

-- ---- Tier 1 structure: 9x9x5 (157 entries) ----
local STRUCTURE_T1 = {}
do
	local function S(dx, dy, dz, node)
		STRUCTURE_T1[#STRUCTURE_T1+1] = {x=dx, y=dy, z=dz, node=node}
	end
	-- FLOOR (y = -2)
	S(-4,-2,-4, PF); S(-3,-2,-4, PF); S(-2,-2,-4, PF); S(-1,-2,-4, PF)
	S( 0,-2,-4, PF); S( 1,-2,-4, PF); S( 2,-2,-4, PF); S( 3,-2,-4, PF); S( 4,-2,-4, PF)
	S(-4,-2,-3, PF); S(-3,-2,-3, SB); S( 0,-2,-3, SB); S( 3,-2,-3, SB); S( 4,-2,-3, PF)
	S(-4,-2,-2, PF); S( 0,-2,-2, SB); S( 4,-2,-2, PF)
	S(-4,-2,-1, PF); S( 0,-2,-1, SB); S( 4,-2,-1, PF)
	S(-4,-2, 0, PF); S(-3,-2, 0, SB); S(-2,-2, 0, SB); S(-1,-2, 0, SB)
	S( 0,-2, 0, SB); S( 1,-2, 0, SB); S( 2,-2, 0, SB); S( 3,-2, 0, SB); S( 4,-2, 0, PF)
	S(-4,-2, 1, PF); S( 0,-2, 1, SB); S( 4,-2, 1, PF)
	S(-4,-2, 2, PF); S( 0,-2, 2, SB); S( 4,-2, 2, PF)
	S(-4,-2, 3, PF); S(-3,-2, 3, SB); S( 0,-2, 3, SB); S( 3,-2, 3, SB); S( 4,-2, 3, PF)
	S(-4,-2, 4, PF); S(-3,-2, 4, PF); S(-2,-2, 4, PF); S(-1,-2, 4, PF)
	S( 0,-2, 4, PF); S( 1,-2, 4, PF); S( 2,-2, 4, PF); S( 3,-2, 4, PF); S( 4,-2, 4, PF)
	-- WALL (lower) (y = -1)
	S(-3,-1,-3, SB); S( 0,-1,-3, TF); S( 3,-1,-3, SB)
	S( 0,-1,-2, TF); S( 0,-1,-1, TF)
	S(-3,-1, 0, TF); S(-2,-1, 0, TF); S(-1,-1, 0, TF); S( 0,-1, 0, AIR)
	S( 1,-1, 0, TF); S( 2,-1, 0, TF); S( 3,-1, 0, TF)
	S( 0,-1, 1, TF); S( 0,-1, 2, TF)
	S(-3,-1, 3, SB); S( 0,-1, 3, TF); S( 3,-1, 3, SB)
	-- MIDDLE (y = 0)
	S(-3, 0,-3, SB); S(-2, 0,-3, SB); S( 0, 0,-3, TF); S( 2, 0,-3, SB); S( 3, 0,-3, SB)
	S(-3, 0,-2, SB); S(-2, 0,-2, PLC); S(-1, 0,-2, PLF); S( 0, 0,-2, PLF)
	S( 1, 0,-2, PLF); S( 2, 0,-2, PLC); S( 3, 0,-2, SB)
	S(-2, 0,-1, PLF); S( 0, 0,-1, TF); S( 2, 0,-1, PLF)
	S(-3, 0, 0, TF); S(-2, 0, 0, PLF); S(-1, 0, 0, TF); S( 0, 0, 0, PC)
	S( 1, 0, 0, TF); S( 2, 0, 0, PLF); S( 3, 0, 0, TF)
	S(-2, 0, 1, PLF); S( 0, 0, 1, TF); S( 2, 0, 1, PLF)
	S(-3, 0, 2, SB); S(-2, 0, 2, PLC); S(-1, 0, 2, PLF); S( 0, 0, 2, PLF)
	S( 1, 0, 2, PLF); S( 2, 0, 2, PLC); S( 3, 0, 2, SB)
	S(-3, 0, 3, SB); S(-2, 0, 3, SB); S( 0, 0, 3, TF); S( 2, 0, 3, SB); S( 3, 0, 3, SB)
	-- WALL (upper) (y = 1)
	S(-3, 1,-3, SB); S( 0, 1,-3, TF); S( 3, 1,-3, SB)
	S( 0, 1,-2, TF); S( 0, 1,-1, TF)
	S(-3, 1, 0, TF); S(-2, 1, 0, TF); S(-1, 1, 0, TF); S( 0, 1, 0, AIR)
	S( 1, 1, 0, TF); S( 2, 1, 0, TF); S( 3, 1, 0, TF)
	S( 0, 1, 1, TF); S( 0, 1, 2, TF)
	S(-3, 1, 3, SB); S( 0, 1, 3, TF); S( 3, 1, 3, SB)
	-- ROOF (y = 2)
	S(-4, 2,-4, PF); S(-3, 2,-4, PF); S(-2, 2,-4, PF); S(-1, 2,-4, PF)
	S( 0, 2,-4, PF); S( 1, 2,-4, PF); S( 2, 2,-4, PF); S( 3, 2,-4, PF); S( 4, 2,-4, PF)
	S(-4, 2,-3, PF); S(-3, 2,-3, SB); S( 3, 2,-3, SB); S( 4, 2,-3, PF)
	S(-4, 2,-2, PF); S( 4, 2,-2, PF)
	S(-4, 2,-1, PF); S( 4, 2,-1, PF)
	S(-4, 2, 0, PF); S( 0, 2, 0, AIR); S( 4, 2, 0, PF)
	S(-4, 2, 1, PF); S( 4, 2, 1, PF)
	S(-4, 2, 2, PF); S( 4, 2, 2, PF)
	S(-4, 2, 3, PF); S(-3, 2, 3, SB); S( 3, 2, 3, SB); S( 4, 2, 3, PF)
	S(-4, 2, 4, PF); S(-3, 2, 4, PF); S(-2, 2, 4, PF); S(-1, 2, 4, PF)
	S( 0, 2, 4, PF); S( 1, 2, 4, PF); S( 2, 2, 4, PF); S( 3, 2, 4, PF); S( 4, 2, 4, PF)
end

-- ---- Tier 2 structure: 13x13x5 (317 entries) ----
local STRUCTURE_T2 = {}
do
	local function S(dx, dy, dz, node)
		STRUCTURE_T2[#STRUCTURE_T2+1] = {x=dx, y=dy, z=dz, node=node}
	end
	-- FLOOR (y = -2): pole_field border, steelblock interior grid
	for i = -6, 6 do S(i,-2,-6, PF); S(i,-2, 6, PF) end
	for i = -5, 5 do S(-6,-2, i, PF); S( 6,-2, i, PF) end
	S( 0,-2, 0, SB)
	for i = -5, 5 do S(i,-2, 0, SB) end
	for i = -5, 5 do if i ~= 0 then S(0,-2, i, SB) end end
	for _, c in ipairs({{-5,-5},{-5,5},{5,-5},{5,5}}) do S(c[1],-2,c[2], SB) end
	S(-1,-2,-1, SB); S( 0,-2,-1, SB); S( 1,-2,-1, SB)
	S(-1,-2, 1, SB); S( 0,-2, 1, SB); S( 1,-2, 1, SB)
	-- ROOF (y = +2)
	for i = -6, 6 do S(i, 2,-6, PF); S(i, 2, 6, PF) end
	for i = -5, 5 do S(-6, 2, i, PF); S( 6, 2, i, PF) end
	for _, c in ipairs({{-5,-5},{-5,5},{5,-5},{5,5}}) do S(c[1], 2,c[2], SB) end
	S(0, 2, 0, AIR)
	-- MIDDLE LAYERS y=-1 and y=+1 (symmetric)
	for _, dy in ipairs({-1, 1}) do
		for _, c in ipairs({{-5,-5},{-5,5},{5,-5},{5,5}}) do S(c[1],dy,c[2], SB) end
		for _, dz in ipairs({-5,-4,-3, 3,4,5}) do
			S(-2,dy,dz, TF); S(0,dy,dz, TF); S(2,dy,dz, TF)
		end
		S(-5,dy,-2, TF); S(-4,dy,-2, TF); S(-3,dy,-2, TF)
		S( 3,dy,-2, TF); S( 4,dy,-2, TF); S( 5,dy,-2, TF)
		S(-5,dy, 0, TF); S(-4,dy, 0, TF); S(-3,dy, 0, TF)
		S( 3,dy, 0, TF); S( 4,dy, 0, TF); S( 5,dy, 0, TF)
		S(-5,dy, 2, TF); S(-4,dy, 2, TF); S(-3,dy, 2, TF)
		S( 3,dy, 2, TF); S( 4,dy, 2, TF); S( 5,dy, 2, TF)
		S(-2,dy, 0, SB); S( 2,dy, 0, SB)
		S( 0,dy,-2, SB); S( 0,dy, 2, SB)
		S(-1,dy,-1, PF); S( 0,dy,-1, PF); S( 1,dy,-1, PF)
		S(-1,dy, 0, PF);                   S( 1,dy, 0, PF)
		S(-1,dy, 1, PF); S( 0,dy, 1, PF); S( 1,dy, 1, PF)
		S(0,dy, 0, AIR)
	end
	-- MIDDLE LAYER y=0: plasma ring, pole corrector
	S(-5, 0,-5, SB); S(-4, 0,-5, SB); S( 4, 0,-5, SB); S( 5, 0,-5, SB)
	S(-5, 0, 5, SB); S(-4, 0, 5, SB); S( 4, 0, 5, SB); S( 5, 0, 5, SB)
	S(-5, 0,-4, SB); S( 5, 0,-4, SB)
	S(-5, 0, 4, SB); S( 5, 0, 4, SB)
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
	S(-3, 0,-4, PLC); S( 4, 0,-4, PLC); S(-4, 0, 3, PLC); S( 2, 0, 4, PLC)
	S(-2, 0,-5, TF); S( 0, 0,-5, TF); S( 2, 0,-5, TF)
	S(-2, 0,-3, TF); S( 0, 0,-3, TF); S( 2, 0,-3, TF)
	S(-5, 0,-2, TF); S(-3, 0,-2, TF); S( 3, 0,-2, TF); S( 5, 0,-2, TF)
	S(-5, 0, 0, TF); S(-3, 0, 0, TF); S( 3, 0, 0, TF); S( 5, 0, 0, TF)
	S(-5, 0, 2, TF); S(-3, 0, 2, TF); S( 3, 0, 2, TF); S( 5, 0, 2, TF)
	S(-2, 0, 3, TF); S( 0, 0, 3, TF); S( 2, 0, 3, TF)
	S(-2, 0, 5, TF); S( 0, 0, 5, TF); S( 2, 0, 5, TF)
	S(-2, 0, 0, SB); S( 2, 0, 0, SB); S( 0, 0,-2, SB); S( 0, 0, 2, SB)
	S(-1, 0,-1, PF); S( 0, 0,-1, PF); S( 1, 0,-1, PF)
	S(-1, 0, 0, PF); S( 0, 0, 0, PC); S( 1, 0, 0, PF)
	S(-1, 0, 1, PF); S( 0, 0, 1, PF); S( 1, 0, 1, PF)
end

-- ---- Tier 3 structure: 17x17x5 (541 entries) ----
local STRUCTURE_T3 = {}
do
	local function S(dx, dy, dz, node)
		STRUCTURE_T3[#STRUCTURE_T3+1] = {x=dx, y=dy, z=dz, node=node}
	end
	-- FLOOR (y = -2)
	for i = -8, 8 do S(i,-2,-8, PF); S(i,-2, 8, PF) end
	for i = -7, 7 do S(-8,-2, i, PF); S( 8,-2, i, PF) end
	-- Inner steelblock border (y=-2, z=-7 and z=7 rows)
	for i = -7, 7 do S(i,-2,-7, SB); S(i,-2, 7, SB) end
	for i = -6, 6 do S(-7,-2, i, SB); S( 7,-2, i, SB) end
	-- Steelblock spines
	for i = -6, 6 do S(i,-2, 0, SB) end
	for i = -6, 6 do if i ~= 0 then S(0,-2, i, SB) end end
	S( 0,-2, 0, SB)
	-- 3x3 center ring
	S(-1,-2,-1, SB); S( 0,-2,-1, SB); S( 1,-2,-1, SB)
	S(-1,-2, 1, SB); S( 0,-2, 1, SB); S( 1,-2, 1, SB)
	-- WALL layers y=-1 and y=+1 (symmetric)
	for _, dy in ipairs({-1, 1}) do
		S(-7,dy,-7, SB); S(-6,dy,-7, SB); S( 6,dy,-7, SB); S( 7,dy,-7, SB)
		S(-7,dy,-6, SB); S( 7,dy,-6, SB)
		S(-7,dy, 6, SB); S( 7,dy, 6, SB)
		S(-7,dy, 7, SB); S(-6,dy, 7, SB); S( 6,dy, 7, SB); S( 7,dy, 7, SB)
		-- Toroid walls: N/S arms (5 columns: x=-4,-2,0,+2,+4)
		for _, dz in ipairs({-7,-6,-5, 5,6,7}) do
			S(-4,dy,dz, TF); S(-2,dy,dz, TF); S(0,dy,dz, TF)
			S( 2,dy,dz, TF); S( 4,dy,dz, TF)
		end
		-- E/W arms
		S(-7,dy,-4, TF); S(-6,dy,-4, TF); S(-5,dy,-4, TF)
		S( 5,dy,-4, TF); S( 6,dy,-4, TF); S( 7,dy,-4, TF)
		S(-7,dy,-2, TF); S(-6,dy,-2, TF); S(-5,dy,-2, TF)
		S( 5,dy,-2, TF); S( 6,dy,-2, TF); S( 7,dy,-2, TF)
		S(-7,dy, 0, TF); S(-6,dy, 0, TF); S(-5,dy, 0, TF)
		S( 5,dy, 0, TF); S( 6,dy, 0, TF); S( 7,dy, 0, TF)
		S(-7,dy, 2, TF); S(-6,dy, 2, TF); S(-5,dy, 2, TF)
		S( 5,dy, 2, TF); S( 6,dy, 2, TF); S( 7,dy, 2, TF)
		S(-7,dy, 4, TF); S(-6,dy, 4, TF); S(-5,dy, 4, TF)
		S( 5,dy, 4, TF); S( 6,dy, 4, TF); S( 7,dy, 4, TF)
		-- Steel block transitions
		S(-4,dy, 0, SB); S(-3,dy, 0, SB); S(-2,dy, 0, SB)
		S( 2,dy, 0, SB); S( 3,dy, 0, SB); S( 4,dy, 0, SB)
		S( 0,dy,-4, SB); S( 0,dy,-3, SB); S( 0,dy,-2, SB)
		S( 0,dy, 2, SB); S( 0,dy, 3, SB); S( 0,dy, 4, SB)
		-- Center 3x3: pole field ring with air
		S(-1,dy,-1, PF); S( 0,dy,-1, PF); S( 1,dy,-1, PF)
		S(-1,dy, 0, PF);                   S( 1,dy, 0, PF)
		S(-1,dy, 1, PF); S( 0,dy, 1, PF); S( 1,dy, 1, PF)
		S(0,dy, 0, AIR)
	end
	-- MIDDLE LAYER y=0: plasma ring, pole corrector
	S(-7, 0,-7, SB); S(-6, 0,-7, SB); S( 6, 0,-7, SB); S( 7, 0,-7, SB)
	S(-7, 0,-6, SB); S( 7, 0,-6, SB)
	S(-7, 0, 6, SB); S( 7, 0, 6, SB)
	S(-7, 0, 7, SB); S(-6, 0, 7, SB); S( 6, 0, 7, SB); S( 7, 0, 7, SB)
	-- Plasma field ring
	S(-6, 0,-6, PLC)
	S(-5, 0,-6, PLF); S(-4, 0,-6, PLF); S(-3, 0,-6, PLF); S(-2, 0,-6, PLF)
	S(-1, 0,-6, PLF); S( 0, 0,-6, PLF); S( 1, 0,-6, PLF); S( 2, 0,-6, PLF)
	S( 3, 0,-6, PLF); S( 4, 0,-6, PLF); S( 5, 0,-6, PLF)
	S( 6, 0,-6, PLC)
	S(-6, 0,-5, PLF); S( 6, 0,-5, PLF)
	S(-6, 0,-4, PLF); S( 6, 0,-4, PLF)
	S(-6, 0,-3, PLF); S( 6, 0,-3, PLF)
	S(-6, 0,-2, PLF); S( 6, 0,-2, PLF)
	S(-6, 0,-1, PLF); S( 6, 0,-1, PLF)
	S(-6, 0, 0, PLF); S( 6, 0, 0, PLF)
	S(-6, 0, 1, PLF); S( 6, 0, 1, PLF)
	S(-6, 0, 2, PLF); S( 6, 0, 2, PLF)
	S(-6, 0, 3, PLF); S( 6, 0, 3, PLF)
	S(-6, 0, 4, PLF); S( 6, 0, 4, PLF)
	S(-6, 0, 5, PLF); S( 6, 0, 5, PLF)
	S(-6, 0, 6, PLC)
	S(-5, 0, 6, PLF); S(-4, 0, 6, PLF); S(-3, 0, 6, PLF); S(-2, 0, 6, PLF)
	S(-1, 0, 6, PLF); S( 0, 0, 6, PLF); S( 1, 0, 6, PLF); S( 2, 0, 6, PLF)
	S( 3, 0, 6, PLF); S( 4, 0, 6, PLF); S( 5, 0, 6, PLF)
	S( 6, 0, 6, PLC)
	-- Toroid walls inside plasma ring
	S(-4, 0,-7, TF); S(-2, 0,-7, TF); S( 0, 0,-7, TF); S( 2, 0,-7, TF); S( 4, 0,-7, TF)
	S(-4, 0,-5, TF); S(-2, 0,-5, TF); S( 0, 0,-5, TF); S( 2, 0,-5, TF); S( 4, 0,-5, TF)
	S(-7, 0,-4, TF); S(-5, 0,-4, TF); S( 5, 0,-4, TF); S( 7, 0,-4, TF)
	S(-7, 0,-2, TF); S(-5, 0,-2, TF); S( 5, 0,-2, TF); S( 7, 0,-2, TF)
	S(-7, 0, 0, TF); S(-5, 0, 0, TF); S( 5, 0, 0, TF); S( 7, 0, 0, TF)
	S(-7, 0, 2, TF); S(-5, 0, 2, TF); S( 5, 0, 2, TF); S( 7, 0, 2, TF)
	S(-7, 0, 4, TF); S(-5, 0, 4, TF); S( 5, 0, 4, TF); S( 7, 0, 4, TF)
	S(-4, 0, 5, TF); S(-2, 0, 5, TF); S( 0, 0, 5, TF); S( 2, 0, 5, TF); S( 4, 0, 5, TF)
	S(-4, 0, 7, TF); S(-2, 0, 7, TF); S( 0, 0, 7, TF); S( 2, 0, 7, TF); S( 4, 0, 7, TF)
	-- Steel block transitions
	S(-4, 0, 0, SB); S(-3, 0, 0, SB); S(-2, 0, 0, SB)
	S( 2, 0, 0, SB); S( 3, 0, 0, SB); S( 4, 0, 0, SB)
	S( 0, 0,-4, SB); S( 0, 0,-3, SB); S( 0, 0,-2, SB)
	S( 0, 0, 2, SB); S( 0, 0, 3, SB); S( 0, 0, 4, SB)
	-- Center 3x3: pole field ring with pole corrector
	S(-1, 0,-1, PF); S( 0, 0,-1, PF); S( 1, 0,-1, PF)
	S(-1, 0, 0, PF); S( 0, 0, 0, PC); S( 1, 0, 0, PF)
	S(-1, 0, 1, PF); S( 0, 0, 1, PF); S( 1, 0, 1, PF)
	-- ROOF (y = 2)
	for i = -8, 8 do S(i, 2,-8, PF); S(i, 2, 8, PF) end
	for i = -7, 7 do S(-8, 2, i, PF); S( 8, 2, i, PF) end
	-- Inner steelblock border on roof
	S(-7, 2,-7, SB); S(-6, 2,-7, SB); S(-5, 2,-7, SB)
	S( 5, 2,-7, SB); S( 6, 2,-7, SB); S( 7, 2,-7, SB)
	S(-7, 2,-6, SB); S( 7, 2,-6, SB)
	S(-7, 2,-5, SB); S( 7, 2,-5, SB)
	S(-7, 2, 5, SB); S( 7, 2, 5, SB)
	S(-7, 2, 6, SB); S( 7, 2, 6, SB)
	S(-7, 2, 7, SB); S(-6, 2, 7, SB); S(-5, 2, 7, SB)
	S( 5, 2, 7, SB); S( 6, 2, 7, SB); S( 7, 2, 7, SB)
	S( 0, 2, 0, AIR)
end

-- ============================================================
-- TIER DEFINITIONS
-- ============================================================

local TIERS = {
	{
		name = "Tier 1",
		power_output = 140000,
		jumpstart_energy = 45000,
		fuel_slots = 3,
		fuel_duration = 8 * 60 * 60,
		charge_time = 5,
		structure = STRUCTURE_T1,
	},
	{
		name = "Tier 2",
		power_output = 240000,
		jumpstart_energy = 85000,
		fuel_slots = 6,
		fuel_duration = 8 * 60 * 60,
		charge_time = 5,
		structure = STRUCTURE_T2,
	},
	{
		name = "Tier 3",
		power_output = 600000,
		jumpstart_energy = 200000,
		fuel_slots = 12,
		fuel_duration = 8 * 60 * 60,
		charge_time = 5,
		structure = STRUCTURE_T3,
	},
}

--- Helper: get tier table from metadata, returns tier table or nil
local function get_tier(pos)
	local meta = minetest.get_meta(pos)
	local idx = meta:get_int("reactor_tier")
	return TIERS[idx], idx
end

-- ============================================================
-- STRUCTURE VALIDATION
-- ============================================================

--- Find the pole corrector near a given position.
local function find_pole_corrector(pos)
	local range = 10 -- large enough for tier 3 (17x17)
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
function lazarus_space.validate_reactor_structure(panel_pos, tier_index)
	local tier = TIERS[tier_index]
	if not tier then
		return false, {"Invalid reactor tier."}
	end

	local center = find_pole_corrector(panel_pos)
	if not center then
		return false, {"No pole corrector detected nearby."}
	end

	local errors = {}

	-- Check each defined structure position
	for _, entry in ipairs(tier.structure) do
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

-- Helper: format seconds as h:mm:ss or m:ss
local function format_time(seconds)
	local hours = math.floor(seconds / 3600)
	local mins = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, mins, secs)
	else
		return string.format("%d:%02d", mins, secs)
	end
end

-- Helper: style[] + button[] for colored buttons (no border boxes)
local function styled_btn(fs, x, y, w, h, name, label, bg, bg_hover, bg_press, text)
	text = text or "#ffffff"
	bg_hover = bg_hover or bg
	bg_press = bg_press or bg
	fs = fs .. "style[" .. name .. ";bgcolor=" .. bg
		.. ";bgcolor_hovered=" .. bg_hover
		.. ";bgcolor_pressed=" .. bg_press
		.. ";textcolor=" .. text .. "]"
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

local function build_tier_select_formspec()
	local fs = "size[9,5.5]"
		.. "bgcolor[#080808;true]"
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[2.2,0.2;Magnetic Fusion Reactor — Select Tier]"
	for i, tier in ipairs(TIERS) do
		local y = 0.8 + (i - 1) * 1.4
		fs = fs .. "box[0," .. y .. ";8.8,1.2;#0d0d1a]"
		fs = fs .. "label[0.3," .. string.format("%.1f", y + 0.15) .. ";"
			.. minetest.colorize("#00ccaa", tier.name) .. "]"
		fs = fs .. "label[0.3," .. string.format("%.1f", y + 0.55) .. ";"
			.. tier.power_output .. " EU  |  "
			.. tier.fuel_slots .. " rods  |  "
			.. tier.jumpstart_energy .. " EU jumpstart]"
		fs = styled_btn(fs, 7.0, y + 0.2, 1.6, 0.7, "select_tier_" .. i, "Select",
			"#00ccaa", "#00ddbb", "#009988")
	end
	return fs
end

local function build_unchecked_formspec(tier_index)
	local fs = "size[9,4.5]"
		.. "bgcolor[#080808;true]"
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[3.4,0.2;Magnetic Fusion Reactor]"
		.. "box[0,1;8.8,0.6;#0a0a15]"
	if tier_index and TIERS[tier_index] then
		fs = fs .. "label[3.0,1.1;" .. TIERS[tier_index].name
			.. " — Structure Check Required]"
	else
		fs = fs .. "label[3.4,1.1;Structure Check Required]"
	end
	fs = styled_btn(fs, 2.5, 2.2, 4, 0.7, "check_structure", "Check Structure",
		"#00ccaa", "#00ddbb", "#009988")
	fs = styled_btn(fs, 2.5, 3.2, 4, 0.7, "change_tier", "Change Tier",
		"#2a2a3e", "#3a3a4e", "#1a1a2e", "#aaaaaa")
	return fs
end

local function build_error_formspec(errors)
	local fs = "size[9,7]"
		.. "bgcolor[#080808;true]"
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[3.4,0.2;Magnetic Fusion Reactor]"
		.. "box[0,1;8.8,0.6;#0a0a15]"
		.. "label[0.3,1.1;" .. minetest.colorize("#ff3333", "Structure Check Failed") .. "]"

	local y = 2.0
	for i, err in ipairs(errors) do
		if i > 6 then break end
		fs = fs .. "label[0.5," .. y .. ";" .. minetest.colorize("#ff8888",
			"- " .. minetest.formspec_escape(err)) .. "]"
		y = y + 0.5
	end

	fs = styled_btn(fs, 2.5, y + 0.3, 4, 0.7, "check_structure", "Retry Check",
		"#00ccaa", "#00ddbb", "#009988")
	return fs
end

local function build_reactor_formspec(pos)
	local meta = minetest.get_meta(pos)
	local tier, tier_index = get_tier(pos)
	if not tier then return build_tier_select_formspec() end
	local state = meta:get_string("reactor_state")
	if state == "" then state = "standby" end
	local fuel_time = meta:get_int("fuel_time")
	-- Count fuel rods and filled slots
	local inv = meta:get_inventory()
	local fuel_count = 0
	local filled_slots = 0
	for i = 1, tier.fuel_slots do
		local stack = inv:get_stack("fuel", i)
		if stack:get_name() == FUEL_ITEM and stack:get_count() > 0 then
			fuel_count = fuel_count + stack:get_count()
			filled_slots = filled_slots + 1
		end
	end

	-- Check jumpstarter power
	local js_pos = find_neighbor(pos, "lazarus_space:plasma_jumpstarter")
	local hv_ready = false
	if js_pos then
		local js_meta = minetest.get_meta(js_pos)
		local stored = js_meta:get_int("stored_energy")
		if stored >= tier.jumpstart_energy then
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

	-- Jump start progress (smooth: js_elapsed is a float updated every 0.1s)
	local js_progress = 0
	if state == "jump_starting" then
		local js_elapsed = meta:get_float("js_elapsed")
		js_progress = math.min(100, math.floor(js_elapsed / tier.charge_time * 100))
	elseif state == "jump_started" or state == "active" then
		js_progress = 100
	end

	-- Dynamic fuel section height: T1/T2 single row, T3 two rows
	local fuel_box_h = (tier.fuel_slots <= 6) and 1.8 or 3.0
	local fuel_offset = fuel_box_h - 1.8  -- 0 for T1/T2, 1.2 for T3
	local form_h = 12.5 + fuel_offset

	local fs = "size[9," .. form_h .. "]"
		.. "bgcolor[#080808;true]"
		.. "listcolors[#1a1a2e;#2a2a3e;#333355]"
		-- Header
		.. "box[0,0;8.8,0.8;#1a1a2e]"
		.. "label[3.4,0.2;Magnetic Fusion Reactor]"
		-- Status
		.. "box[0,1;8.8,0.6;#0a0a15]"
		.. "label[0.3,1.1;Status: " .. status_text .. "]"
	-- Progress bar with gradient
	fs = gradient_bar(fs, 0.5, 1.8, 7.8, 0.5, js_progress)
	fs = fs .. "label[8.5,1.9;" .. js_progress .. "%]"

	-- Fuel section (variable layout per tier)
	fs = fs .. "box[0,2.5;8.8," .. fuel_box_h .. ";#0d0d1a]"
		.. "label[0.3,2.6;Fuel Rods (" .. fuel_count .. "/" .. tier.fuel_slots .. ")]"
	if tier.fuel_slots <= 3 then
		fs = fs .. "list[context;fuel;2.5,3;3,1;]"
	elseif tier.fuel_slots <= 6 then
		fs = fs .. "list[context;fuel;1.5,3;6,1;]"
	else
		-- Two rows of 6, second row starts at slot index 6
		fs = fs .. "list[context;fuel;1.5,3;6,1;]"
			.. "list[context;fuel;1.5,4.25;6,1;6]"
	end

	-- Power section (offset for T3's taller fuel box)
	fs = fs .. "box[0," .. (4.5 + fuel_offset) .. ";8.8,1.2;#0d0d1a]"
	if hv_ready then
		fs = fs .. "label[0.3," .. (4.6 + fuel_offset) .. ";HV Power: " .. minetest.colorize("#00ff66", "READY") .. "]"
	else
		fs = fs .. "label[0.3," .. (4.6 + fuel_offset) .. ";HV Power: " .. minetest.colorize("#ff3333", "INSUFFICIENT") .. "]"
	end

	if state == "active" then
		-- Fuel remaining with gradient drain bar
		fs = fs .. "label[0.3," .. (5.8 + fuel_offset) .. ";Fuel Remaining: " .. format_time(fuel_time) .. "]"
		local fuel_pct = math.floor(fuel_time / tier.fuel_duration * 100)
		fs = gradient_bar(fs, 0.5, 6.3 + fuel_offset, 7.8, 0.4, fuel_pct)
	end

	-- Control buttons (offset for T3's taller fuel box)
	if state == "standby" then
		if hv_ready then
			fs = styled_btn(fs, 2.5, 5.8 + fuel_offset, 4, 0.7, "jump_start", "Jump Start",
				"#00ccaa", "#00ddbb", "#009988")
		else
			fs = styled_btn(fs, 2.5, 5.8 + fuel_offset, 4, 0.7, "jump_start_disabled",
				"Jump Start (HV not ready)", "#333333", "#333333", "#333333", "#666666")
		end
	elseif state == "jump_starting" then
		local js_elapsed = meta:get_float("js_elapsed")
		local js_remaining = math.max(0, tier.charge_time - js_elapsed)
		fs = fs .. "label[2.8," .. (5.9 + fuel_offset) .. ";" .. minetest.colorize("#ff8800",
			"Jump Starting... " .. string.format("%.1fs", js_remaining)) .. "]"
	elseif state == "jump_started" then
		local remaining = meta:get_int("remaining_fuel_time")
		if remaining > 0 then
			-- Resume with stored fuel time — no rods needed
			fs = styled_btn(fs, 1.5, 5.8 + fuel_offset, 6, 0.7, "resume", "Resume Reactor",
				"#00cc66", "#00dd77", "#009955")
		elseif filled_slots >= tier.fuel_slots then
			fs = styled_btn(fs, 1.5, 5.8 + fuel_offset, 6, 0.7, "inject", "Inject Fuel & Start",
				"#00cc66", "#00dd77", "#009955")
		else
			fs = styled_btn(fs, 1.5, 5.8 + fuel_offset, 6, 0.7, "inject_disabled",
				"Need 1 rod in each of " .. tier.fuel_slots .. " slots",
				"#333333", "#333333", "#333333", "#666666")
		end
	elseif state == "active" then
		fs = styled_btn(fs, 2.0, 7.0 + fuel_offset, 5, 0.7, "deactivate", "Deactivate Reactor",
			"#cc3333", "#dd4444", "#aa2222")
	end

	-- Player inventory (offset for T3's taller fuel box)
	fs = fs .. "list[current_player;main;0.5," .. (8 + fuel_offset) .. ";8,1;]"
		.. "list[current_player;main;0.5," .. (9.2 + fuel_offset) .. ";8,3;8]"
		.. "listring[context;fuel]"
		.. "listring[current_player;main]"

	return fs
end

-- ============================================================
-- CONTROL PANEL: on_receive_fields
-- ============================================================

local function panel_on_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)

	-- Tier selection
	for i = 1, #TIERS do
		if fields["select_tier_" .. i] then
			meta:set_int("reactor_tier", i)
			local inv = meta:get_inventory()
			inv:set_size("fuel", TIERS[i].fuel_slots)
			meta:set_string("formspec", build_unchecked_formspec(i))
			return
		end
	end

	if fields.change_tier then
		-- Only allow tier change before validation/running
		local state = meta:get_string("reactor_state")
		if state == "" or state == "standby" then
			meta:set_int("reactor_tier", 0)
			meta:set_string("reactor_state", "")
			meta:set_string("validated", "")
			meta:set_string("formspec", build_tier_select_formspec())
		end
		return
	end

	if fields.check_structure then
		local tier_index = meta:get_int("reactor_tier")
		if tier_index == 0 then
			meta:set_string("formspec", build_tier_select_formspec())
			return
		end
		local ok, result = lazarus_space.validate_reactor_structure(pos, tier_index)
		if ok then
			meta:set_string("reactor_state", "standby")
			meta:set_string("validated", "true")
			meta:set_string("center_x", tostring(result.x))
			meta:set_string("center_y", tostring(result.y))
			meta:set_string("center_z", tostring(result.z))
			local timer = minetest.get_node_timer(pos)
			timer:start(1)
			meta:set_string("formspec", build_reactor_formspec(pos))
		else
			meta:set_string("formspec", build_error_formspec(result))
		end
		return
	end

	if fields.jump_start then
		local tier = get_tier(pos)
		if not tier then return end
		local state = meta:get_string("reactor_state")
		if state ~= "standby" then return end

		local js_pos = find_neighbor(pos, "lazarus_space:plasma_jumpstarter")
		if not js_pos then return end
		local js_meta = minetest.get_meta(js_pos)
		if js_meta:get_int("stored_energy") < tier.jumpstart_energy then return end

		meta:set_string("reactor_state", "jump_starting")
		meta:set_float("js_elapsed", 0)

		local stored = js_meta:get_int("stored_energy")
		js_meta:set_int("stored_energy", math.max(0, stored - tier.jumpstart_energy))

		local timer = minetest.get_node_timer(pos)
		timer:start(0.1)
		meta:set_string("formspec", build_reactor_formspec(pos))
		return
	end

	if fields.inject then
		local tier = get_tier(pos)
		if not tier then return end
		local state = meta:get_string("reactor_state")
		if state ~= "jump_started" then return end

		local inv = meta:get_inventory()
		for i = 1, tier.fuel_slots do
			local stack = inv:get_stack("fuel", i)
			if stack:get_name() ~= FUEL_ITEM or stack:get_count() < 1 then
				return
			end
		end

		for i = 1, tier.fuel_slots do
			local stack = inv:get_stack("fuel", i)
			stack:take_item(1)
			inv:set_stack("fuel", i, stack)
		end

		meta:set_string("reactor_state", "active")
		meta:set_int("fuel_time", tier.fuel_duration)
		meta:set_int("display_accumulator", 0)
		local timer = minetest.get_node_timer(pos)
		timer:start(1)

		local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
		if po_pos then
			local po_meta = minetest.get_meta(po_pos)
			local otier = po_meta:get_string("output_tier")
			if otier == "" then otier = "HV" end
			po_meta:set_string("infotext", "Fusion Power Output - "
				.. tier.power_output .. " EU (" .. otier .. ")")
		end

		meta:set_string("formspec", build_reactor_formspec(pos))
		return
	end

	if fields.resume then
		local tier = get_tier(pos)
		if not tier then return end
		local state = meta:get_string("reactor_state")
		if state ~= "jump_started" then return end
		local remaining = meta:get_int("remaining_fuel_time")
		if remaining <= 0 then return end

		meta:set_string("reactor_state", "active")
		meta:set_int("fuel_time", remaining)
		meta:set_int("remaining_fuel_time", 0)
		meta:set_int("display_accumulator", 0)
		local timer = minetest.get_node_timer(pos)
		timer:start(1)

		local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
		if po_pos then
			local po_meta = minetest.get_meta(po_pos)
			local otier = po_meta:get_string("output_tier")
			if otier == "" then otier = "HV" end
			po_meta:set_string("infotext", "Fusion Power Output - "
				.. tier.power_output .. " EU (" .. otier .. ")")
		end

		meta:set_string("formspec", build_reactor_formspec(pos))
		return
	end

	if fields.deactivate then
		local state = meta:get_string("reactor_state")
		if state ~= "active" then return end

		-- Store remaining fuel time for later resume
		local ft = meta:get_int("fuel_time")
		meta:set_int("remaining_fuel_time", ft)

		-- Shut down gracefully to standby
		meta:set_string("reactor_state", "standby")
		meta:set_int("fuel_time", 0)
		meta:set_string("infotext", "Magnetic Fusion Reactor — Standby")

		-- Notify power output
		local po_pos = find_neighbor(pos, "lazarus_space:fusion_power_output")
		if po_pos then
			local po_meta = minetest.get_meta(po_pos)
			po_meta:set_string("infotext", "Fusion Power Output - Offline")
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
	local tier, tier_index = get_tier(pos)
	local state = meta:get_string("reactor_state")

	-- Periodic structure integrity check
	if meta:get_string("validated") == "true" and tier then
		local check_acc = meta:get_float("check_accumulator") + elapsed
		if check_acc >= STRUCTURE_CHECK_INTERVAL then
			check_acc = 0
			local ok = lazarus_space.validate_reactor_structure(pos, tier_index)
			if not ok then
				meta:set_string("validated", "")
				meta:set_string("reactor_state", "")
				meta:set_float("js_elapsed", 0)

				local po_pos = find_neighbor(pos,
					"lazarus_space:fusion_power_output")
				if po_pos then
					local po_meta = minetest.get_meta(po_pos)
					po_meta:set_string("infotext", "Fusion Power Output - Offline")
				end
				meta:set_string("formspec", build_unchecked_formspec(tier_index))
				return false
			end
		end
		meta:set_float("check_accumulator", check_acc)
	end

	-- Jump start countdown — 0.1s ticks for smooth progress bar
	if state == "jump_starting" and tier then
		local js_elapsed = meta:get_float("js_elapsed") + elapsed
		meta:set_float("js_elapsed", js_elapsed)

		if js_elapsed >= tier.charge_time then
			meta:set_string("reactor_state", "jump_started")
			meta:set_float("js_elapsed", 0)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Jump Start Complete")
			local timer = minetest.get_node_timer(pos)
			timer:start(1)
		else
			local remaining = tier.charge_time - js_elapsed
			meta:set_string("infotext", "Magnetic Fusion Reactor — Jump Starting... "
				.. string.format("%.1fs", remaining))
		end
		meta:set_string("formspec", build_reactor_formspec(pos))
		return true
	end

	-- Active reactor: decrement fuel time
	if state == "active" then
		local ft = meta:get_int("fuel_time") - 1
		if ft <= 0 then
			-- Fuel depleted — shutdown (state transition: rebuild formspec)
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
			meta:set_string("formspec", build_reactor_formspec(pos))
		else
			meta:set_int("fuel_time", ft)
			-- Update infotext every second (does not invalidate open formspec)
			meta:set_string("infotext", "Magnetic Fusion Reactor — Active ("
				.. format_time(ft) .. ")")
			-- Rebuild formspec every 30 seconds for fuel display
			local display_acc = meta:get_int("display_accumulator") + 1
			if display_acc >= 30 then
				display_acc = 0
				meta:set_string("formspec", build_reactor_formspec(pos))
			end
			meta:set_int("display_accumulator", display_acc)
		end
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
-- PLASMA FIELD CORNER HELPER
-- ============================================================

-- Check if a plasma_field at pos should become a corner piece.
-- Converts to corner if it has exactly 2 plasma neighbors on perpendicular axes.
function lazarus_space.check_plasma_corner(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "lazarus_space:plasma_field" then return end

	local PF = "lazarus_space:plasma_field"
	local PFC = "lazarus_space:plasma_field_corner"
	local dirs = {
		{x=1,  y=0, z=0,  label="+x"},
		{x=-1, y=0, z=0,  label="-x"},
		{x=0,  y=0, z=1,  label="+z"},
		{x=0,  y=0, z=-1, label="-z"},
	}

	-- Find which directions have plasma field neighbors
	local connections = {}
	for _, d in ipairs(dirs) do
		local npos = vector.add(pos, d)
		local nn = minetest.get_node(npos).name
		if nn == PF or nn == PFC then
			connections[#connections+1] = d.label
		end
	end

	-- Need exactly 2 connections on perpendicular axes
	if #connections ~= 2 then return end
	local has_x, has_z = false, false
	local x_dir, z_dir
	for _, c in ipairs(connections) do
		if c == "+x" or c == "-x" then has_x = true; x_dir = c end
		if c == "+z" or c == "-z" then has_z = true; z_dir = c end
	end
	if not (has_x and has_z) then return end

	-- Corner nodebox at param2=0: arms along -X and +Z
	-- Facedir rotation (x'=z, z'=-x per step):
	--   param2=0: -X, +Z | param2=1: +X, +Z | param2=2: +X, -Z | param2=3: -X, -Z
	local corner_map = {
		["-x+z"] = 0,
		["+x+z"] = 1,
		["+x-z"] = 2,
		["-x-z"] = 3,
	}
	local key = x_dir .. z_dir
	local param2 = corner_map[key] or 0

	minetest.set_node(pos, {
		name = PFC,
		param2 = param2,
	})
end

-- Recheck a corner piece — revert to straight if it no longer has 2 perpendicular neighbors.
function lazarus_space.recheck_corner(pos)
	local node = minetest.get_node(pos)
	if node.name ~= "lazarus_space:plasma_field_corner" then return end

	local PF = "lazarus_space:plasma_field"
	local PFC = "lazarus_space:plasma_field_corner"
	local dirs = {
		{x=1,  y=0, z=0,  label="+x"},
		{x=-1, y=0, z=0,  label="-x"},
		{x=0,  y=0, z=1,  label="+z"},
		{x=0,  y=0, z=-1, label="-z"},
	}

	local has_x, has_z = false, false
	local x_dir
	for _, d in ipairs(dirs) do
		local npos = vector.add(pos, d)
		local nn = minetest.get_node(npos).name
		if nn == PF or nn == PFC then
			if d.label == "+x" or d.label == "-x" then
				has_x = true; x_dir = d.label
			elseif d.label == "+z" or d.label == "-z" then
				has_z = true
			end
		end
	end

	-- Still has perpendicular neighbors — stay as corner
	if has_x and has_z then return end

	-- Revert to straight piece with correct orientation
	local param2 = 0  -- default: along Z axis
	if x_dir then param2 = 1 end  -- has X neighbor: orient along X
	minetest.set_node(pos, {name = PF, param2 = param2})
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
		-- Auto-corner: check newly placed piece AND all its neighbors
		lazarus_space.check_plasma_corner(pos)
		local horiz = {
			{x=1,y=0,z=0}, {x=-1,y=0,z=0},
			{x=0,y=0,z=1}, {x=0,y=0,z=-1},
		}
		for _, d in ipairs(horiz) do
			local npos = vector.add(pos, d)
			local nn = minetest.get_node(npos).name
			if nn == "lazarus_space:plasma_field" then
				lazarus_space.check_plasma_corner(npos)
			end
		end
	end,

	after_dig_node = function(pos, oldnode, oldmeta, digger)
		-- Neighbors may need to revert from corner to straight
		local horiz = {
			{x=1,y=0,z=0}, {x=-1,y=0,z=0},
			{x=0,y=0,z=1}, {x=0,y=0,z=-1},
		}
		for _, d in ipairs(horiz) do
			local npos = vector.add(pos, d)
			if minetest.get_node(npos).name == "lazarus_space:plasma_field_corner" then
				lazarus_space.recheck_corner(npos)
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

	after_dig_node = function(pos, oldnode, oldmeta, digger)
		local horiz = {
			{x=1,y=0,z=0}, {x=-1,y=0,z=0},
			{x=0,y=0,z=1}, {x=0,y=0,z=-1},
		}
		for _, d in ipairs(horiz) do
			local npos = vector.add(pos, d)
			if minetest.get_node(npos).name == "lazarus_space:plasma_field_corner" then
				lazarus_space.recheck_corner(npos)
			end
		end
	end,
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
		inv:set_size("fuel", 6) -- default size, resized on tier select
		meta:set_int("reactor_tier", 0)
		meta:set_string("reactor_state", "")
		meta:set_string("validated", "")
		meta:set_string("infotext", "Magnetic Fusion Reactor — Select Tier")
		meta:set_string("formspec", build_tier_select_formspec())
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
		meta:set_string("infotext", "Plasma Jumpstarter — 0 EU (no tier selected)")
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

		-- Get tier from neighboring control panel
		local panel_pos = find_neighbor(pos, "lazarus_space:fusion_control_panel")
		local max_energy = 85000 -- default
		if panel_pos then
			local tier = get_tier(panel_pos)
			if tier then max_energy = tier.jumpstart_energy end
		end

		if stored < max_energy then
			meta:set_int("HV_EU_demand", 10000)
			local input = meta:get_int("HV_EU_input")
			stored = math.min(max_energy, stored + input)
			meta:set_int("stored_energy", stored)
		else
			meta:set_int("HV_EU_demand", 0)
		end

		local ready = stored >= max_energy
		meta:set_string("infotext", "Plasma Jumpstarter — "
			.. stored .. " / " .. max_energy .. " EU"
			.. (ready and " (Ready)" or ""))
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
		local otier = meta:get_string("output_tier")
		if otier == "" then otier = "HV" end

		-- Get reactor tier from neighboring control panel
		local panel_pos = find_neighbor(pos, "lazarus_space:fusion_control_panel")
		local active = false
		local power = 0
		if panel_pos then
			local panel_meta = minetest.get_meta(panel_pos)
			active = panel_meta:get_string("reactor_state") == "active"
			local rtier = get_tier(panel_pos)
			if rtier then power = rtier.power_output end
		end

		local fs = "size[6,4.5]"
			.. "bgcolor[#080808;true]"
			.. "box[0,0;5.8,0.8;#1a1a2e]"
			.. "label[1.5,0.2;Fusion Power Output]"
			.. "box[0,1;5.8,0.6;#0a0a15]"

		if active then
			fs = fs .. "label[0.3,1.1;" .. minetest.colorize("#00ff66", "ONLINE") .. "]"
		else
			fs = fs .. "label[0.3,1.1;" .. minetest.colorize("#ff3333", "OFFLINE") .. "]"
		end

		fs = fs .. "box[0,1.8;5.8,1.5;#0d0d1a]"
			.. "label[0.3,1.9;Output Tier]"

		local tiers = {{"LV", 0.3}, {"MV", 2.1}, {"HV", 3.9}}
		for _, t in ipairs(tiers) do
			local tname, tx = t[1], t[2]
			local btn_name = "set_" .. tname:lower()
			if otier == tname then
				fs = styled_btn(fs, tx, 2.4, 1.5, 0.7, btn_name, tname,
					"#00ccaa", "#00ddbb", "#009988")
			else
				fs = styled_btn(fs, tx, 2.4, 1.5, 0.7, btn_name, tname,
					"#2a2a3e", "#3a3a4e", "#1a1a2e", "#aaaaaa")
			end
		end

		fs = fs .. "box[0,3.5;5.8,0.8;#0d0d1a]"
		if active then
			fs = fs .. "label[0.3,3.7;Supplying: " .. minetest.colorize("#00ccaa",
				power .. " EU") .. " on " .. otier .. "]"
		else
			fs = fs .. "label[0.3,3.7;" .. minetest.colorize("#666666",
				"No output - Reactor offline") .. "]"
		end

		minetest.show_formspec(clicker:get_player_name(),
			"lazarus_space:power_output_" .. minetest.pos_to_string(pos), fs)
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local otier = meta:get_string("output_tier")
		if otier == "" then otier = "HV" end

		-- Get reactor tier from neighboring control panel
		local panel_pos = find_neighbor(pos, "lazarus_space:fusion_control_panel")
		local active = false
		local power = 0
		if panel_pos then
			local panel_meta = minetest.get_meta(panel_pos)
			active = panel_meta:get_string("reactor_state") == "active"
			local rtier = get_tier(panel_pos)
			if rtier then power = rtier.power_output end
		end

		if active then
			meta:set_int("HV_EU_supply", otier == "HV" and power or 0)
			meta:set_int("MV_EU_supply", otier == "MV" and power or 0)
			meta:set_int("LV_EU_supply", otier == "LV" and power or 0)
			meta:set_string("infotext", "Fusion Power Output - "
				.. power .. " EU (" .. otier .. ")")
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
