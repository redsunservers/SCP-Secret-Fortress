void SDKHook_Setup()
{
	AddNormalSoundHook(HookSound);
}

void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
	SDKHook(client, SDKHook_ShouldCollide, OnShouldCollide);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "item_healthkit_small"))
	{
		SDKHook(entity, SDKHook_Spawn, OnSmallSpawned);
	}
	else if(StrEqual(classname, "item_healthkit_medium"))
	{
		SDKHook(entity, SDKHook_Spawn, OnMedSpawned);
	}
	else if(StrEqual(classname, "tf_projectile_pipe"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnPipeSpawned);
	}
}

public void OnSmallSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnSmallPickup);
}

public void OnMedSpawned(int entity)
{
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToFloor((GetEngineTime()+2.0)*10.0));
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnMedPickup);
}

public Action OnSmallPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(!IsSCP(client) && !Client[client].Disarmer && Items_CanGiveItem(client, Item_Medical))
	{
		Items_CreateWeapon(client, 30013, false, true, true);
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Handled;
}

public Action OnMedPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(!IsSCP(client))
	{
		float time = GetEntProp(entity, Prop_Data, "m_iHammerID")/10.0;
		float engineTime = GetEngineTime();
		if(time < engineTime)
		{
			if(time+0.3 > engineTime)
			{
				int health;
				OnGetMaxHealth(client, health);
				if(health > GetClientHealth(client))
				{
					SDKUnhook(entity, SDKHook_Touch, OnMedPickup);
					return Plugin_Continue;
				}
			}
			else if(!Client[client].Disarmer && Items_CanGiveItem(client, Item_Medical))
			{
				Items_CreateWeapon(client, 30014, false, true, true);
				AcceptEntityInput(entity, "Kill");
			}
		}
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

public bool OnShouldCollide(int client, int collisiongroup, int contentsmask, bool original)
{
	if(collisiongroup == COLLISION_GROUP_PLAYER_MOVEMENT)
		return false;

	return original;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled)
		return Plugin_Continue;

	bool validAttacker = IsValidClient(attacker);
	if(validAttacker && victim!=attacker)
	{
		if(!CvarFriendlyFire.BoolValue && !IsFakeClient(victim) && IsFriendly(Client[victim].Class, Client[attacker].Class))
			return Plugin_Handled;

		int health = GetClientHealth(victim);
		if(health>25 && (health-damage)<26)
			CreateTimer(3.0, Timer_MyBlood, GetClientUserId(victim), TIMER_FLAG_NO_MAPCHANGE);
	}

	bool changed;
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

	return OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
}

public Action HookSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(flags || !IsValidClient(entity))
		return Plugin_Continue;

	Action action;
	if(Classes_OnSound(action, entity, sample, channel, volume, level, pitch, flags, soundEntry, seed))
		return action;

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
		int ammo[Ammo_MAX];
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
		}

		ViewChange_Switch(client);
	}
}

static const float ViewHeights[] =
{
	75.0,
	65.0,
	75.0,
	68.0,
	68.0,
	75.0,
	75.0,
	68.0,
	75.0,
	68.0
};

public void OnPostThink(int client)
{
	if(IsPlayerAlive(client) && Client[client].WeaponClass!=TFClass_Unknown)
	{
		TF2_SetPlayerClass(client, Client[client].WeaponClass, false);
		if(GetEntPropFloat(client, Prop_Send, "m_vecViewOffset[2]") > 64.0)	// Otherwise, shaking
			SetEntPropFloat(client, Prop_Send, "m_vecViewOffset[2]", ViewHeights[Client[client].WeaponClass]);
	}
}

public void OnPostThinkPost(int client)
{
	if(IsPlayerAlive(client) && Client[client].CurrentClass!=TFClass_Unknown)
		TF2_SetPlayerClass(client, Client[client].CurrentClass, false);
}