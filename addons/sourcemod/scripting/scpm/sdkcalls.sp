#pragma semicolon 1
#pragma newdecls required

static Handle SDKEquipWearable;
static Handle SDKGetMaxHealth;
static Handle SDKStartLagCompensation;
static Handle SDKFinishLagCompensation;
static Handle SDKCreateWeapon;
static Handle SDKInitWeapon;
static Handle SDKInitPickup;
//static Handle SDKGetMaxAmmo;
static Handle SDKSetSpeed;
static Handle SDKGiveNamedItem;

void SDKCall_PluginStart()
{
	GameData gamedata = new GameData("sm-tf2.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	
	gamedata = new GameData("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
	
	delete gamedata;
	
	
	gamedata = new GameData("ff2");
	
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


	gamedata = new GameData("randomizer");
	
	//StartPrepSDKCall(SDKCall_Entity);
	//PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::GetMaxAmmo");
	//PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	//PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	//PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	//SDKGetMaxAmmo = EndPrepSDKCall();
	//if(!SDKGetMaxAmmo)
	//	LogError("[Gamedata] Could not find CTFPlayer::GetMaxAmmo");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTFPlayer::GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	SDKGiveNamedItem = EndPrepSDKCall();
	if(!SDKGiveNamedItem)
		LogError("[Gamedata] Could not find CTFPlayer::GiveNamedItem");
	
	delete gamedata;
}

int SDKCall_CreateDroppedWeapon(int client, const float origin[3], const float angles[3], const char[] model, Address item)
{
	if(SDKCreateWeapon)
		return SDKCall(SDKCreateWeapon, client, origin, angles, model, item);

	return INVALID_ENT_REFERENCE;
}

void SDKCall_EquipWearable(int client, int entity)
{
	if(SDKEquipWearable)
	{
		SDKCall(SDKEquipWearable, client, entity);
	}
	else
	{
		RemoveEntity(entity);
	}
}

void SDKCall_FinishLagCompensation(int client)
{
	if(SDKStartLagCompensation && SDKFinishLagCompensation)
	{
		Address value = DHook_GetLagCompensationManager();
		if(value)
			SDKCall(SDKFinishLagCompensation, value, client);
	}
}
/*
int SDKCall_GetMaxAmmo(int client, int type, int class = -1)
{
	return SDKGetMaxAmmo ? SDKCall(SDKGetMaxAmmo, client, type, class) : -1;
}
*/
int SDKCall_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

int SDKCall_GiveNamedItem(int client, const char[] classname, int subType, Address item, bool force)
{
	return SDKCall(SDKGiveNamedItem, client, classname, subType, item, force);
}

void SDKCall_InitDroppedWeapon(int droppedWeapon, int client, int fromWeapon, bool swap, bool sewerslide)
{
	if(SDKInitWeapon)
		SDKCall(SDKInitWeapon, droppedWeapon, client, fromWeapon, swap, sewerslide);
}

void SDKCall_InitPickup(int entity, int client, int weapon)
{
	if(SDKInitPickup)
		SDKCall(SDKInitPickup, entity, client, weapon);
}

void SDKCall_SetSpeed(int client)
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

void SDKCall_StartLagCompensation(int client)
{
	if(SDKStartLagCompensation && SDKFinishLagCompensation)
	{
		static Address currentCommand;	// m_pCurrentCommand
		if(!currentCommand)
			currentCommand = view_as<Address>(FindSendPropInfo("CTFPlayer", "m_hViewModel") + 76);
		
		Address value = DHook_GetLagCompensationManager();
		if(value)
			SDKCall(SDKStartLagCompensation, value, client, GetEntityAddress(client) + currentCommand);
	}
}
