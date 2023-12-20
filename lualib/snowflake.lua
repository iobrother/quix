local sf = require "snowflake.core"

local snowflake = {}
sf.init(1)

function snowflake.next()
    return sf.next_id()
end

return snowflake