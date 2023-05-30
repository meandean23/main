-- services

local ServerScriptService	= game:GetService("ServerScriptService")
local ReplicatedStorage		= game:GetService("ReplicatedStorage")
local Workspace				= game:GetService("Workspace")

-- constants

local ITEM_SPAWNS	= Workspace.ItemSpawns
local ITEMS			= ReplicatedStorage.Items

local SPAWN_RATES	= {
	["AR-18"]		= 4; --
	["Longshot"]	= 4; --
	["Beagle"]		= 4; --
	["Bulldog"]		= 4; --
	["BR-30"]		= 4; --
	["Dragon"]		= 2; --
	["Hammer"]		= 4; --
	["Annihilator"]	= 4; --
	["Six Shooter"]	= 4; --
	["Node"]		= 4; --
	["Betty"]		= 4; --
	["SH-5"]		= 4; --
	["Ranger"]		= 2; --
	["Puppy"]		= 4; --
	["Whiptail"]	= 4; --
	["Demolisher"]	= 2; --
	["Wyvern"]		= 2; --
	["IF-40"]		= 2; --
	["Undertaker"]	= 3; -- 
	["Impact"]		= 4; --
	["Rook"]		= 4; --
	["Jonny Gun"]	= 4;
	
	["Katana"]		= 6; --
	["Knife"]		= 6; -- 
	["Axe"]			= 6; -- 
	["Fishing Rod"]	= 2; -- 
	
	["Rocket Launcher"]	= 1; -- 
	["Grenade"]			= 4; -- 
	
	["Laser"]				= 4;
	["Scope"]				= 4;
	["Fast Mag"]			= 4;
	["Silencer"]			= 4;
	["Extended Barrel"]		= 4;
	["Extended Mag"]		= 4;
	["Large Extended Mag"]	= 4;
	
	["Light Ammo"]		= 4;
	["Medium Ammo"]		= 4;
	["Heavy Ammo"]		= 4;
	["Shotgun Ammo"]	= 4;
	
	["Armor"]		= 12;
	["Health Pack"]	= 12;
}

local SPAWN_ITEMS	= {
	Random		= {
		"AR-18";
		"Longshot";
		"Beagle";
		"Bulldog";
		"BR-30";
		"Dragon";
		"Hammer";
		"Annihilator";
		"Six Shooter";
		"Node";
		"Betty";
		"SH-5";
		"Ranger";
		"Puppy";
		"Whiptail";
		"Demolisher";
		"Wyvern";
		"IF-40";
		"Undertaker";
		"Impact";
		"Rook";
		"Jonny Gun";
		
		"Katana";
		"Knife";
		"Fishing Rod";
		"Axe";
		
		"Rocket Launcher";
		"Grenade";
		
		"Laser";
		"Scope";
		"Fast Mag";
		"Silencer";
		"Extended Barrel";
		"Extended Mag";
		"Large Extended Mag";
		
		"Light Ammo";
		"Medium Ammo";
		"Heavy Ammo";
		"Shotgun Ammo";
		
		"Armor";
		"Health Pack";
	};
	Upgrade		= {
		"Laser";
		"Scope";
		"Fast Mag";
		"Silencer";
		"Extended Barrel";
		"Extended Mag";
		"Large Extended Mag";
	};
	Ammo		= {
		"Light Ammo";
		"Medium Ammo";
		"Heavy Ammo";
		"Shotgun Ammo";
	};
	Booster		= {
		"Armor";
		"Health Pack";
	};
	Explosive	= {
		"Rocket Launcher";
		"Grenade";
	};
	Weapon		= {
		"AR-18";
		"Longshot";
		"Beagle";
		"Bulldog";
		"BR-30";
		"Dragon";
		"Hammer";
		"Annihilator";
		"Six Shooter";
		"Node";
		"Betty";
		"SH-5";
		"Ranger";
		"Puppy";
		"Whiptail";
		"Demolisher";
		"Wyvern";
		"IF-40";
		"Undertaker";
		"Impact";
		"Rook";
		"Jonny Gun";
		
		"Katana";
		"Knife";
		"Fishing Rod";
		"Axe";
	};
	Sniper		= {
		"Ranger";
		"Dragon";
	};
	Melee		= {
		"Knife";
		"Katana";
		"Fishing Rod";
		"Axe";
	};
}

-- variables

local spawnPoints	= {}

-- functions

local function SpawnItem(item, position)
	local base		= ITEMS[item]
	local config	= require(base.Config)
	
	-- spawn item
	if config.Type == "Ammo" then
		local amount	= 0
		
		if config.Size == "Light" then
			amount	= math.random(30, 60)
		elseif config.Size == "Medium" then
			amount	= math.random(25, 50)
		elseif config.Size == "Heavy" then
			amount	= math.random(10, 20)
		elseif config.Size == "SH-5" then
			amount	= math.random(15, 30)
		end
		ServerScriptService.DropScript.Drop:Fire(item, position, amount)
	elseif config.Type == "Booster" then
		local amount	= math.random(1, config.Stack)
		ServerScriptService.DropScript.Drop:Fire(item, position, amount)
	else
		ServerScriptService.DropScript.Drop:Fire(item, position)
	end
	
	-- spawn ammo
	if config.Type == "Gun" then
		local amount	= math.random(config.Magazine * 2, config.Magazine * 5)
		local angle		= math.rad(math.random(0, 360))
		ServerScriptService.DropScript.Drop:Fire(config.Size .. " Ammo", position + 2 * Vector3.new(math.cos(angle), 0, math.sin(angle)), amount)
		
		if math.random(1, 8) == 1 then
			local items	= SPAWN_ITEMS.Upgrade
			local angle	= math.rad(math.random(0, 360))
			
			SpawnItem(items[math.random(#items)], position + 2  * Vector3.new(math.cos(angle), 0, math.sin(angle)))
		end
	end
end

-- initiate

wait(1)

local spawnParts	= ITEM_SPAWNS:GetChildren()

for i = 1, math.floor(#spawnParts * 1) do
	local index	= math.random(1, #spawnParts)
	table.insert(spawnPoints, spawnParts[index])
	table.remove(spawnParts, index)
end

for _, spawnPoint in pairs(spawnPoints) do
	local position	= spawnPoint.Position-- + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))
	local items		= SPAWN_ITEMS[spawnPoint.Name]
	local pool		= {}
	
	for _, item in pairs(items) do
		for i = 1, SPAWN_RATES[item] do
			table.insert(pool, item)
		end
	end
	
	SpawnItem(pool[math.random(#pool)], position)
end

ITEM_SPAWNS:ClearAllChildren()