static const char ModelMedi[] = "models/scp_sf/049/c_arms_scp049_knife_1.mdl";
static const char ModelMelee[] = "models/scp_sf/049/c_arms_scp049_4.mdl";

static const float SpeedFound = 1.18;

enum struct SCP049Enum
{
	int Index;	// Revive Marker Index / SCP-049 Revive Count
	float MoveAt;	// Revive Marker Move Timer / SCP-049 Melee Timer
	float GoneAt;	// Revive Marker Lifetime Timer / SCP-049 Tick Timer
}

static SCP049Enum Revive[MAXTF2PLAYERS];
static int Index049;
static int Index0492;

public void SCP049_Enable(int index)
{
	HookEvent("revive_player_complete", SCP049_OnRevive);
	Index049 = index;
}

public void SCP0492_Enable(int index)
{
	Index0492 = index;
}

public bool SCP049_Create(int client)
{
	Classes_VipSpawn(client);

	int account = GetSteamAccountID(client, false);

	GiveMelee(client, account);

	int weapon = SpawnWeapon(client, "tf_weapon_medigun", 211, 5, 13, "7 ; 0.65 ; 9 ; 0 ; 18 ; 1 ; 252 ; 0.95 ; 292 ; 2 ; 412 ; 0.8", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 11);
		TF2Attrib_SetByDefIndex(weapon, 454, view_as<float>(1));
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
	}
	
	Client[client].Extra1 = 0;

	Revive[client].Index = 0;
	Revive[client].GoneAt = GetGameTime()+20.0;
	Revive[client].MoveAt = FAR_FUTURE;
	return false;
}

public bool SCP0492_Create(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_bat", 572, 50, 13, "2 ; 1.25 ; 5 ; 1.3 ; 28 ; 0.5 ; 252 ; 0.5", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 4);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	ClassEnum class;
	Classes_GetByIndex(Index0492, class);

	ChangeClientTeamEx(client, class.Team);

	// Show class info
	Client[client].HudIn = GetGameTime()+9.9;
	CreateTimer(2.0, ShowClassInfoTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	// Model stuff
	SetVariantString(class.Model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelIndex, _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelAlt, _, 3);
	TF2_CreateGlow(client, class.Model);

	// Reset health
	SetEntityHealth(client, class.Health);

	// Other stuff
	TF2_AddCondition(client, TFCond_NoHealingDamageBuff, 1.0);
	TF2Attrib_SetByDefIndex(client, 49, 1.0);
	return true;
}

public void SCP049_OnSpeed(int client, float &speed)
{
	if(Client[client].Extra1 == 1)
		speed *= SpeedFound;
}

public Action SCP049_OnAnimation(int client, PlayerAnimEvent_t &anim, int &data)
{
	if((anim==PLAYERANIMEVENT_ATTACK_PRIMARY || anim==PLAYERANIMEVENT_ATTACK_SECONDARY || anim==PLAYERANIMEVENT_ATTACK_GRENADE) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
		ViewModel_SetAnimation(client, GetRandomInt(0, 1) ? "attack1" : "attack2");

	return Plugin_Continue;
}

public void SCP049_OnWeaponSwitch(int client, int entity)
{
	ViewModel_Destroy(client);
	if(entity == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
	{
		if(Revive[client].MoveAt != FAR_FUTURE)
		{
			if(Enabled)
			{
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				GiveMelee(client, GetSteamAccountID(client, false), false);
			}
			Revive[client].MoveAt = FAR_FUTURE;
			Revive[client].GoneAt = GetGameTime()+3.0;
		}

		ViewModel_Create(client, ModelMedi);
		ViewModel_SetDefaultAnimation(client, "b_idle");
		ViewModel_SetAnimation(client, "b_draw");
	}
}

public Action SCP049_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		float engineTime = GetGameTime();
		static float delay[MAXTF2PLAYERS];
		if(delay[client] > engineTime)
			return Plugin_Handled;

		if(StrContains(sample, "activatecharge", false) != -1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/found%d.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "autochargeready", false)!=-1 || StrContains(sample, "taunts", false)!=-1)
		{
			delay[client] = engineTime+6.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/meleedare%d.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "autodejectedtie", false) != -1)
		{
			delay[client] = engineTime+15.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/049/battlecry2.mp3");
		}
		else if(StrContains(sample, "battlecry", false) != -1)
		{
			int value = GetRandomInt(1, 2);
			delay[client] = engineTime+(value*7.5);
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/battlecry%d.mp3", value);
		}
		else if(StrContains(sample, "cheers", false) != -1)
		{
			delay[client] = engineTime+3.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/cheers%d.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "cloakedspy", false) != -1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/doctor%d.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "medic_go", false)!=-1 || StrContains(sample, "head", false)!=-1 || StrContains(sample, "moveup", false)!=-1 || StrContains(sample, "medic_no", false)!=-1 || StrContains(sample, "thanks", false)!=-1 || StrContains(sample, "medic_yes", false)!=-1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/hello%d.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "goodjob", false)!=-1 || StrContains(sample, "incoming", false)!=-1 || StrContains(sample, "need", false)!=-1 || StrContains(sample, "niceshot", false)!=-1 || StrContains(sample, "sentry", false)!=-1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/greet%d.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "helpme", false) != -1)
		{
			delay[client] = engineTime+3.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/chase%d.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "jeers", false) != -1)
		{
			delay[client] = engineTime+4.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/jeers%d.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "negative", false) != -1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/neg%d.mp3", GetRandomInt(1, 2));
		}
		else if(StrContains(sample, "positive", false) != -1)
		{
			delay[client] = engineTime+2.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/pos%d.mp3", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "specialcompleted", false) != -1)
		{
			delay[client] = engineTime+4.0;
			Format(sample, PLATFORM_MAX_PATH, "scp_sf/049/kill%d.mp3", GetRandomInt(1, 5));
		}
		else
		{
			return Plugin_Handled;
		}

		for(int i; i<3; i++)
		{
			EmitSoundToAll2(sample, client, _, level, flags, _, pitch);
		}
		return Plugin_Handled;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 30;
		EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action SCP0492_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		if(StrContains(sample, "battlecry", false)!=-1 || StrContains(sample, "meleedare", false)!=-1)
		{
			Format(sample, PLATFORM_MAX_PATH, "npc/zombie/zombie_alert%d.wav", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "pains", false) != -1)
		{
			Format(sample, PLATFORM_MAX_PATH, "npc/zombie/zombie_pain%d.wav", GetRandomInt(1, 6));
		}
		else if(StrContains(sample, "paincrticial", false) != -1)
		{
			Format(sample, PLATFORM_MAX_PATH, "npc/zombie/zombie_die%d.wav", GetRandomInt(1, 3));
		}
		else
		{
			Format(sample, PLATFORM_MAX_PATH, "npc/zombie/zombie_voice_idle%d.wav", GetRandomInt(1, 14));
		}
		return Plugin_Changed;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 30;
		Format(sample, PLATFORM_MAX_PATH, "npc/zombie/foot%d.wav", GetRandomInt(1, 3));
		EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void SCP049_OnButton(int client, int button)
{
	if(button & IN_ATTACK2)
	{
		int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(entity == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
		{
			entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
			if(entity > MaxClients)
				SetActiveWeapon(client, entity);
		}
		else if(entity > MaxClients)
		{
			SetActiveWeapon(client, entity);
		}
	}

	float engineTime = GetGameTime();
	if(Revive[client].GoneAt > engineTime)
		return;

	Revive[client].GoneAt = engineTime+0.67;
	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
		return;

	static float pos1[3], ang1[3];
	GetClientEyePosition(client, pos1);
	GetClientEyeAngles(client, ang1);
	ang1[0] = fixAngle(ang1[0]);
	ang1[1] = fixAngle(ang1[1]);
	for(int target=1; target<=MaxClients; target++)
	{
		if(target==client || !IsValidClient(target) || IsSpec(target) || IsFriendly(Client[client].Class, Client[target].Class))
			continue;

		static float pos2[3];
		GetClientEyePosition(target, pos2);
		if(GetVectorDistance(pos1, pos2, true) > 299999)
			continue;

		static float ang2[3], ang3[3];
		GetClientEyeAngles(target, ang2);
		GetVectorAnglesTwoPoints(pos1, pos2, ang3);

		// fix all angles
		ang3[0] = fixAngle(ang3[0]);
		ang3[1] = fixAngle(ang3[1]);

		// verify angle validity
		if(!(fabs(ang1[0] - ang3[0]) <= MAXANGLEPITCH ||
		(fabs(ang1[0] - ang3[0]) >= (360.0-MAXANGLEPITCH))))
			continue;

		if(!(fabs(ang1[1] - ang3[1]) <= MAXANGLEYAW ||
		(fabs(ang1[1] - ang3[1]) >= (360.0-MAXANGLEYAW))))
			continue;

		// ensure no wall is obstructing
		TR_TraceRayFilter(pos1, pos2, MASK_VISIBLE, RayType_EndPoint, Trace_WallsOnly);
		TR_GetEndPosition(ang3);
		if(ang3[0]!=pos2[0] || ang3[1]!=pos2[1] || ang3[2]!=pos2[2])
			continue;

		// success
		if(Revive[client].MoveAt == FAR_FUTURE)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);

			target = SpawnWeapon(client, "tf_weapon_bonesaw", 310, 80, 13, "138 ; 11 ; 252 ; 0.2", false);
			if(target > MaxClients)
			{
				ApplyStrangeRank(target, 6);
				SetEntProp(target, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", target);
			}
			
			Client[client].Extra1 = 1;

			FakeClientCommandEx(client, "voicemenu 1 6");	// Activate charge

			ViewModel_Create(client, ModelMelee);
			ViewModel_SetDefaultAnimation(client, "b_idle");
			ViewModel_SetAnimation(client, "b_draw");
		}

		Revive[client].MoveAt = engineTime+8.0;
		return;
	}

	if(Revive[client].MoveAt < engineTime)
	{
		FakeClientCommandEx(client, "voicemenu 2 4");	// Positive
		ViewModel_Destroy(client);
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
		GiveMelee(client, GetSteamAccountID(client, false));
		Client[client].Extra1 = 0;
		Revive[client].MoveAt = FAR_FUTURE;
		Revive[client].GoneAt = engineTime+2.0;
	}
}

public void SCP049_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));	
	Classes_PlayDeathAnimation(client, model, "death_scp_049", "", 0.0);
}

public void SCP049_OnKill(int client, int victim)
{
	SpawnMarker(victim, client);
}

public void SCP0492_OnKill(int client, int victim)
{
	static float pos1[3];
	GetClientAbsOrigin(client, pos1);
	for(int target=1; target<=MaxClients; target++)
	{
		if(!IsValidClient(target) || Client[target].Class!=Index049)
			continue;

		static float pos2[3];
		GetClientAbsOrigin(target, pos2);
		if(GetVectorDistance(pos1, pos2, true) < 999999)
		{
			SpawnMarker(victim, client);
			return;
		}
	}
}

public void SCP049_OnRevive(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("entindex");
	if(!IsValidClient(client))
		return;

	Event points = CreateEvent("player_escort_score", true);
	points.SetInt("player", client);
	points.SetInt("points", -2);
	points.Fire();

	int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(entity <= MaxClients)
		return;

	static char classname[64];
	GetEdictClassname(entity, classname, sizeof(classname));
	if(!StrEqual(classname, "tf_weapon_medigun"))
		return;

	int target = GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget");
	if(target <= MaxClients)
		return;

	target = GetEntPropEnt(target, Prop_Send, "m_hOwner");
	if(!IsValidClient(target) || Client[target].Class==Index0492)
		return;

	Revive[client].Index++;
	float amount = float(Revive[client].Index)*0.05;
	TF2Attrib_SetByDefIndex(entity, 7, 0.7+amount);
	if(Revive[client].Index < 41)
		SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", 1.0-Pow(10.0, (1.0-amount))/10.0);

	if(Revive[client].Index == 10)
		GiveAchievement(Achievement_Revive, client);

	Client[target].Class = Index0492;
	TF2_RespawnPlayer(target);
	Client[target].Floor = Client[client].Floor;

	SetEntProp(target, Prop_Send, "m_bDucked", true);
	SetEntityFlags(target, GetEntityFlags(target)|FL_DUCKING);

	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);

	for(int i=1; i<=MaxClients; i++)
	{
		if(target!=i && (client==i || IsFriendly(Client[i].Class, Client[client].Class)))
			Client[i].ThinkIsDead[target] = false;
	}
}

public void SCP049_Think(int client)
{
	int entity = EntRefToEntIndex(Revive[client].Index);
	if(Revive[client].MoveAt < GetGameTime())
	{
		Revive[client].MoveAt = FAR_FUTURE;
		if(!IsValidMarker(entity)) // Oh fiddlesticks, what now..
		{
			SDKUnhook(client, SDKHook_PreThink, SCP049_Think);
			if(GetClientTeam(client) == view_as<int>(TFTeam_Unassigned))
				ChangeClientTeamEx(client, TFTeam_Red);

			return;
		}

		ChangeClientTeamEx(client, view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum")));

		// get position to teleport the Marker to
		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
		SDKHook(entity, SDKHook_SetTransmit, SCP049_Transmit);
		SDKUnhook(entity, SDKHook_SetTransmit, SCP049_TransmitNone);
	}
	else if(!Enabled || Revive[client].GoneAt<GetGameTime())
	{
		SDKUnhook(client, SDKHook_PreThink, SCP049_Think);
		if(!IsPlayerAlive(client) && GetClientTeam(client)==view_as<int>(TFTeam_Unassigned))
			ChangeClientTeamEx(client, TFTeam_Red);

		if(IsValidMarker(entity))
		{
			AcceptEntityInput(entity, "Kill");
			entity = INVALID_ENT_REFERENCE;
		}
		return;
	}

	if(GetClientTeam(client)!=view_as<int>(TFTeam_Unassigned) && IsValidMarker(entity))
	{
		ChangeClientTeamEx(client, TFTeam_Unassigned);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", TFTeam_Unassigned);
	}
}

public Action SCP049_TransmitNone(int entity, int target)
{
	return Plugin_Handled;
}

public Action SCP049_Transmit(int entity, int target)
{
	return (IsValidClient(target) && Client[target].Class!=Index049) ? Plugin_Handled : Plugin_Continue;
}

static bool IsValidMarker(int marker)
{
	if(!IsValidEntity(marker))
		return false;
	
	static char buffer[64];
	GetEntityClassname(marker, buffer, sizeof(buffer));
	return StrEqual(buffer, "entity_revive_marker", false);
}

static void SpawnMarker(int victim, int client)
{
	int entity = CreateEntityByName("entity_revive_marker");
	if(entity == -1)
		return;

	int team = GetClientTeam(client);
	ChangeClientTeamEx(victim, view_as<TFTeam>(team));
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", victim);
	SetEntPropEnt(entity, Prop_Send, "m_hOwner", victim);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 2); 
	SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8); 
	SetEntProp(entity, Prop_Send, "m_fEffects", 16); 
	SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1); 
	SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", true);
	SetEntDataEnt2(victim, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, entity);
	SetEntProp(entity, Prop_Send, "m_nBody", view_as<int>(TFClass_Scout)-1); // character hologram that is shown
	SetEntProp(entity, Prop_Send, "m_nSequence", 1); 
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 1.0);
	SetEntProp(entity, Prop_Data, "m_iInitialTeamNum", team);
	SDKHook(entity, SDKHook_SetTransmit, SCP049_TransmitNone);

	DispatchSpawn(entity);
	Revive[victim].Index = EntIndexToEntRef(entity);
	Revive[victim].MoveAt = GetGameTime()+0.05;
	Revive[victim].GoneAt = Revive[victim].MoveAt+14.95;

	SDKHook(victim, SDKHook_PreThink, SCP049_Think);
}

static void GiveMelee(int client, int account, bool equip=true)
{
	int weapon = SpawnWeapon(client, "tf_weapon_bonesaw", 413, 1, 13, "138 ; 0 ; 252 ; 0.2", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 6);
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
		if(equip)
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}