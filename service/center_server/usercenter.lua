local skynet = require "skynet"
require "skynet.manager"

local CMD = {}

function CMD.login(uid)

end

function CMD.logout(uid)

end

skynet.start(function ()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)

    skynet.register("." .. SERVICE_NAME)
end)