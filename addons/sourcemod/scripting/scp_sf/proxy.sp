#pragma semicolon 1
#pragma newdecls required

#define PROXY_UPDATE_RATE	20	// Frames between updating speaking ranges

static const char TeamColors[][] =
{
	"gray",
	"gray",
	"red",
	"blue"
};

static int NextRangeUpdate;

Action Proxy_ClientSayCommand(int client)
{
	float gameTime = GetGameTime();
	if(client && Cvar[ChatHook].BoolValue)
	{
		#if defined _sourcecomms_included
		if(SourceComms && SourceComms_GetClientGagType(client) > bNot)
			return Plugin_Handled;
		#endif

		#if defined _basecomm_included
		if(BaseComm && BaseComm_IsClientGagged(client))
			return Plugin_Handled;
		#endif

		if((Client(client).LastChatAt + 0.75) > gameTime)
			return Plugin_Handled;

		char message[256];
		GetCmdArgString(message, sizeof(message));
		if(StrContains(message, "/") < 2 || StrContains(message, "@") < 2)
			return Plugin_Handled;
		
		CRemoveTags(message, sizeof(message));
		ReplaceString(message, sizeof(message), "\"", "'");
		ReplaceString(message, sizeof(message), "\n", "");

		if(strlen(message) == 0)
			return Plugin_Handled;
		
		char name[128];
		GetClientName(client, name, sizeof(name));
		CRemoveTags(name, sizeof(name));

		Forwards_OnMessagePre(client, name, sizeof(name), message, sizeof(message));
		int team = Proxy_GetDisplayTeam(client);

		for(int target = 1; target <= MaxClients; target++)
		{
			if(client == target || (IsClientInGame(target) && Client(client).CanTalkTo(target)))
			{
				char prefix[16];
				Proxy_GetChatTag(client, target, prefix, sizeof(prefix));
				if(prefix[0])
					StrCat(prefix, sizeof(prefix), " ");

				CPrintToChat(target, "%s{%s}%s {default}: %s", prefix, TeamColors[team], name, message);
			}
		}
	}

	Client(client).LastChatAt = gameTime;
	return Plugin_Continue;
}

void Proxy_ClientSpeaking(int client)
{
	Client(client).LastVoiceAt = FAR_FUTURE;
}

void Proxy_ClientSpeakingEnd(int client)
{
	Client(client).LastVoiceAt = GetGameTime();
}

void Proxy_GameFrame()
{
	if(--NextRangeUpdate < 0)
		Proxy_UpdateChatRules();
}

void Proxy_EntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "tf_player_manager"))
	{
		SDKHook(entity, SDKHook_ThinkPost, PlayerManagerThink);
	}
}

int Proxy_GetDisplayTeam(int client)
{
	int team = GetClientTeam(client);
	if(team <= TFTeam_Spectator && IsPlayerAlive(client))
	{
		// Fake team for SCPs
		team = Client(client).ProxyTeam;
	}

	return team;
}

int Proxy_GetChatTag(int client, int target, char[] buffer, int length)
{
	bool alive = IsPlayerAlive(client);
	int team = GetClientTeam(client);

	if(team <= TFTeam_Spectator && !alive)
	{
		// Player is in spectator
		return Format(buffer, length, "%T", "Spec Prefix", target);
	}
	else if(!IsActiveRound())
	{
		// No tags outside rounds
	}
	else if(Client(client).GlobalChatFor > GetGameTime())
	{
		return Format(buffer, length, "%T", "Intercom Prefix", target);
	}
	else if(!alive || Classes_IsDeadClass(client))
	{
		// Player is dead/ghost
		return Format(buffer, length, "%T", "Dead Prefix", target);
	}
	else if(IsPlayerAlive(target) && !Classes_IsDeadClass(target))
	{
		// Target is alive/non-ghost
		
		if(team <= TFTeam_Spectator && team == GetClientTeam(target))
		{
			// SCPs share their classes
			ClassEnum class;
			if(Classes_GetByIndex(Client(client).Class, class))
				return Format(buffer, length, "(%T)", class.Display, target);
		}
		else if(Client(client).CanTalkTo(target) > 1)
		{
			// Far away and using a radio
			return Format(buffer, length, "%T", "Radio Prefix", target);
		}
	}

	buffer[0] = 0;
	return 0;
}

void Proxy_UpdateChatRules()
{
	NextRangeUpdate = PROXY_UPDATE_RATE;

	bool voiceManger = GetFeatureStatus(FeatureType_Native, "OnPlayerAdjustVolume") == FeatureStatus_Available;

	if(IsActiveRound())
	{
		bool[] valid = new bool[MaxClients+1];
		int[] team = new int[MaxClients+1];
		bool[] alive = new bool[MaxClients+1];
		bool[] ghost = new bool[MaxClients+1];
		bool[] admin = new bool[MaxClients+1];
		static float pos[MAXPLAYERS+1][3];

		for(int client = 1; client <= MaxClients; client++)
		{
			valid[client] = IsClientInGame(client);
			if(valid[client])
			{
				team[client] = GetClientTeam(client);
				alive[client] = IsPlayerAlive(client);
				ghost[client] = Classes_IsDeadClass(client);
				admin[client] = CheckCommandAccess(client, "sm_mute", ADMFLAG_CHAT);
				GetClientEyePosition(client, pos[client]);
			}
		}

		float gameTime = GetGameTime();
		for(int client = 1; client <= MaxClients; client++)
		{
			if(valid[client])
			{
				for(int target = 1; target <= MaxClients; target++)
				{
					if(client != target && valid[target])
					{
						bool result = true;
						float distance = -1.0;
						float range, defaultRange;

						if(IsClientMuted(target, client))
						{
							// Target muted the client
							result = false;
						}
						else
						{
							if(Client(client).GlobalChatFor > gameTime ||
								(admin[client] && team[client] <= TFTeam_Spectator && !alive[client]) ||
								(team[target] <= TFTeam_Spectator && !alive[target]))
							{
								// Intercom player can talk to all
								// Admin spectator can talk to all
								// Spectators can hear all
								result = true;
							}
							else if(team[client] <= TFTeam_Spectator && !alive[client])
							{
								// Spectator can talk to other spectators
								result = (team[target] <= TFTeam_Spectator && !alive[target]);
							}
							else if(!alive[client])
							{
								// Dead can't talk
								result = false;
							}
							else
							{
								// Start taking distance to account
								distance = GetVectorDistance(pos[client], pos[target], true);

								Classes_CanTalkTo(client, target, range, defaultRange);
								
								range *= range;
								defaultRange *= defaultRange;

								if(distance > range)
								{
									// Too far away
									result = false;
								}
								else if(ghost[client])
								{
									// Ghost classes can talk to other ghost classes
									result = ghost[target];
								}
								else
								{
									// Alive classes can talk to others
									result = true;
								}
							}
						}

						if(voiceManger)
						{
							// TODO: VoiceManager alterative for proper scaling volume
							if(result && distance > 0.0 && distance <= defaultRange)
							{
								float ratio = distance / defaultRange;

								int volume = VoiceManager_Loud;
								if(ratio > 0.5625)
								{
									// 75% - 100%
									volume = VoiceManager_Quieter;
								}
								else if(ratio > 0.25)
								{
									// 50% - 75%
									volume = VoiceManager_Quiet;
								}
								else if(ratio > 0.0625)
								{
									// 25% - 50%
									volume = VoiceManager_Normal;
								}

								OnPlayerAdjustVolume(target, client, volume);
							}
							else
							{
								OnPlayerAdjustVolume(target, client, VoiceManager_Normal);
							}
						}

						Client(client).SetTalkTo(target, result ? (distance > defaultRange ? 2 : 1) : 0);
						SetListenOverride(target, client, result ? Listen_Default : Listen_No);
					}
				}
			}
		}
	}
	else
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				for(int target = 1; target <= MaxClients; target++)
				{
					// Self, invalid, replay, TV, not muted
					bool valid = IsClientInGame(target);
					bool result = (!valid || client == target || IsClientReplay(target) || IsClientSourceTV(target) || !IsClientMuted(target, client));

					if(voiceManger && valid)
						OnPlayerAdjustVolume(target, client, VoiceManager_Normal);

					Client(client).SetTalkTo(target, 0);
					
					if(valid)
						SetListenOverride(target, client, result ? Listen_Default : Listen_No);
				}
			}
		}
	}
}

static void PlayerManagerThink(int entity)
{
	if(IsActiveRound())
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				SetEntProp(entity, Prop_Send, "m_bAlive", true, _, client);
				SetEntProp(entity, Prop_Send, "m_iTeam", Proxy_GetDisplayTeam(client), _, client);
				SetEntProp(entity, Prop_Send, "m_iPlayerClass", TFClass_Unknown, _, client);
				SetEntProp(entity, Prop_Send, "m_iPlayerClassWhenKilled", TFClass_Unknown, _, client);
			}
		}
	}
}

static bool IsActiveRound()
{
	if(FindEntityByClassname(-1, "tf_gamerules") != -1 && !GameRules_GetProp("m_bInWaitingForPlayers"))
	{
		switch(GameRules_GetRoundState())
		{
			case RoundState_Preround, RoundState_RoundRunning:
				return true;
		}
	}

	return false;
}
