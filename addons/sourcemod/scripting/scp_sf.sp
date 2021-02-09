#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <tf2items>
#include <morecolors>
#include <tf2attributes>
#include <dhooks>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <devzones>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#define REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
//#tryinclude <collisionhook>
#tryinclude <sendproxy>
#define REQUIRE_EXTENSIONS

#pragma newdecls required

void DisplayCredits(int i)
{
	PrintToConsole(i, "Useful Stocks | sarysa | forums.alliedmods.net/showthread.php?t=309245");
	PrintToConsole(i, "SDK/DHooks Functions | Mikusch, 42 | github.com/Mikusch/fortress-royale");
	PrintToConsole(i, "Medi-Gun Hooks | naydef | forums.alliedmods.net/showthread.php?t=311520");
	PrintToConsole(i, "ChangeTeamEx | Benoist3012 | forums.alliedmods.net/showthread.php?t=314271");
	PrintToConsole(i, "Client Eye Angles | sarysa | forums.alliedmods.net/showthread.php?t=309245");
	PrintToConsole(i, "Fire Death Animation | 404UNF, Rowedahelicon | forums.alliedmods.net/showthread.php?t=255753");
	PrintToConsole(i, "Revive Markers | 93SHADoW, sarysa | forums.alliedmods.net/showthread.php?t=248320");
	PrintToConsole(i, "Transmit Outlines | nosoop | forums.alliedmods.net/member.php?u=252787");
	PrintToConsole(i, "Move Speed Unlocker | xXDeathreusXx | forums.alliedmods.net/member.php?u=224722");

	PrintToConsole(i, "Chaos, SCP-049-2 Rigs | DoctorKrazy | forums.alliedmods.net/member.php?u=288676");
	PrintToConsole(i, "MTF Rig | JuegosPablo | forums.alliedmods.net/showthread.php?t=308656");
	PrintToConsole(i, "SCP-173 Port | RavensBro | forums.alliedmods.net/showthread.php?t=203464");
	PrintToConsole(i, "SCP Animations | Badget | steamcommunity.com/profiles/76561198097667312");
	PrintToConsole(i, "Soundtracks | Jacek \"Burnert\" Rogal");

	PrintToConsole(i, "Cosmic Inspiration | Marxvee | forums.alliedmods.net/member.php?u=289257");
	PrintToConsole(i, "Map/Model Development | Artvin | forums.alliedmods.net/member.php?u=304206");
}

#define MAJOR_REVISION	"2"
#define MINOR_REVISION	"0"
#define STABLE_REVISION	"0"
#define PLUGIN_VERSION	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define FAR_FUTURE	100000000.0
#define MAXTF2PLAYERS	36
#define MAXENTITIES	2048

#define ITEMS_MAX	8
#define MAXANGLEPITCH	45.0
#define MAXANGLEYAW	90.0

#define PREFIX		"{red}[SCP]{default} "

float TRIPLE_D[3] = { 0.0, 0.0, 0.0 };

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

enum
{
	Ammo_Micro = 1,
	Ammo_9mm,
	Ammo_Metal,
	Ammo_Misc1,
	Ammo_Misc2,
	Ammo_7mm,
	Ammo_5mm,
	Ammo_Grenade,
	Ammo_Radio,
	Ammo_MAX
}

bool Enabled = false;
bool NoMusic = false;
bool ChatHook = true;
bool SourceComms = false;		// SourceComms++
bool BaseComm = false;		// BaseComm

Handle HudPlayer;
Handle HudClass;
Handle HudGame;

Cookie CookieTraining;
Cookie CookieColor;
Cookie CookieDClass;

//ConVar CvarSpecGhost;
ConVar CvarFriendlyFire;
ConVar CvarSpeedMulti;
ConVar CvarSpeedMax;
ConVar CvarAchievement;
ConVar CvarChatHook;

float NextHintAt = FAR_FUTURE;
float RoundStartAt;
float EndRoundIn;
bool NoMusicRound;

enum struct ClientEnum
{
	int Class;
	int Colors[4];
	int ColorBlind[3];

	bool IsVip;
	bool CanTalkTo[MAXTF2PLAYERS];

	TFClassType CurrentClass;
	TFClassType WeaponClass;

	bool HelpSprint;
	bool HelpSwitch;

	int Extra1;
	int Extra2;
	float Extra3;

	int Floor;
	int Disarmer;
	int DownloadMode;

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

	// Sprinting
	bool Sprinting;
	float SprintPower;

	// Music
	float NextSongAt;
	char CurrentSong[PLATFORM_MAX_PATH];
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
#include "scp_sf/natives.sp"
#include "scp_sf/sdkcalls.sp"
#include "scp_sf/sdkhooks.sp"
#include "scp_sf/targetfilters.sp"
#include "scp_sf/viewchanges.sp"
#include "scp_sf/viewmodels.sp"

#include "scp_sf/scps/049.sp"
#include "scp_sf/scps/076.sp"
#include "scp_sf/scps/096.sp"
#include "scp_sf/scps/106.sp"
#include "scp_sf/scps/173.sp"
#include "scp_sf/scps/939.sp"

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

	GameData gamedata = LoadGameConfigFile("scp_sf");
	if(gamedata)
	{
		SDKCall_Setup(gamedata);
		DHook_Setup(gamedata);

		Address address = GameConfGetAddress(gamedata, "ProcessMovement");
		if(address == Address_Null)
		{
			LogError("[Gamedata] Could not find ProcessMovement");
		}
		else
		{
			for(int i; i<7; i++)
			{
				StoreToAddress(address+view_as<Address>(i), 0x90, NumberType_Int8);
			}
		}
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
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrEqual(buffer, "scp_nomusic", false))
			continue;

		NoMusic = true;
		break;
	}

	#if defined _SENDPROXYMANAGER_INC_
	if(GetFeatureStatus(FeatureType_Native, "SendProxy_HookArrayProp") == FeatureStatus_Available)
	{
		entity = FindEntityByClassname(-1, "tf_player_manager");
		if(entity > MaxClients)
		{
			for(int i=1; i<=MaxClients; i++)
			{
				SendProxy_HookArrayProp(entity, "m_bAlive", i, Prop_Int, SendProp_OnAlive);
				SendProxy_HookArrayProp(entity, "m_iTeam", i, Prop_Int, SendProp_OnTeam);
				SendProxy_HookArrayProp(entity, "m_iPlayerClass", i, Prop_Int, SendProp_OnClass);
				SendProxy_HookArrayProp(entity, "m_iPlayerClassWhenKilled", i, Prop_Int, SendProp_OnClass);
			}
		}
	}
	#endif

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
	}
}

public void OnPluginEnd()
{
	ConVar_Disable();
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
			DHook_UnhookClient(i);
	}

	char buffer[2];
	if(Enabled && GetCurrentMap(buffer, sizeof(buffer)))
		EndRound(0);
}

public void OnClientPutInServer(int client)
{
	Client[client] = Client[0];
	if(AreClientCookiesCached(client))
		OnClientCookiesCached(client);

	SDKHook_HookClient(client);
	DHook_HookClient(client);
	#if defined _SENDPROXYMANAGER_INC_
	if(GetFeatureStatus(FeatureType_Native, "SendProxy_Hook") == FeatureStatus_Available)
		SendProxy_Hook(client, "m_iClass", Prop_Int, SendProp_OnClientClass);
	#endif
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
	RoundStartAt = GetEngineTime();
	NextHintAt = RoundStartAt+60.0;

	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "func_regenerate")) != -1)
	{
		AcceptEntityInput(entity, "Disable");
	}

	entity = -1;
	while((entity=FindEntityByClassname2(entity, "func_respawnroomvisualizer")) != -1)
	{
		AcceptEntityInput(entity, "Disable");
	}

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

		Client[client].IsVip = CheckCommandAccess(client, "sm_trailsvip", ADMFLAG_CUSTOM5);

		if(IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
			ChangeClientTeamEx(client, TFTeam_Red);

		SDKCall_SetSpeed(client);
		Client[client].NextSongAt = FAR_FUTURE;
		if(!Client[client].CurrentSong[0])
			continue;

		for(int i; i<3; i++)
		{
			StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
		}
		Client[client].CurrentSong[0] = 0;
	}

	UpdateListenOverrides(FAR_FUTURE);
	Gamemode_RoundEnd();
}

public Action OnWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
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
				value = Items_OnKeycard(client, access);

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
			int ent, i;
			WeaponEnum weapon;
			while((ent=Items_Iterator(client, i)) != -1)
			{
				if(!Items_GetWeaponByIndex(GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex"), weapon))
					continue;

				if(weapon.Type == Item_Keycard)
				{
					if(ent == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
						Items_SwitchItem(client, ent);

					TF2_RemoveItem(client, ent);
				}
			}
		}
	}
	else if(!StrContains(name, "scp_endmusic", false))
	{
		NoMusicRound = true;
		for(int target=1; target<=MaxClients; target++)
		{
			Client[target].NextSongAt = FAR_FUTURE;
			if(!IsValidClient(target) || !Client[target].CurrentSong[0])
				continue;

			StopSound(target, SNDCHAN_STATIC, Client[target].CurrentSong);
			StopSound(target, SNDCHAN_STATIC, Client[target].CurrentSong);
			Client[target].CurrentSong[0] = 0;
		}
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
			if(Client[client].Cooldown > GetEngineTime())
			{
				Menu menu = new Menu(Handler_None);
				menu.SetTitle("%t\n ", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "in_cooldown");
				menu.AddItem("", buffer);

				menu.ExitButton = false;
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

				menu.ExitButton = false;
				menu.Display(client, 10);
			}
		}
	}
	else if(!StrContains(name, "scp_intercom", false))
	{
		if(Enabled && IsValidClient(client))
		{
			Client[client].ComFor = GetEngineTime()+15.0;
			GiveAchievement(Achievement_Intercom, client);
		}
	}
	else if(!StrContains(name, "scp_nuke", false))
	{
		if(Enabled)
			GiveAchievement(Achievement_SurviveWarhead, 0);
	}
	return Plugin_Continue;
}

public int Handler_None(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_End)
		delete menu;
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
								Client[client].Cooldown = GetEngineTime()+17.5;
								if(weapon.VeryFine[0])
									amount = ExplodeString(weapon.VeryFine, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 1:
							{
								Client[client].Cooldown = GetEngineTime()+15.0;
								if(weapon.Fine[0])
									amount = ExplodeString(weapon.Fine, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 2:
							{
								Client[client].Cooldown = GetEngineTime()+12.5;
								if(weapon.OneToOne[0])
									amount = ExplodeString(weapon.OneToOne, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 3:
							{
								Client[client].Cooldown = GetEngineTime()+10.0;
								if(weapon.Coarse[0])
									amount = ExplodeString(weapon.Coarse, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 4:
							{
								Client[client].Cooldown = GetEngineTime()+7.5;
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
									RemoveAndSwitchItem(client, entity);
									CPrintToChat(client, "%s%t", PREFIX, "914_delet");
								}
							}
							else if(Items_GetWeaponByIndex(amount, weapon))
							{
								TF2_RemoveItem(client, entity);
								if(choice<2 && weapon.Type==Item_Keycard && Client[client].Class==Classes_GetByName("sci"))
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

								bool canGive = Items_CanGiveItem(client, weapon.Type);
								entity = Items_CreateWeapon(client, amount, canGive, true, false);
								if(canGive && entity>MaxClients && IsValidEntity(entity))
								{
									SetActiveWeapon(client, entity);
								}
								else
								{
									static float pos[3], ang[3];
									GetClientEyePosition(client, pos);
									GetClientEyeAngles(client, ang);
									Items_DropItem(client, entity, pos, ang, true);
									FakeClientCommand(client, "use tf_weapon_fists");
								}

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
			Client[client].IgnoreTeleFor = GetEngineTime()+3.0;
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
	if(!client)
		return;

	ViewModel_Destroy(client);

	Client[client].Sprinting = false;
	Client[client].ChargeIn = 0.0;
	Client[client].Disarmer = 0;
	Client[client].SprintPower = 100.0;
	Client[client].WeaponClass = TFClass_Unknown;

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
	return Plugin_Changed;
}

public Action OnBlockCommand(int client, const char[] command, int args)
{
	return Enabled ? Plugin_Handled : Plugin_Continue;
}

public Action OnJoinClass(int client, const char[] command, int args)
{
	return (client && IsPlayerAlive(client)) ? Plugin_Handled : Plugin_Continue;
}

public Action OnPlayerSpray(const char[] name, const int[] clients, int count, float delay)
{
	int client = TE_ReadNum("m_nPlayer");
	return (IsClientInGame(client) && TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)) ? Plugin_Handled : Plugin_Continue;
}

public Action OnJoinAuto(int client, const char[] command, int args)
{
	if(!client || !Enabled)
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
	if(!client)
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
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	Client[client].IdleAt = GetEngineTime()+2.5;
	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		int attempts;
		int i = Client[client].Extra2+1;
		do
		{
			if(IsValidClient(i) && !IsSpec(i))
			{
				static float pos[3], ang[3];
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
				GetClientEyeAngles(i, ang);
				SetEntProp(client, Prop_Send, "m_bDucked", true);
				SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
				TeleportEntity(client, pos, ang, TRIPLE_D);
				Client[client].Extra2 = i;
				break;
			}
			i++;
			attempts++;

			if(i > MaxClients)
				i = 1;
		} while(attempts < MAXTF2PLAYERS);
		return Plugin_Handled;
	}

	if(AttemptGrabItem(client))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnDropItem(int client, const char[] command, int args)
{
	if(client && !IsSpec(client))
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Human)
		{
			int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(entity > MaxClients)
			{
				WeaponEnum weapon;
				bool big = (Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) && weapon.Type==Item_Weapon);

				static float pos[3], ang[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, ang);
				if(Items_DropItem(client, entity, pos, ang, true))
				{
					if(big)
					{
						ClientCommand(client, "playgamesound BaseCombatWeapon.WeaponDrop");
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
	if(!client)
		return Plugin_Continue;

	#if defined _sourcecomms_included
	if(SourceComms && SourceComms_GetClientGagType(client)>bNot)
		return Plugin_Handled;
	#endif

	#if defined _basecomm_included
	if(BaseComm && BaseComm_IsClientGagged(client))
		return Plugin_Handled;
	#endif

	float time = GetEngineTime();
	if(Client[client].ChatIn > time)
		return Plugin_Handled;

	Client[client].ChatIn = time+1.5;

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

	float engineTime = GetEngineTime();

	if(!Enabled)
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target]))
				CPrintToChat(target, "%s {default}: %s", name, msg);
		}
	}
	else if(!IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target] && IsSpec(target)))
				CPrintToChat(target, "*SPEC* %s {default}: %s", name, msg);
		}
	}
	else if(IsSpec(client))
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target] && IsSpec(target)))
				CPrintToChat(target, "*DEAD* %s {default}: %s", name, msg);
		}
	}
	else if(Client[client].ComFor > engineTime)
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target]))
				CPrintToChat(target, "*COMM* %s {default}: %s", name, msg);
		}
	}
	else
	{
		#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR>10
		Client[client].IdleAt = engineTime+2.5;
		#endif

		bool radio = Items_Radio(client)>1;

		ClassEnum class;
		if(!Classes_GetByIndex(Client[client].Class, class))
			class.Human = true;	// If we somehow have an invalid class, atleast prevent errors

		static float clientPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
		for(int target=1; target<=MaxClients; target++)
		{
			if(target != client)
			{
				if(!IsValidClient(target, false) || !Client[client].CanTalkTo[target])
					continue;

				if(!IsSpec(target))
				{
					if(!class.Human && IsFriendly(Client[client].Class, Client[target].Class))
					{
						CPrintToChat(target, "(%t) %s {default}: %s", class.Display, name, msg);
						continue;
					}

					if(radio)
					{
						static float targetPos[3];
						GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
						if(GetVectorDistance(clientPos, targetPos) > 400)
						{
							CPrintToChat(target, "*RADIO* %s {default}: %s", name, msg);
							continue;
						}
					}
				}
			}
			else if(!class.Human)
			{
				CPrintToChat(target, "(%t) %s {default}: %s", class.Display, name, msg);
				continue;
			}

			CPrintToChat(target, "%s {default}: %s", name, msg);
		}
	}
	return Plugin_Handled;
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
		ReplyToCommand(client, "[SM] Invalid class string");
		return Plugin_Handled;
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

		Client[targets[target]].Class = index;
		TF2_RespawnPlayer(targets[target]);
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

public void OnClientDisconnect(int client)
{
	CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if(item)
	{
		if(TF2Items_GetLevel(item) == 101)
			return Plugin_Continue;
	}

	switch(index)
	{
		case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
		{
			return Plugin_Continue;
		}
		case 125, 134, 136, 138, 260, 470, 640, 711, 712, 713, 1158:  //Special hats
		{
			ClassEnum class;
			if(Classes_GetByIndex(Client[client].Class, class) && class.Human)
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

	float engineTime = GetEngineTime();
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

		RequestFrame(UpdateListenOverrides, engineTime);
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
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

		Classes_OnKill(attacker, client);

		if(deadringer || !Classes_OnDeath(client, event))
		{
			event.BroadcastDisabled = true;
			for(int i=1; i<=MaxClients; i++)
			{
				if(i==client || i==attacker || (IsValidClient(i) && IsFriendly(Client[attacker].Class, Client[i].Class) && Client[attacker].CanTalkTo[i]))
					event.FireToClient(i);
			}
		}
	}
	else if(!Classes_OnDeath(client, event))
	{
		event.BroadcastDisabled = true;

		if(!deadringer)
		{
			int damage = event.GetInt("damagebits");
			if(damage & DMG_SHOCK)
			{
				GiveAchievement(Achievement_DeathTesla, client);
				int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==594)
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
				if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==308)
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

	float engineTime = GetEngineTime();
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
	if((buttons & IN_JUMP) || (buttons & IN_SPEED))
	{
		if(!Client[client].Sprinting)
		{
			Client[client].HelpSprint = false;
			Client[client].Sprinting = (Client[client].SprintPower>15 && (GetEntityFlags(client) & FL_ONGROUND));
			if(Client[client].Sprinting)
				SDKCall_SetSpeed(client);
		}
	}
	else if(Client[client].Sprinting)
	{
		Client[client].Sprinting = false;
		SDKCall_SetSpeed(client);
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
	else if(buttons & IN_ATTACK3)
	{
		Client[client].HelpSwitch = false;
		int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(entity>MaxClients && IsValidEntity(entity))
			Items_SwitchItem(client, entity);

		holding[client] = IN_ATTACK3;
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

	// Check if the player moved at all or is speaking
	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=10
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))))
	#else
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT)|| IsClientSpeaking(client))))
	#endif
		Client[client].IdleAt = engineTime+2.5;

	// SCP-specific buttons
	Classes_OnButton(client, wasHolding ? 0 : holding[client]);

	// HUD related things
	static float specialTick[MAXTF2PLAYERS];
	if(specialTick[client] < engineTime)
	{
		bool showHud = (Client[client].HudIn<engineTime && !(GetClientButtons(client) & IN_SCORE));
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

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Human && !IsSpec(client))
		{
			if(DisarmCheck(client))
			{
				Client[client].AloneIn = FAR_FUTURE;
				if(showHud)
				{
					SetHudTextParamsEx(0.01, 0.75, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
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

				if(Client[client].Sprinting)
				{
					if(!TF2_IsPlayerInCondition(client, TFCond_CritHype))
					{
						Client[client].SprintPower -= 2.0;
						if(Client[client].SprintPower < 0)
						{
							Client[client].SprintPower = 0.0;
							Client[client].Sprinting = false;
							SDKCall_SetSpeed(client);
						}
					}
				}
				else
				{
					if(Client[client].SprintPower < 100)
						Client[client].SprintPower += 0.75;
				}

				if(showHud)
				{
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

						ArrayList list = Items_ArrayList(client, TF2_GetClassnameSlot(buffer));
						int length = list.Length;
						if(length)
						{
							if(!showingHelp && length>1 && Client[client].HelpSwitch)
							{
								showingHelp = true;
								PrintKeyHintText(client, "%t", "help_switch");
							}

							buffer[0] = 0;

							for(int i=length-1; i>=0; i--)
							{
								static char tran[16];
								int entity = list.Get(i);
								Items_GetTranName(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), tran, sizeof(tran));
								Format(buffer, sizeof(buffer), "%t%s\n%s", tran, entity==active ? " <" : "", buffer);
							}

							SetHudTextParamsEx(0.01, 0.4-(float(length)/30.0), 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
							ShowSyncHudText(client, HudPlayer, buffer);
						}
						delete list;
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

			// What class am I again
			if(showHud)
			{
				SetHudTextParamsEx(-1.0, 0.06, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
				ShowSyncHudText(client, HudClass, "%t", class.Display);
			}
		}

		// And next theme please
		if(!NoMusic && !NoMusicRound && Client[client].NextSongAt<engineTime)
		{
			float time = Classes_OnTheme(client, buffer);
			if(time <= 0)
				time = Gamemode_GetMusic(client, Client[client].Floor, buffer);

			if(time > 0)
				ChangeSong(client, engineTime+time, buffer);
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnGameFrame()
{
	float engineTime = GetEngineTime();
	static float nextAt;
	if(nextAt > engineTime)
		return;

	nextAt = engineTime+1.0;
	UpdateListenOverrides(engineTime);

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
			static char buffer[PLATFORM_MAX_PATH];
			float duration = Gamemode_GetMusic(0, Music_Timeleft, buffer);
			if(duration > timeleft)
			{
				ChangeGlobalSong(FAR_FUTURE, buffer);
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

public Action CheckAlivePlayers(Handle timer)
{
	if(Enabled)
		Gamemode_CheckRound();

	return Plugin_Continue;
}

public void UpdateListenOverrides(float engineTime)
{
	if(!Enabled)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client, false))
				continue;

			for(int target=1; target<=MaxClients; target++)
			{
				if(!ChatHook)
				{
					Client[target].CanTalkTo[client] = true;
					continue;
				}

				if(client == target)
				{
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
	int[] team = new int[MaxClients];
	bool[] spec = new bool[MaxClients];
	bool[] admin = new bool[MaxClients];
	float[] radio = new float[MaxClients];
	static float pos[MAXTF2PLAYERS][3];
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i, false))
			continue;

		client[total] = i;
		team[total] = GetClientTeam(i);
		radio[total] = Items_Radio(i);
		spec[total] = GetClientTeam(i)==view_as<int>(TFTeam_Spectator);
		admin[total] = (spec[total] && CheckCommandAccess(i, "sm_mute", ADMFLAG_CHAT));
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos[total]);
		total++;
	}

	ClassEnum iclass, aclass;
	for(int i; i<total; i++)
	{
		Classes_GetByIndex(Client[i].Class, iclass);
		for(int a; a<total; a++)
		{
			if(client[i] == client[a])
			{
				if(ChatHook)
					SetListenOverride(client[i], client[a], Listen_Default);

				continue;
			}

			bool muted = (ChatHook && IsClientMuted(client[i], client[a]));
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
				if(ChatHook)
					SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Default);

				continue;
			}

			float range, hearing;
			Classes_GetByIndex(Client[a].Class, aclass);
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
			if(ChatHook)
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

		static char buffer[PLATFORM_MAX_PATH];
		float duration = Gamemode_GetMusic(client, song, buffer);
		ChangeSong(client, duration+GetEngineTime(), buffer);
	}

	PrintToConsole(client, " \n \nWelcome to SCP: Secret Fortress\n \nThis is a gamemode based on the SCP series and community\nPlugin is created by Batfoxkid\n ");

	DisplayCredits(client);
	return Plugin_Continue;
}

void ChangeSong(int client, float next, const char[] filepath, int volume=2)
{
	if(Client[client].CurrentSong[0])
	{
		StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
		StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
	}

	if(Client[client].DownloadMode || !filepath[0])
	{
		Client[client].CurrentSong[0] = 0;
		Client[client].NextSongAt = FAR_FUTURE;
		return;
	}

	strcopy(Client[client].CurrentSong, sizeof(Client[].CurrentSong), filepath);
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
	Client[client].HelpSwitch = true;

	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		SetGlobalTransTarget(client);

		SetHudTextParamsEx(-1.0, 0.3, help ? 20.0 : 10.0, Client[client].Colors, Client[client].Colors, 0, 5.0, 1.0, 1.0);
		ShowSyncHudText(client, HudClass, "%t", "you_are", class.Display);

		char buffer[32];
		bool full = help;
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
				full = true;
			}
		}

		if(full)
		{
			Client[client].HudIn = GetEngineTime();
			if(help)
			{
				Client[client].HudIn += 21.0;
			}
			else
			{
				Client[client].HudIn += 31.0;
			}

			FormatEx(buffer, sizeof(buffer), "train_%s", class.Name);
			if(TranslationPhraseExists(buffer))
			{
				SetHudTextParamsEx(-1.0, 0.5, help ? 20.0 : 30.0, Client[client].Colors, Client[client].Colors, 1, 5.0, 1.0, 1.0);
				ShowSyncHudText(client, HudGame, "%t", buffer);
				return;
			}
		}

		Client[client].HudIn = GetEngineTime()+11.0;

		FormatEx(buffer, sizeof(buffer), "desc_%s", class.Name);
		if(TranslationPhraseExists(buffer))
		{
			SetHudTextParamsEx(-1.0, 0.5, help ? 20.0 : 10.0, Client[client].Colors, Client[client].Colors, 1, 5.0, 1.0, 1.0);
			ShowSyncHudText(client, HudGame, "%t", buffer);
		}
	}
}

bool AttemptGrabItem(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && !(Client[client].Disarmer && class.Human))
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

		if(GetVectorDistance(pos1, pos2) < 800)
			return true;
	}

	TF2_RemoveCondition(client, TFCond_PasstimePenaltyDebuff);
	Client[client].Disarmer = 0;
	return false;
}

bool IsFriendly(int index1, int index2)
{
	ClassEnum class1, class2;
	if(Classes_GetByIndex(index1, class1) && class1.Group>=0
	&& Classes_GetByIndex(index2, class2) && class2.Group>=0)
	{
		if(class1.Group != class2.Group)
			return false;
	}
	return true;
}

public int OnQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, int userid)
{
	if(Client[client].DownloadMode==2 || GetClientOfUserId(userid)!=client || !IsClientInGame(client))
		return;

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

public void Zone_OnClientEntry(int client, char[] zone)
{
	if(!StrContains(zone, "scp_escort", false))
		TF2_AddCondition(client, TFCond_TeleportedGlow, 0.5);
}

#if defined _SENDPROXYMANAGER_INC_
public Action SendProp_OnAlive(int entity, const char[] propname, int &value, int client) 
{
	value = 1;
	return Plugin_Changed;
}

public Action SendProp_OnTeam(int entity, const char[] propname, int &value, int client) 
{
	if(!IsValidClient(client) || (GetClientTeam(client)<2 && !IsPlayerAlive(client)))
		return Plugin_Continue;

	value = Client[client].IsVip ? view_as<int>(TFTeam_Blue) : view_as<int>(TFTeam_Red);
	return Plugin_Changed;
}

public Action SendProp_OnClass(int entity, const char[] propname, int &value, int client) 
{
	if(!Enabled)
		return Plugin_Continue;

	value = view_as<int>(TFClass_Unknown);
	return Plugin_Changed;
}

public Action SendProp_OnClientClass(int client, const char[] name, int &value, int element)
{
	if(Client[client].WeaponClass == TFClass_Unknown)
		return Plugin_Continue;

	value = view_as<int>(Client[client].WeaponClass);
	return Plugin_Changed;
}
#endif

#file "SCP: Secret Fortress"