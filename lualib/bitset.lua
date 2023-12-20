local function bitcount(n)
    local count = 0
    while n > 0 do
        count = count + (n % 2)
        n = math.floor(n / 2)
    end
    return count
end

local M = {}

function M:set(position)
    if position then
        local bytePosition = math.floor(position / 8) + 1
        local bitPosition = position % 8
        local byte = self.data:byte(bytePosition) or 0
        byte = byte | (1 << bitPosition)
        self.data = self.data:sub(1, bytePosition - 1) .. string.char(byte) .. self.data:sub(bytePosition + 1)
    else
        -- 如果没有指定位置，将所有位置设为1
        self.data = string.rep("\xFF", math.ceil(self.size / 8))
    end
end

function M:reset(position)
    if position then
        local bytePosition = math.floor(position / 8) + 1
        local bitPosition = position % 8
        local byte = self.data:byte(bytePosition) or 0
        byte = byte & ~(1 << bitPosition)
        self.data = self.data:sub(1, bytePosition - 1) .. string.char(byte) .. self.data:sub(bytePosition + 1)
    else
        -- 如果没有指定位置，将所有位置设为0
        self.data = string.rep("\0", math.ceil(self.size / 8))
    end
end

function M:flip(position)
    if position and position <= self.size then
        local bytePosition = math.floor(position / 8) + 1
        local bitPosition = position % 8
        local byte = self.data:byte(bytePosition) or 0
        byte = byte ~ (1 << bitPosition)
        self.data = self.data:sub(1, bytePosition - 1) .. string.char(byte) .. self.data:sub(bytePosition + 1)
    else
        -- 如果没有指定位置，或者指定的位置超出范围，反转所有位置的位
        for i = 1, #self.data do
            local byte = self.data:byte(i) or 0
            self.data = self.data:sub(1, i - 1) .. string.char(byte ~ 0xFF) .. self.data:sub(i + 1)
        end
    end
end

function M:test(position)
    local bytePosition = math.floor(position / 8) + 1
    local bitPosition = position % 8
    local byte = self.data:byte(bytePosition) or 0
    return (byte & (1 << bitPosition)) ~= 0
end

function M:all()
    for i = 1, #self.data do
        if self.data:byte(i) ~= 255 then  -- 255 表示所有位都为1
            return false
        end
    end
    return true
end

function M:any()
    for i = 1, #self.data do
        if self.data:byte(i) ~= 0 then  -- 0 表示所有位都为0
            return true
        end
    end
    return false
end

function M:none()
    for i = 1, #self.data do
        if self.data:byte(i) ~= 0 then  -- 0 表示所有位都为0
            return false
        end
    end
    return true
end

function M:count()
    local count = 0
    for i = 1, #self.data do
        count = count + bitcount(string.byte(self.data, i))
    end
    return count
end

function M:tostring()
    local result = ""
    for i = 1, self.size do
        result = result .. (self:test(i) and "1" or "0")
    end
    return result
end

function M:tolong()
    local result = 0
    for i = 1, self.size do
        if self:test(i) then
            result = result | (1 << (i - 1))
        end
    end
    return result
end

local bitset = {}

function bitset.new(size)
    local obj = {
        data = string.rep("\0", math.ceil(size / 8)),
        size = size
    }
    setmetatable(obj, { __index = M })
    return obj
end

return bitset