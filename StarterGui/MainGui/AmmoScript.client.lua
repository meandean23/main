-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

local GUI		= script.Parent
local AMMO_GUI	= GUI:WaitForChild("Ammo"):WaitForChild("AmmoFrame")
local DROP_GUI	= GUI:WaitForChild("AmmoDropper")

-- variables

local character, ammo

local sliderValue	= 0
local currentAmmo	= "Light"
local dropAmount	= 0
local dragging		= false

-- functions

local function Update()
	if character then
		AMMO_GUI.Shotgun.AmmoLabel.Text	= ammo.Shotgun.Value
		AMMO_GUI.Heavy.AmmoLabel.Text	= ammo.Heavy.Value
		AMMO_GUI.Medium.AmmoLabel.Text	= ammo.Medium.Value
		AMMO_GUI.Light.AmmoLabel.Text	= ammo.Light.Value
		
		AMMO_GUI.Shotgun.Visible		= ammo.Shotgun.Value > 0
		AMMO_GUI.Heavy.Visible			= ammo.Heavy.Value > 0
		AMMO_GUI.Medium.Visible			= ammo.Medium.Value > 0
		AMMO_GUI.Light.Visible			= ammo.Light.Value > 0
	end
end

local function UpdateSlider()
	if ammo[currentAmmo].Value > 0 then
		local newAmount	= math.max(math.ceil(ammo[currentAmmo].Value * sliderValue), 1)
		if newAmount ~= dropAmount then
			script.DragSound:Play()
		end
		dropAmount	= newAmount
	else
		dropAmount	= 0
	end
	
	DROP_GUI.Slider.SliderButton.Position		= UDim2.new(sliderValue, 0, 0.5, 0)
	DROP_GUI.Slider.SliderButton.TextLabel.Text	= tostring(dropAmount)
end

local function DisplaySlider(ammoType)
	currentAmmo	= ammoType
	sliderValue	= 0
	
	local gui	= AMMO_GUI[ammoType]
	
	DROP_GUI.Position	= UDim2.new(0, gui.AbsolutePosition.X + gui.AbsoluteSize.X, 0, gui.AbsolutePosition.Y + gui.AbsoluteSize.Y / 2)
	DROP_GUI.Visible	= true
	
	UpdateSlider()
end

local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		
		ammo		= newCharacter:WaitForChild("Ammo")
		character	= newCharacter
		
		ammo:WaitForChild("Shotgun").Changed:connect(function()
			Update()
		end)
		ammo:WaitForChild("Heavy").Changed:connect(function()
			Update()
		end)
		ammo:WaitForChild("Medium").Changed:connect(function()
			Update()
		end)
		ammo:WaitForChild("Light").Changed:connect(function()
			Update()
		end)
		
		Update()
		
		AMMO_GUI.Shotgun.MouseButton1Click:connect(function()
			script.ClickSound:Play()
			DisplaySlider("Shotgun")
		end)
		AMMO_GUI.Heavy.MouseButton1Click:connect(function()
			script.ClickSound:Play()
			DisplaySlider("Heavy")
		end)
		AMMO_GUI.Medium.MouseButton1Click:connect(function()
			script.ClickSound:Play()
			DisplaySlider("Medium")
		end)
		AMMO_GUI.Light.MouseButton1Click:connect(function()
			script.ClickSound:Play()
			DisplaySlider("Light")
		end)
	end
end

-- initiate

HandleCharacter(PLAYER.Character)

-- events

REMOTES.Finished.OnClientEvent:connect(function()
	AMMO_GUI.Visible	= false
	script.Disabled		= true
end)

AMMO_GUI:GetPropertyChangedSignal("Visible"):connect(function()
	if not AMMO_GUI.Visible then
		DROP_GUI.Visible	= false
	end
end)

DROP_GUI.CancelButton.MouseButton1Click:connect(function()
	script.ClickSound:Play()
	DROP_GUI.Visible	= false
end)

DROP_GUI.DropButton.MouseButton1Click:connect(function()
	script.ClickSound:Play()
	DROP_GUI.Visible	= false
	
	if dropAmount > 0 then
		REMOTES.DropAmmo:FireServer(currentAmmo, dropAmount)
	end
end)

DROP_GUI.Slider.SliderButton.InputBegan:connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		script.ClickSound:Play()
		dragging	= true
	end
end)

UserInputService.InputChanged:connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
		if dragging then
			local mousePos	= UserInputService:GetMouseLocation()
			local sliderPos	= DROP_GUI.Slider.AbsolutePosition
			local offset	= mousePos - sliderPos
			
			sliderValue		= math.clamp(offset.X / DROP_GUI.Slider.AbsoluteSize.X, 0, 1)
			
			UpdateSlider()
		end
	end
end)

UserInputService.InputEnded:connect(function(inputObject, processed)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging	= false
	end
end)

PLAYER.CharacterAdded:connect(HandleCharacter)