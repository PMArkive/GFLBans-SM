/*********************************************************
 * Logs a message to root players (for debugging)
 *
 * @param console	Whether or not to log to console
 * @param message	Message to send to the root players
 * @param any		Format message
 * @noreturn
 *********************************************************/
void PrintToRoot(bool console = false, const char[] message, any ...)
{
	char sMessage[PLATFORM_MAX_PATH];
	VFormat(sMessage, sizeof(sMessage), message, 3);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			if (CheckCommandAccess(i, "", ADMFLAG_ROOT))
				if (!console)
					PrintToChat(i, "%s", sMessage);
				else
					PrintToConsole(i, "%s", sMessage);
	}
}

/*********************************************************
 * Logs a message to GFLBans logging folder
 *
 * @param message	The message to log
 * @param ...		Format message
 * @noreturn		
 *********************************************************/
void DebugLog(const char[] message, any ...)
{
	char sDate[32], sMessage[2048], sCurrentMap[64];
	FormatTime(sDate, sizeof(sDate), "%d/%m/%Y %H:%M:%S", GetTime());
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	VFormat(sMessage, sizeof(sMessage), message, 2);
	
	static char sLogPathDebug[PLATFORM_MAX_PATH];
		
	if (sLogPathDebug[0] == '\0')
		BuildPath(Path_SM, sLogPathDebug, sizeof(sLogPathDebug), "logs/GFLBans/GFLBans_DebugLogs.log");
		
	File fLogFile = OpenFile(sLogPathDebug, "a");
	fLogFile.WriteLine("%s | %s | %s", sDate, sCurrentMap, sMessage);
	delete fLogFile;
}

void ErrorLog(const char[] message, any ...)
{
	char sDate[32], sMessage[2048], sCurrentMap[64];
	FormatTime(sDate, sizeof(sDate), "%d/%m/%Y %H:%M:%S", GetTime());
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	VFormat(sMessage, sizeof(sMessage), message, 2);
	
	static char sLogPathError[PLATFORM_MAX_PATH];
		
	if (sLogPathError[0] == '\0')
		BuildPath(Path_SM, sLogPathError, sizeof(sLogPathError), "logs/GFLBans/GFLBans_ErrorLogs.log");
		
	File fLogFile = OpenFile(sLogPathError, "a");
	fLogFile.WriteLine("%s | %s | %s", sDate, sCurrentMap, sMessage);
	delete fLogFile;
}