-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local SoundService		= game:GetService("SoundService")
local TweenService		= game:GetService("TweenService")
local RunService		= game:GetService("RunService")
local StarterGui		= game:GetService("StarterGui")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")
local Lighting			= game:GetService("Lighting")

-- constants

local CAMERA	= Workspace.CurrentCamera
local PLAYER	= Players.LocalPlayer

local SPACESHIP	= Workspace:WaitForChild("Spaceship")

local EFFECTS	= Workspace:WaitForChild("Effects")
local CLOUDS	= EFFECTS:WaitForChild("CloudPart")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local EFFECTS	= require(MODULES:WaitForChild("Effects"))
	local INPUT		= require(MODULES:WaitForChild("Input"))

local GAMEPAD_DEAD	= 0.15

local JUMP_POWER	= 50

local MOVE_SPEED	= 20
local CROUCH_FACTOR	= 0.6
local SPRINT_FACTOR	= 1.4
local DOWN_FACTOR	= 0.6

local RAIL_SPEED	= 50

local DASH_COOLDOWN	= 1
local RAIL_COOLDOWN	= 1

local VAULT_CHECK		= 8
local VAULT_DISTANCE	= 8
local VAULT_SPEED		= 30

-- variables

local character, humanoid, rootPart, equipped, down, stance, flightForce
local waist, waistC0, neck, neckC0
local rShoulder, rShoulderC0
local lShoulder, lShoulderC0

local rotation	= CFrame.new()

local crouching		= false
local sprinting		= false
local canRoll		= true
local doubleJump	= false

local wasGrinding	= false
local grinding		= false
local currentRail	= nil
local railOffset	= 0
local railCooldown	= 0
local railDirection	= -1

local flying			= false
local flightRotation	= CFrame.new()
local deployCooldown	= 0

local lastLookUpdate	= 0

local bounceCooldown	= 0

local vaulting	= false

-- functions

local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		
		rootPart	= newCharacter:WaitForChild("HumanoidRootPart")
		humanoid	= newCharacter:WaitForChild("Humanoid")
		down		= humanoid:WaitForChild("Down")
		stance		= humanoid:WaitForChild("Stance")
		equipped	= newCharacter:WaitForChild("Equipped")
		flightForce	= rootPart:WaitForChild("FlightForce")
		
		waist	= newCharacter:WaitForChild("UpperTorso"):WaitForChild("Waist")
		waistC0	= waist.C0
		neck	= newCharacter:WaitForChild("Head"):WaitForChild("Neck")
		neckC0	= neck.C0
		
		rShoulder	= newCharacter:WaitForChild("RightUpperArm"):WaitForChild("RightShoulder")
		rShoulderC0	= rShoulder.C0
		lShoulder	= newCharacter:WaitForChild("LeftUpperArm"):WaitForChild("LeftShoulder")
		lShoulderC0	= lShoulder.C0
		
		humanoid.AutoRotate	= false
		
		humanoid.StateChanged:connect(function(_, state)
			if state == Enum.HumanoidStateType.Landed then
				humanoid.JumpPower	= JUMP_POWER * 0.3
				
				local info	= TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
				local tween	= TweenService:Create(humanoid, info, {JumpPower = JUMP_POWER})
				
				tween:Play()
			end
		end)
		
		for _, part in pairs(newCharacter:GetChildren()) do
			if part:IsA("BasePart") then
				part.Touched:connect(function(hit)
					if hit.Name == "Rail" then
						local canGrind	= true
						if hit == currentRail and railCooldown ~= 0 then
							canGrind	= false
						end
						
						if canGrind and (not flying) then
							currentRail		= hit
							railCooldown	= 1
							
							local offset	= currentRail.CFrame:pointToObjectSpace(rootPart.Position)
							if offset.Y > 0 then
								local lookOffset	= currentRail.CFrame:vectorToObjectSpace(rootPart.CFrame.lookVector)
								railDirection		= lookOffset.Z <= 0 and -1 or 1
								railOffset	= offset.Z
								grinding	= true
								character.Animate.Grind:Fire(true)
							end
						end
					end
					
					if part == rootPart then
						if hit.Name == "Bouncer" then
							if bounceCooldown == 0 and (not down.Value) then
								bounceCooldown	= 0.5
								EFFECTS:Effect("Dash", "Bounce", rootPart)
								REMOTES.Dash:FireServer("Bounce")
								humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
								rootPart.Velocity	= Vector3.new(rootPart.Velocity.X, 100, rootPart.Velocity.Z)
							end
						end
					end
				end)
			end
		end
		
		character	= newCharacter
	end
end

local function Dash()
	if character then
		if canRoll and (not grinding) and (not flying) and (not humanoid.Down.Value) then
			canRoll	= false
			
			local direction	= humanoid.MoveDirection
			
			if direction.Magnitude > 0 then
				EFFECTS:Effect("Dash", "Dash", rootPart, direction)
				REMOTES.Dash:FireServer("Dash", direction)
				character.Animate.Dash:Fire(direction)
				
				local velocity		= direction * 70
				
				local start		= tick()
				repeat
					rootPart.Velocity	= Vector3.new(velocity.X, math.max(rootPart.Velocity.Y, velocity.Y), velocity.Z)
					RunService.Stepped:wait()
				until tick() - start > 0.2
				
				wait(DASH_COOLDOWN)
			end
			canRoll	= true
		end
	end
end

local function Vault(direction, initialDistance)
	if character and not vaulting then
		vaulting	= true
		
		--humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
		
		local distance	= initialDistance + VAULT_DISTANCE
		local velocity	= direction * VAULT_SPEED
		local timer		= distance / velocity.Magnitude
		
		character.Animate.Vault:Fire(true, timer)
		local hipHeight		= humanoid.HipHeight
		humanoid.HipHeight	= 0
		
		local start		= tick()
		local startCF	= rootPart.CFrame
		local newCF		= startCF * CFrame.new(0, 0, -distance)
		repeat
			humanoid.PlatformStand	= true
			local alpha	= math.min((tick() - start) / timer, 1)
			--rootPart.Velocity	= velocity + Vector3.new(0, (1 - 1.8 * alpha) * 50, 0)
			
			rootPart.CFrame	= startCF:Lerp(newCF, alpha) * CFrame.new(0, math.sin(math.pi * alpha)^(1/2) * 3.5, 0)
			RunService.Stepped:wait()
		until alpha > 0.9 or grinding
		
		humanoid.HipHeight	= hipHeight
		
		if grinding then
			character.Animate.Vault:Fire(false, timer)
		else
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
			rootPart.Velocity	= velocity
		end
		
		vaulting	= false
	end
end

-- initiate

repeat local success = pcall(function() StarterGui:SetCore("ResetButtonCallback", false) end) wait() until success

HandleCharacter(PLAYER.Character)

RunService:BindToRenderStep("Control", 3, function(deltaTime)
	if character and humanoid.Health > 0 then
		local lerp	= math.min(deltaTime * (down.Value and 5 or 20), 1)
		-- rotation
		local lookVector	= CAMERA.CFrame.lookVector
		rotation			= rotation:Lerp(CFrame.new(Vector3.new(), Vector3.new(lookVector.X, 0, lookVector.Z)), lerp)
		
		railCooldown	= math.max(railCooldown - deltaTime, 0)
		bounceCooldown	= math.max(bounceCooldown - deltaTime, 0)
		
		-- input
		local input	= Vector3.new()
		
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
				input	= input + Vector3.new(0, 0, -1)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
				input	= input + Vector3.new(0, 0, 1)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
				input	= input + Vector3.new(-1, 0, 0)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
				input	= input + Vector3.new(1, 0, 0)
			end
			
			for _, inputObject in pairs(UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)) do
				if inputObject.KeyCode == Enum.KeyCode.Thumbstick1 then
					if inputObject.Position.Magnitude > GAMEPAD_DEAD then
						input	= Vector3.new(inputObject.Position.X, 0, -inputObject.Position.Y)
					end
				end
			end
			
			if input.Magnitude > 0 then
				input	= input.Unit
			end
		end
		
		if flying then
			local direction	= CAMERA.CFrame:vectorToWorldSpace(input) + rootPart.CFrame.lookVector * 0.8
			direction		= Vector3.new(direction.X, math.min(direction.Y, -0.5), direction.Z)
			
			local ray		= Ray.new(rootPart.Position, Vector3.new(0, -200, 0))
			local _, pos	= Workspace:FindPartOnRayWithIgnoreList(ray, {character, Workspace.Effects})
			local height	= rootPart.Position.Y - pos.Y
			local speed		= math.clamp(height, 40, 100)
			
			SoundService.FlightWind.Volume	= math.clamp(height / 100, 0, 1)
			
			local target	= direction * speed
			
			flightForce.Force	= (target - rootPart.Velocity) * 200
			
			flightRotation	= flightRotation:Lerp(CFrame.new(Vector3.new(), rootPart.Velocity), math.min(deltaTime * 3, 1))
			rootPart.CFrame	= CFrame.new(rootPart.Position) * flightRotation
			
			deployCooldown	= math.max(deployCooldown - deltaTime, 0)
			
			CLOUDS.CloudEmitter.Enabled	= height == 200
			CLOUDS.CFrame				= CFrame.new(rootPart.Position + rootPart.Velocity, rootPart.Position + rootPart.Velocity * 2)
			
			--humanoid.PlatformStand	= true
			
			if deployCooldown == 0 and height < 5 then
				flightForce.Enabled			= false
				flying						= false
				CLOUDS.CloudEmitter.Enabled	= false
				
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				
				script.Parent.CameraScript.Flying:Fire(false)
				character.Animate.Fly:Fire(false)
				EFFECTS:Effect("Fly", character, false)
				SoundService.FlightWind:Stop()
			end
		elseif grinding then
			rootPart.CFrame	= currentRail.CFrame * CFrame.new(0, 1.1 + humanoid.HipHeight, railOffset) * CFrame.Angles(0, (railDirection == 1 and math.pi or 0), 0)
			
			railOffset			= railOffset + (railDirection * RAIL_SPEED) * deltaTime
			rootPart.Velocity	= currentRail.CFrame.lookVector * RAIL_SPEED * (-railDirection)
			
			humanoid.PlatformStand	= true
			
			local finished	= false
			if railDirection == -1 then
				finished	= railOffset < -(currentRail.Size.Z / 2)
			elseif railDirection == 1 then
				finished	= railOffset > currentRail.Size.Z / 2
			end
			if finished then
				grinding		= false
				railCooldown	= RAIL_COOLDOWN
				character.Animate.Grind:Fire(false)
			end
		else
			if not rootPart:FindFirstChild("SpaceshipWeld") then
				rootPart.CFrame		= CFrame.new(rootPart.Position) * rotation
			end
			
			-- movement
			if down.Value then
				humanoid.WalkSpeed	= MOVE_SPEED * DOWN_FACTOR
			else
				humanoid.WalkSpeed	= MOVE_SPEED * (sprinting and SPRINT_FACTOR or 1) * (crouching and CROUCH_FACTOR or 1)
			end
			
			humanoid:Move(input, true)
			
			if humanoid.FloorMaterial ~= Enum.Material.Air then
				doubleJump	= true
			end
			
			if crouching then
				stance.Value	= "Crouch"
			elseif sprinting then
				stance.Value	= "Sprint"
			else
				stance.Value	= "Walk"
			end
		end
			
		-- leaning
		local camOffset	= rootPart.CFrame:vectorToObjectSpace(Vector3.new(CAMERA.CFrame.lookVector.X, 0, CAMERA.CFrame.lookVector.Z).Unit)
		local hipOffset	= rootPart.CFrame:vectorToObjectSpace(character.LowerTorso.CFrame.lookVector)
		
		local twist	= -math.asin(camOffset.X) + math.asin(hipOffset.X)
		local angle	= math.asin(lookVector.Y) - math.asin(character.UpperTorso.CFrame.lookVector.Y) * 0.5
		
		if down.Value or flying then
			angle	= 0
			twist	= 0
		end
		if not grinding then
			twist	= 0
		end
		
		if tick() - lastLookUpdate >= 0.2 then
			--REMOTES.LookAngle:FireServer(angle, twist)
			lastLookUpdate	= tick()
		end
		
		waist.C0	= waist.C0:Lerp(waistC0 * CFrame.Angles(angle * 0.3, twist, 0), math.min(deltaTime * 10, 1))
		neck.C0		= neck.C0:Lerp(neckC0 * CFrame.Angles(angle * 0.6, 0, 0), math.min(deltaTime * 10, 1))
		rShoulder.C0	= rShoulder.C0:Lerp(rShoulderC0 * CFrame.Angles((equipped.Value and angle * 0.7 or 0), 0, 0), lerp)
		lShoulder.C0	= lShoulder.C0:Lerp(lShoulderC0 * CFrame.Angles((equipped.Value and angle * 0.7 or 0), 0, 0), lerp)
		
		if grinding and (not wasGrinding) then
			EFFECTS:Effect("Grind", character, true)
			REMOTES.Grind:FireServer(true)
		elseif (not grinding) and wasGrinding then
			EFFECTS:Effect("Grind", character, false)
			REMOTES.Grind:FireServer(false)
			
			spawn(function()
				if humanoid:GetState() == Enum.HumanoidStateType.PlatformStanding then
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
		
		wasGrinding	= grinding
	end
end)

-- events

REMOTES.Deploy.OnClientEvent:connect(function()
	script.Parent.CameraScript.Mode:Fire("Default")
	script.Parent.CameraScript.Flying:Fire(true)
	character.Animate.Fly:Fire(true)
	
	local velocity		= CAMERA.CFrame.lookVector * 100 + Vector3.new(0, -300, 0)
	
	flightRotation		= CAMERA.CFrame - CAMERA.CFrame.p
	deployCooldown		= 2
	
	EFFECTS:Effect("Fly", character, true)
	SoundService.FlightWind:Play()
	SoundService.FlightStart:Play()
	
	rootPart.CFrame	= CFrame.new(SPACESHIP.Position) + Vector3.new(0, -10, 0) + CAMERA.CFrame.lookVector * 20
	
	flying	= true
	
	for i = 1, 5 do
		rootPart.Velocity	= velocity
		RunService.Stepped:wait()
	end
end)

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Jump" then
			if character and humanoid.Health > 0 then
				if rootPart:FindFirstChild("SpaceshipWeld") then
					REMOTES.Deploy:FireServer()
				else
					if grinding then
						grinding		= false
						railCooldown	= RAIL_COOLDOWN
						character.Animate.Grind:Fire(false)
						humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					else
						if (not flying) and (not down.Value) then
							if crouching then
								crouching	= false
							else
								if humanoid.FloorMaterial ~= Enum.Material.Air then
									--[[local didVault	= false
									if sprinting and not vaulting then
										local direction	= rootPart.CFrame.LookVector
										local posA		= rootPart.Position + Vector3.new(0, -0.5, 0)
										local posB		= rootPart.Position + Vector3.new(0, 1.5, 0)
										local rayA		= Ray.new(posA, direction * VAULT_CHECK)
										local rayB		= Ray.new(posB, direction * VAULT_CHECK)
										
										local hit	= Workspace:FindPartOnRayWithIgnoreList(rayB, {character, Workspace.Effects, Workspace.Drops})
										if not hit then
											local hit, pos, normal	= Workspace:FindPartOnRayWithIgnoreList(rayA, {character, Workspace.Effects, Workspace.Drops})
											if hit then
												local distance	= (posA - pos).Magnitude
												didVault		= true
												Vault(direction, distance)
											end
										end
									end]]
									
									--if not didVault then
										humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
									--end
								elseif doubleJump then
									doubleJump	= false
									humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
									EFFECTS:Effect("Dash", "Double", rootPart)
									REMOTES.Dash:FireServer("Double")
								end
							end
						end
					end
				end
			end
		elseif action == "Sprint" then
			sprinting	= true
		elseif action == "Crouch" then
			crouching	= not crouching
		elseif action == "Dash" then
			Dash()
		end
	end
end)
			
INPUT.ActionEnded:connect(function(action, processed)
	if not processed then
		if action == "Sprint" then
			sprinting	= false
		end
	end
end)

PLAYER.CharacterAdded:connect(HandleCharacter)