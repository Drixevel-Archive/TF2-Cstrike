/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Cstrike"
#define PLUGIN_DESCRIPTION "A Counter-Strike gamemode for Team Fortress 2."
#define PLUGIN_VERSION "1.0.0"

#define TYPE_SET 0
#define TYPE_ADD 1
#define TYPE_SUB 2

/*****************************/
//Includes
#include <sourcemod>
#include <sourcemod-misc>
#include <sourcemod-colors>

/*****************************/
//ConVars

/*****************************/
//Globals

enum struct PlayersData
{
	int cash;
	int armor;

	void Reset()
	{
		this.cash = 0;
		this.armor = 0;
	}

	void AddCash(int value)
	{
		this.cash += value;

		if (this.cash > 16000)
			this.cash = 16000;
	}

	void SetCash(int value)
	{
		this.cash = value;
	}

	bool RemoveCash(int value)
	{
		if (this.cash < value)
			return false;
		
		this.cash -= value;
		return true;
	}

	void AddArmor(int value)
	{
		this.armor += value;

		if (this.armor > 16000)
			this.armor = 16000;
	}

	void SetArmor(int value)
	{
		this.armor = value;
	}

	bool RemoveArmor(int value)
	{
		if (this.armor < value)
			return false;
		
		this.armor -= value;
		return true;
	}
}

PlayersData g_PlayersData[MAXPLAYERS + 1];
Hud g_PlayerHud;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	HookEvent("teamplay_round_start", Event_OnRoundStart);
	HookEvent("player_death", Event_OnPlayerDeath);

	g_PlayerHud = new Hud();

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnPluginEnd()
{
	g_PlayerHud.ClearAll();
}

public void Event_OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(5.0, Timer_DisplayWeaponsMenu, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DisplayWeaponsMenu(Handle timer, any data)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		g_PlayersData[i].SetCash(800);
		g_PlayersData[i].SetArmor(100);
		UpdateHud(i);

		SendWeaponsMenu(i);
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (attacker > 0)
	{
		g_PlayersData[attacker].AddCash(600);
		UpdateHud(attacker);
	}
}

void SendWeaponsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Weapons);
	menu.SetTitle("Pick a type:");

	menu.AddItem("pistols", "Pistols");
	menu.AddItem("heavy", "Heavy");
	menu.AddItem("smgs", "SMGs");
	menu.AddItem("rifles", "Rifles");
	menu.AddItem("gear", "Gear");
	menu.AddItem("grenades", "Grenades");

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Weapons(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sType[32]; char sDisplay[32];
			menu.GetItem(param2, sType, sizeof(sType), _, sDisplay, sizeof(sDisplay));

			OpenItemsMenu(param1, sType, sDisplay);
		}

		case MenuAction_End:
			delete menu;
	}
}

void OpenItemsMenu(int client, const char[] type, const char[] display)
{
	Menu menu = new Menu(MenuHandler_Items);
	menu.SetTitle("Pick a %s:", display);
	
	if (StrEqual(type, "pistols"))
	{
		menu.AddItem("", "[N/A]");
	}
	else if (StrEqual(type, "heavy"))
	{
		menu.AddItem("", "[N/A]");
	}
	else if (StrEqual(type, "smgs"))
	{
		menu.AddItem("", "[N/A]");
	}
	else if (StrEqual(type, "rifles"))
	{
		menu.AddItem("", "[N/A]");
	}
	else if (StrEqual(type, "gear"))
	{
		menu.AddItem("", "[N/A]");
	}
	else if (StrEqual(type, "grenades"))
	{
		menu.AddItem("", "[N/A]");
	}

	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Items(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char sType[32]; char sDisplay[32];
			menu.GetItem(param2, sType, sizeof(sType), _, sDisplay, sizeof(sDisplay));

			g_PlayersData[param1].RemoveCash(600);
			UpdateHud(param1);
		}

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				SendWeaponsMenu(param1);
		}

		case MenuAction_End:
			delete menu;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (attacker > 0 && attacker <= MaxClients && g_PlayersData[victim].armor > 0)
	{
		int dmg = RoundFloat(damage);

		if (g_PlayersData[victim].armor >= dmg)
		{
			g_PlayersData[victim].RemoveArmor(dmg);
			UpdateHud(victim);
			damage = 0.0;
			return Plugin_Changed;
		}
		else
		{
			int difference = dmg - g_PlayersData[victim].armor;
			g_PlayersData[victim].RemoveArmor(difference);
			UpdateHud(victim);
			damage = float(difference);
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

public void OnClientDisconnect_Post(int client)
{
	g_PlayersData[client].Reset();
}

void UpdateHud(int client)
{
	g_PlayerHud.SetParams(0.1, 0.95, 99999.0, 0, 255, 0, 255);
	g_PlayerHud.Send(client, "Cash: %i\nArmor: %i", g_PlayersData[client].cash, g_PlayersData[client].armor);
}

public Action TF2_OnClassChange(int client, TFClassType& class)
{
	if (class != TFClass_Sniper)
	{
		class = TFClass_Sniper;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public void TF2_OnPlayerSpawn(int client, int team, int class)
{
	if (TF2_GetPlayerClass(client) != TFClass_Sniper)
	{
		TF2_SetPlayerClass(client, TFClass_Sniper);
		TF2_RegeneratePlayer(client);
	}

	CreateTimer(0.2, Timer_UpdateWeapons, client);
}

public Action Timer_UpdateWeapons(Handle timer, any data)
{
	int client = data;

	EquipWeaponSlot(client, 2);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "func_respawnroom", false))
		SDKHook(entity, SDKHook_Spawn, OnRespawnRoomSpawn);
}

public Action OnRespawnRoomSpawn(int entity)
{
	if (IsValidEntity(entity))
		AcceptEntityInput(entity, "Kill");
}