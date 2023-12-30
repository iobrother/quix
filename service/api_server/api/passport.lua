local tostring = tostring

local service = require "service"
local log = require "log"
local uuid = require "uuid"
local util = require "util.util"
local snowflake = require "snowflake"

-- 加载 proto
local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true
pc:loadfile("db/user.proto")
pc:loadfile("db/user_bind.proto")

service.controller = {}

function service.controller.GuestLogin(params)
    LOG("游客登录")
    local req = params.req
    local where_clause = string.format("`platform`=1 and `openid`='%s'", req.openid)
    local ok, rs = util.pcall(util.call, "db", ".dbproxy", "query", 0, "user_bind", {"uid"}, where_clause)
    if not ok then
        assert(false, "系统错误")
    end
    local is_signup = false
    local uid
    if #rs == 0 then
        local row = {
            password = req.openid,
            created_at = os.time(),
        }
        local msg = pb.encode("db.user", row)
        ok, rs = util.pcall(util.call, "db", ".dbproxy", "insert", 0, "user", "db.user", msg)
        if not ok then
            assert(false, "系统错误")
        end
        LOG(rs)
        uid = rs.insert_id
        row = {
            id = snowflake.next(),
            platform = 1,
            uid = uid,
            openid = req.openid,
            created_at = os.time(),
        }
        msg = pb.encode("db.user_bind", row)
        ok = util.pcall(util.call, "db", ".dbproxy", "insert", 0, "user_bind", "db.user_bind", msg)
        if not ok then
            assert(false, "系统错误")
        end
        is_signup = true
    else
        LOG(rs)
        uid = rs[1].uid
    end

    local token = uuid()
    util.do_redis("set", "LOGIN_TOKEN:" .. tostring(uid) .. ":" .. req.device_id, token)
    local expires_at = os.time() + 86400*15
    return { uid = uid, token = token, is_signup = is_signup, expires_at = expires_at }
end

function service.reg_passport_router(r)
    r:post("/passport/guestLogin", service.controller.GuestLogin)
end

