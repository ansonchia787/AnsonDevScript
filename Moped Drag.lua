--[[
    AnsonDev - Moped Drag
    Version : 1.0.0
    Author  : AnsonDev
    UI      : Fluent Library
]]

-- ═══════════════════════════════════════════════════
--  Libraries
-- ═══════════════════════════════════════════════════
local Fluent          = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager     = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ═══════════════════════════════════════════════════
--  Services
-- ═══════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════
--  State
-- ═══════════════════════════════════════════════════
local State = {
    -- farm
    farmPoints   = {},
    farmIndex    = 1,
    farmRunning  = false,
    farmConn     = nil,
    farmSpeed    = 150,
    arrivalDist  = 12,

    -- boost
    boostEnabled = false,
    boostConn    = nil,
    boostMulti   = 2,

    -- fly (V3 method)
    flyEnabled   = false,
    flyConn      = nil,
    flySpeed     = 50,
    flyNowe      = false,

    -- noclip
    noclipEnabled = false,
    noclipConn    = nil,

    -- walk
    walkEnabled  = false,
    walkVal      = 16,

    -- jump
    jumpEnabled  = false,
    jumpVal      = 50,
    infJumpOn    = false,
    infJumpConn  = nil,

    -- god
    godOn        = false,
    godConn      = nil,

    -- afk
    afkOn        = false,

    -- fps boost
    fpsBoostOn   = false,
}

-- ═══════════════════════════════════════════════════
--  Helpers
-- ═══════════════════════════════════════════════════
local function getChar()  return player.Character end
local function getHRP()
    local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function getSeat()
    local hum = getHum()
    if hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat") then
        return hum.SeatPart
    end
end
local function getVehicleModel()
    local seat = getSeat(); return seat and seat.Parent
end
local function getVehicleRoot()
    local seat = getSeat()
    if not seat then return nil end
    local m = seat.Parent
    return (m and (m.PrimaryPart or m:FindFirstChildOfClass("BasePart"))) or seat
end
local function ensureBV(part, name, force)
    local bv = part:FindFirstChild(name)
    if not bv then
        bv = Instance.new("BodyVelocity")
        bv.Name     = name
        bv.MaxForce = Vector3.new(force, force, force)
        bv.Velocity = Vector3.zero
        bv.Parent   = part
    end
    return bv
end
local function ensureBG(part, name)
    local bg = part:FindFirstChild(name)
    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name      = name
        bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bg.P         = 1e5
        bg.D         = 500
        bg.CFrame    = part.CFrame
        bg.Parent    = part
    end
    return bg
end
local function cleanInst(part, name)
    if not part then return end
    local i = part:FindFirstChild(name)
    if i then i:Destroy() end
end
local function isR6()
    local c = getChar()
    return c and c:FindFirstChild("Torso") ~= nil
end
local function getTorso()
    local c = getChar()
    if not c then return nil end
    return isR6() and c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
end

-- ═══════════════════════════════════════════════════
--  FPS Display  (corner overlay)
-- ═══════════════════════════════════════════════════
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name           = "AnsonDevFPS"
fpsGui.ResetOnSpawn   = false
fpsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
fpsGui.Parent         = player:WaitForChild("PlayerGui")

local fpsBg = Instance.new("Frame")
fpsBg.Size                   = UDim2.new(0, 90, 0, 26)
fpsBg.Position               = UDim2.new(1, -100, 0, 8)
fpsBg.BackgroundColor3       = Color3.fromRGB(10, 10, 14)
fpsBg.BackgroundTransparency = 0.2
fpsBg.BorderSizePixel        = 0
fpsBg.Parent                 = fpsGui
Instance.new("UICorner", fpsBg).CornerRadius = UDim.new(0, 6)

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size               = UDim2.new(1, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text               = "FPS  --"
fpsLabel.TextColor3         = Color3.fromRGB(120, 220, 120)
fpsLabel.TextSize           = 13
fpsLabel.Font               = Enum.Font.GothamBold
fpsLabel.Parent             = fpsBg

local fpsSamples = {}
RunService.Heartbeat:Connect(function(dt)
    table.insert(fpsSamples, 1 / dt)
    if #fpsSamples > 30 then table.remove(fpsSamples, 1) end
    local sum = 0
    for _, v in ipairs(fpsSamples) do sum = sum + v end
    local avg = math.floor(sum / #fpsSamples)
    fpsLabel.Text = "FPS  " .. avg
    fpsLabel.TextColor3 = avg >= 55 and Color3.fromRGB(80, 220, 100)
        or avg >= 30 and Color3.fromRGB(240, 180, 60)
        or Color3.fromRGB(220, 70, 70)
end)

-- ═══════════════════════════════════════════════════
--  FPS Boost
-- ═══════════════════════════════════════════════════
local function applyFpsBoost()
    pcall(function() workspace.GlobalShadows = false end)
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function()
        workspace.StreamingMinRadius    = 64
        workspace.StreamingTargetRadius = 256
    end)
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")
                or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end)
    end
end
local function removeFpsBoost()
    pcall(function() workspace.GlobalShadows = true end)
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")
                or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = true
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  Moped Physics Override
-- ═══════════════════════════════════════════════════
local function overrideMopedPhysics(maxSpd, maxTorque)
    local model = getVehicleModel()
    if not model then return false end
    for _, v in ipairs(model:GetDescendants()) do
        pcall(function()
            if v:IsA("VehicleSeat")    then v.MaxSpeed   = maxSpd end
            if v:IsA("TorqueConstraint") then v.MaxTorque = maxTorque end
            if v:IsA("HingeConstraint") and v.ActuatorType == Enum.ActuatorType.Motor then
                v.MaxTorque      = maxTorque
                v.AngularVelocity = maxSpd / 8
            end
            if v:IsA("BodyVelocity") then
                v.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            end
        end)
    end
    return true
end

-- ═══════════════════════════════════════════════════
--  Auto Farm  (XYZ tracking, no height stuck)
-- ═══════════════════════════════════════════════════
local farmStatusEl  -- will be set after UI creation

local function stopFarm()
    State.farmRunning = false
    if State.farmConn then State.farmConn:Disconnect(); State.farmConn = nil end
    local vr = getVehicleRoot()
    if vr then cleanInst(vr, "FarmBV"); cleanInst(vr, "FarmBG") end
    local seat = getSeat()
    if seat then seat.ThrottleFloat = 0; seat.SteerFloat = 0 end
end

local function startFarm(points)
    local pts = points or State.farmPoints
    if #pts < 2 then return false, "Need at least 2 points." end
    if not getVehicleRoot() then return false, "Sit on the moped first." end

    State.farmRunning = true
    State.farmIndex   = 1

    State.farmConn = RunService.Heartbeat:Connect(function()
        if not State.farmRunning then return end
        local vr = getVehicleRoot()
        if not vr then stopFarm(); return end

        local target = pts[State.farmIndex]
        if not target then State.farmIndex = 1; return end

        local cur  = vr.Position

        -- Full 3D distance but steer only horizontally
        local dx   = target.X - cur.X
        local dy   = target.Y - cur.Y
        local dz   = target.Z - cur.Z
        local dist = math.sqrt(dx*dx + dy*dy + dz*dz)

        if dist < State.arrivalDist then
            State.farmIndex = (State.farmIndex % #pts) + 1
            target = pts[State.farmIndex]
        end

        -- Horizontal steering direction
        local flatDir = Vector3.new(dx, 0, dz)
        if flatDir.Magnitude < 0.01 then flatDir = Vector3.new(1, 0, 0) end
        flatDir = flatDir.Unit

        -- Vertical correction: if Y diff is big, include Y component so moped
        -- follows ramps/hills without getting stuck
        local yCorrect = math.clamp(dy, -1, 1) * State.farmSpeed * 0.5
        local moveVec  = flatDir * State.farmSpeed + Vector3.new(0, yCorrect, 0)

        local bv = ensureBV(vr, "FarmBV", 1e6)
        bv.Velocity = moveVec

        local bg = ensureBG(vr, "FarmBG")
        bg.CFrame = CFrame.lookAt(cur, cur + flatDir)

        local seat = getSeat()
        if seat then seat.ThrottleFloat = 1 end
    end)
    return true, "OK"
end

-- ═══════════════════════════════════════════════════
--  Speed Boost (keeps direction, ground only)
-- ═══════════════════════════════════════════════════
local function stopBoost()
    State.boostEnabled = false
    if State.boostConn then State.boostConn:Disconnect(); State.boostConn = nil end
    local vr = getVehicleRoot()
    if vr then cleanInst(vr, "BoostBV") end
end

local function startBoost()
    State.boostEnabled = true
    State.boostConn = RunService.Heartbeat:Connect(function()
        if not State.boostEnabled then return end
        local vr   = getVehicleRoot()
        local seat = getSeat()
        if not vr or not seat then return end

        local moving  = UserInputService:IsKeyDown(Enum.KeyCode.W)
        local hum     = getHum()
        if not moving and hum and hum.MoveDirection.Magnitude > 0.1 then
            moving = true
        end

        if moving then
            local vel     = vr.Velocity
            local flatVel = Vector3.new(vel.X, 0, vel.Z)
            local dir
            if flatVel.Magnitude < 1 then
                local fwd = seat.CFrame.LookVector
                dir = Vector3.new(fwd.X, 0, fwd.Z).Unit
            else
                dir = flatVel.Unit
            end
            local bv = ensureBV(vr, "BoostBV", 1e6)
            bv.Velocity        = dir * math.max(flatVel.Magnitude, 20) * State.boostMulti
            seat.ThrottleFloat = 1
        else
            cleanInst(vr, "BoostBV")
            seat.ThrottleFloat = 0
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  Fly  (V3 method: TranslateBy for walking + BV/BG for flying)
--  Supports R6 and R15
-- ═══════════════════════════════════════════════════
local flyTpWalking = false
local flyTpConn    = nil

local function stopFly()
    State.flyEnabled = false
    State.flyNowe    = false
    flyTpWalking     = false

    if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
    if flyTpConn     then flyTpConn:Disconnect();     flyTpConn = nil     end

    local torso = getTorso()
    if torso then
        cleanInst(torso, "FlyBV")
        cleanInst(torso, "FlyBG")
    end

    local hum = getHum()
    local c   = getChar()
    if hum then
        -- Re-enable all humanoid states
        for _, st in ipairs({
            Enum.HumanoidStateType.Climbing,    Enum.HumanoidStateType.FallingDown,
            Enum.HumanoidStateType.Flying,      Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.GettingUp,   Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Landed,      Enum.HumanoidStateType.Physics,
            Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
            Enum.HumanoidStateType.Running,     Enum.HumanoidStateType.RunningNoPhysics,
            Enum.HumanoidStateType.Seated,      Enum.HumanoidStateType.StrafingNoPhysics,
            Enum.HumanoidStateType.Swimming,
        }) do
            hum:SetStateEnabled(st, true)
        end
        hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
        hum.PlatformStand = false
    end
    if c then
        local anim = c:FindFirstChild("Animate")
        if anim then anim.Disabled = false end
        local h2 = c:FindFirstChildOfClass("Humanoid")
        if h2 then
            for _, t in ipairs(h2:GetPlayingAnimationTracks()) do
                t:AdjustSpeed(1)
            end
        end
    end
end

local function startFly()
    State.flyEnabled = true
    State.flyNowe    = true

    local hum = getHum()
    local c   = getChar()
    if not hum or not c then return end

    -- Disable humanoid states (V3 method)
    for _, st in ipairs({
        Enum.HumanoidStateType.Climbing,    Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Flying,      Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.GettingUp,   Enum.HumanoidStateType.Jumping,
        Enum.HumanoidStateType.Landed,      Enum.HumanoidStateType.Physics,
        Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
        Enum.HumanoidStateType.Running,     Enum.HumanoidStateType.RunningNoPhysics,
        Enum.HumanoidStateType.Seated,      Enum.HumanoidStateType.StrafingNoPhysics,
        Enum.HumanoidStateType.Swimming,
    }) do
        hum:SetStateEnabled(st, false)
    end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    hum.PlatformStand = true

    -- TranslateBy walking thread (same as V3)
    flyTpWalking = true
    flyTpConn = RunService.Heartbeat:Connect(function()
        if not flyTpWalking then return end
        local chr = getChar(); local h = getHum()
        if chr and h and h.MoveDirection.Magnitude > 0 then
            chr:TranslateBy(h.MoveDirection * (State.flySpeed * 0.05))
        end
    end)

    -- BodyVelocity / BodyGyro on torso
    local torso = getTorso()
    if not torso then return end

    local bg = ensureBG(torso, "FlyBG")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P         = 9e4
    bg.CFrame    = torso.CFrame

    local bv = ensureBV(torso, "FlyBV", 9e9)
    bv.Velocity = Vector3.new(0, 0.1, 0)

    local maxspeed = State.flySpeed
    local speed    = 0
    local ctrl     = { f=0, b=0, l=0, r=0 }
    local lastctrl = { f=0, b=0, l=0, r=0 }

    State.flyConn = RunService.RenderStepped:Connect(function()
        if not State.flyNowe then return end

        local h2 = getHum()
        if h2 then h2.PlatformStand = true end

        -- Read input
        ctrl.f = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        ctrl.b = UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
        ctrl.l = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        ctrl.r = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0

        -- Mobile: use MoveDirection
        local hm = getHum()
        if hm then
            local md = hm.MoveDirection
            if md.Magnitude > 0.1 then
                ctrl.f = md.Z < 0 and 1 or (md.Z > 0 and -1 or ctrl.f)
                ctrl.r = md.X > 0 and 1 or (md.X < 0 and -1 or ctrl.r)
            end
        end

        local moving = (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0
        if moving then
            speed = math.min(speed + 0.5 + (speed / maxspeed), maxspeed)
        elseif speed > 0 then
            speed = math.max(speed - 1, 0)
        end

        local cf = camera.CoordinateFrame
        if moving then
            bv.Velocity = ((cf.LookVector * (ctrl.f + ctrl.b)) +
                ((cf * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).Position) - cf.Position)) * speed
            lastctrl = { f=ctrl.f, b=ctrl.b, l=ctrl.l, r=ctrl.r }
        elseif speed > 0 then
            bv.Velocity = ((cf.LookVector * (lastctrl.f + lastctrl.b)) +
                ((cf * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).Position) - cf.Position)) * speed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end

        bg.CFrame = cf * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
    end)
end

-- ═══════════════════════════════════════════════════
--  Noclip
-- ═══════════════════════════════════════════════════
local function stopNoclip()
    State.noclipEnabled = false
    if State.noclipConn then State.noclipConn:Disconnect(); State.noclipConn = nil end
    local char = getChar()
    if char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
end
local function startNoclip()
    State.noclipEnabled = true
    State.noclipConn = RunService.Stepped:Connect(function()
        if not State.noclipEnabled then return end
        local char = getChar(); if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  Fluent Window
-- ═══════════════════════════════════════════════════
local Window = Fluent:CreateWindow({
    Title    = "AnsonDev  -  Moped Drag",
    SubTitle = "v1.0.0",
    TabWidth = 160,
    Size     = UDim2.fromOffset(580, 460),
    Acrylic  = true,
    Theme    = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl,
})

local Tabs = {
    Player    = Window:AddTab({ Title = "Player",      Icon = "user"         }),
    AutoFarm  = Window:AddTab({ Title = "Auto Farm",   Icon = "map-pin"      }),
    SpeedBoost = Window:AddTab({ Title = "Speed Boost", Icon = "zap"         }),
    Misc      = Window:AddTab({ Title = "Misc",        Icon = "settings"     }),
    Settings  = Window:AddTab({ Title = "Settings",    Icon = "settings-2"   }),
}

local Options = Fluent.Options

-- ═══════════════════════════════════════════════════
--  TAB: Player
-- ═══════════════════════════════════════════════════
do
    local T = Tabs.Player

    -- Walk Speed
    T:AddParagraph({ Title = "Walk Speed", Content = "Adjust your character walk speed." })
    T:AddSlider("WalkSpeedSlider", {
        Title   = "Walk Speed",
        Min     = 8, Max = 500, Default = 16, Rounding = 0,
        Callback = function(v) State.walkVal = v end,
    })
    T:AddToggle("WalkSpeedToggle", {
        Title   = "Enable Walk Speed",
        Default = false,
        Callback = function(v)
            State.walkEnabled = v
            local hum = getHum()
            if hum then hum.WalkSpeed = v and State.walkVal or 16 end
        end,
    })

    -- Jump Power
    T:AddParagraph({ Title = "Jump Power", Content = "Adjust jump height." })
    T:AddSlider("JumpPowerSlider", {
        Title   = "Jump Power",
        Min     = 0, Max = 500, Default = 50, Rounding = 0,
        Callback = function(v) State.jumpVal = v end,
    })
    T:AddToggle("JumpPowerToggle", {
        Title   = "Enable Jump Power",
        Default = false,
        Callback = function(v)
            State.jumpEnabled = v
            local hum = getHum()
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = v and State.jumpVal or 50
            end
        end,
    })
    T:AddToggle("InfJump", {
        Title   = "Infinite Jump",
        Default = false,
        Callback = function(v)
            State.infJumpOn = v
            if v then
                State.infJumpConn = UserInputService.JumpRequest:Connect(function()
                    local hum = getHum()
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end)
            else
                if State.infJumpConn then State.infJumpConn:Disconnect(); State.infJumpConn = nil end
            end
        end,
    })

    -- God Mode
    T:AddParagraph({ Title = "God Mode", Content = "Prevents all damage." })
    T:AddToggle("GodMode", {
        Title   = "God Mode",
        Default = false,
        Callback = function(v)
            State.godOn = v
            if v then
                local hum = getHum()
                if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
                State.godConn = RunService.Heartbeat:Connect(function()
                    local h = getHum(); if h then h.Health = h.MaxHealth end
                end)
            else
                if State.godConn then State.godConn:Disconnect(); State.godConn = nil end
            end
        end,
    })

    -- Fly
    T:AddParagraph({
        Title   = "Fly",
        Content = "PC: WASD to move, camera angle controls pitch.\nMobile: joystick to move.",
    })
    T:AddSlider("FlySpeedSlider", {
        Title   = "Fly Speed",
        Min     = 10, Max = 500, Default = 50, Rounding = 0,
        Callback = function(v) State.flySpeed = v end,
    })
    T:AddToggle("FlyToggle", {
        Title   = "Fly",
        Default = false,
        Callback = function(v)
            if v then startFly() else stopFly() end
        end,
    })

    -- Noclip
    T:AddParagraph({ Title = "Noclip", Content = "Walk through walls." })
    T:AddToggle("NoclipToggle", {
        Title   = "Noclip",
        Default = false,
        Callback = function(v)
            if v then startNoclip() else stopNoclip() end
        end,
    })

    T:AddButton({
        Title       = "Reset Player Stats",
        Description = "Resets WalkSpeed, JumpPower and Health to default.",
        Callback    = function()
            local hum = getHum()
            if hum then
                hum.WalkSpeed = 16; hum.JumpPower = 50
                hum.MaxHealth = 100; hum.Health = 100
            end
            Fluent:Notify({ Title = "Player", Content = "Stats reset to default.", Duration = 2 })
        end,
    })
end

-- ═══════════════════════════════════════════════════
--  TAB: Auto Farm
-- ═══════════════════════════════════════════════════
do
    local T = Tabs.AutoFarm

    -- Manual points
    T:AddParagraph({
        Title   = "Manual Points  (up to 4)",
        Content = "Sit on moped, ride to each point, save P1-P4.\nFarm loops through all saved points in order.",
    })

    local pointLabels = {}
    for i = 1, 4 do
        local lbl = T:AddParagraph({ Title = "P" .. i, Content = "Not set" })
        pointLabels[i] = lbl
        T:AddButton({
            Title    = "Save P" .. i,
            Callback = function()
                local vr = getVehicleRoot()
                if not vr then
                    Fluent:Notify({ Title = "Auto Farm", Content = "Sit on the moped first.", Duration = 3 })
                    return
                end
                State.farmPoints[i] = vr.Position
                local p = State.farmPoints[i]
                -- Update paragraph content
                lbl.Content = string.format("X: %.1f  Y: %.1f  Z: %.1f", p.X, p.Y, p.Z)
                Fluent:Notify({
                    Title   = "P" .. i .. " Saved",
                    Content = string.format("X: %.1f  Y: %.1f  Z: %.1f", p.X, p.Y, p.Z),
                    Duration = 2,
                })
            end,
        })
    end

    T:AddButton({
        Title    = "Clear All Points",
        Callback = function()
            State.farmPoints = {}
            for i = 1, 4 do pointLabels[i].Content = "Not set" end
            stopFarm()
            Fluent:Notify({ Title = "Auto Farm", Content = "All points cleared.", Duration = 2 })
        end,
    })

    -- Full Auto (preset coordinates for Moped Drag race track)
    T:AddParagraph({
        Title   = "Full Auto  (Preset)",
        Content = "Automatically farms between the two race track points.\nX: 11185  Y: 4  Z: 836  <->  X: 15777  Y: 4  Z: 836",
    })
    T:AddToggle("FullAutoToggle", {
        Title   = "Full Auto Farm  (Preset Coordinates)",
        Default = false,
        Callback = function(v)
            if v then
                local presetPoints = {
                    Vector3.new(11185, 4, 836),
                    Vector3.new(15777, 4, 836),
                }
                if not getVehicleRoot() then
                    Fluent:Notify({ Title = "Auto Farm", Content = "Sit on the moped first.", Duration = 3 })
                    Options.FullAutoToggle:SetValue(false)
                    return
                end
                stopFarm()
                local ok, msg = startFarm(presetPoints)
                if not ok then
                    Fluent:Notify({ Title = "Auto Farm", Content = msg, Duration = 3 })
                    Options.FullAutoToggle:SetValue(false)
                end
            else
                stopFarm()
            end
        end,
    })

    -- Manual toggle
    T:AddToggle("ManualFarmToggle", {
        Title   = "Manual Farm Loop  (P1-P4)",
        Default = false,
        Callback = function(v)
            if v then
                local ok, msg = startFarm(State.farmPoints)
                if not ok then
                    Fluent:Notify({ Title = "Auto Farm", Content = msg, Duration = 3 })
                    Options.ManualFarmToggle:SetValue(false)
                end
            else
                stopFarm()
            end
        end,
    })

    T:AddParagraph({ Title = "Farm Settings", Content = "" })
    T:AddSlider("FarmSpeed", {
        Title    = "Farm Speed",
        Min      = 10, Max = 1000, Default = 150, Rounding = 0,
        Callback = function(v) State.farmSpeed = v end,
    })
    T:AddSlider("ArrivalDist", {
        Title    = "Arrival Distance",
        Min      = 3, Max = 40, Default = 12, Rounding = 0,
        Callback = function(v) State.arrivalDist = v end,
    })
    T:AddButton({
        Title    = "Force Stop Farm",
        Callback = function()
            stopFarm()
            Fluent:Notify({ Title = "Auto Farm", Content = "Stopped.", Duration = 2 })
        end,
    })
end

-- ═══════════════════════════════════════════════════
--  TAB: Speed Boost
-- ═══════════════════════════════════════════════════
do
    local T = Tabs.SpeedBoost

    T:AddParagraph({
        Title   = "Moped Speed Boost",
        Content = "Multiplies current moped velocity while keeping direction.\nPC: hold W.  Mobile: joystick.",
    })
    T:AddSlider("BoostMulti", {
        Title    = "Speed Multiplier",
        Min      = 1, Max = 20, Default = 2, Rounding = 1,
        Callback = function(v) State.boostMulti = v end,
    })
    T:AddToggle("BoostToggle", {
        Title   = "Enable Speed Boost",
        Default = false,
        Callback = function(v)
            if v then startBoost() else stopBoost() end
        end,
    })

    T:AddParagraph({
        Title   = "Moped Physics Override",
        Content = "Directly patches VehicleSeat MaxSpeed and HingeConstraint torque.\nApply while sitting on moped.",
    })
    local mopedMaxSpd    = 300
    local mopedMaxTorque = 50000
    T:AddSlider("MopedMaxSpeed", {
        Title    = "Max Speed Override",
        Min      = 50, Max = 1000, Default = 300, Rounding = 0,
        Callback = function(v) mopedMaxSpd = v end,
    })
    T:AddSlider("MopedMaxTorque", {
        Title    = "Max Torque  (RPM Override)",
        Min      = 1000, Max = 500000, Default = 50000, Rounding = 0,
        Callback = function(v) mopedMaxTorque = v end,
    })
    T:AddButton({
        Title       = "Apply to Moped Now",
        Description = "Must be sitting on the moped.",
        Callback    = function()
            local ok = overrideMopedPhysics(mopedMaxSpd, mopedMaxTorque)
            Fluent:Notify({
                Title   = ok and "Moped Override Applied" or "Failed",
                Content = ok and ("MaxSpeed: " .. mopedMaxSpd .. "   Torque: " .. mopedMaxTorque) or "Sit on the moped first.",
                Duration = 3,
            })
        end,
    })
end

-- ═══════════════════════════════════════════════════
--  TAB: Misc
-- ═══════════════════════════════════════════════════
do
    local T = Tabs.Misc

    -- Anti AFK
    T:AddParagraph({ Title = "Anti AFK", Content = "Uses VirtualUser on idle event only. Zero performance cost." })
    T:AddToggle("AntiAFK", {
        Title   = "Anti AFK",
        Default = false,
        Callback = function(v)
            State.afkOn = v
            if v then
                player.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), camera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), camera.CFrame)
                end)
                Fluent:Notify({ Title = "Anti AFK", Content = "ON", Duration = 2 })
            else
                Fluent:Notify({ Title = "Anti AFK", Content = "OFF  (takes effect after next idle)", Duration = 3 })
            end
        end,
    })

    -- Rejoin / Server Hop
    T:AddParagraph({ Title = "Server", Content = "" })
    T:AddButton({
        Title    = "Rejoin Server",
        Callback = function()
            Fluent:Notify({ Title = "Rejoin", Content = "Rejoining...", Duration = 2 })
            task.wait(1)
            TeleportService:Teleport(game.PlaceId, player)
        end,
    })
    T:AddButton({
        Title    = "Hop to New Server",
        Callback = function()
            Fluent:Notify({ Title = "Server Hop", Content = "Finding new server...", Duration = 2 })
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end,
    })

    -- Teleport to Player (dropdown)
    T:AddParagraph({
        Title   = "Teleport to Player",
        Content = "Select a player from the list then press Teleport.",
    })
    local tpTarget = ""
    local function getPlayerNames()
        local names = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then table.insert(names, p.Name) end
        end
        return #names > 0 and names or { "No other players" }
    end
    local tpDropdown = T:AddDropdown("TPDropdown", {
        Title   = "Select Player",
        Values  = getPlayerNames(),
        Multi   = false,
        Default = 1,
    })
    tpDropdown:OnChanged(function(v)
        tpTarget = v
    end)
    T:AddButton({
        Title    = "Refresh Player List",
        Callback = function()
            local names = getPlayerNames()
            tpDropdown:SetValues(names)
            Fluent:Notify({ Title = "Player List", Content = table.concat(names, ", "), Duration = 4 })
        end,
    })
    T:AddButton({
        Title    = "Teleport",
        Callback = function()
            if tpTarget == "" or tpTarget == "No other players" then
                Fluent:Notify({ Title = "Teleport", Content = "Select a player first.", Duration = 2 }); return
            end
            local target = Players:FindFirstChild(tpTarget)
            if not target then Fluent:Notify({ Title = "Teleport", Content = "Player not found.", Duration = 2 }); return end
            local tc = target.Character
            if not tc then Fluent:Notify({ Title = "Teleport", Content = "Target has no character.", Duration = 2 }); return end
            local hrp = getHRP()
            if not hrp then return end
            hrp.CFrame = tc:GetPrimaryPartCFrame() + Vector3.new(0, 3, 0)
            Fluent:Notify({ Title = "Teleport", Content = "Teleported to " .. target.Name, Duration = 2 })
        end,
    })

    -- FPS Boost
    T:AddParagraph({ Title = "FPS Boost", Content = "Disables particles, shadows, lowers render quality." })
    T:AddToggle("FPSBoost", {
        Title   = "FPS Boost",
        Default = false,
        Callback = function(v)
            State.fpsBoostOn = v
            if v then applyFpsBoost() else removeFpsBoost() end
        end,
    })

    -- FPS Counter visibility
    T:AddToggle("ShowFPS", {
        Title   = "Show FPS Counter",
        Default = true,
        Callback = function(v) fpsGui.Enabled = v end,
    })
end

-- ═══════════════════════════════════════════════════
--  TAB: Settings  (Fluent SaveManager + InterfaceManager)
-- ═══════════════════════════════════════════════════
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("AnsonDev")
SaveManager:SetFolder("AnsonDev/MopedDrag")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- ═══════════════════════════════════════════════════
--  Respawn: restore active features
-- ═══════════════════════════════════════════════════
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    if State.walkEnabled  then hum.WalkSpeed = State.walkVal end
    if State.jumpEnabled  then hum.UseJumpPower = true; hum.JumpPower = State.jumpVal end
    if State.flyEnabled   then startFly()    end
    if State.noclipEnabled then startNoclip() end
    if State.boostEnabled then startBoost()  end
    if State.godOn then
        hum.MaxHealth = math.huge; hum.Health = math.huge
        if State.godConn then State.godConn:Disconnect() end
        State.godConn = RunService.Heartbeat:Connect(function()
            local h = getHum(); if h then h.Health = h.MaxHealth end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
--  Init
-- ═══════════════════════════════════════════════════
Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title      = "AnsonDev",
    Content    = "Moped Drag v1.0 loaded.",
    SubContent = "RightCtrl to minimize",
    Duration   = 5,
})
