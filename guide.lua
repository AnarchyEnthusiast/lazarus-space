-- Lazarus Space: Magnetic Fusion Reactor Build Guide
-- 8-page craftable guide book with interactive 3D model viewers.

-- ============================================================
-- PER-PLAYER PAGE TRACKING
-- ============================================================

local guide_pages = {}

-- ============================================================
-- STYLED BUTTON HELPER (local copy)
-- ============================================================

local function styled_btn(fs, x, y, w, h, name, label, bg, bg_hover, bg_press, text)
	text = text or "#ffffff"
	bg_hover = bg_hover or bg
	bg_press = bg_press or bg
	fs = fs .. "style[" .. name .. ";bgcolor=" .. bg
		.. ";bgcolor_hovered=" .. bg_hover
		.. ";bgcolor_pressed=" .. bg_press
		.. ";textcolor=" .. text .. "]"
	fs = fs .. "button[" .. x .. "," .. y .. ";" .. w .. "," .. h
		.. ";" .. name .. ";" .. label .. "]"
	return fs
end

-- ============================================================
-- GRID RENDERING (for page 7 control block diagram only)
-- ============================================================

local GRID_COLORS = {
	P = "#e86400",     -- pole field (orange)
	T = "#00cccc",     -- toroid field (cyan)
	S = "#888888",     -- steelblock (grey)
	L = "#33cc33",     -- plasma field (green)
	C = "#33cc33",     -- plasma field corner (same green)
	["*"] = "#cc44ff", -- pole corrector (magenta/purple)
	a = "#222244",     -- enforced air (dark indigo, subtle)
	J = "#ccaa00",     -- jumpstarter (yellow)
	K = "#cc3399",     -- control panel (pink)
	O = "#cc6600",     -- power output (brown/copper)
}

local function draw_grid(fs, grid, start_x, start_y, cell_size, gap, color_table)
	cell_size = cell_size or 0.25
	gap = gap or 0.02
	color_table = color_table or GRID_COLORS
	local step = cell_size + gap
	for row_idx, row_str in ipairs(grid) do
		for col = 1, #row_str do
			local ch = row_str:sub(col, col)
			local color = color_table[ch]
			if color then
				local x = start_x + (col - 1) * step
				local y = start_y + (row_idx - 1) * step
				fs = fs .. "box[" .. x .. "," .. y .. ";"
					.. cell_size .. "," .. cell_size .. ";" .. color .. "]"
			end
		end
	end
	return fs
end

-- ============================================================
-- LEGEND RENDERING UTILITY
-- ============================================================

local function draw_legend(fs, entries, start_x, start_y)
	local x = start_x
	local y = start_y
	for _, e in ipairs(entries) do
		-- Wrap to next row if we'd overflow
		if x + e.width > start_x + 8.4 then
			x = start_x
			y = y + 0.4
		end
		fs = fs .. "box[" .. x .. "," .. y .. ";0.25,0.25;" .. e.color .. "]"
		fs = fs .. "label[" .. (x + 0.35) .. "," .. (y + 0.15) .. ";"
			.. minetest.formspec_escape(e.label) .. "]"
		x = x + e.width
	end
	return fs
end

-- ============================================================
-- PAGE HEADER HELPER
-- ============================================================

local function page_header(fs, title)
	fs = fs .. "box[0.3,0.3;8.4,0.6;#1a1a2e]"
	fs = fs .. "style_type[label;font_size=*1.2]"
	fs = fs .. "label[0.6,0.65;" .. minetest.formspec_escape(title) .. "]"
	fs = fs .. "style_type[label;font_size=*1]"
	return fs
end

-- ============================================================
-- 3D MODEL HELPER — texture atlas approach
-- ============================================================
-- All models use a single material. UV coords point to the correct
-- tile in an 80x16 pre-generated atlas PNG (no [combine at runtime).

local PAGE_MODELS = {
	[2] = "reactor_layer_floor.obj",
	[3] = "reactor_layer_walls.obj",
	[4] = "reactor_layer_middle.obj",
	[5] = "reactor_layer_roof.obj",
	[6] = "reactor_complete.obj",
}

-- Pre-generated 80x16 atlas PNG (avoids [combine commas breaking model[] parsing)
local MODEL_TEXTURE = "lazarus_space_reactor_atlas.png"

local function add_model(fs, page, x, y, w, h, rot_x, rot_y)
	local mesh = PAGE_MODELS[page]
	if not mesh then return fs end
	rot_x = rot_x or 20
	rot_y = rot_y or -30
	fs = fs .. "model[" .. x .. "," .. y .. ";" .. w .. "," .. h
		.. ";reactor_preview;" .. mesh .. ";" .. MODEL_TEXTURE
		.. ";" .. rot_x .. "," .. rot_y .. ";false;true]"
	return fs
end

-- ============================================================
-- PAGE 1: INTRODUCTION
-- ============================================================

local function build_page_intro(fs)
	fs = page_header(fs, "Magnetic Fusion Reactor \xe2\x80\x94 Build Guide")

	local y = 1.5
	local inc = 0.45

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	local c = minetest.colorize
	local teal = "#00ccaa"
	local white = "#ffffff"
	local grey = "#aaaaaa"

	line(c(white, "The Magnetic Fusion Reactor is a 13x13x5 multiblock"))
	line(c(white, "structure that generates ") .. c("#00ff66", "240,000 EU") .. c(white, " of power."))

	y = y + 0.2
	line(c(white, "Fueled by ") .. c(teal, "6") .. c(white, " uranium fuel rods \xe2\x80\x94 each load runs for ") .. c(teal, "8 hours") .. c(white, "."))
	line(c(white, "Requires ") .. c("#ffcc00", "85,000 EU") .. c(white, " from an HV network for jump start."))

	y = y + 0.2
	line(c(white, "Required blocks:"))
	line("  " .. c(teal, "120x") .. "  " .. c(white, "Pole Field"))
	line("  " .. c(teal, " 96x") .. "  " .. c(white, "Toroid Field"))
	line("  " .. c(teal, " 65x") .. "  " .. c(white, "Steel Block"))
	line("  " .. c(teal, " 28x") .. "  " .. c(white, "Plasma Field"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Pole Corrector"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Fusion Control Panel"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Plasma Jumpstarter"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Fusion Power Output"))

	y = y + 0.2
	line(c(grey, "Pages 2-5: Layer-by-layer build guide"))
	line(c(grey, "Page 6: Complete structure overview"))
	line(c(grey, "Page 7: Control block placement"))
	line(c(grey, "Page 8: Startup procedure"))

	return fs
end

-- ============================================================
-- BUILD-STEP PAGE HELPER (pages 2–6)
-- ============================================================
-- Each page shows a large 3D model with legend and notes below.

local function build_model_page(fs, title, page, legend, notes)
	fs = page_header(fs, title)

	-- Label above model
	fs = fs .. "label[0.5,1.05;" .. minetest.colorize("#aaaaaa", "3D View \xe2\x80\x94 click & drag to rotate") .. "]"

	-- Large 3D model filling most of the page
	fs = add_model(fs, page, 0.3, 1.2, 8.4, 5.8)

	-- Legend below model
	local legend_y = 7.2
	fs = draw_legend(fs, legend, 0.6, legend_y)

	-- Notes below legend
	local note_y = legend_y + 0.5
	if #legend > 4 then note_y = note_y + 0.4 end  -- extra row if legend wraps
	for i, note in ipairs(notes) do
		fs = fs .. "label[0.6," .. (note_y + (i - 1) * 0.4) .. ";"
			.. minetest.formspec_escape(note) .. "]"
	end

	return fs
end

-- ============================================================
-- PAGE 2: BASE PLATFORM (FLOOR)
-- ============================================================

local function build_page_floor(fs)
	return build_model_page(fs, "Step 1: Base Platform (Bottom Layer)", 2, {
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, {
		"13x13 square border of Pole Field with a Steel Block",
		"cross and corner bolts inside. Build this layer first.",
	})
end

-- ============================================================
-- PAGE 3: WALL LAYERS
-- ============================================================

local function build_page_walls(fs)
	return build_model_page(fs, "Step 2: Walls (Layers 2 & 4)", 3, {
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, {
		"Cross-shaped layout. Build two identical copies of this layer \xe2\x80\x94",
		"one directly above the base, one directly below the roof.",
	})
end

-- ============================================================
-- PAGE 4: MIDDLE LAYER (merged core + plasma ring)
-- ============================================================

local function build_page_middle(fs)
	return build_model_page(fs, "Step 3: Middle Layer (Core & Plasma Ring)", 4, {
		{color = "#33cc33", label = "Plasma Field", width = 2.0},
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#cc44ff", label = "Corrector", width = 1.6},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, {
		"Pole Corrector at the exact center, surrounded by 3x3 Pole Field ring.",
		"Green plasma ring loops around the outside. Steel Blocks fill corners.",
	})
end

-- ============================================================
-- PAGE 5: ROOF
-- ============================================================

local function build_page_roof(fs)
	return build_model_page(fs, "Step 4: Roof (Top Layer)", 5, {
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, {
		"Mirrors the base \xe2\x80\x94 Pole Field border with corner Steel Blocks.",
	})
end

-- ============================================================
-- PAGE 7: CONTROL BLOCKS (horizontal layout with side view)
-- ============================================================


local GRID_CONTROL = {
	"...",
	"...",
	"JKO",
	"...",
	"...",
}

local function build_page_controls(fs)
	fs = page_header(fs, "Step 5: Control Panel, Jumpstarter & Power Output")

	-- Horizontal row of 3 colored blocks
	local box_w = 2.2
	local box_h = 0.7
	local box_gap = 0.15
	local total_w = 3 * box_w + 2 * box_gap
	local box_x = (9 - total_w) / 2
	local box_y = 1.5

	-- Jumpstarter (left)
	fs = fs .. "box[" .. box_x .. "," .. box_y .. ";" .. box_w .. "," .. box_h .. ";#ccaa00]"
	fs = fs .. "label[" .. (box_x + 0.35) .. "," .. (box_y + 0.38) .. ";Jumpstarter]"

	-- Control Panel (center)
	local cp_x = box_x + box_w + box_gap
	fs = fs .. "box[" .. cp_x .. "," .. box_y .. ";" .. box_w .. "," .. box_h .. ";#cc3399]"
	fs = fs .. "label[" .. (cp_x + 0.25) .. "," .. (box_y + 0.38) .. ";Control Panel]"

	-- Power Output (right)
	local po_x = cp_x + box_w + box_gap
	fs = fs .. "box[" .. po_x .. "," .. box_y .. ";" .. box_w .. "," .. box_h .. ";#cc6600]"
	fs = fs .. "label[" .. (po_x + 0.25) .. "," .. (box_y + 0.38) .. ";Power Output]"

	-- 5x5 side-view placement grid below
	local ctx_cell = 0.5
	local ctx_gap = 0.03
	local ctx_step = ctx_cell + ctx_gap
	local ctx_w = 3 * ctx_step  -- only 3 columns wide (JKO row)
	local ctx_x = (9 - 5 * ctx_step) / 2
	local ctx_y = box_y + box_h + 0.6
	fs = draw_grid(fs, GRID_CONTROL, ctx_x, ctx_y, ctx_cell, ctx_gap)

	-- Label for context grid
	fs = fs .. "label[" .. ctx_x .. "," .. (ctx_y - 0.25) .. ";"
		.. minetest.colorize("#aaaaaa", "Side view \xe2\x80\x94 placement example") .. "]"

	-- Legend
	local legend_y = ctx_y + 5 * ctx_step + 0.35
	fs = draw_legend(fs, {
		{color = "#cc3399", label = "Control Panel", width = 2.2},
		{color = "#ccaa00", label = "Jumpstarter", width = 2.0},
		{color = "#cc6600", label = "Power Output", width = 2.0},
	}, 0.6, legend_y)

	-- Notes
	local note_y = legend_y + 0.9
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("The Control Panel must touch a Toroid Field block.") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.4) .. ";"
		.. minetest.formspec_escape("The Jumpstarter and Power Output must each touch") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.8) .. ";"
		.. minetest.formspec_escape("the Control Panel. Can be placed on any side.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 8: STARTUP PROCEDURE
-- ============================================================

local function build_page_startup(fs)
	fs = page_header(fs, "Step 6: Startup Procedure")

	local y = 1.5
	local inc = 0.45
	local c = minetest.colorize

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	line(c("#ffffff", "1. Connect the Jumpstarter to an HV network"))
	line(c("#aaaaaa", "   (needs ") .. c("#ffcc00", "85,000 EU") .. c("#aaaaaa", " stored)"))

	y = y + 0.15
	line(c("#ffffff", "2. Right-click the Control Panel"))
	line(c("#aaaaaa", "   \xe2\x86\x92 Click ") .. c("#00ccaa", "[Check Structure]") .. c("#aaaaaa", " to validate"))

	y = y + 0.15
	line(c("#ffffff", "3. Load 6 uranium fuel rods into the fuel slots"))

	y = y + 0.15
	line(c("#ffffff", "4. Click ") .. c("#00ccaa", "[Jump Start]"))
	line(c("#aaaaaa", "   (5-second charge sequence)"))

	y = y + 0.15
	line(c("#ffffff", "5. Click ") .. c("#00ccaa", "[Inject Fuel & Start]"))
	line(c("#aaaaaa", "   Reactor activates \xe2\x80\x94 ") .. c("#00ff66", "240,000 EU") .. c("#aaaaaa", " output"))

	y = y + 0.15
	line(c("#ffffff", "6. Right-click the Power Output block"))
	line(c("#aaaaaa", "   Set output tier: LV / MV / HV"))

	-- Divider
	y = y + 0.3
	fs = fs .. "box[0.6," .. y .. ";7.8,0.02;#333333]"
	y = y + 0.3

	line(c("#aaaaaa", "Deactivating the reactor preserves remaining fuel."))
	line(c("#aaaaaa", "Click ") .. c("#00ccaa", "[Resume Reactor]") .. c("#aaaaaa", " to restart without recharging."))

	return fs
end

-- ============================================================
-- PAGE 6: COMPLETE STRUCTURE — INTERACTIVE 3D MODEL
-- ============================================================

local function build_page_complete(fs)
	fs = page_header(fs, "Complete Reactor \xe2\x80\x94 3D View")

	-- Large interactive 3D model of the full reactor
	fs = add_model(fs, 6, 0.3, 1.2, 8.4, 6.8, 25, -45)

	-- Rotate hint
	fs = fs .. "label[2.8,8.15;" .. minetest.colorize("#aaaaaa", "Click and drag to rotate the model") .. "]"

	-- Condensed legend
	local legend_y = 8.5
	fs = draw_legend(fs, {
		{color = "#e86400", label = "Pole", width = 1.1},
		{color = "#00cccc", label = "Toroid", width = 1.3},
		{color = "#33cc33", label = "Plasma", width = 1.3},
		{color = "#cc44ff", label = "Corrector", width = 1.6},
		{color = "#888888", label = "Steel", width = 1.2},
	}, 0.6, legend_y)

	return fs
end

-- ============================================================
-- FORMSPEC SHELL AND NAVIGATION
-- ============================================================

local PAGE_COUNT = 8

local function build_guide_page(page)
	local fs = "formspec_version[4]"
		.. "size[9,10]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Dispatch to page builder
	if page == 1 then     fs = build_page_intro(fs)
	elseif page == 2 then fs = build_page_floor(fs)
	elseif page == 3 then fs = build_page_walls(fs)
	elseif page == 4 then fs = build_page_middle(fs)
	elseif page == 5 then fs = build_page_roof(fs)
	elseif page == 6 then fs = build_page_complete(fs)
	elseif page == 7 then fs = build_page_controls(fs)
	elseif page == 8 then fs = build_page_startup(fs)
	end

	-- Page number (centered)
	fs = fs .. "label[3.8,9.55;Page " .. page .. " / " .. PAGE_COUNT .. "]"

	-- Prev button (hidden on page 1)
	if page > 1 then
		fs = styled_btn(fs, 0.5, 9.15, 1.5, 0.65, "prev", "< Prev",
			"#00ccaa", "#00ddbb", "#009988")
	end

	-- Next button (hidden on last page)
	if page < PAGE_COUNT then
		fs = styled_btn(fs, 7.0, 9.15, 1.5, 0.65, "next", "Next >",
			"#00ccaa", "#00ddbb", "#009988")
	end

	return fs
end

-- ============================================================
-- CRAFTITEM REGISTRATION
-- ============================================================

minetest.register_craftitem("lazarus_space:reactor_guide", {
	description = "Magnetic Fusion Reactor Guide",
	inventory_image = "lazarus_space_reactor_guide.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()
		if not guide_pages[name] then
			guide_pages[name] = 1
		end
		minetest.show_formspec(name, "lazarus_space:reactor_guide",
			build_guide_page(guide_pages[name]))
		return itemstack
	end,
})

-- ============================================================
-- NAVIGATION HANDLER
-- ============================================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "lazarus_space:reactor_guide" then return end
	local name = player:get_player_name()
	local page = guide_pages[name] or 1

	if fields.prev and page > 1 then
		page = page - 1
	elseif fields.next and page < PAGE_COUNT then
		page = page + 1
	elseif fields.quit then
		return  -- formspec closed, keep page state
	else
		return
	end

	guide_pages[name] = page
	minetest.show_formspec(name, "lazarus_space:reactor_guide",
		build_guide_page(page))
end)

-- ============================================================
-- CRAFTING RECIPE
-- ============================================================

minetest.register_craft({
	output = "lazarus_space:reactor_guide",
	recipe = {
		{"", "default:mese_crystal_fragment", ""},
		{"", "default:paper", ""},
		{"", "default:paper", ""},
	},
})
