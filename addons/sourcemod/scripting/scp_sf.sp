#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <tf2items>
#include <morecolors>
#include <tf2attributes>
#include <memorypatch>
#include <dhooks>
#include <tf_econ_data>
#include <tf2utils>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#define REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <sendproxy>
#define REQUIRE_EXTENSIONS

void DisplayCredits(int i)
{
	PrintToConsole(i, "Useful Stocks | sarysa | forums.alliedmods.net/showthread.php?t=309245");
	PrintToConsole(i, "SDK/DHooks Functions | Mikusch, 42 | github.com/Mikusch/fortress-royale");
	PrintToConsole(i, "Medi-Gun Hooks | naydef | forums.alliedmods.net/showthread.php?t=311520");
	PrintToConsole(i, "ChangeTeamEx | Benoist3012 | forums.alliedmods.net/showthread.php?t=314271");
	PrintToConsole(i, "Client Eye Angles | sarysa | forums.alliedmods.net/showthread.php?t=309245");
	PrintToConsole(i, "Revive Markers | 93SHADoW, sarysa | forums.alliedmods.net/showthread.php?t=248320");
	PrintToConsole(i, "Transmit Outlines | nosoop | forums.alliedmods.net/member.php?u=252787");
	PrintToConsole(i, "Move Speed Unlocker | xXDeathreusXx | forums.alliedmods.net/member.php?u=224722");

	PrintToConsole(i, "Chaos, SCP-049-2 Rigs | DoctorKrazy | forums.alliedmods.net/member.php?u=288676");
	PrintToConsole(i, "MTF Rig | JuegosPablo | forums.alliedmods.net/showthread.php?t=308656");
	PrintToConsole(i, "SCP-173 Port | RavensBro | forums.alliedmods.net/showthread.php?t=203464");
	PrintToConsole(i, "SCP Animations | Baget | steamcommunity.com/profiles/76561198097667312");
	PrintToConsole(i, "Soundtracks | Jacek \"Burnert\" Rogal");

	PrintToConsole(i, "Cosmic Inspiration | Marxvee | forums.alliedmods.net/member.php?u=289257");
	PrintToConsole(i, "Map/Model Development | Artvin | forums.alliedmods.net/member.php?u=304206");
}

#define MAJOR_REVISION	"3"
#define MINOR_REVISION	"1"
#define STABLE_REVISION	"0"
#define PLUGIN_VERSION	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#include "scp_sf/defines.sp"

public Plugin myinfo =
{
	name		=	"SCP: Secret Fortress",
	author		=	"Batfoxkid",
	description	=	"WHY DID YOU THROW A GRENADE INTO THE ELEVA-",
	version		=	PLUGIN_VERSION
};

enum AccessEnum
{
	Access_Main = 0,
	Access_Armory,
	Access_Exit,
	Access_Warhead,
	Access_Checkpoint,
	Access_Intercom
}

enum ClassSpawnEnum
{
	ClassSpawn_Other = 0,
	ClassSpawn_RoundStart,
	ClassSpawn_WaveSystem,
	ClassSpawn_Death,
	ClassSpawn_Escape,
	ClassSpawn_Revive
}

bool Enabled = false;
bool NoMusic = false;
bool ChatHook = false;

#if defined _sourcecomms_included
bool SourceComms = false;		// SourceComms++
#endif

#if defined _basecomm_included
bool BaseComm = false;		// BaseComm
#endif

Handle HudPlayer;
Handle HudClass;
Handle HudGame;

Cookie CookieTraining;
Cookie CookieColor;
Cookie CookieDClass;
Cookie CookieKarma;

ConVar CvarFriendlyFire;
ConVar CvarSpeedMulti;
ConVar CvarSpeedMax;
ConVar CvarAchievement;
ConVar CvarChatHook;
ConVar CvarVoiceHook;
ConVar CvarSendProxy;
ConVar CvarKarma;
ConVar CvarKarmaRatio;
ConVar CvarKarmaMin;
ConVar CvarKarmaMax;
ConVar CvarAllowCosmetics;
float NextHintAt = FAR_FUTURE;
float RoundStartAt;
float EndRoundIn;
bool NoMusicRound;

enum struct ClientEnum
{
	int Class;
	int Colors[4];
	int ColorBlind[3];
	int QueueIndex;

	bool IsVip;
	bool CanTalkTo[MAXTF2PLAYERS];
	bool ThinkIsDead[MAXTF2PLAYERS];

	TFClassType PrefClass;
	TFClassType CurrentClass;
	TFClassType WeaponClass;

	bool HelpSprint;
	bool UseBuffer;

	int Extra1;
	int Extra2;
	float Extra3;

	int Floor;
	int Disarmer;
	int DownloadMode;
	int Kills;
	int GoodKills;
	int BadKills;
	
	int PreDamageWeapon;
	int PreDamageHealth;

	float IdleAt;
	float ComFor;
	float IsCapping;
	float InvisFor;
	float FreezeFor;
	float ChatIn;
	float HudIn;
	float ChargeIn;
	float AloneIn;
	float Cooldown;
	float IgnoreTeleFor;
	float Pos[3];
	float NextReactTime;
	float NextPickupReactTime;
	float LastDisarmedTime;
	float LastWeaponTime;
	float KarmaPoints[MAXTF2PLAYERS];

	// Sprinting
	bool Sprinting;
	float SprintPower;

	// Music
	float NextSongAt;
	int CurrentVolume;
	char CurrentSong[PLATFORM_MAX_PATH];

	void ResetThinkIsDead()
	{
		for(int i=1; i<=MaxClients; i++)
		{
			this.ThinkIsDead[i] = false;
		}
	}
}

ClientEnum Client[MAXTF2PLAYERS];

#include "scp_sf/stocks.sp"
#include "scp_sf/achievements.sp"
#include "scp_sf/classes.sp"
#include "scp_sf/configs.sp"
#include "scp_sf/convars.sp"
#include "scp_sf/dhooks.sp"
#include "scp_sf/forwards.sp"
#include "scp_sf/gamemode.sp"
#include "scp_sf/items.sp"
#include "scp_sf/memorypatches.sp"
#include "scp_sf/natives.sp"
#include "scp_sf/sdkcalls.sp"
#include "scp_sf/sdkhooks.sp"
#include "scp_sf/targetfilters.sp"
#include "scp_sf/viewchanges.sp"
#include "scp_sf/viewmodels.sp"

#include "scp_sf/scps/018.sp"
#include "scp_sf/scps/035.sp"
#include "scp_sf/scps/049.sp"
#include "scp_sf/scps/076.sp"
#include "scp_sf/scps/096.sp"
#include "scp_sf/scps/106.sp"
#include "scp_sf/scps/173.sp"
#include "scp_sf/scps/457.sp"
#include "scp_sf/scps/939.sp"
//#include "scp_sf/scps/sjm08.sp"

#include "scp_sf/maps/crypto_forest.sp"
#include "scp_sf/maps/frostbite.sp"
#include "scp_sf/maps/ikea.sp"
#include "scp_sf/maps/szf.sp"

// SourceMod Events

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	#if defined _SENDPROXYMANAGER_INC_
	MarkNativeAsOptional("SendProxy_Hook");
	MarkNativeAsOptional("SendProxy_HookArrayProp");
	#endif

	#if defined _sourcecomms_included
	MarkNativeAsOptional("SourceComms_GetClientGagType");
	MarkNativeAsOptional("SourceComms_GetClientMuteType");
	#endif

	#if defined _basecomm_included
	MarkNativeAsOptional("BaseComm_IsClientGagged");
	MarkNativeAsOptional("BaseComm_IsClientMuted");
	#endif

	Forward_Setup();
	Native_Setup();
	RegPluginLibrary("scp_sf");
	return APLRes_Success;
}

public void OnPluginStart()
{
	Client[0].CurrentClass = TFClass_Spy;
	Client[0].WeaponClass = TFClass_Spy;
	Client[0].NextSongAt = FAR_FUTURE;
	Client[0].ColorBlind[0] = -1;
	Client[0].ColorBlind[1] = -1;
	Client[0].ColorBlind[2] = -1;

	for(int i = 0; i <= MaxClients; i++) {
		Client[i].QueueIndex = -1;
	}

	ConVar_Setup();
	SDKHook_Setup();

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroy, EventHookMode_Pre);
	HookEvent("teamplay_win_panel", OnWinPanel, EventHookMode_Pre);

	RegConsoleCmd("scp", Command_MainMenu, "View SCP: Secret Fortress main menu");

	RegConsoleCmd("scpinfo", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scp_info", Command_HelpClass, "View info about your current class");

	RegConsoleCmd("scpcolor", Command_ColorBlind, "Sets your perfered HUD color.");
	RegConsoleCmd("scp_color", Command_ColorBlind, "Sets your perfered HUD color.");
	RegConsoleCmd("scpcolorblind", Command_ColorBlind, "Sets your perfered HUD color.");
	RegConsoleCmd("scp_colorblind", Command_ColorBlind, "Sets your perfered HUD color.");

	RegAdminCmd("scp_forceclass", Command_ForceClass, ADMFLAG_SLAY, "Usage: scp_forceclass <target> <class>.  Forces that class to be played.");
	RegAdminCmd("scp_giveitem", Command_ForceItem, ADMFLAG_SLAY, "Usage: scp_giveitem <target> <index>.  Gives a specific item.");
	RegAdminCmd("scp_giveammo", Command_ForceAmmo, ADMFLAG_SLAY, "Usage: scp_giveammo <target> <type>.  Gives a specific ammo.");
	RegAdminCmd("scp_setkarma", Command_ForceKarma, ADMFLAG_SLAY, "Usage: scp_setkarma <target> <0-100>. Sets a specific karma level.");
	RegAdminCmd("scp_preventroundwin", Command_PreventWin, ADMFLAG_SLAY, "Usage: scp_preventroundwin <0/1>. Ignore round end conditions for debugging.");

	AddCommandListener(OnBlockCommand, "explode");
	AddCommandListener(OnBlockCommand, "kill");
	AddCommandListener(OnJoinClass, "joinclass");
	AddCommandListener(OnJoinClass, "join_class");
	AddCommandListener(OnJoinSpec, "spectate");
	AddCommandListener(OnJoinTeam, "jointeam");
	AddCommandListener(OnJoinAuto, "autoteam");
	AddCommandListener(OnVoiceMenu, "voicemenu");
	AddCommandListener(OnDropItem, "dropitem");

	SetCommandFlags("firstperson", GetCommandFlags("firstperson") & ~FCVAR_CHEAT);

	#if defined _sourcecomms_included
	SourceComms = LibraryExists("sourcecomms++");
	#endif

	#if defined _basecomm_included
	BaseComm = LibraryExists("basecomm");
	#endif

	HudPlayer = CreateHudSynchronizer();
	HudClass = CreateHudSynchronizer();
	HudGame = CreateHudSynchronizer();

	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);
	AddTempEntHook("Player Decal", OnPlayerSpray);

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("scp_sf.phrases");

	CookieTraining = new Cookie("scp_cookie_training", "Status on learning the SCP gamemode", CookieAccess_Public);
	CookieColor = new Cookie("scp_cookie_colorblind", "Color blind mode settings", CookieAccess_Protected);
	CookieDClass = new Cookie("scp_cookie_dboimurder", "Achievement Status", CookieAccess_Protected);
	CookieKarma = new Cookie("scp_cookie_karma", "Karma level", CookieAccess_Protected);

	GameData gamedata = LoadGameConfigFile("scp_sf");
	if(gamedata)
	{
		SDKCall_Setup(gamedata);
		DHook_Setup(gamedata);
		MemoryPatch_Setup(gamedata);
		
		delete gamedata;
	}
	else
	{
		LogError("[Gamedata] Could not find scp_sf.txt");
	}

	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;

		OnClientPutInServer(i);
		OnClientPostAdminCheck(i);
	}
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _basecomm_included
	if(StrEqual(name, "basecomm"))
	{
		BaseComm = true;
		return;
	}
	#endif

	#if defined _sourcecomms_included
	if(StrEqual(name, "sourcecomms++"))
		SourceComms = true;
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _basecomm_included
	if(StrEqual(name, "basecomm"))
	{
		BaseComm = false;
		return;
	}
	#endif

	#if defined _sourcecomms_included
	if(StrEqual(name, "sourcecomms++"))
		SourceComms = false;
	#endif
}

// Game Events

public void OnMapStart()
{
	Enabled = false;
	NoMusic = false;

	char buffer[16];
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrEqual(buffer, "scp_nomusic", false))
			continue;

		NoMusic = true;
		break;
	}
	
	while((entity=FindEntityByClassname(entity, "tf_player_manager")) != -1)
	{
		// Hook now rather than when spawned, incase the plugin is loaded in late
		SDKHook(entity, SDKHook_ThinkPost, OnPlayerManagerThink);		
		break;
	}

	if(CvarSendProxy.BoolValue)
	{
		#if defined _SENDPROXYMANAGER_INC_
		if(GetFeatureStatus(FeatureType_Native, "SendProxy_HookArrayProp")==FeatureStatus_Available)
		{
			entity = FindEntityByClassname(-1, "tf_player_manager");
			if(entity > MaxClients)
			{
				for(int i=1; i<=MaxClients; i++)
				{
					#if defined SENDPROXY_LIB
					//If sendproxy in server is not per-client, we'll just have to use basic way instead
					if(GetFeatureStatus(FeatureType_Native, "SendProxy_HookPropChangeSafe")==FeatureStatus_Available)
						SendProxy_HookArrayProp(entity, "m_bAlive", i, Prop_Int, SendProp_OnAliveMulti);
					else
						SendProxy_HookArrayProp(entity, "m_bAlive", i, Prop_Int, SendProp_OnAlive);
					#else
					SendProxy_HookArrayProp(entity, "m_bAlive", i, Prop_Int, SendProp_OnAlive);
					#endif
					
					SendProxy_HookArrayProp(entity, "m_iTeam", i, Prop_Int, SendProp_OnTeam);
					SendProxy_HookArrayProp(entity, "m_iPlayerClass", i, Prop_Int, SendProp_OnClass);
					SendProxy_HookArrayProp(entity, "m_iPlayerClassWhenKilled", i, Prop_Int, SendProp_OnClass);
				}
			}
		}
		#endif
	}

	DHook_MapStart();
	ViewChange_MapStart();
}

public void OnConfigsExecuted()
{
	Config_Setup();
	ConVar_Enable();
	Target_Setup();

	if(!ChatHook && CvarChatHook.BoolValue)
	{
		AddCommandListener(OnSayCommand, "say");
		AddCommandListener(OnSayCommand, "say_team");
		ChatHook = true;
	}
}

public void OnMapEnd()
{
	Enabled = false;
}

public void OnPluginEnd()
{
	ConVar_Disable();
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
			DHook_UnhookClient(i);
	}
	
	MemoryPatch_Shutdown();

	if(Enabled)
		EndRound(0);

	#if defined _included_smjm08
	SJM08_Clean();
	#endif
}

public void OnClientPutInServer(int client)
{
	Client[client] = Client[0];
	Classes_ResetKillCounters(client);
	
	if(AreClientCookiesCached(client))
		OnClientCookiesCached(client);

	SDKHook_HookClient(client);
	DHook_HookClient(client);
	if(CvarSendProxy.BoolValue)
	{
		#if defined _SENDPROXYMANAGER_INC_
		if(GetFeatureStatus(FeatureType_Native, "SendProxy_HookArrayProp")==FeatureStatus_Available)
		{
			SendProxy_Hook(client, "m_iClass", Prop_Int, SendProp_OnClientClass);
		}
		#endif
	}
}

public void OnClientCookiesCached(int client)
{
	static char buffer[16];
	CookieColor.Get(client, buffer, sizeof(buffer));
	if(buffer[0])
	{
		static char buffers[3][6];
		ExplodeString(buffer, " ", buffers, sizeof(buffers), sizeof(buffers));
		for(int i; i<3; i++)
		{
			Client[client].ColorBlind[i] = StringToInt(buffers[i]);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	Client[client].IsVip = CheckCommandAccess(client, "sm_trailsvip", ADMFLAG_CUSTOM5);

	int userid = GetClientUserId(client);
	CreateTimer(0.25, Timer_ConnectPost, userid, TIMER_FLAG_NO_MAPCHANGE);

	char steamID[64];
	GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID));
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if(part == AdminCache_Overrides)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client))
				Client[client].IsVip = CheckCommandAccess(client, "sm_trailsvip", ADMFLAG_CUSTOM5);
		}
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RoundStartAt = GetGameTime();
	NextHintAt = RoundStartAt+60.0;

	int entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "func_regenerate")) > MaxClients)
	{
		AcceptEntityInput(entity, "Disable");
	}

	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "func_respawnroomvisualizer")) > MaxClients)
	{
		AcceptEntityInput(entity, "Disable");
	}
	
	entity = MaxClients+1;
	char buffer[64];
	while ((entity = FindEntityByClassname(entity, "trigger_teleport")) > MaxClients)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if (!StrContains(buffer, "teleport") && ((StrContains(buffer, "light", false) != -1) || (StrContains(buffer, "gate", false) != -1)))
		{
			// fix up elevator teleports to allow physics objects (grenades) to teleport as well
			SetEntProp(entity, Prop_Data, "m_spawnflags", 1033);
			
			// the dhook on the trigger's Enable input will take care of other objects (e.g. dropped weapons)
		}
	}
	
	FixUpDoors();

	Items_RoundStart();
	// see comments in szf.sp for why this is here
	SZF_RoundStartDelayed();
	
	// Reset kill counters on round start rather than on player spawn, allows karma bonus to work properly on round end
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
			Classes_ResetKillCounters(client);
	}

	NoAchieve = false;
	GiveAchievement(Achievement_Halloween, 0);
	NoAchieve = !CvarAchievement.BoolValue;

	UpdateListenOverrides(RoundStartAt);

	RequestFrame(DisplayHint, true);
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Enabled = false;
	NoMusicRound = false;
	EndRoundIn = 0.0;
	NextHintAt = FAR_FUTURE;

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		// just to be safe...
		Items_CancelDelayedAction(client);

		Client[client].IsVip = CheckCommandAccess(client, "sm_trailsvip", ADMFLAG_CUSTOM5);

		if(IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
			ChangeClientTeamEx(client, TFTeam_Red);

		// Regenerate some karma at the end of the round
		// Don't give anything if the player got more than 2 bad kills
		if (Client[client].BadKills <= 2)
		{
			float KarmaBonus = 5.0;
			if (Client[client].Kills != 0)		
			{
				// If the player got a kill (5 or more for SCPs) and no bad kills, always give additional bonus
				// If the player had some bad kills but had more good kills (1:3 ratio), give a bonus too
				if ((IsSCP(client) && (Client[client].Kills >= 5)) ||
					((Client[client].BadKills == 0) || (Client[client].GoodKills >= (Client[client].BadKills * 3))))
				{
					KarmaBonus += 5.0;
				}
			}


			Classes_ApplyKarmaBonus(client, KarmaBonus, true);
		}

		SDKCall_SetSpeed(client);
		Client[client].NextSongAt = FAR_FUTURE;
		ChangeSong(client, 0.0, "");
	}

	UpdateListenOverrides(FAR_FUTURE);
	Gamemode_RoundEnd();
	SZF_RoundEnd();

	#if defined _included_smjm08
	SJM08_Clean();
	#endif
}

public Action OnWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action Timer_AccessDeniedReaction(Handle timer, int client)
{
	if (IsValidClient(client))
		Config_DoReaction(client, "accessdenied");

	return Plugin_Stop;
}

public Action OnRelayTrigger(const char[] output, int entity, int client, float delay)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

	if(!StrContains(name, "scp_access", false))
	{
		if(IsValidClient(client))
		{
			int access = StringToInt(name[11]);
			int value;
			if(!Classes_OnKeycard(client, access, value))
			{
				value = Items_OnKeycard(client, access);
				
				if (value == 0)
				{
					// failed to get access, play sound + reaction
					float Time = GetGameTime();
					if (IsCanPickup(client) && (Client[client].NextReactTime < Time))
					{
						EmitSoundToClient(client, "replay/cameracontrolerror.wav");

						Client[client].NextReactTime = Time + 3.0;
						// 0.2 - 0.4 seconds
						CreateTimer(float(GetRandomInt(20, 40)) / 100.0, Timer_AccessDeniedReaction, client, TIMER_FLAG_NO_MAPCHANGE);
					}
				}				
			}
						
			switch(value)
			{
				case 1:
					AcceptEntityInput(entity, "FireUser1", client, client);

				case 2:
					AcceptEntityInput(entity, "FireUser2", client, client);

				case 3:
					AcceptEntityInput(entity, "FireUser3", client, client);

				default:
					AcceptEntityInput(entity, "FireUser4", client, client);
			}
		}
	}
	else if(!StrContains(name, "scp_removecard", false))
	{
		if(IsValidClient(client))
		{
			int ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(ent > MaxClients)
			{
				if(Items_IsHoldingKeycard(ent))
				{
					Items_SwitchItem(client, ent);
					TF2_RemoveItem(client, ent);
					return Plugin_Continue;
				}
			}

			int i;
			while((ent=Items_Iterator(client, i, true)) != -1)
			{
				if(Items_IsKeycard(ent))
					TF2_RemoveItem(client, ent);
			}
		}
	}
	else if(!StrContains(name, "scp_startmusic", false))
	{
		NoMusicRound = false;
		for(int target=1; target<=MaxClients; target++)
		{
			Client[target].NextSongAt = 0.0;
		}
	}
	else if(!StrContains(name, "scp_endmusic", false))
	{
		NoMusicRound = true;
		ChangeGlobalSong(FAR_FUTURE, "");
	}
	else if(!StrContains(name, "scp_respawn", false))	// Temp backwards compability
	{
		if(IsValidClient(client))
		{
			if(Enabled && TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
				GiveAchievement(Achievement_SurvivePocket, client);

			Classes_SpawnPoint(client, Classes_GetByName("scp106"));
		}
	}
	else if(!StrContains(name, "scp_escapepocket", false))
	{
		if(Enabled && IsValidClient(client))
			GiveAchievement(Achievement_SurvivePocket, client);
	}
	else if(!StrContains(name, "scp_floor", false))
	{
		if(IsValidClient(client))
		{
			int floor = StringToInt(name[10]);
			if(floor != Client[client].Floor)
			{
				Client[client].NextSongAt = 0.0;
				Client[client].Floor = floor;
			}
		}
	}
	else if(!StrContains(name, "scp_femur", false))
	{
		ClassEnum class;
		int index = Classes_GetByName("scp106", class);
		int found;
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && index==Client[target].Class)
			{
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
				found = target;
			}
		}

		index = Classes_GetByName("pootisred", class);
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && index==Client[target].Class)
			{
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
				found = target;
			}
		}

		index = class.Group;
		if(Enabled && found)
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && 
				   Classes_GetByIndex(Client[target].Class, class) &&
				   class.Group >= 0 &&
				   class.Group != index)
					GiveAchievement(Achievement_Kill106, target);
			}
		}
	}
	else if(!StrContains(name, "scp_upgrade", false))
	{
		if(Enabled && IsValidClient(client))
		{
			int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(index>MaxClients && IsValidEntity(index))
				index = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");

			char buffer[64];
			Items_GetTranName(index, buffer, sizeof(buffer));

			SetGlobalTransTarget(client);
			if(Client[client].Cooldown > GetGameTime())
			{
				Menu menu = new Menu(Handler_None);
				menu.SetTitle("%t\n ", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "in_cooldown");
				menu.AddItem("", buffer);

				menu.Display(client, 3);
			}
			else
			{
				Menu menu = new Menu(Handler_Upgrade);
				menu.SetTitle("%t\n ", buffer);

				WeaponEnum weapon;
				Items_GetWeaponByIndex(index, weapon);

				FormatEx(buffer, sizeof(buffer), "%t", "914_very");
				menu.AddItem("", buffer, weapon.VeryFine[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_fine");
				menu.AddItem("", buffer, weapon.Fine[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_onetoone");
				menu.AddItem("", buffer, weapon.OneToOne[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_coarse");
				menu.AddItem("", buffer, weapon.Coarse[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_rough");
				menu.AddItem("", buffer, weapon.Rough[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				menu.Display(client, 10);
			}
		}
	}
	else if(!StrContains(name, "scp_printer", false))
	{
		if(Enabled && IsValidClient(client))
		{
			int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(index>MaxClients && IsValidEntity(index))
				index = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");

			char buffer[64];
			Items_GetTranName(index, buffer, sizeof(buffer));

			SetGlobalTransTarget(client);
			if(Client[client].Cooldown > GetGameTime())
			{
				Menu menu = new Menu(Handler_None);
				menu.SetTitle("%t\n ", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "in_cooldown");
				menu.AddItem("", buffer);

				menu.Display(client, 3);
			}
			else
			{

				WeaponEnum weapon;
				if(Items_GetWeaponByIndex(index, weapon) && weapon.Type==ITEM_TYPE_KEYCARD)
				{
					Menu menu = new Menu(Handler_Printer);
					menu.SetTitle("%t\n ", buffer);

					FormatEx(buffer, sizeof(buffer), "%t", "914_copy");
					menu.AddItem("", buffer);

					menu.Display(client, 6);
				}
				else
				{
					Menu menu = new Menu(Handler_None);
					menu.SetTitle("%t\n ", buffer);

					FormatEx(buffer, sizeof(buffer), "%t", "914_nowork");
					menu.AddItem("", buffer);

					menu.Display(client, 3);
				}
			}
		}
	}
	else if(!StrContains(name, "scp_intercom", false))
	{
		if(Enabled && IsValidClient(client))
		{
			Client[client].ComFor = GetGameTime()+15.0;
			GiveAchievement(Achievement_Intercom, client);
		}
	}
	else if(!StrContains(name, "scp_nukecancel", false))
	{
		if(Enabled && IsValidClient(client))
			GiveAchievement(Achievement_SurviveCancel, client);
	}
	else if(!StrContains(name, "scp_nuke", false))
	{
		if(Enabled)
			GiveAchievement(Achievement_SurviveWarhead, 0);
	}
	else if(!StrContains(name, "scp_giveitem_", false))
	{
		if(IsValidClient(client))
		{
			char buffers[4][6];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));
			Items_CreateWeapon(client, StringToInt(buffers[2]), _, true, true);
		}
	}
	else if(!StrContains(name, "scp_removeitem_", false))
	{
		if(IsValidClient(client))
		{
			char buffers[4][6];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));

			int index = StringToInt(buffers[2]);
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			int i, ent;
			while((ent=Items_Iterator(client, i, true)) != -1)
			{
				if(GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == index)
				{
					TF2_RemoveItem(client, ent);
					AcceptEntityInput(entity, "FireUser1", client, client);
					if(ent == active)
						Items_SwitchItem(client, ent);
				}
			}
		}
	}
	else if(!StrContains(name, "scp_insertitem_", false))
	{
		if(IsValidClient(client))
		{
			char buffers[4][6];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));

			int index = StringToInt(buffers[2]);
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if(GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") == index)
			{
				TF2_RemoveItem(client, active);
				AcceptEntityInput(entity, "FireUser1", client, client);
				Items_SwitchItem(client, active);
			}
			else
			{
				AcceptEntityInput(entity, "FireUser2", client, client);
			}
		}
	}
	return Plugin_Continue;
}

public int Handler_None(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		delete menu;
	return 0;
}

public int Handler_Upgrade(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(IsPlayerAlive(client))
			{
				int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(entity>MaxClients && IsValidEntity(entity))
				{
					WeaponEnum weapon;
					if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
					{
						int amount;
						static char buffers[8][16];
						switch(choice)
						{
							case 0:
							{
								Client[client].Cooldown = GetGameTime()+17.5;
								if(weapon.VeryFine[0])
									amount = ExplodeString(weapon.VeryFine, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 1:
							{
								Client[client].Cooldown = GetGameTime()+15.0;
								if(weapon.Fine[0])
									amount = ExplodeString(weapon.Fine, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 2:
							{
								Client[client].Cooldown = GetGameTime()+12.5;
								if(weapon.OneToOne[0])
									amount = ExplodeString(weapon.OneToOne, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 3:
							{
								Client[client].Cooldown = GetGameTime()+10.0;
								if(weapon.Coarse[0])
									amount = ExplodeString(weapon.Coarse, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 4:
							{
								Client[client].Cooldown = GetGameTime()+7.5;
								if(weapon.Rough[0])
									amount = ExplodeString(weapon.Rough, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
						}

						SetGlobalTransTarget(client);

						if(amount)
						{
							amount = StringToInt(buffers[GetRandomInt(0, amount-1)]);
							if(amount == -1)
							{
								if(choice<3 && GetRandomInt(0, 1))
								{
									CPrintToChat(client, "%s%t", PREFIX, "914_noeffect");
								}
								else
								{
									Config_DoReaction(client, "accessdenied");
									EmitSoundToClient(client, "ui/item_light_gun_drop.wav");

									RemoveAndSwitchItem(client, entity);
									CPrintToChat(client, "%s%t", PREFIX, "914_delet");
								}
							}
							else if(Items_GetWeaponByIndex(amount, weapon))
							{
								TF2_RemoveItem(client, entity);
								if(choice<2 && weapon.Type==ITEM_TYPE_KEYCARD && Client[client].Class==Classes_GetByName("sci"))
								{
									static float pos[3];
									GetClientAbsOrigin(client, pos);
									int index = Classes_GetByName("dboi");
									for(int i=1; i<=MaxClients; i++)
									{
										if(!IsValidClient(i) || Client[i].Class!=index)
											continue;

										static float pos2[3];
										GetClientAbsOrigin(i, pos2);
										if(GetVectorDistance(pos, pos2, true) > 160000)
											continue;

										GiveAchievement(Achievement_Upgrade, client);
										break;
									}
								}
								
								Items_PlayPickupReact(client, weapon.Type, amount);

								bool canGive = Items_CanGiveItem(client, weapon.Type);
								entity = Items_CreateWeapon(client, amount, canGive, true, false);
								if(canGive && entity>MaxClients && IsValidEntity(entity))
								{
									Items_SetActiveWeapon(client, entity);
									SZF_DropItem(client);
									Items_ShowItemMenu(client);
									if(amount == ITEM_INDEX_O5)
										GiveAchievement(Achievement_FindO5, client);
								}
								else
								{
									static float pos[3], ang[3];
									GetClientEyePosition(client, pos);
									GetClientEyeAngles(client, ang);
									FakeClientCommand(client, "use tf_weapon_fists");
									Items_DropItem(client, entity, pos, ang, true);
								}
								
								EmitSoundToClient(client, "ui/item_store_add_to_cart.wav");

								static char buffer[64];
								Items_GetTranName(amount, buffer, sizeof(buffer));
								CPrintToChat(client, "%s%t", PREFIX, "914_gained", buffer);
							}
							else
							{
								LogError("[Config] Invalid weapon index %d in 914 arg", amount);
								CPrintToChat(client, "%s%t", PREFIX, "914_noeffect");
							}
						}
						else
						{
							CPrintToChat(client, "%s%t", PREFIX, "914_noeffect");
						}
					}
				}
			}
		}
	}
	return 0;
}

public int Handler_Printer(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(IsPlayerAlive(client))
			{
				int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(index > MaxClients)
				{
					index = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");
					WeaponEnum weapon;
					if(Items_GetWeaponByIndex(index, weapon) && weapon.Type==ITEM_TYPE_KEYCARD)
					{
						Client[client].Cooldown = GetGameTime()+20.0;

						bool canGive = Items_CanGiveItem(client, weapon.Type);
						index = Items_CreateWeapon(client, index, canGive, true, false);
						if(!canGive && index>MaxClients)
						{
							static float pos[3], ang[3];
							GetClientEyePosition(client, pos);
							GetClientEyeAngles(client, ang);
							Items_DropItem(client, index, pos, ang, true);
						}
					}
				}
			}
		}
	}
	return 0;
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	if(cond == TFCond_DemoBuff)
	{
		TF2_RemoveCondition(client, TFCond_DemoBuff);
	}
	else if(cond == TFCond_Taunting)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
			TF2_RemoveCondition(client, TFCond_Taunting);
	}

	SDKCall_SetSpeed(client);
	Classes_OnCondAdded(client, cond);
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	SDKCall_SetSpeed(client);
	Classes_OnCondRemoved(client, cond);
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		result = (class.Human && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode));
		if(result)
			Client[client].IgnoreTeleFor = GetGameTime()+3.0;
	}
	else
	{
		result = false;
	}
	return Plugin_Changed;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsPlayerAlive(client))
		return;
	
	// this is terrible, we need a count of currently alive vips (for HUD) on round start 
	// but we can't do it on round start because players aren't fully spawned yet
	// so just do it here instead...
	Gamecode_CountVIPs();

	ViewModel_Destroy(client);
	SZF_DropItem(client, false);

	Client[client].ResetThinkIsDead();
	Client[client].Sprinting = false;
	Client[client].ChargeIn = 0.0;
	Client[client].Disarmer = 0;
	Client[client].SprintPower = 100.0;
	Client[client].Extra2 = 0;
	Client[client].Extra3 = 0.0;
	Client[client].NextReactTime = 0.0;	
	Client[client].NextPickupReactTime = 0.0;	
	Client[client].LastDisarmedTime = 0.0;	
	Client[client].LastWeaponTime = 0.0;	
	Client[client].WeaponClass = TFClass_Unknown;
	
	float KarmaRatio = CvarKarmaRatio.FloatValue;
	for (int i = 1; i < MAXTF2PLAYERS; i++)
		Client[i].KarmaPoints[client] = KarmaRatio;

	SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
	SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
	SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", false);

	Classes_PlayerSpawn(client);

	if(Client[client].DownloadMode == 2)
	{
		TF2Attrib_SetByDefIndex(client, 406, 4.0);
	}
	else
	{
		TF2Attrib_RemoveByDefIndex(client, 406);
	}
}

public Action OnObjectDestroy(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(i==attacker || (IsClientInGame(i) && IsFriendly(Client[attacker].Class, Client[i].Class) && Client[attacker].CanTalkTo[i]))
				event.FireToClient(i);
		}
	}
	return Plugin_Changed;
}

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	event.SetBool("allseecrit", false);
	event.SetInt("damageamount", 0);

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		Event event2 = CreateEvent("npc_hurt", true);
		event2.SetInt("entindex", client);
		event2.SetInt("damageamount", 1);
		event2.SetInt("attacker_player", userid);
		event2.SetBool("crit", event.GetBool("crit"));
		event2.FireToClient(client);
		event2.Cancel();
	}
	return Plugin_Changed;
}

public Action OnBlockCommand(int client, const char[] command, int args)
{
	return Enabled ? Plugin_Handled : Plugin_Continue;
}

public Action OnJoinClass(int client, const char[] command, int args)
{
	if(client)
	{
		char class[16];
		GetCmdArg(1, class, sizeof(class));
		Client[client].PrefClass = TF2_GetClass(class);
		if(IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", Client[client].PrefClass);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerSpray(const char[] name, const int[] clients, int count, float delay)
{
	int client = TE_ReadNum("m_nPlayer");
	return (IsClientInGame(client) && TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)) ? Plugin_Handled : Plugin_Continue;
}

public Action OnJoinAuto(int client, const char[] command, int args)
{
	if(!client || Classes_AskForClass())
		return Plugin_Continue;

	if(!IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
	{
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(TFClass_Spy));
		ChangeClientTeam(client, 3);
	}
	return Plugin_Handled;
}

public Action OnJoinSpec(int client, const char[] command, int args)
{
	if(!client || !Enabled)
		return Plugin_Continue;

	if(!IsSpec(client))
		return Plugin_Handled;

	TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
	ForcePlayerSuicide(client);
	return Plugin_Continue;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	if(Enabled && !IsSpec(client))
		return Plugin_Handled;

	static char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));
	if(StrEqual(teamString, "spectate", false))
	{
		TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
		ForcePlayerSuicide(client);
		return Plugin_Continue;
	}

	if(Classes_AskForClass())
		return Plugin_Continue;

	if(GetClientTeam(client) <= view_as<int>(TFTeam_Spectator))
	{
		ChangeClientTeam(client, 2);
		if(view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass")) == TFClass_Unknown)
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(TFClass_Spy));
	}
	return Plugin_Handled;
}

public Action OnVoiceMenu(int client, const char[] command, int args)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if(Classes_OnVoiceCommand(client))
		return Plugin_Handled;

	Client[client].IdleAt = GetGameTime()+2.5;
	return Plugin_Continue;
}

public Action OnDropItem(int client, const char[] command, int args)
{
	if(client && IsClientInGame(client) && !IsSpec(client))
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.CanPickup)
		{
			int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(entity > MaxClients)
			{
				WeaponEnum weapon;
				int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
				int dropType = GetEntityFlags(client) & FL_DUCKING ? ItemDrop_Drop : ItemDrop_Throw;
				bool big = ((Items_GetWeaponByIndex(index, weapon) && weapon.Type==ITEM_TYPE_WEAPON) || index == ITEM_INDEX_MICROHID);
				
				static float pos[3], ang[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, ang);
				
				if(Items_DropItem(client, entity, pos, ang, true, dropType))
				{
					if(big)
					{
						ClientCommand(client, "playgamesound ui/item_bag_drop.wav");	// No accompanying GameSound, but this works
					}
					else
					{
						ClientCommand(client, "playgamesound weapon.ImpactSoft");
					}
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnSayCommand(int client, const char[] command, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	#if defined _sourcecomms_included
	if(SourceComms && SourceComms_GetClientGagType(client)>bNot)
		return Plugin_Handled;
	#endif

	#if defined _basecomm_included
	if(BaseComm && BaseComm_IsClientGagged(client))
		return Plugin_Handled;
	#endif

	float time = GetGameTime();
	if(Client[client].ChatIn > time)
		return Plugin_Handled;

	Client[client].ChatIn = time+1.25;

	static char msg[256];
	GetCmdArgString(msg, sizeof(msg));
	if(msg[1]=='/' || msg[1]=='@')
		return Plugin_Handled;

	//CRemoveTags(msg, sizeof(msg));
	ReplaceString(msg, sizeof(msg), "\"", "");
	ReplaceString(msg, sizeof(msg), "\n", "");

	if(!strlen(msg))
		return Plugin_Handled;

	char name[128];
	GetClientName(client, name, sizeof(name));
	CRemoveTags(name, sizeof(name));
	Format(name, sizeof(name), "{red}%s", name);

	Forward_OnMessage(client, name, sizeof(name), msg, sizeof(msg));

	if (Enabled)
	{
		#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR>10
		Client[client].IdleAt = GetGameTime()+2.5;
		#endif
	}

	for(int target=1; target<=MaxClients; target++)
	{
		if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target]))
		{
			if (Enabled)
			{
				if(!IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
				{
					if (IsSpec(target))
						Client[target].ThinkIsDead[client] = true;
					else
						continue;	//Don't show chat to target
				}
				else if(IsSpec(client))
				{
					if (!IsSpec(target))
						continue;	//Don't show chat to target
				}
				else
				{
					Client[target].ThinkIsDead[client] = false;
				}
			}
			
			char tag[64];
			GetClientChatTag(client, target, tag, sizeof(tag));
			if (tag[0])
				CPrintToChat(target, "%s %s {default}: %s", tag, name, msg);
			else
				CPrintToChat(target, "%s {default}: %s", name, msg);
		}
	}

	return Plugin_Handled;
}

public void GetClientChatTag(int client, int target, char[] buffer, int length)
{
	if(!Enabled)
	{
		//No tag
	}
	else if(!IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
	{
		strcopy(buffer, length, "*SPEC*");
	}
	else if(IsSpec(client))
	{
		strcopy(buffer, length, "*DEAD*");
	}
	else if(Client[client].ComFor > GetGameTime())
	{
		strcopy(buffer, length, "*INTERCOM*");
	}
	else if(!IsSpec(target))
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && !class.Human && IsFriendly(Client[client].Class, Client[target].Class))
		{
			Format(buffer, length, "(%T)", class.Display, target);
		}
		else if (Items_Radio(client) > 1)
		{
			static float clientPos[3], targetPos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
			if(GetVectorDistance(clientPos, targetPos) > 400)
				strcopy(buffer, length, "*RADIO*");
		}
	}
}

public Action Command_MainMenu(int client, int args)
{
	if(client)
	{
		Menu menu = new Menu(Handler_MainMenu);
		menu.SetTitle("SCP: Secret Fortress\n ");

		SetGlobalTransTarget(client);
		char buffer[64];

		FormatEx(buffer, sizeof(buffer), "%t (/scpinfo)", "menu_helpclass");
		menu.AddItem("1", buffer, IsPlayerAlive(client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

		FormatEx(buffer, sizeof(buffer), "%t (/scpcolor)", "menu_colorblind");
		menu.AddItem("2", buffer);

		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int Handler_MainMenu(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 0:
				{
					Command_HelpClass(client, 0);
					Command_MainMenu(client, 0);
				}
				case 1:
				{
					Command_ColorBlind(client, -1);
				}
			}
		}
	}
	return 0;
}

public Action Command_HelpClass(int client, int args)
{
	if(client && IsPlayerAlive(client))
		ShowClassInfo(client, true);

	return Plugin_Handled;
}

public Action Command_ColorBlind(int client, int args)
{
	if(client)
	{
		Menu menu = new Menu(Handler_ColorBlind);
		SetGlobalTransTarget(client);
		menu.SetTitle("SCP: Secret Fortress\n%t\n ", "menu_colorblind");

		Client[client].Colors = Client[client].Colors;

		bool found;
		static char buffer[32];
		for(int i; i<3; i++)
		{
			if(Client[client].ColorBlind[i] < 0)
			{
				Format(buffer, sizeof(buffer), "%t", "Off");
			}
			else
			{
				found = true;
				Client[client].Colors[i] = Client[client].ColorBlind[i];
				IntToString(Client[client].ColorBlind[i], buffer, sizeof(buffer));
			}

			static const char Colors[][] = {"Red", "Green", "Blue"};
			Format(buffer, sizeof(buffer), "%t: %s", Colors[i], buffer);
			menu.AddItem("", buffer);
		}

		Format(buffer, sizeof(buffer), "%t", "Reset");
		menu.AddItem("", buffer, found ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

		menu.ExitButton = true;
		menu.ExitBackButton = args==-1;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int Handler_ColorBlind(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
				Command_MainMenu(client, 0);
		}
		case MenuAction_Select:
		{
			if(choice > 2)
			{
				for(int i; i<3; i++)
				{
					Client[client].ColorBlind[i] = -1;
				}
			}
			else
			{
				if(Client[client].ColorBlind[choice] > 245)
				{
					Client[client].ColorBlind[choice] = -1;
				}
				else if(Client[client].ColorBlind[choice] < 0)
				{
					Client[client].ColorBlind[choice] = 0;
				}
				else
				{
					Client[client].ColorBlind[choice] += 10;
				}
			}

			if(AreClientCookiesCached(client))
			{
				char buffer[16];
				FormatEx(buffer, sizeof(buffer), "%d %d %d", Client[client].ColorBlind[0], Client[client].ColorBlind[1], Client[client].ColorBlind[2]);
				CookieColor.Set(client, buffer);
			}

			Command_ColorBlind(client, menu.ExitBackButton ? -1 : 0);
		}
	}
	return 0;
}

public Action Command_ForceClass(int client, int args)
{
	if(!args)
	{
		SetGlobalTransTarget(client);

		ClassEnum class;
		for(int i; Classes_GetByIndex(i, class); i++)
		{
			PrintToConsole(client, "%t | @%s", class.Display, class.Name);
		}

		if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
			ReplyToCommand(client, "[SM] %t", "See console for output");

		return Plugin_Handled;
	}

	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_forceclass <target> <class>");
		return Plugin_Handled;
	}

	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(2, pattern, sizeof(pattern));

	char targetName[MAX_TARGET_LENGTH];

	SetGlobalTransTarget(client);

	int index;
	bool found;
	ClassEnum class;
	while(Classes_GetByIndex(index, class))
	{
		FormatEx(targetName, sizeof(targetName), "%t", class.Display);
		if(StrContains(targetName, pattern, false) != -1)
		{
			found = true;
			break;
		}

		index++;
	}

	if(!found)
	{
		index = 0;
		while(Classes_GetByIndex(index, class))
		{
			if(StrContains(class.Name, pattern, false) != -1)
			{
				found = true;
				break;
			}

			index++;
		}

		if(!found)
		{
			ReplyToCommand(client, "[SM] Invalid class string");
			return Plugin_Handled;
		}
	}

	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	GetCmdArg(1, pattern, sizeof(pattern));
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	NoAchieve = true;

	for(int target; target<matches; target++)
	{
		if(IsClientSourceTV(targets[target]) || IsClientReplay(targets[target]))
			continue;

		strcopy(pattern, sizeof(pattern), class.Name);
		switch(Forward_OnClassPre(targets[target], ClassSpawn_Other, pattern, sizeof(pattern)))
		{
			case Plugin_Changed, Plugin_Handled:
			{
				Client[targets[target]].Class = Classes_GetByName(pattern);
			}
			case Plugin_Stop:
			{
				continue;
			}
			default:
			{
				Client[targets[target]].Class = index;
			}
		}

		TF2_RespawnPlayer(targets[target]);
		Forward_OnClass(targets[target], ClassSpawn_Other, pattern);

		for(int i=1; i<=MaxClients; i++)
		{
			Client[i].ThinkIsDead[targets[target]] = false;
		}
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Forced class %t to %t", class.Display, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Forced class %t to %s", class.Display, targetName);
	}
	return Plugin_Handled;
}

public Action Command_ForceItem(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_giveitem <target> <index>");
		return Plugin_Handled;
	}

	static char targetName[MAX_TARGET_LENGTH];
	GetCmdArg(2, targetName, sizeof(targetName));
	int index = StringToInt(targetName);
	WeaponEnum weapon;
	if(!Items_GetWeaponByIndex(index, weapon))
	{
		ReplyToCommand(client, "[SM] Invalid weapon index");
		return Plugin_Handled;
	}

	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));

	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	NoAchieve = true;

	for(int target; target<matches; target++)
	{
		if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			Items_CreateWeapon(targets[target], index, true, true, true);
	}
	
	Items_GetTranName(index, pattern, sizeof(pattern));

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Gave %t to %t", pattern, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Gave %t to %s", pattern, targetName);
	}
	return Plugin_Handled;
}

public Action Command_ForceAmmo(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_giveammo <target> <type> [amount]");
		return Plugin_Handled;
	}

	static char targetName[MAX_TARGET_LENGTH];
	GetCmdArg(2, targetName, sizeof(targetName));
	int type = StringToInt(targetName);
	if(type<1 || type>31)
	{
		ReplyToCommand(client, "[SM] Invalid ammo index");
		return Plugin_Handled;
	}

	int amount = 999999;
	if(args > 2)
	{
		GetCmdArg(3, targetName, sizeof(targetName));
		amount = StringToInt(targetName);
	}

	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));

	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	NoAchieve = true;

	for(int target; target<matches; target++)
	{
		if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			SetAmmo(targets[target], GetAmmo(targets[target], type)+amount, type);
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Gave %d ammo of %d to %t", amount, type, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Gave %d ammo of %d to %s", amount, type, targetName);
	}
	return Plugin_Handled;
}

public Action Command_ForceKarma(int client, int args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_setkarma <target> <0-100>");
		return Plugin_Handled;
	}

	static char targetName[MAX_TARGET_LENGTH];
	GetCmdArg(2, targetName, sizeof(targetName));
	float karma = StringToFloat(targetName);
	if(karma < 0.0 || karma > 100.0)
	{
		ReplyToCommand(client, "[SM] Invalid karma level");
		return Plugin_Handled;
	}

	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));

	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	NoAchieve = true;

	for(int target; target<matches; target++)
	{
		if(IsClientInGame(targets[target]))
			Classes_SetKarma(targets[target], karma);
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Set karma to %f for %t", karma, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Set karma to %f for %s", karma, targetName);
	}
	return Plugin_Handled;
}

public Action Command_PreventWin(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: scp_preventroundwin <0/1>");
		return Plugin_Handled;
	}

	static char togglechar[2];
	GetCmdArg(1, togglechar, sizeof(togglechar));
	int toggle = StringToInt(togglechar);

	DebugPreventRoundWin = toggle ? true : false;
	CShowActivity2(client, PREFIX, "Round win condition %s", toggle ? "disabled" : "enabled");

	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	if (Client[client].QueueIndex != -1)
		Gamemode_UnassignQueueIndex(client);

	Items_CancelDelayedAction(client);
	SZF_DropItem(client);

	CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if (item)
	{
		if (TF2Items_GetLevel(item) == 101)
			return Plugin_Continue;
	}

	// Handle action slot items
	if (TF2Econ_GetItemLoadoutSlot(index, TF2_GetPlayerClass(client)) == LOADOUT_POSITION_ACTION)
	{
		// Disallow anything that could clip into playermodels
		if (!StrEqual(classname, "tf_powerup_bottle") &&
			!StrEqual(classname, "tf_weapon_spellbook") &&
			!StrEqual(classname, "tf_wearable_campaign_item"))
		{
			return Plugin_Continue;
		}
	}
	// Handle D-Class cosmetics
	else if (CvarAllowCosmetics.BoolValue)
	{
		if (Client[client].Class == Classes_GetByName("dboi") && StrContains(classname, "tf_wearable") != -1)
		{
			int newItemRegionMask = TF2Econ_GetItemEquipRegionMask(index);
			int newItemRegionGroupBits = TF2Econ_GetItemEquipRegionGroupBits(index);

			StringMap regions = TF2Econ_GetEquipRegionGroups();
			StringMapSnapshot snapshot = regions.Snapshot();

			// Multiple groups can share the same group bit, so test each group name
			for (int i = 0; i < snapshot.Length; i++)
			{
				char buffer[16];
				snapshot.GetKey(i, buffer, sizeof(buffer));

				int bit;
				if (regions.GetValue(buffer, bit) && (newItemRegionGroupBits >> bit) & 1)
				{
					// Disallow shirts and pants to avoid obscuring the D-Class colors
					if (StrEqual(buffer, "shirt") || StrEqual(buffer, "pants"))
					{
						delete snapshot;
						delete regions;
						return Plugin_Handled;
					}
				}
			}
			delete snapshot;
			delete regions;

			// Remove any wearable that has a conflicting equip_region
			for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(client); wbl++)
			{
				int wearable = TF2Util_GetPlayerWearable(client, wbl);
				if (wearable == -1)
					continue;

				int wearableDefindex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
				if (wearableDefindex == DEFINDEX_UNDEFINED)
					continue;

				int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefindex);
				if (wearableRegionMask & newItemRegionMask)
					TF2_RemoveWearable(client, wearable);
			}

			return Plugin_Continue;
		}
	}

	return Plugin_Handled;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return Plugin_Continue;
		
	int attacker = GetClientOfUserId(event.GetInt("attacker"));		

	Items_CancelDelayedAction(client);
	
	// do this before the team gets changed
	PlayFriendlyDeathReaction(client, attacker);

	float engineTime = GetGameTime();
	bool deadringer = view_as<bool>(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER);
	if(!deadringer)
	{
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
		if(GetClientTeam(client) <= view_as<int>(TFTeam_Spectator))
			ChangeClientTeamEx(client, TFTeam_Red);

		ViewModel_Destroy(client);

		if(RoundStartAt+60.0 > engineTime)
			GiveAchievement(Achievement_DeathEarly, client);

		int entity = MaxClients+1;
		while((entity=FindEntityByClassname(entity, "obj_sentrygun")) > MaxClients)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
				SetEntProp(entity, Prop_Send, "m_bDisabled", 1);
		}

		CancelClientMenu(client);
		RequestFrame(UpdateListenOverrides, engineTime);
	}

	SZF_DropItem(client);

	if(client!=attacker && !IsValidClient(attacker))
		attacker = event.GetInt("inflictor_entindex");

	if(client!=attacker && IsValidClient(attacker))
	{
		static int spree[MAXTF2PLAYERS];
		static float spreeFor[MAXTF2PLAYERS];
		if(spreeFor[attacker] < engineTime)
		{
			spree[attacker] = 1;
		}
		else if(++spree[attacker] == 5)
		{
			GiveAchievement(Achievement_KillSpree, attacker);
		}
		spreeFor[attacker] = engineTime+6.0;

		if (IsSCP(attacker))
		{
			int wep = EntRefToEntIndex(Client[client].PreDamageWeapon);
			if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==ITEM_INDEX_MICROHID)
				GiveAchievement(Achievement_KillMirco, attacker);		
		}

		Classes_OnKill(attacker, client);

		Client[attacker].Kills++;
		
		SDKCall_SetSpeed(attacker);

		if(deadringer || !Classes_OnDeath(client, event))
		{
			event.BroadcastDisabled = true;
			for(int i=1; i<=MaxClients; i++)
			{
				if(i==client || i==attacker || (IsValidClient(i) && IsFriendly(Client[attacker].Class, Client[i].Class) && Client[attacker].CanTalkTo[i]))
				{
					Client[i].ThinkIsDead[client] = true;
					event.FireToClient(i);
				}
			}
		}
	}
	else if(Classes_OnDeath(client, event))
	{
		for(int i=1; i<=MaxClients; i++)
		{
			Client[i].ThinkIsDead[client] = true;
		}
	}
	else
	{
		event.BroadcastDisabled = true;

		if(!deadringer)
		{
			int damage = event.GetInt("damagebits");
			if(damage & DMG_SHOCK)
			{
				GiveAchievement(Achievement_DeathTesla, client);
				int wep = EntRefToEntIndex(Client[client].PreDamageWeapon);
				if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==ITEM_INDEX_MICROHID)
					GiveAchievement(Achievement_DeathMicro, client);	
			}
			else if(damage & DMG_FALL)
			{
				GiveAchievement(Achievement_DeathFall, client);
			}
			else if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
			{
				GiveAchievement(Achievement_Death106, client);
			}
			else
			{
				int weapon = event.GetInt("weaponid");
				if(weapon>MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==308)
					GiveAchievement(Achievement_DeathGrenade, client);
			}
		}
	}
	return Plugin_Changed;
}

public Action OnBroadcast(Event event, const char[] name, bool dontBroadcast)
{
	static char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.", false))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!Enabled || !IsPlayerAlive(client))
		return Plugin_Continue;

	float engineTime = GetGameTime();
	if(Client[client].FreezeFor)
	{
		if(Client[client].FreezeFor < engineTime)
		{
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
			TF2_RemoveCondition(client, TFCond_Dazed);
			SetEntityMoveType(client, MOVETYPE_WALK);
			Client[client].FreezeFor = 0.0;
		}
		else
		{
			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
			TF2_RemoveCondition(client, TFCond_Taunting);
		}
	}

	SZF_PlayerRunCmd(client);

	if(Client[client].InvisFor)
	{
		if(Client[client].InvisFor > engineTime)
		{
			TF2_RemoveCondition(client, TFCond_Taunting);
		}
		else
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
			Client[client].InvisFor = 0.0;
		}
		return Plugin_Continue;
	}

	// Item-Specific Buttons
	static int holding[MAXTF2PLAYERS];
	bool wasHolding = view_as<bool>(holding[client]);
	bool changed = Items_OnRunCmd(client, buttons, holding[client]);

	// Sprinting Related
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.CanSprint && !Client[client].Disarmer)
	{
		if(((buttons & IN_ATTACK3) || (buttons & IN_SPEED)) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT)) && GetEntPropEnt(client, Prop_Data, "m_hGroundEntity")!=-1)
		{
			if(!Client[client].Sprinting && Client[client].SprintPower>15)
			{
				ClientCommand(client, "playgamesound player/suit_sprint.wav");
				Client[client].HelpSprint = false;
				Client[client].Sprinting = true;
				SDKCall_SetSpeed(client);
			}
		}
		else if(Client[client].Sprinting)
		{
			Client[client].Sprinting = false;
			SDKCall_SetSpeed(client);
		}
	}

	// Everything else
	if(holding[client])
	{
		if(!(buttons & holding[client]))
			holding[client] = 0;
	}
	else if(buttons & IN_ATTACK)
	{
		if(AttemptGrabItem(client))
		{
			buttons &= ~IN_ATTACK;
			changed = true;
		}
		holding[client] = IN_ATTACK;
	}
	else if(buttons & IN_ATTACK2)
	{
		if(AttemptGrabItem(client))
		{
			buttons &= ~IN_ATTACK2;
			changed = true;
		}
		holding[client] = IN_ATTACK2;
	}
	else if(buttons & IN_USE)
	{
		if(AttemptGrabItem(client))
		{
			buttons &= ~IN_USE;
			changed = true;
		}
		holding[client] = IN_USE;
	}
	else if(buttons & IN_RELOAD)
	{
		holding[client] = IN_RELOAD;
	}
	else if(buttons & IN_ATTACK3)
	{
		holding[client] = IN_ATTACK3;
	}

	// Check if the player moved at all or is speaking
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))))
		Client[client].IdleAt = engineTime+2.5;

	// SCP-specific buttons
	Classes_OnButton(client, wasHolding ? 0 : holding[client]);

	// HUD related things
	static float specialTick[MAXTF2PLAYERS];
	if(specialTick[client] < engineTime)
	{
		bool showHud = (Client[client].HudIn<engineTime && !SZF_Enabled() && !(GetClientButtons(client) & IN_SCORE));
		specialTick[client] = engineTime+0.2;

		static char buffer[PLATFORM_MAX_PATH];
		if(showHud)
		{
			SetGlobalTransTarget(client);

			if(EndRoundIn)
			{
				int timeleft = RoundToCeil(EndRoundIn-engineTime);
				if(timeleft < 121)
				{
					char seconds[4];
					int sec = timeleft%60;
					if(sec > 9)
					{
						IntToString(sec, seconds, sizeof(seconds));
					}
					else
					{
						FormatEx(seconds, sizeof(seconds), "0%d", sec);
					}

					int min = timeleft/60;
					BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
					if(bf)
					{
						Format(buffer, sizeof(buffer), "%t", "time_remaining", min, seconds);
						bf.WriteString(buffer);
						bf.WriteString(timeleft<21 ? "ico_notify_ten_seconds" : timeleft<61 ? "ico_notify_thirty_seconds" : "ico_notify_sixty_seconds");
						bf.WriteByte(0);
						EndMessage();
					}
				}
			}
		}

		if(!IsSpec(client))
		{
			if (class.Human || class.CanSprint)
			{
				if(DisarmCheck(client))
				{
					Client[client].AloneIn = FAR_FUTURE;
					if(showHud)
					{
						SetHudTextParamsEx(0.14, 0.93, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
						ShowSyncHudText(client, HudPlayer, "%t", "disarmed_by", Client[client].Disarmer);
					}
				}
				else
				{
					static float pos1[3];
					GetClientEyePosition(client, pos1);
					for(int target=1; target<=MaxClients; target++)
					{
						if(!IsValidClient(target) || IsSpec(target) || IsSCP(target))
							continue;

						static float pos2[3];
						GetClientEyePosition(target, pos2);
						if(GetVectorDistance(pos1, pos2) > 400)
							continue;

						//if(Client[client].AloneIn < engineTime)
							//Client[client].NextSongAt = 0.0;

						Client[client].AloneIn = engineTime+90.0;
						break;
					}

					if(Client[client].Sprinting || !(GetEntityFlags(client) & FL_ONGROUND))
					{
						if(!Client[client].Extra2 && Client[client].Extra3<engineTime)
						{
							float drain = 1.0;
							Items_Sprint(client, drain);
							Client[client].SprintPower -= drain;
							if(Client[client].Sprinting && Client[client].SprintPower<0)
							{
								Client[client].SprintPower = 0.0;
								Client[client].Sprinting = false;
								SDKCall_SetSpeed(client);
							}
						}
					}
					else if(Client[client].SprintPower < 100)
					{
						Client[client].SprintPower += 1.5;
					}

					if(showHud)
					{
						if(GetClientMenu(client) == MenuSource_None)
							Items_ShowItemMenu(client);

						bool showingHelp;
						int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						if(active>MaxClients && IsValidEntity(active) && GetEntityClassname(active, buffer, sizeof(buffer)))
						{
							static float time[MAXTF2PLAYERS];
							if(holding[client] == IN_RELOAD)
							{
								if(time[client] == FAR_FUTURE)
								{
									time[client] = engineTime+0.1;
								}
								else if(time[client] < engineTime)
								{
									showingHelp = Items_ShowItemDesc(client, active);
									if(!showingHelp)
										time[client] = FAR_FUTURE;
								}
							}
							else
							{
								time[client] = FAR_FUTURE;
							}
						}

						if(!showingHelp && Client[client].HelpSprint)
							PrintKeyHintText(client, "%t", "help_sprint");

						active = RoundToFloor(Client[client].SprintPower*0.13);
						if(Client[client].Sprinting)
						{
							strcopy(buffer, sizeof(buffer), "|");
						}
						else
						{
							buffer[0] = 0;
						}

						for(int i=1; i<active; i++)
						{
							Format(buffer, sizeof(buffer), "%s|", buffer);
						}

						SetHudTextParamsEx(0.14, 0.93, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
						ShowSyncHudText(client, HudGame, "%t", "sprint", buffer);
					}
				}
			}

			// What class am I again
			if(class.Human && showHud)
			{
				SetHudTextParamsEx(-1.0, 0.08, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
				ShowSyncHudText(client, HudClass, "%t", class.Display);
			}
			
			if (IsSCP(client) && !IsSpec(client) && showHud)
			{
				// kill counter + how many dbois/scientists left
				SetHudTextParamsEx(-1.0, 0.1, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
				ShowSyncHudText(client, HudClass, "%t", "kill_counter", Client[client].Kills, VIPsAlive);			
			}
		}

		// And next theme please
		if(!NoMusic && !NoMusicRound && Client[client].NextSongAt<engineTime)
		{
			int volume;
			float time = Classes_OnTheme(client, buffer);
			if(time <= 0)
				time = Gamemode_GetMusic(client, Client[client].Floor, buffer, volume);

			if(time > 0)
				ChangeSong(client, engineTime+time, buffer, volume);
		}
	}

	if(class.Driver && !Client[client].Disarmer)
	{
		if(Client[client].UseBuffer)
		{
			buttons |= IN_USE;
			changed = true;
		}
	}
	else if(buttons & IN_USE)
	{
		buttons &= ~IN_USE;
		changed = true;
	}

	Client[client].UseBuffer = false;
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnGameFrame()
{
	// physics simulation is run for this per tick
	SCP18_Tick();

	float engineTime = GetGameTime();
	static float nextAt;
	if(nextAt > engineTime)
		return;

	nextAt = engineTime+1.0;
	UpdateListenOverrides(engineTime);

	if(Enabled)
	{
		if(NextHintAt < engineTime)
		{
			DisplayHint(false);
			NextHintAt = engineTime+60.0;
		}

		if(EndRoundIn)
		{
			float timeleft = EndRoundIn-engineTime;
			if(!NoMusic && !NoMusicRound)
			{
				int volume;
				static char buffer[PLATFORM_MAX_PATH];
				float duration = Gamemode_GetMusic(0, Music_Timeleft, buffer, volume);
				if(duration > timeleft)
				{
					ChangeGlobalSong(FAR_FUTURE, buffer, volume);
					NoMusicRound = true;
				}
			}

			if(timeleft < 0)
			{
				for(int client=1; client<=MaxClients; client++)
				{
					if(!IsValidClient(client))
						continue;

					if(IsPlayerAlive(client))
						ForcePlayerSuicide(client);

					FadeMessage(client, 36, 1536, 0x0012, 255, 228, 200, 228);
					FadeClientVolume(client, 1.0, 4.0, 4.0, 0.2);
				}

				EndRoundIn = 0.0;
			}
		}
	}
}

public Action CheckAlivePlayers(Handle timer)
{
	if(Enabled)
		Gamemode_CheckRound();

	return Plugin_Continue;
}

public void UpdateListenOverrides(float engineTime)
{
	bool manage = CvarVoiceHook.BoolValue;
	if(!Enabled)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client, false))
				continue;

			for(int target=1; target<=MaxClients; target++)
			{
				if(!manage)
				{
					Client[target].CanTalkTo[client] = true;
					continue;
				}

				if(client == target)
				{
					Client[target].CanTalkTo[client] = true;
					SetListenOverride(client, target, Listen_Default);
					continue;
				}

				if(!IsValidClient(target))
					continue;

				if(IsClientMuted(client, target))
				{
					Client[target].CanTalkTo[client] = false;
					SetListenOverride(client, target, Listen_No);
					continue;
				}

				Client[target].CanTalkTo[client] = true;

				#if defined _sourcecomms_included
				if(SourceComms && SourceComms_GetClientMuteType(target)>bNot)
				{
					SetListenOverride(client, target, Listen_No);
					continue;
				}
				#endif

				#if defined _basecomm_included
				if(BaseComm && BaseComm_IsClientMuted(target))
				{
					SetListenOverride(client, target, Listen_No);
					continue;
				}
				#endif

				SetListenOverride(client, target, Listen_Default);
			}
		}
		return;
	}

	int total;
	int[] client = new int[MaxClients];
	bool[] spec = new bool[MaxClients];
	bool[] admin = new bool[MaxClients];
	float[] radio = new float[MaxClients];
	static float pos[MAXTF2PLAYERS][3];
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i, false))
			continue;

		client[total] = i;
		radio[total] = Items_Radio(i);
		spec[total] = GetClientTeam(i)==view_as<int>(TFTeam_Spectator);
		admin[total] = (spec[total] && CheckCommandAccess(i, "sm_mute", ADMFLAG_CHAT));
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos[total]);
		total++;
	}

	ClassEnum iclass, aclass;
	for(int i; i<total; i++)
	{
		Classes_GetByIndex(Client[client[i]].Class, iclass);
		for(int a; a<total; a++)
		{
			if(client[i] == client[a])
			{
				Client[client[a]].CanTalkTo[client[i]] = true;
				if(manage)
					SetListenOverride(client[i], client[a], Listen_Default);

				continue;
			}

			bool muted = (manage && IsClientMuted(client[i], client[a]));
			bool blocked = muted;

			#if defined _basecomm_included
			if(!blocked && BaseComm && BaseComm_IsClientMuted(client[a]))
				blocked = true;
			#endif

			#if defined _sourcecomms_included
			if(!blocked && SourceComms && SourceComms_GetClientMuteType(client[a])>bNot)
				blocked = true;
			#endif

			if(admin[a] || spec[i] || Client[client[a]].ComFor>engineTime)	// Admin speaking, spec team listner, Comm System speaking
			{
				Client[client[a]].CanTalkTo[client[i]] = !muted;
				if(manage)
					SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Default);

				continue;
			}

			float range, hearing;
			Classes_GetByIndex(Client[client[a]].Class, aclass);
			if(aclass.Group == iclass.Group)
			{
				range = aclass.SpeakTeam;
				hearing = iclass.HearTeam;
			}
			else
			{
				range = aclass.Speak;
				hearing = iclass.Hear;
			}

			bool success;
			if(range>0 && hearing>0)
			{
				if(radio[a]>1 && radio[i]>1)
					range *= radio[a];

				float dist = GetVectorDistance(pos[i], pos[a]);
				success = (dist<range || dist<hearing);
			}

			Client[client[a]].CanTalkTo[client[i]] = (success && !muted);
			if(manage)
				SetListenOverride(client[i], client[a], (success && !blocked) ? Listen_Yes : Listen_No);
		}
	}
}

public Action Timer_ConnectPost(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Continue;

	QueryClientConVar(client, "sv_allowupload", OnQueryFinished, userid);
	QueryClientConVar(client, "cl_allowdownload", OnQueryFinished, userid);
	QueryClientConVar(client, "cl_downloadfilter", OnQueryFinished, userid);

	if(!NoMusic)
	{
		int song = CheckCommandAccess(client, "thediscffthing", ADMFLAG_CUSTOM4) ? Music_JoinAlt : Music_Join;

		int volume;
		static char buffer[PLATFORM_MAX_PATH];
		float duration = Gamemode_GetMusic(client, song, buffer, volume);
		ChangeSong(client, duration+GetGameTime(), buffer, volume);
	}

	PrintToConsole(client, " \n \nWelcome to SCP: Secret Fortress\n \nThis is a gamemode based on the SCP series and community\nPlugin is created by Batfoxkid\n ");

	DisplayCredits(client);
	return Plugin_Continue;
}

void ChangeSong(int client, float next, const char[] filepath, int volume=2)
{
	if(Client[client].CurrentSong[0])
	{
		for(int i; i<Client[client].CurrentVolume; i++)
		{
			StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
		}
	}

	if(Client[client].DownloadMode || !filepath[0])
	{
		Client[client].CurrentSong[0] = 0;
		Client[client].CurrentVolume = 0;
		Client[client].NextSongAt = FAR_FUTURE;
		return;
	}

	strcopy(Client[client].CurrentSong, sizeof(Client[].CurrentSong), filepath);
	Client[client].CurrentVolume = volume;
	Client[client].NextSongAt = next;
	for(int i; i<volume; i++)
	{
		EmitSoundToClient(client, filepath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	}
}

void ChangeGlobalSong(float next, const char[] filepath, int volume=2)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			ChangeSong(client, next, filepath, volume);
	}
}

public void DisplayHint(bool all)
{
	char buffer[16];
	static int amount;
	if(!amount)
	{
		do
		{
			amount++;
			FormatEx(buffer, sizeof(buffer), "hint_%d", amount);
		} while(TranslationPhraseExists(buffer));
	}

	if(amount < 2)
		return;

	amount = GetRandomInt(1, amount-1);
	FormatEx(buffer, sizeof(buffer), "hint_%d", amount);

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && (all || IsSpec(client)))
			PrintKeyHintText(client, "%t", buffer);
	}
}

public Action ShowClassInfoTimer(Handle timer, int userid)
{
	if(Enabled)
	{
		int client = GetClientOfUserId(userid);
		if(client && IsClientInGame(client))
			ShowClassInfo(client);
	}
	return Plugin_Continue;
}

void ShowClassInfo(int client, bool help=false)
{
	Client[client].HelpSprint = true;

	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		SetGlobalTransTarget(client);

		SetHudTextParamsEx(-1.0, 0.3, help ? 16.0 : 3.5, Client[client].Colors, Client[client].Colors, 0, 5.0, 1.0, 4.0);
		ShowSyncHudText(client, HudClass, "%t", "you_are", class.Display);

		char buffer[32];
		if(!help && AreClientCookiesCached(client))	// If where not using !scpinfo, check if we ever played the tutorial before for this class
		{
			CookieTraining.Get(client, buffer, sizeof(buffer));	// TODO: Support for dynamic classes

			int flags = StringToInt(buffer);
			int flag = RoundFloat(Pow(2.0, float(view_as<int>(Client[client].Class))));
			if(!(flags & flag))
			{
				flags |= flag;
				IntToString(flags, buffer, sizeof(buffer));
				CookieTraining.Set(client, buffer);
				help = true;
			}
		}

		if(help)
		{
			Client[client].HudIn = GetGameTime();
			Client[client].HudIn += 19.5;

			FormatEx(buffer, sizeof(buffer), "train_%s", class.Name);
			if(TranslationPhraseExists(buffer))
			{
				SetHudTextParamsEx(-1.0, 0.5, 16.0, Client[client].Colors, Client[client].Colors, 1, 5.0, 1.0, 4.0);
				ShowSyncHudText(client, HudGame, "%t", buffer);
				return;
			}
		}

		Client[client].HudIn = GetGameTime()+11.0;

		FormatEx(buffer, sizeof(buffer), "desc_%s", class.Name);
		if(TranslationPhraseExists(buffer))
		{
			SetHudTextParamsEx(-1.0, 0.5, 3.5, Client[client].Colors, Client[client].Colors, 1, 5.0, 1.0, 4.0);
			ShowSyncHudText(client, HudGame, "%t", buffer);
		}
	}
}

bool AttemptGrabItem(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && !(Client[client].Disarmer && class.CanPickup))
	{
		int entity = GetClientPointVisible(client);
		if(entity > MaxClients)
			return Classes_OnPickup(client, entity);
	}
	return false;
}

bool DisarmCheck(int client)
{
	if(!Client[client].Disarmer)
		return false;

	if(IsValidClient(Client[client].Disarmer) && IsPlayerAlive(Client[client].Disarmer))
	{
		static float pos1[3], pos2[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
		GetEntPropVector(Client[client].Disarmer, Prop_Send, "m_vecOrigin", pos2);

		// 800 units
		if(GetVectorDistance(pos1, pos2, true) < 640000.0)
		{
			Client[client].LastDisarmedTime = GetGameTime();
			return true;
		}
	}

	TF2_RemoveCondition(client, TFCond_PasstimePenaltyDebuff);
	Client[client].Disarmer = 0;
	return false;
}

bool IsFriendly(int index1, int index2)
{
	ClassEnum class1, class2;
	if(Classes_GetByIndex(index1, class1) && class1.Group!=-1
	&& Classes_GetByIndex(index2, class2) && class2.Group!=-1)
	{
		if(class1.Group<0 || class1.Group!=class2.Group)
			return false;
	}
	return true;
}

bool IsBadKill(int victim, int attacker, int savedattackerclass)
{
	ClassEnum victimclass, attackerclass;
	if (!Classes_GetByIndex(Client[victim].Class, victimclass) || !Classes_GetByIndex(savedattackerclass, attackerclass))
		return false;

	if (victimclass.Group < 0)
		return false;
	if (attackerclass.Group == victimclass.Group)
		return true;
	// SCP
	if (!victimclass.Human || !attackerclass.Human)
		return false;

	// apply a kerma penalty for this damage if:
	// -> scientist/mtf/guard kills an unarmed dboi, unless he was disarmed recently but is NOT disarmed at the moment
	// -> dboi kills an unarmed scientist		

	if (Items_IsHoldingWeapon(victim) || Items_WasHoldingWeaponRecently(victim))
		return false;

	int dboi_index = Classes_GetByName("dboi");
	int sci_index = Classes_GetByName("sci");

	bool attacker_mtf = (attackerclass.Group > 1) || (Client[attacker].Class == sci_index);
	bool attacker_dboi = (Client[attacker].Class == dboi_index);
	bool victim_dboi = (Client[victim].Class == dboi_index);
	bool victim_scientist = (Client[victim].Class == sci_index);

	if ((attacker_mtf && victim_dboi && (Client[victim].Disarmer || ((Client[victim].LastDisarmedTime + 15.0) < GetGameTime())))
		|| (victim_scientist && attacker_dboi))
	{
		return true;
	}

	return false;
}

void PlayFriendlyDeathReaction(int client, int attacker)
{
	float pos[3];
	GetClientEyePosition(client, pos);
	
	int targetclients[MAXPLAYERS];
	int targetcount = 0;

	float Time = GetGameTime();
	
	// when someone dies, check if any players nearby should react to this tragedy
	for (int i=1; i<=MaxClients; i++)
	{
		if (i == client)
			continue;
			
		if (i == attacker)
			continue;

		if (!IsValidClient(i) || IsSpec(i) || IsSCP(i))
			continue;	
			
		// ignore crouching players, as they are likely trying to be sneaky
		if (GetEntityFlags(i) & FL_DUCKING)
			continue;
		
		// can we play a react now?
		if (Client[i].NextReactTime > Time)
			continue;
			
		if (!IsFriendly(Client[client].Class, Client[i].Class))
			continue;
			
		float pos2[3], ang2[3], fwd2[3];
		GetClientEyePosition(i, pos2);	
	
		float distsqr = GetVectorDistance(pos, pos2, true);	
		if (distsqr > 1048576.0) // 1024 units - too far away to react
			continue;
		
		GetClientEyeAngles(i, ang2);
		GetAngleVectors(ang2, fwd2, NULL_VECTOR, NULL_VECTOR);
		
		// check if we can see the guy
		TR_TraceRayFilter(pos, pos2, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);			
		if (TR_DidHit())
			continue;
		
		// add him to target list
		targetclients[targetcount++] = i;
	}

	for (int i = 0; i < targetcount; i++)
	{	
		// scale the chance of the reaction playing depending on the amount of targets that saw this player die
		// if only 1 or 2 players saw it then always play the react, otherwise diminish the chance to 1/3 and then 1/4
		bool success;
		int maxdelay;

		if (targetcount <= 2)
		{
			success = true;
			maxdelay = 70;
		}
		else if (targetcount <= 5)
		{
			success = (GetRandomInt(0, 2) == 0);
			maxdelay = 100;
		}
		else
		{
			success = (GetRandomInt(0, 3) == 0);	
			maxdelay = 130;		
		}

		if (success)
		{
			// between 0.4 and 1.0 seconds
			int targetclient = targetclients[i];
			CreateTimer(float(GetRandomInt(40, maxdelay)) / 100.0, Timer_FriendlyDeathReaction, targetclient, TIMER_FLAG_NO_MAPCHANGE);
			Client[targetclient].NextReactTime = Time + 5.0;
		}
	}
}

// thanks to dysphie for the I/O offsets
public void FixUpDoors()
{
	// workaround for horrible door logic
	// there is no direct way to tell apart what is a "checkpoint" and normal door in the scp maps
	// this is needed for frag grenade/scp18/096 door destruction logic
	// however, the maps have a whacky manual setup for 096, which we will abuse to find what is a "checkpoint" door
	
	// - iterate all triggers and see if they use the 096 rage filter entity
	// - if so, check the outputs
	// -- if it has a OnTrigger Kill output, then its a normal door
	// -- if it has a OnTrigger Open output, then its a checkpoint door
	// -- if it has a OnTrigger FireUser1 output, then its a door that needs special logic executed (914)
	// - iterate all doors with the built list of doors and flag them accordingly

	#define DOOR_NAME_LENGTH 32
	
	int entity = MaxClients+1;
	char name[64], target[DOOR_NAME_LENGTH], targetinput[32], temp[DOOR_NAME_LENGTH];
		
	ArrayList doorlist_normal = new ArrayList(DOOR_NAME_LENGTH);
	ArrayList doorlist_checkpoint = new ArrayList(DOOR_NAME_LENGTH);	
	ArrayList doorlist_trigger = new ArrayList(DOOR_NAME_LENGTH);
	ArrayList relaylist_trigger = new ArrayList(DOOR_NAME_LENGTH);
	ArrayList relayentlist_trigger = new ArrayList();

	while ((entity = FindEntityByClassname(entity, "trigger_*")) > MaxClients)
	{
		GetEntPropString(entity, Prop_Data, "m_iFilterName", name, sizeof(name));
		if (StrContains(name, "096rage") != -1)
		{
			// this trigger belongs to a door, now check the outputs
			// get the offsets to the OnTrigger outputs
			int offset = FindDataMapInfo(entity, "m_OnTrigger");
			if (offset == -1)
				continue;
			
			Address output = GetEntityAddress(entity) + view_as<Address>(offset);
			Address actionlist = view_as<Address>(LoadFromAddress(output + view_as<Address>(0x14), NumberType_Int32));
			
			// note: there can be multiple different doors being killed/opened in the outputs
			while (actionlist)
			{
				// these are the only 2 parts of the output we care about
				Address iTarget = view_as<Address>(LoadFromAddress(actionlist, NumberType_Int32));
				StringtToCharArray(iTarget, target, sizeof(target));		
				
				// ignore !self outputs
				if (target[0] != '!')
				{	
					Address iTargetInput = view_as<Address>(LoadFromAddress(actionlist + view_as<Address>(0x4), NumberType_Int32));
					StringtToCharArray(iTargetInput, targetinput, sizeof(targetinput));				
					
					if (StrEqual(targetinput, "Kill", true))
					{
						// we are killing a door, which implies its a normal door
						doorlist_normal.PushString(target);
					}
					else if (StrEqual(targetinput, "Open", true))
					{
						// we are simply opening the door, which implies its a checkpoint door
						// becareful, this output is also used for areaportals, so we gotta ensure thats not the case
						if (StrContains(target, "areaportal") == -1)
						{
							doorlist_checkpoint.PushString(target);
						}
					}
					// TODO: I'm not sure about this, it needs more testing across different maps
					// for now just ignore special doors
					//else if (StrEqual(targetinput, "FireUser1", true))
					//{
					//	// this is a special door that needs specific logic to run (914)
					//	if (StrContains(target, "scp_access") != -1)
					//	{
					//		relaylist_trigger.PushString(target);
					//	}
					//}			
				}

				// go to the next output
				actionlist = view_as<Address>(LoadFromAddress(actionlist + view_as<Address>(0x18), NumberType_Int32));						
			}		
			
			// get rid of the trigger, since we will handle it's logic now
			AcceptEntityInput(entity, "Kill");
		}
	}		

	// deal with any relays first
	if (relaylist_trigger.Length)
	{
		entity = -1;
		while ((entity = FindEntityByClassname(entity, "logic_relay")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
							
			int offset = FindDataMapInfo(entity, "m_OnTrigger");
			if (offset == -1)
				continue;
					
			for (int i = relaylist_trigger.Length - 1; i >= 0; i--)
			{
				relaylist_trigger.GetString(i, temp, sizeof(temp));
				if (StrEqual(temp, name, false))
				{
					// go through it's outputs and find the "Toggle" one, that is the door
					Address output = GetEntityAddress(entity) + view_as<Address>(offset);
					Address actionlist = view_as<Address>(LoadFromAddress(output + view_as<Address>(0x14), NumberType_Int32));
					
					while (actionlist)	
					{
						Address iTargetInput = view_as<Address>(LoadFromAddress(actionlist + view_as<Address>(0x4), NumberType_Int32));
						StringtToCharArray(iTargetInput, targetinput, sizeof(targetinput));
						
						if (StrEqual(targetinput, "Toggle", true))
						{						
							// this is the door!
							Address iTarget = view_as<Address>(LoadFromAddress(actionlist, NumberType_Int32));
							StringtToCharArray(iTarget, target, sizeof(target));					
							
							doorlist_trigger.PushString(target);
							// store off our relay's entref, we will store that in the door later
							relayentlist_trigger.Push(EntIndexToEntRef(entity));
				
							break;
						}
												
						// go to the next output
						actionlist = view_as<Address>(LoadFromAddress(actionlist + view_as<Address>(0x18), NumberType_Int32));						
					}		
								
					relaylist_trigger.Erase(i);
				}
			}
			
			// Nothing left to do?
			if (!relaylist_trigger.Length)
				break;
		}
	}
	
	// no doors found? bail
	if (!doorlist_normal.Length && !doorlist_checkpoint.Length && !doorlist_trigger.Length)
	{
		delete doorlist_normal;
		delete doorlist_checkpoint;	
		delete doorlist_trigger;
		delete relaylist_trigger;
		delete relayentlist_trigger;
		return;
	}
	
	// go through all doors, compare the name against the list, then flag it accordingly
	entity = MaxClients+1;
	while ((entity = FindEntityByClassname(entity, "func_door")) > MaxClients)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		
		// go backwards the list since we can remove elements, we don't need to test a name again if we found that door already
		// go through normal doors first, they are the most likely ones to be found first
		bool found_door = false;
		for (int i = doorlist_normal.Length - 1; i >= 0; i--)
		{
			doorlist_normal.GetString(i, temp, sizeof(temp));
			if (StrEqual(temp, name, false))
			{
				SetEntProp(entity, Prop_Data, DOOR_ID_PROP, DOOR_ID_NORMAL);
			}
		}
		
		// checkpoint doors...
		for (int i = doorlist_checkpoint.Length - 1; i >= 0; i--)
		{
			doorlist_checkpoint.GetString(i, temp, sizeof(temp));
			if (StrEqual(temp, name, false))
			{
				SetEntProp(entity, Prop_Data, DOOR_ID_PROP, DOOR_ID_CHECKPOINT);
			}
		}			

		// special trigger doors
		for (int i = doorlist_trigger.Length - 1; i >= 0; i--)
		{
			doorlist_trigger.GetString(i, temp, sizeof(temp));
			if (StrEqual(temp, name, false))
			{
				SetEntProp(entity, Prop_Data, DOOR_ID_PROP, DOOR_ID_TRIGGER);
				// store the relay so we can trigger it later
				SetEntProp(entity, Prop_Send, DOOR_ENTREF_PROP, relayentlist_trigger.Get(i));
			}
		}			
	}
			
	delete doorlist_normal;
	delete doorlist_checkpoint;	
	delete doorlist_trigger;
	delete relaylist_trigger;
	delete relayentlist_trigger;
}

// attempt to destroy a given door, if it can't be destroyed then it will be opened/triggered instead
// returns false if the door couldn't be destroyed nor opened
public bool DestroyOrOpenDoor(int door)
{
	int doorState = GetEntProp(door, Prop_Data, "m_toggle_state");	
	int doorID = GetEntProp(door, Prop_Data, DOOR_ID_PROP);
	
	// only attempt to destroy fully closed doorss
	if (doorState != 1)
		return false;		

	switch (doorID)
	{
		case DOOR_ID_NORMAL:
		{
			EmitSoundToAll("physics/metal/metal_grate_impact_hard2.wav", door, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			AcceptEntityInput(door, "Kill");
			return true;
		}
		case DOOR_ID_CHECKPOINT:
		{
			EmitSoundToAll("physics/metal/metal_grate_impact_hard1.wav", door, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
			AcceptEntityInput(door, "Open");
			return true;
		}
		case DOOR_ID_TRIGGER:
		{
			EmitSoundToAll("physics/metal/metal_grate_impact_hard3.wav", door, SNDCHAN_AUTO, SNDLEVEL_TRAIN);			
			int doorRelay = EntRefToEntIndex(GetEntProp(door, Prop_Send, DOOR_ENTREF_PROP));
			AcceptEntityInput(doorRelay, "FireUser1");
			return true;
		}
	}
	
	return false;
}

public Action Timer_FriendlyDeathReaction(Handle timer, int client)
{
	if (IsValidClient(client))
		Config_DoReaction(client, "friendlydeath");

	return Plugin_Stop;
}

public int OnQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, int userid)
{
	if(Client[client].DownloadMode==2 || GetClientOfUserId(userid)!=client || !IsClientInGame(client))
		return 0;

	if(result != ConVarQuery_Okay)
	{
		CPrintToChat(client, "%s%t", PREFIX, "download_error", cvarName);
	}
	else if(StrEqual(cvarName, "cl_allowdownload") || StrEqual(cvarName, "sv_allowupload"))
	{
		if(!StringToInt(cvarValue))
		{
			CPrintToChat(client, "%s%t", PREFIX, "download_cvar", cvarName, cvarName);
			Client[client].DownloadMode = 2;
			TF2Attrib_SetByDefIndex(client, 406, 4.0);
		}
	}
	else if(StrEqual(cvarName, "cl_downloadfilter"))
	{
		if(StrContains("all", cvarValue) == -1)
		{
			if(StrContains("nosounds", cvarValue) != -1)
			{
				CPrintToChat(client, "%s%t", PREFIX, "download_filter_sound");
				Client[client].DownloadMode = 1;
			}
			else
			{
				CPrintToChat(client, "%s%t", PREFIX, "download_filter", cvarValue);
				Client[client].DownloadMode = 2;
				TF2Attrib_SetByDefIndex(client, 406, 4.0);
			}
		}
	}
	return 0;
}

// Thirdparty

public Action OnStomp(int attacker, int victim)
{
	if(!Enabled)
		return Plugin_Continue;

	int health;
	OnGetMaxHealth(attacker, health);
	if(health < 300)
		return Plugin_Handled;

	OnGetMaxHealth(victim, health);
	return health<300 ? Plugin_Handled : Plugin_Continue;
}

public Action CH_ShouldCollide(int client, int entity, bool &result)
{
	//if(result)
	{
		if(client>0 && client<=MaxClients)
		{
			static char buffer[16];
			GetEntityClassname(entity, buffer, sizeof(buffer));
			if(!StrContains(buffer, "func_door") || StrEqual(buffer, "func_movelinear") || !StrContains(buffer, "func_brush"))
			{
				result = Classes_OnDoorWalk(client, entity);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

#if defined _SENDPROXYMANAGER_INC_

#if defined SENDPROXY_LIB
public Action SendProp_OnAlive(const int entity, const char[] propname, int &value, const int element, const int client)
#else
public Action SendProp_OnAlive(int entity, const char[] propname, int &value, int element)
#endif
{
	value = 1;
	return Plugin_Changed;
}

public Action SendProp_OnAliveMulti(const int entity, const char[] propname, int &value, const int element, const int client)
{
	if(!Enabled)
	{
		value = 1;
	}
	else if(IsValidClient(client))
	{
		if(IsSpec(client))
		{
			if(!IsValidClient(element))
				return Plugin_Continue;

			value = IsSpec(element) ? 0 : 1;
		}
	}
	else if(Client[client].ThinkIsDead[element])
	{
		value = 0;
	}
	else
	{
		value = 1;
	}
	return Plugin_Changed;
}

#if defined SENDPROXY_LIB
public Action SendProp_OnTeam(const int entity, const char[] propname, int &value, const int element, const int client)
#else
public Action SendProp_OnTeam(int entity, const char[] propname, int &value, int element)
#endif
{
	if(!IsValidClient(element) || (GetClientTeam(element)<2 && !IsPlayerAlive(element)))
		return Plugin_Continue;

	value = Client[element].IsVip ? view_as<int>(TFTeam_Blue) : view_as<int>(TFTeam_Red);
	return Plugin_Changed;
}

#if defined SENDPROXY_LIB
public Action SendProp_OnClass(const int entity, const char[] propname, int &value, const int element, const int client)
#else
public Action SendProp_OnClass(int entity, const char[] propname, int &value, int element) 
#endif
{
	if(!Enabled)
		return Plugin_Continue;

	value = view_as<int>(TFClass_Unknown);
	return Plugin_Changed;
}

#if defined SENDPROXY_LIB
public Action SendProp_OnClientClass(const int entity, const char[] propname, int &value, const int element, const int client)
#else
public Action SendProp_OnClientClass(int entity, const char[] propname, int &value, int element)
#endif
{
	if(Client[entity].WeaponClass == TFClass_Unknown)
		return Plugin_Continue;

	value = view_as<int>(Client[entity].WeaponClass);
	return Plugin_Changed;
}
#endif
