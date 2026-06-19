--[[
    AnsonDev - Sell Lemons
    Version : 1.0.0
    Author  : AnsonDev
    UI      : WindUI
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

pcall(function()
    for _,idle in pairs(getconnections(player.Idled)) do idle:Disable() end
end)

-- ═══════════════════════════════════════════════════
--  ScriptData
-- ═══════════════════════════════════════════════════
local ScriptData = {
    PlayerTycoon=nil, Values=nil, Powers=nil, Streams=nil,
    AutoBuy=false, AutoUpgrade=false, AutoRebirth=false, AutoEvolve=false,
    AutoAscend=false, AutoBuyPowers=false, AutoWakeIncomeSources=false,
    AutoPhoneOffers=false, AutoCollectFruits=false,
    MainSettings={
        ButtonBuy={BuyInterval=0.05,UseForeverPurchase=false},
        Rebirth={MaximumRebirths=0,MinimumPotential=1000,XFactor=10,RebirthWhenUnableToBuy=false,TimeBeforeRebirthWhenUnableToBuy=30,RebirthAfterCertainTime=false,TimeAmount=60},
        Evolve={MaximumEvolution=0},
    },
    Modules={Tycoon=nil,Balances=nil,Upgrades=nil,Rebirth=nil,Evolve=nil,Ascension=nil,PhoneOffers=nil,TycoonPowers=nil},
    Remotes={Rebirth=nil,Evolve=nil,Ascend=nil,UpgradePowerLevel=nil,WakeIncomeStream=nil,PhoneOffer=nil},
}

-- Player state (same as Moped/Nuke)
local S = {
    walkEnabled=false, walkVal=16, jumpEnabled=false, jumpVal=50, infJumpConn=nil,
    godOn=false, godConn=nil,
    flyEnabled=false, flyConn=nil, flyTpConn=nil, flyNowe=false, flySpeed=50,
    noclipEnabled=false, noclipConn=nil,
    fpsBoostOn=false,
}

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

-- ═══════════════════════════════════════════════════
--  Tycoon Helpers
-- ═══════════════════════════════════════════════════
local function FindTycoon()
    for _,v in pairs(Workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon%d") then
            if v:FindFirstChild("Owner") and v.Owner.Value==player then return v end
        end
    end
end

local function FindValues(Value,AnotherChild,ReturnLast)
    if not ScriptData.PlayerTycoon then return end
    local Values=ScriptData.PlayerTycoon:FindFirstChild("Values"); if not Values then return end
    local ReturnValue=Values:FindFirstChild(Value); if not ReturnValue then return end
    if not AnotherChild then return ReturnValue end
    local Check=ReturnValue:FindFirstChild(AnotherChild)
    if Check and not ReturnLast then return ReturnValue,Check elseif Check and ReturnLast then return Check end
end

local StartTime=tick()
repeat ScriptData.PlayerTycoon=FindTycoon(); if tick()-StartTime>30 then warn("[ERROR]: Tycoon not found."); return end; task.wait(0.25) until ScriptData.PlayerTycoon~=nil
StartTime=tick(); repeat ScriptData.Values=FindValues("Values"); if tick()-StartTime>5 then warn("[ERROR]: Values not found."); return end; task.wait(0.1) until ScriptData.Values~=nil
StartTime=tick(); repeat ScriptData.Powers=FindValues("Powers","Permanent",true); if tick()-StartTime>5 then warn("[ERROR]: Powers not found."); return end; task.wait(0.1) until ScriptData.Powers~=nil
StartTime=tick(); repeat ScriptData.Streams=FindValues("Income","Streams",true); if tick()-StartTime>5 then warn("[ERROR]: Streams not found."); return end; task.wait(0.1) until ScriptData.Streams~=nil

local S1,R1=pcall(function()
    ScriptData.Modules.Tycoon=require(ReplicatedStorage.Modules.Tycoon.Tycoon)
    ScriptData.Modules.Balances=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonBalances)
    ScriptData.Modules.Upgrades=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonUpgrades)
    ScriptData.Modules.Rebirth=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonRebirth)
    ScriptData.Modules.Evolve=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonEvolution)
    ScriptData.Modules.Ascension=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonAscension)
    ScriptData.Modules.PhoneOffers=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonPhoneOffers)
    ScriptData.Modules.TycoonPowers=require(ReplicatedStorage.Modules.Tycoon.Component.Client.ClientTycoonPowers)
end)
local S2,R2=pcall(function()
    ScriptData.Remotes.Rebirth=ScriptData.PlayerTycoon.Remotes.Rebirth
    ScriptData.Remotes.Evolve=ScriptData.PlayerTycoon.Remotes.Evolve
    ScriptData.Remotes.Ascend=ScriptData.PlayerTycoon.Remotes.Ascend
    ScriptData.Remotes.UpgradePowerLevel=ScriptData.PlayerTycoon.Remotes.UpgradePowerLevel
    ScriptData.Remotes.WakeIncomeStream=ScriptData.PlayerTycoon.Remotes.WakeIncomeStream
    ScriptData.Remotes.PhoneOffer=ScriptData.PlayerTycoon.Remotes.PhoneOffer
end)
if not S1 then warn("[ERROR]: Modules: "..tostring(R1)) end
if not S2 then warn("[ERROR]: Remotes: "..tostring(R2)) end

local function RequestComp(Class)
    if not (ScriptData.Modules.Tycoon and Class) then return nil end
    local ok,ret=pcall(function() local lt=ScriptData.Modules.Tycoon.getLocal(); return lt and lt:GetComponent(Class) end)
    return ok and ret or nil
end
local Resolving=false
local function WaitForResolve() Resolving=true; task.wait(2); Resolving=false end

-- ═══════════════════════════════════════════════════
--  Background loops
-- ═══════════════════════════════════════════════════
task.spawn(function()
    local IsBusy=false
    local function BuyButtons()
        if IsBusy or Resolving then return end; IsBusy=true
        local Buyable={}
        for _,v in ipairs(ScriptData.PlayerTycoon.Purchases:GetDescendants()) do
            if v:IsA("Model") and not v:GetAttribute("Purchased") and v:GetAttribute("Shown") then
                local P=v:FindFirstChild("Purchase"); if P and P:IsA("RemoteFunction") then table.insert(Buyable,P) end
            end
        end
        for _,Purchase in ipairs(Buyable) do
            if not ScriptData.AutoBuy or Resolving then IsBusy=false; return end
            if ScriptData.MainSettings.ButtonBuy.UseForeverPurchase then
                local ok=pcall(function() Purchase:InvokeServer(true) end)
                if not ok then pcall(function() Purchase:InvokeServer() end) end
            else pcall(function() Purchase:InvokeServer() end) end
            local bi=ScriptData.MainSettings.ButtonBuy.BuyInterval
            if type(bi)=="number" and bi>0 then task.wait(bi) end
        end
        IsBusy=false
    end
    while true do task.wait(0.05); if ScriptData.AutoBuy then BuyButtons() end end
end)

task.spawn(function()
    local UR={}; local LastScan=0
    local function RefreshUpgrades()
        UR={}; local P=ScriptData.PlayerTycoon:FindFirstChild("Purchases"); if not P then return end
        for _,v in ipairs(P:GetDescendants()) do if v:IsA("RemoteFunction") and v.Name=="Upgrade" then table.insert(UR,v) end end
    end
    while true do task.wait(0.5)
        if not ScriptData.AutoUpgrade then continue end
        if tick()-LastScan>3 then RefreshUpgrades(); LastScan=tick() end
        for _,r in ipairs(UR) do if r.Parent then task.spawn(function() for i=1,10 do task.wait(); pcall(function() r:InvokeServer(i) end) end end) end end
    end
end)

task.spawn(function()
    local RebirthBusy=false; local LastConflictNotify,LastUnableBuyTime=0,0
    local LastRebirthTime=tick(); local LastTimeState,LastSuccessfulRebirth,LastAutoRebirthToggle=false,0,0
    local RebirthCooldown=2.5
    local function GetBalances() return RequestComp(ScriptData.Modules.Balances) end
    local function GetRebirth()  return RequestComp(ScriptData.Modules.Rebirth) end
    local function GetCurrentInvestors() local B=GetBalances(); if not B then return 0 end; local ok,v=pcall(function() return B:GetInvestors() end); return ok and v or 0 end
    local function GetPotentialInvestors() local R=GetRebirth(); if not R then return 0 end; local ok,v=pcall(function() return R:GetPotentialInvestors() end); return ok and v or 0 end
    local function IsMinimumMet(PL,Min) return Min==0 or PL>=math.log10(Min) end
    local function GetXCondition(PL,CL,X) return PL>=CL+math.log10(X) end
    local function DoRebirth() pcall(function() ScriptData.Remotes.Rebirth:InvokeServer(); WaitForResolve() end) end
    local function HasAnythingToBuy()
        for _,v in ipairs(ScriptData.PlayerTycoon.Purchases:GetDescendants()) do
            if v:IsA("Model") and v:GetAttribute("Shown")==true and v:GetAttribute("Purchased")~=true then return true end
        end; return false
    end
    local function GetCurrentRebirths() return ScriptData.Values and (ScriptData.Values:GetAttribute("Rebirths") or 0) or 0 end
    while true do task.wait(0.1)
        if not ScriptData.AutoRebirth or RebirthBusy then
            if not ScriptData.AutoRebirth then LastAutoRebirthToggle=0 end; continue end
        if LastAutoRebirthToggle==0 then LastAutoRebirthToggle=tick(); continue end
        if tick()-LastAutoRebirthToggle<3 then continue end
        if tick()-LastSuccessfulRebirth<RebirthCooldown then continue end
        if not ScriptData.Remotes.Rebirth then continue end
        local MaxR=ScriptData.MainSettings.Rebirth.MaximumRebirths
        if MaxR>0 and GetCurrentRebirths()>=MaxR then continue end
        local Cfg=ScriptData.MainSettings.Rebirth; local ShouldRebirth=false
        if Cfg.RebirthWhenUnableToBuy and Cfg.RebirthAfterCertainTime then
            if tick()-LastConflictNotify>=5 then notify("Settings Conflict","Cannot use both Rebirth options together."); LastConflictNotify=tick() end; continue
        end
        if Cfg.RebirthAfterCertainTime then
            if not LastTimeState then LastRebirthTime=tick(); LastTimeState=true end
            if tick()-LastRebirthTime>=Cfg.TimeAmount then ShouldRebirth=true end
        else
            LastTimeState=false
            if Cfg.RebirthWhenUnableToBuy then
                if not HasAnythingToBuy() then
                    if LastUnableBuyTime==0 then LastUnableBuyTime=tick()
                    elseif tick()-LastUnableBuyTime>=Cfg.TimeBeforeRebirthWhenUnableToBuy then ShouldRebirth=true end
                else LastUnableBuyTime=0 end
            end
            if not ShouldRebirth then
                local Pot=GetPotentialInvestors(); local Cur=GetCurrentInvestors()
                if Pot>0 and IsMinimumMet(Pot,Cfg.MinimumPotential) then
                    if Cfg.XFactor>0 then if GetXCondition(Pot,Cur,Cfg.XFactor) then ShouldRebirth=true end
                    elseif Cfg.MinimumPotential>0 then ShouldRebirth=true
                    elseif tick()-LastRebirthTime>=8 then ShouldRebirth=true end
                end
            end
        end
        if ShouldRebirth and ScriptData.AutoRebirth then
            RebirthBusy=true; DoRebirth(); LastRebirthTime=tick(); LastUnableBuyTime=0
            LastSuccessfulRebirth=tick(); LastAutoRebirthToggle=tick(); task.wait(1.5); RebirthBusy=false
        end
    end
end)

task.spawn(function()
    while true do task.wait(0.5)
        if not ScriptData.AutoEvolve then continue end
        local M=RequestComp(ScriptData.Modules.Evolve); if not M then continue end
        if M:GetEvolutionProgress()==1 then
            if ScriptData.MainSettings.Evolve.MaximumEvolution>0 then
                local CE=ScriptData.Values:GetAttribute("Evolution")
                if CE and CE<ScriptData.MainSettings.Evolve.MaximumEvolution then pcall(function() ScriptData.Remotes.Evolve:InvokeServer(); WaitForResolve() end) end
            else pcall(function() ScriptData.Remotes.Evolve:InvokeServer(); WaitForResolve() end) end
        end
    end
end)

task.spawn(function()
    while true do task.wait(0.5)
        if not ScriptData.AutoAscend then continue end
        local M=RequestComp(ScriptData.Modules.Ascension); if not M then continue end
        if M:GetAscensionProgress()==1 then pcall(function() ScriptData.Remotes.Ascend:InvokeServer(); WaitForResolve() end) end
    end
end)

task.spawn(function()
    while true do task.wait(0.5)
        if not ScriptData.AutoBuyPowers then continue end
        local M=RequestComp(ScriptData.Modules.TycoonPowers); if not M then continue end
        local ok,Levels=pcall(function() return M:GetLevels() end); if not ok or not Levels then continue end
        for PowerName,CurrentLevel in pairs(Levels) do
            local MaxLevel=M:GetMaxLevel(PowerName)
            if not MaxLevel or CurrentLevel<MaxLevel then pcall(function() M:UpgradeAsync(PowerName) end); task.wait(0.1) end
        end
    end
end)

task.spawn(function()
    local Phone=ScriptData.Remotes.PhoneOffer
    local function AcceptOffer() if ScriptData.AutoPhoneOffers then pcall(function() Phone:FireServer("Accept") end) end end
    Phone.OnClientEvent:Connect(function(v) if type(v)=="number" then AcceptOffer() end end)
    while true do task.wait(1)
        if not ScriptData.AutoPhoneOffers then continue end
        local M=RequestComp(ScriptData.Modules.PhoneOffers); if not M then continue end
        local ok,Offer=pcall(function() return M:GetCurrentOffer() end)
        if ok and type(Offer)=="number" then AcceptOffer() end
    end
end)

task.spawn(function()
    local IncomeStreams={}
    local function IndexStreams() IncomeStreams={}; for _,v in pairs(ScriptData.Streams:GetChildren()) do table.insert(IncomeStreams,v) end end
    while true do task.wait()
        if not ScriptData.AutoWakeIncomeSources then continue end
        if #IncomeStreams==0 then IndexStreams() end
        for _,v in ipairs(IncomeStreams) do
            if not v:GetAttribute("Automatic") then pcall(function() ScriptData.Remotes.WakeIncomeStream:InvokeServer(tostring(v)) end) end
        end
    end
end)

task.spawn(function()
    local Trees={}; local OriginalCFrame=nil
    local function UpdateTree(v,add)
        if v:IsA("Model") and v.Name=="LemonTree" then
            if add then if not table.find(Trees,v) then table.insert(Trees,v) end
            else local i=table.find(Trees,v); if i then table.remove(Trees,i) end end
        end
    end
    for _,v in ipairs(Workspace:GetDescendants()) do UpdateTree(v,true) end
    Workspace.DescendantAdded:Connect(function(v) UpdateTree(v,true) end)
    Workspace.DescendantRemoving:Connect(function(v) UpdateTree(v,false) end)
    while true do task.wait(0.1)
        if ScriptData.AutoCollectFruits then
            for _,Tree in ipairs(Trees) do
                if Tree and Tree.Parent then
                    for _,v in ipairs(Tree:GetDescendants()) do
                        if v:IsA("BasePart") and v.Name=="Fruit" then
                            if not ScriptData.AutoCollectFruits then break end
                            local Det=v:FindFirstChild("ClickPart") and v.ClickPart:FindFirstChildOfClass("ClickDetector")
                            if Det then
                                local chr=player.Character; local hrp=chr and chr:FindFirstChild("HumanoidRootPart")
                                if hrp then pcall(function()
                                    if not OriginalCFrame then OriginalCFrame=hrp.CFrame end
                                    hrp.CFrame=Tree:GetPivot()+Vector3.new(0,Tree:GetExtentsSize().Y/2,0)
                                    task.wait(0.05); fireclickdetector(Det)
                                end) end
                            end
                        end
                    end
                end
            end
        elseif OriginalCFrame then
            local chr=player.Character; local hrp=chr and chr:FindFirstChild("HumanoidRootPart")
            if hrp then pcall(function() hrp.CFrame=OriginalCFrame; OriginalCFrame=nil end) end
        end
    end
end)

-- ═══════════════════════════════════════════════════
--  FPS Overlay
-- ═══════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════
--  Fly (V3)
-- ═══════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════
--  Window
-- ═══════════════════════════════════════════════════
local Window=WindUI:CreateWindow({
    Title="AnsonDev  |  Sell Lemons", Folder="AnsonDev", Icon="citrus", NewElements=true,
    Topbar={Height=48,ButtonsType="Mac"},
    OpenButton={Title="AnsonDev",CornerRadius=UDim.new(1,0),StrokeThickness=2,Enabled=true,Draggable=true,OnlyMobile=false,Scale=0.55,
        Color=ColorSequence.new(Color3.fromHex("#F7D51E"),Color3.fromHex("#F5921E"))},
})
Window:Tag({Title="v1.0.0",Icon="sparkles",Color=Color3.fromHex("#18181b"),Border=true})
Window:Tag({Title="Sell Lemons",Icon="citrus",Color=Color3.fromHex("#1e1e2e"),Border=true})
local All=Window:Section({Title="AnsonDev"})

-- TAB 1: Home
do
    local T=All:Tab({Title="Home",Icon="house"})
    local Hero=T:Section({Title="AnsonDev  |  Sell Lemons"})
    Hero:Section({Title="Welcome back, "..player.Name,TextSize=24,FontWeight=Enum.FontWeight.Bold})
    Hero:Space()
    Hero:Section({Title="Full automation for Sell Lemons tycoon.\nAuto Buy  •  Auto Rebirth  •  Auto Evolve  •  Auto Ascend  •  More",TextSize=15,TextTransparency=0.35,FontWeight=Enum.FontWeight.Medium})
    T:Space({Columns=3})
    local sg=T:Group({})
    sg:Section({Title="Version",TextSize=12,TextTransparency=0.5}); sg:Section({Title="1.0.0",TextSize=18,FontWeight=Enum.FontWeight.Bold}); sg:Space()
    sg:Section({Title="Author",TextSize=12,TextTransparency=0.5}); sg:Section({Title="AnsonDev",TextSize=18,FontWeight=Enum.FontWeight.Bold}); sg:Space()
    sg:Section({Title="Game",TextSize=12,TextTransparency=0.5}); sg:Section({Title="Sell Lemons",TextSize=18,FontWeight=Enum.FontWeight.Bold})
    T:Space({Columns=3})
    T:Paragraph({Title="Community  &  Support",Desc="Join the AnsonDev Discord for updates, bug reports and support.",Image="message-circle",
        Buttons={{Title="Join Discord",Icon="link",Callback=function() if setclipboard then setclipboard("https://discord.gg/FBaqTQqutg"); notify("Discord","Link copied.") end end}}})
    T:Space({Columns=3})
    local fg1=T:Group({})
    local f1=fg1:Section({Title="Auto Buy & Upgrade",Box=true,BoxBorder=true,Opened=true}); f1:Section({Title="Buys available buttons and upgrades income sources automatically.",TextSize=13,TextTransparency=0.35})
    fg1:Space()
    local f2=fg1:Section({Title="Auto Rebirth",Box=true,BoxBorder=true,Opened=true}); f2:Section({Title="Rebirths based on X factor, minimum investors or time interval.",TextSize=13,TextTransparency=0.35})
    T:Space({Columns=2})
    local fg2=T:Group({})
    local f3=fg2:Section({Title="Auto Evolve & Ascend",Box=true,BoxBorder=true,Opened=true}); f3:Section({Title="Evolves and ascends automatically when progress reaches 100%.",TextSize=13,TextTransparency=0.35})
    fg2:Space()
    local f4=fg2:Section({Title="Extras",Box=true,BoxBorder=true,Opened=true}); f4:Section({Title="Auto Buy Powers, Phone Offers, Wake Income, Collect Fruits.",TextSize=13,TextTransparency=0.35})
end

-- TAB 2: Main - Core Automation
do
    local T=All:Tab({Title="Core Auto",Icon="zap"})
    local CS=T:Section({Title="Core Automation",Box=true,BoxBorder=true,Opened=true})
    CS:Toggle({Title="Auto Buy",Desc="Automatically buys available tycoon buttons",Callback=function(v) ScriptData.AutoBuy=v; notify("Auto Buy",v and "ON" or "OFF") end})
    CS:Space()
    CS:Toggle({Title="Auto Upgrade",Desc="Automatically upgrades tycoon income sources",Callback=function(v) ScriptData.AutoUpgrade=v; notify("Auto Upgrade",v and "ON" or "OFF") end})
    CS:Space()
    CS:Toggle({Title="Auto Rebirth",Desc="Automatically rebirths (configure in Settings)",Callback=function(v) ScriptData.AutoRebirth=v; notify("Auto Rebirth",v and "ON  - Check Settings for options." or "OFF") end})
    CS:Space()
    CS:Toggle({Title="Auto Evolve",Desc="Evolves automatically when progress hits 100%",Callback=function(v) ScriptData.AutoEvolve=v; notify("Auto Evolve",v and "ON  - Check Settings for options." or "OFF") end})
    CS:Space()
    CS:Toggle({Title="Auto Ascend",Desc="Ascends automatically when progress hits 100%",Callback=function(v) ScriptData.AutoAscend=v; notify("Auto Ascend",v and "ON" or "OFF") end})
    T:Space()
    local ES=T:Section({Title="Extras",Box=true,BoxBorder=true,Opened=true})
    ES:Toggle({Title="Auto Buy Powers",Desc="Automatically purchases tycoon powers",Callback=function(v) ScriptData.AutoBuyPowers=v; notify("Auto Buy Powers",v and "ON" or "OFF") end})
    ES:Space()
    ES:Toggle({Title="Auto Accept Phone Offers",Desc="Automatically accepts incoming phone offers",Callback=function(v) ScriptData.AutoPhoneOffers=v; notify("Auto Phone Offers",v and "ON" or "OFF") end})
    ES:Space()
    ES:Toggle({Title="Auto Wake Income Sources",Desc="Automatically clicks income sources to wake them",Callback=function(v) ScriptData.AutoWakeIncomeSources=v; notify("Auto Wake Income",v and "ON" or "OFF") end})
    ES:Space()
    ES:Toggle({Title="Auto Collect Fruits",Desc="Teleports to lemon trees and collects all fruits",Callback=function(v) ScriptData.AutoCollectFruits=v; notify("Auto Collect Fruits",v and "ON" or "OFF") end})
end

-- TAB 3: Main - Rebirth & Evolve Settings
do
    local T=All:Tab({Title="Auto Settings",Icon="settings-2"})
    local BS=T:Section({Title="Auto Buy Settings",Box=true,BoxBorder=true,Opened=true})
    BS:Input({Title="Buy Interval (seconds)",Desc="Default: 0.05",Value="0.05",Placeholder="e.g. 0.1",Callback=function(v)
        local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.ButtonBuy.BuyInterval=n; notify("Buy Interval","Set to "..n.."s") else notify("Buy Interval","Invalid number.") end
    end})
    BS:Space()
    BS:Toggle({Title="Use Forever Purchase",Desc="Attempts the forever purchase option when buying",Callback=function(v) ScriptData.MainSettings.ButtonBuy.UseForeverPurchase=v; notify("Forever Purchase",v and "ON" or "OFF") end})
    T:Space()
    local RS=T:Section({Title="Rebirth Settings",Box=true,BoxBorder=true,Opened=true})
    RS:Input({Title="Maximum Rebirths  (per evolve, 0 = off)",Value="0",Placeholder="e.g. 10",Callback=function(v) local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.Rebirth.MaximumRebirths=n; notify("Max Rebirths","Set to "..n) else notify("Max Rebirths","Invalid number.") end end})
    RS:Space()
    RS:Input({Title="Minimum Investors Needed",Value="1000",Placeholder="e.g. 1000",Callback=function(v) local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.Rebirth.MinimumPotential=n; notify("Min Investors","Set to "..n) else notify("Min Investors","Invalid number.") end end})
    RS:Space()
    RS:Input({Title="X Factor  (Current * X = rebirth, 0 = off)",Value="10",Placeholder="e.g. 10",Callback=function(v) local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.Rebirth.XFactor=n; notify("X Factor","Set to "..n.."x") else notify("X Factor","Invalid number.") end end})
    RS:Space()
    RS:Input({Title="Rebirth After Time  (seconds)",Value="60",Placeholder="e.g. 60",Callback=function(v) local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.Rebirth.TimeAmount=n; notify("Rebirth Timer","Set to "..n.."s") else notify("Rebirth Timer","Invalid number.") end end})
    RS:Space()
    RS:Toggle({Title="Rebirth After Certain Time",Desc="Rebirths after the set time interval above",Callback=function(v) ScriptData.MainSettings.Rebirth.RebirthAfterCertainTime=v; notify("Rebirth After Time",v and "ON" or "OFF") end})
    RS:Space()
    RS:Input({Title="Rebirth When Unable to Buy  (wait seconds)",Value="30",Placeholder="e.g. 30",Callback=function(v) local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.Rebirth.TimeBeforeRebirthWhenUnableToBuy=n; notify("Unable to Buy Timer","Set to "..n.."s") else notify("Unable to Buy Timer","Invalid number.") end end})
    T:Space()
    local EvoS=T:Section({Title="Evolve Settings",Box=true,BoxBorder=true,Opened=true})
    EvoS:Input({Title="Max Evolution  (0 = no max)",Desc="Stops evolving at this number, useful for ascending",Value="0",Placeholder="e.g. 5",Callback=function(v) local n=tonumber(v); if n and n>=0 then ScriptData.MainSettings.Evolve.MaximumEvolution=n; notify("Max Evolution","Set to "..n) else notify("Max Evolution","Invalid number.") end end})
end

-- TAB 4: Player
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
    T:Button({Title="Reset Player Stats",Icon="rotate-ccw",Desc="Resets WalkSpeed and JumpPower to default",Callback=function()
        local h=getHum(); if h then h.WalkSpeed=16; h.UseJumpPower=true; h.JumpPower=50 end; notify("Player","Stats reset to default.")
    end})
end

-- TAB 5: Misc (identical to Moped)
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

-- TAB 6: Settings (identical to Moped)
do
    local T=All:Tab({Title="Settings",Icon="settings"})
    local IS=T:Section({Title="Interface",Box=true,BoxBorder=true,Opened=true})
    IS:Keybind({Title="Toggle UI",Desc="Key to show / hide the window",Value="RightShift",Callback=function(v) pcall(function() Window:SetToggleKey(Enum.KeyCode[v]) end) end})
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

notify("AnsonDev","Sell Lemons v1.0 loaded.")
