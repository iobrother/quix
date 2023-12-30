local require = require
local string = string
local assert = assert

local service = require "service"
local skynet = require "skynet"
local snax = require "skynet.snax"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local log = require "log"

require "passport"

-- 加载 proto
local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true
pc:loadfile("api/passport.proto")

-- 加载路由
local router = require "router"
local r = router.new()
service.reg_passport_router(r)

local function gen_interface(fd)
    return {
        read = sockethelper.readfunc(fd),
        write = sockethelper.writefunc(fd),
    }
end

local function response(id, write, ...)
    local ok, err = httpd.write_response(write, ...)
    if not ok then
        log.errorf(string.format("fd = %d, %s", id, err))
    end
end

local function handle_request(id, url, method, header, body, interface)
    local path, query_str = urllib.parse(url)
    local query
    if query_str then
        query = urllib.parse_query(query_str)
    else
        query = {}
    end

    LOGF("url=%s method=%s path=%s", url, method, path)

    local origin = header["origin"]
    local host = header["host"]
    local rspheader = {}
    if not (origin == "http://" .. host or origin == "https://" .. host) then
        rspheader["Access-Control-Allow-Credentials"] = "true"
        rspheader["Access-Control-Allow-Origin"] = "*"
        if method == "OPTIONS" then
            rspheader["Access-Control-Allow-Headers"] = "*"
            rspheader["Access-Control-Allow-Methods"] = "POST, HEAD, GET, PUT, PATCH, DELETE, OPTIONS"
        end
    end

    if method == "OPTIONS" then
        response(id, interface.write, 204, "", rspheader)
        return
    end

    local req
    local cmd = header["x-proto-name"]
    if header["content-type"] == "application/json" then
        LOG("application/json")
    elseif header["content-type"] == "application/x-protobuf" then
        req = assert(pb.decode(cmd, body))
    end

    local ok, rsp, err = r:execute(method, path, query, {header = header, req = req})
    if not ok then
        response(id, interface.write, 404, "404 Not found")
    else
        if rsp then
            local cmd = string.sub(cmd, 1, -4) .. "Rsp"
            local content = assert(pb.encode(cmd, rsp))
            response(id, interface.write, 200, content, rspheader)
        else
            local content = assert(pb.encode("proto.Error", err))
            response(id, interface.write, 599, content, rspheader)
        end
    end
end

-- 由 apigate 转发过来
function service.cmd.forward(id)
    socket.start(id)
    local interface = gen_interface(id)
    
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(interface.read, 8192)
    if not code then
        if url == sockethelper.socket_error then
            log.error("socket closed")
        else
            log.info(url)
        end
        socket.close(id)
        return
    end

    if code ~= 200 then
        response(id, interface.write, code)
        socket.close(id)
        return
    end

    handle_request(id, url, method, header, body, interface)
    socket.close(id)
end

service.init {
    init = function ()
    end
}
