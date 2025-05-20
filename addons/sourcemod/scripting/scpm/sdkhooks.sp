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

void SDKHook_LibraryAdded(const char[] name)
{
	if(!OTDLoaded && StrEqual(name, OTD_LIBRARY))
	{
		OTDLoaded = true;
		
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
				SDKUnhook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
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
				SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
		}
	}
}

void SDKHook_HookClient(int client)
{
	if(!OTDLoaded)
		SDKHook(client, SDKHook_OnTakeDamage, SDKHook_TakeDamage);
	
	SDKHook(client, SDKHook_SetTransmit, SDKHook_Transmit);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_healthkit") != -1 || StrContains(classname, "item_ammopack") != -1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_StartTouch, SDKHook_PickupTouch);
		SDKHook(entity, SDKHook_Touch, SDKHook_PickupTouch);
	}
	else
	{
		Weapons_EntityCreated(entity, classname);
	}
}

static Action SDKHook_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
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
					damage = 100.0;
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

static Action SDKHook_Transmit(int client, int target)
{
	if(client != target && target > 0 && target <= MaxClients)
	{
		if(Client(client).NoTransmitTo(target))
			return Plugin_Stop;
	}

	return Plugin_Continue;
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

static Action SDKHook_PickupTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients && (Client(client).IsBoss || Client(client).Minion))
		return Plugin_Handled;
	
	return Plugin_Continue;
}
