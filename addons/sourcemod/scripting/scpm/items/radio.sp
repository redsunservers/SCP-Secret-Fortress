#pragma semicolon 1
#pragma newdecls required

static const char StaticNoise[] = "ui/tv_static.wav";

static int RadioIndex;
static bool Enabled[MAXPLAYERS+1];
static bool Jammed[MAXPLAYERS+1];
static float JammedFor[MAXPLAYERS+1];

int Radio_Index()
{
	return RadioIndex;
}

bool Radio_IsActive(int client)
{
	return (Enabled[client] && !Jammed[client] && Client(client).ActionItem == Radio_Index());
}

void Radio_JamFor(int client, float time)
{
	float gameTime = GetGameTime() + time;
	if(JammedFor[client] < gameTime)
		JammedFor[client] = gameTime;
}

public void Radio_Pickup(int client)
{
	Enabled[client] = true;
	Jammed[client] = false;
	JammedFor[client] = 0.0;
}

public bool Radio_Drop(int client, bool death)
{
	Enabled[client] = true;
	
	if(Jammed[client])
	{
		StopSound(client, SNDCHAN_AUTO, StaticNoise);
		Jammed[client] = false;
	}

	return true;
}

public void Radio_Precache(int index, ActionInfo data)
{
	RadioIndex = data.Index;
	PrecacheSound(StaticNoise);
}

public bool Radio_Use(int client)
{
	Enabled[client] = !Enabled[client];
	Radio_PlayerRunCmd(client);
	
	if(!Enabled[client])
	{
		PrintCenterText(client, "%T", "Radio Off", client);
	}
	else if(Jammed[client])
	{
		PrintCenterText(client, "%T", "Radio Jammed", client);
	}
	else
	{
		PrintCenterText(client, "%T", "Radio On", client);
	}

	ClientCommand(client, "playgamesound buttons/button17.wav");

	return false;
}

public Action Radio_PlayerRunCmd(int client)
{
	bool jammed;

	if(Enabled[client])
	{
		jammed = JammedFor[client] > GetGameTime();
	}

	if(jammed)
	{
		if(!Jammed[client])
		{
			Jammed[client] = true;
			EmitSoundToClientEx(client, StaticNoise, .dsp = 38);
		}
	}
	else if(Jammed[client])
	{
		StopSound(client, SNDCHAN_AUTO, StaticNoise);
		Jammed[client] = false;
	}

	return Plugin_Continue;
}

public Action Radio_SoundHook(int client, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(client == entity && Radio_IsActive(client) && ((channel == SNDCHAN_VOICE || (channel == SNDCHAN_STATIC && !StrContains(sample, "vo", false)))))
	{
		int castCount;
		int[] cast = new int[MaxClients];

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

	return Plugin_Continue;
}