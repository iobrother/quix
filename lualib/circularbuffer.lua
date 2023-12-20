local CircularBuffer = {}

function CircularBuffer.new(sz)
    local obj = { sz = sz, data = {}, front = 0, rear = 0, count = 0 }
    setmetatable(obj, { __index = CircularBuffer })
    return obj
end

function CircularBuffer:push_back(value)
    if self.count == self.sz then
        self:pop_front()  -- 如果队列满了，弹出最前面的元素
    end

    if self.count == 0 then
        self.front = 0
        self.rear = 0
    end

    self.data[self.rear] = value
    self.rear = self.rear + 1
    self.count = self.count + 1
end

function CircularBuffer:push_front(value)
    if self.count == self.sz then
        self:pop_back()  -- 如果队列满了，弹出最后面的元素
    end

    if self.count == 0 then
        self.front = 0
        self.rear = 0
    end

    self.front = self.front - 1
    self.data[self.front] = value
    self.count = self.count + 1
end

function CircularBuffer:pop_back()
    local value = nil
    if self.count > 0 then
        value = self.data[self.rear]
        self.data[self.rear] = nil
        self.rear = self.rear - 1
        self.count = self.count - 1
    end
    return value
end

function CircularBuffer:pop_front()
    local value = nil
    if self.count > 0 then
        value = self.data[self.front]
        self.data[self.front] = nil
        self.front = self.front + 1
        self.count = self.count - 1
    end
    return value
end

function CircularBuffer:size()
    return self.count
end

return CircularBuffer