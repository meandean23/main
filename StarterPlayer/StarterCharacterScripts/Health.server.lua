-- services

-- constants

local CHARACTER	= script.Parent
local HUMANOID	= CHARACTER.Humanoid
local ARMOR		= HUMANOID.Armor
local SLOTS		= HUMANOID.ArmorSlots

local SLOT_SIZE	= 30

-- variables

local lastDamage	= 0
local lastArmor		= ARMOR.Value

-- events

ARMOR.Changed:connect(function()
	if ARMOR.Value < lastArmor then
		lastDamage	= tick()
	end
	
	lastArmor	= ARMOR.Value
end)

-- loop

while true do
	wait(0.1)
	if tick() - lastDamage > 15 then
		ARMOR.Value	= math.min(ARMOR.Value + 1, SLOTS.Value * SLOT_SIZE)
	end
end