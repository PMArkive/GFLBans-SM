#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

/* ===== Global Variables ===== */
ConVar g_cvAPIUrl;
ConVar g_cvAPIKey;
ConVar g_cvAPIServerID;
char g_sAPIUrl[512];
char g_sAPIKey[128];
char g_sAPIServerID[32];

char g_sMap[64];

Handle hbTimer;

/* ===== Definitions ===== */
#define PREFIX "\x01[\x0CGFLBans\x01]"

/* ===== Plugin Info ===== */
public Plugin myinfo =
{
    name        =    "GFLBans - Core",
    author        =    "Infra",
    description    =    "GFLBans Core plugin",
    version        =    "0.3-BETA",
	url        =    "https://github.com/GFLClan"
};

/* ===== Main Code ===== */

public void OnPluginStart()
{
    g_cvAPIUrl = CreateConVar("gflbans_api_url", "bans.gflclan.com/api/v1", "GFLBans API URL");
    g_cvAPIKey = CreateConVar("gflbans_api_key", "", "GFLBans API Key", FCVAR_PROTECTED);
    g_cvAPIServerID = CreateConVar("gflbans_api_svid", "", "GFLBans API Server ID.", FCVAR_PROTECTED);

    g_sAPIUrl = GetConVarString(g_cvAPIUrl, sizeof(g_sAPIUrl));
    g_sAPIKey = GetConVarString(g_cvAPIKey, sizeof(g_sAPIKey));
    g_sAPIServerID = GetConVarString(g_cvAPIServerID, sizeof(g_sAPIServerID));

    AutoExecConfig(true, "GFLBans-Core");
}

public void OnMapStart()
{
    GetCurrentMap(g_sMap, sizeof(g_sMap));

    // Start the Heartbeat timer - repeats every minute.
    hbTimer = CreateTimer(60.0, API_Heartbeat, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
    // Close the Heartbeat timer handle (started in OnMapStart)
    CloseHandle(hbTimer);
}

public Action API_Heartbeat(Handle timer)
{
    char requestURL[512], requestContent[512];
    Format(requestURL, sizeof(requestURL), "%s/gs/heartbeat", g_sAPIUrl);
    Format(requestContent, sizeof(requestContent), "{}");

    Handle hbReq = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, requestURL);
    if (hbReq == INVALID_HANDLE)
    {
        LogError("[GFLBANS] FATAL ERROR >> Failed to POST heartbeat due to a connection fault.");
        return Plugin_Continue;
    }

    /*
    TO-DO: Use the API spec and make a heartbeat POST here.
    */

    return Plugin_Continue;
}