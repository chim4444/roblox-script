-- sth esp hub
-- windui + hulk/survivor esp

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
}

local draws = {} -- [plr] = {hl, bb, label}

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
    if d.hl then d.hl:Destroy() end
    if d.bb then d.bb:Destroy() end
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
            if not draws[plr] then
                make(plr, h)
            end
        else
            wipe(plr)
        end
    end
end

-- hooks
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        refresh()
    end)
end)

Players.PlayerRemoving:Connect(wipe)

for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
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
        task.wait(1.5)
        if cfg.hulk or cfg.survivor then
            refresh()
        end
    end
end)

-- ui
local win = WindUI:CreateWindow({
    Title = "Survive the Hulk",
    Icon = "eye",
    Theme = "Dark",
    Folder = "sth",
})

local tab = win:Tab({ Title = "ESP", Icon = "eye" })

tab:Toggle({
    Title = "Hulk ESP",
    Desc = "green on the big guy",
    Value = false,
    Flag = "hulk",
    Callback = function(v)
        cfg.hulk = v
        refresh()
    end,
})

tab:Toggle({
    Title = "Survivor ESP",
    Desc = "cyan on everyone else",
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

tab:Button({
    Title = "Refresh",
    Icon = "refresh-cw",
    Callback = function()
        refresh()
        WindUI:Notify({ Title = "esp", Content = "refreshed", Duration = 2 })
    end,
})

WindUI:Notify({
    Title = "Survive the Hulk",
    Content = "esp ready",
    Icon = "eye",
    Duration = 3,
})

print("sth esp up")
