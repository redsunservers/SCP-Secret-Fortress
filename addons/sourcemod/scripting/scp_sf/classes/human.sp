#pragma semicolon 1
#pragma newdecls required

static float NextHudIn[MAXPLAYERS+1];
static bool MaxSprintCached[MAXPLAYERS+1];
static int MaxSprintLevel[MAXPLAYERS+1];
static float SprintEnergy[MAXPLAYERS+1];
static bool WasSprintting[MAXPLAYERS+1];
static float LastRunCmdTime[MAXPLAYERS+1];
static Handle SprintHud;

public void Human_OnPrecache()
{
	if(!SprintHud)
		SprintHud = CreateHudSynchronizer();
}

public void Human_OnSetClass(int client)
{
	NextHudIn[client] = 0.0;
	MaxSprintCached[client] = false;
	SprintEnergy[client] = 0.0;
	WasSprintting[client] = false;
	LastRunCmdTime[client] = GetGameTime();
}

public bool Human_OnClientCommand(int client, const char[] command)
{
	if(!IsPlayerAlive(client))
		return false;
	
	if(StrEqual(command, "dropitem"))	// Drop their active item
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(entity != -1 && Items_DropItem(client, entity, false))
		{
			if(!Items_SwapInSlot(client))
			{
				entity = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				if(entity != -1)
					Items_SwapToItem(client, entity);
			}

			MaxSprintCached[client] = false;
			return true;
		}
	}
	else if(StrEqual(command, "+inspect_server"))	// Swap between items
	{
		Items_SwapInSlot(client);
		return true;
	}
	else if(StrEqual(command, "+use_action_slot_item"))	// Interact with an entity
	{
		int entity = GetClientPointVisible(client);
		if(entity > MaxClients)
		{
			char buffer[64];
			GetEntityClassname(entity, buffer, sizeof(buffer));
			if(StrEqual(buffer, "func_button"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if(!StrContains(buffer, "scp_trigger", false))
				{
					AcceptEntityInput(entity, "Press", client, client);
					return true;
				}
			}
			else if(!StrContains(buffer, "prop_dynamic") || !StrContains(buffer, "prop_physics"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if(!StrContains(buffer, "scp_trigger", false))
				{
					switch(GetClientTeam(client))
					{
						case 2:
							AcceptEntityInput(entity, "FireUser2", client, client);

						case 3:
							AcceptEntityInput(entity, "FireUser3", client, client);

						default:
							AcceptEntityInput(entity, "FireUser1", client, client);
					}

					return true;
				}
				
				int index = -1;
				if(!StrContains(buffer, "scp_keycard_", false))
				{
					index = StringToInt(buffer[12]) + 30000;
				}
				else if(!StrContains(buffer, "scp_healthkit", false))
				{
					index = StringToInt(buffer[14]);

					if(index > 3)
					{
						index = 30017;
					}
					else
					{
						index += 30012;
					}
				}
				else if(!StrContains(buffer, "scp_weapon", false))
				{
					index = StringToInt(buffer[12]);
					
					if(!index)
						index = 773;
				}
				else if(!StrContains(buffer, "scp_item_", false) || !StrContains(buffer, "scp_rand_", false))
				{
					index = StringToInt(buffer[10]);
				}

				if(index != -1)
				{
					Items_AttemptPickup(client, index);
					MaxSprintCached[client] = false;
					return true;
				}
			}
			else if(StrEqual(buffer, "tf_dropped_weapon"))
			{
				Items_AttemptPickup(client, GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), entity);
				MaxSprintCached[client] = false;
				return true;
			}
		}
	}

	return false;
}

public void Human_OnUpdateSpeed(int client, float &speed)
{
	if(WasSprintting[client])
		speed *= 1.3;
}

public Action Human_OnPlayerRunCmd(int client, int &buttons)
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(!MaxSprintCached[client])
	{
		MaxSprintCached[client] = true;
		MaxSprintLevel[client] = 9;

		WeaponEnum weapon;

		int entity, i;
		while(TF2_GetItem(client, entity, i))
		{
			if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
				MaxSprintLevel[client] -= weapon.Weight;
		}

		if(MaxSprintLevel[client] < 0)
		{
			MaxSprintLevel[client] = 0;
		}
		else if(MaxSprintLevel[client] > 9)
		{
			MaxSprintLevel[client] = 9;
		}
	}

	float gameTime = GetGameTime();
	bool ground = view_as<bool>(GetEntityFlags(client) & FL_ONGROUND);

	if(ground && (buttons & IN_ATTACK3))
	{
		if(SprintEnergy[client] > 11.0 && !WasSprintting[client])
		{
			WasSprintting[client] = true;
			Classes_UpdateSpeed(client);
			ClientCommand(client, "playgamesound player/suit_sprint.wav");
		}
		
		if(WasSprintting[client])
		{
			// Drain rate of 10/s (10 sec of sprinting)
			SprintEnergy[client] -= (gameTime - LastRunCmdTime[client]) * 10.0;

			if(SprintEnergy[client] < 0.0)
			{
				WasSprintting[client] = false;
				Classes_UpdateSpeed(client);
			}
		}
	}
	else if(WasSprintting[client])
	{
		WasSprintting[client] = false;
		Classes_UpdateSpeed(client);
	}
	else if(!ground)
	{
		float maxEnergy = float(1 + MaxSprintLevel[client] * 11);
		if(SprintEnergy[client] < maxEnergy)
		{
			// Recover rate of 6.67/s (15 sec of recovery)
			SprintEnergy[client] += (gameTime - LastRunCmdTime[client]) * 6.666667;
		}

		if(SprintEnergy[client] > maxEnergy)
			SprintEnergy[client] = maxEnergy;
	}
	
	if(NextHudIn[client] < gameTime)
	{
		NextHudIn[client] = gameTime + 0.4;
		SetGlobalTransTarget(client);

		char interact[32];
		WeaponEnum weapon;

		int entity = GetClientPointVisible(client);
		if(entity > MaxClients)
		{
			GetEntityClassname(entity, weapon.Classname, sizeof(weapon.Classname));
			if(StrEqual(weapon.Classname, "func_button"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", weapon.Classname, sizeof(weapon.Classname));
				if(!StrContains(weapon.Classname, "scp_trigger", false))
				{
					strcopy(interact, sizeof(interact), "Interact");
				}
			}
			else if(!StrContains(weapon.Classname, "prop_dynamic") || !StrContains(weapon.Classname, "prop_physics"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", weapon.Classname, sizeof(weapon.Classname));
				if(!StrContains(weapon.Classname, "scp_trigger", false))
				{
					strcopy(interact, sizeof(interact), "Interact");
				}
				else
				{
					int index = -1;
					if(!StrContains(weapon.Classname, "scp_keycard_", false))
					{
						index = StringToInt(weapon.Classname[12]) + 30000;
					}
					else if(!StrContains(weapon.Classname, "scp_healthkit", false))
					{
						index = StringToInt(weapon.Classname[14]);

						if(index > 3)
						{
							index = 30017;
						}
						else
						{
							index += 30012;
						}
					}
					else if(!StrContains(weapon.Classname, "scp_weapon", false))
					{
						index = StringToInt(weapon.Classname[12]);
						
						if(!index)
							index = 773;
					}
					else if(!StrContains(weapon.Classname, "scp_item_", false) || !StrContains(weapon.Classname, "scp_rand_", false))
					{
						index = StringToInt(weapon.Classname[10]);
					}

					if(index != -1)
					{
						if(Items_CanPickupItem(client, index))
						{
							strcopy(interact, sizeof(interact), "Pick Up Item");
						}
						else if(Items_CanAttractAmmo(client, index))
						{
							strcopy(interact, sizeof(interact), "Take Ammunition");
						}
					}
				}
			}
			else if(StrEqual(weapon.Classname, "tf_dropped_weapon"))
			{
				int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

				if(Items_CanPickupItem(client, index))
				{
					strcopy(interact, sizeof(interact), "Pick Up Item");
				}
				else if(Items_CanAttractAmmo(client, index))
				{
					strcopy(interact, sizeof(interact), "Take Ammunition");
				}
			}
		}

		entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(entity != -1)
			Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon);
		
		if(MaxSprintLevel[client] > 0)
		{
			Format(weapon.Viewmodel, sizeof(weapon.Viewmodel), "%%+attack3%% %t", "Sprint");
		}
		else
		{
			weapon.Viewmodel[0] = 0;
		}

		if(weapon.DisplayAttack[0])
			Format(weapon.Viewmodel, sizeof(weapon.Viewmodel), "%s %%+attack%% %t", weapon.Viewmodel, weapon.DisplayAttack);

		if(weapon.DisplayAltfire[0])
			Format(weapon.Viewmodel, sizeof(weapon.Viewmodel), "%s %%+attack2%% %t", weapon.Viewmodel, weapon.DisplayAltfire);

		if(weapon.DisplayReload[0])
			Format(weapon.Viewmodel, sizeof(weapon.Viewmodel), "%s %%+reload%% %t", weapon.Viewmodel, weapon.DisplayReload);

		if(entity != -1 && Items_HasMultiInSlot(client, TF2Util_GetWeaponSlot(entity)))
			Format(weapon.Viewmodel, sizeof(weapon.Viewmodel), "%s %%+inspect%% %t", weapon.Viewmodel, "Switch Items");

		if(interact[0])
			Format(weapon.Viewmodel, sizeof(weapon.Viewmodel), "%s %%+use_action_slot_item%% %t", weapon.Viewmodel, interact);
		
		PrintKeyHintText(client, weapon.Viewmodel);


		if(SprintHud && MaxSprintLevel[client] > 0)
		{
			interact[0] = 0;
			for(int i = 9; i > 0; i--)
			{
				if(i != 9 && (i % 3) == 0)
				{
					Format(interact, sizeof(interact), "%s \n", interact);
				}
				
				if(i >= MaxSprintLevel[client])
				{
					float highest = float((i * 11) + 1);
					if(SprintEnergy[client] > highest)
					{
						Format(interact, sizeof(interact), "%s" ... CHAR_FULL, interact);
					}
					else if(SprintEnergy[client] > (highest - 3.667))
					{
						Format(interact, sizeof(interact), "%s" ... CHAR_PARTFULL, interact);
					}
					else if(SprintEnergy[client] > (highest - 7.333))
					{
						Format(interact, sizeof(interact), "%s" ... CHAR_PARTEMPTY, interact);
					}
					else
					{
						Format(interact, sizeof(interact), "%s" ... CHAR_EMPTY, interact);
					}
				}
			}

			SetHudTextParams(0.175, 0.925, 0.9, 255, 255, 255, 255);
			ShowSyncHudText(client, SprintHud, interact);
		}
	}

	LastRunCmdTime[client] = gameTime;
	return Plugin_Continue;
}