-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local CAMERA	= Workspace.CurrentCamera
local PLAYER	= Players.LocalPlayer

local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local ITEMS		= ReplicatedStorage:WaitForChild("Items")
local DROPS		= Workspace:WaitForChild("Drops")
local EFFECTS	= Workspace:WaitForChild("Effects")

local OUTLINE_COLOR	= Color3.fromRGB(249, 142, 190)
local OUTLINE_WIDTH	= 0.3

local UPDATE_RANGE	= 400

-- variables

local drops	= {}

-- functions

local function HandleDrop(d)
	local drop	= {
		Model	= nil;
		Outline	= nil;
		Parts	= {};
	}
	
	local model	= ITEMS[d.Name]:Clone()
		model.Parent	= EFFECTS
		model:BreakJoints()
		
	local config	= require(model:WaitForChild("Config"))
	local base		= ITEMS[d.Name]
	
	if base:FindFirstChild("Attachments") then
		local attachments	= d:WaitForChild("Attachments")
		
		for _, attach in pairs(attachments:GetChildren()) do
			local attachment	= ITEMS[attach.Name]:Clone()
			local config		= require(attachment.Config)
			attachment:SetPrimaryPartCFrame(model.PrimaryPart.CFrame * model.PrimaryPart[config.Attach .. "Attach"].CFrame * attachment.PrimaryPart.Attach.CFrame:inverse())
			attachment.Parent	= model
			attachment:BreakJoints()
		end
	end
	
	local outline	= Instance.new("Model")
		outline.Name	= "Outline"
		outline.Parent	= EFFECTS
		
	drop.Model		= model
	drop.Outline	= outline
				
	local center	= model.PrimaryPart:FindFirstChild("Center")
	
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CFrame		= CFrame.new(0, -100, 0)
			v.Anchored		= true
			v.CanCollide	= false
		
			local o	= v:Clone()
				o.Name		= "Outline"
				o.Material	= Enum.Material.Neon
				o.Color		= OUTLINE_COLOR
				o.Size		= o.Size + Vector3.new(OUTLINE_WIDTH, OUTLINE_WIDTH, OUTLINE_WIDTH)
				if o:IsA("MeshPart") then
					o.TextureID	= ""
				end
				o.Parent	= outline
		
			local info	= {
				Part		= v;
				Outline		= o;
				Offset		= CFrame.new();
			}
			
			if center then
				info.Offset	= center.WorldCFrame:toObjectSpace(v.CFrame)
			else
				info.Offset	= model.PrimaryPart.CFrame:toObjectSpace(v.CFrame)
			end
			
			table.insert(drop.Parts, info)
		end
	end
	
	drops[d]	= drop
	
	d.AncestryChanged:connect(function()
		if d.Parent ~= DROPS then
			if drops[d] then
				drops[d].Model:Destroy()
				drops[d].Outline:Destroy()
				drops[d]	= nil
			end
		end
	end)
end

-- initiate

for _, drop in pairs(DROPS:GetChildren()) do
	HandleDrop(drop)
end

local t	= 0

RunService.Stepped:connect(function(_, deltaTime)
	t	= t + deltaTime
	for drop, dropInfo in pairs(drops) do
		local offset	= drop.Position - CAMERA.CFrame.p
		
		if math.abs(offset.X) < UPDATE_RANGE and math.abs(offset.Y) < UPDATE_RANGE and math.abs(offset.Z) < UPDATE_RANGE then
			local localT	= t + (drop.Position.X + drop.Position.Z) * 0.2
			local cframe	= CFrame.new(drop.Position) * CFrame.new(0, math.sin(localT) * 0.2, 0) * CFrame.Angles(0, localT / 4, 0)
			
			for _, info in pairs(dropInfo.Parts) do
				info.Part.CFrame	= cframe * info.Offset
				local offset		= info.Part.Position - CAMERA.CFrame.p
				info.Outline.CFrame	= info.Part.CFrame + offset.Unit * OUTLINE_WIDTH * 2
			end
		end
	end
end)

-- events

DROPS.ChildAdded:connect(HandleDrop)