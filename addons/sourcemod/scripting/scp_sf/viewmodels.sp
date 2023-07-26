#pragma semicolon 1
#pragma newdecls required

// Yes, taken from Super Zombie Fortress.

static int ViewmodelRef[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

int ViewModel_Create(int iClient, const char[] sModel, const float vecAnglesOffset[3] = NULL_VECTOR, float flHeight = 0.0, int Skin = 0, bool ViewChange = true, bool NeedsHands = false)
{
	int iViewModel = CreateEntityByName("prop_dynamic");
	if (iViewModel <= MaxClients)
		return 0;
	
	SetEntPropEnt(iViewModel, Prop_Send, "m_hOwnerEntity", iClient);
	SetEntProp(iViewModel, Prop_Send, "m_nSkin", Skin);
	
	DispatchKeyValue(iViewModel, "model", sModel);
	DispatchKeyValue(iViewModel, "disablereceiveshadows", "0");
	DispatchKeyValue(iViewModel, "disableshadows", "1");
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(iClient, vecOrigin);
	GetClientAbsAngles(iClient, vecAngles);
	
	vecOrigin[2] += flHeight;
	AddVectors(vecAngles, vecAnglesOffset, vecAngles);
	
	TeleportEntity(iViewModel, vecOrigin, vecAngles, NULL_VECTOR);
	DispatchSpawn(iViewModel);
	
	SetVariantString("!activator");

	int iActualViewModel = GetEntPropEnt(iClient, Prop_Send, "m_hViewModel");
	AcceptEntityInput(iViewModel, "SetParent", iActualViewModel);

	// keycard uses this to pick the right skin
	SetEntityMaterialData(iViewModel, Skin);
	
	SDKHook(iViewModel, SDKHook_SetTransmit, ViewModel_SetTransmit);
	
	ViewmodelRef[iClient] = EntIndexToEntRef(iViewModel);

	if (NeedsHands)
	{
		// if the viewmodel gets killed, this will automatically delete itself due to hierarchy
		int iHands = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(iHands))
		{
			ViewChange_SetHandModel(iClient, iHands);
			DispatchKeyValue(iHands, "solid", "0");
			DispatchKeyValue(iHands, "effects", "129");
			DispatchKeyValue(iHands, "disableshadows", "1");

			int skin = GetClientTeam(iClient) - 2;
			if (skin < 0)
				skin = 0;
			SetEntProp(iHands, Prop_Send, "m_nSkin", skin);

			TeleportEntity(iHands, vecOrigin, vecAngles, NULL_VECTOR);

			DispatchSpawn(iHands);
			ActivateEntity(iHands);
			
			SetVariantString("!activator");
			AcceptEntityInput(iHands, "SetParent", iViewModel, iViewModel);	
	
			SetVariantString("vm");
			AcceptEntityInput(iHands, "SetParentAttachment", iViewModel, iViewModel);		
		}
	}

	if (ViewChange)
		ViewChange_Switch(iClient);
	
	return iViewModel;
}

bool ViewModel_Valid(int iClient)
{
	return IsValidEntity(EntRefToEntIndex(ViewmodelRef[iClient]));
}

void ViewModel_SetAnimation(int iClient, const char[] sAnimation)
{
	if (ViewModel_Valid(iClient))
	{
		SetVariantString(sAnimation);
		AcceptEntityInput(ViewmodelRef[iClient], "SetAnimation");
	}
}

void ViewModel_SetDefaultAnimation(int iClient, const char[] sAnimation)
{
	if (ViewModel_Valid(iClient))
	{
		SetVariantString(sAnimation);
		AcceptEntityInput(ViewmodelRef[iClient], "SetDefaultAnimation");
	}
}

void ViewModel_Destroy(int iClient)
{
	if (ViewModel_Valid(iClient))
		RemoveEntity(EntRefToEntIndex(ViewmodelRef[iClient]));
	
	ViewmodelRef[iClient] = INVALID_ENT_REFERENCE;
}

public Action ViewModel_SetTransmit(int iViewModel, int iClient)
{
	int iOwner = GetEntPropEnt(iViewModel, Prop_Send, "m_hOwnerEntity");
	if (!IsValidClient(iOwner) || !IsPlayerAlive(iOwner) || iViewModel != EntRefToEntIndex(ViewmodelRef[iOwner]))
	{
		//Viewmodel entity no longer valid
		ViewModel_Destroy(iOwner);
		return Plugin_Handled;
	}
	
	//Allow if spectating owner and in firstperson
	if (iClient != iOwner)
	{
		if (GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget") == iOwner && GetEntProp(iClient, Prop_Send, "m_iObserverMode") == OBS_MODE_IN_EYE)
		    return Plugin_Continue;
		
		return Plugin_Handled;
	}
	
	//Allow if client itself and in firstperson
	if (TF2_IsPlayerInCondition(iClient, TFCond_Taunting) || GetEntProp(iClient, Prop_Send, "m_nForceTauntCam"))
		return Plugin_Handled;
	
	return Plugin_Continue;
}