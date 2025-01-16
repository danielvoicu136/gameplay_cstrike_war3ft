// ****************************************
// Night Stalkers's Dark Ascension
// ****************************************

#define NS_ASCENSION_DURATION  5

public NS_Ult_DarkAscension( id )
{
	if ( !p_data_b[id][PB_ISCONNECTED] )
	{
		return;
	}

	ULT_ResetCooldown( id, get_pcvar_num( CVAR_wc3_ult_cooldown ) + NS_ASCENSION_DURATION, false );

	ULT_Icon( id, ICON_FLASH );
	
	Create_BarTime( id, NS_ASCENSION_DURATION, 0 );
	
	set_user_noclip(id, 1);
		
	emit_sound( id, CHAN_STATIC, g_szSounds[SOUND_VOODOO], 1.0, ATTN_NORM, 0, PITCH_NORM );

	new vOrigin[3];
	get_user_origin( id, vOrigin );
	vOrigin[2] += 75;

	Create_TE_ELIGHT( id, vOrigin, 100, 255, 245, 200, NS_ASCENSION_DURATION, 0 );
	
	set_task( float( NS_ASCENSION_DURATION ), "NS_Ult_Remove", TASK_RESETCLIP + id );

	return;
}

public NS_Ult_Remove( id )
{
	if ( id >= TASK_RESETCLIP )
	{
		id -= TASK_RESETCLIP;
	}

	if ( !p_data_b[id][PB_ISCONNECTED] )
	{
		return;
	}

	set_user_noclip(id, 0);

	ULT_Icon( id, ICON_HIDE );
	
	positionChangeTimer(id);
	
	return;
}

public positionChangeTimer(id)
{
	if ( !is_user_alive(id) ) return

	get_user_origin(id, g_lastPosition[id])

	new Float:velocity[3]
	Entvars_Get_Vector(id, EV_VEC_velocity, velocity)

	if ( velocity[0]==0.0 && velocity[1]==0.0 ) {
		velocity[0] += 20.0
		velocity[2] += 100.0
		Entvars_Set_Vector(id, EV_VEC_velocity, velocity)
	}

	set_task(0.4, "positionChangeCheck", id)
}

public positionChangeCheck(id)
{
	if ( !is_user_alive(id) ) return

	new origin[3]
	get_user_origin(id, origin)

	if ( g_lastPosition[id][0] == origin[0] && g_lastPosition[id][1] == origin[1] && g_lastPosition[id][2] == origin[2] && is_user_alive(id) ) {
		user_kill(id)
		client_print(id, print_chat, "* You died from being stuck when leaving Dark Ascension")
	}
}