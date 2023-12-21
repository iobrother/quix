local require = require
local tonumber = tonumber

local skynet = require "skynet"
local cluster = require "skynet.cluster"

skynet.start(function ()
	skynet.uniqueservice("mysqlpool")
	skynet.uniqueservice("redispool")
	skynet.uniqueservice("dbproxy")

    cluster.open(NODE_NAME)
    skynet.exit()
end)
