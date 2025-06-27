#tryinclude <tf2utils>

#pragma semicolon 1
#pragma newdecls required

#define TF2U_LIBRARY	"nosoop_tf2utils"

#if defined __nosoop_tf2_utils_included
static bool Loaded;
#endif

void TF2U_PluginLoad()
{
	#if defined __nosoop_tf2_utils_included
	MarkNativeAsOptional("TF2Util_GetPlayerWearableCount");
	MarkNativeAsOptional("TF2Util_GetPlayerWearable");
	MarkNativeAsOptional("TF2Util_EquipPlayerWearable");
	MarkNativeAsOptional("TF2Util_SetPlayerActiveWeapon");
	MarkNativeAsOptional("TF2Util_GetPlayerLoadoutEntity");
	#endif
}

void TF2U_PluginStart()
{
	#if defined __nosoop_tf2_utils_included
	Loaded = LibraryExists(TF2U_LIBRARY);
	#endif
}

public void TF2U_LibraryAdded(const char[] name)
{
	#if defined __nosoop_tf2_utils_included
	if(!Loaded && StrEqual(name, TF2U_LIBRARY))
		Loaded = true;
	#endif
}

public void TF2U_LibraryRemoved(const char[] name)
{
	#if defined __nosoop_tf2_utils_included
	if(Loaded && StrEqual(name, TF2U_LIBRARY))
		Loaded = false;
	#endif
}

stock void TF2U_PrintStatus()
{
	#if defined __nosoop_tf2_utils_included
	PrintToServer("'%s' is %sloaded", TF2U_LIBRARY, Loaded ? "" : "not ");
	#else
	PrintToServer("'%s' not compiled", TF2U_LIBRARY);
	#endif
}

stock bool TF2U_GetWearable(int client, int &entity, int &index)
{
	/*#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		int length = TF2Util_GetPlayerWearableCount(client);
		while(index < length)
		{
			entity = TF2Util_GetPlayerWearable(client, index++);
			if(entity != -1)
				return true;
		}
	}
	else
	#endif*/
	{
		if(index >= -1 && index <= MaxClients)
			index = MaxClients + 1;
		
		if(index > -2)
		{
			while((index = FindEntityByClassname(index, "tf_wear*")) != -1)
			{
				if(GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(index, Prop_Send, "m_bDisguiseWearable"))
				{
					entity = index;
					return true;
				}
			}
			
			index = -(MaxClients + 1);
		}
		
		entity = -index;
		while((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) != -1)
		{
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				index = -entity;
				return true;
			}
		}
	}
	return false;
}

stock void TF2U_EquipPlayerWearable(int client, int entity)
{
	#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		TF2Util_EquipPlayerWearable(client, entity);
	}
	else
	#endif
	{
		SDKCall_EquipWearable(client, entity);
	}
}

stock void TF2U_SetPlayerActiveWeapon(int client, int entity)
{
	#if defined __nosoop_tf2_utils_included
	if(Loaded)
	{
		TF2Util_SetPlayerActiveWeapon(client, entity);
	}
	else
	#endif
	{
		char buffer[36];
		GetEntityClassname(entity, buffer, sizeof(buffer));
		ClientCommand(client, "use %s", buffer);
	}
}

stock int TF2U_GetPlayerLoadoutEntity(int client, int loadoutSlot, bool includeWearableWeapons = true)
{
	#if defined __nosoop_tf2_utils_included
	if(Loaded)
		return TF2Util_GetPlayerLoadoutEntity(client, loadoutSlot, includeWearableWeapons);
	#endif

	int entity = GetPlayerWeaponSlot(client, loadoutSlot);
	if(entity == -1 && includeWearableWeapons)
	{
		switch(loadoutSlot)
		{
			case TFWeaponSlot_Primary:
			{
				int index;
				while((TF2U_GetWearable(client, entity, index)))
				{
					int defindex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					switch(defindex)
					{
						case 405, 608:
							break;
					}
				}
			}
			case TFWeaponSlot_Secondary:
			{
				int index;
				while((TF2U_GetWearable(client, entity, index)))
				{
					int defindex = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					switch(defindex)
					{
						case 133, 444, 131, 406, 1099, 1144, 57, 231, 642:
							break;
					}
				}
			}
		}
	}

	return entity;
}