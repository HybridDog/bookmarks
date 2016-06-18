
-- ***********************************************************************************
--		go										**************************************************
-- ***********************************************************************************

local worldpath = minetest.get_worldpath()
local file_path = worldpath.."/bookmarks_v2"

local pos_to_string = vector.pos_to_string or minetest.pos_to_string

local function rnd(za)
	return math.floor(za*10+0.5)/10
end

-- saves GONETWORK to file
local function write_gofile()
	local f = io.open(file_path, "w")
	f:write(minetest.compress(minetest.serialize(GONETWORK)))
	io.close(f)
end

-- load GONETWORK from file
local gonfile = io.open(file_path, "rb")
if gonfile then
	local contents = gonfile:read"*all"
	io.close(gonfile)
	if contents
	and contents ~= "" then
		GONETWORK = minetest.deserialize(minetest.decompress(contents))
	end
end

GONETWORK = rawget(_G, "GONETWORK") or {}

minetest.register_chatcommand("setgo", {
	params = "<name>",
	description = "set /go destination",
	privs = {server=true},
	func = function(name, param)
		local target = minetest.get_player_by_name(name)
		if not target then
			return false, "Are you a player?"
		end
		local np = target:getpos()
		GONETWORK[param] = {
			{x=rnd(np.x), y=rnd(np.y), z=rnd(np.z)},
			{yaw=rnd(target:get_look_yaw()), pitch=rnd(target:get_look_pitch())}
		}
		write_gofile()
		return true, "/go "..param.." set"
	end,
})

minetest.register_chatcommand("go", {
	params = "<goname>",
	description = "go to destination",
	func = function(name, target)
		local second_choice = next(GONETWORK)
		if not second_choice then
			return false, "currently there are no destinations in GONETWORK"
		end
		local dest = GONETWORK[target]
		if not dest then
			target = second_choice
			dest = GONETWORK[target]
		end
		minetest.get_player_by_name(name):moveto(dest[1])
		print(dest[2].yaw)
		--teleportee:set_look_yaw(dest[2].yaw)
		--teleportee:set_look_pitch(dest[2].pitch)
		return true, "you're at "..target
	end,
})

minetest.register_chatcommand("delgo", {
	params = "<name>",
	description = "delete /go destination",
	privs = {server=true},
	func = function(name, param)
		if GONETWORK[param] then
			GONETWORK[param] = nil
			write_gofile()
			return true, "/go "..param.." removed"
		end
		return false, "Something failed…"
	end,
})

minetest.register_chatcommand("listgo", {
	params = "<goname>",
	description = "list all go destinations",
	func = function(name)
		if not next(GONETWORK) then
			return false, "currently there are no destinations in GONETWORK"
		end
		local info = ""
		for go, coords in pairs(GONETWORK) do
			info = info.."/go "..go.. " at "..pos_to_string(coords[1]).."\n"
		end
		return true, info
	end,
})


-- [[ legacy

local oldpath = worldpath.."/bookmarks.go"
local gonfile = io.open(oldpath, "r")
if gonfile then
	local contents = gonfile:read"*all"
	io.close(gonfile)
	if contents then
		local lines = string.split(contents, "]\n")
		for _,entry in ipairs(lines) do
			local i, d = unpack(string.split(entry, ")["))
			local goname, pos = unpack(string.split(i, "("))
			local p = {}
			local dir = {}
			--p.x, p.y, p.z = string.match(coords, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
			p.x, p.y, p.z = unpack(string.split(pos, "|"))
			dir.yaw, dir.pitch = unpack(string.split(d, ", "))
			if p.x
			and p.y
			and p.z
			and dir.yaw
			and dir.pitch then
				GONETWORK[goname] = {
					{x = tonumber(p.x), y= tonumber(p.y), z = tonumber(p.z)},
					{yaw = tonumber(dir.yaw), pitch = tonumber(dir.pitch)}
				}
			end
		end
	end
	write_gofile()
	os.remove(oldpath)
end

--]]
