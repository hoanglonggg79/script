-- ============================================================
--  Speed & Jump Modifier - By HoangLong
--  Tính năng: Chỉnh WalkSpeed, JumpPower, Sprint giữ Shift
--  GUI: Slider kéo được, toggle từng tính năng, có thể drag
-- ============================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer    = Players.LocalPlayer

local Config = {
    SpeedEnabled  = false,
    JumpEnabled   = false,
    SprintEnabled = false,

    WalkSpeed     = 16,
    JumpPower     = 50,
    SprintSpeed   = 50,

    MinSpeed      = 16,
    MaxSpeed      = 200,
    MinJump       = 50,
    MaxJump       = 300,
    MinSprint     = 16,
    MaxSprint     = 300,
}

local isSprinting = false

-- Giữ Shift để sprint
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = true
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = false
    end
end)

RunService.Heartbeat:Connect(function()
    local char      = LocalPlayer.Character
    local humanoid  = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- WalkSpeed
    if Config.SpeedEnabled then
        if Config.SprintEnabled and isSprinting then
            humanoid.WalkSpeed = Config.SprintSpeed
        else
            humanoid.WalkSpeed = Config.WalkSpeed
        end
    end

    -- JumpPower
    if Config.JumpEnabled then
        humanoid.JumpPower = Config.JumpPower
    end
end)

local function resetHumanoid()
    local char     = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "SpeedJump_GUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

local PANEL_W    = 240
local PANEL_H    = 420
local PANEL_SIZE = UDim2.new(0, PANEL_W, 0, PANEL_H)

local Panel = Instance.new("Frame")
Panel.Size             = PANEL_SIZE
Panel.Position         = UDim2.new(0, 14, 0.5, -PANEL_H / 2)
Panel.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Panel.Parent           = ScreenGui
do
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke", Panel)
    s.Color = Color3.fromRGB(120, 60, 255); s.Thickness = 1.5
end

local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(90, 40, 200)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Panel
do Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12) end

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size                   = UDim2.new(1, -44, 1, 0)
TitleLbl.Position               = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "⚡ Speed & Jump"
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.TextSize               = 15
TitleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.Parent                 = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size                   = UDim2.new(0, 26, 0, 26)
MinBtn.Position               = UDim2.new(1, -34, 0.5, -13)
MinBtn.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundTransparency = 0.75
MinBtn.Text                   = "–"
MinBtn.Font                   = Enum.Font.GothamBold
MinBtn.TextSize               = 18
MinBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
MinBtn.BorderSizePixel        = 0
MinBtn.Parent                 = TitleBar
do Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0) end

local IconBtn = Instance.new("ImageButton")
IconBtn.Size             = UDim2.new(0, 46, 0, 46)
IconBtn.Position         = Panel.Position
IconBtn.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
IconBtn.BorderSizePixel  = 0
IconBtn.Visible          = false
IconBtn.ZIndex           = 10
IconBtn.Parent           = ScreenGui
do
    Instance.new("UICorner", IconBtn).CornerRadius = UDim.new(1, 0)
    local s = Instance.new("UIStroke", IconBtn)
    s.Color = Color3.fromRGB(120, 60, 255); s.Thickness = 2
    local lbl = Instance.new("TextLabel", IconBtn)
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "⚡"; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 20; lbl.TextColor3 = Color3.fromRGB(180, 100, 255)
end

-- Drag panel
do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = Panel.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            IconBtn.Position = Panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            Panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local Content = Instance.new("Frame")
Content.Size                   = UDim2.new(1, 0, 1, -44)
Content.Position               = UDim2.new(0, 0, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent                 = Panel
do
    local layout = Instance.new("UIListLayout", Content)
    layout.Padding             = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pad = Instance.new("UIPadding", Content)
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingLeft   = UDim.new(0, 14)
    pad.PaddingRight  = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 10)
end

-- Toggle switch
local function makeToggle(icon, label, initState, onToggle)
    local row = Instance.new("Frame")
    row.Size                   = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent                 = Content

    local lbl = Instance.new("TextLabel", row)
    lbl.Size               = UDim2.new(1, -54, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = icon .. "  " .. label
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13
    lbl.TextColor3         = Color3.fromRGB(210, 210, 225)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", row)
    track.Size             = UDim2.new(0, 44, 0, 22)
    track.Position         = UDim2.new(1, -44, 0.5, -11)
    track.BorderSizePixel  = 0
    track.BackgroundColor3 = initState and Color3.fromRGB(120, 60, 255) or Color3.fromRGB(60, 60, 80)
    do Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0) end

    local thumb = Instance.new("Frame", track)
    thumb.Size             = UDim2.new(0, 18, 0, 18)
    thumb.AnchorPoint      = Vector2.new(0, 0.5)
    thumb.Position         = initState and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel  = 0
    do Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0) end

    local state    = initState
    local ti       = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    local hitbox   = Instance.new("TextButton", track)
    hitbox.Size                   = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""

    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, ti, {
            BackgroundColor3 = state and Color3.fromRGB(120, 60, 255) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(thumb, ti, {
            Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }):Play()
        onToggle(state)
    end)
end

-- Separator
local function makeSep()
    local f = Instance.new("Frame", Content)
    f.Size             = UDim2.new(1, 0, 0, 1)
    f.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
    f.BorderSizePixel  = 0
end

local function makeSlider(icon, label, min, max, init, onChanged)
    local TRACK_W = PANEL_W - 28 - 28   -- padding trái phải

    local container = Instance.new("Frame", Content)
    container.Size                   = UDim2.new(1, 0, 0, 52)
    container.BackgroundTransparency = 1

    -- Label + value
    local topRow = Instance.new("Frame", container)
    topRow.Size                   = UDim2.new(1, 0, 0, 20)
    topRow.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", topRow)
    lbl.Size               = UDim2.new(1, -46, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = icon .. "  " .. label
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 12
    lbl.TextColor3         = Color3.fromRGB(190, 190, 210)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left

    local valBox = Instance.new("TextBox", topRow)
    valBox.Size                   = UDim2.new(0, 44, 1, 0)
    valBox.Position               = UDim2.new(1, -44, 0, 0)
    valBox.BackgroundColor3       = Color3.fromRGB(30, 25, 50)
    valBox.BorderSizePixel        = 0
    valBox.Text                   = tostring(init)
    valBox.Font                   = Enum.Font.GothamBold
    valBox.TextSize               = 12
    valBox.TextColor3             = Color3.fromRGB(200, 160, 255)
    valBox.TextXAlignment         = Enum.TextXAlignment.Center
    do Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 5) end

    -- Track + fill + thumb
    local track = Instance.new("Frame", container)
    track.Size             = UDim2.new(1, 0, 0, 6)
    track.Position         = UDim2.new(0, 0, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(45, 35, 75)
    track.BorderSizePixel  = 0
    do Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0) end

    local fill = Instance.new("Frame", track)
    fill.Size             = UDim2.new((init - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(120, 60, 255)
    fill.BorderSizePixel  = 0
    do Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0) end

    local thumb = Instance.new("Frame", track)
    thumb.Size             = UDim2.new(0, 14, 0, 14)
    thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
    thumb.Position         = UDim2.new((init - min) / (max - min), 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(200, 160, 255)
    thumb.BorderSizePixel  = 0
    thumb.ZIndex           = 2
    do Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0) end

    local currentVal = init
    local dragging   = false

    local function applyValue(v)
        v = math.clamp(math.round(v), min, max)
        if v == currentVal then return end
        currentVal = v
        local ratio = (v - min) / (max - min)
        fill.Size     = UDim2.new(ratio, 0, 1, 0)
        thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
        valBox.Text   = tostring(v)
        onChanged(v)
    end

    -- Kéo thumb
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local abs     = track.AbsolutePosition
            local width   = track.AbsoluteSize.X
            local relX    = math.clamp(inp.Position.X - abs.X, 0, width)
            local ratio   = relX / width
            applyValue(min + ratio * (max - min))
        end
    end)

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local abs   = track.AbsolutePosition
            local width = track.AbsoluteSize.X
            local relX  = math.clamp(inp.Position.X - abs.X, 0, width)
            applyValue(min + (relX / width) * (max - min))
        end
    end)

    valBox.FocusLost:Connect(function(enterPressed)
        local n = tonumber(valBox.Text)
        if n then
            applyValue(n)
        else
            valBox.Text = tostring(currentVal)
        end
    end)
end

makeToggle("🏃", "Tốc độ di chuyển", Config.SpeedEnabled, function(v)
    Config.SpeedEnabled = v
    if not v then resetHumanoid() end
end)
makeSlider("💨", "WalkSpeed", Config.MinSpeed, Config.MaxSpeed, Config.WalkSpeed, function(v)
    Config.WalkSpeed = v
end)

makeSep()

makeToggle("🦘", "Nhảy cao", Config.JumpEnabled, function(v)
    Config.JumpEnabled = v
    if not v then resetHumanoid() end
end)
makeSlider("🔼", "JumpPower", Config.MinJump, Config.MaxJump, Config.JumpPower, function(v)
    Config.JumpPower = v
end)

makeSep()

makeToggle("⚡", "Sprint (giữ Shift)", Config.SprintEnabled, function(v)
    Config.SprintEnabled = v
end)
makeSlider("🔥", "SprintSpeed", Config.MinSprint, Config.MaxSprint, Config.SprintSpeed, function(v)
    Config.SprintSpeed = v
end)

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, PANEL_W, 0, 0)
    }):Play()
    task.delay(0.22, function()
        Panel.Visible   = false
        IconBtn.Visible = true
    end)
end)

IconBtn.MouseButton1Click:Connect(function()
    Panel.Size    = UDim2.new(0, PANEL_W, 0, 0)
    Panel.Visible = true
    IconBtn.Visible = false
    TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
        Size = PANEL_SIZE
    }):Play()
end)

print("[Speed & Jump By HoangLong] Load xong! Chỉnh slider rồi bật toggle nhé.")
