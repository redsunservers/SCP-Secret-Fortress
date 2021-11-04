static const char Theme[] = "#scp_sf/itstlives/yu5w56wile.mp3";
static const char Anger[] = "scp_sf/itstlives/914aa3cd.mp3";
static const char TimeUp[] = "#scp_sf/itstlives/youhadyourchance.mp3";
static const char TheEnd[] = "scp_sf/itstlives/a3ao8zi_aeaux.mp3";
static const char Overlay[] = "freak_fortress_2/scp_173/scp173_rage_overlay1.vmt";

public Action SCPSF_OnClassPre(int client, char[] class, ClassSpawnEnum context)
{
	if(context == ClassSpawn_Other)
	{
		if(StrEqual(class, "itstlives"))
		{
			strcopy(class, 16, "void");
			PrintToChatAll("You can't summon me...");
			return Plugin_Changed;
		}

		if(Client[client].Class == Classes_GetByName("itstlives"))
		{
			strcopy(class, 16, "itstlives");
			PrintToChatAll("You can't rid me...");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public bool Corruptor_Create(int client)
{
	ServerCommand("mp_timelimit 1");

	char buffer[128];
	FormatEx(buffer, sizeof(buffer), "6 ; 0 ; 187 ; 6 ; 201 ; %.2f ; 252 ; 0 ; 4328 ; 1", GetRandomFloat(0.8, 1.2));

	int weapon = SpawnWeapon(client, "tf_weapon_knife", 461, 0, 0, buffer, false);
	if(weapon > MaxClients)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);

	ViewModel_Create(client, "models/scp_sf/049/c_arms_scp049_knife_1.mdl");
	ViewModel_SetDefaultAnimation(client, "b_idle");
	ViewModel_SetAnimation(client, "b_draw");

	ViewModel_Create(client, "models/scp_sf/096/scp096_hands_7.mdl");
	ViewModel_SetDefaultAnimation(client, "attack1");
	ViewModel_SetAnimation(client, "a_fists_idle_02");

	ViewModel_Create(client, "models/scp_sf/106/scp106_hands_1.mdl");
	ViewModel_SetDefaultAnimation(client, "fists_draw");
	ViewModel_SetAnimation(client, "fists_draw");

	for(int i=1; i<=MaxClients; i++)
	{
		if(i!=client && IsClientInGame(i))
			EmitSoundToClient(i, "scp_sf/itstlives/nm-3exu7_e5146mlogi_et9u.mp3", client);
	}

	return false;
}

public void Corruptor_OnButton(int client, int button)
{
	float engineTime = GetEngineTime();
	if(Client[client].Extra3 > engineTime)
		return;

	Client[client].Extra3 = engineTime+1.5;

	if(NoMusic || NoMusicRound)
		return;

	static float pos1[3];
	GetClientAbsOrigin(client, pos1);
	for(int target=1; target<=MaxClients; target++)
	{
		if(target==client || !IsValidClient(target) || IsSpec(target) || IsFriendly(Client[client].Class, Client[target].Class) || !StrContains(Client[target].CurrentSong, "#scp_sf/itstlives"))
			continue;

		static float pos2[3];
		GetClientEyePosition(target, pos2);
		if(GetVectorDistance(pos1, pos2, true) < 999999)
		{
			ChangeSong(target, 40.0, Theme, 1);
			Config_DoReaction(target, "trigger096");
			SetEntProp(target, Prop_Send, "m_iHideHUD", 128);
		}
	}
}

public bool Corruptor_OnCanSpawn(int client)
{
	return false;
}

public void Corruptor_OnDeath(int client, Event event)
{
	EmitSoundToAll2("scp_sf/itstlives/caeio1autmwu.mp3", client);
	EmitSoundToAll2("scp_sf/itstlives/caeio1autmwu.mp3", client);

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
		{
			char model[PLATFORM_MAX_PATH];
			GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
			DispatchKeyValue(entity, "model", model);
		}	
		{
			float angles[3];
			GetClientEyeAngles(client, angles);
			angles[0] = 0.0;
			angles[2] = 0.0;
			DispatchKeyValueVector(entity, "angles", angles);
		}
		DispatchSpawn(entity);

		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		SetVariantString("DEAD");
		AcceptEntityInput(entity, "SetAnimation");
	}

	char buffer[16] = "void";
	int index = Classes_GetByName(buffer);
	if(Classes_AssignClass(client, ClassSpawn_Death, index))
	{
		Client[client].Class = index;
		Classes_AssignClassPost(client, ClassSpawn_Death);
	}
}

public void Corruptor_OnKill(int client, int victim)
{
	DataPack pack;
	CreateDataTimer(1.5, Corruptor_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(GetClientUserId(victim));

	ClientCommand(victim, "playgamesound scp_sf/itstlives/k_uom.mp3");
	ClientCommand(victim, "playgamesound scp_sf/itstlives/k_uom.mp3");

	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	ClientCommand(victim, "r_screenoverlay %s", Overlay);
	SetCommandFlags("r_screenoverlay", flags);

	int targets;
	for(int i=1; i<=MaxClients; i++)
	{
		if(i!=client && i!=victim && IsClientInGame(i) && IsPlayerAlive(i) && Client[i].Class!=Client[client].Class)
			targets++;
	}

	if(targets > 1)
	{
		static bool WasMad;
		if(!WasMad && !GetRandomInt(0, targets))
		{
			WasMad = true;
			ChangeGlobalSong(10.0, Anger, 1);
		}
	}
	else if(targets == 1)
	{
		static bool WasSuper;
		if(!WasSuper)
		{
			WasSuper = true;
			NoMusicRound = true;
			for(int i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					ChangeSong(i, FAR_FUTURE, TimeUp, 4);
					FadeMessage(i, 1000, 999999999, 0x0012, 50, 0, 0, 100);
				}
			}
			CreateTimer(115.5, Corrupter_TheEnd, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		NoMusicRound = true;
		ChangeGlobalSong(FAR_FUTURE, TheEnd, 3);
		CreateTimer(5.5, Corrupter_TheEnd, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Corrupter_OnTakeDamage(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(damage < 100.0)
		return Plugin_Continue;

	damage = 100.0;
	return Plugin_Changed;
}

public Action Corrupter_TheEnd(Handle timer)
{
	int entity = CreateEntityByName("game_end");
	if(IsValidEntity(entity) && DispatchSpawn(entity))
		AcceptEntityInput(entity, "EndGame");

	return Plugin_Continue;
}

public Action Corruptor_Timer(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int victim = GetClientOfUserId(pack.ReadCell());
	if(victim && IsClientInGame(victim))
	{
		int flags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
		ClientCommand(victim, "r_screenoverlay off");
		SetCommandFlags("r_screenoverlay", flags);

		if(Enabled && client && IsClientInGame(client) && IsPlayerAlive(client))
		{
			Client[victim].Class = Client[client].Class;
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

public Action Corruptor_OnSound(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		strcopy(sample, PLATFORM_MAX_PATH, GetRandomInt(0, 29) ? "scp_sf/itstlives/ycoe7ou.mp3" : "scp_sf/itstlives/jmtm.mp3");
		EmitSoundToAll2(sample, client, channel, level, flags, volume);
		EmitSoundToAll2(sample, client, channel, level, flags, volume);
		return Plugin_Handled;
	}

	if(StrContains(sample, "footsteps", false) != -1)
	{
		strcopy(sample, PLATFORM_MAX_PATH, "hl1/fvox/hiss.wav");
		return Plugin_Changed;
	}

	return Plugin_Continue;
}