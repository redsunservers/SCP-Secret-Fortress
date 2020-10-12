void SDKHook_Setup()
{
	AddNormalSoundHook(HookSound);
}

void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

void SDKHook_HookCapture(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnCPTouch);
	SDKHook(entity, SDKHook_Touch, OnCPTouch);
}

void SDKHook_HookFlag(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnFlagTouch);
	SDKHook(entity, SDKHook_Touch, OnFlagTouch);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_healthkit") != -1)
	{
		SDKHook(entity, SDKHook_Spawn, StrEqual(classname, "item_healthkit_medium") ? OnMedSpawned : OnKitSpawned);
		return;
	}
	else if(Ready && StrEqual(classname, "tf_projectile_pipe"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnPipeSpawned);
	}
	else if(Enabled && !StrContains(classname, "obj_"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnObjDamage);
	}
}

public void OnKitSpawned(int entity)
{
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToCeil((GetEngineTime()+0.75)*10.0));
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnKitPickup);
}

public void OnMedSpawned(int entity)
{
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToFloor((GetEngineTime()+2.25)*10.0));
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnKitPickup);
}

public Action OnKitPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(StrContains(classname, "item_healthkit") == -1)
	{
		SDKUnhook(entity, SDKHook_Touch, OnKitPickup);
		return Plugin_Continue;
	}

	float time = GetEntProp(entity, Prop_Data, "m_iHammerID")/10.0;
	if(IsSCP(client) || Client[client].Disarmer || time>GetEngineTime())
		return Plugin_Handled;

	if(StrEqual(classname, "item_healthkit_full") || (time+0.3)>GetEngineTime())
	{
		int health;
		OnGetMaxHealth(client, health);
		if(health <= GetClientHealth(client))
			return Plugin_Handled;

		SDKUnhook(entity, SDKHook_Touch, OnKitPickup);
		return Plugin_Continue;
	}

	if(Client[client].HealthPack)
		return Plugin_Handled;

	Client[client].HealthPack = StrEqual(classname, "item_healthkit_small") ? 1 : 2;
	AcceptEntityInput(entity, "Kill");
	return Plugin_Handled;
}

public Action OnPipeSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnPipeTouch);
	return Plugin_Continue;
}

public Action OnPipeTouch(int entity, int client)
{
	return (IsValidClient(client)) ? Plugin_Handled : Plugin_Continue;
}

public Action OnObjDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Enabled && IsValidClient(attacker) && !CvarFriendlyFire.BoolValue)
	{
		if(TF2_GetTeam(entity) == Client[attacker].TeamTF())
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled)
		return Plugin_Continue;

	float engineTime = GetEngineTime();
	if(Client[victim].InvisFor > engineTime)
		return Plugin_Handled;

	if(!IsValidClient(attacker))
	{
		if(damagetype & DMG_FALL)
		{
			if(Client[victim].Class==Class_173 || Client[victim].Class==Class_1732)
				return Plugin_Handled;

			//damage = IsSCP(victim) ? damage*0.01 : Pow(damage, 1.25);
			damage = IsSCP(victim) ? damage*0.02 : damage*5.0;
			return Plugin_Changed;
		}
		else if(damagetype & DMG_CRUSH)
		{
			static float delay[MAXTF2PLAYERS];
			if(delay[victim] > engineTime)
				return Plugin_Handled;

			delay[victim] = engineTime+0.05;
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}

	if(victim == attacker)
		return Plugin_Continue;

	if(!CvarFriendlyFire.BoolValue)
	{
		if(!IsFakeClient(victim) && IsFriendly(Client[victim].Class, Client[attacker].Class))
			return Plugin_Handled;

		if(Client[victim].Disarmer && Client[victim].Disarmer!=attacker && IsFriendly(Client[Client[victim].Disarmer].Class, Client[attacker].Class))
			return Plugin_Handled;
	}

	if(IsValidEntity(weapon) && weapon>MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index == WeaponIndex[Weapon_Disarm])
		{
			if(!IsSCP(victim))
			{
				bool cancel;
				if(!Client[victim].Disarmer)
				{
					int weapon2 = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
					cancel = (weapon2>MaxClients && IsValidEntity(weapon2) && HasEntProp(weapon2, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon2, Prop_Send, "m_iItemDefinitionIndex")!=WeaponIndex[Weapon_None]);

					if(!cancel)
					{
						TF2_AddCondition(victim, TFCond_PasstimePenaltyDebuff);
						BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", victim));
						if(bf != null)
						{
							char buffer[64];
							FormatEx(buffer, sizeof(buffer), "%T", "disarmed", victim);
							bf.WriteString(buffer);
							bf.WriteString("ico_notify_flag_moving_alt");
							bf.WriteByte(view_as<int>(TFTeam_Red));
							EndMessage();
						}

						DropAllWeapons(victim);
						Client[victim].HealthPack = 0;
						TF2_RemoveAllWeapons(victim);
						SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", GiveWeapon(victim, Weapon_None));
					}
				}

				if(!cancel)
				{
					Client[victim].Disarmer = attacker;
					return Plugin_Handled;
				}
			}
		}
		else if(index == WeaponIndex[Weapon_Flash])
		{
			FadeMessage(victim, 36, 768, 0x0012);
			FadeClientVolume(victim, 1.0, 2.0, 2.0, 0.2);
		}
	}

	switch(Client[victim].Class)
	{
		case Class_096:
		{
			if(!Client[attacker].Triggered && !TF2_IsPlayerInCondition(victim, TFCond_Dazed))
				TriggerShyGuy(victim, attacker, engineTime);
		}
		case Class_3008:
		{
			if(!Client[victim].Radio)
			{
				Client[victim].Radio = 1;
				TF2_RemoveWeaponSlot(victim, TFWeaponSlot_Melee);
				SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", GiveWeapon(victim, Weapon_3008Rage));
			}
		}
	}

	switch(Client[attacker].Class)
	{
		case Class_096:
		{
			if(!Client[victim].Triggered)
				return Plugin_Handled;
		}
		case Class_106:
		{
			SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);

			int entity = -1;
			static char name[16];
			static int spawns[4];
			int count;
			while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
			{
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(!StrContains(name, "scp_pocket", false))
					spawns[count++] = entity;

				if(count > 3)
					break;
			}

			if(!count)
			{
				if(!GetRandomInt(0, 2))
					return Plugin_Continue;

				damagetype |= DMG_CRIT;
				return Plugin_Changed;
			}

			entity = spawns[GetRandomInt(0, count-1)];

			static float pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(victim, pos, NULL_VECTOR, TRIPLE_D);
		}
		case Class_Stealer:
		{
			if(Client[victim].Triggered)
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!Enabled || !IsValidClient(entity))
		return Plugin_Continue;

	if(!StrContains(sample, "vo", false))
		return (IsSCP(entity) || IsSpec(entity)) ? Plugin_Handled : Plugin_Continue;

	if(StrContains(sample, "step", false) != -1)
	{
		if(IsSCP(entity) || Client[entity].Sprinting)
		{
			if(Client[entity].Class == Class_Stealer)
				Config_GetSound(Sound_ItSteps, sample, PLATFORM_MAX_PATH);

			volume = 1.0;
			level += 30;
			return Plugin_Changed;
		}

		if(Gamemode == Gamemode_Steals)
			return Plugin_Stop;

		int flag = GetEntityFlags(entity);
		if((flag & FL_DUCKING) && (flag & FL_ONGROUND))
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action OnTransmit(int client, int target)
{
	if(!Enabled || client==target || !IsValidClient(target) || IsClientObserver(target) || TF2_IsPlayerInCondition(target, TFCond_HalloweenGhostMode))
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return Plugin_Stop;

	float engineTime = GetEngineTime();
	if(Client[client].InvisFor > engineTime)
		return Plugin_Stop;

	if(IsSCP(client))
		return Plugin_Continue;

	if(Client[target].Class == Class_096)
		return (!Client[target].Radio || Client[client].Triggered) ? Plugin_Continue : Plugin_Stop;

	if(Client[target].Class == Class_Stealer)
		return Client[client].Triggered ? Plugin_Stop : Plugin_Continue;

	return ((Client[target].Class==Class_939 || Client[target].Class==Class_9392 || (Client[target].Class==Class_3008 && !Client[target].Radio)) && Client[client].IdleAt<engineTime) ? Plugin_Handled : Plugin_Continue;
}

public Action OnCPTouch(int entity, int client)
{
	if(IsValidClient(client))
		Client[client].IsCapping = GetGameTime()+0.15;

	return Plugin_Continue;
}

public Action OnFlagTouch(int entity, int client)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	return (Client[client].Class==Class_DBoi || Client[client].Class==Class_Scientist) ? Plugin_Continue : Plugin_Handled;
}

public Action OnGetMaxHealth(int client, int &health)
{
	if(!Enabled)
		return Plugin_Continue;

	switch(Client[client].Class)
	{
		case Class_MTF2, Class_MTFS, Class_MTFE, Class_Chaos:
		{
			health = 150;
		}
		case Class_MTF3:
		{
			health = 200; //187.5
		}
		case Class_049:
		{
			health = 2125;
		}
		case Class_0492:
		{
			health = 375;
		}
		case Class_076:
		{
			health = 1500;
		}
		case Class_096:
		{
			health = Client[client].HealthPack + (Client[client].Disarmer*250);

			int current = GetClientHealth(client);
			if(current > health)
			{
				SetEntityHealth(client, health);
			}
			else if(current < Client[client].HealthPack-250)
			{
				Client[client].HealthPack = current+250;
			}
		}
		case Class_106:
		{
			health = 800; //812.5
		}
		case Class_173:
		{
			health = 4000;
		}
		case Class_1732:
		{
			health = 800;
		}
		case Class_939, Class_9392:
		{
			health = 2750;
		}
		case Class_3008:
		{
			health = 500;
		}
		case Class_Stealer:
		{
			switch(Client[client].Radio)
			{
				case -1:
				{
					health = ((DClassMax+SciMax)*2)+6;
					SetEntityHealth(client, 1);
				}
				case 1:
				{
					health = 66;
					SetEntityHealth(client, 66);
				}
				case 2:
				{
					health = 666;
					SetEntityHealth(client, 666);
				}
				default:
				{
					if(SciEscaped < -1)
					{
						ForcePlayerSuicide(client);

						for(int i=1; i<=MaxClients; i++)
						{
							if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==view_as<int>(TFTeam_Red))
								ChangeClientTeamEx(i, TFTeam_Blue);
						}

						EndRound(Team_MTF, TFTeam_Blue);
						return Plugin_Continue;
					}

					health = ((DClassMax+SciMax)*2)+6;
					SetEntityHealth(client, SciEscaped+2);
				}
			}
		}
		default:
		{
			health = 125;
		}
	}
	return Plugin_Changed;
}

public void OnPreThink(int client)
{
	if(!Enabled || !IsPlayerAlive(client))
		return;

	float engineTime = GetEngineTime();
	if(Client[client].InvisFor > engineTime+2.0)
	{
		if(Client[client].InvisFor < engineTime)
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
			return;
		}
		
		TF2_RemoveCondition(client, TFCond_Taunting);
		return;
	}

	static float clientPos[3], enemyPos[3];
	static char buffer[PLATFORM_MAX_PATH];
	if(Gamemode==Gamemode_Steals && Client[client].HealthPack)
	{
		int entity = EntRefToEntIndex(Client[client].HealthPack);
		if(entity>MaxClients && IsValidEntity(entity))
		{
			GetClientEyeAngles(client, clientPos);
			GetClientAbsAngles(client, enemyPos);
			SubtractVectors(clientPos, enemyPos, clientPos);
			TeleportEntity(entity, NULL_VECTOR, clientPos, NULL_VECTOR);
		}
		else
		{
			Client[client].HealthPack = 0;
		}
	}

	if(Client[client].InvisFor>engineTime || (Client[client].Class>Class_DBoi && RoundStartAt>engineTime))
	{
		SetSpeed(client, 1.0);
	}
	else
	{
		switch(Client[client].Class)
		{
			case Class_Spec:
			{
				SetSpeed(client, 360.0);
			}
			case Class_DBoi, Class_Scientist:
			{
				if(Gamemode == Gamemode_Steals)
				{
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", Client[client].IdleAt>engineTime);
					SetSpeed(client, Client[client].Sprinting ? 360.0 : 270.0);
				}
				else
				{
					SetSpeed(client, Client[client].Disarmer ? 230.0 : Client[client].Sprinting ? 310.0 : 260.0);
				}
			}
			case Class_Chaos, Class_MTFE:
			{
				SetSpeed(client, (Client[client].Sprinting && !Client[client].Disarmer) ? 270.0 : 230.0);
			}
			case Class_MTF3:
			{
				SetSpeed(client, Client[client].Disarmer ? 230.0 : Client[client].Sprinting ? 280.0 : 240.0);
			}
			case Class_Guard, Class_MTF, Class_MTF2, Class_MTFS:
			{
				SetSpeed(client, Client[client].Disarmer ? 230.0 : Client[client].Sprinting ? 290.0 : 250.0);
			}
			case Class_049:
			{
				SetSpeed(client, 250.0);
			}
			case Class_0492, Class_3008:
			{
				SetSpeed(client, 270.0);
			}
			case Class_076:
			{
				switch(Client[client].Radio)
				{
					case 0:
						SetSpeed(client, 240.0);

					case 1:
						SetSpeed(client, 245.0);

					case 2:
						SetSpeed(client, 250.0);

					case 3:
						SetSpeed(client, 255.0);

					default:
						SetSpeed(client, 275.0);
				}
			}
			case Class_096:
			{
				switch(Client[client].Radio)
				{
					case 1:
					{
						SetSpeed(client, 230.0);
						if(Client[client].Power < engineTime)
						{
							TF2_AddCondition(client, TFCond_CritCola, 99.9);
							TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096Rage));
							Client[client].Power = engineTime+(Client[client].Disarmer*2.0)+13.0;
							Client[client].Keycard = Keycard_106;
							Client[client].Radio = 2;
						}
					}
					case 2:
					{
						TF2_RemoveCondition(client, TFCond_Dazed);
						SetSpeed(client, 520.0);
						if(Client[client].Power < engineTime)
						{
							TF2_RemoveCondition(client, TFCond_CritCola);
							TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GiveWeapon(client, Weapon_096));
							Client[client].Disarmer = 0;
							Client[client].Radio = 0;
							Client[client].Keycard = Keycard_SCP;
							Client[client].Power = engineTime+15.0;
							TF2_StunPlayer(client, 6.0, 0.9, TF_STUNFLAG_SLOWDOWN);
							Config_GetSound(Sound_Screams, buffer, sizeof(buffer));
							StopSound(client, SNDCHAN_VOICE, buffer);
							StopSound(client, SNDCHAN_VOICE, buffer);

							bool another096;
							for(int i=1; i<=MaxClients; i++)
							{
								if(Client[i].Class!=Class_096 || !Client[client].Radio)
									continue;

								another096 = true;
								break;
							}

							if(!another096)
							{
								for(int i; i<MAXTF2PLAYERS; i++)
								{
									Client[i].Triggered = false;
								}
							}
						}
					}
					default:
					{
						SetSpeed(client, 230.0);
						if(Client[client].Power > engineTime)
							return;

						if(Client[client].IdleAt < engineTime)
						{
							if(Client[client].Pos[0])
							{
								Config_GetSound(Sound_096, buffer, sizeof(buffer));
								StopSound(client, SNDCHAN_VOICE, buffer);
								StopSound(client, SNDCHAN_VOICE, buffer);
								Client[client].Pos[0] = 0.0;
							}
						}
						else if(!Client[client].Pos[0])
						{
							Config_GetSound(Sound_096, buffer, sizeof(buffer));
							EmitSoundToAll(buffer, client, SNDCHAN_VOICE, SNDLEVEL_SCREAMING, _, _, _, client);
							Client[client].Pos[0] = 1.0;
						}
					}
				}
			}
			case Class_106:
			{
				SetSpeed(client, 240.0);
			}
			case Class_173:
			{
				switch(Client[client].Radio)
				{
					case 1:
					{
						if(GetEntityMoveType(client) != MOVETYPE_NONE)
						{
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								SetEntityMoveType(client, MOVETYPE_NONE);
							}
							else
							{
								SetSpeed(client, 1.0);
								static float vel[3];
								vel[2] = -500.0;
								TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
							}
						}
					}
					case 2:
					{
						SetSpeed(client, 3000.0);
					}
					default:
					{
						SetSpeed(client, 420.0);
					}
				}
			}
			case Class_1732:
			{
				switch(Client[client].Radio)
				{
					case 1:
					{
						if(GetEntityMoveType(client) != MOVETYPE_NONE)
						{
							static float vel[3];
							if(GetEntityFlags(client) & FL_ONGROUND)
							{
								vel[2] = 0.0;
								TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
								SetEntityMoveType(client, MOVETYPE_NONE);
							}
							else
							{
								vel[2] = -500.0;
								TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
								SetSpeed(client, 1.0);
							}
						}
					}
					case 2:
					{
						SetSpeed(client, 2600.0);
					}
					default:
					{
						SetSpeed(client, 450.0);
					}
				}
			}
			case Class_939, Class_9392:
			{
				SetSpeed(client, 300.0-(GetClientHealth(client)/55.0));
			}
			case Class_Stealer:
			{
				switch(Client[client].Radio)
				{
					case 1:
					{
						SetSpeed(client, 400.0);
						if(Client[client].Power > engineTime)
							return;

						TurnOffGlow(client);
						Client[client].Radio = 0;
						TF2_RemoveCondition(client, TFCond_CritCola);
					}
					case 2:
					{
						SetSpeed(client, 500.0);
						return;
					}
					default:
					{
						SetSpeed(client, 350.0+((SciEscaped/(SciMax+DClassMax)*50.0)));
						GetClientAbsOrigin(client, clientPos);
						for(int target=1; target<=MaxClients; target++)
						{
							if(!Client[target].Triggered)
								continue;

							if(IsValidClient(target) && !IsSpec(target) && !IsSCP(target))
							{
								GetClientAbsOrigin(target, enemyPos);
								if(GetVectorDistance(clientPos, enemyPos, true) < 1000000)
									continue;
							}
							Client[target].Triggered = false;
						}

						if(Client[client].IdleAt+5.0 < engineTime)
						{
							SciEscaped--;
							Client[client].IdleAt = engineTime+2.5;
						}
					}
				}
			}
		}
	}

	static float specialTick[MAXTF2PLAYERS];
	if(specialTick[client] > engineTime)
		return;

	static float clientAngles[3], enemyAngles[3], anglesToBoss[3], result[3];
	bool showHud = (Client[client].HudIn<engineTime && !(GetClientButtons(client) & IN_SCORE));
	specialTick[client] = engineTime+0.2;
	switch(Client[client].Class)
	{
		case Class_Spec:
		{
			ClientCommand(client, "firstperson");
		}
		case Class_076:
		{
			TF2_RemoveCondition(client, TFCond_DemoBuff);
			SetEntProp(client, Prop_Send, "m_iDecapitations", Client[client].Radio);
		}
		case Class_096:
		{
			GetClientEyePosition(client, clientPos);
			GetClientEyeAngles(client, clientAngles);
			clientAngles[0] = fixAngle(clientAngles[0]);
			clientAngles[1] = fixAngle(clientAngles[1]);

			int status;
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target) || Client[target].Triggered)
					continue;

				GetClientEyePosition(target, enemyPos);
				if(GetVectorDistance(clientPos, enemyPos) > 700)
					continue;

				GetClientEyeAngles(target, enemyAngles);
				GetVectorAnglesTwoPoints(enemyPos, clientPos, anglesToBoss);

				// fix all angles
				enemyAngles[0] = fixAngle(enemyAngles[0]);
				enemyAngles[1] = fixAngle(enemyAngles[1]);
				anglesToBoss[0] = fixAngle(anglesToBoss[0]);
				anglesToBoss[1] = fixAngle(anglesToBoss[1]);

				// verify angle validity
				if(!(fabs(enemyAngles[0] - anglesToBoss[0]) <= MAXANGLEPITCH ||
				(fabs(enemyAngles[0] - anglesToBoss[0]) >= (360.0-MAXANGLEPITCH))))
					continue;

				if(!(fabs(enemyAngles[1] - anglesToBoss[1]) <= MAXANGLEYAW ||
				(fabs(enemyAngles[1] - anglesToBoss[1]) >= (360.0-MAXANGLEYAW))))
					continue;

				// ensure no wall is obstructing
				TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
					continue;

				GetVectorAnglesTwoPoints(clientPos, enemyPos, anglesToBoss);

				// fix all angles
				anglesToBoss[0] = fixAngle(anglesToBoss[0]);
				anglesToBoss[1] = fixAngle(anglesToBoss[1]);

				// verify angle validity
				if(!(fabs(clientAngles[0] - anglesToBoss[0]) <= MAXANGLEPITCH ||
				(fabs(clientAngles[0] - anglesToBoss[0]) >= (360.0-MAXANGLEPITCH))))
					continue;

				if(!(fabs(clientAngles[1] - anglesToBoss[1]) <= MAXANGLEYAW ||
				(fabs(clientAngles[1] - anglesToBoss[1]) >= (360.0-MAXANGLEYAW))))
					continue;

				// ensure no wall is obstructing
				TR_TraceRayFilter(clientPos, enemyPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=enemyPos[0] || result[1]!=enemyPos[1] || result[2]!=enemyPos[2])
					continue;

				// success
				status = target;
				break;
			}

			if(status)
				TriggerShyGuy(client, status, engineTime);
		}
		case Class_106:
		{
			if(Client[client].ChargeIn && Client[client].ChargeIn<engineTime)
			{
				Client[client].ChargeIn = 0.0;
				TeleportEntity(client, Client[client].Pos, NULL_VECTOR, TRIPLE_D);
			}
			else if(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2])
			{
				GetClientEyePosition(client, clientPos);
				if(Client[client].Radio)
				{
					if(GetVectorDistance(clientPos, Client[client].Pos) > 400)
						HideAnnotation(client);
				}
				else if(GetVectorDistance(clientPos, Client[client].Pos) < 300)
				{
					ShowAnnotation(client);
				}
			}
		}
		case Class_173, Class_1732:
		{
			static int blink;
			GetClientEyePosition(client, clientPos);

			GetClientEyeAngles(client, clientAngles);
			clientAngles[0] = fixAngle(clientAngles[0]);
			clientAngles[1] = fixAngle(clientAngles[1]);

			int status;
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target))
					continue;

				GetClientEyePosition(target, enemyPos);
				GetClientEyeAngles(target, enemyAngles);
				GetVectorAnglesTwoPoints(enemyPos, clientPos, anglesToBoss);

				// fix all angles
				enemyAngles[0] = fixAngle(enemyAngles[0]);
				enemyAngles[1] = fixAngle(enemyAngles[1]);
				anglesToBoss[0] = fixAngle(anglesToBoss[0]);
				anglesToBoss[1] = fixAngle(anglesToBoss[1]);

				// verify angle validity
				if(!(fabs(enemyAngles[0] - anglesToBoss[0]) <= MAXANGLEPITCH ||
				(fabs(enemyAngles[0] - anglesToBoss[0]) >= (360.0-MAXANGLEPITCH))))
					continue;

				if(!(fabs(enemyAngles[1] - anglesToBoss[1]) <= MAXANGLEYAW ||
				(fabs(enemyAngles[1] - anglesToBoss[1]) >= (360.0-MAXANGLEYAW))))
					continue;

				// ensure no wall is obstructing
				TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
					continue;

				// success
				if(!blink)
				{
					status = 2;
					FadeMessage(target, 52, 52, 0x0002, 0, 0, 0);
				}
				else
				{
					status = 1;
				}
			}

			if(blink > 0)
			{
				blink--;
			}
			else
			{
				blink = GetRandomInt(10, 20);
			}

			switch(status)
			{
				case 1:
				{
					Client[client].Radio = 1;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
					SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
				}
				case 2:
				{
					Client[client].Radio = 2;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
					SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
					if(GetEntityMoveType(client) != MOVETYPE_WALK)
						SetEntityMoveType(client, MOVETYPE_WALK);
				}
				default:
				{
					Client[client].Radio = 0;
					SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
					SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
					if(GetEntityMoveType(client) != MOVETYPE_WALK)
						SetEntityMoveType(client, MOVETYPE_WALK);
				}
			}
		}
		case Class_Stealer:
		{
			GetClientEyePosition(client, clientPos);
			GetClientEyeAngles(client, clientAngles);
			clientAngles[0] = fixAngle(clientAngles[0]);
			clientAngles[1] = fixAngle(clientAngles[1]);

			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target) || !Client[target].HealthPack || Client[target].Triggered)
					continue;

				GetClientEyePosition(target, enemyPos);
				if(GetVectorDistance(clientPos, enemyPos, true) > 125000)
					continue;

				GetClientEyeAngles(target, enemyAngles);
				GetVectorAnglesTwoPoints(enemyPos, clientPos, anglesToBoss);

				// fix all angles
				enemyAngles[0] = fixAngle(enemyAngles[0]);
				enemyAngles[1] = fixAngle(enemyAngles[1]);
				anglesToBoss[0] = fixAngle(anglesToBoss[0]);
				anglesToBoss[1] = fixAngle(anglesToBoss[1]);

				// verify angle validity
				if(!(fabs(enemyAngles[0] - anglesToBoss[0]) <= MAXANGLEPITCH ||
				(fabs(enemyAngles[0] - anglesToBoss[0]) >= (360.0-MAXANGLEPITCH))))
					continue;

				if(!(fabs(enemyAngles[1] - anglesToBoss[1]) <= MAXANGLEYAW ||
				(fabs(enemyAngles[1] - anglesToBoss[1]) >= (360.0-MAXANGLEYAW))))
					continue;

				// ensure no wall is obstructing
				TR_TraceRayFilter(enemyPos, clientPos, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
				TR_GetEndPosition(result);
				if(result[0]!=clientPos[0] || result[1]!=clientPos[1] || result[2]!=clientPos[2])
					continue;

				// success
				if(SciEscaped >= ((DClassMax+SciMax)*2)+4)
				{
					for(target=1; target<=MaxClients; target++)
					{
						Client[target].Triggered = false;
					}

					SCPKilled = 2;
					Client[client].Radio = 2;
					TurnOnGlow(client, "255 0 0", 10, 700.0);
					TF2_AddCondition(client, TFCond_CritCola);
					Config_GetSound(Sound_ItHadEnough, buffer, sizeof(buffer));
					ChangeGlobalSong(FAR_FUTURE, buffer);
					TF2_StunPlayer(client, 11.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
				}
				else if(!SCPKilled && SciEscaped==DClassMax+SciMax+2)
				{
					Config_GetSound(Sound_ItRages, buffer, sizeof(buffer));
					for(target=1; target<=MaxClients; target++)
					{
						if(IsValidClient(target))
							ClientCommand(target, "playgamesound %s", buffer);
					}

					SCPKilled = 1;
					Client[client].Radio = 1;
					Client[client].Power = engineTime+15.0;
					TurnOnGlow(client, "255 0 0", 10, 600.0);
					TF2_AddCondition(client, TFCond_CritCola, 15.0);
					ChangeGlobalSong(Client[client].Power, buffer);
					TF2_StunPlayer(client, 4.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
				}
				else
				{
					SciEscaped++;
					Client[target].Triggered = true;
					Config_GetSound(Sound_ItStuns, buffer, sizeof(buffer));
					ClientCommand(target, "playgamesound %s", buffer);
				}
				break;
			}
		}
		default:
		{
			if(!IsSCP(client) && !IsSpec(client))
			{
				if(Gamemode == Gamemode_Steals)
				{
					if(Client[client].Sprinting)
					{
						Client[client].SprintPower -= 1.25;
					}
					else
					{
						if(Client[client].SprintPower < 99)
							Client[client].SprintPower += 2.0;
					}

					if(Client[client].HudIn < engineTime)
					{
						if(Client[client].SprintPower > 85)
						{
							ClientCommand(client, "r_screenoverlay \"\"");
						}
						else if(Client[client].SprintPower > 70)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/almostnone.vmt");
						}
						else if(Client[client].SprintPower > 55)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/verylow.vmt");
						}
						else if(Client[client].SprintPower > 40)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/low.vmt");
						}
						else if(Client[client].SprintPower > 25)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/medium.vmt");
						}
						else if(Client[client].SprintPower > 10)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/high.vmt");
						}
						else if(Client[client].SprintPower > 0)
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/ultrahigh.vmt");
						}
						else
						{
							ClientCommand(client, "r_screenoverlay it_steals/distortion/ultrahigh.vmt");
							SetEntityHealth(client, GetClientHealth(client)-1);
						}

						if(showHud)
						{
							SetGlobalTransTarget(client);
							int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
							if(weapon>MaxClients && IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==WeaponIndex[Weapon_Disarm])
								Format(buffer, sizeof(buffer), "%t", "camera", RoundToCeil(Client[client].Power));

							SetHudTextParams(-1.0, 0.92, 0.35, 255, 255, 255, 255, 0, 0.1, 0.05, 0.05);
							if(Client[client].Radio)
							{
								ShowSyncHudText(client, HudPlayer, "%s\n%t", buffer, "radar");
							}
							else
							{
								ShowSyncHudText(client, HudPlayer, buffer);
							}
						}
					}
				}
				else
				{
					if(DisarmCheck(client))
					{
						Client[client].AloneIn = FAR_FUTURE;
						if(showHud)
						{
							SetHudTextParamsEx(-1.0, Gamemode==Gamemode_Ctf ? 0.77 : 0.88, 0.35, ClassColors[Client[Client[client].Disarmer].Class], ClassColors[Client[Client[client].Disarmer].Class], 0, 0.1, 0.05, 0.05);
							ShowSyncHudText(client, HudPlayer, "%T", "disarmed_by", client, Client[client].Disarmer);
						}
					}
					else
					{
						GetClientEyePosition(client, clientPos);
						for(int target=1; target<=MaxClients; target++)
						{
							if(!IsValidClient(target) || IsSpec(target) || IsSCP(target))
								continue;

							GetClientEyePosition(target, enemyPos);
							if(GetVectorDistance(clientPos, enemyPos) > 400)
								continue;

							//if(Client[client].AloneIn < engineTime)
								//Client[client].NextSongAt = 0.0;

							Client[client].AloneIn = engineTime+90.0;
							break;
						}

						if(Client[client].Power > 0)
						{
							switch(Client[client].Radio)
							{
								case 1:
									Client[client].Power -= 0.005;

								case 2:
									Client[client].Power -= 0.015;

								case 3:
									Client[client].Power -= 0.045;

								case 4:
									Client[client].Power -= 0.135;
							}
						}

						if(Client[client].Sprinting)
						{
							Client[client].SprintPower -= 2.0;
							if(Client[client].SprintPower <= 0)
							{
								PrintKeyHintText(client, "%t", "sprint", 0);
								Client[client].Sprinting = false;
							}
							else
							{
								PrintKeyHintText(client, "%t", "sprint", RoundToCeil(Client[client].SprintPower));
							}
						}
						else
						{
							if(Client[client].SprintPower < 100)
							{
								Client[client].SprintPower += 0.75;
								PrintKeyHintText(client, "%t", "sprint", RoundToFloor(Client[client].SprintPower));
							}
						}

						if(showHud)
						{
							SetGlobalTransTarget(client);

							char tran[16];
							if(Client[client].Power>1 && Client[client].Radio && Client[client].Radio<5)
							{
								FormatEx(tran, sizeof(tran), "radio_%d", Client[client].Radio);
								Format(buffer, sizeof(buffer), "%t", "radio", tran, RoundToCeil(Client[client].Power));
							}
							else
							{
								strcopy(buffer, sizeof(buffer), "");
							}

							switch(Client[client].HealthPack)
							{
								case 1:
									Format(buffer, sizeof(buffer), "%t\n%s", "pain_killers", buffer);

								case 2, 3:
									Format(buffer, sizeof(buffer), "%t\n%s", "health_kit", buffer);

								case 4:
									Format(buffer, sizeof(buffer), "%t\n%s", "scp_500", buffer);
							}

							FormatEx(tran, sizeof(tran), "keycard_%d", Client[client].Keycard);

							SetHudTextParamsEx(-1.0, Gamemode==Gamemode_Ctf ? 0.77 : 0.88, 0.35, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 0.1, 0.05, 0.05);
							ShowSyncHudText(client, HudPlayer, "%t\n%s", "keycard", tran, buffer);
						}
					}
				}
			}
		}
	}

	if(showHud && Gamemode!=Gamemode_Steals)
	{
		GetClassName(Client[client].Class, buffer, sizeof(buffer));
		SetHudTextParamsEx(-1.0, 0.06, 0.35, ClassColors[Client[client].Class], ClassColors[Client[client].Class], 0, 0.1, 0.05, 0.05);
		ShowSyncHudText(client, HudExtra, "%T", buffer, client);
	}

	if(!NoMusic && !NoMusicRound && Client[client].NextSongAt<engineTime)
	{
		int song;
		if(Client[client].Class == Class_Spec)
		{
			song = Music_Spec;
		}
		else if(Client[client].AloneIn < engineTime)
		{
			song = Music_Alone;
		}
		else if(Client[client].Floor == Floor_Light)
		{
			song = Music_Light;
		}
		else if(Client[client].Floor == Floor_Heavy)
		{
			song = Music_Heavy;
		}
		else if(Client[client].Floor == Floor_Surface)
		{
			song = Music_Outside;
		}

		if(song)
		{
			float duration = Config_GetMusic(song, buffer, sizeof(buffer));
			ChangeSong(client, duration+engineTime, buffer);
		}
	}
}