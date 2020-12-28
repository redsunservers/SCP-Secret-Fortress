enum WeaponEnum
{
	Weapon_None = 0,

	Weapon_Axe,
	Weapon_Hammer,
	Weapon_Knife,
	Weapon_Bash,
	Weapon_Meat,
	Weapon_Wrench,
	Weapon_Pan,

	Weapon_Disarm,

	Weapon_Pistol,		// COM-15 Sidearm
	Weapon_Pistol2,		// USP
	Weapon_SMG,		// MP7
	Weapon_SMG2,		// Project 90
	Weapon_SMG3,		// MTF-E11-SR
	Weapon_SMG4,		// Logicer

	Weapon_Flash,
	Weapon_Frag,
	Weapon_Shotgun,
	Weapon_Micro,

	Weapon_PDA1,
	Weapon_PDA2,
	Weapon_PDA3
}

int WeaponIndex[] =
{
	5,

	// Melee
	192,
	153,
	30758,
	325,
	1013,
	197,
	264,

	954,	// Disarmer

	// Secondary
	773,
	209,
	751,
	1150,
	425,
	415,

	// Primary
	1151,
	308,
	199,
	594,

	// PDAs
	25,
	26,
	28
};

int WeaponRank[] =
{
	13,

	// Melee
	2,
	3,
	4,
	1,
	17,
	5,
	6,

	0,	// Disarmer

	// Secondary
	1,
	2,
	3,
	4,
	6,
	7,

	// Primary
	12,
	11,
	9,
	14,

	// PDAs
	-1,
	-1,
	-1
};

void DropAllWeapons(int client)
{
	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	if(Client[client].Keycard > Keycard_None)
	{
		DropKeycard(client, false, origin, angles, Client[client].Keycard);
		Client[client].Keycard = Keycard_None;
	}

	if(Client[client].Extra2)
	{
		DropKeycard(client, true, origin, angles, Keycard_Radio);
		Client[client].Extra2 = 0;
	}

	//Drop all weapons
	for(int i; i<3; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if(weapon>MaxClients && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")!=WeaponIndex[Weapon_None])
			TF2_CreateDroppedWeapon(client, weapon, false, origin, angles);
	}

	if(Client[client].HealthPack)
	{
		int entity = CreateEntityByName(Client[client].HealthPack==3 ? "item_healthkit_full" : Client[client].HealthPack==2 ? "item_healthkit_medium" : "item_healthkit_small");
		if(entity > MaxClients)
		{
			GetClientAbsOrigin(client, origin);
			origin[2] += 20.0;
			DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
			DispatchSpawn(entity);
			SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client), 4);
			SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
			SetEntityMoveType(entity, MOVETYPE_VPHYSICS);

			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

void DropCurrentKeycard(int client)
{
	if(Client[client].Keycard <= Keycard_None)
		return;

	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	DropKeycard(client, true, origin, angles, Client[client].Keycard);
}

void DropKeycard(int client, bool swap, const float origin[3], const float angles[3], KeycardEnum card)
{
	for(int i=2; i>=0; i--)
	{
		int weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients)
		{
			if(TF2_CreateDroppedWeapon(client, weapon, swap, origin, angles, card) != INVALID_ENT_REFERENCE)
				break;
		}
	}
}

int GiveWeapon(int client, WeaponEnum weapon, bool equip=true, bool ammo=true, int account=-3)
{
	int entity;
	switch(weapon)
	{
		/*
			Melee Weapons
		*/
		case Weapon_None:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 1, 0, "1 ; 0 ; 252 ; 0.99", _, true);
			if(entity > MaxClients)
			{
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 0);
			}
		}
		case Weapon_Disarm:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "1 ; 0.3 ; 15 ; 0 ; 252 ; 0.95", _, true);
		}
		case Weapon_Axe:
		{
			entity = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 5, 6, "2 ; 1.65 ; 28 ; 0.5 ; 252 ; 0.95", _, true);
		}
		case Weapon_Hammer:
		{
			entity = SpawnWeapon(client, "tf_weapon_fireaxe", WeaponIndex[weapon], 5, 6, "2 ; 11 ; 6 ; 0.9 ; 28 ; 0.5 ; 138 ; 0.13 ; 252 ; 0.95");
		}
		case Weapon_Knife:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.2 ; 6 ; 0.8 ; 15 ; 0 ; 252 ; 0.95 ; 362 ; 1", _, true);
		}
		case Weapon_Bash:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.05 ; 6 ; 0.7 ; 28 ; 0.5 ; 252 ; 0.95");
		}
		case Weapon_Meat:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "1 ; 0.9 ; 6 ; 0.7 ; 252 ; 0.95", _, true);
		}
		case Weapon_Wrench:
		{
			entity = SpawnWeapon(client, "tf_weapon_wrench", WeaponIndex[weapon], 5, 6, "2 ; 1.5 ; 6 ; 0.9 ; 28 ; 0.5 ; 252 ; 0.95 ; 2043 ; 0", _, true);
		}
		case Weapon_Pan:
		{
			entity = SpawnWeapon(client, "tf_weapon_club", WeaponIndex[weapon], 5, 6, "2 ; 1.35 ; 6 ; 0.8 ; 28 ; 0.5 ; 252 ; 0.95", _, true);
		}

		/*
			Secondary Weapons
		*/
		case Weapon_Pistol:
		{
			switch(Client[client].Class)
			{
				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Scout);
			}
			entity = SpawnWeapon(client, "tf_weapon_pistol", WeaponIndex[weapon], 5, 6, "2 ; 1.426667 ; 5 ; 1.111111 ; 96 ; 1.149425 ; 106 ; 0.33 ; 252 ; 0.95 ; 397 ; 1 ; 4363 ; 0.5");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 24, 0);
		}
		case Weapon_Pistol2:
		{
			switch(Client[client].Class)
			{
				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Scout);
			}
			entity = SpawnWeapon(client, "tf_weapon_pistol", WeaponIndex[weapon], 5, 6, "2 ; 1.7 ; 4 ; 1.5 ; 5 ; 1.333333 ; 96 ; 1.214559 ; 106 ; 0.33 ; 252 ; 0.925 ; 397 ; 2 ; 4363 ; 0.5", _, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 18, 18);
		}
		case Weapon_SMG:
		{
			switch(Client[client].Class)
			{
				case Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Sniper);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 5, 6, "2 ; 1.65 ; 4 ; 1.4 ; 96 ; 2.863636 ; 252 ; 0.9");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 35, 35);
		}
		case Weapon_SMG2:
		{
			switch(Client[client].Class)
			{
				case Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_DemoMan);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 10, 6, "2 ; 1.75 ; 4 ; 2 ; 6 ; 0.909091 ; 96 ; 3 ; 252 ; 0.85 ; 397 ; 1 ; 4363 ; 0.5");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 30, 50);
		}
		case Weapon_SMG3:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					ChangeClientClass(client, TFClass_Pyro);

				case Class_MTF2:
					ChangeClientClass(client, TFClass_Heavy);

				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Soldier);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 20, 6, "2 ; 2.275 ; 4 ; 1.6 ; 5 ; 1.25 ; 96 ; 3 ; 252 ; 0.8 ; 397 ; 2 ; 4363 ; 0.5");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, Client[client].Class>=Class_MTFS ? 120 : 80, 40);
		}
		case Weapon_SMG4:
		{
			switch(Client[client].Class)
			{
				case Class_Chaos:
					ChangeClientClass(client, TFClass_Pyro);

				case Class_MTF2:
					ChangeClientClass(client, TFClass_Heavy);

				case Class_Scientist, Class_MTFS, Class_MTFE:
					ChangeClientClass(client, TFClass_Engineer);

				default:
					ChangeClientClass(client, TFClass_Soldier);
			}
			entity = SpawnWeapon(client, "tf_weapon_smg", WeaponIndex[weapon], 30, 6, "2 ; 2.475 ; 4 ; 2 ; 6 ; 0.90909 ; 96 ; 2 ; 252 ; 0.7 ; 389 ; 3 ; 4363 ; 0.5");
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 125, 50);
		}

		/*
			Primary Weapons
		*/
		case Weapon_Flash:
		{
			entity = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 5, 6, "1 ; 0.01 ; 5 ; 8.5 ; 15 ; 0 ; 77 ; 0.003 ; 99 ; 1.5 ; 252 ; 0.95 ; 303 ; -1 ; 773 ; 2 ; 787 ; 1.304348", 1, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 1);
		}
		case Weapon_Frag:
		{
			entity = SpawnWeapon(client, "tf_weapon_grenadelauncher", WeaponIndex[weapon], 10, 6, "2 ; 45 ; 5 ; 8.5 ; 15 ; 0 ; 77 ; 0.003 ; 99 ; 1.5 ; 252 ; 0.95 ; 303 ; -1 ; 773 ; 2 ; 787 ; 2.173913", 1);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 1);
		}
		case Weapon_Shotgun:
		{
			entity = SpawnWeapon(client, "tf_weapon_shotgun_primary", WeaponIndex[weapon], 10, 6, "3 ; 0.66 ; 5 ; 1.34 ; 36 ; 1.5 ; 45 ; 2 ; 77 ; 0.016 ; 252 ; 0.95 ; 389 ; 3 ; 4363 ; 0.5", _, true);
			if(ammo && entity>MaxClients)
				SetAmmo(client, entity, 8, 4);
		}
		case Weapon_Micro:
		{
			entity = SpawnWeapon(client, "tf_weapon_flamethrower", WeaponIndex[weapon], 110, 6, "2 ; 3.25 ; 173 ; 6 ; 138 ; 2.25 ; 252 ; 0.5 ; 421 ; 1", _, true);
			if(entity > MaxClients)
			{
				SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
				if(ammo)
					SetAmmo(client, entity, 1000);
			}
		}

		/*
			Other Weapons
		*/
		case Weapon_PDA1:
		{
			entity = SpawnWeapon(client, "tf_weapon_pda_engineer_build", WeaponIndex[weapon], 5, 6, "80 ; 2 ; 148 ; 3 ; 177 ; 1.3 ; 205 ; 3 ; 276 ; 1 ; 343 ; 0.5 ; 353 ; 1 ; 464 ; 0 ; 465 ; 0 ; 732 ; 2 ; 790 ; 1.333333 ; 4350 ; 0.75 ; 4351 ; 0.5 ; 4354 ; 2.5", _, true);
			SetEntProp(client, Prop_Data, "m_iAmmo", 400, 4, 3);
		}
		case Weapon_PDA2:
		{
			entity = SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", WeaponIndex[weapon], 5, 6, "205 ; 3", _, true);
		}
		case Weapon_PDA3:
		{
			entity = SpawnWeapon(client, "tf_weapon_builder", WeaponIndex[weapon], 5, 6, "205 ; 3", _, true);
			if(entity > MaxClients)
			{
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 0);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 1);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, 2);
				SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, 3);
			}
		}

		default:
		{
			return -1;
		}
	}

	if(entity > MaxClients)
	{
		ApplyStrangeRank(entity, WeaponRank[weapon]);

		if(account == -3)
			account = GetSteamAccountID(client);

		SetEntProp(entity, Prop_Send, "m_iAccountID", account);
		if(equip)
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);

		Forward_OnWeapon(client, entity);
	}
	return entity;
}

void PickupWeapon(int client, int entity)
{
	{
		static char name[48];
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(name[0])
		{
			if(!StrContains(name, "scp_radio_"))
			{
				ClientCommand(client, "playgamesound ui/item_nvg_pickup.wav");
				ReplaceString(name, sizeof(name), "scp_radio_", "");
				float power = StringToFloat(name);
				if(Client[client].Extra2)
				{
					Format(name, sizeof(name), "scp_radio_%f", Client[client].Power);
					SetEntPropString(entity, Prop_Data, "m_iName", name);
					Client[client].Power = power;
				}
				else
				{
					Client[client].Extra2 = 1;
					Client[client].Power = power;
					RemoveEntity(entity);
				}
				return;
			}

			int card = view_as<int>(Keycard_Janitor);
			for(; card<sizeof(KeycardNames); card++)
			{
				if(StrEqual(name, KeycardNames[card], false))
				{
					if(card == view_as<int>(Keycard_O5))
						GiveAchievement(Achievement_FindO5, client);

					ClientCommand(client, "playgamesound ui/item_metal_tiny_pickup.wav");
					DropCurrentKeycard(client);
					Client[client].Keycard = view_as<KeycardEnum>(card);
					RemoveEntity(entity);
					return;
				}
			}
		}
	}

	int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
	for(WeaponEnum i=Weapon_Axe; i<Weapon_Pistol; i++)
	{
		if(index != WeaponIndex[i])
			continue;

		if(Items_CanGive(client, Item_Weapon))
		{
			
		}
		else
		{
		}
	}

	for(WeaponEnum i=Weapon_Pistol; i<Weapon_PDA1; i++)
	{
		if(index != WeaponIndex[i])
			continue;

		if(Client[client].Class == Class_DBoi)
			GiveAchievement(Achievement_FindGun, client);

		if(ReplaceWeapon(client, i, entity))
		{
			SetVariantString("randomnum:100");
			AcceptEntityInput(client, "AddContext");
			SetVariantString("TLK_MVM_LOOT_COMMON");
			AcceptEntityInput(client, "SpeakResponseConcept");
			AcceptEntityInput(client, "ClearContext");
		}

		RemoveEntity(entity);
		return;
	}
}

bool ReplaceWeapon(int client, WeaponEnum wep, int entity=0)
{
	static float origin[3], angles[3];
	GetClientEyePosition(client, origin);

	//Check if client already has weapon in given slot, remove and create dropped weapon if so
	bool newWeapon;
	int slot = wep>Weapon_Disarm ? wep<Weapon_Flash ? TFWeaponSlot_Secondary : TFWeaponSlot_Primary : TFWeaponSlot_Melee;
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(weapon > MaxClients)
	{
		int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(WeaponIndex[wep] == index)
		{
			SpawnPickup(client, "item_ammopack_small");
			return newWeapon;
		}
		else if(index != WeaponIndex[Weapon_None])
		{
			GetClientEyePosition(client, origin);
			GetClientEyeAngles(client, angles);
			TF2_CreateDroppedWeapon(client, weapon, true, origin, angles);
		}
		else
		{
			newWeapon = true;
		}

		TF2_RemoveWeaponSlot(client, slot);
	}

	ClientCommand(client, "playgamesound %s", SOUNDPICKUP);

	if(entity > MaxClients)
	{
		weapon = GiveWeapon(client, wep, _, false, GetEntProp(entity, Prop_Send, "m_iAccountID"));
		if(weapon > MaxClients)
		{
			//Restore ammo, energy etc from picked up weapon
			SDKCall_InitPickup(entity, client, weapon);

			//If max ammo not calculated yet (-1), do it now
			if(TF2_GetWeaponAmmo(client, weapon) < 0)
			{
				TF2_SetWeaponAmmo(client, weapon, 0);
				TF2_RefillWeaponAmmo(client, weapon);
			}
		}
	}
	else
	{
		GiveWeapon(client, wep);
	}
	return newWeapon;
}