#pragma semicolon 1
#pragma newdecls required

enum struct ClassEnum
{
	char Name[32];
	char Display[32];
	char Spawn[32];

	bool Regen;
	bool DeadClass;
	bool Cosmetics;
	
	int Health;
	int MusicType;
	int HandModel;
	int PlayerModel;
	int ForceTeam;
	int PaintColor;

	float Speed;
	float SpeakAllyDist;
	float SpeakOtherDist;

	TFClassType Class;

	int StartAmmo[Ammo_MAX];
	int MaxAmmo[Ammo_MAX];
	int StartItems[10];
	int MaxItems[Type_MAX+1];

	Function FuncCanTalkTo;		// void(int client, int target, float &distance)
	Function FuncCardAccess;	// void(int client, int type, int &level) 
	Function FuncCommand;		// bool(int client, const char[] command)
	Function FuncCondAdded;		// void(int client, TFCond cond)
	Function FuncDeath;			// void(int client, int attacker, Event event)
	Function FuncDealDamage;	// void(int client, int victim, ...)
	Function FuncDoAnimation;	// Action(int client, int anim, int data)
	Function FuncDoorTouch;		// void(int client, int entity)
	Function FuncDoorWalk;		// bool(int client, int entity)
	Function FuncForceRespawn;	// bool(int client)
	Function FuncInventory;		// bool(int client)
	Function FuncKill;			// void(int client, int victim, Event event)
	Function FuncMusic;			// void(int client, char filepath[PLATFORM_MAX_PATH], int &duration)
	Function FuncPlayerRunCmd;	// Action(int client, int &buttons)
	Function FuncPrecache;		// void(int index, ClassEnum class)
	Function FuncSetClass;		// void(int client)
	Function FuncSound;			// Action(int client, int clients[MAXPLAYERS], ...)
	Function FuncSpawn;			// bool(int client)
	Function FuncTakeDamage;	// void(int client, int &attacker, ...)
	Function FuncTransmitSee;	// bool(int client, int target)
	Function FuncTransmitSelf;	// bool(int client, int target)
	Function FuncUpdateSpeed;	// void(int client, float &speed)
	Function FuncWeaponSwitch;	// void(int client, int entity)
	Function FuncViewmodel;		// void(int client, int entity, WeaponEnum weapon)

	int SetupEnum(KeyValues kv, ArrayList whitelist, const ClassEnum defaul)
	{
		kv.GetSectionName(this.Name, sizeof(this.Name));

		// Check whitelist
		int pos = whitelist ? whitelist.FindString(this.Name) : 0;
		if(pos == -1)
			return -1;
		
		char buffer[PLATFORM_MAX_PATH];

		/*
			Display Class Name
		*/
		Format(this.Display, sizeof(this.Display), "class_%s", this.Name);
		if(!TranslationPhraseExists(this.Display))
			strcopy(this.Display, sizeof(this.Display), "class_0");

		/*
			Generic Values
		*/
		this.Regen = view_as<bool>(kv.GetNum("regen", defaul.Regen));
		this.DeadClass = view_as<bool>(kv.GetNum("deadclass", defaul.DeadClass));
		this.Cosmetics = view_as<bool>(kv.GetNum("cosmetics", defaul.Cosmetics));
		this.Health = kv.GetNum("health", defaul.Health);
		this.MusicType = kv.GetNum("musicindex", defaul.MusicType);
		this.ForceTeam = kv.GetNum("forceteam", defaul.ForceTeam);
		this.PaintColor = kv.GetNum("paintcolor", defaul.PaintColor);
		this.Speed = kv.GetFloat("speed", defaul.Speed);
		this.SpeakAllyDist = kv.GetFloat("speakallydist", defaul.SpeakAllyDist);
		this.SpeakOtherDist = kv.GetFloat("speakotherdist", defaul.SpeakOtherDist);
		this.Class = KvGetClass(kv, "class", defaul.Class);
		this.PlayerModel = KvGetModelIndex(kv, "model", defaul.PlayerModel);
		this.HandModel = KvGetModelIndex(kv, "hands", defaul.HandModel);
		kv.GetString("spawn", this.Spawn, sizeof(this.Spawn), defaul.Spawn);

		/*
			Array Values
		*/
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
				IntToString(i + 1, this.Spawn, sizeof(this.Spawn));
				this.StartItems[i] = kv.GetNum(this.Spawn, -1);
			}

			kv.GoBack();
		}
		else
		{
			this.StartItems = defaul.StartItems;
		}

		if(kv.JumpToKey("MaxItems"))
		{
			this.MaxItems[0] = kv.GetNum("0", 31);

			for(int i = 1; i < sizeof(this.MaxItems); i++)
			{
				IntToString(i - 1, this.Spawn, sizeof(this.Spawn));
				this.MaxItems[i] = kv.GetNum(this.Spawn);
			}

			kv.GoBack();
		}
		else
		{
			this.MaxItems = defaul.MaxItems;
		}

		/*
			Precache List
		*/
		if(kv.JumpToKey("Precache"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));
					if(buffer[0])
					{
						kv.GetString(NULL_STRING, this.Spawn, sizeof(this.Spawn));

						if(this.Spawn[0] == 'm')	// mdl, model, mat, material
						{
							PrecacheModel(buffer);
						}
						else if(this.Spawn[0] == 'g' || this.Spawn[2] == 'r')	// gs, gamesound, script
						{
							PrecacheScriptSound(buffer);
						}
						else if(this.Spawn[0] == 's')
						{
							if(this.Spawn[1] == 'e')	// sentence
							{
								PrecacheSentenceFile(buffer);
							}
							else	// snd, sound
							{
								PrecacheSound(buffer);
							}
						}
						else if(this.Spawn[0] == 'd')	// decal
						{
							PrecacheDecal(buffer);
						}
						else if(this.Spawn[0])	// generic
						{
							PrecacheGeneric(buffer);
						}
					}
				}
				while(kv.GotoNextKey(false));

				kv.GoBack();
			}

			kv.GoBack();
		}

		/*
			Download List
		*/
		if(kv.JumpToKey("Downloads"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				int table = FindStringTable("downloadables");
				bool save = LockStringTables(false);

				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));
					if(!FileExists(buffer, true))
					{
						LogError("[Config] '%s' has missing file '%s' in 'Downloads'", this.Name, buffer);
						continue;
					}

					AddToStringTable(table, buffer);
				}
				while(kv.GotoNextKey(false));

				LockStringTables(save);
				kv.GoBack();
			}

			kv.GoBack();
		}

		/*
			Function Values
		*/
		this.FuncCanTalkTo = KvGetFunction(kv, "func_cantalkto", defaul.FuncCanTalkTo);
		this.FuncCardAccess = KvGetFunction(kv, "func_cardaccess", defaul.FuncCardAccess);
		this.FuncCommand = KvGetFunction(kv, "func_clientcommand", defaul.FuncCommand);
		this.FuncCondAdded = KvGetFunction(kv, "func_condadded", defaul.FuncCondAdded);
		this.FuncDealDamage = KvGetFunction(kv, "func_dealdamage", defaul.FuncDealDamage);
		this.FuncDeath = KvGetFunction(kv, "func_playerdeath", defaul.FuncDeath);
		this.FuncDoAnimation = KvGetFunction(kv, "func_doanimation", defaul.FuncDoAnimation);
		this.FuncDoorTouch = KvGetFunction(kv, "func_doortouch", defaul.FuncDoorTouch);
		this.FuncDoorWalk = KvGetFunction(kv, "func_doorwalk", defaul.FuncDoorWalk);
		this.FuncForceRespawn = KvGetFunction(kv, "func_forcerespawn", defaul.FuncForceRespawn);
		this.FuncInventory = KvGetFunction(kv, "func_inventory", defaul.FuncInventory);
		this.FuncKill = KvGetFunction(kv, "func_playerkill", defaul.FuncKill);
		this.FuncMusic = KvGetFunction(kv, "func_music", defaul.FuncMusic);
		this.FuncPlayerRunCmd = KvGetFunction(kv, "func_playerruncmd", defaul.FuncPlayerRunCmd);
		this.FuncPrecache = KvGetFunction(kv, "func_precache", defaul.FuncPrecache);
		this.FuncSetClass = KvGetFunction(kv, "func_setclass", defaul.FuncSetClass);
		this.FuncSound = KvGetFunction(kv, "func_sound", defaul.FuncSound);
		this.FuncSpawn = KvGetFunction(kv, "func_playerspawn", defaul.FuncSpawn);
		this.FuncTakeDamage = KvGetFunction(kv, "func_takedamage", defaul.FuncTakeDamage);
		this.FuncTransmitSee = KvGetFunction(kv, "func_transmitsee", defaul.FuncTransmitSee);
		this.FuncTransmitSelf = KvGetFunction(kv, "func_transmitself", defaul.FuncTransmitSelf);
		this.FuncUpdateSpeed = KvGetFunction(kv, "func_updatespeed", defaul.FuncUpdateSpeed);
		this.FuncWeaponSwitch = KvGetFunction(kv, "func_weaponswitch", defaul.FuncWeaponSwitch);
		this.FuncViewmodel = KvGetFunction(kv, "func_viewmodel", defaul.FuncViewmodel);

		return pos;
	}

	void SetDefaultValues()
	{
		this.FuncCanTalkTo = INVALID_FUNCTION;
		this.FuncCardAccess = INVALID_FUNCTION;
		this.FuncCommand = INVALID_FUNCTION;
		this.FuncCondAdded = INVALID_FUNCTION;
		this.FuncDealDamage = INVALID_FUNCTION;
		this.FuncDeath = INVALID_FUNCTION;
		this.FuncDoAnimation = INVALID_FUNCTION;
		this.FuncDoorTouch = INVALID_FUNCTION;
		this.FuncDoorWalk = INVALID_FUNCTION;
		this.FuncForceRespawn = INVALID_FUNCTION;
		this.FuncInventory = INVALID_FUNCTION;
		this.FuncKill = INVALID_FUNCTION;
		this.FuncMusic = INVALID_FUNCTION;
		this.FuncPlayerRunCmd = INVALID_FUNCTION;
		this.FuncPrecache = INVALID_FUNCTION;
		this.FuncSetClass = INVALID_FUNCTION;
		this.FuncSound = INVALID_FUNCTION;
		this.FuncSpawn = INVALID_FUNCTION;
		this.FuncTakeDamage = INVALID_FUNCTION;
		this.FuncTransmitSee = INVALID_FUNCTION;
		this.FuncTransmitSelf = INVALID_FUNCTION;
		this.FuncUpdateSpeed = INVALID_FUNCTION;
		this.FuncWeaponSwitch = INVALID_FUNCTION;
		this.FuncViewmodel = INVALID_FUNCTION;
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

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), FOLDER_CONFIGS ... "/classes.cfg");

	KeyValues kv = new KeyValues("Classes");
	kv.ImportFromFile(buffer);

	ClassEnum defaul, class;
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
	if(!Classes_GetByIndex(index, class))
		return false;
	
	Function func = class.GetFuncOf(pos);
	if(func == INVALID_FUNCTION)
		return false;
	
	Call_StartFunction(null, func);
	return true;
}

bool Classes_GetByIndex(int index, ClassEnum class = {})
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

Action Classes_SetClientClass(int client, int index, int context)
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

void Classes_UpdateHealth(int client)
{
	float amount = 0.0;

	ClassEnum class;
	if(Classes_GetByIndex(Client(client).Class, class) && class.Health > 0)
	{
		// Apply correct health per class
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Soldier:
				amount = float(class.Health) - 200.0;
			
			case TFClass_Pyro, TFClass_DemoMan:
				amount = float(class.Health) - 175.0;
			
			case TFClass_Heavy:
				amount = float(class.Health) - 300.0;
			
			case TFClass_Medic:
				amount = float(class.Health) - 150.0;
			
			default:
				amount = float(class.Health) - 125.0;
		}
	}

	TF2Attrib_SetByName(client, "max health additive bonus", amount);
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

void Classes_TeleportToPoint(int client, const char[] spawn)
{
	ArrayList list = new ArrayList();

	char name[32];
	int entity = -1;
	while((entity=FindEntityByClassname(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(!StrContains(name, spawn, false))
			list.Push(entity);
	}

	int length = list.Length;
	if(!length && GetClientTeam(client) <= TFTeam_Spectator)
	{
		entity = -1;
		while((entity=FindEntityByClassname(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(StrEqual(name, "scp_spawn_p", false))
				list.Push(entity);
		}

		length = list.Length;
	}

	if(length)
	{
		entity = list.Get(GetRandomInt(0, length-1));

		static float pos[3], ang[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ang);
		ang[0] = 0.0;
		ang[2] = 0.0;
		TeleportEntity(client, pos, ang, NULL_VECTOR);
	}

	delete list;
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

int Classes_GetMaxItems(int client, int type)
{
	int index = type + 1;
	if(index >= 0 && index <= Type_MAX)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client(client).Class, class))
			return class.MaxItems[index];
	}
	return -1;
}

bool Classes_IsDeadClass(int client)
{
	ClassEnum class;
	Classes_GetByIndex(Client(client).Class, class);
	return class.DeadClass;
}

void Classes_PlayerSpawn(int client)
{
	bool result = false;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncSpawn))
	{
		Call_PushCell(client);
		Call_Finish(result);
	}

	if(!result)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client(client).Class, class))
		{
			if(class.ForceTeam >= 0)
				SDKCalls_ChangeClientTeam(client, class.ForceTeam);
			
			if(class.Spawn[0])
				Classes_TeleportToPoint(client, class.Spawn);
			
			TF2_AddCondition(client, TFCond_DodgeChance, 5.0);
		}
	}
}

void Classes_PostInventoryApplication(int client)
{
	bool result = false;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncInventory))
	{
		Call_PushCell(client);
		Call_Finish(result);
	}

	if(!result)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client(client).Class, class))
		{
			if(class.Cosmetics && GetClientTeam(client) > TFTeam_Spectator)
			{
				for(int i = TF2Util_GetPlayerWearableCount(client) - 1; i >= 0; i--)
				{
					int entity = TF2Util_GetPlayerWearable(client, i);
					if(entity != -1)
					{
						SetEntProp(entity, Prop_Send, "m_bOnlyIterateItemViewAttributes", true);	// Removes attributes
						
						if(class.PaintColor)
							TF2Attrib_SetByName(entity, "set item tint RGB", view_as<float>(class.PaintColor));
						
						/*
						if(team == 2)
						{
							TF2Attrib_SetByName(entity, "set item tint RGB", view_as<float>(13595446));	// Mann Co. Orange
						}
						else
						{
							TF2Attrib_SetByName(entity, "set item tint RGB", view_as<float>(15132390));	// An Extraordinary Abundance of Tinge
						}
						*/
					}
				}
			}
			else
			{
				for(int i = TF2Util_GetPlayerWearableCount(client) - 1; i >= 0; i--)
				{
					int entity = TF2Util_GetPlayerWearable(client, i);
					if(entity != -1)
						TF2_RemoveWearable(client, entity);
				}
			}

			char buffer[PLATFORM_MAX_PATH];
			if(class.PlayerModel)
				ModelIndexToString(class.PlayerModel, buffer, sizeof(buffer));
			
			SetVariantString(buffer);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
			
			int length = GetMaxWeapons(client);
			for(int i; i < length; i++)
			{
				int entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if(entity != -1)
					TF2_RemoveItem(client, entity);
			}

			Classes_UpdateHealth(client);

			for(int i; i < sizeof(class.StartItems); i++)
			{
				if(class.StartItems[i] >= 0)
					Items_GiveItem(client, class.StartItems[i]);
			}

			for(int i = 1; i < sizeof(class.StartAmmo); i++)
			{
				SetAmmo(client, class.StartAmmo[i], i);
			}

			TF2Attrib_SetByDefIndex(client, 49, 1.0);
		}
	}
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

void Classes_PlayerDeath(int victim, int attacker, Event event)
{
	if(Call_StartClassFunc(Client(victim).Class, ClassEnum::FuncDeath))
	{
		Call_PushCell(victim);
		Call_PushCell(attacker);
		Call_PushCell(event);
		Call_Finish();
	}

	if(attacker && Call_StartClassFunc(Client(attacker).Class, ClassEnum::FuncKill))
	{
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCell(event);
		Call_Finish();
	}
}

void Classes_DoorTouch(int client, int entity)
{
	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncDoorTouch))
	{
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_Finish();
	}
}

bool Classes_DoorWalk(int client, int entity)
{
	bool result = false;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncDoorWalk))
	{
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_Finish(result);
	}

	return result;
}

Action Classes_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;

	if(Call_StartClassFunc(Client(victim).Class, ClassEnum::FuncTakeDamage))
	{
		Call_PushCell(victim);
		Call_PushCellRef(attacker);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, sizeof(damageForce), SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, sizeof(damagePosition), SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);

		if(result >= Plugin_Handled)
			return result;
	}

	bool changed = result == Plugin_Changed;

	if(attacker > 0 && attacker <= MaxClients && Call_StartClassFunc(Client(attacker).Class, ClassEnum::FuncDealDamage))
	{
		Call_PushCell(attacker);
		Call_PushCell(victim);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, sizeof(damageForce), SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, sizeof(damagePosition), SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);

		if(result == Plugin_Continue && changed)
			result = Plugin_Changed;
	}
	
	return result;
}

Action Classes_SoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	Action result = Plugin_Continue;

	if(Call_StartClassFunc(Client(entity).Class, ClassEnum::FuncSound))
	{
		Call_PushCell(entity);
		Call_PushArrayEx(clients, sizeof(clients), SM_PARAM_COPYBACK);
		Call_PushCellRef(numClients);
		Call_PushStringEx(sample, sizeof(sample), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(channel);
		Call_PushFloatRef(volume);
		Call_PushCellRef(level);
		Call_PushCellRef(pitch);
		Call_PushCellRef(flags);
		Call_PushStringEx(soundEntry, sizeof(soundEntry), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(seed);
		Call_Finish(result);
	}

	return result;
}

void Classes_SetViewmodel(int client, int entity, WeaponEnum weapon)
{
	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncViewmodel))
	{
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_PushArrayEx(weapon, sizeof(weapon), SM_PARAM_COPYBACK);
		Call_Finish();
	}
}

Action Classes_DoAnimationEvent(int client, int &anim, int &data)
{
	Action result = Plugin_Continue;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncDoAnimation))
	{
		Call_PushCell(client);
		Call_PushCellRef(anim);
		Call_PushCellRef(data);
		Call_Finish(result);
	}

	return result;
}

void Classes_CardAccess(int client, int type, int &level)
{
	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncCardAccess))
	{
		Call_PushCell(client);
		Call_PushCell(type);
		Call_PushCellRef(level);
		Call_Finish();
	}
}

bool Classes_ForceRespawn(int client)
{
	bool result = false;

	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncForceRespawn))
	{
		Call_PushCell(client);
		Call_Finish(result);
	}

	return result;
}

void Classes_WeaponSwitch(int client, int entity)
{
	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncWeaponSwitch))
	{
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_Finish();
	}
}

void Classes_ConditionAdded(int client, TFCond cond)
{
	if(Call_StartClassFunc(Client(client).Class, ClassEnum::FuncCondAdded))
	{
		Call_PushCell(client);
		Call_PushCell(cond);
		Call_Finish();
	}
}
