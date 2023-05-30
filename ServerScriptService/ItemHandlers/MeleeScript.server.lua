-- services

local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local ServerScriptService	= game:GetService("ServerScriptService")
local RunService			= game:GetService("RunService")
local Players				= game:GetService("Players")

-- constants

local STAT_SCRIPT	= ServerScriptService.StatScript

local REMOTES	= ReplicatedStorage.Remotes
local MODULES	= ReplicatedStorage.Modules
	local DAMAGE	= require(MODULES.Damage)

local MAX_DISTANCE	= 20

-- variables

local inits		= {}

-- functions

local function Init(player, item, timeout)
	inits[player]	= {Item = item; Timeout = tick() + timeout + 0.5};
end

-- events

REMOTES.Melee.OnServerEvent:connect(function(player, action, item, ...)
	local character	= player.Character
	if character then
		local equipped	= character.Equipped.Value
		
		if item == equipped then
			if action == "Init" then
				local index		= ...
				local animation	= item.Animations["Attack" .. tostring(index)]
				local timeout	= 0
				
				repeat
					RunService.Stepped:wait()
					for _, track in pairs(character.Humanoid:GetPlayingAnimationTracks()) do
						if track.Animation.AnimationId == animation.AnimationId then
							if track.Length == 0 then
								repeat RunService.Stepped:wait() until track.Length ~= 0
							end
							timeout	= track.Length
							break
						end
					end
				until timeout ~= 0
				
				Init(player, item, timeout)
				
				for _, p in pairs(Players:GetPlayers()) do
					if p ~= player then
						REMOTES.Effect:FireClient(p, "Swing", item, timeout)
					end
				end
			elseif action == "Hit" then
				local info	= inits[player]
				if info then
					if info.Item == item then
						if tick() <= info.Timeout then
							local humanoid	= ...
							if DAMAGE:PlayerCanDamage(player, humanoid) then
								local otherChar	= humanoid.Parent
								local config	= require(item.Config)
								
								local offset	= otherChar.HumanoidRootPart.Position - character.HumanoidRootPart.Position
								local distance	= offset.Magnitude
								
								if distance < MAX_DISTANCE then
									if humanoid.Health > 0 then
										local down	= humanoid:FindFirstChild("Down")
										local alreadyDowned	= false
										
										if down then
											alreadyDowned	= down.Value
										end
										
										local damage	= config.Damage
										DAMAGE:Damage(humanoid, damage, player)
										otherChar.HumanoidRootPart.Velocity	= otherChar.HumanoidRootPart.Velocity + offset.Unit * config.Knockback
										
										local otherPlayer	= Players:GetPlayerFromCharacter(humanoid.Parent)
										if otherPlayer then
											REMOTES.HitIndicator:FireClient(otherPlayer, offset, damage)
										end
										
										if humanoid.Health <= 0 then
											local killDist	= math.floor(offset.Magnitude + 0.5)
											STAT_SCRIPT.FurthestKill:Fire(player, killDist)
											REMOTES.Killfeed:FireAllClients(player.Name, humanoid.Parent.Name, item.Name, killDist)
										end
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

Players.PlayerRemoving:connect(function(player)
	if inits[player] then
		inits[player]	= nil
	end
end)