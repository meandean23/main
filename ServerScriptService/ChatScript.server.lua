-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local TextService			= game:GetService("TextService")
local Chat					= game:GetService("Chat")
local Players				= game:GetService("Players")

-- constants

local PLAYER_DATA	= ReplicatedStorage.PlayerData
local REMOTES		= ReplicatedStorage.Remotes
local SQUADS		= ReplicatedStorage.Squads

local MAX_PER_SECOND	= 2

-- variables

local cooldowns	= {}

-- functions

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

-- events

REMOTES.Chat.OnServerEvent:connect(function(player, message, scope)
	local players
	
	if scope == "Global" then
		players	= Players:GetPlayers()
	elseif scope == "Squad" then
		local squad	= GetSquad(player)
		if squad then
			players	= {}
			
			for _, p in pairs(squad:GetChildren()) do
				table.insert(players, p.Value)
			end
		end
	end
	
	if not cooldowns[player] then
		cooldowns[player]	= 0
	end
	
	cooldowns[player]	= cooldowns[player] + 1
	
	if cooldowns[player] <= MAX_PER_SECOND then
		if players then
			if string.gsub(message, "%s", "") ~= "" then
				local result	= TextService:FilterStringAsync(message, player.UserId)
				for _, p in pairs(players) do
					spawn(function()
						pcall(function()
							if player.Parent == Players and p.Parent == Players and Chat:CanUsersChatAsync(player.UserId, p.UserId) then
								local filtered	= result:GetChatForUserAsync(p.UserId)
								REMOTES.Chat:FireClient(p, player.Name, filtered, scope)
							end
						end)
					end)
				end
			end
		end
	else
		REMOTES.Chat:FireClient(player, "SERVER", "Woah there, you're sending messages too fast!", "Server")
	end
end)

Players.PlayerRemoving:connect(function(player)
	if cooldowns[player] then
		cooldowns[player]	= nil
	end
end)

-- initiate

while true do
	wait(1)
	for p, v in pairs(cooldowns) do
		cooldowns[p]	= v - 1
	end
end