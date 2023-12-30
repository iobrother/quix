# quix

A game engine based on skynet

## 特性

- 通信数据格式用 protobuf 存储
- 数据保存，玩家状态数据有变动才会同步至 redis 与 mysql，记录型数据（与玩家游戏状态无关）直接保存至 mysql，不缓存至 redis
- 统一的模块编写方法，一个玩家对应一个 agent，一个 agent 服务包含多个业务逻辑模块，每个模块都有以下回调函数 onInit onRun onLoad onActivate onTimeEvent onPlayerOnline onPlayerOffline onRelease
- 多文件日志，日志可以根据需要写入不同的文件中，比如与金币变动相关的日志单独记录到 money.log 文件中
- 聊天服务器
- 定时任务

## 快速开始

### 编译

```
make
```

### 导入 SQL 脚本

创建 quix 数据库，导入 quix.sql 脚本

### 以单节点方式运行

```
./start.sh
```

### 以多节点方式运行

```
./start.sh 1
```

### 注意

以单节点方式运行，必须确保节点内服务名称不能重复，多节点方式没有这个限制，不同节点的服务可以重名

### 运行客户端

```
./client.sh
```

- login

### PM 命令

给玩家增加金币

```
pm attr 1 10000
```

### 数据库约定

quix 数据库表主键名称要么是 uid, 要么是 id

### 开发一个模块

在 service/game_server/agent 目录下创建一个 mod_example 开始开发一个新模块, 一个模块属于一个 agent 服务, 一个玩家绑定一个 agent 服务。

模块内的 local 函数仅在模块内函数

service.client 用于处理 客户端消息, 客户端消息命名规则 模块名称\_方法名称, 比如 proto 中的 chat.SendReq 协议就命名为 chat_SendReq 挂在 service.client 下, 即 service.client.chat_SendReq

所有客户端消息处理函数返回值格式为 rsp, err

service.cmd 用于处理节点内消息

service.method 用于处理服务内调用, 比如一个模块调用了另一个模块的方法

模块要实现的函数

```
-- 模块初始化, 在这个函数中可以进行模块事件订阅 eventbus.subscribe(event, observer)
function M.onInit()
end

-- 在这个函数中可以进行解除模块事件订阅 eventbus.unsubscribe(event, observer)
function M.onRelease()
end

-- 每秒1帧执行该函数
function M.onRun()
end

-- 将内存中的玩家状态数据备份到数据库, 该函数框定期执行, 目前设定是2分钟,
-- 如果有些逻辑需要立刻保存数据到数据库, 也可以手动执行该函数
function M.onBackup()
end

-- 一个 agent 被加载的时候会执行各个模块的onLoad方法
function M.onLoad()
end

-- 在玩家数据被加载后执行, 该函数可以处理离线逻辑
function M.onActivate()
end

-- 玩家上线后会调用, 该函数内部可以同步数据给客户端
function M.onPlayerOnline()
end

-- 玩家下线调用
function M.onPlayerOffline()
end

-- 定时器事件到来, ct类型定义在CONSTANT.CRONTAB_TYPE
-- 该函数可选, 可以在此函数内部实现定时任务
function M.onTimeEvent(ct)
end
```
