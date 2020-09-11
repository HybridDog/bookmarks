
-- ***********************************************************************************
--		go										**************************************************
-- ***********************************************************************************


local storage = minetest.get_mod_storage()
local bookmarks

-- Load the bookmarked locations from the storage
bookmarks = minetest.deserialize(storage:get_string("bookmarks")) or {}

local function save_bookmarks()
	storage:set_string("bookmarks", minetest.serialize(bookmarks))
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
		bookmarks[param] = {
			vector.apply(np, function(za)
				return math.floor(za * 10 + 0.5) / 10
			end),
			{
				yaw = math.floor(player:get_look_horizontal() * 100 + .5) / 100,
				pitch = math.floor(player:get_look_vertical() * 100 + .5) / 100
			}
		}
		save_bookmarks()
		return true, "/go "..param.." set"
	end,
})

minetest.register_chatcommand("go", {
	params = "<bookmark_name>",
	description = "Go to a destination",
	func = function(name, target)
		if not next(bookmarks) then
			return false, "Currently there are no destinations bookmarked"
		end
		local dest = bookmarks[target]
		if not dest then
			return false, "Bookmark not found: \"" .. target .. "\""
		end
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Are you a player?"
		end
		player:moveto(dest[1])
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
		if not bookmarks[param] then
			return false, "Destination not found: " .. param
		end
		bookmarks[param] = nil
		save_bookmarks()
		return true, "/go "..param.." removed"
	end,
})

local listgo_entry_form = minetest.colorize("#BAEDEF", "/go %s") .. " at %s"
minetest.register_chatcommand("listgo", {
	description = "List all bookmarked destinations",
	func = function()
		if not next(bookmarks) then
			return false, "Currently there are no destinations bookmarked"
		end
		local info = {}
		for go, coords in pairs(bookmarks) do
			info[#info+1] = listgo_entry_form:format(go,
				minetest.pos_to_string(vector.round(coords[1])))
		end
		table.sort(info)
		return true, table.concat(info, "\n")
	end,
})


-- Legacy code for backwards-compatibility

local function load_v1_bookmarks(secure_env)
	local worldpath = minetest.get_worldpath()
	local oldpath = worldpath .. "/bookmarks.go"
	local old_gonfile = secure_env.io.open(oldpath, "r")
	if not old_gonfile then
		return
	end
	local contents = old_gonfile:read"*all"
	secure_env.io.close(old_gonfile)
	if contents then
		local lines = contents:split"]\n"
		for k = 1,#lines do
			local entry = lines[k]
			local i, d = unpack(entry:split")[")
			local goname, pos = unpack(i:split"(")
			local p = {}
			local dir = {}
			--p.x, p.y, p.z = string.match(coords, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
			p.x, p.y, p.z = unpack(pos:split"|")
			p = vector.apply(p, tonumber)
			dir.yaw, dir.pitch = unpack(d:split", ")
			if p.x and p.y and p.z
			and dir.yaw
			and dir.pitch then
				bookmarks[goname] = {
					p,
					{yaw = tonumber(dir.yaw), pitch = tonumber(dir.pitch)}
				}
			end
		end
	end
	save_bookmarks()
	assert(secure_env.os.rename(oldpath, worldpath .. "/old_bookmarks.go"))
end

local function load_v2_bookmarks(secure_env)
	local worldpath = minetest.get_worldpath()
	local file_path = worldpath .. "/bookmarks_v2"
	local gonfile = secure_env.io.open(file_path, "rb")
	if not gonfile then
		return
	end
	local contents = gonfile:read"*all"
	secure_env.io.close(gonfile)
	if contents
	and contents ~= "" then
		local v2_bookmarks = minetest.deserialize(minetest.decompress(contents))
		if type(v2_bookmarks) == "table" then
			for k, v in pairs(v2_bookmarks) do
				bookmarks[k] = v
			end
		end
	end
	save_bookmarks()
	assert(secure_env.os.rename(file_path, worldpath .. "/old_bookmarks_v2"))
end

if minetest.settings:get_bool("bookmarks.legacy", false) then
	local secure_env = minetest.request_insecure_environment()
	if not secure_env then
		minetest.log("error",
			"bookmarks legacy code requires a trusted environment")
	else
		load_v1_bookmarks(secure_env)
		load_v2_bookmarks(secure_env)
	end
end
