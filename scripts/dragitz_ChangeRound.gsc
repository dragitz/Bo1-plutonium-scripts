#include maps\_utility;
#include maps\_zombiemode_utility;
#include common_scripts\utility;

/*

Scroll down, and edit: level.round_number

*/

init(){

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		player thread onConnect();
	}
}

onConnect()
{
	// Wait till the player has spawned
	self waittill( "spawned_player" );
	

	level.round_number = 199; 
	
	
	for(;;)
	{
		if(level.round_number < 2)
			break;
			
		zb = getAiSpeciesArray("axis", "all");
		if(zb.size > 0)
		{
			level.zombie_total = 0;
			
			for (m = 0; m < zb.size; m++)
				zb[m] doDamage(zb[m].health + 100, zb[m].origin);
				
			break;
		}
		wait .1;
	}
}