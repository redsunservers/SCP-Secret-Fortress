#pragma semicolon 1
#pragma newdecls required

enum struct ClassEnum
{
	char Name[32];
	char Display[32];
	char Model[PLATFORM_MAX_PATH];
	char Spawn[32];

	bool Regen;
	bool DeadClass;
	
	int Health;
	int MusicType;

	float Speed;
	float SpeakAllyDist;
	float SpeakOtherDist;

	TFClassType Class;

	int StartAmmo[Ammo_MAX];
	int MaxAmmo[Ammo_MAX];
	int StartItems[10];
	int MaxItems[Type_MAX];

	Function FuncCanTalkTo;		// void(int client, int target, float &distance)
	Function FuncCommand;		// bool(int client, const char[] command)
	Function FuncMusic;			// void(int client, char filepath[PLATFORM_MAX_PATH], int &duration)
	Function FuncPlayerRunCmd;	// Action(int client, int &buttons)
	Function FuncPrecache;		// void(int index, ClassEnum class)
	Function FuncSetClass;		// void(int client)
	Function FuncTransmitSee;	// bool(int client, int target)
	Function FuncTransmitSelf;	// bool(int client, int target)
	Function FuncUpdateSpeed;	// void(int client, float &speed)

	int SetupEnum(KeyValues kv, ArrayList whitelist, const ClassEnum defaul)
	{
		kv.GetSectionName(this.Name, sizeof(this.Name));

		int pos = whitelist ? 0 : whitelist.FindString(this.Name);
		if(pos == -1)
			return -1;
		
		Format(this.Display, sizeof(this.Display), "class_%s", this.Name);
		if(!TranslationPhraseExists(this.Display))
			strcopy(this.Display, sizeof(this.Display), "class_0");

		this.Regen = view_as<bool>(kv.GetNum("regen", defaul.Regen));
		this.DeadClass = view_as<bool>(kv.GetNum("deadclass", defaul.DeadClass));
		this.Health = kv.GetNum("health", defaul.Health);
		this.MusicType = kv.GetNum("musicindex", defaul.MusicType);
		this.Speed = kv.GetFloat("speed", defaul.Speed);
		this.SpeakAllyDist = kv.GetFloat("speakallydist", defaul.SpeakAllyDist);
		this.SpeakOtherDist = kv.GetFloat("speakotherdist", defaul.SpeakOtherDist);
		this.Class = KvGetClass(kv, "class", defaul.Class);

		if(kv.JumpToKey("StartAmmo"))
		{
			for(int i; i < sizeof(this.StartAmmo); i++)
			{
				IntToString(i, this.Spawn, sizeof(this.Spawn));
				this.StartAmmo[i] = kv.GetNum(this.Spawn, -1);
			}

			kv.GoBack();
		}
		else
		{
			this.StartAmmo = defaul.StartAmmo;
		}

		if(kv.JumpToKey("MaxAmmo"))
		{
			for(int i; i < sizeof(this.MaxAmmo); i++)
			{
				IntToString(i, this.Spawn, sizeof(this.Spawn));
				this.MaxAmmo[i] = kv.GetNum(this.Spawn, -1);
			}

			kv.GoBack();
		}
		else
		{
			this.MaxAmmo = defaul.MaxAmmo;
		}

		if(kv.JumpToKey("StartItems"))
		{
			for(int i; i < sizeof(this.StartItems); i++)
			{
				IntToString(i, this.Spawn, sizeof(this.Spawn));
				this.StartItems[i] = kv.GetNum(this.Spawn);
			}

			kv.GoBack();
		}
		else
		{
			this.StartItems = defaul.StartItems;
		}

		if(kv.JumpToKey("MaxItems"))
		{
			for(int i; i < sizeof(this.MaxItems); i++)
			{
				IntToString(i, this.Spawn, sizeof(this.Spawn));
				this.MaxItems[i] = kv.GetNum(this.Spawn);
			}

			kv.GoBack();
		}
		else
		{
			this.MaxItems = defaul.MaxItems;
		}

		if(kv.JumpToKey("Precache"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(this.Model, sizeof(this.Model));
					if(this.Model[0])
					{
						kv.GetString(NULL_STRING, this.Spawn, sizeof(this.Spawn));

						if(this.Spawn[0] == 'm')	// mdl, model, mat, material
						{
							PrecacheModel(this.Model);
						}
						else if(this.Spawn[0] == 'g' || this.Spawn[2] == 'r')	// gs, gamesound, script
						{
							PrecacheScriptSound(this.Model);
						}
						else if(this.Spawn[0] == 's')
						{
							if(this.Spawn[1] == 'e')	// sentence
							{
								PrecacheSentenceFile(this.Model);
							}
							else	// snd, sound
							{
								PrecacheSound(this.Model);
							}
						}
						else if(this.Spawn[0] == 'd')	// decal
						{
							PrecacheDecal(this.Model);
						}
						else if(this.Spawn[0])	// generic
						{
							PrecacheGeneric(this.Model);
						}
					}
				}
				while(kv.GotoNextKey(false));

				kv.GoBack();
			}

			kv.GoBack();
		}

		if(kv.JumpToKey("Downloads"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				int table = FindStringTable("downloadables");
				bool save = LockStringTables(false);

				do
				{
					kv.GetSectionName(this.Model, sizeof(this.Model));
					if(!FileExists(this.Model, true))
					{
						LogError("[Config] '%s' has missing file '%s' in 'Downloads'", this.Name, this.Model);
						continue;
					}

					AddToStringTable(table, this.Model);
				}
				while(kv.GotoNextKey(false));

				LockStringTables(save);
				kv.GoBack();
			}

			kv.GoBack();
		}

		kv.GetString("model", this.Model, sizeof(this.Model), defaul.Model);
		if(this.Model[0])
			PrecacheModel(this.Model);
		
		kv.GetString("spawn", this.Spawn, sizeof(this.Spawn), defaul.Spawn);

		this.FuncCanTalkTo = KvGetFunction(kv, "func_cantalkto", defaul.FuncCanTalkTo);
		this.FuncCommand = KvGetFunction(kv, "func_clientcommand", defaul.FuncCommand);
		this.FuncMusic = KvGetFunction(kv, "func_music", defaul.FuncMusic);
		this.FuncPlayerRunCmd = KvGetFunction(kv, "func_playerruncmd", defaul.FuncPlayerRunCmd);
		this.FuncPrecache = KvGetFunction(kv, "func_precache", defaul.FuncPrecache);
		this.FuncSetClass = KvGetFunction(kv, "func_setclass", defaul.FuncSetClass);
		this.FuncTransmitSee = KvGetFunction(kv, "func_transmitsee", defaul.FuncTransmitSee);
		this.FuncTransmitSelf = KvGetFunction(kv, "func_transmitself", defaul.FuncTransmitSelf);
		this.FuncUpdateSpeed = KvGetFunction(kv, "func_updatespeed", defaul.FuncUpdateSpeed);
		return pos;
	}

	void SetDefaultValues()
	{
		this.FuncCanTalkTo = INVALID_FUNCTION;
		this.FuncCommand = INVALID_FUNCTION;
		this.FuncMusic = INVALID_FUNCTION;
		this.FuncPlayerRunCmd = INVALID_FUNCTION;
		this.FuncPrecache = INVALID_FUNCTION;
		this.FuncSetClass = INVALID_FUNCTION;
		this.FuncTransmitSee = INVALID_FUNCTION;
		this.FuncTransmitSelf = INVALID_FUNCTION;
		this.FuncUpdateSpeed = INVALID_FUNCTION;
	}

	Function GetFuncOf(int pos)
	{
		return GetItemInArray(this, pos);
	}
}

static ArrayList ClassList;

void Classes_PluginStart()
{
	RegAdminCmd("scp_setclass", SetClassCommand, ADMFLAG_SLAY, "Sets a player's class");
}

static Action SetClassCommand(int client, int args)
{
	SetGlobalTransTarget(client);

	if(!args)
	{
		ClassEnum class;
		for(int i; Classes_GetByIndex(i, class); i++)
		{
			ReplyToCommand(client, "%t | @%s", class.Display, class.Name);
		}

		if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
			ReplyToCommand(client, "[SM] %t", "See console for output");

		return Plugin_Handled;
	}

	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: scp_setclass [target] [class]");
		return Plugin_Handled;
	}

	char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(2, pattern, sizeof(pattern));

	char targetName[MAX_TARGET_LENGTH];

	SetGlobalTransTarget(client);

	int index;
	bool found;
	ClassEnum class;
	while(Classes_GetByIndex(index, class))
	{
		FormatEx(targetName, sizeof(targetName), "%t", class.Display);
		if(StrContains(targetName, pattern, false) != -1)
		{
			found = true;
			break;
		}

		index++;
	}

	if(!found)
	{
		index = 0;
		while(Classes_GetByIndex(index, class))
		{
			if(StrContains(class.Name, pattern, false) != -1)
			{
				found = true;
				break;
			}

			index++;
		}

		if(!found)
		{
			ReplyToCommand(client, "[SM] Invalid class string");
			return Plugin_Handled;
		}
	}

	int targets[MAXPLAYERS+1], matches;
	bool targetNounIsMultiLanguage;

	GetCmdArg(1, pattern, sizeof(pattern));
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	for(int i; i < matches; i++)
	{
		Classes_SetClientClass(targets[i], index, ClassSpawn_Other);
	}

	if(targetNounIsMultiLanguage)
	{
		CShowActivity2(client, PREFIX, "Forced class %t to %t", class.Display, targetName);
	}
	else
	{
		CShowActivity2(client, PREFIX, "Forced class %t to %s", class.Display, targetName);
	}

	return Plugin_Handled;
}

void Classes_ConfigSetup(KeyValues map, ArrayList whitelist)
{
	delete ClassList;
	ClassList = new ArrayList(sizeof(ClassEnum));

	ClassEnum defaul, class;
	BuildPath(Path_SM, class.Model, sizeof(class.Model), FOLDER_CONFIGS ... "/classes.cfg");

	KeyValues kv = new KeyValues("Classes");
	kv.ImportFromFile(class.Model);

	defaul.SetDefaultValues();
	
	if(kv.JumpToKey("default"))
	{
		defaul.SetupEnum(kv, null, defaul);
		kv.Rewind();
	}

	kv.GotoFirstSubKey();

	if(map && map.JumpToKey("Classes"))
	{
		if(map.GotoFirstSubKey())
		{
			do
			{
				int pos = class.SetupEnum(kv, whitelist, defaul);
				if(pos != -1)
				{
					ClassList.PushArray(class);

					if(whitelist)	// Remove from whitelist to override default cfg
						whitelist.Erase(pos);
				}
			}
			while(map.GotoNextKey());

			map.GoBack();
		}

		map.GoBack();
	}

	do
	{
		if(class.SetupEnum(kv, whitelist, defaul) != -1)
			ClassList.PushArray(class);
	}
	while(kv.GotoNextKey());

	int length = ClassList.Length;
	for(int i; i < length; i++)
	{
		ClassList.GetArray(i, class);
		if(class.FuncPrecache != INVALID_FUNCTION)
		{
			Call_StartFunction(null, class.FuncPrecache);
			Call_PushCell(i);
			Call_PushArrayEx(class, sizeof(class), SM_PARAM_COPYBACK);
			Call_Finish();

			ClassList.SetArray(i, class);
		}
	}

	delete kv;
}

static bool Call_StartClassFunc(int index, int pos)
{
	static ClassEnum class;
	if(!Classes_GetByIndex(index, class) || class.GetFuncOf(pos) == INVALID_FUNCTION)
		return false;
	
	Call_StartFunction(null, class.FuncSetClass);
	return true;
}

bool Classes_GetByIndex(int index, ClassEnum class)
{
	if(index < 0 || index >= ClassList.Length)
		return false;

	ClassList.GetArray(index, class);
	return true;
}

int Classes_GetByName(const char[] name, ClassEnum class = {})
{
	int length = ClassList.Length;
	for(int i; i < length; i++)
	{
		ClassList.GetArray(i, class);
		if(StrEqual(name, class.Name, false))
			return i;
	}

	return -1;
}

Action Classes_SetClientClass(int client, int index, ClassSpawnEnum context)
{
	ClassEnum class;
	Classes_GetByIndex(index, class);

	Action action = Forwards_OnClassPre(client, context, class.Name, sizeof(class.Name));
	switch(action)
	{
		case Plugin_Changed:
		{
			Client(client).Class = Classes_GetByName(class.Name, class);
		}
		case Plugin_Handled, Plugin_Stop:
		{
			return action;
		}
		default:
		{
			Client(client).Class = index;
		}
	}

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncSetClass))
	{
		Call_PushCell(client);
		Call_Finish();
	}

	switch(context)
	{
		case ClassSpawn_Other:
		{
			TF2_RegeneratePlayer(client);
		}
		case ClassSpawn_WaveSystem, ClassSpawn_Escape, ClassSpawn_Revive:
		{
			TF2_RespawnPlayer(client);
		}
	}

	Forwards_OnClassPost(client, context, class.Name);
	
	return action;
}

void Classes_UpdateSpeed(int client)
{
	float multi = 1.0;

	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class))
	{
		float speed = class.Speed;

		if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncUpdateSpeed))
		{
			Call_PushCell(client);
			Call_PushFloatRef(speed);
			Call_Finish();
		}

		if(speed > 0.0)
		{
			// Apply correct multipler per class
			switch(TF2_GetPlayerClass(client))
			{
				case TFClass_Scout:
					multi = speed / 400.0;
				
				case TFClass_Soldier:
					multi = speed / 240.0;
				
				case TFClass_DemoMan:
					multi = speed / 280.0;
				
				case TFClass_Heavy:
					multi = speed / 230.0;
				
				case TFClass_Medic, TFClass_Spy:
					multi = speed / 320.0;
				
				default:
					multi = speed / 300.0;
			}
		}
	}

	TF2Attrib_SetByName(client, "move speed bonus", multi);
	SDKCalls_SetSpeed(client);
}

int Classes_GetMaxAmmo(int client, int type)
{
	if(type >= 0 && type < Ammo_MAX)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client(client).Class, class))
			return class.MaxAmmo[type];
	}
	return -1;
}

bool Classes_IsDeadClass(int client)
{
	ClassEnum class;
	Classes_GetByIndex(Client(client).Class, class);
	return class.DeadClass;
}

void Classes_CanTalkTo(int client, int target, float &range, float &defaultRange)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class))
	{
		defaultRange = GetClientTeam(client) == GetClientTeam(target) ? class.SpeakAllyDist : class.SpeakOtherDist;
		range = defaultRange;

		if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncCanTalkTo))
		{
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushFloatRef(range);
			Call_Finish();
		}
	}
}

Action Classes_PlayerRunCmd(int client, int &button)
{
	Action action = Plugin_Continue;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncPlayerRunCmd))
	{
		Call_PushCell(client);
		Call_PushCellRef(button);
		Call_Finish(action);
	}

	return action;
}

bool Classes_ClientCommand(int client, const char[] command)
{
	bool block;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncCommand))
	{
		Call_PushCell(client);
		Call_PushString(command);
		Call_Finish(block);
	}

	return block;
}

void Classes_PlayMusic(int client, char filepath[PLATFORM_MAX_PATH], int &length)
{
	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncMusic))
	{
		Call_PushCell(client);
		Call_PushStringEx(filepath, sizeof(filepath), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(length);
		Call_Finish();
	}
}

bool Classes_Transmit(int client, int target)
{
	bool blocked;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncTransmitSee))
	{
		Call_PushCell(client);
		Call_PushCell(target);
		Call_Finish(blocked);
	}

	if(!blocked && Call_StartClassFunc(Client(target).Class, ClassEnum::FuncTransmitSelf))
	{
		Call_PushCell(target);
		Call_PushCell(client);
		Call_Finish(blocked);
	}

	return blocked;
}