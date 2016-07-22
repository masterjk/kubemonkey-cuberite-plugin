
-- Plugin initialization
function Initialize(Plugin)
	Plugin:SetName("KubeMonkey")
	Plugin:SetVersion(1)

	UpdateQueue = NewUpdateQueue()

	Villagers = {}

	-- Set Up Event Handlers
	cPluginManager:AddHook(cPluginManager.HOOK_CHUNK_GENERATING, OnChunkGenerating);
	cPluginManager:AddHook(cPluginManager.HOOK_TICK, Tick);
	cPluginManager:AddHook(cPluginManager.HOOK_WEATHER_CHANGING, OnWeatherChanging);
	cPluginManager:AddHook(cPluginManager.HOOK_WORLD_STARTED, WorldStarted);
	cPluginManager:AddHook(cPluginManager.HOOK_KILLED, OnKilled);
	cPluginManager:AddHook(cPluginManager.HOOK_SPAWNED_MONSTER, OnSpawnedMonster)
	cPluginManager:AddHook(cPluginManager.HOOK_MONSTER_IDLE, OnMonsterIdle)
	
	-- User Command Handlers
	cPluginManager.BindCommand("/die", "*", HandleKillCommand, "kill player")
	cPluginManager.BindCommand("/vil", "*", HandleVillagerCommand, "spawn villager")
	cPluginManager.BindCommand("/zom", "*", HandleZombieCommand, "spawn zombie")
	cPluginManager.BindCommand("/creeper", "*", HandleCreeperCommand, "spawn creeper")
	cPluginManager.BindCommand("/pos", "*", HandlePosCommand, "what is my position?")

	-- HTTP EndPoints -- /{pluginName}/{endPoint}
	Plugin:AddWebTab("start", PodStartedHandler)
	Plugin:AddWebTab("stop", PodStoppedHandler)

	-- make all players admin
	cRankManager:SetDefaultRank("Admin")

	LOG("Initialized " .. Plugin:GetName() .. " v." .. Plugin:GetVersion())

	return true
end

-- ------------------------------------------------------------
-- EVENT HANDLERS
-- ------------------------------------------------------------

function OnChunkGenerating(World, ChunkX, ChunkZ, ChunkDesc)
	-- override the built-in chunk generator
	-- to have it generate empty chunks only
	ChunkDesc:SetUseDefaultBiomes(false)
	ChunkDesc:SetUseDefaultComposition(false)
	ChunkDesc:SetUseDefaultFinish(false)
	ChunkDesc:SetUseDefaultHeight(false)
	return true
end

function Tick(TimeDelta)
	UpdateQueue:update(MAX_BLOCK_UPDATE_PER_TICK)
end

function OnWeatherChanging(World, Weather)
	return true, wSunny
end

function WorldStarted(World)
	LOG("OnWorldStarted")
	y = GROUND_LEVEL
	for x = GROUND_MIN_X, GROUND_MAX_X
	do
		for z = GROUND_MIN_Z, GROUND_MAX_Z
		do
			setBlock(UpdateQueue, x, y, z, E_BLOCK_WOOL, E_META_WOOL_WHITE)
		end
	end	
end

function OnSpawnedMonster(World, Monster)
	if Monster:GetMobType() == E_META_SPAWN_EGG_VILLAGER
	then
		table.insert(Villagers, Monster)
		cRoot:Get():BroadcastChat("Spawned Villagers! Size: " .. table.getn(Villagers) .. "; Unique ID: " .. Monster:GetUniqueID());
	end
end

function OnKilled(Entity, TDI, DeathMessage)
	if Entity:IsMob()
	then
		for i, e in ipairs( Villagers ) do
			if e:GetUniqueID() == Entity:GetUniqueID() then
				table.remove( Villagers, i )
				LOG("Killed Villager #" .. Entity:GetUniqueID())
			end
		end
	end
end

function OnMonsterIdle(Monster)
	cRoot:Get():BroadcastChat("Villager Count: " .. #Villagers)
	if #Villagers > 0
	then
		local villager = Villagers[math.random(1, #Villagers)]
		if villager ~= nil
		then 
			Monster:SetTarget(tolua.cast(villager, "cPawn"))
			cRoot:Get():BroadcastChat("Monster: " .. Monster:GetUniqueID())
		end
	end
end

-- ------------------------------------------------------------
-- HTTP HANDLERS
-- ------------------------------------------------------------

function PodStartedHandler(Request)	
	LOG("Started Container")
	local SpawnX = cRoot:Get():GetDefaultWorld():GetSpawnX()
	local SpawnY = cRoot:Get():GetDefaultWorld():GetSpawnY()
	local SpawnZ = cRoot:Get():GetDefaultWorld():GetSpawnZ()
	
	containerId = Request.PostParams["containerId"]

	local entityId = cRoot:Get():GetDefaultWorld():SpawnMob(SpawnX, SpawnY, SpawnZ, mtVillager, false)
	cRoot:Get():GetDefaultWorld():DoWithEntityByID(entityId,
		function(Entity)
			Entity:SetCustomName(containerId);
		end
	)
end

function PodStoppedHandler(Request)	
	LOG("Stopped Container")
	containerId = Request.PostParams["containerId"]

	for i, e in ipairs( Villagers ) do
		if e:GetCustomName() == containerId
		then
			cRoot:Get():GetDefaultWorld():DoWithEntityByID(e:GetUniqueID(),
			function(Entity)
				Entity:TakeDamage(dtInVoid, nil, 1000, 1000, 0)
			end
			)
		end
	end

end

