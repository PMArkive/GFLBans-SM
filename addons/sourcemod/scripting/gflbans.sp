#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required
#define PREFIX "\x01[\x0CGFLBans\x01]"

public Plugin myinfo =
{
    name        =    "GFLBans",
    author        =    "Infra",
    description    =    "GFLBans",
    version        =    "1.0.0",
	url        =    "https://github.com/GFLClan"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_cock", Command_Cock, "Calls a cock.");
}

public Action Command_Cock(int client, int args)
{
    PrintToChat(client, "%s COCK LOLOLOL");
    return Plugin_Handled;
}