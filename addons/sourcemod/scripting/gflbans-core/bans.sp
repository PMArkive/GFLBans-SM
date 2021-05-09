// Ban Commands go here:
public Action Command_Ban(int client, int args)
{
    if (args < 3)
    {
        ReplyToCommand(client, "%s Usage: sm_ban <#userid|name> <time|0> [reason]", PREFIX);
        return Plugin_Handled;
    }
    
    char sBuffer[64];
    
    // Get the target:
    GetCmdArg(1, sBuffer, sizeof(sBuffer));
    int iTarget = FindTarget(client, sBuffer, true, true);
    
    if (iTarget == -1 || !IsValidClient(iTarget))
        return Plugin_Handled;
    
    // Get the time:
    GetCmdArg(2, sBuffer, sizeof(sBuffer));
    int iBanTime = StringToInt(sBuffer);
    
    if (!iBanTime && client && !(CheckCommandAccess(client, "sm_ban", ADMFLAG_UNBAN | ADMFLAG_ROOT)))
    {
        ReplyToCommand(client, "%t", "%s InsufficientPermBanPerms", PREFIX);
        return Plugin_Handled;
    }
    
    // Get the reason:
    char sReason[128];
    GetCmdArg(3, sReason, sizeof(sReason));
    for (int i = 4; i <= args; i++)
    {
        GetCmdArg(i, sBuffer, sizeof(sBuffer));
        Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
    }
    
    SetupInfraction(client, iTarget, iBanTime, sReason, view_as<int>(P_BAN));
    return Plugin_Handled;
}