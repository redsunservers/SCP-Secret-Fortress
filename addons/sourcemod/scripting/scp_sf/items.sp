#define ITEMS_MAX	8

enum
{
	Item_Weapon,
	Item_Keycard,
	Item_Medical,
	Item_Radio,
	Item_SCP
}

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
			Function func = GetFunctionByName(null, buffer);
			if(func != INVALID_FUNCTION)
			{
				Call_StartFunction(null, func);
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

int Items_SwitchItem(int client, int holding)
{
	static char buffer[36];
	if(GetEntityClassname(holding, buffer, sizeof(buffer)))
	{
		if(!MaxWeapons)
			MaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

		int slot = TF2_GetClassnameSlot(buffer);
		for(int i; i<MaxWeapons; i++)
		{
			if(GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) != holding)
				continue;

			for(int a=1; a<MaxWeapons; a++)
			{
				if(++i >= MaxWeapons)
					i = 0;

				int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if(weapon<=MaxClients || !IsValidEntity(weapon) ||
				  !GetEntityClassname(weapon, buffer, sizeof(buffer)) ||
				   TF2_GetClassnameSlot(buffer) != slot)
					continue;

				SetActiveWeapon(client, weapon);
				return weapon;
			}
			break;
		}
	}
	return -1;
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
		Function func = GetFunctionByName(null, buffer);
		if(func != INVALID_FUNCTION)
		{
			Call_StartFunction(null, func);
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

	SDKCall_InitDroppedWeapon(entity, client, weapon, swap, false);

	TF2_RemoveItem(client, weapon);

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

static void SpawnPlayerPickup(int client, const char[] classname)
{
	int entity = CreateEntityByName("item_healthkit_small");
	if(entity > MaxClients)
	{
		static float pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 20.0;
		DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon>=MaxClients && IsValidEntity(weapon))
			RemoveAndSwitch(client, weapon);
	}
}

Action Items_OnDamage(int victim, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action;
	if(IsValidEntity(weapon) && weapon>MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		static char buffer[16];
		IntToString(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), buffer, sizeof(buffer));

		Config.Rewind();
		if(Config.JumpToKey(buffer))
		{
			Config.GetString("func_damage", buffer, sizeof(buffer));
			if(buffer[0])
			{
				Function func = GetFunctionByName(null, buffer);
				if(func != INVALID_FUNCTION)
				{
					Call_StartFunction(null, func);
					Call_PushCell(attacker);
					Call_PushCell(victim);
					Call_PushCellRef(inflictor);
					Call_PushFloatRef(damage);
					Call_PushCellRef(damagetype);
					Call_PushCellRef(weapon);
					Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
					Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
					Call_PushCell(damagecustom);
					Call_Finish(result);
				}
			}
		}
	}
	return action;
}

static void RemoveAndSwitch(int client, int weapon)
{
	Items_SwitchItem(client, weapon);
	TF2_RemoveItem(client, weapon);
}

public bool Items_NoDrop(int client)
{
	return false;
}

public bool Items_PainKillerDrop(int client)
{
	SpawnPlayerPickup(client, "item_healthkit_small");
	return true;
}

public bool Items_HealthKitDrop(int client)
{
	SpawnPlayerPickup(client, "item_healthkit_medium");
	return true;
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

public Action Items_HeadshotHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if((IsSCP(victim) && !Client[victim].Class==Class_0492) ||
	   GetEntProp(victim, Prop_Data, "m_LastHitGroup") != HITGROUP_HEAD)
		return Plugin_Continue;

	damagetype |= DMG_CRIT;
	return Plugin_Changed;
}

public Action Items_LogicerHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	bool changed;
	bool isSCP = IsSCP(victim);
	if(isSCP)
	{
		damage /= 2.0;
		changed = true;
	}

	if((!isSCP || Client[victim].Class==Class_0492) &&
	   GetEntProp(victim, Prop_Data, "m_LastHitGroup") == HITGROUP_HEAD)
	{
		damagetype |= DMG_CRIT;
		changed = true;
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public Action Items_FlashHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	FadeMessage(victim, 36, 768, 0x0012);
	FadeClientVolume(victim, 1.0, 2.0, 2.0, 0.2);
	return Plugin_Continue;
}

public void Items_MicroCreate(int client, int entity)
{
	SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
}

public void Items_BuilderCreate(int client, int entity)
{
	for(int i; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", i!=3, _, i);
	}
}

public bool Items_MicroRunCmd(int client, int weapon, int &buttons)
{
	static float charge[MAXTF2PLAYERS];
	if(!(buttons & IN_ATTACK))
	{
		charge[client] = 0.0;
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 99.0);
		return false;
	}

	buttons &= ~IN_JUMP|IN_SPEED;

	if(charge[client])
	{
		float engineTime = GetEngineTime();
		if(charge[client] < engineTime)
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		}
		else
		{
			PrintKeyHintText(client, "Charge: %d", RoundToCeil((charge[client]-engineTime-6.0)/-0.06));
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", (charge[client]-engineTime)*16.5)

			static float time[MAXTF2PLAYERS];
			if(time[client] < engineTime)
			{
				time[client] = engineTime+0.1;
				int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
				if(type != -1)
				{
					int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, type)-1;
					if(ammo >= 0)
						SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);
				}
			}
		}
	}
	else
	{
		charge[client] = GetEngineTime()+6.0;
	}
	return true;
}

public bool Items_PainKillerRunCmd(int client, int weapon, int &buttons)
{
	if(buttons & IN_ATTACK)
	{
		buttons &= ~IN_ATTACK;

		int userid = GetClientUserId(client);
		ApplyHealEvent(userid, userid, 6);

		SetEntityHealth(client, GetClientHealth(client)+6);
		StartHealingTimer(client, 0.4, 1, 50);
	}
	else if(buttons & IN_ATTACK2)
	{
		buttons &= ~IN_ATTACK2;

		Items_PainKillerDrop(client);
	}
	else
	{
		return false;
	}

	RemoveAndSwitch(client, weapon);
	return true;
}

public bool Items_HealthKitRunCmd(int client, int weapon, int &buttons)
{
	if(!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		return false;

	RemoveAndSwitch(client, weapon);
	buttons &= ~(IN_ATTACK|IN_ATTACK2);
	return Items_HealthKitDrop(client);
}

public bool Items_AdrenalineRunCmd(int client, int weapon, int &buttons)
{
	if(!(buttons & IN_ATTACK))
		return false;

	buttons &= ~IN_ATTACK;
	RemoveAndSwitch(client, weapon);
	StartHealingTimer(client, 0.334, 1, 60, true);
	TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 20.0, client);
	TF2_AddCondition(client, TFCond_CritHype, 20.0, client);
	FadeClientVolume(client, 0.7, 2.5, 17.5, 2.5);
	return true;
}

public bool Items_500RunCmd(int client, int weapon, int &buttons)
{
	if(!(buttons & IN_ATTACK))
		return false;

	buttons &= ~IN_ATTACK;
	RemoveAndSwitch(client, weapon);
	SpawnPickup(client, "item_healthkit_full");
	StartHealingTimer(client, 0.334, 1, 36, true);
	TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 20.0, client);
	TF2_AddCondition(client, TFCond_CritHype, 20.0, client);
	return true;
}

public int Items_KeycardJan(int client, AccessEnum access)
{
	if(access == Access_Main)
		return 1;

	return 0;
}

public int Items_KeycardSci(int client, AccessEnum access)
{
	if(access == Access_Main)
		return 2;

	return 0;
}

public int Items_KeycardZon(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Checkpoint)
		return 1;

	return 0;
}

public int Items_KeycardRes(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 2;

		case Access_Checkpoint:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardGua(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Checkpoint || access==Access_Armory)
		return 1;

	return 0;
}

public int Items_KeycardCad(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 2;

		case Access_Checkpoint, Access_Armory:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardLie(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main, Access_Armory:
			return 2;

		case Access_Exit, Access_Checkpoint:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardCom(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Armory:
			return 3;

		case Access_Main:
			return 2;

		case Access_Exit, Access_Checkpoint, Access_Intercom:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardEng(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 3;

		case Access_Warhead, Access_Checkpoint, Access_Intercom:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardFac(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Main:
			return 3;

		case Access_Exit, Access_Warhead, Access_Checkpoint, Access_Intercom:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardCha(int client, AccessEnum access)
{
	switch(access)
	{
		case Access_Armory:
			return 3;

		case Access_Main:
			return 2;

		case Access_Exit, Access_Checkpoint, Access_Intercom:
			return 1;

		default;
			return 0;
	}
}

public int Items_KeycardAll(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Armory)
		return 3;

	return 1;
}