local COVER_IMAGE_ID = "rbxassetid://6675147490"
local AUDIO_ID       = "rbxassetid://110919391228823"
local MAX_RETRIES    = 3

local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local targetParent = CoreGui:FindFirstChild("RobloxGui") or CoreGui

local existing = targetParent:FindFirstChild("ExecutorMusicGui")
if existing then existing:Destroy() end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color       = color or Color3.fromRGB(255, 85, 85)
	s.Thickness   = thickness or 2
	s.Transparency = transparency or 0.5
	s.Parent      = parent
	return s
end

local function tween(obj, info, props)
	return TweenService:Create(obj, info, props)
end

local FAST   = TweenInfo.new(0.2)
local MEDIUM = TweenInfo.new(0.35, Enum.EasingStyle.Quart)

local C = {
	bg        = Color3.fromRGB(14, 14, 18),
	surface   = Color3.fromRGB(24, 24, 30),
	surface2  = Color3.fromRGB(34, 34, 42),
	accent    = Color3.fromRGB(0, 170, 255),
	accentAlt = Color3.fromRGB(255, 85, 85),
	muted     = Color3.fromRGB(60, 62, 72),
	textPrim  = Color3.fromRGB(245, 245, 250),
	textSec   = Color3.fromRGB(160, 162, 175),
	green     = Color3.fromRGB(0, 220, 120),
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "ExecutorMusicGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = targetParent

local mainFrame = Instance.new("Frame")
mainFrame.Name              = "MainFrame"
mainFrame.Size              = UDim2.new(0, 340, 0, 510)
mainFrame.Position          = UDim2.new(0.5, -170, 0.5, -255)
mainFrame.BackgroundColor3  = C.bg
mainFrame.BorderSizePixel   = 0
mainFrame.Active            = true
mainFrame.Draggable         = true
mainFrame.Parent            = screenGui
corner(mainFrame, 18)
local borderStroke = stroke(mainFrame, C.accentAlt, 1.5, 0.5)

local titleBar = Instance.new("Frame")
titleBar.Size              = UDim2.new(1, 0, 0, 44)
titleBar.BackgroundColor3  = C.surface
titleBar.BorderSizePixel   = 0
titleBar.Parent            = mainFrame
corner(titleBar, 18)

local function fixTitleBarBottom()
	local fixer = Instance.new("Frame")
	fixer.Size             = UDim2.new(1, 0, 0, 18)
	fixer.Position         = UDim2.new(0, 0, 1, -18)
	fixer.BackgroundColor3 = C.surface
	fixer.BorderSizePixel  = 0
	fixer.Parent           = titleBar
end
fixTitleBarBottom()

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(1, -50, 1, 0)
titleLabel.Position           = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "🎵  MUSIC PLAYER"
titleLabel.TextColor3         = C.textPrim
titleLabel.TextSize           = 16
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size              = UDim2.new(0, 28, 0, 28)
closeBtn.Position          = UDim2.new(1, -36, 0.5, -14)
closeBtn.BackgroundColor3  = C.accentAlt
closeBtn.Text              = "✕"
closeBtn.TextColor3        = C.textPrim
closeBtn.TextSize          = 14
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.BorderSizePixel   = 0
closeBtn.Parent            = titleBar
corner(closeBtn, 7)

local coverContainer = Instance.new("Frame")
coverContainer.Size             = UDim2.new(0, 270, 0, 270)
coverContainer.Position         = UDim2.new(0.5, -135, 0, 56)
coverContainer.BackgroundColor3 = C.surface2
coverContainer.BorderSizePixel  = 0
coverContainer.Parent           = mainFrame
corner(coverContainer, 135)
stroke(coverContainer, C.accent, 1, 0.7)

local coverImage = Instance.new("ImageLabel")
coverImage.Size                  = UDim2.new(1, 0, 1, 0)
coverImage.BackgroundTransparency = 1
coverImage.Image                 = ""
coverImage.Parent                = coverContainer
corner(coverImage, 135)

local coverLoading = Instance.new("TextLabel")
coverLoading.Size                 = UDim2.new(1, 0, 1, 0)
coverLoading.BackgroundTransparency = 1
coverLoading.Text                 = "⏳"
coverLoading.TextColor3           = C.textSec
coverLoading.TextSize             = 28
coverLoading.Visible              = true
coverLoading.Parent               = coverContainer

local progressBg = Instance.new("Frame")
progressBg.Size             = UDim2.new(0, 300, 0, 4)
progressBg.Position         = UDim2.new(0.5, -150, 0, 342)
progressBg.BackgroundColor3 = C.muted
progressBg.BorderSizePixel  = 0
progressBg.Parent           = mainFrame
corner(progressBg, 2)

local progressFill = Instance.new("Frame")
progressFill.Size             = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = C.accent
progressFill.BorderSizePixel  = 0
progressFill.Parent           = progressBg
corner(progressFill, 2)

local progressKnob = Instance.new("Frame")
progressKnob.Size             = UDim2.new(0, 10, 0, 10)
progressKnob.Position         = UDim2.new(0, -5, 0.5, -5)
progressKnob.BackgroundColor3 = C.textPrim
progressKnob.BorderSizePixel  = 0
progressKnob.Parent           = progressFill
corner(progressKnob, 5)

local timeLabel = Instance.new("TextLabel")
timeLabel.Size                = UDim2.new(1, -20, 0, 18)
timeLabel.Position            = UDim2.new(0, 10, 0, 352)
timeLabel.BackgroundTransparency = 1
timeLabel.Text                = "0:00 / 0:00"
timeLabel.TextColor3          = C.textSec
timeLabel.TextSize            = 11
timeLabel.Font                = Enum.Font.Gotham
timeLabel.Parent              = mainFrame

local volLabel = Instance.new("TextLabel")
volLabel.Size                 = UDim2.new(0, 55, 0, 18)
volLabel.Position             = UDim2.new(0, 12, 0, 378)
volLabel.BackgroundTransparency = 1
volLabel.Text                 = "🔊 70%"
volLabel.TextColor3           = C.textSec
volLabel.TextSize             = 11
volLabel.Font                 = Enum.Font.Gotham
volLabel.TextXAlignment       = Enum.TextXAlignment.Left
volLabel.Parent               = mainFrame

local volTrack = Instance.new("Frame")
volTrack.Size             = UDim2.new(0, 160, 0, 4)
volTrack.Position         = UDim2.new(0, 72, 0, 386)
volTrack.BackgroundColor3 = C.muted
volTrack.BorderSizePixel  = 0
volTrack.Parent           = mainFrame
corner(volTrack, 2)

local volFill = Instance.new("Frame")
volFill.Size             = UDim2.new(0.7, 0, 1, 0)
volFill.BackgroundColor3 = C.accent
volFill.BorderSizePixel  = 0
volFill.Parent           = volTrack
corner(volFill, 2)

local volKnob = Instance.new("Frame")
volKnob.Size             = UDim2.new(0, 10, 0, 10)
volKnob.Position         = UDim2.new(1, -5, 0.5, -5)
volKnob.BackgroundColor3 = C.textPrim
volKnob.BorderSizePixel  = 0
volKnob.Parent           = volFill
corner(volKnob, 5)

local function makeButton(text, color, posX, posY, w, h)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, w or 105, 0, h or 42)
	btn.Position         = UDim2.new(0, posX, 0, posY)
	btn.BackgroundColor3 = color
	btn.TextColor3       = C.textPrim
	btn.Text             = text
	btn.TextSize         = 14
	btn.Font             = Enum.Font.GothamBold
	btn.BorderSizePixel  = 0
	btn.Parent           = mainFrame
	corner(btn, 10)
	return btn
end

local playBtn = makeButton("▶  PLAY",  C.accent,    17,  408)
local stopBtn = makeButton("⏹  STOP",  C.surface2,  128, 408)
local loopBtn = makeButton("🔁  OFF",   C.surface2,  239, 408, 84)

local eqContainer = Instance.new("Frame")
eqContainer.Size              = UDim2.new(0, 220, 0, 32)
eqContainer.Position          = UDim2.new(0.5, -110, 0, 462)
eqContainer.BackgroundTransparency = 1
eqContainer.Parent            = mainFrame

local eqBars = {}
for i = 1, 10 do
	local bar = Instance.new("Frame")
	bar.AnchorPoint      = Vector2.new(0, 1)
	bar.Size             = UDim2.new(0, 16, 0, 4)
	bar.Position         = UDim2.new(0, (i - 1) * 22, 1, 0)
	bar.BackgroundColor3 = C.accent
	bar.BorderSizePixel  = 0
	bar.Parent           = eqContainer
	corner(bar, 2)
	table.insert(eqBars, bar)
end

local bgm = Instance.new("Sound")
bgm.Name   = "BGM"
bgm.Volume = 0.7
bgm.Looped = false
bgm.Parent = mainFrame

local state = {
	playing       = false,
	volume        = 0.7,
	looped        = false,
	audioReady    = false,
	draggingVol   = false,
	draggingSeek  = false,
	coverRotation = 0,
}

local function formatTime(s)
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end

local function setVolume(v)
	state.volume   = math.clamp(v, 0, 1)
	bgm.Volume     = state.volume
	volFill.Size   = UDim2.new(state.volume, 0, 1, 0)
	volLabel.Text  = "🔊 " .. math.floor(state.volume * 100) .. "%"
end

local function setPlayUI(playing)
	state.playing = playing
	if playing then
		playBtn.Text             = "⏸  PAUSE"
		playBtn.BackgroundColor3 = C.accentAlt
		tween(borderStroke, MEDIUM, {Transparency = 0}):Play()
	else
		playBtn.Text             = "▶  PLAY"
		playBtn.BackgroundColor3 = C.accent
		tween(borderStroke, MEDIUM, {Transparency = 0.5}):Play()
	end
end

local function loadAudio(attempt)
	attempt = attempt or 1
	state.audioReady           = false
	playBtn.Text               = "⏳  LOADING"
	playBtn.BackgroundColor3   = C.surface2
	playBtn.Active             = false

	local ok, err = pcall(function()
		bgm.SoundId = AUDIO_ID
		local waited = 0
		repeat
			task.wait(0.1)
			waited += 0.1
		until bgm.IsLoaded or waited >= 8
		if not bgm.IsLoaded then error("Timeout") end
	end)

	if ok then
		state.audioReady         = true
		playBtn.Text             = "▶  PLAY"
		playBtn.BackgroundColor3 = C.accent
		playBtn.Active           = true
	elseif attempt < MAX_RETRIES then
		warn("[MusicPlayer] Retry", attempt, err)
		task.wait(1.5)
		loadAudio(attempt + 1)
	else
		warn("[MusicPlayer] Failed after", MAX_RETRIES, "attempts:", err)
		playBtn.Text             = "❌  ERROR"
		playBtn.BackgroundColor3 = C.accentAlt
		playBtn.Active           = false
	end
end

task.spawn(function()
	coverLoading.Visible = true
	local ok = pcall(function() coverImage.Image = COVER_IMAGE_ID end)
	task.wait(0.8)
	coverLoading.Visible = not ok
end)

task.spawn(loadAudio)

local eqTimer = 0
local spinSpeed = 15

RunService.Heartbeat:Connect(function(dt)
	if not screenGui.Parent then return end

	if state.playing then
		local len = bgm.TimeLength
		local pos = bgm.TimePosition
		if len > 0 then
			progressFill.Size = UDim2.new(pos / len, 0, 1, 0)
			timeLabel.Text    = formatTime(pos) .. " / " .. formatTime(len)
		end

		state.coverRotation = (state.coverRotation + spinSpeed * dt) % 360
		coverContainer.Rotation = state.coverRotation
	end

	eqTimer += dt
	if eqTimer >= 0.12 then
		eqTimer = 0
		if state.playing then
			for _, bar in ipairs(eqBars) do
				local h = 4 + math.random(0, 28)
				tween(bar, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 16, 0, h)}):Play()
			end
		else
			for _, bar in ipairs(eqBars) do
				tween(bar, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {Size = UDim2.new(0, 16, 0, 4)}):Play()
			end
		end
	end
end)

bgm.Ended:Connect(function()
	setPlayUI(false)
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	timeLabel.Text    = "0:00 / " .. formatTime(bgm.TimeLength)
end)

playBtn.MouseButton1Click:Connect(function()
	if not state.audioReady then return end
	if not state.playing then
		local ok, err = pcall(function() bgm:Play() end)
		if ok then
			setPlayUI(true)
		else
			warn("[MusicPlayer] Play error:", err)
		end
	else
		bgm:Pause()
		setPlayUI(false)
	end
end)

stopBtn.MouseButton1Click:Connect(function()
	bgm:Stop()
	setPlayUI(false)
	coverContainer.Rotation = 0
	state.coverRotation     = 0
	progressFill.Size       = UDim2.new(0, 0, 1, 0)
	timeLabel.Text          = "0:00 / 0:00"
end)

loopBtn.MouseButton1Click:Connect(function()
	state.looped   = not state.looped
	bgm.Looped     = state.looped
	if state.looped then
		loopBtn.Text             = "🔁  ON"
		loopBtn.BackgroundColor3 = C.accent
	else
		loopBtn.Text             = "🔁  OFF"
		loopBtn.BackgroundColor3 = C.surface2
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	bgm:Stop()
	screenGui:Destroy()
end)

progressBg.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	state.draggingSeek = true
	local x = math.clamp((input.Position.X - progressBg.AbsolutePosition.X) / progressBg.AbsoluteSize.X, 0, 1)
	if bgm.TimeLength > 0 then
		bgm.TimePosition = x * bgm.TimeLength
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		state.draggingVol  = false
		state.draggingSeek = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

	if state.draggingVol then
		local x = math.clamp((input.Position.X - volTrack.AbsolutePosition.X) / volTrack.AbsoluteSize.X, 0, 1)
		setVolume(x)
	end

	if state.draggingSeek then
		local x = math.clamp((input.Position.X - progressBg.AbsolutePosition.X) / progressBg.AbsoluteSize.X, 0, 1)
		if bgm.TimeLength > 0 then
			bgm.TimePosition = x * bgm.TimeLength
		end
	end
end)

volTrack.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	state.draggingVol = true
	local x = math.clamp((input.Position.X - volTrack.AbsolutePosition.X) / volTrack.AbsoluteSize.X, 0, 1)
	setVolume(x)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not screenGui.Parent then return end
	if input.KeyCode == Enum.KeyCode.Space then
		playBtn:Click()
	elseif input.KeyCode == Enum.KeyCode.S then
		stopBtn:Click()
	elseif input.KeyCode == Enum.KeyCode.L then
		loopBtn:Click()
	elseif input.KeyCode == Enum.KeyCode.Up then
		setVolume(state.volume + 0.05)
	elseif input.KeyCode == Enum.KeyCode.Down then
		setVolume(state.volume - 0.05)
	end
end)

local function tooltip(btn, text)
	local tip = Instance.new("TextLabel")
	tip.Size                 = UDim2.new(0, 110, 0, 24)
	tip.Position             = UDim2.new(0.5, -55, 1, 6)
	tip.BackgroundColor3     = C.surface2
	tip.TextColor3           = C.textPrim
	tip.Text                 = text
	tip.TextSize             = 11
	tip.Font                 = Enum.Font.Gotham
	tip.Visible              = false
	tip.Parent               = btn
	corner(tip, 5)
	btn.MouseEnter:Connect(function()  tip.Visible = true  end)
	btn.MouseLeave:Connect(function()  tip.Visible = false end)
end

tooltip(playBtn,  "Play / Pause  [Space]")
tooltip(stopBtn,  "Stop  [S]")
tooltip(loopBtn,  "Toggle Loop  [L]")
tooltip(closeBtn, "Close")

local function notify(msg, color)
	local n = Instance.new("TextLabel")
	n.Size               = UDim2.new(0, 240, 0, 36)
	n.Position           = UDim2.new(1, -250, 1, -46)
	n.BackgroundColor3   = C.surface
	n.BackgroundTransparency = 0.1
	n.TextColor3         = color or C.green
	n.Text               = msg
	n.TextSize           = 13
	n.Font               = Enum.Font.GothamMedium
	n.Parent             = screenGui
	corner(n, 8)
	stroke(n, color or C.green, 1, 0.5)

	tween(n, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
	task.delay(2.5, function()
		tween(n, TweenInfo.new(0.4), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		task.wait(0.4)
		n:Destroy()
	end)
end

task.wait(0.3)
notify("✓  Music Player Ready!")
