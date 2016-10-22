
-- ***********************************************************************************
--		go										**************************************************
-- ***********************************************************************************

local load_time_start = minetest.get_us_time()


local worldpath = minetest.get_worldpath()
local file_path = worldpath.."/bookmarks_v2"

local pos_to_string = vector.pos_to_string or minetest.pos_to_string

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
			vector.apply(np, function(za)
				return math.floor(za * 10 + 0.5) / 10
			end),
			{
				yaw = math.floor(target:get_look_horizontal() * 100 + .5) / 100,
				pitch = math.floor(target:get_look_vertical() * 100 + .5) / 100
			}
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
		local player = minetest.get_player_by_name(name)
		player:moveto(dest[1])
		player:set_look_horizontal(dest[2].yaw)
		player:set_look_vertical(dest[2].pitch)
		return true, "you're at "..target
	end,
})

minetest.register_chatcommand("delgo", {
	params = "<name>",
	description = "delete /go destination",
	privs = {server=true},
	func = function(name, param)
		if not GONETWORK[param] then
			return false, "destination not found: " .. param
		end
		GONETWORK[param] = nil
		write_gofile()
		return true, "/go "..param.." removed"
	end,
})

minetest.register_chatcommand("listgo", {
	params = "<goname>",
	description = "list all go destinations",
	func = function(name)
		if not next(GONETWORK) then
			return false, "currently there are no destinations in GONETWORK"
		end
		local info,i = {},1
		for go, coords in pairs(GONETWORK) do
			info[i] = "/go "..go.. " at "..pos_to_string(coords[1])
			i = i+1
		end
		table.sort(info)
		return true, table.concat(info, "\n")
	end,
})


-- [[ legacy

local oldpath = worldpath.."/bookmarks.go"
local gonfile = io.open(oldpath, "r")
if gonfile then
	local contents = gonfile:read"*all"
	io.close(gonfile)
	if contents then
		local lines = contents:split"]\n"
		for i = 1,#lines do
			local entry = lines[i]
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
				GONETWORK[goname] = {
					p,
					{yaw = tonumber(dir.yaw), pitch = tonumber(dir.pitch)}
				}
			end
		end
	end
	write_gofile()
	os.remove(oldpath)
end

--]]


local time = (minetest.get_us_time() - load_time_start) / 1000000
local msg = "[bookmarks] loaded after ca. " .. time .. " seconds."
if time > 0.01 then
	print(msg)
else
	minetest.log("info", msg)
end
