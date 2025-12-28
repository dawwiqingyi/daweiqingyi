local AutoChatConfig = {
    enabled = true,
    userName = "weidada9",
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

if not AutoChatConfig.enabled then
    return
end

if not localPlayer then
    return
end

if AutoChatConfig.userName ~= "" and localPlayer.Name ~= AutoChatConfig.userName then
    return
end

local function getRandomMessage()
    local list = AutoChatConfig.messages
    if not list or #list == 0 then
        return nil
    end
    local index = math.random(1, #list)
    return list[index]
end

local function sendChatMessage(message)
    if not message or message == "" then
        return
    end

    local success = false

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

    if not success and TextChatService then
        local channels = TextChatService:FindFirstChild("TextChannels")
        if channels and channels:FindFirstChild("RBXGeneral") then
            local general = channels.RBXGeneral
            local ok2, err = pcall(function()
                general:SendAsync(message)
            end)
            if ok2 then
                success = true
            end
        end
    end
end

math.randomseed(tick())

task.spawn(function()
    while AutoChatConfig.enabled do
        local msg = getRandomMessage()
        if msg then
            sendChatMessage(msg)
        end
        local delayTime = AutoChatConfig.intervalSeconds or 30
        if delayTime < 1 then
            delayTime = 1
        end
        task.wait(delayTime)
    end
end)
