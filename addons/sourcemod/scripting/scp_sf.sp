#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <tf2items>
#include <morecolors>
#include <tf2attributes>
#include <dhooks>
#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <voiceannounce_ex>
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
	PrintToConsole(i, "Revive Markers | SHADoW NiNE TR3S, sarysa | forums.alliedmods.net/showthread.php?t=248320");

	PrintToConsole(i, "Chaos, SCP-049-2 | DoctorKrazy | forums.alliedmods.net/member.php?u=288676");
	PrintToConsole(i, "MTF, SCP-049, SCP-096 | JuegosPablo | forums.alliedmods.net/showthread.php?t=308656");
	PrintToConsole(i, "SCP-173 | RavensBro | forums.alliedmods.net/showthread.php?t=203464");
	PrintToConsole(i, "SCP-106 | Spyer | forums.alliedmods.net/member.php?u=272596");

	PrintToConsole(i, "Cosmic Inspiration | Marxvee | forums.alliedmods.net/member.php?u=289257");
	PrintToConsole(i, "Map/Model Development | Artvin | steamcommunity.com/id/laz_boyx");
}

#define MAJOR_REVISION	"1"
#define MINOR_REVISION	"3"
#define STABLE_REVISION	"5"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

// I'm cheating yayy
#define IsSCP(%1)	(Client[%1].Class>=Class_049)
#define IsSpec(%1)	(Client[%1].Class==Class_Spec || !IsPlayerAlive(%1) || TF2_IsPlayerInCondition(%1, TFCond_HalloweenGhostMode))

#define FAR_FUTURE	100000000.0
#define MAXTF2PLAYERS	36
#define MAXANGLEPITCH	45.0
#define MAXANGLEYAW	90.0
#define MAXTIME		898

#define PREFIX		"{red}[SCP]{default} "
#define KEYCARD_MODEL	"models/scp_sl/keycard.mdl"
#define DOWNLOADS	"configs/scp_sf/downloads.txt"

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
	"#scpsl/music/mainmenu.mp3",		// Main Menu Theme (Reserved for join sound)
	"#scpsl/music/wegottarun.mp3",		// We Gotta Run (Reserved for Alpha Warhead)
	"#scpsl/music/melancholy.mp3",		// Melancholy
	"#scpsl/music/unexplainedbehaviors.mp3",// Unexplained Behaviors
	"#scpsl/music/doctorlab.mp3",		// Doctor Lab
	"#scpsl/music/massivelabyrinth.mp3",	// Massive Labyrinth
	"#scpsl/music/forgetaboutyourfears.mp3"	// Forget About Your Fears
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
	Sound_ChaosSpawn,

	Sound_ItSteps,
	Sound_ItRages,
	Sound_ItHadEnough,
	Sound_ItStuns,
	Sound_ItKills
}

static const char SoundList[][] =
{
	//"scpsl/096/effect_loop.wav",			// SCP-096 Passive
	"freak_fortress_2/scp096/bgm.mp3",		// SCP-096 Passive
	"freak_fortress_2/scp096/fullrage.mp3",		// SCP-096 Rage
	"freak_fortress_2/scp173/scp173_kill2.mp3",	// SCP-173 Kill
	"freak_fortress_2/scp173/scp173_mtf_spawn.mp3",	// MTF Spawn
	"freak_fortress_2/scp-049/red_backup1.mp3",	// Chaos Spawn

	"scpsl/it_steals/monster_step.wav",		// Stealer Step Noise
	"scpsl/it_steals/enraged.mp3",		// Stealer First Rage
	"scpsl/it_steals/youhadyourchance.mp3",	// Stealer Second Rage
	"scpsl/it_steals/stunned.mp3",		// Stealer Stunned
	"scpsl/it_steals/deathcam.mp3"		// Player Killed
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

// entity effects
enum
{
	EF_BONEMERGE			= 0x001,	// Performs bone merge on client side
	EF_BRIGHTLIGHT 			= 0x002,	// DLIGHT centered at entity origin
	EF_DIMLIGHT 			= 0x004,	// player flashlight
	EF_NOINTERP				= 0x008,	// don't interpolate the next frame
	EF_NOSHADOW				= 0x010,	// Don't cast no shadow
	EF_NODRAW				= 0x020,	// don't draw entity
	EF_NORECEIVESHADOW		= 0x040,	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= 0x080,	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK			= 0x100,	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES		= 0x200,	// always assume that the parent entity is animating
	EF_MAX_BITS = 10
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

static const char Characters[] = "abcdefghijklmnopqrstuvwxyzABDEFGHIJKLMNOQRTUVWXYZ~`1234567890@#$^&*(){}:[]|¶�;<>.,?/'|";

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
	Class_1732,
	Class_939,
	Class_9392,
	Class_3008,
	Class_Stealer
}

static const char ClassShort[][] =
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

	"049",
	"0492",
	"079",
	"096",
	"106",
	"173",
	"1732",
	"939",
	"9392",
	"3008",
	"itsteals"
};

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

	"darkred",	// 049
	"red",		// 049-2
	"darkred",	// 079
	"darkred",	// 096
	"darkred",	// 106
	"darkred",	// 173
	"darkred",	// 173
	"darkred",	// 939
	"darkred",	// 939
	"darkred",	// 3008
	"black"		// It Steals
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
	{ 189, 0, 0, 255 },
	{ 189, 0, 0, 255 },
	{ 0, 0, 0, 255}
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
	"scp_spawn_173",
	"scp_spawn_939",
	"scp_spawn_939",
	"scp_spawn_p",
	"scp_spawn_p"
};

static const char ClassModel[][] =
{
	"models/empty.mdl",	// Spec

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
	"models/freak_fortress_2/scp_173/scp_173new.mdl",	// 173-2
	"models/scp_sl/scp_939/scp_939_redone_pm.mdl",		// 939-89
	"models/scp_sl/scp_939/scp_939_redone_pm.mdl",		// 939-53
	"models/freak_fortress_2/scp-049/zombie049.mdl",	// 3008-2
	"models/freak_fortress_2/it_steals/it_steals_v39.mdl"	// Stealer
};

static const char ClassModelSub[][] =
{
	"models/empty.mdl",	// Spec

	"models/player/scout.mdl",	// DBoi
	"models/player/sniper.mdl",	// Chaos

	"models/player/medic.mdl",	// Sci
	"models/player/sniper.mdl",	// Guard
	"models/player/soldier.mdl",	// MTF 1
	"models/player/soldier.mdl",	// MTF 2
	"models/player/soldier.mdl",	// MTF S
	"models/player/soldier.mdl",	// MTF 3

	"models/player/medic.mdl",	// 049
	"models/player/spy.mdl",	// 049-2
	"models/player/engineer.mdl", 	// 079
	"models/player/demo.mdl",	// 096
	"models/player/soldier.mdl",	// 106
	"models/player/heavy.mdl",	// 173
	"models/player/heavy.mdl",	// 173
	"models/player/pyro.mdl",	// 939-89
	"models/player/pyro.mdl",	// 939-53
	"models/player/sniper.mdl",	// 3008-2
	"models/freak_fortress_2/it_steals/it_steals_v39.mdl"	// Stealer
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
	TFClass_Heavy,		// 173-2
	TFClass_Pyro,		// 939-89
	TFClass_Pyro,		// 939-53
	TFClass_Sniper,		// 3008-2
	TFClass_Spy		// Stealer
};

static const TFClassType ClassClassModel[] =
{
	TFClass_Unknown,		// Spec

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
	TFClass_Unknown,	// 173
	TFClass_Unknown,	// 173-2
	TFClass_Pyro,		// 939-89
	TFClass_Pyro,		// 939-53
	TFClass_Sniper,		// 3008-2
	TFClass_Unknown		// Stealer
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
	Keycard_106 = -2,
	Keycard_SCP = -1,

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

static const int KeycardSkin[] =
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

	{ Keycard_Chaos, Keycard_MTF3, Keycard_O5 },
	{ Keycard_Engineer, Keycard_O5, Keycard_O5 }
};

/*static const char KeycardModel[][] =
{
	"models/empty.mdl",

	"models/props/sl/keycardj.mdl",
	"models/props/sl/keycardbs.mdl",

	"models/props/sl/keycardzm.mdl",
	"models/props/sl/keycardms.mdl",

	"models/props/sl/keycardbg.mdl",
	"models/props/sl/keycardsg.mdl",
	"models/props/sl/keycardlt.mdl",
	"models/props/sl/keycardcg.mdl",

	"models/props/sl/keycarden.mdl",
	"models/props/sl/keycardfm.mdl",

	"models/empty.mdl",
	"models/props/sl/keycard5.mdl",
};*/

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

	Weapon_Axe,
	Weapon_Hammer,
	Weapon_Knife,
	Weapon_Bash,
	Weapon_Meat,
	Weapon_Wrench,
	Weapon_Pan,

	Weapon_Disarm,

	Weapon_Pistol,
	Weapon_SMG,		// Guard
	Weapon_SMG2,		// MTF
	Weapon_SMG3,		// MTF2
	Weapon_SMG4,		// Chaos
	Weapon_SMG5,		// MTF3

	Weapon_Flash,
	Weapon_Frag,
	Weapon_Micro,

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

	Weapon_Stealer
}

static const int WeaponIndex[] =
{
	5,

	192,
	153,
	30758,
	325,
	1013,
	197,
	264,

	954,

	209,
	751,
	1150,
	425,
	415,
	1153,

	1151,
	308,
	594,

	173,
	35,
	572,

	195,
	154,

	939,
	195,
	326,

	195,
	195,

	574
};

enum GamemodeEnum
{
	Gamemode_None,	// SCP dedicated map
	Gamemode_Ikea,	// SCP-3008-2 map
	Gamemode_Nut,	// SCP-173 infection map
	Gamemode_Steals,// It Steals spin-off map
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
bool CollisionHook = false;	// CollisionHook

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
//Handle DHShouldCollide;
//Handle DHLagCompensation;
//Handle DHForceRespawn;
//Handle DoorTimer = INVALID_HANDLE;

ConVar CvarQuickRounds;

GlobalForward GFOnEscape;

GamemodeEnum Gamemode = Gamemode_None;

int ClassModelIndex[sizeof(ClassModel)];
int ClassModelSubIndex[sizeof(ClassModelSub)];
bool ClassEnabled[view_as<int>(ClassEnum)];

int DClassEscaped;
int DClassMax;
int SciEscaped;
int SciMax;
int SCPKilled;
int SCPMax;

enum struct ClientEnum
{
	ClassEnum Class;
	//TeamEnum Team;
	KeycardEnum Keycard;

	bool IsVip;
	bool Triggered;
	bool CustomHitbox;
	bool CanTalkTo[MAXTF2PLAYERS];

	int HealthPack;
	int Radio;
	int Disarmer;
	int DownloadMode;

	float Power;
	float IdleAt;
	float ComFor;
	float IsCapping;
	float InvisFor;
	float Respawning;
	float ChatIn;
	float HudIn;
	float ChargeIn;
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

			if(this.Class<Class_Scientist || this.Class>=Class_049)
				return TFTeam_Red;

			return TFTeam_Blue;
		}

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

			if(Gamemode!=Gamemode_Steals && IsClassTaken(Class_Scientist) && !GetRandomInt(0, 2))
			{
				this.Class = Class_Guard;
				return Class_Guard;
			}

			this.Class = Class_Scientist;
			return Class_Scientist;
		}

		if(team == TFTeam_Red)
		{
			if(Gamemode!=Gamemode_Steals && Gamemode!=Gamemode_Ikea)
			{
				if(!bot && IsClassTaken(Class_DBoi) && GetRandomInt(0, 1))
				{
					ClassEnum class = view_as<ClassEnum>(GetRandomInt(view_as<int>(Class_049), view_as<int>(ClassEnum)-1));
					if(ClassEnabled[class] && !IsClassTaken(class))
					{
						this.Class = class;
						return class;
					}
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
	CvarQuickRounds = CreateConVar("scp_quickrounds", "1", "If to end the round if winning outcome can no longer be changed", _, true, 0.0, true, 1.0);

	HookEvent("arena_round_start", OnRoundReady, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeathPost, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", OnCapturePoint, EventHookMode_Pre);
	HookEvent("teamplay_flag_event", OnCaptureFlag, EventHookMode_Pre);
	HookEvent("teamplay_win_panel", OnWinPanel, EventHookMode_Pre);
	HookEvent("revive_player_complete", OnRevive);

	RegConsoleCmd("sm_scp", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scpinfo", Command_HelpClass, "View info about your current class");
	RegConsoleCmd("scp_info", Command_HelpClass, "View info about your current class");

	RegAdminCmd("scp_forceclass", Command_ForceClass, ADMFLAG_SLAY, "Usage: scp_forceclass <target> <class>.  Forces that class to be played.");
	RegAdminCmd("scp_giveweapon", Command_ForceWeapon, ADMFLAG_SLAY, "Usage: scp_giveweapon <target> <id>.  Gives a specific weapon.");
	RegAdminCmd("scp_givekeycard", Command_ForceCard, ADMFLAG_SLAY, "Usage: scp_givekeycard <target> <id>.  Gives a specific keycard.");

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

		DHSetWinningTeam = DHookCreate(gamedata.GetOffset("CTFGameRules::SetWinningTeam"), HookType_GameRules, ReturnType_Void, ThisPointer_Ignore);
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

		//DHForceRespawn = DHookCreateFromConf(gamedata, "CTFPlayer::ForceRespawn");
		//if(DHForceRespawn == null)
			//LogError("[Gamedata] Could not find CTFPlayer::ForceRespawn");

		DHRoundRespawn = DHookCreateFromConf(gamedata, "CTeamplayRoundBasedRules::RoundRespawn");
		if(DHRoundRespawn == null)
			LogError("[Gamedata] Could not find CTFPlayer::RoundRespawn");

		/*DHShouldCollide = DHookCreate(gamedata.GetOffset("ILocomotion::ShouldCollideWith"), HookType_Raw, ReturnType_Bool, ThisPointer_Address, DHook_ShouldCollideWith);
		if(DHShouldCollide == null)
		{
			LogError("[Gamedata] Could not find ILocomotion::ShouldCollideWith!");
		}
		else
		{
			DHookAddParam(DHShouldCollide, HookParamType_CBaseEntity);
		}*/

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
	Enabled = false;
	Ready = false;

	for(int i; i<sizeof(MusicList); i++)
	{
		PrecacheSoundEx(MusicList[i], true);
	}

	for(int i; i<sizeof(SoundList); i++)
	{
		PrecacheSoundEx(SoundList[i], true);
	}

	for(int i; i<sizeof(ClassModel); i++)
	{
		ClassModelIndex[i] = PrecacheModelEx(ClassModel[i], true);
	}

	for(int i; i<sizeof(ClassModelSub); i++)
	{
		ClassModelSubIndex[i] = PrecacheModel(ClassModelSub[i], true);
	}

	PrecacheModelEx(KEYCARD_MODEL, true);

	static char buffer[PLATFORM_MAX_PATH];
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

		ClassEnabled[Class_049] = StrContains(buffer, " 049", false)!=-1;
		ClassEnabled[Class_079] = StrContains(buffer, " 079", false)!=-1;
		ClassEnabled[Class_096] = StrContains(buffer, " 096", false)!=-1;
		ClassEnabled[Class_106] = StrContains(buffer, " 106", false)!=-1;
		ClassEnabled[Class_173] = StrContains(buffer, " 173", false)!=-1;
		ClassEnabled[Class_1732] = StrContains(buffer, " 1732", false)!=-1;
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

	if(DHSetWinningTeam != null)
		DHookGamerules(DHSetWinningTeam, false, _, DHook_SetWinningTeam);

	if(DHRoundRespawn != null)
		DHookGamerules(DHRoundRespawn, false, _, DHook_RoundRespawn);
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
}

public void OnClientPostAdminCheck(int client)
{
	Client[client].DownloadMode = 0;
	Client[client].NextSongAt = FAR_FUTURE;
	Client[client].Class = Class_Spec;
	Client[client].IsVip = (CheckCommandAccess(client, "thisguyisavipiguess", ADMFLAG_RESERVATION, true) || CheckCommandAccess(client, "thisguyisaadminiguess", ADMFLAG_GENERIC, true));

	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	//SDKHook(client, SDKHook_ShouldCollide, OnCollide);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
	SDKHook(client, SDKHook_PreThink, OnPreThink);

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

		Client[client].NextSongAt = FAR_FUTURE;
		if(!Client[client].CurrentSong[0])
			continue;

		StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
		StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
		Client[client].CurrentSong[0] = 0;
	}

	UpdateListenOverrides(FAR_FUTURE);

	/*for(int entity=2047; entity>MaxClients; entity++)
	{
		if(!IsValidEntity(entity))
			continue;

		
	}*/
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!Ready)
		return;

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
			GoToSpawn(client, GetRandomInt(0, 2) ? Class_0492 : Class_106);
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

		char buffer[64];
		if(Client[client].Cooldown > GetEngineTime())
		{
			Menu menu = new Menu(Handler_None);
			menu.SetTitle("%T", "scp_914", client);

			FormatEx(buffer, sizeof(buffer), "%T", "in_cooldown", client);
			menu.AddItem("0", buffer);
			menu.ExitButton = false;
			menu.Display(client, 5);
		}
		else
		{
			Menu menu = new Menu(Handler_Upgrade);
			menu.SetTitle("%T", "scp_914", client);

			if(Client[client].Keycard > Keycard_None)
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
			else
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

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+10.0;

					wep -= view_as<WeaponEnum>(2);
					if(wep<Weapon_Pistol || GetRandomInt(0, 1))
					{
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

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+12.5;

					wep--;
					if(wep < Weapon_Pistol)
					{
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
					for(; wep<=Weapon_SMG5; wep++)
					{
						if(index == WeaponIndex[wep])
							break;
					}

					if(wep > Weapon_SMG5)
						return;

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+17.5;

					wep++;
					if(wep > Weapon_SMG5)
						wep = Weapon_SMG5;

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

					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					Client[client].Cooldown = GetEngineTime()+20.0;
					if(GetRandomInt(0, 1))
					{
						if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)<=MaxClients && GetPlayerWeaponSlot(client, TFWeaponSlot_Primary)<=MaxClients)
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));

						return;
					}

					wep += view_as<WeaponEnum>(2);
					if(wep > Weapon_SMG5)
						wep = Weapon_SMG5;

					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, wep));
				}
			}
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond cond)
{
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
		TF2_RemoveAllWeapons(client);
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
		AssignTeam(client);
		RespawnPlayer(client);
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(Client[client].Class == Class_Scientist)
	{
		DropAllWeapons(client);
		TF2_RemoveAllWeapons(client);
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
		AssignTeam(client);
		RespawnPlayer(client);
		CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
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

		TF2_SetPlayerClass(client, ClassClass[Client[client].Class]);

		if(team != TFTeam_Spectator)
			ChangeClientTeamEx(client, team);
	}

	Client[client].CustomHitbox = false;
	Client[client].Triggered = false;
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
			if(Gamemode == Gamemode_Steals)
			{
				TurnOnFlashlight(client);
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			}

			Client[client].Radio = Gamemode==Gamemode_Steals ? 2 : 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
		}
		case Class_Chaos:
		{
			Client[client].Keycard = Keycard_Chaos;
			Client[client].HealthPack = 2;
			Client[client].Radio = 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG4));
		}
		case Class_Scientist:
		{
			Client[client].Keycard = Keycard_Scientist;
			Client[client].HealthPack = Gamemode==Gamemode_Steals ? 0 : 2;
			if(Gamemode == Gamemode_Steals)
			{
				TurnOnFlashlight(client);
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			}

			Client[client].Radio = Gamemode==Gamemode_Steals ? 2 : 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));
		}
		case Class_Guard:
		{
			Client[client].Keycard = Keycard_Guard;
			Client[client].HealthPack = 0;
			Client[client].Radio = 1;
			GiveWeapon(client, Weapon_Flash);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG));
			GiveWeapon(client, Weapon_Disarm);
		}
		case Class_MTF:
		{
			Client[client].Keycard = Keycard_MTF;
			Client[client].HealthPack = 0;
			Client[client].Radio = 1;
			GiveWeapon(client, Weapon_Flash);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG2));
		}
		case Class_MTF2, Class_MTFS:
		{
			Client[client].Keycard = Keycard_MTF2;
			Client[client].HealthPack = Client[client].Class==Class_MTFS ? 2 : 1;
			Client[client].Radio = 1;
			GiveWeapon(client, Weapon_Frag);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG3));
			if(Gamemode != Gamemode_Ikea)
				GiveWeapon(client, Weapon_Disarm);
		}
		case Class_MTF3:
		{
			Client[client].Keycard = Keycard_MTF3;
			Client[client].HealthPack = 1;
			Client[client].Radio = 1;
			GiveWeapon(client, Weapon_Frag);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_SMG5));
			if(Gamemode != Gamemode_Ikea)
				GiveWeapon(client, Weapon_Disarm);
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
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_0492));
		}
		case Class_096:
		{
			Client[client].Pos[0] = 0.0;
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 750;
			Client[client].Radio = 0;
			SetEntityHealth(client, 750);
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
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_106));
		}
		case Class_173:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_173));
		}
		case Class_1732:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_173));
		}
		case Class_939, Class_9392:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_939));
		}
		case Class_3008:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = SciEscaped;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, SciEscaped ? Weapon_3008Rage : Weapon_3008));
		}
		case Class_Stealer:
		{
			Client[client].Keycard = Keycard_SCP;
			Client[client].HealthPack = 0;
			Client[client].Radio = 0;
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_Stealer));
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		default:
		{
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade, TFCondDuration_Infinite);
			TF2_AddCondition(client, TFCond_HalloweenGhostMode, TFCondDuration_Infinite);

			SetVariantString(ClassModel[Class_Spec]);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);

			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelIndex[Class_Spec], _, 0);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelSubIndex[Class_Spec], _, 3);

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

	//if(!TF2_HasGlow(client))
		//TF2_CreateGlow(client);

	ShowClassInfo(client);
	SetCaptureRate(client);
	SetVariantString(ClassModel[Client[client].Class]);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	TF2Attrib_SetByDefIndex(client, 49, 1.0);
	TF2Attrib_SetByDefIndex(client, 69, 0.0);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);

	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelIndex[Client[client].Class], _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelSubIndex[Client[client].Class], _, 3);

	if(Client[client].Class==Class_939 || Client[client].Class==Class_9392)
	{
		//CreateCustomModel(client);
		//SetVariantVector3D(view_as<float>({0.75, 0.75, 0.75}));
		//AcceptEntityInput(client, "SetModelScale");
	}

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
		ChangeClientTeam(client, 3);

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
			for(WeaponEnum wep=Weapon_Axe; wep<Weapon_049; wep++)
			{
				if(index != WeaponIndex[wep])
					continue;

				TF2_CreateDroppedWeapon(client, entity, true, origin, angles);
				int slot = wep>Weapon_Disarm ? wep<Weapon_Flash ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary : TFWeaponSlot_Melee;
				TF2_RemoveWeaponSlot(client, slot);
				if(GetPlayerWeaponSlot(client, slot)<=MaxClients && (slot==TFWeaponSlot_Melee || GetPlayerWeaponSlot(client, TFWeaponSlot_Melee)<=MaxClients))
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_None));

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
	if(msg[1] == '/')
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
	else
	{
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
				CPrintToChat(target, "%s%s {default}: %s", GetVectorDistance(clientPos, targetPos)<350 ? "" : "*RADIO* ", name, msg);
			}
		}
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
		AssignTeam(targets[target]);
		RespawnPlayer(targets[target]);
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

	for(int target; target<matches; target++)
	{
		if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			ReplaceWeapon(targets[target], view_as<WeaponEnum>(weapon));
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

	for(int target; target<matches; target++)
	{
		if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
		{
			DropCurrentKeycard(targets[target]);
			Client[targets[target]].Keycard = view_as<KeycardEnum>(card);
		}
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
				CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, "gray", "tesla_gate");
			}
			else if(damage & DMG_NERVEGAS)
			{
				CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, "gray", "femur_breaker");
			}
			else if(damage & DMG_BLAST)
			{
				CPrintToChatAll("%s%t", PREFIX, "scp_killed", ClassColor[Client[client].Class], class1, "gray", "alpha_warhead");
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
			RequestFrame(CreateSpecialDeath, client);
		}
		return Plugin_Handled;
	}

	switch(Client[attacker].Class)
	{
		case Class_049:
		{
			if(GetEntityFlags(client) & FL_ONGROUND)
			{
				RequestFrame(RemoveRagdoll, client);
				CreateSpecialDeath(client);
			}
			ChangeClientTeamEx(client, view_as<TFTeam>(GetClientTeam(attacker)));
			SpawnReviveMarker(client, GetClientTeam(attacker));
		}
		case Class_173:
		{
			EmitSoundToAll(SoundList[Sound_Snap], client, SNDCHAN_BODY, SNDLEVEL_TRAIN, _, _, _, client);
		}
		case Class_Stealer:
		{
			ClientCommand(client, "playgamesound %s", SoundList[Sound_ItKills]);
		}
	}
	return Plugin_Handled;
}

public void OnPlayerDeathPost(Event event, const char[] name, bool dontBroadcast)
{
	UpdateListenOverrides(GetEngineTime());
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
				Client[client].ChargeIn = engineTime+10.0;
			}
			else if(Client[client].ChargeIn < engineTime)
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
			}
			else
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", (engineTime-Client[client].ChargeIn)*9.9);

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
			Client[client].Sprinting = (Client[client].SprintPower>15 && (GetEntityFlags(client) & FL_ONGROUND));

		if(Gamemode == Gamemode_Steals)
		{
			buttons &= ~IN_JUMP;
			changed = true;
		}
	}
	else
	{
		Client[client].Sprinting = false;
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

	if(holding[client])
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
		if(!(ticks % 180))
		{
			switch(Gamemode)
			{
				case Gamemode_Ikea:
				{
					if(SciEscaped)
					{
						SciEscaped = 0;

						int count;
						static int choosen[MAXTF2PLAYERS];
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
						static int choosen[MAXTF2PLAYERS];
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
						static int choosen[MAXTF2PLAYERS];
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

							count = 0;
							for(int client=1; client<=MaxClients; client++)
							{
								if(!IsValidClient(client))
									continue;

								ChangeSong(client, engineTime+20.0, SoundList[Sound_MTFSpawn], false);
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

							if(!IsSpec(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
								continue;

							Client[client].Class = Class_Chaos;
							AssignTeam(client);
							RespawnPlayer(client);
							hasSpawned = true;
						}

						if(hasSpawned)
							ChangeGlobalSong(engineTime+20.0, SoundList[Sound_ChaosSpawn], false);
					}
				}
			}
		}
		else if(!(ticks % 60))
		{
			DisplayHint(false);
		}
		else if(Gamemode>=Gamemode_Arena || Gamemode==Gamemode_Ikea)
		{
			if(!NoMusic && ticks==RoundFloat(MAXTIME-MusicTimes[1]))
			{
				ChangeGlobalSong(engineTime+15.0+MusicTimes[1], MusicList[1]);
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

						FadeMessage(client, 36, 1536, 0x0012, 255, 228, 200, 228);
						FadeClientVolume(client, 1.0, 4.0, 4.0, 0.2);
					}
					EndRound(Team_Spec, TFTeam_Unassigned);
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

	float engineTime = GetEngineTime();
	if(Client[victim].InvisFor > engineTime)
		return Plugin_Handled;

	if(!IsValidClient(attacker))
	{
		if(damagetype & DMG_FALL)
		{
			if(Client[victim].Class==Class_173 || Client[victim].Class==Class_1732)
				return Plugin_Handled;

			//damage = IsSCP(victim) ? damage*0.01 : Pow(damage, 1.25);
			damage = IsSCP(victim) ? damage*0.02 : damage*5.0;
			return Plugin_Changed;
		}
		else if(damagetype & DMG_CRUSH)
		{
			//static float delay[MAXTF2PLAYERS];
			//if(delay[victim] > engineTime)
				return Plugin_Handled;

			//delay[victim] = engineTime+0.05;
			//return Plugin_Continue;
		}
		return Plugin_Continue;
	}

	if(victim!=attacker && !IsFakeClient(victim))
	{
		if(IsFriendly(Client[victim].Class, Client[attacker].Class))
			return Plugin_Handled;

		if(Client[victim].Class == Class_096)
		{
			if(!Client[attacker].Triggered && !TF2_IsPlayerInCondition(victim, TFCond_Dazed))
				TriggerShyGuy(victim, attacker, engineTime);
		}
		else if(Client[victim].Class==Class_939 || Client[victim].Class==Class_9392)
		{
			
			return Plugin_Handled;
		}
		else if(Client[victim].Class==Class_3008 && !Client[victim].Radio)
		{
			Client[victim].Radio = 1;
			TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Melee);
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
				return Plugin_Handled;
			}
		}
		else if(index == WeaponIndex[Weapon_Flash])
		{
			FadeMessage(victim, 36, 768, 0x0012);
			FadeClientVolume(victim, 1.0, 2.0, 2.0, 0.2);
		}
	}

	switch(Client[attacker].Class)
	{
		case Class_106:
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
		case Class_Stealer:
		{
			if(Client[victim].Triggered)
				return Plugin_Handled;
		}
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
	if(!Enabled || !IsValidClient(entity))
		return Plugin_Continue;

	if(!StrContains(sample, "vo", false))
		return (IsSCP(entity) || IsSpec(entity)) ? Plugin_Handled : Plugin_Continue;

	if(StrContains(sample, "step", false) != -1)
	{
		if(IsSCP(entity) || Client[entity].Sprinting)
		{
			if(Client[entity].Class == Class_Stealer)
				strcopy(sample, PLATFORM_MAX_PATH, SoundList[Sound_ItSteps]);

			volume = 1.0;
			level += 30;
			return Plugin_Changed;
		}

		if(Gamemode == Gamemode_Steals)
			return Plugin_Stop;

		int flag = GetEntityFlags(entity);
		if((flag & FL_DUCKING) && (flag & FL_ONGROUND))
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action OnTransmit(int client, int target)
{
	if(!Enabled || client==target || !IsValidClient(target) || IsClientObserver(target) || TF2_IsPlayerInCondition(target, TFCond_HalloweenGhostMode))
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return Plugin_Handled;

	float engineTime = GetEngineTime();
	if(Client[client].InvisFor > engineTime)
		return Plugin_Handled;

	if(IsSCP(client))
		return Plugin_Continue;

	if(Client[target].Class == Class_096)
		return (!Client[target].Radio || Client[client].Triggered) ? Plugin_Continue : Plugin_Handled;

	if(Client[target].Class == Class_Stealer)
		return Client[client].Triggered ? Plugin_Handled : Plugin_Continue;

	return ((Client[target].Class==Class_939 || Client[target].Class==Class_9392 || (Client[target].Class==Class_3008 && !Client[target].Radio)) && Client[client].IdleAt<engineTime) ? Plugin_Handled : Plugin_Continue;
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
			health = Client[client].HealthPack + (Client[client].Disarmer*250);

			int current = GetClientHealth(client);
			if(current > health)
			{
				SetEntityHealth(client, health);
			}
			else if(current < Client[client].HealthPack-250)
			{
				Client[client].HealthPack = current+250;
			}
		}
		case Class_106:
		{
			health = 800; //812.5
		}
		case Class_173:
		{
			health = 4000;
		}
		case Class_1732:
		{
			health = 800;
		}
		case Class_939, Class_9392:
		{
			health = 2750;
		}
		case Class_3008:
		{
			health = 500;
		}
		case Class_Stealer:
		{
			switch(Client[client].Radio)
			{
				case -1:
				{
					health = ((DClassMax+SciMax)*2)+6;
					SetEntityHealth(client, 1);
				}
				case 1:
				{
					health = 66;
					SetEntityHealth(client, 66);
				}
				case 2:
				{
					health = 666;
					SetEntityHealth(client, 666);
				}
				default:
				{
					if(SciEscaped < -1)
					{
						ForcePlayerSuicide(client);

						for(int i=1; i<=MaxClients; i++)
						{
							if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==view_as<int>(TFTeam_Red))
								ChangeClientTeamEx(i, TFTeam_Blue);
						}

						EndRound(Team_MTF, TFTeam_Blue);
						return Plugin_Continue;
					}

					health = ((DClassMax+SciMax)*2)+6;
					SetEntityHealth(client, SciEscaped+2);
				}
			}
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
	if(!Enabled || !IsPlayerAlive(client))
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

	static float clientPos[3], enemyPos[3];
	if(Gamemode==Gamemode_Steals && Client[client].HealthPack)
	{
		int entity = EntRefToEntIndex(Client[client].HealthPack);
		if(entity>MaxClients && IsValidEntity(entity))
		{
			GetClientEyeAngles(client, clientPos);
			GetClientAbsAngles(client, enemyPos);
			SubtractVectors(clientPos, enemyPos, clientPos);
			TeleportEntity(entity, NULL_VECTOR, clientPos, NULL_VECTOR);
		}
		else
		{
			Client[client].HealthPack = 0;
		}
	}

	switch(Client[client].Class)
	{
		case Class_Spec:
		{
			SetSpeed(client, 360.0);
		}
		case Class_DBoi, Class_Scientist:
		{
			if(Gamemode == Gamemode_Steals)
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", Client[client].IdleAt>engineTime);
				SetSpeed(client, Client[client].Sprinting ? 360.0 : 270.0);
			}
			else
			{
				SetSpeed(client, Client[client].Disarmer ? 230.0 : Client[client].Sprinting ? 310.0 : 260.0);
			}
		}
		case Class_Chaos:
		{
			SetSpeed(client, (Client[client].Sprinting && !Client[client].Disarmer) ? 270.0 : 230.0);
		}
		case Class_MTF3:
		{
			SetSpeed(client, Client[client].Disarmer ? 230.0 : Client[client].Sprinting ? 280.0 : 240.0);
		}
		case Class_Guard, Class_MTF, Class_MTF2, Class_MTFS:
		{
			SetSpeed(client, Client[client].Disarmer ? 230.0 : Client[client].Sprinting ? 290.0 : 250.0);
		}
		case Class_049:
		{
			SetSpeed(client, 250.0);
		}
		case Class_0492, Class_3008:
		{
			SetSpeed(client, 270.0);
		}
		case Class_096:
		{
			switch(Client[client].Radio)
			{
				case 1:
				{
					SetSpeed(client, 230.0);
					if(Client[client].Power < engineTime)
					{
						TF2_AddCondition(client, TFCond_CritCola, 99.9);
						TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096Rage));
						Client[client].Power = engineTime+(Client[client].Disarmer*2.0)+13.0;
						Client[client].Keycard = Keycard_106;
						Client[client].Radio = 2;
					}
				}
				case 2:
				{
					TF2_RemoveCondition(client, TFCond_Dazed);
					SetSpeed(client, 520.0);
					if(Client[client].Power < engineTime)
					{
						TF2_RemoveCondition(client, TFCond_CritCola);
						TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096));
						Client[client].Disarmer = 0;
						Client[client].Radio = 0;
						Client[client].Keycard = Keycard_SCP;
						Client[client].Power = engineTime+15.0;
						TF2_StunPlayer(client, 6.0, 0.9, TF_STUNFLAG_SLOWDOWN);
						StopSound(client, SNDCHAN_VOICE, SoundList[Sound_Screams]);
						StopSound(client, SNDCHAN_VOICE, SoundList[Sound_Screams]);

						bool another096;
						for(int i=1; i<=MaxClients; i++)
						{
							if(Client[i].Class!=Class_096 || !Client[client].Radio)
								continue;

							another096 = true;
							break;
						}

						if(!another096)
						{
							for(int i; i<MAXTF2PLAYERS; i++)
							{
								Client[i].Triggered = false;
							}
						}
					}
				}
				default:
				{
					SetSpeed(client, 230.0);
					if(Client[client].Power > engineTime)
						return;

					if(Client[client].IdleAt < engineTime)
					{
						if(Client[client].Pos[0])
						{
							StopSound(client, SNDCHAN_VOICE, SoundList[Sound_096]);
							StopSound(client, SNDCHAN_VOICE, SoundList[Sound_096]);
							Client[client].Pos[0] = 0.0;
						}
					}
					else if(!Client[client].Pos[0])
					{
						EmitSoundToAll(SoundList[Sound_096], client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING, _, _, _, client);
						Client[client].Pos[0] = 1.0;
					}
				}
			}
		}
		case Class_106:
		{
			SetSpeed(client, 240.0);
		}
		case Class_173:
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
							SetSpeed(client, 1.0);
							static float vel[3];
							vel[2] = -500.0;
							TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
						}
					}
				}
				case 2:
				{
					SetSpeed(client, 3000.0);
				}
				default:
				{
					SetSpeed(client, 420.0);
				}
			}
		}
		case Class_1732:
		{
			switch(Client[client].Radio)
			{
				case 1:
				{
					if(GetEntityMoveType(client) != MOVETYPE_NONE)
					{
						static float vel[3];
						if(GetEntityFlags(client) & FL_ONGROUND)
						{
							vel[2] = 0.0;
							TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
							SetEntityMoveType(client, MOVETYPE_NONE);
						}
						else
						{
							vel[2] = -500.0;
							TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
							SetSpeed(client, 1.0);
						}
					}
				}
				case 2:
				{
					SetSpeed(client, 2600.0);
				}
				default:
				{
					SetSpeed(client, 450.0);
				}
			}
		}
		case Class_939, Class_9392:
		{
			SetSpeed(client, 300.0-(GetClientHealth(client)/55.0));
		}
		case Class_Stealer:
		{
			switch(Client[client].Radio)
			{
				/*case -1:
				{
					SetSpeed(client, 335.0);
					GetClientAbsOrigin(client, clientPos);
					for(int target=1; target<=MaxClients; target++)
					{
						if(!IsValidClient(target) || IsSpec(target) || IsSCP(target))
							continue;

						GetClientAbsOrigin(target, enemyPos);
						if(GetVectorDistance(clientPos, enemyPos, true) < 1000000)
							return;
					}

					Client[client].Radio = 0;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
				}*/
				case 1:
				{
					SetSpeed(client, 400.0);
					if(Client[client].Power > engineTime)
						return;

					TurnOffGlow(client);
					Client[client].Radio = 0;
					TF2_RemoveCondition(client, TFCond_CritCola);
				}
				case 2:
				{
					SetSpeed(client, 500.0);
					return;
				}
				default:
				{
					SetSpeed(client, 350.0+((SciEscaped/(SciMax+DClassMax)*50.0)));
					GetClientAbsOrigin(client, clientPos);
					for(int target=1; target<=MaxClients; target++)
					{
						if(!Client[target].Triggered)
							continue;

						if(IsValidClient(target) && !IsSpec(target) && !IsSCP(target))
						{
							GetClientAbsOrigin(target, enemyPos);
							if(GetVectorDistance(clientPos, enemyPos, true) < 1000000)
								continue;
						}
						Client[target].Triggered = false;
					}

					if(Client[client].IdleAt+5.0 < engineTime)
					{
						SciEscaped--;
						Client[client].IdleAt = engineTime+2.5;
					}
				}
			}
		}
	}

	static float specialTick[MAXTF2PLAYERS];
	if(specialTick[client] > engineTime)
		return;

	static float clientAngles[3], enemyAngles[3], anglesToBoss[3], result[3];

	bool showHud = (Client[client].HudIn<engineTime && !(GetClientButtons(client) & IN_SCORE));
	specialTick[client] = engineTime+0.2;
	switch(Client[client].Class)
	{
		case Class_Spec:
		{
			ClientCommand(client, "firstperson");
		}
		case Class_096:
		{
			GetClientEyePosition(client, clientPos);
			GetClientEyeAngles(client, clientAngles);
			clientAngles[0] = fixAngle(clientAngles[0]);
			clientAngles[1] = fixAngle(clientAngles[1]);

			int status;
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target) || Client[target].Triggered)
					continue;

				GetClientEyePosition(target, enemyPos);
				GetClientEyeAngles(target, enemyAngles);
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
				TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
					continue;

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

				// success
				status = target;
				break;
			}

			if(status)
				TriggerShyGuy(client, status, engineTime);
		}
		case Class_106:
		{
			if(Client[client].ChargeIn && Client[client].ChargeIn<engineTime)
			{
				Client[client].ChargeIn = 0.0;
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
		case Class_173, Class_1732:
		{
			static int blink;
			GetClientEyePosition(client, clientPos);

			GetClientEyeAngles(client, clientAngles);
			clientAngles[0] = fixAngle(clientAngles[0]);
			clientAngles[1] = fixAngle(clientAngles[1]);

			int status;
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target))
					continue;

				GetClientEyePosition(target, enemyPos);
				GetClientEyeAngles(target, enemyAngles);
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
				TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
					continue;

				// success
				if(!blink)
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

			switch(status)
			{
				case 1:
				{
					Client[client].Radio = 1;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
					SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
				}
				case 2:
				{
					Client[client].Radio = 2;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
					SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
					if(GetEntityMoveType(client) != MOVETYPE_WALK)
						SetEntityMoveType(client, MOVETYPE_WALK);
				}
				default:
				{
					Client[client].Radio = 0;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
					SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
					if(GetEntityMoveType(client) != MOVETYPE_WALK)
						SetEntityMoveType(client, MOVETYPE_WALK);
				}
			}
		}
		case Class_Stealer:
		{
			GetClientEyePosition(client, clientPos);
			GetClientEyeAngles(client, clientAngles);
			clientAngles[0] = fixAngle(clientAngles[0]);
			clientAngles[1] = fixAngle(clientAngles[1]);

			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target) || !Client[target].HealthPack || Client[target].Triggered)
					continue;

				GetClientEyePosition(target, enemyPos);
				if(GetVectorDistance(clientPos, enemyPos, true) > 125000)
					continue;

				GetClientEyeAngles(target, enemyAngles);
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
				TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
					continue;

				// success
				if(SciEscaped >= ((DClassMax+SciMax)*2)+4)
				{
					for(target=1; target<=MaxClients; target++)
					{
						Client[target].Triggered = false;
					}

					SCPKilled = 2;
					Client[client].Radio = 2;
					TurnOnGlow(client, "255 0 0", 10, 700.0);
					TF2_AddCondition(client, TFCond_CritCola);
					ChangeGlobalSong(FAR_FUTURE, SoundList[Sound_ItHadEnough]);
					TF2_StunPlayer(client, 11.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
				}
				else if(!SCPKilled && SciEscaped==DClassMax+SciMax+2)
				{
					for(target=1; target<=MaxClients; target++)
					{
						if(IsValidClient(target))
							ClientCommand(target, "playgamesound %s", SoundList[Sound_ItRages]);
					}

					SCPKilled = 1;
					Client[client].Radio = 1;
					Client[client].Power = engineTime+15.0;
					TurnOnGlow(client, "255 0 0", 10, 600.0);
					TF2_AddCondition(client, TFCond_CritCola, 15.0);
					ChangeGlobalSong(Client[client].Power, SoundList[Sound_ItRages]);
					TF2_StunPlayer(client, 4.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
				}
				else
				{
					SciEscaped++;
					Client[target].Triggered = true;
					ClientCommand(target, "playgamesound %s", SoundList[Sound_ItStuns]);
				}
				break;
			}
		}
		default:
		{
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
							Client[client].SprintPower += 2.0;
					}

					if(Client[client].HudIn < engineTime)
					{
						if(Client[client].SprintPower > 85)
						{
							ClientCommand(client, "r_screenoverlay \"\"");
						}
						else if(Client[client].SprintPower > 70)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/almostnone.vmt");
						}
						else if(Client[client].SprintPower > 55)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/verylow.vmt");
						}
						else if(Client[client].SprintPower > 40)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/low.vmt");
						}
						else if(Client[client].SprintPower > 25)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/medium.vmt");
						}
						else if(Client[client].SprintPower > 10)
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
							SetGlobalTransTarget(client);
							char buffer[32];
							int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
							if(weapon>MaxClients && IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Disarm])
								FormatEx(buffer, sizeof(buffer), "%t", "camera", RoundToCeil(Client[client].Power));

							SetHudTextParams(-1.0, 0.92, 0.35, 255, 255, 255, 255, 0, 0.1, 0.05, 0.05);
							if(Client[client].Radio)
							{
								ShowSyncHudText(client, HudPlayer, "%s\n%t", buffer, "radar");
							}
							else
							{
								ShowSyncHudText(client, HudPlayer, buffer);
							}
						}
					}
				}
				else
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

						if(Client[client].Sprinting)
						{
							Client[client].SprintPower -= 2.0;
							if(Client[client].SprintPower <= 0)
							{
								PrintKeyHintText(client, "%t", "sprint", 0);
								Client[client].Sprinting = false;
							}
							else
							{
								PrintKeyHintText(client, "%t", "sprint", RoundToCeil(Client[client].SprintPower));
							}
						}
						else
						{
							if(Client[client].SprintPower < 100)
							{
								Client[client].SprintPower += 0.75;
								PrintKeyHintText(client, "%t", "sprint", RoundToFloor(Client[client].SprintPower));
							}
						}

						if(showHud)
						{
							SetGlobalTransTarget(client);

							char buffer[256], tran[16];
							if(Client[client].Power>1 && Client[client].Radio && Client[client].Radio<5)
							{
								FormatEx(tran, sizeof(tran), "radio_%d", Client[client].Radio);
								FormatEx(buffer, sizeof(buffer), "%t", "radio", tran, RoundToCeil(Client[client].Power));
							}

							switch(Client[client].HealthPack)
							{
								case 1:
									Format(buffer, sizeof(buffer), "%t\n%s", "pain_killers", buffer);

								case 2, 3:
									Format(buffer, sizeof(buffer), "%t\n%s", "health_kit", buffer);

								case 4:
									Format(buffer, sizeof(buffer), "%t\n%s", "scp_500", buffer);
							}

							FormatEx(tran, sizeof(tran), "keycard_%d", Client[client].Keycard);

							SetHudTextParamsEx(-1.0, Gamemode==Gamemode_Ctf ? 0.77 : 0.88, 0.35, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 0.1, 0.05, 0.05);
							ShowSyncHudText(client, HudPlayer, "%t\n%s", "keycard", tran, buffer);
						}
					}
				}
			}
		}
	}

	if(showHud && Gamemode!=Gamemode_Steals)
	{
		char buffer[32];
		GetClassName(Client[client].Class, buffer, sizeof(buffer));

		SetHudTextParamsEx(-1.0, 0.06, 0.35, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 0.1, 0.05, 0.05);
		ShowSyncHudText(client, HudExtra, "%T", buffer, client);
	}

	if(!NoMusic && Client[client].NextSongAt<engineTime)
	{
		int song = GetRandomInt(2, sizeof(MusicList)-1);
		ChangeSong(client, MusicTimes[song]+engineTime, MusicList[song]);
		CPrintToChat(client, "%s%t", PREFIX, "now_playing", MusicNames[song]);
	}

	int buttons = GetClientButtons(client);
	#if defined _voiceannounceex_included_
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT)|| (Vaex && IsClientSpeaking(client)))))
	#else
	if((buttons & IN_ATTACK) || (!(buttons & IN_DUCK) && ((buttons & IN_FORWARD) || (buttons & IN_BACK) || (buttons & IN_MOVELEFT) || (buttons & IN_MOVERIGHT))))
	#endif
		Client[client].IdleAt = engineTime+2.5;
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
}

public bool OnCollide(int client, int collision, int contents, bool result)
{
	if(collision!=COLLISION_GROUP_PLAYER_MOVEMENT || !IsValidClient(client))
		return result;

	return !(IsSpec(client) || IsSCP(client));
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
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToCeil((GetEngineTime()+0.75)*10.0));
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnKitPickup);
}

public void OnMedSpawned(int entity)
{
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToFloor((GetEngineTime()+2.25)*10.0));
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

	float time = GetEntProp(entity, Prop_Data, "m_iHammerID")/10.0;
	if(IsSCP(client) || Client[client].Disarmer || time>GetEngineTime())
		return Plugin_Handled;

	if(StrEqual(classname, "item_healthkit_full") || (time+0.3)>GetEngineTime())
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

			if(SciEscaped)
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
		if(class >= Class_049)
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

void TriggerShyGuy(int client, int target, float engineTime)
{
	SetEntityHealth(client, GetClientHealth(client)+250);
	Client[target].Triggered = true;
	switch(Client[client].Radio)
	{
		case 1:
		{
			Client[client].Disarmer++;
		}
		case 2:
		{
			Client[client].Power += 2.0;
			Client[client].Disarmer++;
		}
		default:
		{
			if(Client[client].Pos[0])
			{
				StopSound(client, SNDCHAN_VOICE, SoundList[Sound_096]);
				StopSound(client, SNDCHAN_VOICE, SoundList[Sound_096]);
			}

			Client[client].Pos[0] = 0.0;
			Client[client].Power = engineTime+6.0;
			Client[client].Radio = 1;
			Client[client].Disarmer = 1;
			TF2_StunPlayer(client, 9.9, 0.9, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
			EmitSoundToAll(SoundList[Sound_Screams], client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING, _, _, _, client);
		}
	}
}

public Action Timer_ConnectPost(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Continue;

	/*if(DHForceRespawn != null)
		DHookEntity(DHForceRespawn, false, client, _, DHook_ForceRespawn);*/

	QueryClientConVar(client, "sv_allowupload", OnQueryFinished, userid);
	QueryClientConVar(client, "cl_allowdownload", OnQueryFinished, userid);
	QueryClientConVar(client, "cl_downloadfilter", OnQueryFinished, userid);

	if(!NoMusic)
		ChangeSong(client, MusicTimes[0]+GetEngineTime(), MusicList[0]);

	PrintToConsole(client, " \n \nWelcome to SCP: Secret Fortress\n \nThis is a gamemode based on the SCP series and community\nPlugin is created by Batfoxkid\n ");
	PrintToConsole(client, "If you like to support the gamemode, you can join Gamers Freak Fortress community at https://discord.gg/JWE72cs\n ");
	PrintToConsole(client, "The SCP community also needs help, you can support them at https://www.gofundme.com/f/scp-legal-funds\n \n ");

	DisplayCredits(client);
	return Plugin_Continue;
}

void ChangeSong(int client, float next, const char[] filepath, bool volume=true)
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
		int entity = SDKCall(SDKCreateWeapon, -1, origin, angles, KEYCARD_MODEL, GetEntityAddress(weapon)+view_as<Address>(offset));

		FlagDroppedWeapons(false);

		if(entity == INVALID_ENT_REFERENCE)
			break;

		DispatchSpawn(entity);
		SDKCall(SDKInitWeapon, entity, client, weapon, swap, false);
		SetEntPropString(entity, Prop_Data, "m_iName", KeycardNames[Client[client].Keycard]);
		SetVariantInt(KeycardSkin[Client[client].Keycard]);
		AcceptEntityInput(entity, "Skin");
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
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "15 ; 0 ; 138 ; 0 ; 252 ; 0.95");
		}
		case Weapon_Axe:
		{
			wep = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 5, 6, "2 ; 1.65 ; 28 ; 0.5 ; 252 ; 0.95");
		}
		case Weapon_Hammer:
		{
			wep = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 5, 6, "2 ; 11 ; 6 ; 0.9 ; 28 ; 0.5 ; 138 ; 0.13 ; 252 ; 0.95");
		}
		case Weapon_Knife:
		{
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.2 ; 6 ; 0.8 ; 15 ; 0 ; 252 ; 0.95 ; 362 ; 1");
		}
		case Weapon_Bash:
		{
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.05 ; 6 ; 0.7 ; 28 ; 0.5 ; 252 ; 0.95");
		}
		case Weapon_Meat:
		{
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "1 ; 0.9 ; 6 ; 0.7 ; 252 ; 0.95");
		}
		case Weapon_Wrench:
		{
			wep = SpawnWeapon(client, "tf_weapon_wrench", WeaponIndex[weapon], 5, 6, "2 ; 1.5 ; 6 ; 0.9 ; 28 ; 0.5 ; 252 ; 0.95");
		}
		case Weapon_Pan:
		{
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.35 ; 6 ; 0.8 ; 28 ; 0.5 ; 252 ; 0.95");
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
			wep = SpawnWeapon(client, "tf_weapon_pistol", WeaponIndex[weapon], 5, 6, "2 ; 1.5 ; 3 ; 0.75 ; 5 ; 1.25 ; 51 ; 1 ; 96 ; 1.25 ; 106 ; 0.33 ; 252 ; 0.95");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 27, 0);
		}
		case Weapon_SMG:
		{
			TF2_SetPlayerClass(client, TFClass_Sniper, false);
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 5, 6, "2 ; 1.4 ; 4 ; 2 ; 5 ; 1.3 ; 51 ; 1 ; 78 ; 2 ; 96 ; 1.25 ; 252 ; 0.95");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 50, 50);
		}
		case Weapon_SMG2:
		{
			TF2_SetPlayerClass(client, TFClass_DemoMan, false);
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
			wep = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 40, 6, "2 ; 2.2 ; 4 ; 2 ; 6 ; 0.9 ; 51 ; 1 ; 78 ; 4.6875 ; 96 ; 2.25 ; 252 ; 0.6");
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 150, 50);
		}

		/*
			Primary Weapons
		*/
		case Weapon_Flash:
		{
			wep = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 5, 6, "1 ; 0.75 ; 3 ; 0.25 ; 15 ; 0 ; 76 ; 0.125 ; 99 ; 1.35 ; 252 ; 0.95 ; 787 ; 1.25", false, true);
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 1, 0);
		}
		case Weapon_Frag:
		{
			wep = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 10, 6, "2 ; 30 ; 3 ; 0.25 ; 28 ; 1.5 ; 76 ; 0.125 ; 99 ; 1.35 ; 138 ; 0.3 ; 252 ; 0.9 ; 671 ; 1 ; 787 ; 1.25", false);
			if(ammo && wep>MaxClients)
				SetAmmo(client, wep, 1, 0);
		}
		case Weapon_Micro:
		{
			wep = SpawnWeapon(client, "tf_weapon_flamethrower", WeaponIndex[weapon], 110, 6, "2 ; 7 ; 15 ; 0 ; 72 ; 0 ; 76 ; 5 ; 173 ; 5 ; 252 ; 0.5", false, true);
			if(wep > MaxClients)
			{
				SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				if(ammo)
					SetAmmo(client, wep, 1000);
			}
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
			wep = SpawnWeapon(client, "tf_weapon_sword", WeaponIndex[weapon], 100, 13, "2 ; 101 ; 6 ; 0.8 ; 28 ; 3 ; 252 ; 0 ; 326 ; 2.33", false);
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
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 100, 13, "2 ; 1.35 ; 28 ; 0.25 ; 252 ; 0.5", false);
		}
		case Weapon_Stealer:
		{
			wep = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 10, 14, "2 ; 1.5 ; 15 ; 0", false);
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

void ShowClassInfo(int client)
{
	Client[client].HudIn = GetEngineTime()+11.0;

	SetGlobalTransTarget(client);

	bool found;
	char buffer[32];
	GetClassName(Client[client].Class, buffer, sizeof(buffer));

	SetHudTextParamsEx(-1.0, 0.3, 10.0, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 5.0, 1.0, 1.0);
	ShowSyncHudText(client, HudExtra, "%t", "you_are", buffer);

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
	for(; wep<Weapon_049; wep++)
	{
		if(index == WeaponIndex[wep])
		{
			ReplaceWeapon(client, wep, entity);
			RemoveEntity(entity);

			Event event = CreateEvent("localplayer_pickup_weapon", true);
			event.FireToClient(client);
			event.Cancel();
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

bool IsFriendly(ClassEnum class1, ClassEnum class2)
{
	if(class1<Class_DBoi || class2<Class_DBoi)	// Either Spectator
		return true;

	switch(Gamemode)
	{
		case Gamemode_Ikea, Gamemode_Steals:
		{
			if(class1>=Class_DBoi && class2>=Class_DBoi && class1<Class_049 && class2<Class_049)
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

			if(class1>=Class_Scientist && class2>=Class_Scientist && class1<Class_049 && class2<Class_049)	// Both are Scientist/MTF
				return true;
		}
	}

	return (class1>=Class_049 && class2>=Class_049);	// Both are SCPs
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
		SetEntPropString(iGlow, Prop_Data, "m_iName", "SZF_WEAPON_GLOW");
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

	/*for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && (GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || IsPlayerAlive(client)))
			ChangeClientTeamEx(client, GetRandomInt(0, 1) ? TFTeam_Blue : TFTeam_Red);
	}*/

	DClassEscaped = 0;
	DClassMax = 1;
	SciEscaped = 0;
	SciMax = 0;
	SCPKilled = 0;
	SCPMax = 0;

	int total;
	int[] clients = new int[MaxClients];
	for(int client=1; client<=MaxClients; client++)
	{
		Client[client].NextSongAt = 0.0;
		if(!IsValidClient(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
		{
			Client[client].Class = Class_Spec;
			continue;
		}

		if(TestForceClass[client] <= Class_Spec)
		{
			clients[total++] = client;
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
		AssignTeam(client);
	}

	if(!total)
		return;

	int client = clients[GetRandomInt(0, total-1)];
	switch(Gamemode)
	{
		case Gamemode_Nut:
			Client[client].Class = Class_173;

		case Gamemode_Steals:
			Client[client].Class = total>1 ? Class_Stealer : Class_DBoi;

		default:
			Client[client].Class = Class_DBoi;
	}
	AssignTeam(client);

	for(int i; i<total; i++)
	{
		if(clients[i] == client)
			continue;

		switch(Client[clients[i]].Setup(view_as<TFTeam>(GetRandomInt(2, 3)), IsFakeClient(clients[i])))
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
				if(IsSCP(clients[i]))
					SCPMax++;
			}
		}
		AssignTeam(clients[i]);
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
}

public MRESReturn DHook_ForceRespawn(int client)
{
	if(!Enabled || Client[client].Class==Class_Spec || Client[client].Respawning>GetGameTime())
		return MRES_Ignored;
	
	return MRES_Supercede;
}*/

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
	if(Client[client].Class == Class_096)
	{
		TF2_SetPlayerClass(client, TFClass_Medic);
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		TF2_SetPlayerClass(client, TFClass_Unknown);
	}
}

public MRESReturn DHook_RegenThinkPost(int client, Handle params)
{
	if(Client[client].Class == Class_096)
	{
		TF2_SetPlayerClass(client, view_as<TFClassType>(ClassClass[Class_096]));
	}
	else if(TF2_GetPlayerClass(client) == TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, TFClass_Medic);
	}
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

public MRESReturn DHook_ShouldCollideWith(Address pointer, Handle returnVal, Handle params)
{
	int entity = DHookGetParam(params, 1);
	if(IsValidEntity(entity))
	{
		static char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "base_boss"))
		{
			DHookSetReturn(returnVal, false);
			return MRES_Supercede;
		}
	}
	return MRES_Ignored;
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

	result = !IsFriendly(Client[ent1].Class, Client[ent2].Class);
	return Plugin_Changed;

	/*if(!IsSCP(ent1) && !IsSCP(ent2) && !TF2_IsPlayerInCondition(ent1, TFCond_HalloweenGhostMode) && !TF2_IsPlayerInCondition(ent2, TFCond_HalloweenGhostMode) && !IsFriendly(Client[ent1].Class, Client[ent2].Class))
	{
		int weapon = GetEntPropEnt(ent1, Prop_Send, "m_hActiveWeapon");
		if(weapon>MaxClients && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")!=WeaponIndex[Weapon_None])
		{
			result = true;
			return Plugin_Changed;
		}
	}

	result = false;
	return Plugin_Changed;*/
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

	Client[entity].Class = Class_0492;
	AssignTeam(entity);
	RespawnPlayer(entity);

	SetEntProp(entity, Prop_Send, "m_bDucked", 1);
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
	else if(Client[client].ReviveGoneAt < GetEngineTime())
	{
		SDKUnhook(client, SDKHook_PreThink, MarkerThink);
		if(!IsPlayerAlive(client) && GetClientTeam(client)==view_as<int>(TFTeam_Unassigned))
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
	
	static char buffer[64];
	GetEntityClassname(marker, buffer, sizeof(buffer));
	return StrEqual(buffer, "entity_revive_marker", false);
}

// Ragdoll Effects

public void CreateSpecialDeath(int client)
{
	int entity = CreateEntityByName("prop_dynamic_override");
	if(!IsValidEntity(entity))
		return;

	TFClassType class = ClassClassModel[Client[client].Class];
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

// Glow Effects

stock int TF2_CreateGlow(int iEnt)
{
	char oldEntName[64];
	GetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName, sizeof(oldEntName));

	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%d", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);
	
	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchSpawn(ent);
	
	SDKHook(ent, SDKHook_SetTransmit, GlowTransmit);
	AcceptEntityInput(ent, "Enable");

	//SetVariantColor(view_as<int>({255, 255, 255, 255}));
	//AcceptEntityInput(ent, "SetGlowColor");

	//Change name back to old name because we don't need it anymore.
	SetEntPropString(iEnt, Prop_Data, "m_iName", oldEntName);

	return ent;
}

stock bool TF2_HasGlow(int iEnt)
{
	int index = -1;
	while ((index = FindEntityByClassname(index, "tf_glow")) != -1)
	{
		if (GetEntPropEnt(index, Prop_Send, "m_hTarget") == iEnt)
		{
			return true;
		}
	}
	
	return false;
}

/*public Action GlowTransmit(int entity, int target)
{
	if(!IsValidClient(target))
		return Plugin_Handled;

	if(Client[target].Class==Class_096 || Client[target].Class>=Class_939)
	{
		int client = GetEntPropEnt(entity, Prop_Send, "m_hTarget");
		if(!IsValidClient(client) || IsSpec(client))
		{
			SDKUnhook(entity, SDKHook_SetTransmit, GlowTransmit);
			AcceptEntityInput(entity, "Kill");
			return Plugin_Handled;
		}

		if(Client[target].Class == Class_096)
		{
			if(Client[target].Radio==2 && Client[client].Triggered)
			{
				SetVariantColor(view_as<int>({255, 255, 255, 255}));
				AcceptEntityInput(entity, "SetGlowColor");
				return Plugin_Continue;
			}
		}
		else if(Client[target].Class==Class_3008 && Client[target].Radio)
		{
			SetVariantColor(view_as<int>({255, 255, 255, 255}));
			AcceptEntityInput(entity, "SetGlowColor");
			return Plugin_Continue;
		}

		float time = Client[client].IdleAt-GetEngineTime();
		if(time > 0)
		{
			static float clientPos[3], targetPos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", targetPos);
			if(GetVectorDistance(clientPos, targetPos) < (700*time/2.5))
			{
				SetVariantColor(view_as<int>({255, 255, 255, 255}));
				AcceptEntityInput(entity, "SetGlowColor");
				return Plugin_Continue;
			}
		}
	}

	SetVariantColor(view_as<int>({255, 255, 255, 0}));
	AcceptEntityInput(entity, "SetGlowColor");
	return Plugin_Handled;
}*/

// Custom Model

/*void CreateCustomModel(int client)
{
	int entity = CreateEntityByName("base_boss");
	if(!IsValidEntity(entity))
		return;

	Client[client].CustomHitbox = true;
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", ClassModelIndex[Class_Spec], _, 0);

	DispatchKeyValue(entity, "model", ClassModel[Client[client].Class]);
	DispatchKeyValue(entity, "modelscale", "0.75");
	DispatchKeyValue(entity, "health", "30000");
	DispatchSpawn(entity);

	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", ClassModelIndex[Client[client].Class], _, 0);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", ClassModelSubIndex[Class_Spec], _, 3);

	SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

	SDKHook(entity, SDKHook_Think, CustomModelThink);
	SDKHook(entity, SDKHook_OnTakeDamage, CustomModelDamage);
	//SDKHook(entity, SDKHook_ShouldCollide, CustomModelCollide);

	//if(DHShouldCollide)
		//DHookRaw(DHShouldCollide, true, view_as<Address>(DHShouldCollide));
}

public void CustomModelThink(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(!Enabled || !IsValidClient(client) || IsSpec(client))
	{
		SDKUnhook(entity, SDKHook_Think, CustomModelThink);
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill");
		return;
	}

	static float pos[3], ang[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	GetClientEyeAngles(client, ang);

	 TODO: Offset pos
	float angle = ang[0];
	while(angle > 180)
		angle -= 360.0;

	while(angle < -180)
		angle += 360.0;

	if(angle < 0)
		angle *= -1.0;

	if(angle < 90)
	{
		pos[0] += 30.0-(angle/3.0);
		pos[1] += 30.0-(angle/3.0);
	}
	else
	{
		pos[0] -= 30.0-((angle-90.0)/3.0);
	}

	ang[1] = 0.0;
	TeleportEntity(entity, pos, ang, TRIPLE_D);
}

public Action CustomModelDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled || !IsValidClient(attacker))
		return Plugin_Handled;

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client!=attacker && IsValidClient(client) && !IsFriendly(Client[client].Class, Client[attacker].Class))
		SDKHooks_TakeDamage(client, inflictor, attacker, damage, damagetype, weapon, damageForce, damagePosition);

	return Plugin_Handled;
}

public bool CustomModelCollide(int entity, int collisiongroup, int contentsmask, bool originalResult)
{
	return false;
}*/

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
		ChangeClientTeam(client, (newTeam==TFTeam_Unassigned) ? view_as<int>(TFTeam_Red) : view_as<int>(newTeam));
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

stock void SetSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
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
	/*if(StrEqual(name, "saxxy", false))	// if "saxxy" is specified as the name, replace with appropiate name
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
	}*/

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

stock int PrecacheModelEx(const char[] model, bool preload=false)
{
	static char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), model);
	ReplaceString(buffer, sizeof(buffer), ".mdl", "");

	int table = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	char buffer2[PLATFORM_MAX_PATH];
	static const char fileTypes[][] = {"dx80.vtx", "dx90.vtx", "mdl", "phy", "sw.vtx", "vvd"};
	for(int i; i<sizeof(fileTypes); i++)
	{
		FormatEx(buffer2, sizeof(buffer2), "%s.%s", buffer, fileTypes[i]);
		if(FileExists(buffer2))
			AddToStringTable(table, buffer2);
	}
	LockStringTables(save);

	return PrecacheModel(model, preload);
}

stock int PrecacheSoundEx(const char[] sound, bool preload=false)
{
	char buffer[PLATFORM_MAX_PATH];
	FormatEx(buffer, sizeof(buffer), "sound/%s", sound);
	ReplaceStringEx(buffer, sizeof(buffer), "#", "");
	if(FileExists(buffer))
		AddFileToDownloadsTable(buffer);

	return PrecacheSound(sound, preload);
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

		if(Client[client].Class>=Class_MTF && Client[client].Class<=Class_MTF3)
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

// Natives

public any Native_GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>=0 && client<MAXTF2PLAYERS)
		return Client[client].Class;

	return Class_Spec;
}

#file "SCP: Secret Fortress"
