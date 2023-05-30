-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local RunService			= game:GetService("RunService")
local Players				= game:GetService("Players")
local Debris				= game:GetService("Debris")

-- constants

local REMOTES	= ReplicatedStorage.Remotes
local SQUADS	= ReplicatedStorage.Squads

local STAT_SCRIPT	= ServerScriptService.StatScript

local DOWN_TIME			= 20
local REVIVE_HEALTH		= 0.5
local REVIVE_RADIUS		= 8
local REVIVE_MULTIPLIER	= 3

-- variables

-- functions

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

local function HandleCharacter(character)
	local player	= Players:GetPlayerFromCharacter(character)
	local humanoid	= character.Humanoid
	local rootPart	= character.HumanoidRootPart
	local down		= humanoid.Down
	local downGui	= character.HumanoidRootPart.DownTimerGui
	
	down.Changed:connect(function()
		if down.Value then
			downGui.Enabled	= true
			
			local squad	= GetSquad(player)
			
			for _, p in pairs(squad:GetChildren()) do
				REMOTES.Effect:FireClient(p.Value, "Down", true, character, REVIVE_RADIUS)
			end
			
			local reviveBeam	= script.ReviveBeam:Clone()
				reviveBeam.Attachment1	= rootPart.Center
				reviveBeam.Parent		= rootPart
				
			local reviveSound	= script.ReviveSound:Clone()
				reviveSound.Parent		= rootPart
			
			local timer			= DOWN_TIME
			local lastText		= tostring(math.ceil(timer))
			local multiplier	= 1
			
			local reviver
			
			repeat
				local timerText		= tostring(math.ceil(timer))
				if timerText ~= lastText then
					local sound		= script.TickSound:Clone()
						sound.Parent	= rootPart
						sound:Play()
						Debris:AddItem(sound, 0.1)
						
					lastText		= timerText
				end
				
				downGui.TimerLabel.Text		= timerText
				downGui.ShadowLabel.Text	= timerText
				
				timer	= math.max(timer - (0.1 * multiplier), 0)
				
				local center	= Vector2.new(rootPart.Position.X, rootPart.Position.Z)
				
				reviver	= nil
				
				for _, p in pairs(squad:GetChildren()) do
					local other		= p.Value
					local otherChar	= other.Character
					if otherChar then
						local otherHumanoid	= otherChar:FindFirstChild("Humanoid")
						if otherHumanoid and otherHumanoid.Health > 0 and (not otherHumanoid.Down.Value) then
							local otherRoot	= otherChar:FindFirstChild("HumanoidRootPart")
							if otherRoot then
								local distance	= (center - Vector2.new(otherRoot.Position.X, otherRoot.Position.Z)).Magnitude
								if distance <= REVIVE_RADIUS then
									reviver	= otherChar
									break
								end
							end
						end
					end
				end
				
				if reviver then
					multiplier	= REVIVE_MULTIPLIER
					reviveBeam.Attachment0			= reviver.HumanoidRootPart.Center
					downGui.TimerLabel.TextColor3	= Color3.fromRGB(255, 233, 67)
					downGui.TextLabel.TextColor3	= Color3.fromRGB(255, 233, 67)
					
					if not reviveSound.Playing then
						reviveSound:Play()
					end
				else
					multiplier	= 1
					reviveBeam.Attachment0	= nil
					downGui.TimerLabel.TextColor3	= Color3.fromRGB(242, 242, 242)
					downGui.TextLabel.TextColor3	= Color3.fromRGB(242, 242, 242)
					
					if reviveSound.Playing then
						reviveSound:Stop()
					end
				end
				
				wait(0.1)
			until timer == 0 or humanoid.Health <= 0
			
			if reviver and humanoid.Health > 0 then
				local reviverPlayer	= Players:GetPlayerFromCharacter(reviver)
				if reviverPlayer then
					STAT_SCRIPT.Increment:Fire(reviverPlayer, "Revives", 1)
				end
			end
			
			for _, p in pairs(squad:GetChildren()) do
				REMOTES.Effect:FireClient(p.Value, "Down", false, character)
			end
			
			downGui.Enabled	= false
			if reviveBeam then
				reviveBeam:Destroy()
			end
			if reviveSound then
				reviveSound:Destroy()
			end
			
			if humanoid.Health > 0 then
				humanoid.Health	= math.ceil(humanoid.MaxHealth * REVIVE_HEALTH)
				down.Value		= false
			end
		else
			if rootPart:FindFirstChild("ReviveBeam") then
				rootPart.ReviveBeam:Destroy()
			end
		end
	end)
end

-- events

Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(HandleCharacter)
end)

REMOTES.LookAngle.OnServerEvent:connect(function(player, angle, twist)
	local character	= player.Character
	if character then
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player then
				REMOTES.LookAngle:FireClient(p, character, angle, twist)
			end
		end
	end
end)