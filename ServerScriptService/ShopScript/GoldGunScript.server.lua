-- constants

local CHARACTER	= script.Parent
local ITEMS		= CHARACTER.Items

-- functions

local function Goldify(part)
	if part:IsA("MeshPart") then
		part.TextureID	= ""
	end
	
	part.Color		= Color3.fromRGB(255, 157, 0)
	part.Material	= Enum.Material.Glass
	
	local emitter	= script.SparkleEmitter:Clone()
		emitter.Enabled	= true
		emitter.Parent	= part
end

-- initiate

for _, p in pairs(ITEMS:GetDescendants()) do
	if p:IsA("BasePart") then
		Goldify(p)
	end
end

-- events

ITEMS.DescendantAdded:connect(function(p)
	if p:IsA("BasePart") then
		Goldify(p)
	end
end)