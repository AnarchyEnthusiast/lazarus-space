-- Biological Dimension: Mapgen Framework
-- Main terrain generation for y=26890 to y=29200.
-- Handles noise system, non-biome layers, cave biomes, upper asteroids,
-- and dispatches modular surface biomes from biomes/ subdirectory.

local modpath = minetest.get_modpath("lazarus_space")

-- =============================================================================
-- Local Math Cache (Lua local lookups faster than global table lookups)
-- =============================================================================

local math_floor  = math.floor
local math_sqrt   = math.sqrt
local math_abs    = math.abs
local math_random = math.random
local math_max    = math.max
local math_min    = math.min

-- =============================================================================
-- Layer Boundary Constants
-- =============================================================================

local BIO_MIN               = 26890
local BIO_MAX               = 29200

local FROZEN_ASTEROID_MIN   = 26890
local FROZEN_ASTEROID_MAX   = 26997

local DEATH_SPACE_MIN       = 26997
local DEATH_SPACE_MAX       = 27006

local ORGANIC_CAVE_MIN      = 27006
local ORGANIC_CAVE_MAX      = 27697
local LOWER_CAP_TOP_BASE    = 27026

local JELLY_MEMBRANE_MIN    = 27697
local JELLY_MEMBRANE_MAX    = 27712

local PLASMA_MIN           = 27702
local PLASMA_MAX           = 27775
local PLASMA_BARRIER_BOTTOM_MIN = 27690  -- Lowest possible barrier bottom (27695 - 5 amplitude)

local SURFACE_BASE          = 27775

local UPPER_ASTEROID_MIN    = 27920
local UPPER_ASTEROID_MAX    = 28693

local CEILING_CAVE_MIN      = 28793
local CEILING_CAVE_MAX      = 29193

local CEILING_MEMBRANE_MIN  = 29193
local CEILING_MEMBRANE_MAX  = 29200

local CAP_BOTTOM_BASE       = 28793
local CAP_TOP_BASE          = 28823
local CAP_MIN_THICKNESS     = 10

local STALACTITE_MIN        = 28583
local STALACTITE_MAX        = 28803
local STALACTITE_CELL_SIZE  = 60

-- Erosion factor for two-layer Perlin detail attenuation (tunable)
local EROSION_FACTOR = 2.5

-- =============================================================================
-- Surface Biome Registration API
-- =============================================================================

lazarus_space.bio_surface_biomes = {}

function lazarus_space.register_surface_biome(def)
	assert(def.name, "Surface biome must have a name")
	assert(def.noise_min, "Surface biome must have noise_min")
	assert(def.noise_max, "Surface biome must have noise_max")
	assert(def.noise_min < def.noise_max, "noise_min must be less than noise_max")
	assert(def.base_height_offset, "Surface biome must have base_height_offset")
	assert(def.height_amplitude, "Surface biome must have height_amplitude")
	assert(def.detail_amplitude, "Surface biome must have detail_amplitude")
	assert(def.get_content_ids, "Surface biome must have get_content_ids function")
	assert(def.generate_column, "Surface biome must have generate_column function")

	-- Insert sorted by noise_min
	local inserted = false
	for i, biome in ipairs(lazarus_space.bio_surface_biomes) do
		if def.noise_min < biome.noise_min then
			table.insert(lazarus_space.bio_surface_biomes, i, def)
			inserted = true
			break
		end
	end
	if not inserted then
		table.insert(lazarus_space.bio_surface_biomes, def)
	end
end

-- =============================================================================
-- Noise Definitions
-- =============================================================================

local np = {
	cave_biome = {
		offset = 0, scale = 1, spread = {x = 600, y = 600, z = 600},
		seed = 59274, octaves = 3, persist = 0.5,
	},
	surface_biome = {
		offset = 0, scale = 1, spread = {x = 900, y = 900, z = 900},
		seed = 81736, octaves = 3, persist = 0.5,
	},
	terrain_height = {
		offset = 0, scale = 1, spread = {x = 100, y = 100, z = 100},
		seed = 34829, octaves = 4, persist = 0.5,
	},
	terrain_detail = {
		offset = 0, scale = 1, spread = {x = 30, y = 30, z = 30},
		seed = 62048, octaves = 3, persist = 0.5,
	},
	cave_shape = {
		offset = 0, scale = 1, spread = {x = 60, y = 60, z = 60},
		seed = 47193, octaves = 4, persist = 0.5,
	},
	cave_detail = {
		offset = 0, scale = 1, spread = {x = 10, y = 10, z = 10},
		seed = 28461, octaves = 2, persist = 0.5,
	},
	asteroid_shape = {
		offset = 0, scale = 1, spread = {x = 105, y = 105, z = 105},
		seed = 73920, octaves = 3, persist = 0.5,
	},
	lower_cap_top = {
		offset = 0, scale = 6, spread = {x = 40, y = 40, z = 40},
		seed = 44183, octaves = 2, persist = 0.5,
	},
	cap_bottom = {
		offset = 0, scale = 10, spread = {x = 50, y = 50, z = 50},
		seed = 55219, octaves = 2, persist = 0.5,
	},
	cap_top = {
		offset = 0, scale = 8, spread = {x = 60, y = 60, z = 60},
		seed = 63847, octaves = 2, persist = 0.5,
	},
	cave_transition = {
		offset = 0, scale = 1, spread = {x = 40, y = 40, z = 40},
		seed = 28374, octaves = 2, persist = 0.5,
	},
	asteroid_edge_bottom = {
		offset = 0, scale = 30, spread = {x = 16, y = 16, z = 16},
		seed = 33891, octaves = 4, persist = 0.7,
	},
	asteroid_edge_top = {
		offset = 0, scale = 25, spread = {x = 20, y = 20, z = 20},
		seed = 41203, octaves = 4, persist = 0.65,
	},
	ceiling_underside = {
		offset = 0, scale = 1, spread = {x = 32, y = 32, z = 32},
		seed = 77412, octaves = 3, persist = 0.6,
	},
	plasma_barrier_top = {
		offset = 0, scale = 6, spread = {x = 40, y = 40, z = 40},
		seed = 52791, octaves = 2, persist = 0.4,
	},
	plasma_barrier_bottom = {
		offset = 0, scale = 5, spread = {x = 28, y = 28, z = 28},
		seed = 63802, octaves = 3, persist = 0.5,
	},
	sphere_surface = {
		offset = 0, scale = 1, spread = {x = 5, y = 5, z = 5},
		seed = 61938, octaves = 3, persist = 0.6,
	},
}

-- Cached noise objects and flat buffers
local nobj = {}
local nbuf = {}

-- Additional noise object for gradient sampling (terrain height at offset positions)
-- nobj.terrain_height_point initialized lazily

-- =============================================================================
-- Content ID Cache
-- =============================================================================

local c = {}

minetest.register_on_mods_loaded(function()
	-- Core
	c.air                       = minetest.get_content_id("air")
	c.ignore                    = minetest.get_content_id("ignore")

	-- Structural
	c.flesh                     = minetest.get_content_id("lazarus_space:flesh")
	c.rotten_flesh              = minetest.get_content_id("lazarus_space:rotten_flesh")
	c.sinew                     = minetest.get_content_id("lazarus_space:sinew")
	c.bone                      = minetest.get_content_id("lazarus_space:bone")
	c.enamel                    = minetest.get_content_id("lazarus_space:enamel")
	c.bone_block                = minetest.get_content_id("lazarus_space:bone_block")
	c.rotten_bone               = minetest.get_content_id("lazarus_space:rotten_bone")
	c.cartilage                 = minetest.get_content_id("lazarus_space:cartilage")

	-- Barriers / Congealed
	c.congealed_plasma          = minetest.get_content_id("lazarus_space:congealed_plasma")
	c.congealed_rotten_plasma   = minetest.get_content_id("lazarus_space:congealed_rotten_plasma")
	c.congealed_blood           = minetest.get_content_id("lazarus_space:congealed_blood")
	c.death_space               = minetest.get_content_id("lazarus_space:death_space")

	-- Neural / Coral
	c.fatty_nerve               = minetest.get_content_id("lazarus_space:fatty_nerve")
	c.glowing_nerve             = minetest.get_content_id("lazarus_space:glowing_nerve")
	c.brain_coral_block         = minetest.get_content_id("lazarus_space:brain_coral_block")
	c.nerve_block               = minetest.get_content_id("lazarus_space:nerve_block")

	-- Follicle / Fat
	c.fat_tissue                = minetest.get_content_id("lazarus_space:fat_tissue")
	c.keratin                   = minetest.get_content_id("lazarus_space:keratin")

	-- Tungsten
	c.tungsten_ore              = minetest.get_content_id("lazarus_space:tungsten_ore")

	-- Cave
	c.mucus                     = minetest.get_content_id("lazarus_space:mucus")
	c.glowing_mushroom          = minetest.get_content_id("lazarus_space:glowing_mushroom")
	c.cave_shroom_small         = minetest.get_content_id("lazarus_space:cave_shroom_small")
	c.cave_shroom_bright        = minetest.get_content_id("lazarus_space:cave_shroom_bright")
	c.cave_vine                 = minetest.get_content_id("lazarus_space:cave_vine")

	-- Surface plants
	c.bio_grass_1               = minetest.get_content_id("lazarus_space:bio_grass_1")
	c.bio_grass_3               = minetest.get_content_id("lazarus_space:bio_grass_3")
	c.bio_tendril               = minetest.get_content_id("lazarus_space:bio_tendril")
	c.bio_polyp_plant           = minetest.get_content_id("lazarus_space:bio_polyp_plant")

	-- Liquids
	c.plasma_source             = minetest.get_content_id("lazarus_space:plasma_source")
	c.bile_source               = minetest.get_content_id("lazarus_space:bile_source")
	c.pus_source                = minetest.get_content_id("lazarus_space:pus_source")
	c.marrow_source             = minetest.get_content_id("lazarus_space:marrow_source")

	-- Default nodes
	c.dirt                      = minetest.get_content_id("default:dirt")
	c.dirt_with_grass           = minetest.get_content_id("default:dirt_with_grass")
	c.stone                     = minetest.get_content_id("default:stone")
	c.cobblestone               = minetest.get_content_id("default:stone")  -- cobblestone not available in all games
	c.ice                       = minetest.get_content_id("default:ice")
	c.steelblock                = minetest.get_content_id("default:steelblock")
	c.water_source              = minetest.get_content_id("default:water_source")

	-- Let each registered biome cache its content IDs
	for _, biome in ipairs(lazarus_space.bio_surface_biomes) do
		biome.get_content_ids(c)
	end
end)

-- =============================================================================
-- Utility Functions
-- =============================================================================

local pos_hash = lazarus_space.pos_hash

local function pos_hash_2d(x, z, seed)
	seed = seed or 0
	local h = (x * 374761393 + z * 668265263 + seed) % 2147483647
	h = ((h * 1103515245) + 12345) % 2147483647
	h = ((h * 1103515245) + 12345) % 2147483647
	return h
end

-- Find which surface biome applies at a given noise value
-- Returns biome_a, biome_b, blend_factor
-- If not in transition zone: biome_b is nil, blend_factor is nil
local TRANSITION_HALF_WIDTH = 0.05

local function find_surface_biome(noise_val)
	local biomes = lazarus_space.bio_surface_biomes
	if #biomes == 0 then return nil, nil, nil end

	-- Find the biome whose range contains this noise value
	local active_biome = nil
	local active_idx = nil
	for i, biome in ipairs(biomes) do
		if noise_val >= biome.noise_min and noise_val < biome.noise_max then
			active_biome = biome
			active_idx = i
			break
		end
	end

	if not active_biome then
		return nil, nil, nil
	end

	-- Check if we're in a transition zone near a boundary
	for i, biome in ipairs(biomes) do
		if i ~= active_idx then
			-- Check boundary between this biome and active biome
			local boundary = nil
			local biome_below, biome_above
			if biome.noise_max == active_biome.noise_min then
				boundary = biome.noise_max
				biome_below = biome
				biome_above = active_biome
			elseif active_biome.noise_max == biome.noise_min then
				boundary = active_biome.noise_max
				biome_below = active_biome
				biome_above = biome
			end

			if boundary then
				local dist = math_abs(noise_val - boundary)
				if dist < TRANSITION_HALF_WIDTH then
					local blend = (noise_val - boundary + TRANSITION_HALF_WIDTH) / (2 * TRANSITION_HALF_WIDTH)
					blend = math_max(0, math_min(1, blend))
					return biome_below, biome_above, blend
				end
			end
		end
	end

	return active_biome, nil, nil
end

-- =============================================================================
-- Hollow Asteroid System (Upper Asteroids)
-- =============================================================================

local HOLLOW_CELL_SIZE = 200
local HOLLOW_SEED = 84729

local function get_hollow_asteroid(cell_x, cell_y, cell_z)
	local hash = pos_hash(cell_x + HOLLOW_SEED, cell_y + HOLLOW_SEED, cell_z + HOLLOW_SEED)
	local rng = PcgRandom(hash)

	-- 1 in 6 chance (was 1/7, ×1.2 more common)
	if rng:next(1, 6) ~= 1 then
		return nil
	end

	local margin = 50
	local cx = cell_x * HOLLOW_CELL_SIZE + rng:next(margin, HOLLOW_CELL_SIZE - margin)
	local cy = cell_y * HOLLOW_CELL_SIZE + rng:next(margin, HOLLOW_CELL_SIZE - margin)
	local cz = cell_z * HOLLOW_CELL_SIZE + rng:next(margin, HOLLOW_CELL_SIZE - margin)
	local radius = rng:next(29, 86)  -- wider range: min -30%, max +20%

	-- Entry tunnel directions (2 opposing cardinal directions at equator)
	local tunnel_dir = rng:next(0, 1) -- 0 = x-axis, 1 = z-axis

	return {
		cx = cx, cy = cy, cz = cz,
		radius = radius,
		tunnel_dir = tunnel_dir,
	}
end

-- Cache for hollow asteroids to avoid recalculating
local hollow_cache = {}
local hollow_cache_key = ""

local function get_hollow_asteroids_near(px, py, pz)
	local gcx = math_floor(px / HOLLOW_CELL_SIZE)
	local gcy = math_floor(py / HOLLOW_CELL_SIZE)
	local gcz = math_floor(pz / HOLLOW_CELL_SIZE)
	local key = gcx .. ":" .. gcy .. ":" .. gcz

	if key == hollow_cache_key then
		return hollow_cache
	end

	local result = {}
	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				local asteroid = get_hollow_asteroid(gcx + dx, gcy + dy, gcz + dz)
				if asteroid then
					result[#result + 1] = asteroid
				end
			end
		end
	end

	hollow_cache = result
	hollow_cache_key = key
	return result
end

-- =============================================================================
-- Frozen Asteroid System constants (generation done per-chunk in mapgen callback)
-- =============================================================================

local FROZEN_CELL_SIZE = 40
local FROZEN_SEED = 57231

-- =============================================================================
-- Giant Stalactite System (hanging from cave cap bottom surface)
-- =============================================================================

local STALACTITE_SEED = 92847

-- Point noise for cap bottom displacement (used by stalactite attachment)
local cap_bottom_point_noise = nil
local function get_cap_bottom_y(x, z)
	if not cap_bottom_point_noise then
		cap_bottom_point_noise = minetest.get_perlin(np.cap_bottom)
	end
	return CAP_BOTTOM_BASE + cap_bottom_point_noise:get_2d({x = x, y = z})
end

local function get_stalactite_in_cell(cell_x, cell_z)
	local h = ((cell_x * 374761393 + cell_z * 668265263 + STALACTITE_SEED) % 2147483647 * 1103515245 + 12345) % 2147483647
	-- 50% chance per cell
	if h % 2 ~= 0 then
		return nil
	end
	local rng = PcgRandom(h)
	local cx = cell_x * STALACTITE_CELL_SIZE + rng:next(5, STALACTITE_CELL_SIZE - 5)
	local cz = cell_z * STALACTITE_CELL_SIZE + rng:next(5, STALACTITE_CELL_SIZE - 5)
	local length = rng:next(60, 200)
	local base_r = rng:next(8, 15)
	local tip_r = rng:next(1, 3)
	-- Embed stalactites 4 blocks into the cap for seamless attachment
	local top_y = math_floor(get_cap_bottom_y(cx, cz)) + 4
	return {
		cx = cx, cz = cz,
		top_y = top_y,
		bottom_y = top_y - length,
		length = length,
		base_r = base_r,
		tip_r = tip_r,
	}
end

-- Cache for stalactites near a position
local stalactite_cache = {}
local stalactite_cache_key = ""

local function get_stalactites_near(px, pz)
	local gcx = math_floor(px / STALACTITE_CELL_SIZE)
	local gcz = math_floor(pz / STALACTITE_CELL_SIZE)
	local key = gcx .. ":" .. gcz

	if key == stalactite_cache_key then
		return stalactite_cache
	end

	local result = {}
	for dx = -1, 1 do
		for dz = -1, 1 do
			local s = get_stalactite_in_cell(gcx + dx, gcz + dz)
			if s then
				result[#result + 1] = s
			end
		end
	end

	stalactite_cache = result
	stalactite_cache_key = key
	return result
end

-- =============================================================================
-- Main on_generated Callback
-- =============================================================================

local unwarned_ranges = {}

minetest.register_on_generated(function(minp, maxp, blockseed)
	-- Early exit if chunk doesn't overlap biological dimension
	if maxp.y < BIO_MIN or minp.y > BIO_MAX then
		return
	end

	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

	local sidelen = maxp.x - minp.x + 1
	local ylen = maxp.y - minp.y + 1

	-- Determine which layers overlap this chunk
	local has_frozen    = (minp.y <= FROZEN_ASTEROID_MAX and maxp.y >= FROZEN_ASTEROID_MIN)
	local has_death     = (minp.y <= DEATH_SPACE_MAX and maxp.y >= DEATH_SPACE_MIN)
	local has_caves     = (minp.y <= PLASMA_BARRIER_BOTTOM_MIN and maxp.y >= ORGANIC_CAVE_MIN)
	local has_plasma   = (minp.y <= PLASMA_MAX and maxp.y >= PLASMA_BARRIER_BOTTOM_MIN)
	local has_surface   = (maxp.y >= SURFACE_BASE and minp.y <= UPPER_ASTEROID_MIN - 100)
	local has_upper_ast = (minp.y <= UPPER_ASTEROID_MAX + 25 and maxp.y >= UPPER_ASTEROID_MIN - 100)
	local has_stalact   = (minp.y <= STALACTITE_MAX and maxp.y >= STALACTITE_MIN)
	local has_ceil_cave = (minp.y <= CEILING_CAVE_MAX and maxp.y >= CEILING_CAVE_MIN)
	local has_ceiling   = (minp.y <= CEILING_MEMBRANE_MAX and maxp.y > UPPER_ASTEROID_MAX + 25)

	-- Initialize 2D noise objects
	local chunksize2d = {x = sidelen, y = sidelen}
	local minpos2d = {x = minp.x, y = minp.z}

	if has_caves or has_surface then
		nobj.cave_biome = nobj.cave_biome or minetest.get_perlin_map(np.cave_biome, chunksize2d)
		nbuf.cave_biome = nobj.cave_biome:get_2d_map_flat(minpos2d, nbuf.cave_biome)

		nobj.surface_biome = nobj.surface_biome or minetest.get_perlin_map(np.surface_biome, chunksize2d)
		nbuf.surface_biome = nobj.surface_biome:get_2d_map_flat(minpos2d, nbuf.surface_biome)
	end

	if has_surface then
		nobj.terrain_height = nobj.terrain_height or minetest.get_perlin_map(np.terrain_height, chunksize2d)
		nbuf.terrain_height = nobj.terrain_height:get_2d_map_flat(minpos2d, nbuf.terrain_height)

		nobj.terrain_detail = nobj.terrain_detail or minetest.get_perlin_map(np.terrain_detail, chunksize2d)
		nbuf.terrain_detail = nobj.terrain_detail:get_2d_map_flat(minpos2d, nbuf.terrain_detail)

		-- Point noise for gradient sampling at offset positions
		nobj.terrain_height_point = nobj.terrain_height_point or minetest.get_perlin(np.terrain_height)
	end

	if has_caves then
		nobj.lower_cap_top = nobj.lower_cap_top or minetest.get_perlin_map(np.lower_cap_top, chunksize2d)
		nbuf.lower_cap_top = nobj.lower_cap_top:get_2d_map_flat(minpos2d, nbuf.lower_cap_top)
	end

	if has_ceiling then
		nobj.cap_bottom = nobj.cap_bottom or minetest.get_perlin_map(np.cap_bottom, chunksize2d)
		nbuf.cap_bottom = nobj.cap_bottom:get_2d_map_flat(minpos2d, nbuf.cap_bottom)

		nobj.cap_top = nobj.cap_top or minetest.get_perlin_map(np.cap_top, chunksize2d)
		nbuf.cap_top = nobj.cap_top:get_2d_map_flat(minpos2d, nbuf.cap_top)

		nobj.ceiling_underside = nobj.ceiling_underside or minetest.get_perlin_map(np.ceiling_underside, chunksize2d)
		nbuf.ceiling_underside = nobj.ceiling_underside:get_2d_map_flat(minpos2d, nbuf.ceiling_underside)
	end

	if has_upper_ast then
		nobj.asteroid_edge_bottom = nobj.asteroid_edge_bottom or minetest.get_perlin_map(np.asteroid_edge_bottom, chunksize2d)
		nbuf.asteroid_edge_bottom = nobj.asteroid_edge_bottom:get_2d_map_flat(minpos2d, nbuf.asteroid_edge_bottom)

		nobj.asteroid_edge_top = nobj.asteroid_edge_top or minetest.get_perlin_map(np.asteroid_edge_top, chunksize2d)
		nbuf.asteroid_edge_top = nobj.asteroid_edge_top:get_2d_map_flat(minpos2d, nbuf.asteroid_edge_top)
	end

	-- Initialize 3D noise objects
	local chunksize3d = {x = sidelen, y = ylen, z = sidelen}

	if has_caves then
		nobj.cave_shape = nobj.cave_shape or minetest.get_perlin_map(np.cave_shape, chunksize3d)
		nbuf.cave_shape = nobj.cave_shape:get_3d_map_flat(minp, nbuf.cave_shape)

		nobj.cave_detail = nobj.cave_detail or minetest.get_perlin_map(np.cave_detail, chunksize3d)
		nbuf.cave_detail = nobj.cave_detail:get_3d_map_flat(minp, nbuf.cave_detail)

		nobj.cave_transition = nobj.cave_transition or minetest.get_perlin_map(np.cave_transition, chunksize3d)
		nbuf.cave_transition = nobj.cave_transition:get_3d_map_flat(minp, nbuf.cave_transition)
	end

	if has_frozen or has_upper_ast or has_ceiling or has_stalact then
		nobj.asteroid_shape = nobj.asteroid_shape or minetest.get_perlin_map(np.asteroid_shape, chunksize3d)
		nbuf.asteroid_shape = nobj.asteroid_shape:get_3d_map_flat(minp, nbuf.asteroid_shape)
	end

	if has_upper_ast then
		nobj.sphere_surface = nobj.sphere_surface or minetest.get_perlin_map(np.sphere_surface, chunksize3d)
		nbuf.sphere_surface = nobj.sphere_surface:get_3d_map_flat(minp, nbuf.sphere_surface)
	end

	if has_plasma then
		nobj.plasma_barrier_top = nobj.plasma_barrier_top or minetest.get_perlin_map(np.plasma_barrier_top, chunksize2d)
		nbuf.plasma_barrier_top = nobj.plasma_barrier_top:get_2d_map_flat(minpos2d, nbuf.plasma_barrier_top)

		nobj.plasma_barrier_bottom = nobj.plasma_barrier_bottom or minetest.get_perlin_map(np.plasma_barrier_bottom, chunksize2d)
		nbuf.plasma_barrier_bottom = nobj.plasma_barrier_bottom:get_2d_map_flat(minpos2d, nbuf.plasma_barrier_bottom)
	end

	-- Also need cave_shape/cave_detail for ceiling caves, stalactites, upper asteroids, and coral cliffs
	if (has_ceiling or has_ceil_cave or has_stalact or has_upper_ast) and not has_caves then
		nobj.cave_shape = nobj.cave_shape or minetest.get_perlin_map(np.cave_shape, chunksize3d)
		nbuf.cave_shape = nobj.cave_shape:get_3d_map_flat(minp, nbuf.cave_shape)

		nobj.cave_detail = nobj.cave_detail or minetest.get_perlin_map(np.cave_detail, chunksize3d)
		nbuf.cave_detail = nobj.cave_detail:get_3d_map_flat(minp, nbuf.cave_detail)
	end

	-- Also need cave_shape for coral tube formations in surface biomes
	if has_surface and not has_caves and not has_ceil_cave and not has_stalact then
		nobj.cave_shape = nobj.cave_shape or minetest.get_perlin_map(np.cave_shape, chunksize3d)
		nbuf.cave_shape = nobj.cave_shape:get_3d_map_flat(minp, nbuf.cave_shape)

		if not has_ceiling then
			nobj.cave_detail = nobj.cave_detail or minetest.get_perlin_map(np.cave_detail, chunksize3d)
			nbuf.cave_detail = nobj.cave_detail:get_3d_map_flat(minp, nbuf.cave_detail)
		end
	end

	-- Pre-compute surface biome and terrain height per column
	-- Also store column-specific data for biome generate_column calls
	local column_biome = {}       -- [ni2d] = biome definition
	local column_biome_b = {}     -- [ni2d] = second biome (transition)
	local column_blend = {}       -- [ni2d] = blend factor
	local column_height = {}      -- [ni2d] = final terrain height (y value)
	local column_detail_weight = {} -- [ni2d] = erosion detail weight
	local column_processed = {}   -- [ni2d] = true if column's generate_column was called

	if has_surface and #lazarus_space.bio_surface_biomes > 0 then
		local ni2d = 0
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ni2d = ni2d + 1
				local biome_noise = nbuf.surface_biome[ni2d]

				local biome_a, biome_b, blend = find_surface_biome(biome_noise)
				column_biome[ni2d] = biome_a
				column_biome_b[ni2d] = biome_b
				column_blend[ni2d] = blend

				if biome_a then
					-- Two-layer Perlin height with erosion
					local h_val = nbuf.terrain_height[ni2d]
					local d_val = nbuf.terrain_detail[ni2d]

					-- Gradient computation for erosion
					-- Get neighbor height values
					local h_east, h_west, h_north, h_south
					-- Interior positions: use buffer directly
					local col_in_row = x - minp.x
					local row = z - minp.z
					if col_in_row > 0 and col_in_row < sidelen - 1 and row > 0 and row < sidelen - 1 then
						h_west  = nbuf.terrain_height[ni2d - 1]
						h_east  = nbuf.terrain_height[ni2d + 1]
						h_south = nbuf.terrain_height[ni2d - sidelen]
						h_north = nbuf.terrain_height[ni2d + sidelen]
					else
						-- Edge positions: sample noise directly
						h_west  = nobj.terrain_height_point:get_2d({x = x - 1, y = z})
						h_east  = nobj.terrain_height_point:get_2d({x = x + 1, y = z})
						h_south = nobj.terrain_height_point:get_2d({x = x, y = z - 1})
						h_north = nobj.terrain_height_point:get_2d({x = x, y = z + 1})
					end

					local grad_x = (h_east - h_west) * 0.5
					local grad_z = (h_north - h_south) * 0.5
					local grad_mag = math_sqrt(grad_x * grad_x + grad_z * grad_z)

					local detail_weight = math_max(0, 1 - grad_mag * EROSION_FACTOR)
					column_detail_weight[ni2d] = detail_weight

					-- Compute final terrain height
					if biome_b and blend then
						-- Transition: interpolate heights from both biomes
						local h_a = SURFACE_BASE + biome_a.base_height_offset + h_val * biome_a.height_amplitude + d_val * biome_a.detail_amplitude * detail_weight
						local h_b = SURFACE_BASE + biome_b.base_height_offset + h_val * biome_b.height_amplitude + d_val * biome_b.detail_amplitude * detail_weight
						column_height[ni2d] = math_floor(h_a * (1 - blend) + h_b * blend + 0.5)
					else
						column_height[ni2d] = math_floor(SURFACE_BASE + biome_a.base_height_offset + h_val * biome_a.height_amplitude + d_val * biome_a.detail_amplitude * detail_weight + 0.5)
					end
				end
			end
		end
	end

	-- Per-chunk liquid source counters (hard caps)
	local bile_source_count = 0
	local marrow_source_count = 0
	local LIQUID_CAP = 3

	-- Pre-compute frozen asteroids that overlap this chunk (once per mapgen call)
	local frozen_asteroids = {}
	if has_frozen then
		local cell_min_x = math_floor((minp.x - 16) / FROZEN_CELL_SIZE) - 1
		local cell_max_x = math_floor((maxp.x + 16) / FROZEN_CELL_SIZE) + 1
		local cell_min_y = math_floor((math_max(minp.y, FROZEN_ASTEROID_MIN) - 16) / FROZEN_CELL_SIZE) - 1
		local cell_max_y = math_floor((math_min(maxp.y, DEATH_SPACE_MIN) + 16) / FROZEN_CELL_SIZE) + 1
		local cell_min_z = math_floor((minp.z - 16) / FROZEN_CELL_SIZE) - 1
		local cell_max_z = math_floor((maxp.z + 16) / FROZEN_CELL_SIZE) + 1

		for cx = cell_min_x, cell_max_x do
			for cy = cell_min_y, cell_max_y do
				for cz = cell_min_z, cell_max_z do
					local hash = lazarus_space.pos_hash(cx + FROZEN_SEED, cy + FROZEN_SEED, cz + FROZEN_SEED)
					local rng = PcgRandom(hash)

					if rng:next(1, 3) == 1 then
						local margin = 5
						local ax = cx * FROZEN_CELL_SIZE + rng:next(margin, FROZEN_CELL_SIZE - margin)
						local ay = cy * FROZEN_CELL_SIZE + rng:next(margin, FROZEN_CELL_SIZE - margin)
						local az = cz * FROZEN_CELL_SIZE + rng:next(margin, FROZEN_CELL_SIZE - margin)
						local radius = rng:next(3, 16)
						local ice_ratio = rng:next(30, 70) / 100

						-- Only include if it could overlap this chunk
						if ax + radius >= minp.x and ax - radius <= maxp.x
						and ay + radius >= minp.y and ay - radius <= maxp.y
						and az + radius >= minp.z and az - radius <= maxp.z then
							frozen_asteroids[#frozen_asteroids + 1] = {
								cx = ax, cy = ay, cz = az,
								radius = radius,
								radius_sq = radius * radius,
								ice_ratio = ice_ratio,
							}
						end
					end
				end
			end
		end
	end

	-- Main generation loop: z-y-x order (x innermost)
	local ni3d = 0
	for z = minp.z, maxp.z do
		for y = minp.y, maxp.y do
			for x = minp.x, maxp.x do
				ni3d = ni3d + 1
				local vi = area:index(x, y, z)

				-- Skip positions outside biological dimension
				if y < BIO_MIN or y > BIO_MAX then
					-- do nothing
				elseif y >= FROZEN_ASTEROID_MIN and y < DEATH_SPACE_MIN and has_frozen then
					-- Frozen Asteroid Field: individual ice/stone asteroids
					local placed_frozen = false

					for fi = 1, #frozen_asteroids do
						local fa = frozen_asteroids[fi]
						local fdx = x - fa.cx
						local fdy = y - fa.cy
						local fdz = z - fa.cz
						local fdist_sq = fdx * fdx + fdy * fdy + fdz * fdz

						if fdist_sq <= fa.radius_sq then
							-- Deform slightly using position hash
							local deform = (pos_hash(x + 19283, y + 48271, z + 73619) % 1000) / 1000
							local deformed_r_sq = fa.radius_sq * (0.72 + deform * 0.36)

							if fdist_sq <= deformed_r_sq then
								local frac = fdist_sq / deformed_r_sq
								if frac > 0.49 then
									-- Surface: ice/stone mix
									local sh = pos_hash(x + 33721, y + 91283, z + 17539) % 100
									if sh < fa.ice_ratio * 100 then
										data[vi] = c.ice
									else
										data[vi] = c.stone
									end
								else
									-- Core: mostly stone
									local ch = pos_hash(x + 55129, y + 22817, z + 66491) % 100
									if ch < 15 then
										data[vi] = c.ice
									else
										data[vi] = c.stone
									end
								end
								placed_frozen = true
								break
							end
						end
					end

					if not placed_frozen then
						data[vi] = c.air
					end

				elseif y >= DEATH_SPACE_MIN and y < DEATH_SPACE_MAX and has_death then
					-- Death Space Barrier
					data[vi] = c.death_space

				elseif y >= ORGANIC_CAVE_MIN and y < PLASMA_BARRIER_BOTTOM_MIN and has_caves then
					-- Organic Cave Layer
					local ni2d = (z - minp.z) * sidelen + (x - minp.x) + 1

					-- Lower cave bottom cap (y=27006-27026, wavy top ±6)
					local lower_cap_disp = nbuf.lower_cap_top and nbuf.lower_cap_top[ni2d] or 0
					local lower_cap_top_y = LOWER_CAP_TOP_BASE + lower_cap_disp

					if y < lower_cap_top_y then
						-- Solid cap between ORGANIC_CAVE_MIN and displaced top
						local cap_thickness = lower_cap_top_y - ORGANIC_CAVE_MIN
						local pos_in_cap = (y - ORGANIC_CAVE_MIN) / math_max(cap_thickness, 1)
						if pos_in_cap < 0.4 then
							data[vi] = c.bone  -- Bottom 40%: structural base
						elseif pos_in_cap < 0.7 then
							data[vi] = c.rotten_bone  -- Middle 30%: transitional
						elseif y >= lower_cap_top_y - 1 then
							data[vi] = c.flesh  -- Top surface: cave floor
						else
							data[vi] = c.flesh  -- Top 30%: blends into floor
						end
					else
					-- Normal cave generation above the cap

					local cave_biome_val = nbuf.cave_biome[ni2d]
					local cave_shape = nbuf.cave_shape[ni3d]
					local cave_detail = nbuf.cave_detail[ni3d]

					-- Determine cave biome with smooth transition blending
					local cave_type
					local in_transition = false
					local cave_trans_val = nbuf.cave_transition[ni3d]

					-- Carving thresholds by biome
					local threshold
					if cave_biome_val < -0.4 then
						cave_type = "intestinal"
						threshold = 0.10
					elseif cave_biome_val < -0.2 then
						-- Transition zone: intestinal/tumor
						-- Use large-spread noise for patch-based blending
						in_transition = true
						local frac = (cave_biome_val - (-0.4)) / 0.2  -- 0.0 at -0.4, 1.0 at -0.2
						-- Bias the noise by frac: at midpoint (0.5), noise decides 50/50
						-- Shifting noise threshold creates smooth spatial patches
						local blend_threshold = (frac - 0.5) * 2  -- maps 0..1 to -1..1
						if cave_trans_val > blend_threshold then
							cave_type = "tumor"
						else
							cave_type = "intestinal"
						end
						-- Interpolate carving threshold between biomes
						threshold = 0.10 * (1 - frac) + 0.0 * frac
					elseif cave_biome_val < 0.2 then
						cave_type = "tumor"
						threshold = 0.0
					elseif cave_biome_val < 0.4 then
						-- Transition zone: tumor/marrow
						in_transition = true
						local frac = (cave_biome_val - 0.2) / 0.2  -- 0.0 at 0.2, 1.0 at 0.4
						local blend_threshold = (frac - 0.5) * 2
						if cave_trans_val > blend_threshold then
							cave_type = "marrow"
						else
							cave_type = "tumor"
						end
						-- Interpolate carving threshold between biomes
						threshold = 0.0 * (1 - frac) + (-0.10) * frac
					else
						cave_type = "marrow"
						threshold = -0.10
					end

					-- Hysteresis: near threshold, bias toward same result as y-1
					local is_solid
					if math_abs(cave_shape - threshold) < 0.02 then
						-- Near threshold: check y-1 (already processed in z-y-x order)
						local ni3d_below = ni3d - sidelen
						if y > minp.y and nbuf.cave_shape[ni3d_below] then
							is_solid = nbuf.cave_shape[ni3d_below] >= threshold
						else
							is_solid = cave_shape >= threshold
						end
					else
						is_solid = cave_shape >= threshold
					end
					local ph = pos_hash(x, y, z)

					if is_solid then
						-- Check if this is a floor or ceiling position
						-- Floor: solid here, air above
						-- We approximate by checking noise at y+1
						local ni3d_above = ni3d + sidelen  -- y+1 in z-y-x order
						local above_is_air = false
						if y + 1 <= maxp.y and y + 1 < PLASMA_BARRIER_BOTTOM_MIN then
							local cave_shape_above = nbuf.cave_shape[ni3d_above]
							above_is_air = cave_shape_above < threshold
						end

						local ni3d_below = ni3d - sidelen
						local below_is_air = false
						if y - 1 >= minp.y and y - 1 >= ORGANIC_CAVE_MIN then
							local cave_shape_below = nbuf.cave_shape[ni3d_below]
							below_is_air = cave_shape_below < threshold
						end

						local is_floor = above_is_air
						local is_ceiling = below_is_air

						if cave_type == "intestinal" then
							-- Tumor cave: cyst wall at boundaries
							if cave_detail > 0 then
								data[vi] = c.congealed_blood
							else
								data[vi] = c.flesh
							end
							if is_floor and ph % 4 == 0 then
								data[vi] = c.mucus
							end
						elseif cave_type == "tumor" then
							-- Cyst formations at boundaries
							if cave_shape < threshold + 0.03 then
								data[vi] = c.congealed_rotten_plasma
							elseif cave_detail < -0.3 then
								data[vi] = c.congealed_rotten_plasma
							elseif cave_detail > 0.3 then
								data[vi] = c.rotten_flesh
							else
								data[vi] = c.flesh
							end
							if is_floor and ph % 200 == 0 then
								data[vi] = c.glowing_nerve
							end
						else -- marrow
							-- Wider material bands for smoother surfaces
							-- Scale detail noise to create larger contiguous patches
							local md = cave_detail * 0.67  -- effectively 1.5x spread
							if md > 0.15 then
								data[vi] = c.rotten_bone
							elseif md < -0.15 then
								data[vi] = c.rotten_bone
							else
								data[vi] = c.bone
							end
							if is_floor then
								data[vi] = c.cartilage
								if ph % 150 == 0 then
									data[vi] = c.rotten_bone
								end
							end
						end

						-- Cave mushrooms on floors (all biomes)
						if is_floor and above_is_air and y + 1 <= maxp.y then
							local vi_above = area:index(x, y + 1, z)
							if ph % 15 == 0 then
								data[vi_above] = c.glowing_mushroom
							elseif ph % 100 == 3 then
								data[vi_above] = c.cave_shroom_bright
							elseif ph % 40 == 1 then
								data[vi_above] = c.cave_shroom_small
							elseif ph % 15 == 2 then
								data[vi_above] = c.cave_shroom_small
							end
						end

						-- Hanging cave vines on ceilings (all cave biomes)
						if is_ceiling and y - 1 >= minp.y then
							local vi_below = area:index(x, y - 1, z)
							if data[vi_below] == c.air then
								local ph_ceil = pos_hash(x + 7919, y, z + 3571)
								if ph_ceil % 60 == 0 then
									data[vi_below] = c.cave_vine
								end
							end
						end

						-- Small bone stalactites from cave ceilings
						if is_ceiling and y - 1 >= minp.y then
							local ph_stl = pos_hash(x + 4219, y, z + 8837)
							local stl_chance = (cave_type == "marrow") and 25 or 40
							if ph_stl % stl_chance == 0 then
								-- Length: 50% 1, 25% 2, 15% 3, 10% 4
								local len_roll = ph_stl % 20
								local stl_len
								if len_roll < 10 then stl_len = 1
								elseif len_roll < 15 then stl_len = 2
								elseif len_roll < 18 then stl_len = 3
								else stl_len = 4 end
								for dy = 1, stl_len do
									local sy = y - dy
									if sy >= minp.y and sy >= ORGANIC_CAVE_MIN then
										local svi = area:index(x, sy, z)
										if data[svi] == c.air then
											data[svi] = c.bone
										else
											break
										end
									end
								end
							end
						end
					else
						-- Air/void position
						-- Intestinal: bile pools (extremely narrow band, 3-per-chunk cap)
						if cave_type == "intestinal" and y < 27237 and cave_shape >= threshold - 0.0001 and bile_source_count < LIQUID_CAP then
							data[vi] = c.bile_source
							bile_source_count = bile_source_count + 1
						-- Marrow: marrow liquid pools (extremely narrow band, 3-per-chunk cap)
						elseif cave_type == "marrow" and cave_shape >= threshold - 0.0001 and marrow_source_count < LIQUID_CAP then
							data[vi] = c.marrow_source
							marrow_source_count = marrow_source_count + 1
						else
							data[vi] = c.air
						end
					end -- is_solid/air branch
					end -- lower cap else (normal cave generation)

				elseif y >= PLASMA_BARRIER_BOTTOM_MIN and y < PLASMA_MAX and has_plasma then
					-- Plasma Barrier + Ocean
					-- Solid congealed_plasma barrier centered at y=27705 with noise on both surfaces
					-- Ocean fills above barrier to PLASMA_MAX
					local ni2d_plasma = (z - minp.z) * sidelen + (x - minp.x) + 1
					local barrier_top_noise = nbuf.plasma_barrier_top and nbuf.plasma_barrier_top[ni2d_plasma] or 0
					local barrier_bot_noise = nbuf.plasma_barrier_bottom and nbuf.plasma_barrier_bottom[ni2d_plasma] or 0

					local barrier_top = 27715 + math_floor(barrier_top_noise)
					local barrier_bot = 27695 + math_floor(barrier_bot_noise)

					-- Enforce minimum 8-block barrier thickness
					if barrier_top - barrier_bot < 8 then
						barrier_top = barrier_bot + 8
					end

					if y > barrier_top then
						-- Above barrier: plasma ocean
						data[vi] = c.plasma_source
					elseif y >= barrier_bot then
						-- Inside barrier: solid congealed_plasma (with bone patches on bottom face)
						if y == barrier_bot then
							-- Bottom face: 15% bone for variety
							local ph_bone = pos_hash(x + 19283, y + 47561, z + 83102)
							if ph_bone % 7 == 0 then
								data[vi] = c.bone
							else
								data[vi] = c.congealed_plasma
							end
						else
							data[vi] = c.congealed_plasma
						end
					else
						-- Below barrier: air (cave ceiling zone)
						data[vi] = c.air
					end

				elseif y >= SURFACE_BASE and y < UPPER_ASTEROID_MIN - 100 and has_surface then
					-- Surface Biome Zone - handled per-column below

				elseif y >= UPPER_ASTEROID_MIN - 100 and y <= UPPER_ASTEROID_MAX + 25 and has_upper_ast then
					-- Upper Asteroid Field
					local noise_val = nbuf.asteroid_shape[ni3d]
					local ph = pos_hash(x, y, z)

					-- Check hollow asteroids first
					local hollows = get_hollow_asteroids_near(x, y, z)
					local in_hollow = false

					for _, h in ipairs(hollows) do
						local dx = x - h.cx
						local dy = y - h.cy
						local dz = z - h.cz
						local dist_sq = dx * dx + dy * dy + dz * dz

						-- Base deformation from large-scale noise
						local displacement = h.radius * 0.28
						local ast_noise = nbuf.asteroid_shape[ni3d]
						local base_radius = h.radius + ast_noise * displacement
						local shell_thickness = 5
						local shell_inner = base_radius - shell_thickness

						-- Surface bump noise (aggressive chunky deformation, spread=5, 3 octaves)
						local ss_noise = nbuf.sphere_surface and nbuf.sphere_surface[ni3d] or 0
						local bump_amp = 6 + (h.radius - 29) / 57 * 2  -- 6 at r=29, 8 at r=86
						local y_norm = math_min(math_abs(dy) / math_max(h.radius, 1), 1.0)
						local pole_factor = 1.0 + y_norm * 1.5  -- 1.0 at equator, 2.5 at poles
						local outer_radius = base_radius + ss_noise * bump_amp * pole_factor

						-- Clamp: min 2-block shell thickness
						if outer_radius < shell_inner + 2 then
							outer_radius = shell_inner + 2
						end

						if dist_sq <= outer_radius * outer_radius then
							in_hollow = true

							-- Check entry tunnels (cylindrical, no displacement)
							local in_tunnel = false
							local tunnel_r = 3.5
							local tunnel_r_sq = tunnel_r * tunnel_r
							if h.tunnel_dir == 0 then
								local tdist_sq = dy * dy + dz * dz
								if tdist_sq < tunnel_r_sq and dy * dy < tunnel_r_sq then
									in_tunnel = true
								end
							else
								local tdist_sq = dy * dy + dx * dx
								if tdist_sq < tunnel_r_sq and dy * dy < tunnel_r_sq then
									in_tunnel = true
								end
							end

							local shell_inner_sq = shell_inner * shell_inner
							if in_tunnel and dist_sq > shell_inner_sq then
								data[vi] = c.air
							elseif dist_sq > shell_inner_sq then
								-- Shell material
								local cd_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
								if cd_val > 0.35 then
									data[vi] = c.stone
								else
									data[vi] = c.stone
								end
							else
								-- Interior (uses base_radius, unaffected by surface bumps)
								local interior_bottom = h.cy - shell_inner + shell_thickness
								local interior_top = h.cy + shell_inner - shell_thickness
								local interior_height = math_max(1, interior_top - interior_bottom)

								-- Ceiling dome: cyst_wall 60% / cartilage 40%
								local ceiling_threshold = shell_inner - 3
								if dist_sq > ceiling_threshold * ceiling_threshold then
									local cd_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
									if cd_val > -0.2 then
										data[vi] = c.congealed_rotten_plasma
									else
										data[vi] = c.cartilage
									end
								-- Bottom third: ground with habitable blocks
								elseif y < h.cy - base_radius / 3.0 then
									local cave_d_val
									if nbuf.cave_detail then
										cave_d_val = nbuf.cave_detail[ni3d]
									else
										cave_d_val = 0
									end
									local grass_y = interior_bottom + math_floor(interior_height * 0.25)
									if cave_d_val < -0.4 and y <= grass_y and y >= interior_bottom + 2 then
										data[vi] = c.water_source
									elseif y == grass_y or (y < grass_y and y >= grass_y - 1) then
										if y == grass_y then
											-- 40% dirt_with_grass, 60% stone floor
											if cave_d_val > 0.1 then
												data[vi] = c.dirt_with_grass
											else
												data[vi] = c.stone
											end
										else
											data[vi] = c.dirt
										end
									elseif y < grass_y then
										data[vi] = c.dirt
									else
										data[vi] = c.air
									end
								else
									data[vi] = c.air
								end
							end
							break
						end
					end

					if not in_hollow then
						-- Check stalactites (override barren asteroids)
						local in_stalactite = false
						if has_stalact and y >= STALACTITE_MIN then
							local stalactites = get_stalactites_near(x, z)
							for _, s in ipairs(stalactites) do
								if y >= s.bottom_y and y <= s.top_y then
									local dx = x - s.cx
									local dz = z - s.cz
									local dist_xz = math_sqrt(dx * dx + dz * dz)

									-- Linear taper: radius from base_r at top to tip_r at bottom
									local t = (y - s.bottom_y) / s.length
									local r_at_y = s.tip_r + (s.base_r - s.tip_r) * t

									-- Noise displacement for organic irregularity (smoothed 30%)
									local ast_noise = nbuf.asteroid_shape and nbuf.asteroid_shape[ni3d] or 0
									local effective_r = r_at_y + ast_noise * 2.8

									if dist_xz <= effective_r then
										in_stalactite = true
										local r_frac = dist_xz / math_max(effective_r, 1)

										-- Hollow core for stalactites > 200 blocks
										if s.length > 200 and dist_xz < 2 then
											local mid_low = s.bottom_y + s.length * 0.25
											local mid_high = s.bottom_y + s.length * 0.75
											if y > mid_low and y < mid_high then
												data[vi] = c.air
												break
											end
										end

										-- Materials: outer 30% = bone/tungsten, inner 70% = flesh/rotten_flesh
										if r_frac > 0.7 then
											-- Surface: rare glow
											if r_frac > 0.95 and pos_hash(x, y, z) % 300 == 0 then
												data[vi] = c.cobblestone
											else
												-- Tungsten veins: ~18% of bone via noise clusters
												local cd_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
												if cd_val > 0.25 and pos_hash(x + 82917, y + 39401, z + 55183) % 5 < 2 then
													data[vi] = c.tungsten_ore
												else
													data[vi] = c.bone
												end
											end
										else
											local cave_d_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
											if cave_d_val > 0.2 then
												data[vi] = c.flesh
											else
												data[vi] = c.rotten_flesh
											end
										end
										break
									end
								end
							end
						end

						if in_stalactite then
							-- Already placed by stalactite code above
						elseif y < UPPER_ASTEROID_MIN then
							-- Buffer zone: only hollow asteroids generate here (handled above)
							-- Barren asteroid noise does not extend into buffer
							if not in_hollow then
								data[vi] = c.air
							end
						else
						-- Displaced asteroid field edges (noisy boundaries)
						local ni2d_ast = (z - minp.z) * sidelen + (x - minp.x) + 1
						local ast_bottom = UPPER_ASTEROID_MIN + (nbuf.asteroid_edge_bottom and nbuf.asteroid_edge_bottom[ni2d_ast] or 0)
						local ast_top = UPPER_ASTEROID_MAX + (nbuf.asteroid_edge_top and nbuf.asteroid_edge_top[ni2d_ast] or 0)

						-- Check if outside displaced edge
						local outside_edge = (y < ast_bottom or y > ast_top)

						-- Livable asteroids exempt from edge cropping
						if outside_edge then
							for _, h in ipairs(hollows) do
								local dx = x - h.cx
								local dy = y - h.cy
								local dz = z - h.cz
								local exempt_r = h.radius + 5  -- account for surface bump noise
							if dx * dx + dy * dy + dz * dz <= exempt_r * exempt_r then
									outside_edge = false
									break
								end
							end
						end

						if outside_edge then
							-- Outside displaced edge and not in livable asteroid: air
							data[vi] = c.air
						else
						-- Barren asteroid noise with density gradient
						-- Additional displacement reduction (×0.7) for smoother surfaces
						noise_val = noise_val * 0.7
						-- Density gradient uses undisplaced boundaries (not displaced edges)
						local ast_range = math_max(1, UPPER_ASTEROID_MAX - UPPER_ASTEROID_MIN)
						local frac = (y - UPPER_ASTEROID_MIN) / ast_range
						local threshold = 0.64 - frac * 0.28  -- 0.64 at bottom (was 0.58, +0.06 rarer), 0.36 at top

						-- Upper 50%: sparser + smoother
						if frac > 0.5 then
							noise_val = noise_val * 0.5  -- further reduce surface displacement
							threshold = threshold * 0.5 + 0.08  -- compensate density + sparsity boost
						end

						-- Lower zone smoothing: bottom 400 blocks get denser, smoother asteroids
						local lower_zone_top = UPPER_ASTEROID_MIN + 400
						if y < lower_zone_top then
							local lower_frac = (lower_zone_top - y) / 400  -- 1.0 at bottom, 0.0 at top of zone
							-- Boost threshold by up to 0.1 (making asteroids denser)
							threshold = threshold + lower_frac * 0.1
							-- Reduce noise displacement by up to 40% (smoother shapes)
							noise_val = noise_val * (1.0 - lower_frac * 0.4) + lower_frac * 0.4
						end

						if noise_val > threshold then
							-- Asteroid surface: patchy sinew islands via noise
							local cd_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
							if noise_val < threshold + 0.01 and cd_val > 0.4 then
								-- Pre-check: only place sinew if at least 1 adjacent block is solid asteroid material
								local has_solid = false
								for _, dv in ipairs({{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}) do
									local nvi = area:index(x+dv[1], y+dv[2], z+dv[3])
									local nid = data[nvi]
									if nid ~= c.air and nid ~= c.sinew and nid ~= c.ignore then
										has_solid = true
										break
									end
								end
								if has_solid then
									data[vi] = c.sinew
								else
									data[vi] = c.stone
								end
							elseif ph % 500 == 0 then
								data[vi] = c.cobblestone
							else
								data[vi] = c.stone
							end
						else
							data[vi] = c.air
						end
						end
						end
					end

				elseif y > UPPER_ASTEROID_MAX + 25 and y <= CEILING_MEMBRANE_MAX and has_ceiling then
					-- Gap zone, cave cap, ceiling caves, and ceiling membrane
					-- Displaced ceiling underside: drops 0-12 blocks below CEILING_MEMBRANE_MIN
					local ni2d_ceil_us = (z - minp.z) * sidelen + (x - minp.x) + 1
					local ceil_noise = nbuf.ceiling_underside and nbuf.ceiling_underside[ni2d_ceil_us] or 0
					local ceil_drop = math_min(12, math_abs(ceil_noise) * 12)
					local ceil_underside_y = CEILING_MEMBRANE_MIN - math_floor(ceil_drop)

					if y >= CEILING_MEMBRANE_MIN then
						-- Original solid ceiling membrane (top surface unchanged)
						local cave_d_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
						if cave_d_val > 0.3 then
							data[vi] = c.congealed_blood
						else
							data[vi] = c.congealed_rotten_plasma
						end
					elseif y >= ceil_underside_y and y < CEILING_MEMBRANE_MIN then
						-- Displaced ceiling protrusion hanging down
						local depth_from_membrane = CEILING_MEMBRANE_MIN - y
						if depth_from_membrane <= 3 then
							-- Top 2-3 blocks: membrane material
							data[vi] = c.congealed_rotten_plasma
						else
							-- Below that: bony protrusions
							data[vi] = c.bone
						end
					else
						-- Compute dual-surface cave cap
						local ni2d_ceil = (z - minp.z) * sidelen + (x - minp.x) + 1
						local cap_bot_disp = nbuf.cap_bottom and nbuf.cap_bottom[ni2d_ceil] or 0
						local cap_top_disp = nbuf.cap_top and nbuf.cap_top[ni2d_ceil] or 0
						local cap_bottom_y = CAP_BOTTOM_BASE + cap_bot_disp
						local cap_top_y = CAP_TOP_BASE + cap_top_disp

						-- Enforce minimum thickness
						if cap_top_y - cap_bottom_y < CAP_MIN_THICKNESS then
							cap_top_y = cap_bottom_y + CAP_MIN_THICKNESS
						end

						if y >= cap_top_y then
							-- Above cap: normal cave generation
							local cave_shape = nbuf.cave_shape and nbuf.cave_shape[ni3d] or 0
							local cave_detail = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0

							local is_solid = cave_shape >= 0.0

							if is_solid then
								-- Wall materials (bone/flesh_dark/muscle mix)
								if cave_detail > 0.2 then
									data[vi] = c.bone
								elseif cave_detail > -0.2 then
									data[vi] = c.rotten_flesh
								else
									data[vi] = c.flesh
								end

								-- Floor mushrooms: solid here, air above
								if y + 1 <= maxp.y and y + 1 < CEILING_MEMBRANE_MIN then
									local ni3d_above = ni3d + sidelen
									if nbuf.cave_shape[ni3d_above] and nbuf.cave_shape[ni3d_above] < 0.0 then
										local ph = pos_hash(x, y, z)
										if ph % 15 == 0 then
											local vi_above = area:index(x, y + 1, z)
											data[vi_above] = c.glowing_mushroom
										end
									end
								end
							else
								data[vi] = c.air
							end

						elseif y >= cap_bottom_y then
							-- Inside cave cap: material bands by position
							local cap_thickness = cap_top_y - cap_bottom_y
							local pos_in_cap = (y - cap_bottom_y) / cap_thickness
							if pos_in_cap < 0.3 then
								data[vi] = c.bone  -- Bottom 30%: hard exterior
							else
								data[vi] = c.rotten_flesh  -- Middle/top 70%: fleshy interior
							end

						else
							-- Below cap: gap zone (air + stalactites)
							local in_stalactite = false
							if has_stalact then
								local stalactites = get_stalactites_near(x, z)
								for _, s in ipairs(stalactites) do
									if y >= s.bottom_y and y <= s.top_y then
										local sdx = x - s.cx
										local sdz = z - s.cz
										local dist_xz = math_sqrt(sdx * sdx + sdz * sdz)

										local t = (y - s.bottom_y) / s.length
										local r_at_y = s.tip_r + (s.base_r - s.tip_r) * t

										local ast_noise = nbuf.asteroid_shape and nbuf.asteroid_shape[ni3d] or 0
										local effective_r = r_at_y + ast_noise * 2.8

										if dist_xz <= effective_r then
											in_stalactite = true
											local r_frac = dist_xz / math_max(effective_r, 1)

											if r_frac > 0.7 then
												if r_frac > 0.95 and pos_hash(x, y, z) % 300 == 0 then
													data[vi] = c.cobblestone
												else
													local cd_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
													if cd_val > 0.25 and pos_hash(x + 82917, y + 39401, z + 55183) % 5 < 2 then
														data[vi] = c.tungsten_ore
													else
														data[vi] = c.bone
													end
												end
											else
												local cave_d_val = nbuf.cave_detail and nbuf.cave_detail[ni3d] or 0
												if cave_d_val > 0.2 then
													data[vi] = c.flesh
												else
													data[vi] = c.rotten_flesh
												end
											end
											break
										end
									end
								end
							end
							if not in_stalactite then
								data[vi] = c.air
							end
						end
					end
				end
			end
		end
	end

	-- Consolidated floating block cleanup: single pass for cave + asteroid zones
	-- Replaces 5 separate passes (marrow cave, cave transition, lower asteroid,
	-- full asteroid fragment suppression, sinew cleanup)
	if has_caves or has_upper_ast then
		-- Y-range boundaries for each zone
		local cave_y_min  = has_caves     and math_max(minp.y + 1, ORGANIC_CAVE_MIN)       or 0
		local cave_y_max  = has_caves     and math_min(maxp.y - 1, PLASMA_BARRIER_BOTTOM_MIN - 1) or -1
		local ast_y_min   = has_upper_ast and math_max(minp.y + 1, UPPER_ASTEROID_MIN - 100) or 0
		local ast_y_max   = has_upper_ast and math_min(maxp.y - 1, UPPER_ASTEROID_MAX + 25) or -1
		local ast_lower_top = UPPER_ASTEROID_MIN + 400

		-- Combined y-range spanning both zones
		local combined_y_min = math_min(cave_y_min, ast_y_min)
		local combined_y_max = math_max(cave_y_max, ast_y_max)
		if not has_caves     then combined_y_min = ast_y_min  end
		if not has_upper_ast then combined_y_max = cave_y_max end

		-- Cached content IDs for inner-loop comparisons
		local c_air          = c.air
		local c_ignore       = c.ignore
		local c_bile_source  = c.bile_source
		local c_marrow_source = c.marrow_source
		local c_sinew        = c.sinew

		if combined_y_min <= combined_y_max and minp.x + 1 <= maxp.x - 1 then
			for z = minp.z + 1, maxp.z - 1 do
				for y = combined_y_min, combined_y_max do
					local in_cave = has_caves     and y >= cave_y_min and y <= cave_y_max
					local in_ast  = has_upper_ast and y >= ast_y_min  and y <= ast_y_max

					if in_cave or in_ast then
						for x = minp.x + 1, maxp.x - 1 do
							local vi = area:index(x, y, z)
							local node_id = data[vi]

							if node_id ~= c_air then
								local removed = false

								-- Cave zone: remove blocks with 5+ air neighbors (skip liquids)
								if in_cave and node_id ~= c_bile_source and node_id ~= c_marrow_source then
									local air_count = 0
									if data[area:index(x+1,y,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x-1,y,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y+1,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y-1,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y,z+1)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y,z-1)] == c_air then air_count = air_count + 1 end
									if air_count >= 5 then
										data[vi] = c_air
										removed = true
									end
								end

								-- Asteroid zone (only if not already removed)
								if in_ast and not removed then
									if node_id == c_sinew then
										-- Sinew cleanup: remove sinew with <2 solid non-sinew neighbors
										local solid_count = 0
										local nid
										nid = data[area:index(x+1,y,z)]
										if nid ~= c_air and nid ~= c_sinew and nid ~= c_ignore then solid_count = solid_count + 1 end
										nid = data[area:index(x-1,y,z)]
										if nid ~= c_air and nid ~= c_sinew and nid ~= c_ignore then solid_count = solid_count + 1 end
										nid = data[area:index(x,y+1,z)]
										if nid ~= c_air and nid ~= c_sinew and nid ~= c_ignore then solid_count = solid_count + 1 end
										nid = data[area:index(x,y-1,z)]
										if nid ~= c_air and nid ~= c_sinew and nid ~= c_ignore then solid_count = solid_count + 1 end
										nid = data[area:index(x,y,z+1)]
										if nid ~= c_air and nid ~= c_sinew and nid ~= c_ignore then solid_count = solid_count + 1 end
										nid = data[area:index(x,y,z-1)]
										if nid ~= c_air and nid ~= c_sinew and nid ~= c_ignore then solid_count = solid_count + 1 end
										if solid_count < 2 then
											data[vi] = c_air
										end
									else
										-- Fragment suppression: count air neighbors
										local air_count = 0
										if data[area:index(x+1,y,z)] == c_air then air_count = air_count + 1 end
										if data[area:index(x-1,y,z)] == c_air then air_count = air_count + 1 end
										if data[area:index(x,y+1,z)] == c_air then air_count = air_count + 1 end
										if data[area:index(x,y-1,z)] == c_air then air_count = air_count + 1 end
										if data[area:index(x,y,z+1)] == c_air then air_count = air_count + 1 end
										if data[area:index(x,y,z-1)] == c_air then air_count = air_count + 1 end
										-- Lower asteroid zone (stricter): 5+ air neighbors
										-- Full asteroid zone: 4+ air neighbors (fragment suppression)
										local threshold = (y <= ast_lower_top) and 5 or 4
										if air_count >= threshold then
											data[vi] = c_air
										end
									end
								end
							end
						end
					end
				end
			end

			-- Cave transition zone 2nd pass: extra cleanup in biome transition columns
			-- Re-processes transition-noise columns to catch blocks newly exposed by main pass
			if has_caves and cave_y_min <= cave_y_max then
				for z = minp.z + 1, maxp.z - 1 do
					local ni2d_t = (z - minp.z) * sidelen + 1
					for x = minp.x + 1, maxp.x - 1 do
						local ni2d_col = ni2d_t + (x - minp.x)
						local cbv = nbuf.cave_biome[ni2d_col]
						if (cbv >= -0.4 and cbv < -0.2) or (cbv >= 0.2 and cbv < 0.4) then
							for y = cave_y_min, cave_y_max do
								local vi = area:index(x, y, z)
								local node_id = data[vi]
								if node_id ~= c_air and node_id ~= c_bile_source and node_id ~= c_marrow_source then
									local air_count = 0
									if data[area:index(x+1,y,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x-1,y,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y+1,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y-1,z)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y,z+1)] == c_air then air_count = air_count + 1 end
									if data[area:index(x,y,z-1)] == c_air then air_count = air_count + 1 end
									if air_count >= 5 then
										data[vi] = c_air
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- Tungsten ore scatter: replace ~1/2500 flesh/bone/cartilage with tungsten ore clusters
	do
		local ore_y_min = math_max(minp.y, BIO_MIN)
		local ore_y_max = math_min(maxp.y, BIO_MAX)
		if ore_y_min <= ore_y_max then
			for z = minp.z, maxp.z do
				for y = ore_y_min, ore_y_max do
					for x = minp.x, maxp.x do
						local vi = area:index(x, y, z)
						local nid = data[vi]
						if nid == c.flesh or nid == c.bone or nid == c.cartilage then
							local ph = pos_hash(x + 91723, y + 44281, z + 67543)
							if ph % 2500 == 0 then
								-- Place ore cluster: this block + 1-3 qualifying neighbors
								data[vi] = c.tungsten_ore
								local cluster_count = 1 + ph % 3  -- 1-3 extra blocks
								local offsets = {{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}
								for oi = 1, math_min(cluster_count, #offsets) do
									local o = offsets[oi]
									local nvi = area:index(x + o[1], y + o[2], z + o[3])
									local nnid = data[nvi]
									if nnid == c.flesh or nnid == c.bone or nnid == c.cartilage then
										data[nvi] = c.tungsten_ore
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- Water pools in lower caves (bottom third: y=27026 to y=27256)
	if has_caves then
		local water_pool_count = 0
		local WATER_POOL_MAX = 3
		local WATER_Y_MIN = math_max(minp.y, LOWER_CAP_TOP_BASE)
		local WATER_Y_MAX = math_min(maxp.y, 27256)
		if WATER_Y_MIN <= WATER_Y_MAX and WATER_Y_MIN + 1 <= maxp.y then
			for z = minp.z + 1, maxp.z - 1 do
				for x = minp.x + 1, maxp.x - 1 do
					if water_pool_count >= WATER_POOL_MAX then break end
					for y = WATER_Y_MIN, WATER_Y_MAX do
						local vi = area:index(x, y, z)
						if data[vi] == c.air then
							local vi_below = area:index(x, y - 1, z)
							if y - 1 >= minp.y and data[vi_below] ~= c.air
								and data[vi_below] ~= c.water_source
								and data[vi_below] ~= c.bile_source then
								-- Floor position: air above solid
								local ph_w = pos_hash(x + 3317, y, z + 5923)
								if ph_w % 200 == 0 then
									-- Check below placement for cascading
									if y - 2 >= minp.y then
										local vi_below2 = area:index(x, y - 2, z)
										if data[vi_below2] == c.air then
											goto skip_water
										end
									end
									-- Place center water
									data[vi] = c.water_source
									local pool_size = 1
									-- Expand to 4 neighbors
									for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
										if pool_size >= 5 then break end
										local nx, nz = x + off[1], z + off[2]
										if nx >= minp.x and nx <= maxp.x and nz >= minp.z and nz <= maxp.z then
											local nvi = area:index(nx, y, nz)
											local nvi_below = area:index(nx, y - 1, nz)
											if data[nvi] == c.air and data[nvi_below] ~= c.air
												and data[nvi_below] ~= c.water_source then
												data[nvi] = c.water_source
												pool_size = pool_size + 1
											end
										end
									end
									water_pool_count = water_pool_count + 1
									break  -- One pool per column
								end
								::skip_water::
							end
						end
					end
				end
				if water_pool_count >= WATER_POOL_MAX then break end
			end
		end
	end

	-- Surface biome column generation (done after the main loop to avoid per-voxel biome dispatch)
	if has_surface and #lazarus_space.bio_surface_biomes > 0 then
		local surf_y_min = math_max(minp.y, SURFACE_BASE)
		local surf_y_max = math_min(maxp.y, UPPER_ASTEROID_MIN - 101)

		-- Pre-allocate reusable tables to avoid per-column allocation
		local col_cave_shape = {}
		local col_cave_detail = {}
		local ctx = {
			x = 0, z = 0,
			terrain_height = 0,
			height_noise = 0, detail_noise = 0, detail_weight = 0,
			data = data, area = area, c = c,
			y_min = surf_y_min, y_max = surf_y_max,
			cave_shape_noise = col_cave_shape,
			cave_detail_noise = col_cave_detail,
		}

		local ni2d = 0
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ni2d = ni2d + 1

				local biome_a = column_biome[ni2d]
				if not biome_a then
					-- No registered biome for this noise range - fill with default flesh
					local terrain_h = SURFACE_BASE + 5
					for y = surf_y_min, math_min(maxp.y, terrain_h) do
						local vi = area:index(x, y, z)
						data[vi] = c.flesh
					end
					-- Log warning once
					local noise_val = nbuf.surface_biome[ni2d]
					local warn_key = math_floor(noise_val * 10)
					if not unwarned_ranges[warn_key] then
						unwarned_ranges[warn_key] = true
						minetest.log("warning", "[lazarus_space] No surface biome registered for noise value " .. noise_val)
					end
				else
					local terrain_h = column_height[ni2d]

					-- Skip empty columns: terrain below chunk floor
					if terrain_h and terrain_h < surf_y_min then
						goto continue_column
					end

					local biome_b = column_biome_b[ni2d]
					local blend = column_blend[ni2d]
					local detail_w = column_detail_weight[ni2d]

					-- Determine which biome generates this column
					local active_biome = biome_a
					if biome_b and blend then
						-- Stochastic blend: hash position to pick which biome generates
						local h = pos_hash_2d(x, z) % 100
						if h < blend * 100 then
							active_biome = biome_b
						end
					end

					if surf_y_min <= surf_y_max then
						-- Fast solid fill: terrain above chunk ceiling
						if terrain_h and terrain_h > surf_y_max then
							for y = surf_y_min, surf_y_max do
								local vi = area:index(x, y, z)
								data[vi] = c.flesh
							end
							goto continue_column
						end

						local height_noise = nbuf.terrain_height[ni2d]
						local detail_noise = nbuf.terrain_detail[ni2d]

						-- Build 3D noise accessor for this column (reuse tables)
						-- Clear previous entries
						for k in pairs(col_cave_shape) do col_cave_shape[k] = nil end
						for k in pairs(col_cave_detail) do col_cave_detail[k] = nil end
						if nbuf.cave_shape and nbuf.cave_detail then
							for y = surf_y_min, surf_y_max do
								local ni3d_col = (z - minp.z) * ylen * sidelen + (y - minp.y) * sidelen + (x - minp.x) + 1
								col_cave_shape[y] = nbuf.cave_shape[ni3d_col]
								col_cave_detail[y] = nbuf.cave_detail[ni3d_col]
							end
						end

						-- Update reusable context table
						ctx.x = x
						ctx.z = z
						ctx.terrain_height = terrain_h
						ctx.height_noise = height_noise
						ctx.detail_noise = detail_noise
						ctx.detail_weight = detail_w
						ctx.y_min = surf_y_min
						ctx.y_max = surf_y_max

						active_biome.generate_column(ctx)
					end
				end
				::continue_column::
			end
		end
	end

	-- =================================================================
	-- Cleanup Pass: Remove thin noise artifacts and floating blocks
	-- Only applies to surface biome zone (SURFACE_BASE to UPPER_ASTEROID_MIN)
	-- =================================================================
	if has_surface then
		local c_air_id = c.air

		-- Set of content IDs that should NOT be cleaned up
		-- (plantlike, liquids, cell-based structure internals)
		local no_cleanup = {}
		no_cleanup[c.bio_grass_1]        = true
		no_cleanup[c.bio_grass_3]        = true
		no_cleanup[c.bio_tendril]        = true
		no_cleanup[c.bio_polyp_plant]    = true
		no_cleanup[c.cave_shroom_small]  = true
		no_cleanup[c.cave_shroom_bright] = true
		no_cleanup[c.glowing_mushroom]   = true
		no_cleanup[c.cave_vine]          = true
		no_cleanup[c.plasma_source]      = true
		no_cleanup[c.bile_source]        = true
		no_cleanup[c.pus_source]         = true
		no_cleanup[c.marrow_source]      = true
		no_cleanup[c.water_source]       = true
		no_cleanup[c.fat_tissue]         = true
		no_cleanup[c.keratin]            = true

		local cleanup_min_y = math_max(minp.y, SURFACE_BASE)
		local cleanup_max_y = math_min(maxp.y, UPPER_ASTEROID_MIN - 101)

		-- Pass: remove isolated thin blocks and floating blocks
		-- A block is "isolated thin" if air on both sides of any axis
		-- A block is "floating" if it has 0 or 1 solid face-neighbors
		for z = minp.z + 1, maxp.z - 1 do
			for y = cleanup_min_y + 1, cleanup_max_y - 1 do
				for x = minp.x + 1, maxp.x - 1 do
					local vi = area:index(x, y, z)
					local node_id = data[vi]

					-- Skip air, skip protected nodes
					if node_id ~= c_air_id and not no_cleanup[node_id] then
						-- Check if above continuous ground fill
						-- (only clean up blocks above terrain surface)
						local ni2d_check = (z - minp.z) * sidelen + (x - minp.x) + 1
						local terrain_h = column_height[ni2d_check]
						if terrain_h and y > terrain_h then
							-- Count solid face neighbors
							local vi_xp = area:index(x + 1, y, z)
							local vi_xn = area:index(x - 1, y, z)
							local vi_yp = area:index(x, y + 1, z)
							local vi_yn = area:index(x, y - 1, z)
							local vi_zp = area:index(x, y, z + 1)
							local vi_zn = area:index(x, y, z - 1)

							local solid_neighbors = 0
							if data[vi_xp] ~= c_air_id then solid_neighbors = solid_neighbors + 1 end
							if data[vi_xn] ~= c_air_id then solid_neighbors = solid_neighbors + 1 end
							if data[vi_yp] ~= c_air_id then solid_neighbors = solid_neighbors + 1 end
							if data[vi_yn] ~= c_air_id then solid_neighbors = solid_neighbors + 1 end
							if data[vi_zp] ~= c_air_id then solid_neighbors = solid_neighbors + 1 end
							if data[vi_zn] ~= c_air_id then solid_neighbors = solid_neighbors + 1 end

							-- Remove thin walls: air on both opposing sides of any axis
							local thin_x = (data[vi_xp] == c_air_id and data[vi_xn] == c_air_id)
							local thin_y = (data[vi_yp] == c_air_id and data[vi_yn] == c_air_id)
							local thin_z = (data[vi_zp] == c_air_id and data[vi_zn] == c_air_id)

							if thin_x or thin_y or thin_z then
								data[vi] = c_air_id
							-- Remove floating blocks (0-1 solid neighbors)
							elseif solid_neighbors <= 1 then
								data[vi] = c_air_id
							end
						end
					end
				end
			end
		end
	end

	-- =================================================================
	-- Large Hollow Egg Structures
	-- Three variants: ocean floor, surface, and cave
	-- =================================================================

	-- Shared egg helper: place an elongated spheroid with decaying membrane walls
	-- cx,cy,cz = center; rx = horizontal radius; ry = vertical radius (rx * 1.4)
	-- decay_pct = 0.20-0.35; broken_top = true to remove top 25%
	-- fill_plasma_below = y level below which interior is plasma_static
	-- floor_items = table of {id=content_id, chance=N} for interior floor scatter
	local function place_hollow_egg(data, area, cx, cy, cz, rx, ry, decay_pct,
	                                broken_top, fill_plasma_below, floor_items, egg_seed)
		local inner_rx = math_max(1, rx - 2)
		local inner_ry = math_max(1, ry - 2)
		local rx2 = rx * rx
		local ry2 = ry * ry
		local irx2 = inner_rx * inner_rx
		local iry2 = inner_ry * inner_ry

		local egg_bottom = cy - ry
		local egg_top = cy + ry
		local egg_height = ry * 2

		-- Broken top: remove top 25%
		local broken_top_y = broken_top and (cy + math_floor(ry * 0.5)) or (egg_top + 1)

		for ey = math_max(egg_bottom, minp.y), math_min(egg_top, maxp.y) do
			-- Skip blocks above broken top
			if ey >= broken_top_y then goto continue_egg_y end

			for ez = math_max(cz - rx, minp.z), math_min(cz + rx, maxp.z) do
				for ex = math_max(cx - rx, minp.x), math_min(cx + rx, maxp.x) do
					local dx = ex - cx
					local dy = ey - cy
					local dz = ez - cz

					-- Ellipsoid distance: (dx/rx)^2 + (dy/ry)^2 + (dz/rx)^2
					local outer_dist = (dx * dx) / rx2 + (dy * dy) / ry2 + (dz * dz) / rx2
					if outer_dist > 1.0 then goto continue_egg_x end

					local inner_dist = (dx * dx) / irx2 + (dy * dy) / iry2 + (dz * dz) / irx2
					local vi = area:index(ex, ey, ez)

					if inner_dist > 1.0 then
						-- Wall zone: membrane with decay
						local h_frac = (ey - egg_bottom) / egg_height -- 0=bottom, 1=top
						-- More decay in bottom 40%
						local eff_decay = decay_pct
						if h_frac < 0.4 then
							eff_decay = decay_pct * 1.5
						end
						-- Chunky decay: hash in 3-block groups
						local gx = math_floor(ex / 3)
						local gy = math_floor(ey / 3)
						local gz = math_floor(ez / 3)
						local decay_hash = pos_hash(gx + egg_seed, gy, gz)
						if (decay_hash % 1000) / 1000 < eff_decay then
							-- Decay hole: leave as-is (air or existing terrain)
						else
							data[vi] = c.congealed_plasma
						end
					else
						-- Interior zone
						if fill_plasma_below and ey <= fill_plasma_below then
							data[vi] = c.plasma_source
						else
							-- Floor: scatter items on lowest interior layer
							if dy >= ry - 3 and outer_dist > 0.7 then
								-- Near the inner bottom curve, skip (wall region)
							else
								-- Check if this is near the floor (bottom of interior)
								-- Floor = first air layer above the wall bottom
								local floor_dist = (dx * dx) / irx2 + ((dy + 1) * (dy + 1)) / iry2 + (dz * dz) / irx2
								if floor_dist > 1.0 and inner_dist <= 1.0 then
									-- This is the floor layer
									local floor_hash = pos_hash(ex, ey + egg_seed, ez)
									local placed = false
									if floor_items then
										for _, item in ipairs(floor_items) do
											if not placed and floor_hash % 100 < item.chance then
												data[vi] = item.id
												placed = true
											end
										end
									end
									if not placed then
										data[vi] = c.air
									end
								else
									data[vi] = c.air
								end
							end
						end
					end

					::continue_egg_x::
				end
			end
			::continue_egg_y::
		end
	end

	-- ----- Variant A: Massive Ocean Floor Eggs -----
	if has_plasma then
		local OCEAN_EGG_CELL = 200
		local OCEAN_EGG_SEED = 73291

		-- Determine which cells could overlap this chunk
		local cell_x_min = math_floor((minp.x - 50) / OCEAN_EGG_CELL)
		local cell_x_max = math_floor((maxp.x + 50) / OCEAN_EGG_CELL)
		local cell_z_min = math_floor((minp.z - 50) / OCEAN_EGG_CELL)
		local cell_z_max = math_floor((maxp.z + 50) / OCEAN_EGG_CELL)

		for ocx = cell_x_min, cell_x_max do
			for ocz = cell_z_min, cell_z_max do
				local oh = pos_hash_2d(ocx, ocz, OCEAN_EGG_SEED)
				-- 15% chance per cell
				if oh % 100 >= 15 then goto continue_ocean_egg end

				local rng_oe = PcgRandom(oh)
				local egg_width = rng_oe:next(25, 50)
				local egg_rx = math_floor(egg_width / 2)
				local egg_ry = math_floor(egg_rx * 1.4)

				local egg_cx = ocx * OCEAN_EGG_CELL + rng_oe:next(egg_rx + 5, OCEAN_EGG_CELL - egg_rx - 5)
				local egg_cz = ocz * OCEAN_EGG_CELL + rng_oe:next(egg_rx + 5, OCEAN_EGG_CELL - egg_rx - 5)
				-- Resting on ocean floor, bottom 20% embedded
				local embed = math_floor(egg_ry * 0.2)
				local egg_cy = PLASMA_MIN - embed + egg_ry

				-- Check if this egg overlaps the current chunk
				if egg_cx + egg_rx < minp.x or egg_cx - egg_rx > maxp.x then goto continue_ocean_egg end
				if egg_cz + egg_rx < minp.z or egg_cz - egg_rx > maxp.z then goto continue_ocean_egg end
				if egg_cy + egg_ry < minp.y or egg_cy - egg_ry > maxp.y then goto continue_ocean_egg end

				local decay = 0.20 + (rng_oe:next(0, 15) / 100)
				local floor_items = {
					{id = c.mucus, chance = 30},
					{id = c.dirt, chance = 15},
				}

				place_hollow_egg(data, area, egg_cx, egg_cy, egg_cz, egg_rx, egg_ry,
					decay, false, PLASMA_MIN, floor_items, oh % 100000)

				-- 1 in 4: steelblock cluster inside on the floor
				if rng_oe:next(1, 4) == 1 then
					local num_steel = rng_oe:next(3, 6)
					for si = 1, num_steel do
						local sx = egg_cx + rng_oe:next(-math_floor(egg_rx * 0.4), math_floor(egg_rx * 0.4))
						local sz = egg_cz + rng_oe:next(-math_floor(egg_rx * 0.4), math_floor(egg_rx * 0.4))
						-- Place on the interior floor (just above the bottom wall)
						local sy = egg_cy - egg_ry + 3
						if sy >= minp.y and sy <= maxp.y and sx >= minp.x and sx <= maxp.x and sz >= minp.z and sz <= maxp.z then
							local vi = area:index(sx, sy, sz)
							data[vi] = c.steelblock
						end
					end
				end

				::continue_ocean_egg::
			end
		end
	end

	-- ----- Variant B: Medium Surface Eggs -----
	if has_surface then
		local SURFACE_EGG_SEED = 49217

		local ni2d_se = 0
		local surface_egg_count = 0
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ni2d_se = ni2d_se + 1
				if surface_egg_count >= 2 then break end

				local terrain_h = column_height[ni2d_se]
				if not terrain_h or terrain_h < SURFACE_BASE or terrain_h > UPPER_ASTEROID_MIN then
					goto continue_surface_egg
				end

				local ph_se = pos_hash_2d(x, z, SURFACE_EGG_SEED)
				if ph_se % 25000 ~= 0 then goto continue_surface_egg end

				local rng_se = PcgRandom(ph_se)
				local egg_width = rng_se:next(8, 16)
				local egg_rx = math_floor(egg_width / 2)
				local egg_ry = math_floor(egg_rx * 1.4)

				-- Embedded 30% in ground
				local embed = math_floor(egg_ry * 0.3)
				local egg_cy = terrain_h - embed + egg_ry

				-- 30% chance of broken top
				local broken = rng_se:next(1, 100) <= 30

				local decay = 0.20 + (rng_se:next(0, 15) / 100)
				local floor_items = {
					{id = c.mucus, chance = 30},
					{id = c.dirt, chance = 15},
					{id = c.bio_grass_1, chance = 5},
				}

				place_hollow_egg(data, area, x, egg_cy, z, egg_rx, egg_ry,
					decay, broken, nil, floor_items, ph_se % 100000)

				surface_egg_count = surface_egg_count + 1
				::continue_surface_egg::
			end
			if surface_egg_count >= 2 then break end
		end
	end

	-- ----- Variant C: Medium Cave Eggs -----
	if has_caves then
		local CAVE_EGG_SEED = 38471
		local cave_egg_count = 0
		local MAX_CAVE_EGGS = 2

		local cave_y_min = math_max(minp.y, ORGANIC_CAVE_MIN)
		local cave_y_max = math_min(maxp.y, PLASMA_BARRIER_BOTTOM_MIN)

		if cave_y_min <= cave_y_max then
			for z = minp.z + 6, maxp.z - 6, 4 do
				for x = minp.x + 6, maxp.x - 6, 4 do
					if cave_egg_count >= MAX_CAVE_EGGS then break end

					local ph_ce = pos_hash_2d(x, z, CAVE_EGG_SEED)
					if ph_ce % 400 ~= 0 then goto continue_cave_egg end

					-- Find a cave floor: solid below, air above
					local floor_y = nil
					for y = cave_y_min, cave_y_max - 8 do
						local vi = area:index(x, y, z)
						local vi_above = area:index(x, y + 1, z)
						if data[vi] ~= c.air and data[vi] ~= c.ignore and data[vi_above] == c.air then
							-- Check enough headroom (at least 8 blocks of air)
							local headroom = 0
							for hy = y + 1, math_min(y + 20, cave_y_max) do
								local hvi = area:index(x, hy, z)
								if data[hvi] == c.air then
									headroom = headroom + 1
								else
									break
								end
							end
							if headroom >= 8 then
								floor_y = y
								break
							end
						end
					end

					if not floor_y then goto continue_cave_egg end

					local rng_ce = PcgRandom(ph_ce)
					local egg_width = rng_ce:next(6, 12)
					local egg_rx = math_floor(egg_width / 2)
					local egg_ry = math_floor(egg_rx * 1.4)

					-- Sitting on cave floor
					local egg_cy = floor_y + 1 + egg_ry

					local decay = 0.20 + (rng_ce:next(0, 15) / 100)
					local floor_items = {
						{id = c.mucus, chance = 30},
					}

					place_hollow_egg(data, area, x, egg_cy, z, egg_rx, egg_ry,
						decay, false, nil, floor_items, ph_ce % 100000)

					-- 1-2 glowing_mushroom inside on the floor
					local num_shrooms = rng_ce:next(1, 2)
					for si = 1, num_shrooms do
						local sx = x + rng_ce:next(-math_floor(egg_rx * 0.5), math_floor(egg_rx * 0.5))
						local sz = z + rng_ce:next(-math_floor(egg_rx * 0.5), math_floor(egg_rx * 0.5))
						local sy = floor_y + 2
						if sy >= minp.y and sy <= maxp.y and sx >= minp.x and sx <= maxp.x and sz >= minp.z and sz <= maxp.z then
							local vi = area:index(sx, sy, sz)
							if data[vi] == c.air then
								data[vi] = c.glowing_mushroom
							end
						end
					end

					cave_egg_count = cave_egg_count + 1
					::continue_cave_egg::
				end
				if cave_egg_count >= MAX_CAVE_EGGS then break end
			end
		end
	end

	vm:set_data(data)
	vm:calc_lighting()
	vm:write_to_map()
	vm:update_liquids()

	-- =================================================================
	-- Post-VoxelManip Schematic Placement
	-- place_schematic works on the map directly, so must be after write_to_map
	-- =================================================================
	local MAX_SCHEMATICS_PER_CHUNK = 5
	local schematic_count = 0

	-- Helper: deterministic position hash for schematic selection
	local function schem_hash(x, z, seed)
		seed = seed or 0
		local h = (x * 374761393 + z * 668265263 + blockseed + seed) % 2147483647
		h = ((h * 1103515245) + 12345) % 2147483647
		h = ((h * 1103515245) + 12345) % 2147483647
		return h
	end

	-- Surface biome schematic placement
	if has_surface and lazarus_space.schematics and lazarus_space.schematic_placement
		and #lazarus_space.bio_surface_biomes > 0 then

		local placement = lazarus_space.schematic_placement
		local schematics = lazarus_space.schematics
		local yoffsets = lazarus_space.schematic_yoffsets or {}

		local ni2d = 0
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ni2d = ni2d + 1
				if schematic_count >= MAX_SCHEMATICS_PER_CHUNK then
					break
				end

				local biome_a = column_biome[ni2d]
				if not biome_a then
					goto continue_schem
				end

				local terrain_h = column_height[ni2d]
				if not terrain_h or terrain_h < SURFACE_BASE or terrain_h > UPPER_ASTEROID_MIN then
					goto continue_schem
				end

				-- Surface position is terrain_h + 1
				local surface_y = terrain_h + 1
				if surface_y < minp.y or surface_y > maxp.y then
					goto continue_schem
				end

				local ph = schem_hash(x, z, 1)
				local biome_name = biome_a.name

				-- Priority 1: Grass patches (most common)
				if placement.grass then
					-- Ground check: skip grass if center ground is not solid/walkable
					local gn = minetest.get_node({x = x, y = terrain_h, z = z})
					local gndef = minetest.registered_nodes[gn.name]
					if gndef and gndef.walkable then
						-- Marsh grass reduction: 50% density in abscess_marsh
						local grass_tall_chance = 320
						local grass_chance = 120
						if biome_name == "abscess_marsh" then
							grass_tall_chance = 640
							grass_chance = 240
						end
						-- Tall grass patch (separate hash seed to break line patterns)
						local ph_tg = schem_hash(x, z, 77)
						if ph_tg % grass_tall_chance == 0 and schematics.grass_tall_patch then
							local pos = {x = x - 2, y = surface_y, z = z - 2}
							minetest.place_schematic(pos, schematics.grass_tall_patch, "random", nil, false)
							schematic_count = schematic_count + 1
							goto continue_schem
						-- Regular grass patch
						elseif ph % grass_chance == 1 and schematics.grass_patch then
							local pos = {x = x - 1, y = surface_y, z = z - 1}
							minetest.place_schematic(pos, schematics.grass_patch, "random", nil, false)
							schematic_count = schematic_count + 1
							goto continue_schem
						end
					end
				end

				-- Priority 2: Fleshy mushrooms
				if placement.mushroom and placement.mushroom.biome_chances[biome_name] then
					local chance = placement.mushroom.biome_chances[biome_name]
					local ph_m = schem_hash(x, z, 2)  -- seed 2: mushrooms
					if ph_m % chance == 2 then
						-- Select variant
						local variants = placement.mushroom.biome_variants[biome_name]
							or placement.mushroom.variants
						local variant_name = variants[(ph_m % #variants) + 1]
						local schem = schematics[variant_name]
						if schem then
							local yoff = yoffsets[variant_name] or 0
							local half_x = math_floor((schem.size.x - 1) / 2)
							local half_z = math_floor((schem.size.z - 1) / 2)
							local pos = {x = x - half_x, y = surface_y + yoff, z = z - half_z}
							minetest.place_schematic(pos, schem, "random", nil, false)
							schematic_count = schematic_count + 1
							goto continue_schem
						end
					end
				end

				-- Priority 3: Skeletons (rarest)
				if placement.skeleton and placement.skeleton.biome_chances[biome_name] then
					local ph_s = schem_hash(x, z, 3)  -- seed 3: skeletons
					local chance = placement.skeleton.biome_chances[biome_name]
					if ph_s % chance == 3 then
						local variants = placement.skeleton.biome_variants[biome_name]
							or placement.skeleton.variants
						local variant_name = variants[(ph_s % #variants) + 1]
						local schem = schematics[variant_name]
						if schem then
							local yoff = yoffsets[variant_name] or 0
							local half_x = math_floor((schem.size.x - 1) / 2)
							local half_z = math_floor((schem.size.z - 1) / 2)
							local pos = {x = x - half_x, y = surface_y + yoff, z = z - half_z}
							minetest.place_schematic(pos, schem, "random", nil, false)
							schematic_count = schematic_count + 1
						end
					end
				end

				-- Priority 4: Ruins (placeholder structures)
				if placement.ruin and placement.ruin.biome_chances[biome_name] then
					local ph_r = schem_hash(x, z, 4)  -- seed 4: ruins
					local chance = placement.ruin.biome_chances[biome_name]
					if ph_r % chance == 4 then
						local variants = placement.ruin.biome_variants[biome_name]
							or placement.ruin.variants
						local variant_name = variants[(ph_r % #variants) + 1]
						local schem = schematics[variant_name]
						if schem then
							local yoff = yoffsets[variant_name] or 0
							local half_x = math_floor((schem.size.x - 1) / 2)
							local half_z = math_floor((schem.size.z - 1) / 2)
							local pos = {x = x - half_x, y = surface_y + yoff, z = z - half_z}
							minetest.place_schematic(pos, schem, "random", nil, false)
							schematic_count = schematic_count + 1
						end
					end
				end

				-- Priority 5: Outposts (Vein Flats — flat terrain only)
				if placement.outpost and placement.outpost.biome_chances[biome_name] then
					local ph_o = schem_hash(x, z, 5)  -- seed 5: outposts
					local chance = placement.outpost.biome_chances[biome_name]
					if ph_o % chance == 5 then
						-- Flatness check: surface within ±1 of neighbors
						local flat = true
						local h_ref = terrain_h
						for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
							local ni2d_n = ((z + off[2]) - minp.z) * sidelen + ((x + off[1]) - minp.x) + 1
							local h_n = column_height[ni2d_n]
							if not h_n or math_abs(h_n - h_ref) > 1 then
								flat = false
								break
							end
						end
						if flat then
							local variants = placement.outpost.variants
							local variant_name = variants[(ph_o % #variants) + 1]
							local schem = schematics[variant_name]
							if schem then
								local yoff = yoffsets[variant_name] or 0
								local half_x = math_floor((schem.size.x - 1) / 2)
								local half_z = math_floor((schem.size.z - 1) / 2)
								local pos = {x = x - half_x, y = surface_y + yoff, z = z - half_z}
								minetest.place_schematic(pos, schem, "random", nil, false)
								schematic_count = schematic_count + 1
							end
						end
					end
				end

				::continue_schem::
			end
			if schematic_count >= MAX_SCHEMATICS_PER_CHUNK then
				break
			end
		end
	end

	-- Cave layer schematic placement (mushrooms and skeletons on cave floors)
	if has_caves and schematic_count < MAX_SCHEMATICS_PER_CHUNK
		and lazarus_space.schematics and lazarus_space.schematic_placement then

		local placement = lazarus_space.schematic_placement
		local schematics = lazarus_space.schematics

		if placement.cave then
			-- Sample a grid of positions in the cave layer to check for floors
			local cave_y_min = math_max(minp.y, ORGANIC_CAVE_MIN)
			local cave_y_max = math_min(maxp.y, PLASMA_BARRIER_BOTTOM_MIN - 1)

			for z = minp.z + 2, maxp.z - 2, 4 do
				for x = minp.x + 2, maxp.x - 2, 4 do
					if schematic_count >= MAX_SCHEMATICS_PER_CHUNK then
						break
					end

					local ph = schem_hash(x, z, 1)

					-- Find a cave floor in this column
					for y = cave_y_min, cave_y_max - 1 do
						local vi = area:index(x, y, z)
						local vi_above = area:index(x, y + 1, z)
						-- Floor: solid below, air above
						if data[vi] ~= c.air and data[vi_above] == c.air then
							local surface_y = y + 1
							-- Cave mushroom
							if ph % placement.cave.mushroom_chance == 0 and schematics.flesh_mushroom_small then
								local pos = {x = x - 1, y = surface_y, z = z - 1}
								minetest.place_schematic(pos, schematics.flesh_mushroom_small, "random", nil, false)
								schematic_count = schematic_count + 1
							-- Cave skeleton
							elseif ph % placement.cave.skeleton_chance == 1 and schematics.skeleton_small then
								local pos = {x = x - 2, y = surface_y, z = z - 1}
								minetest.place_schematic(pos, schematics.skeleton_small, "random", nil, false)
								schematic_count = schematic_count + 1
							end
							break  -- Only use first floor in column
						end
					end
				end
				if schematic_count >= MAX_SCHEMATICS_PER_CHUNK then
					break
				end
			end
		end
	end

	-- =================================================================
	-- Egg Cluster Generation (membrane/mucus spheroids on surfaces)
	-- =================================================================
	if has_surface and #lazarus_space.bio_surface_biomes > 0 then
		local EGG_SEED = 94127
		local egg_count = 0
		local MAX_EGGS_PER_CHUNK = 2

		local egg_shell_positions = {}
		local egg_core_positions = {}

		local ni2d_egg = 0
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ni2d_egg = ni2d_egg + 1
				if egg_count >= MAX_EGGS_PER_CHUNK then break end

				local biome_a = column_biome[ni2d_egg]
				if not biome_a then goto continue_egg end

				local terrain_h = column_height[ni2d_egg]
				if not terrain_h or terrain_h < SURFACE_BASE or terrain_h > UPPER_ASTEROID_MIN then
					goto continue_egg
				end

				local ph_egg = pos_hash_2d(x, z, EGG_SEED)
				if ph_egg % 65000 ~= 0 then goto continue_egg end

				-- Flatness check: surface within ±2 of neighbors
				local flat = true
				for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
					local ni2d_n = ((z + off[2]) - minp.z) * sidelen + ((x + off[1]) - minp.x) + 1
					local h_n = column_height[ni2d_n]
					if not h_n or math_abs(h_n - terrain_h) > 2 then
						flat = false
						break
					end
				end
				if not flat then goto continue_egg end

				-- Generate egg cluster: 3-6 spheroids
				local rng_egg = PcgRandom(ph_egg)
				local num_eggs = rng_egg:next(3, 6)
				local surface_y = terrain_h

				for ei = 1, num_eggs do
					local egg_dx = rng_egg:next(-11, 11)
					local egg_dz = rng_egg:next(-11, 11)
					local egg_r = rng_egg:next(2, 4)  -- radius 2-4 (33% larger)
					local egg_cx = x + egg_dx
					local egg_cz = z + egg_dz
					-- Center the egg so bottom 40% is below surface
					local egg_cy = surface_y + math_floor(egg_r * 0.6)

					-- Place spheroid blocks
					for ey = egg_cy - egg_r, egg_cy + egg_r do
						for ez = egg_cz - egg_r, egg_cz + egg_r do
							for ex = egg_cx - egg_r, egg_cx + egg_r do
								local edx = ex - egg_cx
								local edy = ey - egg_cy
								local edz = ez - egg_cz
								local edist_sq = edx * edx + edy * edy + edz * edz
								local r_sq = egg_r * egg_r

								if edist_sq <= r_sq then
									local epos = {x = ex, y = ey, z = ez}
									local existing = minetest.get_node(epos)
									-- Only place in air or on surface blocks
									if existing.name == "air" or ey <= surface_y then
										if edist_sq > (egg_r - 1) * (egg_r - 1) then
											egg_shell_positions[#egg_shell_positions + 1] = epos
										else
											egg_core_positions[#egg_core_positions + 1] = epos
										end
									end
								end
							end
						end
					end
				end

				egg_count = egg_count + 1
				::continue_egg::
			end
			if egg_count >= MAX_EGGS_PER_CHUNK then break end
		end

		-- Flush batched egg cluster nodes
		if #egg_shell_positions > 0 then
			minetest.bulk_set_node(egg_shell_positions, {name = "lazarus_space:congealed_plasma"})
		end
		if #egg_core_positions > 0 then
			minetest.bulk_set_node(egg_core_positions, {name = "lazarus_space:mucus"})
		end
	end

	-- =================================================================
	-- Spine Tree Generation (vertebral column structures on flat flesh)
	-- =================================================================
	if has_surface and #lazarus_space.bio_surface_biomes > 0 then
		local SPINE_SEED = 61483
		local spine_count = 0
		local MAX_SPINES_PER_CHUNK = 2

		local spine_bone_positions = {}
		local spine_cartilage_positions = {}
		local spine_fatty_nerve_positions = {}

		-- Biome-specific placement rates
		local spine_chances = {
			rib_fields = 4000,
			vein_flats = 3500,
			nerve_thicket = 5000,
		}

		local ni2d_sp = 0
		for z = minp.z, maxp.z do
			for x = minp.x, maxp.x do
				ni2d_sp = ni2d_sp + 1
				if spine_count >= MAX_SPINES_PER_CHUNK then break end

				local biome_a = column_biome[ni2d_sp]
				if not biome_a then goto continue_spine end

				local chance = spine_chances[biome_a.name]
				if not chance then goto continue_spine end

				local terrain_h = column_height[ni2d_sp]
				if not terrain_h or terrain_h < SURFACE_BASE or terrain_h > UPPER_ASTEROID_MIN then
					goto continue_spine
				end

				local ph_sp = pos_hash_2d(x, z, SPINE_SEED)
				if ph_sp % chance ~= 0 then goto continue_spine end

				-- Flatness check: surface within ±1 of neighbors
				local flat = true
				for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
					local ni2d_n = ((z + off[2]) - minp.z) * sidelen + ((x + off[1]) - minp.x) + 1
					local h_n = column_height[ni2d_n]
					if not h_n or math_abs(h_n - terrain_h) > 1 then
						flat = false
						break
					end
				end
				if not flat then goto continue_spine end

				-- Generate spine tree
				local rng_sp = PcgRandom(ph_sp)
				local spine_height = rng_sp:next(20, 45)
				local surface_y = terrain_h

				-- Segment layout: 3 bone + 1 cartilage = 4 blocks per segment
				local SEGMENT_HEIGHT = 4

				-- Branch parameters
				local branch_interval = rng_sp:next(8, 12)
				local branch_dirs = {{1,0},{-1,0},{0,1},{0,-1}}
				local last_branch_dir = 0

				-- Trunk: vertebral column
				for h = -2, spine_height do
					local ty = surface_y + h

					-- Determine cross-section width
					local cross_size
					if h <= 0 then
						-- Base: 5×5 (with rounded corners)
						cross_size = 5
					elseif h >= spine_height - 7 then
						-- Crown: narrow to 1×1
						cross_size = 1
					else
						-- Normal: 3×3 (with corners cut)
						cross_size = 3
					end

					local half = math_floor(cross_size / 2)

					-- Determine material based on segment position
					local seg_pos = h % SEGMENT_HEIGHT
					local is_cartilage_disc = (seg_pos == 3 and h > 0 and h < spine_height - 7)

					for dx = -half, half do
						for dz = -half, half do
							-- Round corners for cross-sections > 1
							if cross_size >= 3 then
								-- Cut diagonal corners
								if math_abs(dx) == half and math_abs(dz) == half then
									goto skip_spine_block
								end
							end
							if cross_size >= 5 then
								-- Also cut near-diagonal corners for 5×5
								if math_abs(dx) == half and math_abs(dz) >= half - 1 then
									goto skip_spine_block
								end
								if math_abs(dz) == half and math_abs(dx) >= half - 1 then
									goto skip_spine_block
								end
							end

							local bx = x + dx
							local bz = z + dz
							local bpos = {x = bx, y = ty, z = bz}
							local existing = minetest.get_node(bpos)
							if existing.name == "air" or h <= 0 then
								if is_cartilage_disc then
									spine_cartilage_positions[#spine_cartilage_positions + 1] = bpos
								else
									spine_bone_positions[#spine_bone_positions + 1] = bpos
								end
							end

							::skip_spine_block::
						end
					end

					-- Branches (nerve roots) at regular intervals
					if h > 0 and h < spine_height - 7 and h % branch_interval == 0 then
						local num_branches = rng_sp:next(1, 2)
						for bi = 1, num_branches do
							-- Pick direction, avoiding same as last
							local dir_idx = rng_sp:next(1, 4)
							if dir_idx == last_branch_dir then
								dir_idx = (dir_idx % 4) + 1
							end
							last_branch_dir = dir_idx
							local dir = branch_dirs[dir_idx]

							local branch_len = rng_sp:next(3, 8)
							for bl = 1, branch_len do
								local bx = x + dir[1] * (bl + 1)
								local bz = z + dir[2] * (bl + 1)
								-- Slight upward angle: 1 block up per 2-3 blocks out
								local by = ty + math_floor(bl / 2.5)
								local bpos = {x = bx, y = by, z = bz}
								local existing = minetest.get_node(bpos)
								if existing.name == "air" then
									spine_fatty_nerve_positions[#spine_fatty_nerve_positions + 1] = bpos
								end
							end

							-- Dangling nerve_root at branch tip
							local tip_x = x + dir[1] * (branch_len + 1)
							local tip_z = z + dir[2] * (branch_len + 1)
							local tip_y = ty + math_floor(branch_len / 2.5)
							for dy = 1, rng_sp:next(1, 2) do
								local rpos = {x = tip_x, y = tip_y - dy, z = tip_z}
								local existing = minetest.get_node(rpos)
								if existing.name == "air" then
									spine_fatty_nerve_positions[#spine_fatty_nerve_positions + 1] = rpos
								end
							end
						end
					end
				end

				-- Base surface roots: 2-3 directions, extending 2-3 blocks outward
				local num_roots = rng_sp:next(2, 3)
				for ri = 1, num_roots do
					local dir = branch_dirs[rng_sp:next(1, 4)]
					local root_len = rng_sp:next(2, 3)
					for rl = 1, root_len do
						-- Taper: width decreases from 2 to 1
						local root_width = (rl <= root_len / 2) and 2 or 1
						for rw = 0, root_width - 1 do
							local rx = x + dir[1] * (rl + 2) + dir[2] * rw
							local rz = z + dir[2] * (rl + 2) + dir[1] * rw
							local rpos = {x = rx, y = surface_y + 1, z = rz}
							local existing = minetest.get_node(rpos)
							if existing.name == "air" then
								spine_bone_positions[#spine_bone_positions + 1] = rpos
							end
						end
					end
				end

				-- Crown: short nerve_fiber branches from top
				local crown_y = surface_y + spine_height
				for ci = 1, rng_sp:next(3, 4) do
					local dir = branch_dirs[rng_sp:next(1, 4)]
					local crown_len = rng_sp:next(3, 5)
					for cl = 1, crown_len do
						local cx = x + dir[1] * cl
						local cz = z + dir[2] * cl
						local cy = crown_y + math_floor(cl / 3)
						local cpos = {x = cx, y = cy, z = cz}
						local existing = minetest.get_node(cpos)
						if existing.name == "air" then
							spine_fatty_nerve_positions[#spine_fatty_nerve_positions + 1] = cpos
						end
					end
				end

				spine_count = spine_count + 1
				::continue_spine::
			end
			if spine_count >= MAX_SPINES_PER_CHUNK then break end
		end

		-- Flush batched spine tree nodes
		if #spine_bone_positions > 0 then
			minetest.bulk_set_node(spine_bone_positions, {name = "lazarus_space:bone"})
		end
		if #spine_cartilage_positions > 0 then
			minetest.bulk_set_node(spine_cartilage_positions, {name = "lazarus_space:cartilage"})
		end
		if #spine_fatty_nerve_positions > 0 then
			minetest.bulk_set_node(spine_fatty_nerve_positions, {name = "lazarus_space:fatty_nerve"})
		end
	end
end)

-- =============================================================================
-- Zone-Based Sky and Fog
-- =============================================================================

-- Track which zone each player is in to avoid redundant API calls
-- Values: nil (default), "bio_fog" (red fog)
local player_zone = {}
local fog_timer = 0

minetest.register_globalstep(function(dtime)
	fog_timer = fog_timer + dtime
	if fog_timer < 2.0 then
		return
	end
	fog_timer = 0

	for _, player in ipairs(minetest.get_connected_players()) do
		local pos = player:get_pos()
		local name = player:get_player_name()

		-- Determine current zone: only bio_fog or default
		local zone = nil
		if pos.y >= ORGANIC_CAVE_MIN and pos.y <= BIO_MAX then
			-- y=27006 to y=29200: biological interior (red fog)
			zone = "bio_fog"
		end
		-- Everything else (frozen asteroids, death space, overworld) = default sky

		local prev_zone = player_zone[name]

		if zone ~= prev_zone then
			if zone == "bio_fog" then
				-- FOG FIX: Using type="plain" because type="skybox" forces white fog
				-- in some Minetest/Luanti versions, ignoring set_fog() color.
				-- If your engine version supports skybox + fog_tint_type, switch to
				-- type="skybox" with sky_color.fog_tint_type = "custom".
				player:set_sky({
					type = "plain",
					base_color = {r = 30, g = 5, b = 5},
					clouds = false,
				})
				player:set_sun({visible = false, sunrise_visible = false})
				player:set_moon({visible = false})
				player:set_stars({visible = false})
				player:set_clouds({density = 0})
				player:override_day_night_ratio(0.35)
				if player.set_fog then
					player:set_fog({
						fog_start = 0.0,
						fog_distance = 100,
						fog_color = {r = 60, g = 10, b = 10},
					})
				end
			else
				-- Default: regular overworld sky (frozen asteroids, death space, etc.)
				player:set_sky({type = "regular"})
				player:set_sun({visible = true, sunrise_visible = true})
				player:set_moon({visible = true})
				player:set_stars({visible = true})
				player:set_clouds({density = 0.4})
				player:override_day_night_ratio(nil)
				if player.set_fog then
					player:set_fog({})
				end
			end

			player_zone[name] = zone
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	player_zone[player:get_player_name()] = nil
end)

-- =============================================================================
-- Load Biome Files from biomes/ Subdirectory
-- =============================================================================

local biome_dir = modpath .. "/biomes"
local biome_files = minetest.get_dir_list(biome_dir, false)
for _, filename in ipairs(biome_files) do
	if filename:match("%.lua$") then
		dofile(biome_dir .. "/" .. filename)
	end
end
