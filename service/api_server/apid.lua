local require = require
local tonumber = tonumber

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function ()
	local apigate = skynet.uniqueservice "apigate"
	skynet.call(apigate, "lua", "start", {
		port = tonumber(skynet.getenv("api_port") or 2080),
	})

	cluster.open(NODE_NAME)
    skynet.exit()
end)
