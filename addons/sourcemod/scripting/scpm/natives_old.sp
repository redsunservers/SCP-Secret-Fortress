#pragma semicolon 1
#pragma newdecls required

void NativeOld_PluginLoad()
{
	CreateNative("SCPSF_GetClientClass", GetClientClass);
	CreateNative("SCPSF_IsSCP", IsSCP);
	CreateNative("SCPSF_StartMusic", StartMusic);
	CreateNative("SCPSF_StopMusic", StopMusic);
	CreateNative("SCPSF_CanTalkTo", CanTalkTo);
	CreateNative("SCPSF_GetChatTag", GetChatTag);

	RegPluginLibrary("scp_sf");
}

static any GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return 0;
	
	int bytes;
	int length = GetNativeCell(3);
	char[] buffer = new char[length];

	if(Client(client).IsBoss)
	{
		bytes = Bosses_GetName(Client(client).Boss, buffer, length);
	}
	else if(!IsPlayerAlive(client))
	{
		bytes = strcopy(buffer, length, "spec");
	}
	else if(Client(client).NoEscape)
	{
		bytes = strcopy(buffer, length, "chaos");
	}
	else
	{
		bytes = strcopy(buffer, length, "dboi");
	}

	SetNativeString(2, buffer, length, _, bytes);
	return bytes;
}

static any IsSCP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients)
		return Client(client).IsBoss;

	return false;
}

static any StartMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients)
	{
		Music_ToggleMusic(client, true, false);
	}
	else
	{
		Music_ToggleRoundMusic(true);

		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target))
				Music_ToggleMusic(target, true, false);
		}
	}

	return 0;
}

static any StopMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients)
	{
		Music_ToggleMusic(client, false, true);
	}
	else
	{
		Music_ToggleRoundMusic(false);

		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target))
				Music_ToggleMusic(target, false, true);
		}
	}
	return 0;
}

static any CanTalkTo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients)
		return false;

	int target = GetNativeCell(2);
	if(target < 0 || target > MaxClients)
		return false;

	return Client(client).CanTalkTo(target);
}

static any GetChatTag(Handle plugin, int numParams)
{
	SetNativeString(3, NULL_STRING, GetNativeCell(4));
	return 0;
}
