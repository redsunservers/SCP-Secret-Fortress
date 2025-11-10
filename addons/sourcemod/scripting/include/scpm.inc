#if defined _SCPM_included
	#endinput
#endif
#define _SCPM_included

/**
 * Checks if the client can talk to the target
 *
 * @param client 	Client index of speaker
 * @param target 	Client index of listener
 *
 * @return	True if can talk to, false otherwise
 */
native bool SCPM_CanTalkTo(int client, int target);

public SharedPlugin __pl_SCPM =
{
	name = "scpm",
	file = "scpm.smx",
	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_SCPM_SetNTVOptional()
{
	MarkNativeAsOptional("SCPM_CanTalkTo");
}
#endif
