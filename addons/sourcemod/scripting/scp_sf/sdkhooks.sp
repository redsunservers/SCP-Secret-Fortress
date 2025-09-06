#pragma semicolon 1
#pragma newdecls required

void SDKHook_Setup()
{
	AddNormalSoundHook(HookSound);
}

void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);	
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

void SDKHook_DealDamage(int client, int inflictor, int attacker, float damage, int damagetype=DMG_GENERIC, int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR)
{
	int inflictor2 = inflictor;
	int attacker2 = attacker;
	float damage2 = damage;
	int damagetype2 = damagetype;
	int weapon2 = weapon;
	float damageForce2[3], damagePosition2[3];
	for(int i; i<3; i++)
	{
		damageForce2[i] = damageForce[i];
		damagePosition2[i] = damagePosition[i];
	}

	if(OnTakeDamage(client, inflictor2, attacker2, damage2, damagetype2, weapon2, damageForce2, damagePosition2, -1) < Plugin_Handled)
		SDKHooks_TakeDamage(client, inflictor2, attacker2, damage2, damagetype2, weapon2, damageForce2, damagePosition2);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "item_healthkit_small"))
	{
		SDKHook(entity, SDKHook_Spawn, OnSmallHealthSpawned);
	}
	else if(StrEqual(classname, "item_healthkit_medium"))
	{
		SDKHook(entity, SDKHook_Spawn, OnMediumHealthSpawned);
	}
	else if(StrEqual(classname, "item_ammopack_small"))
	{
		SDKHook(entity, SDKHook_Spawn, OnSmallAmmoSpawned);
	}
	else if(StrEqual(classname, "item_ammopack_medium"))
	{
		SDKHook(entity, SDKHook_Spawn, OnMediumAmmoSpawned);
	}
	else if(StrEqual(classname, "item_ammopack_full"))
	{
		SDKHook(entity, SDKHook_Spawn, OnFullAmmoSpawned);
	}
	else if(StrEqual(classname, "tf_projectile_pipe"))
	{
		SDKHook(entity, SDKHook_Spawn, OnPipeSpawned);
	}
	else if(StrContains(classname, "func_door") == 0 || StrEqual(classname, "func_movelinear"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnDoorTouch);
	}
	else if (StrEqual(classname, "func_button"))
	{
		RequestFrame(UpdateDoorsFromButton, EntIndexToEntRef(entity));
	}
	else if (StrEqual(classname, "logic_relay"))
	{
		RequestFrame(UpdateDoorsFromRelay, entity);
	}
}

public void OnSmallHealthSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnSmallHealthPickup);
}

public void OnMediumHealthSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnMediumHealthPickup);
}

public Action OnSmallHealthPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(IsCanPickup(client) && !Client[client].Disarmer && Items_CanGiveItem(client, 3))
	{
		Items_CreateWeapon(client, 30013, false, true, true);
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Handled;
}

public Action OnMediumHealthPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(IsCanPickup(client))
	{
		if (GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") == client)
		{
			SDKUnhook(entity, SDKHook_Touch, OnMediumHealthPickup);
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

public void OnSmallAmmoSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnSmallAmmoPickup);
}

public void OnMediumAmmoSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnMediumAmmoPickup);
}

public void OnFullAmmoSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnFullAmmoPickup);
}

public Action OnSmallAmmoPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(IsCanPickup(client) && !Client[client].Disarmer)
	{
		int ammo = GetAmmo(client, 2);

		int max = Classes_GetMaxAmmo(client, 2);
		Items_Ammo(client, 2, max);
		if(ammo < max)
		{
			ammo += 30;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 2);
			AcceptEntityInput(entity, "Kill");
		}
	}
	return Plugin_Handled;
}

public Action OnMediumAmmoPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(IsCanPickup(client) && !Client[client].Disarmer)
	{
		bool found;
		int ammo = GetAmmo(client, 2);
		int max = Classes_GetMaxAmmo(client, 2);
		Items_Ammo(client, 2, max);
		if(ammo < max)
		{
			ammo += 90;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 2);
			found = true;
		}

		ammo = GetAmmo(client, 6);
		max = Classes_GetMaxAmmo(client, 6);
		Items_Ammo(client, 6, max);
		if(ammo < max)
		{
			ammo += 80;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 6);
			found = true;
		}

		ammo = GetAmmo(client, 7);
		max = Classes_GetMaxAmmo(client, 7);
		Items_Ammo(client, 7, max);
		if(ammo < max)
		{
			ammo += 80;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 7);
			found = true;
		}

		ammo = GetAmmo(client, 10);
		max = Classes_GetMaxAmmo(client, 10);
		Items_Ammo(client, 10, max);
		if(ammo < max)
		{
			ammo += 30;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 10);
			found = true;
		}

		ammo = GetAmmo(client, 11);
		max = Classes_GetMaxAmmo(client, 11);
		Items_Ammo(client, 11, max);
		if(ammo < max)
		{
			ammo += 40;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 11);
			found = true;
		}

		if(found)
			AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Handled;
}

public Action OnFullAmmoPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(IsCanPickup(client) && !Client[client].Disarmer)
	{
		bool found;
		int ammo = GetAmmo(client, 2);
		int max = Classes_GetMaxAmmo(client, 2);
		Items_Ammo(client, 2, max);
		if(ammo < max)
		{
			ammo += 170;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 2);
			found = true;
		}

		ammo = GetAmmo(client, 6);
		max = Classes_GetMaxAmmo(client, 6);
		Items_Ammo(client, 6, max);
		if(ammo < max)
		{
			ammo += 160;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 6);
			found = true;
		}

		ammo = GetAmmo(client, 7);
		max = Classes_GetMaxAmmo(client, 7);
		Items_Ammo(client, 7, max);
		if(ammo < max)
		{
			ammo += 160;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 7);
			found = true;
		}

		ammo = GetAmmo(client, 10);
		max = Classes_GetMaxAmmo(client, 10);
		Items_Ammo(client, 10, max);
		if(ammo < max)
		{
			ammo += 50;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 10);
			found = true;
		}

		ammo = GetAmmo(client, 11);
		max = Classes_GetMaxAmmo(client, 11);
		Items_Ammo(client, 11, max);
		if(ammo < max)
		{
			ammo += 60;
			if(ammo > max)
				ammo = max;

			SetAmmo(client, ammo, 11);
			found = true;
		}

		if(found)
			AcceptEntityInput(entity, "Kill");
	}
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
	return IsValidClient(client) ? Plugin_Handled : Plugin_Continue;
}

public Action OnDoorTouch(int entity, int client)
{
	if (IsValidClient(client))
	{
		// ignore the result, this is only called so scps like 096 can destroy doors when touching them
		Classes_OnDoorTouch(client, entity);	
	}
	
	return Plugin_Continue;
}

public void OnPlayerManagerThink(int entity) 
{
	static int offsetAlive = -1;
	if(offsetAlive == -1) 
		offsetAlive = FindSendPropInfo("CTFPlayerResource", "m_bAlive");

	static int offsetTeam = -1;
	if(offsetTeam == -1) 
		offsetTeam = FindSendPropInfo("CTFPlayerResource", "m_iTeam");

	static int offsetScore = -1;
	if(offsetScore == -1) 
		offsetScore = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");

	static int offsetClass = -1;
	if(offsetClass == -1) 
		offsetClass = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClass");

	static int offsetClassKilled = -1;
	if(offsetClassKilled == -1) 
		offsetClassKilled = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClassWhenKilled");

	bool[] alive = new bool[MaxClients+1];
	int[] team = new int[MaxClients+1];
	int[] score = new int[MaxClients+1];
	bool karmaEnabled = CvarKarma.BoolValue && !SZF_Enabled();
	int MinKarma = CvarKarmaMin.IntValue;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) > 1)
			{
				team[client] = (client % 2) ? 3 : 2;
				alive[client] = true;
			}
			else
			{
				team[client] = 1;
				alive[client] = false;
			}

			if(karmaEnabled)
			{
				float karma = Classes_GetKarma(client);

				score[client] = RoundToFloor(karma);
				
				if(score[client] < MinKarma)
					score[client] = MinKarma;
			}
		}
	}

	static const int zero[MAXPLAYERS+1] = {0, ...};
	SetEntDataArray(entity, offsetAlive, alive, MaxClients + 1);
	SetEntDataArray(entity, offsetTeam, team, MaxClients + 1);
	SetEntDataArray(entity, offsetScore, score, MaxClients + 1);
	SetEntDataArray(entity, offsetClass, zero, MaxClients + 1);
	SetEntDataArray(entity, offsetClassKilled, zero, MaxClients + 1);
}

// prevent exploits if attacker dies and kills someone afterwards (e.g. grenade)
int DamageSavedClass = -1;

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled)
		return Plugin_Continue;

	Client[victim].PreDamageHealth = GetClientHealth(victim);

	int activeWeapon = GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon");
	if (activeWeapon>MaxClients)
		Client[victim].PreDamageWeapon = EntIndexToEntRef(activeWeapon);
	
	bool validAttacker = IsValidClient(attacker);
	DamageSavedClass = -1;
	if(victim!=attacker)
	{
		char classname[16];
		if(inflictor>MaxClients && GetEntityClassname(inflictor, classname, sizeof(classname)))
		{
			if (StrEqual(classname, "taunt_soldier")) // frag
			{
				if (!validAttacker)
				{
					attacker = GetOwnerLoop(attacker);
					validAttacker = IsValidClient(attacker);
				}
				// grenade owner might have died and have a different class, so make sure we are using the correct saved class
				DamageSavedClass = GetEntProp(inflictor, Prop_Data, "m_iHammerID");
			}
			else if (StrEqual(classname, "deflect_ball")) // scp18
			{
				// same reason as above
				DamageSavedClass = GetEntProp(inflictor, Prop_Data, "m_iHammerID");
			}
		}
	}

	bool changed;
	if(validAttacker && victim!=attacker)
	{
		// if we have no saved class, grab our attacker's current class
		if (DamageSavedClass == -1)
			DamageSavedClass = Client[attacker].Class;
		
		if(IsFriendly(Client[victim].Class, DamageSavedClass))
		{
			if(!CvarFriendlyFire.BoolValue && !IsFakeClient(victim))
				return Plugin_Handled;
			
			// friendlyfire is pointless in SZF
			if (SZF_Enabled())
				return Plugin_Handled;
			
			// do not allow friendlyfire between SCPs
			if (IsSCP(victim) && IsSCP(attacker))
				damage = 0.0;
			else
				damage *= 0.4;
				
			changed = true;
		}

		if (CvarKarma.BoolValue && !SZF_Enabled() && !IsSCP(attacker))
		{
			float karma = Classes_GetKarma(attacker) * 0.01;
			if (karma < 1.0)
			{
				if (damagetype & DMG_CRIT)
				{
					// lower the crit multiplier from x3 to x1 if below 30 karma, and from x3 to x2 if below 60
					// hack: fudge the multiplier lower due to falloff
					if (karma <= 0.3)
						damage *= (1.0 / 5.0);
					else if (karma <= 0.6)
						damage *= (1.0 / 3.0);
				}
				
				// and then negate the base damage
				damage *= karma;
			}
			changed = true;
		}

		int health = Client[victim].PreDamageHealth;
		if(health>25 && (health-damage)<26)
			CreateTimer(3.0, Timer_MyBlood, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}

	Action action;
	if(validAttacker)
	{
		action = Items_OnDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		switch(action)
		{
			case Plugin_Changed:
				changed = true;

			case Plugin_Handled, Plugin_Stop:
				return action;
		}
	}

	action = Classes_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	switch(action)
	{
		case Plugin_Changed:
			changed = true;

		case Plugin_Handled, Plugin_Stop:
			return action;
	}

	if(validAttacker)
	{
		action = Classes_OnDealDamage(attacker, victim, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		switch(action)
		{
			case Plugin_Changed:
				changed = true;

			case Plugin_Handled, Plugin_Stop:
				return action;
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!(damagetype & DMG_VEHICLE))
		return Plugin_Continue;

	damage *= 15.0;
	return OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
}

public void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if (!Enabled)
		return;

	// shouldn't happen but just in case
	if (Client[victim].PreDamageHealth <= 0)
		return;

	// ensure attacker is valid and not ourselves
	if (!IsValidClient(attacker) || (victim == attacker))
		return;	

	bool karma_enabled = CvarKarma.BoolValue && !SZF_Enabled();
	int health = GetClientHealth(victim);
	int checked = 0;

	// this damage will cause the player to die
	if (health <= 0)
	{
		if (IsBadKill(victim, attacker, DamageSavedClass))
		{
			Client[attacker].BadKills++;

			if (karma_enabled)
			{
				BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", attacker));
				if(bf)
				{
					char buffer[64];
					FormatEx(buffer, sizeof(buffer), "%T", "badkill", attacker);
					bf.WriteString(buffer);
					bf.WriteString("ico_demolish");
					bf.WriteByte(0);
					EndMessage();
				}
			}

			checked = 2;
		}
		else
		{
			Client[attacker].GoodKills++;
			checked = 1;
		}

		// don't mess up the calculations
		health = 0;
	}
	
	// If karma isn't enabled then we don't need to proceed further here
	if (!karma_enabled)
		return;

	if (Client[victim].PreDamageHealth <= health)
		return; // no damage or healed

	int penaltyamount = Client[victim].PreDamageHealth - health;
	int maxhealth = Classes_GetMaxHealth(attacker);
	// if we somehow had overheal then don't account for that, it can cause karma to go down too far
	if (Client[victim].PreDamageHealth > maxhealth)
		penaltyamount -= (Client[victim].PreDamageHealth - maxhealth);

	if (penaltyamount <= 0)
		return;	

	// compensate for the other player's karma
	// don't apply this for friendlyfire damage though
	// removed: this makes karma too lenient
	float victimkarmaratio = 1.0;
	//if (!IsFriendly(Client[victim].Class, DamageSavedClass))
	//{
	//	float victimkarma = Classes_GetKarma(victim);
	//	victimkarmaratio = (victimkarma * 0.01);
	//	penaltyamount = RoundFloat(float(penaltyamount) * victimkarmaratio);
	//}
	
	if ((checked == 2) || ((checked == 0) && IsBadKill(victim, attacker, DamageSavedClass)))
	{
		// karma is applied per damage rather than per kill so players cant shoot others to lowest health possible and get away with it
		Classes_ApplyKarmaDamage(attacker, victim, penaltyamount);	
		
		if (health == 0)
		{
			// on kill, apply any karma deduction that wasn't added previously from damage
			// this ensures the killer is given a full karma penalty 
			// this prevents exploiting the system by killing a player already at low HP
			// as you would technically deal little damage and hence get little penalty
		
			float karma = Classes_GetKarma(attacker);
			float karmaPoints = Client[attacker].KarmaPoints[victim];
			float karmaMin = CvarKarmaMin.FloatValue;
			float prevkarma = karma;
			
			// lose 5 more karma for friendlyfire kills
			if (IsFriendly(Client[victim].Class, DamageSavedClass))
				karmaPoints += 5.0;
				
			// hack: this compensates for miniscule precision errors
			if (karmaPoints > 0.01)
			{
				karma -= karmaPoints * victimkarmaratio;
				if (karma < karmaMin)
					karma = karmaMin;

				if (prevkarma != karma)
					Classes_SetKarma(attacker, karma);
			}
			
			Client[attacker].KarmaPoints[victim] = 0.0;
		}
	}
}

public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(flags || !IsValidClient(entity))
		return Plugin_Continue;
	
	static bool soundPlaying;
	if (soundPlaying)
		return Plugin_Continue;
	
	soundPlaying = true;
	
	Action action;
	if(Classes_OnSound(action, entity, sample, channel, volume, level, pitch, flags, soundEntry, seed))
	{
		soundPlaying = false;
		return action;
	}
	
	soundPlaying = false;
	return Plugin_Continue;
}

public Action OnTransmit(int client, int target)
{
	if(!Enabled || client==target || !IsValidClient(target) || IsClientObserver(target) || TF2_IsPlayerInCondition(target, TFCond_HalloweenGhostMode))
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return Plugin_Stop;

	float engineTime = GetGameTime();
	if(Client[client].InvisFor > engineTime)
		return Plugin_Stop;

	return Classes_OnSeePlayer(target, client) ? Plugin_Continue : Plugin_Stop;
}

public Action OnGetMaxHealth(int client, int &health)
{
	health = Classes_GetMaxHealth(client);
	return Plugin_Changed;
}

public void OnWeaponSwitch(int client, int entity)
{
	Classes_OnWeaponSwitch(client, entity);
	RequestFrame(OnWeaponSwitchFrame, GetClientUserId(client));
}

static void OnWeaponSwitchFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		/*int ammo[Ammo_MAX];
		for(int i=1; i<Ammo_MAX; i++)
		{
			ammo[i] = GetEntProp(client, Prop_Data, "m_iAmmo", _, i);
			if(i!=Ammo_Metal && !ammo[i])
				SetEntProp(client, Prop_Data, "m_iAmmo", -1, _, i);
		}

		int entity;
		for(int i; (entity=Items_Iterator(client, i))!=-1; i++)
		{
			if(GetEntProp(entity, Prop_Data, "m_iClip1") >= 0)
				continue;

			int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
			if(type>0 && type<Ammo_MAX && ammo[type]<1)
				TF2_RemoveItem(client, entity);
		}*/
		
		Items_ShowItemMenu(client);
		
		//ViewChange_Switch(client);
	}
}
