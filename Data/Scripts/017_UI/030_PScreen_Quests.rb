# CHANGED: Script section to handle quests screen

def pbQuestsScreen
  questmenu = []
  cActive = -1
  cCompleted = -1
  cCancel = -1
  questmenu[cActive = questmenu.length] = _INTL("Active") if $Trainer.activeQuests.length > 0
  questmenu[cCompleted = questmenu.length] = _INTL("Completed") if $Trainer.completedQuests.length > 0
  questmenu[cCancel = questmenu.length] = _INTL("Cancel")
  loop do
    c = pbShowCommands(nil, questmenu, questmenu.length)
    if cActive >= 0 && c == cActive
      quests = []
      for q in $Trainer.activeQuests
        quests.push(q.name)
      end
      quests.push("Back")
      loop do
        co = pbShowCommands(nil, quests, quests.length)
        if co < quests.length - 1
          q = $Trainer.activeQuests[co]
          stagemsg = PBQuests.getStageDescription(q.id, q.currentStage)
          pbMessage(_INTL(stagemsg))
          for i in 0...q.currentObjectives.length
            objectivemsg = PBQuests.getStageObjectiveDescription(q.id, q.currentStage, i + 1)
            currentcount = q.currentObjectives[i]
            objectivecount = PBQuests.getStageObjectiveCount(q.id, q.currentStage, i + 1)
            pbMessage(_INTL(objectivemsg + " (#{currentcount} / #{objectivecount})"))
          end
        else
          break
        end
      end
    elsif cCompleted >= 0 && c == cCompleted
      quests = []
      for q in $Trainer.completedQuests
        quests.push(q.name)
      end
      quests.push("Back")
      loop do
        co = pbShowCommands(nil, quests, quests.length)
        if co < quests.length - 1
          q = $Trainer.completedQuests[co]
          pbMessage(_INTL(q.completedMessage))
        else
          break
        end
      end
    else
      break
    end
  end
end