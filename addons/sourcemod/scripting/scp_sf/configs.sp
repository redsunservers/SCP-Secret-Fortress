enum
{
	Music_Join = 0,
	Music_Join2,
	Music_Time,
	Music_Outside,
	Music_Alone,
	Music_Light,
	Music_Heavy,
	Music_Spec,

	Sound_MTFSpawn = 0,
	Sound_ChaosSpawn
}

static const char MusicList[][] =
{
	"#scp_sf/music/finalflashofexistence.mp3",
	"#scp_sf/music/retromenu.mp3",
	"#scp_sf/music/wegottarun.mp3",
	"#scp_sf/music/melancholy.mp3",
	"#scp_sf/music/massivelabyrinth.mp3",
	"#scp_sf/music/lczambient.mp3",
	"#scp_sf/music/doctorlab.mp3",
	"#scp_sf/music/unexplainedbehaviors.mp3"
};

static const float MusicTimes[] =
{
	215.0,	// Final Flash of Existence
	128.0,	// Retro Menu
	112.0,	// We Gotta Run
	92.0,	// Melancholy
	124.5,	// Massive Labyrnith
	55.0,	// LCZ Ambient
	93.0,	// Doctor Lab
	49.0	// Unexplained Behaviors
};

static const char SoundList[][] =
{
	"scp_sf/events/spawn_mtf.mp3",			// MTF Spawn
	"scp_sf/events/spawn_chaos.mp3"			// Chaos Spawn
};

static const char TFClassNames[][] =
{
	"mercenary",
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"heavy",
	"pyro",
	"spy",
	"engineer"
};

#define SOUNDPICKUP	"items/pumpkin_pickup.wav"

static KeyValues Reactions;

void Config_Setup()
{
	for(int i; i<sizeof(MusicList); i++)
	{
		PrecacheSoundEx(MusicList[i], true);
	}

	for(int i; i<sizeof(SoundList); i++)
	{
		PrecacheSoundEx(SoundList[i], true);
	}

	ClassModelIndex[0] = PrecacheModel(ClassModel[0], true);
	for(int i=1; i<sizeof(ClassModel); i++)
	{
		ClassModelIndex[i] = PrecacheModelEx(ClassModel[i], true);
	}

	for(int i; i<sizeof(ClassModelSub); i++)
	{
		ClassModelSubIndex[i] = PrecacheModel(ClassModelSub[i], true);
	}

	PrecacheModel(RADIO_MODEL, true);
	PrecacheModelEx(KEYCARD_MODEL, true);
	VIPGhostModel = PrecacheModel(VIP_GHOST_MODEL, true);

	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), CFG_REACTIONS);
	Reactions = new KeyValues("SCPReactions");
	Reactions.ImportFromFile(buffer);
}

float Config_GetMusic(int index, char[] buffer, int length)
{
	if(index >= sizeof(MusicList))
		return 0.0;

	strcopy(buffer, length, MusicList[index]);
	return MusicTimes[index];
}

int Config_GetSound(int index, char[] buffer, int length)
{
	if(index >= sizeof(SoundList))
		return 0;

	return strcopy(buffer, length, SoundList[index]);
}

void Config_DoReaction(int client, const char[] name)
{
	Reactions.Rewind();
	if(Reactions.JumpToKey(name))
	{
		if(Reactions.JumpToKey(TFClassNames[TF2_GetPlayerClass(client)]))
		{
			static char buffer[PLATFORM_MAX_PATH];
			int amount;
			do
			{
				IntToString(++amount, buffer, sizeof(buffer));
				Reactions.GetString(buffer, buffer, sizeof(buffer));
			} while(buffer[0]);

			if(amount > 1)
			{
				IntToString(GetRandomInt(1, amount-1), buffer, sizeof(buffer));
				Reactions.GetString(buffer, buffer, sizeof(buffer));
				EmitSoundToAll(buffer, client, SNDCHAN_VOICE, 95);
			}
		}
	}
}