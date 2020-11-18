//static const char Name[] = "106";
//static const char Model[] = "models/freak_fortress_2/106_spyper/106.mdl";
static const int Health = 800;
static const float Speed = 240.0;
static const float TeleStun = 8.5;		// Teleport stun duration
static const float TeleDelay = 3.5;	// Teleport delay

static const char Downloads[][] =
{
	"models/freak_fortress_2/106_spyper/106.dx80.vtx",
	"models/freak_fortress_2/106_spyper/106.dx90.vtx",
	"models/freak_fortress_2/106_spyper/106.mdl",
	"models/freak_fortress_2/106_spyper/106.phy",
	"models/freak_fortress_2/106_spyper/106.sw.vtx",
	"models/freak_fortress_2/106_spyper/106.vvd",

	"materials/models/vinrax/scp/106_diffuse.vmt",
	"materials/models/vinrax/scp/106_diffuse.vtf",
	"materials/models/vinrax/scp/106_normal.vtf"
};

void SCP106_Enable()
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

void SCP106_Create(int client)
{
	Client[client].Pos[0] = 0.0;
	Client[client].Pos[1] = 0.0;
	Client[client].Pos[2] = 0.0;
	Client[client].Keycard = Keycard_106;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;
	Client[client].Floor = Floor_Heavy;

	Client[client].OnButton = SCP106_OnButton;
	Client[client].OnDealDamage = SCP106_OnDealDamage;
	Client[client].OnDeath = SCP106_OnDeath;
	Client[client].OnKill = SCP106_OnKill;
	Client[client].OnMaxHealth = SCP106_OnMaxHealth;
	Client[client].OnSpeed = SCP106_OnSpeed;

	int weapon = SpawnWeapon(client, "tf_weapon_shovel", 939, 60, 13, "1 ; 0.01 ; 28 ; 0 ; 66 ; 0.1 ; 137 ; 101 ; 138 ; 101 ; 252 ; 0.4", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 12);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public void SCP106_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP106_OnSpeed(int client, float &speed)
{
	speed = Speed;
}

public void SCP106_OnDeath(int client, int attacker)
{
	if(Client[client].Radio)
		HideAnnotation(client);

	CreateTimer(0.1, Timer_DissolveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void SCP106_OnKill(int client, int victim)
{
	GiveAchievement(Achievement_Death106, victim);
}

public Action SCP106_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);

	int entity = -1;
	static char name[16];
	static int spawns[4];
	int count;
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_pocket", false))
			spawns[count++] = entity;

		if(count > 3)
			break;
	}

	if(count)
	{
		entity = spawns[GetRandomInt(0, count-1)];

		static float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(victim, pos, NULL_VECTOR, TRIPLE_D);
	}
	else if(GetRandomInt(0, 2))
	{
		damagetype |= DMG_CRIT;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void SCP106_OnButton(int client, int button)
{
	if(Client[client].ChargeIn && Client[client].ChargeIn<GetEngineTime())
	{
		Client[client].ChargeIn = 0.0;
		TeleportEntity(client, Client[client].Pos, NULL_VECTOR, TRIPLE_D);
	}
	else if(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2])
	{
		static float pos[3];
		GetClientEyePosition(client, pos);
		if(Client[client].Radio)
		{
			if(GetVectorDistance(pos, Client[client].Pos, true) > 150000)
				HideAnnotation(client);
		}
		else if(GetVectorDistance(pos, Client[client].Pos, true) < 100000)
		{
			ShowAnnotation(client);
		}
	}

	if(button == IN_ATTACK2)
	{
		int flags = GetEntityFlags(client);
		if((flags & FL_DUCKING) || !(flags & FL_ONGROUND) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || GetEntProp(client, Prop_Send, "m_bDucked"))
		{
			PrintHintText(client, "%T", "106_create_deny", client);
		}
		else
		{
			Client[client].Radio = 1;
			PrintHintText(client, "%T", "106_create", client);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Client[client].Pos);
			ShowAnnotation(client);
		}
	}
	else if(button == IN_ATTACK3)
	{
		if(!(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2]))
		{
			PrintHintText(client, "%T", "106_create_none", client);
		}
		else if(TF2_IsPlayerInCondition(client, TFCond_Dazed) || !(GetEntityFlags(client)& FL_ONGROUND))
		{
			PrintHintText(client, "%T", "106_tele_deny", client);
		}
		else
		{
			TF2_StunPlayer(client, TeleStun, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
			TF2_AddCondition(client, TFCond_MegaHeal, TeleStun);
			Client[client].ChargeIn = GetEngineTime()+TeleDelay;
			PrintRandomHintText(client);
		}
	}
}

static void ShowAnnotation(int client)
{
	Event event = CreateEvent("show_annotation");
	if(event != INVALID_HANDLE)
	{
		event.SetFloat("worldPosX", Client[client].Pos[0]);
		event.SetFloat("worldPosY", Client[client].Pos[1]);
		event.SetFloat("worldPosZ", Client[client].Pos[2]);
		event.SetFloat("lifetime", 999.0);
		event.SetInt("id", 9999-client);

		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "%T", "106_portal", client);
		event.SetString("text", buffer);

		event.SetString("play_sound", "vo/null.wav");
		event.SetInt("visibilityBitfield", (1<<client));
		event.Fire();

		Client[client].Radio = 1;
	}
}

void HideAnnotation(int client)
{
	Event event = CreateEvent("hide_annotation");
	if(event != INVALID_HANDLE)
	{
		event.SetInt("id", 9999-client);
		event.Fire();

		Client[client].Radio = 0;
	}
}