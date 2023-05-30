-- services

-- constants

local GUI		= script.Parent
local SQUAD_GUI	= GUI:WaitForChild("Squad")

local HEALTH_COLOR	= Color3.fromRGB(80, 208, 45)
local DOWN_COLOR	= Color3.fromRGB(216, 33, 33)

-- variables

-- functions

local function TrackPlayer(player, color)
	local character	= player.Character
	local humanoid	= character:WaitForChild("Humanoid")
	local armor		= humanoid:WaitForChild("Armor")
	local down		= humanoid:WaitForChild("Down")
	
	local frame		= script.SquadFrame:Clone()
		frame.NameLabel.Text		= player.Name
		frame.NameLabel.TextColor3	= color
		frame.Parent				= SQUAD_GUI
	
	local function Update()
		frame.Bars.Health.Size	= UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 0.6, -1)
		frame.Bars.Armor.Size	= UDim2.new(armor.Value / 150, 0, 0.4, -1)
		
		frame.Bars.Health.BackgroundColor3	= down.Value and DOWN_COLOR or HEALTH_COLOR
		frame.DownLabel.Visible	= down.Value
	end
	
	humanoid.HealthChanged:connect(Update)
	armor.Changed:connect(Update)
	down.Changed:connect(function()
		if down.Value then
			script.DownSound:Play()
		end
		
		Update()
	end)
	
	Update()
end

script.TrackPlayer.Event:connect(TrackPlayer)