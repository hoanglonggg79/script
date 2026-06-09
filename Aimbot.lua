--[[
    Aimbot Script cho Roblox (LUAU)
    Cẩn thận ban khi dùng nhé anh em! Executor phải thật là ổn hẳn dùng nhé.
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Các bạn chỉnh cấu hình ở đây !!
local Settings = {
    Enabled = false,
    AimKey = "RightButton",     -- RightButton, LeftButton, Q, E, etc.
    TeamCheck = true,            -- Không nhắm vào đồng đội
    VisibleCheck = true,         -- Chỉ nhắm nếu nhìn thấy
    SilentAim = false,           -- Silent Aim (không xoay camera)
    FOV = 120,                   -- Vùng ảnh hưởng (pixels)
    Smoothness = 5,              -- Độ mượt (1 = snap, 10 = rất mượt)
    AimPart = "Head",            -- Head, HumanoidRootPart, Torso
    Prediction = 0.15,          -- Dự đoán di chuyển (giây)
    MaxDistance = 450           -- Khoảng cách tối đa
}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimbotGUI"
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 260, 0, 380)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "AIMBOT v1.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 50)
ToggleBtn.Text = "🔴 TẮT AIMBOT"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

local function AddSlider(parent, title, minVal, maxVal, settingKey, isFloat)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 60)
    frame.Position = UDim2.new(0.05, 0, 0, parent.Height + 10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    parent.Height = parent.Height + 70
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = title .. ": " .. tostring(Settings[settingKey])
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame
    
    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, 0, 0, 20)
    slider.Position = UDim2.new(0, 0, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.Text = ""
    slider.Parent = frame
    
    local sliderBar = Instance.new("Frame")
    sliderBar.Size = UDim2.new((Settings[settingKey] - minVal) / (maxVal - minVal), 0, 1, 0)
    sliderBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    sliderBar.Parent = slider
    
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = slider
    
    local dragging = false
    slider.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            local value = minVal + (maxVal - minVal) * percent
            if isFloat then
                value = math.round(value * 100) / 100
            else
                value = math.round(value)
            end
            Settings[settingKey] = value
            label.Text = title .. ": " .. tostring(value)
            sliderBar.Size = UDim2.new(percent, 0, 1, 0)
        end
    end)
    return frame
end

local function AddDropdown(parent, title, options, settingKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 50)
    frame.Position = UDim2.new(0.05, 0, 0, parent.Height + 10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    parent.Height = parent.Height + 60
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = title
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame
    
    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(1, 0, 0, 25)
    dropdown.Position = UDim2.new(0, 0, 0, 22)
    dropdown.Text = tostring(Settings[settingKey])
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    dropdown.Font = Enum.Font.Gotham
    dropdown.TextSize = 13
    dropdown.Parent = frame
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdown
    
    local index = 1
    dropdown.MouseButton1Click:Connect(function()
        index = index % #options + 1
        Settings[settingKey] = options[index]
        dropdown.Text = tostring(options[index])
    end)
    return frame
end

local function AddCheckbox(parent, title, settingKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.9, 0, 0, 30)
    frame.Position = UDim2.new(0.05, 0, 0, parent.Height + 10)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    parent.Height = parent.Height + 40
    
    local checkbox = Instance.new("TextButton")
    checkbox.Size = UDim2.new(0, 20, 0, 20)
    checkbox.Position = UDim2.new(0, 0, 0, 5)
    checkbox.Text = Settings[settingKey] and "✓" or ""
    checkbox.TextColor3 = Color3.fromRGB(100, 200, 100)
    checkbox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    checkbox.Font = Enum.Font.GothamBold
    checkbox.TextSize = 16
    checkbox.Parent = frame
    
    local checkboxCorner = Instance.new("UICorner")
    checkboxCorner.CornerRadius = UDim.new(0, 4)
    checkboxCorner.Parent = checkbox
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 30)
    label.Position = UDim2.new(0, 30, 0, 0)
    label.Text = title
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    checkbox.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        checkbox.Text = Settings[settingKey] and "✓" or ""
    end)
    return frame
end

-- GUI
local currentHeight = 95
AddCheckbox(MainFrame, "Team Check", "TeamCheck")
AddCheckbox(MainFrame, "Visible Check", "VisibleCheck")
AddCheckbox(MainFrame, "Silent Aim", "SilentAim")
AddSlider(MainFrame, "FOV", 30, 300, "FOV", false)
AddSlider(MainFrame, "Smoothness", 1, 20, "Smoothness", false)
AddSlider(MainFrame, "Prediction", 0, 0.5, "Prediction", true)
AddSlider(MainFrame, "Max Distance", 100, 500, "MaxDistance", false)
AddDropdown(MainFrame, "Aim Part", {"Head", "HumanoidRootPart", "Torso"}, "AimPart")
AddDropdown(MainFrame, "Aim Key", {"RightButton", "LeftButton", "Q", "E", "R", "F"}, "AimKey")

local function GetAimPart(character, partName)
    if partName == "Head" then
        return character:FindFirstChild("Head")
    elseif partName == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    else
        return character:FindFirstChild("HumanoidRootPart")
    end
end

local function IsVisible(targetPart)
    if not targetPart then return false end
    local origin = Camera.CFrame.Position
    local ray = Ray.new(origin, (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude)
    local hit = workspace:FindPartOnRay(ray, LocalPlayer.Character)
    local hitPart = hit
    if hitPart and (hitPart:IsDescendantOf(targetPart.Parent) or hitPart == targetPart) then
        return true
    end
    return false
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local closestDistance = Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                local aimPart = GetAimPart(player.Character, Settings.AimPart)
                if not aimPart then continue end
                
                local predictedPos = aimPart.Position
                if Settings.Prediction > 0 and player.Character:FindFirstChild("HumanoidRootPart") then
                    local velocity = player.Character.HumanoidRootPart.Velocity
                    predictedPos = aimPart.Position + velocity * Settings.Prediction
                end
                
                local vector, onScreen = Camera:WorldToViewportPoint(predictedPos)
                if not onScreen then continue end
                
                if Settings.VisibleCheck and not IsVisible(aimPart) then
                    continue
                end
                
                local distanceToCenter = (Vector2.new(vector.X, vector.Y) - center).Magnitude
                
                if distanceToCenter < closestDistance and vector.Z > 0 then
                    local actualDistance = (Camera.CFrame.Position - predictedPos).Magnitude
                    if actualDistance <= Settings.MaxDistance then
                        closestDistance = distanceToCenter
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer, closestDistance
end

local function SmoothAim(targetCFrame)
    local currentCFrame = Camera.CFrame
    local targetAngle = CFrame.new(Camera.CFrame.Position, targetCFrame.Position)
    local step = 1 / Settings.Smoothness
    for i = 1, Settings.Smoothness do
        task.wait()
        local newCFrame = currentCFrame:Lerp(targetAngle, i * step)
        Camera.CFrame = newCFrame
    end
    Camera.CFrame = targetAngle
end

local function AimAt(targetPart)
    if not targetPart then return end
    local targetPos = targetPart.Position
    if Settings.Prediction > 0 and targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart") then
        local velocity = targetPart.Parent.HumanoidRootPart.Velocity
        targetPos = targetPos + velocity * Settings.Prediction
    end
    
    local newCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
    
    if Settings.SilentAim then
        -- Silent Aim: chỉ ghi đè CFrame tạm thời
        local oldCFrame = Camera.CFrame
        Camera.CFrame = newCFrame
        task.wait()
        Camera.CFrame = oldCFrame
    else
        if Settings.Smoothness > 1 then
            SmoothAim(newCFrame)
        else
            Camera.CFrame = newCFrame
        end
    end
end

local lastTarget = nil
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then return end
    
    local aimKeyPressed = false
    if Settings.AimKey == "RightButton" then
        aimKeyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif Settings.AimKey == "LeftButton" then
        aimKeyPressed = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    else
        aimKeyPressed = UserInputService:IsKeyDown(Enum.KeyCode[Settings.AimKey])
    end
    
    if aimKeyPressed then
        local target, fovDist = GetClosestPlayerToCursor()
        if target and target.Character then
            local aimPart = GetAimPart(target.Character, Settings.AimPart)
            if aimPart then
                AimAt(aimPart)
                lastTarget = target
            end
        end
    end
end)

local function ToggleAimbot()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        ToggleBtn.Text = "🟢 BẬT AIMBOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        print("Aimbot Enabled")
    else
        ToggleBtn.Text = "🔴 TẮT AIMBOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        print("Aimbot Disabled")
    end
end

ToggleBtn.MouseButton1Click:Connect(ToggleAimbot)

print("Aimbot Script loaded! Nhấn nút BẬT AIMBOT để bắt đầu")
print("Mặc định aim bằng chuột phải, có thể tùy chỉnh trong GUI")
