#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <tf2items>
#include <morecolors>
#include <tf2attributes>
#include <dhooks>
#include <tf_econ_data>
#include <tf2utils>
#undef REQUIRE_PLUGIN
#tryinclude <sourcecomms>
#tryinclude <basecomm>
#define REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <sendproxy>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

enum
{
	VoiceManager_Normal = -1,
	VoiceManager_Quieter = 0,
	VoiceManager_Quiet = 1,
	VoiceManager_Loud = 2,
	VoiceManager_Louder = 3
}

native bool OnPlayerAdjustVolume(int caller, int client, int volume);

#define PLUGIN_VERSION			"4.0"
#define PLUGIN_VERSION_REVISION	"custom"
#define PLUGIN_VERSION_FULL		PLUGIN_VERSION ... "." ... PLUGIN_VERSION_REVISION

#define FOLDER_CONFIGS	"configs/scp_sf"
#define PREFIX			"{red}[SCP] {default}"
#define GITHUB_URL		"github.com/redsunservers/SCP-Secret-Fortress"

#define FAR_FUTURE		100000000.0
#define MAXENTITIES		2048

#define TFTeam_Unassigned	0
#define TFTeam_Spectator	1
#define TFTeam_Red			2
#define TFTeam_Blue			3
#define TFTeam_MAX			4

#define CHAR_FULL		"█"
#define CHAR_PARTFULL	"▓"
#define CHAR_PARTEMPTY	"▒"
#define CHAR_EMPTY		"░"

enum
{
	Version,
	
	Achievements,
	ChatHook,
	VoiceHook,
	SendProxy,
	DropItemLimit,
	
	Cvar_MAX
}

ConVar Cvar[Cvar_MAX];

#if defined _basecomm_included
bool BaseComm;
#endif

#if defined _sourcecomms_included
bool SourceComms;
#endif

#include "scp_sf/client.sp"
#include "scp_sf/stocks.sp"

#include "scp_sf/classes.sp"
#include "scp_sf/commands.sp"
#include "scp_sf/configs.sp"
#include "scp_sf/convars.sp"
#include "scp_sf/dhooks.sp"
#include "scp_sf/forwards.sp"
#include "scp_sf/gamemode.sp"
#include "scp_sf/items.sp"
#include "scp_sf/music.sp"
#include "scp_sf/natives.sp"
#include "scp_sf/proxy.sp"
#include "scp_sf/sdkcalls.sp"

#include "scp_sf/classes/human.sp"

#include "scp_sf/gamemode/vip_escape.sp"

public Plugin myinfo =
{
	name		=	"SCP: Secret Fortress",
	author		=	"redsun.tf",
	description	=	"Hopefully not a Secret Lab clone this time!",
	version		=	PLUGIN_VERSION,
	url			=	GITHUB_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	#if defined _SENDPROXYMANAGER_INC_
	MarkNativeAsOptional("SendProxy_Hook");
	MarkNativeAsOptional("SendProxy_HookArrayProp");
	#endif

	MarkNativeAsOptional("OnPlayerAdjustVolume");
	
	Forwards_PluginLoad();
	Natives_PluginLoad();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("scp_sf.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	if(!TranslationPhraseExists("Switch Items"))
		SetFailState("Translation file \"scp_sf.phrases\" is outdated");
	
	#if defined _sourcecomms_included
	SourceComms = LibraryExists("sourcecomms++");
	#endif

	#if defined _basecomm_included
	BaseComm = LibraryExists("basecomm");
	#endif
	
	Classes_PluginStart();
	Commands_PluginStart();
	ConVar_PluginStart();
	DHooks_PluginStart();
	Items_PluginStart();
	SDKCalls_PluginStart();
}

public void OnPluginEnd()
{
	DHooks_PluginEnd();
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _basecomm_included
	if(!BaseComm && StrEqual(name, "basecomm"))
		BaseComm = true;
	#endif

	#if defined _sourcecomms_included
	if(!SourceComms && StrEqual(name, "sourcecomms++"))
		SourceComms = true;
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _basecomm_included
	if(BaseComm && StrEqual(name, "basecomm"))
		BaseComm = false;
	#endif

	#if defined _sourcecomms_included
	if(SourceComms && StrEqual(name, "sourcecomms++"))
		SourceComms = false;
	#endif
}

public void OnMapStart()
{
	DHooks_MapStart();
}

public void OnMapEnd()
{
	Gamemode_MapEnd();
}

public void OnConfigsExecuted()
{
	Configs_ConfigsExecuted();
	ConVar_ConfigsExecuted();
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	DHooks_ClientPutInServer(client);
	Proxy_ClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	Items_ClientDisconnect(client);
	Music_ClientDisconnect(client);

	Client(client).ResetByAll();
}

public void OnGameFrame()
{
	Proxy_GameFrame();
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	Music_PlayerRunCmd(client);
	return Classes_PlayerRunCmd(client, buttons);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	return Proxy_ClientSayCommand(client);
}

public void OnClientSpeaking(int client)
{
	Proxy_ClientSpeaking(client);
}

public void OnClientSpeakingEnd(int client)
{
	Proxy_ClientSpeakingEnd(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	Proxy_EntityCreated(entity, classname);
}

public void OnEntityDestroyed(int entity)
{
	DHooks_EntityDestoryed();
}