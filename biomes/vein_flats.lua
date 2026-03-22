-- Vein Flats: Surface biome for the biological dimension.
-- A flat, capillary-covered terrain with raised vessel ridges and
-- rupture points that expose the plasma below.

-- =============================================================================
-- Content ID Cache (biome-local)
-- =============================================================================

local c_congealed_blood
local c_vein_block
local c_flesh
local c_plasma_source
local c_bio_grass_3, c_bio_tendril, c_bio_polyp_plant

-- =============================================================================
-- Biome Registration
-- =============================================================================

local SURFACE_BASE = 27775

lazarus_space.register_surface_biome({
	name = "vein_flats",
	noise_min = -0.25,
	noise_max = -0.05,
	base_height_offset = 3,
	height_amplitude = 1,
	detail_amplitude = 0.5,

	get_content_ids = function(c)
		c_congealed_blood   = c.congealed_blood
		c_vein_block        = minetest.get_content_id("lazarus_space:vein_block")
		c_flesh             = c.flesh
		c_plasma_source     = c.plasma_source
		c_bio_grass_3       = c.bio_grass_3
		c_bio_tendril       = c.bio_tendril
		c_bio_polyp_plant   = c.bio_polyp_plant
	end,

	generate_column = function(ctx)
		local x             = ctx.x
		local z             = ctx.z
		local terrain_height = ctx.terrain_height
		local height_noise  = ctx.height_noise
		local detail_noise  = ctx.detail_noise
		local data          = ctx.data
		local area          = ctx.area
		local c             = ctx.c
		local y_min         = ctx.y_min
		local y_max         = ctx.y_max

		local floor = math.floor

		-- Effective bottom of this column
		local col_base = math.max(y_min, SURFACE_BASE)

		-- ----------------------------------------------------------------
		-- Rupture points: where height_noise is very low and terrain sits
		-- at the minimum height, skip ground entirely and place liquid.
		-- ----------------------------------------------------------------
		if height_noise < -0.4 and terrain_height <= SURFACE_BASE + 3 then
			-- Place plasma_source at the floor level, air above
			if SURFACE_BASE >= y_min and SURFACE_BASE <= y_max then
				local vi = area:index(x, SURFACE_BASE, z)
				data[vi] = c_plasma_source
			end
			-- Air above the liquid
			for y = math.max(y_min, SURFACE_BASE + 1), math.min(y_max, terrain_height + 3) do
				local vi = area:index(x, y, z)
				data[vi] = c.air
			end
			return
		end

		-- ----------------------------------------------------------------
		-- Ground fill: flesh from col_base to terrain_height,
		-- topmost block becomes capillary_surface.
		-- ----------------------------------------------------------------
		for y = col_base, math.min(y_max, terrain_height) do
			local vi = area:index(x, y, z)
			if y == terrain_height then
				data[vi] = c_congealed_blood
			else
				data[vi] = c_flesh
			end
		end

		-- ----------------------------------------------------------------
		-- Raised vessel ridges: where detail_noise > 0.4, stack
		-- vein_block above the terrain surface.
		-- ----------------------------------------------------------------
		if detail_noise > 0.4 then
			local ridge_height = 1 + floor((detail_noise - 0.4) * 5)
			if ridge_height > 2 then
				ridge_height = 2
			end

			local top_y = terrain_height + ridge_height
			for y = terrain_height + 1, math.min(y_max, top_y) do
				local vi = area:index(x, y, z)
				data[vi] = c_vein_block
			end

			-- ----------------------------------------------------------
			-- Vein highlights: where both height_noise > 0.3 and
			-- detail_noise > 0.3, replace the topmost vein_block with
			-- a glowing intersection node.
			-- ----------------------------------------------------------
			if height_noise > 0.3 and detail_noise > 0.3 then
				local intersection_y = math.min(y_max, top_y)
				if intersection_y > terrain_height then
					local vi = area:index(x, intersection_y, z)
					data[vi] = c_vein_block
				end
			end
		end

		-- Surface plants (only on flat areas without ridges)
		if detail_noise <= 0.4 and terrain_height >= y_min and terrain_height < y_max then
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
	end,
})
