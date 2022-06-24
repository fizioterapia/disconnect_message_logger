#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar g_cvLog;

char g_FilePath[PLATFORM_MAX_PATH];

char ignoredMessages[10][256] = {
    "timed out",
    "banned",
    "server uses different class tables",
    "kick",
    "dropped due to slot reservation",
    "disconnect by user",
    "client's map differs from the server's",
    "client left game",
    "vac banned",
    "server shutting down"
};

int g_Clients[25];
char g_SteamID[25][64];

public Plugin myinfo = {
    name        = "Disconnect Message Logger",
    author      = "fizi",
    description = "Logs certain disconnect messages.",
    version     = "0.0.1",
    url         = "https://github.com/fizioterapia"
};

public void OnPluginStart()
{
    BuildPath(Path_SM, g_FilePath, sizeof(g_FilePath), "logs/disconnect_logger.log");
    g_cvLog = CreateConVar("sm_disconnect_loginvalid", "1", "Logs not found disconnect messages to file.");

    HookEvent("player_disconnect", Event_Disconnect);

    for(int i = 0; i < 25; i++)
        g_SteamID[i][0] = '\0';
}

public void OnClientPutInServer(int client)
{
    if (!client) {
        return;
    }

    g_Clients[client] = GetClientUserId(client);
    GetClientAuthId(client, AuthId_Steam2, g_SteamID[client], sizeof(g_SteamID[]));
}

public Action Event_Disconnect(Event event, const char[] name, bool dontBroadcast) 
{
    if (g_cvLog.BoolValue != true)
        return Plugin_Continue;
    
    char disconnectedMessage[256];
    char player_name[256];
    char buffer_real[256];

    int client_userid;
    int client_id;

    client_userid = event.GetInt("userid");
    for(int i = 1; i < 25; i++) {
        if (g_Clients[i] == client_userid) {
            client_id = i;
            g_Clients[i] = -1;
            break;
        }
    }

    event.GetString("name", player_name, 256);
    event.GetString("reason", disconnectedMessage, 256);
    strcopy(buffer_real, 256, disconnectedMessage);

    for(int i = 0; i < 256; i++) {
        if (buffer_real[i] == '\0') {
            break;
        }
        buffer_real[i] = CharToLower(buffer_real[i]);
    }

    for(int i = 0; i < 10; i++) {
        if (StrContains(buffer_real, ignoredMessages[i]) == 0) {
            client_id = 0;
            g_SteamID[client_id][0] = '\0';

            return Plugin_Continue;
        }
    }

    if(client_id > 0)
        LogToFile(g_FilePath, "%s<%s> disconnected with a reason: %s", player_name, g_SteamID[client_id], disconnectedMessage);

    client_id = 0;
    g_SteamID[client_id][0] = '\0';

    return Plugin_Continue;
}
