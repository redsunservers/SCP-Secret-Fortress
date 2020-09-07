#if defined _scpsf_included
  #endinput
#endif
#define _scpsf_included

enum SCPClass
{
	SCPClass_Spec = 0,

	SCPClass_DBoi,
	SCPClass_Chaos,

	SCPClass_Scientist,
	SCPClass_Guard,
	SCPClass_MTF,
	SCPClass_MTF2,
	SCPClass_MTFS,
	SCPClass_MTF3,

	SCPClass_049,
	SCPClass_0492,
	SCPClass_079,
	SCPClass_096,
	SCPClass_106,
	SCPClass_173,
	SCPClass_1732,
	SCPClass_939,
	SCPClass_9392,
	SCPClass_3008,
	SCPClass_Stealer
}

/**
 * Get the client's current class
 *
 * @param client 	Client index
 *
 * @return		Class the client is currently playing as
 */
native SCPClass SCPSF_GetClientClass(int client);

forward void SCPSF_OnEscape(int client);

forward void SCPSF_OnChatMessage(int client, char[] name, char[] message);

public SharedPlugin __pl_SCPSF =
{
	name = "scp_sf",
	file = "scp_sf.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_SCPSF_SetNTVOptional()
{
	MarkNativeAsOptional("SCPSF_GetClientClass");
}
#endif
