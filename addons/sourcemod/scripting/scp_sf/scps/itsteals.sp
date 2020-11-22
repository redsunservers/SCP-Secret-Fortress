//static const char Name[] = "itsteals";
//static const char Model[] = "models/freak_fortress_2/it_steals/it_steals_v39.mdl";

static const char Step[] = "scpsl/it_steals/monster_step.wav";
static const char Enrage[] = "scpsl/it_steals/enraged.mp3";
static const char ItHadEnough[] = "scpsl/it_steals/youhadyourchance.mp3";
static const char Stun[] = "scpsl/it_steals/stunned.mp3";
static const char Kill[] = "scpsl/it_steals/deathcam.mp3";

static const char Downloads[][] =
{
	"models/freak_fortress_2/it_steals/it_steals_v39.dx80.vtx",
	"models/freak_fortress_2/it_steals/it_steals_v39.dx90.vtx",
	"models/freak_fortress_2/it_steals/it_steals_v39.mdl",
	"models/freak_fortress_2/it_steals/it_steals_v39.phy",
	"models/freak_fortress_2/it_steals/it_steals_v39.sw.vtx",
	"models/freak_fortress_2/it_steals/it_steals_v39.vvd",

	"materials/freak_fortress_2/it_steals/it_steals.vmt",
	"materials/freak_fortress_2/it_steals/it_steals.vtf",

	"scpsl/it_steals/monster_step.wav",
	"scpsl/it_steals/enraged.mp3",
	"scpsl/it_steals/youhadyourchance.mp3",
	"scpsl/it_steals/stunned.mp3",
	"scpsl/it_steals/deathcam.mp3"
};

static bool Flashed[MAXTF2PLAYERS];

void ItSteals_Enable()
{
	PrecacheSound(Step, true);
	PrecacheSound(Enrage, true);
	PrecacheSound(ItHadEnough, true);

	NoMusic = true;
	Gamemode = Gamemode_Steals;
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);

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

void ItSteals_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;

	Client[client].OnButton = ItSteals_OnButton;
	Client[client].OnDealDamage = ItSteals_OnDealDamage;
	Client[client].OnGlowPlayer = ItSteals_OnGlowPlayer;
	Client[client].OnKill = ItSteals_OnKill;
	Client[client].OnMaxHealth = ItSteals_OnMaxHealth;
	Client[client].OnSeePlayer = ItSteals_OnSeePlayer;
	Client[client].OnSpeed = ItSteals_OnSpeed;

	int weapon = SpawnWeapon(client, "tf_weapon_club", 574, 10, 14, "2 ; 1.5 ; 15 ; 0 ; 275 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 16);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public void ItSteals_OnMaxHealth(int client, int &health)
{
	switch(Client[client].Radio)
	{
		case -1:
		{
			health = ((DClassMax+SciMax)*3/2)+4;
			SetEntityHealth(client, 1);
		}
		case 1:
		{
			health = 66;
			SetEntityHealth(client, 66);
		}
		case 2:
		{
			health = 666;
			SetEntityHealth(client, 666);
		}
		default:
		{
			if(SciEscaped < -1)
			{
				ForcePlayerSuicide(client);

				for(int i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==view_as<int>(TFTeam_Red))
						ChangeClientTeamEx(i, TFTeam_Blue);
				}

				EndRound(Team_MTF, TFTeam_Blue);
			}
			else
			{
				health = ((DClassMax+SciMax)*3/2)+6;
				SetEntityHealth(client, SciEscaped+2);
			}
		}
	}
}

public void ItSteals_OnSpeed(int client, float &speed)
{
	switch(Client[client].Radio)
	{
		case 1:
		{
			speed = 420.0;
		}
		case 2:
		{
			speed = 520.0;
		}
		default:
		{
			speed = 350.0+((SciEscaped/(SciMax+DClassMax)*60.0));
		}
	}
}

public void ItSteals_OnKill(int client, int victim)
{
	ClientCommand(victim, "playgamesound %s", Kill);
}

public Action ItSteals_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	return Flashed[victim] ? Plugin_Handled : Plugin_Continue;
}

public bool ItSteals_OnSeePlayer(int client, int victim)
{
	return !Flashed[victim];
}

public bool ItSteals_OnGlowPlayer(int client, int victim)
{
	return (Client[client].Radio==2 || Client[victim].IdleAt<GetEngineTime());
}

public void ItSteals_OnButton(int client, int button)
{
	float engineTime = GetEngineTime();
	switch(Client[client].Radio)
	{
		case 1:
		{
			if(Client[client].Power < engineTime)
			{
				TurnOffGlow(client);
				Client[client].Radio = 0;
				TF2_RemoveCondition(client, TFCond_CritCola);
			}
		}
		case 2:
		{
		}
		default:
		{
			static float pos1[3], pos2[3];
			GetClientEyePosition(client, pos1);
			for(int target=1; target<=MaxClients; target++)
			{
				if(!Flashed[target])
					continue;

				if(IsValidClient(target) && !IsSpec(target) && !IsSCP(target))
				{
					GetClientEyePosition(target, pos2);
					if(GetVectorDistance(pos1, pos2, true) < 1000000)
						continue;
				}
				Flashed[target] = false;
			}

			if(Client[client].IdleAt+5.0 < engineTime)
			{
				SciEscaped--;
				Client[client].IdleAt = engineTime+2.5;
			}

			if(Client[client].Power > engineTime)
				return;

			Client[client].Power = engineTime+0.15;

			static float ang1[3];
			GetClientEyeAngles(client, ang1);
			ang1[0] = fixAngle(ang1[0]);
			ang1[1] = fixAngle(ang1[1]);

			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || IsSpec(target) || IsSCP(target) || !Client[target].HealthPack || Flashed[target])
					continue;

				GetClientEyePosition(target, pos2);
				if(GetVectorDistance(pos1, pos2, true) > 125000)
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

				// success
				if(SciEscaped >= ((DClassMax+SciMax)*3/2)+4)
				{
					for(target=1; target<=MaxClients; target++)
					{
						Flashed[target] = false;
					}

					SCPKilled = 2;
					Client[client].Radio = 2;
					TurnOnGlow(client, "255 0 0", 10, 700.0);
					TF2_AddCondition(client, TFCond_CritCola);
					ChangeGlobalSong(FAR_FUTURE, ItHadEnough, true);
					TF2_StunPlayer(client, 11.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
				}
				else if(!SCPKilled && SciEscaped>=((DClassMax+SciMax)*3/4)+2)
				{
					for(target=1; target<=MaxClients; target++)
					{
						Flashed[target] = false;
					}

					SCPKilled = 1;
					Client[client].Radio = 1;
					Client[client].Power = engineTime+15.0;
					TurnOnGlow(client, "255 0 0", 10, 600.0);
					TF2_AddCondition(client, TFCond_CritCola, 15.0);
					ChangeGlobalSong(Client[client].Power, Enrage, true);
					TF2_StunPlayer(client, 4.0, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
				}
				else
				{
					SciEscaped++;
					Flashed[target] = true;
					ClientCommand(target, "playgamesound %s", Stun);
					SDKCall_SetSpeed(client);
				}
				break;
			}
		}
	}
}

void ItSteals_Step(char[] sound, int length)
{
	strcopy(sound, length, Step);
}

void TurnOnGlow(int client, const char[] color, int brightness, float distance)
{
	int entity = CreateEntityByName("light_dynamic");
	if(!IsValidEntity(entity))
		return; // It shouldn't.

	DispatchKeyValue(entity, "_light", color);
	SetEntProp(entity, Prop_Send, "m_Exponent", brightness);
	SetEntPropFloat(entity, Prop_Send, "m_Radius", distance);
	DispatchSpawn(entity);

	static float pos[3];
	GetClientEyePosition(client, pos);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);
	Client[client].HealthPack = EntIndexToEntRef(entity);
}

void TurnOffGlow(int client)
{
	if(Gamemode!=Gamemode_Steals || !Client[client].HealthPack)
		return;

	int entity = EntRefToEntIndex(Client[client].HealthPack);
	if(entity>MaxClients && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "TurnOff");
		CreateTimer(0.1, Timer_RemoveEntity, Client[client].HealthPack, TIMER_FLAG_NO_MAPCHANGE);
	}
	Client[client].HealthPack = 0;
}

void TurnOnFlashlight(int client)
{
	if(Client[client].HealthPack)
		TurnOffFlashlight(client);

	// Spawn the light that only everyone else will see.
	int ent = CreateEntityByName("point_spotlight");
	if(ent == -1)
		return;

	static float pos[3];
	GetClientEyePosition(client, pos);
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(ent, "spotlightlength", "1024");
	DispatchKeyValue(ent, "spotlightwidth", "512");
	DispatchKeyValue(ent, "rendercolor", "255 255 255");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client);
	AcceptEntityInput(ent, "LightOn");

	Client[client].HealthPack = EntIndexToEntRef(ent);
}

void TurnOffFlashlight(int client)
{
	if(Gamemode!=Gamemode_Steals || !Client[client].HealthPack)
		return;

	int entity = EntRefToEntIndex(Client[client].HealthPack);
	if(entity>MaxClients && IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "LightOff");
		CreateTimer(0.1, Timer_RemoveEntity, Client[client].HealthPack, TIMER_FLAG_NO_MAPCHANGE);
	}
	Client[client].HealthPack = 0;
}

int CreateWeaponGlow(int iEntity, float flDuration)
{
	int iGlow = CreateEntityByName("tf_taunt_prop");
	if (IsValidEntity(iGlow) && DispatchSpawn(iGlow))
	{
		int index = -1;
		if(HasEntProp(iEntity, Prop_Send, "m_iWorldModelIndex"))
		{
			index = GetEntProp(iEntity, Prop_Send, "m_iWorldModelIndex");
		}
		else
		{
			index = GetEntProp(iEntity, Prop_Send, "m_nModelIndex");
		}

		if(index < 0)
			return -1;

		static char model[PLATFORM_MAX_PATH];
		ModelIndexToString(index, model, sizeof(model));
		SetEntityModel(iGlow, model);
		SetEntProp(iGlow, Prop_Send, "m_nSkin", 0);
		
		SetEntPropEnt(iGlow, Prop_Data, "m_hEffectEntity", iEntity);
		SetEntProp(iGlow, Prop_Send, "m_bGlowEnabled", true);
		
		int iEffects = GetEntProp(iGlow, Prop_Send, "m_fEffects");
		SetEntProp(iGlow, Prop_Send, "m_fEffects", iEffects | EF_BONEMERGE | EF_NOSHADOW | EF_NORECEIVESHADOW);
		
		SetVariantString("!activator");
		AcceptEntityInput(iGlow, "SetParent", iEntity);
		
		CreateTimer(flDuration, Timer_RemoveEntity, EntIndexToEntRef(iGlow), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return iGlow;
}