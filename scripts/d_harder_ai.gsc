#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_net;
#include maps\_zombiemode_audio;
#using_animtree( "generic_human" ); 

main()
{
	if ( GetDvar( #"zombiemode" ) != "1" )
		return;
	
	// PAP SYSTEM
    replaceFunc( maps\_zombiemode_spawner::zombie_follow_enemy, ::zombie_follow_enemy );
    replaceFunc( maps\_zombiemode_spawner::should_attack_player_thru_boards, ::should_attack_player_thru_boards );

}



zombie_follow_enemy()
{
	self endon( "death" );
	self endon( "zombie_acquire_enemy" );
	self endon( "bad_path" );
	
	level endon( "intermission" );

	DISTANCE = self.meleeAttackDist + 15; // 64 + x (was 15 not 20)
	
    min_reaction_time = 300;
    max_reaction_time = 600;     // Going over 600 may lead to them not being able to reach you
    max_round         = 30;      // Reaction time reaches max_reaction_time at this specified round
	while( 1 )
	{		
		// Default goal
		vector_goal = self.favoriteenemy.origin;
		
		// As the zombie gets shoot more and more, it will get tired
		fitness_reduction = (1 - self.health / self.maxhealth) * 0.13;
		self.moveplaybackrate = 1.14 - fitness_reduction;
		
		// If the distance is higher than x amount, use prediction
		if(distance(self.favoriteenemy.origin, self.origin) > DISTANCE)
		{
			current_position = self.favoriteenemy.origin;
			velocity		 = self.favoriteenemy GetVelocity();
			velocity = (velocity[0], velocity[1], 0);
			
			// Predict next X milliseconds, increases each round
            reaction_time = min_reaction_time + (max_reaction_time - min_reaction_time) * ((level.round_number - 1) / (max_round - 1));
			vector_goal = current_position + velocity * (reaction_time / 1000);

			//vector_goal = self.favoriteenemy.predicted_position;
			
			// Ensure to stop when hitting a wall
			trace = BulletTrace(self.favoriteenemy.origin, vector_goal, false, undefined);
			vector_goal = trace["position"];

			// The first check ensures that the zombie will target the player when close
			// the second one is fixes the zombies standing still caused by the vector_goal being in a bad_path
			if(distance(vector_goal, self.origin) < DISTANCE || distance(vector_goal, self.favoriteenemy.origin) < self.meleeAttackDist )
			{
				vector_goal = self.favoriteenemy.origin;
                self.favoriteenemy IPrintLn("original");
			}
			
		}

		if( isDefined( self.enemyoverride ) && isDefined( self.enemyoverride[1] ) )
		{
			if( distanceSquared( self.origin, self.enemyoverride[0] ) > 1*1 )
			{
				self OrientMode( "face motion" );
			}
			else
			{
				self OrientMode( "face point", self.enemyoverride[1].origin );
			}
			self.ignoreall = true;
			self SetGoalPos( self.enemyoverride[0] );
		}
		else if( IsDefined( self.favoriteenemy ) )
		{
			self.ignoreall = false;
			
			//nodes = GetNodeArray("random_toggle_node", "script_noteworthy");
			//node = get_closest_node( vector_goal, nodes );
			//vector_goal = node.origin;

			self SetGoalPos( vector_goal );
			self OrientMode( "face default", vector_goal);

			if(self.zombie_bad_path)
			{
				self SetGoalPos( self.favoriteenemy.origin );
				self OrientMode( "face default", self.favoriteenemy.origin );
			}
			
		}

		// LDS - changed this from a level specific catch function to a general one that can be overloaded based
		//       on the conditions in a level that can render a player inaccessible to zombies.
		if( isDefined( level.inaccesible_player_func ) )
		{
			self [[ level.inaccessible_player_func ]]();
		}
		
		wait( 0.1 );
	}
}


should_attack_player_thru_boards()
{

	//no board attacks if they are crawlers
	if( !self.has_legs)
	{
		return false;
	}
	
	//DCS 083110: check glass section or walls are all broken through.
	if(IsDefined(self.first_node.barrier_chunks))
	{
		for(i=0;i<self.first_node.barrier_chunks.size;i++)
		{
			if(IsDefined(self.first_node.barrier_chunks[i].unbroken) && self.first_node.barrier_chunks[i].unbroken == true )
			{
				return false;
			}	
		}	
	}	
	
	
	// dunno if it's used somewhere else, I'll keep it here
	if(GetDvar( #"zombie_reachin_freq") == "")
	{
		setdvar("zombie_reachin_freq","50");
	}
	

	// hijack freq, the higher the more aggressive the zombies are
	freq = 100;
	freq_range = 200;

	players = get_players();
	attack = false;

	self.player_targets = [];
	for(i=0;i<players.size;i++)
	{
		if ( isAlive( players[i] ) && !isDefined( players[i].revivetrigger ) && distance2d( self.origin, players[i].origin ) <= freq_range ) // <= 90 makes the zombies feel more aggressive
		{
			self.player_targets[self.player_targets.size] = players[i];
			attack = true;
		}
	}
	if(attack && freq >= randomint(100) )
	{
		//iprintln("checking attack");
		// index 0 is center, index 2 is left and index 1 is the right
		//check to see if the guy is left, right, or center 
		self.old_origin = self.origin;
		if(self.attacking_spot_index == 0) //he's in the center
		{
			
		if(randomint(100) > 50)
		{
				//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", %body, 1, 0.4 );
				self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
				self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", undefined, 1, 0.3 );
		}
		else
		{
			//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", %body, 1, 0.4 );
			self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
			self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", undefined, 1, 0.3 );
		}
		self maps\_zombiemode_spawner::window_notetracks( "window_melee" );
		}
		else if(self.attacking_spot_index == 2) //<-- he's to the left
		{
			//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", %body, 1, 0.4 );
			self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
			self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", undefined, 1, 0.3 );
			self maps\_zombiemode_spawner::window_notetracks( "window_melee" );
		}
		else if(self.attacking_spot_index == 1) //<-- he's to the right
		{
			//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", %body, 1, 0.4 );
			self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
			self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", undefined, 1, 0.3 );
			self maps\_zombiemode_spawner::window_notetracks( "window_melee" );
		}					
	}
	else
	{
		return false;	
	}
}