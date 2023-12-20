-- EventBus 模块
local EventBus = {}

-- 事件表，存储事件及其观察者
local events = {}

-- 订阅事件
function EventBus.subscribe(event, observer)
    if not events[event] then
        events[event] = {}
    end
    table.insert(events[event], observer)
end

-- 发布事件
function EventBus.publish(event, ...)
    local observers = events[event]
    if observers then
        for _, observer in ipairs(observers) do
            -- 调用观察者的处理函数，并传递事件相关参数
            observer(event, ...)
        end
    end
end

-- 退订事件
function EventBus.unsubscribe(event, observer)
    local observers = events[event]
    if observers then
        for i, obs in ipairs(observers) do
            if obs == observer then
                table.remove(observers, i)
                break
            end
        end
    end
end

return EventBus

