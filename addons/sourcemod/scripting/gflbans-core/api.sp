public void API_Heartbeat()
{
	// Update whatever is needed for the Heartbeat pulse:
    GetServerInfo();
    CheckMod(); //Check what game we are on.
	
    char requestURL[512];
    Format(requestURL, sizeof(requestURL), "gs/heartbeat");
    
    // Populate array list of PlayerObjs.
    PlayerObjIPOptional PlayerObjIP = new PlayerObjIPOptional();
    JSONArray playerList = new JSONArray();
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            PlayerObjIP.SetService("steam");
            PlayerObjIP.SetID64(client);
            PlayerObjIP.SetIP(client);

            // Push current PlayerObj
            playerList.Push(PlayerObjIP);
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
    delete PlayerObjIP;
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