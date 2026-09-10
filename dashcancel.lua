local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local Services = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
local dashRemote = Services.StyleService.RF.RequestSpecialCallback

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "DashCancelUI"
gui.ResetOnSpawn = false
gui.Parent = PG

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 150, 0, 45)
btn.Position = UDim2.new(0.5, -75, 0.75, 0)
btn.BackgroundColor3 = Color3.fromRGB(145, 70, 255)
btn.Text = "DASH CANCEL"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 16
btn.Parent = gui
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

-- Draggable
local dragging, dragStart, startPos
btn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = btn.Position
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- Dash + Jump
btn.MouseButton1Click:Connect(function()
	-- Fire Dash
	pcall(function()
		dashRemote:InvokeServer()
	end)

	-- Force jump the normal Roblox way
	task.delay(0.03, function()
		local char = LP.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Jump = true
			end
		end
	end)
end)

print("Dash Cancel (Humanoid Jump) loaded")
