-- dogs | WindUI | Delta mobile

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")

local lp  = Players.LocalPlayer
local cam = workspace.CurrentCamera

local function C()  return lp.Character end
local function H()  local c = C() return c and c:FindFirstChildOfClass("Humanoid") end
local function R()  local c = C() return c and c:FindFirstChild("HumanoidRootPart") end

local fconns = {}
local function kill(name)
    local t = fconns[name] if not t then return end
    for _, c in ipairs(t) do pcall(c.Disconnect, c) end
    fconns[name] = nil
end
local function reg(name, event, fn)
    fconns[name] = fconns[name] or {}
    local c = event:Connect(fn)
    table.insert(fconns[name], c)
end

local state = {
    dogesp      = false,
    espColor    = Color3.fromRGB(255, 60, 60),
    showHp      = true, showDist = true,
    antivoid    = true,
    infstam     = false,
    antiragdoll = false,
}

-- ═══ WINDUI ══════════════════════════════════════════════

local ok, W = pcall(function()
    return loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
    ))()
end)
if not ok then warn("[dogs] WindUI failed: " .. tostring(W)) return end

local Win = W:CreateWindow({
    Title       = "dogs",
    Icon        = "solar:shield-bold",
    Theme       = "Dark",
    Folder      = "dogs_cheat",
    Size        = UDim2.fromOffset(540, 460),
    Transparent = true,
})

local TChar    = Win:Tab({ Title = "Character", Icon = "solar:user-bold"     })
local TVisuals = Win:Tab({ Title = "Visuals",   Icon = "solar:eye-bold"      })
local TMisc    = Win:Tab({ Title = "Misc",      Icon = "solar:settings-bold" })

-- ═══ CHARACTER ════════════════════════════════════════════

-- Inf Stamina
local function applyStamina(chr)
    if not chr then return end
    pcall(function()
        chr:SetAttribute("Epicsauce", workspace:GetServerTimeNow() + 999999)
    end)
end

TChar:Toggle({
    Title = "Inf Stamina", Value = false,
    Callback = function(v)
        state.infstam = v
        if v then
            applyStamina(C())
        else
            local c = C()
            if c then pcall(function() c:SetAttribute("Epicsauce", nil) end) end
        end
    end,
})

-- Anti-Ragdoll
local function fixRagdoll(chr)
    if not chr then return end
    local h = chr:FindFirstChildOfClass("Humanoid")
    if not h then return end
    pcall(function() chr:SetAttribute("Ragdolled", false) end)
    pcall(function() chr:SetAttribute("Dragged",   false) end)
    pcall(function() chr:SetAttribute("Slowed",    nil)   end)
    h.PlatformStand = false
    h.AutoRotate    = true
    h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
    h:ChangeState(Enum.HumanoidStateType.GettingUp)
    for _, d in ipairs(chr:GetDescendants()) do
        if d:IsA("Motor6D") then d.Enabled = true end
        if d:IsA("BallSocketConstraint") or d:IsA("HingeConstraint") then
            pcall(d.Destroy, d)
        end
    end
end

TChar:Toggle({
    Title = "Anti-Ragdoll", Value = false,
    Callback = function(v)
        state.antiragdoll = v
        if v then fixRagdoll(C()) end
    end,
})

-- ═══ VISUALS ═════════════════════════════════════════════

local npcFolder = workspace:FindFirstChild("NPCs")

local function isDog(m)
    if not m:IsA("Model") then return false end
    if m.Parent ~= npcFolder then return false end
    return m.Name:match("^Dog%d+") ~= nil
end

local espBoxes = {}

local function removeBox(root)
    local d = espBoxes[root] if not d then return end
    if d.box    then pcall(d.box.Destroy,  d.box)  end
    if d.bill   then pcall(d.bill.Destroy, d.bill) end
    if d.hpConn then d.hpConn:Disconnect()          end
    espBoxes[root] = nil
end

local function addDogESP(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root or espBoxes[root] then return end
    local h = model:FindFirstChildOfClass("Humanoid")

    local box = Instance.new("SelectionBox")
    box.Color3              = state.espColor
    box.SurfaceColor3       = state.espColor
    box.LineThickness       = 0.05
    box.SurfaceTransparency = 0.8
    box.Adornee             = model
    box.Parent              = cam

    local bill = Instance.new("BillboardGui")
    bill.Size        = UDim2.fromOffset(120, 26)
    bill.StudsOffset = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.Adornee     = root
    bill.Parent      = cam

    local lbl = Instance.new("TextLabel", bill)
    lbl.Size                   = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = state.espColor
    lbl.TextStrokeTransparency = 0.25
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextScaled             = true

    local function upd()
        local lr   = R()
        local dist = lr and math.floor((lr.Position - root.Position).Magnitude) or 0
        local hp   = h and math.floor(h.Health) or "?"
        local parts = {}
        if state.showHp   then parts[#parts+1] = hp   .. "hp" end
        if state.showDist then parts[#parts+1] = dist .. "m"  end
        lbl.Text = #parts > 0 and table.concat(parts, "  ") or "DOG"
    end
    upd()

    local hpConn = h and h:GetPropertyChangedSignal("Health"):Connect(upd) or nil
    model.AncestryChanged:Connect(function(_, p) if not p then removeBox(root) end end)
    espBoxes[root] = { box = box, bill = bill, hpConn = hpConn, updFn = upd }
end

local function scanDogs()
    if not npcFolder then npcFolder = workspace:FindFirstChild("NPCs") end
    if not npcFolder then return end
    for _, m in ipairs(npcFolder:GetChildren()) do
        if isDog(m) then addDogESP(m) end
    end
end

local function clearDogESP()
    for root in pairs(espBoxes) do removeBox(root) end
end

local espDescConn

TVisuals:Toggle({
    Title = "Dog ESP", Value = false,
    Callback = function(v)
        state.dogesp = v
        if v then
            scanDogs()
            if npcFolder then
                espDescConn = npcFolder.ChildAdded:Connect(function(m)
                    task.wait(0.05)
                    if isDog(m) then addDogESP(m) end
                end)
            end
        else
            clearDogESP()
            if espDescConn then espDescConn:Disconnect(); espDescConn = nil end
        end
    end,
})

TVisuals:Toggle({
    Title = "Show HP", Value = true,
    Callback = function(v) state.showHp = v end,
})

TVisuals:Toggle({
    Title = "Show Distance", Value = true,
    Callback = function(v) state.showDist = v end,
})

reg("espdist", RunService.Heartbeat, function()
    if not state.dogesp then return end
    for root, d in pairs(espBoxes) do
        if d.updFn and root and root.Parent then d.updFn() end
    end
end)

-- ═══ MISC ════════════════════════════════════════════════

local avSafe = Vector3.new(0, 10, 0)
local function startAntiVoid()
    kill("antivoid")
    reg("antivoid", RunService.Heartbeat, function()
        local r = R() if not r then return end
        if r.Position.Y > -80 then
            avSafe = r.Position
        else
            r.CFrame = CFrame.new(avSafe + Vector3.new(0, 5, 0))
        end
    end)
end

TMisc:Toggle({
    Title = "Anti-Void", Value = true,
    Callback = function(v)
        if v then startAntiVoid() else kill("antivoid") end
    end,
})
startAntiVoid()

local fbO = { Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd }
TMisc:Toggle({
    Title = "Fullbright", Value = false,
    Callback = function(v)
        Lighting.Brightness = v and 2   or fbO[1]
        Lighting.ClockTime  = v and 14  or fbO[2]
        Lighting.FogEnd     = v and 1e6 or fbO[3]
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if a then a.Density = v and 0 or 0.395 end
    end,
})

local function plrList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then t[#t+1] = p.Name end
    end
    return #t > 0 and t or { "(none)" }
end

TMisc:Dropdown({
    Title    = "TP to Player",
    Values   = plrList(),
    Value    = 1,
    Callback = function(name)
        local p = Players:FindFirstChild(name)
        if not (p and p.Character) then return end
        local tr = p.Character:FindFirstChild("HumanoidRootPart")
        local lr = R()
        if tr and lr then lr.CFrame = tr.CFrame + tr.CFrame.RightVector * 3 end
    end,
})

-- ═══ MASTER LOOP ═════════════════════════════════════════

reg("attrloop", RunService.Heartbeat, function()
    local c = C() if not c then return end

    if state.infstam then
        local cur = c:GetAttribute("Epicsauce")
        if not cur or (workspace:GetServerTimeNow() + 60) > cur then
            pcall(function()
                c:SetAttribute("Epicsauce", workspace:GetServerTimeNow() + 999999)
            end)
        end
        if c:GetAttribute("Slowed") then
            pcall(function() c:SetAttribute("Slowed", nil) end)
        end
    end

    if state.antiragdoll then
        if c:GetAttribute("Ragdolled") then
            pcall(function() c:SetAttribute("Ragdolled", false) end)
            local h = H()
            if h then
                h.PlatformStand = false
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        if c:GetAttribute("Dragged") then
            pcall(function() c:SetAttribute("Dragged", false) end)
        end
        if c:GetAttribute("Slowed") then
            pcall(function() c:SetAttribute("Slowed", nil) end)
        end
    end
end)

-- ═══ RESPAWN ═════════════════════════════════════════════

lp.CharacterAdded:Connect(function(chr)
    task.wait(0.8)
    if state.dogesp      then task.wait(0.5); scanDogs()       end
    if state.antivoid    then startAntiVoid()                   end
    if state.infstam     then task.wait(0.5); applyStamina(chr) end
    if state.antiragdoll then task.wait(0.5); fixRagdoll(chr)   end
end)
