local require = require
local tostring = tostring
local table = table

local service = require "service"
local log = require "log"
local util = require "util.util"

local M = {
    -- cur_room = 0
}

-- 客户端消息

-- 这里不直接调用游戏服务器的对应的方法，是为了将来改成分布式部署考虑
-- 中心服务器维护了各个服务器节点的地址，以及各个房间所属的服务器

function service.client.room_MatchReq(uid, req)
    -- TODO
    -- 读取配置文件，判定是否绑定手机号绑定kyc才允许进入游戏
    -- 判断用户是否绑定手机号，是否绑定kyc
    -- local user = service.method.get_user_info()

    local rsp = util.call("center", ".roommgr",  "match", uid, req)
    -- M.cur_room = rsp and rsp.id or 0
    return rsp
end

function service.client.room_CreateReq(uid, req)
    return util.call("center", ".roommgr", "create", uid, req)
end

function service.client.room_JoinReq(uid, req)
    return util.call("center", ".roommgr", "join", uid, req)
end

function service.client.room_QuitReq(uid, req)
    return util.call("center", ".roommgr", "quit", uid, req)
end

function service.client.room_SpinReq(uid, req)
    -- 根据room_id到中心服务器获取房间所在的游戏服务器，然后调用服务器对应的spin方法
    -- 目前中心服务器还没维护各服务器地址信息以及房间信息，所以这里先直接调用游戏服务器的spin方法
    return util.call("scene", ".gameroom", "spin", uid, req)
end

-- 模块
function M.onInit()

end

function M.onRelease()

end

function M.onRun()

end

function M.onBackup()

end

function M.onLoad()

end

-- 玩家所有数据已加载完毕后触发, 在该函数中可以处理离线逻辑
function M.onActivate()

end

function M.onPlayerOnline()

end

function M.onPlayerOffline()

end

-- function M.onTimeEvent(ct)

-- end

return M
