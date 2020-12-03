################################################################################
# Nuzlocke Permadeath v2.1
# by NettoHikari
# 
# September 4, 2020
# 
# This script allows the developer to enable a Nuzlocke-style permadeath for
# Pokemon battles, where any Pokemon that faints is immediately removed from the
# player's party. The difference between this and other Nuzlocke scripts is that
# Pokemon get removed DURING battle instead of after.
# 
# Credits MUST BE GIVEN to NettoHikari
# You should also credit the authors of Pokemon Essentials itself.
# 
#-------------------------------------------------------------------------------
# INSTALLATION
#-------------------------------------------------------------------------------
# Copy this script, place it somewhere between "Compiler" and "Main" in the
# script sections, and name it "Nuzlocke Permadeath".
# 
# There are also two sections that you need to add to the script section
# Scene_Commands, which are listed below:
# 
=begin

  1. Around line 173:
      
      # Find this section
      idxPartyRet = -1
      partyPos.each_with_index do |pos,i|
        next if pos!=idxParty+partyStart
        idxPartyRet = i
        break
      end
      # Add the 3 lines below
      if @battle
        idxPartyRet = @battle.permadeath_fixPartyIndex(idxPartyRet, idxParty)
      end
      
  
  2. Around line 270:
  
      # Find this section
      idxPartyRet = -1
      partyPos.each_with_index do |pos,i|
        next if pos!=idxParty+partyStart
        idxPartyRet = i
        break
      end
      # Add the 3 lines below
      if @battle
        idxPartyRet = @battle.permadeath_fixPartyIndex(idxPartyRet, idxParty)
      end

=end
# 
# Before using this script, make sure to start a new save file when testing.
# Since it adds new stored data, the script will probably throw errors when used
# with saves where the script wasn't present before. In addition, if you decide
# to release your game in segments, it is important to have this script
# installed in the very first version itself, so as not to cause any problems to
# the player.
# 
#-------------------------------------------------------------------------------
# SCRIPT USAGE
#-------------------------------------------------------------------------------
# This script offers two types of permadeath modes: SOFT and NUZLOCKE. In SOFT
# mode, any Pokemon that faint are sent to the Pokemon Storage after the battle,
# while in NUZLOCKE mode, they are lost forever (except for their held items).
# To switch between permadeath modes, call "pbSetPermadeath(mode)" at the start
# of your game (it is set to NORMAL by default at the beginning), replacing
# "mode" with one of three modes: :NORMAL, :SOFT, or :NUZLOCKE. For example,
# to enable the standard permadeath mode, use:
# 
# pbSetPermadeath(:NUZLOCKE)
# 
# and to disable it, use:
# 
# pbSetPermadeath(:NORMAL)
# 
# These can be called at anytime throughout your game, so for example, you can
# change modes for specific event battles. To find out if the current permadeath
# mode is either SOFT or NUZLOCKE use the function "pbPermadeathActive?". To
# find out if a specific mode is enabled, use the function
# "pbPermadeathModeIs?(mode)", replacing "mode" with what you're checking for.
# 
# I highly suggest reading the "Additional Notes" section below for more
# information on what the script does.
# 
#-------------------------------------------------------------------------------
# ADDITIONAL NOTES
#-------------------------------------------------------------------------------
# - On the outside, every time a Pokemon faints in SOFT or NUZLOCKE mode, it
#   LOOKS like it's been removed from the party immediately. However, what
#   happens internally is that all fainted Pokemon are hidden from the player's
#   view until the end of the round (so technically, they are still part of the
#   player's party). Then, at the end of each round, the player's party is
#   swept for fainted Pokemon, and they are removed and placed into another
#   list called "@faintedlist" (defined in PokeBattle_Battle below). Think of
#   this list as a sort of "purgatory", meaning that the Pokemon here still
#   exist as long as the battle is active, just not in the main party.
# - At the very end of the battle in SOFT mode, @faintedlist is swept and all
#   Pokemon in it are stored in the Pokemon Storage (unless the storage is full,
#   in which case they are simply lost like NUZLOCKE mode).
# - Any battles marked as "can lose", meaning that the game will continue
#   even if the player loses the battle, automatically have NORMAL mode on.
# - When a Pokemon dies in NUZLOCKE mode, it drops its held item into the
#   player's bag.
# - Pokemon can die from fainting in field due to poison if both NUZLOCKE and
#   POISON_IN_FIELD are enabled. For SOFT mode, the Pokemon get stored in the
#   Pokemon Storage.
# - When the player loses a battle in NUZLOCKE mode, meaning that the trainer's
#   entire party is dead, the game simply returns to the title screen with a
#   "GAME OVER" screen, going back to the player's last save.
# 
#-------------------------------------------------------------------------------
# I hope you enjoy this script!
# - NettoHikari
################################################################################

PluginManager.register({
  :name => "Nuzlocke Permadeath",
  :version => "v2.1",
  :credits => ["NettoHikari"],
  :link => "https://reliccastle.com/resources/309/"
})

module PBPermadeath
  NORMAL   = 0 # Standard mode
  SOFT     = 1 # "Soft" nuzlocke (fainted Pokemon get transferred to Pokemon Storage)
  NUZLOCKE = 2 # "Hard" nuzlocke (fainted Pokemon get deleted at the end of battle)
end

class PokemonGlobalMetadata
  # Sets battles to NORMAL, SOFT, or NUZLOCKE
  attr_accessor :permadeathmode
  
  alias permadeath_initialize initialize
  def initialize
    permadeath_initialize
    @permadeathmode = PBPermadeath::NORMAL
  end
end

def pbSetPermadeath(mode)
  if mode.is_a?(Symbol)
    mode = getConst(PBPermadeath, mode)
  end
  return if mode < 0 || mode > 2
  $PokemonGlobal.permadeathmode = mode
end

def pbPermadeathModeIs?(mode)
  if mode.is_a?(Symbol)
    mode = getConst(PBPermadeath, mode)
  end
  return $PokemonGlobal.permadeathmode == mode
end

def pbPermadeathActive?
  return !pbPermadeathModeIs?(:NORMAL)
end

class PokeBattle_Battle
  # Stores fainted Pokemon until end of battle (like a "purgatory")
  attr_accessor :faintedlist
  
  alias permadeath_pbStartBattle pbStartBattle
  def pbStartBattle
    @faintedlist = []
    permadeath_pbStartBattle
  end
  
  alias permadeath_pbReplace pbReplace
  def pbReplace(idxBattler,idxParty,batonPass=false)
    idxPartyOld = @battlers[idxBattler].pokemonIndex
    partyOrder = pbPartyOrder(idxBattler)
    permadeath_pbReplace(idxBattler,idxParty,batonPass)
    # Party order is already changed in original pbReplace, so undo party order change here
    if pbPermadeathBattle? && pbOwnedByPlayer?(idxBattler) &&
          idxPartyOld < $Trainer.party.length && $Trainer.party[idxPartyOld].fainted?
      partyOrder[idxParty],partyOrder[idxPartyOld] = partyOrder[idxPartyOld],partyOrder[idxParty]
    end
  end
  
  alias permadeath_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    # Cancel effect of Future Sight from dead Pokemon
    if pbPermadeathBattle?
      @positions.each_with_index do |pos,idxPos|
        next if !pos || !@battlers[idxPos] || @battlers[idxPos].fainted?
        next if pos.effects[PBEffects::FutureSightUserIndex] < 0
        next if @battlers[pos.effects[PBEffects::FutureSightUserIndex]].opposes?
        attacker = @party1[pos.effects[PBEffects::FutureSightUserPartyIndex]]
        if attacker.fainted?
          pos.effects[PBEffects::FutureSightCounter]        = 0
          pos.effects[PBEffects::FutureSightMove]           = 0
          pos.effects[PBEffects::FutureSightUserIndex]      = -1
          pos.effects[PBEffects::FutureSightUserPartyIndex] = -1
        end
      end
    end
    permadeath_pbEndOfRoundPhase
    pbRemoveFainted
  end
  
  alias permadeath_pbEndOfBattle pbEndOfBattle
  def pbEndOfBattle
    pbRemoveFainted
    permadeath_pbEndOfBattle
    if pbPermadeathBattle? && pbPermadeathModeIs?(:SOFT)
      for i in @faintedlist
        storedbox = $PokemonStorage.pbStoreCaught(i)
      end
    end
  end
  
  def pbPermadeathBattle?
    return pbPermadeathActive? && !@canLose
  end
  
  def pbRemoveFainted
    return if !pbPermadeathBattle?
    pokeindex = 0
    # Loop through Trainer's party
    loop do
      break if pokeindex >= $Trainer.party.length
      if @party1[pokeindex] && @party1[pokeindex].fainted?
        break if $Trainer.party.length == 1 && pbPermadeathModeIs?(:SOFT)
        # Begin by deleting Pokemon from party entirely
        @faintedlist.push($Trainer.party[pokeindex])
        $Trainer.party.delete_at(pokeindex)
        $PokemonTemp.evolutionLevels.delete_at(pokeindex)
        $PokemonTemp.heartgauges.delete_at(pokeindex) if $PokemonTemp.heartgauges
        @initialItems[0].delete_at(pokeindex)
        @recycleItems[0].delete_at(pokeindex)
        @belch[0].delete_at(pokeindex)
        @battleBond[0].delete_at(pokeindex)
        @usedInBattle[0].delete_at(pokeindex)
        # Remove from double battle party as well
        if @party1 != $Trainer.party
          @party1.delete_at(pokeindex)
        end
        # Fix party order
        @party1order.delete(pokeindex)
        for i in 0...$Trainer.party.length
          if @party1order[i] > pokeindex
            @party1order[i] -= 1
          end
        end
        # Fix party starts
        for i in 1...@party1starts.length
          @party1starts[i] -= 1
        end
        # Fix party positions of current battlers
        eachSameSideBattler do |b|
          next if !b
          if b.pokemonIndex == pokeindex
            b.pokemonIndex = $Trainer.party.length
          elsif b.pokemonIndex > pokeindex
            b.pokemonIndex -= 1
          end
        end
        # Fix participants for exp gains
        eachOtherSideBattler do |b|
          next if !b
          participants = b.participants
          for j in 0...participants.length
            next if !participants[j]
            participants[j] -= 1 if participants[j] > pokeindex
          end
        end
        pokeindex -= 1
      end
      pokeindex += 1
    end
    # End battle if player's entire party is gone
    # CHANGED: Checks if Z-Transform still possible
    @decision = 2 if $Trainer.ablePokemonCount == 0 && !pbCanTransformInBattle?
  end
  
  alias permadeath_pbPlayerDisplayParty pbPlayerDisplayParty
  def pbPlayerDisplayParty(idxBattler=0)
    if pbPermadeathBattle? && pbOwnedByPlayer?(idxBattler)
      partyOrders = pbPartyOrder(idxBattler)
      idxStart, idxEnd = pbTeamIndexRangeFromBattlerIndex(idxBattler)
      ret = []
      eachInTeamFromBattlerIndex(idxBattler) { |pkmn,i|
        ret[partyOrders[i]-idxStart] = pkmn if partyOrders[i] && pkmn && !pkmn.fainted?
      }
      ret.compact!
      return ret
    else
      return permadeath_pbPlayerDisplayParty(idxBattler)
    end
  end
  
  def permadeath_fixPartyIndex(idxPartyRet, idxParty)
    if pbPermadeathBattle?
      modParty = pbPlayerDisplayParty
      idxPartyRet = @party1.index(modParty[idxParty])
    end
    return idxPartyRet
  end
end

class PokeBattle_Battler
  alias permadeath_pbFaint pbFaint
  def pbFaint(showMessage=true)
    return true if @fainted || !fainted?
    ret = permadeath_pbFaint(showMessage)
    if @battle.pbPermadeathBattle? && pbOwnedByPlayer?
      if showMessage && pbPermadeathModeIs?(:NUZLOCKE)
        if @pokemon.hasItem?
          # Informs player that fainted's held item was transferred to bag
          @battle.pbDisplayPaused(_INTL("{1} is dead! You picked up its {2}.",
              pbThis, PBItems.getName(@pokemon.item)))
        else
          @battle.pbDisplayPaused(_INTL("{1} is dead!",pbThis))
        end
      end
      # Remove fainted from opposing participants arrays
      indices = @battle.pbGetOpposingIndicesInOrder(@index)
      for i in indices
        @battle.battlers[i].participants.delete(@pokemonIndex)
      end
      # Add held item to bag
      if @pokemon.hasItem? && pbPermadeathModeIs?(:NUZLOCKE)
        $PokemonBag.pbStoreItem(@pokemon.item)
      end
    end
    return ret
  end
end

# Removes Pokemon fainted by poison
Events.onStepTakenTransferPossible+=proc {|sender,e|
  if $PokemonGlobal.stepcount%4==0 && POISON_IN_FIELD
    $Trainer.party.delete_if{|poke|
      if pbPermadeathActive? && poke.fainted?
        if pbPermadeathModeIs?(:SOFT)
          $PokemonStorage.pbStoreCaught(poke)
        else
          if poke.hasItem?
            # Informs player that fainted's held item was transferred to bag
            pbMessage(_INTL("{1} is dead... You picked up its {2}.",
                poke.name, PBItems.getName(poke.item)))
          else
            pbMessage(_INTL("{1} is dead...",poke.name))
          end
          $PokemonBag.pbStoreItem(poke.item) if poke.hasItem?
        end
        true
      end
    }
  end
}

# CHANGED: Commented this out, already have a version of pbStartOver
=begin

# Sends player back to title screen if all Pokemon lost
alias permadeath_pbStartOver pbStartOver
def pbStartOver(gameover=false)
  if pbPermadeathModeIs?(:NUZLOCKE)
    if pbInBugContest?
      pbBugContestStartOver
      return
    end
    pbMessage(_INTL("\\w[]\\wm\\c[8]\\l[3]GAME OVER!"))
    pbCancelVehicles
    pbRemoveDependencies
    $game_temp.to_title = true
  else
    permadeath_pbStartOver(gameover)
  end
end

=end