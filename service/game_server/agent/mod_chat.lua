local skynet = require "skynet"
local service = require "service"

local util = require "util.util"
local snowflake = require "snowflake"
local constant = require "common.constant"

function service.client.chat_SendReq(uid, req)
    local now = math.floor(skynet.time()*1000)
    local id = snowflake.next()
    local msg = {
        id = id,
        type = req.msg_type,
        channel_type = req.channel_type,
        from = uid,
        to = req.to,
        from_name = "", -- TODO
        from_avatar = "",
        content = req.content,
        send_time = now,
        read_time = 0,
        flag = 0,
        language = 0,
        extend = "",
        client_uuid = req.client_uuid,
    }

    if req.channel_type == constant.ChannelType.eCT_LEAGUE then
        -- 调用联盟模块的broadcast方法, 因为联盟成员由联明模块维护
    elseif req.channel_type == constant.ChannelType.eCT_GROUP then
        -- TODO 遍历群成员, 发送
    elseif req.channel_type == constant.ChannelType.eCT_PRIVATE then
        util.call("im", ".chat", "send", uid, msg)
        util.call("im", ".chat", "send", req.to, msg)
    elseif req.channel_type == constant.ChannelType.eCT_GLOBAL then
        util.call("im", ".chat", "send", 0, msg)
    end

    local rsp = {
        id = id,
        send_time = now,
        client_uuid = req.client_uuid,
    }

    return rsp
end

function service.client.chat_SyncMsgReq(uid, req)
    local msgs = util.call("im", ".chat", "sync", uid, req)
    local rsp = {
        list = msgs
    }

    return rsp
end

function service.client.chat_MsgAckReq(uid, req)
    util.call("im", ".chat", "ack", uid, req.id)
    local rsp = {}
    return rsp
end

function service.client.chat_DeleteMsgReq(uid, req)
    util.call("im", ".chat", "delete_msg", uid, req)
    local rsp = {}
    return rsp
end

local M = {}

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
