#pragma semicolon 1
#pragma newdecls required

enum struct BossData
{
	char Prefix[32];
	Handle Subplugin;

	bool SetupKv(KeyValues kv, int index)
	{
		kv.GetSectionName(this.Prefix, sizeof(this.Prefix));
		this.Subplugin = INVALID_HANDLE;

		if(!TranslationPhraseExists(this.Prefix))
		{
			LogError("[Config] Boss '%s' has no translations", this.Prefix);
			return false;
		}

		if(!StartBossFunction(this.Subplugin, this.Prefix, "Precache"))
		{
			LogError("[Config] Boss '%s' does not have precache function", this.Prefix);
			return false;
		}

		Call_PushCell(index);
		Call_PushArrayEx(this, sizeof(BossData), SM_PARAM_COPYBACK);
		Call_Finish();
		return true;
	}
}

static ArrayList BossList;

void Bosses_PluginStart()
{
	RegAdminCmd("scp_makeboss", Bosses_MakeBossCmd, ADMFLAG_CHEATS, "Force a specific boss on a player");
}

static Action Bosses_MakeBossCmd(int client, int args)
{
	if(args && args < 3)
	{
		char buffer[64];
		int special = -1;
		if(args > 1)
		{
			GetCmdArg(2, buffer, sizeof(buffer));
			if(buffer[0] == '#')
			{
				special = StringToInt(buffer[1]);
			}
			else
			{
				special = Bosses_GetByName(buffer, false, client);
			}
		}
		else
		{
			special = GetURandomInt() % BossList.Length;
		}
		
		int team = -1;
		if(args > 2)
		{
			GetCmdArg(3, buffer, sizeof(buffer));
			team = StringToInt(buffer);
			if(team < -1 || team > 3)
				team = -1;
		}
		
		GetCmdArg(1, buffer, sizeof(buffer));
		
		bool lang;
		int matches;
		int[] target = new int[MaxClients];
		if((matches = ProcessTargetString(buffer, client, target, MaxClients, 0, buffer, sizeof(buffer), lang)) > 0)
		{
			for(int i; i < matches; i++)
			{
				if(!IsClientSourceTV(target[i]) && !IsClientReplay(target[i]))
				{
					if(args == 1)
					{
						if(Client(target[i]).IsBoss)
						{
							Bosses_Remove(target[i]);
							LogAction(client, target[i], "\"%L\" removed \"%L\" being a boss", client, target[i]);
							continue;
						}
					}
					
					Bosses_Create(target[i], special);
					LogAction(client, target[i], "\"%L\" made \"%L\" a boss", client, target[i]);
				}
			}
			
			if(lang)
			{
				ShowActivity(client, "%t", "Created Boss On", buffer);
			}
			else
			{
				ShowActivity(client, "%t", "Created Boss On", "_s", buffer);
			}
		}
		else
		{
			ReplyToTargetError(client, matches);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: scp_makeboss <client> [boss name / #index]");
	}
	return Plugin_Handled;
}

void Bosses_SetupConfig(KeyValues map)
{
	delete BossList;
	BossList = new ArrayList(sizeof(BossData));

	KeyValues kv;

	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Bosses"))
			kv = map;
	}

	char buffer[PLATFORM_MAX_PATH];
	if(!kv)
	{
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "bosses");
		kv = new KeyValues("Bosses");
		kv.ImportFromFile(buffer);
	}

	int slots = kv.GetNum("maxloaded", 99);
	
	BossData data;
	if(kv.JumpToKey("Enabled"))
	{
		int count = 1;
		if(kv.GotoFirstSubKey(false))
		{
			do
			{
				count++;
			}
			while(kv.GotoNextKey(false));

			kv.GoBack();
		}

		PrintToServer("[SCP] Picking %d bosses out of %d", slots, count);

		if(kv.GotoFirstSubKey(false))
		{
			int index;

			do
			{
				count--;
				if(count > slots)
				{
					// Loops through and picks bosses to disable depending on our limit
					if((GetURandomInt() % count) >= slots)
						continue;
				}
				
				if(data.SetupKv(kv, index))
				{
					slots--;
					index = BossList.PushArray(data) + 1;
				}
			}
			while(kv.GotoNextKey(false));

			kv.GoBack();
		}

		kv.GoBack();
	}
	
	if(map != kv)
		delete kv;
}

// Calls a boss function is the client is a boss
// @error Invalid client
stock bool Bosses_StartFunctionClient(int client, const char[] name)
{
	if(Client(client).Boss == -1)
		return false;
	
	return Bosses_StartFunction(Client(client).Boss, name);
}

// Calls a boss function given the index
// @error Invalid index
stock bool Bosses_StartFunction(int index, const char[] name)
{
	BossData data;
	BossList.GetArray(index, data);
	return StartBossFunction(data.Subplugin, data.Prefix, name);
}

static bool StartBossFunction(Handle plugin, const char[] prefix, const char[] name)
{
	static char buffer[64];
	Format(buffer, sizeof(buffer), "%s_%s", prefix, name);
	Function func = GetFunctionByName(plugin, buffer);
	if(func == INVALID_FUNCTION)
		return false;
	
	Call_StartFunction(plugin, func);
	return true;
}

// Gets the boss index based on name, returns -1 if none found
int Bosses_GetByName(const char[] name, bool exact = false, int client = 0)
{
	int similarBoss = -1;
	if(BossList)
	{
		int length = BossList.Length;
		int size1 = exact ? 0 : strlen(name);
		int similarChars;
		BossData data;
		char buffer[64];

		SetGlobalTransTarget(client);

		for(int i; i < length; i++)
		{
			BossList.GetArray(i, data);
			FormatEx(buffer, sizeof(buffer), "%t", data.Prefix);
			
			if(StrEqual(name, buffer, false))
				return i;
			
			if(size1)
			{
				int bump = StrContains(buffer, name, false);
				if(bump == -1)
					bump = 0;
				
				int size2 = strlen(buffer) - bump;
				if(size2 > size1)
					size2 = size1;
				
				int amount;
				for(int c; c < size2; c++)
				{
					if(CharToLower(name[c]) == CharToLower(buffer[c + bump]))
						amount++;
				}
				
				if(amount > similarChars)
				{
					similarChars = amount;
					similarBoss = i;
				}
			}
		}
	}
	return similarBoss;
}

// Sets a player as a boss given an index
void Bosses_Create(int client, int index)
{
	if(Client(client).IsBoss)
		Bosses_Remove(client);
	
	SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
	SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
	SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", 0);

	Client(client).Boss = index;

	if(Bosses_StartFunctionClient(client, "Create"))
	{
		Call_PushCell(client);
		Call_Finish();
	}

	if(IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
		Bosses_PlayerSpawn(client);
	}
}

// Removes a player as a boss
void Bosses_Remove(int client, bool regen = true)
{
	if(Client(client).IsBoss)
	{
		SetEntProp(client, Prop_Send, "m_bForcedSkin", false);
		SetEntProp(client, Prop_Send, "m_nForcedSkin", 0);
		SetEntProp(client, Prop_Send, "m_iPlayerSkinOverride", 0);

		if(Bosses_StartFunctionClient(client, "Remove"))
		{
			Call_PushCell(client);
			Call_Finish();
		}

		Client(client).Boss = -1;
		
		SetVariantString(NULL_STRING);
		AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

		Attrib_Remove(client, "healing received penalty");
		
		TF2_RemoveAllItems(client);

		if(regen && IsPlayerAlive(client))
		{
			SetEntityHealth(client, 1);
			TF2_RegeneratePlayer(client);
		}
	}
}

void Bosses_ClientDisconnect(int client)
{
	if(Client(client).IsBoss)
	{
		if(Bosses_StartFunctionClient(client, "Remove"))
		{
			Call_PushCell(client);
			Call_Finish();
		}
	}
}

void Bosses_PlayerSpawn(int client)
{
	if(Bosses_StartFunctionClient(client, "Spawn"))
	{
		Call_PushCell(client);
		Call_Finish();
	}
}

void Bosses_Equip(int client)
{
	EquipBoss(client, false);
	CreateTimer(0.1, Bosses_EquipTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

static Action Bosses_EquipTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client)
		EquipBoss(client, true);
	
	return Plugin_Continue;
}

static void EquipBoss(int client, bool weapons)
{
	if(Bosses_StartFunctionClient(client, "Equip"))
	{
		Call_PushCell(client);
		Call_PushCell(weapons);
		Call_Finish();
	}
}

Action Bosses_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	Action action;
	if(Bosses_StartFunctionClient(client, "PlayerRunCmd"))
	{
		Call_PushCell(client);
		Call_PushCellRef(buttons);
		Call_PushCellRef(impulse);
		Call_PushArrayEx(vel, sizeof(vel), SM_PARAM_COPYBACK);
		Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
		Call_PushCellRef(weapon);
		Call_PushCellRef(subtype);
		Call_PushCellRef(cmdnum);
		Call_PushCellRef(tickcount);
		Call_PushCellRef(seed);
		Call_PushArrayEx(mouse, sizeof(mouse), SM_PARAM_COPYBACK);
		Call_Finish(action);
	}
	
	return action;
}