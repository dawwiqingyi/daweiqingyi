-- 远程代码优化版
-- 1. 先关闭彩虹文本效果（避免文本颜色被覆盖）
if rainbowConn and rainbowConn.Connected then
    rainbowConn:Disconnect()
end

-- 2. 手动设置文本颜色为固定值（与浅绿色主题匹配，可选白色）
titleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
for i = 1, #sectionLabels do
    sectionLabels[i].TextColor3 = Color3.fromRGB(255, 255, 255)
end
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

-- 3. 按钮高亮和主题更新（保持不变）
lightPurpleBtn.BorderSizePixel = 0
lightGreenBtn.BorderSizePixel = 2
lightGreenBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
updateThemeColor(themes.lightGreen)

-- 4. 同步速度分区颜色（保持不变）
task.wait(0.1)
if speedContent then
    local contentTheme = themes.lightGreen:lerp(Color3.fromRGB(255,255,255), 0.4)
    speedContent.BackgroundColor3 = contentTheme
    speedContent.BackgroundTransparency = 0.1
    for _, child in ipairs(speedContent:GetChildren()) do
        if child.Name:find("SpeedButton_") and child:IsA("TextButton") then
            child.BackgroundColor3 = btnBlue
            local redDot = child:FindFirstChild("RedDot")
            if redDot then redDot.BackgroundColor3 = redDotColor end
        end
    end
end
--[[
 lightPurple = Color3.fromRGB(180, 120, 255),  -- 浅紫色（默认）

    lightBlue = Color3.fromRGB(100, 180, 255),    -- 浅蓝色

    lightGreen = Color3.fromRGB(120, 255, 180),   -- 浅绿色

    lightOrange = Color3.fromRGB(255, 180, 100),  -- 浅橘色

    lightRed = Color3.fromRGB(255, 120, 120),     -- 浅红色

    lightCyan = Color3.fromRGB(0, 102, 204),    -- 浅青色

    coffee = Color3.fromRGB(101, 67, 33),         -- 咖啡色

    lightBlack = Color3.fromRGB(30, 30, 30),      -- 浅黑色

    lightBrown = Color3.fromRGB(180, 150, 120)    -- 浅咖啡色
    
    ]]
