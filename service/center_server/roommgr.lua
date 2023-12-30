local skynet = require "skynet"
require "skynet.manager"
local util = require "util.util"

local CMD = {}

function CMD.match(uid, req)
    -- 匹配房间，确定座位
    -- 如果牌类对战，需要匹配玩家或机器人，加入一个房间，匹配不到房间就创建一个新房间

    -- 这里先暂时直接调用游戏服务器的房间管理器，创建一个房间
    return util.call("scene", ".gameroom", "create", uid, req)
end

function CMD.create(uid, req)
    -- TODO: 根据游戏ID, 找到对应的游戏节点，调用游戏节点的创建房间方法
    return util.call("scene", ".gameroom", "create", uid, req)
end

function CMD.join(uid, req)
    -- 根据房间ID, 找到对应的游戏节点，调用游戏节点的加入房间方法
    return util.call("scene", ".gameroom", "join", uid, req)
end

function CMD.quit(uid, req)
    return util.call("scene", ".gameroom", "quit", uid, req)
end

skynet.start(function ()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)

    skynet.register("." .. SERVICE_NAME)
end)