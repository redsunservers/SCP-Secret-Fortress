static const char Characters[] = "abcdefghijklmnopqrstuvwxyzABDEFGHIJKLMNOQRTUVWXYZ~`1234567890@#$^&*(){}:[]|¶�;<>.,?/'|";
static const float OFF_THE_MAP[3] = { 16383.0, 16383.0, -16383.0 };

stock int GetClassCount(ClassEnum c)
{
	int a;
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && Client[i].Class==c)
			a++;
	}
	return a;
}

stock bool IsClassTaken(ClassEnum c)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if(Client[i].Class == c)
			return true;
	}
	return false;
}

public Action Timer_UpdateClientHud(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		Event event = CreateEvent("localplayer_pickup_weapon", true);
		event.FireToClient(client);
		event.Cancel();
	}
	return Plugin_Continue;
}

void PrintRandomHintText(int client)
{
	{
		int rand = GetRandomInt(0, 19);
		if(!rand)
		{
			PrintHintText(client, "%T", "redacted", client);
			return;
		}

		if(rand == 1)
		{
			PrintHintText(client, "%T", "data_expunged", client);
			return;
		}
	}

	char buffer[16];
	for(int i; i<sizeof(buffer); i++)
	{
		buffer[i] = Characters[GetRandomInt(0, sizeof(Characters)-1)];
		if(!GetRandomInt(0, 9))
			break;
	}

	PrintHintText(client, buffer);
}

ArrayList GetSCPList()
{
	ArrayList list = new ArrayList();
	for(ClassEnum i=Class_035; i<ClassEnum; i++)
	{
		if(ClassEnabled[i])
			list.Push(i);
	}
	return list;
}

ClassEnum GetSCPRand(ArrayList list, ClassEnum pref=Class_Spec)
{
	if(pref >= Class_035)
	{
		int index = list.FindValue(pref);
		if(index != -1)
		{
			list.Erase(index);
			return pref;
		}

		if(pref == Class_939)
		{
			index = list.FindValue(Class_9392);
			if(index != -1)
			{
				list.Erase(index);
				return Class_9392;
			}
		}
	}

	int index = list.Length;
	if(!index)
		return Class_Spec;
	
	index = GetRandomInt(0, index-1);
	ClassEnum scp = list.Get(index);
	list.Erase(index);
	return scp;
}

public void RemoveRagdoll(int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return;

	int entity = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action Timer_DissolveRagdoll(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
		if(IsValidEntity(ragdoll))
			DissolveRagdoll(ragdoll);
	}
	return Plugin_Continue;
}

int DissolveRagdoll(int ragdoll)
{
	int dissolver = CreateEntityByName("env_entity_dissolver");
	if(dissolver == -1)
		return;

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}

stock int AttachParticle(int entity, char[] particleType, float offset=0.0, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%d", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity = EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR); // send it away first in case it feels like dying dramatically
		AcceptEntityInput(entity, "Kill");
	}
}

stock int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
	}
	return 2;
}

int GetClientPointVisible(int iClient, float flDistance = 100.0)
{
	float vecOrigin[3], vecAngles[3], vecEndOrigin[3];
	GetClientEyePosition(iClient, vecOrigin);
	GetClientEyeAngles(iClient, vecAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_ALL, RayType_Infinite, Trace_DontHitEntity, iClient);
	TR_GetEndPosition(vecEndOrigin, hTrace);
	
	int iReturn = -1;
	int iHit = TR_GetEntityIndex(hTrace);
	
	if (TR_DidHit(hTrace) && iHit != iClient && GetVectorDistance(vecOrigin, vecEndOrigin) < flDistance)
		iReturn = iHit;
	
	delete hTrace;
	return iReturn;
}

void SpawnPickup(int iClient, const char[] sClassname)
{
	float vecOrigin[3];
	GetClientAbsOrigin(iClient, vecOrigin);
	vecOrigin[2] += 16.0;
	
	int iEntity = CreateEntityByName(sClassname);
	DispatchKeyValue(iEntity, "OnPlayerTouch", "!self,Kill,,0,-1");
	if (DispatchSpawn(iEntity))
	{
		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", 0, 4);
		TeleportEntity(iEntity, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		CreateTimer(0.15, Timer_RemoveEntity, EntIndexToEntRef(iEntity));
	}
}

float fabs(float x)
{
	return x<0 ? -x : x;
}

float fixAngle(float angle)
{
	int i;
	for(; i<11 && angle<-180; i++)
	{
		angle += 360.0;
	}
	for(; i<11 && angle>180; i++)
	{
		angle -= 360.0;
	}	
	return angle;
}

float GetVectorAnglesTwoPoints(const float startPos[3], const float endPos[3], float angles[3])
{
	static float tmpVec[3];
	tmpVec[0] = endPos[0] - startPos[0];
	tmpVec[1] = endPos[1] - startPos[1];
	tmpVec[2] = endPos[2] - startPos[2];
	GetVectorAngles(tmpVec, angles);
}

bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;

	return true;
}

stock bool IsInvuln(int client)
{
	if(!IsValidClient(client))
		return true;

	return (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
		TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
		TF2_IsPlayerInCondition(client, TFCond_Bonked) ||
		TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode) ||
		!GetEntProp(client, Prop_Data, "m_takedamage"));
}

int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

int GetOwnerLoop(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(owner>0 && owner!=entity)
		return GetOwnerLoop(owner);

	return entity;
}

void SetAmmo(int client, int weapon, int ammo=-1, int clip=-1)
{
	if(IsValidEntity(weapon))
	{
		if(clip > -1)
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);

		int ammoType = (ammo>-1 ? GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") : -1);
		if(ammoType != -1)
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
	}
}

void TF2_RefillWeaponAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		GivePlayerAmmo(client, 9999, ammotype, true);
}

void TF2_SetWeaponAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}

int TF2_GetWeaponAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype > -1)
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	
	return -1;
}

TFTeam TF2_GetTeam(int entity)
{
	return view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum"));
}

void SetSpeed(int client, float speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", speed);
}

void FadeMessage(int client, int arg1, int arg2, int arg3, int arg4=255, int arg5=255, int arg6=255, int arg7=255)
{
	Handle msg = StartMessageOne("Fade", client);
	BfWriteShort(msg, arg1);
	BfWriteShort(msg, arg2);
	BfWriteShort(msg, arg3);
	BfWriteByte(msg, arg4);
	BfWriteByte(msg, arg5);
	BfWriteByte(msg, arg6);
	BfWriteByte(msg, arg7);
	EndMessage();
}

void PrintKeyHintText(int client, const char[] format, any ...)
{
	Handle userMessage = StartMessageOne("KeyHintText", client);
	if(userMessage == INVALID_HANDLE)
		return;

	char buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType")==FeatureStatus_Available && GetUserMessageType()==UM_Protobuf)
	{
		PbSetString(userMessage, "hints", buffer);
	}
	else
	{
		BfWriteByte(userMessage, 1); 
		BfWriteString(userMessage, buffer); 
	}
	
	EndMessage();
}

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

int SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att, int visibleMode=2, bool preserve=false)
{
	Handle weapon;
	if(preserve)
	{
		weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	}
	else
	{
		weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	}

	if(weapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, qual);
	char atts[40][40];
	int count = ExplodeString(att, ";", atts, 40, 40);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				continue;
			}

			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, weapon);
	delete weapon;
	if(entity > MaxClients)
	{
		EquipPlayerWeapon(client, entity);

		if(visibleMode == 2)
		{
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
		}
		else if(visibleMode)
		{
			SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 0);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
		}
	}
	return entity;
}

int PrecacheModelEx(const char[] model, bool preload=false)
{
	static char buffer[PLATFORM_MAX_PATH];
	strcopy(buffer, sizeof(buffer), model);
	ReplaceString(buffer, sizeof(buffer), ".mdl", "");

	int table = FindStringTable("downloadables");
	bool save = LockStringTables(false);
	char buffer2[PLATFORM_MAX_PATH];
	static const char fileTypes[][] = {"dx80.vtx", "dx90.vtx", "mdl", "phy", "sw.vtx", "vvd"};
	for(int i; i<sizeof(fileTypes); i++)
	{
		FormatEx(buffer2, sizeof(buffer2), "%s.%s", buffer, fileTypes[i]);
		if(FileExists(buffer2))
			AddToStringTable(table, buffer2);
	}
	LockStringTables(save);

	return PrecacheModel(model, preload);
}

int PrecacheSoundEx(const char[] sound, bool preload=false)
{
	char buffer[PLATFORM_MAX_PATH];
	FormatEx(buffer, sizeof(buffer), "sound/%s", sound);
	ReplaceStringEx(buffer, sizeof(buffer), "#", "");
	if(FileExists(buffer))
		AddFileToDownloadsTable(buffer);

	return PrecacheSound(sound, preload);
}

void ShowDeathNotice(int[] clients, int count, int attacker, int victim, int assister, int weaponid, const char[] weapon, int damagebits, int damageflags)
{
	Event event = CreateEvent("player_death", true);
	if(!event)
		return;

	event.SetInt("userid", victim);
	event.SetInt("attacker", attacker);
	event.SetInt("assister", assister);
	event.SetInt("weaponid", weaponid);
	event.SetString("weapon", weapon);
	event.SetInt("damagebits", damagebits);
	event.SetInt("damage_flags", damageflags);
	for(int i; i<count; i++)
	{
		event.FireToClient(clients[i]);
	}
	event.Cancel();
}

void ShowDestoryNotice(int[] clients, int count, int attacker, int victim, int assister, int weaponid, const char[] weapon, int type, int index, bool building)
{
	Event event = CreateEvent("object_destroyed", true);
	if(!event)
		return;

	event.SetInt("userid", victim);
	event.SetInt("attacker", attacker);
	event.SetInt("assister", assister);
	event.SetInt("weaponid", weaponid);
	event.SetString("weapon", weapon);
	event.SetInt("objecttype", type);
	event.SetInt("index", index);
	event.SetBool("was_building", building);
	for(int i; i<count; i++)
	{
		event.FireToClient(clients[i]);
	}
	event.Cancel();
}

public bool TraceRayPlayerOnly(int client, int mask, any data)
{
	return (client!=data && IsValidClient(client) && IsValidClient(data));
}

public bool TraceWallsOnly(int entity, int contentsMask)
{
	return false;
}

public bool Trace_OnlyHitWorld(int entity, int mask)
{
	return !entity;
}

public bool Trace_DontHitEntity(int entity, int mask, any data)
{
	return entity!=data;
}

bool IsSpec(int client)
{
	if(Client[client].Class == Class_Spec)
		return true;

	if(!IsPlayerAlive(client))
	{
		LogMessage("%N (%d) was not alive and was not Class Spec", client, client);
		return true;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		LogMessage("%N (%d) was a ghost and was not Class Spec", client, client);
		return true;
	}

	return false;
}