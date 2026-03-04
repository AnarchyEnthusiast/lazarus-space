-- Lazarus Space: Formspec GUI for the Continuum Disrupter
--
-- Polished dark-themed UI showing device state, progress bar,
-- power info, field status, and player inventory. The disrupter
-- only knows about the stasis field — no portal awareness.

function lazarus_space.build_formspec(pos)
	local meta = minetest.get_meta(pos)
	local state = meta:get_string("state")
	if state == "" then state = "idle" end
	local eu_input = meta:get_int("HV_EU_input")
	local eu_demand = meta:get_int("HV_EU_demand")
	local charge = meta:get_int("charge")
	local hash = minetest.hash_node_position(pos)
	local field = lazarus_space.active_fields[hash]

	-- Determine display values.
	local display_state, status_color, progress
	local radius = 0
	local field_active = false
	local show_power = false
	local powered = true

	if state == "charging" then
		progress = math.min(100,
			math.floor(charge
				/ (lazarus_space.CHARGE_REQUIRED / 100)))
		if eu_demand > 0 and eu_input < eu_demand then
			display_state = "Offline -- No Power"
			status_color = "#ff4444"
			powered = false
		else
			display_state = "Charging Field"
			status_color = "#ffcc00"
		end
		show_power = true
		radius = meta:get_int("anticipated_radius")
	elseif state == "active" or state == "warp_charging"
			or state == "portal_growing"
			or state == "portal_waiting"
			or state == "portal_ready" then
		display_state = "Stasis Field Active"
		status_color = "#00ff88"
		progress = 100
		field_active = true
		if field then radius = field.radius end
	else
		display_state = "Idle"
		status_color = "#aaaaaa"
		progress = 0
		show_power = true
	end

	-- Build formspec string.
	local fs = "formspec_version[4]"
		.. "size[8,9.25]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"
		.. "listcolors[#00000069;#5A5A5A;"
			.. "#141318;#30434C;#FFF]"

	-- Title.
	fs = fs
		.. "style_type[label;font_size=*1.3]"
		.. "label[2.2,0.45;Continuum Disrupter]"
		.. "style_type[label;font_size=*1]"

	-- Status line with tinted background.
	fs = fs
		.. "box[0.3,0.65;7.4,0.45;"
			.. status_color .. "18]"
		.. "label[0.5,0.9;"
			.. minetest.colorize(status_color,
				display_state) .. "]"

	-- Divider.
	fs = fs .. "box[0.3,1.25;7.4,0.02;#333333]"

	-- Progress bar.
	local bar_x, bar_y = 0.5, 1.45
	local bar_w, bar_h = 7.0, 0.35
	fs = fs
		.. "image[" .. bar_x .. "," .. bar_y .. ";"
			.. bar_w .. "," .. bar_h
			.. ";lazarus_space_progress_bg.png]"
	if progress > 0 then
		local fill_w = bar_w * progress / 100
		fs = fs
			.. "image[" .. bar_x .. "," .. bar_y
				.. ";" .. string.format("%.2f", fill_w)
				.. "," .. bar_h
				.. ";lazarus_space_progress_fill.png]"
	end

	-- Percentage label.
	fs = fs
		.. "label[3.5,2.05;" .. progress .. "%]"

	-- Divider.
	fs = fs .. "box[0.3,2.25;7.4,0.02;#333333]"

	-- Power display.
	local info_y = 2.5
	if show_power then
		local power_color = powered and "#00ff88" or "#ff4444"
		local power_label = powered and "Powered" or "Unpowered"
		fs = fs
			.. "label[0.5," .. info_y
				.. ";Power: "
				.. lazarus_space.POWER_DEMAND .. " EU]"
			.. "label[5.0," .. info_y .. ";"
				.. minetest.colorize(power_color,
					power_label)
				.. "]"
		info_y = info_y + 0.4
	end

	-- Field info.
	if radius > 0 then
		fs = fs
			.. "label[0.5," .. info_y
				.. ";Radius: " .. radius .. " blocks]"
		if field_active then
			fs = fs
				.. "label[5.0," .. info_y .. ";"
					.. minetest.colorize("#00ff88",
						"Time Frozen")
					.. "]"
		end
		info_y = info_y + 0.4
	end

	-- Toggle button.
	local toggle_label, toggle_name
	if state == "idle" then
		toggle_label = "Activate"
		toggle_name = "activate"
	else
		toggle_label = "Deactivate"
		toggle_name = "deactivate"
	end
	fs = fs
		.. "button[3,3.5;2,0.65;" .. toggle_name
			.. ";" .. toggle_label .. "]"

	-- Warning.
	fs = fs
		.. "label[0.5,4.35;"
			.. minetest.colorize("#ff4444",
				"WARNING: Field collapse destroys device.")
			.. "]"

	-- Divider.
	fs = fs .. "box[0.3,4.6;7.4,0.02;#333333]"

	-- Player inventory.
	fs = fs
		.. "list[current_player;main;0,4.8;8,1;]"
		.. "list[current_player;main;0,5.9;8,3;8]"
		.. "listring[]"

	meta:set_string("formspec", fs)
	return fs
end
