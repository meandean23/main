-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Workspace			= game:GetService("Workspace")
local Lighting			= game:GetService("Lighting")

-- constants

local CAMERA	= Workspace.CurrentCamera
local EFFECTS	= Workspace:WaitForChild("Effects")
local STORM		= ReplicatedStorage:WaitForChild("Storm")
local CENTER	= STORM:WaitForChild("Center")
local RADIUS	= STORM:WaitForChild("Radius")

local BLOOM				= Lighting:WaitForChild("StormBloom")
local COLOR_CORRECTION	= Lighting:WaitForChild("StormColorCorrection")
local BLUR				= Lighting:WaitForChild("StormBlur")

-- variables

local walls		= {}

local sphere	= script.StormSphere:Clone()
	sphere.Parent	= EFFECTS
	
--[[local wall		= script.StormWall:Clone()
	wall.Parent		= EFFECTS]]

-- functions

local function Update()
	local centerDistance	= (Vector3.new(CENTER.Value.X, 0, CENTER.Value.Z) - Vector3.new(CAMERA.CFrame.X, 0, CAMERA.CFrame.Z)).Magnitude
	
	sphere.Mesh.Scale		= Vector3.new(RADIUS.Value, 500, RADIUS.Value)
	sphere.CFrame			= CFrame.new(CENTER.Value + Vector3.new(0, 250, 0))
	--wall.CFrame				= CFrame.new(Vector3.new(CENTER.Value.X, CAMERA.CFrame.Y, CENTER.Value.Z), CAMERA.CFrame.p) * CFrame.new(0, 0, -RADIUS.Value)
	
	BLOOM.Enabled				= centerDistance > RADIUS.Value
	COLOR_CORRECTION.Enabled	= centerDistance > RADIUS.Value
	BLUR.Enabled				= centerDistance > RADIUS.Value
	
	Lighting.FogEnd				= centerDistance > RADIUS.Value and 400 or math.clamp(CAMERA.CFrame.Y * 4, 1500, 100000)
	
	local edgeDistance	= RADIUS.Value - centerDistance
	
	if edgeDistance < 150 then
		if not script.StormSound.IsPlaying then
			script.StormSound:Play()
		end
		script.StormSound.Volume	= math.clamp((150 - edgeDistance) / 150, 0, 1)
	else
		if script.StormSound.IsPlaying then
			script.StormSound:Stop()
		end
	end
end

-- initiate

Update()

-- events

RADIUS.Changed:connect(Update)
CENTER.Changed:connect(Update)
CAMERA:GetPropertyChangedSignal("CFrame"):connect(Update)