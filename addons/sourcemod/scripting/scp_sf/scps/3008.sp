//static const char Name[] = "3008";
//static const char Model[] = "";
static const int Health = 500;
static const float Speed = 300.0;

void SCP3008_Enable()
{
	Gamemode = Gamemode_Ikea;
}

void SCP3008_Create(int client)
{
	Client[client].Extra1 = Health;
	Client[client].Extra2 = SciEscaped;
	Client[client].Floor = Floor_Light;

	Client[client].OnGlowPlayer = SCP3008_OnGlowPlayer;
	Client[client].OnKeycard = Items_KeycardScp;
	Client[client].OnMaxHealth = SCP3008_OnMaxHealth;
	Client[client].OnSeePlayer = SCP3008_OnSeePlayer;
	Client[client].OnSpeed = SCP3008_OnSpeed;
	Client[client].OnTakeDamage = SCP3008_OnTakeDamage;

	if(SciEscaped)
	{
		SCP3008_WeaponFists(client);
	}
	else
	{
		SCP3008_WeaponNone(client);
	}
}

public void SCP3008_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP3008_OnSpeed(int client, float &speed)
{
	speed = Speed;
}

public Action SCP3008_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Client[client].Extra2)
	{
		Client[client].Extra2 = 1;
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		SCP3008_WeaponFists(client);
	}
}

public bool SCP3008_OnSeePlayer(int client, int victim)
{
	return (Client[client].Extra2 || Client[victim].IdleAt>GetEngineTime());
}

public bool SCP3008_OnGlowPlayer(int client, int victim)
{
	return view_as<bool>(Client[client].Extra2);
}

void SCP3008_WeaponNone(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_club", 954, 1, 13, "1 ; 0 ; 252 ; 0.99", 2);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 0);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

void SCP3008_WeaponFists(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_club", 195, 100, 13, "2 ; 1.35 ; 28 ; 0.25 ; 252 ; 0.5", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 10);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}