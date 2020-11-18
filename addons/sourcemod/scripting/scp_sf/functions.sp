void Function_OnKill(int client, int victim)
{
	if(Client[client].OnKill == INVALID_FUNCTION)
		return;

	Call_StartFunction(INVALID_HANDLE, Client[client].OnKill);
	Call_PushCell(client);
	Call_PushCell(victim);
	Call_Finish();
}

void Function_OnDeath(int client, int attacker)
{
	if(Client[client].OnDeath == INVALID_FUNCTION)
		return;

	Call_StartFunction(INVALID_HANDLE, Client[client].OnDeath);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_Finish();
}

void Function_OnButton(int client, int button)
{
	if(Client[client].OnButton == INVALID_FUNCTION)
		return;

	Call_StartFunction(INVALID_HANDLE, Client[client].OnButton);
	Call_PushCell(client);
	Call_PushCell(button);
	Call_Finish();
}

void Function_OnSpeed(int client, float &speed)
{
	if(Client[client].OnSpeed == INVALID_FUNCTION)
		return;

	Call_StartFunction(INVALID_HANDLE, Client[client].OnSpeed);
	Call_PushCell(client);
	Call_PushFloatRef(speed);
	Call_Finish();
}

Action Function_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result;
	if(Client[client].OnTakeDamage != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, Client[client].OnTakeDamage);
		Call_PushCell(client);
		Call_PushCellRef(attacker);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish();
	}
	return result;
}

Action Function_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result;
	if(Client[client].OnDealDamage != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, Client[client].OnDealDamage);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish();
	}
	return result;
}

bool Function_OnSeePlayer(int client, int victim)
{
	bool result = true;
	if(Client[client].OnSeePlayer != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, Client[client].OnSeePlayer);
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

	Call_StartFunction(INVALID_HANDLE, Client[client].OnMaxHealth);
	Call_PushCell(client);
	Call_PushCellRef(health);
	Call_Finish();
}

bool Function_OnGlowPlayer(int client, int victim)
{
	bool result;
	if(Client[client].OnGlowPlayer != INVALID_FUNCTION)
	{
		Call_StartFunction(INVALID_HANDLE, Client[client].OnGlowPlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}