-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players			= game:GetService("Players")

-- constants

local PLAYER_DATA	= ReplicatedStorage.PlayerData

-- functions

local function Increment(player, stat, amount)
	if player then
		local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
		
		if playerData then
			if playerData.Stats:FindFirstChild(stat) then
				playerData.Stats[stat].Value	= playerData.Stats[stat].Value + amount
			end
		end
	end
end

local function MostKills(player, kills)
	if player then
		local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
		
		if playerData then
			playerData.Stats.MostKills.Value	= math.max(playerData.Stats.MostKills.Value, kills)
		end
	end
end

local function FurthestKill(player, distance)
	if player then
		local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
		
		if playerData then
			playerData.Stats.FurthestKill.Value	= math.max(playerData.Stats.FurthestKill.Value, distance)
		end
	end
end

-- events

script.Increment.Event:connect(Increment)
script.MostKills.Event:connect(MostKills)
script.FurthestKill.Event:connect(FurthestKill)

-- initiate

while true do
	wait(60)
	for _, player in pairs(Players:GetPlayers()) do
		local character	= player.Character
		if character then
			local humanoid	= character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				Increment(player, "PlayTime", 1)
			end
		end
	end
end