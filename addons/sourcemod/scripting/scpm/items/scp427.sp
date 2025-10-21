/*
	Necklace that heals, but spawns a mob after too long use
*/

#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/freak_fortress_2/wtf/heavy.dx80.vtx",
	"models/freak_fortress_2/wtf/heavy.dx90.vtx",
	"models/freak_fortress_2/wtf/heavy.mdl",
	"models/freak_fortress_2/wtf/heavy.phy",
	"models/freak_fortress_2/wtf/heavy.vvd",
	"sound/scpm/scp427/chase.mp3"
};

static const char PlayerModel[] = "models/freak_fortress_2/wtf/heavy.mdl";
static const char ChaseSound[] = "#scpm/scp427/chase.mp3";
static char OriginalModel[PLATFORM_MAX_PATH];
static int BossIndex = -1;
static bool Opened[MAXPLAYERS+1];
static float LastTime[MAXPLAYERS+1];

public void SCP427_Pickup(int client)
{
	Opened[client] = false;
	LastTime[client] = 0.0;
}

public bool SCP427_Use(int client)
{
	Opened[client] = !Opened[client];
	
	if(Opened[client])
	{
		PrintCenterText(client, "%T", "SCP427 Open", client);
	}
	else
	{
		PrintCenterText(client, "%T", "SCP427 Close", client);
	}
	
	return false;
}

public Action SCP427_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(Opened[client])
	{
		float gameTime = GetGameTime();
		if(gameTime < LastTime[client])
		{
			LastTime[client] = gameTime + 0.1;
			
			int health = GetClientHealth(client);
			SetEntityHealth(client, health + 1);
			Client(client).Stress += 0.2;

			float stress = Human_GetStressPercent(client);
			
			if(stress > 125.0 || (health > 519 && stress > 100.0))
			{
				float pos[3], ang[3];
				GetClientAbsOrigin(client, pos);
				GetClientAbsAngles(client, ang);
				GetClientModel(client, OriginalModel, sizeof(OriginalModel));

				ForcePlayerSuicide(client, true);
				Bosses_DisplayEntry(client, "SCP427 Entry");

				if(BossIndex != -1)
				{
					int humans;
					int[] human = new int[MaxClients];

					int bosses;
					int[] boss = new int[MaxClients];

					for(int target = 1; target <= MaxClients; target++)
					{
						if(client != target && IsClientInGame(target) && !IsPlayerAlive(target))
						{
							switch(GetClientTeam(target))
							{
								case TFTeam_Bosses:
									boss[bosses++] = target;
								
								case TFTeam_Humans:
									human[humans++] = target;
							}
						}
					}
					
					int choosen;

					if(bosses)
					{
						choosen = boss[GetURandomInt() % bosses];
					}
					else if(humans)
					{
						choosen = human[GetURandomInt() % humans];
					}

					if(choosen)
					{
						ChangeClientTeam(choosen, TFTeam_Bosses);
						Bosses_Create(choosen, BossIndex);
						ClientCommand(choosen, "playgamesound ui/system_message_alert.wav");
						TeleportEntity(choosen, pos, ang);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public bool SCP427A_Precache(int index, BossData data, bool &hidden)
{
	hidden = true;
	BossIndex = index;

	PrecacheModel(PlayerModel);
	PrecacheSound(ChaseSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
	return true;
}

public void SCP427A_Unload()
{
	BossIndex = -1;
}

public void SCP427A_Create(int client)
{
	Default_Create(client);
}

public TFClassType SCP427A_TFClass()
{
	return TFClass_Heavy;
}

public void SCP427A_Remove(int client)
{
	SetEntityRenderFx(client, RENDERFX_NONE);
	Default_Remove(client);
}

public void SCP427A_Spawn(int client)
{
}

public void SCP427A_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	if(weapons)
	{
		if(OriginalModel[0])
		{
			int entity = CreateEntityByName("tf_wearable");
			if(entity != -1)
			{
				SetEntProp(entity, Prop_Send, "m_nModelIndex", PrecacheModel(OriginalModel));
				SetEntProp(entity, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", TFTeam_Humans);
				SetEntProp(entity, Prop_Send, "m_nSkin", 0);
				SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4);
				SetEntityCollisionGroup(entity, COLLISION_GROUP_WEAPON);
				SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", true);
				DispatchSpawn(entity);
				SetVariantString("!activator");
				ActivateEntity(entity);
				TF2Util_EquipPlayerWearable(client, entity);

				SetEntityRenderFx(client, RENDERFX_FADE_FAST);
			}
		}

		int entity = Items_GiveCustom(client, 5, "tf_weapon_fists");
		if(entity != -1)
		{
			Attrib_Set(entity, "crit mod disabled", 0.0);
			Attrib_Set(entity, "max health additive penalty", -295.0);
			Attrib_Set(entity, "damage force reduction", 0.0);
			Attrib_Set(entity, "airblast vulnerability multiplier", 0.0);
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);
			Attrib_Set(entity, "voice pitch scale", 0.2);

			TF2U_SetPlayerActiveWeapon(client, entity);
			
			SetEntityHealth(client, 9999);
		}

		Human_ToggleFlashlight(client);
	}
}

public void SCP427A_PlayerKilled(int client, int victim, bool fakeDeath)
{
	if(!fakeDeath)
		Bosses_DisplayEntry(victim, "SCP427 Entry");
}

public float SCP427A_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite, float &volume)
{
	strcopy(theme, sizeof(theme), ChaseSound);
	return 26.8;
}