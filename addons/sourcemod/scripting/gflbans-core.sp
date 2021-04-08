#include <sourcemod>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

#include "gflbans-core/variables.sp"
#include "gflbans-core/natives.sp"
#include "gflbans-core/misc.sp"
#include "gflbans-core/api.sp"

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
    g_hGData = LoadGameConfigFile("gflbans.games");

    g_cvAPIUrl = CreateConVar("gb_api_url", "bans.gflclan.com/api/v1", "GFLBans API URL");
    g_cvAPIKey = CreateConVar("gb_api_key", "", "GFLBans API Key", FCVAR_PROTECTED);
    g_cvAPIServerID = CreateConVar("gb_api_svid", "", "GFLBans API Server ID.", FCVAR_PROTECTED);
    g_cvAcceptGlobalBans = CreateConVar("gb_accept_global_infractions", "1", "Accept global GFL bans. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);
    g_cvDebug = CreateConVar("gb_enable_debug_mode", "0", "Enable detailed logging of actions. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);

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

    CheckMod(g_sMod); // Check what game we are on.
    CheckOS(g_hGData, g_sServerOS); // Check what OS we are on.
    
    if(httpClient != null)
    	delete httpClient;

    // Start the HTTP Connection:
    httpClient = new HTTPClient(g_sAPIUrl);
    httpClient.SetHeader("Authorization", APIAuthHeader);
}

public void OnMapStart()
{
    // Fire a single heartbeat pulse right when map starts.
    GetServerInfo(); // Grab whatever is needed for the Heartbeat pulse.
    API_Heartbeat(httpClient, g_sServerHostname, g_iMaxPlayers, g_sServerOS, g_sMod, g_sMap, g_bServerLocked, g_cvAcceptGlobalBans.BoolValue);

    hbTimer = CreateTimer(30.0, pulseTimer, _, TIMER_REPEAT); // Start the Heartbeat pulse timer
}

public Action pulseTimer(Handle timer)
{
    GetServerInfo(); // Update whatever is needed for the Heartbeat pulse.
    API_Heartbeat(httpClient, g_sServerHostname, g_iMaxPlayers, g_sServerOS, g_sMod, g_sMap, g_bServerLocked, g_cvAcceptGlobalBans.BoolValue);

    return Plugin_Continue;
}

public void OnMapEnd()
{
    CloseHandle(hbTimer); // Close the Heartbeat timer handle (started in OnMapStart)
    if (g_cvDebug.BoolValue)
        LogAction(0, -1, "[GFLBans-Core] DEBUG >> Map is ending, cleaning heartbeat pulse timer handle.");
}

void GetServerInfo()
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