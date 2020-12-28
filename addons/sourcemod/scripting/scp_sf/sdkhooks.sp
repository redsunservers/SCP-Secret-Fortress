void SDKHook_Setup()
{
	AddNormalSoundHook(HookSound);
}

void SDKHook_HookClient(int client)
{
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
	SDKHook(client, SDKHook_ShouldCollide, OnShouldCollide);
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
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
		SDKHook(entity, SDKHook_Spawn, StrEqual(classname, "item_healthkit_small") ? OnKitSpawned : OnMedSpawned);
	}
	else if(StrEqual(classname, "tf_projectile_pipe"))
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
	SetEntProp(entity, Prop_Data, "m_iHammerID", RoundToFloor((GetEngineTime()+2.0)*10.0));
	SDKHook(entity, SDKHook_StartTouch, OnPipeTouch);
	SDKHook(entity, SDKHook_Touch, OnKitPickup);
}

public Action OnSmallPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(!IsSCP(client) && !Client[client].Disarmer &&
	   GetEntProp(entity, Prop_Data, "m_iHammerID")/10.0 < GetEngineTime() &&
	   Items_CanGiveItem(client, Item_Medical))
	{
		Items_CreateWeapon(client, 30013, false, true, true);
		AcceptEntityInput(entity, "Kill");
	}
	return Plugin_Handled;
}

public Action OnKitPickup(int entity, int client)
{
	if(!Enabled || !IsValidClient(client))
		return Plugin_Continue;

	if(!IsSCP(client) && !Client[client].Disarmer)
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
					SDKUnhook(entity, SDKHook_Touch, OnKitPickup);
					return Plugin_Continue;
				}
			}
			else if(Items_CanGiveItem(client, Item_Medical))
			{
				Items_CreateWeapon(client, 30013, false, true, true);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	return Plugin_Handled;
}

public Action OnFullPickup(int entity, int client)
{
	if(Enabled && IsValidClient(client))
	{
		if(IsSCP(client) || Client[client].Disarmer ||
		   GetEntProp(entity, Prop_Data, "m_iHammerID")/10.0 > GetEngineTime())
			return Plugin_Handled;

		int health;
		OnGetMaxHealth(client, health);
		if(health <= GetClientHealth(client))
			return Plugin_Handled;

		SDKUnhook(entity, SDKHook_Touch, OnKitPickup);
	}
	return Plugin_Continue;
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

public Action OnObjDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Enabled && IsValidClient(attacker) && !CvarFriendlyFire.BoolValue)
	{
		if(TF2_GetTeam(entity) == Client[attacker].TeamTF())
			return Plugin_Handled;
	}
	return Plugin_Continue;
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
	Action action = Items_OnDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	switch(action)
	{
		case Plugin_Changed:
			changed = true;

		case Plugin_Handled, Plugin_Stop:
			return action;
	}

	action = Function_OnTakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
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
	if(!IsValidClient(entity))
		return Plugin_Continue;

	Action action;
	if(Function_OnSound(action, entity, sample, channel, volume, level, pitch, flags, soundEntry, seed))
		return action;

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

public void OnWeaponSwitch(int client, int entity)
{
	Function_OnSwitchWeapon(client, entity);
	RequestFrame(OnWeaponSwitchFrame, GetClientUserId(client));
}

static void OnWeaponSwitchFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(entity>MaxClients && IsValidEntity(entity))
		{
			WeaponEnum weapon;
			if(Items_GetWeaponByIndex(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), weapon))
			{
				if(weapon.Hide)
					ViewModel_Hide(client);

				if(weapon.Class != TFClass_Unknown)
				{
					Client[client].WeaponClass = weapon.Class;
					return;
				}
			}
		}
	}

	Client[client].WeaponClass = ClassClass[Client[client].Class];
}

public void OnPostThink(int client)
{
	if(IsPlayerAlive(client) && Client[client].HudIn<GetEngineTime() && TF2_GetPlayerClass(client)!=Client[client].WeaponClass)
		TF2_SetPlayerClass(client, Client[client].WeaponClass, false);
}

public void OnPostThinkPost(int client)
{
	if(IsPlayerAlive(client) && Client[client].HudIn<GetEngineTime() && TF2_GetPlayerClass(client)!=ClassClass[Client[client].Class])
		TF2_SetPlayerClass(client, ClassClass[Client[client].Class], false);
}