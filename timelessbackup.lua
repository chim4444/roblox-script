-- TIMELESS Script Hub (WindUI)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Teams = game:GetService("Teams")
local LP = Players.LocalPlayer

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- ===================== STATES =====================
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
local itemLabels = {}
local trapHighlights = {}
local rebelHighlights = {}
local completedWireboxes = {}
local wireboxCooldowns = {}

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

-- ===================== AUTO WIREBOX =====================
local function completeWireboxesDelayed()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if (obj.Name == "CompleteObjective" or obj.Name == "Complete") and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
			local parent = obj.Parent
			if parent and (parent.Name == "Wirebox" or string.lower(parent.Name):find("wire")) then
				if completedWireboxes[parent] or wireboxCooldowns[parent] then
					continue
				end

				wireboxCooldowns[parent] = true
				local delayTime = math.random(7, 12)

				task.spawn(function()
					task.wait(delayTime)
					if autoWirebox and parent and parent.Parent then
						pcall(function()
							if obj:IsA("RemoteEvent") then
								obj:FireServer()
							else
								obj:InvokeServer()
							end
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
		task.wait(2.5)
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
local function clearItemESP()
	for obj, h in pairs(itemHighlights) do
		pcall(function() h:Destroy() end)
	end
	for obj, b in pairs(itemLabels) do
		pcall(function() b:Destroy() end)
	end
	itemHighlights = {}
	itemLabels = {}
end

local function updateItemESP()
	clearItemESP()

	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		local color, labelText = nil, nil

		if (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder")) then
			local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""

			if gasESP and (name:find("gascanister") or name:find("gas canister") or name:find("gas_canister")) then
				color = Color3.fromRGB(255, 170, 0)
				labelText = "Gas"
			elseif medkitESP and (name:find("medkit") or name:find("med kit")) then
				color = Color3.fromRGB(0, 255, 100)
				labelText = "Medkit"
			elseif slateskinESP and (name:find("slateskin") or name:find("slate skin") or name:find("slateskinpotion")) then
				color = Color3.fromRGB(180, 100, 255)
				labelText = "Slateskin"
			elseif wireboxESP and name == "wirebox" then
				if completedWireboxes[obj] or not obj:FindFirstChild("CompleteObjective") then
					color = Color3.fromRGB(0, 255, 80)
					labelText = "Wirebox ✓"
				else
					color = Color3.fromRGB(0, 220, 255)
					labelText = "Wirebox"
				end
			elseif healingPotionESP and (name:find("healingpotion") or name == "healing potion" or name == "heal potion") and not parentName:find("station") and not name:find("station") then
				color = Color3.fromRGB(100, 255, 180)
				labelText = "Heal"
			elseif bloxyColaESP and (name:find("bloxycola") or name:find("bloxy cola") or name:find("cola")) then
				color = Color3.fromRGB(255, 80, 80)
				labelText = "Cola"
			elseif crateESP and name == "crate" then
				color = Color3.fromRGB(255, 200, 50)
				labelText = "Crate"
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

				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part and labelText then
					local billboard = Instance.new("BillboardGui")
					billboard.Adornee = part
					billboard.Size = UDim2.new(0, 60, 0, 16)
					billboard.StudsOffset = Vector3.new(0, 2.2, 0)
					billboard.AlwaysOnTop = true
					billboard.MaxDistance = 120
					billboard.Parent = obj

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = labelText
					label.TextColor3 = color
					label.TextStrokeTransparency = 0.3
					label.Font = Enum.Font.GothamBold
					label.TextSize = 11
					label.Parent = billboard

					itemLabels[obj] = billboard
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(3)
		updateItemESP()
	end
end)

-- ===================== TRAP + REBEL ESP =====================
local function clearTrapRebel()
	for obj, h in pairs(trapHighlights) do
		pcall(function() h:Destroy() end)
	end
	for obj, h in pairs(rebelHighlights) do
		pcall(function() h:Destroy() end)
	end
	trapHighlights = {}
	rebelHighlights = {}
end

local function updateTrapRebelESP()
	clearTrapRebel()
	if not espEnabled then return end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)

		if obj:IsA("Model") or obj:IsA("BasePart") then
			if name == "trapmodel" or name:find("trap") then
				local highlight = Instance.new("Highlight")
				highlight.Adornee = obj
				highlight.FillColor = Color3.fromRGB(255, 60, 60)
				highlight.OutlineColor = Color3.fromRGB(255, 60, 60)
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = obj
				trapHighlights[obj] = highlight

			elseif name:find("rebel") then
				local highlight = Instance.new("Highlight")
				highlight.Adornee = obj
				highlight.FillColor = Color3.fromRGB(255, 40, 40)
				highlight.OutlineColor = Color3.fromRGB(255, 40, 40)
				highlight.FillTransparency = 0.5
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = obj
				rebelHighlights[obj] = highlight

				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part then
					local billboard = Instance.new("BillboardGui")
					billboard.Adornee = part
					billboard.Size = UDim2.new(0, 50, 0, 16)
					billboard.StudsOffset = Vector3.new(0, 2.5, 0)
					billboard.AlwaysOnTop = true
					billboard.MaxDistance = 200
					billboard.Parent = obj

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = "Bot"
					label.TextColor3 = Color3.fromRGB(255, 40, 40)
					label.TextStrokeTransparency = 0.3
					label.Font = Enum.Font.GothamBold
					label.TextSize = 12
					label.Parent = billboard
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		updateTrapRebelESP()
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
	if not player.Team then return false end
	return player.Team.Name == "Entities"
end

local function isSurvivor(player)
	if not player.Team then return false end
	return player.Team.Name == "Survivors"
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
		clearTrapRebel()
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP then
			if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character:FindFirstChild("HumanoidRootPart") then
				if isEntity(player) or isSurvivor(player) then
					local isEnt = isEntity(player)
					if not highlights[player] or highlights[player].Adornee ~= player.Character then
						createESP(player, isEnt)
					end
				else
					cleanup(player)
				end
			else
				cleanup(player)
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1.2)
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
		if plr ~= LP and plr.Character and isSurvivor(plr) then
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

-- ===================== WINDUI =====================
local Window = WindUI:CreateWindow({
	Title = "TIMELESS",
	Icon = "star",
	Theme = "Dark",
	Folder = "TimelessHub"
})

-- Entity Tab
local EntityTab = Window:Tab({
	Title = "Entity",
	Icon = "skull"
})

EntityTab:Paragraph({
	Title = "Note",
	Desc = "Adding features soon\nWork in progress"
})

-- Survivor Tab
local SurvivorTab = Window:Tab({
	Title = "Survivor",
	Icon = "user"
})

SurvivorTab:Toggle({
	Title = "Auto Carry",
	Value = false,
	Callback = function(v)
		autoCarry = v
	end
})

SurvivorTab:Toggle({
	Title = "Auto Revive",
	Value = false,
	Callback = function(v)
		autoRevive = v
	end
})

SurvivorTab:Toggle({
	Title = "Auto Wirebox",
	Value = false,
	Callback = function(v)
		autoWirebox = v
	end
})

SurvivorTab:Toggle({
	Title = "Auto Pickup Hammer",
	Value = false,
	Callback = function(v)
		autoHammer = v
	end
})

SurvivorTab:Paragraph({
	Title = "Info",
	Desc = "Auto Wirebox waits 7-12 seconds before completing"
})

-- Visuals Tab
local VisualsTab = Window:Tab({
	Title = "Visuals",
	Icon = "eye"
})

VisualsTab:Toggle({
	Title = "Player ESP",
	Value = true,
	Callback = function(v)
		espEnabled = v
		if not v then
			for plr, _ in pairs(highlights) do
				cleanup(plr)
			end
			clearTrapRebel()
		end
	end
})

VisualsTab:Paragraph({
	Title = "Note",
	Desc = "Trap + Rebel ESP included with Player ESP"
})

VisualsTab:Toggle({
	Title = "Gas Canister ESP",
	Value = false,
	Callback = function(v)
		gasESP = v
		updateItemESP()
	end
})

VisualsTab:Toggle({
	Title = "Medkit ESP",
	Value = false,
	Callback = function(v)
		medkitESP = v
		updateItemESP()
	end
})

VisualsTab:Toggle({
	Title = "Wirebox ESP",
	Value = false,
	Callback = function(v)
		wireboxESP = v
		updateItemESP()
	end
})

VisualsTab:Toggle({
	Title = "Slateskin Potion ESP",
	Value = false,
	Callback = function(v)
		slateskinESP = v
		updateItemESP()
	end
})

VisualsTab:Toggle({
	Title = "Healing Potion ESP",
	Value = false,
	Callback = function(v)
		healingPotionESP = v
		updateItemESP()
	end
})

VisualsTab:Toggle({
	Title = "Bloxy Cola ESP",
	Value = false,
	Callback = function(v)
		bloxyColaESP = v
		updateItemESP()
	end
})

VisualsTab:Toggle({
	Title = "Crate ESP",
	Value = false,
	Callback = function(v)
		crateESP = v
		updateItemESP()
	end
})

-- Misc Tab
local MiscTab = Window:Tab({
	Title = "Misc",
	Icon = "settings"
})

MiscTab:Toggle({
	Title = "Fullbright",
	Value = false,
	Callback = function(v)
		fullbrightEnabled = v
		if v then applyFullbright() end
	end
})

MiscTab:Toggle({
	Title = "No Fog",
	Value = false,
	Callback = function(v)
		noFogEnabled = v
		if v then applyNoFog() end
	end
})

print("TIMELESS Hub (WindUI) loaded")
