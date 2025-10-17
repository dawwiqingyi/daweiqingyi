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
local selectedTargets = {"全部"} -- 新增：存储多个选中的目标
getgenv().FPDH = workspace.FallenPartsDestroyHeight

local cleanupList = {connections = {}}

-- 提前定义函数，避免nil值调用错误
local updateFlingButtonState = nil
local stopFling = nil

-- 防甩飞核心配置
local AntiFlingConfig = {
    Enabled = false,
    MaxVelocity = 80, -- 最大允许速度（超限判定为甩飞）
    TeleportBack = true, -- 是否传送回之前位置
    lastPositions = {}, -- 记录玩家正常位置
    playerCharConnections = {} -- 存储玩家角色连接，用于关闭时清理
}

-- 连接句柄
local antiFlingConn = nil
local playerAddedConn = nil

-- 防甩飞核心逻辑
local function startAntiFling()
    -- 初始化玩家位置记录和角色监听
    for _, player in ipairs(Players:GetPlayers()) do
        local function initPlayerCharacter(character)
            task.wait(0.5)
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart then
                -- 禁用异常状态
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                -- 记录初始位置
                AntiFlingConfig.lastPositions[player.UserId] = rootPart.Position
            end
        end

        -- 初始化当前角色
        if player.Character then
            initPlayerCharacter(player.Character)
        end

        -- 监听角色加载并存储连接
        local charConn = player.CharacterAdded:Connect(initPlayerCharacter)
        AntiFlingConfig.playerCharConnections[player.UserId] = charConn
    end

    -- 监听新玩家加入（存储连接用于关闭时清理）
    playerAddedConn = Players.PlayerAdded:Connect(function(player)
        local function initPlayerCharacter(character)
            task.wait(0.5)
            local humanoid = character:FindFirstChild("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoid and rootPart then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                -- 记录初始位置
                AntiFlingConfig.lastPositions[player.UserId] = rootPart.Position
            end
        end

        -- 监听角色加载
        local charConn = player.CharacterAdded:Connect(initPlayerCharacter)
        AntiFlingConfig.playerCharConnections[player.UserId] = charConn
    end)

    -- 心跳检测速度
    antiFlingConn = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChild("Humanoid")
                
                if rootPart and humanoid and humanoid.Health > 0 then
                    local currentVelocity = rootPart.AssemblyLinearVelocity
                    local velocityMagnitude = currentVelocity.Magnitude

                    -- 速度超限判定为甩飞
                    if velocityMagnitude > AntiFlingConfig.MaxVelocity then
                        -- 位置复位
                        if AntiFlingConfig.TeleportBack and AntiFlingConfig.lastPositions[player.UserId] then
                            -- 完全复位：位置、速度和角速度
                            rootPart.CFrame = CFrame.new(AntiFlingConfig.lastPositions[player.UserId])
                            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                            rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                            -- 额外的角色稳定处理
                            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                    else
                        -- 只在正常速度下记录位置
                        AntiFlingConfig.lastPositions[player.UserId] = rootPart.Position
                    end
                end
            end
        end
    end)
    
    -- 添加一个立即复位所有玩家的快捷键（可选）
    -- 注意：这需要在UI创建部分添加对应的按钮或快捷键处理
end

-- 停止防甩飞
local function stopAntiFling()
    -- 断开心跳检测连接
    if antiFlingConn then
        antiFlingConn:Disconnect()
        antiFlingConn = nil
    end

    -- 断开玩家加入监听连接
    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end

    -- 断开所有玩家角色连接并还原角色状态
    for userId, conn in pairs(AntiFlingConfig.playerCharConnections) do
        if conn.Connected then
            conn:Disconnect()
        end
        -- 还原对应玩家角色的状态
        local player = Players:GetPlayerByUserId(userId)
        if player and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid then
                -- 恢复禁用的角色状态
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            end
        end
    end

    -- 清空所有记录
    AntiFlingConfig.lastPositions = {}
    AntiFlingConfig.playerCharConnections = {}
end

-- 立即复位所有玩家位置的函数
local function resetAllPlayersPositions()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            
            if rootPart and humanoid and humanoid.Health > 0 then
                -- 如果有保存的位置，则复位到保存的位置
                if AntiFlingConfig.lastPositions[player.UserId] then
                    rootPart.CFrame = CFrame.new(AntiFlingConfig.lastPositions[player.UserId])
                    rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    Message("复位成功", player.Name .. " 已重置到正常位置", 2)
                else
                    -- 如果没有保存的位置，记录当前位置
                    AntiFlingConfig.lastPositions[player.UserId] = rootPart.Position
                    Message("提示", player.Name .. " 位置已记录", 2)
                end
            end
        end
    end
end

-- 更新防甩飞按钮状态
local function updateAntiFlingButtonState()
    -- 确保按钮存在
    if antiFlingBtn then
        -- 直接设置按钮状态
        if AntiFlingConfig.Enabled then
            antiFlingBtn.Text = "关闭防甩飞"
            antiFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 102, 204) -- 蓝色表示开启
        else
            antiFlingBtn.Text = "开启防甩飞"
            antiFlingBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19) -- 褐色表示关闭
        end
        -- 强制更新按钮属性
        antiFlingBtn.Text = antiFlingBtn.Text
        antiFlingBtn.BackgroundColor3 = antiFlingBtn.BackgroundColor3
    end
end

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
        if not BasePart or not BasePart:IsA("BasePart") then
            Message("甩飞失败", "目标部件无效", 3)
            return
        end
        
        local startTime = tick()
        local timeLimit = 2
        local angle = 0

        repeat
            if not isFlinging then break end
            if not BasePart or not BasePart:IsA("BasePart") or not BasePart.Parent then break end
            if not TargetHumanoid or not TargetHumanoid:IsA("Humanoid") then break end
            
            local currentVelocity = BasePart.Velocity
            if not currentVelocity then break end
            
            if currentVelocity.Magnitude < 50 then
                angle = angle + 100
                local moveDir = TargetHumanoid.MoveDirection or Vector3.new()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + moveDir * currentVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + moveDir * currentVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + moveDir * currentVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + moveDir * currentVelocity.Magnitude / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, 0) + moveDir, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0) + moveDir, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
            else
                local walkSpeed = TargetHumanoid.WalkSpeed or 16
                FPos(BasePart, CFrame.new(0, 1.5, walkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, -walkSpeed), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, 1.5, walkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                
                if TargetRoot and TargetRoot:IsA("BasePart") then
                    local rootVelocity = TargetRoot.Velocity
                    if rootVelocity then
                        FPos(BasePart, CFrame.new(0, 1.5, rootVelocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -rootVelocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, rootVelocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                    end
                end
                
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        until not isFlinging or (BasePart and BasePart:IsA("BasePart") and BasePart.Velocity and BasePart.Velocity.Magnitude > 500) or not BasePart or not BasePart.Parent or BasePart.Parent ~= TargetChar or TargetPlayer.Parent ~= Players or (TargetHumanoid and TargetHumanoid.Sit) or (LocalHumanoid and LocalHumanoid.Health <= 0) or tick() > startTime + timeLimit
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
    
    -- 检查防甩飞是否开启
    if AntiFlingConfig.Enabled then
        Message("甩飞失败", "请关闭防甩飞后再开启甩飞", 3)
        return
    end

    if not LocalPlayer.Character then
        Message("甩飞失败", "请先加载角色", 3)
        return
    end

    isFlinging = true
    Message("甩飞开启", "目标数量：" .. #selectedTargets, 2)
    
    -- 更新按钮状态
    updateFlingButtonState()

    flingConnection = task.spawn(function()
        while isFlinging do
            if #selectedTargets == 0 then
                Message("甩飞失败", "请先选择目标", 3)
                stopFling()
                return
            end
            
            -- 处理多个选中的目标
            for _, targetName in ipairs(selectedTargets) do
                if not isFlinging then break end
                
                if targetName == "全部" then
                    -- 处理"全部"选项
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
                elseif targetName == "随机" then
                    -- 处理"随机"选项
                    local allTargets = Players:GetPlayers()
                    table.remove(allTargets, table.find(allTargets, LocalPlayer))
                    if #allTargets > 0 then
                        local randomTarget = allTargets[math.random(1, #allTargets)]
                        SkidFling(randomTarget)
                        task.wait(0.5)
                    end
                else
                    -- 处理单个玩家
                    local playerTarget = nil
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local displayName = player.DisplayName .. " (" .. player.Name .. ")"
                            if displayName == targetName then
                                playerTarget = player
                                break
                            end
                        end
                    end
                    
                    if playerTarget then
                        SkidFling(playerTarget)
                        task.wait(0.5)
                    end
                end
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
    
    -- 更新按钮状态
    updateFlingButtonState()

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
mainFrame.Size = UDim2.new(0.30, 0, 0.55, 0) -- 减小高度
mainFrame.Position = UDim2.new(0.16, 0, 0.16, 0) -- 向右移动20%
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
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 255) -- 紫色
    else
        toggleBtn.Text = "-" -- 正常状态显示-按钮
        toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 255) -- 紫色
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
attachPlayerScroll.Size = UDim2.new(1, -12, 0.65, 0)
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
            btn.BackgroundColor3 = Color3.fromRGB(173, 216, 230)
            btn.Text = ""
            btn.BorderSizePixel = 1
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
            nameLabel.TextColor3 = Color3.fromRGB(150, 0, 255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextScaled = false
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.SourceSansSemibold
            nameLabel.Parent = btn

            btn:SetAttribute("PlayerName", player.Name)

            btn.MouseButton1Click:Connect(function()
                selectedPlayer = player
                for _, b in playerButtons do
                    b.BackgroundColor3 = Color3.fromRGB(210, 180, 140)
                end
                btn.BackgroundColor3 = Color3.fromRGB(135, 206, 235)
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
divider.Position = UDim2.new(0, 6, 0, 0.37)
divider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

local flingTitle = Instance.new("TextLabel")
flingTitle.Size = UDim2.new(1, -12, 0, 20)
flingTitle.Position = UDim2.new(0, 6, 0, 0.39)
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
flingTargetFrame.Position = UDim2.new(0, 6, 0, 0.44)
flingTargetFrame.BackgroundColor3 = Color3.fromRGB(173, 216, 230)
flingTargetFrame.BackgroundTransparency = 0
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
flingOptionsList.Position = UDim2.new(0, 6, 0, 0.44 + 25.5/55)
flingOptionsList.BackgroundColor3 = Color3.fromRGB(173, 216, 230)
flingOptionsList.BackgroundTransparency = 0
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
    toggleBtn.Visible = true -- 确保展开甩飞选项时最小化按钮可见
    
    if isFlingOptionsOpen then
        for _, child in ipairs(flingOptionsList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        local options, playerInfo = getFlingTargetOptions()
        local y = 0
        local maxHeight = 250
        
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, 0, 0, 25.5) -- 减小15%
            optBtn.Position = UDim2.new(0, 0, 0, y)
            
            local isSelected = table.find(selectedTargets, opt) ~= nil
            if not isSelected and playerInfo[selectedTarget] and playerInfo[opt] and playerInfo[opt].name == playerInfo[selectedTarget].name then
                isSelected = true
            end
            
            optBtn.BackgroundColor3 = isSelected and Color3.fromRGB(135, 206, 235) or Color3.fromRGB(173, 216, 230)
            optBtn.BackgroundTransparency = 0
            optBtn.Text = ""
            optBtn.TextScaled = false
            optBtn.TextSize = 12 -- 略微减小字体
            optBtn.Font = Enum.Font.SourceSans
            optBtn.BorderSizePixel = 0
            optBtn.Parent = flingOptionsList
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = optBtn
            
            -- 新增：复选框
            local checkbox = Instance.new("TextLabel")
            checkbox.Size = UDim2.new(0, 20, 0, 20)
            checkbox.Position = UDim2.new(0, 2, 0.5, -10)
            checkbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            checkbox.BackgroundTransparency = 0
            checkbox.Text = isSelected and "✓" or ""
            checkbox.TextColor3 = Color3.fromRGB(0, 150, 0)
            checkbox.TextScaled = true
            checkbox.TextSize = 14
            checkbox.Font = Enum.Font.SourceSansBold
            checkbox.BorderSizePixel = 1
            checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
            checkbox.Parent = optBtn
            local checkboxCorner = Instance.new("UICorner")
            checkboxCorner.CornerRadius = UDim.new(0, 4)
            checkboxCorner.Parent = checkbox
            
            if opt ~= "全部" and opt ~= "随机" and playerInfo[opt] then
                local thumb = Instance.new("ImageLabel")
                thumb.Size = UDim2.new(0, 20.4, 0, 20.4) -- 减小15%
                thumb.Position = UDim2.new(0, 25, 0, 2.55)
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
                nameLabel.Size = UDim2.new(1, -55, 1, 0)
                nameLabel.Position = UDim2.new(0, 50, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = opt .. "甩飞"
                nameLabel.TextColor3 = Color3.fromRGB(0, 0, 139) -- 深蓝色
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextScaled = false
                nameLabel.TextSize = 17 -- 略微减小字体
                nameLabel.Font = Enum.Font.SourceSansBold 
                nameLabel.Parent = optBtn
            else
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -28, 1, 0)
                nameLabel.Position = UDim2.new(0, 28, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = opt .. "甩飞"
                nameLabel.TextColor3 = Color3.fromRGB(150, 0, 255)
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.TextScaled = false
                nameLabel.TextSize = 14 -- 略微减小字体
                nameLabel.Font = Enum.Font.SourceSansBold
                nameLabel.Parent = optBtn
            end
            
            optBtn.MouseButton1Click:Connect(function()
                -- 处理多选逻辑
                local index = table.find(selectedTargets, opt)
                
                -- 特殊处理"全部"选项
                if opt == "全部" then
                    if index then
                        -- 取消选中"全部"，清空其他选择
                        table.clear(selectedTargets)
                        selectedTarget = ""
                    else
                        -- 选中"全部"，清空其他选择
                        table.clear(selectedTargets)
                        table.insert(selectedTargets, opt)
                        selectedTarget = opt
                    end
                else
                    -- 处理其他选项
                    local allIndex = table.find(selectedTargets, "全部")
                    if allIndex then
                        -- 如果已选中"全部"，先移除它
                        table.remove(selectedTargets, allIndex)
                    end
                    
                    if index then
                        -- 取消选中
                        table.remove(selectedTargets, index)
                    else
                        -- 添加选中
                        table.insert(selectedTargets, opt)
                    end
                    
                    -- 更新selectedTarget（保持兼容性）
                    selectedTarget = #selectedTargets > 0 and selectedTargets[1] or ""
                end
                
                -- 更新显示的目标文本
                if #selectedTargets == 0 then
                    flingTargetLabel.Text = "未选择"
                elseif #selectedTargets == 1 then
                    flingTargetLabel.Text = selectedTargets[1]
                else
                    flingTargetLabel.Text = "已选择 " .. #selectedTargets .. " 个目标"
                end
                
                -- 重新生成选项列表以更新复选框状态
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

-- 添加点击flingTitle时的功能
flingTitle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        -- 直接实现与flingArrowBtn相同的功能
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
                
                local isSelected = table.find(selectedTargets, opt) ~= nil
                if not isSelected and playerInfo[selectedTarget] and playerInfo[opt] and playerInfo[opt].name == playerInfo[selectedTarget].name then
                    isSelected = true
                end
                
                optBtn.BackgroundColor3 = isSelected and Color3.fromRGB(135, 206, 235) or Color3.fromRGB(173, 216, 230)
                optBtn.BackgroundTransparency = 0 -- 设置不透明
                optBtn.Text = ""
                optBtn.TextScaled = false
                optBtn.TextSize = 12 -- 略微减小字体
                optBtn.Font = Enum.Font.SourceSans
                optBtn.BorderSizePixel = 0
                optBtn.Parent = flingOptionsList
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 8)
                corner.Parent = optBtn
                
                -- 新增：复选框
                local checkbox = Instance.new("TextLabel")
                checkbox.Size = UDim2.new(0, 20, 0, 20)
                checkbox.Position = UDim2.new(0, 2, 0.5, -10)
                checkbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                checkbox.BackgroundTransparency = 0
                checkbox.Text = isSelected and "✓" or ""
                checkbox.TextColor3 = Color3.fromRGB(0, 150, 0)
                checkbox.TextScaled = true
                checkbox.TextSize = 14
                checkbox.Font = Enum.Font.SourceSansBold
                checkbox.BorderSizePixel = 1
                checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                checkbox.Parent = optBtn
                local checkboxCorner = Instance.new("UICorner")
                checkboxCorner.CornerRadius = UDim.new(0, 4)
                checkboxCorner.Parent = checkbox
                
                if opt ~= "全部" and opt ~= "随机" and playerInfo[opt] then
                    local thumb = Instance.new("ImageLabel")
                    thumb.Size = UDim2.new(0, 20.4, 0, 20.4) -- 减小15%
                    thumb.Position = UDim2.new(0, 25, 0, 2.55)
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
                    nameLabel.Size = UDim2.new(1, -55, 1, 0)
                    nameLabel.Position = UDim2.new(0, 50, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = opt .. "甩飞"
                    nameLabel.TextColor3 = Color3.fromRGB(0, 0, 139) -- 深蓝色
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.TextScaled = false
                    nameLabel.TextSize = 17 -- 略微减小字体
                    nameLabel.Font = Enum.Font.SourceSansBold 
                    nameLabel.Parent = optBtn
                else
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, -28, 1, 0)
                    nameLabel.Position = UDim2.new(0, 28, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = opt .. "甩飞"
                    nameLabel.TextColor3 = Color3.fromRGB(150, 0, 255)
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.TextScaled = false
                    nameLabel.TextSize = 14 -- 略微减小字体
                    nameLabel.Font = Enum.Font.SourceSansBold
                    nameLabel.Parent = optBtn
                end
                
                optBtn.MouseButton1Click:Connect(function()
                    -- 处理多选逻辑
                    local index = table.find(selectedTargets, opt)
                    
                    -- 特殊处理"全部"选项
                    if opt == "全部" then
                        if index then
                            -- 取消选中"全部"，清空其他选择
                            table.clear(selectedTargets)
                            selectedTarget = ""
                        else
                            -- 选中"全部"，清空其他选择
                            table.clear(selectedTargets)
                            table.insert(selectedTargets, opt)
                            selectedTarget = opt
                        end
                    else
                        -- 处理其他选项
                        local allIndex = table.find(selectedTargets, "全部")
                        if allIndex then
                            -- 如果已选中"全部"，先移除它
                            table.remove(selectedTargets, allIndex)
                        end
                        
                        if index then
                            -- 取消选中
                            table.remove(selectedTargets, index)
                        else
                            -- 添加选中
                            table.insert(selectedTargets, opt)
                        end
                        
                        -- 更新selectedTarget（保持兼容性）
                        selectedTarget = #selectedTargets > 0 and selectedTargets[1] or ""
                    end
                    
                    -- 更新显示的目标文本
                    if #selectedTargets == 0 then
                        flingTargetLabel.Text = "未选择"
                    elseif #selectedTargets == 1 then
                        flingTargetLabel.Text = selectedTargets[1]
                    else
                        flingTargetLabel.Text = "已选择 " .. #selectedTargets .. " 个目标"
                    end
                    
                    -- 重新生成选项列表以更新复选框状态
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
    end
end)

local bottomFrame = Instance.new("Frame")
bottomFrame.Size = UDim2.new(1, -12, 0, 66)
bottomFrame.Position = UDim2.new(0, 6, 1, -70)
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

-- 创建防甩飞按钮（放在左侧）
local antiFlingBtn = Instance.new("TextButton")
antiFlingBtn.Size = UDim2.new(0.48, -2, 1, 0)
antiFlingBtn.Position = UDim2.new(0, 0, 0, 0)
antiFlingBtn.Text = "开启防甩飞" -- 初始状态为关闭
antiFlingBtn.TextScaled = false
antiFlingBtn.TextSize = 20
antiFlingBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19) -- 初始为褐色
antiFlingBtn.TextColor3 = Color3.fromRGB(255,255,255)
antiFlingBtn.BorderSizePixel = 0
antiFlingBtn.Font = Enum.Font.SourceSansSemibold
antiFlingBtn.Parent = flingBtnFrame
local antiFlingCorner = Instance.new("UICorner")
antiFlingCorner.CornerRadius = UDim.new(0, 10)
antiFlingCorner.Parent = antiFlingBtn

-- 创建甩飞切换按钮（放在右侧）
local toggleFlingBtn = Instance.new("TextButton")
toggleFlingBtn.Size = UDim2.new(0.48, -2, 1, 0)
toggleFlingBtn.Position = UDim2.new(0.52, 2, 0, 0)
toggleFlingBtn.Text = "开启甩飞" -- 初始状态为开启
toggleFlingBtn.TextScaled = false
toggleFlingBtn.TextSize = 22
toggleFlingBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0) -- 初始为黄色
toggleFlingBtn.TextColor3 = Color3.fromRGB(255,255,255)
toggleFlingBtn.BorderSizePixel = 0
toggleFlingBtn.Font = Enum.Font.SourceSansSemibold
toggleFlingBtn.Parent = flingBtnFrame
local toggleFlingCorner = Instance.new("UICorner")
toggleFlingCorner.CornerRadius = UDim.new(0, 10)
toggleFlingCorner.Parent = toggleFlingBtn

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

-- 甩飞切换按钮点击事件
updateFlingButtonState = function()
    if toggleFlingBtn then -- 检查toggleFlingBtn是否存在
        if isFlinging then
            toggleFlingBtn.Text = "关闭甩飞"
            toggleFlingBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 200) -- 紫色表示开启中
        else
            toggleFlingBtn.Text = "开启甩飞"
            toggleFlingBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0) -- 黄色表示未开启
        end
    end
end

-- 初始化按钮状态
updateFlingButtonState()
updateAntiFlingButtonState()

-- 防甩飞按钮点击事件
antiFlingBtn.MouseButton1Click:Connect(function()
    -- 切换状态
    AntiFlingConfig.Enabled = not AntiFlingConfig.Enabled
    
    -- 直接更新按钮文本和颜色，不依赖updateAntiFlingButtonState函数
    if AntiFlingConfig.Enabled then
        antiFlingBtn.Text = "关闭防甩飞"
        antiFlingBtn.BackgroundColor3 = Color3.fromRGB(0, 102, 204) -- 蓝色表示开启
        startAntiFling()
        Message("防甩飞已开启", "速度超过" .. AntiFlingConfig.MaxVelocity .. "将自动防御", 2)
    else
        antiFlingBtn.Text = "开启防甩飞"
        antiFlingBtn.BackgroundColor3 = Color3.fromRGB(139, 69, 19) -- 褐色表示关闭
        stopAntiFling()
        Message("防甩飞已关闭", "不再自动防御甩飞攻击", 2)
    end
    
    -- 强制应用更改
    antiFlingBtn.Text = antiFlingBtn.Text
    antiFlingBtn.BackgroundColor3 = antiFlingBtn.BackgroundColor3
end)

-- 甩飞按钮点击事件
toggleFlingBtn.MouseButton1Click:Connect(function()
    if isFlinging then
        stopFling()
    else
        startFling()
    end
end)

-- 关闭按钮逻辑
closeBtn.MouseButton1Click:Connect(function()
    -- 停止所有功能
    stopAttaching()
    stopFling()
    if AntiFlingConfig.Enabled then
        stopAntiFling()
    end
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
        -- 最大化时默认收起甩飞UI
        isFlingOptionsOpen = false
        flingOptionsList.Visible = false
        flingArrowBtn.Text = ">"
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
        mainFrame.Size = UDim2.new(0.30, 0, 0, 30) -- 最小化高度与标题栏相同
        
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
        
        -- 最小化时不显示玩家列表
        attachPlayerScroll.Visible = false
        for _, btn in pairs(playerButtons) do
            btn.Visible = false
        end
        -- 初始化visibleCount变量
        local visibleCount = 0
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
