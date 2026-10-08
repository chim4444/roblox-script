-- sth hub
-- spin results: skip broke msgs, longer cooler reward notifs

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

local cfg = {
    hulk = false,
    survivor = false,
    names = true,
    dist = true,
    hp = true,
    maxdist = 2000,
    hulkcol = Color3.fromRGB(0, 255, 80),
    survcol = Color3.fromRGB(0, 170, 255),
    abilitySpin = false,
    skinSpin = false,
    emoteSpin = false,
    abilityDelay = 0.15,
    skinDelay = 0.15,
    emoteDelay = 0.15,
    showResults = true,
}

local draws = {}
local abilityConn, skinConn, emoteConn

local abilityRemote, skinRemote, emoteRemote
pcall(function()
    local sys = ReplicatedStorage:WaitForChild("HulkSkinSystem", 5)
    if sys then
        abilityRemote = sys:FindFirstChild("AbilitySpin")
        skinRemote = sys:FindFirstChild("Spin")
        emoteRemote = sys:FindFirstChild("EmoteSpin")
    end
end)

local function isBrokeMsg(s)
    if not s then return false end
    s = string.lower(tostring(s))
    return s:find("not enough")
        or s:find("enough money")
        or s:find("enough cash")
        or s:find("insufficient")
        or s:find("can't afford")
        or s:find("cant afford")
        or s:find("no money")
        or s:find("broke")
        or s:find("need more")
end

local function formatResult(r)
    if r == nil then return nil end
    if type(r) == "string" or type(r) == "number" then
        local s = tostring(r)
        if isBrokeMsg(s) then return nil end
        return s
    end
    if type(r) == "table" then
        -- skip failed / no money
        if r.Success == false then
            local msg = r.Message or r.Error or r.error
            if isBrokeMsg(msg) or msg then return nil end
            return nil
        end
        if r.Message and isBrokeMsg(r.Message) then return nil end

        if r.Message and tostring(r.Message) ~= "" then
            return tostring(r.Message)
        end
        local name = r.Result or r.Name or r.name or r.Item or r.Reward
        if name then
            local tag = ""
            if r.Unlocked == true then tag = " · unlocked" end
            if r.PityTriggered == true then tag = tag .. " · pity" end
            return tostring(name) .. tag
        end
        return nil
    end
    return nil
end

local function notifyReward(label, text)
    if not text or text == "" then return end
    WindUI:Notify({
        Title = label,
        Content = text,
        Duration = 5.5,
        Icon = "sparkles",
    })
end

local function doSpin(remote, label)
    if not remote then return end
    local ok, result = pcall(function()
        return remote:InvokeServer()
    end)
    if not ok or not cfg.showResults then return end
    local text = formatResult(result)
    if text then
        notifyReward(label, text)
    end
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

local function stopAbility()
    cfg.abilitySpin = false
    abilityConn = nil
end

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

local function stopSkin()
    cfg.skinSpin = false
    skinConn = nil
end

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

local function stopEmote()
    cfg.emoteSpin = false
    emoteConn = nil
end

-- esp
local function isHulk(plr)
    if not plr or not plr.Character then return false end
    local c = plr.Character
    if c:FindFirstChild("Hulk") or c:FindFirstChild("IsHulk") then return true end
    if plr:GetAttribute("Role") == "Hulk" or plr:GetAttribute("IsHulk") then return true end
    if plr.Team then
        local t = tostring(plr.Team.Name):lower()
        if t:find("hulk") or t:find("killer") then return true end
    end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.HipHeight > 4 then return true end
    if c.Name:lower():find("hulk") then return true end
    return false
end

local function getHp(plr)
    local c = plr.Character
    if not c then return 0, 100 end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        return math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5)
    end
    return 0, 100
end

local function wipe(plr)
    local d = draws[plr]
    if not d then return end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    if d.bb then pcall(function() d.bb:Destroy() end) end
    draws[plr] = nil
end

local function make(plr, hulk)
    if plr == lp then return end
    wipe(plr)

    local c = plr.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
    if not root then return end

    local col = hulk and cfg.hulkcol or cfg.survcol
    local d = {}

    local hl = Instance.new("Highlight")
    hl.Name = "sth_hl"
    hl.Adornee = c
    hl.FillColor = col
    hl.OutlineColor = col
    hl.FillTransparency = 0.55
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = c
    d.hl = hl
    d.hulk = hulk

    local bb = Instance.new("BillboardGui")
    bb.Name = "sth_bb"
    bb.Adornee = root
    bb.Size = UDim2.new(0, 220, 0, 70)
    bb.StudsOffset = Vector3.new(0, 3.4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = c

    local lab = Instance.new("TextLabel")
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.BackgroundTransparency = 1
    lab.TextColor3 = col
    lab.TextStrokeTransparency = 0.3
    lab.Font = Enum.Font.GothamBold
    lab.TextSize = 14
    lab.Text = plr.Name
    lab.Parent = bb

    d.bb = bb
    d.label = lab
    draws[plr] = d
end

local function tickEsp()
    for plr, d in pairs(draws) do
        if not plr.Parent or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then
            wipe(plr)
            continue
        end

        local nowHulk = isHulk(plr)
        if d.hulk ~= nowHulk then
            make(plr, nowHulk)
            continue
        end

        local root = plr.Character.HumanoidRootPart
        local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 9999

        if dist > cfg.maxdist then
            if d.hl then d.hl.Enabled = false end
            if d.bb then d.bb.Enabled = false end
        else
            if d.hl then d.hl.Enabled = true end
            if d.bb then d.bb.Enabled = true end

            if d.label then
                local lines = {}
                if cfg.names then table.insert(lines, plr.Name) end
                if cfg.hp then
                    local hp, max = getHp(plr)
                    table.insert(lines, "HP: "..hp.."/"..max)
                end
                if cfg.dist then
                    table.insert(lines, "["..math.floor(dist).."m]")
                end
                d.label.Text = table.concat(lines, "\n")
            end
        end
    end
end

local function refresh()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == lp then continue end
        local h = isHulk(plr)
        local show = (h and cfg.hulk) or (not h and cfg.survivor)
        if show and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not draws[plr] or draws[plr].hulk ~= h then
                make(plr, h)
            end
        else
            wipe(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.4)
        refresh()
    end)
end)

Players.PlayerRemoving:Connect(wipe)

for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.4)
        refresh()
    end)
end

RunService.RenderStepped:Connect(function()
    if cfg.hulk or cfg.survivor then
        tickEsp()
    end
end)

task.spawn(function()
    while true do
        task.wait(3)
        if cfg.hulk or cfg.survivor then
            refresh()
        end
    end
end)

-- ui
local win = WindUI:CreateWindow({
    Title = "Survive the Hulk",
    Icon = "",
    Theme = "Dark",
    Folder = "sth",
})

local tab = win:Tab({ Title = "ESP", Icon = "eye" })
local shop = win:Tab({ Title = "Shop", Icon = "dollar-sign" })

tab:Toggle({
    Title = "Hulk ESP",
    Desc = "green highlight",
    Value = false,
    Flag = "hulk",
    Callback = function(v)
        cfg.hulk = v
        refresh()
    end,
})

tab:Toggle({
    Title = "Survivor ESP",
    Desc = "cyan highlight",
    Value = false,
    Flag = "survivor",
    Callback = function(v)
        cfg.survivor = v
        refresh()
    end,
})

tab:Space()

tab:Toggle({
    Title = "Names",
    Value = true,
    Flag = "names",
    Callback = function(v) cfg.names = v end,
})

tab:Toggle({
    Title = "Health",
    Value = true,
    Flag = "hp",
    Callback = function(v) cfg.hp = v end,
})

tab:Toggle({
    Title = "Distance",
    Value = true,
    Flag = "dist",
    Callback = function(v) cfg.dist = v end,
})

tab:Slider({
    Title = "Max Distance",
    Step = 50,
    Value = { Min = 100, Max = 3000, Default = 2000 },
    Flag = "maxdist",
    Callback = function(v) cfg.maxdist = v end,
})

shop:Toggle({
    Title = "Show Results",
    Desc = "only real pulls, no broke spam",
    Value = true,
    Flag = "showResults",
    Callback = function(v) cfg.showResults = v end,
})

shop:Space()
shop:Section({ Title = "Ability" })

shop:Toggle({
    Title = "Auto Spin",
    Desc = "abilities",
    Value = false,
    Flag = "abilitySpin",
    Callback = function(v)
        cfg.abilitySpin = v
        if v then
            if not abilityRemote then return end
            startAbility()
        else
            stopAbility()
        end
    end,
})

shop:Slider({
    Title = "Speed",
    Desc = "lower = faster",
    Step = 0.01,
    Value = { Min = 0.05, Max = 0.40, Default = 0.15 },
    Flag = "abilityDelay",
    Callback = function(v) cfg.abilityDelay = v end,
})

shop:Button({
    Title = "Spin Once",
    Icon = "refresh-cw",
    Callback = function() doSpin(abilityRemote, "ability") end,
})

shop:Space()
shop:Section({ Title = "Hulk Skins" })

shop:Toggle({
    Title = "Auto Spin",
    Desc = "skins",
    Value = false,
    Flag = "skinSpin",
    Callback = function(v)
        cfg.skinSpin = v
        if v then
            if not skinRemote then return end
            startSkin()
        else
            stopSkin()
        end
    end,
})

shop:Slider({
    Title = "Speed",
    Desc = "lower = faster",
    Step = 0.01,
    Value = { Min = 0.05, Max = 0.40, Default = 0.15 },
    Flag = "skinDelay",
    Callback = function(v) cfg.skinDelay = v end,
})

shop:Button({
    Title = "Spin Once",
    Icon = "refresh-cw",
    Callback = function() doSpin(skinRemote, "skin") end,
})

shop:Space()
shop:Section({ Title = "Emotes" })

shop:Toggle({
    Title = "Auto Spin",
    Desc = "emotes",
    Value = false,
    Flag = "emoteSpin",
    Callback = function(v)
        cfg.emoteSpin = v
        if v then
            if not emoteRemote then return end
            startEmote()
        else
            stopEmote()
        end
    end,
})

shop:Slider({
    Title = "Speed",
    Desc = "lower = faster",
    Step = 0.01,
    Value = { Min = 0.05, Max = 0.40, Default = 0.15 },
    Flag = "emoteDelay",
    Callback = function(v) cfg.emoteDelay = v end,
})

shop:Button({
    Title = "Spin Once",
    Icon = "refresh-cw",
    Callback = function() doSpin(emoteRemote, "emote") end,
})

WindUI:Notify({
    Title = "sth",
    Content = "up",
    Duration = 2,
})

print("sth hub up")
