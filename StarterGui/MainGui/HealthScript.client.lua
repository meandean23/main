-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local SoundService		= game:GetService("SoundService")
local TweenService		= game:GetService("TweenService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")
local Debris			= game:GetService("Debris")

-- constants

local PLAYER	= Players.LocalPlayer
local ICON_CAM	= Workspace:WaitForChild("IconCamera")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local INPUT		= require(MODULES:WaitForChild("Input"))

local GUI			= script.Parent
local HEALTH_GUI	= GUI:WaitForChild("Health")
local DAMAGE_GUI	= GUI:WaitForChild("Damage")
local PACK_GUI		= GUI:WaitForChild("HealthPacks")
local DROP_GUI		= GUI:WaitForChild("HealthPackDropper")
local MAP_GUI		= GUI:WaitForChild("Map")
local BAR_GUI		= GUI:WaitForChild("HealthPackBar")

local HEALTH_COLOR	= Color3.fromRGB(80, 208, 45)
local DOWN_COLOR	= Color3.fromRGB(216, 33, 33)

local HEAL_TIME	= 3

-- variables

local character, humanoid, down, armor, healthPacks

local lastHealth, lastArmor	= 0, 0

local healEnabled	= true
local sliderValue	= 0
local dropAmount	= 0
local dragging		= false

-- functions

local function UpdateSlider()
	if healthPacks.Value > 0 then
		local newAmount	= math.max(math.ceil(healthPacks.Value * sliderValue), 1)
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
	sliderValue	= 0
	
	local gui	= PACK_GUI.HealthButton
	
	DROP_GUI.Position	= UDim2.new(0, gui.AbsolutePosition.X, 0, gui.AbsolutePosition.Y + gui.AbsoluteSize.Y / 2)
	DROP_GUI.Visible	= true
	
	UpdateSlider()
end

local function Damage(damage)
	DAMAGE_GUI.ImageTransparency	= math.min(1 - math.min(damage / 100, 1), 0.5)
	local info	= TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tween	= TweenService:Create(DAMAGE_GUI, info, {ImageTransparency = 1})
	tween:Play()
	
	local sound	= script["DamageSound" .. tostring(math.random(8))]:Clone()
		sound.Name	= "DamageSound_Clone"
		sound.Parent	= SoundService
		sound:Play()
		Debris:AddItem(sound, sound.TimeLength)
end

local function UpdateHealth()
	if character then
		HEALTH_GUI.Foreground.Bar.Size	= UDim2.new(math.clamp(humanoid.Health / 100, 0, 1), 0, 1, 0)
		HEALTH_GUI.Foreground.Bar.BackgroundColor3	= down.Value and DOWN_COLOR or HEALTH_COLOR
		
		local difference	= humanoid.Health - lastHealth
		
		if difference < 0 then
			Damage(math.abs(difference))
		end
		
		lastHealth	= humanoid.Health
	end
end

local function UpdatePacks()
	if character then
		PACK_GUI.HealthButton.CountLabel.Text		= tostring(healthPacks.Value)
		PACK_GUI.HealthButton.CountLabel.Visible	= healthPacks.Value > 0
		
		PACK_GUI.HealthButton.Frame.ViewportFrame.ImageTransparency	= healthPacks.Value > 0 and 0 or 0.7
	end
end

local function HandleCharacter(newCharacter)
	if newCharacter then
		character	= nil
		
		humanoid	= newCharacter:WaitForChild("Humanoid")
		down		= humanoid:WaitForChild("Down")
		armor		= humanoid:WaitForChild("Armor")
		healthPacks	= newCharacter:WaitForChild("HealthPacks")
		character	= newCharacter
		
		lastHealth	= humanoid.Health
		lastArmor	= armor.Value
		
		UpdateHealth()
		UpdatePacks()
		
		humanoid.HealthChanged:connect(UpdateHealth)
		humanoid:GetPropertyChangedSignal("MaxHealth"):connect(UpdateHealth)
		down.Changed:connect(function()
			UpdateHealth()
			
			if down.Value then
				Damage(100)
			end
		end)
		
		armor.Changed:connect(function()
			local dif	= armor.Value - lastArmor
			
			if dif < 0 then
				Damage(-dif)
			end
			
			lastArmor	= armor.Value
		end)
		
		healthPacks.Changed:connect(UpdatePacks)
	end
end

-- events

DROP_GUI.CancelButton.MouseButton1Click:connect(function()
	script.ClickSound:Play()
	DROP_GUI.Visible	= false
end)

DROP_GUI.DropButton.MouseButton1Click:connect(function()
	script.ClickSound:Play()
	DROP_GUI.Visible	= false
	
	if dropAmount > 0 then
		REMOTES.DropHealth:FireServer(dropAmount)
	end
end)

DROP_GUI.Slider.SliderButton.InputBegan:connect(function(inputObject)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		script.ClickSound:Play()
		dragging	= true
	end
end)

PACK_GUI.HealthButton.MouseButton1Click:connect(function()
	if healthPacks.Value > 0 then
		script.ClickSound:Play()
		DisplaySlider()
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

REMOTES.HealingEnabled.OnClientEvent:connect(function(enabled)
	healEnabled	= enabled
	if enabled then
		if character then
			character.Animate.Heal:Fire(false)
		end
		BAR_GUI.Visible	= false
	end
end)

MAP_GUI:GetPropertyChangedSignal("Visible"):connect(function()
	if not MAP_GUI.Visible then
		DROP_GUI.Visible	= false
	end
end)

PLAYER.CharacterAdded:connect(HandleCharacter)

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Heal" then
			if character then
				if healthPacks.Value > 0 and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth and healEnabled and not down.Value then
					character.Animate.Heal:Fire(true, HEAL_TIME)
					REMOTES.Heal:FireServer()
					
					BAR_GUI.Bar.Size	= UDim2.new(0, 0, 1, 0)
					BAR_GUI.Visible		= true
					
					local info		= TweenInfo.new(HEAL_TIME, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
					local tween		= TweenService:Create(BAR_GUI.Bar, info, {Size = UDim2.new(1, 0, 1, 0)})
					
					tween:Play()
				end
			end
		end
	end
end)

INPUT.KeybindChanged:connect(function(action)
	if action == "Heal" then
		PACK_GUI.HealthButton.KeybindLabel.Text		= INPUT:GetActionInput(action)
	elseif action == "Primary" then
		BAR_GUI.KeybindLabel.Text	= "[" .. INPUT:GetActionInput(action) .. "] CANCEL"
	end
end)

REMOTES.Finished.OnClientEvent:connect(function()
	HEALTH_GUI.Visible	= false
	PACK_GUI.Visible	= false
	
	script.Disabled	= true
end)

-- initiate

HandleCharacter(PLAYER.Character)

PACK_GUI.HealthButton.Frame.ViewportFrame.CurrentCamera		= ICON_CAM
PACK_GUI.HealthButton.Frame.ViewportShadow.CurrentCamera	= ICON_CAM

PACK_GUI.HealthButton.KeybindLabel.Text		= INPUT:GetActionInput("Heal")
BAR_GUI.KeybindLabel.Text					= "[" .. INPUT:GetActionInput("Primary") .. "] CANCEL"