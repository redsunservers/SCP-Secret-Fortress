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
	//Bosses_EntityCreated(entity, classname);

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
			Call_PushCell(damagecustom);
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
			Call_PushCell(damagecustom);
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
	Randomizer_UpdateArms(client, weapon);
	return Plugin_Continue;
}

static void ClientWeaponEquipPost(int client, int weapon)
{
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
		Randomizer_UpdateArms(client);

		if(Bosses_StartFunctionClient(client, "WeaponSwitch"))
		{
			Call_PushCell(client);
			Call_Finish();
		}
	}
}

enum struct SoundData
{
	int clients[MAXPLAYERS];
	int numClients;
	char sample[PLATFORM_MAX_PATH];
	int entity;
	int channel;
	float volume;
	int level;
	int pitch;
	int flags;
}

static SoundData SoundOverride;

void EmitSoundEx(const int[] clients, int numClients,
		const char[] sample,
		int entity = SOUND_FROM_PLAYER,
		int channel = SNDCHAN_AUTO,
		int level = SNDLEVEL_NORMAL,
		int flags = SND_NOFLAGS,
		float volume = SNDVOL_NORMAL,
		int pitch = SNDPITCH_NORMAL,
		int speakerentity = -1,
		const float origin[3] = NULL_VECTOR,
		float soundtime = 0.0,
		int dsp = 0)
{
	// What's going on? We use VScript to use parameters such as DSP as SM doesn't have it
	// But we can't VScript requires bad hacks for setting who can hear the sound
	// So we partially use VScript for special effects, sound hook it, and add the rest of our settings
	// Also SetVariantString is limited to 128 characters shh...

	for(int b; b < numClients && b < sizeof(SoundOverride); b++)
	{
		SoundOverride.clients[b] = clients[b];
	}
	SoundOverride.numClients = numClients;
	strcopy(SoundOverride.sample, sizeof(SoundOverride.sample), sample);
	SoundOverride.entity = entity;
	SoundOverride.channel = channel;
	SoundOverride.level = level;
	SoundOverride.flags = flags;
	SoundOverride.volume = volume;
	SoundOverride.pitch = pitch;

	char buffer[128];
	int size = strcopy(buffer, sizeof(buffer), "EmitSoundEx({sound_name=\"vo/null.mp3\"");
	
	if(dsp != 0)
		size += Format(buffer[size], sizeof(buffer) - size, ",special_dsp=%d", dsp);
	
	if(!IsNullVector(origin))
		size += Format(buffer[size], sizeof(buffer) - size, ",origin=Vector(%f,%f,%f)", origin[0], origin[1], origin[2]);
	
	if(soundtime < 0.0)
		size += Format(buffer[size], sizeof(buffer) - size, ",delay=%f", soundtime);
	
	if(soundtime > 0.0)
		size += Format(buffer[size], sizeof(buffer) - size, ",sound_time=%f", soundtime);
	
	if(speakerentity != -1)
		size += Format(buffer[size], sizeof(buffer) - size, ",speaker_entity=EntIndexToHScript(%d)", speakerentity);
	
	strcopy(buffer[size], sizeof(buffer) - size, "});");

	SetVariantString(buffer);
	AcceptEntityInput(0, "RunScriptCode");
}

stock void EmitSoundToClientEx(int client,
		const char[] sample,
		int entity = SOUND_FROM_PLAYER,
		int channel = SNDCHAN_AUTO,
		int level = SNDLEVEL_NORMAL,
		int flags = SND_NOFLAGS,
		float volume = SNDVOL_NORMAL,
		int pitch = SNDPITCH_NORMAL,
		int speakerentity = -1,
		const float origin[3] = NULL_VECTOR,
		float soundtime = 0.0,
		int dsp = 0)
{
	int clients[1];
	clients[0] = client;
	/* Save some work for SDKTools and remove SOUND_FROM_PLAYER references */
	entity = (entity == SOUND_FROM_PLAYER) ? client : entity;
	EmitSoundEx(clients, 1, sample, entity, channel,
		level, flags, volume, pitch, speakerentity,
		origin, soundtime, dsp);
}

stock void EmitSoundToAllEx(const char[] sample,
		int entity = SOUND_FROM_PLAYER,
		int channel = SNDCHAN_AUTO,
		int level = SNDLEVEL_NORMAL,
		int flags = SND_NOFLAGS,
		float volume = SNDVOL_NORMAL,
		int pitch = SNDPITCH_NORMAL,
		int speakerentity = -1,
		const float origin[3] = NULL_VECTOR,
		float soundtime = 0.0,
		int dsp = 0)
{
	int[] clients = new int[MaxClients];
	int total = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			clients[total++] = i;
	}

	if(total)
	{
		EmitSoundEx(clients, total, sample, entity, channel,
			level, flags, volume, pitch, speakerentity,
			origin, soundtime, dsp);
	}
}

static Action SDKHook_NormalSHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(SoundOverride.numClients)
	{
		for(int i; i < SoundOverride.numClients; i++)
		{
			clients[i] = SoundOverride.clients[i];
		}
		numClients = SoundOverride.numClients;
		strcopy(sample, sizeof(sample), SoundOverride.sample);
		entity = SoundOverride.entity;
		channel = SoundOverride.channel;
		volume = SoundOverride.volume;
		level = SoundOverride.level;
		pitch = SoundOverride.pitch;
		flags = SoundOverride.flags;

		SoundOverride.numClients = 0;
		return Plugin_Changed;
	}

	static bool InSoundHook;

	if(!InSoundHook && entity > 0 && entity <= MaxClients)
	{
		int client = entity;
		if((channel == SNDCHAN_VOICE || (channel == SNDCHAN_STATIC && !StrContains(sample, "vo", false))))
		{
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
		else
		{
			InSoundHook = true;

			Action action;
			if(Items_StartFunctionClient(entity, "SoundHook"))
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

	static const int zero[MAXPLAYERS+1] = {0, ...};
	SetEntDataArray(entity, offsetAlive, alive, MaxClients + 1);
	SetEntDataArray(entity, offsetTeam, team, MaxClients + 1);
	SetEntDataArray(entity, offsetScore, zero, MaxClients + 1);
	SetEntDataArray(entity, offsetClass, zero, MaxClients + 1);
	SetEntDataArray(entity, offsetClassKilled, zero, MaxClients + 1);
}
