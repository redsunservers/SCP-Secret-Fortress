//static const char Name[] = "049";
static const char Model[] = "models/scp_sf/049/scp049_player_7.mdl";
static const char ModelMedi[] = "models/scp_sf/049/c_arms_scp049_knife_1.mdl";
static const char ModelMelee[] = "models/scp_sf/049/c_arms_scp049_4.mdl";
static const int Health = 2125;
static const float Speed = 250.0;

//static const char NameZom[] = "0492";
//static const char ModelZom[] = "models/scp_sf/scp_049/zombieguard.mdl";
static const int HealthZom = 375;
static const float SpeedZom = 270.0;

static const char SoundPrecache[][] =
{
	"scp_sf/049/battlecry1.mp3",
	"scp_sf/049/battlecry2.mp3",
	"scp_sf/049/chase1.mp3",
	"scp_sf/049/chase2.mp3",
	"scp_sf/049/chase3.mp3",
	"scp_sf/049/cheers1.mp3",
	"scp_sf/049/cheers2.mp3",
	"scp_sf/049/cheers3.mp3",
	"scp_sf/049/cure1.mp3",
	"scp_sf/049/cure2.mp3",
	"scp_sf/049/doctor1.mp3",
	"scp_sf/049/doctor2.mp3",
	"scp_sf/049/found1.mp3",
	"scp_sf/049/found2.mp3",
	"scp_sf/049/greet1.mp3",
	"scp_sf/049/greet2.mp3",
	"scp_sf/049/greet3.mp3",
	"scp_sf/049/hello1.mp3",
	"scp_sf/049/hello2.mp3",
	"scp_sf/049/hello3.mp3",
	"scp_sf/049/jeers1.mp3",
	"scp_sf/049/jeers2.mp3",
	"scp_sf/049/kill1.mp3",
	"scp_sf/049/kill2.mp3",
	"scp_sf/049/kill3.mp3",
	"scp_sf/049/kill4.mp3",
	"scp_sf/049/kill5.mp3",
	"scp_sf/049/meleedare1.mp3",
	"scp_sf/049/meleedare2.mp3",
	"scp_sf/049/meleedare3.mp3",
	"scp_sf/049/neg1.mp3",
	"scp_sf/049/neg2.mp3",
	"scp_sf/049/pos1.mp3",
	"scp_sf/049/pos2.mp3",
	"scp_sf/049/pos3.mp3",

	"npc/zombie/foot1.wav",
	"npc/zombie/foot2.wav",
	"npc/zombie/foot3.wav",
	"npc/zombie/zombie_alert1.wav",
	"npc/zombie/zombie_alert2.wav",
	"npc/zombie/zombie_alert3.wav",
	"npc/zombie/zombie_die1.wav",
	"npc/zombie/zombie_die2.wav",
	"npc/zombie/zombie_die3.wav",
	"npc/zombie/zombie_pain1.wav",
	"npc/zombie/zombie_pain2.wav",
	"npc/zombie/zombie_pain3.wav",
	"npc/zombie/zombie_pain4.wav",
	"npc/zombie/zombie_pain5.wav",
	"npc/zombie/zombie_pain6.wav",
	"npc/zombie/zombie_voice_idle1.wav",
	"npc/zombie/zombie_voice_idle2.wav",
	"npc/zombie/zombie_voice_idle3.wav",
	"npc/zombie/zombie_voice_idle4.wav",
	"npc/zombie/zombie_voice_idle5.wav",
	"npc/zombie/zombie_voice_idle6.wav",
	"npc/zombie/zombie_voice_idle7.wav",
	"npc/zombie/zombie_voice_idle8.wav",
	"npc/zombie/zombie_voice_idle9.wav",
	"npc/zombie/zombie_voice_idle10.wav",
	"npc/zombie/zombie_voice_idle11.wav",
	"npc/zombie/zombie_voice_idle12.wav",
	"npc/zombie/zombie_voice_idle13.wav",
	"npc/zombie/zombie_voice_idle14.wav"
};

static const char Downloads[][] =
{
	"models/scp_sf/049/scp049_player_7.dx80.vtx",
	"models/scp_sf/049/scp049_player_7.dx90.vtx",
	"models/scp_sf/049/scp049_player_7.mdl",
	"models/scp_sf/049/scp049_player_7.phy",
	"models/scp_sf/049/scp049_player_7.sw.vtx",
	"models/scp_sf/049/scp049_player_7.vvd",
	"models/scp_sf/049/c_arms_scp049_4.dx80.vtx",
	"models/scp_sf/049/c_arms_scp049_4.dx90.vtx",
	"models/scp_sf/049/c_arms_scp049_4.mdl",
	"models/scp_sf/049/c_arms_scp049_4.sw.vtx",
	"models/scp_sf/049/c_arms_scp049_4.vvd",
	"models/scp_sf/049/c_arms_scp049_knife_1.dx80.vtx",
	"models/scp_sf/049/c_arms_scp049_knife_1.dx90.vtx",
	"models/scp_sf/049/c_arms_scp049_knife_1.mdl",
	"models/scp_sf/049/c_arms_scp049_knife_1.sw.vtx",
	"models/scp_sf/049/c_arms_scp049_knife_1.vvd",
	"materials/models/vinrax/scp/scp-049_clothing_diffuse4.vmt",
	"materials/models/vinrax/scp/scp-049_clothing_diffuse4.vtf",
	"materials/models/vinrax/scp/scp-049_mask_diffuse5.vmt",
	"materials/models/vinrax/scp/scp-049_mask_diffuse5.vtf",
	"sound/scp_sf/049/battlecry1.mp3",
	"sound/scp_sf/049/battlecry2.mp3",
	"sound/scp_sf/049/chase1.mp3",
	"sound/scp_sf/049/chase2.mp3",
	"sound/scp_sf/049/chase3.mp3",
	"sound/scp_sf/049/cheers1.mp3",
	"sound/scp_sf/049/cheers2.mp3",
	"sound/scp_sf/049/cheers3.mp3",
	"sound/scp_sf/049/cure1.mp3",
	"sound/scp_sf/049/cure2.mp3",
	"sound/scp_sf/049/doctor1.mp3",
	"sound/scp_sf/049/doctor2.mp3",
	"sound/scp_sf/049/found1.mp3",
	"sound/scp_sf/049/found2.mp3",
	"sound/scp_sf/049/greet1.mp3",
	"sound/scp_sf/049/greet2.mp3",
	"sound/scp_sf/049/greet3.mp3",
	"sound/scp_sf/049/hello1.mp3",
	"sound/scp_sf/049/hello2.mp3",
	"sound/scp_sf/049/hello3.mp3",
	"sound/scp_sf/049/jeers1.mp3",
	"sound/scp_sf/049/jeers2.mp3",
	"sound/scp_sf/049/kill1.mp3",
	"sound/scp_sf/049/kill2.mp3",
	"sound/scp_sf/049/kill3.mp3",
	"sound/scp_sf/049/kill4.mp3",
	"sound/scp_sf/049/kill5.mp3",
	"sound/scp_sf/049/meleedare1.mp3",
	"sound/scp_sf/049/meleedare2.mp3",
	"sound/scp_sf/049/meleedare3.mp3",
	"sound/scp_sf/049/neg1.mp3",
	"sound/scp_sf/049/neg2.mp3",
	"sound/scp_sf/049/pos1.mp3",
	"sound/scp_sf/049/pos2.mp3",
	"sound/scp_sf/049/pos3.mp3",

	"models/scp_sf/scp_049/zombieguard.dx80.vtx",
	"models/scp_sf/scp_049/zombieguard.dx90.vtx",
	"models/scp_sf/scp_049/zombieguard.mdl",
	"models/scp_sf/scp_049/zombieguard.phy",
	"models/scp_sf/scp_049/zombieguard.sw.vtx",
	"models/scp_sf/scp_049/zombieguard.vvd",
	"materials/freak_fortress_2/scp-049/zombie_049_body.vmt",
	"materials/freak_fortress_2/scp-049/zombie_049_body.vtf",
	"materials/freak_fortress_2/scp-049/zombie_049_head.vmt",
	"materials/freak_fortress_2/scp-049/zombie_049_head.vtf"
};

enum struct SCP049Enum
{
	int Index;	// Revive Marker Index / SCP-049 Revive Count
	float MoveAt;	// Revive Marker Move Timer / SCP-049 Melee Timer
	float GoneAt;	// Revive Marker Lifetime Timer / SCP-049 Tick Timer
}

static SCP049Enum Revive[MAXTF2PLAYERS];

void SCP049_Enable()
{
	HookEvent("revive_player_complete", SCP049_OnRevive);

	PrecacheModel(ModelMedi, true);
	PrecacheModel(ModelMelee, true);

	for(int i; i<sizeof(SoundPrecache); i++)
	{
		PrecacheSound(SoundPrecache[i], true);
	}

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

void SCP049_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;
	Client[client].Floor = Floor_Heavy;

	Client[client].OnAnimation = SCP049_OnAnimation;
	Client[client].OnButton = SCP049_OnButton;
	Client[client].OnDeath = SCP049_OnDeath;
	Client[client].OnKill = SCP049_OnKill;
	Client[client].OnMaxHealth = SCP049_OnMaxHealth;
	Client[client].OnSound = SCP049_OnSound;
	Client[client].OnSpeed = SCP049_OnSpeed;

	int account = GetSteamAccountID(client);

	int weapon = SpawnWeapon(client, "tf_weapon_medigun", 211, 5, 13, "7 ; 0.65 ; 9 ; 0 ; 18 ; 1 ; 252 ; 0.95 ; 292 ; 2", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 11);
		TF2Attrib_SetByDefIndex(weapon, 454, view_as<float>(1));
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
	}

	GiveMelee(client, account);

	Client[client].OnWeaponSwitch = SCP049_OnWeaponSwitch;
	Revive[client].Index = 0;
	Revive[client].GoneAt = GetEngineTime()+20.0;
	Revive[client].MoveAt = FAR_FUTURE;
}

void SCP0492_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;

	Client[client].OnKill = SCP0492_OnKill;
	Client[client].OnMaxHealth = SCP0492_OnMaxHealth;
	Client[client].OnSound = SCP0492_OnSound;
	Client[client].OnSpeed = SCP0492_OnSpeed;

	int weapon = SpawnWeapon(client, "tf_weapon_bat", 572, 50, 13, "2 ; 1.25 ; 5 ; 1.3 ; 28 ; 0.5 ; 252 ; 0.5", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 4);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public void SCP049_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP049_OnSpeed(int client, float &speed)
{
	speed = Speed;
}

public void SCP0492_OnMaxHealth(int client, int &health)
{
	health = HealthZom;
}

public void SCP0492_OnSpeed(int client, float &speed)
{
	speed = SpeedZom;
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
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			GiveMelee(client, GetSteamAccountID(client), false);
			Revive[client].MoveAt = FAR_FUTURE;
			Revive[client].GoneAt = GetEngineTime()+3.0;
		}

		ViewModel_Create(client, ModelMedi);
		ViewModel_Hide(client);
		ViewModel_SetDefaultAnimation(client, "b_idle");
		ViewModel_SetAnimation(client, "b_draw");
	}
}

public Action SCP049_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		float engineTime = GetEngineTime();
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
			EmitSoundToAll(sample, client, _, level, flags, _, pitch);
		}
		return Plugin_Handled;
	}

	if(StrContains(sample, "step", false) != -1)
	{
		volume = 1.0;
		level += 30;
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

	if(StrContains(sample, "step", false) != -1)
	{
		volume = 1.0;
		level += 30;
		Format(sample, PLATFORM_MAX_PATH, "npc/zombie/foot%d.wav", GetRandomInt(1, 3));
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void SCP049_OnButton(int client, int button)
{
	float engineTime = GetEngineTime();
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
		if(!IsValidClient(target) || IsFriendly(Class_049, Client[target].Class))
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
		TR_TraceRayFilter(pos1, pos2, (CONTENTS_SOLID|CONTENTS_AREAPORTAL|CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
		TR_GetEndPosition(ang3);
		if(ang3[0]!=pos2[0] || ang3[1]!=pos2[1] || ang3[2]!=pos2[2])
			continue;

		// success
		if(Revive[client].MoveAt == FAR_FUTURE)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);

			target = SpawnWeapon(client, "tf_weapon_fists", 195, 80, 13, "138 ; 11 ; 252 ; 0.2", false);
			if(target > MaxClients)
			{
				ApplyStrangeRank(target, 6);
				SetEntProp(target, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", target);
			}

			FakeClientCommandEx(client, "voicemenu 1 6");	// Activate charge

			ViewModel_Create(client, ModelMelee);
			ViewModel_Hide(client);
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
		GiveMelee(client, GetSteamAccountID(client));
		Revive[client].MoveAt = FAR_FUTURE;
		Revive[client].GoneAt = engineTime+2.0;
	}
}

public void SCP049_OnDeath(int client, int attacker)
{
	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		int entity = CreateEntityByName("prop_dynamic_override");
		if(!IsValidEntity(entity))
			return;

		RequestFrame(RemoveRagdoll, GetClientUserId(client));
		{
			float pos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		}
		DispatchKeyValue(entity, "skin", "0");
		DispatchKeyValue(entity, "model", Model);
		//DispatchKeyValue(entity, "DefaultAnim", "ragdoll");		
		{
			float angles[3];
			GetClientEyeAngles(client, angles);
			angles[0] = 0.0;
			angles[2] = 0.0;
			DispatchKeyValueVector(entity, "angles", angles);
		}
		DispatchSpawn(entity);

		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		SetVariantString("death_scp_049");
		AcceptEntityInput(entity, "SetAnimation");
	}
}

public void SCP049_OnKill(int client, int victim)
{
	if(GetEntityFlags(victim) & FL_ONGROUND)
		CreateSpecialDeath(victim);

	SpawnMarker(victim, client);
}

public void SCP0492_OnKill(int client, int victim)
{
	static float pos1[3];
	GetClientAbsOrigin(client, pos1);
	for(int target=1; target<=MaxClients; target++)
	{
		if(!IsValidClient(target) || Client[target].Class!=Class_049)
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
	if(!IsValidClient(target))
		return;

	Revive[client].Index++;
	TF2Attrib_SetByDefIndex(entity, 7, 0.7+(Revive[client].Index)*0.05);
	if(Revive[client].Index < 41)
		SetEntPropFloat(entity, Prop_Send, "m_flChargeLevel", 1.0-Pow(10.0, (1.0-(0.05*Revive[client].Index)))/10.0);

	if(Revive[client].Index == 10)
		GiveAchievement(Achievement_Revive, client);

	Client[target].Class = Class_0492;
	AssignTeam(target);
	RespawnPlayer(target);
	Client[target].Floor = Client[client].Floor;

	SetEntProp(target, Prop_Send, "m_bDucked", true);
	SetEntityFlags(target, GetEntityFlags(target)|FL_DUCKING);

	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
}

public void SCP049_Think(int client)
{
	if(Revive[client].MoveAt < GetEngineTime())
	{
		Revive[client].MoveAt = FAR_FUTURE;
		int entity = EntRefToEntIndex(Revive[client].Index);
		if(!IsValidMarker(entity)) // Oh fiddlesticks, what now..
		{
			SDKUnhook(client, SDKHook_PreThink, SCP049_Think);
			if(GetClientTeam(client) == view_as<int>(TFTeam_Unassigned))
				ChangeClientTeamEx(client, TFTeam_Red);

			return;
		}

		// get position to teleport the Marker to
		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
		SDKHook(entity, SDKHook_SetTransmit, SCP049_Transmit);
		SDKUnhook(entity, SDKHook_SetTransmit, SCP049_TransmitNone);
	}
	else if(!Enabled || Revive[client].GoneAt<GetEngineTime())
	{
		SDKUnhook(client, SDKHook_PreThink, SCP049_Think);
		if(!IsPlayerAlive(client) && GetClientTeam(client)==view_as<int>(TFTeam_Unassigned))
			ChangeClientTeamEx(client, TFTeam_Red);

		int entity = EntRefToEntIndex(Revive[client].Index);
		if(!IsValidMarker(entity))
			return;

		AcceptEntityInput(entity, "Kill");
		entity = INVALID_ENT_REFERENCE;
	}
}

public Action SCP049_TransmitNone(int entity, int target)
{
	return Plugin_Handled;
}

public Action SCP049_Transmit(int entity, int target)
{
	return (IsValidClient(target) && Client[target].Class!=Class_049) ? Plugin_Handled : Plugin_Continue;
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
	Revive[victim].MoveAt = GetEngineTime()+0.05;
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