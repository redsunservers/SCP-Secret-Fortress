#pragma semicolon 1
#pragma newdecls required

public void FlashGrenade_Precache()
{
	PrecacheModel("models/scp_fixed/flash/w_flash.mdl");
	PrecacheScriptSound("Weapon_Detonator.Detonate");
}

public bool FlashGrenade_Use(int client)
{
	int entity = CreateEntityByName("prop_physics_multiplayer");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "physicsmode", "2");

		static float ang[3], pos[3], vel[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		GetClientEyeAngles(client, ang);
		pos[2] += 63.0;

		GrenadeTrajectory(ang, vel, 1200.0);

		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));

		SetEntityModel(entity, "models/scp_fixed/flash/w_flash.mdl");

		DispatchSpawn(entity);
		TeleportEntity(entity, pos, ang, vel);

		CreateTimer(3.0, FlashGrenadeTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	return true;
}

static Action FlashGrenadeTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity > MaxClients)
	{
		static float pos1[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos1);
		
		int flags = (SF_ENVEXPLOSION_NODAMAGE|SF_ENVEXPLOSION_REPEATABLE|SF_ENVEXPLOSION_NODECAL|SF_ENVEXPLOSION_NOSOUND|SF_ENVEXPLOSION_RND_ORIENT|SF_ENVEXPLOSION_NOFIREBALLSMOKE|SF_ENVEXPLOSION_NOPARTICLES);
		int explosion = CreateExplosion(_, _, _, pos1, flags, _, false);
		
		if (IsValidEntity(explosion))
		{
			AttachParticle(explosion, "drg_cow_explosioncore_normal_blue", false, 1.0);
			EmitGameSoundToAll("Weapon_Detonator.Detonate", explosion);
			
			// create a short light effect, clientside duration can increase slightly depending on ping
			int light = TF2_CreateLightEntity(1024.0, { 255, 255, 255, 255 }, 5, 0.1);
			if (light > MaxClients)
				TeleportEntity(light, pos1, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
			
			AcceptEntityInput(explosion, "Explode");
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
		}

		for(int i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				static float pos2[3];
				GetClientEyePosition(i, pos2);
				
				// check if we're not hitting a wall
				TR_TraceRayFilter(pos1, pos2, CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_MIST, RayType_EndPoint, Trace_WorldAndBrushes);
				
				// 512 units
				if(GetVectorDistance(pos1, pos2, true) < 524288.0 && !TR_DidHit())
				{
					ScreenFade(i, 1000, 1000, FFADE_OUT, 200, 200, 200, 255);
					ClientCommand(i, "dsp_player %d", GetRandomInt(35, 37));
				}
			}
		}

		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

public void FragGrenade_Precache()
{
	PrecacheModel("models/scp_fixed/frag/w_frag.mdl");
	PrecacheScriptSound("Weapon_Airstrike.Explosion");
}

public bool FragGrenade_Use(int client)
{
	int entity = CreateEntityByName("prop_physics_multiplayer");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "physicsmode", "2");

		static float ang[3], pos[3], vel[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		GetClientEyeAngles(client, ang);
		pos[2] += 63.0;

		GrenadeTrajectory(ang, vel, 1200.0);

		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));

		SetEntityModel(entity, "models/scp_fixed/frag/w_frag.mdl");

		DispatchSpawn(entity);
		TeleportEntity(entity, pos, ang, vel);

		CreateTimer(5.0, FragGrenadeTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	return true;
}

static Action FragGrenadeTimer(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity > MaxClients)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		int flags = (SF_ENVEXPLOSION_REPEATABLE|SF_ENVEXPLOSION_NODECAL|SF_ENVEXPLOSION_NOSOUND|SF_ENVEXPLOSION_RND_ORIENT|SF_ENVEXPLOSION_NOFIREBALLSMOKE|SF_ENVEXPLOSION_NOPARTICLES);
		int explosion = CreateExplosion(client, 700, 350, pos, flags, "taunt_soldier", false);
		
		if (IsValidEntity(explosion))
		{
			AttachParticle(explosion, "asplode_hoodoo", false, 5.0);
			EmitGameSoundToAll("Weapon_Airstrike.Explosion", explosion);
			
			AcceptEntityInput(explosion, "Explode");
			CreateTimer(0.1, Timer_RemoveEntity, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}

static void GrenadeTrajectory(const float angles[3], float velocity[3], float scale)
{
	velocity[0] = Cosine(DegToRad(angles[0])) * Cosine(DegToRad(angles[1])) * scale;
	velocity[1] = Cosine(DegToRad(angles[0])) * Sine(DegToRad(angles[1])) * scale;
	velocity[2] = Sine(DegToRad(angles[0])) * -scale;
}