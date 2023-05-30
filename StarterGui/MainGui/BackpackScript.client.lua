-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TweenService		= game:GetService("TweenService")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local CAMERA	= Workspace.CurrentCamera
local DROPS		= Workspace:WaitForChild("Drops")
local ITEMS		= ReplicatedStorage:WaitForChild("Items")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local EVENTS	= ReplicatedStorage:WaitForChild("Events")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local INPUT		= require(MODULES:WaitForChild("Input"))

local GUI			= script.Parent
local BACKPACK_GUI	= GUI:WaitForChild("Backpack")
local DRAGGER_GUI	= GUI:WaitForChild("BackpackDragger")
local MAP_GUI		= GUI:WaitForChild("Map")

local MISSING_ICON	= "rbxassetid://919621532"
local BACKPACK_SIZE	= 4

local ATTACHMENT_MENU_TIME	= 0.5

local ICON_CAMERA	= Instance.new("Camera")
	ICON_CAMERA.Name		= "IconCamera"
	ICON_CAMERA.CameraType	= Enum.CameraType.Scriptable
	ICON_CAMERA.FieldOfView	= 10
	ICON_CAMERA.CFrame		= CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi, 0)
	ICON_CAMERA.Parent		= Workspace

-- variables

local slots				= {}
local charConnections	= {}
local currentSlot		= 1

local humanoid, down

local dropHeld	= false
local dragging	= false
local enabled	= true
local healing	= false

-- functions

local function Refresh()
	for i, slot in pairs(slots) do
		for _, connection in pairs(slot.Connections) do
			connection:disconnect()
		end
		
		for _, v in pairs(slot.Button.AttachmentFrame:GetChildren()) do
			if v:IsA("GuiObject") then
				v:Destroy()
			end
		end
		
		if slot.Item then
			local item		= slot.Item
			local base		= ITEMS[item.Name]
			local config	= require(item:WaitForChild("Config"))
			
			if config.Type == "Gun" or config.Type == "RocketLauncher" then
				local ammo	= item:WaitForChild("Ammo")
				slot.Button.CountLabel.Visible	= true
				slot.Button.CountLabel.Text		= ammo.Value
				
				table.insert(slot.Connections, ammo.Changed:connect(function()
					slot.Button.CountLabel.Text		= ammo.Value
				end))
			elseif config.Type == "Booster" or config.Type == "Throwable" then
				local stack	= item:WaitForChild("Stack")
				slot.Button.CountLabel.Visible	= true
				slot.Button.CountLabel.Text		= stack.Value
				
				table.insert(slot.Connections, stack.Changed:connect(function()
					slot.Button.CountLabel.Text		= stack.Value
				end))
			else
				slot.Button.CountLabel.Visible	= false
			end
			
			slot.Button.Frame.ViewportFrame:ClearAllChildren()
			
			local preview	= base:Clone()
			preview.Parent	= slot.Button.Frame.ViewportFrame
			
			local function UpdateShadow()
				slot.Button.Frame.ViewportShadow:ClearAllChildren()
				
				for _, v in pairs(slot.Button.Frame.ViewportFrame:GetChildren()) do
					v:Clone().Parent	= slot.Button.Frame.ViewportShadow
				end
			end
			
			local function UpdateCFrame()
				local center, size	= preview:GetBoundingBox()
				local offset		= center:toObjectSpace(preview.PrimaryPart.CFrame)
				
				local dist	= math.max(size.X, size.Y, size.Z)
				
				preview:SetPrimaryPartCFrame(CFrame.new(0, 0, 8 + dist * 4) * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.Angles(math.pi / 4, 0, 0) * offset)
				
				UpdateShadow()
			end
			
			if base:FindFirstChild("Attachments") then
				local attachments	= item:WaitForChild("Attachments")
				local pAttachments	= preview:WaitForChild("Attachments")
				
				local function AddAttachment(attachment)
					local attach	= ITEMS[attachment.Name]:Clone()
					local aConfig	= require(attach:WaitForChild("Config"))
					
					local center	= attach.PrimaryPart.Attach
					local iCenter	= preview.PrimaryPart[aConfig.Attach .. "Attach"]
					
					attach:SetPrimaryPartCFrame(iCenter.WorldCFrame * center.CFrame:Inverse())
					attach.Parent	= pAttachments
					
					if not slot.Button.AttachmentFrame:FindFirstChild(attachment.Name) then
						local preview		= ITEMS[attachment.Name]:Clone()
						do
							local center, size	= preview:GetBoundingBox()
							local offset		= center:toObjectSpace(preview.PrimaryPart.CFrame)
							
							local dist	= math.max(size.X, size.Y, size.Z)
							
							preview:SetPrimaryPartCFrame(CFrame.new(0, 0, 2.5 + dist * 4) * CFrame.Angles(0, -math.pi / 4, 0))
						end
						
						local button	= script.ItemAttachmentButton:Clone()
							button.ViewportFrame.CurrentCamera	= ICON_CAMERA
							button.ViewportShadow.CurrentCamera	= ICON_CAMERA
							button.Name				= attachment.Name
							preview.Parent			= button.ViewportFrame
							preview:Clone().Parent	= button.ViewportShadow
							button.Parent			= slot.Button.AttachmentFrame
							
						button.InputBegan:connect(function(inputObject)
							if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
								if attachment then
									script.DragSound:Play()
									dragging	= true
									
									if DRAGGER_GUI.Display.Frame:FindFirstChild("ViewportFrame") then
										DRAGGER_GUI.Display.Frame.ViewportFrame:Destroy()
									end
									if DRAGGER_GUI.Display.Frame:FindFirstChild("ViewportShadow") then
										DRAGGER_GUI.Display.Frame.ViewportShadow:Destroy()
									end
									button.ViewportFrame:Clone().Parent		= DRAGGER_GUI.Display.Frame
									button.ViewportShadow:Clone().Parent	= DRAGGER_GUI.Display.Frame
									DRAGGER_GUI.Visible	= true
									button.Visible		= false
									
									local targetIndex	= 1
									
									local dropping	= false
									repeat
										RunService.RenderStepped:wait()
										local mouseLoc	= UserInputService:GetMouseLocation()
										local offset	= mouseLoc - DRAGGER_GUI.AbsolutePosition
										
										targetIndex		= math.clamp(math.ceil((offset.X / DRAGGER_GUI.AbsoluteSize.X) * BACKPACK_SIZE), 1, BACKPACK_SIZE)
										
										DRAGGER_GUI.Display.Position	= UDim2.new(0, offset.X, 0, offset.Y - 36)
										DRAGGER_GUI.Selector.Position	= UDim2.new((targetIndex - 1) * 0.25, 0, 0, 0)
										
										local position, size	= DRAGGER_GUI.DropLabel.AbsolutePosition + Vector2.new(0, 36), DRAGGER_GUI.DropLabel.AbsoluteSize
										
										if mouseLoc.X >= position.X and
											mouseLoc.X <= position.X + size.X and
											mouseLoc.Y >= position.Y and
											mouseLoc.Y <= position.Y + size.Y
										then
											dropping	= true
										else
											dropping	= false
										end
										DRAGGER_GUI.DropLabel.ImageTransparency				= dropping and 0.5 or 0.8
										DRAGGER_GUI.DropLabel.IconLabel.ImageTransparency	= dropping and 0 or 0.5
									until not dragging
									
									if dropping then
										button:Destroy()
										REMOTES.Drop:FireServer(attachment)
									else
										if slots[targetIndex].Item and slots[targetIndex].Item:FindFirstChild("Attachments") then
											REMOTES.SwapAttachment:FireServer(attachment, slots[targetIndex].Item)
										end
									end
									
									DRAGGER_GUI.Visible	= false
									if button then
										button.Visible		= true
									end
								end
							end
						end)
					end
				end
				
				local function RemoveAttachment(attachment)
					if pAttachments:FindFirstChild(attachment.Name) then
						pAttachments[attachment.Name]:Destroy()
					end
					if slot.Button.AttachmentFrame:FindFirstChild(attachment.Name) then
						slot.Button.AttachmentFrame[attachment.Name]:Destroy()
					end
				end
				
				for _, child in pairs(attachments:GetChildren()) do
					AddAttachment(child)
				end
				
				table.insert(slot.Connections, attachments.ChildAdded:connect(function(child)
					spawn(function()
						AddAttachment(child)
						UpdateCFrame()
					end)
				end))
				
				table.insert(slot.Connections, attachments.ChildRemoved:connect(function(child)
					RemoveAttachment(child)
					UpdateCFrame()
				end))
			end
			
			UpdateCFrame()
			
			slot.Button.Frame.ViewportFrame.Visible	= true
		else
			--slot.Button.Frame.IconLabel.Visible		= false
			--slot.Button.Frame.ShadowLabel.Visible	= false
			slot.Button.Frame.ViewportFrame.Visible	= false
			
			slot.Button.CountLabel.Visible	= false
		end
	end
end

local function UpdateSlotSizes()
	for i, slot in pairs(slots) do
		if currentSlot == i then
			slot.Button.UIScale.Scale	= 1
		else
			slot.Button.UIScale.Scale	= MAP_GUI.Visible and 0.9 or 0.7
		end
	end
end

local function SetSlot(newSlot)
	currentSlot	= newSlot
	
	UpdateSlotSizes()
	
	if enabled and (not healing) then
		if down then
			if down.Value then
				REMOTES.Equip:FireServer(nil)
			else
				REMOTES.Equip:FireServer(slots[currentSlot].Item)
			end
		end
	end
	
	if script.Parent:FindFirstChild("AttachmentDrop") then
		script.Parent.AttachmentDrop:Destroy()
	end
end

local function AddItem(item)
	local slot	= slots[currentSlot]
	
	if slot.Item then
		for i, slot in pairs(slots) do
			if not slot.Item then
				slot.Item	= item
				
				break
			end
		end
	else
		slot.Item	= item
	end
	Refresh()
end

local function RemoveItem(item)
	for i, slot in pairs(slots) do
		if slot.Item == item then
			slot.Item	= nil
			for _, con in pairs(slot.Connections) do
				con:disconnect()
			end
			slot.Connections	= {}
			
			slot.Button.CountLabel.Visible	= false
			break
		end
	end
	Refresh()
end

local function HandleCharacter(character)
	if character then
		humanoid	= character:WaitForChild("Humanoid")
		down		= humanoid:WaitForChild("Down")
		
		for _, connection in pairs(charConnections) do
			connection:disconnect()
		end
		charConnections	= {}
		
		for i, slot in pairs(slots) do
			slot.Item	= nil
			for _, connection in pairs(slot.Connections) do
				connection:disconnect()
			end
			slot.Connections	= {}
		end
		
		currentSlot	= 1
		
		local items	= character:WaitForChild("Items")
		
		table.insert(charConnections, items.ChildAdded:connect(function(item)
			AddItem(item)
			SetSlot(currentSlot)
		end))
		table.insert(charConnections, items.ChildRemoved:connect(function(item)
			RemoveItem(item)
			SetSlot(currentSlot)
		end))
		table.insert(charConnections, down.Changed:connect(function()
			SetSlot(currentSlot)
		end))
		
		for _, item in pairs(items:GetChildren()) do
			AddItem(item)
		end
		
		SetSlot(currentSlot)
	end
end

local function DropAttachments(item)
	local attachments		= item.Attachments:GetChildren()
	local numAttachments	= #attachments
	local distance			= 0.5 + numAttachments * 0.05
	
	EVENTS.Modal:Fire("Push")
	
	local gui	= script.AttachmentDrop:Clone()
		gui.Parent	= script.Parent
	
	for i, attachment in pairs(attachments) do
		local config	= require(attachment.Config)
		local angle		= ((i - 1) / numAttachments) * (math.pi * 2)
		local offset	= Vector2.new(distance * math.cos(angle), distance * math.sin(angle))
		
		local preview		= ITEMS[attachment.Name]:Clone()
		do
			local center, size	= preview:GetBoundingBox()
			local offset		= center:toObjectSpace(preview.PrimaryPart.CFrame)
			
			local dist	= math.max(size.X, size.Y, size.Z)
			
			preview:SetPrimaryPartCFrame(CFrame.new(0, 0, 2.5 + dist * 4) * CFrame.Angles(0, -math.pi / 4, 0))
		end
		
		local button	= script.AttachmentButton:Clone()
			button.ViewportFrame.CurrentCamera	= ICON_CAMERA
			button.ViewportShadow.CurrentCamera	= ICON_CAMERA
			preview.Parent			= button.ViewportFrame
			preview:Clone().Parent	= button.ViewportShadow
			button.Position		= UDim2.new(0.5, 0, 0.5, 0)
			button.Parent		= gui
		
		local info	= TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tween	= TweenService:Create(button, info, {Position = UDim2.new(0.5 + offset.X, 0, 0.5 + offset.Y, 0)})
		tween:Play()
			
		button.MouseButton1Click:connect(function()
			script.ClickSound:Play()
			REMOTES.Drop:FireServer(attachment)
			gui:Destroy()
		end)
	end
	
	gui.CancelButton.MouseButton1Click:connect(function()
		script.ClickSound:Play()
		gui:Destroy()
	end)
	
	gui.AncestryChanged:connect(function()
		EVENTS.Modal:Fire("Pop")
	end)
end

local function MoveSlot(moveIndex, targetIndex)
	local moveSlot		= slots[moveIndex]
	local targetSlot	= slots[targetIndex]
	
	local moveItem		= moveSlot.Item
	local targetItem	= targetSlot.Item
	
	targetSlot.Item		= moveItem
	moveSlot.Item		= targetItem
	
	Refresh()
	SetSlot(currentSlot)
end

-- initiate

for i = 1, BACKPACK_SIZE do
	local button	= script.ItemButton:Clone()
		button.LayoutOrder		= i
		button.Position			= UDim2.new((i - 1) * 0.25 + 0.125, 0, 0.5, 0)
		button.UIScale.Scale	= 0.8
		button.IndexLabel.Text	= INPUT:GetActionInput("Backpack" .. tostring(i))
		button.Frame.BackgroundLabel.Rotation		= math.random(0, 360)
		button.Frame.ViewportFrame.CurrentCamera	= ICON_CAMERA
		button.Frame.ViewportShadow.CurrentCamera	= ICON_CAMERA
		button.Parent			= BACKPACK_GUI
	
	button.Frame.ViewportFrame:GetPropertyChangedSignal("Visible"):connect(function()
		button.Frame.ViewportShadow.Visible	= button.Frame.ViewportFrame.Visible
	end)
		
	button.InputBegan:connect(function(inputObject)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
			local slot	= slots[i]
			local item	= slot.Item
			
			if item then
				script.DragSound:Play()
				dragging	= true
				
				if DRAGGER_GUI.Display.Frame:FindFirstChild("ViewportFrame") then
					DRAGGER_GUI.Display.Frame.ViewportFrame:Destroy()
				end
				if DRAGGER_GUI.Display.Frame:FindFirstChild("ViewportShadow") then
					DRAGGER_GUI.Display.Frame.ViewportShadow:Destroy()
				end
				button.Frame.ViewportFrame:Clone().Parent	= DRAGGER_GUI.Display.Frame
				button.Frame.ViewportShadow:Clone().Parent	= DRAGGER_GUI.Display.Frame
				DRAGGER_GUI.Visible	= true
				button.Visible		= false
				
				local targetIndex	= 1
				
				local dropping	= false
				repeat
					RunService.RenderStepped:wait()
					local mouseLoc	= UserInputService:GetMouseLocation()
					local offset	= mouseLoc - DRAGGER_GUI.AbsolutePosition
					
					targetIndex		= math.clamp(math.ceil((offset.X / DRAGGER_GUI.AbsoluteSize.X) * BACKPACK_SIZE), 1, BACKPACK_SIZE)
					
					DRAGGER_GUI.Display.Position	= UDim2.new(0, offset.X, 0, offset.Y - 36)
					DRAGGER_GUI.Selector.Position	= UDim2.new((targetIndex - 1) * 0.25, 0, 0, 0)
					
					local position, size	= DRAGGER_GUI.DropLabel.AbsolutePosition + Vector2.new(0, 36), DRAGGER_GUI.DropLabel.AbsoluteSize
										
					if mouseLoc.X >= position.X and
						mouseLoc.X <= position.X + size.X and
						mouseLoc.Y >= position.Y and
						mouseLoc.Y <= position.Y + size.Y
					then
						dropping	= true
					else
						dropping	= false
					end
					DRAGGER_GUI.DropLabel.ImageTransparency				= dropping and 0.5 or 0.8
					DRAGGER_GUI.DropLabel.IconLabel.ImageTransparency	= dropping and 0 or 0.5
				until not dragging
				
				if dropping then
					if slots[i].Item then
						slots[i].Button.Frame.ViewportFrame:ClearAllChildren()
						slots[i].Button.Frame.ViewportShadow:ClearAllChildren()
						slots[i].Button.CountLabel.Visible	= false
						for _, v in pairs(slots[i].Button.AttachmentFrame:GetChildren()) do
							if v:IsA("GuiObject") then
								v:Destroy()
							end
						end
						REMOTES.Drop:FireServer(slots[i].Item)
					end
				else
					MoveSlot(i, targetIndex)
				end
				
				DRAGGER_GUI.Visible	= false
				button.Visible		= true
			end
		end
	end)
		
	table.insert(slots, {Item = nil; Button = button; Connections = {}})
end

HandleCharacter(PLAYER.Character)

Refresh()
SetSlot(1)

-- events

MAP_GUI:GetPropertyChangedSignal("Visible"):Connect(function()
	UpdateSlotSizes()
	for _, slot in pairs(slots) do
		slot.Button.AttachmentFrame.Visible	= MAP_GUI.Visible
	end
end)

INPUT.KeybindChanged:connect(function(action)
	local index	= string.match(action, "Backpack(%d)")
	if index then
		slots[tonumber(index)].Button.IndexLabel.Text	= INPUT:GetActionInput(action)
	end
end)

REMOTES.BackpackEnabled.OnClientEvent:connect(function(e)
	enabled	= e
	if enabled then
		SetSlot(currentSlot)
	end
end)

REMOTES.HealingEnabled.OnClientEvent:connect(function(h)
	healing	= not h
	if not healing then
		SetSlot(currentSlot)
	end
end)

UserInputService.InputChanged:connect(function(inputObject, processed)
	if not processed then
		if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			local newSlot	= currentSlot - inputObject.Position.Z
			
			if newSlot > BACKPACK_SIZE then
				newSlot	= 1
			elseif newSlot < 1 then
				newSlot	= BACKPACK_SIZE
			end
			
			SetSlot(newSlot)
		end
	end
end)

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Backpack1" then
			SetSlot(1)
		elseif action == "Backpack2" then
			SetSlot(2)
		elseif action == "Backpack3" then
			SetSlot(3)
		elseif action == "Backpack4" then
			SetSlot(4)
		--elseif action == "Backpack5" then
		--	SetSlot(5)
		end
		
		if action == "Primary" then
			if healing then
				healing	= false
				SetSlot(currentSlot)
			end
		end
		
		if action == "Drop" then
			dropHeld	= true
			local character	= PLAYER.Character
			if character then
				local equipped	= character.Equipped.Value
				
				if equipped then
					if equipped:FindFirstChild("Attachments") and #equipped.Attachments:GetChildren() > 0 then
						local start	= tick()
						local alpha	= 0
						
						repeat
							RunService.Stepped:wait()
							alpha	= math.min((tick() - start) / ATTACHMENT_MENU_TIME, 1)
						until alpha == 1 or (not dropHeld)
						
						if alpha == 1 then
							DropAttachments(equipped)
						else
							REMOTES.Drop:FireServer(equipped)
						end
					else
						REMOTES.Drop:FireServer(equipped)
					end
				end
			end
		end
	end
end)
		
INPUT.ActionEnded:connect(function(action, processed)
	if not processed then
		if action == "Drop" then
			dropHeld	= false
		end
	end
end)

UserInputService.InputEnded:connect(function(inputObject, processed)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging	= false
	end
end)

REMOTES.Finished.OnClientEvent:connect(function()
	BACKPACK_GUI.Visible	= false
	DRAGGER_GUI.Visible		= false
	
	script.Disabled	= true
end)

PLAYER.CharacterAdded:connect(HandleCharacter)

-- main loop