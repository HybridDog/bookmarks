local last_table_rows = {}
local last_selected_location = {}

-- FIXME: Buttons arranged in a 2D grid as in the bookmarks GUI mod could look
-- better because more locations can be shown on one page
-- https://cornernote.github.io/minetest-bookmarks_gui/

local function get_formspec()
	-- The width and height available in the Unified Inventory
	-- The height excludes the Unified Inventory bottom buttons
	-- I found the values by trial and error
	local full_width = 17.8
	local full_height = 11
	local form = {
		"tablecolumns[text,align=right;text,align=right;text,align=right;" ..
			"indent;text]",
		("table[0.2,0.2;%g,%g;bookmarks.table;X,Y,Z,1.0,Name,"):format(
			full_width - 0.4, full_height - 1.6)
	}
	local location_names = {}
	for go in pairs(bookmarks.locations) do
		location_names[#location_names+1] = go
	end
	table.sort(location_names)
	local info = {}
	for i = 1, #location_names do
		local pos = vector.round(bookmarks.locations[location_names[i]][1])
		local name = minetest.formspec_escape(location_names[i])
		info[#info+1] = ("%d,%d,%d,1.0,%s"):format(pos.x, pos.y, pos.z, name)
	end
	form[#form+1] = table.concat(info, ",")
	form[#form+1] = ";]"
	form[#form+1] = ("button[%g,%g;4,1;bookmarks.go_button;Go]"):format(
		full_width * 0.5 - 2, full_height - 1.2)
	return table.concat(form), location_names
end

local function execute_chatcommand(pname, cmd)
	for _,func in pairs(minetest.registered_on_chat_messages) do
		func(pname, cmd)
	end
end

unified_inventory.register_button("bookmarks", {
	type = "image",
	image = "bookmarks_T.png",
	tooltip = "Teleport Locations",
	hide_lite = true,
	condition = function()
		return next(bookmarks.locations) ~= nil
	end,
})

unified_inventory.register_page("bookmarks", {
	get_formspec = function(player)
		local formspec, location_names = get_formspec()
		last_table_rows[player:get_player_name()] = location_names
		return {
			formspec = formspec,
			draw_inventory = false,
			draw_item_list = false,
			formspec_prepend = true,
		}
	end
})

minetest.register_on_player_receive_fields(function(player, _, fields)
	if fields["bookmarks.table"] then
		local pname = player:get_player_name()
		local event = minetest.explode_table_event(fields["bookmarks.table"])
		if event.type == "CHG" or event.type == "DCL" then
			-- Remember the location for the Go button press
			local location_names = last_table_rows[pname] or {}
			local target = location_names[event.row-1]
			if not target then
				return true
			end
			last_selected_location[pname] = target
			if event.type == "DCL" then
				-- Teleport to the target location on double click or enter
				execute_chatcommand(pname, "/go " .. target)
				return true
			end
		end
	end
	if fields["bookmarks.go_button"] then
		-- Teleport to the last selected target
		local pname = player:get_player_name()
		local target = last_selected_location[pname]
		if not target then
			minetest.chat_send_player(pname, "No location selected!")
			return true
		end
		execute_chatcommand(pname, "/go " .. target)
		return true
	end
end)
