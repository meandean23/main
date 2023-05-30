-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer

local EFFECTS		= Workspace:WaitForChild("Effects")
local PROJECTILES	= ReplicatedStorage:WaitForChild("Projectiles")
local REMOTES		= ReplicatedStorage:WaitForChild("Remotes")
local EVENTS		= ReplicatedStorage:WaitForChild("Events")
local MODULES		= ReplicatedStorage:WaitForChild("Modules")
	local PROJECTILE	= require(MODULES:WaitForChild("Projectile"))
	local CONFIG		= require(MODULES:WaitForChild("Config"))

-- variables

local projectiles	= {}
local currentId		= 0

-- functions

local function UpdateProjectile(projectile, deltaTime)
	projectile.Velocity		= projectile.Velocity + Vector3.new(0, -projectile.Gravity * deltaTime, 0)
	projectile.Position		= projectile.Position + projectile.Velocity * deltaTime
	
	projectile.Model.PrimaryPart.CFrame	= CFrame.new(projectile.Position, projectile.Position + projectile.Velocity)
	
	return true
end

local function Projectile(player, item, id, position, direction)
	local config		= CONFIG:GetConfig(item)
	
	local projectile	= PROJECTILE:Create(config.Projectile, id)
	projectile.Position	= position
	projectile.Velocity	= direction.Unit * projectile.Speed
	
	local model	= PROJECTILES[config.Projectile]:Clone()
		model.PrimaryPart.CFrame	= CFrame.new(projectile.Position, projectile.Position + projectile.Velocity)
		model.Parent				= EFFECTS
		
	if model.PrimaryPart:FindFirstChild("ProjectileSound") then
		model.PrimaryPart.ProjectileSound:Play()
	end
		
	projectile.Model	= model
	
	table.insert(projectiles, projectile)
end

-- events

EVENTS.Projectile.Event:connect(Projectile)

REMOTES.Projectile.OnClientEvent:connect(function(action, ...)
	if action == "Create" then
		Projectile(...)
	elseif action == "Kill" then
		local id	= ...
		local projectile, index
		for i, p in pairs(projectiles) do
			if p.ID == id then
				projectile	= p
				index		= i
				break
			end
		end
		
		if projectile then
			if action == "Kill" then
				projectile.Model:Destroy()
				table.remove(projectiles, index)
			end
		end
	end
end)

-- callbacks

REMOTES.Ping.OnClientInvoke	= function()
	return true
end

EVENTS.GetProjectileID.OnInvoke = function()
	currentId	= (currentId + 1) % 1000
	
	return PLAYER.Name .. "_" .. tostring(currentId)
end

-- loops

RunService:BindToRenderStep("Projectiles", 10, function(deltaTime)
	for i = #projectiles, 1, -1 do
		local alive	= UpdateProjectile(projectiles[i], deltaTime)
		
		if not alive then
			table.remove(projectiles, i)
		end
	end
end)