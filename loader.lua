if game.CoreGui:FindFirstChild("ModernScriptHub") then
    game.CoreGui.ModernScriptHub:Destroy()
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(25, 25, 30),
    Card = Color3.fromRGB(35, 38, 47),
    CardHover = Color3.fromRGB(45, 50, 65),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(150, 150, 160),
    TextDisabled = Color3.fromRGB(100, 100, 110),
    Border = Color3.fromRGB(50, 55, 70),
    BorderHover = Color3.fromRGB(0, 150, 255),
    Success = Color3.fromRGB(0, 230, 100),
    Beta = Color3.fromRGB(255, 200, 0),
    Broken = Color3.fromRGB(255, 60, 60),
}

local Badges = {
    READY = {text = "🟢 READY", color = Theme.Success},
    BETA = {text = "🟡 BETA", color = Theme.Beta},
    BROKEN = {text = "🔴 BROKEN", color = Theme.Broken},
    LOCKED = {text = "🔒 LOCKED", color = Theme.TextDisabled},
}

local ScriptsData = {
    {name = "ESP Script (Hub)", src = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/ESP.lua"))()', status = "READY", desc = "Highlight players, show health, distance"},
    {name = "Music Player Script", src = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/Music-Player.lua"))()', status = "READY", desc = "Play music, control volume, queue songs"},
    {name = "sUNC Test Suite Script", src = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/sUNC-TestSuite.lua"))()', status = "BETA", desc = "Test UNC compatibility and features"},
    {name = "Aimbot Script", src = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/Aimbot.lua"))()', status = "BROKEN", desc = "Auto aim assist (Currently not working)"},
    {name = "Speedhack & Super Jump", src = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/SpeedAndJumpModifier.lua"))()', status = "READY", desc = "Increase movement speed and jump height"},
    {name = "Super Admin Tools", src = "", status = "LOCKED", desc = "Admin commands coming soon"},
    {name = "Aura & Hitbox Expander", src = "loadstring(game:HttpGet("https://raw.githubusercontent.com/hoanglonggg79/script/refs/heads/main/Aura.lua"))()', status = "READY", desc = "Powerful Push Aura and Hitbox Expander"},
    {name = "Teleport Hub", src = "", status = "LOCKED", desc = "Quick teleport to locations"},
    {name = "Auto Farm System", src = "", status = "LOCKED", desc = "Automatic farming features"},
    {name = "Visual Mod Pack", src = "", status = "LOCKED", desc = "Chams, tracer, effects pack"},
}

local TweenSettings = {
    duration = 0.2,
    style = Enum.EasingStyle.Quad,
    direction = Enum.EasingDirection.Out,
}

local function ShowNotification(title, message, duration)
    duration = duration or 3
    
    local notifContainer = Instance.new("Frame")
    local notifCorner = Instance.new("UICorner")
    local notifStroke = Instance.new("UIStroke")
    local titleLabel = Instance.new("TextLabel")
    local msgLabel = Instance.new("TextLabel")
    
    notifContainer.Name = "Notification"
    notifContainer.Parent = game.CoreGui
    notifContainer.Size = UDim2.new(0, 320, 0, 60)
    notifContainer.Position = UDim2.new(1, -340, 0, 10)
    notifContainer.BackgroundColor3 = Theme.Background
    notifContainer.BackgroundTransparency = 0
    notifContainer.ZIndex = 10
    
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notifContainer
    
    notifStroke.Parent = notifContainer
    notifStroke.Thickness = 1
    notifStroke.Color = Theme.Accent
    
    titleLabel.Parent = notifContainer
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.Size = UDim2.new(0, 280, 0, 20)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.Accent
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    msgLabel.Parent = notifContainer
    msgLabel.BackgroundTransparency = 1
    msgLabel.Position = UDim2.new(0, 12, 0, 28)
    msgLabel.Size = UDim2.new(0, 280, 0, 24)
    msgLabel.Font = Enum.Font.GothamMedium
    msgLabel.Text = message
    msgLabel.TextColor3 = Theme.TextSecondary
    msgLabel.TextSize = 12
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    
    local inTween = TweenService:Create(notifContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -10, 0, 10)
    })
    inTween:Play()
    
    task.wait(duration)
    
    local outTween = TweenService:Create(notifContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 10, 0, 10)
    })
    outTween:Play()
    outTween.Completed:Connect(function()
        notifContainer:Destroy()
    end)
end

local function CreateTooltip(parent, text)
    local tooltip = Instance.new("TextLabel")
    local tooltipCorner = Instance.new("UICorner")
    
    tooltip.Name = "Tooltip"
    tooltip.Parent = parent
    tooltip.BackgroundColor3 = Theme.Background
    tooltip.TextColor3 = Theme.Text
    tooltip.Font = Enum.Font.GothamMedium
    tooltip.TextSize = 11
    tooltip.Text = text
    tooltip.TextWrapped = true
    tooltip.Size = UDim2.new(0, 180, 0, 30)
    tooltip.Position = UDim2.new(0, 10, 1, 5)
    tooltip.BackgroundTransparency = 1
    tooltip.Visible = false
    tooltip.ZIndex = 20
    
    tooltipCorner.CornerRadius = UDim.new(0, 4)
    tooltipCorner.Parent = tooltip
    
    local mouseEnterConn
    local mouseLeaveConn
    
    mouseEnterConn = parent.MouseEnter:Connect(function()
        tooltip.BackgroundTransparency = 0
        tooltip.Visible = true
    end)
    
    mouseLeaveConn = parent.MouseLeave:Connect(function()
        tooltip.BackgroundTransparency = 1
        tooltip.Visible = false
    end)
    
    parent.Destroying:Connect(function()
        mouseEnterConn:Disconnect()
        mouseLeaveConn:Disconnect()
        tooltip:Destroy()
    end)
    
    return tooltip
end

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Gradient = Instance.new("UIGradient")
local AccentBar = Instance.new("Frame")
local Shadow = Instance.new("ImageLabel")
local TitleLabel = Instance.new("TextLabel")
local SubtitleLabel = Instance.new("TextLabel")
local ScrollFrame = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local CloseButton = Instance.new("TextButton")
local MainStroke = Instance.new("UIStroke")

ScreenGui.Name = "ModernScriptHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.ClipsDescendants = true
MainFrame.BackgroundTransparency = 0

Shadow.Name = "Shadow"
Shadow.Parent = MainFrame
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0, -10, 0, -10)
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Image = "rbxassetid://1316045210"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.6
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 10, 10)

MainStroke.Parent = MainFrame
MainStroke.Thickness = 1.5
MainStroke.Color = Theme.Accent
MainStroke.Transparency = 0.7
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

Gradient.Parent = MainFrame
Gradient.Rotation = 45
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.Background),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 38))
})

AccentBar.Name = "AccentBar"
AccentBar.Parent = MainFrame
AccentBar.BackgroundColor3 = Theme.Accent
AccentBar.Size = UDim2.new(1, 0, 0, 3)
AccentBar.Position = UDim2.new(0, 0, 0, 0)

TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 20, 0, 14)
TitleLabel.Size = UDim2.new(0, 300, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "PREMIUM SCRIPT HUB"
TitleLabel.TextColor3 = Theme.Text
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

SubtitleLabel.Parent = MainFrame
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Position = UDim2.new(0, 20, 0, 38)
SubtitleLabel.Size = UDim2.new(0, 300, 0, 16)
SubtitleLabel.Font = Enum.Font.Gotham
SubtitleLabel.Text = "Premium Script Collection"
SubtitleLabel.TextColor3 = Theme.Accent
SubtitleLabel.TextSize = 10
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left

CloseButton.Name = "CloseButton"
CloseButton.Parent = MainFrame
CloseButton.BackgroundTransparency = 1
CloseButton.Position = UDim2.new(1, -45, 0, 14)
CloseButton.Size = UDim2.new(0, 35, 0, 35)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.TextColor3 = Theme.TextSecondary
CloseButton.TextSize = 18
CloseButton.AutoButtonColor = false

local closeEnterConn = CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 100, 100)}):Play()
end)
local closeLeaveConn = CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.15), {TextColor3 = Theme.TextSecondary}):Play()
end)
CloseButton.MouseButton1Click:Connect(function()
    local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    closeTween:Play()
    closeTween.Completed:Connect(function()
        ScreenGui:Destroy()
        closeEnterConn:Disconnect()
        closeLeaveConn:Disconnect()
    end)
end)

ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Parent = MainFrame
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.Position = UDim2.new(0, 15, 0, 65)
ScrollFrame.Size = UDim2.new(0, 370, 0, 420)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Theme.TextSecondary

UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)

local function UpdateCanvasSize()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
end

local contentSizeConn = UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvasSize)

local dragging = false
local dragStart = nil
local startPos = nil

local inputBeganConn = MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
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

local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local activeButtons = {}
local buttonConnections = {}

local function CreateScriptButton(parent, data, index)
    local Button = Instance.new("TextButton")
    local ButtonCorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")
    local statusLabel = Instance.new("TextLabel")
    local loadingSpinner = Instance.new("TextLabel")
    
    Button.Name = "ScriptBtn_"..index
    Button.Parent = parent
    Button.Size = UDim2.new(1, -10, 0, 60)
    Button.Font = Enum.Font.GothamSemibold
    Button.Text = "  " .. data.name
    Button.TextSize = 14
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.TextYAlignment = Enum.TextYAlignment.Top
    Button.TextColor3 = data.status == "LOCKED" and Theme.TextDisabled or Theme.Text
    Button.AutoButtonColor = false
    
    ButtonCorner.CornerRadius = UDim.new(0, 8)
    ButtonCorner.Parent = Button
    
    UIStroke.Parent = Button
    UIStroke.Thickness = 1
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Color = data.status == "LOCKED" and Color3.fromRGB(40, 40, 45) or Theme.Border
    
    local badge = Badges[data.status] or Badges.LOCKED
    statusLabel.Parent = Button
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.new(0, 12, 0, 35)
    statusLabel.Size = UDim2.new(0, 100, 0, 16)
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.Text = badge.text
    statusLabel.TextColor3 = badge.color
    statusLabel.TextSize = 10
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Parent = Button
    descLabel.BackgroundTransparency = 1
    descLabel.Position = UDim2.new(0, 12, 0, 48)
    descLabel.Size = UDim2.new(1, -20, 0, 14)
    descLabel.Font = Enum.Font.Gotham
    descLabel.Text = data.desc or "No description"
    descLabel.TextColor3 = Theme.TextSecondary
    descLabel.TextSize = 9
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    loadingSpinner.Parent = Button
    loadingSpinner.BackgroundTransparency = 1
    loadingSpinner.Position = UDim2.new(1, -40, 0, 20)
    loadingSpinner.Size = UDim2.new(0, 20, 0, 20)
    loadingSpinner.Font = Enum.Font.GothamBold
    loadingSpinner.Text = "⏳"
    loadingSpinner.TextColor3 = Theme.Accent
    loadingSpinner.TextSize = 16
    loadingSpinner.Visible = false
    
    if data.desc then
        CreateTooltip(Button, data.desc)
    end
    
    Button.BackgroundColor3 = data.status == "LOCKED" and Color3.fromRGB(28, 29, 33) or Theme.Card
    
    if data.status ~= "LOCKED" then
        local enterConn, leaveConn, clickConn
        local hoverTween, strokeTween
        
        enterConn = Button.MouseEnter:Connect(function()
            if hoverTween then hoverTween:Cancel() end
            if strokeTween then strokeTween:Cancel() end
            hoverTween = TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                BackgroundColor3 = Theme.CardHover
            })
            hoverTween:Play()
            
            strokeTween = TweenService:Create(UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Color = Theme.BorderHover
            })
            strokeTween:Play()
        end)
        
        leaveConn = Button.MouseLeave:Connect(function()
            if hoverTween then hoverTween:Cancel() end
            if strokeTween then strokeTween:Cancel() end
            hoverTween = TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                BackgroundColor3 = Theme.Card
            })
            hoverTween:Play()
            
            strokeTween = TweenService:Create(UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Color = Theme.Border
            })
            strokeTween:Play()
        end)
        
        clickConn = Button.MouseButton1Click:Connect(function()
            loadingSpinner.Visible = true
            Button.Text = "  " .. data.name .. " (Loading...)"
            Button.TextColor3 = Theme.Accent
            
            ShowNotification(data.name, "Starting script...", 1)
            
            task.wait(0.2)
            
            local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            })
            closeTween:Play()
            closeTween.Completed:Connect(function()
                ScreenGui:Destroy()
                task.wait(0.1)
                local success, err = pcall(function()
                    loadstring(data.src)()
                end)
                if success then
                    ShowNotification("✅ SUCCESS", data.name .. " loaded!", 2)
                else
                    ShowNotification("❌ ERROR", "Failed to load: " .. tostring(err), 3)
                    warn("Error: " .. tostring(err))
                end
                for _, conn in pairs(buttonConnections) do
                    if conn then
                        pcall(function() conn:Disconnect() end)
                    end
                end
                if contentSizeConn then contentSizeConn:Disconnect() end
                if inputBeganConn then inputBeganConn:Disconnect() end
                if inputChangedConn then inputChangedConn:Disconnect() end
                if inputEndedConn then inputEndedConn:Disconnect() end
            end)
        end)
        
        buttonConnections[#buttonConnections + 1] = enterConn
        buttonConnections[#buttonConnections + 1] = leaveConn
        buttonConnections[#buttonConnections + 1] = clickConn
    end
    
    activeButtons[#activeButtons + 1] = Button
    return Button
end

for i, data in ipairs(ScriptsData) do
    CreateScriptButton(ScrollFrame, data, i)
end

local openTween = TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 400, 0, 500),
    Position = UDim2.new(0.5, -200, 0.5, -250)
})
openTween:Play()

task.wait(0.1)
UpdateCanvasSize()

task.wait(0.5)
ShowNotification("PREMIUM HUB", "Loaded successfully! " .. #ScriptsData .. " scripts available", 3)

print("[Premium Hub]: Menu loaded successfully!")

local guiVisible = true
local hotkeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F3 then
        guiVisible = not guiVisible
        local targetTransparency = guiVisible and 0 or 1
        TweenService:Create(MainFrame, TweenInfo.new(0.2), {BackgroundTransparency = targetTransparency}):Play()
        TweenService:Create(Shadow, TweenInfo.new(0.2), {ImageTransparency = targetTransparency == 0 and 0.6 or 1}):Play()
        for _, child in ipairs(MainFrame:GetDescendants()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = targetTransparency}):Play()
            end
        end
    end
end)

buttonConnections[#buttonConnections + 1] = hotkeyConn

ScreenGui.Destroying:Connect(function()
    for _, conn in pairs(buttonConnections) do
        if conn then
            pcall(function() conn:Disconnect() end)
        end
    end
    if contentSizeConn then pcall(function() contentSizeConn:Disconnect() end) end
    if inputBeganConn then pcall(function() inputBeganConn:Disconnect() end) end
    if inputChangedConn then pcall(function() inputChangedConn:Disconnect() end) end
    if inputEndedConn then pcall(function() inputEndedConn:Disconnect() end) end
end)
