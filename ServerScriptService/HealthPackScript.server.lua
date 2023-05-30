-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Players			= game:GetService("Players")

-- constants

local REMOTES	= ReplicatedStorage.Remotes
local EVENTS	= ReplicatedStorage.Events

local HEAL_TIME		= 3
local HEAL_AMOUNT	= 25

-- variables

local healing	= {}

-- events

REMOTES.Heal.OnServerEvent:connect(function(player)
	local character	= player.Character
	if character and not healing[player] then
		local humanoid	= character:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
			local healthPacks	= character:FindFirstChild("HealthPacks")
			local down			= humanoid:FindFirstChild("Down")
			if healthPacks and healthPacks.Value > 0 and (down and not down.Value) then
				healing[player]	= true
				--REMOTES.BackpackEnabled:FireClient(player, false)
				REMOTES.HealingEnabled:FireClient(player, false)
				REMOTES.Effect:FireAllClients("Heal", character, true, HEAL_TIME)
				local equipped	= character.Equipped
				equipped.Value	= nil
				
				local cancelled	= false
				local start		= tick()
				
				local connection	= EVENTS.Damaged.Event:connect(function(h)
					if h == humanoid then
						cancelled	= true
					end
				end)
				
				repeat
					RunService.Stepped:wait()
				until tick() - start >= HEAL_TIME or cancelled or equipped.Value or healthPacks.Value <= 0 or down.Value or equipped.Value
				
				if tick() - start >= HEAL_TIME and healthPacks.Value > 0 then
					healthPacks.Value	= healthPacks.Value - 1
					humanoid.Health		= math.min(humanoid.Health + HEAL_AMOUNT, humanoid.MaxHealth)
					REMOTES.Effect:FireAllClients("Booster", character, "Health")
				end
				
				connection:Disconnect()
				
				if healing[player] then
					healing[player]	= nil
				end
				--REMOTES.BackpackEnabled:FireClient(player, true)
				REMOTES.HealingEnabled:FireClient(player, true)
				REMOTES.Effect:FireAllClients("Heal", character, false)
			end
		end
	end
end)

Players.PlayerRemoving:connect(function(player)
	if healing[player] then
		healing[player]	= nil
	end
end)