-- Dropdown ClickGUI - Premium Java Style with Full Aimbot

-- [[ SETTINGS ]]
if not getgenv then
    getgenv = function() return _G end
end

getgenv().aim_settings = {
    enabled = false,
    fov = 150,
    hitbox = "Head",
    priority = "Distance",
    lock_player = false,
    wall_check = false,
    target_esp = false,
    target_esp_mode = "Crosshair",
    target_hud = false,
    esp_enabled = false,
    esp_mode = "White",
    friend_markers = false,
    arrows = false,
    arrows_radius = 60,
    arrows_size = 18,
    rainbow_fov = false,
    rainbow_crosshair = false,
    prediction_enabled = false,
    prediction_amount = 0.13,
    smooth_enabled = false,
    smooth_amount = 0.1,
    noise_enabled = false,
    noise_amount = 0.1,
    toggle_key = Enum.KeyCode.X,
    ui_bind = Enum.KeyCode.RightControl,
    click_action = false,
    click_action_key = Enum.KeyCode.LeftControl,
    running = true,
    speed_display = false,
    esp_chams = false,
    fullbright = false,
    always_day = false,
    unload_script = false,
    hud_enabled = false,
    watermark_enabled = false,
    client_color = Color3.fromRGB(200, 50, 50), -- Цвет клиента
    keybind_list_enabled = false,
    jump_circle_enabled = false,
    jump_circle_speed = 0.5,
    jump_circle_size = 2.0,
    clickgui_enabled = true,
    clickgui_blur = true,
    clickgui_darken = true,
    clickgui_image = true,
    clickgui_image_mode = "Vanilla",
    trollface_animate = false,
    trollface_music = false,
    trollface_volume = 0.5,
    china_hat = false,
    cosmetic_enabled = false,
    hide_in_first_person = true,
    china_hat_friends = false,
    clickgui_bind = Enum.KeyCode.RightControl,
    hotkeys = {},
    friends = {},
    -- Hitboxes settings
    hitboxes_enabled = false,
    hitboxes_visualization = false,
    hitboxes_part = "Head",
    hitboxes_size = 15.0,
    hitboxes_transparency = 0.7,
    hitboxes_color = Color3.fromRGB(0, 170, 255),
    -- Chat settings
    chat_enabled = false,
    -- Config settings
    config_manager_open = false,
    config_name = "",
    -- Aimbot activation settings
    aim_activation = "RMB", -- "RMB", "LMB", "Auto"
    -- TP Walk settings
    tp_walk_enabled = false,
    tp_walk_speed = 5,
}

-- [[ SERVICES ]]
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [[ UTILITY FUNCTIONS ]]
local function tween(obj, props, time)
    local tw = TweenService:Create(obj, TweenInfo.new(time or 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

-- [[ AIMBOT VARIABLES ]]
local LockedTarget = nil
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 2
FOVCircle.Transparency = 1
FOVCircle.Visible = true
local lastAimbotCFrame = nil

-- [[ CHINA HAT VARIABLES ]]
local chinaHat = nil
local chinaHatGradientLayers = {}
local lastCameraMode = nil -- Для стабилизации переключений
local friendsChinaHats = {} -- Хранит China Hat для друзей

-- [[ HITBOXES VARIABLES ]] - Удалены, новая система не требует хранения

-- [[ COLORS & THEME ]]
local THEME = {
    PANEL_BG = Color3.fromRGB(18, 18, 22),
    PANEL_STROKE = Color3.fromRGB(35, 35, 42),
    MODULE_BG = Color3.fromRGB(28, 28, 35),
    MODULE_STROKE = Color3.fromRGB(45, 45, 55),
    TEXT_TITLE = Color3.fromRGB(255, 255, 255),
    TEXT_DIM = Color3.fromRGB(160, 160, 170),
    KNOB = Color3.fromRGB(255, 255, 255),
    GREEN_CHECK = Color3.fromRGB(90, 210, 120),
    RED_CROSS = Color3.fromRGB(235, 85, 85),
    BIND_BG = Color3.fromRGB(22, 22, 28),
}

-- Функция для получения актуального цвета клиента
local function getClientColor()
    return getgenv().aim_settings.client_color
end

-- Переменная для отслеживания последнего цвета клиента
local lastClientColor = getClientColor()
local uiRefreshers = {}
local targetHudStroke, targetHudGlow, TargetHudAccent, avatarStroke, TargetMetaLabel

local function registerUIRefresher(callback)
    table.insert(uiRefreshers, callback)
    return callback
end

local function cloneHotkeys(source)
    local cloned = {}
    local function normalizeKeyCode(value)
        if typeof(value) == "EnumItem" then
            return value
        end

        if type(value) == "string" then
            local keyName = value:match("^Enum%.KeyCode%.(.+)$") or value
            return Enum.KeyCode[keyName] or Enum.KeyCode.Unknown
        end

        if type(value) == "table" and value.__type == "EnumItem" then
            local enumTypeName = tostring(value.enumType or ""):match("^Enum%.(.+)$")
            local enumObject = enumTypeName and Enum[enumTypeName]
            return (enumObject and enumObject[value.name]) or Enum.KeyCode.Unknown
        end

        return Enum.KeyCode.Unknown
    end

    for key, value in pairs(source or {}) do
        local normalized = normalizeKeyCode(value)
        if normalized ~= Enum.KeyCode.Unknown then
            cloned[key] = normalized
        end
    end
    return cloned
end

local function tintColor(color, multiplier, add)
    add = add or 0
    return Color3.new(
        math.clamp(color.R * multiplier + add, 0, 1),
        math.clamp(color.G * multiplier + add, 0, 1),
        math.clamp(color.B * multiplier + add, 0, 1)
    )
end

local function getHeadshotImage(userId)
    local ok, content = pcall(function()
        return Players:GetUserThumbnailAsync(
            userId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    
    if ok and content then
        return content
    end
    
    return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=420&h=420"
end

local function refreshUIFromSettings()
    for _, refresher in ipairs(uiRefreshers) do
        refresher()
    end
end

-- Функция для обновления всех цветов в интерфейсе
local function updateAllColors()
    local clientColor = getClientColor()
    refreshUIFromSettings()
    
    -- Обновляем цвета модулей
    for _, panel in ipairs(panels or {}) do
        for _, module in ipairs(panel.modules or {}) do
            if getgenv().aim_settings[module.settingKey] then
                module.btn.BackgroundColor3 = clientColor
            end
        end
    end
    
    -- Обновляем FOV Circle
    if FOVCircle then
        FOVCircle.Color = clientColor
    end
    
    -- Обновляем HP Bar градиент
    if HPBarGradient and updateHPBarGradient then
        updateHPBarGradient()
    end
    if TargetHudAccent then
        TargetHudAccent.BackgroundColor3 = clientColor
    end
    if TargetMetaLabel then
        TargetMetaLabel.TextColor3 = THEME.TEXT_DIM
    end
    
    -- Обновляем China Hat цвета
    if chinaHat then
        chinaHat.Color = clientColor
    end
    
    for _, hatData in pairs(friendsChinaHats or {}) do
        if hatData.hat then
            hatData.hat.Color = clientColor
        end
        for i, layer in ipairs(hatData.layers or {}) do
            if layer then
                if i == 1 then
                    layer.Color = Color3.new(
                        math.max(clientColor.R * 0.75, 0),
                        math.max(clientColor.G * 0.75, 0),
                        math.max(clientColor.B * 0.75, 0)
                    )
                elseif i == 2 then
                    layer.Color = clientColor
                else
                    layer.Color = Color3.new(
                        math.min(clientColor.R * 1.25, 1),
                        math.min(clientColor.G * 1.25, 1),
                        math.min(clientColor.B * 1.25, 1)
                    )
                end
            end
        end
    end
    
    -- Обновляем градиентные слои локального China Hat
    for i, layer in ipairs(chinaHatGradientLayers or {}) do
        if layer then
            if i == 1 then
                layer.Color = Color3.new(
                    math.max(clientColor.R * 0.75, 0),
                    math.max(clientColor.G * 0.75, 0),
                    math.max(clientColor.B * 0.75, 0)
                )
            elseif i == 2 then
                layer.Color = clientColor
            else
                layer.Color = Color3.new(
                    math.min(clientColor.R * 1.25, 1),
                    math.min(clientColor.G * 1.25, 1),
                    math.min(clientColor.B * 1.25, 1)
                )
            end
        end
    end
    
    -- Обновляем последний цвет
    lastClientColor = clientColor
    
    -- Обновляем цвета хитбоксов (новая система применяет цвет автоматически)
    -- Цвет будет применен при следующем обновлении updateHitboxes()
    
    -- Обновляем цвета чата
    if ChatSendBtn then
        ChatSendBtn.BackgroundColor3 = clientColor
    end
    
    -- Обновляем последний цвет
    lastClientColor = clientColor
end

local ICONS = {
    Combat = "rbxassetid://10709818534",
    Movement = "rbxassetid://10709768538",
    Visuals = "rbxassetid://10723346959",
    Misc = "rbxassetid://10709810948",
    Config = "rbxassetid://10723374641"
}

-- [[ GUI CREATION ]]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
ScreenGui.Name = "PremiumClickGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 100 -- Высокий приоритет отображения

-- Background Blur Effect
local BlurEffect = Instance.new("BlurEffect", game:GetService("Lighting"))
BlurEffect.Name = "ClickGuiBlur"
BlurEffect.Size = 0
BlurEffect.Enabled = false

-- Отдельный ScreenGui для затемнения (покрывает весь экран)
local DarkenScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
DarkenScreenGui.Name = "PremiumClickGUI_Darken"
DarkenScreenGui.ResetOnSpawn = false
DarkenScreenGui.IgnoreGuiInset = true
DarkenScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DarkenScreenGui.DisplayOrder = -100 -- Очень низкий приоритет отображения

-- Background Darken Frame
local DarkenFrame = Instance.new("Frame", DarkenScreenGui)
DarkenFrame.Name = "DarkenBackground"
DarkenFrame.Size = UDim2.new(1, 0, 1, 0)
DarkenFrame.Position = UDim2.new(0, 0, 0, 0)
DarkenFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DarkenFrame.BackgroundTransparency = 1
DarkenFrame.BorderSizePixel = 0
DarkenFrame.ZIndex = -100 -- Очень низкий ZIndex чтобы быть позади всех GUI
DarkenFrame.Visible = false

-- ClickGui Image в правом нижнем углу
local ClickGuiImage = Instance.new("ImageLabel", ScreenGui)
ClickGuiImage.Name = "ClickGuiImage"
ClickGuiImage.Size = UDim2.new(0, 280, 0, 400) -- Увеличенный размер (пропорции 7:10)
ClickGuiImage.Position = UDim2.new(1, -300, 1, -390) -- Правый нижний угол, ниже (отступ 10px снизу)
ClickGuiImage.AnchorPoint = Vector2.new(0, 0)
ClickGuiImage.BackgroundTransparency = 1
ClickGuiImage.Image = "http://www.roblox.com/asset/?id=7331776981" -- По умолчанию Vanilla
ClickGuiImage.ImageTransparency = 1 -- Начинаем невидимым
ClickGuiImage.ScaleType = Enum.ScaleType.Fit
ClickGuiImage.Visible = false

-- Добавляем UICorner для скругления углов
Instance.new("UICorner", ClickGuiImage).CornerRadius = UDim.new(0, 12)

-- Устанавливаем IgnoreGuiInset для ScreenGui чтобы затемнение покрывало весь экран
ScreenGui.IgnoreGuiInset = true

-- Отдельный ScreenGui для HUD элементов (не скрывается с основным меню)
local HudScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
HudScreenGui.Name = "PremiumHUD"
HudScreenGui.ResetOnSpawn = false
HudScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HudScreenGui.DisplayOrder = 50 -- Средний приоритет

-- [[ MESSENGER VARIABLES ]] - УДАЛЕНО, заменено на простой чат в основном меню

-- API данные для JSONBin
local JSONBIN_CONFIG = {
    masterKey = "$2a$10$U6bla5mf3k3c1E9QPBCYuOP02OHKgT4ZNsZpXlIcJ969qf7zA.0Wu",
    accessKey = "$2a$10$.pcZ3pqlRmdcPA3gnYgRX.yJIv02FHpqy.tbe7P5TiteZdyrysFzy",
    binId = "69d5965c36566621a88bb8a0",
    baseUrl = "https://api.jsonbin.io/v3/b/"
}

-- Функция для HTTP запросов через эксплоит
local function makeHttpRequest(method, url, headers, body)
    local success, result = pcall(function()
        if method == "GET" then
            return {
                Success = true,
                Body = request({
                    Url = url,
                    Method = "GET",
                    Headers = headers
                }).Body
            }
        elseif method == "PUT" then
            return {
                Success = true,
                Body = request({
                    Url = url,
                    Method = "PUT",
                    Headers = headers,
                    Body = body
                }).Body
            }
        end
    end)
    
    if success and result.Success then
        return result.Body
    else
        warn("HTTP Request failed:", result)
        return nil
    end
end

-- Кэш для сообщений
local messagesCache = {}
local lastFetchTime = 0
local cacheTimeout = 2 -- Кэш на 2 секунды

-- Функция для получения сообщений с сервера
local function fetchMessages()
    -- Используем кэш если прошло меньше 2 секунд
    local currentTime = tick()
    if currentTime - lastFetchTime < cacheTimeout and #messagesCache > 0 then
        return messagesCache
    end
    
    local headers = {
        ["X-Master-Key"] = JSONBIN_CONFIG.masterKey,
        ["X-Access-Key"] = JSONBIN_CONFIG.accessKey
    }
    
    local url = JSONBIN_CONFIG.baseUrl .. JSONBIN_CONFIG.binId .. "/latest"
    local response = makeHttpRequest("GET", url, headers)
    
    if response then
        local success, data = pcall(function()
            -- Используем HttpService только для JSON декодирования
            local HttpService = game:GetService("HttpService")
            return HttpService:JSONDecode(response)
        end)
        
        if success and data and data.record and data.record.messages then
            messagesCache = data.record.messages
            lastFetchTime = currentTime
            return messagesCache
        else
            warn("Failed to parse messages:", data)
        end
    else
        warn("Failed to fetch messages from server")
    end
    
    -- Возвращаем кэш если запрос не удался
    return messagesCache or {}
end

-- Функция для отправки сообщения на сервер
local function sendMessage(message)
    if not message or message:gsub("%s", "") == "" then return end
    
    local messages = fetchMessages()
    
    -- Добавляем новое сообщение
    local newMessage = {
        userid = LocalPlayer.UserId,
        username = LocalPlayer.Name,
        message = message,
        timestamp = os.time(),
        chat = "global"
    }
    
    table.insert(messages, newMessage)
    
    -- Ограничиваем количество сообщений (последние 100)
    if #messages > 100 then
        local newMessages = {}
        for i = #messages - 99, #messages do
            table.insert(newMessages, messages[i])
        end
        messages = newMessages
    end
    
    -- Обновляем кэш
    messagesCache = messages
    lastFetchTime = tick()
    
    local data = {
        messages = messages
    }
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["X-Master-Key"] = JSONBIN_CONFIG.masterKey,
        ["X-Access-Key"] = JSONBIN_CONFIG.accessKey
    }
    
    local url = JSONBIN_CONFIG.baseUrl .. JSONBIN_CONFIG.binId
    -- Используем HttpService только для JSON кодирования
    local HttpService = game:GetService("HttpService")
    local body = HttpService:JSONEncode(data)
    
    local success = pcall(function()
        makeHttpRequest("PUT", url, headers, body)
    end)
    
    if not success then
        warn("Failed to send message to server")
    end
end

-- Target ESP будет создаваться динамически на игроке через BillboardGui
local targetRotation = 0
local rotationDirection = 1

-- Speed Display Label (в HudScreenGui)
local SpeedLabel = Instance.new("TextLabel", HudScreenGui)
SpeedLabel.Size = UDim2.new(0, 250, 0, 30)
SpeedLabel.Position = UDim2.new(0.5, -125, 0, 10)
SpeedLabel.Text = "Target Speed: N/A"
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SpeedLabel.BackgroundTransparency = 0.5
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 14
SpeedLabel.Visible = false
Instance.new("UICorner", SpeedLabel).CornerRadius = UDim.new(0, 8)

-- Horizontal Watermark (в HudScreenGui)
local WatermarkFrame = Instance.new("Frame", HudScreenGui)
WatermarkFrame.Name = "Watermark"
WatermarkFrame.Visible = false
WatermarkFrame.BorderSizePixel = 0
WatermarkFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
WatermarkFrame.Size = UDim2.new(0, 200, 0, 30)
WatermarkFrame.Position = UDim2.new(0, 10, 0, 10)
WatermarkFrame.BackgroundTransparency = 0.04

Instance.new("UICorner", WatermarkFrame).CornerRadius = UDim.new(0, 6)

-- Container для элементов
local watermarkContainer = Instance.new("Frame", WatermarkFrame)
watermarkContainer.Size = UDim2.new(1, -10, 1, 0)
watermarkContainer.Position = UDim2.new(0, 5, 0, 0)
watermarkContainer.Name = "Container"
watermarkContainer.BackgroundTransparency = 1

-- Layout для горизонтального расположения
local watermarkLayout = Instance.new("UIListLayout", watermarkContainer)
watermarkLayout.VerticalAlignment = Enum.VerticalAlignment.Center
watermarkLayout.SortOrder = Enum.SortOrder.LayoutOrder
watermarkLayout.FillDirection = Enum.FillDirection.Horizontal

-- Padding
local watermarkPadding = Instance.new("UIPadding", watermarkContainer)
watermarkPadding.PaddingRight = UDim.new(0, 8)
watermarkPadding.PaddingLeft = UDim.new(0, 8)

-- Client name с градиентом
local ClientLabel = Instance.new("TextLabel", watermarkContainer)
ClientLabel.TextSize = 14
ClientLabel.TextXAlignment = Enum.TextXAlignment.Left
ClientLabel.Font = Enum.Font.GothamBold
ClientLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ClientLabel.BackgroundTransparency = 1
ClientLabel.Size = UDim2.new(0, 0, 1, 0)
ClientLabel.Text = "moonware"
ClientLabel.AutomaticSize = Enum.AutomaticSize.X
ClientLabel.Name = "Client"
ClientLabel.LayoutOrder = 1

-- Градиент для client name
local clientGradient = Instance.new("UIGradient", ClientLabel)
clientGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0.000, 0.34375),
    NumberSequenceKeypoint.new(0.095, 0.2125),
    NumberSequenceKeypoint.new(0.166, 0.0625),
    NumberSequenceKeypoint.new(0.500, 0.06875),
    NumberSequenceKeypoint.new(0.754, 0.06875),
    NumberSequenceKeypoint.new(0.904, 0.21875),
    NumberSequenceKeypoint.new(1.000, 0.3125)
})

-- Разделитель 1
local Separator1 = Instance.new("TextLabel", watermarkContainer)
Separator1.TextSize = 14
Separator1.TextXAlignment = Enum.TextXAlignment.Left
Separator1.Font = Enum.Font.GothamBold
Separator1.TextColor3 = Color3.fromRGB(125, 125, 125)
Separator1.BackgroundTransparency = 1
Separator1.Size = UDim2.new(0, 0, 1, 0)
Separator1.Text = " · "
Separator1.AutomaticSize = Enum.AutomaticSize.X
Separator1.LayoutOrder = 2

-- Nickname
local NickLabel = Instance.new("TextLabel", watermarkContainer)
NickLabel.TextSize = 14
NickLabel.TextXAlignment = Enum.TextXAlignment.Left
NickLabel.Font = Enum.Font.GothamBold
NickLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
NickLabel.BackgroundTransparency = 1
NickLabel.Size = UDim2.new(0, 0, 1, 0)
NickLabel.Text = LocalPlayer.Name
NickLabel.AutomaticSize = Enum.AutomaticSize.X
NickLabel.Name = "Nick"
NickLabel.LayoutOrder = 3

-- Разделитель 2
local Separator2 = Instance.new("TextLabel", watermarkContainer)
Separator2.TextSize = 14
Separator2.TextXAlignment = Enum.TextXAlignment.Left
Separator2.Font = Enum.Font.GothamBold
Separator2.TextColor3 = Color3.fromRGB(125, 125, 125)
Separator2.BackgroundTransparency = 1
Separator2.Size = UDim2.new(0, 0, 1, 0)
Separator2.Text = " · "
Separator2.AutomaticSize = Enum.AutomaticSize.X
Separator2.LayoutOrder = 4

-- FPS Label
local FPSLabel = Instance.new("TextLabel", watermarkContainer)
FPSLabel.TextSize = 14
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Size = UDim2.new(0, 0, 1, 0)
FPSLabel.Text = "60fps"
FPSLabel.AutomaticSize = Enum.AutomaticSize.X
FPSLabel.Name = "FPS"
FPSLabel.LayoutOrder = 5

-- Разделитель 3
local Separator3 = Instance.new("TextLabel", watermarkContainer)
Separator3.TextSize = 14
Separator3.TextXAlignment = Enum.TextXAlignment.Left
Separator3.Font = Enum.Font.GothamBold
Separator3.TextColor3 = Color3.fromRGB(125, 125, 125)
Separator3.BackgroundTransparency = 1
Separator3.Size = UDim2.new(0, 0, 1, 0)
Separator3.Text = " · "
Separator3.AutomaticSize = Enum.AutomaticSize.X
Separator3.LayoutOrder = 6

-- Ping Label
local PingLabel = Instance.new("TextLabel", watermarkContainer)
PingLabel.TextSize = 14
PingLabel.TextXAlignment = Enum.TextXAlignment.Left
PingLabel.Font = Enum.Font.GothamBold
PingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PingLabel.BackgroundTransparency = 1
PingLabel.Size = UDim2.new(0, 0, 1, 0)
PingLabel.Text = "0ms"
PingLabel.AutomaticSize = Enum.AutomaticSize.X
PingLabel.Name = "Ping"
PingLabel.LayoutOrder = 7

-- Переменные для анимации watermark
local watermarkRotation = 0
local watermarkSmoothPing = 0

-- Переменные для обновления FPS/Ping раз в секунду
local lastUpdateTime = 0
local currentFPS = 60
local currentPing = 0
local displayFPS = 60
local displayPing = 0
local fpsAnimProgress = 1
local pingAnimProgress = 1

-- Функция для плавной анимации чисел (быстро в начале, медленно в конце)
local function easeOutQuart(t)
    return 1 - (1 - t) ^ 4
end

-- Функция для интерполяции чисел с анимацией
local function animateNumber(current, target, progress)
    if progress >= 1 then
        return target
    end
    local easedProgress = easeOutQuart(progress)
    return math.floor(current + (target - current) * easedProgress)
end

-- Keybind List (в HudScreenGui)
local KeybindList = Instance.new("Frame", HudScreenGui)
KeybindList.Size = UDim2.new(0, 180, 0, 40)
KeybindList.Position = UDim2.new(1, -190, 0, 10)
KeybindList.BackgroundColor3 = THEME.PANEL_BG
KeybindList.BorderSizePixel = 0
KeybindList.ClipsDescendants = true
KeybindList.Visible = false
Instance.new("UICorner", KeybindList).CornerRadius = UDim.new(0, 10)
local keybindStroke = Instance.new("UIStroke", KeybindList)
keybindStroke.Color = THEME.PANEL_STROKE
keybindStroke.Thickness = 1.5

local keybindTitle = Instance.new("TextLabel", KeybindList)
keybindTitle.Size = UDim2.new(1, 0, 0, 30)
keybindTitle.BackgroundTransparency = 1
keybindTitle.Text = "keybinds"
keybindTitle.TextColor3 = THEME.TEXT_TITLE
keybindTitle.Font = Enum.Font.GothamBold
keybindTitle.TextSize = 14
keybindTitle.LayoutOrder = 1

local keybindLayout = Instance.new("UIListLayout", KeybindList)
keybindLayout.SortOrder = Enum.SortOrder.LayoutOrder
keybindLayout.Padding = UDim.new(0, 4)
keybindLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local keybindSpacer = Instance.new("Frame", KeybindList)
keybindSpacer.Size = UDim2.new(1, -16, 0, 4)
keybindSpacer.BackgroundTransparency = 1
keybindSpacer.LayoutOrder = 2

local keybindDivider = Instance.new("Frame", keybindSpacer)
keybindDivider.Size = UDim2.new(1, 0, 0, 1)
keybindDivider.Position = UDim2.new(0, 0, 0.5, 0)
keybindDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
keybindDivider.BorderSizePixel = 0

local keybindDividerGradient = Instance.new("UIGradient", keybindDivider)
keybindDividerGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0.7),
    NumberSequenceKeypoint.new(1, 1)
})

local keybindItems = {}

-- Target HUD (в HudScreenGui)
local TargetHudFrame = Instance.new("Frame", HudScreenGui)
TargetHudFrame.Size = UDim2.new(0, 212, 0, 66)
TargetHudFrame.Position = UDim2.new(0.5, -106, 0.7, 0)
TargetHudFrame.BackgroundColor3 = THEME.PANEL_BG
TargetHudFrame.BackgroundTransparency = 0.12
TargetHudFrame.BorderSizePixel = 0
TargetHudFrame.Visible = false
TargetHudFrame.Active = true
local targetHudCorner = Instance.new("UICorner", TargetHudFrame)
targetHudCorner.CornerRadius = UDim.new(0, 10)

TargetHudAccent = Instance.new("Frame", TargetHudFrame)
TargetHudAccent.Size = UDim2.new(0, 0, 0, 0)
TargetHudAccent.BackgroundColor3 = getClientColor()
TargetHudAccent.BorderSizePixel = 0
Instance.new("UICorner", TargetHudAccent).CornerRadius = UDim.new(1, 0)

-- Dragging variables for TargetHud
local targetHudDragging = false
local targetHudDragStart = nil
local targetHudStartPos = nil

-- Avatar Container
local AvatarContainer = Instance.new("Frame", TargetHudFrame)
AvatarContainer.Size = UDim2.new(0, 34, 0, 34)
AvatarContainer.Position = UDim2.new(0, 8, 0, 8)
AvatarContainer.BackgroundTransparency = 1
AvatarContainer.BorderSizePixel = 0
AvatarContainer.ClipsDescendants = true
Instance.new("UICorner", AvatarContainer).CornerRadius = UDim.new(0, 4)

-- Avatar Image
local AvatarImage = Instance.new("ImageLabel", AvatarContainer)
AvatarImage.Size = UDim2.new(1, 0, 1, 0)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = ""
AvatarImage.ScaleType = Enum.ScaleType.Crop
local avatarImageCorner = Instance.new("UICorner", AvatarImage)
avatarImageCorner.CornerRadius = UDim.new(0, 4)

-- Info Container
local InfoContainer = Instance.new("Frame", TargetHudFrame)
InfoContainer.Size = UDim2.new(1, -54, 1, -14)
InfoContainer.Position = UDim2.new(0, 46, 0, 6)
InfoContainer.BackgroundTransparency = 1

-- Player Name
local TargetNameLabel = Instance.new("TextLabel", InfoContainer)
TargetNameLabel.Size = UDim2.new(1, 0, 0, 20)
TargetNameLabel.Position = UDim2.new(0, 0, 0, 2)
TargetNameLabel.BackgroundTransparency = 1
TargetNameLabel.Text = "moonware"
TargetNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetNameLabel.Font = Enum.Font.GothamBold
TargetNameLabel.TextSize = 13
TargetNameLabel.TextXAlignment = Enum.TextXAlignment.Left

TargetMetaLabel = Instance.new("TextLabel", InfoContainer)
TargetMetaLabel.Size = UDim2.new(1, 0, 0, 14)
TargetMetaLabel.Position = UDim2.new(0, 0, 0, 0)
TargetMetaLabel.BackgroundTransparency = 1
TargetMetaLabel.Text = ""
TargetMetaLabel.TextColor3 = THEME.TEXT_DIM
TargetMetaLabel.Font = Enum.Font.Gotham
TargetMetaLabel.TextSize = 10
TargetMetaLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetMetaLabel.Visible = false

-- HP Text
local TargetHPLabel = Instance.new("TextLabel", InfoContainer)
TargetHPLabel.Size = UDim2.new(1, 0, 0, 16)
TargetHPLabel.Position = UDim2.new(0, 0, 0, 18)
TargetHPLabel.BackgroundTransparency = 1
TargetHPLabel.Text = "HP: 100"
TargetHPLabel.TextColor3 = THEME.TEXT_DIM
TargetHPLabel.Font = Enum.Font.Gotham
TargetHPLabel.TextSize = 11
TargetHPLabel.TextXAlignment = Enum.TextXAlignment.Left

-- HP Bar Background
local HPBarBG = Instance.new("Frame", InfoContainer)
HPBarBG.Size = UDim2.new(1, -2, 0, 8)
HPBarBG.Position = UDim2.new(0, 0, 1, -10)
HPBarBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HPBarBG.BackgroundTransparency = 1
HPBarBG.BorderSizePixel = 0
local hpBarBGCorner = Instance.new("UICorner", HPBarBG)
hpBarBGCorner.CornerRadius = UDim.new(0, 3)

-- HP Bar Fill
local HPBarFill = Instance.new("Frame", HPBarBG)
HPBarFill.Size = UDim2.new(1, 0, 1, 0)
HPBarFill.BackgroundColor3 = getClientColor()
HPBarFill.BorderSizePixel = 0
local hpBarFillCorner = Instance.new("UICorner", HPBarFill)
hpBarFillCorner.CornerRadius = UDim.new(0, 3)

-- HP Bar Gradient (будет использовать цвета клиента)
local HPBarGradient = Instance.new("UIGradient", HPBarFill)
local function updateHPBarGradient()
    local clientColor = getClientColor()
    HPBarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, clientColor),
        ColorSequenceKeypoint.new(1, clientColor)
    })
    HPBarFill.BackgroundColor3 = clientColor
end
updateHPBarGradient()
HPBarGradient.Rotation = 0

-- TargetHud Drag Handler
TargetHudFrame.InputBegan:Connect(function(input)
    local guiVisible = (panelAnimationState == "showing" or panelAnimationState == "visible")
    if input.UserInputType == Enum.UserInputType.MouseButton1 and guiVisible then
        targetHudDragging = true
        local mousePos = UserInputService:GetMouseLocation()
        targetHudDragStart = Vector2.new(mousePos.X, mousePos.Y)
        targetHudStartPos = TargetHudFrame.Position
    end
end)

-- Arrows Container (в HudScreenGui)
local ArrowsContainer = Instance.new("Frame", HudScreenGui)
ArrowsContainer.Name = "ArrowsContainer"
ArrowsContainer.Size = UDim2.new(1, 0, 1, 0)
ArrowsContainer.BackgroundTransparency = 1
ArrowsContainer.Visible = false

local animationStep = 60
local targetAnimationStep = 60

-- Сохраняем оригинальные настройки освещения
local Lighting = game:GetService("Lighting")
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- Флаги для отслеживания состояния (чтобы не применять каждый кадр)
local fullbrightActive = false
local alwaysDayActive = false

-- Trollface animation variables
local trollfaceAnimationTime = 0
local trollfaceFlashTime = 0
local trollfaceShakeOffset = Vector2.new(0, 0)
local trollfaceOriginalPosition = nil
local trollfaceMusic = nil

-- Функция создания China Hat
local function createChinaHat(playerName, isLocalPlayer)
    local hatData = {
        hat = nil,
        layers = {},
        playerName = playerName
    }
    
    -- Основная часть China Hat
    hatData.hat = Instance.new("Part")
    hatData.hat.Name = isLocalPlayer and "ChinaHat" or ("ChinaHat_" .. playerName)
    hatData.hat.Size = Vector3.new(3.5, 0.8, 3.5)
    hatData.hat.Shape = Enum.PartType.Block
    hatData.hat.Material = Enum.Material.ForceField
    hatData.hat.Color = getClientColor()
    hatData.hat.CanCollide = false
    hatData.hat.Anchored = true
    hatData.hat.Parent = workspace
    hatData.hat.Transparency = 0.2
    
    local mesh = Instance.new("SpecialMesh", hatData.hat)
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1778999"
    mesh.Scale = Vector3.new(1.8, 0.6, 1.8)
    
    -- Создаем градиентные слои
    for i = 1, 3 do
        local layer = Instance.new("Part")
        layer.Name = isLocalPlayer and ("ChinaHatLayer" .. i) or ("ChinaHatLayer" .. i .. "_" .. playerName)
        layer.Size = Vector3.new(3.5, 0.8, 3.5)
        layer.Shape = Enum.PartType.Block
        layer.Material = Enum.Material.Neon
        layer.CanCollide = false
        layer.Anchored = true
        layer.Parent = workspace
        
        local layerMesh = Instance.new("SpecialMesh", layer)
        layerMesh.MeshType = Enum.MeshType.FileMesh
        layerMesh.MeshId = "rbxassetid://1778999"
        
        -- Градиентные цвета и размеры (используем цвета клиента)
        local clientColor = getClientColor()
        if i == 1 then
            layer.Color = Color3.new(
                math.max(clientColor.R * 0.75, 0),
                math.max(clientColor.G * 0.75, 0),
                math.max(clientColor.B * 0.75, 0)
            )
            layer.Transparency = 0.4
            layerMesh.Scale = Vector3.new(1.9, 0.65, 1.9)
        elseif i == 2 then
            layer.Color = clientColor
            layer.Transparency = 0.3
            layerMesh.Scale = Vector3.new(1.85, 0.62, 1.85)
        else
            layer.Color = Color3.new(
                math.min(clientColor.R * 1.25, 1),
                math.min(clientColor.G * 1.25, 1),
                math.min(clientColor.B * 1.25, 1)
            )
            layer.Transparency = 0.5
            layerMesh.Scale = Vector3.new(1.75, 0.58, 1.75)
        end
        
        table.insert(hatData.layers, layer)
    end
    
    return hatData
end

-- Функция обновления позиции China Hat
local function updateChinaHatPosition(hatData, head, shouldHide)
    if not hatData or not hatData.hat or not hatData.hat.Parent then return end
    
    if shouldHide then
        -- Скрываем
        hatData.hat.Transparency = 1
        for _, layer in ipairs(hatData.layers) do
            if layer and layer.Parent then
                layer.Transparency = 1
            end
        end
    else
        -- Показываем и обновляем позицию
        hatData.hat.Transparency = 0.2
        
        local basePosition = head.CFrame * CFrame.new(0, 0.9, 0)
        hatData.hat.CFrame = basePosition
        
        local time = tick()
        hatData.hat.CFrame = hatData.hat.CFrame * CFrame.Angles(0, math.rad(time * 20), 0)
        
        for i, layer in ipairs(hatData.layers) do
            if layer and layer.Parent then
                local rotationSpeed = 20 + (i * 5)
                layer.CFrame = basePosition * CFrame.Angles(0, math.rad(time * rotationSpeed), 0)
                
                local pulse = math.sin(time * 3 + i) * 0.1
                if i == 1 then
                    layer.Transparency = 0.4 + pulse
                elseif i == 2 then
                    layer.Transparency = 0.3 + pulse
                else
                    layer.Transparency = 0.5 + pulse
                end
            end
        end
    end
end

-- Функция удаления China Hat
local function destroyChinaHat(hatData)
    if not hatData then return end
    
    if hatData.hat then
        hatData.hat:Destroy()
    end
    
    for _, layer in ipairs(hatData.layers) do
        if layer then
            layer:Destroy()
        end
    end
end

-- [[ UTILS ]]
local ColorUtil = {}
function ColorUtil.getColorStyle(angle)
    local hue = (angle / 360) % 1
    return Color3.fromHSV(hue, 0.7, 1)
end

-- JumpCircle variables
local jumpCircles = {}
local lastJumpState = {}

local MODULE_NAMES = {
    enabled = "Aimbot",
    esp_enabled = "Player ESP",
    target_esp = "Target ESP",
    target_hud = "Target HUD",
    friend_markers = "Friend Markers",
    arrows = "Arrows",
    rainbow_fov = "Rainbow FOV",
    rainbow_crosshair = "Rainbow Crosshair",
    speed_display = "Speed Display",
    hud_enabled = "HUD",
    watermark_enabled = "Watermark",
    keybind_list_enabled = "Keybind List",
    jump_circle_enabled = "Jump Circle",
    cosmetic_enabled = "Cosmetic",
    china_hat = "China Hat",
    clickgui_enabled = "ClickGui",
    prediction_enabled = "Prediction",
    lock_player = "Lock Target",
    smooth_enabled = "Smooth",
    noise_enabled = "Noise",
    esp_chams = "Chams",
    click_action = "Friend Add/Rem",
    fullbright = "FullBright",
    always_day = "Always Day",
    unload_script = "Unload Script",
    hitboxes_enabled = "Hitboxes",
    tp_walk_enabled = "TP Walk"
}

local function getBindDisplayName(settingKey)
    local explicitName = MODULE_NAMES[settingKey]
    if explicitName and explicitName ~= "" then
        return explicitName
    end

    local spaced = tostring(settingKey or ""):gsub("_", " ")
    return (spaced:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

local function getKeyName(keyCode)
    if not keyCode or keyCode == Enum.KeyCode.Unknown then return "..." end
    local keyName = tostring(keyCode):gsub("Enum.KeyCode.", "")
    
    -- Сокращения для длинных названий клавиш
    local shortcuts = {
        ["LeftControl"] = "LCtrl",
        ["RightControl"] = "RCtrl",
        ["LeftShift"] = "LShift",
        ["RightShift"] = "RShift",
        ["LeftAlt"] = "LAlt",
        ["RightAlt"] = "RAlt",
        ["CapsLock"] = "Caps",
        ["BackSlash"] = "\\",
        ["Semicolon"] = ";",
        ["Quote"] = "'",
        ["LeftBracket"] = "[",
        ["RightBracket"] = "]",
        ["Comma"] = ",",
        ["Period"] = ".",
        ["Slash"] = "/",
        ["Minus"] = "-",
        ["Equals"] = "=",
        ["Backquote"] = "`",
        ["Backspace"] = "Bksp",
        ["Return"] = "Enter",
        ["Space"] = "Space",
        ["Tab"] = "Tab",
        ["Insert"] = "Ins",
        ["Delete"] = "Del",
        ["Home"] = "Home",
        ["End"] = "End",
        ["PageUp"] = "PgUp",
        ["PageDown"] = "PgDn"
    }
    
    return shortcuts[keyName] or keyName
end

-- [[ FRIEND SYSTEM ]]
local function isFriend(playerName)
    return table.find(getgenv().aim_settings.friends, playerName) ~= nil
end

local function toggleFriend(playerName)
    local index = table.find(getgenv().aim_settings.friends, playerName)
    if index then
        table.remove(getgenv().aim_settings.friends, index)
        return false, "Removed from friends"
    else
        table.insert(getgenv().aim_settings.friends, playerName)
        return true, "Added to friends"
    end
end

local function getPlayerFromMouse()
    local mouse = LocalPlayer:GetMouse()
    local target = mouse.Target
    
    if target and target.Parent then
        local character = target.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if player and player ~= LocalPlayer then
            return player
        end
    end
    return nil
end

-- [[ AIMBOT FUNCTIONS ]]
local function hasLineOfSight(targetPart)
    if not targetPart or not targetPart.Parent then
        return false
    end
    
    if not getgenv().aim_settings.wall_check then
        return true
    end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local ignoreList = {Camera}
    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isFriend(player.Name) then
            table.insert(ignoreList, player.Character)
        end
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.IgnoreWater = true
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    return not result or (result.Instance and result.Instance:IsDescendantOf(targetPart.Parent))
end

local function getClosest()
    local target = nil
    local bestValue = math.huge
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            -- Пропускаем друзей
            if isFriend(v.Name) then
                continue
            end
            
            local hum = v.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local part
                if getgenv().aim_settings.hitbox == "Head" then
                    part = v.Character:FindFirstChild("Head")
                elseif getgenv().aim_settings.hitbox == "Body" then
                    -- Исправляем хитбокс - сначала ищем UpperTorso (R15), потом Torso (R6)
                    part = v.Character:FindFirstChild("UpperTorso") or v.Character:FindFirstChild("Torso")
                else
                    -- Fallback на голову если хитбокс неизвестен
                    part = v.Character:FindFirstChild("Head")
                end
                
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 and hasLineOfSight(part) then
                        local distToCursor = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        -- Проверяем, находится ли игрок в FOV круге
                        if distToCursor <= getgenv().aim_settings.fov then
                            local compareValue
                            
                            -- Выбор приоритета
                            if getgenv().aim_settings.priority == "Free" then
                                -- Free - просто расстояние от курсора (ближайший к прицелу)
                                compareValue = distToCursor
                            elseif getgenv().aim_settings.priority == "Health" then
                                -- Чем меньше здоровье, тем лучше
                                compareValue = hum.Health
                            else
                                -- Distance - расстояние от игрока до цели в мире (3D)
                                local distToPlayer = (part.Position - Camera.CFrame.Position).Magnitude
                                compareValue = distToPlayer
                            end
                            
                            if compareValue < bestValue then
                                bestValue = compareValue
                                target = part
                            end
                        end
                    end
                end
            end
        end
    end
    
    return target
end

local function getPredictedPosition(part)
    if not part or not part.Parent then 
        return part and part.Position or Vector3.new(0, 0, 0)
    end
    
    -- Проверяем что часть все еще существует и имеет Velocity
    local success, velocity = pcall(function() return part.Velocity end)
    if not success then
        return part.Position
    end
    
    -- Уменьшаем базовый prediction в 2 раза для более медленного наведения
    local prediction = getgenv().aim_settings.prediction_amount * 0.5
    
    local character = part.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Freefall then
            -- При падении УВЕЛИЧИВАЕМ prediction (игрок быстро летит вниз)
            prediction = prediction * 3
        elseif state == Enum.HumanoidStateType.Jumping then
            -- При прыжке умеренный prediction
            prediction = prediction * 1.5
        end
    end
    
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = horizontalVelocity.Magnitude
    if speed > 0 then
        -- Уменьшаем влияние скорости
        local speedFactor = speed / 20 -- Было 16, стало 20 (медленнее)
        prediction = prediction * speedFactor
    end
    
    return part.Position + (velocity * prediction)
end

-- [[ TP WALK FUNCTION ]]
local tpwalkConnection = nil

local function updateTPWalk()
    if not getgenv().aim_settings.tp_walk_enabled then
        -- Отключаем если был включен
        if tpwalkConnection then
            tpwalkConnection:Disconnect()
            tpwalkConnection = nil
        end
        return
    end
    
    -- Если уже запущен, не создаем новое подключение
    if tpwalkConnection then
        return
    end
    
    -- Создаем новое подключение
    tpwalkConnection = RunService.Heartbeat:Connect(function(delta)
        if not getgenv().aim_settings.tp_walk_enabled then
            if tpwalkConnection then
                tpwalkConnection:Disconnect()
                tpwalkConnection = nil
            end
            return
        end
        
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
        
        if not (character and humanoid and humanoid.Parent) then
            return
        end
        
        if humanoid.MoveDirection.Magnitude > 0 then
            local speed = getgenv().aim_settings.tp_walk_speed
            local hrp = character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Сохраняем текущую позицию камеры относительно персонажа
                local cameraCFrame = Camera.CFrame
                local cameraOffset = cameraCFrame.Position - hrp.Position
                
                -- Двигаем персонажа
                character:TranslateBy(humanoid.MoveDirection * speed * delta * 10)
                
                -- Обновляем камеру чтобы она следовала за персонажем плавно
                Camera.CFrame = CFrame.new(hrp.Position + cameraOffset, hrp.Position + cameraOffset + cameraCFrame.LookVector)
            end
        end
    end)
end

function updateAimbotCamera()
    if not getgenv().aim_settings.running then
        return
    end

    -- Проверяем активацию в зависимости от режима
    local shouldAim = false
    if getgenv().aim_settings.enabled then
        local activationMode = getgenv().aim_settings.aim_activation or "RMB"
        
        if activationMode == "Auto" then
            shouldAim = true
        elseif activationMode == "RMB" then
            shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        elseif activationMode == "LMB" then
            shouldAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end
    end

    if not shouldAim then
        LockedTarget = nil
        lastAimbotCFrame = nil
        return
    end

    local function isTargetValid(target)
        if not target or not target.Parent then return false end
        local character = target.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        local player = Players:GetPlayerFromCharacter(character)
        if not player or isFriend(player.Name) then return false end
        if not hasLineOfSight(target) then return false end
        return true
    end

    if getgenv().aim_settings.lock_player then
        if not isTargetValid(LockedTarget) then
            LockedTarget = getClosest()
        end
    else
        LockedTarget = getClosest()
    end

    if not (LockedTarget and isTargetValid(LockedTarget)) then
        lastAimbotCFrame = nil
        return
    end

    local activeCamera = workspace.CurrentCamera or Camera
    if not activeCamera then
        return
    end

    local targetPos = getgenv().aim_settings.prediction_enabled and getPredictedPosition(LockedTarget) or LockedTarget.Position

    if getgenv().aim_settings.noise_enabled then
        local noiseAmount = getgenv().aim_settings.noise_amount
        local noiseX = (math.random() - 0.5) * noiseAmount * 2
        local noiseY = (math.random() - 0.5) * noiseAmount * 2
        local noiseZ = (math.random() - 0.5) * noiseAmount * 2
        targetPos = targetPos + Vector3.new(noiseX, noiseY, noiseZ)
    end

    if getgenv().aim_settings.smooth_enabled then
        -- Используем ТЕКУЩУЮ позицию камеры (чтобы следовать за персонажем)
        local currentPos = activeCamera.CFrame.Position
        
        -- Но направление берем из сохраненного CFrame (игнорируем движения мыши)
        local currentLook = lastAimbotCFrame and lastAimbotCFrame.LookVector or activeCamera.CFrame.LookVector
        local targetLook = (targetPos - currentPos).Unit
        
        -- Плавно интерполируем направление
        local smoothLook = currentLook:Lerp(targetLook, getgenv().aim_settings.smooth_amount)
        
        -- Создаем новый CFrame с текущей позицией и плавным направлением
        lastAimbotCFrame = CFrame.new(currentPos, currentPos + smoothLook)
        activeCamera.CFrame = lastAimbotCFrame
    else
        -- Без smooth - мгновенное наведение
        activeCamera.CFrame = CFrame.new(activeCamera.CFrame.Position, targetPos)
    end
end

-- [[ HITBOXES FUNCTIONS - NEW SYSTEM ]]
-- Функция для сброса хитбоксов головы
local function resetHeadHitboxes()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") then
            pcall(function()
                local head = v.Character.Head
                head.Size = Vector3.new(1, 1, 1)
                head.Transparency = 0
                head.CanCollide = true
                head.Anchored = false
                head.Massless = false
            end)
        end
    end
end

-- Функция для сброса хитбоксов тела
local function resetBodyHitboxes()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            pcall(function()
                local hrp = v.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
                hrp.CanCollide = true
            end)
        end
    end
end

-- Главная функция обновления хитбоксов
local function updateHitboxes()
    if not getgenv().aim_settings.hitboxes_enabled then
        resetHeadHitboxes()
        resetBodyHitboxes()
        return
    end
    
    local partName = getgenv().aim_settings.hitboxes_part
    local size = getgenv().aim_settings.hitboxes_size
    local transparency = getgenv().aim_settings.hitboxes_transparency
    local color = getgenv().aim_settings.hitboxes_color
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and not isFriend(v.Name) then
            if partName == "Head" and v.Character:FindFirstChild("Head") then
                pcall(function()
                    local head = v.Character.Head
                    head.Size = Vector3.new(size, size, size)
                    head.Transparency = transparency
                    head.Color = color
                    head.Material = Enum.Material.Neon
                    head.CanCollide = false
                    head.Anchored = false
                    head.Massless = true
                end)
            elseif partName == "Body" and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    local hrp = v.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(size, size, size)
                    hrp.Transparency = transparency
                    hrp.Color = color
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                end)
            end
        end
    end
end

-- [[ CATEGORY PANEL CLASS ]]
local CategoryPanel = {}
CategoryPanel.__index = CategoryPanel

function CategoryPanel.new(name, x, y, width)
    local self = setmetatable({}, CategoryPanel)
    self.name = name
    self.x = x
    self.y = y
    self.width = width
    self.modules = {}
    self.bindingModule = nil
    self.dragging = false
    self.dragStart = nil
    self.startPos = nil
    
    -- Main panel
    self.frame = Instance.new("Frame", ScreenGui)
    self.frame.Size = UDim2.new(0, width, 0, 40)
    self.frame.Position = UDim2.new(0, x, 0, y)
    self.frame.BackgroundColor3 = THEME.PANEL_BG
    self.frame.BorderSizePixel = 0
    self.frame.ClipsDescendants = true
    Instance.new("UICorner", self.frame).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", self.frame)
    stroke.Color = THEME.PANEL_STROKE
    stroke.Thickness = 1.5
    
    -- Header (draggable)
    local header = Instance.new("TextButton", self.frame)
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.Text = ""
    header.AutoButtonColor = false
    
    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = THEME.TEXT_TITLE
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local icon = Instance.new("ImageLabel", header)
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(1, -27, 0.5, -9)
    icon.BackgroundTransparency = 1
    icon.Image = ICONS[name] or ""
    icon.ImageColor3 = THEME.TEXT_DIM
    
    -- Drag functionality
    header.MouseButton1Down:Connect(function()
        self.dragging = true
        local mousePos = UserInputService:GetMouseLocation()
        self.dragStart = Vector2.new(mousePos.X, mousePos.Y)
        self.startPos = self.frame.Position
    end)
    -- Layout
    self.layout = Instance.new("UIListLayout", self.frame)
    self.layout.SortOrder = Enum.SortOrder.LayoutOrder
    self.layout.Padding = UDim.new(0, 6)
    self.layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    -- Spacer for top padding with gradient divider
    local topSpacer = Instance.new("Frame", self.frame)
    topSpacer.Size = UDim2.new(1, -16, 0, 4)
    topSpacer.BackgroundTransparency = 1
    topSpacer.LayoutOrder = 1
    
    local divider = Instance.new("Frame", topSpacer)
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0.5, 0)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BorderSizePixel = 0
    
    local gradient = Instance.new("UIGradient", divider)
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.7),
        NumberSequenceKeypoint.new(1, 1)
    })
    
    self.layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tween(self.frame, {Size = UDim2.new(0, self.width, 0, self.layout.AbsoluteContentSize.Y + 10)}, 0.3)
    end)
    
    return self
end

function CategoryPanel:update()
    if self.dragging then
        local mouse = UserInputService:GetMouseLocation()
        local delta = Vector2.new(mouse.X - self.dragStart.X, mouse.Y - self.dragStart.Y)
        self.frame.Position = UDim2.new(
            0,
            self.startPos.X.Offset + delta.X,
            0,
            self.startPos.Y.Offset + delta.Y
        )
    end
end

function CategoryPanel:addModule(moduleName, settingKey, hasSettings)
    local moduleData = {
        name = moduleName,
        settingKey = settingKey,
        expanded = false,
        settings = {},
        hasSettings = hasSettings
    }

    MODULE_NAMES[settingKey] = moduleName
    
    local container = Instance.new("Frame", self.frame)
    container.Size = UDim2.new(1, -16, 0, 34)
    container.BackgroundTransparency = 1
    container.ClipsDescendants = true
    container.LayoutOrder = #self.modules + 2
    
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = getgenv().aim_settings[settingKey] and getClientColor() or THEME.MODULE_BG
    btn.AutoButtonColor = false
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = THEME.MODULE_STROKE
    btnStroke.Thickness = 1
    
    local nameLbl = Instance.new("TextLabel", btn)
    nameLbl.Size = UDim2.new(1, -70, 1, 0)
    nameLbl.Position = UDim2.new(0, 12, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = moduleName
    nameLbl.TextColor3 = THEME.TEXT_TITLE
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 13
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local actions = Instance.new("Frame", btn)
    actions.Size = UDim2.new(0, 60, 1, 0)
    actions.Position = UDim2.new(1, -65, 0, 0)
    actions.BackgroundTransparency = 1
    
    local actLayout = Instance.new("UIListLayout", actions)
    actLayout.FillDirection = Enum.FillDirection.Horizontal
    actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    actLayout.Padding = UDim.new(0, 6)
    
    local bindBox = Instance.new("TextButton", actions)
    bindBox.Size = UDim2.new(0, 22, 0, 18)
    bindBox.BackgroundColor3 = THEME.BIND_BG
    bindBox.Text = "..."
    bindBox.TextColor3 = THEME.TEXT_DIM
    bindBox.Font = Enum.Font.Gotham
    bindBox.TextSize = 10
    bindBox.AutoButtonColor = false
    Instance.new("UICorner", bindBox).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", bindBox).Color = THEME.MODULE_STROKE
    
    -- Для ClickAction показываем текущую клавишу
    if settingKey == "click_action" then
        bindBox.Text = getKeyName(getgenv().aim_settings.click_action_key)
    elseif settingKey == "clickgui_enabled" then
        bindBox.Text = getKeyName(getgenv().aim_settings.clickgui_bind)
    end
    
    local arrowBox, arrowLbl
    if hasSettings then
        arrowBox = Instance.new("Frame", actions)
        arrowBox.Size = UDim2.new(0, 22, 0, 18)
        arrowBox.BackgroundColor3 = THEME.BIND_BG
        Instance.new("UICorner", arrowBox).CornerRadius = UDim.new(0, 4)
        Instance.new("UIStroke", arrowBox).Color = THEME.MODULE_STROKE
        
        arrowLbl = Instance.new("TextLabel", arrowBox)
        arrowLbl.Size = UDim2.new(1, 0, 1, 0)
        arrowLbl.BackgroundTransparency = 1
        arrowLbl.Text = "↘"
        arrowLbl.TextColor3 = THEME.TEXT_DIM
        arrowLbl.Font = Enum.Font.Gotham
        arrowLbl.TextSize = 12
    end
    
    local settingsList = Instance.new("Frame", container)
    settingsList.Size = UDim2.new(1, 0, 1, -34)
    settingsList.Position = UDim2.new(0, 0, 0, 34)
    settingsList.BackgroundTransparency = 1
    
    local setListLayout = Instance.new("UIListLayout", settingsList)
    setListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    moduleData.container = container
    moduleData.btn = btn
    moduleData.arrowLbl = arrowLbl
    moduleData.bindBox = bindBox
    moduleData.settingsList = settingsList
    moduleData.setListLayout = setListLayout

    registerUIRefresher(function()
        btn.BackgroundColor3 = getgenv().aim_settings[settingKey] and getClientColor() or THEME.MODULE_BG

        if settingKey == "click_action" then
            bindBox.Text = getKeyName(getgenv().aim_settings.click_action_key)
        elseif settingKey == "clickgui_enabled" then
            bindBox.Text = getKeyName(getgenv().aim_settings.clickgui_bind)
        else
            bindBox.Text = getKeyName(getgenv().aim_settings.hotkeys[settingKey])
        end

        if self.bindingModule ~= moduleData then
            bindBox.BackgroundColor3 = THEME.BIND_BG
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        local state = not getgenv().aim_settings[settingKey]
        getgenv().aim_settings[settingKey] = state
        tween(btn, {BackgroundColor3 = state and getClientColor() or THEME.MODULE_BG}, 0.2)
    end)
    
    btn.MouseButton2Click:Connect(function()
        if not hasSettings then return end
        moduleData.expanded = not moduleData.expanded
        if moduleData.expanded then
            tween(arrowLbl, {Rotation = 90}, 0.2)
            tween(container, {Size = UDim2.new(1, -16, 0, 34 + setListLayout.AbsoluteContentSize.Y)}, 0.3)
        else
            tween(arrowLbl, {Rotation = 0}, 0.2)
            tween(container, {Size = UDim2.new(1, -16, 0, 34)}, 0.3)
        end
    end)
    
    bindBox.MouseButton1Click:Connect(function()
        bindBox.Text = "?"
        bindBox.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
        self.bindingModule = moduleData
    end)
    
    table.insert(self.modules, moduleData)
    return moduleData
end

function CategoryPanel:addBoolean(moduleData, name, settingKey)
    local frame = Instance.new("TextButton", moduleData.settingsList)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.Text = ""
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -30, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.TEXT_DIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local checkContainer = Instance.new("Frame", frame)
    checkContainer.Size = UDim2.new(0, 16, 0, 16)
    checkContainer.Position = UDim2.new(1, -28, 0.5, -8)
    checkContainer.BackgroundColor3 = THEME.BIND_BG
    checkContainer.BorderSizePixel = 0
    Instance.new("UICorner", checkContainer).CornerRadius = UDim.new(0, 4)
    
    local gradient = Instance.new("UIGradient", checkContainer)
    gradient.Rotation = 45
    
    local check = Instance.new("TextLabel", checkContainer)
    check.Size = UDim2.new(1, 0, 1, 0)
    check.BackgroundTransparency = 1
    check.Font = Enum.Font.GothamBold
    check.TextSize = 12
    
    local function update()
        local val = getgenv().aim_settings[settingKey]
        check.Text = val and "✓" or "X"
        
        if val then
            tween(checkContainer, {BackgroundColor3 = THEME.GREEN_CHECK}, 0.3)
            tween(check, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.3)
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 210, 120)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 90))
            })
        else
            tween(checkContainer, {BackgroundColor3 = THEME.RED_CROSS}, 0.3)
            tween(check, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.3)
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, THEME.RED_CROSS),
                ColorSequenceKeypoint.new(1, getClientColor())
            })
        end
    end
    
    registerUIRefresher(update)
    update()
    
    frame.MouseButton1Click:Connect(function()
        getgenv().aim_settings[settingKey] = not getgenv().aim_settings[settingKey]
        update()
    end)
    
    table.insert(moduleData.settings, frame)
end

function CategoryPanel:addColorPicker(moduleData, name, settingKey)
    local frame = Instance.new("TextButton", moduleData.settingsList)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.Text = ""
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -30, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.TEXT_DIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Color circle
    local colorCircle = Instance.new("Frame", frame)
    colorCircle.Size = UDim2.new(0, 16, 0, 16)
    colorCircle.Position = UDim2.new(1, -28, 0.5, -8)
    colorCircle.BackgroundColor3 = getgenv().aim_settings[settingKey]
    colorCircle.BorderSizePixel = 0
    
    local circleCorner = Instance.new("UICorner", colorCircle)
    circleCorner.CornerRadius = UDim.new(1, 0)
    
    local circleStroke = Instance.new("UIStroke", colorCircle)
    circleStroke.Color = Color3.fromRGB(255, 255, 255)
    circleStroke.Thickness = 1
    circleStroke.Transparency = 0.7
    
    -- Update color function
    local function updateColor()
        colorCircle.BackgroundColor3 = getgenv().aim_settings[settingKey]
    end
    
    -- Color Picker Window
    local colorPickerWindow = nil
    
    local function createColorPicker()
        if colorPickerWindow then return end
        
        -- Main window
        colorPickerWindow = Instance.new("Frame", ScreenGui)
        colorPickerWindow.Size = UDim2.new(0, 300, 0, 350)
        colorPickerWindow.Position = UDim2.new(0.5, -150, 0.5, -175)
        colorPickerWindow.BackgroundColor3 = THEME.PANEL_BG
        colorPickerWindow.BorderSizePixel = 0
        colorPickerWindow.ZIndex = 1000
        
        local windowCorner = Instance.new("UICorner", colorPickerWindow)
        windowCorner.CornerRadius = UDim.new(0, 10)
        
        local windowStroke = Instance.new("UIStroke", colorPickerWindow)
        windowStroke.Color = THEME.PANEL_STROKE
        windowStroke.Thickness = 2
        
        -- Title
        local title = Instance.new("TextLabel", colorPickerWindow)
        title.Size = UDim2.new(1, -40, 0, 30)
        title.Position = UDim2.new(0, 15, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = ""
        title.TextColor3 = THEME.TEXT_TITLE
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Close button
        local closeBtn = Instance.new("TextButton", colorPickerWindow)
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -30, 0, 15)
        closeBtn.BackgroundColor3 = Color3.fromRGB(235, 85, 85)
        closeBtn.Text = "×"
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 14
        closeBtn.AutoButtonColor = false
        
        local closeBtnCorner = Instance.new("UICorner", closeBtn)
        closeBtnCorner.CornerRadius = UDim.new(1, 0)
        
        -- HSV Color Picker Area (200x200)
        local pickerArea = Instance.new("TextButton", colorPickerWindow)
        pickerArea.Size = UDim2.new(0, 200, 0, 200)
        pickerArea.Position = UDim2.new(0, 20, 0, 50)
        pickerArea.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        pickerArea.BorderSizePixel = 0
        pickerArea.Text = ""
        pickerArea.AutoButtonColor = false
        pickerArea.ZIndex = 1
        
        local pickerCorner = Instance.new("UICorner", pickerArea)
        pickerCorner.CornerRadius = UDim.new(0, 8)
        
        local pickerStroke = Instance.new("UIStroke", pickerArea)
        pickerStroke.Color = Color3.fromRGB(60, 60, 60)
        pickerStroke.Thickness = 1
        
        -- Saturation gradient (left to right: цвет к белому)
        local satFrame = Instance.new("Frame", pickerArea)
        satFrame.Size = UDim2.new(1, 0, 1, 0)
        satFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        satFrame.BorderSizePixel = 0
        satFrame.ZIndex = 2
        
        local satCorner = Instance.new("UICorner", satFrame)
        satCorner.CornerRadius = UDim.new(0, 8)
        
        local satGradient = Instance.new("UIGradient", satFrame)
        satGradient.Rotation = 0
        satGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        })
        
        -- Value gradient (top to bottom: прозрачный к черному)
        local valFrame = Instance.new("Frame", pickerArea)
        valFrame.Size = UDim2.new(1, 0, 1, 0)
        valFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        valFrame.BorderSizePixel = 0
        valFrame.ZIndex = 3
        
        local valCorner = Instance.new("UICorner", valFrame)
        valCorner.CornerRadius = UDim.new(0, 8)
        
        local valGradient = Instance.new("UIGradient", valFrame)
        valGradient.Rotation = 90
        valGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0)
        })
        
        -- Hue slider (30x200)
        local hueSlider = Instance.new("TextButton", colorPickerWindow)
        hueSlider.Size = UDim2.new(0, 30, 0, 200)
        hueSlider.Position = UDim2.new(0, 240, 0, 50)
        hueSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hueSlider.BorderSizePixel = 0
        hueSlider.Text = ""
        hueSlider.AutoButtonColor = false
        hueSlider.ZIndex = 1
        
        local hueCorner = Instance.new("UICorner", hueSlider)
        hueCorner.CornerRadius = UDim.new(0, 8)
        
        local hueStroke = Instance.new("UIStroke", hueSlider)
        hueStroke.Color = Color3.fromRGB(60, 60, 60)
        hueStroke.Thickness = 1
        
        -- Hue gradient (rainbow)
        local hueGradient = Instance.new("UIGradient", hueSlider)
        hueGradient.Rotation = 90
        hueGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),      -- Красный
            ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)), -- Желтый
            ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)), -- Зеленый
            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),     -- Циан
            ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)), -- Синий
            ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)), -- Магента
            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))           -- Красный (замыкание)
        })
        
        -- Color preview
        local colorPreview = Instance.new("Frame", colorPickerWindow)
        colorPreview.Size = UDim2.new(0, 250, 0, 40)
        colorPreview.Position = UDim2.new(0, 20, 0, 270)
        colorPreview.BackgroundColor3 = getgenv().aim_settings[settingKey]
        colorPreview.BorderSizePixel = 0
        
        local previewCorner = Instance.new("UICorner", colorPreview)
        previewCorner.CornerRadius = UDim.new(0, 8)
        
        local previewStroke = Instance.new("UIStroke", colorPreview)
        previewStroke.Color = Color3.fromRGB(60, 60, 60)
        previewStroke.Thickness = 1
        
        -- HSV values
        local currentH, currentS, currentV = Color3.toHSV(getgenv().aim_settings[settingKey])
        
        -- Cursors
        local pickerCursor = Instance.new("Frame", pickerArea)
        pickerCursor.Size = UDim2.new(0, 10, 0, 10) -- Немного меньше для лучшей точности
        pickerCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        pickerCursor.BorderSizePixel = 0
        pickerCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        pickerCursor.ZIndex = 10
        
        local cursorCorner = Instance.new("UICorner", pickerCursor)
        cursorCorner.CornerRadius = UDim.new(1, 0)
        
        local cursorStroke = Instance.new("UIStroke", pickerCursor)
        cursorStroke.Color = Color3.fromRGB(0, 0, 0)
        cursorStroke.Thickness = 2
        
        local hueCursor = Instance.new("Frame", hueSlider)
        hueCursor.Size = UDim2.new(0, 32, 0, 6) -- Фиксированная ширина вместо относительной
        hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hueCursor.BorderSizePixel = 0
        hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
        hueCursor.ZIndex = 10
        
        local hueCursorCorner = Instance.new("UICorner", hueCursor)
        hueCursorCorner.CornerRadius = UDim.new(0, 3)
        
        local hueCursorStroke = Instance.new("UIStroke", hueCursor)
        hueCursorStroke.Color = Color3.fromRGB(0, 0, 0)
        hueCursorStroke.Thickness = 2
        hueCursorStroke.Thickness = 1
        
        -- Update function
        local function updatePickerColor()
            local hueColor = Color3.fromHSV(currentH, 1, 1)
            pickerArea.BackgroundColor3 = hueColor
            
            -- Обновляем градиент saturation для текущего hue
            satGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, hueColor)
            })
            
            local finalColor = Color3.fromHSV(currentH, currentS, currentV)
            colorPreview.BackgroundColor3 = finalColor
            getgenv().aim_settings[settingKey] = finalColor
            updateColor()
            
            -- Если обновляется цвет клиента, обновляем все цвета в интерфейсе
            if settingKey == "client_color" then
                updateAllColors()
            end
            
            -- Update cursor positions (исправляем позиционирование)
            -- Для picker cursor: S по X, V по Y (инвертированный)
            pickerCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
            
            -- Для hue cursor: центрируем по X, H по Y
            hueCursor.Position = UDim2.new(0.5, 0, currentH, 0)
        end
        
        -- Mouse handling
        local draggingPicker = false
        local draggingHue = false
        
        pickerArea.MouseButton1Down:Connect(function()
            draggingPicker = true
            -- Немедленно обновляем позицию при клике
            local mouse = UserInputService:GetMouseLocation()
            local pos = pickerArea.AbsolutePosition
            local size = pickerArea.AbsoluteSize
            
            -- Вычисляем относительную позицию мыши в области picker
            -- Добавляем смещение -18 по Y (вниз)
            local relativeX = (mouse.X - pos.X) / size.X
            local relativeY = ((mouse.Y - 50) - pos.Y) / size.Y
            
            currentS = math.clamp(relativeX, 0, 1)
            currentV = math.clamp(1 - relativeY, 0, 1) -- Инвертируем Y для правильного направления
            updatePickerColor()
        end)
        
        hueSlider.MouseButton1Down:Connect(function()
            draggingHue = true
            -- Немедленно обновляем позицию при клике
            local mouse = UserInputService:GetMouseLocation()
            local pos = hueSlider.AbsolutePosition
            local size = hueSlider.AbsoluteSize
            
            -- Вычисляем относительную позицию мыши в hue slider
            local relativeY = ((mouse.Y - 50) - pos.Y) / size.Y
            
            currentH = math.clamp(relativeY, 0, 1)
            updatePickerColor()
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if draggingPicker then
                    local mouse = UserInputService:GetMouseLocation()
                    local pos = pickerArea.AbsolutePosition
                    local size = pickerArea.AbsoluteSize
                    
                    -- Вычисляем относительную позицию мыши в области picker
                    -- Добавляем смещение -50 по Y (вниз)
                    local relativeX = (mouse.X - pos.X) / size.X
                    local relativeY = ((mouse.Y - 50) - pos.Y) / size.Y
                    
                    currentS = math.clamp(relativeX, 0, 1)
                    currentV = math.clamp(1 - relativeY, 0, 1) -- Инвертируем Y для правильного направления
                    updatePickerColor()
                end
                
                if draggingHue then
                    local mouse = UserInputService:GetMouseLocation()
                    local pos = hueSlider.AbsolutePosition
                    local size = hueSlider.AbsoluteSize
                    
                    -- Вычисляем относительную позицию мыши в hue slider
                    local relativeY = ((mouse.Y - 50) - pos.Y) / size.Y
                    
                    currentH = math.clamp(relativeY, 0, 1)
                    updatePickerColor()
                end
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingPicker = false
                draggingHue = false
            end
        end)
        
        closeBtn.MouseButton1Click:Connect(function()
            colorPickerWindow:Destroy()
            colorPickerWindow = nil
        end)
        
        updatePickerColor()
    end
    
    registerUIRefresher(updateColor)

    frame.MouseButton1Click:Connect(function()
        createColorPicker()
    end)
    
    table.insert(moduleData.settings, frame)
end

function CategoryPanel:addSlider(moduleData, name, settingKey, min, max, inc)
    local frame = Instance.new("Frame", moduleData.settingsList)
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundTransparency = 1
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.5, 0, 0, 16)
    lbl.Position = UDim2.new(0, 12, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.TEXT_DIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0.5, -24, 0, 16)
    valLbl.Position = UDim2.new(0.5, 12, 0, 4)
    valLbl.BackgroundTransparency = 1
    valLbl.TextColor3 = THEME.TEXT_DIM
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 11
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("TextButton", frame)
    track.Size = UDim2.new(1, -24, 0, 4)
    track.Position = UDim2.new(0, 12, 0, 26)
    track.BackgroundColor3 = THEME.BIND_BG
    track.AutoButtonColor = false
    track.Text = ""
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = getClientColor()
    fill.Size = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", fill)
    knob.Size = UDim2.new(0, 10, 0, 10)
    knob.Position = UDim2.new(1, -5, 0.5, -5)
    knob.BackgroundColor3 = THEME.KNOB
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function applySliderValue(value)
        getgenv().aim_settings[settingKey] = value
        valLbl.Text = string.format("%.2f", value)
        tween(fill, {Size = UDim2.new(math.clamp((value - min) / (max - min), 0, 1), 0, 1, 0)}, 0.1)
    end

    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor((min + (max - min) * pos) / inc + 0.5) * inc
        applySliderValue(value)
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
    end)

    registerUIRefresher(function()
        fill.BackgroundColor3 = getClientColor()
        applySliderValue(getgenv().aim_settings[settingKey])
    end)
    
    local startVal = getgenv().aim_settings[settingKey]
    valLbl.Text = string.format("%.2f", startVal)
    fill.Size = UDim2.new(math.clamp((startVal - min) / (max - min), 0, 1), 0, 1, 0)
    
    table.insert(moduleData.settings, frame)
end

function CategoryPanel:addDropdown(moduleData, name, settingKey, options)
    local frame = Instance.new("TextButton", moduleData.settingsList)
    frame.Size = UDim2.new(1, 0, 0, 24)
    frame.BackgroundTransparency = 1
    frame.Text = ""
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.TEXT_DIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0.5, -24, 1, 0)
    valLbl.Position = UDim2.new(0.5, 12, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = getgenv().aim_settings[settingKey]
    valLbl.TextColor3 = getClientColor()
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    frame.MouseButton1Click:Connect(function()
        local currentIndex = table.find(options, getgenv().aim_settings[settingKey]) or 1
        local nextIndex = (currentIndex % #options) + 1
        getgenv().aim_settings[settingKey] = options[nextIndex]
        valLbl.Text = options[nextIndex]
    end)

    registerUIRefresher(function()
        valLbl.Text = tostring(getgenv().aim_settings[settingKey] or options[1] or "")
        valLbl.TextColor3 = getClientColor()
    end)
    
    table.insert(moduleData.settings, frame)
end

function CategoryPanel:addTextBox(name, settingKey, placeholder)
    local frame = Instance.new("Frame", self.frame)
    frame.Size = UDim2.new(1, -16, 0, 50)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #self.modules + 2
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = THEME.TEXT_DIM
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local textBoxFrame = Instance.new("Frame", frame)
    textBoxFrame.Size = UDim2.new(1, -24, 0, 25)
    textBoxFrame.Position = UDim2.new(0, 12, 0, 22)
    textBoxFrame.BackgroundColor3 = THEME.MODULE_BG
    textBoxFrame.BorderSizePixel = 0
    
    local textBoxCorner = Instance.new("UICorner", textBoxFrame)
    textBoxCorner.CornerRadius = UDim.new(0, 6)
    
    local textBoxStroke = Instance.new("UIStroke", textBoxFrame)
    textBoxStroke.Color = THEME.MODULE_STROKE
    textBoxStroke.Thickness = 1
    
    local textBox = Instance.new("TextBox", textBoxFrame)
    textBox.Size = UDim2.new(1, -12, 1, -4)
    textBox.Position = UDim2.new(0, 6, 0, 2)
    textBox.BackgroundTransparency = 1
    textBox.Text = getgenv().aim_settings[settingKey] or ""
    textBox.PlaceholderText = placeholder or ""
    textBox.TextColor3 = THEME.TEXT_TITLE
    textBox.PlaceholderColor3 = THEME.TEXT_DIM
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 11
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.ClearTextOnFocus = false
    
    textBox.FocusLost:Connect(function()
        getgenv().aim_settings[settingKey] = textBox.Text
    end)

    registerUIRefresher(function()
        textBox.Text = tostring(getgenv().aim_settings[settingKey] or "")
    end)
    
    return frame
end

local function getVisibleKeybindEntries()
    local entries = {}

    for settingKey, keyCode in pairs(getgenv().aim_settings.hotkeys) do
        if getgenv().aim_settings[settingKey] and keyCode and keyCode ~= Enum.KeyCode.Unknown then
            table.insert(entries, {
                name = getBindDisplayName(settingKey),
                keyCode = keyCode
            })
        end
    end

    if getgenv().aim_settings.clickgui_enabled and getgenv().aim_settings.clickgui_bind and getgenv().aim_settings.clickgui_bind ~= Enum.KeyCode.Unknown then
        table.insert(entries, {
            name = getBindDisplayName("clickgui_enabled"),
            keyCode = getgenv().aim_settings.clickgui_bind
        })
    end

    if getgenv().aim_settings.click_action and getgenv().aim_settings.click_action_key and getgenv().aim_settings.click_action_key ~= Enum.KeyCode.Unknown then
        table.insert(entries, {
            name = getBindDisplayName("click_action"),
            keyCode = getgenv().aim_settings.click_action_key
        })
    end

    table.sort(entries, function(a, b)
        return a.name < b.name
    end)

    return entries
end

function CategoryPanel:addButton(name, callback)
    local frame = Instance.new("Frame", self.frame)
    frame.Size = UDim2.new(1, -16, 0, 34)
    frame.BackgroundTransparency = 1
    frame.LayoutOrder = #self.modules + 2
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = THEME.MODULE_BG
    btn.Text = name
    btn.TextColor3 = THEME.TEXT_TITLE
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.AutoButtonColor = false
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = THEME.MODULE_STROKE
    btnStroke.Thickness = 1
    
    btn.MouseButton1Click:Connect(function()
        tween(btn, {BackgroundColor3 = getClientColor()}, 0.1)
        wait(0.1)
        tween(btn, {BackgroundColor3 = THEME.MODULE_BG}, 0.1)
        if callback then
            callback()
        end
    end)
    
    return frame
end

function CategoryPanel:addCustomElement(element)
    element.Parent = self.frame
    element.LayoutOrder = #self.modules + 2
    return element
end

-- [[ BUILD UI ]]
local panels = {}
local startX = 50
local panelW = 200
local gap = 12

-- Переменные для анимации панелей
local panelAnimationState = "hidden" -- "hidden", "showing", "visible", "hiding"
local panelAnimationProgress = 0
local panelOriginalPositions = {}
local panelTargetPositions = {}

-- Функция для анимации панелей
local function animatePanels(show)
    if show then
        if panelAnimationState == "hidden" then
            -- Сразу показываем ScreenGui чтобы анимация была видна
            ScreenGui.Enabled = true
            panelAnimationState = "showing"
            panelAnimationProgress = 0
        end
    else
        if panelAnimationState == "visible" then
            panelAnimationState = "hiding"
            panelAnimationProgress = 0
        end
    end
end

-- Функция для обновления анимации панелей
local function updatePanelAnimation(deltaTime)
    if panelAnimationState == "showing" then
        panelAnimationProgress = panelAnimationProgress + deltaTime * 4 -- Скорость анимации
        
        if panelAnimationProgress >= 1 then
            panelAnimationProgress = 1
            panelAnimationState = "visible"
        end
        
        -- Плавная анимация появления снизу с задержкой для каждой панели
        for i, panel in ipairs(panels) do
            local delay = (i - 1) * 0.1 -- Задержка между панелями
            local adjustedProgress = math.max(0, math.min(1, (panelAnimationProgress - delay) / (1 - delay)))
            
            -- Easing функция для плавности (ease out cubic)
            local easedProgress = 1 - math.pow(1 - adjustedProgress, 3)
            
            local startY = 1 + 0.1 -- Начальная позиция (ниже экрана)
            local targetY = panelOriginalPositions[i].Y.Scale
            local currentY = startY + (targetY - startY) * easedProgress
            
            panel.frame.Position = UDim2.new(
                panelOriginalPositions[i].X.Scale,
                panelOriginalPositions[i].X.Offset,
                currentY,
                panelOriginalPositions[i].Y.Offset
            )
        end
        
    elseif panelAnimationState == "hiding" then
        panelAnimationProgress = panelAnimationProgress + deltaTime * 5 -- Быстрее при скрытии
        
        if panelAnimationProgress >= 1 then
            panelAnimationProgress = 1
            panelAnimationState = "hidden"
            -- Скрываем ScreenGui только после завершения анимации
            ScreenGui.Enabled = false
        end
        
        -- Плавная анимация исчезновения вверх с задержкой для каждой панели
        for i, panel in ipairs(panels) do
            local delay = (i - 1) * 0.05 -- Меньшая задержка при скрытии
            local adjustedProgress = math.max(0, math.min(1, (panelAnimationProgress - delay) / (1 - delay)))
            
            -- Easing функция для плавности (ease in cubic)
            local easedProgress = math.pow(adjustedProgress, 3)
            
            local startY = panelOriginalPositions[i].Y.Scale
            local targetY = -0.5 -- Конечная позиция (выше экрана)
            local currentY = startY + (targetY - startY) * easedProgress
            
            panel.frame.Position = UDim2.new(
                panelOriginalPositions[i].X.Scale,
                panelOriginalPositions[i].X.Offset,
                currentY,
                panelOriginalPositions[i].Y.Offset
            )
        end
    end
end

-- 1. COMBAT
local pCombat = CategoryPanel.new("Combat", startX, 50, panelW)
local mAimbot = pCombat:addModule("Aimbot", "enabled", true)
pCombat:addBoolean(mAimbot, "Prediction", "prediction_enabled")
pCombat:addBoolean(mAimbot, "Lock Target", "lock_player")
pCombat:addBoolean(mAimbot, "WallCheck", "wall_check")
pCombat:addBoolean(mAimbot, "Smooth", "smooth_enabled")
pCombat:addBoolean(mAimbot, "Noise", "noise_enabled")
pCombat:addBoolean(mAimbot, "Speed Display", "speed_display")
pCombat:addSlider(mAimbot, "FOV", "fov", 10, 500, 1)
pCombat:addSlider(mAimbot, "Predict Amount", "prediction_amount", 0, 0.5, 0.01)
pCombat:addSlider(mAimbot, "Smooth Amount", "smooth_amount", 0.01, 1, 0.01)
pCombat:addSlider(mAimbot, "Noise Amount", "noise_amount", 0, 0.5, 0.01)
pCombat:addDropdown(mAimbot, "Hitbox", "hitbox", {"Head", "Body"})
pCombat:addDropdown(mAimbot, "Priority", "priority", {"Distance", "Health", "Free"})
pCombat:addDropdown(mAimbot, "Activation", "aim_activation", {"RMB", "LMB", "Auto"})

local mHitboxes = pCombat:addModule("Hitboxes", "hitboxes_enabled", true)
pCombat:addDropdown(mHitboxes, "Part", "hitboxes_part", {"Head", "Body"})
pCombat:addSlider(mHitboxes, "Size", "hitboxes_size", 1.0, 30.0, 0.5)
pCombat:addSlider(mHitboxes, "Transparency", "hitboxes_transparency", 0.0, 1.0, 0.05)
pCombat:addColorPicker(mHitboxes, "Color", "hitboxes_color")

table.insert(panels, pCombat)

-- 2. VISUALS
local pVisuals = CategoryPanel.new("Visuals", startX + panelW + gap, 50, panelW)
local mESP = pVisuals:addModule("Player ESP", "esp_enabled", true)
pVisuals:addDropdown(mESP, "ESP Mode", "esp_mode", {"White", "Black"})
pVisuals:addBoolean(mESP, "Chams", "esp_chams")
local mTargetESP = pVisuals:addModule("Target ESP", "target_esp", true)
pVisuals:addDropdown(mTargetESP, "Mode", "target_esp_mode", {"Crosshair", "Circle"})
pVisuals:addModule("Target HUD", "target_hud", false)
pVisuals:addModule("Friend Markers", "friend_markers", false)
    local mArrows = pVisuals:addModule("Arrows", "arrows", true)
    pVisuals:addSlider(mArrows, "Radius", "arrows_radius", 20, 250, 1)
    pVisuals:addSlider(mArrows, "Size", "arrows_size", 8, 48, 1)
local mHUD = pVisuals:addModule("HUD", "hud_enabled", true)
pVisuals:addBoolean(mHUD, "Watermark", "watermark_enabled")
pVisuals:addBoolean(mHUD, "Keybind List", "keybind_list_enabled")
pVisuals:addColorPicker(mHUD, "Client Color", "client_color")
pVisuals:addModule("Rainbow FOV", "rainbow_fov", false)
pVisuals:addModule("Rainbow Crosshair", "rainbow_crosshair", false)
local mJumpCircle = pVisuals:addModule("Jump Circle", "jump_circle_enabled", true)
pVisuals:addSlider(mJumpCircle, "Speed", "jump_circle_speed", 0.1, 2.0, 0.1)
pVisuals:addSlider(mJumpCircle, "Size", "jump_circle_size", 0.5, 20.0, 0.1)
local mClickGui = pVisuals:addModule("ClickGui", "clickgui_enabled", true)
pVisuals:addBoolean(mClickGui, "Blur", "clickgui_blur")
pVisuals:addBoolean(mClickGui, "Darken", "clickgui_darken")
pVisuals:addBoolean(mClickGui, "Image", "clickgui_image")
pVisuals:addDropdown(mClickGui, "Image Mode", "clickgui_image_mode", {"Vanilla", "Azuki", "mgebrat", "larp", "larp2", "trollface"})
pVisuals:addBoolean(mClickGui, "Animate Trollface", "trollface_animate")
pVisuals:addBoolean(mClickGui, "Trollface Music", "trollface_music")
pVisuals:addSlider(mClickGui, "Music Volume", "trollface_volume", 0, 1, 0.1)
local mCosmetic = pVisuals:addModule("Cosmetic", "cosmetic_enabled", true)
pVisuals:addBoolean(mCosmetic, "China Hat", "china_hat")
pVisuals:addBoolean(mCosmetic, "Hide in First Person", "hide_in_first_person")
pVisuals:addBoolean(mCosmetic, "Friends", "china_hat_friends")
table.insert(panels, pVisuals)

-- 3. MOVEMENT
local pMove = CategoryPanel.new("Movement", startX + (panelW + gap)*2, 50, panelW)
local mTPWalk = pMove:addModule("TP Walk", "tp_walk_enabled", true)
pMove:addSlider(mTPWalk, "Speed", "tp_walk_speed", 1, 10, 0.5)
table.insert(panels, pMove)

-- 4. MISC
local pMisc = CategoryPanel.new("Misc", startX + (panelW + gap)*3, 50, panelW)
local mClickAction = pMisc:addModule("Friend Add/Rem", "click_action", false)
pMisc:addModule("FullBright", "fullbright", false)
pMisc:addModule("Always Day", "always_day", false)
pMisc:addModule("Chat", "chat_enabled", false)
local mUnload = pMisc:addModule("Unload Script", "unload_script", false)
table.insert(panels, pMisc)

-- 5. CONFIG
local pConfig = CategoryPanel.new("Config", startX + (panelW + gap)*4, 50, panelW)

-- CONFIG SYSTEM VARIABLES
local configList = {}
local selectedConfig = ""
local CONFIG_FOLDER = "moonware_configs"

local function hasExploitFileApi()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(listfiles) == "function"
        and type(makefolder) == "function"
        and type(isfolder) == "function"
end

local function ensureConfigFolder()
    if not hasExploitFileApi() then
        return false
    end
    
    if not isfolder(CONFIG_FOLDER) then
        pcall(makefolder, CONFIG_FOLDER)
    end
    
    return isfolder(CONFIG_FOLDER)
end

local function getConfigFilePath(encodedName)
    return CONFIG_FOLDER .. "/" .. encodedName .. ".json"
end

local function serializeConfigValue(value)
    local valueType = typeof(value)
    
    if valueType == "Color3" then
        return {
            __type = "Color3",
            r = value.R,
            g = value.G,
            b = value.B
        }
    elseif valueType == "EnumItem" then
        return {
            __type = "EnumItem",
            enumType = tostring(value.EnumType),
            name = value.Name
        }
    elseif valueType == "table" then
        local serialized = {}
        for key, nestedValue in pairs(value) do
            serialized[key] = serializeConfigValue(nestedValue)
        end
        return serialized
    end
    
    return value
end

local function deserializeConfigValue(value)
    if type(value) ~= "table" then
        return value
    end
    
    if value.__type == "Color3" then
        return Color3.new(value.r or 0, value.g or 0, value.b or 0)
    elseif value.__type == "EnumItem" then
        local enumTypeName = tostring(value.enumType or ""):match("^Enum%.(.+)$")
        local enumObject = enumTypeName and Enum[enumTypeName]
        return (enumObject and enumObject[value.name]) or Enum.KeyCode.Unknown
    end
    
    local deserialized = {}
    for key, nestedValue in pairs(value) do
        deserialized[key] = deserializeConfigValue(nestedValue)
    end
    return deserialized
end

local function snapshotConfigData()
    local runtimeData = {}
    local serializedData = {}
    
    for key, value in pairs(getgenv().aim_settings) do
        if key ~= "running" and key ~= "friends" and key ~= "config_name" then
            local serializedValue = serializeConfigValue(value)
            serializedData[key] = serializedValue
            runtimeData[key] = deserializeConfigValue(serializedValue)
        end
    end
    
    return runtimeData, serializedData
end

local function reloadConfigsFromDisk()
    configList = {}
    
    if not ensureConfigFolder() then
        return false, "Exploit filesystem API недоступен"
    end
    
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if not ok or type(files) ~= "table" then
        return false, "Не удалось прочитать папку конфигов"
    end
    
    for _, path in ipairs(files) do
        local encodedName = tostring(path):match("([^/\\]+)%.json$")
        if encodedName then
            local readOk, raw = pcall(readfile, path)
            if readOk and type(raw) == "string" and raw ~= "" then
                local decodeOk, payload = pcall(function()
                    return HttpService:JSONDecode(raw)
                end)
                
                if decodeOk and type(payload) == "table" then
                    configList[encodedName] = {
                        name = payload.name or decodeConfigName(encodedName) or encodedName,
                        data = deserializeConfigValue(payload.data or {}),
                        timestamp = payload.timestamp or os.time(),
                        path = path
                    }
                end
            end
        end
    end
    
    return true
end

-- Функция для кодирования имени конфига
local function encodeConfigName(name)
    local encoded = "moonware_"
    for i = 1, #name do
        local char = string.byte(name, i)
        encoded = encoded .. string.format("%02x", char)
    end
    return encoded
end

-- Функция для декодирования имени конфига
local function decodeConfigName(encoded)
    if not encoded:match("^moonware_") then
        return nil
    end
    
    local hexPart = encoded:sub(10) -- Убираем "moonware_"
    local decoded = ""
    
    for i = 1, #hexPart, 2 do
        local hex = hexPart:sub(i, i+1)
        local char = tonumber(hex, 16)
        if char then
            decoded = decoded .. string.char(char)
        end
    end
    
    return decoded
end

-- Функция для сохранения конфига
local function saveConfig(name)
    if not name or name:gsub("%s", "") == "" then
        return false, "Имя конфига не может быть пустым"
    end
    
    local encodedName = encodeConfigName(name)
    local configData = {}
    
    -- Сохраняем все настройки из aim_settings
    for key, value in pairs(getgenv().aim_settings) do
        if key ~= "running" and key ~= "friends" and key ~= "config_name" then
            configData[key] = value
        end
    end

    configData.hotkeys = cloneHotkeys(getgenv().aim_settings.hotkeys)
    
    configList[encodedName] = {
        name = name,
        data = configData,
        timestamp = os.time()
    }
    
    return true, "Конфиг '" .. name .. "' сохранен"
end

-- Функция для загрузки конфига
local function loadConfig(encodedName)
    if not configList[encodedName] then
        return false, "Конфиг не найден"
    end
    
    local config = configList[encodedName]
    
    -- Загружаем настройки
    for key, value in pairs(config.data) do
        if key == "hotkeys" then
            getgenv().aim_settings.hotkeys = cloneHotkeys(value)
        elseif getgenv().aim_settings[key] ~= nil then
            getgenv().aim_settings[key] = value
        end
    end

    getgenv().aim_settings.config_name = config.name
    refreshUIFromSettings()
    updateAllColors()
    
    return true, "Конфиг '" .. config.name .. "' загружен"
end

-- Функция для удаления конфига
local function deleteConfig(encodedName)
    if not configList[encodedName] then
        return false, "Конфиг не найден"
    end
    
    local configName = configList[encodedName].name
    configList[encodedName] = nil
    return true, "Конфиг '" .. configName .. "' удален"
end

-- Функция для получения списка конфигов
local function getConfigsList()
    local configs = {}
    for encodedName, config in pairs(configList) do
        table.insert(configs, {
            encoded = encodedName,
            name = config.name,
            timestamp = config.timestamp
        })
    end
    
    -- Сортируем по времени создания
    table.sort(configs, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return configs
end

-- Добавляем элементы в категорию Config
-- TextBox для имени конфига
pConfig:addTextBox("Config Name", "config_name", "Введите название...")

local updateConfigList

-- Кнопки управления
reloadConfigsFromDisk = function()
    configList = {}
    
    if not ensureConfigFolder() then
        return false, "Exploit filesystem API недоступен"
    end
    
    local ok, files = pcall(listfiles, CONFIG_FOLDER)
    if not ok or type(files) ~= "table" then
        return false, "Не удалось прочитать папку конфигов"
    end
    
    for _, path in ipairs(files) do
        local encodedName = tostring(path):match("([^/\\]+)%.json$")
        if encodedName then
            local readOk, raw = pcall(readfile, path)
            if readOk and type(raw) == "string" and raw ~= "" then
                local decodeOk, payload = pcall(function()
                    return HttpService:JSONDecode(raw)
                end)
                
                if decodeOk and type(payload) == "table" then
                    configList[encodedName] = {
                        name = payload.name or decodeConfigName(encodedName) or encodedName,
                        data = deserializeConfigValue(payload.data or {}),
                        timestamp = payload.timestamp or os.time(),
                        path = path
                    }
                end
            end
        end
    end
    
    return true
end

saveConfig = function(name)
    if not name or name:gsub("%s", "") == "" then
        return false, "Имя конфига не может быть пустым"
    end
    if not ensureConfigFolder() then
        return false, "Exploit filesystem API недоступен"
    end
    
    local encodedName = encodeConfigName(name)
    local runtimeData, serializedData = snapshotConfigData()
    local timestamp = os.time()
    local filePath = getConfigFilePath(encodedName)
    local writeOk, writeErr = pcall(function()
        writefile(filePath, HttpService:JSONEncode({
            name = name,
            timestamp = timestamp,
            data = serializedData
        }))
    end)
    if not writeOk then
        return false, "Ошибка сохранения конфига: " .. tostring(writeErr)
    end
    
    configList[encodedName] = {
        name = name,
        data = runtimeData,
        timestamp = timestamp,
        path = filePath
    }
    
    return true, "Конфиг '" .. name .. "' сохранен"
end

loadConfig = function(encodedName)
    reloadConfigsFromDisk()
    if not configList[encodedName] then
        return false, "Конфиг не найден"
    end
    
    local config = configList[encodedName]
    local function normalizeSingleKeyCode(value, fallback)
        local wrapped = cloneHotkeys({ __value = value })
        return wrapped.__value or fallback or Enum.KeyCode.Unknown
    end
    getgenv().aim_settings.hotkeys = cloneHotkeys(config.data.hotkeys or {})
    for key, value in pairs(config.data) do
        if key == "hotkeys" then
            -- already restored above
        elseif key == "click_action_key" then
            getgenv().aim_settings.click_action_key = normalizeSingleKeyCode(value, getgenv().aim_settings.click_action_key)
        elseif key == "clickgui_bind" then
            getgenv().aim_settings.clickgui_bind = normalizeSingleKeyCode(value, getgenv().aim_settings.clickgui_bind)
        elseif getgenv().aim_settings[key] ~= nil then
            getgenv().aim_settings[key] = value
        end
    end
    
    getgenv().aim_settings.config_name = config.name
    refreshUIFromSettings()
    updateAllColors()
    
    return true, "Конфиг '" .. config.name .. "' загружен"
end

deleteConfig = function(encodedName)
    reloadConfigsFromDisk()
    if not configList[encodedName] then
        return false, "Конфиг не найден"
    end
    if type(delfile) ~= "function" then
        return false, "Exploit API не поддерживает удаление файлов"
    end
    
    local configName = configList[encodedName].name
    local filePath = configList[encodedName].path or getConfigFilePath(encodedName)
    local deleteOk, deleteErr = pcall(function()
        delfile(filePath)
    end)
    if not deleteOk then
        return false, "Ошибка удаления конфига: " .. tostring(deleteErr)
    end
    
    configList[encodedName] = nil
    return true, "Конфиг '" .. configName .. "' удален"
end

getConfigsList = function()
    reloadConfigsFromDisk()
    
    local configs = {}
    for encodedName, config in pairs(configList) do
        table.insert(configs, {
            encoded = encodedName,
            name = config.name,
            timestamp = config.timestamp
        })
    end
    
    table.sort(configs, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return configs
end

pConfig:addButton("Save Config", function()
    local name = getgenv().aim_settings.config_name or ""
    name = name:gsub("^%s*(.-)%s*$", "%1") -- Убираем пробелы
    
    local success, message = saveConfig(name)
    print(message)
    
    if success then
        getgenv().aim_settings.config_name = "" -- Очищаем поле
        selectedConfig = ""
        refreshUIFromSettings()
        updateConfigList() -- Обновляем список после сохранения
    end
end)

pConfig:addButton("Load Selected", function()
    if selectedConfig ~= "" then
        local success, message = loadConfig(selectedConfig)
        print(message)
    else
        print("Выберите конфиг для загрузки")
    end
end)

pConfig:addButton("Delete Selected", function()
    if selectedConfig ~= "" then
        local success, message = deleteConfig(selectedConfig)
        print(message)
        if success then
            selectedConfig = ""
            getgenv().aim_settings.config_name = "" -- Очищаем поле
            refreshUIFromSettings()
            updateConfigList() -- Обновляем список после удаления
        end
    else
        print("Выберите конфиг для удаления")
    end
end)

-- Список конфигов в ScrollingFrame
local configScrollFrame = Instance.new("ScrollingFrame")
configScrollFrame.Size = UDim2.new(1, -10, 0, 200)
configScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
configScrollFrame.BorderSizePixel = 0
configScrollFrame.ScrollBarThickness = 4
configScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
configScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

Instance.new("UICorner", configScrollFrame).CornerRadius = UDim.new(0, 8)

local configLayout = Instance.new("UIListLayout", configScrollFrame)
configLayout.SortOrder = Enum.SortOrder.LayoutOrder
configLayout.Padding = UDim.new(0, 2)

-- Добавляем ScrollingFrame в категорию как кастомный элемент
pConfig:addCustomElement(configScrollFrame)

-- Функция для обновления списка конфигов
updateConfigList = function()
    -- Очищаем старый список
    for _, child in pairs(configScrollFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local configs = getConfigsList()
    
    for i, config in ipairs(configs) do
        local item = Instance.new("TextButton")
        item.Parent = configScrollFrame
        item.Size = UDim2.new(1, -10, 0, 40)
        item.BackgroundColor3 = (selectedConfig == config.encoded)
            and getClientColor()
            or Color3.fromRGB(45, 45, 55)
        item.Text = ""
        item.AutoButtonColor = false
        item.LayoutOrder = i
        
        local itemCorner = Instance.new("UICorner")
        itemCorner.Parent = item
        itemCorner.CornerRadius = UDim.new(0, 6)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Parent = item
        nameLabel.Size = UDim2.new(1, -10, 0.6, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 2)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = config.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 11
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local dateLabel = Instance.new("TextLabel")
        dateLabel.Parent = item
        dateLabel.Size = UDim2.new(1, -10, 0.4, 0)
        dateLabel.Position = UDim2.new(0, 5, 0.6, 0)
        dateLabel.BackgroundTransparency = 1
        dateLabel.Text = os.date("%d.%m %H:%M", config.timestamp)
        dateLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        dateLabel.Font = Enum.Font.Gotham
        dateLabel.TextSize = 9
        dateLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Обработчик клика
        item.MouseButton1Click:Connect(function()
            selectedConfig = config.encoded
            
            -- Сброс цветов
            for _, otherItem in pairs(configScrollFrame:GetChildren()) do
                if otherItem:IsA("TextButton") then
                    otherItem.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
                end
            end
            
            -- Подсветка выбранного
            item.BackgroundColor3 = getClientColor()
            
            -- Обновляем имя конфига
            getgenv().aim_settings.config_name = config.name
            refreshUIFromSettings()
        end)
    end
    
    -- Обновляем размер canvas
    configScrollFrame.CanvasSize = UDim2.new(
        0,
        0,
        0,
        configLayout.AbsoluteContentSize.Y + 10
    )
end

-- Кнопка для обновления списка
pConfig:addButton("Refresh List", function()
    updateConfigList()
end)

table.insert(panels, pConfig)

-- Создаем тестовые конфиги
-- 6. CHAT PANEL (простой чат в левом нижнем углу)
spawn(function()
    wait(1.2)
    reloadConfigsFromDisk()
    updateConfigList()
end)

local ChatPanel = Instance.new("Frame", ScreenGui)
ChatPanel.Name = "ChatPanel"
ChatPanel.Size = UDim2.new(0, 350, 0, 400)
ChatPanel.Position = UDim2.new(0, 20, 1, -420)
ChatPanel.BackgroundColor3 = THEME.PANEL_BG
ChatPanel.BorderSizePixel = 0
ChatPanel.Visible = false -- Скрыт по умолчанию

Instance.new("UICorner", ChatPanel).CornerRadius = UDim.new(0, 12)

local chatPanelStroke = Instance.new("UIStroke", ChatPanel)
chatPanelStroke.Color = THEME.PANEL_STROKE
chatPanelStroke.Thickness = 2

-- Заголовок чата
local ChatHeader = Instance.new("Frame", ChatPanel)
ChatHeader.Size = UDim2.new(1, 0, 0, 40)
ChatHeader.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ChatHeader.BorderSizePixel = 0

local chatHeaderCorner = Instance.new("UICorner", ChatHeader)
chatHeaderCorner.CornerRadius = UDim.new(0, 12)

local ChatTitle = Instance.new("TextLabel", ChatHeader)
ChatTitle.Size = UDim2.new(1, -80, 1, 0)
ChatTitle.Position = UDim2.new(0, 15, 0, 0)
ChatTitle.BackgroundTransparency = 1
ChatTitle.Text = "Global Chat"
ChatTitle.TextColor3 = THEME.TEXT_TITLE
ChatTitle.Font = Enum.Font.GothamBold
ChatTitle.TextSize = 16
ChatTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Кнопка скрыть/показать
local ChatToggle = Instance.new("TextButton", ChatHeader)
ChatToggle.Size = UDim2.new(0, 30, 0, 30)
ChatToggle.Position = UDim2.new(1, -35, 0.5, -15)
ChatToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
ChatToggle.Text = "−"
ChatToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatToggle.Font = Enum.Font.GothamBold
ChatToggle.TextSize = 16
ChatToggle.AutoButtonColor = false

local chatToggleCorner = Instance.new("UICorner", ChatToggle)
chatToggleCorner.CornerRadius = UDim.new(0, 6)

-- Область сообщений
local ChatMessages = Instance.new("ScrollingFrame", ChatPanel)
ChatMessages.Size = UDim2.new(1, -10, 1, -90)
ChatMessages.Position = UDim2.new(0, 5, 0, 45)
ChatMessages.BackgroundTransparency = 1
ChatMessages.BorderSizePixel = 0
ChatMessages.ScrollBarThickness = 4
ChatMessages.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ChatMessages.CanvasSize = UDim2.new(0, 0, 0, 0)

local chatMessagesLayout = Instance.new("UIListLayout", ChatMessages)
chatMessagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
chatMessagesLayout.Padding = UDim.new(0, 5)

-- Поле ввода
local ChatInputFrame = Instance.new("Frame", ChatPanel)
ChatInputFrame.Size = UDim2.new(1, -10, 0, 35)
ChatInputFrame.Position = UDim2.new(0, 5, 1, -40)
ChatInputFrame.BackgroundColor3 = THEME.MODULE_BG
ChatInputFrame.BorderSizePixel = 0

local chatInputCorner = Instance.new("UICorner", ChatInputFrame)
chatInputCorner.CornerRadius = UDim.new(0, 8)

local ChatInput = Instance.new("TextBox", ChatInputFrame)
ChatInput.Size = UDim2.new(1, -70, 1, -6)
ChatInput.Position = UDim2.new(0, 8, 0, 3)
ChatInput.BackgroundTransparency = 1
ChatInput.Text = ""
ChatInput.PlaceholderText = "Type a message..."
ChatInput.TextColor3 = THEME.TEXT_TITLE
ChatInput.PlaceholderColor3 = THEME.TEXT_DIM
ChatInput.Font = Enum.Font.Gotham
ChatInput.TextSize = 12
ChatInput.TextXAlignment = Enum.TextXAlignment.Left

local ChatSendBtn = Instance.new("TextButton", ChatInputFrame)
ChatSendBtn.Size = UDim2.new(0, 55, 1, -6)
ChatSendBtn.Position = UDim2.new(1, -58, 0, 3)
ChatSendBtn.BackgroundColor3 = getClientColor()
ChatSendBtn.Text = "Send"
ChatSendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ChatSendBtn.Font = Enum.Font.GothamBold
ChatSendBtn.TextSize = 11
ChatSendBtn.AutoButtonColor = false

local chatSendCorner = Instance.new("UICorner", ChatSendBtn)
chatSendCorner.CornerRadius = UDim.new(0, 6)

-- Переменные для чата
local chatMessages = {}
local chatVisible = false

-- Функция для добавления сообщения в чат
local function addChatMessage(username, message, isOwn, timestamp)
    local messageFrame = Instance.new("Frame", ChatMessages)
    messageFrame.Size = UDim2.new(1, -10, 0, 0) -- Высота будет автоматически подогнана
    messageFrame.BackgroundTransparency = 1
    messageFrame.LayoutOrder = #chatMessages + 1
    
    -- Определяем цвет и выравнивание
    local messageColor = isOwn and getClientColor() or THEME.MODULE_BG
    local textAlign = isOwn and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    
    -- Создаем текст сообщения
    local messageText = Instance.new("TextLabel", messageFrame)
    messageText.Size = UDim2.new(1, 0, 0, 0)
    messageText.BackgroundColor3 = messageColor
    messageText.BorderSizePixel = 0
    messageText.Text = (isOwn and "" or username .. ": ") .. message
    messageText.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageText.Font = Enum.Font.Gotham
    messageText.TextSize = 11
    messageText.TextXAlignment = textAlign
    messageText.TextYAlignment = Enum.TextYAlignment.Top
    messageText.TextWrapped = true
    
    local messageCorner = Instance.new("UICorner", messageText)
    messageCorner.CornerRadius = UDim.new(0, 8)
    
    local messagePadding = Instance.new("UIPadding", messageText)
    messagePadding.PaddingLeft = UDim.new(0, 8)
    messagePadding.PaddingRight = UDim.new(0, 8)
    messagePadding.PaddingTop = UDim.new(0, 4)
    messagePadding.PaddingBottom = UDim.new(0, 4)
    
    -- Вычисляем высоту текста
    local textBounds = game:GetService("TextService"):GetTextSize(
        messageText.Text,
        messageText.TextSize,
        messageText.Font,
        Vector2.new(messageText.AbsoluteSize.X - 16, math.huge)
    )
    
    local messageHeight = math.max(25, textBounds.Y + 8)
    messageFrame.Size = UDim2.new(1, -10, 0, messageHeight)
    messageText.Size = UDim2.new(1, 0, 1, 0)
    
    -- Позиционируем сообщение
    if isOwn then
        messageText.Position = UDim2.new(0.3, 0, 0, 0)
        messageText.Size = UDim2.new(0.7, -5, 1, 0)
    else
        messageText.Position = UDim2.new(0, 0, 0, 0)
        messageText.Size = UDim2.new(0.7, 0, 1, 0)
    end
    
    -- Сохраняем данные сообщения с timestamp
    local msgData = {
        frame = messageFrame, 
        text = messageText, 
        timestamp = timestamp or os.time(),
        username = username,
        message = message,
        isOwn = isOwn
    }
    table.insert(chatMessages, msgData)
    
    -- Обновляем размер canvas и прокручиваем вниз
    ChatMessages.CanvasSize = UDim2.new(0, 0, 0, chatMessagesLayout.AbsoluteContentSize.Y)
    ChatMessages.CanvasPosition = Vector2.new(0, ChatMessages.AbsoluteCanvasSize.Y)
end

-- Функция отправки сообщения (мгновенная)
local function sendChatMessage()
    if not getgenv().aim_settings.chat_enabled then return end -- Проверяем настройку
    
    local message = ChatInput.Text:gsub("^%s*(.-)%s*$", "%1") -- Убираем пробелы
    if message ~= "" then
        -- Добавляем сообщение локально сразу
        addChatMessage(LocalPlayer.Name, message, true, os.time())
        
        -- Очищаем поле ввода
        ChatInput.Text = ""
        
        -- Отправляем на сервер в фоне (без ожидания)
        spawn(function()
            sendMessage(message)
            -- Через секунду проверяем новые сообщения для синхронизации
            wait(1)
            if chatVisible and getgenv().aim_settings.chat_enabled then
                loadServerMessages()
            end
        end)
    end
end

-- События для чата
ChatSendBtn.MouseButton1Click:Connect(sendChatMessage)
ChatInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        sendChatMessage()
    end
end)

-- Переключение видимости чата
ChatToggle.MouseButton1Click:Connect(function()
    -- Проверяем, включен ли чат в настройках
    if not getgenv().aim_settings.chat_enabled then
        return -- Не позволяем переключать если чат выключен в настройках
    end
    
    chatVisible = not chatVisible
    ChatPanel.Visible = chatVisible
    ChatToggle.Text = chatVisible and "−" or "+"
    
    -- Загружаем сообщения при открытии чата
    if chatVisible and #chatMessages == 0 then
        loadAllMessages()
    end
end)

-- Показываем чат при открытии меню
local originalAnimatePanels = animatePanels
animatePanels = function(show)
    originalAnimatePanels(show)
    if show and getgenv().aim_settings.chat_enabled then
        ChatPanel.Visible = true
        chatVisible = true
        ChatToggle.Text = "−"
        -- Загружаем все сообщения при первом открытии
        if #chatMessages == 0 then
            loadAllMessages()
        end
    else
        ChatPanel.Visible = false
        chatVisible = false
    end
end

-- Функция для загрузки сообщений с сервера
local function loadServerMessages()
    if not chatVisible or not getgenv().aim_settings.chat_enabled then return end
    
    spawn(function()
        local serverMessages = fetchMessages()
        if not serverMessages then return end
        
        -- Фильтруем только глобальные сообщения
        local globalMessages = {}
        for _, msg in pairs(serverMessages) do
            if not msg.chat or msg.chat == "global" then
                table.insert(globalMessages, msg)
            end
        end
        
        -- Сортируем по времени
        table.sort(globalMessages, function(a, b)
            return (a.timestamp or 0) < (b.timestamp or 0)
        end)
        
        -- Проверяем, есть ли новые сообщения
        local lastMessageTime = 0
        if #chatMessages > 0 then
            -- Находим время последнего сообщения
            for _, msgData in pairs(chatMessages) do
                if msgData.timestamp and msgData.timestamp > lastMessageTime then
                    lastMessageTime = msgData.timestamp
                end
            end
        end
        
        -- Добавляем только новые сообщения
        local newMessagesAdded = false
        for _, msg in pairs(globalMessages) do
            local msgTime = msg.timestamp or 0
            if msgTime > lastMessageTime then
                local isOwn = msg.userid == LocalPlayer.UserId
                -- Добавляем все новые сообщения (включая свои с сервера для синхронизации)
                addChatMessage(msg.username or "Unknown", msg.message or "", isOwn, msgTime)
                newMessagesAdded = true
            end
        end
        
        -- Если добавили новые сообщения, прокручиваем вниз
        if newMessagesAdded then
            ChatMessages.CanvasPosition = Vector2.new(0, ChatMessages.AbsoluteCanvasSize.Y)
        end
    end)
end

-- Функция для первоначальной загрузки всех сообщений
local function loadAllMessages()
    if not chatVisible or not getgenv().aim_settings.chat_enabled then return end
    
    spawn(function()
        local serverMessages = fetchMessages()
        if not serverMessages then return end
        
        -- Очищаем старые сообщения
        for _, msgData in pairs(chatMessages) do
            if msgData.frame and msgData.frame.Parent then
                msgData.frame:Destroy()
            end
        end
        chatMessages = {}
        
        -- Фильтруем только глобальные сообщения
        local globalMessages = {}
        for _, msg in pairs(serverMessages) do
            if not msg.chat or msg.chat == "global" then
                table.insert(globalMessages, msg)
            end
        end
        
        -- Сортируем по времени
        table.sort(globalMessages, function(a, b)
            return (a.timestamp or 0) < (b.timestamp or 0)
        end)
        
        -- Показываем только последние 50 сообщений для производительности
        local startIndex = math.max(1, #globalMessages - 49)
        for i = startIndex, #globalMessages do
            local msg = globalMessages[i]
            local isOwn = msg.userid == LocalPlayer.UserId
            addChatMessage(msg.username or "Unknown", msg.message or "", isOwn, msg.timestamp)
        end
        
        -- Прокручиваем вниз
        ChatMessages.CanvasPosition = Vector2.new(0, ChatMessages.AbsoluteCanvasSize.Y)
    end)
end

-- Быстрое обновление сообщений (каждые 3 секунды)
spawn(function()
    while getgenv().aim_settings.running do
        wait(3)
        if chatVisible and getgenv().aim_settings.chat_enabled then
            loadServerMessages()
        end
    end
end)

-- Сохраняем оригинальные позиции панелей и устанавливаем начальные позиции внизу экрана
for i, panel in ipairs(panels) do
    panelOriginalPositions[i] = panel.frame.Position
    panelTargetPositions[i] = panel.frame.Position
    -- Устанавливаем панели внизу экрана (невидимые)
    panel.frame.Position = UDim2.new(0, panel.frame.Position.X.Offset, 1, 100)
end

-- Устанавливаем начальное состояние GUI
ScreenGui.Enabled = false
panelAnimationState = "hidden"

-- Если нужно показать GUI при запуске, поменяйте условие на true
if false then
    animatePanels(true)
end

-- [[ AIMBOT LOGIC ]]
local renderState = {
    hue = 0,
    crosshairHue = 0,
    lastFrameTime = tick()
}

-- [[ OPTIMIZATION SETTINGS ]]
local OPTIMIZATION = {
    UPDATE_INTERVAL = 1/60, -- Обновлять некоторые вещи 60 раз в секунду
    HITBOX_UPDATE_INTERVAL = 1/30, -- Хитбоксы 30 раз в секунду
    COLOR_CHECK_INTERVAL = 0.1, -- Проверка цвета 10 раз в секунду
}

local lastHitboxUpdate = 0
local lastColorCheck = 0

RunService.RenderStepped:Connect(function()
    if not getgenv().aim_settings.running then return end
    
    local currentTime = tick()
    local deltaTime = currentTime - renderState.lastFrameTime
    renderState.lastFrameTime = currentTime
    
    -- Обновляем анимацию панелей
    updatePanelAnimation(deltaTime)
    
    -- Обновляем цвета только при изменении client_color (оптимизировано)
    if currentTime - lastColorCheck >= OPTIMIZATION.COLOR_CHECK_INTERVAL then
        local currentClientColor = getClientColor()
        if currentClientColor ~= lastClientColor then
            updateAllColors()
        end
        lastColorCheck = currentTime
    end
    
    -- Update hitboxes (оптимизировано - 30 FPS вместо 60+)
    if currentTime - lastHitboxUpdate >= OPTIMIZATION.HITBOX_UPDATE_INTERVAL then
        updateHitboxes()
        lastHitboxUpdate = currentTime
    end
    
    -- Update TP Walk
    updateTPWalk()
    
    -- Update panels (только если GUI открыт)
    if ScreenGui.Enabled then
        for _, panel in ipairs(panels) do
            panel:update()
        end
    end
    
    -- Show/Hide Trollface options (оптимизировано - кэшируем результат)
    if ScreenGui.Enabled then
        local isTrollface = getgenv().aim_settings.clickgui_image_mode == "trollface"
        for _, panel in ipairs(panels) do
            for _, module in ipairs(panel.modules) do
                if module.settingKey == "trollface_animate" or module.settingKey == "trollface_music" or module.settingKey == "trollface_volume" then
                    if module.container.Visible ~= isTrollface then
                        module.container.Visible = isTrollface
                    end
                end
            end
        end
    end
    
    -- Update Chat visibility (только если GUI открыт)
    if ScreenGui.Enabled then
        local shouldShowChat = getgenv().aim_settings.chat_enabled
        if ChatPanel.Visible ~= shouldShowChat then
            ChatPanel.Visible = shouldShowChat
            chatVisible = shouldShowChat
            if shouldShowChat then
                ChatToggle.Text = "−"
                if #chatMessages == 0 then
                    loadAllMessages()
                end
            else
                ChatToggle.Text = "+"
            end
        end
    end
    
    -- Update TargetHud dragging
    if targetHudDragging then
        local mouse = UserInputService:GetMouseLocation()
        local delta = Vector2.new(mouse.X - targetHudDragStart.X, mouse.Y - targetHudDragStart.Y)
        TargetHudFrame.Position = UDim2.new(
            0,
            targetHudStartPos.X.Offset + delta.X,
            0,
            targetHudStartPos.Y.Offset + delta.Y
        )
    end
    
    -- Rainbow FOV
    if getgenv().aim_settings.rainbow_fov then
        renderState.hue = renderState.hue + 0.005
        FOVCircle.Color = Color3.fromHSV(renderState.hue % 1, 0.7, 1)
    else
        FOVCircle.Color = getClientColor()
    end
    
    -- Rainbow Crosshair (цвет будет применяться к BillboardGui крестику)
    
    -- Target ESP Rotation Animation
    targetRotation = targetRotation + (3 * rotationDirection)
    if targetRotation >= 359 then
        rotationDirection = -1
    elseif targetRotation <= -359 then
        rotationDirection = 1
    end
    
    -- FOV Circle
    FOVCircle.Visible = getgenv().aim_settings.enabled
    FOVCircle.Radius = getgenv().aim_settings.fov
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    -- Target ESP (создается на игроке через BillboardGui)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            -- Определяем часть тела для Target ESP в зависимости от hitbox
            local targetPart
            if getgenv().aim_settings.hitbox == "Head" then
                targetPart = p.Character:FindFirstChild("Head")
            else
                targetPart = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
            end
            
            local head = p.Character:FindFirstChild("Head")
            if targetPart then
                local targetESP = targetPart:FindFirstChild("Y_Target_ESP")
                
                -- Показываем ESP только на заблокированной цели
                if getgenv().aim_settings.target_esp and LockedTarget and LockedTarget.Parent == p.Character then
                    if not targetESP then
                        -- Создаем BillboardGui для Target ESP
                        targetESP = Instance.new("BillboardGui", targetPart)
                        targetESP.Name = "Y_Target_ESP"
                        targetESP.Size = UDim2.new(0, 100, 0, 100)
                        targetESP.StudsOffset = Vector3.new(0, 0, 0)
                        targetESP.AlwaysOnTop = true
                        
                        -- Контейнер для вращения
                        local container = Instance.new("Frame", targetESP)
                        container.Name = "Container"
                        container.Size = UDim2.new(1, 0, 1, 0)
                        container.Position = UDim2.new(0.5, 0, 0.5, 0)
                        container.AnchorPoint = Vector2.new(0.5, 0.5)
                        container.BackgroundTransparency = 1
                        
                        -- Crosshair Mode - Горизонтальная линия
                        local lineH = Instance.new("Frame", container)
                        lineH.Name = "LineH"
                        lineH.Size = UDim2.new(0, 20, 0, 2)
                        lineH.Position = UDim2.new(0.5, 0, 0.5, 0)
                        lineH.AnchorPoint = Vector2.new(0.5, 0.5)
                        lineH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        lineH.BorderSizePixel = 0
                        local lineHGradient = Instance.new("UIGradient", lineH)
                        lineHGradient.Name = "LineGradient"
                        lineHGradient.Rotation = 0
                        
                        -- Crosshair Mode - Вертикальная линия
                        local lineV = Instance.new("Frame", container)
                        lineV.Name = "LineV"
                        lineV.Size = UDim2.new(0, 2, 0, 20)
                        lineV.Position = UDim2.new(0.5, 0, 0.5, 0)
                        lineV.AnchorPoint = Vector2.new(0.5, 0.5)
                        lineV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        lineV.BorderSizePixel = 0
                        local lineVGradient = Instance.new("UIGradient", lineV)
                        lineVGradient.Name = "LineGradient"
                        lineVGradient.Rotation = 90
                        
                        -- Circle Mode - Картинка с градиентом
                        local circleImage = Instance.new("ImageLabel", container)
                        circleImage.Name = "CircleImage"
                        circleImage.Size = UDim2.new(0, 80, 0, 80)
                        circleImage.Position = UDim2.new(0.5, 0, 0.5, 0)
                        circleImage.AnchorPoint = Vector2.new(0.5, 0.5)
                        circleImage.BackgroundTransparency = 1
                        circleImage.Image = "rbxassetid://77511689678153"
                        circleImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        circleImage.Visible = false
                        
                        -- Добавляем UIGradient для эффекта градиента как в Квадрате
                        local circleGradient = Instance.new("UIGradient", circleImage)
                        circleGradient.Name = "CircleGradient"
                        circleGradient.Rotation = 0
                        circleGradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
                        })
                    end
                    
                    targetESP.Enabled = true
                    local container = targetESP:FindFirstChild("Container")
                    
                    if container then
                        local gradientColor1
                        local gradientColor2
                        if getgenv().aim_settings.rainbow_crosshair then
                            renderState.crosshairHue = renderState.crosshairHue + 0.005
                            gradientColor1 = Color3.fromHSV(renderState.crosshairHue % 1, 0.7, 1)
                            gradientColor2 = Color3.fromHSV((renderState.crosshairHue + 0.25) % 1, 0.7, 1)
                        else
                            local clientColor = getClientColor()
                            gradientColor1 = tintColor(clientColor, 0.82, 0)
                            gradientColor2 = tintColor(clientColor, 1, 0)
                        end
                        local espGradient = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, gradientColor1),
                            ColorSequenceKeypoint.new(1, gradientColor2)
                        })

                        -- Переключение между режимами
                        if getgenv().aim_settings.target_esp_mode == "Circle" then
                            -- Circle Mode
                            container.LineH.Visible = false
                            container.LineV.Visible = false
                            container.CircleImage.Visible = true
                            
                            -- Вращение картинки как в режиме Квадрат (используем sin для плавности)
                            local sin = math.sin(tick() / 1.0)
                            container.Rotation = sin * 360
                            
                            -- Применяем градиентные цвета как в Квадрате
                            local gradient = container.CircleImage:FindFirstChild("CircleGradient")
                            if gradient then
                                gradient.Color = espGradient
                                container.CircleImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
                            end
                        else
                            -- Crosshair Mode
                            container.LineH.Visible = true
                            container.LineV.Visible = true
                            container.CircleImage.Visible = false
                            container.Rotation = 0

                            container.LineH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            container.LineV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            local lineHGradient = container.LineH:FindFirstChild("LineGradient")
                            local lineVGradient = container.LineV:FindFirstChild("LineGradient")
                            if lineHGradient then
                                lineHGradient.Color = espGradient
                            end
                            if lineVGradient then
                                lineVGradient.Color = espGradient
                            end
                        end
                    end
                else
                    -- Скрываем ESP если это не цель
                    if targetESP then
                        targetESP.Enabled = false
                    end
                end
                
                -- Очищаем старый Target ESP с другой части тела при смене hitbox
                if getgenv().aim_settings.hitbox == "Head" then
                    local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
                    if torso and torso:FindFirstChild("Y_Target_ESP") then
                        torso.Y_Target_ESP:Destroy()
                    end
                else
                    if head and head:FindFirstChild("Y_Target_ESP") then
                        head.Y_Target_ESP:Destroy()
                    end
                end
            end
        end
    end
    
    -- ESP Logic
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isFriendPlayer = isFriend(p.Name)
            
            -- Highlight (подсветка игрока)
            local hl = p.Character:FindFirstChild("Y_ESP") or Instance.new("Highlight", p.Character)
            hl.Name = "Y_ESP"
            hl.Enabled = getgenv().aim_settings.esp_enabled
            local color = (getgenv().aim_settings.esp_mode == "White" and Color3.new(1,1,1) or Color3.new(0,0,0))
            hl.FillColor = color
            hl.OutlineColor = (getgenv().aim_settings.esp_mode == "White" and Color3.new(0,0,0) or Color3.new(1,1,1))
            hl.FillTransparency = 0.5
            
            -- ESP Text Info
            local head = p.Character:FindFirstChild("Head")
            if head then
                -- Создаем или находим BillboardGui
                local billboardGui = head:FindFirstChild("Y_ESP_Text")
                if not billboardGui then
                    billboardGui = Instance.new("BillboardGui", head)
                    billboardGui.Name = "Y_ESP_Text"
                    billboardGui.Size = UDim2.new(0, 200, 0, 100)
                    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
                    billboardGui.AlwaysOnTop = true
                end
                
                -- Текст показывается только когда ESP включен И Chams выключен
                billboardGui.Enabled = getgenv().aim_settings.esp_enabled and not getgenv().aim_settings.esp_chams
                
                -- Создаем или находим TextLabel
                local textLabel = billboardGui:FindFirstChild("TextLabel")
                if not textLabel then
                    textLabel = Instance.new("TextLabel", billboardGui)
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Font = Enum.Font.GothamBold
                    textLabel.TextSize = 14
                    textLabel.TextStrokeTransparency = 0.5
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                
                -- Обновляем текст
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    local distance = math.floor((head.Position - Camera.CFrame.Position).Magnitude)
                    local health = math.floor(hum.Health)
                    local maxHealth = math.floor(hum.MaxHealth)
                    textLabel.Text = p.Name .. "\n" .. health .. "/" .. maxHealth .. " HP\n" .. distance .. " studs"
                end
                
                -- Friend Marker (как в Sims - зеленый ромб над головой)
                local friendMarker = head:FindFirstChild("Y_Friend_Marker")
                if getgenv().aim_settings.friend_markers and isFriendPlayer then
                    if not friendMarker then
                        friendMarker = Instance.new("BillboardGui", head)
                        friendMarker.Name = "Y_Friend_Marker"
                        friendMarker.Size = UDim2.new(0, 40, 0, 30)
                        friendMarker.StudsOffset = Vector3.new(0, 3, 0)
                        friendMarker.AlwaysOnTop = true
                        
                        -- Ромб (повернутый квадрат)
                        local diamond = Instance.new("Frame", friendMarker)
                        diamond.Size = UDim2.new(0, 22, 0, 22)
                        diamond.Position = UDim2.new(0.5, -11, 0.5, -11)
                        diamond.AnchorPoint = Vector2.new(0.5, 0.5)
                        diamond.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                        diamond.BorderSizePixel = 0
                        diamond.Rotation = 45
                        
                        local diamondStroke = Instance.new("UIStroke", diamond)
                        diamondStroke.Color = Color3.fromRGB(50, 200, 50)
                        diamondStroke.Thickness = 2
                    end
                    friendMarker.Enabled = true
                else
                    if friendMarker then
                        friendMarker.Enabled = false
                    end
                end
            end
        end
    end
    
    -- Speed Display
    SpeedLabel.Visible = getgenv().aim_settings.speed_display
    if getgenv().aim_settings.speed_display and LockedTarget and LockedTarget.Parent then
        local character = LockedTarget.Parent
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local player = Players:GetPlayerFromCharacter(character)
        
        if humanoid and humanoid.Health > 0 and player then
            local velocity = LockedTarget.Velocity
            local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
            local speed = math.floor(horizontalVelocity.Magnitude * 10) / 10
            SpeedLabel.Text = "Target Speed: " .. speed .. " studs/s"
            SpeedLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            SpeedLabel.Text = "Target Speed: N/A"
            SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    else
        SpeedLabel.Text = "Target Speed: N/A"
        SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    
    -- Keybind List Display
    KeybindList.Visible = getgenv().aim_settings.hud_enabled and getgenv().aim_settings.keybind_list_enabled
    if getgenv().aim_settings.hud_enabled and getgenv().aim_settings.keybind_list_enabled then
        -- Удаляем старые элементы
        for _, item in pairs(keybindItems) do
            if item then item:Destroy() end
        end
        keybindItems = {}
        
        local orderIndex = 3
        local bindEntries = getVisibleKeybindEntries()
        -- Добавляем активные кейбинды
        for _, bindEntry in ipairs(bindEntries) do
            local keyCode = bindEntry.keyCode
            if keyCode ~= Enum.KeyCode.Unknown then
                local item = Instance.new("Frame", KeybindList)
                item.Size = UDim2.new(1, -16, 0, 20)
                item.BackgroundTransparency = 1
                item.LayoutOrder = orderIndex
                orderIndex = orderIndex + 1
                
                local nameLbl = Instance.new("TextLabel", item)
                nameLbl.Size = UDim2.new(0.6, 0, 1, 0)
                nameLbl.Position = UDim2.new(0, 0, 0, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.Text = bindEntry.name
                nameLbl.TextColor3 = THEME.TEXT_DIM
                nameLbl.Font = Enum.Font.Gotham
                nameLbl.TextSize = 11
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                
                local keyLbl = Instance.new("TextLabel", item)
                keyLbl.Size = UDim2.new(0.4, 0, 1, 0)
                keyLbl.Position = UDim2.new(0.6, 0, 0, 0)
                keyLbl.BackgroundTransparency = 1
                keyLbl.Text = "[" .. getKeyName(keyCode) .. "]"
                keyLbl.TextColor3 = getClientColor()
                keyLbl.Font = Enum.Font.GothamBold
                keyLbl.TextSize = 11
                keyLbl.TextXAlignment = Enum.TextXAlignment.Right
                
                table.insert(keybindItems, item)
            end
        end
        
        -- Обновляем размер панели
        tween(KeybindList, {Size = UDim2.new(0, 180, 0, keybindLayout.AbsoluteContentSize.Y + 10)}, 0.2)
    end
    
    -- Arrows Display
    ArrowsContainer.Visible = getgenv().aim_settings.arrows
    if getgenv().aim_settings.arrows then
        -- Анимация радиуса от центра
        targetAnimationStep = getgenv().aim_settings.arrows_radius
        animationStep = animationStep + (targetAnimationStep - animationStep) * 0.1
        local arrowSize = getgenv().aim_settings.arrows_size
        
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local activePlayers = {}
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head then
                    activePlayers[p.Name] = true
                    
                    -- Вычисляем направление игрока относительно текущего направления камеры
                    local cameraCFrame = Camera.CFrame
                    local relative = head.Position - cameraCFrame.Position
                    local flatRelative = Vector3.new(relative.X, 0, relative.Z)
                    
                    if flatRelative.Magnitude <= 0.001 then
                        continue
                    end
                    
                    local flatDirection = flatRelative.Unit
                    local cameraForward = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z)
                    local cameraRight = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z)
                    
                    if cameraForward.Magnitude <= 0.001 or cameraRight.Magnitude <= 0.001 then
                        continue
                    end
                    
                    cameraForward = cameraForward.Unit
                    cameraRight = cameraRight.Unit
                    
                    local arrowDirection = Vector2.new(
                        cameraRight:Dot(flatDirection),
                        -cameraForward:Dot(flatDirection)
                    )
                    
                    if arrowDirection.Magnitude <= 0.001 then
                        arrowDirection = Vector2.new(0, -1)
                    else
                        arrowDirection = arrowDirection.Unit
                    end
                    
                    local angle = math.deg(math.atan2(arrowDirection.Y, arrowDirection.X))
                    local x2 = screenCenter.X + (arrowDirection.X * animationStep)
                    local y2 = screenCenter.Y + (arrowDirection.Y * animationStep)
                    
                    -- Ищем или создаем стрелку для этого игрока
                    local arrowName = "Arrow_" .. p.Name
                    local arrow = ArrowsContainer:FindFirstChild(arrowName)
                    
                    if not arrow then
                        -- Создаем НОВУЮ стрелку только если её нет
                        arrow = Instance.new("ImageLabel", ArrowsContainer)
                        arrow.Name = arrowName
                        arrow.Size = UDim2.new(0, arrowSize, 0, arrowSize)
                        arrow.AnchorPoint = Vector2.new(0.5, 0.5)
                        arrow.BackgroundTransparency = 1
                        arrow.Image = "rbxassetid://104609059217889"
                        arrow.ImageTransparency = 0.2
                        
                        arrow.ImageColor3 = getClientColor()
                    end
                    
                    local gradient = arrow:FindFirstChildOfClass("UIGradient")
                    if gradient then
                        gradient:Destroy()
                    end
                    
                    arrow.Size = UDim2.new(0, arrowSize, 0, arrowSize)
                    arrow.ImageColor3 = getClientColor()
                    arrow.Position = UDim2.new(0, x2, 0, y2)
                    arrow.Rotation = angle + 90
                end
            end
        end
        
        -- Удаляем стрелки для игроков которых больше нет
        for _, child in pairs(ArrowsContainer:GetChildren()) do
            if child:IsA("ImageLabel") and child.Name:match("^Arrow_") then
                local playerName = child.Name:gsub("^Arrow_", "")
                if not activePlayers[playerName] then
                    child:Destroy()
                end
            end
        end
    else
        -- Очищаем все стрелки когда Arrows выключен
        for _, child in pairs(ArrowsContainer:GetChildren()) do
            if child:IsA("ImageLabel") then
                child:Destroy()
            end
        end
    end
    
    -- Watermark Display
    WatermarkFrame.Visible = getgenv().aim_settings.hud_enabled and getgenv().aim_settings.watermark_enabled
    
    if getgenv().aim_settings.hud_enabled and getgenv().aim_settings.watermark_enabled then
        local currentTime = tick()
        local dt = RunService.RenderStepped:Wait()
        
        -- Обновляем FPS и Ping раз в секунду
        if currentTime - lastUpdateTime >= 1.0 then
            lastUpdateTime = currentTime
            
            -- Получаем новые значения
            local newFPS = math.floor(1 / dt)
            local newPing = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            
            -- Запускаем анимацию только если значения изменились
            if newFPS ~= currentFPS then
                currentFPS = newFPS
                fpsAnimProgress = 0
            end
            
            if newPing ~= currentPing then
                currentPing = newPing
                pingAnimProgress = 0
            end
        end
        
        -- Обновляем прогресс анимации (быстро в начале, медленно в конце)
        local animSpeed = 3.0 -- Скорость анимации
        if fpsAnimProgress < 1 then
            fpsAnimProgress = math.min(fpsAnimProgress + dt * animSpeed, 1)
        end
        if pingAnimProgress < 1 then
            pingAnimProgress = math.min(pingAnimProgress + dt * animSpeed, 1)
        end
        
        -- Анимируем отображаемые значения
        displayFPS = animateNumber(displayFPS, currentFPS, fpsAnimProgress)
        displayPing = animateNumber(displayPing, currentPing, pingAnimProgress)
        
        -- Обновляем текст с анимированными значениями
        FPSLabel.Text = displayFPS .. "fps"
        PingLabel.Text = displayPing .. "ms"
        
        -- Вращающийся градиент
        local rotationSpeed = 30
        watermarkRotation = (watermarkRotation + rotationSpeed * dt) % 360
        clientGradient.Rotation = watermarkRotation
        
        -- Динамический цвет градиента
        local baseColor = getClientColor()
        clientGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, baseColor),
            ColorSequenceKeypoint.new(1, baseColor:Lerp(Color3.new(1, 1, 1), 0.3))
        })
        
        -- Автоматический размер фрейма
        local totalWidth = ClientLabel.AbsoluteSize.X + NickLabel.AbsoluteSize.X + FPSLabel.AbsoluteSize.X + PingLabel.AbsoluteSize.X + 60
        WatermarkFrame.Size = UDim2.new(0, math.max(180, totalWidth), 0, 30)
    end
    
    -- Jump Circle Logic (только для локального игрока)
    if getgenv().aim_settings.jump_circle_enabled then
        local player = LocalPlayer
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            
            if humanoid and rootPart then
                local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping or 
                                humanoid:GetState() == Enum.HumanoidStateType.Freefall
                
                local playerKey = player.Name
                local wasJumping = lastJumpState[playerKey] or false
                
                -- Если игрок только что начал прыгать
                if isJumping and not wasJumping then
                    -- Находим землю под игроком с помощью Raycast
                    local rayOrigin = rootPart.Position
                    local rayDirection = Vector3.new(0, -100, 0) -- Луч вниз на 100 стадов
                    
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    raycastParams.FilterDescendantsInstances = {player.Character} -- Исключаем самого игрока
                    
                    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                    
                    if raycastResult then
                        -- Создаем плоский Part для круга на земле
                        local circlePart = Instance.new("Part", workspace)
                        circlePart.Name = "JumpCirclePart_" .. player.Name
                        circlePart.Size = Vector3.new(0.1, 0.01, 0.1) -- Начинаем с маленького размера
                        circlePart.Position = raycastResult.Position + Vector3.new(0, 0.02, 0) -- Чуть выше земли
                        circlePart.Anchored = true
                        circlePart.CanCollide = false
                        circlePart.Transparency = 1
                        circlePart.Material = Enum.Material.ForceField
                        circlePart.TopSurface = Enum.SurfaceType.Smooth
                        circlePart.BottomSurface = Enum.SurfaceType.Smooth
                        circlePart.Shape = Enum.PartType.Cylinder
                        
                        -- Поворачиваем цилиндр чтобы он лежал плоско (цилиндр по умолчанию вертикальный)
                        circlePart.CFrame = CFrame.new(raycastResult.Position + Vector3.new(0, 0.02, 0)) * CFrame.Angles(math.rad(90), 0, 0)
                        
                        -- Создаем SurfaceGui на верхней поверхности
                        local surfaceGui = Instance.new("SurfaceGui", circlePart)
                        surfaceGui.Face = Enum.NormalId.Front -- Для цилиндра Front это верхняя круглая поверхность
                        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
                        surfaceGui.PixelsPerStud = 50
                        
                        -- Создаем ImageLabel с картинкой
                        local imageLabel = Instance.new("ImageLabel", surfaceGui)
                        imageLabel.Size = UDim2.new(1, 0, 1, 0)
                        imageLabel.Position = UDim2.new(0, 0, 0, 0)
                        imageLabel.BackgroundTransparency = 1
                        imageLabel.Image = "rbxassetid://74083143980512"
                        imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        imageLabel.ImageTransparency = 1 -- Начинаем невидимым
                        
                        -- Создаем новый круг
                        local circle = {
                            player = player,
                            startTime = tick(),
                            circlePart = circlePart,
                            imageLabel = imageLabel,
                            phase = "appearing"
                        }
                        
                        table.insert(jumpCircles, circle)
                    else
                        -- Если земля не найдена, создаем круг под ногами игрока как fallback
                        local circlePart = Instance.new("Part", workspace)
                        circlePart.Name = "JumpCirclePart_" .. player.Name
                        circlePart.Size = Vector3.new(0.1, 0.01, 0.1)
                        circlePart.Position = rootPart.Position + Vector3.new(0, -2.9, 0)
                        circlePart.Anchored = true
                        circlePart.CanCollide = false
                        circlePart.Transparency = 1
                        circlePart.Material = Enum.Material.ForceField
                        circlePart.TopSurface = Enum.SurfaceType.Smooth
                        circlePart.BottomSurface = Enum.SurfaceType.Smooth
                        circlePart.Shape = Enum.PartType.Cylinder
                        
                        -- Поворачиваем цилиндр чтобы он лежал плоско
                        circlePart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, -2.9, 0)) * CFrame.Angles(math.rad(90), 0, 0)
                        
                        -- Создаем SurfaceGui на верхней поверхности
                        local surfaceGui = Instance.new("SurfaceGui", circlePart)
                        surfaceGui.Face = Enum.NormalId.Front
                        surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
                        surfaceGui.PixelsPerStud = 50
                        
                        -- Создаем ImageLabel с картинкой
                        local imageLabel = Instance.new("ImageLabel", surfaceGui)
                        imageLabel.Size = UDim2.new(1, 0, 1, 0)
                        imageLabel.Position = UDim2.new(0, 0, 0, 0)
                        imageLabel.BackgroundTransparency = 1
                        imageLabel.Image = "rbxassetid://74083143980512"
                        imageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
                        imageLabel.ImageTransparency = 1
                        
                        local circle = {
                            player = player,
                            startTime = tick(),
                            circlePart = circlePart,
                            imageLabel = imageLabel,
                            phase = "appearing"
                        }
                        
                        table.insert(jumpCircles, circle)
                    end
                end
                
                lastJumpState[playerKey] = isJumping
            end
        else
            -- Игрок покинул игру, очищаем состояние
            lastJumpState[player.Name] = nil
        end
        
        -- Обновляем существующие круги
        for i = #jumpCircles, 1, -1 do
            local circle = jumpCircles[i]
            local currentTime = tick()
            local elapsed = currentTime - circle.startTime
            local speed = getgenv().aim_settings.jump_circle_speed
            local maxSize = getgenv().aim_settings.jump_circle_size * 50 -- Конвертируем в пиксели
            
            -- Проверяем что игрок и части еще существуют
            if not circle.player.Character or not circle.circlePart or not circle.circlePart.Parent then
                if circle.circlePart then circle.circlePart:Destroy() end
                table.remove(jumpCircles, i)
            else
                local imageLabel = circle.imageLabel
                if imageLabel then
                    local totalDuration = 2.0 / speed -- Общая длительность анимации
                    local appearDuration = totalDuration * 0.3 -- 30% времени на появление
                    local visibleDuration = totalDuration * 0.4 -- 40% времени видимый
                    local disappearDuration = totalDuration * 0.3 -- 30% времени на исчезновение
                    
                    -- Максимальный размер в стадах (настройка размера)
                    local finalSize = getgenv().aim_settings.jump_circle_size
                    
                    if elapsed < appearDuration then
                        -- Фаза появления: плавно увеличиваем размер и уменьшаем прозрачность
                        local progress = elapsed / appearDuration
                        local easeProgress = 1 - (1 - progress) * (1 - progress) -- Ease out
                        
                        local currentSize = finalSize * easeProgress
                        circle.circlePart.Size = Vector3.new(currentSize, currentSize, 0.01)
                        imageLabel.ImageTransparency = 1 - easeProgress
                        
                    elseif elapsed < appearDuration + visibleDuration then
                        -- Фаза видимости: полный размер, полная видимость
                        circle.circlePart.Size = Vector3.new(finalSize, finalSize, 0.01)
                        imageLabel.ImageTransparency = 0
                        
                    elseif elapsed < totalDuration then
                        -- Фаза исчезновения: сохраняем размер, увеличиваем прозрачность
                        local disappearProgress = (elapsed - appearDuration - visibleDuration) / disappearDuration
                        local easeProgress = disappearProgress * disappearProgress -- Ease in
                        
                        circle.circlePart.Size = Vector3.new(finalSize, finalSize, 0.01)
                        imageLabel.ImageTransparency = easeProgress
                        
                    else
                        -- Анимация завершена, удаляем круг
                        circle.circlePart:Destroy()
                        table.remove(jumpCircles, i)
                    end
                else
                    -- ImageLabel не найден, удаляем круг
                    circle.circlePart:Destroy()
                    table.remove(jumpCircles, i)
                end
            end
        end
    else
        -- JumpCircle выключен, очищаем все круги
        for i = #jumpCircles, 1, -1 do
            local circle = jumpCircles[i]
            if circle.circlePart then circle.circlePart:Destroy() end
            table.remove(jumpCircles, i)
        end
        -- Очищаем состояния прыжков
        lastJumpState = {}
    end
    
    -- China Hat Logic
    if getgenv().aim_settings.cosmetic_enabled and getgenv().aim_settings.china_hat then
        local player = LocalPlayer
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                -- Проверяем режим камеры для Hide in First Person
                local shouldHide = false
                if getgenv().aim_settings.hide_in_first_person then
                    local camera = workspace.CurrentCamera
                    if camera and camera.CameraSubject == player.Character.Humanoid then
                        -- Более стабильная проверка первого лица
                        local distance = (camera.CFrame.Position - head.Position).Magnitude
                        local isFirstPerson = distance < 1.5
                        
                        -- Добавляем гистерезис для предотвращения мерцания
                        if lastCameraMode == nil then
                            lastCameraMode = isFirstPerson
                            shouldHide = isFirstPerson
                        else
                            if isFirstPerson and distance < 1.2 then
                                lastCameraMode = true
                                shouldHide = true
                            elseif not isFirstPerson and distance > 2.0 then
                                lastCameraMode = false
                                shouldHide = false
                            else
                                shouldHide = lastCameraMode
                            end
                        end
                    end
                end
                
                -- Создаем China Hat для локального игрока если его нет
                if not chinaHat then
                    local hatData = createChinaHat(player.Name, true)
                    chinaHat = hatData.hat
                    chinaHatGradientLayers = hatData.layers
                end
                
                -- Обновляем China Hat локального игрока
                local localHatData = {hat = chinaHat, layers = chinaHatGradientLayers}
                updateChinaHatPosition(localHatData, head, shouldHide)
            end
        end
        
        -- China Hat для друзей
        if getgenv().aim_settings.china_hat_friends then
            for _, friendPlayer in pairs(Players:GetPlayers()) do
                if friendPlayer ~= LocalPlayer and friendPlayer.Character and isFriend(friendPlayer.Name) then
                    local friendHead = friendPlayer.Character:FindFirstChild("Head")
                    if friendHead then
                        -- Создаем China Hat для друга если его нет
                        if not friendsChinaHats[friendPlayer.Name] then
                            friendsChinaHats[friendPlayer.Name] = createChinaHat(friendPlayer.Name, false)
                        end
                        
                        -- Обновляем позицию China Hat друга (друзья всегда видимы)
                        updateChinaHatPosition(friendsChinaHats[friendPlayer.Name], friendHead, false)
                    end
                else
                    -- Удаляем China Hat если игрок больше не друг или вышел
                    if friendsChinaHats[friendPlayer.Name] then
                        destroyChinaHat(friendsChinaHats[friendPlayer.Name])
                        friendsChinaHats[friendPlayer.Name] = nil
                    end
                end
            end
        else
            -- Опция Friends выключена, удаляем все China Hat друзей
            for playerName, hatData in pairs(friendsChinaHats) do
                destroyChinaHat(hatData)
            end
            friendsChinaHats = {}
        end
    else
        -- Cosmetic или China Hat выключен, удаляем все части
        if chinaHat then
            chinaHat:Destroy()
            chinaHat = nil
        end
        
        for _, layer in ipairs(chinaHatGradientLayers) do
            if layer then
                layer:Destroy()
            end
        end
        chinaHatGradientLayers = {}
        
        -- Удаляем China Hat всех друзей
        for playerName, hatData in pairs(friendsChinaHats) do
            destroyChinaHat(hatData)
        end
        friendsChinaHats = {}
        
        -- Дополнительная очистка в workspace
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name:match("^ChinaHat") or obj.Name:match("^ChinaHatLayer") then
                obj:Destroy()
            end
        end
        
        -- Сбрасываем режим камеры
        lastCameraMode = nil
    end
    
    -- ClickGui Background Effects
    if getgenv().aim_settings.clickgui_enabled then
        -- Определяем должны ли эффекты быть активными (во время показа или когда GUI видимо)
        local effectsActive = (panelAnimationState == "showing" or panelAnimationState == "visible")
        
        -- Blur Effect
        if getgenv().aim_settings.clickgui_blur and effectsActive then
            BlurEffect.Enabled = true
            if BlurEffect.Size < 24 then
                BlurEffect.Size = math.min(BlurEffect.Size + 1.2, 24)
            end
        else
            if BlurEffect.Size > 0 then
                BlurEffect.Size = math.max(BlurEffect.Size - 1.2, 0)
                if BlurEffect.Size <= 0 then
                    BlurEffect.Enabled = false
                end
            end
        end
        
        -- Darken Effect
        if getgenv().aim_settings.clickgui_darken and effectsActive then
            DarkenFrame.Visible = true
            if DarkenFrame.BackgroundTransparency > 0.3 then
                DarkenFrame.BackgroundTransparency = math.max(DarkenFrame.BackgroundTransparency - 0.05, 0.3)
            end
        else
            if DarkenFrame.BackgroundTransparency < 1 then
                DarkenFrame.BackgroundTransparency = math.min(DarkenFrame.BackgroundTransparency + 0.05, 1)
                if DarkenFrame.BackgroundTransparency >= 1 then
                    DarkenFrame.Visible = false
                end
            end
        end
        
        -- Image Effect
        if getgenv().aim_settings.clickgui_image and effectsActive then
            ClickGuiImage.Visible = true
            
            -- Обновляем картинку в зависимости от режима
            if getgenv().aim_settings.clickgui_image_mode == "Vanilla" then
                ClickGuiImage.Image = "http://www.roblox.com/asset/?id=7331776965"
                -- Сбрасываем trollface анимацию и музыку
                if trollfaceOriginalPosition then
                    ClickGuiImage.Position = trollfaceOriginalPosition
                    trollfaceOriginalPosition = nil
                end
                if trollfaceMusic then
                    trollfaceMusic:Stop()
                    trollfaceMusic:Destroy()
                    trollfaceMusic = nil
                end
            elseif getgenv().aim_settings.clickgui_image_mode == "Azuki" then
                ClickGuiImage.Image = "http://www.roblox.com/asset/?id=7331759194"
                -- Сбрасываем trollface анимацию и музыку
                if trollfaceOriginalPosition then
                    ClickGuiImage.Position = trollfaceOriginalPosition
                    trollfaceOriginalPosition = nil
                end
                if trollfaceMusic then
                    trollfaceMusic:Stop()
                    trollfaceMusic:Destroy()
                    trollfaceMusic = nil
                end
            elseif getgenv().aim_settings.clickgui_image_mode == "mgebrat" then
                ClickGuiImage.Image = "rbxassetid://108286603977430"
                -- Сбрасываем trollface анимацию и музыку
                if trollfaceOriginalPosition then
                    ClickGuiImage.Position = trollfaceOriginalPosition
                    trollfaceOriginalPosition = nil
                end
                if trollfaceMusic then
                    trollfaceMusic:Stop()
                    trollfaceMusic:Destroy()
                    trollfaceMusic = nil
                end
            elseif getgenv().aim_settings.clickgui_image_mode == "larp" then
                ClickGuiImage.Image = "rbxassetid://126488944636237"
                -- Сбрасываем trollface анимацию и музыку
                if trollfaceOriginalPosition then
                    ClickGuiImage.Position = trollfaceOriginalPosition
                    trollfaceOriginalPosition = nil
                end
                if trollfaceMusic then
                    trollfaceMusic:Stop()
                    trollfaceMusic:Destroy()
                    trollfaceMusic = nil
                end
            elseif getgenv().aim_settings.clickgui_image_mode == "larp2" then
                ClickGuiImage.Image = "rbxassetid://112963740799060"
                -- Сбрасываем trollface анимацию и музыку
                if trollfaceOriginalPosition then
                    ClickGuiImage.Position = trollfaceOriginalPosition
                    trollfaceOriginalPosition = nil
                end
                if trollfaceMusic then
                    trollfaceMusic:Stop()
                    trollfaceMusic:Destroy()
                    trollfaceMusic = nil
                end
            elseif getgenv().aim_settings.clickgui_image_mode == "trollface" then
                ClickGuiImage.Image = "rbxassetid://91788760747906"
                
                -- Trollface animation effects
                if getgenv().aim_settings.trollface_animate then
                    trollfaceAnimationTime = trollfaceAnimationTime + 0.016 -- ~60 FPS
                    
                    -- Сохраняем оригинальную позицию при первом запуске
                    if not trollfaceOriginalPosition then
                        trollfaceOriginalPosition = ClickGuiImage.Position
                    end
                    
                    -- Черные мигания (каждые 0.5 секунды)
                    trollfaceFlashTime = trollfaceFlashTime + 0.016
                    if trollfaceFlashTime >= 0.5 then
                        trollfaceFlashTime = 0
                        -- Создаем черную вспышку на весь экран
                        local flashFrame = Instance.new("Frame", ScreenGui)
                        flashFrame.Size = UDim2.new(1, 0, 1, 0)
                        flashFrame.Position = UDim2.new(0, 0, 0, 0)
                        flashFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        flashFrame.BackgroundTransparency = 0
                        flashFrame.BorderSizePixel = 0
                        flashFrame.ZIndex = 1000
                        
                        -- Быстро исчезает
                        local flashTween = TweenService:Create(flashFrame, 
                            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
                            {BackgroundTransparency = 1}
                        )
                        flashTween:Play()
                        flashTween.Completed:Connect(function()
                            flashFrame:Destroy()
                        end)
                        
                        -- Огненный эффект (красно-оранжевые частицы)
                        for i = 1, 5 do
                            local fireParticle = Instance.new("Frame", ScreenGui)
                            fireParticle.Size = UDim2.new(0, math.random(10, 30), 0, math.random(10, 30))
                            fireParticle.Position = UDim2.new(
                                math.random(70, 90) / 100, 
                                math.random(-50, 50), 
                                math.random(60, 90) / 100, 
                                math.random(-50, 50)
                            )
                            fireParticle.BackgroundColor3 = Color3.fromRGB(
                                math.random(200, 255), 
                                math.random(50, 150), 
                                0
                            )
                            fireParticle.BorderSizePixel = 0
                            fireParticle.ZIndex = 999
                            
                            local fireCorner = Instance.new("UICorner", fireParticle)
                            fireCorner.CornerRadius = UDim.new(1, 0)
                            
                            -- Анимация огня (движение вверх и исчезновение)
                            local fireTween = TweenService:Create(fireParticle,
                                TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                                {
                                    Position = UDim2.new(
                                        fireParticle.Position.X.Scale,
                                        fireParticle.Position.X.Offset + math.random(-20, 20),
                                        fireParticle.Position.Y.Scale - 0.3,
                                        fireParticle.Position.Y.Offset
                                    ),
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(0, 5, 0, 5)
                                }
                            )
                            fireTween:Play()
                            fireTween.Completed:Connect(function()
                                fireParticle:Destroy()
                            end)
                        end
                    end
                    
                    -- Тряска (маленькая)
                    local shakeIntensity = 3
                    trollfaceShakeOffset = Vector2.new(
                        math.random(-shakeIntensity, shakeIntensity),
                        math.random(-shakeIntensity, shakeIntensity)
                    )
                    
                    ClickGuiImage.Position = UDim2.new(
                        trollfaceOriginalPosition.X.Scale,
                        trollfaceOriginalPosition.X.Offset + trollfaceShakeOffset.X,
                        trollfaceOriginalPosition.Y.Scale,
                        trollfaceOriginalPosition.Y.Offset + trollfaceShakeOffset.Y
                    )
                else
                    -- Если анимация выключена, возвращаем к оригинальной позиции
                    if trollfaceOriginalPosition then
                        ClickGuiImage.Position = trollfaceOriginalPosition
                    end
                end
                
                -- Trollface music
                if getgenv().aim_settings.trollface_music then
                    -- Создаем музыку если её нет
                    if not trollfaceMusic then
                        trollfaceMusic = Instance.new("Sound")
                        trollfaceMusic.SoundId = "rbxassetid://140709876805704"
                        trollfaceMusic.Looped = true
                        trollfaceMusic.Volume = getgenv().aim_settings.trollface_volume
                        trollfaceMusic.Parent = workspace
                        trollfaceMusic:Play()
                    else
                        -- Обновляем громкость
                        trollfaceMusic.Volume = getgenv().aim_settings.trollface_volume
                        -- Проверяем что музыка играет
                        if not trollfaceMusic.IsPlaying then
                            trollfaceMusic:Play()
                        end
                    end
                else
                    -- Останавливаем и удаляем музыку
                    if trollfaceMusic then
                        trollfaceMusic:Stop()
                        trollfaceMusic:Destroy()
                        trollfaceMusic = nil
                    end
                end
            end
            
            -- Плавное появление
            if ClickGuiImage.ImageTransparency > 0 then
                ClickGuiImage.ImageTransparency = math.max(ClickGuiImage.ImageTransparency - 0.05, 0)
            end
        else
            -- Плавное исчезновение
            if ClickGuiImage.ImageTransparency < 1 then
                ClickGuiImage.ImageTransparency = math.min(ClickGuiImage.ImageTransparency + 0.05, 1)
                if ClickGuiImage.ImageTransparency >= 1 then
                    ClickGuiImage.Visible = false
                end
            end
        end
    else
        -- ClickGui выключен, отключаем эффекты
        if BlurEffect.Size > 0 then
            BlurEffect.Size = math.max(BlurEffect.Size - 1.2, 0)
            if BlurEffect.Size <= 0 then
                BlurEffect.Enabled = false
            end
        end
        
        if DarkenFrame.BackgroundTransparency < 1 then
            DarkenFrame.BackgroundTransparency = math.min(DarkenFrame.BackgroundTransparency + 0.05, 1)
            if DarkenFrame.BackgroundTransparency >= 1 then
                DarkenFrame.Visible = false
            end
        end
        
        if ClickGuiImage.ImageTransparency < 1 then
            ClickGuiImage.ImageTransparency = math.min(ClickGuiImage.ImageTransparency + 0.05, 1)
            if ClickGuiImage.ImageTransparency >= 1 then
                ClickGuiImage.Visible = false
            end
        end
    end
    
    -- FullBright (применяем только при изменении состояния)
    if getgenv().aim_settings.fullbright ~= fullbrightActive then
        fullbrightActive = getgenv().aim_settings.fullbright
        
        if fullbrightActive then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = originalLighting.Brightness
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            -- Восстанавливаем ClockTime только если Always Day тоже выключен
            if not getgenv().aim_settings.always_day then
                Lighting.ClockTime = originalLighting.ClockTime
            end
        end
    end
    
    -- Always Day (применяем только при изменении состояния)
    if getgenv().aim_settings.always_day ~= alwaysDayActive then
        alwaysDayActive = getgenv().aim_settings.always_day
        
        if alwaysDayActive then
            Lighting.ClockTime = 12
        else
            -- Восстанавливаем только если FullBright тоже выключен
            if not getgenv().aim_settings.fullbright then
                Lighting.ClockTime = originalLighting.ClockTime
            end
        end
    end
    
    -- Target HUD Display
    -- Показываем если включен TargetHud И (есть цель ИЛИ меню открыто)
    local guiVisible = (panelAnimationState == "showing" or panelAnimationState == "visible")
    TargetHudFrame.Visible = getgenv().aim_settings.target_hud and (LockedTarget ~= nil or guiVisible)
    
    if getgenv().aim_settings.target_hud and LockedTarget and LockedTarget.Parent then
        local character = LockedTarget.Parent
        local targetPlayer = Players:GetPlayerFromCharacter(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if targetPlayer and humanoid and humanoid.Health > 0 then
            -- Обновляем аватар
            local userId = targetPlayer.UserId
            AvatarImage.Image = getHeadshotImage(userId)
            
            -- Обновляем имя
            TargetNameLabel.Text = targetPlayer.Name
            
            -- Обновляем HP
            local hum = LockedTarget.Parent:FindFirstChildOfClass("Humanoid")
            if hum then
                local health = math.floor(hum.Health)
                local maxHealth = math.floor(hum.MaxHealth)
                TargetHPLabel.Text = "HP: " .. health
                
                -- Анимация HP бара
                local healthPercent = math.clamp(health / maxHealth, 0, 1)
                tween(HPBarFill, {Size = UDim2.new(healthPercent, 0, 1, 0)}, 0.2)
                
                TargetMetaLabel.Text = ""
                
                -- Используем цвета клиента для градиента (слева темнее, справа светлее)
                updateHPBarGradient()
            end
        else
            -- Не сбрасываем здесь LockedTarget, чтобы lock target управлялся только аимботом.
        end
    elseif getgenv().aim_settings.target_hud and guiVisible then
        -- Показываем пример когда меню открыто
        AvatarImage.Image = getHeadshotImage(LocalPlayer.UserId)
        TargetNameLabel.Text = LocalPlayer.Name
        TargetMetaLabel.Text = ""
        local previewHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local previewHealth = math.floor((previewHumanoid and previewHumanoid.Health) or 100)
        local previewMaxHealth = math.max((previewHumanoid and previewHumanoid.MaxHealth) or 100, 1)
        TargetHPLabel.Text = "HP: " .. previewHealth
        HPBarFill.Size = UDim2.new(math.clamp(previewHealth / previewMaxHealth, 0, 1), 0, 1, 0)
        
        -- Используем цвета клиента для градиента
        updateHPBarGradient()
    end
    
    -- Aimbot camera is updated in BindToRenderStep so fast mode can override recoil/shake.
    
    -- Unload Script Logic
    if getgenv().aim_settings.unload_script then
        getgenv().aim_settings.running = false
        getgenv().aim_settings.cosmetic_enabled = false
        getgenv().aim_settings.china_hat = false
        getgenv().aim_settings.china_hat_friends = false
        pcall(function()
            RunService:UnbindFromRenderStep("Y_AimbotCamera")
        end)
        FOVCircle:Remove()
        
        -- Очищаем JumpCircles
        for i = #jumpCircles, 1, -1 do
            local circle = jumpCircles[i]
            if circle.circlePart then circle.circlePart:Destroy() end
            table.remove(jumpCircles, i)
        end
        jumpCircles = {}
        lastJumpState = {}
        
        -- Удаляем все оставшиеся JumpCircle Part'ы в workspace (на всякий случай)
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("Part") and obj.Name:match("^JumpCirclePart_") then
                obj:Destroy()
            end
        end
        
        -- Очищаем ClickGui эффекты
        if BlurEffect then BlurEffect:Destroy() end
        if DarkenScreenGui then DarkenScreenGui:Destroy() end
        if ClickGuiImage then ClickGuiImage.Visible = false end
        
        -- Очищаем trollface музыку
        if trollfaceMusic then
            trollfaceMusic:Stop()
            trollfaceMusic:Destroy()
            trollfaceMusic = nil
        end
        
        -- Очищаем China Hat
        if chinaHat then
            chinaHat:Destroy()
            chinaHat = nil
        end
        
        for _, layer in ipairs(chinaHatGradientLayers) do
            if layer then
                layer:Destroy()
            end
        end
        chinaHatGradientLayers = {}
        
        -- Очищаем China Hat всех друзей
        for playerName, hatData in pairs(friendsChinaHats) do
            destroyChinaHat(hatData)
        end
        friendsChinaHats = {}
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name:match("^ChinaHat") or obj.Name:match("^ChinaHatLayer") then
                obj:Destroy()
            end
        end
        lastCameraMode = nil
        
        -- Восстанавливаем оригинальные настройки освещения
        Lighting.Brightness = originalLighting.Brightness
        Lighting.ClockTime = originalLighting.ClockTime
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                if p.Character:FindFirstChild("Y_ESP") then
                    p.Character.Y_ESP:Destroy()
                end
                local head = p.Character:FindFirstChild("Head")
                local torso = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("Torso")
                
                if head then
                    if head:FindFirstChild("Y_ESP_Text") then
                        head.Y_ESP_Text:Destroy()
                    end
                    if head:FindFirstChild("Y_Target_ESP") then
                        head.Y_Target_ESP:Destroy()
                    end
                    if head:FindFirstChild("Y_Friend_Marker") then
                        head.Y_Friend_Marker:Destroy()
                    end
                end
                
                -- Удаляем Target ESP с торса тоже
                if torso and torso:FindFirstChild("Y_Target_ESP") then
                    torso.Y_Target_ESP:Destroy()
                end
            end
        end
        if HudScreenGui then
            HudScreenGui:Destroy()
        end
        ScreenGui:Destroy()
    end
end)

pcall(function()
    RunService:UnbindFromRenderStep("Y_AimbotCamera")
end)

RunService:BindToRenderStep("Y_AimbotCamera", Enum.RenderPriority.Last.Value + 1, updateAimbotCamera or function() end)

-- [[ GLOBAL MOUSE RELEASE ]]
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        for _, panel in ipairs(panels) do
            panel.dragging = false
        end
        targetHudDragging = false
    end
end)

-- [[ HOTKEYS & BINDS ]]
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- Handle Binding (назначение клавиши) - проверяем первым
    for _, p in ipairs(panels) do
        if p.bindingModule then
            local key = input.KeyCode
            if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Backspace then
                -- Удаление горячей клавиши
                if p.bindingModule.settingKey == "click_action" then
                    getgenv().aim_settings.click_action_key = Enum.KeyCode.Unknown
                    p.bindingModule.bindBox.Text = "..."
                elseif p.bindingModule.settingKey == "clickgui_enabled" then
                    getgenv().aim_settings.clickgui_bind = Enum.KeyCode.Unknown
                    p.bindingModule.bindBox.Text = "..."
                else
                    getgenv().aim_settings.hotkeys[p.bindingModule.settingKey] = nil
                    p.bindingModule.bindBox.Text = "..."
                end
                p.bindingModule.bindBox.BackgroundColor3 = THEME.BIND_BG
            elseif key ~= Enum.KeyCode.Unknown then
                -- Назначение новой горячей клавиши
                if p.bindingModule.settingKey == "click_action" then
                    getgenv().aim_settings.click_action_key = key
                    p.bindingModule.bindBox.Text = getKeyName(key)
                elseif p.bindingModule.settingKey == "clickgui_enabled" then
                    getgenv().aim_settings.clickgui_bind = key
                    p.bindingModule.bindBox.Text = getKeyName(key)
                else
                    getgenv().aim_settings.hotkeys[p.bindingModule.settingKey] = key
                    p.bindingModule.bindBox.Text = getKeyName(key)
                end
                p.bindingModule.bindBox.BackgroundColor3 = THEME.BIND_BG
            end
            p.bindingModule = nil
            return
        end
    end
    
    -- Click Action для добавления/удаления друзей (только при первом нажатии)
    if getgenv().aim_settings.click_action and input.KeyCode == getgenv().aim_settings.click_action_key and input.UserInputState == Enum.UserInputState.Begin then
        local targetPlayer = getPlayerFromMouse()
        if targetPlayer then
            local added, message = toggleFriend(targetPlayer.Name)
            print(targetPlayer.Name .. " - " .. message)
        end
    end
    
    -- Toggle UI
    if input.KeyCode == getgenv().aim_settings.clickgui_bind then
        if getgenv().aim_settings.clickgui_enabled then
            -- Определяем нужно ли показать или скрыть GUI
            local shouldShow = not ScreenGui.Enabled or panelAnimationState == "hidden"
            
            -- Запускаем анимацию панелей
            animatePanels(shouldShow)
        end
        return
    end
    
    -- Toggle Modules via Hotkey
    for settingKey, keyCode in pairs(getgenv().aim_settings.hotkeys) do
        if input.KeyCode == keyCode and keyCode ~= Enum.KeyCode.Unknown then
            getgenv().aim_settings[settingKey] = not getgenv().aim_settings[settingKey]
            
            -- Обновляем визуально все кнопки с этим settingKey
            for _, p in ipairs(panels) do
                for _, m in ipairs(p.modules) do
                    if m.settingKey == settingKey then
                        tween(m.btn, {BackgroundColor3 = getgenv().aim_settings[settingKey] and getClientColor() or THEME.MODULE_BG}, 0.2)
                    end
                end
            end
            break
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
end)
