/***************************************
 * Heartbeat API
 **************************************/
void API_Heartbeat()
{
	// Update whatever is needed for the Heartbeat pulse:
    GetServerInfo();
    CheckMod(); //Check what game we are on.
	
    char requestURL[512];
    Format(requestURL, sizeof(requestURL), "gs/heartbeat");
    
    // Populate array list of PlayerObjs.
    JSONArray playerList = new JSONArray();
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            PlayerObjIPOptional PlayerObjIP = new PlayerObjIPOptional();
            PlayerObjIP.SetService("steam");
            PlayerObjIP.SetID64(client);
            PlayerObjIP.SetIP(client);

            // Push current PlayerObj
            playerList.Push(PlayerObjIP);
            delete PlayerObjIP;
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
    jsonHeartbeat.SetBool("include_other_servers", g_cvAcceptGlobalBans.BoolValue);

    // POST
    httpClient.Post(requestURL, jsonHeartbeat, OnHeartbeatPulse);
    if (g_cvDebug.BoolValue)
    {
    	char sData[2048];
    	jsonHeartbeat.ToString(sData, sizeof(sData), JSON_INDENT(4));
    	DebugLog("Sending API_Heartbeat with the body: %s", sData);
    }

    // Clean up.
    delete jsonHeartbeat;
    delete playerList;
}

void OnHeartbeatPulse(HTTPResponse response, any value) // Callback for heartbeat pulse.
{
    if (response.Status != HTTPStatus_OK)
    {
        char HTTPLocation[128];
        response.GetHeader("Location", HTTPLocation, sizeof(HTTPLocation));
        ErrorLog("FATAL ERROR >> Failed to POST Heartbeat Pulse:");
        ErrorLog("---> ENDPOINT = /gs/heartbeat");
        ErrorLog("---> HTTP Status = %d", response.Status);
        return;
    }

    // TO-DO: Whatever needs to be done after heartbeat pulse has been sent.
    if (g_cvDebug.BoolValue)
    {
    	DebugLog("DEBUG >> 200 - Successfully sent heartbeat pulse.");
    	char sData[2048];
    	response.Data.ToString(sData, sizeof(sData), JSON_INDENT(4));
    	DebugLog("Response from API_Heartbeat: %s", sData);
    }
    
//    JSONArray arr = view_as<JSONArray>(response.Data);
//    JSONObject obj = view_as<JSONObject>(arr.Get(0));
//    CheckInfractionsReply cir = view_as<CheckInfractionsReply>(obj.Get("check"));
//    CInfractionSummary cis = view_as<CInfractionSummary>(cir.VoiceBlock);
//    
//    if (cis == null)
//    	PrintToChatAll("CIS = null");
//    else
//    {
//    	PrintToChatAll("CIS != null");
//    	char sReason[64];
//    	cis.GetReason(sReason, sizeof(sReason));
//    	PrintToChatAll(sReason);
//    }
    
    // Do something with the info:
}

/***************************************
 * Checking Infractions API
 **************************************/
 void API_CheckInfractions(int client)
 {
    if (!IsValidClient(client))
        return;
        
    char requestURL[512];
    Format(requestURL, sizeof(requestURL), "infractions/check?gs_service=steam&gs_id={SteamID64}&ip={PlayerIP}]");
    
    char sSteamID64[64], sPlayerIP[20];
    GetClientAuthId(client, AuthId_SteamID64, sSteamID64, sizeof(sSteamID64), true);
    GetClientIP(client, sPlayerIP, sizeof(sPlayerIP), true);
    
    ReplaceString(requestURL, sizeof(requestURL), "{SteamID64}", sSteamID64);
    ReplaceString(requestURL, sizeof(requestURL), "{PlayerIP}", sPlayerIP);
    
    httpClient.Get(requestURL, OnCheckInfractionsCallback, GetClientUserId(client));
 }
 
 void OnCheckInfractionsCallback(HTTPResponse response, any data)
 {
    int client = GetClientOfUserId(data);
    
    if (!client)
        return;
        
    if (response.Status != HTTPStatus_OK)
    {
        ErrorLog("FATAL ERROR >> Failed to GET Infractions Check data:");
        ErrorLog("---> ENDPOINT = /infractions/check");
        ErrorLog("---> HTTP Status = %d", response.Status);
        return;
    }
    
    if (response.Data == null)
    {
        ErrorLog("FATAL ERROR >> Empty response recieved:");
        ErrorLog("---> ENDPOINT = /infractions/check");
        ErrorLog("---> HTTP Status = %d", response.Status);
        return;
    }
    
    CheckInfractionsReply infractionsReply = view_as<CheckInfractionsReply>(response.Data);
    
    /****************************
    * Get all the relevant data:
    ****************************/
    
    // Bans - Check bans first and kick them if they have an active ban.
    if (!infractionsReply.IsPunishmentNull(view_as<CInfractionSummary>(infractionsReply.Ban)))
    {
        int iClientExpiration = infractionsReply.GetExpiration(view_as<CInfractionSummary>(infractionsReply.Ban));
        
        // Additional check to determine if the client has a ban on record, -1 equals a permanent ban:
        if (iClientExpiration > GetTime() || iClientExpiration == -1)
        {
            char sReason[256], sAdminName[256], sExpirationTime[64];
            infractionsReply.GetReason(view_as<CInfractionSummary>(infractionsReply.Ban), sReason, sizeof(sReason));
            infractionsReply.GetAdminName(view_as<CInfractionSummary>(infractionsReply.Ban), sAdminName, sizeof(sAdminName));
            FormatSeconds(iClientExpiration - GetTime(), sExpirationTime, sizeof(sExpirationTime));
            
            char sDisconnectReason[256];
            Format(sDisconnectReason, sizeof(sDisconnectReason), "%T\n\nADMIN: %s\nREASON: %s\nTIME LEFT: %s", "Banned Player Text", LANG_SERVER, sAdminName, sReason, iClientExpiration != -1 ? sExpirationTime : "PERMANENT");
            
            if (g_cvDebug.BoolValue)
                ErrorLog("[GFLBans] Rejected client %N due to a ban: %s", client, sDisconnectReason);
            
            KickClient(client, sDisconnectReason);
        }
    }
    
    // Voice Blocks
    if (!infractionsReply.IsPunishmentNull(view_as<CInfractionSummary>(infractionsReply.VoiceBlock)))
    {
        
    }
    
    // Chat Blocks
    if (!infractionsReply.IsPunishmentNull(view_as<CInfractionSummary>(infractionsReply.ChatBlock)))
    {
        
    } 
    
    // Cleanup.
    delete infractionsReply;
 }