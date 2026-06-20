============================================
= Aura script by HoangLong
============================================
local AURA_RADIUS = 12 -- Khoảng cách quét (Đừng để quá cao kẻo bị kick)
local KNOCKBACK_POWER = 150 -- Lực đẩy văng (Càng cao bay càng xa)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Biến trạng thái
local isAuraActive = false
local auraConnection = nil
local auraCooldown = 0.2 -- Thời gian chờ giữa các lần đẩy
local lastPushTime = 0

-- Tạo GUI
local function createGUI()
    -- Tạo ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AuraGUI"
    screenGui.Parent = LocalPlayer.PlayerGui
    
    -- Tạo Frame chính
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 120)
    mainFrame.Position = UDim2.new(0, 20, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 255)
    mainFrame.Parent = screenGui
    
    -- Làm tròn góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Tiêu đề
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "⚡ AURA CONTROLLER"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.Parent = mainFrame
    
    -- Nút bật/tắt
    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 100, 0, 40)
    toggleButton.Position = UDim2.new(0.5, -50, 0, 40)
    toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    toggleButton.Text = "TẮT"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 14
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = mainFrame
    
    -- Làm tròn góc cho nút
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = toggleButton
    
    -- Label hiển thị trạng thái
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 85)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: OFF"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    -- Nút điều chỉnh Radius
    local radiusSlider = Instance.new("TextButton")
    radiusSlider.Size = UDim2.new(0, 60, 0, 25)
    radiusSlider.Position = UDim2.new(0.2, 0, 0, 40)
    radiusSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    radiusSlider.Text = "-12"
    radiusSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    radiusSlider.TextSize = 12
    radiusSlider.Font = Enum.Font.Gotham
    radiusSlider.Visible = false
    radiusSlider.Parent = mainFrame
    
    local radiusLabel = Instance.new("TextLabel")
    radiusLabel.Size = UDim2.new(0, 40, 0, 25)
    radiusLabel.Position = UDim2.new(0.4, 0, 0, 40)
    radiusLabel.BackgroundTransparency = 1
    radiusLabel.Text = "R:12"
    radiusLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
    radiusLabel.TextSize = 12
    radiusLabel.Font = Enum.Font.Gotham
    radiusLabel.Visible = false
    radiusLabel.Parent = mainFrame
    
    local radiusSlider2 = Instance.new("TextButton")
    radiusSlider2.Size = UDim2.new(0, 60, 0, 25)
    radiusSlider2.Position = UDim2.new(0.6, 0, 0, 40)
    radiusSlider2.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    radiusSlider2.Text = "+12"
    radiusSlider2.TextColor3 = Color3.fromRGB(255, 255, 255)
    radiusSlider2.TextSize = 12
    radiusSlider2.Font = Enum.Font.Gotham
    radiusSlider2.Visible = false
    radiusSlider2.Parent = mainFrame
    
    -- Hàm cập nhật giao diện
    local function updateUI()
        if isAuraActive then
            toggleButton.Text = "BẬT"
            toggleButton.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
            statusLabel.Text = "Status: ON ✅"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            toggleButton.Text = "TẮT"
            toggleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            statusLabel.Text = "Status: OFF ❌"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end
    
    -- Hàm toggle aura
    local function toggleAura()
        isAuraActive = not isAuraActive
        
        if isAuraActive then
            if not auraConnection then
                auraConnection = RunService.RenderStepped:Connect(function()
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    
                    if not hrp or (hum and hum.Health <= 0) then return end
                    
                    local currentTime = tick()
                    if currentTime - lastPushTime < auraCooldown then return end
                    
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local tChar = player.Character
                            local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
                            local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
                            
                            if tHRP and tHum and tHum.Health > 0 then
                                local distance = (tHRP.Position - hrp.Position).Magnitude
                                
                                if distance <= AURA_RADIUS then
                                    local dir = (tHRP.Position - hrp.Position).Unit
                                    local velocity = Vector3.new(dir.X * KNOCKBACK_POWER, 30, dir.Z * KNOCKBACK_POWER)
                                    
                                    tHRP.AssemblyLinearVelocity = velocity
                                    tHRP.Velocity = velocity
                                    lastPushTime = currentTime
                                end
                            end
                        end
                    end
                end)
            end
        else
            if auraConnection then
                auraConnection:Disconnect()
                auraConnection = nil
            end
        end
        
        updateUI()
    end
    
    -- Sự kiện cho nút toggle
    toggleButton.MouseButton1Click:Connect(toggleAura)
    
    -- Phím tắt (Ctrl + A)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.A and input.UserInputType == Enum.UserInputType.Keyboard then
            local isCtrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or 
                             UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
            if isCtrlDown then
                toggleAura()
            end
        end
    end)
    
    -- Cập nhật UI lần đầu
    updateUI()
    
    -- Phím tắt cho Radisu (Ctrl + R)
    local function adjustRadius(amount)
        AURA_RADIUS = math.clamp(AURA_RADIUS + amount, 1, 30)
        radiusLabel.Text = "R:" .. AURA_RADIUS
        print("Aura Radius đã được đặt thành: " .. AURA_RADIUS)
    end
    
    radiusSlider.MouseButton1Click:Connect(function()
        adjustRadius(-1)
    end)
    
    radiusSlider2.MouseButton1Click:Connect(function()
        adjustRadius(1)
    end)
    
    -- Tạo indicator hiệu ứng khi aura active
    local auraIndicator = Instance.new("Frame")
    auraIndicator.Size = UDim2.new(0, 80, 0, 5)
    auraIndicator.Position = UDim2.new(0.5, -40, 0, 70)
    auraIndicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    auraIndicator.BackgroundTransparency = 1
    auraIndicator.BorderSizePixel = 0
    auraIndicator.Parent = mainFrame
    
    -- Animation cho indicator
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 3)
    indicatorCorner.Parent = auraIndicator
    
    -- Cập nhật indicator khi toggle
    local function updateIndicator()
        if isAuraActive then
            auraIndicator.BackgroundTransparency = 0.8
            auraIndicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            auraIndicator.Size = UDim2.new(0, 80, 0, 5)
        else
            auraIndicator.BackgroundTransparency = 1
            auraIndicator.Size = UDim2.new(0, 0, 0, 0)
        end
    end
    
    -- Ghi đè hàm toggleAura để thêm indicator
    local originalToggle = toggleAura
    toggleAura = function()
        originalToggle()
        updateIndicator()
    end
    
    -- Cập nhật indicator lần đầu
    updateIndicator()
    
    return screenGui
end

-- Khởi tạo GUI
createGUI()

print("Aura Controller đã được tải thành công!")
print("Sử dụng phím tắt Ctrl + A để bật/tắt aura")
print("Sử dụng phím tắt Ctrl + R để hiện/ẩn thanh điều chỉnh Radius")
