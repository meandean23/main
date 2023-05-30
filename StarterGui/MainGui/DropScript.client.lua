-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local CAMERA	= Workspace.CurrentCamera
local DROPS		= Workspace:WaitForChild("Drops")
local ITEMS		= ReplicatedStorage:WaitForChild("Items")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local MOUSE		= require(MODULES:WaitForChild("Mouse"))
	local INPUT		= require(MODULES:WaitForChild("Input"))

local GUI			= script.Parent
local PICKUP_GUI	= GUI:WaitForChild("Pickup")

local PICKUP_DISTANCE	= 6

-- variables

local lastUpdate	= 0
local target

-- functions

-- events

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Pickup" then
			if target then
				PLAYER.Character.Animate.Pickup:Fire()
				REMOTES.Pickup:FireServer(target)
			end
		end
	end
end)

INPUT.KeybindChanged:connect(function(action)
	if action == "Pickup" then
		PICKUP_GUI.KeybindLabel.Text	= INPUT:GetActionInput(action)
	end
end)

REMOTES.Finished.OnClientEvent:connect(function()
	PICKUP_GUI.Visible	= false
	
	script.Disabled	= true
end)

-- initiate

PICKUP_GUI.KeybindLabel.Text	= INPUT:GetActionInput("Pickup")

RunService:BindToRenderStep("Pickup", Enum.RenderPriority.Last.Value, function(deltaTime)
	if tick() - lastUpdate > 0.1 then
		local newTarget
		lastUpdate		= tick()
		local character	= PLAYER.Character
		if character then
			local rootPart	= character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local pickups	= {}
				
				for _, drop in pairs(DROPS:GetChildren()) do
					local distance	= (drop.Position - rootPart.Position).Magnitude
					if distance < PICKUP_DISTANCE then
						table.insert(pickups, drop)
					end
				end
				
				if #pickups > 0 then
					local mousePos	= MOUSE.ScreenPosition --MOUSE.WorldPosition
					table.sort(pickups, function(a, b)
						local posA	= CAMERA:WorldToScreenPoint(a.Position)
						posA		= Vector2.new(posA.X, posA.Y)
						local posB	= CAMERA:WorldToScreenPoint(b.Position)
						posB		= Vector2.new(posB.X, posB.Y)
						
						local distA	= (posA - mousePos).Magnitude
						local distB	= (posB - mousePos).Magnitude
						return distA < distB
					end)
					newTarget	= pickups[1]
				end
				
				for _, pickup in pairs(pickups) do
					local base		= ITEMS[pickup.Name]
					local config	= require(base.Config)
					
					if config.Type == "Ammo" or config.Type == "Armor" or config.Type == "Booster" then
						local distance	= (rootPart.Position - pickup.Position).Magnitude
						if distance <= 3 then
							REMOTES.Pickup:FireServer(pickup)
						end
					end
				end
			end
		end
		
		target	= newTarget
	end
	
	if target then
		PICKUP_GUI.Visible	= true
		local position		= CAMERA:WorldToScreenPoint(target.Position)
		
		PICKUP_GUI.Position	= UDim2.new(0, position.X, 0, position.Y)
		PICKUP_GUI.ItemLabel.Text	= string.upper(target.Name)
		
		--[[if target:FindFirstChild("Stack") then
			PICKUP_GUI.CountLabel.Visible	= true
			PICKUP_GUI.CountLabel.Text		= target.Stack.Value
		elseif target:FindFirstChild("Ammo") then
			PICKUP_GUI.CountLabel.Visible	= true
			PICKUP_GUI.CountLabel.Text		= target.Ammo.Value
		else
			PICKUP_GUI.CountLabel.Visible	= false
		end]]
	else
		PICKUP_GUI.Visible	= false
	end
end)