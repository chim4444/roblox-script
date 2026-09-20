-- TIMELESS Script Hub
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local PG = LP:WaitForChild("PlayerGui")
if PG:FindFirstChild("TimelessHub") then PG.TimelessHub:Destroy() end

local UI = Instance.new("ScreenGui")
UI.Name = "TimelessHub"
UI.ResetOnSpawn = false
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = PG

-- Colors
local ACCENT = Color3.fromRGB(180, 50, 255)
local BG = Color3.fromRGB(18, 18, 24)
local CARD = Color3.fromRGB(28, 28, 36)
local TEXT = Color3.fromRGB(240, 240, 245)
local DIM = Color3.fromRGB(140, 140, 155)

-- States
local espEnabled = true
local gasESP = false
local medkitESP = false
local wireboxESP = false
local slateskinESP = false
local healingPotionESP = false
local bloxyColaESP = false
local crateESP = false
local autoCarry = false
local autoRevive = false
local autoWirebox = false
local autoHammer = false
local fullbrightEnabled = false
local noFogEnabled = false

local highlights = {}
local billboards = {}
local itemHighlights = {}
local completedWireboxes = {}
local wireboxCooldowns = {}

-- ===================== STARTUP NOTE =====================
task.spawn(function()
	local note = Instance.new("Frame")
	note.Size = UDim2.new(0, 340, 0, 125)
	note.Position = UDim2.new(0.5, -170, 0.15, 0)
	note.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
	note.BorderSizePixel = 0
	note.ZIndex = 50
	note.Parent = UI
	Instance.new("UICorner", note).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 1.5
	stroke.Parent = note

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -50, 0, 28)
	title.Position = UDim2.new(0, 12, 0, 8)
	title.BackgroundTransparency = 1
	title.Text = "TIMELESS"
	title.TextColor3 = ACCENT
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 51
	title.Parent = note

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 28, 0, 28)
	closeBtn.Position = UDim2.new(1, -34, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = TEXT
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.ZIndex = 52
	closeBtn.Parent = note
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

	closeBtn.MouseButton1Click:Connect(function()
		note:Destroy()
	end)

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -24, 0, 75)
	msg.Position = UDim2.new(0, 12, 0, 40)
	msg.BackgroundTransparency = 1
	msg.Text = "Found any bugs or have suggestions?\nLeave a comment on ScriptBlox.\nThinking about making a Discord — lmk"
	msg.TextColor3 = TEXT
	msg.Font = Enum.Font.Gotham
	msg.TextSize = 14
	msg.TextWrapped = true
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.TextYAlignment = Enum.TextYAlignment.Top
	msg.ZIndex = 51
	msg.Parent = note
end)

-- ===================== FULLBRIGHT + NO FOG =====================
local function applyFullbright()
	Lighting.Brightness = 5
	Lighting.ClockTime = 12
	Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 1000000
	Lighting.FogStart = 0

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0
		atmosphere.Haze = 0
		atmosphere.Glare = 0
	end
end

local function applyNoFog()
	Lighting.FogEnd = 1000000
	Lighting.FogStart = 0

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0
		atmosphere.Haze = 0
		atmosphere.Glare = 0
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		if fullbrightEnabled then applyFullbright() end
		if noFogEnabled then applyNoFog() end
	end
end)

-- ===================== AUTO WIREBOX (7-12 sec) =====================
local function completeWireboxesDelayed()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name == "CompleteObjective" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
			local parent = obj.Parent
			if parent and parent.Name == "Wirebox" then
				if completedWireboxes[parent] or wireboxCooldowns[parent] then
					continue
				end

				wireboxCooldowns[parent] = true
				local delayTime = math.random(7, 12)

				task.spawn(function()
					task.wait(delayTime)
					if autoWirebox and parent and parent.Parent then
						pcall(function()
							obj:FireServer()
						end)
						completedWireboxes[parent] = true
					end
					wireboxCooldowns[parent] = nil
				end)
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(3)
		if autoWirebox then
			completeWireboxesDelayed()
		end
	end
end)

-- ===================== AUTO PICKUP HAMMER =====================
local function tryPickupHammer()
	local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = obj.Name:lower()
		if name:find("doomhammer") or name == "hammer" then
			local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
			if part then
				local dist = (myRoot.Position - part.Position).Magnitude
				if dist < 22 then
					local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
					if prompt then
						pcall(function() fireproximityprompt(prompt) end)
					end

					local click = obj:FindFirstChildOfClass("ClickDetector") or part:FindFirstChildOfClass("ClickDetector")
					if click then
						pcall(function() fireclickdetector(click) end)
					end
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.7)
		if autoHammer then
			tryPickupHammer()
		end
	end
end)

-- ===================== ITEM ESP =====================
local function updateItemESP()
	for obj, h in pairs(itemHighlights) do
		if not obj or not obj.Parent then
			pcall(function() h:Destroy() end)
			itemHighlights[obj] = nil
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)

		if (obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart")) and not itemHighlights[obj] then
			local color = nil

			if gasESP and (name:find("gascanister") or name:find("gas canister")) then
				color = Color3.fromRGB(255, 170, 0)
			elseif medkitESP and name:find("medkit") then
				color = Color3.fromRGB(0, 255, 100)
			elseif slateskinESP and (name:find("slateskin") or name:find("slate skin")) then
				color = Color3.fromRGB(180, 100, 255)
			elseif wireboxESP and name == "wirebox" then
				if completedWireboxes[obj] or not obj:FindFirstChild("CompleteObjective") then
					color = Color3.fromRGB(0, 255, 80)
				else
					color = Color3.fromRGB(0, 220, 255)
				end
			elseif healingPotionESP and name:find("healingpotion") then
				color = Color3.fromRGB(100, 255, 180)
			elseif bloxyColaESP and name:find("bloxycola") then
				color = Color3.fromRGB(255, 80, 80)
			elseif crateESP and name == "crate" then
				color = Color3.fromRGB(255, 200, 50)
			end

			if color then
				local highlight = Instance.new("Highlight")
				highlight.Adornee = obj
				highlight.FillColor = color
				highlight.OutlineColor = color
				highlight.FillTransparency = 0.55
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = obj
				itemHighlights[obj] = highlight
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(3.5)
		updateItemESP()
	end
end)

-- ===================== PLAYER ESP =====================
local function cleanup(player)
	if highlights[player] then
		pcall(function() highlights[player]:Destroy() end)
		highlights[player] = nil
	end
	if billboards[player] then
		pcall(function() billboards[player]:Destroy() end)
		billboards[player] = nil
	end
end

local function isEntity(player)
	if not player.Character then return false end
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	return hum.MaxHealth > 500
end

local function createESP(player, isEnt)
	if not player.Character then return end
	cleanup(player)

	local char = player.Character
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	local color = isEnt and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(40, 140, 255)

	local highlight = Instance.new("Highlight")
	highlight.Adornee = char
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char
	highlights[player] = highlight

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESPInfo"
	billboard.Adornee = root
	billboard.Size = UDim2.new(0, 140, 0, isEnt and 24 or 42)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 500
	billboard.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, isEnt and 1 or 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = isEnt and (player.Name .. " [ENTITY]") or player.Name
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = billboard

	if not isEnt then
		local healthLabel = Instance.new("TextLabel")
		healthLabel.Name = "HealthLabel"
		healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
		healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
		healthLabel.BackgroundTransparency = 1
		healthLabel.Text = "HP: " .. math.floor(hum.Health)
		healthLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		healthLabel.TextStrokeTransparency = 0.2
		healthLabel.Font = Enum.Font.Gotham
		healthLabel.TextSize = 13
		healthLabel.Parent = billboard

		hum.HealthChanged:Connect(function()
			if healthLabel and healthLabel.Parent then
				healthLabel.Text = "HP: " .. math.floor(hum.Health)
			end
		end)
	end

	billboards[player] = billboard
end

local function updateESP()
	if not espEnabled then
		for plr, _ in pairs(highlights) do
			cleanup(plr)
		end
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP then
			if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
				local isEnt = isEntity(player)
				if not highlights[player] or highlights[player].Adornee ~= player.Character then
					createESP(player, isEnt)
				end
			else
				cleanup(player)
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1.5)
		updateESP()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cleanup(player)
end)

-- ===================== CARRY / REVIVE =====================
local CharacterEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") 
	and ReplicatedStorage.RemoteEvents:FindFirstChild("CharacterEvents")

local RequestCarry = CharacterEvents and CharacterEvents:FindFirstChild("RequestCarry")
local RequestRevive = CharacterEvents and CharacterEvents:FindFirstChild("RequestRevive")

local function getClosestDowned()
	local closest, shortest = nil, 40
	local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.4 then
				local dist = (myRoot.Position - root.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closest = plr.Character
				end
			end
		end
	end
	return closest
end

task.spawn(function()
	while true do
		task.wait(1)
		if autoCarry and RequestCarry then
			local target = getClosestDowned()
			if target then
				pcall(function() RequestCarry:FireServer(target) end)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if autoRevive and RequestRevive then
			local target = getClosestDowned()
			if target then
				pcall(function() RequestRevive:FireServer(target) end)
			end
		end
	end
end)

-- ===================== UI =====================
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 400, 0, 400)
Main.Position = UDim2.new(0.5, -200, 0.5, -200)
Main.BackgroundColor3 = BG
Main.BorderSizePixel = 0
Main.Parent = UI
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 28)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "TIMELESS"
title.TextColor3 = ACCENT
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = Main

local dragging, dragStart, startPos
Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 70, 0, 30)
hideBtn.Position = UDim2.new(1, -85, 0, 70)
hideBtn.BackgroundColor3 = ACCENT
hideBtn.Text = "HIDE"
hideBtn.TextColor3 = TEXT
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
		hStartPos = hideBtn.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if hDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - hDragStart
		hideBtn.Position = UDim2.new(hStartPos.X.Scale, hStartPos.X.Offset + delta.X, hStartPos.Y.Scale, hStartPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		hDragging = false
	end
end)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 100, 1, -45)
sidebar.Position = UDim2.new(0, 10, 0, 40)
sidebar.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
sidebar.BorderSizePixel = 0
sidebar.Parent = Main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -125, 1, -50)
content.Position = UDim2.new(0, 115, 0, 42)
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
padding.PaddingBottom = UDim.new(0, 8)
padding.Parent = content

local currentTab = nil
local tabButtons = {}

local function clearContent()
	for _, c in ipairs(content:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function makeToggle(text, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -10, 0, 36)
	row.BackgroundColor3 = CARD
	row.BorderSizePixel = 0
	row.Parent = content
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = DIM
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 50, 0, 24)
	btn.Position = UDim2.new(1, -58, 0.5, -12)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	btn.Text = "OFF"
	btn.TextColor3 = DIM
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local on = default
	local function refresh()
		btn.Text = on and "ON" or "OFF"
		btn.BackgroundColor3 = on and ACCENT or Color3.fromRGB(45, 45, 55)
		btn.TextColor3 = on and TEXT or DIM
		lbl.TextColor3 = on and TEXT or DIM
	end
	refresh()

	btn.MouseButton1Click:Connect(function()
		on = not on
		refresh()
		callback(on)
	end)
end

local function makeNote(text)
	local note = Instance.new("Frame")
	note.Size = UDim2.new(1, -10, 0, 50)
	note.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
	note.BorderSizePixel = 0
	note.Parent = content
	Instance.new("UICorner", note).CornerRadius = UDim.new(0, 8)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -16, 1, 0)
	lbl.Position = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(200, 160, 255)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = note
end

local function switchTab(name)
	if currentTab == name then return end
	currentTab = name
	for id, btn in pairs(tabButtons) do
		btn.BackgroundColor3 = (id == name) and ACCENT or Color3.fromRGB(40, 40, 50)
		btn.TextColor3 = (id == name) and TEXT or DIM
	end
	clearContent()

	if name == "Entity" then
		makeNote("Adding features soon\nWork in progress")

	elseif name == "Survivor" then
		makeToggle("Auto Carry", autoCarry, function(v) autoCarry = v end)
		makeToggle("Auto Revive", autoRevive, function(v) autoRevive = v end)
		makeToggle("Auto Wirebox", autoWirebox, function(v) autoWirebox = v end)
		makeToggle("Auto Pickup Hammer", autoHammer, function(v) autoHammer = v end)
		makeNote("Auto Wirebox waits\n7-12 seconds")

	elseif name == "Visuals" then
		makeToggle("Player ESP", espEnabled, function(v)
			espEnabled = v
			if not v then
				for plr, _ in pairs(highlights) do cleanup(plr) end
			end
		end)
		makeToggle("Gas Canister ESP", gasESP, function(v) gasESP = v updateItemESP() end)
		makeToggle("Medkit ESP", medkitESP, function(v) medkitESP = v updateItemESP() end)
		makeToggle("Wirebox ESP", wireboxESP, function(v) wireboxESP = v updateItemESP() end)
		makeToggle("Slateskin Potion ESP", slateskinESP, function(v) slateskinESP = v updateItemESP() end)
		makeToggle("Healing Potion ESP", healingPotionESP, function(v) healingPotionESP = v updateItemESP() end)
		makeToggle("Bloxy Cola ESP", bloxyColaESP, function(v) bloxyColaESP = v updateItemESP() end)
		makeToggle("Crate ESP", crateESP, function(v) crateESP = v updateItemESP() end)

	elseif name == "Misc" then
		makeToggle("Fullbright", fullbrightEnabled, function(v)
			fullbrightEnabled = v
			if v then applyFullbright() end
		end)
		makeToggle("No Fog", noFogEnabled, function(v)
			noFogEnabled = v
			if v then applyNoFog() end
		end)
	end
end

local tabs = {"Entity", "Survivor", "Visuals", "Misc"}
for i, name in ipairs(tabs) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -12, 0, 34)
	btn.Position = UDim2.new(0, 6, 0, 8 + (i-1)*42)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	btn.Text = name
	btn.TextColor3 = DIM
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Parent = sidebar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	tabButtons[name] = btn
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

switchTab("Survivor")
print("TIMELESS Hub loaded")
