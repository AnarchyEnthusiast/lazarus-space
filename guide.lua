-- Lazarus Space: Magnetic Fusion Reactor Build Guide
-- 18-page craftable guide book with interactive 3D model viewers.
-- Pages 1: Intro (tier comparison), 2-6: Tier 1, 7-11: Tier 2,
-- 12-16: Tier 3, 17: Control blocks, 18: Startup procedure.

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
-- GRID RENDERING (for page 17 control block diagram only)
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
-- 3D MODEL HELPER — single material, [combine atlas with escaped commas
-- ============================================================
-- All .obj files use a single material with UV coords pointing to slots
-- in an 80x16 atlas. The atlas is built at runtime via [combine with \,
-- so formspec parsing doesn't split on the coordinate commas.

local PAGE_MODELS = {
	-- Tier 1
	[2] = "reactor_t1_floor.obj",
	[3] = "reactor_t1_walls.obj",
	[4] = "reactor_t1_middle.obj",
	[5] = "reactor_t1_roof.obj",
	[6] = "reactor_t1_complete.obj",
	-- Tier 2
	[7] = "reactor_t2_floor.obj",
	[8] = "reactor_t2_walls.obj",
	[9] = "reactor_t2_middle.obj",
	[10] = "reactor_t2_roof.obj",
	[11] = "reactor_t2_complete.obj",
	-- Tier 3
	[12] = "reactor_t3_floor.obj",
	[13] = "reactor_t3_walls.obj",
	[14] = "reactor_t3_middle.obj",
	[15] = "reactor_t3_roof.obj",
	[16] = "reactor_t3_complete.obj",
}

-- ============================================================
-- TIER INFO (for page content generation)
-- ============================================================

local TIER_INFO = {
	{
		name = "Tier 1", size = "9x9x5",
		power = "140,000", rods = 3, jumpstart = "45,000",
		blocks = {pf = 64, tf = 32, sb = 41, plf = 12, pc = 1},
	},
	{
		name = "Tier 2", size = "13x13x5",
		power = "240,000", rods = 6, jumpstart = "85,000",
		blocks = {pf = 120, tf = 96, sb = 65, plf = 28, pc = 1},
	},
	{
		name = "Tier 3", size = "17x17x5",
		power = "550,000", rods = 12, jumpstart = "200,000",
		blocks = {pf = 152, tf = 160, sb = 177, plf = 44, pc = 1},
	},
}

-- Runtime [combine atlas — \, escapes commas for the formspec parser
local MODEL_TEXTURE = "[combine:80x16"
	.. ":0\\,0=lazarus_space_pole_field.png"
	.. ":16\\,0=lazarus_space_toroid_field.png"
	.. ":32\\,0=default_steel_block.png"
	.. ":48\\,0=lazarus_space_plasma_field.png"
	.. ":64\\,0=lazarus_space_pole_corrector.png"

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
	local inc = 0.42

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	local c = minetest.colorize
	local teal = "#00ccaa"
	local white = "#ffffff"
	local grey = "#aaaaaa"
	local green = "#00ff66"
	local gold = "#ffcc00"

	line(c(white, "The Magnetic Fusion Reactor comes in 3 tiers."))
	line(c(white, "Each is a multiblock structure generating power from fuel rods."))

	y = y + 0.25
	-- Tier comparison table header
	fs = fs .. "box[0.5," .. y .. ";8.0,0.35;#1a1a2e]"
	fs = fs .. "label[0.7," .. (y + 0.2) .. ";"
		.. c(teal, "Tier") .. "    "
		.. c(teal, "Power") .. "         "
		.. c(teal, "Rods") .. "   "
		.. c(teal, "Jumpstart") .. "        "
		.. c(teal, "Size") .. "]"
	y = y + 0.45

	for _, t in ipairs(TIER_INFO) do
		line("  " .. c(white, t.name) .. "   "
			.. c(green, t.power .. " EU") .. "   "
			.. c(white, t.rods .. " rods") .. "   "
			.. c(gold, t.jumpstart .. " EU") .. "   "
			.. c(grey, t.size))
	end

	y = y + 0.25
	line(c(white, "All tiers use 8-hour fuel loads and 5-second charge time."))

	y = y + 0.25
	line(c(grey, "Pages 2-6: Tier 1 build guide"))
	line(c(grey, "Pages 7-11: Tier 2 build guide"))
	line(c(grey, "Pages 12-16: Tier 3 build guide"))
	line(c(grey, "Page 17: Control block placement"))
	line(c(grey, "Page 18: Startup procedure"))

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
-- TIER BUILD PAGES (pages 2-16, 5 pages per tier)
-- ============================================================
-- Each tier gets: Floor, Walls, Middle, Roof, Complete 3D.
-- Page number → tier: tier = floor((page - 2) / 5) + 1
-- Page number → layer: layer = (page - 2) % 5 + 1

local LAYER_LEGENDS = {
	-- 1: Floor
	{
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	},
	-- 2: Walls
	{
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	},
	-- 3: Middle
	{
		{color = "#33cc33", label = "Plasma Field", width = 2.0},
		{color = "#00cccc", label = "Toroid Field", width = 2.0},
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#cc44ff", label = "Corrector", width = 1.6},
		{color = "#888888", label = "Steel Block", width = 1.8},
	},
	-- 4: Roof
	{
		{color = "#e86400", label = "Pole Field", width = 1.8},
		{color = "#888888", label = "Steel Block", width = 1.8},
	},
	-- 5: Complete
	{
		{color = "#e86400", label = "Pole", width = 1.1},
		{color = "#00cccc", label = "Toroid", width = 1.3},
		{color = "#33cc33", label = "Plasma", width = 1.3},
		{color = "#cc44ff", label = "Corrector", width = 1.6},
		{color = "#888888", label = "Steel", width = 1.2},
	},
}

local LAYER_TITLES = {
	"Base Platform (Bottom Layer)",
	"Walls (Layers 2 & 4)",
	"Middle Layer (Core & Plasma Ring)",
	"Roof (Top Layer)",
	"Complete 3D View",
}

local LAYER_NOTES = {
	-- 1: Floor
	function(t)
		return {
			t.size:sub(1, t.size:find("x") - 1) .. "x" .. t.size:sub(1, t.size:find("x") - 1)
				.. " square border of Pole Field with a Steel Block",
			"cross and corner bolts inside. Build this layer first.",
		}
	end,
	-- 2: Walls
	function(_)
		return {
			"Cross-shaped layout. Build two identical copies of this layer \xe2\x80\x94",
			"one directly above the base, one directly below the roof.",
		}
	end,
	-- 3: Middle
	function(_)
		return {
			"Pole Corrector at the exact center, surrounded by Pole Field ring.",
			"Green plasma ring loops around the outside. Steel Blocks at corners.",
		}
	end,
	-- 4: Roof
	function(_)
		return {
			"Mirrors the base \xe2\x80\x94 Pole Field border with corner Steel Blocks.",
		}
	end,
	-- 5: Complete
	function(t)
		return {
			t.name .. ": " .. t.power .. " EU  |  " .. t.rods .. " rods  |  " .. t.size,
		}
	end,
}

local function build_tier_page(fs, page)
	local tier_idx = math.floor((page - 2) / 5) + 1
	local layer = (page - 2) % 5 + 1
	local tier = TIER_INFO[tier_idx]

	local title = tier.name .. " \xe2\x80\x94 " .. LAYER_TITLES[layer]
	local legend = LAYER_LEGENDS[layer]
	local notes = LAYER_NOTES[layer](tier)

	if layer == 5 then
		-- Complete 3D page: larger model, no detailed notes
		fs = page_header(fs, title)
		fs = add_model(fs, page, 0.3, 1.2, 8.4, 6.8, 25, -45)
		fs = fs .. "label[2.8,8.15;" .. minetest.colorize("#aaaaaa", "Click and drag to rotate the model") .. "]"
		fs = draw_legend(fs, legend, 0.6, 8.5)
		fs = fs .. "label[0.6,9.0;" .. minetest.formspec_escape(notes[1]) .. "]"
		return fs
	end

	return build_model_page(fs, title, page, legend, notes)
end

-- ============================================================
-- PAGE 17: CONTROL BLOCKS (horizontal layout with side view)
-- ============================================================


local GRID_CONTROL = {
	"...",
	"...",
	"JKO",
	"...",
	"...",
}

local function build_page_controls(fs)
	fs = page_header(fs, "Control Panel, Jumpstarter & Power Output")

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
	fs = page_header(fs, "Startup Procedure")

	local y = 1.5
	local inc = 0.42
	local c = minetest.colorize

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	line(c("#ffffff", "1. Select tier in the Control Panel"))
	line(c("#aaaaaa", "   (sets fuel slots and jumpstart energy)"))

	y = y + 0.12
	line(c("#ffffff", "2. Connect the Jumpstarter to an HV network"))
	line(c("#aaaaaa", "   Jumpstart energy by tier:"))
	line(c("#aaaaaa", "   T1: ") .. c("#ffcc00", "45,000 EU")
		.. c("#aaaaaa", "  T2: ") .. c("#ffcc00", "85,000 EU")
		.. c("#aaaaaa", "  T3: ") .. c("#ffcc00", "200,000 EU"))

	y = y + 0.12
	line(c("#ffffff", "3. Click ") .. c("#00ccaa", "[Check Structure]") .. c("#ffffff", " to validate"))

	y = y + 0.12
	line(c("#ffffff", "4. Load uranium fuel rods"))
	line(c("#aaaaaa", "   T1: 3 rods  |  T2: 6 rods  |  T3: 12 rods"))

	y = y + 0.12
	line(c("#ffffff", "5. Click ") .. c("#00ccaa", "[Jump Start]") .. c("#ffffff", " (5-second charge)"))

	y = y + 0.12
	line(c("#ffffff", "6. Click ") .. c("#00ccaa", "[Inject Fuel & Start]"))
	line(c("#aaaaaa", "   Power output by tier:"))
	line(c("#aaaaaa", "   T1: ") .. c("#00ff66", "140,000 EU")
		.. c("#aaaaaa", "  T2: ") .. c("#00ff66", "240,000 EU")
		.. c("#aaaaaa", "  T3: ") .. c("#00ff66", "550,000 EU"))

	y = y + 0.12
	line(c("#ffffff", "7. Right-click Power Output to set tier: LV / MV / HV"))

	-- Divider
	y = y + 0.25
	fs = fs .. "box[0.6," .. y .. ";7.8,0.02;#333333]"
	y = y + 0.25

	line(c("#aaaaaa", "Deactivating preserves remaining fuel."))
	line(c("#aaaaaa", "Click ") .. c("#00ccaa", "[Resume Reactor]") .. c("#aaaaaa", " to restart without recharging."))

	return fs
end

-- ============================================================
-- FORMSPEC SHELL AND NAVIGATION
-- ============================================================

local PAGE_COUNT = 18

local function build_guide_page(page)
	local fs = "formspec_version[4]"
		.. "size[9,10]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Dispatch to page builder
	if page == 1 then
		fs = build_page_intro(fs)
	elseif page >= 2 and page <= 16 then
		fs = build_tier_page(fs, page)
	elseif page == 17 then
		fs = build_page_controls(fs)
	elseif page == 18 then
		fs = build_page_startup(fs)
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
