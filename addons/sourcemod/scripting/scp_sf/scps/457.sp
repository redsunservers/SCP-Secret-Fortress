static const int HealthKill = 300;
static const int HealthSplit = 2500;

static int Index457;

public void SCP457_Enable(int index)
{
	Index457 = index;
}

public bool SCP457_Create(int client)
{
	Classes_VipSpawn(client);

	int weapon = SpawnWeapon(client, "tf_weapon_fireaxe", 649, 50, 13, "1 ; 0.061538 ; 28 ; 0.5 ; 60 ; 0.3 ; 138 ; 2.5 ; 208 ; 1 ; 219 ; 1 ; 252 ; 0.65", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 14);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	
	return false;
}

public void SCP457_OnButton(int client, int button)
{
	if(GetEntityFlags(client) & (FL_SWIM | FL_INWATER))
	{
		SDKHooks_TakeDamage(client, client, client, 1.0, DMG_CRUSH);
	}
	else if(!TF2_IsPlayerInCondition(client, TFCond_OnFire))
	{
		TF2_IgnitePlayer(client, client);
	}
}

public void SCP457_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	CreateTimer(0.1, Timer_DissolveRagdoll, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void SCP457_OnKill(int client, int victim)
{
	int health = GetClientHealth(client);
	int newHealth = health+HealthKill;
	if(newHealth >= HealthSplit)
	{
		newHealth -= 1250;

		DataPack pack;
		CreateDataTimer(0.5, SCP457_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(GetClientUserId(victim));
	}

	ApplyHealEvent(client, newHealth-health);
	SetEntityHealth(client, newHealth);
}

public void SCP457_OnMaxHealth(int client, int &health)
{
	health = HealthSplit;
}

public Action SCP457_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(TF2_GetPlayerClass(victim) == TFClass_Pyro)
		TF2_AddCondition(victim, TFCond_Gas, 3.0, client); 

	return Plugin_Continue;
}

public Action SCP457_Timer(Handle timer, DataPack pack)
{
	if(Enabled)
	{
		pack.Reset();
		int client = GetClientOfUserId(pack.ReadCell());
		int victim = GetClientOfUserId(pack.ReadCell());
		if(client && IsClientInGame(client) && IsPlayerAlive(client) && victim && IsClientInGame(victim))
		{
			Client[victim].Class = Index457;
			TF2_RespawnPlayer(victim);
			Client[victim].Floor = Client[client].Floor;

			SetEntProp(victim, Prop_Send, "m_bDucked", true);
			SetEntityFlags(victim, GetEntityFlags(victim)|FL_DUCKING);

			static float pos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(victim, pos, NULL_VECTOR, NULL_VECTOR);

			for(int i=1; i<=MaxClients; i++)
			{
				if(victim!=i && (client==i || IsFriendly(Client[i].Class, Client[client].Class)))
					Client[i].ThinkIsDead[victim] = false;
			}
		}
	}
	return Plugin_Continue;
}