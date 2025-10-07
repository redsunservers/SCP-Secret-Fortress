#pragma semicolon 1
#pragma newdecls required

// Precache, downloads
public void Default_Precache(int index, ActionInfo data)
{

}

// True = Remove right after pickup, False = Save for later
public bool Default_Type()
{
	return false;
}

// When picked up
public void Default_Pickup(int client)
{

}

// Return true to use up this item
public bool Default_Use(int client)
{
	return true;
}

// Return true to allow dropping this item
public bool Default_Drop(int client, bool death)
{
	return true;
}

// Called when the player is holding the item
public Action Default_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	return Plugin_Continue;
}