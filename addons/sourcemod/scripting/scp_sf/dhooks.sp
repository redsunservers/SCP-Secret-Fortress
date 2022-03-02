static DynamicDetour AllowedToHealTarget;
static DynamicHook RoundRespawn;
static DynamicHook ShouldCollide;
static DynamicHook ForceRespawn;
static DynamicHook WantsLagCompensationOnEntity;
static int ShouldCollidePreHook[MAXTF2PLAYERS];
static int ForceRespawnPreHook[MAXTF2PLAYERS];
static int ForceRespawnPostHook[MAXTF2PLAYERS];
static int WantsLagCompensationOnEntityPreHook[MAXTF2PLAYERS];
static int WantsLagCompensationOnEntityPostHook[MAXTF2PLAYERS];
static int CalculateSpeedClient;
static int ClientTeam[MAXTF2PLAYERS];

int StudioHdrOffset;

void DHook_Setup(GameData gamedata)
{
	DHook_CreateDetour(gamedata, "CBaseEntity::InSameTeam", DHook_InSameTeamPre);
	DHook_CreateDetour(gamedata, "CBaseAnimating::GetBoneCache", DHook_GetBoneCache);	
	DHook_CreateDetour(gamedata, "CTFGameMovement::ProcessMovement", DHook_ProcessMovementPre);
	DHook_CreateDetour(gamedata, "CTFPlayer::CanPickupDroppedWeapon", DHook_CanPickupDroppedWeaponPre);
	DHook_CreateDetour(gamedata, "CTFPlayer::DoAnimationEvent", DHook_DoAnimationEventPre);
	DHook_CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DHook_DropAmmoPackPre);
	DHook_CreateDetour(gamedata, "CTFPlayer::GetMaxAmmo", DHook_GetMaxAmmoPre);
	DHook_CreateDetour(gamedata, "CTFPlayer::RegenThink", DHook_RegenThinkPre, DHook_RegenThinkPost);
	DHook_CreateDetour(gamedata, "CTFPlayer::Taunt", DHook_TauntPre, DHook_TauntPost);
	DHook_CreateDetour(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed", DHook_CalculateMaxSpeedPre, DHook_CalculateMaxSpeedPost);

	// TODO: DHook_CreateDetour version of this
	AllowedToHealTarget = new DynamicDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(AllowedToHealTarget)
	{
		if(AllowedToHealTarget.SetFromConf(gamedata, SDKConf_Signature, "CWeaponMedigun::AllowedToHealTarget"))
		{
			AllowedToHealTarget.AddParam(HookParamType_CBaseEntity);
			if(!AllowedToHealTarget.Enable(Hook_Pre, DHook_AllowedToHealTarget))
				LogError("[Gamedata] Failed to detour CWeaponMedigun::AllowedToHealTarget");
		}
		else
		{
			LogError("[Gamedata] Could not find CWeaponMedigun::AllowedToHealTarget");
		}
	}
	else
	{
		LogError("[Gamedata] Could not find CWeaponMedigun::AllowedToHealTarget");
	}

	RoundRespawn = DynamicHook.FromConf(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
	if(!RoundRespawn)
		LogError("[Gamedata] Could not find CTeamplayRoundBasedRules::RoundRespawn");
	
	ShouldCollide = DynamicHook.FromConf(gamedata, "CBaseEntity::ShouldCollide");
	if(!ShouldCollide)
		LogError("[Gamedata] Could not find CBaseEntity::ShouldCollide");
	
	ForceRespawn = DynamicHook.FromConf(gamedata, "CBasePlayer::ForceRespawn");
	if(!ForceRespawn)
		LogError("[Gamedata] Could not find CBasePlayer::ForceRespawn");
	
	WantsLagCompensationOnEntity = DynamicHook.FromConf(gamedata, "CBasePlayer::WantsLagCompensationOnEntity");
	if(!WantsLagCompensationOnEntity)
		LogError("[Gamedata] Could not find CBasePlayer::WantsLagCompensationOnEntity");

	StudioHdrOffset = GameConfGetOffset(gamedata, "CBaseAnimating::m_pStudioHdr");
	if (StudioHdrOffset == -1)
		LogError("[Gamedata] Failed to get offset for CBaseAnimating::m_pStudioHdr");		
}

static void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback!=INVALID_FUNCTION && !DHookEnableDetour(detour, false, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback!=INVALID_FUNCTION && !DHookEnableDetour(detour, true, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);

		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

void DHook_HookClient(int client)
{
	if(ShouldCollide)
	{
		ShouldCollidePreHook[client] = ShouldCollide.HookEntity(Hook_Pre, client, DHook_ShouldCollidePre);
	}
	
	if(ForceRespawn)
	{
		ForceRespawnPreHook[client] = ForceRespawn.HookEntity(Hook_Pre, client, DHook_ForceRespawnPre);
		ForceRespawnPostHook[client] = ForceRespawn.HookEntity(Hook_Post, client, DHook_ForceRespawnPost);
	}
	
	if(WantsLagCompensationOnEntity)
	{
		WantsLagCompensationOnEntityPreHook[client] = WantsLagCompensationOnEntity.HookEntity(Hook_Pre, client, DHook_WantsLagCompensationOnEntityPre);
		WantsLagCompensationOnEntityPostHook[client] = WantsLagCompensationOnEntity.HookEntity(Hook_Post, client, DHook_WantsLagCompensationOnEntityPost);
	}
}

void DHook_UnhookClient(int client)
{
	DynamicHook.RemoveHook(ShouldCollidePreHook[client]);
	DynamicHook.RemoveHook(ForceRespawnPreHook[client]);
	DynamicHook.RemoveHook(ForceRespawnPostHook[client]);
	DynamicHook.RemoveHook(WantsLagCompensationOnEntityPreHook[client]);
	DynamicHook.RemoveHook(WantsLagCompensationOnEntityPostHook[client]);
}

void DHook_MapStart()
{
	if(RoundRespawn)
		RoundRespawn.HookGamerules(Hook_Pre, DHook_RoundRespawn);
}

public MRESReturn DHook_RoundRespawn()
{
	if(Enabled || GameRules_GetProp("m_bInWaitingForPlayers"))
		return;

	Enabled = Gamemode_RoundStart();
}

public MRESReturn DHook_AllowedToHealTarget(int weapon, DHookReturn ret, DHookParam param)
{
	if(weapon==-1 || param.IsNull(1))
		return MRES_Ignored;

	//int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	int target = param.Get(1);
	if(!IsValidClient(target) || !IsPlayerAlive(target))
		return MRES_Ignored;

	ret.Value = false;
	return MRES_ChangedOverride;
}

public MRESReturn DHook_ShouldCollidePre(int client, DHookReturn ret, DHookParam param)
{
	int collisiongroup = param.Get(1);
	if(collisiongroup == COLLISION_GROUP_PLAYER_MOVEMENT)
	{
		ret.Value = false;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DHook_ForceRespawnPre(int client)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class))
	{
		Client[client].Class = 0;
		Classes_GetByIndex(0, class);
	}

	if(class.OnCanSpawn != INVALID_FUNCTION)
	{
		bool result = true;
		Call_StartFunction(null, class.OnCanSpawn);
		Call_PushCell(client);
		Call_Finish(result);
		if(!result)
			return MRES_Supercede;
	}

	if(!StrContains(class.Name, "mtf"))
	{
		GiveAchievement(Achievement_MTFSpawn, client);
	}
	else if(!StrContains(class.Name, "chaos"))
	{
		GiveAchievement(Achievement_ChaosSpawn, client);
	}

	TFClassType playerClass = class.Class;
	if(playerClass == TFClass_Unknown)
	{
		playerClass = Client[client].PrefClass;
		if(playerClass == TFClass_Unknown)
			playerClass = view_as<TFClassType>(GetRandomInt(1, 9));
	}

	ChangeClientTeamEx(client, class.Team>TFTeam_Spectator ? class.Team : class.Team+view_as<TFTeam>(2));
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", playerClass);
	Client[client].CurrentClass = playerClass;
	Client[client].WeaponClass = TFClass_Unknown;
	Client[client].Floor = class.Floor;
	return MRES_Ignored;
}

public MRESReturn DHook_ForceRespawnPost(int client)
{
	if(Client[client].PrefClass != TFClass_Unknown)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", Client[client].PrefClass);
}

public MRESReturn DHook_WantsLagCompensationOnEntityPre(int client, DHookReturn ret, DHookParam param)
{
	int player = param.Get(1);
	
	ClientTeam[client] = GetClientTeam(client);
	ClientTeam[player] = GetClientTeam(player);
	
	ChangeClientTeamEx(client, TFTeam_Red);
	ChangeClientTeamEx(player, TFTeam_Blue);
}

public MRESReturn DHook_WantsLagCompensationOnEntityPost(int client, DHookReturn ret, DHookParam param)
{
	int player = param.Get(1);
	
	ChangeClientTeamEx(client, ClientTeam[client]);
	ChangeClientTeamEx(player, ClientTeam[player]);
	
	ret.Value = ret.Value || !IsFriendly(Client[client].Class, Client[player].Class);
	return MRES_Supercede;
}

public MRESReturn DHook_CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && !(Client[client].Disarmer && (class.Human || StrEqual(class.Name, "scp035", false))))
	{
		int entity = param.Get(1);
		Classes_OnPickup(client, entity);
	}

	ret.Value = false;
	return MRES_Supercede;
}

public MRESReturn DHook_DoAnimationEventPre(int client, DHookParam param)
{
	PlayerAnimEvent_t anim = param.Get(1);
	int data = param.Get(2);

	Action action = Classes_OnAnimation(client, anim, data);
	if(action >= Plugin_Handled)
		return MRES_Supercede;

	if(action == Plugin_Changed)
	{
		param.Set(1, anim);
		param.Set(2, data);
		return MRES_ChangedOverride;
	}

	return MRES_Ignored;
}

public MRESReturn DHook_DropAmmoPackPre(int client, DHookParam param)
{
	//TODO: Remove this hook, move to OnEntityCreated and OnPlayerDeath
	ClassEnum class;
	Classes_GetByIndex(Client[client].Class, class);
	
	if(!param.Get(2) && !IsSpec(client) && (!IsSCP(client) || StrEqual(class.Name, "scp035", false)))
		Items_DropAllItems(client);

	return MRES_Supercede;
}

public MRESReturn DHook_InSameTeamPre(int entity, DHookReturn ret, DHookParam param)
{
	bool result;
	if(!param.IsNull(1))
	{
		int ent1 = GetOwnerLoop(entity);
		int ent2 = GetOwnerLoop(param.Get(1));
		if(ent1 == ent2)
		{
			result = true;
		}
		else if(IsValidClient(ent1) && IsValidClient(ent2))
		{
			result = IsFriendly(Client[ent1].Class, Client[ent2].Class);
		}
	}

	ret.Value = result;
	return MRES_Supercede;
}

public MRESReturn DHook_GetBoneCache(int entity, DHookReturn ret)
{
	// Missing null check for parent studiohdr in CBaseAnimating::SetupBones 
	// causes crashes when attaching arms to viewmodel
	if (GetEntData(entity, StudioHdrOffset * 4) == 0)
	{
		ret.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

public MRESReturn DHook_ProcessMovementPre(DHookParam param)
{
	param.SetObjectVar(2, 60, ObjectValueType_Float, CvarSpeedMax.FloatValue);
	return MRES_ChangedHandled;
}

public MRESReturn DHook_CalculateMaxSpeedPre(Address address, DHookReturn ret)
{
	CalculateSpeedClient = SDKCall_GetBaseEntity(address);
}

public MRESReturn DHook_CalculateMaxSpeedPost(int clientwhen, DHookReturn ret)
{
	int client = CalculateSpeedClient;
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return MRES_Ignored;

	float speed = 300.0;
	if(Client[client].InvisFor != FAR_FUTURE)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
			return MRES_Ignored;

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
		{
			speed = class.Speed;
			Classes_OnSpeed(client, speed);
		}

		speed *= CvarSpeedMulti.FloatValue;
		if(Client[client].Sprinting)
			speed *= 1.15;

		if(TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
			speed *= 1.35;

		Items_Speed(client, speed);
	}

	ret.Value = speed;
	return MRES_Override;
}

public MRESReturn DHook_GetMaxAmmoPre(int client, DHookReturn ret, DHookParam param)
{
	int type = param.Get(1);
	int ammo = Classes_GetMaxAmmo(client, type);
	if(!ammo)
		return MRES_Ignored;

	Items_Ammo(client, type, ammo);

	ret.Value = ammo;
	return MRES_Supercede;
}

public MRESReturn DHook_RegenThinkPre(int client, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.Regen)
	{
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		TF2_SetPlayerClass(client, TFClass_Unknown, _, false);
	}
	return MRES_Ignored;
}

public MRESReturn DHook_RegenThinkPost(int client, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.Regen)
	{
		TF2_SetPlayerClass(client, class.Class, _, false);
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
	}
	return MRES_Ignored;
}

public MRESReturn DHook_TauntPre(int client)
{
	//Dont allow taunting if disguised or cloaked
	if(TF2_IsPlayerInCondition(client, TFCond_Disguising) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return MRES_Supercede;

	//Player wants to taunt, set class to whoever can actually taunt with active weapon
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon > MaxClients)
	{
		TFClassType class = TF2_GetDefaultClassFromItem(weapon);
		if(class != TFClass_Unknown)
			TF2_SetPlayerClass(client, class, false, false);
	}
	return MRES_Ignored;
}

public MRESReturn DHook_TauntPost(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
		TF2_SetPlayerClass(client, class.Class, false, false);
}