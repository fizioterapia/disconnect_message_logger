#include <sourcemod>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

enum struct Player {
    int userId;
    char steamId2[64];
    char ip[64];

    void Clear()
    {
        this.userId = 0;
        this.steamId2[0] = '\0';
        this.ip[0] = '\0';
    }
    bool IsEmpty()
    {
        return (strlen(this.steamId2) == 0 || strlen(this.ip) == 0);
    }
}
Player g_pPlayers[MAXPLAYERS+1];

ConVar g_cvLog;
ConVar g_cvBan;

char g_cFilePath[PLATFORM_MAX_PATH];
char g_cIgnoredMessages[11][256] = {
    "timed out",
    "banned",
    "server uses different class tables",
    "kick",
    "dropped due to slot reservation",
    "disconnect by user",
    "client's map differs from the server's",
    "client left game",
    "vac banned",
    "server shutting down",
    "connection closing"
};

char g_cBannableMessages[3][256] = {
    "Greetings from Spook953 & Lak3",
    "Greetings from Spook953 and Lak3",
    "GAS THE NIGGERS AND THE HOMOS"
};

public Plugin myinfo = {
    name        = "Disconnect Message Logger",
    author      = "fizi",
    description = "Logs certain disconnect messages.",
    version     = "0.2.0",
    url         = "https://github.com/fizioterapia"
};

public void OnPluginStart()
{
    BuildPath(Path_SM, g_cFilePath, sizeof(g_cFilePath), "logs/disconnect_logger.log");
    g_cvLog = CreateConVar("sm_disconnect_loginvalid", "1", "Logs not found disconnect messages to file.");
    g_cvBan = CreateConVar("sm_disconnect_ban", "1", "Bans people that have confirmed cheater's disconnect message.");

    HookEvent("player_disconnect", Event_Disconnect);

    AutoExecConfig(true, "disconnect_logger");
}

public void OnClientPutInServer(int client)
{
    if (!client || !IsValidClient(client)) {
        return;
    }

    g_pPlayers[client].userId = GetClientUserId(client);
    GetClientAuthId(client, AuthId_Steam2, g_pPlayers[client].steamId2, 64);
    GetClientIP(client, g_pPlayers[client].ip, 64);
}


// Disconnect
public int ContainsMessage(char[] source, char[] message)
{
    return (StrContains(source, message, false) > -1 || StrEqual(source, message, false));
}

public Action Event_Disconnect(Event event, const char[] name, bool dontBroadcast) 
{
    if (!g_cvLog.BoolValue)
        return Plugin_Continue;

    bool validMessage = false, cheatMessage = false;   
    char disconnectedMessage[256], playerName[256];
    int clientUserid, clientId;

    clientUserid = event.GetInt("userid");
    clientId = GetClient(clientUserid);

    // cannounce sends message twice, it makes sure that only one event is being processed
    if (!IsValidClient(clientId) || g_pPlayers[clientId].IsEmpty()) {
        g_pPlayers[clientId].Clear();
        return Plugin_Continue;
    }

    event.GetString("name", playerName, 256);
    event.GetString("reason", disconnectedMessage, 256);

    for(int i = 0; i < 11; i++)
        if(ContainsMessage(disconnectedMessage, g_cIgnoredMessages[i]))
        {
            validMessage = true;
            break;
        }

    for(int i = 0; i < 3; i++)
        if(ContainsMessage(disconnectedMessage, g_cBannableMessages[i]))
        {
            cheatMessage = true;
            break;
        }

    if(!validMessage)
        LogToFile(g_cFilePath, "%s<%s> | IP: %s - disconnected with a reason: %s", playerName, g_pPlayers[clientId].steamId2, g_pPlayers[clientId].ip, disconnectedMessage);

    if(g_cvBan.BoolValue && cheatMessage)
    {
        LogToFile(g_cFilePath, "%s<%s> | IP: %s - banned due to a reason: %s", playerName, g_pPlayers[clientId].steamId2, g_pPlayers[clientId].ip, disconnectedMessage);
        CPrintToChatAll("{RED} > BOOM {default} | %s<%s> just has been exterminated.", playerName, g_pPlayers[clientId].steamId2);
			
        ServerCommand("sm_addban 0 %s Cheater detected, entry rejected.", g_pPlayers[clientId].steamId2);
        ServerCommand("addip 1440 %s", g_pPlayers[clientId].ip);
        ServerCommand("writeip");
    }

    g_pPlayers[clientId].Clear();

    return Plugin_Continue;
}

// Player
public int GetClient(int userId)
{
    int client = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if (g_pPlayers[i].userId == userId)
        {
            client = i;
            break;
        }
    }

    return client;
}

public int IsValidClient(int client)
{
    return (client > 0 && MaxClients >= client);
}