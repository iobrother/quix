local require = require
local skynet = require "skynet"

local log = require "log"

skynet.start(function ()
    log.debug("This is a debug message")
    log.info("This is an info message")
    log.warn("This is a warn message")
    log.error("This is an error message")
end)