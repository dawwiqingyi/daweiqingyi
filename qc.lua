local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- 1. 核心变量（完全沿用原显示地图逻辑，不改动恢复逻辑）
local hiddenMapContainer = Instance.new("Folder")
hiddenMapContainer.Name = "HiddenMapStorage"
hiddenMapContainer.Parent = game:GetService("ReplicatedStorage")

local targetMapObjects = {"Map", "Chunks"}  -- 仅控制这两个地图对象，与原逻辑一致
local isMapVisible = true  -- 初始：显示地图
local tempAntiFallBedrock = nil  -- 仅隐藏时生成的临时备用基岩

-- 2. 关键函数：判断游戏原底层基岩（保留用）
local function isOriginalBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    -- 匹配游戏原基岩名称+低位置，不改动原基岩任何属性
    local bedrockNames = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrock = table.find(bedrockNames, part.Name) ~= nil
    local isBottom = part.Position.Y <= 5  -- 原基岩通常在低Y坐标
    return isBedrock and isBottom
end

-- 3. 隐藏地图逻辑（仅新增“保留原基岩”，不影响显示恢复）
local function hideMapWithOriginalBedrock()
    -- 遍历需隐藏的地图对象（Map/Chunks）
    for _, objName in ipairs(targetMapObjects) do
        local mapObj = Workspace:FindFirstChild(objName)
        if mapObj then
            -- 先分离原基岩：把原基岩留在Workspace，不随地图对象隐藏
            for _, child in ipairs(mapObj:GetChildren()) do
                if isOriginalBottomBedrock(child) then
                    child.Parent = Workspace  -- 原基岩保留在Workspace
                end
            end
            -- 地图对象本身移到缓存（隐藏非基岩元素）
            mapObj.Parent = hiddenMapContainer
        end
    end

    -- 检查原基岩是否存在：不存在则生成临时基岩（防摔死，显示时会删除）
    local hasOriginalBedrock = false
    for _, part in ipairs(Workspace:GetChildren()) do
        if isOriginalBottomBedrock(part) then
            hasOriginalBedrock = true
            break
        end
    end
    if not hasOriginalBedrock then
        createTempBedrock()
    end

    -- 强制人物站在基岩上（防摔）
    alignCharToBedrock()
end

-- 4. 显示地图逻辑（完全沿用原逻辑，不做任何改动！确保显示有效）
local function showMapAsOriginal()
    -- 仅将缓存的地图对象移回Workspace，不改动原基岩归位（避免破坏显示）
    for _, objName in ipairs(targetMapObjects) do
        local mapObj = hiddenMapContainer:FindFirstChild(objName)
        if mapObj then
            mapObj.Parent = Workspace  -- 原逻辑：直接放回，不处理基岩
        end
    end

    -- 清除临时基岩（原基岩已存在或随地图恢复，无需临时基岩）
    clearTempBedrock()
end

-- 5. 生成/清除临时基岩（仅隐藏时用，显示时必删，不影响原地图）
local function createTempBedrock()
    if tempAntiFallBedrock and tempAntiFallBedrock.Parent then return end
    local bedrock = Instance.new("Part")
    bedrock.Name = "Temp_Bedrock_OnlyHide"  -- 临时标识，避免与原基岩冲突
    bedrock.Anchored = true
    bedrock.CanCollide = true
    bedrock.BrickColor = BrickColor.Black()
    bedrock.Size = Vector3.new(2048, 10, 2048)
    bedrock.Position = Vector3.new(0, -5, 0)
    bedrock.Parent = Workspace
    tempAntiFallBedrock = bedrock
end

local function clearTempBedrock()
    if tempAntiFallBedrock and tempAntiFallBedrock.Parent then
        tempAntiFallBedrock:Destroy()
        tempAntiFallBedrock = nil
    end
end

-- 6. 人物对齐基岩（防摔死，不影响地图显示）
local function alignCharToBedrock()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not (root and hum) then return end

    -- 优先找原基岩，没有则找临时基岩
    local targetBedrock = nil
    for _, part in ipairs(Workspace:GetChildren()) do
        if isOriginalBottomBedrock(part) or part.Name == "Temp_Bedrock_OnlyHide" then
            targetBedrock = part
            break
        end
    end
    if not targetBedrock then return end

    -- 计算安全高度，强制人物站在基岩上
    local bedrockTop = targetBedrock.Position.Y + targetBedrock.Size.Y/2
    root.CFrame = CFrame.new(root.Position.X, bedrockTop + hum.HipHeight + 2, root.Position.Z)
end

-- 7. 地图切换逻辑（仅隐藏时新增保留基岩，显示逻辑完全原封不动）
local function toggleMapState(newVisible)
    isMapVisible = newVisible
    if newVisible then
        -- 显示地图：完全沿用原逻辑，只恢复Map/Chunks到Workspace
        showMapAsOriginal()
    else
        -- 隐藏地图：新增保留原基岩逻辑，不删除、不移动原基岩
        hideMapWithOriginalBedrock()
    end
end

-- 8. UI开关（完全沿用原逻辑，不改动）
local function createMapToggleUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OnlyMapToggleUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "MapSwitchBtn"
    toggleBtn.Size = UDim2.new(0, 180, 0, 50)
    toggleBtn.Position = UDim2.new(0, 30, 0, 30)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    toggleBtn.BorderColor3 = Color3.fromRGB(0, 200, 255)
    toggleBtn.BorderSizePixel = 2
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Text = "地图：显示（点击隐藏）"
    toggleBtn.Parent = screenGui

    -- 点击事件：仅触发切换，不改动显示逻辑
    toggleBtn.MouseButton1Click:Connect(function()
        local newVisible = not isMapVisible
        toggleMapState(newVisible)
        toggleBtn.Text = newVisible and "地图：显示（点击隐藏）" or "地图：隐藏（点击显示）"
    end)
end

-- 9. 角色重生保障（仅隐藏时处理，不影响显示）
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    if not isMapVisible then
        hideMapWithOriginalBedrock()  -- 重生后重新保留原基岩
        alignCharToBedrock()          -- 强制站在基岩上
    end
end)

-- 10. 初始化+退出清理（完全沿用原逻辑）
createMapToggleUI()

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        toggleMapState(true)  -- 退出时显示地图
        hiddenMapContainer:Destroy()
        clearTempBedrock()
    end
end)
