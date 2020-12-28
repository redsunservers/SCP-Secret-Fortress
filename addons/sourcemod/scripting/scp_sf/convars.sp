enum struct CvarInfo
{
	ConVar cvar;
	float value;
	float defaul;
}

static ArrayList CvarList;

ConVar CvarQuickRounds;
ConVar CvarSpecGhost;
ConVar CvarFriendlyFire;
ConVar CvarDiscFF;
ConVar CvarTimelimit;
ConVar CvarSpeedMulti;
ConVar CvarSpeedMax;
ConVar CvarAchievement;
ConVar CvarWinStyle;
ConVar CvarChatHook;

void ConVar_Setup()
{
	CvarQuickRounds = CreateConVar("scp_quickrounds", "1", "If to end the round if winning outcome can no longer be changed", _, true, 0.0, true, 1.0);
	CvarSpecGhost = CreateConVar("scp_specmode", "1", "If to spawn as a ghost while spectating", _, true, 0.0, true, 1.0);
	CvarFriendlyFire = CreateConVar("scp_friendlyfire", "0", "If to enable friendly fire", _, true, 0.0, true, 1.0);
	CvarDiscFF = CreateConVar("scp_discff", "0", "DISC-FF.com private features", _, true, 0.0, true, 1.0);
	CvarTimelimit = CreateConVar("scp_timelimit", "898", "Round timelimit (0 to disable)", _, true, 120.0);
	CvarSpeedMulti = CreateConVar("scp_speedmulti", "1.0", "Player movement speed multiplier", _, true, 0.004167);
	CvarSpeedMax = CreateConVar("scp_speedmax", "3000.0", "Maximum player speed (SCP-173's blink speed)", _, true, 1.0);
	CvarAchievement = CreateConVar("scp_achievements", "1", "If to call SCPSF_OnAchievement forward", _, true, 0.0, true, 1.0);
	CvarWinStyle = CreateConVar("scp_winstyle", "1", "If winner will be determined with the amount of escaped players", _, true, 0.0, true, 1.0);
	CvarChatHook = CreateConVar("scp_chathook", "1", "If to use it's own chat processor to manage chat and voice messages", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "SCPSecretFortress");

	CvarChatHook.AddChangeHook(ConVar_OnChatHook);

	if(CvarList != INVALID_HANDLE)
		delete CvarList;

	CvarList = new ArrayList(sizeof(CvarInfo));
	
	ConVar_Add("mp_autoteambalance", 0.0);
	ConVar_Add("mp_disable_respawn_times", 1.0);
	ConVar_Add("mp_forcecamera", 0.0);
	ConVar_Add("mp_friendlyfire", 1.0);
	ConVar_Add("mp_teams_unbalance_limit", 0.0);
	ConVar_Add("mp_waitingforplayers_time", 70.0);
	ConVar_Add("tf_bot_join_after_player", 0.0);
	ConVar_Add("tf_dropped_weapon_lifetime", 99999.0);
	ConVar_Add("tf_ghost_xy_speed", 400.0);
	ConVar_Add("tf_helpme_range", -1.0);
	ConVar_Add("tf_spawn_glows_duration", 0.0);
	ConVar_Add("tf_weapon_criticals_distance_falloff", 0.0);
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