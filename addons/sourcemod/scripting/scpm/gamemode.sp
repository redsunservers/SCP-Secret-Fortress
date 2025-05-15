#pragma semicolon 1
#pragma newdecls required

/*
	TODO: SCP-914 upgrade access tier

	Coarse: (Highest stat turns into an item)

	Rough: (Decreases highest stat)
	- (SCP 3 or Armory 3) Exit 1 -> 2

	1:1: (Switches SCP and Armory, SCP always stays at 1)

	Fine:
	- (SCP 1) Exit 0 -> 1
	- (SCP 1) SCP 1 -> 2
	- (Armory 1) Armory 1 -> 2
	- (SCP 3 or Armory 3) Exit 1 -> 2
	- (SCP 2) SCP 2 -> 3
	- (Armory 2) Armory 2 -> 3
	- (SCP 3) Armory 0 -> 1

	Very Fine: (Whichever stat has more, otherwise 50/50)
	- (SCP 1) SCP 1 -> 2
	- (SCP 2) SCP 2 -> 3
	- (Armory 1) Armory 1 -> 2
	- (Armory 2) Armory 2 -> 3
*/

enum
{
	Access_Unknown = -1,
	Access_Main = 0,
	Access_Armory,
	Access_Exit,
	Access_Warhead,
	Access_Checkpoint,
	Access_Intercom
}

static Handle SyncHud;
static Handle BlinkTimer;

void Gamemode_PluginStart()
{
	SyncHud = CreateHudSynchronizer();

	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);

	// Reload support
	if(FindEntityByClassname(-1, "tf_gamerules") != -1)
		RequestFrame(Gamemode_RoundRespawn);
}

void Gamemode_RoundRespawn()
{
	RoundStartTime = GetGameTime();

	int count;
	int[] players = new int[MaxClients];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			Client(client).ResetByRound();

			if(GetClientTeam(client) > TFTeam_Spectator)
			{
				Bosses_Remove(client, false);
				players[count++] = client;
			}

			ClearSyncHud(client, SyncHud);
		}
	}
	
	if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		for(int i; i < count; i++)
		{
			SetEntProp(players[i], Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(players[i], TFTeam_Humans);
			SetEntProp(players[i], Prop_Send, "m_lifeState", 0);
		}
	}

	Gamemode_CheckAlivePlayers(_, false, true);

	delete BlinkTimer;
	BlinkTimer = CreateTimer(0.1, GlobalBlinkTimer);
	NextBlinkAt = GetGameTime() + 0.1;
}

void Gamemode_RoundEnd(int winteam)
{
	delete BlinkTimer;
}

Action Gamemode_WinPanel(Event event)
{
	event.SetInt("flagcaplimit", PlayersAlive[TFTeam_Humans]);
	event.SetBool("round_complete", false);
	return Plugin_Changed;
}

static Action GlobalBlinkTimer(Handle timer)
{
	// 10s, every min -0.48s
	float time = 9.5 + GetURandomFloat() - ((GetGameTime() - RoundStartTime) * 0.008);
	if(time < 3.0)
		time = 3.0;
	
	BlinkTimer = CreateTimer(time, GlobalBlinkTimer);
	NextBlinkAt = GetGameTime() + time;

	int numHumans;
	int[] humans = new int[MaxClients];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == TFTeam_Humans && IsPlayerAlive(client))
			humans[numHumans++] = client;
	}
	
	BfWrite bf = view_as<BfWrite>(StartMessage("Fade", humans, numHumans));
	bf.WriteShort(100);	// Duration (0.1s)
	bf.WriteShort(150);	// Fade In Time (0.15s)
	bf.WriteShort(FFADE_IN);
	bf.WriteByte(0);
	bf.WriteByte(0);
	bf.WriteByte(0);
	bf.WriteByte(255);
	EndMessage();
	delete bf;

	return Plugin_Continue;
}

// Call whenever to update PlayerAlive variables
void Gamemode_CheckAlivePlayers(int exclude = 0, bool alive = true, bool resetMax = false)
{
	bool stall;

	for(int i; i < TFTeam_MAX; i++)
	{
		PlayersAlive[i] = 0;
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i != exclude && IsClientInGame(i))
		{
			int team = GetClientTeam(i);
			if((!alive && team > TFTeam_Spectator) || IsPlayerAlive(i))
			{
				PlayersAlive[team]++;

				if(team == TFTeam_Humans && !Client(i).Escaped)
					stall = true;
			}
		}
	}
	
	for(int i; i < TFTeam_MAX; i++)
	{
		if(resetMax || MaxPlayersAlive[i] < PlayersAlive[i])
			MaxPlayersAlive[i] = PlayersAlive[i];
	}

	if(alive && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		// Stall is a boss is alive (or singleplayer)
		if(!stall && (!PlayersAlive[TFTeam_Bosses] || MaxPlayersAlive[TFTeam_Bosses]))
		{
			int winner = TFTeam_Unassigned;
			int reason = WINREASON_STALEMATE;

			if(PlayersAlive[TFTeam_Humans])
			{
				winner = TFTeam_Humans;
				reason =  PlayersAlive[TFTeam_Bosses] ? WINREASON_FLAG_CAPTURE_LIMIT : WINREASON_OPPONENTS_DEAD;
			}
			else if(PlayersAlive[TFTeam_Bosses])
			{
				winner = TFTeam_Bosses;
				reason = WINREASON_OPPONENTS_DEAD;
			}

			int entity = CreateEntityByName("game_round_win"); 
			DispatchKeyValue(entity, "force_map_reset", "1");
			DispatchKeyValueInt(entity, "win_reason", reason);
			SetEntProp(entity, Prop_Data, "m_iTeamNum", winner);
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "RoundWin");
		}
	}
}

bool Gamemode_PlayerRunCmd(int client, int &buttons, int &impulse)
{
	bool changed;
	
	static bool holding[MAXPLAYERS+1];
	if(buttons & (IN_USE|IN_RELOAD))
	{
		if(!(buttons & IN_USE))
		{
			buttons |= IN_USE;
			changed = true;
		}
		
		// Interact Key
		if(!holding[client])
		{
			holding[client] = true;
			TF2_RemoveCondition(client, TFCond_Stealthed);

			int entity = GetClientPointVisible(client);

			Action action;
			if(Bosses_StartFunctionClient(client, "Interact"))
			{
				Call_PushCell(client);
				Call_PushCell(entity);
				Call_Finish(action);
			}

			if(action < Plugin_Handled)
				Gamemode_Interact(client, entity);

			if(!Client(client).IsBoss && !Client(client).Minion)
				Human_Interact(client, entity);
		}
	}
	else if(holding[client])
	{
		holding[client] = false;
	}

	switch(impulse)
	{
		case 100:	// Flashlight
		{
			impulse = 0;
			changed = true;
		}
		/*case 201, 202:	// Spray
		{
			if()
			{
				impulse = 0;
				changed = true;
			}
		}*/
	}

	return changed;
}

void Gamemode_Interact(int client, int entity)
{
	if(entity == -1)
		return;
	
	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
		}
	}
	else if(!StrContains(buffer, "prop_dynamic") || !StrContains(buffer, "prop_physics"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			AcceptEntityInput(entity, GetClientTeam(client) == TFTeam_Humans ? "FireUser2" : "FireUser1", client, client);
		}
	}
}

public Action OnRelayTrigger(const char[] output, int entity, int client, float delay)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

	if(!StrContains(name, "scp_access", false))
	{
		int type = StringToInt(name[11]);
		switch(type)
		{
			case Access_Main:
			{
				switch(Client(client).KeycardContain)
				{
					case 0:
						AcceptEntityInput(entity, "FireUser4", client, client);
					
					case 1:
						AcceptEntityInput(entity, "FireUser1", client, client);

					case 2:
						AcceptEntityInput(entity, "FireUser2", client, client);

					default:
						AcceptEntityInput(entity, "FireUser3", client, client);
				}
			}
			case Access_Armory:
			{
				switch(Client(client).KeycardArmory)
				{
					case 0:
						AcceptEntityInput(entity, "FireUser4", client, client);
					
					case 1:
						AcceptEntityInput(entity, "FireUser1", client, client);

					case 2:
						AcceptEntityInput(entity, "FireUser2", client, client);

					default:
						AcceptEntityInput(entity, "FireUser3", client, client);
				}
			}
			case Access_Exit:
			{
				AcceptEntityInput(entity, Client(client).KeycardExit > 1 ? "FireUser1" : "FireUser4", client, client);
			}
			case Access_Warhead:
			{
				AcceptEntityInput(entity, Client(client).KeycardContain > 2 ? "FireUser1" : "FireUser4", client, client);
			}
			case Access_Checkpoint:
			{
				AcceptEntityInput(entity, Client(client).KeycardExit > 0 ? "FireUser1" : "FireUser4", client, client);
			}
			case Access_Intercom:
			{
				AcceptEntityInput(entity, (Client(client).KeycardContain > 2 || Client(client).KeycardArmory > 2) ? "FireUser1" : "FireUser4", client, client);
			}
		}
	}
	/*
	else if(!StrContains(name, "scp_removecard", false))
	{
		if(IsValidClient(client))
		{
			int ent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(ent > MaxClients)
			{
				if(Items_IsHoldingKeycard(ent))
				{
					Items_SwitchItem(client, ent);
					TF2_RemoveItem(client, ent);
					return Plugin_Continue;
				}
			}

			int i;
			while((ent=Items_Iterator(client, i, true)) != -1)
			{
				if(Items_IsKeycard(ent))
					TF2_RemoveItem(client, ent);
			}
		}
	}
	else if(!StrContains(name, "scp_startmusic", false))
	{
		NoMusicRound = false;
		for(int target=1; target<=MaxClients; target++)
		{
			Client[target].NextSongAt = 0.0;
		}
	}
	else if(!StrContains(name, "scp_endmusic", false))
	{
		NoMusicRound = true;
		ChangeGlobalSong(FAR_FUTURE, "");
	}
	else if(!StrContains(name, "scp_respawn", false))	// Temp backwards compability
	{
		if(IsValidClient(client))
		{
			if(Enabled && TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
				GiveAchievement(Achievement_SurvivePocket, client);

			Classes_SpawnPoint(client, Classes_GetByName("scp106"));
		}
	}
	else if(!StrContains(name, "scp_escapepocket", false))
	{
		if(Enabled && IsValidClient(client))
			GiveAchievement(Achievement_SurvivePocket, client);
	}
	else if(!StrContains(name, "scp_floor", false))
	{
		if(IsValidClient(client))
		{
			int floor = StringToInt(name[10]);
			if(floor != Client[client].Floor)
			{
				Client[client].NextSongAt = 0.0;
				Client[client].Floor = floor;
			}
		}
	}
	else if(!StrContains(name, "scp_femur", false))
	{
		ClassEnum class;
		int index = Classes_GetByName("scp106", class);
		int found;
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && index==Client[target].Class)
			{
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
				found = target;
			}
		}

		index = Classes_GetByName("pootisred", class);
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && index==Client[target].Class)
			{
				SDKHooks_TakeDamage(target, target, target, 9001.0, DMG_NERVEGAS);
				found = target;
			}
		}

		index = class.Group;
		if(Enabled && found)
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && 
				   Classes_GetByIndex(Client[target].Class, class) &&
				   class.Group >= 0 &&
				   class.Group != index)
					GiveAchievement(Achievement_Kill106, target);
			}
		}
	}
	else if(!StrContains(name, "scp_upgrade", false))
	{
		if(Enabled && IsValidClient(client))
		{
			int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(index>MaxClients && IsValidEntity(index))
				index = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");

			char buffer[64];
			Items_GetTranName(index, buffer, sizeof(buffer));

			SetGlobalTransTarget(client);
			if(Client[client].Cooldown > GetGameTime())
			{
				Menu menu = new Menu(Handler_None);
				menu.SetTitle("%t\n ", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "in_cooldown");
				menu.AddItem("", buffer);

				menu.Display(client, 3);
			}
			else
			{
				Menu menu = new Menu(Handler_Upgrade);
				menu.SetTitle("%t\n ", buffer);

				WeaponEnum weapon;
				Items_GetWeaponByIndex(index, weapon);

				FormatEx(buffer, sizeof(buffer), "%t", "914_very");
				menu.AddItem("", buffer, weapon.VeryFine[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_fine");
				menu.AddItem("", buffer, weapon.Fine[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_onetoone");
				menu.AddItem("", buffer, weapon.OneToOne[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_coarse");
				menu.AddItem("", buffer, weapon.Coarse[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				FormatEx(buffer, sizeof(buffer), "%t", "914_rough");
				menu.AddItem("", buffer, weapon.Rough[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

				menu.Display(client, 10);
			}
		}
	}
	else if(!StrContains(name, "scp_printer", false))
	{
		if(Enabled && IsValidClient(client))
		{
			int index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(index>MaxClients && IsValidEntity(index))
				index = GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex");

			char buffer[64];
			Items_GetTranName(index, buffer, sizeof(buffer));

			SetGlobalTransTarget(client);
			if(Client[client].Cooldown > GetGameTime())
			{
				Menu menu = new Menu(Handler_None);
				menu.SetTitle("%t\n ", buffer);

				FormatEx(buffer, sizeof(buffer), "%t", "in_cooldown");
				menu.AddItem("", buffer);

				menu.Display(client, 3);
			}
			else
			{

				WeaponEnum weapon;
				if(Items_GetWeaponByIndex(index, weapon) && weapon.Type==ITEM_TYPE_KEYCARD)
				{
					Menu menu = new Menu(Handler_Printer);
					menu.SetTitle("%t\n ", buffer);

					FormatEx(buffer, sizeof(buffer), "%t", "914_copy");
					menu.AddItem("", buffer);

					menu.Display(client, 6);
				}
				else
				{
					Menu menu = new Menu(Handler_None);
					menu.SetTitle("%t\n ", buffer);

					FormatEx(buffer, sizeof(buffer), "%t", "914_nowork");
					menu.AddItem("", buffer);

					menu.Display(client, 3);
				}
			}
		}
	}
	else if(!StrContains(name, "scp_intercom", false))
	{
		if(Enabled && IsValidClient(client))
		{
			Client[client].ComFor = GetGameTime()+15.0;
			GiveAchievement(Achievement_Intercom, client);
		}
	}
	else if(!StrContains(name, "scp_nukecancel", false))
	{
		if(Enabled && IsValidClient(client))
			GiveAchievement(Achievement_SurviveCancel, client);
	}
	else if(!StrContains(name, "scp_nuke", false))
	{
		if(Enabled)
			GiveAchievement(Achievement_SurviveWarhead, 0);
	}
	else if(!StrContains(name, "scp_giveitem_", false))
	{
		if(IsValidClient(client))
		{
			char buffers[4][6];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));
			Items_CreateWeapon(client, StringToInt(buffers[2]), _, true, true);
		}
	}
	else if(!StrContains(name, "scp_removeitem_", false))
	{
		if(IsValidClient(client))
		{
			char buffers[4][6];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));

			int index = StringToInt(buffers[2]);
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

			int i, ent;
			while((ent=Items_Iterator(client, i, true)) != -1)
			{
				if(GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == index)
				{
					TF2_RemoveItem(client, ent);
					AcceptEntityInput(entity, "FireUser1", client, client);
					if(ent == active)
						Items_SwitchItem(client, ent);
				}
			}
		}
	}
	else if(!StrContains(name, "scp_insertitem_", false))
	{
		if(IsValidClient(client))
		{
			char buffers[4][6];
			ExplodeString(name, "_", buffers, sizeof(buffers), sizeof(buffers[]));

			int index = StringToInt(buffers[2]);
			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if(GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") == index)
			{
				TF2_RemoveItem(client, active);
				AcceptEntityInput(entity, "FireUser1", client, client);
				Items_SwitchItem(client, active);
			}
			else
			{
				AcceptEntityInput(entity, "FireUser2", client, client);
			}
		}
	}
	*/

	return Plugin_Continue;
}