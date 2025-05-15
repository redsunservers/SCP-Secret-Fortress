#pragma semicolon 1
#pragma newdecls required

static Handle SDKGetAttribute;
static Handle SDKGetCustomAttribute;

void VScript_PluginStart()
{
	if(VScript_IsScriptVMInitialized())
		VScript_OnScriptVMInitialized();
}

public void VScript_OnScriptVMInitialized()
{
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