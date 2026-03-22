-- Abscess Marsh: Surface biome for the biological dimension.
-- A festering lowland of infected tissue riddled with pus pools,
-- necrotic patches, and the scattered remains of white blood cells.
-- Completely dark -- no light-emitting blocks.

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

local c_rotten_flesh
local c_congealed_rotten_plasma
local c_rotten_bone
local c_flesh
local c_pus_source
local c_bio_grass_3, c_bio_tendril, c_bio_polyp_plant

-- =============================================================================
-- Biome Registration
-- =============================================================================

lazarus_space.register_surface_biome({
	name = "abscess_marsh",
	noise_min = 0.5,
	noise_max = 1.0,
	base_height_offset = 3,
	height_amplitude = 2,
	detail_amplitude = 0.5,

	get_content_ids = function(c)
		c_rotten_flesh            = c.rotten_flesh
		c_congealed_rotten_plasma = c.congealed_rotten_plasma
		c_rotten_bone             = c.rotten_bone
		c_flesh                   = c.flesh
		c_pus_source              = c.pus_source
		c_bio_grass_3             = c.bio_grass_3
		c_bio_tendril             = c.bio_tendril
		c_bio_polyp_plant         = c.bio_polyp_plant
	end,

	generate_column = function(ctx)
		local x              = ctx.x
		local z              = ctx.z
		local terrain_height = ctx.terrain_height
		local height_noise   = ctx.height_noise
		local detail_noise   = ctx.detail_noise
		local data           = ctx.data
		local area           = ctx.area
		local c              = ctx.c
		local y_min          = ctx.y_min
		local y_max          = ctx.y_max
		local cave_detail_noise = ctx.cave_detail_noise

		local max   = math.max
		local min   = math.min

		local col_base = max(y_min, SURFACE_BASE)
		local fill_max = min(y_max, terrain_height)

		-- ==================================================================
		-- Pus Pools: height_noise < -0.65 (5th percentile — absolute deepest depressions only)
		-- Single block deep at terrain surface, solid infected_tissue below.
		-- ==================================================================
		if height_noise < -0.65 then
			-- Fill solid ground below the surface
			for y = col_base, fill_max do
				local vi = area:index(x, y, z)
				data[vi] = c_rotten_flesh
			end
			-- Place single pus_source layer at terrain_height
			if terrain_height >= y_min and terrain_height <= y_max then
				local vi = area:index(x, terrain_height, z)
				data[vi] = c_pus_source
			end
			return
		end

		-- ==================================================================
		-- Pool Edges: height_noise between -0.65 and -0.55
		-- Columns near pus pools get bacterial_mat / wbc_debris surface
		-- ==================================================================
		local is_pool_edge = (height_noise >= -0.65 and height_noise < -0.55)

		-- ==================================================================
		-- Ground Fill
		-- ==================================================================
		for y = col_base, fill_max do
			local vi = area:index(x, y, z)

			if y == terrain_height then
				-- Surface block
				if is_pool_edge then
					-- Alternate bacterial_mat and wbc_debris by position
					local ph = pos_hash(x, y, z)
					if ph % 2 == 0 then
						data[vi] = c_rotten_flesh
					else
						data[vi] = c_rotten_bone
					end
				else
					-- Normal surface: necrotic_tissue where cave_detail_noise
					-- is below -0.2, otherwise infected_tissue
					local cdn = cave_detail_noise[y]
					if cdn and cdn < -0.2 then
						data[vi] = c_congealed_rotten_plasma
					else
						data[vi] = c_rotten_flesh
					end
				end
			elseif is_pool_edge and y >= terrain_height - 2 then
				-- Near-surface blocks at pool edge also get surface materials
				local ph = pos_hash(x, y, z)
				if ph % 2 == 0 then
					data[vi] = c_rotten_flesh
				else
					data[vi] = c_rotten_bone
				end
			else
				data[vi] = c_rotten_flesh
			end
		end

		-- ==================================================================
		-- Surface Plants (higher density -- darkest biome needs more glow)
		-- ==================================================================
		if not (height_noise < -0.65) and terrain_height >= y_min and terrain_height < y_max then
			local plant_y = terrain_height + 1
			if plant_y <= y_max then
				local ph2d = ((x * 374761393 + z * 668265263 + 7) % 2147483647 * 1103515245 + 12345) % 2147483647
				local vi_plant = area:index(x, plant_y, z)
				if ph2d % 25 == 0 then
					data[vi_plant] = c_bio_polyp_plant
				elseif ph2d % 15 == 1 then
					data[vi_plant] = c_bio_tendril
				elseif ph2d % 8 == 2 then
					data[vi_plant] = c_bio_grass_3
				end
			end
		end
	end,
})
