-- ============================================================
--  ESP Script - By HoangLong
--  Tính năng: Box, Name, Distance, Health Bar, Skeleton, Line ESP
--  Tối ưu: bone cache, throttle, early return
--  GUI: Toggle thu nhỏ, toggle riêng từng tính năng
-- ============================================================
-- LƯU Ý: ESP chỉ đọc dữ liệu (read-only), không chỉnh sửa file game.
-- Cách chặn hiệu quả nhất là Fog of War phía server.
-- ============================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera         = workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer

local Config = {
    Enabled       = false,
    ShowBox       = true,
    ShowName      = true,
    ShowDistance  = true,
    ShowHealthBar = true,
    ShowSkeleton  = true,
    ShowLine      = true,
    UseTeamColor  = true,
    EnemyColor    = Color3.fromRGB(255, 70, 70),
    TeamColor     = Color3.fromRGB(0, 230, 110),
    LineColor     = Color3.fromRGB(255, 255, 255),
    LineOrigin    = "Bottom",
    MaxDistance   = 500,
    UpdateInterval = 0,
}

local SKELETON_CONNECTIONS = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"},
}

local UNIQUE_BONES = {}
do
    local seen = {}
    for _, conn in ipairs(SKELETON_CONNECTIONS) do
        for _, boneName in ipairs(conn) do
            if not seen[boneName] then
                seen[boneName] = true
                table.insert(UNIQUE_BONES, boneName)
            end
        end
    end
end

local HALF_FOV_TAN = math.tan(math.rad(Camera.FieldOfView / 2)) * 2
Camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    HALF_FOV_TAN = math.tan(math.rad(Camera.FieldOfView / 2)) * 2
end)

local function newDrawing(drawType, props)
    local d = Drawing.new(drawType)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local playerColorCache = {}
Players.PlayerAdded:Connect(function(p)
    playerColorCache[p] = nil
end)
Players.PlayerRemoving:Connect(function(p)
    playerColorCache[p] = nil
end)

local function getPlayerColor(player)
    if Config.UseTeamColor and player.Team then
        return player.Team.TeamColor.Color
    end
    if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return Config.TeamColor
    end
    return Config.EnemyColor
end

local function getLineOrigin(vpSize)
    if Config.LineOrigin == "Top" then
        return Vector2.new(vpSize.X / 2, 0)
    elseif Config.LineOrigin == "Center" then
        return Vector2.new(vpSize.X / 2, vpSize.Y / 2)
    else
        return Vector2.new(vpSize.X / 2, vpSize.Y)
    end
end

local espObjects = {}
local lastUpdate = {}

local function hideAll(esp)
    esp.BoxOutline.Visible  = false
    esp.Box.Visible         = false
    esp.Name.Visible        = false
    esp.Distance.Visible    = false
    esp.HealthBG.Visible    = false
    esp.HealthBar.Visible   = false
    esp.LineOutline.Visible = false
    esp.Line.Visible        = false
    for _, line in ipairs(esp.Skeleton) do
        line.Visible = false
    end
end

local function removeESPFor(player)
    if not espObjects[player] then return end
    local esp = espObjects[player]
    local function safeRemove(obj)
        pcall(obj.Remove, obj)
    end
    safeRemove(esp.BoxOutline)
    safeRemove(esp.Box)
    safeRemove(esp.Name)
    safeRemove(esp.Distance)
    safeRemove(esp.HealthBG)
    safeRemove(esp.HealthBar)
    safeRemove(esp.LineOutline)
    safeRemove(esp.Line)
    for _, line in ipairs(esp.Skeleton) do
        safeRemove(line)
    end
    espObjects[player] = nil
    lastUpdate[player] = nil
end

local function clearAllESP()
    for player in pairs(espObjects) do
        removeESPFor(player)
    end
end

local function createESPFor(player, color)
    local skelLines = {}
    for i = 1, #SKELETON_CONNECTIONS do
        skelLines[i] = newDrawing("Line", {
            Color = color, Thickness = 1,
            Visible = false, Transparency = 0.25,
        })
    end
    return {
        BoxOutline = newDrawing("Square", {
            Color = Color3.fromRGB(0,0,0), Thickness = 4,
            Filled = false, Visible = false,
        }),
        Box = newDrawing("Square", {
            Color = color, Thickness = 2,
            Filled = false, Visible = false,
        }),
        Name = newDrawing("Text", {
            Text = player.Name, Color = Color3.fromRGB(255,255,255),
            Size = 13, Center = true, Outline = true, Visible = false,
        }),
        Distance = newDrawing("Text", {
            Text = "0m", Color = Color3.fromRGB(180,180,200),
            Size = 11, Center = true, Outline = true, Visible = false,
        }),
        HealthBG = newDrawing("Square", {
            Color = Color3.fromRGB(0,0,0), Thickness = 1,
            Filled = true, Visible = false,
        }),
        HealthBar = newDrawing("Square", {
            Color = Color3.fromRGB(0,230,100), Thickness = 1,
            Filled = true, Visible = false,
        }),
        LineOutline = newDrawing("Line", {
            Color = Color3.fromRGB(0,0,0), Thickness = 3, Visible = false,
        }),
        Line = newDrawing("Line", {
            Color = color, Thickness = 1.5, Visible = false,
        }),
        Skeleton = skelLines,
    }
end

local function updateESPFor(player)
    local now = tick()
    if Config.UpdateInterval > 0 then
        local last = lastUpdate[player]
        if last and (now - last) < Config.UpdateInterval then return end
    end
    lastUpdate[player] = now

    local char = player.Character
    if not char then
        if espObjects[player] then hideAll(espObjects[player]) end
        return
    end

    local root     = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid or humanoid.Health <= 0 then
        if espObjects[player] then hideAll(espObjects[player]) end
        return
    end

    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        if espObjects[player] then hideAll(espObjects[player]) end
        return
    end

    local dist = math.floor((localRoot.Position - root.Position).Magnitude)
    if dist > Config.MaxDistance then
        if espObjects[player] then hideAll(espObjects[player]) end
        return
    end

    local rootPos = root.Position
    local vec, onScreen = Camera:WorldToViewportPoint(rootPos)
    local color = getPlayerColor(player)

    if not espObjects[player] then
        espObjects[player] = createESPFor(player, color)
    end

    local esp    = espObjects[player]
    local vpSize = Camera.ViewportSize

    local scaleFactor = 1 / (vec.Z * HALF_FOV_TAN) * vpSize.Y
    local boxH = scaleFactor * 6.2
    local boxW = boxH * 0.55
    local boxX = vec.X - boxW * 0.5
    local boxY = vec.Y - boxH * 0.5

    local showBox = Config.ShowBox and onScreen
    esp.BoxOutline.Position = Vector2.new(boxX - 1, boxY - 1)
    esp.BoxOutline.Size     = Vector2.new(boxW + 2, boxH + 2)
    esp.BoxOutline.Visible  = showBox
    esp.Box.Position        = Vector2.new(boxX, boxY)
    esp.Box.Size            = Vector2.new(boxW, boxH)
    esp.Box.Color           = color
    esp.Box.Visible         = showBox

    esp.Name.Text     = player.Name
    esp.Name.Position = Vector2.new(vec.X, boxY - 16)
    esp.Name.Visible  = Config.ShowName and onScreen

    esp.Distance.Text     = dist .. "m"
    esp.Distance.Position = Vector2.new(vec.X, boxY + boxH + 2)
    esp.Distance.Visible  = Config.ShowDistance and onScreen

    local showHP     = Config.ShowHealthBar and onScreen
    local hpRatio    = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local barW       = 4
    local barX       = boxX - barW - 3
    local barFilledH = boxH * hpRatio

    local hpColor
    if hpRatio > 0.5 then
        hpColor = Color3.fromRGB(math.floor(255 * (1 - hpRatio) * 2), 255, 0)
    else
        hpColor = Color3.fromRGB(255, math.floor(255 * hpRatio * 2), 0)
    end

    esp.HealthBG.Position = Vector2.new(barX, boxY)
    esp.HealthBG.Size     = Vector2.new(barW, boxH)
    esp.HealthBG.Visible  = showHP

    esp.HealthBar.Color    = hpColor
    esp.HealthBar.Position = Vector2.new(barX, boxY + boxH - barFilledH)
    esp.HealthBar.Size     = Vector2.new(barW, barFilledH)
    esp.HealthBar.Visible  = showHP

    if Config.ShowLine and onScreen then
        local origin = getLineOrigin(vpSize)
        local target = Vector2.new(vec.X, boxY + boxH)
        esp.LineOutline.From    = origin
        esp.LineOutline.To      = target
        esp.LineOutline.Visible = true
        esp.Line.From    = origin
        esp.Line.To      = target
        esp.Line.Color   = Config.UseTeamColor and color or Config.LineColor
        esp.Line.Visible = true
    else
        esp.LineOutline.Visible = false
        esp.Line.Visible        = false
    end

    if Config.ShowSkeleton and onScreen then
        local boneCache = {}
        for _, boneName in ipairs(UNIQUE_BONES) do
            local part = char:FindFirstChild(boneName)
            if part then
                local bv, bon = Camera:WorldToViewportPoint(part.Position)
                boneCache[boneName] = {bv.X, bv.Y, bon}
            end
        end
        for i, conn in ipairs(SKELETON_CONNECTIONS) do
            local line = esp.Skeleton[i]
            local b0   = boneCache[conn[1]]
            local b1   = boneCache[conn[2]]
            if b0 and b1 and (b0[3] or b1[3]) then
                line.From    = Vector2.new(b0[1], b0[2])
                line.To      = Vector2.new(b1[1], b1[2])
                line.Color   = color
                line.Visible = true
            else
                line.Visible = false
            end
        end
    else
        for _, line in ipairs(esp.Skeleton) do
            line.Visible = false
        end
    end
end

local espConnection

local function startESPLoop()
    if espConnection then return end
    espConnection = RunService.RenderStepped:Connect(function()
        if not Config.Enabled then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                updateESPFor(p)
            end
        end
    end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ESP_GUI_HL"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

local ACCENT   = Color3.fromRGB(80, 160, 255)
local ACCENT2  = Color3.fromRGB(50, 110, 220)
local BG_DEEP  = Color3.fromRGB(10, 10, 18)
local BG_MID   = Color3.fromRGB(18, 18, 30)
local BG_ROW   = Color3.fromRGB(24, 24, 40)
local SEP_COL  = Color3.fromRGB(38, 38, 60)
local TEXT_PRI = Color3.fromRGB(230, 232, 255)
local TEXT_SEC = Color3.fromRGB(130, 135, 170)
local TOGGLE_OFF = Color3.fromRGB(45, 45, 68)
local TOGGLE_ON  = Color3.fromRGB(60, 130, 255)

local PANEL_W  = 230
local PANEL_H  = 358
local PANEL_SIZE = UDim2.new(0, PANEL_W, 0, PANEL_H)

local function makeDraggable(handle, target)
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
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local IconBtn = Instance.new("Frame")
IconBtn.Size             = UDim2.new(0, 50, 0, 50)
IconBtn.Position         = UDim2.new(0, 16, 0, 16)
IconBtn.BackgroundColor3 = BG_DEEP
IconBtn.BorderSizePixel  = 0
IconBtn.Visible          = false
IconBtn.ZIndex           = 10
IconBtn.Parent           = ScreenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = IconBtn
    local s = Instance.new("UIStroke"); s.Color = ACCENT; s.Thickness = 1.5; s.Parent = IconBtn

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -10, 0, 5)
    dot.BackgroundColor3 = Color3.fromRGB(100, 255, 130)
    dot.BorderSizePixel = 0
    dot.ZIndex = 12
    dot.Parent = IconBtn
    do local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1,0); dc.Parent = dot end

    local lbl = Instance.new("TextButton")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "ESP"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.TextColor3 = ACCENT
    lbl.ZIndex = 11
    lbl.Parent = IconBtn

    lbl.MouseButton1Click:Connect(function()
        local Panel = ScreenGui:FindFirstChild("ESP_Panel")
        if not Panel then return end
        Panel.Size    = UDim2.new(0, PANEL_W, 0, 0)
        Panel.Position = IconBtn.Position
        Panel.Visible = true
        IconBtn.Visible = false
        TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = PANEL_SIZE,
        }):Play()
    end)
end
makeDraggable(IconBtn, IconBtn)

local Panel = Instance.new("Frame")
Panel.Name             = "ESP_Panel"
Panel.Size             = PANEL_SIZE
Panel.Position         = UDim2.new(0, 16, 0, 16)
Panel.BackgroundColor3 = BG_DEEP
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Panel.Parent           = ScreenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = Panel
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(55,60,100); s.Thickness = 1; s.Parent = Panel
end

local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = BG_MID
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Panel
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = TitleBar
    local fix = Instance.new("Frame")
    fix.Size = UDim2.new(1,0,0,12); fix.Position = UDim2.new(0,0,1,-12)
    fix.BackgroundColor3 = BG_MID; fix.BorderSizePixel = 0; fix.Parent = TitleBar

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 20)
    accent.Position = UDim2.new(0, 14, 0.5, -10)
    accent.BackgroundColor3 = ACCENT
    accent.BorderSizePixel = 0
    accent.Parent = TitleBar
    do local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(1,0); ac.Parent = accent end

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size               = UDim2.new(1, -52, 1, 0)
    TitleLbl.Position           = UDim2.new(0, 24, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text               = "ESP"
    TitleLbl.Font               = Enum.Font.GothamBold
    TitleLbl.TextSize           = 15
    TitleLbl.TextColor3         = TEXT_PRI
    TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    TitleLbl.Parent             = TitleBar

    local SubLbl = Instance.new("TextLabel")
    SubLbl.Size               = UDim2.new(0, 100, 0, 14)
    SubLbl.Position           = UDim2.new(0, 24, 0, 22)
    SubLbl.BackgroundTransparency = 1
    SubLbl.Text               = "by HoangLong"
    SubLbl.Font               = Enum.Font.Gotham
    SubLbl.TextSize           = 10
    SubLbl.TextColor3         = TEXT_SEC
    SubLbl.TextXAlignment     = Enum.TextXAlignment.Left
    SubLbl.Parent             = TitleBar

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size             = UDim2.new(0, 24, 0, 24)
    MinBtn.Position         = UDim2.new(1, -36, 0.5, -12)
    MinBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 80)
    MinBtn.Text             = "—"
    MinBtn.Font             = Enum.Font.GothamBold
    MinBtn.TextSize         = 12
    MinBtn.TextColor3       = TEXT_SEC
    MinBtn.BorderSizePixel  = 0
    MinBtn.Parent           = TitleBar
    do local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(1,0); mc.Parent = MinBtn end

    MinBtn.MouseEnter:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70,72,110)}):Play()
    end)
    MinBtn.MouseLeave:Connect(function()
        TweenService:Create(MinBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(50,52,80)}):Play()
    end)
    MinBtn.MouseButton1Click:Connect(function()
        TweenService:Create(Panel, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, PANEL_W, 0, 0)
        }):Play()
        task.delay(0.22, function()
            Panel.Visible   = false
            IconBtn.Position = Panel.Position
            IconBtn.Visible = true
        end)
    end)
end

makeDraggable(TitleBar, Panel)

local Content = Instance.new("Frame")
Content.Size                = UDim2.new(1, 0, 1, -46)
Content.Position            = UDim2.new(0, 0, 0, 46)
Content.BackgroundTransparency = 1
Content.Parent              = Panel
do
    local layout = Instance.new("UIListLayout")
    layout.Padding             = UDim.new(0, 4)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder           = Enum.SortOrder.LayoutOrder
    layout.Parent              = Content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop   = UDim.new(0, 8)
    pad.PaddingLeft  = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent       = Content
end

local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

local MainBtn = Instance.new("TextButton")
MainBtn.Size             = UDim2.new(1, 0, 0, 36)
MainBtn.BackgroundColor3 = ACCENT2
MainBtn.Text             = "BẬT ESP"
MainBtn.Font             = Enum.Font.GothamBold
MainBtn.TextSize         = 14
MainBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
MainBtn.BorderSizePixel  = 0
MainBtn.LayoutOrder      = 0
MainBtn.Parent           = Content
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = MainBtn
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80,150,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40,90,210)),
    }
    g.Rotation = 90
    g.Parent = MainBtn
end

local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, 0, 0, 1)
Sep.BackgroundColor3 = SEP_COL
Sep.BorderSizePixel  = 0
Sep.LayoutOrder      = 1
Sep.Parent           = Content

local function makeToggle(labelText, default, callback, order)
    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3    = BG_ROW
    row.BorderSizePixel     = 0
    row.LayoutOrder         = order
    row.Parent              = Content
    do
        local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row
        local rp = Instance.new("UIPadding")
        rp.PaddingLeft = UDim.new(0,10); rp.PaddingRight = UDim.new(0,10); rp.Parent = row
    end

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -52, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 12
    lbl.TextColor3         = TEXT_PRI
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 36, 0, 18)
    track.Position         = UDim2.new(1, -36, 0.5, -9)
    track.BorderSizePixel  = 0
    track.BackgroundColor3 = default and TOGGLE_ON or TOGGLE_OFF
    track.Parent           = row
    do local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = track end

    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, 14, 0, 14)
    thumb.AnchorPoint      = Vector2.new(0, 0.5)
    thumb.Position         = default and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255)
    thumb.BorderSizePixel  = 0
    thumb.Parent           = track
    do local thc = Instance.new("UICorner"); thc.CornerRadius = UDim.new(1,0); thc.Parent = thumb end

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.Parent              = row

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, tweenInfo, {
            BackgroundColor3 = state and TOGGLE_ON or TOGGLE_OFF
        }):Play()
        TweenService:Create(thumb, tweenInfo, {
            Position = state and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0)
        }):Play()
        callback(state)
    end)
end

makeToggle("Box",         Config.ShowBox,       function(v) Config.ShowBox       = v end, 2)
makeToggle("Tên",         Config.ShowName,      function(v) Config.ShowName      = v end, 3)
makeToggle("Khoảng cách", Config.ShowDistance,  function(v) Config.ShowDistance  = v end, 4)
makeToggle("Thanh Máu",   Config.ShowHealthBar, function(v) Config.ShowHealthBar = v end, 5)
makeToggle("Skeleton",    Config.ShowSkeleton,  function(v) Config.ShowSkeleton  = v end, 6)
makeToggle("Line ESP",    Config.ShowLine,      function(v) Config.ShowLine      = v end, 7)
makeToggle("Màu Team",    Config.UseTeamColor,  function(v) Config.UseTeamColor  = v end, 8)

local WatermarkFrame = Instance.new("Frame")
WatermarkFrame.Size             = UDim2.new(1, 0, 0, 20)
WatermarkFrame.BackgroundTransparency = 1
WatermarkFrame.LayoutOrder      = 9
WatermarkFrame.Parent           = Content
do
    local wlbl = Instance.new("TextLabel")
    wlbl.Size = UDim2.new(1,0,1,0)
    wlbl.BackgroundTransparency = 1
    wlbl.Text = "By HoangLong"
    wlbl.Font = Enum.Font.Gotham
    wlbl.TextSize = 10
    wlbl.TextColor3 = TEXT_SEC
    wlbl.TextXAlignment = Enum.TextXAlignment.Center
    wlbl.Parent = wlbl.Parent or WatermarkFrame
    wlbl.Parent = WatermarkFrame
end

MainBtn.MouseEnter:Connect(function()
    if not Config.Enabled then
        TweenService:Create(MainBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(90,165,255)}):Play()
    end
end)
MainBtn.MouseLeave:Connect(function()
    if not Config.Enabled then
        TweenService:Create(MainBtn, TweenInfo.new(0.12), {BackgroundColor3 = ACCENT2}):Play()
    end
end)

MainBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    if Config.Enabled then
        MainBtn.Text = "TẮT ESP"
        TweenService:Create(MainBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = Color3.fromRGB(180, 45, 55),
        }):Play()
        local g = MainBtn:FindFirstChildOfClass("UIGradient")
        if g then
            g.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(220,60,70)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(160,30,40)),
            }
        end
        startESPLoop()
    else
        MainBtn.Text = "BẬT ESP"
        TweenService:Create(MainBtn, TweenInfo.new(0.18), {
            BackgroundColor3 = ACCENT2,
        }):Play()
        local g = MainBtn:FindFirstChildOfClass("UIGradient")
        if g then
            g.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(80,150,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(40,90,210)),
            }
        end
        clearAllESP()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPFor(player)
end)

startESPLoop()

print("[ESP] By HoangLong — Ready.")
