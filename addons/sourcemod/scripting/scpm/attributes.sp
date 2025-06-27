#pragma semicolon 1
#pragma newdecls required

#if !defined DEFAULT_VALUE_TEST
#define DEFAULT_VALUE_TEST	-69420.69
#endif

stock float Attrib_FindOnPlayer(int client, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = Attrib_Get(client, name, total);
	
	int i;
	int entity;
	float value;
	while(TF2U_GetWearable(client, entity, i))
	{
		if(Attrib_Get(entity, name, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}

	bool provideActive = StrEqual(name, "provide on active");
	
	int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	while(TF2_GetItem(client, entity, i))
	{
		if(!provideActive && active != entity && Attrib_Get(entity, "provide on active", value) && value)
			continue;
		
		if(Attrib_Get(entity, name, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	return total;
}

stock float Attrib_FindOnWeapon(int client, int entity, const char[] name, bool multi = false)
{
	float total = multi ? 1.0 : 0.0;
	bool found = Attrib_Get(client, name, total);
	
	int i;
	int wear;
	float value;
	while(TF2U_GetWearable(client, wear, i))
	{
		if(Attrib_Get(wear, name, value))
		{
			if(!found)
			{
				total = value;
				found = true;
			}
			else if(multi)
			{
				total *= value;
			}
			else
			{
				total += value;
			}
		}
	}
	
	if(entity != -1)
	{
		char classname[18];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "tf_w") || StrEqual(classname, "tf_powerup_bottle"))
		{
			if(Attrib_Get(entity, name, value))
			{
				if(!found)
				{
					total = value;
				}
				else if(multi)
				{
					total *= value;
				}
				else
				{
					total += value;
				}
			}
		}
	}
	
	return total;
}

stock bool Attrib_Get(int entity, const char[] name, float &value = 0.0)
{
	float result = DEFAULT_VALUE_TEST;
	if(VScript_GetAttribute(entity, name, result))
	{
		if(result == DEFAULT_VALUE_TEST)
			return false;
		
		value = result;
		return true;
	}

	return false;
}

stock void Attrib_Set(int entity, const char[] name, float value, float duration = -1.0)
{
	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", %f, %f)", entity > MaxClients ? "" : "Custom", name, value, duration);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}

stock void Attrib_SetInt(int entity, const char[] name, int value, float duration = -1.0)
{
	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Add%sAttribute(\"%s\", casti2f(%d), %f)", entity > MaxClients ? "" : "Custom", name, value, duration);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}

stock void Attrib_Remove(int entity, const char[] name)
{
	static char buffer[256];
	Format(buffer, sizeof(buffer), "self.Remove%sAttribute(\"%s\")", (entity > MaxClients) ? "" : "Custom", name);
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode");
}
