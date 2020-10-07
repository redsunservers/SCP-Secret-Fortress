static Handle SDKTeamAddPlayer;
static Handle SDKTeamRemovePlayer;
Handle SDKEquipWearable;
Handle SDKCreateWeapon;
Handle SDKInitPickup;
Handle SDKInitWeapon;
static Handle SDKGlobalTeam;
static Handle SDKChangeTeam;
static Handle SDKTeamAddPlayerRaw;
static Handle SDKTeamRemovePlayerRaw;
static Handle SDKGetNextThink;

void SDKCall_Setup(GameData gamedata)
{
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

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
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

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "GetGlobalTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	SDKGlobalTeam = EndPrepSDKCall();
	if(!SDKGlobalTeam)
		LogError("[Gamedata] Could not find GetGlobalTeam");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::ChangeTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKChangeTeam = EndPrepSDKCall();
	if(!SDKChangeTeam)
		LogError("[Gamedata] Could not find CBaseEntity::ChangeTeam");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamAddPlayerRaw = EndPrepSDKCall();
	if(!SDKTeamAddPlayerRaw)
		LogError("[Gamedata] Could not find CTeam::AddPlayer");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKTeamRemovePlayerRaw = EndPrepSDKCall();
	if(!SDKTeamRemovePlayerRaw)
		LogError("[Gamedata] Could not find CTeam::RemovePlayer");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::GetNextThink");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	SDKGetNextThink = EndPrepSDKCall();
	if(!SDKGetNextThink)
		LogError("[Gamedata] Could not find CBaseEntity::GetNextThink");
}

Address SDKCall_GetGlobalTeam(any team)
{
	if(SDKGlobalTeam)
		return SDKCall(SDKGlobalTeam, team);

	return Address_Null;
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

void ChangeClientTeamEx(int client, TFTeam newTeam)
{
	if(!SDKTeamAddPlayer || !SDKTeamRemovePlayer)
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