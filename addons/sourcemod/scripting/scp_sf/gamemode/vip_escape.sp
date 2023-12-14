#pragma semicolon 1
#pragma newdecls required

enum
{
	List_Red = 0,
	List_Blu,
	List_SCP,
	List_MAX
}

static const char ListName[List_MAX][] =
{
	"Red",
	"Blue",
	"SCPs"
};

static bool Enabled;
static float SCPRatio;
static ArrayList StartClasses[List_MAX];
static ArrayList RespawnClasses[List_MAX];

public void VIPEscape_OnConfigSetup(KeyValues kv)
{
	for(int i; i < List_MAX; i++)
	{
		delete StartClasses[i];
		delete RespawnClasses[i];
	}

	Enabled = true;

	SCPRatio = kv.GetFloat("humanstoscps", 8.0);

	char buffer[32];

	if(kv.JumpToKey("Setup"))
	{
		for(int i; i < List_MAX; i++)
		{
			if(kv.JumpToKey(ListName[i]))
			{
				if(kv.GotoFirstSubKey(false))
				{
					StartClasses[i] = new ArrayList();

					do
					{
						kv.GetSectionName(buffer, sizeof(buffer));

						int index = Classes_GetByName(buffer);
						if(index != -1)
							StartClasses[i].Push(index);
					}
					while(kv.GotoNextKey(false));

					kv.GoBack();
				}

				kv.GoBack();
			}
		}

		kv.GoBack();
	}

	if(kv.JumpToKey("Respawn"))
	{
		for(int i; i < List_MAX; i++)
		{
			if(kv.JumpToKey(ListName[i]))
			{
				if(kv.GotoFirstSubKey(false))
				{
					RespawnClasses[i] = new ArrayList();

					do
					{
						kv.GetSectionName(buffer, sizeof(buffer));

						int index = Classes_GetByName(buffer);
						if(index != -1)
							RespawnClasses[i].Push(index);
					}
					while(kv.GotoNextKey(false));

					kv.GoBack();
				}

				kv.GoBack();
			}
		}

		kv.GoBack();
	}
}

public void VIPEscape_OnRoundRespawn()
{
	ArrayList players = new ArrayList();

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) > 1)
		{
			players.Push(client);
		}
	}

	int length = players.Length;
	if(!length)
		return;
	
	players.Sort(Sort_Random, Sort_Integer);

	ArrayList classes = StartClasses[List_SCP].Clone();
	int count = SCPRatio ? RoundToCeil(float(length - 3) / SCPRatio) : 1;
	while(count > 0 && classes.Length && players.Length)
	{
		int client = players.Get(0);
		
		int arrayIndex = GetURandomInt() % classes.Length;
		int classIndex = classes.Get(arrayIndex);
		
		Classes_SetClientClass(client, classIndex, ClassSpawn_RoundStart);
		players.Erase(0);
		classes.Erase(arrayIndex);
		count--;
	}

	delete classes;

	for(int a = List_Red; a <= List_Blu; a++)
	{
		classes = StartClasses[a].Clone();

		length = classes.Length;
		int remove = -(3 - length);

		for(int b; b < remove; b++)
		{
			length = classes.Length;
			classes.Erase(GetURandomInt() % length);
		}

		count = players.Length;
		for(int b; b < length; b++)
		{
			int client = players.Get(b);
			if(GetClientTeam(client) == (a + 2))
			{
				int classIndex = classes.Get(GetURandomInt() % length);

				Classes_SetClientClass(client, classIndex, ClassSpawn_RoundStart);
			}
		}

		delete classes;
	}
}

public void VIPEscape_OnMapEnd()
{
	Enabled = false;
}