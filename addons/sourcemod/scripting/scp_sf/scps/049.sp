//static const char Name[] = "049";
//static const char Model[] = "models/freak_fortress_2/scp-049/scp049.mdl";
static const int Health = 2125;
static const float Speed = 250.0;

//static const char NameZom[] = "0492";
//static const char ModelZom[] = "models/scp_sf/scp_049/zombieguard.mdl";
static const int HealthZom = 375;
static const float SpeedZom = 270.0;

static const char Downloads[][] =
{
	"models/freak_fortress_2/scp-049/scp049.dx80.vtx",
	"models/freak_fortress_2/scp-049/scp049.dx90.vtx",
	"models/freak_fortress_2/scp-049/scp049.mdl",
	"models/freak_fortress_2/scp-049/scp049.phy",
	"models/freak_fortress_2/scp-049/scp049.sw.vtx",
	"models/freak_fortress_2/scp-049/scp049.vvd",
	"materials/freak_fortress_2/scp-049/body.vmt",
	"materials/freak_fortress_2/scp-049/body.vtf",
	"materials/freak_fortress_2/scp-049/helmet.vmt",
	"materials/freak_fortress_2/scp-049/helmet.vtf",
	"materials/freak_fortress_2/scp-049/scp-049_body.vmt",
	"materials/freak_fortress_2/scp-049/scp-049_body.vtf",
	"materials/freak_fortress_2/scp-049/scp-049_mask.vmt",
	"materials/freak_fortress_2/scp-049/scp-049_mask.vtf",

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
	int Index;
	float MoveAt;
	float GoneAt;
}

static SCP049Enum Revive[MAXTF2PLAYERS];

void SCP049_Enable()
{
	HookEvent("revive_player_complete", SCP049_OnRevive);

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

	Client[client].OnKill = SCP049_OnKill;
	Client[client].OnMaxHealth = SCP049_OnMaxHealth;
	Client[client].OnSpeed = SCP049_OnSpeed;

	int account = GetSteamAccountID(client);

	int weapon = SpawnWeapon(client, "tf_weapon_medigun", 211, 5, 13, "7 ; 0.7 ; 9 ; 0 ; 18 ; 1 ; 252 ; 0.95 ; 292 ; 2", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 11);
		TF2Attrib_SetByDefIndex(weapon, 292, view_as<float>(1));
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
	}

	weapon = SpawnWeapon(client, "tf_weapon_bonesaw", 173, 80, 13, "1 ; 0.01 ; 137 ; 101 ; 138 ; 1001 ; 252 ; 0.2", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 6);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

void SCP0492_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;

	Client[client].OnMaxHealth = SCP0492_OnMaxHealth;
	Client[client].OnSpeed = SCP0492_OnSpeed;

	int weapon = SpawnWeapon(client, "tf_weapon_bat", 572, 50, 13, "1 ; 0.01 ; 5 ; 1.3 ; 28 ; 0.5 ; 137 ; 101 ; 138 ; 125 ; 252 ; 0.5", false);
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

public void SCP049_OnKill(int client, int victim)
{
	if(GetEntityFlags(victim) & FL_ONGROUND)
		CreateSpecialDeath(victim);

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

	entity = GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget");
	if(entity <= MaxClients)
		return;

	entity = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	if(!IsValidClient(entity))
		return;

	if(++Client[client].Disarmer == 10)
		GiveAchievement(Achievement_Revive, client);

	Client[entity].Class = Class_0492;
	AssignTeam(entity);
	RespawnPlayer(entity);
	Client[entity].Floor = Client[client].Floor;

	SetEntProp(entity, Prop_Send, "m_bDucked", true);
	SetEntityFlags(entity, GetEntityFlags(entity)|FL_DUCKING);

	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
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