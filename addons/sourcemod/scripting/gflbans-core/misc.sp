void CheckMod(char modStr[16])
{
    if (GetEngineVersion() == Engine_CSGO)
        Format(modStr, sizeof(modStr), "csgo");
    else if (GetEngineVersion() == Engine_CSS)
        Format(modStr, sizeof(modStr), "cstrike");
    else if (GetEngineVersion() == Engine_TF2)
        Format(modStr, sizeof(modStr), "tf");
    else
        SetFailState("[GFLBans] This plugin is not compatible with the current game."); // Default to disabling the plugin if the game is unidentified.
}

void CheckOS(Handle gData, char osStr[8])
{
    if (GameConfGetOffset(gData, "CheckOS") == 1) // CheckOS = 1 for Windows, CheckOS = 2 for Linux.
        Format(osStr, sizeof(osStr), "windows");
    else
        Format(osStr, sizeof(osStr), "linux"); // We are falling back to Linux.
}