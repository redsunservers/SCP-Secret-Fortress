#pragma semicolon 1
#pragma newdecls required

void Native_PluginLoad()
{
	CreateNative("SCPM_CanTalkTo", CanTalkTo);

	RegPluginLibrary("scpm");
}

static any CanTalkTo(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 0 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d (argument 1)", client);

	int target = GetNativeCell(2);
	if(target < 0 || target > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d (argument 2)", target);

	return Client(client).CanTalkTo(target);
}
