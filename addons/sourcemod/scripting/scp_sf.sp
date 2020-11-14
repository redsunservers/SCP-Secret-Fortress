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
#tryinclude <collisionhook>
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

	PrintToConsole(i, "Chaos, SCP-049-2 | DoctorKrazy | forums.alliedmods.net/member.php?u=288676");
	PrintToConsole(i, "MTF, SCP-049, SCP-096 | JuegosPablo | forums.alliedmods.net/showthread.php?t=308656");
	PrintToConsole(i, "SCP-173 | RavensBro | forums.alliedmods.net/showthread.php?t=203464");
	PrintToConsole(i, "SCP-106 | Spyer | forums.alliedmods.net/member.php?u=272596");
	PrintToConsole(i, "Soundtracks | Jacek \"Burnert\" Rogal");

	PrintToConsole(i, "Cosmic Inspiration | Marxvee | forums.alliedmods.net/member.php?u=289257");
	PrintToConsole(i, "Map/Model Development | Artvin | forums.alliedmods.net/member.php?u=304206");
}

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"7"
#define STABLE_REVISION	"0"
#define PLUGIN_VERSION	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define IsSCP(%1)	(Client[%1].Class>=Class_035)
//#define IsSpec(%1)	(Client[%1].Class==Class_Spec || !IsPlayerAlive(%1) || TF2_IsPlayerInCondition(%1, TFCond_HalloweenGhostMode))

#define FAR_FUTURE	100000000.0
#define MAXTF2PLAYERS	36
#define MAXANGLEPITCH	45.0
#define MAXANGLEYAW	90.0
#define MAXENTITIES	2048

#define PREFIX		"{red}[SCP]{default} "
#define KEYCARD_MODEL	"models/scp_sl/keycard.mdl"
#define VIP_GHOST_MODEL	"models/props_halloween/ghost.mdl"
#define DOWNLOADS	"configs/scp_sf/downloads.txt"
#define CFG_REACTIONS	"configs/scp_sf/reactions.cfg"

float TRIPLE_D[3] = { 0.0, 0.0, 0.0 };

Handle HudIntro;
Handle HudExtra;
Handle HudPlayer;

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

	"models/freak_fortress_2/scp-049/zombie049.mdl",	// 035
	"models/freak_fortress_2/scp-049/scp049.mdl",		// 049
	"models/freak_fortress_2/scp-049/zombie049.mdl",	// 049-2
	"models/freak_fortress_2/newscp076/newscp076_v1.mdl", 	// 076-2
	"models/player/engineer.mdl", 				// 079
	"models/freak_fortress_2/096/scp096.mdl",		// 096
	"models/freak_fortress_2/106_spyper/106.mdl",		// 106
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
	TFClass_Pyro,		// 939-89
	TFClass_Pyro,		// 939-53
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
	TFClass_Medic,		// 049
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

enum KeycardEnum
{
	Keycard_106 = -2,
	Keycard_SCP = -1,

	Keycard_None = 0,

	Keycard_Janitor,		// 1
	Keycard_Scientist,

	Keycard_Zone,		// 3
	Keycard_Research,

	Keycard_Guard,		// 5
	Keycard_MTF,
	Keycard_MTF2,
	Keycard_MTF3,

	Keycard_Engineer,		// 9
	Keycard_Facility,

	Keycard_Chaos,		// 11
	Keycard_O5
}

int KeycardSkin[] =
{
	3,

	3,
	8,

	10,
	5,

	2,
	9,
	4,
	6,

	0,
	1,

	6,
	7
};

KeycardEnum KeycardPaths[][] =
{
	{ Keycard_None, Keycard_None, Keycard_None },

	{ Keycard_None, Keycard_Zone, Keycard_Scientist },
	{ Keycard_None, Keycard_Zone, Keycard_Research },

	{ Keycard_Scientist, Keycard_Guard, Keycard_Facility },
	{ Keycard_Scientist, Keycard_Guard, Keycard_Engineer },

	{ Keycard_Scientist, Keycard_Research, Keycard_MTF },
	{ Keycard_Research, Keycard_Engineer, Keycard_MTF2 },
	{ Keycard_MTF, Keycard_Engineer, Keycard_MTF3 },
	{ Keycard_MTF2, Keycard_Chaos, Keycard_O5 },

	{ Keycard_Research, Keycard_MTF, Keycard_O5 },
	{ Keycard_MTF3, Keycard_Chaos, Keycard_O5 },

	{ Keycard_Chaos, Keycard_MTF3, Keycard_O5 },
	{ Keycard_Engineer, Keycard_O5, Keycard_O5 }
};

char KeycardNames[][] =
{
	"scp_card_00",

	"scp_card_01",
	"scp_card_02",

	"scp_card_03",
	"scp_card_04",

	"scp_card_05",
	"scp_card_06",
	"scp_card_07",
	"scp_card_08",

	"scp_card_09",
	"scp_card_10",

	"scp_card_11",
	"scp_card_12"
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

enum WeaponEnum
{
	Weapon_None = 0,

	Weapon_Axe,
	Weapon_Hammer,
	Weapon_Knife,
	Weapon_Bash,
	Weapon_Meat,
	Weapon_Wrench,
	Weapon_Pan,

	Weapon_Disarm,

	Weapon_Pistol,		// COM-15 Sidearm
	Weapon_Pistol2,		// USP
	Weapon_SMG,		// MP7
	Weapon_SMG2,		// Project 90
	Weapon_SMG3,		// MTF-E11-SR
	Weapon_SMG4,		// Logicer

	Weapon_Flash,
	Weapon_Frag,
	Weapon_Shotgun,
	Weapon_Micro,

	Weapon_PDA1,
	Weapon_PDA2,
	Weapon_PDA3,

	Weapon_049,
	Weapon_049Gun,
	Weapon_0492,

	Weapon_076,
	Weapon_076Rage,

	Weapon_096,
	Weapon_096Rage,

	Weapon_106,
	Weapon_173,
	Weapon_939,

	Weapon_3008,
	Weapon_3008Rage,

	Weapon_Stealer
}

int WeaponIndex[] =
{
	5,

	// Melee
	192,
	153,
	30758,
	325,
	1013,
	197,
	264,

	954,	// Disarmer

	// Secondary
	209,	//773
	294,	//209
	751,
	1150,
	425,
	415,

	// Primary
	1151,
	308,
	199,
	594,

	// PDAs
	25,
	26,
	28,

	// 049
	173,
	35,
	572,

	// 076
	195,
	266,

	// 096
	195,
	154,

	// SCPs
	939,
	195,
	326,

	// 3008
	195,
	195,

	574	// It Steals
};

int WeaponRank[] =
{
	13,

	// Melee
	2,
	3,
	4,
	1,
	17,
	5,
	6,

	0,	// Disarmer

	// Secondary
	1,
	2,
	3,
	4,
	6,
	7,

	// Primary
	12,
	11,
	9,
	14,

	// PDAs
	-1,
	-1,
	-1,

	// 049
	11,
	6,
	4,

	// 076
	11,
	18,

	// 096
	15,
	16,

	// SCPs
	12,
	17,
	10,

	// 3008
	0,
	10,

	16	// It Steals
};

enum GamemodeEnum
{
	Gamemode_None,	// SCP dedicated map
	Gamemode_Ikea,	// SCP-3008-2 map
	Gamemode_Nut,	// SCP-173 infection map
	Gamemode_Steals,	// It Steals spin-off map
	Gamemode_Arena,	// KotH but enable arena logic
	Gamemode_Koth,	// Control Points are the objectives
	Gamemode_Ctf	// Flags are the objectives
}

enum
{
	Floor_Light = 0,
	Floor_Heavy,
	Floor_Surface
}

bool Ready = false;
bool Enabled = false;
bool NoMusic = false;
bool SourceComms = false;		// SourceComms++
bool BaseComm = false;		// BaseComm
bool CollisionHook = false;	// CollisionHook

Cookie CookieTraining;
Cookie CookiePref;
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
	KeycardEnum Keycard;

	bool IsVip;
	bool MTFBan;
	bool CanTalkTo[MAXTF2PLAYERS];

	ClassEnum PreferredSCP;

	int Triggered;
	int HealthPack;
	int Radio;
	int Floor;
	int Disarmer;
	int DownloadMode;
	int Spree;
	float SpreeFor;

	float Power;
	float IdleAt;
	float ComFor;
	float IsCapping;
	float InvisFor;
	float Respawning;
	float ChatIn;
	float HudIn;
	float ChargeIn;
	float AloneIn;
	float Cooldown;
	float Pos[3];

	// Sprinting
	bool Sprinting;
	float SprintPower;

	// Revive Markers
	int ReviveIndex;
	float ReviveMoveAt;
	float ReviveGoneAt;

	// Music
	float NextSongAt;
	char CurrentSong[PLATFORM_MAX_PATH];

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

	int Access(AccessEnum type)
	{
		switch(type)
		{
			case Access_Main:
			{
				switch(this.Keycard)
				{
					case Keycard_None, Keycard_SCP:
						return 0;

					case Keycard_Janitor, Keycard_Guard, Keycard_Zone:
						return 1;

					case Keycard_Engineer, Keycard_Facility, Keycard_O5, Keycard_106:
						return 3;

					default:
						return 2;
				}
			}
			case Access_Armory:
			{
				switch(this.Keycard)
				{
					case Keycard_Guard, Keycard_MTF:
						return 1;

					case Keycard_MTF2:
						return 2;

					case Keycard_MTF3, Keycard_Chaos, Keycard_O5, Keycard_106:
						return 3;
				}
			}
			case Access_Exit:
			{
				if(this.Keycard==Keycard_MTF2 || this.Keycard==Keycard_MTF3 || this.Keycard==Keycard_Facility || this.Keycard==Keycard_Chaos || this.Keycard==Keycard_O5 || this.Keycard==Keycard_106)
					return 1;
			}
			case Access_Warhead:
			{
				if(this.Keycard==Keycard_Engineer || this.Keycard==Keycard_Facility || this.Keycard==Keycard_O5 || this.Keycard==Keycard_106)
					return 1;
			}
			case Access_Checkpoint:
			{
				if(this.Keycard==Keycard_None || this.Keycard==Keycard_Janitor || this.Keycard==Keycard_Scientist)
					return 0;

				return 1;
			}
			case Access_Intercom:
			{
				if(this.Keycard==Keycard_Engineer || this.Keycard==Keycard_MTF3 || this.Keycard==Keycard_Facility || this.Keycard==Keycard_Chaos || this.Keycard==Keycard_O5 || this.Keycard==Keycard_106)
					return 1;
			}
		}
		return 0;
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
#include "scp_sf/natives.sp"
#include "scp_sf/sdkcalls.sp"
#include "scp_sf/sdkhooks.sp"

// SourceMod Events

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Forward_Setup();
	Native_Setup();
	RegPluginLibrary("scp_sf");
	return APLRes_Success;
}

public void OnPluginStart()
{
	Client[0].NextSongAt = FAR_FUTURE;

	ConVar_Setup();
	SDKHook_Setup();

	HookEvent("arena_round_start", OnRoundReady, EventHookMode_PostNoCopy);
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
	HookEvent("revive_player_complete", OnRevive);

	RegConsoleCmd("scp", Command_MainMenu, "View SCP: Secret Fortress main menu");

	RegConsoleCmd("scpinfo", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scp_info", Command_HelpClass, "View info about your current class");

	RegConsoleCmd("scppref", Command_Preference, "Sets your prefered SCP to play as.");
	RegConsoleCmd("scp_pref", Command_Preference, "Sets your prefered SCP to play as.");
	RegConsoleCmd("scppreference", Command_Preference, "Sets your prefered SCP to play as.");
	RegConsoleCmd("scp_preference", Command_Preference, "Sets your prefered SCP to play as.");

	RegAdminCmd("scp_forceclass", Command_ForceClass, ADMFLAG_SLAY, "Usage: scp_forceclass <target> <class>.  Forces that class to be played.");
	RegAdminCmd("scp_giveweapon", Command_ForceWeapon, ADMFLAG_SLAY, "Usage: scp_giveweapon <target> <id>.  Gives a specific weapon.");
	RegAdminCmd("scp_givekeycard", Command_ForceCard, ADMFLAG_SLAY, "Usage: scp_givekeycard <target> <id>.  Gives a specific keycard.");
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

	HudIntro = CreateHudSynchronizer();
	HudExtra = CreateHudSynchronizer();
	HudPlayer = CreateHudSynchronizer();

	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);
	HookEntityOutput("math_counter", "OutValue", OnCounterValue);
	AddTempEntHook("Player Decal", OnPlayerSpray);

	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("scp_sf.phrases");

	AddMultiTargetFilter("@random", Target_Random, "[REDACTED] players", false);
	AddMultiTargetFilter("@!random", Target_Random, "[REDACTED] players", false);
	AddMultiTargetFilter("@scp", Target_SCP, "all SCP subjects", false);
	AddMultiTargetFilter("@!scp", Target_SCP, "all non-SCP subjects", false);
	AddMultiTargetFilter("@chaos", Target_Chaos, "all Chaos Insurgency Agents", false);
	AddMultiTargetFilter("@!chaos", Target_Chaos, "all non-Chaos Insurgency Agents", false);
	AddMultiTargetFilter("@mtf", Target_MTF, "all Mobile Task Force Units", false);
	AddMultiTargetFilter("@!mtf", Target_MTF, "all non-Mobile Task Force Units", false);
	AddMultiTargetFilter("@ghost", Target_Ghost, "all dead players", true);
	AddMultiTargetFilter("@!ghost", Target_Ghost, "all alive players", true);
	AddMultiTargetFilter("@dclass", Target_DBoi, "all d bois", false);
	AddMultiTargetFilter("@!dclass", Target_DBoi, "all not d bois", false);
	AddMultiTargetFilter("@scientist", Target_Scientist, "all Scientists", false);
	AddMultiTargetFilter("@!scientist", Target_Scientist, "all non-Scientists", false);
	AddMultiTargetFilter("@guard", Target_Guard, "all Facility Guards", false);
	AddMultiTargetFilter("@!guard", Target_Guard, "all non-Facility Guards", false);

	CookieTraining = new Cookie("scp_cookie_training", "Status on learning the SCP gamemode", CookieAccess_Public);
	CookiePref = new Cookie("scp_cookie_preference", "Preference on which SCP to become", CookieAccess_Protected);
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
	Ready = false;

	Config_Setup();

	char buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));
	if(!StrContains(buffer, "scp_", false))
	{
		Gamemode = Gamemode_None;
	}
	else if(!StrContains(buffer, "arena_", false) || !StrContains(buffer, "vsh_", false))
	{
		Gamemode = Gamemode_Arena;
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
	else
	{
		if(ClassEnabled[Class_3008])
		{
			Gamemode = Gamemode_Ikea;
		}
		else if(ClassEnabled[Class_1732])
		{
			Gamemode = Gamemode_Nut;
		}
		else if(ClassEnabled[Class_Stealer])
		{
			Gamemode = Gamemode_Steals;
			SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
		}
	}

	#if defined _SENDPROXYMANAGER_INC_
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
	#endif

	DHook_MapStart();
}

public void OnConfigsExecuted()
{
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

	ConVar_Enable();
}

public void OnPluginEnd()
{
	ConVar_Disable();
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i))
			DHook_UnhookClient(i);
	}
}

public void OnClientPutInServer(int client)
{
	Client[client] = Client[0];

	SDKHook_HookClient(client);
	DHook_HookClient(client);
}

public void OnClientCookiesCached(int client)
{
	static char buffer[16];
	CookieMTFBan.Get(client, buffer, sizeof(buffer));
	Client[client].MTFBan = buffer[0]=='1';

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

public void OnRoundReady(Event event, const char[] name, bool dontBroadcast)
{
	Ready = true;
	Gamemode = Gamemode_Arena;
}

public void TF2_OnWaitingForPlayersStart()
{
	Ready = false;
	if(CvarSpecGhost.BoolValue && Gamemode!=Gamemode_Arena)
		TF2_SendHudNotification(HUD_NOTIFY_HOW_TO_CONTROL_GHOST_NO_RESPAWN);
}

public void TF2_OnWaitingForPlayersEnd()
{
	Ready = true;
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

		if(TF2_GetPlayerClass(client) == TFClass_Sniper)
			TF2_SetPlayerClass(client, TFClass_Soldier);

		if(IsPlayerAlive(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
			ChangeClientTeamEx(client, TFTeam_Red);

		if(Client[client].Class==Class_106 && Client[client].Radio)
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

	if(!Ready)
		return;

	if(Gamemode == Gamemode_Arena)
	{
		int entity = MaxClients+1;
		while((entity=FindEntityByClassname2(entity, "trigger_capture_area")) != -1)
		{
			SDKHook_HookCapture(entity);
		}
	}
	else
	{
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
		int id = StringToInt(name[11]);
		if(id<0 && id>=view_as<int>(AccessEnum))
			return Plugin_Continue;

		if(!IsValidClient(client))
			return Plugin_Continue;

		id = Client[client].Access(view_as<AccessEnum>(id));
		switch(id)
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
	else if(!StrContains(name, "scp_removecard", false))
	{
		if(IsValidClient(client))
			Client[client].Keycard = Keycard_None;
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
			if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
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
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && (Client[target].Class==Class_106 || Client[target].Class==Class_3008))
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
		}

		GiveAchievement(Achievement_Kill106);
	}
	else if(!StrContains(name, "scp_upgrade", false))
	{
		if(!IsValidClient(client))
			return Plugin_Continue;

		char buffer[64];
		if(Client[client].Cooldown > GetEngineTime())
		{
			Menu menu = new Menu(Handler_None);
			SetGlobalTransTarget(client);
			menu.SetTitle("%t", "scp_914");

			FormatEx(buffer, sizeof(buffer), "%t", "in_cooldown");
			menu.AddItem("0", buffer);
			menu.ExitButton = false;
			menu.Display(client, 3);
		}
		else
		{
			Menu menu = new Menu(Handler_Upgrade);
			SetGlobalTransTarget(client);
			menu.SetTitle("%t", "scp_914");

			if(Client[client].Keycard > Keycard_None)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "keycard_rough");
				menu.AddItem("0", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_coarse");
				menu.AddItem("1", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_even");
				menu.AddItem("2", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_fine");
				menu.AddItem("3", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_very");
				menu.AddItem("4", buffer);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "keycard_rough");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_coarse");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_even");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_fine");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "keycard_very");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);
			}

			if(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary) > MaxClients)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "weapon_rough");
				menu.AddItem("5", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_coarse");
				menu.AddItem("6", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_even");
				menu.AddItem("7", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_fine");
				menu.AddItem("8", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_very");
				menu.AddItem("9", buffer);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "weapon_rough");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_coarse");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_even");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_fine");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "weapon_very");
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);
			}

			menu.Pagination = false;
			menu.Display(client, 10);
		}
	}
	else if(!StrContains(name, "scp_intercom", false))
	{
		if(IsValidClient(client))
		{
			Client[client].ComFor = GetEngineTime()+15.0;
			GiveAchievement(Achievement_Intercom, client);
		}
	}
	else if(!StrContains(name, "scp_nuke", false))
	{
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
			switch(choice)
			{
				case 0:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard<=Keycard_None)
						return;

					Client[client].Cooldown = GetEngineTime()+10.0;
					if(GetRandomInt(0, 1))
					{
						Client[client].Keycard = Keycard_None;
						return;
					}

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][0];
					Client[client].Keycard = KeycardPaths[Client[client].Keycard][0];
				}
				case 1:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard<=Keycard_None)
						return;

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][0];
					Client[client].Cooldown = GetEngineTime()+12.5;
				}
				case 2:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard<=Keycard_None)
						return;

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][1];
					Client[client].Cooldown = GetEngineTime()+15.0;
				}
				case 3:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard<=Keycard_None)
						return;

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][2];
					Client[client].Cooldown = GetEngineTime()+17.5;
					if(Client[client].Keycard == Keycard_O5)
						GiveAchievement(Achievement_FindO5, client);
				}
				case 4:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard<=Keycard_None)
						return;

					Client[client].Cooldown = GetEngineTime()+20.0;
					if(GetRandomInt(0, 1))
					{
						Client[client].Keycard = Keycard_None;
						return;
					}

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][2];
					Client[client].Keycard = KeycardPaths[Client[client].Keycard][2];
					if(Client[client].Keycard == Keycard_O5)
						GiveAchievement(Achievement_FindO5, client);
				}
				case 5:
				{
					if(!IsPlayerAlive(client))
						return;

					int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(entity <= MaxClients)
						return;

					int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					WeaponEnum wep = Weapon_Pistol;
					for(; wep<=Weapon_SMG4; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG4)
						return;

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+10.0;

					wep -= view_as<WeaponEnum>(2);
					if(wep<Weapon_Pistol || GetRandomInt(0, 1))
						return;

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
				case 6:
				{
					if(!IsPlayerAlive(client))
						return;

					int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(entity <= MaxClients)
						return;

					int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					WeaponEnum wep = Weapon_Pistol;
					for(; wep<=Weapon_SMG4; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG4)
						return;

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+12.5;

					wep--;
					if(wep < Weapon_Pistol)
						return;

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
				case 7:
				{
					if(!IsPlayerAlive(client) || GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)<=MaxClients)
						return;

					Client[client].Cooldown = GetEngineTime()+15.0;
					Client[client].Power = 99.0;
					SpawnPickup(client, "item_ammopack_full");
				}
				case 8:
				{
					if(!IsPlayerAlive(client))
						return;

					int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(entity <= MaxClients)
						return;

					int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					WeaponEnum wep = Weapon_Pistol;
					for(; wep<=Weapon_SMG4; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG4)
						return;

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+17.5;

					wep++;
					if(wep > Weapon_SMG4)
						wep = Weapon_SMG4;

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
				case 9:
				{
					if(!IsPlayerAlive(client))
						return;

					int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(entity <= MaxClients)
						return;

					int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					WeaponEnum wep = Weapon_Pistol;
					for(; wep<=Weapon_SMG4; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG4)
						return;

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+20.0;
					if(GetRandomInt(0, 1))
						return;

					wep += view_as<WeaponEnum>(2);
					if(wep > Weapon_SMG4)
						wep = Weapon_SMG4;

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
			}

			if(choice<5 && Client[client].Class==Class_Scientist)
				GiveAchievement(Achievement_Upgrade, client);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	if(!Enabled)
		return;

	SDKCall_SetSpeed(client);

	if(cond == TFCond_Taunting)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
			TF2_RemoveCondition(client, TFCond_Taunting);

		return;
	}

	if(cond != TFCond_TeleportedGlow)
		return;

	if(Client[client].Class == Class_DBoi)
	{
		DropAllWeapons(client);
		if(Gamemode == Gamemode_Ikea)
		{
			DClassEscaped++;
			Client[client].Class = Client[client].MTFBan ? Class_Spec : Class_MTFS;
		}
		else if(Client[client].Disarmer)
		{
			DClassCaptured++;
			Client[client].Class = Client[client].MTFBan ? Class_Spec : Class_MTF2;

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
				Client[total].Class = Class_MTF2;
				AssignTeam(total);
				RespawnPlayer(total);
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
		DropAllWeapons(client);
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
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client) || (!Ready && !Enabled && Gamemode==Gamemode_Arena))
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

		ChangeClientClass(client, ClassClass[Client[client].Class]);

		if(team != TFTeam_Spectator)
			ChangeClientTeamEx(client, team);
	}

	//Client[client].CustomHitbox = false;
	Client[client].Triggered = 0;
	Client[client].Sprinting = false;
	Client[client].ChargeIn = 0.0;
	Client[client].Disarmer = 0;
	Client[client].SprintPower = 100.0;
	Client[client].Power = 100.0;
	switch(Client[client].Class)
	{
		case Class_DBoi:
		{
			Client[client].Keycard = Keycard_None;
			Client[client].HealthPack = 0;
			Client[client].Floor = Floor_Light;
			if(Gamemode == Gamemode_Steals)
			{
				TurnOnFlashlight(client);
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
			}

			Client[client].Radio = Gamemode==Gamemode_Steals ? 2 : 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
		}
		case Class_Chaos:
		{
			Client[client].Keycard = Keycard_Chaos;
			Client[client].HealthPack = 2;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Surface;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG4));
			GiveWeapon(client, Weapon_None);
			GiveAchievement(Achievement_ChaosSpawn, client);
		}
		case Class_Scientist:
		{
			Client[client].Keycard = Keycard_Scientist;
			Client[client].HealthPack = Gamemode==Gamemode_Steals ? 0 : 2;
			Client[client].Floor = Floor_Heavy;
			if(Gamemode == Gamemode_Steals)
			{
				TurnOnFlashlight(client);
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
			}

			Client[client].Radio = Gamemode==Gamemode_Steals ? 2 : 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
		}
		case Class_Guard:
		{
			Client[client].Keycard = Keycard_Guard;
			Client[client].HealthPack = 0;
			Client[client].Radio = 1;
			Client[client].Floor = Floor_Heavy;
			GiveWeapon(client, Weapon_Flash);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG));
			GiveWeapon(client, Weapon_Disarm);
		}
		case Class_MTF:
		{
			Client[client].Keycard = Keycard_MTF;
			Client[client].HealthPack = 0;
			Client[client].Radio = 1;
			Client[client].Floor = Floor_Surface;
			GiveWeapon(client, Weapon_Flash);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG2));
			GiveWeapon(client, Weapon_None);
			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTF2, Class_MTFS:
		{
			Client[client].Keycard = Keycard_MTF2;
			Client[client].HealthPack = Client[client].Class==Class_MTFS ? 2 : 1;
			Client[client].Radio = 1;
			Client[client].Floor = Floor_Surface;
			GiveWeapon(client, Weapon_Frag);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG3));
			if(Gamemode != Gamemode_Ikea)
				GiveWeapon(client, Weapon_Disarm);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTF3:
		{
			Client[client].Keycard = Keycard_MTF3;
			Client[client].HealthPack = 1;
			Client[client].Radio = 1;
			Client[client].Floor = Floor_Surface;
			GiveWeapon(client, Weapon_Frag);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG4));
			if(Gamemode != Gamemode_Ikea)
				GiveWeapon(client, Weapon_Disarm);

			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_MTFE:
		{
			Client[client].Keycard = Keycard_MTF2;
			Client[client].HealthPack = 1;
			Client[client].Radio = 1;
			Client[client].Floor = Floor_Surface;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_Shotgun));
			GiveWeapon(client, Weapon_Wrench);
			GiveWeapon(client, Weapon_PDA1);
			GiveWeapon(client, Weapon_PDA2);
			GiveWeapon(client, Weapon_PDA3);
			GiveAchievement(Achievement_MTFSpawn, client);
		}
		case Class_049:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			GiveWeapon(client, Weapon_049Gun);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_049));
		}
		case Class_0492:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Heavy;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_0492));
		}
		case Class_076:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Heavy;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_076));
			CreateTimer(1.0, Timer_UpdateClientHud, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		case Class_096:
		{
			Client[client].Pos[0] = 0.0;
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 1500;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Heavy;
			SetEntityHealth(client, 1850);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096));
		}
		case Class_106:
		{
			Client[client].Pos[0] = 0.0;
			Client[client].Pos[1] = 0.0;
			Client[client].Pos[2] = 0.0;
			Client[client].Keycard = Keycard_106;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Heavy;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_106));
		}
		case Class_173:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Heavy;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_173));
		}
		case Class_1732:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Heavy;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_173));
		}
		case Class_939, Class_9392:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			Client[client].Floor = Floor_Light;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_939));
		}
		case Class_3008:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = SciEscaped;
			Client[client].Floor = Floor_Heavy;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, SciEscaped ? Weapon_3008Rage : Weapon_3008));
		}
		case Class_Stealer:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_Stealer));
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", false);
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

	if(Client[client].Class!=Class_0492 && ClassSpawn[Client[client].Class][0])
		GoToSpawn(client, Client[client].Class);

	if(!CollisionHook && team==TFTeam_Unassigned)
	{
		SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	}

	Client[client].HudIn = GetEngineTime()+9.9;
	CreateTimer(2.0, ShowClassInfoTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	TF2_CreateGlow(client, team);
	SetCaptureRate(client);
	SetVariantString(ClassModel[Client[client].Class]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	if(Client[client].Class == Class_1732)
		SetEntProp(client, Prop_Send, "m_nSkin", client%10);

	TF2Attrib_SetByDefIndex(client, 49, 1.0);
	TF2Attrib_SetByDefIndex(client, 69, 0.1);
	TF2_AddCondition(client, TFCond_NoHealingDamageBuff, 1.0);

	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelIndex[Client[client].Class], _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelSubIndex[Client[client].Class], _, 3);

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
	int clientId = event.GetInt("userid");
	int attackerId = event.GetInt("attacker");
	int attacker = GetClientOfUserId(attackerId);
	if(!attacker)
		return Plugin_Handled;

	int count;
	int[] clients = new int[MaxClients];
	for(int i=1; i<=MaxClients; i++)
	{
		if(i==attacker || (IsClientInGame(i) && IsFriendly(Client[attacker].Class, Client[i].Class) && Client[attacker].CanTalkTo[i]))
			clients[count++] = i;
	}

	static char buffer[64];
	event.GetString("weapon", buffer, sizeof(buffer));
	ShowDestoryNotice(clients, count, attackerId, clientId, event.GetInt("assister"), event.GetInt("weaponid"), buffer, event.GetInt("objecttype"), event.GetInt("index"), event.GetBool("was_building"));
	return Plugin_Handled;
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
	if(!client)
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
	if(!client)
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
		int i = Client[client].Radio+1;
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
				Client[client].Radio = i;
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
		static float origin[3], angles[3];
		GetClientEyePosition(client, origin);
		GetClientEyeAngles(client, angles);

		if(Client[client].Keycard > Keycard_None)
		{
			DropKeycard(client, true, origin, angles);
			Client[client].Keycard = Keycard_None;
			return Plugin_Handled;
		}

		int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(entity > MaxClients)
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			for(WeaponEnum wep=Weapon_Axe; wep<Weapon_PDA1; wep++)
			{
				if(index != WeaponIndex[wep])
					continue;

				TF2_CreateDroppedWeapon(client, entity, true, origin, angles);
				int slot = wep>Weapon_Disarm ? wep<Weapon_Flash ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary : TFWeaponSlot_Melee;
				TF2_RemoveWeaponSlot(client, slot);
				if(slot == TFWeaponSlot_Melee)
				{
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
					return Plugin_Handled;
				}

				for(int i; i<3; i++)
				{
					if(i == slot)
						continue;

					entity = GetPlayerWeaponSlot(client, i);
					if(entity <= MaxClients)
						continue;

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
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

		static float clientPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
		for(int target=1; target<=MaxClients; target++)
		{
			if(target == client)
			{
				CPrintToChat(target, "%s {default}: %s", name, msg);
				continue;
			}

			if(!IsValidClient(target, false) || !Client[client].CanTalkTo[target])
				continue;

			if(IsSpec(target))
			{
				CPrintToChat(target, "%s {default}: %s", name, msg);
			}
			else if(IsSCP(client))
			{
				if(IsFriendly(Client[client].Class, Client[target].Class))
					CPrintToChat(target, "%s {default}: %s", name, msg);
			}
			else if(Client[client].Power<=0 || !Client[client].Radio)
			{
				CPrintToChat(target, "%s {default}: %s", name, msg);
			}
			else
			{
				static float targetPos[3];
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
				CPrintToChat(target, "%s%s {default}: %s", GetVectorDistance(clientPos, targetPos)<400 ? "" : "*RADIO* ", name, msg);
			}
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
		menu.SetTitle("SCP: Secret Fortress\n%t ", "menu_preference");

		char current[16];
		if(AreClientCookiesCached(client))
			CookiePref.Get(client, current, sizeof(current));

		menu.AddItem("1", "No SCP", StrEqual(ClassShort[1], current) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		menu.AddItem("0", "Any SCP", StrEqual(ClassShort[0], current) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

		static char buffer[64], num[4];
		for(ClassEnum i=Class_035; i<=Class_939; i++)
		{
			if(!ClassEnabled[i])
				continue;

			GetClassName(i, buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer), "%t", buffer);
			IntToString(view_as<int>(i), num, sizeof(num));
			menu.AddItem(num, buffer, StrEqual(ClassShort[i], current) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
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
	for(int i=1; i<view_as<int>(ClassEnum); i++)
	{
		GetClassName(i, classTrans, sizeof(classTrans));
		FormatEx(targetName, sizeof(targetName), "%t", classTrans);
		if(StrContains(targetName, pattern, false) < 0)
			continue;

		class = view_as<ClassEnum>(i);
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

public Action Command_ForceWeapon(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_giveweapon <target> <id>");
		return Plugin_Handled;
	}

	static char targetName[MAX_TARGET_LENGTH];
	GetCmdArg(2, targetName, sizeof(targetName));
	int weapon = StringToInt(targetName);
	if(weapon<0 || weapon>=view_as<int>(WeaponEnum))
	{
		ReplyToCommand(client, "[SM] Invalid Weapon ID");
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
			ReplaceWeapon(targets[target], view_as<WeaponEnum>(weapon));
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Gave weapon #%d to %t", weapon, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Gave weapon #%d to %s", weapon, targetName);
	}
	return Plugin_Handled;
}

public Action Command_ForceCard(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_givekeycard <target> <id>");
		return Plugin_Handled;
	}

	static char targetName[MAX_TARGET_LENGTH];
	GetCmdArg(2, targetName, sizeof(targetName));
	int card = StringToInt(targetName);
	if(card<0 || card>=view_as<int>(KeycardEnum))
	{
		ReplyToCommand(client, "[SM] Invalid Keycard ID");
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
		{
			DropCurrentKeycard(targets[target]);
			Client[targets[target]].Keycard = view_as<KeycardEnum>(card);
		}
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Gave keycard #%d to %t", card, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Gave keycard #%d to %s", card, targetName);
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
		CookieMTFBan.Set(targets[0], "1");
		CReplyToCommand(client, "%sBanned %N from playing MTF", PREFIX, targets[0]);
	}
	else
	{
		CookieMTFBan.Set(targets[0], "0");
		CReplyToCommand(client, "%sUnbanned %N from playing MTF", PREFIX, targets[0]);
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
		return Plugin_Handled;

	if(Gamemode == Gamemode_Steals)
		ClientCommand(client, "r_screenoverlay \"\"");

	CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	if(GetClientTeam(client) == view_as<int>(TFTeam_Unassigned))
		ChangeClientTeamEx(client, TFTeam_Red);

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
			if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Micro])
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
		else if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Frag])
		//else if((damage & DMG_BLAST) && client==attacker)
		{
			GiveAchievement(Achievement_DeathGrenade, client);
		}
	}

	if(IsSCP(client))
	{
		if(Client[client].Class!=Class_0492 && Client[client].Class!=Class_3008)
		{
			switch(Client[client].Class)
			{
				case Class_076:
				{
					CreateTimer(5.0, Timer_DissolveRagdoll, clientId, TIMER_FLAG_NO_MAPCHANGE);
				}
				case Class_096:
				{
					if(Client[client].Radio == 1)
						GiveAchievement(Achievement_DeathEnrage, client);
				}
				case Class_106:
				{
					if(Client[client].Radio)
						HideAnnotation(client);
				}
			}

			GetClassName(Client[client].Class, buffer, sizeof(buffer));

			SCPKilled++;
			if(validAttacker)
			{
				if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Micro])
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

	if(validAttacker)
	{
		if(Client[attacker].SpreeFor < engineTime)
		{
			Client[attacker].Spree = 1;
		}
		else if(++Client[attacker].Spree == 5)
		{
			GiveAchievement(Achievement_KillSpree, attacker);
		}
		Client[attacker].SpreeFor = engineTime+6.0;

		if(IsSCP(attacker))
		{
			int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(wep>MaxClients && GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Micro])
				GiveAchievement(Achievement_KillMirco, attacker);
		}

		switch(Client[attacker].Class)
		{
			case Class_DBoi:
			{
				if(Client[client].Class==Class_Scientist && Client[client].Keycard>Keycard_None)
				{
					int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if(wep<=MaxClients || GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_None])
						GiveAchievement(Achievement_KillSci, attacker);
				}
			}
			case Class_Scientist:
			{
				if(Client[client].Class == Class_DBoi)
					GiveAchievement(Achievement_KillDClass, attacker);
			}
			case Class_049:
			{
				if(GetEntityFlags(client) & FL_ONGROUND)
					CreateSpecialDeath(client);

				ChangeClientTeamEx(client, view_as<TFTeam>(GetClientTeam(attacker)));
				SpawnReviveMarker(client, GetClientTeam(attacker));
			}
			case Class_076:
			{
				Client[attacker].Radio++;
				if(Client[attacker].Radio == 4)
				{
					TF2_StunPlayer(attacker, 2.0, 0.5, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
					ClientCommand(attacker, "playgamesound items/powerup_pickup_knockback.wav");

					TF2_AddCondition(attacker, TFCond_CritCola);
					TF2_RemoveWeaponSlot(attacker, TFWeaponSlot_Melee);
					SetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon", GiveWeapon(attacker, Weapon_076Rage));
					Client[attacker].Keycard = Keycard_106;
					SetEntityHealth(attacker, GetClientHealth(attacker)+250);
				}
				else if(Client[attacker].Radio < 4)
				{
					TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 0.01);
					SetEntityHealth(attacker, GetClientHealth(attacker)+50);
				}
			}
			case Class_106:
			{
				GiveAchievement(Achievement_Death106, client);
			}
			case Class_173:
			{
				GiveAchievement(Achievement_Death173, client);
				Config_GetSound(Sound_Snap, buffer, sizeof(buffer));
				EmitSoundToAll(buffer, client, SNDCHAN_BODY, SNDLEVEL_SCREAMING, _, _, _, client);
			}
			case Class_Stealer:
			{
				Config_GetSound(Sound_ItKills, buffer, sizeof(buffer));
				ClientCommand(client, "playgamesound %s", buffer);
			}
		}

		int count;
		int[] clients = new int[MaxClients];
		for(int i=1; i<=MaxClients; i++)
		{
			if(i==client || i==attacker || (IsClientInGame(i) && IsFriendly(Client[attacker].Class, Client[i].Class) && Client[attacker].CanTalkTo[i]))
				clients[count++] = i;
		}

		event.GetString("weapon", buffer, sizeof(buffer));
		ShowDeathNotice(clients, count, attackerId, clientId, assisterId, weapon, buffer, event.GetInt("damagebits"), event.GetInt("damage_flags")|TF_DEATHFLAG_DEADRINGER);
	}
	else
	{
		if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) && (GetEntityFlags(client) & FL_ONGROUND))
			CreateSpecialDeath(client);
	}

	CreateTimer(3.9, OnPlayerDeathPoster, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
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

	bool changed;
	static int holding[MAXTF2PLAYERS];
	static float pos[3], ang[3];

	float engineTime = GetEngineTime();
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon > MaxClients)
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index == WeaponIndex[Weapon_Micro])
		{
			if(!(buttons & IN_ATTACK))
			{
				Client[client].ChargeIn = 0.0;
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 99.0);
			}
			else if(!Client[client].ChargeIn)
			{
				Client[client].ChargeIn = engineTime+6.0;
				buttons &= ~IN_JUMP;
				changed = true;
			}
			else if(Client[client].ChargeIn < engineTime)
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
				buttons &= ~IN_JUMP;
				changed = true;
			}
			else
			{
				PrintKeyHintText(client, "Charge: %d", RoundToCeil((Client[client].ChargeIn-engineTime-6.0)/-0.06));
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", (engineTime-Client[client].ChargeIn)*-16.5);
				buttons &= ~IN_JUMP;
				changed = true;

				static float time[MAXTF2PLAYERS];
				if(time[client] < engineTime)
				{
					time[client] = engineTime+0.1;
					int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
					if(type != -1)
						SetEntProp(client, Prop_Data, "m_iAmmo", GetEntProp(client, Prop_Data, "m_iAmmo", _, type)-1, _, type);
				}
			}
		}
		else if(Gamemode==Gamemode_Steals && index==WeaponIndex[Weapon_None] && !holding[client] && (buttons & IN_ATTACK2))
		{
			if(Client[client].HealthPack)
			{
				TurnOffFlashlight(client);
			}
			else
			{
				TurnOnFlashlight(client);
			}
		}
	}

	if(buttons & IN_JUMP)
	{
		if(!Client[client].Sprinting)
		{
			Client[client].Sprinting = (Client[client].SprintPower>15 && (GetEntityFlags(client) & FL_ONGROUND));
			if(Client[client].Sprinting)
				SDKCall_SetSpeed(client);
		}

		if(Gamemode == Gamemode_Steals)
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

	if(holding[client])
	{
		if(!(buttons & holding[client]))
			holding[client] = 0;
	}
	else if(buttons & IN_ATTACK)	// Primary Attack (Pickups)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		{
			int attempts;
			int i = Client[client].Radio+1;
			do
			{
				if(IsValidClient(i) && !IsSpec(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
					GetClientEyeAngles(i, ang);
					SetEntProp(client, Prop_Send, "m_bDucked", true);
					SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
					TeleportEntity(client, pos, ang, TRIPLE_D);
					Client[client].Radio = i;
					break;
				}
				i++;
				attempts++;

				if(i > MaxClients)
					i = 1;
			} while(attempts < MAXTF2PLAYERS);
		}
		else if(AttemptGrabItem(client))
		{
			buttons &= ~IN_ATTACK;
			changed = true;
		}
		holding[client] = IN_ATTACK;
	}
	else if(buttons & IN_ATTACK2)	// Secondary Attack (Health Pack/Set Tele)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		{
			int attempts;
			int i = Client[client].Radio-1;
			do
			{
				if(IsValidClient(i) && !IsSpec(i))
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
					GetClientEyeAngles(i, ang);
					SetEntProp(client, Prop_Send, "m_bDucked", 1);
					SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
					TeleportEntity(client, pos, ang, TRIPLE_D);
					Client[client].Radio = i;
					break;
				}
				i--;
				attempts++;

				if(i > MaxClients)
					i = 1;
			} while(attempts < MAXTF2PLAYERS);
		}
		else if(AttemptGrabItem(client))
		{
			buttons &= ~IN_ATTACK2;
			changed = true;
		}
		else if(Client[client].Class == Class_106)
		{
			int flags = GetEntityFlags(client);
			if((flags & FL_DUCKING) || !(flags & FL_ONGROUND) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || GetEntProp(client, Prop_Send, "m_bDucked"))
			{
				PrintHintText(client, "%T", "106_create_deny", client);
			}
			else
			{
				Client[client].Radio = 1;
				PrintHintText(client, "%T", "106_create", client);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", Client[client].Pos);
				ShowAnnotation(client);
			}
		}
		else if(Gamemode!=Gamemode_Steals && !IsSCP(client) && Client[client].HealthPack)
		{
			if(Client[client].HealthPack == 4)
			{
				if(GetClientHealth(client) < 26)
					GiveAchievement(Achievement_Survive500, client);

				TF2_AddCondition(client, TFCond_MegaHeal, 0.7);
				DataPack pack;
				CreateDataTimer(1.2, Timer_Healing, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteCell(17);
				Client[client].HealthPack = 0;
			}
			else
			{
				int entity = CreateEntityByName(Client[client].HealthPack==1 ? "item_healthkit_small" : Client[client].HealthPack==3 ? "item_healthkit_full" : "item_healthkit_medium");
				if(entity > MaxClients)
				{
					GetClientAbsOrigin(client, pos);
					pos[2] += 20.0;
					DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
					SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					Client[client].HealthPack = 0;
				}
			}
		}
		holding[client] = IN_ATTACK2;
	}
	else if(buttons & IN_RELOAD)
	{
		if(Gamemode==Gamemode_Steals && Client[client].Radio>0)
		{
			buttons &= ~IN_RELOAD;
			changed = true;
			Client[client].Radio--;

			int entity = -1;
			while((entity=FindEntityByClassname(entity, "prop_dynamic")) != -1)
			{
				char name[32];
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(!StrContains(name, "scp_collectable", false))
					CreateWeaponGlow(entity, 4.0);
			}
		}

		holding[client] = IN_RELOAD;
	}
	else if(buttons & IN_ATTACK3)	// Special Attack (Radio/Self Tele)
	{
		if(AttemptGrabItem(client))
		{
			buttons &= ~IN_ATTACK3;
			changed = true;
		}
		else if(Client[client].Class == Class_106)
		{
			if(!(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2]))
			{
				PrintHintText(client, "%T", "106_create_none", client);
			}
			else if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
			{
				PrintHintText(client, "%T", "106_tele_deny", client);
			}
			else
			{
				TF2_StunPlayer(client, 10.0, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
				TF2_AddCondition(client, TFCond_MegaHeal, 10.0);
				Client[client].ChargeIn = engineTime+5.0;
				PrintRandomHintText(client);
			}
		}
		else if(Gamemode!=Gamemode_Steals && !IsSCP(client) && Client[client].Power>1 && Client[client].Radio>0)
		{
			if(++Client[client].Radio > 4)
				Client[client].Radio = 1;
		}
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

	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=10
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))))
	#else
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT)|| IsClientSpeaking(client))))
	#endif
		Client[client].IdleAt = engineTime+2.5;

	return changed ? Plugin_Changed : Plugin_Continue;
}

public void OnGameFrame()
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
									Client[client].Radio = 0;
									TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_3008));
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
								Client[client].Radio = 1;
								TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_3008Rage));
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
					SciEscaped++;
					for(int client=1; client<=MaxClients; client++)
					{
						if(IsValidClient(client) && (Client[client].Class==Class_DBoi || Client[client].Class==Class_Scientist))
							Client[client].Radio++;
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

							if(count == 1)
							{
								Config_GetSound(Sound_MTFSpawnSpooky, buffer, sizeof(buffer));
								ChangeGlobalSong(engineTime+41.0, buffer, true);
							}
							else
							{
								Config_GetSound(Sound_MTFSpawn, buffer, sizeof(buffer));
								ChangeGlobalSong(engineTime+30.0, buffer, true);
							}

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
							ChangeSong(client, time, buffer, true);
							hasSpawned = true;
						}

						if(hasSpawned)
						{
							for(int client=1; client<=MaxClients; client++)
							{
								if(IsValidClient(client) && Client[client].Class==Class_DBoi)
									ChangeSong(client, time, buffer);
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
					if(bf == null)
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

// Hook Events

// Public Events

void AssignTeam(int client)
{
	TFTeam team = Client[client].TeamTF();
	if(team != TFTeam_Blue)
		team = TFTeam_Red;

	ChangeClientTeamEx(client, team);
}

void RespawnPlayer(int client)
{
	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
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
				else if(SciEscaped < DClassEscaped)
				{
					EndRound(Team_DBoi, TFTeam_Red);
				}
				else if(SciCaptured > DClassCaptured)
				{
					EndRound(Team_DBoi, TFTeam_Red);
				}
				else if(SciCaptured < DClassCaptured)
				{
					EndRound(Team_MTF, TFTeam_Blue);
				}
				else if(!salive || SciCaptured==DClassCaptured)
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

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client, false))
			continue;

		bool team = GetClientTeam(client)==view_as<int>(TFTeam_Spectator);
		bool spec = IsSpec(client);
		bool hasRadio = (Gamemode!=Gamemode_Steals && Client[client].Power>0 && Client[client].Radio);

		static float clientPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
		for(int target=1; target<=MaxClients; target++)
		{
			if(client == target)
			{
				SetListenOverride(client, target, Listen_Default);
				continue;
			}

			if(!IsValidClient(target))
				continue;

			bool muted = IsClientMuted(client, target);
			bool blocked = muted;

			#if defined _basecomm_included
			if(!blocked && BaseComm && BaseComm_IsClientMuted(target))
				blocked = true;
			#endif

			#if defined _sourcecomms_included
			if(!blocked && SourceComms && SourceComms_GetClientMuteType(target)>bNot)
				blocked = true;
			#endif

			if(GetClientTeam(target)==view_as<int>(TFTeam_Spectator) && !IsPlayerAlive(target) && CheckCommandAccess(target, "sm_mute", ADMFLAG_CHAT))
			{
				Client[target].CanTalkTo[client] = true;
				SetListenOverride(client, target, blocked ? Listen_No : Listen_Default);
			}
			else if(team)
			{
				Client[target].CanTalkTo[client] = !muted;
				SetListenOverride(client, target, blocked ? Listen_No : Listen_Default);
			}
			else if(IsSpec(target))
			{
				Client[target].CanTalkTo[client] = (!muted && spec);
				SetListenOverride(client, target, (!blocked && spec) ? Listen_Default : Listen_No);
			}
			else if(Client[target].ComFor > engineTime)
			{
				Client[target].CanTalkTo[client] = !muted;
				SetListenOverride(client, target, blocked ? Listen_No : Listen_Default);
			}
			else
			{
				static float targetPos[3];
				if(IsSCP(target))
				{
					if(IsSCP(client))
					{
						Client[target].CanTalkTo[client] = !muted;
						SetListenOverride(client, target, blocked ? Listen_No : Listen_Yes);
						continue;
					}
					else if(Client[target].Class==Class_049 || (Client[target].Class>=Class_939 && Client[target].Class<=Class_3008))
					{
						GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
						if(GetVectorDistance(clientPos, targetPos) < 700)
						{
							Client[target].CanTalkTo[client] = !muted;
							SetListenOverride(client, target, blocked ? Listen_No : Listen_Yes);
							continue;
						}
					}

					Client[target].CanTalkTo[client] = false;
					SetListenOverride(client, target, Listen_No);
				}
				else
				{
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
					int radio = (!hasRadio || IsSCP(target) || Client[target].Power<=0) ? 0 : Client[target].Radio;
					if(GetVectorDistance(clientPos, targetPos) < Pow(400.0, 1.0+(radio*0.15)))
					{
						Client[target].CanTalkTo[client] = !muted;
						SetListenOverride(client, target, blocked ? Listen_No : Listen_Yes);
					}
					else
					{
						Client[target].CanTalkTo[client] = false;
						SetListenOverride(client, target, Listen_No);
					}
				}
			}
		}
	}
}

public Action Timer_Healing(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(!client || !IsClientInGame(client))
		return Plugin_Stop;

	SetEntityHealth(client, GetClientHealth(client)+15);

	int count = pack.ReadCell();
	if(count < 1)
		return Plugin_Stop;

	pack.Position--;
	pack.WriteCell(count-1, false);
	return Plugin_Continue;
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
				if(!StrContains(name, ClassSpawn[Class_0492], false))
					spawns[count++] = entity;

				if(count >= sizeof(spawns))
					break;
			}

			if(!count)
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
				if(!StrContains(name, ClassSpawn[0], false))
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

void TriggerShyGuy(int client, int target, float engineTime, bool full)
{
	if(full)
	{
		if(Client[target].Triggered != 4)
			return;

		Client[target].Triggered = 4;
	}
	else if(++Client[target].Triggered != 4)
	{
		return;
	}

	SetEntityHealth(client, GetClientHealth(client)+70);
	switch(Client[client].Radio)
	{
		case 1:
		{
			Client[client].Disarmer++;
			if(!full)
				Config_DoReaction(target, "trigger096");
		}
		case 2:
		{
			Client[client].Power += 2.0;
			Client[client].Disarmer++;
		}
		default:
		{
			static char buffer[PLATFORM_MAX_PATH];
			if(Client[client].Pos[0])
			{
				Config_GetSound(Sound_096, buffer, sizeof(buffer));
				StopSound(client, SNDCHAN_VOICE, buffer);
				StopSound(client, SNDCHAN_VOICE, buffer);
			}

			Client[client].Pos[0] = 0.0;
			Client[client].Power = engineTime+6.0;
			Client[client].Radio = 1;
			Client[client].Disarmer = 1;
			TF2_StunPlayer(client, 9.9, 0.9, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
			Config_GetSound(Sound_Screams, buffer, sizeof(buffer));
			EmitSoundToAll(buffer, client, SNDCHAN_VOICE, SNDLEVEL_TRAIN, _, _, _, client);
			if(!full)
				Config_DoReaction(target, "trigger096");
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
		int song = CheckCommandAccess(client, "thediscffthing", ADMFLAG_CUSTOM4) ? Music_Join2 : Music_Join;

		static char buffer[PLATFORM_MAX_PATH];
		float duration = Config_GetMusic(song, buffer, sizeof(buffer));
		ChangeSong(client, duration+GetEngineTime(), buffer);
	}

	PrintToConsole(client, " \n \nWelcome to SCP: Secret Fortress\n \nThis is a gamemode based on the SCP series and community\nPlugin is created by Batfoxkid\n ");

	DisplayCredits(client);
	return Plugin_Continue;
}

void ChangeSong(int client, float next, const char[] filepath, bool volume=false)
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
	EmitSoundToClient(client, filepath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	EmitSoundToClient(client, filepath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	if(volume)
		EmitSoundToClient(client, filepath, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
}

void ChangeGlobalSong(float next, const char[] filepath, bool volume=true)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			ChangeSong(client, next, filepath, volume);
	}
}

void DropAllWeapons(int client)
{
	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	if(Client[client].Keycard > Keycard_None)
	{
		DropKeycard(client, false, origin, angles);
		Client[client].Keycard = Keycard_None;
	}

	//Drop all weapons
	for(int i; i<3; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")!=WeaponIndex[Weapon_None])
			TF2_CreateDroppedWeapon(client, weapon, false, origin, angles);
	}

	if(Client[client].HealthPack)
	{
		int entity = CreateEntityByName(Client[client].HealthPack==3 ? "item_healthkit_full" : Client[client].HealthPack==2 ? "item_healthkit_medium" : "item_healthkit_small");
		if(entity > MaxClients)
		{
			GetClientAbsOrigin(client, origin);
			origin[2] += 20.0;
			DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
			DispatchSpawn(entity);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

void DropCurrentKeycard(int client)
{
	if(Client[client].Keycard <= Keycard_None)
		return;

	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	DropKeycard(client, true, origin, angles);
}

void DropKeycard(int client, bool swap, const float origin[3], const float angles[3])
{
	for(int i=2; i>=0; i--)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients)
		{
			if(TF2_CreateDroppedWeapon(client, weapon, swap, origin, angles, Client[client].Keycard) != INVALID_ENT_REFERENCE)
				break;
		}
	}
}

int GiveWeapon(int client, WeaponEnum weapon, bool ammo=true, int account=-3)
{
	int entity;
	switch(weapon)
	{
		/*
			Melee Weapons
		*/
		case Weapon_None:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 1, 0, "1 ; 0 ; 252 ; 0.99", _, true);
			if(entity > MaxClients)
			{
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}
		}
		case Weapon_Disarm:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "1 ; 0.3 ; 15 ; 0 ; 252 ; 0.95", _, true);
		}
		case Weapon_Axe:
		{
			entity = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 5, 6, "2 ; 1.65 ; 28 ; 0.5 ; 252 ; 0.95", _, true);
		}
		case Weapon_Hammer:
		{
			entity = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 5, 6, "2 ; 11 ; 6 ; 0.9 ; 28 ; 0.5 ; 138 ; 0.13 ; 252 ; 0.95");
		}
		case Weapon_Knife:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.2 ; 6 ; 0.8 ; 15 ; 0 ; 252 ; 0.95 ; 362 ; 1", _, true);
		}
		case Weapon_Bash:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.05 ; 6 ; 0.7 ; 28 ; 0.5 ; 252 ; 0.95");
		}
		case Weapon_Meat:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "1 ; 0.9 ; 6 ; 0.7 ; 252 ; 0.95", _, true);
		}
		case Weapon_Wrench:
		{
			entity = SpawnWeapon(client, "tf_weapon_wrench", WeaponIndex[weapon], 5, 6, "2 ; 1.5 ; 6 ; 0.9 ; 28 ; 0.5 ; 252 ; 0.95 ; 2043 ; 0", _, true);
		}
		case Weapon_Pan:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.35 ; 6 ; 0.8 ; 28 ; 0.5 ; 252 ; 0.95", _, true);
		}

		/*
			Secondary Weapons
		*/
		case Weapon_Pistol:
		{
			switch(Client[client].Class)
			{
				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Scout);
			}
			entity = SpawnWeapon(client, "tf_weapon_pistol", WeaponIndex[weapon], 5, 6, "2 ; 1.426667 ; 5 ; 1.111111 ; 96 ; 1.149425 ; 106 ; 0.33 ; 252 ; 0.95");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 24, 0);
		}
		case Weapon_Pistol2:
		{
			switch(Client[client].Class)
			{
				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Scout);
			}
			entity = SpawnWeapon(client, "tf_weapon_pistol", WeaponIndex[weapon], 5, 6, "2 ; 1.7 ; 4 ; 1.5 ; 5 ; 1.333333 ; 96 ; 1.214559 ; 106 ; 0.33 ; 252 ; 0.925", _, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 36, 0);
		}
		case Weapon_SMG:
		{
			switch(Client[client].Class)
			{
				case Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Sniper);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 5, 6, "2 ; 1.65 ; 4 ; 1.4 ; 96 ; 2.863636 ; 252 ; 0.9");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 70, 0);
		}
		case Weapon_SMG2:
		{
			switch(Client[client].Class)
			{
				case Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_DemoMan);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 10, 6, "2 ; 1.75 ; 4 ; 2 ; 6 ; 0.909091 ; 96 ; 3 ; 252 ; 0.85");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 80, 0);
		}
		case Weapon_SMG3:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					ChangeClientClass(client, TFClass_Pyro);

				case Class_MTF2:
					ChangeClientClass(client, TFClass_Heavy);

				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Soldier);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 20, 6, "2 ; 2.275 ; 4 ; 1.6 ; 5 ; 1.25 ; 96 ; 3 ; 252 ; 0.8");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, Client[client].Class>=Class_MTFS ? 120 : 160, 0);
		}
		case Weapon_SMG4:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					ChangeClientClass(client, TFClass_Pyro);

				case Class_MTF2:
					ChangeClientClass(client, TFClass_Heavy);

				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Soldier);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 30, 6, "2 ; 2.475 ; 4 ; 2 ; 6 ; 0.90909 ; 78 ; 4.6875 ; 96 ; 2 ; 252 ; 0.7");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 175, 0);
		}

		/*
			Primary Weapons
		*/
		case Weapon_Flash:
		{
			entity = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 5, 6, "5 ; 8.5 ; 15 ; 0 ; 77 ; 0.003 ; 99 ; 1.5 ; 138 ; 0 ; 252 ; 0.95 ; 303 ; -1 ; 773 ; 2 ; 787 ; 1.304348", 1, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 1);
		}
		case Weapon_Frag:
		{
			entity = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 10, 6, "2 ; 45 ; 5 ; 8.5 ; 15 ; 0 ; 77 ; 0.003 ; 99 ; 1.5 ; 138 ; 0 ; 252 ; 0.95 ; 303 ; -1 ; 773 ; 2 ; 787 ; 2.173913", 1, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 1);
		}
		case Weapon_Shotgun:
		{
			entity = SpawnWeapon(client, "tf_weapon_shotgun_primary", WeaponIndex[weapon], 10, 6, "3 ; 0.66 ; 5 ; 1.34 ; 36 ; 1.5 ; 45 ; 2 ; 77 ; 0.5 ; 252 ; 0.95", _, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 8, 4);
		}
		case Weapon_Micro:
		{
			entity = SpawnWeapon(client, "tf_weapon_flamethrower", WeaponIndex[weapon], 110, 6, "2 ; 7 ; 15 ; 0 ; 72 ; 0 ; 76 ; 5 ; 173 ; 5 ; 252 ; 0.5", _, true);
			if(entity > MaxClients)
			{
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				if(ammo)
					SetAmmo(client, entity, 1000);
			}
		}

		/*
			Other Weapons
		*/
		case Weapon_PDA1:
		{
			entity = SpawnWeapon(client, "tf_weapon_pda_engineer_build", WeaponIndex[weapon], 5, 6, "80 ; 2 ; 148 ; 3 ; 177 ; 1.3 ; 205 ; 3 ; 353 ; 1 ; 464 ; 0 ; 465 ; 0 ; 790 ; 6.66", _, true);
			SetEntProp(client, Prop_Data, "m_iAmmo", 400, 4, 3);
		}
		case Weapon_PDA2:
		{
			entity = SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", WeaponIndex[weapon], 5, 6, "205 ; 3", _, true);
		}
		case Weapon_PDA3:
		{
			entity = SpawnWeapon(client, "tf_weapon_builder", WeaponIndex[weapon], 5, 6, "205 ; 3", _, true);
			if(entity > MaxClients)
			{
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 0);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 1);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 2);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
			}
		}

		/*
			SCP Weapons
		*/
		case Weapon_049:
		{
			entity = SpawnWeapon(client, "tf_weapon_bonesaw", WeaponIndex[weapon], 80, 13, "1 ; 0.01 ; 137 ; 101 ; 138 ; 1001 ; 252 ; 0.2 ; 535 ; 0.333", false);
		}
		case Weapon_049Gun:
		{
			entity = SpawnWeapon(client, "tf_weapon_medigun", WeaponIndex[weapon], 5, 13, "7 ; 0.7 ; 9 ; 0 ; 18 ; 1 ; 252 ; 0.95 ; 292 ; 2", false);
		}
		case Weapon_0492:
		{
			entity = SpawnWeapon(client, "tf_weapon_bat", WeaponIndex[weapon], 50, 13, "1 ; 0.01 ; 5 ; 1.3 ; 28 ; 0.5 ; 137 ; 101 ; 138 ; 125 ; 252 ; 0.5 ; 535 ; 0.333", false);
		}
		case Weapon_076:
		{
			entity = SpawnWeapon(client, "tf_weapon_sword", WeaponIndex[weapon], 1, 13, "1 ; 0.01 ; 137 ; 151 ; 138 ; 151 ; 28 ; 0.5 ; 252 ; 0.8 ; 535 ; 0.333", false);
		}
		case Weapon_076Rage:
		{
			entity = SpawnWeapon(client, "tf_weapon_sword", WeaponIndex[weapon], 90, 13, "2 ; 101 ; 5 ; 1.15 ; 252 ; 0 ; 326 ; 1.67", true, true);
		}
		case Weapon_096:
		{
			entity = SpawnWeapon(client, "tf_weapon_bottle", WeaponIndex[weapon], 1, 13, "1 ; 0 ; 252 ; 0.99 ; 535 ; 0.333", false);
			if(entity > MaxClients)
			{
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}
		}
		case Weapon_096Rage:
		{
			entity = SpawnWeapon(client, "tf_weapon_sword", WeaponIndex[weapon], 100, 13, "2 ; 101 ; 6 ; 0.8 ; 28 ; 3 ; 252 ; 0 ; 326 ; 2.33", false);
		}
		case Weapon_106:
		{
			entity = SpawnWeapon(client, "tf_weapon_shovel", WeaponIndex[weapon], 60, 13, "1 ; 0.01 ; 15 ; 0 ; 66 ; 0.1 ; 137 ; 101 ; 138 ; 101 ; 252 ; 0.4 ; 535 ; 0.333", false);
		}
		case Weapon_173:
		{
			entity = SpawnWeapon(client, "tf_weapon_knife", WeaponIndex[weapon], 90, 13, "1 ; 0.01 ; 6 ; 0.01 ; 15 ; 0 ; 137 ; 11 ; 138 ; 1001 ; 252 ; 0 ; 362 ; 1 ; 535 ; 0.333", false);
		}
		case Weapon_939:
		{
			entity = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 70, 13, "1 ; 0.01 ; 28 ; 0.333 ; 137 ; 101 ; 138 ; 125 ; 252 ; 0.3 ; 535 ; 0.333", false);
		}
		case Weapon_3008:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 1, 13, "1 ; 0 ; 252 ; 0.99 ; 535 ; 0.333", false);
			if(entity > MaxClients)
			{
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}
		}
		case Weapon_3008Rage:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 100, 13, "2 ; 1.35 ; 28 ; 0.25 ; 252 ; 0.5", false);
		}
		case Weapon_Stealer:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 10, 14, "2 ; 1.5 ; 15 ; 0", false);
		}

		default:
		{
			return -1;
		}
	}

	if(entity > MaxClients)
	{
		ApplyStrangeRank(entity, weapon);
		if(account == -3)
		{
			SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_iAccountID", account);
		}
	}
	return entity;
}

void ApplyStrangeRank(int entity, WeaponEnum weapon)
{
	int kills;
	switch(WeaponRank[weapon])
	{
		case 0:
			kills = GetRandomInt(0, 9);

		case 1:
			kills = GetRandomInt(10, 24);

		case 2:
			kills = GetRandomInt(25, 44);

		case 3:
			kills = GetRandomInt(45, 69);

		case 4:
			kills = GetRandomInt(70, 99);

		case 5:
			kills = GetRandomInt(100, 134);

		case 6:
			kills = GetRandomInt(135, 174);

		case 7:
			kills = GetRandomInt(175, 224);

		case 8:
			kills = GetRandomInt(225, 274);

		case 9:
			kills = GetRandomInt(275, 349);

		case 10:
			kills = GetRandomInt(350, 499);

		case 11:
			kills = GetRandomInt(500, 749);

		case 12:
			kills = GetRandomInt(750, 998);

		case 13:
			kills = 999;

		case 14:
			kills = GetRandomInt(1000, 1499);

		case 15:
			kills = GetRandomInt(1500, 2499);

		case 16:
			kills = GetRandomInt(2500, 4999);

		case 17:
			kills = GetRandomInt(5000, 7499);

		case 18:
			kills = GetRandomInt(7500, 7615);

		case 19:
			kills = GetRandomInt(7616, 8499);

		case 20:
			kills = GetRandomInt(8500, 9999);

		default:
			return;
	}

	TF2Attrib_SetByDefIndex(entity, 214, view_as<float>(kills));
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
				ShowSyncHudText(client, HudIntro, "%t", "end_screen_ikea", buffer, DClassEscaped, DClassMax);
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
				ShowSyncHudText(client, HudIntro, "%t", "end_screen_steals", buffer, count, SciMax+DClassMax, DClassEscaped, SCPMax, SCPKilled);
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
				ShowSyncHudText(client, HudIntro, "%t", "end_screen", buffer, DClassEscaped, DClassMax, SciEscaped, SciMax, SCPKilled, SCPMax);
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
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
		ShowClassInfo(client);

	return Plugin_Continue;
}

void ShowClassInfo(int client, bool help=false)
{
	SetGlobalTransTarget(client);

	bool found;
	char buffer[32];
	GetClassName(Client[client].Class, buffer, sizeof(buffer));

	SetHudTextParamsEx(-1.0, 0.3, help ? 20.0 : 10.0, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudExtra, "%t", "you_are", buffer);

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

	SetHudTextParamsEx(-1.0, 0.5, 10.0, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 1, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudIntro, "%t", buffer);
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

	int result;
	if(Client[client].Access(Access_Exit))
	{
		result = TF2_GetPlayerClass(client)==TFClass_Scout ? -1 : 0;
	}
	else
	{
		result = TF2_GetPlayerClass(client)==TFClass_Scout ? -2 : -1;
	}
	TF2Attrib_SetByDefIndex(client, 68, float(result));
}

bool AttemptGrabItem(int client)
{
	if(IsSpec(client) || (Client[client].Disarmer && !IsSCP(client)))
		return false;

	int entity = GetClientPointVisible(client);
	if(entity <= MaxClients)
		return false;

	//SDKCall(SDKTryPickup, client);

	char name[64];
	GetEntityClassname(entity, name, sizeof(name));
	if(StrEqual(name, "tf_dropped_weapon"))
	{
		if(IsSCP(client))
		{
			if(Client[client].Class == Class_106)
				RemoveEntity(entity);

			return true;
		}

		PickupWeapon(client, entity);
		return true;
	}
	else if(!StrContains(name, "prop_dynamic"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_keycard_", false))
		{
			if(IsSCP(client))
				return true;

			char buffers[16][4];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));
			int card = StringToInt(buffers[2]);
			if(card>0 && card<view_as<int>(KeycardEnum))
			{
				DropCurrentKeycard(client);
				Client[client].Keycard = view_as<KeycardEnum>(card);
				AcceptEntityInput(entity, "KillHierarchy");
				return true;
			}
			return true;
		}
		else if(!StrContains(name, "scp_healthkit", false))
		{
			if(IsSCP(client))
			{
				if(Client[client].Class == Class_106)
					AcceptEntityInput(entity, "KillHierarchy");

				return true;
			}

			if(Client[client].HealthPack)
				return true;

			int type = StringToInt(name[14]);
			if(type < 1)
				type = 2;

			Client[client].HealthPack = type;
			AcceptEntityInput(entity, "KillHierarchy");
			return true;
		}
		else if(!StrContains(name, "scp_weapon", false))
		{
			if(IsSCP(client))
			{
				if(Client[client].Class == Class_106)
					AcceptEntityInput(entity, "KillHierarchy");

				return true;
			}

			AcceptEntityInput(entity, "KillHierarchy");
			char buffers[16][4];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));
			int index = StringToInt(buffers[2]);
			if(index)
			{
				WeaponEnum wep = Weapon_Axe;
				for(; wep<Weapon_PDA1; wep++)
				{
					if(index == WeaponIndex[wep])
						break;
				}

				if(wep != Weapon_PDA1)
				{
					ReplaceWeapon(client, wep);
					return true;
				}
			}

			ReplaceWeapon(client, Weapon_Pistol);
			return true;
		}
		else if(!StrContains(name, "scp_trigger", false))
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
		else if(!StrContains(name, "scp_collectable", false))
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
	else if(StrEqual(name, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
	}
	return false;
}

void PickupWeapon(int client, int entity)
{
	{
		static char name[48];
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(name[0])
		{
			int card = view_as<int>(Keycard_Janitor);
			for(; card<sizeof(KeycardNames); card++)
			{
				if(StrEqual(name, KeycardNames[card], false))
				{
					if(card == view_as<int>(Keycard_O5))
						GiveAchievement(Achievement_FindO5, client);

					DropCurrentKeycard(client);
					Client[client].Keycard = view_as<KeycardEnum>(card);
					RemoveEntity(entity);
					return;
				}
			}
		}
	}

	int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	WeaponEnum wep = Weapon_Axe;
	for(; wep<Weapon_PDA1; wep++)
	{
		if(index == WeaponIndex[wep])
		{
			if(Client[client].Class == Class_DBoi)
				GiveAchievement(Achievement_FindGun, client);

			if(ReplaceWeapon(client, wep, entity))
			{
				SetVariantString("randomnum:100");
				AcceptEntityInput(client, "AddContext");
				SetVariantString("TLK_MVM_LOOT_COMMON");
				AcceptEntityInput(client, "SpeakResponseConcept");
				AcceptEntityInput(client, "ClearContext");
			}

			RemoveEntity(entity);
			CreateTimer(0.1, Timer_UpdateClientHud, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
	}
}

bool ReplaceWeapon(int client, WeaponEnum wep, int entity=0, int index=0)
{
	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);

	//Check if client already has weapon in given slot, remove and create dropped weapon if so
	bool newWeapon;
	int slot = wep>Weapon_Disarm ? wep<Weapon_Flash ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary : TFWeaponSlot_Melee;
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon > MaxClients)
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(WeaponIndex[wep] == index)
		{
			SpawnPickup(client, "item_ammopack_small");
			return newWeapon;
		}
		else if(index != WeaponIndex[Weapon_None])
		{
			GetClientEyePosition(client, origin);
			GetClientEyeAngles(client, angles);
			TF2_CreateDroppedWeapon(client, weapon, true, origin, angles);
		}
		else
		{
			newWeapon = true;
		}

		TF2_RemoveWeaponSlot(client, slot);
	}

	if(entity > MaxClients)
	{
		weapon = GiveWeapon(client, wep, false, GetEntProp(entity, Prop_Send, "m_iAccountID"));
		if(weapon > MaxClients)
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

			//Restore ammo, energy etc from picked up weapon
			SDKCall_InitPickup(entity, client, weapon);

			//If max ammo not calculated yet (-1), do it now
			if(TF2_GetWeaponAmmo(client, weapon) < 0)
			{
				TF2_SetWeaponAmmo(client, weapon, 0);
				TF2_RefillWeaponAmmo(client, weapon);
			}
		}
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
	}
	return newWeapon;
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

void ShowAnnotation(int client)
{
	Event event = CreateEvent("show_annotation");
	if(event != INVALID_HANDLE)
	{
		event.SetFloat("worldPosX", Client[client].Pos[0]);
		event.SetFloat("worldPosY", Client[client].Pos[1]);
		event.SetFloat("worldPosZ", Client[client].Pos[2]);
		event.SetFloat("lifetime", 999.0);
		event.SetInt("id", 9999-client);

		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "%T", "106_portal", client);
		event.SetString("text", buffer);

		event.SetString("play_sound", "vo/null.wav");
		event.SetInt("visibilityBitfield", (1<<client));
		event.Fire();

		Client[client].Radio = 1;
	}
}

void HideAnnotation(int client)
{
	Event event = CreateEvent("hide_annotation");
	if(event != INVALID_HANDLE)
	{
		event.SetInt("id", 9999-client);
		event.Fire();

		Client[client].Radio = 0;
	}
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

void TurnOnGlow(int client, const char[] color, int brightness, float distance)
{
	int entity = CreateEntityByName("light_dynamic");
	if(!IsValidEntity(entity))
		return; // It shouldn't.

	DispatchKeyValue(entity, "_light", color);
	SetEntProp(entity, Prop_Send, "m_Exponent", brightness);
	SetEntPropFloat(entity, Prop_Send, "m_Radius", distance);
	DispatchSpawn(entity);

	static float pos[3];
	GetClientEyePosition(client, pos);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	Client[client].ReviveIndex = EntIndexToEntRef(entity);
}

void TurnOffGlow(int client)
{
	if(Gamemode!=Gamemode_Steals || !Client[client].ReviveIndex)
		return;

	int entity = EntRefToEntIndex(Client[client].ReviveIndex);
	if(entity>MaxClients && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "TurnOff");
		CreateTimer(0.1, Timer_RemoveEntity, Client[client].ReviveIndex, TIMER_FLAG_NO_MAPCHANGE);
	}
	Client[client].ReviveIndex = 0;
}

void TurnOnFlashlight(int client)
{
	if(Client[client].HealthPack)
		TurnOffFlashlight(client);

	// Spawn the light that only everyone else will see.
	int ent = CreateEntityByName("point_spotlight");
	if(ent == -1)
		return;

	static float pos[3];
	GetClientEyePosition(client, pos);
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(ent, "spotlightlength", "1024");
	DispatchKeyValue(ent, "spotlightwidth", "512");
	DispatchKeyValue(ent, "rendercolor", "255 255 255");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client);
	AcceptEntityInput(ent, "LightOn");

	Client[client].HealthPack = EntIndexToEntRef(ent);
}

void TurnOffFlashlight(int client)
{
	if(Gamemode!=Gamemode_Steals || !Client[client].HealthPack)
		return;

	int entity = EntRefToEntIndex(Client[client].HealthPack);
	if(entity>MaxClients && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "LightOff");
		CreateTimer(0.1, Timer_RemoveEntity, Client[client].HealthPack, TIMER_FLAG_NO_MAPCHANGE);
	}
	Client[client].HealthPack = 0;
}

int CreateWeaponGlow(int iEntity, float flDuration)
{
	int iGlow = CreateEntityByName("tf_taunt_prop");
	if (IsValidEntity(iGlow) && DispatchSpawn(iGlow))
	{
		int index = -1;
		if(HasEntProp(iEntity, Prop_Send, "m_iWorldModelIndex"))
		{
			index = GetEntProp(iEntity, Prop_Send, "m_iWorldModelIndex");
		}
		else
		{
			index = GetEntProp(iEntity, Prop_Send, "m_nModelIndex");
		}

		if(index < 0)
			return -1;

		static char model[PLATFORM_MAX_PATH];
		ModelIndexToString(index, model, sizeof(model));
		SetEntityModel(iGlow, model);
		SetEntProp(iGlow, Prop_Send, "m_nSkin", 0);
		
		SetEntPropEnt(iGlow, Prop_Data, "m_hEffectEntity", iEntity);
		SetEntProp(iGlow, Prop_Send, "m_bGlowEnabled", true);
		
		int iEffects = GetEntProp(iGlow, Prop_Send, "m_fEffects");
		SetEntProp(iGlow, Prop_Send, "m_fEffects", iEffects | EF_BONEMERGE | EF_NOSHADOW | EF_NORECEIVESHADOW);
		
		SetVariantString("!activator");
		AcceptEntityInput(iGlow, "SetParent", iEntity);
		
		CreateTimer(flDuration, Timer_RemoveEntity, EntIndexToEntRef(iGlow), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return iGlow;
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

public Action CH_PassFilter(int ent1, int ent2, bool &result)
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
#endif

// Revive Marker Events

public void OnRevive(Event event, const char[] name, bool dontBroadcast)
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

	SetEntProp(entity, Prop_Send, "m_bDucked", true);
	SetEntityFlags(entity, GetEntityFlags(entity)|FL_DUCKING);

	static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
}

public bool SpawnReviveMarker(int client, int team)
{
	int reviveMarker = CreateEntityByName("entity_revive_marker");
	if(reviveMarker == -1)
		return false;

	SetEntPropEnt(reviveMarker, Prop_Send, "m_hOwnerEntity", client); // client index 
	SetEntPropEnt(reviveMarker, Prop_Send, "m_hOwner", client); // client index 
	SetEntProp(reviveMarker, Prop_Send, "m_nSolidType", 2); 
	SetEntProp(reviveMarker, Prop_Send, "m_usSolidFlags", 8); 
	SetEntProp(reviveMarker, Prop_Send, "m_fEffects", 16); 
	SetEntProp(reviveMarker, Prop_Send, "m_iTeamNum", team); // client team 
	SetEntProp(reviveMarker, Prop_Send, "m_CollisionGroup", 1); 
	SetEntProp(reviveMarker, Prop_Send, "m_bSimulatedEveryTick", true);
	SetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_nForcedSkin")+4, reviveMarker);
	SetEntProp(reviveMarker, Prop_Send, "m_nBody", view_as<int>(TFClass_Scout)-1); // character hologram that is shown
	SetEntProp(reviveMarker, Prop_Send, "m_nSequence", 1); 
	SetEntPropFloat(reviveMarker, Prop_Send, "m_flPlaybackRate", 1.0);
	SetEntProp(reviveMarker, Prop_Data, "m_iInitialTeamNum", team);
	SDKHook(reviveMarker, SDKHook_SetTransmit, NoTransmit);

	DispatchSpawn(reviveMarker);
	Client[client].ReviveIndex = EntIndexToEntRef(reviveMarker);
	Client[client].ReviveMoveAt = GetEngineTime()+0.05;
	Client[client].ReviveGoneAt = Client[client].ReviveMoveAt+14.95;

	SDKHook(client, SDKHook_PreThink, MarkerThink);
	return true;
}

public void MarkerThink(int client)
{
	if(Client[client].ReviveMoveAt < GetEngineTime())
	{
		Client[client].ReviveMoveAt = FAR_FUTURE;
		int entity = EntRefToEntIndex(Client[client].ReviveIndex);
		if(!IsValidMarker(entity)) // Oh fiddlesticks, what now..
		{
			SDKUnhook(client, SDKHook_PreThink, MarkerThink);
			if(GetClientTeam(client) == view_as<int>(TFTeam_Unassigned))
				ChangeClientTeamEx(client, TFTeam_Red);

			return;
		}

		// get position to teleport the Marker to
		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
		SDKHook(entity, SDKHook_SetTransmit, MarkerTransmit);
		SDKUnhook(entity, SDKHook_SetTransmit, NoTransmit);
	}
	else if(!Enabled || Client[client].ReviveGoneAt<GetEngineTime())
	{
		SDKUnhook(client, SDKHook_PreThink, MarkerThink);
		if(!IsPlayerAlive(client) && GetClientTeam(client)==view_as<int>(TFTeam_Unassigned))
			ChangeClientTeamEx(client, TFTeam_Red);

		int entity = EntRefToEntIndex(Client[client].ReviveIndex);
		if(!IsValidMarker(entity))
			return;

		AcceptEntityInput(entity, "Kill");
		entity = INVALID_ENT_REFERENCE;
	}
}

public Action NoTransmit(int entity, int target)
{
	return Plugin_Handled;
}

public Action MarkerTransmit(int entity, int target)
{
	return (IsValidClient(target) && Client[target].Class!=Class_049) ? Plugin_Handled : Plugin_Continue;
}

bool IsValidMarker(int marker)
{
	if(!IsValidEntity(marker))
		return false;
	
	static char buffer[64];
	GetEntityClassname(marker, buffer, sizeof(buffer));
	return StrEqual(buffer, "entity_revive_marker", false);
}

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
	DispatchKeyValue(entity, "model", ClassModel[Client[client].Class]);
	DispatchKeyValue(entity, "DefaultAnim", FireDeath[special]);	
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

	if(Client[target].Class == Class_096)
	{
		if(Client[target].Radio==2 && Client[client].Triggered>3)
			return Plugin_Continue;

		return Plugin_Stop;
	}
	else if(Client[target].Class==Class_3008 && Client[target].Radio)
	{
		return Plugin_Continue;
	}
	else if(Client[target].Class < Class_939)
	{
		return Plugin_Stop;
	}

	float time = Client[client].IdleAt-GetEngineTime();
	if(time > 0)
	{
		static float clientPos[3], targetPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
		if(GetVectorDistance(clientPos, targetPos) < (700*time/2.5))
			return Plugin_Continue;
	}
	return Plugin_Stop;
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

	SetHudTextParamsEx(-1.0, 0.5, override ? 20.0 : 30.0, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 1, 5.0, 1.0, 1.0);
	FormatEx(buffer, sizeof(buffer), "train_%s", ClassShort[Client[client].Class]);
	ShowSyncHudText(client, HudIntro, "%t", buffer);
	return true;
}

// Target Filters

public bool Target_Random(const char[] pattern, ArrayList clients)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(GetRandomInt(0, 1))
			clients.Push(client);
	}
	return true;
}

public bool Target_SCP(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(IsSCP(client))
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Chaos(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_Chaos)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_MTF(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class>=Class_MTF && Client[client].Class<=Class_MTFE)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Ghost(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_DBoi(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_DBoi)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Scientist(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_Scientist)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Guard(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_Guard)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

#file "SCP: Secret Fortress"
