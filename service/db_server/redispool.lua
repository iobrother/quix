local skynet = require "skynet"
local redis = require "skynet.db.redis"
require "skynet.manager"

local pool = {}

local current_index = 1
local pool_size

local function create_connection()
    local db = redis.connect{
        host = skynet.getenv("redis_host"),
        port = skynet.getenv("redis_port"),
        db = skynet.getenv("redis_db"),
        auth = skynet.getenv("redis_auth"),
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

function CMD.execute(cmd, ...)
    local conn = get_connection()
    local ok, result = pcall(conn.db[cmd], conn.db, ...)
    if not ok then
        error("Error executing Redis command:", result)
    end
    conn.last_active = skynet.time()
    return result
end

skynet.start(function()
    local size = skynet.getenv("redis_maxconn") or 10
    init_pool(size)

    skynet.fork(function()
        while true do
            check_connection()
            skynet.sleep(500)
        end
    end)

    skynet.dispatch("lua", function(_, _, cmd, rediscmd, ...)
        local f = assert(CMD[cmd], cmd .. " not found")
        skynet.ret(skynet.pack(f(rediscmd, ...)))
    end)

    skynet.register("." .. SERVICE_NAME)
end)
