#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <clientprefs>
#include <morecolors>
#include <tf_econ_data> 
#include <dhooks>
#include <vscript>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN

#pragma semicolon 1
#pragma newdecls required

#define CONFIG		"configs/scpm"
#define CONFIG_CFG	CONFIG ... "/%s.cfg"

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Humans		2
#define TFTeam_Bosses		3
#define TFTeam_MAX		4

#define TFClass_MAX		10

#define FFADE_IN	(1 << 0)
#define FFADE_OUT	(1 << 1)
#define FFADE_MODULATE	(1 << 2)
#define FFADE_STAYOUT	(1 << 3)
#define FFADE_PURGE	(1 << 4)

#define	HIDEHUD_WEAPONSELECTION		(1 << 0)	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT		(1 << 1)
#define	HIDEHUD_ALL			(1 << 2)
#define HIDEHUD_HEALTH			(1 << 3)	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD		(1 << 4)	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT		(1 << 5)	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS		(1 << 6)	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT			(1 << 7)	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR		(1 << 8)	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	(1 << 9)	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE		(1 << 10)
#define HIDEHUD_BONUS_PROGRESS		(1 << 11)	// Hide bonus progress display (for bonus map challenges)
#define HIDEHUD_BUILDING_STATUS		(1 << 12)
#define HIDEHUD_CLOAK_AND_FEIGN		(1 << 13)
#define HIDEHUD_PIPES_AND_CHARGE	(1 << 14)
#define HIDEHUD_METAL			(1 << 15)
#define HIDEHUD_TARGET_ID		(1 << 16)

enum
{
	WINREASON_NONE = 0,
	WINREASON_ALL_POINTS_CAPTURED,
	WINREASON_OPPONENTS_DEAD,
	WINREASON_FLAG_CAPTURE_LIMIT,
	WINREASON_DEFEND_UNTIL_TIME_LIMIT,
	WINREASON_STALEMATE,
	WINREASON_TIMELIMIT,
	WINREASON_WINLIMIT,
	WINREASON_WINDIFFLIMIT,
	WINREASON_RD_REACTOR_CAPTURED,
	WINREASON_RD_CORES_COLLECTED,
	WINREASON_RD_REACTOR_RETURNED,
	WINREASON_PD_POINTS,
	WINREASON_SCORED,
	WINREASON_STOPWATCH_WATCHING_ROUNDS,
	WINREASON_STOPWATCH_WATCHING_FINAL_ROUND,
	WINREASON_STOPWATCH_PLAYING_ROUNDS,
	
	WINREASON_CUSTOM_OUT_OF_TIME
};

enum
{
	EF_BONEMERGE		= 0x001,	// Performs bone merge on client side
	EF_BRIGHTLIGHT 		= 0x002,	// DLIGHT centered at entity origin
	EF_DIMLIGHT 		= 0x004,	// player flashlight
	EF_NOINTERP		= 0x008,	// don't interpolate the next frame
	EF_NOSHADOW		= 0x010,	// Don't cast no shadow
	EF_NODRAW		= 0x020,	// don't draw entity
	EF_NORECEIVESHADOW	= 0x040,	// Don't receive no shadow
	EF_BONEMERGE_FASTCULL	= 0x080,	// For use with EF_BONEMERGE. If this is set, then it places this ent's origin at its
										// parent and uses the parent's bbox + the max extents of the aiment.
										// Otherwise, it sets up the parent's bones every frame to figure out where to place
										// the aiment, which is inefficient because it'll setup the parent's bones even if
										// the parent is not in the PVS.
	EF_ITEM_BLINK		= 0x100,	// blink an item so that the user notices it.
	EF_PARENT_ANIMATES	= 0x200,	// always assume that the parent entity is animating
	EF_MAX_BITS = 10
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

	LAST_SHARED_COLLISION_GROUP,

	TF_COLLISIONGROUP_GRENADE = 20,
	TFCOLLISION_GROUP_OBJECT,
	TFCOLLISION_GROUP_OBJECT_SOLIDTOPLAYERMOVEMENT,
	TFCOLLISION_GROUP_COMBATOBJECT,
	TFCOLLISION_GROUP_ROCKETS,		// Solid to players, but not player movement. ensures touch calls are originating from rocket
	TFCOLLISION_GROUP_RESPAWNROOMS,
	TFCOLLISION_GROUP_TANK,
	TFCOLLISION_GROUP_ROCKET_BUT_NOT_WITH_OTHER_ROCKETS
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

enum
{
	Version,
	
	//PrefToggle,
	
	AllowSpectators,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

float RoundStartTime;
float NextBlinkAt;
int PlayersAlive[TFTeam_MAX];
int MaxPlayersAlive[TFTeam_MAX];

#include "scpm/client.sp"
#include "scpm/stocks.sp"
#include "scpm/attributes.sp"
#include "scpm/bosses.sp"
#include "scpm/commands.sp"
#include "scpm/configs.sp"
#include "scpm/convars.sp"
#include "scpm/dhooks.sp"
#include "scpm/events.sp"
#include "scpm/gamemode.sp"
#include "scpm/humans.sp"
#include "scpm/items.sp"
#include "scpm/sdkcalls.sp"
#include "scpm/sdkhooks.sp"
#include "scpm/tf2utils.sp"
#include "scpm/vscript.sp"
#include "scpm/weapons.sp"

#include "scpm/bosses/default.sp"
#include "scpm/bosses/scp173.sp"

public Plugin myinfo =
{
	name		=	"SCP: Mercenaries",
	author		=	"Many Many",
	description	=	"Now with 80% less karma",
	version		=	"manual"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	TF2U_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("scpm.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	if(!TranslationPhraseExists("Weapon Stripped"))
		SetFailState("Translation file \"scpm.phrases\" is outdated");
	
	Bosses_PluginStart();
	Command_PluginStart();
	ConVar_PluginStart();
	Events_PluginStart();
	DHook_PluginStart();
	Gamemode_PluginStart();
	Human_PluginStart();
	TF2U_PluginStart();
	SDKCall_PluginStart();
	SDKHook_PluginStart();
	VScript_PluginStart();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnPluginEnd()
{
	ConVar_Disable();
	DHook_PluginEnd();
}

public void OnMapStart()
{
	
}

public void OnMapEnd()
{
	ConVar_Disable();
}

public void OnLibraryAdded(const char[] name)
{
	SDKHook_LibraryAdded(name);
	TF2U_LibraryAdded(name);
}

public void OnLibraryRemoved(const char[] name)
{
	SDKHook_LibraryRemoved(name);
	TF2U_LibraryRemoved(name);
}

public void OnConfigsExecuted()
{
	ConVar_ConfigsExecuted();
	Configs_ConfigsExecuted();
}

public void OnClientPutInServer(int client)
{
	DHook_HookClient(client);
	SDKHook_HookClient(client);
	Human_PutInServer(client);
}

public void OnClientDisconnect(int client)
{
	Bosses_ClientDisconnect(client);
	Human_ClientDisconnect(client);
	Client(client).ResetByDisconnect();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	bool changed = Gamemode_PlayerRunCmd(client, buttons, impulse);
	Human_PlayerRunCmd(client, buttons, vel);
	Action action = Bosses_PlayerRunCmd(client, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);

	Client(client).LastGameTime = GetGameTime();

	if(action == Plugin_Continue && changed)
		action = Plugin_Changed;
	
	return action;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	Human_ConditionAdded(client, condition);
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	Human_ConditionRemoved(client, condition);
}
