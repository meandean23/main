-- services

local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local ServerScriptService	= game:GetService("ServerScriptService")
local RunService			= game:GetService("RunService")
local Workspace				= game:GetService("Workspace")
local Players				= game:GetService("Players")

-- constants

local STAT_SCRIPT	= ServerScriptService.StatScript

local REMOTES	= ReplicatedStorage.Remotes
local MODULES	= ReplicatedStorage.Modules
	local CONFIG		= require(MODULES.Config)
	local PROJECTILE	= require(MODULES.Projectile)
	local DAMAGE		= require(MODULES.Damage)

-- variables

local pings			= {}
local projectiles	= {}

-- functions

local function Raycast(ray, ignore)
	ignore	= ignore or {}
	
	local hit, position, normal
	
	local success	= false
	repeat
		hit, position, normal	= Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
		
		if hit then
			if hit.Parent:FindFirstChildOfClass("Humanoid") then
				success	= true
			elseif hit.CanCollide and hit.Transparency ~= 1 then
				success	= true
			else
				table.insert(ignore, hit)
			end
		else
			success	= true
		end
	until success
	
	return hit, position, normal
end
	
local function KillProjectile(projectile)
	if projectile.Splash then
		REMOTES.Effect:FireAllClients(projectile.SplashEffect, projectile.Position, projectile.SplashRadius)
	end
	
	REMOTES.Projectile:FireAllClients("Kill", projectile.ID)
	for i, p in pairs(projectiles) do
		if p == projectile then
			table.remove(projectiles, i)
			break
		end
	end
	
	if projectile.Splash then
		local region	= Region3.new(projectile.Position + Vector3.new(-1, -1, -1) * projectile.SplashRadius, projectile.Position + Vector3.new(1, 1, 1) * projectile.SplashRadius)
		local parts		= Workspace:FindPartsInRegion3WithIgnoreList(region, {Workspace.Effects}, 100)
		
		for _, part in pairs(parts) do
			if part.Name == "HumanoidRootPart" then
				local humanoid	= part.Parent:FindFirstChildOfClass("Humanoid")
				
				if humanoid then
					local hitPlayer	= Players:GetPlayerFromCharacter(humanoid.Parent)
					
					if hitPlayer == projectile.Owner or DAMAGE:PlayerCanDamage(projectile.Owner, humanoid) then
						if humanoid.Health > 0 then
							local distance	= (part.Position - projectile.Position).Magnitude
							if distance < projectile.SplashRadius then
								local down	= humanoid:FindFirstChild("Down")
								local alreadyDowned	= false
								
								if down then
									alreadyDowned	= down.Value
								end
								
								local amount	= math.cos((distance / projectile.SplashRadius)^2 * (math.pi / 2))
								local damage	= math.ceil(amount * projectile.Damage)
								local player	= Players:GetPlayerFromCharacter(humanoid.Parent)
								
								local direction	= (part.Position - projectile.Position).Unit
								
								if player then
									REMOTES.HitIndicator:FireClient(player, direction, damage)
								end
								
								if projectile.Owner then
									REMOTES.Hitmarker:FireClient(projectile.Owner, part.Position, damage, humanoid:FindFirstChild("Armor") and humanoid.Armor.Value > 0, false)
								end
								
								DAMAGE:Damage(humanoid, damage, projectile.Owner)
								
								if humanoid.Health <= 0 then
									for _, part in pairs(humanoid.Parent:GetChildren()) do
										if part:IsA("BasePart") then
											part.Velocity	= direction * damage * 2
										end
									end
									local killDist	= math.floor((projectile.StartPosition - part.Position).Magnitude + 0.5)
									STAT_SCRIPT.FurthestKill:Fire(projectile.Owner, killDist)
									REMOTES.Killfeed:FireAllClients(projectile.Owner.Name, humanoid.Parent.Name, projectile.Model, killDist)
								end
							end
						end
					end
				end
			end
		end
	end
end

local function UpdateProjectile(projectile, deltaTime)
	projectile.Velocity	= projectile.Velocity + Vector3.new(0, -projectile.Gravity * deltaTime, 0)
	
	local ray	= Ray.new(projectile.Position, projectile.Velocity * deltaTime)
	local hit, position	= Raycast(ray, projectile.Ignore)
	
	projectile.Position		= position
	--projectile.Debug.CFrame	= CFrame.new(projectile.Position)
	
	if hit then
		return false
	end
	
	return true
end

local function Projectile(player, item, id, position, direction)
	local ping			= pings[player] and pings[player].Average or 0
	local config		= CONFIG:GetConfig(item)
	
	local projectile			= PROJECTILE:Create(config.Projectile, id)
	projectile.Position			= position
	projectile.Velocity			= direction.Unit * projectile.Speed
	projectile.Damage			= config.Damage
	projectile.Owner			= player
	projectile.StartPosition	= position
	
	if player.Character then
		table.insert(projectile.Ignore, player.Character)
	end
	
	--[[local de	= Instance.new("Part")
		de.Anchored		= true
		de.CanCollide	= false
		de.Size			= Vector3.new(1, 1, 1)
		de.Material		= Enum.Material.Neon
		de.Parent		= workspace
		
	projectile.Debug	= de]]
	
	table.insert(projectiles, projectile)
	
	local alive	= UpdateProjectile(projectile, ping)
	
	if alive then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player then
				REMOTES.Projectile:FireClient(p, "Create", player, item, id, position, direction)
			end
		end
	else
		KillProjectile(projectile)
	end
end

-- events

Players.PlayerRemoving:connect(function(player)
	if pings[player] then
		pings[player]	= nil
	end
end)

script.Projectile.Event:connect(Projectile)

-- main loop

RunService.Stepped:connect(function(_, deltaTime)
	for i = #projectiles, 1, -1 do
		local projectile	= projectiles[i]
		local alive	= UpdateProjectile(projectile, deltaTime)
		
		if not alive then
			KillProjectile(projectile)
		elseif tick() - projectile.Start > projectile.Lifetime then
			KillProjectile(projectile)
		end
	end
end)

-- ping loop

while true do
	for _, player in pairs(Players:GetPlayers()) do
		spawn(function()
			if player and player.Parent == Players then
				if not pings[player] then
					pings[player]	= {
						Pings	= {};
						Average	= 0;
					}
				end
			
				local start		= tick()
				pcall(function()
					REMOTES.Ping:InvokeClient(player)
				end)
				local elapsed	= tick() - start
				
				if pings[player] then
					table.insert(pings[player].Pings, elapsed)
					if #pings[player].Pings > 5 then
						table.remove(pings[player].Pings, 1)
					end
					
					local average	= 0
					for _, ping in pairs(pings[player].Pings) do
						average		= average + ping
					end
					pings[player].Average	= average / #pings[player].Pings
				end
			end
		end)
	end
	wait(1)
end