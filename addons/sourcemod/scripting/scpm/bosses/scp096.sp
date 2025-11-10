#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/scp_sf/096/scp096_2.dx80.vtx",
	"models/scp_sf/096/scp096_2.dx90.vtx",
	"models/scp_sf/096/scp096_2.mdl",
	"models/scp_sf/096/scp096_2.phy",
	"models/scp_sf/096/scp096_2.vvd",
	"models/scp_sf/096/scp096_hands_7.dx80.vtx",
	"models/scp_sf/096/scp096_hands_7.dx90.vtx",
	"models/scp_sf/096/scp096_hands_7.mdl",
	"models/scp_sf/096/scp096_hands_7.vvd",
	"materials/models/vinrax/scp/scp096.vmt",
	"materials/models/vinrax/scp/scp096.vtf",
	"materials/models/vinrax/scp/scp096_eyes.vmt",
	"materials/models/vinrax/scp/scp096_eyes.vtf",
	"sound/scpm/scp096/ambient.mp3",
	"sound/scpm/scp096/chase.mp3",
	"sound/scpm/scp096/scare.mp3",
	"sound/scpm/scp096/rage.mp3"
};

static const char PlayerModel[] = "models/scp_sf/096/scp096_2.mdl";
static const char ViewModel[] = "models/scp_sf/096/scp096_hands_7.mdl";
static const char AmbientSound[] = "scpm/scp096/ambient.mp3";
static const char ChaseSound[] = "#scpm/scp096/chase.mp3";
static const char ScareSound[] = "#scpm/scp096/scare.mp3";
static const char RageSound[] = "scpm/scp096/rage.mp3";
static int BossIndex;

static bool IsMarked[MAXPLAYERS+1];
static int SCPMode[MAXPLAYERS+1];

public bool SCP096_Precache(int index)
{
	BossIndex = index;
	
	PrecacheModel(PlayerModel);
	PrecacheModel(ViewModel);
	PrecacheSound(AmbientSound);
	PrecacheSound(ChaseSound);
	PrecacheSound(ScareSound);
	PrecacheSound(RageSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
	return true;
}

public void SCP096_Create(int client)
{
	Default_Create(client);
}

public TFClassType SCP096_TFClass()
{
	return TFClass_DemoMan;
}

public void SCP096_Spawn(int client)
{
	ViewModel_DisableArms(client);
	if(!GoToNamedSpawn(client, "scp_spawn_096"))
		Default_Spawn(client);
	
	SetEntityCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
}

public void SCP096_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	if(weapons)
	{
		GiveDefaultMelee(client);
		SetEntityHealth(client, 2000);
		Human_ToggleFlashlight(client);
	}
}

public void SCP096_PlayerDeath(int client, bool &fakeDeath)
{
	PlayDeathAnimation(client, client, "death_scp_096", _, _, false, PlayerModel);

	switch(SCPMode[client])
	{
		case -1:
		{
			StopSound(client, SNDCHAN_AUTO, AmbientSound);
		}
		case 0:
		{

		}
		default:
		{
			StopSound(client, SNDCHAN_AUTO, RageSound);
		}
	}

	SCPMode[client] = 0;
}

public void SCP096_Remove(int client)
{
	Default_Remove(client);
	SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);

	switch(SCPMode[client])
	{
		case -1:
		{
			StopSound(client, SNDCHAN_AUTO, AmbientSound);
		}
		case 0:
		{

		}
		default:
		{
			StopSound(client, SNDCHAN_AUTO, RageSound);
		}
	}

	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

	SCPMode[client] = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client(client).Boss == BossIndex && i != client)
			return;
	}

	for(int i; i < sizeof(IsMarked); i++)
	{
		IsMarked[i] = false;
	}
}

public float SCP096_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite, float &volume)
{
	if(client != victim && !IsMarked[victim])
	{
		strcopy(theme, sizeof(theme), ScareSound);
		return 30.0;
	}
	
	strcopy(theme, sizeof(theme), ChaseSound);
	infinite = client != victim;
	return 12.5;
}

public Action SCP096_SoundHook(int client, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(StrContains(sample, "pl_impact_stun", false) != -1)
		return Plugin_Handled;
	
	return Default_SoundHook(client, clients, numClients, sample, entity, channel, volume, level, pitch, flags, soundEntry, seed);
}

public void SCP096_Interact(int client, int entity)
{
	if(entity > MaxClients)
		Client(client).ControlProgress = 1;
}

public Action SCP096_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Default_TakeDamage(client, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, critType);
}

public Action SCP096_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(!IsMarked[victim])
	{
		damage = 0.0;
		return Plugin_Handled;
	}
	
	damagetype &= ~DMG_NEVERGIB;
	damagetype |= DMG_BLAST;
	return Plugin_Changed;
}

public Action SCP096_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(!TF2_IsPlayerInCondition(client, TFCond_Dazed))
	{
		bool lookedAt;

		int team = GetClientTeam(client);
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != team && Client(client).LookingAt(target))
			{
				if(IsMarked[target] || TF2_IsPlayerInCondition(target, TFCond_MarkedForDeath) || Client(target).LookingAt(client))
				{
					if(!IsMarked[target])
					{
						IsMarked[target] = true;
						Humans_PlayReaction(target, "ReactRun");
						Music_StartChase(target, client, true);
					}
					
					lookedAt = true;
				}
			}
		}

		if(SCPMode[client] != 0 && SCPMode[client] != -1)
		{
			int entity = EntRefToEntIndex(SCPMode[client]);
			if(entity == client)
			{
				TF2_StunPlayer(client, 2.0, 0.99, TF_STUNFLAG_SLOWDOWN);
				
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");

				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);

				entity = Items_GiveCustom(client, 310, "tf_weapon_shovel", false, false);
				if(entity != -1)
				{
					Attrib_Set(entity, "damage bonus", 4.0);
					Attrib_Set(entity, "move speed bonus", 1.6);
					Attrib_Set(entity, "increased jump height", 1.6);
					Attrib_Set(entity, "damage force reduction", 0.0);
					Attrib_Set(entity, "airblast vulnerability multiplier", 0.0);
					Attrib_Set(entity, "mod weapon blocks healing", 1.0);

					SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);
					TF2_AddCondition(client, TFCond_MegaHeal, 17.0);

					TF2U_SetPlayerActiveWeapon(client, entity);
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);

					ViewModel_Create(client, ViewModel, "a_fists_idle_02");

					SCPMode[client] = EntIndexToEntRef(entity);
				}
			}
			else if(!TF2_IsPlayerInCondition(client, TFCond_MegaHeal))
			{
				if(entity != -1)
				{
					TF2_RemoveItem(client, entity);
					ViewModel_Destroy(client);
					GiveDefaultMelee(client);
				}

				SCPMode[client] = 0;
				TF2_StunPlayer(client, 6.0, 0.9, TF_STUNFLAG_SLOWDOWN);
			}
		}
		else
		{
			if(!lookedAt && (Client(client).LastNoiseAt + 3.0) > GetGameTime())
			{
				if(SCPMode[client] == 0)
				{
					SCPMode[client] = -1;
					EmitSoundToAll(AmbientSound, client, _, SNDLEVEL_GUNFIRE, _, 0.6);
				}
			}
			else if(SCPMode[client] == -1)
			{
				StopSound(client, SNDCHAN_AUTO, AmbientSound);
				SCPMode[client] = 0;
			}

			if(lookedAt)
			{
				SCPMode[client] = EntIndexToEntRef(client);
				TF2_StunPlayer(client, 2.2, 0.99, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
				EmitSoundToAll(RageSound, client, _, SNDLEVEL_GUNFIRE);
			}
		}
	}

	if(!Client(client).ControlProgress)
	{
		if(Client(client).KeyHintUpdateAt < GetGameTime())
		{
			Client(client).KeyHintUpdateAt = GetGameTime() + 0.5;

			if(!(buttons & IN_SCORE))
			{
				static char buffer[64];
				Format(buffer, sizeof(buffer), "%T", "SCP Controls", client);
				PrintKeyHintText(client, buffer);
			}
		}
	}

	return Plugin_Continue;
}

public Action SCP096_CalcIsAttackCritical(int client, int weapon, const char[] weaponname, bool &result)
{
	ViewModel_SetAnimation(client, (GetURandomInt() % 2) ? "attack1" : "attack2");
	return Plugin_Continue;
}

public void SCP096_PlayerKilled(int client, int victim, bool fakeDeath)
{
	if(!fakeDeath)
		Bosses_DisplayEntry(victim, "SCP096 Entry");
}

public bool SCP096_GlowTarget(int client, int target)
{
	if(!IsMarked[target] && SCPMode[client] != 0 && SCPMode[client] != -1)
	{
		Client(target).NoTransmitTo(client, true);
	}
	else
	{
		Client(target).NoTransmitTo(client, false);
	}

	return IsMarked[target];
}

static void GiveDefaultMelee(int client)
{
	int entity = Items_GiveCustom(client, 1123, _, false);
	if(entity != -1)
	{
		Attrib_Set(entity, "damage penalty", 0.0);
		Attrib_Set(entity, "max health additive bonus", 1825.0);
		Attrib_Set(entity, "move speed penalty", 0.85);
		Attrib_Set(entity, "cancel falling damage", 1.0);
		Attrib_Set(entity, "mod weapon blocks healing", 1.0);

		SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 999.9);

		TF2U_SetPlayerActiveWeapon(client, entity);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);

		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}