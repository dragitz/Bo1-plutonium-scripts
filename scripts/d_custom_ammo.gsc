#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#include animscripts\utility;


/*

Made by dragitz

Dev note:

need to fix:
	ammo red colored (might be unfixable)

*/
// Put your custom ammo here !
// editAmmo(weapon, clip, stock)
//
// weapon = the internal weapon name
// clip   = max ammo in the clip
// stock  = max ammo in the stock
// 
// Note: if the weapon is dual wield, and you set the clip to 99, both clips will have a maximum of 99 bullets
customList()
{

	editAmmo("m14_zm", 69, 999);
	
	
	level.CUSTOM_AMMO_DONE = 1;
}

stopReload()
{
	self endon("disconnect");
	
	while(1)
	{
		wait .2;
		CurrentWeapon = self getCurrentWeapon();
		
		if(!isDefined(level.FIX_WEAPONS[CurrentWeapon]))
			continue;
		
		if(self isSwitchingWeapons() || !self isPlayerReloading() || !self isonground())
			continue;
		
		MaxClip = level.CUSTOM_WEAPONS[CurrentWeapon].clip; 
		CurrentClip = self GetWeaponAmmoClip(CurrentWeapon);
		
		if(MaxClip == CurrentClip)
		{
			weapons = self GetWeaponsList();
			
			the_alt = weapons[1];
			if(CurrentWeapon == the_alt)
				the_alt = weapons[0];
			
			self SwitchToWeapon(the_alt);
			wait_network_frame();
			self SwitchToWeapon(CurrentWeapon);
			
			wait .3;
		}
			
           
	}

}

init()
{
	if ( GetDvar( #"zombiemode" ) == "0" )
		return;
		
	level.CUSTOM_AMMO_DONE = 0;
	level.CUSTOM_WEAPONS = [];
	
	level.FIX_WEAPONS = [];
	level.FIX_WEAPONS["python_zm"] = true;
	level.FIX_WEAPONS["china_lake_zm"] = true;
	level.FIX_WEAPONS["china_lake_upgraded_zm"] = true;
	level.FIX_WEAPONS["hs10_zm"] = true;
	level.FIX_WEAPONS["spas_zm"] = true;
	level.FIX_WEAPONS["spas_upgraded_zm"] = true;
	level.FIX_WEAPONS["ithaca_zm"] = true;
	level.FIX_WEAPONS["ithaca_upgraded_zm"] = true;

	level thread onplayerconnect();
	
	while(level.zombie_weapons.size < 20)
	{
		wait 0.5;
	}
	wait 1;
	
	// Use stock ammo to initialize everything
	weapons = getArrayKeys(level.zombie_weapons);
	for(i = 0; i < weapons.size; i++)
	{
		weapon = weapons[i];
		name = weapon;

		clip = WeaponClipSize( name );
		stock = WeaponStartAmmo( name );
		
		// create array
		struct = SpawnStruct();
		level.CUSTOM_WEAPONS[name] = struct;
		
		level.CUSTOM_WEAPONS[name].clip = clip;
		level.CUSTOM_WEAPONS[name].stock = stock;


		
		if(isDefined(level.zombie_weapons[name].upgrade_name))
		{

			name = level.zombie_weapons[name].upgrade_name;

			clip = WeaponClipSize( name );
			stock = WeaponStartAmmo( name );
			
			// create array
			struct = SpawnStruct();
			level.CUSTOM_WEAPONS[name] = struct;
			
			level.CUSTOM_WEAPONS[name].clip = clip;
			level.CUSTOM_WEAPONS[name].stock = stock;
			
			// alt weapons
			if(WeaponAltWeaponName( name ) != "none")
			{
				
				name = WeaponAltWeaponName( name );

				clip = WeaponClipSize( name );
				stock = WeaponStartAmmo( name );
				
				// create array
				struct = SpawnStruct();
				level.CUSTOM_WEAPONS[name] = struct;
				
				level.CUSTOM_WEAPONS[name].clip = clip;
				level.CUSTOM_WEAPONS[name].stock = stock;
			}			
		}
			

		wait .05;
	}
	
	customList();
}




onplayerconnect()
{
	
	for(;;)
	{
		level waittill("connected", player);
		player thread onplayerspawned();
	}
        
}

editAmmo(weapon, clip, stock)
{
	level.CUSTOM_WEAPONS[weapon].clip = clip;
	level.CUSTOM_WEAPONS[weapon].stock = stock;	
}




onplayerspawned()
{
    self endon("disconnect");
    self waittill("spawned_player");

	
	wait 1;
	
	while(level.CUSTOM_AMMO_DONE == 0)
	{
		wait .1;
	}

	self SetClientDvar( "player_clipSizeMultiplier", "50" );
	self SetClientDvar( "lowAmmoWarningPulseMax", "0" );
	
	self thread fixDualWield();
	self thread stopReload();

	// Ammo check
	while(1)
	{

		wait .1;
		
		
		CurrentWeapon = self getCurrentWeapon();
		
		
		if(weaponisdualwield(CurrentWeapon))
			continue;


		ClipRemainder = 0;
		StockRemainder = 0;
		
		MaxClip = level.CUSTOM_WEAPONS[CurrentWeapon].clip;
		MaxStock = level.CUSTOM_WEAPONS[CurrentWeapon].stock;
		
		CurrentClip = self GetWeaponAmmoClip( CurrentWeapon );
		
		
		// Primary clip
		if(CurrentClip > MaxClip)
		{
			
			ClipRemainder = CurrentClip - MaxClip;
			
			self setWeaponAmmoClip(CurrentWeapon, MaxClip);
			self setWeaponAmmoStock(CurrentWeapon, self GetWeaponAmmoStock( CurrentWeapon ) + ClipRemainder);

		}


		// disable max ammo reload
		// might cause some conflict with other scripts since this is a loop
		if(self isonground())
		{
			if(CurrentClip == MaxClip)
			{
				self DisableWeaponReload();
			}else{ self EnableWeaponReload();}
		}
		

		
		CurrentStock = self GetWeaponAmmoStock( CurrentWeapon );
		if(CurrentStock > MaxStock)
		{
			StockRemainder = CurrentStock - MaxStock;
			self setWeaponAmmoStock(CurrentWeapon, MaxStock);
		}
		
		
		// If clip ammo is at 30%, we display the "Reload" text
		diff = int(level.CUSTOM_WEAPONS[CurrentWeapon].clip * 0.3) + 1;
		
		
		if(self GetWeaponAmmoClip( CurrentWeapon ) <= diff && !self isSwitchingWeapons() && MaxClip > 1)
		{
			self SetClientDvar( "lowAmmoWarningColor1", "1.0 1.0 1.0 1.0" );
		}else{
			self SetClientDvar( "lowAmmoWarningColor1", "1.0 1.0 1.0 0.0" );
		}
		
	}
}

fixDualWield()
{
	self endon("disconnect");
	
	while(1)
	{
		wait .1;
		self.player_ammo_low = 0;
		
		CurrentWeapon = self getCurrentWeapon();
		
		if(!weaponisdualwield(CurrentWeapon))
			continue;
		
		
		MaxClip = level.CUSTOM_WEAPONS[CurrentWeapon].clip;
		MaxStock = level.CUSTOM_WEAPONS[CurrentWeapon].stock;
		
		dual_weapon = weapondualwieldweaponname(CurrentWeapon);
		CurrentClip = self GetWeaponAmmoClip(CurrentWeapon); // right clip
		CurrentClip2 = self GetWeaponAmmoClip(dual_weapon); // left clip
		
		CurrentStock = self GetWeaponAmmoStock(CurrentWeapon);
		
		if(self isonground())
		{
			if(CurrentClip == MaxClip && CurrentClip2 == MaxClip)
			{
				self DisableWeaponReload();
			}else{ self EnableWeaponReload();}
		}
		
		// check if redistribution needs to be done
		TotalAmmo = CurrentClip + CurrentClip2 + CurrentStock;
		
		if (CurrentClip > MaxClip && TotalAmmo > MaxClip)
		{
			ToMoveToLeftClip = CurrentClip - MaxClip;

			// check if there's enough space in the left clip for the overflow from the right clip
			if (ToMoveToLeftClip > CurrentClip2)
			{
				// move whatever is possible and update the overflow
				ToMoveToLeftClip = CurrentClip2;
				ToMoveToStock = (CurrentClip - MaxClip) - CurrentClip2;
			}
			else
			{
				ToMoveToStock = 0;
			}

			self setWeaponAmmoClip(CurrentWeapon, MaxClip);
			self setWeaponAmmoClip(dual_weapon, CurrentClip2 + ToMoveToLeftClip);
			self setWeaponAmmoStock(CurrentWeapon, CurrentStock + ToMoveToStock);

			// make sure stock doesn't overflow
			if (self GetWeaponAmmoStock(CurrentWeapon) > MaxStock)
			{
				self setWeaponAmmoStock(CurrentWeapon, MaxStock);
			}
		}
		else if(CurrentClip > MaxClip || CurrentClip2 > MaxClip)
		{
			
			if(CurrentClip > MaxClip)
			{				
				Remainder = CurrentClip - MaxClip;
				self setWeaponAmmoClip(CurrentWeapon, MaxClip);
				self setWeaponAmmoStock(CurrentWeapon, CurrentStock + Remainder);
			}
			if(CurrentClip2 > MaxClip)
			{				
				Remainder = CurrentClip2 - MaxClip;
				self setWeaponAmmoClip(dual_weapon, MaxClip);
				self setWeaponAmmoStock(dual_weapon, CurrentStock + Remainder);
			}
			// do not overflow
			if(self GetWeaponAmmoStock(CurrentWeapon) > MaxStock)
			{				
				self setWeaponAmmoStock(CurrentWeapon, MaxStock);
			}
			
		}
	}
	
}