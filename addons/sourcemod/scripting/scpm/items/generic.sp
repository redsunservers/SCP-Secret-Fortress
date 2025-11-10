#pragma semicolon 1
#pragma newdecls required

public bool SmallHealth_Use(int client)
{
	Client(client).Stress -= 50.0;
	ApplyHealEvent(client, 5);
	
	if(Client(client).Stress < 0.0)
		Client(client).Stress = 0.0;
	
	SetEntityHealth(client, GetClientHealth(client) + 100);
	ClientCommand(client, "playgamesound items/medshot4.wav");
	return true;
}

public bool MediumHealth_Use(int client)
{
	SetEntityHealth(client, GetClientHealth(client) + 400);
	ClientCommand(client, "playgamesound items/medshot4.wav");
	return true;
}

public bool Adrenaline_Use(int client)
{
	Client(client).SprintPower += 80.0;
	ClientCommand(client, "playgamesound items/medshot4.wav");
	return true;
}

public bool SCP500_Use(int client)
{
	ApplyHealEvent(client, RoundToCeil(Client(client).Stress / 10.0));
	Client(client).Stress = 0.0;
	
	Client(client).SprintPower = 100.0;
	SetEntityHealth(client, 300);
	TF2_RemoveCondition(client, TFCond_Plague);
	ToggleZombie(client, false);
	ClientCommand(client, "playgamesound items/medshot4.wav");
	return true;
}

public bool SCP207_Use(int client)
{
	if(Client(client).SprintPower < 200.0 && !TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
	{
		Client(client).Stress += 50.0;
		ApplyHealEvent(client, -5);
		
		Client(client).ActionCooldownFor = GetGameTime() + 5.0;
		Client(client).SprintPower += 50.0;
		ClientCommand(client, "playgamesound player/pl_scout_dodge_can_drink.wav");
	}
	else
	{
		ClientCommand(client, "playgamesound player/suit_denydevice.wav");
	}
	return false;
}

public bool SCP268_Use(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_Stealthed) && !TF2_IsPlayerInCondition(client, TFCond_MarkedForDeath))
	{
		Client(client).Stress += 100.0;
		ApplyHealEvent(client, -10);
		
		Client(client).ActionCooldownFor = GetGameTime() + 20.0;
		TF2_AddCondition(client, TFCond_Stealthed, 20.0);
		ClientCommand(client, "playgamesound misc/halloween/spell_stealth.wav");
	}
	else
	{
		ClientCommand(client, "playgamesound player/suit_denydevice.wav");
	}
	return false;
}

public bool SCP109_Use(int client)
{
	Client(client).ActionCooldownFor = GetGameTime() + 5.0;

	if(Client(client).SprintPower < 90.0)
		Client(client).SprintPower += 10.0;
	
	ClientCommand(client, "playgamesound player/pl_scout_dodge_can_drink.wav");
	return false;
}
