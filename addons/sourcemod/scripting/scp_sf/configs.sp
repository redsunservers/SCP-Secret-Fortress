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

	Sound_096 = 0,
	Sound_Screams,
	Sound_Snap,
	Sound_MTFSpawn,
	Sound_ChaosSpawn,

	Sound_ItSteps,
	Sound_ItRages,
	Sound_ItHadEnough,
	Sound_ItStuns,
	Sound_ItKills,

	Sound_MTFSpawnSpooky
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
	115.0,	// We Gotta Run
	92.0,	// Melancholy
	124.5,	// Massive Labyrnith
	55.0,	// LCZ Ambient
	93.0,	// Doctor Lab
	49.0	// Unexplained Behaviors
};

static const char SoundList[][] =
{
	"freak_fortress_2/scp096/bgm.mp3",		// SCP-096 Passive
	"freak_fortress_2/scp096/fullrage.mp3",		// SCP-096 Rage
	"freak_fortress_2/scp173/scp173_kill2.mp3",	// SCP-173 Kill
	"scp_sf/events/spawn_mtf.mp3",			// MTF Spawn
	"freak_fortress_2/scp-049/red_backup.mp3",	// Chaos Spawn

	"scpsl/it_steals/monster_step.wav",	// Stealer Step Noise
	"scpsl/it_steals/enraged.mp3",		// Stealer First Rage
	"scpsl/it_steals/youhadyourchance.mp3",	// Stealer Second Rage
	"scpsl/it_steals/stunned.mp3",		// Stealer Stunned
	"scpsl/it_steals/deathcam.mp3",		// Player Killed

	"scp_sf/events/spawn_mtf_halloween.mp3"		// Spooky MTF Spawn
};

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

	PrecacheModelEx(KEYCARD_MODEL, true);
	VIPGhostModel = PrecacheModelEx(VIP_GHOST_MODEL, true);
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