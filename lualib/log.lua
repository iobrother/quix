local skynet = require "skynet"

local log = {}

local function log_tostring(log_tbl, sep)
    if sep == nil then
        sep = " "
    end

    local t = {}
    for _, v in pairs(log_tbl) do
        if type(v) ~= "string" then
            v = tostring(v)
        end
        table.insert(t, v)
    end
    return table.concat(t, sep)
end

function log.debug(...)
	log.log("", "", "DEBUG", ...)
end

function log.info(...)
	log.log("", "", "INFO", ...)
end

function log.warn(...)
	log.log("", "", "WARN", ...)
end

function log.error(...)
	log.log("", "", "ERROR", ...)
end

function log.fatal(...)
	log.log("", "", "FATAL", ...)
end

function log.debugf(fmt, ...)
	log.logf("", "", "DEBUG", fmt, ...)
end

function log.infof(fmt, ...)
	log.logf("", "", "INFO", fmt, ...)
end

function log.warnf(fmt, ...)
	log.logf("", "", "WARN", fmt, ...)
end

function log.errorf(fmt, ...)
	log.logf("", "", "ERROR", fmt, ...)
end

function log.fatalf(fmt, ...)
	log.logf("", "", "FATAL", fmt, ...)
end

-- 该函数不直接使用
function log.log(logname, module, level, ...)
	local args = log_tostring({...})
	local msg = ""
	if module and module ~= "" then
		msg = msg .. string.format("[%s] ", module)
	end
	local info = debug.getinfo(3)
	if info then
		msg = msg .. string.format("[%s:%d] ", info.short_src, info.currentline)
	end
	msg = msg .. args

	skynet.send(".logger", "lua", "log", logname, level, msg)
end

-- 该函数不直接使用
function log.logf(logname, module, level, fmt, ...)
	local args
	if select("#", ...) == 0 then
		args = tostring(fmt)
	else
		args = string.format(fmt, ...)
	end
	local msg = ""
	if module and module ~= "" then
		msg = msg .. string.format("[%s] ", module)
	end
	local info = debug.getinfo(3)
	if info then
		msg = msg .. string.format("[%s:%d] ", info.short_src, info.currentline)
	end
	msg = msg .. args

	skynet.send(".logger", "lua", "log", logname, level, msg)
end

return log
