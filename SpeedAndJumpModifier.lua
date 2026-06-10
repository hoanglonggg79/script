-- ============================================================
--  Speed & Jump Modifier - By HoangLong
-- ============================================================

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local Config = {
    SpeedEnabled   = false,
    JumpEnabled    = false,
    SprintEnabled  = false,
    FlyEnabled     = false,
    ZeroGravEnabled = false,

    WalkSpeed      = 16,
    JumpPower      = 50,
    SprintSpeed    = 50,
    FlySpeed       = 60,

    MinSpeed       = 16,
    MaxSpeed       = 200,
    MinJump        = 50,
    MaxJump        = 300,
    MinSprint      = 16,
    MaxSprint      = 300,
    MinFly         = 10,
    MaxFly         = 300,
}

local isSprinting   = false
local flyBodyVel    = nil
local flyBodyGyro   = nil
local prevGravity   = workspace.Gravity

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid"), char
end

local function resetHumanoid()
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end
end

local function stopFly()
    if flyBodyVel  then flyBodyVel:Destroy();  flyBodyVel  = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    local hum, char = getHumanoid()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    stopFly()
    local hum, char = getHumanoid()
    if not hum or not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    hum.PlatformStand = true

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Velocity      = Vector3.zero
    flyBodyVel.MaxForce      = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVel.Parent        = root

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque    = Vector3.new(1e5, 1e5, 1e5)
    flyBodyGyro.P            = 1e4
    flyBodyGyro.CFrame       = root.CFrame
    flyBodyGyro.Parent       = root
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.LeftShift then isSprinting = true end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.LeftShift then isSprinting = false end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if Config.FlyEnabled then
        task.wait(0.5)
        startFly()
    end
end)

RunService.Heartbeat:Connect(function()
    local hum, char = getHumanoid()
    if not hum then return end

    if Config.SpeedEnabled then
        hum.WalkSpeed = (Config.SprintEnabled and isSprinting) and Config.SprintSpeed or Config.WalkSpeed
    end

    if Config.JumpEnabled then
        hum.JumpPower = Config.JumpPower
    end

    if Config.FlyEnabled and flyBodyVel and flyBodyGyro then
        local camera    = workspace.CurrentCamera
        local root      = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        local moveVec   = Vector3.zero
        local camCF     = camera.CFrame
        local speed     = Config.FlySpeed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec += camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec -= camCF.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec -= camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec += camCF.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec -= Vector3.yAxis end

        flyBodyVel.Velocity  = moveVec.Magnitude > 0 and (moveVec.Unit * speed) or Vector3.zero
        flyBodyGyro.CFrame   = camCF
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "SpeedJump_GUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = game:GetService("CoreGui")

local PURPLE    = Color3.fromRGB(110, 50, 240)
local PURPLE_LT = Color3.fromRGB(160, 100, 255)
local PURPLE_DK = Color3.fromRGB(70, 20, 160)
local BG_DARK   = Color3.fromRGB(10, 8, 18)
local BG_PANEL  = Color3.fromRGB(16, 12, 28)
local BG_ROW    = Color3.fromRGB(22, 17, 38)
local TEXT_PRI  = Color3.fromRGB(235, 230, 255)
local TEXT_SEC  = Color3.fromRGB(160, 150, 195)
local SEP_COL   = Color3.fromRGB(38, 28, 65)

local PANEL_W = 250
local PANEL_H = 530

local Panel = Instance.new("Frame")
Panel.Name             = "Panel"
Panel.Size             = UDim2.fromOffset(PANEL_W, PANEL_H)
Panel.Position         = UDim2.new(0, 16, 0.5, -PANEL_H / 2)
Panel.BackgroundColor3 = BG_PANEL
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Panel.Parent           = ScreenGui
do
    local c = Instance.new("UICorner", Panel)
    c.CornerRadius = UDim.new(0, 14)
    local s = Instance.new("UIStroke", Panel)
    s.Color     = Color3.fromRGB(80, 40, 180)
    s.Thickness = 1.2
    s.Transparency = 0.3
end

local Shadow = Instance.new("ImageLabel", Panel)
Shadow.Name                 = "Shadow"
Shadow.Size                 = UDim2.new(1, 30, 1, 30)
Shadow.Position             = UDim2.new(0, -15, 0, -10)
Shadow.BackgroundTransparency = 1
Shadow.Image                = "rbxassetid://6014261993"
Shadow.ImageColor3          = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency    = 0.55
Shadow.ScaleType            = Enum.ScaleType.Slice
Shadow.SliceCenter          = Rect.new(49, 49, 450, 450)
Shadow.ZIndex               = -1

local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = PURPLE_DK
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Panel
do
    local c = Instance.new("UICorner", TitleBar)
    c.CornerRadius = UDim.new(0, 14)

    local grad = Instance.new("UIGradient", TitleBar)
    grad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 45, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 15, 130)),
    })
    grad.Rotation = 90
end

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size                   = UDim2.fromOffset(28, 44)
TitleIcon.Position               = UDim2.fromOffset(12, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text                   = "⚡"
TitleIcon.Font                   = Enum.Font.GothamBold
TitleIcon.TextSize               = 17
TitleIcon.TextColor3             = Color3.fromRGB(220, 180, 255)
TitleIcon.Parent                 = TitleBar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size                   = UDim2.new(1, -90, 1, 0)
TitleLbl.Position               = UDim2.fromOffset(42, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "Speed & Jump"
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.TextSize               = 14
TitleLbl.TextColor3             = TEXT_PRI
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Parent                 = TitleBar

local WatermarkLbl = Instance.new("TextLabel")
WatermarkLbl.Size                   = UDim2.new(1, -90, 0, 14)
WatermarkLbl.Position               = UDim2.new(0, 42, 1, -16)
WatermarkLbl.BackgroundTransparency = 1
WatermarkLbl.Text                   = "By HoangLong"
WatermarkLbl.Font                   = Enum.Font.Gotham
WatermarkLbl.TextSize               = 10
WatermarkLbl.TextColor3             = Color3.fromRGB(180, 140, 255)
WatermarkLbl.TextTransparency       = 0.25
WatermarkLbl.TextXAlignment         = Enum.TextXAlignment.Left
WatermarkLbl.Parent                 = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size                   = UDim2.fromOffset(28, 28)
MinBtn.Position               = UDim2.new(1, -38, 0.5, -14)
MinBtn.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundTransparency = 0.8
MinBtn.Text                   = "–"
MinBtn.Font                   = Enum.Font.GothamBold
MinBtn.TextSize               = 16
MinBtn.TextColor3             = TEXT_PRI
MinBtn.BorderSizePixel        = 0
MinBtn.Parent                 = TitleBar
do Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0) end

MinBtn.MouseEnter:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.55 }):Play()
end)
MinBtn.MouseLeave:Connect(function()
    TweenService:Create(MinBtn, TweenInfo.new(0.12), { BackgroundTransparency = 0.8 }):Play()
end)

local IconBtn = Instance.new("ImageButton")
IconBtn.Size             = UDim2.fromOffset(48, 48)
IconBtn.Position         = Panel.Position
IconBtn.BackgroundColor3 = BG_PANEL
IconBtn.BorderSizePixel  = 0
IconBtn.Visible          = false
IconBtn.ZIndex           = 10
IconBtn.Parent           = ScreenGui
do
    local c = Instance.new("UICorner", IconBtn)
    c.CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", IconBtn)
    s.Color     = PURPLE_LT
    s.Thickness = 1.5

    local grad = Instance.new("UIGradient", IconBtn)
    grad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 16, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 24)),
    })
    grad.Rotation = 135

    local lbl = Instance.new("TextLabel", IconBtn)
    lbl.Size                   = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = "⚡"
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 22
    lbl.TextColor3             = PURPLE_LT
end

local function makeDraggable(handle, target, onDragEnd)
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = target.Position
        end
    end)

    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            if onDragEnd then onDragEnd() end
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

makeDraggable(TitleBar, Panel, function()
    IconBtn.Position = Panel.Position
end)

makeDraggable(IconBtn, IconBtn, function()
    Panel.Position = IconBtn.Position
end)

local Content = Instance.new("ScrollingFrame")
Content.Name                   = "Content"
Content.Size                   = UDim2.new(1, 0, 1, -44)
Content.Position               = UDim2.fromOffset(0, 44)
Content.BackgroundTransparency = 1
Content.BorderSizePixel        = 0
Content.ScrollBarThickness     = 3
Content.ScrollBarImageColor3   = PURPLE
Content.CanvasSize             = UDim2.fromOffset(0, 0)
Content.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Content.Parent                 = Panel

do
    local layout = Instance.new("UIListLayout", Content)
    layout.Padding             = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder           = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", Content)
    pad.PaddingTop    = UDim.new(0, 12)
    pad.PaddingLeft   = UDim.new(0, 12)
    pad.PaddingRight  = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
end

local TI_TOGGLE = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

local function makeToggle(icon, label, initState, onToggle)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 36)
    row.BackgroundColor3 = BG_ROW
    row.BorderSizePixel  = 0
    row.Parent           = Content
    do
        local c = Instance.new("UICorner", row)
        c.CornerRadius = UDim.new(0, 8)
        local pad = Instance.new("UIPadding", row)
        pad.PaddingLeft  = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
    end

    local iconLbl = Instance.new("TextLabel", row)
    iconLbl.Size                   = UDim2.fromOffset(22, 36)
    iconLbl.Position               = UDim2.fromOffset(0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                   = icon
    iconLbl.Font                   = Enum.Font.GothamBold
    iconLbl.TextSize               = 15
    iconLbl.TextColor3             = PURPLE_LT

    local lbl = Instance.new("TextLabel", row)
    lbl.Size               = UDim2.new(1, -90, 1, 0)
    lbl.Position           = UDim2.fromOffset(28, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13
    lbl.TextColor3         = TEXT_PRI
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.fromOffset(44, 22)
    track.Position         = UDim2.new(1, -44, 0.5, -11)
    track.BorderSizePixel  = 0
    track.BackgroundColor3 = initState and PURPLE or Color3.fromRGB(45, 38, 68)
    do Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0) end

    local thumb = Instance.new("Frame", track)
    thumb.Size             = UDim2.fromOffset(18, 18)
    thumb.AnchorPoint      = Vector2.new(0, 0.5)
    thumb.Position         = initState and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel  = 0
    do
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
        local s = Instance.new("UIStroke", thumb)
        s.Color       = Color3.fromRGB(180, 140, 255)
        s.Thickness   = 1
        s.Transparency = 0.6
    end

    local state  = initState
    local hitbox = Instance.new("TextButton", track)
    hitbox.Size                   = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""

    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TI_TOGGLE, {
            BackgroundColor3 = state and PURPLE or Color3.fromRGB(45, 38, 68)
        }):Play()
        TweenService:Create(thumb, TI_TOGGLE, {
            Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }):Play()
        onToggle(state)
    end)
end

local function makeSep()
    local f = Instance.new("Frame", Content)
    f.Size             = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = SEP_COL
    f.BorderSizePixel  = 0
end

local function makeSlider(icon, label, min, max, init, onChanged)
    local container = Instance.new("Frame", Content)
    container.Size                   = UDim2.new(1, 0, 0, 56)
    container.BackgroundColor3       = BG_ROW
    container.BorderSizePixel        = 0
    do
        local c = Instance.new("UICorner", container)
        c.CornerRadius = UDim.new(0, 8)
        local pad = Instance.new("UIPadding", container)
        pad.PaddingLeft  = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.PaddingTop   = UDim.new(0, 6)
    end

    local topRow = Instance.new("Frame", container)
    topRow.Size                   = UDim2.new(1, 0, 0, 20)
    topRow.BackgroundTransparency = 1

    local iconLbl = Instance.new("TextLabel", topRow)
    iconLbl.Size                   = UDim2.fromOffset(20, 20)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text                   = icon
    iconLbl.Font                   = Enum.Font.GothamBold
    iconLbl.TextSize               = 13
    iconLbl.TextColor3             = PURPLE_LT

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size               = UDim2.new(1, -68, 1, 0)
    lbl.Position           = UDim2.fromOffset(24, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = label
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 12
    lbl.TextColor3         = TEXT_SEC
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local valBox = Instance.new("TextBox", topRow)
    valBox.Size                   = UDim2.fromOffset(46, 20)
    valBox.Position               = UDim2.new(1, -46, 0, 0)
    valBox.BackgroundColor3       = Color3.fromRGB(28, 22, 50)
    valBox.BorderSizePixel        = 0
    valBox.Text                   = tostring(init)
    valBox.Font                   = Enum.Font.GothamBold
    valBox.TextSize               = 12
    valBox.TextColor3             = PURPLE_LT
    valBox.TextXAlignment         = Enum.TextXAlignment.Center
    do
        Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 5)
        local s = Instance.new("UIStroke", valBox)
        s.Color     = Color3.fromRGB(80, 50, 160)
        s.Thickness = 1
        s.Transparency = 0.5
    end

    local track = Instance.new("Frame", container)
    track.Size             = UDim2.new(1, 0, 0, 5)
    track.Position         = UDim2.new(0, 0, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(35, 28, 60)
    track.BorderSizePixel  = 0
    do Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0) end

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((init - min) / (max - min), 0, 1, 0)
    fill.BorderSizePixel  = 0
    do
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
        local grad = Instance.new("UIGradient", fill)
        grad.Color    = ColorSequence.new({
            ColorSequenceKeypoint.new(0, PURPLE),
            ColorSequenceKeypoint.new(1, PURPLE_LT),
        })
    end

    local thumb = Instance.new("Frame", track)
    thumb.Size             = UDim2.fromOffset(14, 14)
    thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    thumb.Position         = UDim2.new((init - min) / (max - min), 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 2
    do
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
        local s = Instance.new("UIStroke", thumb)
        s.Color     = PURPLE_LT
        s.Thickness = 1.5
    end

    local currentVal = init
    local sliderDrag = false

    local function applyValue(v)
        v = math.clamp(math.round(v), min, max)
        if v == currentVal then return end
        currentVal      = v
        local ratio     = (v - min) / (max - min)
        fill.Size       = UDim2.new(ratio, 0, 1, 0)
        thumb.Position  = UDim2.new(ratio, 0, 0.5, 0)
        valBox.Text     = tostring(v)
        onChanged(v)
    end

    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliderDrag = true end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliderDrag = false end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if sliderDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = math.clamp(inp.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
            applyValue(min + (relX / track.AbsoluteSize.X) * (max - min))
        end
    end)

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local relX = math.clamp(inp.Position.X - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
            applyValue(min + (relX / track.AbsoluteSize.X) * (max - min))
        end
    end)

    valBox.FocusLost:Connect(function()
        local n = tonumber(valBox.Text)
        if n then applyValue(n) else valBox.Text = tostring(currentVal) end
    end)
end

local function makeSectionLabel(text)
    local lbl = Instance.new("TextLabel", Content)
    lbl.Size                   = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = text
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 10
    lbl.TextColor3             = Color3.fromRGB(130, 100, 200)
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextTransparency       = 0.1
end

makeSectionLabel("  MOVEMENT")
makeToggle("🏃", "Tốc độ di chuyển", Config.SpeedEnabled, function(v)
    Config.SpeedEnabled = v
    if not v then resetHumanoid() end
end)
makeSlider("💨", "WalkSpeed", Config.MinSpeed, Config.MaxSpeed, Config.WalkSpeed, function(v)
    Config.WalkSpeed = v
end)

makeSep()

makeToggle("⚡", "Sprint (giữ Shift)", Config.SprintEnabled, function(v)
    Config.SprintEnabled = v
end)
makeSlider("🔥", "SprintSpeed", Config.MinSprint, Config.MaxSprint, Config.SprintSpeed, function(v)
    Config.SprintSpeed = v
end)

makeSep()

makeSectionLabel("  JUMP")
makeToggle("🦘", "Nhảy cao", Config.JumpEnabled, function(v)
    Config.JumpEnabled = v
    if not v then resetHumanoid() end
end)
makeSlider("🔼", "JumpPower", Config.MinJump, Config.MaxJump, Config.JumpPower, function(v)
    Config.JumpPower = v
end)

makeSep()

makeSectionLabel("  SPECIAL")
makeToggle("🕊️", "Bay (WASD + Space/Ctrl)", Config.FlyEnabled, function(v)
    Config.FlyEnabled = v
    if v then startFly() else stopFly() end
end)
makeSlider("🌬️", "FlySpeed", Config.MinFly, Config.MaxFly, Config.FlySpeed, function(v)
    Config.FlySpeed = v
end)

makeSep()

makeToggle("🌌", "Zero Gravity", Config.ZeroGravEnabled, function(v)
    Config.ZeroGravEnabled = v
    if v then
        prevGravity       = workspace.Gravity
        workspace.Gravity = 0
    else
        workspace.Gravity = prevGravity
    end
end)

local TI_PANEL = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Panel, TI_PANEL, { Size = UDim2.fromOffset(PANEL_W, 0) }):Play()
    task.delay(0.22, function()
        Panel.Visible   = false
        IconBtn.Position = Panel.Position
        IconBtn.Visible = true
    end)
end)

IconBtn.MouseButton1Click:Connect(function()
    Panel.Position  = IconBtn.Position
    Panel.Size      = UDim2.fromOffset(PANEL_W, 0)
    Panel.Visible   = true
    IconBtn.Visible = false
    TweenService:Create(Panel, TI_PANEL, { Size = UDim2.fromOffset(PANEL_W, PANEL_H) }):Play()
end)

print("[Speed & Jump — By HoangLong] Loaded!")
