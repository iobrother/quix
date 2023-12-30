local require = require
local tonumber = tonumber

local skynet = require "skynet"

-- 以单进程模式运行所有服务
skynet.start(function ()
	skynet.newservice("debug_console", tonumber(skynet.getenv("debug_port")))

	-- 中心服务器相关服务
	skynet.uniqueservice("usercenter")
	skynet.uniqueservice("roommgr")
	-- skynet.uniqueservice("config")

	-- 数据库服务器相关服务
	skynet.uniqueservice("mysqlpool")
	skynet.uniqueservice("redispool")
	skynet.uniqueservice("dbproxy")

	-- 场景服务器(这里是棋牌类子游戏服务器)相关服务
	skynet.uniqueservice("gameroom")

	skynet.uniqueservice("chat")
	-- API服务器相关服务
	local apigate = skynet.uniqueservice "apigate"
	skynet.call(apigate, "lua", "start", {
		port = tonumber(skynet.getenv("api_port") or 3180),
	})

	-- 游戏服务器相关服务
    local gate = skynet.uniqueservice "wsgate"
    skynet.call(gate, "lua", "start", {
        port = tonumber(skynet.getenv("ws_port")) or 2188,
		maxclient = tonumber(skynet.getenv("maxclient")) or 1024,
    })

    skynet.exit()
end)
