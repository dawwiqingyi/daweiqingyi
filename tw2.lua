@@ -1,17 +1,35 @@

local TailParticleManager = {}

-- 粒子配置，可自行替换贴图/颜色
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
        Texture = "rbxassetid://48771414", -- 粉色粒子贴图，可换自己喜欢的
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
local PARTICLE_NAME = "TailParticle"
local PARTICLE_PROPERTIES = {
    Texture = "rbxassetid://243098098", -- 可替换为你喜欢的粒子贴图
    Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 255)),
    Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)}),
    Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)}),
    Lifetime = NumberRange.new(0.5, 1.2),
    Rate = 40,
    Speed = NumberRange.new(2, 4),
    Rotation = NumberRange.new(0, 360),
    SpreadAngle = Vector2.new(10, 10),
    LightEmission = 0.7,
}

function TailParticleManager:AddParticle(character)
@@ -18,13 +36,25 @@

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if hrp:FindFirstChild(PARTICLE_NAME) then return end

    -- 添加两种颜色粒子
    for i, config in PARTICLES do
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
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = PARTICLE_NAME
    for k, v in PARTICLE_PROPERTIES do
        emitter[k] = v
    end
    emitter.Parent = hrp
end

function TailParticleManager:RemoveParticle(character)
@@ -31,8 +61,10 @@

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for i, config in PARTICLES do
        local emitter = hrp:FindFirstChild(config.Name)
        if emitter then
            emitter:Destroy()
        end
    local emitter = hrp:FindFirstChild(PARTICLE_NAME)
    if emitter then
        emitter:Destroy()
    end
end


