#if defined _scpsf_included
  #endinput
#endif
#define _scpsf_included

/**
 * Get the client's current class
 *
 * @param client 	Client index
 * @param class 	Class short string
 * @param length 	Max length
 *
 * @return		Number of bytes written
 */
native int SCPSF_GetClientClass(int client, char[] class, int length);

/**
 * Get if the client is a SCP
 *
 * @param client 	Client index
 *
 * @return		If the client is a SCP
 */
native bool SCPSF_IsSCP(int client);

/**
 * Calls when a client escapes
 *
 * @param client 	Client index
 * @param disarmer 	Client index of the disarmer, 0 if none
 *
 * @noreturn
 */
forward void SCPSF_OnEscape(int client, int disarmer);

/**
 * Calls when a client messages
 *
 * @param client 	Client index
 * @param name 		Name shown
 * @param message 	Message shown
 *
 * @noreturn
 */
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
	MarkNativeAsOptional("SCPSF_IsSCP");
}
#endif
