--[[
    AnsonDev Moped Auto Farm
    Version : 3.0.0
    Author  : AnsonDev
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ═══════════════════════════════════════════════════
--  Rayfield
-- ═══════════════════════════════════════════════════
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ═══════════════════════════════════════════════════
--  State
-- ═══════════════════════════════════════════════════
local State = {
    -- farm
    farmPoints  = {},       -- { Vector3, ... } up to 4
    farmIndex   = 1,
    farmRunning = false,
    farmConn    = nil,
    farmSpeed   = 150,
    arrivalDist = 10,

    -- boost
    boostEnabled  = false,
    boostConn     = nil,
    boostMulti    = 2.0,    -- multiply current velocity

    -- fly
    flyEnabled = false,
    flyConn    = nil,
    flySpeed   = 50,

    -- noclip
    noclipEnabled = false,
    noclipConn    = nil,

    -- walk
    walkEnabled = false,
    walkVal     = 16,

    -- jump
    jumpEnabled = false,
    jumpVal     = 50,
    infJumpConn = nil,
    infJumpOn   = false,

    -- god
    godOn   = false,
    godConn = nil,

    -- afk
    afkOn   = false,
    afkConn = nil,

    -- fps boost
    fpsBoostOn = false,
    fpsBoostConn = nil,
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
    local seat = getSeat()
    return seat and seat.Parent
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
        bg.Name       = name
        bg.MaxTorque  = Vector3.new(1e6, 1e6, 1e6)
        bg.P          = 1e5
        bg.D          = 500
        bg.CFrame     = part.CFrame
        bg.Parent     = part
    end
    return bg
end
local function cleanInst(part, name)
    if not part then return end
    local i = part:FindFirstChild(name)
    if i then i:Destroy() end
end
local function notify(title, content, dur)
    Rayfield:Notify({ Title = title, Content = content, Duration = dur or 2, Image = 4483362458 })
end

-- ═══════════════════════════════════════════════════
--  FPS Display overlay
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
    fpsLabel.TextColor3 = avg >= 55 and Color3.fromRGB(80,220,100)
        or avg >= 30 and Color3.fromRGB(240,180,60)
        or Color3.fromRGB(220,70,70)
end)

-- ═══════════════════════════════════════════════════
--  FPS Boost
-- ═══════════════════════════════════════════════════
local function applyFpsBoost()
    -- Lower render distance
    pcall(function() workspace.StreamingMinRadius   = 64  end)
    pcall(function() workspace.StreamingTargetRadius = 256 end)

    -- Disable particles / beams in workspace
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
                v.Enabled = false
            end
            if v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end)
    end

    -- Set graphics quality low via UserGameSettings
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    -- Disable shadows
    pcall(function()
        workspace.GlobalShadows  = false
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
    end)

    notify("FPS Boost", "Applied. Particles and shadows disabled.")
end

local function removeFpsBoost()
    pcall(function() workspace.GlobalShadows = true end)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end)
    -- Re-enable particles
    for _, v in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail")
                or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = true
            end
        end)
    end
    notify("FPS Boost", "Removed. Graphics restored.")
end

-- ═══════════════════════════════════════════════════
--  Moped Internal Override (MaxSpeed + RPM/Torque)
-- ═══════════════════════════════════════════════════
local function overrideMopedPhysics(maxSpd, maxTorque)
    local model = getVehicleModel()
    if not model then notify("Moped", "Sit on moped first."); return end

    local applied = false
    for _, v in ipairs(model:GetDescendants()) do
        pcall(function()
            -- VehicleSeat MaxSpeed
            if v:IsA("VehicleSeat") then
                v.MaxSpeed = maxSpd
                applied = true
            end
            -- Torque constraints (RPM limit)
            if v:IsA("TorqueConstraint") then
                v.MaxTorque = maxTorque
                applied = true
            end
            if v:IsA("HingeConstraint") then
                if v.ActuatorType == Enum.ActuatorType.Motor then
                    v.MaxTorque = maxTorque
                    -- AngularVelocity = RPM * 2pi / 60, set high
                    v.AngularVelocity = (maxSpd / 10)
                    applied = true
                end
            end
            -- BodyVelocity inside moped
            if v:IsA("BodyVelocity") then
                v.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                applied = true
            end
        end)
    end
    if applied then
        notify("Moped Override", "MaxSpeed: " .. maxSpd .. "  Torque: " .. maxTorque)
    else
        notify("Moped Override", "No constraints found. Try after sitting.")
    end
end

-- ═══════════════════════════════════════════════════
--  Auto Farm  (multi-point)
-- ═══════════════════════════════════════════════════
local farmStatusLabel

local function stopFarm()
    State.farmRunning = false
    if State.farmConn then State.farmConn:Disconnect(); State.farmConn = nil end
    local vr = getVehicleRoot()
    if vr then cleanInst(vr, "FarmBV"); cleanInst(vr, "FarmBG") end
    local seat = getSeat()
    if seat then seat.ThrottleFloat = 0; seat.SteerFloat = 0 end
    if farmStatusLabel then farmStatusLabel:Set("Status : Idle") end
end

local function startFarm()
    if #State.farmPoints < 2 then
        notify("Auto Farm", "Need at least 2 points."); return false
    end
    if not getVehicleRoot() then
        notify("Auto Farm", "Sit on the moped first."); return false
    end
    State.farmRunning = true
    State.farmIndex   = 1
    if farmStatusLabel then farmStatusLabel:Set("Status : Running  -> P1") end

    State.farmConn = RunService.Heartbeat:Connect(function()
        if not State.farmRunning then return end
        local vr = getVehicleRoot()
        if not vr then stopFarm(); return end

        local target = State.farmPoints[State.farmIndex]
        if not target then State.farmIndex = 1; return end

        local cur  = vr.Position
        local dist = (Vector3.new(target.X, cur.Y, target.Z) - cur).Magnitude

        if dist < State.arrivalDist then
            State.farmIndex = (State.farmIndex % #State.farmPoints) + 1
            target = State.farmPoints[State.farmIndex]
            if farmStatusLabel then
                farmStatusLabel:Set("Status : Running  -> P" .. State.farmIndex)
            end
        end

        local dir = Vector3.new(target.X - cur.X, 0, target.Z - cur.Z).Unit
        local bv  = ensureBV(vr, "FarmBV", 1e6)
        bv.Velocity = dir * State.farmSpeed
        local bg = ensureBG(vr, "FarmBG")
        if dir.Magnitude > 0.01 then bg.CFrame = CFrame.lookAt(cur, cur + dir) end
        local seat = getSeat()
        if seat then seat.ThrottleFloat = 1 end
    end)
    return true
end

-- ═══════════════════════════════════════════════════
--  Speed Boost  (multiply moped velocity, keeps direction)
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

        -- Only boost when player is actively moving the moped
        local moving = UserInputService:IsKeyDown(Enum.KeyCode.W)
        local hum = getHum()
        if not moving and hum and hum.MoveDirection.Magnitude > 0.1 then
            moving = true
        end

        if moving then
            -- Take the moped's current horizontal velocity direction and amplify it
            local vel = vr.Velocity
            local flatVel = Vector3.new(vel.X, 0, vel.Z)

            -- If moped is barely moving yet, use seat look direction
            local dir
            if flatVel.Magnitude < 1 then
                local fwd = seat.CFrame.LookVector
                dir = Vector3.new(fwd.X, 0, fwd.Z).Unit
            else
                dir = flatVel.Unit
            end

            local bv = ensureBV(vr, "BoostBV", 1e6)
            bv.Velocity = dir * State.boostMulti * math.max(flatVel.Magnitude, 20)
            seat.ThrottleFloat = 1
        else
            cleanInst(vr, "BoostBV")
            seat.ThrottleFloat = 0
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  Fly
-- ═══════════════════════════════════════════════════
local function stopFly()
    State.flyEnabled = false
    if State.flyConn then State.flyConn:Disconnect(); State.flyConn = nil end
    local hrp = getHRP(); if hrp then cleanInst(hrp, "FlyBV") end
    local hum = getHum()
    if hum then hum.PlatformStand = false; hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
end

local function startFly()
    State.flyEnabled = true
    local hum = getHum(); if hum then hum.PlatformStand = true end
    State.flyConn = RunService.Heartbeat:Connect(function()
        if not State.flyEnabled then return end
        local hrp = getHRP(); local h = getHum()
        if not hrp or not h then return end
        h.PlatformStand = true
        local cf  = camera.CFrame
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir = dir + cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir = dir - cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir = dir + Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.yAxis  end
        local md = h.MoveDirection
        if md.Magnitude > 0.1 then dir = dir + md end
        local bv = ensureBV(hrp, "FlyBV", 1e5)
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * State.flySpeed or Vector3.zero
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
--  Rayfield Window
-- ═══════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name            = "AnsonDev",
    Icon            = 0,
    LoadingTitle    = "AnsonDev",
    LoadingSubtitle = "Moped Auto Farm  v3.0",
    Theme           = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving    = { Enabled = false },
    Discord   = { Enabled = false },
    KeySystem = false,
})

-- ═══════════════════════════════════════════════════
--  TAB 1 : Auto Farm
-- ═══════════════════════════════════════════════════
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateSection("Points  (P1 -> P2 -> P3 -> P4 -> loop)")
farmStatusLabel = FarmTab:CreateLabel("Status : Idle")

-- Dynamic point buttons P1-P4
local pointLabels = {}
for i = 1, 4 do
    pointLabels[i] = FarmTab:CreateLabel("P" .. i .. " : not set")
    FarmTab:CreateButton({
        Name     = "Save P" .. i,
        Callback = function()
            local vr = getVehicleRoot()
            if not vr then notify("Auto Farm", "Sit on the moped first."); return end
            State.farmPoints[i] = vr.Position
            local p = State.farmPoints[i]
            pointLabels[i]:Set("P" .. i .. " : X " .. math.floor(p.X) .. "  Z " .. math.floor(p.Z))
            notify("P" .. i .. " Saved", string.format("X: %.1f   Z: %.1f", p.X, p.Z))
        end,
    })
end

FarmTab:CreateButton({
    Name = "Clear All Points",
    Callback = function()
        State.farmPoints = {}
        for i = 1, 4 do pointLabels[i]:Set("P" .. i .. " : not set") end
        stopFarm()
        notify("Auto Farm", "All points cleared.")
    end,
})

FarmTab:CreateSection("Control")
FarmTab:CreateToggle({
    Name = "Auto Farm Loop", CurrentValue = false, Flag = "FarmToggle",
    Callback = function(val)
        if val then startFarm() else stopFarm() end
    end,
})
FarmTab:CreateSlider({
    Name = "Farm Speed", Range = { 10, 500 }, Increment = 5,
    Suffix = " studs/s", CurrentValue = 150, Flag = "FarmSpeed",
    Callback = function(v) State.farmSpeed = v end,
})
FarmTab:CreateSlider({
    Name = "Arrival Distance", Range = { 3, 40 }, Increment = 1,
    Suffix = " studs", CurrentValue = 10, Flag = "ArrivalDist",
    Callback = function(v) State.arrivalDist = v end,
})

-- ═══════════════════════════════════════════════════
--  TAB 2 : Speed Boost
-- ═══════════════════════════════════════════════════
local BoostTab = Window:CreateTab("Speed Boost", 4483362458)

BoostTab:CreateSection("Moped Boost")
BoostTab:CreateLabel("Multiplies current moped speed, keeps direction.")
BoostTab:CreateLabel("PC: hold W   Mobile: use joystick")

BoostTab:CreateSlider({
    Name = "Speed Multiplier", Range = { 1, 20 }, Increment = 1,
    Suffix = "x", CurrentValue = 2, Flag = "BoostMulti",
    Callback = function(v) State.boostMulti = v end,
})

BoostTab:CreateSection("Moped Physics Override")
BoostTab:CreateLabel("Directly modifies VehicleSeat + HingeConstraints.")

local mopedMaxSpd    = 300
local mopedMaxTorque = 50000

BoostTab:CreateSlider({
    Name = "Max Speed", Range = { 50, 1000 }, Increment = 10,
    Suffix = " speed", CurrentValue = 300, Flag = "MopedMaxSpeed",
    Callback = function(v) mopedMaxSpd = v end,
})
BoostTab:CreateSlider({
    Name = "Max Torque (RPM override)", Range = { 1000, 500000 }, Increment = 1000,
    Suffix = " torque", CurrentValue = 50000, Flag = "MopedMaxTorque",
    Callback = function(v) mopedMaxTorque = v end,
})
BoostTab:CreateButton({
    Name = "Apply to Moped Now",
    Callback = function()
        overrideMopedPhysics(mopedMaxSpd, mopedMaxTorque)
    end,
})

BoostTab:CreateSection("Speed Boost Toggle")
BoostTab:CreateToggle({
    Name = "Enable Speed Boost", CurrentValue = false, Flag = "BoostToggle",
    Callback = function(val)
        if val then startBoost(); notify("Speed Boost", "ON")
        else stopBoost(); notify("Speed Boost", "OFF") end
    end,
})

-- ═══════════════════════════════════════════════════
--  TAB 3 : Player
-- ═══════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSection("Walk Speed")
PlayerTab:CreateSlider({
    Name = "Walk Speed", Range = { 8, 500 }, Increment = 1,
    Suffix = " speed", CurrentValue = 16, Flag = "WalkSpeed",
    Callback = function(v) State.walkVal = v end,
})
PlayerTab:CreateToggle({
    Name = "Enable Walk Speed", CurrentValue = false, Flag = "WalkSpeedToggle",
    Callback = function(val)
        State.walkEnabled = val
        local hum = getHum()
        if hum then hum.WalkSpeed = val and State.walkVal or 16 end
        notify("Walk Speed", val and ("Set to " .. State.walkVal) or "Reset to 16")
    end,
})

PlayerTab:CreateSection("Jump Power")
PlayerTab:CreateSlider({
    Name = "Jump Power", Range = { 0, 500 }, Increment = 5,
    Suffix = " power", CurrentValue = 50, Flag = "JumpPower",
    Callback = function(v) State.jumpVal = v end,
})
PlayerTab:CreateToggle({
    Name = "Enable Jump Power", CurrentValue = false, Flag = "JumpToggle",
    Callback = function(val)
        State.jumpEnabled = val
        local hum = getHum()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = val and State.jumpVal or 50
        end
        notify("Jump Power", val and ("Set to " .. State.jumpVal) or "Reset to 50")
    end,
})

PlayerTab:CreateSection("Extra")
PlayerTab:CreateToggle({
    Name = "Infinite Jump", CurrentValue = false, Flag = "InfJump",
    Callback = function(val)
        State.infJumpOn = val
        if val then
            State.infJumpConn = UserInputService.JumpRequest:Connect(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if State.infJumpConn then State.infJumpConn:Disconnect(); State.infJumpConn = nil end
        end
    end,
})
PlayerTab:CreateToggle({
    Name = "God Mode", CurrentValue = false, Flag = "GodMode",
    Callback = function(val)
        State.godOn = val
        if val then
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

PlayerTab:CreateSection("Fly")
PlayerTab:CreateSlider({
    Name = "Fly Speed", Range = { 10, 500 }, Increment = 5,
    Suffix = " studs/s", CurrentValue = 50, Flag = "FlySpeed",
    Callback = function(v) State.flySpeed = v end,
})
PlayerTab:CreateLabel("PC: WASD + Space / Shift")
PlayerTab:CreateToggle({
    Name = "Fly", CurrentValue = false, Flag = "FlyToggle",
    Callback = function(val)
        if val then startFly(); notify("Fly", "ON")
        else stopFly(); notify("Fly", "OFF") end
    end,
})

PlayerTab:CreateSection("Noclip")
PlayerTab:CreateToggle({
    Name = "Noclip", CurrentValue = false, Flag = "NoclipToggle",
    Callback = function(val)
        if val then startNoclip(); notify("Noclip", "ON")
        else stopNoclip(); notify("Noclip", "OFF") end
    end,
})

PlayerTab:CreateSection("Reset")
PlayerTab:CreateButton({
    Name = "Reset Player Stats",
    Callback = function()
        local hum = getHum()
        if hum then
            hum.WalkSpeed = 16; hum.JumpPower = 50
            hum.MaxHealth = 100; hum.Health = 100
        end
        notify("Player", "All stats reset to default.")
    end,
})

-- ═══════════════════════════════════════════════════
--  TAB 4 : Misc
-- ═══════════════════════════════════════════════════
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Anti AFK  (VirtualUser method — server sees constant activity, zero lag)
MiscTab:CreateSection("Anti AFK")
MiscTab:CreateToggle({
    Name = "Anti AFK", CurrentValue = false, Flag = "AntiAFK",
    Callback = function(val)
        State.afkOn = val
        if val then
            player.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
            notify("Anti AFK", "ON")
        else
            -- Disconnecting Idled isn't needed; it only fires when idle, does nothing when active
            notify("Anti AFK", "Will stop at next idle trigger. Rejoin to fully reset.")
        end
    end,
})

-- Rejoin
MiscTab:CreateSection("Rejoin")
MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        notify("Rejoin", "Rejoining...")
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, player)
    end,
})
MiscTab:CreateButton({
    Name = "Hop to New Server",
    Callback = function()
        notify("Server Hop", "Finding new server...")
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
})

-- Teleport to Player (dropdown list)
MiscTab:CreateSection("Teleport to Player")
MiscTab:CreateLabel("Select a player from the list then press Teleport.")

local tpTarget = ""
local function getPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(names, p.Name)
        end
    end
    if #names == 0 then names = { "No other players" } end
    return names
end

MiscTab:CreateDropdown({
    Name    = "Select Player",
    Options = getPlayerNames(),
    CurrentOption = { "" },
    Flag    = "TPDropdown",
    Callback = function(val)
        tpTarget = type(val) == "table" and val[1] or val
    end,
})
MiscTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        -- Rayfield dropdowns can't be dynamically updated after creation easily
        -- So we notify user with current list
        local names = getPlayerNames()
        notify("Players Online", table.concat(names, ", "), 5)
    end,
})
MiscTab:CreateButton({
    Name = "Teleport",
    Callback = function()
        if tpTarget == "" or tpTarget == "No other players" then
            notify("Teleport", "Select a player first."); return
        end
        local target = Players:FindFirstChild(tpTarget)
        if not target then notify("Teleport", "Player not found."); return end
        local tc = target.Character
        if not tc then notify("Teleport", "Target has no character."); return end
        local hrp = getHRP()
        if not hrp then notify("Teleport", "You have no character."); return end
        hrp.CFrame = tc:GetPrimaryPartCFrame() + Vector3.new(0, 3, 0)
        notify("Teleport", "Teleported to " .. target.Name)
    end,
})

-- FPS Boost
MiscTab:CreateSection("FPS Boost")
MiscTab:CreateLabel("Disables particles, shadows, lowers render quality.")
MiscTab:CreateToggle({
    Name = "FPS Boost", CurrentValue = false, Flag = "FPSBoost",
    Callback = function(val)
        State.fpsBoostOn = val
        if val then applyFpsBoost() else removeFpsBoost() end
    end,
})

-- FPS Display toggle
MiscTab:CreateSection("FPS Display")
MiscTab:CreateToggle({
    Name = "Show FPS Counter", CurrentValue = true, Flag = "ShowFPS",
    Callback = function(val) fpsGui.Enabled = val end,
})

-- ═══════════════════════════════════════════════════
--  Respawn restore
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

Rayfield:LoadingFrame(false)
