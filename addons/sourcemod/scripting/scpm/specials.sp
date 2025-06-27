#pragma semicolon 1
#pragma newdecls required

enum struct SpecialInfo
{
	char Prefix[32];
	Handle Subplugin;

	float Delay;

	void SetupKv(KeyValues kv, int index)
	{
		kv.GetSectionName(this.Prefix, sizeof(this.Prefix));
		this.Subplugin = INVALID_HANDLE;

		this.Delay = kv.GetFloat("delay", 300.0);

		if(kv.JumpToKey("downloads"))
		{
			if(kv.GotoFirstSubKey(false))
			{
				char buffer[PLATFORM_MAX_PATH];

				do
				{
					kv.GetSectionName(buffer, sizeof(buffer));

					if(FileExists(buffer, true))
					{
						AddFileToDownloadsTable(buffer);
					}
					else
					{
						LogError("[Config] Missing file '%s' for '%s'", buffer, this.Prefix);
					}
				}
				while(kv.GotoNextKey(false));

				kv.GoBack();
			}

			kv.GoBack();
		}

		if(StartCustomFunction(this.Subplugin, this.Prefix, "Precache"))
		{
			Call_PushCell(index);
			Call_PushArrayEx(this, sizeof(this), SM_PARAM_COPYBACK);
			Call_Finish();
		}
	}
}

static ArrayList SpecialList;
static Handle EventTimer;
static int SpecialActive = -1;
static int LastActive = -1;

void Specials_SetupConfig(KeyValues map)
{
	delete SpecialList;
	SpecialList = new ArrayList(sizeof(SpecialInfo));
	
	KeyValues kv;

	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Specials"))
			kv = map;
	}

	if(!kv)
	{
		char buffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "specials");
		kv = new KeyValues("Specials");
		kv.ImportFromFile(buffer);
	}

	SpecialInfo special;
	int index;

	if(kv.GotoFirstSubKey())
	{
		do
		{
			special.SetupKv(kv, index);
			index = SpecialList.PushArray(special) + 1;
		}
		while(kv.GotoNextKey());

		kv.GoBack();
	}

	if(kv != map)
		delete kv;
}

void Specials_MapEnd()
{
	Specials_RoundEnd();
}

void Specials_PickNewRound()
{
	Specials_RoundEnd();
	
	int choosen = SpecialList.Length;
	if(choosen < 2)
		return;
	
	choosen = GetURandomInt() % (choosen - 1);
	if(choosen >= LastActive)
		choosen++;
	
	SpecialActive = choosen;
	LastActive = choosen;

	SpecialInfo special;
	SpecialList.GetArray(SpecialActive, special);
	if(special.Delay > 0.0)
		special.Delay *= GetRandomFloat(0.9, 1.1);

	if(StartCustomFunction(special.Subplugin, special.Prefix, "Setup"))
	{
		Call_PushFloatRef(special.Delay);
		Call_Finish();
	}

	if(special.Delay > 0.0)
		EventTimer = CreateTimer(special.Delay, StartSpecialEvent);
}

static Action StartSpecialEvent(Handle timer)
{
	EventTimer = null;

	if(SpecialActive != -1)
	{
		if(Specials_StartFunction(SpecialActive, "Event"))
		{
			Call_Finish();
		}
	}

	return Plugin_Continue;
}

void Specials_RoundEnd()
{
	delete EventTimer;

	if(SpecialActive != -1)
	{
		if(Specials_StartFunction(SpecialActive, "End"))
		{
			Call_Finish();
		}

		SpecialActive = -1;
	}
}

bool Specials_StartFunction(int index, const char[] name)
{
	static SpecialInfo special;
	SpecialList.GetArray(index, special);
	return StartCustomFunction(special.Subplugin, special.Prefix, name);
}