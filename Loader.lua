--!strict

local function HttpGet(url: string): string
    return game:HttpGet(url)
end

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local GameId = game.PlaceId
local Games = loadstring(
    HttpGet("https://raw.githubusercontent.com/ansonchia787/AnsonDev/main/GameList.lua")
)()

print("Current PlaceId:", GameId)

local URL = Games[GameId]

-- 创建通知UI函数
local function ShowNotify(text: string)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NotifyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 80)
    Frame.Position = UDim2.new(1, -320, 1, -100)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 12)

    local Stroke = Instance.new("UIStroke", Frame)
    Stroke.Color = Color3.fromRGB(170, 100, 255)
    Stroke.Thickness = 1.5

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -20, 1, -20)
    TextLabel.Position = UDim2.new(0, 10, 0, 10)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = text
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextScaled = true
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.Parent = Frame

    -- 初始透明
    Frame.BackgroundTransparency = 1
    TextLabel.TextTransparency = 1
    Stroke.Transparency = 1

    -- 淡入
    TweenService:Create(Frame, TweenInfo.new(0.4), {
        BackgroundTransparency = 0
    }):Play()

    TweenService:Create(TextLabel, TweenInfo.new(0.4), {
        TextTransparency = 0
    }):Play()

    TweenService:Create(Stroke, TweenInfo.new(0.4), {
        Transparency = 0
    }):Play()

    -- 等3秒
    task.wait(3)

    -- 淡出
    local fadeOut1 = TweenService:Create(Frame, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    })
    local fadeOut2 = TweenService:Create(TextLabel, TweenInfo.new(0.5), {
        TextTransparency = 1
    })
    local fadeOut3 = TweenService:Create(Stroke, TweenInfo.new(0.5), {
        Transparency = 1
    })

    fadeOut1:Play()
    fadeOut2:Play()
    fadeOut3:Play()

    fadeOut1.Completed:Wait()
    ScreenGui:Destroy()
end

-- 没有脚本 → 弹通知
if not URL then
    ShowNotify("Unsupported Game\nPlaceId: " .. tostring(GameId))
    return
end

-- 有脚本 → 正常加载
local success, err = pcall(function()
    loadstring(HttpGet(URL))()
end)

if not success then
    warn("Load Error:", err)
end
