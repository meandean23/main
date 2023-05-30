--game.Cheaters:Destroy()

-- services

local PhysicsService	= game:GetService("PhysicsService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local STEP_TIME		= 0.2
local MAX_STEPS		= 50

local CHAR_COLLISION_ID	= PhysicsService:CreateCollisionGroup("Characters")

-- variables

local characters	= {}
local downs			= {}

-- functions

local function TrackCharacter(character)
	print("tracking " .. character.Name)
	local info		= {
		Heights		= {};
		Positions	= {};
		Speeds		= {};
		
		LastPosition	= nil;
	}
	
	characters[character]	= info
	
	character.AncestryChanged:connect(function()
		if not character:IsDescendantOf(Workspace) then
			if characters[character] then
				characters[character]	= nil
			end
		end
	end)
end

-- events

script.TrackCharacter.Event:connect(TrackCharacter)

Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		for _, v in pairs(character:GetChildren()) do
			if v:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(v, "Characters")
			end
		end
		
		local humanoid	= character:WaitForChild("Humanoid")
		local down		= humanoid:WaitForChild("Down")
		
		repeat wait() until character:IsDescendantOf(Workspace)
		
		humanoid.AncestryChanged:connect(function()
			if character:IsDescendantOf(Workspace) then
				print("kicking " .. player.Name .. " for godmode")
				player:Kick("REASON 1")
			end
		end)
		
		down.Changed:connect(function()
			if down.Value then
				downs[character]	= character.HumanoidRootPart.Position
			else
				if downs[character] then
					downs[character]	= nil
				end
			end
		end)
	end)
end)

-- initiate

PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)

-- main loop

while true do
	wait(STEP_TIME)
	
	for character, info in pairs(characters) do
		local rootPart	= character:FindFirstChild("HumanoidRootPart")
		local humanoid	= character:FindFirstChild("Humanoid")
		
		if rootPart and humanoid then
			-- calculate height
			--local leftRay		= Ray.new(rootPart.CFrame:pointToWorldSpace(Vector3.new(-1, 0, 0)), Vector3.new(0, -100, 0))
			--local rightRay		= Ray.new(rootPart.CFrame:pointToWorldSpace(Vector3.new(1, 0, 0)), Vector3.new(0, -100, 0))
			--[[if downs[character] then
				local distance	= (Vector2.new(rootPart.Position.X, rootPart.Position.Z) - Vector2.new(downs[character].X, downs[character].Z)).Magnitude
			
				if distance >= 250 then
					local player	= Players:GetPlayerFromCharacter(character)
					if player then
						print("kicking " .. player.Name .. " for moving too far while downed")
						player:Kick("REASON 2")
					end
				end
			end]]
			
			local height		= 0
			
			if humanoid.FloorMaterial == Enum.Material.Air then
				local middleRay		= Ray.new(rootPart.Position, Vector3.new(0, -100, 0))
				
				local _, mPos	= Workspace:FindPartOnRayWithIgnoreList(middleRay, {character})
				
				height	= rootPart.Position.Y - mPos.Y
			end
			
			table.insert(info.Heights, height)
			if #info.Heights > MAX_STEPS then
				table.remove(info.Heights, 1)
			end
			
			if #info.Heights == MAX_STEPS then
				local average	= 0
				
				for _, h in pairs(info.Heights) do
					average	= average + h
				end
				
				average	= average / #info.Heights
				
				if average >= 100 then
					local player	= Players:GetPlayerFromCharacter(character)
					if player then
						print("kicking " .. player.Name .. " for flyhacking")
						player:Kick("REASON 3")
					end
				end
			end
			
			-- get movement
			if info.LastPosition then
				local position	= Vector2.new(rootPart.Position.X, rootPart.Position.Z)
				local distance	= (position - info.LastPosition).Magnitude
				local speed		= distance / STEP_TIME
				
				info.LastPosition	= position
				
				if speed >= 1200 then
					local player	= Players:GetPlayerFromCharacter(character)
					if player then
						print("kicking " .. player.Name .. " for teleporting/speeding")
						player:Kick("REASON 4")
					end
				end
				
				table.insert(info.Speeds, speed)
				if #info.Speeds > MAX_STEPS then
					table.remove(info.Speeds, 1)
				end
				
				if #info.Speeds == MAX_STEPS then
					local average	= 0
					
					for _, s in pairs(info.Speeds) do
						average	= average + s
					end
					
					average	= average / #info.Speeds
					
					if average >= 100 then
						local player	= Players:GetPlayerFromCharacter(character)
						if player then
							print("kicking " .. player.Name .. " for speeding")
							player:Kick("REASON 5")
						end
					end
				end
			else
				info.LastPosition	= Vector2.new(rootPart.Position.X, rootPart.Position.Z)
			end
		end
	end
end