#pragma semicolon 1
#pragma newdecls required

static bool Initialized;
static Handle SDKGetAttribute;
static Handle SDKGetCustomAttribute;

void VScript_AllPluginsLoaded()
{
	if(VScript_IsScriptVMInitialized())
		VScript_OnScriptVMInitialized();
}

public void VScript_OnScriptVMInitialized()
{
	if(Initialized)
		return;
	
	Initialized = true;

	VScriptFunction func = VScript_GetClassFunction("CEconEntity", "GetAttribute");
	if(func)
	{
		SDKGetAttribute = func.CreateSDKCall();
		if(!SDKGetAttribute)
			LogError("[VScript] Could not call CEconEntity::GetAttribute");
	}
	else
	{
		LogError("[VScript] Could not find CEconEntity::GetAttribute");
	}

	func = VScript_GetClassFunction("CTFPlayer", "GetCustomAttribute");
	if(func)
	{
		SDKGetCustomAttribute = func.CreateSDKCall();
		if(!SDKGetCustomAttribute)
			LogError("[VScript] Could not call CTFPlayer::GetCustomAttribute");
	}
	else
	{
		LogError("[VScript] Could not find CTFPlayer::GetCustomAttribute");
	}

	VScript_CreateClass("SCPM");

	func = VScript_CreateClassFunction("SCPM", "GetAccessLevel");
	func.SetParam(1, FIELD_HSCRIPT);
	func.SetParam(2, FIELD_INTEGER);
	func.Return = FIELD_INTEGER;
	func.SetFunctionEmpty();
	func.Register();
	func.CreateDetour().Enable(Hook_Pre, VScript_AccessLevel);
}

bool VScript_GetAttribute(int entity, const char[] name, float &value)
{
	if(SDKGetAttribute && SDKGetCustomAttribute)
	{
		value = SDKCall(entity > MaxClients ? SDKGetAttribute : SDKGetCustomAttribute, entity, name, value);
		return true;
	}

	return false;
}

static MRESReturn VScript_AccessLevel(Address address, DHookReturn ret, DHookParam param)
{
	int client = param.Get(1);
	int level = param.Get(2);

	if(client > 0 && client <= MaxClients)
	{
		switch(level)
		{
			case 0:
				ret.Value = Client(client).KeycardContain;
			
			case 1:
				ret.Value = Client(client).KeycardArmory;
			
			case 2:
				ret.Value = Client(client).KeycardExit;
			
			default:
				ret.Value = 0;
		}
	}
	else
	{
		ret.Value = 0;
	}
	
	PrintToChatAll("GetAccessLevel::%d:%d", client, level);
	return MRES_Supercede;
}
