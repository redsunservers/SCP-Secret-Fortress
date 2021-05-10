static int IndexSeeman;
static int IndexSeeldier;
static const char Seeman[] = "freak_fortress_2/seeman/seeman_see.wav";
static const char Seeldier[] = "freak_fortress_2/seeman/seeldier_see.wav";
static const char NukeSong[] = "freak_fortress_2/seeman/seeman_rage.wav";//"freak_fortress_2/seesolo/seeman_nuke.mp3";

public void Seeman_Enable(int index)
{
	IndexSeeman = index;
}

public bool Seeman_Create(int client)
{
	Classes_VipSpawn(client);

	Client[client].Extra2 = 3;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)>view_as<int>(TFTeam_Spectator))
			Client[client].Extra2++;
	}

	int weapon = SpawnWeapon(client, "tf_weapon_stickbomb", 307, 101, 5, "2 ; 3.1 ; 28 ; 0.5 ; 68 ; 2 ; 207 ; 0 ; 252 ; 0.6 ; 476 ; 0.5 ; 2025 ; 1", 0);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 20);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		CreateTimer(1.5, Seeman_CaberTimer, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
	
	return false;
}

public void Seeman_OnKill(int client, int victim)
{
	if(Seeman_Kill(client) && IndexSeeldier)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && Client[i].Class==IndexSeeldier)
			{
				Seeldier_Kill(i, victim);
				break;
			}
		}
	}
}

public Action Seeman_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		EmitSoundToAll2(Seeman, client, _, level, flags, _, pitch+GetRandomInt(-35, 30));
		return Plugin_Handled;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 30;
		EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

static bool Seeman_Kill(int client)
{
	switch(Client[client].Extra2--)
	{
		case 5:
		{
			CPrintToChatAll("%s%t", PREFIX, "seeman_5");
		}
		case 3:
		{
			CPrintToChatAll("%s%t", PREFIX, "seeman_3");
		}
		case 2:
		{
			CPrintToChatAll("%s%t", PREFIX, "seeman_2");
		}
		case 1:
		{
			CPrintToChatAll("%s%t", PREFIX, "seeman_1");
		}
		case 0:
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			TF2_AddCondition(client, TFCond_MegaHeal, 4.5);
			CreateTimer(4.5, Seeman_NukeTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

			ChangeGlobalSong(GetEngineTime()+10.0, NukeSong);

			int weapon = SpawnWeapon(client, "tf_weapon_bottle", 1, 101, 5, "2 ; 3.1 ; 68 ; 2 ; 207 ; 0 ; 252 ; 0.6 ; 2025 ; 1", 0);
			if(weapon > MaxClients)
			{
				ApplyStrangeRank(weapon, 20);
				SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
			}
			return false;
		}
		default:
		{
			if(Client[client].Extra2 < 0)
				return false;
		}
	}
	return true;
}

public Action Seeman_CaberTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients)
		return Plugin_Stop;

	SetEntProp(entity, Prop_Send, "m_bBroken", 0);
	SetEntProp(entity, Prop_Send, "m_iDetonated", 0);
	return Plugin_Continue;
}

public Action Seeman_NukeTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client) && Client[client].Class==IndexSeeman)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		for(int i=1; i<=MaxClients; i++)
		{
			if(i!=client && IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(TF2_IsPlayerInCondition(i, TFCond_HalloweenGhostMode))
					TF2_RemoveCondition(i, TFCond_HalloweenGhostMode);

				SDKHooks_TakeDamage(i, client, client, 3000.34, DMG_BLAST|DMG_CRUSH|DMG_CRIT, weapon);
			}
		}

		ChangeGlobalSong(FAR_FUTURE, NukeSong);

		FakeClientCommand(client, "+taunt");
		FakeClientCommand(client, "+taunt");
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

public void Seeldier_Enable(int index)
{
	IndexSeeldier = index;
}

public bool Seeldier_Create(int client)
{
	Classes_VipSpawn(client);

	int weapon = SpawnWeapon(client, "tf_weapon_shovel", 6, 101, 5, "2 ; 3.1 ; 28 ; 0.5 ; 68 ; 2 ; 252 ; 0.6", 0);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 20);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	
	return false;
}

public bool Seeldier2_Create(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_shovel", 6, 101, 5, "15 ; 0", 0);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	
	return false;
}

public void Seeldier_OnKill(int client, int victim)
{
	Seeldier_Kill(client, victim);

	if(IndexSeeman)
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && Client[i].Class==IndexSeeman)
			{
				Seeman_Kill(i);
				break;
			}
		}
	}
}

public Action Seeldier_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		EmitSoundToAll2(Seeldier, client, _, level, flags, _, pitch+GetRandomInt(-35, 30));
		return Plugin_Handled;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 30;
		EmitSoundToAll(sample, client, channel, level, flags, volume, pitch);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

static void Seeldier_Kill(int client, int victim)
{
	DataPack pack;
	CreateDataTimer(0.5, Seeldier_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(GetClientUserId(victim));
}

public Action Seeldier_Timer(Handle timer, DataPack pack)
{
	if(Enabled)
	{
		pack.Reset();
		int client = GetClientOfUserId(pack.ReadCell());
		int victim = GetClientOfUserId(pack.ReadCell());
		if(client && IsClientInGame(client) && IsPlayerAlive(client) && victim && IsClientInGame(victim))
		{
			Client[victim].Class = IndexSeeldier;
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