class PokemonPauseMenu_Scene
  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].visible = false
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["helpwindow"].visible = false
    @infostate = false
    @helpstate = false
    pbSEPlay("GUI menu open")
  end

  def pbShowInfo(text)
    @sprites["infowindow"].resizeToFit(text,Graphics.height)
    @sprites["infowindow"].text    = text
    @sprites["infowindow"].visible = true
    @infostate = true
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text,Graphics.height)
    @sprites["helpwindow"].text    = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
    @helpstate = true
  end

  def pbShowMenu
    @sprites["cmdwindow"].visible = true
    @sprites["infowindow"].visible = @infostate
    @sprites["helpwindow"].visible = @helpstate
  end

  def pbHideMenu
    @sprites["cmdwindow"].visible = false
    @sprites["infowindow"].visible = false
    @sprites["helpwindow"].visible = false
  end

  def pbShowCommands(commands)
    ret = -1
    cmdwindow = @sprites["cmdwindow"]
    cmdwindow.commands = commands
    cmdwindow.index    = $PokemonTemp.menuLastChoice
    cmdwindow.resizeToFit(commands)
    cmdwindow.x        = Graphics.width-cmdwindow.width
    cmdwindow.y        = 0
    cmdwindow.visible  = true
    loop do
      cmdwindow.update
      Graphics.update
      Input.update
      pbUpdateSceneMap
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        ret = -1
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        ret = cmdwindow.index
        $PokemonTemp.menuLastChoice = ret
        break
      end
    end
    return ret
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbRefresh; end
end



class PokemonPauseMenu
  def initialize(scene)
    @scene = scene
  end

  def pbShowMenu
    @scene.pbRefresh
    @scene.pbShowMenu
  end

  def pbStartPokemonMenu
    if !$Trainer
      if $DEBUG
        pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
        pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
      end
      return
    end
    pbSetViableDexes
    @scene.pbStartScene
    endscene = true
    commands = []
    cmdPokedex  = -1
    cmdPokemon  = -1
    cmdBag      = -1
    cmdTrainer  = -1
    cmdSave     = -1
    cmdOption   = -1
    cmdPokegear = -1
    cmdLucario  = -1 # CHANGED: Added Lucario cmd
    cmdDisguises= -1 # CHANGED: Added Disguises cmd
    cmdGamemode = -1 # CHANGED: Added Gamemode cmd
    cmdQuests   = -1 # CHANGED: Added Quests cmd
    cmdDebug    = -1
    cmdControls = -1 # CHANGED: Set Controls Screen
    cmdQuit     = -1
    cmdEndGame  = -1
    cmdSwitch   = -1 # CHANGED: Multiple Protagonists
    # CHANGED: Changed Pokedex to Journal
    commands[cmdPokedex = commands.length]  = _INTL("Journal") if $Trainer.pokedex && $PokemonGlobal.pokedexViable.length>0
    commands[cmdPokemon = commands.length]  = _INTL("Pokémon") if $Trainer.party.length>0
    commands[cmdBag = commands.length]      = _INTL("Bag") if !pbInBugContest?
    commands[cmdPokegear = commands.length] = _INTL("Pokégear") if $Trainer.pokegear
    # CHANGED: Added Pocket App/Lucario to pause menu
    commands[cmdLucario = commands.length]= _INTL("Lucario") if $Trainer.lucario
    # CHANGED: Added Disguises to pause menu
    commands[cmdDisguises = commands.length]= _INTL("Disguises") if $Trainer.trainertype == 1 && $Trainer.obtainedDisguises.length > 0
    # CHANGED: Added Change Gamemode to pause menu
    commands[cmdGamemode = commands.length] = _INTL("Gamemode") if pbGamemode < 3 # Only below Nuzlocke mode
    # CHANGED: Added Quests to pause menu
    if $Trainer.activeQuests.length > 0 || $Trainer.completedQuests.length > 0
      commands[cmdQuests = commands.length]   = $Trainer.metaID == 1 ? _INTL("Quests") : _INTL("Missions")
    end
    commands[cmdTrainer = commands.length]  = $Trainer.name
    # CHANGED: Multiple Protagonists
    if $PokemonGlobal.commandCharacterSwitchOn && !pbInSafari? &&
          !pbInBugContest? && !pbBattleChallenge.pbInProgress?
      commands[cmdSwitch = commands.length] = _INTL("Switch")
    end
    commands[cmdControls=commands.length]=_INTL("Controls") # CHANGED: Set Controls Screen
    if pbInSafari?
      if SAFARI_STEPS<=0
        @scene.pbShowInfo(_INTL("Balls: {1}",pbSafariState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Steps: {1}/{2}\nBalls: {3}",
           pbSafariState.steps,SAFARI_STEPS,pbSafariState.ballcount))
      end
      commands[cmdQuit = commands.length]   = _INTL("Quit")
    elsif pbInBugContest?
      if pbBugContestState.lastPokemon
        @scene.pbShowInfo(_INTL("Caught: {1}\nLevel: {2}\nBalls: {3}",
           PBSpecies.getName(pbBugContestState.lastPokemon.species),
           pbBugContestState.lastPokemon.level,
           pbBugContestState.ballcount))
      else
        @scene.pbShowInfo(_INTL("Caught: None\nBalls: {1}",pbBugContestState.ballcount))
      end
      commands[cmdQuit = commands.length]   = _INTL("Quit Contest")
    else
      # CHANGED: Don't show save option on certain maps (ex. Green Bay Observatory)
      commands[cmdSave = commands.length]   = _INTL("Save") if $game_system && !$game_system.save_disabled && !SAVE_DISABLED_MAPS.include?($game_map.map_id)
    end
    commands[cmdOption = commands.length]   = _INTL("Options")
    commands[cmdDebug = commands.length]    = _INTL("Debug") if $DEBUG
    commands[cmdEndGame = commands.length]  = _INTL("Quit Game")
    loop do
      command = @scene.pbShowCommands(commands)
      if cmdPokedex>=0 && command==cmdPokedex
        if USE_CURRENT_REGION_DEX
          pbFadeOutIn {
            scene = PokemonPokedex_Scene.new
            screen = PokemonPokedexScreen.new(scene)
            screen.pbStartScreen
            @scene.pbRefresh
          }
        else
          if $PokemonGlobal.pokedexViable.length==1
            $PokemonGlobal.pokedexDex = $PokemonGlobal.pokedexViable[0]
            $PokemonGlobal.pokedexDex = -1 if $PokemonGlobal.pokedexDex==$PokemonGlobal.pokedexUnlocked.length-1
            pbFadeOutIn {
              scene = PokemonPokedex_Scene.new
              screen = PokemonPokedexScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          else
            pbFadeOutIn {
              scene = PokemonPokedexMenu_Scene.new
              screen = PokemonPokedexMenuScreen.new(scene)
              screen.pbStartScreen
              @scene.pbRefresh
            }
          end
        end
      elsif cmdPokemon>=0 && command==cmdPokemon
        hiddenmove = nil
        pbFadeOutIn {
          sscene = PokemonParty_Scene.new
          sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
          hiddenmove = sscreen.pbPokemonScreen
          (hiddenmove) ? @scene.pbEndScene : @scene.pbRefresh
        }
        if hiddenmove
          $game_temp.in_menu = false
          pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
          return
        end
      elsif cmdBag>=0 && command==cmdBag
        item = 0
        pbFadeOutIn {
          scene = PokemonBag_Scene.new
          screen = PokemonBagScreen.new(scene,$PokemonBag)
          item = screen.pbStartScreen
          (item>0) ? @scene.pbEndScene : @scene.pbRefresh
        }
        if item>0
          $game_temp.in_menu = false
          pbUseKeyItemInField(item)
          return
        end
      elsif cmdPokegear>=0 && command==cmdPokegear
        pbFadeOutIn {
          scene = PokemonPokegear_Scene.new
          screen = PokemonPokegearScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
      # CHANGED: Pocket App
      elsif cmdLucario >= 0 && command == cmdLucario
        pbCallPocketApp
      elsif cmdTrainer>=0 && command==cmdTrainer
        pbFadeOutIn {
          scene = PokemonTrainerCard_Scene.new
          screen = PokemonTrainerCardScreen.new(scene)
          screen.pbStartScreen
          @scene.pbRefresh
        }
      elsif cmdQuit>=0 && command==cmdQuit
        @scene.pbHideMenu
        if pbInSafari?
          if pbConfirmMessage(_INTL("Would you like to leave the Safari Game right now?"))
            @scene.pbEndScene
            pbSafariState.decision = 1
            pbSafariState.pbGoToStart
            return
          else
            pbShowMenu
          end
        else
          if pbConfirmMessage(_INTL("Would you like to end the Contest now?"))
            @scene.pbEndScene
            pbBugContestState.pbStartJudging
            return
          else
            pbShowMenu
          end
        end
      elsif cmdSave>=0 && command==cmdSave
        @scene.pbHideMenu
        scene = PokemonSave_Scene.new
        screen = PokemonSaveScreen.new(scene)
        if screen.pbSaveScreen
          @scene.pbEndScene
          endscene = false
          break
        else
          pbShowMenu
        end
      # CHANGED: Multiple Protagonists
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
      elsif cmdOption>=0 && command==cmdOption
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen
          pbUpdateSceneMap
          @scene.pbRefresh
        }
      elsif cmdDebug>=0 && command==cmdDebug
        pbFadeOutIn {
          pbDebugMenu
          @scene.pbRefresh
        }
      # CHANGED: Disguises screen
      elsif cmdDisguises >= 0 && command == cmdDisguises
        pbFadeOutIn(99999){
          scene = PokemonDisguise_Scene.new
          screen = PokemonDisguiseScreen.new(scene)
          screen.pbStartScreen
        }
      # CHANGED: Gamemode code
      elsif cmdGamemode >= 0 && command == cmdGamemode
        gamemodes = ["Normal", "Hard", "Extreme"]
        pbMessage(_INTL("You are currently in {1} mode.", gamemodes[pbGamemode]))
        gamemodes = ["Normal", "Hard", "Extreme"]
        gamemodes.delete_at(pbGamemode)
        gamemodes.push("Cancel")
        loop do
          command = pbMessage(_INTL("What gamemode would you like to switch to?"),
                                      gamemodes, gamemodes.length)
          if command == 0 || command == 1
            if pbConfirmMessage(_INTL("You have chosen {1} mode. Is this OK?", gamemodes[command]))
              choice = gamemodes[command]
              pbSet(32, ["Normal", "Hard", "Extreme"].index(choice))
              break
            end
          else
            break
          end
        end
      # CHANGED: Quests/Missions code
      elsif cmdQuests >= 0 && command == cmdQuests
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
                if PBQuests.getStageCount(q.id, q.currentStage) > 0
                  stagemsg += " (#{q.currentStageCount} / #{PBQuests.getStageCount(q.id, q.currentStage)})"
                end
                pbMessage(_INTL(stagemsg))
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
      # CHANGED: Set Controls Screen
      elsif cmdControls>=0 && command==cmdControls
        scene=PokemonControlsScene.new
        screen=PokemonControls.new(scene)
        pbFadeOutIn(99999) {
          screen.pbStartScreen
        }
      elsif cmdEndGame>=0 && command==cmdEndGame
        @scene.pbHideMenu
        if pbConfirmMessage(_INTL("Are you sure you want to quit the game?"))
          scene = PokemonSave_Scene.new
          screen = PokemonSaveScreen.new(scene)
          if screen.pbSaveScreen
            @scene.pbEndScene
          end
          @scene.pbEndScene
          $scene = nil
          return
        else
          pbShowMenu
        end
      else
        break
      end
    end
    @scene.pbEndScene if endscene
  end
end
