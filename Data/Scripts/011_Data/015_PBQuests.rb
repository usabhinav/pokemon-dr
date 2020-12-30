# CHANGED: Script section to handle internal data for quests/missions
class Quest
  attr_accessor :id
  attr_accessor :currentStage
  attr_accessor :currentObjectives
  attr_accessor :completed
  
  def initialize(id)
    @id = id
    @currentStage = 1
    # Populates array with all zeroes
    @currentObjectives = Array.new(PBQuests.getNumStageObjectives(id, 1), 0)
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

  def objectivesData
    return PBQuests.getStageObjectives(@id, @currentStage)
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

  def PBQuests.getNumStages(id)
    stages = PBQuests.getStages(id)
    return stages.length
  end
  
  def PBQuests.getRank(id)
    data = pbLoadQuestsData
    return data[id - 1][4]
  end

  def PBQuests.getMain(id)
    data = pbLoadQuestsData
    return data[id - 1][5]
  end

  def PBQuests.getStageDescription(id, stage)
    stages = PBQuests.getStages(id)
    return stages[stage - 1][0]
  end

  def PBQuests.getStageLocation(id, stage)
    stages = PBQuests.getStages(id)
    return stages[stage - 1][1]
  end

  def PBQuests.getStageObjectives(id, stage)
    stages = PBQuests.getStages(id)
    return stages[stage - 1][2]
  end

  def PBQuests.getNumStageObjectives(id, stage)
    objectives = PBQuests.getStageObjectives(id, stage)
    return objectives.length
  end

  def PBQuests.getStageObjectiveDescription(id, stage, objective)
    objectives = PBQuests.getStageObjectives(id, stage)
    return objectives[objective - 1][0]
  end

  def PBQuests.getStageObjectiveCount(id, stage, objective)
    objectives = PBQuests.getStageObjectives(id, stage)
    return objectives[objective - 1][1]
  end

  def PBQuests.getStageObjectiveOptional(id, stage, objective)
    objectives = PBQuests.getStageObjectives(id, stage)
    return objectives[objective - 1][2]
  end
end

def pbHasCompletedQuest?(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  for q in $Trainer.completedQuests
    return true if q.id == id
  end
  return false
end

def pbHasActiveQuest?(id)
  quest = pbGetActiveQuest(id)
  return !quest.nil?
end

def pbHasCompletedStageNum?(id, stageNum)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  return true if pbHasCompletedQuest?(id)
  currentNum = pbGetStageNum(id)
  if currentNum
    return currentNum > stageNum
  end
  return false
end

def pbGetActiveQuest(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  for q in $Trainer.activeQuests
    return q if q.id == id
  end
  return nil
end

def pbActivateQuest(id)
  return if pbHasActiveQuest?(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = Quest.new(id)
  $Trainer.activeQuests.push(quest)
  pbMessage(_INTL("Received {1} {2}!", $PokemonGlobal.playerID==0 ? "mission" : "quest", quest.name))
  $PokemonTemp.hud.updateWaypoint
end

def pbActivateQuestSilent(id)
  return if pbHasActiveQuest?(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = Quest.new(id)
  $Trainer.activeQuests.push(quest)
  $PokemonTemp.hud.updateWaypoint
end

def pbAdvanceQuest(id, stage, objective = 1)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  if quest
    if stage != quest.currentStage
      raise _INTL("Trying to advance stage {1} when player is on stage {2}. Please make sure that your event is advancing the correct stage, and that the player will have reached the correct stage upon triggering your event.\n", stage, quest.currentStage)
    end
    quest.currentObjectives[objective - 1] += 1
    if pbQuestStageComplete?(quest.id, quest.currentStage)
      quest.currentStage += 1
      if quest.currentStage > PBQuests.getNumStages(quest.id)
        pbCompleteQuest(quest.id)
      else
        quest.currentObjectives = Array.new(PBQuests.getNumStageObjectives(quest.id, quest.currentStage), 0)
      end
    end
    $PokemonTemp.hud.updateWaypoint
  end
end

def pbCompleteQuest(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  if quest
    quest.completed = true
    $Trainer.completedQuests.push($Trainer.activeQuests.delete(quest))
    pbMessage(_INTL("Completed {1} {2}!", $PokemonGlobal.playerID==0 ? "mission" : "quest", quest.name))
    $PokemonTemp.hud.clearWaypoint
    if $PokemonGlobal.playerID == 0 && PBQuests.getMain(id) && $Trainer.completedQuests.length % 10 == 0
      pbRankup
    end
  end
end

def pbGetStageNum(id)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  return quest.currentStage if quest
  return nil
end

def pbQuestStageComplete?(id, stage)
  id = getConst(PBQuests, id) if id.is_a?(Symbol)
  quest = pbGetActiveQuest(id)
  return false if !quest
  for i in 0...quest.currentObjectives.length
    return false if !PBQuests.getStageObjectiveOptional(quest.id, stage, i + 1) && quest.currentObjectives[i] < PBQuests.getStageObjectiveCount(quest.id, stage, i + 1)
  end
  return true
end