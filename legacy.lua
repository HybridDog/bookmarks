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
				bookmarks.locations[goname] = {
					p,
					{yaw = tonumber(dir.yaw), pitch = tonumber(dir.pitch)}
				}
			end
		end
	end
	bookmarks.save_bookmarks()
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
				bookmarks.locations[k] = v
			end
		end
	end
	bookmarks.save_bookmarks()
	assert(secure_env.os.rename(file_path, worldpath .. "/old_bookmarks_v2"))
end

local secure_env = minetest.request_insecure_environment()
if not secure_env then
	minetest.log("error",
		"bookmarks legacy code requires a trusted environment")
else
	load_v1_bookmarks(secure_env)
	load_v2_bookmarks(secure_env)
end
