-- 1. 初始化核心服务与全局依赖
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoveMapKeepBedrockUI"
ScreenGui.Parent = LocalPlayer.PlayerGui

-- 2. 核心配置与工具函数
local main = { AutoMap = true } -- 默认开启
local autoLoops = {} 
local cleanupList = { connections = {} } 

-- 【关键】基岩识别逻辑（完全保留原逻辑）
local function isBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    local bedrockNameList = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrockName = table.find(bedrockNameList, part.Name) ~= nil
    local isBottomPosition = part.Position.Y <= 5
    return isBedrockName and isBottomPosition
end

-- 循环启动函数
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

-- 【修复】提示功能：确保3秒后销毁，增加鲁棒性
local function showNotify(title, content)
    -- 先销毁可能残留的旧通知，避免叠加
    local existingNotify = ScreenGui:FindFirstChild("TempNotify")
    if existingNotify then
        existingNotify:Destroy()
    end

    -- 创建新通知框，添加唯一名称便于后续查找
    local notify = Instance.new("Frame")
    notify.Name = "TempNotify" -- 新增：给通知框命名，便于管理
    notify.Size = UDim2.new(0, 280, 0, 70)
    notify.Position = UDim2.new(0.5, -140, 0.05, 0)
    notify.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notify.BackgroundTransparency = 0.4
    notify.BorderColor3 = Color3.fromRGB(200, 200, 200)
    notify.BorderSizePixel = 1
    notify.Parent = ScreenGui

    -- 标题文本
    local titleLab = Instance.new("TextLabel")
    titleLab.Size = UDim2.new(1, 0, 0.4, 0)
    titleLab.BackgroundTransparency = 1
    titleLab.Text = title
    titleLab.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLab.TextSize = 18
    titleLab.Parent = notify

    -- 内容文本
    local contentLab = Instance.new("TextLabel")
    contentLab.Size = UDim2.new(1, 0, 0.6, 0)
    contentLab.Position = UDim2.new(0, 0, 0.4, 0)
    contentLab.BackgroundTransparency = 1
    contentLab.Text = content
    contentLab.TextColor3 = Color3.fromRGB(220, 220, 220)
    contentLab.TextSize = 14
    contentLab.Parent = notify

    -- 【关键修复】确保3秒后销毁：用task.spawn包裹，避免延迟函数被阻塞
    task.spawn(function()
        task.wait(3) -- 稳定等待3秒
        if notify and notify.Parent then -- 判空，避免已被手动销毁导致报错
            notify:Destroy()
        end
    end)
end

-- 3. 核心：移除地图逻辑（完全保留原逻辑）
local function removeMapExceptBottomBedrock()
    -- 目标1：删除 Map.Buildings
    local buildings = Workspace.Map:FindFirstChild("Buildings")
    if buildings then
        for _, part in ipairs(buildings:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    -- 目标2：删除 Map.Fragmentable
    local fragmentable = Workspace.Map:FindFirstChild("Fragmentable")
    if fragmentable then
        for _, part in ipairs(fragmentable:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    -- 目标3：删除 Chunks
    local chunks = Workspace:FindFirstChild("Chunks")
    if chunks then
        for _, part in ipairs(chunks:GetChildren()) do
            if not isBottomBedrock(part) then
                pcall(function() part:Destroy() end)
            end
        end
    end

    -- 目标4：删除其他地图容器
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

-- 4. 自动开启功能（加载即启动，通知3秒后消失）
startLoop("AutoMap", removeMapExceptBottomBedrock, 0.1)
showNotify("移除地图", "已自动开启（仅保留底层基岩）") -- 调用修复后的提示函数

-- 5. 资源清理
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, conn in ipairs(cleanupList.connections) do
            if conn.Connected then conn:Disconnect() end
        end
        autoLoops = {}
        if ScreenGui then ScreenGui:Destroy() end -- 销毁所有UI，包括残留通知
    end
end)
