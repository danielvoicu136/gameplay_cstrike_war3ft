#define NS_CONCOCTION_DAMAGE	  15		// Damage done by Fear 
#define NS_CONCOCTION_RADIUS	  300		// Radius of Fear 	
#define NS_ASCENSION_DURATION  3			// Fly time 


// ****************************************
// Night Stalker's Dark Ascension Ultimate 
// ****************************************

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
	
	static iSkillLevel;
	iSkillLevel = SM_GetSkillLevel( id, SKILL_HUNTER );
	if ( iSkillLevel > 0 )
	{
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
	}

}

// ****************************************
// Night Stalker's on Kill  
// ****************************************
NS_SkillsBounty(iAttacker, iVictim)
{
    if (!p_data_b[iVictim][PB_ISCONNECTED] || !p_data_b[iAttacker][PB_ISCONNECTED])
    {
        return;
    }

    if (!is_user_alive(iAttacker))
    {
        return;
    }

    static iSkillLevel;
    iSkillLevel = SM_GetSkillLevel(iAttacker, PASS_HEARTH);
    if (iSkillLevel > 0)
    {
        new iHP = p_hearth[p_data[iAttacker][P_LEVEL]]; 
        new iMaxHealth = get_user_maxhealth(iAttacker);
        new iCurrentHealth = get_user_health(iAttacker);

        new CsArmorType:ArmorType;
        new iCurArmor = cs_get_user_armor(iAttacker, ArmorType);
        new iMaxArmor = SHARED_GetMaxArmor(iAttacker);

        if (iCurrentHealth >= iMaxHealth)
        {
            cs_set_user_armor(iAttacker, min(iCurArmor + iHP, iMaxArmor), ArmorType);
        }
        else
        {
            
            new iHealthNeeded = iMaxHealth - iCurrentHealth;

			set_user_health(iAttacker, min(iCurrentHealth + iHP, iMaxHealth));
			
			if (iHealthNeeded < iHP) { 
				new iExcess = iHP - iHealthNeeded; 
				cs_set_user_armor(iAttacker, min(iCurArmor + iExcess, iMaxArmor), ArmorType);
			}
			
        }
    }
}


// ****************************************
// Night Stalker's Chance to convert armor into health
// ****************************************
NS_SkillsDefensive(iAttacker, iVictim)
{
    if (!p_data_b[iVictim][PB_ISCONNECTED] || !p_data_b[iAttacker][PB_ISCONNECTED])
    {
        return;
    }

    if (!is_user_alive(iVictim))
    {
        return;
    }

    static iSkillLevel;

    iSkillLevel = SM_GetSkillLevel(iVictim, SKILL_VOID);
    if (iSkillLevel > 0)
    {
        if (random_float(0.0, 1.0) <= p_void[iSkillLevel - 1])
        {
			new Float:g_ArmorToHealthMultiplier = 1.0; 
			
            new iMaxHealth = get_user_maxhealth(iVictim);
            new iCurrentHealth = get_user_health(iVictim);

            new CsArmorType:ArmorType;
            new iCurArmor = cs_get_user_armor(iVictim, ArmorType);

            if (iCurrentHealth < iMaxHealth && iCurArmor > 0)
            {
                
                new iHealthDeficit = iMaxHealth - iCurrentHealth;
				
				new iArmorToConvert = floatround(iHealthDeficit / g_ArmorToHealthMultiplier);   
			
				if(iCurArmor >= iArmorToConvert) 
				{ 	
					set_user_health(iVictim, min(iCurrentHealth + iHealthDeficit, iMaxHealth));
					cs_set_user_armor(iVictim, iCurArmor - iArmorToConvert, ArmorType);
				} 
				else {
					new iAvailableArmor = iArmorToConvert - iCurArmor;
					new iArmorToHealth = floatround(iAvailableArmor * g_ArmorToHealthMultiplier);
					set_user_health(iVictim, min(iCurrentHealth + iArmorToHealth, iMaxHealth));
					cs_set_user_armor(iVictim, 0, ArmorType);
				}
            }
        }
    }
}


// ****************************************
// Night Stalker's Cleave Damage
// ****************************************
NS_SkillsOffensive( iAttacker, iVictim)
{
	static iSkillLevel;

	iSkillLevel = SM_GetSkillLevel( iAttacker, SKILL_FEAR );
	if ( iSkillLevel > 0 )
	{
		// Check to see if we should "fear"
		if ( random_float( 0.0, 1.0 ) <= p_fear[iSkillLevel-1] )
		{
			new vOrigin[3], vInitOrigin[3], vAxisOrigin[3], i;
			
			// Get origin of victim
			get_user_origin( iVictim, vOrigin );
			
			// Play sound on attacker
			emit_sound( iAttacker, CHAN_STATIC, g_szSounds[SOUND_CONCOCTION_CAST], 1.0, ATTN_NORM, 0, PITCH_NORM );
			
			// Set up the origins for the effect
			vInitOrigin[0] = vOrigin[0];
			vInitOrigin[1] = vOrigin[1];
			vInitOrigin[2] = vOrigin[2] - 16;

			vAxisOrigin[0] = vOrigin[0];
			vAxisOrigin[1] = vOrigin[1];
			vAxisOrigin[2] = vOrigin[2] + SH_CONCOCTION_RADIUS;
			
			// Display the effect on the attacker
			for ( i = 0; i < 200; i += 25 )
			{
				// Create_TE_BEAMCYLINDER( vOrigin, vInitOrigin, vAxisOrigin, g_iSprites[SPR_SHOCKWAVE], 0, 0, 9, 20, 0, 188, 220, 255, 255, 0 );

				vInitOrigin[2] += 25;
			}

			new team = get_user_team( iVictim );
			new players[32], numberofplayers, vTargetOrigin[3];
			get_players(players, numberofplayers, "a");

			
			// Loop through all players and see if anyone nearby needs to be damaged
			for( i = 0; i < numberofplayers; i++ )
			{
				
				// Then we have a target on the other team!!
				if ( get_user_team( players[i] ) == team )
				{
					get_user_origin( players[i], vTargetOrigin );

					// Make sure they are close enough
					if ( get_distance( vOrigin, vTargetOrigin ) <= NS_CONCOCTION_RADIUS )
					{
						// Damage
						WC3_Damage( players[i], iAttacker, NS_CONCOCTION_DAMAGE, CSW_CONCOCTION, 0 );
						
						Create_TE_SPRITE( vTargetOrigin, g_iSprites[SPR_FIRE], 3, 200 );
					
						// Let the victim know he hit someone
						emit_sound( iAttacker, CHAN_STATIC, g_szSounds[SOUND_CONCOCTION_HIT], 1.0, ATTN_NORM, 0, PITCH_NORM );
					}
				}
			}
		}

		else if ( get_pcvar_num( CVAR_wc3_psychostats ) )
		{
			new WEAPON = CSW_CONCOCTION - CSW_WAR3_MIN;

			iStatsShots[iVictim][WEAPON]++;
		}
	}
}

// ****************************************
// Night Stalker's Hunter 
// ****************************************
public NS_SkillHunter(id) { 

    if (!p_data_b[id][PB_ISCONNECTED])
    {
        return;
    }

    if (!is_user_alive(id))
    {
        return;
    }
	
	static iSkillLevel;

	iSkillLevel = SM_GetSkillLevel( id, SKILL_HUNTER );
	if ( iSkillLevel > 0 )
	{
		give_item(id, "weapon_flashbang");
		give_item(id, "weapon_flashbang");
	}

} 



stock UTIL_KnockBack( iEnt, id, Float:flKnockBack, Float:flRadius )
{
	new Float:flEntOrigin[ 3 ];
	pev( iEnt, pev_origin, flEntOrigin );

	UTIL_BreakModel( flEntOrigin, gExplodeModel, BREAK_TRANS );

	UTIL_Cylinder( flEntOrigin, 100 );
	UTIL_Cylinder( flEntOrigin, 200 );
	UTIL_Cylinder( flEntOrigin, floatround( flRadius ) );

	new iClient = FM_NULLENT, Float:flClientOrigin[ 3 ], Float:flDistance;

    	while( ( iClient = engfunc( EngFunc_FindEntityInSphere, iClient, flEntOrigin, flRadius ) ) )
    	{
		if( IsPlayer( iClient ) 
		&& is_user_alive( iClient ) 
		&& get_user_team( id ) != get_user_team( iClient ) )
		{
			pev( iClient, pev_origin, flClientOrigin );
       			flDistance = get_distance_f( flEntOrigin, flClientOrigin );

			if( flDistance <= flRadius )
			{
				new Float:flVelocity[ 3 ];
 
				xs_vec_sub( flClientOrigin, flEntOrigin, flClientOrigin );
				xs_vec_normalize( flClientOrigin, flClientOrigin );
				pev( iClient, pev_velocity, flVelocity );
 
    				xs_vec_mul_scalar( flClientOrigin, floatmul( flKnockBack, 800.0 ), flClientOrigin );
    				xs_vec_add( flVelocity, flClientOrigin, flVelocity );

    				set_pev( iClient, pev_velocity, flVelocity );
			}
		}
	}
}			

stock UTIL_Cylinder( Float:flOrigin[ 3 ], flRadius )
{
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin );
	write_byte( TE_BEAMCYLINDER );
	write_coord_f( flOrigin[ 0 ] ); 
	write_coord_f( flOrigin[ 1 ] ); 
	write_coord_f( flOrigin[ 2 ] ); 
	write_coord_f( flOrigin[ 0 ] ); 
	write_coord_f( flOrigin[ 1 ] ); 
	write_coord_f( flOrigin[ 2 ] + flRadius ); 
	write_short( gSpriteShockwave ); 
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 4 );
	write_byte( 40 );
	write_byte( 0 );
	write_byte( 150 ); 
	write_byte( 1 ); 
	write_byte( 210 );
	write_byte( 200 );
	write_byte( 0 );
	message_end( );
}

stock UTIL_BreakModel( Float:flOrigin[ 3 ], model, flags )
{
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0 );
	write_byte( TE_BREAKMODEL );
	write_coord_f( flOrigin[ 0 ] );
	write_coord_f( flOrigin[ 1 ] );
	write_coord_f( flOrigin[ 2 ] );
	write_coord( 16 );
	write_coord( 16 );
	write_coord( 16 );
	write_coord( random_num( -20, 20 ) );
	write_coord( random_num( -20, 20 ) );
	write_coord( 10 );
	write_byte( 10 );
	write_short( model );
	write_byte( 10 );
	write_byte( 9 );
	write_byte( flags );
	message_end( );
}

