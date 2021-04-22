static const char SnapSound[] = "freak_fortress_2/scp173/scp173_kill2.mp3";

public bool SCP173_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra2 = 0;

	int weapon = SpawnWeapon(client, "tf_weapon_knife", 195, 90, 13, "1 ; 0.05 ; 6 ; 0.01 ; 15 ; 0 ; 138 ; 101 ; 252 ; 0 ; 263 ; 1.15 ; 264 ; 1.15 ; 275 ; 1 ; 362 ; 1 ; 4328 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 17);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	return false;
}

public void SCP173_OnSpeed(int client, float &speed)
{
	switch(Client[client].Extra2)
	{
		case 1:
			speed = 1.0;

		case 2:
			speed = FAR_FUTURE;
	}
}

public void SCP173_OnKill(int client, int victim)
{
	GiveAchievement(Achievement_Death173, victim);
	EmitSoundToAll(SnapSound, victim, SNDCHAN_BODY, SNDLEVEL_SCREAMING, _, _, _, client);
}

public void SCP173_OnButton(int client, int button)
{
	float engineTime = GetEngineTime();
	if(Client[client].Extra3 > engineTime)
		return;

	Client[client].Extra3 = engineTime+0.2;

	static int blink;
	static float pos1[3], ang1[3];
	GetClientEyePosition(client, pos1);
	GetClientEyeAngles(client, ang1);
	ang1[0] = fixAngle(ang1[0]);
	ang1[1] = fixAngle(ang1[1]);

	int status;
	for(int target=1; target<=MaxClients; target++)
	{
		if(target==client || !IsValidClient(target) || IsSpec(target) || IsFriendly(Client[client].Class, Client[target].Class))
			continue;

		static float pos2[3], ang2[3], ang3[3];
		GetClientEyePosition(target, pos2);
		GetClientEyeAngles(target, ang2);
		GetVectorAnglesTwoPoints(pos2, pos1, ang3);

		// fix all angles
		ang2[0] = fixAngle(ang2[0]);
		ang2[1] = fixAngle(ang2[1]);
		ang3[0] = fixAngle(ang3[0]);
		ang3[1] = fixAngle(ang3[1]);

		// verify angle validity
		if(!(fabs(ang2[0] - ang3[0]) <= MAXANGLEPITCH ||
		(fabs(ang2[0] - ang3[0]) >= (360.0-MAXANGLEPITCH))))
			continue;

		if(!(fabs(ang2[1] - ang3[1]) <= MAXANGLEYAW ||
		(fabs(ang2[1] - ang3[1]) >= (360.0-MAXANGLEYAW))))
			continue;

		// ensure no wall is obstructing
		TR_TraceRayFilter(pos2, pos1, MASK_VISIBLE, RayType_EndPoint, TraceWallsOnly);
		TR_GetEndPosition(ang3);
		if(ang3[0]!=pos1[0] || ang3[1]!=pos1[1] || ang3[2]!=pos1[2])
			continue;

		// success
		if(blink)
		{
			status = 1;
			break;
		}

		status = 2;
		FadeMessage(target, 52, 52, 0x0002, 0, 0, 0);
	}

	if(blink > 0)
	{
		blink--;
	}
	else
	{
		float min = 9.001;
		float max = 13.13;

		int health;
		OnGetMaxHealth(client, health);
		if(health)
		{
			float ratio = (0.6-(GetClientHealth(client)/health))*3.0;	// -1.2 ~ +1.8
			min -= ratio;
			max -= ratio*1.1;
		}

		blink = RoundFloat(GetRandomFloat(min, max));
	}

	if(status == 1)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", false);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false);

		GetEntPropVector(client, Prop_Data, "m_vecVelocity", pos1);
		pos1[0] = 0.0;
		pos1[1] = 0.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, pos1);
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", true);
	}

	if(Client[client].Extra2 != status)
	{
		Client[client].Extra2 = status;
		SDKCall_SetSpeed(client);
	}
}

public Action SCP173_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		return Plugin_Handled;
	}
	else if(StrContains(sample, "footsteps", false) != -1)
	{
		Format(sample, sizeof(sample), "physics/concrete/concrete_scrape_smooth_loop1.wav");
		EmitSoundToAll(sample, client, channel, level+30, flags, volume, pitch+10, _, _, _, _, 0.6);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}