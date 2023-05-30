-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local CAMERA	= Workspace.CurrentCamera
local STORM		= ReplicatedStorage:WaitForChild("Storm")
local EVENTS	= ReplicatedStorage:WaitForChild("Events")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local SQUADS	= ReplicatedStorage:WaitForChild("Squads")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local INPUT		= require(MODULES:WaitForChild("Input"))
	local MOUSE		= require(MODULES:WaitForChild("Mouse"))

local GUI		= script.Parent
local MINIMAP	= GUI:WaitForChild("Minimap")
local MAP		= GUI:WaitForChild("Map")
local COMPASS	= GUI:WaitForChild("Compass")

local MAP_PIN		= MAP:WaitForChild("PlayerPin")
local MINIMAP_PIN	= MINIMAP:WaitForChild("PlayerPin")
local WORLD_PIN		= script.WorldPin:Clone()
	WORLD_PIN.Parent	= Workspace:WaitForChild("Effects")

local LAYER_SIZE	= 10 -- should be a multiple of 2
local MAP_SCALE		= 8
local WORLD_SCALE	= 9500

local MAP_OFFSET	= Vector3.new()

local COMPASS_SCALE	= 8

local SQUAD_COLORS	= {
	Color3.fromRGB(132, 255, 0);
	Color3.fromRGB(5, 209, 255);
	Color3.fromRGB(255, 87, 253);
	Color3.fromRGB(255, 69, 69);
	Color3.fromRGB(255, 213, 44);
}

-- variables 

local character, rootPart

local layers		= {}
local squadmates	= {}
local pins			= {}

local canPin	= true

-- functions

local function GetSquad(player)
	for _, squad in pairs(SQUADS:GetChildren()) do
		if squad:FindFirstChild(player.Name) then
			return squad
		end
	end
end

local function InitializeCompass()
	local replacements	= {
		["0"]	= "N";
		["45"]	= "NE";
		["90"]	= "E";
		["135"]	= "SE";
		["180"]	= "S";
		["225"]	= "SW";
		["270"]	= "W";
		["315"]	= "NW";
	}
	
	for i = -360, 360, 5 do
		local text	= i >= 0 and tostring(i) or tostring(360 + i)
		
		local label	= script.CompassLabel:Clone()
			label.Position	= UDim2.new(0.5 + (i / 360) * COMPASS_SCALE, 0, 0.5, 0)
		
			if replacements[text] then
				text		= replacements[text]
				label.Size	= UDim2.new(1.2, 0, 1.2, 0)
				label.Font	= Enum.Font.SourceSansBold
			end
		
			label.Text		= text
			label.Parent	= COMPASS.Slider
	end
end

local function UpdateSquadmates()
	for player, info in pairs(squadmates) do
		local character	= player.Character
		if character and character.Parent then
			local worldPosition	= (rootPart.Position + MAP_OFFSET) / WORLD_SCALE
			local rp			= character:FindFirstChild("HumanoidRootPart")
			local humanoid		= character:FindFirstChild("Humanoid")
			
			if rp and humanoid and humanoid.Health > 0 then
				local scaledPosition	= rp.Position / WORLD_SCALE
				local minimapPosition	= (scaledPosition - worldPosition) * MAP_SCALE
				local minimapPosition2D	= Vector2.new(minimapPosition.X, minimapPosition.Z)
			
				if minimapPosition2D.Magnitude > 0.5 then
					minimapPosition2D	= minimapPosition2D.Unit * 0.5
				end
				
				info.MinimapIcon.Position	= UDim2.new(0.5 + minimapPosition2D.X, 0, 0.5 + minimapPosition2D.Y, 0)
				info.MapIcon.Position		= UDim2.new(0.5 + scaledPosition.X, 0, 0.5 + scaledPosition.Z, 0)
				
				local lookVector	= Vector2.new(rp.CFrame.lookVector.X, rp.CFrame.lookVector.Z).Unit
				local rotation		= math.deg(math.atan2(lookVector.Y, lookVector.X)) + 90
				
				info.MinimapIcon.Rotation	= rotation
				info.MapIcon.Rotation		= rotation
			else
				info.MinimapIcon:Destroy()
				info.MapIcon:Destroy()
				squadmates[player]	= nil
			end
		else
			info.MinimapIcon:Destroy()
			info.MapIcon:Destroy()
			squadmates[player]	= nil
		end
	end
end

local function UpdatePosition()
	if character then
		local worldPosition		= (rootPart.Position + MAP_OFFSET) / WORLD_SCALE
		local scaledPosition	= worldPosition * MAP_SCALE * MINIMAP.Layers.AbsoluteSize.Y
		
		for player, info in pairs(pins) do
			local pinPosition	= (((info.Position + MAP_OFFSET) / WORLD_SCALE) - worldPosition) * MAP_SCALE
			local pinPosition2D	= Vector2.new(pinPosition.X, pinPosition.Z)
			
			if pinPosition2D.Magnitude > 0.5 then
				pinPosition2D	= pinPosition2D.Unit * 0.5
			end
			
			info.MinimapPin.Position	= UDim2.new(0.5 + pinPosition2D.X, 0, 0.5 + pinPosition2D.Y, 0)
		end
		
		for i, layer in pairs(layers) do
			local center	= MINIMAP.Layers.AbsolutePosition + MINIMAP.Layers.AbsoluteSize / 2
			local position	= layer.AbsolutePosition.Y - center.Y + layer.AbsoluteSize.Y / 2
			
			layer.MapLabel.Position	= UDim2.new(0.5, -scaledPosition.X, 0.5, -scaledPosition.Z - position)
		end
		
		MAP.Player.Position	= UDim2.new(0.5 + worldPosition.X, 0, 0.5 + worldPosition.Z, 0)
		
		local targetPosition	= STORM.TargetCenter.Value / WORLD_SCALE
		local offset			= Vector2.new(targetPosition.X, targetPosition.Z) - Vector2.new(worldPosition.X, worldPosition.Z)
		local distance			= offset.Magnitude
		
		if distance > STORM.TargetRadius.Value / WORLD_SCALE then
			distance	= distance - STORM.TargetRadius.Value / WORLD_SCALE
			
			local angle		= math.deg(math.atan2(offset.X, -offset.Y)) - 90
		
			MINIMAP.Target.Visible	= true
			MINIMAP.Target.Rotation	= angle
			MINIMAP.Target.Bar.Size	= UDim2.new(0, math.min(distance * MAP_SCALE * MINIMAP.AbsoluteSize.X + 1, MINIMAP.AbsoluteSize.X / 2), 1, 0)
			
			MAP.Target.Visible	= true
			MAP.Target.Position	= MAP.Player.Position
			MAP.Target.Rotation	= angle
			MAP.Target.Bar.Size	= UDim2.new(0, distance * MAP.AbsoluteSize.X + 1, 1, 0)
		else
			MINIMAP.Target.Visible	= false
			MAP.Target.Visible		= false
		end
	end
	
	UpdateSquadmates()
end

local function UpdateStorm()
	local size		= (STORM.Radius.Value * 2) / WORLD_SCALE
	local position	= STORM.Center.Value / WORLD_SCALE
	
	for _, layer in pairs(layers) do
		layer.MapLabel.StormLabel.Size		= UDim2.new(size, 0, size, 0)
		layer.MapLabel.StormLabel.Position	= UDim2.new(0.5 + position.X, 0, 0.5 + position.Z, 0)
	end
	
	MAP.MapLabel.StormLabel.Size		= UDim2.new(size, 0, size, 0)
	MAP.MapLabel.StormLabel.Position	= UDim2.new(0.5 + position.X, 0, 0.5 + position.Z, 0)
end

local function UpdateTarget()
	local size		= (STORM.TargetRadius.Value * 2) / WORLD_SCALE
	local position	= STORM.TargetCenter.Value / WORLD_SCALE
	
	for _, layer in pairs(layers) do
		layer.MapLabel.TargetLabel.Size		= UDim2.new(size, 0, size, 0)
		layer.MapLabel.TargetLabel.Position	= UDim2.new(0.5 + position.X, 0, 0.5 + position.Z, 0)
	end
	
	MAP.MapLabel.TargetLabel.Size		= UDim2.new(size, 0, size, 0)
	MAP.MapLabel.TargetLabel.Position	= UDim2.new(0.5 + position.X, 0, 0.5 + position.Z, 0)
end

local function UpdateRotation()
	local lookVector	= CAMERA.CFrame.lookVector
	local angle			= math.atan2(lookVector.Z, lookVector.X) + math.pi / 2
	
	MINIMAP.Player.Rotation	= math.deg(angle)
	MAP.Player.Rotation		= math.deg(angle)
	
	-- update the compass
	local offset	= angle / (math.pi * 2)
	
	COMPASS.Slider.Position	= UDim2.new(0.5 - offset * COMPASS_SCALE, 0, 0, 0)
	
	local center	= COMPASS.AbsolutePosition + COMPASS.AbsoluteSize / 2
	local radius	= COMPASS.AbsoluteSize.X / 2
	
	for _, label in pairs(COMPASS.Slider:GetChildren()) do
		local c			= label.AbsolutePosition + label.AbsoluteSize / 2
		local offset	= math.abs(c.X - center.X)
		
		label.Visible	= offset < radius
		
		if label.Visible then
			local a	= offset / radius
			label.TextTransparency			= a^10
			label.TextStrokeTransparency	= a^2
		end
	end
end

local function InitializeMinimap()
	local num	= 15
	for i = -6, 6 do
		local width		= math.cos(math.asin(math.abs(i) / (num / 2)))
		
		local layer	= script.Layer:Clone()
			layer.Size		= UDim2.new(width, 0, 1 / num, 0)
			layer.Position	= UDim2.new(0.5, 0, 0.5 + (i / num), 0)
			layer.Parent	= MINIMAP.Layers
			
		layers[i]	= layer
	end
end

local function UpdateSize()
	local size	= MINIMAP.Layers.AbsoluteSize.Y
	
	for i, layer in pairs(layers) do
		layer.MapLabel.Size	= UDim2.new(0, size * MAP_SCALE, 0, size * MAP_SCALE)
		
		local size	= layer.AbsoluteSize.Y - layer.Size.Y.Offset
		
		if size % 2 ~= 0 then
			layer.Size	= UDim2.new(layer.Size.X.Scale, 0, layer.Size.Y.Scale, 1)
		else
			layer.Size	= UDim2.new(layer.Size.X.Scale, 0, layer.Size.Y.Scale, 0)
		end
	end
	
	local charSize	= CAMERA.ViewportSize.Y / 16
	local pinSize	= CAMERA.ViewportSize.Y / 20
	
	for player, info in pairs(squadmates) do
		if info.CharacterGui then
			info.CharacterGui.Size	= UDim2.new(0, charSize * 4, 0, charSize)
		end
	end
	
	for player, info in pairs(pins) do
		info.WorldPin.PinGui.Size	= UDim2.new(0, pinSize, 0, pinSize)
	end
	
	UpdatePosition()
end

local function AddSquadmate(player)
	repeat wait() until player.Character and player.Character.Parent
	local rp		= player.Character:WaitForChild("HumanoidRootPart")
	local humanoid	= player.Character:WaitForChild("Humanoid")
	
	local colorIndex	= math.random(#SQUAD_COLORS)
	local color			= SQUAD_COLORS[colorIndex]
	table.remove(SQUAD_COLORS, colorIndex)
	
	local minimapIcon	= script.Squadmate:Clone()
		minimapIcon.ImageColor3	= color
		minimapIcon.Size		= MINIMAP.Player.Size
		minimapIcon.Parent		= MINIMAP
	
	local mapIcon		= script.Squadmate:Clone()
		mapIcon.ImageColor3	= color
		mapIcon.Size		= MAP.Player.Size
		mapIcon.Parent		= MAP
		
	local mapPin	= script.MapPin:Clone()
		mapPin.ImageColor3	= color
		mapPin.Size			= MAP.PlayerPin.Size
		mapPin.Visible		= false
		mapPin.Parent		= MAP
		
	local minimapPin	= script.MapPin:Clone()
		minimapPin.ImageColor3	= color
		minimapPin.Size			= MINIMAP.PlayerPin.Size
		minimapPin.Visible		= false
		minimapPin.Parent		= MINIMAP
		
	local worldPin		= script.WorldPin:Clone()
		worldPin.PinGui.IconLabel.ImageColor3	= color
		worldPin.PinGui.Enabled	= false
		worldPin.Parent				= Workspace.Effects
	
	local info	= {
		MinimapIcon		= minimapIcon;
		MapIcon			= mapIcon;
		
		MapPin		= mapPin;
		MinimapPin	= minimapPin;
		WorldPin	= worldPin;
		
		Color			= color;
	}

	local characterGui	= script.SquadCharacterGui:Clone()
		characterGui.NameLabel.Text			= player.Name
		characterGui.NameLabel.TextColor3	= color
		characterGui.IconLabel.ImageColor3	= color
		characterGui.Adornee	= rp
		characterGui.Parent		= PLAYER.PlayerGui
		characterGui.Enabled	= true
		
		info.CharacterGui	= characterGui
		
	humanoid.Died:connect(function()
		characterGui.Enabled	= false
		
		mapPin.Visible			= false
		minimapPin.Visible		= false
		worldPin.PinGui.Enabled	= false
	end)
	
	squadmates[player]	= info
	
	GUI.SquadScript.TrackPlayer:Fire(player, color)
	GUI.ChatScript.PlayerJoinedSquad:Fire()
	
	UpdateSize()
end

local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		rootPart	= newCharacter:WaitForChild("HumanoidRootPart")
		character	= newCharacter
		
		UpdatePosition()
	end
end

local function AddPin(player, position)
	local info	= {
		Player		= player;
		Position	= position;
		
		MapPin		= nil;
		MinimapPin	= nil;
		WorldPin	= nil;
	}
	
	if player == PLAYER then
		REMOTES.Pin:FireServer("Add", position)
		
		info.MapPin		= MAP_PIN
		info.MinimapPin	= MINIMAP_PIN
		info.WorldPin	= WORLD_PIN
	elseif squadmates[player] then
		info.MapPin		= squadmates[player].MapPin
		info.MinimapPin	= squadmates[player].MinimapPin
		info.WorldPin	= squadmates[player].WorldPin
	end
	
	local scaledPosition	= (position + MAP_OFFSET) / WORLD_SCALE
	info.MapPin.Position	= UDim2.new(0.5 + scaledPosition.X, 0, 0.5 + scaledPosition.Z, 0)
	
	info.WorldPin.CFrame	= CFrame.new(position)
	
	info.MapPin.Visible				= true
	info.MinimapPin.Visible			= true
	info.WorldPin.PinGui.Enabled	= true
	
	--script.PingSound:Play()
	
	pins[player]	= info
	
	UpdateSize()
end

local function RemovePin(player)
	if pins[player] then
		pins[player].MapPin.Visible				= false
		pins[player].MinimapPin.Visible			= false
		pins[player].WorldPin.PinGui.Enabled	= false
		
		pins[player]	= nil
	end
end

local function UpdateTimer()
	local minutes	= math.floor(STORM.Timer.Value / 60)
	local seconds	= STORM.Timer.Value - minutes * 60
	
	MINIMAP.TimerFrame.TimerLabel.Text	= string.format("%d:%02d", minutes, seconds)
end


local function RefreshSquad()
	for player, info in pairs(squadmates) do
		info.MinimapIcon:Destroy()
		info.MapIcon:Destroy()
	end
	
	squadmates	= {}
	
	local squad	= GetSquad(PLAYER)
	
	if squad then
		squad.ChildAdded:connect(function(p)
			wait(0.1)
			if p.Value ~= PLAYER then
				AddSquadmate(p.Value)
			end
		end)
		
		squad.AncestryChanged:connect(function()
			if squad.Parent ~= SQUADS then
				RefreshSquad()
			end
		end)
		
		for _, p in pairs(squad:GetChildren()) do
			if p.Value ~= PLAYER then
				AddSquadmate(p.Value)
			end
		end
		
		UpdateSquadmates()
	end
end

-- initiate

InitializeCompass()
InitializeMinimap()
UpdateRotation()
UpdateStorm()
UpdateTarget()
UpdateTimer()
HandleCharacter(PLAYER.Character)
RefreshSquad()
UpdateSize()

RunService.Stepped:connect(function()
	UpdateSquadmates()
end)

-- events

REMOTES.Finished.OnClientEvent:connect(function()
	canPin	= false
	RemovePin(PLAYER)
	REMOTES.Pin:FireServer("Remove")
end)

MAP.PinButton.MouseButton1Click:connect(function(x, y)
	if canPin then
		local center	= MAP.AbsolutePosition + MAP.AbsoluteSize / 2
		local mouse		= UserInputService:GetMouseLocation()
		local offset	= mouse - center
		
		offset		= Vector2.new(offset.X / MAP.AbsoluteSize.X, (offset.Y - 36) / MAP.AbsoluteSize.Y) * WORLD_SCALE
		local ray	= Ray.new(Vector3.new(offset.X, 500, offset.Y), Vector3.new(0, -600, 0))
		
		local _, position	= Workspace:FindPartOnRayWithIgnoreList(ray, {Workspace.Effects, Workspace.Drops})
		
		AddPin(PLAYER, position)
	end
end)

MAP.PinButton.MouseButton2Click:connect(function()
	if canPin then
		RemovePin(PLAYER)
		REMOTES.Pin:FireServer("Remove")
	end
end)

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Ping" then
			if canPin then
				AddPin(PLAYER, MOUSE.WorldPosition)
			end
		end
	end
end)

REMOTES.Pin.OnClientEvent:connect(function(action, ...)
	if action == "Add" then
		AddPin(...)
	elseif action == "Remove" then
		RemovePin(...)
	end
end)

EVENTS.Aim.Event:connect(function(aiming)
	for _, info in pairs(squadmates) do
		info.WorldPin.PinGui.IconLabel.ImageTransparency	= aiming and 0.5 or 0
		info.CharacterGui.IconLabel.ImageTransparency		= aiming and 0.5 or 0
		info.CharacterGui.NameLabel.Visible					= not aiming
	end
	WORLD_PIN.PinGui.IconLabel.ImageTransparency	= aiming and 0.5 or 0
end)

CAMERA:GetPropertyChangedSignal("ViewportSize"):connect(UpdateSize)
CAMERA:GetPropertyChangedSignal("CFrame"):connect(function()
	UpdatePosition()
	UpdateRotation()
end)

STORM.Radius.Changed:connect(UpdateStorm)
STORM.Center.Changed:connect(UpdateStorm)

STORM.TargetRadius.Changed:connect(UpdateTarget)
STORM.TargetCenter.Changed:connect(UpdateTarget)

STORM.Timer.Changed:connect(UpdateTimer)

PLAYER.CharacterAdded:connect(HandleCharacter)