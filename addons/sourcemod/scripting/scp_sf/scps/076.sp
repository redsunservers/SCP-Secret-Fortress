//static const char Name[] = "076";
//static const char Model[] = "models/freak_fortress_2/newscp076/newscp076_v1.mdl";
static const int Health = 2000;
static const float Speeds[] = {240.0, 246.0, 252.0, 258.0, 276.0};
static const int MaxHeads = 4;
static const int HealthKill = 15;
static const int HealthRage = 250;

static const char Downloads[][] =
{
	"models/freak_fortress_2/newscp076/newscp076_v1.dx80.vtx",
	"models/freak_fortress_2/newscp076/newscp076_v1.dx90.vtx",
	"models/freak_fortress_2/newscp076/newscp076_v1.mdl",
	"models/freak_fortress_2/newscp076/newscp076_v1.phy",
	"models/freak_fortress_2/newscp076/newscp076_v1.sw.vtx",
	"models/freak_fortress_2/newscp076/newscp076_v1.vvd",

	"materials/freak_fortress_2/scp076/arms_full.vmt",
	"materials/freak_fortress_2/scp076/arms_full.vtf",
	"materials/freak_fortress_2/scp076/arms_full_n.vtf",
	"materials/freak_fortress_2/scp076/clothing.vmt",
	"materials/freak_fortress_2/scp076/clothing_d.vtf",
	"materials/freak_fortress_2/scp076/clothing_n.vtf",
	"materials/freak_fortress_2/scp076/eyeball_l_r.vmt",
	"materials/freak_fortress_2/scp076/eyeball_l_r.vtf",
	"materials/freak_fortress_2/scp076/footmale.vmt",
	"materials/freak_fortress_2/scp076/footmale.vtf",
	"materials/freak_fortress_2/scp076/footmale_n.vtf",
	"materials/freak_fortress_2/scp076/head.vmt",
	"materials/freak_fortress_2/scp076/head_d.vtf",
	"materials/freak_fortress_2/scp076/head_n.vtf",
	"materials/freak_fortress_2/scp076/metal.vmt",
	"materials/freak_fortress_2/scp076/metal_d.vtf",
	"materials/freak_fortress_2/scp076/metal_n.vtf",
	"materials/freak_fortress_2/scp076/pop_hair.vmt",
	"materials/freak_fortress_2/scp076/pop_hair.vtf",
	"materials/freak_fortress_2/scp076/pop_hair_exponent.vtf",
	"materials/freak_fortress_2/scp076/pop_hair_normal.vtf",
	"materials/freak_fortress_2/scp076/pop_head.vmt",
	"materials/freak_fortress_2/scp076/pop_head.vtf",
	"materials/freak_fortress_2/scp076/pop_head_exponent.vtf",
	"materials/freak_fortress_2/scp076/pop_head_normal.vtf",
	"materials/freak_fortress_2/scp076/pop_mask_hair.vmt",
	"materials/freak_fortress_2/scp076/pop_skin_lightwrap.vtf",
	"materials/freak_fortress_2/scp076/pupil_l_r.vtf",
	"materials/freak_fortress_2/scp076/torso.vmt",
	"materials/freak_fortress_2/scp076/torso_d.vtf",
	"materials/freak_fortress_2/scp076/torso_n.vtf"
};

void SCP076_Enable()
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

void SCP076_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;
	Client[client].Floor = Floor_Heavy;

	Client[client].OnDeath = SCP076_OnDeath;
	Client[client].OnKill = SCP076_OnKill;
	Client[client].OnMaxHealth = SCP076_OnMaxHealth;
	Client[client].OnSpeed = SCP076_OnSpeed;

	int weapon = SpawnWeapon(client, "tf_weapon_sword", 195, 1, 13, "1 ; 0.01 ; 28 ; 0.5 ; 137 ; 151 ; 138 ; 151 ; 219 ; 1 ; 252 ; 0.8", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 11);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		CreateTimer(15.0, Timer_UpdateClientHud, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void SCP076_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP076_OnSpeed(int client, float &speed)
{
	int value = Client[client].Radio;
	if(value >= sizeof(Speeds))
		value = sizeof(Speeds)-1;

	speed = Speeds[value];
}

public void SCP076_OnKill(int client, int victim)
{
	Client[client].Radio++;
	if(Client[client].Radio == MaxHeads)
	{
		TF2_StunPlayer(client, 2.0, 0.5, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
		ClientCommand(client, "playgamesound items/powerup_pickup_knockback.wav");

		TF2_AddCondition(client, TFCond_CritCola);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		Client[client].Keycard = Keycard_106;
		SetEntityHealth(client, GetClientHealth(client)+HealthRage);

		int weapon = SpawnWeapon(client, "tf_weapon_sword", 266, 90, 13, "2 ; 101 ; 5 ; 1.15 ; 252 ; 0 ; 326 ; 1.67", true, true);
		if(weapon > MaxClients)
		{
			ApplyStrangeRank(weapon, 18);
			SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
	}
	else if(Client[client].Radio < MaxHeads)
	{
		SetEntityHealth(client, GetClientHealth(client)+HealthKill);
		SDKCall_SetSpeed(client);
	}
}

public void SCP076_OnDeath(int client, int attacker)
{
	CreateTimer(5.0, Timer_DissolveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}