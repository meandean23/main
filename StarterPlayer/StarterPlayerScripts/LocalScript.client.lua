-- services

local Players	= game:GetService("Players")
local Workspace	= game:GetService("Workspace")

-- constants

local PLAYER	= Players.LocalPlayer

-- functions

local function HandleCharacter(character)
	if character then
		spawn(function()
			wait(1)
			
			for _, v in pairs(character:GetChildren()) do
				if v:IsA("BasePart") then
					v:GetPropertyChangedSignal("Size"):Connect(function()
						wait(2)
						PLAYER:Kick()
					end)
				end
			end
		end)
	end
end

local function HandlePlayer(player)
	player.CharacterAdded:connect(HandleCharacter)
	
	if player.Character then
		HandleCharacter(player.Character)
	end
end

-- events

Players.PlayerAdded:connect(HandlePlayer)

-- initiate

for _, player in pairs(Players:GetPlayers()) do
	HandlePlayer(player)
end

local map	= Workspace:WaitForChild("Map")

map.DescendantRemoving:Connect(function()
	wait(2)
	PLAYER:Kick()
end)