//static const char Name[] = "096";
static const char Model[] = "models/scp_sf/096/scp096_2.mdl";
static const char ModelMelee[] = "models/scp_sf/096/scp096_hands_7.mdl";
static const char SoundPassive[] = "freak_fortress_2/scp096/bgm.mp3";
static const char SoundEnrage[] = "freak_fortress_2/scp096/fullrage.mp3";

static const int HealthMax = 1875;	// Max standard health
static const int HealthExtra = 425;//437.5// Max regenerable health
static const int HealthRage = 75;//87.5	// Extra health per target in rage

static const float SpeedPassive = 230.0;
static const float SpeedRage = 480.0;

static const float RageWarmup = 6.0;	// Rage warmup time
static const float RageDuration = 12.0;	// Rage initial duration
static const float RageExtra = 3.0;	// Rage duration per target
static const float RageWinddown = 6.0;	// After rage stun
static const float RageCooldown = 15.0;	// After rage cooldown

static const char Downloads[][] =
{
	"models/scp_sf/096/scp096_2.dx80.vtx",
	"models/scp_sf/096/scp096_2.dx90.vtx",
	"models/scp_sf/096/scp096_2.mdl",
	"models/scp_sf/096/scp096_2.phy",
	"models/scp_sf/096/scp096_2.sw.vtx",
	"models/scp_sf/096/scp096_2.vvd",

	"models/scp_sf/096/scp096_hands_7.dx80.vtx",
	"models/scp_sf/096/scp096_hands_7.dx90.vtx",
	"models/scp_sf/096/scp096_hands_7.mdl",
	"models/scp_sf/096/scp096_hands_7.sw.vtx",
	"models/scp_sf/096/scp096_hands_7.vvd",

	"materials/models/vinrax/scp/scp096.vmt",
	"materials/models/vinrax/scp/scp096.vtf",
	"materials/models/vinrax/scp/scp096_eyes.vmt",
	"materials/models/vinrax/scp/scp096_eyes.vtf",

	"sound/freak_fortress_2/scp096/bgm.mp3",
	"sound/freak_fortress_2/scp096/fullrage.mp3"
};

static int Triggered[MAXTF2PLAYERS];

void SCP096_Enable()
{
	PrecacheModel(ModelMelee, true);
	PrecacheSound(SoundPassive, true);
	PrecacheSound(SoundEnrage, true);

	int table = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	for(int i; i<sizeof(Downloads); i++)
	{
		if(!FileExists(Downloads[i], true))
		{
			LogError("Missing file: '%s'", Downloads[i]);
			continue;
		}

		AddToStringTable(table, Downloads[i]);
	}
	LockStringTables(save);
}

void SCP096_Create(int client)
{
	Client[client].Pos[0] = 0.0;
	Client[client].Extra1 = HealthMax;
	Client[client].Extra2 = 0;
	Client[client].Floor = Floor_Heavy;

	Client[client].OnAnimation = SCP096_OnAnimation;
	Client[client].OnButton = SCP096_OnButton;
	Client[client].OnDealDamage = SCP096_OnDealDamage;
	Client[client].OnDeath = SCP096_OnDeath;
	Client[client].OnGlowPlayer = SCP096_OnGlowPlayer;
	Client[client].OnKeycard = Items_KeycardScp;
	Client[client].OnMaxHealth = SCP096_OnMaxHealth;
	Client[client].OnSeePlayer = SCP096_OnSeePlayer;
	Client[client].OnSpeed = SCP096_OnSpeed;
	Client[client].OnTakeDamage = SCP096_OnTakeDamage;

	SetEntityHealth(client, HealthMax+HealthExtra);

	GiveMelee(client);
}

public void SCP096_OnMaxHealth(int client, int &health)
{
	health = Client[client].Extra1 + HealthExtra + (Client[client].Disarmer*HealthRage);

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
	speed = Client[client].Extra2==2 ? SpeedRage : SpeedPassive;
}

public Action SCP096_OnAnimation(int client, PlayerAnimEvent_t &anim, int &data)
{
	if((anim==PLAYERANIMEVENT_ATTACK_PRIMARY || anim==PLAYERANIMEVENT_ATTACK_SECONDARY || anim==PLAYERANIMEVENT_ATTACK_GRENADE) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
		ViewModel_SetAnimation(client, GetRandomInt(0, 1) ? "attack1" : "attack2");

	return Plugin_Continue;
}

public void SCP096_OnDeath(int client, int attacker)
{
	if(Client[client].Extra2 == 1)
	{
		GiveAchievement(Achievement_DeathEnrage, client);
		StopSound(client, SNDCHAN_VOICE, SoundEnrage);
	}

	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		int entity = CreateEntityByName("prop_dynamic_override");
		if(!IsValidEntity(entity))
			return;

		RequestFrame(RemoveRagdoll, GetClientUserId(client));
		{
			float pos[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		}
		DispatchKeyValue(entity, "skin", "0");
		DispatchKeyValue(entity, "model", Model);	
		{
			float angles[3];
			GetClientEyeAngles(client, angles);
			angles[0] = 0.0;
			angles[2] = 0.0;
			DispatchKeyValueVector(entity, "angles", angles);
		}
		DispatchSpawn(entity);

		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		SetVariantString("death_scp_096");
		AcceptEntityInput(entity, "SetAnimation");
	}
}

public Action SCP096_OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(Triggered[attacker]<2 && !TF2_IsPlayerInCondition(client, TFCond_Dazed))
		TriggerShyGuy(client, attacker, true);

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
	return (Client[client].Extra2==2 && Triggered[victim]>1);
}

public void SCP096_OnButton(int client, int button)
{
	float engineTime = GetEngineTime();
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
				Client[client].OnKeycard = Items_KeycardAll;
				Client[client].Extra2 = 2;
				TF2_AddCondition(client, TFCond_CritCola, 99.9);

				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				int weapon = SpawnWeapon(client, "tf_weapon_sword", 195, 100, 13, "2 ; 11 ; 6 ; 0.95 ; 28 ; 3 ; 252 ; 0 ; 326 ; 2 ; 4328 ; 1", false);
				if(weapon > MaxClients)
				{
					ApplyStrangeRank(weapon, 16);
					SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
				}

				ViewModel_Create(client, ModelMelee);
				ViewModel_Hide(client);
				ViewModel_SetDefaultAnimation(client, "a_fists_idle_02");
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
				Client[client].OnKeycard = Items_KeycardScp;
				Client[client].Extra3 = engineTime+RageCooldown;

				ViewModel_Destroy(client);
				TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
				GiveMelee(client);

				TF2_StunPlayer(client, RageWinddown, 0.9, TF_STUNFLAG_SLOWDOWN);
				TF2_RemoveCondition(client, TFCond_CritCola);
				StopSound(client, SNDCHAN_VOICE, SoundEnrage);

				bool another096;
				for(int i=1; i<=MaxClients; i++)
				{
					if(Client[i].Class!=Class_096 || !Client[client].Extra2)
						continue;

					another096 = true;
					break;
				}

				if(!another096)
				{
					for(int i; i<MAXTF2PLAYERS; i++)
					{
						Triggered[i] = 0;
					}
				}
			}
			else
			{
				static float hudIn[MAXTF2PLAYERS];
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
			if(Client[client].Extra3 < engineTime)
			{
				Client[client].Extra3 = engineTime+0.25;
				static float pos1[3], ang1[3];
				GetClientEyePosition(client, pos1);
				GetClientEyeAngles(client, ang1);
				ang1[0] = fixAngle(ang1[0]);
				ang1[1] = fixAngle(ang1[1]);

				bool found;
				for(int target=1; target<=MaxClients; target++)
				{
					if(!IsValidClient(target) || IsFriendly(Class_096, Client[target].Class) || Triggered[target]>1)
						continue;

					static float pos2[3];
					GetClientEyePosition(target, pos2);
					if(GetVectorDistance(pos1, pos2, true) > 499999)
						continue;

					static float ang2[3], ang3[3];
					GetClientEyeAngles(target, ang2);
					GetVectorAnglesTwoPoints(pos2, pos1, ang3);

					// fix all angles
					ang2[0] = fixAngle(ang2[0]);
					ang2[1] = fixAngle(ang2[1]);
					ang3[0] = fixAngle(ang3[0]);
					ang3[1] = fixAngle(ang3[1]);

					// verify angle validity
					if(!(fabs(ang2[0] - ang3[0]) <= MAXANGLEPITCH ||
					(fabs(ang2[0] - ang3[0]) >= (360.0-MAXANGLEPITCH))))
						continue;

					if(!(fabs(ang2[1] - ang3[1]) <= MAXANGLEYAW ||
					(fabs(ang2[1] - ang3[1]) >= (360.0-MAXANGLEYAW))))
						continue;

					// ensure no wall is obstructing
					TR_TraceRayFilter(pos2, pos1, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
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

					// ensure no wall is obstructing
					TR_TraceRayFilter(pos1, pos2, (CONTENTS_SOLID | CONTENTS_AREAPORTAL | CONTENTS_GRATE), RayType_EndPoint, TraceWallsOnly);
					TR_GetEndPosition(ang3);
					if(ang3[0]!=pos2[0] || ang3[1]!=pos2[1] || ang3[2]!=pos2[2])
						continue;

					// success
					TriggerShyGuy(client, target, false);
					found = true;
					break;
				}

				if(!found)
				{
					if(Client[client].IdleAt < engineTime)
					{
						if(Client[client].Pos[0])
						{
							StopSound(client, SNDCHAN_VOICE, SoundPassive);
							Client[client].Pos[0] = 0.0;
						}
					}
					else if(!Client[client].Pos[0])
					{
						EmitSoundToAll(SoundPassive, client, SNDCHAN_VOICE, SNDLEVEL_TRAIN, _, _, _, client);
						Client[client].Pos[0] = 1.0;
					}
				}
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
			if(++Client[client].Disarmer < 7)
				Client[client].Extra3 += RageExtra;
		}
		default:
		{
			if(Client[client].Pos[0])
				StopSound(client, SNDCHAN_VOICE, SoundPassive);

			Client[client].Pos[0] = 0.0;
			Client[client].Extra3 = GetEngineTime()+RageWarmup;
			Client[client].Extra2 = 1;
			Client[client].Disarmer = 1;
			TF2_StunPlayer(client, 9.9, 0.9, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);
			EmitSoundToAll(SoundEnrage, client, SNDCHAN_VOICE, SNDLEVEL_TRAIN, _, _, _, client);
			if(!full)
				Config_DoReaction(target, "trigger096");
		}
	}

	SetEntityHealth(client, GetClientHealth(client)+HealthRage);
}

static void GiveMelee(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_bottle", 1123, 1, 13, "1 ; 0 ; 252 ; 0.6", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 15);
		SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}