-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER		= Players.LocalPlayer
local ITEM_MODULES	= ReplicatedStorage:WaitForChild("ItemModules")
local MODULES		= ReplicatedStorage:WaitForChild("Modules")
	local INPUT			= require(MODULES:WaitForChild("Input"))

-- variables

local itemModules	= {}

-- functions

local function HandleItem(item)
	local config	= require(item:WaitForChild("Config"))
	
	if ITEM_MODULES:FindFirstChild(config.Type) then
		local module		= require(ITEM_MODULES[config.Type])
		local itemModule	= module:Create(item)
		
		itemModules[item]	= itemModule
		itemModule:Connect()
	end
end

local function HandleCharacter(character)
	if character then
		for item, module in pairs(itemModules) do
			module:Disconnect()
		end
		itemModules	= {}
		
		local items			= character:WaitForChild("Items")
		local equipped		= character:WaitForChild("Equipped")
		local currentItem	= equipped.Value
		
		repeat RunService.Stepped:wait() until character:IsDescendantOf(Workspace)
		
		for _, item in pairs(items:GetChildren()) do
			HandleItem(item)
		end
		
		if currentItem then
			itemModules[currentItem]:Equip()
		end
		
		equipped.Changed:connect(function()
			if currentItem and itemModules[currentItem] then
				itemModules[currentItem]:Unequip()
			end
			if equipped.Value then
				if itemModules[equipped.Value] then
					itemModules[equipped.Value]:Equip()
				end
			end
			
			currentItem	= equipped.Value
		end)
		
		items.ChildAdded:connect(HandleItem)
		
		items.ChildRemoved:connect(function(item)
			if itemModules[item] then
				itemModules[item]:Unequip()
				itemModules[item]:Disconnect()
				itemModules[item]	= nil
			end
		end)
	end
end

-- initiate

HandleCharacter(PLAYER.Character)

-- events

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Primary" then
			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
				local character	= PLAYER.Character
				if character then
					local equipped	= character.Equipped
					if itemModules[equipped.Value] then
						itemModules[equipped.Value]:Activate()
					end
				end
			end
		end
	end
end)

INPUT.ActionEnded:connect(function(action, processed)
	if not processed then
		if action == "Primary" then
			local character	= PLAYER.Character
			if character then
				local equipped	= character.Equipped
				if itemModules[equipped.Value] then
					itemModules[equipped.Value]:Deactivate()
				end
			end
		end
	end
end)

PLAYER.CharacterAdded:connect(HandleCharacter)