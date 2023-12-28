#pragma semicolon 1
#pragma newdecls required

enum
{
	Ammo_Metal = 3,	// 3	Metal
	Ammo_Jar = 6,	// 6	Jar
	Ammo_Shotgun,	// 7	Shotgun, Shortstop, Force-A-Nature, Soda Popper
	Ammo_Pistol,	// 8	Pistol
	Ammo_Rocket,	// 9	Rocket Launchers
	Ammo_Flame,		// 10	Flamethrowers
	Ammo_Flare,		// 11	Flare Guns
	Ammo_Grenade,	// 12	Grenade Launchers
	Ammo_Sticky,	// 13	Stickybomb Launchers
	Ammo_Minigun,	// 14	Miniguns
	Ammo_Bolt,		// 15	Resuce Ranger, Cursader's Crossbow
	Ammo_Syringe,	// 16	Needle Guns
	Ammo_Sniper,	// 17	Sniper Rifles
	Ammo_Arrow,		// 18	Huntsman
	Ammo_SMG,		// 19	SMGs
	Ammo_Revolver,	// 20	Revolvers
	Ammo_MAX = 31
};

enum
{
	Type_Any = -1,
	Type_Misc = 0,
	Type_Weapon,
	Type_Keycard,
	Type_Medical,
	Type_Radio,
	Type_SCP,
	Type_Unused,
	Type_Grenade,
	Type_MAX
};

enum
{
	ClassSpawn_Other = 0,
	ClassSpawn_RoundStart,
	ClassSpawn_WaveSystem,
	ClassSpawn_Death,
	ClassSpawn_Escape,
	ClassSpawn_Revive
}

enum
{
	Access_Unknown = -1,
	Access_Main = 0,
	Access_Armory,
	Access_Exit,
	Access_Warhead,
	Access_Checkpoint,
	Access_Intercom
}

enum
{
	PLAYERANIMEVENT_ATTACK_PRIMARY,
	PLAYERANIMEVENT_ATTACK_SECONDARY,
	PLAYERANIMEVENT_ATTACK_GRENADE,
	PLAYERANIMEVENT_RELOAD,
	PLAYERANIMEVENT_RELOAD_LOOP,
	PLAYERANIMEVENT_RELOAD_END,
	PLAYERANIMEVENT_JUMP,
	PLAYERANIMEVENT_SWIM,
	PLAYERANIMEVENT_DIE,
	PLAYERANIMEVENT_FLINCH_CHEST,
	PLAYERANIMEVENT_FLINCH_HEAD,
	PLAYERANIMEVENT_FLINCH_LEFTARM,
	PLAYERANIMEVENT_FLINCH_RIGHTARM,
	PLAYERANIMEVENT_FLINCH_LEFTLEG,
	PLAYERANIMEVENT_FLINCH_RIGHTLEG,
	PLAYERANIMEVENT_DOUBLEJUMP,

	// Cancel.
	PLAYERANIMEVENT_CANCEL,
	PLAYERANIMEVENT_SPAWN,

	// Snap to current yaw exactly
	PLAYERANIMEVENT_SNAP_YAW,

	PLAYERANIMEVENT_CUSTOM,				// Used to play specific activities
	PLAYERANIMEVENT_CUSTOM_GESTURE,
	PLAYERANIMEVENT_CUSTOM_SEQUENCE,	// Used to play specific sequences
	PLAYERANIMEVENT_CUSTOM_GESTURE_SEQUENCE,

	// TF Specific. Here until there's a derived game solution to this.
	PLAYERANIMEVENT_ATTACK_PRE,
	PLAYERANIMEVENT_ATTACK_POST,
	PLAYERANIMEVENT_GRENADE1_DRAW,
	PLAYERANIMEVENT_GRENADE2_DRAW,
	PLAYERANIMEVENT_GRENADE1_THROW,
	PLAYERANIMEVENT_GRENADE2_THROW,
	PLAYERANIMEVENT_VOICE_COMMAND_GESTURE,
	PLAYERANIMEVENT_DOUBLEJUMP_CROUCH,
	PLAYERANIMEVENT_STUN_BEGIN,
	PLAYERANIMEVENT_STUN_MIDDLE,
	PLAYERANIMEVENT_STUN_END,
	PLAYERANIMEVENT_PASSTIME_THROW_BEGIN,
	PLAYERANIMEVENT_PASSTIME_THROW_MIDDLE,
	PLAYERANIMEVENT_PASSTIME_THROW_END,
	PLAYERANIMEVENT_PASSTIME_THROW_CANCEL,

	PLAYERANIMEVENT_ATTACK_PRIMARY_SUPER,

	PLAYERANIMEVENT_COUNT
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

enum
{
	OBS_MODE_NONE = 0,	// not in spectator mode
	OBS_MODE_DEATHCAM,	// special mode for death cam animation
	OBS_MODE_FREEZECAM,	// zooms to a target, and freeze-frames on them
	OBS_MODE_FIXED,		// view from a fixed camera position
	OBS_MODE_IN_EYE,	// follow a player in first person view
	OBS_MODE_CHASE,		// follow a player in third person view
	OBS_MODE_POI,		// PASSTIME point of interest - game objective, big fight, anything interesting; added in the middle of the enum due to tons of hard-coded "<ROAMING" enum compares
	OBS_MODE_ROAMING,	// free roaming

	NUM_OBSERVER_MODES,
};

int GetMaxWeapons(int client)
{
	static int maxweps;
	if(!maxweps)
		maxweps = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	return maxweps;
}

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

TFClassType KvGetClass(KeyValues kv, const char[] string, TFClassType defaul = TFClass_Unknown)
{
	char buffer[24];
	kv.GetString(string, buffer, sizeof(buffer));
	if(!buffer[0])
		return defaul;

	TFClassType class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
		class = TF2_GetClass(buffer);

	return class;
}

Function KvGetFunction(KeyValues kv, const char[] string, Function defaul = INVALID_FUNCTION)
{
	char buffer[64];
	kv.GetString(string, buffer, sizeof(buffer));
	if(buffer[0])
		return GetFunctionByName(null, buffer);

	return defaul;
}

void KvGetTranslation(KeyValues kv, const char[] string, char[] buffer, int length, const char[] defaul)
{
	kv.GetString(string, buffer, length, defaul);
	if(!TranslationPhraseExists(buffer))
	{
		LogError("[Config] Missing translation '%s'", buffer);
		strcopy(buffer, length, defaul);
	}
}

int KvGetModelIndex(KeyValues kv, const char[] string, int defaul = 0)
{
	char buffer[PLATFORM_MAX_PATH];
	kv.GetString(string, buffer, sizeof(buffer), "X");
	if(StrEqual(buffer, "X"))
		return defaul;
	
	if(buffer[0])
		return PrecacheModel(buffer);
	
	return 0;
}

void PrintKeyHintText(int client, const char[] format, any ...)
{
	char buffer[512];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	BfWrite userMessage = view_as<BfWrite>(StartMessageOne("KeyHintText", client));
	if(userMessage != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetString(userMessage, "hints", buffer);
		}
		else
		{
			userMessage.WriteByte(1);
			userMessage.WriteString(buffer);
		}
		
		EndMessage();
	}
}

TFClassType TF2_GetWeaponClass(int index, TFClassType defaul = TFClass_Unknown, int checkSlot = -1)
{
	if(defaul != TFClass_Unknown)
	{
		int slot = TF2Econ_GetItemLoadoutSlot(index, defaul);
		if(checkSlot != -1)
		{
			if(slot == checkSlot)
				return defaul;
		}
		else if(slot>=0 && slot<6)
		{
			return defaul;
		}
	}

	TFClassType backup;
	for(TFClassType class = TFClass_Engineer; class > TFClass_Unknown; class--)
	{
		if(defaul == class)
			continue;

		int slot = TF2Econ_GetItemLoadoutSlot(index, class);
		if(checkSlot != -1)
		{
			if(slot == checkSlot)
				return class;
			
			if(!backup && slot >= 0 && slot < 6)
				backup = class;
		}
		else if(slot >= 0 && slot < 6)
		{
			return class;
		}
	}

	if(checkSlot != -1 && backup)
		return backup;
	
	return defaul;
}

void SetItemID(int entity, int id)
{
	char netclass[64];
	if(GetEntityNetClass(entity, netclass, sizeof(netclass)))
	{
		SetEntData(entity, FindSendPropInfo(netclass, "m_iItemIDHigh") - 4, id);	// m_iItemID
		SetEntProp(entity, Prop_Send, "m_iItemIDHigh", id);
		SetEntProp(entity, Prop_Send, "m_iItemIDLow", id);
	}
}

int GetAmmo(int client, int type)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, type);
}

void SetAmmo(int client, int ammo, int type)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);
}

any GetItemInArray(any[] array, int pos)
{
	return array[pos];
}

int CreateOffset(GameData gamedata, const char[] name)
{
	int offset = gamedata.GetOffset(name);
	if(offset == -1)
		LogError("[Gamedata] Could not find %s", name);
	
	return offset;
}

int GetClientPointVisible(int client, float distSqr = 10000.0)
{
	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	
	Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, Trace_DontHitEntity, client);
	TR_GetEndPosition(ang, trace);
	
	int entity = TR_GetEntityIndex(trace);
	bool hit = TR_DidHit(trace);
	delete trace;

	if(hit && GetVectorDistance(pos, ang, true) < distSqr)
		return entity;
	
	return -1;
}

void ShowGameText(int client = 0, const char[] icon = "leaderboard_streak", int color = 0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(client)
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}

	if(bf)
	{
		char message[64];
		SetGlobalTransTarget(client);
		VFormat(message, sizeof(message), buffer, 5);
		ReplaceString(message, sizeof(message), "\n", "");

		bf.WriteString(message);
		bf.WriteString(icon);
		bf.WriteByte(color);
		EndMessage();
	}
}

void ModelIndexToString(int index, char[] model, int size)
{
	static int table;
	if(!table)
		table = FindStringTable("modelprecache");
	
	ReadStringTable(table, index, model, size);
}

// Set a single byte of data on the entity which can be accessed by it's own materials (clientside)
// This overwrites the entity's alpha, which is normally not used so it shouldn't affect any visuals
void SetEntityMaterialData(int entity, int data)
{
	int r, g, b, a;
	GetEntityRenderColor(entity, r, g, b, a);
	SetEntityRenderColor(entity, r, g, b, data);
}

bool TF2_GetItem(int client, int &weapon, int &pos)
{
	int maxWeapons = GetMaxWeapons(client);

	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;

		if(weapon != -1)
			return true;
	}
	return false;
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity != data;
}

public bool Trace_OnlyHitWorld(int entity, int mask)
{
	return !entity;
}