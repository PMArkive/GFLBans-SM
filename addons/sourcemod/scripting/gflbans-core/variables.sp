/* ===== Plugin Info ===== */
#define PLUGIN_NAME                 "GFLBans - Core"
#define PLUGIN_AUTHOR               "Infra"
#define PLUGIN_DESCRIPTION          "GFLBans Core plugin"
#define PLUGIN_VERSION              "<VERSION>"
#define PLUGIN_URL                  "https://github.com/GFLClan"

/* ===== Global Variables ===== */
ConVar g_cvAPIUrl;
ConVar g_cvAPIKey;
ConVar g_cvAPIServerID;

ConVar g_cvAcceptGlobalBans;
ConVar g_cvInfractionScope;

ConVar g_cvDebug;

char g_sAPIUrl[512];
char g_sMap[64];
char g_sMod[16];
char g_sServerHostname[96];
char g_sServerOS[8];

int g_iMaxPlayers;

bool g_bServerLocked;

Handle hbTimer;

HTTPClient httpClient;

/* ===== Definitions ===== */
#define PREFIX " \x01[\x0CGFLBans\x01]\x05 "

/* ===== Forwards ===== */
GlobalForward g_gfOnPunishAdded;
GlobalForward g_gfOnPunishRemoved;

/* ===== Enum Struct ===== */
enum struct PlayerInfo
{
    bool gagIsGagged;
    int gagExpiration;
    char gagReason[256];
    char gagAdminName[256];
    PunishmentType gagType;
    
    bool muteIsMuted;
    int muteExpiration;
    char muteReason[256];
    char muteAdminName[256];
    PunishmentType muteType;
    
    Handle gagTimer;
    Handle muteTimer;
    
    void ClearAll()
    {
        this.gagIsGagged = false;
        this.gagExpiration = 0;
        this.gagReason[0] = '\0';
        this.gagAdminName[0] = '\0';
        this.gagType = P_NOT;
        
        this.muteExpiration = 0;
        this.muteIsMuted = false;
        this.muteReason[0] = '\0';
        this.muteAdminName[0] = '\0';
        this.muteType = P_NOT;
        
        delete this.gagTimer;
        delete this.muteTimer;
    }
    
    void ClearGag()
    {
        this.gagIsGagged = false;
        this.gagExpiration = 0;
        this.gagReason[0] = '\0';
        this.gagAdminName[0] = '\0';
        this.gagType = P_NOT;
        
        delete this.gagTimer;
    }
    
    void ClearMute()
    {
        this.muteIsMuted = false;
        this.muteExpiration = 0;
        this.muteReason[0] = '\0';
        this.muteAdminName[0] = '\0';
        this.muteType = P_NOT;
        
        delete this.muteTimer;
    }
}

PlayerInfo g_esPlayerInfo[MAXPLAYERS+1];