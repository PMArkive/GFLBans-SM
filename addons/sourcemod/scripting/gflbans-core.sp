#include <sourcemod>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

#include "GFLBans/natives.sp"
#include "GFLBans/misc.sp"

/* ===== Global Variables ===== */
ConVar g_cvAPIUrl;
ConVar g_cvAPIKey;
ConVar g_cvAPIServerID;
ConVar g_cvAcceptGlobalBans;
char g_sAPIUrl[512];
char g_sAPIKey[256];
char g_sAPIServerID[32];
char g_sAPIAuthHeader[512];
char g_sMap[64];
char g_sMod[16];
char g_sServerHostname[128];
char g_sServerOS[8];
int g_iMaxPlayers;
bool g_bServerLocked;
bool g_bAcceptGlobalBans;
Handle hbTimer;
Handle g_hGData;

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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNatives();
    return APLRes_Success;
}

public void OnPluginStart()
{
    g_hGData = LoadGameConfigFile("gflbans.gamedata.txt");

    g_cvAPIUrl = CreateConVar("gb_api_url", "bans.gflclan.com/api/v1", "GFLBans API URL");
    g_cvAPIKey = CreateConVar("gb_api_key", "", "GFLBans API Key", FCVAR_PROTECTED);
    g_cvAPIServerID = CreateConVar("gb_api_svid", "", "GFLBans API Server ID.", FCVAR_PROTECTED);
    g_cvAcceptGlobalBans = CreateConVar("gb_accept_global_infractions", "1", "Accept global GFL bans. 1 = Enabled, 0 = Disabled.", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "GFLBans-Core");
}

public void OnConfigsExecuted()
{
    GetConVarString(g_cvAPIUrl, g_sAPIUrl, sizeof(g_sAPIUrl));
    GetConVarString(g_cvAPIKey, g_sAPIKey, sizeof(g_sAPIKey));
    GetConVarString(g_cvAPIServerID, g_sAPIServerID, sizeof(g_sAPIServerID));
    Format(g_sAPIAuthHeader, sizeof(g_sAPIAuthHeader), "SERVER %s %s", g_sAPIServerID, g_sAPIKey);

    // Check what game we are on.
    CheckMod(g_sMod);

    // Check what OS we are on.
    CheckOS(g_hGData, g_sServerOS);
}

public void OnMapStart()
{
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
    char requestURL[512];
    Format(requestURL, sizeof(requestURL), "%s/gs/heartbeat", g_sAPIUrl);

    // Grab whatever is needed for the Heartbeat pulse.
    GetServerInfo();
    g_bAcceptGlobalBans = GetConVarBool(g_cvAcceptGlobalBans);
    
    // Populate array list of PlayerObjs.
    JSONObject PlayerObjIP = new JSONObject();
    JSONArray playerList = new JSONArray();
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            char playerIP[32], playerID64[64];

            GetClientAuthId(client, AuthId_SteamID64, playerID64, sizeof(playerID64), true);
            GetClientIP(client, playerIP, sizeof(playerIP), true);

            PlayerObjIP.SetString("gs_service", "steam");
            PlayerObjIP.SetString("gs_id", playerID64);
            PlayerObjIP.SetString("ip", playerIP);

            // Push current PlayerObj
            playerList.Push(PlayerObjIP);
        }
    }

    // Create heartbeat pulse object.
    JSONObject jsonHeartbeat = new JSONObject();
    jsonHeartbeat.SetString("hostname", g_sServerHostname);
    jsonHeartbeat.SetInt("max_slots", g_iMaxPlayers);
    jsonHeartbeat.Set("players", playerList); // ngl, no idea if this will work LOL
    jsonHeartbeat.SetString("operating_system", g_sServerOS);
    jsonHeartbeat.SetString("mod", g_sMod);
    jsonHeartbeat.SetString("map", g_sMap);
    jsonHeartbeat.SetBool("locked", g_bServerLocked);
    jsonHeartbeat.SetBool("include_other_servers", g_bAcceptGlobalBans);

    // POST
    HTTPClient httpClient = new HTTPClient(requestURL);
    httpClient.SetHeader("Authorization", g_sAPIAuthHeader);
    httpClient.Post("", jsonHeartbeat, OnHeartbeatPulse);

    // Clean up and continue.
    delete jsonHeartbeat;
    delete playerList;
    delete PlayerObjIP;
    return Plugin_Continue;
}

void OnHeartbeatPulse(HTTPResponse response, any value) // Callback for heartbeat pulse.
{
    if (response.Status != HTTPStatus_Created)
    {
        LogError("[GFLBANS] FATAL ERROR >> Failed to POST heartbeat due to a connection fault.");
        return;
    }

    // TO-DO: Whatever needs to be done after heartbeat pulse has been sent.
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