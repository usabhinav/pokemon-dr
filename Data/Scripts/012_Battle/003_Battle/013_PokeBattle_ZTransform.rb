# CHANGED: Z-Transformation Functions

class PokeBattle_Battle
  def pbCanTransformInBattle?
    for i in @party1
      return false if i && i.species==PBSpecies::ZYGARDE
    end
    return pbCanTransform?
  end
  
  def pbCanStillFight?
    return !pbAllFainted? || pbCanTransformInBattle?
  end
  
  def pbFaintAll
    for i in 0...$Trainer.party.length
      $Trainer.party[i].hp=0 if $Trainer.party[i]
      eachSameSideBattler do |b|
        b.pbFaint if b.pokemonIndex == i
      end
    end
  end
  
  def pbRestartIfKilled(index, hp, species)
    if pbOwnedByPlayer?(index) && hp <= 0 && !@canLose && pbGamemode >= 3
      if species == PBSpecies::ZYGARDE
        pbRestartSave
      elsif !pbCanStillFight?
        pbRestartSave
      end
    end
  end
  
  def pbTransform
    if pbCanTransformInBattle?
      poke = $Trainer.zygarde
      @party1order.insert($Trainer.party.length, $Trainer.party.length)
      @party1.insert($Trainer.party.length, poke)
      for i in 1...@party1starts.length
        @party1starts[i] += 1
      end
      if @party1 != $Trainer.party
        $Trainer.party.insert($Trainer.party.length, poke)  
      end
      pbTransformSendOut
      eachOtherSideBattler do |b|
        b.pbUpdateParticipants
      end
      if !pbPlayer.hasOwned?(PBSpecies::ZYGARDE)
        pbPlayer.setOwned(PBSpecies::ZYGARDE)
      end
    elsif $game_switches[Z_TRANSFORM_SWITCH]
      pbDisplay(_INTL("You can't transform right now!"))
    end
  end
  
  def pbTransformSendOut
    pbDisplay(_INTL("From deep within, you feel yourself transforming."))
    idxBattler = 0
    for b in @battlers
      next if !b
      if (b.fainted? || b.pokemon == $Trainer.zygarde) && pbOwnedByPlayer?(b.index)
        idxBattler = b.index
        break
      end
    end
    if @battlers[idxBattler].fainted?
      pbReplace(idxBattler, $Trainer.party.length - 1)
    elsif @battlers[idxBattler].pokemon != $Trainer.zygarde
      pbRecallAndReplace(idxBattler, $Trainer.party.length - 1)
    end
  end
end