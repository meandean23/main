-- services

local StarterGui	= game:GetService("StarterGui")

-- initiate

repeat local success = pcall(function() StarterGui:SetCore("TopbarEnabled", false) end) wait() until success