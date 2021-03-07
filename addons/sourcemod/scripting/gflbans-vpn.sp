#include <sourcemod>
#include <ripext>

#pragma semicolon 1
#pragma newdecls required

/* ===== Global Variables ===== */
ConVar g_cvAdminFlag;
ConVar g_cvPunishment;
AdminFlag g_hAdminFlag;

/* ===== Definitions ===== */
#define PREFIX "\x01[\x0CGFLBans\x01]"

/* ===== Plugin Info ===== */
public Plugin myinfo =
{
    name        =    "GFLBans - VPN Checker",
    author        =    "Ash Akiri, Infra",
    description    =    "GFLBans - VPN Checker.",
    version        =    "0.3-BETA",
	url        =    "https://github.com/GFLClan/GFLBans-SM"
};

/* ===== Main Code ===== */

public void OnPluginStart()
{
    g_cvAdminFlag = CreateConVar("gb_vpn_flag", "z", "Flag required to see VPN detection notifications and use relevant commands.");
    g_cvPunishment = CreateConVar("gb_vpn_punish", "1", "Action to be taken when a client connects with a VPN. 0=Nothing, 1=Kick. Notifications are not affected by this ConVar.", _, true, 0.0, true, 1.0);

    AutoExecConfig(true, "GFLBans-VPN");
}

public void OnConfigsExecuted()
{
    char aFlag[2];
    GetConVarString(g_cvAdminFlag, aFlag, sizeof(aFlag));

    if (!FindFlagByChar(aFlag[0], g_hAdminFlag))
    {
        LogMessage("[GFLBans-VPN] Invalid Admin Flag found, falling back to Z flag.");
        g_hAdminFlag = ADMFLAG_ROOT;
    } 
    
    else 
    {
        LogMessage("[GFLBans-VPN] Admin flag set to %s", aFlag);
    }
}