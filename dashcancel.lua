local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Index = Packages:WaitForChild("_Index")
local Knit = Index:WaitForChild("sleitnick_knit@1.7.0"):WaitForChild("knit")
local Services = Knit:WaitForChild("Services")

local dashRemote = Services.StyleService.RF.RequestSpecialCallback
local jumpRemote = Services.BallService.RF.Jump

local enabled = true
local jumpDelay = 0.04

-- Better hook (checks by name instead of instance)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
	local method = getnamecallmethod()
	
	if enabled and method == "InvokeServer" then
		local name = tostring(self.Name)
		
		if name == "RequestSpecialCallback" then
			-- Dash detected → jump after tiny delay
			task.delay(jumpDelay, function()
				pcall(function()
					jumpRemote:InvokeServer(true)
				end)
			end)
		end
	end
	
	return oldNamecall(self, ...)
end))

print("Akari Dash Cancel v2 loaded - try dashing now")
