#pragma semicolon 1
#pragma newdecls required

enum struct WeaponEnum
{
	char Display[32];

	char Classname[36];
	char Attributes[256];
	int Index;
	bool Strip;

	char VeryFine[32];
	char Fine[32];
	char OneToOne[32];
	char Coarse[32];
	char Rough[32];

	TFClassType Class;
	int AmmoType;
	int ItemType;
	bool BlockAttack;
	int Ammo;
	int Clip;
	int Weight;

	char DisplayAttack[32];
	char DisplayAltfire[32];
	char DisplayReload[32];

	bool HideModel;
	char Worldmodel[PLATFORM_MAX_PATH];
	char Viewmodel[PLATFORM_MAX_PATH];
	int Viewindex;
	int Skin;

	//Function OnAmmo;		// void(int client, int type, int &ammo)
	//Function OnButton;		// Action(int client, int weapon, int &buttons, int &holding)
	// OnCard;		// int(int client, AccessEnum access)
	//Function OnCreate;		// void(int client, int weapon)
	//Function OnDamage;		// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	//Function OnDrop;		// bool(int client, int weapon, bool swap)
	//Function OnItem;		// void(int client, int type, int &amount)
	Function OnPrecache;	// void(WeaponEnum weapon)

	void SetupEnum(KeyValues kv)
	{
		kv.GetSectionName(this.Display, sizeof(this.Display));
		this.Index = StringToInt(this.Display);

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

		/*this.OnAmmo = KvGetFunction(kv, "func_ammo");
		this.OnButton = KvGetFunction(kv, "func_button");
		this.OnCard = KvGetFunction(kv, "func_card");
		this.OnCreate = KvGetFunction(kv, "func_create");
		this.OnDamage = KvGetFunction(kv, "func_damage");
		this.OnDrop = KvGetFunction(kv, "func_drop");
		this.OnItem = KvGetFunction(kv, "func_item");*/
		this.OnPrecache = KvGetFunction(kv, "func_precache");

		kv.GetString("classname", this.Classname, sizeof(this.Classname));
		kv.GetString("attributes", this.Attributes, sizeof(this.Attributes));
		
		if(kv.JumpToKey("downloads"))
		{
			int table = FindStringTable("downloadables");
			bool save = LockStringTables(false);

			do
			{
				kv.GetSectionName(this.Worldmodel, sizeof(this.Worldmodel));
				if(!FileExists(this.Worldmodel, true))
				{
					LogError("[Config] '%s' has missing file '%s'", this.Display, this.Worldmodel);
					continue;
				}

				AddToStringTable(table, this.Worldmodel);
			}
			while(kv.GotoNextKey());

			LockStringTables(save);
			kv.GoBack();
		}	

		kv.GetString("viewmodel", this.Viewmodel, sizeof(this.Viewmodel));
		this.Viewindex = this.Viewmodel[0] ? PrecacheModel(this.Viewmodel) : 0;		

		kv.GetString("model", this.Worldmodel, sizeof(this.Worldmodel));
		if(this.Worldmodel[0])
			PrecacheModel(this.Worldmodel);	
		
		KvGetTranslation(kv, "displayattack", this.DisplayAttack, sizeof(this.DisplayAttack), "weapon_0");
		KvGetTranslation(kv, "displayaltfire", this.DisplayAltfire, sizeof(this.DisplayAltfire), "weapon_0");
		KvGetTranslation(kv, "displayreload", this.DisplayReload, sizeof(this.DisplayReload), "weapon_0");

		kv.GetString("914++", this.VeryFine, sizeof(this.VeryFine));
		kv.GetString("914+", this.Fine, sizeof(this.Fine));
		kv.GetString("914", this.OneToOne, sizeof(this.OneToOne));
		kv.GetString("914-", this.Coarse, sizeof(this.Coarse));
		kv.GetString("914--", this.Rough, sizeof(this.Rough));
	}
}

static ArrayList WeaponList;
static float NextHudIn[MAXPLAYERS+1];

void Items_PluginStart()
{
}

void Items_ConfigSetup(KeyValues map)
{
	delete WeaponList;
	WeaponList = new ArrayList(sizeof(WeaponEnum));

	WeaponEnum weapon;
	BuildPath(Path_SM, weapon.Worldmodel, sizeof(weapon.Worldmodel), FOLDER_CONFIGS ... "/items.cfg");

	KeyValues kv = new KeyValues("Items");
	kv.ImportFromFile(weapon.Worldmodel);

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
	char buffer[64];

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
		if(weapon.OnPrecache != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnPrecache);
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

bool Items_AttemptPickup(int client, int index, int entity = -1)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
	{
		if(Items_CanPickupItem(client, index))
		{
			Items_GiveItem(client, index, entity);
			ClientCommand(client, "playgamesound AmmoPack.Touch");
			return true;
		}

		if(Items_CanAttractAmmo(client, index))
		{
			Items_AttractAmmo(client, index, entity);
			ClientCommand(client, "playgamesound AmmoPack.Touch");
			return true;
		}
	}

	return false;
}

bool Items_CanPickupItem(int client, int index)
{
	return true;
}

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

				// Set our ammo back
				for(int i; i < Ammo_MAX; i++)
				{
					if(ammo[i])
						SetAmmo(client, ammo[i], i);
				}
			}

			EquipPlayerWeapon(client, entity);
			Items_SwapToItem(client, entity);

			Forwards_OnWeaponPost(client, entity);
		}
	}

	return entity;
}

bool Items_CanAttractAmmo(int client, int index)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon) && weapon.AmmoType != -1)
	{
		if(GetAmmo(client, weapon.AmmoType) < Classes_GetMaxAmmo(client, weapon.AmmoType))
			return true;
	}

	return false;
}

bool Items_AttractAmmo(int client, int index, int ground = -1)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon) && weapon.AmmoType != -1)
	{
		int currentAmmo = GetAmmo(client, weapon.AmmoType);
		int maxAmmo = Classes_GetMaxAmmo(client, weapon.AmmoType);
		if(currentAmmo < maxAmmo)
		{
			if(ground == -1)
			{
				int ammo;

				if(weapon.Ammo > 0)
					ammo += weapon.Ammo;
				
				if(weapon.Clip > 0)
					ammo += weapon.Clip;
				
				if(ammo > 0)
				{
					ammo += currentAmmo;
					if(ammo > maxAmmo)
						ammo = maxAmmo;
					
					SetAmmo(client, ammo, weapon.AmmoType);
					return true;
				}
			}
			else	// Find the ammo through this really hacky method
			{
				int entity = CreateEntityByName(weapon.Classname);
				if(entity != -1)
				{
					SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", 0);
					SetEntProp(entity, Prop_Send, "m_bInitialized", 1);

					DispatchSpawn(entity);

					// Save our current ammo
					int ammo[Ammo_MAX];
					for(int i; i < Ammo_MAX; i++)
					{
						ammo[i] = GetAmmo(client, i);
						SetAmmo(client, 0, i);
					}

					// Get the new weapon's ammo
					SDKCalls_InitPickup(ground, client, entity);

					bool wasChanged;

					// Steal clip too
					int count = GetEntProp(entity, Prop_Data, "m_iClip1");
					if(count > 0)
					{
						ammo[weapon.AmmoType] += count;
						wasChanged = true;
					}

					// See where the ammo was sent to, add to our current ammo count
					for(int i; i < Ammo_MAX; i++)
					{
						count = GetAmmo(client, i);
						if(count)
						{
							ammo[weapon.AmmoType] += count;
							wasChanged = true;
							break;
						}
					}

					if(wasChanged && ammo[weapon.AmmoType] > maxAmmo)
						ammo[weapon.AmmoType] = maxAmmo;

					// Set our ammo back
					for(int i; i < Ammo_MAX; i++)
					{
						if(ammo[i])
							SetAmmo(client, ammo[i], i);
					}

					// Remove temp weapon
					int wearable = GetEntPropEnt(entity, Prop_Send, "m_hExtraWearable");
					if(wearable != -1)
						RemoveEntity(wearable);

					wearable = GetEntPropEnt(entity, Prop_Send, "m_hExtraWearableViewModel");
					if(wearable != -1)
						RemoveEntity(wearable);
					
					RemoveEntity(entity);
					
					return wasChanged;
				}
			}
		}
	}

	return false;
}

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

		if(!weapon.Worldmodel[0])
		{
			index = GetEntProp(weaponEntity, Prop_Send, HasEntProp(weaponEntity, Prop_Send, "m_iWorldModelIndex") ? "m_iWorldModelIndex" : "m_nModelIndex");
			if(index < 1)
				return false;

			ModelIndexToString(index, weapon.Worldmodel, sizeof(weapon.Worldmodel));
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
		int droppedEntity = SDKCalls_CreateDroppedWeapon(-1, vec, ang, weapon.Worldmodel, GetEntityAddress(weaponEntity) + view_as<Address>(offset));

		offset = list.Length;
		for(int i; i < offset; i++)
		{
			other = list.Get(i);
			SetEntProp(other, Prop_Data, "m_iEFlags", GetEntProp(other, Prop_Data, "m_iEFlags") & ~EFL_KILLME);
		}

		delete list;

		if(droppedEntity == -1)
			return false;
		
		DispatchSpawn(droppedEntity);

		//Check if weapon is not marked for deletion after spawn, otherwise we may get bad physics model leading to a crash
		if(GetEntProp(droppedEntity, Prop_Data, "m_iEFlags") & EFL_KILLME)
		{
			LogError("Unable to create dropped weapon with model '%s'", weapon.Worldmodel);
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

	return true;
}