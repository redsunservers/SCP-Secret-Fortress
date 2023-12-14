#pragma semicolon 1
#pragma newdecls required

static Handle SDKEquipWearable;
static Handle SDKGetMaxHealth;
static Handle SDKStartLagCompensation;
static Handle SDKFinishLagCompensation;
static Handle SDKTeamAddPlayer;
static Handle SDKTeamRemovePlayer;
static Handle SDKCreateWeapon;
static Handle SDKInitWeapon;
static Handle SDKInitPickup;
static Handle SDKSetSpeed;

static int CurrentCommandOffset;

void SDKCalls_PluginStart()
{
	GameData gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
	
	delete gamedata;
	
	
	gamedata = new GameData("scp_sf");
	
	CurrentCommandOffset = CreateOffset(gamedata, "CBasePlayer::m_pCurrentCommand");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CLagCompensationManager::StartLagCompensation");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer);
	SDKStartLagCompensation = EndPrepSDKCall();
	if(!SDKStartLagCompensation)
		LogError("[Gamedata] Could not find CLagCompensationManager::StartLagCompensation");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CLagCompensationManager::FinishLagCompensation");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	SDKFinishLagCompensation = EndPrepSDKCall();
	if(!SDKFinishLagCompensation)
		LogError("[Gamedata] Could not find CLagCompensationManager::FinishLagCompensation");
	
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
	
	delete gamedata;
}

int SDKCalls_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

void SDKCalls_StartLagCompensation(int client)
{
	if(SDKStartLagCompensation && SDKFinishLagCompensation && CurrentCommandOffset != -1)
	{
		Address value = DHooks_GetLagCompensationManager();
		if(!value)
			ThrowError("Trying to start lag compensation before any existed");
		
		SDKCall(SDKStartLagCompensation, value, client, GetEntityAddress(client) + view_as<Address>(CurrentCommandOffset));
	}
}

void SDKCalls_FinishLagCompensation(int client)
{
	if(SDKStartLagCompensation && SDKFinishLagCompensation && CurrentCommandOffset != -1)
	{
		Address value = DHooks_GetLagCompensationManager();
		if(!value)
			ThrowError("Trying to finish lag compensation before any existed");
		
		SDKCall(SDKFinishLagCompensation, value, client);
	}
}

void SDKCalls_ChangeClientTeam(int client, int newTeam)
{
	int clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	if(newTeam == clientTeam)
		return;
	
	if(SDKTeamAddPlayer && SDKTeamRemovePlayer)
	{
		int entity = MaxClients+1;
		while((entity = FindEntityByClassname(entity, "tf_team")) != -1)
		{
			int entityTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
			if(entityTeam == clientTeam)
			{
				SDKCall(SDKTeamRemovePlayer, entity, client);
			}
			else if(entityTeam == newTeam)
			{
				SDKCall(SDKTeamAddPlayer, entity, client);
			}
		}
		
		SetEntProp(client, Prop_Send, "m_iTeamNum", newTeam);
	}
	else
	{
		if(newTeam < TFTeam_Red)
			newTeam += 2;
		
		int state = GetEntProp(client, Prop_Send, "m_lifeState");
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, newTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", state);
	}
}

int SDKCalls_CreateDroppedWeapon(int client, const float origin[3], const float angles[3], const char[] model, Address item)
{
	if(SDKCreateWeapon)
		return SDKCall(SDKCreateWeapon, client, origin, angles, model, item);

	return INVALID_ENT_REFERENCE;
}

void SDKCalls_InitDroppedWeapon(int droppedWeapon, int client, int fromWeapon, bool swap, bool suicide)
{
	if(SDKInitWeapon)
		SDKCall(SDKInitWeapon, droppedWeapon, client, fromWeapon, swap, suicide);
}

void SDKCalls_InitPickup(int entity, int client, int weapon)
{
	if(SDKInitPickup)
		SDKCall(SDKInitPickup, entity, client, weapon);
}

void SDKCalls_SetSpeed(int client)
{
	if(SDKSetSpeed)
	{
		SDKCall(SDKSetSpeed, client);
	}
	else
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}
