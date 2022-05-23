static const char SoundDeath[] = "freak_fortress_2/scp966/alert_03.mp3";

public bool SCP966_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra2 = 0;

	int account = GetSteamAccountID(client, false);
	
	int weapon = SpawnWeapon(client, "tf_weapon_invis", 212, 12, 13, "35 ; 1.5 ; 50 ; 1.2 ; 85 ; 0.5 ; 160 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 10);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
	}
	
	weapon = SpawnWeapon(client, "tf_weapon_knife", 225, 70, 13, "2 ; 1.2 ; 6 ; 0.75 ; 15 ; 0 ; 182 ; 2 ; 252 ; 0.5 ; 4328 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 10);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", account);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	
	return false;
}

public void SCP966_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));	
	Classes_PlayDeathAnimation(client, model, "primary_death_backstab", SoundDeath, 0.0);
}

public Action SCP966_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		if(StrContains(sample, "pains", false) != -1)
		{
			Format(sample, PLATFORM_MAX_PATH, "freak_fortress_2/scp966/idle_0%d.wav", GetRandomInt(1, 3));
		}
		else if(StrContains(sample, "paincrticial", false) != -1)
		{
			Format(sample, PLATFORM_MAX_PATH, "freak_fortress_2/scp966/attack_0%d.wav", GetRandomInt(1, 3));
		}
		else
		{
			return Plugin_Handled;
		}
		
		return Plugin_Handled;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 20;
		volume *= 0.5;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}