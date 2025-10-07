/*
	Necklace that heals, but spawns a mob after too long use
*/

#pragma semicolon 1
#pragma newdecls required

static float LastTime[MAXPLAYERS+1];

public bool SCP427_Use(int client)
{
	PrintCenterText(client, "%T", "SCP427 Message", client);
	return false;
}

public Action SCP427_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	float gameTime = GetGameTime();
	if(gameTime > LastTime[client])
	{
		// TODO: Hostile SCP creation when too much
	}

	return Plugin_Continue;
}