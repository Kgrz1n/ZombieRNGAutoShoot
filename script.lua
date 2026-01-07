--====================================================--
-- ZOMBIE RNG - FULL COMBAT & VISUAL SYSTEM + AUTO HOVER
--====================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

--====================================================--
-- CONFIGURAÇÕES
--====================================================--

local settings = {
    lockOn = false,
    lockSmoothness = 0.25,
    hitbox = false,
    hover = false,
    hoverHeight = 12,
    esp = false
}

--====================================================--
-- GUI BASE SIMPLIFICADA
--====================================================--

local ScreenGui = Instance.new("ScreenGui", player.PlayerGui)
ScreenGui.Name = "CombatUI"

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 300, 0, 350)
Main.Position = UDim2.new(0, 20, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0

local function makeToggle(parent, text, y, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 30)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = text .. ": OFF"

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)

    return btn
end

makeToggle(Main, "Lock On", 10, function(v) settings.lockOn = v end)
makeToggle(Main, "Hitbox", 50, function(v) settings.hitbox = v end)
makeToggle(Main, "ESP", 90, function(v) settings.esp = v end)
makeToggle(Main, "Auto Hover", 130, function(v) settings.hover = v end)

--====================================================--
-- FUNÇÃO: ACHAR ALVO
--====================================================--

local function getNearestZombie()
    local zombiesFolder = Workspace:FindFirstChild("Zombies") or Workspace:FindFirstChild("Enemies")
    if not zombiesFolder then return nil end

    local nearest, dist = nil, 999
    for _, zombie in ipairs(zombiesFolder:GetChildren()) do
        if zombie:FindFirstChild("HumanoidRootPart") and zombie:FindFirstChild("Humanoid") then
            local hrp = zombie.HumanoidRootPart
            local d = (hrp.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if d < dist and d < 80 then
                dist = d
                nearest = hrp
            end
        end
    end

    return nearest
end

--====================================================--
-- HITBOX EXPANDER
--====================================================--

local function setHitbox(zombie, expand)
    if not zombie:FindFirstChild("HumanoidRootPart") then return end
    local hrp = zombie.HumanoidRootPart

    if expand then
        hrp.Size = Vector3.new(25, 25, 25)
        hrp.Transparency = 0.7
        hrp.CanCollide = false
    else
        hrp.Size = Vector3.new(2, 2, 1)
        hrp.Transparency = 1
    end
end

--====================================================--
-- AUTO HOVER (VOAR SOBRE O INIMIGO MIRADO)
--====================================================--

local function hoverOver(target)
    if not target then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = player.Character.HumanoidRootPart

    local goal = target.Position + Vector3.new(0, settings.hoverHeight, 0)

    hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(goal, target.Position), 0.25)
end

--====================================================--
-- LOOP PRINCIPAL
--====================================================--

RunService.RenderStepped:Connect(function()
    local target = getNearestZombie()

    if settings.lockOn and target then
        -- Mira no inimigo
        local desired = CFrame.new(camera.CFrame.Position, target.Position)
        camera.CFrame = camera.CFrame:Lerp(desired, settings.lockSmoothness)
    end

    if settings.hitbox and target then
        setHitbox(target.Parent, true)
    end

    if settings.hover and target then
        hoverOver(target)
    end
end)

print(">> SCRIPT CARREGADO COM SUCESSO <<")
