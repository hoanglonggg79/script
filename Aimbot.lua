--[[
    Aimbot Script cho Roblox (Luau)
    Cẩn thận ban khi dùng — chỉ dùng executor ổn định.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function GetCamera()
    return workspace.CurrentCamera
end

-- Tránh load trùng
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("AimbotGUI") then
    CoreGui.AimbotGUI:Destroy()
end

local Settings = {
    Enabled = false,
    AimKey = "RightButton",
    TeamCheck = true,
    VisibleCheck = true,
    SilentAim = false,
    StickyAim = true,
    ShowFOV = true,
    UseMouseFOV = true,
    FOV = 120,
    Smoothness = 8,
    AimPart = "Head",
    Prediction = 0.12,
    MaxDistance = 450,
}

local State = {
    CurrentTarget = nil,
    SilentTargetPart = nil,
    GuiVisible = true,
}

local AIM_PARTS = {"Head", "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso"}
local AIM_KEYS = {"RightButton", "LeftButton", "Q", "E", "R", "F", "C", "X"}

local Theme = {
    Background = Color3.fromRGB(18, 18, 26),
    Card = Color3.fromRGB(30, 32, 44),
    Accent = Color3.fromRGB(88, 166, 255),
    Success = Color3.fromRGB(52, 211, 153),
    Danger = Color3.fromRGB(248, 113, 113),
    Text = Color3.fromRGB(240, 240, 245),
    Muted = Color3.fromRGB(160, 165, 180),
}

-- ── Raycast helpers ──────────────────────────────────────────────

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local function UpdateRayFilter()
    local ignore = {}
    if LocalPlayer.Character then
        table.insert(ignore, LocalPlayer.Character)
    end
    RayParams.FilterDescendantsInstances = ignore
end

local function IsVisible(targetPart)
    if not targetPart or not targetPart.Parent then
        return false
    end

    local cam = GetCamera()
    if not cam then
        return false
    end

    UpdateRayFilter()
    local origin = cam.CFrame.Position
    local direction = targetPart.Position - origin
    local result = workspace:Raycast(origin, direction, RayParams)

    if not result then
        return true
    end

    local hit = result.Instance
    return hit == targetPart or hit:IsDescendantOf(targetPart.Parent)
end

local function GetAimPart(character, partName)
    if not character then
        return nil
    end

    local part = character:FindFirstChild(partName)
    if part and part:IsA("BasePart") then
        return part
    end

    if partName == "Torso" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end

    return character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

local function GetPredictedPosition(part)
    if not part then
        return nil
    end

    local pos = part.Position
    if Settings.Prediction <= 0 then
        return pos
    end

    local root = part.Parent and part.Parent:FindFirstChild("HumanoidRootPart")
    local velocity = Vector3.zero
    if root then
        velocity = root.AssemblyLinearVelocity
        if velocity.Magnitude < 0.01 then
            velocity = root.Velocity
        end
    elseif part:IsA("BasePart") then
        velocity = part.AssemblyLinearVelocity
        if velocity.Magnitude < 0.01 then
            velocity = part.Velocity
        end
    end

    return pos + velocity * Settings.Prediction
end

local function IsValidTarget(player)
    if not player or player == LocalPlayer then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return false
    end

    if humanoid.Health <= 0 then
        return false
    end

    if character:FindFirstChildOfClass("ForceField") then
        return false
    end

    if Settings.TeamCheck then
        local myTeam = LocalPlayer.Team
        local theirTeam = player.Team
        if myTeam and theirTeam and myTeam == theirTeam then
            return false
        end
    end

    return true
end

local function GetFOVOrigin()
    local cam = GetCamera()
    if not cam then
        return Vector2.new(0, 0)
    end

    if Settings.UseMouseFOV then
        return UserInputService:GetMouseLocation()
    end

    local size = cam.ViewportSize
    return Vector2.new(size.X / 2, size.Y / 2)
end

local function GetTargetScore(player, fovOrigin)
    if not IsValidTarget(player) then
        return nil
    end

    local character = player.Character
    local aimPart = GetAimPart(character, Settings.AimPart)
    if not aimPart then
        return nil
    end

    if Settings.VisibleCheck and not IsVisible(aimPart) then
        return nil
    end

    local cam = GetCamera()
    local predictedPos = GetPredictedPosition(aimPart)
    local screenPos, onScreen = cam:WorldToViewportPoint(predictedPos)
    if not onScreen or screenPos.Z <= 0 then
        return nil
    end

    local fovDistance = (Vector2.new(screenPos.X, screenPos.Y) - fovOrigin).Magnitude
    if fovDistance > Settings.FOV then
        return nil
    end

    local worldDistance = (cam.CFrame.Position - predictedPos).Magnitude
    if worldDistance > Settings.MaxDistance then
        return nil
    end

    return {
        Player = player,
        AimPart = aimPart,
        FOVDistance = fovDistance,
        WorldDistance = worldDistance,
        PredictedPos = predictedPos,
    }
end

local function GetBestTarget()
    local fovOrigin = GetFOVOrigin()

    if Settings.StickyAim and State.CurrentTarget then
        local stickyScore = GetTargetScore(State.CurrentTarget, fovOrigin)
        if stickyScore then
            return stickyScore
        end
    end

    local best = nil
    for _, player in ipairs(Players:GetPlayers()) do
        local score = GetTargetScore(player, fovOrigin)
        if score and (not best or score.FOVDistance < best.FOVDistance) then
            best = score
        end
    end

    return best
end

local function IsAimKeyHeld()
    if Settings.AimKey == "RightButton" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif Settings.AimKey == "LeftButton" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end

    local keyCode = Enum.KeyCode[Settings.AimKey]
    return keyCode and UserInputService:IsKeyDown(keyCode) or false
end

-- ── Silent aim hook (executor có hookmetamethod) ─────────────────

local SilentHookInstalled = false

local function TryInstallSilentHook()
    if SilentHookInstalled then
        return true
    end

    local ok, err = pcall(function()
        if not hookmetamethod or not getnamecallmethod or not checkcaller then
            error("Executor không hỗ trợ hook")
        end

        local OldNamecall
        OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if Settings.SilentAim and Settings.Enabled and State.SilentTargetPart and not checkcaller() then
                local targetPos = GetPredictedPosition(State.SilentTargetPart)
                if targetPos then
                    local cam = GetCamera()
                    if cam then
                        local origin = cam.CFrame.Position
                        local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude

                        if method == "Raycast" then
                            local args = {...}
                            if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                                args[1] = origin
                                args[2] = direction
                                return OldNamecall(self, unpack(args))
                            end
                        elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                            local args = {...}
                            args[1] = Ray.new(origin, direction)
                            return OldNamecall(self, unpack(args))
                        end
                    end
                end
            end
            return OldNamecall(self, ...)
        end)
    end)

    if ok then
        SilentHookInstalled = true
        return true
    end

    warn("[Aimbot] Silent Aim hook không khả dụng:", err)
    return false
end

-- ── GUI ──────────────────────────────────────────────────────────

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Parent = ScreenGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Theme.Accent
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.35
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 280, 0, 420)
MainFrame.Position = UDim2.new(0, 12, 0, 12)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 78)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -16, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "AIMBOT by HoangLong"
Title.TextColor3 = Theme.Text
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 18)
StatusLabel.Position = UDim2.new(0, 12, 0, 44)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Trạng thái: Tắt"
StatusLabel.TextColor3 = Theme.Muted
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -24, 0, 38)
ToggleBtn.Position = UDim2.new(0, 12, 0, 66)
ToggleBtn.BackgroundColor3 = Theme.Danger
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "BẬT AIMBOT"
ToggleBtn.TextColor3 = Theme.Text
ToggleBtn.TextSize = 15
ToggleBtn.AutoButtonColor = false
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -24, 1, -118)
Scroll.Position = UDim2.new(0, 12, 0, 112)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Theme.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 10)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Scroll

local function AddSection(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = Theme.Accent
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = Scroll
    return label
end

local function AddCheckbox(title, settingKey)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = Scroll

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0, 22, 0, 22)
    box.BackgroundColor3 = Theme.Card
    box.Font = Enum.Font.GothamBold
    box.Text = Settings[settingKey] and "✓" or ""
    box.TextColor3 = Theme.Success
    box.TextSize = 14
    box.AutoButtonColor = false
    box.Parent = row

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 5)
    boxCorner.Parent = box

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = title
    label.TextColor3 = Theme.Muted
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    box.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        box.Text = Settings[settingKey] and "✓" or ""
        if settingKey == "SilentAim" and Settings[settingKey] then
            TryInstallSilentHook()
        end
    end)
end

local function AddSlider(title, minVal, maxVal, settingKey, isFloat)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.BackgroundTransparency = 1
    frame.Parent = Scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = title .. ": " .. tostring(Settings[settingKey])
    label.TextColor3 = Theme.Muted
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, 0, 0, 18)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = Theme.Card
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = frame

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 6)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((Settings[settingKey] - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    local dragging = false

    local function applyValue(inputX)
        local percent = math.clamp((inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = minVal + (maxVal - minVal) * percent
        if isFloat then
            value = math.round(value * 100) / 100
        else
            value = math.round(value)
        end
        Settings[settingKey] = value
        label.Text = title .. ": " .. tostring(value)
        fill.Size = UDim2.new(percent, 0, 1, 0)
    end

    track.MouseButton1Down:Connect(function()
        dragging = true
        applyValue(UserInputService:GetMouseLocation().X)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            applyValue(input.Position.X)
        end
    end)
end

local function AddDropdown(title, options, settingKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 48)
    frame.BackgroundTransparency = 1
    frame.Parent = Scroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = title
    label.TextColor3 = Theme.Muted
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 24)
    button.Position = UDim2.new(0, 0, 0, 22)
    button.BackgroundColor3 = Theme.Card
    button.Font = Enum.Font.GothamMedium
    button.Text = tostring(Settings[settingKey])
    button.TextColor3 = Theme.Text
    button.TextSize = 13
    button.AutoButtonColor = false
    button.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    local index = table.find(options, Settings[settingKey]) or 1
    button.MouseButton1Click:Connect(function()
        index = index % #options + 1
        Settings[settingKey] = options[index]
        button.Text = tostring(options[index])
    end)
end

AddSection("Tính năng")
AddCheckbox("Team Check", "TeamCheck")
AddCheckbox("Visible Check", "VisibleCheck")
AddCheckbox("Sticky Aim (giữ mục tiêu)", "StickyAim")
AddCheckbox("Silent Aim (hook ray)", "SilentAim")
AddCheckbox("Hiện vòng FOV", "ShowFOV")
AddCheckbox("FOV theo chuột", "UseMouseFOV")

AddSection("Thông số")
AddSlider("FOV (px)", 30, 400, "FOV", false)
AddSlider("Smoothness", 1, 25, "Smoothness", false)
AddSlider("Prediction (s)", 0, 0.5, "Prediction", true)
AddSlider("Max Distance", 50, 1000, "MaxDistance", false)

AddSection("Mục tiêu")
AddDropdown("Aim Part", AIM_PARTS, "AimPart")
AddDropdown("Aim Key", AIM_KEYS, "AimKey")

-- Kéo thả GUI
do
    local dragging = false
    local dragStart
    local startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local function UpdateFOVCircle()
    FOVCircle.Visible = Settings.ShowFOV and Settings.Enabled
    if not FOVCircle.Visible then
        return
    end

    local diameter = Settings.FOV * 2
    FOVCircle.Size = UDim2.fromOffset(diameter, diameter)

    local origin = GetFOVOrigin()
    FOVCircle.Position = UDim2.fromOffset(origin.X - Settings.FOV, origin.Y - Settings.FOV)
end

local function UpdateStatusText(targetPlayer)
    if not Settings.Enabled then
        StatusLabel.Text = "Trạng thái: Tắt"
        StatusLabel.TextColor3 = Theme.Muted
        return
    end

    if targetPlayer then
        StatusLabel.Text = "Đang nhắm: " .. targetPlayer.Name
        StatusLabel.TextColor3 = Theme.Success
    else
        StatusLabel.Text = "Trạng thái: Bật — không có mục tiêu"
        StatusLabel.TextColor3 = Theme.Accent
    end
end

local function ToggleAimbot()
    Settings.Enabled = not Settings.Enabled

    if Settings.Enabled then
        ToggleBtn.Text = "TẮT AIMBOT"
        ToggleBtn.BackgroundColor3 = Theme.Success
        if Settings.SilentAim then
            TryInstallSilentHook()
        end
    else
        ToggleBtn.Text = "BẬT AIMBOT"
        ToggleBtn.BackgroundColor3 = Theme.Danger
        State.CurrentTarget = nil
        State.SilentTargetPart = nil
    end

    UpdateStatusText(nil)
    UpdateFOVCircle()
end

ToggleBtn.MouseButton1Click:Connect(ToggleAimbot)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.Insert then
        State.GuiVisible = not State.GuiVisible
        MainFrame.Visible = State.GuiVisible
    end
end)

-- ── Main loop ────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function(dt)
    UpdateFOVCircle()

    if not Settings.Enabled then
        State.SilentTargetPart = nil
        UpdateStatusText(nil)
        return
    end

    if not IsAimKeyHeld() then
        if not Settings.StickyAim then
            State.CurrentTarget = nil
        end
        State.SilentTargetPart = nil
        UpdateStatusText(nil)
        return
    end

    local targetData = GetBestTarget()
    if not targetData then
        State.CurrentTarget = nil
        State.SilentTargetPart = nil
        UpdateStatusText(nil)
        return
    end

    State.CurrentTarget = targetData.Player
    State.SilentTargetPart = targetData.AimPart
    UpdateStatusText(targetData.Player)

    if Settings.SilentAim then
        TryInstallSilentHook()
        return
    end

    local cam = GetCamera()
    if not cam then
        return
    end

    local targetCF = CFrame.new(cam.CFrame.Position, targetData.PredictedPos)
    if Settings.Smoothness <= 1 then
        cam.CFrame = targetCF
    else
        local alpha = math.clamp(1 - math.exp(-Settings.Smoothness * dt * 10), 0.05, 1)
        cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    UpdateRayFilter()
end)

if LocalPlayer.Character then
    UpdateRayFilter()
end

print("[Aimbot by HoangLong] Loaded!")
print("  • Bấm BẬT AIMBOT trong GUI")
print("  • Giữ phím aim (mặc định: chuột phải)")
print("  • Insert = ẩn/hiện GUI")
