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

static int HandIndex[10];
static int HandRef[MAXTF2PLAYERS];
static int WeaponRef[MAXTF2PLAYERS];

void ViewChange_MapStart()
{
	for(int i; i<10; i++)
	{
		HandIndex[i] = PrecacheModel(HandModels[i], true);
	}
}

void ViewChange_Switch(int client)
{
	int entity = EntRefToEntIndex(WeaponRef[client]);
	if(entity>MaxClients && IsValidEntity(entity))
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	if(entity > MaxClients)
	{
		int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!ViewModel_Valid(client) && active>MaxClients && IsValidEntity(active))
		{
			WeaponEnum weapon;
			if(Items_GetWeaponByIndex(GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			{
				SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
				if(!weapon.Hide)
				{
					TFClassType class = weapon.Class;
					if(class == TFClass_Unknown)
						class = Client[client].CurrentClass;

					SetEntProp(entity, Prop_Send, "m_nModelIndex", HandIndex[class]);

					active = weapon.Viewmodel ? weapon.Viewmodel : GetEntProp(active, Prop_Send, "m_iWorldModelIndex");

					entity = CreateEntityByName("tf_wearable_vm");
					if(entity > MaxClients)	// Weapon viewmodel
					{
						SetEntProp(entity, Prop_Send, "m_nModelIndex", active);
						SetEntProp(entity, Prop_Send, "m_fEffects", 129);
						SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
						SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4);
						SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11);
						SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
						SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
						DispatchSpawn(entity);
						SetVariantString("!activator");
						ActivateEntity(entity);
						SDKCall_EquipWearable(client, entity);
						WeaponRef[client] = EntIndexToEntRef(entity);
					}

					Client[client].WeaponClass = weapon.Class;
					ViewChange_UpdateHands(client, Client[client].CurrentClass);
					return; // Active weapon is set -> Modified viewmodel
				}

				// Active weapon is set hidden -> Nothing shown
			}

			// Active weapon isn't on the config -> Show normal viewmodel
		}
		else
		{	// Custom viewmodel or no active weapon -> Nothing shown
			SetEntProp(entity, Prop_Send, "m_fEffects", EF_NODRAW);
		}
	}

	ViewChange_DeleteHands(client);
	Client[client].WeaponClass = TFClass_Unknown;
	WeaponRef[client] = INVALID_ENT_REFERENCE;
}

void ViewChange_DeleteHands(int client)
{
	int entity = EntRefToEntIndex(HandRef[client]);
	if(entity>MaxClients && IsValidEntity(entity))
		TF2_RemoveWearable(client, entity);

	HandRef[client] = INVALID_ENT_REFERENCE;
}

void ViewChange_UpdateHands(int client, TFClassType class)
{
	int entity = EntRefToEntIndex(HandRef[client]);
	if(entity <= MaxClients)
	{
		entity = CreateEntityByName("tf_wearable_vm");
		if(entity > MaxClients)
		{
			SetEntProp(entity, Prop_Send, "m_nModelIndex", HandIndex[class]);
			SetEntProp(entity, Prop_Send, "m_fEffects", 129);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
			SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4);
			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 11);
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			DispatchSpawn(entity);
			SetVariantString("!activator");
			ActivateEntity(entity);
			SDKCall_EquipWearable(client, entity);
			HandRef[client] = EntIndexToEntRef(entity);
		}
	}
}

void ViewChange_SetHandModel(int client, int entity)
{
	DispatchKeyValue(entity, "model", HandModels[Client[client].CurrentClass]);
}