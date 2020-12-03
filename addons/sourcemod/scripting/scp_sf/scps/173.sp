//static const char Name[] = "173";
//static const char Model[] = "models/freak_fortress_2/scp_173/scp_173new.mdl";
static const int Health = 4000;
static const float Speed = 420.0;
static const char SnapSound[] = "freak_fortress_2/scp173/scp173_kill2.mp3";

static const char Downloads[][] =
{
	"models/freak_fortress_2/scp_173/scp_173new.dx80.vtx",
	"models/freak_fortress_2/scp_173/scp_173new.dx90.vtx",
	"models/freak_fortress_2/scp_173/scp_173new.mdl",
	"models/freak_fortress_2/scp_173/scp_173new.sw.vtx",
	"models/freak_fortress_2/scp_173/scp_173new.vvd",

	"materials/freak_fortress_2/scp_173/new173_texture.vmt",
	"materials/freak_fortress_2/scp_173/new173_texture.vtf",

	"freak_fortress_2/scp173/scp173_kill2.mp3"
};

void SCP173_Enable()
{
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

void SCP173_Create(int client)
{
	Client[client].Keycard = Keycard_SCP;
	Client[client].HealthPack = 0;
	Client[client].Radio = 0;
	Client[client].Floor = Floor_Heavy;

	Client[client].OnButton = SCP173_OnButton;
	Client[client].OnKill = SCP173_OnKill;
	Client[client].OnMaxHealth = SCP173_OnMaxHealth;
	Client[client].OnSpeed = SCP173_OnSpeed;

	int weapon = SpawnWeapon(client, "tf_weapon_knife", 195, 90, 13, "1 ; 0.05 ; 6 ; 0.01 ; 15 ; 0 ; 138 ; 101 ; 252 ; 0 ; 263 ; 1.15 ; 264 ; 1.15 ; 362 ; 1 ; 4328 ; 1", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 17);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public void SCP173_OnMaxHealth(int client, int &health)
{
	health = Health;
}

public void SCP173_OnSpeed(int client, float &speed)
{
	switch(Client[client].Radio)
	{
		case 0:
			speed = Speed;

		case 2:
			speed = FAR_FUTURE;
	}
}

public void SCP173_OnKill(int client, int victim)
{
	GiveAchievement(Achievement_Death173, victim);
	EmitSoundToAll(SnapSound, victim, SNDCHAN_BODY, SNDLEVEL_SCREAMING, _, _, _, client);
}

public void SCP173_OnButton(int client, int button)
{
	float engineTime = GetEngineTime();
	if(Client[client].Power > engineTime)
		return;

	Client[client].Power = engineTime+0.2;

	static int blink;
	static float pos1[3], ang1[3];
	GetClientEyePosition(client, pos1);
	GetClientEyeAngles(client, ang1);
	ang1[0] = fixAngle(ang1[0]);
	ang1[1] = fixAngle(ang1[1]);

	int status;
	for(int target=1; target<=MaxClients; target++)
	{
		if(!IsValidClient(target) || IsFriendly(Class_096, Client[target].Class))
			continue;

		static float pos2[3], ang2[3], ang3[3];
		GetClientEyePosition(target, pos2);
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
		if(blink)
		{
			status = 1;
			break;
		}

		status = 2;
		FadeMessage(target, 52, 52, 0x0002, 0, 0, 0);
	}

	if(blink > 0)
	{
		blink--;
	}
	else
	{
		blink = GetRandomInt(12, 16);
	}

	if(status == 1)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", FAR_FUTURE);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", false);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false);
		if(GetEntityMoveType(client) != MOVETYPE_NONE)
		{
			if(GetEntityFlags(client) & FL_ONGROUND)
			{
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
			else
			{
				GetEntPropVector(client, Prop_Data, "m_vecVelocity", pos1);
				pos1[0] = 0.0;
				pos1[1] = 0.0;
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, pos1);
			}
		}
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", true);
		if(GetEntityMoveType(client) != MOVETYPE_WALK)
		{
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, TRIPLE_D);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}

	if(Client[client].Radio != status)
	{
		Client[client].Radio = status;
		SDKCall_SetSpeed(client);
	}
}