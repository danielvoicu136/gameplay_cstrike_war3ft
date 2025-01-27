#include <amxmodx>
#include <csx>
#include <dhudmessage>
 
#define PLUGIN "Bomb Countdown DHUD"
#define VERSION "0.2"
#define AUTHOR "Daniel / SAMURAI" 
 
new g_c4timer, g_textmsg, pointnum;
new bool:b_planted = false;

 
public plugin_init()
{
	register_plugin(PLUGIN,VERSION,AUTHOR);
 
	pointnum = get_cvar_pointer("mp_c4timer");
	
	g_textmsg = get_user_msgid("TextMsg");
 
	register_logevent("newRound", 2, "1=Round_Start");
	register_logevent("endRound", 2, "1=Round_End");
	register_logevent("endRound", 2, "1&Restart_Round_");
	
	register_message(g_textmsg, "message_bomb");
	
		
 
}
 
public newRound()
{
	g_c4timer = -1;
	remove_task(652450);
	b_planted = false;
}
 
public endRound()
{
	g_c4timer = -1;
	remove_task(652450);
}
 
public bomb_planted()
{
	client_cmd(0, "spk misc/bomba_2.wav")
	set_dhudmessage(255, 186, 3, -1.0, 0.16, 0, 6.0, 6.0)
	show_dhudmessage(0, "Bomb Planted !^n Go go go...")
	
	b_planted = true;
	g_c4timer = get_pcvar_num(pointnum);
	dispTime()
	set_task(1.0, "dispTime", 652450, "", 0, "b");
}
 
public bomb_defused()
{
	
	client_cmd(0, "spk misc/defusebmb.wav")
	set_dhudmessage(24, 109, 238, -1.0, 0.16, 0, 6.0, 6.0)
	show_dhudmessage(0, "Bomb Defused !^n Bravo...")
	
	if(b_planted)
	{
		remove_task(652450);
		b_planted = false;
	}
    
}
 
public bomb_explode()
{
	client_cmd(0, "spk misc/explodebmb.wav")
	set_dhudmessage(219, 71, 51, -1.0, 0.16, 0, 6.0, 6.0)
	show_dhudmessage(0, "Bomb Exploded !^n Ha ha ha...")
	
	if(b_planted)
	{
		remove_task(652450);
		b_planted = false;
	}
	
}
 
public dispTime()
{   
	if(!b_planted)
	{
		remove_task(652450);
		return;
	}
        
 
	if(g_c4timer >= 0)
	{
		if(g_c4timer > 13) set_dhudmessage(0, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
		else if(g_c4timer > 7) set_dhudmessage(150, 150, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
		else set_dhudmessage(150, 0, 0, -1.0, 0.80, 0, 1.0, 1.0, 0.01, 0.01, -1);
 
		show_dhudmessage(0, "-------^n| C4: %d |^n-------", g_c4timer);
	
		--g_c4timer;
	}
  
} 

public message_bomb(msg_id, msg_dest, id)
{
	static msg[64]
	get_msg_arg_string(2, msg, sizeof msg - 1)
	
	if (equal(msg, "#Game_bomb_drop"))
	{
		set_dhudmessage(219, 71, 51, -1.0, 0.16, 0, 6.0, 6.0)
		show_dhudmessage(0, "Bomb Dropped ! Ups ups...")
		return PLUGIN_HANDLED
	}
	
	if ( equal(msg, "#Game_bomb_pickup") || equal(msg, "#Got_bomb") )
	{
		set_dhudmessage(24, 109, 238, -1.0, 0.32, 0, 6.0, 6.0)
		show_dhudmessage(0, "Bomb Picked Up ! Carefull...")
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public plugin_precache() 
{
	precache_sound("misc/bomba_2.wav")
	precache_sound("misc/explodebmb.wav")
	precache_sound("misc/defusebmb.wav")
}
