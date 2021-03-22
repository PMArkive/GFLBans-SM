public void API_Heartbeat(HTTPClient apiClient, char[] hostname, int maxPlayers, char[] serverOS, char[] mod, char[] mapname, bool isLocked, bool acceptGlobalBans)
{
    char requestURL[512];
    Format(requestURL, sizeof(requestURL), "gs/heartbeat");
    
    // Populate array list of PlayerObjs.
    JSONObject PlayerObjIP = new JSONObject();
    JSONArray playerList = new JSONArray();
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            char playerIP[32], playerID64[64];

            GetClientAuthId(client, AuthId_SteamID64, playerID64, sizeof(playerID64), true);
            GetClientIP(client, playerIP, sizeof(playerIP), true);

            PlayerObjIP.SetString("gs_service", "steam");
            PlayerObjIP.SetString("gs_id", playerID64);
            PlayerObjIP.SetString("ip", playerIP);

            // Push current PlayerObj
            playerList.Push(PlayerObjIP);
        }
    }

    // Create heartbeat pulse object.
    JSONObject jsonHeartbeat = new JSONObject();
    jsonHeartbeat.SetString("hostname", hostname);
    jsonHeartbeat.SetInt("max_slots", maxPlayers);
    jsonHeartbeat.Set("players", playerList); // ngl, no idea if this will work LOL
    jsonHeartbeat.SetString("operating_system", serverOS);
    jsonHeartbeat.SetString("mod", mod);
    jsonHeartbeat.SetString("map", mapname);
    jsonHeartbeat.SetBool("locked", isLocked);
    jsonHeartbeat.SetBool("include_other_servers", acceptGlobalBans);

    // POST
    apiClient.Post(requestURL, jsonHeartbeat, OnHeartbeatPulse);

    // Clean up.
    delete jsonHeartbeat;
    delete playerList;
    delete PlayerObjIP;
}

void OnHeartbeatPulse(HTTPResponse response, any value, const char[] error) // Callback for heartbeat pulse.
{
    if (response.Status != HTTPStatus_OK)
    {
        char HTTPLocation[128];
        response.GetHeader("Location", HTTPLocation, sizeof(HTTPLocation));
        LogError("FATAL ERROR >> Failed to POST Heartbeat Pulse:");
        LogError("---> ENDPOINT = /gs/heartbeat");
        LogError("---> HTTP Status = %d", response.Status);
        LogError("---> ERROR: %s", error);
        return;
    }

    if (FindConVar("gb_enable_debug_mode").BoolValue) // Debug
    {
        LogAction(0, -1, "[GFLBans-Core] DEBUG >> 200 - Successfully sent heartbeat pulse.");
    }

    // TO-DO: Whatever needs to be done after heartbeat pulse has been sent.
}