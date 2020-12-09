void Target_Setup()
{
	AddMultiTargetFilter("@random", Target_Random, "[REDACTED] players", false);
	AddMultiTargetFilter("@!random", Target_Random, "[REDACTED] players", false);
	AddMultiTargetFilter("@scp", Target_SCP, "all SCP subjects", false);
	AddMultiTargetFilter("@!scp", Target_SCP, "all non-SCP subjects", false);
	AddMultiTargetFilter("@chaos", Target_Chaos, "all Chaos Insurgency Agents", false);
	AddMultiTargetFilter("@!chaos", Target_Chaos, "all non-Chaos Insurgency Agents", false);
	AddMultiTargetFilter("@mtf", Target_MTF, "all Mobile Task Force Units", false);
	AddMultiTargetFilter("@!mtf", Target_MTF, "all non-Mobile Task Force Units", false);
	AddMultiTargetFilter("@ghost", Target_Ghost, "all dead players", true);
	AddMultiTargetFilter("@!ghost", Target_Ghost, "all alive players", true);
	AddMultiTargetFilter("@dclass", Target_DBoi, "all d bois", false);
	AddMultiTargetFilter("@!dclass", Target_DBoi, "all not d bois", false);
	AddMultiTargetFilter("@scientist", Target_Scientist, "all Scientists", false);
	AddMultiTargetFilter("@!scientist", Target_Scientist, "all non-Scientists", false);
	AddMultiTargetFilter("@guard", Target_Guard, "all Facility Guards", false);
	AddMultiTargetFilter("@!guard", Target_Guard, "all non-Facility Guards", false);
}

public bool Target_Random(const char[] pattern, ArrayList clients)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(GetRandomInt(0, 1))
			clients.Push(client);
	}
	return true;
}

public bool Target_SCP(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(IsSCP(client))
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Chaos(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_Chaos)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_MTF(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class>=Class_MTF && Client[client].Class<=Class_MTFE)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Ghost(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_DBoi(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_DBoi)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Scientist(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_Scientist)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}

public bool Target_Guard(const char[] pattern, ArrayList clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == Class_Guard)
		{
			if(non)
				continue;
		}
		else if(!non)
		{
			continue;
		}

		clients.Push(client);
	}
	return true;
}