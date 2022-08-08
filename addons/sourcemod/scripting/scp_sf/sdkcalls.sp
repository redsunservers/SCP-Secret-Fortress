static Handle SDKGetBaseEntity;
static Handle SDKEquipWearable;
static Handle SDKTeamAddPlayer;
static Handle SDKTeamRemovePlayer;
Handle SDKCreateWeapon;
Handle SDKInitWeapon;
static Handle SDKInitPickup;
static Handle SDKSetSpeed;
static Handle SDKFindCriterionIndex;
static Handle SDKRemoveCriteria;

void SDKCall_Setup(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::GetBaseEntity");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKGetBaseEntity = EndPrepSDKCall();
	if(!SDKGetBaseEntity)
		LogError("[Gamedata] Could not find CBaseEntity::GetBaseEntity");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find CBasePlayer::EquipWearable");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamAddPlayer = EndPrepSDKCall();
	if(!SDKTeamAddPlayer)
		LogError("[Gamedata] Could not find CTeam::AddPlayer");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamRemovePlayer = EndPrepSDKCall();
	if(!SDKTeamRemovePlayer)
		LogError("[Gamedata] Could not find CTeam::RemovePlayer");

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
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "AI_CriteriaSet::FindCriterionIndex");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	SDKFindCriterionIndex = EndPrepSDKCall();
	if (!SDKFindCriterionIndex)
		LogMessage("Failed to create SDKCall: AI_CriteriaSet::FindCriterionIndex");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "AI_CriteriaSet::RemoveCriteria");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	SDKRemoveCriteria = EndPrepSDKCall();
	if (!SDKRemoveCriteria)
		LogMessage("Failed to create SDKCall: AI_CriteriaSet::RemoveCriteria");
}

void SDKCall_EquipWearable(int client, int entity)
{
	if(SDKEquipWearable)
		SDKCall(SDKEquipWearable, client, entity);
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

int SDKCall_FindCriterionIndex(int criteriaSet, const char[] criteria)
{
	if (SDKFindCriterionIndex)
		return SDKCall(SDKFindCriterionIndex, criteriaSet, criteria);
	else
		return -1;
}

void SDKCall_RemoveCriteria(int criteriaSet, const char[] criteria)
{
	if (SDKRemoveCriteria)
		SDKCall(SDKRemoveCriteria, criteriaSet, criteria);
}