#pragma semicolon 1
#pragma newdecls required

static Handle EventTimer;

public void SecondMercs_Event()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == TFTeam_Humans && !IsPlayerAlive(client))
		{
			Client(client).KeycardContain = 1;

			DHook_RepsawnPlayer(client);
			ClientCommand(client, "playgamesound ui/system_message_alert.wav");
		}
	}
}

public void MTFSquad_Precache()
{
	PrecacheSound("scp_sf/events/mtf_spawn.mp3");
	PrecacheModel("models/scp_new/guards/counter_gign.mdl");
	PrecacheModel("models/scp_new/guards/gibs/head.mdl");
	PrecacheModel("models/scp_new/guards/gibs/leftarm.mdl");
	PrecacheModel("models/scp_new/guards/gibs/leftleg.mdl");
	PrecacheModel("models/scp_new/guards/gibs/pelvis.mdl");
	PrecacheModel("models/scp_new/guards/gibs/rightfoot.mdl");
	PrecacheModel("models/scp_new/guards/gibs/righthand.mdl");
	PrecacheModel("models/scp_new/guards/gibs/torso.mdl");
}

public void MTFSquad_Event()
{
	EventTimer = CreateTimer(8.0, MTFSquadTimer);
	TriggerRelay("scp_mtf_spawn_pre");
}

public void MTFSquad_End()
{
	delete EventTimer;
}

static Action MTFSquadTimer(Handle timer)
{
	EventTimer = null;
	TriggerRelay("scp_mtf_spawn");

	char classname[36];
	bool captain = true;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == TFTeam_Humans && !IsPlayerAlive(client))
		{
			Client(client).NoEscape = true;
			Client(client).Escaped = true;
			Client(client).ActionItem = Radio_Index();
			Client(client).KeycardContain = 1;
			Client(client).KeycardArmory = captain ? 3 : 2;
			Client(client).KeycardExit = captain ? 2 : 1;

			DHook_RepsawnPlayer(client);
			ClientCommand(client, "playgamesound ui/system_message_alert.wav");
			
			int entity = TF2U_GetPlayerLoadoutEntity(client, captain ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary);
			if(entity != -1)
			{
				GetEntityClassname(entity, classname, sizeof(classname));
				if(!StrContains(classname, "tf_weap", false))
				{
					TF2_RemoveWeaponSlot(client, entity);
				}
				else
				{
					TF2_RemoveWearable(client, entity);
				}
			}

			SetVariantString("models/scp_new/guards/counter_gign.mdl");
			AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

			captain = false;
		}
	}
	
	EmitSoundToAll("scp_sf/events/mtf_spawn.mp3");
	CPrintToChatAll("%t", "MTFSpawn");
	return Plugin_Continue;
}

