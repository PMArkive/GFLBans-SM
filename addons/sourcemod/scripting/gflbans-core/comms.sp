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
    bool bPlayerFound = false;
    for (int i = 0; i < iTargetCount; i++)
    {
        int iTarget = iTargetList[i];
        
        if (!IsValidClient(iTarget))
            continue;
        
        switch (iPunishmentType)
        {
            case P_CHAT:
            {
                // If client is gagged/ungagged, let the admin know, else create the infraction:
                if (g_esPlayerInfo[iTarget].gagIsGagged && !bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Already Gagged", iTarget);
                else if (!g_esPlayerInfo[iTarget].gagIsGagged && bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Not Gagged", iTarget);
                else if (bRemovingInfraction) {
                    ProcessUnblock(client, iTarget, view_as<int>(iPunishmentType), sReason, iTargetCount);
                    bPlayerFound = true;
                }
                else {
                    ProcessBlock(client, iTarget, iPunishmentLength, view_as<int>(iPunishmentType), sReason);
                    bPlayerFound = true;
                }
            }
            case P_VOICE:
            {
                // If client is muted/unmuted, let the admin know, else create the infraction:
                if (g_esPlayerInfo[iTarget].muteIsMuted && !bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Already Muted", iTarget);
                else if (!g_esPlayerInfo[iTarget].muteIsMuted && bRemovingInfraction)
                    ReplyToCommand(client, "%s %t", PREFIX, "Player Not Muted", iTarget);
                else if (bRemovingInfraction) {
                    ProcessUnblock(client, iTarget, view_as<int>(iPunishmentType), sReason, iTargetCount);
                    bPlayerFound = true;
                }
                else {
                    ProcessBlock(client, iTarget, iPunishmentLength, view_as<int>(iPunishmentType), sReason);
                    bPlayerFound = true;
                }
            }
            case P_SILENCE:
            {
                // If client is silenced or has a mute/gag, let the admin know, else create the infraction:
                if (!bRemovingInfraction)
                {
                    if (!g_esPlayerInfo[iTarget].muteIsMuted && !g_esPlayerInfo[iTarget].gagIsGagged) {
                        ProcessBlock(client, iTarget, iPunishmentLength, view_as<int>(iPunishmentType), sReason);
                        bPlayerFound = true;
                    }
                    else if (g_esPlayerInfo[iTarget].muteIsMuted && g_esPlayerInfo[iTarget].gagIsGagged)
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Already Silenced", iTarget);
                    else
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Muted Or Gagged", iTarget);
                }
                else
                {
                    if (g_esPlayerInfo[iTarget].muteIsMuted && g_esPlayerInfo[iTarget].gagIsGagged) {
                        ProcessUnblock(client, iTarget, view_as<int>(iPunishmentType), sReason, iTargetCount);
                        bPlayerFound = true;
                    }
                    else if (!g_esPlayerInfo[iTarget].muteIsMuted && !g_esPlayerInfo[iTarget].gagIsGagged)
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Not Silenced", iTarget);
                    else
                        ReplyToCommand(client, "%s %t", PREFIX, "Player Not Silenced", iTarget);  // This should be another message
                }
            }
        }
    }
    
    // This below is for printing the activity to chat:
    // Damn this doesn't look nice, improve it maybe?
    char sActionBuffer[256];
    if (bTNisML)
    {
        // Print out only the multi-target phrase:
        switch (iPunishmentType)
        {
            case P_CHAT:
            {
                if (!bRemovingInfraction)
                {
                    if (iPunishmentLength == 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "PermGagged Player", sTargetBuffer, sReason);
                    else if (iPunishmentLength > 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Gagged Player", sTargetBuffer, iPunishmentLength, sReason);
                    else
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Temp Gagged Player", sTargetBuffer, sReason);
                }
                else
                    FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "UnGagged Player", sTargetBuffer, sReason);
            }
            case P_VOICE:
            {
                if (!bRemovingInfraction)
                {
                    if (iPunishmentLength == 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "PermMuted Player", sTargetBuffer, sReason);
                    else if (iPunishmentLength > 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Muted Player", sTargetBuffer, iPunishmentLength, sReason);
                    else
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Temp Muted Player", sTargetBuffer, sReason);
                }
                else
                    FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "UnMuted Player", sTargetBuffer, sReason);
            }
            case P_SILENCE:
            {
                if (!bRemovingInfraction)
                {
                    if (iPunishmentLength == 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "PermSilenced Player", sTargetBuffer, sReason);
                    else if (iPunishmentLength > 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Silenced Player", sTargetBuffer, iPunishmentLength, sReason);
                    else
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Temp Silenced Player", sTargetBuffer, sReason);
                }
                else
                    FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "UnSilenced Player", sTargetBuffer, sReason);
            }
        }
    }
    else
    {
        // Print out the target that got punished:
        switch (iPunishmentType)
        {
            case P_CHAT:
            {
                if (!bRemovingInfraction)
                {
                    if (iPunishmentLength == 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "PermGagged Player", "_s", sTargetBuffer, sReason);
                    else if (iPunishmentLength > 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Gagged Player", "_s", sTargetBuffer, iPunishmentLength, sReason);
                    else
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Temp Gagged Player", "_s", sTargetBuffer, sReason);
                }
                else
                    FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "UnGagged Player", "_s", sTargetBuffer, sReason);
            }
            case P_VOICE:
            {
                if (!bRemovingInfraction)
                {
                    if (iPunishmentLength == 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "PermMuted Player", "_s", sTargetBuffer, sReason);
                    else if (iPunishmentLength > 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Muted Player", "_s", sTargetBuffer, iPunishmentLength, sReason);
                    else
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Temp Muted Player", "_s", sTargetBuffer, sReason);
                }
                else
                    FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "UnMuted Player", "_s", sTargetBuffer, sReason);
            }
            case P_SILENCE:
            {
                if (!bRemovingInfraction)
                {
                    if (iPunishmentLength == 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "PermSilenced Player", "_s", sTargetBuffer, sReason);
                    else if (iPunishmentLength > 0)
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Silenced Player", "_s", sTargetBuffer, iPunishmentLength, sReason);
                    else
                        FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "Temp Silenced Player", "_s", sTargetBuffer, sReason);
                }
                else
                    FormatEx(sActionBuffer, sizeof(sActionBuffer), "%t", "UnSilenced Player", "_s", sTargetBuffer, sReason);
            }
        }
    }
    
    if (bPlayerFound)
        ShowActivity2(client, PREFIX, "%s", sActionBuffer);
        
    return Plugin_Stop;
}

/***************************************
 * Gags
***************************************/
stock void PerformGag(int iTarget, int iLength = -1, bool bInSeconds = false, const char[] sReason, const char[] sAdminName = "CONSOLE")
{
    MarkClientAsGagged(iTarget, bInSeconds ? iLength : iLength * 60, sReason, sAdminName);
    BaseComm_SetClientGag(iTarget, true);
    
    if (iLength > 0)
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
    
    if (iLength > 0)
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

stock void PerformUngag(int iTarget)
{
    g_esPlayerInfo[iTarget].ClearGag();
    BaseComm_SetClientGag(iTarget, false);
}

/***************************************
 * Mutes
***************************************/
stock void PerformMute(int iTarget, int iLength = -1, bool bInSeconds = false, const char[] sReason, const char[] sAdminName = "CONSOLE")
{
    MarkClientAsMuted(iTarget, bInSeconds ? iLength : iLength * 60, sReason, sAdminName);
    BaseComm_SetClientMute(iTarget, true);
    
    if (iLength > 0)
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

stock void PerformUnmute(int iTarget)
{
    g_esPlayerInfo[iTarget].ClearMute();
    BaseComm_SetClientMute(iTarget, false);
}

/***************************************
 * Setting up of comms
***************************************/
stock void ProcessBlock(int iClient, int iTarget, int iLength, int iPunishmentType, const char[] sReason)
{
    if (!IsValidClient(iTarget))
        return;
        
    char sAdminName[256];
    if (iClient)
        GetClientName(iClient, sAdminName, sizeof(sAdminName));
    else
        FormatEx(sAdminName, sizeof(sAdminName), "CONSOLE");
        
    switch (iPunishmentType)
    {
        case P_CHAT:
        {
            if (iLength < 0)
            {
                PerformGag(iTarget, _, _, sReason, sAdminName);
                return;
            }
        }
        case P_VOICE:
        {
            if (iLength < 0)
            {
                PerformMute(iTarget, _, _, sReason, sAdminName);
                return;
            }
        }
        case P_SILENCE:
        {
            if (iLength < 0)
            {
                PerformGag(iTarget, _, _, sReason, sAdminName);
                PerformMute(iTarget, _, _, sReason, sAdminName);
                return;
            }
        }
    }
    
    SetupInfraction(iClient, iTarget, iLength, sReason, iPunishmentType);
}

/***************************************
 * Removal of comms
***************************************/
stock void ProcessUnblock(int iClient, int iTarget, int iPunishmentType, const char[] sReason, int iTargetCount)
{
    if (!IsValidClient(iTarget))
        return;
        
    if (iTargetCount > 1)
    { 
        switch (iPunishmentType)
        {
            case P_CHAT:
            {
                if (g_esPlayerInfo[iTarget].gagType == P_TIMED || g_esPlayerInfo[iTarget].gagType == P_PERM)
                    return;
            }
            case P_VOICE:
            {
                if (g_esPlayerInfo[iTarget].muteType == P_TIMED || g_esPlayerInfo[iTarget].muteType == P_PERM)
                    return;
            }
            case P_SILENCE:
            {
                if ((g_esPlayerInfo[iTarget].gagType == P_TIMED || g_esPlayerInfo[iTarget].gagType == P_PERM) && (g_esPlayerInfo[iTarget].muteType == P_TIMED || g_esPlayerInfo[iTarget].muteType == P_PERM))
                    return;
            }
        }
        
        ProcessUnblock(iClient, iTarget, iPunishmentType, sReason, 1);
    }
    else
    {
        switch (iPunishmentType)
        {
            case P_CHAT:
            {
                if (g_esPlayerInfo[iTarget].gagType == P_SESS)
                {
                    PerformUngag(iTarget);
                    return;
                }
            }
            case P_VOICE:
            {
                if (g_esPlayerInfo[iTarget].muteType == P_SESS)
                {
                    PerformUnmute(iTarget);
                    return;                    
                }
            }
            case P_SILENCE:
            {
                if (g_esPlayerInfo[iTarget].muteType == P_SESS && g_esPlayerInfo[iTarget].gagType == P_SESS)
                {
                    PerformUnmute(iTarget);
                    PerformUngag(iTarget);
                    return;
                }
            }   
        }
        
        SetupRemoval(iClient, iTarget, iPunishmentType, sReason);
    }
}