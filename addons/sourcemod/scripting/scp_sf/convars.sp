enum struct CvarInfo
{
	ConVar cvar;
	float value;
	float defaul;
	bool enforce;
}

static ArrayList CvarList;
static bool CvarEnabled;

void ConVar_Setup()
{
	CvarFriendlyFire = CreateConVar("scp_friendlyfire", "0", "If to enable friendly fire", _, true, 0.0, true, 1.0);
	CvarSpeedMulti = CreateConVar("scp_speedmulti", "1.0", "Player movement speed multiplier", _, true, 0.004167);
	CvarSpeedMax = CreateConVar("scp_speedmax", "3000.0", "Maximum player speed (SCP-173's blink speed)", _, true, 1.0);
	CvarAchievement = CreateConVar("scp_achievements", "1", "If to call SCPSF_OnAchievement forward", _, true, 0.0, true, 1.0);
	CvarChatHook = CreateConVar("scp_chathook", "1", "If to use it's own chat processor to manage chat messages", _, true, 0.0, true, 1.0);
	CvarVoiceHook = CreateConVar("scp_voicehook", "1", "If to use it's own voice processor to manage voice chat", _, true, 0.0, true, 1.0);
	CvarSendProxy = CreateConVar("scp_sendproxy", "1", "If to use SendProxy, if available", _, true, 0.0, true, 1.0);
	CvarKarma = CreateConVar("scp_karma", "1", "If to use karma level for player damage", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "SCPSecretFortress");

	CvarChatHook.AddChangeHook(ConVar_OnChatHook);
	CvarVoiceHook.AddChangeHook(ConVar_OnVoiceHook);

	FindConVar("mp_bonusroundtime").SetBounds(ConVarBound_Upper, true, 20.0);

	if(CvarList != INVALID_HANDLE)
		delete CvarList;

	CvarList = new ArrayList(sizeof(CvarInfo));

	ConVar_Add("mp_autoteambalance", 0.0);
	ConVar_Add("mp_bonusroundtime", 20.0, false);
	ConVar_Add("mp_disable_respawn_times", 1.0);
	ConVar_Add("mp_forcecamera", 0.0, false);
	ConVar_Add("mp_friendlyfire", 1.0);
	ConVar_Add("mp_teams_unbalance_limit", 0.0);
	ConVar_Add("mp_scrambleteams_auto", 0.0);
	ConVar_Add("mp_waitingforplayers_time", 70.0);
	ConVar_Add("tf_bot_join_after_player", 0.0, false);
	ConVar_Add("tf_dropped_weapon_lifetime", 99999.0);
	ConVar_Add("tf_ghost_xy_speed", 400.0, false);
	ConVar_Add("tf_helpme_range", -1.0);
	ConVar_Add("tf_spawn_glows_duration", 0.0);
	ConVar_Add("tf_weapon_criticals_distance_falloff", 1.0);
}

void ConVar_Add(const char[] name, float value, bool enforce=true)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	info.value = value;
	info.enforce = enforce;

	if(CvarEnabled)
	{
		info.defaul = info.cvar.FloatValue;
		info.cvar.SetFloat(info.value);
		info.cvar.AddChangeHook(ConVar_OnChanged);
	}

	CvarList.PushArray(info);
}

void ConVar_Remove(const char[] name)
{
	ConVar cvar = FindConVar(name);
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarInfo info;
		CvarList.GetArray(index, info);
		CvarList.Erase(index);

		if(CvarEnabled)
		{
			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetFloat(info.defaul);
		}
	}
}

void ConVar_Enable()
{
	if(!CvarEnabled)
	{
		if(Classes_AskForClass())
		{
			ConVar_Add("mp_forceautoteam", 1.0);
		}
		else
		{
			ConVar_Remove("mp_forceautoteam");
		}

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

		CvarEnabled = true;
	}
}

void ConVar_Disable()
{
	if(CvarEnabled)
	{
		int length = CvarList.Length;
		for(int i; i<length; i++)
		{
			CvarInfo info;
			CvarList.GetArray(i, info);

			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetFloat(info.defaul);
		}

		CvarEnabled = false;
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
		{
			if(info.enforce)
			{
				info.defaul = value;
				CvarList.SetArray(index, info);
				info.cvar.SetFloat(info.value);
			}
			else
			{
				info.cvar.RemoveChangeHook(ConVar_OnChanged);
				CvarList.Erase(index);
			}
		}
	}
}

public void ConVar_OnChatHook(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(ChatHook)
	{
		if(!cvar.BoolValue)
		{
			ChatHook = false;
			RemoveCommandListener(OnSayCommand, "say");
			RemoveCommandListener(OnSayCommand, "say_team");
		}
	}
	else if(cvar.BoolValue)
	{
		ChatHook = true;
		AddCommandListener(OnSayCommand, "say");
		AddCommandListener(OnSayCommand, "say_team");
	}
}

public void ConVar_OnVoiceHook(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(!cvar.BoolValue && StringToFloat(oldValue))
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client, false))
				continue;

			for(int target=1; target<=MaxClients; target++)
			{
				if(client==target || IsValidClient(target))
					SetListenOverride(client, target, Listen_Default);
			}
		}
	}
}