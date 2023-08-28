#include maps\_utility;
#include maps\_zombiemode_utility;
#include common_scripts\utility;


init(){
	
	// Whoever joins needs to be properly setup
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


// onConnect() will handle the declaration of the required variables
onConnect()
{
	//self endon( "disconnect" );

	// Wait till the player has spawned
	self waittill( "spawned_player" );
	wait 3;
	
	/// TEST STRUCTURE, REMOVE THIS AFTER TESTING
	//if(!isDefined(level.PlayerInventories))
	//{
	//	
	//	
	//	struct = SpawnStruct();
	//	
	//	array = [];
	//	array[0] = "aug_acog_zm";
	//	array[1] = "galil_zm";
	//	array[2] = "commando_zm";
	//	
	//	struct.score = 9000; //self.score;
	//	struct.weapons = array;
	//	
	//	array[0] = "specialty_fastreload";
	//	array[1] = "specialty_armorvest";
	//	array[2] = "specialty_additionalprimaryweapon";
	//	
	//	struct.perks = array;
	//
	//	level.PlayerInventories[self.playername] = struct;
	//}
	
	
	// Handle reconnecting
	if(isDefined(level.PlayerInventories)){
		
		self thread WelcomeBack();
		
		self iprintln("Welcome back :D");
		
	}
	
	self thread SaveState();
	
	
}


SaveState(){
		
	// Map perks
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	
	for(;;){
		
		level waittill("end_of_round" );
		
		// Wait until the player is revived
		if(self.health <= 1)
		{
			for(;;)
			{
				if(self.health > 1){break;}
				wait 1;
			}
		}
		
		// Spectator check
		if(self.sessionstate == "spectator")
		{
			for(;;)
			{
				if(self.sessionstate != "spectator"){break;}
				wait 1;
			}
		}
		
		weapons = self GetWeaponsListPrimaries();
		self iprintln(weapons);
		
		// Save the player's struct, into a slot
		struct = SpawnStruct();

		// Save score
		struct.score = self.score;

		// Save weapons
		if(weapons.size <= 0){
			
			// Try to revert back
			// This is a secondary Failsafe and temporary solution, 
			// until the player has at least one weapon, the old save will be used (if one exists)
			if( (level.PlayerInventories[self.playername].size <= 0) && level.PlayerInventories[self.playername].weapons.size > 0 )
			{
				struct.weapons = level.PlayerInventories[self.playername].weapons;
				
			}
			
			
			// Delay the saving and wait until the player has at least one weapon
			for(;;)
			{
				wait 1;
				weapons = self GetWeaponsListPrimaries();
				if(weapons.size > 0){break;}
				
			}
			
			if(weapons.size > 0)
			{
				// We succesfully prevented a save failure
				struct.weapons = weapons;
				
			}else{
				
				// This should never be executed, but if so, warn the player.
				self iprintln("^1WARNING: ^7Your weapons couldn't be saved. Please survive one more round.");
				
			}
		}else{ struct.weapons = weapons; }
		
		
		// Save perks
		for ( q = 0; q < vending_triggers.size; q++ )
		{
			perk = vending_triggers[q].script_noteworthy;

			//if ( isdefined( self[i].perk_purchased ) && self[i].perk_purchased == perk )
			//{
			//	continue;
			//}

			if ( self HasPerk( perk ) )
			{
				
				struct.perks[struct.perks.size] = perk;
				
			}
			
			wait .1;
		}
		
		// Save player's inventory into the server
		level.PlayerInventories[self.playername] = struct;
		
		
	
	}
	
}

WelcomeBack(){
	
	
	if(isDefined(level.PlayerInventories))
	{
		if( isDefined(level.PlayerInventories[self.playername]) ){
			
			// Restore score
			self.score = level.PlayerInventories[self.playername].score;
			
			
			// Restore perks
			if(level.PlayerInventories[self.playername].perks.size > 0)
			{
				Perks = level.PlayerInventories[self.playername].perks;
			
				for ( q = 0; q < Perks.size; q++ )
				{
					wait .1;
					
					perk = Perks[q];
					self maps\_zombiemode_perks::give_perk( perk, true );

				}
			}
			
			wait .1;
			
			// Restore weapons
			if(level.PlayerInventories[self.playername].weapons.size > 0){
				
				weapons = self GetWeaponsListPrimaries();
				for(i=0;i < weapons.size;i++)
				{
					self TakeWeapon( weapons[i] );
				}
				wait .1;
				
				weapons = level.PlayerInventories[self.playername].weapons;
				for(i=0;i < weapons.size;i++)
				{
					self GiveWeapon( weapons[i] );
				}
				
				self SwitchToWeapon( weapons[0] );
				
			}else{
				
				integer = level.PlayerInventories[self.playername].score;
				self.score = integer + 5000;
				self iprintln("Couldn't give you weapons, giving you 5k in compensation.");
				
			}
			
			
		
		}		
	}
}