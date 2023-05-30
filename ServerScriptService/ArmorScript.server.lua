-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players			= game:GetService("Players")

-- constants

local CUSTOMIZATION	= ReplicatedStorage.Customization
local PLAYER_DATA	= ReplicatedStorage.PlayerData
local REMOTES		= ReplicatedStorage.Remotes

local MAX_SLOTS	= 5
local SLOT_SIZE	= 30

-- functions

local function HandleCharacter(character)
	local player	= Players:GetPlayerFromCharacter(character)
	local playerData
	if player then
		playerData	= PLAYER_DATA:WaitForChild(player.Name)
	end
	
	if character then
		local humanoid	= character.Humanoid
		local armor		= humanoid.Armor
		local slots		= humanoid.ArmorSlots
		
		local lastSlots	= slots.Value
		
		armor.Changed:connect(function()
			local activeSlots	= math.ceil(armor.Value / SLOT_SIZE)
			slots.Value			= activeSlots
		end)
		
		slots.Changed:connect(function()
			if slots.Value > lastSlots then
				REMOTES.Effect:FireAllClients("Booster", character, "Armor")
			elseif slots.Value < lastSlots then
				REMOTES.Effect:FireAllClients("Shatter", character, "Armor")
			end
			
			lastSlots	= slots.Value
			
			-- remove old armor
			character.Armor:ClearAllChildren()
			
			if slots.Value > 0 then
				local armor	= CUSTOMIZATION.Armors.Default
				if playerData then
					if CUSTOMIZATION.Armors:FindFirstChild(playerData.Equipped.Armor.Value) then
						armor	= CUSTOMIZATION.Armors[playerData.Equipped.Armor.Value]
					end
				end
				local armor	= armor["Tier" .. tostring(slots.Value)]:Clone()
				
				local primary	= armor.PrimaryPart
				local attach	= character[primary.Name]
				
				for _, v in pairs(armor:GetChildren()) do
					if v:IsA("BasePart") and v ~= primary then
						v.CanCollide	= false
						v.Massless		= true
						
						local offset	= primary.CFrame:toObjectSpace(v.CFrame)
						
						local weld	= Instance.new("Weld")
							weld.Part0	= attach
							weld.Part1	= v
							weld.C0		= offset
							weld.Parent	= v
							
						v.Anchored	= false
					end
				end
				
				primary:Destroy()
					
				armor.Parent	= character.Armor
			end
		end)
	end
end

local function HandlePlayer(player)
	player.CharacterAdded:connect(HandleCharacter)
	
	HandleCharacter(player.Character)
end

local function AddArmor(character, amount)
	local armor	= character.Humanoid.Armor
	local slots	= character.Humanoid.ArmorSlots
	
	if armor.Value < MAX_SLOTS * SLOT_SIZE then
		slots.Value	= math.min(slots.Value + amount, MAX_SLOTS)
		armor.Value	= math.min(armor.Value + amount * SLOT_SIZE, MAX_SLOTS * SLOT_SIZE)
		
		return true
	end
	
	return false
end

local function Boost(character, amount)
	local humanoid	= character.Humanoid
	local armor		= humanoid.Armor
	local slots		= humanoid.ArmorSlots
	
	local maxArmor	= slots.Value * SLOT_SIZE
	
	armor.Value		= math.min(armor.Value + amount * SLOT_SIZE, maxArmor)
end

-- events

Players.PlayerAdded:connect(HandlePlayer)

script.AddArmor.OnInvoke = AddArmor
script.Boost.Event:connect(Boost)