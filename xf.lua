local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local isAttaching = false
local targetPlayer = nil
local attachConnection = nil
local maxAttachDistance = 9999000
local backOffset = 0.5

local isFlinging = false
local flingConnection = nil
local selectedTarget = "全部"
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local cleanupList = {connections = {}}

local function getRoot()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart
    end
    return nil
end

local GetPlayer = function(Name)
    if Name == "全部" then
        return "全部"
    elseif Name == "随机" then
        local allPlayers = Players:GetPlayers()
        table.remove(allPlayers, table.find(allPlayers, LocalPlayer))
        return #allPlayers > 0 and allPlayers[math.random(#allPlayers)] or nil
    end
    
    local cleanName = Name
    local usernameMatch = Name:match("%((.-)%)")
    if usernameMatch then
        cleanName = usernameMatch
    end
    
    cleanName = cleanName:lower()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local playerName = player.Name:lower()
            local displayName = player.DisplayName:lower()
            if playerName == cleanName or displayName == cleanName or playerName:match("^"..cleanName) or displayName:match("^"..cleanName) then
                return player
            end
        end
    end
    return nil
end

local Message = function(Title, Text, Time)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = Time or 3
    })
end

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

local SkidFling = function(TargetPlayer)
    if not isFlinging then return end

    local LocalChar = LocalPlayer.Character
    local LocalHumanoid = LocalChar and LocalChar:FindFirstChildOfClass("Humanoid")
    local LocalRoot = LocalHumanoid and LocalHumanoid.RootPart

    if not (LocalChar and LocalHumanoid and LocalRoot) then
        Message("甩飞失败", "本地角色部件缺失", 3)
        return
    end

    local TargetChar = TargetPlayer.Character
    local TargetHumanoid = TargetChar and TargetChar:FindFirstChildOfClass("Humanoid")
    local TargetRoot = TargetHumanoid and TargetHumanoid.RootPart
    local TargetHead = TargetChar and TargetChar:FindFirstChild("Head")
    local Accessory = TargetChar and TargetChar:FindFirstChildOfClass("Accessory")
    local AccessoryHandle = Accessory and Accessory:FindFirstChild("Handle")

    if not (TargetChar and TargetHumanoid) then
        Message("甩飞失败", TargetPlayer.Name .. "角色无效", 3)
        return
    end
    if TargetHumanoid.Sit then
        Message("甩飞失败", TargetPlayer.Name .. "正在坐下，无法甩飞", 3)
        return
    end

    if not getgenv().OldPos then
        getgenv().OldPos = LocalRoot.CFrame
    end

    if TargetHead then
        workspace.CurrentCamera.CameraSubject = TargetHead
    elseif AccessoryHandle then
        workspace.CurrentCamera.CameraSubject = AccessoryHandle
    else
        workspace.CurrentCamera.CameraSubject = TargetHumanoid
    end

    local FPos = function(BasePart, Pos, Ang)
        if not isFlinging then return end
        LocalRoot.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
        LocalChar:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
        LocalRoot.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        LocalRoot.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local startTime = tick()
        local timeLimit = 2
        local angle = 0

        repeat
            if not isFlinging then break end
            if BasePart.Velocity.Magnitude < 50 then
                angle = angle + 100
                FPos(BasePart, CFrame.new(0, 1.5, 0) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + TargetHumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + TargetHumanoid.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + TargetHumanoid.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
            else
                FPos(BasePart, CFrame.new(0, 1.5, TargetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -TargetHumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TargetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TargetRoot.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -TargetRoot.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, TargetRoot.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until not isFlinging or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetChar or TargetPlayer.Parent ~= Players or TargetHumanoid.Sit or LocalHumanoid.Health <= 0 or tick() > startTime + timeLimit
    end

    workspace.FallenPartsDestroyHeight = 0/0
    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = LocalRoot
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)

    LocalHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TargetRoot and TargetHead then
        SFBasePart((TargetRoot.Position - TargetHead.Position).Magnitude > 5 and TargetHead or TargetRoot)
    elseif TargetRoot then
        SFBasePart(TargetRoot)
    elseif TargetHead then
        SFBasePart(TargetHead)
    elseif AccessoryHandle then
        SFBasePart(AccessoryHandle)
    else
        Message("甩飞失败", TargetPlayer.Name .. "缺失关键部件", 3)
    end

    if BV and BV.Parent then BV:Destroy() end
    LocalHumanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = LocalHumanoid

    if getgenv().OldPos and isFlinging then
        local recoverStart = tick()
        repeat
            if not isFlinging then break end
            LocalRoot.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
            LocalChar:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
            LocalHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            for _, part in ipairs(LocalChar:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                end
            end
            task.wait()
        until (LocalRoot.Position - getgenv().OldPos.Position).Magnitude < 25 or tick() > recoverStart + 3 or not isFlinging
    end
    workspace.FallenPartsDestroyHeight = getgenv().FPDH
end

local startFling = function()
    if isFlinging then
        Message("提示", "已在甩飞中，无需重复开启", 2)
        return
    end

    if not LocalPlayer.Character then
        Message("甩飞失败", "请先加载角色", 3)
        return
    end

    isFlinging = true
    Message("甩飞开启", "目标：" .. selectedTarget, 2)

    flingConnection = task.spawn(function()
        while isFlinging do
            local targetType = GetPlayer(selectedTarget)
            if targetType == "全部" then
                local allTargets = Players:GetPlayers()
                table.remove(allTargets, table.find(allTargets, LocalPlayer))
                if #allTargets == 0 then
                    Message("甩飞失败", "无其他玩家可作为目标", 3)
                    stopFling()
                    return
                end
                for _, target in ipairs(allTargets) do
                    if not isFlinging then break end
                    SkidFling(target)
                    task.wait(0.5)
                end
            else
                local singleTarget = targetType
                if not singleTarget or singleTarget == LocalPlayer then
                    Message("甩飞失败", "目标玩家不存在或为自己", 3)
                    stopFling()
                    return
                end
                SkidFling(singleTarget)
            end
            task.wait(1)
        end
    end)
end

local stopFling = function()
    if not isFlinging then
        Message("提示", "甩飞吸附系统已退出！", 2)
        return
    end

    isFlinging = false
    if flingConnection then
        task.cancel(flingConnection)
        flingConnection = nil
    end

    local localHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if localHumanoid then
        workspace.CurrentCamera.CameraSubject = localHumanoid
    end

    local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if localRoot then
        local bv = localRoot:FindFirstChild("EpixVel")
        if bv then bv:Destroy() end
        localRoot.Velocity, localRoot.RotVelocity = Vector3.new(), Vector3.new()
    end

    workspace.FallenPartsDestroyHeight = getgenv().FPDH

    Message("甩飞关闭", "已恢复正常状态", 2)
end

local getFlingTargetOptions = function()
    local options = {"全部", "随机"}
    local playerInfo = {}
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local displayName = player.DisplayName .. " (" .. player.Name .. ")"
            table.insert(options, displayName)
            playerInfo[displayName] = {
                name = player.Name,
                userId = player.UserId
            }
        end
    end
    
    return options, playerInfo
end

-- 检查并清理现有UI，确保不重复显示
local existingGui = LocalPlayer.PlayerGui:FindFirstChild("PlayerAttachAndFlingUI")
if existingGui then
    existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PlayerAttachAndFlingUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.25, 0, 0.7, 0) -- 减小宽度
mainFrame.Position = UDim2.new(0.05, 0, 0.16, 0) -- 保持原始位置
mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainFrame.BackgroundTransparency = 0.3 -- 标题栏透明度20%
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

local dragging = false
local dragStart = Vector2.new()
local startPos = mainFrame.Position

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

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

-- 最小化/最大化切换按钮（向X按钮靠拢）
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 20, 0, 20) -- 保持20x20尺寸
toggleBtn.AnchorPoint = Vector2.new(1, 0)
toggleBtn.Position = UDim2.new(1, -23, 0, 6) -- 从-22改为-18，向右移动4单位靠拢X按钮
local isMinimized = false
local function updateToggleButton()
    if isMinimized then
        toggleBtn.Text = "+" -- 最小化状态显示+按钮
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
    else
        toggleBtn.Text = "-" -- 正常状态显示-按钮
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    end
end
updateToggleButton()
toggleBtn.TextScaled = true
toggleBtn.BackgroundTransparency = 0.7 -- 设置半透明
toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = mainFrame
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 10) -- 保持圆角
toggleCorner.Parent = toggleBtn

-- 关闭按钮（X按钮，向左挪动）
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20) -- 保持20x20尺寸
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -2, 0, 6) -- 从3改为-2，向左挪动5单位
closeBtn.Text = "X"
closeBtn.TextScaled = true
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.BackgroundTransparency = 0.7 -- 设置半透明
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.BorderSizePixel = 0
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = mainFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10) -- 保持圆角
closeCorner.Parent = closeBtn

-- 关闭按钮点击事件
closeBtn.MouseButton1Click:Connect(function()
    -- 清理所有连接和状态
    for _, conn in ipairs(cleanupList.connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    stopAttaching()
    stopFling()
    -- 销毁UI
    screenGui:Destroy()
end)

-- 标题标签
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -65, 0, 30) -- 保持原有宽度适配
titleLabel.Position = UDim2.new(0, 6, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "吸附甩飞系统"
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 10
titleLabel.TextXAlignment = Enum.TextXAlignment.Left -- 左对齐文本
titleLabel.Parent = mainFrame

local attachPlayerScroll = Instance.new("ScrollingFrame")
attachPlayerScroll.Size = UDim2.new(1, -12, 0.35, 0)
attachPlayerScroll.Position = UDim2.new(0, 6, 0, 35)
attachPlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
attachPlayerScroll.BackgroundTransparency = 1
attachPlayerScroll.ScrollBarThickness = 6
attachPlayerScroll.BorderSizePixel = 0
attachPlayerScroll.Parent = mainFrame

local playerButtons = {}
local selectedPlayer = nil

local function refreshAttachPlayerList()
    for _, btn in playerButtons do
        btn:Destroy()
    end
    playerButtons = {}
    
    local existingNoPlayerLabel = attachPlayerScroll:FindFirstChild("NoPlayerLabel")
    if existingNoPlayerLabel then
        existingNoPlayerLabel:Destroy()
    end
    
    local y = 0
    local hasOtherPlayers = false
    
    for _, player in Players:GetPlayers() do
        if player ~= LocalPlayer then
            hasOtherPlayers = true
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.95, 0, 0, 30)
            btn.Position = UDim2.new(0.025, 0, 0, y)
            btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            btn.Text = ""
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = true
            btn.Parent = attachPlayerScroll
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
            nameLabel.Position = UDim2.new(0, 26, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "  " .. player.DisplayName .. " (" .. player.Name .. ")"
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextScaled = false
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.SourceSansSemibold
            nameLabel.Parent = btn

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
    
    if not hasOtherPlayers then
        local noPlayerLabel = Instance.new("TextLabel")
        noPlayerLabel.Name = "NoPlayerLabel"
        noPlayerLabel.Size = UDim2.new(1, -12, 0, 30)
        noPlayerLabel.Position = UDim2.new(0, 6, 0, 0)
        noPlayerLabel.BackgroundTransparency = 1
        noPlayerLabel.Text = "暂无其他玩家"
        noPlayerLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        noPlayerLabel.TextXAlignment = Enum.TextXAlignment.Center
        noPlayerLabel.TextScaled = false
        noPlayerLabel.TextSize = 13
        noPlayerLabel.Font = Enum.Font.SourceSansSemibold
        noPlayerLabel.Parent = attachPlayerScroll
        y = 30
    end
    
    attachPlayerScroll.CanvasSize = UDim2.new(0, 0, 0, y)
end

refreshAttachPlayerList()
Players.PlayerAdded:Connect(refreshAttachPlayerList)
Players.PlayerRemoving:Connect(refreshAttachPlayerList)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -12, 0, 1)
divider.Position = UDim2.new(0, 6, 0, 0.42)
divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

local flingTitle = Instance.new("TextLabel")
flingTitle.Size = UDim2.new(1, -12, 0, 20)
flingTitle.Position = UDim2.new(0, 6, 0, 0.44)
flingTitle.BackgroundTransparency = 1
flingTitle.Text = "甩飞控制"
flingTitle.TextColor3 = Color3.fromRGB(255, 165, 0)
flingTitle.TextXAlignment = Enum.TextXAlignment.Left
flingTitle.TextScaled = false
flingTitle.TextSize = 12
flingTitle.Font = Enum.Font.SourceSansBold
flingTitle.Parent = mainFrame

local flingTargetFrame = Instance.new("Frame")
flingTargetFrame.Size = UDim2.new(0.765, -12, 0, 25.5) -- 减小15%
flingTargetFrame.Position = UDim2.new(0, 6, 0, 0.49)
flingTargetFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flingTargetFrame.BackgroundTransparency = 0 -- 设置半透明
flingTargetFrame.BorderSizePixel = 0
flingTargetFrame.Parent = mainFrame
local flingTargetCorner = Instance.new("UICorner")
flingTargetCorner.CornerRadius = UDim.new(0, 10)
flingTargetCorner.Parent = flingTargetFrame

local flingTargetLabel = Instance.new("TextLabel")
flingTargetLabel.Size = UDim2.new(0.7, -30, 1, 0)
flingTargetLabel.Position = UDim2.new(0, 5, 0, 0)
flingTargetLabel.BackgroundTransparency = 1
flingTargetLabel.Text = selectedTarget
flingTargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
flingTargetLabel.TextXAlignment = Enum.TextXAlignment.Left
flingTargetLabel.TextScaled = false
flingTargetLabel.TextSize = 10 -- 略微减小字体
flingTargetLabel.Font = Enum.Font.SourceSans
flingTargetLabel.Parent = flingTargetFrame

local flingArrowBtn = Instance.new("TextButton")
flingArrowBtn.Size = UDim2.new(0, 25.5, 1, 0) -- 减小15%
flingArrowBtn.AnchorPoint = Vector2.new(1, 0)
flingArrowBtn.Position = UDim2.new(1, 0, 0, 0)
flingArrowBtn.Text = "▼"
flingArrowBtn.TextScaled = true
flingArrowBtn.BackgroundTransparency = 1
flingArrowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingArrowBtn.BorderSizePixel = 0
flingArrowBtn.Parent = flingTargetFrame

local flingOptionsList = Instance.new("ScrollingFrame")
flingOptionsList.Size = UDim2.new(0.765, -12, 0, 25.5) -- 减小15%
flingOptionsList.Position = UDim2.new(0, 6, 0, 0.49 + 25.5/70)
flingOptionsList.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
flingOptionsList.BackgroundTransparency = 0.5 -- 设置半透明
flingOptionsList.ScrollBarThickness = 4
flingOptionsList.BorderSizePixel = 0
flingOptionsList.Visible = false
flingOptionsList.Parent = mainFrame
local flingOptionsCorner = Instance.new("UICorner")
flingOptionsCorner.CornerRadius = UDim.new(0, 10)
flingOptionsCorner.Parent = flingOptionsList

local isFlingOptionsOpen = false
flingArrowBtn.MouseButton1Click:Connect(function()
    isFlingOptionsOpen = not isFlingOptionsOpen
    flingOptionsList.Visible = isFlingOptionsOpen
    flingArrowBtn.Text = isFlingOptionsOpen and "▲" or "▼"
    
    if isFlingOptionsOpen then
        for _, child in ipairs(flingOptionsList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local options, playerInfo = getFlingTargetOptions()
        local y = 0
        local maxHeight = 150
        
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 25.5) -- 减小15%
            optBtn.Position = UDim2.new(0, 0, 0, y)
            
            local isSelected = opt == selectedTarget
            if not isSelected and playerInfo[selectedTarget] and playerInfo[opt] and playerInfo[opt].name == playerInfo[selectedTarget].name then
                isSelected = true
            end
            
            optBtn.BackgroundColor3 = isSelected and Color3.fromRGB(80, 120, 200) or Color3.fromRGB(70, 70, 70)
            optBtn.BackgroundTransparency = 0.5 -- 设置半透明
            optBtn.Text = ""
            optBtn.TextScaled = false
            optBtn.TextSize = 12 -- 略微减小字体
            optBtn.Font = Enum.Font.SourceSans
            optBtn.BorderSizePixel = 0
            optBtn.Parent = flingOptionsList
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = optBtn
            
            if opt ~= "全部" and opt ~= "随机" and playerInfo[opt] then
                local thumb = Instance.new("ImageLabel")
                thumb.Size = UDim2.new(0, 20.4, 0, 20.4) -- 减小15%
                thumb.Position = UDim2.new(0, 3, 0, 2.55)
                thumb.BackgroundTransparency = 1
                thumb.Parent = optBtn
                local thumbCorner = Instance.new("UICorner")
                thumbCorner.CornerRadius = UDim.new(1, 0)
                thumbCorner.Parent = thumb
                local thumbType = Enum.ThumbnailType.HeadShot
                local thumbSize = Enum.ThumbnailSize.Size48x48
                local thumbUrl = Players:GetUserThumbnailAsync(playerInfo[opt].userId, thumbType, thumbSize)
                thumb.Image = thumbUrl
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -30, 1, 0)
                nameLabel.Position = UDim2.new(0, 28, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = opt .. "甩飞"
                nameLabel.TextColor3 = Color3.fromRGB(0, 255, 156)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextScaled = false
                nameLabel.TextSize = 17 -- 略微减小字体
                nameLabel.Font = Enum.Font.SourceSansBold 
                nameLabel.Parent = optBtn
            else
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -6, 1, 0)
                nameLabel.Position = UDim2.new(0, 3, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = opt .. "甩飞"
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 156)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextScaled = false
                nameLabel.TextSize = 14 -- 略微减小字体
                nameLabel.Font = Enum.Font.SourceSansBold
                nameLabel.Parent = optBtn
            end
            
            optBtn.MouseButton1Click:Connect(function()
                selectedTarget = opt
                flingTargetLabel.Text = opt
                isFlingOptionsOpen = false
                flingOptionsList.Visible = false
                flingArrowBtn.Text = "▼"
            end)
            
            y = y + 30
        end
        
        local dynamicHeight = math.min(y, maxHeight)
        flingOptionsList.Size = UDim2.new(flingOptionsList.Size.X.Scale, flingOptionsList.Size.X.Offset, 0, dynamicHeight)
        flingOptionsList.CanvasSize = UDim2.new(0, 0, 0, y)
    end
end)

local bottomFrame = Instance.new("Frame")
bottomFrame.Size = UDim2.new(1, -12, 0, 66)
bottomFrame.Position = UDim2.new(0, 6, 1, -72)
bottomFrame.BackgroundTransparency = 1
bottomFrame.Parent = mainFrame

local middleRowFrame = Instance.new("Frame")
middleRowFrame.Size = UDim2.new(1, 0, 0, 30)
middleRowFrame.Position = UDim2.new(0, 0, 0, 0)
middleRowFrame.BackgroundTransparency = 1
middleRowFrame.Parent = bottomFrame

local attachBtn = Instance.new("TextButton")
attachBtn.Size = UDim2.new(0.48, -2, 1, 0)
attachBtn.Position = UDim2.new(0, 0, 0, 0)
attachBtn.Text = "吸附"
attachBtn.TextScaled = true
attachBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 80)
attachBtn.TextColor3 = Color3.fromRGB(255,255,255)
attachBtn.BorderSizePixel = 0
attachBtn.Font = Enum.Font.SourceSansBold
attachBtn.Parent = middleRowFrame
local attachCorner = Instance.new("UICorner")
attachCorner.CornerRadius = UDim.new(0, 10)
attachCorner.Parent = attachBtn

local detachBtn = Instance.new("TextButton")
detachBtn.Size = UDim2.new(0.48, -2, 1, 0)
detachBtn.Position = UDim2.new(0.52, 2, 0, 0)
detachBtn.Text = "取消吸附"
detachBtn.TextScaled = true
detachBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
detachBtn.TextColor3 = Color3.fromRGB(255,255,255)
detachBtn.BorderSizePixel = 0
detachBtn.Font = Enum.Font.SourceSansBold
detachBtn.Parent = middleRowFrame
local detachCorner = Instance.new("UICorner")
detachCorner.CornerRadius = UDim.new(0, 10)
detachCorner.Parent = detachBtn

local flingBtnFrame = Instance.new("Frame")
flingBtnFrame.Size = UDim2.new(1, 0, 0, 30)
flingBtnFrame.Position = UDim2.new(0, 0, 0, 36)
flingBtnFrame.BackgroundTransparency = 1
flingBtnFrame.Parent = bottomFrame

local startFlingBtn = Instance.new("TextButton")
startFlingBtn.Size = UDim2.new(0.48, -2, 1, 0)
startFlingBtn.Position = UDim2.new(0, 0, 0, 0)
startFlingBtn.Text = "开启甩飞"
startFlingBtn.TextScaled = false
startFlingBtn.TextSize = 22
startFlingBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
startFlingBtn.TextColor3 = Color3.fromRGB(255,255,255)
startFlingBtn.BorderSizePixel = 0
startFlingBtn.Font = Enum.Font.SourceSansSemibold
startFlingBtn.Parent = flingBtnFrame
local startFlingCorner = Instance.new("UICorner")
startFlingCorner.CornerRadius = UDim.new(0, 10)
startFlingCorner.Parent = startFlingBtn

local stopFlingBtn = Instance.new("TextButton")
stopFlingBtn.Size = UDim2.new(0.48, -2, 1, 0)
stopFlingBtn.Position = UDim2.new(0.52, 2, 0, 0)
stopFlingBtn.Text = "关闭甩飞"
stopFlingBtn.TextScaled = false
stopFlingBtn.TextSize = 22
stopFlingBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 200)
stopFlingBtn.TextColor3 = Color3.fromRGB(255,255,255)
stopFlingBtn.BorderSizePixel = 0
stopFlingBtn.Font = Enum.Font.SourceSansSemibold
stopFlingBtn.Parent = flingBtnFrame
local stopFlingCorner = Instance.new("UICorner")
stopFlingCorner.CornerRadius = UDim.new(0, 10)
stopFlingCorner.Parent = stopFlingBtn

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

startFlingBtn.MouseButton1Click:Connect(startFling)
stopFlingBtn.MouseButton1Click:Connect(stopFling)

-- 关闭按钮逻辑
closeBtn.MouseButton1Click:Connect(function()
    -- 停止所有功能
    stopAttaching()
    stopFling()
    -- 销毁UI
    screenGui:Destroy()
end)

local originalSize = mainFrame.Size
local originalPosition = mainFrame.Position

local function toggleMinimize()
    if isMinimized then
        isMinimized = false
        mainFrame.Size = originalSize
        
        -- 恢复正常状态的按钮位置（同步调整后位置）
        toggleBtn.Position = UDim2.new(1, -23, 0, 6)
        closeBtn.Position = UDim2.new(1, -2, 0, 6)
        
        -- 其他原有逻辑
        updateToggleButton()
        attachPlayerScroll.Size = UDim2.new(1, -12, 0.35, 0)
        attachPlayerScroll.Visible = true
        divider.Visible = true
        flingTitle.Visible = true
        flingTargetFrame.Visible = true
        flingOptionsList.Visible = true
        flingBtnFrame.Visible = true
        bottomFrame.Visible = true
        
        -- 恢复所有玩家按钮的可见性和位置
        for i, btn in pairs(playerButtons) do
            btn.Visible = true
            btn.Position = UDim2.new(0.025, 0, 0, (i-1) * 30)
        end
        
        refreshAttachPlayerList()
    else
        isMinimized = true
        originalSize = mainFrame.Size
        mainFrame.Size = UDim2.new(0.25, 0, 0.15, 0) -- 调整最小化高度和宽度，确保按钮可见
        
        -- 最小化状态的按钮位置（同步调整后位置）
        toggleBtn.Position = UDim2.new(1, -23, 0, 6)
        closeBtn.Position = UDim2.new(1, -2, 0, 6)
        
        -- 其他原有逻辑
        updateToggleButton()
        divider.Visible = false
        flingTitle.Visible = false
        flingTargetFrame.Visible = false
        flingOptionsList.Visible = false
        flingBtnFrame.Visible = false
        bottomFrame.Visible = false
        
        -- 调整玩家列表在最小化状态下的显示
        attachPlayerScroll.Size = UDim2.new(1, -12, 0, 80) -- 增加高度以显示更多按钮
        local visibleCount = 0
        for _, btn in pairs(playerButtons) do
            btn.Visible = false
        end
        for _, btn in pairs(playerButtons) do
            if visibleCount < 3 then -- 增加可见按钮数量
                btn.Visible = true
                btn.Position = UDim2.new(0.025, 0, 0, visibleCount * 25) -- 调整按钮间距
                visibleCount = visibleCount + 1
            end
        end
    end
end
toggleBtn.MouseButton1Click:Connect(toggleMinimize)

task.spawn(function()
    while true do
        if not isFlingOptionsOpen then
            local currentOptions = getFlingTargetOptions()
            local targetStillExists = false
            if selectedTarget ~= "全部" and selectedTarget ~= "随机" then
                local usernameToCheck = selectedTarget:match("%((.-)%)") or selectedTarget
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Name == usernameToCheck then
                        targetStillExists = true
                        break
                    end
                end
            else
                targetStillExists = true
            end
            
            if not targetStillExists then
                selectedTarget = "全部"
                flingTargetLabel.Text = "全部"
            end
        end
        task.wait(5)
    end
end)

screenGui.Enabled = true

game.Close:Connect(function()
    for _, conn in ipairs(cleanupList.connections) do
        if conn.Connected then
            conn:Disconnect()
        end
    end
    stopAttaching()
    stopFling()
end)
