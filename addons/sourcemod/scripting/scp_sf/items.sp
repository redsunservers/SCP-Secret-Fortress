#pragma semicolon 1
#pragma newdecls required

enum struct WeaponEnum
{
	char Display[32];

	char Classname[36];
	
	int Attrib[20];
	float Value[20];
	int Attribs;

	int Index;
	int AmmoType;
	int ItemType;
	int Ammo;
	int Clip;
	int Weight;

	bool Strip;
	bool BlockAttack;

	TFClassType Class;

	char DisplayAttack[32];
	char DisplayAltfire[32];
	char DisplayReload[32];

	char VeryFine[32];
	char Fine[32];
	char OneToOne[32];
	char Coarse[32];
	char Rough[32];

	bool HideModel;
	int Worldmodel;
	int Viewmodel;
	int Skin;

	//Function OnAmmo;		// void(int client, int type, int &ammo)
	//Function OnButton;		// Action(int client, int weapon, int &buttons, int &holding)
	Function FuncCard;		// int(int client, int type)
	Function FuncCreate;	// void(int client, int weapon)
	Function FuncDamage;	// Action(int client, int victim, ...)
	//Function OnDrop;		// bool(int client, int weapon, bool swap)
	//Function OnItem;		// void(int client, int type, int &amount)
	Function FuncPrecache;	// void(WeaponEnum weapon)

	void SetupEnum(KeyValues kv)
	{
		kv.GetSectionName(this.Display, sizeof(this.Display));
		this.Index = StringToInt(this.Display);

		char buffer[PLATFORM_MAX_PATH];

		Format(this.Display, sizeof(this.Display), "weapon_%d", this.Index);
		if(!TranslationPhraseExists(this.Display))
			strcopy(this.Display, sizeof(this.Display), "weapon_0");

		this.Ammo = kv.GetNum("ammo", -1);
		this.Clip = kv.GetNum("clip", -1);
		this.AmmoType = kv.GetNum("ammotype", -1);
		this.ItemType = kv.GetNum("itemtype", -1);
		this.Weight = kv.GetNum("weight");

		this.Strip = view_as<bool>(kv.GetNum("strip"));
		this.HideModel = view_as<bool>(kv.GetNum("hidemodel"));
		this.BlockAttack = view_as<bool>(kv.GetNum("blockattack"));
		this.Class = KvGetClass(kv, "class");
		this.Skin = kv.GetNum("skin", -1);

		this.Viewmodel = KvGetModelIndex(kv, "viewmodel");
		this.Worldmodel = KvGetModelIndex(kv, "model");

		kv.GetString("classname", this.Classname, sizeof(this.Classname));
		
		KvGetTranslation(kv, "displayattack", this.DisplayAttack, sizeof(this.DisplayAttack), "weapon_0");
		KvGetTranslation(kv, "displayaltfire", this.DisplayAltfire, sizeof(this.DisplayAltfire), "weapon_0");
		KvGetTranslation(kv, "displayreload", this.DisplayReload, sizeof(this.DisplayReload), "weapon_0");

		kv.GetString("914++", this.VeryFine, sizeof(this.VeryFine));
		kv.GetString("914+", this.Fine, sizeof(this.Fine));
		kv.GetString("914", this.OneToOne, sizeof(this.OneToOne));
		kv.GetString("914-", this.Coarse, sizeof(this.Coarse));
		kv.GetString("914--", this.Rough, sizeof(this.Rough));

		/*this.OnAmmo = KvGetFunction(kv, "func_ammo");
		this.OnButton = KvGetFunction(kv, "func_button");
		this.OnDrop = KvGetFunction(kv, "func_drop");
		this.OnItem = KvGetFunction(kv, "func_item");*/
		this.FuncCard = KvGetFunction(kv, "func_card");
		this.FuncCreate = KvGetFunction(kv, "func_create");
		this.FuncDamage = KvGetFunction(kv, "func_damage");
		this.FuncPrecache = KvGetFunction(kv, "func_precache");
		
		this.Attribs = 0;
		if(kv.JumpToKey("attributes"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));
					if(IsCharNumeric(buffer[0]))
					{
						this.Attrib[this.Attribs++] = StringToInt(buffer);
					}
					else
					{
						this.Attrib[this.Attribs++] = TF2Econ_TranslateAttributeNameToDefinitionIndex(buffer);
					}

					if(this.Attrib[this.Attribs] > 0)
					{
						this.Value[this.Attribs] = kv.GetFloat(NULL_STRING);
					}
					else
					{
						LogError("[Config] '%s' has invalid attribute '%s'", this.Display, buffer);
						this.Attribs--;
					}
				}
				while(kv.GotoNextKey(false));

				kv.GoBack();
			}

			kv.GoBack();
		}
		
		if(kv.JumpToKey("downloads"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				int table = FindStringTable("downloadables");
				bool save = LockStringTables(false);

				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));
					if(!FileExists(buffer, true))
					{
						LogError("[Config] '%s' has missing file '%s'", this.Display, buffer);
						continue;
					}

					AddToStringTable(table, buffer);
				}
				while(kv.GotoNextKey(false));

				LockStringTables(save);
				kv.GoBack();
			}

			kv.GoBack();
		}
	}

	Function GetFuncOf(int pos)
	{
		return GetItemInArray(this, pos);
	}
}

static ArrayList WeaponList;
static float NextHudIn[MAXPLAYERS+1];

void Items_PluginStart()
{
	RegAdminCmd("scp_giveitem", GiveItemCommand, ADMFLAG_SLAY, "Gives a player an item");
}

static Action GiveItemCommand(int client, int args)
{
	SetGlobalTransTarget(client);

	if(!args)
	{
		WeaponEnum weapon;

		int length = WeaponList.Length;
		for(int i; i < length; i++)
		{
			WeaponList.GetArray(i, weapon);
			ReplyToCommand(client, "%t | #%d", weapon.Display, weapon.Index);
		}

		if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
			ReplyToCommand(client, "[SM] %t", "See console for output");

		return Plugin_Handled;
	}

	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_giveitem [target] [name]");
		return Plugin_Handled;
	}

	char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(2, pattern, sizeof(pattern));

	char targetName[MAX_TARGET_LENGTH];

	SetGlobalTransTarget(client);

	int index;
	bool found;
	WeaponEnum weapon;
	int length = WeaponList.Length;
	for(int i; i < length; i++)
	{
		WeaponList.GetArray(i, weapon);
		FormatEx(targetName, sizeof(targetName), "%t", weapon.Display);
		if(StrContains(targetName, pattern, false) != -1)
		{
			found = true;
			break;
		}

		index++;
	}

	if(!found)
	{
		index = 0;
		length = WeaponList.Length;
		for(int i; i < length; i++)
		{
			WeaponList.GetArray(i, weapon);
			if(StrContains(weapon.Display, pattern, false) != -1)
			{
				found = true;
				break;
			}

			index++;
		}

		if(!found)
		{
			ReplyToCommand(client, "[SM] Invalid item string");
			return Plugin_Handled;
		}
	}

	int targets[MAXPLAYERS+1], matches;
	bool targetNounIsMultiLanguage;

	GetCmdArg(1, pattern, sizeof(pattern));
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	for(int i; i < matches; i++)
	{
		Items_GiveItem(targets[i], index);
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Gave %t to %t", weapon.Display, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Gave %t to %s", weapon.Display, targetName);
	}

	return Plugin_Handled;
}

void Items_ConfigSetup(KeyValues map)
{
	delete WeaponList;
	WeaponList = new ArrayList(sizeof(WeaponEnum));

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), FOLDER_CONFIGS ... "/items.cfg");

	KeyValues kv = new KeyValues("Items");
	kv.ImportFromFile(buffer);

	WeaponEnum weapon;

	if(map && map.JumpToKey("Items"))
	{
		if(map.GotoFirstSubKey())
		{
			do
			{
				weapon.SetupEnum(map);
				WeaponList.PushArray(weapon);
			}
			while(map.GotoNextKey());

			map.GoBack();
		}

		map.GoBack();
	}

	kv.GotoFirstSubKey();

	do
	{
		// If not already listed via map cfg
		kv.GetSectionName(buffer, sizeof(buffer));
		if(WeaponList.FindValue(StringToInt(buffer), WeaponEnum::Index) == -1)
		{
			weapon.SetupEnum(kv);
			WeaponList.PushArray(weapon);
		}
	}
	while(kv.GotoNextKey());

	delete kv;

	int length = WeaponList.Length;
	for(int i; i < length; i++)
	{
		WeaponList.GetArray(i, weapon);
		if(weapon.FuncPrecache != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.FuncPrecache);
			Call_PushArrayEx(weapon, sizeof(weapon), SM_PARAM_COPYBACK);
			Call_Finish();

			WeaponList.SetArray(i, weapon);
		}
	}
}

void Items_ClientDisconnect(int client)
{
	NextHudIn[client] = 0.0;
}

static bool Call_StartItemIndexFunc(int index, int pos)
{
	static WeaponEnum class;
	if(!Items_GetWeaponByIndex(index, class))
		return false;
	
	Function func = class.GetFuncOf(pos);
	if(func == INVALID_FUNCTION)
		return false;
	
	Call_StartFunction(null, func);
	return true;
}

static bool Call_StartItemEntityFunc(int entity, int pos)
{
	int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	return Call_StartItemIndexFunc(index, pos);
}

bool Items_GetWeaponByIndex(int index, WeaponEnum weapon)
{
	int pos = WeaponList.FindValue(index, WeaponEnum::Index);
	if(pos == -1)
		return false;
	
	WeaponList.GetArray(pos, weapon);
	return true;
}

bool Items_HasMultiInSlot(int client, int slot)
{
	bool found;
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity != -1)
		{
			if(TF2Util_GetWeaponSlot(entity) == slot)
			{
				if(found)
					return true;
				
				found = true;
			}
		}
	}

	return false;
}

void Items_SwapToBest(int client)
{
	if(!Items_SwapInSlot(client))
	{
		int entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if(entity != -1)
			Items_SwapToItem(client, entity);
	}
}

/*
	Swaps an item in the slot the player is holding
	Goes to the next weapon via m_hMyWeapons
	Swaps item positions in m_hMyWeapons to maintain the item when switching to different slots
*/
bool Items_SwapInSlot(int client)
{
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(active != -1)
	{
		int slot = TF2Util_GetWeaponSlot(active);
		
		int length = GetMaxWeapons(client);
		for(int i; i < length; i++)
		{
			if(GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) == active)
			{
				int lowestI, nextI;
				int lowestE = -1;
				int nextE = -1;
				int switchE = active;
				int switchI = i;
				for(int a; a < length; a++)
				{
					if(a != i)
					{
						int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", a);
						if(weapon != -1)
						{
							if(TF2Util_GetWeaponSlot(weapon) == slot)
							{
								if(a < switchI)
								{
									switchE = weapon;
									switchI = a;
								}

								if(lowestE == -1 || weapon < lowestE)
								{
									lowestE = weapon;
									lowestI = a;
								}

								if(weapon > active && (nextE == -1 || weapon < nextE))
								{
									nextE = weapon;
									nextI = a;
								}
							}
						}
					}
				}

				if(nextE == -1)
				{
					nextE = lowestE;
					nextI = lowestI;
				}

				if(nextE != -1 && switchI != nextI)
				{
					SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", nextE, switchI);
					SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", switchE, nextI);
					
					TF2Util_SetPlayerActiveWeapon(client, nextE);
					return true;
				}

				break;
			}
		}
	}

	return false;
}

/*
	Swaps an item and uses the m_hMyWeapons to maintain the item
*/
void Items_SwapToItem(int client, int swap)
{
	int slot = TF2Util_GetWeaponSlot(swap);
	
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		if(GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) == swap)
		{
			for(int a; a < i; a++)
			{
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", a);
				if(weapon != -1)
				{
					if(TF2Util_GetWeaponSlot(weapon) == slot)
					{
						SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", swap, a);
						SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", weapon, i);
						break;
					}
				}
			}

			break;
		}
	}

	TF2Util_SetPlayerActiveWeapon(client, swap);
}

/*
	Ground weapon is NOT deleted here
*/
bool Items_AttemptPickup(int client, int index, int entity = -1)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		int failed;
		int swap = -1;
		if(weapon.ItemType >= 0)
		{
			int maxItems = Classes_GetMaxItems(client, weapon.ItemType);
			if(maxItems < 1)
			{
				failed = 2;	// Can't pick up any
			}
			else
			{
				int items = GetItemTypeCount(client, weapon.ItemType, swap);
				if(items < maxItems)
					swap = -1;	// Will not swap items
			}
		}

		if(!failed && swap == -1)
		{
			int items = GetItemCount(client);
			int maxItems = Classes_GetMaxItems(client, Type_Any);
			if(items < maxItems)
				failed = 1;	// Inventory full
		}

		switch(failed)
		{
			case 1:
			{
				ClientCommand(client, "playgamesound Player.UseDeny");
				ShowGameText(client, "obj_weapon_pickup", 0, "%t", "Inventory Full");
			}
			case 2:
			{
				ClientCommand(client, "playgamesound Player.UseDeny");
				ShowGameText(client, "obj_weapon_pickup", 0, "%t", "Item Type Blocked");
			}
			default:
			{
				if(swap != -1 && !Items_DropItem(client, swap, false))
				{
					ClientCommand(client, "playgamesound Player.UseDeny");
					ShowGameText(client, "obj_weapon_pickup", 0, "%t", "Item Type Blocked");
				}
				else
				{
					Items_GiveItem(client, index, entity);
					ClientCommand(client, "playgamesound AmmoPack.Touch");
					if(swap != -1)
						ClientCommand(client, "playgamesound weapon.ImpactSoft");

					ShowGameText(client, "obj_weapon_pickup", 0, "%t", "Picked Up Item", weapon.Display);
					return true;
				}
			}
		}
	}

	return false;
}

bool Items_CanPickupItem(int client, int index)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		bool swap;
		if(weapon.ItemType >= 0)
		{
			int maxItems = Classes_GetMaxItems(client, weapon.ItemType);
			if(maxItems < 1)
				return false;	// Can't pick up any
			
			int items = GetItemTypeCount(client, weapon.ItemType);
			if(items >= maxItems)
				swap = true;	// Will swap items
		}

		if(!swap)
		{
			int items = GetItemCount(client);
			int maxItems = Classes_GetMaxItems(client, Type_Any);
			if(items < maxItems)
				return false;	// Inventory full
		}

		return true;
	}

	return false;
}

static int GetItemCount(int client)
{
	int count;
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		if(GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) != -1)
			count++;
	}

	return count;
}

static int GetItemTypeCount(int client, int type, int &first = 0)
{
	int count;
	WeaponEnum weapon;
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity != -1 &&
			Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) &&
			weapon.ItemType == type)
		{
			count++;
			if(first == -1)
				first = entity;
		}
	}

	return count;
}

/*
	Ground weapon is NOT deleted here
*/
int Items_GiveItem(int client, int index, int ground = -1)
{
	int entity = index;

	switch(Forwards_OnWeaponPre(client, ground, entity))
	{
		case Plugin_Changed:
		{
			index = entity;
		}
		case Plugin_Handled, Plugin_Stop:
		{
			return -1;
		}
	}

	entity = -1;
	
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		entity = CreateEntityByName(weapon.Classname);
		if(entity != -1)
		{
			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
			SetEntProp(entity, Prop_Send, "m_bInitialized", 1);
			SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", 1);
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
			SetItemID(entity, 0);

			DispatchSpawn(entity);

			if(ground == -1)	// Newly generated weapon
			{
				SetEntProp(entity, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));

				if(weapon.Clip >= 0)
					SetEntProp(entity, Prop_Data, "m_iClip1", weapon.Clip);

				if(weapon.Ammo > 0 && weapon.AmmoType >= 0)
				{
					int ammo = weapon.Ammo + GetAmmo(client, weapon.AmmoType);

					int maxAmmo = Classes_GetMaxAmmo(client, weapon.AmmoType);
					if(ammo > maxAmmo)
						ammo = maxAmmo;

					SetAmmo(client, ammo, weapon.AmmoType);
				}

				for(int i; i < weapon.Attribs; i++)
				{
					TF2Attrib_SetByDefIndex(entity, weapon.Attrib[i], weapon.Value[i]);
				}
			}
			else	// Existing picked up weapon
			{
				SetEntProp(entity, Prop_Send, "m_iAccountID", GetEntProp(ground, Prop_Send, "m_iAccountID"));

				// Save our current ammo
				int ammo[Ammo_MAX];
				for(int i; i < Ammo_MAX; i++)
				{
					ammo[i] = GetAmmo(client, i);
					SetAmmo(client, 0, i);
				}

				// Get the new weapon's ammo
				SDKCalls_InitPickup(ground, client, entity);

				// See where the ammo was sent to, add to our current ammo count
				if(weapon.AmmoType >= 0)
				{
					for(int i; i < Ammo_MAX; i++)
					{
						int count = GetAmmo(client, i);
						if(count)
						{
							ammo[weapon.AmmoType] += count;

							count = Classes_GetMaxAmmo(client, weapon.AmmoType);
							if(ammo[weapon.AmmoType] > count)
								ammo[weapon.AmmoType] = count;
							
							break;
						}
					}
				}

				// Set our ammo back
				for(int i; i < Ammo_MAX; i++)
				{
					if(ammo[i])
						SetAmmo(client, ammo[i], i);
				}
			}

			EquipPlayerWeapon(client, entity);

			if(weapon.HideModel)
			{
				SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}
			else
			{
				if(weapon.Worldmodel)
				{
					for(int i; i < 4; i++)
					{
						SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", weapon.Worldmodel, _, i);
					}
				}

				SetEntityMaterialData(entity, weapon.Skin);
			}

			if(weapon.BlockAttack)
			{
				if(weapon.HideModel)
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
				
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", FAR_FUTURE);
			}

			if(weapon.Strip)
				DHooks_HookStripWeapon(entity);

			if(weapon.AmmoType >= 0)
				SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", weapon.AmmoType);
			
			if(Call_StartItemIndexFunc(index, WeaponEnum::FuncCreate))
			{
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_Finish();
			}

			Items_SwapToItem(client, entity);
			Forwards_OnWeaponPost(client, entity);
		}
	}

	return entity;
}

/*
	Held weapons is deleted here
*/
void Items_DropAllItems(int client)
{
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity != -1)
			Items_DropItem(client, entity, true);
	}
}

/*
	Held weapons is deleted here
*/
bool Items_AttemptDropItem(int client, int entity)
{
	if(DropEmptyItems(client) || Items_DropItem(client, entity, false))
	{
		ClientCommand(client, "playgamesound weapon.ImpactSoft");
		return true;
	}

	return false;
}

bool Items_CanDropItem(int client, int entity)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) && !weapon.HideModel)
		return true;
	
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		int other = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(other != -1)
		{
			if(GetEntProp(other, Prop_Data, "m_iClip1") < 1)
			{
				int type = GetEntProp(other, Prop_Send, "m_iPrimaryAmmoType");
				if(type > 0 && GetAmmo(client, type) < 1)
					return true;
			}
		}
	}

	return false;
}

/*
	Held weapons is deleted here
*/
static bool DropEmptyItems(int client)
{
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity != -1)
		{
			if(GetEntProp(entity, Prop_Data, "m_iClip1") < 1)
			{
				int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
				if(type > 0 && GetAmmo(client, type) < 1)
				{
					Items_DropItem(client, entity, false);
					return true;
				}
			}
		}
	}

	return false;
}

/*
	Held weapons is deleted here
*/
bool Items_DropItem(int client, int weaponEntity, bool byForce)
{
	int index = GetEntProp(weaponEntity, Prop_Send, "m_iItemDefinitionIndex");

	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon) && !weapon.HideModel)
	{
		float pos[3], ang[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);

		char buffer[PLATFORM_MAX_PATH];
		GetEntityNetClass(weaponEntity, buffer, sizeof(buffer));
		int offset = FindSendPropInfo(buffer, "m_Item");
		if(offset < 0)
		{
			LogError("Failed to find m_Item on: %s", buffer);
			return false;
		}

		if(weapon.Worldmodel)
		{
			ModelIndexToString(weapon.Worldmodel, buffer, sizeof(buffer));
		}
		else
		{
			index = GetEntProp(weaponEntity, Prop_Send, HasEntProp(weaponEntity, Prop_Send, "m_iWorldModelIndex") ? "m_iWorldModelIndex" : "m_nModelIndex");
			if(index < 1)
				return false;

			ModelIndexToString(index, buffer, sizeof(buffer));
		}

		Handle trace = TR_TraceRayFilterEx(pos, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
		if(!TR_DidHit(trace))	// Outside of map
		{
			delete trace;
			return false;
		}
		
		float vec[3];
		TR_GetEndPosition(vec, trace);
		delete trace;

		int savedAmmo;
		if(!byForce && weapon.AmmoType >= 0)
		{
			// Player keeps ammo and drops what ammo it has
			savedAmmo = GetAmmo(client, weapon.AmmoType);
			SetAmmo(client, 0, weapon.AmmoType);

			// Steal leftover clip
			int clip = GetEntProp(weaponEntity, Prop_Data, "m_iClip1");
			if(clip > 0)
			{
				savedAmmo += clip;
				int maxAmmo = Classes_GetMaxAmmo(client, weapon.AmmoType);

				if(savedAmmo > maxAmmo)
				{
					clip = savedAmmo - maxAmmo;
					savedAmmo = maxAmmo;
				}
				else
				{
					clip = 0;
				}

				SetEntProp(weaponEntity, Prop_Data, "m_iClip1", clip);
			}
		}
		
		// CTFDroppedWeapon::Create deletes tf_dropped_weapon if there too many in map, pretend entity is marking for deletion so it doesnt actually get deleted
		ArrayList list = new ArrayList();
		int other = MaxClients + 1;
		while((other=FindEntityByClassname(other, "tf_dropped_weapon")) != -1)
		{
			int flags = GetEntProp(other, Prop_Data, "m_iEFlags");
			if(flags & EFL_KILLME)
				continue;

			SetEntProp(other, Prop_Data, "m_iEFlags", flags | EFL_KILLME);
			list.Push(other);
		}

		//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
		int droppedEntity = SDKCalls_CreateDroppedWeapon(-1, vec, ang, buffer, GetEntityAddress(weaponEntity) + view_as<Address>(offset));

		offset = list.Length;
		for(int i; i < offset; i++)
		{
			other = list.Get(i);
			SetEntProp(other, Prop_Data, "m_iEFlags", GetEntProp(other, Prop_Data, "m_iEFlags") & ~EFL_KILLME);
		}

		delete list;

		if(droppedEntity != -1)
		{
			DispatchSpawn(droppedEntity);

			//Check if weapon is not marked for deletion after spawn, otherwise we may get bad physics model leading to a crash
			if(GetEntProp(droppedEntity, Prop_Data, "m_iEFlags") & EFL_KILLME)
			{
				LogError("Unable to create dropped weapon with model '%s'", buffer);
			}
			else
			{
				SDKCalls_InitDroppedWeapon(droppedEntity, client, weaponEntity, byForce, false);
				TF2_RemoveItem(client, weaponEntity);

				if(weapon.Skin >= 0)
				{
					SetVariantInt(weapon.Skin);
					AcceptEntityInput(droppedEntity, "Skin");
					SetEntityMaterialData(droppedEntity, weapon.Skin);
				}

				float vel[3];
				if(byForce)
				{
					vel[0] = float(GetRandomInt(-100, 100));
					vel[1] = float(GetRandomInt(-100, 100));
					vel[2] = float(GetRandomInt(25, 100));
				}

				TeleportEntity(droppedEntity, pos, NULL_VECTOR, vel);
				
				if(byForce && weapon.AmmoType >= 0)
				{
					// Remove ammo from player via force
					SetAmmo(client, 0, weapon.AmmoType);
				}
				
				// Add dropped weapon to list, ordered by time created
				static ArrayList droppedweapons;
				if(!droppedweapons)
					droppedweapons = new ArrayList();
				
				droppedweapons.Push(EntIndexToEntRef(droppedEntity));
				int length = droppedweapons.Length;
				for(int i = length - 1; i >= 0; i--)
				{
					// Clean up any ents that were already removed
					if(!IsValidEntity(droppedweapons.Get(i)))
						droppedweapons.Erase(i);
				}
				
				int maxcount = 60;//CvarDroppedWeaponCount.IntValue;
				if(maxcount != -1)
				{
					// If there are too many dropped weapon, remove some ordered by time created
					length = droppedweapons.Length;
					while(length > maxcount)
					{
						RemoveEntity(droppedweapons.Get(0));
						droppedweapons.Erase(0);
						length--;
					}
				}
			}
		}

		if(!byForce && weapon.AmmoType >= 0)
		{
			// Restore player ammo
			SetAmmo(client, savedAmmo, weapon.AmmoType);
		}
	}

	return true;
}

Action Items_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;

	if(attacker > 0 && attacker <= MaxClients && weapon > MaxClients)
	{
		if(Call_StartItemEntityFunc(weapon, WeaponEnum::FuncDamage))
		{
			Call_PushCell(attacker);
			Call_PushCell(victim);
			Call_PushCellRef(inflictor);
			Call_PushFloatRef(damage);
			Call_PushCellRef(damagetype);
			Call_PushCellRef(weapon);
			Call_PushArrayEx(damageForce, sizeof(damageForce), SM_PARAM_COPYBACK);
			Call_PushArrayEx(damagePosition, sizeof(damagePosition), SM_PARAM_COPYBACK);
			Call_PushCell(damagecustom);
			Call_Finish(result);
		}
	}

	return result;
}

int Items_CardAccess(int client, int type)
{
	int result = 0;

	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity != -1)
	{
		if(Call_StartItemEntityFunc(entity, WeaponEnum::FuncCard))
		{
			Call_PushCell(client);
			Call_PushCell(type);
			Call_Finish(result);
		}
	}

	return result;
}