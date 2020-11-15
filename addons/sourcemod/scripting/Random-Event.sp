#include <sourcemod>
#include <store>

#pragma semicolon 1
#pragma newdecls required

ConVar g_Eventtime = null, g_MinSayi = null, g_MaxSayi = null, g_Beklemesure = null, g_Kredi = null, g_KrediR = null;

bool EventEnable = false, Sureaktif = false;

Handle g_Timer = null, g_Timer_Sayi = null, g_Timer_Sure = null;

int Sira, Sayi, Kalansure;

public Plugin myinfo = 
{
	name = "Kredi Etkinliği", 
	author = "ByDexter", 
	description = "", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_event", EventZaman);
	RegConsoleCmd("sm_eventkalan", EventZaman);
	/* Random Number Event */
	g_MinSayi = CreateConVar("sm_randomnumber_min", "1", "Sayı etkinliğinde en düşük değer", 0, true, 0.0);
	g_MaxSayi = CreateConVar("sm_randomnumber_max", "15", "Sayı etkinliğinde en yüksek değer", 0, true, 1.0);
	g_Beklemesure = CreateConVar("sm_randomnumber_time", "10", "Sayı etkinliği başladıktan sonraki yanıt süresi (Saniye)", 0, true, 0.0);
	g_Kredi = CreateConVar("sm_randomnumber_credit", "1500", "Numarayı bilen oyuncuya verilecek kredi ?", 0, true, 0.0);
	/* Random Player */
	g_KrediR = CreateConVar("sm_randomplayer_credit", "1500", "Rastgele çıkan oyuncuya verilecek kredi ?", 0, true, 0.0);
	/* Event */
	g_Eventtime = CreateConVar("sm_event_minute", "15", "Etkinlik kaç dakika arayla olmalıdır ?", 0, true, 0.0);
	/* Auto Exec Config */
	AutoExecConfig(true, "Random-Event", "ByDexter");
}

public void OnMapStart()
{
	Sira = GetRandomInt(1, 2);
	Olustur();
}

public void OnMapEnd()
{
	Sifirlama();
}

public Action ZamanEksilt(Handle timer, any data)
{
	if (Sureaktif)
	{
		Kalansure--;
	}
	else
	{
		if (g_Timer_Sure != null)
		{
			delete g_Timer_Sure;
			g_Timer_Sure = null;
		}
	}
}

public Action EventZaman(int client, int args)
{
	if (Sureaktif)
	{
		if (Sira == 1)
		{
			ReplyToCommand(client, "[SM] \x01Rastgele sayı kalan: \x04%d Dakika", Kalansure);
			return Plugin_Handled;
		}
		else if (Sira == 2)
		{
			ReplyToCommand(client, "[SM] \x01Rastgele şanslı kişi kalan: \x04%d Dakika", Kalansure);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01Etkinlik başlamış!");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action EventStart(Handle timer, any data)
{
	g_Timer = null;
	Sifirlama();
	if (Sira == 1)
	{
		Sira = 2;
		EventEnable = true;
		Sayi = GetRandomInt(g_MinSayi.IntValue, g_MaxSayi.IntValue);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				Handle ScreenText = CreateHudSynchronizer();
				SetHudTextParams(-1.0, -0.35, 3.0, 0, 255, 0, 0, 2, 1.0, 0.01, 0.01);
				ShowSyncHudText(i, ScreenText, "%d ile %d arasında rastgele sayı | Ödül: %d Kredi", g_MinSayi.IntValue, g_MaxSayi.IntValue, g_Kredi.IntValue);
				delete ScreenText;
			}
		}
		if (g_Timer_Sayi != null)
			delete g_Timer_Sayi;
		g_Timer_Sayi = CreateTimer(g_Beklemesure.FloatValue, EventIptal);
	}
	else if (Sira == 2)
	{
		Sira = 1;
		int Sanslikisi = RastgeleKisi();
		Store_SetClientCredits(Sanslikisi, Store_GetClientCredits(Sanslikisi) + g_KrediR.IntValue);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				char isim[MAX_NAME_LENGTH];
				GetClientName(Sanslikisi, isim, sizeof(isim));
				Handle ScreenText = CreateHudSynchronizer();
				SetHudTextParams(-1.0, -0.35, 3.0, 0, 255, 0, 0, 2, 1.0, 0.01, 0.01);
				ShowSyncHudText(i, ScreenText, "Kazanan: %s", isim);
				delete ScreenText;
			}
		}
		PrintToChat(Sanslikisi, "[SM] \x0C%d Kredi \x01Kazandın!", g_KrediR.IntValue);
		PrintToChatAll("[SM] \x0C%d dakika \x01sonra rastgele sayı etkinliği yapılacaktır!", g_Eventtime.IntValue);
		Olustur();
	}
}

public Action EventIptal(Handle timer)
{
	if (EventEnable)
		EventEnable = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Handle ScreenText = CreateHudSynchronizer();
			SetHudTextParams(-1.0, -0.35, 3.0, 0, 255, 0, 0, 2, 1.0, 0.01, 0.01);
			ShowSyncHudText(i, ScreenText, "Kimse bulamadı :c");
			delete ScreenText;
		}
	}
	PrintToChatAll("[SM] \x0C%d Dakika \x01sonra rastgele kişi etkinliği yapılacaktır!", g_Eventtime.IntValue);
	Olustur();
	g_Timer_Sayi = null;
	return Plugin_Stop;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if (EventEnable)
	{
		char RandomSayi[32];
		IntToString(Sayi, RandomSayi, sizeof(RandomSayi));
		if (!(strcmp(sArgs, RandomSayi, false)))
		{
			Sifirlama();
			Store_SetClientCredits(client, Store_GetClientCredits(client) + g_Kredi.IntValue);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					char isim[MAX_NAME_LENGTH];
					GetClientName(client, isim, sizeof(isim));
					Handle ScreenText = CreateHudSynchronizer();
					SetHudTextParams(-1.0, -0.35, 3.0, 0, 255, 0, 0, 2, 1.0, 0.01, 0.01);
					ShowSyncHudText(i, ScreenText, "Kazanan: %s", isim);
					delete ScreenText;
				}
			}
			PrintToChat(client, "[SM] \x0C%d Kredi \x01Kazandın!", g_Kredi.IntValue);
			PrintToChatAll("[SM] \x0C%d Dakika \x01sonra rastgele kişi etkinliği yapılacaktır!", g_Eventtime.IntValue);
			Olustur();
		}
	}
}

void Sifirlama()
{
	if (g_Timer_Sure != null)
	{
		delete g_Timer_Sure;
		g_Timer_Sure = null;
	}
	if (g_Timer != null)
	{
		delete g_Timer;
		g_Timer = null;
	}
	if (Sureaktif)
		Sureaktif = false;
	if (EventEnable)
		EventEnable = false;
}

void Olustur()
{
	if (!Sureaktif)
		Sureaktif = true;
	float Sure = g_Eventtime.FloatValue;
	Kalansure = g_Eventtime.IntValue;
	Sure = Sure * 60;
	g_Timer_Sure = CreateTimer(60.0, ZamanEksilt, _, TIMER_REPEAT);
	g_Timer = CreateTimer(Sure, EventStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

int RastgeleKisi()
{
	int clients[MAXPLAYERS + 1], clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}
