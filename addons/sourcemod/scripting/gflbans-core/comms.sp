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
    
    // Get the target(s):
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    
    char sTargetBuffer[64];
    int iTargetList[MAXPLAYERS], iTargetCount;
    bool bTNisML;
    
    if((iTargetCount = ProcessTargetString(
                        sBuffer,
                        client,
                        iTargetList,
                        MAXPLAYERS,
                        0,
                        sTargetBuffer,
                        sizeof(sTargetBuffer),
                        bTNisML)) <= 0)
    {
        ReplyToTargetError(client, iTargetCount);
        return Plugin_Stop;
    }
        
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
    
    // Looping through iTargetList and applying punishment where necessary:
    for (int i = 0; i < iTargetCount; i++)
    {
        int iTarget = iTargetList[i];
        
        switch (iPunishmentType)
        {
            case P_CHAT:
            {
                // If client is gagged/ungagged, let the admin know, else create the infraction:
                if (g_esPlayerInfo[iTarget].gagIsGagged && !bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Already Gagged", iTarget);
                else if (!g_esPlayerInfo[iTarget].gagIsGagged && bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Not Gagged", iTarget);
                else if (bRemovingInfraction)
                    PrintToChatAll("%s - %N - %s", command, iTargetList[i], sReason);
                else
                    SetupInfraction(client, iTarget, iPunishmentLength, sReason, view_as<int>(iPunishmentType));
            }
            case P_VOICE:
            {
                // If client is muted/unmuted, let the admin know, else create the infraction:
                if (g_esPlayerInfo[iTarget].muteIsMuted && !bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Already Muted", iTarget);
                else if (!g_esPlayerInfo[iTarget].muteIsMuted && bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Not Muted", iTarget);
                else if (bRemovingInfraction)
                    PrintToChatAll("%s - %N - %s", command, iTargetList[i], sReason);
                else
                    SetupInfraction(client, iTarget, iPunishmentLength, sReason, view_as<int>(iPunishmentType));
            }
            case P_SILENCE:
            {
                // If client is silenced or has a mute/gag, let the admin know, else create the infraction:
                if (!bRemovingInfraction)
                {
                    if (!g_esPlayerInfo[iTarget].muteIsMuted && !g_esPlayerInfo[iTarget].gagIsGagged)
                        SetupInfraction(client, iTarget, iPunishmentLength, sReason, view_as<int>(iPunishmentType));
                    else if (g_esPlayerInfo[iTarget].muteIsMuted && g_esPlayerInfo[iTarget].gagIsGagged)
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Already Silenced", iTarget);
                    else
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Muted Or Gagged", iTarget);
                }
                else
                {
                    if (g_esPlayerInfo[iTarget].muteIsMuted && g_esPlayerInfo[iTarget].gagIsGagged)
                        PrintToChatAll("%s - %N - %s", command, iTarget, sReason);
                    else if (!g_esPlayerInfo[iTarget].muteIsMuted && !g_esPlayerInfo[iTarget].gagIsGagged)
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Not Silenced", iTarget);
                    else
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Not Silenced", iTarget);
                }
            }
        }
    }
    
    // This below is for printing the activity to chat:
    if (bTNisML)
    {
        // Print out only the multi-target phrase:
        
    }
    else
    {
        // Print out the target that got punished:
        
    }

    return Plugin_Stop;
}

/***************************************
 * Gags
***************************************/
stock void PerformGag(int iTarget, int iLength, bool bInSeconds = false, const char[] sReason, const char[] sAdminName = "CONSOLE")
{
    MarkClientAsGagged(iTarget, bInSeconds ? iLength : iLength * 60, sReason, sAdminName);
    BaseComm_SetClientGag(iTarget, true);
    
    if (iLength)
    {
        DataPack dp;
        if (bInSeconds)
            g_esPlayerInfo[iTarget].gagTimer = CreateDataTimer(float(iLength), Timer_GagExpire, dp, TIMER_FLAG_NO_MAPCHANGE);
        else
            g_esPlayerInfo[iTarget].gagTimer = CreateDataTimer(float(iLength * 60), Timer_GagExpire, dp, TIMER_FLAG_NO_MAPCHANGE);
        
        dp.WriteCell(iTarget);
        dp.WriteCell(GetClientUserId(iTarget));
        dp.Reset();
    }
}

public Action Timer_GagExpire(Handle timer, DataPack dp)
{
    g_esPlayerInfo[dp.ReadCell()].gagTimer = null;
    
    int iTarget = GetClientOfUserId(dp.ReadCell());
    if (!iTarget)
        return;
        
    PrintToChat(iTarget, "%s %t", PREFIX, "Gag Expired");
        
    g_esPlayerInfo[iTarget].ClearGag();
    if (IsClientInGame(iTarget))
        BaseComm_SetClientGag(iTarget, false);
}

stock void MarkClientAsGagged(int iTarget, int iLength, const char[] sReason, const char[] sAdminName)
{
    g_esPlayerInfo[iTarget].gagIsGagged = true;
    
    if (iLength)
    {
        g_esPlayerInfo[iTarget].gagExpiration = GetTime() + iLength;
        g_esPlayerInfo[iTarget].gagType = P_TIMED;
    }
    else if (iLength == 0)
    {
        g_esPlayerInfo[iTarget].gagExpiration = 0;
        g_esPlayerInfo[iTarget].gagType = P_PERM;
    }
    else
        g_esPlayerInfo[iTarget].gagType = P_SESS;
        
    strcopy(g_esPlayerInfo[iTarget].gagReason, sizeof(PlayerInfo::gagReason), sReason);
    strcopy(g_esPlayerInfo[iTarget].gagAdminName, sizeof(PlayerInfo::gagAdminName), sAdminName);
    
}

/***************************************
 * Mutes
***************************************/
stock void PerformMute(int iTarget, int iLength, bool bInSeconds = false, const char[] sReason, const char[] sAdminName = "CONSOLE")
{
    MarkClientAsMuted(iTarget, bInSeconds ? iLength : iLength * 60, sReason, sAdminName);
    BaseComm_SetClientMute(iTarget, true);
    
    if (iLength)
    {
        DataPack dp;
        if (bInSeconds)
            g_esPlayerInfo[iTarget].muteTimer = CreateDataTimer(float(iLength), Timer_MuteExpire, dp, TIMER_FLAG_NO_MAPCHANGE);
        else
            g_esPlayerInfo[iTarget].muteTimer = CreateDataTimer(float(iLength * 60), Timer_MuteExpire, dp, TIMER_FLAG_NO_MAPCHANGE);
        
        dp.WriteCell(iTarget);
        dp.WriteCell(GetClientUserId(iTarget));
        dp.Reset();
    }
}

public Action Timer_MuteExpire(Handle timer, DataPack dp)
{
    g_esPlayerInfo[dp.ReadCell()].muteTimer = null;
    
    int iTarget = GetClientOfUserId(dp.ReadCell());
    if (!iTarget)
        return;
    
    PrintToChat(iTarget, "%s %t", PREFIX, "Mute Expired");
    
    g_esPlayerInfo[iTarget].ClearMute();
    if (IsClientInGame(iTarget))
        BaseComm_SetClientMute(iTarget, false);
}

stock void MarkClientAsMuted(int iTarget, int iLength, const char[] sReason, const char[] sAdminName)
{
    g_esPlayerInfo[iTarget].muteIsMuted = true;
    
    if (iLength > 0)
    {
        g_esPlayerInfo[iTarget].muteExpiration = GetTime() + iLength;
        g_esPlayerInfo[iTarget].muteType = P_TIMED;
    }
    else if (iLength == 0)
    {
        g_esPlayerInfo[iTarget].muteExpiration = 0;
        g_esPlayerInfo[iTarget].muteType = P_PERM;
    }
    else
        g_esPlayerInfo[iTarget].muteType = P_SESS;
        
        
    strcopy(g_esPlayerInfo[iTarget].muteReason, sizeof(PlayerInfo::muteReason), sReason);
    strcopy(g_esPlayerInfo[iTarget].muteAdminName, sizeof(PlayerInfo::muteAdminName), sAdminName);
}