-- services

local UserInputService	= game:GetService("UserInputService")
local CollectionService	= game:GetService("CollectionService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local CAMERA	= Workspace.CurrentCamera
local PLAYER	= Players.LocalPlayer

local SPACESHIP	= Workspace:WaitForChild("Spaceship")

local SQUADS	= ReplicatedStorage:WaitForChild("Squads")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local EVENTS	= ReplicatedStorage:WaitForChild("Events")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local SPRING	= require(MODULES:WaitForChild("Spring"))
	local INPUT		= require(MODULES:WaitForChild("Input"))

local MIN_Y, MAX_Y	= -1.4, 1.4
local SENSITIVITY	= Vector2.new(1/250, 1/250)
local CENTER_OFFSET	= Vector3.new(0, 2, 0)

local GAMEPAD_DEAD	= 0.15
local GAMEPAD_SPEED	= 3

local IGNORE_SIZE	= 1

-- variables

local character, rootPart
local parts		= {}

local x, y		= 0, 0
local zoom		= 10
local height	= 1
local shoulder	= 3

local targetZoom	= 10
local zooming		= false

local recoil	= SPRING:Create(1, 100, 10, 2)
local shaker	= SPRING:Create(1, 100, 4, 3)

local mode		= "Default"
local flying	= false

local currentSquad, spectateChar
local killerChar

local modalStack	= 0

local flyShake	= 0

-- functions

local function Lerp(a, b, d) return a + (b - a) * d end

local function ZoomSensitivity()
	return (CAMERA.FieldOfView / 70)^2
end

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

local function CenterFromSubject(subject)
	if subject then
		if subject:IsA("Humanoid") then
			local rootPart	= subject.Parent:FindFirstChild("HumanoidRootPart")
			
			if rootPart then
				return rootPart.Position
			end
		elseif subject:IsA("BasePart") then
			return subject.Position
		elseif subject:IsA("Model") then
			if subject.PrimaryPart then
				return subject.PrimaryPart.Position
			end
		end
	end
	return Vector3.new()
end
		
local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		
		parts	= {}
		for _, v in pairs(newCharacter:GetDescendants()) do
			if v:IsA("BasePart") then
				table.insert(parts, v)
			end
		end
		
		newCharacter.DescendantAdded:Connect(function(obj)
			if obj:IsA("BasePart") then
				table.insert(parts, obj)
			end
		end)
		
		newCharacter.DescendantRemoving:Connect(function(obj)
			if obj:IsA("BasePart") then
				for i, v in pairs(parts) do
					if v == obj then
						table.remove(parts, i)
						break
					end
				end
			end
		end)
		
		rootPart	= newCharacter:WaitForChild("HumanoidRootPart")
		character	= newCharacter
	end
end

local function GetIgnoreList()
	local ignore	= CollectionService:GetTagged("Ignore")
	
	if CAMERA.CameraSubject then
		if CAMERA.CameraSubject:IsA("Humanoid") then
			table.insert(ignore, CAMERA.CameraSubject.Parent)
		end
	end
	
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	
	return ignore
end

local function Raycast(ray)
	local success	= false
	local ignore	= GetIgnoreList()
	local hit, position, normal
	
	repeat
		hit, position, normal	= Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
		
		if hit then
			if hit.CanCollide then
				if hit.Transparency >= 0.5 then
					table.insert(ignore, hit)
				elseif (hit.Size.X <= IGNORE_SIZE and hit.Size.Y <= IGNORE_SIZE)
					or (hit.Size.X <= IGNORE_SIZE and hit.Size.Z <= IGNORE_SIZE)
					or (hit.Size.Y <= IGNORE_SIZE and hit.Size.Z <= IGNORE_SIZE)
				then
					table.insert(ignore, hit)
				else
					success	= true
				end
			else
				table.insert(ignore, hit)
			end
		else
			success	= true
		end
	until success
	
	return hit, position, normal
end

local function GetSpectateChar()
	if not currentSquad then
		currentSquad	= GetSquad(PLAYER)
	end
	if currentSquad then
		for _, p in pairs(currentSquad:GetChildren()) do
			local player	= p.Value
			local char		= player.Character
			if char then
				local humanoid	= char:FindFirstChild("Humanoid")
				if humanoid and humanoid.Health > 0 then
					return char
				end
			end
		end
	end
end

local function Modal(action)
	if action == "Initialize" then
		modalStack	= 0
	elseif action == "Push" then
		modalStack	= modalStack + 1
	elseif action == "Pop" then
		modalStack	= modalStack - 1
	end
	
	UserInputService.MouseIconEnabled	= modalStack ~= 0
end

-- initiate

Modal("Initialize")

CAMERA.CameraType	= Enum.CameraType.Scriptable

HandleCharacter(PLAYER.Character)

RunService:BindToRenderStep("Camera", 4, function(deltaTime)
	UserInputService.MouseBehavior		= modalStack == 0 and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	
	for _, inputObject in pairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
		if inputObject.KeyCode == Enum.KeyCode.Thumbstick2 then
			local input	= inputObject.Position
			if input.Magnitude > GAMEPAD_DEAD then
				x	= (x - input.X * GAMEPAD_SPEED * deltaTime * ZoomSensitivity()) % (math.pi * 2)
				local invert	= UserSettings().GameSettings:GetCameraYInvertValue()
				y	= math.clamp(y + input.Y * GAMEPAD_SPEED * deltaTime * invert * ZoomSensitivity(), MIN_Y, MAX_Y)
			end
		end
	end
	
	if mode == "Default" then
		if character then
			CAMERA.FieldOfView	= Lerp(CAMERA.FieldOfView, 70 - (zooming and targetZoom or 0) + (flying and rootPart.Velocity.Magnitude / 10 or 0), math.min(deltaTime * 10, 1))
			
			local center	= rootPart.Position + CENTER_OFFSET
			local cframe	= CFrame.new(center) * CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0) * CFrame.new(shoulder, height, zoom - 10 * (1 - (CAMERA.FieldOfView / 70)))
			local rotation	= cframe - cframe.p
			
			local ray		= Ray.new(center, cframe.p - center)
			local hit, position, normal	= Raycast(ray)
			
			if hit then
				position	= position + normal * 0.2
			end
			
			local distance		= (center - position).Magnitude
			local transparency	= 0
			if distance < 5 then
				transparency	= (5 - distance) / 5
			end
			
			for _, v in pairs(parts) do
				v.LocalTransparencyModifier	= transparency
			end
			
			recoil:Update(deltaTime)
			shaker:Update(deltaTime)
			
			local offset	= Vector3.new(recoil.Position.X / 2, recoil.Position.Y, recoil.Position.Z) * (CAMERA.FieldOfView / 70)
			local offset2	= shaker.Position
			
			CAMERA.CFrame	= CFrame.new(position) * rotation * CFrame.new(offset + offset2) * CFrame.Angles(offset.Z / 20, -offset.X / 20, 0)
			
			if flying then
				flyShake	= flyShake + deltaTime * (rootPart.Velocity.Magnitude / 80)
				local x, y	= math.noise(flyShake, 0.3, 0.7), math.noise(0.3, flyShake, 0.7)
				
				CAMERA.CFrame	= CAMERA.CFrame * CFrame.Angles(x * 0.015, y * 0.015, 0)
			end
			
			CAMERA.Focus	= CAMERA.CFrame * CFrame.new(0, 0, -20)
		end
	elseif mode == "Spaceship" then
		CAMERA.FieldOfView	= Lerp(CAMERA.FieldOfView, 50, math.min(deltaTime * 10, 1))
		
		y	= math.min(y, 0.5)
		
		local center	= SPACESHIP.Position
		local cframe	= CFrame.new(center) * CFrame.Angles(0, x, 0) * CFrame.Angles(y, 0, 0) * CFrame.new(0, 0, 400)
		
		CAMERA.CFrame	= cframe
		CAMERA.Focus	= CFrame.new(center)
	elseif mode == "Spectate" then
		CAMERA.FieldOfView	= Lerp(CAMERA.FieldOfView, 70, math.min(deltaTime * 10, 1))
		
		if not spectateChar then
			spectateChar	= GetSpectateChar()
			
			if not spectateChar then
				for _, p in pairs(game.Players:GetPlayers()) do
					local char		= p.Character
					if char then
						local humanoid	= char:FindFirstChild("Humanoid")
						if humanoid and humanoid.Health > 0 then
							spectateChar	= char
							break
						end
					end
				end
			end
		end
		
		if killerChar then
			local humanoid	= killerChar:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				spectateChar	= killerChar
			else
				killerChar		= nil
				spectateChar	= nil
			end
		end
		
		if spectateChar then
			local root		= spectateChar:FindFirstChild("HumanoidRootPart")
			local humanoid	= spectateChar:FindFirstChildOfClass("Humanoid")
			
			if humanoid and humanoid.Health <= 0 then
				spectateChar	= nil
			elseif root then
				local head		= spectateChar.Head
				local angle		= 0--math.asin(head.CFrame.lookVector.Y)
				local position	= (root.CFrame * CFrame.Angles(angle, 0, 0) * CFrame.new(0, 6, 20)).p
				
				local ray			= Ray.new(root.Position, position - root.Position)
				local _, position	= Raycast(ray)--Workspace:FindPartOnRayWithIgnoreList(ray, {spectateChar, Workspace.Drops})
				
				local direction	= Vector3.new(root.CFrame.lookVector.X, 0, root.CFrame.lookVector.Z).Unit
				
				if spectateChar == killerChar then
					CAMERA.CFrame	= head.CFrame * CFrame.new(3, -0.1, -4) * CFrame.Angles(0, math.pi - math.pi / 4, 0)
				else
					CAMERA.CFrame	= CAMERA.CFrame:Lerp(CFrame.new(position, position + direction) * CFrame.Angles(angle, 0, 0), math.min(deltaTime * 10))
					CAMERA.Focus	= CAMERA.CFrame * CFrame.new(0, 0, -20)
				end
			end
		end
	end
end)

-- events

REMOTES.Camera.OnClientEvent:connect(function(action, ...)
	if action == "Mode" then
		mode	= ...
	elseif action == "KillChar" then
		killerChar	= ...
		wait(7)
		if GetSpectateChar() then
			killerChar		= nil
			spectateChar	= nil
		else
			if killerChar then
				spectateChar	= killerChar
				killerChar		= nil
			end
		end
	end
end)

script.Mode.Event:connect(function(m)
	mode	= m
end)

script.Flying.Event:connect(function(f)
	flying	= f
end)

EVENTS.Modal.Event:connect(Modal)

EVENTS.Zoom.Event:connect(function(target)
	targetZoom	= target and target or 10
end)

EVENTS.Recoil.Event:connect(function(r)
	recoil:Shove(r)
	EVENTS.Sway:Fire(-Vector3.new(r.X, r.Z, 0))
end)

EVENTS.Shake.Event:connect(function(s)
	shaker:Shove(s)
end)

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Aim" then
			zooming	= true
			EVENTS.Aim:Fire(zooming)
		elseif action == "AimToggle" then
			zooming	= not zooming
			EVENTS.Aim:Fire(zooming)
		end
	end
end)

INPUT.ActionEnded:connect(function(action, processed)
	if not processed then
		if action == "Aim" then
			zooming	= false
			EVENTS.Aim:Fire(zooming)
		end
	end
end)

UserInputService.InputChanged:connect(function(inputObject, processed)
	if not processed then
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
			x	= (x - inputObject.Delta.X * SENSITIVITY.X * ZoomSensitivity()) % (math.pi * 2)
			y	= math.clamp(y - inputObject.Delta.Y * SENSITIVITY.Y * ZoomSensitivity(), MIN_Y, MAX_Y)
			
			EVENTS.Sway:Fire(Vector3.new(-inputObject.Delta.X, -inputObject.Delta.Y, 0))
		end
	end
end)

PLAYER.CharacterAdded:connect(HandleCharacter)