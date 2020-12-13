################################################################################
# This section was created solely for you to put various bits of code that
# modify various wild Pokémon and trainers immediately prior to battling them.
# Be sure that any code you use here ONLY applies to the Pokémon/trainers you
# want it to apply to!
################################################################################

# Make all wild Pokémon shiny while a certain Switch is ON (see Settings).
Events.onWildPokemonCreate += proc { |_sender, e|
  pokemon = e[0]
  if $game_switches[SHINY_WILD_POKEMON_SWITCH]
    pokemon.makeShiny
  end
}

# Used in the random dungeon map.  Makes the levels of all wild Pokémon in that
# map depend on the levels of Pokémon in the player's party.
# This is a simple method, and can/should be modified to account for evolutions
# and other such details.  Of course, you don't HAVE to use this code.
=begin
Events.onWildPokemonCreate += proc { |_sender, e|
  pokemon = e[0]
  if $game_map.map_id == 51
    max_level = PBExperience.maxLevel
    new_level = pbBalancedLevel($Trainer.party) - 4 + rand(5)   # For variety
    new_level = 1 if new_level < 1
    new_level = max_level if new_level > max_level
    pokemon.level = new_level
    pokemon.calcStats
    pokemon.resetMoves
  end
}
=end

# CHANGED: Capture Froakie event
Events.onWildPokemonCreate+=proc {|sender,e|
  pokemon=e[0]
  if $game_switches[63]
    if rand(2) == 1
      pokemon.makeShiny
    end
    if rand(2) == 1
      pokemon.setAbility(0)
    else
      pokemon.setAbility(1)
    end
    pokemon.pbLearnMove(:QUICKATTACK)
    pokemon.pbLearnMove(:TOXIC)
    pokemon.pbLearnMove(:BUBBLE)
    pokemon.pbLearnMove(:LICK)
  end
}

# CHANGED: Battle Tangrowths event
Events.onWildPokemonCreate+=proc {|sender,e|
  pokemon=e[0]
  if $game_switches[67]
    pokemon.setAbility(0)
    pokemon.pbLearnMove(:SLEEPPOWDER)
    pokemon.pbLearnMove(:LEECHSEED)
    pokemon.pbLearnMove(:KNOCKOFF)
    pokemon.pbLearnMove(:VINEWHIP)
  end
}

# CHANGED: King's Club Snorlax
Events.onWildPokemonCreate+=proc {|sender,e|
  pokemon=e[0]
  if $game_switches[68]
    pokemon.setAbility(0)
    pokemon.pbLearnMove(:CRUNCH)
    pokemon.pbLearnMove(:ZENHEADBUTT)
    pokemon.pbLearnMove(:PURSUIT)
    pokemon.pbLearnMove(:PROTECT)
  end
}

# CHANGED: Zyree Ship Battles
Events.onWildPokemonCreate+=proc {|sender,e|
  pokemon=e[0]
  if $game_switches[74]
    if pokemon.species == PBSpecies::DHELMISE
      if pbGet(35) >= 4
        pokemon.pbLearnMove(:GYROBALL)
        pokemon.pbLearnMove(:MEGADRAIN)
        pokemon.pbLearnMove(:IRONDEFENSE)
        pokemon.pbLearnMove(:SHADOWCLAW)
      else
        pokemon.pbLearnMove(:WRAP)
        pokemon.pbLearnMove(:GYROBALL)
        pokemon.pbLearnMove(:PAINSPLIT)
        pokemon.pbLearnMove(:RAPIDSPIN)
      end
    else
      if pbGet(35) >= 4
        pokemon.pbLearnMove(:ACID)
        pokemon.pbLearnMove(:WATERPULSE)
        pokemon.pbLearnMove(:VENOSHOCK)
        pokemon.pbLearnMove(:SHOCKWAVE)
      else
        pokemon.pbLearnMove(:BUBBLE)
        pokemon.pbLearnMove(:FEINTATTACK)
        pokemon.pbLearnMove(:RAINDANCE)
        pokemon.pbLearnMove(:SMOKESCREEN)
      end
    end
  end
}

# CHANGED: Changes Combee's gender to female on Observatory Route
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $game_map.map_id==39 && isConst?(pokemon.species,PBSpecies,:COMBEE)
     pokemon.makeFemale
   end
}

# CHANGED: Changes all Rattatas to Alolan form on Deku Route
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $game_map.map_id==3 && isConst?(pokemon.species,PBSpecies,:RATTATA)
     pokemon.form = 1
   end
}

# This is the basis of a trainer modifier.  It works both for trainers loaded
# when you battle them, and for partner trainers when they are registered.
# Note that you can only modify a partner trainer's Pokémon, and not the trainer
# themselves nor their items this way, as those are generated from scratch
# before each battle.
#Events.onTrainerPartyLoad += proc { |_sender, e|
#  if e[0] # Trainer data should exist to be loaded, but may not exist somehow
#    trainer = e[0][0] # A PokeBattle_Trainer object of the loaded trainer
#    items = e[0][1]   # An array of the trainer's items they can use
#    party = e[0][2]   # An array of the trainer's Pokémon
#    YOUR CODE HERE
#  end
#}

# CHANGED: Add +2 levels to enemy trainer's Pokemon
Events.onTrainerPartyLoad += proc { |_sender, e|
  if e[0] # Trainer data should exist to be loaded, but may not exist somehow
    trainer = e[0][0] # A PokeBattle_Trainer object of the loaded trainer
    items = e[0][1]   # An array of the trainer's items they can use
    party = e[0][2]   # An array of the trainer's Pokémon
    if pbGamemode > 1 # Extreme+ modes
      for i in party
        newlevel = [i.level + 2, PBExperience.maxLevel].min
        i.level = newlevel
        i.calcStats
      end
    end
  end
}

# CHANGED: DR Underdome battles
Events.onTrainerPartyLoad += proc { |_sender, e|
  if e[0] # Trainer data should exist to be loaded, but may not exist somehow
    trainer = e[0][0] # A PokeBattle_Trainer object of the loaded trainer
    items = e[0][1]   # An array of the trainer's items they can use
    party = e[0][2]   # An array of the trainer's Pokémon
    if $game_switches[82]
      newlevel = $Trainer.party[0].level
      for i in $Trainer.party
        newlevel = i.level if i.level > newlevel
      end
      newlevel = pbGet(39) if newlevel > pbGet(39)
      for i in party
        i.level = newlevel
        i.calcStats
      end
    end
  end
}
