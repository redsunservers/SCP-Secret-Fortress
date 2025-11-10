#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/freak_fortress_2/painiscupcakev3/painiscupcakev3.dx80.vtx",
	"models/freak_fortress_2/painiscupcakev3/painiscupcakev3.dx90.vtx",
	"models/freak_fortress_2/painiscupcakev3/painiscupcakev3.mdl",
	"models/freak_fortress_2/painiscupcakev3/painiscupcakev3.phy",
	"models/freak_fortress_2/painiscupcakev3/painiscupcakev3.vvd",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_body.vmt",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_body.vtf",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_head.vmt",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_head.vtf",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_invun.vmt",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_invun.vtf",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_invun_red_head.vmt",
	"materials/freak_fortress_2/painiscupcakev3/painiscupcake_invun_red_head.vtf",
	"sound/scpm/painiscupcake/chase1.mp3",
	"sound/scpm/painiscupcake/chase2.mp3",
	"sound/scpm/painiscupcake/death1.mp3",
	"sound/scpm/painiscupcake/death2.mp3",
	"sound/scpm/painiscupcake/kill.mp3",
	"sound/scpm/painiscupcake/long.mp3",
	"sound/scpm/painiscupcake/scare.mp3",
	"sound/scpm/painiscupcake/short.mp3",
	"sound/scpm/painiscupcake/taunt.mp3"
};

static const char PlayerModel[] = "models/freak_fortress_2/painiscupcakev3/painiscupcakev3.mdl";
static const char StepLSound[] = "weapons/shotgun_cock_back.wav";
static const char StepRSound[] = "weapons/shotgun_cock_forward.wav";
static const char Rage1Sound[] = "scpm/painiscupcake/chase1.mp3";
static const char Rage2Sound[] = "scpm/painiscupcake/chase2.mp3";
static const char KillSound[] = "scpm/painiscupcake/kill.mp3";
static const char ScareSound[] = "#scpm/painiscupcake/scare.mp3";
static const char VoScream1Sound[] = "scpm/painiscupcake/death1.mp3";
static const char VoScream2Sound[] = "scpm/painiscupcake/death2.mp3";
static const char VoLongSound[] = "scpm/painiscupcake/long.mp3";
static const char VoShortSound[] = "scpm/painiscupcake/short.mp3";
static const char VoTauntSound[] = "scpm/painiscupcake/taunt.mp3";

static float StaringTime[MAXPLAYERS+1];
static int InRage[MAXPLAYERS+1];

public bool PainisCupcake_Precache(int index)
{
	PrecacheModel(PlayerModel);
	PrecacheSound(StepLSound);
	PrecacheSound(StepRSound);
	PrecacheSound(Rage1Sound);
	PrecacheSound(Rage2Sound);
	PrecacheSound(KillSound);
	PrecacheSound(ScareSound);
	PrecacheSound(VoScream1Sound);
	PrecacheSound(VoScream2Sound);
	PrecacheSound(VoLongSound);
	PrecacheSound(VoShortSound);
	PrecacheSound(VoTauntSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
	return true;
}

public void PainisCupcake_Create(int client)
{
	Default_Create(client);
}

public TFClassType PainisCupcake_TFClass()
{
	return TFClass_Soldier;
}

public void PainisCupcake_Spawn(int client)
{
	ViewModel_DisableArms(client);
	if(!GoToNamedSpawn(client, "scp_spawn_096"))
		Default_Spawn(client);
}

public void PainisCupcake_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);
	Attrib_Remove(client, "healing received penalty");

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	if(weapons)
	{
		GiveDefaultMelee(client);
		SetEntityHealth(client, 500);
		Human_ToggleFlashlight(client);
	}
}

public void PainisCupcake_PlayerDeath(int client, bool &fakeDeath)
{
	if(InRage[client])
	{
		SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
		StopSound(client, SNDCHAN_AUTO, Rage1Sound);
		StopSound(client, SNDCHAN_AUTO, Rage2Sound);

		InRage[client] = 0;
	}
}

public void PainisCupcake_Remove(int client)
{
	Default_Remove(client);

	if(InRage[client])
	{
		SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
		StopSound(client, SNDCHAN_AUTO, Rage1Sound);
		StopSound(client, SNDCHAN_AUTO, Rage2Sound);

		InRage[client] = 0;
	}
}

public float PainisCupcake_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite, float &volume)
{
	if(InRage[client])
		volume = 0.01;
	
	strcopy(theme, sizeof(theme), ScareSound);
	return 16.7;
}

public Action PainisCupcake_SoundHook(int client, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(StrContains(sample, "footstep", false) != -1)
	{
		bool left;

		for(int i = strlen(sample) - 1; i >= 0; i--)
		{
			if(IsCharNumeric(sample[i]))
			{
				left = view_as<bool>(StringToInt(sample[i]) % 2);
				break;
			}
		}

		int numClients2;
		int[] clients2 = new int[MaxClients];
		for(int target = 1; target <= MaxClients; target++)
		{
			if(target != client && IsClientInGame(target))
				clients2[numClients2++] = target;
		}

		EmitSound(clients2, numClients2, left ? StepLSound : StepRSound, client, _, SNDLEVEL_TRAIN);

		// Footsteps are client-side
		EmitSoundToClient(client, left ? StepLSound : StepRSound, client, _, _, _, 0.15);
	}
	else if(!StrContains(sample, "vo", false))
	{
		if(StrContains(sample, "activatecharge", false) != -1 ||
			StrContains(sample, "battlecry", false) != -1 ||
			StrContains(sample, "medic", false) != -1 ||
			StrContains(sample, "thanks", false) != -1)
		{
			Format(sample, sizeof(sample), VoLongSound);
		}
		else if(StrContains(sample, "cheers", false) != -1 ||
			StrContains(sample, "_go", false) != -1 ||
			StrContains(sample, "head", false) != -1 ||
			StrContains(sample, "_need", false) != -1 ||
			StrContains(sample, "niceshot", false) != -1 ||
			StrContains(sample, "_no", false) != -1 ||
			StrContains(sample, "positivevocalization", false) != -1 ||
			StrContains(sample, "sentry", false) != -1 ||
			StrContains(sample, "_yes", false) != -1)
		{
			Format(sample, sizeof(sample), VoShortSound);
		}
		else if(StrContains(sample, "cloakedspy", false) != -1 ||
			StrContains(sample, "helpme", false) != -1 ||
			StrContains(sample, "incoming", false) != -1 ||
			StrContains(sample, "jeers", false) != -1 ||
			StrContains(sample, "negative", false) != -1)
		{
			Format(sample, sizeof(sample), VoTauntSound);
		}
		else if(StrContains(sample, "paincrticialdeath", false) != -1)
		{
			if(InRage[client])
				return Plugin_Handled;
			
			int pos = FindCharInString(sample, '0', true);

			Format(sample, sizeof(sample), (StringToInt(sample[pos+1]) % 2) ? VoScream1Sound : VoScream2Sound);
		}
		else if(StrContains(sample, "directhittaunt", false) != -1 ||
			StrContains(sample, "laugh", false) != -1 ||
			StrContains(sample, "painsevere", false) != -1 ||
			StrContains(sample, "pickaxetaunt", false) != -1)
		{
			return Plugin_Continue;
		}
		else
		{
			return Plugin_Handled;
		}

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void PainisCupcake_Interact(int client, int entity)
{
	if(entity > MaxClients)
		Client(client).ControlProgress = 1;
}

public Action PainisCupcake_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	return Default_TakeDamage(client, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, critType);
}

public Action PainisCupcake_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(InRage[client] > 0 && InRage[client] != victim)
	{
		damage = 0.0;
		return Plugin_Handled;
	}
	
	damagetype &= ~DMG_NEVERGIB;
	damagetype |= DMG_BLAST;
	return Plugin_Changed;
}

public Action PainisCupcake_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	float gameTime = GetGameTime();

	if(InRage[client])
	{
		if(!TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen))
		{
			SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
			if(!StaringTime[client])
				StaringTime[client] = gameTime + 2.0;	// Cooldown
			
			InRage[client] = 0;
			GiveDefaultMelee(client);
		}
		/*else if(StaringTime[client] && !TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
			StaringTime[client] = 0.0;

			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(active != -1)
				Attrib_Set(active, "gesture speed increase", 1.5);
		}*/
	}
	else
	{
		int victim;

		int team = GetClientTeam(client);
		for(int target = 1; target <= MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != team && Client(client).LookingAt(target))
			{
				victim = target;
				break;
			}
		}

		if(victim)
		{
			// Start stare time
			if(!StaringTime[client])
				StaringTime[client] = gameTime;
			
			// Marked causes no delay
			if(TF2_IsPlayerInCondition(victim, TFCond_MarkedForDeath))
				StaringTime[client] -= 3.0;
		}
		else if(StaringTime[client] && StaringTime[client] < gameTime)
		{
			StaringTime[client] = 0.0;
			PrintCenterText(client, "");
		}

		if(StaringTime[client] && victim)
		{
			float delay = 6.0 - ((gameTime - RoundStartTime) * 0.005);
			if((StaringTime[client] + delay) < gameTime)
			{
				PrintCenterText(client, "[  X  ]");

				if(GetEntityFlags(client) & FL_ONGROUND)
				{
					Humans_PlayReaction(victim, "ReactRun");
					Music_StopSpecificTheme(ScareSound, 12.0);

					InRage[client] = victim;
					StaringTime[client] = 0.0;
					SetEntityCollisionGroup(client, COLLISION_GROUP_DEBRIS_TRIGGER);
					EmitSoundToAll((GetURandomInt() % 2) ? Rage1Sound : Rage2Sound, client, _, SNDLEVEL_GUNFIRE);

					float pos[3];
					GetClientAbsOrigin(client, pos);
					CreateEarthquake(pos, 2.0, 800.0, 16.0, 255.0);

					int entity = TF2_CreateLightEntity(200.0, {255, 0, 0, 255}, 8, 10.5);
					if(entity != -1)
					{
						TeleportEntity(entity, pos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
						SetVariantString("!activator");
						AcceptEntityInput(entity, "SetParent", client);
					}

					entity = Items_GiveCustom(client, 195, "tf_weapon_shovel");
					if(entity != -1)
					{
						Attrib_Set(entity, "damage bonus", 4.0);
						Attrib_Set(entity, "fire rate bonus", 0.6);
						Attrib_Set(entity, "crit mod disabled", 0.0);
						Attrib_Set(entity, "max health additive bonus", 800.0);
						Attrib_Set(entity, "move speed bonus", 1.8);
						Attrib_Set(entity, "heal on kill", 100.0);
						Attrib_Set(entity, "increased jump height", 1.5);
						Attrib_Set(entity, "damage force reduction", 0.8);
						Attrib_Set(entity, "cancel falling damage", 1.0);
						Attrib_Set(entity, "airblast vulnerability multiplier", 0.8);
						Attrib_Set(entity, "mod weapon blocks healing", 1.0);
						Attrib_Set(entity, "gesture speed increase", 2.0);

						SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 2.0);

						TF2U_SetPlayerActiveWeapon(client, entity);
						SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);

						FakeClientCommand(client, "taunt");
						TF2_AddCondition(client, TFCond_UberchargedCanteen, 10.5);
						TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 2.0);
					}
				}
			}
			else
			{
				PrintCenterText(client, "[%.1f]", (StaringTime[client] + delay) - gameTime);
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

public void PainisCupcake_PlayerKilled(int client, int victim, bool fakeDeath)
{
	if(InRage[client])
	{
		if(GetEntityFlags(client) & FL_ONGROUND)
		{
			StaringTime[client] = 0.0;
			InRage[client] = -1;

			int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(active != -1)
				Attrib_Set(active, "gesture speed increase", 2.5);
			
			ForceTaunt(client, 31413);
			EmitSoundToClient(victim, KillSound);
			EmitSoundToAll(KillSound, client);
		}
		else if(!fakeDeath)
		{
			StaringTime[client] = GetGameTime() + 8.0;	// Extended Cooldown
			TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
		}
	}

	if(!fakeDeath)
		Bosses_DisplayEntry(victim, "PainisCupcake Entry");
}

public bool PainisCupcake_GlowTarget(int client, int target)
{
	if(InRage[client] > 0 && InRage[client] != target)
	{
		Client(target).NoTransmitTo(client, true);
	}
	else
	{
		Client(target).NoTransmitTo(client, false);
		return InRage[client] > 0;
	}

	return false;
}

static void GiveDefaultMelee(int client)
{
	int entity = Items_GiveCustom(client, 195, "tf_weapon_shovel");
	if(entity != -1)
	{
		Attrib_Set(entity, "crit mod disabled", 0.0);
		Attrib_Set(entity, "max health additive bonus", 500.0);
		Attrib_Set(entity, "move speed penalty", 0.95);
		Attrib_Set(entity, "heal on kill", 100.0);
		Attrib_Set(entity, "damage force reduction", 0.8);
		Attrib_Set(entity, "cancel falling damage", 1.0);
		Attrib_Set(entity, "airblast vulnerability multiplier", 0.8);
		Attrib_Set(entity, "mod weapon blocks healing", 1.0);

		TF2U_SetPlayerActiveWeapon(client, entity);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
	}
}