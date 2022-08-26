#pragma semicolon 1
#pragma newdecls required

static const char SCP18Model[] = "models/scp_fixed/scp18/w_scp18.mdl";
static const char SCP18HitSound[] = "weapons/samurai/tf_marked_for_death_impact_01.wav";
static const char SCP18ClientHitSound[] = "weapons/grappling_hook_impact_flesh.wav";
static const char SCP18BreakSound[] = "weapons/ball_buster_break_02.wav";

//static const float SCP18VelocityFactor = 1.08;
static const float SCP18VelocityBoost = 40.0;
static const float SCP18GravityFactor = 0.5;
static const float SCP18GravityAccelTime = 3.0;
static const float SCP18MaxVelocity = 10000.0;
static const float SCP18MaxDamage = 1200.0;
static const float SCP18Lifetime = 30.0;

enum struct SCP18Enum
{
	int EntRef;
	int EntIndex;
	int Thrower;
	int Class;
	int Bounces;
	float SpawnTime;
	float Magnitude;
	float Position[3];
	float Velocity[3];
	int ClientHits[MAXTF2PLAYERS];
}

// list of all scp 18 entities
static ArrayList SCP18List;

// cached convars
bool SCP18FriendlyFire;
float SCP18Gravity;

public void Init_SCP18()
{	
	if(SCP18List != INVALID_HANDLE)
		delete SCP18List;
	
	SCP18List = new ArrayList(sizeof(SCP18Enum));
	
	PrecacheSound(SCP18HitSound, true);
	PrecacheSound(SCP18ClientHitSound, true);
	PrecacheSound(SCP18BreakSound, true);
}

// temporary storage for the trace... thanks sourcemod :(
SCP18Enum SCP18Trace;

float SCP18Damage;
float SCP18Volume;
float SCP18Magnitude;
int SCP18Pitch;

public Action Timer_SCP18Damage(Handle timer, DataPack pack)
{
	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	int entindex = EntRefToEntIndex(pack.ReadCell());
	if ((entindex > MaxClients) && IsValidClient(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		int thrower = pack.ReadCell();
		float damage = pack.ReadFloat();
		SDKHook_DealDamage(client, entindex, thrower, damage, DMG_CLUB);
	}

	return Plugin_Continue;
}

public bool SCP18_Trace(int entity, int mask)
{
	if (entity > 0 && entity <= MaxClients)
	{
		// only deal damage to a client once per bounce trajectory
		if (SCP18Trace.ClientHits[entity] != SCP18Trace.Bounces)
		{
			if ((entity == SCP18Trace.Thrower) || SCP18FriendlyFire || !IsFriendly(Client[entity].Class, SCP18Trace.Class) || IsFakeClient(entity))
			{		
				// NOTE: Killing players during OnGameTrace will cause a bizarre and misleading crash!
				// Hence they are instead killed via a timer. This took HOURS to figure out
				
				//SDKHooks_TakeDamage(entity, SCP18Trace.EntIndex, SCP18Trace.Thrower, SCP18Damage, DMG_CLUB);
				
				DataPack pack;
				CreateDataTimer(0.1, Timer_SCP18Damage, pack, TIMER_FLAG_NO_MAPCHANGE);
				pack.WriteCell(GetClientUserId(entity));
				pack.WriteCell(SCP18Trace.EntRef);
				pack.WriteCell(SCP18Trace.Thrower);
				pack.WriteFloat(SCP18Damage);
				
				SCP18Trace.ClientHits[entity] = SCP18Trace.Bounces;
				
				EmitSoundToAll(SCP18ClientHitSound, entity, SNDCHAN_BODY, SNDLEVEL_NORMAL, _, SCP18Volume, SCP18Pitch);	
			}
		}
	}
	
	// keep going
	return true;
}

public bool SCP18_TraceWorld(int entity, int mask)
{
	// world
	if (!entity)
		return true;
	
	// If its not a brush entity, just pass through it
	char buffer[10];
	if ((GetEntityClassname(entity, buffer, sizeof(buffer)) && (strncmp(buffer, "func_", 5, false)))) 
		return false;
	
	if (SCP18Magnitude < 1000.0)
	{
		// Bounce off brush entities at low velocity
		return true;
	}

	if (!strncmp(buffer, "func_door", 9, false))
	{
		// If we hit a door entity at high velocity, try destroy or force it open
		if (!DestroyOrOpenDoor(entity))
		{	
			// *Don't* pass through if we couldn't destroy or force open
			// This allows it to stay trapped in a elevator	
			return true; 
		}
	}

	// Pass through...
	return false;
}

public void SCP18_TryTouchTeleport(float mins[3], float maxs[3], float dest[3])
{
	int count = SCP18List.Length;
	
	for (int i = 0; i < count; i++)
	{
		SCP18Enum scp18;
		SCP18List.GetArray(i, scp18);
		
		if (IsPointTouchingBox(scp18.Position, mins, maxs))
		{
			scp18.EntIndex = EntRefToEntIndex(scp18.EntRef);
			if (scp18.EntIndex > MaxClients)
			{
				TeleportEntity(scp18.EntIndex, dest, NULL_VECTOR, NULL_VECTOR);
				CopyVector(dest, scp18.Position);
				SCP18List.SetArray(i, scp18);
			}
		}
	}
}

public void SCP18_Tick()
{
	if (SCP18List == INVALID_HANDLE)
		return;
		
	// faster to cache this off
	SCP18FriendlyFire = CvarFriendlyFire.BoolValue;
	SCP18Gravity = CvarGravity.FloatValue;
	
	float gravity[3] = { 0.0, 0.0, 0.0 };
	gravity[2] = SCP18Gravity * -SCP18GravityFactor;
	int count = SCP18List.Length;
	float tickinterval = GetTickInterval();
	float time = GetGameTime();
				
	// go backwards as we might delete entries as we go
	for (int i = count-1; i >= 0; i--)
	{
		SCP18Enum scp18;
		SCP18List.GetArray(i, scp18);
		
		scp18.EntIndex = EntRefToEntIndex(scp18.EntRef);
		
		// no longer exists? get rid of it
		if (scp18.EntIndex <= MaxClients)
		{
			SCP18List.Erase(i);
			continue;
		}
		
		// if we are at max velocity, check if we have exceeded our lifetime
		if (scp18.Magnitude == SCP18MaxVelocity && ((scp18.SpawnTime + SCP18Lifetime) < time))
		{
			EmitSoundToAll(SCP18BreakSound, scp18.EntIndex, SNDCHAN_AUTO, SNDLEVEL_NORMAL, _, SNDVOL_NORMAL);
			CreateTimer(0.1, Timer_RemoveEntity, scp18.EntRef, TIMER_FLAG_NO_MAPCHANGE);
			SCP18List.Erase(i);
			continue;
		}
		
		float position[3], nextposition[3], hitposition[3], hitnormal[3], velocity[3], direction[3], reflection[3];
		
		CopyVector(scp18.Position, position);
		CopyVector(scp18.Velocity, velocity);
		
		// apply gravity on throw only
		if (scp18.Bounces == 0)
		{
			// slowly apply it
			float gravityaccel = time - scp18.SpawnTime;
			if (gravityaccel > SCP18GravityAccelTime)
				gravityaccel = SCP18GravityAccelTime;
			gravityaccel /= SCP18GravityAccelTime;
			
			float newgravity[3];
			CopyVector(gravity, newgravity);
			ScaleVector(newgravity, gravityaccel);
			AddVectors(velocity, newgravity, velocity);
		}
		
		ScaleVector(velocity, tickinterval);		
		AddVectors(position, velocity, nextposition);
		
		// trace from current position to next predicted position, ignore any players
		SCP18Magnitude = scp18.Magnitude; // store this for the trace
		TR_TraceRayFilter(position, nextposition, MASK_SOLID, RayType_EndPoint, SCP18_TraceWorld);
		
		if (TR_DidHit())
		{
			TR_GetEndPosition(hitposition);
			TR_GetPlaneNormal(INVALID_HANDLE, hitnormal);
			
			// disappear if we hit the sky
			if (TR_GetSurfaceFlags() & SURF_SKY)
			{
				AcceptEntityInput(scp18.EntIndex, "Kill");
				SCP18List.Erase(i);
				continue;
			}		
					
			// calculate reflection from the hit point
			SubtractVectors(nextposition, position, direction);
			NormalizeVector(direction, direction);
			ScaleVector(hitnormal, GetVectorDotProduct(direction, hitnormal) * 2.0);		
			SubtractVectors(direction, hitnormal, reflection);
						
			scp18.Bounces++;					

			// gain some speed depending on how fast we are currently going	
			// -- a fixed amount seems to work better
			//scp18.Magnitude *= RemapValueInRange(scp18.Magnitude, 0.0, SCP18MaxVelocity, SCP18VelocityFactor, 1.0);	
			scp18.Magnitude += SCP18VelocityBoost;
			
			if (scp18.Magnitude > SCP18MaxVelocity) // don't go too insane!
				scp18.Magnitude = SCP18MaxVelocity;
				
			ScaleVector(reflection, scp18.Magnitude);	
			CopyVector(hitposition, scp18.Position);
			CopyVector(reflection, scp18.Velocity);
			
			TeleportEntity(scp18.EntIndex, hitposition, NULL_VECTOR, reflection);		
			
			EmitSoundToAll(SCP18HitSound, scp18.EntIndex, SNDCHAN_BODY, SNDLEVEL_NORMAL, _, SNDVOL_NORMAL);
		}
		else
		{
			CopyVector(nextposition, scp18.Position);
			CopyVector(nextposition, hitposition);
			
			// keep going in straight line
			TeleportEntity(scp18.EntIndex, nextposition, NULL_VECTOR, scp18.Velocity);
		}
		
		// only deal damage after 1st bounce
		if (scp18.Bounces > 0)
		{		
			// copy into a temporary global variable
			SCP18List.GetArray(i, SCP18Trace);
			// pre calculate damage + volume
			float Ratio = SCP18Trace.Magnitude / SCP18MaxVelocity;
			SCP18Damage = SCP18MaxDamage * Ratio;
			SCP18Volume = LerpValue(Ratio, 0.3, 1.0);
			SCP18Pitch = RoundFloat(LerpValue(Ratio, 85.0, 115.0));
			
			// redo the trace to damage players, with the possibly truncated end position from the trace before
			TR_TraceRayFilter(position, hitposition, MASK_SOLID, RayType_EndPoint, SCP18_Trace);
			
			// copy over any client hits
			for (int j = 1; j <= MaxClients; j++)
				scp18.ClientHits[j] = SCP18Trace.ClientHits[j];				
		}
		
		SCP18List.SetArray(i, scp18);
	}
}

public bool SCP18_Button(int client, int weapon, int &buttons, int &holding)
{
	if(!holding && !Items_InDelayedAction(client))
	{
		bool short = view_as<bool>(buttons & IN_ATTACK2);
		if(short || (buttons & IN_ATTACK))
		{
			holding = short ? IN_ATTACK2 : IN_ATTACK;

			// remove after a delay so the viewmodel throw animation can play out
			Items_StartDelayedAction(client, 0.3, Items_GrenadeAction, client);

			ViewModel_SetAnimation(client, "use");
			Config_DoReaction(client, "throwgrenade");		

			int entity = CreateEntityByName("prop_dynamic");
			if(IsValidEntity(entity))
			{
				DispatchKeyValue(entity, "solid", "0");

				static float ang[3], pos[3], vel[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				GetClientEyeAngles(client, ang);
				pos[2] += 63.0;

				Items_GrenadeTrajectory(ang, vel, 300.0);

				if(short)
					ScaleVector(vel, 0.25);

				SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntProp(entity, Prop_Data, "m_iHammerID", Client[client].Class);		

				SetEntityModel(entity, SCP18Model);

				DispatchSpawn(entity);
				
				// allow it to move, smoothly
				SetEntityMoveType(entity, MOVETYPE_NOCLIP);		
				SetEntityFlags(entity, GetEntityFlags(entity) & (~FL_STATICPROP));
				
				// sets the kill icon
				SetVariantString("classname deflect_ball"); 
				AcceptEntityInput(entity, "AddOutput");				
				
				TeleportEntity(entity, pos, ang, vel);
				
				SCP18Enum scp18;
				scp18.EntRef = EntIndexToEntRef(entity);
				scp18.EntIndex = entity;
				scp18.Thrower = client;
				scp18.SpawnTime = GetGameTime();
				scp18.Bounces = 0;
				CopyVector(pos, scp18.Position);
				CopyVector(vel, scp18.Velocity);
				scp18.Magnitude = NormalizeVector(vel, vel);
				scp18.Class = Client[client].Class;
				for (int i = 1; i <= MaxClients; i++)
					scp18.ClientHits[i] = 0;		
				SCP18List.PushArray(scp18);
			}
		}
	}
	
	return false;
}