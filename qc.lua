local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local hiddenMapContainer = Instance.new("Folder")
hiddenMapContainer.Name = "HiddenMapStorage"
hiddenMapContainer.Parent = game:GetService("ReplicatedStorage")

local targetMapObjects = {"Map", "Chunks"}
local isMapVisible = true
local tempAntiFallBedrock = nil

local createTempBedrock, clearTempBedrock, alignCharToBedrock, pullCharToGround
local getRespawnPosition

function getRespawnPosition()
    local baseplate = Workspace:FindFirstChild("Baseplate")
    if baseplate then
        return baseplate.Position + Vector3.new(0, 40, 0), baseplate.Position.Y
    else
        return Vector3.new(0, 40, 0), 0
    end
end

local function isOriginalBottomBedrock(part)
    if not part:IsA("BasePart") then return false end
    local bedrockNames = {"Baseplate", "Bedrock", "基岩", "底层基岩"}
    local isBedrock = table.find(bedrockNames, part.Name) ~= nil
    local isBottom = part.Position.Y <= 5
    return isBedrock and isBottom
end

function createTempBedrock()
    if tempAntiFallBedrock and tempAntiFallBedrock.Parent then return end
    local bedrock = Instance.new("Part")
    bedrock.Name = "Temp_Bedrock_OnlyHide"
    bedrock.Anchored = true
    bedrock.CanCollide = true
    bedrock.BrickColor = BrickColor.Black()
    bedrock.Size = Vector3.new(2048, 10, 2048)
    bedrock.Position = Vector3.new(0, -5, 0)
    bedrock.Parent = Workspace
    tempAntiFallBedrock = bedrock
end

function clearTempBedrock()
    if tempAntiFallBedrock and tempAntiFallBedrock.Parent then
        tempAntiFallBedrock:Destroy()
        tempAntiFallBedrock = nil
    end
end

function alignCharToBedrock()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not (root and hum) then return end

    local targetBedrock = nil
    for _, part in ipairs(Workspace:GetChildren()) do
        if isOriginalBottomBedrock(part) or part.Name == "Temp_Bedrock_OnlyHide" then
            targetBedrock = part
            break
        end
    end
    if not targetBedrock then return end

    local bedrockTop = targetBedrock.Position.Y + targetBedrock.Size.Y/2
    root.CFrame = CFrame.new(root.Position.X, bedrockTop + hum.HipHeight + 2, root.Position.Z)
end

function pullCharToGround()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and humanoid and humanoid.Health > 0) then return end

    task.wait(0.3)
    local respawnPos, baseplateY = getRespawnPosition()
    local newPos = Vector3.new(root.Position.X, baseplateY + 40, root.Position.Z)
    root.CFrame = CFrame.new(newPos)
    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
end

local function hideMapWithOriginalBedrock()
    for _, objName in ipairs(targetMapObjects) do
        local mapObj = Workspace:FindFirstChild(objName)
        if mapObj then
            for _, child in ipairs(mapObj:GetChildren()) do
                if isOriginalBottomBedrock(child) then
                    child.Parent = Workspace
                end
            end
            mapObj.Parent = hiddenMapContainer
        end
    end

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

    alignCharToBedrock()
end

local function showMapAsOriginal()
    for _, objName in ipairs(targetMapObjects) do
        local mapObj = hiddenMapContainer:FindFirstChild(objName)
        if mapObj then
            mapObj.Parent = Workspace
        end
    end

    clearTempBedrock()
    pullCharToGround()
end

local function toggleMapState(newVisible)
    isMapVisible = newVisible
    if newVisible then
        showMapAsOriginal()
    else
        hideMapWithOriginalBedrock()
    end
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MapControlUI"
    screenGui.Parent = LocalPlayer.PlayerGui

    local mapBtn = Instance.new("TextButton")
    mapBtn.Name = "MapSwitchBtn"
    mapBtn.Size = UDim2.new(0, 60, 0, 30)
    mapBtn.Position = UDim2.new(0.5, -30, 0.83, -15)
    mapBtn.BackgroundTransparency = 0.8
    mapBtn.BackgroundColor3 = Color3.fromRGB(60, 179, 113)
    mapBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    mapBtn.Text = "显示F"
    mapBtn.Font = Enum.Font.SourceSansBold
    mapBtn.TextSize = 14
    mapBtn.ClipsDescendants = true
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)
    corner.Parent = mapBtn
    mapBtn.Parent = screenGui

    mapBtn.MouseButton1Click:Connect(function()
        local newVisible = not isMapVisible
        toggleMapState(newVisible)
        mapBtn.Text = newVisible and "显示F" or "隐藏F"
    end)
end

local function setupFKeyShortcut()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
            local newVisible = not isMapVisible
            toggleMapState(newVisible)
            local mapBtn = LocalPlayer.PlayerGui:FindFirstChild("MapControlUI"):FindFirstChild("MapSwitchBtn")
            if mapBtn then
                mapBtn.Text = newVisible and "显示F" or "隐藏F"
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(1)
    if not isMapVisible then
        hideMapWithOriginalBedrock()
        alignCharToBedrock()
    else
        pullCharToGround()
    end
end)

createUI()
setupFKeyShortcut()

game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        toggleMapState(true)
        hiddenMapContainer:Destroy()
        clearTempBedrock()
    end
end)
