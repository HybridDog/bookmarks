
-- ***********************************************************************************
--		go										**************************************************
-- ***********************************************************************************


local storage = minetest.get_mod_storage()
bookmarks = {}

-- Load the bookmarked locations from the storage
bookmarks.locations = minetest.deserialize(storage:get_string("bookmarks")) or {}

function bookmarks.save_bookmarks()
	storage:set_string("bookmarks", minetest.serialize(bookmarks.locations))
end

local mod_path = minetest.get_modpath(minetest.get_current_modname())
if minetest.settings:get_bool("bookmarks.legacy", false) then
	dofile(mod_path .. "/legacy.lua")
end

if minetest.global_exists("unified_inventory") then
	dofile(mod_path .. "/unified_inventory_gui.lua")
end


minetest.register_chatcommand("setgo", {
	params = "<bookmark_name>",
	description = "Set a /go destination",
	privs = {server=true},
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Are you a player?"
		end
		if param == "" then
			return false, "Missing bookmark name argument"
		end
		local np = player:get_pos()
		bookmarks.locations[param] = {
			vector.apply(np, function(za)
				return math.floor(za * 10 + 0.5) / 10
			end),
			{
				yaw = math.floor(player:get_look_horizontal() * 100 + .5) / 100,
				pitch = math.floor(player:get_look_vertical() * 100 + .5) / 100
			}
		}
		bookmarks.save_bookmarks()
		return true, "/go "..param.." set"
	end,
})

minetest.register_chatcommand("go", {
	params = "<bookmark_name>",
	description = "Go to a destination",
	func = function(name, target)
		if not next(bookmarks.locations) then
			return false, "Currently there are no destinations bookmarked"
		end
		local dest = bookmarks.locations[target]
		if not dest then
			return false, "Bookmark not found: \"" .. target .. "\""
		end
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Are you a player?"
		end
		player:move_to(dest[1])
		player:set_look_horizontal(dest[2].yaw)
		player:set_look_vertical(dest[2].pitch)
		return true, "You are at \"" .. target .. "\""
	end,
})

minetest.register_chatcommand("delgo", {
	params = "<bookmark_name>",
	description = "Delete a /go destination",
	privs = {server=true},
	func = function(_, param)
		if not bookmarks.locations[param] then
			return false, "Destination not found: " .. param
		end
		bookmarks.locations[param] = nil
		bookmarks.save_bookmarks()
		return true, "/go "..param.." removed"
	end,
})

local listgo_entry_form = minetest.colorize("#BAEDEF", "/go %s") .. " at %s"
minetest.register_chatcommand("listgo", {
	description = "List all bookmarked destinations",
	func = function()
		if not next(bookmarks.locations) then
			return false, "Currently there are no destinations bookmarked"
		end
		local info = {}
		for go, coords in pairs(bookmarks.locations) do
			info[#info+1] = listgo_entry_form:format(go,
				minetest.pos_to_string(vector.round(coords[1])))
		end
		table.sort(info)
		return true, table.concat(info, "\n")
	end,
})

