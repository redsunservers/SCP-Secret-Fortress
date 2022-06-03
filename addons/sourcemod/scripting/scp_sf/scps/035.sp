static const int HealthKill = 25;
static const char SoundDeath[] = "freak_fortress_2/scp035/death1.wav";

public bool SCP035_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra2 = 0;
	
	//TF2Attrib_SetByDefIndex(client, 490, -3.0);

	return false;
}

public void SCP035_OnKill(int client, int victim)
{
	SetEntityHealth(client, GetClientHealth(client)+HealthKill);
}

public void SCP035_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));	
	Classes_PlayDeathAnimation(client, model, "primary_death_burning", SoundDeath, 0.0);
}

public Action SCP035_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		float engineTime = GetGameTime();
		static float delay[MAXTF2PLAYERS];
		if(delay[client] > engineTime)
			return Plugin_Handled;

		if(StrContains(sample, "autodejectedtie", false) != -1)
		{
			delay[client] = engineTime+19.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle7.mp3");
		}
		else if(StrContains(sample, "battlecry", false) != -1)
		{
			delay[client] = engineTime+2.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle4.mp3");
		}
		else if(StrContains(sample, "cheers", false) != -1 || StrContains(sample, "niceshot", false)!=-1)
		{
			delay[client] = engineTime+2.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle1.mp3");
		}
		else if(StrContains(sample, "cloakedspy", false) != -1 || StrContains(sample, "incoming", false)!=-1)
		{
			delay[client] = engineTime+6.0;
			strcopy(sample, PLATFORM_MAX_PATH, "freak_fortress_2/scp035/intro1.wav");
		}
		else if(StrContains(sample, "goodjob", false)!=-1 || StrContains(sample, "sentry", false)!=-1 || StrContains(sample, "need", false)!=-1)
		{
			delay[client] = engineTime+4.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle6.mp3");
		}
		else if(StrContains(sample, "jeers", false) != -1 || StrContains(sample, "helpme", false) != -1)
		{
			delay[client] = engineTime+5.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035closet2.mp3");
		}
		else if(StrContains(sample, "negative", false) != -1)
		{
			delay[client] = engineTime+5.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle3.mp3");
		}
		else if(StrContains(sample, "positive", false) != -1)
		{
			delay[client] = engineTime+8.0;
			strcopy(sample, PLATFORM_MAX_PATH, "scp_sf/035/035idle5.mp3");
		}
		else
		{
			return Plugin_Handled;
		}

		for(int i; i<3; i++)
		{
			EmitSoundToAll2(sample, client, _, level, flags, _, pitch);
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}