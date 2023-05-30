-- services

local MarketplaceService	= game:GetService("MarketplaceService")
local UserInputService		= game:GetService("UserInputService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local Players				= game:GetService("Players")
local Lighting				= game:GetService("Lighting")
local StarterGui			= game:GetService("StarterGui")

-- constants

local PLAYER	= Players.LocalPlayer

local EVENTS	= ReplicatedStorage:WaitForChild("Events")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local INPUT		= require(MODULES:WaitForChild("Input"))

local GUI		= script.Parent
local AMMO_GUI	= GUI:WaitForChild("Ammo")
local MAP_GUI	= GUI:WaitForChild("Map")

local INV_BLUR	= Lighting:WaitForChild("InventoryBlur")
local INV_COLOR	= Lighting:WaitForChild("InventoryColor")

-- variables

local open	= false

local armorTimer	= 0
local deliveryTimer	= 0

-- functions

local function Toggle()
	open	= not open
	
	EVENTS.Modal:Fire(open and "Push" or "Pop")
	INV_BLUR.Enabled	= open
	INV_COLOR.Enabled	= open
	
	AMMO_GUI.Visible	= open
	MAP_GUI.Visible		= open
	
	if open then
		script.OpenSound:Play()
	else
		script.CloseSound:Play()
	end
end

-- initiate

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

-- events

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Inventory" then
			Toggle()
		end
	end
end)