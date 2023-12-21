local skynet = require "skynet"
require "skynet.manager"

local log = require "log"
local util = require "util.util"
local tableutil = require "util.table"
local lfs = require "lfs"

local pb = require "pb"
local protoc = require "protoc"
local pc = protoc.new()
pc:addpath("proto/db")
pc.include_imports = true

for file in lfs.dir("./proto/db") do
    if file:match("%.proto$") then
        pc:loadfile(file)
    end
end

local CMD = {}

function  CMD.start()

end

-- pb message中包含表名
function CMD.load(uid, table_name)
	local sql = string.format("SELECT * FROM `%s` WHERE `uid`=%d LIMIT 1", table_name, uid)
	local rs = skynet.call(".mysqlpool", "lua", "execute", sql)
	local row = #rs > 0 and rs[1] or rs
	return row
end

-- 各个模块定时备份，调用该函数
function CMD.set(uid, table_name, msg_name, msg)
	local key = "table:" .. table_name .. ":" .. tostring(uid)
	local data = util.do_redis("get", key)
	if data then
		if data == msg then
			-- 数据没有改变，直接返回
			return
		end
	end

	local t = pb.decode(msg_name, msg)
	local pk = "`uid`"
	local pk_value = uid
	if t.id then
		pk = "`id`"
		pk_value = t.id
	end

	local counter = 0
	local set_clause = ""
	for k, v in pairs(t) do
		if counter > 0 then
			set_clause = set_clause .. ","
		end
		set_clause = set_clause .. "`" .. k .. "`" .. "="
		if type(v) == "string" then
			v = "'" .. v .. "'"
		end
		set_clause = set_clause .. v
		counter = counter + 1
	end

	local sql = ""
	sql = sql .. "UPDATE "
	sql = sql .. "`" .. table_name .. "`"
	sql = sql .. " SET "
	sql = sql .. set_clause
	sql = sql .. " WHERE "
	sql = sql .. pk
	sql = sql .. "=";
	sql = sql .. tostring(pk_value)

	LOG(sql)

	skynet.call(".mysqlpool", "lua", "execute", sql)
	util.do_redis("set", key, msg)

end

-- update 与 set 的区别就在于没有缓存
function CMD.update(uid, table_name, msg_name, msg)
	local t = pb.decode(msg_name, msg)
	local pk = "`uid`"
	local pk_value = uid
	if t.id then
		pk = "`id`"
		pk_value = t.id
	end
	local counter = 0
	local set_clause = ""
	for k, v in pairs(t) do
		if counter > 0 then
			set_clause = set_clause .. ","
		end
		set_clause = set_clause .. "`" .. k .. "`" .. "="
		if type(v) == "string" then
			v = "'" .. v .. "'"
		end
		set_clause = set_clause .. v
		counter = counter + 1
	end

	local sql = ""

	sql = sql .. "UPDATE "
	sql = sql .. "`" .. table_name .. "`"
	sql = sql .. " SET "
	sql = sql .. set_clause
	sql = sql .. " WHERE "
	sql = sql .. pk
	sql = sql .. "=";
	sql = sql .. tostring(pk_value)

	LOG(sql)

	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function CMD.query(uid, table_name, fields, where_clause)
	local columns
	if tableutil.empty(fields) then
		columns = "*"
	else
		local counter = 0
		for _, field in ipairs(fields) do
			if counter == 0 then
				columns = "`" .. field .. "`"
			else
				columns = columns .. "," .. "`" .. field .. "`"
			end
			counter = counter + 1
		end
	end

	local sql
	if where_clause and where_clause ~= "" then
		sql = string.format("SELECT %s FROM `%s` WHERE %s", columns, table_name, where_clause)
	else
		sql = string.format("SELECT %s FROM `%s`", columns, table_name)
	end

	LOG(sql)

	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function CMD.insert(uid, table_name, msg_name, msg)
	local t = pb.decode(msg_name, msg)
	local counter = 0
	local clause1 = ""
	local clause2 = ""
	for k, v in pairs(t) do
		if counter > 0 then
			clause1 = clause1 .. ","
			clause2 = clause2 .. ","
		end
		clause1 = clause1 .. "`" .. k .. "`"
		if type(v) == "string" then
			v = "'" .. v .. "'"
		end
		clause2 = clause2 .. v
		counter = counter + 1
	end

	local sql = ""

	sql = sql .. "INSERT INTO "
	sql = sql .. "`" .. table_name .. "`"
	sql = sql .. "("
	sql = sql .. clause1
	sql = sql .. ") VALUES("
	sql = sql .. clause2
	sql = sql .. ")";

	LOG(sql)

	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function CMD.remove(uid, table_name, msg_name, msg)
	local t = pb.decode(msg_name, msg)
	local pk = "`uid`"
	local pk_value = uid
	if t.id then
		pk = "`id`"
		pk_value = t.id
	end

	local sql = ""

	sql = sql .. "DELETE FROM "
	sql = sql .. "`" .. table_name .. "`"
	sql = sql .. " WHERE "
	sql = sql .. pk
	sql = sql .. "="
	sql = sql .. tostring(pk_value)
	sql = sql .. " LIMIT 1";

	LOG(sql)

	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

function CMD.execute(uid, sql)
	return skynet.call(".mysqlpool", "lua", "execute", sql)
end

skynet.start(function ()
	skynet.dispatch("lua", function (_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)

	skynet.register("." .. SERVICE_NAME)
end)
