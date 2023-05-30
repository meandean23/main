-- services

local MarketplaceService	= game:GetService("MarketplaceService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local Players				= game:GetService("Players")

-- constants

local PLAYER_DATA	= ReplicatedStorage.PlayerData
local CUSTOMIZATION	= ReplicatedStorage.Customization

-- functions

local function EquipHat(character, hat)
	if CUSTOMIZATION.Hats:FindFirstChild(hat) then
		local hat			= CUSTOMIZATION.Hats[hat]:Clone()
		local attach		= hat.PrimaryPart
		local charAttach	= character[attach.Name]
		
		for _, v in pairs(hat:GetChildren()) do
			if v:IsA("BasePart") and v ~= attach then
				local offset	= attach.CFrame:ToObjectSpace(v.CFrame)
				
				local weld	= Instance.new("Weld")
					weld.Part0	= charAttach
					weld.Part1	= v
					weld.C0		= offset
					weld.Parent	= v
					
				v.Anchored		= false
				v.CanCollide	= false
				v.Massless		= true
			end
		end
		
		attach:Destroy()
		hat.Parent	= character.Attachments
	end
end

local function EquipOutfit(character, outfit)
	if CUSTOMIZATION.Outfits:FindFirstChild(outfit) then
		local shirt	= CUSTOMIZATION.Outfits[outfit]:FindFirstChild("Shirt")
		if shirt then
			shirt	= shirt:Clone()
				shirt.Parent	= character
		end
		local pants	= CUSTOMIZATION.Outfits[outfit]:FindFirstChild("Pants")
		if pants then
			pants	= pants:Clone()
				pants.Parent	= character
		end
	end
end

local function EquipFace(character, face)
	if CUSTOMIZATION.Faces:FindFirstChild(face) then
		local face	= CUSTOMIZATION.Faces[face]:Clone()
			face.Parent	= character.Head
	end
end

local function EquipSkinColor(character, skinColor)
	if CUSTOMIZATION.SkinColors:FindFirstChild(skinColor) then
		for _, v in pairs(character:GetChildren()) do
			if v:IsA("BasePart") then
				v.Color	= CUSTOMIZATION.SkinColors[skinColor].Value
			end
		end
	end
end

local function EquipBackpack(character, backpack)
	if CUSTOMIZATION.Backpacks:FindFirstChild(backpack) then
		local backpack		= CUSTOMIZATION.Backpacks[backpack]:Clone()
		local attach		= backpack.PrimaryPart
		local charAttach	= character[attach.Name]
		
		for _, v in pairs(backpack:GetChildren()) do
			if v:IsA("BasePart") and v ~= attach then
				local offset	= attach.CFrame:ToObjectSpace(v.CFrame)
				
				local weld	= Instance.new("Weld")
					weld.Part0	= charAttach
					weld.Part1	= v
					weld.C0		= offset
					weld.Parent	= v
					
				v.Anchored		= false
				v.CanCollide	= false
				v.Massless		= true
			end
		end
		
		attach:Destroy()
		backpack.Parent	= character.Attachments
	end
end

local function EquipEmote(character, emote)
	if CUSTOMIZATION.Emotes:FindFirstChild(emote) then
		emote	= CUSTOMIZATION.Emotes[emote]:Clone()
			emote.Parent	= character.Animate.Animations.Emotes
	end
end

local function HandleCharacter(character)
	if character then
		local playerData	= PLAYER_DATA:WaitForChild(character.Name)
		
		EquipHat(character, playerData.Equipped.Hat.Value)
		EquipHat(character, playerData.Equipped.Hat2.Value)
		EquipOutfit(character, playerData.Equipped.Outfit.Value)
		EquipFace(character, playerData.Equipped.Face.Value)
		EquipSkinColor(character, playerData.Equipped.SkinColor.Value)
		EquipBackpack(character, playerData.Equipped.Backpack.Value)
		EquipEmote(character, playerData.Equipped.Emote.Value)
	end
end

local function HandlePlayer(player)
	player.CharacterAdded:connect(HandleCharacter)
	
	HandleCharacter(player.Character)
end

-- events

Players.PlayerAdded:connect(HandlePlayer)