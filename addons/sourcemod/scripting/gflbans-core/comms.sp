public Action ListenerCallback(int client, const char[] command, int args)
{
    if (client && !CheckCommandAccess(client, command, ADMFLAG_CHAT))
		return Plugin_Continue;
    
    PunishmentsTemplate iPunishmentType;
    bool bRemovingInfraction;
    
    if (StrEqual(command, "sm_gag", false))
        iPunishmentType = P_CHAT;
    else if (StrEqual(command, "sm_mute", false))
        iPunishmentType = P_VOICE;
    else if (StrEqual(command, "sm_silence", false))
        iPunishmentType = P_SILENCE;
    else if (StrEqual(command, "sm_ungag", false)) {
        bRemovingInfraction = true;
        iPunishmentType = P_CHAT;
    } else if (StrEqual(command, "sm_unmute", false)) {
        bRemovingInfraction = true;
        iPunishmentType = P_VOICE;
    } else if (StrEqual(command, "sm_unsilence", false)) {
        bRemovingInfraction = true;
        iPunishmentType = P_SILENCE;
    }
    else
        return Plugin_Stop;
        
    if (bRemovingInfraction ? args < 2  : args < 3)
    {
        ReplyToCommand(client, "%s Usage: %s <#userid|name> %s", PREFIX, command, bRemovingInfraction ? "[reason]" : "<time|0> [reason]");
        return Plugin_Stop;
    }
    
    char sBuffer[64], sReason[128];
    int iPunishmentLength;
    
    // Get the target:
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    int iTarget = FindTarget(client, sBuffer, true, true);
    
    if (iTarget == -1 || !IsValidClient(iTarget))
        return Plugin_Stop;
        
    // Get reason if it's an ungag/unmute/unsilence:
    if (bRemovingInfraction)
    {
        GetCmdArg(2, sReason, sizeof(sReason));
        for (int i = 3; i <= args; i++)
        {
            GetCmdArg(i, sBuffer, sizeof(sBuffer));
            Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
        }
    }
    else
    {
        // else, get time & reason:
        GetCmdArg(2, sBuffer, sizeof(sBuffer));
        iPunishmentLength = StringToInt(sBuffer);
        
        GetCmdArg(3, sReason, sizeof(sReason));
        for (int i = 4; i <= args; i++)
        {
            GetCmdArg(i, sBuffer, sizeof(sBuffer));
            Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
        }
    }
    
    // Could be called in the above if/else but it's "cleaner" here:
    if (bRemovingInfraction)
        PrintToChatAll("%s - %N - %s", command, iTarget, sReason);
    else
        SetupInfraction(client, iTarget, iPunishmentLength, sReason, view_as<int>(iPunishmentType));
        
    
    return Plugin_Stop;
}