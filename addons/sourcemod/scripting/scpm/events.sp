#pragma semicolon 1
#pragma newdecls required

void Events_PluginStart()
{
	HookEvent("player_spawn", Events_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Events_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", Events_PlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", Events_InventoryApplication, EventHookMode_Pre);
	HookEvent("scorestats_accumulated_update", Events_RoundRespawn, EventHookMode_PostNoCopy);
	//HookEvent("teamplay_broadcast_audio", Events_BroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_round_start", Events_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Events_RoundEnd, EventHookMode_Post);
	HookEvent("teamplay_win_panel", Events_WinPanel, EventHookMode_Pre);
}

static void Events_RoundRespawn(Event event, const char[] name, bool dontBroadcast)
{
	Music_ToggleRoundMusic(true);
	Gamemode_RoundRespawn();
}

static void Events_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Items_RoundStart();
}

static void Events_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundEnd(/*event.GetInt("team")*/);
	Specials_RoundEnd();
}
/*
static Action Events_BroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	char sound[64];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}
*/
static void Events_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		ViewModel_Destroy(client);
		Human_PlayerSpawn(client);
		Bosses_PlayerSpawn(client);
		if(GetClientTeam(client) > TFTeam_Spectator)
		{
			Gamemode_PlayerSpawn(client);
			Music_ToggleMusic(client);
		}
	}

	Gamemode_CheckAlivePlayers();
}

static Action Events_InventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		Human_InventoryApplication(client);

		if(Client(client).IsBoss)
			Bosses_Equip(client);
	}
	return Plugin_Continue;
}

static Action Events_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int victim = GetClientOfUserId(userid);
	if(victim)
	{
		bool deadRinger = view_as<bool>(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER);
		
		if(Bosses_StartFunctionClient(victim, "PlayerDeath"))
		{
			Call_PushCell(victim);
			Call_PushCellRef(deadRinger);
			Call_Finish();
		}
		
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(attacker)
		{
			if(attacker != victim)
			{
				if(Bosses_StartFunctionClient(attacker, "PlayerKilled"))
				{
					Call_PushCell(attacker);
					Call_PushCell(victim);
					Call_PushCell(deadRinger);
					Call_Finish();
				}
			}
		}

		int assister = GetClientOfUserId(event.GetInt("assist"));

		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target))
			{
				// If all these conditions fail, don't show the kill feed to the player
				if(victim != target && attacker != target && !Client(victim).IsBoss && !Client(target).LookingAt(victim))
				{
					if(!attacker || GetClientTeam(attacker) != GetClientTeam(target) || !Client(attacker).CanTalkTo(victim))
					{
						if(!assister || GetClientTeam(assister) != GetClientTeam(target) || !Client(assister).CanTalkTo(victim))
						{
							continue;
						}
					}
				}

				event.FireToClient(target);
			}
		}

		if(!deadRinger && Client(victim).IsBoss)
		{
			char boss[64], killer[64];
			Bosses_GetName(Client(victim).Boss, boss, sizeof(boss));

			if(attacker)
				GetClientName(attacker, killer, sizeof(killer));

			if(assister)
			{
				char assistant[64];
				GetClientName(assister, assistant, sizeof(assistant));
				CPrintToChatAll("%t", "Boss Killed Message Duo", boss, killer, assistant);
			}
			else if(attacker && attacker != victim)
			{
				CPrintToChatAll("%t", "Boss Killed Message Solo", boss, killer);
			}
			else
			{
				CPrintToChatAll("%t", "Boss Killed Message None", boss);
			}
		}
		
		if(!deadRinger)
		{
			Human_PlayerDeath(victim);
			Music_ToggleMusic(victim, false, true);
			Gamemode_CheckAlivePlayers(victim);
			ViewModel_Destroy(victim);
			Client(victim).ResetByDeath();
			
			CreateTimer(0.1, RemoveKillCam, userid, TIMER_FLAG_NO_MAPCHANGE);

			if(Client(victim).IsBoss)
				CreateTimer(0.1, RemoveBossTimer, userid, TIMER_FLAG_NO_MAPCHANGE);
		}

		Gamemode_UpdateListeners();
		
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

static Action RemoveBossTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
		Bosses_Remove(client, false);
	
	return Plugin_Continue;
}

static Action RemoveKillCam(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
		SetEntProp(client, Prop_Send, "m_hObserverTarget", -1);
	
	return Plugin_Continue;
}

static Action Events_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return Gamemode_WinPanel(event);
}