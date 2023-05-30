-- services

local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local ServerScriptService	= game:GetService("ServerScriptService")
local TweenService			= game:GetService("TweenService")
local Workspace				= game:GetService("Workspace")
local Players				= game:GetService("Players")

-- constants

local ITEMS		= ReplicatedStorage.Items
local STORM		= ReplicatedStorage.Storm
local REMOTES	= ReplicatedStorage.Remotes
local MODULES	= ReplicatedStorage.Modules
	local DAMAGE	= require(MODULES.Damage)
	
local SPACESHIP	= Workspace.Spaceship
	
local STARTING_PLAYERS	= 30

local DISTANCE		= 10000
local TIME			= 60

-- variables

local deployEnabled	= false
local readyEnabled	= false

-- functions

local function Deploy(player)
	if deployEnabled then
		local character	= player.Character
		if character then
			local root	= character:FindFirstChild("HumanoidRootPart")
			
			if root and root:FindFirstChild("SpaceshipWeld") then
				root.SpaceshipWeld:Destroy()
				root:SetNetworkOwner(player)
				REMOTES.Deploy:FireClient(player)
				
				for _, p in pairs(game.Players:GetPlayers()) do
					if p ~= player then
						REMOTES.Effect:FireClient(p, "Fly", player.Character, true)
					end
				end
				
				spawn(function()
					repeat
						wait(0.1)
					until character.Humanoid.FloorMaterial ~= Enum.Material.Air
					
					for _, p in pairs(game.Players:GetPlayers()) do
						if p ~= player then
							REMOTES.Effect:FireClient(p, "Fly", player.Character, false)
						end
					end
					
					local pistol	= ITEMS.Pistol:Clone()
						pistol.Parent	= character.Items
						
					for _, ammo in pairs(character.Ammo:GetChildren()) do
						if ammo.Name == "Light" then
							ammo.Value	= 50
						else
							ammo.Value	= 0
						end
					end
					
					ServerScriptService.AntiCheat.TrackCharacter:Fire(character)
				end)
			end
		end
	end
end

local function ReadyCharacter(character)
	local rootPart	= character:FindFirstChild("HumanoidRootPart")
	local humanoid	= character:FindFirstChild("Humanoid")
	local items		= character:FindFirstChild("Items")
	local ammo		= character:FindFirstChild("Ammo")
	local healthPacks	= character:FindFirstChild("HealthPacks")
	
	if items then
		items:ClearAllChildren()
	end
	
	if humanoid then
		humanoid.ArmorSlots.Value	= 0
		humanoid.Armor.Value		= 0
	end
	
	if ammo then
		for _, a in pairs(ammo:GetChildren()) do
			a.Value	= 0
		end
	end
	
	if healthPacks then
		healthPacks.Value	= 0
	end
	
	if rootPart then
		rootPart.CFrame	= SPACESHIP.CFrame
		
		local weld	= Instance.new("Motor6D")
			weld.Name	= "SpaceshipWeld"
			weld.Part0	= SPACESHIP
			weld.Part1	= rootPart
			weld.Parent	= rootPart
	end
end

-- events

REMOTES.Deploy.OnServerEvent:connect(Deploy)

Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		wait(1)
		if readyEnabled then
			REMOTES.Camera:FireClient(player, "Mode", "Spaceship")
			ReadyCharacter(character)
		end
	end)
end)
	
-- initiate

local direction		= math.random(0, 360)
local startCFrame	= CFrame.Angles(0, math.rad(direction), 0) * CFrame.new(math.random(-DISTANCE / 2, DISTANCE / 2) * 0.3, 2000, DISTANCE / 2)
SPACESHIP.CFrame	= startCFrame
local info			= TweenInfo.new(TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local shipTween		= TweenService:Create(SPACESHIP, info, {CFrame = startCFrame * CFrame.new(0, 0, -DISTANCE)})

DAMAGE:SetEnabled(false)

for i = 30, 1, -1 do
	-- fire timer remote
	STORM.Timer.Value	= i
	
	wait(1)
	
	if Players.NumPlayers >= STARTING_PLAYERS then
		wait(2)
		break
	end
end

STORM.Timer.Value	= 0
readyEnabled		= true

-- set camera to target spaceship
REMOTES.Camera:FireAllClients("Mode", "Spaceship")

-- weld all characters to the ship center
for _, player in pairs(game.Players:GetPlayers()) do
	local character	= player.Character
	
	if character then
		ReadyCharacter(character)
	end
end

print("Flying")
SPACESHIP.FlySound:Play()
shipTween:Play()

wait(TIME * 0.1)
print("Jumping enabled")
REMOTES.RoundInfo:FireAllClients("Message", "Ready to deploy")
DAMAGE:SetEnabled(true)
deployEnabled	= true

wait(TIME * 0.8)

-- eject all remaining players
print("Ejecting players and starting storm")
readyEnabled	= false

for _, player in pairs(Players:GetPlayers()) do
	Deploy(player)
end
script.Parent.StormScript.RunSequence:Fire()

deployEnabled	= false

wait(TIME * 0.1)
SPACESHIP.FlySound:Stop()
