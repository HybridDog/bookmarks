
-- ***********************************************************************************
--		go										**************************************************
-- ***********************************************************************************

local function rnd(za)
	return math.floor(za*10+0.5)/10
end

local write_gofile = function()
	local output = ''						--	WRITE CHANGES TO FILE
	for name, coords in pairs(GONETWORK) do
		local pos = coords[1]
		local dir = coords[2]
		output = output..name..'('..pos.x..'|'..pos.y..'|'..pos.z..')['..dir.yaw..", "..dir.pitch..']\n'
	end
	local f = io.open(minetest.get_worldpath()..'/bookmarks.go', "w")
	f:write(output)
	io.close(f)
end


GONETWORK = {}
local gonfile = io.open(minetest.get_worldpath()..'/bookmarks.go', "r")
if gonfile then
	local contents = gonfile:read('*all')
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
end
minetest.register_chatcommand("setgo", {
	params = "<name>",
	description = "set /go destination",
	privs = {server=true},
	func = function(name, param)
		local target = minetest.get_player_by_name(name)
		if target then
			local np = target:getpos()
			local tab = {
				{x=rnd(np.x), y=rnd(np.y), z=rnd(np.z)},
				{yaw=rnd(target:get_look_yaw()), pitch=rnd(target:get_look_pitch())}
			}
			GONETWORK[param] = tab
			write_gofile()
			minetest.chat_send_player(name, "/go "..param.." set")
		end
	end,
})
minetest.register_chatcommand("go", {
	params = "<goname>",
	description = "go to destination",
	func = function(name, param)
		local dest = GONETWORK[param]
		if dest == nil then
			minetest.chat_send_player(name, "no such destination")
			return
		end
		minetest.get_player_by_name(name):moveto(dest[1])
		print(dest[2].yaw)
		--teleportee:set_look_yaw(dest[2].yaw)
		--teleportee:set_look_pitch(dest[2].pitch)
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
			minetest.chat_send_player(name, "/go "..param.." removed")
		end
	end,
})
minetest.register_chatcommand("listgo", {
	params = "<goname>",
	description = "list all go destinations",
	func = function(name)
		local info = ""
		for go, coords in pairs(GONETWORK) do
			local pos = coords[1]
			info = info.."/go "..go.. ' at ('..pos.x..' | '..pos.y..' | '..pos.z..')\n'
		end
		if info == "" then
			info = 'currently there are no destinations in GONETWORK'
		end
		minetest.chat_send_player(name, info)
	end,
})
