static const char PuddleModel[] = "models/props_farm/haypile001.mdl";
static const char DeathModel[] = "models/scp_new/173/scp_173new_death.mdl";

static const char SnapSound[] = "freak_fortress_2/scp173/scp173_kill2.mp3";
static const char DeathSound[] = "freak_fortress_2/scp173/173_death.wav";
static const char MoveSound[] = "physics/concrete/concrete_scrape_smooth_loop1.wav";

static const int HealthMax = 2000;	// Max standard health
static const int HealthExtra = 1500;	// Max regenerable health
static const int HealthKill = 150;	// Health gain on stunned kill

static const float DistanceMax = 1250.0;	// Teleport distance while in speed
static const float DistanceMin = 750.0;	// Teleport distance

static int Health[MAXTF2PLAYERS];
static int ModelRef[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};
static float BlinkExpire[MAXTF2PLAYERS];
static float BlinkCharge[MAXTF2PLAYERS];
static bool Frozen[MAXTF2PLAYERS];

public bool SCP173_Create(int client)
{
	Classes_VipSpawn(client);

	Health[client] = HealthMax;
	BlinkExpire[client] = 0.0;
	BlinkCharge[client] = 0.0;
	Frozen[client] = false;

	SetEntProp(client, Prop_Send, "m_bForcedSkin", true);
	SetEntProp(client, Prop_Send, "m_nForcedSkin", (client % 11));	// Skin 0 to 10
	SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", true);

	int weapon = SpawnWeapon(client, "tf_weapon_flamethrower", 594, 90, 13, "", 1, true);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 17);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 50.0);
	}

	weapon = SpawnWeapon(client, "tf_weapon_jar_gas", 1180, 90, 13, "874 ; 0.5 ; 2059 ; 9000", 1, true);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 17);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
	}

	weapon = SpawnWeapon(client, "tf_weapon_fists", 593, 90, 13, "6 ; 0.4 ; 15 ; 0 ; 138 ; 11 ; 236 ; 1 ; 252 ; 0 ; 275 ; 1 ; 362 ; 1 ; 412 ; 0.8 ; 698 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 17);
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		// no crouching
		TF2Attrib_SetByDefIndex(weapon, 820, 1.0);		
	}

	CreateTimer(15.0, Timer_UpdateClientHud, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return false;
}

public void SCP173_OnMaxHealth(int client, int &health)
{
	health = Health[client] + HealthExtra;

	int current = GetClientHealth(client);
	if(current > health)
	{
		SetEntityHealth(client, health);
	}
	else if(current < Health[client]-HealthExtra)
	{
		Health[client] = current+HealthExtra;
	}
}

public void SCP173_OnSpeed(int client, float &speed)
{
	if(Frozen[client])
	{
		speed = 1.0;
	}
	else if(TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
	{
		speed *= 1.1;	// 1.485 multi in total
	}
}

public void SCP173_OnKill(int client, int victim)
{
	GiveAchievement(Achievement_Death173, victim);
	EmitSoundToAll(SnapSound, victim, SNDCHAN_BODY, SNDLEVEL_SCREAMING, _, _, _, client);
	if(TF2_IsPlayerInCondition(victim, TFCond_Dazed))
		SetEntityHealth(client, GetClientHealth(client) + HealthKill);
}

public void SCP173_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);

	Classes_PlayDeathAnimation(client, DeathModel, "death", DeathSound, 0.0);
}

public Action SCP173_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		return Plugin_Handled;
	}
	else if(StrContains(sample, "footsteps", false) != -1)
	{
		// need to stop sound twice here on different channels or it gets stuck looping
		if (channel != SNDCHAN_AUTO)
			StopSound(client, channel, sample);		
		StopSound(client, SNDCHAN_AUTO, sample);
		
		if(!Frozen[client])
			EmitSoundToAll(MoveSound, client, channel, level+30, flags, volume, pitch+10, _, _, _, _, 0.6);

		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void SCP173_OnButton(int client, int button)
{
	static float pos1[3], ang1[3], pos2[3], ang2[3], ang3[3];
	float engineTime = GetGameTime();
	static float delay[MAXTF2PLAYERS];
	if(delay[client] < engineTime)
	{
		delay[client] = engineTime+0.2;

		bool rageDrain = view_as<bool>(GetEntProp(client, Prop_Send, "m_bRageDraining"));
		if(!rageDrain)
		{
			float rage = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
			if(rage < 100.0)
			{
				rage += 0.444444;	// 45 seconds recharge time
				if(rage > 100.0)
					rage = 100.0;

				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rage);
			}
		}

		GetClientEyePosition(client, pos1);
		GetClientEyeAngles(client, ang1);
		ang1[0] = fixAngle(ang1[0]);
		ang1[1] = fixAngle(ang1[1]);

		float players;
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || !IsValidClient(target) || IsSpec(target) || IsFriendly(Client[client].Class, Client[target].Class))
				continue;

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
			TR_TraceRayFilter(pos2, pos1, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);
			TR_GetEndPosition(ang3);
			if(ang3[0]!=pos1[0] || ang3[1]!=pos1[1] || ang3[2]!=pos1[2])
				continue;

			// success
			players += 1.0;
		}

		if(players)
		{
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", pos1);
			pos1[0] = 0.0;
			pos1[1] = 0.0;
			if(pos1[2] > 0.0)
				pos1[2] = 0.0;

			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, pos1);

			if(!Frozen[client])
			{
				Frozen[client] = true;
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
				SetEntProp(client, Prop_Send, "m_bUseClassAnimations", false);
				SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false);
				SDKCall_SetSpeed(client);

				if(rageDrain)
				{
					SetEntProp(client, Prop_Send, "m_bRageDraining", false);
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
				}
			}

			BlinkExpire[client] = engineTime + 3.0;
			BlinkCharge[client] += 5.6;
			if(BlinkCharge[client] > 100.0)
				BlinkCharge[client] = 100.0;
		}
		else
		{
			if(BlinkExpire[client] < engineTime)
				BlinkCharge[client] = 0.0;

			if(Frozen[client])
			{
				Frozen[client] = false;
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
				SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
				SetEntProp(client, Prop_Send, "m_bCustomModelRotates", true);
				SDKCall_SetSpeed(client);
			}
		}

		if(!(GetClientButtons(client) & IN_SCORE))
		{
			if(BlinkCharge[client] >= 100.0)
			{
				SetHudTextParams(-1.0, -1.0, 0.35, 255, 0, 0, 255, 0, 1.0, 0.01, 0.5);
				ShowSyncHudText(client, HudPlayer, players ? "ATTACK2" : "100%%");
			}
			else if(players)
			{
				SetHudTextParams(-1.0, -1.0, 0.35, 255, 255, 255, 255, 0, 1.0, 0.01, 2.5);
				ShowSyncHudText(client, HudPlayer, "%.0f%%", BlinkCharge[client]);
			}
		}
	}
	else if(BlinkCharge[client] >= 100.0)
	{
		GetClientEyePosition(client, pos1);
		GetClientEyeAngles(client, ang1);
	}

	if(button & IN_ATTACK3)
	{
		if(!Frozen[client] && GetEntPropFloat(client, Prop_Send, "m_flRageMeter")>=100.0)
		{
			SetEntProp(client, Prop_Send, "m_bRageDraining", true);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 10.0);
		}
	}

	if((button & IN_RELOAD) && (GetEntityFlags(client) & FL_ONGROUND) && GetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", 1) >= 100.0)
	{
		int entity = CreateEntityByName("prop_dynamic_override");
		if(IsValidEntity(entity))
		{
			SetEntityModel(entity, PuddleModel);
			DispatchSpawn(entity);

			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);

			GetClientAbsOrigin(client, pos1);
			pos1[2] -= 12.0;
			TeleportEntity(entity, pos1, NULL_VECTOR, NULL_VECTOR);

			SetEntityRenderColor(entity, 15, 15, 25);

			DataPack pack;
			CreateDataTimer(0.25, SCP173_PuddleTimer, pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(EntIndexToEntRef(entity));
			pack.WriteCell(Client[client].Class);
			pack.WriteCell(720);

			SetEntPropFloat(client, Prop_Send, "m_flItemChargeMeter", 0.0, 1);
			EmitGameSoundToAll("Concrete.BulletImpact", entity);
		}
	}

	if(BlinkCharge[client] >= 100.0 && !GetEntProp(client, Prop_Send, "m_bUseClassAnimations"))
	{
		GetClientEyePosition(client, pos1);
		GetClientEyeAngles(client, ang1);
		if(DPT_TryTeleport(client, TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly) ? DistanceMax : DistanceMin, pos1, ang1, pos2))
		{
			if(button & IN_ATTACK2)
			{
				BlinkCharge[client] = 0.0;
				TeleportEntity(client, pos2, NULL_VECTOR, NULL_VECTOR);

				int victim;
				float distance = 10000.0;
				for(int target=1; target<=MaxClients; target++)
				{
					if(target==client || IsInvuln(target) || IsFriendly(Client[client].Class, Client[target].Class))
						continue;

					GetClientEyePosition(target, pos1);
					GetClientEyeAngles(target, ang2);
					float dist = GetVectorDistance(pos1, pos2, true);
					if(dist < distance)
					{
						victim = target;
						distance = dist;
					}

					GetVectorAnglesTwoPoints(pos1, pos2, ang3);

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
					TR_TraceRayFilter(pos1, pos2, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);
					TR_GetEndPosition(ang3);
					if(ang3[0]!=pos2[0] || ang3[1]!=pos2[1] || ang3[2]!=pos2[2])
						continue;

					// success
					FadeMessage(target, 52, 52, 0x0002, 0, 0, 0);
				}

				if(victim)
					SDKHook_DealDamage(victim, client, client, 65.0, DMG_GENERIC, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), ang1, pos2);
			}
			else
			{
				int entity = EntRefToEntIndex(ModelRef[client]);
				if(entity <= MaxClients)
				{
					entity = CreateEntityByName("prop_dynamic_override");
					if(!IsValidEntity(entity))
						return;

					DispatchKeyValue(entity, "skin", "0");

					static char model[PLATFORM_MAX_PATH];
					GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
					DispatchKeyValue(entity, "model", model);
					DispatchSpawn(entity);

					SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
					SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
					SetEntityRenderMode(entity, RENDER_TRANSALPHA);
					SetEntityRenderColor(entity, 255, 55, 55, 155);

					SDKHook(entity, SDKHook_SetTransmit, SCP173_SetTransmit);

					ModelRef[client] = EntIndexToEntRef(entity);
				}

				TeleportEntity(entity, pos2, ang1, NULL_VECTOR);
				return;
			}
		}
	}

	if(ModelRef[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(ModelRef[client]);
		if(entity > MaxClients)
			RemoveEntity(entity);

		ModelRef[client] = INVALID_ENT_REFERENCE;
	}
}

public Action SCP173_SetTransmit(int entity, int target)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==target ? Plugin_Continue : Plugin_Stop;
}

public Action SCP173_PuddleTimer(Handle timer, DataPack pack)
{
	pack.Reset();
	int entity = EntRefToEntIndex(pack.ReadCell());
	if(entity > MaxClients)
	{
		static float pos1[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos1);
		int class = pack.ReadCell();
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && !IsFriendly(class, Client[target].Class))
			{
				static float pos2[3];
				GetClientAbsOrigin(target, pos2);
				if(GetVectorDistance(pos1, pos2, true) < 2300.0)
					TF2_StunPlayer(target, 3.0, 0.2, TF_STUNFLAG_SLOWDOWN);
			}
		}

		class = pack.ReadCell();
		if(class > 0)
		{
			pack.Position--;
			pack.WriteCell(class-1, false);
			return Plugin_Continue;
		}

		RemoveEntity(entity);
	}
	return Plugin_Stop;
}

// From ff2_dynamic_defaults by sarysa
public bool DPT_TracePlayersAndBuildings(int entity, int contentsMask, any data)
{
	if(entity>0 && entity<=MaxClients)
		return false;

	return IsValidEntity(entity);
}

static bool DPT_TryTeleport(int clientIdx, float maxDistance, const float startPos[3], const float eyeAngles[3], float testPos[3])
{
	float sizeMultiplier = GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale");
	static float endPos[3];
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, DPT_TracePlayersAndBuildings);
	TR_GetEndPosition(endPos);
	
	// don't even try if the distance is less than 82
	float distance = GetVectorDistance(startPos, endPos);
	if (distance < 82.0)
		return false;
		
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
				TR_TraceRayFilter(endPos, testPos, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);
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
	
	return true;
}