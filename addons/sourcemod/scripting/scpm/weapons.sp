#pragma semicolon 1
#pragma newdecls required

static KeyValues WeaponsKv;

void Weapons_SetupConfig(KeyValues map)
{
	delete WeaponsKv;

	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Weapons"))
			WeaponsKv.Import(map);
	}

	if(!WeaponsKv)
	{
		char buffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "weapons");
		WeaponsKv = new KeyValues("Weapons");
		WeaponsKv.ImportFromFile(buffer);
	}
}

void Weapons_ShowChanges(int client, int entity)
{
	if(!WeaponsKv)
		return;
	
	if(!FindWeaponSection(entity))
		return;
	
	char name[64];

	GetEntityClassname(entity, name, sizeof(name));
	if(!TF2Econ_GetLocalizedItemName(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), name, sizeof(name)))
		return;
	
	char buffer[64];
	SetGlobalTransTarget(client);
	if(WeaponsKv.GetNum("strip"))
	{
		Format(buffer, sizeof(buffer), "%%s3 (%t):", "Weapon Stripped");
		PrintSayText2(client, client, true, buffer, _, _, name);
	}
	else
	{
		PrintSayText2(client, client, true, "%s3:", _, _, name);
	}

	if(WeaponsKv.JumpToKey("attributes"))
	{
		if(WeaponsKv.GotoFirstSubKey(false))
		{
			char desc[64], type[64], value[16];

			do
			{
				WeaponsKv.GetSectionName(name, sizeof(name));
				WeaponsKv.GetString(NULL_STRING, value, sizeof(value));

				int attrib = TF2Econ_TranslateAttributeNameToDefinitionIndex(name);
				PrintThisAttrib(client, attrib, value, type, desc, buffer, name);
			}
			while(WeaponsKv.GotoNextKey());
		}
	}
}

static void PrintThisAttrib(int client, int attrib, char value[16], char buffer1[64], char desc[64], char buffer2[64], char buffer3[64])
{
	// Not a "removed" attribute
	if(value[0] != 'R')
	{
		// Not a hidden attribute
		if(!TF2Econ_GetAttributeDefinitionString(attrib, "hidden", buffer1, sizeof(buffer1)) || !StringToInt(buffer1))
		{
			if(TF2Econ_GetAttributeDefinitionString(attrib, "description_ff2_string", desc, sizeof(desc)))
			{
				if(TF2Econ_GetAttributeDefinitionString(attrib, "description_ff2_file", buffer1, sizeof(buffer1)))
					LoadTranslations(buffer1);
				
				if(TranslationPhraseExists(desc))
				{
					FormatValue(value, buffer2, sizeof(buffer2), "value_is_percentage");
					FormatValue(value, buffer3, sizeof(buffer3), "value_is_inverted_percentage");
					FormatValue(value, buffer1, sizeof(buffer1), "value_is_additive_percentage");
					PrintToChat(client, "%t", desc, buffer2, buffer3, buffer1, value);
				}
			}
			else if(TF2Econ_GetAttributeDefinitionString(attrib, "description_string", desc, sizeof(desc)))
			{
				TF2Econ_GetAttributeDefinitionString(attrib, "description_format", buffer1, sizeof(buffer1));
				FormatValue(value, value, sizeof(value), buffer1);
				PrintSayText2(client, client, true, desc, value);
			}
		}
	}
}

static void FormatValue(const char[] value, char[] buffer, int length, const char[] type)
{
	if(StrEqual(type, "value_is_percentage"))
	{
		float val = StringToFloat(value);
		if(val < 1.0 && val > -1.0)
		{
			Format(buffer, length, "%.0f", -(100.0 - (val * 100.0)));
		}
		else
		{
			Format(buffer, length, "%.0f", val * 100.0 - 100.0);
		}
	}
	else if(StrEqual(type, "value_is_inverted_percentage"))
	{
		float val = StringToFloat(value);
		if(val < 1.0 && val > -1.0)
		{
			Format(buffer, length, "%.0f", (100.0 - (val * 100.0)));
		}
		else
		{
			Format(buffer, length, "%.0f", val * 100.0 - 100.0);
		}
	}
	else if(StrEqual(type, "value_is_additive_percentage"))
	{
		float val = StringToFloat(value);
		Format(buffer, length, "%.0f", val * 100.0);
	}
	else if(StrEqual(type, "value_is_particle_index") || StrEqual(type, "value_is_from_lookup_table"))
	{
		buffer[0] = 0;
	}
	else
	{
		strcopy(buffer, length, value);
	}
}

void Weapons_EntityCreated(int entity, const char[] classname)
{
	if(WeaponsKv && (!StrContains(classname, "tf_wea") || !StrContains(classname, "tf_powerup_bottle")))
		SDKHook(entity, SDKHook_SpawnPost, Weapons_Spawn);
}

static void Weapons_Spawn(int entity)
{
	RequestFrame(Weapons_SpawnFrame, EntIndexToEntRef(entity));
}

static void Weapons_SpawnFrame(int ref)
{
	if(!WeaponsKv)
		return;
	
	int entity = EntRefToEntIndex(ref);
	if(entity == INVALID_ENT_REFERENCE)
		return;
	
	if((HasEntProp(entity, Prop_Send, "m_bDisguiseWearable") && GetEntProp(entity, Prop_Send, "m_bDisguiseWearable")) ||
		(HasEntProp(entity, Prop_Send, "m_bDisguiseWeapon") && GetEntProp(entity, Prop_Send, "m_bDisguiseWeapon")))
		return;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client < 1 || client > MaxClients || Client(client).IsBoss || Client(client).Minion)
		return;
	
	if(!FindWeaponSection(entity))
		return;
	
	if(WeaponsKv.GetNum("strip"))
		SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);
	
	int amount = WeaponsKv.GetNum("clip", -2);
	if(amount != -2)
	{
		if(HasEntProp(entity, Prop_Data, "m_iClip1"))
			SetEntProp(entity, Prop_Data, "m_iClip1", amount);
	}
	
	amount = WeaponsKv.GetNum("ammo", -2);
	if(amount != -2)
	{
		if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
		{
			int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
			if(type >= 0)
				SetEntProp(client, Prop_Data, "m_iAmmo", amount, _, type);
		}
	}
	
	if(WeaponsKv.JumpToKey("attributes"))
	{
		if(WeaponsKv.GotoFirstSubKey(false))
		{
			char name[64];

			do
			{
				WeaponsKv.GetSectionName(name, sizeof(name));
				Attrib_Set(entity, name, WeaponsKv.GetFloat(NULL_STRING));
			}
			while(WeaponsKv.GotoNextKey());
		}
	}
}

static bool FindWeaponSection(int entity)
{
	char buffer1[64];

	WeaponsKv.Rewind();
	if(WeaponsKv.JumpToKey("Indexes"))
	{
		if(WeaponsKv.GotoFirstSubKey())
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			char buffer2[12];

			do
			{
				WeaponsKv.GetSectionName(buffer1, sizeof(buffer1));

				bool found;
				int current;
				do
				{
					int add = SplitString(buffer1[current], " ", buffer2, sizeof(buffer2));
					found = add != -1;
					if(found)
					{
						current += add;
					}
					else
					{
						strcopy(buffer2, sizeof(buffer2), buffer1[current]);
					}
					
					if(StringToInt(buffer2) == index)
						return true;
				}
				while(found);
			}
			while(WeaponsKv.GotoNextKey());

			WeaponsKv.GoBack();
		}

		WeaponsKv.GoBack();
	}
	
	if(WeaponsKv.JumpToKey("Classnames"))
	{
		GetEntityClassname(entity, buffer1, sizeof(buffer1));
		return WeaponsKv.JumpToKey(buffer1);
	}
	
	return false;
}
