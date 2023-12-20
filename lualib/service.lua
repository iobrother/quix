local string = string
local skynet = require "skynet"

local service = {
	client = {},	-- 客户端消息
	cmd = {},		-- 节点内消息
	cluster = {},	-- 集群内消息
	method = {},	-- 服务内调用 函数列表（服务内一个模块调用了另一个模块中定义的函数）
}

function service.init(mod)
	if mod.info then
		skynet.info_func(function ()
			return mod.info
		end)
	end
	skynet.start(function ()
		if mod.init then
			mod.init()
		end
		skynet.dispatch("lua", function (_, _, cmd, ...)
			local f = service.cmd[cmd]
			if f then
				skynet.retpack(f(...))
			else
				skynet.error(string.format("Unknown command : [%s]", cmd))
				skynet.response()(false)
			end
		end)
	end)
end

return service
