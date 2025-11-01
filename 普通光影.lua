-- Roblox Graphics Enhancher
-- 防止重复加载检查
if _G.RTXGraphicsEnabled then
	print("高亮光影已经加载，跳过重复加载")
	return
end

local light = game.Lighting
-- 保存原始光照设置以便关闭时恢复
local originalLightingSettings = {
	Ambient = light.Ambient,
	Brightness = light.Brightness,
	ColorShift_Bottom = light.ColorShift_Bottom,
	ColorShift_Top = light.ColorShift_Top,
	EnvironmentDiffuseScale = light.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = light.EnvironmentSpecularScale,
	GlobalShadows = light.GlobalShadows,
	OutdoorAmbient = light.OutdoorAmbient,
	ShadowSoftness = light.ShadowSoftness,
	GeographicLatitude = light.GeographicLatitude,
	ExposureCompensation = light.ExposureCompensation
}

-- 清除现有效果
for i, v in pairs(light:GetChildren()) do
	v:Destroy()
end

-- 创建效果表以便后续管理
local createdEffects = {}

local ter = workspace.Terrain
local color = Instance.new("ColorCorrectionEffect")
local bloom = Instance.new("BloomEffect")
local sun = Instance.new("SunRaysEffect")
local blur = Instance.new("BlurEffect")

color.Parent = light
bloom.Parent = light
sun.Parent = light
blur.Parent = light

-- 将创建的效果添加到表中
createdEffects["color"] = color
createdEffects["bloom"] = bloom
createdEffects["sun"] = sun
createdEffects["blur"] = blur

-- enable or disable shit

local config = {

	Terrain = true;
	ColorCorrection = true;
	Sun = true;
	Lighting = true;
	BloomEffect = true;
	
}

-- settings {

color.Enabled = false
color.Contrast = 0.15
color.Brightness = 0.1
color.Saturation = 0.25
color.TintColor = Color3.fromRGB(255, 222, 211)

bloom.Enabled = false
bloom.Intensity = 0.1

sun.Enabled = false
sun.Intensity = 0.2
sun.Spread = 1

bloom.Enabled = false
bloom.Intensity = 0.05
bloom.Size = 32
bloom.Threshold = 1

blur.Enabled = false
blur.Size = 6

-- settings }


if config.ColorCorrection then
	color.Enabled = true
end


if config.Sun then
	sun.Enabled = true
end


if config.Terrain then
	-- settings {
	ter.WaterWaveSize = 0.1
	ter.WaterWaveSpeed = 22
	ter.WaterTransparency = 0.9
	ter.WaterReflectance = 0.05
	-- settings }
end
if config.Lighting then
	-- settings {
	light.Ambient = Color3.fromRGB(0, 0, 0)
	light.Brightness = 4
	light.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	light.ColorShift_Top = Color3.fromRGB(0, 0, 0)
	light.ExposureCompensation = 0
	light.FogColor = Color3.fromRGB(132, 132, 132)
	light.GlobalShadows = true
	light.OutdoorAmbient = Color3.fromRGB(112, 117, 128)
	light.Outlines = false
	-- settings }
end
local a = game.Lighting
a.Ambient = Color3.fromRGB(33, 33, 33)
a.Brightness = 5.69
a.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
a.ColorShift_Top = Color3.fromRGB(255, 247, 237)
a.EnvironmentDiffuseScale = 0.105
a.EnvironmentSpecularScale = 0.522
a.GlobalShadows = true
a.OutdoorAmbient = Color3.fromRGB(51, 54, 67)
a.ShadowSoftness = 0.18
a.GeographicLatitude = -15.525
a.ExposureCompensation = 0.75
b.Enabled = true
b.Intensity = 0.99
b.Size = 9999 
b.Threshold = 0
local c = Instance.new("ColorCorrectionEffect", a)
c.Brightness = 0.015
c.Contrast = 0.25
c.Enabled = true
c.Saturation = 0.2
c.TintColor = Color3.fromRGB(217, 145, 57)
if getgenv().mode == "Summer" then
   c.TintColor = Color3.fromRGB(255, 220, 148)
elseif getgenv().mode == "Autumn" then
   c.TintColor = Color3.fromRGB(217, 145, 57)
else
   warn("No mode selected!")
   print("Please select a mode")
   b:Destroy()
   c:Destroy()
end
local d = Instance.new("DepthOfFieldEffect", a)
d.Enabled = true
d.FarIntensity = 0.077
d.FocusDistance = 21.54
d.InFocusRadius = 20.77
d.NearIntensity = 0.277
local e = Instance.new("ColorCorrectionEffect", a)
e.Brightness = 0
e.Contrast = -0.07
e.Saturation = 0
e.Enabled = true
e.TintColor = Color3.fromRGB(255, 247, 239)
local e2 = Instance.new("ColorCorrectionEffect", a)
e2.Brightness = 0.2
e2.Contrast = 0.45
e2.Saturation = -0.1
e2.Enabled = true
e2.TintColor = Color3.fromRGB(255, 255, 255)
local s = Instance.new("SunRaysEffect", a)
s.Enabled = true
s.Intensity = 0.01
s.Spread = 0.146

-- 将额外创建的效果添加到表中
createdEffects["b"] = b
createdEffects["c"] = c
createdEffects["d"] = d
createdEffects["e"] = e
createdEffects["e2"] = e2
createdEffects["s"] = s

-- 保存地形原始设置
local originalTerrainSettings = {
	WaterWaveSize = ter.WaterWaveSize,
	WaterWaveSpeed = ter.WaterWaveSpeed,
	WaterTransparency = ter.WaterTransparency,
	WaterReflectance = ter.WaterReflectance
}

-- 高亮光影状态变量
_G.RTXGraphicsEnabled = true

-- 关闭高亮光影的函数
function _G.DisableRTXGraphics()
	print("正在关闭高亮光影...")
	
	-- 销毁所有创建的效果
	for name, effect in pairs(createdEffects) do
		if effect and effect:IsA("Instance") then
			effect:Destroy()
		end
	end
	
	-- 清空效果表
	createdEffects = {}
	
	-- 恢复原始光照设置
	for property, value in pairs(originalLightingSettings) do
		if light and light[property] ~= nil then
			light[property] = value
		end
	end
	
	-- 恢复地形原始设置
	for property, value in pairs(originalTerrainSettings) do
		if ter and ter[property] ~= nil then
			ter[property] = value
		end
	end
	
	_G.RTXGraphicsEnabled = false
	print("高亮光影已关闭！")
end

-- 开启高亮光影的函数
function _G.EnableRTXGraphics()
	if _G.RTXGraphicsEnabled then
		print("高亮光影已经开启！")
		return
	end
	
	print("正在开启高亮光影...")
	
	-- 重新加载高亮光影脚本
	local success = pcall(function()
		local rtxCode = readfile("高亮光影")
		if rtxCode then
			loadstring(rtxCode)()
		else
			warn("高亮光影文件未找到")
		end
	end)
	
	if not success then
		warn("高亮光影开启失败")
	end
end

-- 切换高亮光影状态的函数
function _G.ToggleRTXGraphics()
	if _G.RTXGraphicsEnabled then
		_G.DisableRTXGraphics()
	else
		_G.EnableRTXGraphics()
	end
end

-- 获取高亮光影状态的函数
function _G.GetRTXGraphicsStatus()
	return _G.RTXGraphicsEnabled
end

print("高亮光影已加载！作者：BrickoIcko")
print("可用命令：")
print("  _G.DisableRTXGraphics() - 关闭高亮光影")
print("  _G.EnableRTXGraphics() - 开启高亮光影")
print("  _G.ToggleRTXGraphics() - 切换高亮光影状态")
print("  _G.GetRTXGraphicsStatus() - 获取高亮光影状态")
