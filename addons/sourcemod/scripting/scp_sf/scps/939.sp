static const int HealthMax = 3300;	// Max standard health
static const int HealthExtra = 1100;	// Max regenerable health

static const float SpeedExtra = 50.0;	// Extra speed while low health
static const float GlowRange = 1200.0;	// Max outline range

static int Health[MAXTF2PLAYERS];

public bool SCP939_Create(int client)
{
	Classes_VipSpawn(client);

	Health[client] = HealthMax;
	
	int account = GetSteamAccountID(client, false);

	int weapon = SpawnWeapon(client, "tf_weapon_knife", 461, 70, 13, "2 ; 1.625 ; 15 ; 0 ; 252 ; 0.3 ; 412 ; 0.8 ; 4328 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 10);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	weapon = SpawnWeapon(client, "tf_weapon_pda_spy", 27, 70, 13, "", false);
	if(weapon > MaxClients)
	{
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(250, 374))); // Sharp
		TF2Attrib_SetByDefIndex(weapon, 292, view_as<float>(64));
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
	}
	return false;
}

public void SCP939_OnButton(int client, int button)
{
	Client[client].WeaponClass = TFClass_Spy;

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		Client[client].CurrentClass = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
		if(Client[client].CurrentClass != TFClass_Unknown)
			return;
	}

	Client[client].CurrentClass = TFClass_Spy;
}

public void SCP939_OnMaxHealth(int client, int &health)
{
	health = Health[client] + HealthExtra;

	int current = GetClientHealth(client);
	if(current > health)
	{
		SetEntityHealth(client, health);
	}
	else if(current < Health[client]-HealthExtra)
	{
		Health[client] = current+HealthExtra;
	}
}

public void SCP939_OnSpeed(int client, float &speed)
{
	speed += (1.0-(Health[client]/HealthMax))*SpeedExtra;
}

public Action SCP939_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Client[victim].IdleAt < GetGameTime())
	{
		damage = 60.0;
		damagetype &= ~DMG_CRIT;
		Client[victim].HudIn = GetGameTime()+6.0;
		return Plugin_Changed;
	}

	if(damagecustom!=TF_CUSTOM_BACKSTAB || damage<108)
	{
		Client[victim].HudIn = GetGameTime()+6.0;
		return Plugin_Continue;
	}

	damage = 65.0;
	damagetype &= ~DMG_CRIT;
	Client[victim].HudIn = GetGameTime()+13.0;
	return Plugin_Changed;
}

public Action SCP939_OnTakeDamage(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	SDKCall_SetSpeed(client);

	if(!(damagetype & DMG_FALL))
		return Plugin_Continue;

	damage *= 0.015;
	return Plugin_Changed;
}

public bool SCP939_OnSeePlayer(int client, int victim)
{
	return (IsFriendly(Client[client].Class, Client[victim].Class) || Client[victim].IdleAt>GetGameTime());
}

public bool SCP939_OnGlowPlayer(int client, int victim)
{
	float time = Client[victim].IdleAt-GetGameTime();
	if(time > 0)
	{
		static float clientPos[3], targetPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", targetPos);
		if(GetVectorDistance(clientPos, targetPos) < (GlowRange*time/2.5))
			return true;
	}
	return false;
}