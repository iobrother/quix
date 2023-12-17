local skynet = require "skynet"
local log = require "log"

NODE_NAME = skynet.getenv("nodename")

LOG = function (...)
    log.log("", "", "INFO", ...)
end

LOGF = function (fmt, ...)
    log.logf("", "", "INFO", fmt, ...)
end

MONEY_LOG = function (...)
    log.log("money.log", "money", "INFO", ...)
end

MONEY_LOGF = function (fmt, ...)
    log.logf("money.log", "money", "INFO", fmt, ...)
end