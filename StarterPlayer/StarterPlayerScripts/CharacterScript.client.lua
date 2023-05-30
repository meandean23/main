-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")

-- constants

local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

-- variables

local characters	= {}

-- functions

local function HandleCharacter(character)
	local waist		= character:WaitForChild("UpperTorso"):WaitForChild("Waist")
	local neck		= character:WaitForChild("Head"):WaitForChild("Neck")
	local rShoulder	= character:WaitForChild("RightUpperArm"):WaitForChild("RightShoulder")
	local lShoulder	= character:WaitForChild("LeftUpperArm"):WaitForChild("LeftShoulder")
	local equipped	= character:WaitForChild("Equipped")
	
	local info	= {
		LookAngle	= 0;
		Twist		= 0;
		Equipped	= equipped;
		
		Waist		= waist;
		WaistC0		= waist.C0;
		Neck		= neck;
		NeckC0		= neck.C0;
		
		LShoulder	= lShoulder;
		LShoulderC0	= lShoulder.C0;
		RShoulder	= rShoulder;
		RShoulderC0	= rShoulder.C0;
	}
	
	characters[character]	= info
	
	character.AncestryChanged:connect(function()
		if not character:IsDescendantOf(Workspace) then
			characters[character]	= nil
		end
	end)
end

-- initiate

RunService:BindToRenderStep("CharacterLook", 10, function(deltaTime)
	for character, info in pairs(characters) do
		info.Waist.C0	= info.Waist.C0:Lerp(info.WaistC0 * CFrame.Angles(info.LookAngle * 0.3, info.Twist, 0), math.min(deltaTime * 5, 1))
		info.Neck.C0	= info.Neck.C0:Lerp(info.NeckC0 * CFrame.Angles(info.LookAngle * 0.6, 0, 0), math.min(deltaTime * 5, 1))
		info.RShoulder.C0	= info.RShoulder.C0:Lerp(info.RShoulderC0 * CFrame.Angles((info.Equipped.Value and info.LookAngle * 0.7 or 0), 0, 0), math.min(deltaTime * 5, 1))
		info.LShoulder.C0	= info.LShoulder.C0:Lerp(info.LShoulderC0 * CFrame.Angles((info.Equipped.Value and info.LookAngle * 0.7 or 0), 0, 0), math.min(deltaTime * 5, 1))
	end
end)

-- events

REMOTES.LookAngle.OnClientEvent:connect(function(character, angle, twist)
	if characters[character] then
		characters[character].LookAngle	= angle
		characters[character].Twist		= twist
	else
		HandleCharacter(character)
	end
end)