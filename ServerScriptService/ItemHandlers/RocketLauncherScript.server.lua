-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local RunService			= game:GetService("RunService")
local Players				= game:GetService("Players")
local Debris				= game:GetService("Debris")

-- constants

local REMOTES	= ReplicatedStorage.Remotes
local MODULES	= ReplicatedStorage.Modules
	local CONFIG	= require(MODULES.Config)
	
local POSITION_BUFFER	= 15

-- events

REMOTES.RocketLauncher.OnServerEvent:connect(function(player, item, action, ...)
	local character	= player.Character
	local ammo		= character.Ammo
	local equipped	= character.Equipped
	
	if item == equipped.Value then
		if action == "Fire" then
			local ammo	= item.Ammo
			
			if ammo.Value > 0 then
				ammo.Value		= ammo.Value - 1
				local handle	= item.Handle
				local muzzle	= handle.Muzzle
				local config	= CONFIG:GetConfig(item)
				
				local id, position, direction	= ...
				local muzzlePosition			= muzzle.WorldPosition
				
				if (position - muzzlePosition).Magnitude < POSITION_BUFFER then
					ServerScriptService.ProjectileScript.Projectile:Fire(player, item, id, position, direction)
					for _, p in pairs(game.Players:GetPlayers()) do
						if p ~= player then
							REMOTES.Effect:FireClient(p, "RocketLauncher", item, "Fire", ammo.Value > 0)
						end
					end
				end
				
				if ammo.Value <= 0 then
					Debris:AddItem(item, 0.3)
				end
			end
		elseif action == "Reload" then
			local config		= CONFIG:GetConfig(item)
			local storedAmmo	= ammo[config.Size]
			
			local start		= tick()
			local elapsed	= 0
			
			repeat
				elapsed	= tick() - start
				RunService.Stepped:wait()
			until elapsed >= config.ReloadTime or equipped.Value ~= item
			
			if equipped.Value == item then
				if elapsed >= config.ReloadTime then
					if storedAmmo.Value >= 1 then
						item.Loaded.Value	= true
						storedAmmo.Value	= storedAmmo.Value - 1
						
						for _, p in pairs(game.Players:GetPlayers()) do
							if p ~= player then
								REMOTES.Effect:FireClient(p, "RocketLauncher", item, "Reload")
							end
						end
					end
				end
			end
		end
	end
end)