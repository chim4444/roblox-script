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
local fullbrightEnabled = false
local noFogEnabled = false

local highlights = {}
local billboards = {}
local itemHighlights = {}

-- Save original lighting
local oldAmbient = Lighting.Ambient
local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldFogEnd = Lighting.FogEnd
local oldFogStart = Lighting.FogStart
local oldGlobalShadows = Lighting.GlobalShadows
local oldOutdoorAmbient = Lighting.OutdoorAmbient

-- ===================== FULLBRIGHT + NO FOG =====================
local function applyFullbright(state)
	if state then
		Lighting.Brightness = 5
		Lighting.ClockTime = 12
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 1000000
		Lighting.FogStart = 0
		Lighting.FogColor = Color3.fromRGB(255, 255, 255)

		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			atmosphere.Density = 0
			atmosphere.Haze = 0
			atmosphere.Glare = 0
		end
	else
		Lighting.Brightness = oldBrightness
		Lighting.ClockTime = oldClockTime
		Lighting.Ambient = oldAmbient
		Lighting.OutdoorAmbient = oldOutdoorAmbient
		Lighting.GlobalShadows = oldGlobalShadows
		Lighting.FogEnd = oldFogEnd
		Lighting.FogStart = oldFogStart
	end
end

local function applyNoFog(state)
	if state then
		Lighting.FogEnd = 1000000
		Lighting.FogStart = 0
		Lighting.FogColor = Color3.fromRGB(255, 255, 255)

		local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmosphere then
			atmosphere.Density = 0
			atmosphere.Offset = 0
			atmosphere.Haze = 0
			atmosphere.Glare = 0
		end

		for _, effect in ipairs(Lighting:GetChildren()) do
			if effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
				effect.Enabled = false
			end
		end
	else
		Lighting.FogEnd = oldFogEnd
		Lighting.FogStart = oldFogStart
	end
end

-- ===================== ITEM ESP =====================
local function clearItemESP()
	for obj, h in pairs(itemHighlights) do
		pcall(function() h:Destroy() end)
	end
	table.clear(itemHighlights)
end

local function updateItemESP()
	-- Remove highlights for objects that no longer exist
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

			if gasESP and (name:find("gascanister") or name:find("gas canister") or name:find("gas_canister")) then
				color = Color3.fromRGB(255, 170, 0) -- Orange
			elseif medkitESP and (name:find("medkit") or name:find("med kit")) then
				color = Color3.fromRGB(0, 255, 100) -- Green
			elseif slateskinESP and (name:find("slateskin") or name:find("slate skin") or name:find("slateskinpotion")) then
				color = Color3.fromRGB(180, 100, 255) -- Purple
			elseif wireboxESP and name == "wirebox" then
				color = Color3.fromRGB(0, 220, 255) -- Cyan
			elseif healingPotionESP and (name:find("healingpotion") or name:find("healing potion")) then
				color = Color3.fromRGB(100, 255, 180) -- Light green
			elseif bloxyColaESP and (name:find("bloxycola") or name:find("bloxy cola")) then
				color = Color3.fromRGB(255, 80, 80) -- Red
			elseif crateESP and name == "crate" then
				color = Color3.fromRGB(255, 200, 50) -- Yellow
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
		task.wait(0.8)
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
				else
					local color = isEnt and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(40, 140, 255)
					if highlights[player].FillColor ~= color then
						createESP(player, isEnt)
					end
				end
			else
				cleanup(player)
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.3)
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
		task.wait(0.5)
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
		task.wait(0.5)
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
Main.Size = UDim2.new(0, 400, 0, 360)
Main.Position = UDim2.new(0.5, -200, 0.5, -180)
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

-- Drag
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

-- UI Toggle
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

-- Sidebar
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
	note.Size = UDim2.new(1, -10, 0, 60)
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

	elseif name == "Visuals" then
		makeToggle("Player ESP", espEnabled, function(v)
			espEnabled = v
			if not v then
				for plr, _ in pairs(highlights) do
					cleanup(plr)
				end
			end
		end)
		makeToggle("Gas Canister ESP", gasESP, function(v)
			gasESP = v
			updateItemESP()
		end)
		makeToggle("Medkit ESP", medkitESP, function(v)
			medkitESP = v
			updateItemESP()
		end)
		makeToggle("Wirebox ESP", wireboxESP, function(v)
			wireboxESP = v
			updateItemESP()
		end)
		makeToggle("Slateskin Potion ESP", slateskinESP, function(v)
			slateskinESP = v
			updateItemESP()
		end)
		makeToggle("Healing Potion ESP", healingPotionESP, function(v)
			healingPotionESP = v
			updateItemESP()
		end)
		makeToggle("Bloxy Cola ESP", bloxyColaESP, function(v)
			bloxyColaESP = v
			updateItemESP()
		end)
		makeToggle("Crate ESP", crateESP, function(v)
			crateESP = v
			updateItemESP()
		end)

	elseif name == "Misc" then
		makeToggle("Fullbright", fullbrightEnabled, function(v)
			fullbrightEnabled = v
			applyFullbright(v)
		end)
		makeToggle("No Fog", noFogEnabled, function(v)
			noFogEnabled = v
			applyNoFog(v)
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
print("TIMELESS Hub loaded - new item ESPs + auto remove")
