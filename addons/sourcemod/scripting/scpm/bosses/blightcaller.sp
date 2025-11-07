#pragma semicolon 1
#pragma newdecls required

static const char Downloads[][] =
{
	"models/freak_fortress_2/blightcaller_remade/blightcaller.dx80.vtx",
	"models/freak_fortress_2/blightcaller_remade/blightcaller.dx90.vtx",
	"models/freak_fortress_2/blightcaller_remade/blightcaller.mdl",
	"models/freak_fortress_2/blightcaller_remade/blightcaller.phy",
	"models/freak_fortress_2/blightcaller_remade/blightcaller.vvd",
	"materials/freak_fortress_2/blightcaller_remade/lantern.vmt",
	"materials/freak_fortress_2/blightcaller_remade/lantern.vtf",
	"materials/freak_fortress_2/blightcaller_remade/pick.vmt",
	"materials/freak_fortress_2/blightcaller_remade/pick.vtf",
	"materials/freak_fortress_2/blightcaller_remade/backpack1.vmt",
	"materials/freak_fortress_2/blightcaller_remade/backpack1.vtf",
	"materials/freak_fortress_2/blightcaller_remade/backpack2.vmt",
	"materials/freak_fortress_2/blightcaller_remade/backpack2.vtf",
	"materials/freak_fortress_2/blightcaller_remade/backpack3.vmt",
	"materials/freak_fortress_2/blightcaller_remade/backpack3.vtf",
	"materials/freak_fortress_2/blightcaller_remade/beak.vmt",
	"materials/freak_fortress_2/blightcaller_remade/beak.vtf",
	"materials/freak_fortress_2/blightcaller_remade/blightcaller.vmt",
	"materials/freak_fortress_2/blightcaller_remade/blightcaller.vtf",
	"materials/freak_fortress_2/blightcaller_remade/blightcaller_head.vmt",
	"materials/freak_fortress_2/blightcaller_remade/blightcaller_head.vtf",
	"materials/freak_fortress_2/blightcaller_remade/gasmask.vmt",
	"materials/freak_fortress_2/blightcaller_remade/gasmask.vtf",
	"materials/freak_fortress_2/blightcaller_remade/green.vtf",
	"materials/freak_fortress_2/blightcaller_remade/hat.vmt",
	"materials/freak_fortress_2/blightcaller_remade/hat.vtf",
	"materials/freak_fortress_2/blightcaller_remade/invulnfx_green.vmt",
	"materials/freak_fortress_2/scp_173/scp173_rage_overlay1.vmt",
	"materials/freak_fortress_2/scp_173/scp173_rage_overlay1.vtf",
	"sound/scpm/blightcaller/ambient.mp3",
	"sound/scpm/blightcaller/scare.mp3"
};

static const char PlayerModel[] = "models/freak_fortress_2/blightcaller_remade/blightcaller.mdl";
static const char JumpscareOverlay[] = "freak_fortress_2/scp_173/scp173_rage_overlay1";
static const char AmbientSound[] = "#scpm/blightcaller/ambient.mp3";
static const char JumpscareSound[] = "scpm/blightcaller/scare.mp3";
static int BossIndex;

static int CurrentTarget;
static ArrayList TeleLocations;
static Handle TeleportTimer;
static bool DoneJumpscare;

public bool Blightcaller_Precache(int index)
{
	BossIndex = index;
	
	PrecacheModel(PlayerModel);
	PrecacheSound(AmbientSound);
	PrecacheSound(JumpscareSound);
	MultiToDownloadsTable(Downloads, sizeof(Downloads));
	return true;
}

public void Blightcaller_Create(int client)
{
	Default_Create(client);
	
	if(!TeleLocations)
		TeleLocations = new ArrayList(3);
}

public TFClassType Blightcaller_TFClass()
{
	return TFClass_Medic;
}

public void Blightcaller_Spawn(int client)
{
	if(!GoToNamedSpawn(client, "scp_spawn_049"))
		Default_Spawn(client);
}

public void Blightcaller_Equip(int client, bool weapons)
{
	Default_Equip(client, weapons);
	Attrib_Set(client, "healing received penalty", 0.33);

	SetVariantString(PlayerModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");

	if(weapons)
	{
		int entity = Items_GiveCustom(client, 30758, "tf_weapon_bonesaw", false);
		if(entity != -1)
		{
			Attrib_Set(entity, "crit mod disabled", 0.0);
			Attrib_Set(entity, "max health additive bonus", 150.0);
			Attrib_Set(entity, "move speed penalty", 0.7);
			Attrib_Set(entity, "damage force reduction", 0.8);
			Attrib_Set(entity, "cancel falling damage", 1.0);
			Attrib_Set(entity, "SET BONUS: special dsp", 15.0);
			Attrib_Set(entity, "airblast vulnerability multiplier", 0.8);
			Attrib_Set(entity, "mod weapon blocks healing", 1.0);

			TF2U_SetPlayerActiveWeapon(client, entity);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
		}

		SetEntityHealth(client, 300);
		
		Human_ToggleFlashlight(client);
	}
}

public void Blightcaller_PlayerDeath(int client, bool &fakeDeath)
{
	PlayDeathAnimation(client, client, "dieviolent", _, 2.0, false, PlayerModel);
}

public void Blightcaller_Remove(int client)
{
	Default_Remove(client);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(Client(client).Boss == BossIndex && i != client)
			return;
	}

	CurrentTarget = 0;
	DoneJumpscare = false;
	delete TeleLocations;
	delete TeleportTimer;
}

public float Blightcaller_ChaseTheme(int client, char theme[PLATFORM_MAX_PATH], int victim, bool &infinite, float &volume)
{
	if(client != victim && victim != CurrentTarget)
	{
		ShowQuietTooltop(victim);
		return 0.0;
	}

	strcopy(theme, sizeof(theme), AmbientSound);
	infinite = true;
	return 206.5;
}

public Action Blightcaller_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(CurrentTarget == attacker)
		damage *= 0.1;
	
	Default_TakeDamage(client, attacker, inflictor, damage, damagetype, weapon, damageForce, damagePosition, damagecustom, critType);
	return Plugin_Changed;
}

public Action Blightcaller_DealDamage(int client, int victim, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom, CritType &critType)
{
	if(damagecustom != TF_CUSTOM_BLEEDING)
	{
		if(TF2_IsPlayerInCondition(victim, TFCond_Plague) || SCP714_IsWearing(victim))
		{
			// Wearing SCP-714, resists plague
			damage *= 0.1;
			return Plugin_Changed;
		}

		TF2_AddCondition(victim, TFCond_Plague, _, client);
		ToggleZombie(victim, true);
	}
	
	return Plugin_Continue;
}

public Action Blightcaller_PlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(Client(client).KeyHintUpdateAt < GetGameTime())
	{
		Client(client).KeyHintUpdateAt = GetGameTime() + 0.5;

		if(!CurrentTarget || !IsClientInGame(CurrentTarget) || !IsPlayerAlive(CurrentTarget))
		{
			CurrentTarget = 0;
			DoneJumpscare = false;

			for(int target = 1; target <= MaxClients; target++)
			{
				if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == TFTeam_Humans)
				{
					if(CurrentTarget)
					{
						// Prio highest stress target
						if(Client(CurrentTarget).Stress > Client(target).Stress)
							continue;
					}
					
					CurrentTarget = target;
				}
			}
		}

		if(CurrentTarget)
		{
			if(!DoneJumpscare && Client(CurrentTarget).LookingAt(client) && !SCP714_IsWearing(CurrentTarget))
			{
				DoneJumpscare = true;
				
				SetVariantString(JumpscareOverlay);
				AcceptEntityInput(CurrentTarget, "SetScriptOverlayMaterial", CurrentTarget, CurrentTarget);
				
				BfWrite msg = view_as<BfWrite>(StartMessageOne("Fade", CurrentTarget));
				msg.WriteShort(100);
				msg.WriteShort(250);	// 0.5s * 500
				msg.WriteShort(0x0001);
				msg.WriteByte(64);
				msg.WriteByte(0);
				msg.WriteByte(0);
				msg.WriteByte(255);
				EndMessage();

				CreateTimer(0.5, Timer_RemoveOverlay, GetClientUserId(CurrentTarget), TIMER_FLAG_NO_MAPCHANGE);

				EmitSoundToClient(CurrentTarget, JumpscareSound);
			}
			
			// Create tele locations if target is far away from previous spot
			float lastPos[3], newPos[3];

			int length = TeleLocations.Length;
			if(length)
				TeleLocations.GetArray(length - 1, lastPos);
			
			GetClientAbsOrigin(CurrentTarget, newPos);
			if(GetVectorDistance(newPos, lastPos, true) > 999999.0)
			{
				if(!IsPointTeleporter(newPos, {-24.0, -24.0, 0.0}, {24.0, 24.0, 82.0}))
					TeleLocations.PushArray(newPos);
			}
		}

		if(!Client(client).ControlProgress)
		{
			if(!(buttons & IN_SCORE))
			{
				static char buffer[64];
				Format(buffer, sizeof(buffer), "%T", "Blightcaller Controls", client);
				PrintKeyHintText(client, buffer);
			}
		}
	}

	return Plugin_Continue;
}

public void Blightcaller_ActionButton(int client)
{
	SetGlobalTransTarget(client);

	static const int required = 3;

	int length = TeleLocations.Length;
	if(length >= required && !TeleportTimer)
	{
		if(GetEntityFlags(client) & (FL_ONGROUND|FL_DUCKING))
		{
			float pos[3];
			TeleLocations.GetArray(length - required, pos);
			TeleLocations.Clear();

			FakeClientCommand(client, "taunt");
			TF2_AddCondition(client, TFCond_UberchargedCanteen, 4.0);
			TF2_AddCondition(client, TFCond_MegaHeal, 3.0);
			TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, 3.0);
			
			DataPack pack;
			TeleportTimer = CreateDataTimer(3.0, BlightTeleportTimer, pack);
			pack.WriteCell(GetClientUserId(client));
			pack.WriteFloat(pos[0]);
			pack.WriteFloat(pos[1]);
			pack.WriteFloat(pos[2]);
			
			CreateParticleEffect("lava_fireball", pos, _, 4.0, false);
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			CreateParticleEffect("lava_fireball", pos, _, 4.0, false);
		}
		else
		{
			PrintCenterText(client, "%t", "Blightcaller Tele Duck");
			ClientCommand(client, "playgamesound items/suitchargeno1.wav");
		}
	}
	else
	{
		PrintCenterText(client, "%t", "Blightcaller Tele Early", length, 3);
		ClientCommand(client, "playgamesound items/suitchargeno1.wav");
	}
}

public bool Blightcaller_GlowTarget(int client, int target)
{
	if(CurrentTarget != target && GetClientTeam(client) != GetClientTeam(target) && !TF2_IsPlayerInCondition(target, TFCond_Plague) && (Client(target).LastNoiseAt + 1.0) < GetGameTime() && !TF2_IsPlayerInCondition(target, TFCond_MarkedForDeath))
	{
		Client(target).NoTransmitTo(client, true);
	}
	else
	{
		Client(target).NoTransmitTo(client, false);
	}

	return CurrentTarget == target;
}

public void Blightcaller_PlayerKilled(int client, int victim, bool fakeDeath)
{
	if(!fakeDeath)
		Bosses_DisplayEntry(victim, "Blightcaller Entry");
}

static Action BlightTeleportTimer(Handle timer, DataPack pack)
{
	TeleportTimer = null;

	pack.Reset();
	int client = GetClientOfUserId(pack.ReadCell());
	if(client)
	{
		float pos[3];
		for(int i; i < sizeof(pos); i++)
		{
			pos[i] = pack.ReadFloat();
		}

		SetEntProp(client, Prop_Send, "m_bDucked", true);
		SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
		TeleportEntity(client, pos);
	}

	return Plugin_Continue;
}
