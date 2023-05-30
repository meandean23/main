-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local DataStoreService	= game:GetService("DataStoreService")
local Players			= game:GetService("Players")

-- constants

local REMOTES	= ReplicatedStorage.Remotes

local SEASON_WINS_DATA		= DataStoreService:GetOrderedDataStore("Season1Wins")
local SEASON_KILLS_DATA		= DataStoreService:GetOrderedDataStore("Season1Kills")
local ALLTIME_WINS_DATA		= DataStoreService:GetOrderedDataStore("AllTimeWins")
local ALLTIME_KILLS_DATA	= DataStoreService:GetOrderedDataStore("AllTimeKills")

-- variables

-- functions

local function UpdateLeaderboard(player, place, matchKills, wins, kills)
	if place <= 3 then
		SEASON_WINS_DATA:UpdateAsync(player.UserId, function(oldData)
			local saveData	= oldData and oldData or 0
			saveData	= saveData + 1
			return saveData
		end)
	end
	
	SEASON_KILLS_DATA:UpdateAsync(player.UserId, function(oldData)
		local saveData	= oldData and oldData or 0
		saveData	= saveData + matchKills
		return saveData
	end)
	
	ALLTIME_WINS_DATA:SetAsync(player.UserId, wins)
	ALLTIME_KILLS_DATA:SetAsync(player.UserId, kills)
end

-- events

script.UpdateLeaderboard.Event:Connect(UpdateLeaderboard)