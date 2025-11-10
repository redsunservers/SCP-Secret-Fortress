#pragma semicolon 1
#pragma newdecls required

void Command_PluginStart()
{
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all current non-boss players", false);

	AddCommandListener(Command_KermitSewerSlide, "explode");
	AddCommandListener(Command_KermitSewerSlide, "kill");
	AddCommandListener(Command_Spectate, "spectate");
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_AutoTeam, "autoteam");
	AddCommandListener(Command_JoinClass, "joinclass");
	AddCommandListener(Command_DropItem, "dropitem");
	AddCommandListener(Command_SayTeam, "say_team");
}

static bool BossTargetFilter(const char[] pattern, ArrayList clients)
{
	bool reverse = pattern[1] == '!';

	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client))
			continue;

		if(Client(client).IsBoss || Client(client).Minion)
		{
			if(!reverse)
				clients.Push(client);
		}
		else if(reverse)
		{
			clients.Push(client);
		}
	}

	return true;
}

public Action OnClientCommandKeyValues(int client, KeyValues kv)
{
	if(IsPlayerAlive(client))
	{
		char buffer[64];
		kv.GetSectionName(buffer, sizeof(buffer));
		if(StrEqual(buffer, "+inspect_server", false))
		{
			Human_ToggleFlashlight(client);
			return Plugin_Handled;
		}
		else if(StrEqual(buffer, "+use_action_slot_item_server", false))
		{
			Items_UseActionItem(client);
			return Plugin_Handled;	// Block normal weapon pickups
		}
	}
	return Plugin_Continue;
}

static Action Command_KermitSewerSlide(int client, const char[] command, int args)
{
	if(Client(client).IsBoss || Client(client).Minion)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

static Action Command_Spectate(int client, const char[] command, int args)
{
	return SwapTeam(client, true);
}

static Action Command_AutoTeam(int client, const char[] command, int args)
{
	return SwapTeam(client, false);
}

static Action Command_JoinTeam(int client, const char[] command, int args)
{
	char buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	return SwapTeam(client, StrEqual(buffer, "spectate", false));
}

static Action SwapTeam(int client, bool spectator)
{
	// No kill binds
	if(IsPlayerAlive(client) && (Client(client).IsBoss || Client(client).Minion))
		return Plugin_Handled;
	
	// Prevent going to spectate with cvar disabled
	if(spectator && !Cvar[AllowSpectators].BoolValue)
		return Plugin_Handled;
	
	// Already in spectator
	if(spectator && GetClientTeam(client) == TFTeam_Spectator)
		return Plugin_Handled;
	
	// Prevent swapping to a different team unless in spec or going to spec
	if(!spectator && GetClientTeam(client) > TFTeam_Spectator)
		return Plugin_Handled;
	
	if(Client(client).IsBoss)
	{
		// Remove properties
		Bosses_Remove(client);
	}
	
	ForcePlayerSuicide(client);
	ChangeClientTeam(client, spectator ? TFTeam_Spectator : TFTeam_Humans);
	if(!spectator)
		ShowVGUIPanel(client, "class_red");
	
	return Plugin_Handled;
}

static Action Command_JoinClass(int client, const char[] command, int args)
{
	if(Client(client).IsBoss || Client(client).Minion)
	{
		char class[16];
		GetCmdArg(1, class, sizeof(class));
		TFClassType num = TF2_GetClass(class);
		if(num != TFClass_Unknown)
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", num);

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

static Action Command_DropItem(int client, const char[] command, int args)
{
	if(!Client(client).IsBoss && !Client(client).Minion)
	{
		if(Client(client).ActionItem != -1)
		{
			if(Items_DropActionItem(client, false))
			{
				ClientCommand(client, "playgamesound ui/item_light_gun_drop.wav");
				return Plugin_Handled;
			}
		}

		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon != -1)
		{
			bool found;
			int entity, i;
			while(TF2_GetItem(client, entity, i))
			{
				if(weapon != entity)
				{
					found = true;
					TF2U_SetPlayerActiveWeapon(client, entity);
					break;
				}
			}

			if(found)
			{
				float pos[3], ang[3];
				GetClientEyePosition(client, pos);
				GetClientEyeAngles(client, ang);
				Items_DropByEntity(client, weapon, pos, ang, false);
				ClientCommand(client, "playgamesound ui/item_heavy_gun_drop.wav");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

static Action Command_SayTeam(int client, const char[] command, int args)
{
	char buffer[512];
	GetCmdArgString(buffer, sizeof(buffer));
	FakeClientCommandEx(client, "say %s", buffer);
	return Plugin_Handled;
}
