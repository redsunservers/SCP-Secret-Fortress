#pragma semicolon 1
#pragma newdecls required

static char Gameruler[64];

ArrayList Gamemode_ConfigSetupPre(KeyValues map)
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), FOLDER_CONFIGS ... "/gamemode.cfg");

	KeyValues kv = new KeyValues("Gamemode");
	kv.ImportFromFile(buffer);

	bool usingMap = (map && map.JumpToKey("Gamemode"));
	KeyValues choosen;


	/*
		Enabled Classes
	*/
	ArrayList classes;
	if(usingMap && map.JumpToKey("Classes"))
	{
		choosen = map;
	}
	else if(kv.JumpToKey("Classes"))
	{
		choosen = kv;
	}
	
	if(choosen)
	{
		if(choosen.GotoFirstSubKey(false))
		{
			classes = new ArrayList(ByteCountToCells(32));

			do
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				classes.PushString(buffer);
			}
			while(kv.GotoNextKey(false));

			choosen.GoBack();
		}

		choosen.GoBack();
	}

	
	/*
		Downloads
	*/
	if(usingMap && map.JumpToKey("Downloads"))
	{
		choosen = map;
	}
	else if(kv.JumpToKey("Downloads"))
	{
		choosen = kv;
	}
	
	if(choosen)
	{
		if(choosen.GotoFirstSubKey(false))
		{
			int table = FindStringTable("downloadables");
			bool save = LockStringTables(false);

			do
			{
				choosen.GetSectionName(buffer, sizeof(buffer));
				if(!FileExists(buffer, true))
				{
					LogError("[Config] Gamemode has missing file '%s' in 'Downloads'", buffer);
					continue;
				}

				AddToStringTable(table, buffer);
			}
			while(choosen.GotoNextKey(false));

			LockStringTables(save);
			choosen.GoBack();
		}

		choosen.GoBack();
	}


	if(usingMap)
		map.GoBack();

	delete kv;
	return classes;
}

/*
	Set up "gamefunc" and it's "Gamerules"
*/
void Gamemode_ConfigSetupPost(KeyValues map)
{
	KeyValues kv;
	
	// See if map has it's own game function and custom rules
	if(map && map.JumpToKey("Gamemode"))
	{
		if(map.JumpToKey("Gamerules"))
		{
			kv = map;
		}
		else
		{
			map.GoBack();
		}
	}

	if(!kv)
	{
		char buffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, buffer, sizeof(buffer), FOLDER_CONFIGS ... "/gamemode.cfg");

		kv = new KeyValues("Gamemode");
		kv.ImportFromFile(buffer);
		kv.JumpToKey("Gamerules");
	}

	kv.GetString("function", Gameruler, sizeof(Gameruler));

	if(Call_StartGameruler("OnConfigSetup"))
	{
		Call_PushCell(kv);
		Call_Finish();
	}

	if(kv == map)
	{
		map.GoBack();
	}
	else
	{
		delete kv;
	}
}

static bool Call_StartGameruler(const char[] suffix)
{
	if(!Gameruler[0])
		return false;
	
	char buffer[64];
	FormatEx(buffer, sizeof(buffer), "%s_%s", Gameruler, suffix);

	Function func = GetFunctionByName(null, buffer);
	if(func == INVALID_FUNCTION)
		return false;
	
	Call_StartFunction(null, func);
	return true;
}

void Gamemode_RoundRespawn()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			Client(client).ResetByRound();
	}

	if(Call_StartGameruler("OnRoundRespawn"))
		Call_Finish();
}

void Gamemode_RoundStart()
{
	if(Call_StartGameruler("RoundStart"))
		Call_Finish();
}

void Gamemode_RoundEnd()
{
	if(Call_StartGameruler("RoundEnd"))
		Call_Finish();
}

void Gamemode_MapEnd()
{
	if(Call_StartGameruler("OnMapEnd"))
		Call_Finish();
	
	Gameruler[0] = 0;
}