#pragma semicolon 1
#pragma newdecls required

void Events_PluginStart()
{
	HookEvent("object_destroyed", ObjectDestroyed, EventHookMode_Pre);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", PostInventoryApplication, EventHookMode_Post);
	HookEvent("teamplay_broadcast_audio", TeamplayBroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_round_start", TeamplayRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", TeamplayRoundWin, EventHookMode_PostNoCopy);
	HookEvent("teamplay_win_panel", TeamplayWinPanel, EventHookMode_Pre);
}

static Action ObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker)
	{
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target == attacker || (IsClientInGame(target) && Client(attacker).CanTalkTo(target)))
				event.FireToClient(target);
		}
	}
	return Plugin_Changed;
}

static Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(!victim)
		return Plugin_Continue;
	
	// Note: If we add dead ringers, add a check here
	Music_PlayerDeath(victim);

	event.BroadcastDisabled = true;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	Classes_PlayerDeath(victim, attacker, event);

	if(attacker && event.BroadcastDisabled)
	{
		int team = GetClientTeam(attacker);
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target == attacker || (IsClientInGame(target) && GetClientTeam(target) == team && Client(attacker).CanTalkTo(target)))
				event.FireToClient(target);
		}
	}

	Proxy_UpdateChatRules();
	return Plugin_Changed;
}

static void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
	{
		Classes_PlayerSpawn(client);
	}
}

static void PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
	{
		Classes_PostInventoryApplication(client);
	}
}

static Action TeamplayBroadcastAudio(Event event, const char[] name, bool dontBroadcast)
{
	char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.", false))
	{
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

static void TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundStart();
}

static void TeamplayRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	Gamemode_RoundEnd();
	Music_RoundEnd();
}

static Action TeamplayWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
	return Plugin_Changed;
}