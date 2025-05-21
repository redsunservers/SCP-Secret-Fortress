#pragma semicolon 1
#pragma newdecls required

#define TALK_DISTANCE	650000.0	// 800 HU
#define LOOK_PITCH	45.0	// Pitch to be considered looking at a target
#define LOOK_YAW	60.0	// Yaw to be considered looking at a target

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
static Handle GlobalTimer;
static Cookie BossQueue;
static bool ListenerDefault;
static float NextBlinkAt;
static float MenuCooldownFor[MAXPLAYERS+1];
static float MenuDurationFor[MAXPLAYERS+1];
static int GlowEffectRef[MAXPLAYERS+1] = {-1, ...};
static Handle MenuTimer[MAXPLAYERS+1];

void Gamemode_PluginStart()
{
	SyncHud = CreateHudSynchronizer();
	BossQueue = new Cookie("scpm_queue", "SCP queue points", CookieAccess_Protected);
	GlobalTimer = CreateTimer(0.2, GlobalThinkTimer);

	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);

	RoundStartTime = GetGameTime();
}

void Gamemode_RoundRespawn()
{
	RoundStartTime = GetGameTime();

	int count;
	int[][] players = new int[MaxClients][2];
	for(int client = 1; client <= MaxClients; client++)
	{
		MenuCooldownFor[client] = 0.0;

		if(IsClientInGame(client))
		{
			Client(client).ResetByRound();

			if(GetClientTeam(client) > TFTeam_Spectator)
			{
				Bosses_Remove(client, false);
				players[count][0] = client;
				players[count][1] = IsFakeClient(client) ? 10 : BossQueue.GetInt(client);
				count++;
			}

			ClearSyncHud(client, SyncHud);
		}
	}
	
	if(!GameRules_GetProp("m_bInWaitingForPlayers", 1))
	{
		SortCustom2D(players, count, SortByQueuePoints);

		int base = Cvar[SCPCount].IntValue;
		int bosses = count / base;

		if(bosses == 0 && count > 2)
		{
			// Min of one boss at 3 player count
			bosses = 1;
		}
		else if((count % base) > GetRandomInt(0, base - 1))
		{
			// Bonus boss chance
			bosses++;
		}
		
		ArrayList list = Bosses_GetRandomList();
		if(list.Length < bosses)
			bosses = list.Length;

		for(int i; i < count; i++)
		{
			int client = players[i][0];

			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, i < bosses ? TFTeam_Bosses : TFTeam_Humans);
			SetEntProp(client, Prop_Send, "m_lifeState", 0);

			if(i < bosses)
			{
				if(!IsFakeClient(client))
					BossQueue.SetInt(client, 0);

				int index = list.Get(i);
				Bosses_Create(client, index);
			}
			else if(!IsFakeClient(client))
			{
				BossQueue.SetInt(client, players[i][1] + 10);
			}
		}

		delete list;

		Specials_PickNewRound();

		delete BlinkTimer;
		BlinkTimer = CreateTimer(0.1, GlobalBlinkTimer);
		NextBlinkAt = GetGameTime() + 0.1;
	}

	Gamemode_CheckAlivePlayers(_, false, true);
}

static int SortByQueuePoints(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
	if(elem1[1] > elem2[1])
		return -1;
	
	if(elem1[1] < elem2[1])
		return 1;
	
	return (elem1[0] > elem2[0]) ? 1 : -1;
}

void Gamemode_PlayerSpawn(int client)
{
	CreateTimer(2.0, ReapplyGlowEffect, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

void Gamemode_RoundEnd()
{
	delete BlinkTimer;
	
	char buffer[256];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(Client(client).EscapeTimeAt)
			{
				int sec = RoundFloat(RoundStartTime - Client(client).EscapeTimeAt);
				int min = sec / 60;
				sec = sec % 60;

				Format(buffer, sizeof(buffer), "%s\n%N (%d:%02d)%s", buffer, client, min, sec, IsPlayerAlive(client) ? "" : " ☠");
			}
		}
	}

	if(!buffer[0])
		strcopy(buffer, sizeof(buffer), "\n☠");

	SetHudTextParams(-1.0, 0.3, 19.0, 255, 255, 255, 255, 2, 0.1, 0.1);
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			SetGlobalTransTarget(client);
			ShowSyncHudText(client, SyncHud, "%t%s", "Stat Win Screen", PlayersAlive[TFTeam_Bosses], PlayersAlive[TFTeam_Humans], buffer);
		}
	}
}

void Gamemode_ClientDisconnect(int client)
{
	if(IsValidEntity(GlowEffectRef[client]))
		RemoveEntity(GlowEffectRef[client]);
	
	delete MenuTimer[client];
	MenuCooldownFor[client] = 0.0;
	GlowEffectRef[client] = -1;
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

	return Plugin_Continue;
}

stock float Gamemode_NextBlinkAt()
{
	return NextBlinkAt;
}

static Action GlobalThinkTimer(Handle timer)
{
	GlobalTimer = null;
	Gamemode_UpdateListeners();
	return Plugin_Continue;
}

void Gamemode_UpdateListeners()
{
	delete GlobalTimer;
	GlobalTimer = CreateTimer(0.2, GlobalThinkTimer);

	if(!RoundActive())
	{
		if(!ListenerDefault)
		{
			ListenerDefault = true;
			for(int a = 0; a <= MaxClients; a++)
			{
				Client(a).LookingAt(a, false);
				Client(a).CanTalkTo(a, true);
				Client(a).GlowingTo(a, false);
				Client(a).NoTransmitTo(a, false);

				for(int b = a + 1; b <= MaxClients; b++)
				{
					Client(a).LookingAt(b, false);
					Client(a).CanTalkTo(b, true);
					Client(a).GlowingTo(b, false);
					Client(a).NoTransmitTo(b, false);
					Client(b).LookingAt(a, false);
					Client(b).CanTalkTo(a, true);
					Client(b).GlowingTo(a, false);
					Client(b).NoTransmitTo(a, false);

					if(a && IsClientInGame(a) && IsClientInGame(b))
					{
						SetListenOverride(a, b, Listen_Default);
						SetListenOverride(b, a, Listen_Default);
					}
				}
			}
		}
		return;
	}

	ListenerDefault = false;
	static int valid[MAXPLAYERS+1], team[MAXPLAYERS+1], spec[MAXPLAYERS+1];
	static float pos[MAXPLAYERS+1][3], ang[MAXPLAYERS+1][3], range[MAXPLAYERS+1];
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
		{
			valid[client] = 0;
			continue;
		}

		GetClientEyePosition(client, pos[client]);

		if(!IsPlayerAlive(client))
		{
			valid[client] = 1;
			spec[client] = GetClientTeam(client) == TFTeam_Spectator ? 1 : 0;
			if(spec[client] && CheckCommandAccess(client, "sm_mute", ADMFLAG_CHAT))
				spec[client] = 2;
			
			continue;
		}

		valid[client] = 2;
		spec[client] = 0;
		team[client] = GetClientTeam(client);
		GetClientEyeAngles(client, ang[client]);

		ang[client][0] = FixAngle(ang[client][0]);
		ang[client][1] = FixAngle(ang[client][1]);

		int entity = GetEntPropEnt(client, Prop_Send, "m_PlayerFog.m_hCtrl");
		if(entity == -1 || !GetEntProp(entity, Prop_Send, "m_fog.enable") || GetEntPropFloat(entity, Prop_Send, "m_fog.maxdensity") < 0.99)
		{
			range[client] = 0.0;
		}
		else
		{
			range[client] = GetEntPropFloat(entity, Prop_Send, "m_fog.end");
			range[client] *= range[client];
		}
	}

	for(int a = 1; a <= MaxClients; a++)
	{
		if(!valid[a])
			continue;
		
		for(int b = a + 1; b <= MaxClients; b++)
		{
			if(!valid[b])
				continue;
			
			float distance = GetVectorDistance(pos[a], pos[b], true);

			for(int c; c < 2; c++)
			{
				int speaker = c ? b : a;
				int target = c ? a : b;

				bool failed;

				// Check for dead talk
				if(valid[speaker] < 2)
				{
					if(spec[speaker] != 2 && valid[target] > 1)
						failed = true;
				}

				// Global talk
				else if(Client(speaker).AllTalkTimeFor > GetGameTime())
				{

				}

				// Bosses can always hear other bosses
				else if(!Client(target).IsBoss && !spec[speaker])
				{
					if(Client(speaker).SilentTalk)
						failed = true;
					
					if(distance > TALK_DISTANCE)
					{
						// If both players have a radio, can hear at any range
						if(Client(speaker).ActionItem != Radio_Index() || Client(target).ActionItem != Radio_Index())
							failed = true;
					}
				}
				
				Client(speaker).CanTalkTo(target, !failed);
				SetListenOverride(target, speaker, failed ? Listen_No : Listen_Yes);

				// Either are dead, don't do LOS checks
				if(valid[speaker] < 2 || valid[target] < 2)
				{
					Client(speaker).GlowingTo(target, false);
					continue;
				}
				
				// Fog distance
				failed = (range[speaker] && range[speaker] < distance);

				// Invis
				if(TF2_IsPlayerInCondition(target, TFCond_Stealthed) ||
				   TF2_IsPlayerInCondition(target, TFCond_StealthedUserBuffFade) ||
				   TF2_IsPlayerInCondition(target, TFCond_Cloaked))
					failed = true;
				
				// Glow Logic
				if(!failed)
				{
					bool glow;

					// Insanity
					if(TF2_IsPlayerInCondition(speaker, TFCond_MarkedForDeath))
					{
						glow = true;
					}
					else if(Bosses_StartFunctionClient(speaker, "GlowTarget"))
					{
						Call_PushCell(speaker);
						Call_PushCell(target);
						Call_Finish(glow);
					}

					Client(speaker).GlowingTo(target, glow);
				}

				if(!failed)
				{
					// "Looking" at our target
					static float vec[3];
					GetVectorAnglesTwoPoints(pos[speaker], pos[target], vec);
					vec[0] = FixAngle(vec[0]);
					vec[1] = FixAngle(vec[1]);

					float diff = FAbs(ang[speaker][0] - vec[0]);
					float min = LOOK_PITCH * Humans_GetAwareness(speaker);
					if(diff > min && diff < (360.0 - min))
						failed = true;
					
					if(!failed)
					{
						diff = FAbs(ang[speaker][1] - vec[1]);
						min = LOOK_YAW * Humans_GetAwareness(speaker);
						if(diff > min && diff < (360.0 - min))
							failed = true;
						
						//PrintCenterText(speaker, "%f %f [0] %f [1] %f [%d]", vec[0], vec[1], FAbs(ang[speaker][0] - vec[0]), FAbs(ang[speaker][1] - vec[1]), failed ? 0 : 1);
						
						if(!failed)
						{
							TR_TraceRayFilter(pos[speaker], pos[target], CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MIST, RayType_EndPoint, Trace_WorldAndBrushes);
							TR_GetEndPosition(vec);
							if(pos[target][0] != vec[0] || pos[target][1] != vec[1] || pos[target][2] != vec[2])
								failed = true;
						}
					}
					/*else
					{
						PrintCenterText(speaker, "%f %f [0] %f [1] %f [0]", vec[0], vec[1], FAbs(ang[speaker][0] - vec[0]), FAbs(ang[speaker][1] - vec[1]));
					}*/
				}
				
				Client(speaker).LookingAt(target, !failed);
				if(!failed)
				{
					//PrintToConsole(speaker, "DEBUG: Looking at %N", target);

					if(team[speaker] != team[target])
					{
						if(Client(target).IsBoss)
						{
							Music_StartChase(speaker, target);
						}
						else if(Client(speaker).IsBoss)
						{
							Music_StartChase(speaker, speaker);
						}
					}
				}
			}
		}
	}
}

// Call whenever to update PlayerAlive variables
void Gamemode_CheckAlivePlayers(int exclude = 0, bool alive = true, bool resetMax = false)
{
	bool stall, vip;

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
				if(!Client(i).NoEscape)
					PlayersAlive[team]++;

				if(!Client(i).NoEscape && team == TFTeam_Humans)
				{
					vip = true;
					if(!Client(i).Escaped)
						stall = true;
				}
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

			if(vip)
			{
				winner = TFTeam_Humans;
				reason = PlayersAlive[TFTeam_Bosses] ? WINREASON_FLAG_CAPTURE_LIMIT : WINREASON_OPPONENTS_DEAD;
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

static Action OnRelayTrigger(const char[] output, int entity, int client, float delay)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

	if(!StrContains(name, "scp_", false))
	{
		for(int other = 1; other <= MaxClients; other++)
		{
			if(IsClientInGame(other) && IsPlayerAlive(other) && Bosses_StartFunctionClient(other, "RelayTrigger"))
			{
				Call_PushCell(other);
				Call_PushString(name);
				Call_PushCell(entity);
				Call_PushCell(client);
				Call_Finish();
			}
		}
	
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
		else if(!StrContains(name, "scp_removecard", false))
		{
			if(client > 0 && client <= MaxClients)
			{
				Client(client).KeycardContain = 0;
				Client(client).KeycardArmory = 0;
				Client(client).KeycardExit = 0;
			}
		}
		else if(!StrContains(name, "scp_startmusic", false))
		{
			Music_ToggleRoundMusic(true);

			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target))
					Music_ToggleMusic(target, true, false);
			}
		}
		else if(!StrContains(name, "scp_endmusic", false))
		{
			Music_ToggleRoundMusic(false);

			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target))
					Music_ToggleMusic(target, false, true);
			}
		}
		else if(!StrContains(name, "scp_respawn", false))
		{
			if(client > 0 && client <= MaxClients)
			{
				//if(Enabled && TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
				//	GiveAchievement(Achievement_SurvivePocket, client);

				if(!GoToNamedSpawn(client, "scp_spawn_106"))
				{
					if(!GoToNamedSpawn(client, "scp_spawn_p"))
						TF2_RespawnPlayer(client);
				}
			}
		}
		else if(!StrContains(name, "scp_escapepocket", false))
		{
			//if(Enabled && IsValidClient(client))
			//	GiveAchievement(Achievement_SurvivePocket, client);
		}
		/*
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
		*/
		else if(!StrContains(name, "scp_upgrade", false))
		{
			if(client > 0 && client <= MaxClients && !Client(client).IsBoss && !Client(client).Minion)
			{
				MenuDurationFor[client] = GetGameTime() + (30.0 - Human_GetStressPercent(client) * 0.25);
				UpgradeMenu(client);
			}
		}
		/*
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
		*/
		else if(!StrContains(name, "scp_intercom", false))
		{
			if(client > 0 && client <= MaxClients)
			{
				float duration = StringToFloat(name[13]);
				if(duration < 1.0)
					duration = 15.0;
				
				Client(client).AllTalkTimeFor = GetGameTime() + duration;
				//GiveAchievement(Achievement_Intercom, client);
			}
		}
		/*
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
		*/
		else if(!StrContains(name, "scp_giveitem_", false))
		{
			if(client > 0 && client <= MaxClients)
			{
				Items_GiveByIndex(client, StringToInt(name[13]));
			}
		}
		else if(!StrContains(name, "scp_removeitem_", false))
		{
			if(client > 0 && client <= MaxClients)
			{
				int index = StringToInt(name[15]);
				int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

				int i, ent;
				while(TF2_GetItem(client, ent, i))
				{
					if(GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == index)
					{
						TF2_RemoveItem(client, ent);
						AcceptEntityInput(entity, "FireUser1", client, client);

						if(ent == active)
						{
							int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
							if(melee != -1)
								TF2U_SetPlayerActiveWeapon(client, melee);
						}
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
				
				if(GetEntProp(active, Prop_Send, "m_iItemDefinitionIndex") == index)
				{
					TF2_RemoveItem(client, active);
					AcceptEntityInput(entity, "FireUser1", client, client);
					
					int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
					if(melee != -1)
						TF2U_SetPlayerActiveWeapon(client, melee);
				}
				else
				{
					AcceptEntityInput(entity, "FireUser2", client, client);
				}
			}
		}
	}

	return Plugin_Continue;
}

static Action CooldownMenuTimer(Handle timer, int client)
{
	MenuTimer[client] = null;
	bool active = MenuCooldownFor[client] > GetGameTime();

	if(!active && MenuDurationFor[client] > GetGameTime())
	{
		UpgradeMenu(client, _, true);
		return Plugin_Continue;
	}

	Menu menu = new Menu(CooldownMenuH);

	menu.SetTitle("%T", "In Menu Cooldown", client, MenuCooldownFor[client] - GetGameTime());
	menu.AddItem(NULL_STRING, NULL_STRING, ITEMDRAW_SPACER);
	menu.Display(client, 1);

	if(active)
		MenuTimer[client] = CreateTimer(0.1, CooldownMenuTimer, client);

	return Plugin_Continue;
}

static int CooldownMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			delete MenuTimer[client];
		}
	}
	return 0;
}

static bool CheckMenuCooldown(int client)
{
	if(MenuCooldownFor[client] < GetGameTime())
		return false;
	
	if(!MenuTimer[client])
		MenuTimer[client] = CreateTimer(0.1, CooldownMenuTimer, client);
	
	return true;
}

static void UpgradeMenu(int client, int slot = -1, bool force = false)
{
	if(!force && GetClientMenu(client) != MenuSource_None)
		return;

	if(CheckMenuCooldown(client))
		return;

	if(MenuDurationFor[client] < GetGameTime())
		return;
	
	char num[16], buffer[64];
	SetGlobalTransTarget(client);

	Menu menu = new Menu(UpgradeMenuH);

	switch(slot)
	{
		case -1:
		{
			menu.SetTitle("%t\n ", "SCP-914");

			// 1, 2, 3 Wepaons
			for(int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Melee; i++)
			{
				int entity = GetPlayerWeaponSlot(client, i);
				if(entity == -1)
				{
					menu.AddItem("-1", NULL_STRING, ITEMDRAW_DISABLED);
					continue;
				}

				int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
				TF2Econ_GetLocalizedItemName(index, buffer, sizeof(buffer));
				menu.AddItem("-1", buffer);
			}

			// 4 Keycard
			if(Client(client).KeycardContain)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "Keycard");
				menu.AddItem("-1", buffer, ITEMDRAW_DEFAULT);
			}
			else
			{
				menu.AddItem("-1", NULL_STRING, ITEMDRAW_DISABLED);
			}

			menu.AddItem("-1", NULL_STRING, ITEMDRAW_DISABLED);

			// 6 Myself
			if(Human_GetStressPercent(client) > 60.0)
			{
				FormatEx(buffer, sizeof(buffer), "%t", "My Body");
				menu.AddItem("-1", buffer, ITEMDRAW_DEFAULT);
			}
			else
			{
				menu.AddItem("-1", NULL_STRING, ITEMDRAW_DISABLED);
			}
		}
		case 3:	// Keycard
		{
			if(Client(client).KeycardContain)
			{
				menu.SetTitle("%t", "Keycard");

				FormatEx(buffer, sizeof(buffer), "Very Fine");
				menu.AddItem("4", buffer);

				FormatEx(buffer, sizeof(buffer), "Fine");
				menu.AddItem("4", buffer);

				FormatEx(buffer, sizeof(buffer), "1:1");
				menu.AddItem("4", buffer);

				FormatEx(buffer, sizeof(buffer), "Coarse");
				menu.AddItem("4", buffer);

				FormatEx(buffer, sizeof(buffer), "Rough");
				menu.AddItem("4", buffer);

				menu.ExitBackButton = true;
			}
		}
		case 4:
		{
		}
		case 5:	// My Body
		{
			menu.SetTitle("%t", "My Body");

			FormatEx(buffer, sizeof(buffer), "Very Fine");
			menu.AddItem("6", buffer);

			FormatEx(buffer, sizeof(buffer), "Fine");
			menu.AddItem("6", buffer);

			FormatEx(buffer, sizeof(buffer), "1:1");
			menu.AddItem("6", buffer);

			FormatEx(buffer, sizeof(buffer), "Coarse");
			menu.AddItem("6", buffer);

			FormatEx(buffer, sizeof(buffer), "Rough");
			menu.AddItem("6", buffer);

			menu.ExitBackButton = true;
		}
		default:
		{
			int entity = GetPlayerWeaponSlot(client, slot);
			if(entity != -1)
			{
				int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
				TF2Econ_GetLocalizedItemName(index, buffer, sizeof(buffer));
				menu.SetTitle(buffer);

				IntToString(slot, num, sizeof(num));

				FormatEx(buffer, sizeof(buffer), "Very Fine");
				menu.AddItem(num, buffer);

				FormatEx(buffer, sizeof(buffer), "Fine");
				menu.AddItem(num, buffer);

				FormatEx(buffer, sizeof(buffer), "1:1");
				menu.AddItem(num, buffer);

				FormatEx(buffer, sizeof(buffer), "Coarse");
				menu.AddItem(num, buffer);

				FormatEx(buffer, sizeof(buffer), "Rough");
				menu.AddItem(num, buffer);

				menu.ExitBackButton = true;
			}
		}
	}

	menu.Display(client, RoundToCeil(MenuDurationFor[client] - GetGameTime()));
}

static int UpgradeMenuH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char buffer[64];
			menu.GetItem(choice, buffer, sizeof(buffer));
			int slot = StringToInt(buffer);
			switch(slot)
			{
				case -1:
				{
					UpgradeMenu(client, choice);
					return 0;
				}
				case 3:	// Keycard
				{
					if(Client(client).KeycardContain)
					{
						switch(choice)
						{
							case 0:	// Very Fine - Upgrades the best stat first
							{
								bool type;

								if(Client(client).KeycardContain > Client(client).KeycardArmory)
								{
									type = false;
								}
								else if(Client(client).KeycardArmory > Client(client).KeycardContain)
								{
									type = true;
								}
								else if(Client(client).KeycardArmory == 3)
								{
									Client(client).KeycardExit++;
									if(Client(client).KeycardExit > 2)
										Client(client).KeycardExit = 2;
								}
								else
								{
									type = view_as<bool>(GetURandomInt() % 2);
								}

								if(type)
								{
									Client(client).KeycardArmory++;
									if(Client(client).KeycardArmory > 3)
										Client(client).KeycardArmory = 3;
								}
								else
								{
									Client(client).KeycardContain++;
									if(Client(client).KeycardContain > 3)
										Client(client).KeycardContain = 3;
								}
							}
							case 1:	// Fine - Specific conditions
							{
								if(Client(client).KeycardExit < 1)
								{
									Client(client).KeycardExit = 1;
								}
								else if(Client(client).KeycardContain < 2)
								{
									Client(client).KeycardContain = 2;
								}
								else if(Client(client).KeycardArmory > 0 && Client(client).KeycardArmory < 2)
								{
									Client(client).KeycardArmory = 2;
								}
								else if(Client(client).KeycardArmory != 2 && Client(client).KeycardContain < 3)
								{
									Client(client).KeycardContain = 3;
								}
								else if(Client(client).KeycardExit < 2)
								{
									Client(client).KeycardExit = 2;
								}
								else if(Client(client).KeycardArmory < 3)
								{
									Client(client).KeycardArmory++;
								}
							}
							case 2:	// 1:1 - Switches Armory and Containment
							{
								int armory = Client(client).KeycardArmory;
								if(armory < 1)
									armory = 1;
								
								Client(client).KeycardArmory = Client(client).KeycardContain;
								Client(client).KeycardContain = armory;
							}
							case 3:	// Rough - Decreases highest stat
							{
								bool type;

								if(Client(client).KeycardContain > Client(client).KeycardArmory)
								{
									type = false;
								}
								else if(Client(client).KeycardArmory > Client(client).KeycardContain)
								{
									type = true;
								}
								else
								{
									type = view_as<bool>(GetURandomInt() % 2);
								}

								if(Client(client).KeycardContain > 2 || Client(client).KeycardArmory > 1)
								{
									Client(client).KeycardExit++;
									if(Client(client).KeycardExit > 2)
										Client(client).KeycardExit = 2;
								}

								if(type)
								{
									Client(client).KeycardArmory--;
									if(Client(client).KeycardArmory < 0)
										Client(client).KeycardArmory = 03;
								}
								else
								{
									Client(client).KeycardContain++;
									if(Client(client).KeycardContain < 1)
										Client(client).KeycardContain = 1;
								}
							}
							case 4:	// Coarse - Highest stat turns into an item
							{
								bool type;

								if(Client(client).KeycardContain > Client(client).KeycardArmory)
								{
									type = false;
								}
								else if(Client(client).KeycardArmory > Client(client).KeycardContain)
								{
									type = true;
								}
								else
								{
									type = view_as<bool>(GetURandomInt() % 2);
								}

								if(type)
								{
									int index = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
									if(index != -1)
									{
										index = Items_GetUpgradePath(GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex"), Client(client).KeycardArmory > 2 ? 0 : 1);
										if(index != -1)
											Items_GiveByIndex(client, index);
									}
								}
								else
								{
									for(int i; i < Client(client).KeycardContain; i++)
									{
										int index = Items_GetUpgradePath(30001, 1);
										if(index != -1)
											Items_GiveByIndex(client, index);
									}
								}

								Client(client).KeycardContain = 0;
								Client(client).KeycardArmory = 0;
								Client(client).KeycardExit = 0;
							}
						}
					}
				}
				case 4:
				{

				}
				case 5:	// My Body
				{
					switch(choice)
					{
						case 0:	// Very Fine
						{
							Client(client).Stress += 675.0;
							ApplyHealEvent(client, -68);

							SetEntityHealth(client, 600);
							TF2_AddCondition(client, TFCond_Kritzkrieged);
							TF2_AddCondition(client, TFCond_MegaHeal);
							TF2_AddCondition(client, TFCond_DefenseBuffed);
							TF2_AddCondition(client, TFCond_SpeedBuffAlly);
						}
						case 1:	// Fine - Buffed
						{
							Client(client).Stress += 50.0;
							ApplyHealEvent(client, -5);

							SetEntityHealth(client, 300);
							TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock);
						}
						case 2:	// 1:1 - Class Swap
						{
							TFClassType class = view_as<TFClassType>(GetURandomInt() % (TFClass_MAX - 1));
							if(TF2_GetPlayerClass(client) <= class)
								class++;
							
							TF2_SetPlayerClass(client, class, _, false);
						}
						case 3:	// Coarse - 1 HP
						{
							Client(client).Stress -= 50.0;
							ApplyHealEvent(client, 5);
							
							if(Client(client).Stress < 0.0)
								Client(client).Stress = 0.0;
							
							SetEntityHealth(client, 1);
							TF2_AddCondition(client, TFCond_Jarated, 60.0);
						}
						case 4:	// Rough - Die
						{
							ForcePlayerSuicide(client, true);
						}
					}
				}
				default:
				{
					int entity = GetPlayerWeaponSlot(client, slot);
					if(entity != -1)
					{
						int index = Items_GetUpgradePath(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), choice);
						TF2_RemoveItem(client, entity);

						if(index != -1)
						{
							entity = Items_GiveByIndex(client, index);
							
							if(entity != -1)
							{
								if(HasEntProp(entity, Prop_Data, "m_iClip1") && GetEntProp(entity, Prop_Data, "m_iClip1") > 0)
									SetEntProp(entity, Prop_Data, "m_iClip1", 0);
								
								if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
								{
									int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
									if(type > 0)
										SetEntProp(client, Prop_Data, "m_iAmmo", GetEntProp(client, Prop_Data, "m_iAmmo") / 8, _, type);
								}
							}
						}
					}
				}
			}

			MenuCooldownFor[client] = GetGameTime() + 30.0;
			UpgradeMenu(client);
		}
	}

	return 0;
}

static Action ReapplyGlowEffect(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		if(IsValidEntity(GlowEffectRef[client]))
			RemoveEntity(GlowEffectRef[client]);
		
		char model[PLATFORM_MAX_PATH];
		GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
		int entity = TF2_CreateGlow(client, model);
		if(entity != -1)
		{
			SDKHook(entity, SDKHook_SetTransmit, GlowTransmit);
			GlowEffectRef[client] = EntIndexToEntRef(entity);
		}
		else
		{
			GlowEffectRef[client] = -1;
		}
	}
	return Plugin_Continue;
}

static Action GlowTransmit(int entity, int target)
{
	if(target > 0 && target <= MaxClients)
	{
		int client = GetEntPropEnt(entity, Prop_Data, "m_hParent");
		if(client > 0 && client <= MaxClients)
		{
			return Client(client).GlowingTo(target) ? Plugin_Continue : Plugin_Stop;
		}

		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Continue;
}
