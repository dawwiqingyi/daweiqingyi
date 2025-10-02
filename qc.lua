-- 1. 初始化核心服务与全局依赖（移除StarterGui，无需通知相关服务）
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoveMapKeepBedrockUI"
ScreenGui.Parent = LocalPlayer.PlayerGui

-- 2. 核心配置与工具函数（删除所有通知相关代码）
local main = { AutoMap = true } -- 默认开启移除地图功能
local autoLoops = {} 
local cleanupList = { connections = {} } -- 仅保留连接清理，删除通知管理

-- 【关键】基岩识别逻辑（完全保留原功能，无修改）
local function isBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    local bedrockNameList = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrockName = table.find(bedrockNameList, part.Name) ~= nil
    local isBottomPosition = part.Position.Y <= 5
    return isBedrockName and isBottomPosition
end

-- 循环启动函数（无修改，保障功能运行）
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

-- 循环停止函数（无修改，用于资源清理）
local function stopLoop(name)
    if autoLoops[name] then autoLoops[name] = nil end
end

-- 3. 核心：移除地图逻辑（完全保留原功能，无修改）
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

-- 4. 自动开启功能（仅启动核心逻辑，无任何文字通知）
startLoop("AutoMap", removeMapExceptBottomBedrock, 0.1)

-- 5. 资源清理（简化通知相关清理，仅保留核心资源释放）
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        -- 清理连接
        for _, conn in ipairs(cleanupList.connections) do
            if conn.Connected then conn:Disconnect() end
        end
        -- 停止循环
        autoLoops = {}
        -- 销毁UI容器（彻底清理残留）
        if ScreenGui then ScreenGui:Destroy() end
    end
end)
