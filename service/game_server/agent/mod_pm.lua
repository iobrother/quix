local require = require
local tostring = tostring
local table = table

local service = require "service"
local log = require "log"
local util = require "util.util"
local stringutil = require "util.string"

local enable_pm = true
function service.client.pm_PmReq(uid, req)
    LOG(req)
    if not enable_pm then
        return
    end

    -- TODO 判断玩家是否允许PM
    local args = stringutil.split(req.args, " ")
    assert(#args >= 1)

    return service.cmd["pm_" .. args[1]](uid, table.unpack(args, 2))
end

function service.cmd.pm_test(uid)

end

function service.cmd.pm_spin(uid, flag)
    if not flag then
        flag = 0
    else
        flag = tonumber(flag)
    end
    local rsp, err = util.call("scene", ".gameroom", "pm_spin", uid, flag)
    return rsp, err
end

function service.cmd.pm_attr(uid, attr_type, attr_value)
    attr_type = tonumber(attr_type)
    attr_value = tonumber(attr_value)
    service.method.change_attribute(attr_type, attr_value, 2, {remark="pm命令"})
    return {}, nil
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
