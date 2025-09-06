#pragma semicolon 1
#pragma newdecls required

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

enum HudNotification_t
{
	HUD_NOTIFY_YOUR_FLAG_TAKEN,
	HUD_NOTIFY_YOUR_FLAG_DROPPED,
	HUD_NOTIFY_YOUR_FLAG_RETURNED,
	HUD_NOTIFY_YOUR_FLAG_CAPTURED,

	HUD_NOTIFY_ENEMY_FLAG_TAKEN,
	HUD_NOTIFY_ENEMY_FLAG_DROPPED,
	HUD_NOTIFY_ENEMY_FLAG_RETURNED,
	HUD_NOTIFY_ENEMY_FLAG_CAPTURED,

	HUD_NOTIFY_TOUCHING_ENEMY_CTF_CAP,

	HUD_NOTIFY_NO_INVULN_WITH_FLAG,
	HUD_NOTIFY_NO_TELE_WITH_FLAG,

	HUD_NOTIFY_SPECIAL,

	HUD_NOTIFY_GOLDEN_WRENCH,

	HUD_NOTIFY_RD_ROBOT_UNDER_ATTACK,

	HUD_NOTIFY_HOW_TO_CONTROL_GHOST,
	HUD_NOTIFY_HOW_TO_CONTROL_KART,

	HUD_NOTIFY_PASSTIME_HOWTO,
	HUD_NOTIFY_PASSTIME_NO_TELE,
	HUD_NOTIFY_PASSTIME_NO_CARRY,
	HUD_NOTIFY_PASSTIME_NO_INVULN,
	HUD_NOTIFY_PASSTIME_NO_DISGUISE, 
	HUD_NOTIFY_PASSTIME_NO_CLOAK, 
	HUD_NOTIFY_PASSTIME_NO_OOB, // out of bounds
	HUD_NOTIFY_PASSTIME_NO_HOLSTER,
	HUD_NOTIFY_PASSTIME_NO_TAUNT,

	HUD_NOTIFY_COMPETITIVE_GC_DOWN,

	HUD_NOTIFY_TRUCE_START,
	HUD_NOTIFY_TRUCE_END,

	HUD_NOTIFY_HOW_TO_CONTROL_GHOST_NO_RESPAWN,
	//
	// ADD NEW ITEMS HERE TO AVOID BREAKING DEMOS
	//

	NUM_STOCK_NOTIFICATIONS
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

enum PlayerAnimEvent_t
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

enum
{
	HITGROUP_GENERIC = 0,
	HITGROUP_HEAD,
	HITGROUP_CHEST,
	HITGROUP_STOMACH,
	HITGROUP_LEFTARM,
	HITGROUP_RIGHTARM,
	HITGROUP_LEFTLEG,
	HITGROUP_RIGHTLEG,

	HITGROUP_GEAR = 10
};

enum
{
	TFSpell_Fireball = 1,
	TFSpell_Bats,
	TFSpell_OverHeal,
	TFSpell_MIRV,
	TFSpell_BlastJump,
	TFSpell_Stealth,
	TFSpell_Teleport,
	TFSpell_LightningBall,
	TFSpell_Athletic,
	TFSpell_Meteor,
	TFSpell_SkeletonHorde
}

// env_explosion flags
#define SF_ENVEXPLOSION_NODAMAGE	0x00000001 // when set, ENV_EXPLOSION will not actually inflict damage
#define SF_ENVEXPLOSION_REPEATABLE	0x00000002 // can this entity be refired?
#define SF_ENVEXPLOSION_NOFIREBALL	0x00000004 // don't draw the fireball
#define SF_ENVEXPLOSION_NOSMOKE		0x00000008 // don't draw the smoke
#define SF_ENVEXPLOSION_NODECAL		0x00000010 // don't make a scorch mark
#define SF_ENVEXPLOSION_NOSPARKS	0x00000020 // don't make sparks
#define SF_ENVEXPLOSION_NOSOUND		0x00000040 // don't play explosion sound.
#define SF_ENVEXPLOSION_RND_ORIENT	0x00000080	// randomly oriented sprites
#define SF_ENVEXPLOSION_NOFIREBALLSMOKE 0x0100
#define SF_ENVEXPLOSION_NOPARTICLES 0x00000200
#define SF_ENVEXPLOSION_NODLIGHTS	0x00000400
#define SF_ENVEXPLOSION_NOCLAMPMIN	0x00000800 // don't clamp the minimum size of the fireball sprite
#define SF_ENVEXPLOSION_NOCLAMPMAX	0x00001000 // don't clamp the maximum size of the fireball sprite
#define SF_ENVEXPLOSION_SURFACEONLY	0x00002000 // don't damage the player if he's underwater.
#define SF_ENVEXPLOSION_GENERIC_DAMAGE	0x00004000 // don't do BLAST damage

// anything that blocks visibility
#define MASK_BLOCKLOS (CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MIST)

static const char Characters[] = "abcdefghijklmnopqrstuvwxyzABDEFGHIJKLMNOQRTUVWXYZ~`1234567890@#$^&*(){}:[]|¶�;<>.,?/'|";
static const float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

stock int GetClassCount(int c)
{
	int a;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && Client[i].Class==c)
			a++;
	}
	return a;
}

stock bool IsClassTaken(int c)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(Client[i].Class == c)
			return true;
	}
	return false;
}

public Action Timer_UpdateClientHud(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		Event event = CreateEvent("localplayer_pickup_weapon", true);
		event.FireToClient(client);
		event.Cancel();
	}
	return Plugin_Continue;
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

public void RemoveRagdoll(int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	int entity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action Timer_DissolveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(ragdoll))
			DissolveRagdoll(ragdoll);
	}
	return Plugin_Continue;
}

void DissolveRagdoll(int ragdoll)
{
	int dissolver = CreateEntityByName("env_entity_dissolver");
	if(dissolver == -1)
		return;

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}

stock int AttachParticle(int entity, char[] particleType, bool attach=true, float lifetime)
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return 0;
		
	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	if (attach)
	{
		Format(targetName, sizeof(targetName), "target%d", entity);
		DispatchKeyValue(entity, "targetname", targetName);
	
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", targetName);
	}
	
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	
	if (attach)
	{
		SetVariantString(targetName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	
	CreateTimer(lifetime, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);	
	
	return particle;
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		RemoveEntity(entity);
	}
	return Plugin_Continue;
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

int GetClientPointVisible(int iClient, float flDistance = 100.0)
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

float fabs(float x)
{
	return x<0 ? -x : x;
}

float fmod(float x, float y)
{
    return (x - y * RoundToFloor(x / y));
}

float fixAngle(float angle)
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

void GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

void CopyVector(const float from[3], float out[3])
{
	out[0] = from[0];
	out[1] = from[1];
	out[2] = from[2];
}

// interpolate between 2 values as a percentage
float LerpValue(float p, float a, float b)
{
	return a + (b - a) * p;
}

// remap from a->b to c->d
//float RemapValueInRange(float v, float a, float b, float c, float d)
//{
//	return c + (d - c) * (v - a) / (b - a);
//}

bool IsValidClient(int client, bool replaycheck=true)
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

stock void TakeDamage(int entity, int inflictor, int attacker, float damage, int damagetype=DMG_GENERIC, int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR, int damagecustom=0)
{
	static float damageForce2[3], damagePosition2[3];
	for(int i; i<3; i++)
	{
		damageForce2[i] = damageForce[i];
		damagePosition2[i] = damagePosition[i];
	}

	if(OnTakeDamage(entity, inflictor, attacker, damage, damagetype, weapon, damageForce2, damagePosition2, damagecustom) < Plugin_Handled)
		SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damagetype, weapon, damageForce2, damagePosition2);
}

int GetOwnerLoop(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner>0 && owner!=entity)
		return GetOwnerLoop(owner);

	return entity;
}

int GetAmmo(int client, int type)
{
	int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, type);
	if(ammo < 0)
		ammo = 0;

	return ammo;
}

void SetAmmo(int client, int ammo, int type)
{
	SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);
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

stock int TF2_GetClassnameSlot(const char[] classname)
{
	if(StrEqual(classname, "tf_weapon_scattergun") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_primary") ||
	   StrEqual(classname, "tf_weapon_soda_popper") ||
	   StrEqual(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	   StrEqual(classname, "tf_weapon_particle_cannon") ||
	   StrEqual(classname, "tf_weapon_flamethrower") ||
	   StrEqual(classname, "tf_weapon_grenadelauncher") ||
	   StrEqual(classname, "tf_weapon_cannon") ||
	   StrEqual(classname, "tf_weapon_minigun") ||
	   StrEqual(classname, "tf_weapon_shotgun_primary") ||
	   StrEqual(classname, "tf_weapon_sentry_revenge") ||
	   StrEqual(classname, "tf_weapon_drg_pomson") ||
	   StrEqual(classname, "tf_weapon_shotgun_building_rescue") ||
	   StrEqual(classname, "tf_weapon_syringegun_medic") ||
	   StrEqual(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	   StrEqual(classname, "tf_weapon_compound_bow") ||
	   StrEqual(classname, "tf_weapon_revolver"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	   StrEqual(classname, "tf_weapon_handgun_scout_secondary") ||
	   StrEqual(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	   StrEqual(classname, "tf_weapon_buff_item") ||
	   StrEqual(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	   StrEqual(classname, "tf_weapon_laser_pointer") ||
	   StrEqual(classname, "tf_weapon_mechanical_arm") ||
	   StrEqual(classname, "tf_weapon_medigun") ||
	   StrEqual(classname, "tf_weapon_smg") ||
	   StrEqual(classname, "tf_weapon_charged_smg") ||
	   StrEqual(classname, "tf_weapon_sapper"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_pda_engineer_b") ||
	  !StrContains(classname, "tf_weapon_pda_s"))
	{
		return TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_p") ||
	   StrEqual(classname, "tf_weapon_i"))
	{
		return TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_b"))
	{
		return TFWeaponSlot_PDA;
	}
	return TFWeaponSlot_Melee;
}

stock bool TF2_GetItem(int client, int &weapon, int &pos)
{
	//Could be looped through client slots, but would cause issues with >1 weapons in same slot
	static int maxWeapons;
	if(!maxWeapons)
		maxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	//Loop though all weapons (non-wearables)
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;

		if(weapon > MaxClients)
			return true;
	}
	return false;
}

stock int TF2_GetItemByClassname(int client, const char[] classname)
{
	int weapon, pos;
	while(TF2_GetItem(client, weapon, pos))
	{
		static char buffer[36];
		if(GetEntityClassname(weapon, buffer, sizeof(buffer)) && StrEqual(classname, buffer))
			return weapon;
	}
	return INVALID_ENT_REFERENCE;
}

stock void TF2_RemoveItem(int client, int weapon)
{
	// action needs to know about the item when it cancels, so we must do this here to be safe
	Items_CancelDelayedAction(client);

	/*if(TF2_IsWearable(weapon))
	{
		TF2_RemoveWearable(client, weapon);
		return;
	}*/

	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

stock bool TF2_IsWearable(int weapon)
{
	static char classname[36];
	GetEntityClassname(weapon, classname, sizeof(classname));
	return !StrContains(classname, "tf_wearable");
}

void SetActiveWeapon(int client, int entity)
{
	TF2Util_SetPlayerActiveWeapon(client, entity);
	
	/*static char buffer[36];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	FakeClientCommand(client, "use %s", buffer);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);*/
}

stock void SetSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
}

void constrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

void FadeMessage(int client, int arg1, int arg2, int arg3, int arg4=255, int arg5=255, int arg6=255, int arg7=255)
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

void PrintKeyHintText(int client, const char[] format, any ...)
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

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

void ApplyStrangeRank(int entity, int rank)
{
	int kills;
	switch(rank)
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

stock void ApplyStrangeHatRank(int entity, int rank)
{
	int points;
	switch(rank)
	{
		case 0:
			points = GetRandomInt(0, 14);

		case 1:
			points = GetRandomInt(15, 29);

		case 2:
			points = GetRandomInt(30, 49);

		case 3:
			points = GetRandomInt(50, 74);

		case 4:
			points = GetRandomInt(75, 99);

		case 5:
			points = GetRandomInt(100, 134);

		case 6:
			points = GetRandomInt(135, 174);

		case 7:
			points = GetRandomInt(175, 249);

		case 8:
			points = GetRandomInt(250, 374);

		case 9:
			points = GetRandomInt(375, 499);

		case 10:
			points = GetRandomInt(500, 724);

		case 11:
			points = GetRandomInt(725, 999);

		case 12:
			points = GetRandomInt(1000, 1499);

		case 13:
			points = GetRandomInt(1500, 1999);

		case 14:
			points = GetRandomInt(2000, 2749);

		case 15:
			points = GetRandomInt(2750, 3999);

		case 16:
			points = GetRandomInt(4000, 5499);

		case 17:
			points = GetRandomInt(5500, 7499);

		case 18:
			points = GetRandomInt(7500, 9999);

		case 19:
			points = GetRandomInt(10000, 14999);

		case 20:
			points = GetRandomInt(15000, 19999);

		default:
			return;
	}

	TF2Attrib_SetByDefIndex(entity, 214, view_as<float>(points));
	TF2Attrib_SetByDefIndex(entity, 454, view_as<float>(64));
}

int SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att, int visibleMode=2, bool preserve=false)
{
	Handle weapon;
	if(preserve)
	{
		weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	}
	else
	{
		weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	}

	if(weapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, qual);
	char atts[40][40];
	int count = ExplodeString(att, ";", atts, 40, 40);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				continue;
			}

			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	if(entity > MaxClients)
	{
		EquipPlayerWeapon(client, entity);

		if(visibleMode == 2)
		{
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		}
		else if(visibleMode)
		{
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", false);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
		}
	}
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
	static int soundchars[] = { '*', '#', '@', '>', '<', '^', ')', '}', '$' };

	char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), sound);

	for(int i=0; i<sizeof(soundchars); i++)
	{
		if(buffer[0] == soundchars[i])
		{
			strcopy(buffer, sizeof(buffer), sound[1]);
			break;
		}
	}

	FormatEx(buffer, sizeof(buffer), "sound/%s", sound);
	if(FileExists(buffer))
		AddFileToDownloadsTable(buffer);

	return PrecacheSound(sound, preload);
}

stock void ShowDeathNotice(int[] clients, int count, int attacker, int victim, int assister, int weaponid, const char[] weapon, int damagebits, int damageflags)
{
	Event event = CreateEvent("player_death", true);
	if(!event)
		return;

	event.SetInt("userid", victim);
	event.SetInt("attacker", attacker);
	event.SetInt("assister", assister);
	event.SetInt("weaponid", weaponid);
	event.SetString("weapon", weapon);
	event.SetInt("damagebits", damagebits);
	event.SetInt("damage_flags", damageflags);
	for(int i; i<count; i++)
	{
		event.FireToClient(clients[i]);
	}
	event.Cancel();
}

stock void ShowDestoryNotice(int[] clients, int count, int attacker, int victim, int assister, int weaponid, const char[] weapon, int type, int index, bool building)
{
	Event event = CreateEvent("object_destroyed", true);
	if(!event)
		return;

	event.SetInt("userid", victim);
	event.SetInt("attacker", attacker);
	event.SetInt("assister", assister);
	event.SetInt("weaponid", weaponid);
	event.SetString("weapon", weapon);
	event.SetInt("objecttype", type);
	event.SetInt("index", index);
	event.SetBool("was_building", building);
	for(int i; i<count; i++)
	{
		event.FireToClient(clients[i]);
	}
	event.Cancel();
}

stock void TF2_SendHudNotification(HudNotification_t type, bool forceShow=false)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("HudNotify"));
	bf.WriteByte(view_as<int>(type));
	bf.WriteBool(forceShow);	//Display in cl_hud_minmode
	EndMessage();
}

TFClassType TF2_GetDefaultClassFromItem(int weapon)
{
	static char classname[36];
	if(GetEntityClassname(weapon, classname, sizeof(classname)))
	{
		if(StrEqual(classname, "tf_weapon_smg") || StrEqual(classname, "tf_weapon_club"))
			return TFClass_Sniper;

		if(StrEqual(classname, "tf_weapon_grenadelauncher"))
			return TFClass_DemoMan;

		if(!StrContains(classname, "tf_weapon_pistol"))
			return TFClass_Scout;

		if(!StrContains(classname, "tf_weapon_shotgun") || StrEqual(classname, "tf_weapon_wrench"))
			return TFClass_Engineer;

		if(StrEqual(classname, "tf_weapon_flamethrower") || StrEqual(classname, "tf_weapon_fireaxe"))
			return TFClass_Pyro;
	}
	return TFClass_Unknown;
}

stock TFClassType KvGetClass(KeyValues kv, const char[] string, TFClassType defaul=TFClass_Unknown)
{
	TFClassType class;
	static char buffer[24];
	kv.GetString(string, buffer, sizeof(buffer));
	if(!buffer[0])
		return defaul;

	class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
		class = TF2_GetClass(buffer);

	return class;
}

Function KvGetFunction(KeyValues kv, const char[] string, Function defaul=INVALID_FUNCTION)
{
	static char buffer[64];
	kv.GetString(string, buffer, sizeof(buffer));
	if(buffer[0])
		return GetFunctionByName(null, buffer);

	return defaul;
}

/*float KvGetSound(KeyValues kv, const char[] string, char[] value, int length, const char[] defaul)
{
	static char buffer[2][PLATFORM_MAX_PATH+9];
	kv.GetString(string, buffer[0], sizeof(buffer[]), defaul);
	float value;
	if(ExplodeString(buffer[0], ";", buffer, sizeof(buffer), sizeof(buffer[])) > 1)
		value = StringToFloat(buffer[1]);

	strcopy(value, length, buffer[0]);
	return value;
}*/

public Action Timer_Stun(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		float duration = pack.ReadFloat();
		float slowdown = pack.ReadFloat();
		TF2_StunPlayer(client, duration, slowdown, pack.ReadCell());
	}
	return Plugin_Continue;
}

public Action Timer_MyBlood(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && !IsSpec(client) && GetClientHealth(client)<26 && !(GetEntityFlags(client) & FL_DUCKING))
		Config_DoReaction(client, "lowhealth");

	return Plugin_Continue;
}

void StartHealingTimer(int client, float delay, int health, int amount=0, bool maxhealth=true, bool require=false)
{
	DataPack pack;
	CreateDataTimer(delay, Timer_Healing, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(require);
	pack.WriteCell(health);
	pack.WriteCell(maxhealth);
	pack.WriteCell(amount);
}

public Action Timer_Healing(Handle timer, DataPack pack)
{
	pack.Reset();
	int userid = pack.ReadCell();
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if(pack.ReadCell() && !Client[client].Extra2)
		return Plugin_Stop;

	int current = GetClientHealth(client);
	int health = pack.ReadCell();
	if(pack.ReadCell())
	{
		int max = Classes_GetMaxHealth(client);
		if(current<=max && current+health>max)
			health = max-current;
	}

	health = current+health;
	if(health < 1)
	{
		ForcePlayerSuicide(client);
	}
	else if(health)
	{
		SetEntityHealth(client, health);
	}

	current = pack.ReadCell();
	if(current < 1)
		return Plugin_Stop;

	pack.Position--;
	pack.WriteCell(current-1, false);
	return Plugin_Continue;
}

void ApplyHealEvent(int entindex, int amount)
{
	Event event = CreateEvent("player_healonhit", true);

	event.SetInt("entindex", entindex);
	event.SetInt("amount", amount);

	event.Fire();
}

void EndRound(any team)
{
	int entity = CreateEntityByName("game_round_win"); 
	DispatchKeyValue(entity, "force_map_reset", "1");
	SetEntProp(entity, Prop_Data, "m_iTeamNum", team);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "RoundWin");
}



stock void EmitSoundToAll2(const char[] sample,
				 int entity = SOUND_FROM_PLAYER,
				 int channel = SNDCHAN_AUTO,
				 int level = SNDLEVEL_NORMAL,
				 int flags = SND_NOFLAGS,
				 float volume = SNDVOL_NORMAL,
				 int pitch = SNDPITCH_NORMAL,
				 int speakerentity = -1,
				 const float origin[3] = NULL_VECTOR,
				 const float dir[3] = NULL_VECTOR,
				 bool updatePos = true,
				 float soundtime = 0.0)
{
	int[] clients = new int[MaxClients];
	int total = 0;

	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !Client[i].DownloadMode)
		{
			clients[total++] = i;
		}
	}

	if (total)
	{
		EmitSound(clients, total, sample, entity, channel,
			level, flags, volume, pitch, speakerentity,
			origin, dir, updatePos, soundtime);
	}
}

void AnglesToVelocity(const float ang[3], float vel[3], float speed=1.0)
{
	vel[0] = Cosine(DegToRad(ang[1]));
	vel[1] = Sine(DegToRad(ang[1]));
	vel[2] = Sine(DegToRad(ang[0])) * -1.0;
	
	NormalizeVector(vel, vel);
	
	ScaleVector(vel, speed);
}

bool ObstactleBetweenEntities(int entity1, int entity2)
{
	static float pos1[3], pos2[3];
	if(IsValidClient(entity1))
	{
		GetClientEyePosition(entity1, pos1);
	}
	else
	{
		GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", pos1);
	}

	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", pos2);

	Handle trace = TR_TraceRayFilterEx(pos1, pos2, MASK_ALL, RayType_EndPoint, Trace_DontHitEntity, entity1);

	bool hit = TR_DidHit(trace);
	int index = TR_GetEntityIndex(trace);
	delete trace;

	if(!hit || index!=entity2)
		return true;

	return false;
}

bool IsEntityStuck(int entity)
{
	static float min[3], max[3], pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecMins", min);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", max);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	
	TR_TraceHullFilter(pos, pos, min, max, MASK_SOLID, Trace_DontHitEntity, entity);
	return (TR_DidHit());
}

// Set a single byte of data on the entity which can be accessed by it's own materials (clientside)
// This overwrites the entity's alpha, which is normally not used so it shouldn't affect any visuals
void SetEntityMaterialData(int entity, int data)
{
	int r, g, b, a;
	GetEntityRenderColor(entity, r, g, b, a);
	SetEntityRenderColor(entity, r, g, b, data);
}

int TF2_CreateGlow(int client, const char[] model)
{
	if(!model[0])
		return -1;

	int prop = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(prop))
	{
		int team = GetClientTeam(client);
		SetEntProp(prop, Prop_Data, "m_iInitialTeamNum", team);
		SetEntProp(prop, Prop_Send, "m_iTeamNum", team);

		DispatchSpawn(prop);

		SetEntityModel(prop, model);
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
	if(Enabled)
	{
		if(!IsValidClient(target))
			return Plugin_Continue;

		int client = GetEntPropEnt(entity, Prop_Data, "m_hParent");
		if(IsValidClient(client) && IsPlayerAlive(client))
			return Classes_OnGlowPlayer(target, client) ? Plugin_Continue : Plugin_Stop;
	}

	SDKUnhook(entity, SDKHook_SetTransmit, GlowTransmit);
	AcceptEntityInput(entity, "Kill");
	return Plugin_Continue;
}

public bool Trace_WallsOnly(int entity, int mask)
{
	return false;
}

public bool Trace_WorldAndBrushes(int entity, int mask)
{
	// world
	if (!entity)
		return true;
	
	char buffer[8];
	// anything prefixed with func_ can be safely regarded as a brush entity
	return (GetEntityClassname(entity, buffer, sizeof(buffer)) && (!strncmp(buffer, "func_", 5, false)));
}

public bool Trace_OnlyHitWorld(int entity, int mask)
{
	return !entity;
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity!=data;
}

public bool Trace_DontHitPlayers(int entity, int mask, any data)
{
	return entity <= 0 || entity > MaxClients;
}

public bool Trace_PlayerOnly(int client, int mask, any data)
{
	return (client!=data && client>0 && client<=MaxClients);
}

bool IsSpec(int client)
{
	if(!IsPlayerAlive(client) || TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return true;

	return false;
}

void TimeToMinutesSeconds(float time, int& minutes, int& seconds)
{
	minutes = RoundToFloor(time / 60.0);
	seconds = RoundToFloor(fmod(time, 60.0));
}

bool IsPointTouchingBox(float pos[3], float mins[3], float maxs[3])
{
	if ( pos[0] < mins[0] || pos[0] > maxs[0] ||
		 pos[1] < mins[1] || pos[1] > maxs[1] ||
		 pos[2] < mins[2] || pos[2] > maxs[2] )
		return false;
		
	return true;
}

int GetEntityFromHandle(any handle)
{
	int ent = handle & 0xFFF;
	if (ent == 0xFFF)
		ent = -1;
	return ent;
}

int GetEntityFromAddress(Address entity)
{
	if (entity == Address_Null)
		return -1;

	return GetEntityFromHandle(LoadFromAddress(entity + view_as<Address>(FindDataMapInfo(0, "m_angRotation") + 12), NumberType_Int32));
}

int StringtToCharArray(Address stringt, char[] buffer, int maxlen)
{
	if (stringt == Address_Null)
	{
		buffer[0] = '\0';
		return 0;
	}

	if (maxlen <= 0) 
	{
		ThrowError("Buffer size is negative or zero");
	}

	int max = maxlen-1;
	int i = 0;
	for (; i < max; i++) 
	{
		if ((buffer[i] = view_as<char>(LoadFromAddress(stringt + view_as<Address>(i), NumberType_Int8))) == '\0') 
		{
			return i;
		}
	}

	buffer[i] = '\0';
	return i;
}

void TriggerRelays(const char[] name)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "logic_relay")) != -1)
	{
		char entityname[32];
		GetEntPropString(entity, Prop_Data, "m_iName", entityname, sizeof(entityname));
		if (StrEqual(entityname, name, false))
		{
			AcceptEntityInput(entity, "Trigger");
			break;
		}
	}
}

stock int TraceClientViewEntity(int client)
{
	float m_vecOrigin[3];
	float m_angRotation[3];

	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);

	Handle trace = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;

	if (TR_DidHit(trace))
	{
		pEntity = TR_GetEntityIndex(trace);
		CloseHandle(trace);
		return pEntity;
	}

	if(trace != INVALID_HANDLE)
	{
		CloseHandle(trace);
	}
	
	return -1;
}

public bool TRDontHitSelf(int entity, int mask, any data)
{
	return (1 <= entity <= MaxClients) && (entity != data);
}

stock int TF2_CreateLightEntity(float radius, int color[4], int brightness, float lifetime)
{
	int entity = CreateEntityByName("light_dynamic");
	if (entity != -1)
	{			
		char lightColor[32];
		Format(lightColor, sizeof(lightColor), "%d %d %d", color[0], color[1], color[2]);
		DispatchKeyValue(entity, "rendercolor", lightColor);
		
		SetVariantFloat(radius);
		AcceptEntityInput(entity, "spotlight_radius");
		
		SetVariantFloat(radius);
		AcceptEntityInput(entity, "distance");
		
		SetVariantInt(brightness);
		AcceptEntityInput(entity, "brightness");
		
		SetVariantInt(1);
		AcceptEntityInput(entity, "cone");
		
		DispatchSpawn(entity);
		
		ActivateEntity(entity);
		AcceptEntityInput(entity, "TurnOn");
		SetEntityRenderFx(entity, RENDERFX_SOLID_SLOW);
		SetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);
		
		int flags = GetEdictFlags(entity);
		if (!(flags & FL_EDICT_ALWAYS))
		{
			flags |= FL_EDICT_ALWAYS;
			SetEdictFlags(entity, flags);
		}
		
		CreateTimer(lifetime, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return entity;
}

stock int CreateExplosion(int attacker = -1, int damage = 0, int radius = -1, float pos[3], int flags = 0, const char[] killIcon = "", bool immediate = true)
{
	int explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
		return -1;
	
	char buffer[32];
	
	DispatchKeyValueVector(explosion, "origin", pos);
	
	Format(buffer, sizeof(buffer), "%d", damage);
	DispatchKeyValue(explosion, "iMagnitude", buffer);
	
	// set radius override if specified
	if (radius != -1)
	{
		Format(buffer, sizeof(buffer), "%d", radius);
		DispatchKeyValue(explosion, "iRadiusOverride", buffer);
	}
	
	Format(buffer, sizeof(buffer), "%d", flags);
	DispatchKeyValue(explosion, "spawnflags", buffer);
	
	// set attacker if specified
	if (attacker != -1)
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", attacker);
	
	DispatchSpawn(explosion);
	
	// change the kill icon if specified
	if (killIcon[0])
	{
		Format(buffer, sizeof(buffer), "classname %s", killIcon);
		SetVariantString(buffer);
		AcceptEntityInput(explosion, "AddOutput");
	}
	
	// do the explosion and clean up right here if it's set to do immediately, or let the explosion be manipulated further if not
	if (immediate)
	{
		AcceptEntityInput(explosion, "Explode");
		CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return explosion;
}

stock void StrToLower(char[] buffer)
{
	int length = strlen(buffer);
	for (int i = 0; i < length; i++)
		buffer[i] = CharToLower(buffer[i]);
}