-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TeleportService	= game:GetService("TeleportService")
local TweenService		= game:GetService("TweenService")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Lighting			= game:GetService("Lighting")
local Players			= game:GetService("Players")

-- constants

local REMOTES		= ReplicatedStorage:WaitForChild("Remotes")
local EVENTS		= ReplicatedStorage:WaitForChild("Events")
local SQUADS		= ReplicatedStorage:WaitForChild("Squads")
local DATA			= ReplicatedStorage:WaitForChild("PlayerData")

local PLAYER		= Players.LocalPlayer
local PLAYER_DATA	= DATA:WaitForChild(PLAYER.Name)

local GUI				= script.Parent
local KILLER_GUI		= GUI:WaitForChild("KillerFrame")
local KILLER_INFO_GUI	= GUI:WaitForChild("KillerInfoFrame")
local MENU_BUTTON		= GUI:WaitForChild("MenuButton")
local PLACE_GUI			= GUI:WaitForChild("PlacementFrame")
local VICTORY_GUI		= GUI:WaitForChild("VictoryFrame")

local TICKETS_ICON	= "🎟"

-- variables

local cornered	= false

-- functions

-- initiate

-- events

MENU_BUTTON.MouseButton1Click:connect(function()
	script.ClickSound:Play()
	REMOTES.ReturnToMenu:FireServer()
end)

REMOTES.Victory.OnClientEvent:connect(function(place, matchInfo, xpInfo, tickets)
	if not GUI.Enabled then
		EVENTS.Modal:Fire("Push")
		GUI.Enabled	= true
	end
	
	if place == 1 then
		script.VictorySound:Play()
		
		VICTORY_GUI.Visible				= true
		Lighting.VictoryBlur.Enabled	= true
		
		local info	= TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tween	= TweenService:Create(VICTORY_GUI.VictoryLabel, info, {Size = UDim2.new(1, 0, 1, 0)})
		tween:Play()
		
		if not cornered then
			cornered	= true
			PLACE_GUI.Size		= UDim2.new(0.2, 0, 0.15, 0)
			PLACE_GUI.Position	= UDim2.new(0.9, 0, 0.8, 0)
		end
	end
	
	PLACE_GUI.PlaceLabel.Text	= "#" .. tostring(place)
	
	PLACE_GUI.PlacementLabel.StatLabel.Text	= tostring(place)
	PLACE_GUI.KillsLabel.StatLabel.Text		= tostring(matchInfo.Kills)
	PLACE_GUI.DownsLabel.StatLabel.Text		= tostring(matchInfo.Downs)
	PLACE_GUI.RevivesLabel.StatLabel.Text	= tostring(matchInfo.Revives)
	
	PLACE_GUI.Visible	= true
	
	local medal
	if place == 1 then
		medal	= PLACE_GUI.GoldLabel
	elseif place == 2 then
		medal	= PLACE_GUI.SilverLabel
	elseif place == 3 then
		medal	= PLACE_GUI.BronzeLabel
	end
	
	if medal then
		script.MedalSound:Play()
		local info		= TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tween		= TweenService:Create(medal, info, {Rotation = 0; Size = UDim2.new(0.5, 0, 0.5, 0)})
		medal.Visible	= true
		tween:Play()
	end
	
	PLACE_GUI.PlacementLabel.Visible	= true
	if xpInfo.Placement > 0 then
		for i = 1, xpInfo.Placement do
			script.TickSound.PlaybackSpeed	= 0.5 + i / 150
			script.TickSound:Play()
			
			PLACE_GUI.PlacementLabel.XPLabel.Text	= "+" .. tostring(i) .. "XP"
			RunService.Stepped:wait()
		end
	else
		PLACE_GUI.PlacementLabel.XPLabel.Text	= "+0XP"
	end
	script.ClickSound:Play()
	wait(0.1)
	
	PLACE_GUI.KillsLabel.Visible	= true
	if xpInfo.Kills > 0 then
		for i = 1, xpInfo.Kills do
			script.TickSound.PlaybackSpeed	= 0.5 + i / 150
			script.TickSound:Play()
			
			PLACE_GUI.KillsLabel.XPLabel.Text	= "+" .. tostring(i) .. "XP"
			RunService.Stepped:wait()
		end
	else
		PLACE_GUI.KillsLabel.XPLabel.Text	= "+0XP"
	end
	script.ClickSound:Play()
	wait(0.1)
	
	PLACE_GUI.DownsLabel.Visible	= true
	if xpInfo.Downs > 0 then
		for i = 1, xpInfo.Downs do
			script.TickSound.PlaybackSpeed	= 0.5 + i / 150
			script.TickSound:Play()
			
			PLACE_GUI.DownsLabel.XPLabel.Text	= "+" .. tostring(i) .. "XP"
			RunService.Stepped:wait()
		end
	else
		PLACE_GUI.DownsLabel.XPLabel.Text	= "+0XP"
	end
	script.ClickSound:Play()
	wait(0.1)
	
	PLACE_GUI.RevivesLabel.Visible	= true
	if xpInfo.Revives > 0 then
		for i = 1, xpInfo.Revives do
			script.TickSound.PlaybackSpeed	= 0.5 + i / 150
			script.TickSound:Play()
			
			PLACE_GUI.RevivesLabel.XPLabel.Text	= "+" .. tostring(i) .. "XP"
			RunService.Stepped:wait()
		end
	else
		PLACE_GUI.RevivesLabel.XPLabel.Text	= "+0XP"
	end
	script.ClickSound:Play()
	wait(0.1)
	
	PLACE_GUI.XPLabel.Text		= "+" .. tostring(xpInfo.Unboosted) .. "XP"
	PLACE_GUI.XPLabel.Visible	= true
	
	script.MedalSound:Play()
	local info	= TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local tween	= TweenService:Create(PLACE_GUI.XPLabel, info, {Size = UDim2.new(0.5, 0, 0.2, 0)})
	tween:Play()
	
	if PLAYER_DATA.BattlePass.XPBoost.Value > 0 then
		PLACE_GUI.XPLabel.BoostLabel.Text		= "+" .. tostring(PLAYER_DATA.BattlePass.XPBoost.Value) .. "%"
		PLACE_GUI.XPLabel.BoostLabel.Visible	= true
		wait(0.2)
		
		for i = 1, (xpInfo.Total - xpInfo.Unboosted) do
			script.TickSound.PlaybackSpeed	= 0.5 + i / 150
			script.TickSound:Play()
			
			PLACE_GUI.XPLabel.Text	= "+" .. tostring(xpInfo.Unboosted + i) .. "XP"
			RunService.Stepped:wait()
		end
		script.ClickSound:Play()
	end
	wait(0.1)
	
	PLACE_GUI.TicketsLabel.Text		= "+" .. tostring(tickets) .. " " .. TICKETS_ICON
	PLACE_GUI.TicketsLabel.Visible	= true
	
	script.MedalSound:Play()
	local info	= TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local tween	= TweenService:Create(PLACE_GUI.TicketsLabel, info, {Size = UDim2.new(0.5, 0, 0.2, 0)})
	tween:Play()
	
	wait(2.5)
	
	if not cornered then
		cornered	= true
		local info	= TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local tween	= TweenService:Create(PLACE_GUI, info, {Size = UDim2.new(0.2, 0, 0.15, 0); Position = UDim2.new(0.9, 0, 0.8, 0)})
		tween:Play()
	end
end)

REMOTES.Finished.OnClientEvent:connect(function(killer)
	EVENTS.Modal:Fire("Push")
	GUI.Enabled	= true
	
	if killer then
		KILLER_GUI.KillerLabel.Text	= string.upper(killer.Name)
		KILLER_GUI.Visible			= true
		
		local character	= killer.Character
		if character then
			local humanoid		= character:FindFirstChild("Humanoid")
			local armor			= humanoid:FindFirstChild("Armor")
			local killerData	= DATA:FindFirstChild(killer.Name)
			
			if killerData and humanoid then
				local function Update()
					KILLER_INFO_GUI.Bars.Armor.Size		= UDim2.new(armor.Value/150, 0, 0.4, -1)
					KILLER_INFO_GUI.Bars.Health.Size	= UDim2.new(humanoid.Health/humanoid.MaxHealth, 0, 0.6, -1)
					
					KILLER_INFO_GUI.KillsLabel.TextLabel.Text	= tostring(killerData.Stats.Kills.Value)
				end
				
				Update()
				
				humanoid.HealthChanged:connect(Update)
				armor.Changed:connect(Update)
				killerData.Stats.Kills.Changed:connect(Update)
				
				wait(0.5)
				KILLER_INFO_GUI.Visible	= true
				wait(4.5)
				KILLER_INFO_GUI.Visible	= false
			end
		end
	end
end)