#pragma semicolon 1
#pragma newdecls required

#define _included_smjm08

static const float NoclipAccel = 10.0;
static const float NoclipSpeed = 0.8;
static const char Overlay[] = "effects/tvscreen_noise002a";
static const char Theme[] = "#scp_sf/sjm08/theme.mp3";

static bool Hooked;

void SJM08_Clean()	// OnRoundEnd, OnPluginEnd
{
	if(Hooked)
	{
		ConVar_Remove("sv_noclipaccelerate");
		ConVar_Remove("sv_noclipspeed");
		UnhookEvent("player_death", SJM08_PlayerDeath);
		Hooked = false;

		int flags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);

		for(int target=1; target<=MaxClients; target++)
		{
			if(StrEqual(Client[target].CurrentSong, Theme))
			{
				Client[target].NextSongAt = 0.0;
				ClientCommand(target, "r_screenoverlay off");
			}
		}

		SetCommandFlags("r_screenoverlay", flags);
	}
}

public bool SJM08_Create(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_club", 880, 8, 14, "1 ; 0.615385 ; 5 ; 3 ; 28 ; 0.5 ; 206 ; 0.1 ; 252 ; 0 ; 4328 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 8);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	weapon = GiveWearable(client, 993);
	if(weapon > MaxClients)
		ApplyStrangeHatRank(weapon, 5);

	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 0, 0, 0);
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", false);

	if(!Hooked)
	{
		ConVar_Add("sv_noclipaccelerate", NoclipAccel);
		ConVar_Add("sv_noclipspeed", NoclipSpeed);
		HookEvent("player_death", SJM08_PlayerDeath);
		Hooked = true;
	}

	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	return false;
}

public void SJM08_OnButton(int client, int button)
{
	float engineTime = GetGameTime();
	if(Client[client].Extra3 > engineTime)
		return;

	Client[client].Extra3 = engineTime+1.5;

	if(NoMusic || NoMusicRound)
		return;

	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);

	static float pos1[3];
	GetClientAbsOrigin(client, pos1);
	for(int target=1; target<=MaxClients; target++)
	{
		if(target==client || !IsValidClient(target) || IsSpec(target) || IsFriendly(Client[client].Class, Client[target].Class))
			continue;

		bool inState = StrEqual(Client[target].CurrentSong, Theme);

		static float pos2[3];
		GetClientEyePosition(target, pos2);
		bool inRange = GetVectorDistance(pos1, pos2, true) < (inState ? 999999 : 799999);

		if(inRange)
		{
			bool inMusic = !StrContains(Client[target].CurrentSong, "#scp_sf/sjm");
			if(inState || !inMusic)
				ClientCommand(target, "r_screenoverlay \"%s\"", Overlay);

			if(!inMusic)
				ChangeSong(target, FAR_FUTURE, Theme, 3);
		}
		else if(inState)
		{
			ClientCommand(target, "r_screenoverlay off");
			Client[target].NextSongAt = 0.0;
		}
	}

	SetCommandFlags("r_screenoverlay", flags);
}

public void SJM08_OnDeath(int client, Event event)
{
	Classes_MoveToSpec(client, event);

	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);

	for(int target=1; target<=MaxClients; target++)
	{
		if(StrEqual(Client[target].CurrentSong, Theme))
		{
			Client[target].NextSongAt = 0.0;
			ClientCommand(target, "r_screenoverlay off");
		}
	}

	SetCommandFlags("r_screenoverlay", flags);
}

public void SJM08_OnKill(int client, int victim)
{
	CreateTimer(1.0, SJM08_KillTimer, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
}

public Action SJM08_KillTimer(Handle timer, int userid)
{
	if(Enabled)
	{
		int client = GetClientOfUserId(userid);
		if(client && IsClientInGame(client))
		{
			int entity = -1;
			ArrayList spawns = new ArrayList();
			while((entity=FindEntityByClassname(entity, "info_target")) != -1)
			{
				static char name[16];
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(!StrContains(name, "scp_sjm08", false))
					spawns.Push(entity);
			}

			int length = spawns.Length;
			if(length)
				entity = spawns.Get(GetRandomInt(0, length-1));

			delete spawns;

			if(entity != -1)
			{
				TF2_RespawnPlayer(client);

				static float pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(client, pos, NULL_VECTOR, TRIPLE_D);
			}
		}
	}
	return Plugin_Continue;
}

public Action SJM08_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		Format(sample, PLATFORM_MAX_PATH, "scp_sf/sjm08/voice%d.mp3", GetRandomInt(1, 4));
		EmitSoundToAll2(sample, client, channel, level, flags, volume);
		EmitSoundToAll2(sample, client, channel, level, flags, volume);
		return Plugin_Handled;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		StopSound(client, SNDCHAN_AUTO, sample);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void SJM08_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
	{
		int flags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
		ClientCommand(client, "r_screenoverlay off");
		SetCommandFlags("r_screenoverlay", flags);
	}
}

static int GiveWearable(int client, int index)
{
	int entity = CreateEntityByName("tf_wearable");
	if(IsValidEntity(entity))
	{
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(entity, Prop_Send, "m_bInitialized", true);
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", 14);
		SetEntProp(entity, Prop_Send, "m_iEntityLevel", 8);

		DispatchSpawn(entity);

		SDKCall_EquipWearable(client, entity);

		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
	}
	return entity;
}