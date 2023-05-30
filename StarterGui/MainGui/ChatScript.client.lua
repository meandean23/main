-- services

local UserInputService	= game:GetService("UserInputService")
local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local TextService		= game:GetService("TextService")
local RunService		= game:GetService("RunService")
local Workspace			= game:GetService("Workspace")
local Players			= game:GetService("Players")

-- constants

local PLAYER	= Players.LocalPlayer
local PLAYERGUI	= PLAYER:WaitForChild("PlayerGui")
local REMOTES	= ReplicatedStorage:WaitForChild("Remotes")
local MODULES	= ReplicatedStorage:WaitForChild("Modules")
	local INPUT		= require(MODULES:WaitForChild("Input"))

local GUI			= script.Parent
local CHAT_GUI		= GUI:WaitForChild("Chat")
local GLOBAL_GUI	= CHAT_GUI:WaitForChild("GlobalMessages")
local SQUAD_GUI		= CHAT_GUI:WaitForChild("SquadMessages")
local CHATBAR_GUI	= CHAT_GUI:WaitForChild("Chatbar")

local NUM_CHATS	= 9

local CHAT_COLORS	= {
	Squad	= Color3.fromRGB(37, 167, 227);
	Global	= Color3.fromRGB(227, 104, 22);
	Server	= Color3.fromRGB(255, 217, 23);
}

-- variables

local defaultText	= "Press [" .. INPUT:GetActionInput("Chat") .. "] to chat"
local currentScope	= "Global"

-- functions

local function NewChat(name, message, scope)
	local messageGui	= scope == "Global" and GLOBAL_GUI or SQUAD_GUI
	if scope == "Server" then
		messageGui	= currentScope == "Global" and GLOBAL_GUI or SQUAD_GUI
	end
	
	local size		= messageGui.AbsoluteSize
	local fontSize	= math.floor(size.Y / NUM_CHATS)
	local spaceSize	= TextService:GetTextSize(" ", fontSize, script.ChatLabel.Font, size)
	
	local nameText	= "[" .. name .. "]"
	local nameSize	= TextService:GetTextSize(nameText, fontSize, script.ChatLabel.NameLabel.Font, size)
	
	local messageText	= string.rep(" ", math.ceil(nameSize.X / spaceSize.X) + 1) .. message
	local messageSize	= TextService:GetTextSize(messageText, fontSize, script.ChatLabel.Font, size)
	
	local chatLabel	= script.ChatLabel:Clone()
		chatLabel.TextSize	= fontSize
		chatLabel.Size		= UDim2.new((messageSize.X + 4) / size.X, 0, messageSize.Y / size.Y, 0)
		chatLabel.Text		= messageText
		
		chatLabel.NameLabel.TextSize	= fontSize
		chatLabel.NameLabel.Text		= nameText
		chatLabel.NameLabel.TextColor3	= CHAT_COLORS[scope]
		
		if scope == "Server" then
			chatLabel.TextColor3	= CHAT_COLORS[scope]
		end
		
		chatLabel.Parent	= messageGui
		
	for _, label in pairs(messageGui:GetChildren()) do
		if label:IsA("GuiObject") then
			if label.AbsolutePosition.Y + label.AbsoluteSize.Y < messageGui.AbsolutePosition.Y then
				label:Destroy()
			end
		end
	end
end

-- events

script.PlayerJoinedSquad.Event:Connect(function()
	currentScope	= "Squad"
	CHATBAR_GUI.ScopeLabel.TextColor3	= CHAT_COLORS[currentScope]
	CHATBAR_GUI.ScopeLabel.Text			= "[" .. string.upper(currentScope) .. "]"
	GLOBAL_GUI.Visible	= currentScope == "Global"
	SQUAD_GUI.Visible	= currentScope == "Squad"
end)

CHATBAR_GUI.TextBox.FocusLost:connect(function(enterPressed)
	if enterPressed then
		local message	= CHATBAR_GUI.TextBox.Text
		
		CHATBAR_GUI.TextBox.Text	= defaultText
		REMOTES.Chat:FireServer(message, currentScope)
	end
end)

CHATBAR_GUI.TextBox.Focused:connect(function()
	if CHATBAR_GUI.TextBox.Text == defaultText then
		CHATBAR_GUI.TextBox.Text	= ""
	end
end)

INPUT.ActionBegan:connect(function(action, processed)
	if not processed then
		if action == "Chat" then
			RunService.Stepped:wait()
			CHATBAR_GUI.TextBox:CaptureFocus()
		elseif action == "ChatScope" then
			if currentScope == "Global" then
				currentScope	= "Squad"
			else
				currentScope	= "Global"
			end
			CHATBAR_GUI.ScopeLabel.TextColor3	= CHAT_COLORS[currentScope]
			CHATBAR_GUI.ScopeLabel.Text			= "[" .. string.upper(currentScope) .. "]"
			GLOBAL_GUI.Visible	= currentScope == "Global"
			SQUAD_GUI.Visible	= currentScope == "Squad"
		end
	end
end)

INPUT.KeybindChanged:connect(function(action)
	if action == "Chat" then
		defaultText	= "Press [" .. INPUT:GetActionInput("Chat") .. "] to chat"
		
		if UserInputService:GetFocusedTextBox() ~= CHATBAR_GUI.TextBox then
			CHATBAR_GUI.TextBox.Text	= defaultText
		end
	end
end)

REMOTES.Chat.OnClientEvent:connect(NewChat)

-- initiate

CHATBAR_GUI.TextBox.Text			= defaultText
CHATBAR_GUI.ScopeLabel.TextColor3	= CHAT_COLORS[currentScope]
CHATBAR_GUI.ScopeLabel.Text			= "[" .. string.upper(currentScope) .. "]"
GLOBAL_GUI.Visible	= currentScope == "Global"
SQUAD_GUI.Visible	= currentScope == "Squad"