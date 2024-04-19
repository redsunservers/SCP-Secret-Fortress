#pragma semicolon 1
#pragma newdecls required

enum struct RawHooks
{
	int Ref;
	int Pre;
	int Post;
}

static DynamicHook ForceRespawn;
static DynamicHook ModifyOrAppendCriteria;
static DynamicHook ShouldCollide;
static DynamicHook ItemIterateAttribute;
static DynamicHook RoundRespawn;

static ArrayList RawEntityHooks;
static Address CLagCompensationManager;
static int IterateAttributesOffset;
static int EconItemOffset;
static int StudioHdrOffset;

static int ForceRespawnPreHook[MAXPLAYERS+1];
static int ModifyOrAppendCriteriaPostHook[MAXPLAYERS+1];
static int ShouldCollidePreHook[MAXPLAYERS+1];

void DHooks_PluginStart()
{
	GameData gamedata = new GameData("scp_sf");
	
	CreateDetour(gamedata, "CBaseAnimating::GetBoneCache", GetBoneCachePre);
	CreateDetour(gamedata, "CLagCompensationManager::StartLagCompensation", _, StartLagCompensationPost);
	CreateDetour(gamedata, "CTFPlayer::CanPickupDroppedWeapon", CanPickupDroppedWeaponPre);
	CreateDetour(gamedata, "CTFPlayer::DoAnimationEvent", DoAnimationEventPre);
	CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DropAmmoPackPre);
	CreateDetour(gamedata, "CTFPlayer::GetMaxAmmo", GetMaxAmmoPre);
	CreateDetour(gamedata, "CTFPlayer::RegenThink", RegenThinkPre, RegenThinkPost);
	CreateDetour(gamedata, "CTFPlayer::SpeakConceptIfAllowed", SpeakConceptIfAllowedPre, SpeakConceptIfAllowedPost);
	CreateDetour(gamedata, "CTFPlayer::Taunt", TauntPre, TauntPost);
	CreateDetour(gamedata, "PassServerEntityFilter", _, PassServerEntityFilterPost);
	
	ForceRespawn = CreateHook(gamedata, "CBasePlayer::ForceRespawn");
	ModifyOrAppendCriteria = CreateHook(gamedata, "CBaseEntity::ModifyOrAppendCriteria");
	ShouldCollide = CreateHook(gamedata, "CBaseEntity::ShouldCollide");
	ItemIterateAttribute = CreateHook(gamedata, "CEconItemView::IterateAttributes");
	RoundRespawn = CreateHook(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");

	StudioHdrOffset = CreateOffset(gamedata, "CBaseAnimating::m_pStudioHdr");

	EconItemOffset = FindSendPropInfo("CEconEntity", "m_Item");
	FindSendPropInfo("CEconEntity", "m_bOnlyIterateItemViewAttributes", _, _, IterateAttributesOffset);
	
	delete gamedata;
	
	RawEntityHooks = new ArrayList(sizeof(RawHooks));
}

static DynamicHook CreateHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if(!hook)
		LogError("[Gamedata] Could not find %s", name);
	
	return hook;
}

static void CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback != INVALID_FUNCTION && !detour.Enable(Hook_Pre, preCallback))
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback != INVALID_FUNCTION && !detour.Enable(Hook_Post, postCallback))
			LogError("[Gamedata] Failed to enable post detour: %s", name);
		
		delete detour;
	}
	else
	{
		LogError("[Gamedata] Could not find %s", name);
	}
}

void DHooks_MapStart()
{
	if(RoundRespawn)
	{
		RoundRespawn.HookGamerules(Hook_Pre, RoundRespawnPre);
	}
}

void DHooks_ClientPutInServer(int client)
{
	if(ForceRespawn)
	{
		ForceRespawnPreHook[client] = ForceRespawn.HookEntity(Hook_Pre, client, ForceRespawnPre);
	}

	if(ShouldCollide)
	{
		ShouldCollidePreHook[client] = ShouldCollide.HookEntity(Hook_Pre, client, ShouldCollidePre);
	}
	
	if(ModifyOrAppendCriteria)
	{
		ModifyOrAppendCriteriaPostHook[client] = ModifyOrAppendCriteria.HookEntity(Hook_Post, client, ModifyOrAppendCriteriaPost);
	}
}

void DHooks_EntityDestoryed()
{
	RequestFrame(EntityDestoryedFrame);
}

static void EntityDestoryedFrame()
{
	int length = RawEntityHooks.Length;
	if(length)
	{
		RawHooks raw;
		for(int i; i < length; i++)
		{
			RawEntityHooks.GetArray(i, raw);
			if(!IsValidEntity(raw.Ref))
			{
				if(raw.Pre != INVALID_HOOK_ID)
					DynamicHook.RemoveHook(raw.Pre);
				
				if(raw.Post != INVALID_HOOK_ID)
					DynamicHook.RemoveHook(raw.Post);
				
				RawEntityHooks.Erase(i--);
				length--;
			}
		}
	}
}

void DHooks_HookStripWeapon(int entity)
{
	if(EconItemOffset > 0 && IterateAttributesOffset > 0)
	{
		Address address = GetEntityAddress(entity) + view_as<Address>(EconItemOffset);
		
		RawHooks raw;
		
		raw.Ref = EntIndexToEntRef(entity);
		raw.Pre = ItemIterateAttribute.HookRaw(Hook_Pre, address, IterateAttributesPre);
		raw.Post = ItemIterateAttribute.HookRaw(Hook_Post, address, IterateAttributesPost);
		
		RawEntityHooks.PushArray(raw);
	}
}

void DHooks_PluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			UnhookClient(client);
	}
}

static void UnhookClient(int client)
{
	if(ForceRespawn)
		DynamicHook.RemoveHook(ForceRespawnPreHook[client]);

	if(ModifyOrAppendCriteria)
		DynamicHook.RemoveHook(ModifyOrAppendCriteriaPostHook[client]);

	if(ShouldCollide)
		DynamicHook.RemoveHook(ShouldCollidePreHook[client]);
}

Address DHooks_GetLagCompensationManager()
{
	return CLagCompensationManager;
}

static MRESReturn CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
	ret.Value = false;
	return MRES_Supercede;
}

static MRESReturn DoAnimationEventPre(int client, DHookParam param)
{
	int anim = param.Get(1);
	int data = param.Get(2);

	Action action = Classes_DoAnimationEvent(client, anim, data);
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

static MRESReturn DropAmmoPackPre(int client, DHookParam param)
{
	return MRES_Supercede;
}

static MRESReturn ForceRespawnPre(int client)
{
	if(Classes_ForceRespawn(client))
		return MRES_Supercede;
	
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class) && class.Class)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class.Class);

	Client(client).ResetByDeath();
	return MRES_Ignored;
}

static MRESReturn GetMaxAmmoPre(int client, DHookReturn ret, DHookParam param)
{
	int type = param.Get(1);
	int ammo = Classes_GetMaxAmmo(client, type);
	if(ammo < 0)
		return MRES_Ignored;

	ret.Value = ammo;
	return MRES_Supercede;
}

static MRESReturn GetBoneCachePre(int entity, DHookReturn ret)
{
	// Missing null check for parent studiohdr in CBaseAnimating::SetupBones 
	// causes crashes when attaching arms to viewmodel
	if(GetEntData(entity, StudioHdrOffset * 4) == 0)
	{
		ret.Value = 0;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

static MRESReturn IterateAttributesPre(Address address, DHookParam param)
{
	StoreToAddress(address + view_as<Address>(IterateAttributesOffset), true, NumberType_Int8);
	return MRES_Ignored;
}

static MRESReturn IterateAttributesPost(Address address, DHookParam param)
{
	StoreToAddress(address + view_as<Address>(IterateAttributesOffset), false, NumberType_Int8);
	return MRES_Ignored;
}

static MRESReturn ModifyOrAppendCriteriaPost(int client, DHookParam params)
{
	if(!IsClientInGame(client) || GetClientTeam(client) > TFTeam_Spectator || !TF2_IsPlayerInCondition(client, TFCond_Disguised))
		return MRES_Ignored;
	
	int criteriaSet = params.Get(1);
	
	if(SDKCalls_FindCriterionIndex(criteriaSet, "crosshair_enemy") == -1)
		return MRES_Ignored;
	
	// Prevent disguised SCP from calling people they may not be able to see out
	SDKCalls_RemoveCriteria(criteriaSet, "crosshair_on");
	SDKCalls_RemoveCriteria(criteriaSet, "crosshair_enemy");
	
	return MRES_Ignored;
}

static MRESReturn PassServerEntityFilterPost(DHookReturn ret, DHookParam param)
{
	if(param.IsNull(1) || param.IsNull(2))
	{
		return MRES_Ignored;
	}
	
	int touch_ent = param.Get(1);
	int pass_ent  = param.Get(2);
	
	if(!IsValidEntity(touch_ent) || !IsValidEntity(pass_ent))
	{
		return MRES_Ignored;
	}
	
	bool touch_is_player = touch_ent > 0 && touch_ent <= MaxClients && IsPlayerAlive(touch_ent);
	bool pass_is_player = pass_ent > 0 && pass_ent <= MaxClients && IsPlayerAlive(pass_ent);
	
	if((touch_is_player && pass_is_player) || (!touch_is_player && !pass_is_player))
	{
		return MRES_Ignored;
	}
	
	int entity = touch_is_player ? pass_ent : touch_ent;
	
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	if(strncmp(classname, "func_door", sizeof(classname)) != 0 && strncmp(classname, "func_movelinear", sizeof(classname)) != 0)
	{
		return MRES_Ignored;
	}
	
	int client = touch_is_player ? touch_ent : pass_ent;
	
	ret.Value = !Classes_DoorWalk(client, entity);
	return MRES_Supercede;
}

static MRESReturn RegenThinkPre(int client, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class))
	{
		if(class.Regen)
		{
			TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			TF2_SetPlayerClass(client, TFClass_Unknown, _, false);
		}
	}
	return MRES_Ignored;
}

static MRESReturn RegenThinkPost(int client, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class))
	{
		if(class.Regen && class.Class)
		{
			TF2_SetPlayerClass(client, class.Class, _, false);
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Unknown)
		{
			TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		}
	}
	return MRES_Ignored;
}

static MRESReturn RoundRespawnPre()
{
	Music_RoundRespawn();
	Gamemode_RoundRespawn();
	return MRES_Ignored;
}

static MRESReturn SpeakConceptIfAllowedPre(int client, DHookParam param)
{
	ClassEnum class;
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && Classes_GetByIndex(Client(target).Class, class) && class.Class)
		{
			TF2_SetPlayerClass(target, class.Class, _, false);
		}
	}
	return MRES_Ignored;
}

static MRESReturn SpeakConceptIfAllowedPost(int client, DHookParam param)
{
	ClassEnum class;
	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && Classes_GetByIndex(Client(target).Class, class) && Client(target).WeaponClass)
		{
			TF2_SetPlayerClass(target, Client(target).WeaponClass, _, false);
		}
	}
	return MRES_Ignored;
}

public MRESReturn ShouldCollidePre(int client, DHookReturn ret, DHookParam param)
{
	if(param.Get(1) == COLLISION_GROUP_PLAYER_MOVEMENT)
	{
		ret.Value = false;
		return MRES_Supercede;
	}

	return MRES_Ignored;
}

static MRESReturn StartLagCompensationPost(Address address)
{
	CLagCompensationManager = address;
	return MRES_Ignored;
}

static MRESReturn TauntPre(int client)
{
	// Dont allow taunting if disguised or cloaked
	if(TF2_IsPlayerInCondition(client, TFCond_Disguising) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return MRES_Supercede;

	// Player wants to taunt, set class to whoever can actually taunt with active weapon
	if(Classes_GetByIndex(Client(client).Class))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon > MaxClients)
		{
			TFClassType class = TF2_GetWeaponClass(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
			if(class != TFClass_Unknown)
				TF2_SetPlayerClass(client, class, false, false);
		}
	}
	return MRES_Ignored;
}

static MRESReturn TauntPost(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class))
		TF2_SetPlayerClass(client, class.Class, false, false);
	
	return MRES_Ignored;
}
