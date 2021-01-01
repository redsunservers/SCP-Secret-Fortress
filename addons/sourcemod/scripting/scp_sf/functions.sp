void Function_OnKill(int client, int victim)
{
	if(Client[client].OnKill == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnKill);
	Call_PushCell(client);
	Call_PushCell(victim);
	Call_Finish();
}

void Function_OnDeath(int client, int attacker)
{
	if(Client[client].OnDeath == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnDeath);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_Finish();
}

void Function_OnButton(int client, int button)
{
	if(Client[client].OnButton == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnButton);
	Call_PushCell(client);
	Call_PushCell(button);
	Call_Finish();
}

void Function_OnSpeed(int client, float &speed)
{
	if(Client[client].OnSpeed == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnSpeed);
	Call_PushCell(client);
	Call_PushFloatRef(speed);
	Call_Finish();
}

Action Function_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;
	if(Client[client].OnTakeDamage != INVALID_FUNCTION)
	{
		Call_StartFunction(null, Client[client].OnTakeDamage);
		Call_PushCell(client);
		Call_PushCellRef(attacker);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);
	}
	return result;
}

Action Function_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;
	if(Client[client].OnDealDamage != INVALID_FUNCTION)
	{
		Call_StartFunction(null, Client[client].OnDealDamage);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);
	}
	return result;
}

bool Function_OnSeePlayer(int client, int victim)
{
	bool result = true;
	if(Client[client].OnSeePlayer != INVALID_FUNCTION)
	{
		Call_StartFunction(null, Client[client].OnSeePlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}

void Function_OnMaxHealth(int client, int &health)
{
	if(Client[client].OnMaxHealth == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnMaxHealth);
	Call_PushCell(client);
	Call_PushCellRef(health);
	Call_Finish();
}

bool Function_OnGlowPlayer(int client, int victim)
{
	bool result;
	if(Client[client].OnGlowPlayer != INVALID_FUNCTION)
	{
		Call_StartFunction(null, Client[client].OnGlowPlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}

void Function_OnSwitchWeapon(int client, int entity)
{
	if(Client[client].OnWeaponSwitch == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnWeaponSwitch);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_Finish();
}

bool Function_OnSound(Action &result, int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(Client[client].OnSound == INVALID_FUNCTION)
		return false;

	Call_StartFunction(null, Client[client].OnSound);
	Call_PushCell(client);
	Call_PushStringEx(sample, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(channel);
	Call_PushFloatRef(volume);
	Call_PushCellRef(level);
	Call_PushCellRef(pitch);
	Call_PushCellRef(flags);
	Call_PushStringEx(soundEntry, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(seed);
	Call_Finish(result);
	return true;
}

void Function_OnCondRemoved(int client, TFCond cond)
{
	if(Client[client].OnCondRemoved == INVALID_FUNCTION)
		return;

	Call_StartFunction(null, Client[client].OnCondRemoved);
	Call_PushCell(client);
	Call_PushCell(cond);
	Call_Finish();
}

bool Function_OnKeycard(int client, any access, int &value)
{
	if(Client[client].OnKeycard == INVALID_FUNCTION)
		return false;

	Call_StartFunction(null, Client[client].OnKeycard);
	Call_PushCell(client);
	Call_PushCell(access);
	Call_Finish(value);
	return true;
}