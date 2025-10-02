-- 1. 初始化核心服务与全局依赖
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoveMapKeepBedrockUI"
ScreenGui.Parent = LocalPlayer.PlayerGui

-- 2. 核心配置与工具函数（完全对齐防掉落的基岩逻辑）
local main = { AutoMap = false } -- 移除地图开关
local autoLoops = {} -- 循环管理
local cleanupList = { connections = {} } -- 资源清理

-- 【关键】统一底层基岩识别逻辑（完全沿用防掉落的基岩判断规则）
-- 作用：判断是否为“最底下的基岩”，保留它不删除
local function isBottomBedrock(part)
    -- 条件1：是实体方块（BasePart）
    if not part:IsA("BasePart") then return false end
    -- 条件2：名称符合基岩命名（可根据你的游戏补充，如“Bedrock”“基岩”）
    local bedrockNameList = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrockName = table.find(bedrockNameList, part.Name) ~= nil
    -- 条件3：位置在最底层（Y坐标≤5，与防掉落判断一致，可根据游戏调整）
    local isBottomPosition = part.Position.Y <= 5
    return isBedrockName and isBottomPosition
end

-- 循环启动函数（移除地图依赖）
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

-- 循环停止函数
local function stopLoop(name)
    if autoLoops[name] then autoLoops[name] = nil end
end

-- 提示功能
local function showNotify(title, content)
    local notify = Instance.new("Frame")
    notify.Size = UDim2.new(0, 280, 0, 70)
    notify.Position = UDim2.new(0.5, -140, 0.05, 0)
    notify.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notify.BackgroundTransparency = 0.4
    notify.BorderColor3 = Color3.fromRGB(200, 200, 200)
    notify.BorderSizePixel = 1
    notify.Parent = ScreenGui

    local titleLab = Instance.new("TextLabel")
    titleLab.Size = UDim2.new(1, 0, 0.4, 0)
    titleLab.BackgroundTransparency = 1
    titleLab.Text = title
    titleLab.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLab.TextSize = 18
    titleLab.Parent = notify

    local contentLab = Instance.new("TextLabel")
    contentLab.Size = UDim2.new(1, 0, 0.6, 0)
    contentLab.Position = UDim2.new(0, 0, 0.4, 0)
    contentLab.BackgroundTransparency = 1
    contentLab.Text = content
    contentLab.TextColor3 = Color3.fromRGB(220, 220, 220)
    contentLab.TextSize = 14
    contentLab.Parent = notify

    task.delay(3, function() notify:Destroy() end)
end

-- 3. 核心：移除地图逻辑（按防掉落基岩逻辑保留底层基岩）
local function removeMapExceptBottomBedrock()
    -- 目标1：删除 Map.Buildings（房子等建筑）- 跳过底层基岩
    local buildings = Workspace.Map:FindFirstChild("Buildings")
    if buildings then
        for _, part in ipairs(buildings:GetChildren()) do
            if not isBottomBedrock(part) then -- 不是底层基岩就删除
                pcall(function() part:Destroy() end)
            end
        end
    end

    -- 目标2：删除 Map.Fragmentable（可破碎部件）- 跳过底层基岩
    local fragmentable = Workspace.Map:FindFirstChild("Fragmentable")
    if fragmentable then
        for _, part in ipairs(fragmentable:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    -- 目标3：删除 Chunks（地图区块）- 跳过底层基岩
    local chunks = Workspace:FindFirstChild("Chunks")
    if chunks then
        for _, part in ipairs(chunks:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    -- 目标4：删除其他可能的地图容器（如Ground）- 跳过底层基岩
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

-- 4. 独立UI开关按钮（控制移除地图启停）
local function createToggleButton(parent, title, x, y, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 35)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    btn.Text = title
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Parent = parent

    local isEnabled = false
    btn.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        btn.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 180, 70) or Color3.fromRGB(70, 70, 70)
        btn.Text = isEnabled and title:gsub("%[关闭%]", "[开启]") or title:gsub("%[开启%]", "[关闭]")
        callback(isEnabled)
    end)
    return btn
end

-- 创建UI面板与按钮
local uiPanel = Instance.new("Frame")
uiPanel.Size = UDim2.new(0, 160, 0, 60)
uiPanel.Position = UDim2.new(0.02, 0, 0.2, 0)
uiPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
uiPanel.BackgroundTransparency = 0.6
uiPanel.BorderColor3 = Color3.fromRGB(180, 180, 180)
uiPanel.BorderSizePixel = 1
uiPanel.Parent = ScreenGui

createToggleButton(uiPanel, "移除地图[留底层基岩] [关闭]", 10, 12, function(enabled)
    main.AutoMap = enabled
    if enabled then
        -- 开启：启动移除循环，只删非底层基岩
        startLoop("AutoMap", removeMapExceptBottomBedrock, 0.1)
        showNotify("移除地图", "已开启（仅保留底层基岩）")
    else
        -- 关闭：停止循环
        stopLoop("AutoMap")
        showNotify("移除地图", "已关闭")
    end
end)

-- 5. 资源清理（避免内存泄漏）
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, conn in ipairs(cleanupList.connections) do
            if conn.Connected then conn:Disconnect() end
        end
        autoLoops = {}
        ScreenGui:Destroy()
    end
end)
