#pragma semicolon 1
#pragma newdecls required

void Configs_ConfigsExecuted()
{
	KeyValues kv;
	
	char mapname[64], buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, buffer, sizeof(buffer), FOLDER_CONFIGS ... "/maps");

	DirectoryListing dir = OpenDirectory(buffer);
	if(dir)
	{
		FileType file;
		char filename[64];
		while(dir.GetNext(filename, sizeof(filename), file))
		{
			if(file != FileType_File)
				continue;

			if(SplitString(filename, ".cfg", filename, sizeof(filename)) == -1)
				continue;
			
			if(StrContains(mapname, filename) != 0)
				continue;

			kv = new KeyValues("Map");
			Format(buffer, sizeof(buffer), "%s/%s.cfg", buffer, filename);
			if(!kv.ImportFromFile(buffer))
				LogError("[Config] Found '%s' but was unable to read", buffer);

			break;
		}

		delete dir;
	}
	else
	{
		LogError("[Config] Directory '%s' does not exist", buffer);
	}
	
	ArrayList classes = Gamemode_ConfigSetupPre(kv);
	
	Items_ConfigSetup(kv);
	Classes_ConfigSetup(kv, classes);
	Music_ConfigSetup(kv);

	Gamemode_ConfigSetupPost(kv);

	delete kv;
}