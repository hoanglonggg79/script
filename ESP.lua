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
local Camera         = workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer

local Config = {
    Enabled       = false,

    -- Tính năng
    ShowBox       = true,
    ShowName      = true,
    ShowDistance  = true,
    ShowHealthBar = true,
    ShowSkeleton  = true,
    ShowLine      = true,
    UseTeamColor  = true,

    EnemyColor    = Color3.fromRGB(255, 80,  80),
    TeamColor     = Color3.fromRGB(0,   255, 120),
    LineColor     = Color3.fromRGB(255, 255, 255),

    -- Điểm gốc của Line ESP: "Bottom" | "Center" | "Top"
    LineOrigin    = "Bottom",

    MaxDistance   = 500,

    UpdateInterval = 0,
}

local SKELETON_CONNECTIONS = {
    { "Head",         "UpperTorso"    },
    { "UpperTorso",   "LowerTorso"    },
    { "UpperTorso",   "LeftUpperArm"  },
    { "LeftUpperArm", "LeftLowerArm"  },
    { "LeftLowerArm", "LeftHand"      },
    { "UpperTorso",   "RightUpperArm" },
    { "RightUpperArm","RightLowerArm" },
    { "RightLowerArm","RightHand"     },
    { "LowerTorso",   "LeftUpperLeg"  },
    { "LeftUpperLeg", "LeftLowerLeg"  },
    { "LeftLowerLeg", "LeftFoot"      },
    { "LowerTorso",   "RightUpperLeg" },
    { "RightUpperLeg","RightLowerLeg" },
    { "RightLowerLeg","RightFoot"     },
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

local function newDrawing(drawType, props)
    local d = Drawing.new(drawType)
    for k, v in pairs(props) do d[k] = v end
    return d
end

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
    else -- "Bottom" (default)
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
        pcall(function() obj:Remove() end)
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
            Color        = color,
            Thickness    = 1,
            Visible      = false,
            Transparency = 0.2,
        })
    end

    return {
        BoxOutline = newDrawing("Square", {
            Color           = Color3.fromRGB(0, 0, 0),
            Thickness       = 4,
            Filled          = false,
            Visible         = false,
        }),
        Box = newDrawing("Square", {
            Color           = color,
            Thickness       = 2,
            Filled          = false,
            Visible         = false,
        }),
        Name = newDrawing("Text", {
            Text            = player.Name,
            Color           = Color3.fromRGB(255, 255, 255),
            Size            = 13,
            Center          = true,
            Outline         = true,
            Visible         = false,
        }),
        Distance = newDrawing("Text", {
            Text            = "0m",
            Color           = Color3.fromRGB(200, 200, 200),
            Size            = 11,
            Center          = true,
            Outline         = true,
            Visible         = false,
        }),
        HealthBG = newDrawing("Square", {
            Color           = Color3.fromRGB(0, 0, 0),
            Thickness       = 1,
            Filled          = true,
            Visible         = false,
        }),
        HealthBar = newDrawing("Square", {
            Color           = Color3.fromRGB(0, 255, 100),
            Thickness       = 1,
            Filled          = true,
            Visible         = false,
        }),
        LineOutline = newDrawing("Line", {
            Color           = Color3.fromRGB(0, 0, 0),
            Thickness       = 3,
            Visible         = false,
        }),
        Line = newDrawing("Line", {
            Color           = color,
            Thickness       = 1.5,
            Visible         = false,
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
    local dist = localRoot
        and math.floor((localRoot.Position - root.Position).Magnitude)
        or 0

    if dist > Config.MaxDistance then
        if espObjects[player] then hideAll(espObjects[player]) end
        return
    end

    local vec, onScreen = Camera:WorldToViewportPoint(root.Position)
    local color = getPlayerColor(player)

    if not espObjects[player] then
        espObjects[player] = createESPFor(player, color)
    end

    local esp    = espObjects[player]
    local vpSize = Camera.ViewportSize

    local scaleFactor = 1 / (vec.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * vpSize.Y
    local boxH = scaleFactor * 6.2
    local boxW = boxH * 0.55
    local boxX = vec.X - boxW / 2
    local boxY = vec.Y - boxH / 2

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
    local barFullH   = boxH
    local barFilledH = barFullH * hpRatio

    local hpColor
    if hpRatio > 0.5 then
        hpColor = Color3.fromRGB(math.floor(255 * (1 - hpRatio) * 2), 255, 0)
    else
        hpColor = Color3.fromRGB(255, math.floor(255 * hpRatio * 2), 0)
    end

    esp.HealthBG.Position = Vector2.new(barX, boxY)
    esp.HealthBG.Size     = Vector2.new(barW, barFullH)
    esp.HealthBG.Visible  = showHP

    esp.HealthBar.Color    = hpColor
    esp.HealthBar.Position = Vector2.new(barX, boxY + barFullH - barFilledH)
    esp.HealthBar.Size     = Vector2.new(barW, barFilledH)
    esp.HealthBar.Visible  = showHP

    local showLine = Config.ShowLine and onScreen
    if showLine then
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
                boneCache[boneName] = { pos = bv, onScreen = bon }
            end
        end

        for i, conn in ipairs(SKELETON_CONNECTIONS) do
            local line = esp.Skeleton[i]
            local b0   = boneCache[conn[1]]
            local b1   = boneCache[conn[2]]

            if b0 and b1 and (b0.onScreen or b1.onScreen) then
                line.From    = Vector2.new(b0.pos.X, b0.pos.Y)
                line.To      = Vector2.new(b1.pos.X, b1.pos.Y)
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
ScreenGui.Name           = "ESP_GUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

local IconBtn = Instance.new("ImageButton")
IconBtn.Size             = UDim2.new(0, 46, 0, 46)
IconBtn.Position         = UDim2.new(0, 14, 0, 14)
IconBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
IconBtn.BorderSizePixel  = 0
IconBtn.Visible          = false
IconBtn.ZIndex           = 10
IconBtn.Parent           = ScreenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = IconBtn
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(0, 200, 255); s.Thickness = 2; s.Parent = IconBtn
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Text = "ESP"; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13; lbl.TextColor3 = Color3.fromRGB(0, 200, 255)
    lbl.Parent = IconBtn
end

local PANEL_SIZE = UDim2.new(0, 220, 0, 345)

local Panel = Instance.new("Frame")
Panel.Size             = PANEL_SIZE
Panel.Position         = UDim2.new(0, 14, 0, 14)
Panel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
Panel.BorderSizePixel  = 0
Panel.ClipsDescendants = true
Panel.Parent           = ScreenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = Panel
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(0, 180, 255); s.Thickness = 1.5; s.Parent = Panel
end

local TitleBar = Instance.new("Frame")
TitleBar.Size             = UDim2.new(1, 0, 0, 38)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 140, 210)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = Panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = TitleBar end

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size               = UDim2.new(1, -44, 1, 0)
TitleLbl.Position           = UDim2.new(0, 10, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "✦ ESP by HoangLong"
TitleLbl.Font               = Enum.Font.GothamBold
TitleLbl.TextSize           = 15
TitleLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment     = Enum.TextXAlignment.Left
TitleLbl.Parent             = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 26, 0, 26)
MinBtn.Position         = UDim2.new(1, -32, 0.5, -13)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundTransparency = 0.8
MinBtn.Text             = "–"
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.TextSize         = 18
MinBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
MinBtn.BorderSizePixel  = 0
MinBtn.Parent           = TitleBar
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = MinBtn end

do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = Panel.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            Panel.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local Content = Instance.new("Frame")
Content.Size                = UDim2.new(1, 0, 1, -42)
Content.Position            = UDim2.new(0, 0, 0, 42)
Content.BackgroundTransparency = 1
Content.Parent              = Panel
do
    local layout = Instance.new("UIListLayout")
    layout.Padding             = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent              = Content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop   = UDim.new(0, 8)
    pad.PaddingLeft  = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent       = Content
end

local function makeToggle(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size                = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent              = Content

    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(1, -54, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = labelText
    lbl.Font               = Enum.Font.Gotham
    lbl.TextSize           = 13
    lbl.TextColor3         = Color3.fromRGB(210, 210, 220)
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.Parent             = row

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 44, 0, 22)
    track.Position         = UDim2.new(1, -44, 0.5, -11)
    track.BorderSizePixel  = 0
    track.BackgroundColor3 = default and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(70, 70, 90)
    track.Parent           = row
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = track end

    local thumb = Instance.new("Frame")
    thumb.Size             = UDim2.new(0, 18, 0, 18)
    thumb.AnchorPoint      = Vector2.new(0, 0.5)
    thumb.Position         = default and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel  = 0
    thumb.Parent           = track
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = thumb end

    local state    = default
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                = ""
    btn.Parent              = track

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, tweenInfo, {
            BackgroundColor3 = state and Color3.fromRGB(0, 160, 255) or Color3.fromRGB(70, 70, 90)
        }):Play()
        TweenService:Create(thumb, tweenInfo, {
            Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        }):Play()
        callback(state)
    end)
end

local MainBtn = Instance.new("TextButton")
MainBtn.Size             = UDim2.new(1, 0, 0, 38)
MainBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
MainBtn.Text             = "BẬT ESP"
MainBtn.Font             = Enum.Font.GothamBold
MainBtn.TextSize         = 15
MainBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
MainBtn.BorderSizePixel  = 0
MainBtn.Parent           = Content
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = MainBtn end

local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, 0, 0, 1)
Sep.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
Sep.BorderSizePixel  = 0
Sep.Parent           = Content

makeToggle("📦  Hiện Box",          Config.ShowBox,       function(v) Config.ShowBox       = v end)
makeToggle("🏷️  Hiện Tên",           Config.ShowName,      function(v) Config.ShowName      = v end)
makeToggle("📏  Khoảng cách",        Config.ShowDistance,  function(v) Config.ShowDistance  = v end)
makeToggle("❤️  Thanh Máu",          Config.ShowHealthBar, function(v) Config.ShowHealthBar = v end)
makeToggle("💀  Skeleton",           Config.ShowSkeleton,  function(v) Config.ShowSkeleton  = v end)
makeToggle("📍  Line ESP",           Config.ShowLine,      function(v) Config.ShowLine      = v end)
makeToggle("🎨  Màu Team",           Config.UseTeamColor,  function(v) Config.UseTeamColor  = v end)

MainBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    if Config.Enabled then
        MainBtn.Text = "TẮT ESP"
        TweenService:Create(MainBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        }):Play()
        startESPLoop()
    else
        MainBtn.Text = "BẬT ESP"
        TweenService:Create(MainBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(0, 120, 200)
        }):Play()
        clearAllESP()
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 220, 0, 0)
    }):Play()
    task.delay(0.25, function()
        Panel.Visible   = false
        IconBtn.Visible = true
    end)
end)

IconBtn.MouseButton1Click:Connect(function()
    Panel.Size    = UDim2.new(0, 220, 0, 0)
    Panel.Visible = true
    IconBtn.Visible = false
    TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = PANEL_SIZE
    }):Play()
end)

Players.PlayerRemoving:Connect(function(player)
    removeESPFor(player)
end)

startESPLoop()

print("[ESP By HoangLong] Load thành công! Nhấn 'BẬT ESP' để bắt đầu.")
