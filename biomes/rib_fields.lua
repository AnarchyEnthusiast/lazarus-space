-- Rib Fields Surface Biome
-- Vast plains of fleshy ground punctuated by towering parabolic rib arches.
-- Ribs emerge from cartilage-encrusted bases and arc high overhead,
-- connected at intervals by taut sinew strands.

local SURFACE_BASE = 27775

-- =============================================================================
-- Utility
-- =============================================================================

local pos_hash = lazarus_space.pos_hash

-- =============================================================================
-- Content ID Cache (biome-local)
-- =============================================================================

local c_cartilage
local c_flesh
local c_bone
local c_sinew
local c_bio_grass_3, c_bio_tendril, c_bio_polyp_plant

-- =============================================================================
-- Rib Cell Parameters
-- =============================================================================

local RIB_CELL_WIDTH = 50
local RIB_SEED = 29371
local RIB_THICKNESS = 1.5     -- half-thickness of rib wall in blocks (reduced 25%)
local BASE_HEIGHT = 4         -- height of joint cluster at rib base (reduced 25%)
local BASE_SPREAD = 2         -- lateral spread of base joint cluster (reduced 25%)

-- =============================================================================
-- Rib Cell Helper
-- =============================================================================

-- Given a cell index along the x-axis, return deterministic rib parameters.
local function get_rib_params(cell_x)
	local hash = ((cell_x * 374761393 + RIB_SEED * 668265263) % 2147483647 * 1103515245 + 12345) % 2147483647
	local rng = PcgRandom(hash)

	local rib_center_x = cell_x * RIB_CELL_WIDTH + rng:next(0, RIB_CELL_WIDTH - 1)
	local rib_peak_height = rng:next(4, 7)     -- ~80% shorter (was 20-37)
	local rib_half_span = rng:next(3, 5)       -- ~80% shorter span (was 15-25)

	return {
		center_x = rib_center_x,
		peak_height = rib_peak_height,
		half_span = rib_half_span,
	}
end

-- =============================================================================
-- Biome Registration
-- =============================================================================

lazarus_space.register_surface_biome({
	name = "rib_fields",
	noise_min = -1.0,
	noise_max = -0.6,
	base_height_offset = 5,
	height_amplitude = 2.5,
	detail_amplitude = 0.75,

	get_content_ids = function(c)
		c_cartilage       = c.cartilage
		c_flesh           = c.flesh
		c_bone            = c.bone
		c_sinew           = c.sinew
		c_bio_grass_3     = c.bio_grass_3
		c_bio_tendril     = c.bio_tendril
		c_bio_polyp_plant = c.bio_polyp_plant
	end,

	generate_column = function(ctx)
		local x             = ctx.x
		local z             = ctx.z
		local terrain_height = ctx.terrain_height
		local detail_noise  = ctx.detail_noise
		local data          = ctx.data
		local area          = ctx.area
		local y_min         = ctx.y_min
		local y_max         = ctx.y_max

		-- Ensure we start no lower than SURFACE_BASE
		local fill_min = math.max(y_min, SURFACE_BASE)
		local fill_max = math.min(y_max, terrain_height)

		-- ==================================================================
		-- Ground Fill
		-- ==================================================================

		for y = fill_min, fill_max do
			local vi = area:index(x, y, z)
			if y >= terrain_height - 1 then
				-- Top 1-2 blocks: alternate flesh / cartilage by detail noise
				if detail_noise > 0 then
					data[vi] = c_cartilage
				else
					data[vi] = c_flesh
				end
				-- Occasional gristle patches on the very surface
				if y == terrain_height then
					local ph = pos_hash(x, y, z)
					if ph % 6 == 0 then
						data[vi] = c_cartilage
					end
				end
			else
				data[vi] = c_flesh
			end
		end

		-- ==================================================================
		-- Surface Plants
		-- ==================================================================
		if terrain_height >= y_min and terrain_height < y_max then
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
		-- Rib Structures (cell-based along x-axis)
		-- ==================================================================

		local cell_x = math.floor(x / RIB_CELL_WIDTH)

		-- Gather nearby rib cells (current, left, right)
		local nearby_ribs = {}
		for dx = -1, 1 do
			nearby_ribs[#nearby_ribs + 1] = get_rib_params(cell_x + dx)
		end

		-- Ground height at this column serves as rib base
		local ground_y = terrain_height

		for _, rib in ipairs(nearby_ribs) do
			local dist_to_center = x - rib.center_x
			local peak = rib.peak_height
			local half_span = rib.half_span

			-- Each rib is a parabolic/cosine arch rising from ground level.
			-- At height h above ground, the arch has two arms at
			-- x offsets: center +/- offset, where
			-- offset = half_span * cos(h / peak * pi/2)
			-- The rib wall is ~4 blocks thick (2 on each side).

			local rib_y_min = math.max(y_min, ground_y + 1)
			local rib_y_max = math.min(y_max, ground_y + peak)

			for y = rib_y_min, rib_y_max do
				local h = y - ground_y
				local frac = h / peak
				local offset = half_span * math.cos(frac * math.pi / 2)

				-- Check left arm (center - offset) and right arm (center + offset)
				local left_arm_x = rib.center_x - offset
				local right_arm_x = rib.center_x + offset
				local dist_left = math.abs(x + 0.0 - left_arm_x)
				local dist_right = math.abs(x + 0.0 - right_arm_x)

				-- Soft edge: dithered boundary within 0.5 blocks of threshold
				local in_left = dist_left < RIB_THICKNESS
				local in_right = dist_right < RIB_THICKNESS
				if not in_left and dist_left < RIB_THICKNESS + 0.5 then
					in_left = pos_hash(x, y, z) % 2 == 0
				end
				if not in_right and dist_right < RIB_THICKNESS + 0.5 then
					in_right = pos_hash(x, y, z) % 2 == 0
				end
				local in_rib = in_left or in_right

				if in_rib then
					local vi = area:index(x, y, z)

					-- Base joint cluster: lowest BASE_HEIGHT blocks
					if h <= BASE_HEIGHT then
						-- Spread wider at the base
						local base_dist = math.min(dist_left, dist_right)
						if base_dist < BASE_SPREAD then
							local ph = pos_hash(x, y, z)
							if ph % 3 == 0 then
								data[vi] = c_bone
							else
								data[vi] = c_cartilage
							end
						else
							data[vi] = c_bone
						end
					else
						data[vi] = c_bone
					end
				end

				-- Base joint cluster extends wider than the rib itself
				if h <= BASE_HEIGHT and not in_rib then
					local dist_left_base = math.abs(x - left_arm_x)
					local dist_right_base = math.abs(x - right_arm_x)
					local base_dist = math.min(dist_left_base, dist_right_base)

					if base_dist < BASE_SPREAD then
						local vi = area:index(x, y, z)
						local ph = pos_hash(x, y, z)
						if ph % 3 == 0 then
							data[vi] = c_bone
						elseif ph % 3 == 1 then
							data[vi] = c_cartilage
						else
							data[vi] = c_flesh
						end
					end
				end
			end
		end

		-- ==================================================================
		-- Sinew Connections Between Adjacent Ribs
		-- ==================================================================
		-- Place sinew at ~30%, 50%, 70% of rib height where this column's
		-- x position falls between two adjacent rib centers.

		-- Find the two closest rib centers bracketing this x position
		local left_rib = nil
		local right_rib = nil

		for _, rib in ipairs(nearby_ribs) do
			if rib.center_x <= x then
				if not left_rib or rib.center_x > left_rib.center_x then
					left_rib = rib
				end
			end
			if rib.center_x > x then
				if not right_rib or rib.center_x < right_rib.center_x then
					right_rib = rib
				end
			end
		end

		if left_rib and right_rib then
			-- Use the shorter rib's peak for sinew height references
			local ref_peak = math.min(left_rib.peak_height, right_rib.peak_height)
			local sinew_fracs = {0.3, 0.5, 0.7}

			for _, frac in ipairs(sinew_fracs) do
				local sinew_y = ground_y + math.floor(ref_peak * frac)

				if sinew_y >= y_min and sinew_y <= y_max then
					-- Check that this x is between the two rib centers
					-- (already guaranteed by left/right selection)
					-- Also verify both ribs actually extend to this height
					local left_h = sinew_y - ground_y
					local right_h = sinew_y - ground_y

					if left_h < left_rib.peak_height and right_h < right_rib.peak_height then
						-- Compute where the rib walls are at this height
						local left_frac = left_h / left_rib.peak_height
						local left_offset = left_rib.half_span * math.cos(left_frac * math.pi / 2)
						local left_inner_x = left_rib.center_x + left_offset

						local right_frac = right_h / right_rib.peak_height
						local right_offset = right_rib.half_span * math.cos(right_frac * math.pi / 2)
						local right_inner_x = right_rib.center_x - right_offset

						-- Place sinew if x is between the inner edges of both ribs
						if x >= math.floor(left_inner_x) and x <= math.ceil(right_inner_x) then
							local vi = area:index(x, sinew_y, z)
							data[vi] = c_sinew
						end
					end
				end
			end
		end
	end,
})
