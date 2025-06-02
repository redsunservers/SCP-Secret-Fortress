#tryinclude <tf_ontakedamage>

#pragma semicolon 1
#pragma newdecls required

#define OTD_LIBRARY		"tf_ontakedamage"

#if !defined __tf_ontakedamage_included
enum CritType
{
	CritType_None = 0,
	CritType_MiniCrit,
	CritType_Crit
};
#endif

static bool OTDLoaded;

void SDKHook_PluginStart()
{
	AddNormalSoundHook(SDKHook_NormalSHook);
	
	OTDLoaded = LibraryExists(OTD_LIBRARY);
}

void SDKHook_MapStart()
{
	int entity = FindEntityByClassname(-1, "tf_player_manager");
	if(entity != -1)
		SDKHook(entity, SDKHook_ThinkPost, PlayerManagerThink);
}

void SDKHook_LibraryAdded(const char[] name)
{
	if(!OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = true;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKUnhook(client, SDKHook_OnTakeDamage, ClientTakeDamage);
		}
	}
}

void SDKHook_LibraryRemoved(const char[] name)
{
	if(OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = false;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKHook(client, SDKHook_OnTakeDamage, ClientTakeDamage);
		}
	}
}

void SDKHook_HookClient(int client)
{
	if(!OTDLoaded)
		SDKHook(client, SDKHook_OnTakeDamage, ClientTakeDamage);
	
	SDKHook(client, SDKHook_SetTransmit, ClientTransmit);
	SDKHook(client, SDKHook_WeaponEquip, ClientWeaponEquipPre);
	SDKHook(client, SDKHook_WeaponEquipPost, ClientWeaponEquipPost);
	SDKHook(client, SDKHook_WeaponSwitchPost, ClientWeaponSwitch);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_healthkit") != -1 || StrContains(classname, "item_ammopack") != -1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_StartTouch, PickupTouch);
		SDKHook(entity, SDKHook_Touch, PickupTouch);
	}
	else
	{
		Weapons_EntityCreated(entity, classname);
	}
}

static Action ClientTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	CritType crit = (damagetype & DMG_CRIT) ? CritType_Crit : CritType_None;
	return TF2_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, crit);
}

public Action TF2_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(Client(victim).IsBoss)
	{
		if(!attacker)
		{
			if(damagetype & DMG_FALL)
			{
				damage = 0.0;
				return Plugin_Handled;
			}
		}
		
		bool changed;
		if(attacker > 0 && attacker <= MaxClients)
		{
			switch(damagecustom)
			{
				case TF_CUSTOM_BACKSTAB:
				{
					damage = 150.0;
					damagetype |= DMG_PREVENT_PHYSICS_FORCE|DMG_CRIT;
					critType = CritType_Crit;
					changed = true;
				}
			}
		}

		Action action;
		if(Bosses_StartFunctionClient(victim, "TakeDamage"))
		{
			Call_PushCell(victim);
			Call_PushCellRef(attacker);
			Call_PushCellRef(inflictor);
			Call_PushCellRef(damage);
			Call_PushCellRef(damagetype);
			Call_PushCellRef(weapon);
			Call_PushArrayEx(damageForce, sizeof(damageForce), SM_PARAM_COPYBACK);
			Call_PushArrayEx(damagePosition, sizeof(damagePosition), SM_PARAM_COPYBACK);
			Call_PushCellRef(damagecustom);
			Call_PushCellRef(critType);
			Call_Finish(action);
		}

		if(action >= Plugin_Handled)
			return action;

		if(action < Plugin_Changed && changed)
			action = Plugin_Changed;

		return action;
	}
	else if(attacker > 0 && attacker <= MaxClients && (Client(attacker).IsBoss || Client(attacker).Minion))
	{
		Action action;
		if(Bosses_StartFunctionClient(attacker, "DealDamage"))
		{
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushCellRef(inflictor);
			Call_PushCellRef(damage);
			Call_PushCellRef(damagetype);
			Call_PushCellRef(weapon);
			Call_PushArrayEx(damageForce, sizeof(damageForce), SM_PARAM_COPYBACK);
			Call_PushArrayEx(damagePosition, sizeof(damagePosition), SM_PARAM_COPYBACK);
			Call_PushCellRef(damagecustom);
			Call_PushCellRef(critType);
			Call_Finish(action);
		}

		return action;
	}
	return Plugin_Continue;
}

static Action ClientTransmit(int client, int target)
{
	if(client != target && target > 0 && target <= MaxClients)
	{
		if(Client(client).NoTransmitTo(target))
			return Plugin_Stop;
	}

	return Plugin_Continue;
}

static Action ClientWeaponEquipPre(int client, int weapon)
{
	if(!Client(client).NoViewModel)
		Randomizer_UpdateArms(client, weapon);
	
	return Plugin_Continue;
}

static void ClientWeaponEquipPost(int client, int weapon)
{
	if(!Client(client).NoViewModel)
		Randomizer_UpdateArms(client);
}

static void ClientWeaponSwitch(int client, int weapon)
{
	RequestFrame(ClientWeaponSwitchFrame, GetClientUserId(client));
}

static void ClientWeaponSwitchFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		if(!Client(client).NoViewModel)
			Randomizer_UpdateArms(client);

		if(Bosses_StartFunctionClient(client, "WeaponSwitch"))
		{
			Call_PushCell(client);
			Call_Finish();
		}
	}
}

static Action SDKHook_NormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	static bool InSoundHook;

	if(!InSoundHook && entity > 0 && entity <= MaxClients && (channel == SNDCHAN_VOICE || (channel == SNDCHAN_STATIC && !StrContains(sample, "vo", false))))
	{
		int client = entity;
		if(TF2_IsPlayerInCondition(entity, TFCond_Disguised))
		{
			for(int i; i < numClients; i++)
			{
				if(clients[i] == entity)	// Get the sound from the Spy/enemies to avoid teammates hearing it
				{
					client = GetEntPropEnt(entity, Prop_Send, "m_hDisguiseTarget");
					if(client == -1 || view_as<TFClassType>(GetEntProp(entity, Prop_Send, "m_nDisguiseClass")) != TF2_GetPlayerClass(client))
						client = entity;
					
					break;
				}
			}
		}
		
		if(Client(client).IsBoss)
		{
			InSoundHook = true;

			Action action;
			if(Bosses_StartFunctionClient(client, "SoundHook"))
			{
				Call_PushCell(client);
				Call_PushArrayEx(clients, sizeof(clients), SM_PARAM_COPYBACK);
				Call_PushCellRef(numClients);
				Call_PushStringEx(sample, sizeof(sample), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(entity);
				Call_PushCellRef(channel);
				Call_PushCellRef(volume);
				Call_PushCellRef(level);
				Call_PushCellRef(pitch);
				Call_PushCellRef(flags);
				Call_PushStringEx(soundEntry, sizeof(soundEntry), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(seed);
				Call_Finish(action);
			}
			
			InSoundHook = false;
			return action;
		}
	}
	
	return Plugin_Continue;
}

static Action PickupTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients && (Client(client).IsBoss || Client(client).Minion))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

static void PlayerManagerThink(int entity)
{
	if(!RoundActive())
		return;
	
	static int offsetAlive = -1;
	if(offsetAlive == -1) 
		offsetAlive = FindSendPropInfo("CTFPlayerResource", "m_bAlive");

	static int offsetTeam = -1;
	if(offsetTeam == -1) 
		offsetTeam = FindSendPropInfo("CTFPlayerResource", "m_iTeam");

	static int offsetScore = -1;
	if(offsetScore == -1) 
		offsetScore = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");

	static int offsetClass = -1;
	if(offsetClass == -1) 
		offsetClass = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClass");

	static int offsetClassKilled = -1;
	if(offsetClassKilled == -1) 
		offsetClassKilled = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClassWhenKilled");

	bool[] alive = new bool[MaxClients+1];
	int[] team = new int[MaxClients+1];

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) > TFTeam_Spectator)
			{
				team[client] = (client % 2) ? TFTeam_Bosses : TFTeam_Humans;
				alive[client] = true;
			}
			else
			{
				team[client] = TFTeam_Spectator;
				alive[client] = false;
			}
		}
	}

	static const int zero[MAXPLAYERS+1];
	SetEntDataArray(entity, offsetAlive, alive, MaxClients + 1, 1);
	SetEntDataArray(entity, offsetTeam, team, MaxClients + 1);
	SetEntDataArray(entity, offsetScore, zero, MaxClients + 1);
	SetEntDataArray(entity, offsetClass, zero, MaxClients + 1);
	SetEntDataArray(entity, offsetClassKilled, zero, MaxClients + 1);
}
