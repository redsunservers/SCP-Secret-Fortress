#define ITEMS_MAX	8

static const int ItemLimits[] =
{
	2,	// Weapons
	3,	// Keycards
	3,	// Medical
	1,	// Radio
	3	// SCPs
};

enum
{
	Ammo_Micro = 1,
	Ammo_9mm,
	Ammo_Metal,
	Ammo_Misc1,
	Ammo_Misc2,
	Ammo_7mm,
	Ammo_5mm,
	Ammo_Grenade,
	Ammo_MAX
}

static KeyValues Config;
static int MaxWeapons;

void Items_Setup()
{
	if(Config != INVALID_HANDLE)
		delete Config;

	Config = new KeyValues("Weapons");

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), CFG_WEAPONS);
	Config.ImportFromFile(buffer);
}

int Items_CreateWeapon(int client, int index, bool equip=true, bool clip=false, bool ammo=false, int account=-3)
{
	Config.Rewind();

	static char classname[36];
	IntToString(index, classname, sizeof(classname));
	if(!Config.JumpToKey(classname))
		return -1;

	Handle weapon;
	if(Config.GetNum("strip"))
	{
		weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	}
	else
	{
		weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	}

	if(weapon == INVALID_HANDLE)
		return -1;

	TFClassType class = KvGetClass(kv, "class");
	if(class != TFClass_Unknown)
		TF2_SetPlayerClass(client, class, false, false);

	Config.GetString("classname", classname, sizeof(classname));
	TF2Items_SetClassname(weapon, classname);

	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, 101);
	TF2Items_SetQuality(weapon, 6);

	static char buffer[256];
	Config.GetString("attributes", buffer, sizeof(buffer));

	static char buffers[40][16];
	int count = ExplodeString(buffer, " ; ", buffers, sizeof(buffers), sizeof(buffers));

	if(count % 2)
		count--;

	int i;
	if(count > 0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int a;
		for(; i<count && i<32; i+=2)
		{
			int attrib = StringToInt(buffers[i]);
			if(!attrib)
			{
				LogError("[Config] Bad weapon attribute passed for index %d: %s ; %s", index, buffers[i], buffers[i+1]);
				continue;
			}

			TF2Items_SetAttribute(weapon, a++, attrib, StringToFloat(buffers[i+1]));
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;

	if(entity > MaxClients)
	{
		EquipPlayerWeapon(client, entity);

		while(i < count)
		{
			int attrib = StringToInt(buffers[i]);
			if(attrib)
			{
				TF2Attrib_SetByDefIndex(entity, attrib, StringToFloat(buffers[i+1]));
			}
			else
			{
				LogError("[Config] Bad weapon attribute passed for index %d: %s ; %s", index, buffers[i], buffers[i+1]);
			}
			i += 2;
		}

		if(Config.GetNum("hide"))
		{
			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
			SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 255, 255, 255, 0);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
		}

		if(account == -3)
			account = GetSteamAccountID(client);

		SetEntProp(entity, Prop_Send, "m_iAccountID", account);

		if(clip)
		{
			count = Config.GetNum("clip", -1);
			if(count >= 0)
				SetEntProp(entity, Prop_Data, "m_iClip1", count);
		}

		if(ammo)
		{
			count = Config.GetNum("ammo", -1);

			i = Config.GetNum("bullet");
			if(i)
			{
				SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", i);
				if(count>=0 && i>0)
					SetEntProp(client, Prop_Data, "m_iAmmo", GetEntProp(client, Prop_Data, "m_iAmmo", _, i)+count, _, i);
			}
			else if(count >= 0)
			{
				i = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				if(i != -1)
					SetEntProp(client, Prop_Data, "m_iAmmo", GetEntProp(client, Prop_Data, "m_iAmmo", _, i)+count, _, i);
			}
		}

		Config.GetString("func_spawn", buffer, sizeof(buffer));
		if(buffer[0])
		{
			Function func = GetFunctionByName(INVALID_HANDLE, buffer);
			if(func != INVALID_FUNCTION)
			{
				Call_StartFunction(INVALID_HANDLE, func);
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_Finish();
			}
		}

		if(equip)
			SetActiveWeapon(client, entity);

		Forward_OnWeapon(client, entity);
	}
	return entity;
}

int Items_SwitchItem(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon>MaxClients && IsValidEntity(weapon))
	{
		static char buffer[36];
		if(GetEntityClassname(weapon, buffer, sizeof(buffer)))
		{
			if(!MaxWeapons)
				MaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

			int slot = TF2_GetClassnameSlot(buffer);
			for(int i; i<MaxWeapons; i++)
			{
				if(GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) != weapon)
					continue;

				for(int a=1; a<MaxWeapons; a++)
				{
					if(++i >= MaxWeapons)
						i = 0;

					weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
					if(weapon<=MaxClients || !IsValidEntity(weapon) ||
					  !GetEntityClassname(weapon, buffer, sizeof(buffer)) ||
					   TF2_GetClassnameSlot(buffer) != slot)
						continue;

					SetActiveWeapon(client, weapon);
					break;
				}
				break;
			}
		}
	}
	return weapon;
}

bool Items_CanGiveItem(int client, int type)
{
	if(!MaxWeapons)
		MaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	int all, types;
	for(int i; i<MaxWeapons; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(++all > ITEMS_MAX)
			return false;

		if(type<0 || type>=sizeof(ItemLimits))
			continue;

		static char buffer[16];
		IntToString(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), buffer, sizeof(buffer));

		Config.Rewind();
		if(!Config.JumpToKey(buffer) || Config.GetNum("type", -1)==type)
			continue;

		if(++types >= ItemLimits[type])
			return false;
	}
	return true;
}

bool Items_DropItem(int client, int weapon, const float origin[3], const float angles[3], bool swap=true)
{
	static char buffer[PLATFORM_MAX_PATH];
	GetEntityNetClass(weapon, buffer, sizeof(buffer));
	int offset = FindSendPropInfo(buffer, "m_Item");
	if(offset < 0)
	{
		LogError("Failed to find m_Item on: %s", buffer);
		return false;
	}

	IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), buffer, sizeof(buffer));

	Config.Rewind();
	if(!Config.JumpToKey(buffer))
		return false;

	Config.GetString("func_drop", buffer, sizeof(buffer));
	if(buffer[0])
	{
		Function func = GetFunctionByName(INVALID_HANDLE, buffer);
		if(func != INVALID_FUNCTION)
		{
			Call_StartFunction(INVALID_HANDLE, func);
			Call_PushCell(client);

			bool canDrop;
			Call_Finish(canDrop);
			if(!canDrop)
				return false;
		}
	}

	Config.GetString("model", buffer, sizeof(buffer));
	if(!buffer[0])
	{
		int index = GetEntProp(weapon, Prop_Send, HasEntProp(weapon, Prop_Send, "m_iWorldModelIndex") ? "m_iWorldModelIndex" : "m_nModelIndex");
		if(index < 1)
			return false;

		ModelIndexToString(index, buffer, sizeof(buffer));
	}

	//Dropped weapon doesn't like being spawn high in air, create on ground then teleport back after DispatchSpawn
	TR_TraceRayFilter(origin, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
	if(!TR_DidHit())	//Outside of map
		return false;

	static float spawn[3];
	TR_GetEndPosition(spawn);

	// CTFDroppedWeapon::Create deletes tf_dropped_weapon if there too many in map, pretend entity is marking for deletion so it doesnt actually get deleted
	ArrayList list = new ArrayList();
	int entity = MaxClients+1;
	while((entity=FindEntityByClassname(entity, "tf_dropped_weapon")) > MaxClients)
	{
		int flags = GetEntProp(entity, Prop_Data, "m_iEFlags");
		if(flags & EFL_KILLME)
			continue;

		SetEntProp(entity, Prop_Data, "m_iEFlags", flags|EFL_KILLME);
		list.Push(entity);
	}

	//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
	entity = SDKCall_CreateDroppedWeapon(-1, spawn, angles, buffer, GetEntityAddress(weapon)+view_as<Address>(offset));

	offset = list.Length;
	for(int i; i<offset; i++)
	{
		int ent = list.Get(i);
		int flags = GetEntProp(ent, Prop_Data, "m_iEFlags");
		flags = flags &= ~EFL_KILLME;
		SetEntProp(ent, Prop_Data, "m_iEFlags", flags);
	}

	delete list;
	if(entity == INVALID_ENT_REFERENCE)
		return false;

	DispatchSpawn(entity);

	//Check if weapon is not marked for deletion after spawn, otherwise we may get bad physics model leading to a crash
	if(GetEntProp(entity, Prop_Data, "m_iEFlags") & EFL_KILLME)
	{
		LogError("Unable to create dropped weapon with model '%s'", buffer);
		return false;
	}

	TF2_RemoveItem(client, weapon);

	SDKCall_InitDroppedWeapon(entity, client, weapon, swap, false);

	offset = Config.GetNum("skin", -1);
	if(offset >= 0)
	{
		SetVariantInt(offset);
		AcceptEntityInput(entity, "Skin");
	}

	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	return true;
}

void Items_DropAllItems(int client)
{
	if(!MaxWeapons)
		MaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	static float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	for(int i; i<MaxWeapons; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity>MaxClients && IsValidEntity(entity))
			Items_DropItem(client, entity, pos, ang, false);
	}
}

public bool Items_NoDrop(int client)
{
	return false;
}

public Action Items_DisarmerHit(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsSCP(victim) && !IsFriendly(Client[victim].Class, Client[attacker].Class))
	{
		bool cancel;
		if(!Client[victim].Disarmer)
		{
			int entity = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
			if(entity>MaxClients && IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				static char buffer[16];
				IntToString(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), buffer, sizeof(buffer));

				Config.Rewind();
				if(!Config.JumpToKey(buffer) || Config.GetNum("hide"))
					cancel = true;
			}

			if(!cancel)
			{
				TF2_AddCondition(victim, TFCond_PasstimePenaltyDebuff);
				BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", victim));
				if(bf != null)
				{
					char buffer[64];
					FormatEx(buffer, sizeof(buffer), "%T", "disarmed", attacker);
					bf.WriteString(buffer);
					bf.WriteString("ico_notify_flag_moving_alt");
					bf.WriteByte(view_as<int>(TFTeam_Red));
					EndMessage();
				}

				DropAllWeapons(victim);
				Client[victim].HealthPack = 0;
				TF2_RemoveAllWeapons(victim);
				GiveWeapon(victim, Weapon_None);

				if(Client[victim].Class>=Class_Guard && Client[victim].Class<=Class_MTFE)
					GiveAchievement(Achievement_DisarmMTF, attacker);
			}
		}

		if(!cancel)
		{
			Client[victim].Disarmer = attacker;
			SDKCall_SetSpeed(victim);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Items_LogicerHit(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsSCP(victim))
		return Plugin_Changed;

	damage /= 2.0;
	return false;
}

public void Items_BuilderSpawn(int client, int entity)
{
	for(int i; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", i!=3, _, i);
	}
}