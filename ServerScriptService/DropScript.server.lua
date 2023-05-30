-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local RunService			= game:GetService("RunService")
local Workspace				= game:GetService("Workspace")
local Players				= game:GetService("Players")

-- constants

local ITEMS		= ReplicatedStorage.Items
local REMOTES	= ReplicatedStorage.Remotes
local DROPS		= Workspace.Drops

local DROP		= Instance.new("Part")
	DROP.Name			= "Drop"
	DROP.Anchored		= true
	DROP.CanCollide		= false
	DROP.TopSurface		= Enum.SurfaceType.Smooth
	DROP.BottomSurface	= Enum.SurfaceType.Smooth
	DROP.Material		= Enum.Material.Neon
	DROP.Color			= Color3.new(0.2, 0.6, 0.5)
	DROP.Transparency	= 1
	DROP.Size			= Vector3.new(2, 2, 2)
	
local PICKUP_DISTANCE	= 10

local DROP_OFFSET	= Vector3.new(2, 0, -3)

local MAX_BACKPACK		= 4
local MAX_HEALTH_PACKS	= 10

-- variables

-- functions

local function DropAmmo(ammo, position, amount)
	local drop	= DROP:Clone()
		drop.Name	= ammo
		drop.CFrame	= CFrame.new(position)
		
		local itemValue		= Instance.new("StringValue")
			itemValue.Name		= "Ammo"
			itemValue.Value		= ammo
			itemValue.Parent	= drop
			
		local amountValue	= Instance.new("IntValue")
			amountValue.Name	= "Stack"
			amountValue.Value	= amount
			amountValue.Parent	= drop
		
		drop.Parent	= DROPS
end

local function DropAttachment(attachment, position)
	local drop	= DROP:Clone()
		drop.Name	= attachment
		drop.CFrame	= CFrame.new(position)
		
		local itemValue		= Instance.new("StringValue")
			itemValue.Name		= "Attachment"
			itemValue.Value		= attachment
			itemValue.Parent	= drop
		
		drop.Parent	= DROPS
end

local function DropArmor(armor, position)
	local drop	= DROP:Clone()
		drop.Name	= armor
		drop.CFrame	= CFrame.new(position)
		
		local itemValue		= Instance.new("StringValue")
			itemValue.Name		= "Armor"
			itemValue.Value		= armor
			itemValue.Parent	= drop
		
		drop.Parent	= DROPS
end

local function DropItem(item, position, base)
	if not base then
		base	= ITEMS:FindFirstChild(item)
	end
	
	local drop	= DROP:Clone()
		drop.Name	= item
		drop.CFrame	= CFrame.new(position)
		
		local itemValue		= Instance.new("StringValue")
			itemValue.Name		= "Item"
			itemValue.Value		= item
			itemValue.Parent	= drop
		
		if base:FindFirstChild("Ammo") then
			base.Ammo:Clone().Parent	= drop
		end
		
		if base:FindFirstChild("Loaded") then
			base.Loaded:Clone().Parent	= drop
		end
		
		if base:FindFirstChild("Attachments") then
			local attachments	= Instance.new("Folder")
				attachments.Name	= "Attachments"
				attachments.Parent	= drop
				
			for _, attachment in pairs(base.Attachments:GetChildren()) do
				local val	= Instance.new("StringValue")
					val.Name	= attachment.Name
					val.Value	= attachment.Name
					val.Parent	= attachments
			end
		end
		
		drop.Parent	= DROPS
end

local function DropBooster(item, position, amount)
	local base	= ITEMS:FindFirstChild(item)
	
	local drop	= DROP:Clone()
		drop.Name	= item
		drop.CFrame	= CFrame.new(position)
		
		local itemValue		= Instance.new("StringValue")
			itemValue.Name		= "Booster"
			itemValue.Value		= item
			itemValue.Parent	= drop
		
		
		local stackValue	= Instance.new("IntValue")
			stackValue.Name		= "Stack"
			stackValue.Value	= (amount ~= nil and amount or base.Stack.Value)
			stackValue.Parent	= drop
		
		drop.Parent	= DROPS
end

local function DropThrowable(item, position, base)
	if not base then
		base	= ITEMS:FindFirstChild(item)
	end
	
	local drop	= DROP:Clone()
		drop.Name	= item
		drop.CFrame	= CFrame.new(position)
		
		local itemValue		= Instance.new("StringValue")
			itemValue.Name		= "Throwable"
			itemValue.Value		= item
			itemValue.Parent	= drop
		
		if base:FindFirstChild("Stack") then
			base.Stack:Clone().Parent	= drop
		else
			local stackValue	= Instance.new("IntValue")
				stackValue.Name		= "Stack"
				stackValue.Value	= 1
				stackValue.Parent	= drop
		end
		
		drop.Parent	= DROPS
end

local function Drop(item, position, ...)
	local ignore	= {Workspace.Effects, Workspace.Drops, Workspace.ItemSpawns}
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	
	local ray		= Ray.new(position + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0))
	local _, pos	= Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
	
	position	= pos + Vector3.new(0, 2, 0)
	
	local base		= ITEMS[item]
	local config	= require(base.Config)
	
	if config.Type == "Ammo" then
		DropAmmo(item, position, ...)
	elseif config.Type == "Booster" then
		DropBooster(item, position, ...)
	elseif config.Type == "Throwable" then
		DropThrowable(item, position, ...)
	elseif config.Type == "Armor" then
		DropArmor(item, position, ...)
	elseif config.Type == "Attachment" then
		DropAttachment(item, position, ...)
	else
		DropItem(item, position, ...)
	end
end

local function AddAttachment(item, attach)
	local attachments	= item:FindFirstChild("Attachments")
	local config		= require(ITEMS[attach].Config)
						
	if attachments and not attachments:FindFirstChild(attach) then
		if item.PrimaryPart:FindFirstChild(config.Attach .. "Attach") then
			local attachment	= ITEMS[attach]:Clone()
			
			for _, a in pairs(attachments:GetChildren()) do
				local c	= require(a.Config)
				if c.Attach == config.Attach then
					DropAttachment(a.Name, item.Parent.Parent.HumanoidRootPart.CFrame:pointToWorldSpace(Vector3.new(0, 0, -3)))
					a:Destroy()
				end
			end
			
			local weld	= Instance.new("Weld")
				weld.Part0	= item.PrimaryPart
				weld.Part1	= attachment.PrimaryPart
				weld.C0		= item.PrimaryPart[config.Attach .. "Attach"].CFrame
				weld.C1		= attachment.PrimaryPart.Attach.CFrame
				weld.Parent	= attachment.PrimaryPart
				
			attachment.Parent	= attachments
				
			return true
		end
	end
	return false
end

local function SwapAttachment(player, attachment, item)
	if attachment and item then
		local character	= player.Character
		if character then
			local items		= character.Items
			if attachment:IsDescendantOf(items) and item.Parent == items then
				local config	= require(attachment.Config)
				if config.Type == "Attachment" and item:FindFirstChild("Attachments") then
					local from, to	= attachment.Parent.Parent, item
					local send, receive
					
					if to.PrimaryPart:FindFirstChild(config.Attach .. "Attach") and not to.Attachments:FindFirstChild(attachment.Name) then
						for _, other in pairs(to.Attachments:GetChildren()) do
							local oConfig	= require(other.Config)
							if oConfig.Attach == config.Attach then
								receive	= other.Name
								other:Destroy()
								break
							end
						end
						
						send	= attachment.Name
						attachment:Destroy()
					end
					
					if send then
						AddAttachment(to, send)
					end
					if receive then
						AddAttachment(from, receive)
					end
				end
			end
		end
	end
end

local function Pickup(player, drop)
	local character	= player.Character
	if character then
		local humanoid	= character.Humanoid
		local rootPart	= character.HumanoidRootPart
		local items		= character.Items
		local equipped	= character.Equipped
		
		if humanoid.Health > 0 and (not humanoid.Down.Value) then
			if drop and drop.Parent == DROPS then
				local distance	= (rootPart.Position - drop.Position).Magnitude
				if distance < PICKUP_DISTANCE then
					if drop:FindFirstChild("Item") then
						local safe	= true
						if #items:GetChildren() >= MAX_BACKPACK then
							local current	= equipped.Value
							local config	= require(current.Config)
							
							if config.Permanent then
								safe	= false
							else
								if current:FindFirstChild("Attachments") and drop:FindFirstChild("Attachments") then
									local pickupBase	= ITEMS[drop.Name]
									for _, a in pairs(current.Attachments:GetChildren()) do
										local aConfig	= require(a.Config)
										local aSafe		= true
										for _, oa in pairs(drop.Attachments:GetChildren()) do
											local oaConfig	= require(ITEMS[oa.Name].Config)
											if oaConfig.Attach == aConfig.Attach then
												aSafe	= false
												break
											end
										end
										if not pickupBase.PrimaryPart:FindFirstChild(aConfig.Attach .. "Attach") then
											aSafe	= false
										end
										if aSafe then
											local val	= Instance.new("StringValue")
												val.Name	= a.Name
												val.Value	= a.Name
												val.Parent	= drop.Attachments
											
											a:Destroy()
										end
									end
								end
								Drop(current.Name, rootPart.CFrame:pointToWorldSpace(DROP_OFFSET), current)
								current:Destroy()
							end
						end
						if safe then
							local item	= ITEMS[drop.Item.Value]:Clone()
							
							if item:FindFirstChild("Ammo") and drop:FindFirstChild("Ammo") then
								item.Ammo.Value	= drop.Ammo.Value
							end
							if item:FindFirstChild("Loaded") and drop:FindFirstChild("Loaded") then
								item.Loaded.Value	= drop.Loaded.Value
							end
							if item:FindFirstChild("Attachments") and drop:FindFirstChild("Attachments") then
								for _, attach in pairs(drop.Attachments:GetChildren()) do
									AddAttachment(item, attach.Name)
								end
							end
							
							item.Parent	= items
							
							drop:Destroy()
						end
					elseif drop:FindFirstChild("Armor") then
						local item		= ITEMS[drop.Armor.Value]
						local config	= require(item.Config)
						
						local success	= ServerScriptService.ArmorScript.AddArmor:Invoke(character, config.Slots)
						
						if success then
							drop:Destroy()
						end
					elseif drop:FindFirstChild("Attachment") then
						local item	= equipped.Value
						if item then
							local success	= AddAttachment(item, drop.Attachment.Value)
							if success then
								drop:Destroy()
							end
						end
					elseif drop:FindFirstChild("Ammo") then
						local item		= ITEMS[drop.Ammo.Value]
						local config	= require(item.Config)
						
						character.Ammo[config.Size].Value	= character.Ammo[config.Size].Value + drop.Stack.Value
						
						drop:Destroy()
					elseif drop:FindFirstChild("Booster") then
						local item		= ITEMS[drop.Booster.Value]
						local config	= require(item.Config)
						
						if config.Boost == "Health" then
							local healthPacks	= character.HealthPacks
							
							if healthPacks.Value + drop.Stack.Value > MAX_HEALTH_PACKS then
								local dif	= MAX_HEALTH_PACKS - healthPacks.Value
								
								healthPacks.Value	= healthPacks.Value + dif
								drop.Stack.Value	= drop.Stack.Value - dif
							else
								healthPacks.Value	= healthPacks.Value + drop.Stack.Value
								drop:Destroy()
							end
						end
					elseif drop:FindFirstChild("Throwable") then
						local item		= ITEMS[drop.Throwable.Value]
						local config	= require(item.Config)
						
						for _, otherItem in pairs(items:GetChildren()) do
							if otherItem.Name == item.Name then
								if otherItem.Stack.Value < config.Stack then
									local dif	= config.Stack - otherItem.Stack.Value
									if drop.Stack.Value >= dif then
										drop.Stack.Value		= drop.Stack.Value - dif
										otherItem.Stack.Value	= otherItem.Stack.Value + dif
									else
										otherItem.Stack.Value	= otherItem.Stack.Value + drop.Stack.Value
										drop.Stack.Value		= 0
									end
								end
								if drop.Stack.Value == 0 then
									drop:Destroy()
									break
								end
							end
						end
						
						if drop and drop.Parent then
							local safe	= true
							if #items:GetChildren() >= MAX_BACKPACK then
								local current	= equipped.Value
								local config	= require(current.Config)
								
								if current.Name == drop.Name then
									safe	= false
								else
									Drop(current.Name, rootPart.CFrame:pointToWorldSpace(DROP_OFFSET), current)
									current:Destroy()
								end
							end
							if safe then
								local item	= ITEMS[drop.Name]:Clone()
								
								if item:FindFirstChild("Stack") and drop:FindFirstChild("Stack") then
									item.Stack.Value	= drop.Stack.Value
								end
								
								item.Parent	= items
								
								drop:Destroy()
							end
						end
					end
				end
			end
		end
	end
end

local function DropEverything(character)
	local rootPart		= character.HumanoidRootPart
	local humanoid		= character.Humanoid
	local items			= character.Items
	local ammo			= character.Ammo
	local healthPacks	= character.HealthPacks
	
	for _, item in pairs(items:GetChildren()) do
		Drop(item.Name, rootPart.Position + Vector3.new(math.random(-40, 40) / 10, 0, math.random(-40, 40) / 10), item)
	end
	for _, ammo in pairs(ammo:GetChildren()) do
		if ammo.Value > 0 then
			Drop(ammo.Name .. " Ammo", rootPart.Position + Vector3.new(math.random(-40, 40) / 10, 0, math.random(-40, 40) / 10), ammo.Value)
		end
	end
	if healthPacks.Value > 0 then
		Drop("Health Pack", rootPart.Position + Vector3.new(math.random(-40, 40) / 10, 0, math.random(-40, 40) / 10), healthPacks.Value)
	end
	DropArmor("Armor", rootPart.Position + Vector3.new(math.random(-40, 40) / 10, 0, math.random(-40, 40) / 10))
	if character:IsDescendantOf(Workspace) then
		items:ClearAllChildren()
	end
end

-- events

Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		local rootPart	= character.HumanoidRootPart
		local humanoid	= character.Humanoid
		local items		= character.Items
		local ammo		= character.Ammo
		
		humanoid.Died:connect(function()
			DropEverything(character)
		end)
	end)
	
	player.CharacterRemoving:connect(function(character)
		local rootPart	= character:FindFirstChild("HumanoidRootPart")
		local humanoid	= character:FindFirstChild("Humanoid")
		local items		= character:FindFirstChild("Items")
		local ammo		= character:FindFirstChild("Ammo")
		
		if humanoid and humanoid.Health > 0 then
			DropEverything(character)
		end
	end)
end)

REMOTES.Pickup.OnServerEvent:connect(Pickup)
REMOTES.SwapAttachment.OnServerEvent:Connect(SwapAttachment)

REMOTES.Drop.OnServerEvent:connect(function(player, item)
	local character	= player.Character
	if character then
		local rootPart	= character.HumanoidRootPart
		local items		= character.Items
		local config	= require(item.Config)
		
		if config.Type == "Attachment" then
			if item:IsDescendantOf(items) then
				Drop(item.Name, rootPart.CFrame:pointToWorldSpace(DROP_OFFSET))
				item:Destroy()
			end
		else
			if item.Parent == items then
				Drop(item.Name, rootPart.CFrame:pointToWorldSpace(DROP_OFFSET), item)
				
				item:Destroy()
			end
		end
	end
end)

REMOTES.DropAmmo.OnServerEvent:connect(function(player, ammoType, amount)
	amount	= math.floor(math.abs(amount) + 0.5)
	
	local character	= player.Character
	if character then
		local rootPart	= character.HumanoidRootPart
		local ammo	=	 character.Ammo
		if ammo[ammoType].Value >= amount then
			ammo[ammoType].Value	= ammo[ammoType].Value - amount
			Drop(ammoType .. " Ammo", rootPart.CFrame:pointToWorldSpace(DROP_OFFSET), amount)
		end
	end
end)

REMOTES.DropHealth.OnServerEvent:connect(function(player, amount)
	amount	= math.floor(math.abs(amount) + 0.5)
	
	local character	= player.Character
	if character then
		local rootPart	= character.HumanoidRootPart
		local packs		= character.HealthPacks
		
		if packs.Value >= amount then
			packs.Value		= packs.Value - amount
			Drop("Health Pack", rootPart.CFrame:pointToWorldSpace(DROP_OFFSET), amount)
		end
	end
end)


script.Drop.Event:connect(function(...)
	Drop(...)
end)

-- loop

DROPS.ChildAdded:connect(function(drop)
	for _, other in pairs(DROPS:GetChildren()) do
		if other ~= drop then
			local offset	= drop.Position - other.Position
			if math.abs(offset.X) < 2 and math.abs(offset.Y) < 2 and math.abs(offset.Z) < 2 then
				local distance	= offset.Magnitude
				if distance < 2 then
					if distance == 0 then
						offset	= Vector3.new(0, 0, 1)
					end
					drop.CFrame		= drop.CFrame + Vector3.new(offset.X, 0, offset.Z).Unit * 2
				end
			end
		end
	end
end)