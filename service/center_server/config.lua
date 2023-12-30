local skynet = require "skynet"
require "skynet.manager"

local log = require "log"
local util = require "util.util"
local lfs = require "lfs"

local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/config")
pc.include_imports = true

pc:loadfile("config.proto")

local data
local CMD = {}

function CMD.get(name, id)
	if not id then
		return data[name][id]
	else
		return data[name]
	end
end

skynet.start(function ()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)

	local file = io.open("proto/config/s_data.pb", "rb")
	local content
	if file then
		content = file:read("*all")
		file:close()
	end

	data = pb.decode("config.s_data", content)
	content = nil
	skynet.register("." .. SERVICE_NAME)
end)
