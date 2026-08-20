-- [[ 
--   POTATO MODE SCRIPT
--   Version: 1.1.0
--   Created by: HoangLong
--   Youtube: https://www.youtube.com/@LongHoang-2105/
--   GitHub : https://github.com/hoanglonggg79
-- ]]
if type(_G.Ignore) ~= "table" then
	_G.Ignore = {}
end

if _G.SendNotifications == nil then
	_G.SendNotifications = true
end

if _G.ConsoleLogs == nil then
	_G.ConsoleLogs = false
end

local DefaultSettings = {
	Players = {
		["Ignore Me"] = false,       
		["Ignore Others"] = false,   
		["Ignore Tools"] = true      
	},
	Meshes = {
		NoMesh = true,               
		NoTexture = true,            
		Destroy = true               
	},
	Images = {
		Invisible = true,            
		Destroy = true               
	},
	Explosions = {
		Smaller = true,              
		Invisible = true,            
		Destroy = true               
	},
	Particles = {
		Invisible = true,            
		Destroy = true               
	},
	TextLabels = {
		LowerQuality = true,         
		Invisible = true,            
		Destroy = true               
	},
	MeshParts = {
		LowerQuality = true,         
		Invisible = true,            
		NoTexture = true,            
		NoMesh = true,               
		Destroy = true               
	},
	Other = {
		["FPS Cap"] = 999,           
		["No Camera Effects"] = true,
		["No Clothes"] = true,       
		["Low Water Graphics"] = true,
		["No Shadows"] = true,       
		["Low Rendering"] = true,    
		["Low Quality Parts"] = true,
		["Low Quality Models"] = true,
		["Reset Materials"] = true,  
		["Lower Quality MeshParts"] = true, 
		["Mute Sounds"] = true,      
		["Optimize Lighting"] = true,
		ClearNilInstances = true,    
		AutoReapply = true,          
		AutoReapplyInterval = 15     
	}
}

local function deepMerge(target, default)
	if type(target) ~= "table" then
		target = {}
	end
	for k, v in pairs(default) do
		if type(v) == "table" then
			if type(target[k]) ~= "table" then
				target[k] = {}
			end
			deepMerge(target[k], v)
		else
			if target[k] == nil then
				target[k] = v
			end
		end
	end
	return target
end

if type(_G.Settings) ~= "table" then
	_G.Settings = {}
end
_G.Settings = deepMerge(_G.Settings, DefaultSettings)

if not game:IsLoaded() then
	repeat task.wait() until game:IsLoaded()
end

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
local UserInputService = game:GetService("UserInputService")
local ME = Players.LocalPlayer

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

local VERSION = "1.1.0"
local TotalScanned = 0
local TotalOptimized = 0
local TotalDestroyed = 0
local TotalSkipped = 0
local MeshPartsProcessed = 0
local SoundsMuted = 0
local ParticlesDisabled = 0

local function isGodModeActive()
	local s = _G.Settings
	if not s then return false end
	if (s.Meshes and s.Meshes.Destroy)
		or (s.MeshParts and s.MeshParts.Destroy)
		or (s.Images and s.Images.Destroy)
		or (s.Particles and s.Particles.Destroy)
		or (s.Explosions and s.Explosions.Destroy)
		or (s.TextLabels and s.TextLabels.Destroy)
		or (s.Other and s.Other["No Clothes"])
		or (s.Other and s.Other["Mute Sounds"])
		or (s.Other and s.Other.ClearNilInstances)
		or (s.Players and s.Players["Ignore Me"] == false) then
		return true
	end
	return false
end

local OtherCharacters = {}
local MyCharacter = ME and ME.Character

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

if ME then
	ME.CharacterAdded:Connect(function(char)
		MyCharacter = char
	end)
	ME.CharacterRemoving:Connect(function()
		MyCharacter = nil
	end)
end

local IgnoreSet = {}
local IgnoreInstances = {}

local function addIgnore(v)
	if v == nil then return end
	IgnoreSet[v] = true
	if typeof(v) == "Instance" then
		IgnoreInstances[v] = true
	end
end

if type(_G.Ignore) == "table" then
	for _, v in pairs(_G.Ignore) do
		addIgnore(v)
	end
end

pcall(function()
	if type(_G.Ignore) ~= "table" then
		_G.Ignore = {}
	end
	local mt = getmetatable(_G.Ignore)
	if type(mt) ~= "table" then
		mt = {}
	end
	local original_newindex = mt.__newindex
	mt.__newindex = function(t, k, v)
		addIgnore(v)
		if type(original_newindex) == "function" then
			original_newindex(t, k, v)
		elseif type(original_newindex) == "table" then
			original_newindex[k] = v
		else
			rawset(t, k, v)
		end
	end
	setmetatable(_G.Ignore, mt)
end)

local function shouldSkipInstance(Inst)
	if not Inst then return true end
	if IgnoreSet[Inst] then return true end

	local parent = Inst.Parent
	local playersConfig = _G.Settings.Players or {}
	local isIgnoreOthers = playersConfig["Ignore Others"]
	local isIgnoreMe = playersConfig["Ignore Me"]
	local isIgnoreTools = playersConfig["Ignore Tools"]

	while parent do
		if IgnoreSet[parent] then
			return true
		end
		if isIgnoreOthers and OtherCharacters[parent] then
			return true
		end
		if isIgnoreMe and MyCharacter and parent == MyCharacter then
			return true
		end
		if isIgnoreTools and parent:IsA("BackpackItem") then
			return true
		end
		parent = parent.Parent
	end
	return false
end

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
		warn("[Potato] " .. tostring(text))
	end
end

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
	local destroyed = false

	if className == "Sound" then
		if _G.Settings.Other["Mute Sounds"] then
			pcall(function()
				Inst.Volume = 0
				Inst:Stop()
			end)

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

	elseif className == "MeshPart" then
		if _G.Settings.MeshParts.Destroy then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			optimized = true
		else
			pcall(function()
				if _G.Settings.MeshParts.LowerQuality or _G.Settings.Other["Lower Quality MeshParts"] then
					Inst.RenderFidelity = EnumRenderFidelityPerformance
					Inst.Reflectance = 0
					Inst.Material = EnumMaterialSmoothPlastic
					Inst.CastShadow = false
					optimized = true
				end
				if _G.Settings.MeshParts.Invisible or _G.Settings.MeshParts.NoMesh then
					Inst.Transparency = 1
					optimized = true
				end
				if _G.Settings.MeshParts.NoTexture then
					Inst.TextureID = ""
					optimized = true
				end
			end)
		end
		if optimized then
			MeshPartsProcessed += 1
		end

	elseif Inst:IsA("DataModelMesh") then
		if _G.Settings.Meshes.Destroy then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			optimized = true
		else
			if className == "SpecialMesh" then
				pcall(function()
					if _G.Settings.Meshes.NoMesh then
						Inst.MeshId = ""
						optimized = true
					end
					if _G.Settings.Meshes.NoTexture then
						Inst.TextureId = ""
						optimized = true
					end
				end)
			end
		end

	elseif className == "Decal" or className == "Texture" then
		if _G.Settings.Images.Destroy then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			optimized = true
		elseif _G.Settings.Images.Invisible then
			pcall(function()
				Inst.Transparency = 1
				optimized = true
			end)
		end

	elseif className == "ShirtGraphic" then
		if _G.Settings.Images.Destroy then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			optimized = true
		elseif _G.Settings.Images.Invisible then
			pcall(function()
				Inst.Graphic = ""
				optimized = true
			end)
		end

	elseif CanBeEnabledSet[className] then
		if _G.Settings.Particles.Destroy then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			ParticlesDisabled += 1
			optimized = true
		elseif _G.Settings.Particles.Invisible then
			pcall(function()
				Inst.Enabled = false
				ParticlesDisabled += 1
				optimized = true
			end)
		end

	elseif Inst:IsA("PostEffect") then
		if _G.Settings.Other["No Camera Effects"] then
			pcall(function()
				Inst.Enabled = false
				optimized = true
			end)
		end

	elseif className == "Explosion" then
		if _G.Settings.Explosions.Destroy then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			optimized = true
		else
			pcall(function()
				if _G.Settings.Explosions.Smaller then
					Inst.BlastPressure = 1
					Inst.BlastRadius = 1
					optimized = true
				end
				if _G.Settings.Explosions.Invisible then
					Inst.Visible = false
					optimized = true
				end
			end)
		end

	elseif className == "Clothing" or className == "SurfaceAppearance" or className == "BaseWrap"
		or className == "Accessory" or className == "Hat" or className == "CharacterMesh" or className == "BodyColors"
		or Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap") or Inst:IsA("Accessory")
		or Inst:IsA("CharacterMesh") or Inst:IsA("BodyColors") then
		if _G.Settings.Other["No Clothes"] then
			pcall(function() Inst:Destroy() end)
			destroyed = true
			optimized = true
		end

	elseif Inst:IsA("Light") then
		if _G.Settings.Other["Optimize Lighting"] or _G.Settings.Other["No Shadows"] then
			pcall(function()
				Inst.Enabled = false
				Inst:Destroy()
				destroyed = true
				optimized = true
			end)
		end

	elseif className == "TextLabel" then
		if Inst:IsDescendantOf(Workspace) then
			if _G.Settings.TextLabels.Destroy then
				pcall(function() Inst:Destroy() end)
				destroyed = true
				optimized = true
			else
				pcall(function()
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
				end)
			end
		end

	elseif className == "Model" then
		if _G.Settings.Other["Low Quality Models"] then
			pcall(function()
				Inst.LevelOfDetail = EnumModelLevelOfDetailStreamingMesh
			end)
			optimized = true
		end

	elseif Inst:IsA("BasePart") then
		if _G.Settings.Other["Low Quality Parts"] then
			pcall(function()
				Inst.Material = EnumMaterialSmoothPlastic
				Inst.Reflectance = 0
				Inst.CastShadow = false
				optimized = true
			end)
		end
	end

	if destroyed then
		TotalDestroyed += 1
	end

	if optimized then
		TotalOptimized += 1
	else
		TotalSkipped += 1
	end
end

local function getUIContainer()
	if type(gethui) == "function" then
		local success, hui = pcall(gethui)
		if success and hui then
			return hui
		end
	end

	local coreGui = nil
	pcall(function()
		coreGui = game:GetService("CoreGui")
	end)
	return coreGui
end

local hudGui = nil
local function createFPSHUD()
	pcall(function()
		if hudGui then
			pcall(function() hudGui:Destroy() end)
			hudGui = nil
		end

		local isGod = isGodModeActive()

		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "PotatoFPSHUD"
		ScreenGui.ResetOnSpawn = false
		ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

		local parented = false
		local targetContainer = getUIContainer()

		if targetContainer then
			local s = pcall(function()
				ScreenGui.Parent = targetContainer
			end)
			if s and ScreenGui.Parent == targetContainer then
				parented = true
			end
		end

		if not parented and ME then
			local playerGui = ME:FindFirstChildOfClass("PlayerGui") or ME:WaitForChild("PlayerGui", 5)
			if playerGui then
				local s = pcall(function()
					ScreenGui.Parent = playerGui
				end)
				if s and ScreenGui.Parent == playerGui then
					parented = true
				end
			end
		end

		if not parented then
			pcall(function() ScreenGui:Destroy() end)
			return
		end

		hudGui = ScreenGui

		local MainFrame = Instance.new("Frame")
		MainFrame.Name = "MainFrame"
		MainFrame.Size = UDim2.new(0, 150, 0, 52)
		MainFrame.Position = UDim2.new(1, -165, 0, 15)
		MainFrame.BackgroundColor3 = isGod and Color3.fromRGB(20, 8, 8) or Color3.fromRGB(15, 15, 15)
		MainFrame.BackgroundTransparency = 0.25
		MainFrame.BorderSizePixel = 0
		MainFrame.Active = true
		MainFrame.Draggable = true
		MainFrame.Parent = ScreenGui

		local UICorner = Instance.new("UICorner")
		UICorner.CornerRadius = UDim.new(0, 8)
		UICorner.Parent = MainFrame

		local UIStroke = Instance.new("UIStroke")
		UIStroke.Thickness = 1.5
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke.Color = isGod and Color3.fromRGB(255, 45, 45) or Color3.fromRGB(255, 255, 255)
		UIStroke.Parent = MainFrame

		local ModeLabel = Instance.new("TextLabel")
		ModeLabel.Name = "ModeLabel"
		ModeLabel.Size = UDim2.new(1, 0, 0, 18)
		ModeLabel.Position = UDim2.new(0, 0, 0, 4)
		ModeLabel.BackgroundTransparency = 1
		ModeLabel.Font = Enum.Font.GothamBold
		ModeLabel.TextSize = 11
		ModeLabel.TextColor3 = isGod and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(120, 220, 255)
		ModeLabel.Text = isGod and "🥔 GOD MODE (v" .. VERSION .. ")" or "🥔 POTATO MODE (v" .. VERSION .. ")"
		ModeLabel.Parent = MainFrame

		local FPSLabel = Instance.new("TextLabel")
		FPSLabel.Name = "FPSLabel"
		FPSLabel.Size = UDim2.new(0.5, 0, 0, 26)
		FPSLabel.Position = UDim2.new(0, 8, 0, 22)
		FPSLabel.BackgroundTransparency = 1
		FPSLabel.Font = Enum.Font.RobotoMono
		FPSLabel.TextSize = 15
		FPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
		FPSLabel.Text = "FPS: "
		FPSLabel.Parent = MainFrame

		local StatsLabel = Instance.new("TextLabel")
		StatsLabel.Name = "StatsLabel"
		StatsLabel.Size = UDim2.new(0.5, -8, 0, 26)
		StatsLabel.Position = UDim2.new(0.5, 0, 0, 22)
		StatsLabel.BackgroundTransparency = 1
		StatsLabel.Font = Enum.Font.RobotoMono
		StatsLabel.TextSize = 10
		StatsLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		StatsLabel.TextXAlignment = Enum.TextXAlignment.Right
		StatsLabel.Text = string.format("Opt: %d", TotalOptimized)
		StatsLabel.Parent = MainFrame

		task.spawn(function()
			local hue = 0
			local godPulse = 0
			while task.wait(0.02) do
				if not MainFrame or not MainFrame.Parent then break end
				if isGod then
					godPulse = (godPulse + 0.05) % (math.pi * 2)
					local brightness = 0.6 + 0.4 * math.sin(godPulse)
					UIStroke.Color = Color3.fromRGB(math.floor(255 * brightness), math.floor(35 * brightness), math.floor(35 * brightness))
				else
					hue = (hue + 1) % 360
					UIStroke.Color = Color3.fromHSV(hue / 360, 0.75, 0.85)
				end
			end
		end)

		local frames = 0
		local last = tick()

		local renderConn
		renderConn = RunService.RenderStepped:Connect(function()
			if not MainFrame or not MainFrame.Parent then
				if renderConn then renderConn:Disconnect() end
				return
			end
			frames = frames + 1
			local now = tick()
			if now - last >= 1 then
				local currentFps = frames
				frames = 0
				last = now
				FPSLabel.Text = string.format("FPS: %d", currentFps)
				StatsLabel.Text = isGod and string.format("Des: %d", TotalDestroyed) or string.format("Opt: %d", TotalOptimized)

				if currentFps >= 120 then
					FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
				elseif currentFps >= 60 then
					FPSLabel.TextColor3 = Color3.fromRGB(255, 230, 64)
				else
					FPSLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				end
			end
		end)

		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and MainFrame and MainFrame.Parent then
				if input.KeyCode == Enum.KeyCode.F6 or input.KeyCode == Enum.KeyCode.RightControl then
					MainFrame.Visible = not MainFrame.Visible
				end
			end
		end)
	end)
end

local modeName = isGodModeActive() and "🥔 GOD MODE" or "🥔 POTATO MODE"
Notify(modeName, "Optimizing game graphics...", 3)
print(string.format("[Potato] %s initialization started. Version: %s", modeName, VERSION))

local startTime = tick()

if _G.Settings.Other["Low Water Graphics"] then
	pcall(function()
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
				if type(sethiddenproperty) == "function" then
					sethiddenproperty(terrain, "Decoration", false)
				end
			end)
		end
	end)
end

if _G.Settings.Other["No Shadows"] or _G.Settings.Other["Optimize Lighting"] then
	pcall(function()
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
			if type(sethiddenproperty) == "function" then
				sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
			end
		end)

		for _, v in ipairs(Lighting:GetChildren()) do
			pcall(function()
				local cName = v.ClassName
				if v:IsA("PostEffect") or cName == "Atmosphere" or cName == "Sky" or cName == "Clouds" or v:IsA("Light") then
					v:Destroy()
				end
			end)
		end
	end)
end

if _G.Settings.Other["Low Rendering"] then
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
		settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04
	end)
end

if _G.Settings.Other["Reset Materials"] then
	pcall(function()
		for _, v in pairs(MaterialService:GetChildren()) do
			pcall(function() v:Destroy() end)
		end
		pcall(function()
			MaterialService.Use2022Materials = false
		end)
	end)
end

if _G.Settings.Other["Mute Sounds"] then
	pcall(function()
		SoundService.AmbientReverb = Enum.ReverbType.NoReverb
		SoundService.DistanceFactor = 0
		SoundService.DopplerScale = 0
		SoundService.RolloffScale = 0
	end)
end

if _G.Settings.Other["FPS Cap"] then
	pcall(function()
		if type(setfpscap) == "function" then
			local cap = _G.Settings.Other["FPS Cap"]
			if type(cap) == "number" then
				setfpscap(cap)
			else
				setfpscap(999)
			end
		end
	end)
end

if _G.Settings.Other.ClearNilInstances then
	pcall(function()
		if type(getnilinstances) == "function" then
			local nilList = getnilinstances()
			if type(nilList) == "table" then
				for _, v in pairs(nilList) do
					if typeof(v) == "Instance" then
						pcall(function() v:Destroy() end)
					end
				end
			end
		end
	end)
end

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

	Notify(modeName, "✅ Optimization Complete\n\nLoaded in " .. string.format("%.2fs", totalTime), 5)

	print(string.rep("-", 45))
	print(string.format("[Potato] %s Report (v%s)", modeName, VERSION))
	print(string.rep("-", 45))
	print("- Status: ✅ Optimization Complete")
	print("- Mode: " .. modeName)
	print("- Services Scanned:")
	for _, s in ipairs(ServicesToScan) do
		print("  • " .. s.Name)
	end
	print(string.format("- Total Objects Scanned: %d", TotalScanned))
	print(string.format("- Objects Optimized: %d", TotalOptimized))
	print(string.format("- Objects Destroyed: %d", TotalDestroyed))
	print(string.format("- Objects Skipped: %d", TotalSkipped))
	print(string.format("- MeshParts Processed: %d", MeshPartsProcessed))
	print(string.format("- Sounds Muted: %d", SoundsMuted))
	print(string.format("- Particles Disabled/Destroyed: %d", ParticlesDisabled))
	print(string.format("- Total Optimization Time: %.4f seconds", totalTime))
	print(string.rep("-", 45))

	createFPSHUD()
end)

game.DescendantAdded:Connect(function(obj)
	task.defer(function()
		pcall(function()
			CheckIfBad(obj)
		end)
	end)
end)

if _G.Settings.Other.AutoReapply ~= false then
	local interval = tonumber(_G.Settings.Other.AutoReapplyInterval) or 15
	task.spawn(function()
		while task.wait(interval) do
			for _, service in ipairs(ServicesToScan) do
				local success, descendants = pcall(function()
					return service:GetDescendants()
				end)
				if success and descendants then
					for i, v in ipairs(descendants) do
						CheckIfBad(v)
						if i % 1000 == 0 then
							task.wait()
						end
					end
				end
			end

			if _G.Settings.Other.ClearNilInstances then
				pcall(function()
					if type(getnilinstances) == "function" then
						local nilList = getnilinstances()
						if type(nilList) == "table" then
							for _, v in pairs(nilList) do
								if typeof(v) == "Instance" then
									pcall(function() v:Destroy() end)
								end
							end
						end
					end
				end)
			end
		end
	end)
end
