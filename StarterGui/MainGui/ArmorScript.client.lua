-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local SoundService		= game:GetService("SoundService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")
local Debris			= game:GetService("Debris")

-- constants

local PLAYER	= Players.LocalPlayer
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

local GUI			= script.Parent
local ARMOR_GUI		= GUI:WaitForChild("Armor")

local MAX_SLOTS	= 5
local SLOT_SIZE	= 30

-- variables

local character, humanoid, armor, armorSlots

local slots		= {}

-- functions

local function UpdateArmor()
	local numSlots	= armorSlots.Value
	local fullSlots	= math.floor(armor.Value / SLOT_SIZE)
	local remainder	= armor.Value - (fullSlots * SLOT_SIZE)
	
	for i = 5, 1, -1 do
		local slot	= slots[i]
		
		if i <= numSlots then
			if not slot then
				local slot	= script.Slot:Clone()
					slot.Parent	= ARMOR_GUI
					
				slots[i]	= slot
			end
		else
			if slot then
				slot:Destroy()
				slots[i]	= nil
			end
		end
		
		
		slot	= slots[i]
		if slot then
			slot.LayoutOrder	= i
			if i <= fullSlots then
				slot.Bar.Size	= UDim2.new(1, 0, 1, 0)
			elseif i <= fullSlots + 1 then
				slot.Bar.Size	= UDim2.new(remainder / SLOT_SIZE, 0, 1, 0)
			else
				slot.Bar.Size	= UDim2.new(0, 0, 1, 0)
			end
		end
	end
end

local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		
		humanoid	= newCharacter:WaitForChild("Humanoid")
		armor		= humanoid:WaitForChild("Armor")
		armorSlots	= humanoid:WaitForChild("ArmorSlots")
		
		UpdateArmor()
		
		armor.Changed:connect(UpdateArmor)
		armorSlots.Changed:connect(UpdateArmor)
	end
end

-- initiate

HandleCharacter(PLAYER.Character)

-- events

REMOTES.Finished.OnClientEvent:connect(function()
	ARMOR_GUI.Visible	= false
	
	script.Disabled	= true
end)

PLAYER.CharacterAdded:connect(HandleCharacter)