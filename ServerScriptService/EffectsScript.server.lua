-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local REMOTES	= ReplicatedStorage.Remotes

-- variables

-- events

REMOTES.Grind.OnServerEvent:connect(function(player, grinding)
	if player.Character then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player then
				REMOTES.Effect:FireClient(p, "Grind", player.Character, grinding)
			end
		end
	end
end)

REMOTES.Dash.OnServerEvent:connect(function(player, mode, direction)
	if player.Character then
		local rootPart	= player.Character:FindFirstChild("HumanoidRootPart")
		
		if rootPart then
			for _, p in pairs(Players:GetPlayers()) do
				if p ~= player then
					REMOTES.Effect:FireClient(p, "Dash", mode, rootPart, direction)
				end
			end
		end
	end
end)