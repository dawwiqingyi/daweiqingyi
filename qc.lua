-- 1. 初始化核心服务与全局依赖（无修改）
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoveMapKeepBedrockUI"
ScreenGui.Parent = LocalPlayer.PlayerGui

-- 2. 核心配置与工具函数（仅修改AutoMap默认值为true，无其他改动）
local main = { AutoMap = true } -- 改为默认开启，无其他修改
local autoLoops = {} 
local cleanupList = { connections = {} } 

-- 【关键】基岩识别逻辑（完全保留原代码，未动任何基岩相关判断）
local function isBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    local bedrockNameList = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrockName = table.find(bedrockNameList, part.Name) ~= nil
    local isBottomPosition = part.Position.Y <= 5
    return isBedrockName and isBottomPosition -- 仅判断名称和位置，不涉及颜色
end

-- 循环启动/停止、提示功能（完全保留原代码，无修改）
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

-- 3. 核心移除地图逻辑（完全保留原代码，仅删除非底层基岩的部件，不修改基岩属性）
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

-- 4. 仅移除UI相关代码（删除原createToggleButton函数、uiPanel创建代码）
-- 直接启动功能（无UI，加载即开启）
startLoop("AutoMap", removeMapExceptBottomBedrock, 0.1)
showNotify("移除地图", "已自动开启（仅保留底层基岩）")

-- 5. 资源清理（完全保留原代码，无修改）
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        for _, conn in ipairs(cleanupList.connections) do
            if conn.Connected then conn:Disconnect() end
        end
        autoLoops = {}
        ScreenGui:Destroy()
    end
end)
