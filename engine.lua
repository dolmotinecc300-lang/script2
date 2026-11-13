local M = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local cfg = {
    Aim = false, Fov = 150, Bind = false, Esp = false, Kill = true, 
    TargetPolice = false, TargetCriminals = false, TargetInmates = false, 
    Speed = 27, InfJump = false, JumpBind = false, EspNames = false
}

function M.init(Window)
    -- Вкладки
    local AimTab = Window:CreateTab("Аим", nil)
    local ESPTab = Window:CreateTab("ESP", nil)
    local SetTab = Window:CreateTab("Настройки", nil)

    -- ================= АИМ =================
    AimTab:CreateToggle({
        Name = "Aimbot",
        CurrentValue = cfg.Aim,
        Flag = "Aimbot",
        Callback = function(v) cfg.Aim = v end,
    })

    AimTab:CreateSlider({
        Name = "FOV",
        Range = {0, 360},
        Increment = 1,
        Suffix = "°",
        CurrentValue = cfg.Fov,
        Flag = "FOV",
        Callback = function(v) cfg.Fov = v end,
    })

    AimTab:CreateToggle({
        Name = "Kill Check",
        CurrentValue = cfg.Kill,
        Flag = "KillCheck",
        Callback = function(v) cfg.Kill = v end,
    })

    AimTab:CreateSection("Цели")
    AimTab:CreateToggle({
        Name = "Полиция",
        CurrentValue = cfg.TargetPolice,
        Flag = "TPolice",
        Callback = function(v) cfg.TargetPolice = v end,
    })
    AimTab:CreateToggle({
        Name = "Преступники",
        CurrentValue = cfg.TargetCriminals,
        Flag = "TCrims",
        Callback = function(v) cfg.TargetCriminals = v end,
    })
    AimTab:CreateToggle({
        Name = "Заключенные",
        CurrentValue = cfg.TargetInmates,
        Flag = "TInmates",
        Callback = function(v) cfg.TargetInmates = v end,
    })

    -- ================= ESP =================
    ESPTab:CreateToggle({
        Name = "ESP (Подсветка)",
        CurrentValue = cfg.Esp,
        Flag = "ESP",
        Callback = function(v) cfg.Esp = v end,
    })

    ESPTab:CreateToggle({
        Name = "Nick Visible (> 500 studs)",
        CurrentValue = cfg.EspNames,
        Flag = "ESPNames",
        Callback = function(v) cfg.EspNames = v end,
    })

    -- ================= НАСТРОЙКИ =================
    SetTab:CreateInput({
        Name = "Speed (16-30)",
        CurrentValue = tostring(cfg.Speed),
        PlaceholderText = "16-30",
        RemoveTextAfterFocusLost = false,
        Callback = function(text)
            local n = tonumber(text)
            if n and n >= 16 and n <= 30 then
                cfg.Speed = n
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = n end
            end
        end,
    })

    SetTab:CreateToggle({
        Name = "Inf Jump",
        CurrentValue = cfg.InfJump,
        Flag = "InfJump",
        Callback = function(v) cfg.InfJump = v end,
    })

    -- ================= ПЛАВАЮЩИЕ КНОПКИ =================
    local function makeFloatingBtn(text, x, y, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 60)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Parent = game:GetService("CoreGui")
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 10)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local aimBtn = makeFloatingBtn("AIM", 20, 200, function()
        cfg.Aim = not cfg.Aim
        aimBtn.BackgroundColor3 = cfg.Aim and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(20, 40, 80)
    end)

    local jumpBtn = makeFloatingBtn("JUMP", 20, 270, function()
        cfg.InfJump = not cfg.InfJump
        jumpBtn.BackgroundColor3 = cfg.InfJump and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(20, 40, 80)
    end)

    -- ================= ЛОГИКА ИГРЫ =================
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

    RunService.Heartbeat:Connect(function()
        if cfg.Aim then
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
end

return M
