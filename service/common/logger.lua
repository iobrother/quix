local skynet = require "skynet"
require "skynet.manager"

local DEFAUT_LOG = "default.log"

local logname = skynet.getenv("logname") or DEFAUT_LOG
local logger = skynet.getenv("logger")
local logpath = skynet.getenv("logpath")
local loglevel = skynet.getenv("loglevel") or "INFO"
local daemon = skynet.getenv("daemon")
local logfile = {}

local LEVEL = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	SKYNET = 5,
}

local log_level = LEVEL[loglevel]

local CMD = {}

function CMD.log(source, name, level, msg)
	local lv = assert(LEVEL[level], "日志等级错误")
	if log_level > lv then
		return
	end

	if name == "" then
		name = logname
	end
	msg = string.format("%s [%s] [:%08x] %s", os.date("%Y-%m-%d %H:%M:%S"), level, source, msg)
	if not daemon then
		print(msg)
	end

	local file = logfile[name]
	if not file then
		file = io.open(string.format("%s%s", logpath, name), "a+")
		logfile[name] = file
	end

	if file then
		file:write(msg .. "\n")
		file:flush()
	end
end

function CMD.debug(source, name, msg)
	if log_level <= LEVEL.DEBUG then
		CMD.log(source, name, "DEBUG", msg)
	end
end

function CMD.info(source, name, msg)
	if log_level <= LEVEL.INFO then
		CMD.log(source, name, "INFO", msg)
	end
end

function CMD.warn(source, name, msg)
	if log_level <= LEVEL.WARN then
		CMD.log(source, name, "WARN", msg)
	end
end

function CMD.error(source, name, msg)
	if log_level <= LEVEL.ERROR then
		CMD.log(source, name, "ERROR", msg)
	end
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, source, msg)
		CMD.log(source, "skynet.log", "SKYNET", msg)
	end
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function(_, source)
		for name, file in pairs(logfile) do
			io.close(file)
			file = io.open(string.format("%s%s", logpath, name), "a+")
			logfile[name] = file
		end
	end
}

skynet.start( function ()
	skynet.dispatch("lua", function(_, source, cmd, ...)
		CMD[cmd](source, ...)
	end)

	skynet.register(SERVICE_NAME)
end)