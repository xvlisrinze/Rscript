-- Services
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local player = Players.LocalPlayer

local config = {
	enabled = false,
	radius = 1000,
	smoothness = 0.70,
	screenRadius = 0.4,
	mode = "All",
	onScreen = true,
	showCircle = true,
	aimMode = "Camera"
}
local localChar, localRoot, closestTarget, isTapDown = nil, nil, nil, false
local teamNames = {}

local function updateTeams()
	table.clear(teamNames)
	for _, team in ipairs(Teams:GetChildren()) do
		if team:IsA("Team") then table.insert(teamNames, team.Name) end
	end
end
updateTeams()
Teams.ChildAdded:Connect(updateTeams)
Teams.ChildRemoved:Connect(updateTeams)

local function Create(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

-- ✅ Langsung pakai PlayerGui (lebih aman di Delta)
local gui = Create("ScreenGui", { Name = "AimbotUI", ResetOnSpawn = false })
gui.Parent = player:WaitForChild("PlayerGui")

-- Circle di tengah layar
local aimCircle = Create("Frame", {
	Size = UDim2.fromScale(config.screenRadius*2, config.screenRadius*2),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Visible = config.showCircle
}, gui)
local circleBorder = Create("Frame", {
	Size = UDim2.new(1, -2, 1, -2),
	Position = UDim2.fromOffset(1, 1),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.new(1, 0, 0),
	BackgroundTransparency = 0.7,
	BorderSizePixel = 0,
	ZIndex = 100
}, aimCircle)
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0.5, 0)
corner.Parent = circleBorder

-- ✅ Posisi aman di pojok kiri atas
local main = Create("Frame", {
	Size = UDim2.fromOffset(155, 40),
	Position = UDim2.new(0, 10, 0, 50), -- Dekat tombol chat, gak hilang
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderColor3 = Color3.fromRGB(70, 70, 70)
}, gui)

local toggle = Create("TextButton", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.new(0, 10, 0.5, -8),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 1, Text = ""
}, main)

Create("TextLabel", {
	Size = UDim2.fromOffset(70, 40),
	Position = UDim2.fromOffset(34, 0),
	BackgroundTransparency = 1, Text = "Aimbot",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 14, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, main)

local gear = Create("TextButton", {
	Size = UDim2.fromOffset(32, 30),
	Position = UDim2.new(1, -37, 0.5, -15), BackgroundTransparency = 1,
	BorderSizePixel = 0, Text = "⚙️", TextSize = 18
}, main)

toggle.Activated:Connect(function()
	config.enabled = not config.enabled
	toggle.BackgroundColor3 = config.enabled and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
end)

-- ✅ Settings panel di sebelah kanan, gak terpotong
local settings = Create("Frame", {
	Size = UDim2.fromOffset(245, 340),
	Position = UDim2.new(0, 175, 0, 45),
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderColor3 = Color3.fromRGB(90, 90, 90), Visible = false
}, gui)

local dragBar = Create("TextButton", {
	Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(30, 30, 30),
	BorderSizePixel = 0, Text = "⚙️ Settings", TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14, Font = Enum.Font.Gotham
}, settings)

do
	local dragging, startPos, dragStart = false, nil, nil
	dragBar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, settings.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			settings.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
end)

gear.Activated:Connect(function() settings.Visible = not settings.Visible end)

-- Radius Slider
local radiusLabel = Create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 38),
	BackgroundTransparency = 1, Text = "Radius: "..config.radius.." studs",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 13, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, settings)

local slider = Create("Frame", {
	Size = UDim2.new(1, -20, 0, 8), Position = UDim2.fromOffset(10, 68),
	BackgroundColor3 = Color3.fromRGB(65, 65, 65), BorderSizePixel = 0
}, settings)
local fill = Create("Frame", {
	Size = UDim2.new((config.radius-1)/4999, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, slider)
local knob = Create("Frame", {
	Size = UDim2.fromOffset(12, 16), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new((config.radius-1)/4999, 0, 0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, slider)

local function setRadius(x)
	local a = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
	config.radius = math.clamp(math.floor(1 + a * 4999 + 0.5), 1, 5000)
	local p = (config.radius - 1) / 4999
	fill.Size = UDim2.new(p, 0, 1, 0)
	knob.Position = UDim2.new(p, 0, 0.5, 0)
	radiusLabel.Text = "Radius: "..config.radius.." studs"
end

local sliding = false
local function inputSlider(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sliding = true
		setRadius(i.Position.X)
	end
end
slider.InputBegan:Connect(inputSlider)
knob.InputBegan:Connect(inputSlider)
fill.InputBegan:Connect(inputSlider)
UserInputService.InputChanged:Connect(function(i)
	if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		setRadius(i.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		sliding = false
	end
end)

-- Mode Button
local modeList = {"All", "Player", "NPC", "Same Team", "Other Team"}
local modeIndex = 1
local modeButton = Create("TextButton", {
	Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 95),
	BackgroundColor3 = Color3.fromRGB(25, 25, 25), BorderColor3 = Color3.fromRGB(100, 100, 100),
	Text = modeList[modeIndex], TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13, Font = Enum.Font.Gotham, AutoButtonColor = true
}, settings)
modeButton.Activated:Connect(function()
	modeIndex = modeIndex % #modeList + 1
	config.mode = modeList[modeIndex]
	modeButton.Text = modeList[modeIndex]
end)

-- Toggle onScreen
local onScreenToggle = Create("TextButton", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.fromOffset(10, 135),
	BackgroundColor3 = config.onScreen and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
	BorderColor3 = Color3.new(1, 1, 1), BorderSizePixel = 1, Text = ""
}, settings)
Create("TextLabel", {
	Size = UDim2.new(1, -36, 0, 16),
	Position = UDim2.fromOffset(32, 135),
	BackgroundTransparency = 1, Text = "Circle Radius Only",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, settings)
onScreenToggle.Activated:Connect(function()
	config.onScreen = not config.onScreen
	onScreenToggle.BackgroundColor3 = config.onScreen and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
end)

-- Toggle showCircle
local showCircleToggle = Create("TextButton", {
	Size = UDim2.fromOffset(16, 16),
	Position = UDim2.fromOffset(10, 160),
	BackgroundColor3 = config.showCircle and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
	BorderColor3 = Color3.new(1, 1, 1), BorderSizePixel = 1, Text = ""
}, settings)
Create("TextLabel", {
	Size = UDim2.new(1, -36, 0, 16),
	Position = UDim2.fromOffset(32, 160),
	BackgroundTransparency = 1, Text = "Show Circle",
	TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, settings)
showCircleToggle.Activated:Connect(function()
	config.showCircle = not config.showCircle
	showCircleToggle.BackgroundColor3 = config.showCircle and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	aimCircle.Visible = config.showCircle
end)

-- Aim Mode
local aimModeList = {"Camera", "Silent", "Rotate"}
local aimModeIndex = 1
local aimModeButton = Create("TextButton", {
	Size = UDim2.new(1, -20, 0, 32),
	Position = UDim2.fromOffset(10, 185),
	BackgroundColor3 = Color3.fromRGB(25, 25, 25),
	BorderColor3 = Color3.fromRGB(100, 100, 100),
	Text = aimModeList[aimModeIndex],
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 12,
	Font = Enum.Font.Gotham,
	AutoButtonColor = true
}, settings)
aimModeButton.Activated:Connect(function()
	aimModeIndex = aimModeIndex % #aimModeList + 1
	config.aimMode = aimModeList[aimModeIndex]:gsub("%s+", ""):lower()
	if config.aimMode == "Camera" then config.aimMode = "Camera"
	elseif config.aimMode == "Silent" then config.aimMode = "Silent"
	elseif config.aimMode == "Rotate" then config.aimMode = "Rotate" end
	aimModeButton.Text = aimModeList[aimModeIndex]
end)

-- Smoothness Slider
local smoothLabel = Create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 220),
	BackgroundTransparency = 1, Text = "Smoothness: "..config.smoothness,
	TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, settings)
local smoothSlider = Create("Frame", {
	Size = UDim2.new(1, -20, 0, 8), Position = UDim2.fromOffset(10, 245),
	BackgroundColor3 = Color3.fromRGB(65, 65, 65), BorderSizePixel = 0
}, settings)
local smoothFill = Create("Frame", {
	Size = UDim2.new(config.smoothness, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, smoothSlider)
local smoothKnob = Create("Frame", {
	Size = UDim2.fromOffset(12, 16), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(config.smoothness, 0, 0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, smoothSlider)
local function setSmooth(x)
	local a = math.clamp((x - smoothSlider.AbsolutePosition.X) / smoothSlider.AbsoluteSize.X, 0, 1)
	config.smoothness = math.round(a * 100) / 100
	smoothFill.Size = UDim2.new(config.smoothness, 0, 1, 0)
	smoothKnob.Position = UDim2.new(config.smoothness, 0, 0.5, 0)
	smoothLabel.Text = "Smoothness: "..config.smoothness
end
local smoothSliding = false
local function inputSmooth(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		smoothSliding = true
		setSmooth(i.Position.X)
	end
end
smoothSlider.InputBegan:Connect(inputSmooth)
smoothKnob.InputBegan:Connect(inputSmooth)
smoothFill.InputBegan:Connect(inputSmooth)
UserInputService.InputChanged:Connect(function(i)
	if smoothSliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		setSmooth(i.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		smoothSliding = false
	end
end)

-- Circle Size Slider
local circleLabel = Create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 275),
	BackgroundTransparency = 1, Text = "Circle Size: "..config.screenRadius,
	TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Left
}, settings)
local circleSlider = Create("Frame", {
	Size = UDim2.new(1, -20, 0, 8), Position = UDim2.fromOffset(10, 300),
	BackgroundColor3 = Color3.fromRGB(65, 65, 65), BorderSizePixel = 0
}, settings)
local circleFill = Create("Frame", {
	Size = UDim2.new(config.screenRadius, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, circleSlider)
local circleKnob = Create("Frame", {
	Size = UDim2.fromOffset(12, 16), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(config.screenRadius, 0, 0.5, 0),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0
}, circleSlider)
local function setCircle(x)
	local a = math.clamp((x - circleSlider.AbsolutePosition.X) / circleSlider.AbsoluteSize.X, 0, 1)
	config.screenRadius = math.round(a * 100) / 100
	circleFill.Size = UDim2.new(config.screenRadius, 0, 1, 0)
	circleKnob.Position = UDim2.new(config.screenRadius, 0, 0.5, 0)
	circleLabel.Text = "Circle Size: "..config.screenRadius
end
local circleSliding = false
local function inputCircle(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		circleSliding = true
		setCircle(i.Position.X)
	end
end
circleSlider.InputBegan:Connect(inputCircle)
circleKnob.InputBegan:Connect(inputCircle)
circleFill.InputBegan:Connect(inputCircle)
UserInputService.InputChanged:Connect(function(i)
	if circleSliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		setCircle(i.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		circleSliding = false
	end
end)

Create("TextLabel", {
	Size = UDim2.new(1, -20, 0, 35), Position = UDim2.fromOffset(10, 325),
	BackgroundTransparency = 1, Text = "Tap Screen = Aimbot",
	TextColor3 = Color3.fromRGB(160, 160, 160), TextSize = 11,
	Font = Enum.Font.Gotham, TextWrapped = true
}, settings)

-- Fungsi Bantuan
local function InScreenCenter(pos)
	local sp, ok = Camera:WorldToViewportPoint(pos)
	if not ok then return false end
	local cx, cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
	local r = math.min(cx, cy) * config.screenRadius
	return ((sp.X - cx)^2 + (sp.Y - cy)^2)^0.5 <= r
end

local function ValidTarget(model)
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0 and model ~= localChar
end

local function ShouldIncludePlayer(target)
	if config.mode == "All" or config.mode == "Player" then return true end
	if config.mode == "Same Team" then return target.Team == player.Team end
	if config.mode == "Other Team" then return target.Team ~= player.Team end
	return false
end

local function FindTarget()
	if not localRoot then return end
	local nearest, minDist = nil, config.radius
	if config.mode ~= "NPC" then
		for _, v in ipairs(Players:GetPlayers()) do
			local ch, hrp = v.Character, v.Character and v.Character:FindFirstChild("HumanoidRootPart")
			if hrp and ValidTarget(ch) and ShouldIncludePlayer(v) then
				local d = (localRoot.Position - hrp.Position).Magnitude
				local inScreen = not config.onScreen or InScreenCenter(hrp.Position)
				if d <= config.radius and d < minDist and inScreen then
					minDist, nearest = d, hrp
				end
			end
		end
	end
	if config.mode == "All" or config.mode == "NPC" then
		for _, desc in ipairs(Workspace:GetDescendants()) do
			if desc:IsA("Humanoid") then
				local mdl, hrp = desc.Parent, desc.Parent:FindFirstChild("HumanoidRootPart")
				if hrp and ValidTarget(mdl) then
					local d = (localRoot.Position - hrp.Position).Magnitude
					local inScreen = not config.onScreen or InScreenCenter(hrp.Position)
					if d <= config.radius and d < minDist and inScreen then
						minDist, nearest = d, hrp
					end
				end
			end
		end
	end
	return nearest
end

-- Karakter
player.CharacterAdded:Connect(function(c)
	localChar = c
	localRoot = c:WaitForChild("HumanoidRootPart")
end)
if player.Character then
	localChar = player.Character
	localRoot = localChar:FindFirstChild("HumanoidRootPart")
end

-- Input Mobile
UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.UserInputType == Enum.UserInputType.Touch then isTapDown = true end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch then isTapDown = false end
end)

-- Main Loop
RunService.RenderStepped:Connect(function()
	aimCircle.Visible = config.showCircle
	aimCircle.Size = UDim2.fromScale(config.screenRadius*2, config.screenRadius*2)
	if not config.enabled or not localRoot then
		closestTarget = nil
		return
	end
	closestTarget = FindTarget()
	if isTapDown and closestTarget then
		local targetPos = closestTarget.Position + Vector3.new(0, 1.2, 0)
		if config.aimMode == "Camera" then
			local targetCF = CFrame.new(Camera.CFrame.Position, targetPos)
			Camera.CFrame = Camera.CFrame:Lerp(targetCF, config.smoothness)
		elseif config.aimMode == "Silent" then
		elseif config.aimMode == "Rotate" then
			local dir = (targetPos - localRoot.Position)
			dir = Vector3.new(dir.X, 0, dir.Z).Unit
			local lookAt = localRoot.Position + dir
			localRoot.CFrame = CFrame.new(localRoot.Position, lookAt)
		end
	end
end)

print("✅ Aimbot Loaded! — Tombol di pojok kiri atas")
