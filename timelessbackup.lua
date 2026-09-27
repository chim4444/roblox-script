-- TIMELESS Script Hub (WindUI) - Less blatant Grab + better Users
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
local gasESP, medkitESP, wireboxESP, slateskinESP = false, false, false, false
local healingPotionESP, bloxyColaESP, crateESP, computerESP = false, false, false, false
local autoCarry, autoRevive, autoWirebox, autoEscape = false, false, false, false
local autoBadwareComputer, autoPizzaBox = false, false
local autoPickupGas, autoPickupMedkit, autoPickupSlateskin = false, false, false
local autoPickupCola, autoPickupHealing = false, false
local fullbrightEnabled, noFogEnabled, showUsers = false, false, true
local autoSelectSurvivor = false
local selectedSurvivor = "Ace"
local autoEscapeGrab = false

local highlights, billboards = {}, {}
local itemHighlights, itemLabels = {}, {}
local trapHighlights, rebelHighlights, landmineHighlights = {}, {}, {}
local zombieHighlights, computerHighlights = {}, {}
local knownUsers = {}

local wireboxBusy, lastWireboxTime = false, 0
local escapePending, lastEscapeTeleport, escapeUsedThisRescue = false, 0, false
local lastGasPickup, lastMedkitPickup, lastSlateskinPickup = 0, 0, 0
local lastColaPickup, lastHealingPickup, lastPizzaBox = 0, 0, 0
local rescueReady, scriptLoadTime = false, tick()

local survivorList = {
	"Ace", "Aero", "Builderman", "Brighteyes", "Clockwork", "Combine Soldier",
	"Dayze", "Elliot", "Guest", "HelperBot", "Jard", "Luminos", "Matt Dusek",
	"Mr. Doombringer", "Nikilis", "Noob", "Shedletsky", "Synt4x"
}

-- ===================== CACHES =====================
local cachedComputers = {}
local cachedPizzaBoxes = {}
local lastCacheRefresh = 0
local CACHE_INTERVAL = 4

local function refreshCaches()
	if tick() - lastCacheRefresh < CACHE_INTERVAL then return end
	lastCacheRefresh = tick()
	cachedComputers = {}
	cachedPizzaBoxes = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		if name == "computer" and (obj:IsA("Model") or obj:IsA("BasePart")) then
			table.insert(cachedComputers, obj)
		elseif (name == "pizzabox" or name:find("pizza")) and (obj:IsA("Model") or obj:IsA("BasePart")) then
			table.insert(cachedPizzaBoxes, obj)
		end
	end
end

-- ===================== NOTIFY =====================
local function Notify(title, content, duration)
	duration = duration or 4
	pcall(function()
		WindUI:Notify({ Title = title, Content = content, Duration = duration })
	end)
end

-- ===================== HELPERS =====================
local function getRoot()
	local char = LP.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function findPrompt(parent)
	if not parent then return nil end
	return parent:FindFirstChildOfClass("ProximityPrompt") or parent:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function isOwnedByPlayer(obj)
	if not obj then return true end
	local current = obj
	while current and current ~= game do
		if current:IsA("Player") or current == LP.Character or current == LP:FindFirstChild("Backpack") then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isLocalSurvivor()
	return LP.Team and LP.Team.Name == "Survivors"
end

local function isEntity(p) return p.Team and p.Team.Name == "Entities" end
local function isSurvivor(p) return p.Team and p.Team.Name == "Survivors" end

local CharSelect = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("CharSelect")

-- ===================== AUTO SELECT SURVIVOR =====================
task.spawn(function()
	while true do
		task.wait(0.08)
		if autoSelectSurvivor and CharSelect and selectedSurvivor ~= "" then
			pcall(function() CharSelect:FireServer(selectedSurvivor) end)
		end
	end
end)

-- ===================== AUTO ESCAPE GRAB (less blatant) =====================
task.spawn(function()
	while true do
		task.wait(0.12) -- slower = less blatant
		if not autoEscapeGrab then continue end

		local char = LP.Character
		if not char then continue end

		local isGrabbed = false
		local escapeRemote = nil

		-- Check if we are actually grabbed
		for _, obj in ipairs(char:GetDescendants()) do
			if obj.Name == "Grabbing" and obj:IsA("BoolValue") and obj.Value == true then
				isGrabbed = true
			end
			if obj.Name == "GrabEscapeInput" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
				escapeRemote = obj
			end
		end

		-- Also check other players (entity might hold the remote)
		if not escapeRemote then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character then
					for _, obj in ipairs(plr.Character:GetDescendants()) do
						if obj.Name == "GrabEscapeInput" and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
							escapeRemote = obj
						end
						if obj.Name == "Grabbing" and obj:IsA("BoolValue") and obj.Value == true then
							isGrabbed = true
						end
					end
				end
			end
		end

		-- Only spam if actually grabbed
		if isGrabbed and escapeRemote then
			for i = 1, 4 do -- only 4 times (was 12)
				pcall(function()
					if escapeRemote:IsA("RemoteEvent") then
						escapeRemote:FireServer()
					else
						escapeRemote:InvokeServer()
					end
				end)
			end
		end
	end
end)

-- Escape detection (rescue)
Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		if not obj or not obj.Parent then return end
		if string.lower(obj.Name) ~= "escapemodel" then return end
		if not obj:IsDescendantOf(Workspace) then return end
		local path = string.lower(obj:GetFullName())
		if path:find("replicatedstorage") or tick() - scriptLoadTime < 20 then return end

		local thisModel = obj
		task.delay(3, function()
			if thisModel and thisModel.Parent and thisModel:IsDescendantOf(Workspace) then
				rescueReady = true
				escapeUsedThisRescue = false
				if autoEscape and isLocalSurvivor() then
					Notify("Auto Escape", "Rescue confirmed — ready", 3)
				end
			end
		end)
	end)
end)

Workspace.DescendantRemoving:Connect(function(obj)
	if obj and string.lower(obj.Name) == "escapemodel" then
		task.defer(function()
			local still = false
			for _, o in ipairs(Workspace:GetDescendants()) do
				if string.lower(o.Name) == "escapemodel" then
					local path = string.lower(o:GetFullName())
					if not path:find("replicatedstorage") then still = true break end
				end
			end
			if not still then
				rescueReady = false
				escapeUsedThisRescue = false
			end
		end)
	end
end)

-- ===================== USER MARK (improved) =====================
local function markAsUser()
	pcall(function()
		-- Character tag
		local char = LP.Character
		if char then
			local tag = char:FindFirstChild("TIMELESS_TAG")
			if not tag then
				tag = Instance.new("BoolValue")
				tag.Name = "TIMELESS_TAG"
				tag.Value = true
				tag.Parent = char
			end
		end

		-- Workspace marker (more reliable)
		local markerName = "TIMELESS_USER_" .. tostring(LP.UserId)
		local marker = Workspace:FindFirstChild(markerName)
		if not marker then
			marker = Instance.new("Folder")
			marker.Name = markerName
			marker.Parent = Workspace
		end
	end)
end

markAsUser()
LP.CharacterAdded:Connect(function()
	task.wait(1)
	markAsUser()
end)

task.spawn(function()
	while true do
		task.wait(5)
		markAsUser()
	end
end)

-- ===================== USERS =====================
local function getOtherUsers()
	local users = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local hasTag = plr.Character and plr.Character:FindFirstChild("TIMELESS_TAG")
			local hasMarker = Workspace:FindFirstChild("TIMELESS_USER_" .. tostring(plr.UserId))
			if hasTag or hasMarker then
				table.insert(users, plr.Name)
			end
		end
	end
	return users
end

local function notifyUsers()
	local users = getOtherUsers()
	if #users > 0 then
		Notify("TIMELESS Users", "Server: " .. (#users + 1) .. " user(s)\nOthers: " .. table.concat(users, ", "), 6)
	else
		Notify("TIMELESS Users", "Server: 1 user (only you)\nNo other TIMELESS users found", 5)
	end
end

task.spawn(function()
	while true do
		task.wait(12)
		if showUsers then
			local users = getOtherUsers()
			for _, name in ipairs(users) do
				if not knownUsers[name] then
					knownUsers[name] = true
					Notify("New TIMELESS User", name .. " is using TIMELESS", 4)
				end
			end
		end
	end
end)

task.spawn(function()
	task.wait(1.5)
	Notify("TIMELESS Loaded", "Found any bugs or suggestions?\nLeave a comment on ScriptBlox.", 5)
	task.wait(2)
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
		task.wait(3)
		if fullbrightEnabled then applyFullbright() end
		if noFogEnabled then applyNoFog() end
	end
end)

-- ===================== AUTO PICKUP =====================
local function firePickupFor(nameMatch)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if not (obj:IsA("Tool") or obj:IsA("Model")) then continue end
		if isOwnedByPlayer(obj) then continue end
		local name = string.lower(obj.Name)
		if not name:find(nameMatch) then continue end
		if nameMatch:find("heal") and string.lower(obj:GetFullName()):find("station") then continue end
		local prompt = findPrompt(obj)
		if prompt and prompt.Enabled then
			pcall(function() fireproximityprompt(prompt) end)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(1.4)
		if autoPickupGas and tick() - lastGasPickup >= 1.5 then firePickupFor("gas") lastGasPickup = tick() end
		if autoPickupMedkit and tick() - lastMedkitPickup >= 1.5 then firePickupFor("medkit") lastMedkitPickup = tick() end
		if autoPickupSlateskin and tick() - lastSlateskinPickup >= 1.5 then firePickupFor("slateskin") lastSlateskinPickup = tick() end
		if autoPickupCola and tick() - lastColaPickup >= 1.5 then firePickupFor("cola") lastColaPickup = tick() end
		if autoPickupHealing and tick() - lastHealingPickup >= 1.5 then firePickupFor("healing") lastHealingPickup = tick() end
	end
end)

-- ===================== AUTO WIREBOX =====================
local function doAutoWirebox()
	if not autoWirebox or wireboxBusy or tick() - lastWireboxTime < 6 then return end
	local root = getRoot()
	if not root then return end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if string.lower(obj.Name):find("wirebox") then
			local remote = obj:FindFirstChild("CompleteObjective") or obj:FindFirstChild("Complete")
			if remote and (remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction")) then
				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
				if part and (part.Position - root.Position).Magnitude < 18 then
					wireboxBusy = true
					lastWireboxTime = tick()
					Notify("Wirebox", "Completing in 5s...", 3)
					task.delay(5, function()
						if remote and remote.Parent then
							pcall(function()
								if remote:IsA("RemoteEvent") then remote:FireServer() else remote:InvokeServer() end
							end)
							Notify("Wirebox", "Completed!", 2)
						end
						wireboxBusy = false
					end)
					return
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		doAutoWirebox()
	end
end)

-- ===================== AUTO BADWARE COMPUTER =====================
task.spawn(function()
	while true do
		task.wait(0.12)
		if not autoBadwareComputer then continue end
		refreshCaches()
		local root = getRoot()
		if not root then continue end
		for _, obj in ipairs(cachedComputers) do
			if obj and obj.Parent then
				local part = obj:FindFirstChild("RootPart") or obj:FindFirstChildWhichIsA("BasePart")
				if part and (part.Position - root.Position).Magnitude < 22 then
					local prompt = findPrompt(obj)
					if prompt and prompt.Enabled then
						pcall(function() fireproximityprompt(prompt) end)
					end
				end
			end
		end
	end
end)

-- ===================== AUTO PIZZA BOX =====================
task.spawn(function()
	while true do
		task.wait(0.9)
		if not autoPizzaBox or tick() - lastPizzaBox < 1 then continue end
		refreshCaches()
		local root = getRoot()
		if not root then continue end
		for _, obj in ipairs(cachedPizzaBoxes) do
			if obj and obj.Parent and not isOwnedByPlayer(obj) then
				local part = obj:FindFirstChild("BoxPart") or obj:FindFirstChildWhichIsA("BasePart")
				if part and (part.Position - root.Position).Magnitude < 18 then
					local prompt = findPrompt(obj)
					if prompt and prompt.Enabled then
						pcall(function() fireproximityprompt(prompt) end)
						lastPizzaBox = tick()
						break
					end
				end
			end
		end
	end
end)

-- ===================== AUTO ESCAPE (RESCUE) =====================
local function getRescueExitParts()
	local targets = {}
	if not rescueReady then return targets end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if string.lower(obj.Name) == "escapemodel" and obj:IsDescendantOf(Workspace) then
			local path = string.lower(obj:GetFullName())
			if not path:find("replicatedstorage") then
				local exitPart = obj:FindFirstChild("ExitPart")
				if exitPart and exitPart:IsA("BasePart") then
					table.insert(targets, exitPart)
				end
			end
		end
	end
	return targets
end

task.spawn(function()
	while true do
		task.wait(0.8)
		if not autoEscape or not isLocalSurvivor() or not rescueReady or escapeUsedThisRescue or escapePending then
			escapePending = false
			continue
		end
		if tick() - lastEscapeTeleport < 3 then continue end
		local targets = getRescueExitParts()
		if #targets == 0 then continue end

		escapePending = true
		Notify("Auto Escape", "Rescue is out — teleporting in 1s...", 3)
		task.spawn(function()
			task.wait(1)
			if not autoEscape or not rescueReady or escapeUsedThisRescue or not isLocalSurvivor() then
				escapePending = false
				return
			end
			local myRoot = getRoot()
			if myRoot then
				targets = getRescueExitParts()
				if #targets > 0 then
					local chosen = targets[math.random(1, #targets)]
					pcall(function() myRoot.CFrame = chosen.CFrame + Vector3.new(0, 3, 0) end)
					lastEscapeTeleport = tick()
					escapeUsedThisRescue = true
					Notify("Auto Escape", "Teleported to exit", 3)
				end
			end
			escapePending = false
		end)
	end
end)

-- ===================== ESP =====================
local function clearItemESP()
	for _, h in pairs(itemHighlights) do pcall(function() h:Destroy() end) end
	for _, b in pairs(itemLabels) do pcall(function() b:Destroy() end) end
	itemHighlights, itemLabels = {}, {}
end

local function clearComputerESP()
	for _, h in pairs(computerHighlights) do pcall(function() h:Destroy() end) end
	computerHighlights = {}
end

local function clearZombieESP()
	for _, h in pairs(zombieHighlights) do pcall(function() h:Destroy() end) end
	zombieHighlights = {}
end

local function clearTrapRebelLandmine()
	for _, h in pairs(trapHighlights) do pcall(function() h:Destroy() end) end
	for _, h in pairs(rebelHighlights) do pcall(function() h:Destroy() end) end
	for _, h in pairs(landmineHighlights) do pcall(function() h:Destroy() end) end
	trapHighlights, rebelHighlights, landmineHighlights = {}, {}, {}
end

local function updateAllESP()
	clearItemESP()
	if gasESP or medkitESP or wireboxESP or slateskinESP or healingPotionESP or bloxyColaESP or crateESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			local name = string.lower(obj.Name)
			local color = nil
			if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Tool") then
				local fullPath = string.lower(obj:GetFullName())
				if gasESP and name:find("gas") then color = Color3.fromRGB(255, 170, 0)
				elseif medkitESP and name:find("medkit") then color = Color3.fromRGB(0, 255, 100)
				elseif slateskinESP and name:find("slateskin") then color = Color3.fromRGB(180, 100, 255)
				elseif wireboxESP and name == "wirebox" then color = Color3.fromRGB(0, 220, 255)
				elseif healingPotionESP and name:find("healing") and not fullPath:find("station") then color = Color3.fromRGB(100, 255, 180)
				elseif bloxyColaESP and name:find("cola") then color = Color3.fromRGB(255, 80, 80)
				elseif crateESP and name == "crate" and not fullPath:find("area 51") then color = Color3.fromRGB(255, 200, 50)
				end
				if color then
					local h = Instance.new("Highlight")
					h.Adornee = obj
					h.FillColor = color
					h.OutlineColor = color
					h.FillTransparency = 0.55
					h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					h.Parent = obj
					itemHighlights[obj] = h
				end
			end
		end
	end

	clearComputerESP()
	if computerESP then
		refreshCaches()
		for _, obj in ipairs(cachedComputers) do
			if obj and obj.Parent then
				local h = Instance.new("Highlight")
				h.Adornee = obj
				h.FillColor = Color3.fromRGB(0, 200, 255)
				h.OutlineColor = Color3.fromRGB(0, 255, 255)
				h.FillTransparency = 0.5
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = obj
				computerHighlights[obj] = h
			end
		end
	end

	clearTrapRebelLandmine()
	clearZombieESP()
	if espEnabled then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			local name = string.lower(obj.Name)
			if obj:IsA("Model") or obj:IsA("BasePart") then
				if name == "trapmodel" or (name:find("trap") and not name:find("exit")) then
					local h = Instance.new("Highlight")
					h.Adornee = obj h.FillColor = Color3.fromRGB(255, 60, 60) h.OutlineColor = Color3.fromRGB(255, 60, 60)
					h.FillTransparency = 0.5 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = obj
					trapHighlights[obj] = h
				elseif name:find("rebel") then
					local h = Instance.new("Highlight")
					h.Adornee = obj h.FillColor = Color3.fromRGB(255, 40, 40) h.OutlineColor = Color3.fromRGB(255, 40, 40)
					h.FillTransparency = 0.5 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = obj
					rebelHighlights[obj] = h
				elseif name:find("landmine") then
					local h = Instance.new("Highlight")
					h.Adornee = obj h.FillColor = Color3.fromRGB(255, 120, 0) h.OutlineColor = Color3.fromRGB(255, 120, 0)
					h.FillTransparency = 0.45 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = obj
					landmineHighlights[obj] = h
				elseif name:find("zombiekingzombie") then
					local h = Instance.new("Highlight")
					h.Adornee = obj h.FillColor = Color3.fromRGB(0, 255, 80) h.OutlineColor = Color3.fromRGB(0, 255, 80)
					h.FillTransparency = 0.5 h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop h.Parent = obj
					zombieHighlights[obj] = h
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(3.5)
		updateAllESP()
	end
end)

-- ===================== PLAYER ESP =====================
local function cleanup(player)
	if highlights[player] then pcall(function() highlights[player]:Destroy() end) highlights[player] = nil end
	if billboards[player] then pcall(function() billboards[player]:Destroy() end) billboards[player] = nil end
end

local function createESP(player, isEnt)
	if not player.Character then return end
	cleanup(player)
	local char = player.Character
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	local color = isEnt and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(40, 140, 255)
	local h = Instance.new("Highlight")
	h.Adornee = char
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.7
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = char
	highlights[player] = h

	local bb = Instance.new("BillboardGui")
	bb.Adornee = root
	bb.Size = UDim2.new(0, 140, 0, isEnt and 24 or 40)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 400
	bb.Parent = char

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, isEnt and 1 or 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = isEnt and (player.Name .. " [ENTITY]") or player.Name
	nameLabel.TextColor3 = color
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.Parent = bb

	if not isEnt then
		local hp = Instance.new("TextLabel")
		hp.Size = UDim2.new(1, 0, 0.5, 0)
		hp.Position = UDim2.new(0, 0, 0.5, 0)
		hp.BackgroundTransparency = 1
		hp.Text = "HP: " .. math.floor(hum.Health)
		hp.TextColor3 = Color3.fromRGB(0, 255, 100)
		hp.TextStrokeTransparency = 0.3
		hp.Font = Enum.Font.Gotham
		hp.TextSize = 12
		hp.Parent = bb
		hum.HealthChanged:Connect(function()
			if hp and hp.Parent then hp.Text = "HP: " .. math.floor(hum.Health) end
		end)
	end
	billboards[player] = bb
end

task.spawn(function()
	while true do
		task.wait(2)
		if not espEnabled then
			for plr in pairs(highlights) do cleanup(plr) end
			continue
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				if isEntity(player) or isSurvivor(player) then
					if not highlights[player] or highlights[player].Adornee ~= player.Character then
						createESP(player, isEntity(player))
					end
				else
					cleanup(player)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(cleanup)

-- ===================== CARRY / REVIVE =====================
local CharacterEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") and ReplicatedStorage.RemoteEvents:FindFirstChild("CharacterEvents")
local RequestCarry = CharacterEvents and CharacterEvents:FindFirstChild("RequestCarry")
local RequestRevive = CharacterEvents and CharacterEvents:FindFirstChild("RequestRevive")

local function getDownedSurvivors()
	local downed = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character and isSurvivor(plr) then
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.4 then
				table.insert(downed, plr.Character)
			end
		end
	end
	return downed
end

task.spawn(function()
	while true do
		task.wait(1.8)
		if autoCarry and RequestCarry then
			for _, target in ipairs(getDownedSurvivors()) do
				pcall(function() RequestCarry:FireServer(target) end)
				task.wait(0.4)
			end
		end
		if autoRevive and RequestRevive then
			for _, target in ipairs(getDownedSurvivors()) do
				pcall(function() RequestRevive:FireServer(target) end)
				task.wait(0.4)
			end
		end
	end
end)

-- ===================== UI =====================
local Window = WindUI:CreateWindow({
	Title = "TIMELESS",
	Icon = "star",
	Theme = "Dark",
	Folder = "TimelessHub"
})

local EntityTab = Window:Tab({ Title = "Entity", Icon = "skull" })
EntityTab:Paragraph({ Title = "Note", Desc = "Adding features soon\nWork in progress" })

local SurvivorTab = Window:Tab({ Title = "Survivor", Icon = "user" })

SurvivorTab:Dropdown({
	Title = "Select Survivor",
	Values = survivorList,
	Value = "Ace",
	Callback = function(option)
		selectedSurvivor = option
	end
})

SurvivorTab:Toggle({
	Title = "Auto Select Survivor",
	Value = false,
	Callback = function(v)
		autoSelectSurvivor = v
		if v then
			Notify("Auto Select", "Spamming " .. selectedSurvivor .. " — turn off after you get it", 4)
		end
	end
})

SurvivorTab:Paragraph({
	Title = "How to use",
	Desc = "1. Pick survivor from dropdown\n2. Turn Auto Select ON before/during character select\n3. Turn OFF once you got the character"
})

SurvivorTab:Toggle({ Title = "Auto Escape Grab", Value = false, Callback = function(v) autoEscapeGrab = v end })
SurvivorTab:Toggle({ Title = "Auto Carry", Value = false, Callback = function(v) autoCarry = v end })
SurvivorTab:Toggle({ Title = "Auto Revive", Value = false, Callback = function(v) autoRevive = v end })
SurvivorTab:Toggle({ Title = "Auto Wirebox", Value = false, Callback = function(v) autoWirebox = v wireboxBusy = false end })
SurvivorTab:Toggle({ Title = "Auto Escape", Value = false, Callback = function(v) autoEscape = v end })
SurvivorTab:Toggle({ Title = "Auto Badware Computer", Value = false, Callback = function(v) autoBadwareComputer = v end })
SurvivorTab:Toggle({ Title = "Auto Pizza Box", Value = false, Callback = function(v) autoPizzaBox = v end })

local ItemsTab = Window:Tab({ Title = "Items", Icon = "package" })
ItemsTab:Toggle({ Title = "Auto Pickup Gas", Value = false, Callback = function(v) autoPickupGas = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Medkit", Value = false, Callback = function(v) autoPickupMedkit = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Slateskin", Value = false, Callback = function(v) autoPickupSlateskin = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Bloxy Cola", Value = false, Callback = function(v) autoPickupCola = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Healing Potion", Value = false, Callback = function(v) autoPickupHealing = v end })

local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
VisualsTab:Toggle({
	Title = "Player ESP",
	Value = true,
	Callback = function(v)
		espEnabled = v
		if not v then
			for plr in pairs(highlights) do cleanup(plr) end
			clearTrapRebelLandmine()
			clearZombieESP()
		end
	end
})
VisualsTab:Toggle({ Title = "Gas Canister ESP", Value = false, Callback = function(v) gasESP = v end })
VisualsTab:Toggle({ Title = "Medkit ESP", Value = false, Callback = function(v) medkitESP = v end })
VisualsTab:Toggle({ Title = "Wirebox ESP", Value = false, Callback = function(v) wireboxESP = v end })
VisualsTab:Toggle({ Title = "Slateskin Potion ESP", Value = false, Callback = function(v) slateskinESP = v end })
VisualsTab:Toggle({ Title = "Healing Potion ESP", Value = false, Callback = function(v) healingPotionESP = v end })
VisualsTab:Toggle({ Title = "Bloxy Cola ESP", Value = false, Callback = function(v) bloxyColaESP = v end })
VisualsTab:Toggle({ Title = "Crate ESP", Value = false, Callback = function(v) crateESP = v end })
VisualsTab:Toggle({
	Title = "Badware Computer ESP",
	Value = false,
	Callback = function(v)
		computerESP = v
		if not v then clearComputerESP() end
	end
})

local MiscTab = Window:Tab({ Title = "Misc", Icon = "settings" })
MiscTab:Toggle({ Title = "Fullbright", Value = false, Callback = function(v) fullbrightEnabled = v if v then applyFullbright() end end })
MiscTab:Toggle({ Title = "No Fog", Value = false, Callback = function(v) noFogEnabled = v if v then applyNoFog() end end })
MiscTab:Toggle({ Title = "Show Other Users", Value = true, Callback = function(v) showUsers = v end })
MiscTab:Button({ Title = "Check TIMELESS Users", Callback = function() notifyUsers() end })

print("TIMELESS Hub loaded - Less blatant Grab + better Users")
