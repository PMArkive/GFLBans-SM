#include <sourcemod>
#include <ripext>

#include <gflbans>

#pragma semicolon 1
#pragma newdecls required

#include "gflbans-core/methodmaps.sp"
#include "gflbans-core/variables.sp"
#include "gflbans-core/logging.sp"
#include "gflbans-core/natives.sp"
#include "gflbans-core/misc.sp"
#include "gflbans-core/api.sp"
#include "gflbans-core/events.sp"
#include "gflbans-core/bans.sp"

/* ===== Plugin Info ===== */
public Plugin myinfo =
{
    name		=    PLUGIN_NAME,
    author		=    PLUGIN_AUTHOR,
    description	=    PLUGIN_DESCRIPTION,
    version		=    PLUGIN_VERSION,
	url			=    PLUGIN_URL
};

/* ===== Main Code ===== */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNatives(); // From natives.sp
    return APLRes_Success;
}

public void OnPluginStart()
{
    Handle gameData = LoadGameConfigFile("gflbans.games");
    if (gameData == INVALID_HANDLE)
		SetFailState("Can't find gflbans.games.txt gamedata.");
		
    if (GameConfGetOffset(gameData, "CheckOS") == 1) // CheckOS = 1 for Windows, CheckOS = 2 for Linux.
	    Format(g_sServerOS, sizeof(g_sServerOS), "windows");
    else
	    Format(g_sServerOS, sizeof(g_sServerOS), "linux"); // We are falling back to Linux.
        
    delete gameData;

    g_cvAPIUrl = CreateConVar("gb_api_url", "", "GFLBans API URL");
    g_cvAPIKey = CreateConVar("gb_api_key", "", "GFLBans API Key", FCVAR_PROTECTED);
    g_cvAPIServerID = CreateConVar("gb_api_svid", "", "GFLBans API Server ID.", FCVAR_PROTECTED);
    g_cvAcceptGlobalBans = CreateConVar("gb_accept_global_infractions", "1", "Accept global GFL bans. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);
    g_cvDebug = CreateConVar("gb_enable_debug_mode", "1", "Enable detailed logging of actions. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "GFLBans-Core");
}

public void OnConfigsExecuted()
{
    char APIKey[256];
    char APIServerID[32];
    char APIAuthHeader[512];

    GetConVarString(g_cvAPIUrl, g_sAPIUrl, sizeof(g_sAPIUrl));
    GetConVarString(g_cvAPIKey, APIKey, sizeof(APIKey));
    GetConVarString(g_cvAPIServerID, APIServerID, sizeof(APIServerID));
    Format(APIAuthHeader, sizeof(APIAuthHeader), "SERVER %s %s", APIServerID, APIKey);
    
    if(httpClient != null)
    	delete httpClient;

    // Start the HTTP Connection:
    httpClient = new HTTPClient(g_sAPIUrl);
    httpClient.SetHeader("Authorization", APIAuthHeader);
}

public void OnMapStart()
{
    hbTimer = CreateTimer(30.0, pulseTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); // Start the Heartbeat pulse timer
}

public Action pulseTimer(Handle timer)
{
    API_Heartbeat();

    return Plugin_Continue;
}

public void OnMapEnd()
{
    CloseHandle(hbTimer); // Close the Heartbeat timer handle (started in OnMapStart)
    if (g_cvDebug.BoolValue)
        LogAction(0, -1, "[GFLBans-Core] DEBUG >> Map is ending, cleaning heartbeat pulse timer handle.");
}

public void OnClientPostAdminCheck(int client)
{
	GFLBansPostAdminCheck(client);
}

