#pragma semicolon 1 
#pragma tabsize 0;
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <smlib>

#define CFG_NAME "awp_scout_deagle"

new	Handle:g_givedeagle = INVALID_HANDLE;
new	Handle:g_deagleonebullet = INVALID_HANDLE;
new	Handle:g_removebuyzone = INVALID_HANDLE;

int g_iawp_scout;
ConVar g_disableknife;
ConVar g_noscope;
ConVar g_deaglehsonly;
ConVar g_scouthsonly;
ConVar g_deletemapweapons;
ConVar g_deletedropweapons;
ConVar g_oneshotawp;
ConVar g_awp_scout;


g_bKnifeDamage = false;
g_bnoawpscope = false;
g_bhsonly = false;
g_bscouthsonly = false;

char CfgFile[PLATFORM_MAX_PATH];

public Plugin:myinfo = 
{
	name = "Awp / Scout / Deagle / Knife Mode",
	author = "Gold_KingZ",
	description = "Scout Awp Deagle Knife Mode",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/oQYh"
}


public OnPluginStart()
{
	Format(CfgFile, sizeof(CfgFile), "sourcemod/%s.cfg", CFG_NAME);
	
	g_awp_scout = CreateConVar( "sm_awp_or_scout", "1", "Force Give Knife / Awp / Scout / Deagle || 0= Knife Only || 1= Awp || 2= Scout || 3= Deagle Only (sm_give_deagle)");
	g_oneshotawp = CreateConVar("sm_oneshot_awp", "1", "Enable One Shot Awp Kill ( leg shot ) || 1= Yes || 0= No");
	g_givedeagle = CreateConVar( "sm_give_deagle", "1", "Force Give Deagle || 1= Yes || 0= No");
	g_deagleonebullet = CreateConVar( "sm_deagle_onebullet", "1", "Deagle One Bullet || 1= Yes || 0= No");
	g_deaglehsonly = CreateConVar( "sm_deagle_hsonly", "1", "Deagle Head Shot Only || 1= Yes || 0= No");
	g_scouthsonly = CreateConVar( "sm_scout_hsonly", "1", "Scout Head Shot Only || 1= Yes || 0= No");
	g_removebuyzone = CreateConVar( "sm_disable_buyzone", "1", "Disable Buy Zone || 1= Yes || 0= No");
	g_noscope = CreateConVar( "sm_disable_scope", "1", "Disable Scope || 1= Yes || 0= No");
	g_disableknife = CreateConVar("sm_disable_knife_damage", "1", "Disable Knife Damage || 1= Yes || 0= No");
	g_deletemapweapons = CreateConVar("sm_delete_map_weapons", "1", "Delete Map Weapons || 1= Yes || 0= No");
	g_deletedropweapons = CreateConVar("sm_delete_drop_weapons", "1", "Delete Drop Weapons || 1= Yes || 0= No");

	HookEvent( "player_spawn",	Event_PlayerAwp);
	HookConVarChange(g_disableknife, OnSettingsChanged);
	HookConVarChange(g_noscope, OnSettingsChanged);
	HookConVarChange(g_deaglehsonly, OnSettingsChanged);
	HookConVarChange(g_scouthsonly, OnSettingsChanged);
	HookEvent("weapon_zoom", Fun_EventWeaponZoom, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post); 
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
	
	RegPluginLibrary("spirt_deaglehs");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamages);
		}
	}

	LoadCfg();
	
}

void LoadCfg()
{
	AutoExecConfig(true, CFG_NAME);
}

public void OnMapStart()
{
    if(g_deletemapweapons.BoolValue)
        ServerCommand("sm_cvar mp_weapons_allow_map_placed 0");
		
	if(g_deletedropweapons.BoolValue)
	{
	SetCvarInt("weapon_auto_cleanup_time", 5);
	SetCvarInt("weapon_max_before_cleanup", 5);
	}
}

public Event_PlayerAwp( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	new wepIdx;

	for( new i = 0; i < 5; i++ ){
		if( i == 2 ) continue; 
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
			RemovePlayerItem( client, wepIdx );
			}
		}

	switch( g_iawp_scout )
	{
	case 1: {
	GivePlayerItem( client, "weapon_awp" );
	ClientCommand( client, "slot1" );
		
	if( !GetConVarBool( g_givedeagle ) )
		return;
		
	GivePlayerItem( client, "weapon_deagle" );
	ClientCommand( client, "slot1" );
	
	}
	
	case 2: 
	{
	GivePlayerItem( client, "weapon_ssg08" );
	ClientCommand( client, "slot1" );
	
	if( !GetConVarBool( g_givedeagle ) )
		return;
		
	GivePlayerItem( client, "weapon_deagle" );
	ClientCommand( client, "slot1" );
	}
	case 3: {
	if( !GetConVarBool( g_givedeagle ) )
		return;
		
	GivePlayerItem( client, "weapon_deagle" );
	ClientCommand( client, "slot1" );
	
	}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamages);
}

public void Hook_PostThinkPost(int entity)
{
	if( !GetConVarBool( g_removebuyzone ) )
		return;
	
	SetEntProp(entity, Prop_Send, "m_bInBuyZone", 0);
}

public int OnSettingsChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == g_disableknife)
	{
		g_bKnifeDamage = !!StringToInt(newValue);
	}
	
	if(convar == g_noscope)
	{
		g_bnoawpscope = g_noscope.BoolValue;
	}
	
	if(convar == g_deaglehsonly)
	{
		g_bhsonly = g_deaglehsonly.BoolValue;
	}
	
		if(convar == g_scouthsonly)
	{
		g_bscouthsonly = g_scouthsonly.BoolValue;
	}
}

public void OnConfigsExecuted()
{
	g_bKnifeDamage = GetConVarBool(g_disableknife);
	g_bnoawpscope = GetConVarBool(g_noscope);
	g_bhsonly = GetConVarBool(g_deaglehsonly);
	g_bscouthsonly = GetConVarBool(g_scouthsonly);
	g_iawp_scout = g_awp_scout.IntValue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsValidEntity(weapon) || !g_bKnifeDamage)
		return Plugin_Continue;
	if (attacker <= 0 || attacker > MaxClients)
		return Plugin_Continue;
	char WeaponName[20];
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
	if(StrContains(WeaponName, "knife", false) != -1 || StrContains(WeaponName, "bayonet", false) != -1 || StrContains(WeaponName, "fists", false) != -1 || StrContains(WeaponName, "axe", false) != -1 || StrContains(WeaponName, "hammer", false) != -1 || StrContains(WeaponName, "spanner", false) != -1 || StrContains(WeaponName, "melee", false) != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action Fun_EventWeaponZoom(Handle hEvent, const char[] name, bool bDontBroadcast)
{
if (g_bnoawpscope)
	{
		int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client)) {
			int ent = GetPlayerWeaponSlot(client, 0);
			CS_DropWeapon(client, ent, true, true);
			CPrintToChat(client, "{darkred}Scope Is NOT Allowed!");
	}
}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!g_oneshotawp.BoolValue || attacker == 0 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	
	int active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEntity(active))
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetEntityClassname(active, sWeapon, sizeof(sWeapon));
	
	if (!StrEqual(sWeapon, "weapon_awp", false))
	{
		return Plugin_Continue;
	}
	
	damage = float(GetClientHealth(victim) + GetClientArmor(victim));
	return Plugin_Changed;
}


public Action OnTakeDamages(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(IsValidEdict(weapon))
	{
	if (g_bhsonly)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "weapon_deagle"))
		{
			if (damagetype &= CS_DMG_HEADSHOT)
			{
				return Plugin_Continue;
			}
			
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	if (g_bscouthsonly)
	{
		char sWeapon[32];
		GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "weapon_ssg08"))
		{
			if (damagetype &= CS_DMG_HEADSHOT)
			{
				return Plugin_Continue;
			}
			
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	}
	return Plugin_Continue;
}


public void Event_WeaponFire(Event event, const char[] sEventName, bool bDontBroadcast)
{ 
	if( !GetConVarBool( g_deagleonebullet ) )
		return;
    int client = GetClientOfUserId(GetEventInt(event, "userid")); 

    char sWeapon[65];
    event.GetString("weapon", sWeapon, sizeof(sWeapon));
    
    if (StrEqual(sWeapon, "weapon_deagle")) 
    {
    	    CreateTimer(0.05, RemoveDeagle, client);
    } 
}  

public Action RemoveDeagle(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client))) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
		CreateTimer(0.15, GiveDeagle, client);
	}
}

public Action GiveDeagle(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client))) 
		GivePlayerItem(client, "weapon_deagle");
		Client_SetActiveWeapon(client, GetPlayerWeaponSlot(client, 1)); 
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
stock void SetCvarInt(char[] scvar, int svalue)
{
	SetConVarInt(FindConVar(scvar), svalue, true);
}