#if defined _scpsf_included
  #endinput
#endif
#define _scpsf_included

enum SCPAchievement
{
	Achievement_MTFSpawn = 0,	// Respawn as Nine-Tailed Fox
	Achievement_ChaosSpawn,	// Respawn as Chaos Insurgency
	Achievement_DeathTesla,	// Die from a Tesla Gate burst
	Achievement_DeathEarly,	// Die within the first minute of the game
	Achievement_Death173,	// Let SCP-173 snap your neck
	Achievement_Death106,	// Die inside the pocket dimension
	Achievement_DeathFall,	// Die from a fall
	Achievement_DeathGrenade,	// Kill yourself with a grenade
	Achievement_DeathEnrage,	// Die while entering a rage as SCP-096
	Achievement_DeathMicro,	// Try to recharge the MicroHID
	Achievement_Kill106,	// Successfully re-contain SCP-106
	Achievement_KillSCPMirco,	// Kill an SCP with the Micro HID
	Achievement_KillSCPSci,	// Kill an SCP as a Scientist
	Achievement_KillMirco,	// As an SCP, kill someone who's charging or firing the MicroHID
	Achievement_KillSci,	// As Class-D, kill a Scientist holding a keycard
	Achievement_KillDClass,	// Kill 50 D-Class as a Scientist
	Achievement_KillSpree,	// Kill 5 enemies in less than 30 seconds
	Achievement_FindGun,	// Find any gun as a Class-D
	Achievement_FindO5,	// Pick up an O5-Keycard
	Achievement_FindSCP,	// Liberate two or more SCP objects from the facility while escaping as a Class-D
	Achievement_EscapeDClass,	// Escape as D-Class personnel
	Achievement_EscapeSci,	// Escape as a Scientist
	Achievement_EscapeSpeed,	// Escape the facility in 3 minutes or under
	Achievement_Escape207,	// Escape while under the effects of SCP-207
	Achievement_SurvivePocket,	// Successfully escape from the Pocket Dimension
	Achievement_SurviveWarhead,// Survive a successful Alpha Warhead Detonation
	Achievement_Survive500,	// Use SCP-500 when you're about to die
	Achievement_SurviveAdren,	// Use adrenaline to survive a hit that would otherwise kill you
	Achievement_SurviveCancel,	// Cancel the Alpha Warhead detonation within the last 15 seconds of the countdown
	Achievement_Intercom,	// Broadcast a 'helpful' message via the Intercom
	Achievement_Upgrade,	// As a Scientist, successfully upgrade your keycard alongside any amount of Class-D
	Achievement_Revive,	// Cure 10 people in a single game
	Achievement_DisarmMTF,	// Disarm a MTF operative
	Achievement_Halloween,	// Play the Halloween version of the game
	Achievement_Christmas	// Play the Christmas version of the game
}

enum SCPSpawnContext
{
	ClassSpawn_Other = 0,
	ClassSpawn_RoundStart,
	ClassSpawn_WaveSystem,
	ClassSpawn_Death,
	ClassSpawn_Escape,
	ClassSpawn_Revive
}

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
 * Starts or restarts current music (will reenable music if was disabled)
 *
 * @note		Has no effect on music disabled maps
 *
 * @param client 	Client index, 0 for all players
 *
 * @noreturn
 */
native void SCPSF_StartMusic(int client=0);

/**
 * Stops current music (if all players, will permanently disable until reenabled)
 *
 * @note		Has no effect on music disabled maps
 *
 * @param client 	Client index, 0 for all players and will 
 *
 * @noreturn
 */
native void SCPSF_StopMusic(int client=0);

/**
 * Checks if the client can talk to the target
 *
 * @param client 	Client index of speaker
 * @param target 	Client index of listener
 *
 * @noreturn
 */
native bool SCPSF_CanTalkTo(int client, int target);

/**
 * Gets tag to display in client chat
 *
 * @param client 	Client index of speaker
 * @param target 	Client index of listener
 * @param buffer 	Buffer string to store
 * @param length 	Max length of buffer
 *
 * @noreturn
 */
native void SCPSF_GetChatTag(int client, int target, char[] buffer, int length);

/**
 * Gets tag to display in client chat
 *
 * @param client 	Client index of speaker
 * @param target 	Client index of listener
 * @param buffer 	Buffer string to store
 * @param length 	Max length of buffer
 *
 * @noreturn
 */
native void SCPSF_GetChatTag(int client, int target, char[] buffer, int length);

/**
 * Calls when a specific event happens
 *
 * @param client 	Client index
 * @param name 		Name shown
 * @param message 	Message shown
 *
 * @noreturn
 */
forward void SCPSF_OnAchievement(int client, SCPAchievement achievement);

/**
 * Calls when a client messages when the chat processor is enabled
 *
 * @param client 	Client index
 * @param name 		Name shown (size of 64)
 * @param message 	Message shown (size of 512)
 *
 * @noreturn
 */
forward void SCPSF_OnChatMessage(int client, char[] name, char[] message);

/**
 * Calls when a client is being assigned a new class
 *
 * @param client 	Client index
 * @param class		Class short string (size of 16)
 * @param context 	Context on why a new class is assigned
 *
 * @return		Plugin_Continue - No changes
 *			Plugin_Changed - Changed class, a queue will move on to the next class
 *			Plugin_Handled - Changed class, a queue will keep the last class for the next player
 *			Plugin_Stop - Class is unchanged, a queue will keep the last class for the next player
 */
forward Action SCPSF_OnClassPre(int client, char[] class, SCPSpawnContext context);

/**
 * Calls when a client is assigned a new class
 *
 * @param client 	Client index
 * @param class		Class short string
 * @param context 	Context on why a new class is assigned
 *
 * @noreturn
 */
forward void SCPSF_OnClass(int client, const char[] class, SCPSpawnContext context);

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
 * Calls when a client is picking up a new item
 *
 * @param client 	Client index
 * @param entity 	Entity index of dropped weapon, -1 if came from other sources
 * @param index		Weapon index
 *
 * @return		Plugin_Continue - No changes
 *			Plugin_Changed - Changed weapon index, if index is invalid nothing is given
 *			Plugin_Handled - Nothing is given
 *			Plugin_Stop - Nothing is given
 */
forward Action SCPSF_OnWeaponPre(int client, int entity, int &index);

/**
 * Calls when a client is given a new item
 *
 * @param client 	Client index
 * @param entity 	Entity index of weapon
 *
 * @noreturn
 */
forward void SCPSF_OnWeapon(int client, int entity);

/**
 * Calls when a client is reacting to a certain event
 *
 * @param client 	Client index
 * @param event		Name of the event
 * @param sound		Filepath of sound
 *
 * @return		Plugin_Continue - No changes
 *			Plugin_Changed - Changed sound
 *			Plugin_Handled - No sound is played
 *			Plugin_Stop - No sound is played
 */
forward Action SCPSF_OnReactionPre(int client, const char[] event, char sound[PLATFORM_MAX_PATH]);

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
	MarkNativeAsOptional("SCPSF_StartMusic");
	MarkNativeAsOptional("SCPSF_StopMusic");
	MarkNativeAsOptional("SCPSF_CanTalkTo");
	MarkNativeAsOptional("SCPSF_GetChatTag");
}
#endif
