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

bool IsValidClient(int client, bool bAlive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bAlive == false || IsPlayerAlive(client)))
		return true;

	return false;
}