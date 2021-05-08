public Action ListenerCallback(int client, const char[] command, int args)
{
    if (client && !CheckCommandAccess(client, command, ADMFLAG_CHAT))
		return Plugin_Continue;
		
    PrintToChatAll("Listener callbacked!");
    
    return Plugin_Stop;
}