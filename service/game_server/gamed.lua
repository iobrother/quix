local require = require
local tonumber = tonumber

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function ()
    local gate = skynet.uniqueservice "wsgate"
    skynet.call(gate, "lua", "start", {
        port = tonumber(skynet.getenv("port")) or 2188,
		maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
    })

    cluster.open(NODE_NAME)
    skynet.exit()
end)
