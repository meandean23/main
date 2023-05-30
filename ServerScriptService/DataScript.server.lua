-- services

local ReplicatedStorage	= game:GetService("ReplicatedStorage")
local DataStoreService	= game:GetService("DataStoreService")
local Players			= game:GetService("Players")

-- constants

local PLAYER_DATA	= ReplicatedStorage.PlayerData

local PREFIX		= "beta2_"
local DATASTORE		= DataStoreService:GetDataStore("Data")

local SAVE_STATS		= true
local SAVE_KEYBINDS		= false
local SAVE_EQUIPPED		= false
local SAVE_INVENTORY	= false
local SAVE_RANKING		= true
local SAVE_BATTLEPASS	= false
local SAVE_CURRENCY		= true

-- functions

local function LoadData(player)
	print("Loading " .. player.Name .."'s data...")
	local playerData	= script.PlayerData:Clone()
		playerData.Name		= player.Name
	
	local saveData
	
	local success, err	= pcall(function()
		saveData	= DATASTORE:GetAsync(PREFIX .. tostring(player.UserId))
	end)
	
	if success then
		print("\tSuccess!")
		if saveData then
			if saveData.Stats then
				for stat, value in pairs(saveData.Stats) do
					if playerData.Stats:FindFirstChild(stat) then
						playerData.Stats[stat].Value	= value
					end
				end
			end
			if saveData.Keybinds then
				for keybind, value in pairs(saveData.Keybinds)do
					if playerData.Keybinds:FindFirstChild(keybind) then
						playerData.Keybinds[keybind].Value	= value
					end
				end
			end
			if saveData.Equipped then
				for slot, item in pairs(saveData.Equipped) do
					if playerData.Equipped:FindFirstChild(slot) then
						playerData.Equipped[slot].Value	= item
					end
				end
			end
			if saveData.Inventory then
				for folder, items in pairs(saveData.Inventory) do
					if playerData.Inventory:FindFirstChild(folder) then
						for item, n in pairs(items) do
							if playerData.Inventory[folder]:FindFirstChild(item) then
								playerData.Inventory[folder][item].Value	= n
							else
								local itemValue		= Instance.new("IntValue")
									itemValue.Name		= item
									itemValue.Value		= n
									itemValue.Parent	= playerData.Inventory[folder]
							end
						end
					end
				end
			end
			if saveData.Ranking then
				for stat, value in pairs(saveData.Ranking) do
					if playerData.Ranking:FindFirstChild(stat) then
						playerData.Ranking[stat].Value	= value
					end
				end
			end
			if saveData.BattlePass then
				for stat, value in pairs(saveData.BattlePass) do
					if playerData.BattlePass:FindFirstChild(stat) then
						playerData.BattlePass[stat].Value	= value
					end
				end
			end
			if saveData.Currency then
				for stat, value in pairs(saveData.Currency) do
					if playerData.Currency:FindFirstChild(stat) then
						playerData.Currency[stat].Value	= value
					end
				end
			end
		else
			print("\tNo save data")
			print("\tRandomizing appearance")
			playerData.Equipped.Outfit.Value	= math.random(2) == 1 and "Default" or "Default Alt"
			playerData.Equipped.SkinColor.Value	= "Skin" .. tostring(math.random(5))
			playerData.Equipped.Face.Value		= playerData.Inventory.Faces:GetChildren()[math.random(#playerData.Inventory.Faces:GetChildren())].Name
			playerData.Equipped.Hat.Value		= playerData.Inventory.Hats:GetChildren()[math.random(#playerData.Inventory.Hats:GetChildren())].Name
		end
	else
		print("\tUnsafe load")
		local errorValue	= Instance.new("StringValue")
			errorValue.Name		= "ERROR_ON_LOAD"
			errorValue.Value	= err
			errorValue.Parent	= playerData
	end
	
	playerData.Parent	= PLAYER_DATA
	return playerData
end

local function SaveData(player)
	print("Saving " .. player.Name .. "'s data...")
	local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
	
	if playerData then
		if playerData:FindFirstChild("ERROR_ON_LOAD") then
			print("\tData unsafe to save, aborting")
			return false
		end
		
		local tries		= 0
		local success	= false
		
		repeat
			tries	= tries + 1
			print("\tTry #" .. tostring(tries))
			success	= pcall(function()
				DATASTORE:UpdateAsync(PREFIX .. tostring(player.UserId), function(saveData)
					if saveData then
						if not saveData.Stats then
							saveData.Stats	= {}
						end
						if not saveData.Keybinds then
							saveData.Keybinds	= {}
						end
						if not saveData.Equipped then
							saveData.Equipped	= {}
						end
						if not saveData.Inventory then
							saveData.Inventory	= {}
						end
						if not saveData.Ranking then
							saveData.Ranking	= {}
						end
						if not saveData.BattlePass then
							saveData.BattlePass	= {}
						end
						if not saveData.Currency then
							saveData.Currency	= {}
						end
					else
						saveData	= {
							Stats		= {};
							Keybinds	= {};
							Equipped	= {};
							Inventory	= {};
							Ranking		= {};
							BattlePass	= {};
							Currency	= {};
						}
					end
					
					if SAVE_STATS then
						for _, stat in pairs(playerData.Stats:GetChildren()) do
							saveData.Stats[stat.Name]	= stat.Value
						end
					end
					if SAVE_KEYBINDS then
						for _, keybind in pairs(playerData.Keybinds:GetChildren()) do
							saveData.Keybinds[keybind.Name]	= keybind.Value
						end
					end
					if SAVE_EQUIPPED then
						for _, equipped in pairs(playerData.Equipped:GetChildren()) do
							saveData.Equipped[equipped.Name]	= equipped.Value
						end
					end
					if SAVE_INVENTORY then
						for _, folder in pairs(playerData.Inventory:GetChildren()) do
							if not saveData.Inventory[folder.Name] then
								saveData.Inventory[folder.Name]	= {}
							end
							for _, item in pairs(folder:GetChildren()) do
								saveData.Inventory[folder.Name][item.Name]	= item.Value
							end
						end
					end
					if SAVE_RANKING then
						for _, stat in pairs(playerData.Ranking:GetChildren()) do
							saveData.Ranking[stat.Name]	= stat.Value
						end
					end
					if SAVE_BATTLEPASS then
						for _, stat in pairs(playerData.BattlePass:GetChildren()) do
							saveData.BattlePass[stat.Name]	= stat.Value
						end
					end
					if SAVE_CURRENCY then
						for _, stat in pairs(playerData.Currency:GetChildren()) do
							saveData.Currency[stat.Name]	= stat.Value
						end
					end
					
					return saveData
				end)
			end)
		until success or tries == 3
		return success
	else
		return false
	end
end

-- events

script.SaveData.OnInvoke	= SaveData

Players.PlayerAdded:connect(function(player)
	LoadData(player)
end)

Players.PlayerRemoving:connect(function(player)
	SaveData(player)
	local playerData	= PLAYER_DATA:FindFirstChild(player.Name)
	if playerData then
		playerData:Destroy()
	end
end)