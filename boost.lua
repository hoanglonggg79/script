-- [[ 
--   POTATO MODE FPS BOOSTER
--   Scr by : HoangLong
--   Youtube: https://www.youtube.com/@LongHoang-2105/
--   GitHub : https://github.com/hoanglonggg79
-- ]]

if not _G.Ignore then
	_G.Ignore = {}
end

if _G.SendNotifications == nil then
	_G.SendNotifications = true
end

if _G.ConsoleLogs == nil then
	_G.ConsoleLogs = false
end

-- Defaul Config
if not _G.Settings then
	_G.Settings = {
		Players = {
			["Ignore Me"] = true,        -- false = tối ưu cả bản thân
			["Ignore Others"] = false,   -- false = tối ưu người khác
			["Ignore Tools"] = true
		},
		Meshes = {
			NoMesh = false,
			NoTexture = true,
			Destroy = false
		},
		Images = {
			Invisible = true,
			Destroy = false
		},
		Explosions = {
			Smaller = true,
			Invisible = false,
			Destroy = false
		},
		Particles = {
			Invisible = true,
			Destroy = true
		},
		TextLabels = {
			LowerQuality = true,
			Invisible = false,
			Destroy = false
		},
		MeshParts = {
			LowerQuality = true,
			Invisible = false,
			NoTexture = true,
			NoMesh = false,
			Destroy = false
		},
		Other = {
			["FPS Cap"] = true,               -- true = uncap FPS
			["No Camera Effects"] = true,
			["No Clothes"] = false,
			["Low Water Graphics"] = true,
			["No Shadows"] = true,
			["Low Rendering"] = true,
			["Low Quality Parts"] = true,
			["Low Quality Models"] = true,
			["Reset Materials"] = true,
			["Lower Quality MeshParts"] = true,
			["Mute Sounds"] = false,
			["Optimize Lighting"] = true,
			ClearNilInstances = false
		}
	}
end

if not game:IsLoaded() then
	repeat task.wait() until game:IsLoaded()
end

--  SERVICE REFERENCES
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local ME = Players.LocalPlayer

-- CACHED ENUM VALUES
local EnumRenderFidelityPerformance = Enum.RenderFidelity.Performance
local EnumMaterialSmoothPlastic = Enum.Material.SmoothPlastic
local EnumFontSourceSans = Enum.Font.SourceSans
local EnumModelLevelOfDetailStreamingMesh = Enum.ModelLevelOfDetail.StreamingMesh

local CanBeEnabledSet = {
	ParticleEmitter = true,
	Trail = true,
	Smoke = true,
	Fire = true,
	Sparkles = true
}

-- STATE TRACKING
local VERSION = "1.0.0"
local TotalScanned = 0
local TotalOptimized = 0
local TotalSkipped = 0
local MeshPartsProcessed = 0
local SoundsMuted = 0
local ParticlesDisabled = 0

-- CACHED CHARACTER TRACKING
local OtherCharacters = {}
local MyCharacter = ME.Character

local function onCharacterAdded(player, character)
	if player ~= ME then
		OtherCharacters[character] = true
	end
end

local function onCharacterRemoving(player, character)
	OtherCharacters[character] = nil
end

local function onPlayerAdded(player)
	if player ~= ME then
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		player.CharacterRemoving:Connect(function(character)
			onCharacterRemoving(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		OtherCharacters[player.Character] = nil
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

ME.CharacterAdded:Connect(function(char)
	MyCharacter = char
end)
ME.CharacterRemoving:Connect(function()
	MyCharacter = nil
end)

-- CACHED IGNORE TRACKING
local IgnoreSet = {}
local IgnoreInstances = {}

local function addIgnore(v)
	IgnoreSet[v] = true
	if typeof(v) == "Instance" then
		IgnoreInstances[v] = true
	end
end

for _, v in ipairs(_G.Ignore) do
	addIgnore(v)
end

-- Monitor dynamic additions to _G.Ignore
pcall(function()
	local mt = getmetatable(_G.Ignore) or {}
	local original_newindex = mt.__newindex
	mt.__newindex = function(t, k, v)
		addIgnore(v)
		if original_newindex then
			original_newindex(t, k, v)
		else
			rawset(t, k, v)
		end
	end
	setmetatable(_G.Ignore, mt)
end)

-- HIERARCHY STATUS CHECK
local function shouldSkipInstance(Inst)
	if IgnoreSet[Inst] then return true end

	local parent = Inst.Parent
	local isIgnoreOthers = _G.Settings.Players["Ignore Others"]
	local isIgnoreMe = _G.Settings.Players["Ignore Me"]
	local isIgnoreTools = _G.Settings.Players["Ignore Tools"]

	while parent do
		if IgnoreSet[parent] then
			return true
		end
		if isIgnoreOthers and OtherCharacters[parent] then
			return true
		end
		if isIgnoreMe and parent == MyCharacter then
			return true
		end
		if isIgnoreTools and parent:IsA("BackpackItem") then
			return true
		end
		parent = parent.Parent
	end
	return false
end

-- NOTIFICATION HELPERS
local function Notify(title, text, duration)
	if _G.SendNotifications then
		pcall(function()
			StarterGui:SetCore("SendNotification", {
				Title = title or "Potato Mode",
				Text = text,
				Duration = duration or 5
			})
		end)
	end
	if _G.ConsoleLogs then
		warn("[Potato] " .. text)
	end
end

-- OPTIMIZATION LOGIC
local function CheckIfBad(Inst)
	TotalScanned += 1

	if not Inst or not Inst.Parent then
		TotalSkipped += 1
		return
	end

	if Inst:IsDescendantOf(Players) then
		TotalSkipped += 1
		return
	end

	if shouldSkipInstance(Inst) then
		TotalSkipped += 1
		return
	end

	local className = Inst.ClassName
	local optimized = false

	-- Sound
	if className == "Sound" then
		if _G.Settings.Other["Mute Sounds"] then
			Inst.Volume = 0
			Inst:Stop()

			pcall(function()
				Inst:GetPropertyChangedSignal("Volume"):Connect(function()
					Inst.Volume = 0
				end)
				Inst:GetPropertyChangedSignal("Playing"):Connect(function()
					if Inst.Playing then
						Inst:Stop()
					end
				end)
			end)

			SoundsMuted += 1
			optimized = true
		end

	-- MeshPart
	elseif className == "MeshPart" then
		if _G.Settings.MeshParts.LowerQuality or _G.Settings.Other["Lower Quality MeshParts"] then
			Inst.RenderFidelity = EnumRenderFidelityPerformance
			Inst.Reflectance = 0
			Inst.Material = EnumMaterialSmoothPlastic
			Inst.CastShadow = false
			optimized = true
		end
		if _G.Settings.MeshParts.Invisible then
			Inst.Transparency = 1
			optimized = true
		end
		if _G.Settings.MeshParts.NoTexture then
			Inst.TextureID = ""
			optimized = true
		end
		if _G.Settings.MeshParts.Destroy then
			Inst:Destroy()
			optimized = true
		end
		if optimized then
			MeshPartsProcessed += 1
		end

	-- SpecialMesh / DataModelMesh
	elseif Inst:IsA("DataModelMesh") then
		if className == "SpecialMesh" then
			if _G.Settings.Meshes.NoMesh then
				Inst.MeshId = ""
				optimized = true
			end
			if _G.Settings.Meshes.NoTexture then
				Inst.TextureId = ""
				optimized = true
			end
		end
		if _G.Settings.Meshes.Destroy then
			Inst:Destroy()
			optimized = true
		end

	-- Decal / Texture
	elseif className == "Decal" or className == "Texture" then
		if _G.Settings.Images.Invisible then
			Inst.Transparency = 1
			optimized = true
		end
		if _G.Settings.Images.Destroy then
			Inst:Destroy()
			optimized = true
		end

	-- ShirtGraphic
	elseif className == "ShirtGraphic" then
		if _G.Settings.Images.Invisible then
			Inst.Graphic = ""
			optimized = true
		end
		if _G.Settings.Images.Destroy then
			Inst:Destroy()
			optimized = true
		end

	-- Particles
	elseif CanBeEnabledSet[className] then
		if _G.Settings.Particles.Invisible or _G.Settings.Particles.Destroy then
			Inst.Enabled = false
			ParticlesDisabled += 1
			optimized = true
		end

	-- PostEffect
	elseif Inst:IsA("PostEffect") then
		if _G.Settings.Other["No Camera Effects"] then
			Inst.Enabled = false
			optimized = true
		end

	-- Explosion
	elseif className == "Explosion" then
		if _G.Settings.Explosions.Smaller then
			Inst.BlastPressure = 1
			Inst.BlastRadius = 1
			optimized = true
		end
		if _G.Settings.Explosions.Invisible then
			Inst.Visible = false
			optimized = true
		end
		if _G.Settings.Explosions.Destroy then
			Inst:Destroy()
			optimized = true
		end

	-- Clothes & SurfaceAppearance
	elseif className == "Clothing" or className == "SurfaceAppearance" or className == "BaseWrap"
		or className == "Accessory" or className == "Hat" or className == "CharacterMesh" or className == "BodyColors"
		or Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") or Inst:IsA("Accessory") then
		if _G.Settings.Other["No Clothes"] then
			Inst:Destroy()
			optimized = true
		end

	-- TextLabel
	elseif className == "TextLabel" then
		if Inst:IsDescendantOf(Workspace) then
			if _G.Settings.TextLabels.LowerQuality then
				Inst.Font = EnumFontSourceSans
				Inst.TextScaled = false
				Inst.RichText = false
				Inst.TextSize = 14
				optimized = true
			end
			if _G.Settings.TextLabels.Invisible then
				Inst.Visible = false
				optimized = true
			end
			if _G.Settings.TextLabels.Destroy then
				Inst:Destroy()
				optimized = true
			end
		end

	-- Model
	elseif className == "Model" then
		if _G.Settings.Other["Low Quality Models"] then
			pcall(function()
				Inst.LevelOfDetail = EnumModelLevelOfDetailStreamingMesh
			end)
			optimized = true
		end

	-- BasePart (WedgePart, Part, TrussPart, etc.)
	elseif Inst:IsA("BasePart") then
		if _G.Settings.Other["Low Quality Parts"] then
			Inst.Material = EnumMaterialSmoothPlastic
			Inst.Reflectance = 0
			Inst.CastShadow = false
			optimized = true
		end
	end

	if optimized then
		TotalOptimized += 1
	else
		TotalSkipped += 1
	end
end

-- FPS HUD UI GENERATION
local function createFPSHUD()
	local UIContainer = nil
	local success, err = pcall(function()
		UIContainer = game:GetService("CoreGui")
	end)
	if not success or not UIContainer then
		UIContainer = ME:WaitForChild("PlayerGui")
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "PotatoFPSHUD"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = UIContainer

	local Frame = Instance.new("Frame")
	Frame.Name = "MainFrame"
	Frame.Size = UDim2.new(0, 110, 0, 35)
	Frame.Position = UDim2.new(1, -125, 0, 15)
	Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	Frame.BackgroundTransparency = 0.45
	Frame.BorderSizePixel = 0
	Frame.Parent = ScreenGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 6)
	UICorner.Parent = Frame

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Thickness = 1.5
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.Name = "FPSLabel"
	Label.Size = UDim2.new(1, 0, 1, 0)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.RobotoMono
	Label.TextSize = 14
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.Text = "FPS: --"
	Label.Parent = Frame

	-- Rainbow border stroke animation
	task.spawn(function()
		local hue = 0
		while task.wait(0.015) do
			if not Frame or not Frame.Parent then break end
			hue = (hue + 1) % 360
			UIStroke.Color = Color3.fromHSV(hue / 360, 0.75, 0.85)
		end
	end)

	-- FPS Counter Logic
	local fps = 0
	local frames = 0
	local last = tick()

	RunService.RenderStepped:Connect(function()
		frames = frames + 1
		local now = tick()
		if now - last >= 1 then
			fps = frames
			frames = 0
			last = now
			Label.Text = string.format("FPS: %d", fps)

			if fps >= 120 then
				Label.TextColor3 = Color3.fromRGB(0, 255, 128)
			elseif fps >= 60 then
				Label.TextColor3 = Color3.fromRGB(255, 230, 64)
			else
				Label.TextColor3 = Color3.fromRGB(255, 80, 80)
			end
		end
	end)
end

-- INITIALIZATION
Notify("[Potato]", "Optimizing game...", 3)
print("[Potato] Initialization started. Version: " .. VERSION)

local startTime = tick()

-- Low Water Graphics
if _G.Settings.Other["Low Water Graphics"] then
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		terrain.WaterWaveSize = 0
		terrain.WaterWaveSpeed = 0
		terrain.WaterReflectance = 0
		terrain.WaterTransparency = 1

		pcall(function()
			terrain.Decoration = false
		end)
		pcall(function()
			if sethiddenproperty then
				sethiddenproperty(terrain, "Decoration", false)
			end
		end)
	end
end

-- No Shadows + Lighting
if _G.Settings.Other["No Shadows"] or _G.Settings.Other["Optimize Lighting"] then
	Lighting.GlobalShadows = false
	Lighting.FogStart = 9e9
	Lighting.FogEnd = 9e9
	Lighting.ShadowSoftness = 0
	Lighting.Brightness = 1
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.Ambient = Color3.fromRGB(128, 128, 128)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)

	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
		end
	end)

	for _, v in ipairs(Lighting:GetChildren()) do
		local cName = v.ClassName
		if v:IsA("PostEffect") or cName == "Atmosphere" or cName == "Sky" or cName == "Clouds" then
			v:Destroy()
		end
	end
end

-- Low Rendering
if _G.Settings.Other["Low Rendering"] then
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
	end)
end

-- Reset Materials
if _G.Settings.Other["Reset Materials"] then
	for _, v in pairs(MaterialService:GetChildren()) do
		v:Destroy()
	end
	pcall(function()
		MaterialService.Use2022Materials = false
	end)
end

-- Mute Sound Service
if _G.Settings.Other["Mute Sounds"] then
	SoundService.AmbientReverb = Enum.ReverbType.NoReverb
	SoundService.DistanceFactor = 0
	SoundService.DopplerScale = 0
	SoundService.RolloffScale = 0
end

-- FPS Cap / Uncap
if _G.Settings.Other["FPS Cap"] then
	pcall(function()
		if setfpscap then
			if type(_G.Settings.Other["FPS Cap"]) == "number" then
				setfpscap(_G.Settings.Other["FPS Cap"])
			else
				setfpscap(999)
			end
		end
	end)
end

-- Clear Nil Instances
if _G.Settings.Other.ClearNilInstances and getnilinstances then
	for _, v in pairs(getnilinstances()) do
		pcall(function() v:Destroy() end)
	end
end

-- SCANNING SERVICES IN BATCHES
local ServicesToScan = {
	Workspace,
	Lighting,
	ReplicatedStorage,
	ReplicatedFirst,
	StarterGui,
	StarterPack,
	SoundService
}

task.spawn(function()
	for _, service in ipairs(ServicesToScan) do
		print("[Potato] Scanning service: " .. service.Name)
		local success, descendants = pcall(function()
			return service:GetDescendants()
		end)

		if not success or not descendants then
			warn("[Potato] Warnings or failed operations: Could not scan descendants of service " .. service.Name)
			continue
		end

		for i, v in ipairs(descendants) do
			CheckIfBad(v)
			if i % 1000 == 0 then
				task.wait()
			end
		end
	end

	local endTime = tick()
	local totalTime = endTime - startTime

	Notify("[Potato]", "✅ Optimization Complete\n\nLoaded in " .. string.format("%.2fs", totalTime), 5)

	print(string.rep("-", 40))
	print("[Potato] Optimization Report (v" .. VERSION .. ")")
	print(string.rep("-", 40))
	print("- Status: ✅ Optimization Complete")
	print("- Services Scanned:")
	for _, s in ipairs(ServicesToScan) do
		print("  • " .. s.Name)
	end
	print(string.format("- Total Objects Scanned: %d", TotalScanned))
	print(string.format("- Objects Optimized: %d", TotalOptimized))
	print(string.format("- Objects Skipped: %d", TotalSkipped))
	print(string.format("- MeshParts Processed: %d", MeshPartsProcessed))
	print(string.format("- Sounds Muted: %d", SoundsMuted))
	print(string.format("- Particles Disabled: %d", ParticlesDisabled))
	print(string.format("- Total Optimization Time: %.4f seconds", totalTime))
	print(string.rep("-", 40))

	-- Create FPS HUD UI
	createFPSHUD()
end)

-- LISTEN FOR NEW INSTANCES
game.DescendantAdded:Connect(function(obj)
	task.defer(function()
		CheckIfBad(obj)
	end)
end)
