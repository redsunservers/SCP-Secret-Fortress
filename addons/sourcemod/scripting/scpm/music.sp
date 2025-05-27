#pragma semicolon 1
#pragma newdecls required

/*
	The Garage - Danger
	Distant Piano - Unsafe
	Ghost Theme 1 - Unsafe
	Ghost Theme 2 - Unsafe
	Ghost Theme 3 - Safe
	Haunted Graveyard - Danger
	Ghost Theme 4 - Unsafe
	Ghost Theme 5 - Safe
	Ghost Theme 6 - Unsafe
	Antechamber - Danger
	Ghost Theme 7 - Danger
	Ghost Theme 8 - Unsafe
	Ghost Theme 10 - Safe
	Ghost Theme 12 - Unsafe
	Ghost Theme 13 - Unsafe
	Ghost Theme 14 - Danger
	Ghost Theme 15 - Safe

	Grouchy Possessor Appears - Chase
*/

enum
{
	Music_Safe = 0,
	Music_Unsafe = 1,
	Music_Danger = 2
}

static const char MusicType[][] =
{
	"Safe",
	"Unsafe",
	"Danger"
};

enum struct MusicInfo
{
	int Type;

	char Filepath[PLATFORM_MAX_PATH];
	float Time;
	float Volume;

	bool SetupKv(KeyValues kv)
	{
		kv.GetSectionName(this.Filepath, sizeof(this.Filepath));
		if(!this.Filepath[0])
			return false;
		
		if(this.Filepath[0] != '#')
			Format(this.Filepath, sizeof(this.Filepath), "#%s", this.Filepath);

		PrecacheSound(this.Filepath);
		this.Time = kv.GetFloat("time");
		this.Volume = kv.GetFloat("volume", 1.0);

		if(kv.GetNum("download"))
		{
			char buffer[PLATFORM_MAX_PATH];
			FormatEx(buffer, sizeof(buffer), "sound/%s", this.Filepath);
			ReplaceString(buffer, sizeof(buffer), "#", "");
			if(!FileExists(buffer, true))
			{
				LogError("[Config] Missing file '%s' for music", buffer);
				return false;
			}

			AddFileToDownloadsTable(buffer);
		}

		return true;
	}
}

static ArrayList MusicList;
static bool RoundDisabled;
static DataPack CurrentTheme[MAXPLAYERS+1];
static int LastTheme[MAXPLAYERS+1] = {-1, ...};
static float MusicEndAt[MAXPLAYERS+1];
static bool MusicInfinite[MAXPLAYERS+1];
static Handle MusicTimer[MAXPLAYERS+1];

void Music_SetupConfig(KeyValues map)
{
	delete MusicList;
	MusicList = new ArrayList(sizeof(MusicInfo));

	KeyValues kv;

	if(map)
	{
		map.Rewind();
		if(map.JumpToKey("Music"))
			kv = map;
	}

	if(!kv)
	{
		char buffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "music");
		kv = new KeyValues("Music");
		kv.ImportFromFile(buffer);
	}

	MusicInfo music;

	for(int i; i < sizeof(MusicType); i++)
	{
		if(kv.JumpToKey(MusicType[i]))
		{
			if(kv.GotoFirstSubKey())
			{
				music.Type = i;
				
				do
				{
					if(music.SetupKv(kv))
						MusicList.PushArray(music);
				}
				while(kv.GotoNextKey());

				kv.GoBack();
			}

			kv.GoBack();
		}
	}

	if(kv != map)
		delete kv;
}

void Music_ClientDisconnect(int client)
{
	LastTheme[client] = -1;
	delete CurrentTheme[client];
	delete MusicTimer[client];
}

void Music_ToggleRoundMusic(bool enable)
{
	RoundDisabled = !enable;
}

// Victim is the human, attacker is the boss
void Music_StartChase(int victim, int attacker, bool force = false)
{
	float gameTime = GetGameTime();
	bool newTheme = force || (Client(victim).LastDangerAt < (gameTime - 90.0)) || (MusicEndAt[victim] < gameTime);
	Client(victim).LastDangerAt = gameTime;

	if(newTheme && !RoundDisabled)
	{
		bool infinite;
		float time;
		char buffer[PLATFORM_MAX_PATH];
		if(Bosses_StartFunctionClient(attacker, "ChaseTheme"))
		{
			Call_PushCell(attacker);
			Call_PushStringEx(buffer, sizeof(buffer), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(victim);
			Call_PushCellRef(infinite);
			Call_Finish(time);
		}

		if(buffer[0])
		{
			Music_ToggleMusic(victim, false, true);

			EmitSoundToClient(victim, buffer, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
			LastTheme[victim] = -1;

			delete CurrentTheme[victim];
			CurrentTheme[victim] = new DataPack();
			CurrentTheme[victim].WriteString(buffer);
			CurrentTheme[victim].WriteFloat(time);

			if(infinite && time > 0.0)
				MusicInfinite[victim] = true;

			if(!MusicTimer[victim] && time > 0.0)
				MusicTimer[victim] = CreateTimer(time + (MusicInfinite[victim] ? 0.0 : 20.0), MusicNextTimer, victim);
			
			if(infinite || time <= 0.0)
				time = 999.9;
			
			MusicEndAt[victim] = gameTime + time;
		}
		else
		{
			Music_ToggleMusic(victim, true, true);
		}
	}
}

void Music_ToggleMusic(int client, bool startNew = true, bool stopExisting = false)
{
	if(stopExisting)
	{
		delete MusicTimer[client];
		MusicInfinite[client] = false;

		if(CurrentTheme[client])
		{
			char buffer[PLATFORM_MAX_PATH];
			CurrentTheme[client].Reset();
			CurrentTheme[client].ReadString(buffer, sizeof(buffer));
			StopSound(client, SNDCHAN_STATIC, buffer);

			delete CurrentTheme[client];
		}
	}

	if(startNew && !RoundDisabled && !MusicTimer[client] && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		if(MusicInfinite[client])
		{
			if(CurrentTheme[client])
			{
				char buffer[PLATFORM_MAX_PATH];
				CurrentTheme[client].Reset();
				CurrentTheme[client].ReadString(buffer, sizeof(buffer));
				float time = CurrentTheme[client].ReadFloat();
				EmitSoundToClient(client, buffer, _, SNDCHAN_STATIC, SNDLEVEL_NONE);

				if(time > 0.0)
					MusicTimer[client] = CreateTimer(time, MusicNextTimer, client);

				return;
			}

			MusicInfinite[client] = false;
		}

		float stress = Human_GetStressPercent(client);
		bool marked = TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath);

		int type;
		if(marked || stress > 80.0 || Client(client).LastDangerAt || Client(client).KeycardExit > 1)
		{
			if(marked/* || Client(client).LastDangerAt > (GetGameTime() - 90.0)*/ && !Client(client).Escaped)
			{
				type = 2;
			}
			else
			{
				type = 1;
			}
		}

		// Bug: Plays danger first then unsafe as SCP?

		if(stress < 40.0)
			stress = 40.0;

		float intensity = (stress / 100.0) + (type * 0.2);
		if(intensity > 1.0)
			intensity = 1.0;
		
		ArrayList list = new ArrayList();

		MusicInfo music;
		int length = MusicList.Length;
		for(int i; i < length; i++)
		{
			MusicList.GetArray(i, music);
			if(music.Type != type)
				continue;
			
			// Reuse the same track if we're still on same type
			if(LastTheme[client] == i)
			{
				list.Clear();
				list.Push(i);
				break;
			}

			list.Push(i);
		}
		
		length = list.Length;
		if(length)
		{
			int index = list.Get(GetURandomInt() % length);
			MusicList.GetArray(index, music);
			
			EmitSoundToClient(client, music.Filepath, _, SNDCHAN_STATIC, SNDLEVEL_NONE, _, music.Volume * intensity);
			LastTheme[client] = index;
			
			delete CurrentTheme[client];
			CurrentTheme[client] = new DataPack();
			CurrentTheme[client].WriteString(music.Filepath);
			CurrentTheme[client].WriteFloat(music.Time);

			if(intensity > 0.0 && music.Time > 0.0)
				MusicTimer[client] = CreateTimer(music.Time / GetRandomFloat(intensity, 1.0), MusicNextTimer, client);
			
			if(music.Time <= 0.0)
				music.Time = 999.9;
			
			MusicEndAt[client] = GetGameTime() + music.Time;

		}
		else
		{
			MusicTimer[client] = CreateTimer(10.0 / intensity, MusicNextTimer, client);
		}

		delete list;
	}
}

static Action MusicNextTimer(Handle timer, int client)
{
	MusicTimer[client] = null;
	delete CurrentTheme[client];

	Music_ToggleMusic(client);
	return Plugin_Continue;
}
