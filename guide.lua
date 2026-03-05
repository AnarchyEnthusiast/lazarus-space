-- Lazarus Space: Magnetic Fusion Reactor Build Guide
-- 8-page craftable guide book with colored grid blueprints.

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
-- GRID RENDERING UTILITY
-- ============================================================

local CELL = 0.3
local GAP  = 0.02
local STEP = CELL + GAP  -- 0.32 per cell

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

local function draw_grid(fs, grid, start_x, start_y, cell_size)
	cell_size = cell_size or CELL
	local step = cell_size + GAP
	for row_idx, row_str in ipairs(grid) do
		for col = 1, #row_str do
			local ch = row_str:sub(col, col)
			local color = GRID_COLORS[ch]
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
	line(c(white, "structure that generates ") .. c("#00ff66", "140,000 EU") .. c(white, " of power."))

	y = y + 0.2
	line(c(white, "Fueled by ") .. c(teal, "6") .. c(white, " uranium fuel rods \xe2\x80\x94 each load runs for ") .. c(teal, "8 hours") .. c(white, "."))
	line(c(white, "Requires ") .. c("#ffcc00", "50,000 EU") .. c(white, " from an HV network for jump start."))

	y = y + 0.2
	line(c(white, "Required blocks:"))
	line("  " .. c(teal, "120x") .. "  " .. c(white, "Pole Field"))
	line("  " .. c(teal, " 96x") .. "  " .. c(white, "Toroid Field"))
	line("  " .. c(teal, " 65x") .. "  " .. c(white, "Steel Block"))
	line("  " .. c(teal, " 28x") .. "  " .. c(white, "Plasma Field") .. c(grey, "  (corners form automatically)"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Pole Corrector"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Fusion Control Panel"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Plasma Jumpstarter"))
	line("  " .. c(teal, "  1x") .. "  " .. c(white, "Fusion Power Output"))

	y = y + 0.2
	line(c(grey, "Pages 2-6: Layer-by-layer build guide"))
	line(c(grey, "Page 7: Control block placement"))
	line(c(grey, "Page 8: Startup procedure"))

	return fs
end

-- ============================================================
-- PAGE 2: BASE PLATFORM (FLOOR)
-- ============================================================

local GRID_FLOOR = {
	"PPPPPPPPPPPPP",  -- z=-6
	"PS....S....SP",  -- z=-5
	"P.....S.....P",  -- z=-4
	"P.....S.....P",  -- z=-3
	"P.....S.....P",  -- z=-2
	"P....SSS....P",  -- z=-1
	"PSSSSSSSSSSSP",  -- z= 0
	"P....SSS....P",  -- z=+1
	"P.....S.....P",  -- z=+2
	"P.....S.....P",  -- z=+3
	"P.....S.....P",  -- z=+4
	"PS....S....SP",  -- z=+5
	"PPPPPPPPPPPPP",  -- z=+6
}

local function build_page_floor(fs)
	fs = page_header(fs, "Step 1: Base Platform (Bottom Layer)")

	local grid_w = 13 * STEP
	local start_x = (9 - grid_w) / 2
	local start_y = 1.5
	fs = draw_grid(fs, GRID_FLOOR, start_x, start_y)

	local legend_y = start_y + 13 * STEP + 0.3
	fs = draw_legend(fs, {
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, 0.6, legend_y)

	local note_y = legend_y + 0.6
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("13x13 square border of Pole Field with a Steel Block") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.4) .. ";"
		.. minetest.formspec_escape("cross and corner bolts inside. Build this layer first.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 3: WALL LAYERS
-- ============================================================

local GRID_WALLS = {
	".............",  -- z=-6
	".S..T.T.T..S.",  -- z=-5
	"....T.T.T....",  -- z=-4
	"....T.T.T....",  -- z=-3
	".TTT..S..TTT.",  -- z=-2
	".....PPP.....",  -- z=-1
	".TTTSPaPSTTT.",  -- z= 0
	".....PPP.....",  -- z=+1
	".TTT..S..TTT.",  -- z=+2
	"....T.T.T....",  -- z=+3
	"....T.T.T....",  -- z=+4
	".S..T.T.T..S.",  -- z=+5
	".............",  -- z=+6
}

local function build_page_walls(fs)
	fs = page_header(fs, "Step 2: Walls (Layers 2 & 4)")

	local grid_w = 13 * STEP
	local start_x = (9 - grid_w) / 2
	local start_y = 1.5
	fs = draw_grid(fs, GRID_WALLS, start_x, start_y)

	local legend_y = start_y + 13 * STEP + 0.3
	fs = draw_legend(fs, {
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
		{color = "#222244", label = "Air (required)", width = 2.0},
	}, 0.6, legend_y)

	local note_y = legend_y + 0.9
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("Cross-shaped layout. Build two identical copies of this layer \xe2\x80\x94") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.4) .. ";"
		.. minetest.formspec_escape("one directly above the base, one directly below the roof.") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.8) .. ";"
		.. minetest.formspec_escape("Center must be air (empty) above and below the Pole Corrector.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 4: REACTOR CORE (zoomed center)
-- ============================================================

local GRID_CORE = {
	".T.T.T.",  -- z=-3
	"T..S..T",  -- z=-2
	"..PPP..",  -- z=-1
	"TSP*PST",  -- z= 0
	"..PPP..",  -- z=+1
	"T..S..T",  -- z=+2
	".T.T.T.",  -- z=+3
}

local function build_page_core(fs)
	fs = page_header(fs, "Step 3: Reactor Core (Middle Layer Center)")

	local core_cell = 0.55
	local core_step = core_cell + GAP
	local grid_w = 7 * core_step
	local start_x = (9 - grid_w) / 2
	local start_y = 1.8
	fs = draw_grid(fs, GRID_CORE, start_x, start_y, core_cell)

	local legend_y = start_y + 7 * core_step + 0.4
	fs = draw_legend(fs, {
		{color = "#cc44ff", label = "Pole Corrector", width = 2.2},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, 0.6, legend_y)

	local note_y = legend_y + 0.9
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("3x3 Pole Field ring with Pole Corrector at the exact center.") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.4) .. ";"
		.. minetest.formspec_escape("Steel Blocks connect the core to the outer Toroid walls.") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.8) .. ";"
		.. minetest.formspec_escape("Air is required directly above and below the Pole Corrector.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 5: PLASMA RING (full middle layer)
-- ============================================================

local GRID_PLASMA = {
	".............",  -- z=-6
	".SS.T.T.T.SS.",  -- z=-5
	".SLCLLLLLLCS.",  -- z=-4
	"..L.T.T.T.L..",  -- z=-3
	".TLT..S..TLT.",  -- z=-2
	"..L..PPP..L..",  -- z=-1
	".TLTSP*PSTLT.",  -- z= 0
	"..L..PPP..L..",  -- z=+1
	".TLT..S..TLT.",  -- z=+2
	"..C.T.T.T.L..",  -- z=+3
	".SLLLLLLCLLS.",  -- z=+4
	".SS.T.T.T.SS.",  -- z=+5
	".............",  -- z=+6
}

local function build_page_plasma(fs)
	fs = page_header(fs, "Step 4: Plasma Ring (Middle Layer Full)")

	local grid_w = 13 * STEP
	local start_x = (9 - grid_w) / 2
	local start_y = 1.5
	fs = draw_grid(fs, GRID_PLASMA, start_x, start_y)

	local legend_y = start_y + 13 * STEP + 0.3
	fs = draw_legend(fs, {
		{color = "#33cc33", label = "Plasma Field", width = 2.0},
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#cc44ff", label = "Pole Corrector", width = 2.2},
		{color = "#888888", label = "Steel Block", width = 1.8},
	}, 0.6, legend_y)

	local note_y = legend_y + 0.9
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("Green plasma ring loops around the outside. Corners form") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.4) .. ";"
		.. minetest.formspec_escape("automatically when you place straight pieces \xe2\x80\x94 just place them") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.8) .. ";"
		.. minetest.formspec_escape("in a continuous loop. Steel Blocks at the outer corners.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 6: ROOF
-- ============================================================

local GRID_ROOF = {
	"PPPPPPPPPPPPP",  -- z=-6
	"PS.........SP",  -- z=-5
	"P...........P",  -- z=-4
	"P...........P",  -- z=-3
	"P...........P",  -- z=-2
	"P...........P",  -- z=-1
	"P.....a.....P",  -- z= 0
	"P...........P",  -- z=+1
	"P...........P",  -- z=+2
	"P...........P",  -- z=+3
	"P...........P",  -- z=+4
	"PS.........SP",  -- z=+5
	"PPPPPPPPPPPPP",  -- z=+6
}

local function build_page_roof(fs)
	fs = page_header(fs, "Step 5: Roof (Top Layer)")

	local grid_w = 13 * STEP
	local start_x = (9 - grid_w) / 2
	local start_y = 1.5
	fs = draw_grid(fs, GRID_ROOF, start_x, start_y)

	local legend_y = start_y + 13 * STEP + 0.3
	fs = draw_legend(fs, {
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
		{color = "#222244", label = "Air (required)", width = 2.0},
	}, 0.6, legend_y)

	local note_y = legend_y + 0.6
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("Mirrors the base \xe2\x80\x94 Pole Field border with corner Steel Blocks.") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.4) .. ";"
		.. minetest.formspec_escape("Center must be air (open) above the Pole Corrector.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 7: CONTROL BLOCKS
-- ============================================================

local GRID_CONTROL = {
	"..T..",
	"..T..",
	"KJTOT",
	"..T..",
	"..T..",
}

local function build_page_controls(fs)
	fs = page_header(fs, "Step 6: Control Panel, Jumpstarter & Power Output")

	-- Vertical stack diagram (3 colored blocks)
	local stack_x = 1.5
	local stack_y = 1.8
	local box_w = 3.0
	local box_h = 0.7
	local box_gap = 0.05

	-- Jumpstarter (top)
	fs = fs .. "box[" .. stack_x .. "," .. stack_y .. ";" .. box_w .. "," .. box_h .. ";#ccaa00]"
	fs = fs .. "label[" .. (stack_x + 0.6) .. "," .. (stack_y + 0.38) .. ";Jumpstarter]"

	-- Control Panel (middle)
	local cp_y = stack_y + box_h + box_gap
	fs = fs .. "box[" .. stack_x .. "," .. cp_y .. ";" .. box_w .. "," .. box_h .. ";#cc3399]"
	fs = fs .. "label[" .. (stack_x + 0.5) .. "," .. (cp_y + 0.38) .. ";Control Panel]"

	-- Power Output (bottom)
	local po_y = cp_y + box_h + box_gap
	fs = fs .. "box[" .. stack_x .. "," .. po_y .. ";" .. box_w .. "," .. box_h .. ";#cc6600]"
	fs = fs .. "label[" .. (stack_x + 0.5) .. "," .. (po_y + 0.38) .. ";Power Output]"

	-- Context grid (5x5, cell_size=0.4)
	local ctx_cell = 0.4
	local ctx_step = ctx_cell + GAP
	local ctx_x = 5.5
	local ctx_y = 2.0
	fs = draw_grid(fs, GRID_CONTROL, ctx_x, ctx_y, ctx_cell)

	-- Label for context grid
	fs = fs .. "label[" .. ctx_x .. "," .. (ctx_y + 5 * ctx_step + 0.2) .. ";"
		.. minetest.formspec_escape("Top-down view") .. "]"

	-- Notes below diagrams
	local note_y = po_y + box_h + 0.6
	fs = fs .. "label[0.6," .. note_y .. ";"
		.. minetest.formspec_escape("The Control Panel must touch a Toroid Field block.") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.45) .. ";"
		.. minetest.formspec_escape("The Jumpstarter and Power Output must each touch") .. "]"
	fs = fs .. "label[0.6," .. (note_y + 0.85) .. ";"
		.. minetest.formspec_escape("the Control Panel. Can be placed on any side.") .. "]"

	-- Legend
	local legend_y = note_y + 1.4
	fs = draw_legend(fs, {
		{color = "#cc3399", label = "Control Panel", width = 2.2},
		{color = "#ccaa00", label = "Jumpstarter", width = 2.0},
		{color = "#cc6600", label = "Power Output", width = 2.0},
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
	}, 0.6, legend_y)

	return fs
end

-- ============================================================
-- PAGE 8: STARTUP PROCEDURE
-- ============================================================

local function build_page_startup(fs)
	fs = page_header(fs, "Step 7: Startup Procedure")

	local y = 1.5
	local inc = 0.45
	local c = minetest.colorize

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	line(c("#ffffff", "1. Connect the Jumpstarter to an HV network"))
	line(c("#aaaaaa", "   (needs ") .. c("#ffcc00", "50,000 EU") .. c("#aaaaaa", " stored)"))

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
	line(c("#aaaaaa", "   Reactor activates \xe2\x80\x94 ") .. c("#00ff66", "140,000 EU") .. c("#aaaaaa", " output"))

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
	elseif page == 4 then fs = build_page_core(fs)
	elseif page == 5 then fs = build_page_plasma(fs)
	elseif page == 6 then fs = build_page_roof(fs)
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

	-- Next button (hidden on page 8)
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
