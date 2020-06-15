#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#pragma newdecls required

float Cooldown[36];

public void OnPluginStart()
{
	AddCommandListener(Console_VoiceMenu, "voicemenu");
	HookEntityOutput("logic_relay", "OnTrigger", OnRelayTrigger);
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &weapon)
{
	//If an item was succesfully grabbed
	if(iButtons & IN_ATTACK)
	{
		if(AttemptGrabItem(client))
			iButtons &= ~IN_ATTACK;
	}
	else if(iButtons & IN_ATTACK2)
	{
		if(AttemptGrabItem(client, true))
			iButtons &= ~IN_ATTACK2;
	}

	if(weapon)
	{
		static bool boosted[36];
		if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) == weapon)
		{
			if(!boosted[client])
			{
				TF2Attrib_SetByDefIndex(client, 68, 9.0);
				TF2Attrib_SetByDefIndex(client, 442, 9.0);
				TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
				boosted[client] = true;
				PrintToChat(client, "Speed/Capture Rate Boosted");
			}
		}
		else if(boosted[client])
		{
			TF2Attrib_SetByDefIndex(client, 68, 0.0);
			TF2Attrib_SetByDefIndex(client, 442, 1.0);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
			boosted[client] = false;
			PrintToChat(client, "Speed/Capture Rate Normal");
		}
	}

	return Plugin_Continue;
}

public Action Console_VoiceMenu(int client, const char[] command, int args)
{
	if(args < 1)
		return Plugin_Continue;
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	char arg1[32], arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if (arg1[0] != '0' || arg2[0] != '0')
	{
		if (AttemptGrabItem(client, true))
			return Plugin_Handled;
	}
	else
	{
		if (AttemptGrabItem(client))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnRelayTrigger(const char[] output, int entity, int client, float delay)
{
	char name[32];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));

	if(!StrContains(name, "scp_access", false))
	{
		if(!IsValidClient(client))
			return Plugin_Continue;

		int id = StringToInt(name[11]);
		PrintToChat(client, "Id: %d | Entity: %d | Name: %s", id, entity, name);

		if(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
		{
			if(id < 2)
			{
				AcceptEntityInput(entity, "FireUser3", client, client);
			}
			else
			{
				AcceptEntityInput(entity, "FireUser1", client, client);
			}
		}
		else
		{
			AcceptEntityInput(entity, "FireUser4", client, client);
		}
	}
	else if(!StrContains(name, "scp_removecard", false))
	{
		PrintToChat(client, "Entity: %d | Name: %s", entity, name);
	}
	else if(!StrContains(name, "scp_respawn", false))
	{
		if(!IsValidClient(client))
			return Plugin_Continue;

		PrintToChat(client, "Entity: %d | Name: %s", entity, name);

		int target = -1;
		static int spawns[36];
		int count;
		while((target=FindEntityByClassname(target, "info_player_teamspawn")) != -1)
		{
			if(GetEntProp(target, Prop_Send, "m_iTeamNum") == 2)
				spawns[count++] = target;

			if(count >= sizeof(spawns))
				break;
		}

		target = spawns[GetRandomInt(0, count-1)];

		static float pos[3];
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	}
	else if(!StrContains(name, "scp_femur", false))
	{
		PrintToChat(client, "Entity: %d | Name: %s", entity, name);
	}

	return Plugin_Continue;
}

bool AttemptGrabItem(int client, bool mode=false)
{
	float gameTime = GetGameTime();
	if(Cooldown[client] > gameTime)
		return false;

	Cooldown[client] = gameTime+1.0;

	int entity = GetClientPointVisible(client);
	if(entity < 1)
		return false;

	char name[255];
	GetEntityClassname(entity, name, sizeof(name));
	if(!StrContains(name, "prop_dynamic"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_keycard_", false))
		{
			if(mode)
				RemoveEntity(entity);

			return true;
		}
		else if(!StrContains(name, "scp_healthkit", false))
		{
			if(mode)
				RemoveEntity(entity);

			return true;
		}
		else if(!StrContains(name, "scp_weapon", false))
		{
			if(mode)
				RemoveEntity(entity);

			return true;
		}
		else if(!StrContains(name, "scp_trigger", false))
		{
			switch(TF2_GetClientTeam(client))
			{
				case TFTeam_Unassigned:
					AcceptEntityInput(entity, "FireUser1", client, client);

				case TFTeam_Red:
					AcceptEntityInput(entity, "FireUser2", client, client);

				case TFTeam_Blue:
					AcceptEntityInput(entity, "FireUser3", client, client);
			}
			return true;
		}
	}
	else if(StrEqual(name, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
	}
	return true;
}

stock bool PointsAtTarget(float vecPos[3], any iTarget)
{
	float vecTargetPos[3];
	GetClientEyePosition(iTarget, vecTargetPos);
	
	Handle hTrace = TR_TraceRayFilterEx(vecPos, vecTargetPos, MASK_VISIBLE, RayType_EndPoint, Trace_DontHitOtherEntities, iTarget);
	
	int iHit = -1;
	if (TR_DidHit(hTrace))
		iHit = TR_GetEntityIndex(hTrace);
	
	delete hTrace;
	return (iHit == iTarget);
}

stock int GetClientPointVisible(int iClient, float flDistance = 100.0)
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

stock bool ObstactleBetweenEntities(int iEntity1, int iEntity2)
{
	float vecOrigin1[3];
	float vecOrigin2[3];
	
	if (IsValidClient(iEntity1))
		GetClientEyePosition(iEntity1, vecOrigin1);
	else
		GetEntPropVector(iEntity1, Prop_Send, "m_vecOrigin", vecOrigin1);
	
	GetEntPropVector(iEntity2, Prop_Send, "m_vecOrigin", vecOrigin2);
	
	Handle hTrace = TR_TraceRayFilterEx(vecOrigin1, vecOrigin2, MASK_ALL, RayType_EndPoint, Trace_DontHitEntity, iEntity1);
	
	bool bHit = TR_DidHit(hTrace);
	int iHit = TR_GetEntityIndex(hTrace);
	delete hTrace;
	
	if (!bHit || iHit != iEntity2)
		return true;
	
	return false;
}

stock void AnglesToVelocity(const float vecAngle[3], float vecVelocity[3], float flSpeed = 1.0)
{
	vecVelocity[0] = Cosine(DegToRad(vecAngle[1]));
	vecVelocity[1] = Sine(DegToRad(vecAngle[1]));
	vecVelocity[2] = Sine(DegToRad(vecAngle[0])) * -1.0;

	NormalizeVector(vecVelocity, vecVelocity);

	ScaleVector(vecVelocity, flSpeed);
}

stock bool IsEntityStuck(int iEntity)
{
	float vecMin[3];
	float vecMax[3];
	float vecOrigin[3];
	
	GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMin);
	GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMax);
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOrigin);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, Trace_DontHitEntity, iEntity);
	return (TR_DidHit());
}

public bool Trace_DontHitOtherEntities(int iEntity, int iMask, any iData)
{
	if (iEntity == iData)
		return true;
	
	if (iEntity > 0)
		return false;
	
	return true;
}

public bool Trace_DontHitEntity(int iEntity, int iMask, any iData)
{
	if (iEntity == iData)
		return false;
	
	return true;
}

stock bool IsClassname(int iEntity, const char[] sClassname)
{
	if (iEntity > MaxClients)
	{
		char sClassname2[256];
		GetEntityClassname(iEntity, sClassname2, sizeof(sClassname2));
		return (StrEqual(sClassname2, sClassname));
	}
	
	return false;
}

stock bool IsValidClient(int iClient)
{
	return 0 < iClient <= MaxClients && IsClientInGame(iClient) && !IsClientSourceTV(iClient) && !IsClientReplay(iClient);
}
