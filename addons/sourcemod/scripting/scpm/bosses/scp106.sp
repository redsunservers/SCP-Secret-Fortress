#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/scp_sf/106/scp106_player_3.dx80.vtx",
	"models/scp_sf/106/scp106_player_3.dx90.vtx",
	"models/scp_sf/106/scp106_player_3.mdl",
	"models/scp_sf/106/scp106_player_3.phy",
	"models/scp_sf/106/scp106_player_3.vvd",
	"models/scp_sf/106/scp106_hands_1.dx80.vtx",
	"models/scp_sf/106/scp106_hands_1.dx90.vtx",
	"models/scp_sf/106/scp106_hands_1.mdl",
	"models/scp_sf/106/scp106_hands_1.vvd",
	"materials/models/vinrax/scp/106_diffuse.vmt",
	"materials/models/vinrax/scp/106_diffuse.vtf",
	"materials/models/vinrax/scp/106_normal.vtf",
	"sound/scpm/scp106/chase.mp3"
};

static const char PlayerModel[] = "models/scp_sf/106/scp106_player_3.mdl";
static const char ViewModel[] = "models/scp_sf/106/scp106_hands_1.mdl";
static const char ChaseSound[] = "#scpm/scp106/chase.mp3";

static int BossIndex;
static bool NoclipHooked;
static float HoverPosition[MAXPLAYERS+1];

public void SCP106_Precache(int index)
{
	BossIndex = index;

	PrecacheModel(PlayerModel);
	PrecacheModel(ViewModel);
	PrecacheSound(ChaseSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
}

public void SCP106_Create(int client)
{
	Default_Create(client);

	if(!NoclipHooked)
	{
		ConVar_Add("sv_noclipspeed", "0.7");
		NoclipHooked = true;
	}
}

public TFClassType SCP106_TFClass()
{
	return TFClass_Soldier;
}

public void SCP106_Spawn(int client)
{
	if(!GoToNamedSpawn(client, "scp_spawn_106"))
		Default_Spawn(client);
}

public void SCP106_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	if(weapons)
	{
		int entity = Items_GiveByIndex(client, 195);
		if(entity != -1)
		{
			Attrib_Set(entity, "damage penalty", 0.77);
			Attrib_Set(entity, "crit mod disabled", 1.0);
			Attrib_Set(entity, "max health additive bonus", 1400.0);
			Attrib_Set(entity, "move speed penalty", 0.85);
			Attrib_Set(entity, "dmg taken from crit reduced", 0.0);
			Attrib_Set(entity, "dmg taken from bullets reduced", 0.2);
			Attrib_Set(entity, "damage force reduction", 0.4);
			Attrib_Set(entity, "airblast vulnerability multiplier", 0.4);

			TF2U_SetPlayerActiveWeapon(client, entity);

			SetEntityHealth(client, 1600);
		}
	}
}

public void SCP106_Remove(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	Default_Remove(client);

	if(NoclipHooked)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && Client(target).Boss == BossIndex)
				return;
		}

		ConVar_Remove("sv_noclipspeed");
		NoclipHooked = false;
	}
}

public float SCP106_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite)
{
	strcopy(theme, sizeof(theme), ChaseSound);
	return 30.8;
}

public Action SCP106_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Plugin_Continue;
}

public Action SCP106_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
	{
		float dist = FAbs(pos[2] - HoverPosition[client]);
		if(dist > 100.0)
		{
			// Assume teleported
			HoverPosition[client] = pos[2];
		}
		else if(dist > 0.0)
		{
			pos[2] = HoverPosition[client];
			TeleportEntity(client, pos);
		}
	}
	else
	{
		HoverPosition[client] = pos[2];
	}

	static float updateTime[MAXPLAYERS+1];
	if(FAbs(updateTime[client] - GetGameTime()) > 0.5)
	{
		updateTime[client] = GetGameTime();

		if(!(buttons & IN_SCORE))
		{
			static char buffer[64];
			Format(buffer, sizeof(buffer), "%T", "SCP106 Controls", client);
			PrintKeyHintText(client, buffer);
		}
	}

	return Plugin_Continue;
}

public void SCP106_ActionButton(int client)
{
	if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
	{
		float pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 16.0;

		if(GetSafePosition(client, pos, pos))
		{
			TeleportEntity(client, pos);
			SetEntityMoveType(client, MOVETYPE_WALK);

			PrintCenterText(client, "");
			ClientCommand(client, "playgamesound common/wpn_hudoff.wav");
		}
		else
		{
			PrintCenterText(client, "%T", "Unsafe Location", client);
			ClientCommand(client, "playgamesound items/suitchargeno1.wav");
		}
	}
	else if(GetEntityFlags(client) & FL_ONGROUND)
	{
		SetEntityMoveType(client, MOVETYPE_NOCLIP);

		PrintCenterText(client, "");
		ClientCommand(client, "playgamesound common/wpn_moveselect.wav");
	}
	else
	{
		PrintCenterText(client, "%T", "Unsafe Location", client);
		ClientCommand(client, "playgamesound items/suitchargeno1.wav");
	}
}

static bool GetSafePosition(int client, const float testPos[3], float result[3])
{
	float mins[3], maxs[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
	
	// Check if spot is safe
	result = testPos;
	TR_TraceHullFilter(testPos, testPos, mins, maxs, MASK_PLAYERSOLID, Trace_DontHitPlayers);
	if (!TR_DidHit())
		return true;
	
	// Might be hitting a celing, get the highest point
	float height = maxs[2] - mins[2];
	result[2] += height;
	TR_TraceRayFilter(testPos, result, MASK_PLAYERSOLID, RayType_EndPoint, Trace_DontHitPlayers);
	TR_GetEndPosition(result);
	result[2] -= height;
	
	TR_TraceHullFilter(result, result, mins, maxs, MASK_PLAYERSOLID, Trace_DontHitPlayers);
	if (!TR_DidHit())
		return true;
	
	return false;
}
