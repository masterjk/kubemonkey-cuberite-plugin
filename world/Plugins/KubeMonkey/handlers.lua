
function HandleKillCommand(Split, Player)
	LOG("Player Suicide")
	Player:TakeDamage(dtInVoid, nil, 1000, 1000, 0)
	return true
end

function HandleVillagerCommand(Split, Player)
	cRoot:Get():GetDefaultWorld():SpawnMob(Player:GetPosX() + 5, Player:GetPosY(), Player:GetPosZ() + 5, mtVillager, false)
	return true
end

function HandleCreeperCommand(Split, Player)
	cRoot:Get():GetDefaultWorld():SpawnMob(Player:GetPosX() + 5, Player:GetPosY(), Player:GetPosZ() + 5, mtCreeper, false)
	return true
end

function HandleZombieCommand(Split, Player)
	local entityId = cRoot:Get():GetDefaultWorld():SpawnMob(Player:GetPosX() + 5, Player:GetPosY(), Player:GetPosZ() + 5, mtZombie, false)
	cRoot:Get():GetDefaultWorld():DoWithEntityByID(entityId, ApplyZombieEffects)
	return true
end

function HandlePosCommand(Split, Player)
	cRoot:Get():BroadcastChat("X: " .. Player:GetPosX() .. "; Y: " .. Player:GetPosY() .. "; Z: " .. Player:GetPosZ())
	return true
end

function HandleSpawnCommand(Split, Player)
	cRoot:Get():GetDefaultWorld():SpawnMob(Player:GetPosX() + 5, Player:GetPosY(), Player:GetPosZ() + 5, mtSheep, false)
	return true
end

function ApplyZombieEffects(Monster)
	Monster:AddEntityEffect(12, 6000, 0)
end