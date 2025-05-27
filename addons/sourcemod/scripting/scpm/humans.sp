#pragma semicolon 1
#pragma newdecls required

static const char ClassNames[TFClass_MAX][] =
{
	"Ghost",
	"Scout",
	"Sniper",
	"Soldier",
	"Demoman",
	"Medic",
	"Heavy",
	"Pyro",
	"Spy",
	"Engineer"
};

enum struct ClassStat
{
	float WalkSpeed;
	float SprintSpeed;
	float SprintRegen;
	float SprintDegen;
	float StressLimit;
	float Awareness;
	float StressAlone;
	float StressGroup;
	float StressDark;
	float StressDeath;
	float PowerDrain;

	void SetupKv(KeyValues kv)
	{
		this.WalkSpeed = kv.GetFloat("walkspeed", 200.0);
		this.SprintSpeed = kv.GetFloat("sprintspeed", 300.0);
		this.SprintRegen = kv.GetFloat("sprintregen", 5.0);
		this.SprintDegen = kv.GetFloat("sprintdrain", 10.0);
		this.StressLimit = kv.GetFloat("maxstress", 1000.0);
		this.Awareness = kv.GetFloat("awareness", 1.0);
		this.StressAlone = kv.GetFloat("stressalone", 1.0);
		this.StressGroup = kv.GetFloat("stressgroup", -1.0);
		this.StressDark = kv.GetFloat("stressdark", 0.0);
		this.StressDeath = kv.GetFloat("stressdeath", 30.0);
		this.PowerDrain = kv.GetFloat("powerdrain", 1.0);
	}
}

static bool ImpulseFlashlight[MAXPLAYERS+1];
static int FlashlightRef[MAXPLAYERS+1] = {-1, ...};
static ClassStat ClassStats[TFClass_MAX];
static Handle StatusHud;
static Handle ActionHud;

void Human_PluginStart()
{
	StatusHud = CreateHudSynchronizer();
	ActionHud = CreateHudSynchronizer();
}

void Human_SetupConfig(KeyValues map)
{
	KeyValues kv;

	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Humans"))
			kv = map;
	}

	char buffer[PLATFORM_MAX_PATH];
	if(!kv)
	{
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "humans");
		kv = new KeyValues("Humans");
		kv.ImportFromFile(buffer);
	}

	for(int i; i < TFClass_MAX; i++)
	{
		bool found = kv.JumpToKey(ClassNames[i]);
		
		ClassStats[i].SetupKv(kv);

		if(found)
			kv.GoBack();
	}

	if(kv != map)
		delete kv;
}

void Human_PutInServer(int client)
{
	if(IsFakeClient(client))
	{
		ImpulseFlashlight[client] = true;
	}
	else
	{
		QueryClientConVar(client, "mat_supportflashlight", FlashlightQuery);
	}
}

void Human_ClientDisconnect(int client)
{
	ImpulseFlashlight[client] = false;

	if(IsValidEntity(FlashlightRef[client]))
	{
		AcceptEntityInput(FlashlightRef[client], "TurnOff");
		RemoveEntity(FlashlightRef[client]);
		FlashlightRef[client] = -1;
	}
}

void Human_PlayerSpawn(int client)
{
	if(!Client(client).IsBoss && !Client(client).Minion && IsPlayerAlive(client))
	{
		int team = GetClientTeam(client);
		if(team > TFTeam_Spectator)
		{
			if(GameRules_GetProp("m_bInWaitingForPlayers", 1))
			{
				TF2_AddCondition(client, TFCond_HalloweenGhostMode);
			}
			else if(!Client(client).NoEscape)
			{
				GoToNamedSpawn(client, team == TFTeam_Humans ? "scp_spawn_d" : "scp_spawn_s");
			}
		}
	}
}

void Human_InventoryApplication(int client)
{
	Client(client).LightPower = 100.0;
	Attrib_Remove(client, "major move speed bonus");
	Attrib_Remove(client, "maxammo primary reduced");
	Attrib_Remove(client, "maxammo secondary reduced");

	int hud;
	if(!Client(client).IsBoss && !Client(client).Minion)
	{
		hud = HIDEHUD_HEALTH|HIDEHUD_TARGET_ID;
		if(!Client(client).Escaped)
			hud += HIDEHUD_BUILDING_STATUS|HIDEHUD_CLOAK_AND_FEIGN|HIDEHUD_PIPES_AND_CHARGE|HIDEHUD_METAL;
	}
	
	SetEntProp(client, Prop_Send, "m_iHideHUD", hud);

	EquipHuman(client, true);
	CreateTimer(0.1, HumanEquipTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

static Action HumanEquipTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
		EquipHuman(client, true);
	
	return Plugin_Continue;
}

void Human_ToggleFlashlight(int client)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return;
	
	Client(client).LastNoiseAt = GetGameTime();

	int effects = GetEntProp(client, Prop_Send, "m_fEffects");
	if(effects & EF_DIMLIGHT)
	{
		ClientCommand(client, "playgamesound items/flashlight1.wav");
		SetEntProp(client, Prop_Send, "m_fEffects", effects & ~EF_DIMLIGHT);
		
		if(IsValidEntity(FlashlightRef[client]))
		{
			AcceptEntityInput(FlashlightRef[client], "TurnOff");
			RemoveEntity(FlashlightRef[client]);
			FlashlightRef[client] = -1;
		}
	}
	else
	{
		ClientCommand(client, "playgamesound items/flashlight1.wav");
		SetEntProp(client, Prop_Send, "m_fEffects", effects | EF_DIMLIGHT);
		
		if(!ImpulseFlashlight[client] && !IsValidEntity(FlashlightRef[client]))
		{
			int entity = CreateEntityByName("light_dynamic");
			if(entity != -1)
			{
				float pos[3], ang[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, ang);
				TeleportEntity(entity, pos, ang, NULL_VECTOR);

				DispatchKeyValue(entity, "_light", "255 255 255");
				DispatchKeyValue(entity, "spotlight_radius", "512");
				DispatchKeyValue(entity, "distance", "1024");
				DispatchKeyValue(entity, "brightness", "0");
				DispatchKeyValue(entity, "_inner_cone", "41");
				DispatchKeyValue(entity, "_cone", "41");

				DispatchSpawn(entity);
				ActivateEntity(entity);
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);
				AcceptEntityInput(entity, "TurnOn");

				SDKHook(entity, SDKHook_SetTransmit, FlashlightTransmit);

				FlashlightRef[client] = EntIndexToEntRef(entity);
			}
		}
	}
}

// 100.0 being gone insane
float Human_GetStressPercent(int client)
{
	int class = view_as<int>(TF2_GetPlayerClass(client));
	return ((GetGameTime() - RoundStartTime) + Client(client).Stress) * 100.0 / ClassStats[class].StressLimit;
}

void Human_PlayerRunCmd(int client, int buttons, const float vel[3])
{
	if(!Client(client).IsBoss && !Client(client).Minion && IsPlayerAlive(client))
	{
		float gameTime = GetGameTime();
		float delta = gameTime - Client(client).LastGameTime;
		if(delta < 0.0)
			delta = 0.0;
		
		int class = view_as<int>(TF2_GetPlayerClass(client));
		int effects = GetEntProp(client, Prop_Send, "m_fEffects");

		// Close Eyes Button
		Client(client).EyesClosed = view_as<bool>(buttons & IN_SCORE);

		// Sprint Button
		if(((buttons & IN_ATTACK3) || (buttons & IN_SPEED)) && (vel[0] || vel[1] || vel[2]))
		{
			// MOVE TO ON SUCCESSFUL INTERACT
			//Client(client).HideControls = true;

			if(Client(client).Sprinting)
			{
				Client(client).SprintPower -= delta * ClassStats[class].SprintDegen;
				if(Client(client).SprintPower < 0.1)
				{
					Client(client).Sprinting = false;
					UpdateSpeed(client);
				}
			}
			else if(Client(client).SprintPower > (ClassStats[class].SprintDegen * 3.0))
			{
				Client(client).Sprinting = true;
				Client(client).SprintPower -= ClassStats[class].SprintDegen / 2.0;
				ClientCommand(client, "playgamesound player/suit_sprint.wav");
				UpdateSpeed(client);
			}
		}
		else if(Client(client).Sprinting)
		{
			Client(client).Sprinting = false;
			UpdateSpeed(client);
		}
		else if(Client(client).SprintPower < 100.0)
		{
			Client(client).SprintPower += delta * ClassStats[class].SprintRegen;
			if(Client(client).SprintPower > 100.0)
				Client(client).SprintPower = 100.0;
		}

		// Flashlight Logic
		if(effects & EF_DIMLIGHT)
		{
			Client(client).LightPower -= delta;
			if(Client(client).LightPower < 0.5)
			{
				ClientCommand(client, "playgamesound ambient/energy/spark6.wav");
				SetEntProp(client, Prop_Send, "m_fEffects", effects & ~EF_DIMLIGHT);
				
				if(IsValidEntity(FlashlightRef[client]))
				{
					AcceptEntityInput(FlashlightRef[client], "TurnOff");
					RemoveEntity(FlashlightRef[client]);
					FlashlightRef[client] = -1;
				}
			}
			else if(IsValidEntity(FlashlightRef[client]))
			{
				TeleportEntity(FlashlightRef[client], _, {0.0, 0.0, 0.0});
			}
		}
		else
		{
			if(ClassStats[class].StressDark)
				Client(client).Stress += ClassStats[class].StressDark * delta;

			if(Client(client).LightPower < 100.0)
			{
				Client(client).LightPower += delta;
				if(Client(client).LightPower > 100.0)
					Client(client).LightPower = 100.0;
			}
		}

		static char buffer[256];
		static float updateTime[MAXPLAYERS+1][3];
		if(FAbs(updateTime[client][0] - gameTime) > 0.2)
		{
			updateTime[client][0] = gameTime;

			if(GameRules_GetRoundState() != RoundState_RoundRunning)
				return;
			
			int stress = 999;
			int health = GetClientHealth(client);
			int maxhealth = SDKCall_GetMaxHealth(client);

			// Escapee Aura
			if(Client(client).Escaped)
				TF2_AddCondition(client, TFCond_TeleportedGlow);

			// Stress Meter
			if(ClassStats[class].StressLimit > 0.0)
			{
				stress = 100 - RoundToFloor(((gameTime - RoundStartTime) + Client(client).Stress) * 100.0 / ClassStats[class].StressLimit);
				if(Client(client).Escaped && stress < 0)
					stress = 0;
				
				if(stress < -9)
				{
					Format(buffer, sizeof(buffer), "%T", "You Will Die", client);
				}
				else
				{
					if(stress < 0)
						stress = 0;
					
					Format(buffer, sizeof(buffer), "♨ %d％", stress);
				}

				if(stress < 1)
					TF2_AddCondition(client, TFCond_MarkedForDeath);

				// Stress kills at -25
				if(stress < -20)
				{
					if(maxhealth > 0)
					{
						int low = maxhealth * (stress + 25) / 5;
						if(health > low)
						{
							SDKHooks_TakeDamage(client, client, client, 1.0, DMG_CLUB);
							Attrib_Set(client, "vision opt in flags", 1.0, 6.0);
						}
					}
					else
					{
						ForcePlayerSuicide(client);
					}
				}
			}
			else
			{
				strcopy(buffer, sizeof(buffer), " ");
			}
			
			// Flashlight Meter
			if(stress < -14)
			{
				Format(buffer, sizeof(buffer), "%s\n%T", buffer, "There Is No Hope", client);
			}
			else
			{
				Format(buffer, sizeof(buffer), "%s\nϟ  %d％", buffer, RoundToCeil(Client(client).LightPower));
			}
			
			// Sprint Meter
			if(stress < -19)
			{
				Format(buffer, sizeof(buffer), "%s\n%T", buffer, "Mental Breakdown", client);
				Client(client).SprintPower = 0.0;
			}
			else if(ClassStats[class].SprintDegen > 0.0)
			{
				Format(buffer, sizeof(buffer), "%s\n»  %d％", buffer, RoundToCeil(Client(client).SprintPower));
			}
			
			// Close Eyes Logic
			if(Client(client).EyesClosed)
			{
				ScreenFade(client, 300, 150, FFADE_IN, 0, 0, 0, 255);
			}
			else
			{
				int red = (health * 255 / maxhealth);
				if(red > 255)
					red = 255;
				
				int green = 255;
				if(health > 259)
				{
					green = 128;
					if(health > 519)
						green = 32;
				}

				SetHudTextParams(0.07, 0.83, 0.3, red > 254 ? green : 255, 255, red > 254 ? green : red, 255);
				ShowSyncHudText(client, StatusHud, buffer);
			}
		}
		else if(FAbs(updateTime[client][1] - gameTime) > 0.2)
		{
			updateTime[client][1] = gameTime;

			if(GameRules_GetRoundState() != RoundState_RoundRunning)
				return;
			
			// Not while in scoreboard
			if(Client(client).EyesClosed)
				return;
			
			SetGlobalTransTarget(client);

			// Action Item
			if(Client(client).ActionItem == -1)
			{
				Format(buffer, sizeof(buffer), "%t", "Action Item", "NaN");
			}
			else
			{
				Items_GetItemName(Client(client).ActionItem, buffer, sizeof(buffer));
				Format(buffer, sizeof(buffer), "%t", "Action Item", buffer);
			}
			
			// Keycard Level
			Format(buffer, sizeof(buffer), "%s\n%t", buffer, "Keycard Status", Client(client).KeycardContain, Client(client).KeycardArmory, Client(client).KeycardExit);

			SetHudTextParams(0.7, 0.79, 0.3, 255, 255, 255, 255);
			ShowSyncHudText(client, ActionHud, buffer);
		}
		else if(Client(client).ControlProgress < 2 && FAbs(updateTime[client][2] - gameTime) > 0.5)
		{
			updateTime[client][2] = gameTime;

			if(GameRules_GetRoundState() != RoundState_RoundRunning)
				return;
			
			if(Client(client).ControlProgress)
			{
				if(Client(client).ActionItem != -1)
				{
					Format(buffer, sizeof(buffer), "%T", "Control Progress 2", client);
					PrintKeyHintText(client, buffer);
				}
			}
			else
			{
				Format(buffer, sizeof(buffer), "%T", "Control Progress 1", client);
				PrintKeyHintText(client, buffer);
			}
		}
	}
}

void Human_PlayerDeath(int client)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return;

	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);

	int i, entity;
	while(TF2_GetItem(client, entity, i))
	{
		Items_DropByEntity(client, entity, pos, ang, true);
	}

	Items_DropActionItem(client, true);
	Keycard_DropBestMatch(client, true);

	for(int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && Client(target).LookingAt(client))
		{
			Client(target).Stress += ClassStats[TF2_GetPlayerClass(target)].StressDeath;
		}
	}
}

void Human_ConditionAdded(int client, TFCond cond)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return;

	switch(cond)
	{
		case TFCond_TeleportedGlow:
		{
			if(!Client(client).Escaped && !Client(client).NoEscape)
			{
				Client(client).EscapeTimeAt = GetGameTime();
				Client(client).Escaped = true;
				TF2_RegeneratePlayer(client);
				Gamemode_CheckAlivePlayers();
			}
		}
	}
}
/*
void Human_ConditionRemoved(int client, TFCond cond)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return;

}
*/
void Human_Interact(int client, int entity)
{
	if(entity == -1)
		return;
	
	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "tf_dropped_weapon"))
	{
		Items_GiveByEntity(client, entity);
		AcceptEntityInput(entity, "Kill");

		if(!Client(client).ControlProgress)
			Client(client).ControlProgress = 1;
	}
	else if(!StrContains(buffer, "prop_dynamic") || !StrContains(buffer, "prop_physics"))
	{
		GetEntPropString(entity, Prop_Data, "m_iGlobalname", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_item_", false))
		{
			AcceptEntityInput(entity, "FireUser1", client, client);

			Items_GiveByIndex(client, StringToInt(buffer[9]));

			AcceptEntityInput(entity, "FireUser2", client, client);
			AcceptEntityInput(entity, "KillHierarchy");
			
			if(!Client(client).ControlProgress)
				Client(client).ControlProgress = 1;
		}
	}
}

float Humans_GetAwareness(int client)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return 1.0;
	
	return ClassStats[TF2_GetPlayerClass(client)].Awareness;
}

float Humans_GetStressGain(int client, bool alone)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return 0.0;
	
	return alone ? ClassStats[TF2_GetPlayerClass(client)].StressAlone : ClassStats[TF2_GetPlayerClass(client)].StressGroup;
}

static void EquipHuman(int client, bool post)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return;

	if(!Client(client).Escaped)
	{
		Attrib_Set(client, "maxammo primary reduced", 0.5);
		Attrib_Set(client, "maxammo secondary reduced", 0.5);

		int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

		int i, entity;
		while(TF2_GetItem(client, entity, i))
		{
			if(entity != melee)
				TF2_RemoveItem(client, entity);
		}

		if(melee != -1 && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != melee)
			TF2U_SetPlayerActiveWeapon(client, melee);
		
		i = 0;
		while(TF2U_GetWearable(client, entity, i))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 57, 131, 133, 231, 405, 406, 444, 608, 642, 1099, 1144:
				{
					// Wearable weapons
					TF2_RemoveWearable(client, entity);
				}
			}
		}

		if(post && melee != -1)	// BUG: Ran twice on round start
		{
			char buffer[32];
			FormatEx(buffer, sizeof(buffer), "%s Entry", ClassNames[TF2_GetPlayerClass(client)]);
			CPrintToChat(client, "%t", buffer);
			Weapons_ShowChanges(client, melee);
		}
	}

	UpdateSpeed(client);
}

static void UpdateSpeed(int client)
{
	float defaul = 300.0;
	switch(TF2_GetPlayerClass(client))
	{
		case TFClass_Scout:
			defaul = 400.0;
		
		case TFClass_Soldier:
			defaul = 240.0;
		
		case TFClass_DemoMan:
			defaul = 280.0;
		
		case TFClass_Heavy:
			defaul = 230.0;
		
		case TFClass_Medic, TFClass_Spy:
			defaul = 320.0;
	}

	float speed;
	if(Client(client).Sprinting)
	{
		speed = ClassStats[TF2_GetPlayerClass(client)].SprintSpeed;
	}
	else
	{
		speed = ClassStats[TF2_GetPlayerClass(client)].WalkSpeed;
	}
	
	Attrib_Set(client, "major move speed bonus", speed / defaul);
	SDKCall_SetSpeed(client);
}

static void FlashlightQuery(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if(result == ConVarQuery_Okay)
		ImpulseFlashlight[client] = view_as<bool>(StringToInt(cvarValue));
}

static Action FlashlightTransmit(int entity, int client)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hMoveParent") == client ? Plugin_Continue : Plugin_Handled;
}
