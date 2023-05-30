-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local HttpService		= game:GetService("HttpService")

-- constants

local REMOTES	= ReplicatedStorage.Remotes

-- variables

local serverRegion

-- functions

REMOTES.GetDebugInfo.OnServerInvoke = function()
	if not serverRegion then
		local json	= HttpService:GetAsync("http://ip-api.com/json")
		local data	= HttpService:JSONDecode(json)
		
		serverRegion	= data.regionName
	end
	
	local info	= {
		ServerRegion	= serverRegion;
	}
	
	return info
end