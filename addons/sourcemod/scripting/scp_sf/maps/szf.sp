enum SZFWeaponType
{
	WeaponType_Invalid,
	WeaponType_Static,
	WeaponType_Default,
	WeaponType_Spawn,
	WeaponType_Rare,
	WeaponType_RareSpawn,
	WeaponType_StaticSpawn,
	WeaponType_DefaultNoPickup,
	WeaponType_Common,
	WeaponType_Uncommon,
	WeaponType_UncommonSpawn
};

static int Carrying[MAXTF2PLAYERS] = {INVALID_ENT_REFERENCE, ...};
static bool TurnOn;

void SZF_RoundStart()
{
	TurnOn = false;

	char buffer[PLATFORM_MAX_PATH];
	int entity = -1;
	float pos[3];
	WeaponEnum weapon;
	while((entity=FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", buffer, sizeof(buffer));
		switch(GetWeaponType(buffer))
		{
			case WeaponType_Common:
			{
				if(Items_GetRandomWeapon(1, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_rand_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Spawn:
			{
				if(Items_GetRandomWeapon(1, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Uncommon:
			{
				if(Items_GetRandomWeapon(2, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_rand_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_UncommonSpawn:
			{
				if(Items_GetRandomWeapon(2, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Rare:
			{
				if(Items_GetRandomWeapon(GetRandomInt(2, 3), weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_rand_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_RareSpawn:
			{
				if(Items_GetRandomWeapon(3, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Default, WeaponType_DefaultNoPickup:
			{
				int rarity = GetRandomInt(0, 6) ? GetRandomInt(1, 2) : 3;
				if(Items_GetRandomWeapon(rarity, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_rand_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
					SetEntityModel(entity, weapon.Model);
					if(weapon.Skin >= 0)
						SetEntProp(entity, Prop_Send, "m_nSkin", weapon.Skin);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_Static:
			{
				GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
				if(Items_GetWeaponByModel(buffer, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_rand_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			case WeaponType_StaticSpawn:
			{
				GetEntPropString(entity, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
				if(Items_GetWeaponByModel(buffer, weapon))
				{
					FormatEx(buffer, sizeof(buffer), "scp_item_%d", weapon.Index);
					SetEntPropString(entity, Prop_Data, "m_iName", buffer);
				}
				else
				{
					RemoveEntity(entity);
					continue;
				}
			}
			default:
			{
				continue;
			}
		}

		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
		AcceptEntityInput(entity, "DisableShadow");
		AcceptEntityInput(entity, "EnableCollision");

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 0.8;
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		TurnOn = true;
	}
}

bool SZF_Enabled()
{
	return TurnOn;
}

bool SZF_Pickup(int client, int entity, const char[] name)
{
	if(!StrContains(name, "szf_carry", false) || !StrContains(name, "szf_pick", false) || StrEqual(name, "gascan", false))
	{
		int weapon, pos;
		while((weapon=Items_Iterator(client, pos, true)) != -1)
		{
			if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 5)
			{
				SetActiveWeapon(client, weapon);
				Items_ShowItemMenu(client);

				Carrying[client] = EntIndexToEntRef(entity);
				AcceptEntityInput(entity, "DisableMotion");
				SetEntProp(entity, Prop_Send, "m_nSolidType", 0);

				EmitSoundToClient(client, "ui/item_paint_can_pickup.wav");
				AcceptEntityInput(entity, "FireUser1", client, client);
				return true;
			}
		}
	}
	return false;
}

void SZF_PlayerRunCmd(int client)
{
	if(Carrying[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(Carrying[client]);
		if(entity > MaxClients)
		{
			static float pos[3], ang[3], vel[3];
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, ang);
			
			pos[2] -= 20.0;
			
			ang[0] = 5.0;
			ang[2] += 35.0;
			
			AnglesToVelocity(ang, vel, 60.0);
			AddVectors(pos, vel, pos);
			TeleportEntity(entity, pos, ang, NULL_VECTOR);
		}
		else
		{
			Carrying[client] = INVALID_ENT_REFERENCE;
		}
	}
}

void SZF_DropItem(int client, bool teleport=true)
{
	if(Carrying[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(Carrying[client]);
		if(entity > MaxClients)
		{
			SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
			AcceptEntityInput(entity, "EnableMotion");
			AcceptEntityInput(entity, "FireUser2", client, client);

			if(teleport)
			{
				static float pos[3];
				GetClientEyePosition(client, pos);
				if(!IsEntityStuck(entity) && !ObstactleBetweenEntities(client, entity))
				{
					pos[0] += 20.0;
					pos[2] -= 30.0;
				}

				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}

		Carrying[client] = INVALID_ENT_REFERENCE;
	}
}

static SZFWeaponType GetWeaponType(const char[] buffer)
{
	if(!StrContains(buffer, "szf_weapon_spawn", false))
	{
		return WeaponType_Spawn;
	}
	else if(!StrContains(buffer, "szf_weapon_rare_spawn", false))
	{
		return WeaponType_RareSpawn;
	}
	else if(!StrContains(buffer, "szf_weapon_rare", false))
	{
		return WeaponType_Rare;
	}
	else if(!StrContains(buffer, "szf_weapon_static_spawn", false))
	{
		return WeaponType_StaticSpawn;
	}
	else if(!StrContains(buffer, "szf_weapon_static", false))
	{
		return WeaponType_Static;
	}
	else if(!StrContains(buffer, "szf_weapon_nopickup", false))
	{
		return WeaponType_DefaultNoPickup;
	}
	else if(!StrContains(buffer, "szf_weapon_common", false))
	{
		return WeaponType_Common;
	}
	else if(!StrContains(buffer, "szf_weapon_uncommon_spawn", false))
	{
		return WeaponType_UncommonSpawn;
	}
	else if(!StrContains(buffer, "szf_weapon_uncommon", false))
	{
		return WeaponType_Uncommon;
	}
	else if(StrContains(buffer, "szf_weapon", false) != -1)
	{
		return WeaponType_Default;
	}
	return WeaponType_Invalid;
}