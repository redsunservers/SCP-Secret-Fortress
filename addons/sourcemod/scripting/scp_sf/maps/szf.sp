#pragma semicolon 1
#pragma newdecls required

enum SZFWeaponType
{
	WeaponType_Invalid,
	WeaponType_Static,
	WeaponType_Default,
	WeaponType_Spawn,
	WeaponType_Rare,
	WeaponType_RareSpawn,
	WeaponType_StaticSpawn,
	WeaponType_DefaultNoPickup,
	WeaponType_Common,
	WeaponType_Uncommon,
	WeaponType_UncommonSpawn
};

static const char ModelMelee[] = "models/scp_sf/106/scp106_hands_1.mdl";

static int Index610;
static int Index049;
static int Index0492;
static int Carrying[MAXPLAYERS] = {INVALID_ENT_REFERENCE, ...};
static float Damage[MAXPLAYERS];
static bool TurnOn;
static bool DoRoundStart;

public void SZF_RoundStart()
{
	// actual functionality has now been moved to SZF_RoundStartDelayed, 
	// because the items get converted too early in this hook and get re-spawned afterwards when the round really begins
	DoRoundStart = true;
}

public void SZF_RoundStartDelayed()
{
	if (!DoRoundStart)
		return;
	
	char buffer[PLATFORM_MAX_PATH];
	int entity = -1;
	float pos[3];
	WeaponEnum weapon;
	while((entity=FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		switch(GetWeaponType(buffer))
		{
			case WeaponType_Common, WeaponType_Spawn:
			{
				if(Items_GetRandomWeapon(1, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Uncommon, WeaponType_UncommonSpawn:
			{
				if(Items_GetRandomWeapon(2, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Rare, WeaponType_RareSpawn:
			{
				if(Items_GetRandomWeapon(3, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Default, WeaponType_DefaultNoPickup:
			{
				int rarity = GetRandomInt(0, 6) ? GetRandomInt(1, 2) : 3;
				if(Items_GetRandomWeapon(rarity, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Static, WeaponType_StaticSpawn:
			{
				GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
				if(Items_GetWeaponByModel(buffer, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			default:
			{
				continue;
			}
		}

		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		AcceptEntityInput(entity, "DisableShadow");
		AcceptEntityInput(entity, "EnableCollision");

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 0.8;
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		TurnOn = true;
	}

	if(TurnOn)
	{
		HookEvent("teamplay_point_captured", SZF_PointCaptured);
		for(int i=1; i<MaxClients; i++)
		{
			Damage[i] = 0.0;
		}
	}
}

void SZF_RoundEnd()
{
	if(TurnOn)
	{
		TurnOn = false;
		UnhookEvent("teamplay_point_captured", SZF_PointCaptured);
	}
	
	DoRoundStart = false;
}

bool SZF_Enabled()
{
	return TurnOn;
}

bool SZF_Pickup(int client, int entity, const char[] name)
{
	if(!StrContains(name, "szf_carry", false) || !StrContains(name, "szf_pick", false) || StrEqual(name, "gascan", false))
	{
		int weapon, pos;
		while((weapon=Items_Iterator(client, pos, true)) != -1)
		{
			if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 5)
			{
				SetActiveWeapon(client, weapon);
				Items_ShowItemMenu(client);

				Carrying[client] = EntIndexToEntRef(entity);
				AcceptEntityInput(entity, "DisableMotion");
				SetEntProp(entity, Prop_Send, "m_nSolidType", 0);

				EmitSoundToClient(client, "ui/item_paint_can_pickup.wav");
				AcceptEntityInput(entity, "FireUser1", client, client);
				return true;
			}
		}
	}
	return false;
}

void SZF_PlayerRunCmd(int client)
{
	if(Carrying[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(Carrying[client]);
		if(entity > MaxClients)
		{
			static float pos[3], ang[3], vel[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			
			pos[2] -= 20.0;
			
			ang[0] = 5.0;
			ang[2] += 35.0;
			
			AnglesToVelocity(ang, vel, 60.0);
			AddVectors(pos, vel, pos);
			TeleportEntity(entity, pos, ang, NULL_VECTOR);
		}
		else
		{
			Carrying[client] = INVALID_ENT_REFERENCE;
		}
	}
}

void SZF_DropItem(int client, bool teleport=true)
{
	if(Carrying[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(Carrying[client]);
		if(entity > MaxClients)
		{
			SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
			AcceptEntityInput(entity, "EnableMotion");
			AcceptEntityInput(entity, "FireUser2", client, client);

			if(teleport)
			{
				static float pos[3];
				GetClientEyePosition(client, pos);
				if(!IsEntityStuck(entity) && !ObstactleBetweenEntities(client, entity))
				{
					pos[0] += 20.0;
					pos[2] -= 30.0;
				}

				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}

		Carrying[client] = INVALID_ENT_REFERENCE;
	}
}

public void SZF_PointCaptured(Event event, const char[] name, bool dontBroadcast)
{
	static float Cooldown;
	float engineTime = GetGameTime();
	if(Cooldown > engineTime)
		return;

	Cooldown = GetGameTime()+3.0;

	ArrayList players = ZombiePlayersList();

	ArrayList classes;
	SZF_PointWave(classes, players);

	if(classes)
	{
		ClassEnum class;
		int length = classes.Length;
		for(int i; i<length; i++)
		{
			int client = players.Get(i);
			Client[client].Class = classes.Get(i);
			static char buffer[16];
			if(Classes_GetByIndex(Client[client].Class, class))
			{
				strcopy(buffer, sizeof(buffer), class.Name);
				switch(Forward_OnClassPre(client, ClassSpawn_WaveSystem, buffer, sizeof(buffer)))
				{
					case Plugin_Changed:
					{
						Client[client].Class = Classes_GetByName(buffer, class);
						if(Client[client].Class == -1)
						{
							Client[client].Class = 0;
							Classes_GetByIndex(0, class);
						}
					}
					case Plugin_Handled:
					{
						players.Erase(i--);
						int size = players.Length;
						if(length > size)
							length = size;

						Client[client].Class = Classes_GetByName(buffer, class);
						if(Client[client].Class == -1)
						{
							Client[client].Class = 0;
							Classes_GetByIndex(0, class);
						}
					}
					case Plugin_Stop:
					{
						players.Erase(i--);
						int size = players.Length;
						if(length > size)
							length = size;

						Client[client].Class = 0;
						continue;
					}
				}
			}
			else
			{
				Client[client].Class = 0;
				Classes_GetByIndex(Client[client].Class, class);
				strcopy(buffer, sizeof(buffer), class.Name);
				switch(Forward_OnClassPre(client, ClassSpawn_WaveSystem, buffer, sizeof(buffer)))
				{
					case Plugin_Changed:
					{
						Client[client].Class = Classes_GetByName(buffer, class);
						if(Client[client].Class == -1)
						{
							Client[client].Class = 0;
							Classes_GetByIndex(0, class);
						}
					}
					case Plugin_Handled:
					{
						players.Erase(i--);
						int size = players.Length;
						if(length > size)
							length = size;

						Client[client].Class = Classes_GetByName(buffer, class);
						if(Client[client].Class == -1)
						{
							Client[client].Class = 0;
							Classes_GetByIndex(0, class);
						}
					}
					case Plugin_Stop:
					{
						players.Erase(i--);
						int size = players.Length;
						if(length > size)
							length = size;

						continue;
					}
					default:
					{
						continue;
					}
				}
			}

			Damage[client] = 0.0;
			TF2_RespawnPlayer(client);
			Forward_OnClass(client, ClassSpawn_WaveSystem, class.Name);
		}
		delete classes;
	}
	delete players;
}

public void SZF_610Enable(int index)
{
	Index610 = index;
}

public void SZF_049Enable(int index)
{
	Index049 = index;
}

public void SZF_0492Enable(int index)
{
	Index0492 = index;
	SCP0492_Enable(index);
}

public bool SZF_SpecCanSpawn(int client)
{
	return !Enabled;
}

public bool SZF_049Spawn(int client)
{
	Classes_VipSpawn(client);

	int weapon = SpawnWeapon(client, "tf_weapon_bonesaw", 413, 1, 13, "138 ; 0 ; 252 ; 0.2", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 6);
		SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
		SetEntityRenderColor(weapon, 255, 255, 255, 0);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
	return false;
}

public bool SZF_610Spawn(int client)
{
	int weapon = SpawnWeapon(client, "tf_weapon_bat", 572, 50, 13, "5 ; 1.3 ; 28 ; 0.5 ; 49 ; 1 ; 252 ; 0.5", false);
	if(weapon > MaxClients)
	{
		ApplyStrangeRank(weapon, 4);
		SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client, false));
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	ClassEnum class;
	Classes_GetByIndex(Index610, class);

	ChangeClientTeamEx(client, class.Team);

	// Model stuff
	SetVariantString(class.Model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelIndex, _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelAlt, _, 3);
	TF2_CreateGlow(client, class.Model);

	// Reset health
	SetEntityHealth(client, 125);

	// Other stuff
	TF2_AddCondition(client, TFCond_NoHealingDamageBuff, 1.0);
	return true;
}

public void SZF_049Kill(int client, int victim)
{
	ZombieRespawn(victim, client);
}

public void SZF_0492Kill(int client, int victim)
{
	static float pos1[3];
	GetClientAbsOrigin(client, pos1);
	for(int target=1; target<=MaxClients; target++)
	{
		if(!IsValidClient(target) || Client[target].Class!=Index049)
			continue;

		static float pos2[3];
		GetClientAbsOrigin(target, pos2);
		if(GetVectorDistance(pos1, pos2, true) < 999999)
		{
			ZombieRespawn(victim, target);
			return;
		}
	}
}

static void ZombieRespawn(int client, int victim)
{
	DataPack pack;
	CreateDataTimer(0.5, SZF_049Timer, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(GetClientUserId(victim));
}

public Action SZF_049Timer(Handle timer, DataPack pack)
{
	if(Enabled)
	{
		pack.Reset();
		int client = GetClientOfUserId(pack.ReadCell());
		int victim = GetClientOfUserId(pack.ReadCell());
		if(client && IsClientInGame(client) && IsPlayerAlive(client) && victim && IsClientInGame(victim))
		{
			Client[victim].Class = Index0492;
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

public void SZF_106Button(int client, int button)
{
	if(Client[client].ChargeIn && Client[client].ChargeIn<GetGameTime())
	{
		Client[client].ChargeIn = 0.0;
		TF2_RemoveCondition(client, TFCond_Dazed);
		if(TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
		{
			int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(weapon > MaxClients)
				TF2Attrib_SetByDefIndex(weapon, 821, 0.0);

			ViewModel_Create(client, ModelMelee);
			ViewModel_SetDefaultAnimation(client, "a_fists_idle_02");
			TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
			TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade);
			TF2_RemoveCondition(client, TFCond_DodgeChance);
			TF2_StunPlayer(client, 1.5, 1.0, TF_STUNFLAG_THIRDPERSON|TF_STUNFLAG_NOSOUNDOREFFECT);
		}
		else
		{
			int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
			if(weapon > MaxClients)
				TF2Attrib_SetByDefIndex(weapon, 821, 1.0);

			TF2_AddCondition(client, TFCond_SpeedBuffAlly);
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
			TF2_AddCondition(client, TFCond_DodgeChance);
		}
	}

	if(button==IN_ATTACK2 || button==IN_ATTACK3)
	{
		float engineTime = GetGameTime();
		if(Client[client].ChargeIn>engineTime || !(GetEntityFlags(client) & FL_ONGROUND))
		{
			PrintHintText(client, "%T", "106_tele_deny", client);
		}
		else
		{
			TF2_RemoveCondition(client, TFCond_Dazed);
			TF2_StunPlayer(client, 9.9, 1.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT);

			if(TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly))
			{
				Client[client].FreezeFor = engineTime+4.0;
				SetEntityMoveType(client, MOVETYPE_NONE);
				Client[client].ChargeIn = engineTime+1.0;
			}
			else
			{
				ViewModel_Destroy(client);
				Client[client].ChargeIn = engineTime+3.0;
			}

			PrintRandomHintText(client);
		}
	}
}

public Action SZF_MTFDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	damage /= 2.0;
	damagetype &= ~DMG_CRIT;
	Damage[client] += damage;
	return Plugin_Changed;
}

public Action SZF_610DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Damage[client] += damage;
	return Plugin_Continue;
}

public bool SZF_939GlowPlayer(int client, int victim)
{
	return ((Client[victim].IdleAt - GetGameTime()) > 0.0);
}

public Action SZF_HeadshotHit(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(GetEntProp(victim, Prop_Data, "m_LastHitGroup") != HITGROUP_HEAD ||
	  (IsSCP(victim) && Client[victim].Class!=Classes_GetByName("scp610")))
		return Plugin_Continue;

	damagetype |= DMG_CRIT;
	return Plugin_Changed;
}

public bool SZF_Condition(TFTeam &team)
{
	ClassEnum class;
	for(int i=1; i<=MaxClients; i++)
	{
		if(!IsValidClient(i) || IsSpec(i) || !Classes_GetByIndex(Client[i].Class, class))
			continue;

		if(class.Vip)
			return false;
	}

	int descape, dtotal;
	Gamemode_GetValue("descape", descape);
	Gamemode_GetValue("dtotal", dtotal);

	int group;
	if(descape)
	{
		SetHudTextParamsEx(-1.0, 0.3, 17.5, { 255, 200, 200, 255 }, {255, 255, 255, 255}, 1, 2.0, 1.0, 1.0);
		team = TFTeam_Red;
		group = 1;
	}
	else
	{
		SetHudTextParamsEx(-1.0, 0.3, 17.5, { 139, 0, 0, 255 }, {255, 255, 255, 255}, 1, 2.0, 1.0, 1.0);
		team = TFTeam_Blue;
		group = 3;
	}

	char buffer[16];
	FormatEx(buffer, sizeof(buffer), "team_%d", group);
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		SetGlobalTransTarget(client);
		ShowSyncHudText(client, HudGame, "%t", "end_screen_boss", buffer, descape, dtotal);
	}
	return true;
}

public float SZF_RespawnWave(ArrayList &list, ArrayList &players)
{
	int length = players.Length;
	if(length)
	{
		if(length > 6)
			length = 6;

		list = new ArrayList();
		for(int i; i<length; i++)
		{
			list.Push(Index610);
		}
	}

	float min, max;
	Gamemode_GetWaveTimes(min, max);
	return GetRandomFloat(min, max);
}

public float SZF_PointWave(ArrayList &list, ArrayList &players)
{
	int length = players.Length;
	if(length)
	{
		list = new ArrayList();
		WaveEnum wave;
		for(int i; Gamemode_GetWave(i, wave); i++)
		{
			for(int a; a<wave.TicketsLeft; a++)
			{
				list.Push(i);
			}
		}

		if(!list.Length)
		{
			delete list;
			list = null;
			return 0.0;
		}

		int index = list.Get(GetRandomInt(0, list.Length-1));
		delete list;

		Gamemode_GetWave(index, wave);

		if(length > wave.TicketsLeft)
			length = wave.TicketsLeft;

		switch(wave.Type)
		{
			case 0:
				wave.TicketsLeft -= length;

			case 1:
				wave.TicketsLeft = 0;
		}

		Gamemode_SetWave(index, wave);

		list = Gamemode_MakeClassList(wave.Classes, length);
	}
	return 0.0;
}

static SZFWeaponType GetWeaponType(const char[] buffer)
{
	if(!StrContains(buffer, "szf_weapon_spawn", false))
	{
		return WeaponType_Spawn;
	}
	else if(!StrContains(buffer, "szf_weapon_rare_spawn", false))
	{
		return WeaponType_RareSpawn;
	}
	else if(!StrContains(buffer, "szf_weapon_rare", false))
	{
		return WeaponType_Rare;
	}
	else if(!StrContains(buffer, "szf_weapon_static_spawn", false))
	{
		return WeaponType_StaticSpawn;
	}
	else if(!StrContains(buffer, "szf_weapon_static", false))
	{
		return WeaponType_Static;
	}
	else if(!StrContains(buffer, "szf_weapon_nopickup", false))
	{
		return WeaponType_DefaultNoPickup;
	}
	else if(!StrContains(buffer, "szf_weapon_common", false))
	{
		return WeaponType_Common;
	}
	else if(!StrContains(buffer, "szf_weapon_uncommon_spawn", false))
	{
		return WeaponType_UncommonSpawn;
	}
	else if(!StrContains(buffer, "szf_weapon_uncommon", false))
	{
		return WeaponType_Uncommon;
	}
	else if(StrContains(buffer, "szf_weapon", false) != -1)
	{
		return WeaponType_Default;
	}
	return WeaponType_Invalid;
}

static ArrayList ZombiePlayersList()
{
	int class = Classes_GetByName("scp610");
	int spec = Classes_GetByName("spec");
	ArrayList list = new ArrayList();
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsClientInGame(client))
			continue;

		if(Client[client].Class!=class && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))	// If not a dead ghost or 610
		{
			// Check if player is alive or in spectator team
			if((IsPlayerAlive(client) && spec!=Client[client].Class) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
				continue;
		}

		list.Push(client);
	}
	list.SortCustom(SZF_DamageSort);
	return list;
}

public int SZF_DamageSort(int index1, int index2, Handle array, Handle hndl)
{
	int client1 = GetArrayCell(array, index1);
	int client2 = GetArrayCell(array, index2);
	if(Damage[client1] > Damage[client2])
	{
		return -1;
	}
	else if(Damage[client1] < Damage[client2] || client1 > client2)
	{
		return 1;
	}
	return -1;
}