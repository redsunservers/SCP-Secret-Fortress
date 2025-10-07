#pragma semicolon 1
#pragma newdecls required

#define SCP106_NOCLIPSPEED	"0.7"

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
	Client(client).KeycardExit = 0;

	if(!NoclipHooked)
	{
		char value[16];
		Cvar[NoclipSpeed].GetString(value, sizeof(value));

		ConVar_Add("sv_noclipspeed", SCP106_NOCLIPSPEED);
		NoclipHooked = true;

		// No spoilers about the upcoming SCP
		for(int i = 1; i <= MaxClients; i++)
		{
			if(i != client && IsClientInGame(i) && !IsFakeClient(i))
				Cvar[NoclipSpeed].ReplicateToClient(i, value);
		}
	}
	
	if(!IsFakeClient(client))
		Cvar[NoclipSpeed].ReplicateToClient(client, SCP106_NOCLIPSPEED);
}

public TFClassType SCP106_TFClass()
{
	return TFClass_Soldier;
}

public void SCP106_Spawn(int client)
{
	ViewModel_DisableArms(client);
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
		GiveDefaultMelee(client);
		SetEntityHealth(client, 1000);

		ViewModel_Create(client, ViewModel, "a_fists_idle_02");
		ViewModel_SetAnimation(client, "fists_draw");
		
		Human_ToggleFlashlight(client);
	}
}

public void SCP106_PlayerDeath(int client, bool &fakeDeath)
{
	PlayDeathAnimation(client, client, "death_scp_106", _, 3.0, false, PlayerModel);
}

public void SCP106_Remove(int client)
{
	SetEntityMoveType(client, MOVETYPE_WALK);
	Default_Remove(client);

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	if(NoclipHooked)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && Client(target).Boss == BossIndex)
				return;
		}

		int flags = Cvar[NoclipSpeed].Flags;
		bool replicate = !(flags & FCVAR_REPLICATED);
		if(replicate)
			Cvar[NoclipSpeed].Flags |= FCVAR_REPLICATED;
		
		ConVar_Remove("sv_noclipspeed");

		if(replicate)
			Cvar[NoclipSpeed].Flags &= ~FCVAR_REPLICATED;

		NoclipHooked = false;
	}
}

public float SCP106_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite, float &volume)
{
	strcopy(theme, sizeof(theme), ChaseSound);
	return 30.8;
}

public Action SCP106_SoundHook(int client, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	return Default_SoundHook(client, clients, numClients, sample, entity, channel, volume, level, pitch, flags, soundEntry, seed);
}

public Action SCP106_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Default_TakeDamage(client, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, critType);
}

public Action SCP106_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(!Client(victim).IsBoss)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);

		if(!GoToNamedSpawn(victim, "scp_pocket"))
		{
			if(GetURandomInt() % 3)
			{
				damage *= 2.0;
				damagetype |= DMG_CRIT;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action SCP106_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	if(GetEntityMoveType(client) == MOVETYPE_NOCLIP)
	{
		float dist = FAbs(pos[2] - HoverPosition[client]);
		if(dist > 50.0)
		{
			// Assume teleported
			HoverPosition[client] = pos[2];
		}
		else if(dist > 0.0)
		{
			pos[2] = HoverPosition[client];
			TeleportEntity(client, pos);
		}

		if(buttons & IN_ATTACK)
			Client(client).ControlProgress = 0;
	}
	else
	{
		HoverPosition[client] = pos[2];
	}

	if(!Client(client).ControlProgress)
	{
		if(Client(client).KeyHintUpdateAt < GetGameTime())
		{
			Client(client).KeyHintUpdateAt = GetGameTime() + 0.5;

			if(!(buttons & IN_SCORE))
			{
				static char buffer[64];
				Format(buffer, sizeof(buffer), "%T", "SCP106 Controls", client);
				PrintKeyHintText(client, buffer);
			}
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

			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			GiveDefaultMelee(client);
			ViewModel_Create(client, ViewModel, "a_fists_idle_02");
			ViewModel_SetAnimation(client, "fists_draw");

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
		ViewModel_Destroy(client);
		
		int entity = Items_GiveCustom(client, 1123, _, false);
		if(entity != -1)
		{
			Attrib_Set(entity, "damage penalty", 0.0);
			Attrib_Set(entity, "max health additive bonus", 800.0);
			Attrib_Set(entity, "move speed penalty", 0.85);
			Attrib_Set(entity, "dmg taken from crit reduced", 0.0);
			Attrib_Set(entity, "dmg taken from bullets reduced", 0.2);
			Attrib_Set(entity, "damage force reduction", 0.0);
			Attrib_Set(entity, "cancel falling damage", 1.0);
			Attrib_Set(entity, "airblast vulnerability multiplier", 0.0);
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);

			SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 999.9);

			TF2U_SetPlayerActiveWeapon(client, entity);

			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
		}

		PrintCenterText(client, "");
		ClientCommand(client, "playgamesound common/wpn_moveselect.wav");
		Client(client).ControlProgress = 1;
	}
	else
	{
		PrintCenterText(client, "%T", "Unsafe Location", client);
		ClientCommand(client, "playgamesound items/suitchargeno1.wav");
	}
}

public Action SCP106_CalcIsAttackCritical(int client, int weapon, const char[] weaponname, bool &result)
{
	ViewModel_SetAnimation(client, (GetURandomInt() % 2) ? "attack1" : "attack2");
	return Plugin_Continue;
}

public void SCP106_RelayTrigger(int client, const char[] name, int relay, int target)
{
	if(!StrContains(name, "scp_femur", false))
		SDKHooks_TakeDamage(client, client, client, 9001.0, DMG_NERVEGAS);
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

static void GiveDefaultMelee(int client)
{
	int entity = Items_GiveCustom(client, 649, "tf_weapon_shovel", false, false);
	if(entity != -1)
	{
		Attrib_Set(entity, "damage penalty", 0.77);
		Attrib_Set(entity, "crit mod disabled", 0.0);
		Attrib_Set(entity, "max health additive bonus", 800.0);
		Attrib_Set(entity, "move speed penalty", 0.85);
		Attrib_Set(entity, "dmg taken from crit reduced", 0.0);
		Attrib_Set(entity, "dmg taken from bullets reduced", 0.2);
		Attrib_Set(entity, "damage force reduction", 0.4);
		Attrib_Set(entity, "cancel falling damage", 1.0);
		Attrib_Set(entity, "airblast vulnerability multiplier", 0.4);
		Attrib_Set(entity, "mod weapon blocks healing", 1.0);

		TF2U_SetPlayerActiveWeapon(client, entity);
	}
}