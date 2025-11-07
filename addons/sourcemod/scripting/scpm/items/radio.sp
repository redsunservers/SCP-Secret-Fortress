#pragma semicolon 1
#pragma newdecls required

static int RadioIndex;
static bool Enabled[MAXPLAYERS+1];

int Radio_Index()
{
	return RadioIndex;
}

bool Radio_IsActive(int client)
{
	return (Enabled[client] && Client(client).ActionItem == Radio_Index());
}

public void Radio_Pickup(int client)
{
	Enabled[client] = true;
}

public bool Radio_Drop(int client, bool death)
{
	Enabled[client] = true;
	return true;
}

public void Radio_Precache(int index, ActionInfo data)
{
	RadioIndex = data.Index;
}

public bool Radio_Use(int client)
{
	Enabled[client] = !Enabled[client];
	
	if(Enabled[client])
	{
		PrintCenterText(client, "%T", "Radio On", client);
	}
	else
	{
		PrintCenterText(client, "%T", "Radio Off", client);
	}

	return false;
}

public Action Radio_SoundHook(int client, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(client == entity)
	{
		int castCount;
		int[] cast = new int[MaxClients];

		cast[castCount++] = client;	// DEBUG

		for(int target = 1; target <= MaxClients; target++)
		{
			if(target != client && Client(client).CanTalkTo(target))
			{
				bool found;

				for(int i; i < numClients; i++)
				{
					if(clients[i] == target)
					{
						found = true;
						break;
					}
				}

				if(!found && Radio_IsActive(target))
					cast[castCount++] = target;
			}
		}

		if(castCount)
			EmitSoundEx(cast, castCount, sample, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NONE, flags, volume * 0.5, pitch, .dsp = 56);
	}

	return Plugin_Stop;
}