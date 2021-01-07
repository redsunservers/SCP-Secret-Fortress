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

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"8"
#define STABLE_REVISION	"2"
#define PLUGIN_VERSION	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define IsSCP(%1)	(Client[%1].Class>=Class_035)
//#define IsSpec(%1)	(Client[%1].Class==Class_Spec || !IsPlayerAlive(%1) || TF2_IsPlayerInCondition(%1, TFCond_HalloweenGhostMode))

#define FAR_FUTURE	100000000.0
#define FAR_FUTURE_ALT	99999998.0
#define MAXTF2PLAYERS	36
#define MAXANGLEPITCH	45.0
#define MAXANGLEYAW	90.0
#define MAXENTITIES	2048

#define PREFIX		"{red}[SCP]{default} "
#define KEYCARD_MODEL	"models/scp_sl/keycard.mdl"
#define RADIO_MODEL	"models/weapons/w_models/w_sd_sapper.mdl"
#define VIP_GHOST_MODEL	"models/props_halloween/ghost.mdl"
#define DOWNLOADS	"configs/scp_sf/downloads.txt"
#define CFG_REACTIONS	"configs/scp_sf/reactions.cfg"
#define CFG_WEAPONS	"configs/scp_sf/weapons.cfg"

float TRIPLE_D[3] = { 0.0, 0.0, 0.0 };

Handle HudPlayer;
Handle HudClass;
Handle HudGame;

public Plugin myinfo =
{
	name		=	"SCP: Secret Fortress",
	author		=	"Batfoxkid",
	description	=	"WHY DID YOU THROW A GRENADE INTO THE ELEVA-",
	version		=	PLUGIN_VERSION
};

enum ClassEnum
{
	Class_Spec = 0,

	Class_DBoi,
	Class_Chaos,

	Class_Scientist,
	Class_Guard,
	Class_MTF,
	Class_MTF2,
	Class_MTFS,
	Class_MTF3,
	Class_MTFE,

	Class_035,
	Class_049,
	Class_0492,
	Class_076,
	Class_079,
	Class_096,
	Class_106,
	Class_173,
	Class_1732,
	Class_527,
	Class_939,
	Class_9392,
	Class_3008,
	Class_Stealer
}

char ClassShort[][] =
{
	"spec",

	"dboi",
	"chaos",

	"sci",
	"guard",
	"mtf1",
	"mtf2",
	"mtfs",
	"mtf3",
	"mtfe",

	"035",
	"049",
	"0492",
	"076",
	"079",
	"096",
	"106",
	"173",
	"1732",
	"527",
	"939",
	"9392",
	"3008",
	"itsteals"
};

char ClassColor[][] =
{
	"snow",

	"orange",
	"darkgreen",

	"yellow",
	"mediumblue",
	"darkblue",
	"darkblue",
	"darkblue",
	"darkblue",
	"darkblue",

	"darkred",	// 035
	"darkred",	// 049
	"red",		// 049-2
	"darkred",	// 076
	"darkred",	// 079
	"darkred",	// 096
	"darkred",	// 106
	"darkred",	// 173
	"darkred",	// 173
	"darkblue",	// 527
	"darkred",	// 939
	"darkred",	// 939
	"darkred",	// 3008
	"black"		// It Steals
};

int ClassColors[][] =
{
	{ 255, 255, 200, 255 },

	{ 255, 165, 0, 255 },
	{ 0, 100, 0, 255 },

	{ 255, 255, 0, 255 },
	{ 0, 0, 255, 255 },
	{ 0, 0, 214, 255 },
	{ 0, 0, 189, 255 },
	{ 0, 0, 154, 255 },
	{ 0, 0, 139, 255 },
	{ 0, 0, 154, 255 },

	{ 189, 0, 0, 255 },	// 035
	{ 189, 0, 0, 255 },	// 049
	{ 189, 0, 0, 255 },	// 049-2
	{ 189, 0, 0, 255 },	// 076
	{ 189, 0, 0, 255 },	// 079
	{ 189, 0, 0, 255 },	// 096
	{ 189, 0, 0, 255 },	// 106
	{ 189, 0, 0, 255 },	// 173
	{ 189, 0, 0, 255 },	// 173
	{ 214, 0, 0, 255 },	// 527
	{ 189, 0, 0, 255 },	// 939
	{ 189, 0, 0, 255 },	// 939
	{ 189, 0, 0, 255 },	// 3008
	{ 0, 0, 0, 255}		// It Steals
};

char ClassSpawn[][] =
{
	"scp_spawn",

	"scp_spawn_d",
	"",

	"scp_spawn_s",
	"scp_spawn_g",
	"",
	"",
	"",
	"",
	"",

	"scp_spawn_035",
	"scp_spawn_049",
	"scp_spawn_p",
	"scp_spawn_076",
	"scp_spawn_079",
	"scp_spawn_096",
	"scp_spawn_106",
	"scp_spawn_173",
	"scp_spawn_173",
	"scp_spawn_d",
	"scp_spawn_939",
	"scp_spawn_939",
	"scp_spawn_p",
	"scp_spawn_p"
};

char ClassModel[][] =
{
	"models/props_halloween/ghost_no_hat.mdl",	// Spec

	"models/jailbreak/scout/jail_scout_v2.mdl",	// DBoi
	"models/freak_fortress_2/scp-049/chaos.mdl",	// Chaos

	"models/scp_sl/scientists/apsci_cohrt_1.mdl",			// Sci
	"models/scp_sl/guards/counter_gign.mdl",			// Guard
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF 1
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF 2
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF S
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF 3
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF E

	"models/scp_sf/scp_049/zombieguard.mdl",		// 035
	"models/scp_sf/049/scp049_player_7.mdl",		// 049
	"models/scp_sf/scp_049/zombieguard.mdl",		// 049-2
	"models/freak_fortress_2/newscp076/newscp076_v1.mdl", 	// 076-2
	"models/player/engineer.mdl", 				// 079
	"models/scp_sf/096/scp096_2.mdl",			// 096
	"models/scp_sf/106/scp106_player_3.mdl",		// 106
	"models/freak_fortress_2/scp_173/scp_173new.mdl",	// 173
	"models/scp/scp173.mdl",				// 173-2
	"models/player/spy.mdl",				// 527
	"models/scp_sl/scp_939/scp_939_redone_pm_1.mdl",	// 939-89
	"models/scp_sl/scp_939/scp_939_redone_pm_1.mdl",	// 939-53
	"models/freak_fortress_2/scp-049/zombie049.mdl",	// 3008-2
	"models/freak_fortress_2/it_steals/it_steals_v39.mdl"	// Stealer
};

char ClassModelSub[][] =
{
	"models/props_halloween/ghost_no_hat.mdl",	// Spec

	"models/player/scout.mdl",	// DBoi
	"models/player/sniper.mdl",	// Chaos

	"models/player/medic.mdl",	// Sci
	"models/player/sniper.mdl",	// Guard
	"models/player/soldier.mdl",	// MTF 1
	"models/player/soldier.mdl",	// MTF 2
	"models/player/soldier.mdl",	// MTF S
	"models/player/soldier.mdl",	// MTF 3
	"models/player/soldier.mdl",	// MTF E

	"models/player/sniper.mdl",	// 035
	"models/player/medic.mdl",	// 049
	"models/player/sniper.mdl",	// 049-2
	"models/player/demo.mdl", 	// 076
	"models/player/engineer.mdl", 	// 079
	"models/player/demo.mdl",	// 096
	"models/player/soldier.mdl",	// 106
	"models/player/heavy.mdl",	// 173
	"models/player/heavy.mdl",	// 173
	"models/player/spy.mdl",	// 527
	"models/player/pyro.mdl",	// 939-89
	"models/player/pyro.mdl",	// 939-53
	"models/player/sniper.mdl",	// 3008-2
	"models/freak_fortress_2/it_steals/it_steals_v39.mdl"	// Stealer
};

TFClassType ClassClass[] =
{
	TFClass_Spy,		// Spec

	TFClass_Scout,		// DBoi
	TFClass_Pyro,		// Chaos

	TFClass_Medic,		// Sci
	TFClass_Sniper,		// Guard
	TFClass_DemoMan,	// MTF 1
	TFClass_Heavy,		// MTF 2
	TFClass_Engineer,	// MTF S
	TFClass_Soldier,	// MTF 3
	TFClass_Engineer,	// MTF E

	TFClass_Sniper,		// 035
	TFClass_Medic,		// 049
	TFClass_Scout,		// 049-2
	TFClass_DemoMan, 	// 076
	TFClass_Engineer, 	// 079
	TFClass_DemoMan,	// 096
	TFClass_Soldier,	// 106
	TFClass_Heavy,		// 173
	TFClass_Heavy,		// 173-2
	TFClass_Spy,		// 527
	TFClass_Spy,		// 939-89
	TFClass_Spy,		// 939-53
	TFClass_Sniper,		// 3008-2
	TFClass_Spy		// Stealer
};

TFClassType ClassClassModel[] =
{
	TFClass_Unknown,	// Spec

	TFClass_Scout,		// DBoi
	TFClass_Sniper,		// Chaos

	TFClass_Unknown,	// Sci
	TFClass_Unknown,	// Guard
	TFClass_Sniper,		// MTF 1
	TFClass_Sniper,		// MTF 2
	TFClass_Sniper,		// MTF S
	TFClass_Sniper,		// MTF 3
	TFClass_Sniper,		// MTF E

	TFClass_Sniper,		// 035
	TFClass_Unknown,	// 049
	TFClass_Sniper,		// 049-2
	TFClass_DemoMan, 	// 076
	TFClass_Unknown, 	// 079
	TFClass_Spy,		// 096
	TFClass_Scout,		// 106
	TFClass_Unknown,	// 173
	TFClass_Unknown,	// 173-2
	TFClass_Unknown,	// 527
	TFClass_Unknown,	// 939-89
	TFClass_Unknown,	// 939-53
	TFClass_Sniper,		// 3008-2
	TFClass_Unknown		// Stealer
};

char FireDeath[][] =
{
	"primary_death_burning",
	"PRIMARY_death_burning"
};

float FireDeathTimes[] =
{
	4.2,	// Merc
	3.2,	// Scout
	4.7,	// Sniper 	
	4.2,	// Soldier
	2.5,	// Demoman
	3.6,	// Medic 
	3.5,	// Heavy	
	0.0,	// Pyro
	2.2,	// Spy
	3.8	// Engineer
};

enum TeamEnum
{
	Team_Spec,
	Team_DBoi,
	Team_MTF,
	Team_SCP
}

int TeamColors[][] =
{
	{ 255, 200, 200, 255 },
	{ 255, 165, 0, 255 },
	{ 0, 0, 139, 255 },
	{ 139, 0, 0, 255 }
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

enum GamemodeEnum
{
	Gamemode_None,	// SCP dedicated map
	Gamemode_Ikea,	// SCP-3008-2 map
	Gamemode_Nut,	// SCP-173 infection map
	Gamemode_Steals,	// It Steals spin-off map
	Gamemode_Koth,	// Control Points are the objectives
	Gamemode_Ctf	// Flags are the objectives
}

enum
{
	Floor_Light = 0,
	Floor_Heavy,
	Floor_Surface
}

bool Enabled = false;
bool NoMusic = false;
bool ChatHook = true;
bool SourceComms = false;		// SourceComms++
bool BaseComm = false;		// BaseComm
//bool CollisionHook = false;	// CollisionHook

Cookie CookieTraining;
Cookie CookiePref;
Cookie CookieColor;
Cookie CookieDClass;
Cookie CookieMTFBan;

GamemodeEnum Gamemode = Gamemode_None;

int Timelimit;
float RoundStartAt;
int VIPGhostModel;
int ClassModelIndex[sizeof(ClassModel)];
int ClassModelSubIndex[sizeof(ClassModelSub)];
bool ClassEnabled[view_as<int>(ClassEnum)];

bool NoMusicRound;
int DClassEscaped;
int DClassCaptured;
int DClassMax;
int SciEscaped;
int SciCaptured;
int SciMax;
int SCPKilled;
int SCPMax;

enum struct ClientEnum
{
	ClassEnum Class;
	int Colors[4];
	int ColorBlind[3];

	bool IsVip;
	bool MTFBan;
	bool CanTalkTo[MAXTF2PLAYERS];

	ClassEnum PreferredSCP;

	Function OnKill;		// void(int client, int victim)
	Function OnDeath;		// void(int client, int attacker)
	Function OnButton;	// void(int client, int button)
	Function OnSpeed;		// void(int client, float &speed)
	Function OnTakeDamage;	// Action(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnDealDamage;	// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnSeePlayer;	// bool(int client, int victim)
	Function OnMaxHealth;	// void(int client, int &health)
	Function OnGlowPlayer;	// bool(int client, int victim)
	Function OnAnimation;	// Action(int client, PlayerAnimEvent_t &anim, int &data)
	Function OnWeaponSwitch;	// void(int client, int entity)
	Function OnSound;		// Action(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	Function OnCondRemoved;	// void(int client, TFCond cond)
	Function OnKeycard;	// int(int client, AccessEnum access)

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

	void ClearFunc()
	{
		this.OnKill = INVALID_FUNCTION;
		this.OnDeath = INVALID_FUNCTION;
		this.OnButton = INVALID_FUNCTION;
		this.OnSpeed = INVALID_FUNCTION;
		this.OnTakeDamage = INVALID_FUNCTION;
		this.OnDealDamage = INVALID_FUNCTION;
		this.OnSeePlayer = INVALID_FUNCTION;
		this.OnMaxHealth = INVALID_FUNCTION;
		this.OnGlowPlayer = INVALID_FUNCTION;
		this.OnAnimation = INVALID_FUNCTION;
		this.OnWeaponSwitch = INVALID_FUNCTION;
		this.OnSound = INVALID_FUNCTION;
		this.OnCondRemoved = INVALID_FUNCTION;
		this.OnKeycard = INVALID_FUNCTION;
	}

	TFTeam TeamTF()
	{
		if(this.Class < Class_DBoi)
			return TFTeam_Spectator;

		if(Gamemode == Gamemode_Nut)
		{
			if(this.Class==Class_173 || this.Class==Class_1732)
				return TFTeam_Unassigned;

			if(this.Class<Class_Scientist || this.Class>=Class_035)
				return TFTeam_Red;

			return TFTeam_Blue;
		}

		if(this.Class < Class_Scientist)
			return TFTeam_Red;

		return this.Class<Class_035 ? TFTeam_Blue : TFTeam_Unassigned;
	}

	ClassEnum Setup(TFTeam team, bool bot, ArrayList scpList, int &classD, int &classS, int &scp)
	{
		if(team == TFTeam_Blue)
		{
			if(Gamemode == Gamemode_Ikea)
			{
				if(!bot && !GetRandomInt(0, 3))
				{
					scp++;
					this.Class = Class_3008;
					return Class_3008;
				}

				classD++;
				this.Class = Class_DBoi;
				return Class_DBoi;
			}

			if(Gamemode!=Gamemode_Steals && classS && !this.MTFBan && !GetRandomInt(0, 2))
			{
				this.Class = Class_Guard;
				return Class_Guard;
			}

			classS++;
			this.Class = Class_Scientist;
			return Class_Scientist;
		}

		if(team == TFTeam_Red)
		{
			if(Gamemode!=Gamemode_Steals && Gamemode!=Gamemode_Ikea && !bot && this.PreferredSCP!=Class_DBoi && (!GetRandomInt(0, scp+3) || (!scp && (classD+classS)>4)))
			{
				this.Class = GetSCPRand(scpList, this.PreferredSCP);
				if(this.Class != Class_Spec)
				{
					scp++;
					return this.Class;
				}
			}

			classD++;
			this.Class = Class_DBoi;
			return Class_DBoi;
		}

		this.Class = Class_Spec;
		return Class_Spec;
	}
}

ClassEnum TestForceClass[MAXTF2PLAYERS];
ClientEnum Client[MAXTF2PLAYERS];

#include "scp_sf/stocks.sp"
#include "scp_sf/achievements.sp"
#include "scp_sf/configs.sp"
#include "scp_sf/convars.sp"
#include "scp_sf/dhooks.sp"
#include "scp_sf/forwards.sp"
#include "scp_sf/functions.sp"
#include "scp_sf/items.sp"
#include "scp_sf/natives.sp"
#include "scp_sf/sdkcalls.sp"
#include "scp_sf/sdkhooks.sp"
#include "scp_sf/targetfilters.sp"
#include "scp_sf/viewmodels.sp"

#include "scp_sf/scps/049.sp"
#include "scp_sf/scps/076.sp"
#include "scp_sf/scps/096.sp"
#include "scp_sf/scps/106.sp"
#include "scp_sf/scps/173.sp"
#include "scp_sf/scps/939.sp"
#include "scp_sf/scps/1732.sp"
#include "scp_sf/scps/3008.sp"
#include "scp_sf/scps/itsteals.sp"

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

	Forward_Setup();
	Native_Setup();
	RegPluginLibrary("scp_sf");
	return APLRes_Success;
}

public void OnPluginStart()
{
	Client[0].ClearFunc();
	Client[0].NextSongAt = FAR_FUTURE;
	Client[0].ColorBlind[0] = -1;
	Client[0].ColorBlind[1] = -1;
	Client[0].ColorBlind[2] = -1;

	ConVar_Setup();
	SDKHook_Setup();
	Target_Setup();

	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeathPost, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroy, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", OnCapturePoint, EventHookMode_Pre);
	HookEvent("teamplay_flag_event", OnCaptureFlag, EventHookMode_Pre);
	HookEvent("teamplay_win_panel", OnWinPanel, EventHookMode_Pre);

	RegConsoleCmd("scp", Command_MainMenu, "View SCP: Secret Fortress main menu");

	RegConsoleCmd("scpinfo", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scp_info", Command_HelpClass, "View info about your current class");

	RegConsoleCmd("scppref", Command_Preference, "Sets your prefered SCP to play as.");
	RegConsoleCmd("scp_pref", Command_Preference, "Sets your prefered SCP to play as.");
	RegConsoleCmd("scppreference", Command_Preference, "Sets your prefered SCP to play as.");
	RegConsoleCmd("scp_preference", Command_Preference, "Sets your prefered SCP to play as.");

	RegConsoleCmd("scpcolor", Command_ColorBlind, "Sets your perfered HUD color.");
	RegConsoleCmd("scp_color", Command_ColorBlind, "Sets your perfered HUD color.");
	RegConsoleCmd("scpcolorblind", Command_ColorBlind, "Sets your perfered HUD color.");
	RegConsoleCmd("scp_colorblind", Command_ColorBlind, "Sets your perfered HUD color.");

	RegAdminCmd("scp_forceclass", Command_ForceClass, ADMFLAG_SLAY, "Usage: scp_forceclass <target> <class>.  Forces that class to be played.");
	RegAdminCmd("scp_giveitem", Command_ForceItem, ADMFLAG_SLAY, "Usage: scp_giveitem <target> <index>.  Gives a specific item.");
	RegAdminCmd("scp_banmtf", Command_BanMTF, ADMFLAG_BAN, "Usage: scp_banmtf <target> <id>.  Prevents a player from getting MTF/Guard.");

	AddCommandListener(OnSayCommand, "say");
	AddCommandListener(OnSayCommand, "say_team");
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
	HookEntityOutput("math_counter", "OutValue", OnCounterValue);
	AddTempEntHook("Player Decal", OnPlayerSpray);

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("scp_sf.phrases");

	CookieTraining = new Cookie("scp_cookie_training", "Status on learning the SCP gamemode", CookieAccess_Public);
	CookiePref = new Cookie("scp_cookie_preference", "Preference on which SCP to become", CookieAccess_Protected);
	CookieColor = new Cookie("scp_cookie_colorblind", "Color blind mode settings", CookieAccess_Protected);
	CookieDClass = new Cookie("scp_cookie_dboimurder", "Achievement Status", CookieAccess_Protected);
	CookieMTFBan = new Cookie("scp_cookie_mtfban", "Private Cookie", CookieAccess_Private);

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

	char buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));
	if(!StrContains(buffer, "scp_", false))
	{
		Gamemode = Gamemode_None;
	}
	else if(!StrContains(buffer, "ctf_", false))
	{
		Gamemode = Gamemode_Ctf;
	}
	else
	{
		Gamemode = Gamemode_Koth;
	}

	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrEqual(buffer, "scp_nomusic", false))
			continue;

		NoMusic = true;
		break;
	}

	for(int i; i<sizeof(ClassEnabled); i++)
	{
		ClassEnabled[i] = false;
	}

	entity = -1;
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrContains(buffer, "scp_scps ", false))
			continue;

		ClassEnabled[Class_035] = StrContains(buffer, " 035", false)!=-1;
		ClassEnabled[Class_049] = StrContains(buffer, " 049", false)!=-1;
		ClassEnabled[Class_076] = StrContains(buffer, " 076", false)!=-1;
		ClassEnabled[Class_079] = StrContains(buffer, " 079", false)!=-1;
		ClassEnabled[Class_096] = StrContains(buffer, " 096", false)!=-1;
		ClassEnabled[Class_106] = StrContains(buffer, " 106", false)!=-1;
		ClassEnabled[Class_173] = StrContains(buffer, " 173", false)!=-1;
		ClassEnabled[Class_1732] = StrContains(buffer, " 1732", false)!=-1;
		ClassEnabled[Class_527] = StrContains(buffer, " 527", false)!=-1;
		ClassEnabled[Class_939] = StrContains(buffer, " 939", false)!=-1;
		ClassEnabled[Class_9392] = ClassEnabled[Class_939];
		ClassEnabled[Class_3008] = StrContains(buffer, " 3008", false)!=-1;
		ClassEnabled[Class_Stealer] = StrContains(buffer, " itsteals", false)!=-1;
		break;
	}

	if(entity == -1)
	{
		ClassEnabled[Class_049] = true;
		ClassEnabled[Class_096] = true;
		ClassEnabled[Class_106] = true;
		ClassEnabled[Class_173] = true;
		ClassEnabled[Class_939] = true;
		ClassEnabled[Class_9392] = true;
	}

	if(ClassEnabled[Class_049])
		SCP049_Enable();

	if(ClassEnabled[Class_076])
		SCP076_Enable();

	if(ClassEnabled[Class_096])
		SCP096_Enable();

	if(ClassEnabled[Class_106])
		SCP106_Enable();

	if(ClassEnabled[Class_173])
		SCP173_Enable();

	if(ClassEnabled[Class_939])
		SCP939_Enable();

	if(ClassEnabled[Class_3008])
	{
		SCP3008_Enable();
	}
	else if(ClassEnabled[Class_1732])
	{
		SCP1732_Enable();
	}
	else if(ClassEnabled[Class_Stealer])
	{
		ItSteals_Enable();
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
}

public void OnConfigsExecuted()
{
	Config_Setup();
	ConVar_Enable();
	Items_Setup();

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), DOWNLOADS);
	if(!FileExists(buffer))
		return;

	File file = OpenFile(buffer, "r");
	if(!file)
		return;

	int table = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	while(!file.EndOfFile() && file.ReadLine(buffer, sizeof(buffer)))
	{
		ReplaceString(buffer, sizeof(buffer), "\n", "");
		if(FileExists(buffer))
			AddToStringTable(table, buffer);
	}
	delete file;
	LockStringTables(save);
}

public void OnPluginEnd()
{
	ConVar_Disable();
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
			DHook_UnhookClient(i);
	}

	if(Enabled)
		EndRound(Team_Spec, TFTeam_Unassigned);
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
	CookieMTFBan.Get(client, buffer, sizeof(buffer));
	Client[client].MTFBan = buffer[0]=='1';

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

	CookiePref.Get(client, buffer, sizeof(buffer));

	ClassEnum i = Class_DBoi;
	for(; i<=Class_939; i++)
	{
		if(ClassEnabled[i] && StrEqual(buffer, ClassShort[i]))
			break;

		if(i != Class_DBoi)
			continue;

		i = Class_035;
		i--;
	}

	if(i <= Class_939)
		Client[client].PreferredSCP = i;
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

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Enabled = false;
	NoMusicRound = false;

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		if(Gamemode == Gamemode_Steals)
		{
			ClientCommand(client, "r_screenoverlay \"\"");
			TurnOffFlashlight(client);
			TurnOffGlow(client);
		}

		Client[client].IsVip = CheckCommandAccess(client, "sm_trailsvip", ADMFLAG_CUSTOM5);

		if(TF2_GetPlayerClass(client) == TFClass_Sniper)
			TF2_SetPlayerClass(client, TFClass_Soldier);

		if(IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
			ChangeClientTeamEx(client, TFTeam_Red);

		if(Client[client].Class==Class_106 && Client[client].Extra2)
			HideAnnotation(client);

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
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	RoundStartAt = GetEngineTime();
	if(Gamemode == Gamemode_Ctf)
	{
		int entity = MaxClients+1;
		while((entity=FindEntityByClassname2(entity, "item_teamflag")) != -1)
		{
			SDKHook_HookFlag(entity);
		}
	}
	else if(Gamemode == Gamemode_Koth)
	{
		int entity = MaxClients+1;
		while((entity=FindEntityByClassname2(entity, "trigger_capture_area")) != -1)
		{
				SDKHook_HookCapture(entity);
		}
	}

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

	Timelimit = CvarTimelimit.IntValue;

	UpdateListenOverrides(RoundStartAt);

	RequestFrame(DisplayHint, true);
}

public Action OnCapturePoint(Event event, const char[] name, bool dontBroadcast)
{
	float gameTime = GetGameTime();
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && Client[client].IsCapping>gameTime)
			TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);
	}

	CreateTimer(0.3, ResetPoint, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action OnCaptureFlag(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("eventtype") != 2)
		return Plugin_Handled;

	int client = event.GetInt("player");
	if(IsValidClient(client))
		TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);

	return Plugin_Handled;
}

public Action OnWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action OnCounterValue(const char[] output, int entity, int client, float delay)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

	if(!StrContains(name, "scp_collectcount", false))
		SCPMax = RoundFloat(GetEntDataFloat(entity, FindDataMapInfo(entity, "m_OutValue")));

	return Plugin_Continue;
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
			if(!Function_OnKeycard(client, access, value))
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
	else if(!StrContains(name, "scp_respawn", false))
	{
		if(IsValidClient(client))
		{
			if(Enabled && TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
				GiveAchievement(Achievement_SurvivePocket, client);

			GoToSpawn(client, GetRandomInt(0, 2) ? Class_0492 : Class_106);
		}
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
		bool found;
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && (Client[target].Class==Class_106 || Client[target].Class==Class_3008))
			{
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
				found = true;
			}
		}

		if(Enabled && found)
			GiveAchievement(Achievement_Kill106);
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
			GiveAchievement(Achievement_SurviveWarhead);
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
								if(choice<2 && Client[client].Class==Class_Scientist && weapon.Type==Item_Keycard)
									GiveAchievement(Achievement_Upgrade, client);

								bool canGive = Items_CanGiveItem(client, weapon.Type);
								entity = Items_CreateWeapon(client, amount, canGive, true, false);
								if(entity>MaxClients && IsValidEntity(entity))
								{
									if(canGive)
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
	if(!Enabled)
		return;

	SDKCall_SetSpeed(client);

	if(cond == TFCond_DemoBuff)
		TF2_RemoveCondition(client, TFCond_DemoBuff);

	if(cond == TFCond_Taunting)
	{
		ViewModel_Hide(client);
		if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
			TF2_RemoveCondition(client, TFCond_Taunting);

		return;
	}

	if(cond!=TFCond_TeleportedGlow || Client[client].IgnoreTeleFor>GetEngineTime())
		return;

	if(Client[client].Class == Class_DBoi)
	{
		Items_DropAllItems(client);
		if(Gamemode == Gamemode_Ikea)
		{
			DClassEscaped++;
			Client[client].Class = Client[client].MTFBan ? Class_Spec : Class_MTFS;
		}
		else if(Client[client].Disarmer)
		{
			DClassCaptured++;
			if(Client[client].MTFBan)
			{
				Client[client].Class = Class_Spec;

				int total;
				int[] clients = new int[MaxClients];
				for(int i=1; i<=MaxClients; i++)
				{
					if(IsValidClient(i) && IsSpec(i) && !Client[i].MTFBan && GetClientTeam(i)>view_as<int>(TFTeam_Spectator))
						clients[total++] = i;
				}

				if(total)
				{
					total = clients[GetRandomInt(0, total-1)];
					Client[total].Class = Class_MTFE;
					AssignTeam(total);
					RespawnPlayer(total);
				}
			}
			else
			{
				Client[client].Class = Class_MTFE;
			}
		}
		else
		{
			DClassEscaped++;
			Client[client].Class = Class_Chaos;
			GiveAchievement(Achievement_EscapeDClass, client);
		}

		AssignTeam(client);
		RespawnPlayer(client);
		Forward_OnEscape(client, Client[client].Disarmer);
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(Client[client].Class == Class_Scientist)
	{
		Items_DropAllItems(client);
		if(Client[client].Disarmer)
		{
			SciCaptured++;
			Client[client].Class = Class_Chaos;

			int total;
			int[] clients = new int[MaxClients];
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsValidClient(i) && IsSpec(i) && GetClientTeam(i)>view_as<int>(TFTeam_Spectator))
					clients[total++] = i;
			}

			if(total)
			{
				total = clients[GetRandomInt(0, total-1)];
				Client[total].Class = Class_Chaos;
				AssignTeam(total);
				RespawnPlayer(total);
			}
		}
		else
		{
			SciEscaped++;
			Client[client].Class = Client[client].MTFBan ? Class_Spec : Class_MTFS;
			GiveAchievement(Achievement_EscapeSci, client);
		}

		AssignTeam(client);
		RespawnPlayer(client);
		Forward_OnEscape(client, Client[client].Disarmer);
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	if(Enabled)
		SDKCall_SetSpeed(client);

	Function_OnCondRemoved(client, cond);
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	result = !(IsSpec(client) || IsSCP(client));
	if(result)
		Client[client].IgnoreTeleFor = GetEngineTime()+3.0;

	return Plugin_Changed;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return;

	TFTeam team = Client[client].TeamTF();
	if(Client[client].Class != Class_Spec)
	{
		if(team == TFTeam_Blue)
		{
			if(GetClientTeam(client) != view_as<int>(TFTeam_Blue))
			{
				ChangeClientTeamEx(client, TFTeam_Blue);
				RespawnPlayer(client);
				return;
			}
		}
		else if(GetClientTeam(client) != view_as<int>(TFTeam_Red))
		{
			ChangeClientTeamEx(client, TFTeam_Red);
			RespawnPlayer(client);
			return;
		}

		TF2_SetPlayerClass(client, ClassClass[Client[client].Class]);

		if(team != TFTeam_Spectator)
			ChangeClientTeamEx(client, team);
	}

	ViewModel_Destroy(client);

	Client[client].Colors = ClassColors[Client[client].Class];
	for(int i; i<3; i++)
	{
		if(Client[client].ColorBlind[i] >= 0)
			Client[client].Colors[i] = Client[client].ColorBlind[i];
	}

	int Ammo[Ammo_MAX];
	Client[client].ClearFunc();
	Client[client].Sprinting = false;
	Client[client].ChargeIn = 0.0;
	Client[client].Disarmer = 0;
	Client[client].SprintPower = 100.0;
	switch(Client[client].Class)
	{
		case Class_DBoi:
		{
			Client[client].Floor = Floor_Light;
			if(Gamemode == Gamemode_Steals)
				TurnOnFlashlight(client);

			Items_CreateWeapon(client, 5, true, true);
			int entity = TF2_CreateHat(client, 150);
			if(entity > MaxClients)
				TF2Attrib_SetByDefIndex(entity, 261, view_as<float>(13595446));
		}
		case Class_Chaos:
		{
			Client[client].Floor = Floor_Surface;

			Ammo[Ammo_7mm] = 100;

			Items_CreateWeapon(client, 415, true, true);

			Items_CreateWeapon(client, 30011, false, true);
			Items_CreateWeapon(client, 30013, false, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);

			GiveAchievement(Achievement_ChaosSpawn, client);
		}
		case Class_Scientist:
		{
			Client[client].Floor = Floor_Heavy;
			if(Gamemode == Gamemode_Steals)
				TurnOnFlashlight(client);

			Items_CreateWeapon(client, 30002, true, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);
		}
		case Class_Guard:
		{
			Client[client].Floor = Floor_Heavy;

			Ammo[Ammo_7mm] = 35;
			Ammo[Ammo_Grenade] = 1;
			Ammo[Ammo_Radio] = 100;

			Items_CreateWeapon(client, 30016, false, true);
			Items_CreateWeapon(client, 1151, false, true);

			Items_CreateWeapon(client, 751, true, true);

			Items_CreateWeapon(client, 30005, false, true);
			Items_CreateWeapon(client, 954, false, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);
		}
		case Class_MTF:
		{
			Client[client].Floor = Floor_Surface;

			Ammo[Ammo_5mm] = 40;
			Ammo[Ammo_9mm] = 100;
			Ammo[Ammo_Radio] = 100;

			Items_CreateWeapon(client, 30016, false, true);

			Items_CreateWeapon(client, 1150, true, true);

			Items_CreateWeapon(client, 30006, false, true);
			if(Gamemode != Gamemode_Ikea)
				Items_CreateWeapon(client, 954, false, true);
			Items_CreateWeapon(client, 5, false, true);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTF2:
		{
			Client[client].Floor = Floor_Surface;

			Ammo[Ammo_5mm] = 80;
			Ammo[Ammo_9mm] = 50;
			Ammo[Ammo_Grenade] = 1;
			Ammo[Ammo_Radio] = 100;

			Items_CreateWeapon(client, 30016, false, true);
			Items_CreateWeapon(client, 308, false, true);

			Items_CreateWeapon(client, 425, true, true);

			Items_CreateWeapon(client, 30007, false, true);
			if(Gamemode != Gamemode_Ikea)
				Items_CreateWeapon(client, 954, false, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTFS:
		{
			Client[client].Floor = Floor_Surface;

			Ammo[Ammo_5mm] = 120;
			Ammo[Ammo_7mm] = 20;
			Ammo[Ammo_9mm] = 20;
			Ammo[Ammo_Grenade] = 1;
			Ammo[Ammo_Radio] = 100;

			Items_CreateWeapon(client, 30016, false, true);
			Items_CreateWeapon(client, 308, false, true);

			Items_CreateWeapon(client, 425, true, true);

			Items_CreateWeapon(client, 30007, false, true);
			if(Gamemode != Gamemode_Ikea)
				Items_CreateWeapon(client, 954, false, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTF3:
		{
			Client[client].Floor = Floor_Surface;

			Ammo[Ammo_5mm] = 120;
			Ammo[Ammo_9mm] = 100;
			Ammo[Ammo_Grenade] = 1;
			Ammo[Ammo_Radio] = 100;

			Items_CreateWeapon(client, 30016, false, true);
			Items_CreateWeapon(client, 308, false, true);

			Items_CreateWeapon(client, 425, true, true);

			Items_CreateWeapon(client, 30008, false, true);
			if(Gamemode != Gamemode_Ikea)
				Items_CreateWeapon(client, 954, false, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTFE:
		{
			Client[client].Floor = Floor_Surface;

			Ammo[Ammo_5mm] = 120;
			Ammo[Ammo_7mm] = 20;
			Ammo[Ammo_9mm] = 20;
			Ammo[Ammo_Radio] = 100;
			Ammo[Ammo_Metal] = 400;

			Items_CreateWeapon(client, 30016, false, true);
			Items_CreateWeapon(client, 308, false, true);

			Items_CreateWeapon(client, 199, true, true);

			Items_CreateWeapon(client, 30009, false, true);
			Items_CreateWeapon(client, 197, false, true);
			Items_CreateWeapon(client, 30014, false, true);
			Items_CreateWeapon(client, 5, false, true);

			Items_CreateWeapon(client, 25, false, true);
			Items_CreateWeapon(client, 26, false, true);
			Items_CreateWeapon(client, 28, false, true);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_049:
		{
			SCP049_Create(client);
		}
		case Class_0492:
		{
			SCP0492_Create(client);
		}
		case Class_076:
		{
			SCP076_Create(client);
		}
		case Class_096:
		{
			SCP096_Create(client);
		}
		case Class_106:
		{
			SCP106_Create(client);
		}
		case Class_173:
		{
			SCP173_Create(client);
		}
		case Class_1732:
		{
			SCP1732_Create(client);
		}
		case Class_939, Class_9392:
		{
			SCP939_Create(client);
		}
		case Class_3008:
		{
			SCP3008_Create(client);
		}
		case Class_Stealer:
		{
			ItSteals_Create(client);
		}
		default:
		{
			//TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
			TF2_AddCondition(client, TFCond_HalloweenGhostMode);

			SetVariantString(Client[client].IsVip ? VIP_GHOST_MODEL : ClassModel[Class_Spec]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);

			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", (Client[client].IsVip ? VIPGhostModel : ClassModelIndex[Class_Spec]), _, 0);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", (Client[client].IsVip ? VIPGhostModel : ClassModelSubIndex[Class_Spec]), _, 3);

			//SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);

			if(IsFakeClient(client))
				TeleportEntity(client, TRIPLE_D, NULL_VECTOR, NULL_VECTOR);

			return;
		}
	}

	// Teleport to spawn point
	if(Client[client].Class!=Class_0492 && ClassSpawn[Client[client].Class][0])
		GoToSpawn(client, Client[client].Class);

	/*if(team == TFTeam_Unassigned)
	{
		SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	}*/

	// Show class info
	Client[client].HudIn = GetEngineTime()+9.9;
	TF2_SetPlayerClass(client, ClassClass[Client[client].Class], false);
	CreateTimer(2.0, ShowClassInfoTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

	// Model stuff
	SetVariantString(ClassModel[Client[client].Class]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelIndex[Client[client].Class], _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelSubIndex[Client[client].Class], _, 3);

	if(Client[client].Class == Class_1732)
		SetEntProp(client, Prop_Send, "m_nSkin", client%10);

	// Reset health
	int health;
	OnGetMaxHealth(client, health);
	SetEntityHealth(client, health);

	// Ammo stuff
	for(int i; i<Ammo_MAX; i++)
	{
		SetEntProp(client, Prop_Data, "m_iAmmo", Ammo[i], _, i);
	}

	// Other stuff
	TF2_CreateGlow(client, team);
	TF2_AddCondition(client, TFCond_NoHealingDamageBuff, 1.0);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);

	// Attribute stuff
	SetCaptureRate(client);
	TF2Attrib_SetByDefIndex(client, 49, 1.0);
	TF2Attrib_SetByDefIndex(client, 69, 0.1);

	if(Gamemode == Gamemode_Steals)
		TF2Attrib_SetByDefIndex(client, 819, 1.0);

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
	if(client && view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))==TFClass_Unknown)
	{
		Client[client].Class = Class_Spec;
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(TFClass_Spy));
		RespawnPlayer(client);
	}
	return Plugin_Handled;
}

public Action OnPlayerSpray(const char[] name, const int[] clients, int count, float delay)
{
	if(Gamemode == Gamemode_Steals)
		return Plugin_Handled;

	int client = TE_ReadNum("m_nPlayer");
	return (IsClientInGame(client) && IsSpec(client)) ? Plugin_Handled : Plugin_Continue;
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
	if(!client || !Enabled)
		return Plugin_Continue;

	if(!IsSpec(client))
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
		{
			Client[client].Class = Class_Spec;
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(TFClass_Spy));
			RespawnPlayer(client);
		}
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
	if(client && Enabled && !IsSpec(client) && !IsSCP(client))
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
	else if(GetClientTeam(client)==view_as<int>(TFTeam_Spectator) && !IsPlayerAlive(client) && CheckCommandAccess(client, "sm_mute", ADMFLAG_CHAT))
	{
		CPrintToChatAll("*SPEC* %s {default}: %s", name, msg);
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

		static char buffer[32];
		GetClassName(Client[client].Class, buffer, sizeof(buffer));

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
					if(IsSCP(client))
					{
						if(IsFriendly(Client[client].Class, Client[target].Class))
							CPrintToChat(target, "(%t) %s {default}: %s", buffer, name, msg);

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

		FormatEx(buffer, sizeof(buffer), "%t (/scppref)", "menu_preference");
		menu.AddItem("2", buffer);

		FormatEx(buffer, sizeof(buffer), "%t (/scpcolor)", "menu_colorblind");
		menu.AddItem("3", buffer);

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
					Command_Preference(client, -1);
				}
				case 2:
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

public Action Command_Preference(int client, int args)
{
	if(client)
	{
		if(CvarDiscFF.BoolValue && !CheckCommandAccess(client, "scp_basicvip", ADMFLAG_CUSTOM4))	// DISC-FF thing
		{
			Menu menu = new Menu(Handler_None);
			menu.SetTitle("You must add this server to your favorites\nand join the server through your favorites.\n ");
			menu.AddItem("", "Visit community server browser");
			menu.AddItem("", "Click on Favorites tab");
			menu.AddItem("", "Click on Add Current Server");
			menu.AddItem("", "Click on Refresh");
			menu.AddItem("", "Join the server through that menu");
			menu.ExitButton = false;
			menu.Display(client, MENU_TIME_FOREVER);
			return Plugin_Continue;
		}
		
		Menu menu = new Menu(Handler_Preference);
		SetGlobalTransTarget(client);
		menu.SetTitle("SCP: Secret Fortress\n%t\n ", "menu_preference");

		menu.AddItem("1", "No SCP", Client[client].PreferredSCP==Class_DBoi ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("0", "Any SCP", Client[client].PreferredSCP==Class_Spec ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

		static char buffer[64], num[4];
		for(ClassEnum i=Class_035; i<=Class_939; i++)
		{
			if(!ClassEnabled[i])
				continue;

			GetClassName(i, buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer), "%t", buffer);
			IntToString(view_as<int>(i), num, sizeof(num));
			menu.AddItem(num, buffer, Client[client].PreferredSCP==i ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		menu.ExitButton = true;
		menu.ExitBackButton = args==-1;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int Handler_Preference(Menu menu, MenuAction action, int client, int choice)
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
			char buffer[4];
			menu.GetItem(choice, buffer, sizeof(buffer));
			ClassEnum class = view_as<ClassEnum>(StringToInt(buffer));
			if(class<=Class_DBoi || ClassEnabled[class])
			{
				Client[client].PreferredSCP = class;
				if(AreClientCookiesCached(client))
					CookiePref.Set(client, ClassShort[class]);
			}
			Command_Preference(client, menu.ExitBackButton ? -1 : 0);
		}
	}
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
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_forceclass <target> <class>");
		return Plugin_Handled;
	}

	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(2, pattern, sizeof(pattern));

	char targetName[MAX_TARGET_LENGTH];
	static char classTrans[64];
	SetGlobalTransTarget(client);
	ClassEnum class = Class_Spec;
	for(ClassEnum i=Class_DBoi; i<ClassEnum; i++)
	{
		if(i>=Class_049 && !ClassEnabled[i])
			continue;

		GetClassName(i, classTrans, sizeof(classTrans));
		FormatEx(targetName, sizeof(targetName), "%t", classTrans);
		if(StrContains(targetName, pattern, false) < 0)
			continue;

		class = i;
		break;
	}

	if(class == Class_Spec)
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

		if(!Enabled)
		{
			TestForceClass[targets[target]] = class;
			continue;
		}

		switch(Client[targets[target]].Class)
		{
			case Class_DBoi:
			{
				DClassMax--;
			}
			case Class_Scientist:
			{
				SciMax--;
			}
			default:
			{
				if(IsSCP(targets[target]))
					SCPMax--;
			}
		}

		Client[targets[target]].Class = class;
		switch(class)
		{
			case Class_DBoi:
			{
				DClassMax++;
			}
			case Class_Scientist:
			{
				SciMax++;
			}
			default:
			{
				if(IsSCP(targets[target]))
					SCPMax++;
			}
		}
		AssignTeam(targets[target]);
		RespawnPlayer(targets[target]);
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Gave forced class %t to %t", classTrans, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Gave forced class %t to %s", classTrans, targetName);
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

public Action Command_BanMTF(int client, int args)
{
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: scp_banmtf <target>");
		return Plugin_Handled;
	}

	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArgString(pattern, sizeof(pattern));

	static char targetName[MAX_TARGET_LENGTH];
	int targets[1], matches;
	bool targetNounIsMultiLanguage;
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	Client[targets[0]].MTFBan = !Client[targets[0]].MTFBan;
	if(Client[targets[0]].MTFBan)
	{
		CReplyToCommand(client, "%sBanned %N from playing MTF", PREFIX, targets[0]);
		if(AreClientCookiesCached(targets[0]))
			CookieMTFBan.Set(targets[0], "1");
	}
	else
	{
		CReplyToCommand(client, "%sUnbanned %N from playing MTF", PREFIX, targets[0]);
		if(AreClientCookiesCached(targets[0]))
			CookieMTFBan.Set(targets[0], "0");
	}
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	Client[client].PreferredSCP = Class_Spec;
	CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	if(item != INVALID_HANDLE)
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
			return Plugin_Continue;
		}
		default:
		{
			return Plugin_Handled;
		}
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	int clientId = event.GetInt("userid");
	int client = GetClientOfUserId(clientId);
	if(!client)
		return Plugin_Continue;

	TurnOffFlashlight(client);
	TurnOffGlow(client);
	int flags = event.GetInt("death_flags");
	if(flags & TF_DEATHFLAG_DEADRINGER)
	{
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}

	if(Gamemode == Gamemode_Steals)
		ClientCommand(client, "r_screenoverlay \"\"");

	CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	if(GetClientTeam(client) == view_as<int>(TFTeam_Unassigned))
		ChangeClientTeamEx(client, TFTeam_Red);

	ViewModel_Destroy(client);
	TF2_SetPlayerClass(client, TFClass_Spy);

	float engineTime = GetEngineTime();
	if(RoundStartAt+60 > engineTime)
		GiveAchievement(Achievement_DeathEarly, client);

	int attackerId = event.GetInt("attacker");
	int attacker = GetClientOfUserId(attackerId);
	bool validAttacker = (client!=attacker && IsValidClient(attacker));

	int assisterId = event.GetInt("assister");
	int assister = GetClientOfUserId(assisterId);
	bool validAssiter = (client!=assister && IsValidClient(assister));

	static char buffer[PLATFORM_MAX_PATH];
	int damage = event.GetInt("damagebits");
	int weapon = event.GetInt("weaponid");
	if(!validAttacker)
	{
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
		else if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==308)
		//else if((damage & DMG_BLAST) && client==attacker)
		{
			GiveAchievement(Achievement_DeathGrenade, client);
		}
	}

	if(IsSCP(client))
	{
		if(Client[client].Class!=Class_0492 && Client[client].Class!=Class_3008)
		{
			Function_OnDeath(client, attacker);
			GetClassName(Client[client].Class, buffer, sizeof(buffer));
			SCPKilled++;

			if(validAttacker)
			{
				if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==594)
					GiveAchievement(Achievement_KillSCPMirco, attacker);

				if(Client[attacker].Class == Class_Scientist)
					GiveAchievement(Achievement_KillSCPSci, attacker);

				Config_DoReaction(attacker, "killscp");

				static char class[16];
				GetClassName(Client[attacker].Class, class, sizeof(class));

				if(validAssiter)
				{
					if(Client[assister].Class == Class_Scientist)
						GiveAchievement(Achievement_KillSCPSci, assister);

					Config_DoReaction(assister, "killscp");

					static char class3[16];
					GetClassName(Client[assister].Class, class3, sizeof(class3));

					flags |= TF_DEATHFLAG_KILLERREVENGE|TF_DEATHFLAG_ASSISTERREVENGE;
					CPrintToChatAll("%s%t", PREFIX, "scp_killed_duo", ClassColor[Client[client].Class], buffer, ClassColor[Client[attacker].Class], class, ClassColor[Client[assister].Class], class3);
				}
				else
				{
					flags |= TF_DEATHFLAG_KILLERREVENGE;
					CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], buffer, ClassColor[Client[attacker].Class], class);
				}
			}
			else
			{
				if(damage & DMG_SHOCK)
				{
					CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], buffer, "gray", "tesla_gate");
				}
				else if(damage & DMG_NERVEGAS)
				{
					CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], buffer, "gray", "femur_breaker");
				}
				else if(damage & DMG_BLAST)
				{
					CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], buffer, "gray", "alpha_warhead");
				}
				else
				{
					CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], buffer, "black", "redacted");
				}
			}
			Client[client].Class = Class_Spec;
			return Plugin_Changed;
		}
	}

	for(int entity=MAXENTITIES-1; entity>MaxClients; entity--)
	{
		if(!IsValidEntity(entity) || !GetEntityClassname(entity, buffer, sizeof(buffer)) || StrContains(buffer, "obj_") || GetEntPropEnt(entity, Prop_Send, "m_hBuilder")!=client)
			continue;

		int target = 1;
		for(; target<=MaxClients; target++)
		{
			if(!IsValidClient(target) || IsSpec(target) || !IsFriendly(Client[client].Class, Client[target].Class))
				continue;

			SetEntPropEnt(entity, Prop_Send, "m_hBuilder", target);
			break;
		}

		if(target > MaxClients)
		{
			FakeClientCommand(client, "destroy 0");
			FakeClientCommand(client, "destroy 2");

			SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
			AcceptEntityInput(entity, "RemoveHealth");

			Event boom = CreateEvent("object_removed", true);
			boom.SetInt("userid", clientId);
			boom.SetInt("index", entity);
			boom.Fire();

			AcceptEntityInput(entity, "kill");
		}
	}

	event.BroadcastDisabled = true;

	if(validAttacker)
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

		if(IsSCP(attacker))
		{
			int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==594)
				GiveAchievement(Achievement_KillMirco, attacker);
		}

		switch(Client[attacker].Class)
		{
			case Class_DBoi:
			{
				if(Client[client].Class==Class_Scientist && Items_OnKeycard(client, Access_Main))
					GiveAchievement(Achievement_KillSci, attacker);
			}
			case Class_Scientist:
			{
				if(Client[client].Class == Class_DBoi)
					GiveAchievement(Achievement_KillDClass, attacker);
			}
			default:
			{
				Function_OnKill(attacker, client);
			}
		}

		for(int i=1; i<=MaxClients; i++)
		{
			if(i==client || i==attacker || (IsClientInGame(i) && IsFriendly(Client[attacker].Class, Client[i].Class) && Client[attacker].CanTalkTo[i]))
				event.FireToClient(i);
		}
	}
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) && (GetEntityFlags(client) & FL_ONGROUND))
			CreateSpecialDeath(client);
	}

	CreateTimer(3.9, OnPlayerDeathPoster, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Changed;
}

public void OnPlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	UpdateListenOverrides(GetEngineTime());
}

public Action OnPlayerDeathPoster(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && !IsPlayerAlive(client))
		Client[client].Class = Class_Spec;

	return Plugin_Continue;
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

	// SCP spawning delay
	float engineTime = GetEngineTime();
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

	// It Steals, moving flashlight
	static float pos[3], ang[3];
	if(Gamemode==Gamemode_Steals && Client[client].Extra1)
	{
		int entity = EntRefToEntIndex(Client[client].Extra1);
		if(entity>MaxClients && IsValidEntity(entity))
		{
			GetClientEyeAngles(client, pos);
			GetClientAbsAngles(client, ang);
			SubtractVectors(pos, ang, pos);
			TeleportEntity(entity, NULL_VECTOR, pos, NULL_VECTOR);
		}
		else
		{
			Client[client].Extra1 = 0;
		}
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

		// No jumping in It Steals
		if(Gamemode==Gamemode_Steals && (buttons & IN_JUMP))
		{
			buttons &= ~IN_JUMP;
			changed = true;
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
	else if(buttons & IN_RELOAD)
	{
		if(Gamemode==Gamemode_Steals && Client[client].Extra2>0)
		{
			buttons &= ~IN_RELOAD;
			changed = true;
			Client[client].Extra2--;

			int entity = -1;
			while((entity=FindEntityByClassname(entity, "prop_dynamic")) != -1)
			{
				char name[32];
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(!StrContains(name, "scp_collectable", false))
					CreateWeaponGlow(entity, 2.25);
			}
		}
		holding[client] = IN_RELOAD;
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
	Function_OnButton(client, wasHolding ? 0 : holding[client]);

	// HUD related things
	static float specialTick[MAXTF2PLAYERS];
	if(specialTick[client] < engineTime)
	{
		bool showHud = (Client[client].HudIn<engineTime && !(GetClientButtons(client) & IN_SCORE));
		specialTick[client] = engineTime+0.2;

		if(showHud)
			SetGlobalTransTarget(client);

		char buffer[PLATFORM_MAX_PATH];
		if(!IsSCP(client) && !IsSpec(client))
		{
			if(Gamemode == Gamemode_Steals)
			{
				if(Client[client].Sprinting)
				{
					Client[client].SprintPower -= 1.25;
				}
				else
				{
					if(Client[client].SprintPower < 99)
						Client[client].SprintPower += 1.0;
				}

				if(Client[client].HudIn < engineTime)
				{
					// Blur vision with less sprint
					if(Client[client].SprintPower > 90)
					{
						ClientCommand(client, "r_screenoverlay \"\"");
					}
					else if(Client[client].SprintPower > 75)
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/almostnone.vmt");
					}
					else if(Client[client].SprintPower > 60)
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/verylow.vmt");
					}
					else if(Client[client].SprintPower > 45)
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/low.vmt");
					}
					else if(Client[client].SprintPower > 30)
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/medium.vmt");
					}
					else if(Client[client].SprintPower > 15)
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/high.vmt");
					}
					else if(Client[client].SprintPower > 0)
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/ultrahigh.vmt");
					}
					else
					{
						ClientCommand(client, "r_screenoverlay it_steals/distortion/ultrahigh.vmt");
						SetEntityHealth(client, GetClientHealth(client)-1);
					}

					if(showHud)
					{
						//if(weapon>MaxClients && IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Disarm])
							//Format(buffer, sizeof(buffer), "%t", "camera", RoundToCeil(Client[client].Extra3));

						SetHudTextParams(-1.0, 0.92, 0.35, 255, 255, 255, 255, 0, 0.1, 0.05, 0.05);
						if(Client[client].Extra2)
						{
							//ShowSyncHudText(client, HudPlayer, "%s\n%t", buffer, "radar");
							ShowSyncHudText(client, HudPlayer, "%t", "radar");
						}
						/*else
						{
							ShowSyncHudText(client, HudPlayer, buffer);
						}*/
					}
				}
			}
			else
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
			}
		}

		// What class am I again
		if(showHud && Gamemode!=Gamemode_Steals)
		{
			GetClassName(Client[client].Class, buffer, sizeof(buffer));
			SetHudTextParamsEx(-1.0, 0.06, 0.35, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
			ShowSyncHudText(client, HudClass, "%t", buffer);
		}

		// And next theme please
		if(!NoMusic && !NoMusicRound && Client[client].NextSongAt<engineTime)
		{
			int song;
			if(Client[client].Class == Class_Spec)
			{
				song = Music_Spec;
			}
			else if(Client[client].AloneIn < engineTime)
			{
				song = Music_Alone;
			}
			else if(Client[client].Floor == Floor_Light)
			{
				song = Music_Light;
			}
			else if(Client[client].Floor == Floor_Heavy)
			{
				song = Music_Heavy;
			}
			else if(Client[client].Floor == Floor_Surface)
			{
				song = Music_Outside;
			}

			if(song)
			{
				float duration = Config_GetMusic(song, buffer, sizeof(buffer));
				ChangeSong(client, duration+engineTime, buffer);
			}
		}
	}
	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnGameFrame()	// TODO: Change this to NOT use ticks++ because that's kinda dumb
{
	float engineTime = GetEngineTime();
	static float nextAt;
	if(nextAt > engineTime)
		return;

	nextAt = engineTime+1.0;
	static int ticks;
	if(Enabled)
	{
		ticks++;
		static char buffer[PLATFORM_MAX_PATH];
		if(!(ticks % 180))
		{
			static int choosen[MAXTF2PLAYERS];
			switch(Gamemode)
			{
				case Gamemode_Ikea:
				{
					if(SciEscaped)
					{
						SciEscaped = 0;

						int count;
						for(int client=1; client<=MaxClients; client++)
						{
							if(IsValidClient(client) && IsSpec(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
								choosen[count++] = client;
						}

						if(count)
						{
							count = choosen[GetRandomInt(0, count-1)];
							Client[count].Class = Class_MTF3;
							AssignTeam(count);
							RespawnPlayer(count);

							for(int client=1; client<=MaxClients; client++)
							{
								if(!IsValidClient(client))
									continue;

								if(Client[client].Class == Class_3008)
								{
									Client[client].Extra2 = 0;
									TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
									SCP3008_WeaponNone(client);
									continue;
								}

								if(!IsSpec(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
									continue;

								Client[client].Class = GetRandomInt(0, 3) ? Class_MTF : Class_MTF2;
								AssignTeam(client);
								RespawnPlayer(client);
							}
						}

						count = -1;
						while((count=FindEntityByClassname(count, "logic_relay")) != -1)
						{
							char name[32];
							GetEntPropString(count, Prop_Data, "m_iName", name, sizeof(name));
							if(StrEqual(name, "scp_time_day", false))
							{
								AcceptEntityInput(count, "FireUser1");
								break;
							}
						}
					}
					else
					{
						SciEscaped = 1;

						for(int client=1; client<=MaxClients; client++)
						{
							if(!IsValidClient(client))
								continue;

							if(Client[client].Class == Class_3008)
							{
								Client[client].Extra2 = 1;
								TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
								SCP3008_WeaponFists(client);
								continue;
							}

							if(!IsSpec(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
								continue;

							Client[client].Class = Class_3008;
							AssignTeam(client);
							RespawnPlayer(client);
						}

						int entity = -1;
						while((entity=FindEntityByClassname(entity, "logic_relay")) != -1)
						{
							char name[32];
							GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
							if(StrEqual(name, "scp_time_night", false))
							{
								AcceptEntityInput(entity, "FireUser1");
								break;
							}
						}
					}
				}
				case Gamemode_Nut:
				{
					if(GetRandomInt(0, 2))
					{
						int count;
						for(int client=1; client<=MaxClients; client++)
						{
							if(IsValidClient(client) && IsSpec(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
								choosen[count++] = client;
						}

						if(count)
						{
							count = choosen[GetRandomInt(0, count-1)];
							Client[count].Class = Class_MTF3;
							AssignTeam(count);
							RespawnPlayer(count);

							for(int client=1; client<=MaxClients; client++)
							{
								if(!IsValidClient(client))
									continue;

								if(!IsSpec(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
									continue;

								Client[client].Class = GetRandomInt(0, 2) ? Class_MTF : Class_MTF2;
								AssignTeam(client);
								RespawnPlayer(client);
							}
							CPrintToChatAll("%s%t", PREFIX, "mtf_spawn");
							CPrintToChatAll("%s%t", PREFIX, "mtf_spawn_nut_over");
						}
					}
				}
				case Gamemode_Steals:
				{
					SciEscaped += ticks/180;
					for(int client=1; client<=MaxClients; client++)
					{
						if(IsValidClient(client) && (Client[client].Class==Class_DBoi || Client[client].Class==Class_Scientist))
							Client[client].Extra2++;
					}
				}
				default:
				{
					if(GetRandomInt(0, 1))
					{
						int count;
						for(int client=1; client<=MaxClients; client++)
						{
							if(IsValidClient(client) && !Client[client].MTFBan && IsSpec(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
								choosen[count++] = client;
						}

						if(count)
						{
							count = choosen[GetRandomInt(0, count-1)];
							Client[count].Class = Class_MTF3;
							AssignTeam(count);
							RespawnPlayer(count);

							count = 0;
							for(int client=1; client<=MaxClients; client++)
							{
								if(!IsValidClient(client))
									continue;

								if(IsSCP(client))
								{
									count++;
									continue;
								}

								if(!IsSpec(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
									continue;

								Client[client].Class = GetRandomInt(0, 3) ? Class_MTF : Class_MTF2;
								AssignTeam(client);
								RespawnPlayer(client);
							}
							CPrintToChatAll("%s%t", PREFIX, "mtf_spawn");

							Config_GetSound(Sound_MTFSpawn, buffer, sizeof(buffer));
							ChangeGlobalSong(engineTime+30.0, buffer, 3);

							if(count > 5)
							{
								CPrintToChatAll("%s%t", PREFIX, "mtf_spawn_scp_over");
							}
							else if(count)
							{
								CPrintToChatAll("%s%t", PREFIX, "mtf_spawn_scp", count);
							}
						}
					}
					else
					{
						float time = engineTime+26.0;
						bool hasSpawned;
						Config_GetSound(Sound_ChaosSpawn, buffer, sizeof(buffer));
						for(int client=1; client<=MaxClients; client++)
						{
							if(!IsValidClient(client))
								continue;

							if(!IsSpec(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
								continue;

							Client[client].Class = Class_Chaos;
							AssignTeam(client);
							RespawnPlayer(client);
							ChangeSong(client, time, buffer, 1);
							hasSpawned = true;
						}

						if(hasSpawned)
						{
							for(int client=1; client<=MaxClients; client++)
							{
								if(IsValidClient(client) && Client[client].Class==Class_DBoi)
									ChangeSong(client, time, buffer, 1);
							}
						}
					}
				}
			}
		}
		else if(!(ticks % 60))
		{
			DisplayHint(false);
		}
		else if(Timelimit > 120)
		{
			if(!NoMusic && !NoMusicRound)
			{
				float duration = Config_GetMusic(Music_Time, buffer, sizeof(buffer));
				if(ticks == RoundFloat(Timelimit-duration))
					ChangeGlobalSong(engineTime+15.0+duration, buffer);
			}

			if(ticks > Timelimit)
			{
				if(Gamemode == Gamemode_Ikea)
				{
					for(int client=1; client<=MaxClients; client++)
					{
						if(IsValidClient(client) && Client[client].Class==Class_DBoi && IsPlayerAlive(client))
							ForcePlayerSuicide(client);
					}
				}
				else
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
					EndRound(Team_Spec, TFTeam_Unassigned);
				}
			}
			else if(ticks > (Timelimit-120))
			{
				char seconds[4];
				int sec = (Timelimit-ticks)%60;
				if(sec > 9)
				{
					IntToString(sec, seconds, sizeof(seconds));
				}
				else
				{
					FormatEx(seconds, sizeof(seconds), "0%d", sec);
				}

				int min = RoundToFloor((Timelimit-ticks)/60.0);
				for(int client=1; client<=MaxClients; client++)
				{
					if(!IsValidClient(client))
						continue;

					BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
					if(!bf)
						continue;

					Format(buffer, sizeof(buffer), "%T", "time_remaining", client, min, seconds);
					bf.WriteString(buffer);
					bf.WriteString(ticks>(Timelimit-20) ? "ico_notify_ten_seconds" : ticks>(Timelimit-60) ? "ico_notify_thirty_seconds" : "ico_notify_sixty_seconds");
					bf.WriteByte(0);
					EndMessage();
				}
			}
		}
	}
	else
	{
		ticks = 0;
	}

	UpdateListenOverrides(engineTime);
}

// Public Events

void AssignTeam(int client)
{
	TFTeam team = Client[client].TeamTF();
	if(team != TFTeam_Blue)
		team = TFTeam_Red;

	ChangeClientTeamEx(client, team);
}

// TODO: Check if we even need this function because of... github.com/Kenzzer/JetPack_Fix
void RespawnPlayer(int client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Spy)
		TF2_SetPlayerClass(client, TFClass_Spy);

	TF2_RespawnPlayer(client);
}

public Action CheckAlivePlayers(Handle timer)
{
	if(!Enabled)
		return Plugin_Continue;

	switch(Gamemode)
	{
		case Gamemode_Ikea:
		{
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsValidClient(i) && !IsSpec(i) && Client[i].Class==Class_DBoi)
					return Plugin_Continue;
			}

			if(DClassEscaped)
			{
				EndRound(Team_MTF, TFTeam_Blue);
			}
			else
			{
				EndRound(Team_SCP, TFTeam_Red);
			}
		}
		case Gamemode_Nut:
		{
			int alive;
			for(int i=1; i<=MaxClients; i++)
			{
				if(!IsValidClient(i) || IsSpec(i))
					continue;

				if(Client[i].Class==Class_173 || Client[i].Class==Class_1732)
				{
					if(alive == 2)
						return Plugin_Continue;

					alive = 1;
				}
				else if(!IsSCP(i))
				{
					if(alive == 1)
						return Plugin_Continue;

					alive = 2;
				}
			}

			if(alive == 1)
			{
				EndRound(Team_SCP, TFTeam_Red);
			}
			else
			{
				for(int i=1; i<=MaxClients; i++)
				{
					if(IsValidClient(i) && GetClientTeam(i)>view_as<int>(TFTeam_Spectator))
						ChangeClientTeamEx(i, TFTeam_Blue);
				}

				EndRound(Team_MTF, TFTeam_Blue);
			}
		}
		case Gamemode_Steals:
		{
			bool salive, alive;
			for(int i=1; i<=MaxClients; i++)
			{
				if(!IsValidClient(i) || IsSpec(i))
					continue;

				if(IsSCP(i))
				{
					salive = true;
				}
				else
				{
					alive = true;
				}
			}

			if(!salive)
			{
				for(int i=1; i<=MaxClients; i++)
				{
					if(IsValidClient(i) && GetClientTeam(i)>view_as<int>(TFTeam_Spectator))
						ChangeClientTeamEx(i, TFTeam_Blue);
				}

				EndRound(Team_MTF, TFTeam_Blue);
			}
			else if(!alive)
			{
				EndRound(Team_SCP, TFTeam_Red);
			}
		}
		default:
		{
			bool salive;
			if(CvarQuickRounds.BoolValue)
			{
				for(int i=1; i<=MaxClients; i++)
				{
					if(!IsValidClient(i) || IsSpec(i))
						continue;

					if(Client[i].Class==Class_DBoi || Client[i].Class==Class_Scientist)
						return Plugin_Continue;

					if(!salive)
						salive = Client[i].TeamTF()==TFTeam_Unassigned;
				}
			}
			else
			{
				bool ralive, balive;
				for(int i=1; i<=MaxClients; i++)
				{
					if(!IsValidClient(i) || IsSpec(i))
						continue;

					if(Client[i].Class==Class_DBoi || Client[i].Class==Class_Scientist)
						return Plugin_Continue;

					switch(Client[i].TeamTF())
					{
						case TFTeam_Unassigned:	// SCPs
							salive = true;

						case TFTeam_Red:	// Chaos
							ralive = true;

						case TFTeam_Blue:	// Guards and MTF Squads
							balive = true;
					}
				}

				if(balive && (salive || ralive))
					return Plugin_Continue;
			}

			if(CvarWinStyle.BoolValue)
			{
				if(SciEscaped > DClassEscaped)
				{
					EndRound(Team_MTF, TFTeam_Blue);
				}
				else if(SciEscaped<DClassEscaped || SciCaptured>DClassCaptured)
				{
					EndRound(Team_DBoi, TFTeam_Red);
				}
				else if(SciCaptured < DClassCaptured)
				{
					EndRound(Team_MTF, TFTeam_Blue);
				}
				else if(!salive || SciEscaped)
				{
					EndRound(Team_Spec, TFTeam_Unassigned);
				}
				else
				{
					EndRound(Team_SCP, TFTeam_Red);
				}
			}
			else if(SciEscaped)
			{
				if(DClassEscaped)
				{
					EndRound(Team_Spec, TFTeam_Unassigned);
				}
				else
				{
					EndRound(Team_MTF, TFTeam_Blue);
				}
			}
			else if(DClassEscaped)
			{
				EndRound(Team_DBoi, TFTeam_Red);
			}
			else if(salive)
			{
				EndRound(Team_SCP, TFTeam_Red);
			}
			else
			{
				EndRound(Team_Spec, TFTeam_Unassigned);
			}
		}
	}
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

	for(int i; i<total; i++)
	{
		for(int a; a<total; a++)
		{
			if(client[i] == client[a])
			{
				if(ChatHook)
					SetListenOverride(client[i], client[a], Listen_Default);

				continue;
			}

			if(!IsValidClient(client[a]))
				continue;

			bool muted = IsClientMuted(client[i], client[a]);
			bool blocked = muted;

			#if defined _basecomm_included
			if(!blocked && BaseComm && BaseComm_IsClientMuted(client[a]))
				blocked = true;
			#endif

			#if defined _sourcecomms_included
			if(!blocked && SourceComms && SourceComms_GetClientMuteType(client[a])>bNot)
				blocked = true;
			#endif

			if(spec[i] || admin[a])
			{
				Client[client[a]].CanTalkTo[client[i]] = !muted;
				if(ChatHook)
					SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Default);
			}
			else if(IsSpec(client[a]))
			{
				Client[client[a]].CanTalkTo[client[i]] = (!muted && IsSpec(client[i]));
				if(ChatHook)
					SetListenOverride(client[i], client[a], (!blocked && IsSpec(client[i])) ? Listen_Default : Listen_No);
			}
			else if(Client[client[a]].ComFor > engineTime)
			{
				Client[client[a]].CanTalkTo[client[i]] = !muted;
				if(ChatHook)
					SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Default);
			}
			else if(IsSCP(client[a]))
			{
				if(IsSCP(client[i]))
				{
					Client[client[a]].CanTalkTo[client[i]] = !muted;
					if(ChatHook)
						SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Yes);
					continue;
				}
				else if(Client[client[a]].Class>=Class_939 && Client[client[a]].Class<=Class_3008)
				{
					if(GetVectorDistance(pos[i], pos[a], true) < 499999)
					{
						Client[client[a]].CanTalkTo[client[i]] = !muted;
						if(ChatHook)
							SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Yes);
						continue;
					}
				}

				Client[client[a]].CanTalkTo[client[i]] = false;
				if(ChatHook)
					SetListenOverride(client[i], client[a], Listen_No);
			}
			else if(GetVectorDistance(pos[i], pos[a], true) < (radio[i]>1 ? 160000.0*radio[a] : 160000.0))
			{
				Client[client[a]].CanTalkTo[client[i]] = !muted;
				if(ChatHook)
					SetListenOverride(client[i], client[a], blocked ? Listen_No : Listen_Yes);
			}
			else
			{
				Client[client[a]].CanTalkTo[client[i]] = false;
				if(ChatHook)
					SetListenOverride(client[i], client[a], Listen_No);
			}
		}
	}
}

void GoToSpawn(int client, ClassEnum class)
{
	int entity = -1;
	static char name[64];
	static int spawns[32];
	int count;
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, ClassSpawn[class], false))
			spawns[count++] = entity;

		if(count >= sizeof(spawns))
			break;
	}

	if(!count)
	{
		if(class >= Class_035)
		{
			entity = -1;
			while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
			{
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(StrEqual(name, ClassSpawn[Class_0492], false))
					spawns[count++] = entity;

				if(count >= sizeof(spawns))
					break;
			}

			if(!count && IsSCP(client))
			{
				Client[client].InvisFor = GetEngineTime()+30.0;

				DataPack pack;
				CreateDataTimer(1.0, Timer_Stun, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteFloat(29.0);
				pack.WriteFloat(1.0);
				pack.WriteCell(TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
				return;
			}
		}

		if(!count)
		{
			entity = -1;
			while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
			{
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(StrEqual(name, ClassSpawn[0], false))
					spawns[count++] = entity;

				if(count >= sizeof(spawns))
					break;
			}
		}
	}

	if(IsSCP(client))
	{
		Client[client].InvisFor = GetEngineTime()+15.0;

		DataPack pack;
		CreateDataTimer(1.0, Timer_Stun, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteFloat(14.0);
		pack.WriteFloat(1.0);
		pack.WriteCell(TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
	}

	if(!count)
		return;

	entity = spawns[GetRandomInt(0, count-1)];

	static float pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

public Action ResetPoint(Handle timer)
{
	int point = MaxClients+1;
	while((point=FindEntityByClassname2(point, "team_control_point")) != -1)
	{
		SetVariantInt(0);
		AcceptEntityInput(point, "SetOwner");
		SetVariantInt(1);
		AcceptEntityInput(point, "SetLocked");
		SetVariantInt(90);
		AcceptEntityInput(point, "SetUnlockTime");
	}
	return Plugin_Continue;
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
		int song = CheckCommandAccess(client, "thediscffthing", ADMFLAG_CUSTOM4) ? Music_Join2 : Music_Join;

		static char buffer[PLATFORM_MAX_PATH];
		float duration = Config_GetMusic(song, buffer, sizeof(buffer));
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

	if(Client[client].DownloadMode)
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

void EndRound(TeamEnum team, TFTeam team2)
{
	char buffer[16];
	switch(Gamemode)
	{
		case Gamemode_Ikea:
		{
			FormatEx(buffer, sizeof(buffer), "team_%d_ikea", team);
			if(!TranslationPhraseExists(buffer))
				FormatEx(buffer, sizeof(buffer), "team_%d", team);

			SetHudTextParamsEx(-1.0, 0.4, 13.0, TeamColors[team], {255, 255, 255, 255}, 1, 2.0, 1.0, 1.0);
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client))
					continue;

				SetGlobalTransTarget(client);
				ShowSyncHudText(client, HudGame, "%t", "end_screen_ikea", buffer, DClassEscaped, DClassMax);
			}
		}
		case Gamemode_Steals:
		{
			FormatEx(buffer, sizeof(buffer), "team_%d_steals", team);
			if(!TranslationPhraseExists(buffer))
				FormatEx(buffer, sizeof(buffer), "team_%d", team);

			int count;
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client) && (Client[client].Class==Class_DBoi || Client[client].Class==Class_Scientist))
					count++;
			}

			SetHudTextParamsEx(-1.0, 0.4, 8.0, TeamColors[team], {255, 255, 255, 255}, 1, 2.0, 1.0, 1.0);
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client))
					continue;

				SetGlobalTransTarget(client);
				ShowSyncHudText(client, HudGame, "%t", "end_screen_steals", buffer, count, SciMax+DClassMax, DClassEscaped, SCPMax, SCPKilled);
			}
		}
		default:
		{
			FormatEx(buffer, sizeof(buffer), "team_%d", team);
			SetHudTextParamsEx(-1.0, 0.3, 13.0, TeamColors[team], {255, 255, 255, 255}, 1, 2.0, 1.0, 1.0);
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client))
					continue;

				SetGlobalTransTarget(client);
				ShowSyncHudText(client, HudGame, "%t", "end_screen", buffer, DClassEscaped, DClassMax, SciEscaped, SciMax, SCPKilled, SCPMax);
			}
		}
	}

	int entity = -1;
	while((entity=FindEntityByClassname(entity, "logic_relay")) != -1)
	{
		char name[32];
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(StrEqual(name, "scp_roundend", false))
		{
			switch(team)
			{
				case Team_DBoi:
					AcceptEntityInput(entity, "FireUser1");

				case Team_MTF:
					AcceptEntityInput(entity, "FireUser2");

				case Team_SCP:
					AcceptEntityInput(entity, "FireUser3");

				case Team_Spec:
					AcceptEntityInput(entity, "FireUser4");
			}
			break;
		}
	}

	Enabled = false;
	entity = FindEntityByClassname(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity = CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(view_as<int>(team2));
	AcceptEntityInput(entity, "SetWinner");
}

public void DisplayHint(bool all)
{
	int amount;
	char buffer[16];
	do
	{
		amount++;
		FormatEx(buffer, sizeof(buffer), "hint_%d", amount);
	} while(TranslationPhraseExists(buffer));

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
	SetGlobalTransTarget(client);

	Client[client].HelpSprint = true;
	Client[client].HelpSwitch = true;

	bool found;
	char buffer[32];
	GetClassName(Client[client].Class, buffer, sizeof(buffer));

	SetHudTextParamsEx(-1.0, 0.3, help ? 20.0 : 10.0, Client[client].Colors, Client[client].Colors, 0, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudClass, "%t", "you_are", buffer);

	if(TrainingMessageClient(client, help))
		return;

	Client[client].HudIn = GetEngineTime()+11.0;

	switch(Gamemode)
	{
		case Gamemode_Ikea:
		{
			FormatEx(buffer, sizeof(buffer), "desc_%s_ikea", ClassShort[Client[client].Class]);
			found = TranslationPhraseExists(buffer);
		}
		case Gamemode_Nut:
		{
			FormatEx(buffer, sizeof(buffer), "desc_%s_nut", ClassShort[Client[client].Class]);
			found = TranslationPhraseExists(buffer);
		}
		case Gamemode_Steals:
		{
			FormatEx(buffer, sizeof(buffer), "desc_%s_steals", ClassShort[Client[client].Class]);
			found = TranslationPhraseExists(buffer);
		}
	}

	if(!found)
		FormatEx(buffer, sizeof(buffer), "desc_%s", ClassShort[Client[client].Class]);

	SetHudTextParamsEx(-1.0, 0.5, 10.0, Client[client].Colors, Client[client].Colors, 1, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudGame, "%t", buffer);
}

void GetClassName(any class, char[] buffer, int length)
{
	bool found;
	switch(Gamemode)
	{
		case Gamemode_Ikea:
		{
			Format(buffer, length, "class_%s_ikea", ClassShort[class]);
			found = TranslationPhraseExists(buffer);
		}
		case Gamemode_Nut:
		{
			Format(buffer, length, "class_%s_nut", ClassShort[class]);
			found = TranslationPhraseExists(buffer);
		}
		case Gamemode_Steals:
		{
			Format(buffer, length, "class_%s_steals", ClassShort[class]);
			found = TranslationPhraseExists(buffer);
		}
	}

	if(!found)
		Format(buffer, length, "class_%s", ClassShort[class]);
}

void SetCaptureRate(int client)
{
	if(Gamemode == Gamemode_None)
		return;

	float result;
	if(Items_OnKeycard(client, Access_Exit))
	{
		result = TF2_GetPlayerClass(client)==TFClass_Scout ? -1.0 : 0.0;
	}
	else
	{
		result = TF2_GetPlayerClass(client)==TFClass_Scout ? -2.0 : -1.0;
	}
	TF2Attrib_SetByDefIndex(client, 68, result);
}

bool AttemptGrabItem(int client)
{
	if(IsSpec(client) || (Client[client].Disarmer && !IsSCP(client)))
		return false;

	int entity = GetClientPointVisible(client);
	if(entity <= MaxClients)
		return false;

	//SDKCall(SDKTryPickup, client);

	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "tf_dropped_weapon"))
	{
		if(IsSCP(client))
		{
			if(Client[client].Class == Class_106)
				RemoveEntity(entity);

			return true;
		}

		if(Items_Pickup(client, GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), entity))
			AcceptEntityInput(entity, "Kill");

		return true;
	}
	else if(!StrContains(buffer, "prop_dynamic"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_keycard_", false))	// Backwards compatibility
		{
			if(!IsSCP(client))
			{
				char buffers[3][4];
				ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
				if(Items_Pickup(client, StringToInt(buffers[2])+30000))
					AcceptEntityInput(entity, "KillHierarchy");
			}
			return true;
		}
		else if(!StrContains(buffer, "scp_healthkit", false))	// Backwards compatibility
		{
			if(Client[client].Class == Class_106)
			{
				AcceptEntityInput(entity, "KillHierarchy");
			}
			else if(!IsSCP(client))
			{
				char buffers[3][4];
				ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
				int value = StringToInt(buffers[2]);
				if(value > 3)
				{
					value = 30017;
				}
				else
				{
					value += 30012;
				}

				if(Items_Pickup(client, value))
					AcceptEntityInput(entity, "KillHierarchy");
			}
			return true;
		}
		else if(!StrContains(buffer, "scp_weapon", false))	// Backwards compatibility
		{
			if(Client[client].Class == Class_106)
			{
				AcceptEntityInput(entity, "KillHierarchy");
			}
			else if(!IsSCP(client))
			{
				char buffers[3][4];
				ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
				int index = StringToInt(buffers[2]);
				if(!index)
					index = 773;

				if(Items_Pickup(client, index))
					AcceptEntityInput(entity, "KillHierarchy");
			}
			return true;
		}
		else if(!StrContains(buffer, "scp_item_", false))
		{
			if(Client[client].Class == Class_106)
			{
				AcceptEntityInput(entity, "FireUser2", client, client);
			}
			else if(!IsSCP(client))
			{
				AcceptEntityInput(entity, "FireUser1", client, client);

				char buffers[3][6];
				ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
				if(Items_Pickup(client, StringToInt(buffers[2])))
					AcceptEntityInput(entity, "KillHierarchy");
			}
			return true;
		}
		else if(!StrContains(buffer, "scp_trigger", false))
		{
			TFTeam team = Client[client].TeamTF();
			switch(team)
			{
				case TFTeam_Unassigned:
					AcceptEntityInput(entity, "FireUser1", client, client);

				case TFTeam_Red:
					AcceptEntityInput(entity, "FireUser2", client, client);

				case TFTeam_Blue:
					AcceptEntityInput(entity, "FireUser3", client, client);
			}
			return true;
		}
		else if(!StrContains(buffer, "scp_collectable", false))
		{
			if(IsSCP(client))
				return true;

			AcceptEntityInput(entity, "FireUser1", client, client);
			AcceptEntityInput(entity, "KillHierarchy");
			if(Gamemode == Gamemode_Steals)
			{
				int left = SCPMax - ++DClassEscaped;
				if(left < 1)
				{
					for(int i=1; i<=MaxClients; i++)
					{
						if(!IsClientInGame(i) || !IsPlayerAlive(i))
							continue;

						if(IsSCP(i))
						{
							ForcePlayerSuicide(i);
							continue;
						}

						ChangeClientTeamEx(i, TFTeam_Blue);
					}

					EndRound(Team_DBoi, TFTeam_Blue);
				}
				else
				{
					float engineTime = GetEngineTime()+0.7;
					for(int i=1; i<=MaxClients; i++)
					{
						if(!IsClientInGame(i) || !IsPlayerAlive(i) || IsSCP(i))
							continue;

						Client[i].HudIn = engineTime;
						ClientCommand(i, "r_screenoverlay it_steals/numbers/%d.vmt", left);
					}
				}
			}
			return true;
		}
	}
	else if(StrEqual(buffer, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
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

bool IsFriendly(ClassEnum class1, ClassEnum class2)
{
	if(class1<Class_DBoi || class2<Class_DBoi)	// Either Spectator
		return true;

	switch(Gamemode)
	{
		case Gamemode_Ikea, Gamemode_Steals:
		{
			if(class1>=Class_DBoi && class2>=Class_DBoi && class1<Class_035 && class2<Class_035)
				return true;
		}
		case Gamemode_Nut:
		{
			bool isNut1 = (class1==Class_173 || class1==Class_1732);
			bool isNut2 = (class2==Class_173 || class2==Class_1732);
			if(isNut1 && isNut2)
				return true;

			return (!isNut1 && !isNut2);
		}
		default:
		{
			if(class1<Class_Scientist && class2<Class_Scientist)	// Both are DBoi/Chaos
				return true;

			if(class1>=Class_Scientist && class2>=Class_Scientist && class1<Class_035 && class2<Class_035)	// Both are Scientist/MTF
				return true;
		}
	}

	return (class1>=Class_035 && class2>=Class_035);	// Both are SCPs
}

int ClassMaxAmmo(int ammo, ClassEnum class)
{
	switch(ammo)
	{
		case Ammo_Micro:
		{
			return 1000;
		}
		case Ammo_9mm:
		{
			if(class == Class_Chaos)
			{
				return 100;
			}
			else if(class < Class_Guard)
			{
				return 50;
			}
			else
			{
				return 200;
			}
		}
		case Ammo_Metal:
		{
			return 400;
		}
		case Ammo_7mm:
		{
			if(class == Class_Chaos)
			{
				return 200;
			}
			else if(class < Class_Guard)
			{
				return 70;
			}
			else
			{
				return 100;
			}
		}
		case Ammo_5mm:
		{
			if(class < Class_Guard)
			{
				return 80;
			}
			else
			{
				return 160;
			}
		}
		case Ammo_Grenade:
		{
			return 3;
		}
		case Ammo_Radio:
		{
			return 100;
		}
		default:
		{
			return 1;
		}
	}
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

/*public Action CH_PassFilter(int ent1, int ent2, bool &result)
{
	CollisionHook = true;
	if(!Enabled || !IsValidClient(ent1) || !IsValidClient(ent2))
		return Plugin_Continue;

	if(IsFriendly(Client[ent1].Class, Client[ent2].Class))
	{
		result = false;
	}
	else
	{
		int weapon = GetEntPropEnt(ent1, Prop_Send, "m_hActiveWeapon");
		result = (weapon>MaxClients && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")!=WeaponIndex[Weapon_None]);

		if(!result)
		{
			weapon = GetEntPropEnt(ent2, Prop_Send, "m_hActiveWeapon");
			if(weapon>MaxClients && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")!=WeaponIndex[Weapon_None])
				result = true;
		}
	}
	result = !IsFriendly(Client[ent1].Class, Client[ent2].Class);
	return Plugin_Handled;
}*/

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
	if(Enabled && Client[client].HudIn>GetEngineTime())
		return Plugin_Continue;

	value = view_as<int>(Client[client].WeaponClass);
	return Plugin_Changed;
}
#endif

// Ragdoll Effects

void CreateSpecialDeath(int client)
{
	TFClassType class = ClassClassModel[Client[client].Class];
	if(class==TFClass_Pyro || class==TFClass_Unknown)
		return;

	int entity = CreateEntityByName("prop_dynamic_override");
	if(!IsValidEntity(entity))
		return;

	RequestFrame(RemoveRagdoll, GetClientUserId(client));

	int special = (class==TFClass_Engineer || class==TFClass_DemoMan || class==TFClass_Heavy) ? 1 : 0;
	float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	int team = GetClientTeam(client);
	{
		char skin[2];
		IntToString(team-2, skin, sizeof(skin));
		DispatchKeyValue(entity, "skin", skin);
	}
	DispatchKeyValue(entity, "solid", "0");
	DispatchKeyValue(entity, "model", ClassModel[Client[client].Class]);
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		DispatchKeyValueVector(entity, "angles", angles);
	}
	DispatchSpawn(entity);

	SetVariantString(FireDeath[special]);
	AcceptEntityInput(entity, "SetAnimation");

	CreateTimer(FireDeathTimes[class], Timer_RemoveEntity, EntIndexToEntRef(entity));
}

// Glow Effects

stock int TF2_CreateGlow(int client, TFTeam team)
{
	int prop = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(prop))
	{
		if(team != TFTeam_Unassigned)
		{
			SetEntProp(prop, Prop_Data, "m_iInitialTeamNum", view_as<int>(team));
			SetEntProp(prop, Prop_Send, "m_iTeamNum", view_as<int>(team));
		}

		DispatchSpawn(prop);

		SetEntityModel(prop, ClassModel[Client[client].Class]);
		SetEntPropEnt(prop, Prop_Data, "m_hEffectEntity", client);
		SetEntProp(prop, Prop_Send, "m_bGlowEnabled", true);
		SetEntProp(prop, Prop_Send, "m_fEffects", GetEntProp(prop, Prop_Send, "m_fEffects")|EF_BONEMERGE|EF_NOSHADOW|EF_NOINTERP);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", client);

		SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
		SetEntityRenderColor(prop, 255, 255, 255, 255);
		SDKHook(prop, SDKHook_SetTransmit, GlowTransmit);
	}
	return prop;
}

public Action GlowTransmit(int entity, int target)
{
	if(!Enabled)
	{
		SDKUnhook(entity, SDKHook_SetTransmit, GlowTransmit);
		AcceptEntityInput(entity, "Kill");
		return Plugin_Continue;
	}

	if(!IsValidClient(target))
		return Plugin_Continue;

	int client = GetEntPropEnt(entity, Prop_Data, "m_hParent");
	if(!IsValidClient(client) || IsSpec(client))
	{
		SDKUnhook(entity, SDKHook_SetTransmit, GlowTransmit);
		AcceptEntityInput(entity, "Kill");
		return Plugin_Stop;
	}

	return Function_OnGlowPlayer(target, client) ? Plugin_Continue : Plugin_Stop;
}

bool TrainingMessageClient(int client, bool override=false)
{
	char buffer[32];
	if(!override)
	{
		if(!AreClientCookiesCached(client))
			return false;

		CookieTraining.Get(client, buffer, sizeof(buffer));

		int flags = StringToInt(buffer);
		int flag = RoundFloat(Pow(2.0, float(view_as<int>(Client[client].Class))));
		if(flags & flag)
		{
			return false;
		}
		else
		{
			flags |= flag;
		}

		IntToString(flags, buffer, sizeof(buffer));
		CookieTraining.Set(client, buffer);
	}

	SetGlobalTransTarget(client);

	Client[client].HudIn = GetEngineTime();
	if(override)
	{
		Client[client].HudIn += 21.0;
	}
	else
	{
		Client[client].HudIn += 31.0;
	}

	SetHudTextParamsEx(-1.0, 0.5, override ? 20.0 : 30.0, Client[client].Colors, Client[client].Colors, 1, 5.0, 1.0, 1.0);
	FormatEx(buffer, sizeof(buffer), "train_%s", ClassShort[Client[client].Class]);
	ShowSyncHudText(client, HudGame, "%t", buffer);
	return true;
}

#file "SCP: Secret Fortress"