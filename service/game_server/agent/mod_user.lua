local require = require
local tostring = tostring
local table = table

local skynet = require "skynet"
local service = require "service"
local log = require "log"
local util = require "util.util"
local tableutil = require "util.table"
local snowflake = require "snowflake"
local constant = require "common.constant"

-- 加载 proto
local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true
pc:loadfile("db/player.proto")
pc:loadfile("db/coin_log.proto")
pc:loadfile("user.proto")

local M = {
    uid = 0,
    player = {},
}


-- 客户端消息
-- function service.client.user_InfoReq(uid, req)
--     local rsp = {
--         name = "test name"
--     }

--     -- 如果出现业务, 请返回错误
--     -- return nil, errors.XXXX
--     -- 错误码定义在lualib/errors/errors.lua中
--     return rsp
-- end

-- 节点内消息
function service.cmd.change_attribute(attr_type, attr_value, action, extra, nopush)
    return service.method.change_attribute(attr_type, attr_value, action, extra, nopush)
end

-- data是一个属性编号与值map
function service.cmd.inc_attribute(data, action, extra, nopush)
    if #data then
        return true
    end

    for k, v in pairs(data) do
        service.method.change_attribute(k, v, action, extra, nopush)
    end
end

-- data是一个属性编号与值map
function service.cmd.dec_attribute(data, action, extra, nopush)
    if #data then
        return true
    end

    for k, v in pairs(data) do
        service.method.change_attribute(k, -v, action, extra, nopush)
    end
end

function service.cmd.get_attribute(attr_type)
    local f = service.method.get_function[attr_type]
    return f()
end

function service.cmd.check_attribute(attr_type, attr_value)
    local f = service.method.check_function[attr_type]
    return f(attr_value)
end

-- data是一个属性编号与值map
function service.cmd.check_enough(data)
    if #data then
        return true
    end

    for k, v in pairs(data) do
        if not service.cmd.check_attribute(k, v) then
            return false
        end
    end

    return true
end

function service.method.change_attribute(attr_type, attr_value, action, extra, nopush)
    -- TODO: 根据attr_type获取相应的函数
    local f = service.method.change_function[attr_type]
    return f(attr_value, action, extra, nopush)
end

-- TODO: 属性相关代码, 可以用工具来生成
-- BEGIN 玩家属性相关代码
function service.method.change_coin(attr_value, action, extra, nopush)
    if attr_value == 0 then
        return
    end
    if not M.player.coin then
        M.player.coin = 0
    end

    local before_coin = M.player.coin
    M.player.coin = M.player.coin + attr_value
    if M.player.coin < 0 then
        log.warnf("%d %d %d", M.uid, attr_value, M.player.coin)
        M.player.coin = 0
    end

    local game_id = extra and extra.game_id or 0
    local remark = extra and extra.remark or ""

    local row = {
        id = snowflake.next(),
        uid = M.uid,
        type = action,
        before_coin = before_coin,
        after_coin = M.player.coin,
        amount = attr_value,
        game_id = game_id,
        created_at = os.time(),
        remark = remark,
    }

    LOG(row)
    if not nopush then
        local data = {attr_type=1, attr_value=M.player.coin}
        local payload = pb.encode("user.AttrNty", data)
        local nty = {
            seq = 0,
            cmd = "user.AttrNty",
            payload = payload
        }
        local msg = pb.encode("proto.Msg", nty)
        skynet.send(".wsgate", "lua", "push", M.uid, msg)
    end

    local msg = pb.encode("db.coin_log", row)
    util.call("db", ".dbproxy", "insert", M.uid, "coin_log", "db.coin_log", msg)
end

function service.method.check_coin(attr_value)
    if attr_value < 0 then
        log.warnf("%d %d", M.uid, attr_value)
        return false
    end

    if not M.player.coin then
        M.player.coin = 0
    end

    return M.player.coin - attr_value >= 0
end

function service.method.get_coin()
    if not M.player.coin then
        M.player.coin = 0
    end
    return M.player.coin
end


service.method.change_function = {
    [constant.ATTRIBUTE_TYPE.COIN] = service.method.change_coin
}

service.method.get_function = {
    [constant.ATTRIBUTE_TYPE.COIN] = service.method.get_coin
}

service.method.check_function = {
    [constant.ATTRIBUTE_TYPE.COIN] = service.method.check_coin
}
-- END 玩家属性相关代码

function service.method.get_user_info()
    return M.player
end

local function syncUserInfo()
    local user_info = {
        uid = M.player.uid,
        name = M.player.name,
        coin = M.player.coin
    }
    local payload = pb.encode("user.UserInfoNty", user_info)
    local nty = {
        seq = 0,        -- 推送的消息seq都填0
        cmd = "user.UserInfoNty",
        payload = payload
    }
    local msg = pb.encode("proto.Msg", nty)
    skynet.send(".wsgate", "lua", "push", M.uid, msg)
end

-- 模块
function M.onInit()

end

function M.onRelease()

end

function M.onRun()

end

function M.onBackup()
    local player = tableutil.copy(M.player)
    player.coin = M.player.coin
    player.cash_bonus = M.player.cash_bonus
    player.cash_balance = M.player.cash_balance
    player.withdrawable_balance = M.player.withdrawable_balance

    local data = pb.encode("db.player", player)
    util.call("db", ".dbproxy", "set", M.uid, "player", "db.player", data)
end

function M.onLoad()
    M.player = util.call("db", ".dbproxy", "load", M.uid, "player")
    assert(not tableutil.empty(M.player))
end

-- 玩家所有数据已加载完毕后触发, 在该函数中可以处理离线逻辑
function M.onActivate()

end

function M.onPlayerOnline()
    syncUserInfo()
end

function M.onPlayerOffline()

end

function M.onTimeEvent(ct)

end

return M