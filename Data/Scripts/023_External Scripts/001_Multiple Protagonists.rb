################################################################################
# Multiple Protagonists v3.0
# by NettoHikari
# 
# September 3, 2020
# 
# This script allows the player to have up to 8 main characters, each with their
# own Pokemon parties, PC and Item storages, Trainer data, etc. It is intended
# for use in games where at least 2 playable characters are introduced
# throughout the story, no matter how significant each protagonist is.
# 
# Credits MUST BE GIVEN to NettoHikari
# You should also credit the authors of Pokemon Essentials itself.
# 
#-------------------------------------------------------------------------------
# INSTALLATION
#-------------------------------------------------------------------------------
# Copy this script, place it somewhere between "Compiler" and "Main" in the
# script sections, and name it "Multiple Protagonists". In addition, make sure
# to define all of your playable characters in the Global Metadata (found under
# "PBS/metadata.txt" in your game folder), starting with PlayerA (PlayerH is
# the max).
# 
# Before using this script, make sure to start a new save file when testing.
# Since it adds new stored data, the script will probably throw errors when used
# with saves where the script wasn't present before. In addition, if you decide
# to release your game in segments, it is important to have this script
# installed in the very first version itself, so as not to cause any problems to
# the player.
# 
# To install the "Switch" character command in the pause menu, follow the
# instructions below.
# 
# You will need to paste the following code into the section "PScreen_PauseMenu"
# at the appropriate lines (all of which are under "def pbStartPokemonMenu").
# If you've already made your own edits to the script before, then ignore the
# suggested line numbers below and just find each line with CTRL + Shift + F.

=begin
  1. You'll need to start by defining a variable for the command. Place the
     following line AFTER the line "cmdEndGame  = -1" (around line 106):
  
     cmdEndGame  = -1 # Find this
     cmdSwitch   = -1 # Add this below
  
  2. Now you need to add it to the list of pause menu commands. Place these 4
     lines AFTER the line "commands[cmdTrainer = commands.length]  = $Trainer.name"
     (around line 119):
  
     commands[cmdTrainer = commands.length]  = $Trainer.name # Find this
     # Add following lines below
     if $PokemonGlobal.commandCharacterSwitchOn && !pbInSafari? &&
           !pbInBugContest? && !pbBattleChallenge.pbInProgress?
       commands[cmdSwitch = commands.length] = _INTL("Switch")
     end
  
  3. Finally, you need to add the code for what actually happens when the player
     selects the command. Add the following code BEFORE the line
     "elsif cmdOption>=0 && command==cmdOption" (around line 247):
  
     elsif cmdSwitch>=0 && command==cmdSwitch
       characters = []
       characterIDs = []
       for i in 0...8
         if $PokemonGlobal.allowedCharacters[i] && i != $PokemonGlobal.playerID
           characters.push($PokemonGlobal.mainCharacters[i][PBCharacterData::Trainer].name)
           characterIDs.push(i)
         end
       end
       if characters.length <= 0
         pbMessage(_INTL("You're the only character!"))
         next
       end
       characters.push("Cancel")
       command = pbShowCommands(nil, characters, characters.length)
       if command >= 0 && command < characters.length - 1
         @scene.pbHideMenu
         pbSwitchCharacter(characterIDs[command])
         break
       end
     # Add lines above this line
     elsif cmdOption>=0 && command==cmdOption # Find this
  
  4. That's it! When you enable character switching through the menu, this
     should now show up and let the player switch between characters.
=end

# In addition, you'll need to allow the use of \PN0 - \PN7 for map names and
# Show Text boxes, exactly like how \PN works. To do this, follow the
# instructions below.

=begin
  1. In section Game_Map, around line 95:
  
     gsubPN(ret) # Add this above
     ret.gsub!(/\\PN/,$Trainer.name) if $Trainer # Find this
  
  2. In section Messages, around line 867:
  
     gsubPN(map) # Add this above
     map.gsub!(/\\PN/,$Trainer.name) if $Trainer # Find this
  
  3. In section Messages, around line 1045:
  
     gsubPN(text) if defined?(gsubPN) # Add this above
     text.gsub!(/\\pn/i,$Trainer.name) if $Trainer # Find this
  
  4. In section Battle_StartAndEnd, around line 409:
  
     gsubPN(msg) # Add this above
     pbDisplayPaused(msg.gsub(/\\[Pp][Nn]/,pbPlayer.name)) # Find this
  
  5. In section Battle_StartAndEnd, around line 444:
  
     gsubPN(msg) # Add this above
     pbDisplayPaused(msg.gsub(/\\[Pp][Nn]/,pbPlayer.name)) # Find this

=end

#-------------------------------------------------------------------------------
# SCRIPT USAGE
#-------------------------------------------------------------------------------
# To switch to another character at any point in the story, simply call
# "pbSwitchCharacter(id)", where the id corresponds to the definition in the
# Global Metadata (PlayerA is 0, B is 1, etc). If you're switching to a
# character for the first time, you can pass in the same parameters as you would
# for "pbTrainerName", though it's not necessary.
# 
# At the start of the game, the character id is initially 0 (PlayerA). Use
# pbTrainerName to set the character up instead of pbSwitchCharacter, unless
# you want the starting character to be someone else.
# 
# You can enable and disable the "Switch" command with
# "pbEnableCharacterCommandSwitching" and "pbDisableCharacterCommandSwitching".
# 
# You can also enable and disable certain characters from the Switch command
# with "pbEnableCharacter(id)" and "pbDisableCharacter(id)", where "id" is the
# character id.
# 
# The "pbSetLastMap(id, map_id, x, y, dir)" function lets you set the spawn
# point of the character id to the specified location, though this doesn't apply
# when pbSwitchCharacter is called from an event.
# 
# You can use \PN0 - \PN7 to refer to each of the protagonists' names (\PN0 is
# PlayerA, \PN1 is Player B, and so on) in map names exactly like the way you
# use \PN to refer to the .
# 
# You can register or battle against other characters (even yourself!) by
# setting the trainer id as the character id and the trainer name as
# "PROTAG". The general format is pbRegisterPartner(character_id, "PROTAG")
# and pbTrainerBattle(character_id, "PROTAG", _I("END SPEECH"))
# (and similar for one or more characters in pbDoubleTrainerBattle)
# 
# For example, if you wanted to fight against Player B, you can use
# this line: pbTrainerBattle(1, "PROTAG", _I("..."))
# More examples can be found below.
# 
# There are two ways of trading between characters. The first is basically
# like a standard trade with an NPC, but instead with another character. The
# second allows a character to send Pokemon from their party to another
# character. Examples of both systems can be found below.
# 
# I have also included a compatibility fix for mej71's Follow Pokemon script
# in the "Script Compatibility" section below.
# 
# The instructions above are a fairly abridged version of each function's
# capabilities. While this should be enough to be able to sufficiently use the
# script, I highly suggest you to read the "List of Functions" section below to
# gain a better understanding of how the script works.
# 
#-------------------------------------------------------------------------------
# LIST OF FUNCTIONS
#-------------------------------------------------------------------------------
# def pbEnableCharacterCommandSwitching
# - Adds the "Switch" command to the pause menu.
# - Starts as disabled by default.
# 
# def pbDisableCharacterCommandSwitching
# - Removes the "Switch" command from the pause menu.
# 
# def pbEnableCharacter(id)
# - Adds a character to the list of characters that can be switched to from the
#   pause menu.
# - All characters that have been switched to at least once are enabled by
#   default (including PlayerA at the start).
# 
# def pbDisableCharacter(id)
# - Removes a character from the list of characters that can be switched to from
#   the pause menu.
# 
# def pbSwitchCharacter(id, name = nil, outfit = 0)
# - The main command for switching to another character. It requires the "id"
#   of the character, which is the id from the Global Metadata (PlayerA has
#   id = 0, PlayerB's id = 1, etc). It also corresponds to the $Trainer.metaID.
# - Additionally, the function has two optional parameters, "name" and "outfit".
#   If you are switching to a character for the first time, the function will
#   automatically call "pbTrainerName" on it, and if you set name and outfit at
#   that time, they will be sent to pbTrainerName.
#   Example: pbSwitchCharacter(1, "Leaf", 1) will first create the character,
#   give them the name "Leaf", and set their outfit to 1.
# - This function will fade out/fade in when called from the pause menu by the
#   player, but NOT when called through an event, so you will need to call
#   the "Transfer Player" command after switching in an event.
# - It's generally a good idea to transfer the player AFTER calling this
#   function (it won't be noticeable to the player when done after a blackout)
#   rather than before, because if you transfer the player BEFORE calling this
#   function, the map data stored for the old character will be that of the new
#   map, where the new character is supposed to be. It usually won't cause any
#   problems either way, though.
# - All global switches/variables and event self-switches DO NOT get saved in
#   the character's data, so if you have an event that you want to work on each
#   individual character instead of only one, make sure to handle that by having
#   the event keep track of which characters have already used it.
# 
# def pbSetLastMap(id, map_id, x, y, dir)
# - Sets the location of a character from the "id" to the specified location.
#   This only takes effect when the character is switched to by the player, not
#   by an event.
# - Erases the "last Pokecenter" location for the character you set it on, so
#   unless that character visits a new Pokecenter after being switched to, that
#   character's blackout location will be the global metadata "home" variable
#   instead. If you do force a new "last map", make sure to put a Pokecenter
#   (or anything else that calls pbSetPokemonCenter) around that area.
# 
# def pbCharacterInfoArray
# - Returns an array of the current character's data. Each index is given by a
#   constant from the module PBCharacterData (i.e. index 0 is the constant
#   PBCharacterData::Trainer, which refers to the PokeBattle_Trainer object).
#   See module PBCharacterData below for full list.
# - Used internally by other functions of this script.
# 
# def pbDefaultCharacterInfoArray
# - Returns an array of the default data (used when creating a new character).
# - Used internally by other functions of this script.
# 
# def pbGetForeignCharacterID
# - Returns a unique trainer ID compared to all previously defined trainers (the
#   ID that shows up on the trainer card, not to be confused with character ID).
# - Used internally by other functions of this script.
# 
# def gsubPN(name)
# - Modifies the input string to replace \PN0 - \PN7 with the 8 protagonists'
#   names
# - Used internally in other script sections.
# 
# def pbLoadTrainer(trainerid,trainername,partyid=0)
# - Modified to allow registering/battling other characters
# - If trainername is set to "PROTAG" in pbRegisterPartner, pbTrainerBattle,
#   or pbDoubleTrainerBattle, then the protagonist with their character ID
#   equal to trainerid will be cloned and returned (the original character won't
#   be affected after battle)
# - Used internally in pbRegisterPartner, pbTrainerBattle, and
#   pbDoubleTrainerBattle.
# 
# - Ex. If Player A wants to fight alongside Player B against Player C and a
#   camper, the following two lines can be used:
# 
#   pbRegisterPartner(1, "PROTAG")
#   pbDoubleTrainerBattle(2, "PROTAG", 0, _I(""), :CAMPER, "Liam", 0, _I(""))
# 
# - Ex. If Player A wants to fight against themselves, use this line:
#   pbTrainerBattle(0, "PROTAG", _I(""))
# 
# def getTrainerFromCharacter(id)
# - Returns PokeBattle_Trainer of character at that id
# - Used internally in this script
# 
# def characterIDValid?(id)
# - Returns true if character exists whose character ID is "id"
# - Used internally in this script
# 
# def pbChoosePokemonFromCharacter(id,variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
# - Same as pbChoosePokemon but for a character different than the current one.
# - First parameter is character ID, the rest are the same as pbChoosePokemon.
# 
# def pbChooseTradablePokemonFromCharacter(id,variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
# - Same as pbChooseTradablePokemon but for a character different than the
#   current one.
# - First parameter is character ID, the rest are the same as
#   pbChooseTradablePokemon.
# 
# def pbTradeWithCharacter(id, firstPokemonIndex, secondPokemonIndex)
# - Performs trade between current character with firstPokemonIndex and another
#   character with secondPokemonIndex.
# - Similar to pbStartTrade but for other characters rather than NPCs.
# - Used only after choosing Pokemon from both parties using the default
#   Essentials methods for the current character and the methods from this
#   script for the second character.
# - Ex. Assume Player A (the current character) wants to trade with Player B.
# 
#   First choose a Pokemon from the current character:
#   pbChoosePokemon(1, 2) # "pbGet(1)" is firstPokemonIndex
# 
#   If pbGet(1) is not -1, choose a Pokemon from Player B:
#   pbChoosePokemonFromCharacter(1, 3, 4) # "pbGet(3)" is secondPokemonIndex
#   # The first "1" means character ID of 1 = Player B
# 
#   If pbGet(3) is not -1, perform the trade:
#   pbTradeWithCharacter(1, pbGet(1), pbGet(3))
#   # The first "1" means character ID of 1 = Player B
# 
#   You can put whatever messages and other commands you want for your trade
#   event. Visit the "Trading Pokemon" section on the Essentials wiki to see an
#   example of a default trade event.
# 
# def pbSendToCharacter(id, pokemonIndex)
# - Sends Pokemon at pokemonIndex from current character to another character.
# - Can use pbChoosePokemon to choose which Pokemon to send, much like
#   pbTradeWithCharacter.
# 
#-------------------------------------------------------------------------------
# POTENTIAL BUGS
#-------------------------------------------------------------------------------
# Any maps that have \PN in the name (a placeholder for the player's name) have
# a minor bug of not updating the map's name correctly. For example, if a player
# named Red steps into a house named "\PN's House", the name would show as
# "Red's House", and if later another character named Blue comes in, the name
# would still show "Red's House", UNTIL you save, close and open the game again,
# in which case it will then turn into "Blue's House". If you have any maps with
# \PN in it, this can be fixed by replacing the following:
# 
# ret.gsub!(/\\PN/,$Trainer.name) if $Trainer # Find this
# 
# with:
# 
# ret=ret.gsub(/\\PN/,$Trainer.name) if $Trainer # Replace it with this
# 
# Solution added by Tustin2121
# 
#-------------------------------------------------------------------------------
# SCRIPT COMPATIBILITY
#-------------------------------------------------------------------------------
# This script works just fine in base Essentials (and mej's Follow Pokemon
# script if you use that), but if you add any new data for your character
# outside of data that is already saved by this script, you will need to add
# that into this script manually. For example, if you add a new variable in
# class PokeBattle_Trainer, you DO NOT need to do anything as the entire
# PokeBattle_Trainer object is saved for each character. However, you MAY need
# to add it below if you add a new variable in class PokemonGlobalMetadata or
# elsewhere. Below is a guide on how to add such data to this script (I use
# switch ID 5 as an example, but you can apply this to whatever you actually
# need to add).
# 
# 1. Add a constant for the data to the bottom of module PBCharacterData:
# 
#    PokecenterDirection   = 45 # Find this
#    Example               = XX # Add this (name can be whatever makes sense)
#    # The next number (XX) should be one more than the previous number.
#    # If you haven't added data using this tutorial yet:
#    # If you aren't using Follow Pokemon then it would be 46.
#    # If you are using it, then it would be 52.
# 
# 2. In def pbSwitchCharacter:
# 
#    $PokemonGlobal.pokecenterDirection   = meta[PBCharacterData::PokecenterDirection] # Find this
#    $game_switches[5]                    = meta[PBCharacterData::Example] # Add this
# 
# 3. In def pbCharacterInfoArray:
# 
#    info[PBCharacterData::PokecenterDirection]   = $PokemonGlobal.pokecenterDirection # Find this
#    info[PBCharacterData::Example]               = $game_switches[5] # Add this
# 
# 4. In def pbDefaultCharacterInfoArray:
# 
#    info[PBCharacterData::PokecenterDirection]   = -1 # Find this
#    info[PBCharacterData::Example]               = false # Add this
# 
# 5. Once you've added the data you needed, make sure to start a new save in
#    order to test those changes.
# 
#-------------------------------------------------------------------------------
# I would like to acknowledge Tustin2121 for making a tutorial for Multiple
# Protagonists on the old wiki, before the wiki was shut down. His tutorial
# essentially laid the basis for how I would design my script.
# 
# I hope you enjoy this script!
# - NettoHikari
################################################################################

PluginManager.register({
  :name => "Multiple Protagonists",
  :credits => ["NettoHikari"],
  :version => "v3.0",
  :link => "https://reliccastle.com/resources/280/"
})

# List of objects stored for each character
# 0. Trainer Object
# 1. Item Bag
# 2. Pokemon Storage
# 3. Running Shoes
# 4. Snag Machine
# 5. Seen Storage Creator
# 6. Coins
# 7. Sootsack
# 8. Mailbox
# 9. Item Storage
# 10. Happiness Steps
# 11. Pokerus Time
# 12. Daycare Pokemon
# 13. Daycare Egg
# 14. Daycare Egg Steps
# 15. Unlocked Pokedexes
# 16. Viable Pokedexes
# 17. Current Pokedex
# 18. Last Viewed Pokemon in each Dex
# 19. Pokedex Search Mode
# 20. Visited Maps
# 21. Partner Trainer
# 22. Phone Numbers
# 23. Phone Time
# 24. Dependent Events
# 25. Pokeradar Battery
# 26. Purify Chamber
# 27. Seen Purify Chamber
# 28. Triad Collection
# 29. Trainer Recording
# 30. Last Map
# 31. Last X
# 32. Last Y
# 33. Last Direction
# 34. Bicycle Active
# 35. Surfing Active
# 36. Diving Active
# 37. Repel Steps Remaining
# 38. Flash Active
# 39. Bridge Tile Passage
# 40. Last Healing Spot
# 41. Cave Escape Point
# 42. Last Pokecenter Map ID
# 43. Last Pokecenter X
# 44. Last Pokecenter Y
# 45. Last Pokecenter Direction
# 46. Last Battle (Battle Tower)
# 47. Map Trail

module PBCharacterData
  Trainer               = 0
  PokemonBag            = 1
  PokemonStorage        = 2
  RunningShoes          = 3
  SnagMachine           = 4
  SeenStorageCreator    = 5
  Coins                 = 6
  SootSack              = 7
  Mailbox               = 8
  PCItemStorage         = 9
  HappinessSteps        = 10
  PokerusTime           = 11
  Daycare               = 12
  DaycareEgg            = 13
  DaycareEggSteps       = 14
  PokedexUnlocked       = 15
  PokedexViable         = 16
  PokedexDex            = 17
  PokedexIndex          = 18
  PokedexMode           = 19
  VisitedMaps           = 20
  Partner               = 21
  PhoneNumbers          = 22
  PhoneTime             = 23
  DependentEvents       = 24
  PokeradarBattery      = 25
  PurifyChamber         = 26
  SeenPurifyChamber     = 27
  Triads                = 28
  TrainerRecording      = 29
  MapID                 = 30
  X                     = 31
  Y                     = 32
  Direction             = 33
  Bicycle               = 34
  Surfing               = 35
  Diving                = 36
  Repel                 = 37
  FlashUsed             = 38
  Bridge                = 39
  HealingSpot           = 40
  EscapePoint           = 41
  PokecenterMapID       = 42
  PokecenterX           = 43
  PokecenterY           = 44
  PokecenterDirection   = 45
  LastBattle            = 46
  MapTrail              = 47
  if defined?(Following_Activated_Switch)
    Following_Activated_Switch = 48
    Toggle_Following_Switch    = 49
    Current_Following_Variable = 50
    ItemWalk                   = 51
    Walking_Time_Variable      = 52
    Walking_Item_Variable      = 53
  end
end

class PokemonGlobalMetadata
  attr_accessor :mainCharacters           # Stores all protagonists' data
  attr_accessor :commandCharacterSwitchOn # Enables character switching from menu
  attr_accessor :allowedCharacters        # Characters allowed for command switching
  
  alias new_initialize initialize
  def initialize
    new_initialize
    @mainCharacters = Array.new(8)
    @commandCharacterSwitchOn = false
    @allowedCharacters = Array.new(8, false)
    @allowedCharacters[0] = true
  end
end

# Enables character switching through pause menu
def pbEnableCharacterCommandSwitching
  $PokemonGlobal.commandCharacterSwitchOn = true
end

# Disables character switching through pause menu
def pbDisableCharacterCommandSwitching
  $PokemonGlobal.commandCharacterSwitchOn = false
end

# Enables specific character in command switching
def pbEnableCharacter(id)
  return if !characterIDValid?(id)
  $PokemonGlobal.allowedCharacters[id] = true
end

# Disables specific character in command switching
def pbDisableCharacter(id)
  return if !characterIDValid?(id)
  $PokemonGlobal.allowedCharacters[id] = false
end

# Main function to switch between characters
def pbSwitchCharacter(id, name = nil, outfit = 0)
  return if id<0 || id>=8 || id == $Trainer.metaID
  meta = $PokemonGlobal.mainCharacters[id]
  oldid = $Trainer.metaID
  $PokemonGlobal.mainCharacters[oldid] = pbCharacterInfoArray
  if !meta
    $Trainer = nil
    $PokemonGlobal.playerID = id
    pbTrainerName(name, outfit)
    $Trainer.metaID = id
    $Trainer.id = pbGetForeignCharacterID
    $PokemonTemp.begunNewGame = false
    newmeta = pbDefaultCharacterInfoArray
    # Set Trainer and PokemonBag to what was already set in pbTrainerName
    newmeta[PBCharacterData::Trainer] = $Trainer
    newmeta[PBCharacterData::PokemonBag] = $PokemonBag
    $PokemonGlobal.mainCharacters[id] = newmeta
    meta = $PokemonGlobal.mainCharacters[id]
    pbEnableCharacter(id)
  end
  if pbMapInterpreterRunning? # Must have been called through event command
    meta[PBCharacterData::MapID]                 = -1
    meta[PBCharacterData::X]                     = -1
    meta[PBCharacterData::Y]                     = -1
    meta[PBCharacterData::Direction]             = -1
    meta[PBCharacterData::Bicycle]               = false
    meta[PBCharacterData::Surfing]               = false
    meta[PBCharacterData::Diving]                = false
    meta[PBCharacterData::Repel]                 = 0
    meta[PBCharacterData::FlashUsed]             = false
    meta[PBCharacterData::Bridge]                = 0
    meta[PBCharacterData::EscapePoint]           = []
  end
  $Trainer                             = meta[PBCharacterData::Trainer]
  $PokemonBag                          = meta[PBCharacterData::PokemonBag]
  $PokemonStorage                      = meta[PBCharacterData::PokemonStorage]
  $PokemonGlobal.runningShoes          = meta[PBCharacterData::RunningShoes]
  $PokemonGlobal.snagMachine           = meta[PBCharacterData::SnagMachine]
  $PokemonGlobal.seenStorageCreator    = meta[PBCharacterData::SeenStorageCreator]
  $PokemonGlobal.coins                 = meta[PBCharacterData::Coins]
  $PokemonGlobal.sootsack              = meta[PBCharacterData::SootSack]
  $PokemonGlobal.mailbox               = meta[PBCharacterData::Mailbox]
  $PokemonGlobal.pcItemStorage         = meta[PBCharacterData::PCItemStorage]
  $PokemonGlobal.happinessSteps        = meta[PBCharacterData::HappinessSteps]
  $PokemonGlobal.pokerusTime           = meta[PBCharacterData::PokerusTime]
  $PokemonGlobal.daycare               = meta[PBCharacterData::Daycare]
  $PokemonGlobal.daycareEgg            = meta[PBCharacterData::DaycareEgg]
  $PokemonGlobal.daycareEggSteps       = meta[PBCharacterData::DaycareEggSteps]
  $PokemonGlobal.pokedexUnlocked       = meta[PBCharacterData::PokedexUnlocked]
  $PokemonGlobal.pokedexViable         = meta[PBCharacterData::PokedexViable]
  $PokemonGlobal.pokedexDex            = meta[PBCharacterData::PokedexDex]
  $PokemonGlobal.pokedexIndex          = meta[PBCharacterData::PokedexIndex]
  $PokemonGlobal.pokedexMode           = meta[PBCharacterData::PokedexMode]
  $PokemonGlobal.visitedMaps           = meta[PBCharacterData::VisitedMaps]
  $PokemonGlobal.partner               = meta[PBCharacterData::Partner]
  $PokemonGlobal.phoneNumbers          = meta[PBCharacterData::PhoneNumbers]
  $PokemonGlobal.phoneTime             = meta[PBCharacterData::PhoneTime]
  $PokemonGlobal.dependentEvents       = [] # Gets set after fade
  pbRemoveDependencies()
  if defined?(Following_Activated_Switch)
    $game_switches[Following_Activated_Switch] = false
    $game_switches[Toggle_Following_Switch] = false
    $game_variables[Current_Following_Variable] = 0
    $game_variables[ItemWalk] = 0
    $game_variables[Walking_Time_Variable] = 0
    $game_variables[Walking_Item_Variable] = 0
  end
  $PokemonGlobal.pokeradarBattery      = meta[PBCharacterData::PokeradarBattery]
  $PokemonGlobal.purifyChamber         = meta[PBCharacterData::PurifyChamber]
  $PokemonGlobal.seenPurifyChamber     = meta[PBCharacterData::SeenPurifyChamber]
  $PokemonGlobal.triads                = meta[PBCharacterData::Triads]
  $PokemonGlobal.trainerRecording      = meta[PBCharacterData::TrainerRecording]
  # Assumes that if called through event, then meta[PBCharacterData::MapID]
  # was set to -1 earlier
  # Handles fade transition between characters
  if meta[PBCharacterData::MapID] >= 0 && $PokemonGlobal.commandCharacterSwitchOn
    $game_temp.player_new_map_id       = meta[PBCharacterData::MapID]
    $game_temp.player_new_x            = meta[PBCharacterData::X]
    $game_temp.player_new_y            = meta[PBCharacterData::Y]
    $game_temp.player_new_direction    = meta[PBCharacterData::Direction]
    $game_screen.start_tone_change(Tone.new(-255, -255, -255, 0), 12)
    pbWait(16)
    $scene.transfer_player
    $game_screen.start_tone_change(Tone.new(0, 0, 0, 0), 12)
  end
  $PokemonGlobal.bicycle               = meta[PBCharacterData::Bicycle]
  $PokemonGlobal.surfing               = meta[PBCharacterData::Surfing]
  $PokemonGlobal.diving                = meta[PBCharacterData::Diving]
  $PokemonGlobal.repel                 = meta[PBCharacterData::Repel]
  $PokemonGlobal.flashUsed             = meta[PBCharacterData::FlashUsed]
  $PokemonGlobal.bridge                = meta[PBCharacterData::Bridge]
  $PokemonGlobal.healingSpot           = meta[PBCharacterData::HealingSpot]
  $PokemonGlobal.escapePoint           = meta[PBCharacterData::EscapePoint]
  $PokemonGlobal.pokecenterMapId       = meta[PBCharacterData::PokecenterMapID]
  $PokemonGlobal.pokecenterX           = meta[PBCharacterData::PokecenterX]
  $PokemonGlobal.pokecenterY           = meta[PBCharacterData::PokecenterY]
  $PokemonGlobal.pokecenterDirection   = meta[PBCharacterData::PokecenterDirection]
  $PokemonGlobal.dependentEvents       = meta[PBCharacterData::DependentEvents]
  $PokemonTemp.dependentEvents = DependentEvents.new
  $PokemonTemp.dependentEvents.updateDependentEvents
  $PokemonGlobal.lastbattle            = meta[PBCharacterData::LastBattle]
  $PokemonGlobal.mapTrail              = meta[PBCharacterData::MapTrail]
  if defined?(Following_Activated_Switch)
    $game_switches[Following_Activated_Switch] = meta[PBCharacterData::Following_Activated_Switch]
    $game_switches[Toggle_Following_Switch] = meta[PBCharacterData::Toggle_Following_Switch]
    $game_variables[Current_Following_Variable] = meta[PBCharacterData::Current_Following_Variable]
    $game_variables[ItemWalk] = meta[PBCharacterData::ItemWalk]
    $game_variables[Walking_Time_Variable] = meta[PBCharacterData::Walking_Time_Variable]
    $game_variables[Walking_Item_Variable] = meta[PBCharacterData::Walking_Item_Variable]
    $PokemonTemp.dependentEvents.refresh_sprite
  end
  $PokemonGlobal.playerID = $Trainer.metaID
  $game_player.charsetData = nil
  pbUpdateVehicle
  $PokemonTemp.hud.update # CHANGED: Update HUD on switching
end

# Saves data of Player A (id 0) at start of game
alias protag_pbTrainerName pbTrainerName
def pbTrainerName(name=nil,outfit=0)
  protag_pbTrainerName(name, outfit)
  if $PokemonGlobal.playerID == 0
    $PokemonGlobal.mainCharacters[0] = pbCharacterInfoArray
  end
end

# Sets the "last map" variables of character
def pbSetLastMap(id, map_id, x, y, dir)
  return if !characterIDValid?(id) || map_id < 0
  info = $PokemonGlobal.mainCharacters[id]
  info[PBCharacterData::MapID]                 = map_id
  info[PBCharacterData::X]                     = x
  info[PBCharacterData::Y]                     = y
  info[PBCharacterData::Direction]             = dir
  info[PBCharacterData::Bicycle]               = false
  info[PBCharacterData::Surfing]               = false
  info[PBCharacterData::Diving]                = false
  info[PBCharacterData::Repel]                 = 0
  info[PBCharacterData::FlashUsed]             = false
  info[PBCharacterData::Bridge]                = 0
  info[PBCharacterData::HealingSpot]           = nil
  info[PBCharacterData::EscapePoint]           = []
  info[PBCharacterData::PokecenterMapID]       = -1
  info[PBCharacterData::PokecenterX]           = -1
  info[PBCharacterData::PokecenterY]           = -1
  info[PBCharacterData::PokecenterDirection]   = -1
end

def pbCharacterInfoArray
  info = []
  info[PBCharacterData::Trainer]               = $Trainer
  info[PBCharacterData::PokemonBag]            = $PokemonBag
  info[PBCharacterData::PokemonStorage]        = $PokemonStorage
  info[PBCharacterData::RunningShoes]          = $PokemonGlobal.runningShoes
  info[PBCharacterData::SnagMachine]           = $PokemonGlobal.snagMachine
  info[PBCharacterData::SeenStorageCreator]    = $PokemonGlobal.seenStorageCreator
  info[PBCharacterData::Coins]                 = $PokemonGlobal.coins
  info[PBCharacterData::SootSack]              = $PokemonGlobal.sootsack
  info[PBCharacterData::Mailbox]               = $PokemonGlobal.mailbox
  info[PBCharacterData::PCItemStorage]         = $PokemonGlobal.pcItemStorage
  info[PBCharacterData::HappinessSteps]        = $PokemonGlobal.happinessSteps
  info[PBCharacterData::PokerusTime]           = $PokemonGlobal.pokerusTime
  info[PBCharacterData::Daycare]               = $PokemonGlobal.daycare
  info[PBCharacterData::DaycareEgg]            = $PokemonGlobal.daycareEgg
  info[PBCharacterData::DaycareEggSteps]       = $PokemonGlobal.daycareEggSteps
  info[PBCharacterData::PokedexUnlocked]       = $PokemonGlobal.pokedexUnlocked
  info[PBCharacterData::PokedexViable]         = $PokemonGlobal.pokedexViable
  info[PBCharacterData::PokedexDex]            = $PokemonGlobal.pokedexDex
  info[PBCharacterData::PokedexIndex]          = $PokemonGlobal.pokedexIndex
  info[PBCharacterData::PokedexMode]           = $PokemonGlobal.pokedexMode
  info[PBCharacterData::VisitedMaps]           = $PokemonGlobal.visitedMaps
  info[PBCharacterData::Partner]               = $PokemonGlobal.partner
  info[PBCharacterData::PhoneNumbers]          = $PokemonGlobal.phoneNumbers
  info[PBCharacterData::PhoneTime]             = $PokemonGlobal.phoneTime
  info[PBCharacterData::DependentEvents]       = $PokemonGlobal.dependentEvents
  info[PBCharacterData::PokeradarBattery]      = $PokemonGlobal.pokeradarBattery
  info[PBCharacterData::PurifyChamber]         = $PokemonGlobal.purifyChamber
  info[PBCharacterData::SeenPurifyChamber]     = $PokemonGlobal.seenPurifyChamber
  info[PBCharacterData::Triads]                = $PokemonGlobal.triads
  info[PBCharacterData::TrainerRecording]      = $PokemonGlobal.trainerRecording
  info[PBCharacterData::MapID]                 = $game_player.map.map_id
  info[PBCharacterData::X]                     = $game_player.x
  info[PBCharacterData::Y]                     = $game_player.y
  info[PBCharacterData::Direction]             = $game_player.direction
  info[PBCharacterData::Bicycle]               = $PokemonGlobal.bicycle
  info[PBCharacterData::Surfing]               = $PokemonGlobal.surfing
  info[PBCharacterData::Diving]                = $PokemonGlobal.diving
  info[PBCharacterData::Repel]                 = $PokemonGlobal.repel
  info[PBCharacterData::FlashUsed]             = $PokemonGlobal.flashUsed
  info[PBCharacterData::Bridge]                = $PokemonGlobal.bridge
  info[PBCharacterData::HealingSpot]           = $PokemonGlobal.healingSpot
  info[PBCharacterData::EscapePoint]           = $PokemonGlobal.escapePoint
  info[PBCharacterData::PokecenterMapID]       = $PokemonGlobal.pokecenterMapId
  info[PBCharacterData::PokecenterX]           = $PokemonGlobal.pokecenterX
  info[PBCharacterData::PokecenterY]           = $PokemonGlobal.pokecenterY
  info[PBCharacterData::PokecenterDirection]   = $PokemonGlobal.pokecenterDirection
  info[PBCharacterData::LastBattle]            = $PokemonGlobal.lastbattle
  info[PBCharacterData::MapTrail]              = $PokemonGlobal.mapTrail
  if defined?(Following_Activated_Switch)
    info[PBCharacterData::Following_Activated_Switch] = $game_switches[Following_Activated_Switch]
    info[PBCharacterData::Toggle_Following_Switch] = $game_switches[Toggle_Following_Switch]
    info[PBCharacterData::Current_Following_Variable] = $game_variables[Current_Following_Variable]
    info[PBCharacterData::ItemWalk] = $game_variables[ItemWalk]
    info[PBCharacterData::Walking_Time_Variable] = $game_variables[Walking_Time_Variable]
    info[PBCharacterData::Walking_Item_Variable] = $game_variables[Walking_Item_Variable]
  end
  return info
end

def pbDefaultCharacterInfoArray
  info = []
  info[PBCharacterData::Trainer]               = nil
  info[PBCharacterData::PokemonBag]            = PokemonBag.new
  info[PBCharacterData::PokemonStorage]        = PokemonStorage.new
  info[PBCharacterData::RunningShoes]          = false
  info[PBCharacterData::SnagMachine]           = false
  info[PBCharacterData::SeenStorageCreator]    = false
  info[PBCharacterData::Coins]                 = 0
  info[PBCharacterData::SootSack]              = 0
  info[PBCharacterData::Mailbox]               = nil
  info[PBCharacterData::PCItemStorage]         = nil
  info[PBCharacterData::HappinessSteps]        = 0
  info[PBCharacterData::PokerusTime]           = nil
  info[PBCharacterData::Daycare]               = [[nil,0],[nil,0]]
  info[PBCharacterData::DaycareEgg]            = false
  info[PBCharacterData::DaycareEggSteps]       = 0
  info[PBCharacterData::PokedexUnlocked]       = []
  info[PBCharacterData::PokedexViable]         = []
  numRegions = pbLoadRegionalDexes.length
  info[PBCharacterData::PokedexDex]            = (numRegions==0) ? -1 : 0
  info[PBCharacterData::PokedexIndex]          = []
  for i in 0...numRegions+1     # National Dex isn't a region, but is included
    info[PBCharacterData::PokedexIndex][i]    = 0
    info[PBCharacterData::PokedexUnlocked][i] = (i==0)
  end
  info[PBCharacterData::PokedexMode]           = 0
  info[PBCharacterData::VisitedMaps]           = []
  info[PBCharacterData::Partner]               = nil
  info[PBCharacterData::PhoneNumbers]          = []
  info[PBCharacterData::PhoneTime]             = 0
  info[PBCharacterData::DependentEvents]       = nil
  info[PBCharacterData::PokeradarBattery]      = 0
  info[PBCharacterData::PurifyChamber]         = nil
  info[PBCharacterData::SeenPurifyChamber]     = false
  info[PBCharacterData::Triads]                = nil
  info[PBCharacterData::TrainerRecording]      = nil
  info[PBCharacterData::MapID]                 = -1
  info[PBCharacterData::X]                     = -1
  info[PBCharacterData::Y]                     = -1
  info[PBCharacterData::Direction]             = -1
  info[PBCharacterData::Bicycle]               = false
  info[PBCharacterData::Surfing]               = false
  info[PBCharacterData::Diving]                = false
  info[PBCharacterData::Repel]                 = 0
  info[PBCharacterData::FlashUsed]             = false
  info[PBCharacterData::Bridge]                = 0
  info[PBCharacterData::HealingSpot]           = nil
  info[PBCharacterData::EscapePoint]           = []
  info[PBCharacterData::PokecenterMapID]       = -1
  info[PBCharacterData::PokecenterX]           = -1
  info[PBCharacterData::PokecenterY]           = -1
  info[PBCharacterData::PokecenterDirection]   = -1
  info[PBCharacterData::LastBattle]            = nil
  info[PBCharacterData::MapTrail]              = []
  if defined?(Following_Activated_Switch)
    info[PBCharacterData::Following_Activated_Switch] = false
    info[PBCharacterData::Toggle_Following_Switch] = false
    info[PBCharacterData::Current_Following_Variable] = 0
    info[PBCharacterData::ItemWalk] = 0
    info[PBCharacterData::Walking_Time_Variable] = 0
    info[PBCharacterData::Walking_Item_Variable] = 0
  end
  return info
end

# Returns a trainer ID different from all other trainer IDs.
# Prevents two characters from accidentally having same trainer IDs on their
# trainer cards.
def pbGetForeignCharacterID
  characterIDs = []
  for i in 0...$PokemonGlobal.mainCharacters.length
    if $PokemonGlobal.mainCharacters[i] != nil
      characterIDs.push($PokemonGlobal.mainCharacters[i][PBCharacterData::Trainer].id)
    end
  end
  id = $Trainer.getForeignID
  while characterIDs.include?(id)
    id = $Trainer.getForeignID
  end
  return id
end

# Substitutes \PN0-\PN7 with the appropriate trainer name
def gsubPN(name)
  global = $PokemonGlobal
  if !global
    savefile = RTP.getSaveFileName("Game.rxdata")
    return if !safeExists?(savefile)
    File.open(savefile){|f|
          Marshal.load(f) # Trainer already loaded
          Marshal.load(f) # Graphics.frame_count
          Marshal.load(f) # $game_system
          Marshal.load(f) # PokemonSystem already loaded
          Marshal.load(f) # Current map id no longer needed
          Marshal.load(f) # $game_switches
          Marshal.load(f) # $game_variables
          Marshal.load(f) # $game_self_switches
          Marshal.load(f) # $game_screen
          Marshal.load(f) # $MapFactory
          Marshal.load(f) # $game_player
          global=Marshal.load(f) # $PokemonGlobal
    }
  end
  for i in 0..7
    if global.mainCharacters[i]
      name.gsub!(/\\[Pp][Nn]#{i}/, global.mainCharacters[i][PBCharacterData::Trainer].name)
    end
  end
end

# Clones and returns character trainer and party if given character id and
# "PROTAG" as trainer name, otherwise loads trainer data normally
alias reg_pbLoadTrainer pbLoadTrainer
def pbLoadTrainer(trainerid,trainername,partyid=0)
  if trainername=="PROTAG" && trainerid >= 0 && trainerid < 8 &&
        $PokemonGlobal.mainCharacters[trainerid]
    original = (trainerid == $PokemonGlobal.playerID) ? $Trainer : getTrainerFromCharacter(trainerid)
    cloned = Marshal.load(Marshal.dump(original))
    return [cloned, [], cloned.party, _I("...")]
  else
    return reg_pbLoadTrainer(trainerid,trainername,partyid)
  end
end

# Gets PokeBattle_Trainer object at specific character ID
def getTrainerFromCharacter(id)
  return nil if id < 0 || id >= 8
  if id == $Trainer.metaID
    return $Trainer
  else
    meta = $PokemonGlobal.mainCharacters[id]
    return nil if !meta
    return meta[PBCharacterData::Trainer]
  end
end

# Returns true if id is within range 0..7 and meta exists
def characterIDValid?(id)
  return id >= 0 && id < 8 && $PokemonGlobal.mainCharacters[id]
end

# Same as pbChoosePokemon but for another character (EXCLUDING the current character)
def pbChoosePokemonFromCharacter(id,variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
  return if !characterIDValid?(id) || id == $Trainer.metaID
  ot = $Trainer
  $Trainer = getTrainerFromCharacter(id) # Partial switch to new character
  pbChoosePokemon(variableNumber,nameVarNumber,ableProc,allowIneligible)
  $Trainer = ot # Restore original character
end

# Same as pbChooseTradablePokemon but for another character (EXCLUDING the current character)
def pbChooseTradablePokemonFromCharacter(id,variableNumber,nameVarNumber,ableProc=nil,allowIneligible=false)
  return if !characterIDValid?(id) || id == $Trainer.metaID
  ot = $Trainer
  $Trainer = getTrainerFromCharacter(id) # Partial switch to new character
  pbChooseTradablePokemon(variableNumber,nameVarNumber,ableProc,allowIneligible)
  $Trainer = ot # Restore original character
end

# Trade with another character (just like NPC trade)
def pbTradeWithCharacter(id, firstPokemonIndex, secondPokemonIndex)
  return if !characterIDValid?(id) || id == $Trainer.metaID
  firsttrainer = $Trainer
  firstpoke = firsttrainer.party[firstPokemonIndex]
  secondtrainer = getTrainerFromCharacter(id)
  secondpoke = secondtrainer.party[secondPokemonIndex]
  # secondtrainer will have firstpoke
  firstpoke.obtainMode=2 # traded
  secondtrainer.seen[firstpoke.species]=true
  secondtrainer.owned[firstpoke.species]=true
  $Trainer = secondtrainer # Temporarily set to secondtrainer
  pbSeenForm(firstpoke)
  $Trainer = firsttrainer # Set back to firsttrainer
  # firsttrainer will have secondpoke
  secondpoke.obtainMode=2 # traded
  $Trainer.seen[secondpoke.species]=true
  $Trainer.owned[secondpoke.species]=true
  pbSeenForm(secondpoke)
  # Start trade animation
  pbFadeOutInWithMusic(99999){
    evo=PokemonTrade_Scene.new
    evo.pbStartScreen(firstpoke,secondpoke,firsttrainer.name,secondtrainer.name)
    evo.pbTrade
    evo.pbEndScreen
    newspecies=pbTradeCheckEvolution(firstpoke,secondpoke)
    if newspecies>0
      evo=PokemonEvolutionScene.new
      evo.pbStartScreen(firstpoke,newspecies)
      evo.pbEvolution(false)
      evo.pbEndScreen
    end
  }
  # Swap Pokemon
  $Trainer.party[firstPokemonIndex] = secondpoke
  secondtrainer.party[secondPokemonIndex] = firstpoke
  $PokemonTemp.dependentEvents.refresh_sprite if defined?(Following_Activated_Switch)
end

# Send Pokemon to another character
def pbSendToCharacter(id, pokemonIndex)
  return false if !characterIDValid?(id) || id == $Trainer.metaID
  if $Trainer.party.length == 1
    pbMessage(_INTL("You can't send your last Pokemon away!"))
    return false
  end
  secondstorage = $PokemonGlobal.mainCharacters[id][PBCharacterData::PokemonStorage]
  firsttrainer = $Trainer
  secondtrainer = getTrainerFromCharacter(id)
  if secondtrainer.party.length == 6 && secondstorage.full?
    pbMessage(_INTL("#{secondtrainer.name} has no space available!"))
    return false
  end
  pokemon = $Trainer.party[pokemonIndex]
  pokemon.obtainMode=2 # traded
  secondtrainer.seen[pokemon.species]  = true
  secondtrainer.owned[pokemon.species] = true
  $Trainer = secondtrainer # Temporary for pbSeenForm
  pbSeenForm(pokemon)
  $Trainer = firsttrainer
  if secondtrainer.party.length < 6
    secondtrainer.party[secondtrainer.party.length] = pokemon
  else
    secondstorage.pbStoreCaught(pokemon)
  end
  $Trainer.party.delete_at(pokemonIndex)
  $PokemonTemp.dependentEvents.refresh_sprite if defined?(Following_Activated_Switch)
  return true
end