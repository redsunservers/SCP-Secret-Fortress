#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/scp_sf/049/scp049_player_7.dx80.vtx",
	"models/scp_sf/049/scp049_player_7.dx90.vtx",
	"models/scp_sf/049/scp049_player_7.mdl",
	"models/scp_sf/049/scp049_player_7.phy",
	"models/scp_sf/049/scp049_player_7.vvd",
	"models/scp_sf/049/c_arms_scp049_4.dx80.vtx",
	"models/scp_sf/049/c_arms_scp049_4.dx90.vtx",
	"models/scp_sf/049/c_arms_scp049_4.mdl",
	"models/scp_sf/049/c_arms_scp049_4.vvd",
	"models/scp_sf/049/c_arms_scp049_knife_1.dx80.vtx",
	"models/scp_sf/049/c_arms_scp049_knife_1.dx90.vtx",
	"models/scp_sf/049/c_arms_scp049_knife_1.mdl",
	"models/scp_sf/049/c_arms_scp049_knife_1.vvd",
	"materials/models/vinrax/scp/scp-049_clothing_diffuse4.vmt",
	"materials/models/vinrax/scp/scp-049_clothing_diffuse4.vtf",
	"materials/models/vinrax/scp/scp-049_mask_diffuse5.vmt",
	"materials/models/vinrax/scp/scp-049_mask_diffuse5.vtf"
};

static const char SoundDownloads[][] =
{
	"scpm/scp049/chase.mp3",
	"scpm/scp049/battlecry1.mp3",
	"scpm/scp049/battlecry2.mp3",
	"scpm/scp049/chase1.mp3",
	"scpm/scp049/chase2.mp3",
	"scpm/scp049/chase3.mp3",
	"scpm/scp049/cheers1.mp3",
	"scpm/scp049/cheers2.mp3",
	"scpm/scp049/cheers3.mp3",
	"scpm/scp049/cure1.mp3",
	"scpm/scp049/cure2.mp3",
	"scpm/scp049/doctor1.mp3",
	"scpm/scp049/doctor2.mp3",
	"scpm/scp049/found1.mp3",
	"scpm/scp049/found2.mp3",
	"scpm/scp049/greet1.mp3",
	"scpm/scp049/greet2.mp3",
	"scpm/scp049/greet3.mp3",
	"scpm/scp049/hello1.mp3",
	"scpm/scp049/hello2.mp3",
	"scpm/scp049/hello3.mp3",
	"scpm/scp049/jeers1.mp3",
	"scpm/scp049/jeers2.mp3",
	"scpm/scp049/kill1.mp3",
	"scpm/scp049/kill2.mp3",
	"scpm/scp049/kill3.mp3",
	"scpm/scp049/kill4.mp3",
	"scpm/scp049/kill5.mp3",
	"scpm/scp049/meleedare1.mp3",
	"scpm/scp049/meleedare2.mp3",
	"scpm/scp049/meleedare3.mp3",
	"scpm/scp049/neg1.mp3",
	"scpm/scp049/neg2.mp3",
	"scpm/scp049/pos1.mp3",
	"scpm/scp049/pos2.mp3",
	"scpm/scp049/pos3.mp3"
};

static const char PlayerModel[] = "models/scp_sf/049/scp049_player_7.mdl";
static const char ViewModelMelee[] = "models/scp_sf/049/c_arms_scp049_4.mdl";
static const char ViewModelKnife[] = "models/scp_sf/049/c_arms_scp049_knife_1.mdl";
static const char ChaseSound[] = "#scpm/scp049/chase.mp3";

static int BossIndex;

public void SCP049_Precache(int index)
{
	BossIndex = index;

	PrecacheModel(PlayerModel);
	PrecacheModel(ViewModelMelee);
	PrecacheModel(ViewModelKnife);
	PrecacheSound(ChaseSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
	
	char buffer[PLATFORM_MAX_PATH];
	for(int i; i < sizeof(SoundDownloads); i++)
	{
		PrecacheSound(SoundDownloads[i]);
		FormatEx(buffer, sizeof(buffer), "sound/%s", SoundDownloads[i]);
		CheckAndAddFileToDownloadsTable(buffer);
	}

	// Assume all Revive Markers belong to 049 while active
	HookEvent("revive_player_complete", RevivePlayerComplete);
}

public void SCP049_Unload()
{
	UnhookEvent("revive_player_complete", RevivePlayerComplete);
}

public void SCP049_Create(int client)
{
	Default_Create(client);
}

public TFClassType SCP049_TFClass()
{
	return TFClass_Medic;
}

public void SCP049_Spawn(int client)
{
	ViewModel_DisableArms(client);
	if(!GoToNamedSpawn(client, "scp_spawn_049"))
		Default_Spawn(client);
}

public void SCP049_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	if(weapons)
	{
		int entity = Items_GiveByIndex(client, 954, _, "tf_weapon_bonesaw");
		if(entity != -1)
		{
			Attrib_Set(entity, "crit mod disabled", 1.0);
			Attrib_Set(entity, "max health additive bonus", 650.0);
			Attrib_Set(entity, "move speed penalty", 0.72);
			Attrib_Set(entity, "dmg penalty vs players", 11.0);
			Attrib_Set(entity, "damage force reduction", 0.8);
			Attrib_Set(entity, "cancel falling damage", 1.0);
			Attrib_Set(entity, "airblast vulnerability multiplier", 0.8);
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);

			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", ModelEmpty);

			TF2U_SetPlayerActiveWeapon(client, entity);
			
			SetEntityHealth(client, 800);
		}

		entity = Items_GiveByIndex(client, 411);
		if(entity != -1)
		{
			Attrib_Set(entity, "heal rate bonus", 0.5);
			Attrib_Set(entity, "ubercharge rate bonus", 0.5);
			Attrib_Set(entity, "overheal penalty", 0.0);
			Attrib_Set(entity, "reduced_healing_from_medics", 0.1);
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);

			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", ModelEmpty);
		}
	}
}

public void SCP049_WeaponSwitch(int client)
{
	if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
	{
		ViewModel_Create(client, ViewModelMelee, "b_idle");
		ViewModel_SetAnimation(client, "b_draw");
	}
	else
	{
		ViewModel_Create(client, ViewModelKnife, "b_idle");
		ViewModel_SetAnimation(client, "b_draw");
		Client(client).ControlProgress = 1;
	}
}

public void SCP049_Remove(int client)
{
	Default_Remove(client);
}

public float SCP049_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite)
{
	strcopy(theme, sizeof(theme), ChaseSound);
	return 14.8;
}

public Action SCP049_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!Client(client).ControlProgress)
	{
		if(Client(client).KeyHintUpdateAt < GetGameTime())
		{
			Client(client).KeyHintUpdateAt = GetGameTime() + 0.5;

			if(!(buttons & IN_SCORE))
			{
				static char buffer[64];
				Format(buffer, sizeof(buffer), "%T", "SCP049 Controls", client);
				PrintKeyHintText(client, buffer);
			}
		}
	}

	return Plugin_Continue;
}

public Action SCP049_CalcIsAttackCritical(int client, int weapon, const char[] weaponname, bool &result)
{
	ViewModel_SetAnimation(client, (GetURandomInt() % 2) ? "attack1" : "attack2");
	return Plugin_Continue;
}

public void SCP049_PlayerKilled(int client, int victim, bool fakeDeath)
{
	if(!fakeDeath)
		SpawnMarker(victim, client);
}

static void SpawnMarker(int victim, int client)
{
	int entity = CreateEntityByName("entity_revive_marker");
	if(entity == -1)
		return;

	int team = GetClientTeam(client);
	ChangeClientTeam(victim, team);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", victim);
	SetEntPropEnt(entity, Prop_Send, "m_hOwner", victim);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 2); 
	SetEntProp(entity, Prop_Send, "m_usSolidFlags", 8); 
	SetEntProp(entity, Prop_Send, "m_fEffects", 16); 
	SetEntProp(entity, Prop_Send, "m_iTeamNum", team);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1); 
	SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", true);
	SetEntDataEnt2(victim, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, entity);
	SetEntProp(entity, Prop_Send, "m_nBody", view_as<int>(TF2_GetPlayerClass(victim))-1); // character hologram that is shown
	SetEntProp(entity, Prop_Send, "m_nSequence", 1); 
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 1.0);
	SetEntProp(entity, Prop_Data, "m_iInitialTeamNum", team);
	SDKHook(entity, SDKHook_SetTransmit, TransmitToDoctor);

	DispatchSpawn(entity);

	CreateTimer(20.0, Timer_ExpireReviveMarker, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

static Action Timer_ExpireReviveMarker(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != -1)
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
		if(client != -1 && !IsPlayerAlive(client) && GetClientTeam(client) == TFTeam_Bosses)
			ChangeClientTeam(client, TFTeam_Humans);
		
		RemoveEntity(entity);
	}

	return Plugin_Continue;
}

static Action TransmitToDoctor(int entity, int client)
{
	if(client > 0 && client <= MaxClients)
	{
		if(!IsPlayerAlive(client) || Client(client).Boss != BossIndex)
			return Plugin_Stop;
	}

	return Plugin_Continue;
}

static void RevivePlayerComplete(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("entindex");
	if(client < 1 || client > MaxClients)
		return;
	
	int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(entity != -1)
		return;

	char classname[36];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(StrContains(classname, "tf_weapon_medigun") != 0)
		return;

	int target = GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget");
	if(target <= MaxClients)
		return;

	target = GetEntPropEnt(target, Prop_Send, "m_hOwner");
	if(target == -1)
		return;
	
	SetEntProp(target, Prop_Send, "m_bDucked", true);
	SetEntityFlags(target, GetEntityFlags(target)|FL_DUCKING);

	float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);

	CreateTimer(0.2, TurnToZombie, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);
}

static Action TurnToZombie(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsPlayerAlive(client))
	{
		Client(client).SilentTalk = true;
		Client(client).Minion = true;
		Client(client).NoEscape = true;
		
		SetVariantString(NULL_STRING);
		AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
		
		TFClassType class = TF2_GetPlayerClass(client);
		SetEntProp(client, Prop_Send, "m_bForcedSkin", true);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", (class == TFClass_Spy) ? 23 : 5);
		
		int entity = CreateEntityByName("tf_wearable");
		if(entity != -1)
		{
			static const int VoodooIndex[] =  {-1, 5617, 5625, 5618, 5620, 5622, 5619, 5624, 5623, 5621};

			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", VoodooIndex[class]);
			SetEntProp(entity, Prop_Send, "m_bInitialized", true);
			SetEntProp(entity, Prop_Send, "m_iEntityQuality", 0);
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", 1);

			DispatchSpawn(entity);
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		}

		int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		int i;
		while(TF2_GetItem(client, entity, i))
		{
			if(entity != melee)
			{
				TF2_RemoveItem(client, entity);
				continue;
			}

			Attrib_Set(entity, "crit mod disabled hidden", 1.0);
			Attrib_Set(entity, "major move speed bonus", 1.15);
		}

		SDKCall_SetSpeed(client);
	}
	
	return Plugin_Continue;
}
