enum struct CvarInfo
{
	ConVar cvar;
	float value;
	float defaul;
}

static ArrayList CvarList;

void ConVar_Setup()
{
	CvarQuickRounds = CreateConVar("scp_quickrounds", "1", "If to end the round if winning outcome can no longer be changed", _, true, 0.0, true, 1.0);

	if(CvarList != INVALID_HANDLE)
		delete CvarList;

	CvarList = new ArrayList(sizeof(CvarInfo));
	
	ConVar_Add("mp_autoteambalance", 0.0);
	ConVar_Add("mp_teams_unbalance_limit", 0.0);
	ConVar_Add("mp_forcecamera", 0.0);
	ConVar_Add("mp_friendlyfire", 1.0);
	ConVar_Add("mp_disable_respawn_times", 1.0);
	ConVar_Add("tf_weapon_criticals_distance_falloff", 0.0);
	ConVar_Add("tf_dropped_weapon_lifetime", 99999.0);
	ConVar_Add("tf_helpme_range", -1.0);
	ConVar_Add("tf_ghost_xy_speed", 400.0);
	ConVar_Add("tf_spawn_glows_duration", 0.0);
}

static void ConVar_Add(const char[] name, float value)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	info.value = value;
	CvarList.PushArray(info);
}

void ConVar_Enable()
{
	int length = CvarList.Length;
	for(int i; i<length; i++)
	{
		CvarInfo info;
		CvarList.GetArray(i, info);
		info.defaul = info.cvar.FloatValue;
		CvarList.SetArray(i, info);
		
		info.cvar.SetFloat(info.value);
		info.cvar.AddChangeHook(ConVar_OnChanged);
	}
}

void ConVar_Disable()
{
	int length = CvarList.Length;
	for(int i; i<length; i++)
	{
		CvarInfo info;
		CvarList.GetArray(i, info);
		
		info.cvar.RemoveChangeHook(ConVar_OnChanged);
		info.cvar.SetFloat(info.defaul);
	}
}

public void ConVar_OnChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);
		float value = StringToFloat(newValue);
		if(value != info.value)
			info.cvar.SetFloat(info.value);
	}
}