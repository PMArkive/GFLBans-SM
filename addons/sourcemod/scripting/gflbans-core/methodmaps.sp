methodmap PlayerObjNoIp < JSONObject
{
	public PlayerObjNoIp() { return view_as<PlayerObjNoIp>(new JSONObject()); }
	
	public void GetService(char[] buffer, int maxlength)
	{
		this.GetString("gs_service", buffer, maxlength);
	}
	
	public void SetService(const char[] buffer)
	{
		this.SetString("gs_service", buffer);
	}
	
	public void GetID(char[] buffer, int maxlength)
	{
		this.GetString("gs_id", buffer, maxlength);
	}
	
	public void SetID64(int client)
	{
		char playerID64[64];
		GetClientAuthId(client, AuthId_SteamID64, playerID64, sizeof(playerID64), true);
		this.SetString("gs_id", playerID64);
	}
}

methodmap PlayerObjIPOptional < PlayerObjNoIp
{
	public PlayerObjIPOptional() { return view_as<PlayerObjIPOptional>(new JSONObject()); }
	
	public void GetIP(char[] buffer, int maxlength)
	{
		this.GetString("ip", buffer, maxlength);
	}
	
	public void SetIP(int client)
	{
		char playerIP[32];
		GetClientIP(client, playerIP, sizeof(playerIP), true);
		this.SetString("ip", playerIP);
	}
}

methodmap CInfractionSummary < JSONObject
{
	property int Expiration
	{
		public get()
		{
			if (this.IsNull("expiration"))
				return 0;
				
			return this.GetInt("expiration");
		}
	}
	
	public void GetReason(char[] buffer, int maxlength)
	{
		this.GetString("reason", buffer, maxlength);
	}
	
	public void GetAdminName(char[] buffer, int maxlength)
	{
		this.GetString("admin_name", buffer, maxlength);
	}
}

methodmap CheckInfractionsReply < JSONObject
{
	public CheckInfractionsReply() { return view_as<CheckInfractionsReply>(new JSONObject()); }
	
	property CInfractionSummary VoiceBlock
	{
		public get()
		{
			if (this.IsNull("voice_block"))
				return null;
				
			return view_as<CInfractionSummary>(this.Get("voice_block"));
		}
	}
	
	property CInfractionSummary ChatBlock
	{
		public get()
		{
			if (this.IsNull("chat_block"))
				return null;
				
			return view_as<CInfractionSummary>(this.Get("chat_block"));
		}
	}
	
	property CInfractionSummary Ban
	{
		public get()
		{
			if (this.IsNull("ban"))
				return null;
				
			return view_as<CInfractionSummary>(this.Get("ban"));
		}
	}
	
	property CInfractionSummary AdminChatBlock
	{
		public get()
		{
			if (this.IsNull("admin_chat_block"))
				return null;
				
			return view_as<CInfractionSummary>(this.Get("admin_chat_block"));
		}
	}
	
	property CInfractionSummary CallAdminBlock
	{
		public get()
		{
			if (this.IsNull("call_admin_block"))
				return null;
				
			return view_as<CInfractionSummary>(this.Get("call_admin_block"));
		}
	}
	
	
}

