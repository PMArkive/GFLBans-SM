/* ===== Plugin Info ===== */
#define PLUGIN_NAME "GFLBans - Core"
#define PLUGIN_AUTHOR "Infra"
#define PLUGIN_DESCRIPTION "GFLBans Core plugin"
#define PLUGIN_VERSION "<VERSION>"
#define PLUGIN_URL "https://github.com/GFLClan"

/* ===== Global Variables ===== */
ConVar g_cvAPIUrl;
ConVar g_cvAPIKey;
ConVar g_cvAPIServerID;
ConVar g_cvAcceptGlobalBans;
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
#define PREFIX "\x01[\x0CGFLBans\x01]"

/* ===== Enum Struct ===== */
