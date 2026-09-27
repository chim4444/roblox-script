-- TIMELESS Script Hub (WindUI)
-- Auto Badware Computer (faster spam) + ESP | Healing Potion | Pizza Box | no Generator fill
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
local computerESP = false
local autoCarry = false
local autoRevive = false
local autoWirebox = false
local autoEscape = false
local autoBadwareComputer = false
local autoPizzaBox = false
local autoPickupGas = false
local autoPickupMedkit = false
local autoPickupSlateskin = false
local autoPickupCola = false
local autoPickupHealing = false
local fullbrightEnabled = false
local noFogEnabled = false
local showUsers = true

local highlights = {}
local billboards = {}
local itemHighlights = {}
local itemLabels = {}
local trapHighlights = {}
local rebelHighlights = {}
local landmineHighlights = {}
local zombieHighlights = {}
local computerHighlights = {}
local knownUsers = {}

local wireboxBusy = false
local lastWireboxTime = 0
local escapePending = false
local lastEscapeTeleport = 0
local escapeUsedThisRescue = false
local lastGasPickup = 0
local lastMedkitPickup = 0
local lastSlateskinPickup = 0
local lastColaPickup = 0
local lastHealingPickup = 0
local lastPizzaBox = 0
local rescueReady = false
local scriptLoadTime = tick()

-- ===================== NOTIFICATION =====================
local notifOffset = 0

local function Notify(title, content, duration)
	duration = duration or 5
	local ok = pcall(function()
		WindUI:Notify({ Title = title, Content = content, Duration = duration })
	end)
	if ok then return end

	local gui = Instance.new("ScreenGui")
	gui.Name = "TimelessNotify"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = PG

	local yPos = 80 + (notifOffset * 95)
	notifOffset = notifOffset + 1

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 280, 0, 85)
	frame.Position = UDim2.new(1, 20, 0, yPos)
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
		Position = UDim2.new(1, -300, 0, yPos)
	}):Play()

	task.delay(duration, function()
		local tween = TweenService:Create(frame, TweenInfo.new(0.3), {
			Position = UDim2.new(1, 20, 0, yPos)
		})
		tween:Play()
		tween.Completed:Wait()
		gui:Destroy()
		notifOffset = math.max(0, notifOffset - 1)
	end)
end

-- ===================== HELPERS =====================
local function getRoot()
	local char = LP.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local char = LP.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function findPrompt(parent)
	if not parent then return nil end
	local p = parent:FindFirstChildOfClass("ProximityPrompt")
	if p then return p end
	return parent:FindFirstChildWhichIsA("ProximityPrompt", true)
end

local function isOwnedByPlayer(obj)
	if not obj then return true end
	local current = obj
	while current and current ~= game do
		if current:IsA("Player") then return true end
		if current == LP.Character or current == LP:FindFirstChild("Backpack") then return true end
		for _, plr in ipairs(Players:GetPlayers()) do
			if current == plr.Character or current == plr:FindFirstChild("Backpack") then
				return true
			end
		end
		current = current.Parent
	end
	return false
end

local function isLocalSurvivor()
	return LP.Team and LP.Team.Name == "Survivors"
end

local function isEntity(player)
	return player.Team and player.Team.Name == "Entities"
end

local function isSurvivor(player)
	return player.Team and player.Team.Name == "Survivors"
end

-- EscapeModel: ignore map-load fake exit
Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		if not obj or not obj.Parent then return end
		if string.lower(obj.Name) ~= "escapemodel" then return end
		if not obj:IsDescendantOf(Workspace) then return end

		local path = string.lower(obj:GetFullName())
		if path:find("replicatedstorage") then return end
		if tick() - scriptLoadTime < 20 then return end

		local thisModel = obj
		task.delay(3, function()
			if thisModel and thisModel.Parent and thisModel:IsDescendantOf(Workspace) then
				local stillPath = string.lower(thisModel:GetFullName())
				if not stillPath:find("replicatedstorage") then
					rescueReady = true
					escapeUsedThisRescue = false
					if autoEscape and isLocalSurvivor() then
						Notify("Auto Escape", "Rescue confirmed — ready", 3)
					end
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
					if not path:find("replicatedstorage") then
						still = true
						break
					end
				end
			end
			if not still then
				rescueReady = false
				escapeUsedThisRescue = false
			end
		end)
	end
end)

-- ===================== MARK USER =====================
local function markAsUser()
	pcall(function()
		local char = LP.Character
		if char and not char:FindFirstChild("TIMELESS_TAG") then
			local tag = Instance.new("BoolValue")
			tag.Name = "TIMELESS_TAG"
			tag.Value = true
			tag.Parent = char
		end
		local markerName = "TIMELESS_" .. LP.UserId
		if not Workspace:FindFirstChild(markerName) then
			local marker = Instance.new("Folder")
			marker.Name = markerName
			marker.Parent = Workspace
		end
	end)
end

markAsUser()
LP.CharacterAdded:Connect(function()
	task.wait(0.8)
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
			local found = false
			if plr.Character and plr.Character:FindFirstChild("TIMELESS_TAG") then found = true end
			if Workspace:FindFirstChild("TIMELESS_" .. plr.UserId) then found = true end
			if found then table.insert(users, plr.Name) end
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
				if not stillHere then knownUsers[name] = nil end
			end
		end
	end
end)

task.spawn(function()
	task.wait(1.5)
	Notify("TIMELESS Loaded", "Found any bugs or suggestions?\nLeave a comment on ScriptBlox.", 6)
	task.wait(1.8)
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

-- ===================== AUTO PICKUP =====================
local function firePickupFor(nameMatch)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if not (obj:IsA("Tool") or obj:IsA("Model")) then continue end
		if isOwnedByPlayer(obj) then continue end

		local name = string.lower(obj.Name)
		if not name:find(nameMatch) then continue end

		local full = string.lower(obj:GetFullName())
		if nameMatch:find("heal") and full:find("station") then continue end

		local prompt = findPrompt(obj)
		if prompt and prompt.Enabled then
			pcall(function() fireproximityprompt(prompt) end)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(0.9)
		if autoPickupGas and tick() - lastGasPickup >= 1.3 then
			firePickupFor("gas")
			lastGasPickup = tick()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.9)
		if autoPickupMedkit and tick() - lastMedkitPickup >= 1.3 then
			firePickupFor("medkit")
			lastMedkitPickup = tick()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.9)
		if autoPickupSlateskin and tick() - lastSlateskinPickup >= 1.3 then
			firePickupFor("slateskin")
			lastSlateskinPickup = tick()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.9)
		if autoPickupCola and tick() - lastColaPickup >= 1.3 then
			firePickupFor("cola")
			lastColaPickup = tick()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.9)
		if autoPickupHealing and tick() - lastHealingPickup >= 1.3 then
			firePickupFor("healing")
			lastHealingPickup = tick()
		end
	end
end)

-- ===================== AUTO WIREBOX =====================
local function doAutoWirebox()
	if not autoWirebox or wireboxBusy then return end
	if tick() - lastWireboxTime < 6 then return end

	local root = getRoot()
	if not root then return end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		if name:find("wirebox") then
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
								if remote:IsA("RemoteEvent") then
									remote:FireServer()
								else
									remote:InvokeServer()
								end
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
		task.wait(1.5)
		doAutoWirebox()
	end
end)

-- ===================== AUTO BADWARE COMPUTER (heavy spam) =====================
task.spawn(function()
	while true do
		task.wait(0.05) -- very fast
		if not autoBadwareComputer then continue end

		local root = getRoot()
		if not root then continue end

		for _, obj in ipairs(Workspace:GetDescendants()) do
			if string.lower(obj.Name) == "computer" then
				local part = obj:IsA("BasePart") and obj or obj:FindFirstChild("RootPart") or obj:FindFirstChildWhichIsA("BasePart")
				if part and (part.Position - root.Position).Magnitude < 22 then
					local prompt = findPrompt(obj)
					if prompt and prompt.Enabled then
						-- fire multiple times per tick for heavier spam
						for i = 1, 3 do
							pcall(function() fireproximityprompt(prompt) end)
						end
					end
				end
			end
		end
	end
end)

-- ===================== AUTO PIZZA BOX (nearby) =====================
task.spawn(function()
	while true do
		task.wait(0.6)
		if not autoPizzaBox then continue end
		if tick() - lastPizzaBox < 0.8 then continue end

		local root = getRoot()
		if not root then continue end

		for _, obj in ipairs(Workspace:GetDescendants()) do
			local name = string.lower(obj.Name)
			if name == "pizzabox" or name:find("pizza") then
				if isOwnedByPlayer(obj) then continue end
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

-- ===================== AUTO ESCAPE (survivors only) =====================
local function getRescueExitParts()
	local targets = {}
	if not rescueReady then return targets end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if not obj:IsDescendantOf(Workspace) then continue end
		local path = string.lower(obj:GetFullName())
		if path:find("replicatedstorage") then continue end

		if string.lower(obj.Name) == "escapemodel" then
			local exitPart = obj:FindFirstChild("ExitPart")
			if exitPart and exitPart:IsA("BasePart") then
				table.insert(targets, exitPart)
			end
		end
	end
	return targets
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if not autoEscape then
			escapePending = false
			continue
		end
		if not isLocalSurvivor() then
			escapePending = false
			continue
		end
		if not rescueReady then continue end
		if escapeUsedThisRescue then continue end
		if escapePending then continue end
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
			if not myRoot then
				escapePending = false
				return
			end

			targets = getRescueExitParts()
			if #targets > 0 then
				local chosen = targets[math.random(1, #targets)]
				pcall(function()
					myRoot.CFrame = chosen.CFrame + Vector3.new(0, 3, 0)
				end)
				lastEscapeTeleport = tick()
				escapeUsedThisRescue = true
				Notify("Auto Escape", "Teleported to exit", 3)
			end
			escapePending = false
		end)
	end
end)

-- ===================== ITEM ESP =====================
local function clearItemESP()
	for obj, h in pairs(itemHighlights) do pcall(function() h:Destroy() end) end
	for obj, b in pairs(itemLabels) do pcall(function() b:Destroy() end) end
	itemHighlights = {}
	itemLabels = {}
end

local function isInteractiveCrate(obj)
	local fullPath = string.lower(obj:GetFullName())
	if fullPath:find("area 51") or fullPath:find("area51") then return false end
	if obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChildOfClass("ClickDetector") then return true end
	if obj:FindFirstChildWhichIsA("ProximityPrompt", true) or obj:FindFirstChildWhichIsA("ClickDetector", true) then return true end
	return false
end

local function updateItemESP()
	clearItemESP()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		local color, labelText = nil, nil
		if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder") or obj:IsA("Tool") then
			local parentName = obj.Parent and string.lower(obj.Parent.Name) or ""
			local fullPath = string.lower(obj:GetFullName())

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
				color = Color3.fromRGB(0, 220, 255)
				labelText = "Wirebox"
			elseif healingPotionESP and (
				name:find("healingpotion") or name:find("heal potion") or name:find("healing potion") or
				name:find("healthpotion") or name:find("health potion") or name:find("healpotion") or
				(name:find("potion") and name:find("heal"))
			) and not parentName:find("station") and not fullPath:find("station") then
				color = Color3.fromRGB(100, 255, 180)
				labelText = "Heal"
			elseif bloxyColaESP and (name:find("bloxycola") or name:find("bloxy cola") or name:find("cola")) then
				color = Color3.fromRGB(255, 80, 80)
				labelText = "Cola"
			elseif crateESP and name == "crate" and isInteractiveCrate(obj) then
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
					bb.Size = UDim2.new(0, 90, 0, 16)
					bb.StudsOffset = Vector3.new(0, 2.5, 0)
					bb.AlwaysOnTop = true
					bb.MaxDistance = 150
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
		task.wait(2.5)
		updateItemESP()
	end
end)

-- ===================== BADWARE COMPUTER ESP =====================
local function clearComputerESP()
	for obj, h in pairs(computerHighlights) do pcall(function() h:Destroy() end) end
	computerHighlights = {}
end

local function updateComputerESP()
	clearComputerESP()
	if not computerESP then return end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if string.lower(obj.Name) == "computer" and (obj:IsA("Model") or obj:IsA("BasePart")) then
			local highlight = Instance.new("Highlight")
			highlight.Adornee = obj
			highlight.FillColor = Color3.fromRGB(0, 200, 255)
			highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
			highlight.FillTransparency = 0.5
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = obj
			computerHighlights[obj] = highlight

			local part = obj:FindFirstChild("RootPart") or obj:FindFirstChildWhichIsA("BasePart")
			if part then
				local bb = Instance.new("BillboardGui")
				bb.Adornee = part
				bb.Size = UDim2.new(0, 100, 0, 18)
				bb.StudsOffset = Vector3.new(0, 2.8, 0)
				bb.AlwaysOnTop = true
				bb.MaxDistance = 200
				bb.Parent = obj
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, 0, 1, 0)
				label.BackgroundTransparency = 1
				label.Text = "Badware PC"
				label.TextColor3 = Color3.fromRGB(0, 255, 255)
				label.TextStrokeTransparency = 0.3
				label.Font = Enum.Font.GothamBold
				label.TextSize = 12
				label.Parent = bb
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		updateComputerESP()
	end
end)

-- ===================== ZOMBIE / TRAP / REBEL / LANDMINE =====================
local function clearZombieESP()
	for obj, h in pairs(zombieHighlights) do pcall(function() h:Destroy() end) end
	zombieHighlights = {}
end

local function updateZombieESP()
	clearZombieESP()
	if not espEnabled then return end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		if (obj:IsA("Model") or obj:IsA("BasePart")) and name:find("zombiekingzombie") then
			local highlight = Instance.new("Highlight")
			highlight.Adornee = obj
			highlight.FillColor = Color3.fromRGB(0, 255, 80)
			highlight.OutlineColor = Color3.fromRGB(0, 255, 80)
			highlight.FillTransparency = 0.5
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = obj
			zombieHighlights[obj] = highlight
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		updateZombieESP()
	end
end)

local function clearTrapRebelLandmine()
	for obj, h in pairs(trapHighlights) do pcall(function() h:Destroy() end) end
	for obj, h in pairs(rebelHighlights) do pcall(function() h:Destroy() end) end
	for obj, h in pairs(landmineHighlights) do pcall(function() h:Destroy() end) end
	trapHighlights = {}
	rebelHighlights = {}
	landmineHighlights = {}
end

local function updateTrapRebelLandmineESP()
	clearTrapRebelLandmine()
	if not espEnabled then return end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(obj.Name)
		if obj:IsA("Model") or obj:IsA("BasePart") then
			if name == "trapmodel" or (name:find("trap") and not name:find("exit")) then
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
			elseif name == "landmine" or name:find("landmine") then
				local h = Instance.new("Highlight")
				h.Adornee = obj
				h.FillColor = Color3.fromRGB(255, 120, 0)
				h.OutlineColor = Color3.fromRGB(255, 120, 0)
				h.FillTransparency = 0.45
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = obj
				landmineHighlights[obj] = h
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		updateTrapRebelLandmineESP()
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
		clearTrapRebelLandmine()
		clearZombieESP()
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
		task.wait(1.2)
		if autoCarry and RequestCarry then
			for _, target in ipairs(getDownedSurvivors()) do
				pcall(function() RequestCarry:FireServer(target) end)
				task.wait(0.3)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(1.2)
		if autoRevive and RequestRevive then
			for _, target in ipairs(getDownedSurvivors()) do
				pcall(function() RequestRevive:FireServer(target) end)
				task.wait(0.3)
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

local EntityTab = Window:Tab({ Title = "Entity", Icon = "skull" })
EntityTab:Paragraph({ Title = "Note", Desc = "Adding features soon\nWork in progress" })

local SurvivorTab = Window:Tab({ Title = "Survivor", Icon = "user" })
SurvivorTab:Toggle({ Title = "Auto Carry", Value = false, Callback = function(v) autoCarry = v end })
SurvivorTab:Toggle({ Title = "Auto Revive", Value = false, Callback = function(v) autoRevive = v end })
SurvivorTab:Toggle({ Title = "Auto Wirebox", Value = false, Callback = function(v) autoWirebox = v wireboxBusy = false end })
SurvivorTab:Toggle({ Title = "Auto Escape", Value = false, Callback = function(v) autoEscape = v end })
SurvivorTab:Toggle({ Title = "Auto Badware Computer", Value = false, Callback = function(v) autoBadwareComputer = v end })
SurvivorTab:Toggle({ Title = "Auto Pizza Box", Value = false, Callback = function(v) autoPizzaBox = v end })
SurvivorTab:Paragraph({ Title = "Escape Info", Desc = "Survivors only\nIgnores map-load exit\nReal rescue (3s confirm) • 1s delay" })
SurvivorTab:Paragraph({ Title = "Badware / Pizza", Desc = "Badware: heavy spam when nearby\nPizza Box: interacts when nearby" })

local ItemsTab = Window:Tab({ Title = "Items", Icon = "package" })
ItemsTab:Toggle({ Title = "Auto Pickup Gas", Value = false, Callback = function(v) autoPickupGas = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Medkit", Value = false, Callback = function(v) autoPickupMedkit = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Slateskin", Value = false, Callback = function(v) autoPickupSlateskin = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Bloxy Cola", Value = false, Callback = function(v) autoPickupCola = v end })
ItemsTab:Toggle({ Title = "Auto Pickup Healing Potion", Value = false, Callback = function(v) autoPickupHealing = v end })
ItemsTab:Paragraph({
	Title = "Info",
	Desc = "Never fires prompts on items you already hold\n(fixes auto-drop while running)"
})

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
VisualsTab:Paragraph({ Title = "Note", Desc = "Includes: Trap + Rebel + Landmine + Zombie ESP" })
VisualsTab:Toggle({ Title = "Gas Canister ESP", Value = false, Callback = function(v) gasESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Medkit ESP", Value = false, Callback = function(v) medkitESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Wirebox ESP", Value = false, Callback = function(v) wireboxESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Slateskin Potion ESP", Value = false, Callback = function(v) slateskinESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Healing Potion ESP", Value = false, Callback = function(v) healingPotionESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Bloxy Cola ESP", Value = false, Callback = function(v) bloxyColaESP = v updateItemESP() end })
VisualsTab:Toggle({ Title = "Crate ESP", Value = false, Callback = function(v) crateESP = v updateItemESP() end })
VisualsTab:Toggle({
	Title = "Badware Computer ESP",
	Value = false,
	Callback = function(v)
		computerESP = v
		if not v then clearComputerESP() else updateComputerESP() end
	end
})

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

print("TIMELESS Hub loaded - Auto Badware Computer + ESP")
