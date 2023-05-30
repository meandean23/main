-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer

local EVENTS	= ReplicatedStorage:WaitForChild("Events")

local GUI		= script.Parent
local GUN_GUI	= GUI:WaitForChild("Gun")

-- variables

local character, ammo
local ammoConnection

local currentSize	= "Light"
local currentAmmo	= 0

-- functions

local function Update()
	GUN_GUI.AmmoLabel.Text	= tostring(currentAmmo)
	
	if character then
		GUN_GUI.TotalLabel.Text	= tostring(ammo[currentSize].Value)
	end
end

local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		
		ammo		= newCharacter:WaitForChild("Ammo")
		character	= newCharacter
	end
end

-- initiate

HandleCharacter(PLAYER.Character)

-- events

EVENTS.Gun.Event:connect(function(action, ...)
	if action == "Enable" then
		currentSize, currentAmmo	= ...
		
		Update()
		GUN_GUI.Visible	= true
		
		if ammoConnection then
			ammoConnection:Disconnect()
			ammoConnection	= nil
		end
		
		if character then
			ammoConnection	= ammo[currentSize].Changed:connect(function()
				Update()
			end)
		end
	elseif action == "Disable" then
		GUN_GUI.Visible	= false
	elseif action == "Update" then
		currentAmmo	= ...
		Update()
	end
end)

PLAYER.CharacterAdded:connect(HandleCharacter)