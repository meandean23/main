-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Debris			= game:GetService("Debris")

-- constants

local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

local GUI			= script.Parent
local KILLFEED_GUI	= GUI:WaitForChild("Killfeed")
local KILL_GUI		= GUI:WaitForChild("KillFrame")

-- variables

local character, ammo

-- functions

local function Killfeed(a, b, weapon, distance)
	for _, v in pairs(KILLFEED_GUI:GetChildren()) do
		v.Position	= v.Position + UDim2.new(0, 0, -0.1, 0)
		
		if v.Position.Y.Scale <= 0 then
			v:Destroy()
		end
	end
	
	local frame	= script.KillfeedFrame:Clone()
		frame.PlayerLabel.Text		= a
		frame.DeathLabel.Text		= b
		frame.DistanceLabel.Text	= tostring(distance) .. " studs"
		frame.WeaponLabel.Text		= weapon
		frame.Position				= UDim2.new(0, 0, 1, 0)
		frame.Parent				= KILLFEED_GUI
		
	frame.WeaponLabel.Size			= UDim2.new(0, frame.WeaponLabel.TextBounds.X + 20, 0.6, 0)
	frame.WeaponLabel.Position		= UDim2.new(0, frame.PlayerLabel.TextBounds.X + frame.WeaponLabel.AbsoluteSize.X / 2, 0, 0)
	frame.DistanceLabel.Position	= frame.WeaponLabel.Position + UDim2.new(0, 0, 1, 0)
	frame.DeathLabel.Position		= frame.WeaponLabel.Position + UDim2.new(0, frame.WeaponLabel.AbsoluteSize.X / 2, 0, 0, 0)
	
	frame.BackgroundFrame.Size		= UDim2.new(0, frame.DeathLabel.Position.X.Offset + frame.DeathLabel.TextBounds.X, 1.2, 0)
	
	Debris:AddItem(frame, 60)
end

local function Kill(name, trulyDead)
	for _, label in pairs(KILL_GUI:GetChildren()) do
		label.Position	= label.Position + UDim2.new(0, 0, -1.1, 0)
	end
	
	local prefix	= trulyDead and "Killed" or "Downed"
	local text		= prefix .. " [" .. name .. "]"
	
	local label		= script.KillFrame:Clone()
		label.Parent	= KILL_GUI
	
	if trulyDead then
		label.KillSound:Play()
	else
		label.DownSound:Play()
	end
	
	local start	= tick()
	repeat
		local alpha		= math.min((tick() - start) / 0.6, 1)
		local numChars	= math.ceil(#text * alpha)
		
		label.KillLabel.Text				= string.sub(text, 1, numChars)
		label.KillLabel.OverlayLabel.Text	= string.sub(text, 1, math.min(numChars, #prefix))
		
		RunService.Stepped:wait()
	until alpha == 1
	
	Debris:AddItem(label, 5)
end

-- events

REMOTES.Killfeed.OnClientEvent:connect(Killfeed)
REMOTES.Killed.OnClientEvent:connect(Kill)