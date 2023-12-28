#pragma semicolon 1
#pragma newdecls required

void SDKHooks_PluginStart()
{
	AddNormalSoundHook(SoundHook);
}

void SDKHooks_PutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_SetTransmit, SetTransmit);
	SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost);
}

void SDKHooks_EntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "item_healthkit") == 0)
	{
		SDKHook(entity, SDKHook_StartTouch, HealthKitTouch);
		SDKHook(entity, SDKHook_Touch, HealthKitTouch);
	}
	else if(StrEqual(classname, "item_ammopack_small"))
	{
		SDKHook(entity, SDKHook_StartTouch, BlockPlayerTouch);
		SDKHook(entity, SDKHook_Touch, AmmopackSmallTouch);
	}
	else if(StrEqual(classname, "item_ammopack_medium"))
	{
		SDKHook(entity, SDKHook_StartTouch, BlockPlayerTouch);
		SDKHook(entity, SDKHook_Touch, AmmopackMediumTouch);
	}
	else if(StrEqual(classname, "item_ammopack_full"))
	{
		SDKHook(entity, SDKHook_StartTouch, BlockPlayerTouch);
		SDKHook(entity, SDKHook_Touch, AmmopackFullTouch);
	}
	else if(StrContains(classname, "func_door") == 0 || StrEqual(classname, "func_movelinear"))
	{
		SDKHook(entity, SDKHook_StartTouch, DoorTouch);
	}
}

static Action BlockPlayerTouch(int entity, int target)
{
	if(target < 1 || target > MaxClients)
		return Plugin_Continue;

	return Plugin_Handled;
}

static Action HealthKitTouch(int entity, int target)
{
	// Allow players below 400 max health to pick up health kits
	if(target < 1 || target > MaxClients || SDKCalls_GetMaxHealth(target) < 400)
		return Plugin_Continue;

	return Plugin_Handled;
}

static Action AmmopackSharedTouch(int entity, int target, int divide)
{
	if(target < 1 || target > MaxClients)
		return Plugin_Continue;
	
	bool used;

	for(int i = 1; i < Ammo_MAX; i++)
	{
		// Skip charge-based ammo
		if(i > Ammo_Metal && i < Ammo_Pistol)
			continue;
		
		int maxammo = Classes_GetMaxAmmo(target, i);
		if(maxammo > 0)
		{
			int ammo = GetAmmo(target, i);
			if(ammo < maxammo)
			{
				ammo += maxammo / divide;
				if(ammo > maxammo)
					ammo = maxammo;
				
				SetAmmo(target, ammo, i);
				used = true;
			}
		}
	}

	if(used)
	{
		ClientCommand(target, "playgamesound AmmoPack.Touch");
		AcceptEntityInput(entity, "Kill");
	}
	
	return Plugin_Handled;
}

static Action AmmopackSmallTouch(int entity, int client)
{
	return AmmopackSharedTouch(entity, client, 5);
}

static Action AmmopackMediumTouch(int entity, int client)
{
	return AmmopackSharedTouch(entity, client, 2);
}

static Action AmmopackFullTouch(int entity, int client)
{
	return AmmopackSharedTouch(entity, client, 1);
}

static Action DoorTouch(int entity, int client)
{
	if(client > 0 && client <= MaxClients)
	{
		// ignore the result, this is only called so scps like 096 can destroy doors when touching them
		Classes_DoorTouch(client, entity);
	}
	
	return Plugin_Continue;
}

static Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;

	if(attacker > 0 && attacker <= MaxClients)
	{
		result = Items_TakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
		
		if(result >= Plugin_Handled)
			return result;
	}

	bool changed = result == Plugin_Changed;

	result = Classes_TakeDamage(victim, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom);
	
	if(result == Plugin_Continue && changed)
		result = Plugin_Changed;

	return result;
}

static Action SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(flags || entity < 1 || entity > MaxClients)
		return Plugin_Continue;
	
	static bool soundPlaying;
	if(soundPlaying)
		return Plugin_Continue;
	
	soundPlaying = true;
	Action action = Classes_SoundHook(clients, numClients, sample, entity, channel, volume, level, pitch, flags, soundEntry, seed);
	soundPlaying = false;
	
	return action;
}

static Action SetTransmit(int client, int target)
{
	if(client == target || target < 1 || target > MaxClients || IsClientObserver(target))
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return Plugin_Stop;

	return Classes_Transmit(target, client) ? Plugin_Continue : Plugin_Stop;
}

static void WeaponSwitchPost(int client, int entity)
{
	RequestFrame(WeaponSwitchPostFrame, GetClientUserId(client));
}

static void WeaponSwitchPostFrame(int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
	{
		ViewEffects_WeaponSwitch(client);
	}
}
