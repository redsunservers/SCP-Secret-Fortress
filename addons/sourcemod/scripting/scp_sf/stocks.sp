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

static const char Characters[] = "abcdefghijklmnopqrstuvwxyzABDEFGHIJKLMNOQRTUVWXYZ~`1234567890@#$^&*(){}:[]|¶�;<>.,?/'|";
static const float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

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

stock bool IsClassTaken(ClassEnum c)
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

ArrayList GetSCPList()
{
	ArrayList list = new ArrayList();
	for(ClassEnum i=Class_035; i<ClassEnum; i++)
	{
		if(ClassEnabled[i])
			list.Push(i);
	}
	return list;
}

ClassEnum GetSCPRand(ArrayList list, ClassEnum pref=Class_Spec)
{
	if(pref >= Class_035)
	{
		int index = list.FindValue(pref);
		if(index != -1)
		{
			list.Erase(index);
			return pref;
		}

		if(pref == Class_939)
		{
			index = list.FindValue(Class_9392);
			if(index != -1)
			{
				list.Erase(index);
				return Class_9392;
			}
		}
	}

	int index = list.Length;
	if(!index)
		return Class_Spec;
	
	index = GetRandomInt(0, index-1);
	ClassEnum scp = list.Get(index);
	list.Erase(index);
	return scp;
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

int DissolveRagdoll(int ragdoll)
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

void SpawnPickup(int iClient, const char[] sClassname)
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

float fabs(float x)
{
	return x<0 ? -x : x;
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

float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

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

int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

int GetOwnerLoop(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner>0 && owner!=entity)
		return GetOwnerLoop(owner);

	return entity;
}

void SetAmmo(int client, int weapon, int ammo=-1, int clip=-1)
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

void TF2_RefillWeaponAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		GivePlayerAmmo(client, 9999, ammotype, true);
}

void TF2_SetWeaponAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}

int TF2_GetWeaponAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	
	return -1;
}

TFTeam TF2_GetTeam(int entity)
{
	return view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum"));
}

stock void SetSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
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

void ApplyStrangeHatRank(int entity, int rank)
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
	TF2Attrib_SetByDefIndex(entity, 292, view_as<float>(64));
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

int PrecacheModelEx(const char[] model, bool preload=false)
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

int PrecacheSoundEx(const char[] sound, bool preload=false)
{
	char buffer[PLATFORM_MAX_PATH];
	FormatEx(buffer, sizeof(buffer), "sound/%s", sound);
	ReplaceStringEx(buffer, sizeof(buffer), "#", "");
	if(FileExists(buffer))
		AddFileToDownloadsTable(buffer);

	return PrecacheSound(sound, preload);
}

void ShowDeathNotice(int[] clients, int count, int attacker, int victim, int assister, int weaponid, const char[] weapon, int damagebits, int damageflags)
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

void ShowDestoryNotice(int[] clients, int count, int attacker, int victim, int assister, int weaponid, const char[] weapon, int type, int index, bool building)
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

void TF2_SendHudNotification(HudNotification_t type, bool forceShow=false)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("HudNotify"));
	bf.WriteByte(view_as<int>(type));
	bf.WriteBool(forceShow);	//Display in cl_hud_minmode
	EndMessage();
}

void ChangeClientClass(int client, any class)
{
	SetEntProp(client, Prop_Send, "m_iClass", class);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class);

	float primary = 1.0;
	float secondary = 1.0;
	switch(class)
	{
		case TFClass_Scout:
		{
			primary = 31.25;		// 32 -> 1000
			secondary = 5.555555;	// 36 -> 200
		}
		case TFClass_Soldier:
		{
			primary = 50.0;		// 20 -> 1000
			secondary = 6.25;	// 32 -> 200
		}
		case TFClass_Pyro, TFClass_Heavy:
		{
			primary = 5.0;		// 200 -> 1000
			secondary = 6.25;	// 32 -> 200
		}
		case TFClass_DemoMan, TFClass_Spy:
		{
			primary = 62.5;		// 16 -> 1000
			secondary = 8.333333;	// 24 -> 200
		}
		case TFClass_Engineer:
		{
			primary = 31.25;		// 32 -> 1000
			secondary = 1.0;		// 200 -> 200
		}
		case TFClass_Medic:
		{
			primary = 6.666667;	// 150 -> 1000
			// Medic class is never used as a gun class so...
		}
		case TFClass_Sniper:
		{
			primary = 40.0;		// 25 -> 1000
			secondary = 2.666666;	// 75 -> 200
		}
	}

	if(Client[client].Class==Class_DBoi || Client[client].Class==Class_Scientist)
		secondary /= 2.0;

	TF2Attrib_SetByDefIndex(client, 37, primary);
	TF2Attrib_SetByDefIndex(client, 25, secondary);
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
	if(client && IsClientInGame(client) && !IsSpec(client) && GetClientHealth(client)<26)
		Config_DoReaction(client, "lowhealth");

	return Plugin_Continue;
}

public bool TraceRayPlayerOnly(int client, int mask, any data)
{
	return (client!=data && IsValidClient(client) && IsValidClient(data));
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

public bool Trace_OnlyHitWorld(int entity, int mask)
{
	return !entity;
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity!=data;
}

bool IsSpec(int client)
{
	if(Client[client].Class == Class_Spec)
		return true;

	if(!IsPlayerAlive(client))
	{
		LogMessage("%N (%d) was not alive and was not Class Spec", client, client);
		return true;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		LogMessage("%N (%d) was a ghost and was not Class Spec", client, client);
		return true;
	}

	return false;
}