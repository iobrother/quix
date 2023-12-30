local skynet = require "skynet"
require "skynet.manager"
local log = require "log"
local errors = require "common.errors"

local CMD = {}

local rooms = {}
local user_room = {}

function CMD.create(uid, req)
    local rsp = {
    }
    return rsp
end

function CMD.join(uid, req)
end

function CMD.quit(uid, req)
    local room_id = user_room[uid]
    if not room_id then
        return
    end
    user_room[uid] = nil
    rooms[room_id] = nil
end

skynet.start(function ()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)

    skynet.register("." .. SERVICE_NAME)
end)
