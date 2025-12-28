local AutoChatConfig = { 
    enabled = true, 
    userName = "", 
    targetUserId = 8590884903, 
    intervalSeconds = 30, 
    useTeamChat = false, 
    messages = { 
        "老虎最可爱", 
        "萌萌哒", 
        "嘿呦嘿呦" 
    } 
}

local Players = game:GetService("Players") 
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local TextChatService = game:FindService("TextChatService") 
local localPlayer = Players.LocalPlayer 

local Global = (getgenv and getgenv()) or _G

if Global.AutoChatStop and type(Global.AutoChatStop) == "function" then
    Global.AutoChatStop()
end

Global.AutoChatStop = nil

local running = true
Global.AutoChatStop = function()
    running = false
end

if not AutoChatConfig.enabled then 
    Global.AutoChatStop()
    return 
end 

if not localPlayer then 
    Global.AutoChatStop()
    return 
end 

if AutoChatConfig.targetUserId and localPlayer.UserId ~= AutoChatConfig.targetUserId then 
    warn("[自动聊天] 玩家ID不匹配，已禁用自动聊天") 
    Global.AutoChatStop()
    return 
end 

if AutoChatConfig.userName ~= "" and localPlayer.Name ~= AutoChatConfig.userName then 
    warn("[自动聊天] 用户名不匹配，已禁用自动聊天") 
    Global.AutoChatStop()
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
            else 
                warn("[自动聊天] 发送消息失败：", err) 
            end 
        end 
    end 

    if not success then 
        warn("[自动聊天] 所有聊天通道均发送失败") 
    end 
end 

math.randomseed(tick()) 

task.spawn(function() 
    while running and AutoChatConfig.enabled do 
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
