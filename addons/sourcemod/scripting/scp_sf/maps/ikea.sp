static float Triggered[MAXTF2PLAYERS];
static bool IsBackup;
static int IkeaIndex;

public void Ikea_RoundStart()
{
	IsBackup = false;

	for(int i; i<=MaxClients; i++)
	{
		Triggered[i] = 0.0;
	}
}

public bool Ikea_Condition(TFTeam &team)
{
	ClassEnum class;
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i) || IsSpec(i) || !Classes_GetByIndex(Client[i].Class, class))
			continue;

		if(class.Vip)
			return false;
	}

	int escape, total;
	Gamemode_GetValue("dtotal", total);
	if(Gamemode_GetValue("sescape", escape) && escape)
	{
		team = TFTeam_Blue;
	}
	else
	{
		team = TFTeam_Red;
	}

	float time = GetEngineTime()-RoundStartAt;

	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "%d:%02d", RoundToFloor(time/60.0), RoundToFloor(time)%60);
	SetHudTextParamsEx(-1.0, 0.3, 17.5, escape ? {255, 165, 0, 255} : {165, 0, 0, 255}, {255, 255, 255, 255}, 1, 2.0, 1.0, 1.0);
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		SetGlobalTransTarget(client);
		ShowSyncHudText(client, HudGame, "%t", escape ? "ikea_win" : "ikea_lose", escape, total, buffer);
	}
	return true;
}

public float Ikea_RespawnWave(ArrayList &list, ArrayList &players)
{
	int length = players.Length;
	if(length)
	{
		WaveEnum wave;
		if(Triggered[0] && !IsBackup && Gamemode_GetWave(1, wave))
		{
			list = Gamemode_MakeClassList(wave.Classes, length>wave.TicketsLeft ? wave.TicketsLeft : length);
			IsBackup = true;
		}
		else if(Gamemode_GetWave(0, wave))
		{
			list = Gamemode_MakeClassList(wave.Classes, length>wave.TicketsLeft ? wave.TicketsLeft : length);
		}
		else
		{
			EndRoundIn = 1.0;
			return FAR_FUTURE;
		}
	}

	if(Triggered[0])
	{
		Triggered[0] = 0.0;
	}
	else
	{
		Triggered[0] = 1.0;
		for(int client=1; client<=MaxClients; client++)
		{
			Triggered[client] = 1.0;
			if(IsClientInGame(client) && IsPlayerAlive(client) && Client[client].Class==IkeaIndex)
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				GiveAngerWeapon(client);
			}
		}
	}

	length = -1;
	while((length=FindEntityByClassname(length, "logic_relay")) != -1)
	{
		static char name[32];
		GetEntPropString(length, Prop_Data, "m_iName", name, sizeof(name));
		if(StrEqual(name, Triggered[0] ? "scp_time_night" : "scp_time_day", false))
		{
			AcceptEntityInput(length, "Trigger");
			break;
		}
	}

	float min, max;
	Gamemode_GetWaveTimes(min, max);
	return GetRandomFloat(min, max);
}

public void Ikea_Enable(int index)
{
	IkeaIndex = index;
}

public bool Ikea_Create(int client)
{
	if(Triggered[0])
	{
		Triggered[client] = 1.0;
		GiveAngerWeapon(client);
	}
	else
	{
		Triggered[client] = 0.0;
		GivePassiveWeapon(client);
	}
	return false;
}

public void Ikea_OnButton(int client, int button)
{
	if(!Triggered[0] && Triggered[client] && Triggered[client]<GetEngineTime())
	{
		Triggered[client] = 0.0;
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		GivePassiveWeapon(client);
	}
}

public void Ikea_OnDeath(int client, Event event)
{
	Client[client].Class = IkeaIndex;
}

public Action Ikea_OnTakeDamage(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker>0 && attacker<=MaxClients)
	{
		bool calm = !Triggered[client];

		Triggered[client] = GetEngineTime()+15.0;
		Triggered[attacker] = Triggered[client]+45.0;

		if(calm)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			GiveAngerWeapon(client);
		}
	}
	return Plugin_Continue;
}

public bool Ikea_OnGlowPlayer(int client, int victim)
{
	if(Triggered[0] || GetClientTeam(client)==GetClientTeam(victim))
		return true;

	float engineTime = GetEngineTime();
	if(Triggered[client] < engineTime)
		return false;

	return Triggered[victim]>engineTime;
}

public bool Ikea_OnSeePlayer(int client, int victim)
{
	if(Triggered[0] || GetClientTeam(client)==GetClientTeam(victim))
		return true;

	float engineTime = GetEngineTime();
	if(Triggered[client] < engineTime)
		return true;

	return Triggered[victim]>engineTime;
}

public void Ikea_OnSpeed(int client, float &speed)
{
	if(Triggered[0] || Triggered[client]>GetEngineTime())
		speed += 50.0;
}

static void GivePassiveWeapon(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_club", 954, 50, 13, "1 ; 0 ; 57 ; 10 ; 412 ; 2.6", 2);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 5);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

static void GiveAngerWeapon(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_club", 195, 1, 13, "1 ; 0.65 ; 28 ; 0.25 ; 57 ; 5 ; 206 ; 2", 2);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 15);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}