-- Polyfills
if not math.clamp then
	math.clamp = function(v, min, max)
		if v < min then return min end
		if v > max then return max end
		return v
	end
end

print("=== JOSSEPOPSIER ===")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local PG = LP:WaitForChild("PlayerGui")
if PG:FindFirstChild("JOSSEPOPSIER") then
	PG.JOSSEPOPSIER:Destroy()
end

local UI = Instance.new("ScreenGui")
UI.Name = "JOSSEPOPSIER"
UI.ResetOnSpawn = false
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = PG

-- Colors
local ACCENT     = Color3.fromRGB(145, 70, 255)
local BG_MAIN    = Color3.fromRGB(16, 16, 22)
local BG_SIDE    = Color3.fromRGB(22, 22, 30)
local BG_CARD    = Color3.fromRGB(30, 30, 40)
local BG_BTN     = Color3.fromRGB(40, 40, 52)
local TEXT_MAIN  = Color3.fromRGB(245, 245, 250)
local TEXT_DIM   = Color3.fromRGB(140, 140, 155)

-- ===================== STATES =====================
local hitboxEnabled = false
local hitboxSize = 2.75
local hitboxVisible = true
local hitboxConn = nil

local maxServeEnabled = false
local maxSpikeEnabled = false
local maxHook = nil

local shiftlockEnabled = false
local asyncDesyncEnabled = false
local desyncDuration = 0.15
local lastDesync = 0
local desyncConn = nil

local espEnabled = false
local espBeams = {}

local facingUntil = 0
local faceTime = 0.18
local facingConn = nil

-- Silent Spike
local silentSpikeEnabled = false
local silentSpikeGui = nil

-- ===================== SILENT SPIKE =====================
local function getBallId()
	for _, obj in pairs(Workspace:GetChildren()) do
		if obj.Name:match("^CLIENT_BALL") then
			local id = tonumber(obj.Name:match("%d+"))
			if id then return id end
		end
	end
	return nil
end

local function doSilentSpike()
	local ballId = getBallId()
	if not ballId then return end

	local look = Camera.CFrame.LookVector
	local lookFlat = Vector3.new(look.X, 0, look.Z)
	if lookFlat.Magnitude > 0.001 then
		lookFlat = lookFlat.Unit
	else
		lookFlat = Vector3.new(0, 0, -1)
	end

	local Interact = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.BallService.RF.Interact

	pcall(function()
		Interact:InvokeServer({
			Charge = 1,
			Move = "Spike",
			SpecialCharge = 0,
			TiltDirection = Vector3.yAxis,
			LookVector = lookFlat,
			MoveDirection = Vector3.zero,
			ClientCanRunSpecial = false,
			From = "Client",
			Timestamp = workspace:GetServerTimeNow(),
			BallId = ballId,
			CustomClient = {}
		})
	end)
end

local function createSilentSpikeButton()
	if silentSpikeGui then silentSpikeGui:Destroy() end

	silentSpikeGui = Instance.new("ScreenGui")
	silentSpikeGui.Name = "SilentSpikeBtn"
	silentSpikeGui.ResetOnSpawn = false
	silentSpikeGui.Parent = PG

	local MainBtn = Instance.new("Frame")
	MainBtn.Size = UDim2.new(0, 150, 0, 48)
	MainBtn.Position = UDim2.new(0.5, -75, 0.75, 0)
	MainBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 70)
	MainBtn.BorderSizePixel = 0
	MainBtn.Active = true
	MainBtn.Parent = silentSpikeGui
	Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 10)

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.Text = "SPIKE BALL"
	Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Btn.Font = Enum.Font.GothamBold
	Btn.TextSize = 16
	Btn.Parent = MainBtn

	Btn.MouseButton1Click:Connect(doSilentSpike)

	-- Non-snapping drag
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		MainBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	MainBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = MainBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	MainBtn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local function destroySilentSpikeButton()
	if silentSpikeGui then
		silentSpikeGui:Destroy()
		silentSpikeGui = nil
	end
end

-- ===================== FEATURES =====================
local function updateHitboxes(scale)
	for _, model in ipairs(Workspace:GetChildren()) do
		if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
			local ball = model:FindFirstChild("Ball.001")
			if hitboxEnabled then
				if not ball then
					local base = model:FindFirstChildWhichIsA("BasePart", true)
					if base then
						ball = Instance.new("Part")
						ball.Name = "Ball.001"
						ball.Shape = Enum.PartType.Ball
						ball.Size = Vector3.new(2, 2, 2) * scale
						ball.CFrame = base.CFrame
						ball.Anchored = true
						ball.CanCollide = false
						ball.Material = Enum.Material.Plastic
						ball.Color = Color3.fromRGB(80, 255, 120)
						ball.Parent = model
					end
				else
					ball.Size = Vector3.new(2, 2, 2) * scale
				end
				if ball then
					ball.Transparency = hitboxVisible and 0.85 or 1
				end
			else
				if ball then ball:Destroy() end
			end
		end
	end
end

local function toggleHitbox(state)
	hitboxEnabled = state
	if state then
		if not hitboxConn then
			hitboxConn = Workspace.ChildAdded:Connect(function(c)
				if c:IsA("Model") and c.Name:match("^CLIENT_BALL_") then
					task.wait(0.2)
					if hitboxEnabled then updateHitboxes(hitboxSize) end
				end
			end)
		end
		updateHitboxes(hitboxSize)
	else
		if hitboxConn then
			hitboxConn:Disconnect()
			hitboxConn = nil
		end
		for _, model in ipairs(Workspace:GetChildren()) do
			if model:IsA("Model") and model.Name:match("^CLIENT_BALL_") then
				local b = model:FindFirstChild("Ball.001")
				if b then b:Destroy() end
			end
		end
	end
end

-- ===================== MAX SERVE + AUTO TSH MAX SPIKE =====================
local function setupMaxHook()
	if maxHook then return end

	maxHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local args = {...}

		if method == "InvokeServer" then
			local name = tostring(self.Name)

			if maxServeEnabled and name == "Serve" then
				if typeof(args[2]) == "number" then
					args[2] = 0.94 + math.random() * 0.05
				end
				return maxHook(self, unpack(args))
			end

			if maxSpikeEnabled and name == "Interact" then
				if typeof(args[1]) == "table" then
					local data = args[1]
					if data.Move == "Spike" then
						local power = 0.93 + math.random() * 0.05
						data.Charge = power
						data.SpecialCharge = power
					end
				end
				return maxHook(self, unpack(args))
			end
		end

		return maxHook(self, ...)
	end))
end

local function setMaxServe(state)
	maxServeEnabled = state
	if state then setupMaxHook() end
end

local function setMaxSpike(state)
	maxSpikeEnabled = state
	if state then setupMaxHook() end
end

-- ===================== DESYNC =====================
local function applyDesync(state)
	pcall(function()
		setfflag("PhysicsSenderMaxBandwidthBps", state and "1" or "999999")
	end)
end

local function onJump()
	if not asyncDesyncEnabled then return end
	local now = tick()
	if now - lastDesync < 0.40 then return end
	lastDesync = now
	applyDesync(true)
	task.delay(desyncDuration, function()
		applyDesync(false)
	end)
end

local function setupDesync(char)
	if desyncConn then desyncConn:Disconnect() end
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		desyncConn = hum.Jumping:Connect(onJump)
	end
end

-- ===================== IMPROVED AUTO SHIFTLOCK =====================
local function setupShiftlock(char)
	if facingConn then facingConn:Disconnect() end

	local hum = char:WaitForChild("Humanoid", 3)
	local root = char:WaitForChild("HumanoidRootPart", 3)
	if not hum or not root then return end

	facingConn = RunService.RenderStepped:Connect(function()
		if not shiftlockEnabled or not root.Parent then return end

		if tick() < facingUntil then
			local look = Camera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.05 then
				root.CFrame = CFrame.new(root.Position, root.Position + flat.Unit)
			end
		end
	end)

	hum.StateChanged:Connect(function(_, new)
		if shiftlockEnabled and (new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall) then
			facingUntil = tick() + faceTime
		end
	end)
end

-- ===================== DIRECTION ESP =====================
local function getTiltAmount(root, hum)
	if not root or not hum then return 0 end

	local moveDir = hum.MoveDirection
	if moveDir.Magnitude < 0.1 then return 0 end

	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.1 then return 0 end
	flatLook = flatLook.Unit

	local right = Vector3.new(flatLook.Z, 0, -flatLook.X)
	local sideAmount = moveDir:Dot(right)

	return math.clamp(sideAmount * 1.6, -1, 1)
end

local function clearESP()
	for _, data in pairs(espBeams) do
		pcall(function()
			if data.Beam then data.Beam:Destroy() end
			if data.A0 then data.A0:Destroy() end
			if data.A1 then data.A1:Destroy() end
		end)
	end
	table.clear(espBeams)
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Team == LP.Team then
			if espBeams[player] then
				pcall(function()
					espBeams[player].Beam:Destroy()
					espBeams[player].A0:Destroy()
					espBeams[player].A1:Destroy()
				end)
				espBeams[player] = nil
			end
			continue
		end

		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")

			if hum and hum.Health > 0 and root then
				local data = espBeams[player]

				if not data then
					local a0 = Instance.new("Attachment")
					a0.Parent = Workspace.Terrain
					local a1 = Instance.new("Attachment")
					a1.Parent = Workspace.Terrain

					local beam = Instance.new("Beam")
					beam.Attachment0 = a0
					beam.Attachment1 = a1
					beam.Width0 = 0.45
					beam.Width1 = 0.45
					beam.FaceCamera = true
					beam.LightEmission = 0.4
					beam.Parent = Workspace.Terrain

					data = {Beam = beam, A0 = a0, A1 = a1}
					espBeams[player] = data
				end

				local look = root.CFrame.LookVector
				local dir = Vector3.new(look.X, 0, look.Z)
				if dir.Magnitude < 0.05 then
					dir = Vector3.new(0, 0, -1)
				else
					dir = dir.Unit
				end

				local state = hum:GetState()
				local inAir = state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall

				local tilt = getTiltAmount(root, hum)

				if inAir and math.abs(tilt) > 0.22 then
					local angle = math.rad(-tilt * 13)
					local cos, sin = math.cos(angle), math.sin(angle)

					local newX = dir.X * cos - dir.Z * sin
					local newZ = dir.X * sin + dir.Z * cos
					dir = Vector3.new(newX, 0, newZ).Unit

					data.Beam.Color = ColorSequence.new(Color3.fromRGB(0, 140, 255))
				else
					data.Beam.Color = ColorSequence.new(Color3.fromRGB(200, 30, 30))
				end

				data.A0.WorldPosition = root.Position + dir * 0.7
				data.A1.WorldPosition = root.Position + dir * 60
			end
		end
	end

	for player, data in pairs(espBeams) do
		if not player.Parent then
			pcall(function()
				data.Beam:Destroy()
				data.A0:Destroy()
				data.A1:Destroy()
			end)
			espBeams[player] = nil
		end
	end
end)

-- ===================== UI =====================
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 460, 0, 340)
Main.Position = UDim2.new(0.5, -230, 0.5, -170)
Main.BackgroundColor3 = BG_MAIN
Main.BorderSizePixel = 0
Main.Parent = UI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(50, 50, 65)
stroke.Thickness = 1
stroke.Transparency = 0.3

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 22)
title.Position = UDim2.new(0, 16, 0, 10)
title.BackgroundTransparency = 1
title.Text = "JOSSEPOPSIER"
title.TextColor3 = ACCENT
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Main

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -20, 0, 14)
sub.Position = UDim2.new(0, 16, 0, 30)
sub.BackgroundTransparency = 1
sub.Text = "Volleyball Legends"
sub.TextColor3 = TEXT_DIM
sub.Font = Enum.Font.Gotham
sub.TextSize = 11
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = Main

-- Drag + Clamp
local dragging, dragStart, startPos = false, nil, nil
Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.AbsolutePosition
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local viewport = Camera.ViewportSize
		local size = Main.AbsoluteSize
		local newX = math.clamp(startPos.X + delta.X, -size.X * 0.3, viewport.X - size.X * 0.7)
		local newY = math.clamp(startPos.Y + delta.Y, -size.Y * 0.2, viewport.Y - size.Y * 0.7)
		Main.Position = UDim2.new(0, newX, 0, newY)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Hide Button
local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 70, 0, 30)
hideBtn.Position = UDim2.new(1, -85, 0, 70)
hideBtn.BackgroundColor3 = ACCENT
hideBtn.Text = "HIDE"
hideBtn.TextColor3 = TEXT_MAIN
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 13
hideBtn.Parent = UI
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)

local uiVisible = true
hideBtn.MouseButton1Click:Connect(function()
	uiVisible = not uiVisible
	Main.Visible = uiVisible
	hideBtn.Text = uiVisible and "HIDE" or "SHOW"
end)

local hDragging, hDragStart, hStartPos
hideBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		hDragging = true
		hDragStart = input.Position
		hStartPos = hideBtn.AbsolutePosition
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if hDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - hDragStart
		local viewport = Camera.ViewportSize
		local size = hideBtn.AbsoluteSize
		local newX = math.clamp(hStartPos.X + delta.X, -20, viewport.X - size.X + 20)
		local newY = math.clamp(hStartPos.Y + delta.Y, -10, viewport.Y - size.Y + 10)
		hideBtn.Position = UDim2.new(0, newX, 0, newY)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		hDragging = false
	end
end)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 105, 1, -55)
sidebar.Position = UDim2.new(0, 10, 0, 50)
sidebar.BackgroundColor3 = BG_SIDE
sidebar.BorderSizePixel = 0
sidebar.Parent = Main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -130, 1, -60)
content.Position = UDim2.new(0, 122, 0, 52)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = ACCENT
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = Main

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = content

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 2)
padding.PaddingRight = UDim.new(0, 6)
padding.Parent = content

local currentTab = nil
local tabButtons = {}

local function clearContent()
	for _, child in ipairs(content:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function switchTab(name)
	if currentTab == name then return end
	currentTab = name
	for id, btn in pairs(tabButtons) do
		if id == name then
			btn.BackgroundColor3 = ACCENT
			btn.TextColor3 = TEXT_MAIN
		else
			btn.BackgroundColor3 = BG_BTN
			btn.TextColor3 = TEXT_DIM
		end
	end
	clearContent()
	if name == "Main" then buildMain()
	elseif name == "Character" then buildCharacter()
	elseif name == "Visuals" then buildVisuals() end
end

local tabData = {
	{id = "Main", text = "Main"},
	{id = "Character", text = "Character"},
	{id = "Visuals", text = "Visuals"}
}

for i, t in ipairs(tabData) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -12, 0, 34)
	btn.Position = UDim2.new(0, 6, 0, 8 + (i-1)*42)
	btn.BackgroundColor3 = (i == 1) and ACCENT or BG_BTN
	btn.Text = t.text
	btn.TextColor3 = (i == 1) and TEXT_MAIN or TEXT_DIM
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = sidebar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	tabButtons[t.id] = btn
	btn.MouseButton1Click:Connect(function()
		switchTab(t.id)
	end)
end

-- ===================== UI HELPERS =====================
local function makeToggle(text, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 38)
	row.BackgroundColor3 = BG_CARD
	row.BorderSizePixel = 0
	row.Parent = content
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = TEXT_DIM
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 48, 0, 24)
	btn.Position = UDim2.new(1, -56, 0.5, -12)
	btn.BackgroundColor3 = BG_BTN
	btn.Text = "OFF"
	btn.TextColor3 = TEXT_DIM
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.AutoButtonColor = false
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local on = default
	local function refresh()
		btn.Text = on and "ON" or "OFF"
		btn.BackgroundColor3 = on and ACCENT or BG_BTN
		btn.TextColor3 = on and TEXT_MAIN or TEXT_DIM
		lbl.TextColor3 = on and TEXT_MAIN or TEXT_DIM
	end
	refresh()

	btn.MouseButton1Click:Connect(function()
		on = not on
		refresh()
		callback(on)
	end)
end

local function makeSlider(text, min, max, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 70)
	row.BackgroundColor3 = BG_CARD
	row.BorderSizePixel = 0
	row.Parent = content
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.55, 0, 0, 18)
	lbl.Position = UDim2.new(0, 12, 0, 6)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = TEXT_DIM
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0, 58, 0, 22)
	textBox.Position = UDim2.new(1, -70, 0, 5)
	textBox.BackgroundColor3 = BG_BTN
	textBox.Text = string.format("%.2f", default)
	textBox.TextColor3 = TEXT_MAIN
	textBox.Font = Enum.Font.GothamBold
	textBox.TextSize = 13
	textBox.ClearTextOnFocus = false
	textBox.Parent = row
	Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 6)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 5)
	bar.Position = UDim2.new(0, 12, 0, 42)
	bar.BackgroundColor3 = BG_BTN
	bar.Parent = row
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = ACCENT
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Text = ""
	knob.Parent = bar
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function update(val)
		val = math.clamp(val, min, max)
		val = math.floor(val * 100 + 0.5) / 100
		local pct = (val - min) / (max - min)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		knob.Position = UDim2.new(pct, -7, 0.5, -7)
		textBox.Text = string.format("%.2f", val)
		callback(val)
	end

	local sliding = false
	knob.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = true
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if sliding and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local pct = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			update(min + pct * (max - min))
		end
	end)

	textBox.FocusLost:Connect(function()
		local num = tonumber(textBox.Text)
		if num then
			update(num)
		else
			textBox.Text = string.format("%.2f", default)
		end
	end)
end

local function makeWarning(text)
	local warning = Instance.new("Frame")
	warning.Size = UDim2.new(1, -4, 0, 52)
	warning.BackgroundColor3 = Color3.fromRGB(90, 20, 20)
	warning.BorderSizePixel = 0
	warning.Parent = content
	Instance.new("UICorner", warning).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 60, 60)
	stroke.Thickness = 2
	stroke.Parent = warning

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(255, 120, 120)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = warning
end

-- Build Tabs
function buildMain()
	makeToggle("Hitbox Extender", hitboxEnabled, function(v) toggleHitbox(v) end)
	makeSlider("Hitbox Size", 1, 8, hitboxSize, function(v)
		hitboxSize = v
		if hitboxEnabled then updateHitboxes(v) end
	end)
	makeToggle("Max Serve", maxServeEnabled, function(v) setMaxServe(v) end)
	makeToggle("Auto TSH Max Spike", maxSpikeEnabled, function(v) setMaxSpike(v) end)
	makeToggle("Silent Spike Button", silentSpikeEnabled, function(v)
		silentSpikeEnabled = v
		if v then
			createSilentSpikeButton()
		else
			destroySilentSpikeButton()
		end
	end)
end

function buildCharacter()
	makeToggle("Auto Shiftlock", shiftlockEnabled, function(v)
		shiftlockEnabled = v
		if v and LP.Character then setupShiftlock(LP.Character) end
	end)
	makeToggle("Desync", asyncDesyncEnabled, function(v)
		asyncDesyncEnabled = v
		if v and LP.Character then setupDesync(LP.Character) end
	end)
	makeSlider("Desync Duration", 0.05, 1.00, desyncDuration, function(v)
		desyncDuration = v
	end)
	makeWarning("⚠ WARNING  •  Recommended: 0.15\nHigher values look extremely obvious and increase ban risk!")
end

function buildVisuals()
	makeToggle("Hitbox ESP", hitboxVisible, function(v)
		hitboxVisible = v
		updateHitboxes(hitboxSize)
	end)
	makeToggle("Direction ESP", espEnabled, function(v)
		espEnabled = v
		if not v then clearESP() end
	end)
end

LP.CharacterAdded:Connect(function(char)
	task.wait(0.35)
	if shiftlockEnabled then setupShiftlock(char) end
	if asyncDesyncEnabled then setupDesync(char) end
end)

task.defer(function()
	switchTab("Main")
	print("JOSSEPOPSIER loaded - Silent Spike added")
end)
