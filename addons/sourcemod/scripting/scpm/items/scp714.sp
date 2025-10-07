/*
	Ring that slows the player but resist to infection/mind alters
*/

#pragma semicolon 1
#pragma newdecls required

static int SCP714Index;

stock int SCP714_Index()
{
	return SCP714Index;
}

public void SCP714_Precache(int index, ActionInfo data)
{
	SCP714Index = data.Index;
}

public bool SCP714_Use(int client)
{
	PrintCenterText(client, "%T", "SCP714 Message", client);
	return false;
}

public Action SCP714_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	Client(client).SprintPower = 0.0;

	if(!TF2_IsPlayerInCondition(client, TFCond_Dazed))
		TF2_StunPlayer(client, 1.0, 0.1, TF_STUNFLAG_SLOWDOWN);
	
	return Plugin_Continue;
}