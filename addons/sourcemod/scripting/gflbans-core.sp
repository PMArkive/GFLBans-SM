#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

/* ===== Global Variables ===== */
ConVar g_cvAPIUrl;
ConVar g_cvAPIKey;
ConVar g_cvAPIServerID;
char g_sAPIUrl[512];
char g_sAPIKey[256];
char g_sAPIServerID[32];

char g_sMap[64];
char g_sMod[16];
char g_sServerHostname[128];
char g_sServerOS[8];

int g_iMaxPlayers;

bool g_bServerLocked;

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

    GetConVarString(g_cvAPIUrl, g_sAPIUrl, sizeof(g_sAPIUrl));
    GetConVarString(g_cvAPIKey, g_sAPIKey, sizeof(g_sAPIKey));
    GetConVarString(g_cvAPIServerID, g_sAPIServerID, sizeof(g_sAPIServerID));

    AutoExecConfig(true, "GFLBans-Core");

    // Check what game we are on.
    CheckMod();

    // Check what OS we are on.
    CheckOS();
}

public void OnMapStart()
{
    char svPwd[128];

    // Grab whatever is needed for the Heartbeat pulse.
    GetCurrentMap(g_sMap, sizeof(g_sMap));
    g_iMaxPlayers = GetMaxHumanPlayers();
    GetConVarString(FindConVar("hostname"), g_sServerHostname, sizeof(g_sServerHostname));

    // Check if the server is locked:
    GetConVarString(FindConVar("sv_password"), svPwd, sizeof(svPwd));
    if(!StrEqual(svPwd, ""))
        g_bServerLocked = true;
    else 
        g_bServerLocked = false;

    // Start the Heartbeat pulse timer - repeats every minute.
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

void CheckMod()
{
    if (GetEngineVersion() == Engine_CSGO)
        Format(g_sMod, sizeof(g_sMod), "csgo");
    else if (GetEngineVersion() == Engine_CSS)
        Format(g_sMod, sizeof(g_sMod), "css");
    else if (GetEngineVersion() == Engine_TF2)
        Format(g_sMod, sizeof(g_sMod), "tf2");
    else
        SetFailState("[GFLBans] This plugin is not compatible with the current game."); // Default to disabling the plugin if the game is unidentified.
}

void CheckOS()
{
    Handle GData = LoadGameConfigFile("gflbans.gamedata.txt");
    if (GameConfGetOffset(GData, "CheckOS") == 1) // CheckOS = 1 for Windows, CheckOS = 2 for Linux.
        Format(g_sServerOS, sizeof(g_sServerOS), "windows");
    else
        Format(g_sServerOS, sizeof(g_sServerOS), "linux"); // We are falling back to Linux.
}