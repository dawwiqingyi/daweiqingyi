-- 远程代码示例（需与本地变量名一致）
-- 1. 选中浅绿色按钮（替换本地默认的浅紫色）
lightPurpleBtn.BorderSizePixel = 0 -- 取消原选中
lightGreenBtn.BorderSizePixel = 2
lightGreenBtn.BorderColor3 = Color3.fromRGB(255, 255, 255)
-- 2. 应用浅绿色主题（替换本地默认的浅黑色）
updateThemeColor(themes.lightGreen)

-- 3. 延迟同步移动速度分区颜色（逻辑与本地一致，可按需修改）
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
