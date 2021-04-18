stock void CheckMod()
{
    if (GetEngineVersion() == Engine_CSGO)
        Format(g_sMod, sizeof(g_sMod), "csgo");
    else if (GetEngineVersion() == Engine_CSS)
        Format(g_sMod, sizeof(g_sMod), "cstrike");
    else if (GetEngineVersion() == Engine_TF2)
        Format(g_sMod, sizeof(g_sMod), "tf");
    else
        SetFailState("[GFLBans] This plugin is not compatible with the current game."); // Default to disabling the plugin if the game is unidentified.
}

stock void CheckOS(Handle gData, char osStr[8])
{
    if (GameConfGetOffset(gData, "CheckOS") == 1) // CheckOS = 1 for Windows, CheckOS = 2 for Linux.
        Format(osStr, sizeof(osStr), "windows");
    else
        Format(osStr, sizeof(osStr), "linux"); // We are falling back to Linux.
}

stock void GetServerInfo()
{
    char svPwd[128];

    GetCurrentMap(g_sMap, sizeof(g_sMap));
    g_iMaxPlayers = GetMaxHumanPlayers();
    GetConVarString(FindConVar("hostname"), g_sServerHostname, sizeof(g_sServerHostname));

    // Check if the server is locked:
    GetConVarString(FindConVar("sv_password"), svPwd, sizeof(svPwd));
    if(!StrEqual(svPwd, ""))
        g_bServerLocked = true;
    else 
        g_bServerLocked = false;
}

stock bool IsValidClient(int client, bool bAlive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
		return true;

	return false;
}

/**
* Formats the buffer with the specified duration using .2f seconds, minutes, hours, or days.
*
* @param seconds The amount of seconds in the timespan
* @param buffer The buffer to store the result in
* @param length The max length of the buffer
*/
stock void FormatSeconds(int seconds, char[] buffer, int length) {
	if (seconds < 60) {
		Format(buffer, length, "%d second%s", seconds, seconds == 1 ? "":"s");
	} else if (seconds < 60 * 60) {
		Format(buffer, length, "%.2f minute%s", seconds / 60.0, seconds / 60.0 == 1 ? "":"s");
	} else if (seconds < 60 * 60 * 24) {
		Format(buffer, length, "%.2f hour%s", seconds / 60.0 / 60.0, seconds / 60.0 / 60.0 == 1 ? "":"s");
	} else {
		Format(buffer, length, "%.2f day%s", seconds / 60.0 / 60.0 / 24.0, seconds / 60.0 / 60.0 / 24.0 == 1 ? "":"s");
	}
}