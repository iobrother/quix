local require = require
local pairs = pairs
local assert = assert
local tonumber = tonumber
local table = table

local skynet = require "skynet"
require "skynet.manager"
local socketchannel = require "skynet.socketchannel"
local mysql = require "skynet.db.mysql"
local log = require "log"
local util = require "util.util"


local pool = {}

local current_index = 1
local pool_size

local function create_connection()
	local function on_connect(db)
		db:query("set charset utf8mb4");
	end
	local db = mysql.connect{
		host = skynet.getenv("mysql_host"),
		port = tonumber(skynet.getenv("mysql_port")),
		database = skynet.getenv("mysql_db"),
		user = skynet.getenv("mysql_user"),
		password = skynet.getenv("mysql_pwd"),
		max_packet_size = 1024 * 1024,
		on_connect = on_connect,
	}
    return { db = db, last_active = skynet.time() }
end

local function init_pool(size)
    for _ = 1, size do
        table.insert(pool, create_connection())
    end

    pool_size = 10
end

local function get_connection()
    local conn = pool[current_index]
    current_index = current_index % pool_size + 1
    return conn
end

local function check_connection()
    for i, conn in ipairs(pool) do
        local now = skynet.time()
        if now - conn.last_active > 30 then
            local ok, _ = pcall(conn.db.ping, conn.db)
            if not ok then
                skynet.error("Connection is invalid")
                conn.db:disconnect()
                conn = create_connection()
                pool[i] = conn
            else
                conn.last_active = now
            end
        end
    end
end

local CMD = {}

function CMD.execute(sql)
	local conn = get_connection()
	local ok, result = util.pcall(conn.db.query, conn.db, sql)
	if not ok then
		if result == socketchannel.error then
			-- 重新执行一遍, 内部会重连
			ok, result = util.pcall(conn.db.query, conn.db, sql)
		end
	end
	if result and result.errno then
		log.error(result.errno, result.err, result.badresult, result.sqlstate)
		error("db error")
	end
	conn.last_active = skynet.time()
	return result
end

function CMD.stop()
	for _, conn in pairs(pool) do
		conn.db:disconnect()
	end
	pool = {}
end

skynet.start(function ()
	local size = skynet.getenv("mysql_maxconn") or 10
    init_pool(size)

	skynet.fork(function()
        while true do
            check_connection()
            skynet.sleep(500)
        end
    end)

	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)

	skynet.register("." .. SERVICE_NAME)
end)
