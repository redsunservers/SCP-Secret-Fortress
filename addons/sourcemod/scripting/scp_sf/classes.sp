#define ITEMS_MAX	8
#define AMMO_MAX		16

enum struct ClassEnum
{
	char Name[16];
	char Display[22];

	TFClassType Class;
	char Model[PLATFORM_MAX_PATH];
	int ModelIndex;
	int ModelAlt;
	bool Human;
	bool Vip;
	bool Driver;

	float Speak;
	float Hear;
	float SpeakTeam;
	float HearTeam;

	int Health;
	float Speed;
	bool Regen;

	int Group;
	TFTeam Team;

	int Floor;
	char Spawn[32];
	char Color[16];
	int Color4[4];

	int Ammo[AMMO_MAX];
	int MaxAmmo[AMMO_MAX];
	int Items[12];
	int MaxItems[ITEMS_MAX];

	Function OnAnimation;	// Action(int client, PlayerAnimEvent_t &anim, int &data)
	Function OnButton;	// void(int client, int button)
	Function OnCanSpawn;	// bool(int client)
	Function OnCondAdded;	// void(int client, TFCond cond)
	Function OnCondRemoved;	// void(int client, TFCond cond)
	Function OnDealDamage;	// Action(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnDeath;		// void(int client, int attacker)
	Function OnDoorWalk;	// bool(int client, int entity)
	Function OnGlowPlayer;	// bool(int client, int victim)
	Function OnKeycard;	// int(int client, AccessEnum access)
	Function OnKill;		// void(int client, int victim)
	Function OnMaxHealth;	// void(int client, int &health)
	Function OnPickup;	// bool(int client, int entity)
	Function OnSeePlayer;	// bool(int client, int victim)
	Function OnSound;		// Action(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
	Function OnSpawn;		// void(int client)
	Function OnSpeed;		// void(int client, float &speed)
	Function OnTakeDamage;	// Action(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
	Function OnTheme;		// void(int client, char path[PLATFORM_MAX_PATH])
	Function OnWeaponSwitch;	// void(int client, int entity)
	Function OnVoiceCommand;	// bool(int client)

	void SetDefaults()
	{
		this.OnAnimation = INVALID_FUNCTION;
		this.OnButton = INVALID_FUNCTION;
		this.OnCanSpawn = INVALID_FUNCTION;
		this.OnCondAdded = INVALID_FUNCTION;
		this.OnCondRemoved = INVALID_FUNCTION;
		this.OnDealDamage = INVALID_FUNCTION;
		this.OnDeath = INVALID_FUNCTION;
		this.OnDoorWalk = INVALID_FUNCTION;
		this.OnGlowPlayer = INVALID_FUNCTION;
		this.OnKeycard = INVALID_FUNCTION;
		this.OnKill = INVALID_FUNCTION;
		this.OnMaxHealth = INVALID_FUNCTION;
		this.OnPickup = INVALID_FUNCTION;
		this.OnSeePlayer = INVALID_FUNCTION;
		this.OnSound = INVALID_FUNCTION;
		this.OnSpawn = INVALID_FUNCTION;
		this.OnSpeed = INVALID_FUNCTION;
		this.OnTakeDamage = INVALID_FUNCTION;
		this.OnTheme = INVALID_FUNCTION;
		this.OnWeaponSwitch = INVALID_FUNCTION;
		this.OnVoiceCommand = INVALID_FUNCTION;
	}
}

static ArrayList Classes;
static bool AskClass;

void Classes_Setup(KeyValues main, KeyValues map, ArrayList whitelist)
{
	AskClass = false;
	if(Classes != INVALID_HANDLE)
		delete Classes;

	Classes = new ArrayList(sizeof(ClassEnum));

	KeyValues kv = main;
	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Classes"))
			kv = map;
	}

	ClassEnum defaul;
	defaul.SetDefaults();
	if(kv.JumpToKey("default"))
	{
		GrabKvValues(kv, defaul, defaul, -1);
		kv.GoBack();
	}

	ClassEnum class;
	if(kv.GotoFirstSubKey())
	{
		int count;
		do
		{
			if(!kv.GetSectionName(class.Name, sizeof(class.Name)) || StrEqual(class.Name, "default"))
				continue;

			if(whitelist && whitelist.FindString(class.Name)==-1)
				continue;

			GrabKvValues(kv, class, defaul, count++);
			Format(class.Display, sizeof(class.Display), "class_%s", class.Name);
			if(!TranslationPhraseExists(class.Display))
				strcopy(class.Display, sizeof(class.Display), "class_0");

			Classes.PushArray(class);
		} while(kv.GotoNextKey());
	}
}

static void GrabKvValues(KeyValues kv, ClassEnum class, ClassEnum defaul, int index)
{
	class.Class = KvGetClass(kv, "class", defaul.Class);
	if(class.Class==TFClass_Unknown && index!=-1)
		AskClass = true;

	class.Speed = kv.GetFloat("speed", defaul.Speed);
	class.Speak = kv.GetFloat("speak", defaul.Speak);
	class.Hear = kv.GetFloat("hear", defaul.Hear);
	class.SpeakTeam = kv.GetFloat("speak_team", defaul.SpeakTeam);
	class.HearTeam = kv.GetFloat("hear_team", defaul.HearTeam);

	class.Health = kv.GetNum("health", defaul.Health);
	class.Group = kv.GetNum("group", defaul.Group);
	class.Floor = kv.GetNum("floor", defaul.Floor);
	class.Team = view_as<TFTeam>(kv.GetNum("team", view_as<int>(defaul.Team)));
	class.Regen = view_as<bool>(kv.GetNum("regen", defaul.Regen ? 1 : 0));
	class.Human = view_as<bool>(kv.GetNum("human", defaul.Human ? 1 : 0));
	class.Vip = view_as<bool>(kv.GetNum("vip", defaul.Vip ? 1 : 0));
	class.Driver = view_as<bool>(kv.GetNum("driver", defaul.Driver ? 1 : 0));

	class.Color4 = defaul.Color4;
	kv.GetColor4("color4", class.Color4);

	class.OnAnimation = KvGetFunction(kv, "func_precache");
	if(class.OnAnimation != INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnAnimation);
		Call_PushCell(index);
		Call_Finish();
	}

	class.OnAnimation = KvGetFunction(kv, "func_animation", defaul.OnAnimation);
	class.OnButton = KvGetFunction(kv, "func_button", defaul.OnButton);
	class.OnCanSpawn = KvGetFunction(kv, "func_canspawn", defaul.OnCanSpawn);
	class.OnCondAdded = KvGetFunction(kv, "func_condadded", defaul.OnCondAdded);
	class.OnCondRemoved = KvGetFunction(kv, "func_condremove", defaul.OnCondRemoved);
	class.OnDealDamage = KvGetFunction(kv, "func_dealdamage", defaul.OnDealDamage);
	class.OnDeath = KvGetFunction(kv, "func_death", defaul.OnDeath);
	class.OnDoorWalk = KvGetFunction(kv, "func_doorwalk", defaul.OnDoorWalk);
	class.OnGlowPlayer = KvGetFunction(kv, "func_glow", defaul.OnGlowPlayer);
	class.OnKeycard = KvGetFunction(kv, "func_keycard", defaul.OnKeycard);
	class.OnKill = KvGetFunction(kv, "func_kill", defaul.OnKill);
	class.OnMaxHealth = KvGetFunction(kv, "func_maxhealth", defaul.OnMaxHealth);
	class.OnPickup = KvGetFunction(kv, "func_pickup", defaul.OnPickup);
	class.OnSeePlayer = KvGetFunction(kv, "func_transmit", defaul.OnSeePlayer);
	class.OnSound = KvGetFunction(kv, "func_sound", defaul.OnSound);
	class.OnSpawn = KvGetFunction(kv, "func_spawn", defaul.OnSpawn);
	class.OnSpeed = KvGetFunction(kv, "func_speed", defaul.OnSpeed);
	class.OnTakeDamage = KvGetFunction(kv, "func_takedamage", defaul.OnTakeDamage);
	class.OnTheme = KvGetFunction(kv, "func_theme", defaul.OnTheme);
	class.OnWeaponSwitch = KvGetFunction(kv, "func_switch", defaul.OnWeaponSwitch);
	class.OnVoiceCommand = KvGetFunction(kv, "func_voice", defaul.OnVoiceCommand);
	
	kv.GetString("spawn", class.Spawn, sizeof(class.Spawn), defaul.Spawn);
	kv.GetString("color", class.Color, sizeof(class.Color), defaul.Color);

	char num[6];
	if(kv.JumpToKey("ammo"))
	{
		for(int i; i<sizeof(class.Ammo); i++)
		{
			IntToString(i, num, sizeof(num));
			class.Ammo[i] = kv.GetNum(num, defaul.Ammo[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.Ammo = defaul.Ammo;
	}

	if(kv.JumpToKey("maxammo"))
	{
		for(int i; i<sizeof(class.MaxAmmo); i++)
		{
			IntToString(i, num, sizeof(num));
			class.MaxAmmo[i] = kv.GetNum(num, defaul.MaxAmmo[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.MaxAmmo = defaul.MaxAmmo;
	}

	if(kv.JumpToKey("items"))
	{
		for(int i; i<sizeof(class.Items); i++)
		{
			IntToString(i+1, num, sizeof(num));
			class.Items[i] = kv.GetNum(num, defaul.Items[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.Items = defaul.Items;
	}

	if(kv.JumpToKey("maxitems"))
	{
		for(int i; i<sizeof(class.MaxItems); i++)
		{
			IntToString(i, num, sizeof(num));
			class.MaxItems[i] = kv.GetNum(num, defaul.MaxItems[i]);
		}
		kv.GoBack();
	}
	else
	{
		class.MaxItems = defaul.MaxItems;
	}

	if(kv.JumpToKey("precache"))
	{
		for(int i=1; ; i++)
		{
			IntToString(i, num, sizeof(num));
			kv.GetString(num, class.Model, sizeof(class.Model));
			if(!class.Model[0])
				break;

			if(!FileExists(class.Model, true))
			{
				LogError("[Config] '%s' has missing file '%s' in 'precache'", class.Name, class.Model);
				continue;
			}

			PrecacheModel(class.Model, true);
		}
		kv.GoBack();
	}

	if(kv.JumpToKey("precache_sound"))
	{
		for(int i=1; ; i++)
		{
			IntToString(i, num, sizeof(num));
			kv.GetString(num, class.Model, sizeof(class.Model));
			if(!class.Model[0])
				break;

			PrecacheSound(class.Model, true);
		}
		kv.GoBack();
	}

	if(kv.JumpToKey("downloads"))
	{
		int table = FindStringTable("downloadables");
		bool save = LockStringTables(false);
		for(int i=1; ; i++)
		{
			IntToString(i, num, sizeof(num));
			kv.GetString(num, class.Model, sizeof(class.Model));
			if(!class.Model[0])
				break;

			if(!FileExists(class.Model, true))
			{
				LogError("[Config] '%s' has missing file '%s' in 'downloads'", class.Name, class.Model);
				continue;
			}

			AddToStringTable(table, class.Model);
		}
		LockStringTables(save);
		kv.GoBack();
	}
	
	kv.GetString("modelalt", class.Model, sizeof(class.Model));
	class.ModelAlt = class.Model[0] ? PrecacheModel(class.Model, true) : defaul.ModelAlt;	

	kv.GetString("modelgibs", class.Model, sizeof(class.Model));
	if (class.Model[0])
	{
		// max 8 gibs
		// first one is relative path
		char GibBuffers[8][PLATFORM_MAX_PATH];
		int GibCount = ExplodeString(class.Model, ";", GibBuffers, sizeof(GibBuffers), sizeof(GibBuffers[]));
		
		for (int i = 1; i < GibCount; i++)
		{
			Format(class.Model, sizeof(class.Model), "%s%s.mdl", GibBuffers[0], GibBuffers[i]);
			PrecacheModel(class.Model, true);
		}
	}

	kv.GetString("model", class.Model, sizeof(class.Model), defaul.Model);
	class.ModelIndex = class.Model[0] ? PrecacheModel(class.Model, true) : defaul.ModelIndex;
}

bool Classes_GetByIndex(int index, ClassEnum class)
{
	if(!Classes || index<0 || index>=Classes.Length)
		return false;

	Classes.GetArray(index, class);
	return true;
}

int Classes_GetByName(const char[] name, ClassEnum class=0)
{
	int length = Classes.Length;
	for(int i; i<length; i++)
	{
		Classes.GetArray(i, class);
		if(StrEqual(name, class.Name, false))
			return i;
	}
	return -1;
}

bool Classes_AssignClass(int client, ClassSpawnEnum context, int &index)
{
	ClassEnum class;
	if(!Classes_GetByIndex(index, class))
	{
		index = 0;
		Classes_GetByIndex(index, class);
	}

	switch(Forward_OnClassPre(client, context, class.Name, sizeof(class.Name)))
	{
		case Plugin_Changed, Plugin_Handled:
		{
			index = Classes_GetByName(class.Name);
			if(index == -1)
				index = 0;
		}
		case Plugin_Stop:
		{
			return false;
		}
	}
	return true;
}

void Classes_AssignClassPost(int client, ClassSpawnEnum context)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
		Forward_OnClass(client, context, class.Name);
}

void Classes_PlayerSpawn(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		Client[client].Colors = class.Color4;
		for(int i; i<3; i++)
		{
			if(Client[client].ColorBlind[i] >= 0)
				Client[client].Colors[i] = Client[client].ColorBlind[i];
		}

		bool result;
		if(class.OnSpawn != INVALID_FUNCTION)
		{
			Call_StartFunction(null, class.OnSpawn);
			Call_PushCell(client);
			Call_Finish(result);
		}

		if(!result)
		{
			// Teleport to spawn point
			ChangeClientTeamEx(client, class.Team);
			Classes_SpawnPoint(client, Client[client].Class);

			// Show class info
			Client[client].HudIn = GetGameTime()+9.9;
			CreateTimer(2.0, ShowClassInfoTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

			// Model stuff
			SetVariantString(class.Model);
			AcceptEntityInput(client, "SetCustomModel");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelIndex, _, 0);
			SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", class.ModelAlt, _, 3);
			TF2_CreateGlow(client, class.Model);

			// Reset health
			SetEntityHealth(client, class.Health);

			// Weapon stuff
			int i;
			for(; i<sizeof(class.Items); i++)
			{
				if(!class.Items[i])
					break;

				Items_CreateWeapon(client, class.Items[i], !i, true);
			}

			if(i > 1)
				Items_ShowItemMenu(client);

			// Ammo stuff
			for(i=0; i<AMMO_MAX; i++)
			{
				SetEntProp(client, Prop_Data, "m_iAmmo", class.Ammo[i], _, i);
			}

			// Other stuff
			TF2_AddCondition(client, TFCond_NoHealingDamageBuff, 1.0);
			TF2_AddCondition(client, TFCond_DodgeChance, 3.0);
			TF2Attrib_SetByDefIndex(client, 49, 1.0);
		}
	}
}

void Classes_SpawnPoint(int client, int index)
{
	ClassEnum class;
	if(Classes_GetByIndex(index, class) && class.Spawn[0])
	{
		ArrayList list = new ArrayList();
		int entity = -1;
		static char name[32];
		while((entity=FindEntityByClassname(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(!StrContains(name, class.Spawn, false))
				list.Push(entity);
		}

		int length = list.Length;
		if(!length && !class.Human)	// Temp backwards compability
		{
			entity = -1;
			while((entity=FindEntityByClassname(entity, "info_target")) != -1)
			{
				GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
				if(StrEqual(name, "scp_spawn_p", false))
					list.Push(entity);
			}

			length = list.Length;
			if(!length)
			{
				Client[client].InvisFor = GetGameTime()+30.0;

				DataPack pack;
				CreateDataTimer(1.0, Timer_Stun, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(client));
				pack.WriteFloat(29.0);
				pack.WriteFloat(1.0);
				pack.WriteCell(TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT);
				delete list;
				return;
			}
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
}

int Classes_GetMaxAmmo(int client, int type)
{
	if(type>=0 && type<AMMO_MAX)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
		{
			int ammo = class.MaxAmmo[type];
			if(ammo > 0)
				return ammo;
		}
	}
	return 0;
}

void Classes_GetMaxAmmoList(int client, int ammo[AMMO_MAX])
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		for(int i; i<AMMO_MAX; i++)
		{
			ammo[i] = class.MaxAmmo[i];
		}
	}
}

int Classes_GetMaxItems(int client, int type)
{
	if(type>=0 && type<ITEMS_MAX)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
			return class.MaxItems[type];
	}
	return 0;
}

int Classes_GetMaxHealth(int client)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class))
		return 125;

	int health = class.Health;
	if(class.OnMaxHealth != INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnMaxHealth);
		Call_PushCell(client);
		Call_PushCellRef(health);
		Call_Finish();
	}
	return health;
}

bool Classes_AskForClass()
{
	return AskClass;
}

stock bool IsSCP(int client)
{
	ClassEnum class;
	Classes_GetByIndex(Client[client].Class, class);
	return !class.Human;
}

Action Classes_OnAnimation(int client, PlayerAnimEvent_t &anim, int &data)
{
	Action result = Plugin_Continue;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnAnimation!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnAnimation);
		Call_PushCell(client);
		Call_PushCellRef(anim);
		Call_PushCellRef(data);
		Call_Finish(result);
	}
	return result;
}

void Classes_OnButton(int client, int button)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnButton==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnButton);
	Call_PushCell(client);
	Call_PushCell(button);
	Call_Finish();
}

void Classes_OnCondAdded(int client, TFCond cond)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnCondAdded==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnCondAdded);
	Call_PushCell(client);
	Call_PushCell(cond);
	Call_Finish();
}

void Classes_OnCondRemoved(int client, TFCond cond)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnCondRemoved==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnCondRemoved);
	Call_PushCell(client);
	Call_PushCell(cond);
	Call_Finish();
}

Action Classes_OnDealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnDealDamage!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnDealDamage);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnDeath(int client, Event event)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnDeath!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnDeath);
		Call_PushCell(client);
		Call_PushCell(event);
		Call_Finish(result);
	}
	return result;
}

stock bool Classes_OnDoorWalk(int client, int entity)	// TODO: Find a good way to ShouldCollide on func entities per player
{
	bool result = true;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnDoorWalk!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnDoorWalk);
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnGlowPlayer(int client, int victim)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnGlowPlayer!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnGlowPlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnKeycard(int client, any access, int &value)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnKeycard==INVALID_FUNCTION)
		return false;

	Call_StartFunction(null, class.OnKeycard);
	Call_PushCell(client);
	Call_PushCell(access);
	Call_Finish(value);
	return true;
}

void Classes_OnKill(int client, int victim)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnKill==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnKill);
	Call_PushCell(client);
	Call_PushCell(victim);
	Call_Finish();
}

bool Classes_OnPickup(int client, int entity)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnPickup!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnPickup);
		Call_PushCell(client);
		Call_PushCell(entity);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnSeePlayer(int client, int victim)
{
	bool result = true;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnSeePlayer!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnSeePlayer);
		Call_PushCell(client);
		Call_PushCell(victim);
		Call_Finish(result);
	}
	return result;
}

bool Classes_OnSound(Action &result, int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnSound==INVALID_FUNCTION)
		return false;

	Call_StartFunction(null, class.OnSound);
	Call_PushCell(client);
	Call_PushStringEx(sample, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(channel);
	Call_PushFloatRef(volume);
	Call_PushCellRef(level);
	Call_PushCellRef(pitch);
	Call_PushCellRef(flags);
	Call_PushStringEx(soundEntry, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(seed);
	Call_Finish(result);
	return true;
}

void Classes_OnSpeed(int client, float &speed)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class) || class.OnSpeed==INVALID_FUNCTION)
		return;

	Call_StartFunction(null, class.OnSpeed);
	Call_PushCell(client);
	Call_PushFloatRef(speed);
	Call_Finish();
}

Action Classes_OnTakeDamage(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	Action result = Plugin_Continue;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnTakeDamage!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnTakeDamage);
		Call_PushCell(client);
		Call_PushCell(attacker);
		Call_PushCellRef(inflictor);
		Call_PushFloatRef(damage);
		Call_PushCellRef(damagetype);
		Call_PushCellRef(weapon);
		Call_PushArrayEx(damageForce, 3, SM_PARAM_COPYBACK);
		Call_PushArrayEx(damagePosition, 3, SM_PARAM_COPYBACK);
		Call_PushCell(damagecustom);
		Call_Finish(result);
	}
	return result;
}

float Classes_OnTheme(int client, char path[PLATFORM_MAX_PATH])
{
	float result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnTheme!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnTheme);
		Call_PushCell(client);
		Call_PushStringEx(path, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish(result);
	}
	return result;
}

void Classes_OnWeaponSwitch(int client, int entity)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class)) return;

	if(!StrEqual(class.Name, "scp173", false))
	{
		if(entity>MaxClients && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==ITEM_INDEX_MICROHID)
		{
			charge[client] = 0.0;
			SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 99.0);
			TF2Attrib_SetByDefIndex(entity, 821, 1.0);
		}
	}

	if(class.OnWeaponSwitch==INVALID_FUNCTION) return;
	
	Call_StartFunction(null, class.OnWeaponSwitch);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_Finish();
}

bool Classes_OnVoiceCommand(int client)
{
	bool result;
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class) && class.OnVoiceCommand!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, class.OnVoiceCommand);
		Call_PushCell(client);
		Call_Finish(result);
	}
	return result;
}

public bool Classes_GhostSpawn(int client)
{
	ClassEnum class;
	if(!Classes_GetByIndex(Client[client].Class, class))
		return false;

	TF2_AddCondition(client, TFCond_HalloweenGhostMode);

	SetVariantString(class.Model);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);

	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", (Client[client].IsVip ? class.ModelAlt : class.ModelIndex), _, 0);
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", (Client[client].IsVip ? class.ModelAlt : class.ModelIndex), _, 3);

	if(IsFakeClient(client))
		TeleportEntity(client, TRIPLE_D, NULL_VECTOR, NULL_VECTOR);

	return true;
}

public bool Classes_VipSpawn(int client)
{
	ClassEnum class;
	if(Classes_GetByIndex(Client[client].Class, class))
	{
		switch(class.Group)
		{
			case 0:
				Gamemode_AddValue("ptotal");

			case 1:
				Gamemode_AddValue("dtotal");

			default:
				Gamemode_AddValue("stotal");
		}
	}
	return false;
}

public void Classes_MoveToSpec(int client, Event event)
{
	char buffer[16] = "spec";
	int index = Classes_GetByName(buffer);
	if(Classes_AssignClass(client, ClassSpawn_Death, index))
	{
		Client[client].Class = index;
		Classes_AssignClassPost(client, ClassSpawn_Death);
	}
}

public bool Classes_DeathScp(int client, Event event)
{
	ClassEnum clientClass;
	Classes_GetByIndex(Client[client].Class, clientClass);

	Gamemode_AddValue("pkill");

	ClassEnum attackerClass;
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(attacker!=client && IsValidClient(attacker) && Classes_GetByIndex(Client[attacker].Class, attackerClass))
	{
		int weapon = event.GetInt("weaponid");
		if(weapon>MaxClients && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==ITEM_INDEX_MICROHID)
			GiveAchievement(Achievement_KillSCPMirco, attacker);

		if(StrEqual(attackerClass.Name, "sci"))
			GiveAchievement(Achievement_KillSCPSci, attacker);

		Config_DoReaction(attacker, "killscp");

		// 10% reward
		Classes_ApplyKarmaBonus(attacker, 10.0, false);

		ClassEnum assisterClass;
		int assister = GetClientOfUserId(event.GetInt("assister"));
		if(assister!=client && IsValidClient(assister) && Classes_GetByIndex(Client[assister].Class, assisterClass))
		{
			if(StrEqual(assisterClass.Name, "sci"))
				GiveAchievement(Achievement_KillSCPSci, assister);

			Config_DoReaction(assister, "killscp");

			// 10% bonus for helping
			Classes_ApplyKarmaBonus(assister, 10.0, false);

			CPrintToChatAll("%s%t", PREFIX, "scp_killed_duo", clientClass.Color, clientClass.Display, attackerClass.Color, attackerClass.Display, assisterClass.Color, assisterClass.Display);
		}
		else
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, attackerClass.Color, attackerClass.Display);
		}

		if(attackerClass.Group==2 || assisterClass.Group==2)
			Gamemode_GiveTicket(2, 5);
	}
	else
	{
		int damage = event.GetInt("damagebits");
		if(damage & DMG_SHOCK)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "tesla_gate");
		}
		else if(damage & DMG_NERVEGAS)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "femur_breaker");
		}
		else if(damage & DMG_BLAST)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "alpha_warhead");
		}
		else if(damage & DMG_POISON)
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "gray", "light_decontamination");
		}
		else
		{
			CPrintToChatAll("%s%t", PREFIX, "scp_killed", clientClass.Color, clientClass.Display, "black", "redacted");
		}
	}

	Classes_MoveToSpec(client, event);
	return true;
}

public void Classes_PlayDeathAnimation(int client, const char[] modelname, const char[] animation, const char[] soundname, float removetime)
{
	float pos[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		// try snap to floor if not on ground
		TR_TraceRayFilter(pos, view_as<float>({90.0, 0.0, 0.0}), MASK_SOLID, RayType_Infinite, Trace_OnlyHitWorld);
		if (!TR_DidHit())
			return;
		
		TR_GetEndPosition(pos);
	}	
	
	int entity = CreateEntityByName("prop_dynamic_override");
	if (!IsValidEntity(entity))
		return;

	RequestFrame(RemoveRagdoll, GetClientUserId(client));
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(entity, "skin", "0");	
	DispatchKeyValue(entity, "model", modelname);

	float angles[3];
	GetClientEyeAngles(client, angles);
	angles[0] = 0.0;
	angles[2] = 0.0;
	DispatchKeyValueVector(entity, "angles", angles);
	
	DispatchSpawn(entity);

	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
	SetVariantString(animation);
	AcceptEntityInput(entity, "SetAnimation");
	
	if (soundname[0])
	{
		EmitSoundToAll2(soundname, client, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, _, _, _, client);
	}
	
	if (removetime > 0.0)
	{
		CreateTimer(removetime, Timer_RemoveEntity, EntIndexToEntRef(entity));
	}
}

public void Classes_KillDBoi(int client, int victim)
{
	if( Classes_GetByName("sci") == Client[victim].Class ||
		Classes_GetByName("sci1") == Client[victim].Class ||
		Classes_GetByName("sci2") == Client[victim].Class ||
		Classes_GetByName("sci3") == Client[victim].Class)
	{
		if(Items_OnKeycard(victim, Access_Main))
			GiveAchievement(Achievement_KillSci, client);

		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
			Gamemode_GiveTicket(class.Group, 1);
	}
}

public void Classes_KillChaos(int client, int victim)
{
	if(Classes_GetByName("sci") == Client[victim].Class)
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
			Gamemode_GiveTicket(class.Group, 1);
	}
	else
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[victim].Class, class) && class.Group==2 && Classes_GetByIndex(Client[client].Class, class))
			Gamemode_GiveTicket(class.Group, 1);
	}
}

public void Classes_KillSci(int client, int victim)
{
	if( Classes_GetByName("dboi") == Client[victim].Class ||
		Classes_GetByName("dboi1") == Client[victim].Class ||
		Classes_GetByName("dboi2") == Client[victim].Class ||
		Classes_GetByName("dboi3") == Client[victim].Class ||
		Classes_GetByName("dboi4") == Client[victim].Class)
	{
		GiveAchievement(Achievement_KillDClass, client);
	}
}

public void Classes_KillMtf(int client, int victim)
{
	if ((Classes_GetByName("dboi") != Client[victim].Class) && !GetRandomInt(0, 3))
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[victim].Class, class) && class.Group==1 && Classes_GetByIndex(Client[client].Class, class))
			Gamemode_GiveTicket(class.Group, 1);
	}
}

public void Classes_KillSnake(int client, int victim)
{
    if ((Classes_GetByName("sci") != Client[victim].Class) && !GetRandomInt(0, 3))
    {
        ClassEnum class;
        if(Classes_GetByIndex(Client[victim].Class, class) && class.Group==2 && Classes_GetByIndex(Client[client].Class, class))
            Gamemode_GiveTicket(class.Group, 3);
    }
}

public Action Classes_TakeDamageHuman(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker<1 || attacker>MaxClients)
	{
		if(damagetype & DMG_CRUSH)
		{
			float engineTime = GetGameTime();
			static float delay[MAXTF2PLAYERS];
			if(delay[client] > engineTime)
				return Plugin_Handled;

			delay[client] = engineTime+0.05;
		}
		else if(damagetype & DMG_FALL)
		{
			damage *= 5.0;
			return Plugin_Changed;
		}

		if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffNoCritBlock))
		{
			int health = GetClientHealth(client);
			if(damage >= health)
				CreateTimer(0.5, Achievement_AdrenCheck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(!CvarFriendlyFire.BoolValue)
	{
		if(Client[client].Disarmer && Client[client].Disarmer!=attacker && IsFriendly(Client[Client[client].Disarmer].Class, Client[attacker].Class))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Classes_TakeDamageScp(int client, int attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!(damagetype & DMG_FALL))
		return Plugin_Continue;

	damage *= 0.02;
	return Plugin_Changed;
}

public void Classes_CondDBoi(int client, TFCond cond)
{
	if(cond == TFCond_TeleportedGlow)
	{
		float engineTime = GetGameTime();
		if(Client[client].IgnoreTeleFor < engineTime)
		{
			int index;
			ClassEnum class;
			if(Client[client].Disarmer)
			{
				Gamemode_AddValue("dcapture");
				index = Classes_GetByName("mtfs", class);

				// reward the disarmer with 15% karma
				Classes_ApplyKarmaBonus(Client[client].Disarmer, 15.0, false);
			}
			else
			{
				Gamemode_AddValue("descape");
				GiveAchievement(Achievement_EscapeDClass, client);
				index = Classes_GetByName("chaosd", class);

				if(Client[client].Extra2)
					GiveAchievement(Achievement_Escape207, client);

				if(RoundStartAt > engineTime-180.0)
					GiveAchievement(Achievement_EscapeSpeed, client);

				if(Items_GetItemsOfType(client, 5) > 1)
					GiveAchievement(Achievement_FindSCP, client);
			}

			if(index == -1)
			{
				index = 0;
				Classes_GetByIndex(0, class);
			}
			else
			{
				Gamemode_GiveTicket(class.Group, 1);
			}

			Items_DropAllItems(client);
			Forward_OnEscape(client, Client[client].Disarmer);

			if(Classes_AssignClass(client, ClassSpawn_Escape, index))
			{
				Client[client].Class = index;
				TF2_RespawnPlayer(client);
				Classes_AssignClassPost(client, ClassSpawn_Escape);
				CreateTimer(0.3, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public void Classes_CondSci(int client, TFCond cond)
{
	if(cond == TFCond_TeleportedGlow)
	{
		float engineTime = GetGameTime();
		if(Client[client].IgnoreTeleFor < engineTime)
		{
			int index;
			ClassEnum class;
			if(Client[client].Disarmer)
			{
				Gamemode_AddValue("scapture");
				index = Classes_GetByName("chaosd", class);

				// reward the disarmer with 15% karma
				Classes_ApplyKarmaBonus(Client[client].Disarmer, 15.0, false);				
			}
			else
			{
				Gamemode_AddValue("sescape");
				GiveAchievement(Achievement_EscapeSci, client);
				index = Classes_GetByName("mtfs", class);

				if(Client[client].Extra2)
					GiveAchievement(Achievement_Escape207, client);

				if(RoundStartAt > engineTime-180.0)
					GiveAchievement(Achievement_EscapeSpeed, client);
			}

			if(index == -1)
			{
				index = 0;
				Classes_GetByIndex(0, class);
			}
			else
			{
				Gamemode_GiveTicket(class.Group, Client[client].Disarmer ? 2 : 1);
			}

			Items_DropAllItems(client);
			Forward_OnEscape(client, Client[client].Disarmer);

			if(Classes_AssignClass(client, ClassSpawn_Escape, index))
			{
				Client[client].Class = index;
				TF2_RespawnPlayer(client);
				Classes_AssignClassPost(client, ClassSpawn_Escape);
				CreateTimer(0.3, CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public bool Classes_GlowHuman(int client, int victim)
{
	return Client[client].Disarmer==victim;
}

public bool Classes_SeeHuman(int client, int victim)
{
	return (victim<1 || victim>MaxClients || (IsFriendly(Client[client].Class, Client[victim].Class) || (!TF2_IsPlayerInCondition(victim, TFCond_Stealthed) && !TF2_IsPlayerInCondition(victim, TFCond_StealthedUserBuffFade))));
}

public bool Classes_PickupStandard(int client, int entity)
{
	if(Client[client].Disarmer)
		return false;

	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			// play animation if holding a keycard
			if (Items_IsHoldingKeycard(client))
				ViewModel_SetAnimation(client, "use");		
				
			TF2_RemoveCondition(client, TFCond_Stealthed);
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
	}
	else if(StrEqual(buffer, "prop_vehicle_driveable"))
	{
		Client[client].UseBuffer = true;
		return true;
	}
	else
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
		{
			if(StrEqual(buffer, "tf_dropped_weapon"))
			{
				if(Items_Pickup(client, GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"), entity))
				{
					AcceptEntityInput(entity, "Kill");
					TF2_RemoveCondition(client, TFCond_Stealthed);
				}
				return true;
			}
			else if(!StrContains(buffer, "prop_dynamic") || !StrContains(buffer, "prop_physics"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if(!StrContains(buffer, "scp_keycard_", false))	// Backwards compatibility
				{
					char buffers[3][4];
					ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
					if(Items_Pickup(client, StringToInt(buffers[2])+30000))
					{
						TF2_RemoveCondition(client, TFCond_Stealthed);
						AcceptEntityInput(entity, "KillHierarchy");
					}
					return true;
				}
				else if(!StrContains(buffer, "scp_healthkit", false))	// Backwards compatibility
				{
					char buffers[3][4];
					ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
					int value = StringToInt(buffers[2]);
					if(value > 3)
					{
						value = 30017;
					}
					else
					{
						value += 30012;
					}

					if(Items_Pickup(client, value))
					{
						TF2_RemoveCondition(client, TFCond_Stealthed);
						AcceptEntityInput(entity, "KillHierarchy");
					}
					return true;
				}
				else if(!StrContains(buffer, "scp_weapon", false))	// Backwards compatibility
				{
					char buffers[3][4];
					ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
					int index = StringToInt(buffers[2]);
					if(!index)
						index = 773;

					if(Items_Pickup(client, index))
					{
						TF2_RemoveCondition(client, TFCond_Stealthed);
						AcceptEntityInput(entity, "KillHierarchy");
					}
					return true;
				}
				else if(!StrContains(buffer, "scp_item_", false) || !StrContains(buffer, "scp_rand_", false))
				{
					AcceptEntityInput(entity, "FireUser1", client, client);

					char buffers[4][6];
					ExplodeString(buffer, "_", buffers, sizeof(buffers), sizeof(buffers[]));
					if(Items_Pickup(client, StringToInt(buffers[2])))
					{
						AcceptEntityInput(entity, "FireUser2", client, client);
						TF2_RemoveCondition(client, TFCond_Stealthed);
						AcceptEntityInput(entity, "KillHierarchy");
					}
					return true;
				}
				else if(!StrContains(buffer, "scp_trigger", false))
				{
					TF2_RemoveCondition(client, TFCond_Stealthed);
					switch(class.Group)
					{
						case 0:
						{
							if(Classes_GetByName("scp035") != Client[client].Class) AcceptEntityInput(entity, "FireUser1", client, client);
							else AcceptEntityInput(entity, "FireUser2", client, client);
						}
						case 1:
							AcceptEntityInput(entity, "FireUser2", client, client);

						case 2:
							AcceptEntityInput(entity, "FireUser3", client, client);

						default:
							AcceptEntityInput(entity, "FireUser4", client, client);
					}
					return true;
				}
				else
				{
					return SZF_Pickup(client, entity, buffer);
				}
			}
		}
	}
	return false;
}

public bool Classes_PickupScp(int client, int entity)
{
	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return false;

	char buffer[64];
	GetEntityClassname(entity, buffer, sizeof(buffer));
	if(StrEqual(buffer, "func_button"))
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(!StrContains(buffer, "scp_trigger", false))
		{
			AcceptEntityInput(entity, "Press", client, client);
			return true;
		}
	}
	else if(StrEqual(buffer, "prop_vehicle_driveable"))
	{
		Client[client].UseBuffer = true;
		return true;
	}
	else
	{
		ClassEnum class;
		if(Classes_GetByIndex(Client[client].Class, class))
		{
			if(!StrContains(buffer, "prop_dynamic"))
			{
				GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
				if(!StrContains(buffer, "scp_trigger", false))
				{
					switch(class.Group)
					{
						case 0:
						{
							if(Classes_GetByName("scp035") != Client[client].Class) AcceptEntityInput(entity, "FireUser1", client, client);
							else AcceptEntityInput(entity, "FireUser2", client, client);
						}
						case 1:
							AcceptEntityInput(entity, "FireUser2", client, client);

						case 2:
							AcceptEntityInput(entity, "FireUser3", client, client);

						default:
							AcceptEntityInput(entity, "FireUser4", client, client);
					}
					return true;
				}
			}
		}
	}
	return false;
}

public Action Classes_SoundHuman(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		if(IsSpec(client))
			return Plugin_Handled;

		level = RoundFloat(level / 1.2);
		return Plugin_Changed;
	}
	else if(StrContains(sample, "footsteps", false) != -1)
	{
		if(Client[client].Sprinting)
		{
			level += 20;
			volume *= 2.0;
			return Plugin_Changed;
		}

		int flag = GetEntityFlags(client);
		if((flag & FL_DUCKING) && (flag & FL_ONGROUND))
		{
			StopSound(client, SNDCHAN_AUTO, sample);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action Classes_SoundScp(int client, char sample[PLATFORM_MAX_PATH], int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!StrContains(sample, "vo", false))
	{
		if(!TF2_IsPlayerInCondition(client, TFCond_Disguised))
			return Plugin_Handled;
	}
	else if(StrContains(sample, "footsteps", false) != -1)
	{
		level += 20;
		volume *= 2.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public float Classes_SpeedHuman(int client, float &speed)
{
	if(Client[client].Extra2)
		speed *= 1.0+(Client[client].Extra2*0.125);
}

public float Classes_GhostTheme(int client, char path[PLATFORM_MAX_PATH])
{
	strcopy(path, PLATFORM_MAX_PATH, "#scp_sf/music/unexplainedbehaviors.mp3");
	return 49.0;
}

public float Classes_GhostThemeAlt(int client, char path[PLATFORM_MAX_PATH])
{
	if(TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		return Classes_GhostTheme(client, path);

	strcopy(path, PLATFORM_MAX_PATH, "#scp_containmentbreach/music/elevator.mp3");
	return 84.0;
}

public bool Classes_GhostDoors(int client, int entity)
{
	return false;
}

public bool Classes_DefaultVoice(int client)
{
	char buffer[8];
	GetCmdArgString(buffer, sizeof(buffer));
	if(StrContains(buffer, "0 0"))
		return false;

	Client[client].UseBuffer = true;
	return AttemptGrabItem(client);
}

public bool Classes_GhostVoice(int client)
{
	int attempts;
	int i = Client[client].Extra2+1;
	do
	{
		if(Client[client].Class!=Client[i].Class && IsValidClient(i) && !IsSpec(i))
		{
			static float pos[3], ang[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
			GetClientEyeAngles(i, ang);
			SetEntProp(client, Prop_Send, "m_bDucked", true);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
			TeleportEntity(client, pos, ang, TRIPLE_D);
			Client[client].Extra2 = i;
			break;
		}
		i++;
		attempts++;

		if(i > MaxClients)
			i = 1;
	} while(attempts < MAXTF2PLAYERS);
	return true;
}

public bool Classes_GhostVoiceAlt(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
	{
		char buffer[8];
		GetCmdArgString(buffer, sizeof(buffer));
		if(StrContains(buffer, "0 0"))
		{
			AttemptGrabItem(client);
			return false;
		}
	}

	int attempts;
	int i = Client[client].Extra2+1;
	do
	{
		if(Client[client].Class!=Client[i].Class && IsValidClient(i) && !IsSpec(i))
		{
			if(!TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
			{
				TF2_AddCondition(client, TFCond_HalloweenGhostMode);
				Client[client].NextSongAt = 0.0;

				int model = PrecacheModel(Client[client].IsVip ? "models/props_halloween/ghost.mdl" : "models/props_halloween/ghost_no_hat.mdl");
				SetVariantString(Client[client].IsVip ? "models/props_halloween/ghost.mdl" : "models/props_halloween/ghost_no_hat.mdl");
				AcceptEntityInput(client, "SetCustomModel");
				SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true);
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", model, _, 0);
				SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", model, _, 3);
			}

			static float pos[3], ang[3];
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
			GetClientEyeAngles(i, ang);
			SetEntProp(client, Prop_Send, "m_bDucked", true);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
			TeleportEntity(client, pos, ang, TRIPLE_D);
			Client[client].Extra2 = i;
			break;
		}
		i++;
		attempts++;

		if(i > MaxClients)
		{
			Client[client].Extra2 = 0;
			TF2_RespawnPlayer(client);
			Client[client].NextSongAt = 0.0;
			break;
		}
	} while(attempts < MAXTF2PLAYERS);
	return true;
}

public void Classes_ResetKillCounters(int client)
{
	Client[client].Kills = 0;
	Client[client].GoodKills = 0;
	Client[client].BadKills = 0;
}

public void Classes_ApplyKarmaDamage(int client, int damage)
{
	if (!AreClientCookiesCached(client))
		return;
	
	float karma, oldkarma;

	karma = Classes_GetKarma(client);
	// karma is a ratio to damage done vs the max health of the client
	int maxhealth = Classes_GetMaxHealth(client);
	oldkarma = karma;
	float loss = CvarKarmaRatio.FloatValue * (float(damage) / float(maxhealth));
	karma -= loss;
	
	float MinKarma = CvarKarmaMin.FloatValue;
	if (karma < MinKarma)
		karma = MinKarma;

	if (karma != oldkarma)
		Classes_SetKarma(client, karma);
}

public void Classes_ApplyKarmaBonus(int client, float amount, bool silent)
{
	if (!AreClientCookiesCached(client))
		return;
	
	float karma, oldkarma;
	
	karma = Classes_GetKarma(client);

	oldkarma = karma;
	karma += amount;
	
	float MaxKarma = CvarKarmaMax.FloatValue;
	if (karma > MaxKarma)
		karma = MaxKarma;

	Classes_SetKarma(client, karma);

	if (!silent && CvarKarma.BoolValue && (karma != oldkarma))
	{
		BfWrite bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
		if(bf)
		{
			char buffer[64];
			FormatEx(buffer, sizeof(buffer), "%T", "goodkarma", client);
			bf.WriteString(buffer);
			bf.WriteString("voice_self");
			bf.WriteByte(0);
			EndMessage();
		}		
	}
}

public float Classes_GetKarma(int client)
{
	if (!AreClientCookiesCached(client))
		return CvarKarmaMax.FloatValue;
	
	float karma;
	
	char value[64];
	GetClientCookie(client, CookieKarma, value, sizeof(value));
	if (!value[0])
	{
		// no karma value saved yet, initialize to max
		karma = CvarKarmaMax.FloatValue;
		FloatToString(karma, value, sizeof(value));
		SetClientCookie(client, CookieKarma, value);
	}
	else
	{
		karma = StringToFloat(value);
	}
	
	return karma;
}

public void Classes_SetKarma(int client, float karma)
{
	if (!AreClientCookiesCached(client))
		return;
	
	char value[64];
	FloatToString(karma, value, sizeof(value));
	SetClientCookie(client, CookieKarma, value);
}