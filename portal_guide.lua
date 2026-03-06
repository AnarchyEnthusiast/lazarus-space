-- Lazarus Space: Lazarus Portal Guide Book
-- 4-page guide covering portal system: overview, setup, portal, safety.

-- ============================================================
-- PER-PLAYER PAGE TRACKING
-- ============================================================

local portal_guide_pages = {}

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
-- PAGE 1: OVERVIEW
-- ============================================================

local function build_page_overview(fs)
	fs = page_header(fs, "Lazarus Portal \xe2\x80\x94 Interdimensional Teleportation")

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
	local red = "#ff4444"

	line(c(white, "The Continuum Disrupter tears open a pocket of disrupted"))
	line(c(white, "space, creating a one-way portal to a random location."))

	y = y + 0.3
	line(c(white, "Requirements:"))
	line("  " .. c(teal, "Continuum Disrupter") .. c(grey, " (HV machine)"))
	line("  " .. c(teal, "HV power network") .. c(grey, " (") .. c(green, "36,000 EU/tick") .. c(grey, ")"))
	line("  " .. c(teal, "Decaying Uranium") .. c(grey, " (1 piece, portal fuel)"))

	y = y + 0.3
	line(c(white, "Obtaining Decaying Uranium:"))
	line("  " .. c(grey, "Build a ") .. c(gold, "Technic Reactor") .. c(grey, " inside the"))
	line("  " .. c(grey, "disrupted space field. While the reactor core is"))
	line("  " .. c(grey, "active, break it \xe2\x80\x94 it transmutes into ") .. c(gold, "Decaying Uranium") .. c(grey, "."))
	line("  " .. c(grey, "Handle with extreme care (see page 4)."))

	y = y + 0.3
	line(c(white, "The portal is temporary \xe2\x80\x94 it collapses after teleportation,"))
	line(c(white, "destroying 50% of the terrain inside the field."))

	y = y + 0.3
	fs = fs .. "box[0.5," .. y .. ";8,0.5;#331111]"
	fs = fs .. "label[0.7," .. (y + 0.08) .. ";" .. c(gold, "WARNING: ")
		.. c(red, "Decaying Uranium is lethal outside the field.") .. "]"

	return fs
end

-- ============================================================
-- PAGE 2: SETUP & CHARGING
-- ============================================================

local function build_page_setup(fs)
	fs = page_header(fs, "Step 1: Power the Disrupter")

	local c = minetest.colorize
	local teal = "#00ccaa"
	local white = "#ffffff"
	local grey = "#aaaaaa"
	local green = "#00ff66"

	local y = 1.5
	local inc = 0.42

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	line(c(white, "1. Place the Continuum Disrupter"))
	line(c(white, "2. Connect to an HV power network"))
	line(c(white, "3. Right-click to open the control panel"))
	line(c(white, "4. Click ") .. c(teal, "[Activate]") .. c(white, " to begin charging"))
	line(c(white, "5. Charging requires ") .. c(green, "168,000 EU") .. c(white, " total"))
	line(c(grey, "   at ") .. c(green, "36,000 EU") .. c(grey, " per tick (~5 seconds)"))

	y = y + 0.2
	line(c(grey, "Once the field is active, everything inside it will"))
	line(c(grey, "be frozen in time."))

	return fs
end

-- ============================================================
-- PAGE 3: PORTAL ACTIVATION & TELEPORTATION
-- ============================================================

local function build_page_portal(fs)
	fs = page_header(fs, "Step 2: Open the Portal")

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

	line(c(white, "1. Place a ") .. c(teal, "Warp Device") .. c(white, " inside the field"))
	line(c(white, "2. Hold ") .. c(teal, "Decaying Uranium") .. c(white, " in your hand"))
	line(c(white, "3. Right-click the ") .. c(teal, "Warp Device"))

	y = y + 0.3
	line(c(grey, "This will open the portal."))

	return fs
end

-- ============================================================
-- PAGE 4: SAFETY & WARNINGS
-- ============================================================

local function build_page_safety(fs)
	fs = page_header(fs, "Warnings & Safety")

	local y = 1.5
	local inc = 0.40

	local function line(text)
		fs = fs .. "label[0.6," .. y .. ";" .. text .. "]"
		y = y + inc
	end

	local c = minetest.colorize
	local white = "#ffffff"
	local grey = "#aaaaaa"
	local red = "#ff4444"
	local gold = "#ffcc00"
	local teal = "#00ccaa"

	-- Uranium warning box
	fs = fs .. "box[0.4," .. y .. ";8.2,2.1;#2a0808]"
	y = y + 0.1
	line(c(red, "DECAYING URANIUM IS LETHAL OUTSIDE THE FIELD"))
	y = y + 0.05
	line("  " .. c(gold, "\xe2\x80\xa2") .. c(grey, " Carrying it in your inventory deals fatal damage"))
	line("  " .. c(gold, "\xe2\x80\xa2") .. c(grey, " Placing a uranium block outside the field"))
	line(c(grey, "    triggers a massive explosion (15 block radius)"))
	line("  " .. c(gold, "\xe2\x80\xa2") .. c(grey, " It is ONLY safe inside an active disrupted space field"))

	y = y + 0.3
	line(c(white, "PORTAL COLLAPSE"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " After teleportation, the field collapses instantly"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " 50% of terrain inside the field is destroyed"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " The Continuum Disrupter is destroyed"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " Build away from anything you want to keep"))

	y = y + 0.3
	line(c(white, "ONE-WAY TRIP"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " Portals are one-way \xe2\x80\x94 there is no return portal"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " The destination is random and cannot be chosen"))
	line("  " .. c(teal, "\xe2\x80\xa2") .. c(grey, " Bring supplies for survival at the destination"))

	return fs
end

-- ============================================================
-- FORMSPEC SHELL AND NAVIGATION
-- ============================================================

local PAGE_COUNT = 4

local function build_portal_guide_page(page)
	local fs = "formspec_version[4]"
		.. "size[9,10]"
		.. "bgcolor[#080808;true]"
		.. "no_prepend[]"

	-- Dispatch
	if page == 1 then     fs = build_page_setup(fs)
	elseif page == 2 then fs = build_page_overview(fs)
	elseif page == 3 then fs = build_page_portal(fs)
	elseif page == 4 then fs = build_page_safety(fs)
	end

	-- Navigation
	fs = fs .. "label[3.5,9.55;Page " .. page .. " / " .. PAGE_COUNT .. "]"

	if page > 1 then
		fs = styled_btn(fs, 0.5, 9.15, 1.5, 0.65, "prev", "< Prev",
			"#00ccaa", "#00ddbb", "#009988")
	end

	if page < PAGE_COUNT then
		fs = styled_btn(fs, 7.0, 9.15, 1.5, 0.65, "next", "Next >",
			"#00ccaa", "#00ddbb", "#009988")
	end

	return fs
end

-- ============================================================
-- CRAFTITEM REGISTRATION
-- ============================================================

minetest.register_craftitem("lazarus_space:portal_guide", {
	description = "Lazarus Portal Guide",
	inventory_image = "lazarus_space_portal_guide.png",
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
		local name = user:get_player_name()
		if not portal_guide_pages[name] then
			portal_guide_pages[name] = 1
		end
		minetest.show_formspec(name, "lazarus_space:portal_guide",
			build_portal_guide_page(portal_guide_pages[name]))
		return itemstack
	end,
})

-- ============================================================
-- NAVIGATION HANDLER
-- ============================================================

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "lazarus_space:portal_guide" then return end
	local name = player:get_player_name()
	local page = portal_guide_pages[name] or 1

	if fields.prev and page > 1 then
		page = page - 1
	elseif fields.next and page < PAGE_COUNT then
		page = page + 1
	elseif fields.quit then
		return
	else
		return
	end

	portal_guide_pages[name] = page
	minetest.show_formspec(name, "lazarus_space:portal_guide",
		build_portal_guide_page(page))
end)

-- ============================================================
-- CRAFTING RECIPE
-- ============================================================

minetest.register_craft({
	output = "lazarus_space:portal_guide",
	recipe = {
		{"", "default:paper", ""},
		{"default:paper", "default:obsidian", "default:paper"},
		{"", "default:paper", ""},
	},
})
