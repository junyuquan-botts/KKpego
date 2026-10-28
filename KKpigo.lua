local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local LP = Players.LocalPlayer

local introGui = Instance.new("ScreenGui")
introGui.Name = "SoundManIntro"
introGui.ResetOnSpawn = false
introGui.IgnoreGuiInset = true
introGui.Parent = LP:WaitForChild("PlayerGui")

local introText = Instance.new("TextLabel")
introText.Size = UDim2.new(1, 0, 1, 0)
introText.BackgroundTransparency = 1
introText.Text = "SOUND MAN"
introText.TextColor3 = Color3.fromRGB(255, 50, 50)
introText.Font = Enum.Font.GothamBlack
introText.TextSize = 60
introText.TextTransparency = 0
introText.TextStrokeTransparency = 0
introText.Parent = introGui

local introSound = Instance.new("Sound")
introSound.SoundId = "rbxassetid://131237241"
introSound.Volume = 2
introSound.Parent = SoundService
introSound:Play()

TweenService:Create(introText, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, TextStrokeTransparency = 1, Size = UDim2.new(1, 0, 1.5, 0)}):Play()
task.delay(2, function()
    introGui:Destroy()
    introSound:Destroy()
end)

local function getRemote(name)
    local ds = RS:FindFirstChild("DodgeShared")
    local remotes = ds and ds:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild(name)
end

local CatchRemote = getRemote("RequestCatch")
local ThrowRemote = getRemote("RequestThrow")
local PickupRemote = getRemote("RequestPickup")
local DodgeRemote = getRemote("RequestDodge")
local GameState = RS:FindFirstChild("GameState")
local Config = nil
pcall(function() Config = require(RS.DodgeShared.Config) end)

local S = { autoCatch = false, fireball = false, autoPickup = false, autoDodge = false }

local function getBallInfo()
    local ball = workspace:FindFirstChild("DodgeBall")
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not (ball and hrp and GameState) then return nil, nil end
    if GameState:GetAttribute("BallState") ~= "Live" then return ball, nil end
    local v = ball.AssemblyLinearVelocity
    local hv = Vector3.new(v.X, 0, v.Z)
    local sp = hv.Magnitude
    if sp < 20 then return ball, nil end
    local d = hv / sp
    local to = Vector3.new(hrp.Position.X - ball.Position.X, 0, hrp.Position.Z - ball.Position.Z)
    local along = to:Dot(d)
    if along < -1 then return ball, nil end
    local catchRadius = (Config and Config.CatchRadius) or 3
    local e = math.max(along - catchRadius, 0) / sp
    return ball, e
end

local function getNearestEnemy()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if h and hum and hum.Health > 0 then
                local d = (h.Position - hrp.Position).Magnitude
                if d < bd then best, bd = p, d end
            end
        end
    end
    return best
end

RunService.Heartbeat:Connect(function()
    local ball, eta = getBallInfo()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if S.autoCatch and eta and eta < 0.5 and CatchRemote then
        local fake = math.min(0.2, ((ball and ball:GetAttribute("CatchWin")) or 0.2) * 0.7)
        pcall(function() CatchRemote:FireServer(fake) end)
        S.autoCatch = false
        task.delay(1, function() S.autoCatch = true end)
    end

    if S.fireball and GameState and GameState:GetAttribute("HolderId") == LP.UserId and hrp and ThrowRemote then
        local tgt = getNearestEnemy()
        if tgt and tgt.Character then
            local th = tgt.Character.HumanoidRootPart
            local dir = Vector3.new(th.Position.X - hrp.Position.X, 0, th.Position.Z - hrp.Position.Z)
            if dir.Magnitude > 1 then
                dir = dir.Unit
                pcall(function() ThrowRemote:FireServer(1, dir, 1, tgt.UserId) end)
                S.fireball = false
                task.delay(0.5, function() S.fireball = true end)
            end
        end
    end

    if S.autoPickup and ball and hrp and PickupRemote then
        if GameState and GameState:GetAttribute("BallState") == "Loose" then
            local radius = (Config and Config.TapPickupRadius) or 10
            if (ball.Position - hrp.Position).Magnitude <= radius then
                pcall(function() PickupRemote:FireServer() end)
                S.autoPickup = false
                task.delay(0.3, function() S.autoPickup = true end)
            end
        end
    end

    if S.autoDodge and eta and eta < 0.18 and DodgeRemote then
        pcall(function() DodgeRemote:FireServer("RollF") end)
        S.autoDodge = false
        task.delay(0.5, function() S.autoDodge = true end)
    end
end)

local old = LP.PlayerGui:FindFirstChild("VulnDiagUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "VulnDiagUI"
gui.ResetOnSpawn = false
gui.Parent = LP.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(240, 180)
frame.Position = UDim2.fromOffset(12, 12)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundTransparency = 1
title.Text = "피구 자동화 (R-Shift)"
title.TextColor3 = Color3.fromRGB(255, 210, 80)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame

local function makeBtn(y, keyText, stateKey, name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 24)
    b.Position = UDim2.fromOffset(6, y)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = 12
    b.TextColor3 = Color3.fromRGB(230, 230, 230)
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    local function sync()
        local on = S[stateKey]
        b.Text = ("%s [%s] %s"):format(name, keyText, on and "● ON" or "○ off")
        b.BackgroundColor3 = on and Color3.fromRGB(70, 110, 60) or Color3.fromRGB(40, 40, 52)
    end
    b.MouseButton1Click:Connect(function()
        S[stateKey] = not S[stateKey]
        sync()
    end)
    sync()
    return sync
end

local syncs = {
    makeBtn(30, "U", "autoCatch", "자동 캐치"),
    makeBtn(58, "I", "fireball", "자동 불꽃슛"),
    makeBtn(86, "O", "autoPickup", "자동 픽업"),
    makeBtn(114, "P", "autoDodge", "자동 회피"),
}

local dragging, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = frame.Position
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    local k = input.KeyCode
    if k == Enum.KeyCode.RightShift then
        gui.Enabled = not gui.Enabled
        return
    end
    if gp then return end
    if k == Enum.KeyCode.U then S.autoCatch = not S.autoCatch
    elseif k == Enum.KeyCode.I then S.fireball = not S.fireball
    elseif k == Enum.KeyCode.O then S.autoPickup = not S.autoPickup
    elseif k == Enum.KeyCode.P then S.autoDodge = not S.autoDodge
    else return end
    for _, s in ipairs(syncs) do s() end
end)
