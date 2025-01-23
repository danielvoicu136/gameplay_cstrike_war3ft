#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <fun>
#include <engine>


// Configs 

new const Float:REVIVE_DISTANCE = 100.0;
new const Float:EXPLOSION_DAMAGE = 50.0;
new const Float:EXPLOSION_RADIUS = 200.0;

new const Float:REVIVE_DELAY_MIN = 5.0;
new const Float:REVIVE_DELAY_MAX = 10.0;

#define BOX_MODEL_TE "models/te_soul.mdl" 
#define BOX_MODEL_CT "models/ct_soul.mdl"

#define BOX_TRANSLATE_OFFSET_Z 1.0 

#define TASK_THINK	0.05 


// Plugin 



#define MAX_BOXES 33

new stuck[MAX_BOXES];

// rotations 
new direction[MAX_BOXES]; 
new Float:direction_change_time[MAX_BOXES];
new Float:box_angles[MAX_BOXES];

new const Float:size[][3] = {
    {0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, 
    {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, 
    {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, 
    {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0}, {0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, 
    {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, 
    {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, 
    {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
    {0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, 
    {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, 
    {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, 
    {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0}, {0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, 
    {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, 
    {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, 
    {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
    {0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, 
    {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, 
    {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, 
    {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
};

new boxes[MAX_BOXES];
new Float:box_origin[MAX_BOXES][3];
new box_owner[MAX_BOXES];
new bool:box_is_used[MAX_BOXES];
new bool:box_is_trap[MAX_BOXES];
new box_trapper[MAX_BOXES];
new Float:temp_origin[MAX_BOXES][3]; 

public plugin_init()
{
    register_plugin("Revive Box", "1.1", "Daniel");
    register_event("HLTV", "NewRoundEvent", "a", "1=0", "2=0");
    RegisterHam(Ham_Spawn, "player", "hamSpawn", 1);
    RegisterHam(Ham_Killed, "player", "hamKilled", 1);
    RegisterHam(Ham_Player_PreThink, "player", "hamPlayerPreThink");
	
	set_task(10.0, "moveBoxes"); 
}

public plugin_precache() {
    precache_model(BOX_MODEL_TE);
    precache_model(BOX_MODEL_CT);

} 

public NewRoundEvent()
{
    for (new i = 0; i < MAX_BOXES; i++)
    {
        if (boxes[i])
        {
            remove_entity(boxes[i]);
            boxes[i] = 0;
            box_owner[i] = 0;
            box_is_used[i] = false;
            box_is_trap[i] = false;
        }
    }
}

public hamKilled(victim, attacker, shouldgib)
{
    if (!is_user_connected(victim))
        return;

    if (!is_valid_player(victim))
        return;

    new Float:origin[3];
    entity_get_vector(victim, EV_VEC_origin, origin);

    origin[2] -= BOX_TRANSLATE_OFFSET_Z;

    new box = create_entity("info_target");
    if (box == -1)
        return;

    if (cs_get_user_team(victim) == CS_TEAM_T)
    {
        entity_set_model(box, BOX_MODEL_TE);
        fm_set_rendering(box, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 100);
    }
    else if (cs_get_user_team(victim) == CS_TEAM_CT)
    {
        entity_set_model(box, BOX_MODEL_CT);
        fm_set_rendering(box, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 100);
    }

    entity_set_string(box, EV_SZ_classname, "revive_box");
    entity_set_origin(box, origin);

    for (new i = 0; i < MAX_BOXES; i++)
    {
        if (!boxes[i])
        {
            boxes[i] = box;
            box_owner[i] = victim;
            box_origin[i][0] = origin[0];
            box_origin[i][1] = origin[1];
            box_origin[i][2] = origin[2] + BOX_TRANSLATE_OFFSET_Z;
            box_is_used[i] = false;
            box_is_trap[i] = false;
            break;
        }
    }
}

public hamPlayerPreThink(id)
{
    if (!is_valid_player(id) || !is_user_alive(id))
        return;

    new Float:player_origin[3];
    entity_get_vector(id, EV_VEC_origin, player_origin);

    for (new i = 0; i < MAX_BOXES; i++)
    {
        if (boxes[i] && is_valid_player(box_owner[i]))
        {
            if (get_distance_f(player_origin, box_origin[i]) <= REVIVE_DISTANCE)
            {
                if (cs_get_user_team(id) != cs_get_user_team(box_owner[i]) && !box_is_trap[i])
                {
				
					new name[32];
					get_user_name(box_owner[i], name, charsmax(name));
						
                    client_print(id, print_center, "Press R to block the enemy respawn [ %s ]", name);

                    if (pev(id, pev_button) & IN_RELOAD || pev(id, pev_button) & IN_USE)
                    {
                        box_is_trap[i] = true;
                        box_trapper[i] = id;
						
                        client_print(id, print_chat, "[ %s ] Enemy respawn has been blocked !",name);
						client_print(id, print_center, "[ %s ] Enemy respawn has been blocked !",name);
                    }
                }
                else if (cs_get_user_team(id) == cs_get_user_team(box_owner[i]) && !box_is_used[i])
                {
                    new name[32];
                    get_user_name(box_owner[i], name, charsmax(name));
                    client_print(id, print_center, "Press R to respawn [ %s ]", name);

                    if (pev(id, pev_button) & IN_RELOAD || pev(id, pev_button) & IN_USE)
                    {
                        box_is_used[i] = true;
						
						if(box_is_trap[i]) { 
							explodeBox(i, id);
							new name2[32];
							get_user_name(box_trapper[i], name2, charsmax(name2));
							
							client_print(id, print_chat, "[ %s ] Explosion !", name2);
							client_print(id, print_center, "[ %s ] Explosion !", name2);
						}
						else 
						{ 
							new Float:reviveTime = get_random_revive_delay();
							
							set_task(reviveTime, "revivePlayer", i);
							
							fm_set_rendering(boxes[i], kRenderFxNone, 0, 0, 0, kRenderNormal, 0);
							
							client_print(id, print_chat, "[ %s ] will respawn in %.1f seconds !", name, reviveTime);
							client_print(id, print_center, "[ %s ] will respawn in %.1f seconds !", name, reviveTime);
							
							new name3[32];
							get_user_name(id, name3, charsmax(name3));
							
			client_print(box_owner[i], print_chat, "[ %s ] will respawn you in %.1f seconds be prepared !", name3, reviveTime);
			client_print(box_owner[i], print_chat, "[ %s ] will respawn you in %.1f seconds be prepared !", name3, reviveTime);
			client_print(box_owner[i], print_chat, "[ %s ] will respawn you in %.1f seconds be prepared !", name3, reviveTime);

						} 

                    }
                }
            }
        }
    }
}

public hamSpawn(id)
{
    for (new i = 0; i < MAX_BOXES; i++)
    {
        if (boxes[i] && box_owner[i] == id)
        {
            remove_entity(boxes[i]);
            boxes[i] = 0;
            box_owner[i] = 0;
            box_is_used[i] = false;
            box_is_trap[i] = false;
        }
    }
}

public revivePlayer(i)
{
    if (boxes[i] && is_valid_player(box_owner[i]) && is_user_connected(box_owner[i]) 
        && !is_user_alive(box_owner[i]) 
        && (cs_get_user_team(box_owner[i]) == CS_TEAM_T || cs_get_user_team(box_owner[i]) == CS_TEAM_CT))
    {
        remove_entity(boxes[i]);

        ExecuteHamB(Ham_CS_RoundRespawn, box_owner[i]);

        new player_id = box_owner[i];
        temp_origin[player_id][0] = box_origin[i][0];
        temp_origin[player_id][1] = box_origin[i][1];
        temp_origin[player_id][2] = box_origin[i][2];

        set_task(0.2, "movePlayerToBox", player_id);

        boxes[i] = 0;
        box_owner[i] = 0;
        box_is_used[i] = false;
        box_is_trap[i] = false;
    }
}

public movePlayerToBox(player_id)
{
    if (is_valid_player(player_id) && is_user_alive(player_id))
    {
        temp_origin[player_id][2] = temp_origin[player_id][2] + BOX_TRANSLATE_OFFSET_Z;
        set_user_origin(player_id, temp_origin[player_id]);
        checkstuck(player_id);

        temp_origin[player_id][0] = 0.0;
        temp_origin[player_id][1] = 0.0;
        temp_origin[player_id][2] = 0.0;
    }
}

public checkstuck(id) {
    static Float:origin[3];
    static Float:mins[3], hull;
    static Float:vec[3];
    static o;
    if (is_user_connected(id) && is_user_alive(id)) {
        pev(id, pev_origin, origin);
        hull = pev(id, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;
        if (!is_hull_vacant(origin, hull, id) && !get_user_noclip(id) && !(pev(id, pev_solid) & SOLID_NOT)) {
            ++stuck[id];
            pev(id, pev_mins, mins);
            vec[2] = origin[2];
            for (o = 0; o < sizeof(size); ++o) {
                vec[0] = origin[0] - mins[0] * size[o][0];
                vec[1] = origin[1] - mins[1] * size[o][1];
                vec[2] = origin[2] - mins[2] * size[o][2];
                if (is_hull_vacant(vec, hull, id)) {
                    engfunc(EngFunc_SetOrigin, id, vec);
                    set_pev(id, pev_velocity, {0.0, 0.0, 0.0});
                    o = sizeof(size);
                }
            }
        } else {
            stuck[id] = 0;
        }
    }
}

public explodeBox(i, id)
{
    if (boxes[i])
    {
       
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, box_origin[i], 0)
		write_byte(TE_IMPLOSION)
		engfunc(EngFunc_WriteCoord, box_origin[i][0])
		engfunc(EngFunc_WriteCoord, box_origin[i][1])
		engfunc(EngFunc_WriteCoord, box_origin[i][2])
		write_byte(200)
		write_byte(100)
		write_byte(5)  
		message_end()
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, box_origin[i], 0)
		write_byte(TE_PARTICLEBURST) // TE id
		engfunc(EngFunc_WriteCoord, box_origin[i][0]) // x
		engfunc(EngFunc_WriteCoord, box_origin[i][1]) // y
		engfunc(EngFunc_WriteCoord, box_origin[i][2]) // z
		write_short(50) // radius
		write_byte(72) // color
		write_byte(6) // duration (will be randomized a bit)
		message_end()
		
		client_cmd( id, "speak ambience/thunder_clap.wav" );

		new healthAfterDamage = floatround(get_user_health(id) - EXPLOSION_DAMAGE); 
		
		if(healthAfterDamage > 0) { 
			set_user_health(id, healthAfterDamage);
		}
		else { 
			set_user_health(id, 1);
		}

        new players[32], num;
        get_players(players, num, "a");

        for (new j = 0; j < num; j++)
        {
            new target = players[j];

            if (target != id && is_user_alive(target))
            {
                new Float:target_origin[3];
                entity_get_vector(target, EV_VEC_origin, target_origin);

                if (get_distance_f(target_origin, box_origin[i]) <= EXPLOSION_RADIUS)
                {
                    
					new healthAfterDamage = floatround(get_user_health(target) - EXPLOSION_DAMAGE); 
		
					if(healthAfterDamage > 0) { 
						set_user_health(target, healthAfterDamage);
					}
					else { 
						set_user_health(target, 1);
					}
					
					client_cmd( target, "speak ambience/thunder_clap.wav" );
                }
            }
        }

        remove_entity(boxes[i]);
        boxes[i] = 0;
        box_owner[i] = 0;
        box_is_used[i] = false;
        box_is_trap[i] = false;
    }
}

public moveBoxes()
{
    new Float:current_time = get_gametime(); // Obținem timpul curent

    for (new i = 0; i < MAX_BOXES; i++)
    {
        if (boxes[i] && !box_is_used[i]) // Verificăm dacă există cutia și dacă nu este folosită
        {
            // Schimbă direcția dacă e timpul
            if (current_time >= direction_change_time[i])
            {
                direction[i] = (direction[i] + 1) % 4; // Trecem la următoarea direcție (0 -> 1 -> 2 -> 3 -> 0)
                direction_change_time[i] = current_time + 5.0; // Schimbă direcția după 5 secunde
            }

            // Calculează noua poziție în funcție de direcție
            new Float:new_origin[3];
            new_origin[0] = box_origin[i][0];
            new_origin[1] = box_origin[i][1];
            new_origin[2] = box_origin[i][2];

            // Mișcare în funcție de direcție
            switch (direction[i])
            {
                case 0: // Mișcare circulară (orizontală)
                {
                    box_angles[i] += 5.0;
                    if (box_angles[i] >= 360.0)
                        box_angles[i] -= 360.0;

                    new_origin[0] += 50.0 * floatcos(box_angles[i], degrees);
                    new_origin[1] += 50.0 * floatsin(box_angles[i], degrees);
                }
                case 1: // Mișcare verticală (sus-jos)
                {
                    box_angles[i] += 5.0;
                    if (box_angles[i] >= 360.0)
                        box_angles[i] -= 360.0;

                    new_origin[2] += 30.0 * floatsin(box_angles[i], degrees); // Mișcare pe axa Z
                }
                case 2: // Diagonală 1 (X și Z)
                {
                    box_angles[i] += 5.0;
                    if (box_angles[i] >= 360.0)
                        box_angles[i] -= 360.0;

                    new_origin[0] += 35.0 * floatcos(box_angles[i], degrees);
                    new_origin[2] += 35.0 * floatsin(box_angles[i], degrees);
                }
                case 3: // Diagonală 2 (Y și Z)
                {
                    box_angles[i] += 5.0;
                    if (box_angles[i] >= 360.0)
                        box_angles[i] -= 360.0;

                    new_origin[1] += 35.0 * floatcos(box_angles[i], degrees);
                    new_origin[2] += 35.0 * floatsin(box_angles[i], degrees);
                }
            }

            // Aplică noua poziție
            entity_set_origin(boxes[i], new_origin);
        }
    }

    set_task(TASK_THINK, "moveBoxes");
}


stock bool:is_hull_vacant(const Float:origin[3], hull, id) {
    static tr;
    engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr);
    if (!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid)) {
        return true;
    }

    return false;
}

bool:is_valid_player(id) {
    return (id > 0 && id <= 32 && is_user_connected(id));
}

stock Float:get_random_revive_delay()
{
    return random_float(REVIVE_DELAY_MIN, REVIVE_DELAY_MAX);
}