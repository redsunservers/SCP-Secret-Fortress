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

public void MTFSpawn_Precache()
{
	PrecacheSound("scpm/misc/spawn_mtf.mp3");
	PrecacheModel("models/scp_new/guards/counter_gign.mdl");
	PrecacheModel("models/scp_new/guards/gibs/head.mdl");
	PrecacheModel("models/scp_new/guards/gibs/leftarm.mdl");
	PrecacheModel("models/scp_new/guards/gibs/leftleg.mdl");
	PrecacheModel("models/scp_new/guards/gibs/pelvis.mdl");
	PrecacheModel("models/scp_new/guards/gibs/rightfoot.mdl");
	PrecacheModel("models/scp_new/guards/gibs/righthand.mdl");
	PrecacheModel("models/scp_new/guards/gibs/torso.mdl");

	AddFileToDownloadsTable("sound/scpm/misc/spawn_mtf.mp3");
}

public void MTFSpawn_Event()
{
	EventTimer = CreateTimer(8.0, MTFSpawnTimer);
	TriggerRelay("scp_mtf_spawn_pre");
}

public void MTFSpawn_End()
{
	delete EventTimer;
}

static Action MTFSpawnTimer(Handle timer)
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

			int i;
			while(TF2_GetItem(client, entity, i))
			{
				if(HasEntProp(entity, Prop_Send, "m_iPrimaryAmmoType"))
				{
					int type = GetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType");
					if(type > 0)
					{
						//SetEntProp(client, Prop_Data, "m_iAmmo", 0, _, type);
						//GivePlayerAmmo(client, 100, type, true);
						SetEntProp(client, Prop_Data, "m_iAmmo", GetEntProp(client, Prop_Data, "m_iAmmo", _, type) / 5, _, type);
					}
				}
			}
			
			i = 0;
			while(TF2U_GetWearable(client, entity, i))
			{
				switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 57, 131, 133, 231, 405, 406, 444, 608, 642, 1099, 1144:
					{
						// Wearable weapons
					}
					default:
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}

			SetVariantString("models/scp_new/guards/counter_gign.mdl");
			AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

			captain = false;
		}
	}
	
	EmitSoundToAll("scpm/misc/spawn_mtf.mp3");
	EmitSoundToAll("scpm/misc/spawn_mtf.mp3");
	CPrintToChatAll("%t", "MTFSpawn");
	return Plugin_Continue;
}

