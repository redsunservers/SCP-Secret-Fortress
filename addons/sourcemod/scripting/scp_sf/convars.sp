#pragma semicolon 1
#pragma newdecls required

enum struct CvarInfo
{
	ConVar cvar;
	char value[16];
	char defaul[16];
	bool enforce;
}

static ArrayList CvarList;
static bool CvarHooked;

void ConVar_PluginStart()
{
	Cvar[Version] = CreateConVar("scp_version", PLUGIN_VERSION_FULL, "SCP: Secret Fortress Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Cvar[Achievements] = CreateConVar("scp_achievements", "1", "If to call SCPSF_OnAchievement forward", _, true, 0.0, true, 1.0);
	Cvar[ChatHook] = CreateConVar("scp_chathook", "1", "If SCP runs internal chat processor to manage chat messages", _, true, 0.0, true, 1.0);
	Cvar[VoiceHook] = CreateConVar("scp_voicehook", "1", "If SCP runs internal voice processor to manage voice chat", _, true, 0.0, true, 1.0);
	Cvar[SendProxy]= CreateConVar("scp_sendproxy", "1", "If to use SendProxy, if available", _, true, 0.0, true, 1.0);
	Cvar[DropItemLimit] = CreateConVar("scp_droppedweaponcount", "-1", "How many dropped weapon to allow in map, -1 for no limit", _, true, -1.0);

	AutoExecConfig(false, "SCPSecretFortress");
	
	CvarList = new ArrayList(sizeof(CvarInfo));
	
	FindConVar("mp_bonusroundtime").SetBounds(ConVarBound_Upper, true, 20.0);
	
	ConVar_Add("mp_bonusroundtime", "20.0", false);
	ConVar_Add("mp_disable_respawn_times", "1.0");
	ConVar_Add("mp_waitingforplayers_time", "70.0", false);
	ConVar_Add("tf_bot_join_after_player", "0.0", false);
	ConVar_Add("tf_dropped_weapon_lifetime", "99999.0");
	ConVar_Add("tf_helpme_range", "-1.0");
	ConVar_Add("tf_spawn_glows_duration", "0.0");
}

void ConVar_ConfigsExecuted()
{
	bool generate = !FileExists("cfg/sourcemod/SCPSecretFortress.cfg");
	
	if(!generate)
	{
		char buffer[512];
		Cvar[Version].GetString(buffer, sizeof(buffer));
		if(!StrEqual(buffer, PLUGIN_VERSION_FULL))
		{
			if(buffer[0])
				generate = true;
			
			Cvar[Version].SetString(PLUGIN_VERSION_FULL);
		}
	}
	
	if(generate)
		GenerateConfig();
	
	ConVar_Enable();
}

static void GenerateConfig()
{
	File file = OpenFile("cfg/sourcemod/SCPSecretFortress.cfg", "wt");
	if(file)
	{
		file.WriteLine("// Settings present are for SCP: Secret Fortress (" ... PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION ... ")");
		file.WriteLine("// Updating the plugin version will generate new cvars and any non-SCP commands will be lost");
		file.WriteLine("scp_version \"" ... PLUGIN_VERSION_FULL ... "\"");
		file.WriteLine(NULL_STRING);
		
		char buffer1[512], buffer2[256];
		for(int i; i < Cvar_MAX; i++)
		{
			if(Cvar[i].Flags & FCVAR_DONTRECORD)
				continue;
			
			Cvar[i].GetDescription(buffer1, sizeof(buffer1));
			
			int current, split;
			do
			{
				split = SplitString(buffer1[current], "\n", buffer2, sizeof(buffer2));
				if(split == -1)
				{
					file.WriteLine("// %s", buffer1[current]);
					break;
				}
				
				file.WriteLine("// %s", buffer2);
				current += split;
			}
			while(split != -1);
			
			file.WriteLine("// -");
			
			Cvar[i].GetDefault(buffer2, sizeof(buffer2));
			file.WriteLine("// Default: \"%s\"", buffer2);
			
			float value;
			if(Cvar[i].GetBounds(ConVarBound_Lower, value))
				file.WriteLine("// Minimum: \"%.2f\"", value);
			
			if(Cvar[i].GetBounds(ConVarBound_Upper, value))
				file.WriteLine("// Maximum: \"%.2f\"", value);
			
			Cvar[i].GetName(buffer2, sizeof(buffer2));
			Cvar[i].GetString(buffer1, sizeof(buffer1));
			file.WriteLine("%s \"%s\"", buffer2, buffer1);
			file.WriteLine(NULL_STRING);
		}
		
		delete file;
	}
}

static void ConVar_Add(const char[] name, const char[] value, bool enforce = true)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	strcopy(info.value, sizeof(info.value), value);
	info.enforce = enforce;

	if(CvarHooked)
	{
		info.cvar.GetString(info.defaul, sizeof(info.defaul));

		bool setValue = true;
		if(!info.enforce)
		{
			char buffer[sizeof(info.defaul)];
			info.cvar.GetDefault(buffer, sizeof(buffer));
			if(!StrEqual(buffer, info.defaul))
				setValue = false;
		}

		if(setValue)
			info.cvar.SetString(info.value);
		
		info.cvar.AddChangeHook(ConVar_OnChanged);
	}

	CvarList.PushArray(info);
}

public void ConVar_OnlyChangeOnEmpty(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			cvar.SetString(oldValue);
			break;
		}
	}
}

stock void ConVar_Remove(const char[] name)
{
	ConVar cvar = FindConVar(name);
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);
		CvarList.Erase(index);

		if(CvarHooked)
		{
			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
		}
	}
}

void ConVar_Enable()
{
	if(!CvarHooked)
	{
		int length = CvarList.Length;
		for(int i; i < length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);
			info.cvar.GetString(info.defaul, sizeof(info.defaul));
			CvarList.SetArray(i, info);

			bool setValue = true;
			if(!info.enforce)
			{
				char buffer[sizeof(info.defaul)];
				info.cvar.GetDefault(buffer, sizeof(buffer));
				if(!StrEqual(buffer, info.defaul))
					setValue = false;
			}

			if(setValue)
				info.cvar.SetString(info.value);
			
			info.cvar.AddChangeHook(ConVar_OnChanged);
		}

		CvarHooked = true;
	}
}

void ConVar_Disable()
{
	if(CvarHooked)
	{
		int length = CvarList.Length;
		for(int i; i < length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);

			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
		}

		CvarHooked = false;
	}
}

public void ConVar_OnChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);

		if(!StrEqual(info.value, newValue))
		{
			strcopy(info.defaul, sizeof(info.defaul), newValue);
			CvarList.SetArray(index, info);

			if(info.enforce)
				info.cvar.SetString(info.value);
		}
	}
}
