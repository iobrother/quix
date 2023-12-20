local M = {}

-- 获取下一个整点时间戳
function M.get_next_hour()
    local now = os.date("*t")
    local cur_hour = {
        year = now.year,
        month = now.month,
        day = now.day,
        hour = now.hour,
        min = 0,
        sec = 0,
    }
    return os.time(cur_hour) + 3600
end

-- 获取下一天某个整点时间戳
function M.get_next_day(hour)
    if not hour then
        hour = 0
    end
	local now = os.date("*t")
    local cur_day = {
        year = now.year,
        month = now.month,
        day = now.day,
        hour = hour,
        min = 0,
        sec = 0,
    }

    return os.time(cur_day) + 86400
end

function M.get_next_week()
    local now = os.date("*t")
    local days = now.wday == 1 and 1 or 9 - now.wday
    local cur_day = {
        year = now.year,
        month = now.month,
        day = now.day,
        hour = 0,
        min = 0,
        sec = 0,
    }

    return os.time(cur_day) + 86400 * days
end

function M.get_next_month()
    local now = os.date("*t")
    local next_month = {
        year = now.year,
        month = now.month + 1,
        day = 0,
        hour = 0,
        min = 0,
        sec = 0,
    }

    return os.time(next_month)
end

return M
