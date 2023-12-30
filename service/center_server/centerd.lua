local require = require
local tonumber = tonumber

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function ()
	skynet.uniqueservice("usercenter")
	skynet.uniqueservice("roommgr")
    -- skynet.uniqueservice("config")

    cluster.open(NODE_NAME)
    skynet.exit()
end)
