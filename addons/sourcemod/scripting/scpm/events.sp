#pragma semicolon 1
#pragma newdecls required

void Events_PluginStart()
{
	HookEvent("player_spawn", Events_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Events_PlayerDeath, EventHookMode_Post);
	HookEvent("player_team", Events_PlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", Events_InventoryApplication, EventHookMode_Pre);
	HookEvent("scorestats_accumulated_update", Events_RoundRespawn, EventHookMode_PostNoCopy);
	HookEvent("teamplay_broadcast_audio", Events_BroadcastAudio, EventHookMode_Pre);
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
	Gamemode_RoundEnd(event.GetInt("team"));
}

static Action Events_BroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	char sound[64];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.AM_RoundStartRandom", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

static void Events_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(client)
	{
		Human_PlayerSpawn(client);
		if(GetClientTeam(client) > TFTeam_Spectator)
			Music_ToggleMusic(client);
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

static void Events_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(victim)
	{
		PrintToChatAll("Events_PlayerDeath");
		
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
		
		//ScreenFade(victim, 50, 50, FFADE_IN|FFADE_PURGE, 50, 0, 0, 255);
		
		if(!deadRinger)
		{
			Human_PlayerDeath(victim);
			Bosses_Remove(victim, false);
			Music_ToggleMusic(victim, false, true);
			Gamemode_CheckAlivePlayers(victim);
			Client(victim).ResetByDeath();
		}
	}
}

static Action Events_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return Gamemode_WinPanel(event);
}