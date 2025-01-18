#include <amxmodx>
#include <hamsandwich>
#include <engine>
#include <cstrike>
#include <fun>
#include <fakemeta>

// --------------------------------------------
//   ------------- DE EDITAT ---------------
// --------------------------------------------
new const TAG[] = "[CS]";		// TAGUL IN CHAT CARE APARE
new const CONTACT[] = "mosu discord:mosu3828";

new const VIP_MODEL_T[] = "models/player/vip_t/vip_t.mdl";
new const VIP_MODEL_CT[] = "models/player/vip_ct/vip_ct.mdl";


#define is_user_vip(%1) (get_user_flags(%1) & read_flags("bit"))

// --------------------------------------------
//   ------------- NU SCHIMBA ---------------
// --------------------------------------------

#define PLUGIN_NAME "VIP System"
#define PLUGIN_NAME_PAUSED "VIP System [OPRIT]"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "YONTU"

#define is_user_valid(%1) (1 <= %1 <= max_players)

enum cvars
{
	hp_spawn = 0,
	ap_spawn,
	money_spawn,
	hp_kill,
	hp_hs,
	ap_kill,
	ap_hs,
	hp_max,
	money_kill,
	money_hs,
	show_vip_tab,
	show_bullet_dmg,
	multi_jump,
	parachute,
	noflash
}

new cvar[cvars], rounds = 0;
new max_players;
new bool:g_bJump[33] = false, g_JumpNum[33] = 0;
new g_iPlayerPos[33], g_iPlayerCol[33];

// NU SCHIMBA
new const Float:g_flCoords[][] =  
{ 
	{0.50, 0.40}, 
	{0.56, 0.44}, 
	{0.60, 0.50}, 
	{0.56, 0.56}, 
	{0.50, 0.60}, 
	{0.44, 0.56}, 
	{0.40, 0.50}, 
	{0.44, 0.44} 
}

// NU SCHIMBA VALORILE DEJA EXISTENTE. Poti adauga mai multe culori, respectand matricea
new const g_iColors[][] = 
{ 
	{0, 127, 255}, // blue 
	{255, 127, 0}, // orange 
	{127, 0, 255}, // purple 
	{255, 0, 0}, // red 
	{255, 100, 150}, // pink
	{0, 255, 0} // green
}

public plugin_init()
{	
	new path[64];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	formatex(path, charsmax(path), "%s/vip_maps.ini", path);
	
	new file = fopen(path, "r+");
	
	if(!file_exists(path))
	{
		write_file(path, "; VIP-UL ESTE DEZACTIVAT PE URMATOARELE HARTI: ");
		write_file(path, "; Exemplu de adaugare HARTA:^n; ^"harta^"^n^nfy_snow^ncss_bycastor");
	}
	
	new mapname[32];
	get_mapname(mapname, charsmax(mapname));
	
	new text[121], maptext[32], bool:remove_vip = false;
	while(!feof(file))
	{
		fgets(file, text, charsmax(text));
		trim(text);
		
		if(text[0] == ';' || !strlen(text)) 
		{
			continue; 
		}
		
		parse(text, maptext, charsmax(maptext));
		
		if(equal(maptext, mapname))
		{
			log_amx("Am dezactivat pluginul 'VIP' pe harta %s.", maptext);
			remove_vip = true;
			break;
		}
		
	}
	fclose(file);
	
	if(!remove_vip)
	{
		register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

		register_event("DeathMsg", "event_DeathMsg", "a");
		register_event("Damage", "event_Damage", "b", "2>0", "3=0");
		register_event("CurWeapon", "event_CurWeapon", "be", "1=1");
		register_event("WeapPickup", "event_WeapPickup", "b");
		register_event("HLTV", "event_NewRound", "a", "1=0", "2=0");
		register_event("TextMsg", "event_textmsg", "a", "2=#Game_will_restart_in")

		RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawnPost", 1);
		RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon");

		register_message(get_user_msgid("ScoreAttrib"), "msg_ScoreAttrib");
		register_message(get_user_msgid("ScreenFade"), "msg_ScreenFade");

		register_clcmd("say /vips", "CmdVipsOnline");
		register_clcmd("say_team /vips", "CmdVipsOnline");
		register_clcmd("say vips", "CmdVipsOnline");
		register_clcmd("say_team vips", "CmdVipsOnline");
		
		register_clcmd("say vreauvip", "CmdPrintAttributes");
		register_clcmd("say_team vreauvip", "CmdPrintAttributes");
		register_clcmd("say /vreauvip", "CmdPrintAttributes");
		register_clcmd("say_team /vreauvip", "CmdPrintAttributes");

        cvar[hp_spawn] = register_cvar("vip_hp_spawn", "0");			// 0 = dezactivat
		cvar[ap_spawn] = register_cvar("vip_ap_spawn", "0");			// 0 = dezactivat
		cvar[money_spawn] = register_cvar("vip_money_spawn", "0");		// 0 = dezactivat
		cvar[show_vip_tab] = register_cvar("vip_show_tab", "1");			// 0 = dezactivat
		cvar[show_bullet_dmg] = register_cvar("vip_show_bullet_dmg", "0");		// 0 = dezactivat
		cvar[multi_jump] = register_cvar("vip_multijump", "1");			// 0 = dezactivat. Daca valoarea cvar-ului este 1, vei sari de 2 ori. Orice valoare pui, va fi +1 jump
		cvar[hp_kill] = register_cvar("vip_hp_kill", "5");				// 0 = dezactivat
		cvar[hp_hs] = register_cvar("vip_hp_hs", "5");				// 0 = dezactivat
		cvar[ap_kill] = register_cvar("vip_ap_kill", "5");				// 0 = dezactivat
		cvar[ap_hs] = register_cvar("vip_ap_hs", "5");				// 0 = dezactivat
		cvar[hp_max] = register_cvar("vip_hp_max", "100");			// 0 = viata infinita
		cvar[money_kill] = register_cvar("vip_money_kill", "0");			// 0 = dezactivat
		cvar[money_hs] = register_cvar("vip_money_hs", "0");			// 0 = dezactivat
		cvar[parachute] = register_cvar("vip_parachute", "0");			// 0 = dezactivat
		cvar[noflash] = register_cvar("vip_noflash", "0");				// 0 = dezactivat

		max_players = get_maxplayers();
	}
	else
	{
		register_plugin(PLUGIN_NAME_PAUSED, PLUGIN_VERSION, PLUGIN_AUTHOR);
		pause("ade");
	}
	
	register_cvar("vip_", PLUGIN_VERSION, FCVAR_SPONLY|FCVAR_SERVER);
	set_cvar_string("vip_", PLUGIN_VERSION);
}

public plugin_precache()
{
    precache_model(VIP_MODEL_T);
    precache_model(VIP_MODEL_CT);
}


public client_putinserver(id)
{
	g_JumpNum[id] = 0;
	g_bJump[id] = false;
}

public CmdVipsOnline(id)
{
	if(!is_user_connected(id))
		return PLUGIN_CONTINUE;

	new adminnames[33][32], message[256], i, count, len;
	len = format(message, charsmax(message), "!4%s!3 VIPS ONLINE: ", TAG);
	for(i = 1 ; i <= max_players; i++)
	{
		if(is_user_connected(i) && is_user_vip(i))
			get_user_name(i, adminnames[count++], charsmax(adminnames[]));
	}
	
	if(count > 0)
	{
		for(i = 0; i < count; i++)
		{
			len += format(message[len], 255 -len, "!4%s!1%s ", adminnames, i < (count -1) ? " | " : "");
		}
		ColorChat(id, message);
	}
	else
	{
		len += format(message[len], 255 -len, "!4No one !")
		ColorChat(id, message);
	}

	return PLUGIN_CONTINUE;
}

public CmdPrintAttributes(id)
{
	if(!is_user_connected(id)) return;
	show_motd(id, "vip.txt", "Beneficii VIP");
}

public client_PreThink(id)
{
	new cache = get_pcvar_num(cvar[multi_jump]);
	if(is_user_alive(id) && !is_user_vip(id))
		return PLUGIN_CONTINUE;

	new nbut = get_user_button(id);
	new obut = get_user_oldbutton(id);

	if(cache != 0)
	{	
		if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
		{
			if(g_JumpNum[id] < cache)
			{
				g_bJump[id] = true;
				g_JumpNum[id]++;
				return PLUGIN_CONTINUE;
			}
		}
	
		if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
		{
			g_JumpNum[id] = 0;
			return PLUGIN_CONTINUE;
		}
	}

	if(get_pcvar_num(cvar[parachute]))
	{
		new Float:fallspeed = 100.0 * -1.0;
		if(nbut & IN_USE) 
		{
			new Float:velocity[3];
			entity_get_vector(id, EV_VEC_velocity, velocity);
			if(velocity[2] < 0.0) 
			{
				entity_set_int(id, EV_INT_sequence, 3);
				entity_set_int(id, EV_INT_gaitsequence, 1);
				entity_set_float(id, EV_FL_frame, 1.0);
				entity_set_float(id, EV_FL_framerate, 1.0);

				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed;
				entity_set_vector(id, EV_VEC_velocity, velocity);
			}
		}
	}
	return PLUGIN_CONTINUE;
}

public client_PostThink(id)
{
	new jump_num = get_pcvar_num(cvar[multi_jump]);
	if(!jump_num)
		return PLUGIN_CONTINUE;
		
	if(is_user_alive(id) && !is_user_vip(id))
		return PLUGIN_CONTINUE;
	
	if(g_bJump[id])
	{
		new Float:fVelocity[3];
		entity_get_vector(id, EV_VEC_velocity, fVelocity);
		fVelocity[2] = random_float(265.0, 285.0);
		entity_set_vector(id, EV_VEC_velocity, fVelocity);
		
		g_bJump[id] = false;
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public event_DeathMsg()
{
	new killer = read_data(1), hs = read_data(3);	
	if(is_user_alive(killer) && is_user_vip(killer))
	{
		if(killer == read_data(2)) return PLUGIN_HANDLED;

		if(hs && !user_has_weapon(killer, CSW_HEGRENADE)) give_item(killer, "weapon_hegrenade");

		new cache = hs ? get_pcvar_num(cvar[hp_hs]) : get_pcvar_num(cvar[hp_kill]);
		if(cache != 0) set_user_health(killer, min(get_user_health(killer) + cache, get_pcvar_num(cvar[hp_max])));

		cache = hs ? get_pcvar_num(cvar[ap_hs]) : get_pcvar_num(cvar[ap_kill]);
		if(cache != 0) set_user_armor(killer, min(get_user_armor(killer) + cache, get_pcvar_num(cvar[hp_max])));

		cache = hs ? get_pcvar_num(cvar[money_hs]) : get_pcvar_num(cvar[money_kill]);
		if(cache != 0) cs_set_user_money(killer, min(cs_get_user_money(killer) + cache, 16000));
	}

	return PLUGIN_CONTINUE;
}

public event_Damage(victim)
{
	if(!get_pcvar_num(cvar[show_bullet_dmg]))
		return PLUGIN_CONTINUE;
		
	new id = get_user_attacker(victim);
	if(is_user_valid(id))
	{
		if(is_user_alive(id) && !is_user_vip(id))
			return PLUGIN_HANDLED;
		
		if(read_data(4) || read_data(5) || read_data(6))
		{		
			new iPos = ++g_iPlayerPos[id];
			if(iPos == sizeof(g_flCoords))
				iPos = g_iPlayerPos[id] = 0;
			
			new iCol = ++g_iPlayerCol[id];
			if(iCol == sizeof(g_iColors))
				iCol = g_iPlayerCol[id] = 0;
			
			set_hudmessage(g_iColors[iCol][0], g_iColors[iCol][1], g_iColors[iCol][2], Float:g_flCoords[iPos][0], Float:g_flCoords[iPos][1], 0, 0.1, 2.5, 0.02, 0.02, -1);
			show_hudmessage(id, "%d", read_data(2));
		}
	}
	
	return PLUGIN_CONTINUE;
}

public event_NewRound()
{
	rounds++;
}

public event_textmsg()
{
	rounds = 0;
}

public fw_PlayerSpawnPost(id)
{
	if(is_user_vip(id) && is_user_alive(id))
	{
		set_task(0.25, "give_items", id + 212);
		set_task(2.0, "apply_vip_model", id);
		return HAM_IGNORED;
	}
	
	return HAM_IGNORED;
}

public give_items(taskid)
{
	new id = taskid - 212;
	if(!is_user_alive(id))
		return;

	new cache = get_pcvar_num(cvar[hp_spawn])
	if(cache != 0) set_user_health(id, cache);

	cache = get_pcvar_num(cvar[ap_spawn]);
	if(cache != 0) cs_set_user_armor(id, cache, CS_ARMOR_VESTHELM);

	cache = get_pcvar_num(cvar[money_spawn]);
	if(cache != 0) cs_set_user_money(id, min(cs_get_user_money(id) + cache, 16000));

	if(rounds >= 3) ShowVipMenu(id);
}

public fw_TouchWeapon(ent, id)
{
	if(is_user_alive(id) && !is_user_vip(id))
	{
		static model[128];
		pev(ent, pev_model, model, charsmax(model));

		if(equal(model, "models/w_awp.mdl"))
			return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public msg_ScoreAttrib(msgid, dest, id)
{
	if(!get_pcvar_num(cvar[show_vip_tab]))
		return PLUGIN_CONTINUE;
		
	new id = get_msg_arg_int(1);
	if(is_user_connected(id) && is_user_vip(id))
		set_msg_arg_int(2, ARG_BYTE, is_user_alive(id) ? (1<<2) : (1<<0));
	
	return PLUGIN_CONTINUE;
}

public msg_ScreenFade(msgid, dest, id)
{
	if(!get_pcvar_num(cvar[noflash]))
		return PLUGIN_HANDLED;

	if(is_user_connected(id) && is_user_vip(id))
	{
		static data[4];
		data[0] = get_msg_arg_int(4);
		data[1] = get_msg_arg_int(5);
		data[2] = get_msg_arg_int(6);
		data[3] = get_msg_arg_int(7);
		
		if(data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] > 199)
			return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public apply_vip_model(taskid)
{
    new id = taskid;
    if (!is_user_alive(id)) return;

    // Verificăm echipa și aplicăm modelul corespunzător
    if (cs_get_user_team(id) == CS_TEAM_T)
    {
        cs_set_user_model(id, VIP_MODEL_T);
    }
    else if (cs_get_user_team(id) == CS_TEAM_CT)
    {
        cs_set_user_model(id, VIP_MODEL_CT);
    }
}

public ShowVipMenu(id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(!is_user_vip(id))
	{
		ColorChat(id, "!4%s!1 Imi pare rau, dar nu ai acces la meniul pentru!3 membrii VIP!1.", TAG);
		ColorChat(id, "!4%s!1 Poti cumpara VIP, contactand pe mosu discord:mosu3828 !3 %s!1.", TAG, CONTACT);
		return PLUGIN_HANDLED;
	}

	give_item(id, "weapon_hegrenade");
	give_item(id, "weapon_flashbang");
	give_item(id, "weapon_flashbang");
	drop_weapons(id, 2);
	give_item(id, "weapon_deagle");
	cs_set_user_bpammo(id, CSW_DEAGLE, 35);

	new menu = menu_create("\rMeniu VIP", "VipMenuHandler");
	menu_additem(menu, "M4A1 + Echipament", "1");
	menu_additem(menu, "AK-47 + Echipament", "2");
	menu_additem(menu, "AWP + Echipament", "3");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	
	return PLUGIN_CONTINUE;
}

public VipMenuHandler(id, menu, item)
{
	if(!is_user_connected(id) || item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new data[6], namei[64], access, CallBack;
	menu_item_getinfo(menu, item, access, data, charsmax(data), namei, charsmax(namei), CallBack);
	new key = str_to_num(data);

	switch(key)
	{
		case 1:
		{
			drop_weapons(id, 1);
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 120);
			
			ColorChat(id, "!4%s!1 Ai ales!3 M4A1!1 +!3 Deagle!1 +!3 Set grenade!1 (!31 HE!1 + !32 FB!1).", TAG);
		}

		case 2:
		{
			drop_weapons(id, 1);
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 120);
			
			ColorChat(id, "!4%s!1 Ai ales!3 AK47!1 +!3 Deagle!1 +!3 Set grenade!1 (!31 HE!1 + !32 FB!1).", TAG);
		}

		case 3:
		{
			drop_weapons(id, 1);
			give_item(id, "weapon_awp");
			cs_set_user_bpammo(id, CSW_AWP, 30);
			
			ColorChat(id, "!4%s!1 Ai ales!3 AWP!1 +!3 Deagle!1 +!3 Set grenade!1 (!31 HE!1 + !32 FB!1).", TAG);
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90);
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE);

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
    // Get user weapons
    static weapons[32], num, i, weaponid, wname[32];
    num = 0; // reset passed weapons count (bugfix)
    get_user_weapons(id, weapons, num);

    // Loop through them and drop primaries or secondaries
    for (i = 0; i < num; i++)
    {
        // Get weapon ID from array
        weaponid = weapons[i];  // Corrected assignment
        
        // Check if weapon is primary or secondary
        if ((dropwhat == 1 && ((1 << weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || 
            (dropwhat == 2 && ((1 << weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
        {
            // Get weapon name
            get_weaponname(weaponid, wname, charsmax(wname));
            
            // Drop the weapon
            engclient_cmd(id, "drop", wname);
        }
    }
}


stock ColorChat(id, String[], any:...) 
{
	static szMesage[192];
	vformat(szMesage, charsmax(szMesage), String, 3);
	
	replace_all(szMesage, charsmax(szMesage), "!1", "^1");
	replace_all(szMesage, charsmax(szMesage), "!3", "^3");
	replace_all(szMesage, charsmax(szMesage), "!4", "^4");
	
	static g_msg_SayText = 0;
	if(!g_msg_SayText)
		g_msg_SayText = get_user_msgid("SayText");
	
	new Players[32], iNum = 1, i;

 	if(id) Players[0] = id;
	else get_players(Players, iNum, "ch");
	
	for(--iNum; iNum >= 0; iNum--) 
	{
		i = Players[iNum];
		
		message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
		write_byte(i);
		write_string(szMesage);
		message_end();
	}
}