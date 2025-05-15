#pragma semicolon 1
#pragma newdecls required

#define PrecacheSoundArray(%1)	PrecacheSoundList(%1, sizeof(%1))
stock void PrecacheSoundList(const char[][] array, int length)
{
	for(int i; i < length; i++)
	{
		PrecacheSound(array[i]);
	}
}

#define AddFilesToDownloadsTable(%1)	AddDownloadList(%1, sizeof(%1))
stock void AddDownloadList(const char[][] array, int length)
{
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("downloadables");

	bool save = LockStringTables(false);
	
	for(int i; i < length; i++)
	{
		AddToStringTable(table, array[i]);
	}

	LockStringTables(save);
}

float FAbs(float value)
{
	return value < 0.0 ? -value : value;
}

bool TF2_GetItem(int client, int &weapon, int &pos)
{	
	static int maxWeapons;
	if(!maxWeapons)
		maxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(pos < 0)
		pos = 0;
	
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;
		
		if(weapon != -1)
			return true;
	}
	return false;
}

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

void TF2_RemoveAllItems(int client)
{
	int entity, i;
	while(TF2_GetItem(client, entity, i))
	{
		TF2_RemoveItem(client, entity);
	}
}

int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
{
	if(StrContains(classname, "tf_weapon_"))
	{
		return -1;
	}
	else if(!StrContains(classname, "tf_weapon_scattergun") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_primary") ||
	  !StrContains(classname, "tf_weapon_soda_popper") ||
	  !StrContains(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	  !StrContains(classname, "tf_weapon_particle_cannon") ||
	  !StrContains(classname, "tf_weapon_flamethrower") ||
	  !StrContains(classname, "tf_weapon_grenadelauncher") ||
	  !StrContains(classname, "tf_weapon_cannon") ||
	  !StrContains(classname, "tf_weapon_minigun") ||
	  !StrContains(classname, "tf_weapon_shotgun_primary") ||
	  !StrContains(classname, "tf_weapon_sentry_revenge") ||
	  !StrContains(classname, "tf_weapon_drg_pomson") ||
	  !StrContains(classname, "tf_weapon_shotgun_building_rescue") ||
	  !StrContains(classname, "tf_weapon_syringegun_medic") ||
	  !StrContains(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	  !StrContains(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_secondary") ||
	  !StrContains(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	  !StrContains(classname, "tf_weapon_buff_item") ||
	  !StrContains(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	  !StrContains(classname, "tf_weapon_laser_pointer") ||
	  !StrContains(classname, "tf_weapon_mechanical_arm") ||
	  !StrContains(classname, "tf_weapon_medigun") ||
	  !StrContains(classname, "tf_weapon_smg") ||
	  !StrContains(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_re"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

void ScreenFade(int client, int duration, int time, int flags, int r, int g, int b, int a)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("Fade", client));
	bf.WriteShort(duration);
	bf.WriteShort(time);
	bf.WriteShort(flags);
	bf.WriteByte(r);
	bf.WriteByte(g);
	bf.WriteByte(b);
	bf.WriteByte(a);
	EndMessage();
}

void PrintSayText2(int client, int author, bool chat = true, const char[] message, const char[] param1 = NULL_STRING, const char[] param2 = NULL_STRING, const char[] param3 = NULL_STRING, const char[] param4 = NULL_STRING)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(author);
	bf.WriteByte(chat);
	bf.WriteString(message);
	bf.WriteString(param1);
	bf.WriteString(param2);
	bf.WriteString(param3);
	bf.WriteString(param4);
	EndMessage();
}

int GetClientPointVisible(int client, float distance = 100.0)
{
	float pos[3], vec[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, vec);
	
	Handle trace = TR_TraceRayFilterEx(pos, vec, MASK_ALL, RayType_Infinite, Trace_DontHitEntity, client);
	
	int entity = -1;
	TR_GetEndPosition(vec, trace);

	if(TR_DidHit(trace) && GetVectorDistance(pos, vec, true) < (distance * distance))
		entity = TR_GetEntityIndex(trace);
	
	delete trace;
	return entity;
}

void ModelIndexToString(int index, char[] model, int size)
{
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("modelprecache");
	
	ReadStringTable(table, index, model, size);
}

public bool Trace_OnlyHitWorld(int entity, int mask)
{
	return entity == 0;
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity != data;
}
