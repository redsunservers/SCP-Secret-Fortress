#pragma semicolon 1
#pragma newdecls required

public void CryptoForest_RoundStart()
{
	HookEntityOutput("game_end", "EndGame", CryptoForest_GameOver);
}

public Action CryptoForest_GameOver(const char[] output, int entity, int client, float delay)
{
	EndRound(TFTeam_Red);
	UnhookEntityOutput("game_end", "EndGame", CryptoForest_GameOver);
	return Plugin_Handled;
}

public bool CryptoForest_OnSpawn(int client)
{
	RequestFrame(CryptoForest_OnSpawnPost, client);
	return false;
}

public void CryptoForest_OnSpawnPost(int client)
{
	Client[client].HudIn = FAR_FUTURE;
	Client[client].Extra2 = true;
}

public bool CryptoForest_Condition(TFTeam &team)
{
	ClassEnum class;
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i) || IsSpec(i) || !Classes_GetByIndex(Client[i].Class, class))
			continue;

		if(class.Vip)
			return false;
	}

	team = TFTeam_Red;
	UnhookEntityOutput("game_end", "EndGame", CryptoForest_GameOver);
	return true;
}

public float CryptoForest_RespawnWave(ArrayList &list, ArrayList &players)
{
	int length = players.Length;
	if(length)
	{
		list = new ArrayList();
		for(int i; i<length; i++)
		{
			list.Push(1);
		}
		return 0.0;
	}

	float min, max;
	Gamemode_GetWaveTimes(min, max);
	return GetRandomFloat(min, max);
}