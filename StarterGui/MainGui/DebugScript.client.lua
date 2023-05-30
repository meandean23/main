-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")

local GUI		= script.Parent
local DEBUG_GUI	= GUI:WaitForChild("DebugLabel")

-- variables

-- functions

-- initiate

local debugInfo	= REMOTES.GetDebugInfo:InvokeServer()

DEBUG_GUI.Text	= "SERVER REGION: " .. debugInfo.ServerRegion

-- events