-- services

local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local ServerScriptService	= game:GetService("ServerScriptService")
local RunService			= game:GetService("RunService")
local Workspace				= game:GetService("Workspace")
local Players				= game:GetService("Players")

-- constants

local PLAYER_SCRIPT	= ServerScriptService.RoundHandlers.PlayerScript
local STAT_SCRIPT	= ServerScriptService.StatScript

local REMOTES	= ReplicatedStorage.Remotes
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local CONFIG	= require(MODULES.Config)
	local DAMAGE	= require(MODULES.Damage)

-- variables

local shots	= {}

local cancels	= {}

-- functions

local function Raycast(position, direction, ignore)
	local ray		= Ray.new(position, direction)
	local success	= false
	local h, p, n, humanoid
	
	table.insert(ignore, Workspace.Effects)
	table.insert(ignore, Workspace.Drops)
	
	repeat
		h, p, n	= Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
		
		if h then
			local humanoid	= h.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid then
				table.insert(ignore, humanoid.Parent)
				success	= false
			elseif h.CanCollide and h.Transparency < 1 then
				success	= true
			else
				table.insert(ignore, h)
				success	= false
			end
		else
			success	= true
		end
	until success
	
	return h, p, n
end

-- events

REMOTES.Reload.OnServerEvent:connect(function(player, item)
	local character	= player.Character
	
	if character then
		local equipped	= character.Equipped
		local ammo		= character.Ammo
		if equipped.Value == item then
			local config		= CONFIG:GetConfig(item)
			local storedAmmo	= ammo[config.Size]
			local itemAmmo		= item.Ammo
			
			if storedAmmo.Value > 0 then
				if cancels[item] then
					cancels[item]	= nil
				end
				local magazine	= config.Magazine
				
				for _, p in pairs(Players:GetPlayers()) do
					if p ~= player then
						REMOTES.Effect:FireClient(p, "Reload", item)
					end
				end
				
				local needed	= magazine - itemAmmo.Value
				local start		= tick()
				local elapsed	= 0
				
				repeat
					elapsed	= tick() - start
					RunService.Stepped:wait()
				until elapsed >= config.ReloadTime or equipped.Value ~= item or cancels[item]
				
				if equipped.Value == item then
					if elapsed >= config.ReloadTime then
						if storedAmmo.Value >= needed then
							itemAmmo.Value		= itemAmmo.Value + needed
							storedAmmo.Value	= storedAmmo.Value - needed
						else
							itemAmmo.Value		= itemAmmo.Value + storedAmmo.Value
							storedAmmo.Value	= 0
						end
					end
				end
				
				if cancels[item] then
					cancels[item]	= nil
				end
			end
		end
	end
end)

REMOTES.Hit.OnServerEvent:connect(function(player, hit, index)
	spawn(function() -- spawn to avoid race conditions
		local shot	= shots[player]
		
		if shot then
			local character	= player.Character
			local equipped	= character.Equipped
			
			if equipped.Value == shot.Item then
				local humanoid	= hit.Parent:FindFirstChildOfClass("Humanoid")
				if humanoid then
					if DAMAGE:PlayerCanDamage(player, humanoid) then
						local position	= shot.Position
						local direction	= shot.Directions[index]
						local config	= shot.Config
						
						if direction then
							local ray		= Ray.new(position, direction)
							local distance	= (hit.Position - position).Magnitude
							local ignore	= {}
							
							for _, p in pairs(Players:GetPlayers()) do
								if p.Character then
									table.insert(ignore, p.Character)
								end
							end
							
							--local h	= Raycast(position, direction.Unit * distance, ignore)
							
							if distance <= config.Range then --and (not h) then
								local offset	= ray:Distance(hit.Position)
								if offset < 15 then
									if humanoid.Health > 0 then
										
										shot.Directions[index]	= nil
										local numDir	= 0
										for _, v in pairs(shot.Directions) do
											if v then
												numDir	= numDir + 1
											end
										end
										if numDir == 0 then
											shots[player]	= nil
										end
										
										local down	= humanoid:FindFirstChild("Down")
										local alreadyDowned	= false
										
										if down then
											alreadyDowned	= down.Value
										end
										
										local damage	= DAMAGE:Calculate(shot.Item, hit, position)
										DAMAGE:Damage(humanoid, damage, player)
										
										local otherPlayer	= Players:GetPlayerFromCharacter(humanoid.Parent)
										if otherPlayer then
											REMOTES.HitIndicator:FireClient(otherPlayer, direction, damage)
										end
										
										if humanoid.Health <= 0 then
											for _, part in pairs(humanoid.Parent:GetChildren()) do
												if part:IsA("BasePart") then
													part.Velocity	= direction * config.Damage
												end
											end
											local killDist	= math.floor((position - humanoid.Parent.HumanoidRootPart.Position).Magnitude + 0.5)
											STAT_SCRIPT.FurthestKill:Fire(player, killDist)
											REMOTES.Killfeed:FireAllClients(player.Name, humanoid.Parent.Name, shot.Item.Name, killDist)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end)

REMOTES.Shoot.OnServerEvent:connect(function(player, item, position, directions)
	if shots[player] then
		shots[player]	= nil
	end
	
	local character	= player.Character
	local rootPart	= character.HumanoidRootPart
	local humanoid	= character.Humanoid
	local down		= humanoid.Down
	local equipped	= character.Equipped
	local items		= character.Items
	
	if item.Parent == items and not down.Value then
		if (rootPart.Position - position).Magnitude < 15 then
			if equipped.Value == item then
				local ammo		= item.Ammo
				local config	= CONFIG:GetConfig(item)
				
				if #directions == config.ShotSize then
					if ammo.Value > 0 then
						ammo.Value	= ammo.Value - 1
						for i, dir in pairs(directions) do
							directions[i]	= dir.Unit
						end
						
						local shot	= {
							Item		= item;
							Config		= config;
							Position	= position;
							Directions	= directions;
						}
						
						shots[player]	= shot
						cancels[item]	= true
						
						for _, other in pairs(Players:GetPlayers()) do
							if other ~= player then
								REMOTES.Effect:FireClient(other, "Shoot", item, position, directions)
							end
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:connect(function(player)
	if shots[player] then
		shots[player]	= nil
	end
end)