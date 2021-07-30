static const char SnapSound[] = "freak_fortress_2/scp173/scp173_kill2.mp3";

static const int HealthMax = 2000;	// Max standard health
static const int HealthExtra = 1250;	// Max regenerable health
static const int HealthKill = 100;	// Health gain on stunned kill

static const float DistanceMax = 600.0;	// Distance at low health
static const float DistanceExtra = 200.0;	// Distance removed at max health

public bool SCP173_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra1 = HealthMax;
	Client[client].Extra2 = 0;
	Client[client].Extra3 = 0.0;

	int weapon = SpawnWeapon(client, "tf_weapon_knife", 593, 90, 13, "1 ; 0.05 ; 6 ; 0.01 ; 15 ; 0 ; 66 ; 0.8 ; 138 ; 101 ; 252 ; 0 ; 263 ; 1.15 ; 264 ; 1.15 ; 275 ; 1 ; 362 ; 1 ; 4328 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 17);
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	return false;
}

public void SCP173_OnMaxHealth(int client, int &health)
{
	health = Client[client].Extra1 + HealthExtra;

	int current = GetClientHealth(client);
	if(current > health)
	{
		SetEntityHealth(client, health);
	}
	else if(current < Client[client].Extra1-HealthExtra)
	{
		Client[client].Extra1 = current+HealthExtra;
	}
}

public void SCP173_OnSpeed(int client, float &speed)
{
	switch(Client[client].Disarmer)
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
	static float delay[MAXTF2PLAYERS];
	if(delay[client] > engineTime)
		return;

	delay[client] = engineTime+0.2;

	static float pos1[3], ang1[3];
	GetClientEyePosition(client, pos1);
	GetClientEyeAngles(client, ang1);
	ang1[0] = fixAngle(ang1[0]);
	ang1[1] = fixAngle(ang1[1]);

	bool teleport = (Client[client].Extra3 >= 100.0 && ((buttons & IN_ATTACK) || (buttons & IN_FORWARD) || (buttons & IN_JUMP)));

	float players;
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

		// ensure no wall or door is obstructing
		TR_TraceRayFilter(pos2, pos1, MASK_VISIBLE, RayType_EndPoint, Trace_DoorOnly);
		TR_GetEndPosition(ang3);
		if(ang3[0]!=pos1[0] || ang3[1]!=pos1[1] || ang3[2]!=pos1[2])
			continue;

		// success
		players += 1.0;
		if(teleport)
			FadeMessage(target, 52, 52, 0x0002, 0, 0, 0);
	}

	bool failed;
	if(players)
	{
		if(teleport)
		{
			float distance = DistanceMax - ((GetClientHealth(client) / (HealthMax+HealthExtra)) * DistanceExtra);
			if(DPT_TryTeleport(client, distance))
			{
				Client[client].Extra3 = 0.0;
			}
			else
			{
				failed = true;
				teleport = false;
			}
		}
		else
		{
			Client[client].Extra3 += 20.0 / (players + 2.0);
			if(Client[client].Extra3 > 100.0)
				Client[client].Extra3 = 100.0;
		}
	}

	if(!(GetClientButtons(client) & IN_SCORE))
	{
		char buffer[32];
		if(failed)
		{
			FormatEx(buffer, sizeof(buffer), "%T", "failed");
		}
		else
		{
			int amount = 15 - RoundToCeil(Client[client].Extra3 * 0.15);
			for(int i; i<amount; i++)
			{
				Format(buffer, sizeof(buffer), "%s|", buffer);
			}
		}

		SetHudTextParamsEx(0.14, 0.93, 0.425, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
		ShowSyncHudText(client, HudGame, "%T", "blink", client, buffer);
	}

	if(players)
	{
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", pos1);
		pos1[0] = 0.0;
		pos1[1] = 0.0;
		if(pos1[2] > 0.0)
			pos1[2] = 0.0;

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, pos1);
	}

	int status = 1;
	if(teleport || !players)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", true);

		if(!teleport)
			status = 0;
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", false);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false);
	}

	if(Client[client].Disarmer != status)
	{
		Client[client].Disarmer = status;
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
		StopSound(client, SNDCHAN_AUTO, sample);
		EmitSoundToAll("physics/concrete/concrete_scrape_smooth_loop1.wav", client, channel, level+30, flags, volume, pitch+10, _, _, _, _, 0.6);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

// From ff2_dynamic_defaults by sarysa
public bool DPT_TracePlayersAndBuildings(int entity, int contentsMask, any data)
{
	if(entity>0 && entity<=MaxClients)
		return GetClientTeam(entity) != data;

	return IsValidEntity(entity);
}

static bool DPT_TryTeleport(int clientIdx, float maxDistance)
{
	float sizeMultiplier = GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale");
	static float startPos[3];
	static float endPos[3];
	static float testPos[3];
	static float eyeAngles[3];
	GetClientEyePosition(clientIdx, startPos);
	GetClientEyeAngles(clientIdx, eyeAngles);
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, DPT_TracePlayersAndBuildings, GetClientTeam(clientIdx));
	TR_GetEndPosition(endPos);
	
	// don't even try if the distance is less than 82
	float distance = GetVectorDistance(startPos, endPos);
	if (distance < 82.0)
		return true;
		
	if (distance > maxDistance)
		constrainDistance(startPos, endPos, distance, maxDistance);
	else // shave just a tiny bit off the end position so our point isn't directly on top of a wall
		constrainDistance(startPos, endPos, distance, distance - 1.0);
	
	// now for the tests. I go 1 extra on the standard mins/maxs on purpose.
	bool found = false;
	for (int x = 0; x < 3; x++)
	{
		if (found)
			break;
	
		float xOffset;
		if (x == 0)
			xOffset = 0.0;
		else if (x == 1)
			xOffset = 12.5 * sizeMultiplier;
		else
			xOffset = 25.0 * sizeMultiplier;
		
		if (endPos[0] < startPos[0])
			testPos[0] = endPos[0] + xOffset;
		else if (endPos[0] > startPos[0])
			testPos[0] = endPos[0] - xOffset;
		else if (xOffset != 0.0)
			break; // super rare but not impossible, no sense wasting on unnecessary tests
	
		for (int y = 0; y < 3; y++)
		{
			if (found)
				break;

			float yOffset;
			if (y == 0)
				yOffset = 0.0;
			else if (y == 1)
				yOffset = 12.5 * sizeMultiplier;
			else
				yOffset = 25.0 * sizeMultiplier;

			if (endPos[1] < startPos[1])
				testPos[1] = endPos[1] + yOffset;
			else if (endPos[1] > startPos[1])
				testPos[1] = endPos[1] - yOffset;
			else if (yOffset != 0.0)
				break; // super rare but not impossible, no sense wasting on unnecessary tests
		
			for (int z = 0; z < 3; z++)
			{
				if (found)
					break;

				float zOffset;
				if (z == 0)
					zOffset = 0.0;
				else if (z == 1)
					zOffset = 41.5 * sizeMultiplier;
				else
					zOffset = 83.0 * sizeMultiplier;

				if (endPos[2] < startPos[2])
					testPos[2] = endPos[2] + zOffset;
				else if (endPos[2] > startPos[2])
					testPos[2] = endPos[2] - zOffset;
				else if (zOffset != 0.0)
					break; // super rare but not impossible, no sense wasting on unnecessary tests

				// before we test this position, ensure it has line of sight from the point our player looked from
				// this ensures the player can't teleport through walls
				static float tmpPos[3];
				TR_TraceRayFilter(endPos, testPos, MASK_PLAYERSOLID, RayType_EndPoint, DPT_TraceWallsOnly);
				TR_GetEndPosition(tmpPos);
				if (testPos[0] != tmpPos[0] || testPos[1] != tmpPos[1] || testPos[2] != tmpPos[2])
					continue;
				
				// now we do our very expensive test. thankfully there's only 27 of these calls, worst case scenario.
				found = IsSpotSafe(clientIdx, testPos, sizeMultiplier);
			}
		}
	}
	
	if (!found)
		return false;
	
	TeleportEntity(clientIdx, testPos, NULL_VECTOR, NULL_VECTOR);
	
	return true;
}