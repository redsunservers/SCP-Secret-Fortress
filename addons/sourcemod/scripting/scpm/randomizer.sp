/*
	github.com/FortyTwoFortyTwo/Randomizer
*/

#pragma semicolon 1
#pragma newdecls required

static const char ArmModels[][] =
{
	"",
	"models/weapons/c_models/c_scout_arms.mdl",
	"models/weapons/c_models/c_sniper_arms.mdl",
	"models/weapons/c_models/c_soldier_arms.mdl",
	"models/weapons/c_models/c_demo_arms.mdl",
	"models/weapons/c_models/c_medic_arms.mdl",
	"models/weapons/c_models/c_heavy_arms.mdl",
	"models/weapons/c_models/c_pyro_arms.mdl",
	"models/weapons/c_models/c_spy_arms.mdl",
	"models/weapons/c_models/c_engineer_arms.mdl",
};

enum
{
	ViewType_Arm,
	ViewType_Weapon,
	
	ViewType_MAX,
}

static int RobotArmIndex;
static int DisguiseArmIndex;
static int ViewModels[MAXPLAYERS+1][ViewType_MAX];
static int ArmModelIndex[sizeof(ArmModels)];

void Randomizer_MapStart()
{
	RobotArmIndex = PrecacheModel("models/weapons/c_models/c_engineer_gunslinger.mdl");
	DisguiseArmIndex = PrecacheModel("models/weapons/v_models/v_pda_spy.mdl");

	for(int i = 1; i < sizeof(ArmModels); i++)
	{
		ArmModelIndex[i] = PrecacheModel(ArmModels[i]);
	}
}

void Randomizer_DeleteFromClient(int client, int type)
{
	if (ViewModels[client][type] && IsValidEntity(ViewModels[client][type]))
		RemoveEntity(ViewModels[client][type]);
	
	ViewModels[client][type] = -1;
}

void Randomizer_ConditionChanged(int client, TFCond cond)
{
	if(cond == TFCond_Disguised && !Client(client).NoViewModel)
		Randomizer_UpdateArms(client);
}

void Randomizer_UpdateArms(int client, int force = -1)
{
	TFClassType current = TF2_GetPlayerClass(client);

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		TFClassType disguise = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
		if(disguise != TFClass_Unknown)
			current = disguise;
	}

	if(current == TFClass_Unknown)
		return;
	
	bool sameClass;
	
	int weapon = force == -1 ? GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") : force;
	int viewmodel = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
	if(viewmodel != -1)
	{
		TFClassType class = TF2_GetPlayerClass(client);
		
		if(weapon != -1)
			class = TF2_GetWeaponClass(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), current);

		sameClass = class == current;
		
		int effects = GetEntProp(viewmodel, Prop_Send, "m_fEffects");
		if(sameClass)
		{
			SetEntProp(viewmodel, Prop_Send, "m_fEffects", effects & ~EF_NODRAW);
		}
		else
		{
			SetEntProp(viewmodel, Prop_Send, "m_fEffects", effects | EF_NODRAW);
		}
		
		char classname[36];
		if(weapon != -1)
			GetEntityClassname(weapon, classname, sizeof(classname));
		
		int model;
		if(!StrContains(classname, "tf_weapon_pda_spy"))
		{
			model = DisguiseArmIndex;
		}
		else if(Attrib_FindOnPlayer(client, "wrench_builds_minisentry"))
		{
			model = RobotArmIndex;
		}
		else
		{
			model = ArmModelIndex[class];
		}
		
		SetEntProp(viewmodel, Prop_Send, "m_nModelIndex", model);
	}
	
	int arms = GetViewModel(client, ViewType_Arm, ArmModelIndex[current]);
	if(arms == -1)
		return;
	
	int effects = GetEntProp(arms, Prop_Send, "m_fEffects");
	if(sameClass)
	{
		SetEntProp(arms, Prop_Send, "m_fEffects", effects | EF_NODRAW);
	}
	else
	{
		SetEntProp(arms, Prop_Send, "m_fEffects", effects & ~EF_NODRAW);
	}
	
	if(sameClass)
	{
		Randomizer_DeleteFromClient(client, ViewType_Weapon);
	}
	else if(weapon != -1)
	{
		int wearable = GetViewModel(client, ViewType_Weapon, GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex"), weapon);
		if(wearable != -1)
			SetEntPropEnt(wearable, Prop_Send, "m_hWeaponAssociatedWith", weapon);
		
		SetEntPropEnt(arms, Prop_Send, "m_hWeaponAssociatedWith", weapon);
	}
	
	int i;
	while(TF2_GetItem(client, weapon, i))
	{
		SetEntProp(weapon, Prop_Send, "m_nCustomViewmodelModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));
	}
}

static int CreateWearable(int client, int modelIndex, int weapon = -1)
{
	int wearable = CreateEntityByName("tf_wearable_vm");
	
	if(weapon != -1)
	{
		static Address offset;
		if(!offset)
			offset = view_as<Address>(FindSendPropInfo("CTFWearable", "m_Item"));
		
		SDKCall_EconItemCopy(GetEntityAddress(wearable) + offset, GetEntityAddress(weapon) + offset);
	}
	
	float pos[3], ang[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(client, Prop_Send, "m_angRotation", ang);
	TeleportEntity(wearable, pos, ang, NULL_VECTOR);
	
	SetEntProp(wearable, Prop_Send, "m_bValidatedAttachedEntity", true);
	SetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(wearable, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(wearable, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
	
	DispatchSpawn(wearable);
	
	SetEntProp(wearable, Prop_Send, "m_nModelIndex", modelIndex);
	
	SetVariantString("!activator");
	AcceptEntityInput(wearable, "SetParent", GetEntPropEnt(client, Prop_Send, "m_hViewModel"));
	
	return EntIndexToEntRef(wearable);
}

static int GetViewModel(int client, int type, int modelIndex, int weapon = -1)
{
	if(!ViewModels[client][type] || !IsValidEntity(ViewModels[client][type]))
		ViewModels[client][type] = -1;
	
	if(ViewModels[client][type] != -1 && GetEntProp(ViewModels[client][type], Prop_Send, "m_nModelIndex") != modelIndex)
	{
		RemoveEntity(ViewModels[client][type]);
		ViewModels[client][type] = -1;
	}
	
	if(ViewModels[client][type] == -1)
		ViewModels[client][type] = CreateWearable(client, modelIndex, weapon);
	
	return ViewModels[client][type];
}