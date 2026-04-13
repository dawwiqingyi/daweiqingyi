Players = game:GetService("Players")
RunService = game:GetService("RunService")
TweenService = game:GetService("TweenService")
HttpService = game:GetService("HttpService")
UserInputService = game:GetService("UserInputService")

LocalPlayer = Players.LocalPlayer
PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

API_KEY = "YOUR_API_KEY_HERE"
BASE_URL = "http://kpl.wyp8.top/cs/k.php"
FIXED_ROOM = "Foodie Base"
FIXED_API_KEY = "P9&Wa3$Xf5!Cy1#Vb7@Ze2*Nd4^Qk6%Sr8+Mt0=Gh9"

local function getSelfChatName()
    local displayName = LocalPlayer.DisplayName
    local name = LocalPlayer.Name
    if displayName and displayName ~= "" and displayName ~= name then
        return displayName .. "(" .. name .. ")"
    end
    return name
end

currentRoom = nil
userName = getSelfChatName()
isPolling = false
messageCache = {}
messageUiByKey = {}
pendingSelfMessages = {}
selfMessageWindow = 10
pendingSelfDms = {}
selfDmWindow = 20
avatarCache = {}
defaultAvatarUrl = "rbxassetid://0"
currentTimeFilter = 2
isMinimized = false
hasUnread = false
unreadDot = nil
mentionDot = nil
hasMentionUnread = false
replyDot = nil
hasReplyUnread = false
dmDot = nil
hasDmUnread = false
needForceOpenAll = false
sessionJoinTime = 0
dmCache = {}
dmInitialized = false
dmTargetName = nil

particleCount = 40
connectionDistance = 80
maxLines = 60

accentColor = Color3.fromRGB(120, 140, 255)
accentColorLight = Color3.fromRGB(132, 155, 255)
accentColorDark = Color3.fromRGB(72, 90, 210)
starColor = Color3.fromRGB(160, 120, 255)
meteorColor = Color3.fromRGB(255, 210, 255)
backgroundColor = Color3.fromRGB(40, 42, 54)
backgroundSecondary = Color3.fromRGB(52, 55, 68)
backgroundTertiary = Color3.fromRGB(64, 68, 84)
textColor = Color3.fromRGB(255, 255, 255)
textMuted = Color3.fromRGB(200, 206, 220)
successColor = Color3.fromRGB(87, 242, 135)
errorColor = Color3.fromRGB(237, 66, 69)
chatFontColor = starColor
selfFontColor = chatFontColor
FONT_PREFIX = "##FONT##|"
messageSentColor = Color3.fromRGB(220, 220, 220)
selfBubbleColor = messageSentColor
selfBubbleStyle = selfBubbleColor
selfBubbleBorderId = 0
selfAvatarBorderId = 0
messageReceivedColor = Color3.fromRGB(220, 220, 220)
CHAT_COLOR_CONFIG_FILE = "ThirdGenChatColorConfig.json"
randomColorEnabled = false
CHAT_SETTINGS_FILE = "ThirdGenChatSettings.json"
autoPopupEnabled = true
startMinimizedOnLoad = false
BACKGROUND_CACHE_FOLDER = "吃吃聊天背景_pro"
BACKGROUND_REMOTE_BASE_URL = "http://kpl.wyp8.top/cs/bg/"
BACKGROUND_REMOTE_LIST_ACTION = "get_backgrounds"
backgroundSetting = nil
DEFAULT_BACKGROUND_URL = "http://kpl.wyp8.top/cs/bg/3.png"
DEFAULT_BACKGROUND_FILE = "3.png"
DEFAULT_BACKGROUND_SETTING = { kind = "remote", url = DEFAULT_BACKGROUND_URL, fileName = DEFAULT_BACKGROUND_FILE }
SYSTEM_NAME = "Roblox"

local function isSystemName(name)
    return name == SYSTEM_NAME or name == "系统"
end

SPAM_LIMIT = 8
SPAM_MUTE_SECONDS = 120
VIOLATION_MUTE_SECONDS = 300
SYSTEM_BUBBLE_COLOR = Color3.fromRGB(245, 245, 245)
VIOLATION_WINDOW_SECONDS = 3600
violationStateByName = {}

FORBIDDEN_WORDS = {
    "傻逼",
    "傻b",
    "sb",
    "nmsl",
    "cnm",
    "操你妈",
	"煞笔",
	"沙币",
	"shabi",
    "草泥马",
    "草你妈",
    "你妈的",
    "你妈逼",
    "妈逼",
    "妈b",
    "日你妈",
    "去死",
    "死妈",
    "死全家",
    "脑残",
    "废物",
    "垃圾",
    "狗东西",
    "你妈死了",
    "fuck",
    "fuk",
    "fck",
    "shit"
}

local function findForbiddenWord(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end
    local lower = string.lower(text)
    for _, w in ipairs(FORBIDDEN_WORDS) do
        if type(w) == "string" and w ~= "" then
            local lw = string.lower(w)
            if lower:find(lw, 1, true) then
                return w
            end
        end
    end
    return nil
end

local function getViolationStageSeconds(stage)
    if stage == 1 then
        return 300
    end
    if stage == 2 then
        return 600
    end
    if stage == 3 then
        return 1800
    end
    return 86400
end

local function getViolationMuteSecondsForName(name, now)
    if type(name) ~= "string" or name == "" then
        return VIOLATION_MUTE_SECONDS, 1
    end
    if type(now) ~= "number" then
        now = os.time()
    end
    local state = violationStateByName[name]
    if type(state) ~= "table" or type(state.windowStart) ~= "number" or type(state.count) ~= "number" then
        state = { windowStart = now, count = 0 }
        violationStateByName[name] = state
    end
    if (now - state.windowStart) > VIOLATION_WINDOW_SECONDS then
        state.windowStart = now
        state.count = 0
    end
    state.count = state.count + 1
    local stage = state.count
    return getViolationStageSeconds(stage), stage
end

local function formatMuteDuration(seconds)
    if seconds >= 86400 then
        return "一天"
    end
    if seconds >= 1800 then
        return "半个小时"
    end
    if seconds >= 600 then
        return "十分钟"
    end
    return "五分钟"
end

local function colorToString(c)
    if typeof(c) ~= "Color3" then
        return ""
    end
    local r = math.clamp(math.floor(c.R * 255 + 0.5), 0, 255)
    local g = math.clamp(math.floor(c.G * 255 + 0.5), 0, 255)
    local b = math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
    return string.format("%d,%d,%d", r, g, b)
end

local function stringToColor(str)
    if type(str) ~= "string" then
        return nil
    end
    local r, g, b = str:match("(%d+),(%d+),(%d+)")
    if r and g and b then
        return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
    end
    return nil
end

local function parseBubbleStyle(str)
    if type(str) ~= "string" or str == "" then
        return nil
    end
    local animId = nil
    do
        local idStr = str:match(";ba=(%d+)")
        if idStr then
            animId = tonumber(idStr)
            if animId and animId <= 0 then
                animId = nil
            end
        end
    end
    local mainPart = str:match("^[^;]+") or str
    local nStr, rest = mainPart:match("^g(%d):(.+)$")
    if nStr and rest then
        local n = tonumber(nStr)
        if n == 2 or n == 3 then
            local colors = {}
            for part in rest:gmatch("[^|]+") do
                local c = stringToColor(part)
                if c then
                    table.insert(colors, c)
                end
            end
            if #colors >= 2 then
                if #colors > n then
                    while #colors > n do
                        table.remove(colors)
                    end
                end
                local style = { type = "gradient", colors = colors }
                if animId then
                    style.animId = animId
                end
                return style
            end
        end
        return nil
    end
    return stringToColor(mainPart)
end

local function srgbToLinear(v)
    if v <= 0.04045 then
        return v / 12.92
    end
    return ((v + 0.055) / 1.055) ^ 2.4
end

local function relativeLuminance(c)
    if typeof(c) ~= "Color3" then
        return 0
    end
    local r = srgbToLinear(c.R)
    local g = srgbToLinear(c.G)
    local b = srgbToLinear(c.B)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

local function contrastRatio(a, b)
    local la = relativeLuminance(a)
    local lb = relativeLuminance(b)
    local lighter = math.max(la, lb)
    local darker = math.min(la, lb)
    return (lighter + 0.05) / (darker + 0.05)
end

local function parseBubbleBorderId(str)
    if type(str) ~= "string" or str == "" then
        return nil
    end
    local idStr = str:match(";bd=(%d+)")
    if idStr then
        return tonumber(idStr)
    end
    return nil
end

local function parseAvatarBorderId(str)
    if type(str) ~= "string" or str == "" then
        return nil
    end
    local idStr = str:match(";ab=(%d+)")
    if idStr then
        return tonumber(idStr)
    end
    return nil
end

local function bubbleStyleToString(style)
    if typeof(style) == "Color3" then
        return colorToString(style)
    end
    if type(style) == "table" and style.type == "gradient" and type(style.colors) == "table" then
        local colors = style.colors
        local n = #colors
        if n < 2 then
            return ""
        end
        if n > 3 then
            n = 3
        end
        local parts = {}
        for i = 1, n do
            local s = colorToString(colors[i])
            if s == "" then
                return ""
            end
            table.insert(parts, s)
        end
        local out = "g" .. tostring(n) .. ":" .. table.concat(parts, "|")
        local animId = tonumber(style.animId)
        if animId and animId > 0 then
            out = out .. ";ba=" .. tostring(math.floor(animId))
        end
        return out
    end
    return ""
end

local dynamicBubbleDefs = {
    { colors = { Color3.fromRGB(80, 150, 255), Color3.fromRGB(255, 140, 200), Color3.fromRGB(255, 230, 120) }, speed = 1.25 },
    { colors = { Color3.fromRGB(80, 210, 210), Color3.fromRGB(160, 120, 255), Color3.fromRGB(255, 140, 200) }, speed = 1.15 },
    { colors = { Color3.fromRGB(255, 170, 80), Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 230, 120) }, speed = 1.35 },
    { colors = { Color3.fromRGB(80, 200, 120), Color3.fromRGB(190, 240, 120), Color3.fromRGB(255, 230, 120) }, speed = 1.05 },
    { colors = { Color3.fromRGB(120, 140, 255), Color3.fromRGB(160, 120, 255), Color3.fromRGB(200, 140, 255) }, speed = 1.2 },
    { colors = { Color3.fromRGB(255, 140, 200), Color3.fromRGB(255, 200, 120), Color3.fromRGB(80, 150, 255) }, speed = 1.1 },
    { colors = { Color3.fromRGB(200, 80, 255), Color3.fromRGB(255, 230, 120), Color3.fromRGB(80, 150, 255) }, speed = 1.3 },
    { colors = { Color3.fromRGB(120, 80, 255), Color3.fromRGB(255, 70, 120), Color3.fromRGB(80, 200, 120) }, speed = 1.18 },
    { colors = { Color3.fromRGB(230, 230, 230), Color3.fromRGB(120, 140, 255), Color3.fromRGB(200, 140, 255) }, speed = 0.95 },
    { colors = { Color3.fromRGB(255, 200, 120), Color3.fromRGB(80, 210, 210), Color3.fromRGB(160, 120, 255) }, speed = 1.12 },
    { colors = { Color3.fromRGB(255, 140, 200), Color3.fromRGB(120, 140, 255), Color3.fromRGB(80, 200, 120) }, speed = 1.06 },
    { colors = { Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 80, 80), Color3.fromRGB(200, 80, 255) }, speed = 1.28 },
    { colors = { Color3.fromRGB(80, 150, 255), Color3.fromRGB(230, 230, 230), Color3.fromRGB(255, 140, 200) }, speed = 0.98 },
    { colors = { Color3.fromRGB(80, 200, 120), Color3.fromRGB(255, 170, 80), Color3.fromRGB(120, 80, 255) }, speed = 1.22 },
    { colors = { Color3.fromRGB(160, 120, 255), Color3.fromRGB(255, 230, 120), Color3.fromRGB(80, 210, 210) }, speed = 1.16 },
}

local function animateBubbleGradient(gradient, animId)
    if not gradient or not gradient.Parent then
        return
    end
    local def = dynamicBubbleDefs[tonumber(animId) or 0]
    local speed = (def and tonumber(def.speed)) or 1.2
    task.spawn(function()
        local start = os.clock()
        while gradient and gradient.Parent do
            local t = (os.clock() - start) * speed
            local phase = t % 2
            local x = phase < 1 and phase or (2 - phase)
            gradient.Offset = Vector2.new((x - 0.5) * 1.1, 0)
            task.wait(0.03)
        end
    end)
end

local addUIStroke
local addStrokeGradient
local animateStrokeGradient

local bubbleBorderDefs = {
    [1] = {
        thickness = 2,
        transparency = 0.05,
        speed = 26,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 140, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 200)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 120)),
        }),
    },
    [2] = {
        thickness = 2,
        transparency = 0.08,
        speed = 20,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 210, 210)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 200)),
        }),
    },
    [3] = {
        thickness = 2,
        transparency = 0.06,
        speed = 30,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 200, 120)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(190, 240, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 120)),
        }),
    },
    [4] = {
        thickness = 2,
        transparency = 0.06,
        speed = 34,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 60)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 70, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
        }),
    },
    [5] = {
        thickness = 2,
        transparency = 0.08,
        speed = 22,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 230, 230)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 140, 255)),
        }),
    },
    [6] = {
        thickness = 2,
        transparency = 0.07,
        speed = 28,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 120, 255)),
        }),
    },
    [7] = {
        thickness = 2,
        transparency = 0.06,
        speed = 24,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 200)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 255)),
        }),
    },
    [8] = {
        thickness = 2,
        transparency = 0.07,
        speed = 32,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 255)),
        }),
    },
    [9] = {
        thickness = 2,
        transparency = 0.06,
        speed = 36,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(120, 140, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 200)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 230, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }),
    },
    [10] = {
        thickness = 2,
        transparency = 0.08,
        speed = 18,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 80, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 70, 120)),
        }),
    },
    [11] = {
        thickness = 2,
        transparency = 0.06,
        speed = 27,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 120)),
        }),
    },
    [12] = {
        thickness = 2,
        transparency = 0.07,
        speed = 23,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 150, 255)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(80, 210, 210)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(80, 200, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 120)),
        }),
    },
}

local function applyBubbleBorderToFrame(frame, borderId)
    if not frame then
        return
    end
    local existing = frame:FindFirstChild("AdminBubbleBorder")
    if existing and existing:IsA("UIStroke") then
        existing:Destroy()
    end
    borderId = tonumber(borderId)
    if not borderId or borderId <= 0 then
        return
    end
    local def = bubbleBorderDefs[borderId]
    if not def then
        return
    end
    local stroke = addUIStroke(frame, Color3.fromRGB(255, 255, 255), def.thickness, def.transparency)
    stroke.Name = "AdminBubbleBorder"
    addStrokeGradient(stroke, def.gradient, 0)
    animateStrokeGradient(stroke, def.speed)
end

local avatarBorderDefs = {
    [1] = { thickness = 2, transparency = 0.06, speed = 26, gradient = bubbleBorderDefs[1] and bubbleBorderDefs[1].gradient },
    [2] = { thickness = 2, transparency = 0.07, speed = 22, gradient = bubbleBorderDefs[2] and bubbleBorderDefs[2].gradient },
    [3] = { thickness = 2, transparency = 0.06, speed = 28, gradient = bubbleBorderDefs[3] and bubbleBorderDefs[3].gradient },
    [4] = { thickness = 2, transparency = 0.07, speed = 30, gradient = bubbleBorderDefs[4] and bubbleBorderDefs[4].gradient },
    [5] = { thickness = 2, transparency = 0.06, speed = 24, gradient = bubbleBorderDefs[6] and bubbleBorderDefs[6].gradient },
    [6] = { thickness = 2, transparency = 0.07, speed = 20, gradient = bubbleBorderDefs[7] and bubbleBorderDefs[7].gradient },
    [7] = { thickness = 2, transparency = 0.06, speed = 32, gradient = bubbleBorderDefs[9] and bubbleBorderDefs[9].gradient },
    [8] = { thickness = 2, transparency = 0.07, speed = 18, gradient = bubbleBorderDefs[12] and bubbleBorderDefs[12].gradient },
    [9] = { thickness = 2, transparency = 0.06, speed = 24, gradient = bubbleBorderDefs[5] and bubbleBorderDefs[5].gradient },
    [10] = { thickness = 2, transparency = 0.07, speed = 34, gradient = bubbleBorderDefs[8] and bubbleBorderDefs[8].gradient },
    [11] = { thickness = 2, transparency = 0.06, speed = 20, gradient = bubbleBorderDefs[10] and bubbleBorderDefs[10].gradient },
    [12] = { thickness = 2, transparency = 0.07, speed = 28, gradient = bubbleBorderDefs[11] and bubbleBorderDefs[11].gradient },
    [13] = {
        thickness = 2,
        transparency = 0.06,
        speed = 18,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 150, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 150, 255)),
        }),
    },
    [14] = {
        thickness = 2,
        transparency = 0.06,
        speed = 18,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
        }),
    },
    [15] = {
        thickness = 2,
        transparency = 0.06,
        speed = 18,
        gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 120)),
        }),
    },
}

local avatarBorderSolidColors = {
    Color3.fromRGB(80, 150, 255),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(255, 230, 120),
    Color3.fromRGB(255, 80, 80),
    Color3.fromRGB(80, 200, 120),
    Color3.fromRGB(80, 210, 210),
    Color3.fromRGB(160, 120, 255),
    Color3.fromRGB(255, 140, 200),
    Color3.fromRGB(255, 170, 80),
    Color3.fromRGB(0, 0, 0),
    Color3.fromRGB(180, 180, 180),
    Color3.fromRGB(160, 120, 80),
}

local function applyAvatarBorderToFrame(frame, borderId)
    if not frame then
        return
    end
    local existing = frame:FindFirstChild("AvatarBorder")
    if existing and existing:IsA("UIStroke") then
        existing:Destroy()
    end
    borderId = tonumber(borderId)
    if not borderId or borderId <= 0 then
        return
    end
    local def = avatarBorderDefs[borderId]
    if def and def.gradient then
        local stroke = addUIStroke(frame, Color3.fromRGB(255, 255, 255), def.thickness or 2, def.transparency or 0.06)
        stroke.Name = "AvatarBorder"
        addStrokeGradient(stroke, def.gradient, 0)
        animateStrokeGradient(stroke, def.speed or 22)
        return
    end
    local solidIndex = nil
    if borderId >= 101 and borderId <= (100 + #avatarBorderSolidColors) then
        solidIndex = borderId - 100
    end
    if solidIndex then
        local c = avatarBorderSolidColors[solidIndex]
        if c then
            local stroke = addUIStroke(frame, c, 2, 0.06)
            stroke.Name = "AvatarBorder"
        end
    end
end

local function buildBubblePayload(style, fallbackColor, borderId, avatarBorderId)
    local bubbleStr = bubbleStyleToString(style)
    if bubbleStr == "" then
        bubbleStr = colorToString(fallbackColor)
    end
    borderId = tonumber(borderId)
    if borderId and borderId > 0 then
        bubbleStr = bubbleStr .. ";bd=" .. tostring(math.floor(borderId))
    end
    avatarBorderId = tonumber(avatarBorderId)
    if avatarBorderId and avatarBorderId > 0 then
        bubbleStr = bubbleStr .. ";ab=" .. tostring(math.floor(avatarBorderId))
    end
    return bubbleStr
end

local function applyBubbleStyleToFrame(frame, style)
    if not frame then
        return
    end
    local existing = frame:FindFirstChild("BubbleGradient")
    if existing and existing:IsA("UIGradient") then
        existing:Destroy()
    end
    if typeof(style) == "Color3" then
        frame.BackgroundColor3 = style
        return
    end
    if type(style) == "table" and style.type == "gradient" and type(style.colors) == "table" then
        local colors = style.colors
        if #colors >= 2 then
            frame.BackgroundColor3 = colors[1]
            local gradient = Instance.new("UIGradient")
            gradient.Name = "BubbleGradient"
            if #colors >= 3 then
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, colors[1]),
                    ColorSequenceKeypoint.new(0.5, colors[2]),
                    ColorSequenceKeypoint.new(1, colors[3]),
                })
            else
                gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, colors[1]),
                    ColorSequenceKeypoint.new(1, colors[2]),
                })
            end
            gradient.Rotation = 0
            gradient.Parent = frame
            local animId = tonumber(style.animId)
            if animId and animId > 0 then
                animateBubbleGradient(gradient, animId)
            end
        end
    end
end

local function encodeMessageWithFont(messageText, fontColor)
    if type(messageText) ~= "string" or messageText == "" then
        return messageText
    end
    if messageText:sub(1, 2) == "##" then
        return messageText
    end
    if messageText:sub(1, 7) == "##IMG##" then
        return messageText
    end
    local singleUrl = messageText:match("^(https?://%S+)$")
    if singleUrl then
        local ext = singleUrl:match("%.([%a%d]+)$")
        if ext then
            ext = string.lower(ext)
            if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" or ext == "webp" then
                return messageText
            end
        end
    end
    local colorStr = colorToString(fontColor)
    if colorStr == "" then
        return messageText
    end
    return FONT_PREFIX .. colorStr .. "|" .. messageText
end

local function decodeMessageWithFont(messageText)
    if type(messageText) ~= "string" then
        return messageText, nil
    end
    if messageText:sub(1, #FONT_PREFIX) ~= FONT_PREFIX then
        return messageText, nil
    end
    local rest = messageText:sub(#FONT_PREFIX + 1)
    local colorStr, inner = rest:match("^([^|]+)|(.*)$")
    if not colorStr then
        return messageText, nil
    end
    return inner, stringToColor(colorStr)
end

local function canUseChatColorFile()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

local function loadChatColorConfig()
    if getgenv and getgenv().ThirdGenChatColor then
        local data = getgenv().ThirdGenChatColor
        if type(data) == "table" and type(data.color) == "string" then
            local s = parseBubbleStyle(data.color)
            if s then
                selfBubbleStyle = s
                if typeof(s) == "Color3" then
                    selfBubbleColor = s
                elseif type(s) == "table" and type(s.colors) == "table" and s.colors[1] then
                    selfBubbleColor = s.colors[1]
                end
            end
        end
        if type(data) == "table" and type(data.random) == "boolean" then
            randomColorEnabled = data.random
        end
        if type(data) == "table" and tonumber(data.border) then
            selfBubbleBorderId = math.max(0, math.floor(tonumber(data.border)))
        end
    end
    if not canUseChatColorFile() or not isfile(CHAT_COLOR_CONFIG_FILE) then
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CHAT_COLOR_CONFIG_FILE))
    end)
    if ok and type(data) == "table" and type(data.color) == "string" then
        local s = parseBubbleStyle(data.color)
        if s then
            selfBubbleStyle = s
            if typeof(s) == "Color3" then
                selfBubbleColor = s
            elseif type(s) == "table" and type(s.colors) == "table" and s.colors[1] then
                selfBubbleColor = s.colors[1]
            end
        end
    end
    if ok and type(data) == "table" and type(data.random) == "boolean" then
        randomColorEnabled = data.random
    end
    if ok and type(data) == "table" and tonumber(data.border) then
        selfBubbleBorderId = math.max(0, math.floor(tonumber(data.border)))
    end
    if ok and type(data) == "table" and tonumber(data.avatarBorder) then
        selfAvatarBorderId = math.max(0, math.floor(tonumber(data.avatarBorder)))
    end
end

local function saveChatColorConfig()
    local colorStr = bubbleStyleToString(selfBubbleStyle)
    if colorStr == "" then
        colorStr = colorToString(selfBubbleColor)
    end
    local payload = {
        color = colorStr,
        random = randomColorEnabled,
        border = selfBubbleBorderId,
        avatarBorder = selfAvatarBorderId,
    }
    if getgenv then
        getgenv().ThirdGenChatColor = payload
    end
    if not canUseChatColorFile() then
        return
    end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if ok then
        pcall(function()
            writefile(CHAT_COLOR_CONFIG_FILE, encoded)
        end)
    end
end

loadChatColorConfig()

local function canUseChatSettingsFile()
    return typeof(writefile) == "function"
        and typeof(readfile) == "function"
        and typeof(isfile) == "function"
end

local function loadChatSettings()
    if getgenv and getgenv().ThirdGenChatSettings then
        local data = getgenv().ThirdGenChatSettings
        if type(data) == "table" and type(data.autoPopup) == "boolean" then
            autoPopupEnabled = data.autoPopup
        end
        if type(data) == "table" and type(data.background) == "table" then
            backgroundSetting = data.background
        end
    end
    if not canUseChatSettingsFile() or not isfile(CHAT_SETTINGS_FILE) then
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CHAT_SETTINGS_FILE))
    end)
    if ok and type(data) == "table" and type(data.autoPopup) == "boolean" then
        autoPopupEnabled = data.autoPopup
    end
    if ok and type(data) == "table" and type(data.background) == "table" then
        backgroundSetting = data.background
    end
end

local function saveChatSettings()
    local payload = { autoPopup = autoPopupEnabled, background = backgroundSetting }
    if getgenv then
        getgenv().ThirdGenChatSettings = payload
    end
    if not canUseChatSettingsFile() then
        return
    end
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if ok then
        pcall(function()
            writefile(CHAT_SETTINGS_FILE, encoded)
        end)
    end
end

loadChatSettings()
startMinimizedOnLoad = autoPopupEnabled

function ThirdGenChat_GetAssetFunc()
    if typeof(getcustomasset) == "function" then
        return getcustomasset
    end
    if typeof(getsynasset) == "function" then
        return getsynasset
    end
    return nil
end

function ThirdGenChat_EnsureFolder(folderName)
    if typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then
        return
    end
    if isfolder(folderName) then
        return
    end
    pcall(function()
        makefolder(folderName)
    end)
end

function ThirdGenChat_SafeFileName(name)
    return tostring(name or "bg.png"):gsub("[^%w%._%-]", "_")
end

function ThirdGenChat_RequestDownload(url)
    if typeof(request) ~= "function" then
        return false, nil
    end
    local ok, res = pcall(function()
        return request({ Url = url, Method = "GET" })
    end)
    if not ok or not res or not res.Success or type(res.Body) ~= "string" or #res.Body <= 0 then
        return false, nil
    end
    return true, res.Body
end

function ThirdGenChat_NormalizeLocalPath(pathOrName, folderName)
    if type(pathOrName) ~= "string" or pathOrName == "" then
        return nil
    end
    local p = pathOrName:gsub("\\", "/")
    local base = p:match("([^/]+)$")
    if base and base ~= "" and folderName and folderName ~= "" then
        return tostring(folderName) .. "/" .. base
    end
    return p
end

function ThirdGenChat_ResolveLocalAsset(pathOrAsset)
    if type(pathOrAsset) ~= "string" or pathOrAsset == "" then
        return nil
    end
    if string.find(pathOrAsset, "rbxassetid://", 1, true) or string.find(pathOrAsset, "rbxthumb://", 1, true) then
        return pathOrAsset
    end
    local getAsset = ThirdGenChat_GetAssetFunc()
    if not getAsset then
        return nil
    end
    pathOrAsset = pathOrAsset:gsub("\\", "/")
    local okAsset, assetId = pcall(function()
        return getAsset(pathOrAsset)
    end)
    if okAsset and type(assetId) == "string" and assetId ~= "" then
        return assetId
    end
    return nil
end

chatBgImage = nil

function ThirdGenChat_ApplyBackgroundSetting()
    if not chatBgImage then
        return
    end
    local setting = backgroundSetting
    if type(setting) ~= "table" then
        setting = DEFAULT_BACKGROUND_SETTING
    end
    local kind = setting.kind
    if kind == "none" then
        chatBgImage.Visible = false
        chatBgImage.Image = ""
        return
    end
    if kind == "local" then
        local asset = ThirdGenChat_ResolveLocalAsset(setting.path)
        if asset then
            chatBgImage.Image = asset
            chatBgImage.Visible = true
        else
            chatBgImage.Visible = false
            chatBgImage.Image = ""
        end
        return
    end

    if kind == "remote" then
        if typeof(writefile) ~= "function" or typeof(isfile) ~= "function" then
            chatBgImage.Visible = false
            chatBgImage.Image = ""
            return
        end
        ThirdGenChat_EnsureFolder(BACKGROUND_CACHE_FOLDER)
        local safeName = ThirdGenChat_SafeFileName(setting.fileName)
        local path = BACKGROUND_CACHE_FOLDER .. "/" .. safeName
        if not isfile(path) and type(setting.url) == "string" and setting.url ~= "" then
            local okBody, body = ThirdGenChat_RequestDownload(setting.url)
            if okBody and body then
                pcall(function()
                    writefile(path, body)
                end)
            end
        end
        local asset = ThirdGenChat_ResolveLocalAsset(path)
        if asset then
            chatBgImage.Image = asset
            chatBgImage.Visible = true
        else
            chatBgImage.Visible = false
            chatBgImage.Image = ""
        end
        return
    end

    chatBgImage.Visible = false
    chatBgImage.Image = ""
end

function ThirdGenChat_SetBackgroundRemote(url, fileName)
    backgroundSetting = { kind = "remote", url = url, fileName = fileName }
    saveChatSettings()
    ThirdGenChat_ApplyBackgroundSetting()
end

function ThirdGenChat_SetBackgroundLocal(path)
    local normalized = ThirdGenChat_NormalizeLocalPath(path, BACKGROUND_CACHE_FOLDER) or path
    backgroundSetting = { kind = "local", path = normalized }
    saveChatSettings()
    ThirdGenChat_ApplyBackgroundSetting()
end

function ThirdGenChat_ClearBackground()
    backgroundSetting = { kind = "none" }
    saveChatSettings()
    ThirdGenChat_ApplyBackgroundSetting()
end

function ThirdGenChat_ListLocalImages(folderName)
    local out = {}
    if typeof(listfiles) ~= "function" then
        return out
    end
    ThirdGenChat_EnsureFolder(folderName)
    local ok, files = pcall(function()
        return listfiles(folderName)
    end)
    if not ok or type(files) ~= "table" then
        return out
    end
    for _, p in ipairs(files) do
        if type(p) == "string" then
            local lower = string.lower(p)
            if string.sub(lower, -4) == ".png" or string.sub(lower, -4) == ".jpg" or string.sub(lower, -5) == ".jpeg" or string.sub(lower, -4) == ".webp" then
                local normalized = ThirdGenChat_NormalizeLocalPath(p, folderName) or p
                table.insert(out, normalized)
            end
        end
    end
    return out
end

local backgroundGradient = ColorSequence.new(Color3.fromRGB(40, 42, 54), Color3.fromRGB(76, 82, 102))
local strokeGradient = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 60, 60)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 60))
}
local accentGradient = ColorSequence.new(accentColorLight, accentColorDark)
local softPurpleColor = Color3.fromRGB(176, 150, 255)
local softPurpleLight = Color3.fromRGB(200, 178, 255)
local softPurpleDark = Color3.fromRGB(140, 115, 235)
local softPurpleGradient = ColorSequence.new(softPurpleLight, softPurpleDark)

local softOrangeColor = Color3.fromRGB(255, 176, 90)
local softOrangeLight = Color3.fromRGB(255, 200, 140)
local softOrangeDark = Color3.fromRGB(235, 132, 60)
local softOrangeGradient = ColorSequence.new(softOrangeLight, softOrangeDark)

local softInputColor = Color3.fromRGB(236, 220, 200)
local softInputDark = Color3.fromRGB(220, 200, 175)
local softInputGradient = ColorSequence.new(softInputColor, softInputDark)
local softInputTextColor = Color3.fromRGB(45, 40, 40)
local softInputPlaceholderColor = Color3.fromRGB(120, 100, 85)

local function createMainGui()
    if getgenv then
        local g = getgenv()
        local old = rawget(g, "CHICHISHIJIE_GUI")
        if typeof(old) == "Instance" and old.Parent then
            pcall(function()
                old:Destroy()
            end)
        end
    end
    local okCg, cg = pcall(function()
        return game:GetService("CoreGui")
    end)
    for _, root in ipairs({ PlayerGui, (okCg and cg) or nil }) do
        if root then
            for _, child in ipairs(root:GetChildren()) do
                if child:IsA("ScreenGui") and (child:GetAttribute("CHICHISHIJIE_UI") == true) then
                    child:Destroy()
                end
            end
        end
    end
    local existing = PlayerGui:FindFirstChild("CHICHISHIJIE")
    if not existing then
        if okCg and cg then
            existing = cg:FindFirstChild("CHICHISHIJIE")
        end
    end
    if existing then
        existing:Destroy()
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CHICHISHIJIE"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 99999
    screenGui.IgnoreGuiInset = true
    local parented = false
    pcall(function()
        screenGui.Parent = game:GetService("CoreGui")
        parented = true
    end)
    if not parented then
        screenGui.Parent = PlayerGui
    end
    screenGui:SetAttribute("CHICHISHIJIE_UI", true)
    if getgenv then
        getgenv().CHICHISHIJIE_GUI = screenGui
    end
    return screenGui
end

local function addUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 8)
    corner.Parent = parent
    return corner
end

addUIStroke = function(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(255, 255, 255)
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0.8
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function addUIGradient(parent, colorSequence, rotation, transparency)
    local gradient = Instance.new("UIGradient")
    gradient.Color = colorSequence
    if rotation then
        gradient.Rotation = rotation
    end
    if transparency then
        gradient.Transparency = transparency
    end
    gradient.Parent = parent
    return gradient
end

addStrokeGradient = function(stroke, colorSequence, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = colorSequence
    gradient.Rotation = rotation or 0
    gradient.Parent = stroke
    return gradient
end

animateStrokeGradient = function(stroke, speed)
    local gradient = stroke:FindFirstChildOfClass("UIGradient")
    if not gradient then
        return
    end
    speed = speed or 20
    task.spawn(function()
        while stroke.Parent do
            local current = gradient.Rotation
            gradient.Rotation = current + speed * 0.03
            task.wait(0.03)
        end
    end)
end

local function addButtonStroke(button, rotation, transparency)
    local stroke = addUIStroke(button, Color3.fromRGB(255, 255, 255), 1.1, transparency or 0.4)
    addStrokeGradient(stroke, strokeGradient, rotation or 180)
    return stroke
end

local function addUIPadding(parent, padding)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, padding)
    pad.PaddingBottom = UDim.new(0, padding)
    pad.PaddingLeft = UDim.new(0, padding)
    pad.PaddingRight = UDim.new(0, padding)
    pad.Parent = parent
    return pad
end

local function addShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6015897843"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent
    return shadow
end

local function getUserAvatar(playerName)
    local cacheKey = playerName
    if avatarCache[cacheKey] then
        return avatarCache[cacheKey]
    end
    local lookupName = playerName
    local extractedName = playerName:match("%(([%w_]+)%)")
    if extractedName and extractedName ~= "" then
        lookupName = extractedName
    end
    local success, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(lookupName)
    end)
    if success and userId then
        local thumbSuccess, thumbUrl = pcall(function()
            local content, isReady = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            return content
        end)
        if thumbSuccess and thumbUrl then
            avatarCache[cacheKey] = thumbUrl
            return thumbUrl
        end
    end
    avatarCache[cacheKey] = defaultAvatarUrl
    return defaultAvatarUrl
end

local function tweenProperty(object, properties, duration, style, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Cubic, direction or Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

local currentAnnouncement = ""
local announcementVersion = 0

local function createParticle()
    local dot = Instance.new("Frame")
    dot.BackgroundColor3 = starColor
    dot.BorderSizePixel = 0
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.ZIndex = 2
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = dot
    return dot
end

local function spawnParticlesInFrame(layer, width, height)
    local particles = {}
    for i = 1, particleCount do
        local dot = createParticle()
        local size = math.random() * 2 + 1.5
        dot.Size = UDim2.new(0, size, 0, size)
        dot.BackgroundTransparency = 0.5
        local x = math.random(10, math.floor(width - 10))
        local y = math.random(10, math.floor(height - 10))
        dot.Position = UDim2.new(0, x, 0, y)
        dot.Parent = layer
        particles[i] = {
            dot = dot,
            x = x,
            y = y,
            size = size,
            vx = (math.random() - 0.5) * 0.4,
            vy = (math.random() - 0.5) * 0.4,
            isMeteor = false,
            meteorTime = 0,
        }
    end
    return particles
end

local function createLine(lineLayer)
    local line = Instance.new("Frame")
    line.BackgroundColor3 = starColor
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Size = UDim2.new(0, 0, 0, 1)
    line.Visible = false
    line.ZIndex = 1
    line.Parent = lineLayer
    return line
end

local function updateParticlesInFrame(particles, width, height)
    local now = tick()
    for _, particle in ipairs(particles) do
        if not particle.isMeteor then
            particle.x = particle.x + particle.vx
            particle.y = particle.y + particle.vy
            if particle.x < 5 or particle.x > width - 5 then
                particle.vx = -particle.vx
                particle.x = math.clamp(particle.x, 5, width - 5)
            end
            if particle.y < 5 or particle.y > height - 5 then
                particle.vy = -particle.vy
                particle.y = math.clamp(particle.y, 5, height - 5)
            end
            particle.dot.Position = UDim2.new(0, particle.x, 0, particle.y)
            particle.dot.BackgroundColor3 = starColor
            particle.dot.Size = UDim2.new(0, particle.size, 0, particle.size)
        else
            local dt = now - particle.meteorTime
            if dt > 0.5 then
                particle.isMeteor = false
                particle.vx = (math.random() - 0.5) * 0.4
                particle.vy = (math.random() - 0.5) * 0.4
                particle.dot.BackgroundColor3 = starColor
                particle.dot.Size = UDim2.new(0, particle.size, 0, particle.size)
                particle.dot.BackgroundTransparency = 0.5
            else
                particle.x = particle.x + particle.vx * 3
                particle.y = particle.y + particle.vy * 3
                particle.dot.Position = UDim2.new(0, particle.x, 0, particle.y)
                particle.dot.BackgroundColor3 = meteorColor
                local scale = 1.5 + dt * 2
                local w = particle.size * scale
                particle.dot.Size = UDim2.new(0, w, 0, particle.size * 0.8)
                particle.dot.BackgroundTransparency = 0.2
            end
        end
    end
    if math.random() < 0.03 then
        local index = math.random(1, #particles)
        local p = particles[index]
        if not p.isMeteor then
            p.isMeteor = true
            p.meteorTime = now
            local angle = math.random() * math.pi * 2
            local speed = 0.8
            p.vx = math.cos(angle) * speed
            p.vy = math.sin(angle) * speed
        end
    end
end

local function updateLines(particles, lineLayer, pool)
    local active = 0
    for i = 1, #particles do
        for j = i + 1, #particles do
            local p1 = particles[i]
            local p2 = particles[j]
            local dx = p1.x - p2.x
            local dy = p1.y - p2.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < connectionDistance then
                active = active + 1
                if active > maxLines then break end
                local line = pool[active]
                if not line then
                    line = createLine(lineLayer)
                    pool[active] = line
                end
                line.Visible = true
                local midX = (p1.x + p2.x) / 2
                local midY = (p1.y + p2.y) / 2
                line.Size = UDim2.new(0, distance, 0, 1)
                line.Position = UDim2.new(0, midX, 0, midY)
                line.Rotation = math.deg(math.atan2(dy, dx))
                line.BackgroundTransparency = 0.6 + (distance / connectionDistance) * 0.3
            end
        end
        if active >= maxLines then break end
    end
    for i = active + 1, #pool do
        if pool[i] then pool[i].Visible = false end
    end
end

local function createButton(parent, text, size, position, isPrimary)
    local button = Instance.new("TextButton")
    button.Name = text .. "Button"
    button.Size = size
    button.Position = position
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.BackgroundColor3 = isPrimary and accentColor or backgroundTertiary
    button.BackgroundTransparency = 0
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = text
    button.TextColor3 = textColor
    button.TextSize = 13
    button.AutoButtonColor = false
    button.Parent = parent
    addUICorner(button, UDim.new(0, 6))
    addUIGradient(button, isPrimary and accentGradient or backgroundGradient, 68)
    addButtonStroke(button, 180, 0.35)
    local originalTransparency = button.BackgroundTransparency
    button.MouseEnter:Connect(function()
        tweenProperty(button, {BackgroundTransparency = 0.35}, 0.15)
    end)
    button.MouseLeave:Connect(function()
        tweenProperty(button, {BackgroundTransparency = originalTransparency}, 0.15)
    end)
    return button
end

local function createTextBox(parent, placeholder, size, position)
    local container = Instance.new("Frame")
    container.Name = "TextBoxContainer"
    container.Size = size
    container.Position = position
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.BackgroundColor3 = backgroundSecondary
    container.BorderSizePixel = 0
    container.Parent = parent
    addUICorner(container, UDim.new(0, 6))
    local containerStroke = addUIStroke(container, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(containerStroke, strokeGradient, 180)
    addUIGradient(container, backgroundGradient, 68)
    local textBox = Instance.new("TextBox")
    textBox.Name = "Input"
    textBox.Size = UDim2.new(1, -16, 1, 0)
    textBox.Position = UDim2.new(0, 8, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = textMuted
    textBox.Text = ""
    textBox.TextColor3 = textColor
    textBox.TextSize = 13
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    textBox.Parent = container
    textBox.Focused:Connect(function()
        tweenProperty(container:FindFirstChildOfClass("UIStroke"), {Color = accentColor, Transparency = 0.3}, 0.15)
    end)
    textBox.FocusLost:Connect(function()
        tweenProperty(container:FindFirstChildOfClass("UIStroke"), {Color = Color3.fromRGB(70, 70, 70), Transparency = 0.5}, 0.15)
    end)
    return container, textBox
end

local muteList = {}
local muteIssuer = {}
local messageWindowStart = 0
local messageCountInWindow = 0
local ADMIN_USER = "weidada3"
local ADMIN_USER_2 = "aqin5200"
local ADMIN_USER_3 = "ChristmasEveQ"
local ADMIN_USER_4 = "Apple520145"
local ADMIN_USER_5 = "weidada9"
local ADMIN_USER_6 = "daweiqingyi"
local ADMIN_USER_7 = "qazwsx14736988"
local ADMIN_USER_8 = "zthh5"
local ADMIN_USER_9 = "MrYu260"
local ADMIN_USER_10 = "qw540889"
local ADMIN_USER_11 = "CSC201000"
local ADMIN_USER_12 = "c_shi2"
local ADMIN_USER_13 = "AQAQQASA"
local ADMIN_USER_14 = "ayuan0629"
local ADMIN_USER_15 = "Kqqne101"
local ADMIN_USER_15 = "Tkssn101"
local ADMIN_USER_16 = "Sans0012o"
local ADMIN_USER_17 = "ZYQ1224"
local ADMIN_USER_18 = "SBB_1234o"
local ADMIN_USER_19 = "SBB_12345o"
local ADMIN_USER_20 = "NightDiamond750"
local SUPER_ADMINS = {
    ADMIN_USER,
    ADMIN_USER_2,
    ADMIN_USER_3,
    ADMIN_USER_4,
    ADMIN_USER_5,
    ADMIN_USER_6,
    ADMIN_USER_7,
    ADMIN_USER_8,
    ADMIN_USER_9,
    ADMIN_USER_10,
    ADMIN_USER_11,
    ADMIN_USER_12,
    ADMIN_USER_13,
    ADMIN_USER_14,
    ADMIN_USER_15,
    ADMIN_USER_16,
    ADMIN_USER_17,
	ADMIN_USER_18,
	ADMIN_USER_19,
	ADMIN_USER_20,
	ADMIN_USER_21,
}
local CREATOR_ADMINS = {
    ADMIN_USER,
}
local remoteAdmins = {}
local adminsLoaded = false

local function normalizeAdminName(name)
    if type(name) ~= "string" then
        return nil
    end
    local extracted = name:match("%(([%w_]+)%)")
    if extracted and extracted ~= "" then
        return extracted
    end
    return name
end

local function extractReplyTargetName(text)
    if type(text) ~= "string" then
        return nil
    end
    local target = text:match("^回复%s+([^：:]+)[：:]")
    if not target then
        return nil
    end
    target = tostring(target):gsub("^%s+", ""):gsub("%s+$", "")
    if target == "" then
        return nil
    end
    return normalizeAdminName(target) or target
end

local function buildDmKey(dm)
    if type(dm) ~= "table" then
        return nil
    end
    local t = tostring(dm.time or dm.t or "")
    local f = tostring(dm["from"] or dm.f or "")
    local to = tostring(dm["to"] or dm.to or "")
    local m = tostring(dm.msg or dm.m or "")
    if t == "" and f == "" and to == "" and m == "" then
        return nil
    end
    return t .. "|" .. f .. "|" .. to .. "|" .. m
end

local function normalizeDisplayNameForTarget(displayName)
    local base = normalizeAdminName(displayName)
    if base and base ~= "" then
        return base
    end
    if type(displayName) == "string" and displayName ~= "" then
        return displayName
    end
    return nil
end

local function isSuperAdminName(name)
    if type(name) ~= "string" then
        return false
    end
    local baseName = normalizeAdminName(name)
    if not baseName or baseName == "" then
        return false
    end
    for _, adminName in ipairs(SUPER_ADMINS) do
        if adminName ~= "" and baseName == adminName then
            return true
        end
    end
    return false
end

local function isCreatorAdminName(name)
    if type(name) ~= "string" then
        return false
    end
    local baseName = normalizeAdminName(name)
    if not baseName or baseName == "" then
        return false
    end
    for _, adminName in ipairs(CREATOR_ADMINS) do
        if adminName ~= "" and baseName == adminName then
            return true
        end
    end
    return false
end

local function setRemoteAdmins(list)
    remoteAdmins = {}
    if type(list) == "table" then
        for _, v in ipairs(list) do
            if type(v) == "string" and v ~= "" then
                local value = v
                if value:match("^%d+$") then
                    local ok, userNameFromId = pcall(function()
                        return Players:GetNameFromUserIdAsync(tonumber(value))
                    end)
                    if ok and type(userNameFromId) == "string" and userNameFromId ~= "" then
                        value = userNameFromId
                    end
                end
                local baseName = normalizeAdminName(value)
                if baseName and baseName ~= "" then
                    remoteAdmins[baseName] = true
                end
                remoteAdmins[value] = true
            end
        end
    end
    for _, adminName in ipairs(SUPER_ADMINS) do
        if adminName ~= "" then
            remoteAdmins[adminName] = true
        end
    end
    adminsLoaded = true
end

local function fetchRemoteAdmins()
    local url = string.format("%s?action=get_admins&apikey=%s",
        BASE_URL,
        HttpService:UrlEncode(FIXED_API_KEY)
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response or not response.Success then
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if ok and type(data) == "table" then
        setRemoteAdmins(data)
        if updateAdminUI then
            updateAdminUI()
        end
    end
end

local function addAdminRemote(targetName)
    if not targetName or targetName == "" then
        return false, "请输入用户名或用户ID"
    end
    local url = string.format("%s?action=add_admin&apikey=%s&name=%s",
        BASE_URL,
        HttpService:UrlEncode(FIXED_API_KEY),
        HttpService:UrlEncode(targetName)
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response or not response.Success then
        return false, "添加管理员失败"
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if ok and type(data) == "table" then
        if data[1] == "success" then
            return true, data[2] or "添加成功"
        elseif data[1] == "error" and data[2] then
            return false, tostring(data[2])
        end
    end
    return false, "添加管理员返回异常"
end

local function removeAdminRemote(targetName)
    if not targetName or targetName == "" then
        return false, "请选择要移除的管理员"
    end
    if isSuperAdminName(targetName) then
        return false, "不能移除超级管理员"
    end
    local url = string.format("%s?action=remove_admin&apikey=%s&name=%s",
        BASE_URL,
        HttpService:UrlEncode(FIXED_API_KEY),
        HttpService:UrlEncode(targetName)
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response or not response.Success then
        return false, "移除管理员失败"
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if ok and type(data) == "table" then
        if data[1] == "success" then
            return true, data[2] or "移除成功"
        elseif data[1] == "error" and data[2] then
            return false, tostring(data[2])
        end
    end
    return false, "移除管理员返回异常"
end

local function isAdminName(name)
    if type(name) ~= "string" then
        return false
    end
    if remoteAdmins[name] then
        return true
    end
    local baseName = normalizeAdminName(name)
    if baseName and remoteAdmins[baseName] then
        return true
    end
    return isSuperAdminName(name)
end

local updateAdminUI
local applyAnnouncement
local openMuteMenu
local openAdminPanel
local openRoomList
local roomListPanel
local roomListScroll
local roomListTitle
local roomListTipLabel
local revokeMessageRemote

local function createMessageBubble(parent, message, name, time, isSelf, layoutOrder, animate, bubbleColor, bubbleBorderId, avatarBorderId, rootGui)
    local container = Instance.new("Frame")
    container.Name = "MessageContainer"
    container.Size = UDim2.new(1, -10, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.LayoutOrder = layoutOrder or 0
    container.Parent = parent

    local avatarSize = 24
    local avatarMargin = 6

    local avatarFrame = Instance.new("ImageButton")
    avatarFrame.Name = "Avatar"
    avatarFrame.Size = UDim2.new(0, avatarSize, 0, avatarSize)
    if isSelf then
        avatarFrame.AnchorPoint = Vector2.new(1, 0)
        avatarFrame.Position = UDim2.new(1, 0, 0, 0)
    else
        avatarFrame.Position = UDim2.new(0, 0, 0, 0)
    end
    avatarFrame.BackgroundColor3 = backgroundTertiary
    avatarFrame.BorderSizePixel = 0
    avatarFrame.Image = defaultAvatarUrl
    avatarFrame.Parent = container
    addUICorner(avatarFrame, UDim.new(1, 0))
    local effectiveAvatarBorderId = avatarBorderId
    if effectiveAvatarBorderId == nil and isSelf then
        effectiveAvatarBorderId = selfAvatarBorderId
    end
    applyAvatarBorderToFrame(avatarFrame, effectiveAvatarBorderId)
    task.spawn(function()
        if isSelf then
            local ok, thumbUrl = pcall(function()
                local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                return content
            end)
            if ok and thumbUrl then
                avatarFrame.Image = thumbUrl
            end
        else
            local displayName = name
            if displayName == nil or displayName == "" then
                displayName = "Roblox"
            end
            local avatarUrl = getUserAvatar(displayName)
            avatarFrame.Image = avatarUrl
        end
    end)

    avatarFrame.AutoButtonColor = false

    local avatarPressing = false
    local avatarLongPressFired = false
    local avatarLongPressThreshold = 0.6

    if not isSelf then
        avatarFrame.MouseButton1Click:Connect(function()
            if avatarLongPressFired then
                avatarLongPressFired = false
                return
            end
            local nowClick = os.clock()
            if not isAdminName(userName) then
                avatarFrame:SetAttribute("LastClick", avatarFrame:GetAttribute("LastClick") or 0)
                local lastClick = tonumber(avatarFrame:GetAttribute("LastClick")) or 0
                avatarFrame:SetAttribute("LastClick", nowClick)
                if nowClick - lastClick <= 0.3 then
                    local target = normalizeDisplayNameForTarget(name)
                    if target and target ~= "" then
                        dmTargetName = target
                        if messageInput then
                            messageInput.PlaceholderText = "私信给 " .. tostring(target) .. "..."
                            messageInput:CaptureFocus()
                        end
                        local notifyParent = rootGui or parent
                        createNotification(notifyParent, "已进入私信模式", false)
                    else
                        local notifyParent = rootGui or parent
                        createNotification(notifyParent, "无法私信该用户", true)
                    end
                    return
                end
            end
            if openMuteMenu and isAdminName(userName) then
                openMuteMenu(name)
                return
            end
            local baseName = name
            if baseName and baseName ~= "" then
                local openParen = string.find(baseName, "(", 1, true)
                local closeParen = openParen and string.find(baseName, ")", openParen + 1, true) or nil
                if openParen and closeParen and closeParen > openParen then
                    baseName = string.sub(baseName, openParen + 1, closeParen - 1)
                end
            end
            if messageInput and baseName and baseName ~= "" then
                local atText = "@" .. baseName .. " "
                local current = messageInput.Text or ""
                if current == "" then
                    messageInput.Text = atText
                else
                    if not current:find(atText, 1, true) then
                        messageInput.Text = atText .. current
                    end
                end
                messageInput:CaptureFocus()
                local notifyParent = rootGui or parent
                createNotification(notifyParent, "已填入 " .. atText, false)
            else
                local notifyParent = rootGui or parent
                createNotification(notifyParent, "无法获取对方名称，暂时不能 @", true)
            end
        end)
    end

    if isSelf and openAdminPanel and isSuperAdminName(LocalPlayer.Name) then
        avatarFrame.MouseButton1Click:Connect(function()
            openAdminPanel()
        end)
    end

    avatarFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if isSelf then
                return
            end
            avatarPressing = true
            avatarLongPressFired = false
            local pressStart = os.clock()
            task.spawn(function()
                while avatarPressing and not avatarLongPressFired do
                    if os.clock() - pressStart >= avatarLongPressThreshold then
                        avatarLongPressFired = true
                        local baseName = name
                        if baseName and baseName ~= "" then
                            local openParen = string.find(baseName, "(", 1, true)
                            local closeParen = openParen and string.find(baseName, ")", openParen + 1, true) or nil
                            if openParen and closeParen and closeParen > openParen then
                                baseName = string.sub(baseName, openParen + 1, closeParen - 1)
                            end
                        end
                        if messageInput and baseName and baseName ~= "" then
                            local atText = "@" .. baseName .. " "
                            local current = messageInput.Text or ""
                            if current == "" then
                                messageInput.Text = atText
                            else
                                if not current:find(atText, 1, true) then
                                    messageInput.Text = atText .. current
                                end
                            end
                            messageInput:CaptureFocus()
                        end
                        break
                    end
                    task.wait(0.05)
                end
            end)
        end
    end)

    avatarFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            avatarPressing = false
        end
    end)

    local bubble = Instance.new("Frame")
    bubble.Name = "Bubble"
    bubble.Size = UDim2.new(0, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.XY
    bubble.Position = isSelf and UDim2.new(1, -(avatarSize + avatarMargin), 0, 0) or UDim2.new(0, avatarSize + avatarMargin, 0, 0)
    bubble.AnchorPoint = isSelf and Vector2.new(1, 0) or Vector2.new(0, 0)
    bubble.Active = true
    local effectiveStyle = bubbleColor
    if effectiveStyle == nil then
        effectiveStyle = isSelf and selfBubbleStyle or messageReceivedColor
    end
    applyBubbleStyleToFrame(bubble, effectiveStyle)
    bubble.BorderSizePixel = 0
    bubble.ClipsDescendants = true
    bubble.Parent = container

    addUICorner(bubble, UDim.new(0, 10))
    local bubbleStroke = addUIStroke(bubble, Color3.fromRGB(255, 255, 255), 1.1, isSelf and 0.5 or 0.6)
    addStrokeGradient(bubbleStroke, strokeGradient, -44)
    applyBubbleBorderToFrame(bubble, bubbleBorderId)

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 2)
    contentLayout.Parent = bubble

    local bubblePadding = Instance.new("UIPadding")
    bubblePadding.PaddingTop = UDim.new(0, 6)
    bubblePadding.PaddingBottom = UDim.new(0, 6)
    bubblePadding.PaddingLeft = UDim.new(0, 10)
    bubblePadding.PaddingRight = UDim.new(0, 10)
    bubblePadding.Parent = bubble

    local maxWidth = Instance.new("UISizeConstraint")
    maxWidth.MaxSize = Vector2.new(170, math.huge)
    maxWidth.Parent = bubble
    
    local lastClickTime = 0
    local longPressThreshold = 0.6
    local isPressing = false
    local longPressFired = false
    local revokeInFlight = false

    local function tryAdminRevoke()
        if not isAdminName(userName) then
            return false
        end
        if isSelf or revokeInFlight then
            return false
        end
        if type(revokeMessageRemote) ~= "function" then
            local notifyParent = rootGui or parent
            createNotification(notifyParent, "撤回接口未初始化", true)
            return false
        end
        revokeInFlight = true
        task.spawn(function()
            local ok, err = revokeMessageRemote(currentRoom, name, message, time, userName)
            local notifyParent = rootGui or parent
            if ok then
                container:Destroy()
                messageUiByKey[tostring(time or "") .. tostring(name or "") .. tostring(message or "")] = nil
                local oldText = messageInput and messageInput.Text or ""
                local oldDm = dmTargetName
                dmTargetName = nil
                if messageInput then
                    messageInput.Text = "##REVOKE##|" .. HttpService:JSONEncode({ n = tostring(name or ""), t = tostring(time or ""), m = tostring(message or "") })
                end
                if type(sendMessageAction) == "function" then
                    sendMessageAction()
                end
                if messageInput then
                    messageInput.Text = oldText
                end
                dmTargetName = oldDm
                createNotification(notifyParent, "撤回成功", false)
            else
                createNotification(notifyParent, tostring(err or "撤回失败"), true)
            end
            revokeInFlight = false
        end)
        return true
    end

    local function handleDoubleTap(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local now = os.clock()
        if now - lastClickTime <= 0.55 then
            tryAdminRevoke()
        end
        lastClickTime = now
    end

    local function handlePressBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isPressing = true
            longPressFired = false
            local pressStart = os.clock()
            task.spawn(function()
                while isPressing and not longPressFired do
                    if os.clock() - pressStart >= longPressThreshold then
                        longPressFired = true
                        if message and message ~= "" then
                            local notifyParent = rootGui or parent
                            if not isSelf and messageInput then
                                if isSystemName(name) then
                                    createNotification(notifyParent, SYSTEM_NAME .. "消息不可回复", true)
                                else
                                    local replyName = name or "未知"
                                    local preview = tostring(message)
                                    if type(message) == "string" then
                                        local decodedMsg = (decodeMessageWithFont(message))
                                        preview = tostring(decodedMsg or "")
                                        if decodedMsg:sub(1, 7) == "##IMG##" then
                                            preview = "[图片]"
                                        else
                                            local singleUrl = decodedMsg:match("^(https?://%S+)$")
                                            if singleUrl then
                                                local ext = singleUrl:match("%.([%a%d]+)$")
                                                if ext then
                                                    ext = string.lower(ext)
                                                    if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" or ext == "webp" then
                                                        preview = "[图片]"
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    if #preview > 40 then
                                        preview = string.sub(preview, 1, 40) .. "..."
                                    end
                                    local current = messageInput.Text or ""
                                    local replyPrefix = "回复 " .. replyName .. ": " .. preview .. "\n"
                                    messageInput.Text = replyPrefix .. current
                                    messageInput:CaptureFocus()
                                    createNotification(notifyParent, "已引用消息", false)
                                end
                            else
                                if setclipboard then
                                    pcall(setclipboard, message)
                                    createNotification(notifyParent, "已复制消息", false)
                                else
                                    createNotification(notifyParent, "当前环境不支持复制", true)
                                end
                            end
                        end
                        break
                    end
                    task.wait(0.05)
                end
            end)
        end
        handleDoubleTap(input)
    end

    local function handlePressEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isPressing = false
        end
    end

    bubble.InputBegan:Connect(handlePressBegan)
    bubble.InputEnded:Connect(handlePressEnded)

    local displayMessageText = message or ""
    if type(displayMessageText) ~= "string" then
        displayMessageText = tostring(displayMessageText)
    end
    local messageFontColor = nil
    if displayMessageText ~= "" then
        local decodedText, decodedColor = decodeMessageWithFont(displayMessageText)
        if decodedText ~= displayMessageText then
            displayMessageText = decodedText
        end
        if decodedColor then
            messageFontColor = decodedColor
        end
    end
    local imageUrl = nil
    if displayMessageText ~= "" then
        local prefix = "##IMG##|"
        if displayMessageText:sub(1, #prefix) == prefix then
            imageUrl = displayMessageText:sub(#prefix + 1)
            displayMessageText = ""
        else
            local singleUrl = displayMessageText:match("^(https?://%S+)$")
            if singleUrl then
                local ext = singleUrl:match("%.([%a%d]+)$")
                if ext then
                    ext = string.lower(ext)
                    if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "gif" or ext == "webp" then
                        imageUrl = singleUrl
                        displayMessageText = ""
                    end
                end
            end
        end
    end
    if imageUrl and imageUrl ~= "" then
        bubblePadding.PaddingTop = UDim.new(0, 6)
        bubblePadding.PaddingBottom = UDim.new(0, 6)
        bubblePadding.PaddingLeft = UDim.new(0, 6)
        bubblePadding.PaddingRight = UDim.new(0, 6)
    end
    local disableCopy = false
    if isSystemName(name) then
        disableCopy = true
    end
    if imageUrl and imageUrl ~= "" then
        disableCopy = true
    elseif type(displayMessageText) == "string" and displayMessageText ~= "" then
        if isSystemName(name) and displayMessageText:find("撤回", 1, true) then
            disableCopy = true
        elseif displayMessageText:sub(1, 5) == "你撤回了" then
            disableCopy = true
        end
    end
    if not isSelf then
        local nameRow = Instance.new("Frame")
        nameRow.Name = "NameRow"
        nameRow.Size = UDim2.new(1, 0, 0, 14)
        nameRow.BackgroundTransparency = 1
        nameRow.LayoutOrder = 1
        nameRow.Parent = bubble
        if imageUrl and imageUrl ~= "" then
            nameRow.Size = UDim2.new(0, 0, 0, 14)
            nameRow.AutomaticSize = Enum.AutomaticSize.X
        end

        local nameLayout = Instance.new("UIListLayout")
        nameLayout.FillDirection = Enum.FillDirection.Horizontal
        nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        nameLayout.Padding = UDim.new(0, 4)
        nameLayout.Parent = nameRow

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(0, 0, 0, 14)
        nameLabel.AutomaticSize = Enum.AutomaticSize.X
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        local displayName = name
        if displayName == nil or displayName == "" then
            displayName = "匿名"
        else
            local nickPart = displayName
            local userPart = ""
            local openParen = string.find(displayName, "(", 1, true)
            local closeParen = openParen and string.find(displayName, ")", openParen + 1, true) or nil
            if openParen and closeParen and closeParen > openParen then
                nickPart = string.sub(displayName, 1, openParen - 1)
                userPart = string.sub(displayName, openParen, #displayName)
            end
            local ok, len = pcall(function()
                return utf8.len(nickPart)
            end)
            if ok and len and len > 10 then
                local cut = utf8.offset(nickPart, 11)
                if cut then
                    nickPart = string.sub(nickPart, 1, cut - 1) .. "..."
                end
            end
            displayName = nickPart .. userPart
        end
        nameLabel.Text = tostring(displayName)
        if isSystemName(name) then
            nameLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
        elseif isAdminName(name) then
            nameLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
        else
            nameLabel.TextColor3 = textColor
        end
        nameLabel.TextSize = 11
        nameLabel.LayoutOrder = 1
        nameLabel.Parent = nameRow

        if not disableCopy then
            local copyBtn = Instance.new("TextButton")
            copyBtn.Name = "CopyButton"
            copyBtn.Size = UDim2.new(0, 32, 0, 16)
            copyBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            copyBtn.BorderSizePixel = 0
            copyBtn.Font = Enum.Font.GothamBold
            copyBtn.Text = "拷贝"
            copyBtn.TextColor3 = Color3.new(1, 1, 1)
            copyBtn.TextSize = 10
            copyBtn.AutoButtonColor = false
            copyBtn.LayoutOrder = 2
            copyBtn.ZIndex = bubble.ZIndex + 1
            copyBtn.Parent = nameRow
            addUICorner(copyBtn, UDim.new(0, 6))
            local copyScale = Instance.new("UIScale")
            copyScale.Scale = 1
            copyScale.Parent = copyBtn
            copyBtn.MouseButton1Click:Connect(function()
                if message and message ~= "" then
                    local toCopy = message
                    if type(toCopy) == "string" then
                        toCopy = (decodeMessageWithFont(toCopy))
                    end
                    if setclipboard then
                        pcall(setclipboard, toCopy)
                    else
                        local notifyParent = rootGui or parent
                        createNotification(notifyParent, "当前环境不支持复制", true)
                    end
                    task.spawn(function()
                        local tweenUp = TweenService:Create(copyScale, TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1.25})
                        local tweenDown = TweenService:Create(copyScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 1})
                        tweenUp:Play()
                        tweenUp.Completed:Wait()
                        tweenDown:Play()
                    end)
                end
            end)
        end
    end

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(0, 0, 0, 0)
    messageLabel.AutomaticSize = Enum.AutomaticSize.XY
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.GothamBold
    if isSystemName(name) then
        messageLabel.RichText = true
    end
    if displayMessageText ~= "" and isAdminName(name) then
        local replaced, count = displayMessageText:gsub("@全体", '<font color="rgb(255,80,80)">@全体</font>')
        if count > 0 then
            displayMessageText = replaced
            messageLabel.RichText = true
        end
    end
    if displayMessageText ~= "" then
        local baseSelfName = normalizeAdminName(userName) or userName
        if baseSelfName and baseSelfName ~= "" then
            local mentionTag = "@" .. baseSelfName
            if displayMessageText:find(mentionTag, 1, true) then
                local pattern = mentionTag:gsub("([%%%[%]%(%)%.%+%-%*%?%$%^])", "%%%1")
                local replacedMention, mentionCount = displayMessageText:gsub(pattern, '<font color="rgb(255,80,80)">' .. mentionTag .. '</font>')
                if mentionCount > 0 then
                    displayMessageText = replacedMention
                    messageLabel.RichText = true
                end
            end
        end
    end
    local effectiveBubbleColor = nil
    if typeof(bubbleColor) == "Color3" then
        effectiveBubbleColor = bubbleColor
    elseif type(bubbleColor) == "table" and type(bubbleColor.colors) == "table" and bubbleColor.colors[1] then
        effectiveBubbleColor = bubbleColor.colors[1]
    else
        if typeof(selfBubbleStyle) == "Color3" then
            effectiveBubbleColor = isSelf and selfBubbleStyle or messageReceivedColor
        elseif type(selfBubbleStyle) == "table" and type(selfBubbleStyle.colors) == "table" and selfBubbleStyle.colors[1] then
            effectiveBubbleColor = isSelf and selfBubbleStyle.colors[1] or messageReceivedColor
        else
            effectiveBubbleColor = isSelf and selfBubbleColor or messageReceivedColor
        end
    end
    messageLabel.Text = displayMessageText
    local desiredTextColor = messageFontColor or (isSelf and selfFontColor) or chatFontColor
    if effectiveBubbleColor and desiredTextColor then
        local cyan = Color3.fromRGB(80, 210, 210)
        local function isCloseColor(a, b)
            return math.abs(a.R - b.R) < 0.002 and math.abs(a.G - b.G) < 0.002 and math.abs(a.B - b.B) < 0.002
        end
        if isCloseColor(desiredTextColor, cyan) then
            local ratio = contrastRatio(effectiveBubbleColor, desiredTextColor)
            local lum = relativeLuminance(effectiveBubbleColor)
            if lum > 0.72 and ratio < 1.8 then
                local black = Color3.new(0, 0, 0)
                local white = Color3.new(1, 1, 1)
                local blackRatio = contrastRatio(effectiveBubbleColor, black)
                local whiteRatio = contrastRatio(effectiveBubbleColor, white)
                desiredTextColor = (blackRatio >= whiteRatio) and black or white
            end
        end
    end
    messageLabel.TextColor3 = desiredTextColor or chatFontColor
    messageLabel.TextSize = 12
    messageLabel.TextWrapped = true
    messageLabel.LayoutOrder = 2
    messageLabel.Visible = imageUrl == nil
    messageLabel.Active = true
    messageLabel.Parent = bubble
    messageLabel.InputBegan:Connect(handlePressBegan)
    messageLabel.InputEnded:Connect(handlePressEnded)
    if imageUrl and imageUrl ~= "" then
        local preview = Instance.new("ImageButton")
        preview.Name = "ImagePreview"
        preview.Size = UDim2.new(0, 120, 0, 90)
        preview.BackgroundTransparency = 1
        preview.BorderSizePixel = 0
        preview.AutoButtonColor = false
        preview.ZIndex = bubble.ZIndex + 1
        preview.LayoutOrder = 2
        preview.Active = true
        preview.Parent = bubble
        addUICorner(preview, UDim.new(0, 10))
        local fileName = imageUrl:match("([^/%?]+)$") or "image.png"
        local resolved = imageUrl
        if remoteEmoji and type(remoteEmoji) == "table" and type(remoteEmoji.resolveImage) == "function" then
            local okResolve, resolvedImage = pcall(remoteEmoji.resolveImage, imageUrl, fileName)
            if okResolve and type(resolvedImage) == "string" and resolvedImage ~= "" then
                resolved = resolvedImage
            end
        end
        preview.Image = resolved
        preview.ScaleType = Enum.ScaleType.Fit
        preview.MouseButton1Click:Connect(function()
            if setclipboard then
                pcall(setclipboard, imageUrl)
            end
        end)
        preview.InputBegan:Connect(handlePressBegan)
        preview.InputEnded:Connect(handlePressEnded)
    end

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "Time"
    timeLabel.Size = UDim2.new(0, 0, 0, 10)
    timeLabel.AutomaticSize = Enum.AutomaticSize.X
    timeLabel.BackgroundTransparency = 1
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.Text = time
    timeLabel.TextColor3 = chatFontColor
    timeLabel.TextSize = 9
    timeLabel.TextTransparency = 0.4
    timeLabel.LayoutOrder = 3
    timeLabel.Parent = bubble

    local shouldAnimate = animate ~= false
    local scale = Instance.new("UIScale")
    scale.Scale = shouldAnimate and 0.85 or 1
    scale.Parent = bubble
    bubble.BackgroundTransparency = shouldAnimate and 1 or 0

    if shouldAnimate then
        task.spawn(function()
            task.wait(0.02)
            tweenProperty(scale, {Scale = 1}, 0.25, Enum.EasingStyle.Back)
            tweenProperty(bubble, {BackgroundTransparency = 0}, 0.2)
        end)
    end

    return container
end

local function createNotification(parent, text, isError)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 220, 0, 36)
    notification.Position = UDim2.new(0.5, 0, 0, -50)
    notification.AnchorPoint = Vector2.new(0.5, 0)
    notification.BackgroundColor3 = isError and errorColor or successColor
    notification.ZIndex = 100
    notification.Parent = parent
    addUICorner(notification, UDim.new(0, 8))
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 12
    label.Parent = notification
    tweenProperty(notification, {Position = UDim2.new(0.5, 0, 0, 10)}, 0.3, Enum.EasingStyle.Back)
    task.delay(2.5, function()
        tweenProperty(notification, {Position = UDim2.new(0.5, 0, 0, -50)}, 0.25)
        task.wait(0.25)
        notification:Destroy()
    end)
    return notification
end

local function parseApiError(body)
    if type(body) ~= "string" then
        return nil
    end
    local err = body:match("\"error\"%s*,%s*\"(.-)\"")
    return err
end

local function sendMessage(room, message, name, apiKey, colorString)
    colorString = colorString or ""
    local ttlParam = ""
    if room ~= FIXED_ROOM then
        ttlParam = "&ttl=172800"
    end
    local url = string.format("%s?action=send&chat-in=%s&msg=%s&name=%s&apikey=%s&color=%s%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(room),
        HttpService:UrlEncode(message),
        HttpService:UrlEncode(name),
        HttpService:UrlEncode(apiKey),
        HttpService:UrlEncode(colorString),
        ttlParam,
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response then
        return false, "请求失败"
    end
    if not response.Success then
        return false, response.StatusMessage or "请求失败"
    end

    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if parseSuccess and type(data) == "table" and data[1] == "success" then
        return true, data[2] or "发送成功"
    end
    
    return false, response.Body or "未知错误"
end

local function getMessages(room, apiKey)
    local url = string.format("%s?action=get&chat-in=%s&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(room),
        HttpService:UrlEncode(apiKey),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response then
        return false, nil, "接收失败"
    end
    if not response.Success then
        return false, nil, response.StatusMessage or "请求失败"
    end

    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if parseSuccess and type(data) == "table" then
        if data[1] == "error" and data[2] then
            return false, nil, tostring(data[2])
        end
        return true, data, nil
    end
    
    return false, nil, "解析失败: " .. response.Body
end

local function sendDirectMessage(target, message, fromName, apiKey)
    local url = string.format("%s?action=send_dm&to=%s&msg=%s&name=%s&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(target or ""),
        HttpService:UrlEncode(message or ""),
        HttpService:UrlEncode(fromName or ""),
        HttpService:UrlEncode(apiKey or ""),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response then
        return false, "请求失败"
    end
    if not response.Success then
        return false, response.StatusMessage or "请求失败"
    end
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if parseSuccess and type(data) == "table" and data[1] == "success" then
        return true, data[2] or "发送成功"
    end
    if parseSuccess and type(data) == "table" and data[1] == "error" and data[2] then
        return false, tostring(data[2])
    end
    return false, response.Body or "未知错误"
end

local function getDirectMessages(name, apiKey)
    local url = string.format("%s?action=get_dm&name=%s&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(name or ""),
        HttpService:UrlEncode(apiKey or ""),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response then
        return false, nil, "接收失败"
    end
    if not response.Success then
        return false, nil, response.StatusMessage or "请求失败"
    end
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if parseSuccess and type(data) == "table" then
        if data[1] == "error" and data[2] then
            return false, nil, tostring(data[2])
        end
        return true, data, nil
    end
    return false, nil, "解析失败: " .. response.Body
end

local function getAnnouncement()
    local url = string.format("%s?action=get_announcement&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(FIXED_API_KEY),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response then
        return false, nil
    end
    if not response.Success then
        return false, nil
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if ok and type(data) == "table" then
        if data[1] == "success" and type(data[2]) == "string" then
            return true, data[2]
        end
    end
    return false, nil
end

local function setAnnouncementRemote(text)
    text = text or ""
    local url = string.format("%s?action=set_announcement&chat-in=%s&msg=%s&name=%s&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(FIXED_ROOM),
        HttpService:UrlEncode(text),
        HttpService:UrlEncode(userName),
        HttpService:UrlEncode(FIXED_API_KEY),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response or not response.Success then
        return false, "设置公告失败"
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if ok and type(data) == "table" then
        if data[1] == "success" then
            return true, data[2] or "公告已更新"
        elseif data[1] == "error" and data[2] then
            return false, tostring(data[2])
        end
    end
    return false, "设置公告返回异常"
end

local function getRoomList(apiKey)
    local url = string.format("%s?action=list_rooms&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(apiKey),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response then
        return false, nil, "获取房间列表失败"
    end
    if not response.Success then
        return false, nil, response.StatusMessage or "获取房间列表失败"
    end

    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if parseSuccess and type(data) == "table" then
        return true, data, nil
    end

    return false, nil, "解析失败: " .. response.Body
end

local function deleteRoomRemote(roomName)
    if not roomName or roomName == "" then
        return false, "房间名不能为空"
    end
    if roomName == FIXED_ROOM then
        return false, "默认房间不能删除"
    end
    local url = string.format("%s?action=delete_room&chat-in=%s&name=%s&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(roomName),
        HttpService:UrlEncode(userName),
        HttpService:UrlEncode(FIXED_API_KEY),
        os.time()
    )
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not success or not response or not response.Success then
        return false, "删除房间失败"
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if ok and type(data) == "table" then
        local tag = data[1]
        local msg = data[2]
        if tag == "success" then
            return true, msg or "删除成功"
        elseif tag == "error" then
            return false, msg or "删除失败"
        end
    end
    return false, "删除房间返回异常"
end

revokeMessageRemote = function(roomName, targetName, targetMsg, targetTime, adminName)
    if not roomName or roomName == "" then
        return false, "房间不能为空"
    end
    if not targetName or targetName == "" then
        return false, "目标用户为空"
    end
    if targetMsg == nil or targetMsg == "" then
        return false, "消息为空"
    end
    if not targetTime or targetTime == "" then
        return false, "时间为空"
    end
    local url = string.format("%s?action=revoke_message&chat-in=%s&target=%s&time=%s&msg=%s&name=%s&apikey=%s&t=%d",
        BASE_URL,
        HttpService:UrlEncode(roomName),
        HttpService:UrlEncode(targetName),
        HttpService:UrlEncode(targetTime),
        HttpService:UrlEncode(tostring(targetMsg)),
        HttpService:UrlEncode(adminName or userName),
        HttpService:UrlEncode(FIXED_API_KEY),
        os.time()
    )
    local okReq, response = pcall(function()
        return request({
            Url = url,
            Method = "GET",
        })
    end)
    if not okReq or not response or not response.Success then
        return false, "请求失败"
    end
    local okJson, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if okJson and type(data) == "table" then
        if data[1] == "success" then
            return true, data[2] or "撤回成功"
        end
        if data[1] == "error" then
            return false, data[2] or "撤回失败"
        end
    end
    return false, response.Body or "撤回失败"
end

local function buildRoomList(data)
    local list = {}
    for _, item in pairs(data) do
        if type(item) == "table" then
            local roomId = item.room or item.name or item.id or item[1]
            if type(roomId) == "string" and roomId ~= "" then
                local lastTimeValue = item.lastTime or item.last or item.time or item[2]
                local lastTime = tonumber(lastTimeValue) or 0
                local creator = item.creator or item.owner or item.user or item[3]
                table.insert(list, {
                    room = roomId,
                    lastTime = lastTime,
                    creator = creator,
                })
            end
        end
    end
    table.sort(list, function(a, b)
        return a.lastTime > b.lastTime
    end)
    return list
end

local function checkRoomExists(roomName)
    if not roomName or roomName == "" then
        return false, "请输入房间号"
    end
    return true
end

local gui = createMainGui()

task.spawn(function()
    while true do
        fetchRemoteAdmins()
        task.wait(30)
    end
end)

local loginPanel, loginFoldButton, roomInput, joinButton, loginLineLayer, loginParticleLayer, loginContent
do
    loginPanel = Instance.new("Frame")
    loginPanel.Name = "LoginPanel"
    loginPanel.Size = UDim2.new(0, 230, 0, 260)
    loginPanel.Position = UDim2.new(0.5, 0, 0.5, -30)
    loginPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    loginPanel.BackgroundColor3 = backgroundSecondary
    loginPanel.BorderSizePixel = 0
    loginPanel.ZIndex = 10
    loginPanel.ClipsDescendants = true
    loginPanel.Parent = gui

    addUICorner(loginPanel, UDim.new(0, 16))
    local loginStroke = addUIStroke(loginPanel, Color3.fromRGB(255, 255, 255), 2.4, 0.2)
    addStrokeGradient(loginStroke, strokeGradient, 0)
    animateStrokeGradient(loginStroke, 18)
    addShadow(loginPanel)

    local loginBgLayer = Instance.new("Frame")
    loginBgLayer.Name = "BgLayer"
    loginBgLayer.Size = UDim2.fromScale(1, 1)
    loginBgLayer.BackgroundColor3 = backgroundColor
    loginBgLayer.BackgroundTransparency = 1
    loginBgLayer.BorderSizePixel = 0
    loginBgLayer.ZIndex = 1
    loginBgLayer.Parent = loginPanel

    addUIGradient(loginBgLayer, backgroundGradient, 68)
    addUICorner(loginBgLayer, UDim.new(0, 16))

    loginLineLayer = Instance.new("Frame")
    loginLineLayer.Name = "LineLayer"
    loginLineLayer.Size = UDim2.fromScale(1, 1)
    loginLineLayer.BackgroundTransparency = 1
    loginLineLayer.ZIndex = 2
    loginLineLayer.Parent = loginPanel

    loginParticleLayer = Instance.new("Frame")
    loginParticleLayer.Name = "ParticleLayer"
    loginParticleLayer.Size = UDim2.fromScale(1, 1)
    loginParticleLayer.BackgroundTransparency = 1
    loginParticleLayer.ZIndex = 3
    loginParticleLayer.Parent = loginPanel

    loginContent = Instance.new("Frame")
    loginContent.Name = "Content"
    loginContent.Size = UDim2.fromScale(1, 1)
    loginContent.BackgroundTransparency = 1
    loginContent.ZIndex = 10
    loginContent.Parent = loginPanel

    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(0, 70, 0, 40)
    logoContainer.Position = UDim2.new(0.5, 0, 0, 26)
    logoContainer.AnchorPoint = Vector2.new(0.5, 0)
    logoContainer.BackgroundColor3 = Color3.fromRGB(180, 140, 255)
    logoContainer.BackgroundTransparency = 0.2
    logoContainer.BorderSizePixel = 0
    logoContainer.ZIndex = 11
    logoContainer.Parent = loginContent

    addUICorner(logoContainer, UDim.new(0, 20))
    local logoStroke = addButtonStroke(logoContainer, 180, 0.45)
    animateStrokeGradient(logoStroke, 18)

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Font = Enum.Font.GothamBlack
    logoText.Text = "STA"
    logoText.TextColor3 = textColor
    logoText.TextSize = 18
    logoText.ZIndex = 12
    logoText.Parent = logoContainer

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 24)
    titleLabel.Position = UDim2.new(0, 0, 0, 78)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "David Station Chat"
    titleLabel.TextColor3 = textColor
    titleLabel.TextSize = 18
    titleLabel.ZIndex = 11
    titleLabel.Parent = loginContent

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 102)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = "浮华万千，藏尽人间声色"
    subtitleLabel.TextColor3 = textMuted
    subtitleLabel.TextSize = 11
    subtitleLabel.ZIndex = 11
    subtitleLabel.Parent = loginContent

    loginFoldButton = Instance.new("TextButton")
    loginFoldButton.Name = "FoldButton"
    loginFoldButton.Size = UDim2.new(0, 24, 0, 24)
    loginFoldButton.Position = UDim2.new(1, -32, 0, 10)
    loginFoldButton.BackgroundColor3 = backgroundTertiary
    loginFoldButton.BorderSizePixel = 0
    loginFoldButton.Font = Enum.Font.GothamBold
    loginFoldButton.Text = "—"
    loginFoldButton.TextColor3 = textColor
    loginFoldButton.TextSize = 14
    loginFoldButton.AutoButtonColor = false
    loginFoldButton.ZIndex = 12
    loginFoldButton.Parent = loginContent

    addUICorner(loginFoldButton, UDim.new(0, 6))
    addUIGradient(loginFoldButton, backgroundGradient, 68)
    addButtonStroke(loginFoldButton, 180, 0.45)

    loginFoldButton.MouseEnter:Connect(function()
        tweenProperty(loginFoldButton, {BackgroundTransparency = 0.35}, 0.15)
    end)

    loginFoldButton.MouseLeave:Connect(function()
        tweenProperty(loginFoldButton, {BackgroundTransparency = 0}, 0.15)
    end)

    local roomContainer
    roomContainer, roomInput = createTextBox(loginContent, "房间号", UDim2.new(0.85, 0, 0, 32), UDim2.new(0.5, 0, 0, 135))
    roomContainer.ZIndex = 11
    roomInput.ZIndex = 12
    roomInput.ClearTextOnFocus = true

    joinButton = createButton(loginContent, "加入房间", UDim2.new(0.5, 0, 0, 32), UDim2.new(0.5, 0, 0, 188), false)
    joinButton.ZIndex = 11
end

local chatPanel, chatLineLayer, chatParticleLayer, chatContent
do
    chatPanel = Instance.new("Frame")
    chatPanel.Name = "ChatPanel"
    chatPanel.Size = UDim2.new(0, 340, 0, 350)
    chatPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
    chatPanel.AnchorPoint = Vector2.new(0.5, 0.5)
    chatPanel.BackgroundColor3 = backgroundSecondary
    chatPanel.BorderSizePixel = 0
    chatPanel.Visible = false
    chatPanel.ZIndex = 10
    chatPanel.ClipsDescendants = true
    chatPanel.Parent = gui

    addUICorner(chatPanel, UDim.new(0, 18))
    local chatStroke = addUIStroke(chatPanel, Color3.fromRGB(255, 255, 255), 2.4, 0.2)
    addStrokeGradient(chatStroke, strokeGradient, 0)
    animateStrokeGradient(chatStroke, 18)
    addShadow(chatPanel)

    local chatBgLayer = Instance.new("Frame")
    chatBgLayer.Name = "BgLayer"
    chatBgLayer.Size = UDim2.fromScale(1, 1)
    chatBgLayer.BackgroundColor3 = backgroundColor
    chatBgLayer.BackgroundTransparency = 1
    chatBgLayer.BorderSizePixel = 0
    chatBgLayer.ZIndex = 1
    chatBgLayer.Parent = chatPanel

    addUIGradient(chatBgLayer, backgroundGradient, 68)
    addUICorner(chatBgLayer, UDim.new(0, 18))

    chatBgImage = Instance.new("ImageLabel")
    chatBgImage.Name = "BackgroundImage"
    chatBgImage.Size = UDim2.fromScale(1, 1)
    chatBgImage.Position = UDim2.fromScale(0, 0)
    chatBgImage.BackgroundTransparency = 1
    chatBgImage.Image = ""
    chatBgImage.ImageTransparency = 0.12
    chatBgImage.ScaleType = Enum.ScaleType.Crop
    chatBgImage.ZIndex = 1
    chatBgImage.Visible = false
    chatBgImage.Parent = chatBgLayer
    addUICorner(chatBgImage, UDim.new(0, 18))
    ThirdGenChat_ApplyBackgroundSetting()

    chatLineLayer = Instance.new("Frame")
    chatLineLayer.Name = "LineLayer"
    chatLineLayer.Size = UDim2.fromScale(1, 1)
    chatLineLayer.BackgroundTransparency = 1
    chatLineLayer.ZIndex = 2
    chatLineLayer.Parent = chatPanel

    chatParticleLayer = Instance.new("Frame")
    chatParticleLayer.Name = "ParticleLayer"
    chatParticleLayer.Size = UDim2.fromScale(1, 1)
    chatParticleLayer.BackgroundTransparency = 1
    chatParticleLayer.ZIndex = 3
    chatParticleLayer.Parent = chatPanel

    chatContent = Instance.new("Frame")
    chatContent.Name = "Content"
    chatContent.Size = UDim2.fromScale(1, 1)
    chatContent.BackgroundTransparency = 1
    chatContent.ZIndex = 10
    chatContent.Parent = chatPanel
end

local muteMenu
local muteTargetName
local muteTitle
local muteCustomInput
local muteListPanel
local muteListScroll
local adminPanel
local adminNameInput
local adminListScroll

local function sendMuteCommand(targetName, seconds, reason, meta)
    if not currentRoom or not targetName then
        return false
    end
    if isCreatorAdminName(targetName) and not isCreatorAdminName(userName) then
        createNotification(gui, "不能禁言创世管理员", true)
        return false
    end
    if seconds > 0 and isAdminName(userName) and isAdminName(targetName) and (not isCreatorAdminName(userName)) then
        createNotification(gui, "管理员之间不能互相禁言", true)
        return false
    end
    if seconds <= 0 then
        local issuer = muteIssuer[targetName]
        if issuer and issuer.creator and (not isCreatorAdminName(userName)) then
            createNotification(gui, "创世管理员禁言的成员无法被解除", true)
            return false
        end
    end
    if isSuperAdminName(targetName) and (not isSuperAdminName(userName)) and (not isCreatorAdminName(userName)) then
        createNotification(gui, "不能禁言超级管理员", true)
        return false
    end
    local expireAt = os.time() + math.max(seconds, 0)
    if seconds <= 0 then
        muteList[targetName] = nil
        muteIssuer[targetName] = nil
    else
        muteList[targetName] = expireAt
        muteIssuer[targetName] = { by = normalizeAdminName(userName) or userName, creator = isCreatorAdminName(userName) }
    end
    local controlMsg = "##MUTE##|" .. targetName .. "|" .. tostring(expireAt)
    if reason and reason ~= "" then
        controlMsg = controlMsg .. "|" .. tostring(reason)
    end
    if type(meta) == "table" then
        if meta.duration and tonumber(meta.duration) then
            controlMsg = controlMsg .. "|" .. tostring(math.floor(tonumber(meta.duration)))
        end
        if meta.stage and tonumber(meta.stage) then
            controlMsg = controlMsg .. "|" .. tostring(math.floor(tonumber(meta.stage)))
        end
    end
    task.spawn(function()
        sendMessage(currentRoom, controlMsg, userName, API_KEY, "")
        if currentRoom ~= FIXED_ROOM then
            sendMessage(FIXED_ROOM, controlMsg, userName, FIXED_API_KEY, "")
        end
    end)
    if isAdminName(userName) then
        if seconds <= 0 then
            createNotification(gui, "已解除禁言: " .. targetName, false)
        else
            local minutes = math.floor(seconds / 60 + 0.5)
            if minutes <= 0 then
                minutes = 1
            end
            createNotification(gui, "已禁言 " .. targetName .. " " .. tostring(minutes) .. " 分钟", false)
        end
    end
    return true
end

local function openMuteList()
    if not isAdminName(userName) then
        return
    end
    if not muteListPanel then
        muteListPanel = Instance.new("Frame")
        muteListPanel.Name = "MuteListPanel"
        muteListPanel.Size = UDim2.new(0, 220, 0, 220)
        muteListPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
        muteListPanel.AnchorPoint = Vector2.new(0.5, 0.5)
        muteListPanel.BackgroundColor3 = backgroundTertiary
        muteListPanel.BorderSizePixel = 0
        muteListPanel.Visible = false
        muteListPanel.ZIndex = 32
        muteListPanel.Parent = chatPanel

        addUICorner(muteListPanel, UDim.new(0, 10))
        addUIGradient(muteListPanel, backgroundGradient, 68)
        addUIStroke(muteListPanel, Color3.fromRGB(255, 255, 255), 1.2, 0.4)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 0, 20)
        title.Position = UDim2.new(0, 8, 0, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "禁言名单"
        title.ZIndex = 33
        title.Parent = muteListPanel

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -24, 0, 4)
        closeBtn.BackgroundColor3 = backgroundSecondary
        closeBtn.BorderSizePixel = 0
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "X"
        closeBtn.TextColor3 = textColor
        closeBtn.TextSize = 12
        closeBtn.ZIndex = 33
        closeBtn.AutoButtonColor = false
        closeBtn.Parent = muteListPanel
        addUICorner(closeBtn, UDim.new(0, 6))
        closeBtn.MouseButton1Click:Connect(function()
            muteListPanel.Visible = false
        end)

        muteListScroll = Instance.new("ScrollingFrame")
        muteListScroll.Size = UDim2.new(1, -16, 1, -40)
        muteListScroll.Position = UDim2.new(0, 8, 0, 32)
        muteListScroll.BackgroundTransparency = 1
        muteListScroll.ScrollBarThickness = 4
        muteListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        muteListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        muteListScroll.ZIndex = 33
        muteListScroll.Parent = muteListPanel

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 4)
        listLayout.Parent = muteListScroll
    end

    for _, child in ipairs(muteListScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end

    local now = os.time()
    local hasMuted = false
    for name, expireAt in pairs(muteList) do
        if type(expireAt) == "number" and expireAt > now then
            hasMuted = true
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 26)
            row.BackgroundColor3 = backgroundSecondary
            row.BorderSizePixel = 0
            row.ZIndex = 34
            row.Parent = muteListScroll
            addUICorner(row, UDim.new(0, 6))

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 6, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.Text = name
            nameLabel.TextColor3 = textColor
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.ZIndex = 35
            nameLabel.Parent = row

            local remaining = expireAt - now
            if remaining < 0 then
                remaining = 0
            end
            local minutes = math.floor(remaining / 60)
            local seconds = remaining % 60
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(0.35, 0, 1, 0)
            timeLabel.Position = UDim2.new(0.4, 0, 0, 0)
            timeLabel.BackgroundTransparency = 1
            timeLabel.Font = Enum.Font.Gotham
            timeLabel.Text = tostring(minutes) .. "分" .. tostring(seconds) .. "秒"
            timeLabel.TextColor3 = textMuted
            timeLabel.TextSize = 10
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            timeLabel.ZIndex = 35
            timeLabel.Parent = row

            local unmuteBtn = Instance.new("TextButton")
            unmuteBtn.Size = UDim2.new(0.2, -10, 0, 20)
            unmuteBtn.Position = UDim2.new(0.8, 5, 0.5, -10)
            unmuteBtn.BackgroundColor3 = backgroundColor
            unmuteBtn.BorderSizePixel = 0
            unmuteBtn.Font = Enum.Font.Gotham
            unmuteBtn.Text = "解除"
            unmuteBtn.TextColor3 = textColor
            unmuteBtn.TextSize = 11
            unmuteBtn.AutoButtonColor = false
            unmuteBtn.ZIndex = 35
            unmuteBtn.Parent = row
            addUICorner(unmuteBtn, UDim.new(0, 6))
            unmuteBtn.MouseButton1Click:Connect(function()
                local ok = sendMuteCommand(name, 0)
                if ok then
                    row:Destroy()
                end
            end)
        end
    end

    if not hasMuted then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, -16, 1, -40)
        emptyLabel.Position = UDim2.new(0, 8, 0, 40)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Text = "暂无禁言人员"
        emptyLabel.TextColor3 = textMuted
        emptyLabel.TextSize = 12
        emptyLabel.ZIndex = 34
        emptyLabel.TextWrapped = true
        emptyLabel.Parent = muteListScroll
    end

    muteListPanel.Visible = true
end

openMuteMenu = function(targetName)
    if not isAdminName(userName) then
        return
    end
    muteTargetName = targetName
    if not muteMenu then
        muteMenu = Instance.new("Frame")
        muteMenu.Name = "MuteMenu"
        muteMenu.Size = UDim2.new(0, 160, 0, 170)
        muteMenu.Position = UDim2.new(0.5, 0, 0.5, 0)
        muteMenu.AnchorPoint = Vector2.new(0.5, 0.5)
        muteMenu.BackgroundColor3 = backgroundTertiary
        muteMenu.BorderSizePixel = 0
        muteMenu.Visible = false
        muteMenu.ZIndex = 30
        muteMenu.Parent = chatPanel

        addUICorner(muteMenu, UDim.new(0, 10))
        addUIGradient(muteMenu, backgroundGradient, 68)
        addUIStroke(muteMenu, Color3.fromRGB(255, 255, 255), 1.2, 0.4)

        muteTitle = Instance.new("TextLabel")
        muteTitle.Size = UDim2.new(1, -16, 0, 20)
        muteTitle.Position = UDim2.new(0, 8, 0, 8)
        muteTitle.BackgroundTransparency = 1
        muteTitle.Font = Enum.Font.GothamBold
        muteTitle.TextColor3 = Color3.new(1, 1, 1)
        muteTitle.TextSize = 12
        muteTitle.TextXAlignment = Enum.TextXAlignment.Left
        muteTitle.ZIndex = 31
        muteTitle.Parent = muteMenu

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -24, 0, 4)
        closeBtn.BackgroundColor3 = backgroundSecondary
        closeBtn.BorderSizePixel = 0
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "X"
        closeBtn.TextColor3 = textColor
        closeBtn.TextSize = 12
        closeBtn.ZIndex = 31
        closeBtn.AutoButtonColor = false
        closeBtn.Parent = muteMenu
        addUICorner(closeBtn, UDim.new(0, 6))
        closeBtn.MouseButton1Click:Connect(function()
            muteMenu.Visible = false
        end)

        local timeRow = Instance.new("Frame")
        timeRow.Size = UDim2.new(1, -16, 0, 24)
        timeRow.Position = UDim2.new(0, 8, 0, 36)
        timeRow.BackgroundTransparency = 1
        timeRow.ZIndex = 31
        timeRow.Parent = muteMenu

        local timeLayout = Instance.new("UIListLayout")
        timeLayout.FillDirection = Enum.FillDirection.Horizontal
        timeLayout.SortOrder = Enum.SortOrder.LayoutOrder
        timeLayout.Padding = UDim.new(0, 4)
        timeLayout.Parent = timeRow

        local btn1 = Instance.new("TextButton")
        btn1.Size = UDim2.new(1 / 3, -4, 1, 0)
        btn1.BackgroundColor3 = backgroundSecondary
        btn1.BorderSizePixel = 0
        btn1.Font = Enum.Font.Gotham
        btn1.Text = "1分钟"
        btn1.TextColor3 = textColor
        btn1.TextSize = 12
        btn1.ZIndex = 31
        btn1.AutoButtonColor = false
        btn1.Parent = timeRow
        addUICorner(btn1, UDim.new(0, 6))

        local btn5 = Instance.new("TextButton")
        btn5.Size = UDim2.new(1 / 3, -4, 1, 0)
        btn5.BackgroundColor3 = backgroundSecondary
        btn5.BorderSizePixel = 0
        btn5.Font = Enum.Font.Gotham
        btn5.Text = "5分钟"
        btn5.TextColor3 = textColor
        btn5.TextSize = 12
        btn5.ZIndex = 31
        btn5.AutoButtonColor = false
        btn5.Parent = timeRow
        addUICorner(btn5, UDim.new(0, 6))

        local btn10 = Instance.new("TextButton")
        btn10.Size = UDim2.new(1 / 3, -4, 1, 0)
        btn10.BackgroundColor3 = backgroundSecondary
        btn10.BorderSizePixel = 0
        btn10.Font = Enum.Font.Gotham
        btn10.Text = "10分钟"
        btn10.TextColor3 = textColor
        btn10.TextSize = 12
        btn10.ZIndex = 31
        btn10.AutoButtonColor = false
        btn10.Parent = timeRow
        addUICorner(btn10, UDim.new(0, 6))

        local actionRow = Instance.new("Frame")
        actionRow.Name = "ActionRow"
        actionRow.Size = UDim2.new(1, -16, 0, 22)
        actionRow.Position = UDim2.new(0, 8, 0, 64)
        actionRow.BackgroundTransparency = 1
        actionRow.ZIndex = 31
        actionRow.Parent = muteMenu

        local actionLayout = Instance.new("UIListLayout")
        actionLayout.FillDirection = Enum.FillDirection.Horizontal
        actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        actionLayout.Padding = UDim.new(0, 6)
        actionLayout.Parent = actionRow

        local dmBtn = Instance.new("TextButton")
        dmBtn.Name = "DmButton"
        dmBtn.Size = UDim2.new(0.62, -3, 1, 0)
        dmBtn.BackgroundColor3 = accentColor
        dmBtn.BorderSizePixel = 0
        dmBtn.Font = Enum.Font.GothamBold
        dmBtn.Text = "私信"
        dmBtn.TextColor3 = textColor
        dmBtn.TextSize = 12
        dmBtn.ZIndex = 31
        dmBtn.AutoButtonColor = false
        dmBtn.LayoutOrder = 1
        dmBtn.Parent = actionRow
        addUICorner(dmBtn, UDim.new(0, 6))

        local atBtn = Instance.new("TextButton")
        atBtn.Name = "AtButton"
        atBtn.Size = UDim2.new(0.38, -3, 1, 0)
        atBtn.BackgroundColor3 = accentColor
        atBtn.BorderSizePixel = 0
        atBtn.Font = Enum.Font.GothamBold
        atBtn.Text = "@"
        atBtn.TextColor3 = textColor
        atBtn.TextSize = 12
        atBtn.ZIndex = 31
        atBtn.AutoButtonColor = false
        atBtn.LayoutOrder = 2
        atBtn.Parent = actionRow
        addUICorner(atBtn, UDim.new(0, 6))

        muteCustomInput = Instance.new("TextBox")
        muteCustomInput.Size = UDim2.new(0.5, -12, 0, 24)
        muteCustomInput.Position = UDim2.new(0, 8, 0, 146)
        muteCustomInput.BackgroundColor3 = backgroundSecondary
        muteCustomInput.BorderSizePixel = 0
        muteCustomInput.Font = Enum.Font.Gotham
        muteCustomInput.PlaceholderText = "自定义分钟"
        muteCustomInput.PlaceholderColor3 = textMuted
        muteCustomInput.Text = ""
        muteCustomInput.TextColor3 = textColor
        muteCustomInput.TextSize = 12
        muteCustomInput.ZIndex = 31
        muteCustomInput.Parent = muteMenu
        addUICorner(muteCustomInput, UDim.new(0, 6))

        local customBtn = Instance.new("TextButton")
        customBtn.Size = UDim2.new(0.5, -12, 0, 24)
        customBtn.Position = UDim2.new(0.5, 4, 0, 146)
        customBtn.BackgroundColor3 = backgroundSecondary
        customBtn.BorderSizePixel = 0
        customBtn.Font = Enum.Font.Gotham
        customBtn.Text = "自定义禁言"
        customBtn.TextColor3 = textColor
        customBtn.TextSize = 12
        customBtn.ZIndex = 31
        customBtn.AutoButtonColor = false
        customBtn.Parent = muteMenu
        addUICorner(customBtn, UDim.new(0, 6))

        local listBtn = Instance.new("TextButton")
        listBtn.Size = UDim2.new(1, -16, 0, 22)
        listBtn.Position = UDim2.new(0, 8, 0, 90)
        listBtn.BackgroundColor3 = backgroundSecondary
        listBtn.BorderSizePixel = 0
        listBtn.Font = Enum.Font.Gotham
        listBtn.Text = "查看禁言名单"
        listBtn.TextColor3 = textColor
        listBtn.TextSize = 12
        listBtn.ZIndex = 31
        listBtn.AutoButtonColor = false
        listBtn.Parent = muteMenu
        addUICorner(listBtn, UDim.new(0, 6))

        local unmuteBtn = Instance.new("TextButton")
        unmuteBtn.Size = UDim2.new(1, -16, 0, 24)
        unmuteBtn.Position = UDim2.new(0, 8, 0, 118)
        unmuteBtn.BackgroundColor3 = backgroundSecondary
        unmuteBtn.BorderSizePixel = 0
        unmuteBtn.Font = Enum.Font.Gotham
        unmuteBtn.Text = "解除禁言"
        unmuteBtn.TextColor3 = textColor
        unmuteBtn.TextSize = 12
        unmuteBtn.ZIndex = 31
        unmuteBtn.AutoButtonColor = false
        unmuteBtn.Parent = muteMenu
        addUICorner(unmuteBtn, UDim.new(0, 6))

        btn1.MouseButton1Click:Connect(function()
            if muteTargetName then
                if isAdminName(muteTargetName) and (not isCreatorAdminName(userName)) then
                    createNotification(gui, "管理员之间不能互相禁言", true)
                    return
                end
                sendMuteCommand(muteTargetName, 60)
                muteMenu.Visible = false
            end
        end)

        btn5.MouseButton1Click:Connect(function()
            if muteTargetName then
                if isAdminName(muteTargetName) and (not isCreatorAdminName(userName)) then
                    createNotification(gui, "管理员之间不能互相禁言", true)
                    return
                end
                sendMuteCommand(muteTargetName, 300)
                muteMenu.Visible = false
            end
        end)

        btn10.MouseButton1Click:Connect(function()
            if muteTargetName then
                if isAdminName(muteTargetName) and (not isCreatorAdminName(userName)) then
                    createNotification(gui, "管理员之间不能互相禁言", true)
                    return
                end
                sendMuteCommand(muteTargetName, 600)
                muteMenu.Visible = false
            end
        end)

        customBtn.MouseButton1Click:Connect(function()
            if muteTargetName and muteCustomInput and muteCustomInput.Text ~= "" then
                if isAdminName(muteTargetName) and (not isCreatorAdminName(userName)) then
                    createNotification(gui, "管理员之间不能互相禁言", true)
                    return
                end
                local minutes = tonumber(muteCustomInput.Text)
                if minutes and minutes > 0 then
                    sendMuteCommand(muteTargetName, minutes * 60)
                    muteMenu.Visible = false
                end
            end
        end)

        listBtn.MouseButton1Click:Connect(function()
            openMuteList()
        end)

        atBtn.MouseButton1Click:Connect(function()
            if muteTargetName and messageInput then
                local baseName = muteTargetName
                local openParen = string.find(baseName, "(", 1, true)
                local closeParen = openParen and string.find(baseName, ")", openParen + 1, true) or nil
                if openParen and closeParen and closeParen > openParen then
                    baseName = string.sub(baseName, openParen + 1, closeParen - 1)
                end
                if baseName ~= "" then
                    local atText = "@" .. baseName .. " "
                    local current = messageInput.Text or ""
                    if current == "" then
                        messageInput.Text = atText
                    else
                        if not current:find(atText, 1, true) then
                            messageInput.Text = atText .. current
                        end
                    end
                    messageInput:CaptureFocus()
                    createNotification(gui, "已填入 " .. atText, false)
                    muteMenu.Visible = false
                end
            else
                createNotification(gui, "当前无法 @ 该用户", true)
                if muteMenu then
                    muteMenu.Visible = false
                end
            end
        end)

        dmBtn.MouseButton1Click:Connect(function()
            if not muteTargetName or muteTargetName == "" then
                createNotification(gui, "当前无法私信该用户", true)
                if muteMenu then
                    muteMenu.Visible = false
                end
                return
            end
            if not isAdminName(userName) then
                createNotification(gui, "只有管理员可以私信", true)
                if muteMenu then
                    muteMenu.Visible = false
                end
                return
            end
            dmTargetName = muteTargetName
            if messageInput then
                messageInput.PlaceholderText = "私信给 " .. tostring(muteTargetName) .. "..."
                messageInput:CaptureFocus()
            end
            createNotification(gui, "已进入私信模式", false)
            muteMenu.Visible = false
        end)

        unmuteBtn.MouseButton1Click:Connect(function()
            if muteTargetName then
                local ok = sendMuteCommand(muteTargetName, 0)
                if ok then
                    muteMenu.Visible = false
                end
            end
        end)
    end
    if muteTitle then
        muteTitle.Text = "禁言: " .. targetName
    end
    if muteCustomInput then
        muteCustomInput.Text = ""
    end
    muteMenu.Visible = true
end

local function refreshAdminList()
    if not adminListScroll then
        return
    end
    for _, child in ipairs(adminListScroll:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    local hasAdmin = false
    for name, _ in pairs(remoteAdmins) do
        hasAdmin = true
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -4, 0, 26)
        row.BackgroundColor3 = backgroundSecondary
        row.BorderSizePixel = 0
        row.ZIndex = 52
        row.Parent = adminListScroll
        addUICorner(row, UDim.new(0, 6))

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 6, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.Text = name
        nameLabel.TextColor3 = textColor
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 53
        nameLabel.Parent = row

        local removeBtn = Instance.new("TextButton")
        removeBtn.Size = UDim2.new(0.3, -10, 0, 20)
        removeBtn.Position = UDim2.new(0.7, 4, 0.5, -10)
        removeBtn.BackgroundColor3 = errorColor
        removeBtn.BorderSizePixel = 0
        removeBtn.Font = Enum.Font.Gotham
        removeBtn.Text = "移除"
        removeBtn.TextColor3 = textColor
        removeBtn.TextSize = 11
        removeBtn.AutoButtonColor = false
        removeBtn.ZIndex = 53
        removeBtn.Parent = row
        addUICorner(removeBtn, UDim.new(0, 6))

        removeBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                local success, msg = removeAdminRemote(name)
                if success then
                    fetchRemoteAdmins()
                    createNotification(gui, msg or "移除成功", false)
                    refreshAdminList()
                else
                    createNotification(gui, msg or "移除失败", true)
                end
            end)
        end)
    end
    if not hasAdmin then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Size = UDim2.new(1, -16, 1, -40)
        emptyLabel.Position = UDim2.new(0, 8, 0, 40)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Text = "暂无管理员数据"
        emptyLabel.TextColor3 = textMuted
        emptyLabel.TextSize = 12
        emptyLabel.ZIndex = 52
        emptyLabel.TextWrapped = true
        emptyLabel.Parent = adminListScroll
    end
end

openAdminPanel = function()
    if not isSuperAdminName(LocalPlayer.Name) then
        return
    end
    if not adminPanel then
        adminPanel = Instance.new("Frame")
        adminPanel.Name = "AdminPanel"
        adminPanel.Size = UDim2.new(0, 260, 0, 260)
        adminPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
        adminPanel.AnchorPoint = Vector2.new(0.5, 0.5)
        adminPanel.BackgroundColor3 = backgroundTertiary
        adminPanel.BorderSizePixel = 0
        adminPanel.Visible = false
        adminPanel.ZIndex = 50
        adminPanel.Parent = gui

        addUICorner(adminPanel, UDim.new(0, 10))
        addUIGradient(adminPanel, backgroundGradient, 68)
        addUIStroke(adminPanel, Color3.fromRGB(255, 255, 255), 1.2, 0.4)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -16, 0, 20)
        title.Position = UDim2.new(0, 8, 0, 8)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextColor3 = textColor
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "管理员管理"
        title.ZIndex = 51
        title.Parent = adminPanel

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -24, 0, 4)
        closeBtn.BackgroundColor3 = backgroundSecondary
        closeBtn.BorderSizePixel = 0
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "X"
        closeBtn.TextColor3 = textColor
        closeBtn.TextSize = 12
        closeBtn.ZIndex = 51
        closeBtn.AutoButtonColor = false
        closeBtn.Parent = adminPanel
        addUICorner(closeBtn, UDim.new(0, 6))
        closeBtn.MouseButton1Click:Connect(function()
            adminPanel.Visible = false
        end)

        local announceInput = Instance.new("TextBox")
        announceInput.Size = UDim2.new(1, -16, 0, 24)
        announceInput.Position = UDim2.new(0, 8, 0, 40)
        announceInput.BackgroundColor3 = backgroundSecondary
        announceInput.BorderSizePixel = 0
        announceInput.Font = Enum.Font.Gotham
        announceInput.PlaceholderText = "输入全服公告内容"
        announceInput.PlaceholderColor3 = textMuted
        announceInput.Text = ""
        announceInput.TextColor3 = textColor
        announceInput.TextSize = 12
        announceInput.ZIndex = 51
        announceInput.Parent = adminPanel
        addUICorner(announceInput, UDim.new(0, 6))

        local announceBtn = Instance.new("TextButton")
        announceBtn.Size = UDim2.new(1, -16, 0, 24)
        announceBtn.Position = UDim2.new(0, 8, 0, 72)
        announceBtn.BackgroundColor3 = accentColor
        announceBtn.BorderSizePixel = 0
        announceBtn.Font = Enum.Font.GothamBold
        announceBtn.Text = "发布公告"
        announceBtn.TextColor3 = textColor
        announceBtn.TextSize = 12
        announceBtn.AutoButtonColor = false
        announceBtn.ZIndex = 51
        announceBtn.Parent = adminPanel
        addUICorner(announceBtn, UDim.new(0, 6))

        announceBtn.MouseButton1Click:Connect(function()
            local text = ""
            if announceInput then
                text = announceInput.Text or ""
            end
            applyAnnouncement(text)
            task.spawn(function()
                local ok, msg = setAnnouncementRemote(text)
                if ok then
                    createNotification(gui, msg or "公告已更新", false)
                else
                    createNotification(gui, msg or "公告更新失败", true)
                end
            end)
        end)

    end
    adminPanel.Visible = true
end

local headerBar = Instance.new("Frame")
headerBar.Name = "Header"
headerBar.Size = UDim2.new(1, 0, 0, 44)
headerBar.BackgroundColor3 = backgroundTertiary
headerBar.BackgroundTransparency = 1
headerBar.BorderSizePixel = 0
headerBar.ZIndex = 11
headerBar.Parent = chatContent

addUICorner(headerBar, UDim.new(0, 14))
addUIGradient(headerBar, backgroundGradient, 68)

local headerMask = Instance.new("Frame")
headerMask.Size = UDim2.new(1, 0, 0, 20)
headerMask.Position = UDim2.new(0, 0, 1, -20)
headerMask.BackgroundColor3 = backgroundTertiary
headerMask.BackgroundTransparency = 1
headerMask.BorderSizePixel = 0
headerMask.ZIndex = 11
headerMask.Parent = headerBar

addUIGradient(headerMask, backgroundGradient, 68)

local roomTitle = Instance.new("TextLabel")
roomTitle.Name = "RoomTitle"
roomTitle.Size = UDim2.new(1, -160, 0, 20)
roomTitle.Position = UDim2.new(0.5, 0, 0, 6)
roomTitle.AnchorPoint = Vector2.new(0.5, 0)
roomTitle.BackgroundTransparency = 1
roomTitle.Font = Enum.Font.GothamBold
roomTitle.Text = "房间: ---"
roomTitle.TextColor3 = textColor
roomTitle.TextSize = 14
roomTitle.TextXAlignment = Enum.TextXAlignment.Center
roomTitle.ZIndex = 12
roomTitle.Parent = headerBar

local statusIndicator = Instance.new("Frame")
statusIndicator.Name = "StatusIndicator"
statusIndicator.Size = UDim2.new(0, 8, 0, 8)
statusIndicator.Position = UDim2.new(0, 8, 0, 6)
statusIndicator.BackgroundColor3 = successColor
statusIndicator.BorderSizePixel = 0
statusIndicator.ZIndex = 12
statusIndicator.Parent = headerBar

addUICorner(statusIndicator, UDim.new(1, 0))

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(0, 60, 0, 12)
statusLabel.Position = UDim2.new(0, 20, 0, 4)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "已连接"
statusLabel.TextColor3 = textMuted
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 12
statusLabel.Parent = headerBar

local announcementFrame = Instance.new("Frame")
announcementFrame.Name = "AnnouncementFrame"
announcementFrame.Size = UDim2.new(1, -116, 0, 16)
announcementFrame.Position = UDim2.new(0, 8, 0, 26)
announcementFrame.BackgroundTransparency = 1
announcementFrame.ZIndex = 12
announcementFrame.Parent = headerBar

local announcementClip = Instance.new("Frame")
announcementClip.Name = "AnnouncementClip"
announcementClip.Size = UDim2.new(1, 0, 1, 0)
announcementClip.BackgroundTransparency = 1
announcementClip.ClipsDescendants = true
announcementClip.ZIndex = 12
announcementClip.Parent = announcementFrame

local announcementLabel = Instance.new("TextLabel")
announcementLabel.Name = "AnnouncementLabel"
announcementLabel.Size = UDim2.new(0, 0, 1, 0)
announcementLabel.Position = UDim2.new(0, 0, 0, 0)
announcementLabel.AutomaticSize = Enum.AutomaticSize.X
announcementLabel.BackgroundTransparency = 1
announcementLabel.Font = Enum.Font.GothamBold
announcementLabel.Text = ""
announcementLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
announcementLabel.TextSize = 11
announcementLabel.TextXAlignment = Enum.TextXAlignment.Left
announcementLabel.RichText = true
announcementLabel.ZIndex = 12
announcementLabel.Parent = announcementClip

applyAnnouncement = function(text)
    currentAnnouncement = text or ""
    announcementVersion = announcementVersion + 1
    local myVersion = announcementVersion
    if not announcementLabel or not announcementClip then
        return
    end
    if currentAnnouncement == "" then
        announcementLabel.Text = ""
        announcementLabel.Position = UDim2.new(0, 0, 0, 0)
        return
    end
    local function escapeRichText(str)
        str = tostring(str or "")
        str = str:gsub("&", "&amp;")
        str = str:gsub("<", "&lt;")
        str = str:gsub(">", "&gt;")
        return str
    end
    local displayText = '<font color="rgb(255,0,0)">公告：</font>' .. escapeRichText(currentAnnouncement)
    announcementLabel.Text = displayText
    task.spawn(function()
        task.wait(0.1)
        local padding = 40
        local function getStableTextWidth()
            local last = -1
            local stable = 0
            local startAt = os.clock()
            while os.clock() - startAt < 2 do
                RunService.Heartbeat:Wait()
                local w = announcementLabel.TextBounds.X
                if w and w > 0 then
                    if last > 0 and math.abs(w - last) < 0.5 then
                        stable = stable + 1
                    else
                        stable = 0
                    end
                    last = w
                    if stable >= 3 then
                        return w
                    end
                end
            end
            return announcementLabel.TextBounds.X
        end
        while myVersion == announcementVersion do
            local clipWidth = announcementClip.AbsoluteSize.X
            local textWidth = getStableTextWidth()
            if clipWidth <= 0 or textWidth <= 0 then
                task.wait(0.5)
            else
                announcementLabel.Position = UDim2.new(0, clipWidth, 0, 0)
                local distance = clipWidth + textWidth + padding
                local speed = 40
                local duration = math.max(8, distance / speed)
                local tween = tweenProperty(announcementLabel, {Position = UDim2.new(0, -textWidth - padding, 0, 0)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                local doneState = nil
                if tween then
                    tween.Completed:Connect(function(state)
                        doneState = state
                    end)
                else
                    doneState = Enum.PlaybackState.Completed
                end
                local startAt = os.clock()
                while myVersion == announcementVersion and doneState == nil do
                    if os.clock() - startAt > duration + 0.6 then
                        doneState = Enum.PlaybackState.Completed
                        break
                    end
                    RunService.Heartbeat:Wait()
                end
                if myVersion ~= announcementVersion and tween then
                    pcall(function()
                        tween:Cancel()
                    end)
                end
                if myVersion == announcementVersion then
                    task.wait(0.2)
                end
            end
        end
    end)
end

local foldButton = Instance.new("TextButton")
foldButton.Name = "FoldButton"
foldButton.Size = UDim2.new(0, 28, 0, 28)
foldButton.Position = UDim2.new(1, -70, 0, 8)
foldButton.BackgroundColor3 = softPurpleColor
foldButton.BackgroundTransparency = 0.35
foldButton.BorderSizePixel = 0
foldButton.Font = Enum.Font.GothamBold
foldButton.Text = "—"
foldButton.TextColor3 = textColor
foldButton.TextSize = 14
foldButton.AutoButtonColor = false
foldButton.ZIndex = 12
foldButton.Parent = headerBar

addUICorner(foldButton, UDim.new(0, 6))
addUIGradient(foldButton, softPurpleGradient, 68)
addButtonStroke(foldButton, 180, 0.45)

foldButton.MouseEnter:Connect(function()
    tweenProperty(foldButton, {BackgroundTransparency = 0.15}, 0.15)
end)
foldButton.MouseLeave:Connect(function()
    tweenProperty(foldButton, {BackgroundTransparency = 0.35}, 0.15)
end)

local leaveButton = Instance.new("TextButton")
leaveButton.Name = "LeaveButton"
leaveButton.Size = UDim2.new(0, 28, 0, 28)
leaveButton.Position = UDim2.new(1, -38, 0, 8)
leaveButton.BackgroundColor3 = errorColor
leaveButton.BackgroundTransparency = 0.35
leaveButton.BorderSizePixel = 0
leaveButton.Font = Enum.Font.GothamBold
leaveButton.Text = "X"
leaveButton.TextColor3 = textColor
leaveButton.TextSize = 14
leaveButton.AutoButtonColor = false
leaveButton.ZIndex = 12
leaveButton.Parent = headerBar

addUICorner(leaveButton, UDim.new(0, 6))
addUIGradient(leaveButton, ColorSequence.new(Color3.fromRGB(255, 120, 120), errorColor), 68)
addButtonStroke(leaveButton, 180, 0.45)

leaveButton.MouseEnter:Connect(function()
    tweenProperty(leaveButton, {BackgroundTransparency = 0.15}, 0.15)
end)
leaveButton.MouseLeave:Connect(function()
    tweenProperty(leaveButton, {BackgroundTransparency = 0.35}, 0.15)
end)

local messageArea = Instance.new("ScrollingFrame")
messageArea.Name = "MessageArea"
messageArea.Size = UDim2.new(1, -16, 1, -102)
messageArea.Position = UDim2.new(0, 8, 0, 48)
messageArea.BackgroundColor3 = backgroundColor
messageArea.BackgroundTransparency = 1
messageArea.BorderSizePixel = 0
messageArea.ScrollBarThickness = 4
messageArea.ScrollBarImageColor3 = accentColor
messageArea.ScrollBarImageTransparency = 0.4
messageArea.CanvasSize = UDim2.new(0, 0, 0, 0)
messageArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
messageArea.ScrollingDirection = Enum.ScrollingDirection.Y
messageArea.ElasticBehavior = Enum.ElasticBehavior.Always
messageArea.ZIndex = 11
messageArea.Parent = chatContent

addUICorner(messageArea, UDim.new(0, 12))
addUIPadding(messageArea, 6)
local messageStroke = addUIStroke(messageArea, Color3.fromRGB(255, 255, 255), 1.2, 0.5)
addStrokeGradient(messageStroke, strokeGradient, -44)
animateStrokeGradient(messageStroke, 18)
addUIGradient(messageArea, backgroundGradient, 68)

local messageLayout = Instance.new("UIListLayout")
messageLayout.SortOrder = Enum.SortOrder.LayoutOrder
messageLayout.Padding = UDim.new(0, 6)
messageLayout.Parent = messageArea

local messageCount = 0

local loadMessages
local atAllButton

local inputArea = Instance.new("Frame")
inputArea.Name = "InputArea"
inputArea.Size = UDim2.new(1, -16, 0, 40)
inputArea.Position = UDim2.new(0, 8, 1, -48)
inputArea.BackgroundTransparency = 1
inputArea.ZIndex = 11
inputArea.Parent = chatContent

local bottomTipLabel = Instance.new("TextLabel")
bottomTipLabel.Name = "BottomTip"
bottomTipLabel.Size = UDim2.new(1, -16, 0, 14)
bottomTipLabel.Position = UDim2.new(0, 8, 1, -70)
bottomTipLabel.BackgroundTransparency = 1
bottomTipLabel.Font = Enum.Font.Gotham
bottomTipLabel.Text = ""
bottomTipLabel.TextColor3 = textMuted
bottomTipLabel.TextSize = 11
bottomTipLabel.TextXAlignment = Enum.TextXAlignment.Left
bottomTipLabel.ZIndex = 12
bottomTipLabel.Visible = false
bottomTipLabel.Parent = chatContent

local bottomTipToken = 0
local function showBottomTip(text)
    bottomTipToken = bottomTipToken + 1
    local myToken = bottomTipToken
    bottomTipLabel.Text = tostring(text or "")
    bottomTipLabel.TextTransparency = 0
    bottomTipLabel.Visible = true
    task.spawn(function()
        task.wait(2)
        if myToken ~= bottomTipToken then
            return
        end
        tweenProperty(bottomTipLabel, {TextTransparency = 1}, 0.2)
        task.wait(0.22)
        if myToken ~= bottomTipToken then
            return
        end
        bottomTipLabel.Visible = false
    end)
end

local scrollToBottomButton = Instance.new("TextButton")
scrollToBottomButton.Name = "ScrollToBottom"
scrollToBottomButton.Size = UDim2.new(0, 34, 0, 28)
scrollToBottomButton.AnchorPoint = Vector2.new(0.5, 1)
scrollToBottomButton.Position = UDim2.new(0.5, 0, 1, -58)
scrollToBottomButton.BackgroundColor3 = softPurpleColor
scrollToBottomButton.BackgroundTransparency = 0.35
scrollToBottomButton.BorderSizePixel = 0
scrollToBottomButton.Font = Enum.Font.GothamBold
scrollToBottomButton.Text = "↓"
scrollToBottomButton.TextColor3 = textColor
scrollToBottomButton.TextSize = 18
scrollToBottomButton.AutoButtonColor = false
scrollToBottomButton.ZIndex = 25
scrollToBottomButton.Visible = false
scrollToBottomButton.Parent = chatContent
addUICorner(scrollToBottomButton, UDim.new(0, 12))
addUIGradient(scrollToBottomButton, softPurpleGradient, 68)
addButtonStroke(scrollToBottomButton, 180, 0.35)

local scrollToBottomScale = Instance.new("UIScale")
scrollToBottomScale.Scale = 1
scrollToBottomScale.Parent = scrollToBottomButton

local function getMaxMessageScrollY()
    local canvasY = 0
    pcall(function()
        canvasY = messageArea.AbsoluteCanvasSize.Y
    end)
    local windowY = 0
    pcall(function()
        windowY = messageArea.AbsoluteWindowSize.Y
    end)
    return math.max(0, (tonumber(canvasY) or 0) - (tonumber(windowY) or 0))
end

local function updateScrollToBottomButton()
    if not scrollToBottomButton or not messageArea then
        return
    end
    local maxY = getMaxMessageScrollY()
    local currentY = 0
    pcall(function()
        currentY = messageArea.CanvasPosition.Y
    end)
    scrollToBottomButton.Visible = maxY > 0 and (maxY - (tonumber(currentY) or 0)) > 24
end

scrollToBottomButton.MouseButton1Click:Connect(function()
    tweenProperty(scrollToBottomScale, {Scale = 0.9}, 0.05)
    task.delay(0.07, function()
        tweenProperty(scrollToBottomScale, {Scale = 1}, 0.12, Enum.EasingStyle.Back)
    end)
    if not messageArea then
        return
    end
    local maxY = getMaxMessageScrollY()
    local target = Vector2.new(0, maxY)
    local okTween = pcall(function()
        tweenProperty(messageArea, {CanvasPosition = target}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end)
    if not okTween then
        pcall(function()
            messageArea.CanvasPosition = target
        end)
    end
    task.delay(0.2, updateScrollToBottomButton)
end)

messageArea:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollToBottomButton)
messageArea:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateScrollToBottomButton)
messageArea:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollToBottomButton)
task.defer(updateScrollToBottomButton)

local emojiToggle = Instance.new("TextButton")
emojiToggle.Name = "EmojiToggle"
emojiToggle.Size = UDim2.new(0, 32, 0, 32)
emojiToggle.Position = UDim2.new(0, 0, 0.5, 0)
emojiToggle.AnchorPoint = Vector2.new(0, 0.5)
emojiToggle.BackgroundColor3 = Color3.fromRGB(90, 100, 180)
emojiToggle.BorderSizePixel = 0
emojiToggle.Font = Enum.Font.SourceSans
emojiToggle.Text = "😎"
emojiToggle.TextSize = 18
emojiToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
emojiToggle.AutoButtonColor = false
emojiToggle.ZIndex = 12
emojiToggle.Parent = inputArea

addUICorner(emojiToggle, UDim.new(0, 10))
addUIGradient(emojiToggle, backgroundGradient, 68)
addButtonStroke(emojiToggle, 180, 0.25)

local emojiScale = Instance.new("UIScale")
emojiScale.Scale = 1
emojiScale.Parent = emojiToggle

local colorPickerContainer = Instance.new("Frame")
colorPickerContainer.Name = "ColorPickerContainer"
colorPickerContainer.Size = UDim2.new(0, 32, 0, 32)
colorPickerContainer.Position = UDim2.new(0, 38, 0.5, 0)
colorPickerContainer.AnchorPoint = Vector2.new(0, 0.5)
colorPickerContainer.BackgroundTransparency = 1
colorPickerContainer.ZIndex = 12
colorPickerContainer.Parent = inputArea

local colorToggle = Instance.new("TextButton")
colorToggle.Name = "ColorToggle"
colorToggle.Size = UDim2.new(1, 0, 1, 0)
colorToggle.Position = UDim2.new(0, 0, 0, 0)
applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
colorToggle.BorderSizePixel = 0
colorToggle.Text = ""
colorToggle.AutoButtonColor = false
colorToggle.ZIndex = 13
colorToggle.Parent = colorPickerContainer

addUICorner(colorToggle, UDim.new(0, 10))
addButtonStroke(colorToggle, 180, 0.25)
applyBubbleBorderToFrame(colorToggle, isAdminName(userName) and selfBubbleBorderId or 0)

local colorScale = Instance.new("UIScale")
colorScale.Scale = 1
colorScale.Parent = colorToggle

local messageInputContainer = Instance.new("Frame")
messageInputContainer.Name = "MessageInputContainer"
if isAdminName(userName) then
    messageInputContainer.Size = UDim2.new(1, -160, 0, 32)
    messageInputContainer.Position = UDim2.new(0, 120, 0.5, 0)
else
    messageInputContainer.Size = UDim2.new(1, -126, 0, 32)
    messageInputContainer.Position = UDim2.new(0, 86, 0.5, 0)
end
messageInputContainer.AnchorPoint = Vector2.new(0, 0.5)
messageInputContainer.BackgroundColor3 = softInputColor
messageInputContainer.BackgroundTransparency = 0.35
messageInputContainer.BorderSizePixel = 0
messageInputContainer.ZIndex = 12
messageInputContainer.Parent = inputArea

addUICorner(messageInputContainer, UDim.new(0, 12))
local inputStroke = addUIStroke(messageInputContainer, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
addStrokeGradient(inputStroke, strokeGradient, 180)
animateStrokeGradient(inputStroke, 18)
addUIGradient(messageInputContainer, softInputGradient, 68)

messageInput = Instance.new("TextBox")
messageInput.Name = "MessageInput"
messageInput.Size = UDim2.new(1, -16, 1, 0)
messageInput.Position = UDim2.new(0, 8, 0, 0)
messageInput.BackgroundTransparency = 1
messageInput.Font = Enum.Font.Gotham
messageInput.PlaceholderText = "输入消息..."
messageInput.PlaceholderColor3 = softInputPlaceholderColor
messageInput.Text = ""
messageInput.TextColor3 = selfFontColor
messageInput.TextSize = 12
messageInput.TextXAlignment = Enum.TextXAlignment.Left
messageInput.ClearTextOnFocus = false
messageInput.ZIndex = 13
messageInput.Parent = messageInputContainer

messageInput.Focused:Connect(function()
    tweenProperty(messageInputContainer:FindFirstChildOfClass("UIStroke"), {Color = accentColor, Transparency = 0.3}, 0.15)
end)
messageInput.FocusLost:Connect(function()
    tweenProperty(messageInputContainer:FindFirstChildOfClass("UIStroke"), {Color = Color3.fromRGB(70, 70, 70), Transparency = 0.5}, 0.15)
end)

local sendButton = Instance.new("TextButton")
sendButton.Name = "SendButton"
sendButton.Size = UDim2.new(0, 42, 0, 32)
sendButton.Position = UDim2.new(1, -36, 0.5, 0)
sendButton.AnchorPoint = Vector2.new(0, 0.5)
sendButton.BackgroundColor3 = softOrangeColor
sendButton.BackgroundTransparency = 0.35
sendButton.BorderSizePixel = 0
sendButton.Font = Enum.Font.GothamBold
sendButton.Text = "↑"
sendButton.TextColor3 = textColor
sendButton.TextSize = 18
sendButton.AutoButtonColor = false
sendButton.ZIndex = 12
sendButton.Parent = inputArea

addUICorner(sendButton, UDim.new(0, 12))
addUIGradient(sendButton, softOrangeGradient, 68)
addButtonStroke(sendButton, 180, 0.35)

do
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = sendButton
    local bouncing = false
    local function bounceOnce()
        if bouncing then
            return
        end
        bouncing = true
        tweenProperty(scale, {Scale = 0.92}, 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.delay(0.06, function()
            tweenProperty(scale, {Scale = 1.06}, 0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.delay(0.14, function()
                tweenProperty(scale, {Scale = 1}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.12, function()
                    bouncing = false
                end)
            end)
        end)
    end
    sendButton.MouseButton1Click:Connect(bounceOnce)
end

updateAdminUI = function()
    local isAdmin = isAdminName(userName)
    if adminRoomsButton then
        adminRoomsButton.Visible = isAdmin
    end
    if not isAdmin then
        if atAllButton then
            atAllButton:Destroy()
            atAllButton = nil
        end
        return
    end
    if atAllButton or not inputArea or not messageInput then
        return
    end
    atAllButton = Instance.new("TextButton")
    atAllButton.Name = "AtAllButton"
    atAllButton.Size = UDim2.new(0, 40, 0, 26)
    atAllButton.Position = UDim2.new(0, 38 + 32 + 6, 0.5, 0)
    atAllButton.AnchorPoint = Vector2.new(0, 0.5)
    atAllButton.BackgroundColor3 = softPurpleColor
    atAllButton.BorderSizePixel = 0
    atAllButton.Font = Enum.Font.GothamBold
    atAllButton.Text = "@全体"
    atAllButton.TextColor3 = textColor
    atAllButton.TextSize = 12
    atAllButton.AutoButtonColor = false
    atAllButton.ZIndex = 12
    atAllButton.Parent = inputArea

    addUICorner(atAllButton, UDim.new(0, 12))
    addUIGradient(atAllButton, softPurpleGradient, 68)
    addButtonStroke(atAllButton, 180, 0.35)

    atAllButton.MouseEnter:Connect(function()
        tweenProperty(atAllButton, {BackgroundTransparency = 0.35}, 0.15)
    end)
    atAllButton.MouseLeave:Connect(function()
        tweenProperty(atAllButton, {BackgroundTransparency = 0}, 0.15)
    end)
    atAllButton.MouseButton1Click:Connect(function()
        if not messageInput then
            return
        end
        local text = messageInput.Text or ""
        if text == "" then
            messageInput.Text = "@全体 "
        elseif not string.find(text, "@全体", 1, true) then
            messageInput.Text = "@全体 " .. text
        end
        messageInput:CaptureFocus()
        messageInput.CursorPosition = #messageInput.Text + 1
    end)
end

updateAdminUI()

sendButton.MouseEnter:Connect(function()
    tweenProperty(sendButton, {BackgroundTransparency = 0.15}, 0.15)
end)
sendButton.MouseLeave:Connect(function()
    tweenProperty(sendButton, {BackgroundTransparency = 0.35}, 0.15)
end)

function createRemoteEmojiUI(chatContent, headerBar, messageInput, hideConflicts)
    local remoteEmoji = {
        loadedByMode = { image = false, background = false },
        loading = false,
        mode = "image",
        folder = "ThirdGenEmojiCache",
        bgFolder = BACKGROUND_CACHE_FOLDER,
    }

    local function attachClickBounce(button)
        local scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = button
        button.MouseButton1Click:Connect(function()
            tweenProperty(scale, {Scale = 0.9}, 0.05)
            task.delay(0.07, function()
                tweenProperty(scale, {Scale = 1}, 0.12, Enum.EasingStyle.Back)
            end)
        end)
    end

    remoteEmoji.panel = Instance.new("Frame")
    remoteEmoji.panel.Name = "RemoteEmojiPanel"
    remoteEmoji.panel.Size = UDim2.new(0, 360, 0, 260)
    remoteEmoji.panel.AnchorPoint = Vector2.new(0.5, 0.5)
    remoteEmoji.panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    remoteEmoji.panel.BackgroundColor3 = backgroundTertiary
    remoteEmoji.panel.BorderSizePixel = 0
    remoteEmoji.panel.Visible = false
    remoteEmoji.panel.ZIndex = 30
    remoteEmoji.panel.Parent = chatContent

    addUICorner(remoteEmoji.panel, UDim.new(0, 12))
    local remoteEmojiStroke = addUIStroke(remoteEmoji.panel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(remoteEmojiStroke, strokeGradient, 180)
    addUIGradient(remoteEmoji.panel, backgroundGradient, 68)

    local remoteHeader = Instance.new("Frame")
    remoteHeader.Name = "Header"
    remoteHeader.Size = UDim2.new(1, -12, 0, 28)
    remoteHeader.Position = UDim2.new(0, 6, 0, 6)
    remoteHeader.BackgroundTransparency = 1
    remoteHeader.ZIndex = 31
    remoteHeader.Parent = remoteEmoji.panel

    local remoteTitle = Instance.new("TextLabel")
    remoteTitle.Name = "Title"
    remoteTitle.Size = UDim2.new(1, -156, 1, 0)
    remoteTitle.Position = UDim2.new(0, 10, 0, 0)
    remoteTitle.BackgroundTransparency = 1
    remoteTitle.Font = Enum.Font.GothamBold
    remoteTitle.Text = "表情包图"
    remoteTitle.TextColor3 = textColor
    remoteTitle.TextSize = 14
    remoteTitle.TextXAlignment = Enum.TextXAlignment.Left
    remoteTitle.ZIndex = 32
    remoteTitle.Parent = remoteHeader

    remoteEmoji.closeButton = Instance.new("TextButton")
    remoteEmoji.closeButton.Name = "Close"
    remoteEmoji.closeButton.Size = UDim2.new(0, 28, 0, 28)
    remoteEmoji.closeButton.AnchorPoint = Vector2.new(1, 0)
    remoteEmoji.closeButton.Position = UDim2.new(1, -6, 0, 0)
    remoteEmoji.closeButton.BackgroundColor3 = errorColor
    remoteEmoji.closeButton.BorderSizePixel = 0
    remoteEmoji.closeButton.Font = Enum.Font.GothamBold
    remoteEmoji.closeButton.Text = "X"
    remoteEmoji.closeButton.TextColor3 = textColor
    remoteEmoji.closeButton.TextSize = 13
    remoteEmoji.closeButton.AutoButtonColor = false
    remoteEmoji.closeButton.ZIndex = 32
    remoteEmoji.closeButton.Parent = remoteHeader
    addUICorner(remoteEmoji.closeButton, UDim.new(0, 8))
    addButtonStroke(remoteEmoji.closeButton, 180, 0.35)
    attachClickBounce(remoteEmoji.closeButton)

    remoteEmoji.refreshButton = Instance.new("TextButton")
    remoteEmoji.refreshButton.Name = "Refresh"
    remoteEmoji.refreshButton.Size = UDim2.new(0, 28, 0, 28)
    remoteEmoji.refreshButton.AnchorPoint = Vector2.new(1, 0)
    remoteEmoji.refreshButton.Position = UDim2.new(1, -38, 0, 0)
    remoteEmoji.refreshButton.BackgroundColor3 = backgroundSecondary
    remoteEmoji.refreshButton.BorderSizePixel = 0
    remoteEmoji.refreshButton.Font = Enum.Font.GothamBold
    remoteEmoji.refreshButton.Text = "♻️"
    remoteEmoji.refreshButton.TextColor3 = textColor
    remoteEmoji.refreshButton.TextSize = 14
    remoteEmoji.refreshButton.AutoButtonColor = false
    remoteEmoji.refreshButton.ZIndex = 32
    remoteEmoji.refreshButton.Parent = remoteHeader
    addUICorner(remoteEmoji.refreshButton, UDim.new(0, 8))
    addButtonStroke(remoteEmoji.refreshButton, 180, 0.35)
    attachClickBounce(remoteEmoji.refreshButton)

    remoteEmoji.autoPopupToggle = Instance.new("TextButton")
    remoteEmoji.autoPopupToggle.Name = "AutoPopupToggle"
    remoteEmoji.autoPopupToggle.Size = UDim2.new(0, 28, 0, 28)
    remoteEmoji.autoPopupToggle.AnchorPoint = Vector2.new(1, 0)
    remoteEmoji.autoPopupToggle.Position = UDim2.new(1, -70, 0, 0)
    remoteEmoji.autoPopupToggle.BackgroundColor3 = backgroundSecondary
    remoteEmoji.autoPopupToggle.BorderSizePixel = 0
    remoteEmoji.autoPopupToggle.Font = Enum.Font.GothamBold
    remoteEmoji.autoPopupToggle.TextColor3 = textColor
    remoteEmoji.autoPopupToggle.TextSize = 12
    remoteEmoji.autoPopupToggle.AutoButtonColor = false
    remoteEmoji.autoPopupToggle.ZIndex = 32
    remoteEmoji.autoPopupToggle.Parent = remoteHeader
    addUICorner(remoteEmoji.autoPopupToggle, UDim.new(0, 8))
    addButtonStroke(remoteEmoji.autoPopupToggle, 180, 0.35)
    attachClickBounce(remoteEmoji.autoPopupToggle)

    remoteEmoji.backgroundButton = Instance.new("TextButton")
    remoteEmoji.backgroundButton.Name = "Background"
    remoteEmoji.backgroundButton.Size = UDim2.new(0, 28, 0, 28)
    remoteEmoji.backgroundButton.AnchorPoint = Vector2.new(1, 0)
    remoteEmoji.backgroundButton.Position = UDim2.new(1, -70 - 32, 0, 0)
    remoteEmoji.backgroundButton.BackgroundColor3 = backgroundSecondary
    remoteEmoji.backgroundButton.BorderSizePixel = 0
    remoteEmoji.backgroundButton.Font = Enum.Font.GothamBold
    remoteEmoji.backgroundButton.Text = "背景"
    remoteEmoji.backgroundButton.TextColor3 = textColor
    remoteEmoji.backgroundButton.TextSize = 12
    remoteEmoji.backgroundButton.AutoButtonColor = false
    remoteEmoji.backgroundButton.ZIndex = 32
    remoteEmoji.backgroundButton.Parent = remoteHeader
    addUICorner(remoteEmoji.backgroundButton, UDim.new(0, 8))
    addButtonStroke(remoteEmoji.backgroundButton, 180, 0.35)
    attachClickBounce(remoteEmoji.backgroundButton)

    remoteEmoji.restoreBgButton = Instance.new("TextButton")
    remoteEmoji.restoreBgButton.Name = "RestoreBackground"
    remoteEmoji.restoreBgButton.Size = UDim2.new(0, 28, 0, 28)
    remoteEmoji.restoreBgButton.AnchorPoint = Vector2.new(1, 0)
    remoteEmoji.restoreBgButton.Position = UDim2.new(1, -70 - 32 - 32, 0, 0)
    remoteEmoji.restoreBgButton.BackgroundColor3 = backgroundSecondary
    remoteEmoji.restoreBgButton.BorderSizePixel = 0
    remoteEmoji.restoreBgButton.Font = Enum.Font.GothamBold
    remoteEmoji.restoreBgButton.Text = "恢复"
    remoteEmoji.restoreBgButton.TextColor3 = textColor
    remoteEmoji.restoreBgButton.TextSize = 12
    remoteEmoji.restoreBgButton.AutoButtonColor = false
    remoteEmoji.restoreBgButton.ZIndex = 32
    remoteEmoji.restoreBgButton.Parent = remoteHeader
    addUICorner(remoteEmoji.restoreBgButton, UDim.new(0, 8))
    addButtonStroke(remoteEmoji.restoreBgButton, 180, 0.35)
    attachClickBounce(remoteEmoji.restoreBgButton)

    local function updateAutoPopupToggleVisual()
        if not remoteEmoji.autoPopupToggle then
            return
        end
        if autoPopupEnabled then
            remoteEmoji.autoPopupToggle.BackgroundColor3 = successColor
            remoteEmoji.autoPopupToggle.Text = "开"
        else
            remoteEmoji.autoPopupToggle.BackgroundColor3 = backgroundSecondary
            remoteEmoji.autoPopupToggle.Text = "关"
        end
    end

    updateAutoPopupToggleVisual()

    local function setRemoteMode(mode)
        remoteEmoji.mode = mode
        if remoteEmoji.mode == "background" then
            remoteTitle.Text = "背景设置"
            remoteEmoji.backgroundButton.BackgroundColor3 = successColor
        else
            remoteTitle.Text = "表情包图"
            remoteEmoji.backgroundButton.BackgroundColor3 = backgroundSecondary
        end
        if remoteEmoji.loadingLabel then
            remoteEmoji.loadingLabel.Text = "点击刷新加载..."
            remoteEmoji.loadingLabel.Visible = true
        end
    end

    setRemoteMode("image")

    remoteEmoji.autoPopupToggle.MouseButton1Click:Connect(function()
        autoPopupEnabled = not autoPopupEnabled
        startMinimizedOnLoad = autoPopupEnabled
        saveChatSettings()
        updateAutoPopupToggleVisual()
        if autoPopupEnabled then
            createNotification(gui, "已保存，下次加载UI不弹出", false)
        else
            createNotification(gui, "已保存，下次加载聊天UI弹出", false)
        end
    end)

    remoteEmoji.restoreBgButton.MouseButton1Click:Connect(function()
        ThirdGenChat_ClearBackground()
        createNotification(gui, "已恢复默认背景", false)
    end)

    remoteEmoji.scroll = Instance.new("ScrollingFrame")
    remoteEmoji.scroll.Name = "RemoteEmojiScroll"
    remoteEmoji.scroll.Size = UDim2.new(1, -20, 1, -52)
    remoteEmoji.scroll.Position = UDim2.new(0, 10, 0, 42)
    remoteEmoji.scroll.BackgroundTransparency = 1
    remoteEmoji.scroll.ScrollBarThickness = 4
    remoteEmoji.scroll.ScrollBarImageColor3 = accentColor
    remoteEmoji.scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    remoteEmoji.scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    remoteEmoji.scroll.ZIndex = 31
    remoteEmoji.scroll.Parent = remoteEmoji.panel

    local remoteEmojiGrid = Instance.new("UIGridLayout")
    remoteEmojiGrid.CellSize = UDim2.new(0, 60, 0, 60)
    remoteEmojiGrid.CellPadding = UDim2.new(0, 4, 0, 4)
    remoteEmojiGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
    remoteEmojiGrid.VerticalAlignment = Enum.VerticalAlignment.Top
    remoteEmojiGrid.Parent = remoteEmoji.scroll

    remoteEmoji.loadingLabel = Instance.new("TextLabel")
    remoteEmoji.loadingLabel.Name = "Loading"
    remoteEmoji.loadingLabel.Size = UDim2.new(1, -12, 0, 24)
    remoteEmoji.loadingLabel.Position = UDim2.new(0, 6, 0, 40)
    remoteEmoji.loadingLabel.BackgroundTransparency = 1
    remoteEmoji.loadingLabel.Font = Enum.Font.Gotham
    remoteEmoji.loadingLabel.Text = "点击刷新加载..."
    remoteEmoji.loadingLabel.TextColor3 = textMuted
    remoteEmoji.loadingLabel.TextSize = 12
    remoteEmoji.loadingLabel.ZIndex = 32
    remoteEmoji.loadingLabel.Parent = remoteEmoji.panel

    remoteEmoji.resolveImage = function(fileUrl, fileName, folderOverride)
        local getAsset = nil
        if typeof(getcustomasset) == "function" then
            getAsset = getcustomasset
        elseif typeof(getsynasset) == "function" then
            getAsset = getsynasset
        end
        if not getAsset then
            return fileUrl
        end

        local targetFolder = folderOverride or remoteEmoji.folder

        if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
            if not isfolder(targetFolder) then
                pcall(function()
                    makefolder(targetFolder)
                end)
            end
        end

        if typeof(writefile) ~= "function" or typeof(isfile) ~= "function" then
            return fileUrl
        end

        local safeName = tostring(fileName or "emoji.png"):gsub("[^%w%._%-]", "_")
        local path = targetFolder .. "/" .. safeName
        if not isfile(path) then
            local ok, res = pcall(function()
                return request({ Url = fileUrl, Method = "GET" })
            end)
            if ok and res and res.Success and type(res.Body) == "string" and #res.Body > 0 then
                pcall(function()
                    writefile(path, res.Body)
                end)
            end
        end

        local okAsset, assetId = pcall(function()
            return getAsset(path)
        end)
        if okAsset and type(assetId) == "string" and assetId ~= "" then
            return assetId
        end
        return fileUrl
    end

    remoteEmoji.clearCells = function()
        for _, child in ipairs(remoteEmoji.scroll:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
    end

    remoteEmoji.load = function(force)
        if remoteEmoji.loading then
            return
        end
        local key = remoteEmoji.mode == "background" and "background" or "image"
        if remoteEmoji.loadedByMode[key] and not force then
            return
        end
        remoteEmoji.loading = true
        remoteEmoji.loadingLabel.Text = "正在加载..."
        remoteEmoji.loadingLabel.Visible = true
        remoteEmoji.clearCells()

        task.spawn(function()
            local isBackground = remoteEmoji.mode == "background"
            local actionName = isBackground and BACKGROUND_REMOTE_LIST_ACTION or "get_emojis"
            local url = string.format("%s?action=%s&apikey=%s&t=%d", BASE_URL, HttpService:UrlEncode(actionName), HttpService:UrlEncode(API_KEY or ""), os.time())
            local ok, response = pcall(function()
                return request({ Url = url, Method = "GET" })
            end)
            local localFiles = {}
            if isBackground then
                localFiles = ThirdGenChat_ListLocalImages(remoteEmoji.bgFolder)
            end
            local list = {}
            local remoteListOk = false
            if ok and response and response.Success then
                local okJson, data = pcall(function()
                    return HttpService:JSONDecode(response.Body)
                end)
                if okJson and type(data) == "table" and data[1] == "success" and type(data[2]) == "table" then
                    list = data[2]
                    remoteListOk = true
                end
            end

            if not remoteListOk and (not isBackground or #localFiles == 0) then
                remoteEmoji.loadingLabel.Text = isBackground and "背景远程加载失败" or "加载失败"
                remoteEmoji.loadedByMode[key] = false
                remoteEmoji.loading = false
                return
            end

            if #list == 0 and (not isBackground or #localFiles == 0) then
                remoteEmoji.loadingLabel.Text = "没有图片"
                remoteEmoji.loadedByMode[key] = true
                remoteEmoji.loading = false
                return
            end

            local remoteBgNameSet = {}
            if isBackground then
                for _, fileName in ipairs(list) do
                    if type(fileName) == "string" and fileName ~= "" then
                        remoteBgNameSet[string.lower(ThirdGenChat_SafeFileName(fileName))] = true
                    end
                end
            end

            for _, fileName in ipairs(list) do
                if type(fileName) == "string" and fileName ~= "" then
                    local fileUrl
                    if isBackground then
                        fileUrl = BACKGROUND_REMOTE_BASE_URL .. fileName
                    else
                        fileUrl = "http://kpl.wyp8.top/cs/emoji/" .. fileName
                    end
                    local cell = Instance.new("Frame")
                    cell.Name = "EmojiCell"
                    cell.Size = UDim2.new(0, 60, 0, 60)
                    cell.BackgroundColor3 = backgroundColor
                    cell.BorderSizePixel = 0
                    cell.ZIndex = 32
                    cell.Parent = remoteEmoji.scroll
                    addUICorner(cell, UDim.new(0, 10))
                    addButtonStroke(cell, 180, 0.25)

                    local img = Instance.new("ImageButton")
                    img.Name = "Image"
                    img.Size = UDim2.new(1, -8, 1, -8)
                    img.Position = UDim2.new(0, 4, 0, 4)
                    img.BackgroundTransparency = 1
                    if isBackground then
                        img.Image = remoteEmoji.resolveImage(fileUrl, fileName, remoteEmoji.bgFolder)
                    else
                        img.Image = remoteEmoji.resolveImage(fileUrl, fileName)
                    end
                    img.ScaleType = Enum.ScaleType.Fit
                    img.AutoButtonColor = false
                    img.ZIndex = 33
                    img.Parent = cell

                    img.MouseEnter:Connect(function()
                        tweenProperty(cell, {BackgroundColor3 = backgroundSecondary}, 0.1)
                    end)
                    img.MouseLeave:Connect(function()
                        tweenProperty(cell, {BackgroundColor3 = backgroundColor}, 0.1)
                    end)
                    img.MouseButton1Click:Connect(function()
                        remoteEmoji.panel.Visible = false
                        if isBackground then
                            ThirdGenChat_SetBackgroundRemote(fileUrl, fileName)
                            createNotification(gui, "已设置聊天背景", false)
                        else
                            if not messageInput then
                                return
                            end
                            messageInput.Text = "##IMG##|" .. fileUrl
                            if type(sendMessageAction) == "function" then
                                sendMessageAction()
                            else
                                messageInput:CaptureFocus()
                            end
                        end
                    end)
                end
            end

            if isBackground and #localFiles > 0 then
                for _, p in ipairs(localFiles) do
                    if type(p) == "string" and p ~= "" then
                        local baseName = p:gsub("\\", "/"):match("([^/]+)$") or p
                        local safeBase = string.lower(ThirdGenChat_SafeFileName(baseName))
                        local asset = nil
                        if not remoteBgNameSet[safeBase] then
                            asset = ThirdGenChat_ResolveLocalAsset(p)
                        end
                        if asset then
                            local cell = Instance.new("Frame")
                            cell.Name = "EmojiCell"
                            cell.Size = UDim2.new(0, 60, 0, 60)
                            cell.BackgroundColor3 = backgroundColor
                            cell.BorderSizePixel = 0
                            cell.ZIndex = 32
                            cell.Parent = remoteEmoji.scroll
                            addUICorner(cell, UDim.new(0, 10))
                            addButtonStroke(cell, 180, 0.25)

                            local img = Instance.new("ImageButton")
                            img.Name = "Image"
                            img.Size = UDim2.new(1, -8, 1, -8)
                            img.Position = UDim2.new(0, 4, 0, 4)
                            img.BackgroundTransparency = 1
                            img.Image = asset
                            img.ScaleType = Enum.ScaleType.Fit
                            img.AutoButtonColor = false
                            img.ZIndex = 33
                            img.Parent = cell

                            img.MouseEnter:Connect(function()
                                tweenProperty(cell, {BackgroundColor3 = backgroundSecondary}, 0.1)
                            end)
                            img.MouseLeave:Connect(function()
                                tweenProperty(cell, {BackgroundColor3 = backgroundColor}, 0.1)
                            end)
                            img.MouseButton1Click:Connect(function()
                                remoteEmoji.panel.Visible = false
                                ThirdGenChat_SetBackgroundLocal(p)
                                    createNotification(gui, "已设置聊天背景", false)
                                end)
                        end
                    end
                end
            end

            if isBackground and not remoteListOk and #localFiles > 0 then
                remoteEmoji.loadingLabel.Text = "远程失败，仅显示本地"
                remoteEmoji.loadingLabel.Visible = true
            else
                remoteEmoji.loadingLabel.Visible = false
            end
            remoteEmoji.loadedByMode[key] = true
            remoteEmoji.loading = false
        end)
    end

    remoteEmoji.button = Instance.new("TextButton")
    remoteEmoji.button.Name = "RemoteEmojiButton"
    remoteEmoji.button.Size = UDim2.new(0, 28, 0, 28)
    remoteEmoji.button.Position = UDim2.new(1, -70 - 28 - 4, 0, 8)
    remoteEmoji.button.BackgroundColor3 = softPurpleColor
    remoteEmoji.button.BackgroundTransparency = 0.35
    remoteEmoji.button.BorderSizePixel = 0
    remoteEmoji.button.Font = Enum.Font.GothamBold
    remoteEmoji.button.Text = "图"
    remoteEmoji.button.TextColor3 = textColor
    remoteEmoji.button.TextSize = 14
    remoteEmoji.button.AutoButtonColor = false
    remoteEmoji.button.ZIndex = 12
    remoteEmoji.button.Parent = headerBar

    addUICorner(remoteEmoji.button, UDim.new(0, 6))
    addUIGradient(remoteEmoji.button, softPurpleGradient, 68)
    addButtonStroke(remoteEmoji.button, 180, 0.45)
    attachClickBounce(remoteEmoji.button)

    remoteEmoji.button.MouseEnter:Connect(function()
        tweenProperty(remoteEmoji.button, {BackgroundTransparency = 0.15}, 0.15)
    end)
    remoteEmoji.button.MouseLeave:Connect(function()
        tweenProperty(remoteEmoji.button, {BackgroundTransparency = 0.35}, 0.15)
    end)
    remoteEmoji.button.MouseButton1Click:Connect(function()
        if typeof(hideConflicts) == "function" then
            hideConflicts()
        end
        setRemoteMode("image")
        remoteEmoji.panel.Visible = not remoteEmoji.panel.Visible
        if remoteEmoji.panel.Visible then
            remoteEmoji.load(true)
        end
    end)

    remoteEmoji.closeButton.MouseButton1Click:Connect(function()
        remoteEmoji.panel.Visible = false
    end)

    remoteEmoji.refreshButton.MouseButton1Click:Connect(function()
        local key = remoteEmoji.mode == "background" and "background" or "image"
        remoteEmoji.loadedByMode[key] = false
        remoteEmoji.load(true)
    end)

    remoteEmoji.backgroundButton.MouseButton1Click:Connect(function()
        if remoteEmoji.mode == "background" then
            setRemoteMode("image")
        else
            setRemoteMode("background")
        end
        remoteEmoji.panel.Visible = true
        remoteEmoji.load(true)
    end)

    return remoteEmoji
end

local emojiPanel
do
    emojiPanel = Instance.new("Frame")
    emojiPanel.Name = "EmojiPanel"
    emojiPanel.Size = UDim2.new(0, 200, 0, 140)
    emojiPanel.Position = UDim2.new(0, 0, 1, -190)
    emojiPanel.BackgroundColor3 = backgroundTertiary
    emojiPanel.BorderSizePixel = 0
    emojiPanel.Visible = false
    emojiPanel.ZIndex = 20
    emojiPanel.Parent = chatContent

    addUICorner(emojiPanel, UDim.new(0, 10))
    local emojiStroke = addUIStroke(emojiPanel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(emojiStroke, strokeGradient, 180)
    addUIGradient(emojiPanel, backgroundGradient, 68)
end

local customColorPanel
local customColorArea
local fontColorPanel
local bubblePalettePanel
local bubbleBorderPanel
local avatarBorderPanel
local avatarBorderQuickPanel
local avatarBorderSolidPanel
local dynamicBubblePanel
local isAdminUser = isAdminName(userName)
local regularBubbleRemovedColor = Color3.fromRGB(140, 200, 255)
local regularBubbleCoffeeColor = Color3.fromRGB(160, 120, 80)
local colorPanel
local randomColorPool = {}

remoteEmoji = createRemoteEmojiUI(chatContent, headerBar, messageInput, function()
    emojiPanel.Visible = false
    if colorPanel and colorPanel.Visible then
        colorPanel.Visible = false
    end
    if customColorPanel and customColorPanel.Visible then
        customColorPanel.Visible = false
    end
    if fontColorPanel and fontColorPanel.Visible then
        fontColorPanel.Visible = false
    end
    if avatarBorderQuickPanel and avatarBorderQuickPanel.Visible then
        avatarBorderQuickPanel.Visible = false
    end
    if bubblePalettePanel and bubblePalettePanel.Visible then
        bubblePalettePanel.Visible = false
    end
    if bubbleBorderPanel and bubbleBorderPanel.Visible then
        bubbleBorderPanel.Visible = false
    end
    if avatarBorderPanel and avatarBorderPanel.Visible then
        avatarBorderPanel.Visible = false
    end
    if avatarBorderSolidPanel and avatarBorderSolidPanel.Visible then
        avatarBorderSolidPanel.Visible = false
    end
    if dynamicBubblePanel and dynamicBubblePanel.Visible then
        dynamicBubblePanel.Visible = false
    end
end)

do
    avatarBorderQuickPanel = Instance.new("Frame")
    avatarBorderQuickPanel.Name = "AvatarBorderQuickPanel"
    avatarBorderQuickPanel.Size = UDim2.new(0, 180, 0, 96)
    avatarBorderQuickPanel.AnchorPoint = Vector2.new(0, 1)
    avatarBorderQuickPanel.Position = UDim2.new(0, 8, 1, isAdminUser and -265 or -200)
    avatarBorderQuickPanel.BackgroundColor3 = backgroundTertiary
    avatarBorderQuickPanel.BorderSizePixel = 0
    avatarBorderQuickPanel.Visible = false
    avatarBorderQuickPanel.ZIndex = 21
    avatarBorderQuickPanel.Parent = chatContent
    addUICorner(avatarBorderQuickPanel, UDim.new(0, 10))
    local panelStroke = addUIStroke(avatarBorderQuickPanel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(panelStroke, strokeGradient, 180)
    addUIGradient(avatarBorderQuickPanel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "头像边框"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = avatarBorderQuickPanel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = avatarBorderQuickPanel
    closeBtn.MouseButton1Click:Connect(function()
        avatarBorderQuickPanel.Visible = false
    end)

    local gridHost = Instance.new("Frame")
    gridHost.Name = "GridHost"
    gridHost.Size = UDim2.new(1, -16, 1, -30)
    gridHost.Position = UDim2.new(0, 8, 0, 26)
    gridHost.BackgroundTransparency = 1
    gridHost.BorderSizePixel = 0
    gridHost.ZIndex = 22
    gridHost.Parent = avatarBorderQuickPanel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 78, 0, 22)
    grid.CellPadding = UDim2.new(0, 6, 0, 4)
    grid.FillDirectionMaxCells = 2
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = gridHost

    local function makeBorderPickButton(borderId, labelText)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 78, 0, 22)
        b.BackgroundColor3 = backgroundSecondary
        b.BorderSizePixel = 0
        b.Text = labelText or ""
        b.TextColor3 = textColor
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.AutoButtonColor = false
        b.ZIndex = 23
        b.Parent = gridHost
        addUICorner(b, UDim.new(0, 7))
        addUIStroke(b, Color3.fromRGB(255, 255, 255), 1, 0.35)

        local preview = Instance.new("Frame")
        preview.Name = "Preview"
        preview.Size = UDim2.new(0, 16, 0, 16)
        preview.Position = UDim2.new(0, 6, 0.5, -8)
        preview.BackgroundColor3 = backgroundTertiary
        preview.BorderSizePixel = 0
        preview.ZIndex = 24
        preview.Parent = b
        addUICorner(preview, UDim.new(1, 0))
        applyAvatarBorderToFrame(preview, borderId)

        b.MouseButton1Click:Connect(function()
            selfAvatarBorderId = math.max(0, math.floor(tonumber(borderId) or 0))
            saveChatColorConfig()
            avatarBorderQuickPanel.Visible = false
        end)
    end

    makeBorderPickButton(13, "蓝色")
    makeBorderPickButton(14, "白色")
    makeBorderPickButton(15, "黄色")
end

do
    if not isAdminUser and typeof(selfBubbleColor) == "Color3" and selfBubbleColor == regularBubbleRemovedColor then
        selfBubbleColor = regularBubbleCoffeeColor
        selfBubbleStyle = regularBubbleCoffeeColor
        if colorToggle then
            applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
        end
        saveChatColorConfig()
    end

    colorPanel = Instance.new("Frame")
    colorPanel.Name = "ColorPanel"
    colorPanel.Size = UDim2.new(0, 240, 0, isAdminUser and 86 or 58)
    colorPanel.Position = isAdminUser and UDim2.new(0, 8, 1, -140) or UDim2.new(0, 8, 1, -108)
    colorPanel.BackgroundColor3 = backgroundTertiary
    colorPanel.BorderSizePixel = 0
    colorPanel.Visible = false
    colorPanel.ZIndex = 20
    colorPanel.Parent = chatContent

    addUICorner(colorPanel, UDim.new(0, 10))
    local colorStroke = addUIStroke(colorPanel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(colorStroke, strokeGradient, 180)
    addUIGradient(colorPanel, backgroundGradient, 68)

    local colorGrid = Instance.new("UIGridLayout")
    colorGrid.CellSize = UDim2.new(0, 56, 0, 24)
    colorGrid.CellPadding = UDim2.new(0, 4, 0, 4)
    colorGrid.FillDirection = Enum.FillDirection.Horizontal
    colorGrid.FillDirectionMaxCells = 4
    colorGrid.SortOrder = Enum.SortOrder.LayoutOrder
    colorGrid.Parent = colorPanel

    local allColorOptions = {
        Color3.fromRGB(120, 140, 255),
        Color3.fromRGB(160, 120, 80),
        Color3.fromRGB(255, 170, 80),
        Color3.fromRGB(255, 120, 160),
        Color3.fromRGB(255, 200, 120),
        Color3.fromRGB(140, 200, 255),
        Color3.fromRGB(200, 140, 255),
        Color3.fromRGB(255, 140, 200),
        Color3.fromRGB(180, 180, 180),
    }

    local function addRandomPoolColor(c)
        if not isAdminUser and c == regularBubbleRemovedColor then
            return
        end
        for _, existing in ipairs(randomColorPool) do
            if existing == c then
                return
            end
        end
        table.insert(randomColorPool, c)
    end

    for _, c in ipairs(allColorOptions) do
        addRandomPoolColor(c)
    end

    addRandomPoolColor(Color3.fromRGB(255, 255, 255))
    addRandomPoolColor(Color3.fromRGB(230, 230, 230))
    addRandomPoolColor(Color3.fromRGB(180, 180, 180))
    addRandomPoolColor(Color3.fromRGB(120, 120, 120))
    addRandomPoolColor(Color3.fromRGB(0, 0, 0))
    addRandomPoolColor(Color3.fromRGB(255, 120, 120))
    addRandomPoolColor(Color3.fromRGB(255, 170, 110))
    addRandomPoolColor(Color3.fromRGB(255, 230, 160))
    addRandomPoolColor(Color3.fromRGB(170, 240, 170))
    addRandomPoolColor(Color3.fromRGB(120, 210, 170))
    addRandomPoolColor(Color3.fromRGB(150, 210, 255))
    addRandomPoolColor(Color3.fromRGB(120, 180, 255))
    addRandomPoolColor(Color3.fromRGB(210, 190, 255))
    addRandomPoolColor(Color3.fromRGB(255, 180, 225))
    addRandomPoolColor(Color3.fromRGB(0, 170, 170))
    addRandomPoolColor(Color3.fromRGB(210, 90, 90))

    addRandomPoolColor(Color3.fromRGB(255, 80, 80))
    addRandomPoolColor(Color3.fromRGB(255, 230, 230))
    addRandomPoolColor(Color3.fromRGB(0, 0, 0))
    addRandomPoolColor(Color3.fromRGB(230, 230, 230))
    addRandomPoolColor(Color3.fromRGB(40, 160, 70))
    addRandomPoolColor(Color3.fromRGB(220, 255, 230))
    addRandomPoolColor(Color3.fromRGB(255, 120, 180))
    addRandomPoolColor(Color3.fromRGB(255, 235, 245))
    addRandomPoolColor(Color3.fromRGB(80, 150, 255))
    addRandomPoolColor(Color3.fromRGB(230, 240, 255))
    addRandomPoolColor(Color3.fromRGB(250, 220, 120))
    addRandomPoolColor(Color3.fromRGB(255, 245, 210))
    addRandomPoolColor(Color3.fromRGB(150, 90, 210))
    addRandomPoolColor(Color3.fromRGB(230, 220, 255))
    addRandomPoolColor(Color3.fromRGB(255, 160, 210))
    addRandomPoolColor(Color3.fromRGB(255, 240, 250))

    local function getSelfColorOptions()
        local subset = {}
        local count = isAdminUser and math.min(4, #allColorOptions) or math.min(5, #allColorOptions)
        for i = 1, count do
            table.insert(subset, allColorOptions[i])
        end
        return subset
    end

    for i, c in ipairs(getSelfColorOptions()) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 34, 0, 24)
        btn.BackgroundColor3 = c
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = 100 + i
        btn.ZIndex = 21
        btn.Parent = colorPanel
        addUICorner(btn, UDim.new(0, 6))

        local stroke = addUIStroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.3)

        btn.MouseEnter:Connect(function()
            tweenProperty(stroke, {Transparency = 0}, 0.1)
        end)

        btn.MouseLeave:Connect(function()
            tweenProperty(stroke, {Transparency = 0.6}, 0.1)
        end)

        btn.MouseButton1Click:Connect(function()
            selfBubbleColor = c
            selfBubbleStyle = c
            applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
            colorPanel.Visible = false
            saveChatColorConfig()
        end)
    end

    applyChatFontColorToExistingMessages = function()
        if messageInput and messageInput:IsA("TextBox") then
            messageInput.TextColor3 = selfFontColor
        end
    end

    setChatFontColor = function(newColor)
        if typeof(newColor) ~= "Color3" then
            return
        end
        selfFontColor = newColor
        applyChatFontColorToExistingMessages()
    end

    local fontButton = Instance.new("TextButton")
    fontButton.Name = "FontColorToggle"
    fontButton.Size = UDim2.new(0, 44, 0, 22)
    fontButton.AnchorPoint = Vector2.new(1, 1)
    fontButton.Position = isAdminUser and UDim2.new(1, -8 - 44 - 4, 1, -8) or UDim2.new(1, -8 - 44 - 4 - 44 - 4, 1, -8)
    fontButton.BackgroundColor3 = backgroundSecondary
    fontButton.BorderSizePixel = 0
    fontButton.Font = Enum.Font.GothamBold
    fontButton.Text = "字体颜色"
    fontButton.TextColor3 = textColor
    fontButton.TextSize = 11
    fontButton.AutoButtonColor = false
    fontButton.LayoutOrder = 4
    fontButton.ZIndex = 22
    fontButton.Parent = colorPanel
    addUICorner(fontButton, UDim.new(0, 8))
    addButtonStroke(fontButton, 180, 0.3)

    fontButton.MouseButton1Click:Connect(function()
        emojiPanel.Visible = false
        remoteEmoji.panel.Visible = false
        colorPanel.Visible = false
        if customColorPanel then
            customColorPanel.Visible = false
        end
        if avatarBorderQuickPanel then
            avatarBorderQuickPanel.Visible = false
        end
        if fontColorPanel then
            fontColorPanel.Visible = not fontColorPanel.Visible
        end
    end)

    if not isAdminUser then
        local customBubbleButton = Instance.new("TextButton")
        customBubbleButton.Name = "CustomBubbleToggle"
        customBubbleButton.Size = UDim2.new(0, 44, 0, 22)
        customBubbleButton.AnchorPoint = Vector2.new(1, 1)
        customBubbleButton.Position = UDim2.new(1, -8, 1, -8)
        customBubbleButton.BackgroundColor3 = backgroundSecondary
        customBubbleButton.BorderSizePixel = 0
        customBubbleButton.Font = Enum.Font.GothamBold
        customBubbleButton.Text = "自定义气泡"
        customBubbleButton.TextColor3 = textColor
        customBubbleButton.TextSize = 11
        customBubbleButton.AutoButtonColor = false
        customBubbleButton.LayoutOrder = 6
        customBubbleButton.ZIndex = 22
        customBubbleButton.Parent = colorPanel
        addUICorner(customBubbleButton, UDim.new(0, 8))
        addButtonStroke(customBubbleButton, 180, 0.3)

        customBubbleButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if avatarBorderQuickPanel then
                avatarBorderQuickPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
            if customColorPanel then
                customColorPanel.Visible = not customColorPanel.Visible
            end
        end)

        local avatarQuickButton = Instance.new("TextButton")
        avatarQuickButton.Name = "AvatarBorderQuickToggle"
        avatarQuickButton.Size = UDim2.new(0, 44, 0, 22)
        avatarQuickButton.AnchorPoint = Vector2.new(1, 1)
        avatarQuickButton.Position = UDim2.new(1, -8 - 44 - 4, 1, -8)
        avatarQuickButton.BackgroundColor3 = backgroundSecondary
        avatarQuickButton.BorderSizePixel = 0
        avatarQuickButton.Font = Enum.Font.GothamBold
        avatarQuickButton.Text = "头像边框"
        avatarQuickButton.TextColor3 = textColor
        avatarQuickButton.TextSize = 11
        avatarQuickButton.AutoButtonColor = false
        avatarQuickButton.LayoutOrder = 5
        avatarQuickButton.ZIndex = 22
        avatarQuickButton.Parent = colorPanel
        addUICorner(avatarQuickButton, UDim.new(0, 8))
        addButtonStroke(avatarQuickButton, 180, 0.3)

        avatarQuickButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderQuickPanel then
                local container = chatContent
                if container and avatarQuickButton and avatarBorderQuickPanel then
                    local containerPos = container.AbsolutePosition
                    local containerSize = container.AbsoluteSize
                    local btnPos = avatarQuickButton.AbsolutePosition
                    local btnSize = avatarQuickButton.AbsoluteSize
                    local panelSize = avatarBorderQuickPanel.AbsoluteSize
                    local panelW = (panelSize and panelSize.X > 0) and panelSize.X or (avatarBorderQuickPanel.Size.X.Offset or 180)
                    local panelH = (panelSize and panelSize.Y > 0) and panelSize.Y or (avatarBorderQuickPanel.Size.Y.Offset or 96)
                    local desiredX = (btnPos.X - containerPos.X) - panelW - 6
                    local desiredY = (btnPos.Y - containerPos.Y) + btnSize.Y + 4
                    local minX = 8
                    local maxX = math.max(minX, (containerSize.X - panelW - 8))
                    local minY = panelH + 8
                    local maxY = math.max(minY, (containerSize.Y - 8))
                    local clampedX = math.clamp(desiredX, minX, maxX)
                    local clampedY = math.clamp(desiredY, minY, maxY)
                    avatarBorderQuickPanel.Position = UDim2.fromOffset(clampedX, clampedY)
                end
                avatarBorderQuickPanel.Visible = not avatarBorderQuickPanel.Visible
            end
        end)
    end

    if isAdminUser then
        local customOpenButton = Instance.new("TextButton")
        customOpenButton.Name = "CustomColorToggle"
        customOpenButton.Size = UDim2.new(0, 44, 0, 22)
        customOpenButton.AnchorPoint = Vector2.new(1, 1)
        customOpenButton.Position = UDim2.new(1, -8, 1, -8)
        customOpenButton.BackgroundColor3 = backgroundSecondary
        customOpenButton.BorderSizePixel = 0
        customOpenButton.Font = Enum.Font.GothamBold
        customOpenButton.Text = "自定义气泡颜色"
        customOpenButton.TextColor3 = textColor
        customOpenButton.TextSize = 11
        customOpenButton.AutoButtonColor = false
        customOpenButton.LayoutOrder = 3
        customOpenButton.ZIndex = 22
        customOpenButton.Parent = colorPanel
        addUICorner(customOpenButton, UDim.new(0, 8))
        addButtonStroke(customOpenButton, 180, 0.3)

        customOpenButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = not customColorPanel.Visible
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
        end)
    end

    if isAdminUser then
        local paletteRightOffset = (-8 - 44 - 4 - 44 - 4)
        local paletteButton = Instance.new("TextButton")
        paletteButton.Name = "BubblePaletteToggle"
        paletteButton.Size = UDim2.new(0, 36, 0, 22)
        paletteButton.AnchorPoint = Vector2.new(1, 1)
        paletteButton.Position = UDim2.new(1, paletteRightOffset, 1, -8 - 22 - 4)
        paletteButton.BackgroundColor3 = backgroundSecondary
        paletteButton.BorderSizePixel = 0
        paletteButton.Font = Enum.Font.GothamBold
        paletteButton.Text = "渐变气泡"
        paletteButton.TextColor3 = textColor
        paletteButton.TextSize = 11
        paletteButton.AutoButtonColor = false
        paletteButton.LayoutOrder = 2
        paletteButton.ZIndex = 22
        paletteButton.Parent = colorPanel
        addUICorner(paletteButton, UDim.new(0, 8))
        addButtonStroke(paletteButton, 180, 0.3)

        paletteButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = not bubblePalettePanel.Visible
            end
        end)

        local borderButton = Instance.new("TextButton")
        borderButton.Name = "BubbleBorderToggle"
        borderButton.Size = UDim2.new(0, 36, 0, 22)
        borderButton.AnchorPoint = Vector2.new(1, 1)
        borderButton.Position = UDim2.new(1, paletteRightOffset, 1, -8)
        borderButton.BackgroundColor3 = backgroundSecondary
        borderButton.BorderSizePixel = 0
        borderButton.Font = Enum.Font.GothamBold
        borderButton.Text = "渐变气泡边框"
        borderButton.TextColor3 = textColor
        borderButton.TextSize = 11
        borderButton.AutoButtonColor = false
        borderButton.LayoutOrder = 1
        borderButton.ZIndex = 22
        borderButton.Parent = colorPanel
        addUICorner(borderButton, UDim.new(0, 8))
        addButtonStroke(borderButton, 180, 0.3)

        borderButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = not bubbleBorderPanel.Visible
            end
        end)

        local avatarBorderButton = Instance.new("TextButton")
        avatarBorderButton.Name = "AvatarBorderToggle"
        avatarBorderButton.Size = UDim2.new(0, 56, 0, 22)
        avatarBorderButton.BackgroundColor3 = backgroundSecondary
        avatarBorderButton.BorderSizePixel = 0
        avatarBorderButton.Font = Enum.Font.GothamBold
        avatarBorderButton.Text = "头像边框"
        avatarBorderButton.TextColor3 = textColor
        avatarBorderButton.TextSize = 11
        avatarBorderButton.AutoButtonColor = false
        avatarBorderButton.LayoutOrder = 6
        avatarBorderButton.ZIndex = 22
        avatarBorderButton.Parent = colorPanel
        addUICorner(avatarBorderButton, UDim.new(0, 8))
        addButtonStroke(avatarBorderButton, 180, 0.3)

        avatarBorderButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = not avatarBorderPanel.Visible
            end
        end)

        local avatarBorderSolidButton = Instance.new("TextButton")
        avatarBorderSolidButton.Name = "AvatarBorderSolidToggle"
        avatarBorderSolidButton.Size = UDim2.new(0, 56, 0, 22)
        avatarBorderSolidButton.BackgroundColor3 = backgroundSecondary
        avatarBorderSolidButton.BorderSizePixel = 0
        avatarBorderSolidButton.Font = Enum.Font.GothamBold
        avatarBorderSolidButton.Text = "普通边框"
        avatarBorderSolidButton.TextColor3 = textColor
        avatarBorderSolidButton.TextSize = 11
        avatarBorderSolidButton.AutoButtonColor = false
        avatarBorderSolidButton.LayoutOrder = 7
        avatarBorderSolidButton.ZIndex = 22
        avatarBorderSolidButton.Parent = colorPanel
        addUICorner(avatarBorderSolidButton, UDim.new(0, 8))
        addButtonStroke(avatarBorderSolidButton, 180, 0.3)

        avatarBorderSolidButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = not avatarBorderSolidPanel.Visible
            end
        end)

        local dynamicBubbleButton = Instance.new("TextButton")
        dynamicBubbleButton.Name = "DynamicBubbleToggle"
        dynamicBubbleButton.Size = UDim2.new(0, 56, 0, 22)
        dynamicBubbleButton.BackgroundColor3 = backgroundSecondary
        dynamicBubbleButton.BorderSizePixel = 0
        dynamicBubbleButton.Font = Enum.Font.GothamBold
        dynamicBubbleButton.Text = "动态气泡"
        dynamicBubbleButton.TextColor3 = textColor
        dynamicBubbleButton.TextSize = 11
        dynamicBubbleButton.AutoButtonColor = false
        dynamicBubbleButton.LayoutOrder = 8
        dynamicBubbleButton.ZIndex = 22
        dynamicBubbleButton.Parent = colorPanel
        addUICorner(dynamicBubbleButton, UDim.new(0, 8))
        addButtonStroke(dynamicBubbleButton, 180, 0.3)

        dynamicBubbleButton.MouseButton1Click:Connect(function()
            emojiPanel.Visible = false
            remoteEmoji.panel.Visible = false
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if fontColorPanel then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = not dynamicBubblePanel.Visible
            end
        end)

        local randomRightOffset = paletteRightOffset - 36 - 4
        local randomButton = Instance.new("TextButton")
        randomButton.Name = "RandomColorToggle"
        randomButton.Size = UDim2.new(0, 36, 0, 22)
        randomButton.AnchorPoint = Vector2.new(1, 1)
        randomButton.Position = UDim2.new(1, randomRightOffset, 1, -8)
        randomButton.BackgroundColor3 = backgroundSecondary
        randomButton.BorderSizePixel = 0
        randomButton.Font = Enum.Font.GothamBold
        randomButton.Text = "随机气泡"
        randomButton.TextColor3 = textColor
        randomButton.TextSize = 11
        randomButton.AutoButtonColor = false
        randomButton.LayoutOrder = 5
        randomButton.ZIndex = 22
        randomButton.Parent = colorPanel
        addUICorner(randomButton, UDim.new(0, 8))
        addButtonStroke(randomButton, 180, 0.3)

        local function updateRandomButtonVisual()
            if randomColorEnabled then
                randomButton.BackgroundColor3 = accentColor
                randomButton.TextColor3 = textColor
            else
                randomButton.BackgroundColor3 = backgroundSecondary
                randomButton.TextColor3 = textColor
            end
        end

        updateRandomButtonVisual()

        randomButton.MouseButton1Click:Connect(function()
            randomColorEnabled = not randomColorEnabled
            updateRandomButtonVisual()
            saveChatColorConfig()
            colorPanel.Visible = false
            if customColorPanel then
                customColorPanel.Visible = false
            end
            if bubblePalettePanel then
                bubblePalettePanel.Visible = false
            end
            if bubbleBorderPanel then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel then
                avatarBorderSolidPanel.Visible = false
            end
            if dynamicBubblePanel then
                dynamicBubblePanel.Visible = false
            end
        end)
    end
end

local function getRandomColorFromPool()
    local total = #randomColorPool
    if total == 0 then
        return selfBubbleColor
    end
    local index = math.random(1, total)
    return randomColorPool[index]
end

local function createBubblePalettePanel()
    local panel = Instance.new("Frame")
    panel.Name = "BubblePalettePanel"
    panel.Size = UDim2.new(0, 180, 0, 120)
    panel.Position = UDim2.new(0, 8, 1, -255)
    panel.BackgroundColor3 = backgroundTertiary
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 21
    panel.Parent = chatContent
    addUICorner(panel, UDim.new(0, 10))
    local paletteStroke = addUIStroke(panel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(paletteStroke, strokeGradient, 180)
    addUIGradient(panel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "渐变气泡"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    local gridHost = Instance.new("Frame")
    gridHost.Name = "GridHost"
    gridHost.Size = UDim2.new(1, -16, 1, -34)
    gridHost.Position = UDim2.new(0, 8, 0, 26)
    gridHost.BackgroundTransparency = 1
    gridHost.BorderSizePixel = 0
    gridHost.ZIndex = 22
    gridHost.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 34, 0, 24)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    grid.Parent = gridHost

    local paletteDefs = {
        { Color3.fromRGB(255, 0, 0), Color3.fromRGB(80, 150, 255), Color3.fromRGB(255, 230, 120) },
        { Color3.fromRGB(255, 120, 60), Color3.fromRGB(255, 140, 200), Color3.fromRGB(160, 120, 255) },
        { Color3.fromRGB(80, 200, 120), Color3.fromRGB(190, 240, 120), Color3.fromRGB(255, 250, 170) },
        { Color3.fromRGB(80, 150, 255), Color3.fromRGB(160, 120, 255), Color3.fromRGB(255, 140, 200) },
        { Color3.fromRGB(255, 140, 200), Color3.fromRGB(255, 200, 120), Color3.fromRGB(80, 150, 255) },
        { Color3.fromRGB(200, 80, 255), Color3.fromRGB(255, 230, 120), Color3.fromRGB(80, 150, 255) },
        { Color3.fromRGB(120, 80, 255), Color3.fromRGB(255, 70, 120), Color3.fromRGB(80, 200, 120) },
        { Color3.fromRGB(80, 210, 210), Color3.fromRGB(80, 150, 255), Color3.fromRGB(160, 120, 255) },
        { Color3.fromRGB(255, 230, 120), Color3.fromRGB(80, 200, 120), Color3.fromRGB(80, 210, 210) },
        { Color3.fromRGB(255, 170, 80), Color3.fromRGB(255, 140, 200), Color3.fromRGB(80, 150, 255) },
        { Color3.fromRGB(230, 230, 230), Color3.fromRGB(120, 140, 255), Color3.fromRGB(200, 140, 255) },
    }

    for _, def in ipairs(paletteDefs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 34, 0, 24)
        btn.BackgroundColor3 = def[1]
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 23
        btn.Parent = gridHost
        addUICorner(btn, UDim.new(0, 6))
        local g = Instance.new("UIGradient")
        g.Name = "BubbleGradient"
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, def[1]),
            ColorSequenceKeypoint.new(0.5, def[2]),
            ColorSequenceKeypoint.new(1, def[3]),
        })
        g.Rotation = 0
        g.Parent = btn
        local stroke = addUIStroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.3)
        btn.MouseEnter:Connect(function()
            tweenProperty(stroke, {Transparency = 0}, 0.1)
        end)
        btn.MouseLeave:Connect(function()
            tweenProperty(stroke, {Transparency = 0.6}, 0.1)
        end)
        btn.MouseButton1Click:Connect(function()
            local colors = { def[1], def[2], def[3] }
            selfBubbleStyle = { type = "gradient", colors = colors }
            selfBubbleColor = colors[1]
            if colorToggle then
                applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
            end
            saveChatColorConfig()
            panel.Visible = false
        end)
    end
    return panel
end

local function createDynamicBubblePanel()
    local panel = Instance.new("Frame")
    panel.Name = "DynamicBubblePanel"
    panel.Size = UDim2.new(0, 180, 0, 200)
    panel.Position = UDim2.new(0, 8, 1, -335)
    panel.BackgroundColor3 = backgroundTertiary
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 21
    panel.Parent = chatContent
    addUICorner(panel, UDim.new(0, 10))
    local paletteStroke = addUIStroke(panel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(paletteStroke, strokeGradient, 180)
    addUIGradient(panel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "动态气泡"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    local gridHost = Instance.new("Frame")
    gridHost.Name = "GridHost"
    gridHost.Size = UDim2.new(1, -16, 1, -34)
    gridHost.Position = UDim2.new(0, 8, 0, 26)
    gridHost.BackgroundTransparency = 1
    gridHost.BorderSizePixel = 0
    gridHost.ZIndex = 22
    gridHost.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 52, 0, 28)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    grid.Parent = gridHost

    for i = 1, 15 do
        local def = dynamicBubbleDefs[i]
        if def and type(def.colors) == "table" and def.colors[1] and def.colors[2] and def.colors[3] then
            local btn = Instance.new("TextButton")
            btn.Name = "DynamicBubble" .. tostring(i)
            btn.Size = UDim2.new(0, 52, 0, 28)
            btn.BackgroundColor3 = backgroundSecondary
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 23
            btn.Parent = gridHost
            addUICorner(btn, UDim.new(0, 6))

            local style = { type = "gradient", colors = { def.colors[1], def.colors[2], def.colors[3] }, animId = i }
            applyBubbleStyleToFrame(btn, style)

            local stroke = addUIStroke(btn, Color3.fromRGB(255, 255, 255), 1, 0.3)
            btn.MouseEnter:Connect(function()
                tweenProperty(stroke, {Transparency = 0}, 0.1)
            end)
            btn.MouseLeave:Connect(function()
                tweenProperty(stroke, {Transparency = 0.6}, 0.1)
            end)
            btn.MouseButton1Click:Connect(function()
                selfBubbleStyle = style
                selfBubbleColor = style.colors[1]
                if colorToggle then
                    applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
                end
                saveChatColorConfig()
                panel.Visible = false
            end)
        end
    end

    return panel
end

local function createBubbleBorderPanel()
    local panel = Instance.new("Frame")
    panel.Name = "BubbleBorderPanel"
    panel.Size = UDim2.new(0, 180, 0, 120)
    panel.Position = UDim2.new(0, 8, 1, -255)
    panel.BackgroundColor3 = backgroundTertiary
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 21
    panel.Parent = chatContent
    addUICorner(panel, UDim.new(0, 10))
    local borderStroke = addUIStroke(panel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(borderStroke, strokeGradient, 180)
    addUIGradient(panel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "气泡边框"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    local gridHost = Instance.new("Frame")
    gridHost.Name = "GridHost"
    gridHost.Size = UDim2.new(1, -16, 1, -34)
    gridHost.Position = UDim2.new(0, 8, 0, 26)
    gridHost.BackgroundTransparency = 1
    gridHost.BorderSizePixel = 0
    gridHost.ZIndex = 22
    gridHost.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 34, 0, 24)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    grid.Parent = gridHost

    for i = 1, 12 do
        local def = bubbleBorderDefs[i]
        if def then
            local btn = Instance.new("TextButton")
            btn.Name = "Border" .. tostring(i)
            btn.Size = UDim2.new(0, 34, 0, 24)
            btn.BackgroundColor3 = backgroundSecondary
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 23
            btn.Parent = gridHost
            addUICorner(btn, UDim.new(0, 6))

            local stroke = addUIStroke(btn, Color3.fromRGB(255, 255, 255), def.thickness or 2, 0.05)
            addStrokeGradient(stroke, def.gradient, 0)
            animateStrokeGradient(stroke, def.speed or 22)

            btn.MouseButton1Click:Connect(function()
                if selfBubbleBorderId == i then
                    selfBubbleBorderId = 0
                else
                    selfBubbleBorderId = i
                end
                if colorToggle then
                    applyBubbleBorderToFrame(colorToggle, isAdminName(userName) and selfBubbleBorderId or 0)
                end
                saveChatColorConfig()
                panel.Visible = false
            end)
        end
    end

    return panel
end

local function createAvatarSolidBorderPanel()
    local panel = Instance.new("Frame")
    panel.Name = "AvatarBorderSolidPanel"
    panel.Size = UDim2.new(0, 180, 0, 140)
    panel.Position = UDim2.new(0, 152, 1, -255)--整体u
    panel.BackgroundColor3 = backgroundTertiary
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 21
    panel.Parent = chatContent
    addUICorner(panel, UDim.new(0, 10))
    local borderStroke = addUIStroke(panel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(borderStroke, strokeGradient, 180)
    addUIGradient(panel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "普通边框"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    local gridHost = Instance.new("Frame")
    gridHost.Name = "GridHost"
    gridHost.Size = UDim2.new(1, -16, 1, -34)
    gridHost.Position = UDim2.new(0, 8, 0, 26)
    gridHost.BackgroundTransparency = 1
    gridHost.BorderSizePixel = 0
    gridHost.ZIndex = 22
    gridHost.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 34, 0, 24)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    grid.Parent = gridHost

    for i, c in ipairs(avatarBorderSolidColors) do
        local borderId = 100 + i
        local btn = Instance.new("TextButton")
        btn.Name = "SolidBorder" .. tostring(i)
        btn.Size = UDim2.new(0, 34, 0, 24)
        btn.BackgroundColor3 = backgroundSecondary
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 23
        btn.Parent = gridHost
        addUICorner(btn, UDim.new(0, 6))

        local stroke = addUIStroke(btn, c, 2, 0.05)

        btn.MouseButton1Click:Connect(function()
            if selfAvatarBorderId == borderId then
                selfAvatarBorderId = 0
            else
                selfAvatarBorderId = borderId
            end
            saveChatColorConfig()
            panel.Visible = false
            if avatarBorderPanel then
                avatarBorderPanel.Visible = false
            end
        end)
    end

    return panel
end

local function createAvatarBorderPanel()
    local panel = Instance.new("Frame")
    panel.Name = "AvatarBorderPanel"
    panel.Size = UDim2.new(0, 180, 0, 140)
    panel.Position = UDim2.new(0, 8, 1, -285)
    panel.BackgroundColor3 = backgroundTertiary
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.ZIndex = 21
    panel.Parent = chatContent
    addUICorner(panel, UDim.new(0, 10))
    local borderStroke = addUIStroke(panel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(borderStroke, strokeGradient, 180)
    addUIGradient(panel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "头像边框"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = panel

    local normalBtn = Instance.new("TextButton")
    normalBtn.Name = "OpenSolid"
    normalBtn.Size = UDim2.new(0, 56, 0, 18)
    normalBtn.Position = UDim2.new(1, -24 - 56 - 6, 0, 6)
    normalBtn.BackgroundColor3 = backgroundSecondary
    normalBtn.BorderSizePixel = 0
    normalBtn.Font = Enum.Font.GothamBold
    normalBtn.Text = "普通边框"
    normalBtn.TextColor3 = textColor
    normalBtn.TextSize = 11
    normalBtn.AutoButtonColor = false
    normalBtn.ZIndex = 22
    normalBtn.Parent = panel
    addUICorner(normalBtn, UDim.new(0, 6))
    addButtonStroke(normalBtn, 180, 0.35)
    normalBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        if avatarBorderSolidPanel then
            avatarBorderSolidPanel.Visible = not avatarBorderSolidPanel.Visible
        end
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
    end)

    local gridHost = Instance.new("Frame")
    gridHost.Name = "GridHost"
    gridHost.Size = UDim2.new(1, -16, 1, -34)
    gridHost.Position = UDim2.new(0, 8, 0, 26)
    gridHost.BackgroundTransparency = 1
    gridHost.BorderSizePixel = 0
    gridHost.ZIndex = 22
    gridHost.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 34, 0, 24)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    grid.Parent = gridHost

    for i = 1, 12 do
        local def = avatarBorderDefs[i]
        if def and def.gradient then
            local btn = Instance.new("TextButton")
            btn.Name = "Border" .. tostring(i)
            btn.Size = UDim2.new(0, 34, 0, 24)
            btn.BackgroundColor3 = backgroundSecondary
            btn.BorderSizePixel = 0
            btn.Text = ""
            btn.AutoButtonColor = false
            btn.ZIndex = 23
            btn.Parent = gridHost
            addUICorner(btn, UDim.new(0, 6))

            local stroke = addUIStroke(btn, Color3.fromRGB(255, 255, 255), def.thickness or 2, 0.05)
            addStrokeGradient(stroke, def.gradient, 0)
            animateStrokeGradient(stroke, def.speed or 22)

            btn.MouseButton1Click:Connect(function()
                if selfAvatarBorderId == i then
                    selfAvatarBorderId = 0
                else
                    selfAvatarBorderId = i
                end
                saveChatColorConfig()
                panel.Visible = false
            end)
        end
    end

    return panel
end

do
    customColorPanel = Instance.new("Frame")
    customColorPanel.Name = "CustomColorPanel"
    customColorPanel.Size = UDim2.new(0, 180, 0, 120)
    customColorPanel.Position = UDim2.new(0, 8, 1, -210)
    customColorPanel.BackgroundColor3 = backgroundTertiary
    customColorPanel.BorderSizePixel = 0
    customColorPanel.Visible = false
    customColorPanel.ZIndex = 21
    customColorPanel.Parent = chatContent

    addUICorner(customColorPanel, UDim.new(0, 10))
    local customStroke = addUIStroke(customColorPanel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(customStroke, strokeGradient, 180)
    addUIGradient(customColorPanel, backgroundGradient, 68)

    local colorArea = Instance.new("Frame")
    colorArea.Name = "ColorArea"
    colorArea.Size = UDim2.new(1, -16, 0, 32)
    colorArea.Position = UDim2.new(0, 8, 0, 8)
    colorArea.BackgroundColor3 = Color3.new(1, 1, 1)
    colorArea.BorderSizePixel = 0
    colorArea.ClipsDescendants = true
    colorArea.ZIndex = 22
    colorArea.Parent = customColorPanel
    addUICorner(colorArea, UDim.new(0, 8))
    customColorArea = colorArea

    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
    })
    hueGradient.Rotation = 0
    hueGradient.Parent = colorArea

    local indicator = Instance.new("Frame")
    indicator.Name = "Selector"
    indicator.Size = UDim2.new(0, 6, 0, 6)
    indicator.AnchorPoint = Vector2.new(0.5, 0.5)
    indicator.BackgroundColor3 = Color3.new(1, 1, 1)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 23
    indicator.Parent = colorArea
    addUICorner(indicator, UDim.new(1, 0))

    local pickingCustomColor = false
    local lastCustomColor = nil

    local function updateCustomColorFromPosition(pos)
        local areaPos = colorArea.AbsolutePosition
        local areaSize = colorArea.AbsoluteSize
        if areaSize.X <= 0 or areaSize.Y <= 0 then
            return
        end
        local rx = math.clamp((pos.X - areaPos.X) / areaSize.X, 0, 1)
        local ry = math.clamp((pos.Y - areaPos.Y) / areaSize.Y, 0, 1)
        local c = Color3.fromHSV(rx, 1, 1 - 0.6 * ry)
        selfBubbleColor = c
        selfBubbleStyle = c
        lastCustomColor = c
        applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
        indicator.Position = UDim2.new(rx, 0, ry, 0)
    end

    colorArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pickingCustomColor = true
            updateCustomColorFromPosition(input.Position)
        end
    end)

    colorArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pickingCustomColor = false
            if lastCustomColor then
                saveChatColorConfig()
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not pickingCustomColor then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateCustomColorFromPosition(input.Position)
        end
    end)

    local stripesContainer = Instance.new("Frame")
    stripesContainer.Name = "StripesContainer"
    stripesContainer.Size = UDim2.new(1, -16, 0, 63)
    stripesContainer.Position = UDim2.new(0, 8, 0, 48)
    stripesContainer.BackgroundTransparency = 1
    stripesContainer.BorderSizePixel = 0
    stripesContainer.ZIndex = 22
    stripesContainer.Parent = customColorPanel

    local stripesLayout = Instance.new("UIListLayout")
    stripesLayout.FillDirection = Enum.FillDirection.Vertical
    stripesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    stripesLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    stripesLayout.Padding = UDim.new(0, 1)
    stripesLayout.Parent = stripesContainer

    local stripeDefs = {
        {Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 230, 230)},
        {Color3.fromRGB(0, 0, 0), Color3.fromRGB(230, 230, 230)},
        {Color3.fromRGB(40, 160, 70), Color3.fromRGB(220, 255, 230)},
        {Color3.fromRGB(255, 120, 180), Color3.fromRGB(255, 235, 245)},
        {Color3.fromRGB(80, 150, 255), Color3.fromRGB(230, 240, 255)},
        {Color3.fromRGB(250, 220, 120), Color3.fromRGB(255, 245, 210)},
        {Color3.fromRGB(150, 90, 210), Color3.fromRGB(230, 220, 255)},
        {Color3.fromRGB(255, 160, 210), Color3.fromRGB(255, 240, 250)},
    }

    local function createStripe(startColor, endColor)
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, 0, 0, 7)
        bar.BackgroundColor3 = startColor
        bar.BorderSizePixel = 0
        bar.ZIndex = 23
        bar.Parent = stripesContainer
        addUICorner(bar, UDim.new(0, 4))

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, startColor),
            ColorSequenceKeypoint.new(1, endColor),
        })
        gradient.Rotation = 0
        gradient.Parent = bar

        bar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local barPos = bar.AbsolutePosition
                local barSize = bar.AbsoluteSize
                if barSize.X <= 0 then
                    return
                end
                local t = math.clamp((input.Position.X - barPos.X) / barSize.X, 0, 1)
                local c = startColor:Lerp(endColor, t)
                selfBubbleColor = c
                selfBubbleStyle = c
                applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
                saveChatColorConfig()
                customColorPanel.Visible = false
            end
        end)
    end

    for _, def in ipairs(stripeDefs) do
        createStripe(def[1], def[2])
    end
    bubblePalettePanel = createBubblePalettePanel()
    dynamicBubblePanel = createDynamicBubblePanel()
    bubbleBorderPanel = createBubbleBorderPanel()
    avatarBorderPanel = createAvatarBorderPanel()
    avatarBorderSolidPanel = createAvatarSolidBorderPanel()
end

do
    fontColorPanel = Instance.new("Frame")
    fontColorPanel.Name = "FontColorPanel"
    fontColorPanel.Size = UDim2.new(0, 180, 0, isAdminUser and 150 or 96)
    fontColorPanel.Position = UDim2.new(0, 8, 1, isAdminUser and -265 or -200)
    fontColorPanel.BackgroundColor3 = backgroundTertiary
    fontColorPanel.BorderSizePixel = 0
    fontColorPanel.Visible = false
    fontColorPanel.ZIndex = 21
    fontColorPanel.Parent = chatContent
    addUICorner(fontColorPanel, UDim.new(0, 10))
    local fontStroke = addUIStroke(fontColorPanel, Color3.fromRGB(255, 255, 255), 1.1, 0.55)
    addStrokeGradient(fontStroke, strokeGradient, 180)
    addUIGradient(fontColorPanel, backgroundGradient, 68)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "字体颜色"
    title.TextColor3 = textColor
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 22
    title.Parent = fontColorPanel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 18, 0, 18)
    closeBtn.Position = UDim2.new(1, -24, 0, 6)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "×"
    closeBtn.TextColor3 = textMuted
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = fontColorPanel
    closeBtn.MouseButton1Click:Connect(function()
        fontColorPanel.Visible = false
    end)

    local function makePickButton(parent, pos, size, c, labelText)
        local b = Instance.new("TextButton")
        b.Size = size
        b.Position = pos
        b.BackgroundColor3 = c
        b.BorderSizePixel = 0
        b.Text = labelText or ""
        b.TextColor3 = (c == Color3.new(0, 0, 0)) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.AutoButtonColor = false
        b.ZIndex = 22
        b.Parent = parent
        addUICorner(b, UDim.new(0, 8))
        addUIStroke(b, Color3.fromRGB(255, 255, 255), 1, 0.35)
        b.MouseButton1Click:Connect(function()
            if setChatFontColor then
                setChatFontColor(c)
            end
            fontColorPanel.Visible = false
        end)
        return b
    end

    if not isAdminUser then
        local gridHost = Instance.new("Frame")
        gridHost.Name = "GridHost"
        gridHost.Size = UDim2.new(1, -16, 1, -30)
        gridHost.Position = UDim2.new(0, 8, 0, 26)
        gridHost.BackgroundTransparency = 1
        gridHost.BorderSizePixel = 0
        gridHost.ZIndex = 22
        gridHost.Parent = fontColorPanel

        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0, 78, 0, 22)
        grid.CellPadding = UDim2.new(0, 6, 0, 4)
        grid.FillDirectionMaxCells = 2
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = gridHost

        local function makeGridPickButton(c, text)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 78, 0, 22)
            b.BackgroundColor3 = c
            b.BorderSizePixel = 0
            b.Text = text or ""
            b.TextColor3 = (c == Color3.new(0, 0, 0)) and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.AutoButtonColor = false
            b.ZIndex = 23
            b.Parent = gridHost
            addUICorner(b, UDim.new(0, 7))
            addUIStroke(b, Color3.fromRGB(255, 255, 255), 1, 0.35)
            b.MouseButton1Click:Connect(function()
                if setChatFontColor then
                    setChatFontColor(c)
                end
                fontColorPanel.Visible = false
            end)
        end

        makeGridPickButton(Color3.new(1, 1, 1), "白色")
        makeGridPickButton(Color3.new(0, 0, 0), "黑色")
        makeGridPickButton(Color3.fromRGB(80, 210, 210), "青色")
    else
        local hueBar = Instance.new("Frame")
        hueBar.Name = "HueBar"
        hueBar.Size = UDim2.new(1, -20, 0, 24)
        hueBar.Position = UDim2.new(0, 10, 0, 32)
        hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
        hueBar.BorderSizePixel = 0
        hueBar.ZIndex = 22
        hueBar.Parent = fontColorPanel
        hueBar.ClipsDescendants = true
        addUICorner(hueBar, UDim.new(0, 8))

        local hueGradient = Instance.new("UIGradient")
        hueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        hueGradient.Rotation = 0
        hueGradient.Parent = hueBar

        local hueIndicator = Instance.new("Frame")
        hueIndicator.Name = "Indicator"
        hueIndicator.Size = UDim2.new(0, 6, 0, 16)
        hueIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
        hueIndicator.Position = UDim2.new(0, 0, 0.5, 0)
        hueIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
        hueIndicator.BorderSizePixel = 0
        hueIndicator.ZIndex = 23
        hueIndicator.Parent = hueBar
        addUICorner(hueIndicator, UDim.new(0, 3))
        addUIStroke(hueIndicator, Color3.fromRGB(0, 0, 0), 1, 0.35)

        local pickingHue = false
        local function updateHueAt(pos)
            local p = hueBar.AbsolutePosition
            local s = hueBar.AbsoluteSize
            if s.X <= 0 then
                return
            end
            local t = math.clamp((pos.X - p.X) / s.X, 0, 1)
            hueIndicator.Position = UDim2.new(t, 0, 0.5, 0)
            local c = Color3.fromHSV(t, 1, 1)
            if setChatFontColor then
                setChatFontColor(c)
            end
        end

        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                pickingHue = true
                updateHueAt(input.Position)
            end
        end)
        hueBar.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                pickingHue = false
                fontColorPanel.Visible = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not pickingHue then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                updateHueAt(input.Position)
            end
        end)

        local stripesContainer = Instance.new("Frame")
        stripesContainer.Name = "Stripes"
        stripesContainer.Size = UDim2.new(1, -20, 0, 70)
        stripesContainer.Position = UDim2.new(0, 10, 0, 62)
        stripesContainer.BackgroundTransparency = 1
        stripesContainer.BorderSizePixel = 0
        stripesContainer.ZIndex = 22
        stripesContainer.Parent = fontColorPanel

        local stripesLayout = Instance.new("UIListLayout")
        stripesLayout.FillDirection = Enum.FillDirection.Vertical
        stripesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        stripesLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        stripesLayout.Padding = UDim.new(0, 1)
        stripesLayout.Parent = stripesContainer

        local stripeDefs = {
            {Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 230, 230)},
            {Color3.fromRGB(0, 0, 0), Color3.fromRGB(230, 230, 230)},
            {Color3.fromRGB(40, 160, 70), Color3.fromRGB(220, 255, 230)},
            {Color3.fromRGB(255, 120, 180), Color3.fromRGB(255, 235, 245)},
            {Color3.fromRGB(80, 150, 255), Color3.fromRGB(230, 240, 255)},
            {Color3.fromRGB(250, 220, 120), Color3.fromRGB(255, 245, 210)},
            {Color3.fromRGB(150, 90, 210), Color3.fromRGB(230, 220, 255)},
            {Color3.fromRGB(255, 160, 210), Color3.fromRGB(255, 240, 250)},
        }

        local function createStripe(startColor, endColor)
            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, 0, 0, 7)
            bar.BackgroundColor3 = startColor
            bar.BorderSizePixel = 0
            bar.ZIndex = 23
            bar.Parent = stripesContainer
            addUICorner(bar, UDim.new(0, 4))

            local gradient = Instance.new("UIGradient")
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, startColor),
                ColorSequenceKeypoint.new(1, endColor),
            })
            gradient.Rotation = 0
            gradient.Parent = bar

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local barPos = bar.AbsolutePosition
                    local barSize = bar.AbsoluteSize
                    if barSize.X <= 0 then
                        return
                    end
                    local t = math.clamp((input.Position.X - barPos.X) / barSize.X, 0, 1)
                    local c = startColor:Lerp(endColor, t)
                    if setChatFontColor then
                        setChatFontColor(c)
                    end
                    fontColorPanel.Visible = false
                end
            end)
        end

        for _, def in ipairs(stripeDefs) do
            createStripe(def[1], def[2])
        end
    end
end

local emojiScroll = Instance.new("ScrollingFrame")
emojiScroll.Size = UDim2.new(1, -12, 1, -12)
emojiScroll.Position = UDim2.new(0, 6, 0, 6)
emojiScroll.BackgroundTransparency = 1
emojiScroll.ScrollBarThickness = 3
emojiScroll.ScrollBarImageColor3 = accentColor
emojiScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
emojiScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
emojiScroll.ZIndex = 21
emojiScroll.Parent = emojiPanel

local emojiGrid = Instance.new("UIGridLayout")
emojiGrid.CellSize = UDim2.new(0, 30, 0, 30)
emojiGrid.CellPadding = UDim2.new(0, 4, 0, 4)
emojiGrid.Parent = emojiScroll

local emojis = {"🤪","🥴", "🤭", "😀", "😂", "😍", "🥺", "😎", "🤔", "👍", "👎", "❤️", "🔥", "✨", "🎉", "💯", "😮", "🤯", "😱", "🥶", "🥵", "🤮", "🤢", "🙏", "😊", "😢", "😡", "🤣", "😘", "🥰","😈", "👹", "👺", "🤡", "💀", "☠️", "👻", "👽", "👾", "🤖", "🎃", "😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"}

for _, emoji in ipairs(emojis) do
    local emojiButton = Instance.new("TextButton")
    emojiButton.Size = UDim2.new(0, 30, 0, 30)
    emojiButton.BackgroundColor3 = backgroundColor
    emojiButton.BorderSizePixel = 0
    emojiButton.Text = emoji
    emojiButton.TextSize = 18
    emojiButton.AutoButtonColor = false
    emojiButton.ZIndex = 22
    emojiButton.Parent = emojiScroll
    addUICorner(emojiButton, UDim.new(0, 6))
    emojiButton.MouseEnter:Connect(function()
        tweenProperty(emojiButton, {BackgroundColor3 = backgroundSecondary}, 0.1)
    end)
    emojiButton.MouseLeave:Connect(function()
        tweenProperty(emojiButton, {BackgroundColor3 = backgroundColor}, 0.1)
    end)
    emojiButton.MouseButton1Click:Connect(function()
        if not messageInput then
            return
        end
        local current = messageInput.Text or ""
        messageInput.Text = current .. emoji
        messageInput:CaptureFocus()
        emojiPanel.Visible = false
    end)
end

emojiToggle.MouseButton1Click:Connect(function()
    tweenProperty(emojiScale, {Scale = 0.9}, 0.05)
    task.delay(0.07, function()
        tweenProperty(emojiScale, {Scale = 1}, 0.12, Enum.EasingStyle.Back)
    end)
    colorPanel.Visible = false
    remoteEmoji.panel.Visible = false
    if customColorPanel and customColorPanel.Visible then
        customColorPanel.Visible = false
    end
    if fontColorPanel and fontColorPanel.Visible then
        fontColorPanel.Visible = false
    end
    emojiPanel.Visible = not emojiPanel.Visible
end)

colorToggle.MouseButton1Click:Connect(function()
    tweenProperty(colorScale, {Scale = 0.9}, 0.05)
    task.delay(0.07, function()
        tweenProperty(colorScale, {Scale = 1}, 0.12, Enum.EasingStyle.Back)
    end)
    emojiPanel.Visible = false
    remoteEmoji.panel.Visible = false
    if customColorPanel and customColorPanel.Visible then
        customColorPanel.Visible = false
    end
    if fontColorPanel and fontColorPanel.Visible then
        fontColorPanel.Visible = false
    end
    colorPanel.Visible = not colorPanel.Visible
end)

local loginParticles = spawnParticlesInFrame(loginParticleLayer, 230, 260)
local loginLinePool = {}
local chatParticles = spawnParticlesInFrame(chatParticleLayer, 340, 350)
local chatLinePool = {}

local particleConnection
particleConnection = RunService.RenderStepped:Connect(function()
    if loginPanel.Visible then
        updateParticlesInFrame(loginParticles, 230, 260)
        updateLines(loginParticles, loginLineLayer, loginLinePool)
    end
    if chatPanel.Visible then
        updateParticlesInFrame(chatParticles, 340, 350)
        updateLines(chatParticles, chatLineLayer, chatLinePool)
    end
end)

local function addMessageToUI(msg, name, time, isSelf, animate, bubbleColor, bubbleBorderId, fromServer, avatarBorderId)
    messageCount = messageCount + 1
    local container = createMessageBubble(messageArea, msg, name, time, isSelf, messageCount, animate, bubbleColor, bubbleBorderId, avatarBorderId, gui)
    if fromServer and not isSystemName(name) and type(msg) == "string" and type(name) == "string" and type(time) == "string" then
        messageUiByKey[time .. name .. msg] = container
    end
    if animate ~= false then
        task.wait(0.05)
        messageArea.CanvasPosition = Vector2.new(0, math.max(0, messageArea.AbsoluteCanvasSize.Y - messageArea.AbsoluteSize.Y))
    end
    return container
end

local function parseMessageTime(timeStr)
    if type(timeStr) ~= "string" then
        return nil
    end
    local year, month, day, hour, min, sec = timeStr:match("(%d+)%-(%d+)%-(%d+)%s+(%d+):(%d+):(%d+)")
    if year and month and day and hour and min and sec then
        return os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour), min = tonumber(min), sec = tonumber(sec)})
    end
    local hourOnly, minOnly, secOnly = timeStr:match("(%d+):(%d+):(%d+)")
    if hourOnly and minOnly and secOnly then
        local now = os.date("*t")
        local msgTime = os.time({year = now.year, month = now.month, day = now.day, hour = tonumber(hourOnly), min = tonumber(minOnly), sec = tonumber(secOnly)})
        if msgTime > os.time() then
            msgTime = msgTime - 86400
        end
        return msgTime
    end
    local hourSimple, minSimple = timeStr:match("(%d+):(%d+)")
    if hourSimple and minSimple then
        local now = os.date("*t")
        local msgTime = os.time({year = now.year, month = now.month, day = now.day, hour = tonumber(hourSimple), min = tonumber(minSimple), sec = 0})
        if msgTime > os.time() then
            msgTime = msgTime - 86400
        end
        return msgTime
    end
    return nil
end

local function findLatestServerMessageTime(messages, senderName, messageText)
    if type(messages) ~= "table" or type(senderName) ~= "string" or type(messageText) ~= "string" then
        return nil
    end
    local bestTimeStr = nil
    local bestTs = nil
    for _, m in ipairs(messages) do
        if type(m) == "table" and m.name == senderName and m.msg == messageText and type(m.time) == "string" then
            local ts = parseMessageTime(m.time) or 0
            if bestTs == nil or ts >= bestTs then
                bestTs = ts
                bestTimeStr = m.time
            end
        end
    end
    return bestTimeStr
end

local function processIncomingMessages(messages, animate)
    local now = os.time()
    local filterSeconds = currentTimeFilter * 3600
    for _, msg in ipairs(messages) do
        local msgKey = msg.time .. msg.name .. msg.msg
        if not messageCache[msgKey] then
            local msgTime = parseMessageTime(msg.time)
            local bubbleColor = nil
            local bubbleBorderId = nil
            local avatarBorderId = nil
            local colorStr = msg.color or msg.c
            if colorStr then
                bubbleColor = parseBubbleStyle(colorStr)
                if isAdminName(msg.name) then
                    bubbleBorderId = parseBubbleBorderId(colorStr)
                end
                avatarBorderId = parseAvatarBorderId(colorStr)
            end
            local handledControl = false
            if type(msg.msg) == "string" and msg.msg:sub(1, 11) == "##REVOKE##|" then
                local revokerIsSystem = isSystemName(msg.name)
                local revokerIsAdmin = isAdminName(msg.name)
                if revokerIsAdmin or revokerIsSystem then
                    local jsonText = msg.msg:sub(12)
                    local okPayload, payload = pcall(function()
                        return HttpService:JSONDecode(jsonText)
                    end)
                    if okPayload and type(payload) == "table" then
                        local targetName = payload.n or payload.targetName or payload.name
                        local targetTime = payload.t or payload.time
                        local targetMsg = payload.m or payload.msg
                        if targetName and targetTime and targetMsg then
                            local allowRevoke = true
                            if revokerIsAdmin and (not revokerIsSystem) and isAdminName(targetName) then
                                local revokerBase = normalizeAdminName(msg.name) or msg.name
                                local targetBase = normalizeAdminName(targetName) or targetName
                                if tostring(revokerBase) ~= tostring(targetBase) then
                                    allowRevoke = false
                                end
                            end
                            if allowRevoke then
                                local key = tostring(targetTime) .. tostring(targetName) .. tostring(targetMsg)
                                local container = messageUiByKey[key]
                                if container and container.Parent then
                                    container:Destroy()
                                end
                                messageUiByKey[key] = nil
                                pendingSelfMessages[msg.name .. "|" .. msg.msg] = nil
                                local sysName = SYSTEM_NAME
                                local displayTime = msg.time or os.date("%H:%M")
                                if msg.name == userName then
                                    local greenTarget = '<font color="rgb(80,255,120)">' .. tostring(targetName or "") .. "</font>"
                                    addMessageToUI("你撤回了成员" .. greenTarget .. "的一条消息", sysName, displayTime, false, true, SYSTEM_BUBBLE_COLOR, nil, false)
                                else
                                    addMessageToUI("管理员撤回了一条成员消息", sysName, displayTime, false, true, SYSTEM_BUBBLE_COLOR, nil, false)
                                end
                            end
                        end
                    end
                end
                messageCache[msgKey] = true
                handledControl = true
            end
            if type(msg.msg) == "string" and msg.msg:sub(1, 9) == "##MUTE##|" then
                local parts = {}
                for part in string.gmatch(msg.msg, "[^|]+") do
                    table.insert(parts, part)
                end
                if parts[1] == "##MUTE##" and parts[2] and parts[3] then
                    local targetName = parts[2]
                    local expireAt = tonumber(parts[3])
                    local reason = parts[4] or ""
                    local durationSeconds = tonumber(parts[5] or "")
                    local stage = tonumber(parts[6] or "")
                    if targetName and expireAt then
                        if not (reason == "violation" and isAdminName(targetName)) then
                            local issuerBase = normalizeAdminName(msg.name) or msg.name
                            local issuerIsCreator = isCreatorAdminName(issuerBase)
                            if expireAt > os.time() then
                                muteList[targetName] = expireAt
                                muteIssuer[targetName] = { by = issuerBase, creator = issuerIsCreator }
                            else
                                local existing = muteIssuer[targetName]
                                if existing and existing.creator and (not issuerIsCreator) then
                                    messageCache[msgKey] = true
                                    handledControl = true
                                    return
                                end
                                muteList[targetName] = nil
                                muteIssuer[targetName] = nil
                            end
                            if reason == "spam" or reason == "violation" then
                                local sysName = SYSTEM_NAME
                                local displayTime = msg.time or os.date("%H:%M")
                                local targetShow = '<font color="rgb(255,80,80)">' .. tostring(targetName or "") .. "</font>"
                                local text
                                if reason == "spam" then
                                    text = "由于" .. targetShow .. "刷屏，已被打入冷宫两分钟！"
                                else
                                    local durationText = formatMuteDuration(durationSeconds or (expireAt - os.time()))
                                    text = "由于" .. targetShow .. "检测到违禁词，已赏三个大B兜并禁言" .. durationText .. "！"
                                end
                                addMessageToUI(text, sysName, displayTime, false, true, SYSTEM_BUBBLE_COLOR, nil, false)
                            end
                        end
                    end
                end
                messageCache[msgKey] = true
                handledControl = true
            end
            if not handledControl then
                local passFilter = true
                if msgTime and currentTimeFilter > 0 then
                    passFilter = (now - msgTime) <= filterSeconds
                end
                if passFilter then
                    messageCache[msgKey] = true
                    local isSelf = msg.name == userName
                    local textForCheck = msg.msg
                    if type(textForCheck) == "string" then
                        textForCheck = (decodeMessageWithFont(textForCheck))
                    end
                    local isAtAll = type(textForCheck) == "string" and textForCheck:find("@全体", 1, true) ~= nil
                    local isMentionMe = false
                    local isReplyMe = false
                    if not isSelf and type(textForCheck) == "string" then
                        local baseSelfName = normalizeAdminName(userName) or userName
                        if baseSelfName and baseSelfName ~= "" then
                            local mentionTag = "@" .. baseSelfName
                            if textForCheck:find(mentionTag, 1, true) then
                                isMentionMe = true
                            end
                            local replyTarget = extractReplyTargetName(textForCheck)
                            if replyTarget and replyTarget == baseSelfName then
                                isReplyMe = true
                            end
                        end
                    end
                    local skipAddSelf = false
                    if isSelf and isAtAll and msgTime and sessionJoinTime and sessionJoinTime > 0 then
                        if msgTime >= sessionJoinTime then
                            local pendingKey = msg.name .. "|" .. msg.msg
                            pendingSelfMessages[pendingKey] = nil
                            skipAddSelf = true
                        end
                    end
                    if not skipAddSelf then
                        if isSelf then
                            local pendingKey = msg.name .. "|" .. msg.msg
                            local sentAt = pendingSelfMessages[pendingKey]
                            if sentAt and (os.time() - sentAt) <= selfMessageWindow then
                                pendingSelfMessages[pendingKey] = nil
                            else
                                addMessageToUI(msg.msg, msg.name, msg.time, true, animate, bubbleColor, bubbleBorderId, true, avatarBorderId)
                            end
                        else
                            addMessageToUI(msg.msg, msg.name, msg.time, false, animate, bubbleColor, bubbleBorderId, true, avatarBorderId)
                        end
                    end
                    if not isSelf then
                        if isAtAll and isAdminName(msg.name) then
                            local shouldNotify = true
                            if sessionJoinTime and sessionJoinTime > 0 and msgTime then
                                shouldNotify = msgTime >= sessionJoinTime
                            end
                            if shouldNotify then
                                needForceOpenAll = true
                            end
                        end
                        if isMinimized then
                            if isReplyMe and replyDot and not hasDmUnread then
                                hasReplyUnread = true
                                replyDot.Visible = true
                            end
                            if isMentionMe and mentionDot then
                                hasMentionUnread = true
                                mentionDot.Visible = true
                            end
                            if (not isMentionMe and not isReplyMe) and unreadDot then
                                hasUnread = true
                                unreadDot.Visible = true
                            end
                        end
                    end
                end
            end
        end
    end
end

local function syncRemovedServerMessages(messages)
    if type(messages) ~= "table" then
        return
    end
    local present = {}
    for _, m in ipairs(messages) do
        if type(m) == "table" then
            local t = m.time
            local n = m.name
            local s = m.msg
            if type(t) == "string" and type(n) == "string" and type(s) == "string" then
                present[t .. n .. s] = true
            end
        end
    end
    for key, container in pairs(messageUiByKey) do
        if not present[key] then
            if container and container.Parent then
                container:Destroy()
            end
            messageUiByKey[key] = nil
        end
    end
end

local function processIncomingDirectMessages(dms, animate)
    if type(dms) ~= "table" then
        return
    end
    if not dmInitialized then
        for _, dm in ipairs(dms) do
            local key = buildDmKey(dm)
            if key then
                dmCache[key] = true
            end
        end
        dmInitialized = true
        return
    end
    local baseSelfName = normalizeAdminName(userName) or userName
    for _, dm in ipairs(dms) do
        local key = buildDmKey(dm)
        if key and not dmCache[key] then
            dmCache[key] = true
            local fromName = tostring(dm["from"] or dm.f or "")
            local toName = tostring(dm["to"] or dm.to or "")
            local message = tostring(dm.msg or dm.m or "")
            local timeStr = tostring(dm.time or dm.t or os.date("%H:%M"))
            local fromBase = normalizeAdminName(fromName) or fromName
            local toBase = normalizeAdminName(toName) or toName
            local isSelfDm = fromBase ~= "" and baseSelfName ~= "" and fromBase == baseSelfName
            local visibleToMe = false
            if toBase ~= "" and baseSelfName ~= "" and toBase == baseSelfName then
                visibleToMe = true
            end
            if isSelfDm then
                visibleToMe = true
            end
            if visibleToMe then
                local skipAdd = false
                if isSelfDm then
                    local pendingKey = (toName ~= "" and (normalizeAdminName(toName) or toName) or "") .. "|" .. message
                    local sentAt = pendingSelfDms[pendingKey]
                    if sentAt and (os.time() - sentAt) <= selfDmWindow then
                        pendingSelfDms[pendingKey] = nil
                        skipAdd = true
                    end
                end
                if not skipAdd then
                    if not isSelfDm then
                        local text = "私信来自 " .. (fromName ~= "" and fromName or "未知") .. ": " .. message
                        addMessageToUI(text, fromName, timeStr, false, animate, nil, nil, false)
                    end
                    if not isSelfDm and isMinimized and dmDot then
                        hasDmUnread = true
                        dmDot.Visible = true
                        if replyDot then
                            replyDot.Visible = false
                        end
                    end
                end
            end
        end
    end
end

loadMessages = function(animate)
    local success, messages, errMessage = getMessages(currentRoom, API_KEY)
    if success and messages then
        syncRemovedServerMessages(messages)
        processIncomingMessages(messages, animate)
        local dmSuccess, dms = getDirectMessages(userName, API_KEY)
        if dmSuccess and dms then
            processIncomingDirectMessages(dms, animate)
        end
        if animate == false then
            task.defer(function()
                messageArea.CanvasPosition = Vector2.new(0, math.max(0, messageArea.AbsoluteCanvasSize.Y - messageArea.AbsoluteSize.Y))
            end)
        end
    elseif errMessage then
        createNotification(gui, errMessage, true)
    end
end

local function startPolling()
    isPolling = true
    task.spawn(function()
        while isPolling and currentRoom do
            task.wait(3)
            if not isPolling or not currentRoom then break end
            local success, messages, errMessage = getMessages(currentRoom, API_KEY)
            if success and messages then
                syncRemovedServerMessages(messages)
                processIncomingMessages(messages, true)
            end
            local dmSuccess, dms = getDirectMessages(userName, API_KEY)
            if dmSuccess and dms then
                processIncomingDirectMessages(dms, true)
            end
        end
    end)
end

local function stopPolling()
    isPolling = false
end

local function joinRoom()
    dmTargetName = nil
    pendingSelfDms = {}
    dmCache = {}
    dmInitialized = false
    if messageInput then
        messageInput.PlaceholderText = "输入消息..."
    end
    userName = getSelfChatName()
    API_KEY = FIXED_API_KEY
    local inputRoom = roomInput.Text
    if inputRoom == nil or inputRoom == "" then
        inputRoom = FIXED_ROOM
        roomInput.Text = FIXED_ROOM
    end
    if inputRoom == nil or inputRoom == "" then
        createNotification(gui, "请输入房间号", true)
        return
    end
    local exists, errMessage = checkRoomExists(inputRoom)
    if exists == nil then
        if errMessage and errMessage ~= "" then
            createNotification(gui, errMessage, true)
        else
            createNotification(gui, "获取房间列表失败", true)
        end
        return
    end
    if not exists then
        createNotification(gui, errMessage or "没有此房间", true)
        return
    end
    currentRoom = inputRoom
    sessionJoinTime = os.time()
    roomTitle.Text = "房间: " .. currentRoom
    if startMinimizedOnLoad then
        loginPanel.Visible = false
        chatPanel.Visible = true
        chatPanel.Position = UDim2.new(1.5, 0, 0.5, 0)
        isMinimized = true
        if minimizeButton then
            minimizeButton.Visible = true
        end
        createNotification(gui, "已加入: " .. currentRoom, false)
        loadMessages(false)
        startPolling()
        return
    end
    tweenProperty(loginPanel, {Position = UDim2.new(0.5, 0, 1.5, -30)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.25)
    loginPanel.Visible = false
    chatPanel.Visible = true
    chatPanel.Position = UDim2.new(0.5, 0, 1.5, -30)
    tweenProperty(chatPanel, {Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.35, Enum.EasingStyle.Back)
    createNotification(gui, "已加入: " .. currentRoom, false)
    loadMessages(false)
    startPolling()
end

task.spawn(function()
    local ok, text = getAnnouncement()
    if ok and type(text) == "string" then
        applyAnnouncement(text)
    end
end)

openRoomList = nil
function leaveRoom()
    stopPolling()
    dmTargetName = nil
    pendingSelfDms = {}
    dmCache = {}
    dmInitialized = false
    currentRoom = nil
    messageCache = {}
    messageUiByKey = {}
    messageCount = 0
    for _, child in ipairs(messageArea:GetChildren()) do
        if child:IsA("Frame") and child.Name == "MessageContainer" then
            child:Destroy()
        end
    end
    tweenProperty(chatPanel, {Position = UDim2.new(0.5, 0, 1.5, -30)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.25)
    chatPanel.Visible = false
    loginPanel.Visible = true
    loginPanel.Position = UDim2.new(0.5, 0, -0.5, -30)
    tweenProperty(loginPanel, {Position = UDim2.new(0.5, 0, 0.5, -30)}, 0.35, Enum.EasingStyle.Back)
end

function sendMessageAction()
    local now = os.time()
    local muteExpire = muteList[userName]
    if muteExpire and muteExpire > now then
        local remaining = muteExpire - now
        local minutes = math.floor(remaining / 60 + 0.5)
        local text = "你已被禁言"
        if minutes > 0 then
            text = text .. "，剩余约" .. tostring(minutes) .. "分钟"
        end
        createNotification(gui, text, true)
        return
    end
    if not isAdminName(userName) then
        if messageWindowStart == 0 or now - messageWindowStart >= 60 then
            messageWindowStart = now
            messageCountInWindow = 0
        end
        messageCountInWindow = messageCountInWindow + 1
        if messageCountInWindow >= SPAM_LIMIT then
            sendMuteCommand(userName, SPAM_MUTE_SECONDS, "spam")
            return
        end
    end
    local msg = messageInput.Text
    if msg == "" or not currentRoom then return end
    local msgToSend = encodeMessageWithFont(msg, selfFontColor)
    local isRevokeControl = type(msgToSend) == "string" and msgToSend:sub(1, 11) == "##REVOKE##|"
    if not isRevokeControl and not isAdminName(userName) then
        local hitWord = findForbiddenWord(msg)
        if hitWord then
            local offendingMsg = msgToSend
            messageInput.Text = ""
            local muteSeconds, stage = getViolationMuteSecondsForName(userName, now)
            task.spawn(function()
                local borderId = isAdminName(userName) and selfBubbleBorderId or 0
                local bubbleStr = buildBubblePayload(selfBubbleStyle, selfBubbleColor, borderId, selfAvatarBorderId)
                sendMessage(currentRoom, offendingMsg, userName, API_KEY, bubbleStr)
                task.wait(0.35)
                sendMuteCommand(userName, muteSeconds, "violation", { duration = muteSeconds, stage = stage })
                task.wait(0.25)
                local okList, messages = getMessages(currentRoom, API_KEY)
                if okList and messages then
                    local t = findLatestServerMessageTime(messages, userName, offendingMsg)
                    if t and t ~= "" then
                        revokeMessageRemote(currentRoom, userName, offendingMsg, t, SYSTEM_NAME)
                    end
                    local okList2, messages2 = getMessages(currentRoom, API_KEY)
                    if okList2 and messages2 then
                        syncRemovedServerMessages(messages2)
                        processIncomingMessages(messages2, true)
                    end
                end
            end)
            return
        end
    end
    if dmTargetName and dmTargetName ~= "" then
        local target = dmTargetName
        messageInput.Text = ""
        local baseTarget = normalizeDisplayNameForTarget(target) or target
        pendingSelfDms[baseTarget .. "|" .. msg] = os.time()
        local time = os.date("%H:%M")
        addMessageToUI("私信给 " .. tostring(target) .. ": " .. msg, userName, time, true, true, nil, nil, false)
        task.spawn(function()
            local ok, result = sendDirectMessage(baseTarget, msg, userName, API_KEY)
            if not ok then
                createNotification(gui, tostring(result or "私信发送失败"), true)
                return
            end
            dmTargetName = nil
            if messageInput then
                messageInput.PlaceholderText = "输入消息..."
            end
        end)
        return
    end
    if msg:find("@全体", 1, true) and not isAdminName(userName) then
        createNotification(gui, "只有管理员可以@全体成员", true)
        return
    end
    if randomColorEnabled then
        local c = getRandomColorFromPool()
        if c then
            selfBubbleColor = c
            selfBubbleStyle = c
            applyBubbleStyleToFrame(colorToggle, selfBubbleStyle)
            saveChatColorConfig()
        end
    end
    messageInput.Text = ""
    local time = os.date("%H:%M")
    if not isRevokeControl then
        local localBorderId = isAdminName(userName) and selfBubbleBorderId or nil
        addMessageToUI(msgToSend, userName, time, true, true, selfBubbleStyle, localBorderId, false, selfAvatarBorderId)
    end
    local pendingKey = userName .. "|" .. msgToSend
    pendingSelfMessages[pendingKey] = os.time()
    task.spawn(function()
        local borderId = isAdminName(userName) and selfBubbleBorderId or 0
        local bubbleStr = buildBubblePayload(selfBubbleStyle, selfBubbleColor, borderId, selfAvatarBorderId)
        local success, result = sendMessage(currentRoom, msgToSend, userName, API_KEY, bubbleStr)
        if not success then
            local errorText = result
            if errorText == nil or errorText == "" then
                errorText = "请求失败"
            else
                errorText = "请求失败: " .. tostring(errorText)
            end
            createNotification(gui, errorText, true)
            pendingSelfMessages[pendingKey] = nil
        end
        local recvSuccess, messages, errMessage = getMessages(currentRoom, API_KEY)
        if recvSuccess and messages then
            syncRemovedServerMessages(messages)
            processIncomingMessages(messages, true)
        end
    end)
end

joinButton.MouseButton1Click:Connect(joinRoom)
leaveButton.MouseButton1Click:Connect(leaveRoom)
sendButton.MouseButton1Click:Connect(sendMessageAction)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    if input.KeyCode ~= Enum.KeyCode.Return and input.KeyCode ~= Enum.KeyCode.KeypadEnter then
        return
    end
    local focusedTextBox
    local ok, tb = pcall(function()
        return UserInputService:GetFocusedTextBox()
    end)
    if ok then
        focusedTextBox = tb
    end
    if focusedTextBox ~= nil then
        return
    end
    if loginPanel and loginPanel.Visible then
        return
    end
    if chatPanel and not chatPanel.Visible then
        return
    end
    if not messageInput or not messageInput.Parent or not messageInput.Visible then
        return
    end
    messageInput:CaptureFocus()
    local t = messageInput.Text or ""
    messageInput.CursorPosition = #t + 1
end)
messageInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendMessageAction()
    end
end)

task.spawn(function()
    task.wait(0.5)
    if roomInput then
        roomInput.Text = FIXED_ROOM
    end
    joinRoom()
end)

function setupSmoothDrag(dragHandle, targetFrame)
    local dragging = false
    local dragStartPos = nil
    local frameStartPos = nil
    
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = targetFrame.Position
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end
    
    local function onInputChanged(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y
            local targetPos = UDim2.new(frameStartPos.X.Scale, newX, frameStartPos.Y.Scale, newY)
            tweenProperty(targetFrame, {Position = targetPos}, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
    
    dragHandle.InputBegan:Connect(onInputBegan)
    dragHandle.InputEnded:Connect(onInputEnded)
    UserInputService.InputChanged:Connect(onInputChanged)
    UserInputService.InputEnded:Connect(onInputEnded)
end

setupSmoothDrag(headerBar, chatPanel)
setupSmoothDrag(loginContent, loginPanel)

minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "MinimizeButton"
minimizeButton.Size = UDim2.new(0, 40, 0, 40)
minimizeButton.Position = UDim2.new(1, -42, 1, -42)
minimizeButton.BackgroundColor3 = softPurpleColor
minimizeButton.BorderSizePixel = 0
minimizeButton.Font = Enum.Font.SourceSans
minimizeButton.Text = "🗨️"
minimizeButton.TextSize = 20
minimizeButton.AutoButtonColor = false
minimizeButton.Visible = false
minimizeButton.ZIndex = 100
minimizeButton.Parent = gui
if startMinimizedOnLoad then
    minimizeButton.Visible = true
end

addUICorner(minimizeButton, UDim.new(1, 0))
addUIGradient(minimizeButton, softPurpleGradient, 68)
animateStrokeGradient(addButtonStroke(minimizeButton, 180, 0.35), 18)

unreadDot = Instance.new("Frame")
unreadDot.Name = "UnreadDot"
unreadDot.Size = UDim2.new(0, 10, 0, 10)
unreadDot.Position = UDim2.new(1, -8, 0, 8)
unreadDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
unreadDot.BorderSizePixel = 0
unreadDot.Visible = false
unreadDot.ZIndex = 101
unreadDot.Parent = minimizeButton
addUICorner(unreadDot, UDim.new(1, 0))

mentionDot = Instance.new("TextLabel")
mentionDot.Name = "MentionDot"
mentionDot.Size = UDim2.new(0, 40, 0, 18)
mentionDot.AnchorPoint = Vector2.new(0.5, 1)
mentionDot.Position = UDim2.new(0.5, 0, 1, -2)
mentionDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
mentionDot.BorderSizePixel = 0
mentionDot.Font = Enum.Font.GothamBold
mentionDot.Text = "有人@"
mentionDot.TextColor3 = Color3.new(1, 1, 1)
mentionDot.TextSize = 12
mentionDot.Visible = false
mentionDot.ZIndex = 101
mentionDot.Parent = minimizeButton
addUICorner(mentionDot, UDim.new(1, 0))

replyDot = Instance.new("TextLabel")
replyDot.Name = "ReplyDot"
replyDot.Size = UDim2.new(0, 36, 0, 18)
replyDot.AnchorPoint = Vector2.new(0.5, 0.5)
replyDot.Position = UDim2.new(0.5, 0, 0.5, 0)
replyDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
replyDot.BorderSizePixel = 0
replyDot.Font = Enum.Font.GothamBold
replyDot.Text = "回复"
replyDot.TextColor3 = Color3.new(1, 1, 1)
replyDot.TextSize = 12
replyDot.Visible = false
replyDot.ZIndex = 102
replyDot.Parent = minimizeButton
addUICorner(replyDot, UDim.new(1, 0))

dmDot = Instance.new("TextLabel")
dmDot.Name = "DmDot"
dmDot.Size = UDim2.new(0, 36, 0, 18)
dmDot.AnchorPoint = Vector2.new(0.5, 0.5)
dmDot.Position = UDim2.new(0.5, 0, 0.5, 0)
dmDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
dmDot.BorderSizePixel = 0
dmDot.Font = Enum.Font.GothamBold
dmDot.Text = "私信"
dmDot.TextColor3 = Color3.new(1, 1, 1)
dmDot.TextSize = 12
dmDot.Visible = false
dmDot.ZIndex = 103
dmDot.Parent = minimizeButton
addUICorner(dmDot, UDim.new(1, 0))

minimizeButton.MouseEnter:Connect(function()
    tweenProperty(minimizeButton, {Size = UDim2.new(0, 44, 0, 44)}, 0.15)
end)
minimizeButton.MouseLeave:Connect(function()
    tweenProperty(minimizeButton, {Size = UDim2.new(0, 40, 0, 40)}, 0.15)
end)

function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        if chatPanel.Visible then
            tweenProperty(chatPanel, {Position = UDim2.new(1.5, 0, 0.5, -30)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end
        if loginPanel.Visible then
            tweenProperty(loginPanel, {Position = UDim2.new(1.5, 0, 0.5, -30)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end
        if muteMenu and muteMenu.Visible then
            muteMenu.Visible = false
        end
        minimizeButton.Visible = true
    else
        minimizeButton.Visible = false
        if chatPanel.Visible then
            tweenProperty(chatPanel, {Position = UDim2.new(0.5, 0, 0.5, -10)}, 0.3, Enum.EasingStyle.Back)
        end
        if loginPanel.Visible then
            tweenProperty(loginPanel, {Position = UDim2.new(0.5, 0, 0.5, -30)}, 0.3, Enum.EasingStyle.Back)
        end
        hasUnread = false
        if unreadDot then
            unreadDot.Visible = false
        end
        hasMentionUnread = false
        if mentionDot then
            mentionDot.Visible = false
        end
        hasReplyUnread = false
        if replyDot then
            replyDot.Visible = false
        end
        hasDmUnread = false
        if dmDot then
            dmDot.Visible = false
        end
    end
end

if startMinimizedOnLoad then
    if not isMinimized then
        toggleMinimize()
    else
        minimizeButton.Visible = true
    end
end

foldButton.MouseButton1Click:Connect(toggleMinimize)
loginFoldButton.MouseButton1Click:Connect(toggleMinimize)

minimizeButton.MouseButton1Click:Connect(function()
    isMinimized = true
    toggleMinimize()
end)

function isPointInFrame(frame, point)
    if not frame or not frame.Visible then
        return false
    end
    local absPos = frame.AbsolutePosition
    local absSize = frame.AbsoluteSize
    local x = point.X
    local y = point.Y
    return x >= absPos.X and x <= absPos.X + absSize.X and y >= absPos.Y and y <= absPos.Y + absSize.Y
end

task.spawn(function()
    while true do
        if needForceOpenAll then
            needForceOpenAll = false
            if isMinimized then
                toggleMinimize()
            end
        end
        task.wait(0.1)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleMinimize()
    elseif input.KeyCode == Enum.KeyCode.H then
        if isMinimized then
            toggleMinimize()
        elseif chatPanel.Visible and messageInput then
            messageInput:CaptureFocus()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local pos = input.Position
        if not isMinimized and (chatPanel.Visible or loginPanel.Visible) then
            if not (isPointInFrame(chatPanel, pos) or isPointInFrame(loginPanel, pos) or isPointInFrame(minimizeButton, pos)) then
                toggleMinimize()
            end
        end
        if emojiPanel.Visible or colorPanel.Visible or remoteEmoji.panel.Visible or (customColorPanel and customColorPanel.Visible) or (fontColorPanel and fontColorPanel.Visible) or (bubblePalettePanel and bubblePalettePanel.Visible) or (dynamicBubblePanel and dynamicBubblePanel.Visible) or (bubbleBorderPanel and bubbleBorderPanel.Visible) or (avatarBorderPanel and avatarBorderPanel.Visible) or (avatarBorderSolidPanel and avatarBorderSolidPanel.Visible) or (avatarBorderQuickPanel and avatarBorderQuickPanel.Visible) then
            local insideEmoji = isPointInFrame(emojiPanel, pos) or isPointInFrame(emojiToggle, pos)
            local insideColor = isPointInFrame(colorPanel, pos) or isPointInFrame(colorPickerContainer, pos)
            local insideRemote = isPointInFrame(remoteEmoji.panel, pos) or isPointInFrame(remoteEmoji.button, pos)
            local insideCustom = customColorPanel and isPointInFrame(customColorPanel, pos)
            local insideFont = fontColorPanel and isPointInFrame(fontColorPanel, pos)
            local insideBubblePalette = bubblePalettePanel and isPointInFrame(bubblePalettePanel, pos)
            local insideDynamic = dynamicBubblePanel and isPointInFrame(dynamicBubblePanel, pos)
            local insideBubbleBorder = bubbleBorderPanel and isPointInFrame(bubbleBorderPanel, pos)
            local insideAvatarBorder = avatarBorderPanel and isPointInFrame(avatarBorderPanel, pos)
            local insideAvatarSolid = avatarBorderSolidPanel and isPointInFrame(avatarBorderSolidPanel, pos)
            local insideAvatarQuick = avatarBorderQuickPanel and isPointInFrame(avatarBorderQuickPanel, pos)
            if emojiPanel.Visible and not insideEmoji then
                emojiPanel.Visible = false
            end
            if colorPanel.Visible and not insideColor then
                colorPanel.Visible = false
            end
            if remoteEmoji.panel.Visible and not insideRemote then
                remoteEmoji.panel.Visible = false
            end
            if customColorPanel and customColorPanel.Visible and not insideCustom then
                customColorPanel.Visible = false
            end
            if fontColorPanel and fontColorPanel.Visible and not insideFont then
                fontColorPanel.Visible = false
            end
            if bubblePalettePanel and bubblePalettePanel.Visible and not insideBubblePalette then
                bubblePalettePanel.Visible = false
            end
            if dynamicBubblePanel and dynamicBubblePanel.Visible and not insideDynamic then
                dynamicBubblePanel.Visible = false
            end
            if bubbleBorderPanel and bubbleBorderPanel.Visible and not insideBubbleBorder then
                bubbleBorderPanel.Visible = false
            end
            if avatarBorderPanel and avatarBorderPanel.Visible and not insideAvatarBorder then
                avatarBorderPanel.Visible = false
            end
            if avatarBorderSolidPanel and avatarBorderSolidPanel.Visible and not insideAvatarSolid then
                avatarBorderSolidPanel.Visible = false
            end
            if avatarBorderQuickPanel and avatarBorderQuickPanel.Visible and not insideAvatarQuick then
                avatarBorderQuickPanel.Visible = false
            end
        end
    end
end)

task.spawn(function()
    while true do
        if statusIndicator and statusIndicator.Parent then
            tweenProperty(statusIndicator, {BackgroundTransparency = 0.4}, 0.6)
            task.wait(0.6)
            tweenProperty(statusIndicator, {BackgroundTransparency = 0}, 0.6)
            task.wait(0.6)
        else
            break
        end
    end
end)

print("成功")
