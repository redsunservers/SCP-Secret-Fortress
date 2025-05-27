#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/freak_fortress_2/scp_173/scp_173new.dx80.vtx",
	"models/freak_fortress_2/scp_173/scp_173new.dx90.vtx",
	"models/freak_fortress_2/scp_173/scp_173new.mdl",
	"models/freak_fortress_2/scp_173/scp_173new.vvd",
	"models/scp_new/173/scp_173new_death.dx80.vtx",
	"models/scp_new/173/scp_173new_death.dx90.vtx",
	"models/scp_new/173/scp_173new_death.mdl",
	"models/scp_new/173/scp_173new_death.vvd",	
	"materials/freak_fortress_2/scp_173/new173_texture.vmt",
	"materials/freak_fortress_2/scp_173/new173_texture.vtf",
	"sound/scpm/scp173/kill.mp3",
	"sound/scpm/scp173/scare.mp3",
	"sound/scpm/scp173/death.wav"
};

static const char DeathAnims[][] =
{
	"stand_MELEE",

	"taunt_neck_snap_scout",
	"taunt_neck_snap_sniper",
	"taunt_neck_snap_soldier",

	"taunt_neck_snap_demo",
	"taunt_neck_snap_medic",
	"taunt_neck_snap_heavy",

	"taunt_neck_snap_pyro",
	"taunt_neck_snap_spy",
	"taunt_neck_snap_engineer"
};

static const float CycleAnims[] =
{
	0.23,

	0.23,
	0.23,
	0.23,

	0.23,
	0.23,
	0.23,

	0.23,
	0.23,
	0.23
};

static const float TimeAnims[] =
{
	0.5,

	2.3,	// 125
	1.7,	// 105
	1.7,	// 105

	2.0,	// 115
	1.3,	// 95
	2.0,	// 115

	1.7,	// 105
	2.7,	// 135
	1.7	// 105
};

static const char PlayerModel[] = "models/freak_fortress_2/scp_173/scp_173new.mdl";
static const char DeathModel[] = "models/scp_new/173/scp_173new_death.mdl";
static const char ScareSound[] = "scpm/scp173/scare.mp3";
static const char KillSound[] = "scpm/scp173/kill.mp3";
static const char DeathSound[] = "scpm/scp173/death.wav";
static const char WalkSound[] = "physics/concrete/concrete_scrape_smooth_loop1.wav";

static float LastBlinkTime[MAXPLAYERS+1];
static float MotionTimeFor[MAXPLAYERS+1];
static float CutsceneFor[MAXPLAYERS+1];
static int ModelRef[MAXPLAYERS+1] = {-1, ...};
static bool PlayingWalk[MAXPLAYERS+1];

public void SCP173_Precache()
{
	PrecacheModel(PlayerModel);
	PrecacheModel(DeathModel);
	PrecacheSound(ScareSound);
	PrecacheSound(KillSound);
	PrecacheSound(DeathSound);
	PrecacheSound(WalkSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
}

public void SCP173_Create(int client)
{
	CutsceneFor[client] = 0.0;
	MotionTimeFor[client] = 0.0;
	Default_Create(client);
}

public TFClassType SCP173_TFClass()
{
	return TFClass_Heavy;
}

public void SCP173_Spawn(int client)
{
	if(!GoToNamedSpawn(client, "scp_spawn_173"))
		Default_Spawn(client);
}

public void SCP173_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModel");

	if(weapons)
	{
		int entity = Items_GiveByIndex(client, 195);
		if(entity != -1)
		{
			Attrib_Set(entity, "fire rate bonus", 0.3);
			Attrib_Set(entity, "crit mod disabled", 1.0);
			Attrib_Set(entity, "max health additive bonus", 1700.0);
			Attrib_Set(entity, "dmg penalty vs players", 11.0);
			Attrib_Set(entity, "damage force reduction", 0.0);
			Attrib_Set(entity, "cancel falling damage", 1.0);
			Attrib_Set(entity, "cannot be backstabbed", 1.0);
			Attrib_Set(entity, "airblast vulnerability multiplier", 0.0);
			Attrib_Set(entity, "no_duck", 1.0);

			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, 0);

			TF2U_SetPlayerActiveWeapon(client, entity);

			SetEntityHealth(client, 2000);
		}
	}
}

public void SCP173_WeaponSwitch(int client)
{
	Default_WeaponSwitch(client);
}

public void SCP173_Remove(int client)
{
	if(IsValidEntity(ModelRef[client]))
		RemoveEntity(ModelRef[client]);
	
	StopSound(client, SNDCHAN_STATIC, WalkSound);

	PlayingWalk[client] = false;
	ModelRef[client] = -1;
	Attrib_Remove(client, "major move speed bonus");
	Attrib_Remove(client, "no_jump");
	Default_Remove(client);
}

public float SCP173_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite)
{
	if(client == victim)
		return 0.0;
	
	strcopy(theme, sizeof(theme), ScareSound);
	return 30.0;
}

public Action SCP173_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Default_TakeDamage(client, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, critType);
}

public Action SCP173_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	bool lookedAt = CutsceneFor[client] > GetGameTime();

	int team = GetClientTeam(client);
	for(int target = 1; target <= MaxClients; target++)
	{
		if(Client(target).LookingAt(client) && IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != team)
		{
			lookedAt = true;
			break;
		}
	}

	bool blinked = LastBlinkTime[client] != Gamemode_NextBlinkAt();

	if(blinked)
		LastBlinkTime[client] = Gamemode_NextBlinkAt();
	
	if(!lookedAt && (vel[0] > 0.0 || vel[1] > 0.0 || vel[2] > 0.0))
	{
		if(!PlayingWalk[client])
		{
			PlayingWalk[client] = true;
			EmitSoundToAll(WalkSound, client, SNDCHAN_STATIC, SNDLEVEL_GUNFIRE);
		}
	}
	else if(PlayingWalk[client])
	{
		PlayingWalk[client] = false;
		StopSound(client, SNDCHAN_STATIC, WalkSound);
	}

	if(lookedAt)
	{
		if(GetEntProp(client, Prop_Send, "m_bUseClassAnimations"))
		{
			Attrib_Set(client, "major move speed bonus", 0.002);
			Attrib_Set(client, "no_jump", 1.0);
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", false);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false);
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 999.9);
			SDKCall_SetSpeed(client);
		}
	}
	else if(!GetEntProp(client, Prop_Send, "m_bUseClassAnimations"))
	{
		MotionTimeFor[client] = 0.0;
		Attrib_Set(client, "major move speed bonus", 2.0);
		Attrib_Remove(client, "no_jump");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", true);
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 1.0);
		SDKCall_SetSpeed(client);
		PrintCenterText(client, "");
	}

	if(lookedAt && MotionTimeFor[client])
	{
		if(MotionTimeFor[client] < GetGameTime())
		{
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false);
		}
		else if(!GetEntProp(client, Prop_Send, "m_bCustomModelRotates"))
		{
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", true);
		}
	}

	float pos1[3], ang[3], pos2[3];
	GetClientEyePosition(client, pos1);
	GetClientEyeAngles(client, ang);
	if(DPT_TryTeleport(client, 1000.0, pos1, ang, pos2))
	{
		if(lookedAt && blinked)
		{
			PrintCenterText(client, "[ X ]");

			MotionTimeFor[client] = GetGameTime() + 0.15;
			TeleportEntity(client, pos2, NULL_VECTOR, NULL_VECTOR);

			int victim;
			float distance = 10000.0;
			for(int target = 1; target <= MaxClients; target++)
			{
				if(target == client || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) == team)
					continue;

				GetClientAbsOrigin(target, pos1);
				float dist = GetVectorDistance(pos1, pos2, true);
				if(dist < distance)
				{
					victim = target;
					distance = dist;
				}
			}

			if(victim)
			{
				bool grounded = view_as<bool>(GetEntityFlags(victim) & FL_ONGROUND);
				SDKHooks_TakeDamage(victim, client, client, 65.0, DMG_CRUSH, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), ang, pos2, false);
				if(grounded && GetClientHealth(victim) < 1)
					TryDeathScene(victim, client);
			}
		}
		else
		{
			if(lookedAt)
				PrintCenterText(client, "[%.1f]", Gamemode_NextBlinkAt() - GetGameTime());

			int entity = EntRefToEntIndex(ModelRef[client]);
			if(entity == -1)
			{
				entity = CreateEntityByName("prop_dynamic_override");
				if(entity == -1)
					return Plugin_Continue;

				DispatchKeyValue(entity, "skin", "0");
				DispatchKeyValue(entity, "model", PlayerModel);
				DispatchSpawn(entity);

				SetEntityCollisionGroup(entity, 2);
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntityRenderMode(entity, RENDER_TRANSALPHA);
				SetEntityRenderColor(entity, (blinked || lookedAt) ? 255 : 55, 55, 55, 155);

				SDKHook(entity, SDKHook_SetTransmit, PropSetTransmit);

				ModelRef[client] = EntIndexToEntRef(entity);
			}
			
			ang[0] = 0.0;
			ang[2] = 0.0;
			TeleportEntity(entity, pos2, ang, NULL_VECTOR);
			return Plugin_Continue;
		}
	}

	if(ModelRef[client] != -1)
	{
		if(IsValidEntity(ModelRef[client]))
			RemoveEntity(ModelRef[client]);
		
		ModelRef[client] = -1;
	}

	return Plugin_Continue;
}

static Action PropSetTransmit(int entity, int target)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == target ? Plugin_Continue : Plugin_Stop;
}

static bool DPT_TryTeleport(int clientIdx, float maxDistance, const float startPos[3], const float eyeAngles[3], float testPos[3])
{
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, Trace_DontHitEntity, clientIdx);
	TR_GetEndPosition(testPos);

	if (TR_PointOutsideWorld(testPos))
		return false;
	
	float distance = GetVectorDistance(startPos, testPos);
	if (distance > maxDistance)
	{
		ConstrainDistance(startPos, testPos, distance, maxDistance);
	}
	else
	{
		int entity = TR_GetEntityIndex();
		if (0 < entity <= MaxClients && GetClientTeam(entity) != GetClientTeam(clientIdx))
		{
			// Try lock into enemy
			GetClientAbsOrigin(entity, testPos);
			if (GetSafePosition(clientIdx, testPos, testPos))
				return true;
		}
	}
	
	float eyeVel[3];
	AnglesToVelocity(eyeAngles, eyeVel);
	
	// shave just a tiny bit off the end position so our point isn't directly on top of a wall
	SubtractVectors(testPos, eyeVel, testPos);
	
	// don't even try if the distance is less than 82
	for (int i; i < 100 && GetVectorDistance(startPos, testPos) >= 82.0; i++)
	{
		if (GetSafePosition(clientIdx, testPos, testPos))
			return true;
		
		// Go back by 1hu and try again
		SubtractVectors(testPos, eyeVel, testPos);
	}
	
	return false;
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

static void TryDeathScene(int victim, int attacker)
{
	CutsceneFor[attacker] = GetGameTime() + 1.3;
	CreateTimer(1.3, NecksnapTimer, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	PlayClassDeathAnimation(victim, attacker, DeathAnims, CycleAnims, TimeAnims);
}

static Action NecksnapTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		ScreenFade(client, 100, 150, FFADE_IN, 0, 0, 0, 255);
		ClientCommand(client, "playgamesound %s", KillSound);
		EmitSoundToAll(KillSound, client, _, SNDLEVEL_GUNFIRE);
	}

	return Plugin_Continue;
}
