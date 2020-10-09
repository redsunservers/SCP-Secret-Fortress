void Native_Setup()
{
	CreateNative("SCPSF_GetClientClass", Native_GetClientClass);
	CreateNative("SCPSF_IsSCP", Native_IsSCP);
}

public any Native_GetClientClass(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>=0 && client<MAXTF2PLAYERS)
		return 0;

	int length = GetNativeCell(3);
	char[] buffer = new char[length];
	strcopy(buffer, length, ClassShort[Client[client].Class]);

	int bytes;
	SetNativeString(2, buffer, length, _, bytes);
	return bytes;
}

public any Native_IsSCP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client>=0 && client<MAXTF2PLAYERS)
		return IsSCP(client);

	return false;
}