-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local TeleportService		= game:GetService("TeleportService")
local Players				= game:GetService("Players")

-- constants

local STAT_SCRIPT	= ServerScriptService.StatScript
local PLAYER_DATA	= ReplicatedStorage.PlayerData
local REMOTES		= ReplicatedStorage.Remotes
local SQUADS		= ReplicatedStorage.Squads

local MENU_ID	= 2608963374

-- variables

local roundEnded	= false
local kills			= {}
local finished		= {}

local playerStatInfo	= {}

-- functions

local function SquadAlive(squad)
	for _, p in pairs(squad:GetChildren()) do
		local player	= p.Value
		
		if player then
			local character	= player.Character
			if character then
				local humanoid	= character:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return true
				end
			end
		end
	end
	
	return false
end

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

local function SendToMenu(player)
	local squadName
	local squad		= GetSquad(player)
	if squad then
		squadName	= squad.Name
	end
	
	ServerScriptService.DataScript.SaveData:Invoke(player)
	
	TeleportService:Teleport(MENU_ID, player, squadName)
end

local function AliveSquads()
	local num	= 0
	
	for _, squad in pairs(SQUADS:GetChildren()) do
		if SquadAlive(squad) then
			num	= num + 1
		end
	end
	
	return num
end

local function AlivePlayers()
	local num	= 0
	
	for _, player in pairs(game.Players:GetPlayers()) do
		local character	= player.Character
		
		if character then
			local humanoid	= character:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				num	= num + 1
			end
		end
	end
	
	return num
end


local function GetMatchInfo(player)
	local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
	
	local info	= {}
	
	if playerData and playerStatInfo[player] then
		for _, stat in pairs(playerData.Stats:GetChildren()) do
			info[stat.Name]	= stat.Value - playerStatInfo[player][stat.Name]
		end
	end
	
	return info
end

local function SaveStatInfo(player)
	local playerData	= PLAYER_DATA:WaitForChild(player.Name)
	
	local info	= {}
	
	for _, stat in pairs(playerData.Stats:GetChildren()) do
		info[stat.Name]	= stat.Value
	end
	
	playerStatInfo[player]	= info
end

local function GetXPInfo(player, place)
	local matchInfo		= GetMatchInfo(player)
	local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
	
	local placement	= 0
	if place == 1 then
		placement	= 100
	elseif place == 2 then
		placement	= 75
	elseif place == 3 then
		placement	= 50
	else
		placement	= 25
	end
	
	local info	= {
		Placement	= placement;
		Kills		= matchInfo.Kills * 10;
		Downs		= matchInfo.Downs * 5;
		Revives		= matchInfo.Revives * 20;
	}
	
	local unboosted	= info.Placement + info.Kills + info.Downs + info.Revives
	local total		= unboosted
	
	if playerData then
		total	= math.floor(unboosted + (unboosted * playerData.BattlePass.XPBoost.Value / 100) + 0.5)
	end
	
	info.Unboosted	= unboosted
	info.Total		= total
	
	return info
end

local function GiveXP(player, xp)
	local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
	if playerData then
		playerData.Ranking.LevelXP.Value	= playerData.Ranking.LevelXP.Value + xp
	end
end

local function GiveTickets(player, tickets)
	local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
	if playerData then
		playerData.Currency.Tickets.Value	= playerData.Currency.Tickets.Value + tickets
	end
end

local function PlayerFinished(player, place)
	if not finished[player] then
		finished[player]	= true
		
		print(player, "finished", place)
		
		local tickets	= 5
		
		if place <= 3 then
			STAT_SCRIPT.Increment:Fire(player, "Wins", 1)
			if place == 3 then
				tickets	= 10
				STAT_SCRIPT.Increment:Fire(player, "BronzeMedals", 1)
			elseif place == 2 then
				tickets	= 15
				STAT_SCRIPT.Increment:Fire(player, "SilverMedals", 1)
			elseif place == 1 then
				tickets	= 30
				STAT_SCRIPT.Increment:Fire(player, "GoldMedals", 1)
			end
		else
			STAT_SCRIPT.Increment:Fire(player, "Losses", 1)
		end
		local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
		local matchInfo		= GetMatchInfo(player)
		local xpInfo		= GetXPInfo(player, place)
		
		GiveXP(player, xpInfo.Total)
		GiveTickets(player, tickets)
		
		ServerScriptService.LeaderboardScript.UpdateLeaderboard:Fire(player, place, matchInfo.Kills, playerData.Stats.Wins.Value, playerData.Stats.Kills.Value)
		REMOTES.Victory:FireClient(player, place, matchInfo, xpInfo, tickets)
	end
end

local function EndRound()
	if not roundEnded then
		roundEnded	= true
		script.Parent.StormScript.Disabled	= true
		REMOTES.Finished:FireAllClients()
		
		local winnerSquad
		
		for _, squad in pairs(SQUADS:GetChildren()) do
			if SquadAlive(squad) then
				winnerSquad	= squad
				break
			end
		end
		
		if winnerSquad then
			for _, p in pairs(winnerSquad:GetChildren()) do
				PlayerFinished(p.Value, 1)
			end
		end
		
		wait(10)
		
		for _, player in pairs(Players:GetPlayers()) do
			SendToMenu(player)
		end
	end
end

-- initiate

Players.CharacterAutoLoads	= false

-- events

REMOTES.ReturnToMenu.OnServerEvent:Connect(SendToMenu)

Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		local humanoid	= character.Humanoid
		local down		= humanoid.Down
		
		down.Changed:connect(function()
			if down.Value then
				local downTag	= humanoid:FindFirstChild("DownTag")
				if downTag and downTag.Value then
					STAT_SCRIPT.Increment:Fire(downTag.Value, "Downs", 1)
				end
			end
		end)
		
		humanoid.Died:connect(function()
			STAT_SCRIPT.Increment:Fire(player, "Deaths", 1)
			
			if AliveSquads() <= 1 then
				spawn(function()
					EndRound()
				end)
			end
			
			local squad = GetSquad(player)
			if squad then
				if not SquadAlive(squad) then
					spawn(function()
						local place	= AliveSquads() + 1
						for _, p in pairs(squad:GetChildren()) do
							PlayerFinished(p.Value, place)
						end
					end)
				end
			end
			
			REMOTES.RoundInfo:FireAllClients("Alive", AlivePlayers())
			
			local killTag	= humanoid:FindFirstChild("KillTag")
			local downTag	= humanoid:FindFirstChild("DownTag")
			local killer, downer
			
			if killTag then
				killer	= killTag.Value
				if killer then
					if not kills[killer] then
						kills[killer]	= 0
					end
					
					kills[killer]	= kills[killer] + 1
					STAT_SCRIPT.Increment:Fire(killer, "Kills", 1)
					STAT_SCRIPT.MostKills:Fire(killer, kills[killer])
					
					REMOTES.RoundInfo:FireClient(killer, "Kills", kills[killer])
				end
			end
			
			REMOTES.Finished:FireClient(player, killer, GetMatchInfo(player))
			
			if downTag then
				downer	= downTag.Value
				if downer and downer ~= killer then
					if not kills[downer] then
						kills[downer]	= 0
					end
					
					kills[downer]	= kills[downer] + 1
					STAT_SCRIPT.Increment:Fire(downer, "Kills", 1)
					STAT_SCRIPT.MostKills:Fire(downer, kills[downer])
					
					REMOTES.RoundInfo:FireClient(downer, "Kills", kills[downer])
				end
			end
			
			wait(0.5)
			
			if killTag then
				local killer	= killTag.Value
				if killer then
					local killChar	= killer.Character
					REMOTES.Camera:FireClient(player, "KillChar", killChar)
				end
			end
			REMOTES.Camera:FireClient(player, "Mode", "Spectate")
		end)
	end)
	
	player.CharacterRemoving:connect(function(character)
		local humanoid	= character:FindFirstChild("Humanoid")
		
		if humanoid and humanoid.Down.Value and humanoid.Health > 0 then
			local downTag	= humanoid:FindFirstChild("DownTag")
			if downTag then
				local downer	= downTag.Value
				if downer then
					if not kills[downer] then
						kills[downer]	= 0
					end
					
					kills[downer]	= kills[downer] + 1
					STAT_SCRIPT.Increment:Fire(downer, "Kills", 1)
					STAT_SCRIPT.MostKills:Fire(downer, kills[downer])
					
					REMOTES.RoundInfo:FireClient(downer, "Kills", kills[downer])
					REMOTES.Killed:FireClient(downer, character.Name, true)
				end
			end
		end
	end)
	
	PLAYER_DATA:WaitForChild(player.Name)
	SaveStatInfo(player)
	
	player:LoadCharacter()
	
	REMOTES.RoundInfo:FireAllClients("Alive", AlivePlayers())
end)

Players.PlayerRemoving:connect(function(player)
	if kills[player] then
		kills[player]	= nil
	end
	
	REMOTES.RoundInfo:FireAllClients("Alive", AlivePlayers())
	
	local place	= AliveSquads() + 1
	PlayerFinished(player, place)
	
	if AliveSquads() <= 1 then
		EndRound()
	end
end)