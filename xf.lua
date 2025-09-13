local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService") -- 新增：用于全局输入处理
local LocalPlayer = Players.LocalPlayer

-- 吸附逻辑变量（不变）
local isAttaching = false
local targetPlayer = nil
local attachConnection = nil
local maxAttachDistance = 999000
local backOffset = 0.5
local cleanupList = {connections = {}}

-- 获取角色根部件（不变）
local function getRoot()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    end
    return nil
end

-- 创建ScreenGui（不变）
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerAttachUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ====================== 主框架 ======================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.22, 0, 0.6, 0) -- 缩小宽度+加高高度
mainFrame.Position = UDim2.new(0.05, 0, 0.16, 0) -- 初始位置
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

-- 拖动状态变量
local dragging = false
local dragStart = Vector2.new()
local startPos = mainFrame.Position

-- 拖动逻辑
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

-- 结束拖动时的处理（只保留一个事件处理函数）
mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        -- 移除input:Consume()，输入结束时无需阻止传递
    end
end)

-- 拖动过程中的处理
mainFrame.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- 4. 框架内拖动结束处理（备用）
mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            dragging = false
            isDraggingFromFrame = false
            mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        end
    end
end)

-- ====================== 原有UI元素（只保留最小化按钮） ======================
-- 最小化按钮（调整位置到右上角，统一+号和-号大小）
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 25, 0, 25) -- 固定30x30像素，确保+号和-号大小一致
minimizeBtn.AnchorPoint = Vector2.new(1, 0)
minimizeBtn.Position = UDim2.new(1, -4, 0, 4) -- 原关闭按钮位置
minimizeBtn.Text = "-"
minimizeBtn.TextScaled = true
minimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
minimizeBtn.TextColor3 = Color3.fromRGB(255,255,255)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = mainFrame
local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 12)
minimizeCorner.Parent = minimizeBtn

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -12, 0.75, 0)
playerScroll.Position = UDim2.new(0, 6, 0, 30)
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.BackgroundTransparency = 1
playerScroll.ScrollBarThickness = 6
playerScroll.BorderSizePixel = 0
playerScroll.Parent = mainFrame

-- 存储玩家按钮（不变）
local playerButtons = {}
-- 当前选择的玩家（不变）
local selectedPlayer = nil
-- 最小化状态
local isMinimized = false
local originalSize = mainFrame.Size
local originalPosition = mainFrame.Position

-- 透明度状态
local transparencyLevel = 0 -- 0=不透明, 1=50%透明, 2=90%透明
local transparencyValues = {0, 0.5, 0.9}

-- 透明度切换功能
local function toggleTransparency()
    transparencyLevel = (transparencyLevel + 1) % 3
    local transparency = transparencyValues[transparencyLevel + 1]
    
    -- 递归设置所有UI元素的透明度
    local function setElementTransparency(element, alpha)
        if element:IsA("Frame") or element:IsA("TextButton") then
            if alpha == 0 then
                if element == mainFrame then
                    element.BackgroundTransparency = 0
                elseif element.Name:find("Btn") or element:IsA("TextButton") then
                    element.BackgroundTransparency = 0
                else
                    element.BackgroundTransparency = element.BackgroundTransparency
                end
            else
                element.BackgroundTransparency = math.min(0.95, alpha)
            end
        end
        
        if element:IsA("TextLabel") or element:IsA("TextButton") then
            element.TextTransparency = alpha
        end
        
        if element:IsA("ImageLabel") then
            element.ImageTransparency = alpha
        end
        
        -- 递归处理子元素
        for _, child in pairs(element:GetChildren()) do
            if child:IsA("GuiObject") then
                setElementTransparency(child, alpha)
            end
        end
    end
    
    -- 应用透明度到整个UI
    setElementTransparency(mainFrame, transparency)
end

-- 最小化功能（修改：底部按钮保持原大小，只显示两个玩家）
local function toggleMinimize()
    if isMinimized then
        -- 恢复到正常大小（最大化状态）
        isMinimized = false
        mainFrame.Size = originalSize
        minimizeBtn.Text = "-"
        
        -- 显示所有UI元素
        titleLabel.Visible = true
        playerScroll.Visible = true
        
        -- 恢复底部按钮框位置
        bottomFrame.Position = UDim2.new(0, 6, 1, -bottomFrameHeight - 6)
        
        -- 显示所有玩家按钮并恢复原始位置
        refreshPlayerList()
    else
        -- 最小化状态
        isMinimized = true
        originalSize = mainFrame.Size
        mainFrame.Size = UDim2.new(0.22, 0, 0.22, 0)  -- 调整高度以容纳两个玩家和底部按钮
        minimizeBtn.Text = "+"
        
        -- 隐藏标题和玩家滚动区域
        titleLabel.Visible = false
        playerScroll.Visible = false
        
        -- 底部按钮保持原始大小和位置（不变）
        bottomFrame.Position = UDim2.new(0, 6, 1, -bottomFrameHeight - 6)  -- 调整位置适应新高度
        
        -- 显示前两个玩家按钮
        local visibleCount = 0
        for _, btn in pairs(playerButtons) do
            btn.Visible = false
        end
        
        -- 只显示前两个玩家
        for _, btn in pairs(playerButtons) do
            if visibleCount < 2 then
                btn.Visible = true
                btn.Position = UDim2.new(0.025, 0, 0, 35 + visibleCount * 33)  -- 垂直排列
                btn.Size = UDim2.new(0.95, 0, 0, 30)  -- 保持原始大小
                visibleCount = visibleCount + 1
            end
        end
    end
end

-- 背部吸附功能核心函数（不变）
local function findNearestPlayer()
    local root = getRoot()
    if not root then return nil end
    
    local myPosition = root.Position
    local nearestPlayer = nil
    local shortestDistance = maxAttachDistance
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer 
           and otherPlayer.Character 
           and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
           and otherPlayer.Character:FindFirstChildOfClass("Humanoid")
           and otherPlayer.Character.Humanoid.Health > 0 then
            
            local otherRoot = otherPlayer.Character.HumanoidRootPart
            local distance = (otherRoot.Position - myPosition).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestPlayer = otherPlayer
            end
        end
    end
    return nearestPlayer
end

local function stopAttaching()
    if attachConnection and attachConnection.Connected then
        attachConnection:Disconnect()
        attachConnection = nil
    end
    isAttaching = false
    targetPlayer = nil
end

local function startAttaching(player)
    local root = getRoot()
    if not root then
        return false
    end
    
    local target = player or findNearestPlayer()
    if not target then
        return false
    end
    
    targetPlayer = target
    isAttaching = true
    
    attachConnection = RunService.Heartbeat:Connect(function()
        if not targetPlayer 
           or not targetPlayer.Character 
           or not targetPlayer.Character:FindFirstChild("HumanoidRootPart")
           or (targetPlayer.Character:FindFirstChildOfClass("Humanoid") and targetPlayer.Character.Humanoid.Health <= 0) then
            stopAttaching()
            return
        end
        
        local root = getRoot()
        if not root then
            stopAttaching()
            return
        end
        
        local otherRoot = targetPlayer.Character.HumanoidRootPart
        local distance = (otherRoot.Position - root.Position).Magnitude
        if distance > maxAttachDistance then
            stopAttaching()
            return
        end
        
        local targetCFrame = otherRoot.CFrame
        local offset = targetCFrame.LookVector * -backOffset
        local targetPosition = targetCFrame.Position + offset
        local newCFrame = CFrame.new(targetPosition, targetPosition + root.CFrame.LookVector)
        
        local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = newCFrame})
        tween:Play()
    end)
    table.insert(cleanupList.connections, attachConnection)
    return true
end

local function toggleAttach(enabled, player)
    if enabled then
        return startAttaching(player)
    else
        stopAttaching()
        return true
    end
end

-- 创建玩家选择按钮（不变）
local function refreshPlayerList()
    for _, btn in playerButtons do
        btn:Destroy()
    end
    playerButtons = {}
    local y = 0
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.95, 0, 0, 30)
            btn.Position = UDim2.new(0.025, 0, 0, y)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.Text = ""
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Parent = playerScroll
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 10)
            btnCorner.Parent = btn

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 24, 0, 24)
            thumb.Position = UDim2.new(0, 3, 0, 3)
            thumb.BackgroundTransparency = 1
            thumb.Parent = btn
            local thumbCorner = Instance.new("UICorner")
            thumbCorner.CornerRadius = UDim.new(1, 0)
            thumbCorner.Parent = thumb
            local thumbType = Enum.ThumbnailType.HeadShot
            local thumbSize = Enum.ThumbnailSize.Size48x48
            local thumbUrl = Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)
            thumb.Image = thumbUrl

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0, 60, 1, 0)
            nameLabel.Position = UDim2.new(0, 32, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "  " .. player.DisplayName .. " (" .. player.Name .. ")"
            nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextScaled = false
            nameLabel.TextSize = 13  -- 自定义字体大小
            nameLabel.Font = Enum.Font.SourceSansSemibold
            nameLabel.Parent = btn

            -- 存储玩家引用到按钮中，方便最小化时识别
            btn:SetAttribute("PlayerName", player.Name)

            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                for _, b in playerButtons do
                    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
                btn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
            end)

            table.insert(playerButtons, btn)
            y = y + 33
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -12, 0, 30)
titleLabel.Position = UDim2.new(0, 6, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "吸附系统"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

-- 自定义底部按钮尺寸变量
local bottomButtonHeight = 30  -- 底部按钮高度（像素）
local bottomFrameHeight = bottomButtonHeight + 0  -- 底部框架高度（按钮高度+边距）

local bottomFrame = Instance.new("Frame")
bottomFrame.Size = UDim2.new(1, -12, 0, bottomFrameHeight)
bottomFrame.Position = UDim2.new(0, 6, 1, -bottomFrameHeight - 6)
bottomFrame.BackgroundTransparency = 1
bottomFrame.Parent = mainFrame

local attachBtn = Instance.new("TextButton")
attachBtn.Size = UDim2.new(0.35, -2, 0, bottomButtonHeight)
attachBtn.Position = UDim2.new(0, 0, 0, 5)
attachBtn.Text = "吸附"
attachBtn.TextScaled = true
attachBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
attachBtn.TextColor3 = Color3.fromRGB(255,255,255)
attachBtn.BorderSizePixel = 0
attachBtn.Font = Enum.Font.SourceSansBold
attachBtn.Parent = bottomFrame
local attachCorner = Instance.new("UICorner")
attachCorner.CornerRadius = UDim.new(0, 10)
attachCorner.Parent = attachBtn

-- 透明度按钮
local transparencyBtn = Instance.new("TextButton")
transparencyBtn.Size = UDim2.new(0.2, -2, 0, bottomButtonHeight)
transparencyBtn.Position = UDim2.new(0.4, 2, 0, 5)
transparencyBtn.Text = "透"
transparencyBtn.TextScaled = true
transparencyBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
transparencyBtn.TextColor3 = Color3.fromRGB(255,255,255)
transparencyBtn.BorderSizePixel = 0
transparencyBtn.Font = Enum.Font.SourceSansBold
transparencyBtn.Parent = bottomFrame
local transparencyCorner = Instance.new("UICorner")
transparencyCorner.CornerRadius = UDim.new(0, 10)
transparencyCorner.Parent = transparencyBtn

local detachBtn = Instance.new("TextButton")
detachBtn.Size = UDim2.new(0.35, -2, 0, bottomButtonHeight)
detachBtn.Position = UDim2.new(0.65, 2, 0, 5)
detachBtn.Text = "取消吸附"
detachBtn.TextScaled = true
detachBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
detachBtn.TextColor3 = Color3.fromRGB(255,255,255)
detachBtn.BorderSizePixel = 0
detachBtn.Font = Enum.Font.SourceSansBold
detachBtn.Parent = bottomFrame
local detachCorner = Instance.new("UICorner")
detachCorner.CornerRadius = UDim.new(0, 10)
detachCorner.Parent = detachBtn

-- 按钮逻辑（不变）
attachBtn.MouseButton1Click:Connect(function()
    if selectedPlayer then
        local success = toggleAttach(true, selectedPlayer)
        if success then
            attachBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
            attachBtn.Text = "吸附中..."
        end
    end
end)

detachBtn.MouseButton1Click:Connect(function()
    toggleAttach(false)
    attachBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
    attachBtn.Text = "吸附"
end)

-- 透明度按钮点击事件
transparencyBtn.MouseButton1Click:Connect(function()
    toggleTransparency()
end)

-- 最小化按钮点击事件
minimizeBtn.MouseButton1Click:Connect(function()
    toggleMinimize()
end)

-- 默认显示UI（不变）
screenGui.Enabled = true
