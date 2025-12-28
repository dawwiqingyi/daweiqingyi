local AutoChatConfig = {
    enabled = true,
    userName = "",          -- 可选：用户名验证
    targetUserId = 85908843,      -- 新增：锁定的玩家ID（必填，替换为实际ID）
    intervalSeconds = 30,
    useTeamChat = false,
    messages = {
        "这是第一个自动消息",
        "这是第二个自动消息",
        "这是第三个自动消息"
    }
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:FindService("TextChatService")
local localPlayer = Players.LocalPlayer

-- 1. 基础开关判断
if not AutoChatConfig.enabled then
    return
end

-- 2. 验证本地玩家存在
if not localPlayer then
    return
end

-- 3. 新增：验证玩家ID（核心锁定逻辑）
if AutoChatConfig.targetUserId and localPlayer.UserId ~= AutoChatConfig.targetUserId then
    warn("[自动聊天] 玩家ID不匹配，已禁用自动聊天")
    return
end

-- 4. 保留原有的用户名验证（可选：如果不需要可以注释/删除）
if AutoChatConfig.userName ~= "" and localPlayer.Name ~= AutoChatConfig.userName then
    warn("[自动聊天] 用户名不匹配，已禁用自动聊天")
    return
end

-- 获取随机消息
local function getRandomMessage()
    local list = AutoChatConfig.messages
    if not list or #list == 0 then
        return nil
    end
    local index = math.random(1, #list)
    return list[index]
end

-- 发送聊天消息（原有逻辑不变）
local function sendChatMessage(message)
    if not message or message == "" then
        return
    end

    local success = false

    -- 尝试旧版聊天系统
    local ok1, chatEvents = pcall(function()
        return ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 1)
    end)

    if ok1 and chatEvents then
        local sayRemote = chatEvents:FindFirstChild("SayMessageRequest")
        if sayRemote and sayRemote:IsA("RemoteEvent") then
            local channel = AutoChatConfig.useTeamChat and "Team" or "All"
            sayRemote:FireServer(message, channel)
            success = true
        end
    end

    -- 尝试新版TextChatService
    if not success and TextChatService then
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels and channels:FindFirstChild("RBXGeneral") then
            local general = channels.RBXGeneral
            local ok2, err = pcall(function()
                general:SendAsync(message)
            end)
            if ok2 then
                success = true
            else
                warn("[自动聊天] 发送消息失败：", err)
            end
        end
    end

    if not success then
        warn("[自动聊天] 所有聊天通道均发送失败")
    end
end

-- 初始化随机数种子
math.randomseed(tick())

-- 启动自动聊天循环
task.spawn(function()
    while AutoChatConfig.enabled do
        local msg = getRandomMessage()
        if msg then
            sendChatMessage(msg)
        end
        -- 防呆：确保延迟时间不小于1秒
        local delayTime = AutoChatConfig.intervalSeconds or 30
        if delayTime < 1 then
            delayTime = 1
        end
        task.wait(delayTime)
    end
end)
