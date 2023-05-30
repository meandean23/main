-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")

-- constants

local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local EFFECTS	= require(MODULES:WaitForChild("Effects"))

-- events

REMOTES.Effect.OnClientEvent:connect(function(...)
	EFFECTS:Effect(...)
end)