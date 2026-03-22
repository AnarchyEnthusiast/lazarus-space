-- Molar Peaks: Giant tooth structures rising from gum tissue ground.
-- Surface biome for the biological dimension.

local SURFACE_BASE = 27775

-- =============================================================================
-- Deterministic Position Hash
-- =============================================================================

local pos_hash = lazarus_space.pos_hash

-- =============================================================================
-- Tooth Parameter Generation
-- =============================================================================

local MAJOR_CELL = 100
local MINOR_CELL = 50
local TOOTH_SEED = 57392
local MINOR_SEED = 91847

local function get_major_tooth(cell_x, cell_z)
	local hash = pos_hash(cell_x + TOOTH_SEED, 0, cell_z + TOOTH_SEED)
	local rng = PcgRandom(hash)

	-- 70% chance a tooth exists
	if rng:next(1, 10) > 7 then
		return nil
	end

	local cx = cell_x * MAJOR_CELL + rng:next(10, 90)
	local cz = cell_z * MAJOR_CELL + rng:next(10, 90)
	local height = rng:next(50, 100)
	local base_radius = rng:next(8, 18)

	return {
		cx = cx,
		cz = cz,
		height = height,
		base_radius = base_radius,
	}
end

local function get_minor_tooth(cell_x, cell_z, major_teeth)
	local hash = pos_hash(cell_x + MINOR_SEED, 0, cell_z + MINOR_SEED)
	local rng = PcgRandom(hash)

	-- 70% chance a minor tooth exists
	if rng:next(1, 10) > 7 then
		return nil
	end

	local cx = cell_x * MINOR_CELL + rng:next(5, 45)
	local cz = cell_z * MINOR_CELL + rng:next(5, 45)

	-- Scale is 20-60% of major tooth dimensions
	local scale = (rng:next(20, 60)) / 100
	local height = math.floor(rng:next(50, 100) * scale)
	local base_radius = math.floor(rng:next(8, 18) * scale)

	if base_radius < 3 then
		return nil
	end

	-- Check overlap with all nearby major teeth
	for _, mt in ipairs(major_teeth) do
		local dx = cx - mt.cx
		local dz = cz - mt.cz
		local dist = math.sqrt(dx * dx + dz * dz)
		if dist < mt.base_radius + 10 then
			return nil
		end
	end

	return {
		cx = cx,
		cz = cz,
		height = height,
		base_radius = base_radius,
	}
end

-- =============================================================================
-- Tooth Profile: radius at a given height fraction
-- =============================================================================

local function tooth_radius_at_frac(base_radius, frac)
	if frac < 0 or frac > 1 then
		return 0
	end

	if frac <= 0.30 then
		-- Root: tapers inward
		return base_radius * (1.0 - frac * 0.5)
	elseif frac <= 0.50 then
		-- Neck: narrowest
		return base_radius * 0.65
	elseif frac <= 0.90 then
		-- Crown: widens
		return base_radius * (0.65 + (frac - 0.5) * 0.5)
	else
		-- Grinding surface: flat top at crown radius at 0.9
		return base_radius * (0.65 + (0.9 - 0.5) * 0.5)
	end
end

-- =============================================================================
-- Content ID Cache
-- =============================================================================

local c_congealed_plasma, c_flesh, c_cartilage
local c_bone, c_enamel, c_dentin, c_air
local c_bio_grass_3, c_bio_tendril, c_bio_polyp_plant

-- =============================================================================
-- Biome Registration
-- =============================================================================

lazarus_space.register_surface_biome({
	name = "molar_peaks",
	noise_min = -0.6,
	noise_max = -0.25,
	base_height_offset = 5,
	height_amplitude = 3.5,
	detail_amplitude = 1,

	get_content_ids = function(c)
		c_congealed_plasma = c.congealed_plasma
		c_flesh            = c.flesh
		c_cartilage        = c.cartilage
		c_bone             = c.bone
		c_enamel           = c.enamel
		c_dentin           = c.bone_block
		c_air              = c.air
		c_bio_grass_3      = c.bio_grass_3
		c_bio_tendril      = c.bio_tendril
		c_bio_polyp_plant  = c.bio_polyp_plant
	end,

	generate_column = function(ctx)
		local x             = ctx.x
		local z             = ctx.z
		local terrain_height = ctx.terrain_height
		local data           = ctx.data
		local area           = ctx.area
		local c              = ctx.c
		local y_min          = ctx.y_min
		local y_max          = ctx.y_max
		local cave_detail_noise = ctx.cave_detail_noise

		-- Ensure y_min is at least SURFACE_BASE
		if y_min < SURFACE_BASE then
			y_min = SURFACE_BASE
		end

		-- =============================================================
		-- Gather nearby teeth (major + minor) from current + 8 neighbors
		-- =============================================================

		local major_cell_x = math.floor(x / MAJOR_CELL)
		local major_cell_z = math.floor(z / MAJOR_CELL)

		local major_teeth = {}
		for dx = -1, 1 do
			for dz = -1, 1 do
				local tooth = get_major_tooth(major_cell_x + dx, major_cell_z + dz)
				if tooth then
					major_teeth[#major_teeth + 1] = tooth
				end
			end
		end

		local minor_cell_x = math.floor(x / MINOR_CELL)
		local minor_cell_z = math.floor(z / MINOR_CELL)

		local minor_teeth = {}
		for dx = -1, 1 do
			for dz = -1, 1 do
				local tooth = get_minor_tooth(minor_cell_x + dx, minor_cell_z + dz, major_teeth)
				if tooth then
					minor_teeth[#minor_teeth + 1] = tooth
				end
			end
		end

		-- Combine all teeth
		local all_teeth = {}
		for _, t in ipairs(major_teeth) do
			all_teeth[#all_teeth + 1] = t
		end
		for _, t in ipairs(minor_teeth) do
			all_teeth[#all_teeth + 1] = t
		end

		-- =============================================================
		-- Surface Plants (on ground, not inside teeth)
		-- =============================================================
		if terrain_height >= y_min and terrain_height < y_max then
			local plant_y = terrain_height + 1
			if plant_y <= y_max then
				-- Only place plant if not inside any tooth at surface
				local in_tooth = false
				for _, tooth in ipairs(all_teeth) do
					local tdx = x + 0.0 - tooth.cx
					local tdz = z + 0.0 - tooth.cz
					local tdist = math.sqrt(tdx * tdx + tdz * tdz)
					if tdist <= tooth.base_radius then
						in_tooth = true
						break
					end
				end
				if not in_tooth then
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
		end

		-- =============================================================
		-- Iterate y from y_min to y_max
		-- =============================================================

		for y = y_min, y_max do
			local vi = area:index(x, y, z)

			-- Ground fill: below or at terrain_height -> gum_tissue
			if y <= terrain_height then
				data[vi] = c_flesh
			else
				-- Check if inside any tooth
				local placed = false

				for _, tooth in ipairs(all_teeth) do
					local tooth_base = terrain_height
					local tooth_top = tooth_base + tooth.height

					if y > tooth_base and y <= tooth_top then
						local frac = (y - tooth_base) / tooth.height
						local radius = tooth_radius_at_frac(tooth.base_radius, frac)

						local tdx = x + 0.0 - tooth.cx
						local tdz = z + 0.0 - tooth.cz
						local dist = math.sqrt(tdx * tdx + tdz * tdz)

						-- Soft edge: dithered boundary within 0.5 blocks
					local in_tooth_boundary = dist <= radius
					if not in_tooth_boundary and dist <= radius + 0.5 then
						in_tooth_boundary = pos_hash(x, y, z) % 2 == 0
					end
					if in_tooth_boundary then
							-- Inside this tooth: determine material
							local dist_frac = dist / radius

							if dist_frac > 0.85 and frac > 0.85 then
								-- Outer 15% at top: enamel
								data[vi] = c_enamel
							elseif dist_frac > 0.70 then
								-- Outer 30%: dentin
								data[vi] = c_dentin
							else
								-- Inner core
								if frac > 0.50 then
									-- Upper core: pulp
									data[vi] = c_congealed_plasma
								else
									-- Lower core: nerve channels with tunnels
									local cd_val = cave_detail_noise[y]
									if cd_val and cd_val < -0.2 then
										data[vi] = c_air
									else
										data[vi] = c_cartilage
									end
								end
							end

							placed = true
							break
						end
					end
				end

				-- Above ground and not inside any tooth: air
				if not placed then
					data[vi] = c_air
				end
			end
		end
	end,
})
