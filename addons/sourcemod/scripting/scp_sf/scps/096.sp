#pragma semicolon 1
#pragma newdecls required

static const char ModelMelee[] = "models/scp_sf/096/scp096_hands_7.mdl";
static const char SoundPassive[] = "freak_fortress_2/scp096/bgm.mp3";
static const char SoundEnrage[] = "freak_fortress_2/scp096/fullrage.mp3";
static const char SoundDeath[] = "freak_fortress_2/scp096/096_death.mp3";

static const int HealthMax = 1500;	// Max standard health
static const int HealthExtra = 750;	// Max regenerable health

static const float SpeedRage = 2.1;

static const float RageWarmup = 6.0;	// Rage warmup time
static const float RageDuration = 12.0;	// Rage initial duration
static const float RageExtra = 3.0;	// Rage duration per target
static const float RageWinddown = 6.0;	// After rage stun
static const float RageCooldown = 15.0;	// After rage cooldown

static int Triggered[MAXPLAYERS + 1];

public bool SCP096_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Pos[0] = 0.0;
	Client[client].Extra1 = HealthMax;
	Client[client].Extra2 = 0;

	for(int i; i<MAXPLAYERS; i++)
	{
		Triggered[i] = 0;
	}

	GiveMelee(client);
	return false;
}

public void SCP096_OnMaxHealth(int client, int &health)
{
	health = Client[client].Extra1 + HealthExtra;

	int current = GetClientHealth(client);
	if(current > health)
	{
		SetEntityHealth(client, health);
	}
	else if(current < Client[client].Extra1-HealthExtra)
	{
		Client[client].Extra1 = current+HealthExtra;
	}
}

public void SCP096_OnSpeed(int client, float &speed)
{
	if(Client[client].Extra2 == 2)
		speed *= SpeedRage;
}

public Action SCP096_OnAnimation(int client, PlayerAnimEvent_t &anim, int &data)
{
	if((anim==PLAYERANIMEVENT_ATTACK_PRIMARY || anim==PLAYERANIMEVENT_ATTACK_SECONDARY || anim==PLAYERANIMEVENT_ATTACK_GRENADE) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
		ViewModel_SetAnimation(client, GetRandomInt(0, 1) ? "attack1" : "attack2");

	return Plugin_Continue;
}

public void SCP096_OnDeath(int client, Event event)
{
	Classes_DeathScp(client, event);

	if(Client[client].Extra2 == 1)
	{
		GiveAchievement(Achievement_DeathEnrage, client);
		StopSound(client, SNDCHAN_AUTO, SoundEnrage);
	}

	char model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));	
	Classes_PlayDeathAnimation(client, model, "death_scp_096", SoundDeath, 0.0);
}

public Action SCP096_OnTakeDamage(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker<1 || attacker>MaxClients)
	{
		if(damagetype & DMG_FALL)
		{
			switch(Client[client].Extra2)
			{
				case 1:
					damage *= 0.06;

				case 2:
					damage *= 0.015;

				default:
					damage *= 0.03;
			}
			return Plugin_Changed;
		}
	}
	// don't allow stunned players or SCPs to trigger shy guy, the latter can occur when friendlyfire is on
	else if(Triggered[attacker]<2 && !TF2_IsPlayerInCondition(client, TFCond_Dazed) && !IsFriendly(Client[client].Class, Client[attacker].Class))
	{
		TriggerShyGuy(client, attacker, true);
	}
	else if(Client[client].Extra2 == 1)
	{
		damagetype |= DMG_PREVENT_PHYSICS_FORCE;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action SCP096_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	return (Triggered[victim] > 1) ? Plugin_Continue : Plugin_Handled;
}

public bool SCP096_OnSeePlayer(int client, int victim)
{
	return (!Client[client].Extra2 || Triggered[victim]>1);
}

public bool SCP096_OnGlowPlayer(int client, int victim)
{
	return (Client[client].Extra2 && Triggered[victim]>1);
}

public void SCP096_DoorTouch(int client, int door)
{
	if(Client[client].Extra2 == 2)
		DestroyOrOpenDoor(door);
}

public void SCP096_OnButton(int client, int button)
{
	float engineTime = GetGameTime();
	switch(Client[client].Extra2)
	{
		case 1:
		{
			if(Client[client].Extra3 < engineTime)
			{
				float duration = (Client[client].Disarmer*RageExtra)+RageDuration;
				if(duration > 30)
					duration = 30.0;

				Client[client].Extra3 = engineTime+duration;
				Client[client].Extra2 = 2;
				TF2_AddCondition(client, TFCond_CritCola, 99.9);

				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				int weapon = SpawnWeapon(client, "tf_weapon_sword", 310, 100, 13, "2 ; 11 ; 6 ; 0.95 ; 28 ; 3 ; 252 ; 0 ; 326 ; 2 ; 412 ; 0.6", false);
				if(weapon > MaxClients)
				{
					ApplyStrangeRank(weapon, 16);
					SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				}

				ViewModel_Create(client, ModelMelee, .sDefaultAnim = "a_fists_idle_02");
				ViewModel_SetAnimation(client, "a_fists_idle_02");
			}
		}
		case 2:
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Dazed))
				TF2_RemoveCondition(client, TFCond_Dazed);

			if(Client[client].Extra3 < engineTime)
			{
				Client[client].Disarmer = 0;
				Client[client].Extra2 = 0;
				Client[client].Extra3 = engineTime+RageCooldown;

				ViewModel_Destroy(client);
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				GiveMelee(client);

				TF2_StunPlayer(client, RageWinddown, 0.9, TF_STUNFLAG_SLOWDOWN);
				TF2_RemoveCondition(client, TFCond_CritCola);
				StopSound(client, SNDCHAN_AUTO, SoundEnrage);

				bool another096;
				for(int i=1; i<=MaxClients; i++)
				{
					if(Client[i].Class!=Client[client].Class || !Client[client].Extra2)
						continue;

					another096 = true;
					break;
				}

				if(!another096)
				{
					for(int i; i<MAXPLAYERS; i++)
					{
						Triggered[i] = 0;
					}
				}
			}
			else
			{
				static float hudIn[MAXPLAYERS + 1];
				if(hudIn[client]<engineTime && !(GetClientButtons(client) & IN_SCORE))
				{
					hudIn[client] = engineTime+0.25;

					char buffer[32];
					int amount = RoundToCeil(Client[client].Extra3-engineTime);
					for(int i; i<amount; i++)
					{
						Format(buffer, sizeof(buffer), "%s|", buffer);
					}

					SetHudTextParamsEx(0.14, 0.93, 0.425, Client[client].Colors, Client[client].Colors, 0, 0.1, 0.05, 0.05);
					ShowSyncHudText(client, HudGame, "%T", "sprint", client, buffer);
				}
			}
		}
		default:
		{
			if(Client[client].Extra3 > engineTime)
				return;
		}
	}

	static float delay;
	if(delay < engineTime)
	{
		delay = engineTime+0.25;
		static float pos1[3], ang1[3];
		GetClientEyePosition(client, pos1);
		pos1[0] += 15.0;
		GetClientEyeAngles(client, ang1);
		ang1[0] = fixAngle(ang1[0]);
		ang1[1] = fixAngle(ang1[1]);

		bool found;
		for(int target=1; target<=MaxClients; target++)
		{
			if(target==client || !IsValidClient(target) || IsSpec(target) || IsFriendly(Client[client].Class, Client[target].Class) || Triggered[target]>1)
				continue;

			static float pos2[3];
			GetClientEyePosition(target, pos2);
			// 1024 units
			if(GetVectorDistance(pos1, pos2, true) > 1048576.0)
				continue;
			
			static float ang2[3], ang3[3];
			GetClientEyeAngles(target, ang2);

			// fix all angles
			ang2[0] = fixAngle(ang2[0]);
			ang2[1] = fixAngle(ang2[1]);
			
			// check if we are looking at each other
			float fwd1[3], fwd2[3];
			GetAngleVectors(ang1, fwd1, NULL_VECTOR, NULL_VECTOR);
			GetAngleVectors(ang2, fwd2, NULL_VECTOR, NULL_VECTOR);
			if (GetVectorDotProduct(fwd1, fwd2) > -0.05)
				continue;
			
			GetVectorAnglesTwoPoints(pos2, pos1, ang3);			
			ang3[0] = fixAngle(ang3[0]);
			ang3[1] = fixAngle(ang3[1]);			

			// verify angle validity
			if(!(fabs(ang2[0] - ang3[0]) <= MAXANGLEPITCH ||
			(fabs(ang2[0] - ang3[0]) >= (360.0-MAXANGLEPITCH))))
				continue;

			if(!(fabs(ang2[1] - ang3[1]) <= MAXANGLEYAW ||
			(fabs(ang2[1] - ang3[1]) >= (360.0-MAXANGLEYAW))))
				continue;

			// ensure no wall or door is obstructing
			TR_TraceRayFilter(pos2, pos1, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);
			TR_GetEndPosition(ang3);
			if(ang3[0]!=pos1[0] || ang3[1]!=pos1[1] || ang3[2]!=pos1[2])
				continue;

			GetVectorAnglesTwoPoints(pos1, pos2, ang3);

			// fix all angles
			ang3[0] = fixAngle(ang3[0]);
			ang3[1] = fixAngle(ang3[1]);

			// verify angle validity
			if(!(fabs(ang1[0] - ang3[0]) <= MAXANGLEPITCH ||
			(fabs(ang1[0] - ang3[0]) >= (360.0-MAXANGLEPITCH))))
				continue;

			if(!(fabs(ang1[1] - ang3[1]) <= MAXANGLEYAW ||
			(fabs(ang1[1] - ang3[1]) >= (360.0-MAXANGLEYAW))))
				continue;

			// ensure no wall or door is obstructing
			TR_TraceRayFilter(pos1, pos2, MASK_BLOCKLOS, RayType_EndPoint, Trace_WorldAndBrushes);
			TR_GetEndPosition(ang3);
			if(ang3[0]!=pos2[0] || ang3[1]!=pos2[1] || ang3[2]!=pos2[2])
				continue;

			// success
			TriggerShyGuy(client, target, false);
			found = true;
		}

		if(!found && !Client[client].Extra2)
		{
			if(Client[client].IdleAt < engineTime)
			{
				if(Client[client].Pos[0])
				{
					StopSound(client, SNDCHAN_AUTO, SoundPassive);
					Client[client].Pos[0] = 0.0;
				}
			}
			else if(!Client[client].Pos[0])
			{
				EmitSoundToAll2(SoundPassive, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE, _, _, _, client);
				Client[client].Pos[0] = 1.0;
			}
		}
	}
}

static void TriggerShyGuy(int client, int target, bool full)
{
	if(full)
	{
		//if(Triggered[target] == 2)
			//return;

		Triggered[target] = 2;
	}
	else if(++Triggered[target] != 2)
	{
		return;
	}

	switch(Client[client].Extra2)
	{
		case 1:
		{
			Client[client].Disarmer++;
			if(!full)
				Config_DoReaction(target, "trigger096");
		}
		case 2:
		{
		}
		default:
		{
			if(Client[client].Pos[0])
				StopSound(client, SNDCHAN_AUTO, SoundPassive);

			Client[client].Pos[0] = 0.0;
			Client[client].Extra3 = GetGameTime()+RageWarmup;
			Client[client].FreezeFor = Client[client].Extra3;
			Client[client].Extra2 = 1;
			Client[client].Disarmer = 1;
			TF2_StunPlayer(client, RageWarmup-2.0, 0.9, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
			EmitSoundToAll2(SoundEnrage, client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, _, _, _, client);
			if(!full)
				Config_DoReaction(target, "trigger096");
		}
	}
}

static void GiveMelee(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_bottle", 1123, 1, 13, "1 ; 0 ; 252 ; 0.6 ; 412 ; 0.5", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 15);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}