#include <amxmodx>
#include <cstrike>
#include <engine>

/*
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <amxmisc>
#include <fun>
*/

// Configs 

#define MARK_DURATION 0.5 
#define MARK_REFRESH 0.2 

#define MARK_SPRITE "sprites/mark_1.spr"
#define MARK_SOUND "here_10.wav"

// Plugin 

#define MAX_PLAYERS 32
new g_sprite;
new bool:g_sprite_active[MAX_PLAYERS + 1]; 
new Float:g_sprite_delay[MAX_PLAYERS + 1]; 
new aim_pos[MAX_PLAYERS + 1][3];

public plugin_init() {
    register_plugin("Mark Here", "1.1", "Daniel");

    register_clcmd("radio1", "cmd_mark");
    register_clcmd("radio2", "cmd_mark");
    register_clcmd("radio3", "cmd_mark");
}

public plugin_precache() {

    g_sprite = precache_model(MARK_SPRITE);
    precache_sound(MARK_SOUND);
}

public cmd_mark(id) {
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    if (!g_sprite_active[id]) {
        g_sprite_active[id] = true;

		get_user_origin( id, aim_pos[id], 3 );
		
        emit_sound(id, CHAN_VOICE, MARK_SOUND, 1.0, ATTN_NORM, 0, PITCH_NORM);

        g_sprite_delay[id] = MARK_DURATION; 
		
        set_task(MARK_REFRESH, "CreateMark", id );
        set_task(g_sprite_delay[id], "DeleteMark", id);
    }
    return PLUGIN_HANDLED;
}

public CreateMark(id) {
    if (is_user_alive(id) && g_sprite_active[id]) {
        
		message_begin( MSG_BROADCAST,SVC_TEMPENTITY ) 
		write_byte( TE_SPRITE ) 
		write_coord( aim_pos[id][0] )		// position)
		write_coord( aim_pos[id][1] ) 
		write_coord( aim_pos[id][2] ) 
		write_short( g_sprite )			// sprite index
		write_byte( 5)				// scale in 0.1's
		write_byte( 255 )				// brightness
		message_end() 
					
        set_task(MARK_REFRESH, "CreateMark", id);
    }
}

public DeleteMark(id) {
    g_sprite_active[id] = false;
}

