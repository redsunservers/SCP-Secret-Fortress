#pragma semicolon 1
#pragma newdecls required

static Handle ResultHud;

void Events_PluginStart()
{
	ResultHud = CreateHudSynchronizer();
	
	HookEvent("teamplay_win_panel", TeamplayWinPanel, EventHookMode_Pre);
	HookEvent("object_destroyed", ObjectDestroyed, EventHookMode_Post);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_healed", PlayerHealed, EventHookMode_Post);
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", PlayerDeath, EventHookMode_Post);
	HookEvent("player_team", PlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", PostInventoryApplication, EventHookMode_Pre);
	HookEvent("rps_taunt_event", RPSTauntEvent, EventHookMode_Post);
	HookEvent("teamplay_broadcast_audio", TeamplayBroadcastAudio, EventHookMode_Pre);
	HookEvent("teamplay_round_win", TeamplayRoundEnd, EventHookMode_Post);
}

void Events_RoundRespawn()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			ClearSyncHud(client, ResultHud);
	}
}
