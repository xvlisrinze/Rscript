local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer

-- === CONFIG — SEMUA PENGATURAN DISINI ===
local config = {
	enabled = false,
	radius = 1000,
	smoothness = 0.12,
	screenRadius = 0.35,
	modeIndex = 1,
	modes = {
		"Semua (Players + NPC)",
		"Players saja",
		"NPC saja",
		"Team sendiri",
		"Team lain"
	},
	uiPosition = UDim2.new(0, 200, 0.5, -200),
	settingsPosition = UDim2.new(0, 185, 0.5, -90)
}

-- === FUNGSI BANTUAN ===
local localCharacter, localRoot
local closestTarget = nil
local isTapDown = false

local function create(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function makeButton(parent, text, size, pos)
	return create("TextButton", {
		Size = size, Position = pos,
		BackgroundColor3 = Color3.fromRGB(25, 25, 25),
		BorderColor3 = Color3.fromRGB(100, 100, 100),
		Text = text, TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13, Font = Enum.Font.Gotham, AutoButtonColor = true
	}, parent)
end

-- === UI ===
local gui = create("ScreenGui", { Name = "AimbotUI", ResetOnSpawn = false })
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local main = create("Frame", {
	Size = UDim2.fromOffset(155, 40),
	Position = config.uiPosition,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderColor3 = Color3.fromRGB(70, 70, 70)
}, gui)

local toggle = create("TextButton", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.new(0, 10, 0.5, -8),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 1, Text = ""
}, main)

create("TextLabel", {
	Size = UDim2.fromOffset(70, 40),
	Position = UDim2.fromOffset(34, 0),
	BackgroundTransparency = 1, Text = "Aimbot",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 14,
	Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left
}, main)

local gear = makeButton(main, "⚙️", UDim2.fromOffset(32, 30), UDim2.new(1, -37, 0.5, -15))
gear.BackgroundTransparency = 1
gear.BorderSizePixel = 0
gear.TextSize = 18

toggle.Activated:Connect(function()
	config.enabled = not config.enabled
	toggle.BackgroundColor3 = config.enabled and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
end)

-- Settings Panel
local settings = create("Frame", {
	Size = UDim2.fromOffset(245, 180),
	Position = config.settingsPosition,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderColor3 = Color3.fromRGB(90, 90, 90),
	Visible = false
}, gui)

local dragBar = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	BorderSizePixel = 0, Text = "⚙️ Settings",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 14, Font = Enum.Font.Gotham
}, settings)

local dragging, dragStart, startPos = false, nil, nil
dragBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, settings.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		settings.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

gear.Activated:Connect(function() settings.Visible = not settings.Visible end)

-- Radius Slider
local radiusLabel = create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 38),
	BackgroundTransparency = 1, Text = "Radius: "..config.radius.." studs",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, settings)

local slider = create("Frame", {
	Size = UDim2.new(1, -20, 0, 8), Position = UDim2.fromOffset(10, 68),
	BackgroundColor3 = Color3.fromRGB(65, 65, 65), BorderSizePixel = 0
}, settings)
local fill = create("Frame", {
	Size = UDim2.new((config.radius - 1) / 4999, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, slider)
local knob = create("Frame", {
	Size = UDim2.fromOffset(12, 16), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new((config.radius - 1) / 4999, 0, 0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, slider)

local function setRadius(x)
	local alpha = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
	config.radius = math.clamp(math.floor(1 + alpha * 4999 + 0.5), 1, 5000)
	local progress = (config.radius - 1) / 4999
	fill.Size = UDim2.new(progress, 0, 1, 0)
	knob.Position = UDim2.new(progress, 0, 0.5, 0)
	radiusLabel.Text = "Radius: " .. config.radius .. " studs"
end

local sliding = false
local function inputSlider(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliding = true
		setRadius(input.Position.X)
	end
end
slider.InputBegan:Connect(inputSlider)
knob.InputBegan:Connect(inputSlider)
fill.InputBegan:Connect(inputSlider)
UserInputService.InputChanged:Connect(function(input)
	if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		setRadius(input.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliding = false
	end
end)

-- Mode Button
local modeButton = makeButton(settings, config.modes[config.modeIndex], UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 95))
modeButton.Activated:Connect(function()
	config.modeIndex = config.modeIndex % #config.modes + 1
	modeButton.Text = config.modes[config.modeIndex]
end)

create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 35), Position = UDim2.fromOffset(10, 137),
	BackgroundTransparency = 1, Text = "TAP layar = Aim | Musuh di tengah layar saja",
	TextColor3 = Color3.fromRGB(160, 160, 160), TextSize = 11,
	Font = Enum.Font.Gotham, TextWrapped = true
}, settings)

-- === FUNGSI AIM ===
local function IsInScreenCenter(worldPos)
	local scrPos, onScr = Camera:WorldToViewportPoint(worldPos)
	if not onScr then return false end
	local centerX, centerY = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
	local distFromCenter = ((scrPos.X - centerX)^2 + (scrPos.Y - centerY)^2)^0.5
	local radiusPixels = math.min(centerX, centerY) * config.screenRadius
	return distFromCenter <= radiusPixels
end

local function ShouldSkipTarget(model)
	if not model then return true end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return true end
	if model == localCharacter then return true end
	return false
end

local function IsEnemyTeam(targetPlayer)
	if not targetPlayer or not targetPlayer:IsA("Player") then return true end
	if config.modeIndex == 4 then return false end
	if config.modeIndex == 1 then return true end
	if config.modeIndex == 2 then return true end
	if config.modeIndex == 3 then return false end
	if config.modeIndex == 5 then
		return targetPlayer.Team ~= player.Team
	end
	return true
end

local function FindTarget()
	if not localRoot then return nil end
	local nearest, nearestDist = nil, config.radius
	if config.modeIndex ~= 3 then
		for _, v in ipairs(Players:GetPlayers()) do
			local char = v.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and not ShouldSkipTarget(char) and IsEnemyTeam(v) then
				local dist = (localRoot.Position - hrp.Position).Magnitude
				if dist <= config.radius and dist < nearestDist and IsInScreenCenter(hrp.Position) then
					nearestDist = dist
					nearest = hrp
				end
			end
		end
	end
	if config.modeIndex == 1 or config.modeIndex == 3 then
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("Humanoid") then
				local mdl = desc.Parent
				local hrp = mdl:FindFirstChild("HumanoidRootPart")
				if hrp and not ShouldSkipTarget(mdl) then
					local dist = (localRoot.Position - hrp.Position).Magnitude
					if dist <= config.radius and dist < nearestDist and IsInScreenCenter(hrp.Position) then
						nearestDist = dist
						nearest = hrp
					end
				end
			end
		end
	end
	return nearest
end

-- Karakter
player.CharacterAdded:Connect(function(c)
	localCharacter = c
	localRoot = c:WaitForChild("HumanoidRootPart")
end)
if player.Character then
	localCharacter = player.Character
	localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
end

-- Input
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.Touch then isTapDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then isTapDown = false end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
	if not config.enabled or not localRoot then
		closestTarget = nil
		return
	end
	closestTarget = FindTarget()
	if isTapDown and closestTarget then
		local targetCF = CFrame.new(Camera.CFrame.Position, closestTarget.Position - Vector3.new(0, 1.2, 0))
		Camera.CFrame = Camera.CFrame:Lerp(targetCF, config.smoothness)
	end
end)