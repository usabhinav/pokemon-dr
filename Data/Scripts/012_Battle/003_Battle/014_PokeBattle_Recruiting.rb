# CHANGED: Recruiting Functions

class PokeBattle_Battle
  def pbRecruit
    recruitCommandList = [
      _INTL("You're going to join me. (Stern)"),
      _INTL("You won't be weak with me. (Stern)"),
      _INTL("You can trust me. (Nice)"),
      _INTL("Let's be friends! (Nice)")]
    recruitCmd = pbShowCommands(_INTL("What will you say to the Pokemon?"), recruitCommandList, 4)
    battlerLevel = @battlers[1].level
    if recruitCmd >= 4 || recruitCmd < 0
      return false
    end
    pbDisplayBrief(_INTL("{1}: {2}", $Trainer.name, recruitCommandList[recruitCmd]))
    waitMsg = ".   "
    for i in 0..2
      pbDisplayBrief(waitMsg)
      waitMsg += ".   "
    end
    if recruitCmd == 0 || recruitCmd == 1
      if battlerLevel >= 40
        if rand(100) < pbRecruitChance
          pbRecruitSuccess
        else
          pbRecruitFail
        end
      else
        pbRecruitFail
      end
    elsif recruitCmd == 2 || recruitCmd == 3
      if battlerLevel < 40
        if rand(100) < pbRecruitChance
          pbRecruitSuccess
        else
          pbRecruitFail
        end
      else
        pbRecruitFail
      end
    end
    return true
  end
  
  # Stolen code from def pbThrowPokeBall
  def pbRecruitSuccess
    battler = @battlers[1]
    pkmn = battler.pokemon
    pbDisplayBrief(_INTL("Yes! {1} was recruited!",pkmn.name))
    @scene.pbThrowSuccess   # Play capture success jingle
    pbRemoveFromParty(battler.index,battler.pokemonIndex)
    battler.pbReset
    @decision = 4 if pbAllFainted?(battler.index)   # Battle ended by capture
    pkmn.makeUnmega if pkmn.mega?
    pkmn.makeUnprimal
    pkmn.pbUpdateShadowMoves if pkmn.shadowPokemon?
    pkmn.pbRecordFirstMoves
    # Gain Exp
    if GAIN_EXP_FOR_CAPTURE
      battler.captured = true
      pbGainExp
      battler.captured = false
    end
    # Reset form
    pkmn.forcedForm = nil if MultipleForms.hasFunction?(pkmn.species,"getForm")
    @peer.pbOnLeavingBattle(self,pkmn,true,true)
    # Save the Pokémon for storage at the end of battle
    @caughtPokemon.push(pkmn)
  end

  def pbRecruitFail
    battler = @battlers[1]
    pbDisplayBrief(_INTL("{1} became enraged at your words!", battler.name))
    if @recruitChance > 10
      @recruitChance /= 2
    end
    battler.pbRaiseStatStage(PBStats::ATTACK,2,battler)
    battler.pbRaiseStatStage(PBStats::DEFENSE,2,battler)
  end

  def pbRecruitChance
    totalHP = @battlers[1].totalhp
    currentHP = @battlers[1].hp
    chance = ((1 - (currentHP / totalHP)) * @recruitChance) + 1
    if @battlers[1].status != 0
      chance *= 1.15
    end
    return chance
  end
  
  # Nuzlocke exceptions (not Nuzlocke mode, static encounter, or shiny Pokemon)
  # NOTE: Assumes wild battle
  def pbNuzlockeException?
    return true if pbGamemode < 3 || pbMapInterpreterRunning?
    # Look for non-shinies among caught
    @caughtPokemon.each do |poke|
      return false if !poke.shiny?
    end
    # Look for non-shiny foes
    @party2.each do |poke|
      return false if !poke.shiny?
    end
    # All caught Pokemon and foes are shiny, so they are all exceptions
    return true
  end

  # Returns if no Nuzlocke rules prevent player from catching Pokemon
  # NOTE: Assumes wild battle
  def pbNuzlockeCheck
    return pbNuzlockeException? || !$PokemonGlobal.nuzlockeMaps[$game_map.map_id]
  end

  def pbCanRecruit?
    return $Trainer.party.length < 6 && wildBattle? && pbSideSize(1)==1 && @canRecruit && pbNuzlockeCheck
  end
end