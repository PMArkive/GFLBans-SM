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

stock bool IsValidClient(int iClient, bool bAlive = false)
{
	if (iClient >= 1 && iClient <= MaxClients && IsClientConnected(iClient) && IsClientInGame(iClient) && (bAlive == false || IsPlayerAlive(iClient)))
		return true;

	return false;
}

/**
* Formats the buffer with the specified duration using .2f seconds, minutes, hours, or days.
*
* @param iSeconds The amount of seconds in the timespan
* @param sBuffer The buffer to store the result in
* @param iLength The max length of the buffer
**/
stock void FormatSeconds(int iSeconds, char[] sBuffer, int iLength) {
	if (iSeconds < 60) {
		Format(sBuffer, iLength, "%d second%s", iSeconds, iSeconds == 1 ? "":"s");
	} else if (iSeconds < 60 * 60) {
		Format(sBuffer, iLength, "%.2f minute%s", iSeconds / 60.0, iSeconds / 60.0 == 1 ? "":"s");
	} else if (iSeconds < 60 * 60 * 24) {
		Format(sBuffer, iLength, "%.2f hour%s", iSeconds / 60.0 / 60.0, iSeconds / 60.0 / 60.0 == 1 ? "":"s");
	} else {
		Format(sBuffer, iLength, "%.2f day%s", iSeconds / 60.0 / 60.0 / 24.0, iSeconds / 60.0 / 60.0 / 24.0 == 1 ? "":"s");
	}
}

void PrintToClientOrServer(int iClient, MsgTypes msgType = MsgType_Chat, const char[] sMessage, any ...)
{
    char sMessageBuffer[256];
    SetGlobalTransTarget(client);
    VFormat(sMessageBuffer, sizeof(sMessageBuffer), sMessage, 4);
    
    if (client == 0)
        PrintToServer(sMessageBuffer);
    else
    {
        switch (msgType)
        {
            case MsgType_Console: PrintToConsole(client, sMessageBuffer);
            case MsgType_Chat: PrintToChat(client, sMessageBuffer);
            case MsgType_Reply: ReplyToCommand(client, sMessageBuffer);
            case MsgType_Center: PrintCenterText(client, sMessageBuffer);
            case MsgType_Hint: PrintHintText(client, sMessageBuffer);
        }
    }
}