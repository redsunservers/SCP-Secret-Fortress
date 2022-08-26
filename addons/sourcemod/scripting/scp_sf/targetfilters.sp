#pragma semicolon 1
#pragma newdecls required

void Target_Setup()
{
	AddMultiTargetFilter("@random", Target_Random, "[REDACTED] players", false);
	AddMultiTargetFilter("@!random", Target_Random, "[REDACTED] players", false);
	AddMultiTargetFilter("@scp", Target_SCP, "all SCP subjects", false);
	AddMultiTargetFilter("@!scp", Target_SCP, "all non-SCP subjects", false);
	AddMultiTargetFilter("@ghost", Target_Ghost, "all dead players", true);
	AddMultiTargetFilter("@!ghost", Target_Ghost, "all alive players", true);

	ClassEnum class;
	char target[18], desc[64];
	SetGlobalTransTarget(LANG_SERVER);
	for(int i; Classes_GetByIndex(i, class); i++)
	{
		FormatEx(target, sizeof(target), "@%s", class.Name);
		FormatEx(desc, sizeof(desc), "all %t", class.Display);
		AddMultiTargetFilter(target, Target_Custom, desc, false);

		FormatEx(target, sizeof(target), "@!%s", class.Name);
		FormatEx(desc, sizeof(desc), "all non-%t", class.Display);
		AddMultiTargetFilter(target, Target_Custom, desc, false);
	}
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

public bool Target_Custom(const char[] pattern, ArrayList clients)
{
	ClassEnum class;
	int index;
	bool non;
	for(; ; index++)
	{
		if(!Classes_GetByIndex(index, class))
			return false;

		int contain = StrContains(pattern, class.Name, false);
		if(contain == 1)
			break;

		if(contain == 2)
		{
			non = true;
			break;
		}
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || clients.FindValue(client)!=-1)
			continue;

		if(Client[client].Class == index)
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