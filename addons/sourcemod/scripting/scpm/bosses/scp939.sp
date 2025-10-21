#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/scp_sl/scp_939/scp_939_redone_pm_1.dx80.vtx",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.dx90.vtx",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.mdl",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.phy",
	"models/scp_sl/scp_939/scp_939_redone_pm_1.vvd",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01.vmt",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01_normal.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_diffusetest01_phong.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_extremities2.vmt",
	"materials/models/scpbreach/scp939redone/scp-939_licker_extremities2.vtf",
	"materials/models/scpbreach/scp939redone/scp-939_licker_extremities2_normal.vtf",
	"sound/scpm/scp939/chase.mp3"
};

static const char PlayerModel[] = "models/scp_sl/scp_939/scp_939_redone_pm_1.mdl";
static const char ChaseSound[] = "#scpm/scp939/chase.mp3";
static int BossIndex;
static int PlayerModelIndex;

static int PackLeader;
static Handle PackTimer;

public bool SCP939_Precache(int index)
{
	BossIndex = index;
	
	PlayerModelIndex = PrecacheModel(PlayerModel);
	PrecacheSound(ChaseSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
	return true;
}

public void SCP939_Create(int client)
{
	Default_Create(client);
	Client(client).SilentTalk = false;

	if(!PackLeader)
		PackLeader = client;
	
	if(!PackTimer)
		PackTimer = CreateTimer(120.0, SpawnExtraDog);
}

public TFClassType SCP939_TFClass()
{
	return TFClass_Spy;
}

public void SCP939_Spawn(int client)
{
	if(!GoToNamedSpawn(client, "scp_spawn_939"))
		Default_Spawn(client);
	
	SetEntityCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
}

public void SCP939_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	for(int i; i < 4; i++)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", PlayerModelIndex, _, i);
	}

	if(weapons)
	{
		bool leader = PackLeader == client;

		int entity = Items_GiveCustom(client, 27, _, false);
		if(entity != -1)
		{
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);
		}

		entity = Items_GiveCustom(client, 461, _, false);
		if(entity != -1)
		{
			Attrib_Set(entity, "damage bonus", 2.5);
			Attrib_Set(entity, "health regen", 4.0);
			Attrib_Set(entity, "max health additive penalty", leader ? 125.0 : 25.0);
			Attrib_Set(entity, "move speed penalty", 0.75);
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);

			TF2U_SetPlayerActiveWeapon(client, entity);

			SetEntityHealth(client, 250);
		}

		if(!leader)
		{
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, GetRandomInt(200, 255), GetRandomInt(200, 255), GetRandomInt(200, 255));
		}
		
		Human_ToggleFlashlight(client);
	}
}

public void SCP939_PlayerDeath(int client, bool &fakeDeath)
{
	if(PackLeader == client)
		fakeDeath = true;
}

public void SCP939_Remove(int client)
{
	Default_Remove(client);
	SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
	SetEntityRenderColor(client);
	SetEntityRenderMode(client, RENDER_NORMAL);

	for(int i; i < 4; i++)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, i);
	}

	if(PackLeader == client)
	{
		PackLeader = 0;
		delete PackTimer;
	}
}

public float SCP939_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite, float &volume)
{
	strcopy(theme, sizeof(theme), ChaseSound);
	return 15.9;
}

public Action SCP939_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Default_TakeDamage(client, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, critType);
}

public Action SCP939_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(Client(client).NoTransmitTo(victim) && damagecustom != TF_CUSTOM_BACKSTAB)
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	else
	{
		Client(victim).LastNoiseAt = GetGameTime();
	}

	return Plugin_Continue;
}

public void SCP939_ConditionAdded(int client, TFCond cond)
{
	if(cond == TFCond_Disguised)
		Client(client).ControlProgress = 9;
}

public Action SCP939_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(Client(client).ControlProgress < 9)
	{
		if(Client(client).KeyHintUpdateAt < GetGameTime())
		{
			Client(client).KeyHintUpdateAt = GetGameTime() + 0.5;

			if(!(buttons & IN_SCORE))
			{
				static char buffer[64];
				Format(buffer, sizeof(buffer), "%T", "SCP939 Controls", client);
				PrintKeyHintText(client, buffer);
			}
		}
	}

	return Plugin_Continue;
}

public bool SCP939_GlowTarget(int client, int target)
{
	float gameTime = GetGameTime();

	if(GetClientTeam(client) != GetClientTeam(target) && (Client(target).LastNoiseAt + 3.0) < gameTime && !TF2_IsPlayerInCondition(target, TFCond_MarkedForDeath))
	{
		Client(target).NoTransmitTo(client, true);
	}
	else
	{
		Client(target).NoTransmitTo(client, false);
	}

	if((Client(target).LastNoiseAt + 1.5) > gameTime)
		return true;
	
	return false;
}

public void SCP939_PlayerKilled(int client, int victim, bool fakeDeath)
{
	if(!fakeDeath)
		Bosses_DisplayEntry(victim, "SCP939 Entry");
}

static Action SpawnExtraDog(Handle timer)
{
	PackTimer = null;

	int choosen = PackLeader;

	if(IsPlayerAlive(PackLeader))
	{
		int humans;
		int[] human = new int[MaxClients];

		int allies;
		int[] ally = new int[MaxClients];

		for(int target = 1; target <= MaxClients; target++)
		{
			if(PackLeader != target && IsClientInGame(target) && !IsPlayerAlive(target))
			{
				switch(GetClientTeam(target))
				{
					case TFTeam_Bosses:
						ally[allies++] = target;
					
					case TFTeam_Humans:
						human[humans++] = target;
				}
			}
		}

		if(allies)
		{
			choosen = ally[GetURandomInt() % allies];
		}
		else if(humans)
		{
			choosen = human[GetURandomInt() % humans];
		}
		else
		{
			PackTimer = CreateTimer(20.0, SpawnExtraDog);
			return Plugin_Continue;
		}
	}

	ChangeClientTeam(choosen, TFTeam_Bosses);
	Bosses_Create(choosen, BossIndex);
	ClientCommand(choosen, "playgamesound ui/system_message_alert.wav");
	return Plugin_Continue;
}
