static Handle SDKChangeTeam;
static Handle SDKGetBaseEntity;
static Handle SDKGetNextThink;
static Handle SDKEquipWearable;
static Handle SDKTeamAddPlayerRaw;
static Handle SDKTeamAddPlayer;
static Handle SDKTeamRemovePlayerRaw;
static Handle SDKTeamRemovePlayer;
Handle SDKCreateWeapon;
Handle SDKInitWeapon;
static Handle SDKInitPickup;
static Handle SDKSetSpeed;
static Handle SDKGlobalTeam;

void SDKCall_Setup(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::ChangeTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKChangeTeam = EndPrepSDKCall();
	if(!SDKChangeTeam)
		LogError("[Gamedata] Could not find CBaseEntity::ChangeTeam");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::GetBaseEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKGetBaseEntity = EndPrepSDKCall();
	if(!SDKGetBaseEntity)
		LogError("[Gamedata] Could not find CBaseEntity::GetBaseEntity");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::GetNextThink");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	SDKGetNextThink = EndPrepSDKCall();
	if(!SDKGetNextThink)
		LogError("[Gamedata] Could not find CBaseEntity::GetNextThink");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find CBasePlayer::EquipWearable");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamAddPlayerRaw = EndPrepSDKCall();
	if(!SDKTeamAddPlayerRaw)
		LogError("[Gamedata] Could not find CTeam::AddPlayer");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamAddPlayer = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamRemovePlayerRaw = EndPrepSDKCall();
	if(!SDKTeamRemovePlayerRaw)
		LogError("[Gamedata] Could not find CTeam::RemovePlayer");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamRemovePlayer = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::Create");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKCreateWeapon = EndPrepSDKCall();
	if(!SDKCreateWeapon)
		LogError("[Gamedata] Could not find CTFDroppedWeapon::Create");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::InitDroppedWeapon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	SDKInitWeapon = EndPrepSDKCall();
	if(!SDKInitWeapon)
		LogError("[Gamedata] Could not find CTFDroppedWeapon::InitDroppedWeapon");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFDroppedWeapon::InitPickedUpWeapon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKInitPickup = EndPrepSDKCall();
	if(!SDKInitPickup)
		LogError("[Gamedata] Could not find CTFDroppedWeapon::InitPickedUpWeapon");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed");
	SDKSetSpeed = EndPrepSDKCall();
	if(!SDKSetSpeed)
		LogError("[Gamedata] Could not find CTFPlayer::TeamFortress_SetSpeed");

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "GetGlobalTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	SDKGlobalTeam = EndPrepSDKCall();
	if(!SDKGlobalTeam)
		LogError("[Gamedata] Could not find GetGlobalTeam");
}

void SDKCall_ChangeTeam(int entity, any team)
{
	if(SDKChangeTeam)
		SDKCall(SDKChangeTeam, entity, team);
}

void SDKCall_AddPlayer(Address team, int client)
{
	if(SDKTeamAddPlayerRaw)
		SDKCall(SDKTeamAddPlayerRaw, team, client);
}

void SDKCall_RemovePlayer(Address team, int client)
{
	if(SDKTeamRemovePlayerRaw)
		SDKCall(SDKTeamRemovePlayerRaw, team, client);
}

float SDKCall_GetNextThink(int entity, const char[] buffer="")
{
	if(!SDKGetNextThink)
		return 0.0;

	if(buffer[0])
		return SDKCall(SDKGetNextThink, entity, buffer);

	return SDKCall(SDKGetNextThink, entity, NULL_STRING);
}

int SDKCall_GetBaseEntity(Address entity)
{
	if(SDKGetBaseEntity)
		return SDKCall(SDKGetBaseEntity, entity);

	return 1;
}

int SDKCall_CreateDroppedWeapon(int client, const float origin[3], const float angles[3], const char[] model, Address item)
{
	if(SDKCreateWeapon)
		return SDKCall(SDKCreateWeapon, client, origin, angles, model, item);

	return INVALID_ENT_REFERENCE;
}

void SDKCall_InitDroppedWeapon(int droppedWeapon, int client, int fromWeapon, bool swap, bool suicide)
{
	if(SDKInitWeapon)
		SDKCall(SDKInitWeapon, droppedWeapon, client, fromWeapon, swap, suicide);
}

void SDKCall_InitPickup(int entity, int client, int weapon)
{
	if(SDKInitPickup)
		SDKCall(SDKInitPickup, entity, client, weapon);
}

void SDKCall_SetSpeed(int client)
{
	if(SDKSetSpeed)
		SDKCall(SDKSetSpeed, client);
}

Address SDKCall_GetGlobalTeam(any team)
{
	if(SDKGlobalTeam)
		return SDKCall(SDKGlobalTeam, team);

	return Address_Null;
}

void ChangeClientTeamEx(int client, any newTeam)
{
	if(!SDKTeamAddPlayer || !SDKTeamRemovePlayer)
	{
		int state = GetEntProp(client, Prop_Send, "m_lifeState");
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, (newTeam<=TFTeam_Spectator) ? view_as<int>(TFTeam_Red) : newTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", state);
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
		else if(entityTeam == newTeam)
		{
			SDKCall(SDKTeamAddPlayer, team, client);
		}
	}
	SetEntProp(client, Prop_Send, "m_iTeamNum", newTeam);
}

int TF2_CreateHat(int client, int index, int quality=0, int level=1)
{
	if(!SDKEquipWearable)
		return -1;

	int wearable = CreateEntityByName("tf_wearable");
	if(IsValidEntity(wearable))
	{
		SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(wearable, Prop_Send, "m_bInitialized", true);
		SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
		SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);

		DispatchSpawn(wearable);
		SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", true);

		SDKCall(SDKEquipWearable, client, wearable);
	}
	return wearable;
}

int TF2_CreateDroppedWeapon(int client, int weapon, bool swap, const float origin[3], const float angles[3], KeycardEnum keycard=Keycard_None)
{
	if(!SDKCreateWeapon || !SDKInitWeapon)
		return INVALID_ENT_REFERENCE;

	static char buffer[PLATFORM_MAX_PATH];
	GetEntityNetClass(weapon, buffer, sizeof(buffer));
	int offset = FindSendPropInfo(buffer, "m_Item");
	if(offset < 0)
	{
		LogError("Failed to find m_Item on: %s", buffer);
		return INVALID_ENT_REFERENCE;
	}

	switch(keycard)
	{
		case Keycard_None:
		{
			int index;
			if(HasEntProp(weapon, Prop_Send, "m_iWorldModelIndex"))
			{
				index = GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex");
			}
			else
			{
				index = GetEntProp(weapon, Prop_Send, "m_nModelIndex");
			}

			if(index < 1)
				return INVALID_ENT_REFERENCE;

			ModelIndexToString(index, buffer, sizeof(buffer));
		}
		case Keycard_Radio:
		{
			strcopy(buffer, sizeof(buffer), RADIO_MODEL);
		}
		default:
		{
			strcopy(buffer, sizeof(buffer), KEYCARD_MODEL);
		}
	}

	//Dropped weapon doesn't like being spawn high in air, create on ground then teleport back after DispatchSpawn
	TR_TraceRayFilter(origin, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
	if(!TR_DidHit())	//Outside of map
		return INVALID_ENT_REFERENCE;

	static float originSpawn[3];
	TR_GetEndPosition(originSpawn);

	// CTFDroppedWeapon::Create deletes tf_dropped_weapon if there too many in map, pretend entity is marking for deletion so it doesnt actually get deleted
	ArrayList droppedWeapons = new ArrayList();
	int entity = MaxClients+1;
	while((entity=FindEntityByClassname(entity, "tf_dropped_weapon")) > MaxClients)
	{
		int flags = GetEntProp(entity, Prop_Data, "m_iEFlags");
		if(flags & EFL_KILLME)
			continue;

		SetEntProp(entity, Prop_Data, "m_iEFlags", flags|EFL_KILLME);
		droppedWeapons.Push(entity);
	}

	//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
	int droppedWeapon = SDKCall(SDKCreateWeapon, -1, originSpawn, angles, buffer, GetEntityAddress(weapon)+view_as<Address>(offset));

	int length = droppedWeapons.Length;
	for(int i; i<length; i++)
	{
		entity = droppedWeapons.Get(i);
		offset = GetEntProp(entity, Prop_Data, "m_iEFlags");
		offset = offset &= ~EFL_KILLME;
		SetEntProp(entity, Prop_Data, "m_iEFlags", offset);
	}

	delete droppedWeapons;
	if(droppedWeapon != INVALID_ENT_REFERENCE)
	{
		DispatchSpawn(droppedWeapon);

		//Check if weapon is not marked for deletion after spawn, otherwise we may get bad physics model leading to a crash
		if(GetEntProp(droppedWeapon, Prop_Data, "m_iEFlags") & EFL_KILLME)
		{
			LogError("Unable to create dropped weapon with model '%s'", buffer);
			return INVALID_ENT_REFERENCE;
		}

		SDKCall(SDKInitWeapon, droppedWeapon, client, weapon, swap, false);

		switch(keycard)
		{
			case Keycard_None:
			{
			}
			case Keycard_Radio:
			{
				Format(buffer, sizeof(buffer), "scp_radio_%f", Client[client].Power);
				SetEntPropString(droppedWeapon, Prop_Data, "m_iName", buffer);
			}
			default:
			{
				SetEntPropString(droppedWeapon, Prop_Data, "m_iName", KeycardNames[keycard]);
				SetVariantInt(KeycardSkin[keycard]);
				AcceptEntityInput(droppedWeapon, "Skin");
			}
		}

		TeleportEntity(droppedWeapon, origin, NULL_VECTOR, NULL_VECTOR);
	}
	return droppedWeapon;
}