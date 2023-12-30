local require = require
local tonumber = tonumber

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function ()
	skynet.uniqueservice("chat")

    cluster.open(NODE_NAME)
    skynet.exit()
end)
