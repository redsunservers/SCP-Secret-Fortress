#pragma semicolon 1
#pragma newdecls required

static const char SCP018Model[] = "models/scp_fixed/scp018/w_scp018.mdl";
static const char SCP018HitSound[] = "weapons/samurai/tf_marked_for_death_impact_01.wav";
static const char SCP018ClientHitSound[] = "weapons/grappling_hook_impact_flesh.wav";
static const char SCP018BreakSound[] = "weapons/ball_buster_break_02.wav";

//static const float SCP018VelocityFactor = 1.08;
static const float SCP018VelocityBoost = 40.0;
static const float SCP018GravityFactor = 0.5;
static const float SCP018GravityAccelTime = 3.0;
static const float SCP018MaxVelocity = 10000.0;
static const float SCP018MaxDamage = 1200.0;
static const float SCP018Lifetime = 30.0;

enum struct SCP018Enum
{
	int EntRef;
	int EntIndex;
	int Thrower;
	int Bounces;
	float SpawnTime;
	float Magnitude;
	float Position[3];
	float Velocity[3];
	int ClientHits[MAXPLAYERS + 1];
}

// list of all scp 18 entities
static ArrayList SCP018List;

// cached convars
static float SCP018Gravity;

public void SCP018_Precache()
{
	if(SCP018List != INVALID_HANDLE)
		delete SCP018List;
	
	SCP018List = new ArrayList(sizeof(SCP018Enum));
	
	PrecacheModel(SCP018Model);
	PrecacheSound(SCP018HitSound);
	PrecacheSound(SCP018ClientHitSound);
	PrecacheSound(SCP018BreakSound);
}

// temporary storage for the trace... thanks sourcemod :(
static SCP018Enum SCP018Trace;

static float SCP018Damage;
static float SCP018Volume;
static float SCP018Magnitude;
static int SCP018Pitch;

static Action Timer_SCP018Damage(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int entindex = EntRefToEntIndex(pack.ReadCell());
	if ((entindex > MaxClients) && client && IsPlayerAlive(client))
	{
		int thrower = pack.ReadCell();
		float damage = pack.ReadFloat();
		SDKHooks_TakeDamage(client, entindex, thrower, damage, DMG_CLUB, .bypassHooks = false);
		if(GetClientHealth(client) < 1)
			Bosses_DisplayEntry(client, "SCP018 Entry");
	}

	return Plugin_Continue;
}

static bool SCP018_Trace(int entity, int mask)
{
	if (entity > 0 && entity <= MaxClients)
	{
		// only deal damage to a client once per bounce trajectory
		if (SCP018Trace.ClientHits[entity] != SCP018Trace.Bounces)
		{
			// NOTE: Killing players during OnGameTrace will cause a bizarre and misleading crash!
			// Hence they are instead killed via a timer. This took HOURS to figure out
			
			//SDKHooks_TakeDamage(entity, SCP018Trace.EntIndex, SCP018Trace.Thrower, SCP018Damage, DMG_CLUB);
			
			DataPack pack;
			CreateDataTimer(0.1, Timer_SCP018Damage, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(GetClientUserId(entity));
			pack.WriteCell(SCP018Trace.EntRef);
			pack.WriteCell(SCP018Trace.Thrower);
			pack.WriteFloat(SCP018Damage);
			
			SCP018Trace.ClientHits[entity] = SCP018Trace.Bounces;
			
			EmitSoundToAll(SCP018ClientHitSound, entity, SNDCHAN_BODY, SNDLEVEL_NORMAL, _, SCP018Volume, SCP018Pitch);	
		}
	}
	
	// keep going
	return true;
}

static bool SCP018_TraceWorld(int entity, int mask)
{
	// world
	if (!entity)
		return true;
	
	// If its not a brush entity, just pass through it
	char buffer[10];
	if ((GetEntityClassname(entity, buffer, sizeof(buffer)) && (strncmp(buffer, "func_", 5, false)))) 
		return false;
	
	if (SCP018Magnitude < 1000.0)
	{
		// Bounce off brush entities at low velocity
		return true;
	}

	if (!strncmp(buffer, "func_door", 9, false))
	{
		// *Don't* pass through if we couldn't destroy or force open
		// This allows it to stay trapped in a elevator	
		return true; 
	}

	// Pass through...
	return false;
}
/*
void SCP018_TryTouchTeleport(float mins[3], float maxs[3], float dest[3])
{
	int count = SCP018List.Length;
	
	for (int i = 0; i < count; i++)
	{
		SCP018Enum scp018;
		SCP018List.GetArray(i, scp018);
		
		if (IsPointTouchingBox(scp018.Position, mins, maxs))
		{
			scp018.EntIndex = EntRefToEntIndex(scp018.EntRef);
			if (scp018.EntIndex > MaxClients)
			{
				TeleportEntity(scp018.EntIndex, dest, NULL_VECTOR, NULL_VECTOR);
				CopyVector(dest, scp018.Position);
				SCP018List.SetArray(i, scp018);
			}
		}
	}
}
*/
void SCP018_GameFrame()
{
	if (SCP018List == INVALID_HANDLE)
		return;
		
	// faster to cache this off
	SCP018Gravity = Cvar[Gravity].FloatValue;
	
	float gravity[3] = { 0.0, 0.0, 0.0 };
	gravity[2] = SCP018Gravity * -SCP018GravityFactor;
	int count = SCP018List.Length;
	float tickinterval = GetTickInterval();
	float time = GetGameTime();
				
	// go backwards as we might delete entries as we go
	for (int i = count-1; i >= 0; i--)
	{
		SCP018Enum scp018;
		SCP018List.GetArray(i, scp018);
		
		scp018.EntIndex = EntRefToEntIndex(scp018.EntRef);
		
		// no longer exists? get rid of it
		if (scp018.EntIndex <= MaxClients)
		{
			SCP018List.Erase(i);
			continue;
		}
		
		// if we are at max velocity, check if we have exceeded our lifetime
		if (scp018.Magnitude == SCP018MaxVelocity && ((scp018.SpawnTime + SCP018Lifetime) < time))
		{
			EmitSoundToAll(SCP018BreakSound, scp018.EntIndex, SNDCHAN_AUTO, SNDLEVEL_NORMAL, _, SNDVOL_NORMAL);
			CreateTimer(0.1, Timer_RemoveEntity, scp018.EntRef, TIMER_FLAG_NO_MAPCHANGE);
			SCP018List.Erase(i);
			continue;
		}
		
		float position[3], nextposition[3], hitposition[3], hitnormal[3], velocity[3], direction[3], reflection[3];
		
		CopyVector(scp018.Position, position);
		CopyVector(scp018.Velocity, velocity);
		
		// apply gravity on throw only
		if (scp018.Bounces == 0)
		{
			// slowly apply it
			float gravityaccel = time - scp018.SpawnTime;
			if (gravityaccel > SCP018GravityAccelTime)
				gravityaccel = SCP018GravityAccelTime;
			gravityaccel /= SCP018GravityAccelTime;
			
			float newgravity[3];
			CopyVector(gravity, newgravity);
			ScaleVector(newgravity, gravityaccel);
			AddVectors(velocity, newgravity, velocity);
		}
		
		ScaleVector(velocity, tickinterval);		
		AddVectors(position, velocity, nextposition);
		
		// trace from current position to next predicted position, ignore any players
		SCP018Magnitude = scp018.Magnitude; // store this for the trace
		TR_TraceRayFilter(position, nextposition, MASK_SOLID, RayType_EndPoint, SCP018_TraceWorld);
		
		if (TR_DidHit())
		{
			TR_GetEndPosition(hitposition);
			TR_GetPlaneNormal(INVALID_HANDLE, hitnormal);
			
			// disappear if we hit the sky
			if (TR_GetSurfaceFlags() & SURF_SKY)
			{
				AcceptEntityInput(scp018.EntIndex, "Kill");
				SCP018List.Erase(i);
				continue;
			}		
					
			// calculate reflection from the hit point
			SubtractVectors(nextposition, position, direction);
			NormalizeVector(direction, direction);
			ScaleVector(hitnormal, GetVectorDotProduct(direction, hitnormal) * 2.0);		
			SubtractVectors(direction, hitnormal, reflection);
						
			scp018.Bounces++;					

			// gain some speed depending on how fast we are currently going	
			// -- a fixed amount seems to work better
			//scp018.Magnitude *= RemapValueInRange(scp018.Magnitude, 0.0, SCP018MaxVelocity, SCP018VelocityFactor, 1.0);	
			scp018.Magnitude += SCP018VelocityBoost;
			
			if (scp018.Magnitude > SCP018MaxVelocity) // don't go too insane!
				scp018.Magnitude = SCP018MaxVelocity;
				
			ScaleVector(reflection, scp018.Magnitude);	
			CopyVector(hitposition, scp018.Position);
			CopyVector(reflection, scp018.Velocity);
			
			TeleportEntity(scp018.EntIndex, hitposition, NULL_VECTOR, reflection);		
			
			EmitSoundToAll(SCP018HitSound, scp018.EntIndex, SNDCHAN_BODY, SNDLEVEL_NORMAL, _, SNDVOL_NORMAL);
		}
		else
		{
			CopyVector(nextposition, scp018.Position);
			CopyVector(nextposition, hitposition);
			
			// keep going in straight line
			TeleportEntity(scp018.EntIndex, nextposition, NULL_VECTOR, scp018.Velocity);
		}
		
		// only deal damage after 1st bounce
		if (scp018.Bounces > 0)
		{		
			// copy into a temporary global variable
			SCP018List.GetArray(i, SCP018Trace);
			// pre calculate damage + volume
			float Ratio = SCP018Trace.Magnitude / SCP018MaxVelocity;
			SCP018Damage = SCP018MaxDamage * Ratio;
			SCP018Volume = LerpValue(Ratio, 0.3, 1.0);
			SCP018Pitch = RoundFloat(LerpValue(Ratio, 85.0, 115.0));
			
			// redo the trace to damage players, with the possibly truncated end position from the trace before
			TR_TraceRayFilter(position, hitposition, MASK_SOLID, RayType_EndPoint, SCP018_Trace);
			
			// copy over any client hits
			for (int j = 1; j <= MaxClients; j++)
				scp018.ClientHits[j] = SCP018Trace.ClientHits[j];				
		}
		
		SCP018List.SetArray(i, scp018);
	}
}

public bool SCP018_Use(int client)
{
	int entity = CreateEntityByName("prop_dynamic");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "solid", "0");

		static float ang[3], pos[3], vel[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		GetClientEyeAngles(client, ang);
		pos[2] += 63.0;

		GrenadeTrajectory(ang, vel, 300.0);

		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));

		SetEntityModel(entity, SCP018Model);

		DispatchSpawn(entity);
		
		// allow it to move, smoothly
		SetEntityMoveType(entity, MOVETYPE_NOCLIP);		
		SetEntityFlags(entity, GetEntityFlags(entity) & (~FL_STATICPROP));
		
		// sets the kill icon
		SetVariantString("classname deflect_ball"); 
		AcceptEntityInput(entity, "AddOutput");				
		
		TeleportEntity(entity, pos, ang, vel);
		
		SCP018Enum scp018;
		scp018.EntRef = EntIndexToEntRef(entity);
		scp018.EntIndex = entity;
		scp018.Thrower = client;
		scp018.SpawnTime = GetGameTime();
		scp018.Bounces = 0;
		CopyVector(pos, scp018.Position);
		CopyVector(vel, scp018.Velocity);
		scp018.Magnitude = NormalizeVector(vel, vel);
		for (int i = 1; i <= MaxClients; i++)
			scp018.ClientHits[i] = 0;		
		SCP018List.PushArray(scp018);
	}
	return true;
}

static void GrenadeTrajectory(const float angles[3], float velocity[3], float scale)
{
	velocity[0] = Cosine(DegToRad(angles[0])) * Cosine(DegToRad(angles[1])) * scale;
	velocity[1] = Cosine(DegToRad(angles[0])) * Sine(DegToRad(angles[1])) * scale;
	velocity[2] = Sine(DegToRad(angles[0])) * -scale;
}