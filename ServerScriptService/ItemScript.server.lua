-- Services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- Constants

local ITEMS		= ReplicatedStorage.Items
local REMOTES	= ReplicatedStorage.Remotes

local DROPS		= Workspace.Drops

-- Variables

-- Functions

local function GetPosition(item)
	local config	= require(item.Config)
	
	if config.AttachPosition then
		return config.AttachPosition
	end
	
	if config.Type == "Melee" then
		return config.Size == "Small" and "Lower" or "Upper"
	elseif config.Type == "Booster" or config.Type == "Throwable" then
		return "Lower"
	elseif config.Type == "Gun" then
		if config.Size == "Light" then
			return "Lower"
		else
			return "Upper"
		end
	elseif config.Type == "Build" then
		return "Build"
	end
	
	return "Upper"
end

local function PrepareItem(item) -- weld, unanchor, and remove mass from an item
	local handle	= item.PrimaryPart
	handle.Name		= "Handle"
	
	for _, v in pairs(item:GetDescendants()) do
		if v:IsA("BasePart") and v ~= handle then
			local offset	= handle.CFrame:toObjectSpace(v.CFrame)
			
			local weld	= Instance.new("Weld")
				weld.Part0	= handle
				weld.Part1	= v
				weld.C0		= offset
				weld.Parent	= v
				
			--v.CustomPhysicalProperties	= PhysicalProperties.new(0, 0, 0, 1, 1)
			v.Massless		= true
			v.Anchored		= false
			v.CanCollide	= false
		end
	end
	--handle.CustomPhysicalProperties	= PhysicalProperties.new(0, 0, 0, 1, 1)
	handle.Massless		= true
	handle.Anchored		= false
	handle.CanCollide	= false
	
	local config	= require(item.Config)
	
	if config.Type == "Gun" or config.Type == "RocketLauncher" then
		local ammo	= Instance.new("IntValue")
			ammo.Name	= "Ammo"
			ammo.Value	= config.Magazine
			ammo.Parent	= item
		
		local attachments	= Instance.new("Folder")
			attachments.Name	= "Attachments"
			attachments.Parent	= item
	elseif config.Type == "Booster" or config.Type == "Throwable" then
		local stack		= Instance.new("IntValue")
			stack.Name		= "Stack"
			stack.Value		= config.Stack
			stack.Parent	= item
	end
end

local function Unequip(item) -- move an item from the hand to the back
	spawn(function() -- if i dont do this it breaks lmao im too lazy to fix it
		if item:IsDescendantOf(Workspace) then
			local character	= item.Parent.Parent
			local items		= character.Items
			local handle	= item.PrimaryPart
			
			-- remove equipped stuff
			if handle:FindFirstChild("GripMotor") then
				handle.GripMotor:Destroy()
			end
			
			local position		= GetPosition(item)
			local attachment
			
			attachment	= character[position .. "Torso"][item.CharacterSlot.Value]
			
			local backpackAttach	= character:FindFirstChild("Backpack" .. item.CharacterSlot.Value, true)
			if backpackAttach then
				attachment	= backpackAttach
			end
			
			-- add unequipped stuff
			local weld	= Instance.new("Weld")
				weld.Name	= "UnequippedWeld"
				weld.Part0	= attachment.Parent
				weld.Part1	= handle
				weld.C0		= attachment.CFrame
				weld.C1		= handle.Center.CFrame
				weld.Parent	= handle
		end
	end)
end

local function Equip(item) -- move an item from the back to the hand
	spawn(function()
		local character	= item.Parent.Parent
		local handle	= item.PrimaryPart
		
		-- remove unequipped stuff
		if handle:FindFirstChild("UnequippedWeld") then
			handle.UnequippedWeld:Destroy()
		end
		
		-- add equipped stuff
		local gripMotor		= Instance.new("Motor6D")
			gripMotor.Name		= "GripMotor"
			gripMotor.Part0		= character.RightHand
			gripMotor.Part1		= handle
			gripMotor.C0		= CFrame.Angles(-math.pi / 2, 0, 0)
			gripMotor.C1		= handle.Grip.CFrame
			gripMotor.Parent	= handle
	end)
end

local function HandleCharacter(character)
	local humanoid		= character.Humanoid
	local equipped		= character.Equipped
	local currentItem	= equipped.Value
	local items			= character.Items
	
	local function HandleItem(item)
		local charSlot	= item:FindFirstChild("CharacterSlot")
		if not charSlot then
			charSlot	= Instance.new("StringValue")
				charSlot.Name	= "CharacterSlot"
				charSlot.Parent	= item
		end
		
		local position	= GetPosition(item)
		
		for i = 1, 5 do
			local safe	= true
			for _, other in pairs(items:GetChildren()) do
				if other ~= item then
					if other.CharacterSlot.Value == position .. "Slot" .. tostring(i) then
						safe	= false
						break
					end
				end
			end
			if safe then
				charSlot.Value	= position .. "Slot" .. tostring(i)
				break
			end
		end
		
		Unequip(item)
	end
	
	for _, item in pairs(items:GetChildren()) do
		HandleItem(item)
	end
	
	items.ChildAdded:connect(HandleItem)
	
	items.ChildRemoved:connect(function(item)
		if equipped.Value == item then
			equipped.Value	= nil
		end
	end)
	
	if currentItem then
		Equip(currentItem)
	end
	
	equipped.Changed:connect(function()
		if currentItem then
			Unequip(currentItem)
		end
		if equipped.Value then
			Equip(equipped.Value)
		end
		currentItem	= equipped.Value
	end)
end

local function HandlePlayer(player)
	if player.Character then
		HandleCharacter(player.Character)
	end
	
	player.CharacterAdded:connect(HandleCharacter)
end

-- Initiate

for _, item in pairs(ITEMS:GetChildren()) do
	PrepareItem(item)
end

for _, player in pairs(Players:GetPlayers()) do
	HandlePlayer(player)
end

-- Events

REMOTES.Equip.OnServerEvent:connect(function(player, item)
	local character	= player.Character
	
	if character then
		local items		= character.Items
		local equipped	= character.Equipped
		
		if item then
			if item.Parent == items then
				equipped.Value	= item
			end
		else
			equipped.Value	= nil
		end
	end
end)

Players.PlayerAdded:connect(HandlePlayer)