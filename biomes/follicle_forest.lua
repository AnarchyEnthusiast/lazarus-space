-- Follicle Forest Surface Biome
-- A dense, dark vertical forest of giant hair follicles growing from oily
-- sebaceous terrain. Very low visibility, claustrophobic. Players navigate
-- between and climb massive follicle trunks.

local SURFACE_BASE = 27775

-- =============================================================================
-- Utility
-- =============================================================================

local function pos_hash(x, y, z)
	local h = (x * 374761393 + y * 668265263 + z * 83492791) % 2147483647; h = ((h * 1103515245) + 12345) % 2147483647; return ((h * 1103515245) + 12345) % 2147483647
end

-- =============================================================================
-- Content ID Cache (biome-local)
-- =============================================================================

local c_fat_tissue
local c_congealed_rotten_plasma
local c_keratin
local c_flesh
local c_mucus
local c_bio_grass_3
local c_air

-- =============================================================================
-- Follicle Cell Parameters
-- =============================================================================

local CELL_SIZE = 8
local FOLLICLE_SEED = 55913

-- =============================================================================
-- Follicle Cell Helper
-- =============================================================================

-- Given cell coordinates, return deterministic follicle parameters (or nil).
local function get_follicle_params(cell_x, cell_z)
	local hash = ((cell_x * 374761393 + cell_z * 668265263 + FOLLICLE_SEED * 83492791) % 2147483647 * 1103515245 + 12345) % 2147483647
	local rng = PcgRandom(hash)

	-- 40% chance of containing a follicle
	if rng:next(1, 100) > 40 then
		return nil
	end

	local center_x = cell_x * CELL_SIZE + rng:next(1, CELL_SIZE - 2)
	local center_z = cell_z * CELL_SIZE + rng:next(1, CELL_SIZE - 2)
	local outer_radius = rng:next(2, 4)
	local inner_radius = outer_radius - 1
	local height = rng:next(15, 40)
	local hair_height = rng:next(5, 15)
	local num_strands = rng:next(1, 3)

	-- Slight lean at the top: ±1 block offset based on hash
	local lean_x = (rng:next(0, 2) - 1)  -- -1, 0, or 1
	local lean_z = (rng:next(0, 2) - 1)

	-- Pre-compute strand offsets
	local strand_offsets = {}
	for i = 1, num_strands do
		strand_offsets[i] = {
			dx = rng:next(-1, 1),
			dz = rng:next(-1, 1),
		}
	end

	return {
		center_x = center_x,
		center_z = center_z,
		outer_radius = outer_radius,
		inner_radius = inner_radius,
		height = height,
		hair_height = hair_height,
		lean_x = lean_x,
		lean_z = lean_z,
		strand_offsets = strand_offsets,
	}
end

-- =============================================================================
-- Biome Registration
-- =============================================================================

lazarus_space.register_surface_biome({
	name = "follicle_forest",
	noise_min = 0.35,
	noise_max = 0.5,
	base_height_offset = 5,
	height_amplitude = 2.0,
	detail_amplitude = 0.5,

	get_content_ids = function(c)
		c_fat_tissue              = c.fat_tissue
		c_congealed_rotten_plasma = c.congealed_rotten_plasma
		c_keratin                 = c.keratin
		c_flesh                   = c.flesh
		c_mucus                   = c.mucus
		c_bio_grass_3             = c.bio_grass_3
		c_air                     = c.air
	end,

	generate_column = function(ctx)
		local x              = ctx.x
		local z              = ctx.z
		local terrain_height = ctx.terrain_height
		local data           = ctx.data
		local area           = ctx.area
		local y_min          = ctx.y_min
		local y_max          = ctx.y_max

		-- Ensure we start no lower than SURFACE_BASE
		local fill_min = math.max(y_min, SURFACE_BASE)
		local fill_max = math.min(y_max, terrain_height)

		-- ==================================================================
		-- Gather nearby follicles (current cell + 8 surrounding)
		-- ==================================================================

		local cell_x = math.floor(x / CELL_SIZE)
		local cell_z = math.floor(z / CELL_SIZE)

		local nearby_follicles = {}
		for dx = -1, 1 do
			for dz = -1, 1 do
				local f = get_follicle_params(cell_x + dx, cell_z + dz)
				if f then
					nearby_follicles[#nearby_follicles + 1] = f
				end
			end
		end

		-- ==================================================================
		-- Ground Fill
		-- ==================================================================

		for y = fill_min, fill_max do
			local vi = area:index(x, y, z)
			if y >= terrain_height - 1 then
				-- Top 2 blocks: sebum (oily ground surface)
				data[vi] = c_congealed_rotten_plasma
			else
				data[vi] = c_flesh
			end
		end

		-- ==================================================================
		-- Ground Cover (between follicles)
		-- ==================================================================
		if terrain_height >= y_min and terrain_height < y_max then
			local plant_y = terrain_height + 1
			if plant_y <= y_max then
				local ph2d = ((x * 374761393 + z * 668265263 + 7) % 2147483647 * 1103515245 + 12345) % 2147483647
				if ph2d % 20 == 0 then
					-- Occasional mucus patches
					local vi = area:index(x, terrain_height, z)
					data[vi] = c_mucus
				elseif ph2d % 300 == 1 then
					-- Very rare bio_sprout for tiny pinpricks of light
					local vi_plant = area:index(x, plant_y, z)
					data[vi_plant] = c_bio_grass_3
				end
			end
		end

		-- ==================================================================
		-- Follicle Structures
		-- ==================================================================

		for _, fol in ipairs(nearby_follicles) do
			local cx = fol.center_x
			local cz = fol.center_z
			local outer_r = fol.outer_radius
			local inner_r = fol.inner_radius
			local fol_height = fol.height
			local hair_h = fol.hair_height

			-- Skip if this column is too far from the follicle center
			local base_dx = x - cx
			local base_dz = z - cz
			local base_dist = math.sqrt(base_dx * base_dx + base_dz * base_dz)

			-- Max possible distance including lean + flare
			if base_dist > outer_r + 3 then
				goto continue_follicle
			end

			-- Follicle trunk: from ground-5 to ground+height (embed 5 blocks deep)
			local fol_y_min = math.max(y_min, terrain_height - 5)
			local fol_y_max = math.min(y_max, terrain_height + fol_height)

			for y = fol_y_min, fol_y_max do
				local h = y - terrain_height  -- height above ground (negative = below)
				local frac = math.max(0, h / fol_height)  -- 0 at ground, 1 at top

				-- Apply lean: offset center axis at the top
				local lean_cx = cx + fol.lean_x * frac
				local lean_cz = cz + fol.lean_z * frac

				local dx = x - lean_cx
				local dz = z - lean_cz
				local dist = math.sqrt(dx * dx + dz * dz)

				-- Ground-level flare: widen by 1 block for bottom 2 blocks above ground
				local eff_outer_r = outer_r
				if h >= 0 and h <= 1 then
					eff_outer_r = outer_r + 1
				end

				if h < 0 then
					-- Below ground: fill solid within outer radius (embedded root)
					if dist <= outer_r then
						local vi = area:index(x, y, z)
						data[vi] = c_fat_tissue
					end
				elseif dist <= eff_outer_r and dist > inner_r then
					-- Wall: follicle_sheath with decay only in top 1/3
					local place = true
					if frac > 0.667 then
						local decay_hash = pos_hash(x, y, z)
						if decay_hash % 100 >= 85 then
							place = false
						end
					end
					if place then
						local vi = area:index(x, y, z)
						data[vi] = c_fat_tissue
					end
				elseif dist <= inner_r then
					-- Interior: air (hollow core)
					local vi = area:index(x, y, z)
					data[vi] = c_air
				end
			end

			-- Hair extensions above the follicle
			local hair_y_min = math.max(y_min, terrain_height + fol_height + 1)
			local hair_y_max = math.min(y_max, terrain_height + fol_height + hair_h)

			if hair_y_min <= hair_y_max then
				for _, strand in ipairs(fol.strand_offsets) do
					local strand_x = cx + strand.dx
					local strand_z = cz + strand.dz

					if x == strand_x and z == strand_z then
						for y = hair_y_min, hair_y_max do
							local vi = area:index(x, y, z)
							data[vi] = c_keratin
						end
					end
				end
			end

			::continue_follicle::
		end
	end,
})
