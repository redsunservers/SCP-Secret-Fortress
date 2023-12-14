#pragma semicolon 1
#pragma newdecls required

#define DYNAMIC_COUNT	5
#define DYNAMIC_HUMAN	"scp_sf/music/dynamic_human/%d.mp3"
#define DYNAMIC_SCP		"scp_sf/music/dynamic_scp/%d.mp3"

static int GetMusicTime(int index, bool scp)
{
	if(scp)
		return index == 0 ? 6 : 8;
	
	return index == 4 ? 6 : 7;
}

static bool MusicEnabled;
static bool MusicTempDisable;
static char CurrentTheme[MAXPLAYERS+1][PLATFORM_MAX_PATH];
static int NextThemeAt[MAXPLAYERS+1] = {-1, ...};

void Music_ConfigSetup(KeyValues map)
{
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), FOLDER_CONFIGS ... "/gamemode.cfg");

	KeyValues kv = new KeyValues("Gamemode");
	kv.ImportFromFile(buffer);

	MusicEnabled = !kv.GetNum("nomusic");

	if(map)
		MusicEnabled = !map.GetNum("nomusic", MusicEnabled ? 0 : 1);
	
	delete kv;

	if(MusicEnabled)
	{
		int entity = -1;
		while((entity=FindEntityByClassname(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
			if(!StrEqual(buffer, "scp_nomusic", false))
				continue;

			MusicEnabled = false;
			break;
		}
	}
	
	if(MusicEnabled)
	{
		int table = FindStringTable("downloadables");
		bool save = LockStringTables(false);

		for(int i = 1; i <= DYNAMIC_COUNT; i++)
		{
			FormatEx(buffer, sizeof(buffer), "sound/" ... DYNAMIC_HUMAN, i);
			if(FileExists(buffer, true))
			{
				AddToStringTable(table, buffer);

				FormatEx(buffer, sizeof(buffer), "#" ... DYNAMIC_HUMAN, i);
				PrecacheSound(buffer);
			}
			else
			{
				MusicEnabled = false;
				LogError("[Config] Gamemode has missing file '%s'", buffer);
			}
			
			FormatEx(buffer, sizeof(buffer), "sound/" ... DYNAMIC_SCP, i);
			if(FileExists(buffer, true))
			{
				AddToStringTable(table, buffer);

				FormatEx(buffer, sizeof(buffer), "#" ... DYNAMIC_SCP, i);
				PrecacheSound(buffer);
			}
			else
			{
				MusicEnabled = false;
				LogError("[Config] Gamemode has missing file '%s'", buffer);
			}
		}

		LockStringTables(save);
	}
}

void Music_ClientDisconnect(int client)
{
	CurrentTheme[client][0] = 0;
	NextThemeAt[client] = -1;
}

void Music_PlayerSpawn(int client)
{
	if(NextThemeAt[client] == -1)
		NextThemeAt[client] = 0;
}

void Music_PlayerDeath(int client)
{
	Music_StopMusic(client);
}

void Music_RoundRespawn()
{
	MusicTempDisable = false;
}

void Music_RoundEnd()
{
	MusicTempDisable = true;

	for(int client = 1; client <= MaxClients; client++)
	{
		Music_StopMusic(client);
	}
}

void Music_PlayerRunCmd(int client)
{
	if(MusicEnabled && !MusicTempDisable && NextThemeAt[client] != -1 && NextThemeAt[client] < GetTime())
	{
		if(!IsPlayerAlive(client))
		{
			NextThemeAt[client] = -1;
			return;
		}

		bool alone = false;
		int safe, danger;
		float pos1[3], pos2[3];
		GetClientEyePosition(client, pos1);
		int team1 = GetClientTeam(client);
		bool isSCP = team1 <= TFTeam_Spectator;

		for(int target = 1; target <= MaxClients; target++)
		{
			if(client != target && IsClientInGame(target) && IsPlayerAlive(target) && Classes_Transmit(client, target))
			{
				int team2 = GetClientTeam(target);

				if(isSCP && team1 == team2)
				{
					// SCPs feel safe when others are alive
					safe++;
					continue;
				}

				GetClientEyePosition(target, pos2);

				// Close teammates makes us feel safe
				// Close enemies makes us feel danger

				float distance = GetVectorDistance(pos1, pos2, true);
				if(distance < 62500)	// 250 HU
				{
					alone = false;

					if(team1 == team2)
					{
						safe += 2;
					}
					else if(isSCP || team2 <= TFTeam_Spectator)
					{
						danger += 4;
					}
				}
				else if(distance < 202500)	// 450 HU
				{
					alone = false;

					if(team1 == team2)
					{
						safe += 2;
					}
					else if(isSCP || team2 <= TFTeam_Spectator)
					{
						danger += 3;
					}
				}
				else if(distance < 490000)	// 700 HU
				{
					alone = false;

					if(team1 == team2)
					{
						safe++;
					}
					else if(isSCP || team2 <= TFTeam_Spectator)
					{
						danger += 2;
					}
				}
				else if(distance < 1000000)	// 1000 HU
				{
					alone = false;

					if(isSCP || team2 <= TFTeam_Spectator)
						danger++;
				}
			}
		}

		// Being alone gives danger
		if(alone)
			danger++;
		
		// Danger vs Safeness
		int score = danger - safe;

		// Minimum of 2 danger regardless of safety
		if(danger > 2)
			danger = 2;
		
		if(score < danger)
			score = danger;
		
		// Cap
		if(score > DYNAMIC_COUNT)
			score = DYNAMIC_COUNT;

		int length;
		char buffer[PLATFORM_MAX_PATH];
		if(score < 1)
		{
			// No track, still gives a delay
			length = GetMusicTime(6, false);
		}
		else if(isSCP)
		{
			// SCP theme
			length = GetMusicTime(score - 1, true);
			FormatEx(buffer, sizeof(buffer), "#" ... DYNAMIC_SCP, score);
		}
		else
		{
			// Human theme
			length = GetMusicTime(score - 1, false);
			FormatEx(buffer, sizeof(buffer), "#" ... DYNAMIC_HUMAN, score);
		}

		// Overrides
		Classes_PlayMusic(client, buffer, length);

		if(length < -1)
			length = -1;
		
		NextThemeAt[client] = length;

		if(buffer[0])
		{
			EmitSoundToClient(client, buffer, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
			strcopy(CurrentTheme[client], sizeof(CurrentTheme[]), buffer);
		}
	}
}

void Music_SetMusicStatus(bool enable)
{
	MusicTempDisable = !enable;
}

void Music_StopMusic(int client)
{
	if(CurrentTheme[client][0])
	{
		StopSound(client, SNDCHAN_STATIC, CurrentTheme[client]);
		CurrentTheme[client][0] = 0;
	}

	NextThemeAt[client] = -1;
}
