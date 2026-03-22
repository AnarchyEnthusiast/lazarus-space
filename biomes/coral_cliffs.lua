-- Coral Cliffs Surface Biome
-- Terraced coral shelves with tube formations and varied coral materials.

local SURFACE_BASE = 27775
local SHELF_STEP = 8

-- =============================================================================
-- Biome Registration
-- =============================================================================

lazarus_space.register_surface_biome({
	name = "coral_cliffs",
	noise_min = -0.05,
	noise_max = 0.15,
	base_height_offset = 10,
	height_amplitude = 72,
	detail_amplitude = 2,

	get_content_ids = function(c)
		c.brain_coral = minetest.get_content_id("lazarus_space:brain_coral")
	end,

	generate_column = function(ctx)
		local x            = ctx.x
		local z            = ctx.z
		local terrain_height = ctx.terrain_height
		local data         = ctx.data
		local area         = ctx.area
		local c            = ctx.c
		local y_min        = ctx.y_min
		local y_max        = ctx.y_max
		local cave_shape   = ctx.cave_shape_noise
		local cave_detail  = ctx.cave_detail_noise

		-- Quantize terrain height to shelf steps
		local quantized = math.floor((terrain_height - SURFACE_BASE) / SHELF_STEP) * SHELF_STEP + SURFACE_BASE

		-- Clamp iteration bounds
		local fill_min = math.max(y_min, SURFACE_BASE)
		local fill_max = math.min(y_max, quantized)

		for y = fill_min, fill_max do
			local vi = area:index(x, y, z)

			-- Tube formations: carve air where cave_shape noise is high
			if cave_shape[y] and cave_shape[y] > 0.60 then
				data[vi] = c.air
			else
				-- Determine which shelf step this y belongs to
				local rel = (y - SURFACE_BASE) % SHELF_STEP
				local is_shelf_surface = (rel >= SHELF_STEP - 2)

				-- Check if this is actually at the top of a completed shelf
				-- (only mark as shelf surface if the shelf above is NOT filled)
				local shelf_top = math.floor((y - SURFACE_BASE) / SHELF_STEP) * SHELF_STEP + SURFACE_BASE + SHELF_STEP
				if is_shelf_surface and shelf_top <= quantized then
					-- Not actually an exposed surface; this shelf continues above
					is_shelf_surface = false
				end

				if is_shelf_surface then
					-- Shelf surface: alternate polyp and lung_coral
					if rel == SHELF_STEP - 1 then
						data[vi] = c.nerve_block
					else
						data[vi] = c.brain_coral_block
					end
				else
					-- Interior fill based on cave detail noise
					local detail = cave_detail[y] or 0
					if detail < -0.2 then
						data[vi] = c.brain_coral
					elseif detail <= 0.2 then
						data[vi] = c.brain_coral_block
					else
						data[vi] = c.nerve_block
					end
				end
			end
		end

		-- Fill any remaining y above quantized up to y_max with air
		-- (the mapgen framework handles this, but ensure columns above
		-- the coral volume that were previously set by main loop are air)
		for y = math.max(fill_max + 1, fill_min), y_max do
			local vi = area:index(x, y, z)
			data[vi] = c.air
		end

		-- Surface plants on the topmost shelf
		-- Ground check: only place plants if the block below is solid (not carved by caves)
		if quantized >= y_min and quantized < y_max then
			local plant_y = quantized + 1
			if plant_y <= y_max then
				local vi_ground = area:index(x, quantized, z)
				if data[vi_ground] ~= c.air then
					local ph2d = ((x * 374761393 + z * 668265263 + 7) % 2147483647 * 1103515245 + 12345) % 2147483647
					local vi_plant = area:index(x, plant_y, z)
					if ph2d % 40 == 0 then
						data[vi_plant] = c.bio_polyp_plant
					elseif ph2d % 25 == 1 then
						data[vi_plant] = c.bio_tendril
					elseif ph2d % 12 == 2 then
						data[vi_plant] = c.bio_grass_3
					end
				end
			end
		end
	end,
})
