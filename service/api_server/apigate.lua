local require = require

local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local log = require "log"

local CMD = {}

function CMD.start(conf)
    local agent = {}
    for i = 1, 8 do
        agent[i] = skynet.newservice("api")
    end

    local balance = 1
    local id = socket.listen("0.0.0.0", conf.port)
    log.info("Listen api port:", conf.port)
    socket.start(id , function(fd, addr)
        skynet.send(agent[balance], "lua", "forward", fd)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end

skynet.start(function ()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)

    skynet.register("." .. SERVICE_NAME)
end)
