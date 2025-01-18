stock get_user_maxhealth( id )
{

	new maxHealth = 100

	static iSkillLevel;
	iSkillLevel = SM_GetSkillLevel( id, SKILL_DEVOTION );

	// Human Devotion Skill
	if ( iSkillLevel > 0 )
	{
		maxHealth += iSkillLevel * p_devotion;
	}


	// Player has a health bonus from the Periapt of Health

	if ( ITEM_Has( id, ITEM_HEALTH ) > ITEM_NONE )
		maxHealth += get_pcvar_num( CVAR_wc3_health );

	return maxHealth
}

// Function checks to see if the weapon is a pistol
stock SHARED_IsSecondaryWeapon( iWeaponID )
{
	// Check for Counter-Strike or Condition Zero
	if ( g_MOD == GAME_CSTRIKE || g_MOD == GAME_CZERO )
	{
		if ( iWeaponID == CSW_ELITE || iWeaponID == CSW_FIVESEVEN || iWeaponID == CSW_USP || iWeaponID == CSW_GLOCK18 || iWeaponID == CSW_DEAGLE || iWeaponID == CSW_P90 )
		{
			return true;
		}
	}
	
	// Check for Day of Defeat
	else if ( g_MOD == GAME_DOD )
	{

	}


	return false;
}

// Compare player speed with the limit 
stock bool:IsCurrentSpeedHigherThan(id, Float:fValue) 
{ 

    new Float:fVecVelocity[3];
    entity_get_vector(id, EV_VEC_velocity, fVecVelocity);
    
    if (vector_length(fVecVelocity) > fValue) 
        return true;
     
    return false;
}

// Convert option 10 into 0 for change race menu 
stock getKeyString(num, output[], size)
{
    if (num == 10)
    {
        formatex(output, size, "0"); 
    }
    else
    {
        formatex(output, size, "%d", num); 
    }
}

// Create Fog 

/*

public EventRoundStart( ) 
{ 
    set_lights("off")
    CreateFog( 0, .clear = false )
}  
public t_win()
{
    CreateFog( 0, 0, 0, 0, 0.003 );
    set_lights("b") 
	
*/

stock CreateFog ( const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false )
{
    static msgFog;
    
    if ( msgFog || ( msgFog = get_user_msgid( "Fog" ) ) )
    {
        new density = _:floatclamp( density_f, 0.0001, 0.25 ) * _:!clear;
        
        message_begin( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, msgFog, .player = index );
        write_byte( clamp( red  , 0, 255 ) );
        write_byte( clamp( green, 0, 255 ) );
        write_byte( clamp( blue , 0, 255 ) );
        write_long( _:density );
        message_end();
    }
} 

