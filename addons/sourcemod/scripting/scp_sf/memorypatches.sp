#pragma semicolon 1
#pragma newdecls required

MemoryPatch PatchProcessMovement;
//MemoryPatch PatchFlameThink;

void MemoryPatch_Setup(GameData gamedata)
{
	MemoryPatch.SetGameData(gamedata);
	
	PatchProcessMovement = new MemoryPatch("Patch_ProcessMovement");
	if (PatchProcessMovement)
	{
		PatchProcessMovement.Enable();
	}
	else
	{
		LogError("[Gamedata] Could not find Patch_ProcessMovement");
	}
	
	// FIXME: get this working
	
	// fix flames going through walls (for Micro HID weapon)
	//PatchFlameThink = new MemoryPatch("Patch_FlameThink");
	//if (PatchFlameThink)
	//{
	//	PatchFlameThink.Enable();
	//}
	//else
	//{
	//	LogError("[Gamedata] Could not find Patch_FlameThink");
	//}
}

void MemoryPatch_Shutdown()
{
	if (PatchProcessMovement)
		PatchProcessMovement.Disable();
	//if (PatchFlameThink)
	//	PatchFlameThink.Disable();
}