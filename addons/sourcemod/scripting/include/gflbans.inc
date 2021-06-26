#if defined _gflbans_included
#endinput
#endif
#define _gflbans_included

#include <ripext>
#include <gflbans/enums>
#include <gflbans/methodmaps>

native bool GFLBans_SetClientGag(int iTarget, bool bGagState, int iLength = -1, bool bSavePunishment = false, const char[] sReason = "Muted thorugh GFLBans native");

native bool GFLBans_SetClientMute(int iTarget, bool bMuteState, int iLength = -1, bool bSavePunishment = false, const char[] sReason = "Muted through GFLBans native");

native PunishmentType GFLBans_GetClientGagType(int iTarget);

native PunishmentType GFLBans_GetClientMuteType(int iTarget);

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
	MarkNativeAsOptional("GFLBans_SetClientMute");
	MarkNativeAsOptional("GFLBans_SetClientGag");
	MarkNativeAsOptional("GFLBans_GetClientGagType");
	MarkNativeAsOptional("GFLBans_GetClientMuteType");
}
#endif

/*********************************************************
 * Called when a player is punished
 *
 * @param iClient               The client index of the admin who is punishing the client
 * @param iTarget               The client index of the player to punish
 * @param iLength               The time to punish the player for (in minutes, 0 = permanent)
 * @param iPunishmentFlags      The punishment flags being applied to iTarget
 * @param sReason               The reason to punish the player from the server
 * @param sInfractionID         The infraction ID returned by GFLBans. (Append it to the link and you'll get the page of the infraction)
 *********************************************************/
forward void GFLBans_OnPlayerPunished(int iClient, int iTarget, int iLength, int iPunishmentFlags, const char[] sReason, const char[] sInfractionID);

/*********************************************************
 * Called when a player punishment is removed
 *
 * @param iClient               The client index of the admin removed the punishment
 * @param iTarget               The client index of the target
 * @param iPunishmentFlags      The punishment flags being applied to iTarget
 * @param sReason               The reason of removal
 *********************************************************/
forward void GFLBans_OnPunishRemoved(int iClient, int iTarget, int iPunishmentFlags, const char[] sReason);