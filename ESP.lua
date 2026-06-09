local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_GUI"
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0.2
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "ESP Script"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
ToggleButton.Position = UDim2.new(0.1, 0, 0, 45)
ToggleButton.Text = "BẬT ESP"
ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 14
ToggleButton.Parent = Frame

local UICornerBtn = Instance.new("UICorner")
UICornerBtn.CornerRadius = UDim.new(0, 4)
UICornerBtn.Parent = ToggleButton

local espEnabled = false

local function createDrawingObject(drawingType, properties)
    local drawing = Drawing.new(drawingType)
    for k, v in pairs(properties) do
        drawing[k] = v
    end
    return drawing
end

local espObjects = {}

local function updateESP()
    if not espEnabled then return end
    
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = otherPlayer.Character.HumanoidRootPart
            local humanoid = otherPlayer.Character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local vector, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                
                if onScreen then
                    local boxSize = Vector2.new(100, 200)
                    local boxPos = Vector2.new(vector.X - boxSize.X/2, vector.Y - boxSize.Y/2)
                    
                    if not espObjects[otherPlayer] then
                        espObjects[otherPlayer] = {
                            Box = createDrawingObject("Square", {
                                Color = Color3.fromRGB(0, 255, 0),
                                Thickness = 2,
                                Filled = false,
                                Visible = true
                            }),
                            Line = createDrawingObject("Line", {
                                Color = Color3.fromRGB(255, 0, 0),
                                Thickness = 2,
                                Visible = true
                            }),
                            Name = createDrawingObject("Text", {
                                Text = otherPlayer.Name,
                                Color = Color3.fromRGB(255, 255, 255),
                                Size = 14,
                                Center = true,
                                Visible = true
                            }),
                            Health = createDrawingObject("Text", {
                                Text = math.floor(humanoid.Health) .. " HP",
                                Color = Color3.fromRGB(255, 100, 100),
                                Size = 12,
                                Center = true,
                                Visible = true
                            })
                        }
                    end
                    
                    local box = espObjects[otherPlayer].Box
                    box.Position = boxPos
                    box.Size = boxSize
                    
                    local line = espObjects[otherPlayer].Line
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.From = screenCenter
                    line.To = Vector2.new(vector.X, vector.Y)
                    
                    local nameText = espObjects[otherPlayer].Name
                    nameText.Position = Vector2.new(vector.X, vector.Y - boxSize.Y/2 - 15)
                    
                    local healthText = espObjects[otherPlayer].Health
                    healthText.Position = Vector2.new(vector.X, vector.Y + boxSize.Y/2 + 5)
                    healthText.Text = math.floor(humanoid.Health) .. " HP"
                    
                    if humanoid.Health <= 30 then
                        healthText.Color = Color3.fromRGB(255, 0, 0)
                    else
                        healthText.Color = Color3.fromRGB(100, 255, 100)
                    end
                else
                    if espObjects[otherPlayer] then
                        for _, obj in pairs(espObjects[otherPlayer]) do
                            obj.Visible = false
                        end
                    end
                end
            else
                if espObjects[otherPlayer] then
                    for _, obj in pairs(espObjects[otherPlayer]) do
                        obj.Visible = false
                    end
                end
            end
        end
    end
end

local function clearESP()
    for _, objects in pairs(espObjects) do
        for _, obj in pairs(objects) do
            obj:Remove()
        end
    end
    espObjects = {}
end

local function toggleESP()
    espEnabled = not espEnabled
    if espEnabled then
        ToggleButton.Text = "TẮT ESP"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        -- Bắt đầu loop cập nhật
        RunService.RenderStepped:Connect(function()
            updateESP()
        end)
    else
        ToggleButton.Text = "BẬT ESP"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        clearESP()
    end
end

ToggleButton.MouseButton1Click:Connect(toggleESP)

-- Xóa khi player rời game
Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] then
        for _, obj in pairs(espObjects[player]) do
            obj:Remove()
        end
        espObjects[player] = nil
    end
end)

print("ESP Script đã load! Nhấn nút BẬT ESP để bắt đầu")
