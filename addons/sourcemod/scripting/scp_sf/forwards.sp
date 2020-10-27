static GlobalForward OnEscape;
static GlobalForward OnAchievement;

void Forward_Setup()
{
	OnEscape = new GlobalForward("SCPSF_OnEscape", ET_Ignore, Param_Cell, Param_Cell);
	OnAchievement = new GlobalForward("SCPSF_OnAchievement", ET_Ignore, Param_Cell, Param_Cell);
}

void Forward_OnEscape(int client, int disarmer)
{
	Call_StartForward(OnEscape);
	Call_PushCell(client);
	Call_PushCell(disarmer);
	Call_Finish();
}

void Forward_OnAchievement(int client, Achievements achievement)
{
	Call_StartForward(OnAchievement);
	Call_PushCell(client);
	Call_PushCell(achievement);
	Call_Finish();
}

void Forward_OnMessage(int client, char[] name, int nameL, char[] msg, int msgL)
{
	Handle iter = GetPluginIterator();
	while(MorePlugins(iter))
	{
		Handle plugin = ReadPlugin(iter);
		Function func = GetFunctionByName(plugin, "SCPSF_OnChatMessage");
		if(func == INVALID_FUNCTION)
			continue;

		Call_StartFunction(plugin, func);
		Call_PushCell(client);
		Call_PushStringEx(name, nameL, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushStringEx(msg, msgL, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_Finish();
	}
	delete iter;
}