#pragma semicolon 1
#pragma newdecls required

void Natives_PluginLoad()
{
	CreateNative("SCPSF_GetClientClass", GetClientClass);
	CreateNative("SCPSF_IsSCP", IsSCP);
	CreateNative("SCPSF_StartMusic", StartMusic);
	CreateNative("SCPSF_StopMusic", StopMusic);
	CreateNative("SCPSF_CanTalkTo", CanClientTalkTo);
	CreateNative("SCPSF_GetChatTag", GetChatTag);
}

static any GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);

	ClassEnum class;
	Classes_GetByIndex(Client(client).Class, class);

	int length = GetNativeCell(3);
	char[] buffer = new char[length];
	strcopy(buffer, length, class.Name);

	int bytes;
	SetNativeString(2, buffer, length, _, bytes);
	return bytes;
}

static any IsSCP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients || !IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);
	
	return (GetClientTeam(client) <= TFTeam_Spectator && IsPlayerAlive(client));
}

static any StartMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients)
	{
		Music_PlayerSpawn(client);
	}
	else
	{
		for(client = 1; client <= MaxClients; client++)
		{
			Music_PlayerSpawn(client);
		}
	}

	Music_SetMusicStatus(true);
	return 0;
}

static any StopMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client > 0 && client <= MaxClients)
	{
		Music_StopMusic(client);
	}
	else
	{
		for(client = 1; client <= MaxClients; client++)
		{
			Music_StopMusic(client);
		}

		Music_SetMusicStatus(false);
	}
	
	return 0;
}

static any CanClientTalkTo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);

	int target = GetNativeCell(2);
	if(target < 0 || target > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", target);

	return Client(client).CanTalkTo(target);
}

static any GetChatTag(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", client);

	int target = GetNativeCell(2);
	if(target < 0 || target > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Client index %d is invalid", target);
	
	int bytes;
	int length = GetNativeCell(4);
	char[] buffer = new char[length];
	Proxy_GetChatTag(client, target, buffer, length);
	SetNativeString(3, buffer, length, _, bytes);
	return bytes;
}
