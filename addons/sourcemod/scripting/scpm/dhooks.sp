#pragma semicolon 1
#pragma newdecls required

static DynamicDetour StartLagCompensation;
static DynamicHook ForceRespawn;
static Address CLagCompensationManager;

static int ForceRespawnPreHook[MAXPLAYERS+1];
static int ForceRespawnPostHook[MAXPLAYERS+1];
static int PrefClass;

void DHook_PluginStart()
{
	GameData gamedata = new GameData("ff2");
	
	StartLagCompensation = CreateDetour(gamedata, "CLagCompensationManager::StartLagCompensation", _, DHook_StartLagCompensation, true);
	
	CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DHook_DropAmmoPackPre);

	ForceRespawn = CreateHook(gamedata, "CBasePlayer::ForceRespawn");
	
	delete gamedata;
}

static DynamicHook CreateHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if(!hook)
		LogError("[Gamedata] Could not find %s", name);
	
	return hook;
}

static DynamicDetour CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION, bool reference = false, bool error = true)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if(detour)
	{
		if(preCallback != INVALID_FUNCTION && !detour.Enable(Hook_Pre, preCallback) && error)
			LogError("[Gamedata] Failed to enable pre detour: %s", name);
		
		if(postCallback != INVALID_FUNCTION && !detour.Enable(Hook_Post, postCallback) && error)
			LogError("[Gamedata] Failed to enable post detour: %s", name);
		
		if(!reference)
			CloseHandle(detour);
	}
	else if(error)
	{
		LogError("[Gamedata] Could not find %s", name);
	}

	return detour;
}

void DHook_HookClient(int client)
{
	if(ForceRespawn)
	{
		ForceRespawnPreHook[client] = ForceRespawn.HookEntity(Hook_Pre, client, DHook_ForceRespawnPre);
		ForceRespawnPostHook[client] = ForceRespawn.HookEntity(Hook_Post, client, DHook_ForceRespawnPost);
	}
}

void DHook_PluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			DHook_UnhookClient(client);
	}
}

void DHook_UnhookClient(int client)
{
	if(ForceRespawn)
	{
		DynamicHook.RemoveHook(ForceRespawnPreHook[client]);
		DynamicHook.RemoveHook(ForceRespawnPostHook[client]);
	}
}

Address DHook_GetLagCompensationManager()
{
	return CLagCompensationManager;
}
/*
static MRESReturn DHook_CanPickupDroppedWeaponPre(int client, DHookReturn ret, DHookParam param)
{
	//int weapon = param.Get(1);
	return CanPickupDroppedWeapon(client, ret);
}

static MRESReturn DHook_CanPickupDroppedWeaponPreAlt(DHookReturn ret, DHookParam param)
{
	int client = param.Get(1);
	//int weapon = param.Get(2);
	return CanPickupDroppedWeapon(client, ret);
}

static MRESReturn CanPickupDroppedWeapon(int client, DHookReturn ret)
{
	ret.Value = !(Client(client).Minion || Client(client).IsBoss);
	return MRES_Supercede;
}
*/
static MRESReturn DHook_DropAmmoPackPre(int client, DHookParam param)
{
	return MRES_Supercede;
	//return (Client(client).Minion || Client(client).IsBoss) ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn DHook_ForceRespawnPre(int client)
{
	PrefClass = 0;
	if(Client(client).IsBoss)
	{
		int class;

		if(Bosses_StartFunctionClient(client, "TFClass"))
		{
			Call_PushCell(client);
			Call_Finish(class);
		}

		if(class)
		{
			PrefClass = GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass");
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);
		}
	}

	return MRES_Ignored;
}

static MRESReturn DHook_ForceRespawnPost(int client)
{
	if(PrefClass)
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", PrefClass);
	
	return MRES_Ignored;
}

static MRESReturn DHook_StartLagCompensation(Address address)
{
	CLagCompensationManager = address;
	RequestFrame(DisableStartLagCompensation);
	return MRES_Ignored;
}

static void DisableStartLagCompensation()
{
	if(StartLagCompensation)
	{
		StartLagCompensation.Disable(Hook_Post, DHook_StartLagCompensation);
		delete StartLagCompensation;
	}
}