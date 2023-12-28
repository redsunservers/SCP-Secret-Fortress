#pragma semicolon 1
#pragma newdecls required

static const char HandModels[][] =
{
	"models/empty.mdl",
	"models/weapons/c_models/c_scout_arms.mdl",
	"models/weapons/c_models/c_sniper_arms.mdl",
	"models/weapons/c_models/c_soldier_arms.mdl",
	"models/weapons/c_models/c_demo_arms.mdl",
	"models/weapons/c_models/c_medic_arms.mdl",
	"models/weapons/c_models/c_heavy_arms.mdl",
	"models/weapons/c_models/c_pyro_arms.mdl",
	"models/weapons/c_models/c_spy_arms.mdl",
	"models/weapons/c_models/c_engineer_arms.mdl"
};

static int HandIndex[sizeof(HandModels)];
static int HandRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
static int WeaponRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

void ViewEffects_MapStart()
{
	for(int i; i < sizeof(HandIndex); i++)
	{
		HandIndex[i] = PrecacheModel(HandModels[i], true);
	}
}

void ViewEffects_WeaponSwitch(int client)
{
	DeleteWeapon(client);

	int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(viewmodel != -1 && active != -1)
	{
		ClassEnum class;
		if(!Classes_GetByIndex(Client(client).Class, class))
			class.HandModel = HandIndex[TF2_GetPlayerClass(client)];

		WeaponEnum weapon;
		Items_GetWeaponByIndex(GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex"), weapon);

		Classes_SetViewmodel(client, active, weapon);

		SetEntProp(viewmodel, Prop_Send, "m_fEffects", EF_NODRAW);	// Hide normal viewmodel
		Client(client).WeaponClass = weapon.Class;

		if(weapon.HideModel)	// No viewmodel
		{
			DeleteHands(client);
		}
		else if(weapon.Viewmodel)	// Custom viewmodel
		{
			DeleteHands(client);

			int entity = CreateEntityByName("prop_dynamic");
			if(entity != -1)
			{
				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				
				char buffer[PLATFORM_MAX_PATH];
				ModelIndexToString(weapon.Worldmodel, buffer, sizeof(buffer));
				DispatchKeyValue(entity, "model", buffer);
				DispatchKeyValue(entity, "disablereceiveshadows", "0");
				DispatchKeyValue(entity, "disableshadows", "1");
				
				float pos[3], ang[3];
				GetClientAbsOrigin(client, pos);
				GetClientAbsAngles(client, ang);
				
				TeleportEntity(entity, pos, ang, NULL_VECTOR);
				DispatchSpawn(entity);
				
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", viewmodel);

				SetEntityMaterialData(entity, weapon.Skin);
				SDKHook(entity, SDKHook_SetTransmit, SetTransmit);

				WeaponRef[client] = EntIndexToEntRef(entity);

				if(class.HandModel)
				{
					int hands = CreateEntityByName("prop_dynamic");
					if(IsValidEntity(hands))
					{
						ModelIndexToString(class.HandModel, buffer, sizeof(buffer));
						DispatchKeyValue(hands, "model", buffer);
						DispatchKeyValue(hands, "solid", "0");
						DispatchKeyValue(hands, "effects", "129");
						DispatchKeyValue(hands, "disableshadows", "1");

						int skin = GetClientTeam(client) - 2;
						if(skin < 0)
							skin = 0;
						
						SetEntProp(hands, Prop_Send, "m_nSkin", skin);

						TeleportEntity(hands, pos, ang, NULL_VECTOR);

						DispatchSpawn(hands);
						ActivateEntity(hands);
						
						SetVariantString("!activator");
						AcceptEntityInput(hands, "SetParent", entity, entity);

						SetVariantString("vm");
						AcceptEntityInput(hands, "SetParentAttachment", entity, entity);
					}
				}

				ViewEffects_SetDefaultAnimation(client, "idle");
				ViewEffects_SetAnimation(client, "draw");
			}
		}
		else	// Standard viewmodel
		{
			if(weapon.Class != TFClass_Unknown)	// Set animations for class
				SetEntProp(viewmodel, Prop_Send, "m_nModelIndex", HandIndex[weapon.Class]);

			if(class.HandModel && EntRefToEntIndex(HandRef[client]) == -1)	// Apply hand model
			{
				int entity = CreateWearableVM(client, class.HandModel, 0);
				if(entity != -1)
					HandRef[client] = EntIndexToEntRef(entity);
			}

			// Apply weapon model
			int model = weapon.Worldmodel ? weapon.Worldmodel : GetEntProp(active, Prop_Send, "m_iWorldModelIndex");
			int entity = CreateWearableVM(client, model, weapon.Skin);
			if(entity != -1)
				WeaponRef[client] = EntIndexToEntRef(entity);
		}
	}
	else
	{
		DeleteHands(client);
		Client(client).WeaponClass = TFClass_Unknown;
	}
}

void ViewEffects_SetAnimation(int client, const char[] animation)
{
	if(WeaponRef[client] != INVALID_ENT_REFERENCE)
	{
		SetVariantString(animation);
		AcceptEntityInput(WeaponRef[client], "SetAnimation");
	}
}

void ViewEffects_SetDefaultAnimation(int client, const char[] animation)
{
	if(WeaponRef[client] != INVALID_ENT_REFERENCE)
	{
		SetVariantString(animation);
		AcceptEntityInput(WeaponRef[client], "SetDefaultAnimation");
	}
}

static int CreateWearableVM(int client, int model, int skin)
{
	int entity = CreateEntityByName("tf_wearable_vm");
	if(entity != -1)
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndex", model);
		SetEntProp(entity, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(entity, Prop_Send, "m_nSkin", skin);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		DispatchSpawn(entity);
		SetVariantString("!activator");
		ActivateEntity(entity);
		TF2Util_EquipPlayerWearable(client, entity);
	}
	
	return entity;
}

static void DeleteWeapon(int client)
{
	if(WeaponRef[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(WeaponRef[client]);
		if(entity != -1)
		{
			if(TF2Util_IsEntityWearable(entity))
			{
				TF2_RemoveWearable(client, entity);
			}
			else
			{
				RemoveEntity(entity);
			}
		}

		WeaponRef[client] = INVALID_ENT_REFERENCE;
	}
}

static void DeleteHands(int client)
{
	if(HandRef[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(HandRef[client]);
		if(entity != -1)
		{
			if(TF2Util_IsEntityWearable(entity))
			{
				TF2_RemoveWearable(client, entity);
			}
			else
			{
				RemoveEntity(entity);
			}
		}

		HandRef[client] = INVALID_ENT_REFERENCE;
	}
}

static Action SetTransmit(int entity, int target)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner < 1 || owner >= MaxClients || !IsPlayerAlive(owner) || entity != EntRefToEntIndex(WeaponRef[owner]))
	{
		// Viewmodel entity no longer valid
		RemoveEntity(entity);
		return Plugin_Handled;
	}
	
	// Allow if spectating owner and in firstperson
	if(target != owner)
	{
		if(GetEntPropEnt(target, Prop_Send, "m_hObserverTarget") == owner && GetEntProp(target, Prop_Send, "m_iObserverMode") == OBS_MODE_IN_EYE)
		    return Plugin_Continue;
		
		return Plugin_Handled;
	}
	
	// Allow if client itself and in firstperson
	if(TF2_IsPlayerInCondition(target, TFCond_Taunting) || GetEntProp(target, Prop_Send, "m_nForceTauntCam"))
		return Plugin_Handled;
	
	return Plugin_Continue;
}