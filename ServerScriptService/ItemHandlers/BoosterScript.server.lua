-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local Players				= game:GetService("Players")

-- constants

local REMOTES	= ReplicatedStorage.Remotes

-- variables

local inits		= {}

-- functions

local function Init(player, item)
	inits[player]	= {Item = item; Start = tick()};
end

-- events

REMOTES.Booster.OnServerEvent:connect(function(player, action, item)
	local character	= player.Character
	if character then
		local equipped	= character.Equipped.Value
		
		if item == equipped then
			if action == "Init" then
				Init(player, item)
			elseif action == "Use" then
				if inits[player] then
					if inits[player].Item == item then
						local elapsed	= tick() - inits[player].Start
						local config	= require(item.Config)
						local dif		= math.abs(elapsed - config.UseTime)
						
						if dif <= 0.5 then
							local humanoid	= character.Humanoid
							if config.Boost == "Armor" then
								ServerScriptService.ArmorScript.Boost:Fire(character, config.Potency)
								REMOTES.Effect:FireAllClients("Booster", character, "Armor")
							elseif config.Boost == "Health" then
								humanoid.Health	= math.min(humanoid.Health + config.Potency, humanoid.MaxHealth)
								REMOTES.Effect:FireAllClients("Booster", character, "Health")
							end
							item.Stack.Value	= item.Stack.Value - 1
							if item.Stack.Value == 0 then
								item:Destroy()
							end
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:connect(function(player)
	if inits[player] then
		inits[player]	= nil
	end
end)