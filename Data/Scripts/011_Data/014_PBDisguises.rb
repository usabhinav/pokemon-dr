# CHANGED: Script section to define disguise related methods for Zyree
class PBDisguises
  def PBDisguises.getName(id)
    data = pbLoadDisguiseData
    return data[id][0]
  end
  
  def PBDisguises.getOutfitID(id)
    data = pbLoadDisguiseData
    return data[id][1]
  end
  
  def PBDisguises.getStepCount(id)
    data = pbLoadDisguiseData
    return data[id][2]
  end
  
  def PBDisguises.getDesc(id)
    data = pbLoadDisguiseData
    return data[id][3]
  end
  
  def PBDisguises.isDisguise?(outfit_id)
    data = pbLoadDisguiseData
    data.each{|d| return true if d[1] == outfit_id}
    return false
  end
end

class Disguise
  attr_accessor :id
  attr_accessor :stepcount
  attr_accessor :maxcount
  
  def initialize(id)
    @id = id
    @stepcount = PBDisguises.getStepCount(id)
    @maxcount = @stepcount
  end
  
  def name
    return PBDisguises.getName(@id)
  end
  
  def isBroken?
    return @stepcount <= 0
  end
  
  def outfit_id
    return PBDisguises.getOutfitID(@id)
  end
end

def pbAddDisguise(disguise_id)
  if disguise_id.is_a?(String) || disguise_id.is_a?(Symbol)
    disguise_id = getID(PBDisguises, disguise_id)
  end
  $Trainer.obtainedDisguises.each {|d| return if d.id == disguise_id}
  disguise = Disguise.new(disguise_id)
  $Trainer.obtainedDisguises.push(disguise)
  if ['a','e','i','o','u'].include?((disguise.name)[0,1].downcase)
    pbMessage(_INTL("\\me[Treasure Chest Sound]You found an \\c[1]{1}\\c[0]!\\wtnp[30]",disguise.name))
  else
    pbMessage(_INTL("\\me[Treasure Chest Sound]You found a \\c[1]{1}\\c[0]!\\wtnp[30]",disguise.name))
  end
  pbMessage(_INTL("You stored the \\c[1]{1}\\c[0] away in your disguise stash.", disguise.name))
end

def pbAddDisguiseSilent(disguise_id)
  if disguise_id.is_a?(String) || disguise_id.is_a?(Symbol)
    disguise_id = getID(PBDisguises, disguise_id)
  end
  $Trainer.obtainedDisguises.each {|d| return if d.id == disguise_id}
  disguise = Disguise.new(disguise_id)
  $Trainer.obtainedDisguises.push(disguise)
end

def pbReceiveDisguise(disguise_id)
  if disguise_id.is_a?(String) || disguise_id.is_a?(Symbol)
    disguise_id = getID(PBDisguises, disguise_id)
  end
  $Trainer.obtainedDisguises.each {|d| return if d.id == disguise_id}
  disguise = Disguise.new(disguise_id)
  $Trainer.obtainedDisguises.push(disguise)
  if ['a','e','i','o','u'].include?((disguise.name)[0,1].downcase)
    pbMessage(_INTL("\\me[Item get]You obtained an \\c[1]{1}\\c[0]!\\wtnp[30]",disguise.name))
  else
    pbMessage(_INTL("\\me[Item get]You obtained a \\c[1]{1}\\c[0]!\\wtnp[30]",disguise.name))
  end
  pbMessage(_INTL("You stored the \\c[1]{1}\\c[0] away in your disguise stash.", disguise.name))
end

def pbEquipDisguise(disguise_id, showmessage=true)
  if disguise_id.is_a?(String) || disguise_id.is_a?(Symbol)
    disguise_id = getID(PBDisguises, disguise_id)
  end
  return if $Trainer.equippedDisguise && $Trainer.equippedDisguise.id == disguise_id
  for i in $Trainer.obtainedDisguises
    if i.id == disguise_id
      if i.isBroken?
        pbMessage(_INTL("The \\c[1]{1}\\c[0] is broken!\\wtnp[30]",i.name)) if showmessage
      else
        $Trainer.equippedDisguise = i
        $Trainer.outfit = i.outfit_id
        pbMessage(_INTL("You equipped the \\c[1]{1}\\c[0].\\wtnp[30]",i.name)) if showmessage
        $PokemonTemp.hud.updateDisguiseSteps
        return
      end
    end
  end
end

def pbUnequipDisguise(showmessage=true)
  return if !$Trainer.equippedDisguise
  pbMessage(_INTL("You unequipped the \\c[1]{1}\\c[0].\\wtnp[30]",$Trainer.equippedDisguise.name)) if showmessage
  $Trainer.equippedDisguise = nil
  $Trainer.outfit = 0
  $PokemonTemp.hud.updateDisguiseSteps
end

def pbGetBrokenDisguises
  return if !$Trainer.obtainedDisguises
  broken = []
  for i in $Trainer.obtainedDisguises
    broken.push(i) if i.stepcount < i.maxcount
  end
  return broken
end