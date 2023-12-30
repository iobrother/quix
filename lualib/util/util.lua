local skynet = require "skynet"
local cluster = require "skynet.cluster"
local log = require "log"
local snowflake = require "snowflake"
local constant = require "common.constant"

local M = {}

function M.do_redis(...)
    if not NODE_NAME then
        -- 单节点部署
        return skynet.call(".redispool", "lua", "execute", ...)
    else
        -- 多节点部署
        return cluster.call("db", ".redispool", "execute", ...)
    end
end

function M.call(node, addr, cmd, ...)
    if not NODE_NAME then
        -- 单节点部署
        return skynet.call(addr, "lua", cmd, ...)
    else
        -- 多节点部署
        return cluster.call(node, addr, cmd, ...)
    end
end

function M.pcall(f, ...)
    return xpcall(f, debug.traceback, ...)
end

-- 发送全服公告
function M.send_announdement(content)
    local msg = {
        id = snowflake.next,
        type = constant.MsgType.eMT_TEXT,
        channel_type = constant.ChannelType.eCT_NOTICE,
        from = 0,
        to = 0,
        from_name = "", -- TODO
        from_avatar = "",
        content = content,
        send_time = os.time(),
        read_time = 0,
        flag = 0,
        language = 0,
        extend = "",
    }
    M.call("im", ".chat", "send", 0, msg)
end

return M
