#pragma semicolon 1
#pragma newdecls required

static int ViewmodelRef[MAXPLAYERS+1] = {-1, ...};

void ViewModel_DisableArms(int client)
{
	Client(client).NoViewModel = true;
	Randomizer_UpdateArms(client);
}

int ViewModel_Create(int client, const char[] model, const char[] anim = "", const float angOffset[3] = NULL_VECTOR, const float posOffset[3] = NULL_VECTOR)
{
	ViewModel_DisableArms(client);
	ViewModel_Destroy(client);

	int viewmodel = CreateEntityByName("prop_dynamic");
	if(viewmodel == -1)
		return -1;
	
	SetEntPropEnt(viewmodel, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchKeyValue(viewmodel, "model", model);
	DispatchKeyValue(viewmodel, "disablereceiveshadows", "0");
	DispatchKeyValue(viewmodel, "disableshadows", "1");
	
	if(anim[0])
		DispatchKeyValue(viewmodel, "defaultanim", anim);
	
	float pos[3], ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	
	AddVectors(ang, angOffset, ang);
	AddVectors(pos, posOffset, pos);
	
	TeleportEntity(viewmodel, pos, ang, NULL_VECTOR);
	DispatchSpawn(viewmodel);
	
	SetVariantString("!activator");

	AcceptEntityInput(viewmodel, "SetParent", GetEntPropEnt(client, Prop_Send, "m_hViewModel"));

	SDKHook(viewmodel, SDKHook_SetTransmit, ViewModel_SetTransmit);
	
	ViewmodelRef[client] = EntIndexToEntRef(viewmodel);

	return viewmodel;
}

bool ViewModel_Valid(int client)
{
	return IsValidEntity(ViewmodelRef[client]);
}

void ViewModel_SetAnimation(int client, const char[] animation)
{
	if(ViewModel_Valid(client))
	{
		SetVariantString(animation);
		AcceptEntityInput(ViewmodelRef[client], "SetAnimation");
	}
}

void ViewModel_Destroy(int client)
{
	if(ViewModel_Valid(client))
		RemoveEntity(ViewmodelRef[client]);
	
	ViewmodelRef[client] = -1;
}

static Action ViewModel_SetTransmit(int viewmodel, int client)
{
	int owner = GetEntPropEnt(viewmodel, Prop_Send, "m_hOwnerEntity");
	if(owner < 1 || owner > MaxClients || !IsPlayerAlive(owner) || viewmodel != EntRefToEntIndex(ViewmodelRef[owner]))
	{
		//Viewmodel entity no longer valid
		ViewModel_Destroy(owner);
		return Plugin_Handled;
	}
	
	//Allow if spectating owner and in firstperson
	if(client != owner)
	{
		if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == owner && GetEntProp(client, Prop_Send, "m_iObserverMode") == OBS_MODE_IN_EYE)
		    return Plugin_Continue;
		
		return Plugin_Handled;
	}
	
	//Allow if client itself and in firstperson
	if(TF2_IsPlayerInCondition(client, TFCond_Taunting) || GetEntProp(client, Prop_Send, "m_nForceTauntCam"))
		return Plugin_Handled;
	
	return Plugin_Continue;
}