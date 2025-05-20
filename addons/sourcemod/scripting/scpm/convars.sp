#pragma semicolon 1
#pragma newdecls required

#define CVAR_VERSION	"0.1"

enum struct CvarInfo
{
	ConVar Cvar;
	char Name[32];
	char Value[64];
	char Defaul[64];
	bool Enforce;
}

static ArrayList CvarList;
static bool CvarHooked;

void ConVar_PluginStart()
{
	Cvar[Version] = CreateConVar("scp_version", CVAR_VERSION, "SCP Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Cvar[SCPCount] = CreateConVar("scp_game_bosses", "8", "How many players for every boss spawn", _, true, 1.0);
	
	AutoExecConfig(false, "SCPM");
	
	Cvar[AllowSpectators] = FindConVar("mp_allowspectators");
	Cvar[Gravity] = FindConVar("sv_gravity");
	
	CvarList = new ArrayList(sizeof(CvarInfo));

	ConVar_Add("randomizer_class", "");//"trigger=@!boss group=@me action=round");
	ConVar_Add("randomizer_weapons", "");//"trigger=@!boss group=@me action=round count-primary=0 count-secondary=0 count-melee=1");
	ConVar_Add("randomizer_cosmetics", "");
	ConVar_Add("randomizer_droppedweapons", "1");
	ConVar_Add("randomizer_enabled", "1");
	
	ConVar_Add("mat_supportflashlight", "1");
	ConVar_Add("mp_autoteambalance", "0");
	ConVar_Add("mp_bonusroundtime", "20.0", false);
	ConVar_Add("mp_disable_respawn_times", "1");
	ConVar_Add("mp_flashlight", "1");
	ConVar_Add("mp_forcecamera", "0", false);
	ConVar_Add("mp_humans_must_join_team", "any");
	ConVar_Add("mp_teams_unbalance_limit", "0");
	ConVar_Add("mp_stalemate_enable", "0");
	ConVar_Add("mp_scrambleteams_auto", "0");
	ConVar_Add("mp_waitingforplayers_time", "90.0", false);
	ConVar_Add("tf_allow_player_use", "1");
	ConVar_Add("tf_dropped_weapon_lifetime", "900.0");
	ConVar_Add("tf_helpme_range", "-1.0");
	ConVar_Add("tf_spawn_glows_duration", "0.0");
}

void ConVar_ConfigsExecuted()
{
	bool generate = !FileExists("cfg/sourcemod/SCPM.cfg");
	
	if(!generate)
	{
		char buffer[512];
		Cvar[Version].GetString(buffer, sizeof(buffer));
		if(!StrEqual(buffer, CVAR_VERSION))
		{
			if(buffer[0])
				generate = true;
			
			Cvar[Version].SetString(CVAR_VERSION);
		}
	}
	
	if(generate)
		GenerateConfig();
	
	ConVar_Enable();
}

static void GenerateConfig()
{
	File file = OpenFile("cfg/sourcemod/SCPM.cfg", "wt");
	if(file)
	{
		file.WriteLine("// Settings present are for SCP: Mercenaries (" ... CVAR_VERSION ... ")");
		file.WriteLine("// Updating the plugin version will generate new cvars and any non-SCP commands will be lost");
		file.WriteLine("scp_version \"" ... CVAR_VERSION ... "\"");
		file.WriteLine(NULL_STRING);
		
		char buffer1[512], buffer2[256];
		for(int i; i < AllowSpectators; i++)
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
	strcopy(info.Name, sizeof(info.Name), name);
	strcopy(info.Value, sizeof(info.Value), value);
	info.Enforce = enforce;
	CvarList.PushArray(info);
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
			
			if(!info.Cvar)
			{
				info.Cvar = FindConVar(info.Name);
				if(!info.Cvar)
				{
					CvarList.Erase(i);
					i--;
					length--;
					continue;
					//SetFailState("Could not find convar '%s'", info.Name);
				}
			}

			info.Cvar.GetString(info.Defaul, sizeof(info.Defaul));
			CvarList.SetArray(i, info);

			bool setValue = true;
			if(!info.Enforce)
			{
				char buffer[sizeof(info.Defaul)];
				info.Cvar.GetDefault(buffer, sizeof(buffer));
				if(!StrEqual(buffer, info.Defaul))
					setValue = false;
			}

			if(setValue)
				info.Cvar.SetString(info.Value);
			
			info.Cvar.AddChangeHook(ConVar_OnChanged);
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

			info.Cvar.RemoveChangeHook(ConVar_OnChanged);
			info.Cvar.SetString(info.Defaul);
		}

		CvarHooked = false;
	}
}

static void ConVar_OnChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	int index = CvarList.FindValue(cvar, CvarInfo::Cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);

		if(!StrEqual(info.Value, newValue))
		{
			strcopy(info.Defaul, sizeof(info.Defaul), newValue);
			CvarList.SetArray(index, info);

			if(info.Enforce)
				info.Cvar.SetString(info.Value);
		}
	}
}
