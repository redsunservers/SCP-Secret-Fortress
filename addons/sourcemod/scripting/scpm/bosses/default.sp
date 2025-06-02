#pragma semicolon 1
#pragma newdecls required

// Required, precache, downloads
public void Default_Precache(int index, BossData data)
{
}

// When unloaded such as map/plugin end
public void Default_Unload()
{
}

// Created on the player
public void Default_Create(int client)
{
	Client(client).KeycardExit = 1;
	Client(client).SilentTalk = true;
}

// Removed from the player
public void Default_Remove(int client)
{
	Attrib_Remove(client, "healing received penalty");
	Client(client).SilentTalk = false;
}

// When the player spawns in
public void Default_Spawn(int client)
{
	GoToNamedSpawn(client, "scp_spawn_p");
}

// Called twice, once with weapons false, then weapons true
public void Default_Equip(int client, bool weapons)
{
	TF2_RemovePlayerDisguise(client);
	TF2_RemoveAllItems(client);

	Attrib_Set(client, "healing received penalty", 0.0);
	
	int entity, i;
	while(TF2U_GetWearable(client, entity, i))
	{
		switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:
			{
				// Action slot items
			}
			default:
			{
				// Wearable cosmetics
				TF2_RemoveWearable(client, entity);
			}
		}
	}
}

public Action Default_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	return Plugin_Continue;
}

// Enable fakedeath to prevent the boss being removed from the player
public void Default_PlayerDeath(int client, bool &fakeDeath)
{
}

public void Default_PlayerKilled(int client, int victim, bool fakeDeath)
{
}

// Client is the boss (that a spy is disguised as)
public Action Default_SoundHook(int client, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	return Plugin_Continue;
}

public Action Default_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(attacker > 0 && attacker <= MaxClients && weapon != -1)
	{
		if(damagetype & (DMG_CLUB|DMG_SLASH))
		{
			// Resist melee weapons
			damage *= 0.5;
			return Plugin_Changed;
		}
		else
		{
			char classname[36];
			if(GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				// Resist most non-primary weapons
				if(StrContains(classname, "tf_weapon_scattergun") == -1 &&
					StrContains(classname, "tf_weapon_handgun_scout_primary") == -1 &&
					StrContains(classname, "tf_weapon_soda_popper") == -1 &&
					StrContains(classname, "tf_weapon_pep_brawler_blaster") == -1 &&
					StrContains(classname, "tf_weapon_rocketlauncher") == -1 &&
					StrContains(classname, "tf_weapon_particle_cannon") == -1 &&
					StrContains(classname, "tf_weapon_flamethrower") == -1 &&
					StrContains(classname, "tf_weapon_grenadelauncher") == -1 &&
					StrContains(classname, "tf_weapon_cannon") == -1 &&
					StrContains(classname, "tf_weapon_minigun") == -1 &&
					StrContains(classname, "tf_weapon_sniperrifle") == -1 &&
					StrContains(classname, "tf_weapon_compound_bow") == -1)
				{
					damage *= 0.75;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Default_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Plugin_Continue;
}

public TFClassType Default_TFClass()
{
	return TFClass_Unknown;
}

// Entity is what the player is looking at, can be -1
public void Default_Interact(int client, int entity)
{
}

// When a scp map relay is triggered
public void Default_RelayTrigger(int client, const char[] name, int relay, int target)
{
}

// The chase theme that will play to the victim
public float Default_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite)
{
	return 0.0;
}

// When the player presses use action key
public void Default_ActionButton(int client)
{
}

public Action Default_CalcIsAttackCritical(int client, int weapon, const char[] weaponname, bool &result)
{
	return Plugin_Continue;
}

public void Default_ConditionAdded(int client, TFCond condition)
{
}

public void Default_ConditionRemoved(int client, TFCond condition)
{
}

// Called the frame after switching weapons
public void Default_WeaponSwitch(int client)
{
}
