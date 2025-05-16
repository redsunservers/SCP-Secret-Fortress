#pragma semicolon 1
#pragma newdecls required

static void KeycardPickup(int client, int contain, int armory, int checkpoint)
{
	bool drop;	// Only drop our old card if ALL stats changed/the same, otherwise we can clone stats onto old cards

	// All better stats
	if(Client(client).KeycardContain <= contain && Client(client).KeycardArmory <= armory && Client(client).KeycardExit <= checkpoint)
		drop = true;
	
	// All worse stats
	if(Client(client).KeycardContain >= contain && Client(client).KeycardArmory >= armory && Client(client).KeycardExit >= checkpoint)
		drop = true;
	
	if(drop)
		Keycard_DropBestMatch(client, false);
	
	if(drop || contain > Client(client).KeycardContain)
		Client(client).KeycardContain = contain;
	
	if(drop || armory > Client(client).KeycardArmory)
		Client(client).KeycardArmory = armory;
	
	if(drop || checkpoint > Client(client).KeycardExit)
		Client(client).KeycardExit = checkpoint;
}

// Hack Function
void Keycard_DropBestMatch(int client, bool death)
{
	if(Client(client).KeycardContain < 1)
		return;

	int index = 30001;
	switch(Client(client).KeycardExit)
	{
		case 0:
		{
			index = Client(client).KeycardContain > 0 ? 30002 : 30001;
		}
		case 1:
		{
			if(Client(client).KeycardContain > 2)
			{
				index = 30009;
			}
			else if(Client(client).KeycardContain > 1)
			{
				index = 30004;
			}
			else if(Client(client).KeycardArmory > 1)
			{
				index = 30006;
			}
			else if(Client(client).KeycardArmory > 0)
			{
				index = 30005;
			}
			else
			{
				index = 30003;
			}
		}
		default:
		{
			if(Client(client).KeycardContain > 2)
			{
				index = Client(client).KeycardArmory > 2 ? 30012 : 30010;
			}
			else if(Client(client).KeycardArmory > 2)
			{
				index = Client(client).KeycardContain > 1 ? 30011 : 30008;
			}
			else
			{
				index = 30007;
			}
		}
	}

	float pos[3], ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	Items_DropByIndex(client, index, pos, ang, death);
}

public bool Keycard100_Type()
{
	return true;
}
public void Keycard100_Pickup(int client)
{
	KeycardPickup(client, 1, 0, 0);
}

public bool Keycard101_Type()
{
	return true;
}
public void Keycard101_Pickup(int client)
{
	KeycardPickup(client, 1, 0, 2);
}

public bool Keycard102_Type()
{
	return true;
}
public void Keycard102_Pickup(int client)
{
	KeycardPickup(client, 1, 0, 2);
}

public bool Keycard110_Type()
{
	return true;
}
public void Keycard110_Pickup(int client)
{
	KeycardPickup(client, 1, 1, 0);
}

public bool Keycard111_Type()
{
	return true;
}
public void Keycard111_Pickup(int client)
{
	KeycardPickup(client, 1, 1, 2);
}

public bool Keycard112_Type()
{
	return true;
}
public void Keycard112_Pickup(int client)
{
	KeycardPickup(client, 1, 1, 2);
}

public bool Keycard120_Type()
{
	return true;
}
public void Keycard120_Pickup(int client)
{
	KeycardPickup(client, 1, 2, 0);
}

public bool Keycard121_Type()
{
	return true;
}
public void Keycard121_Pickup(int client)
{
	KeycardPickup(client, 1, 2, 2);
}

public bool Keycard122_Type()
{
	return true;
}
public void Keycard122_Pickup(int client)
{
	KeycardPickup(client, 1, 2, 2);
}

public bool Keycard130_Type()
{
	return true;
}
public void Keycard130_Pickup(int client)
{
	KeycardPickup(client, 1, 3, 0);
}

public bool Keycard131_Type()
{
	return true;
}
public void Keycard131_Pickup(int client)
{
	KeycardPickup(client, 1, 3, 2);
}

public bool Keycard132_Type()
{
	return true;
}
public void Keycard132_Pickup(int client)
{
	KeycardPickup(client, 1, 3, 2);
}

public bool Keycard200_Type()
{
	return true;
}
public void Keycard200_Pickup(int client)
{
	KeycardPickup(client, 2, 0, 0);
}

public bool Keycard201_Type()
{
	return true;
}
public void Keycard201_Pickup(int client)
{
	KeycardPickup(client, 2, 0, 2);
}

public bool Keycard202_Type()
{
	return true;
}
public void Keycard202_Pickup(int client)
{
	KeycardPickup(client, 2, 0, 2);
}

public bool Keycard210_Type()
{
	return true;
}
public void Keycard210_Pickup(int client)
{
	KeycardPickup(client, 2, 1, 0);
}

public bool Keycard211_Type()
{
	return true;
}
public void Keycard211_Pickup(int client)
{
	KeycardPickup(client, 2, 1, 2);
}

public bool Keycard212_Type()
{
	return true;
}
public void Keycard212_Pickup(int client)
{
	KeycardPickup(client, 2, 1, 2);
}

public bool Keycard220_Type()
{
	return true;
}
public void Keycard220_Pickup(int client)
{
	KeycardPickup(client, 2, 2, 0);
}

public bool Keycard221_Type()
{
	return true;
}
public void Keycard221_Pickup(int client)
{
	KeycardPickup(client, 2, 2, 2);
}

public bool Keycard222_Type()
{
	return true;
}
public void Keycard222_Pickup(int client)
{
	KeycardPickup(client, 2, 2, 2);
}

public bool Keycard230_Type()
{
	return true;
}
public void Keycard230_Pickup(int client)
{
	KeycardPickup(client, 2, 3, 0);
}

public bool Keycard231_Type()
{
	return true;
}
public void Keycard231_Pickup(int client)
{
	KeycardPickup(client, 2, 3, 2);
}

public bool Keycard232_Type()
{
	return true;
}
public void Keycard232_Pickup(int client)
{
	KeycardPickup(client, 2, 3, 2);
}

public bool Keycard300_Type()
{
	return true;
}
public void Keycard300_Pickup(int client)
{
	KeycardPickup(client, 3, 0, 0);
}

public bool Keycard301_Type()
{
	return true;
}
public void Keycard301_Pickup(int client)
{
	KeycardPickup(client, 3, 0, 2);
}

public bool Keycard302_Type()
{
	return true;
}
public void Keycard302_Pickup(int client)
{
	KeycardPickup(client, 3, 0, 2);
}

public bool Keycard310_Type()
{
	return true;
}
public void Keycard310_Pickup(int client)
{
	KeycardPickup(client, 3, 1, 0);
}

public bool Keycard311_Type()
{
	return true;
}
public void Keycard311_Pickup(int client)
{
	KeycardPickup(client, 3, 1, 2);
}

public bool Keycard312_Type()
{
	return true;
}
public void Keycard312_Pickup(int client)
{
	KeycardPickup(client, 3, 1, 2);
}

public bool Keycard320_Type()
{
	return true;
}
public void Keycard320_Pickup(int client)
{
	KeycardPickup(client, 3, 2, 0);
}

public bool Keycard321_Type()
{
	return true;
}
public void Keycard321_Pickup(int client)
{
	KeycardPickup(client, 3, 2, 2);
}

public bool Keycard322_Type()
{
	return true;
}
public void Keycard322_Pickup(int client)
{
	KeycardPickup(client, 3, 2, 2);
}

public bool Keycard330_Type()
{
	return true;
}
public void Keycard330_Pickup(int client)
{
	KeycardPickup(client, 3, 3, 0);
}

public bool Keycard331_Type()
{
	return true;
}
public void Keycard331_Pickup(int client)
{
	KeycardPickup(client, 3, 3, 2);
}

public bool Keycard332_Type()
{
	return true;
}
public void Keycard332_Pickup(int client)
{
	KeycardPickup(client, 3, 3, 2);
}
