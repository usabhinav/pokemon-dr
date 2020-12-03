# CHANGED: Script section to handle internal data for quests/missions
class Quest
  attr_accessor :id
  attr_accessor :currentStage
  attr_accessor :currentStageCount
  attr_accessor :completed
  
  def initialize(id)
    @id = id
    @currentStage = 1
    @currentStageCount = 0
    @completed = false
  end

  def name
    return PBQuests.getName(@id)
  end

  def summary
    return PBQuests.getSummary(@id)
  end

  def completedMessage
    return PBQuests.getCompleted(@id)
  end

  def stages
    return PBQuests.getStages(@id)
  end
end

module PBQuests
  def PBQuests.getName(id)
    data = pbLoadQuestsData
    return data[id - 1][0]
  end
  
  def PBQuests.getSummary(id)
    data = pbLoadQuestsData
    return data[id - 1][1]
  end

  def PBQuests.getCompleted(id)
    data = pbLoadQuestsData
    return data[id - 1][2]
  end
  
  def PBQuests.getStages(id)
    data = pbLoadQuestsData
    return data[id - 1][3]
  end
  
  def PBQuests.getRank(id)
    data = pbLoadQuestsData
    return data[id - 1][4]
  end

  def PBQuests.getStageDescription(id, stage)
    stages = PBQuests.getStages(id)
    return stages[stage - 1][0]
  end

  def PBQuests.getStageLocation(id, stage)
    stages = PBQuests.getStages(id)
    return stages[stage - 1][1]
  end

  def PBQuests.getStageCount(id, stage)
    stages = PBQuests.getStages(id)
    return stages[stage - 1][2]
  end
  
  def PBQuests.getNumStages(id)
    stages = PBQuests.getStages(id)
    return stages.length
  end
end

def pbHasActiveQuest?(id)
  quest = pbGetActiveQuest(id)
  return !quest.nil?
end

def pbGetActiveQuest(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = nil
  for q in $Trainer.activeQuests
    quest = q if q.id == id
  end
  return quest
end

def pbActivateQuest(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = Quest.new(id)
  $Trainer.activeQuests.push(quest)
  pbMessage(_INTL("Received quest {1}!", quest.name))
end

def pbAdvanceQuest(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  if quest
    quest.currentStageCount += 1
    if quest.currentStageCount >= PBQuests.getStageCount(quest.id, quest.currentStage)
      quest.currentStage += 1
      quest.currentStageCount = 0
      if quest.currentStage > PBQuests.getNumStages(quest.id)
        quest.completed = true
        $Trainer.completedQuests.push($Trainer.activeQuests.delete(quest))
        pbMessage(_INTL("Completed quest {1}!", quest.name))
      end
    end
  end
end

def pbCompleteQuest(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  if quest
    quest.completed = true
    $Trainer.completedQuests.push($Trainer.activeQuests.delete(quest))
    pbMessage(_INTL("Completed quest {1}!", quest.name))
  end
end

def pbGetStageNum(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  return quest.currentStage if quest
end