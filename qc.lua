-- 1. 初始化核心服务与全局依赖（新增StarterGui服务，用于系统通知）
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoveMapKeepBedrockUI"
ScreenGui.Parent = LocalPlayer.PlayerGui

-- 2. 核心配置与工具函数
local main = { AutoMap = true } -- 默认开启
local autoLoops = {} 
local cleanupList = { connections = {}, notifyInstances = {} } -- 新增：专门管理通知实例，便于强制清理

-- 【关键】基岩识别逻辑（无修改）
local function isBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    local bedrockNameList = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrockName = table.find(bedrockNameList, part.Name) ~= nil
    local isBottomPosition = part.Position.Y <= 5
    return isBedrockName and isBottomPosition
end

-- 循环启动/停止函数（无修改）
local function startLoop(name, callback, delay)
    if autoLoops[name] then return end
    autoLoops[name] = coroutine.wrap(function()
        while autoLoops[name] do
            pcall(callback)
            task.wait(delay)
        end
    end)
    task.spawn(autoLoops[name])
end

local function stopLoop(name)
    if autoLoops[name] then autoLoops[name] = nil end
end

-- 【终极修复】提示功能：三重保障确保3秒消失
local function showNotify(title, content)
    -- 保障1：先清理所有残留通知（避免叠加）
    for _, notify in ipairs(cleanupList.notifyInstances) do
        if notify and notify.Parent then
            notify:Destroy()
        end
    end
    cleanupList.notifyInstances = {} -- 清空列表

    -- 方案A：优先使用系统级通知（StarterGui:SetCoreGuiEnabled 相关，销毁逻辑最稳定）
    local success = pcall(function()
        -- 调用Roblox内置通知（部分游戏支持，优先级高，自动消失）
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = content,
            Duration = 3 -- 强制设置显示时长3秒
        })
    end)

    -- 方案B：若系统通知不支持，使用自定义通知（双重定时销毁）
    if not success then
        local notify = Instance.new("Frame")
        notify.Name = "TempNotify"
        notify.Size = UDim2.new(0, 280, 0, 70)
        notify.Position = UDim2.new(0.5, -140, 0.05, 0)
        notify.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        notify.BackgroundTransparency = 0.4
        notify.BorderColor3 = Color3.fromRGB(200, 200, 200)
        notify.BorderSizePixel = 1
        notify.Parent = ScreenGui
        table.insert(cleanupList.notifyInstances, notify) -- 加入管理列表

        -- 标题文本
        local titleLab = Instance.new("TextLabel")
        titleLab.Name = "TitleLab"
        titleLab.Size = UDim2.new(1, 0, 0.4, 0)
        titleLab.BackgroundTransparency = 1
        titleLab.Text = title
        titleLab.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLab.TextSize = 18
        titleLab.Parent = notify

        -- 内容文本
        local contentLab = Instance.new("TextLabel")
        contentLab.Name = "ContentLab"
        contentLab.Size = UDim2.new(1, 0, 0.6, 0)
        contentLab.Position = UDim2.new(0, 0, 0.4, 0)
        contentLab.BackgroundTransparency = 1
        contentLab.Text = content
        contentLab.TextColor3 = Color3.fromRGB(220, 220, 220)
        contentLab.TextSize = 14
        contentLab.Parent = notify

        -- 保障2：第一层定时销毁（正常情况触发）
        task.spawn(function()
            task.wait(3)
            if notify and notify.Parent then
                notify:Destroy()
            end
        end)

        -- 保障3：第二层定时销毁（防止第一层失效，延迟3.1秒强制清理）
        task.spawn(function()
            task.wait(3.1)
            for i = #cleanupList.notifyInstances, 1, -1 do
                local inst = cleanupList.notifyInstances[i]
                if inst and inst.Parent then
                    inst:Destroy()
                end
                table.remove(cleanupList.notifyInstances, i)
            end
        end)
    end
end

-- 3. 核心：移除地图逻辑（无修改）
local function removeMapExceptBottomBedrock()
    local buildings = Workspace.Map:FindFirstChild("Buildings")
    if buildings then
        for _, part in ipairs(buildings:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    local fragmentable = Workspace.Map:FindFirstChild("Fragmentable")
    if fragmentable then
        for _, part in ipairs(fragmentable:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    local chunks = Workspace:FindFirstChild("Chunks")
    if chunks then
        for _, part in ipairs(chunks:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    local otherMapFolders = {Workspace.Ground, Workspace.TerrainParts}
    for _, folder in ipairs(otherMapFolders) do
        if folder then
            for _, part in ipairs(folder:GetChildren()) do
                if not isBottomBedrock(part) then
                    pcall(function() part:Destroy() end)
                end
            end
        end
    end
end

-- 4. 自动开启功能（加载即启动）
startLoop("AutoMap", removeMapExceptBottomBedrock, 0.1)
showNotify("移除地图", "已自动开启（仅保留底层基岩）")

-- 5. 资源清理（新增：强制清理所有通知）
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        -- 清理连接
        for _, conn in ipairs(cleanupList.connections) do
            if conn.Connected then conn:Disconnect() end
        end
        -- 清理通知（最后保障）
        for _, notify in ipairs(cleanupList.notifyInstances) do
            if notify and notify.Parent then
                notify:Destroy()
            end
        end
        -- 清理循环和UI
        autoLoops = {}
        if ScreenGui then ScreenGui:Destroy() end
    end
end)
