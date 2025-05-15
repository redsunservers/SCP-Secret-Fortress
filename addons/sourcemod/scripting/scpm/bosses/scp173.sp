#pragma semicolon 1
#pragma newdecls required

public void SCP173_Precache()
{

}

public TFClassType SCP173_TFClass()
{
	return TFClass_Heavy;
}

public void SCP173_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);
}
