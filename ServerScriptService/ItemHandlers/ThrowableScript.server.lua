-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local RunService			= game:GetService("RunService")
local Players				= game:GetService("Players")

-- constants

local REMOTES	= ReplicatedStorage.Remotes
local MODULES	= ReplicatedStorage.Modules
	local CONFIG	= require(MODULES.Config)
	
local POSITION_BUFFER	= 15

-- events

REMOTES.Throwable.OnServerEvent:connect(function(player, item, action, ...)
	local character	= player.Character
	local ammo		= character.Ammo
	local equipped	= character.Equipped
	
	if item == equipped.Value then
		if action == "Throw" then
			local stack	= item.Stack
			
			if stack.Value > 0 then
				local handle	= item.Handle
				local config	= CONFIG:GetConfig(item)
				
				local id, position, direction	= ...
				
				if (position - handle.Position).Magnitude < POSITION_BUFFER then
					stack.Value		= stack.Value - 1
					ServerScriptService.ProjectileScript.Projectile:Fire(player, item, id, position, direction)
					
					for _, p in pairs(Players:GetPlayers()) do
						if p ~= player then
							REMOTES.Effect:FireClient(p, "Throw", item)
						end
					end
					
					if stack.Value <= 0 then
						item:Destroy()
					end
				end
			end
		end
	end
end)