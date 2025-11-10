#pragma semicolon 1
#pragma newdecls required

static int BossIndex[MAXPLAYERS+1] = {-1, ...};
static bool Minion[MAXPLAYERS+1];
static bool Sprinting[MAXPLAYERS+1];
static bool Escaped[MAXPLAYERS+1];
static float SprintPower[MAXPLAYERS+1];
static float Stress[MAXPLAYERS+1];
static float LastGameTime[MAXPLAYERS+1];
static bool EyesClosed[MAXPLAYERS+1];
static int ControlProgress[MAXPLAYERS+1];
static float LightPower[MAXPLAYERS+1];
static int KeycardContain[MAXPLAYERS+1];
static int KeycardArmory[MAXPLAYERS+1];
static int KeycardExit[MAXPLAYERS+1];
static int ActionItem[MAXPLAYERS+1] = {-1, ...};
static float AllTalkTimeFor[MAXPLAYERS+1];
static float LastDangerAt[MAXPLAYERS+1];
static int LookingAtPos[MAXPLAYERS+1][(MAXPLAYERS+1) / 32];
static int CanTalkToPos[MAXPLAYERS+1][(MAXPLAYERS+1) / 32];
static int GlowingToPos[MAXPLAYERS+1][(MAXPLAYERS+1) / 32];
static int NoTransmitToPos[MAXPLAYERS+1][(MAXPLAYERS+1) / 32];
static bool SilentTalk[MAXPLAYERS+1];
static bool NoEscape[MAXPLAYERS+1];
static float EscapeTimeAt[MAXPLAYERS+1];
static float LastNoiseAt[MAXPLAYERS+1];
static bool NoViewModel[MAXPLAYERS+1];
static float KeyHintUpdateAt[MAXPLAYERS+1];
static float ActionCooldownFor[MAXPLAYERS+1];
static bool QuietTooltip[MAXPLAYERS+1];

methodmap Client
{
	public Client(int client)
	{
		return view_as<Client>(client);
	}
	
	property int Index
	{
		public get()
		{
			return view_as<int>(this);
		}
	}

	property bool IsBoss
	{
		public get()
		{
			return BossIndex[this.Index] != -1;
		}
	}

	property int Boss
	{
		public get()
		{
			return BossIndex[this.Index];
		}
		public set(int value)
		{
			BossIndex[this.Index] = value;
		}
	}

	property bool Minion
	{
		public get()
		{
			return Minion[this.Index];
		}
		public set(bool value)
		{
			Minion[this.Index] = value;
		}
	}

	property bool Sprinting
	{
		public get()
		{
			return Sprinting[this.Index];
		}
		public set(bool value)
		{
			Sprinting[this.Index] = value;
		}
	}

	property bool Escaped
	{
		public get()
		{
			return Escaped[this.Index];
		}
		public set(bool value)
		{
			Escaped[this.Index] = value;
		}
	}

	// Out of 100.0
	property float SprintPower
	{
		public get()
		{
			return SprintPower[this.Index];
		}
		public set(float value)
		{
			SprintPower[this.Index] = value;
		}
	}

	// Based on 1s per time passed
	property float Stress
	{
		public get()
		{
			return Stress[this.Index];
		}
		public set(float value)
		{
			Stress[this.Index] = value;
		}
	}

	property float LastGameTime
	{
		public get()
		{
			return LastGameTime[this.Index];
		}
		public set(float value)
		{
			LastGameTime[this.Index] = value;
		}
	}

	property bool EyesClosed
	{
		public get()
		{
			return EyesClosed[this.Index];
		}
		public set(bool value)
		{
			EyesClosed[this.Index] = value;
		}
	}

	property int ControlProgress
	{
		public get()
		{
			return ControlProgress[this.Index];
		}
		public set(int value)
		{
			ControlProgress[this.Index] = value;
		}
	}

	// Out of 100.0
	property float LightPower
	{
		public get()
		{
			return LightPower[this.Index];
		}
		public set(float value)
		{
			LightPower[this.Index] = value;
		}
	}

	property int KeycardContain
	{
		public get()
		{
			return KeycardContain[this.Index];
		}
		public set(int value)
		{
			KeycardContain[this.Index] = value;
		}
	}

	property int KeycardArmory
	{
		public get()
		{
			return KeycardArmory[this.Index];
		}
		public set(int value)
		{
			KeycardArmory[this.Index] = value;
		}
	}

	property int KeycardExit
	{
		public get()
		{
			return KeycardExit[this.Index];
		}
		public set(int value)
		{
			KeycardExit[this.Index] = value;
		}
	}
	
	// Item index, -1 for none
	property int ActionItem
	{
		public get()
		{
			return ActionItem[this.Index];
		}
		public set(int value)
		{
			ActionItem[this.Index] = value;
		}
	}

	// Game time
	property float AllTalkTimeFor
	{
		public get()
		{
			return AllTalkTimeFor[this.Index];
		}
		public set(float value)
		{
			AllTalkTimeFor[this.Index] = value;
		}
	}

	// Game time, set in music.sp
	property float LastDangerAt
	{
		public get()
		{
			return LastDangerAt[this.Index];
		}
		public set(float value)
		{
			LastDangerAt[this.Index] = value;
		}
	}

	public bool LookingAt(int target, any value = -1)
	{
		int pos = target / 32;
		int at = target % 32;

		if(value == true)
		{
			LookingAtPos[this.Index][pos] |= (1 << at);
		}
		else if(value == false)
		{
			LookingAtPos[this.Index][pos] &= ~(1 << at);
		}

		return view_as<bool>(LookingAtPos[this.Index][pos] & (1 << at));
	}

	public bool CanTalkTo(int target, any value = -1)
	{
		int pos = target / 32;
		int at = target % 32;

		if(value == true)
		{
			CanTalkToPos[this.Index][pos] |= (1 << at);
		}
		else if(value == false)
		{
			CanTalkToPos[this.Index][pos] &= ~(1 << at);
		}

		return view_as<bool>(CanTalkToPos[this.Index][pos] & (1 << at));
	}

	public bool GlowingTo(int target, any value = -1)
	{
		int pos = target / 32;
		int at = target % 32;

		if(value == true)
		{
			GlowingToPos[this.Index][pos] |= (1 << at);
		}
		else if(value == false)
		{
			GlowingToPos[this.Index][pos] &= ~(1 << at);
		}

		return view_as<bool>(GlowingToPos[this.Index][pos] & (1 << at));
	}

	public bool NoTransmitTo(int target, any value = -1)
	{
		int pos = target / 32;
		int at = target % 32;

		if(value == true)
		{
			NoTransmitToPos[this.Index][pos] |= (1 << at);
		}
		else if(value == false)
		{
			NoTransmitToPos[this.Index][pos] &= ~(1 << at);
		}

		return view_as<bool>(NoTransmitToPos[this.Index][pos] & (1 << at));
	}

	property bool SilentTalk
	{
		public get()
		{
			return SilentTalk[this.Index];
		}
		public set(bool value)
		{
			SilentTalk[this.Index] = value;
		}
	}

	property bool NoEscape
	{
		public get()
		{
			return NoEscape[this.Index];
		}
		public set(bool value)
		{
			NoEscape[this.Index] = value;
		}
	}

	// Game time
	property float EscapeTimeAt
	{
		public get()
		{
			return EscapeTimeAt[this.Index];
		}
		public set(float value)
		{
			EscapeTimeAt[this.Index] = value;
		}
	}

	// Game time
	property float LastNoiseAt
	{
		public get()
		{
			return LastNoiseAt[this.Index];
		}
		public set(float value)
		{
			LastNoiseAt[this.Index] = value;
		}
	}

	property bool NoViewModel
	{
		public get()
		{
			return NoViewModel[this.Index];
		}
		public set(bool value)
		{
			NoViewModel[this.Index] = value;
		}
	}

	// Game time
	property float KeyHintUpdateAt
	{
		public get()
		{
			return KeyHintUpdateAt[this.Index];
		}
		public set(float value)
		{
			KeyHintUpdateAt[this.Index] = value;
		}
	}

	// Game time
	property float ActionCooldownFor
	{
		public get()
		{
			return ActionCooldownFor[this.Index];
		}
		public set(float value)
		{
			ActionCooldownFor[this.Index] = value;
		}
	}

	property bool QuietTooltip
	{
		public get()
		{
			return QuietTooltip[this.Index];
		}
		public set(bool value)
		{
			QuietTooltip[this.Index] = value;
		}
	}
	
	public void ResetByDeath()
	{
		this.Minion = false;
		this.Sprinting = false;
		this.Escaped = false;
		this.SprintPower = 0.0;
		this.Stress = 0.0;
		this.EyesClosed = false;
		this.LightPower = 0.0;
		this.KeycardContain = 0;
		this.KeycardArmory = 0;
		this.KeycardExit = 0;
		this.ActionItem = -1;
		this.AllTalkTimeFor = 0.0;
		this.LastDangerAt = 0.0;
		this.SilentTalk = false;
		this.NoEscape = false;
		this.LastNoiseAt = 0.0;
		this.NoViewModel = false;
		this.ActionCooldownFor = 0.0;
	}
	
	public void ResetByRound()
	{
		this.ControlProgress = 0;
		this.EscapeTimeAt = 0.0;
		this.QuietTooltip = false;
		this.ResetByDeath();
	}
	
	public void ResetByDisconnect()
	{
		this.LastGameTime = 0.0;
		this.KeyHintUpdateAt = 0.0;
		this.ResetByRound();
	}
}