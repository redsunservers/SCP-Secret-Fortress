#pragma semicolon 1
#pragma newdecls required

// Precache, downloads
public void Default_Precache(int index, ActionInfo data)
{

}

// True = Remove right after pickup, False = Save for later
public bool Default_Type()
{
	return true;
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
