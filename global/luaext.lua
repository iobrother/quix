-- lua扩展

-- table扩展

-- 返回table大小
table.size = function(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- 判断table是否为空
table.empty = function(t)
    return not next(t)
end

-- 返回table索引列表
table.indices = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, k)
    end
end

-- 返回table值列表
table.values = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
end

-- 浅拷贝
table.clone = function(t, nometa)
    local result = {}
    if not nometa then
        setmetatable(result, getmetatable(t))
    end
    for k, v in pairs (t) do
        result[k] = v
    end
    return result
end

-- 深拷贝
table.copy = function(t, nometa)
    local result = {}

    if not nometa then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = table.copy(v, nometa)
        else
            result[k] = v
        end
    end
    return result
end

table.merge = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

table.sum = function(t)
    local s = 0
    for _, v in pairs(t) do
        s = s + v
    end
    return s
end

--返回table的最大value
table.maxn = function(t)
    local maxn = nil
    for _, v in pairs(t) do
        if nil == maxn then
            maxn = v
        end
        if maxn < v then
            maxn = v
        end
    end
    return maxn
end

--返回table的最小value
table.minn = function(t)
    local min = nil
    for _, v in pairs(t) do
        if nil == min then
            min = v
        end
        if min > v then
            min = v
        end
    end
    return min
end

table.contain = function(t, val)
    for _, v in pairs(t) do
        if v == val then
            return true
        end
    end
    return false
end

-- string扩展

-- 下标运算
do
    local mt = getmetatable("")
    local _index = mt.__index

    mt.__index = function (s, ...)
        local k = ...
        if "number" == type(k) then
            return _index.sub(s, k, k)
        else
            return _index[k]
        end
    end
end

string.split = function(s, delim)
    local split = {}
    local pattern = "[^" .. delim .. "]+"
    _ = string.gsub(s, pattern, function(v) table.insert(split, v) end)
    return split
end

string.ltrim = function(s, c)
    local pattern = "^" .. (c or "%s") .. "+"
    return (string.gsub(s, pattern, ""))
end

string.rtrim = function(s, c)
    local pattern = (c or "%s") .. "+" .. "$"
    return (string.gsub(s, pattern, ""))
end

string.trim = function(s, c)
    return string.rtrim(string.ltrim(s, c), c)
end

local function table_tostring(root)
    local cache = { [root] = "." }
    local function _dump(t, space, name)
        if next(t) == nil then
            return "{}"
        end
        local temp = {}
        for k, v in pairs(t) do
            local key = tostring(k)
            local keystr = "[" .. key .. "]"
            local valstr
            if cache[v] then
                valstr = "{" .. cache[v] .. "}"
            elseif type(v) == "table" then
                local new_key = name ..".".. key
                cache[v] = new_key
                valstr = _dump(v, space .. "  ", new_key)
            else
                valstr = tostring(v)
            end

            table.insert(temp, keystr .. " = " .. valstr)
        end
        return "{\n" .. space .. table.concat(temp, ",\n" .. space) .. "\n" .. space:sub(1, -3) .. "}"
    end
    return _dump(root, "  ", "")
end

do
    local _tostring = tostring
    tostring = function(v)
        if type(v) == 'table' then
            return table_tostring(v)
        else
            return _tostring(v)
        end
    end
end

-- math扩展
do
	local _floor = math.floor
	math.floor = function(n, p)
		if p and p ~= 0 then
			local e = 10 ^ p
			return _floor(n * e) / e
		else
			return _floor(n)
		end
	end
end

math.round = function(n, p)
    local e = 10 ^ (p or 0)
    return math.floor(n * e + 0.5) / e
end


-- lua面向对象扩展
local _class={}

function class(super)
    local class_type={}
    class_type.ctor=false
    class_type.super=super
    class_type.new=function(...)
            local obj={}
            do
                local create
                create = function(c,...)
                    if c.super then
                        create(c.super,...)
                    end
                    if c.ctor then
                        c.ctor(obj,...)
                    end
                end

                create(class_type,...)
            end
            setmetatable(obj,{ __index=_class[class_type] })
            return obj
        end
    local vtbl={}
    _class[class_type]=vtbl

    setmetatable(class_type,{__newindex=
        function(t,k,v)
            vtbl[k]=v
        end
    })

    if super then
        setmetatable(vtbl,{__index=
            function(t,k)
                local ret=_class[super][k]
                vtbl[k]=ret
                return ret
            end
        })
    end

    return class_type
end
