#pragma semicolon 1
#pragma newdecls required

enum struct RawHooks
{
	int Ref;
	int Pre;
	int Post;
}

static DynamicHook ForceRespawn;
static DynamicHook RoundRespawn;
static DynamicHook HookItemIterateAttribute;

static ArrayList RawEntityHooks;
static Address CLagCompensationManager;
static int IterateAttributesOffset;
static int EconItemOffset;
static int StudioHdrOffset;

static int ForceRespawnPreHook[MAXPLAYERS+1];
static int ForceRespawnPostHook[MAXPLAYERS+1];

void DHooks_PluginStart()
{
	GameData gamedata = new GameData("scp_sf");
	
	CreateDetour(gamedata, "CBaseAnimating::GetBoneCache", GetBoneCachePre);
	CreateDetour(gamedata, "CLagCompensationManager::StartLagCompensation", _, StartLagCompensationPost);
	CreateDetour(gamedata, "CTFPlayer::DoAnimationEvent", DoAnimationEventPre);
	CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DropAmmoPackPre);
	CreateDetour(gamedata, "CTFPlayer::GetMaxAmmo", GetMaxAmmoPre);
	CreateDetour(gamedata, "CTFPlayer::RegenThink", RegenThinkPre, RegenThinkPost);
	CreateDetour(gamedata, "CTFPlayer::Taunt", TauntPre, TauntPost);
	
	ForceRespawn = CreateHook(gamedata, "CBasePlayer::ForceRespawn");
	RoundRespawn = CreateHook(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
	HookItemIterateAttribute = CreateHook(gamedata, "CEconItemView::IterateAttributes");

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
		ForceRespawnPostHook[client] = ForceRespawn.HookEntity(Hook_Post, client, ForceRespawnPost);
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
		raw.Pre = HookItemIterateAttribute.HookRaw(Hook_Pre, address, IterateAttributesPre);
		raw.Post = HookItemIterateAttribute.HookRaw(Hook_Post, address, IterateAttributesPost);
		
		RawEntityHooks.PushArray(raw);
	}
}

void DHooks_PluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			DHooks_UnhookClient(client);
	}
}

static void DHooks_UnhookClient(int client)
{
	if(ForceRespawn)
	{
		DynamicHook.RemoveHook(ForceRespawnPreHook[client]);
		DynamicHook.RemoveHook(ForceRespawnPostHook[client]);
	}
}

Address DHooks_GetLagCompensationManager()
{
	return CLagCompensationManager;
}

static MRESReturn CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
/*
	switch(Forward_OnPickupDroppedWeapon(client, param.Get(1)))
	{
		case Plugin_Continue:
		{
			if(Client(client).IsBoss || Client(client).Minion)
			{
				ret.Value = false;
				return MRES_Supercede;
			}
		}
		case Plugin_Handled:
		{
			ret.Value = true;
			return MRES_Supercede;
		}
		case Plugin_Stop:
		{
			ret.Value = false;
			return MRES_Supercede;
		}
	}
	*/
	return MRES_Ignored;
}

static MRESReturn DoAnimationEventPre(int client, DHookParam param)
{
	/*
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
*/
	return MRES_Ignored;
}

static MRESReturn DropAmmoPackPre(int client, DHookParam param)
{
	//return (Client(client).Minion || Client(client).IsBoss) ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn ForceRespawnPre(int client)
{/*
	PrefClass = 0;
	if(Client(client).IsBoss)
	{
		int class;
		Client(client).Cfg.GetInt("class", class);
		if(class)
		{
			PrefClass = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
		}
	}
*/
	return MRES_Ignored;
}

static MRESReturn ForceRespawnPost(int client)
{
	//if(PrefClass)
	//	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", PrefClass);
	
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

static MRESReturn RegenThinkPre(int client, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class) && class.Regen)
	{
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		TF2_SetPlayerClass(client, TFClass_Unknown, _, false);
	}
	return MRES_Ignored;
}

static MRESReturn RegenThinkPost(int client, DHookParam param)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class) && class.Regen)
	{
		TF2_SetPlayerClass(client, class.Class, _, false);
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
	}
	return MRES_Ignored;
}

static MRESReturn RoundRespawnPre()
{
	Music_RoundRespawn();
	Gamemode_RoundRespawn();
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
	if(Client(client).Class < 0 || TF2_IsPlayerInCondition(client, TFCond_Disguising) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		return MRES_Supercede;

	// Player wants to taunt, set class to whoever can actually taunt with active weapon
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon > MaxClients)
	{
		TFClassType class = TF2_GetWeaponClass(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(class != TFClass_Unknown)
			TF2_SetPlayerClass(client, class, false, false);
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