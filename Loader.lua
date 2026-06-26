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

local function AdvancedNotify(title: string, text: string)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AdvancedNotify"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = CoreGui

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(0, 364, 0, 100)
	Frame.Position = UDim2.new(1, 380, 1, -120)
	Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
	Frame.BorderSizePixel = 0
	Frame.ClipsDescendants = true
	Frame.Parent = ScreenGui

	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

	local Stroke = Instance.new("UIStroke", Frame)
	Stroke.Color = Color3.fromRGB(255, 255, 255)
	Stroke.Thickness = 1
	Stroke.Transparency = 0.92

	local Sheen = Instance.new("Frame")
	Sheen.Size = UDim2.new(1, 0, 0, 1)
	Sheen.Position = UDim2.new(0, 0, 0, 0)
	Sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Sheen.BackgroundTransparency = 0.88
	Sheen.BorderSizePixel = 0
	Sheen.ZIndex = 3
	Sheen.Parent = Frame

	local Body = Instance.new("Frame")
	Body.Size = UDim2.new(1, 0, 0, 88)
	Body.Position = UDim2.new(0, 0, 0, 0)
	Body.BackgroundTransparency = 1
	Body.ZIndex = 2
	Body.Parent = Frame

	local IconBG = Instance.new("Frame")
	IconBG.Size = UDim2.new(0, 32, 0, 32)
	IconBG.Position = UDim2.new(0, 16, 0, 15)
	IconBG.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	IconBG.BackgroundTransparency = 0.94
	IconBG.BorderSizePixel = 0
	IconBG.ZIndex = 3
	IconBG.Parent = Body

	Instance.new("UICorner", IconBG).CornerRadius = UDim.new(0, 6)

	local IconStroke = Instance.new("UIStroke", IconBG)
	IconStroke.Color = Color3.fromRGB(255, 255, 255)
	IconStroke.Thickness = 1
	IconStroke.Transparency = 0.9

	local Icon = Instance.new("TextLabel")
	Icon.Text = "i"
	Icon.Font = Enum.Font.GothamBold
	Icon.TextSize = 15
	Icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	Icon.TextTransparency = 0.3
	Icon.BackgroundTransparency = 1
	Icon.Size = UDim2.new(1, 0, 1, 0)
	Icon.TextXAlignment = Enum.TextXAlignment.Center
	Icon.TextYAlignment = Enum.TextYAlignment.Center
	Icon.ZIndex = 4
	Icon.Parent = IconBG

	local Title = Instance.new("TextLabel")
	Title.Text = title
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 13
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextTransparency = 0.1
	Title.BackgroundTransparency = 1
	Title.Position = UDim2.new(0, 60, 0, 14)
	Title.Size = UDim2.new(1, -76, 0, 17)
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.ZIndex = 3
	Title.Parent = Body

	local Desc = Instance.new("TextLabel")
	Desc.Text = text
	Desc.Font = Enum.Font.Gotham
	Desc.TextSize = 12
	Desc.TextColor3 = Color3.fromRGB(255, 255, 255)
	Desc.TextTransparency = 0.5
	Desc.BackgroundTransparency = 1
	Desc.Position = UDim2.new(0, 60, 0, 33)
	Desc.Size = UDim2.new(1, -76, 0, 16)
	Desc.TextWrapped = true
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	Desc.ZIndex = 3
	Desc.Parent = Body

	local PillBG = Instance.new("Frame")
	PillBG.Size = UDim2.new(0, 0, 0, 18)
	PillBG.Position = UDim2.new(0, 60, 0, 56)
	PillBG.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	PillBG.BackgroundTransparency = 0.95
	PillBG.BorderSizePixel = 0
	PillBG.AutomaticSize = Enum.AutomaticSize.X
	PillBG.ZIndex = 3
	PillBG.Parent = Body

	Instance.new("UICorner", PillBG).CornerRadius = UDim.new(0, 4)

	local PillStroke = Instance.new("UIStroke", PillBG)
	PillStroke.Color = Color3.fromRGB(255, 255, 255)
	PillStroke.Thickness = 1
	PillStroke.Transparency = 0.91

	local PillPad = Instance.new("UIPadding", PillBG)
	PillPad.PaddingLeft = UDim.new(0, 7)
	PillPad.PaddingRight = UDim.new(0, 7)

	local PillText = Instance.new("TextLabel")
	PillText.Text = "PlaceId: " .. tostring(GameId)
	PillText.Font = Enum.Font.Code
	PillText.TextSize = 10
	PillText.TextColor3 = Color3.fromRGB(255, 255, 255)
	PillText.TextTransparency = 0.65
	PillText.BackgroundTransparency = 1
	PillText.Size = UDim2.new(0, 0, 1, 0)
	PillText.AutomaticSize = Enum.AutomaticSize.X
	PillText.TextXAlignment = Enum.TextXAlignment.Left
	PillText.ZIndex = 4
	PillText.Parent = PillBG

	local Divider = Instance.new("Frame")
	Divider.Size = UDim2.new(1, -32, 0, 1)
	Divider.Position = UDim2.new(0, 16, 0, 88)
	Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Divider.BackgroundTransparency = 0.94
	Divider.BorderSizePixel = 0
	Divider.ZIndex = 2
	Divider.Parent = Frame

	local BarBG = Instance.new("Frame")
	BarBG.Size = UDim2.new(1, 0, 0, 2)
	BarBG.Position = UDim2.new(0, 0, 1, -2)
	BarBG.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	BarBG.BackgroundTransparency = 0.95
	BarBG.BorderSizePixel = 0
	BarBG.ZIndex = 2
	BarBG.Parent = Frame

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, 0, 1, 0)
	Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Bar.BackgroundTransparency = 0.75
	Bar.BorderSizePixel = 0
	Bar.ZIndex = 3
	Bar.Parent = BarBG

	TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -380, 1, -120)
	}):Play()

	TweenService:Create(Bar, TweenInfo.new(3, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	task.wait(3)

	local fadeOut = TweenInfo.new(0.25, Enum.EasingStyle.Quint)

	TweenService:Create(Frame, fadeOut, {
		Position = UDim2.new(1, 380, 1, -120),
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play()

	for _, lbl in ipairs({Title, Desc, PillText, Icon}) do
		TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
	end

	task.wait(0.35)
	ScreenGui:Destroy()
end

if not URL then
	AdvancedNotify(
		"Unsupported Game",
		"This game is not supported"
	)
	return
end

local success, err = pcall(function()
	loadstring(HttpGet(URL))()
end)

if not success then
	warn("Load Error:", err)
end
