-- note: you can modify this however you want, js credit my discord please - @deadshizik

local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZombiesFolder = workspace:WaitForChild("Zombies")
local ServerZombies = workspace:WaitForChild("ServerZombies")
local Camera = workspace.CurrentCamera

for _, name in pairs({"autosolver_euler", "hitbox_debugger_gui"}) do
    local old = game:GetService("CoreGui"):FindFirstChild(name) or player.PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local isLockOnActive = false
local isShowHitboxEnabled = false
local lockSmoothness = 0.2
local lockKey = Enum.KeyCode.T
local priorityMode = "closest"
local TARGET_PART_NAME = "Head"
local currentLockedTarget = nil
local isBinding = false
local isMinimized = false

-- ADICIONADO: Auto Shoot
local isAutoShoot = false

local function getServerData(zombieClient)
    if not zombieClient then return nil end
    local targetIdStr = tostring(zombieClient.Name)
    for _, serverModel in pairs(ServerZombies:GetChildren()) do
        local success, idValue = pcall(function() return serverModel.id end)
        if not success or not idValue then
            idValue = serverModel:GetAttribute("id") or (serverModel:FindFirstChild("id") and serverModel.id.Value)
        end
        if idValue and tostring(idValue) == targetIdStr then
            return serverModel:FindFirstChildOfClass("Humanoid"), serverModel:FindFirstChild("HumanoidRootPart"), serverModel
        end
    end
    return nil
end

local function isZombieValid(zombieClient)
    if not zombieClient or not zombieClient.Parent or zombieClient.Parent ~= ZombiesFolder then return false end
    local hitbox = zombieClient:FindFirstChild(TARGET_PART_NAME)
    if not hitbox then return false end
    local hum, root, serverModel = getServerData(zombieClient)
    if not hum or hum.Health <= 0 or not root then return false end
    if serverModel:GetAttribute("Dead") or serverModel:GetAttribute("Ragdoll") then return false end
    return true
end

local function getValidTarget()
    if currentLockedTarget and not isZombieValid(currentLockedTarget.Parent) then
        currentLockedTarget = nil
    end
    
    local bestTarget = nil
    local bestVal = (priorityMode == "hp") and 0 or math.huge
    local char = player.Character
    local pRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not pRoot then return nil end

    for _, zombie in pairs(ZombiesFolder:GetChildren()) do
        if isZombieValid(zombie) then
            local hitbox = zombie:FindFirstChild(TARGET_PART_NAME)
            local hum = getServerData(zombie)
            if hitbox and hum then
                local dist = (pRoot.Position - hitbox.Position).Magnitude
                if priorityMode == "hp" then
                    if hum.Health > bestVal then
                        bestVal = hum.Health
                        bestTarget = hitbox
                    end
                elseif priorityMode == "closest" then
                    if dist < bestVal then
                        bestVal = dist
                        bestTarget = hitbox
                    end
                end
            end
        end
    end
    currentLockedTarget = bestTarget
    return bestTarget
end

local function createStrictToggle(parent, text, pos, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30); frame.Position = pos; frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0, 120, 1, 0); lbl.Text = text:lower(); lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local bg = Instance.new("Frame", frame)
    bg.Size = UDim2.new(0, 34, 0, 16); bg.Position = UDim2.new(1, -34, 0.5, -8)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 20); bg.BorderSizePixel = 1; bg.BorderColor3 = Color3.fromRGB(50, 50, 50)
    local box = Instance.new("Frame", bg)
    box.Size = UDim2.new(0, 8, 0, 8)
    box.Position = default and UDim2.new(1, -11, 0.5, -4) or UDim2.new(0, 3, 0.5, -4)
    box.BackgroundColor3 = default and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(60, 60, 60)
    box.BorderSizePixel = 0
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        default = not default
        box.Position = default and UDim2.new(1, -11, 0.5, -4) or UDim2.new(0, 3, 0.5, -4)
        box.BackgroundColor3 = default and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(60, 60, 60)
        callback(default)
    end)
end

local function createStrictSlider(parent, text, pos, minV, maxV, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 45); frame.Position = pos; frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 15); lbl.Text = text:lower(); lbl.TextColor3 = Color3.fromRGB(130, 130, 130)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.BackgroundTransparency = 1
    local sBack = Instance.new("Frame", frame)
    sBack.Size = UDim2.new(1, -60, 0, 1); sBack.Position = UDim2.new(0, 0, 0, 30)
    sBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50); sBack.BorderSizePixel = 0
    local sBtn = Instance.new("Frame", sBack)
    sBtn.Size = UDim2.new(0, 2, 0, 10)
    sBtn.Position = UDim2.new((default - minV)/(maxV - minV), -1, 0.5, -5)
    sBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(0, 50, 0, 20); input.Position = UDim2.new(1, -50, 0, 21)
    input.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    input.BorderSizePixel = 1; input.BorderColor3 = Color3.fromRGB(40, 40, 40)
    input.Text = tostring(default); input.TextColor3 = Color3.new(1, 1, 1)
    input.Font = Enum.Font.Code; input.TextSize = 11
    local function update(val)
        val = math.clamp(math.round(val * 100) / 100, minV, maxV)
        input.Text = tostring(val)
        sBtn.Position = UDim2.new((val - minV)/(maxV - minV), -1, 0.5, -5)
        callback(val)
    end
    local dragBtn = Instance.new("TextButton", sBack)
    dragBtn.Size = UDim2.new(1, 20, 1, 30)
    dragBtn.Position = UDim2.new(0, -10, 0, -15)
    dragBtn.BackgroundTransparency = 1; dragBtn.Text = ""
    local dragging = false
    dragBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - sBack.AbsolutePosition.X) / sBack.AbsoluteSize.X, 0, 1)
            update(minV + (maxV - minV) * rel)
        end
    end)
    input.FocusLost:Connect(function() update(tonumber(input.Text) or default) end)
end

local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "autosolver_euler"
local header = Instance.new("Frame", screenGui)
header.Size = UDim2.new(0, 340, 0, 35)
header.Position = UDim2.new(0.5, -170, 0.3, 0)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BorderSizePixel = 0
header.Active = true
header.Draggable = true

local headerTxt = Instance.new("TextLabel", header)
headerTxt.Size = UDim2.new(1, -10, 1, 0)
headerTxt.Position = UDim2.new(0, 10, 0, 0)
headerTxt.Text = "zombie rng | dc: @deadshizik"
headerTxt.TextColor3 = Color3.new(1, 1, 1)
headerTxt.Font = Enum.Font.GothamBold
headerTxt.TextSize = 13
headerTxt.BackgroundTransparency = 1
headerTxt.TextXAlignment = Enum.TextXAlignment.Left

local mainBody = Instance.new("Frame", header)
mainBody.Size = UDim2.new(1, 0, 0, 200)
mainBody.Position = UDim2.new(0, 0, 1, 1)
mainBody.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainBody.BorderSizePixel = 0

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -30, 0, 5)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.ZIndex = 10

minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    mainBody.Visible = not isMinimized
    minimizeBtn.Text = isMinimized and "+" or "-"
end)

local sideBar = Instance.new("Frame", mainBody)
sideBar.Size = UDim2.new(0, 80, 1, 0)
sideBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
sideBar.BorderSizePixel = 0

local combatTabBtn = Instance.new("TextButton", sideBar)
combatTabBtn.Size = UDim2.new(1, 0, 0, 45)
combatTabBtn.Text = "combat"
combatTabBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
combatTabBtn.TextColor3 = Color3.new(1, 1, 1)
combatTabBtn.Font = Enum.Font.GothamBold
combatTabBtn.BorderSizePixel = 0

local visualTabBtn = Instance.new("TextButton", sideBar)
visualTabBtn.Size = UDim2.new(1, 0, 0, 45)
visualTabBtn.Position = UDim2.new(0, 0, 0, 45)
visualTabBtn.Text = "visuals"
visualTabBtn.BackgroundTransparency = 1
visualTabBtn.TextColor3 = Color3.new(0.5, 0.5, 0.5)
visualTabBtn.Font = Enum.Font.GothamBold
visualTabBtn.BorderSizePixel = 0

local combatFrame = Instance.new("Frame", mainBody)
combatFrame.Size = UDim2.new(1, -100, 1, -20)
combatFrame.Position = UDim2.new(0, 90, 0, 10)
combatFrame.BackgroundTransparency = 1

local visualFrame = Instance.new("Frame", mainBody)
visualFrame.Size = UDim2.new(1, -100, 1, -20)
visualFrame.Position = UDim2.new(0, 90, 0, 10)
visualFrame.BackgroundTransparency = 1
visualFrame.Visible = false

createStrictToggle(combatFrame, "camera lock", UDim2.new(0,0,0,0), isLockOnActive, function(v) isLockOnActive = v end)

local bindBtn = Instance.new("TextButton", combatFrame)
bindBtn.Size = UDim2.new(1, 0, 0, 30)
bindBtn.Position = UDim2.new(0,0,0,35)
bindBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
bindBtn.Text = "keybind: " .. lockKey.Name:lower()
bindBtn.TextColor3 = Color3.new(1,1,1)
bindBtn.Font = Enum.Font.Code
bindBtn.TextSize = 11
bindBtn.BorderSizePixel = 1
bindBtn.BorderColor3 = Color3.fromRGB(50,50,50)

bindBtn.MouseButton1Click:Connect(function()
    isBinding = true
    bindBtn.Text = "press any key..."
end)

createStrictSlider(combatFrame, "lock smoothness", UDim2.new(0,0,0,75), 0.05, 1, lockSmoothness, function(v) lockSmoothness = v end)

createStrictToggle(visualFrame, "hitbox outline", UDim2.new(0,0,0,0), isShowHitboxEnabled, function(v) isShowHitboxEnabled = v end)

-- ADICIONADO: toggle AUTO SHOOT
createStrictToggle(combatFrame, "auto shoot", UDim2.new(0,0,0,115), isAutoShoot, function(v)
    isAutoShoot = v
end)

combatTabBtn.MouseButton1Click:Connect(function()
    combatFrame.Visible = true
    visualFrame.Visible = false
    combatTabBtn.TextColor3 = Color3.new(1, 1, 1)
    combatTabBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    visualTabBtn.TextColor3 = Color3.new(0.5,0.5,0.5)
    visualTabBtn.BackgroundTransparency = 1
end)

visualTabBtn.MouseButton1Click:Connect(function()
    combatFrame.Visible = false
    visualFrame.Visible = true
    visualTabBtn.TextColor3 = Color3.new(1, 1, 1)
    visualTabBtn.BackgroundTransparency = 0
    combatTabBtn.TextColor3 = Color3.new(0.5,0.5,0.5)
    combatTabBtn.BackgroundColor3 = Color3.fromRGB(10,10,10)
end)

UserInputService.InputBegan:Connect(function(input)
    if isBinding then
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            lockKey = input.KeyCode
            bindBtn.Text = "keybind: " .. lockKey.Name:lower()
            isBinding = false
        end
    elseif input.KeyCode == lockKey then
        isLockOnActive = not isLockOnActive
    end
end)

-- ADICIONADO: Função Auto Shoot
local function autoShoot(target)
    if not target then return end

    local char = player.Character
    if not char then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    for _, obj in pairs(tool:GetChildren()) do
        if obj:IsA("RemoteEvent") and (obj.Name:lower():match("shoot") or obj.Name:lower():match("fire") or obj.Name:lower():match("attack")) then
            obj:FireServer(target.Position)
            return
        end
    end
end

RunService.RenderStepped:Connect(function()
    if isLockOnActive then
        local target = getValidTarget()
        if target then
            local goal = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goal, lockSmoothness)

            -- AUTO SHOOT INTEGRADO
            if isAutoShoot then
                autoShoot(target)
            end
        end
    end
end)
