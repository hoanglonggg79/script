-- ==========================================
-- POTATO MODE SCRIPT
-- ==========================================

if not _G.Ignore then
	_G.Ignore = {} -- Thêm instance muốn bỏ qua vào đây (ví dụ: workspace.Map)
end

if _G.SendNotifications == nil then
	_G.SendNotifications = true
end

if _G.ConsoleLogs == nil then
	_G.ConsoleLogs = false
end

-- ========== CÀI ĐẶT MẶC ĐỊNH ==========
if not _G.Settings then
	_G.Settings = {
		Players = {
			["Ignore Me"] = false,       -- false = tối ưu cả bản thân
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
			ClearNilInstances = false
		}
	}
end

-- ========== CHỜ GAME LOAD ==========
if not game:IsLoaded() then
	repeat task.wait() until game:IsLoaded()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local MaterialService = game:GetService("MaterialService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ME = Players.LocalPlayer

local CanBeEnabled = {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}

-- ========== HÀM HỖ TRỢ ==========
local function PartOfCharacter(Inst)
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= ME and v.Character and Inst:IsDescendantOf(v.Character) then
			return true
		end
	end
	return false
end

local function DescendantOfIgnore(Inst)
	for _, v in pairs(_G.Ignore) do
		if type(v) == "userdata" and Inst:IsDescendantOf(v) then
			return true
		end
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
		warn("[Potato] " .. text)
	end
end

local function CheckIfBad(Inst)
	if not Inst or not Inst.Parent then return end

	if Inst:IsDescendantOf(Players) then return end
	if _G.Settings.Players["Ignore Others"] and PartOfCharacter(Inst) then return end
	if _G.Settings.Players["Ignore Me"] and ME.Character and Inst:IsDescendantOf(ME.Character) then return end
	if _G.Settings.Players["Ignore Tools"] and (Inst:IsA("BackpackItem") or Inst:FindFirstAncestorWhichIsA("BackpackItem")) then return end
	if _G.Ignore and (table.find(_G.Ignore, Inst) or DescendantOfIgnore(Inst)) then return end

	-- Mesh (SpecialMesh / DataModelMesh)
	if Inst:IsA("DataModelMesh") then
		if Inst:IsA("SpecialMesh") then
			if _G.Settings.Meshes.NoMesh then Inst.MeshId = "" end
			if _G.Settings.Meshes.NoTexture then Inst.TextureId = "" end
		end
		if _G.Settings.Meshes.Destroy then Inst:Destroy() end

	-- Decal / Texture
	elseif Inst:IsA("FaceInstance") then
		if _G.Settings.Images.Invisible then
			Inst.Transparency = 1
		end
		if _G.Settings.Images.Destroy then Inst:Destroy() end

	-- ShirtGraphic
	elseif Inst:IsA("ShirtGraphic") then
		if _G.Settings.Images.Invisible then Inst.Graphic = "" end
		if _G.Settings.Images.Destroy then Inst:Destroy() end

	-- Particles
	elseif table.find(CanBeEnabled, Inst.ClassName) then
		if _G.Settings.Particles.Invisible then Inst.Enabled = false end
		if _G.Settings.Particles.Destroy then Inst:Destroy() end

	-- PostEffect
	elseif Inst:IsA("PostEffect") and _G.Settings.Other["No Camera Effects"] then
		Inst.Enabled = false

	-- Explosion
	elseif Inst:IsA("Explosion") then
		if _G.Settings.Explosions.Smaller then
			Inst.BlastPressure = 1
			Inst.BlastRadius = 1
		end
		if _G.Settings.Explosions.Invisible then
			Inst.Visible = false
		end
		if _G.Settings.Explosions.Destroy then Inst:Destroy() end

	-- Clothes & SurfaceAppearance
	elseif Inst:IsA("Clothing") or Inst:IsA("SurfaceAppearance") or Inst:IsA("BaseWrap")
		or Inst:IsA("Accessory") or Inst:IsA("Hat") or Inst:IsA("CharacterMesh") or Inst:IsA("BodyColors") then
		if _G.Settings.Other["No Clothes"] then
			Inst:Destroy()
		end

	-- MeshPart
	elseif Inst:IsA("MeshPart") then
		if _G.Settings.MeshParts.LowerQuality or _G.Settings.Other["Lower Quality MeshParts"] then
			Inst.RenderFidelity = Enum.RenderFidelity.Performance
			Inst.Reflectance = 0
			Inst.Material = Enum.Material.SmoothPlastic
			Inst.CastShadow = false
		end
		if _G.Settings.MeshParts.Invisible then
			Inst.Transparency = 1
		end
		if _G.Settings.MeshParts.NoTexture then Inst.TextureID = "" end
		if _G.Settings.MeshParts.Destroy then Inst:Destroy() end

	-- BasePart thường
	elseif Inst:IsA("BasePart") then
		if _G.Settings.Other["Low Quality Parts"] then
			Inst.Material = Enum.Material.SmoothPlastic
			Inst.Reflectance = 0
			Inst.CastShadow = false
		end

	-- TextLabel
	elseif Inst:IsA("TextLabel") and Inst:IsDescendantOf(Workspace) then
		if _G.Settings.TextLabels.LowerQuality then
			Inst.Font = Enum.Font.SourceSans
			Inst.TextScaled = false
			Inst.RichText = false
			Inst.TextSize = 14
		end
		if _G.Settings.TextLabels.Invisible then Inst.Visible = false end
		if _G.Settings.TextLabels.Destroy then Inst:Destroy() end

	-- Model
	elseif Inst:IsA("Model") then
		if _G.Settings.Other["Low Quality Models"] then
			pcall(function()
				Inst.LevelOfDetail = Enum.ModelLevelOfDetail.StreamingMesh
			end)
		end

	-- Sound
	elseif Inst:IsA("Sound") and _G.Settings.Other["Mute Sounds"] then
		Inst.Volume = 0
		Inst:Stop()
	end
end

Notify("Potato Mode", "Đang tải FPS Booster...", 5)

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

	-- PostEffect / Atmosphere / Sky / Clouds
	for _, v in ipairs(Lighting:GetChildren()) do
		if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("Clouds") then
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

local Descendants = game:GetDescendants()
Notify("Potato Mode", "Đang kiểm tra " .. #Descendants .. " objects...", 5)

task.spawn(function()
	for i, v in ipairs(Descendants) do
		CheckIfBad(v)
		if i % 1000 == 0 then
			task.wait() -- Nghỉ mỗi 1000 object để chống giật lag
		end
	end
	Notify("Potato Mode", "FPS Booster Loaded!", 5)
	print(">>> POTATO MODE LOADED <<<")
end)

-- Lắng nghe object mới spawn
game.DescendantAdded:Connect(function(obj)
	task.defer(function()
		CheckIfBad(obj)
	end)
end)
