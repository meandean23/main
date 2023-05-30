-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local MarketplaceService	= game:GetService("MarketplaceService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local Players				= game:GetService("Players")

-- constants

local REMOTES	= ReplicatedStorage.Remotes

local GOLD_PASS_ID		= 5339124
local GOLD_PASS_ID_2	= 5562553

-- variables

-- functions

local function GiveCharacterGoldGuns(character)
	if character then
		local goldGunScript	= script.GoldGunScript:Clone()
			goldGunScript.Parent	= character
			goldGunScript.Disabled	= false
	end
end

local function GivePlayerGoldGuns(player)
	GiveCharacterGoldGuns(player.Character)
	
	player.CharacterAdded:connect(GiveCharacterGoldGuns)
end

-- events

Players.PlayerAdded:connect(function(player)
	if MarketplaceService:UserOwnsGamePassAsync(player.UserId, GOLD_PASS_ID) or MarketplaceService:UserOwnsGamePassAsync(player.UserId, GOLD_PASS_ID_2) then
		GivePlayerGoldGuns(player)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:connect(function(player, passId, purchased)
	if passId == GOLD_PASS_ID or passId == GOLD_PASS_ID_2 then
		if purchased then
			GivePlayerGoldGuns(player)
		end
	end
end)

-- callbacks