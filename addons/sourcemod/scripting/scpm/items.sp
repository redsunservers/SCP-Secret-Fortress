#pragma semicolon 1
#pragma newdecls required

enum struct ActionInfo
{
	int Index;
	char Prefix[32];
	Handle Subplugin;

	char Model[PLATFORM_MAX_PATH];
	int Skin;

	bool SetupKv(KeyValues kv, int index)
	{
		kv.GetSectionName(this.Prefix, sizeof(this.Prefix));
		this.Index = StringToInt(this.Prefix);
		this.Subplugin = INVALID_HANDLE;

		kv.GetString("name", this.Prefix, sizeof(this.Prefix), this.Prefix);

		if(!TranslationPhraseExists(this.Prefix))
		{
			LogError("[Config] Item '%s' has no translations", this.Prefix);
			return false;
		}

		if(kv.JumpToKey("downloads"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(this.Model, sizeof(this.Model));

					if(FileExists(this.Model, true))
					{
						AddFileToDownloadsTable(this.Model);
					}
					else
					{
						LogError("[Config] Missing file '%s' for '%s'", this.Model, this.Prefix);
					}
				}
				while(kv.GotoNextKey(false));

				kv.GoBack();
			}

			kv.GoBack();
		}

		this.Skin = kv.GetNum("skin", 255);
		kv.GetString("model", this.Model, sizeof(this.Model));
		if(this.Model[0])
			PrecacheModel(this.Model);
		
		if(StartCustomFunction(this.Subplugin, this.Prefix, "Precache"))
		{
			Call_PushCell(index);
			Call_PushArrayEx(this, sizeof(this), SM_PARAM_COPYBACK);
			Call_Finish();
		}

		return true;
	}
}

enum struct ItemInfo
{
	int Index;
	int Type;

	int Common;
	char Model[PLATFORM_MAX_PATH];

	void SetupKv(KeyValues kv)
	{
		this.Common = kv.GetNum("common", 1);
		kv.GetString("model", this.Model, sizeof(this.Model));
		if(this.Model[0])
			PrecacheModel(this.Model);
	}
}

static ArrayList ActionList;
static ArrayList ItemList;
static StringMap CompatList;
static ArrayList TypeList;

void Items_SetupConfig(KeyValues map)
{
	delete ActionList;
	ActionList = new ArrayList(sizeof(ActionInfo));

	delete ItemList;
	ItemList = new ArrayList(sizeof(ItemInfo));

	delete CompatList;
	CompatList = new StringMap();

	delete TypeList;
	TypeList = new ArrayList(ByteCountToCells(32));
	
	KeyValues kv;

	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Items"))
			kv = map;
	}

	char buffer1[PLATFORM_MAX_PATH], buffer2[32];
	
	if(!kv)
	{
		BuildPath(Path_SM, buffer1, sizeof(buffer1), CONFIG_CFG, "items");
		kv = new KeyValues("Items");
		kv.ImportFromFile(buffer1);
	}

	ItemInfo item;

	if(kv.JumpToKey("Groups"))
	{
		if(kv.GotoFirstSubKey())
		{
			do
			{
				kv.GetSectionName(buffer2, sizeof(buffer2));
				item.Type = TypeList.PushString(buffer2);

				if(kv.GotoFirstSubKey())
				{
					do
					{
						kv.GetSectionName(buffer2, sizeof(buffer2));
						item.Index = StringToInt(buffer2);

						item.SetupKv(kv);
						ItemList.PushArray(item);
					}
					while(kv.GotoNextKey());
					
					kv.GoBack();
				}
			}
			while(kv.GotoNextKey());

			kv.GoBack();
		}

		kv.GoBack();
	}

	ActionInfo action;
	int index;

	if(kv.JumpToKey("Consumables"))
	{
		if(kv.GotoFirstSubKey())
		{
			do
			{
				if(action.SetupKv(kv, index))
				{
					index = ActionList.PushArray(action) + 1;
				}
			}
			while(kv.GotoNextKey());

			kv.GoBack();
		}

		kv.GoBack();
	}

	if(kv.JumpToKey("Compact"))
	{
		if(kv.GotoFirstSubKey(false))
		{
			do
			{
				kv.GetSectionName(buffer1, sizeof(buffer1));
				kv.GetString(NULL_STRING, buffer2, sizeof(buffer2));
				CompatList.SetString(buffer1, buffer2);
			}
			while(kv.GotoNextKey(false));

			kv.GoBack();
		}

		kv.GoBack();
	}

	if(kv != map)
		delete kv;
}

void Items_RoundStart()
{
	// 100% at 32 players
	float chance = 0.4 + (MaxPlayersAlive[TFTeam_Humans] * 0.01875);

	int index;
	char buffer[PLATFORM_MAX_PATH], type[32];
	ItemInfo item;
	ActionInfo action;

	int entity = -1;
	while((entity=FindEntityByClassname(entity, "prop_dynamic*")) != -1)
	{
		int extra;
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrContains(buffer, "_rand_", false) == 3)
		{
			if(GetRandomFloat() > chance)
			{
				RemoveEntity(entity);
				continue;
			}

			index = 9;
		}
		else if(StrContains(buffer, "_item_", false) == 3)
		{
			index = 9;
		}
		else if(StrContains(buffer, "_weapon", false) == 3)
		{
			index = 11;
		}
		else if(StrContains(buffer, "_keycard_", false) == 3)
		{
			index = 12;
			extra = 1;
		}
		else if(StrContains(buffer, "_healthkit", false) == 3)
		{
			index = 14;
			extra = 2;
		}
		else
		{
			continue;
		}

		if(strlen(buffer) > index)
		{
			strcopy(type, sizeof(type), buffer[index]);
			int end = FindCharInString(type, '_');
			if(end != -1)
				type[end] = '\0';
			
			switch(extra)
			{
				case 1:
					IntToString(StringToInt(type) + 30000, type, sizeof(type));
				
				case 2:
					IntToString(StringToInt(type) + 30012, type, sizeof(type));
			}
		}
		else
		{
			strcopy(type, sizeof(type), "common");
		}
		
		if(CompatList.ContainsKey(type))
			CompatList.GetString(type, type, sizeof(type));
		
		int typeIndex = TypeList.FindString(type);
		
		if(typeIndex == -1)
		{
			index = StringToInt(type);

			index = GetItemDataOfIndex(index, _, item);
			if(index == -1)
			{
				LogError("[Map] Unknown item index '%s' for '%s'", type, buffer);
				RemoveEntity(entity);
				continue;
			}
		}
		else
		{
			index = GetItemDataOfType(typeIndex, item);
			if(index == -1)
			{
				LogError("[Config] Item group '%s' has no valid entries", type);
				RemoveEntity(entity);
				continue;
			}
		}
		
		index = GetActionDataOfIndex(item.Index, action);
		if(index == -1)
		{
			TF2Econ_GetItemDefinitionString(item.Index, "model_player", buffer, sizeof(buffer));
			if(buffer[0])
				SetEntityModel(entity, buffer);
		}
		else
		{
			if(action.Model[0])
				SetEntityModel(entity, action.Model);
			
			if(action.Skin)
				SetEntityRenderColor(entity, _, _, _, action.Skin);
		}
		
		FormatEx(buffer, sizeof(buffer), "scp_item_%d", item.Index);
		SetEntPropString(entity, Prop_Data, "m_iGlobalname", buffer);
	}
}

// Gets a random item based on it's type
static int GetItemDataOfType(int type, ItemInfo item)
{
	ArrayList list = new ArrayList();

	int length = ItemList.Length;
	for(int i; i < length; i++)
	{
		ItemList.GetArray(i, item);
		if(item.Type == type)
		{
			for(int b; b < item.Common; b++)
			{
				list.Push(i);
			}
		}
	}

	length = list.Length;
	if(length)
	{
		length = list.Get(GetURandomInt() % length);
		ItemList.GetArray(length, item);
	}
	else
	{
		length = -1;
	}

	delete list;
	return length;
}

// Gets the item based on it's index and type
static int GetItemDataOfIndex(int itemIndex, int type = -1, ItemInfo item)
{
	int length = ItemList.Length;
	for(int i; i < length; i++)
	{
		ItemList.GetArray(i, item);
		if(item.Index == itemIndex)
		{
			if(type == -1 || item.Type == type)
				return i;
		}
	}

	return -1;
}

// Gets the action based on it's index
static int GetActionDataOfIndex(int itemIndex, ActionInfo action)
{
	int length = ActionList.Length;
	for(int i; i < length; i++)
	{
		ActionList.GetArray(i, action);
		if(action.Index == itemIndex)
			return i;
	}

	return -1;
}

bool Items_CanSpawn(int itemIndex)
{
	return ItemList.FindValue(itemIndex, ItemInfo::Index) != -1;
}

// Gives a new weapon to the player given a index
int Items_GiveByIndex(int client, int itemIndex, bool tempWeapon = false, const char[] forceClassname = "")
{
	char classname[64];
	ActionInfo action;
	bool isAction = GetActionDataOfIndex(itemIndex, action) != -1;

	if(forceClassname[0])
	{
		strcopy(classname, sizeof(classname), forceClassname);
	}
	// Check if this index is an action
	else if(isAction)
	{
		if(!tempWeapon)
		{
			Items_GiveActionItem(client, itemIndex);
			return -1;
		}
		
		strcopy(classname, sizeof(classname), "tf_weapon_shovel");
	}
	else
	{
		TF2Econ_GetItemClassName(itemIndex, classname, sizeof(classname));
	}

	// Force to soldier shovel
	if(StrContains(classname, "saxxy", false) != -1)
		strcopy(classname, sizeof(classname), "tf_weapon_shovel");
	
	// Don't bother with wearables or builders
	if(StrContains(classname, "tf_weapon", false) == -1 || StrContains(classname, "tf_weapon_builder", false) != -1 || StrContains(classname, "tf_weapon_sapper", false) != -1)
		return -1;

	// Force to soldier shotgun
	if(StrContains(classname, "tf_weapon_shotgun", false) != -1)
		strcopy(classname, sizeof(classname), "tf_weapon_shotgun_soldier");

	// Drop anything in our current slot
	if(!isAction)
	{
		int slot = TF2_GetClassnameSlot(classname);
		if(slot != -1)
		{
			slot = GetPlayerWeaponSlot(client, slot);
			if(slot != -1)
			{
				float pos[3], ang[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, ang);
				Items_DropByEntity(client, slot, pos, ang, false);
			}
		}
	}

	int entity = CreateEntityByName(classname);
	if(entity != -1)
	{
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", isAction ? 196 : itemIndex);
		SetEntProp(entity, Prop_Send, "m_bInitialized", true);
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
		SetEntProp(entity, Prop_Send, "m_iEntityLevel", 1);

		DispatchSpawn(entity);

		if(isAction && action.Model[0])
			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", PrecacheModel(action.Model));
		
		if(isAction && action.Skin)
			SetEntityRenderColor(entity, _, _, _, action.Skin);
		
		if(isAction)
			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", itemIndex);
		
		if(!tempWeapon)
		{
			int type;
			if(!StrContains(classname, "tf_weapon_revolver"))
			{
				// Set revolver to primary slot ammo
				type = 1;
				SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", type);
			}
			else if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
			{
				type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
			}

			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
			EquipPlayerWeapon(client, entity);

			// Refill ammo correctly
			if(type > 0)
				GivePlayerAmmo(client, 100, type, true);

			if(!isAction)
				TF2U_SetPlayerActiveWeapon(client, entity);
		}
	}

	if(!Client(client).Boss)
		ClientCommand(client, "playgamesound ui/item_heavy_gun_pickup.wav");

	return entity;
}

// Gives the dropped weapon to the player
bool Items_GiveByEntity(int client, int entity, bool specialCheck = false)
{
	static Address offsetIndex;
	if(!offsetIndex)
		offsetIndex = view_as<Address>(FindSendPropInfo("CTFDroppedWeapon", "m_iItemDefinitionIndex"));
	
	int itemIndex = LoadFromAddress(GetEntityAddress(entity) + offsetIndex, NumberType_Int16);

	ActionInfo action;
	bool isAction = GetActionDataOfIndex(itemIndex, action) != -1;

	// Check if this index is an action
	if(isAction)
	{
		Items_GiveActionItem(client, itemIndex);
		return true;
	}
	
	char classname[64];
	TF2Econ_GetItemClassName(itemIndex, classname, sizeof(classname));
	
	// Don't bother with wearables or builders
	if(StrContains(classname, "tf_weapon", false) == -1 || StrContains(classname, "tf_weapon_builder", false) != -1 || StrContains(classname, "tf_weapon_sapper", false) != -1)
		return false;

	// Not all classes can use every weapon, get only their class or the spawn pool
	if(specialCheck && !Items_CanSpawn(itemIndex))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		if(TF2_GetWeaponClass(itemIndex, class, TF2_GetClassnameSlot(classname, true)) != class)
			return false;
	}

	// Force to soldier shotgun
	if(StrContains(classname, "tf_weapon_shotgun", false) != -1)
		strcopy(classname, sizeof(classname), "tf_weapon_shotgun_soldier");

	// Force to soldier shovel
	if(StrContains(classname, "saxxy", false) != -1)
		strcopy(classname, sizeof(classname), "tf_weapon_shovel");
	
	// Drop anything in our current slot
	int slot = TF2_GetClassnameSlot(classname);
	if(slot != -1)
	{
		slot = GetPlayerWeaponSlot(client, slot);
		if(slot != -1)
		{
			float pos[3], ang[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			Items_DropByEntity(client, slot, pos, ang, false);
		}
	}

	static Address offsetItem;
	if(!offsetItem)
		offsetItem = view_as<Address>(FindSendPropInfo("CTFDroppedWeapon", "m_Item"));

	int weapon = SDKCall_GiveNamedItem(client, classname, 0, GetEntityAddress(entity) + offsetItem, true);
	if(weapon != -1)
	{
		SDKCall_InitPickup(entity, client, weapon);
		EquipPlayerWeapon(client, weapon);
	}

	ClientCommand(client, "playgamesound ui/item_heavy_gun_pickup.wav");
	
	return true;
}

// Drops a new weapon from the player given a index
bool Items_DropByIndex(int client, int itemIndex, const float origin[3], const float angles[3], bool death)
{
	int entity = Items_GiveByIndex(client, itemIndex, true);
	if(entity == -1)
		return false;
	
	bool result = Items_DropByEntity(client, entity, origin, angles, death);

	if(!result)
		TF2_RemoveItem(client, entity);
	
	return result;
}

// Drops and removes a weapon from the player
bool Items_DropByEntity(int client, int helditem, const float origin[3], const float angles[3], bool death)
{
	int index = GetEntProp(helditem, Prop_Send, HasEntProp(helditem, Prop_Send, "m_iWorldModelIndex") ? "m_iWorldModelIndex" : "m_nModelIndex");
	if(index < 1)
		return false;

	char buffer[PLATFORM_MAX_PATH];
	ModelIndexToString(index, buffer, sizeof(buffer));

	//Dropped weapon doesn't like being spawn high in air, create on ground then teleport back after DispatchSpawn
	TR_TraceRayFilter(origin, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
	if(!TR_DidHit())	//Outside of map
		return false;

	float spawn[3];
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

	static Address offset;
	if(!offset)
		offset = view_as<Address>(FindSendPropInfo("CTFWearable", "m_Item"));
	
	//Pass client as NULL, only used for deleting existing dropped weapon which we do not want to happen
	entity = SDKCall_CreateDroppedWeapon(-1, spawn, angles, buffer, GetEntityAddress(helditem) + offset);

	int length = list.Length;
	for(int i; i<length; i++)
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
			LogError("Unable to create dropped weapon with model '%s'", buffer);
		}
		else
		{
			SDKCall_InitDroppedWeapon(entity, client, helditem, !death, death);

			bool wasActive = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == helditem;

			int r, g, b, a;
			GetEntityRenderColor(helditem, r, g, b, a);
			SetEntityRenderColor(entity, r, g, b, a);

			TF2_RemoveItem(client, helditem);

			if(wasActive && !death)
			{
				int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				if(melee != -1)
					TF2U_SetPlayerActiveWeapon(client, melee);
			}

			// throw the item, if specified
			float vel[3];
			
			if(death)
			{
				vel[0] = float(GetRandomInt(-100, 100));
				vel[1] = float(GetRandomInt(-100, 100));
				vel[2] = float(GetRandomInt(25, 100));
			}

			TeleportEntity(entity, origin, NULL_VECTOR, vel);
			result = true;
			
			// Add dropped weapon to list, ordered by time created
			static ArrayList droppedweapons;
			if(!droppedweapons)
				droppedweapons = new ArrayList();
			
			droppedweapons.Push(EntIndexToEntRef(entity));
			length = droppedweapons.Length;
			for(int i = length - 1; i >= 0; i--)
			{
				// Clean up any ents that were already removed
				if(!IsValidEntity(droppedweapons.Get(i)))
					droppedweapons.Erase(i);
			}
			
			// If there are too many dropped weapon, remove some ordered by time created
			length = droppedweapons.Length;
			while(length > 99)
			{
				RemoveEntity(droppedweapons.Get(0));
				droppedweapons.Erase(0);
				length--;
			}
		}
	}

	return result;
}

void Items_GiveActionItem(int client, int itemIndex)
{
	bool result;
	if(StartItemFunctionByIndex(itemIndex, "Type"))
	{
		Call_Finish(result);
	}

	if(!result)
	{
		// Already have an item
		if(Client(client).ActionItem != -1)
		{
			if(!Items_DropActionItem(client, false))
			{
				// Blocked from picking up
				float pos[3], ang[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, ang);
				Items_DropByIndex(client, itemIndex, pos, ang, false);
				return;
			}
		}
		
		Client(client).ActionItem = itemIndex;
	}
	
	ClientCommand(client, "playgamesound ui/item_light_gun_pickup.wav");

	if(StartItemFunctionByIndex(itemIndex, "Pickup"))
	{
		Call_PushCell(client);
		Call_Finish();
	}
}

bool Items_UseActionItem(int client)
{
	Client(client).LastNoiseAt = GetGameTime();
	
	if(Bosses_StartFunctionClient(client, "ActionButton"))
	{
		Call_PushCell(client);
		Call_Finish();
		return true;
	}
	
	if(Client(client).ActionItem == -1)
		return false;
	
	bool result = true;
	if(StartItemFunctionByIndex(Client(client).ActionItem, "Use"))
	{
		Call_PushCell(client);
		Call_Finish(result);
	}

	if(result)
		Client(client).ActionItem = -1;
	
	Client(client).ControlProgress = 2;
	return true;
}

bool Items_DropActionItem(int client, bool death)
{
	if(Client(client).ActionItem == -1)
		return false;
	
	bool result = true;
	if(StartItemFunctionByIndex(Client(client).ActionItem, "Drop"))
	{
		Call_PushCell(client);
		Call_PushCell(death);
		Call_Finish(result);
	}

	if(result)
	{
		float pos[3], ang[3];
		GetClientEyePosition(client, pos);
		GetClientEyeAngles(client, ang);
		Items_DropByIndex(client, Client(client).ActionItem, pos, ang, death);
		Client(client).ActionItem = -1;
	}
	
	Client(client).ControlProgress = 2;
	return result;
}

stock bool Items_GetItemName(int itemIndex, char[] name, int length)
{
	static ActionInfo action;
	if(GetActionDataOfIndex(itemIndex, action) == -1)
		return TF2Econ_GetLocalizedItemName(itemIndex, name, length);
	
	strcopy(name, length, action.Prefix);
	return true;
}

// 4: Rough, 3: Coarse, 2: 1:1, 1: Fine, 0: Very Fine
int Items_GetUpgradePath(int itemIndex, int type)
{
	ActionInfo action;

	if(GetActionDataOfIndex(itemIndex, action) == -1)
	{
		TFClassType class = TFClass_Engineer;
		int slot = TFWeaponSlot_Secondary;
		
		static TFClassType ClassIndexes[] = {TFClass_Scout, TFClass_Soldier, TFClass_Pyro, TFClass_DemoMan, TFClass_Heavy, TFClass_Engineer, TFClass_Medic, TFClass_Sniper, TFClass_Spy};

		SortIntegers(view_as<int>(ClassIndexes), sizeof(ClassIndexes), Sort_Random);

		for(int i; i < sizeof(ClassIndexes); i++)
		{
			int found = TF2Econ_GetItemLoadoutSlot(itemIndex, ClassIndexes[i]);
			if(found != -1)
			{
				class = ClassIndexes[i];
				slot = found;
				break;
			}
		}

		switch(type)
		{
			case 4:	// Rough
			{
				class = ClassIndexes[0];
				slot = TFWeaponSlot_Melee;
			}
			case 3:	// Coarse
			{
				slot++;
				if(slot > TFWeaponSlot_Melee)
					slot = TFWeaponSlot_Melee;
			}
			case 1:	// Fine
			{
				slot--;
				if(slot < TFWeaponSlot_Primary)
					slot = TFWeaponSlot_Primary;
			}
			case 0:	// Very Fine
			{
				class = ClassIndexes[0];
				slot = TFWeaponSlot_Primary;
			}
		}
		
		ItemInfo item;
		int length = ItemList.Length;
		int start = GetURandomInt() % length;
		for(int a = start + 1; a != start; a++)
		{
			if(a >= length)
			{
				a = -1;
				continue;
			}

			ItemList.GetArray(a, item);
			if(item.Index == itemIndex)
				continue;
			
			if(GetActionDataOfIndex(item.Index, action) != -1)
				continue;

			if(TF2Econ_GetItemLoadoutSlot(item.Index, class) != slot)
				return item.Index;
		}

		return -1;
	}

	return -1;
}

static bool StartItemFunctionByIndex(int itemIndex, const char[] name)
{
	static ActionInfo action;
	if(GetActionDataOfIndex(itemIndex, action) == -1)
		return false;
	
	return StartCustomFunction(action.Subplugin, action.Prefix, name);
}
