local skynet = require "skynet"

local M = {
    sequence = 0,
    timers = {},
    started = false,
    timer_handle = nil
}

local function run()
    local expired = {}
    local now = skynet.now()
    for id, v in pairs(M.timers) do
        if now >= v.expiration then
            table.insert(expired, v)
            if v.is_repeat then
                v.expiration = now + v.interval
            else
                M.timers[id] = nil
            end
        end
    end

    for _, v in pairs(expired) do
        v.cb(table.unpack(v.args))
    end
    if M.started then
        M.timer_handle = skynet.timeout(100, run)
    end
end

function M:start()
    if self.started then
        return
    end
    self.timer_handle = skynet.timeout(100, run)
    self.started = true
end

function M:add(expiration, interval, cb, ...)
    self.sequence = self.sequence + 1
    local id = self.sequence
    local timer = {}
    timer.id = id
    timer.expiration = expiration
    if not interval then
        interval = 0
    end
    timer.interval = interval
    timer.is_repeat = interval > 0
    timer.cb = cb
    timer.args = table.pack(...)

    self.timers[id] = timer
    return id
end

function M:cancel(id)
    self.timers[id] = nil
end

function M:stop()
    for id, _ in pairs(M.timers) do
        M.timers[id] = nil
    end

    self.started = false
end

return M
