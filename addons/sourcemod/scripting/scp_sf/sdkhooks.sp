void SDKHook_Setup()
{
	AddNormalSoundHook(HookSound);
}

void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
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

		if(!IsSCP(victim) && Client[victim].Disarmer && Client[victim].Disarmer!=attacker && IsFriendly(Client[Client[victim].Disarmer].Class, Client[attacker].Class))
			return Plugin_Handled;
	}

	int health = GetClientHealth(victim);
	if(health>25 && (health-damage)<26)
		CreateTimer(3.0, Timer_MyBlood, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);

	bool changed;
	if(IsValidEntity(weapon) && weapon>MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index == WeaponIndex[Weapon_Disarm])
		{
			if(!IsSCP(victim) && !IsFriendly(Client[victim].Class, Client[attacker].Class))
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
							FormatEx(buffer, sizeof(buffer), "%T", "disarmed", attacker);
							bf.WriteString(buffer);
							bf.WriteString("ico_notify_flag_moving_alt");
							bf.WriteByte(view_as<int>(TFTeam_Red));
							EndMessage();
						}

						DropAllWeapons(victim);
						Client[victim].HealthPack = 0;
						TF2_RemoveAllWeapons(victim);
						SetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon", GiveWeapon(victim, Weapon_None));

						if(Client[victim].Class>=Class_Guard && Client[victim].Class<=Class_MTFE)
							GiveAchievement(Achievement_DisarmMTF, attacker);
					}
				}

				if(!cancel)
				{
					Client[victim].Disarmer = attacker;
					SDKCall_SetSpeed(victim);
					return Plugin_Handled;
				}
			}
		}
		else if(index == WeaponIndex[Weapon_Flash])
		{
			FadeMessage(victim, 36, 768, 0x0012);
			FadeClientVolume(victim, 1.0, 2.0, 2.0, 0.2);
		}
		else
		{
			bool isSCP = IsSCP(victim);
			if(isSCP && WeaponIndex[Weapon_SMG4]==index)
			{
				damage /= 2.0;
				changed = true;
			}

			if((!isSCP || Client[victim].Class==Class_0492) && GetEntProp(victim, Prop_Data, "m_LastHitGroup")==HITGROUP_HEAD)
			{
				for(WeaponEnum i=Weapon_Pistol; i<Weapon_Flash; i++)
				{
					if(index != WeaponIndex[i])
						continue;

					damagetype |= DMG_CRIT;
					changed = true;
					break;
				}
			}
		}
	}

	Action action = Function_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	switch(action)
	{
		case Plugin_Changed:
			changed = true;

		case Plugin_Handled, Plugin_Stop:
			return action;
	}

	action = Function_OnDealDamage(attacker, victim, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	switch(action)
	{
		case Plugin_Changed:
			changed = true;

		case Plugin_Handled, Plugin_Stop:
			return action;
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!Enabled || !IsValidClient(entity))
		return Plugin_Continue;

	if(!StrContains(sample, "vo", false))
	{
		if(IsSpec(entity) || (IsSCP(entity) && !TF2_IsPlayerInCondition(entity, TFCond_Disguised)))
			return Plugin_Handled;
	}
	else if(StrContains(sample, "step", false) != -1)
	{
		if(IsSCP(entity) || Client[entity].Sprinting)
		{
			if(Client[entity].Class == Class_Stealer)
				ItSteals_Step(sample, PLATFORM_MAX_PATH);

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

	return Function_OnSeePlayer(target, client) ? Plugin_Continue : Plugin_Stop;
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
		default:
		{
			health = 125;
			Function_OnMaxHealth(client, health);
		}
	}
	return Plugin_Changed;
}