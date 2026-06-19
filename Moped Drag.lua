--[[
    AnsonDev - Merge a Nuke
    Version : 1.0.0
    Author  : AnsonDev
    UI      : WindUI
]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local player  = Players.LocalPlayer
local camera  = workspace.CurrentCamera
local PlayerId = tonumber(player.UserId)

local S = {
    AutoMerge=false, AutoPickUp=false, AutoLock=false, AutoUpgrade=false, SelectedUpgrades={},
    walkEnabled=false, walkVal=16, jumpEnabled=false, jumpVal=50, infJumpConn=nil,
    godOn=false, godConn=nil,
    flyEnabled=false, flyConn=nil, flyTpConn=nil, flyNowe=false, flySpeed=50,
    noclipEnabled=false, noclipConn=nil,
    EspEnabled=false, EspConns={},
    EspFolder=Workspace:FindFirstChild("AnsonDevESP") or Instance.new("Folder",Workspace),
    fpsBoostOn=false,
}
S.EspFolder.Name="AnsonDevESP"

local function getChar()  return player.Character end
local function getHRP()   local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function isR6()     local c=getChar(); return c and c:FindFirstChild("Torso")~=nil end
local function getTorso() local c=getChar(); if not c then return nil end; return isR6() and c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso") end
local function ensureBV(part,name,force)
    local bv=part:FindFirstChild(name); if not bv then bv=Instance.new("BodyVelocity"); bv.Name=name; bv.MaxForce=Vector3.new(force,force,force); bv.Velocity=Vector3.zero; bv.Parent=part end; return bv
end
local function ensureBG(part,name)
    local bg=part:FindFirstChild(name); if not bg then bg=Instance.new("BodyGyro"); bg.Name=name; bg.MaxTorque=Vector3.new(9e9,9e9,9e9); bg.P=9e4; bg.D=500; bg.CFrame=part.CFrame; bg.Parent=part end; return bg
end
local function cleanInst(part,name) if not part then return end; local i=part:FindFirstChild(name); if i then i:Destroy() end end
local function notify(t,c) WindUI:Notify({Title=t,Content=c or "",Duration=3}) end

local function getPlayerBase()
    local bases=Workspace:FindFirstChild("Bases"); if not bases then return nil end
    for _,f in ipairs(bases:GetChildren()) do local a=f:GetAttribute("OwnerUserId"); if a and tonumber(a)==PlayerId then return f end end
end
local function teleportTo(obj)
    if not obj or not getChar() then return end; local root=getHRP(); local pos
    if obj:IsA("Model") then pos=obj:GetPivot().Position elseif obj:IsA("BasePart") then pos=obj.Position end
    if root and pos then root.CFrame=CFrame.new(pos+Vector3.new(0,2,0)) end
end

-- FPS Overlay
local fpsGui=Instance.new("ScreenGui"); fpsGui.Name="AnsonDevFPS"; fpsGui.ResetOnSpawn=false
fpsGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; fpsGui.Parent=player:WaitForChild("PlayerGui")
local fpsBg=Instance.new("Frame"); fpsBg.Size=UDim2.new(0,80,0,24); fpsBg.Position=UDim2.new(1,-90,0,8)
fpsBg.BackgroundColor3=Color3.fromRGB(8,8,12); fpsBg.BackgroundTransparency=0.1; fpsBg.BorderSizePixel=0; fpsBg.Parent=fpsGui
Instance.new("UICorner",fpsBg).CornerRadius=UDim.new(0,6)
local fpsStroke=Instance.new("UIStroke",fpsBg); fpsStroke.Color=Color3.fromRGB(60,60,80); fpsStroke.Thickness=1
local fpsLbl=Instance.new("TextLabel"); fpsLbl.Size=UDim2.new(1,0,1,0); fpsLbl.BackgroundTransparency=1
fpsLbl.Text="FPS  --"; fpsLbl.TextColor3=Color3.fromRGB(120,220,120); fpsLbl.TextSize=12; fpsLbl.Font=Enum.Font.GothamBold; fpsLbl.Parent=fpsBg
local fpsSamples={}
RunService.Heartbeat:Connect(function(dt)
    table.insert(fpsSamples,1/dt); if #fpsSamples>30 then table.remove(fpsSamples,1) end
    local sum=0; for _,v in ipairs(fpsSamples) do sum=sum+v end
    local avg=math.floor(sum/#fpsSamples); fpsLbl.Text="FPS  "..avg
    fpsLbl.TextColor3=avg>=55 and Color3.fromRGB(80,220,100) or avg>=30 and Color3.fromRGB(240,180,60) or Color3.fromRGB(220,70,70)
end)

local function applyFpsBoost()
    pcall(function() workspace.GlobalShadows=false end)
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
    for _,v in ipairs(workspace:GetDescendants()) do pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled=false end end) end
end
local function removeFpsBoost()
    pcall(function() workspace.GlobalShadows=true end)
    pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic end)
    for _,v in ipairs(workspace:GetDescendants()) do pcall(function()
        if v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled=true end end) end
end

-- Fly
local flyStates={Enum.HumanoidStateType.Climbing,Enum.HumanoidStateType.FallingDown,Enum.HumanoidStateType.Flying,Enum.HumanoidStateType.Freefall,Enum.HumanoidStateType.GettingUp,Enum.HumanoidStateType.Jumping,Enum.HumanoidStateType.Landed,Enum.HumanoidStateType.Physics,Enum.HumanoidStateType.PlatformStanding,Enum.HumanoidStateType.Ragdoll,Enum.HumanoidStateType.Running,Enum.HumanoidStateType.RunningNoPhysics,Enum.HumanoidStateType.Seated,Enum.HumanoidStateType.StrafingNoPhysics,Enum.HumanoidStateType.Swimming}
local function stopFly()
    S.flyEnabled=false; S.flyNowe=false
    if S.flyConn then S.flyConn:Disconnect(); S.flyConn=nil end
    if S.flyTpConn then S.flyTpConn:Disconnect(); S.flyTpConn=nil end
    local torso=getTorso(); if torso then cleanInst(torso,"FlyBV"); cleanInst(torso,"FlyBG") end
    local hum=getHum(); local c=getChar()
    if hum then for _,st in ipairs(flyStates) do hum:SetStateEnabled(st,true) end; hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics); hum.PlatformStand=false end
    if c then local a=c:FindFirstChild("Animate"); if a then a.Disabled=false end
        local h2=c:FindFirstChildOfClass("Humanoid"); if h2 then for _,t in ipairs(h2:GetPlayingAnimationTracks()) do t:AdjustSpeed(1) end end end
end
local function startFly()
    S.flyEnabled=true; S.flyNowe=true
    local hum=getHum(); local c=getChar(); if not hum or not c then return end
    for _,st in ipairs(flyStates) do hum:SetStateEnabled(st,false) end
    hum:ChangeState(Enum.HumanoidStateType.Swimming); hum.PlatformStand=true
    S.flyTpConn=RunService.Heartbeat:Connect(function()
        if not S.flyNowe then return end; local chr=getChar(); local h=getHum()
        if chr and h and h.MoveDirection.Magnitude>0 then chr:TranslateBy(h.MoveDirection*(S.flySpeed*0.05)) end
    end)
    local torso=getTorso(); if not torso then return end
    ensureBG(torso,"FlyBG").CFrame=torso.CFrame; ensureBV(torso,"FlyBV",9e9).Velocity=Vector3.new(0,0.1,0)
    local speed,ctrl,last=0,{f=0,b=0,l=0,r=0},{f=0,b=0,l=0,r=0}
    S.flyConn=RunService.RenderStepped:Connect(function()
        if not S.flyNowe then return end; local h2=getHum(); if h2 then h2.PlatformStand=true end
        local ms=S.flySpeed
        ctrl.f=UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        ctrl.b=UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
        ctrl.l=UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        ctrl.r=UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        local hm=getHum(); if hm then local md=hm.MoveDirection
            if md.Magnitude>0.1 then
                if ctrl.f==0 and ctrl.b==0 then ctrl.f=md.Z<0 and 1 or (md.Z>0 and -1 or 0) end
                if ctrl.l==0 and ctrl.r==0 then ctrl.r=md.X>0 and 1 or (md.X<0 and -1 or 0) end end end
        local mov=(ctrl.l+ctrl.r)~=0 or (ctrl.f+ctrl.b)~=0
        if mov then speed=math.min(speed+0.5+(speed/ms),ms) elseif speed>0 then speed=math.max(speed-1,0) end
        local cf=camera.CoordinateFrame
        local bv=torso:FindFirstChild("FlyBV"); local bg=torso:FindFirstChild("FlyBG"); if not bv or not bg then return end
        if mov then
            bv.Velocity=((cf.LookVector*(ctrl.f+ctrl.b))+((cf*CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*0.2,0).Position)-cf.Position))*speed
            last={f=ctrl.f,b=ctrl.b,l=ctrl.l,r=ctrl.r}
        elseif speed>0 then
            bv.Velocity=((cf.LookVector*(last.f+last.b))+((cf*CFrame.new(last.l+last.r,(last.f+last.b)*0.2,0).Position)-cf.Position))*speed
        else bv.Velocity=Vector3.zero end
        bg.CFrame=cf*CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/ms),0,0)
    end)
end

-- Noclip
local function stopNoclip()
    S.noclipEnabled=false; if S.noclipConn then S.noclipConn:Disconnect(); S.noclipConn=nil end
    local c=getChar(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
end
local function startNoclip()
    S.noclipEnabled=true
    S.noclipConn=RunService.Stepped:Connect(function()
        if not S.noclipEnabled then stopNoclip(); return end
        local c=getChar(); if not c then return end
        for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
    end)
end

-- ESP
local function cleanESP(plr)
    if S.EspConns[plr] then for _,c in ipairs(S.EspConns[plr]) do c:Disconnect() end; S.EspConns[plr]=nil end
    local cont=S.EspFolder:FindFirstChild(plr.Name); if cont then cont:Destroy() end
end
local function buildESP(plr)
    if plr==player then return end; cleanESP(plr); S.EspConns[plr]={}
    local cont=Instance.new("Folder"); cont.Name=plr.Name; cont.Parent=S.EspFolder
    local function makeTag(char)
        if not char then return end; local root=char:WaitForChild("HumanoidRootPart",5); if not root then return end
        local bb=Instance.new("BillboardGui"); bb.AlwaysOnTop=true; bb.Size=UDim2.new(0,200,0,50)
        bb.StudsOffset=Vector3.new(0,3,0); bb.Adornee=root; bb.Parent=cont
        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text=plr.Name; lbl.TextColor3=Color3.fromRGB(255,60,60); lbl.TextSize=14; lbl.Font=Enum.Font.GothamBold
        lbl.TextStrokeTransparency=0; lbl.TextStrokeColor3=Color3.fromRGB(0,0,0); lbl.Parent=bb
    end
    if plr.Character then makeTag(plr.Character) end
    local conn=plr.CharacterAdded:Connect(function(c) task.wait(0.5); makeTag(c) end)
    table.insert(S.EspConns[plr],conn)
end

-- Window
local Window=WindUI:CreateWindow({
    Title="AnsonDev  |  Merge a Nuke", Folder="AnsonDev", Icon="zap", NewElements=true,
    Topbar={Height=48,ButtonsType="Mac"},
    OpenButton={Title="AnsonDev",CornerRadius=UDim.new(1,0),StrokeThickness=2,Enabled=true,Draggable=true,OnlyMobile=false,Scale=0.55,
        Color=ColorSequence.new(Color3.fromHex("#F7514F"),Color3.fromHex("#F59B1E"))},
})
Window:Tag({Title="v1.0.0",Icon="sparkles",Color=Color3.fromHex("#18181b"),Border=true})
Window:Tag({Title="Merge a Nuke",Icon="zap",Color=Color3.fromHex("#1e1e2e"),Border=true})
local All=Window:Section({Title="AnsonDev"})

-- TAB 1: Home
do
    local T=All:Tab({Title="Home",Icon="house"})
    local Hero=T:Section({Title="AnsonDev  |  Merge a Nuke"})
    Hero:Section({Title="Welcome back, "..player.Name,TextSize=24,FontWeight=Enum.FontWeight.Bold})
    Hero:Space()
    Hero:Section({Title="Full automation for Merge a Nuke.\nAuto Merge  •  Auto Pick Up  •  Auto Upgrade  •  Player Tools",TextSize=15,TextTransparency=0.35,FontWeight=Enum.FontWeight.Medium})
    T:Space({Columns=3})
    local sg=T:Group({})
    sg:Section({Title="Version",TextSize=12,TextTransparency=0.5}); sg:Section({Title="1.0.0",TextSize=18,FontWeight=Enum.FontWeight.Bold}); sg:Space()
    sg:Section({Title="Author",TextSize=12,TextTransparency=0.5}); sg:Section({Title="AnsonDev",TextSize=18,FontWeight=Enum.FontWeight.Bold}); sg:Space()
    sg:Section({Title="Game",TextSize=12,TextTransparency=0.5}); sg:Section({Title="Merge a Nuke",TextSize=18,FontWeight=Enum.FontWeight.Bold})
    T:Space({Columns=3})
    T:Paragraph({Title="Community  &  Support",Desc="Join the AnsonDev Discord for updates, bug reports and support.",Image="message-circle",
        Buttons={{Title="Join Discord",Icon="link",Callback=function() if setclipboard then setclipboard("https://discord.gg/FBaqTQqutg"); notify("Discord","Link copied.") end end}}})
    T:Space({Columns=3})
    local fg1=T:Group({})
    local f1=fg1:Section({Title="Auto Merge",Box=true,BoxBorder=true,Opened=true}); f1:Section({Title="Detects and merges matching nukes in your base automatically.",TextSize=13,TextTransparency=0.35})
    fg1:Space()
    local f2=fg1:Section({Title="Auto Upgrade",Box=true,BoxBorder=true,Opened=true}); f2:Section({Title="Continuously fires MAX / TIER / LOCKBASE upgrade events.",TextSize=13,TextTransparency=0.35})
    T:Space({Columns=2})
    local fg2=T:Group({})
    local f3=fg2:Section({Title="Auto Pick Up",Box=true,BoxBorder=true,Opened=true}); f3:Section({Title="Teleports to each nuke, picks it up, drops singles back.",TextSize=13,TextTransparency=0.35})
    fg2:Space()
    local f4=fg2:Section({Title="Player Tools",Box=true,BoxBorder=true,Opened=true}); f4:Section({Title="Fly, Noclip, Walk Speed, Jump Power, God Mode, ESP.",TextSize=13,TextTransparency=0.35})
end

-- TAB 2: Main - Nuke Automation
do
    local T=All:Tab({Title="Nuke Auto",Icon="zap"})
    local AS=T:Section({Title="Nuke Automation",Box=true,BoxBorder=true,Opened=true})
    AS:Toggle({Title="Auto Merge",Desc="Automatically merges matching nukes in your base",Callback=function(v)
        S.AutoMerge=v; if not v then return end
        task.spawn(function()
            while S.AutoMerge do
                local base=getPlayerBase()
                if base and base:FindFirstChild("Nukes") then
                    local counts={}
                    for _,nuke in ipairs(base.Nukes:GetChildren()) do
                        if nuke.Name=="Nuke" and nuke:FindFirstChild("OverheadNuke") and nuke.OverheadNuke:FindFirstChild("TextLabel") then
                            local t=nuke.OverheadNuke.TextLabel.Text
                            if t and t~="" then counts[t]=counts[t] or {}; table.insert(counts[t],nuke) end
                        end
                    end
                    for _,matches in pairs(counts) do
                        if #matches>=2 then
                            ReplicatedStorage.NukeRemotes.PickUp:FireServer(matches[1]); task.wait()
                            ReplicatedStorage.NukeRemotes.MergeRequest:FireServer(matches[2]); break
                        end
                    end
                end
                task.wait()
            end
        end)
    end})
    AS:Space()
    AS:Toggle({Title="Auto Pick Up All",Desc="Teleports to each nuke, picks up, drops singles back",Callback=function(v)
        S.AutoPickUp=v; if not v then return end
        task.spawn(function()
            while S.AutoPickUp do
                local base=getPlayerBase()
                if base and base:FindFirstChild("Nukes") then
                    local counts={}
                    for _,nuke in ipairs(base.Nukes:GetChildren()) do
                        if nuke.Name=="Nuke" and nuke:FindFirstChild("OverheadNuke") and nuke.OverheadNuke:FindFirstChild("TextLabel") then
                            local t=nuke.OverheadNuke.TextLabel.Text
                            if t and t~="" then counts[t]=counts[t] or {}; table.insert(counts[t],nuke) end
                        end
                    end
                    for _,nuke in ipairs(base.Nukes:GetChildren()) do
                        if not S.AutoPickUp then break end
                        if nuke.Name=="Nuke" and nuke:FindFirstChild("OverheadNuke") and nuke.OverheadNuke:FindFirstChild("TextLabel") then
                            local t=nuke.OverheadNuke.TextLabel.Text; local mc=counts[t] and #counts[t] or 0
                            local root=getHRP(); local origCF=root and root.CFrame
                            teleportTo(nuke); task.wait()
                            ReplicatedStorage.NukeRemotes.PickUp:FireServer(nuke); task.wait()
                            if mc<2 then
                                local drop=ReplicatedStorage.NukeRemotes.Drop
                                if root then drop:FireServer(root.CFrame) else drop:FireServer(CFrame.new(290.03,17.20,249.74)) end
                                task.wait()
                            end
                            if root and origCF then root.CFrame=origCF end
                        end
                    end
                end
                task.wait()
            end
        end)
    end})
    AS:Space()
    AS:Toggle({Title="Auto Lock Base",Desc="Continuously fires the lock base event",Callback=function(v)
        S.AutoLock=v; if not v then return end
        task.spawn(function() while S.AutoLock do task.wait(); ReplicatedStorage.NukeRemotes.RequestLockBase:FireServer() end end)
    end})
    T:Space()
    local US=T:Section({Title="Upgrade",Box=true,BoxBorder=true,Opened=true})
    US:Dropdown({Title="Select Upgrade Types",Desc="Choose which upgrades to fire (multi-select)",Values={"MAX","TIER","LOCKBASE"},Multi=true,Value=nil,AllowNone=true,
        Callback=function(v) S.SelectedUpgrades={}; if type(v)=="table" then for _,val in ipairs(v) do table.insert(S.SelectedUpgrades,val) end elseif v then table.insert(S.SelectedUpgrades,v) end end})
    US:Space()
    US:Toggle({Title="Auto Upgrade",Desc="Fires selected upgrade events continuously",Callback=function(v)
        S.AutoUpgrade=v; if not v then return end
        task.spawn(function()
            while S.AutoUpgrade do
                for _,utype in ipairs(S.SelectedUpgrades) do
                    if not S.AutoUpgrade then break end
                    ReplicatedStorage.NukeRemotes.PurchaseUpgrade:FireServer(utype)
                end
                task.wait()
            end
        end)
    end})
    T:Space()
    local TS=T:Section({Title="Teleport",Box=true,BoxBorder=true,Opened=true})
    local tg=TS:Group({})
    tg:Button({Title="To Spawn",Icon="home",Justify="Center",Callback=function()
        local root=getHRP(); if not root then return end
        local spawn=Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then root.CFrame=CFrame.new(spawn.Position+Vector3.new(0,5,0)) end
    end})
    tg:Space()
    tg:Button({Title="To My Base",Icon="map-pin",Justify="Center",Callback=function()
        local base=getPlayerBase(); if base then teleportTo(base) else notify("Teleport","Could not find your base.") end
    end})
end

-- TAB 3: Player
do
    local T=All:Tab({Title="Player",Icon="user"})
    local MS=T:Section({Title="Movement",Box=true,BoxBorder=true,Opened=true})
    MS:Slider({Title="Walk Speed",Step=1,Value={Min=16,Max=500,Default=16},Callback=function(v) S.walkVal=v; if S.walkEnabled then local h=getHum(); if h then h.WalkSpeed=v end end end})
    MS:Space()
    MS:Toggle({Title="Enable Walk Speed",Callback=function(v) S.walkEnabled=v; local h=getHum(); if h then h.WalkSpeed=v and S.walkVal or 16 end end})
    MS:Space()
    MS:Slider({Title="Jump Power",Step=5,Value={Min=50,Max=1000,Default=50},Callback=function(v) S.jumpVal=v; if S.jumpEnabled then local h=getHum(); if h then h.UseJumpPower=true; h.JumpPower=v end end end})
    MS:Space()
    MS:Toggle({Title="Enable Jump Power",Callback=function(v) S.jumpEnabled=v; local h=getHum(); if h then h.UseJumpPower=true; h.JumpPower=v and S.jumpVal or 50 end end})
    MS:Space()
    MS:Toggle({Title="Infinite Jump",Callback=function(v)
        if v then S.infJumpConn=UserInputService.JumpRequest:Connect(function() local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end)
        else if S.infJumpConn then S.infJumpConn:Disconnect(); S.infJumpConn=nil end end
    end})
    T:Space()
    local AS=T:Section({Title="Abilities",Box=true,BoxBorder=true,Opened=true})
    AS:Toggle({Title="God Mode",Desc="Prevents all damage",Callback=function(v)
        S.godOn=v
        if v then local h=getHum(); if h then h.MaxHealth=math.huge; h.Health=math.huge end
            S.godConn=RunService.Heartbeat:Connect(function() local h=getHum(); if h then h.Health=h.MaxHealth end end)
        else if S.godConn then S.godConn:Disconnect(); S.godConn=nil end end
    end})
    AS:Space()
    AS:Slider({Title="Fly Speed",Step=5,Value={Min=10,Max=500,Default=50},Callback=function(v) S.flySpeed=v end})
    AS:Space()
    AS:Toggle({Title="Fly",Desc="PC: WASD + camera   Mobile: joystick",Callback=function(v) if v then startFly() else stopFly() end end})
    AS:Space()
    AS:Toggle({Title="Noclip",Desc="Walk through walls",Callback=function(v) if v then startNoclip() else stopNoclip() end end})
    T:Space()
    local VS=T:Section({Title="Visuals",Box=true,BoxBorder=true,Opened=true})
    VS:Toggle({Title="Player ESP",Desc="Shows player names above their heads",Callback=function(v)
        S.EspEnabled=v
        if v then
            for _,p in ipairs(Players:GetPlayers()) do buildESP(p) end
            S.EspAddConn=Players.PlayerAdded:Connect(buildESP)
            S.EspRemConn=Players.PlayerRemoving:Connect(cleanESP)
        else
            if S.EspAddConn then S.EspAddConn:Disconnect() end
            if S.EspRemConn then S.EspRemConn:Disconnect() end
            for _,p in ipairs(Players:GetPlayers()) do cleanESP(p) end
        end
    end})
    T:Space()
    T:Button({Title="Reset Player Stats",Icon="rotate-ccw",Desc="Resets WalkSpeed and JumpPower to default",Callback=function()
        local h=getHum(); if h then h.WalkSpeed=16; h.UseJumpPower=true; h.JumpPower=50 end; notify("Player","Stats reset to default.")
    end})
end

-- TAB 4: Misc (same as Moped)
do
    local T=All:Tab({Title="Misc",Icon="wrench"})
    local US=T:Section({Title="Utilities",Box=true,BoxBorder=true,Opened=true})
    US:Toggle({Title="Anti AFK",Desc="Fires on idle event only, zero performance cost",Callback=function(v)
        if v then player.Idled:Connect(function() VirtualUser:Button2Down(Vector2.new(0,0),camera.CFrame); task.wait(0.1); VirtualUser:Button2Up(Vector2.new(0,0),camera.CFrame) end) end
        notify("Anti AFK",v and "ON" or "OFF")
    end})
    US:Space()
    US:Toggle({Title="FPS Boost",Desc="Disables particles, shadows, lowers render quality",Callback=function(v)
        if v then applyFpsBoost() else removeFpsBoost() end; notify("FPS Boost",v and "ON" or "OFF")
    end})
    US:Space()
    US:Toggle({Title="Show FPS Counter",Value=true,Callback=function(v) fpsGui.Enabled=v end})
    T:Space()
    local SS=T:Section({Title="Server",Box=true,BoxBorder=true,Opened=true})
    local sg=SS:Group({})
    sg:Button({Title="Rejoin",Icon="refresh-cw",Justify="Center",Callback=function() notify("Server","Rejoining..."); task.wait(1); TeleportService:Teleport(game.PlaceId,player) end})
    sg:Space()
    sg:Button({Title="New Server",Icon="shuffle",Justify="Center",Callback=function() notify("Server","Finding new server..."); task.wait(1); TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,player) end})
    T:Space()
    local TS=T:Section({Title="Teleport to Player",Box=true,BoxBorder=true,Opened=true})
    local tpTarget=""
    local function getPlayerNames() local n={}; for _,p in ipairs(Players:GetPlayers()) do if p~=player then table.insert(n,p.Name) end end; return #n>0 and n or {"No other players"} end
    local tpDrop=TS:Dropdown({Title="Select Player",Values=getPlayerNames(),Value=nil,AllowNone=true,Callback=function(v) tpTarget=v or "" end})
    TS:Space()
    local tg=TS:Group({})
    tg:Button({Title="Refresh",Icon="refresh-cw",Justify="Center",Callback=function() tpDrop:Refresh(getPlayerNames()); notify("Teleport","List refreshed.") end})
    tg:Space()
    tg:Button({Title="Teleport",Icon="navigation",Justify="Center",Callback=function()
        if tpTarget=="" or tpTarget=="No other players" then notify("Teleport","Select a player first."); return end
        local t=Players:FindFirstChild(tpTarget); if not t or not t.Character then notify("Teleport","Player not found."); return end
        local hrp=getHRP(); if not hrp then return end
        hrp.CFrame=t.Character:GetPrimaryPartCFrame()+Vector3.new(0,3,0); notify("Teleport","Teleported to "..tpTarget)
    end})
end

-- TAB 5: Settings (same as Moped)
do
    local T=All:Tab({Title="Settings",Icon="settings"})
    local IS=T:Section({Title="Interface",Box=true,BoxBorder=true,Opened=true})
    IS:Keybind({Title="Toggle UI",Desc="Key to show / hide the window",Value="RightAlt",Callback=function(v) pcall(function() Window:SetToggleKey(Enum.KeyCode[v]) end) end})
    T:Space()
    local CS=T:Section({Title="Credits",Box=true,BoxBorder=true,Opened=true})
    CS:Section({Title="Made by AnsonDev\ndiscord.gg/FBaqTQqutg",TextSize=14,TextTransparency=0.3})
    T:Space()
    T:Button({Title="Destroy UI",Desc="Completely removes the interface",Icon="trash-2",Color=Color3.fromHex("#ef4444"),Justify="Center",Callback=function() Window:Destroy() end})
end

-- Respawn
player.CharacterAdded:Connect(function(char)
    task.wait(0.5); local hum=char:WaitForChild("Humanoid",5); if not hum then return end
    if S.walkEnabled then hum.WalkSpeed=S.walkVal end
    if S.jumpEnabled then hum.UseJumpPower=true; hum.JumpPower=S.jumpVal end
    if S.flyEnabled then startFly() end
    if S.noclipEnabled then startNoclip() end
    if S.godOn then hum.MaxHealth=math.huge; hum.Health=math.huge
        if S.godConn then S.godConn:Disconnect() end
        S.godConn=RunService.Heartbeat:Connect(function() local h=getHum(); if h then h.Health=h.MaxHealth end end) end
end)

notify("AnsonDev","Merge a Nuke v1.0 loaded.")
