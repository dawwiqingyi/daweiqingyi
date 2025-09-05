local TailParticleManager = {}

-- 粒子配置（双颜色：蓝色+粉色）
local PARTICLES = {
    {
        Name = "TailParticleBlue",
        Texture = "rbxassetid://243098098", -- 蓝色粒子贴图
        Color = ColorSequence.new(Color3.fromRGB(0, 200, 255), Color3.fromRGB(0, 60, 255)),
        Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)}),
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}),
        Lifetime = NumberRange.new(0.8, 1.5),
        Rate = 35,
        Speed = NumberRange.new(2, 4),
        Rotation = NumberRange.new(0, 360),
        SpreadAngle = Vector2.new(20, 10),
        LightEmission = 0.7,
        ZOffset = -0.3
    },
    {
        Name = "TailParticlePink",
        Texture = "rbxassetid://48771414", -- 粉色粒子贴图
        Color = ColorSequence.new(Color3.fromRGB(255, 0, 200), Color3.fromRGB(255, 120, 255)),
        Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)}),
        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}),
        Lifetime = NumberRange.new(0.7, 1.2),
        Rate = 30,
        Speed = NumberRange.new(2, 4),
        Rotation = NumberRange.new(0, 360),
        SpreadAngle = Vector2.new(15, 15),
        LightEmission = 0.8,
        ZOffset = -0.4
    }
}

-- 添加粒子（核心方法）
function TailParticleManager:AddParticle(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    -- 避免重复创建粒子
    for _, config in ipairs(PARTICLES) do
        if not hrp:FindFirstChild(config.Name) then
            local emitter = Instance.new("ParticleEmitter")
            emitter.Name = config.Name
            emitter.Texture = config.Texture
            emitter.Color = config.Color
            emitter.Size = config.Size
            emitter.Transparency = config.Transparency
            emitter.Lifetime = config.Lifetime
            emitter.Rate = config.Rate
            emitter.Speed = config.Speed
            emitter.Rotation = config.Rotation
            emitter.SpreadAngle = config.SpreadAngle
            emitter.LightEmission = config.LightEmission
            emitter.ZOffset = config.ZOffset
            emitter.Parent = hrp
        end
    end
end

-- 移除粒子（核心方法）
function TailParticleManager:RemoveParticle(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, config in ipairs(PARTICLES) do
        local emitter = hrp:FindFirstChild(config.Name)
        if emitter then emitter:Destroy() end
    end
end

return TailParticleManager
