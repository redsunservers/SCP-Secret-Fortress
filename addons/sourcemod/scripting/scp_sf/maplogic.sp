#pragma semicolon 1
#pragma newdecls required

static float UpgradeCooldown[MAXPLAYERS+1];
static float PrinterCooldown[MAXPLAYERS+1];
static float MenuUntil[MAXPLAYERS+1];
static int MenuType[MAXPLAYERS+1];
static Handle MenuTimer[MAXPLAYERS+1];
static ArrayList ScriptList;

void MapLogic_PluginStart()
{
	HookEntityOutput("logic_relay", "OnTrigger", LogicRelayTrigger);
}

void MapLogic_AllPluginsLoaded()
{
	SetupVScript();
}

void MapLogic_MapStart()
{
	int length = ScriptList.Length;
	for(int i; i < length; i++)
	{
		VScriptFunction func = ScriptList.Get(i);
		func.Register();
	}

	for(int i; i < sizeof(UpgradeCooldown); i++)
	{
		UpgradeCooldown[i] = 0.0;
		PrinterCooldown[i] = 0.0;
		MenuUntil[i] = 0.0;
	}
}

void MapLogic_RunScript(int entity, const char[] funcname, int activator = -1, int caller = -1)
{
	SetVariantString(funcname);
	AcceptEntityInput(entity, "RunScriptCode", activator, caller);
}

int MapLogic_GetPlayerAccess(int client, int type)
{
	int level = Items_CardAccess(client, type);
	Classes_CardAccess(client, type, level);
	return level;
}

static Action LogicRelayTrigger(const char[] output, int entity, int client, float delay)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

	if(!StrContains(name, "scp_access", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			switch(MapLogic_GetPlayerAccess(client, StringToInt(name[11])))
			{
				case 1:
					AcceptEntityInput(entity, "FireUser1", client, client);

				case 2:
					AcceptEntityInput(entity, "FireUser2", client, client);

				case 3:
					AcceptEntityInput(entity, "FireUser3", client, client);

				default:
					AcceptEntityInput(entity, "FireUser4", client, client);
			}
		}
	}
	else if(!StrContains(name, "scp_removecard", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			WeaponEnum weapon;
			int length = GetMaxWeapons(client);
			for(int i; i < length; i++)
			{
				int other = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if(other != -1 &&
					Items_GetWeaponByIndex(GetEntProp(other, Prop_Send, "m_iItemDefinitionIndex"), weapon) &&
					weapon.ItemType == Type_Keycard)
				{
					bool active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == other;

					TF2_RemoveItem(client, other);

					if(active)
						Items_SwapToBest(client);

					break;
				}
			}
		}
	}
	else if(!StrContains(name, "scp_startmusic", false))
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			Music_PlayerSpawn(target);
		}
		
		Music_SetMusicStatus(true);
	}
	else if(!StrContains(name, "scp_stopmusic", false))
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			Music_StopMusic(target);
		}
		
		Music_SetMusicStatus(false);
	}
	else if(!StrContains(name, "scp_respawn", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			//if(Enabled && TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
			//	GiveAchievement(Achievement_SurvivePocket, client);

			Classes_TeleportToPoint(client, "scp_spawn_106");
		}
	}
	else if(!StrContains(name, "scp_escapepocket", false))
	{
		//if(Enabled && IsValidClient(client))
		//	GiveAchievement(Achievement_SurvivePocket, client);
	}
	else if(!StrContains(name, "scp_floor", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			int floor = StringToInt(name[10]);
			if(Client(client).CurrentFloor != floor)
			{
				Client(client).CurrentFloor = floor;
				Music_StopMusic(client);
				Music_PlayerSpawn(client);
			}
		}
	}
	else if(!StrContains(name, "scp_femur", false))
	{
		int index = Classes_GetByName("scp106");
		if(index != -1)
		{
			//bool found;
			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && Client(client).Class == index)
				{
					SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
					//found = true;
				}
			}
			
			//if(found && client > 0 && client <= MaxClients)
				//GiveAchievement(Achievement_Kill106, client);
		}
	}
	else if(!StrContains(name, "scp_upgrade", false))
	{
		if(client > 0 && client <= MaxClients)
			Start914Menu(client);
	}
	else if(!StrContains(name, "scp_printer", false))
	{
		if(client > 0 && client <= MaxClients)
			StartPrinterMenu(client);
	}
	else if(!StrContains(name, "scp_intercom", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			Client(client).GlobalChatFor = GetGameTime() + 15.0;
			//GiveAchievement(Achievement_Intercom, client);
		}
	}
	else if(!StrContains(name, "scp_nukecancel", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			//GiveAchievement(Achievement_SurviveCancel, client);
		}
	}
	else if(!StrContains(name, "scp_nuke", false))
	{
		//GiveAchievement(Achievement_SurviveWarhead, 0);
	}
	else if(!StrContains(name, "scp_giveitem_", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			Items_GiveItem(client, StringToInt(name[13]));
		}
	}
	else if(!StrContains(name, "scp_removeitem_", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			int index = StringToInt(name[15]);
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			int length = GetMaxWeapons(client);
			for(int i; i < length; i++)
			{
				int other = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if(GetEntProp(other, Prop_Send, "m_iItemDefinitionIndex") == index)
				{
					TF2_RemoveItem(client, other);
					AcceptEntityInput(entity, "FireUser1", client, client);

					if(other == active)
						Items_SwapToBest(client);
				}
			}
		}
	}
	else if(!StrContains(name, "scp_insertitem_", false))
	{
		if(client > 0 && client <= MaxClients)
		{
			int index = StringToInt(name[15]);
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			if(active != -1 && GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") == index)
			{
				TF2_RemoveItem(client, active);
				AcceptEntityInput(entity, "FireUser1", client, client);
				Items_SwapToBest(client);
			}
			else
			{
				AcceptEntityInput(entity, "FireUser2", client, client);
			}
		}
	}
	
	return Plugin_Continue;
}

static VScriptFunction AddGlobalFunction(const char[] name)
{
	VScriptFunction func = VScript_CreateGlobalFunction(name);
	ScriptList.Push(func);
	return func;
}

static void BindGlobalFunction(VScriptFunction vscript, DHookCallback dhook)
{
	vscript.SetFunctionEmpty();

	DynamicDetour detour = vscript.CreateDetour();
	detour.Enable(Hook_Post, dhook);
	delete detour;
}

static void SetupVScript()
{
	ScriptList = new ArrayList();

	VScriptFunction func = AddGlobalFunction("SCP_GetPlayerAccess");
	func.SetParam(1, FIELD_HSCRIPT);
	func.SetParam(2, FIELD_INTEGER);
	func.Return = FIELD_INTEGER;
	BindGlobalFunction(func, GetPlayerAccess);

	func = AddGlobalFunction("SCP_GetPlayerClass");
	func.SetParam(1, FIELD_HSCRIPT);
	func.Return = FIELD_CSTRING;
	BindGlobalFunction(func, GetPlayerClass);
}

static MRESReturn GetPlayerAccess(int entity, DHookReturn ret, DHookParam param)
{
	int client = VScript_HScriptToEntity(param.Get(1));
	if(client > 0 && client <= MaxClients)
	{
		ret.Value = MapLogic_GetPlayerAccess(client, param.Get(2));
		return MRES_Override;
	}

	LogVScriptError("Invalid client %d", client);
	return MRES_Ignored;
}

static MRESReturn GetPlayerClass(int entity, DHookReturn ret, DHookParam param)
{
	int client = VScript_HScriptToEntity(param.Get(1));
	if(client > 0 && client <= MaxClients)
	{
		ClassEnum class;
		Classes_GetByIndex(Client(client).Class, class);
		ret.SetString(class.Name);
		return MRES_Override;
	}
	
	LogVScriptError("Invalid client %d", client);
	return MRES_Ignored;
}

static void LogVScriptError(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);
	LogError("[Map] %s", buffer);
}

static void Start914Menu(int client)
{
	delete MenuTimer[client];
	MenuTimer[client] = CreateTimer(0.1, Timer914Menu, client, TIMER_REPEAT);
	MenuUntil[client] = GetGameTime() + 10.0;

	if(MenuType[client] > 0 && MenuType[client] != 1)
		CancelClientMenu(client);
}

static Action Timer914Menu(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		float gameTime = GetGameTime();
		if(MenuUntil[client] > gameTime)
		{
			WeaponEnum weapon;

			int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(entity != -1)
				Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon);
			
			SetGlobalTransTarget(client);

			Menu menu = new Menu(Menu914Menu);
			menu.SetTitle("%t\n ", "SCP-914");

			char buffer[32];

			if(UpgradeCooldown[client] > gameTime)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Cooling Down For", RoundToCeil(UpgradeCooldown[client] - gameTime));
				menu.AddItem(buffer, buffer, ITEMDRAW_DISABLED);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Very Fine");
				menu.AddItem(buffer, buffer, weapon.VeryFine[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "Fine");
				menu.AddItem(buffer, buffer, weapon.Fine[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "1 to 1");
				menu.AddItem(buffer, buffer, weapon.OneToOne[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "Coarse");
				menu.AddItem(buffer, buffer, weapon.Coarse[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "Rough");
				menu.AddItem(buffer, buffer, weapon.Rough[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}

			menu.OptionFlags |= MENUFLAG_NO_SOUND;
			if(menu.Display(client, 1))
				MenuType[client] = 1;
			
			return Plugin_Continue;
		}
		else if(MenuType[client])
		{
			CancelClientMenu(client);
		}
	}

	return Plugin_Stop;
}

static int Menu914Menu(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			MenuType[client] = 0;

			if(choice == MenuCancel_Exit)
				MenuUntil[client] = 0.0;
		}
		case MenuAction_Select:
		{
			if(IsPlayerAlive(client))
			{
				int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(entity != -1)
				{
					WeaponEnum weapon;
					int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					if(Items_GetWeaponByIndex(index, weapon))
					{
						int amount;
						char buffers[8][16];
						switch(choice)
						{
							case 0:
							{
								if(weapon.VeryFine[0])
									amount = ExplodeString(weapon.VeryFine, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 1:
							{
								if(weapon.Fine[0])
									amount = ExplodeString(weapon.Fine, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 2:
							{
								if(weapon.OneToOne[0])
									amount = ExplodeString(weapon.OneToOne, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 3:
							{
								if(weapon.Coarse[0])
									amount = ExplodeString(weapon.Coarse, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
							case 4:
							{
								if(weapon.Rough[0])
									amount = ExplodeString(weapon.Rough, ";", buffers, sizeof(buffers), sizeof(buffers[]));
							}
						}

						if(amount)
						{
							UpgradeCooldown[client] = GetGameTime() + 15.0;
							ClientCommand(client, "playgamesound ui/item_store_add_to_cart.wav");

							amount = StringToInt(buffers[GetURandomInt() % amount]);
							if(amount == -1)
							{
								// 50% to destory the item if using 1:1 or better
								if(choice > 2 || (GetURandomInt() % 2))
								{
									TF2_RemoveItem(client, entity);
									Items_SwapToBest(client);
								}
							}
							else
							{
								TF2_RemoveItem(client, entity);

								bool drop = !Items_CanPickupItem(client, amount);
								entity = Items_GiveItem(client, amount);

								// Drop the item if inventory is full
								if(drop && entity != -1)
									Items_DropItem(client, entity, false);
							}
						}
					}
				}
			}
		}
	}

	return 0;
}

static void StartPrinterMenu(int client)
{
	delete MenuTimer[client];
	MenuTimer[client] = CreateTimer(0.1, TimerPrinterMenu, client, TIMER_REPEAT);
	MenuUntil[client] = GetGameTime() + 10.0;

	if(MenuType[client] > 0 && MenuType[client] != 2)
		CancelClientMenu(client);
}

static Action TimerPrinterMenu(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		float gameTime = GetGameTime();
		if(MenuUntil[client] > gameTime)
		{
			WeaponEnum weapon;

			int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(entity != -1)
				Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon);
			
			SetGlobalTransTarget(client);

			Menu menu = new Menu(MenuPrinterMenu);
			menu.SetTitle("%t\n ", "Printer");

			char buffer[32];

			if(PrinterCooldown[client] > gameTime)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Cooling Down For", RoundToCeil(PrinterCooldown[client] - gameTime));
				menu.AddItem(buffer, buffer, ITEMDRAW_DISABLED);
			}
			else
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Copy Keycard");
				menu.AddItem(buffer, buffer, weapon.ItemType == Type_Keycard ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			}

			menu.OptionFlags |= MENUFLAG_NO_SOUND;
			if(menu.Display(client, 1))
				MenuType[client] = 2;
			
			return Plugin_Continue;
		}
		else if(MenuType[client])
		{
			CancelClientMenu(client);
		}
	}

	return Plugin_Stop;
}

static int MenuPrinterMenu(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			MenuType[client] = 0;

			if(choice == MenuCancel_Exit)
				MenuUntil[client] = 0.0;
		}
		case MenuAction_Select:
		{
			if(IsPlayerAlive(client))
			{
				int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
				if(entity != -1)
				{
					WeaponEnum weapon;
					int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
					if(Items_GetWeaponByIndex(index, weapon) && weapon.ItemType == Type_Keycard)
					{
						PrinterCooldown[client] = GetGameTime() + 30.0;
						ClientCommand(client, "playgamesound ui/item_store_add_to_cart.wav");

						bool drop = !Items_CanPickupItem(client, index);
						entity = Items_GiveItem(client, index);

						// Drop the item if inventory is full
						if(drop && entity != -1)
							Items_DropItem(client, entity, false);
					}
				}
			}
		}
	}

	return 0;
}