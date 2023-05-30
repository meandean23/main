-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")

-- constants

local CAMERA	= Workspace.CurrentCamera
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

local GUI			= script.Parent
local HIT_GUI		= GUI:WaitForChild("HitIndicator")

local INDICATOR_LIFE	= 2

-- variables

local indicators	= {}

-- functions

local function NewIndicator(direction, damage)
	local indicator	= {
		Start		= tick();
		Direction	= direction;
		Damage		= damage;
	}
	
	local frame	= script.HitFrame:Clone()
		frame.Indicator.Size		= UDim2.new((damage / 100) * 0.2, 0, 0.4, 0)
		frame.Indicator.Position	= UDim2.new(1.5, 0, 0.5, 0)
		frame.Parent				= HIT_GUI
		
		frame.Indicator:TweenPosition(UDim2.new(1, 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.1)
		
	indicator.Frame	= frame
	
	table.insert(indicators, indicator)
end

-- initiate

RunService:BindToRenderStep("HitIndicators", 10, function()
	local cframe	= CFrame.new(Vector3.new(), Vector3.new(CAMERA.CFrame.lookVector.X, 0, CAMERA.CFrame.lookVector.Z))
	
	for i = #indicators, 1, -1 do
		local indicator	= indicators[i]
		local life		= tick() - indicator.Start
		
		if life >= INDICATOR_LIFE then
			indicator.Frame:Destroy()
			table.remove(indicators, i)
		else
			local localDir	= cframe:VectorToObjectSpace(-indicator.Direction)
			local angle		= math.deg(math.atan2(localDir.Z, localDir.X))
			
			indicator.Frame.Rotation	= angle
			indicator.Frame.Indicator.ImageTransparency	= life / INDICATOR_LIFE
		end
	end
end)

-- events

REMOTES:WaitForChild("HitIndicator").OnClientEvent:connect(NewIndicator)