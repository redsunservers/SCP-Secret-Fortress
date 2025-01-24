#pragma semicolon 1
#pragma newdecls required

static GlobalForward OnAchievement;
static GlobalForward OnClass;
static GlobalForward OnClassPre;
static GlobalForward OnEscape;
static GlobalForward OnReactionPre;
static GlobalForward OnUpdateListenOverrides;
static GlobalForward OnWeapon;
static GlobalForward OnWeaponPre;

void Forward_Setup()
{
	OnAchievement = new GlobalForward("SCPSF_OnAchievement", ET_Ignore, Param_Cell, Param_Cell);
	OnClass = new GlobalForward("SCPSF_OnClass", ET_Ignore, Param_Cell, Param_String, Param_Cell);
	OnClassPre = new GlobalForward("SCPSF_OnClassPre", ET_Event, Param_Cell, Param_String, Param_Cell);
	OnEscape = new GlobalForward("SCPSF_OnEscape", ET_Ignore, Param_Cell, Param_Cell);
	OnReactionPre = new GlobalForward("SCPSF_OnReactionPre", ET_Event, Param_Cell, Param_String, Param_String);
	OnUpdateListenOverrides = new GlobalForward("SCPSF_OnUpdateListenOverrides", ET_Ignore, Param_Cell, Param_Cell);
	OnWeapon = new GlobalForward("SCPSF_OnWeapon", ET_Ignore, Param_Cell, Param_Cell);
	OnWeaponPre = new GlobalForward("SCPSF_OnWeaponPre", ET_Event, Param_Cell, Param_Cell, Param_CellByRef);
}

void Forward_OnAchievement(int client, Achievements achievement)
{
	Call_StartForward(OnAchievement);
	Call_PushCell(client);
	Call_PushCell(achievement);
	Call_Finish();
}

void Forward_OnClass(int client, ClassSpawnEnum context, const char[] class)
{
	Call_StartForward(OnClass);
	Call_PushCell(client);
	Call_PushString(class);
	Call_PushCell(context);
	Call_Finish();
}

Action Forward_OnClassPre(int client, ClassSpawnEnum context, char[] class, int length)
{
	Action action;
	Call_StartForward(OnClassPre);
	Call_PushCell(client);
	Call_PushStringEx(class, length, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(context);
	Call_Finish(action);
	return action;
}

void Forward_OnEscape(int client, int disarmer)
{
	Call_StartForward(OnEscape);
	Call_PushCell(client);
	Call_PushCell(disarmer);
	Call_Finish();
}

Action Forward_OnReactionPre(int client, const char[] event, char sound[PLATFORM_MAX_PATH])
{
	Action action;
	Call_StartForward(OnReactionPre);
	Call_PushCell(client);
	Call_PushString(event);
	Call_PushStringEx(sound, PLATFORM_MAX_PATH, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	return action;
}

void Forward_OnWeapon(int client, int entity)
{
	Call_StartForward(OnWeapon);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_Finish();
}

Action Forward_OnWeaponPre(int client, int entity, int &index)
{
	Action action;
	Call_StartForward(OnWeaponPre);
	Call_PushCell(client);
	Call_PushCell(entity);
	Call_PushCellRef(index);
	Call_Finish(action);
	return action;
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

Action Forward_OnUpdateListenOverrides(int listener, int talker)
{
	Action action;
	Call_StartForward(OnUpdateListenOverrides);
	Call_PushCell(listener);
	Call_PushCell(talker);
	Call_Finish(action);
	return action;
}