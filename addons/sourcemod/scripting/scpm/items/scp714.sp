/*
	Ring that slows the player but resist to infection/mind alters
*/

#pragma semicolon 1
#pragma newdecls required

static int SCP714Index = -1;
static bool Opened[MAXPLAYERS+1];

stock bool SCP714_IsWearing(int client)
{
	if(Client(client).ActionItem != -1 && Client(client).ActionItem == SCP714Index)
		return Opened[client];
	
	return false;
}

public void SCP714_Precache(int index, ActionInfo data)
{
	SCP714Index = data.Index;
}

public void SCP714_Pickup(int client)
{
	Opened[client] = false;
}

public bool SCP714_Drop(int client, bool death)
{
	Opened[client] = false;
	return true;
}

public bool SCP714_Use(int client)
{
	Opened[client] = !Opened[client];
	
	if(Opened[client])
	{
		PrintCenterText(client, "%T", "SCP714 On", client);
		TF2_RemoveCondition(client, TFCond_Plague);
	}
	else
	{
		PrintCenterText(client, "%T", "SCP714 Off", client);
	}
	
	return false;
}

public Action SCP714_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(Opened[client])
	{
		Client(client).SprintPower = 0.0;

		if(!TF2_IsPlayerInCondition(client, TFCond_Dazed))
			TF2_StunPlayer(client, 1.0, 0.2, TF_STUNFLAG_SLOWDOWN);
	}
	
	return Plugin_Continue;
}