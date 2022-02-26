public bool SCP035_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra2 = 0;

	return false;
}

public void SCP035_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	CreateTimer(5.0, Timer_DissolveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}