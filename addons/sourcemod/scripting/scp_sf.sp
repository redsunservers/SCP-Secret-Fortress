#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <tf2items>
#include <morecolors>
#include <tf2attributes>
#include <dhooks>
#include <SteamWorks>
#undef REQUIRE_PLUGIN
//#tryinclude <goomba>
#tryinclude <voiceannounce_ex>
#tryinclude <devzones>
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#define REQUIRE_PLUGIN

#pragma newdecls required

void DisplayCredits(int client)
{
	PrintToConsole(client, "Useful Stocks | sarysa | forums.alliedmods.net/showthread.php?t=309245");
	PrintToConsole(client, "Friendly Fire Fixes | Chdata, Kit O' Rifty | github.com/Chdata/TF2-Fixed-Friendly-Fire");
	PrintToConsole(client, "SDK/DHooks Functions | Mikusch | github.com/Mikusch/fortress-royale");
	PrintToConsole(client, "Medi-Gun Hooks | naydef | forums.alliedmods.net/showthread.php?t=311520");
	PrintToConsole(client, "ChangeTeamEx | Benoist3012 | forums.alliedmods.net/showthread.php?t=314271");
	PrintToConsole(client, "Client Eye Angles | sarysa | forums.alliedmods.net/showthread.php?t=309245");
	PrintToConsole(client, "Fire Death Animation | 404UNF, Rowedahelicon | forums.alliedmods.net/showthread.php?t=255753");
	PrintToConsole(client, "Revive Markers | SHADoW NiNE TR3S, sarysa | forums.alliedmods.net/showthread.php?t=248320");

	PrintToConsole(client, "Chaos, SCP-049-2 | DoctorKrazy | forums.alliedmods.net/member.php?u=288676");
	PrintToConsole(client, "MTF, SCP-049, SCP-096 | JuegosPablo | forums.alliedmods.net/showthread.php?t=308656");
	PrintToConsole(client, "SCP-173 | RavensBro | forums.alliedmods.net/showthread.php?t=203464");
	PrintToConsole(client, "SCP-106 | Spyer | forums.alliedmods.net/member.php?u=272596");

	PrintToConsole(client, "Cosmic Inspiration | Marxvee | forums.alliedmods.net/member.php?u=289257");
	PrintToConsole(client, "Is Cute | Artvin | steamcommunity.com/id/laz_boyx");
}

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"0"
#define STABLE_REVISION	"0"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define FAR_FUTURE		100000000.0
#define MAX_SOUND_LENGTH	80
#define MAX_MODEL_LENGTH	128
#define MAX_MATERIAL_LENGTH	128
#define MAX_ENTITY_LENGTH	48
#define MAX_EFFECT_LENGTH	48
#define MAX_ATTACHMENT_LENGTH	48
#define MAX_ICON_LENGTH		48
#define HEX_OR_DEC_LENGTH	12
#define MAX_ATTRIBUTE_LENGTH	256
#define MAX_CONDITION_LENGTH	256
#define MAX_CLASSNAME_LENGTH	64
#define MAX_BOSSNAME_LENGTH	64
#define MAX_ABILITY_LENGTH	64
#define MAX_PLUGIN_LENGTH	64
#define MAX_MENUITEM_LENGTH	48
#define MAX_TITLE_LENGTH	192
#define MAXTF2PLAYERS		36
#define MAXENTITIES		2048
#define VOID_ARG		-1

// I'm cheating yayy
#define IsSCP(%1)	(Client[%1].Class>=Class_049)
#define IsSpec(%1)	(Client[%1].Class==Class_Spec || !IsPlayerAlive(%1) || TF2_IsPlayerInCondition(%1, TFCond_HalloweenGhostMode))

#define MAXANGLEPITCH	45.0
#define MAXANGLEYAW	90.0
#define MAXTIME		898

#define PREFIX		"{red}[SCP]{default} "

static const float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };
static const float TRIPLE_D[3] = { 0.0, 0.0, 0.0 };

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

static const char MusicList[][] =
{
	"scpsl/music/mainmenu.mp3",		// Main Menu Theme (Reserved for join sound)
	"scpsl/music/wegottarun.mp3",		// We Gotta Run (Reserved for Alpha Warhead)
	"scpsl/music/melancholy.mp3",		// Melancholy
	"scpsl/music/unexplainedbehaviors.mp3",	// Unexplained Behaviors
	"scpsl/music/doctorlab.mp3",		// Doctor Lab
	"scpsl/music/massivelabyrinth.mp3",	// Massive Labyrinth
	"scpsl/music/forgetaboutyourfears.mp3"	// Forget About Your Fears
};

static const char MusicNames[][] =
{
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}Main Menu Theme",
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}We Gotta Run",
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}Melancholy",
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}Unexplained Behaviors",
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}Doctor Lab",
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}Massive Labyrinth",
	"{blue}Jacek \"Burnert\" Rogal {default}- {orange}Forget About Your Fears"
};

static const float MusicTimes[] =
{
	106.0,	// Main Menu Theme
	114.0,	// We Gotta Run
	93.0,	// Melancholy
	49.0,	// Unexplained Behaviors
	154.0,	// Doctor Lab
	124.5,	// Massive Labyrinth
	172.0	// Forget About Your Fears
};

enum
{
	Sound_096 = 0,
	Sound_Screams,
	Sound_Snap,
	Sound_MTFSpawn,
	Sound_ChaosSpawn
}

static const char SoundList[][] =
{
	//"scpsl/096/effect_loop.wav",			// SCP-096 Passive
	"freak_fortress_2/scp096/bgm.mp3",		// SCP-096 Passive
	"freak_fortress_2/scp096/fullrage.mp3",		// SCP-096 Rage
	"freak_fortress_2/scp173/scp173_kill_2.mp3",	// SCP-173 Kill
	"freak_fortress_2/scp173/scp173_mtf_spawn.mp3",	// MTF Spawn
	"freak_fortress_2/scp-049/red_backup1.mp3"	// Chaos Spawn
};

enum // Collision_Group_t in const.h - m_CollisionGroup
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER,		// Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,		// Collides with everything except interactive debris or debris	Can be hit by bullets, explosions, players, projectiles, melee
	COLLISION_GROUP_PLAYER,			// Can be hit by bullets, explosions, players, projectiles, melee
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,	// For HL2, same as Collision_Group_Player, for TF2, this filters out other players and CBaseObjects

	COLLISION_GROUP_NPC,		// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,	// for any entity inside a vehicle	Can be hit by explosions. Melee unknown.
	COLLISION_GROUP_WEAPON,		// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,	// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,	// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,	// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code) // Can be hit by bullets, explosions, projectiles, melee

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED = 19,	// Used for NPCs in scripts that should not collide with each other.

	LAST_SHARED_COLLISION_GROUP
};

// entity flags, CBaseEntity::m_iEFlags
enum
{
	EFL_KILLME	=				(1<<0),	// This entity is marked for death -- This allows the game to actually delete ents at a safe time
	EFL_DORMANT	=				(1<<1),	// Entity is dormant, no updates to client
	EFL_NOCLIP_ACTIVE =			(1<<2),	// Lets us know when the noclip command is active.
	EFL_SETTING_UP_BONES =		(1<<3),	// Set while a model is setting up its bones.
	EFL_KEEP_ON_RECREATE_ENTITIES = (1<<4), // This is a special entity that should not be deleted when we restart entities only

	EFL_HAS_PLAYER_CHILD=		(1<<4),	// One of the child entities is a player.

	EFL_DIRTY_SHADOWUPDATE =	(1<<5),	// Client only- need shadow manager to update the shadow...
	EFL_NOTIFY =				(1<<6),	// Another entity is watching events on this entity (used by teleport)

	// The default behavior in ShouldTransmit is to not send an entity if it doesn't
	// have a model. Certain entities want to be sent anyway because all the drawing logic
	// is in the client DLL. They can set this flag and the engine will transmit them even
	// if they don't have a model.
	EFL_FORCE_CHECK_TRANSMIT =	(1<<7),

	EFL_BOT_FROZEN =			(1<<8),	// This is set on bots that are frozen.
	EFL_SERVER_ONLY =			(1<<9),	// Non-networked entity.
	EFL_NO_AUTO_EDICT_ATTACH =	(1<<10), // Don't attach the edict; we're doing it explicitly
	
	// Some dirty bits with respect to abs computations
	EFL_DIRTY_ABSTRANSFORM =	(1<<11),
	EFL_DIRTY_ABSVELOCITY =		(1<<12),
	EFL_DIRTY_ABSANGVELOCITY =	(1<<13),
	EFL_DIRTY_SURROUNDING_COLLISION_BOUNDS	= (1<<14),
	EFL_DIRTY_SPATIAL_PARTITION = (1<<15),
//	UNUSED						= (1<<16),

	EFL_IN_SKYBOX =				(1<<17),	// This is set if the entity detects that it's in the skybox.
											// This forces it to pass the "in PVS" for transmission.
	EFL_USE_PARTITION_WHEN_NOT_SOLID = (1<<18),	// Entities with this flag set show up in the partition even when not solid
	EFL_TOUCHING_FLUID =		(1<<19),	// Used to determine if an entity is floating

	// FIXME: Not really sure where I should add this...
	EFL_IS_BEING_LIFTED_BY_BARNACLE = (1<<20),
	EFL_NO_ROTORWASH_PUSH =		(1<<21),		// I shouldn't be pushed by the rotorwash
	EFL_NO_THINK_FUNCTION =		(1<<22),
	EFL_NO_GAME_PHYSICS_SIMULATION = (1<<23),

	EFL_CHECK_UNTOUCH =			(1<<24),
	EFL_DONTBLOCKLOS =			(1<<25),		// I shouldn't block NPC line-of-sight
	EFL_DONTWALKON =			(1<<26),		// NPC;s should not walk on this entity
	EFL_NO_DISSOLVE =			(1<<27),		// These guys shouldn't dissolve
	EFL_NO_MEGAPHYSCANNON_RAGDOLL = (1<<28),	// Mega physcannon can't ragdoll these guys.
	EFL_NO_WATER_VELOCITY_CHANGE  =	(1<<29),	// Don't adjust this entity's velocity when transitioning into water
	EFL_NO_PHYSCANNON_INTERACTION =	(1<<30),	// Physcannon can't pick these up or punt them
	EFL_NO_DAMAGE_FORCES =		(1<<31),	// Doesn't accept forces from physics damage
};

static const char Characters[] = "abcdefghijklmnopqrstuvwxyzABDEFGHIJKLMNOQRTUVWXYZ~`1234567890@#$%^&*(){}:[]|¶�;<>.,?/\\";

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

	Class_049,
	Class_0492,
	Class_079,
	Class_096,
	Class_106,
	Class_173,
	Class_939,
	Class_9392,
	Class_3008
}

static const char ClassColor[][] =
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

	"darkred",
	"red",
	"darkred",
	"darkred",
	"darkred",
	"darkred",
	"darkred",
	"darkred",
	"darkred"
};

static const int ClassColors[][] =
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

	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 }
};

static const char ClassSpawn[][] =
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

	"scp_spawn_049",
	"scp_spawn_p",
	"",
	"scp_spawn_096",
	"scp_spawn_106",
	"scp_spawn_173",
	"scp_spawn_939",
	"scp_spawn_939",
	"scp_spawn_p"
};

static const char ClassModel[][] =
{
	"models/props_halloween/ghost_no_hat.mdl",	// Spec

	"models/jailbreak/scout/jail_scout_v2.mdl",	// DBoi
	"models/freak_fortress_2/scp-049/chaos.mdl",	// Chaos

	"models/player/medic.mdl",					// Sci
	"models/player/sniper.mdl",					// Guard
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF 1
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF 2
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF S
	"models/freak_fortress_2/scpmtf/mtf_guard_playerv4.mdl",	// MTF 3

	"models/freak_fortress_2/scp-049/scp049.mdl",		// 049
	"models/freak_fortress_2/scp-049/zombie049.mdl",	// 049-2
	"models/player/engineer.mdl", 				// 079
	"models/freak_fortress_2/096/scp096.mdl",		// 096
	"models/freak_fortress_2/106_spyper/106.mdl",		// 106
	"models/freak_fortress_2/scp_173/scp_173new.mdl",	// 173
	"models/player/pyro.mdl",				// 939-89
	"models/player/pyro.mdl",				// 939-53
	"models/freak_fortress_2/scp-049/zombie049.mdl",	// 3008-2
};

static const TFClassType ClassClass[] =
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

	TFClass_Medic,		// 049
	TFClass_Scout,		// 049-2
	TFClass_Engineer, 	// 079
	TFClass_DemoMan,	// 096
	TFClass_Soldier,	// 106
	TFClass_Heavy,		// 173
	TFClass_Pyro,		// 939-89
	TFClass_Pyro,		// 939-53
	TFClass_Sniper		// 3008-2
};

static const TFClassType ClassClassModel[] =
{
	TFClass_Pyro,		// Spec

	TFClass_Scout,		// DBoi
	TFClass_Sniper,		// Chaos

	TFClass_Medic,		// Sci
	TFClass_Sniper,		// Guard
	TFClass_Sniper,		// MTF 1
	TFClass_Sniper,		// MTF 2
	TFClass_Sniper,		// MTF S
	TFClass_Sniper,		// MTF 3

	TFClass_Medic,		// 049
	TFClass_Sniper,		// 049-2
	TFClass_Pyro, 		// 079
	TFClass_Spy,		// 096
	TFClass_Scout,		// 106
	TFClass_Pyro,		// 173
	TFClass_Pyro,		// 939-89
	TFClass_Pyro,		// 939-53
	TFClass_Sniper,		// 3008-2
};

static const char FireDeath[][] =
{
	"primary_death_burning",
	"PRIMARY_death_burning"
};

static const float FireDeathTimes[] =
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

static const int TeamColors[][] =
{
	{ 255, 200, 200, 255 },
	{ 255, 165, 0, 255 },
	{ 0, 0, 139, 255 },
	{ 139, 0, 0, 255 }
};

enum KeycardEnum
{
	Keycard_None = 0,

	Keycard_Janitor,	// 1
	Keycard_Scientist,

	Keycard_Zone,		// 3
	Keycard_Research,

	Keycard_Guard,		// 5
	Keycard_MTF,
	Keycard_MTF2,
	Keycard_MTF3,

	Keycard_Engineer,	// 9
	Keycard_Facility,

	Keycard_Chaos,		// 11
	Keycard_O5
}

static const KeycardEnum KeycardPaths[][] =
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

	{ Keycard_None, Keycard_MTF3, Keycard_O5 },
	{ Keycard_Engineer, Keycard_None, Keycard_None }
};

static const char KeycardModel[][] =
{
	"models/props/sl/keycard.mdl",

	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",

	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",

	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",

	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",

	"models/props/sl/keycard.mdl",
	"models/props/sl/keycard.mdl",
};

static const char KeycardNames[][] =
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
	Weapon_Disarm,

	Weapon_Pistol,
	Weapon_SMG,		// Guard
	Weapon_SMG2,		// MTF
	Weapon_SMG3,		// MTF2
	Weapon_SMG4,		// Chaos
	Weapon_SMG5,		// MTF3

	Weapon_Flash,
	Weapon_Frag,

	Weapon_Keycard,

	Weapon_049,
	Weapon_049Gun,
	Weapon_0492,

	Weapon_096,
	Weapon_096Rage,

	Weapon_106,
	Weapon_173,
	Weapon_939,

	Weapon_3008,
	Weapon_3008Rage,
}

static const int WeaponIndex[] =
{
	5,
	954,

	209,
	751,
	1150,
	425,
	415,
	1153,

	1151,
	308,

	133,

	173,
	35,
	572,

	195,
	154,

	939,
	195,
	326,

	195,
	195
};

enum GamemodeEnum
{
	Gamemode_None,	// SCP dedicated map
	Gamemode_Ikea,	// SCP-3008-2 map
	Gamemode_Arena,	// KotH but enable arena logic
	Gamemode_Koth,	// Control Points are the objectives
	Gamemode_Ctf	// Flags are the objectives
}

bool Ready = false;
bool Enabled = false;
bool NoMusic = false;
bool Vaex = false;		// VoiceAnnounceEx
bool SourceComms = false;	// SourceComms++
bool BaseComm = false;		// BaseComm

Handle SDKTeamAddPlayer;
Handle SDKTeamRemovePlayer;
Handle SDKEquipWearable;
Handle SDKCreateWeapon;
Handle SDKEquippedWearable;
Handle SDKInitPickup;
Handle SDKInitWeapon;
Handle SDKTryPickup;
Handle DHAllowedToHealTarget;
Handle DHSetWinningTeam;
Handle DHRoundRespawn;
//Handle DHLagCompensation;
Handle DHForceRespawn;
//Handle DoorTimer = INVALID_HANDLE;

GlobalForward GFOnEscape;

GamemodeEnum Gamemode = Gamemode_None;

float CanTouchAt[MAXENTITIES+1];

int DClassEscaped;
int DClassMax;
int SciEscaped;
int SciMax;
int SCPKilled;
int SCPMax;

enum struct ClientEnum
{
	ClassEnum Class;
	TeamEnum Team;
	KeycardEnum Keycard;
	int HealthPack;
	int Radio;
	int Disarmer;
	float Power;
	bool DisableSpeed;
	float IdleAt;
	float ComFor;
	float IsCapping;
	float InvisFor;
	float Respawning;
	float Pos[3];
	float ChatIn;
	float HudIn;
	float TeleIn;
	float Cooldown;
	bool CanTalkTo[MAXTF2PLAYERS];

	// Revive Markers
	int ReviveIndex;
	float ReviveMoveAt;
	float ReviveGoneAt;

	// Music
	float NextSongAt;
	int CurrentSong;

	TFTeam TeamTF()
	{
		if(this.Class < Class_DBoi)
			return TFTeam_Spectator;

		if(this.Class < Class_Scientist)
			return TFTeam_Red;

		return this.Class<Class_049 ? TFTeam_Blue : TFTeam_Unassigned;
	}

	ClassEnum Setup(TFTeam team, bool bot)
	{
		if(team == TFTeam_Blue)
		{
			if(Gamemode == Gamemode_Ikea)
			{
				if(!bot && IsClassTaken(Class_DBoi) && !GetRandomInt(0, 3))
				{
					this.Class = Class_3008;
					return Class_3008;
				}

				this.Class = Class_DBoi;
				return Class_DBoi;
			}

			if(IsClassTaken(Class_Scientist) && !GetRandomInt(0, 2))
			{
				this.Class = Class_Guard;
				return Class_Guard;
			}

			this.Class = Class_Scientist;
			return Class_Scientist;
		}

		if(team == TFTeam_Red)
		{
			if(Gamemode == Gamemode_Ikea)
			{
				this.Class = Class_DBoi;
				return Class_DBoi;
			}

			if(!bot && IsClassTaken(Class_DBoi) && GetRandomInt(0, 1))
			{
				ClassEnum class = view_as<ClassEnum>(GetRandomInt(view_as<int>(Class_049), view_as<int>(Class_9392)));
				if(class!=Class_0492 && class!=Class_079 && !IsClassTaken(class))
				{
					this.Class = class;
					return class;
				}
			}

			this.Class = Class_DBoi;
			return Class_DBoi;
		}

		this.Class = Class_Spec;
		this.Keycard = Keycard_None;
		this.HealthPack = 0;
		this.Radio = 0;
		this.Power = 100.0;
		return Class_Spec;
	}

	void Spawn(int client, bool respawn)
	{
		TFTeam team = this.TeamTF();
		if(respawn)
		{
			if(team == TFTeam_Blue)
			{
				ChangeClientTeamEx(client, TFTeam_Blue);
			}
			else
			{
				ChangeClientTeamEx(client, TFTeam_Red);
			}
		}

		TF2_SetPlayerClass(client, ClassClass[this.Class]);

		if(respawn)
		{
			this.Respawning = GetGameTime()+0.5;
			TF2_RespawnPlayer(client);
		}

		if(team != TFTeam_Spectator)
			ChangeClientTeamEx(client, team);

		this.Disarmer = 0;
		this.DisableSpeed = false;
		this.Power = 100.0;
		TF2_RemoveAllWeapons(client);
		switch(this.Class)
		{
			case Class_DBoi:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
			}
			case Class_Chaos:
			{
				this.Keycard = Keycard_Chaos;
				this.HealthPack = 2;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG4));
			}
			case Class_Scientist:
			{
				this.Keycard = Keycard_Scientist;
				this.HealthPack = 2;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
			}
			case Class_Guard:
			{
				this.Keycard = Keycard_Guard;
				this.HealthPack = 0;
				this.Radio = 1;
				GiveWeapon(client, Weapon_Flash);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG));
				GiveWeapon(client, Weapon_Disarm);
			}
			case Class_MTF:
			{
				this.Keycard = Keycard_MTF;
				this.HealthPack = 0;
				this.Radio = 1;
				GiveWeapon(client, Weapon_Flash);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG2));
			}
			case Class_MTF2, Class_MTFS:
			{
				this.Keycard = Keycard_MTF2;
				this.HealthPack = this.Class==Class_MTFS ? 2 : 1;
				this.Radio = 1;
				GiveWeapon(client, Weapon_Frag);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG3));
				if(Gamemode != Gamemode_Ikea)
					GiveWeapon(client, Weapon_Disarm);
			}
			case Class_MTF3:
			{
				this.Keycard = Keycard_MTF3;
				this.HealthPack = 1;
				this.Radio = 1;
				GiveWeapon(client, Weapon_Frag);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG5));
				if(Gamemode != Gamemode_Ikea)
					GiveWeapon(client, Weapon_Disarm);
			}
			case Class_049:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				GiveWeapon(client, Weapon_049Gun);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_049));
			}
			case Class_0492:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_0492));
			}
			case Class_096:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096));
			}
			case Class_106:
			{
				this.Pos[0] = 0.0;
				this.Pos[1] = 0.0;
				this.Pos[2] = 0.0;
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_106));
			}
			case Class_173:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_173));
			}
			case Class_939, Class_9392:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = 0;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_939));
			}
			case Class_3008:
			{
				this.Keycard = Keycard_None;
				this.HealthPack = 0;
				this.Radio = SciEscaped;
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, SciEscaped ? Weapon_3008Rage : Weapon_3008));
			}
		}

		if(respawn)
			GoToSpawn(client);

		ShowClassInfo(client);
		SetCaptureRate(client);
		SetVariantString(ClassModel[this.Class]);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		TF2Attrib_SetByDefIndex(client, 49, 1.0);
		TF2Attrib_SetByDefIndex(client, 69, 0.0);
		//TF2Attrib_SetByDefIndex(client, 112, 0.03);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
	}

	int Access(AccessEnum type)
	{
		switch(type)
		{
			case Access_Main:
			{
				switch(this.Keycard)
				{
					case Keycard_None:
						return 0;

					case Keycard_Janitor, Keycard_Guard, Keycard_Zone:
						return 1;

					case Keycard_Engineer, Keycard_Facility, Keycard_O5:
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

					case Keycard_MTF3, Keycard_Chaos, Keycard_O5:
						return 3;
				}
			}
			case Access_Exit:
			{
				if(this.Keycard==Keycard_MTF2 || this.Keycard==Keycard_MTF3 || this.Keycard==Keycard_Facility || this.Keycard==Keycard_Chaos || this.Keycard==Keycard_O5)
					return 1;
			}
			case Access_Warhead:
			{
				if(this.Keycard==Keycard_Engineer || this.Keycard==Keycard_Facility || this.Keycard==Keycard_O5)
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
				if(this.Keycard==Keycard_Engineer || this.Keycard==Keycard_MTF3 || this.Keycard==Keycard_Facility || this.Keycard==Keycard_Chaos || this.Keycard==Keycard_O5)
					return 1;
			}
		}
		return 0;
	}
}

static const char ProjectileList[][] = 
{
	"tf_projectile_pipe",
	"tf_projectile_rocket",
	"tf_projectile_sentryrocket",
	"tf_projectile_arrow",
	"tf_projectile_stun_ball",
	"tf_projectile_ball_ornament",
	"tf_projectile_energy_ball",
	"tf_projectile_energy_ring",
	"tf_projectile_flare",
	"tf_projectile_healing_bolt",
	"tf_projectile_jar",
	"tf_projectile_jar_milk",
	"tf_projectile_syringe",
	//"tf_projectile_pipe_remote",
	//"tf_projectile_cleaver",
};

ClassEnum TestForceClass[MAXTF2PLAYERS];
ClientEnum Client[MAXTF2PLAYERS];

// SourceMod Events

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SCPSF_GetClientClass", Native_GetClientClass);

	GFOnEscape = new GlobalForward("SCPSF_OnEscape", ET_Ignore, Param_Cell);

	RegPluginLibrary("scp_sf");
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("arena_round_start", OnRoundReady, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeathPost, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", OnCapturePoint, EventHookMode_Pre);
	HookEvent("teamplay_flag_event", OnCaptureFlag, EventHookMode_Pre);
	HookEvent("teamplay_win_panel", OnWinPanel, EventHookMode_Pre);
	HookEvent("revive_player_complete", OnRevive);

	RegConsoleCmd("sm_scp", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scpinfo", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scp_info", Command_HelpClass, "View info about your current class");

	RegAdminCmd("scp_forceclass", Command_ForceClass, ADMFLAG_RCON, "Usage: scp_forceclass <target> <class>.  Forces that class to be played.");

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

	#if defined _voiceannounceex_included_
	Vaex = LibraryExists("voiceannounce_ex");
	#endif

	#if defined _sourcecomms_included
	SourceComms = LibraryExists("sourcecomms++");
	#endif

	#if defined _basecomm_included
	BaseComm = LibraryExists("basecomm");
	#endif

	HudIntro = CreateHudSynchronizer();
	HudExtra = CreateHudSynchronizer();
	HudPlayer = CreateHudSynchronizer();

	AddNormalSoundHook(HookSound);

	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);

	LoadTranslations("common.phrases");
	LoadTranslations("scp_sf.phrases");

	GameData gamedata = LoadGameConfigFile("scp_sf");
	if(gamedata != null)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		SDKTeamAddPlayer = EndPrepSDKCall();
		if(SDKTeamAddPlayer == null)
			LogError("[Gamedata] Could not find CTeam::AddPlayer");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		SDKTeamRemovePlayer = EndPrepSDKCall();
		if(SDKTeamRemovePlayer == null)
			LogError("[Gamedata] Could not find CTeam::RemovePlayer");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		SDKEquipWearable = EndPrepSDKCall();
		if(SDKEquipWearable == null)
			LogError("[Gamedata] Could not find CBasePlayer::EquipWearable");

		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::Create");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		SDKCreateWeapon = EndPrepSDKCall();
		if(SDKCreateWeapon == null)
			LogError("[Gamedata] Could not find CTFDroppedWeapon::Create");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::InitDroppedWeapon");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		SDKInitWeapon = EndPrepSDKCall();
		if(SDKInitWeapon == null)
			LogError("[Gamedata] Could not find CTFDroppedWeapon::InitDroppedWeapon");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::InitPickedUpWeapon");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		SDKInitPickup = EndPrepSDKCall();
		if(SDKInitPickup == null)
			LogError("[Gamedata] Could not find CTFDroppedWeapon::InitPickedUpWeapon");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TryToPickupDroppedWeapon");
		PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
		SDKTryPickup = EndPrepSDKCall();
		if(SDKTryPickup == null)
			LogError("[Gamedata] Could not find CTFPlayer::TryToPickupDroppedWeapon");

		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		SDKEquippedWearable = EndPrepSDKCall();
		if(SDKEquippedWearable == null)
			LogError("[Gamedata] Could not find CTFPlayer::GetEquippedWearableForLoadoutSlot");

		DHook_CreateDetour(gamedata, "CTFPlayer::SaveMe", DHook_Supercede, _);
		DHook_CreateDetour(gamedata, "CTFPlayer::RegenThink", DHook_RegenThinkPre, DHook_RegenThinkPost);
		DHook_CreateDetour(gamedata, "CTFPlayer::CanPickupDroppedWeapon", DHook_CanPickupDroppedWeaponPre, _);
		DHook_CreateDetour(gamedata, "CTFPlayer::DropAmmoPack", DHook_DropAmmoPackPre, _);

		DHAllowedToHealTarget = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
		if(DHAllowedToHealTarget != null)
		{
			if(DHookSetFromConf(DHAllowedToHealTarget, gamedata, SDKConf_Signature, "CWeaponMedigun::AllowedToHealTarget"))
			{
				DHookAddParam(DHAllowedToHealTarget, HookParamType_CBaseEntity);
				if(!DHookEnableDetour(DHAllowedToHealTarget, false, DHook_AllowedToHealTarget))
					LogError("[Gamedata] Failed to detour CWeaponMedigun::AllowedToHealTarget");
			}
			else
			{
				LogError("[Gamedata] Could not find CWeaponMedigun::AllowedToHealTarget");
			}
		}
		else
		{
			LogError("[Gamedata] Could not find CWeaponMedigun::AllowedToHealTarget");
		}

		/*int offset = GameConfGetOffset(gamedata, "CTFPlayer::WantsLagCompensationOnEntity"); 
		DHLagCompensation = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, DHook_ClientWantsLagCompensationOnEntity); 
		if(DHLagCompensation != null)
		{
			DHookAddParam(DHLagCompensation, HookParamType_CBaseEntity);
			DHookAddParam(DHLagCompensation, HookParamType_ObjectPtr);
			DHookAddParam(DHLagCompensation, HookParamType_Unknown);
		}
		else
		{
			LogError("[Gamedata] Could not find CTFPlayer::WantsLagCompensationOnEntity");
		}*/

		int offset = gamedata.GetOffset("CTFGameRules::SetWinningTeam");
		DHSetWinningTeam = DHookCreate(offset, HookType_GameRules, ReturnType_Void, ThisPointer_Ignore);
		if(DHSetWinningTeam != null)
		{
			DHookAddParam(DHSetWinningTeam, HookParamType_Int);
			DHookAddParam(DHSetWinningTeam, HookParamType_Int);
			DHookAddParam(DHSetWinningTeam, HookParamType_Bool);
			DHookAddParam(DHSetWinningTeam, HookParamType_Bool);
			DHookAddParam(DHSetWinningTeam, HookParamType_Bool);
			DHookAddParam(DHSetWinningTeam, HookParamType_Bool);
		}
		else
		{
			LogError("[Gamedata] Could not find CTFGameRules::SetWinningTeam");
		}

		DHForceRespawn = DHookCreateFromConf(gamedata, "CTFPlayer::ForceRespawn");
		if(DHForceRespawn == null)
			LogError("[Gamedata] Could not find CTFPlayer::ForceRespawn");

		DHRoundRespawn = DHookCreateFromConf(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
		if(DHRoundRespawn == null)
			LogError("[Gamedata] Could not find CTFPlayer::RoundRespawn");

		delete gamedata;
	}
	else
	{
		LogError("[Gamedata] Could not find scp_sl!");
	}

	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	}
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _voiceannounceex_included_
	if(StrEqual(name, "voiceannounce_ex"))
	{
		Vaex = true;
		return;
	}
	#endif

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
	#if defined _voiceannounceex_included_
	if(StrEqual(name, "voiceannounce_ex"))
	{
		Vaex = false;
		return;
	}
	#endif

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
	char buffer[PLATFORM_MAX_PATH];
	for(int i; i<sizeof(MusicList); i++)
	{
		FormatEx(buffer, sizeof(buffer), "sound/%s", MusicList[i]);
		if(FileExists(buffer, true))
			PrecacheSound(MusicList[i], true);
	}

	for(int i; i<sizeof(SoundList); i++)
	{
		FormatEx(buffer, sizeof(buffer), "sound/%s", SoundList[i]);
		if(FileExists(buffer, true))
			PrecacheSound(SoundList[i], true);
	}

	for(int i; i<sizeof(ClassModel); i++)
	{
		if(FileExists(ClassModel[i], true))
			PrecacheModel(ClassModel[i], true);
	}

	for(int i; i<sizeof(KeycardModel); i++)
	{
		if(FileExists(KeycardModel[i], true))
			PrecacheModel(KeycardModel[i], true);
	}

	GetCurrentMap(buffer, sizeof(buffer));
	if(!StrContains(buffer, "scp_3008", false))
	{
		Gamemode = Gamemode_Ikea;
	}
	else if(!StrContains(buffer, "scp_", false))
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

	if(DHSetWinningTeam != null)
		DHookGamerules(DHSetWinningTeam, false, _, DHook_SetWinningTeam);

	if(DHRoundRespawn != null)
		DHookGamerules(DHRoundRespawn, false, _, DHook_RoundRespawn);
}

public void OnMapEnd()
{
	ServerCommand("sm plugins reload scp_sl");
}

public void OnClientPostAdminCheck(int client)
{
	Client[client].NextSongAt = FAR_FUTURE;
	Client[client].Class = Class_Spec;
	//SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
	//SDKHook(client, SDKHook_PreThinkPost, OnPostThink);
	SDKHook(client, SDKHook_PreThink, OnPreThink);

	//if(DHLagCompensation != null)
		//DHookEntity(DHLagCompensation, true, client);

	if(DHForceRespawn != null)
		DHookEntity(DHForceRespawn, false, client, _, DHook_ForceRespawn);

	PrintToConsole(client, " \n \nWelcome to SCP: Secret Fortress\n \nThis is a gamemode based on the SCP series and community\nPlugin is created by Batfoxkid\n ");
	PrintToConsole(client, "If you like to support the gamemode, you can donate to Gamers Freak Fortress community at https://discordapp.com/invite/JWE72cs\n ");
	PrintToConsole(client, "The SCP community also needs help, you can support them at https://www.gofundme.com/f/scp-legal-funds\n \n ");

	CreateTimer(0.1, Timer_StartMenuTheme, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnRoundReady(Event event, const char[] name, bool dontBroadcast)
{
	Ready = true;
	Gamemode = Gamemode_Arena;
}

public void TF2_OnWaitingForPlayersStart()
{
	Ready = false;
}

public void TF2_OnWaitingForPlayersEnd()
{
	Ready = true;
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Enabled = false;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		if(IsPlayerAlive(client) && TF2_GetClientTeam(client)<=TFTeam_Spectator)
			ChangeClientTeamEx(client, TFTeam_Red);

		if(Client[client].Class==Class_106 && Client[client].Radio)
			HideAnnotation(client);
	}

	UpdateListenOverrides(FAR_FUTURE);

	/*for(int entity=2047; entity>MaxClients; entity++)
	{
		if(!IsValidEntity(entity))
			continue;

		
	}*/
}

public void OnConfigsExecuted()
{
	SteamWorks_SetGameDescription("SCP: Secret Fortress");
	//SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 9999);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!Ready)
		return;

	DClassEscaped = 0;
	DClassMax = 1;
	SciEscaped = 0;
	SciMax = 0;
	SCPKilled = 0;
	SCPMax = 0;
	Enabled = true;

	if(Gamemode == Gamemode_Arena)
	{
		int entity = MaxClients+1;
		while((entity=FindEntityByClassname2(entity, "trigger_capture_area")) != -1)
		{
			SDKHook(entity, SDKHook_StartTouch, OnCPTouch);
			SDKHook(entity, SDKHook_Touch, OnCPTouch);
		}
	}
	else
	{
		if(Gamemode == Gamemode_Ctf)
		{
			int entity = MaxClients+1;
			while((entity=FindEntityByClassname2(entity, "item_teamflag")) != -1)
			{
				SDKHook(entity, SDKHook_StartTouch, OnFlagTouch);
				SDKHook(entity, SDKHook_Touch, OnFlagTouch);
			}
		}
		else if(Gamemode == Gamemode_Koth)
		{
			int entity = MaxClients+1;
			while((entity=FindEntityByClassname2(entity, "trigger_capture_area")) != -1)
			{
				SDKHook(entity, SDKHook_StartTouch, OnCPTouch);
				SDKHook(entity, SDKHook_Touch, OnCPTouch);
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

		//if(DoorTimer == INVALID_HANDLE)
			//DoorTimer = CreateTimer(3.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	int entity = 0;
	int[] choosen = new int[MaxClients];
	for(int client=1; client<=MaxClients; client++)
	{
		Client[client].NextSongAt = 0.0;
		if(!IsValidClient(client) || TF2_GetClientTeam(client)<=TFTeam_Spectator)
			continue;

		if(TestForceClass[client] <= Class_Spec)
		{
			choosen[entity++] = client;
			continue;
		}

		Client[client].Class = TestForceClass[client];
		TestForceClass[client] = Class_Spec;
		switch(Client[client].Class)
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
				if(IsSCP(client))
					SCPMax++;
			}
		}
		Client[client].Spawn(client, true);
	}

	if(!entity)
		return;

	entity = choosen[GetRandomInt(0, entity-1)];
	Client[entity].Class = Class_DBoi;
	Client[entity].Spawn(entity, true);

	for(int client=1; client<=MaxClients; client++)
	{
		if(client==entity || !IsValidClient(client) || TestForceClass[client]>Class_Spec || TF2_GetClientTeam(client)<=TFTeam_Spectator)
			continue;

		TFTeam team = TF2_GetClientTeam(client);
		switch(Client[client].Setup(team, IsFakeClient(client)))
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
				if(IsSCP(client))
					SCPMax++;
			}
		}
		Client[client].Spawn(client, true);
	}

	UpdateListenOverrides(FAR_FUTURE);

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
	//char buffer[4];
	//event.GetString("eventtype", buffer, sizeof(buffer));
	if(event.GetInt("eventtype") != 2)
		return Plugin_Handled;

	//event.GetString("player", buffer, sizeof(buffer));
	int client = event.GetInt("player");
	if(IsValidClient(client))
		TF2_AddCondition(client, TFCond_TeleportedGlow, 5.0);

	return Plugin_Handled;
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
		for(int target=1; target<=MaxClients; target++)
		{
			Client[target].NextSongAt = FAR_FUTURE;
			if(IsValidClient(target) && Client[target].CurrentSong>=0)
				StopSound(target, SNDCHAN_AUTO, MusicList[Client[target].CurrentSong]);
		}
	}
	else if(!StrContains(name, "scp_respawn", false))
	{
		if(!IsValidClient(client))
			return Plugin_Continue;

		int target = -1;
		static int spawns[36];
		int count;
		while((target=FindEntityByClassname2(target, "info_player_teamspawn")) != -1)
		{
			if(GetEntProp(target, Prop_Send, "m_iTeamNum") == 2)
				spawns[count++] = target;

			if(count >= sizeof(spawns))
				break;
		}

		target = spawns[GetRandomInt(0, count-1)];

		static float pos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(client, pos, NULL_VECTOR, TRIPLE_D);
	}
	else if(!StrContains(name, "scp_femur", false))
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && (Client[target].Class==Class_106 || Client[target].Class==Class_3008))
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
		}
	}
	else if(!StrContains(name, "scp_upgrade", false))
	{
		if(!IsValidClient(client))
			return Plugin_Continue;

		char buffer[32];
		if(Client[client].Cooldown > GetEngineTime())
		{
			Menu menu = new Menu(Handler_None);
			menu.SetTitle("%T", "scp_914", client);

			FormatEx(buffer, sizeof(buffer), "%T", "in_cooldown");
			menu.AddItem("0", buffer);
			menu.ExitButton = false;
			menu.Display(client, 5);
		}
		else
		{
			Menu menu = new Menu(Handler_Upgrade);
			menu.SetTitle("%T", "scp_914", client);

			char buffer[32];

			if(Client[client].Keycard == Keycard_None)
			{
				FormatEx(buffer, sizeof(buffer), "%T", "keycard_rough", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_coarse", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_even", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_fine", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_very", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "keycard_rough", client);
				menu.AddItem("0", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_coarse", client);
				menu.AddItem("1", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_even", client);
				menu.AddItem("2", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_fine", client);
				menu.AddItem("3", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "keycard_very", client);
				menu.AddItem("4", buffer);
			}

			if(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary) > MaxClients)
			{
				FormatEx(buffer, sizeof(buffer), "%T", "weapon_rough", client);
				menu.AddItem("5", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_coarse", client);
				menu.AddItem("6", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_even", client);
				menu.AddItem("7", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_fine", client);
				menu.AddItem("8", buffer);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_very", client);
				menu.AddItem("9", buffer);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%T", "weapon_rough", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_coarse", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_even", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_fine", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%T", "weapon_very", client);
				menu.AddItem("0", buffer, ITEMDRAW_DISABLED);
			}

			menu.Pagination = false;
			menu.Display(client, 15);
		}
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
					if(!IsPlayerAlive(client) || Client[client].Keycard==Keycard_None)
						return;

					if(GetRandomInt(0, 1))
					{
						Client[client].Keycard = Keycard_None;
						return;
					}

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][0];
					Client[client].Keycard = KeycardPaths[Client[client].Keycard][0];
					Client[client].Cooldown = GetEngineTime()+5.0;
				}
				case 1:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard==Keycard_None)
						return;

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][0];
					Client[client].Cooldown = GetEngineTime()+7.5;
				}
				case 2:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard==Keycard_None)
						return;

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][1];
					Client[client].Cooldown = GetEngineTime()+10.0;
				}
				case 3:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard==Keycard_None)
						return;

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][2];
					Client[client].Cooldown = GetEngineTime()+12.5;
				}
				case 4:
				{
					if(!IsPlayerAlive(client) || Client[client].Keycard==Keycard_None)
						return;

					if(GetRandomInt(0, 1))
					{
						Client[client].Keycard = Keycard_None;
						return;
					}

					Client[client].Keycard = KeycardPaths[Client[client].Keycard][2];
					Client[client].Keycard = KeycardPaths[Client[client].Keycard][2];
					Client[client].Cooldown = GetEngineTime()+15.0;
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
					for(; wep<=Weapon_SMG5; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG5)
						return;

					Client[client].Cooldown = GetEngineTime()+5.0;
					wep -= view_as<WeaponEnum>(2);
					if(wep<Weapon_Pistol || GetRandomInt(0, 1))
					{
						TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
						if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)<=MaxClients && GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)<=MaxClients)
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));

						return;
					}

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
					for(; wep<=Weapon_SMG5; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG5)
						return;

					Client[client].Cooldown = GetEngineTime()+7.5;
					wep--;
					if(wep < Weapon_Pistol)
					{
						TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
						if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)<=MaxClients && GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)<=MaxClients)
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));

						return;
					}

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
				case 7:
				{
					if(!IsPlayerAlive(client) || GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)<=MaxClients)
						return;

					Client[client].Cooldown = GetEngineTime()+10.0;
					Client[client].Power = 99.0;
					SpawnPickup(client, "item_ammopack_large");
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
					for(; wep<=Weapon_SMG5; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG5)
						return;

					Client[client].Cooldown = GetEngineTime()+12.5;
					wep++;
					if(wep > Weapon_SMG5)
					{
						TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
						if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)<=MaxClients && GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)<=MaxClients)
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));

						return;
					}

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
					for(; wep<=Weapon_SMG5; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG5)
						return;

					Client[client].Cooldown = GetEngineTime()+15.0;
					wep += view_as<WeaponEnum>(2);
					if(wep>Weapon_SMG5 || GetRandomInt(0, 1))
					{
						TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
						if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)<=MaxClients && GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)<=MaxClients)
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));

						return;
					}

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
			}
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
	if(cond!=TFCond_TeleportedGlow || !IsValidClient(client))
		return;

	if(Client[client].Class == Class_DBoi)
	{
		DropAllWeapons(client);
		if(Gamemode == Gamemode_Ikea)
		{
			Call_StartForward(GFOnEscape);
			Call_PushCell(client);
			Call_Finish();

			DClassEscaped++;
			Client[client].Class = Class_MTFS;
		}
		else if(Client[client].Disarmer)
		{
			Client[client].Class = Class_MTF;
		}
		else
		{
			Call_StartForward(GFOnEscape);
			Call_PushCell(client);
			Call_Finish();

			DClassEscaped++;
			Client[client].Class = Class_Chaos;
		}
		Client[client].Spawn(client, false);
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(Client[client].Class == Class_Scientist)
	{
		DropAllWeapons(client);
		if(Client[client].Disarmer)
		{
			Client[client].Class = Class_Chaos;
		}
		else
		{
			Call_StartForward(GFOnEscape);
			Call_PushCell(client);
			Call_Finish();

			SciEscaped++;
			Client[client].Class = Class_MTFS;
		}
		Client[client].Spawn(client, false);
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;

	if((Enabled && Client[client].Class==Class_Spec) || (!Enabled && Gamemode!=Gamemode_Arena))
	{
		TF2_AddCondition(client, TFCond_StealthedUserBuffFade, TFCondDuration_Infinite);
		TF2_AddCondition(client, TFCond_HalloweenGhostMode, TFCondDuration_Infinite);
		if(IsFakeClient(client))
			TeleportEntity(client, TRIPLE_D, NULL_VECTOR, NULL_VECTOR);
	}

	/*int entity = MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*")) != -1)
	{
		client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
				{
					//NOOP
				}
				default:
				{
					TF2_RemoveWearable(client, entity);
				}
			}
		}
	}

	entity = MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle")) != -1)
	{
		client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(IsValidClient(client))
			TF2_RemoveWearable(client, entity);
	}*/
	return Plugin_Continue;
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
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(TFClass_Scout));
		TF2_RespawnPlayer(client);
	}
	return Plugin_Handled;
}

public Action OnJoinAuto(int client, const char[] command, int args)
{
	return (client && TF2_GetClientTeam(client)>TFTeam_Spectator) ? Plugin_Handled : Plugin_Continue;
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

	if(TF2_GetClientTeam(client) <= TFTeam_Spectator)
		ClientCommand(client, "autoteam");

	return Plugin_Handled;
}

public Action OnVoiceMenu(int client, const char[] command, int args)
{
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

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
				SetEntProp(client, Prop_Send, "m_bDucked", 1);
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
	if(msg[1] == '/')
		return Plugin_Handled;

	ReplaceString(msg, sizeof(msg), "\"", "");
	ReplaceString(msg, sizeof(msg), "\n", "");

	char name[128];
	FormatEx(name, sizeof(name), "{red}%N", client);

	Handle iter = GetPluginIterator();
	while(MorePlugins(iter))
	{
		Handle plugin = ReadPlugin(iter);
		Function func = GetFunctionByName(plugin, "SCPSF_OnChatMessage");
		if(func == INVALID_FUNCTION)
			continue;

		Call_StartFunction(plugin, func);
		Call_PushCell(client);
		Call_PushStringEx(name, sizeof(name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(msg, sizeof(msg), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish();
	}
	delete iter;

	if(!Enabled)
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target]))
				CPrintToChat(target, "%s {default}: %s", name, msg);
		}
		return Plugin_Handled;
	}

	if(!IsSCP(client) && GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target] && IsSpec(target)))
				CPrintToChat(target, "*SPEC* %s {default}: %s", name, msg);
		}
		return Plugin_Handled;
	}

	if(IsSpec(client))
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || (IsValidClient(target, false) && Client[client].CanTalkTo[target] && IsSpec(target)))
				CPrintToChat(target, "*DEAD* %s {default}: %s", name, msg);
		}
		return Plugin_Handled;
	}

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
			continue;
		}

		if(IsSCP(client) || Client[client].Power<=0 || !Client[client].Radio)
		{
			CPrintToChat(target, "%s {default}: %s", name, msg);
			continue;
		}

		static float targetPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", targetPos);
		CPrintToChat(target, "%s%s {default}: %s", GetVectorDistance(clientPos, targetPos)<350 ? "" : "*RADIO* ", name, msg);
	}
	return Plugin_Handled;
}

public Action Command_HelpClass(int client, int args)
{
	if(client && IsPlayerAlive(client))
		ShowClassInfo(client);

	return Plugin_Handled;
}

public Action Command_ForceClass(int client, int args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_forceclass <target> <class>");
		return Plugin_Handled;
	}

	static char classString[64];
	GetCmdArg(2, classString, sizeof(classString));

	char pattern[PLATFORM_MAX_PATH];

	ClassEnum class = Class_Spec;
	for(int i=1; i<view_as<int>(ClassEnum); i++)
	{
		GetClassName(i, pattern, sizeof(pattern));
		Format(pattern, sizeof(pattern), "%T", pattern, client);
		if(StrContains(pattern, classString, false) < 0)
			continue;

		class = view_as<ClassEnum>(i);
		break;
	}

	if(class == Class_Spec)
	{
		ReplyToCommand(client, "[SM] Invalid class string");
		return Plugin_Handled;
	}

	static char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	GetCmdArg(1, pattern, sizeof(pattern));
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches < 1)
		return Plugin_Handled;

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
		Client[targets[target]].Spawn(targets[target], true);
	}
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
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

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return Plugin_Continue;

	int flags = event.GetInt("death_flags");
	if(flags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Handled;

	CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	if(TF2_GetClientTeam(client) == TFTeam_Unassigned)
		ChangeClientTeamEx(client, TFTeam_Red);

	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
		TF2_SetPlayerClass(client, TFClass_Medic);

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsSCP(client))
	{
		if(Client[client].Class!=Class_0492 && Client[client].Class!=Class_3008)
		{
			if(Client[client].Class==Class_106 && Client[client].Radio)
				HideAnnotation(client);

			static char class1[16];
			GetClassName(Client[client].Class, class1, sizeof(class1));

			SCPKilled++;
			if(attacker!=client && IsValidClient(attacker))
			{
				static char class2[16];
				GetClassName(Client[attacker].Class, class2, sizeof(class2));

				int assister = GetClientOfUserId(event.GetInt("assister"));
				if(assister!=client && IsValidClient(assister))
				{
					static char class3[16];
					GetClassName(Client[assister].Class, class3, sizeof(class3));

					flags |= TF_DEATHFLAG_KILLERREVENGE|TF_DEATHFLAG_ASSISTERREVENGE;
					CPrintToChatAll("%s%t", PREFIX, "scp_killed_duo", ClassColor[Client[client].Class], class1, ClassColor[Client[attacker].Class], class2, ClassColor[Client[assister].Class], class3);
				}
				else
				{
					flags |= TF_DEATHFLAG_KILLERREVENGE;
					CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, ClassColor[Client[attacker].Class], class2);
				}
				Client[client].Class = Class_Spec;
				return Plugin_Changed;
			}

			int damage = event.GetInt("damagebits");
			if(damage & DMG_SHOCK)
			{
				CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, "gray", "telsa_gate");
			}
			else if(damage & DMG_NERVEGAS)
			{
				CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, "gray", "femur_breaker");
			}
			else
			{
				CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, "black", "redacted");
			}
		}
		Client[client].Class = Class_Spec;
		return Plugin_Handled;
	}

	Client[client].Class = Class_Spec;
	if(client==attacker || !IsValidClient(attacker))
	{
		if(TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath) && (GetEntityFlags(client) & FL_ONGROUND))
		{
			RequestFrame(RemoveRagdoll, client);
			CreateSpecialDeath(client);
		}
		return Plugin_Handled;
	}

	if(Client[attacker].Class == Class_049)
	{
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			RequestFrame(RemoveRagdoll, client);
			CreateSpecialDeath(client);
		}
		ChangeClientTeamEx(client, TF2_GetClientTeam(attacker));
		SpawnReviveMarker(client, GetClientTeam(attacker));
	}
	else if(Client[attacker].Class == Class_173)
	{
		EmitSoundToAll(SoundList[Sound_Snap], client);
		EmitSoundToAll(SoundList[Sound_Snap], client);
	}
	return Plugin_Handled;
}

public void OnPlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	UpdateListenOverrides(GetEngineTime());
}

public Action OnBroadcast(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	static char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.", false))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!Enabled || IsSpec(client))
		return Plugin_Continue;

	bool changed;
	static int holding[MAXTF2PLAYERS];
	static float pos[3], ang[3];
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
					SetEntProp(client, Prop_Send, "m_bDucked", 1);
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
		else if(!IsSCP(client))
		{
			if(AttemptGrabItem(client))
			{
				buttons &= ~IN_ATTACK2;
				changed = true;
			}
			else if(Client[client].HealthPack)
			{
				int entity = CreateEntityByName(Client[client].HealthPack==1 ? "item_healthkit_small" : "item_healthkit_medium");
				if(entity > MaxClients)
				{
					GetClientAbsOrigin(client, pos);
					pos[2] += 20.0;
					DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
					DispatchSpawn(entity);
					SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
					SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

					CanTouchAt[entity] = GetEngineTime()+2.0;
					SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
					SDKHook(entity, SDKHook_Touch, OnKitPickup);

					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					Client[client].HealthPack = 0;
				}
			}
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
		holding[client] = IN_ATTACK2;
	}
	else if(buttons & IN_ATTACK3)	// Special Attack (Radio/Self Tele)
	{
		if(!IsSCP(client))
		{
			if(AttemptGrabItem(client))
			{
				buttons &= ~IN_ATTACK3;
				changed = true;
			}
			else if(Client[client].Power>1 && Client[client].Radio>0)
			{
				if(++Client[client].Radio > 4)
					Client[client].Radio = 1;
			}
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
				Client[client].TeleIn = GetEngineTime()+5.0;
				PrintRandomHintText(client);
			}
		}
		holding[client] = IN_ATTACK3;
	}

	if(!(buttons & IN_SCORE))
		return changed ? Plugin_Changed : Plugin_Continue;

	buttons &= ~IN_SCORE;
	return Plugin_Changed;
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
		if(!(ticks % 180))
		{
				if(Gamemode == Gamemode_Ikea)
				{
					if(SciEscaped)
					{
						SciEscaped = 0;

						int count;
						static int choosen[MAXTF2PLAYERS];
						for(int client=1; client<=MaxClients; client++)
						{
							if(IsValidClient(client) && IsSpec(client) && TF2_GetClientTeam(client)>TFTeam_Spectator)
								choosen[count++] = client;
						}

						if(count)
						{
							count = choosen[GetRandomInt(0, count-1)];
							Client[count].Class = Class_MTF3;
							Client[count].Spawn(count, true);

							for(int client=1; client<=MaxClients; client++)
							{
								if(!IsValidClient(client))
									continue;

								if(Client[client].Class == Class_3008)
								{
									Client[client].Radio = 0;
									SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_3008));
									continue;
								}

								if(!IsSpec(client) || TF2_GetClientTeam(client)<=TFTeam_Spectator)
									continue;

								Client[client].Class = GetRandomInt(0, 3) ? Class_MTF : Class_MTF2;
								Client[client].Spawn(client, true);
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
								SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_3008Rage));
								continue;
							}

							if(!IsSpec(client) || TF2_GetClientTeam(client)<=TFTeam_Spectator)
								continue;

							Client[client].Class = Class_3008;
							Client[client].Spawn(client, true);
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
				else
				{
					if(GetRandomInt(0, 1))
					{
						int count;
						static int choosen[MAXTF2PLAYERS];
						for(int client=1; client<=MaxClients; client++)
						{
							if(IsValidClient(client) && IsSpec(client) && TF2_GetClientTeam(client)>TFTeam_Spectator)
								choosen[count++] = client;
						}

						if(count)
						{
							count = choosen[GetRandomInt(0, count-1)];
							Client[count].Class = Class_MTF3;
							Client[count].Spawn(count, true);

							count = 0;
							for(int client=1; client<=MaxClients; client++)
							{
								if(!IsValidClient(client))
									continue;

								ChangeSong(client, -1, engineTime+20.0, SoundList[Sound_MTFSpawn]);
								if(IsSCP(client))
								{
									count++;
									continue;
								}

								if(!IsSpec(client) || TF2_GetClientTeam(client)<=TFTeam_Spectator)
									continue;

								Client[client].Class = GetRandomInt(0, 3) ? Class_MTF : Class_MTF2;
								Client[client].Spawn(client, true);
							}
							CPrintToChatAll("%s%t", PREFIX, "mtf_spawn");

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
						bool hasSpawned;
						for(int client=1; client<=MaxClients; client++)
						{
							if(!IsValidClient(client))
								continue;

							if(!IsSpec(client) || TF2_GetClientTeam(client)<=TFTeam_Spectator)
								continue;

							Client[client].Class = Class_Chaos;
							Client[client].Spawn(client, true);
							hasSpawned = true;
						}

						if(hasSpawned)
							ChangeGlobalSong(-1, engineTime+20.0, SoundList[Sound_ChaosSpawn]);
					}
				}
		}
		else if(!(ticks % 90))
		{
			DisplayHint(false);
		}
		else if(Gamemode >= Gamemode_Arena)
		{
				if(!NoMusic && ticks==RoundFloat(MAXTIME-MusicTimes[1]))
				{
					ChangeGlobalSong(1, engineTime+15.0+MusicTimes[1], MusicList[1]);
					CPrintToChatAll("%sNow Playing: %s", PREFIX, MusicNames[1]);
				}

				if(ticks > MAXTIME)
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

							FadeMessage(client, 36, 1536, 0x00010, 255, 228, 200, 228);
							ClientCommand(client, "soundfade 100 4 4 0.2");
						}
						EndRound(Team_Spec);
					}
				}
				else if(ticks > (MAXTIME-120))
				{
					char seconds[4];
					int sec = (MAXTIME-ticks)%60;
					if(sec > 9)
					{
						IntToString(sec, seconds, sizeof(seconds));
					}
					else
					{
						FormatEx(seconds, sizeof(seconds), "0%d", sec);
					}

					int min = RoundToFloor((MAXTIME-ticks)/60.0);
					char buffer[64];
					for(int client=1; client<=MaxClients; client++)
					{
						if(!IsValidClient(client))
							continue;

						BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
						if(bf == null)
							continue;

						FormatEx(buffer, sizeof(buffer), "%T", "time_remaining", client, min, seconds);
						bf.WriteString(buffer);
						bf.WriteString(ticks>(MAXTIME-20) ? "ico_notify_ten_seconds" : ticks>(MAXTIME-60) ? "ico_notify_thirty_seconds" : "ico_notify_sixty_seconds");
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

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled)
		return Plugin_Continue;

	if(Client[victim].InvisFor > GetEngineTime())
		return Plugin_Handled;

	if(!IsValidClient(attacker))
	{
		if(damagetype & DMG_FALL)
		{
			if(Client[victim].Class == Class_173)
				return Plugin_Handled;

			//damage = IsSCP(victim) ? damage*0.01 : Pow(damage, 1.25);
			damage = IsSCP(victim) ? damage*0.01 : damage*5.0;
			return Plugin_Changed;
		}
		return Plugin_Continue;
	}

	if(victim!=attacker && !IsFakeClient(victim))
	{
		if(Client[victim].Class<Class_DBoi || Client[attacker].Class<Class_DBoi)	// Either Spectator
			return Plugin_Handled;

		if(Gamemode == Gamemode_Ikea)
		{
			if(Client[victim].Class>=Class_DBoi && Client[attacker].Class>=Class_DBoi && Client[victim].Class<Class_049 && Client[attacker].Class<Class_049)
				return Plugin_Handled;
		}
		else
		{
			if(Client[victim].Class<Class_Scientist && Client[attacker].Class<Class_Scientist)	// Both are DBoi/Chaos
				return Plugin_Handled;

			if(Client[victim].Class>=Class_Scientist && Client[attacker].Class>=Class_Scientist && Client[victim].Class<Class_049 && Client[attacker].Class<Class_049)	// Both are Scientist/MTF
				return Plugin_Handled;
		}

		if(Client[victim].Class>=Class_049 && Client[attacker].Class>=Class_049)	// Both are SCPs
			return Plugin_Handled;

		if(Client[victim].Class==Class_3008 && !Client[victim].Radio)
		{
			Client[victim].Radio = 1;
			SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", GiveWeapon(victim, Weapon_3008Rage));
		}
	}

	if(IsValidEntity(weapon) && weapon>MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index == WeaponIndex[Weapon_Disarm])
		{
			if(!IsSCP(victim))
			{
				if(!Client[victim].Disarmer)
				{
					BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", victim));
					if(bf != null)
					{
						char buffer[64];
						FormatEx(buffer, sizeof(buffer), "%T", "disarmed", victim);
						bf.WriteString(buffer);
						bf.WriteString("ico_notify_flag_moving_alt");
						bf.WriteByte(view_as<int>(TFTeam_Red));
						EndMessage();
					}
				}

				Client[victim].Disarmer = attacker;
				DropAllWeapons(victim);
				Client[victim].HealthPack = 0;
				TF2_RemoveAllWeapons(victim);
				SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", GiveWeapon(victim, Weapon_None));
			}
		}
		else if(index == WeaponIndex[Weapon_Flash])
		{
			FadeMessage(victim, 36, 768, 0x00010);
			ClientCommand(victim, "soundfade 100 2 2 0.2");
		}
	}

	if(Client[attacker].Class == Class_106)
	{
		SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);

		int entity = -1;
		static char name[16];
		static int spawns[4];
		int count;
		while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(!StrContains(name, "scp_pocket", false))
				spawns[count++] = entity;

			if(count > 3)
				break;
		}

		if(!count)
		{
			if(!GetRandomInt(0, 2))
				return Plugin_Continue;

			damagetype |= DMG_CRIT;
			return Plugin_Changed;
		}

		entity = spawns[GetRandomInt(0, count-1)];

		static float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(victim, pos, NULL_VECTOR, TRIPLE_D);
	}
	return Plugin_Continue;
}

/*public void OnWeaponSwitch(int client, int weapon)
{
	if(!Enabled || IsSCP(client) || weapon<=MaxClients || !IsValidEntity(weapon))
		return;

	static char classname[MAX_CLASSNAME_LENGTH];
	if(!GetEntityClassname(weapon, classname, MAX_CLASSNAME_LENGTH) || StrContains(classname, "tf_weapon", false))
		return;

	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 35, 173:	// Kritzkrieg, Vita-Saw
		{
			TF2_SetPlayerClass(client, TFClass_Medic, false);
		}
		case 308, 1151, 1150:	// Loch-n-Load, Iron Bomber, Quickiebomb Launcher
		{
			TF2_SetPlayerClass(client, TFClass_DemoMan, false);
		}
		case 415, 425, 1153:	// Reserve Shooter, Family Business, Panic Attack
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					TF2_SetPlayerClass(client, TFClass_Pyro, false);

				case Class_MTF2, Class_MTFS:
					TF2_SetPlayerClass(client, TFClass_Heavy, false);

				default:
					TF2_SetPlayerClass(client, TFClass_Soldier, false);
			}
		}
		case 954:	// Memory Maker
		{
			//TF2_SetPlayerClass(client, Client[client].TFClass(), false);
			TF2_SetPlayerClass(client, TFClass_Sniper, false);
		}
		case 735, 736:	// Sapper
		{
			TF2_SetPlayerClass(client, TFClass_Spy, false);
		}
	}
}*/

public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	return (Enabled && IsValidClient(entity) && (IsSCP(entity) || IsSpec(entity)) && !StrContains(sample, "vo", false)) ? Plugin_Handled : Plugin_Continue;
}

public Action OnTransmit(int client, int target)
{
	if(!Enabled || client==target || TF2_IsPlayerInCondition(target, TFCond_HalloweenGhostMode))
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return Plugin_Handled;

	float engineTime = GetEngineTime();
	if(Client[client].InvisFor > engineTime)
		return Plugin_Handled;

	return (IsValidClient(target) && (Client[target].Class==Class_939 || Client[target].Class==Class_9392 || (Client[target].Class==Class_3008 && !Client[target].Radio)) && !IsSCP(client) && Client[client].IdleAt<engineTime) ? Plugin_Handled : Plugin_Continue;
}

public Action OnCPTouch(int entity, int client)
{
	if(IsValidClient(client))
		Client[client].IsCapping = GetGameTime()+0.15;

	return Plugin_Continue;
}

public Action OnFlagTouch(int entity, int client)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	return (Client[client].Class==Class_DBoi || Client[client].Class==Class_Scientist) ? Plugin_Continue : Plugin_Handled;
}

public Action OnGetMaxHealth(int client, int &health)
{
	if(!Enabled)
		return Plugin_Continue;

	switch(Client[client].Class)
	{
		case Class_MTF2, Class_MTFS, Class_Chaos:
		{
			health = 150;
		}
		case Class_MTF3:
		{
			health = 200; //187.5
		}
		case Class_049:
		{
			health = 2125;
		}
		case Class_0492:
		{
			health = 375;
		}
		case Class_096:
		{
			health = 2500;	//???
		}
		case Class_106:
		{
			health = 800; //812.5
		}
		case Class_173:
		{
			health = 4000;
		}
		case Class_939, Class_9392:
		{
			health = 2750;
		}
		case Class_3008:
		{
			health = 500;
		}
		default:
		{
			health = 125;
		}
	}
	return Plugin_Changed;
}

public void OnPreThink(int client)
{
	if(!Enabled)
		return;

	float engineTime = GetEngineTime();
	if(Client[client].InvisFor > engineTime+2.0)
	{
		if(Client[client].InvisFor < engineTime)
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
			return;
		}
		
		TF2_RemoveCondition(client, TFCond_Taunting);
		return;
	}

	if(!IsSpec(client) && !Client[client].DisableSpeed)
	{
		float speed;
		switch(Client[client].Class)
		{
			case Class_DBoi, Class_Scientist:
			{
				speed = Client[client].Disarmer ? 240.0 : 270.0;
			}
			case Class_Chaos:
			{
				speed = 240.0;
			}
			case Class_MTF3:
			{
				speed = 240.0;
			}
			case Class_Guard, Class_MTF, Class_MTF2, Class_MTFS:
			{
				speed = Client[client].Disarmer ? 240.0 : 250.0;
			}
			case Class_049:
			{
				speed = 230.0;
			}
			case Class_0492, Class_3008:
			{
				speed = 260.0;
			}
			case Class_096:
			{
				speed = 210.0;
			}
			case Class_106:
			{
				speed = 190.0;
			}
			case Class_173:
			{
				speed = 400.0;
			}
			case Class_939, Class_9392:
			{
				speed = 280.0 - (GetClientHealth(client)/55.0);
			}
			default:
			{
				speed = 270.0;
			}
		}
		SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
	}

	if(Client[client].Class == Class_173)
	{
		switch(Client[client].Radio)
		{
			case 1:
			{
				if(GetEntityMoveType(client) != MOVETYPE_NONE)
				{
					if(GetEntityFlags(client) & FL_ONGROUND)
					{
						SetEntityMoveType(client, MOVETYPE_NONE);
					}
					else
					{
						SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 1.0);
						static float vel[3];
						vel[2] = -500.0;
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
					}
				}
			}
			case 2:
			{
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 3000.0);
			}
		}
	}
	else if(Client[client].Class == Class_096)
	{
		switch(Client[client].Radio)
		{
			case 1:
			{
				if(Client[client].Power < engineTime)
				{
					TF2_AddCondition(client, TFCond_CritCola, 20.0);
					Client[client].DisableSpeed = true;
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096Rage));
					Client[client].Power = engineTime+15.0;
					Client[client].Radio = 2;
				}
				return;
			}
			case 2:
			{
				TF2_RemoveCondition(client, TFCond_Dazed);
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", 475.0);
				if(Client[client].Power < engineTime)
				{
					TF2_RemoveCondition(client, TFCond_CritCola);
					Client[client].DisableSpeed = false;
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096));
					Client[client].Radio = 0;
					Client[client].Power = engineTime+15.0;
					EmitSoundToAll(SoundList[Sound_096], client);
				}
				return;
			}
			default:
			{
				if(Client[client].Power > engineTime)
					return;
			}
		}
	}

	static float specialTick[MAXTF2PLAYERS];
	if(specialTick[client] > engineTime)
		return;

	static float clientPos[3];

	int status;
	bool showHud = (Client[client].HudIn<engineTime && IsPlayerAlive(client));
	specialTick[client] = engineTime+0.2;
	if(Client[client].Class == Class_106)
	{
		if(Client[client].TeleIn && Client[client].TeleIn<engineTime)
		{
			Client[client].TeleIn = 0.0;
			TeleportEntity(client, Client[client].Pos, NULL_VECTOR, TRIPLE_D);
		}
		else if(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2])
		{
			GetClientEyePosition(client, clientPos);
			if(Client[client].Radio)
			{
				if(GetVectorDistance(clientPos, Client[client].Pos) > 400)
					HideAnnotation(client);
			}
			else if(GetVectorDistance(clientPos, Client[client].Pos) < 300)
			{
				ShowAnnotation(client);
			}
		}

	}
	else if(Client[client].Class==Class_096 || Client[client].Class==Class_173)
	{
		static int blink;
		GetClientEyePosition(client, clientPos);

		static float clientAngles[3];
		GetClientEyeAngles(client, clientAngles);
		clientAngles[0] = fixAngle(clientAngles[0]);
		clientAngles[1] = fixAngle(clientAngles[1]);

		for(int target=1; target<=MaxClients; target++)
		{
			if(!IsValidClient(target) || IsSpec(target) || IsSCP(target))
				continue;

			static float enemyPos[3];
			static float enemyAngles[3];
			GetClientEyePosition(target, enemyPos);
			GetClientEyeAngles(target, enemyAngles);
			static float anglesToBoss[3];
			GetVectorAnglesTwoPoints(enemyPos, clientPos, anglesToBoss);

			// fix all angles
			enemyAngles[0] = fixAngle(enemyAngles[0]);
			enemyAngles[1] = fixAngle(enemyAngles[1]);
			anglesToBoss[0] = fixAngle(anglesToBoss[0]);
			anglesToBoss[1] = fixAngle(anglesToBoss[1]);

			// verify angle validity
			if(!(fabs(enemyAngles[0] - anglesToBoss[0]) <= MAXANGLEPITCH ||
			(fabs(enemyAngles[0] - anglesToBoss[0]) >= (360.0-MAXANGLEPITCH))))
				continue;

			if(!(fabs(enemyAngles[1] - anglesToBoss[1]) <= MAXANGLEYAW ||
			(fabs(enemyAngles[1] - anglesToBoss[1]) >= (360.0-MAXANGLEYAW))))
				continue;

			// ensure no wall is obstructing
			static float result[3];
			TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
			TR_GetEndPosition(result);
			if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
				continue;

			if(Client[client].Class == Class_096)
			{
				GetVectorAnglesTwoPoints(clientPos, enemyPos, anglesToBoss);

				// fix all angles
				anglesToBoss[0] = fixAngle(anglesToBoss[0]);
				anglesToBoss[1] = fixAngle(anglesToBoss[1]);

				// verify angle validity
				if(!(fabs(clientAngles[0] - anglesToBoss[0]) <= MAXANGLEPITCH ||
				(fabs(clientAngles[0] - anglesToBoss[0]) >= (360.0-MAXANGLEPITCH))))
					continue;

				if(!(fabs(clientAngles[1] - anglesToBoss[1]) <= MAXANGLEYAW ||
				(fabs(clientAngles[1] - anglesToBoss[1]) >= (360.0-MAXANGLEYAW))))
					continue;

				// ensure no wall is obstructing
				TR_TraceRayFilter(clientPos, enemyPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=enemyPos[0] || result[1]!=enemyPos[1] || result[2]!=enemyPos[2])
					continue;
			}

			// success
			if(!blink && Client[client].Class==Class_173)
			{
				status = 2;
				FadeMessage(target, 52, 52, 0x0002, 0, 0, 0);
			}
			else
			{
				status = 1;
			}
		}

		if(blink > 0)
		{
			blink--;
		}
		else
		{
			blink = GetRandomInt(10, 20);
		}

		if(Client[client].Class == Class_096)
		{
			if(status==1 && !GetRandomInt(0, 5))
			{
				Client[client].Power = engineTime+5.0;
				Client[client].Radio = 1;
				TF2_StunPlayer(client, 9.9, 1.0, TF_STUNFLAGS_NORMALBONK);
				StopSound(client, SNDCHAN_AUTO, SoundList[Sound_096]);
				EmitSoundToAll(SoundList[Sound_Screams], client);
				EmitSoundToAll(SoundList[Sound_Screams], client);
			}
		}
		else if(status == 1)
		{
			Client[client].DisableSpeed = true;
			Client[client].Radio = 1;
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
		}
		else if(status == 2)
		{
			Client[client].DisableSpeed = true;
			Client[client].Radio = 2;
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
			if(GetEntityMoveType(client) != MOVETYPE_WALK)
				SetEntityMoveType(client, MOVETYPE_WALK);
		}
		else
		{
			Client[client].DisableSpeed = false;
			Client[client].Radio = 0;
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
			if(GetEntityMoveType(client) != MOVETYPE_WALK)
				SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
	else if(!IsSCP(client))
	{
		if(!IsSpec(client))
		{
			if(DisarmCheck(client))
			{
				if(showHud)
				{
					SetHudTextParamsEx(-1.0, Gamemode==Gamemode_Ctf ? 0.77 : 0.88, 0.35, ClassColors[Client[Client[client].Disarmer].Class], ClassColors[Client[Client[client].Disarmer].Class], 0, 0.1, 0.05, 0.05);
					ShowSyncHudText(client, HudPlayer, "%T", "disarmed_by", client, Client[client].Disarmer);
				}
			}
			else
			{
				if(Client[client].Power > 0)
				{
					switch(Client[client].Radio)
					{
						case 1:
							Client[client].Power -= 0.005;

						case 2:
							Client[client].Power -= 0.015;

						case 3:
							Client[client].Power -= 0.045;

						case 4:
							Client[client].Power -= 0.135;
					}
				}

				if(showHud)
				{
					SetGlobalTransTarget(client);

					char buffer[256], tran[16];
					if(Client[client].HealthPack == 2)
					{
						if(Client[client].Power>1 && Client[client].Radio && Client[client].Radio<5)
						{
							FormatEx(tran, sizeof(tran), "radio_%d", Client[client].Radio);
							FormatEx(buffer, sizeof(buffer), "%t\n%t", "health_kit", "radio", tran, RoundToCeil(Client[client].Power));
						}
						else
						{
							FormatEx(buffer, sizeof(buffer), "%t", "health_kit");
						}
					}
					else if(Client[client].HealthPack)
					{
						if(Client[client].Power>1 && Client[client].Radio && Client[client].Radio<5)
						{
							FormatEx(tran, sizeof(tran), "radio_%d", Client[client].Radio);
							FormatEx(buffer, sizeof(buffer), "%t\n%t", "pain_killers", "radio", tran, RoundToCeil(Client[client].Power));
						}
						else
						{
							FormatEx(buffer, sizeof(buffer), "%t", "pain_killers");
						}
					}
					else if(Client[client].Power>1 && Client[client].Radio && Client[client].Radio<5)
					{
						FormatEx(tran, sizeof(tran), "radio_%d", Client[client].Radio);
						FormatEx(buffer, sizeof(buffer), "%t", "radio", tran, RoundToCeil(Client[client].Power));
					}

					FormatEx(tran, sizeof(tran), "keycard_%d", Client[client].Keycard);

					SetHudTextParamsEx(-1.0, Gamemode==Gamemode_Ctf ? 0.77 : 0.88, 0.35, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 0.1, 0.05, 0.05);
					ShowSyncHudText(client, HudPlayer, "%t\n%s", "keycard", tran, buffer);
				}
			}
		}
	}

	if(showHud)
	{
		bool found;
		char buffer[32];
		if(Gamemode == Gamemode_Ikea)
		{
			FormatEx(buffer, sizeof(buffer), "class_%d_ikea", Client[client].Class);
			found = TranslationPhraseExists(buffer);
		}

		if(!found)
			FormatEx(buffer, sizeof(buffer), "class_%d", Client[client].Class);

		SetHudTextParamsEx(-1.0, 0.06, 0.35, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 0.1, 0.05, 0.05);
		ShowSyncHudText(client, HudExtra, "%T", buffer, client);
	}

	if(!NoMusic && Client[client].NextSongAt<engineTime)
	{
		int song = GetRandomInt(2, sizeof(MusicList)-1);
		ChangeSong(client, song, MusicTimes[song]+engineTime, MusicList[song]);
		CPrintToChat(client, "%s%t", PREFIX, "now_playing", MusicNames[song]);
	}

	int buttons = GetClientButtons(client);
	#if defined _voiceannounceex_included_
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT)|| (Vaex && IsClientSpeaking(client)))))
	#else
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))))
	#endif
		Client[client].IdleAt = engineTime+3.0;
}

/*public void OnPostThink(int client)
{
	if(!Enabled || IsSpec(client))
	{
		//SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		return;
	}

	if(IsSCP(client))
	{
		//SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		return;
	}

	static float min[3], max[3], pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Send, "m_vecMins", min);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", max);

	TR_TraceHullFilter(pos, pos, min, max, MASK_SOLID, TraceRayPlayerOnly, client);
	if(!TR_DidHit())
	{
		//SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
		return;
	}

	int target = TR_GetEntityIndex();
	//SetEntProp(client, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);
	//SetEntProp(target, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS_TRIGGER);

	static float vel[3], tar[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", tar);

	MakeVectorFromPoints(pos, tar, vel);
	NormalizeVector(vel, vel);
	ScaleVector(vel, -15.0);

	vel[1] += 0.1;
	vel[2] = 0.0;
	SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", vel);
}*/

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_healthkit") != -1)
	{
		SDKHook(entity, SDKHook_Spawn, StrEqual(classname, "item_healthkit_medium") ? OnMedSpawned : OnKitSpawned);
		return;
	}
	else if(Ready && !StrContains(classname, "tf_projectile_"))
	{
		for(int i; i<sizeof(ProjectileList); i++)
		{
			if(!StrEqual(classname, ProjectileList[i], false))
				continue;

			SDKHook(entity, SDKHook_SpawnPost, OnProjSpawned);
			return;
		}
	}
}

public void OnKitSpawned(int entity)
{
	if(IsValidClient(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		return;

	CanTouchAt[entity] = GetEngineTime()+1.0;
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnKitPickup);
}

public void OnMedSpawned(int entity)
{
	if(IsValidClient(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		return;

	CanTouchAt[entity] = GetEngineTime()+2.75;
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnKitPickup);
}

public Action OnKitPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(StrContains(classname, "item_healthkit") == -1)
	{
		SDKUnhook(entity, SDKHook_Touch, OnKitPickup);
		return Plugin_Continue;
	}

	if(IsSCP(client) || Client[client].Disarmer || CanTouchAt[entity]>GetEngineTime())
		return Plugin_Handled;

	if(StrEqual(classname, "item_healthkit_full") || (CanTouchAt[entity]+0.25)>GetEngineTime())
	{
		int health;
		OnGetMaxHealth(client, health);
		if(health <= GetClientHealth(client))
			return Plugin_Handled;

		SDKUnhook(entity, SDKHook_Touch, OnKitPickup);
		return Plugin_Continue;
	}

	if(Client[client].HealthPack)
		return Plugin_Handled;

	Client[client].HealthPack = StrEqual(classname, "item_healthkit_small") ? 1 : 2;
	AcceptEntityInput(entity, "Kill");
	return Plugin_Handled;
}

public Action OnProjSpawned(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(client == -1)
		client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");

	if(!IsValidClient(client))
		return Plugin_Continue;

	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(StrEqual(classname, ProjectileList[0], false))
	{
		SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
		SDKHook(entity, SDKHook_Touch, OnPipeTouch);
	}

	//SetEntProp(entity, Prop_Data, "m_iInitialTeamNum", 0);
	//SetEntProp(entity, Prop_Send, "m_iTeamNum", 0);
	return Plugin_Continue;
}

public Action OnPipeTouch(int entity, int client)
{
	return (IsValidClient(client)) ? Plugin_Handled : Plugin_Continue;
}

// Public Events

public Action CheckAlivePlayers(Handle timer)
{
	if(!Enabled)
		return Plugin_Continue;

	if(Gamemode == Gamemode_Ikea)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsValidClient(i) && !IsSpec(i) && Client[i].Class==Class_DBoi)
				return Plugin_Continue;
		}

		if(DClassEscaped)
		{
			EndRound(Team_MTF);
		}
		else
		{
			EndRound(Team_SCP);
		}
		return Plugin_Continue;
	}

	bool ralive, balive, ealive;
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i) || IsSpec(i))
			continue;

		ralive = (ralive || Client[i].TeamTF()==TFTeam_Red || Client[i].TeamTF()==TFTeam_Unassigned);	// Chaos and SCPs
		ealive = (ealive || Client[i].Class==Class_DBoi || Client[i].Class==Class_Scientist);	// DBois and Scientists
		balive = (balive || Client[i].TeamTF()==TFTeam_Blue);				// Guards and MTF Squads
	}

	if(ealive || (ralive && balive))
		return Plugin_Continue;

	if(SciEscaped && !DClassEscaped)
	{
		EndRound(Team_MTF);
	}
	else if(!SciEscaped && DClassEscaped)
	{
		EndRound(Team_DBoi);
	}
	else if(!SciEscaped && !DClassEscaped)
	{
		EndRound(Team_SCP);
	}
	else
	{
		EndRound(Team_Spec);
	}
	return Plugin_Continue;
}

/*public Action Timer_CheckDoors(Handle timer)
{
	if(!Enabled)
	{
		DoorTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "func_door")) != -1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}*/

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

		bool spec = IsSpec(client);

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

			if(IsSpec(target))
			{
				Client[target].CanTalkTo[client] = (!muted && spec);
				SetListenOverride(client, target, (!blocked && Client[client].CanTalkTo[target]) ? Listen_Default : Listen_No);
				continue;
			}

			if(Client[target].ComFor > engineTime)
			{
				Client[target].CanTalkTo[client] = !muted;
				SetListenOverride(client, target, blocked ? Listen_No : Listen_Default);
				continue;
			}

			if(IsSCP(target))
			{
				if(IsSCP(client))
				{
					Client[target].CanTalkTo[client] = !muted;
					SetListenOverride(client, target, blocked ? Listen_No : Listen_Yes);
					continue;
				}
				else if(Client[target].Class!=Class_049 && Client[target].Class<Class_939)
				{
					Client[target].CanTalkTo[client] = false;
					SetListenOverride(client, target, Listen_No);
					continue;
				}
			}

			static float targetPos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPos);
			int radio = (Client[client].Power<=0 || IsSCP(target) || Client[target].Power<=0) ? 0 : Client[target].Radio;
			if(GetVectorDistance(clientPos, targetPos) < Pow(350.0, 1.0+(radio*0.15)))
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

public void GoToSpawn(int client)
{
	if(Client[client].Class==Class_0492 || !ClassSpawn[Client[client].Class][0])
		return;

	int entity = -1;
	static char name[64];
	static int spawns[32];
	int count;
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, ClassSpawn[Client[client].Class], false))
			spawns[count++] = entity;

		if(count >= sizeof(spawns))
			break;
	}

	if(!count)
	{
		if(IsSCP(client))
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
				TF2_StunPlayer(client, 29.9, 1.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
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

public Action Timer_StartMenuTheme(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(!NoMusic)
		ChangeSong(client, 0, MusicTimes[0]+GetEngineTime(), MusicList[0]);

	DisplayCredits(client);
	return Plugin_Continue;
}

void ChangeSong(int client, int song, float next, const char[] filepath)
{
	if(Client[client].CurrentSong >= 0)
		StopSound(client, SNDCHAN_AUTO, MusicList[Client[client].CurrentSong]);

	Client[client].CurrentSong = song;
	Client[client].NextSongAt = next;
	ClientCommand(client, "playgamesound %s", filepath);
	//if(song < 2)
		//ClientCommand(client, "playgamesound %s", filepath);
}

void ChangeGlobalSong(int song, float next, const char[] filepath)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			ChangeSong(client, song, next, filepath);
	}
}

void DropAllWeapons(int client)
{
	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	if(Client[client].Keycard != Keycard_None)
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
		int entity = CreateEntityByName(Client[client].HealthPack==1 ? "item_healthkit_small" : "item_healthkit_medium");
		if(entity > MaxClients)
		{
			GetClientAbsOrigin(client, origin);
			origin[2] += 20.0;
			DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
			DispatchSpawn(entity);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

			CanTouchAt[entity] = GetEngineTime()+2.0;
			SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
			SDKHook(entity, SDKHook_Touch, OnKitPickup);

			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

void DropCurrentKeycard(int client)
{
	if(Client[client].Keycard == Keycard_None)
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
		if(weapon <= MaxClients)
			continue;

		static char classname[32];
		GetEntityNetClass(weapon, classname, sizeof(classname));
		int offset = FindSendPropInfo(classname, "m_Item");
		if(offset < 0)
		{
			LogError("Failed to find m_Item on: %s", classname);
			break;
		}

		FlagDroppedWeapons(true);

		//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
		int entity = SDKCall(SDKCreateWeapon, -1, origin, angles, KeycardModel[Client[client].Keycard], GetEntityAddress(weapon)+view_as<Address>(offset));

		FlagDroppedWeapons(false);

		if(entity == INVALID_ENT_REFERENCE)
			break;

		DispatchSpawn(entity);
		SDKCall(SDKInitWeapon, entity, client, weapon, swap, false);
		SetEntPropString(entity, Prop_Data, "m_iName", KeycardNames[Client[client].Keycard]);
		//SetVariantInt(KeycardSkin[Client[client].Keycard]);
		//AcceptEntityInput(entity, "Skin");
		break;
	}
}

int GiveWeapon(int client, WeaponEnum weapon, bool ammo=true, int account=-3)
{
	int wep = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(wep > MaxClients)
	{
		if(GetEntProp(wep, Prop_Send, "m_iItemDefinitionIndex") == WeaponIndex[Weapon_None])
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	}

	switch(weapon)
	{
		/*
			Melee Weapons
		*/
		case Weapon_None:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 1, 0, "1 ; 0 ; 252 ; 0.99", _, true);
			if(wep > MaxClients)
			{
				SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(wep, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wep, 255, 255, 255, 0);
			}
		}
		case Weapon_Disarm:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "15 ; 0 ; 138 ; 0 ; 252 ; 0.95");
		}

		/*
			Secondary Weapons
		*/
		case Weapon_Pistol:
		{
			switch(Client[client].Class)
			{
				case Class_Scientist, Class_MTFS:
					TF2_SetPlayerClass(client, TFClass_Engineer, false);

				default:
					TF2_SetPlayerClass(client, TFClass_Scout, false);
			}
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			wep = SpawnWeapon(client, "tf_weapon_pistol", WeaponIndex[weapon], 5, 6, "2 ; 1.5 ; 3 ; 0.75 ; 5 ; 1.25 ; 51 ; 1 ; 96 ; 1.25 ; 106 ; 0.33 ; 252 ; 0.95");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 27, 0);
		}
		case Weapon_SMG:
		{
			TF2_SetPlayerClass(client, TFClass_Sniper, false);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 5, 6, "2 ; 1.4 ; 4 ; 2 ; 5 ; 1.3 ; 51 ; 1 ; 78 ; 2 ; 96 ; 1.25 ; 252 ; 0.95");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 50, 50);
		}
		case Weapon_SMG2:
		{
			TF2_SetPlayerClass(client, TFClass_DemoMan, false);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 10, 6, "2 ; 1.6 ; 4 ; 2 ; 5 ; 1.2 ; 51 ; 1 ; 78 ; 4.6875 ; 96 ; 1.5 ; 252 ; 0.9");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 75, 50);
		}
		case Weapon_SMG3:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					TF2_SetPlayerClass(client, TFClass_Pyro, false);

				case Class_MTF2:
					TF2_SetPlayerClass(client, TFClass_Heavy, false);

				case Class_MTFS:
					TF2_SetPlayerClass(client, TFClass_Engineer, false);

				default:
					TF2_SetPlayerClass(client, TFClass_Soldier, false);
			}
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 20, 6, "2 ; 1.8 ; 4 ; 2 ; 5 ; 1.1 ; 51 ; 1 ; 78 ; 4.6875 ; 96 ; 1.75 ; 252 ; 0.8");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 100, 50);
		}
		case Weapon_SMG4:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					TF2_SetPlayerClass(client, TFClass_Pyro, false);

				case Class_MTF2:
					TF2_SetPlayerClass(client, TFClass_Heavy, false);

				case Class_MTFS:
					TF2_SetPlayerClass(client, TFClass_Engineer, false);

				default:
					TF2_SetPlayerClass(client, TFClass_Soldier, false);
			}
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 30, 6, "2 ; 2 ; 4 ; 2 ; 51 ; 1 ; 78 ; 4.6875 ; 96 ; 2 ; 252 ; 0.7");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 125, 50);
		}
		case Weapon_SMG5:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					TF2_SetPlayerClass(client, TFClass_Pyro, false);

				case Class_MTF2:
					TF2_SetPlayerClass(client, TFClass_Heavy, false);

				case Class_MTFS:
					TF2_SetPlayerClass(client, TFClass_Engineer, false);

				default:
					TF2_SetPlayerClass(client, TFClass_Soldier, false);
			}
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 40, 6, "2 ; 2.2 ; 4 ; 2 ; 6 ; 0.9 ; 51 ; 1 ; 78 ; 4.6875 ; 96 ; 2.25 ; 252 ; 0.6");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 150, 50);
		}

		/*
			Primary Weapons
		*/
		case Weapon_Flash:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			wep = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 5, 6, "1 ; 0.5 ; 3 ; 0.25 ; 15 ; 0 ; 76 ; 0.125 ; 252 ; 0.95 ; 787 ; 1.25", false, true);
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 1, 0);
		}
		case Weapon_Frag:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			wep = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 10, 6, "2 ; 30 ; 3 ; 0.25 ; 28 ; 1.5 ; 76 ; 0.125 ; 138 ; 0.1 ; 252 ; 0.9 ; 671 ; 1 ; 787 ; 1.25", false);
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 1, 0);
		}

		/*
			SCP Weapons
		*/
		case Weapon_049:
		{
			wep = SpawnWeapon(client, "tf_weapon_bonesaw", WeaponIndex[weapon], 80, 13, "1 ; 0.01 ; 137 ; 101 ; 138 ; 1001 ; 252 ; 0.2 ; 535 ; 0.333", false);
		}
		case Weapon_049Gun:
		{
			wep = SpawnWeapon(client, "tf_weapon_medigun", WeaponIndex[weapon], 5, 13, "7 ; 0.7 ; 9 ; 0 ; 18 ; 1 ; 252 ; 0.95", false);
		}
		case Weapon_0492:
		{
			wep = SpawnWeapon(client, "tf_weapon_bat", WeaponIndex[weapon], 50, 13, "1 ; 0.01 ; 5 ; 1.3 ; 28 ; 0.5 ; 137 ; 101 ; 138 ; 151 ; 252 ; 0.5 ; 535 ; 0.333", false);
		}
		case Weapon_096:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			wep = SpawnWeapon(client, "tf_weapon_bottle", WeaponIndex[weapon], 1, 13, "1 ; 0 ; 252 ; 0.99 ; 535 ; 0.333", false);
			if(wep > MaxClients)
			{
				SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(wep, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wep, 255, 255, 255, 0);
			}
		}
		case Weapon_096Rage:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			wep = SpawnWeapon(client, "tf_weapon_sword", WeaponIndex[weapon], 100, 13, "2 ; 101 ; 6 ; 0.5 ; 28 ; 3 ; 252 ; 0", false);
		}
		case Weapon_106:
		{
			wep = SpawnWeapon(client, "tf_weapon_shovel", WeaponIndex[weapon], 60, 13, "1 ; 0.01 ; 15 ; 0 ; 66 ; 0.1 ; 137 ; 11 ; 138 ; 101 ; 252 ; 0.4 ; 535 ; 0.333", false);
		}
		case Weapon_173:
		{
			wep = SpawnWeapon(client, "tf_weapon_knife", WeaponIndex[weapon], 90, 13, "1 ; 0.01 ; 6 ; 0.01 ; 15 ; 0 ; 137 ; 11 ; 138 ; 1001 ; 252 ; 0.1 ; 362 ; 1 ; 535 ; 0.333", false);
		}
		case Weapon_939:
		{
			wep = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 70, 13, "1 ; 0.01 ; 28 ; 0.333 ; 137 ; 101 ; 138 ; 101 ; 252 ; 0.3 ; 535 ; 0.333", false);
		}
		case Weapon_3008:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 1, 13, "1 ; 0 ; 252 ; 0.99 ; 535 ; 0.333", false);
			if(wep > MaxClients)
			{
				SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(wep, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wep, 255, 255, 255, 0);
			}
		}
		case Weapon_3008Rage:
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 100, 13, "2 ; 1.35 ; 28 ; 0.25 ; 252 ; 0.5", false);
		}

		default:
		{
			return -1;
		}
	}

	if(wep > MaxClients)
	{
		TF2Attrib_SetByDefIndex(wep, 214, view_as<float>(weapon));
		if(account == -3)
		{
			SetEntProp(wep, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		}
		else
		{
			SetEntProp(wep, Prop_Send, "m_iAccountID", account);
		}
	}

	return wep;
}

void EndRound(TeamEnum team)
{
	TFTeam team2;
	switch(team)
	{
		case Team_Spec:
			team2 = TFTeam_Unassigned;

		case Team_DBoi:
			team2 = TFTeam_Red;

		case Team_MTF:
			team2 = TFTeam_Blue;

		case Team_SCP:
			team2 = Gamemode==Gamemode_Ikea ? TFTeam_Red : TFTeam_Unassigned;
	}

	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "team_%d", team);
	if(Gamemode == Gamemode_Ikea)
	{
		SetHudTextParamsEx(-1.0, 0.4, 15.0, TeamColors[team], {255, 255, 255, 255}, 1, 10.0, 1.0, 1.0);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client))
				continue;

			SetGlobalTransTarget(client);
			ShowSyncHudText(client, HudIntro, "%t", "end_screen_ikea", buffer, DClassEscaped, DClassMax);
		}
	}
	else
	{
		SetHudTextParamsEx(-1.0, 0.3, 15.0, TeamColors[team], {255, 255, 255, 255}, 1, 10.0, 1.0, 1.0);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client))
				continue;

			SetGlobalTransTarget(client);
			ShowSyncHudText(client, HudIntro, "%t", "end_screen", buffer, DClassEscaped, DClassMax, SciEscaped, SciMax, SCPKilled, SCPMax);
		}
	}

	Enabled = false;
	int entity = FindEntityByClassname(-1, "team_control_point_master");
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

void ShowClassInfo(int client)
{
	Client[client].HudIn = GetEngineTime()+11.0;

	SetGlobalTransTarget(client);

	bool found;
	char buffer[32];
	GetClassName(Client[client].Class, buffer, sizeof(buffer));

	SetHudTextParamsEx(-1.0, 0.3, 10.0, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudExtra, "%t", "you_are", buffer);

	if(Gamemode == Gamemode_Ikea)
	{
		FormatEx(buffer, sizeof(buffer), "desc_%d_ikea", Client[client].Class);
		found = TranslationPhraseExists(buffer);
	}

	if(!found)
		FormatEx(buffer, sizeof(buffer), "desc_%d", Client[client].Class);

	SetHudTextParamsEx(-1.0, 0.5, 10.0, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 1, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudIntro, "%t", buffer);
}

void GetClassName(any class, char[] buffer, int length)
{
	bool found;
	if(Gamemode == Gamemode_Ikea)
	{
		Format(buffer, length, "class_%d_ikea", class);
		found = TranslationPhraseExists(buffer);
	}

	if(!found)
		Format(buffer, length, "class_%d", class);
}

stock int GetClassCount(ClassEnum c)
{
	int a;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && Client[i].Class==c)
			a++;
	}
	return a;
}

bool IsClassTaken(ClassEnum c)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && Client[i].Class==c)
			return true;
	}
	return false;
}

void SetCaptureRate(int client)
{
	if(Gamemode == Gamemode_None)
		return;

	//if(DHGetCaptureValue != null)
		//return;

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

stock int TF2_CreateDroppedWeapon(int client, int weapon, bool swap, const float origin[3], const float angles[3])
{
	static char classname[32];
	GetEntityNetClass(weapon, classname, sizeof(classname));
	int offset = FindSendPropInfo(classname, "m_Item");
	if(offset <= -1)
	{
		LogError("Failed to find m_Item on: %s", classname);
		return -1;
	}

	int index = -1;
	if(HasEntProp(weapon, Prop_Send, "m_iWorldModelIndex"))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex");
	}
	else
	{
		index = GetEntProp(weapon, Prop_Send, "m_nModelIndex");
	}

	if(index < 0)
		return INVALID_ENT_REFERENCE;

	static char model[PLATFORM_MAX_PATH];
	ModelIndexToString(index, model, sizeof(model));

	FlagDroppedWeapons(true);

	//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
	int entity = SDKCall(SDKCreateWeapon, -1, origin, angles, model, GetEntityAddress(weapon)+view_as<Address>(offset));

	FlagDroppedWeapons(false);

	if(entity == INVALID_ENT_REFERENCE)
		return INVALID_ENT_REFERENCE;

	DispatchSpawn(entity);
	SDKCall(SDKInitWeapon, entity, client, weapon, swap, false);
	return entity;
}

bool AttemptGrabItem(int client)
{
	if(IsSpec(client) || Client[client].Disarmer)
		return false;

	int entity = GetClientPointVisible(client);
	if(entity <= MaxClients)
		return false;

	bool oldMan;
	if(IsSCP(client))
	{
		if(Client[client].Class != Class_106)
			return false;

		oldMan = true;
	}

	//SDKCall(SDKTryPickup, client);

	char name[64];
	GetEntityClassname(entity, name, sizeof(name));
	if(StrEqual(name, "tf_dropped_weapon"))
	{
		PickupWeapon(client, entity);
		return true;
	}
	else if(!StrContains(name, "prop_dynamic"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_keycard_", false))
		{
			if(!oldMan)
			{
				char buffers[16][4];
				ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));
				int card = StringToInt(buffers[2]);
				if(card>0 && card<view_as<int>(KeycardEnum) && Client[client].Keycard<view_as<KeycardEnum>(card))
				{
					DropCurrentKeycard(client);
					Client[client].Keycard = view_as<KeycardEnum>(card);
					RemoveEntity(entity);
					return true;
				}
			}
			return false;
		}
		else if(!StrContains(name, "scp_healthkit", false))
		{
			if(!oldMan)
			{
				if(Client[client].HealthPack == 2)
					return true;

				Client[client].HealthPack = 2;
			}

			RemoveEntity(entity);
			return true;
		}
		else if(!StrContains(name, "scp_weapon", false))
		{
			RemoveEntity(entity);

			if(oldMan)
				return true;

			char buffers[16][4];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));
			int index = StringToInt(buffers[2]);
			if(index)
			{
				WeaponEnum wep = Weapon_Disarm;
				for(; wep<Weapon_049; wep++)
				{
					if(index == WeaponIndex[wep])
						break;
				}

				if(wep != Weapon_049)
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
	if(Client[client].Class == Class_106)
	{
		RemoveEntity(entity);
		return;
	}

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
					DropCurrentKeycard(client);
					Client[client].Keycard = view_as<KeycardEnum>(card);
					RemoveEntity(entity);
					return;
				}
			}
		}
	}

	int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	WeaponEnum wep = Weapon_Disarm;
	for(; wep<Weapon_049; wep++)
	{
		if(index == WeaponIndex[wep])
		{
			ReplaceWeapon(client, wep, entity);
			RemoveEntity(entity);
			return;
		}
	}
}

void ReplaceWeapon(int client, WeaponEnum wep, int entity=0, int index=0)
{
	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);

	//Check if client already has weapon in given slot, remove and create dropped weapon if so
	int slot = wep>Weapon_Disarm ? wep<Weapon_Flash ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary : TFWeaponSlot_Melee;
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon > MaxClients)
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(WeaponIndex[wep] == index)
		{
			SpawnPickup(client, "item_ammopack_small");
			return;
		}
		else if(SDKInitWeapon!=null && SDKCreateWeapon!=null && index!=WeaponIndex[Weapon_None])
		{
			GetClientEyePosition(client, origin);
			GetClientEyeAngles(client, angles);
			TF2_CreateDroppedWeapon(client, weapon, true, origin, angles);
		}

		TF2_RemoveWeaponSlot(client, slot);
	}

	if(entity <= MaxClients)
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
		return;
	}

	weapon = GiveWeapon(client, wep, (SDKInitPickup==null && weapon<=MaxClients), GetEntProp(entity, Prop_Send, "m_iAccountID"));
	if(SDKInitPickup!=null && weapon>MaxClients)
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

		//Restore ammo, energy etc from picked up weapon
		SDKCall(SDKInitPickup, entity, client, weapon);

		//If max ammo not calculated yet (-1), do it now
		if(TF2_GetWeaponAmmo(client, weapon) < 0)
		{
			TF2_SetWeaponAmmo(client, weapon, 0);
			TF2_RefillWeaponAmmo(client, weapon);
		}
	}
}

void PrintRandomHintText(int client)
{
	{
		int rand = GetRandomInt(0, 19);
		if(!rand)
		{
			PrintHintText(client, "%T", "redacted", client);
			return;
		}

		if(rand == 1)
		{
			PrintHintText(client, "%T", "data_expunged", client);
			return;
		}
	}

	char buffer[16];
	for(int i; i<sizeof(buffer); i++)
	{
		buffer[i] = Characters[GetRandomInt(0, sizeof(Characters)-1)];
		if(!GetRandomInt(0, 9))
			break;
	}

	PrintHintText(client, buffer);
}

bool DisarmCheck(int client)
{
	if(!Client[client].Disarmer)
		return false;

	if(IsValidClient(Client[client].Disarmer))
	{
		static float pos1[3], pos2[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos1);
		GetEntPropVector(Client[client].Disarmer, Prop_Send, "m_vecOrigin", pos2);

		if(GetVectorDistance(pos1, pos2) < 800)
			return true;
	}

	Client[client].Disarmer = 0;
	return false;
}

stock void FlagDroppedWeapons(bool on)
{
	// CTFDroppedWeapon::Create deletes tf_dropped_weapon if there too many in map, pretend entity is marking for deletion so it doesnt actually get deleted
	int entity = MaxClients+1;
	while((entity = FindEntityByClassname(entity, "tf_dropped_weapon")) > MaxClients)
	{
		int flags = GetEntProp(entity, Prop_Data, "m_iEFlags");
		if(on)
		{
			SetEntProp(entity, Prop_Data, "m_iEFlags", flags|EFL_KILLME);
		}
		else
		{
			flags = flags &= ~EFL_KILLME;
			SetEntProp(entity, Prop_Data, "m_iEFlags", flags);
		}
	}
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

public bool TraceRayPlayerOnly(int client, int mask, any data)
{
	return (client!=data && IsValidClient(client) && IsValidClient(data));
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

public bool Trace_DontHitEntity(int iEntity, int iMask, any iData)
{
	if (iEntity == iData)
		return false;
	
	return true;
}

// DHook Events

public MRESReturn DHook_RoundRespawn()
{
	if(Enabled || !Ready)
		return;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && (GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || IsPlayerAlive(client)))
			ChangeClientTeamEx(client, GetRandomInt(0, 1) ? TFTeam_Blue : TFTeam_Red);
	}

	Enabled = true;
}

public MRESReturn DHook_AllowedToHealTarget(int weapon, Handle returnVal, Handle params)
{
	if(weapon==-1 || DHookIsNullParam(params, 1))
		return MRES_Ignored;

	//int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	int target = DHookGetParam(params, 1);
	if(!IsValidClient(target) || !IsPlayerAlive(target))
		return MRES_Ignored;

	DHookSetReturn(returnVal, false);
	return MRES_ChangedOverride;
}

/*public MRESReturn DHook_CaptureValue(Handle returnVal, Handle params)
{
	int client = DHookGetParam(params, 1);
	bool success;
	if(Client[client].Access(Access_Exit))	// Client has working keycard
	{
		float engineTime = GetEngineTime();
		for(int target=1; target<=MaxClients; target++)
		{
			if(!IsValidClient(target) || IsSpec(target) || (Client[target].Class!=Class_DBoi && Client[target].Class!=Class_Scientist) || Client[client].TeamTF!=Client[target].TeamTF || Client[target].IsCapping<engineTime)
				continue;

			success = true;
			break;
		}
	}

	if(success)
		return MRES_Ignored;

	DHookSetReturn(returnVal, 0);
	return MRES_Supercede;
}

public MRESReturn DHook_ClientWantsLagCompensationOnEntity(int client, Handle returnVal, Handle params)
{
	DHookSetReturn(returnVal, true);
	return MRES_Supercede;
}*/

public MRESReturn DHook_ForceRespawn(int client)
{
	if(!Enabled || Client[client].Class==Class_Spec || Client[client].Respawning>GetGameTime())
		return MRES_Ignored;
	
	return MRES_Supercede;
}

public MRESReturn DHook_SetWinningTeam(Handle params)
{
	if(Enabled)
		return MRES_Supercede;

	DHookSetParam(params, 4, false);
	return MRES_ChangedOverride;
}

/*public MRESReturn DHook_IsInTraining(Address pointer, Handle returnVal)
{
	//Trick the client into thinking the training mode is enabled.
	DHookSetReturn(returnVal, false);
	return MRES_Supercede;
}

public MRESReturn DHook_GetGameType(Address pointer, Handle returnVal)
{
	return MRES_Supercede;
}*/

public MRESReturn DHook_Supercede(int client, Handle params)
{
	//Prevent showing medic bubble over this player's head
	return MRES_Supercede;
}

public MRESReturn DHook_RegenThinkPre(int client, Handle params)
{
	if(TF2_GetPlayerClass(client) == TFClass_Medic)
		TF2_SetPlayerClass(client, TFClass_Unknown);
}

public MRESReturn DHook_RegenThinkPost(int client, Handle params)
{
	if(TF2_GetPlayerClass(client) == TFClass_Unknown)
		TF2_SetPlayerClass(client, TFClass_Medic);
}

public MRESReturn DHook_CanPickupDroppedWeaponPre(int client, Handle returnVal, Handle params)
{
	if(!IsSpec(client) && !IsSCP(client) && !Client[client].Disarmer)
		PickupWeapon(client, DHookGetParam(params, 1));

	DHookSetReturn(returnVal, false);
	return MRES_Supercede;
}

public MRESReturn DHook_DropAmmoPackPre(int client, Handle params)
{
	//Ignore feign death
	if(!DHookGetParam(params, 2) && !IsSpec(client) && !IsSCP(client))
		DropAllWeapons(client);

	//Prevent TF2 dropping anything else
	return MRES_Supercede;
}

// Dev Zone Events

public void Zone_OnClientEntry(int client, char[] zone)
{
	if(!StrContains(zone, "scp_escort", false))
		TF2_AddCondition(client, TFCond_TeleportedGlow, 0.5);
}

// Revive Marker Events

public void OnRevive(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return;

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

	static char classname[MAX_CLASSNAME_LENGTH];
	GetEdictClassname(entity, classname, MAX_CLASSNAME_LENGTH);
	if(!StrEqual(classname, "tf_weapon_medigun"))
		return;

	entity = GetEntPropEnt(entity, Prop_Send, "m_hHealingTarget");
	if(entity <= MaxClients)
		return;

	entity = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	if(!IsValidClient(entity))
		return;

	Client[entity].Class = Class_0492;
	Client[entity].Spawn(entity, true);

	SetEntProp(entity, Prop_Send, "m_bDucked", 1);
	SetEntityFlags(entity, GetEntityFlags(entity)|FL_DUCKING);

	/*static float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);*/
}

public bool SpawnReviveMarker(int client, int team)
{
	int reviveMarker = CreateEntityByName("entity_revive_marker");
	if(reviveMarker == -1)
		return false;

	SetEntPropEnt(reviveMarker, Prop_Send, "m_hOwner", client); // client index 
	SetEntProp(reviveMarker, Prop_Send, "m_nSolidType", 2); 
	SetEntProp(reviveMarker, Prop_Send, "m_usSolidFlags", 8); 
	SetEntProp(reviveMarker, Prop_Send, "m_fEffects", 16); 
	SetEntProp(reviveMarker, Prop_Send, "m_iTeamNum", team); // client team 
	SetEntProp(reviveMarker, Prop_Send, "m_CollisionGroup", 1); 
	SetEntProp(reviveMarker, Prop_Send, "m_bSimulatedEveryTick", 1);
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
			if(TF2_GetClientTeam(client) == TFTeam_Unassigned)
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
	else if(Client[client].ReviveGoneAt < GetEngineTime())
	{
		SDKUnhook(client, SDKHook_PreThink, MarkerThink);
		if(!IsPlayerAlive(client) && TF2_GetClientTeam(client)==TFTeam_Unassigned)
			ChangeClientTeamEx(client, TFTeam_Red);

		int entity = EntRefToEntIndex(Client[client].ReviveIndex);
		if(!IsValidMarker(entity))
			return;

		AcceptEntityInput(entity, "Kill");
		entity = INVALID_ENT_REFERENCE;
		//if(GetClientTeam(client) == 0)
			//ChangeClientTeamEx(client, TFTeam_Red);
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
	
	static char buffer[MAX_CLASSNAME_LENGTH];
	GetEntityClassname(marker, buffer, MAX_CLASSNAME_LENGTH);
	return StrEqual(buffer, "entity_revive_marker", false);
}

// Ragdoll Effects

public void CreateSpecialDeath(int client)
{
	int entity = CreateEntityByName("prop_dynamic_override");
	if(!IsValidEdict(entity))
		return;

	TFClassType class = ClassClassModel[Client[client].Class];
	bool special = (class==TFClass_Engineer || class==TFClass_DemoMan || class==TFClass_Heavy);
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
	DispatchKeyValue(entity, "DefaultAnim", FireDeath[special ? 1 : 0]);	
	{
		float angles[3];
		GetClientEyeAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		DispatchKeyValueVector(entity, "angles", angles);
	}
	DispatchSpawn(entity);
		
	SetVariantString(FireDeath[special ? 1 : 0]);
	AcceptEntityInput(entity, "SetAnimation");

	SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
	AcceptEntityInput(entity, "AddOutput");
	{
		char output[128];
		FormatEx(output, sizeof(output), "OnUser1 !self:KillHierarchy::%f:1", FireDeathTimes[class]+0.1); 
		SetVariantString(output);
		AcceptEntityInput(entity, "AddOutput");
	}
	SetVariantString("");
	AcceptEntityInput(entity, "FireUser1");

	CreateTimer(FireDeathTimes[class], Timer_RemoveEntity, EntIndexToEntRef(entity));

	DataPack pack;
	CreateDataTimer(FireDeathTimes[class]-0.4, CreateRagdoll, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteFloat(pos[0]);
	pack.WriteFloat(pos[1]);
	pack.WriteFloat(pos[2]);
	pack.WriteCell(team);
	pack.WriteCell(Client[client].Class);
}

public Action CreateRagdoll(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(!IsValidClient(client))
		return Plugin_Continue;

	int entity = CreateEntityByName("tf_ragdoll");
	{
		float vec[3];
		vec[0] = -18000.552734;
		vec[1] = -8000.552734;
		vec[2] = 8000.552734;
		SetEntPropVector(entity, Prop_Send, "m_vecRagdollVelocity", vec);
		SetEntPropVector(entity, Prop_Send, "m_vecForce", vec);

		vec[0] = pack.ReadFloat();
		vec[1] = pack.ReadFloat();
		vec[2] = pack.ReadFloat();
		SetEntPropVector(entity, Prop_Send, "m_vecRagdollOrigin", vec);
	}

	SetEntProp(entity, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(entity, Prop_Send, "m_iTeam", pack.ReadCell());

	ClassEnum class = pack.ReadCell();
	SetEntProp(entity, Prop_Send, "m_iClass", view_as<int>(ClassClassModel[class]));

	SetEntProp(entity, Prop_Send, "m_nForceBone", 1);
	DispatchKeyValue(entity, "model", ClassModel[class]);
	DispatchSpawn(entity);

	CreateTimer(15.0, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public void RemoveRagdoll(int client)
{
	int entity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

// Stocks

stock int AttachParticle(int entity, char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%d", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

stock void ChangeClientTeamEx(int client, TFTeam newTeam)
{
	if(SDKTeamAddPlayer==null || SDKTeamRemovePlayer==null)
	{
		TF2_ChangeClientTeam(client, (newTeam==TFTeam_Unassigned) ? TFTeam_Red : newTeam);
		return;
	}

	int currentTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");

	// Safely swap team
	int team = MaxClients+1;
	while((team=FindEntityByClassname(team, "tf_team")) != -1)
	{
		int entityTeam = GetEntProp(team, Prop_Send, "m_iTeamNum");
		if(entityTeam == currentTeam)
		{
			SDKCall(SDKTeamRemovePlayer, team, client);
		}
		else if(entityTeam == view_as<int>(newTeam))
		{
			SDKCall(SDKTeamAddPlayer, team, client);
		}
	}
	SetEntProp(client, Prop_Send, "m_iTeamNum", view_as<int>(newTeam));
}

stock void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	Handle detour = DHookCreateFromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (preCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, false, preCallback))
				LogError("Failed to enable pre detour: %s", name);
		
		if (postCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, true, postCallback))
				LogError("Failed to enable post detour: %s", name);
		
		delete detour;
	}
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}

stock int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
	}
	return 2;
}

stock int GetClientPointVisible(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_ALL, RayType_Infinite, Trace_DontHitEntity, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin) < flDistance)
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

stock void SpawnPickup(int iClient, const char[] sClassname)
{
	float vecOrigin[3];
	GetClientAbsOrigin(iClient, vecOrigin);
	vecOrigin[2] += 16.0;
	
	int iEntity = CreateEntityByName(sClassname);
	DispatchKeyValue(iEntity, "OnPlayerTouch", "!self,Kill,,0,-1");
	if (DispatchSpawn(iEntity))
	{
		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 0, 4);
		TeleportEntity(iEntity, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.15, Timer_RemoveEntity, EntIndexToEntRef(iEntity));
	}
}

stock void DoOverlay(int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0])
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	else
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
}

stock bool IsClassname(int iEntity, const char[] sClassname)
{
	if (iEntity > MaxClients)
	{
		char sClassname2[256];
		GetEntityClassname(iEntity, sClassname2, sizeof(sClassname2));
		return (StrEqual(sClassname2, sClassname));
	}
	
	return false;
}

stock float fabs(float x)
{
	return x<0 ? -x : x;
}

stock float fixAngle(float angle)
{
	int i;
	for(; i<11 && angle<-180; i++)
	{
		angle += 360.0;
	}
	for(; i<11 && angle>180; i++)
	{
		angle -= 360.0;
	}	
	return angle;
}

stock float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

stock bool IsInvuln(int client)
{
	if(!IsValidClient(client))
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock void SetAmmo(int client, int weapon, int ammo=-1, int clip=-1)
{
	if(IsValidEntity(weapon))
	{
		if(clip > -1)
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);

		int ammoType = (ammo>-1 ? GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") : -1);
		if(ammoType != -1)
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
	}
}

stock void TF2_RefillWeaponAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		GivePlayerAmmo(client, 9999, ammotype, true);
}

stock void TF2_SetWeaponAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}

stock int TF2_GetWeaponAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	
	return -1;
}

stock void FadeMessage(int client, int arg1, int arg2, int arg3, int arg4=255, int arg5=255, int arg6=255, int arg7=255)
{
	Handle msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, arg1);
	BfWriteShort(msg, arg2);
	BfWriteShort(msg, arg3);
	BfWriteByte(msg, arg4);
	BfWriteByte(msg, arg5);
	BfWriteByte(msg, arg6);
	BfWriteByte(msg, arg7);
	EndMessage();
}

stock void PrintKeyHintText(int client, const char[] format, any ...)
{
	Handle userMessage = StartMessageOne("KeyHintText", client);
	if(userMessage == INVALID_HANDLE)
		return;

	char buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType")==FeatureStatus_Available && GetUserMessageType()==UM_Protobuf)
	{
		PbSetString(userMessage, "hints", buffer);
	}
	else
	{
		BfWriteByte(userMessage, 1); 
		BfWriteString(userMessage, buffer); 
	}
	
	EndMessage();
}

stock void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att, bool visible=true, bool preserve=false)
{
	if(StrEqual(name, "saxxy", false))	// if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:	ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan:	ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic:	ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper:	ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy:	ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
			default:		ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun", false))	// If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default:		ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
		}
	}

	Handle hWeapon;
	if(preserve)
	{
		hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	}
	else
	{
		hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	}
	if(hWeapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				delete hWeapon;
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	if(entity == -1)
		return -1;

	EquipPlayerWeapon(client, entity);

	if(visible)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	return entity;
}

stock int SpawnWearable(int client, const char[] name, int index, int id)
{
	if(SDKEquipWearable == null)
		return -1;

	int entity = CreateEntityByName(classname);
	if(!IsValidEntity(weapon))
		return -1;

	SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(entity, Prop_Send, "m_bInitialized", 1);

	/*static char netClass[64];
	GetEntityNetClass(wearable, netClass, sizeof(netClass));
	SetEntData(entity, FindSendPropInfo(netClass, "m_iEntityQuality"), 6);
	SetEntData(entity, FindSendPropInfo(netClass, "m_iEntityLevel"), id);*/
	SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
	SetEntProp(entity, Prop_Send, "m_iEntityLevel", id);

	DispatchSpawn(entity);
	SDKCall(SDKEquipWearable, client, wearable);
	return entity;
}

public any Native_GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>=0 && client<MAXTF2PLAYERS)
		return Client[client].Class;

	return Class_Spec;
}

#file "SCP: Secret Fortress"
