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
	bool Attack;

	char Model[PLATFORM_MAX_PATH];
	char ViewmodelName[PLATFORM_MAX_PATH];
	int Viewmodel;
	int Skin;
	int Rarity;

	Function OnAmmo;		// void(int client, int type, int &ammo)
	Function OnButton;	// Action(int client, int weapon, int &buttons, int &holding)
	Function OnCard;		// int(int client, AccessEnum access)
	Function OnCreate;	// void(int client, int weapon)
	Function OnDamage;	// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnDrop;		// bool(int client, int weapon, bool swap)
	Function OnItem;		// void(int client, int type, int &amount)
	Function OnRadio;		// int(int client, int weapon)
	Function OnSpeed;		// void(int client, float &speed)
	Function OnSprint;	// void(int client, float &drain)
}

enum
{
	ItemDrop_Drop,
	ItemDrop_Throw,
	ItemDrop_Scatter,
}

static ArrayList Weapons;

// Some items like healthkit or grenades have actions that will be executed while holding them
// If the player switches weapons or dies though, these actions must be cancelled
// Use Items_StartDelayedAction to start a new delayed action
// Use Items_CancelDelayedAction to stop it pre-maturely (there can only be one per client)
// item actions can assume the item is still valid, so it should always be called before the item gets deleted or stripped etc
// the action func can detect if it was called while cancelled using Items_IsDelayedActionCancelled

// TODO: shouldn't this be in the class struct?
static Handle Item_DelayedAction[MAXTF2PLAYERS] = {INVALID_HANDLE, ...};

void Items_Setup(KeyValues main, KeyValues map)
{
	if(Weapons != INVALID_HANDLE)
		delete Weapons;

	Weapons = new ArrayList(sizeof(WeaponEnum));

	Init_SCP18();
	
	main.Rewind();
	KeyValues kv = main;
	if(map)	// Check if the map has it's own gamemode config
	{
		map.Rewind();
		if(map.JumpToKey("Weapons"))
			kv = map;
	}

	char buffer[PLATFORM_MAX_PATH];
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
		weapon.Type = kv.GetNum("type");
		weapon.Skin = kv.GetNum("skin", -1);
		weapon.Rarity = kv.GetNum("rarity", -1);

		weapon.Strip = view_as<bool>(kv.GetNum("strip"));
		weapon.Hide = view_as<bool>(kv.GetNum("hide"));
		weapon.Hidden = view_as<bool>(kv.GetNum("hidden"));
		weapon.Attack = view_as<bool>(kv.GetNum("attack", 1));
		weapon.Class = KvGetClass(kv, "class");

		weapon.OnAmmo = KvGetFunction(kv, "func_ammo");
		weapon.OnButton = KvGetFunction(kv, "func_button");
		weapon.OnCard = KvGetFunction(kv, "func_card");
		weapon.OnCreate = KvGetFunction(kv, "func_create");
		weapon.OnDamage = KvGetFunction(kv, "func_damage");
		weapon.OnDrop = KvGetFunction(kv, "func_drop");
		weapon.OnItem = KvGetFunction(kv, "func_item");
		weapon.OnRadio = KvGetFunction(kv, "func_radio");
		weapon.OnSpeed = KvGetFunction(kv, "func_speed");
		weapon.OnSprint = KvGetFunction(kv, "func_sprint");

		kv.GetString("classname", weapon.Classname, sizeof(weapon.Classname));
		kv.GetString("attributes", weapon.Attributes, sizeof(weapon.Attributes));
		
		if(kv.JumpToKey("downloads"))
		{
			int table = FindStringTable("downloadables");
			bool save = LockStringTables(false);
			for(int i=1; ; i++)
			{
				IntToString(i, weapon.Model, sizeof(weapon.Model));
				kv.GetString(weapon.Model, buffer, sizeof(buffer));
				if(!buffer[0])
					break;

				if(!FileExists(buffer, true))
				{
					LogError("[Config] '%s' has missing file '%s'", weapon.Display, buffer);
					continue;
				}

				AddToStringTable(table, buffer);
			}
			LockStringTables(save);
			kv.GoBack();
		}	

		kv.GetString("viewmodel", weapon.ViewmodelName, sizeof(weapon.ViewmodelName));
		weapon.Viewmodel = weapon.ViewmodelName[0] ? PrecacheModel(weapon.ViewmodelName, true) : 0;
		
		kv.GetString("sound", weapon.Model, sizeof(weapon.Model));
		if(weapon.Model[0])
		{
			PrecacheSound(weapon.Model, true);
			PrecacheScriptSound(weapon.Model);		

			weapon.Model[0] = 0;
		}			

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

void Items_RoundStart()
{
	Items_ClearDelayedActions();

	int players;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
			players++;
	}

	if(players < 8)
		players = 8;

	char buffer[PLATFORM_MAX_PATH];
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "prop_dynamic*")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_rand_", false))
		{
			if(GetRandomInt(1, 32) > players)
				RemoveEntity(entity);
		}

		GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));

		// compatibility, remap old model paths to new ones
		if (!strcmp(buffer, "models/scp_sl/keycard.mdl", false))
		{
			SetEntityModel(entity, "models/scp_fixed/keycard/w_keycard.mdl");
			// the keycard stores skin inside the alpha, so we need to translate that here too
			SetEntityMaterialData(entity, GetEntProp(entity, Prop_Data, "m_nSkin"));			
			continue;
		}
		if (!strcmp(buffer, "models/vinrax/props/firstaidkit.mdl", false))
		{
			SetEntityModel(entity, "models/scp_fixed/medkit/w_medkit.mdl");
			continue;
		}
	}
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

bool Items_GetWeaponByModel(const char[] model, WeaponEnum weapon)
{
	int length = Weapons.Length;
	for(int i; i<length; i++)
	{
		Weapons.GetArray(i, weapon);
		if(StrEqual(model, weapon.Model, false))
			return true;
	}
	return false;
}

bool Items_GetRandomWeapon(int rarity, WeaponEnum weapon)
{
	ArrayList list = new ArrayList();
	int length = Weapons.Length;
	for(int i; i<length; i++)
	{
		Weapons.GetArray(i, weapon);
		if(weapon.Rarity == rarity)
			list.Push(i);
	}

	length = list.Length;
	if(length < 1)
	{
		delete list;
		return false;
	}

	Weapons.GetArray(list.Get(GetRandomInt(0, length-1)), weapon);
	delete list;
	return true;
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

ArrayList Items_ArrayList(int client, int slot=-1, bool all=false)
{
	ArrayList list = new ArrayList();
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(slot != -1)
		{
			static char buffer[36];
			if(!GetEntityClassname(entity, buffer, sizeof(buffer)) || TF2_GetClassnameSlot(buffer)!=slot)
				continue;
		}

		if(!all && (!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.Hidden))
			continue;

		list.Push(entity);
	}

	list.Sort(Sort_Ascending, Sort_Integer);
	return list;
}

int Items_CreateWeapon(int client, int index, bool equip=true, bool clip=false, bool ammo=false, int ground=-1)
{
	int entity = index;
	switch(Forward_OnWeaponPre(client, ground, entity))
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
		static char buffers[40][16];
		int count = ExplodeString(weapon.Attributes, " ; ", buffers, sizeof(buffers), sizeof(buffers));

		if(count % 2)
			count--;

		int i;
		bool wearable = view_as<bool>(StrContains(weapon.Classname, "tf_weap", false));
		if(wearable)
		{
			int newItemRegionMask = TF2Econ_GetItemEquipRegionMask(index);

			// Do not create this wearable if it would conflict with existing items
			for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(client); wbl++)
			{
				int wearableEnt = TF2Util_GetPlayerWearable(client, wbl);
				if (wearableEnt == -1)
					continue;

				int wearableDefindex = GetEntProp(wearableEnt, Prop_Send, "m_iItemDefinitionIndex");
				if (wearableDefindex == DEFINDEX_UNDEFINED)
					continue;

				int wearableRegionMask = TF2Econ_GetItemEquipRegionMask(wearableDefindex);
				if (wearableRegionMask & newItemRegionMask)
					return -1;
			}

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

			ApplyStrangeRank(entity, GetRandomInt(0, 20));

			if(weapon.Hide)
			{
				SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}

			if (!wearable && (weapon.Hide || !weapon.Attack))
			{
				if (weapon.Hide)
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", FAR_FUTURE);
			}
			
			if (!weapon.Hide)
			{
				SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
				if(weapon.Model[0])
				{
					int precache = PrecacheModel(weapon.Model);
					for(i=0; i<4; i++)
					{
						SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", precache, _, i);
					}
				}
				
				// the keycard uses this alt method because skins can't be overwriten when attached to a player
				SetEntityMaterialData(entity, weapon.Skin);
			}

			if(!wearable)
			{
				if(ground > MaxClients)
				{
					i = GetEntProp(entity, Prop_Send, "m_iAccountID");
				}
				else
				{
					i = GetSteamAccountID(client, false);
				}
				SetEntProp(entity, Prop_Send, "m_iAccountID", i);

				if(weapon.Bullet>=0 && weapon.Bullet<AMMO_MAX)
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
					int ammos[AMMO_MAX];
					for(i=1; i<AMMO_MAX; i++)
					{
						ammos[i] = GetAmmo(client, i);
						SetAmmo(client, 0, i);
					}

					// Get the new weapon's ammo
					SDKCall_InitPickup(ground, client, entity);

					// See where the ammo was sent to, add to our current ammo count
					for(i=0; i<AMMO_MAX; i++)
					{
						count = GetEntProp(client, Prop_Data, "m_iAmmo", _, i);
						if(!count)
							continue;

						if(count < 0)	// Guess we give a new set of ammo
							count = weapon.Ammo;

						ammos[weapon.Bullet] += count;

						count = Classes_GetMaxAmmo(client, weapon.Bullet);
						Items_Ammo(client, weapon.Bullet, count);
						if(ammos[weapon.Bullet] > count)
							ammos[weapon.Bullet] = count;

						break;
					}

					// Set our ammo back
					for(i=0; i<AMMO_MAX; i++)
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
						Items_Ammo(client, weapon.Bullet, i);
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
			{
				Items_SetActiveWeapon(client, entity);
				SZF_DropItem(client);
			}

			Items_ShowItemMenu(client);
			Forward_OnWeapon(client, entity);
		}
	}
	return entity;
}

void Items_SetActiveWeapon(int client, int weapon)
{
	Items_CancelDelayedAction(client);
	
	SetActiveWeapon(client, weapon);	

	if (Items_IsHoldingWeapon(client))
	{
		Client[client].LastWeaponTime = GetGameTime();
	}
	
	Items_SetupViewmodel(client, weapon);
}

void Items_SetEmptyWeapon(int client)
{
	FakeClientCommand(client, "use tf_weapon_fists");
	Items_SetupViewmodel(client, -1);
	Items_ShowItemMenu(client);
}

void Items_SetupViewmodel(int client, int weapon)
{
	// if the current weapon needs a unique viewmodel, set it up
	ViewModel_Destroy(client);
	if (IsValidEntity(weapon))
	{
		WeaponEnum Weapon;
		if (Items_GetWeaponByIndex(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"), Weapon))
		{
			if (Weapon.ViewmodelName[0])
			{
				// all custom viewmodels follow this anim name convention
				ViewModel_Create(client, Weapon.ViewmodelName, _, _, Weapon.Skin, false, true);
				ViewModel_SetDefaultAnimation(client, "idle");
				ViewModel_SetAnimation(client, "draw");
			}
		}
	}
	
	ViewChange_Switch(client);
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

		bool found;
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
					Items_SetActiveWeapon(client, entity);
					SZF_DropItem(client);
					Items_ShowItemMenu(client);
					found = true;
					break;
				}
				break;
			}
		}
		delete list;

		if(found)
			return;
	}
	
	Items_SetEmptyWeapon(client);
}

bool Items_CanGiveItem(int client, int type, bool &full=false)
{
	int maxall = Classes_GetMaxItems(client, 0);
	int maxtypes = Classes_GetMaxItems(client, type);
	int i, entity, all, types;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i)) != -1)
	{
		all++;
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			continue;

		if(weapon.OnItem != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnItem);
			Call_PushCell(client);
			Call_PushCell(0);
			Call_PushCellRef(maxall);
			Call_Finish();
		}

		if(type<1 || type>=ITEMS_MAX)
			continue;

		if(weapon.OnItem != INVALID_FUNCTION)
		{
			Call_StartFunction(null, weapon.OnItem);
			Call_PushCell(client);
			Call_PushCell(type);
			Call_PushCellRef(maxtypes);
			Call_Finish();
		}

		if(weapon.Type != type)
			continue;

		types++;
	}

	if(all >= maxall)
	{
		full = true;
		return false;
	}

	if(types >= maxtypes)
	{
		full = false;
		return false;
	}
	return true;
}

bool Items_DropItem(int client, int helditem, const float origin[3], const float angles[3], bool swap = true, int dropType = ItemDrop_Drop)
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
	int type = GetEntProp(helditem, Prop_Send, "m_iPrimaryAmmoType");
	if(swap)
	{
		if(type != -1)
		{
			ammo = GetAmmo(client, type);
			int clip = GetEntProp(helditem, Prop_Data, "m_iClip1");
			int max = Classes_GetMaxAmmo(client, type);
			Items_Ammo(client, type, max);

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

			if(swap)
				Items_ShowItemMenu(client);

			if(weapon.Skin >= 0)
			{
				SetVariantInt(weapon.Skin);
				AcceptEntityInput(entity, "Skin");
				// the keycard uses this alt method because skins can't be overwriten when attached to a player
				SetEntityMaterialData(entity, weapon.Skin);
			}

			// throw the item, if specified
			float vel[3];
			
			switch(dropType)
			{
				case ItemDrop_Throw:	// throw in the direction the player is looking at
				{
					// check if we're too close to a wall
					float posFinal[3];
					TR_TraceRayFilter(origin, angles, MASK_SOLID, RayType_Infinite, Trace_WorldAndBrushes);
					TR_GetEndPosition(posFinal);
					
					// if we are too close, weaken the throw
					float distance = GetVectorDistance(origin, posFinal, false);
					
					if (distance > 200.0)
						distance = 200.0
					
					Items_GrenadeTrajectory(angles, vel, (distance * 1.5));	// just reuse this, I guess
				}
				
				case ItemDrop_Scatter:	// throw in a random-ish direction
				{
					vel[0] = float(GetRandomInt(-100, 100));
					vel[1] = float(GetRandomInt(-100, 100));
					vel[2] = float(GetRandomInt(25, 100));
				}
			}

			TeleportEntity(entity, origin, NULL_VECTOR, vel);
			result = true;
		}
	}

	if(type != -1)
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, type);

	return result;
}

void Items_DropAllItems(int client)
{
	Items_CancelDelayedAction(client);

	static float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);

	int i, entity;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		Items_DropItem(client, entity, pos, ang, false, ItemDrop_Scatter);
	}
}

void Items_PlayPickupReact(int client, int type, int index)
{
	float Time = GetGameTime();
	if (Client[client].NextPickupReactTime < Time)
	{		
		if ((index == ITEM_INDEX_MICROHID) || (index == ITEM_INDEX_SCP18))	
			Config_DoReaction(client, "item_veryrare");
		else if ((index == ITEM_INDEX_O5) || (type == ITEM_TYPE_WEAPON) || (type == ITEM_TYPE_GRENADE) || (type == ITEM_TYPE_SCP))		
			Config_DoReaction(client, "item_rare");
		else if (GetRandomInt(0, 1)) // 50% chance
			Config_DoReaction(client, "item_common");
	
		Client[client].NextPickupReactTime = Time + 5.0;
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
			Items_PlayPickupReact(client, weapon.Type, index);
			Items_CreateWeapon(client, index, true, newWep, newWep, entity);
			ClientCommand(client, "playgamesound AmmoPack.Touch");

			if(index == ITEM_INDEX_O5)
			{
				GiveAchievement(Achievement_FindO5, client);
			}
			else if(weapon.Type==ITEM_TYPE_WEAPON)
			{
				if (Classes_GetByName("dboi")==Client[client].Class)
				{
					GiveAchievement(Achievement_FindGun, client);
				}
			}

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

void Items_ShowItemMenu(int client)
{
	int max = Classes_GetMaxItems(client, 0);
	Items_Items(client, 0, max);

	Menu menu = new Menu(Items_ShowItemMenuH);
	menu.SetTitle("Inventory            ");

	SetGlobalTransTarget(client);
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int fists = -1;
	int items;
	char buffer[64], num[16];
	ArrayList list = Items_ArrayList(client, _, true);
	int length = list.Length;
	WeaponEnum weapon;
	Weapons.GetArray(0, weapon);
	int fistsIndex = weapon.Index;
	for(int i; i<length; i++)
	{
		int entity = list.Get(i);
		int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(Items_GetWeaponByIndex(index, weapon))
		{
			if(weapon.OnItem != INVALID_FUNCTION)
			{
				Call_StartFunction(null, weapon.OnItem);
				Call_PushCell(client);
				Call_PushCell(0);
				Call_PushCellRef(max);
				Call_Finish();
			}

			if(weapon.Hidden)
			{
				max--;
				continue;
			}

			if(index == fistsIndex && fists == -1)
			{
				fists = entity;
				continue;
			}

			IntToString(EntIndexToEntRef(entity), num, sizeof(num));
			FormatEx(buffer, sizeof(buffer), "%t", weapon.Display);
			menu.AddItem(num, buffer, active==entity ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}
		else
		{
			IntToString(EntIndexToEntRef(entity), num, sizeof(num));
			FormatEx(buffer, sizeof(buffer), "%t", "weapon_0");
			menu.AddItem(num, buffer, active==entity ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		items++;
	}
	delete list;

	if(max > 1)
	{
		SetEntProp(client, Prop_Send, "m_bWearingSuit", false);

		if(fists != -1)
			max--;

		for(; items<max; items++)
		{
			menu.AddItem("-1", ""); 
		}

		if(fists != -1)
		{
			for(; items<9; items++)
			{
				menu.AddItem("-1", "", ITEMDRAW_SPACER);
			}

			Weapons.GetArray(0, weapon);
			IntToString(EntIndexToEntRef(fists), num, sizeof(num));
			FormatEx(buffer, sizeof(buffer), "%t", weapon.Display);
			menu.AddItem(num, buffer, active==fists ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		menu.Pagination = false;
		menu.OptionFlags |= MENUFLAG_NO_SOUND;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		delete menu;
		SetEntProp(client, Prop_Send, "m_bWearingSuit", true);
	}
}

public int Items_ShowItemMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(IsPlayerAlive(client))
			{
				char buffer[16];
				menu.GetItem(choice, buffer, sizeof(buffer));

				int entity = StringToInt(buffer);
				if(entity == -1)
				{
					int i;
					WeaponEnum weapon;
					Weapons.GetArray(0, weapon);
					while((entity=Items_Iterator(client, i, true)) != -1)
					{
						if(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex") == weapon.Index)
						{
							Items_SetActiveWeapon(client, entity);
							SZF_DropItem(client);
							break;
						}
					}
				}
				else
				{
					entity = EntRefToEntIndex(entity);
					if(entity > MaxClients)
					{
						Items_SetActiveWeapon(client, entity);
						SZF_DropItem(client);
					}
				}

				Items_ShowItemMenu(client);
				ClientCommand(client, "playgamesound common/wpn_moveselect.wav");
			}
		}
	}
	return 0;
}

bool Items_IsHoldingWeapon(int client)
{
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(entity>MaxClients && IsValidEntity(entity) && HasEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
	{
		WeaponEnum weapon;
		
		int index = Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon);
		if(!index)
			return true;
			
		if ((weapon.Type == ITEM_TYPE_WEAPON) || (weapon.Type == ITEM_TYPE_GRENADE))
			return true;	

		// HACK: there's currently a bug where map-spawned items can "attack"
		// this is a temporary fix until the real cause is found
		if ((weapon.Type == ITEM_TYPE_KEYCARD) || (weapon.Type == ITEM_TYPE_MEDICAL))
			return false;		

		// HACK: I'm afraid of breaking something, these weapons don't have types assigned in the config
		if ((index == ITEM_INDEX_MICROHID) || (index == ITEM_INDEX_DISARMER) || (index == ITEM_INDEX_SCP18))
			return true;
			
		if (weapon.Attack && !weapon.Hide)
			return true;		
	}
	return false;
}

bool Items_WasHoldingWeaponRecently(int client)
{
	return (Client[client].LastWeaponTime + 15.0) > GetGameTime(); 
}

bool Items_IsKeycard(int entity)
{
	WeaponEnum weapon;
	return (Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) && (weapon.Type == ITEM_TYPE_KEYCARD));
}

bool Items_IsHoldingKeycard(int client)
{
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (entity>MaxClients && IsValidEntity(entity))
		return Items_IsKeycard(entity);

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

void Items_Ammo(int client, int type, int &ammo)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnAmmo==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnAmmo);
		Call_PushCell(client);
		Call_PushCell(type);
		Call_PushCellRef(ammo);
		Call_Finish();
	}
}

void Items_Items(int client, int type, int &amount)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnItem==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnItem);
		Call_PushCell(client);
		Call_PushCell(type);
		Call_PushCellRef(amount);
		Call_Finish();
	}
}

void Items_Speed(int client, float &speed)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnSpeed==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnSpeed);
		Call_PushCell(client);
		Call_PushFloatRef(speed);
		Call_Finish();
	}
}

void Items_Sprint(int client, float &drain)
{
	int i, entity;
	WeaponEnum weapon;
	while((entity=Items_Iterator(client, i, true)) != -1)
	{
		if(!Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) || weapon.OnSprint==INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, weapon.OnSprint);
		Call_PushCell(client);
		Call_PushFloatRef(drain);
		Call_Finish();
	}
}

int Items_GetTranName(int index, char[] buffer, int length)
{
	WeaponEnum weapon;
	if(Items_GetWeaponByIndex(index, weapon))
		return strcopy(buffer, length, weapon.Display);

	return strcopy(buffer, length, "weapon_0");
}

int Items_GetItemsOfType(int client, int type)
{
	int count;
	int max = GetMaxWeapons(client);
	WeaponEnum weapon;
	for(int i; i<max; i++)
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(entity<=MaxClients || !IsValidEntity(entity))
			continue;

		if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon) && weapon.Type==type)
			count++;
	}
	return count;
}

void RemoveAndSwitchItem(int client, int weapon)
{
	Items_SwitchItem(client, weapon);
	TF2_RemoveItem(client, weapon);
	Items_ShowItemMenu(client);
}

static void SpawnPlayerPickup(int client, const char[] classname, bool timed=false, bool instant=false)
{
	int entity = CreateEntityByName(classname);
	if(entity > MaxClients)
	{
		static float pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 20.0;
		DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");

		if (instant)
		{
			// spawn invisible so it doesn't appear for a frame
			DispatchKeyValue(entity, "rendermode", "10");
		}

		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

		if(timed)
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

static int GetMaxWeapons(int client)
{
	static int max;
	if(!max)
		max = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");

	return max;
}

public bool Items_NoneDrop(int client, int weapon, bool &swap)
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

public bool Items_RadioDrop(int client, int weapon, bool &swap)
{
	if(swap)
		Items_SwitchItem(client, weapon);

	swap = false;
	return true;
}

public bool Items_ArmorDrop(int client, int weapon, bool &swap)
{
	int ammo[AMMO_MAX];
	Classes_GetMaxAmmoList(client, ammo);

	for(int i; i<AMMO_MAX; i++)
	{
		if(ammo[i] && GetEntProp(client, Prop_Data, "m_iAmmo", _, i)>ammo[i])
		{
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo[i], _, i);
		}
	}
	return true;
}

public Action Items_DisarmerHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapo, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsSCP(victim) && !IsFriendly(Client[victim].Class, Client[client].Class))
	{
		bool cancel;
		if(!Client[victim].Disarmer)
		{
			cancel = Items_IsHoldingWeapon(victim);
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

				SZF_DropItem(victim);
				Items_DropAllItems(victim);
				for(int i; i<AMMO_MAX; i++)
				{
					SetEntProp(victim, Prop_Data, "m_iAmmo", 0, _, i);
				}
				Items_SetEmptyWeapon(victim);

				ClassEnum class;
				if(Classes_GetByIndex(Client[victim].Class, class) && class.Group==2 && !class.Vip)
					GiveAchievement(Achievement_DisarmMTF, client);

				// all weapons are gone, so reset the time		
				Client[victim].LastWeaponTime = 0.0;

				CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
				Client[victim].Disarmer = client;
				SDKCall_SetSpeed(victim);
			}
		}

		if(!cancel)
		{
			//Client[victim].Disarmer = client;
			//SDKCall_SetSpeed(victim);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action Items_HeadshotHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(GetEntProp(victim, Prop_Data, "m_LastHitGroup") != HITGROUP_HEAD ||
	  (IsSCP(victim) && Client[victim].Class!=Classes_GetByName("scp0492")))
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

public void Items_LogicerSpeed(int client, float &speed)
{
	speed *= 0.91;
}

public void Items_LogicerSprint(int client, float &drain)
{
	drain *= 1.24;
}

public void Items_ChaosSpeed(int client, float &speed)
{
	speed *= 0.99;
}

public void Items_ChaosSprint(int client, float &drain)
{
	drain *= 1.02;
}

public void Items_ExplosiveHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	ClientCommand(victim, "dsp_player %d", GetRandomInt(32, 34));
}

public Action Items_FlashHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	FadeMessage(victim, 36, 768, 0x0012, 200, 200, 200, 200);
	ClientCommand(victim, "dsp_player %d", GetRandomInt(35, 37));
	return Plugin_Continue;
}

public void Items_BuilderCreate(int client, int entity)
{
	for(int i; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", i!=3, _, i);
	}
}

static const char MicroChargeSound[] = "weapons/stickybomblauncher_charge_up.wav";

public bool Items_MicroButton(int client, int weapon, int &buttons, int &holding)
{
	int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int ammo = GetAmmo(client, type);
	static float charge[MAXTF2PLAYERS];
	if(ammo<2 || !(buttons & IN_ATTACK))
	{
		if (charge[client])
			StopSound(client, SNDCHAN_AUTO, MicroChargeSound);
			
		charge[client] = 0.0;
		TF2Attrib_SetByDefIndex(weapon, 821, 1.0);
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 99.0);
		return false;
	}

	buttons &= ~IN_JUMP|IN_SPEED;

	if(charge[client])
	{
		float engineTime = GetGameTime();
		if(charge[client] == FAR_FUTURE)
		{
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		}
		else if(charge[client] < engineTime)
		{
			charge[client] = FAR_FUTURE;
			TF2Attrib_SetByDefIndex(weapon, 821, 0.0);
		}
		else
		{
			TF2Attrib_SetByDefIndex(weapon, 821, 1.0);
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", (charge[client]-engineTime)*16.5);

			static float time[MAXTF2PLAYERS];
			if(time[client] < engineTime)
			{
				time[client] = engineTime+0.45;
				if(type != -1)
					SetEntProp(client, Prop_Data, "m_iAmmo", ammo-1, _, type);
			}
		}
	}
	else
	{
		charge[client] = GetGameTime()+6.0;
		EmitSoundToAll2(MicroChargeSound, client, SNDCHAN_AUTO, SNDLEVEL_CAR, _, _, 67);
	}
	return true;
}

public Action Items_GrenadeAction(Handle timer, int client)
{
	// if we finish successfully or cancel early, we still need to remove the weapon
	// active weapon should still be the grenade here
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(weapon))
	{
		RemoveAndSwitchItem(client, weapon);
	}

	return Plugin_Stop;
}

public void Items_GrenadeTrajectory(const float angles[3], float velocity[3], float scale)
{
	velocity[0] = Cosine(DegToRad(angles[0])) * Cosine(DegToRad(angles[1])) * scale;
	velocity[1] = Cosine(DegToRad(angles[0])) * Sine(DegToRad(angles[1])) * scale;
	velocity[2] = Sine(DegToRad(angles[0])) * -scale;
}

public bool Items_FragButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && !Items_InDelayedAction(client))
	{
		bool short = view_as<bool>(buttons & IN_ATTACK2);
		if(short || (buttons & IN_ATTACK))
		{
			holding = short ? IN_ATTACK2 : IN_ATTACK;

			// remove after a delay so the viewmodel throw animation can play out
			Items_StartDelayedAction(client, 0.3, Items_GrenadeAction, client);

			ViewModel_SetAnimation(client, "use");
			Config_DoReaction(client, "throwgrenade");			

			int entity = CreateEntityByName("prop_physics_multiplayer");
			if(IsValidEntity(entity))
			{
				DispatchKeyValue(entity, "physicsmode", "2");

				static float ang[3], pos[3], vel[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				GetClientEyeAngles(client, ang);
				pos[2] += 63.0;

				Items_GrenadeTrajectory(ang, vel, 1200.0);

				if(short)
					ScaleVector(vel, 0.5);

				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntProp(entity, Prop_Data, "m_iHammerID", Client[client].Class);			

				// shouldn't be hardcoded!!
				SetEntityModel(entity, "models/scp_fixed/frag/w_frag.mdl");

				DispatchSpawn(entity);
				TeleportEntity(entity, pos, ang, vel);

				CreateTimer(5.0, Items_FragTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return false;
}

bool Items_FragTrace(int entity)
{
	// things like static props do go through, ignore them
	if (!IsValidEntity(entity))
		return true;
	
	char buffer[10];
	if (GetEntityClassname(entity, buffer, sizeof(buffer))) 
	{
		if (!strncmp(buffer, "func_door", 9, false))
			DestroyOrOpenDoor(entity);
	}
	
	return true;
}

public Action Items_FragTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity > MaxClients)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		int flags = (SF_ENVEXPLOSION_REPEATABLE|SF_ENVEXPLOSION_NODECAL|SF_ENVEXPLOSION_NOSOUND|SF_ENVEXPLOSION_RND_ORIENT|SF_ENVEXPLOSION_NOFIREBALLSMOKE|SF_ENVEXPLOSION_NOPARTICLES);
		int explosion = CreateExplosion(client, 500, 350, pos, flags, "taunt_soldier", false);
		
		if (IsValidEntity(explosion))
		{
			AttachParticle(explosion, "asplode_hoodoo", false, 5.0);
			EmitGameSoundToAll("Weapon_Airstrike.Explosion", explosion);
			
			// pass the original class of the thrower
			SetEntProp(explosion, Prop_Data, "m_iHammerID", GetEntProp(entity, Prop_Data, "m_iHammerID"));	
			
			// find any doors nearby and try destroy or force them open
			TR_EnumerateEntitiesSphere(pos, 350.0, PARTITION_SOLID_EDICTS, Items_FragTrace);
			
			AcceptEntityInput(explosion, "Explode");
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

public void Items_FragHook(const char[] output, int caller, int activator, float delay)
{
	if(activator > 0 && activator <= MaxClients)
		ClientCommand(activator, "dsp_player %d", GetRandomInt(32, 34));
}

public bool Items_FlashButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && !Items_InDelayedAction(client))
	{
		bool short = view_as<bool>(buttons & IN_ATTACK2);
		if(short || (buttons & IN_ATTACK))
		{
			holding = short ? IN_ATTACK2 : IN_ATTACK;

			// remove after a delay so the viewmodel throw animation can play out
			Items_StartDelayedAction(client, 0.3, Items_GrenadeAction, client);

			ViewModel_SetAnimation(client, "use");
			Config_DoReaction(client, "throwgrenade");		

			int entity = CreateEntityByName("prop_physics_multiplayer");
			if(IsValidEntity(entity))
			{
				DispatchKeyValue(entity, "physicsmode", "2");

				static float ang[3], pos[3], vel[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				GetClientEyeAngles(client, ang);
				pos[2] += 63.0;

				Items_GrenadeTrajectory(ang, vel, 1200.0);

				if(short)
					ScaleVector(vel, 0.5);

				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntProp(entity, Prop_Data, "m_iHammerID", Client[client].Class);

				// shouldn't be hardcoded!!
				SetEntityModel(entity, "models/scp_fixed/flash/w_flash.mdl");

				DispatchSpawn(entity);
				TeleportEntity(entity, pos, ang, vel);

				CreateTimer(3.0, Items_FlashTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return false;
}

public Action Items_FlashTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity > MaxClients)
	{
		static float pos1[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos1);
		
		int flags = (SF_ENVEXPLOSION_NODAMAGE|SF_ENVEXPLOSION_REPEATABLE|SF_ENVEXPLOSION_NODECAL|SF_ENVEXPLOSION_NOSOUND|SF_ENVEXPLOSION_RND_ORIENT|SF_ENVEXPLOSION_NOFIREBALLSMOKE|SF_ENVEXPLOSION_NOPARTICLES);
		int explosion = CreateExplosion(_, _, _, pos1, flags, _, false);
		
		if (IsValidEntity(explosion))
		{
			AttachParticle(explosion, "drg_cow_explosioncore_normal_blue", false, 1.0);
			EmitGameSoundToAll("Weapon_Detonator.Detonate", explosion);
			
			// create a short light effect, clientside duration can increase slightly depending on ping
			int light = TF2_CreateLightEntity(1024.0, { 255, 255, 255, 255 }, 5, 0.1);
			if (light > MaxClients)
				TeleportEntity(light, pos1, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
			
			// pass the original class of the thrower
			SetEntProp(explosion, Prop_Data, "m_iHammerID", GetEntProp(entity, Prop_Data, "m_iHammerID"));	
			
			AcceptEntityInput(explosion, "Explode");
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
		}

		int class = GetEntProp(entity, Prop_Data, "m_iHammerID");
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFriendly(class, Client[i].Class) && !IsSpec(i))
			{
				static float pos2[3];
				GetClientEyePosition(i, pos2);
				
				// check if we're not hitting a wall
				TR_TraceRayFilter(pos1, pos2, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);
				
				// 512 units
				if(GetVectorDistance(pos1, pos2, true) < 524288.0 && !TR_DidHit())
				{
					FadeMessage(i, 1000, 1000, 0x0001, 200, 200, 200, 255);
					ClientCommand(i, "dsp_player %d", GetRandomInt(35, 37));
				}
			}
		}

		RemoveEntity(entity);
	}
	return Plugin_Continue;
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

		ApplyHealEvent(client, 6);

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

public Action Items_HealthKitAction(Handle timer, int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(weapon))
	{
		if (!Items_IsDelayedActionCancelled(client))
		{
			// player will instantly pick this up
			RemoveAndSwitchItem(client, weapon);
			SpawnPlayerPickup(client, "item_healthkit_medium", true, true);
		}
		else 
		{
			// revert to idle animation
			ViewModel_SetAnimation(client, "idle");
			// allow movement again
			TF2_RemoveCondition(client, TFCond_Dazed);
		}
	}

	return Plugin_Continue;
}

public bool Items_HealthKitButton(int client, int weapon, int &buttons, int &holding)
{
	bool canHeal = 	GetClientHealth(client) < Classes_GetMaxHealth(client);
	if(!holding && ((buttons & IN_ATTACK) || (buttons & IN_ATTACK2)))
	{
		holding = (buttons & IN_ATTACK) ? IN_ATTACK : IN_ATTACK2;

		if (canHeal && !Items_InDelayedAction(client))
		{
			// begin delayed action, the heal will be finished at the end of the action unless it gets cancelled early
			Items_StartDelayedAction(client, 2.5, Items_HealthKitAction, client);
			ViewModel_SetAnimation(client, "use");
			// don't allow movement
			TF2_StunPlayer(client, 2.5, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
		}
		else 
		{
			EmitSoundToClient(client, "common/wpn_denyselect.wav");
		}
	}
	else if (!canHeal || (!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2)))
	{
		// cancel healing as holding was stopped or we can't be healed anymore (player could have been healed externally)
		Items_CancelDelayedAction(client);
	}

	return false;
}

public bool Items_AdrenalineButton(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;
		RemoveAndSwitchItem(client, weapon);
		TF2_AddCondition(client, TFCond_DefenseBuffed, 20.0, client);
		Client[client].Extra3 = GetGameTime()+20.0;
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

		if(GetClientHealth(client) < 26)
			GiveAchievement(Achievement_Survive500, client);

		SpawnPlayerPickup(client, "item_healthkit_full", true);
		StartHealingTimer(client, 0.334, 1, 36, true);
		Client[client].Extra2 = 0;
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
			ApplyHealEvent(client, health);
		}

		if(Client[client].Extra2 < 4)
		{
			StartHealingTimer(client, 2.5, -1, 250, _, true);
			Client[client].Extra2++;
		}
	}
	return false;
}

static float SCP268Delay[MAXTF2PLAYERS];

public Action Items_268Action(Handle timer, int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(weapon))
	{
		if (!Items_IsDelayedActionCancelled(client))
		{
			RemoveAndSwitchItem(client, weapon);
			
			SCP268Delay[client] = GetGameTime() + 90.0;
			TF2_AddCondition(client, TFCond_Stealthed, 15.0);
			ClientCommand(client, "playgamesound misc/halloween/spell_stealth.wav");
		}
		else 
		{
			ViewModel_SetAnimation(client, "idle");
		}
	}

	return Plugin_Continue;
}

public bool Items_268Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && (buttons & IN_ATTACK))
	{
		holding = IN_ATTACK;

		if (!Items_InDelayedAction(client))
		{
			float engineTime = GetGameTime();
			if(SCP268Delay[client] > engineTime)
			{
				ClientCommand(client, "playgamesound items/medshotno1.wav");
				PrintCenterText(client, "%T", "in_cooldown", client);
				return false;
			}
			
			Items_StartDelayedAction(client, 1.5, Items_268Action, client);
			ViewModel_SetAnimation(client, "use");			
		}
	}
	else if (!(buttons & IN_ATTACK))
	{
		Items_CancelDelayedAction(client);
	}
	
	return false;
}

public bool Items_RadioRadio(int client, int entity, float &multi)
{
	static float time[MAXTF2PLAYERS];
	bool remove, off;
	float engineTime = GetGameTime();
	switch(GetEntProp(entity, Prop_Data, "m_iClip1"))
	{
		case 1:
		{
			multi = 2.6;
			if(time[client]+60.0 < engineTime)
				remove = true;
		}
		case 2:
		{
			multi = 3.5;
			if(time[client]+30.0 < engineTime)
				remove = true;
		}
		case 3:
		{
			multi = 5.7;
			if(time[client]+12.5 < engineTime)
				remove = true;
		}
		case 4:
		{
			multi = 10.8;
			if(time[client]+5.0 < engineTime)
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

public void Items_LightAmmo(int client, int type, int &ammo)
{
	if(ammo == 2)	// 9mm
		ammo *= 2;
}

public void Items_LightItem(int client, int type, int &amount)
{
	if(type == ITEM_TYPE_WEAPON)
		amount++;
}

public void Items_CombatAmmo(int client, int type, int &ammo)
{
	switch(type)
	{
		case 2:	// 9mm
		{
			ammo *= 4;
		}
		case 6, 7:	// 7mm, 5mm
		{
			ammo *= 3;
		}
		case 10:	// 4mag
		{
			ammo = RoundFloat(ammo * 2.666667);
		}
		case 11:	// 12ga
		{
			ammo = RoundFloat(ammo * 3.857143);
		}
	}
}

public void Items_CombatItem(int client, int type, int &amount)
{
	switch(type)
	{
		case 1:	// Weapons
			amount++;

		case 7:	// Grenades
			amount++;
	}
}

public void Items_CombatSprint(int client, float &drain)
{
	drain *= 1.1;
}

public void Items_HeavyAmmo(int client, int type, int &ammo)
{
	switch(type)
	{
		case 2:	// 9mm
		{
			ammo = RoundFloat(ammo * 6.666667);
		}
		case 6, 7:	// 7mm, 5mm
		{
			ammo *= 5;
		}
		case 10:	// 4mag
		{
			ammo *= RoundFloat(ammo * 3.777778);
		}
		case 11:	// 12ga
		{
			ammo = RoundFloat(ammo * 5.285714);
		}
	}
}

public void Items_HeavyItem(int client, int type, int &amount)
{
	switch(type)
	{
		case 1:	// Weapons
			amount += 2;

		case 3:	// Medical
			amount++;

		case 7:	// Grenades
			amount++;
	}
}

public void Items_HeavySpeed(int client, float &speed)
{
	speed *= 0.95;
}

public void Items_HeavySprint(int client, float &drain)
{
	drain *= 1.2;
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

public void Items_StartDelayedAction(int client, float length, Timer func, any data)
{
	Item_DelayedAction[client] = CreateTimer(length, func, data, TIMER_FLAG_NO_MAPCHANGE);
}

public void Items_CancelDelayedAction(int client)
{
	Handle timer = Item_DelayedAction[client];

	if (timer != INVALID_HANDLE)
	{
		// null handle will indicate to the func that it got cancelled, as normally it should still be here
		Item_DelayedAction[client] = INVALID_HANDLE;
		TriggerTimer(timer, false);
	}
}

public bool Items_InDelayedAction(int client)
{
	return (Item_DelayedAction[client] != INVALID_HANDLE);
}

public bool Items_IsDelayedActionCancelled(int client)
{
	return (Item_DelayedAction[client] == INVALID_HANDLE);
}

public void Items_ClearDelayedActions()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		Handle timer = Item_DelayedAction[client];
		if (timer != INVALID_HANDLE)
		{
			Item_DelayedAction[client] = INVALID_HANDLE;
			KillTimer(timer);
		}
	}
}

public bool Items_DisarmerButton(int client, int weapon, int &buttons, int &holding)
{
	static int previousTarget[MAXTF2PLAYERS];
	static float DisarmerCharge[MAXTF2PLAYERS];

	if(!(buttons & IN_ATTACK2))
	{
		previousTarget[client] = -1;
		DisarmerCharge[client] = 0.0;
		return false;
	}
	
	int target = TraceClientViewEntity(client);
	
	if(!IsValidClient(target) || !IsPlayerAlive(target))
	{
		previousTarget[client] = -1;
		DisarmerCharge[client] = 0.0;
		return false;
	}
	
	float targetPos[3], clientPos[3];
	GetClientAbsOrigin(target, targetPos);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
	
	float distance = GetVectorDistance(targetPos, clientPos);
	
	if(distance > 150.0)
	{
		previousTarget[client] = -1;
		DisarmerCharge[client] = 0.0;
		return false;
	}
	
	bool cancel;
	cancel = Items_IsHoldingWeapon(target);
	
	if(cancel)
	{
		previousTarget[client] = -1;
		DisarmerCharge[client] = 0.0;
		return false;
	}
	
	if(previousTarget[client] != target)
	{
		DisarmerCharge[client] = 0.0;
		previousTarget[client] = target;
	}
	
	float engineTime = GetGameTime();
	static float delay[MAXTF2PLAYERS];

	bool isTargetTeammate = IsFriendly(Client[target].Class, Client[client].Class);
	bool canDisarm = Client[target].Disarmer == 0 && !isTargetTeammate;

	// Only allow the disarmer and disarmed player's team to undisarm (to prevent griefing and accidents)
	bool canUndisarm = Client[target].Disarmer > 0 && (client == Client[target].Disarmer || isTargetTeammate);
	
	if((canDisarm || canUndisarm) && delay[client] < engineTime)
	{
		delay[client] = engineTime + 0.1;
		DisarmerCharge[client] += 10.0;
		
		SetHudTextParamsEx(-1.0, 0.6, 0.35, Client[client].Colors, Client[client].Colors, 0, 1.0, 0.01, 0.5);
		if(canDisarm)
		{
			ShowSyncHudText(client, HudPlayer, "%t", "disarming_other", target, DisarmerCharge[client]);
			ShowSyncHudText(target, HudPlayer, "%t", "disarming_me", client, DisarmerCharge[client]);
		}
		else if (canUndisarm)
		{
			ShowSyncHudText(client, HudPlayer, "%t", "arming_other", target, DisarmerCharge[client]);
			ShowSyncHudText(target, HudPlayer, "%t", "arming_me", client, DisarmerCharge[client]);
		}
	
		if(DisarmerCharge[client] >= 100.0)
		{
			if(canDisarm)
			{
				TF2_AddCondition(target, TFCond_PasstimePenaltyDebuff);
				BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", target));
				if(bf)
				{
					char buffer[64];
					FormatEx(buffer, sizeof(buffer), "%T", "disarmed", client);
					bf.WriteString(buffer);
					bf.WriteString("ico_notify_flag_moving_alt");
					bf.WriteByte(view_as<int>(TFTeam_Red));
					EndMessage();
				}
				
				SZF_DropItem(target);
				Items_DropAllItems(target);
				for(int i; i<AMMO_MAX; i++)
				{
					SetEntProp(target, Prop_Data, "m_iAmmo", 0, _, i);
				}
				Items_SetEmptyWeapon(target);
				
				ClassEnum class;
				if(Classes_GetByIndex(Client[target].Class, class) && class.Group==2 && !class.Vip)
					GiveAchievement(Achievement_DisarmMTF, client);
				
				// all weapons are gone, so reset the time		
				Client[target].LastWeaponTime = 0.0;
				
				CreateTimer(1.0, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
				Client[target].Disarmer = client;
				SDKCall_SetSpeed(target);
			}
			else if (canUndisarm)
			{
				TF2_RemoveCondition(target, TFCond_PasstimePenaltyDebuff);
				Client[target].Disarmer = 0;
			}
			
			DisarmerCharge[client] = 0.0;
			previousTarget[client] = -1;
			delay[client] = engineTime + 1.0;
			
			return false;
		}
	}
	
	return true;
}