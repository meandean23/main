-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Players			= game:GetService("Players")
local HttpService		= game:GetService("HttpService")

-- constants

local SQUADS	= ReplicatedStorage.Squads
local REMOTES	= ReplicatedStorage.Remotes

-- variables

-- functions

local function CreateSquad(name)
	if not name then
		name	= HttpService:GenerateGUID(false)
	end
	
	local squad		= script.Squad:Clone()
		squad.Name		= name
		squad.Parent	= SQUADS
		
	return squad
end

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

local function AddPlayerToSquad(player, squad)
	local playerValue	= Instance.new("ObjectValue")
		playerValue.Name	= player.Name
		playerValue.Value	= player
		playerValue.Parent	= squad
end

local function RemovePlayer(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		local playerValue	= squad:FindFirstChild(player.Name)
		
		if playerValue then
			playerValue:Destroy()
		end
	end
end

-- events

REMOTES.Pin.OnServerEvent:connect(function(player, action, ...)
	local squad	= GetSquad(player)
	
	if squad then
		if action == "Add" then
			for _, p in pairs(squad:GetChildren()) do
				if p.Value ~= player then
					REMOTES.Pin:FireClient(p.Value, action, player, ...)
				end
			end
		elseif action == "Remove" then
			for _, p in pairs(squad:GetChildren()) do
				if p.Value ~= player then
					REMOTES.Pin:FireClient(p.Value, action, player)
				end
			end
		end
	end
end)

Players.PlayerAdded:connect(function(player)
	local info		= player:GetJoinData()
	local squadName	= info.TeleportData
	local squad
	
	if squadName then
		squad = SQUADS:FindFirstChild(squadName)
	end	
	
	if not squad then
		squad	= CreateSquad(squadName)
	end
	
	AddPlayerToSquad(player, squad)
end)

Players.PlayerRemoving:connect(function(player)
	RemovePlayer(player)
end)