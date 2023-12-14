#pragma semicolon 1
#pragma newdecls required

void Commands_PluginStart()
{
	AddCommandListener(Joinclass, "joinclass");
	AddCommandListener(HookedCommand, "voicemenu");
	AddCommandListener(HookedCommand, "dropitem");
	AddCommandListener(OnlyWhileDead, "explode");
	AddCommandListener(OnlyWhileDead, "kill");
	AddCommandListener(OnlyWhileDead, "spectate");
	AddCommandListener(OnlyWhileDead, "jointeam");
	AddCommandListener(OnlyWhileDead, "autoteam");
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	char buffer[64];
	kv.GetSectionName(buffer, sizeof(buffer));

	return Classes_ClientCommand(client, buffer) ? Plugin_Handled : Plugin_Continue;
}

static Action Joinclass(int client, const char[] command, int args)
{
	if(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") == view_as<int>(TFClass_Unknown))
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TFClass_Spy);
	
	return Plugin_Handled;
}

static Action HookedCommand(int client, const char[] command, int args)
{
	return Classes_ClientCommand(client, command) ? Plugin_Handled : Plugin_Continue;
}

static Action OnlyWhileDead(int client, const char[] command, int args)
{
	if(IsPlayerAlive(client))
		return Plugin_Handled;
	
	return Plugin_Continue;
}