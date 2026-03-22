-- Nerve Thicket Surface Biome
-- Dense groves of massive nerve fiber trunks wrapped in myelin sheath,
-- with glowing nodes of Ranvier at regular intervals and tangled canopies
-- of branching axons overhead.

local SURFACE_BASE = 27775

-- =============================================================================
-- Utility
-- =============================================================================

local pos_hash = lazarus_space.pos_hash

-- =============================================================================
-- Node Registrations
-- =============================================================================

minetest.register_node("lazarus_space:fatty_nerve", {
	description = "Fatty Nerve",
	tiles = {"lazarus_space_fatty_nerve.png"},
	groups = {choppy = 2, cracky = 2},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("lazarus_space:glowing_nerve", {
	description = "Glowing Nerve",
	tiles = {"lazarus_space_glowing_nerve.png"},
	light_source = 5,
	groups = {choppy = 2},
	sounds = default.node_sound_wood_defaults(),
})

-- =============================================================================
-- Content ID Cache (biome-local)
-- =============================================================================

local c_fatty_nerve
local c_glowing_nerve
local c_flesh
local c_bio_grass_3, c_bio_tendril, c_bio_polyp_plant

-- =============================================================================
-- Nerve Tree Cell Parameters
-- =============================================================================

local CELL_SIZE = 15
local NERVE_SEED = 41827

-- =============================================================================
-- Nerve Tree Cell Helper
-- =============================================================================

-- Given cell coordinates, return deterministic nerve tree parameters.
local function get_nerve_tree_params(cell_x, cell_z)
	local hash = ((cell_x * 374761393 + cell_z * 668265263 + NERVE_SEED * 83492791) % 2147483647 * 1103515245 + 12345) % 2147483647
	local rng = PcgRandom(hash)

	local center_x = cell_x * CELL_SIZE + rng:next(2, 12)
	local center_z = cell_z * CELL_SIZE + rng:next(2, 12)
	local tree_height = rng:next(10, 20)
	local trunk_radius = rng:next(1, 2)

	-- Pre-compute myelin segment layout along the trunk using same rng
	local myelin_segments = {}
	local y_cursor = 0
	while y_cursor < tree_height do
		local interval = rng:next(6, 10)
		local span = rng:next(4, 8)
		local seg_start = y_cursor + interval
		local seg_end = seg_start + span
		if seg_start >= tree_height then
			break
		end
		if seg_end > tree_height then
			seg_end = tree_height
		end
		myelin_segments[#myelin_segments + 1] = {start = seg_start, stop = seg_end}
		-- After each myelin segment there is a 1-block node of Ranvier gap
		y_cursor = seg_end + 1
	end

	return {
		center_x = center_x,
		center_z = center_z,
		tree_height = tree_height,
		trunk_radius = trunk_radius,
		myelin_segments = myelin_segments,
	}
end

-- =============================================================================
-- Biome Registration
-- =============================================================================

lazarus_space.register_surface_biome({
	name = "nerve_thicket",
	noise_min = 0.15,
	noise_max = 0.35,
	base_height_offset = 5,
	height_amplitude = 2.5,
	detail_amplitude = 0.75,

	get_content_ids = function(c)
		c_fatty_nerve     = c.fatty_nerve
		c_glowing_nerve   = c.glowing_nerve
		c_flesh           = c.flesh
		c_bio_grass_3     = c.bio_grass_3
		c_bio_tendril     = c.bio_tendril
		c_bio_polyp_plant = c.bio_polyp_plant
	end,

	generate_column = function(ctx)
		local x              = ctx.x
		local z              = ctx.z
		local terrain_height = ctx.terrain_height
		local data           = ctx.data
		local area           = ctx.area
		local y_min          = ctx.y_min
		local y_max          = ctx.y_max
		local cave_detail_noise = ctx.cave_detail_noise

		-- Ensure we start no lower than SURFACE_BASE
		local fill_min = math.max(y_min, SURFACE_BASE)
		local fill_max = math.min(y_max, terrain_height)

		-- ==================================================================
		-- Gather nearby nerve trees (current cell + 8 surrounding)
		-- ==================================================================

		local cell_x = math.floor(x / CELL_SIZE)
		local cell_z = math.floor(z / CELL_SIZE)

		local nearby_trees = {}
		for dx = -1, 1 do
			for dz = -1, 1 do
				nearby_trees[#nearby_trees + 1] = get_nerve_tree_params(cell_x + dx, cell_z + dz)
			end
		end

		-- ==================================================================
		-- Determine proximity to any trunk footprint (for ground cover)
		-- ==================================================================

		local min_trunk_dist = math.huge
		for _, tree in ipairs(nearby_trees) do
			local dx = x + 0.0 - tree.center_x
			local dz = z + 0.0 - tree.center_z
			local dist = math.sqrt(dx * dx + dz * dz)
			if dist < min_trunk_dist then
				min_trunk_dist = dist
			end
		end

		-- ==================================================================
		-- Ground Fill
		-- ==================================================================

		for y = fill_min, fill_max do
			local vi = area:index(x, y, z)
			if y == terrain_height then
				-- Surface block: nerve_root if within 3 blocks of any trunk center
				if min_trunk_dist <= 3 then
					data[vi] = c_fatty_nerve
				else
					data[vi] = c_flesh
				end
			else
				data[vi] = c_flesh
			end
		end

		-- ==================================================================
		-- Surface Plants (only outside trunk footprints)
		-- ==================================================================
		if min_trunk_dist > 3 and terrain_height >= y_min and terrain_height < y_max then
			local plant_y = terrain_height + 1
			if plant_y <= y_max then
				local ph2d = ((x * 374761393 + z * 668265263 + 7) % 2147483647 * 1103515245 + 12345) % 2147483647
				local vi_plant = area:index(x, plant_y, z)
				if ph2d % 40 == 0 then
					data[vi_plant] = c_bio_polyp_plant
				elseif ph2d % 25 == 1 then
					data[vi_plant] = c_bio_tendril
				elseif ph2d % 12 == 2 then
					data[vi_plant] = c_bio_grass_3
				end
			end
		end

		-- ==================================================================
		-- Nerve Tree Structures
		-- ==================================================================

		for _, tree in ipairs(nearby_trees) do
			local cx = tree.center_x
			local cz = tree.center_z
			local tree_height = tree.tree_height
			local trunk_radius = tree.trunk_radius
			local myelin_segments = tree.myelin_segments

			local dx = x + 0.0 - cx
			local dz = z + 0.0 - cz
			local dist = math.sqrt(dx * dx + dz * dz)

			-- Canopy starts at 70% of tree height
			local canopy_start = math.floor(tree_height * 0.7)

			-- Maximum possible radius (at top of tree)
			local top_extra = (tree_height - canopy_start) * 0.4
			local max_radius = trunk_radius + top_extra

			-- Skip this tree entirely if column is too far away
			if dist > max_radius + 1 then
				goto continue_tree
			end

			local tree_y_min = math.max(y_min, terrain_height + 1)
			local tree_y_max = math.min(y_max, terrain_height + tree_height)

			for y = tree_y_min, tree_y_max do
				local h = y - terrain_height  -- height above ground

				-- Determine effective radius at this height
				local effective_radius
				if h >= canopy_start then
					-- Canopy: radius expands by 0.4 per block above canopy start
					effective_radius = trunk_radius + (h - canopy_start) * 0.4
				else
					effective_radius = trunk_radius
				end

				-- Check if this column is within the effective radius (with soft edge)
				local in_radius = dist <= effective_radius
				if not in_radius and dist <= effective_radius + 0.5 then
					in_radius = pos_hash(x, y, z) % 2 == 0
				end
				if in_radius then
					local vi = area:index(x, y, z)

					if h >= canopy_start then
						-- Canopy zone: tangled branching with gaps
						local cdn = cave_detail_noise[y]
						if cdn and cdn > -0.3 then
							data[vi] = c_fatty_nerve
						end
						-- else: leave gap (air) for irregular branching
					else
						-- Below canopy: solid trunk with myelin/ranvier features
						local is_outer = (dist > trunk_radius - 1) and (dist <= trunk_radius)

						if is_outer then
							-- Check if this height falls within a myelin segment
							local in_outer_sheath = false
							local is_ranvier = false

							for _, seg in ipairs(myelin_segments) do
								if h >= seg.start and h <= seg.stop then
									in_outer_sheath = true
									break
								end
								-- Node of Ranvier: the 1-block gap right after a segment
								if h == seg.stop + 1 then
									is_ranvier = true
									break
								end
							end

							if in_outer_sheath then
								data[vi] = c_fatty_nerve
							elseif is_ranvier then
								data[vi] = c_glowing_nerve
							else
								data[vi] = c_fatty_nerve
							end
						else
							-- Inner trunk
							data[vi] = c_fatty_nerve
						end
					end
				end
			end

			-- Ground cover: nerve_root within 2 blocks of trunk footprint
			if dist <= trunk_radius + 2 and terrain_height >= fill_min and terrain_height <= fill_max then
				local vi = area:index(x, terrain_height, z)
				data[vi] = c_fatty_nerve
			end

			::continue_tree::
		end
	end,
})
