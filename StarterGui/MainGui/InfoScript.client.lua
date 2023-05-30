-- services

local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local TweenService			= game:GetService("TweenService")
local Players				= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer

local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

local GUI		= script.Parent
local INFO_GUI	= GUI:WaitForChild("InfoFrame")
local MAP_GUI	= GUI:WaitForChild("Minimap")

-- variables

-- functions

local function Display(text, sound)
	script.BeepSound:Play()
	
	INFO_GUI.Visible			= true
	INFO_GUI.Position			= UDim2.new(0.5, 0, 0.15, 0)
	INFO_GUI.InfoLabel.TextTransparency			= 1
	INFO_GUI.InfoLabel.TextStrokeTransparency	= 1
	INFO_GUI.InfoLabel.Text		= text
	
	INFO_GUI.BackgroundLabel.Size		= UDim2.new(0, 0, 1, 0)
	
	if sound then
		if script:FindFirstChild(sound .. "Sound") then
			script[sound .. "Sound"]:Play()
		end
	end
	
	local openInfo	= TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local closeInfo	= TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	
	local openTweenA	= TweenService:Create(INFO_GUI.InfoLabel, openInfo, {TextTransparency = 0; TextStrokeTransparency = 0; Position = UDim2.new(0.5, 0, 0.2, 0)})
	local openTweenB	= TweenService:Create(INFO_GUI.BackgroundLabel, openInfo, {Size = UDim2.new(1, 0, 1, 0)})
	
	openTweenA:Play()
	openTweenB:Play()
	
	wait(5)
	
	local closeTweenA	= TweenService:Create(INFO_GUI.InfoLabel, closeInfo, {TextTransparency = 1; TextStrokeTransparency = 1; Position = UDim2.new(0.5, 0, 0.15, 0)})
	local closeTweenB	= TweenService:Create(INFO_GUI.BackgroundLabel, closeInfo, {Size = UDim2.new(0, 0, 1, 0)})
	
	closeTweenA:Play()
	closeTweenB:Play()
	
	wait(0.5)
	INFO_GUI.Visible	= false
end

-- events

REMOTES.RoundInfo.OnClientEvent:connect(function(info, ...)
	if info == "Kills" then
		MAP_GUI.KillsFrame.KillsLabel.Text		= tostring(...)
	elseif info == "Alive" then
		MAP_GUI.PlayersFrame.PlayersLabel.Text	= tostring(...)
	elseif info == "Message" then
		Display(...)
	end
end)