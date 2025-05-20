#pragma semicolon 1
#pragma newdecls required

#define PrecacheSoundArray(%1)	PrecacheSoundList(%1, sizeof(%1))
stock void PrecacheSoundList(const char[][] array, int length)
{
	for(int i; i < length; i++)
	{
		PrecacheSound(array[i]);
	}
}

#define AddFilesToDownloadsTable(%1)	AddDownloadList(%1, sizeof(%1))
stock void AddDownloadList(const char[][] array, int length)
{
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("downloadables");

	bool save = LockStringTables(false);
	
	for(int i; i < length; i++)
	{
		AddToStringTable(table, array[i]);
	}

	LockStringTables(save);
}

float FAbs(float value)
{
	return value < 0.0 ? -value : value;
}

bool TF2_GetItem(int client, int &weapon, int &pos)
{	
	static int maxWeapons;
	if(!maxWeapons)
		maxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	
	if(pos < 0)
		pos = 0;
	
	while(pos < maxWeapons)
	{
		weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", pos);
		pos++;
		
		if(weapon != -1)
			return true;
	}
	return false;
}

void TF2_RemoveItem(int client, int weapon)
{
	int entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearable");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	entity = GetEntPropEnt(weapon, Prop_Send, "m_hExtraWearableViewModel");
	if(entity != -1)
		TF2_RemoveWearable(client, entity);

	RemovePlayerItem(client, weapon);
	RemoveEntity(weapon);
}

void TF2_RemoveAllItems(int client)
{
	int entity, i;
	while(TF2_GetItem(client, entity, i))
	{
		TF2_RemoveItem(client, entity);
	}
}

int TF2_GetClassnameSlot(const char[] classname, bool econ = false)
{
	if(StrContains(classname, "tf_weapon_"))
	{
		return -1;
	}
	else if(!StrContains(classname, "tf_weapon_scattergun") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_primary") ||
	  !StrContains(classname, "tf_weapon_soda_popper") ||
	  !StrContains(classname, "tf_weapon_pep_brawler_blaster") ||
	  !StrContains(classname, "tf_weapon_rocketlauncher") ||
	  !StrContains(classname, "tf_weapon_particle_cannon") ||
	  !StrContains(classname, "tf_weapon_flamethrower") ||
	  !StrContains(classname, "tf_weapon_grenadelauncher") ||
	  !StrContains(classname, "tf_weapon_cannon") ||
	  !StrContains(classname, "tf_weapon_minigun") ||
	  !StrContains(classname, "tf_weapon_shotgun_primary") ||
	  !StrContains(classname, "tf_weapon_sentry_revenge") ||
	  !StrContains(classname, "tf_weapon_drg_pomson") ||
	  !StrContains(classname, "tf_weapon_shotgun_building_rescue") ||
	  !StrContains(classname, "tf_weapon_syringegun_medic") ||
	  !StrContains(classname, "tf_weapon_crossbow") ||
	  !StrContains(classname, "tf_weapon_sniperrifle") ||
	  !StrContains(classname, "tf_weapon_compound_bow"))
	{
		return TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_pistol") ||
	  !StrContains(classname, "tf_weapon_lunchbox") ||
	  !StrContains(classname, "tf_weapon_jar") ||
	  !StrContains(classname, "tf_weapon_handgun_scout_secondary") ||
	  !StrContains(classname, "tf_weapon_cleaver") ||
	  !StrContains(classname, "tf_weapon_shotgun") ||
	  !StrContains(classname, "tf_weapon_buff_item") ||
	  !StrContains(classname, "tf_weapon_raygun") ||
	  !StrContains(classname, "tf_weapon_flaregun") ||
	  !StrContains(classname, "tf_weapon_rocketpack") ||
	  !StrContains(classname, "tf_weapon_pipebomblauncher") ||
	  !StrContains(classname, "tf_weapon_laser_pointer") ||
	  !StrContains(classname, "tf_weapon_mechanical_arm") ||
	  !StrContains(classname, "tf_weapon_medigun") ||
	  !StrContains(classname, "tf_weapon_smg") ||
	  !StrContains(classname, "tf_weapon_charged_smg"))
	{
		return TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_re"))	// Revolver
	{
		return econ ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary;
	}
	else if(!StrContains(classname, "tf_weapon_sa"))	// Sapper
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_Secondary;
	}
	else if(!StrContains(classname, "tf_weapon_i") || !StrContains(classname, "tf_weapon_pda_engineer_d"))	// Invis & Destory PDA
	{
		return econ ? TFWeaponSlot_Item1 : TFWeaponSlot_Building;
	}
	else if(!StrContains(classname, "tf_weapon_p"))	// Disguise Kit & Build PDA
	{
		return econ ? TFWeaponSlot_PDA : TFWeaponSlot_Grenade;
	}
	else if(!StrContains(classname, "tf_weapon_bu"))	// Builder Box
	{
		return econ ? TFWeaponSlot_Building : TFWeaponSlot_PDA;
	}
	else if(!StrContains(classname, "tf_weapon_sp"))	 // Spellbook
	{
		return TFWeaponSlot_Item1;
	}
	return TFWeaponSlot_Melee;
}

void ScreenFade(int client, int duration, int time, int flags, int r, int g, int b, int a)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("Fade", client));
	bf.WriteShort(duration);
	bf.WriteShort(time);
	bf.WriteShort(flags);
	bf.WriteByte(r);
	bf.WriteByte(g);
	bf.WriteByte(b);
	bf.WriteByte(a);
	EndMessage();
}

void PrintSayText2(int client, int author, bool chat = true, const char[] message, const char[] param1 = NULL_STRING, const char[] param2 = NULL_STRING, const char[] param3 = NULL_STRING, const char[] param4 = NULL_STRING)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(author);
	bf.WriteByte(chat);
	bf.WriteString(message);
	bf.WriteString(param1);
	bf.WriteString(param2);
	bf.WriteString(param3);
	bf.WriteString(param4);
	EndMessage();
}

void PrintKeyHintText(int client, const char[] message)
{
	BfWrite bf = view_as<BfWrite>(StartMessageOne("KeyHintText", client));
	bf.WriteByte(1);
	bf.WriteString(message);
	EndMessage();
}

int GetClientPointVisible(int client, float distance = 100.0)
{
	float pos[3], vec[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, vec);
	
	Handle trace = TR_TraceRayFilterEx(pos, vec, MASK_ALL, RayType_Infinite, Trace_DontHitEntity, client);
	
	int entity = -1;
	TR_GetEndPosition(vec, trace);

	if(TR_DidHit(trace) && GetVectorDistance(pos, vec, true) < (distance * distance))
		entity = TR_GetEntityIndex(trace);
	
	delete trace;
	return entity;
}

void ModelIndexToString(int index, char[] model, int size)
{
	static int table = INVALID_STRING_TABLE;
	if(table == INVALID_STRING_TABLE)
		table = FindStringTable("modelprecache");
	
	ReadStringTable(table, index, model, size);
}

void GetVectorAnglesTwoPoints(const float start[3], const float end[3], float angles[3])
{
	angles[0] = end[0] - start[0];
	angles[1] = end[1] - start[1];
	angles[2] = end[2] - start[2];
	GetVectorAngles(angles, angles);
}

float FixAngle(float angle)
{
	while(angle < -180.0)
	{
		angle += 360.0;
	}
	while(angle > 180.0)
	{
		angle -= 360.0;
	}	
	return angle;
}

void ApplyHealEvent(int entindex, int amount)
{
	Event event = CreateEvent("player_healonhit", true);

	event.SetInt("entindex", entindex);
	event.SetInt("amount", amount);

	event.FireToClient(entindex);
	event.Cancel();
}

void CopyVector(const float from[3], float out[3])
{
	out[0] = from[0];
	out[1] = from[1];
	out[2] = from[2];
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, { 16383.0, 16383.0, -16383.0 }, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

// interpolate between 2 values as a percentage
float LerpValue(float p, float a, float b)
{
	return a + (b - a) * p;
}

int CreateExplosion(int attacker = -1, int damage = 0, int radius = -1, float pos[3], int flags = 0, const char[] killIcon = "", bool immediate = true)
{
	int explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
		return -1;
	
	char buffer[32];
	
	DispatchKeyValueVector(explosion, "origin", pos);
	
	Format(buffer, sizeof(buffer), "%d", damage);
	DispatchKeyValue(explosion, "iMagnitude", buffer);
	
	// set radius override if specified
	if (radius != -1)
	{
		Format(buffer, sizeof(buffer), "%d", radius);
		DispatchKeyValue(explosion, "iRadiusOverride", buffer);
	}
	
	Format(buffer, sizeof(buffer), "%d", flags);
	DispatchKeyValue(explosion, "spawnflags", buffer);
	
	// set attacker if specified
	if (attacker != -1)
		SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", attacker);
	
	DispatchSpawn(explosion);
	
	// change the kill icon if specified
	if (killIcon[0])
	{
		Format(buffer, sizeof(buffer), "classname %s", killIcon);
		SetVariantString(buffer);
		AcceptEntityInput(explosion, "AddOutput");
	}
	
	// do the explosion and clean up right here if it's set to do immediately, or let the explosion be manipulated further if not
	if (immediate)
	{
		AcceptEntityInput(explosion, "Explode");
		CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return explosion;
}

int AttachParticle(int entity, char[] particleType, bool attach=true, float lifetime)
{
	int particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle))
		return 0;
		
	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	if (attach)
	{
		Format(targetName, sizeof(targetName), "target%d", entity);
		DispatchKeyValue(entity, "targetname", targetName);
	
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", targetName);
	}
	
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	
	if (attach)
	{
		SetVariantString(targetName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	
	CreateTimer(lifetime, Timer_RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);	
	
	return particle;
}

int TF2_CreateLightEntity(float radius, int color[4], int brightness, float lifetime)
{
	int entity = CreateEntityByName("light_dynamic");
	if (entity != -1)
	{			
		char lightColor[32];
		Format(lightColor, sizeof(lightColor), "%d %d %d", color[0], color[1], color[2]);
		DispatchKeyValue(entity, "rendercolor", lightColor);
		
		SetVariantFloat(radius);
		AcceptEntityInput(entity, "spotlight_radius");
		
		SetVariantFloat(radius);
		AcceptEntityInput(entity, "distance");
		
		SetVariantInt(brightness);
		AcceptEntityInput(entity, "brightness");
		
		SetVariantInt(1);
		AcceptEntityInput(entity, "cone");
		
		DispatchSpawn(entity);
		
		ActivateEntity(entity);
		AcceptEntityInput(entity, "TurnOn");
		SetEntityRenderFx(entity, RENDERFX_SOLID_SLOW);
		SetEntityRenderColor(entity, color[0], color[1], color[2], color[3]);
		
		int flags = GetEdictFlags(entity);
		if (!(flags & FL_EDICT_ALWAYS))
		{
			flags |= FL_EDICT_ALWAYS;
			SetEdictFlags(entity, flags);
		}
		
		CreateTimer(lifetime, Timer_RemoveEntity, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return entity;
}

int TF2_CreateGlow(int client, const char[] model)
{
	if(!model[0])
		return -1;

	int prop = CreateEntityByName("tf_taunt_prop");
	if(IsValidEntity(prop))
	{
		int team = GetClientTeam(client);
		SetEntProp(prop, Prop_Data, "m_iInitialTeamNum", team);
		SetEntProp(prop, Prop_Send, "m_iTeamNum", team);

		DispatchSpawn(prop);

		SetEntityModel(prop, model);
		SetEntPropEnt(prop, Prop_Data, "m_hEffectEntity", client);
		SetEntProp(prop, Prop_Send, "m_bGlowEnabled", true);
		SetEntProp(prop, Prop_Send, "m_fEffects", GetEntProp(prop, Prop_Send, "m_fEffects")|EF_BONEMERGE|EF_NOSHADOW|EF_NOINTERP);

		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", client);

		SetEntityRenderMode(prop, RENDER_TRANSCOLOR);
		SetEntityRenderColor(prop, 255, 255, 255, 255);
	}
	return prop;
}

bool GoToNamedSpawn(int client, const char[] match)
{
	ArrayList list = new ArrayList();

	int entity = -1;
	char name[32];
	while((entity=FindEntityByClassname(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, match, false))
			list.Push(entity);
	}

	int length = list.Length;
	if(length)
	{
		entity = list.Get(GetRandomInt(0, length-1));

		float pos[3], ang[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ang);
		ang[0] = 0.0;
		ang[2] = 0.0;
		TeleportEntity(client, pos, ang, NULL_VECTOR);
	}

	delete list;
}

public bool Trace_OnlyHitWorld(int entity, int mask)
{
	return entity == 0;
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity != data;
}

public bool Trace_WorldAndBrushes(int entity, int mask)
{
	if(Trace_OnlyHitWorld(entity, mask))
		return true;
	
	static char buffer[8];
	return (GetEntityClassname(entity, buffer, sizeof(buffer)) && (!strncmp(buffer, "func_", 5, false)));
}