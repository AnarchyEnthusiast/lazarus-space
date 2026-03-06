-- Lazarus Space: Magnetic Fusion Reactor Build Guide
-- Tabbed guide book with 3 tier tabs, 7 pages each.
-- Pages 1: Tier intro, 2-5: Layer build steps, 6: Complete 3D, 7: Controls & startup.

-- ============================================================
-- PER-PLAYER STATE TRACKING (tab + page)
-- ============================================================

local guide_state = {}  -- { [player_name] = { tab = 1, page = 1 } }

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
-- 3D MODEL HELPER — single material, [combine atlas with escaped commas
-- ============================================================

local TIER_MODELS = {
	-- [tab][page] = mesh file
	{  -- Tier 1
		[2] = "reactor_t1_floor.obj",
		[3] = "reactor_t1_walls.obj",
		[4] = "reactor_t1_middle.obj",
		[5] = "reactor_t1_roof.obj",
		[6] = "reactor_t1_complete.obj",
	},
	{  -- Tier 2
		[2] = "reactor_t2_floor.obj",
		[3] = "reactor_t2_walls.obj",
		[4] = "reactor_t2_middle.obj",
		[5] = "reactor_t2_roof.obj",
		[6] = "reactor_t2_complete.obj",
	},
	{  -- Tier 3
		[2] = "reactor_t3_floor.obj",
		[3] = "reactor_t3_walls.obj",
		[4] = "reactor_t3_middle.obj",
		[5] = "reactor_t3_roof.obj",
		[6] = "reactor_t3_complete.obj",
	},
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

local function add_model(fs, tab, page, x, y, w, h, rot_x, rot_y)
	local tier_models = TIER_MODELS[tab]
	local mesh = tier_models and tier_models[page]
	if not mesh then return fs end
	rot_x = rot_x or 20
	rot_y = rot_y or -30
	fs = fs .. "model[" .. x .. "," .. y .. ";" .. w .. "," .. h
		.. ";reactor_preview;" .. mesh .. ";" .. MODEL_TEXTURE
		.. ";" .. rot_x .. "," .. rot_y .. ";false;true]"
	return fs
end

-- ============================================================
-- PAGE 1: TIER INTRO (per-tab)
-- ============================================================

local function build_tier_intro(fs, tab)
	local tier = TIER_INFO[tab]
	fs = page_header(fs, tier.name .. " \xe2\x80\x94 Magnetic Fusion Reactor")

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
	local green = "#00ff66"
	local gold = "#ffcc00"

	line(c(white, "A " .. tier.size .. " multiblock structure."))

	y = y + 0.2
	line(c(grey, "Power Output:  ") .. c(green, tier.power .. " EU"))
	line(c(grey, "Fuel Rods:     ") .. c(white, tier.rods .. ""))
	line(c(grey, "Jumpstart:     ") .. c(gold, tier.jumpstart .. " EU"))
	line(c(grey, "Fuel Duration: ") .. c(white, "8 hours"))
	line(c(grey, "Charge Time:   ") .. c(white, "5 seconds"))

	y = y + 0.3
	line(c(white, "Required blocks:"))
	local b = tier.blocks
	line("  " .. c(teal, string.format("%3d", b.pf)) .. "x  " .. c(white, "Pole Field"))
	line("  " .. c(teal, string.format("%3d", b.tf)) .. "x  " .. c(white, "Toroid Field"))
	line("  " .. c(teal, string.format("%3d", b.sb)) .. "x  " .. c(white, "Steel Block"))
	line("  " .. c(teal, string.format("%3d", b.plf)) .. "x  " .. c(white, "Plasma Field"))
	line("  " .. c(teal, "  1") .. "x  " .. c(white, "Pole Corrector"))
	line("  " .. c(teal, "  1") .. "x  " .. c(white, "Fusion Control Panel"))
	line("  " .. c(teal, "  1") .. "x  " .. c(white, "Plasma Jumpstarter"))
	line("  " .. c(teal, "  1") .. "x  " .. c(white, "Fusion Power Output"))

	y = y + 0.3
	line(c(grey, "Pages 2-5: Layer-by-layer build guide"))
	line(c(grey, "Page 6: Complete structure overview"))
	line(c(grey, "Page 7: Control blocks & startup"))

	return fs
end

-- ============================================================
-- BUILD-STEP PAGE HELPER (pages 2-5)
-- ============================================================

local function build_model_page(fs, title, tab, page, legend, notes)
	fs = page_header(fs, title)

	-- Label above model
	fs = fs .. "label[0.5,1.05;" .. minetest.colorize("#aaaaaa", "3D View \xe2\x80\x94 click & drag to rotate") .. "]"

	-- Large 3D model filling most of the page
	fs = add_model(fs, tab, page, 0.3, 1.2, 8.4, 5.8)

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
-- TIER BUILD PAGES (pages 2-6)
-- ============================================================

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
	function(t)
		return {
			t.size:sub(1, t.size:find("x") - 1) .. "x" .. t.size:sub(1, t.size:find("x") - 1)
				.. " square border of Pole Field with a Steel Block",
			"cross and corner bolts inside. Build this layer first.",
		}
	end,
	function(_)
		return {
			"Cross-shaped layout. Build two identical copies of this layer \xe2\x80\x94",
			"one directly above the base, one directly below the roof.",
		}
	end,
	function(_)
		return {
			"Pole Corrector at the exact center, surrounded by Pole Field ring.",
			"Green plasma ring loops around the outside. Steel Blocks at corners.",
		}
	end,
	function(_)
		return {
			"Mirrors the base \xe2\x80\x94 Pole Field border with corner Steel Blocks.",
		}
	end,
	function(t)
		return {
			t.name .. ": " .. t.power .. " EU  |  " .. t.rods .. " rods  |  " .. t.size,
		}
	end,
}

local function build_tier_model_page(fs, tab, page)
	local tier = TIER_INFO[tab]
	local layer = page - 1  -- page 2→layer 1, page 6→layer 5

	local title = tier.name .. " \xe2\x80\x94 " .. LAYER_TITLES[layer]
	local legend = LAYER_LEGENDS[layer]
	local notes = LAYER_NOTES[layer](tier)

	if layer == 5 then
		-- Complete 3D page: larger model
		fs = page_header(fs, title)
		fs = add_model(fs, tab, page, 0.3, 1.2, 8.4, 6.8, 25, -45)
		fs = fs .. "label[2.8,8.15;" .. minetest.colorize("#aaaaaa", "Click and drag to rotate the model") .. "]"
		fs = draw_legend(fs, legend, 0.6, 8.5)
		fs = fs .. "label[0.6,9.0;" .. minetest.formspec_escape(notes[1]) .. "]"
		return fs
	end

	return build_model_page(fs, title, tab, page, legend, notes)
end

-- ============================================================
-- PAGE 7: CONTROL BLOCKS & STARTUP (shared across all tabs)
-- ============================================================

local GRID_CONTROL = {
	"...",
	"...",
	"JKO",
	"...",
	"...",
}

local function build_page_controls_and_startup(fs)
	fs = page_header(fs, "Control Blocks & Startup Procedure")

	local c = minetest.colorize
	local grey = "#aaaaaa"

	-- Control blocks — compact horizontal row
	local box_w = 2.2
	local box_h = 0.55
	local box_gap = 0.15
	local total_w = 3 * box_w + 2 * box_gap
	local box_x = (9 - total_w) / 2
	local box_y = 1.3

	fs = fs .. "box[" .. box_x .. "," .. box_y .. ";" .. box_w .. "," .. box_h .. ";#ccaa00]"
	fs = fs .. "label[" .. (box_x + 0.35) .. "," .. (box_y + 0.3) .. ";Jumpstarter]"

	local cp_x = box_x + box_w + box_gap
	fs = fs .. "box[" .. cp_x .. "," .. box_y .. ";" .. box_w .. "," .. box_h .. ";#cc3399]"
	fs = fs .. "label[" .. (cp_x + 0.25) .. "," .. (box_y + 0.3) .. ";Control Panel]"

	local po_x = cp_x + box_w + box_gap
	fs = fs .. "box[" .. po_x .. "," .. box_y .. ";" .. box_w .. "," .. box_h .. ";#cc6600]"
	fs = fs .. "label[" .. (po_x + 0.25) .. "," .. (box_y + 0.3) .. ";Power Output]"

	-- Compact placement grid
	local ctx_cell = 0.35
	local ctx_gap = 0.02
	local ctx_step = ctx_cell + ctx_gap
	local ctx_x = (9 - 3 * ctx_step) / 2
	local ctx_y = 2.1
	fs = draw_grid(fs, GRID_CONTROL, ctx_x, ctx_y, ctx_cell, ctx_gap)
	fs = fs .. "label[" .. ctx_x .. "," .. (ctx_y - 0.2) .. ";"
		.. c(grey, "Side view") .. "]"

	-- Placement notes
	local y = ctx_y + 5 * ctx_step + 0.15
	fs = fs .. "label[0.6," .. y .. ";"
		.. c(grey, "Panel touches Toroid Field. Jumpstarter & Output touch Panel.") .. "]"

	-- Divider
	y = y + 0.35
	fs = fs .. "box[0.6," .. y .. ";7.8,0.02;#333333]"
	y = y + 0.25

	-- Startup procedure (compact)
	local inc = 0.38
	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	line(c("#ffffff", "1. Select tier in the Control Panel"))
	line(c("#ffffff", "2. Connect Jumpstarter to HV network"))
	line(c(grey, "   T1: ") .. c("#ffcc00", "45k EU")
		.. c(grey, "  T2: ") .. c("#ffcc00", "85k EU")
		.. c(grey, "  T3: ") .. c("#ffcc00", "200k EU"))
	line(c("#ffffff", "3. Click ") .. c("#00ccaa", "[Check Structure]"))
	line(c("#ffffff", "4. Load fuel rods (") .. c(grey, "3 / 6 / 12 by tier") .. c("#ffffff", ")"))
	line(c("#ffffff", "5. Click ") .. c("#00ccaa", "[Jump Start]") .. c(grey, " (5s charge)"))
	line(c("#ffffff", "6. Click ") .. c("#00ccaa", "[Inject Fuel & Start]"))
	line(c(grey, "   T1: ") .. c("#00ff66", "140k EU")
		.. c(grey, "  T2: ") .. c("#00ff66", "240k EU")
		.. c(grey, "  T3: ") .. c("#00ff66", "550k EU"))
	line(c("#ffffff", "7. Set Power Output tier: LV / MV / HV"))

	y = y + 0.1
	line(c(grey, "Deactivate preserves fuel. Resume without recharging."))

	return fs
end

-- ============================================================
-- FORMSPEC SHELL AND NAVIGATION
-- ============================================================

local PAGES_PER_TAB = 7

local function build_guide_page(tab, page)
	local fs = "formspec_version[4]"
		.. "size[9,10]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Tab header
	fs = fs .. "tabheader[0,0;9,0.65;guide_tab;Tier 1,Tier 2,Tier 3;"
		.. tab .. ";true;true]"

	-- Dispatch to page builder
	if page == 1 then
		fs = build_tier_intro(fs, tab)
	elseif page >= 2 and page <= 6 then
		fs = build_tier_model_page(fs, tab, page)
	elseif page == 7 then
		fs = build_page_controls_and_startup(fs)
	end

	-- Navigation (within tab)
	fs = fs .. "label[3.5,9.55;Page " .. page .. " / " .. PAGES_PER_TAB .. "]"

	if page > 1 then
		fs = styled_btn(fs, 0.5, 9.15, 1.5, 0.65, "prev", "< Prev",
			"#00ccaa", "#00ddbb", "#009988")
	end

	if page < PAGES_PER_TAB then
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
		local state = guide_state[name]
		if not state then
			state = { tab = 1, page = 1 }
			guide_state[name] = state
		end
		minetest.show_formspec(name, "lazarus_space:reactor_guide",
			build_guide_page(state.tab, state.page))
		return itemstack
	end,
})

-- ============================================================
-- NAVIGATION HANDLER
-- ============================================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "lazarus_space:reactor_guide" then return end
	local name = player:get_player_name()
	local state = guide_state[name] or { tab = 1, page = 1 }

	if fields.guide_tab then
		-- Tab clicked — switch tier, reset to page 1
		local new_tab = tonumber(fields.guide_tab)
		if new_tab and new_tab >= 1 and new_tab <= 3 then
			state.tab = new_tab
			state.page = 1
		end
	elseif fields.prev and state.page > 1 then
		state.page = state.page - 1
	elseif fields.next and state.page < PAGES_PER_TAB then
		state.page = state.page + 1
	elseif fields.quit then
		return
	else
		return
	end

	guide_state[name] = state
	minetest.show_formspec(name, "lazarus_space:reactor_guide",
		build_guide_page(state.tab, state.page))
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
