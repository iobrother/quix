local M = {}

-- 返回table大小
M.size = function(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- 判断table是否为空
M.empty = function(t)
    return not next(t)
end

-- 返回table索引列表
M.indices = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, k)
    end
end

-- 返回table值列表
M.values = function(t)
    local result = {}
    for k, v in pairs(t) do
        table.insert(result, v)
    end
end

-- 浅拷贝
M.clone = function(t, nometa)
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
M.copy = function(t, nometa)
    local result = {}

    if not nometa then
        setmetatable(result, getmetatable(t))
    end

    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = M.copy(v, nometa)
        else
            result[k] = v
        end
    end
    return result
end

M.merge = function(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

M.sum = function(t)
    local s = 0
    for _, v in pairs(t) do
        s = s + v
    end
    return s
end

--返回table的最大value
M.maxn = function(t)
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
M.minn = function(t)
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

M.contain = function(t, val)
    for _, v in pairs(t) do
        if v == val then
            return true
        end
    end
    return false
end

local function table_tostring(root)
    local cache = { [root] = "." }
    local quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    local wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    local wrapVal = function(val)
        if type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    local function _dump(t, space, name)
        if next(t) == nil then
            return "{}"
        end
        local temp = {}
        for k, v in pairs(t) do
            local keystr = wrapKey(k)
            local valstr
            if cache[v] then
                valstr = "{" .. cache[v] .. "}"
            elseif type(v) == "table" then
                local new_key = name ..".".. tostring(k)
                cache[v] = new_key
                valstr = _dump(v, space .. "  ", new_key)
            else
                valstr = wrapVal(v)
            end

            table.insert(temp, keystr .. " = " .. valstr)
        end
        return "{\n" .. space .. table.concat(temp, ",\n" .. space) .. "\n" .. space:sub(1, -3) .. "}"
    end
    return _dump(root, "  ", "")
end

M.tostring = function(t)
    if type(t) == 'table' then
        return table_tostring(t)
    else
        return tostring(t)
    end
end

return M
