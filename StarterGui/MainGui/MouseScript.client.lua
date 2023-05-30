-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TweenService		= game:GetService("TweenService")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")
local Lighting			= game:GetService("Lighting")
local Debris			= game:GetService("Debris")

-- constants

local PLAYER	= Players.LocalPlayer
local CAMERA	= Workspace.CurrentCamera
local EFFECTS	= Workspace:WaitForChild("Effects")
local EVENTS	= ReplicatedStorage:WaitForChild("Events")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local MOUSE		= require(MODULES:WaitForChild("Mouse"))
	local SPRING	= require(MODULES:WaitForChild("Spring"))
	
local GUI		= script.Parent
local MOUSE_GUI	= GUI:WaitForChild("Mouse")
local SCOPE_GUI	= GUI:WaitForChild("Scope")
	
-- variables

local reticleSize		= 0.1
local currentReticle	= ""

local scope		= false
local aiming	= false

local scopeSpring	= SPRING:Create(1, 400, 20, 1)

-- functions

local function Lerp(a, b, d) return a + (b - a) * d end

local function UpdateReticle()
	for _, reticle in pairs(MOUSE_GUI:GetChildren()) do
		reticle.Visible	= reticle.Name == MOUSE.Reticle
	end
end

local function UpdateScope()
	SCOPE_GUI.Visible	= scope and aiming
	MOUSE_GUI.Visible	= not SCOPE_GUI.Visible
end

local function Hitmarker(position, damage, armor, headshot)
	local position	= CAMERA:WorldToViewportPoint(position)
	
	local hitmarker	= script.Hitmarker:Clone()
		hitmarker.Position	= UDim2.new(0, position.X, 0, position.Y)
		hitmarker.Size		= UDim2.new(0.05, 0, 0.05, 0)
		hitmarker.Parent	= GUI
		
	if headshot then
		for _, frame in pairs(hitmarker:GetChildren()) do
			if frame.Name ~= "Shadow" then
				frame.BackgroundColor3	= Color3.new(1, 0.2, 0.2)
			end
		end
	end
		
	local infoB		= TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenB	= TweenService:Create(hitmarker, infoB, {Size = UDim2.new(0.015, 0, 0.015, 0)})
	
	tweenB:Play()
	Debris:AddItem(hitmarker, 0.1)
	
	local damageLabel	= script.DamageLabel:Clone()
		damageLabel.Position	= UDim2.new(0, position.X, 0, position.Y)
		damageLabel.Size		= UDim2.new(0, 1, 0, 1)
		damageLabel.Text		= tostring(damage)
		damageLabel.TextColor3	= armor and Color3.fromRGB(248, 130, 33) or Color3.fromRGB(230, 230, 230)
		damageLabel.Parent		= GUI
		
	local offset	= math.random(-36, 36)
		
	local infoC		= TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
	local tweenC	= TweenService:Create(damageLabel, infoC, {Size = UDim2.new(0, 36, 0, 36); Rotation = offset / 3; Position = UDim2.new(0, position.X + offset, 0, position.Y - 48)})
	local infoD		= TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local tweenD	= TweenService:Create(damageLabel, infoD, {TextTransparency = 1; TextStrokeTransparency = 1})
	
	tweenC:Play()
	tweenD:Play()
	Debris:AddItem(damageLabel, 1)
	
	script.HitmarkerSound:Play()
	
	if armor then
		script.ArmorSound:Play()
	end
	if headshot then
		script.HeadshotSound:Play()
	end
end

-- initiate

RunService:BindToRenderStep("Mouse", 5, function(deltaTime)
	if MOUSE.Reticle ~= currentReticle then
		currentReticle	= MOUSE.Reticle
		UpdateReticle()
	end
	
	scopeSpring:Update(deltaTime)
	
	if scope and aiming then
		local ratio	= CAMERA.ViewportSize.Y / CAMERA.ViewportSize.X
		MOUSE_GUI.Position	= UDim2.new(0.5 + scopeSpring.Position.X * 0.02 * ratio, 0, 0.5 + scopeSpring.Position.Y * 0.02, 0)
	else
		MOUSE_GUI.Position	= UDim2.new(0.5, 0, 0.5, 0)
	end
	
	SCOPE_GUI.Position	= MOUSE_GUI.Position
	
	local ignore	= {EFFECTS}
	if PLAYER.Character then
		table.insert(ignore, PLAYER.Character)
	end
	
	local h, pos
	local screenPos	= MOUSE_GUI.AbsolutePosition + MOUSE_GUI.AbsoluteSize / 2
	local ray		= CAMERA:ScreenPointToRay(screenPos.X, screenPos.Y, 0)
	local mouseRay	= Ray.new(CAMERA.CFrame.p, ray.Direction * 1000)
	
	local finished	= false
	
	repeat
		h, pos	= Workspace:FindPartOnRayWithIgnoreList(mouseRay, ignore)
		
		if h then
			if h.Parent:FindFirstChildOfClass("Humanoid") then
				finished	= true
			elseif h.Transparency >= 0.5 then
				table.insert(ignore, h)
			else
				if h.CanCollide then
					finished	= true
				else
					table.insert(ignore, h)
				end
			end
		else
			finished	= true
		end
	until finished
	
	MOUSE.ScreenPosition	= screenPos
	MOUSE.WorldPosition		= pos
end)

-- events

REMOTES.Finished.OnClientEvent:connect(function()
	SCOPE_GUI.Visible	= false
	MOUSE_GUI.Visible	= false
	
	script.Disabled	= true
end)

SCOPE_GUI:GetPropertyChangedSignal("Visible"):connect(function()
	script.ScopeSound:Play()
	
	if SCOPE_GUI.Visible then
		Lighting.ScopeBlur.Enabled	= true
		Lighting.ScopeBlur.Size		= 32
		
		SCOPE_GUI.Size		= UDim2.new(1.1, 0, 1.1, 0)
		
		local info	= TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local blurTween		= TweenService:Create(Lighting.ScopeBlur, info, {Size = 0})
		local scopeTween	= TweenService:Create(SCOPE_GUI, info, {Size = UDim2.new(1.4, 0, 1.4, 0)})
		
		blurTween:Play()
		scopeTween:Play()
	else
		Lighting.ScopeBlur.Enabled	= false
	end
end)

EVENTS.Aim.Event:connect(function(a)
	aiming	= a
	UpdateScope()
end)

EVENTS.Scope.Event:connect(function(s)
	scope	= s
	UpdateScope()
end)

EVENTS.Sway.Event:connect(function(sway)
	scopeSpring:Shove(sway)
end)

EVENTS.Hitmarker.Event:connect(Hitmarker)

REMOTES.Hitmarker.OnClientEvent:connect(Hitmarker)