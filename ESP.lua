-- ESP Cực kỳ khó chặn bằng thuật toán thông thường vì ESP chỉ đọc dữ liệu (Read-only), nó không sửa đổi bất kỳ file nào của game. 
-- Trừ khi máy chủ áp dụng kỹ thuật Fog of War (chỉ gửi dữ liệu kẻ địch về máy khách khi kẻ địch thực sự lộ diện trong tầm nhìn), nếu không thì ESP vẫn sẽ tồn tại!
-- ============================================================
--  Tính năng: Box, Name, Distance, Health Bar, Skeleton, Team Color
--  GUI: Toggle thu nhỏ thành icon, toggle riêng từng tính năng
-- ============================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local Camera         = workspace.CurrentCamera
local LocalPlayer    = Players.LocalPlayer

local Config = {
    Enabled       = false,
    ShowBox       = true,
    ShowName      = true,
    ShowDistance  = true,
    ShowHealthBar = true,
    ShowSkeleton  = true,
    UseTeamColor  = true,
    DefaultColor  = Color3.fromRGB(0, 200, 255),
    EnemyColor    = Color3.fromRGB(255, 80, 80),
    TeamColor     = Color3.fromRGB(0, 255, 120),
    MaxDistance   = 500, 
}

local SKELETON_CONNECTIONS = {
    {"Head",            "UpperTorso"},
    {"UpperTorso",      "LowerTorso"},
    {"UpperTorso",      "LeftUpperArm"},
    {"LeftUpperArm",    "LeftLowerArm"},
    {"LeftLowerArm",    "LeftHand"},
    {"UpperTorso",      "RightUpperArm"},
    {"RightUpperArm",   "RightLowerArm"},
    {"RightLowerArm",   "RightHand"},
    {"LowerTorso",      "LeftUpperLeg"},
    {"LeftUpperLeg",    "LeftLowerLeg"},
    {"LeftLowerLeg",    "LeftFoot"},
    {"LowerTorso",      "RightUpperLeg"},
    {"RightUpperLeg",   "RightLowerLeg"},
    {"RightLowerLeg",   "RightFoot"},
}

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

local espObjects = {}

local function removeESPFor(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            if typeof(obj) == "table" then
                for _, line in pairs(obj) do
                    pcall(function() line:Remove() end)
                end
            else
                pcall(function() obj:Remove() end)
            end
        end
        espObjects[player] = nil
    end
end

local function clearAllESP()
    for player in pairs(espObjects) do
        removeESPFor(player)
    end
end

local function updateESPFor(player)
    local char      = player.Character
    local root      = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid  = char and char:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid or humanoid.Health <= 0 then
        if espObjects[player] then
            for _, obj in pairs(espObjects[player]) do
                if typeof(obj) == "table" then
                    for _, line in pairs(obj) do pcall(function() line.Visible = false end) end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
        end
        return
    end

    local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        and math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
        or 0

    if dist > Config.MaxDistance then
        if espObjects[player] then
            for _, obj in pairs(espObjects[player]) do
                if typeof(obj) == "table" then
                    for _, line in pairs(obj) do pcall(function() line.Visible = false end) end
                else
                    pcall(function() obj.Visible = false end)
                end
            end
        end
        return
    end

    local vec, onScreen = Camera:WorldToViewportPoint(root.Position)
    local color = getPlayerColor(player)

    if not espObjects[player] then
        local skelLines = {}
        for i = 1, #SKELETON_CONNECTIONS do
            skelLines[i] = newDrawing("Line", {Color=color, Thickness=1, Visible=false, Transparency=0.2})
        end

        espObjects[player] = {
            Box = newDrawing("Square", {
                Color=color, Thickness=2, Filled=false, Visible=false
            }),
            BoxOutline = newDrawing("Square", {
                Color=Color3.fromRGB(0,0,0), Thickness=4, Filled=false, Visible=false
            }),
            Name = newDrawing("Text", {
                Text=player.Name, Color=Color3.fromRGB(255,255,255),
                Size=13, Center=true, Outline=true, Visible=false
            }),
            Distance = newDrawing("Text", {
                Text="0m", Color=Color3.fromRGB(200,200,200),
                Size=11, Center=true, Outline=true, Visible=false
            }),
            -- Health bar: background (đen) + thanh máu thực
            HealthBG = newDrawing("Square", {
                Color=Color3.fromRGB(0,0,0), Thickness=1, Filled=true, Visible=false
            }),
            HealthBar = newDrawing("Square", {
                Color=Color3.fromRGB(0,255,100), Thickness=1, Filled=true, Visible=false
            }),
            -- Skeleton lines
            Skeleton = skelLines,
        }
    end

    local esp = espObjects[player]
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
    esp.Box.Position  = Vector2.new(boxX, boxY)
    esp.Box.Size      = Vector2.new(boxW, boxH)
    esp.Box.Color     = color
    esp.Box.Visible   = showBox

    local showName = Config.ShowName and onScreen
    esp.Name.Text     = player.Name
    esp.Name.Position = Vector2.new(vec.X, boxY - 16)
    esp.Name.Visible  = showName

    local showDist = Config.ShowDistance and onScreen
    esp.Distance.Text     = dist .. "m"
    esp.Distance.Position = Vector2.new(vec.X, boxY + boxH + 2)
    esp.Distance.Visible  = showDist

    local showHP = Config.ShowHealthBar and onScreen
    local hpRatio   = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    local barW      = 4
    local barX      = boxX - barW - 3
    local barFullH  = boxH
    local barFilledH = barFullH * hpRatio

    local hpColor
    if hpRatio > 0.5 then
        hpColor = Color3.fromRGB(
            math.floor(255 * (1 - hpRatio) * 2),
            255, 0
        )
    else
        hpColor = Color3.fromRGB(
            255,
            math.floor(255 * hpRatio * 2),
            0
        )
    end

    esp.HealthBG.Position = Vector2.new(barX, boxY)
    esp.HealthBG.Size     = Vector2.new(barW, barFullH)
    esp.HealthBG.Visible  = showHP

    esp.HealthBar.Color    = hpColor
    esp.HealthBar.Position = Vector2.new(barX, boxY + barFullH - barFilledH)
    esp.HealthBar.Size     = Vector2.new(barW, barFilledH)
    esp.HealthBar.Visible  = showHP

    for i, conn in ipairs(SKELETON_CONNECTIONS) do
        local line = esp.Skeleton[i]
        local p0   = char:FindFirstChild(conn[1])
        local p1   = char:FindFirstChild(conn[2])
        local showSkel = Config.ShowSkeleton and onScreen and p0 and p1

        if showSkel then
            local v0, on0 = Camera:WorldToViewportPoint(p0.Position)
            local v1, on1 = Camera:WorldToViewportPoint(p1.Position)
            if on0 or on1 then
                line.From    = Vector2.new(v0.X, v0.Y)
                line.To      = Vector2.new(v1.X, v1.Y)
                line.Color   = color
                line.Visible = true
            else
                line.Visible = false
            end
        else
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

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "ESP_GUI_V2"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = game:GetService("CoreGui")

local IconBtn = Instance.new("ImageButton")
IconBtn.Size                = UDim2.new(0, 46, 0, 46)
IconBtn.Position            = UDim2.new(0, 14, 0, 14)
IconBtn.BackgroundColor3    = Color3.fromRGB(20, 20, 30)
IconBtn.BorderSizePixel     = 0
IconBtn.Visible             = false
IconBtn.ZIndex              = 10
IconBtn.Parent              = ScreenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = IconBtn
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(0,200,255); s.Thickness = 2; s.Parent = IconBtn
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = "ESP"; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13; lbl.TextColor3 = Color3.fromRGB(0,200,255)
    lbl.Parent = IconBtn
end

local Panel = Instance.new("Frame")
Panel.Size              = UDim2.new(0, 220, 0, 310)
Panel.Position          = UDim2.new(0, 14, 0, 14)
Panel.BackgroundColor3  = Color3.fromRGB(15, 15, 22)
Panel.BorderSizePixel   = 0
Panel.ClipsDescendants  = true
Panel.Parent            = ScreenGui
do
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = Panel
    local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(0,180,255); s.Thickness = 1.5; s.Parent = Panel
end

local TitleBar = Instance.new("Frame")
TitleBar.Size           = UDim2.new(1,0,0,38)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 140, 210)
TitleBar.BorderSizePixel = 0
TitleBar.Parent         = Panel
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,10); c.Parent = TitleBar end

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1,-44,1,0); TitleLbl.Position = UDim2.new(0,10,0,0)
TitleLbl.BackgroundTransparency = 1; TitleLbl.Text = "✦ ESP v2.0"
TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 15
TitleLbl.TextColor3 = Color3.fromRGB(255,255,255); TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0,26,0,26); MinBtn.Position = UDim2.new(1,-32,0.5,-13)
MinBtn.BackgroundColor3 = Color3.fromRGB(255,255,255); MinBtn.BackgroundTransparency = 0.8
MinBtn.Text = "–"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 18
MinBtn.TextColor3 = Color3.fromRGB(255,255,255); MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = MinBtn end

do
    local dragging, dragStart, startPos = false, nil, nil
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position
            startPos = Panel.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
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
Content.Size = UDim2.new(1,0,1,-42); Content.Position = UDim2.new(0,0,0,42)
Content.BackgroundTransparency = 1; Content.Parent = Panel
do
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0,6); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = Content
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0,8); pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
    pad.Parent = Content
end

local function makeToggle(labelText, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,32); row.BackgroundTransparency = 1; row.Parent = Content

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-54,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = labelText; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13
    lbl.TextColor3 = Color3.fromRGB(210,210,220); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0,44,0,22); track.Position = UDim2.new(1,-44,0.5,-11)
    track.BorderSizePixel = 0
    track.BackgroundColor3 = default and Color3.fromRGB(0,160,255) or Color3.fromRGB(70,70,90)
    track.Parent = row
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = track end

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0,18,0,18); thumb.AnchorPoint = Vector2.new(0,0.5)
    thumb.Position = default and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0)
    thumb.BackgroundColor3 = Color3.fromRGB(255,255,255); thumb.BorderSizePixel = 0
    thumb.Parent = track
    do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = thumb end

    local state = default
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""
    btn.Parent = track

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, tweenInfo, {
            BackgroundColor3 = state and Color3.fromRGB(0,160,255) or Color3.fromRGB(70,70,90)
        }):Play()
        TweenService:Create(thumb, tweenInfo, {
            Position = state and UDim2.new(1,-20,0.5,0) or UDim2.new(0,2,0.5,0)
        }):Play()
        callback(state)
    end)

    return row
end

local MainBtn = Instance.new("TextButton")
MainBtn.Size = UDim2.new(1,0,0,38); MainBtn.BackgroundColor3 = Color3.fromRGB(0,120,200)
MainBtn.Text = "BẬT ESP"; MainBtn.Font = Enum.Font.GothamBold; MainBtn.TextSize = 15
MainBtn.TextColor3 = Color3.fromRGB(255,255,255); MainBtn.BorderSizePixel = 0
MainBtn.Parent = Content
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = MainBtn end

local Sep = Instance.new("Frame")
Sep.Size = UDim2.new(1,0,0,1); Sep.BackgroundColor3 = Color3.fromRGB(50,50,70)
Sep.BorderSizePixel = 0; Sep.Parent = Content

-- Các toggle tính năng
makeToggle("📦  Hiện Box",         Config.ShowBox,       function(v) Config.ShowBox = v end)
makeToggle("🏷️  Hiện Tên",          Config.ShowName,      function(v) Config.ShowName = v end)
makeToggle("📏  Hiện Khoảng cách", Config.ShowDistance,  function(v) Config.ShowDistance = v end)
makeToggle("❤️  Thanh Máu",         Config.ShowHealthBar, function(v) Config.ShowHealthBar = v end)
makeToggle("💀  Skeleton",          Config.ShowSkeleton,  function(v) Config.ShowSkeleton = v end)
makeToggle("🎨  Màu Team",          Config.UseTeamColor,  function(v) Config.UseTeamColor = v end)

MainBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    if Config.Enabled then
        MainBtn.Text = "TẮT ESP"
        TweenService:Create(MainBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(200,50,50)}):Play()
        startESPLoop()
    else
        MainBtn.Text = "BẬT ESP"
        TweenService:Create(MainBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,120,200)}):Play()
        clearAllESP()
    end
end)

local isMinimized = false
local PANEL_SIZE  = UDim2.new(0, 220, 0, 310)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    TweenService:Create(Panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 220, 0, 0)
    }):Play()
    task.delay(0.25, function()
        Panel.Visible = false
        IconBtn.Visible = true
    end)
end)

IconBtn.MouseButton1Click:Connect(function()
    isMinimized = false
    Panel.Size = UDim2.new(0, 220, 0, 0)
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

print("[ESP By HoangLong] Đã load! Nhấn 'BẬT ESP' để bắt đầu.")
