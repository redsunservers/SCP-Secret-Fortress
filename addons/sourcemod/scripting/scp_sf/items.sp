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
	Item_Weapon = 0,
	Item_Keycard,
	Item_Medical,
	Item_Radio,
	Item_SCP
}

enum struct WeaponEnum
{
	char Display[16];

	// Weapon Stats
	char Classname[36];
	char Attributes[256];
	int Index;
	bool Strip;

	// SCP-914
	char VeryFine[32];
	char Fine[32];
	char OneToOne[32];
	char Coarse[32];
	char Rough[32];

	TFClassType Class;
	int Ammo;
	int Clip;
	int Bullet;
	int Type;
	bool Hide;
	bool Hidden;

	char Model[PLATFORM_MAX_PATH];
	int Viewmodel;
	int Skin;

	Function OnButton;	// Action(int client, int weapon, int &buttons, int &holding)
	Function OnCard;		// int(int client, AccessEnum access)
	Function OnCreate;	// void(int client, int weapon)
	Function OnDamage;	// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnDrop;		// bool(int client, int weapon, bool swap)
	Function OnRadio;		// int(int client, int weapon)
}

static ArrayList Weapons;

void Items_Setup(KeyValues main, KeyValues map)
{
	if(Weapons != INVALID_HANDLE)
		delete Weapons;

	Weapons = new ArrayList(sizeof(WeaponEnum));

	main.Rewind();
	KeyValues kv = main;
	if(map)	// Check if the map has it's own gamemode config
	{
		map.Rewind();
		if(map.JumpToKey("Weapons"))
			kv = map;
	}

	char buffer[16];
	WeaponEnum weapon;
	kv.GotoFirstSubKey();
	do
	{
		kv.GetSectionName(buffer, sizeof(buffer));
		weapon.Index = StringToInt(buffer);

		Format(weapon.Display, sizeof(weapon.Display), "weapon_%d", weapon.Index);
		if(!TranslationPhraseExists(weapon.Display))
			strcopy(weapon.Display, sizeof(weapon.Display), "weapon_0");

		weapon.Ammo = kv.GetNum("ammo", -1);
		weapon.Clip = kv.GetNum("clip", -1);
		weapon.Bullet = kv.GetNum("bullet");
		weapon.Type = kv.GetNum("type", -1);
		weapon.Skin = kv.GetNum("skin", -1);

		weapon.Strip = view_as<bool>(kv.GetNum("strip"));
		weapon.Hide = view_as<bool>(kv.GetNum("hide"));
		weapon.Hidden = view_as<bool>(kv.GetNum("hidden"));

		weapon.Class = KvGetClass(kv, "class");

		weapon.OnButton = KvGetFunction(kv, "func_button");
		weapon.OnCard = KvGetFunction(kv, "func_card");
		weapon.OnCreate = KvGetFunction(kv, "func_create");
		weapon.OnDamage = KvGetFunction(kv, "func_damage");
		weapon.OnDrop = KvGetFunction(kv, "func_drop");
		weapon.OnRadio = KvGetFunction(kv, "func_radio");

		kv.GetString("classname", weapon.Classname, sizeof(weapon.Classname));
		kv.GetString("attributes", weapon.Attributes, sizeof(weapon.Attributes));

		kv.GetString("viewmodel", weapon.Model, sizeof(weapon.Model));
		weapon.Viewmodel = weapon.Model[0] ? PrecacheModel(weapon.Model, true) : 0;

		kv.GetString("model", weapon.Model, sizeof(weapon.Model));
		if(weapon.Model[0])
			PrecacheModel(weapon.Model, true);

		kv.GetString("914++", weapon.VeryFine, sizeof(weapon.VeryFine));
		kv.GetString("914+", weapon.Fine, sizeof(weapon.Fine));
		kv.GetString("914", weapon.OneToOne, sizeof(weapon.OneToOne));
		kv.GetString("914-", weapon.Coarse, sizeof(weapon.Coarse));
		kv.GetString("914--", weapon.Rough, sizeof(weapon.Rough));

		Weapons.PushArray(weapon);
	} while(kv.GotoNextKey());
}

bool Items_GetWeaponByIndex(int index, WeaponEnum weapon)
{
	int length = Weapons.Length;
	for(int i; i<length; i++)
	{
		Weapons.GetArray(i, weapon);
		if(weapon.Index == index)
			return true;
	}
	return false;
}

int Items_Iterator(int client, int &index, bool all=false)
{
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(; index<max; index++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", index);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(!all && (!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.Hidden))
			continue;

		index++;
		return entity;
	}
	return -1;
}

ArrayList Items_ArrayList(int client, int slot, bool all=false)
{
	ArrayList list = new ArrayList();
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		static char buffer[36];
		if(!GetEntityClassname(entity, buffer, sizeof(buffer)) || TF2_GetClassnameSlot(buffer)!=slot)
			continue;

		if(!all && (!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.Hidden))
			continue;

		list.Push(entity);
	}

	list.Sort(Sort_Ascending, Sort_Integer);
	return list;
}

int Items_CreateWeapon(int client, int index, bool equip=true, bool clip=false, bool ammo=false, int ground=-1)
{
	int entity = -1;
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		static char buffers[40][16];
		int count = ExplodeString(weapon.Attributes, " ; ", buffers, sizeof(buffers), sizeof(buffers));

		if(count % 2)
			count--;

		int i;
		bool wearable = view_as<bool>(StrContains(weapon.Classname, "tf_weap", false));
		if(wearable)
		{
			entity = CreateEntityByName(weapon.Classname);
			if(IsValidEntity(entity))
			{
				SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
				SetEntProp(entity, Prop_Send, "m_bInitialized", true);
				SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
				SetEntProp(entity, Prop_Send, "m_iEntityLevel", 101);

				DispatchSpawn(entity);

				SDKCall_EquipWearable(client, entity);
			}
			else
			{
				LogError("[Config] Invalid classname '%s' for index '%d'", weapon.Classname, index);
			}
		}
		else
		{
			Handle item;
			if(weapon.Strip)
			{
				item = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
			}
			else
			{
				item = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
			}

			if(item)
			{
				TFClassType class = weapon.Class;
				if(class == TFClass_Unknown)
					class = Client[client].CurrentClass;

				if(class != TFClass_Unknown)
					TF2_SetPlayerClass(client, class, false, false);

				TF2Items_SetClassname(item, weapon.Classname);

				TF2Items_SetItemIndex(item, weapon.Index);
				TF2Items_SetLevel(item, 101);
				TF2Items_SetQuality(item, 6);

				if(count > 0)
				{
					TF2Items_SetNumAttributes(item, count/2);
					int a;
					for(; i<count && i<32; i+=2)
					{
						int attrib = StringToInt(buffers[i]);
						if(!attrib)
						{
							LogError("[Config] Bad weapon attribute passed for index %d: %s ; %s", index, buffers[i], buffers[i+1]);
							continue;
						}

						TF2Items_SetAttribute(item, a++, attrib, StringToFloat(buffers[i+1]));
					}
				}
				else
				{
					TF2Items_SetNumAttributes(item, 0);
				}

				entity = TF2Items_GiveNamedItem(client, item);
				delete item;
			}
		}

		if(entity > MaxClients)
		{
			if(!wearable)
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

			if(weapon.Hide)
			{
				SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);

				if(!wearable)
				{
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
					SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
					SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", FAR_FUTURE);
				}
			}
			else
			{
				SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
			}

			if(!wearable)
			{
				if(ground > MaxClients)
				{
					i = GetEntProp(entity, Prop_Send, "m_iAccountID");
				}
				else
				{
					i = GetSteamAccountID(client);
				}
				SetEntProp(entity, Prop_Send, "m_iAccountID", i);

				if(weapon.Bullet>=0 && weapon.Bullet<Ammo_MAX)
				{
					SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", weapon.Bullet);
				}
				else
				{
					weapon.Bullet = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				}

				if(ground > MaxClients)
				{
					// Save our current ammo
					int ammos[Ammo_MAX];
					for(i=1; i<Ammo_MAX; i++)
					{
						ammos[i] = GetAmmo(client, i);
						SetAmmo(client, 0, i);
					}

					// Get the new weapon's ammo
					SDKCall_InitPickup(ground, client, entity);

					// See where the ammo was sent to, add to our current ammo count
					for(i=0; i<Ammo_MAX; i++)
					{
						count = GetEntProp(client, Prop_Data, "m_iAmmo", _, i);
						if(!count)
							continue;

						if(count < 0)	// Guess we give a new set of ammo
							count = weapon.Ammo;

						ammos[weapon.Bullet] += count;

						count = Classes_GetMaxAmmo(client, weapon.Bullet);
						if(ammos[weapon.Bullet] > count)
							ammos[weapon.Bullet] = count;

						break;
					}

					// Set our ammo back
					for(i=0; i<Ammo_MAX; i++)
					{
						if(ammos[i])
							SetAmmo(client, ammos[i], i);
					}
				}
				else
				{
					if(clip && weapon.Clip>=0)
						SetEntProp(entity, Prop_Data, "m_iClip1", weapon.Clip);

					if(ammo && weapon.Ammo>0 && weapon.Bullet>0)
					{
						count = weapon.Ammo+GetAmmo(client, weapon.Bullet);

						i = Classes_GetMaxAmmo(client, weapon.Bullet);
						if(count > i)
							count = i;

						SetAmmo(client, count, weapon.Bullet);
					}
				}
			}

			if(weapon.OnCreate != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnCreate);
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_Finish();
			}

			if(!wearable && equip)
				SetActiveWeapon(client, entity);

			Forward_OnWeapon(client, entity);
		}
	}
	return entity;
}

void Items_SwapWeapons(int client, int wep1, int wep2)
{
	int slot1 = -1;
	int slot2 = -1;
	int max = GetMaxWeapons(client);
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity == wep1)
		{
			slot1 = i;
			if(slot2 == -1)
				continue;
		}
		else if(entity == wep2)
		{
			slot2 = i;
			if(slot1 == -1)
				continue;
		}
		else
		{
			continue;
		}

		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", wep1, slot2);
		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", wep2, slot1);
		break;
	}
}

void Items_SwitchItem(int client, int holding)
{
	int slot = 2;
	static char buffer[36];
	if(holding>MaxClients && GetEntityClassname(holding, buffer, sizeof(buffer)))
	{
		slot = TF2_GetClassnameSlot(buffer);
		ArrayList list = Items_ArrayList(client, slot);

		int length = list.Length;
		if(length > 1)
		{
			for(int i; i<length; i++)
			{
				if(list.Get(i) != holding)
					continue;

				for(int a=1; a<length; a++)
				{
					i++;
					if(i >= length)
						i = 0;

					int entity = list.Get(i);
					Items_SwapWeapons(client, entity, holding);
					SetActiveWeapon(client, entity);
					break;
				}
				break;
			}
		}
		delete list;
	}
	else
	{
		FakeClientCommand(client, "slot%d", slot+1);
	}
}

bool Items_CanGiveItem(int client, int type, bool &full=false)
{
	int i, entity, all, types;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i)) != -1)
	{
		if(++all > ITEMS_MAX)
		{
			full = true;
			return false;
		}

		if(type<0 || type>=sizeof(ItemLimits))
			continue;

		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			continue;

		if(weapon.Type != type)
			continue;

		if(++types >= ItemLimits[type])
		{
			full = false;
			return false;
		}
	}
	return true;
}

bool Items_DropItem(int client, int helditem, const float origin[3], const float angles[3], bool swap=true)
{
	static char buffer[PLATFORM_MAX_PATH];
	GetEntityNetClass(helditem, buffer, sizeof(buffer));
	int offset = FindSendPropInfo(buffer, "m_Item");
	if(offset < 0)
	{
		LogError("Failed to find m_Item on: %s", buffer);
		return false;
	}

	WeaponEnum weapon;
	if(!Items_GetWeaponByIndex(GetEntProp(helditem, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		return false;

	if(weapon.OnDrop != INVALID_FUNCTION)
	{
		Call_StartFunction(null, weapon.OnDrop);
		Call_PushCell(client);
		Call_PushCell(helditem);
		Call_PushCellRef(swap);

		bool canDrop;
		Call_Finish(canDrop);
		if(!canDrop)
			return false;
	}

	if(!weapon.Model[0])
	{
		int index = GetEntProp(helditem, Prop_Send, HasEntProp(helditem, Prop_Send, "m_iWorldModelIndex") ? "m_iWorldModelIndex" : "m_nModelIndex");
		if(index < 1)
			return false;

		ModelIndexToString(index, weapon.Model, sizeof(weapon.Model));
	}

	//Dropped weapon doesn't like being spawn high in air, create on ground then teleport back after DispatchSpawn
	TR_TraceRayFilter(origin, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
	if(!TR_DidHit())	//Outside of map
		return false;

	static float spawn[3];
	TR_GetEndPosition(spawn);

	// If were swapping, don't drop any ammo with this weapon
	int ammo;
	int type = -1;
	if(swap)
	{
		type = GetEntProp(helditem, Prop_Send, "m_iPrimaryAmmoType");
		if(type != -1)
		{
			ammo = GetAmmo(client, type);
			int clip = GetEntProp(helditem, Prop_Data, "m_iClip1");
			int max = Classes_GetMaxAmmo(client, type);

			if(ammo > max)
			{
				ammo = max;
			}
			else
			{
				while(clip>0 && ammo<max)
				{
					clip--;
					ammo++;
				}
			}

			SetEntProp(helditem, Prop_Data, "m_iClip1", clip);
			SetEntProp(client, Prop_Data, "m_iAmmo", 0, _, type);
		}
	}

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
	entity = SDKCall_CreateDroppedWeapon(-1, spawn, angles, weapon.Model, GetEntityAddress(helditem)+view_as<Address>(offset));

	offset = list.Length;
	for(int i; i<offset; i++)
	{
		int ent = list.Get(i);
		int flags = GetEntProp(ent, Prop_Data, "m_iEFlags");
		flags = flags &= ~EFL_KILLME;
		SetEntProp(ent, Prop_Data, "m_iEFlags", flags);
	}

	delete list;

	bool result;
	if(entity != INVALID_ENT_REFERENCE)
	{
		DispatchSpawn(entity);

		//Check if weapon is not marked for deletion after spawn, otherwise we may get bad physics model leading to a crash
		if(GetEntProp(entity, Prop_Data, "m_iEFlags") & EFL_KILLME)
		{
			LogError("Unable to create dropped weapon with model '%s'", weapon.Model);
		}
		else
		{
			SDKCall_InitDroppedWeapon(entity, client, helditem, swap, false);

			if(swap)
				Items_SwitchItem(client, helditem);

			TF2_RemoveItem(client, helditem);

			if(weapon.Skin >= 0)
			{
				SetVariantInt(weapon.Skin);
				AcceptEntityInput(entity, "Skin");
			}

			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
			result = true;
		}
	}

	if(type != -1)
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);

	return result;
}

void Items_DropAllItems(int client)
{
	static float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);

	int i, entity;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		Items_DropItem(client, entity, pos, ang, false);
	}
}

bool Items_Pickup(int client, int index, int entity=-1)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		bool full;
		if(Items_CanGiveItem(client, weapon.Type, full))
		{
			bool newWep = entity==-1;
			Items_CreateWeapon(client, index, true, newWep, newWep, entity);
			ClientCommand(client, "playgamesound AmmoPack.Touch");
			return true;
		}

		ClientCommand(client, "playgamesound items/medshotno1.wav");

		BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
		if(bf)
		{
			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "%T", full ? "inv_full" : "type_full", client);
			bf.WriteString(buffer);
			bf.WriteString("ico_notify_highfive");
			bf.WriteByte(0);
			EndMessage();
		}
	}
	return false;
}

int Items_OnKeycard(int client, any access)
{
	int value;
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity>MaxClients && IsValidEntity(entity))
	{
		WeaponEnum weapon;
		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		{
			if(weapon.OnCard != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnCard);
				Call_PushCell(client);
				Call_PushCell(access);
				Call_Finish(value);
			}
		}
	}
	return value;
}

Action Items_OnDamage(int victim, int attacker, int &inflictor, float &damage, int &damagetype, int &entity, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action action;
	if(IsValidEntity(entity) && entity>MaxClients && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
	{
		WeaponEnum weapon;
		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		{
			if(weapon.OnDamage != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnDamage);
				Call_PushCell(attacker);
				Call_PushCell(victim);
				Call_PushCellRef(inflictor);
				Call_PushFloatRef(damage);
				Call_PushCellRef(damagetype);
				Call_PushCellRef(entity);
				Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
				Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
				Call_PushCell(damagecustom);
				Call_Finish(action);
			}
		}
	}
	return action;
}

bool Items_OnRunCmd(int client, int &buttons, int &holding)
{
	bool changed;
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity>MaxClients && IsValidEntity(entity))
	{
		WeaponEnum weapon;
		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
		{
			if(weapon.OnButton != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnButton);
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_PushCellRef(buttons);
				Call_PushCellRef(holding);
				Call_Finish(changed);
			}
		}
	}
	return changed;
}

bool Items_ShowItemDesc(int client, int entity)
{
	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "info_%d", GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
	if(!TranslationPhraseExists(buffer))
		return false;

	PrintKeyHintText(client, "%t", buffer);
	return true;
}

float Items_Radio(int client)
{
	float distance = 1.0;
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			continue;

		if(weapon.OnRadio != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnRadio);
			Call_PushCell(client);
			Call_PushCell(entity);
			Call_PushFloatRef(distance);

			bool finished;
			Call_Finish(finished);
			if(finished)
				break;
		}
	}
	return distance;
}

int Items_GetTranName(int index, char[] buffer, int length)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
		return strcopy(buffer, length, weapon.Display);

	return strcopy(buffer, length, "weapon_0");
}

void RemoveAndSwitchItem(int client, int weapon)
{
	Items_SwitchItem(client, weapon);
	TF2_RemoveItem(client, weapon);
}

static void SpawnPlayerPickup(int client, const char[] classname)
{
	int entity = CreateEntityByName(classname);
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
	}
}

static int GetMaxWeapons(int client)
{
	static int max;
	if(!max)
		max = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	return max;
}

public bool Items_NoDrop(int client, int weapon, bool &swap)
{
	return false;
}

public bool Items_DeleteDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	TF2_RemoveItem(client, weapon);
	return false;
}

public bool Items_PainKillerDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	TF2_RemoveItem(client, weapon);
	SpawnPlayerPickup(client, "item_healthkit_small");
	return false;
}

public bool Items_HealthKitDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	TF2_RemoveItem(client, weapon);
	SpawnPlayerPickup(client, "item_healthkit_medium");
	return false;
}

public bool Items_RadioDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	swap = false;
	return true;
}

public Action Items_DisarmerHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapo, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsSCP(victim) && !IsFriendly(Client[victim].Class, Client[client].Class))
	{
		bool cancel;
		if(!Client[victim].Disarmer)
		{
			int entity = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
			if(entity>MaxClients && IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				WeaponEnum weapon;
				if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || !weapon.Hide)
					cancel = true;
			}

			if(!cancel)
			{
				TF2_AddCondition(victim, TFCond_PasstimePenaltyDebuff);
				BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", victim));
				if(bf)
				{
					char buffer[64];
					FormatEx(buffer, sizeof(buffer), "%T", "disarmed", client);
					bf.WriteString(buffer);
					bf.WriteString("ico_notify_flag_moving_alt");
					bf.WriteByte(view_as<int>(TFTeam_Red));
					EndMessage();
				}

				Items_DropAllItems(victim);
				for(int i; i<Ammo_MAX; i++)
				{
					SetEntProp(victim, Prop_Data, "m_iAmmo", 0, _, i);
				}
				FakeClientCommand(victim, "use tf_weapon_fists");

				ClassEnum class;
				if(Classes_GetByIndex(Client[victim].Class, class) && class.Group==2 && !class.Vip)
					GiveAchievement(Achievement_DisarmMTF, client);
			}
		}

		if(!cancel)
		{
			Client[victim].Disarmer = client;
			SDKCall_SetSpeed(victim);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Items_HeadshotHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if((IsSCP(victim) && Client[victim].Class!=Classes_GetByName("scp0492")) ||
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

	if((!isSCP || Client[victim].Class==Classes_GetByName("scp0492")) &&
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
	SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", FAR_FUTURE);
}

public void Items_BuilderCreate(int client, int entity)
{
	for(int i; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", i!=3, _, i);
	}
}

public bool Items_MicroButton(int client, int weapon, int &buttons, int &holding)
{
	int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int ammo = GetAmmo(client, type);
	static float charge[MAXTF2PLAYERS];
	if(ammo<2 || !(buttons & IN_ATTACK))
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
		if(charge[client] == FAR_FUTURE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		}
		else if(charge[client] < engineTime)
		{
			charge[client] = FAR_FUTURE;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+0.1);
		}
		else
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", (charge[client]-engineTime)*16.5);

			static float time[MAXTF2PLAYERS];
			if(time[client] < engineTime)
			{
				time[client] = engineTime+0.1;
				if(type != -1)
					SetEntProp(client, Prop_Data, "m_iAmmo", ammo-1, _, type);
			}
		}
	}
	else
	{
		charge[client] = GetEngineTime()+6.0;
	}
	return true;
}

public bool Items_PainKillerButton(int client, int weapon, int &buttons, int &holding)
{
	if(holding)
	{
		return false;
	}
	else if(buttons & IN_ATTACK)
	{
		holding = IN_ATTACK;

		int userid = GetClientUserId(client);
		ApplyHealEvent(userid, userid, 6);

		SetEntityHealth(client, GetClientHealth(client)+6);
		StartHealingTimer(client, 0.4, 1, 50);
	}
	else if(buttons & IN_ATTACK2)
	{
		holding = IN_ATTACK2;

		SpawnPlayerPickup(client, "item_healthkit_small");
	}
	else
	{
		return false;
	}

	RemoveAndSwitchItem(client, weapon);
	return false;
}

public bool Items_HealthKitButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2)))
	{
		holding = (buttons & IN_ATTACK) ? IN_ATTACK : IN_ATTACK2;
		SpawnPlayerPickup(client, "item_healthkit_medium");
		RemoveAndSwitchItem(client, weapon);
	}
	return false;
}

public bool Items_AdrenalineButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);
		StartHealingTimer(client, 0.334, 1, 60, true);
		TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, 20.0, client);
		Client[client].Extra3 = GetEngineTime()+20.0;
		FadeClientVolume(client, 0.3, 2.5, 17.5, 2.5);
	}
	return false;
}

public bool Items_RadioButton(int client, int entity, int &buttons, int &holding)
{
	if(!holding)
	{
		if(buttons & IN_ATTACK)
		{
			holding = IN_ATTACK;

			int clip = GetEntProp(entity, Prop_Data, "m_iClip1");
			if(clip > 3)
			{
				clip = 0;
			}
			else
			{
				clip++;
			}

			SetEntProp(entity, Prop_Data, "m_iClip1", clip);
		}
		else if(buttons & IN_ATTACK2)
		{
			holding = IN_ATTACK2;

			int clip = GetEntProp(entity, Prop_Data, "m_iClip1");
			if(clip < 1)
			{
				clip = 4;
			}
			else
			{
				clip--;
			}

			SetEntProp(entity, Prop_Data, "m_iClip1", clip);
		}
	}
	return false;
}

public bool Items_500Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);
		SpawnPlayerPickup(client, "item_healthkit_full");
		StartHealingTimer(client, 0.334, 1, 36, true);
		Client[client].Extra2 = 0;

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 2);
	}
	return false;
}

public bool Items_207Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);

		int current = GetClientHealth(client);
		int max = Classes_GetMaxHealth(client);
		if(current < max)
		{
			int health = max/3;
			if(current+health > max)
				health = max-current;

			SetEntityHealth(client, current+health);
			ApplyHealEvent(client, client, health);
		}

		if(Client[client].Extra2 < 4)
		{
			StartHealingTimer(client, 2.5, -1, 250, _, true);
			Client[client].Extra2++;
		}

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 2);
	}
	return false;
}

public bool Items_018Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);
		TF2_AddCondition(client, TFCond_CritCola, 6.0);
		TF2_AddCondition(client, TFCond_RestrictToMelee, 6.0);

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 2);
	}
	return false;
}

public bool Items_268Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;

		float engineTime = GetEngineTime();
		static float delay[MAXTF2PLAYERS];
		if(delay[client] > engineTime)
		{
			ClientCommand(client, "playgamesound items/medshotno1.wav");
			PrintCenterText(client, "%T", "in_cooldown", client);
			return false;
		}

		delay[client] = engineTime+90.0;
		TF2_AddCondition(client, TFCond_Stealthed, 15.0);
		ClientCommand(client, "playgamesound misc/halloween/spell_stealth.wav");

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class) && class.Group==1)
			Gamemode_GiveTicket(1, 1);
	}
	return false;
}

public bool Items_RadioRadio(int client, int entity, float &multi)
{
	static float time[MAXTF2PLAYERS];
	bool remove, off;
	float engineTime = GetEngineTime();
	switch(GetEntProp(entity, Prop_Data, "m_iClip1"))
	{
		case 1:
		{
			multi = 2.6;
			if(time[client]+8.0 < engineTime)
				remove = true;
		}
		case 2:
		{
			multi = 3.5;
			if(time[client]+4.0 < engineTime)
				remove = true;
		}
		case 3:
		{
			multi = 5.7;
			if(time[client]+2.0 < engineTime)
				remove = true;
		}
		case 4:
		{
			multi = 10.8;
			if(time[client]+1.0 < engineTime)
				remove = true;
		}
		default:
		{
			off = true;
		}
	}

	if(remove)
	{
		time[client] = engineTime;
		int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
		if(type != -1)
		{
			int ammo = GetAmmo(client, type);
			if(ammo > 0)
			{
				SetEntProp(client, Prop_Data, "m_iAmmo", ammo-1, _, type);
			}
			else
			{
				multi = 1.0;
				off = true;
			}
		}
	}
	return !off;
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

		default:
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

		default:
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

		default:
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

		default:
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

		default:
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

		default:
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

		default:
			return 0;
	}
}

public int Items_KeycardAll(int client, AccessEnum access)
{
	if(access==Access_Main || access==Access_Armory)
		return 3;

	return 1;
}

public int Items_KeycardScp(int client, AccessEnum access)
{
	if(access == Access_Checkpoint)
		return 1;

	return 0;
}