StringMap DoorNameToActivator;

// workaround for horrible door logic
// there is no direct way to tell apart what is a "checkpoint" and normal door in the scp maps
// this is needed for frag grenade/scp18/096 door destruction logic
// however, maps use scp_access relays for checks, which we will abuse to find what is a "checkpoint" door

void Doors_Clear()
{
	delete DoorNameToActivator;
	DoorNameToActivator = new StringMap();
	
	// Kill all of legacy 096rage, don't need it anymore
	int entity = INVALID_ENT_REFERENCE;
	while ((entity = FindEntityByClassname(entity, "trigger_*")) != INVALID_ENT_REFERENCE)
	{
		char filtername[64];
		GetEntPropString(entity, Prop_Data, "m_iFilterName", filtername, sizeof(filtername));
		if (StrContains(filtername, "096rage") != -1)
			RemoveEntity(entity);
	}
}

void UpdateDoorsFromButton(int entity)
{
	if (IsValidEntity(entity))
		CollectDoorsFromInput(entity, "m_OnPressed", "Toggle", entity);
}

void UpdateDoorsFromRelay(int entity)
{
	if (!IsValidEntity(entity))
		return;
	
	if (GetRelayAccess(entity) == Access_Unknown)
		return;
	
	CollectDoorsFromInput(entity, "m_OnUser1", "Toggle", entity);
	CollectDoorsFromInput(entity, "m_OnUser2", "Toggle", entity);
	CollectDoorsFromInput(entity, "m_OnUser3", "Toggle", entity);
	CollectDoorsFromInput(entity, "m_OnUser1", "Open", entity);
	CollectDoorsFromInput(entity, "m_OnUser2", "Open", entity);
	CollectDoorsFromInput(entity, "m_OnUser3", "Open", entity);
}

void CollectDoorsFromInput(int entity, const char[] prop, const char[] input, int activator)
{
	ArrayList doors = FindEntitiesFromInput(entity, prop, input);
	int length = doors.Length;
	for (int i = 0; i < length; i++)
	{
		char name[64];
		doors.GetString(i, name, sizeof(name));
		DoorNameToActivator.SetValue(name, activator);
		
		// Look up any connected doors
		CollectDoorsFromName("func_door", name, activator);
	}
	
	delete doors;
}

void CollectDoorsFromName(const char[] classname, const char[] name, int activator)
{
	int door = INVALID_ENT_REFERENCE;
	while ((door = FindEntityByClassname(door, classname)) != INVALID_ENT_REFERENCE)
	{
		char other[64];
		GetEntPropString(door, Prop_Data, "m_iName", other, sizeof(other));
		if (StrEqual(name, other, false))
			CollectDoorsFromInput(door, "m_OnOpen", "Open", activator);
	}
}

// thanks to dysphie for the I/O offsets
ArrayList FindEntitiesFromInput(int entity, const char[] prop, const char[] input)
{
	// get the offsets to the outputs
	int offset = FindDataMapInfo(entity, prop);
	if (offset == -1)
		return null;
	
	ArrayList doors = new ArrayList(32);
	
	char classname[64], name[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	
	Address output = GetEntityAddress(entity) + view_as<Address>(offset);
	Address actionlist = view_as<Address>(LoadFromAddress(output + view_as<Address>(0x14), NumberType_Int32));
	
	// note: there can be multiple different doors being killed/opened in the outputs
	while (actionlist)
	{
		// these are the only 2 parts of the output we care about
		Address iTarget = view_as<Address>(LoadFromAddress(actionlist, NumberType_Int32));
		
		Address iTargetInput = view_as<Address>(LoadFromAddress(actionlist + view_as<Address>(0x4), NumberType_Int32));
		
		// for the next output
		actionlist = view_as<Address>(LoadFromAddress(actionlist + view_as<Address>(0x18), NumberType_Int32));	
		
		char target[32], targetinput[32];
		StringtToCharArray(iTarget, target, sizeof(target));
		
		// ignore !self outputs
		if (target[0] == '!')
			continue;
		
		StringtToCharArray(iTargetInput, targetinput, sizeof(targetinput));
		if (!StrEqual(targetinput, input, false))
			continue;
		
		StringToLower(target);
		doors.PushString(target);
	}
	
	return doors;
}

int GetActivatorFromDoor(int door)
{
	char name[64];
	GetEntPropString(door, Prop_Data, "m_iName", name, sizeof(name));
	StringToLower(name);
	
	int activator;
	if (DoorNameToActivator.GetValue(name, activator) && IsValidEntity(activator))
		return activator;
	
	return INVALID_ENT_REFERENCE;
}

bool IsDoorNormal(int door)
{
	return GetActivatorFromDoor(door) != INVALID_ENT_REFERENCE && !IsDoorGate(door);
}

bool IsDoorGate(int door)
{
	int relay = GetActivatorFromDoor(door);
	if (relay == INVALID_ENT_REFERENCE)
		return false;
	
	char classname[256];
	GetEntityClassname(relay, classname, sizeof(classname));
	if (!StrEqual(classname, "logic_relay"))
		return false;
	
	AccessEnum access = GetRelayAccess(relay);
	return access == Access_Main || access == Access_Checkpoint || access == Access_Exit;
}

// attempt to destroy a given door, if it can't be destroyed then it will be opened/triggered instead
// returns false if the door couldn't be destroyed nor opened
public bool DestroyOrOpenDoor(int door)
{
	if (IsDoorNormal(door))
	{
		// Destroy all doors that is connected by button/relay
		bool destoryed;
		int activator = GetActivatorFromDoor(door);
		StringMapSnapshot snapshot = DoorNameToActivator.Snapshot();
		
		int length = snapshot.Length;
		for (int i = 0; i < length; i++)
		{
			char name[32];
			snapshot.GetKey(i, name, sizeof(name));
			
			int other;
			if (DoorNameToActivator.GetValue(name, other) && activator == other)
			{
				int entity = INVALID_ENT_REFERENCE;
				while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
				{
					char othername[64];
					GetEntPropString(entity, Prop_Data, "m_iName", othername, sizeof(othername));
					if (!StrEqual(name, othername, false))
						continue;
					
					if (!destoryed)
						EmitSoundToAll("physics/metal/metal_grate_impact_hard2.wav", door, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
					
					RemoveEntity(entity);
					destoryed = true;
				}
			}
		}
		
		delete snapshot;
		return destoryed;
	}
	else if (IsDoorGate(door))
	{
		// only attempt to open fully closed doors
		
		char classname[64];
		GetEntityClassname(door, classname, sizeof(classname));
		if (StrEqual(classname, "func_movelinear"))
		{
			if (GetEntProp(door, Prop_Data, "m_movementType") != 0)
				return false;
		}
		else
		{
			if (GetEntProp(door, Prop_Data, "m_toggle_state") != 1)
				return false;
		}
		
		// Call a relay that opens all of the door
		int relay = GetActivatorFromDoor(door);
		
		EmitSoundToAll("physics/metal/metal_grate_impact_hard1.wav", door, SNDCHAN_AUTO, SNDLEVEL_TRAIN);
		
		AcceptEntityInput(relay, "FireUser1");
		AcceptEntityInput(relay, "FireUser2");
		return true;
	}
	
	return false;
}

void StringToLower(char[] buffer)
{
	for (int i = 0; i < strlen(buffer); i++)
		buffer[i] = CharToLower(buffer[i]);
}