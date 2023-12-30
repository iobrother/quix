local skynet = require "skynet"
local socket = require "skynet.socket"
local websocket = require "http.websocket"
local httpc = require "http.httpc"

local log = require "log"
local uuid = require "uuid"

local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/")
pc.include_imports = true
pc:loadfile("proto.proto")
pc:loadfile("login.proto")
pc:loadfile("chat.proto")
pc:loadfile("api/passport.proto")
pc:loadfile("user.proto")
-- pc:loadfile("room.proto")
pc:loadfile("pm.proto")

local ws_id
local seq = 0
local logged = false

local function inc_seq()
    seq = seq + 1
end

local function sync(offset)
    local msg = {
        seq = seq + 1,
        cmd = "chat.SyncMsgReq",
        payload = nil
    }

    local req = {
        offset = offset,
        limit = 0,
    }
    local payload = assert(pb.encode("chat.SyncMsgReq", req))
    msg.payload = payload
    local data = assert(pb.encode("proto.Msg", msg))
    websocket.write(ws_id, data, "binary")
end

local function recv_msg_loop()
    while true do
        local data, close_reason = websocket.read(ws_id)
        if not data then
            LOG("server close")
            os.exit()
        end
        local m = assert(pb.decode("proto.Msg", data))
        LOGF("recv msg cmd=%s", m.cmd)
        local rsp = assert(pb.decode(m.cmd, m.payload))
        LOG(rsp)
        if m.cmd == "login.LoginRsp" then
            logged = true
        end
        if m.cmd == "chat.SyncMsgRsp" then
            if rsp.list and #rsp.list > 0 then
                sync(rsp.list[#rsp.list].send_time)
            end
        end
    end
end

local function heartbeat()
    skynet.timeout(30*100, heartbeat)
    local msg = {
        seq = seq + 1,
        cmd = "proto.Noop",
        payload = nil
    }

    local req = {
    }
    local payload = assert(pb.encode("proto.Noop", req))
    msg.payload = payload

    local data = assert(pb.encode("proto.Msg", msg))
    websocket.write(ws_id, data, "binary")
end

local CMD = {}

function CMD.login(openid, device_id)
    if not openid then
        openid = "test_open_id"
    end
    if not device_id then
        device_id = "test_device_id"
    end
    httpc.timeout = 500

    local reqheader = {
        ["Content-Type"] = "application/x-protobuf",
        ["X-Proto-Name"] = "passport.GuestLoginReq",
    }

    local guest_login_req = {
        openid = openid,
        device_id = device_id,
    }

    local api_url = "http://127.0.0.1:2080"
    local content = assert(pb.encode("passport.GuestLoginReq", guest_login_req))
    local rspheader = {}
    local status, body = httpc.request("POST", api_url, "/passport/guestLogin", rspheader, reqheader, content)
    LOG(status, body)

    local rsp = assert(pb.decode("passport.GuestLoginRsp", body))
    LOG(rsp.uid, rsp.token)

    ws_id = websocket.connect("ws://127.0.0.1:2188/ws")

    skynet.fork(recv_msg_loop)

    skynet.timeout(30*100, heartbeat)

    local msg = {
        seq = seq + 1,
        cmd = "login.LoginReq",
        payload = nil
    }

    local req = {
        type = 1,
        uid = rsp.uid,
        token = rsp.token,
        platform = "web",
        device_id = device_id,
        device_name = "test device name",
        device_model = "PC",
        app_version = "1.0.0.0",
        res_version = "1.0.0.0",
    }
    local payload = assert(pb.encode("login.LoginReq", req))
    msg.payload = payload

    local data = assert(pb.encode("proto.Msg", msg))
    websocket.write(ws_id, data, "binary")
end

function CMD.pm(args)
    local msg = {
        seq = seq + 1,
        cmd = "pm.PmReq",
        payload = nil
    }

    local req = {
        args = args,
    }
    local payload = assert(pb.encode("pm.PmReq", req))
    msg.payload = payload
    local data = assert(pb.encode("proto.Msg", msg))
    websocket.write(ws_id, data, "binary")
end

function CMD.send()
    local msg = {
        seq = seq + 1,
        cmd = "chat.SendReq",
        payload = nil
    }

    local req = {
        channel_type = 3,
        msg_type = 1,
        to = 1388,
        content = "this is a test msg",
        client_uuid = uuid(),
    }
    local payload = assert(pb.encode("chat.SendReq", req))
    msg.payload = payload
    local data = assert(pb.encode("proto.Msg", msg))
    websocket.write(ws_id, data, "binary")
end

function CMD.sync()
    sync(0)
end

local function split_cmdline(cmdline)
	local split = {}
	for i in string.gmatch(cmdline, "%S+") do
		table.insert(split,i)
	end
	return split
end

local function console_main_loop()
	local stdin = socket.stdin()
	while true do
		local cmdline = socket.readline(stdin, "\n")
        local cmd, args = cmdline:match("^%s*([^%s]+)%s(.*)")
        if cmd == "pm" then
            if not logged then
                LOG("请先登录再执行该命令")
            else
                CMD[cmd](args)
            end
        else
            local split = split_cmdline(cmdline)
            cmd = split[1]
            local f = CMD[cmd]
            if f then
                if (not logged) and cmd ~= "login" then
                    LOG("请先登录再执行该命令")
                else
                    f(table.unpack(split, 2))
                end
            else
                LOG("unknown cmd")
            end
            inc_seq()
        end

        inc_seq()
	end
end

skynet.start(function ()
    skynet.fork(console_main_loop)
end)

