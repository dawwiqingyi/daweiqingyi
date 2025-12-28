local AutoChatConfig = { 
    enabled = true,                -- 是否开启自动发言
    userName = "weidada9",         -- 可选：用户名
    targetUserId = 859088490,     -- 可选：玩家ID
    intervalSeconds = 30, 
    useTeamChat = false, 
    messages = { 
        "老虎最可爱", 
        "萌萌哒嘿呦嘿呦", 
        "木嘛~" 
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

-- ===== 只要 ID 或 用户名 任意一个匹配就通过 =====
local needCheck = (AutoChatConfig.targetUserId ~= nil) or (AutoChatConfig.userName ~= "")

local idMatch = false
if AutoChatConfig.targetUserId ~= nil then
    idMatch = (localPlayer.UserId == AutoChatConfig.targetUserId)
end

local nameMatch = false
if AutoChatConfig.userName ~= "" then
    nameMatch = (localPlayer.Name == AutoChatConfig.userName)
end

if needCheck and not (idMatch or nameMatch) then
    Global.AutoChatStop()
    return
end
-- ===============================================
 
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
            local ok2 = pcall(function() 
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
