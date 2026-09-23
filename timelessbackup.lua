-- TIMELESS Script Hub (WindUI) - Server Users Only
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

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
local showUsers = true

local highlights = {}
local billboards = {}
local itemHighlights = {}
local itemLabels = {}
local trapHighlights = {}
local rebelHighlights = {}
local completedWireboxes = {}
local wireboxCooldowns = {}
local knownUsers = {}

-- ===================== CUSTOM NOTIFICATION =====================
local function Notify(title, content, duration)
	duration = duration or 5

	local gui = Instance.new("ScreenGui")
	gui.Name = "TimelessNotify"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PG

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 280, 0, 85)
	frame.Position = UDim2.new(1, 20, 0, 80)
	frame.BackgroundColor3 = Color3.fromRGB(22, 18, 32)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 50, 255)
	stroke.Thickness = 1.2
	stroke.Parent = frame

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -16, 0, 24)
	titleLbl.Position = UDim2.new(0, 10, 0, 8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title
	titleLbl.TextColor3 = Color3.fromRGB(180, 50, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 15
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = frame

	local contentLbl = Instance.new("TextLabel")
	contentLbl.Size = UDim2.new(1, -16, 0, 45)
	contentLbl.Position = UDim2.new(0, 10, 0, 32)
	contentLbl.BackgroundTransparency = 1
	contentLbl.Text = content
	contentLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
	contentLbl.Font = Enum.Font.Gotham
	contentLbl.TextSize = 13
	contentLbl.TextWrapped = true
	contentLbl.TextXAlignment = Enum.TextXAlignment.Left
	contentLbl.TextYAlignment = Enum.TextYAlignment.Top
	contentLbl.Parent = frame

	TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
		Position = UDim2.new(1, -300, 0, 80)
	}):Play()

	task.delay(duration, function()
		local tween = TweenService:Create(frame, TweenInfo.new(0.3), {
			Position = UDim2.new(1, 20, 0, 80)
		})
		tween:Play()
		tween.Completed:Wait()
		gui:Destroy()
	end)
end

-- ===================== MARK USER =====================
local function markAsUser()
	pcall(function()
		if not LP:FindFirstChild("TIMELESS_USER") then
			local marker = Instance.new("BoolValue")
			marker.Name = "TIMELESS_USER"
			marker.Value = true
			marker.Parent = LP
		end
	end)
end

markAsUser()
LP.CharacterAdded:Connect(function()
	task.wait(1)
	markAsUser()
end)

-- ===================== SERVER USERS =====================
local function getOtherUsers()
	local users = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr:FindFirstChild("TIMELESS_USER") then
			table.insert(users, plr.Name)
		end
	end
	return users
end

local function notifyUsers()
	local users = getOtherUsers()
	local serverCount = #users + 1

	local content
	if #users > 0 then
		content = "Server: " .. serverCount .. " user(s)\nOthers: " .. table.concat(users, ", ")
	else
		content = "Server: 1 user (only you)\nNo other TIMELESS users found"
	end

	Notify("TIMELESS Users", content, 6)
end

-- Detect new users joining
task.spawn(function()
	while true do
		task.wait(6)
		if showUsers then
			local users = getOtherUsers()
			for _, name in ipairs(users) do
				if not knownUsers[name] then
					knownUsers[name] = true
					Notify("New TIMELESS User", name .. " is also using TIMELESS", 5)
				end
			end
			for name in pairs(knownUsers) do
				local stillHere = false
				for _, u in ipairs(users) do
					if u == name then stillHere = true break end
				end
				if not stillHere then
					knownUsers[name] = nil
				end
			end
		end
	end
end)

-- ===================== STARTUP =====================
task.spawn(function()
	task.wait(1.5)
	Notify("TIMELESS Loaded", "Found any bugs or suggestions?\nLeave a comment on ScriptBlox.", 6)

	task.wait(1.5)
	notifyUsers()
end)

-- ===================== LIGHTING =====================
local function applyFullbright()
	Lighting.Brightness = 5
	Lighting.ClockTime = 12
	Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 1000000
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then atmo.Density = 0 atmo.Haze = 0 atmo.Glare = 0 end
end

local function applyNoFog()
	Lighting.FogEnd = 1000000
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then atmo.Density = 0 atmo.Haze = 0 atmo.Glare = 0 end
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
				if completedWireboxes[parent] or wireboxCooldowns[parent] then continue end
				wireboxCooldowns[parent] = true
				local delayTime = math.random(7, 12)
				task.spawn(function()
					task.wait(delayTime)
					if autoWirebox and parent and parent.Parent then
						pcall(function()
							if obj:IsA("RemoteEvent") then obj:FireServer() else obj:InvokeServer() end
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
		if autoWirebox then completeWireboxesDelayed() end
	end
end)

-- ===================== AUTO HAMMER =====================
local function tryPickupHammer()
	local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		if name:find("doomhammer") or name == "hammer" then
			local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
			if part and (myRoot.Position - part.Position).Magnitude < 22 then
				local prompt = obj:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildOfClass("ProximityPrompt")
				if prompt then pcall(function() fireproximityprompt(prompt) end) end
				local click = obj:FindFirstChildOfClass("ClickDetector") or part:FindFirstChildOfClass("ClickDetector")
				if click then pcall(function() fireclickdetector(click) end) end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.7)
		if autoHammer then tryPickupHammer() end
	end
end)

-- ===================== ITEM ESP =====================
local function clearItemESP()
	for obj, h in pairs(itemHighlights) do pcall(function() h:Destroy() end) end
	for obj, b in pairs(itemLabels) do pcall(function() b:Destroy() end) end
	itemHighlights = {}
	itemLabels = {}
end

local function updateItemESP()
	clearItemESP()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		local color, labelText = nil, nil
		if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder") then
			local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
			if gasESP and (name:find("gascanister") or name:find("gas canister")) then
				color = Color3.fromRGB(255, 170, 0)
				labelText = "Gas"
			elseif medkitESP and name:find("medkit") then
				color = Color3.fromRGB(0, 255, 100)
				labelText = "Medkit"
			elseif slateskinESP and (name:find("slateskin") or name:find("slate skin")) then
				color = Color3.fromRGB(180, 100, 255)
				labelText = "Slateskin"
			elseif wireboxESP and name == "wirebox" then
				color = (completedWireboxes[obj] or not obj:FindFirstChild("CompleteObjective")) and Color3.fromRGB(0, 255, 80) or Color3.fromRGB(0, 220, 255)
				labelText = completedWireboxes[obj] and "Wirebox ✓" or "Wirebox"
			elseif healingPotionESP and (name:find("healingpotion") or name:find("heal potion")) and not parentName:find("station") then
				color = Color3.fromRGB(100, 255, 180)
				labelText = "Heal"
			elseif bloxyColaESP and (name:find("bloxycola") or name:find("cola")) then
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
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = obj
				itemHighlights[obj] = highlight

				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part and labelText then
					local bb = Instance.new("BillboardGui")
					bb.Adornee = part
					bb.Size = UDim2.new(0, 60, 0, 16)
					bb.StudsOffset = Vector3.new(0, 2.2, 0)
					bb.AlwaysOnTop = true
					bb.MaxDistance = 120
					bb.Parent = obj
					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = labelText
					label.TextColor3 = color
					label.TextStrokeTransparency = 0.3
					label.Font = Enum.Font.GothamBold
					label.TextSize = 11
					label.Parent = bb
					itemLabels[obj] = bb
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

-- ===================== TRAP + REBEL =====================
local function clearTrapRebel()
	for obj, h in pairs(trapHighlights) do pcall(function() h:Destroy() end) end
	for obj, h in pairs(rebelHighlights) do pcall(function() h:Destroy() end) end
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
				local h = Instance.new("Highlight")
				h.Adornee = obj
				h.FillColor = Color3.fromRGB(255, 60, 60)
				h.OutlineColor = Color3.fromRGB(255, 60, 60)
				h.FillTransparency = 0.5
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = obj
				trapHighlights[obj] = h
			elseif name:find("rebel") then
				local h = Instance.new("Highlight")
				h.Adornee = obj
				h.FillColor = Color3.fromRGB(255, 40, 40)
				h.OutlineColor = Color3.fromRGB(255, 40, 40)
				h.FillTransparency = 0.5
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = obj
				rebelHighlights[obj] = h
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
	if highlights[player] then pcall(function() highlights[player]:Destroy() end) highlights[player] = nil end
	if billboards[player] then pcall(function() billboards[player]:Destroy() end) billboards[player] = nil end
end

local function isEntity(player)
	return player.Team and player.Team.Name == "Entities"
end

local function isSurvivor(player)
	return player.Team and player.Team.Name == "Survivors"
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
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = char
	highlights[player] = highlight

	local bb = Instance.new("BillboardGui")
	bb.Adornee = root
	bb.Size = UDim2.new(0, 140, 0, isEnt and 24 or 42)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 500
	bb.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, isEnt and 1 or 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = isEnt and (player.Name .. " [ENTITY]") or player.Name
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.Parent = bb

	if not isEnt then
		local hp = Instance.new("TextLabel")
		hp.Size = UDim2.new(1, 0, 0.5, 0)
		hp.Position = UDim2.new(0, 0, 0.5, 0)
		hp.BackgroundTransparency = 1
		hp.Text = "HP: " .. math.floor(hum.Health)
		hp.TextColor3 = Color3.fromRGB(0, 255, 100)
		hp.TextStrokeTransparency = 0.2
		hp.Font = Enum.Font.Gotham
		hp.TextSize = 13
		hp.Parent = bb
		hum.HealthChanged:Connect(function()
			if hp and hp.Parent then hp.Text = "HP: " .. math.floor(hum.Health) end
		end)
	end
	billboards[player] = bb
end

local function updateESP()
	if not espEnabled then
		for plr in pairs(highlights) do cleanup(plr) end
		clearTrapRebel()
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if isEntity(player) or isSurvivor(player) then
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
		task.wait(1.2)
		updateESP()
	end
end)

Players.PlayerRemoving:Connect(cleanup)

-- ===================== CARRY / REVIVE =====================
local CharacterEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("CharacterEvents")
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
				if dist < shortest then shortest = dist closest = plr.Character end
			end
		end
	end
	return closest
end

task.spawn(function()
	while true do
		task.wait(1)
		if autoCarry and RequestCarry then
			local t = getClosestDowned()
			if t then pcall(function() RequestCarry:FireServer(t) end) end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if autoRevive and RequestRevive then
			local t = getClosestDowned()
			if t then pcall(function() RequestRevive:FireServer(t) end) end
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

local EntityTab = Window:Tab({ Title = "Entity", Icon = "skull" })
EntityTab:Paragraph({ Title = "Note", Desc = "Adding features soon\nWork in progress" })

local SurvivorTab = Window:Tab({ Title = "Survivor", Icon = "user" })
SurvivorTab:Toggle({ Title = "Auto Carry", Value = false, Callback = function(v) autoCarry = v end })
SurvivorTab:Toggle({ Title = "Auto Revive", Value = false, Callback = function(v) autoRevive = v end })
SurvivorTab:Toggle({ Title = "Auto Wirebox", Value = false, Callback = function(v) autoWirebox = v end })
SurvivorTab:Toggle({ Title = "Auto Pickup Hammer", Value = false, Callback = function(v) autoHammer = v end })
SurvivorTab:Paragraph({ Title = "Info", Desc = "Auto Wirebox waits 7-12 seconds" })

local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
VisualsTab:Toggle({
	Title = "Player ESP",
	Value = true,
	Callback = function(v)
		espEnabled = v
		if not v then
			for plr in pairs(highlights) do cleanup(plr) end
			clearTrapRebel()
		end
	end
})
VisualsTab:Paragraph({ Title = "Note", Desc = "Trap + Rebel ESP included with Player ESP" })
VisualsTab:Toggle({ Title = "Gas Canister ESP", Value = false, Callback = function(v) gasESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Medkit ESP", Value = false, Callback = function(v) medkitESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Wirebox ESP", Value = false, Callback = function(v) wireboxESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Slateskin Potion ESP", Value = false, Callback = function(v) slateskinESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Healing Potion ESP", Value = false, Callback = function(v) healingPotionESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Bloxy Cola ESP", Value = false, Callback = function(v) bloxyColaESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Crate ESP", Value = false, Callback = function(v) crateESP = v updateItemESP() end })

local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
MiscTab:Toggle({ Title = "Fullbright", Value = false, Callback = function(v) fullbrightEnabled = v if v then applyFullbright() end end })
MiscTab:Toggle({ Title = "No Fog", Value = false, Callback = function(v) noFogEnabled = v if v then applyNoFog() end end })
MiscTab:Toggle({ Title = "Show Other Users", Value = true, Callback = function(v) showUsers = v end })
MiscTab:Button({
	Title = "Check TIMELESS Users",
	Callback = function()
		notifyUsers()
	end
})

print("TIMELESS Hub loaded")
