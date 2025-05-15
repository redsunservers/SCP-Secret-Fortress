#pragma semicolon 1
#pragma newdecls required

void Configs_ConfigsExecuted()
{
	char buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));
	GetMapDisplayName(buffer, buffer, sizeof(buffer));
	KeyValues map = Configs_GetMapKv(buffer);

	Bosses_SetupConfig(map);
	Human_SetupConfig(map);
	Items_SetupConfig(map);
	Weapons_SetupConfig(map);

	delete map;
}

KeyValues Configs_GetMapKv(const char[] mapname)
{
	char buffer[PLATFORM_MAX_PATH];
	KeyValues kv;
	
	BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG ... "/maps");
	DirectoryListing dir = OpenDirectory(buffer);
	if(dir != INVALID_HANDLE)
	{
		FileType file;
		char filename[68];
		while(dir.GetNext(filename, sizeof(filename), file))
		{
			if(file != FileType_File)
				continue;

			if(SplitString(filename, ".cfg", filename, sizeof(filename)) == -1)
				continue;
				
			if(StrContains(mapname, filename))
				continue;

			kv = new KeyValues("Map");
			Format(buffer, sizeof(buffer), "%s/%s.cfg", buffer, filename);
			if(!kv.ImportFromFile(buffer))
				LogError("[Config] Found '%s' but was unable to read", buffer);

			break;
		}
		delete dir;
	}

	return kv;
}