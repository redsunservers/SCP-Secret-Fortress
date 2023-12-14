#pragma semicolon 1
#pragma newdecls required

static int ClassIndex[MAXPLAYERS+1] = {-1, ...};
static int ProxyTeam[MAXPLAYERS+1];
static float LastChatAt[MAXPLAYERS+1];
static float LastVoiceAt[MAXPLAYERS+1];
static int CanTalkTo[MAXPLAYERS+1][MAXPLAYERS+1];
static float GlobalFor[MAXPLAYERS+1];
static TFClassType DisplayClass[MAXPLAYERS+1];
static TFClassType WeaponClass[MAXPLAYERS+1];
static int CurrentFloor[MAXPLAYERS+1];

methodmap Client
{
	public Client(int client)
	{
		return view_as<Client>(client);
	}

	property int Class
	{
		public get()
		{
			return ClassIndex[view_as<int>(this)];
		}
		public set(int index)
		{
			ClassIndex[view_as<int>(this)] = index;
		}
	}

	property float LastChatAt
	{
		public get()
		{
			return LastChatAt[view_as<int>(this)];
		}
		public set(float time)
		{
			LastChatAt[view_as<int>(this)] = time;
		}
	}

	property float LastVoiceAt
	{
		public get()
		{
			return LastVoiceAt[view_as<int>(this)];
		}
		public set(float time)
		{
			LastVoiceAt[view_as<int>(this)] = time;
		}
	}

	property int ProxyTeam
	{
		public get()
		{
			return ProxyTeam[view_as<int>(this)];
		}
		public set(int team)
		{
			ProxyTeam[view_as<int>(this)] = team;
		}
	}

	property float GlobalChatFor
	{
		public get()
		{
			return GlobalFor[view_as<int>(this)];
		}
		public set(float time)
		{
			GlobalFor[view_as<int>(this)] = time;
		}
	}

	property TFClassType DisplayClass
	{
		public get()
		{
			return DisplayClass[view_as<int>(this)];
		}
		public set(TFClassType class)
		{
			DisplayClass[view_as<int>(this)] = class;
		}
	}

	property TFClassType WeaponClass
	{
		public get()
		{
			return WeaponClass[view_as<int>(this)];
		}
		public set(TFClassType class)
		{
			WeaponClass[view_as<int>(this)] = class;
		}
	}

	property int CurrentFloor
	{
		public get()
		{
			return CurrentFloor[view_as<int>(this)];
		}
		public set(int floor)
		{
			CurrentFloor[view_as<int>(this)] = floor;
		}
	}

	public int CanTalkTo(int target)
	{
		return CanTalkTo[view_as<int>(this)][target];
	}

	public void SetTalkTo(int target, int type)
	{
		CanTalkTo[view_as<int>(this)][target] = type;
	}
	
	public void ResetByDeath()
	{
		this.CurrentFloor = -1;
	}
	
	public void ResetByRound()
	{
		this.Class = -1;

		this.ResetByDeath();
	}
	
	public void ResetByAll()
	{
		this.LastChatAt = 0.0;
		this.LastVoiceAt = 0.0;
		this.ProxyTeam = 0;

		this.ResetByRound();
	}
}