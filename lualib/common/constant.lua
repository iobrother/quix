

local constant = {}

constant.CRONTAB_TYPE = {
    CT_HOUR = 1,
    CT_DAY_0 = 2,
    CT_DAY_12 = 3,
    CT_WEEK = 4,
    CT_MONTH = 5,
}

constant.ATTRIBUTE_TYPE = {
    COIN = 1,
}

constant.COIN_OPERATION_TYPE = {
    WELCOME = 1,    -- 新用户首次登录奖励
}

constant.HEARTBEAT_INTERVAL = 30

constant.MODULE_EVENT = {
    NAME_CHANGE = 1,    -- 玩家改名
}

-- 消息类型
constant.MsgType = {
    eMT_NONE = 0,
    eMT_TEXT = 1,
    eMT_IMAGE = 2,
    eMT_AUDIO = 3,
    eMT_VIDEO = 4,
    eMT_FILE = 5,
    eMT_LOCATION = 7,
    eMT_QUOTE = 8,      -- 引用消息
    eMT_MERGER = 9,     -- 合并消息
    eMT_TIP = 10,       -- 提示消息
    eMT_RECALL = 11,    -- 撤回消息
}

-- 聊天频道
constant.ChannelType = {
    eCT_NONE = 0,
    eCT_NOTICE = 1,      -- 全服公告
    eCT_GLOBAL = 2,      -- 全服
    eCT_PRIVATE = 3,     -- 私聊
    eCT_GROUP = 4,       -- 群聊
    eCT_LEAGUE = 5,      -- 联盟
}

return constant
