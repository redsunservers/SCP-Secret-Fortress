#pragma semicolon 1
#pragma newdecls required

public void SCP173_Precache()
{

}

public void SCP173_Create(int client)
{
	Default_Create(client);
}

public TFClassType SCP173_TFClass()
{
	return TFClass_Heavy;
}

public void SCP173_Spawn(int client)
{
	if(!GoToNamedSpawn(client, "scp_spawn_173"))
		Default_Spawn(client);
}

public void SCP173_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);
}

public void SCP173_Remove(int client)
{
	Default_Remove(client);
}
