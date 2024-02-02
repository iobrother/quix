local require = require
local pairs = pairs
local assert = assert
local pcall = pcall
local string = string

local service = require "service"
local skynet = require "skynet"
local errors = require "common.errors"
local log = require "log"
local timer = require "timer"
local lfs = require "lfs"
local util = require "util.util"
local tableutil = require "util.table"
local constant = require "common.constant"

-- 玩家代理服务，一个在线玩家，对就一个agent服务
-- 某些游戏类型，所有玩家共用一个agent服务更合理

-- 加载 proto
local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true

for file in lfs.dir("./proto") do
    if file:match("%.proto$") then
        pc:loadfile(file)
    end
end

pc:loadfile("db/login_log.proto")

local UID
local FD
local DEVICE_ID

local last_active_time = 0

local ai_timer_id
local backup_timer_id
local heartbeat_timer_id

local heartbeat_check_flag = false

-- 加载模块
local MOD = {}
service.MOD = MOD
for file in lfs.dir("./service/game_server/agent") do
    local mod_name = file:match("^mod_(.+)%..+$")
    if mod_name then
        MOD[mod_name] = require("mod_" .. mod_name)
        MOD[mod_name].onInit()
    end
end

local function logout()
	skynet.call(".wsgate", "lua", "logout", UID)

    -- 注意不能关闭定时器, 因为logout之后, 这个agent对象并不销毁, 而是放到缓存中，待玩家重新上线后直接复用
    -- 缓存中的离线玩家数据, 有可能被其他玩家访问修改, 因此定时器不能销毁
    -- timer:cancel(ai_timer_id)
    -- timer:cancel(backup_timer_id)

    service.method.onPlayerOffline()
    service.method.onBackup()
    heartbeat_check_flag = false
	--这里不退出agent服务，以便agent能复用
	--skynet.exit()
end

local function kick(reason)
    skynet.call(".wsgate", "lua", "kick", UID, reason)
    service.method.onPlayerOffline()
    service.method.onBackup()
    heartbeat_check_flag = false
end

-- 处理心跳
local function heartbeat()
    -- 一次性定时器
    heartbeat_timer_id = timer:add(skynet.now()+constant.HEARTBEAT_INTERVAL*100, 0, function ()
        -- 收到客户端心跳后，延迟一倍心跳间隔回心跳包给客户端
        local payload = assert(pb.encode("proto.Noop", {}))
        local msg = assert(pb.encode("proto.Msg", {
            seq = 0,
            cmd = "proto.Noop",
            payload = payload,
        }))
        skynet.send(".wsgate", "lua", "push", UID, msg)
    end)
end

local function msg_unpack(msg, sz)
    local data = skynet.tostring(msg, sz)
    local m = assert(pb.decode("proto.Msg", data))
    return m
end

-- local function msg_pack(msg)
--     local data = assert(pb.encode("proto.Msg", msg))
--     return data
-- end

local function msg_dispatch(msg)
    local begin = skynet.time()
    local cmd = msg.cmd
    LOGF("calling to %s", cmd)
    local module, method = msg.cmd:match "([^.]*).(.*)"
    LOG(module, method)

    last_active_time = os.time()
    -- 收到的是心跳包
    if module == "proto" and method == "Noop" then
        heartbeat()
        return
    end

    if module == "login" and method == "LoginReq" then
        assert(false, "玩家已登录, 不要复复登录")
        return
    end

    local req = assert(pb.decode(msg.cmd, msg.payload))
    LOG("req =", req)
    local ok, rsp, err = util.pcall(service.client[module .. "_" .. method], UID, req)

    if not ok then
        local payload = assert(pb.encode("proto.Error", errors.SYSTEM))
        msg = assert(pb.encode("proto.Msg", {
            seq = msg.seq,
            cmd = "proto.Error",
            payload = payload
        }))
        skynet.send(".wsgate", "lua", "push", UID, msg)
    else
        if rsp then
            cmd = string.sub(msg.cmd, 1, -4) .. "Rsp"
            local payload = assert(pb.encode(cmd, rsp))
            msg = assert(pb.encode("proto.Msg", {
                seq = msg.seq,
                cmd = cmd,
                payload = payload
            }))
            skynet.send(".wsgate", "lua", "push", UID, msg)
        else
            local payload = assert(pb.encode("proto.Error", err))
            msg = assert(pb.encode("proto.Msg", {
                seq = msg.seq,
                cmd = "proto.Error",
                payload = payload
            }))
            skynet.send(".wsgate", "lua", "push", UID, msg)
        end
    end

	LOGF("process %s time used %f ms", cmd, (skynet.time()-begin)*10)
end

-- 加载玩家数据
function service.cmd.load(uid)
    UID = uid
    local sql = string.format("call sp_init_player(%d)", uid)
    local result = util.call("db", ".dbproxy", "execute", uid, sql)
    local is_new = result[1][1].is_new
    service.method.onLoad()
    -- 新用户初始化数据
    if is_new == 1 then
        -- 这里不需要推送消息
        service.method.change_coin(1000000, constant.COIN_OPERATION_TYPE.WELCOME, {remark="新用户首次登录"}, true)
    end

    timer:start()
    ai_timer_id = timer:add(skynet.now()+100, 100, service.method.onRun)
    backup_timer_id = timer:add(skynet.now()+100*60*2, 100*60*2, service.method.onBackup)

    service.method.onActivate()
end

-- call by gate
function service.cmd.login(uid, fd, device_id)
    heartbeat_check_flag = true
    last_active_time = os.time()
    UID = uid
    FD = fd
    DEVICE_ID = device_id
end

function service.cmd.online()
    -- 这个逻辑不能放到 service.cmd.login, 因为service.method.onPlayerOnline()内部会同步消息给客户端
    -- 同步消息给客户端要在wsgate里面找到player对象, 而player对象是在service.cmd.login成功之后才加入wsgate的players表里的
    -- 所以service.method.onPlayerOnline()一定要在service.cmd.login返回给wsgate并把player对象加入players之后再执行
    -- 如果直接通过FD来同步消息给客户端,可以不必有这个限制,而一般在模块中发消息给客户端是通过uid来索引的
    service.method.onPlayerOnline()
end

function service.cmd.afk()
	-- the connection is broken, but the user may back
    if heartbeat_timer_id then
        timer:cancel(heartbeat_timer_id)
        heartbeat_timer_id = nil
    end
	LOG("AFK")
    service.method.onPlayerOffline()
    service.method.onBackup()

    -- 登录时长记录
    if not DEVICE_ID then
        DEVICE_ID = ""
    end
    local where_clause = string.format("uid=%d and device_id='%s' and logout_time=0 ORDER BY login_time DESC LIMIT 1", UID, DEVICE_ID)
    local result = util.call("db", ".dbproxy", "query", UID, "login_log", {}, where_clause)

    if not tableutil.empty(result) then
        -- 记录在线时长
        result[1].logout_time = os.time()
        result[1].duration = result[1].logout_time -result[1].login_time
        local msg = pb.encode("db.login_log", result[1])
        util.call("db", ".dbproxy", "update", UID, "login_log", "db.login_log", msg)
    end

end

function service.cmd.logout()
    LOGF("user %d is logout", UID)
	logout()
end

function service.cmd.kick(reason)
    LOGF("user %d is kicked", UID, reason)
    kick(reason)
end

function service.cmd.exit()
    LOG("agent exit ....")
    timer:stop()
    service.method.onBackup()
    service.method.onRelease()
    skynet.exit()
end

function service.method.onRelease()
    for _, m in pairs(MOD) do
        if m.onRelease then
            m.onRelease()
        end
    end
end

-- 每秒1帧
function service.method.onRun()
    if heartbeat_check_flag then
        local now = os.time()
        local duration = now - last_active_time
        if duration >= 2*constant.HEARTBEAT_INTERVAL then
            logout()
        end
    end

    for _, m in pairs(MOD) do
        if m.onRun then
            m.onRun()
        end
    end
end

function service.method.onLoad()
    for _, m in pairs(MOD) do
        m.uid = UID
        if m.onLoad then
            m.onLoad()
        end
    end
end

function service.method.onActivate()
    for _, m in pairs(MOD) do
        if m.onActivate then
            m.onActivate()
        end
    end
end

function service.method.onPlayerOnline()
    LOG("player online")
    for _, m in pairs(MOD) do
        if m.onPlayerOnline then
            m.onPlayerOnline()
        end
    end
end

function service.method.onPlayerOffline()
    LOG("player offline")
    for _, m in pairs(MOD) do
        if m.onPlayerOffline then
            m.onPlayerOffline()
        end
    end
end

-- 定期备份数据到数据库
function service.method.onBackup()
    for _, m in pairs(MOD) do
        if m.onBackup then
            m.onBackup()
        end
    end
end

function service.method.onTimeEvent(ct)
    for _, m in pairs(MOD) do
        if m.onTimeEvent then
            m.onTimeEvent(ct)
        end
    end
end

service.init {
    init = function ()
        skynet.register_protocol {
            name =  "client",
            id = skynet.PTYPE_CLIENT,
            unpack = function (msg, sz)
                return msg_unpack(msg, sz)
            end,

            dispatch = function (fd, source, msg)
                skynet.ignoreret()
                msg_dispatch(msg)
            end
        }
    end
}