
local require = require
local tostring = tostring
local table = table

local skynet = require "skynet"
local cluster = require "skynet.cluster"
local service = require "service"
local log = require "log"
local cjson = require "cjson"
local util = require "util.util"
local timeutil = require "util.time"
local snowflake = require "snowflake"
local CRONTAB_TYPE = require("common.constant").CRONTAB_TYPE

-- 加载 proto
local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/db")
pc.include_imports = true
pc:loadfile("player_crontab.proto")

local M = {
    uid = 0,
    refresh_timestamp = {}  -- 时间刷新类型 -> 下次刷新时间
}

-- 模块
function M.onInit()

end

function M.onRelease()

end

function M.onRun()
    M.refresh()
end

function M.onBackup()
    local player_crontab = {
        uid = M.uid,
        data = cjson.encode(M.refresh_timestamp),
    }
    local data = pb.encode("db.player_crontab", player_crontab)
    util.call("db", ".dbproxy", "set", M.uid, "player_crontab", "db.player_crontab", data)
end

function M.onLoad()
    local player_crontab = util.call("db", ".dbproxy", "load", M.uid, "player_crontab")
    if not player_crontab then
        if player_crontab.data and player_crontab.data ~= "" then
            M.refresh_timestamp = cjson.decode(player_crontab.data)
            if not M.refresh_timestamp then
                M.refresh_timestamp = {}
            end
        end
    end
end

-- 玩家所有数据已加载完毕后触发, 在该函数中可以处理离线逻辑
function M.onActivate()
    M.refresh()
end

function M.onPlayerOnline()

end

function M.onPlayerOffline()

end

function M.refresh()
    local now = os.time()
    for _, ct in pairs(CRONTAB_TYPE) do
        if not M.refresh_timestamp[ct] then
            M.refresh_timestamp[ct] = 0
        end
        if M.refresh_timestamp[ct] and M.refresh_timestamp[ct] <= now then
            M.reset(ct)
        end
    end
end

function M.reset(ct)
    local next_refresh_time = 0
    if ct == CRONTAB_TYPE.CT_HOUR then
        next_refresh_time = timeutil.get_next_hour_zero()
    elseif ct == CRONTAB_TYPE.CT_DAY_0 then
        next_refresh_time = timeutil.get_next_day_zero()
    elseif ct == CRONTAB_TYPE.CT_DAY_12 then
        next_refresh_time = timeutil.get_next_day_zero(12)
    elseif ct == CRONTAB_TYPE.CT_WEEK then
        next_refresh_time = timeutil.get_next_week_zero()
    elseif ct == CRONTAB_TYPE.CT_MONTH then
        next_refresh_time = timeutil.get_next_month_zero()
    else
        return
    end

    M.refresh_timestamp[ct] = next_refresh_time
    service.method.onTimeEvent(ct)
end

return M

