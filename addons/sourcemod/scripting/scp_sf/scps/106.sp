static const int HealthMax = 1200;	// Max standard health

static const char ModelMelee[] = "models/scp_sf/106/scp106_hands_1.mdl";
static const float TeleFreeze = 8.0;	// Teleport freeze duration
static const float TeleStun = 5.0;		// Teleport stun duration
static const float TeleDelay = 4.0;		// Teleport delay

static const float SpeedExtra = 40.0;	// Extra speed while low health

static int Health[MAXTF2PLAYERS];

public bool SCP106_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Pos[0] = 0.0;
	Client[client].Pos[1] = 0.0;
	Client[client].Pos[2] = 0.0;
	Client[client].Extra2 = 0;

	Health[client] = HealthMax;

	int weapon = SpawnWeapon(client, "tf_weapon_shovel", 649, 60, 13, "1 ; 0.769231 ; 28 ; 0 ; 66 ; 0.1 ; 252 ; 0.4", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 12);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	ViewModel_Create(client, ModelMelee);
	ViewModel_SetDefaultAnimation(client, "a_fists_idle_02");
	ViewModel_SetAnimation(client, "fists_draw");
	return false;
}

public Action SCP106_OnAnimation(int client, PlayerAnimEvent_t &anim, int &data)
{
	if((anim==PLAYERANIMEVENT_ATTACK_PRIMARY || anim==PLAYERANIMEVENT_ATTACK_SECONDARY || anim==PLAYERANIMEVENT_ATTACK_GRENADE) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
		ViewModel_SetAnimation(client, GetRandomInt(0, 1) ? "attack1" : "attack2");

	return Plugin_Continue;
}

public void SCP106_OnCondRemoved(int client, TFCond cond)
{
	if(cond == TFCond_Dazed)
		ViewModel_SetAnimation(client, "fists_draw");
}

public void SCP106_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);
	if(Client[client].Extra2)
		HideAnnotation(client);
		
	char model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));	
	Classes_PlayDeathAnimation(client, model, "death_scp_106", "", 3.0);
}

public void SCP106_OnKill(int client, int victim)
{
	GiveAchievement(Achievement_Death106, victim);
}

public void SCP106_OnMaxHealth(int client, int &health)
{
	int current = GetClientHealth(client);
	Health[client] = current;
}

public void SCP106_OnSpeed(int client, float &speed)
{
    speed += (1.0-(Health[client]/HealthMax))*SpeedExtra;
}

public Action SCP106_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);

	int entity = -1;
	ArrayList spawns = new ArrayList();
	while((entity=FindEntityByClassname(entity, "info_target")) != -1)
	{
		static char name[16];
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_pocket", false))
			spawns.Push(entity);
	}

	int length = spawns.Length;
	if(length)
		entity = spawns.Get(GetRandomInt(0, length-1));

	delete spawns;

	if(entity != -1)
	{
		static float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(victim, pos, NULL_VECTOR, TRIPLE_D);
		Client[client].ThinkIsDead[victim] = true;
	}
	else if(GetRandomInt(0, 2))
	{
		damage *= 2.0;
		damagetype |= DMG_CRIT;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void SCP106_OnButton(int client, int button)
{
	if(Client[client].ChargeIn && Client[client].ChargeIn<GetGameTime())
	{
		Client[client].ChargeIn = 0.0;
		TeleportEntity(client, Client[client].Pos, NULL_VECTOR, TRIPLE_D);
	}
	else if(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2])
	{
		static float pos[3];
		GetClientEyePosition(client, pos);
		if(Client[client].Extra2)
		{
			if(GetVectorDistance(pos, Client[client].Pos, true) > 150000)
				HideAnnotation(client);
		}
		else if(GetVectorDistance(pos, Client[client].Pos, true) < 100000)
		{
			ShowAnnotation(client);
		}
	}

	if(button == IN_ATTACK2)
	{
		int flags = GetEntityFlags(client);
		if((flags & FL_DUCKING) || !(flags & FL_ONGROUND) || TF2_IsPlayerInCondition(client, TFCond_Dazed) || GetEntProp(client, Prop_Send, "m_bDucked"))
		{
			PrintHintText(client, "%T", "106_create_deny", client);
		}
		else
		{
			Client[client].Extra2 = 1;
			PrintHintText(client, "%T", "106_create", client);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Client[client].Pos);
			ShowAnnotation(client);
		}
	}
	else if(button == IN_ATTACK3)
	{
		if(!(Client[client].Pos[0] || Client[client].Pos[1] || Client[client].Pos[2]))
		{
			PrintHintText(client, "%T", "106_create_none", client);
		}
		else if(TF2_IsPlayerInCondition(client, TFCond_Dazed) || !(GetEntityFlags(client)& FL_ONGROUND))
		{
			PrintHintText(client, "%T", "106_tele_deny", client);
		}
		else
		{
			TF2_StunPlayer(client, TeleStun, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);

			float engineTime = GetGameTime();
			Client[client].ChargeIn = engineTime+TeleDelay;
			Client[client].FreezeFor = engineTime+TeleFreeze;

			SetEntityMoveType(client, MOVETYPE_NONE);
			PrintRandomHintText(client);
		}
	}
}

public bool SCP106_OnPickup(int client, int entity)
{
	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "tf_dropped_weapon"))
	{
		RemoveEntity(entity);
		return true;
	}
	else if(!StrContains(buffer, "prop_dynamic"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			ClassEnum class;
			if(Classes_GetByIndex(Client[client].Class, class))
			{
				switch(class.Group)
				{
					case 0:
						AcceptEntityInput(entity, "FireUser1", client, client);

					case 1:
						AcceptEntityInput(entity, "FireUser2", client, client);

					case 2:
						AcceptEntityInput(entity, "FireUser3", client, client);

					default:
						AcceptEntityInput(entity, "FireUser4", client, client);
				}
				return true;
			}
		}
	}
	else if(StrEqual(buffer, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
	}
	return false;
}

public Action SCP106_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		return Plugin_Handled;
	}
	else if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 30;

		int value = strlen(sample);
		value = StringToInt(sample[value-5]);
		if(value<0 || value>4)
			value = GetRandomInt(1, 4);

		Format(sample, sizeof(sample), "player/footsteps/metalgrate%d.wav", value);
		EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action SCP106_TakeDamage(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Client[client].ChargeIn < GetGameTime())
		return Plugin_Continue;

	damagetype |= DMG_PREVENT_PHYSICS_FORCE;
	return Plugin_Changed;
}

public bool SCP106_DoorWalk(int client, int entity)
{
	static char buffer[16];
	GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
	return !StrContains(buffer, "scp", false);
}

static void ShowAnnotation(int client)
{
	Event event = CreateEvent("show_annotation");
	if(event != INVALID_HANDLE)
	{
		event.SetFloat("worldPosX", Client[client].Pos[0]);
		event.SetFloat("worldPosY", Client[client].Pos[1]);
		event.SetFloat("worldPosZ", Client[client].Pos[2]);
		event.SetFloat("lifetime", 999.0);
		event.SetInt("id", 9999-client);

		char buffer[32];
		FormatEx(buffer, sizeof(buffer), "%T", "106_portal", client);
		event.SetString("text", buffer);

		event.SetString("play_sound", "vo/null.wav");
		event.SetInt("visibilityBitfield", (1<<client));
		event.Fire();

		Client[client].Extra2 = 1;
	}
}

static void HideAnnotation(int client)
{
	Event event = CreateEvent("hide_annotation");
	if(event != INVALID_HANDLE)
	{
		event.SetInt("id", 9999-client);
		event.Fire();

		Client[client].Extra2 = 0;
	}
}