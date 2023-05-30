-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")
local Debris			= game:GetService("Debris")

-- constants

local PLAYER	= Players.LocalPlayer
local ITEMS		= ReplicatedStorage:WaitForChild("Items")

-- variables

local sounds	= {}

-- functions

local function HandleCharacter(character)
	if character then
		spawn(function()
			local rootPart	= character:WaitForChild("HumanoidRootPart")
			local humanoid	= character:WaitForChild("Humanoid")
			
			local ammo			= character:WaitForChild("Ammo")
			local items			= character:WaitForChild("Items")
			local equipped		= character:WaitForChild("Equipped")
			local healthPacks	= character:WaitForChild("HealthPacks")
			
			local lastEquipSound
			
			local lastHealthPacks	= healthPacks.Value
			
			-- sound function
			local function PlaySound(s, vScale)
				if not sounds[s] then
					sounds[s]	= {}
					for _, v in pairs(script.Sounds:GetChildren()) do
						if string.match(v.Name, "^" .. s .. "Sound") then
							table.insert(sounds[s], v)
						end
					end
				end
				
				local sound	= sounds[s][math.random(#sounds[s])]:Clone()
					sound.Volume	= sound.Volume * vScale
					sound.Parent	= rootPart
				
				sound:Play()
				Debris:AddItem(sound, sound.TimeLength)
			end
			
			-- variables
			local grounded		= false	
			local lastStep		= 0
			local volumeScale	= 1
			
			if character == PLAYER.Character then
				volumeScale	= 0.3
			end
			
			-- events
			for _, a in pairs(ammo:GetChildren()) do
				local last	= a.Value
				
				a.Changed:connect(function()
					if a.Value > last then
						PlaySound("AmmoPickup", 1)
					end
					
					last	= a.Value
				end)
			end
			
			healthPacks.Changed:connect(function()
				if healthPacks.Value > lastHealthPacks then
					PlaySound("ItemPickup", 1)
				end
				
				lastHealthPacks	= healthPacks.Value
			end)
			
			items.ChildAdded:connect(function(item)
				PlaySound("ItemPickup", 1)
				
				local base	= ITEMS[item.Name]
				if base:FindFirstChild("Attachments") then
					local attachments	= item:WaitForChild("Attachments")
					
					attachments.ChildAdded:connect(function()
						PlaySound("AttachmentPickup", 1)
					end)
				end
			end)
			
			equipped.Changed:connect(function()
				if lastEquipSound then
					lastEquipSound:Stop()
				end
				
				local item	= equipped.Value
				if item then
					local handle	= item.PrimaryPart
					if handle:FindFirstChild("EquipSound") then
						handle.EquipSound:Play()
						lastEquipSound	= handle.EquipSound
					end
				end
			end)
			
			humanoid.StateChanged:connect(function(_, state)
				if state == Enum.HumanoidStateType.Jumping then
					PlaySound("Jump", volumeScale)
				elseif state == Enum.HumanoidStateType.Landed then
					PlaySound("Land", volumeScale)
				elseif state == Enum.HumanoidStateType.Freefall then
					grounded	= false
				elseif state == Enum.HumanoidStateType.Running then
					grounded	= true
				end
			end)
			
			humanoid.Died:connect(function()
				PlaySound("Death", 1)
			end)
			
			while character and character:IsDescendantOf(Workspace) do
				RunService.Stepped:wait()
				
				if grounded then
					local speed		= Vector2.new(rootPart.Velocity.X, rootPart.Velocity.Z).Magnitude
					local elapsed	= tick() - lastStep
					local rate		= 999999
					if speed > 0 then
						rate	= 8 / speed
					end
					
					if elapsed > rate then
						PlaySound("Step", volumeScale)
						lastStep	= tick()
					end
				end
			end
		end)
	end
end

-- initiate

for _, player in pairs(Players:GetPlayers()) do
	HandleCharacter(player.Character)
	
	player.CharacterAdded:connect(HandleCharacter)
end

-- events

Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(HandleCharacter)
end)