//static const char Name[] = "939";
//static const char Name2[] = "9392";
//static const char Model[] = "models/scp_sl/scp_939/scp_939_redone_pm_1.mdl";
static const int Health = 2750;
static const float SpeedFull = 300.0;
static const float SpeedDiv = 55.0;
static const float GlowRange = 800.0;

static const char Downloads[][] =
{
	"models/scp_sl/scp_939/scp_939_redone_pm_1.dx80.vtx",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.dx90.vtx",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.mdl",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.phy",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.sw.vtx",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.vvd",

	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01.vmt",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01_normal.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01_phong.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_extremities2.vmt",
	"materials/models/scpbreach/scp939redone/scp-939_licker_extremities2.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_extremities2_normal.vtf"
};

void SCP939_Enable()
{
	int table = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	for(int i; i<sizeof(Downloads); i++)
	{
		if(!FileExists(Downloads[i], true))
		{
			LogError("Missing file: '%s'", Downloads[i]);
			continue;
		}

		AddToStringTable(table, Downloads[i]);
	}
	LockStringTables(save);
}

void SCP939_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = Health;
	Client[client].Radio = 0;
	Client[client].Floor = Floor_Light;

	Client[client].OnDealDamage = SCP939_OnDealDamage;
	Client[client].OnGlowPlayer = SCP939_OnGlowPlayer;
	Client[client].OnMaxHealth = SCP939_OnMaxHealth;
	Client[client].OnSeePlayer = SCP939_OnSeePlayer;
	Client[client].OnSpeed = SCP939_OnSpeed;

	int account = GetSteamAccountID(client);

	int weapon = SpawnWeapon(client, "tf_weapon_knife", 461, 70, 13, "1 ; 0.01 ; 15 ; 0 ; 137 ; 165 ; 138 ; 165 ; 252 ; 0.3 ; 869 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 10);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	weapon = SpawnWeapon(client, "tf_weapon_pda_spy", 27, 70, 13, "816 ; 1", false);
	if(weapon > MaxClients)
	{
		TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(GetRandomInt(250, 374))); // Sharp
		TF2Attrib_SetByDefIndex(weapon, 292, view_as<float>(64));
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
	}
}

public void SCP939_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP939_OnSpeed(int client, float &speed)
{
	speed = SpeedFull-(GetClientHealth(client)/SpeedDiv);
}

public Action SCP939_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(damagecustom != TF_CUSTOM_BACKSTAB)
		return Plugin_Continue;

	SDKHooks_TakeDamage(victim, client, client, 66.0);
	return Plugin_Handled;
}

public bool SCP939_OnSeePlayer(int client, int victim)
{
	return (IsFriendly(Client[client].Class, Client[victim].Class) || Client[victim].IdleAt>GetEngineTime());
}

public bool SCP939_OnGlowPlayer(int client, int victim)
{
	float time = Client[victim].IdleAt-GetEngineTime();
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