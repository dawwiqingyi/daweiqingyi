
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RemoveMapKeepBedrockUI"
ScreenGui.Parent = LocalPlayer.PlayerGui


local main = { AutoMap = true } 
local autoLoops = {} 
local cleanupList = { connections = {} } 


local function isBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    local bedrockNameList = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrockName = table.find(bedrockNameList, part.Name) ~= nil
    local isBottomPosition = part.Position.Y <= 5
    return isBedrockName and isBottomPosition
end


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


startLoop("AutoMap", removeMapExceptBottomBedrock, 0.1)


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
