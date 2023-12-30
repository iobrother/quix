local require = require
local assert = assert
local tostring = tostring

local skynet = require "skynet"
local log = require "log"
local errors = require "common.errors"
local util = require "util.util"
local uuid = require "uuid"
local snowflake = require "snowflake"

-- 加载 proto
local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true
pc:loadfile("db/login_log.proto")

-- 正在登录中的用户
local loggin_in_user = {}

local CMD = {}

function CMD.login(req)
    assert(req.uid > 0, "错误的uid")
    if loggin_in_user[req.uid] then
        return nil, errors.PLAYER_LOGGING_IN
    end
    loggin_in_user[req.uid] = true
    LOG("req =", req)
    local token = util.do_redis("get", "LOGIN_TOKEN:" .. tostring(req.uid) .. ":" .. req.device_id)
    if not token or req.token ~= token then
        loggin_in_user[req.uid] = nil
        return nil, errors.AUTH_FAIL
    else
        local uid = req.uid
        -- TODO: 踢掉该帐号其它登录的终端
        -- 去中心服务器上查找玩家在哪个游戏服务器登录了，并调用该游戏服务器的gate服务的kick方法将其踢下线
        -- 这里简单地从本地服务器的gate服务获取在线玩家，并调用 gate 服务器的 kick方法
        local player = skynet.call(".wsgate", "lua", "get_online", uid)
        if player ~= nil then
            if player.device_id == req.device_id then
                loggin_in_user[req.uid] = nil
                return nil, errors.ALREADY_LOGGED
            end
            LOGF("玩家 %d 在另一处登录", uid)
            skynet.call(player.agent, "lua", "kick", "Player logged in elsewhere")
        end

        local rsp = {
            uid=uid,
            device_id=req.device_id,
        }

        local row = {
            id = snowflake.next(),
            uid = uid,
            type = req.type,
            platform = req.platform,
            app_version = req.app_version,
            res_version = req.res_version,
            device_id = req.device_id,
            device_name = req.device_name,
            device_model = req.device_model,
            login_time = os.time(),
            logout_time = 0,
            duration = 0,
        }
        local msg = pb.encode("db.login_log", row)
        local ok = util.pcall(util.call, "db", ".dbproxy", "insert", uid, "login_log", "db.login_log", msg)
        if not ok then
            loggin_in_user[req.uid] = nil
            return nil, errors.SYSTEM
        end

        loggin_in_user[req.uid] = nil

        return rsp, nil
    end
end

skynet.start(function ()
    skynet.dispatch("lua", function (_, _, cmd, ...)
        local f = CMD[cmd]
        skynet.retpack(f(...))
    end)
end)
