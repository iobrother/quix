local M = {}

M.split = function(s, delim)
    local split = {}
    local pattern = "[^" .. delim .. "]+"
    _ = string.gsub(s, pattern, function(v) table.insert(split, v) end)
    return split
end

M.ltrim = function(s, c)
    local pattern = "^" .. (c or "%s") .. "+"
    return (string.gsub(s, pattern, ""))
end

M.rtrim = function(s, c)
    local pattern = (c or "%s") .. "+" .. "$"
    return (string.gsub(s, pattern, ""))
end

M.trim = function(s, c)
    return M.rtrim(M.ltrim(s, c), c)
end

return M
