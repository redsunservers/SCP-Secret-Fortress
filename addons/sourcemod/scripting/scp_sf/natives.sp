void Native_Setup()
{
	CreateNative("SCPSF_GetClientClass", Native_GetClientClass);
	CreateNative("SCPSF_IsSCP", Native_IsSCP);
	CreateNative("SCPSF_StartMusic", Native_StartMusic);
	CreateNative("SCPSF_StopMusic", Native_StopMusic);
	CreateNative("SCPSF_CanTalkTo", Native_CanTalkTo);
}

public any Native_GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return 0;

	int length = GetNativeCell(3);
	char[] buffer = new char[length];
	strcopy(buffer, length, ClassShort[Client[client].Class]);

	int bytes;
	SetNativeString(2, buffer, length, _, bytes);
	return bytes;
}

public any Native_IsSCP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>=0 && client<MAXTF2PLAYERS)
		return IsSCP(client);

	return false;
}

public any Native_StartMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>0 && client<MAXTF2PLAYERS)
	{
		Client[client].NextSongAt = 0.0;
	}
	else if(!NoMusicRound)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			Client[client].NextSongAt = 0.0;
		}
	}

	NoMusicRound = false;
}

public any Native_StopMusic(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>0 && client<MAXTF2PLAYERS)
	{
		Client[client].NextSongAt = FAR_FUTURE;
		if(Client[client].CurrentSong[0])
		{
			StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
			StopSound(client, SNDCHAN_STATIC, Client[client].CurrentSong);
			Client[client].CurrentSong[0] = 0;
		}
	}
	else
	{
		for(int i=1; i<=MaxClients; i++)
		{
			Client[i].NextSongAt = FAR_FUTURE;
			if(!Client[i].CurrentSong[0] || !IsValidClient(client))
				continue;

			StopSound(i, SNDCHAN_STATIC, Client[i].CurrentSong);
			StopSound(i, SNDCHAN_STATIC, Client[i].CurrentSong);
			Client[i].CurrentSong[0] = 0;
		}
		NoMusicRound = false;
	}
}

public any Native_CanTalkTo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<0 || client>=MAXTF2PLAYERS)
		return false;

	int target = GetNativeCell(2);
	if(target<0 || target>=MAXTF2PLAYERS)
		return false;

	return Client[client].CanTalkTo[target];
}