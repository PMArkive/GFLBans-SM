#if defined _gflbans_included
#endinput
#endif
#define _gflbans_included

#include <ripext>
#include <gflbans/enums>
#include <gflbans/methodmaps>

public SharedPlugin:__pl_gflbans =
{
	name = "gflbans", 
	file = "gflbans-core.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_sourcebans_SetNTVOptional()
{
	
}
#endif

/*********************************************************
 * Called when a player is punished
 *
 * @param iClient               The client index of the admin who is banning the client
 * @param iTarget               The client index of the player to ban
 * @param iLength               The time to ban the player for (in minutes, 0 = permanent)
 * @param iPunishmentFlags      The punishment flags being applied to iTarget
 * @param sReason               The reason to ban the player from the server
 * @param sInfractionID         The infraction ID returned by GFLBans. (Append it to the link and you'll get the page of the infraction)
 *********************************************************/
forward void GFLBans_OnPlayerPunished(int iClient, int iTarget, int iLength, int iPunishmentFlags, const char[] sReason, const char[] sInfractionID);