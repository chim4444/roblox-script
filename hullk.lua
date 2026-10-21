-- survive the hulk hub
-- never ESP self | colors kept | smooth plastic | fixed hl | anti afk | hb | 600hp

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local rs = game:GetService("RunService")
local stats = game:GetService("Stats")
local rep = game:GetService("ReplicatedStorage")
local vu = game:GetService("VirtualUser")
local lighting = game:GetService("Lighting")

pcall(function()
    local old = lp.PlayerGui:FindFirstChild("PerfHud")
    if old then old:Destroy() end
end)

-- anti afk always on
lp.Idled:Connect(function()
    pcall(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

local skinSys = rep:FindFirstChild("HulkSkinSystem")
local abilityRemote = skinSys and skinSys:FindFirstChild("AbilitySpin")
local skinRemote = skinSys and skinSys:FindFirstChild("Spin")
local emoteRemote = skinSys and skinSys:FindFirstChild("EmoteSpin")

local cfg = {
    hulkEsp = true,
    survEsp = true,
    hbEsp = true,
    names = true,
    hp = true,
    dist = true,
    maxDist = 2000,

    hulkCol = Color3.fromRGB(80, 255, 120),
    survCol = Color3.fromRGB(80, 200, 255),
    hbCol = Color3.fromRGB(255, 160, 40),

    abilitySpin = false,
    abilityDelay = 0.35,
    skinSpin = false,
    skinDelay = 0.35,
    emoteSpin = false,
    emoteDelay = 0.35,

    fastMode = false,
}

local draws = {}
local abilityConn, skinConn, emoteConn
local savedMaterials = {}
local savedLighting = {}

local function isHulk(plr)
    local char = plr.Character
    if not char then return false end
    if plr:GetAttribute("IsHulk") or plr:GetAttribute("Hulk") then return true end
    if char:FindFirstChild("Hulk") then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.HipHeight and hum.HipHeight > 3 then return true end
    if plr.Team and tostring(plr.Team):lower():find("hulk") then return true end
    return false
end

local function isHulkbuster(plr)
    local char = plr.Character
    if not char then return false end
    if plr:GetAttribute("Hulkbuster") or plr:GetAttribute("IsHulkbuster") or plr:GetAttribute("InHulkbuster") then return true end
    if char:GetAttribute("Hulkbuster") then return true end
    if char:FindFirstChild("Hulkbuster") or char:FindFirstChild("HulkbusterVisual") then return true end
    if char:FindFirstChild("HulkbusterAnimationController") then return true end
    if char:FindFirstChild("HulkbusterVisualWeld", true) then return true end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MaxHealth >= 500 and not isHulk(plr) then return true end
    return false
end

local function getRole(plr)
    if isHulk(plr) then return "hulk" end
    if isHulkbuster(plr) then return "hb" end
    return "surv"
end

local function getHp(plr)
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, 100 end
    return math.floor(hum.Health), math.floor(hum.MaxHealth)
end

local function clearPlr(plr)
    local d = draws[plr]
    if not d then return end
    pcall(function() if d.hl then d.hl:Destroy() end end)
    pcall(function() if d.bb then d.bb:Destroy() end end)
    draws[plr] = nil
end

-- NEVER make ESP on yourself
local function make(plr)
    if plr == lp then return end
    if draws[plr] then return end
    local char = plr.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local role = getRole(plr)
    local col = role == "hulk" and cfg.hulkCol or (role == "hb" and cfg.hbCol or cfg.survCol)

    local hl = Instance.new("Highlight")
    hl.Name = "STH_HL"
    hl.Adornee = char
    hl.FillColor = col
    hl.OutlineColor = col
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "STH_BB"
    bb.Adornee = root
    bb.Size = UDim2.new(0, 160, 0, 42)
    bb.StudsOffset = Vector3.new(0, 3.4, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = true
    bb.Parent = root

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 13
    txt.TextColor3 = col
    txt.TextStrokeTransparency = 0.4
    txt.Text = plr.Name
    txt.Parent = bb

    draws[plr] = {
        hl = hl, bb = bb, txt = txt,
        role = role, lastHp = -1, lastDist = -1, lastText = "",
    }
end

local function updateOne(plr, myRoot)
    if plr == lp then
        clearPlr(plr)
        return
    end
    local d = draws[plr]
    if not d then return end

    local char = plr.Character
    if not char or not char.Parent then
        clearPlr(plr)
        return
    end

    if not d.hl or not d.hl.Parent then
        local role = d.role or getRole(plr)
        local col = role == "hulk" and cfg.hulkCol or (role == "hb" and cfg.hbCol or cfg.survCol)
        local hl = Instance.new("Highlight")
        hl.Name = "STH_HL"
        hl.Adornee = char
        hl.FillColor = col
        hl.OutlineColor = col
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = true
        hl.Parent = char
        d.hl = hl
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local role = d.role
    local roleOn = (role == "hulk" and cfg.hulkEsp)
        or (role == "hb" and cfg.hbEsp)
        or (role == "surv" and cfg.survEsp)

    local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0
    local show = roleOn and dist <= cfg.maxDist

    d.hl.Enabled = show
    d.hl.Adornee = char

    local wantBb = show and (cfg.names or cfg.hp or cfg.dist)
    if d.bb then d.bb.Enabled = wantBb end
    if not show then return end

    local cur, max = getHp(plr)
    local strong = (role ~= "hulk") and cur >= 600

    if strong then
        d.hl.FillTransparency = 0.25
        d.hl.OutlineTransparency = 0
        d.hl.FillColor = Color3.fromRGB(255, 70, 70)
        d.hl.OutlineColor = Color3.fromRGB(255, 30, 30)
        if d.txt then d.txt.TextColor3 = Color3.fromRGB(255, 120, 120) end
    else
        local col = role == "hulk" and cfg.hulkCol or (role == "hb" and cfg.hbCol or cfg.survCol)
        d.hl.FillTransparency = 0.5
        d.hl.OutlineTransparency = 0
        d.hl.FillColor = col
        d.hl.OutlineColor = col
        if d.txt then d.txt.TextColor3 = col end
    end

    local distI = math.floor(dist)
    if cur ~= d.lastHp or distI ~= d.lastDist then
        local bits = {}
        if cfg.names then bits[#bits + 1] = plr.Name end
        if cfg.hp then bits[#bits + 1] = string.format("%d/%d", cur, max) end
        if cfg.dist then bits[#bits + 1] = distI .. "m" end
        if role == "hb" then bits[#bits + 1] = "[HB]" end
        local text = table.concat(bits, " | ")
        if d.txt and text ~= d.lastText then
            d.txt.Text = text
            d.lastText = text
        end
        d.lastHp = cur
        d.lastDist = distI
    end
end

local function tickEsp()
    if not (cfg.hulkEsp or cfg.survEsp or cfg.hbEsp) then
        for _, d in pairs(draws) do
            if d.hl then d.hl.Enabled = false end
            if d.bb then d.bb.Enabled = false end
        end
        return
    end
    local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    for plr in pairs(draws) do
        updateOne(plr, myRoot)
    end
end

task.spawn(function()
    while true do
        if cfg.hulkEsp or cfg.survEsp or cfg.hbEsp then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character and not draws[plr] then
                    make(plr)
                end
            end
            for plr in pairs(draws) do
                if plr == lp or not plr.Parent then
                    clearPlr(plr)
                end
            end
        end
        task.wait(1.5)
    end
end)

task.spawn(function()
    while true do
        task.wait(3)
        for plr, d in pairs(draws) do
            if plr ~= lp and plr.Character then
                local r = getRole(plr)
                if r ~= d.role then
                    d.role = r
                    d.lastHp = -1
                end
            end
        end
    end
end)

rs.Heartbeat:Connect(tickEsp)

Players.PlayerRemoving:Connect(clearPlr)
Players.PlayerAdded:Connect(function(plr)
    if plr == lp then return end
    plr.CharacterAdded:Connect(function()
        task.wait(0.5)
        clearPlr(plr)
        if cfg.hulkEsp or cfg.survEsp or cfg.hbEsp then make(plr) end
    end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= lp then
        plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            clearPlr(plr)
            if cfg.hulkEsp or cfg.survEsp or cfg.hbEsp then make(plr) end
        end)
        if plr.Character then make(plr) end
    end
end

-- spins
local function isBrokeMsg(s)
    if not s then return false end
    s = tostring(s):lower()
    return s:find("not enough") or s:find("insufficient") or s:find("broke") or s:find("can't afford") or s:find("cannot afford") or s:find("no money")
end

local function formatResult(res)
    if type(res) ~= "table" then
        local s = tostring(res or "")
        if isBrokeMsg(s) or s == "" or s == "nil" then return nil end
        return s
    end
    local msg = res.Message or res.message
    if isBrokeMsg(msg) then return nil end
    if res.Success == false and not msg then return nil end
    local line = msg or res.Result or res.Unlocked or "hit something"
    if res.PityTriggered then line = line .. "  (pity)" end
    return tostring(line)
end

local function notifyReward(title, body)
    if not body then return end
    pcall(function()
        WindUI:Notify({ Title = title, Content = body, Duration = 5.5 })
    end)
end

local function doSpin(remote, title)
    if not remote then return end
    local ok, res = pcall(function() return remote:InvokeServer() end)
    if ok then notifyReward(title, formatResult(res)) end
end

local function startAbility()
    if abilityConn or not abilityRemote then return end
    abilityConn = task.spawn(function()
        while cfg.abilitySpin do
            doSpin(abilityRemote, "ability")
            task.wait(cfg.abilityDelay)
        end
        abilityConn = nil
    end)
end
local function stopAbility() cfg.abilitySpin = false end

local function startSkin()
    if skinConn or not skinRemote then return end
    skinConn = task.spawn(function()
        while cfg.skinSpin do
            doSpin(skinRemote, "skin")
            task.wait(cfg.skinDelay)
        end
        skinConn = nil
    end)
end
local function stopSkin() cfg.skinSpin = false end

local function startEmote()
    if emoteConn or not emoteRemote then return end
    emoteConn = task.spawn(function()
        while cfg.emoteSpin do
            doSpin(emoteRemote, "emote")
            task.wait(cfg.emoteDelay)
        end
        emoteConn = nil
    end)
end
local function stopEmote() cfg.emoteSpin = false end

-- Fast Mode: keep colors, only SmoothPlastic
local function setFast(on)
    cfg.fastMode = on

    local names = {"FacilityDustClient", "CombatEffectsClient", "SpiderManFxClient", "SpiderManClient"}
    local function setDisabled(name, state)
        local s = lp:FindFirstChild("PlayerScripts") and lp.PlayerScripts:FindFirstChild(name)
        if s and s:IsA("LocalScript") then s.Disabled = state end
        local sp = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
        local s2 = sp and sp:FindFirstChild(name)
        if s2 and s2:IsA("LocalScript") then s2.Disabled = state end
    end
    for _, n in ipairs(names) do setDisabled(n, on) end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire")
            or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = not on
        end
    end

    local cam = workspace:FindFirstChild("Camera")
    if cam then
        local holder = cam:FindFirstChild("FacilityDustHolder")
        if holder and on then holder:Destroy() end
    end

    if on then
        savedMaterials = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("UnionOperation") or obj:IsA("MeshPart") then
                if not savedMaterials[obj] then
                    savedMaterials[obj] = obj.Material
                end
                obj.Material = Enum.Material.SmoothPlastic
                obj.MaterialVariant = ""
            end
        end

        savedLighting = {
            GlobalShadows = lighting.GlobalShadows,
            Technology = lighting.Technology,
        }
        lighting.GlobalShadows = false
        pcall(function() lighting.Technology = Enum.Technology.Compatibility end)

        for _, name in ipairs({"Bloom", "Blur", "ColorCorrection", "DepthOfField", "HulkSkinSpinBlur", "SunRays"}) do
            local fx = lighting:FindFirstChild(name)
            if fx and (fx:IsA("PostEffect") or fx:IsA("BlurEffect") or fx:IsA("BloomEffect")
                or fx:IsA("DepthOfFieldEffect") or fx:IsA("SunRaysEffect") or fx:IsA("ColorCorrectionEffect")) then
                fx.Enabled = false
            end
        end
        for _, fx in ipairs(lighting:GetChildren()) do
            if fx:IsA("PostEffect") then fx.Enabled = false end
        end
    else
        for part, mat in pairs(savedMaterials) do
            pcall(function()
                if part and part.Parent then
                    part.Material = mat
                end
            end)
        end
        savedMaterials = {}
        if savedLighting.GlobalShadows ~= nil then
            lighting.GlobalShadows = savedLighting.GlobalShadows
        end
        pcall(function()
            if savedLighting.Technology then
                lighting.Technology = savedLighting.Technology
            end
        end)
    end
end

-- ui
local win = WindUI:CreateWindow({
    Title = "Survive the Hulk",
    Icon = "",
    Theme = "Dark",
    Size = UDim2.fromOffset(520, 420),
})

local tabEsp = win:Tab({ Title = "ESP", Icon = "eye" })
local tabShop = win:Tab({ Title = "Shop", Icon = "dollar-sign" })
local tabMisc = win:Tab({ Title = "Misc", Icon = "settings" })

tabEsp:Toggle({ Title = "Hulk ESP", Desc = "green highlight", Value = true, Callback = function(v) cfg.hulkEsp = v end })
tabEsp:Toggle({ Title = "Survivor ESP", Desc = "cyan highlight", Value = true, Callback = function(v) cfg.survEsp = v end })
tabEsp:Toggle({ Title = "Hulkbuster ESP", Desc = "orange highlight", Value = true, Callback = function(v) cfg.hbEsp = v end })
tabEsp:Toggle({ Title = "Names", Value = true, Callback = function(v) cfg.names = v end })
tabEsp:Toggle({ Title = "Health", Value = true, Callback = function(v) cfg.hp = v end })
tabEsp:Toggle({ Title = "Distance", Value = true, Callback = function(v) cfg.dist = v end })
tabEsp:Slider({ Title = "Max Distance", Value = { Min = 50, Max = 2000, Default = 2000 }, Callback = function(v) cfg.maxDist = v end })

local secA = tabShop:Section({ Title = "Ability" })
secA:Toggle({ Title = "Auto Spin", Value = false, Callback = function(v) cfg.abilitySpin = v if v then startAbility() else stopAbility() end end })
secA:Slider({ Title = "Delay", Value = { Min = 0.15, Max = 2, Default = 0.35 }, Callback = function(v) cfg.abilityDelay = v end })
secA:Button({ Title = "Spin Once", Callback = function() doSpin(abilityRemote, "ability") end })

local secS = tabShop:Section({ Title = "Hulk Skin" })
secS:Toggle({ Title = "Auto Spin", Value = false, Callback = function(v) cfg.skinSpin = v if v then startSkin() else stopSkin() end end })
secS:Slider({ Title = "Delay", Value = { Min = 0.15, Max = 2, Default = 0.35 }, Callback = function(v) cfg.skinDelay = v end })
secS:Button({ Title = "Spin Once", Callback = function() doSpin(skinRemote, "skin") end })

local secE = tabShop:Section({ Title = "Emote" })
secE:Toggle({ Title = "Auto Spin", Value = false, Callback = function(v) cfg.emoteSpin = v if v then startEmote() else stopEmote() end end })
secE:Slider({ Title = "Delay", Value = { Min = 0.15, Max = 2, Default = 0.35 }, Callback = function(v) cfg.emoteDelay = v end })
secE:Button({ Title = "Spin Once", Callback = function() doSpin(emoteRemote, "emote") end })

tabMisc:Toggle({
    Title = "Fast Mode",
    Desc = "smooth plastic (keeps colors) + no shadows/fx/dust",
    Value = false,
    Callback = function(v) setFast(v) end
})

tabMisc:Section({ Title = "Stats" })
local statsNote = tabMisc:Paragraph({ Title = "Live", Desc = "FPS: --\nPing: --" })

task.spawn(function()
    local frames, last = 0, tick()
    rs.Heartbeat:Connect(function()
        frames += 1
        local now = tick()
        if now - last >= 1 then
            local fps = frames
            frames = 0
            last = now
            local ping = 0
            pcall(function()
                ping = math.floor(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            pcall(function()
                if statsNote and statsNote.SetDesc then
                    statsNote:SetDesc(string.format("FPS: %d\nPing: %dms", fps, ping))
                end
            end)
        end
    end)
end)

-- safety: never keep self in draws
clearPlr(lp)

print("sth hub loaded | ESP never on self")
