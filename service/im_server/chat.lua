local skynet = require "skynet"
require "skynet.manager"
local mutex = require "skynet.queue"

local circularbuffer = require "circularbuffer"
local constant = require "common.constant"
local util = require "util.util"
local cjson = require "cjson"

local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true
pc:loadfile("proto.proto")
pc:loadfile("chat.proto")

local MSG_KEEP_DAYS = 30
local process_co

local function get_msg_key(uid, id)
    return string.format("im:msg:%d:%d", uid, id)
end

local function get_msg_sync_key(uid)
    return string.format("im:msg_sync:%d", uid)
end

local function store_msg(uid, msg)
    local key = get_msg_sync_key(uid)
    util.do_redis("zadd", key, msg.send_time, msg.id)
    util.do_redis("expire", key, MSG_KEEP_DAYS*24*3600)
    key = get_msg_key(uid, msg.id)
    util.do_redis("setex", key, MSG_KEEP_DAYS*24*3600, cjson.encode(msg))
end

-- 这是一个简化版的IM服务器, 不保证消息必达, 主要是为了满足游戏内的聊天需求
-- 用循环队列实现, 超出循环队列容量, 会顶掉最老的还未处理的消息, 以保证服务器不爆掉
-- 由于游戏中聊天记录不是很重要, 因此聊天仅存在redis中, 不落地到MYSQL数据库
local CMD = {}

local QUEUE_SIZE = 100000

-- 虽然skynet是单线程的, 但是由消息处理的过程中需要访问IO, 会让出协程
-- 这样有可能接收消息协程就有可能被调度到, 所以queue需要加锁
local queue
local cs = mutex()

local function process_notice_msg(uid, msg)
    -- 公告消息不需要入库
    util.call("game", ".wsgate", "broadcast", msg)
end

local function process_global_msg(uid, msg)
    store_msg(uid, msg)

    local m = {
        seq = 0,
        cmd = "chat.Msg",
        payload = nil
    }
    local payload = assert(pb.encode("chat.Msg", msg))
    m.payload = payload
    local data = assert(pb.encode("proto.Msg", m))
    util.call("game", ".wsgate", "broadcast", data)
end

-- 单聊或群聊
local function process_chat_msg(uid, msg)
    store_msg(uid, msg)

    local m = {
        seq = 0,
        cmd = "chat.Msg",
        payload = nil
    }
    local payload = assert(pb.encode("chat.Msg", msg))
    m.payload = payload
    local data = assert(pb.encode("proto.Msg", m))
    util.call("game", ".wsgate", "push", uid, data)
end

local function process_msg(uid, msg)
    if msg.channel_type == constant.ChannelType.eCT_NOTICE then
        process_notice_msg(uid, msg)
    elseif msg.channel_type == constant.ChannelType.eCT_GLOBAL then
        process_global_msg(uid, msg)
    elseif msg.channel_type == constant.ChannelType.eCT_PRIVATE or msg.channel_type == constant.ChannelType.eCT_GROUP then
        process_chat_msg(uid, msg)
    end
end

local function process()
    while true do
        local msg
        cs(function ()
            msg = queue:pop_front()
        end)
        if msg then
            local ok, err = util.pcall(process_msg, msg.uid, msg.msg)
            if not ok then
                LOG("Error while processing message:", err)
            end
        else
            skynet.wait()
        end
    end
end

local function remove_dirty(uid, req)
    local now = os.time()
    local exipre_time = now - MSG_KEEP_DAYS*86400
    local key = get_msg_sync_key(uid)
    -- 删除过期id
    util.do_redis("zremrangebyscore",  key, "-inf", tostring(exipre_time))

    while true do
        local result = util.do_redis("zrangebyscore", key, "(" .. tostring(req.offset), "+inf", "limit", 0, 1000)
        local keys = {}
        for _, v in ipairs(result) do
            key = get_msg_key(uid, tonumber(v))
            keys[#keys+1] = key
        end

        if #keys == 0 then break end

        -- 同步库中存在，而消息库中却不存在
		-- 发生这种情况是因为，消息库中的消息过期已从redis中清除了，但是同步库中的消息id还未即时跑批处理清理掉(这种情况在删除过期id中已处理)
        -- 人为手工删除了消息库, 但是同步库中还保留其id
        local dirty_members = {}
        local msgs = util.do_redis("mget",  table.unpack(keys))
        for k, v in pairs(result) do
            if not msgs[k] then
                dirty_members[#dirty_members+1] = tonumber(v)
            end
        end
        if #dirty_members == 0 then break end
        key = get_msg_sync_key(uid)
        util.do_redis("zrem", key, table.unpack(dirty_members))
    end

end

function CMD.send(uid, msg)
    local m = {
        uid = uid,
        msg = msg,
    }
    cs(function ()
        queue:push_back(m)
        skynet.wakeup(process_co)
    end)
end

function CMD.sync(uid, req)
    local msgs = {}
    remove_dirty(uid, req)
    if req.limit <= 0 then
        req.limit = 20
    end
    if req.limit > 100 then
        req.limit = 100
    end

    local key = get_msg_sync_key(uid)
    local result = util.do_redis("zrangebyscore", key, "(" .. tostring(req.offset), "+inf", "limit", 0, req.limit)
    local keys = {}
    for _, v in ipairs(result) do
        key = get_msg_key(uid, tonumber(v))
        keys[#keys+1] = key
    end

    if #keys == 0 then
        return msgs
    end
    result = util.do_redis("mget",  table.unpack(keys))
    -- 注意这里不能用ipair
    for _, v in pairs(result) do
        if v then
            local msg = cjson.decode(v)
            msgs[#msgs+1] = msg
        end
    end
    return msgs
end

function CMD.ack(uid, id)
    -- 用于删除消息
    local key = get_msg_key(uid, id)
    local data = util.do_redis("get", key, key)
    local msg = cjson.decode(data)
    util.do_redis("zremrangebyscore",  key, "-inf", tostring(msg.send_time))
end

function CMD.delete_msg(uid, req)
    if not req.ids or #req.ids == 0 then
        return
    end
    local key = get_msg_sync_key(uid)
    util.do_redis("zrem", key, table.unpack(req.ids))
end

skynet.start(function()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd .. " not found")
        skynet.retpack(f(...))
    end)

    queue = circularbuffer.new(QUEUE_SIZE)

    process_co = skynet.fork(process)

    skynet.register("." .. SERVICE_NAME)
end)