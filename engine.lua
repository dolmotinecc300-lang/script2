local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local cfg = _G.cfg
local gui = _G.Gui

local fov = Instance.new("Frame", gui)
fov.BackgroundTransparency = 1
fov.Size = UDim2.new(0, cfg.Fov * 2, 0, cfg.Fov * 2)
fov.Position = UDim2.new(0.5, -cfg.Fov, 0.5, -cfg.Fov)
Instance.new("UICorner", fov).CornerRadius = UDim.new(1,0)
local fovStroke = Instance.new("UIStroke", fov)
fovStroke.Color = Color3.fromRGB(255,0,0)
fovStroke.Thickness = 2

local function getCol(p)
    local n = (p.Team and p.Team.Name:lower()) or ""
    if n:find("guard") or n:find("cop") or n:find("police") then return Color3.fromRGB(0,100,255) end
    if n:find("criminal") or n:find("prisoner") then return Color3.fromRGB(255,0,0) end
    if n:find("inmate") or n:find("prison") then return Color3.fromRGB(0,255,0) end
    return Color3.new(1,1,1)
end

local function setupP(p)
    if p == LocalPlayer then return end
    local function a()
        if not p.Character then return end
        local o = p.Character:FindFirstChild("ESP_Highlight")
        if o then o:Destroy() end
        local h = Instance.new("Highlight", p.Character)
        h.Name = "ESP_Highlight"
        h.FillColor = getCol(p)
        h.OutlineColor = Color3.new(1,1,1)
        h.FillTransparency = 0.3
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Enabled = cfg.Esp

        local head = p.Character:FindFirstChild("Head")
        if head then
            local oldBb = head:FindFirstChild("ESP_Name")
            if oldBb then oldBb:Destroy() end
            local bb = Instance.new("BillboardGui", head)
            bb.Name = "ESP_Name"
            bb.Size = UDim2.new(0, 100, 0, 20)
            bb.StudsOffset = Vector3.new(0, 1.5, 0)
            bb.AlwaysOnTop = true
            bb.Enabled = cfg.EspNames
            local txt = Instance.new("TextLabel", bb)
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = p.Name
            txt.TextColor3 = getCol(p)
            txt.TextStrokeTransparency = 0
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 12
        end
    end
    p.CharacterAdded:Connect(function() task.wait(1); a() end)
    if p.Character then a() end
end
Players.PlayerAdded:Connect(setupP)
for _, p in ipairs(Players:GetPlayers()) do setupP(p) end

local function isVis(part)
    if not cfg.Kill then return true end
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    return workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rp) == nil
end

LocalPlayer.CharacterAdded:Connect(function(c) task.wait(1); local h = c:FindFirstChild("Humanoid"); if h then h.WalkSpeed = cfg.Speed end end)
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = cfg.Speed end

UserInputService.JumpRequest:Connect(function()
    if cfg.InfJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- AUTO PUNCH
local autoPunchCooldown = 0
local function tryAutoPunch()
    if not cfg.AutoPunch then return end
    if tick() - autoPunchCooldown < 0.6 then return end -- Задержка удара
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local theirRoot = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            if theirRoot and hum and hum.Health > 0 then
                if (theirRoot.Position - root.Position).Magnitude <= 6 then -- Радиус удара
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        -- Имитация клика мышью по игроку
                        pcall(function()
                            tool:Activate()
                        end)
                        autoPunchCooldown = tick()
                    end
                    break
                end
            end
        end
    end
end

-- INFINITE AMMO (Авто-перезарядка)
local reloadCooldown = 0
local function tryInfiniteAmmo()
    if not cfg.InfAmmo then return end
    if tick() - reloadCooldown < 0.5 then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    
    if tool then
        local ammo = tool:GetAttribute("Local_CurrentAmmo")
        local maxAmmo = tool:GetAttribute("MaxAmmo")
        
        if ammo and maxAmmo and ammo <= 0 then
            -- Эмуляция нажатия R (перезарядка)
            local reloadEvent = game:GetService("ReplicatedStorage"):FindFirstChild("GunRemotes")
            if reloadEvent and reloadEvent:FindFirstChild("ReloadEvent") then
                pcall(function()
                    reloadEvent.ReloadEvent:FireServer()
                end)
            else
                -- Если нет ремоута, пробуем через клавишу (работает не везде)
                pcall(function()
                    tool:Activate() -- Иногда заставляет перезарядиться
                end)
            end
            reloadCooldown = tick()
        end
    end
end

RunService.RenderStepped:Connect(function()
    -- Auto Punch
    if cfg.AutoPunch then tryAutoPunch() end
    -- Inf Ammo
    if cfg.InfAmmo then tryInfiniteAmmo() end

    -- Аим
    if cfg.Aim and cfg.Bind then
        local b, bd = nil, cfg.Fov
        local c = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("Head")
                local hu = p.Character:FindFirstChild("Humanoid")
                if h and hu then
                    local vh = true
                    if cfg.Kill and hu.Health <= 0 then vh = false end
                    if vh then
                        local n = (p.Team and p.Team.Name:lower()) or ""
                        local vm = false
                        if cfg.TargetPolice and (n:find("guard") or n:find("cop") or n:find("police")) then vm = true end
                        if cfg.TargetCriminals and (n:find("criminal") or n:find("prisoner")) then vm = true end
                        if cfg.TargetInmates and (n:find("inmate") or n:find("prison")) then vm = true end
                        
                        if vm then
                            local sp, on = Camera:WorldToViewportPoint(h.Position)
                            if on then
                                local d = (Vector2.new(sp.X, sp.Y) - c).Magnitude
                                if d < bd and isVis(h) then bd = d; b = h end
                            end
                        end
                    end
                end
            end
        end
        if b then Camera.CFrame = CFrame.new(Camera.CFrame.Position, b.Position) end
    end

    -- ESP и ники
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChild("ESP_Highlight")
            if h then 
                h.Enabled = cfg.Esp
                if cfg.Esp then h.FillColor = getCol(p) end 
            end
            local head = p.Character:FindFirstChild("Head")
            local theirRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if head and myRoot and theirRoot then
                local bb = head:FindFirstChild("ESP_Name")
                if bb then
                    local dist = (theirRoot.Position - myRoot.Position).Magnitude
                    bb.Enabled = cfg.EspNames and dist >= 500
                    if bb.Enabled then bb.TextLabel.TextColor3 = getCol(p) end
                end
            end
        end
    end
end)
