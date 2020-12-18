# CHANGED: Class to hold Zyro and Zyree's HUD

class PokemonTemp
  attr_accessor :hud
end

class HUD
  WAYPOINT_PADDING = 4

  def initialize
    @sprites = {}
    # Disguise Limit
    @sprites["disguisebar"] = Sprite.new(Spriteset_Global.viewport2)
    @sprites["disguisebar"].bitmap = Bitmap.new("Graphics/Pictures/HUD/frame.png")
    @sprites["disguisebar"].x = 370
    @sprites["disguisebar"].y = 30
    @sprites["disguisebar"].z = 999
    # Karma Bar
    @sprites["karmabar"] = Sprite.new(Spriteset_Global.viewport2)
    @sprites["karmabar"].bitmap = Bitmap.new("Graphics/Pictures/HUD/karmabar.png")
    @sprites["karmabar"].x = 380
    @sprites["karmabar"].y = 10
    @sprites["karmabar"].z = 999
    # Karma Indicator
    @sprites["karmaindicator"] = Sprite.new(Spriteset_Global.viewport2)
    @sprites["karmaindicator"].bitmap = Bitmap.new("Graphics/Pictures/HUD/karmaindicator.png")
    @sprites["karmaindicator"].z = 999
    # Waypoint
    @sprites["waypoint"] = Sprite.new(Spriteset_Global.viewport2)
    @sprites["waypoint"].bitmap = Bitmap.new(SCREEN_WIDTH, SCREEN_HEIGHT)
    @sprites["waypoint"].z = 999
  end

  def update
    if $PokemonGlobal.playerID == 0 # Zyro's HUD
      updateWaypoint
    elsif $PokemonGlobal.playerID == 1 # Zyree's HUD
      updateWaypoint
      updateDisguiseSteps
      updateKarmaBar
    end
  end

  def clearDisguiseSteps
    @sprites["disguisebar"].bitmap.dispose
  end

  def updateDisguiseSteps
    return if $PokemonGlobal.playerID != 1 # Only works for Zyree's HUD
    clearDisguiseSteps
    if $Trainer && $Trainer.equippedDisguise
      disguise = $Trainer.equippedDisguise
      framebitmap = Bitmap.new("Graphics/Pictures/HUD/frame.png")
      @sprites["disguisebar"].bitmap = framebitmap
      barbitmap = Bitmap.new("Graphics/Pictures/HUD/bar.png")
      bar_start_y = 0
      if disguise.stepcount < disguise.maxcount / 4
        bar_start_y = barbitmap.height.to_f * 2 / 3
      elsif disguise.stepcount < disguise.maxcount / 2
        bar_start_y = barbitmap.height.to_f / 3
      end
      barwidth = barbitmap.width.to_f * disguise.stepcount / disguise.maxcount
      barsrcrect = Rect.new(0, bar_start_y, barwidth, barbitmap.height / 3.0)
      pbSetSystemFont(@sprites["disguisebar"].bitmap)
      @sprites["disguisebar"].bitmap.font.size = 25
      @sprites["disguisebar"].bitmap.blt(3, 3, barbitmap, barsrcrect)
      @sprites["disguisebar"].bitmap.draw_text(framebitmap.rect, "Disguise Limit", 1)
    end
  end

  def clearKarmaBar
    @sprites["karmabar"].bitmap.dispose
    @sprites["karmaindicator"].bitmap.dispose
  end

  def updateKarmaBar
    return if $PokemonGlobal.playerID != 1 # Only works for Zyree's HUD
    clearKarmaBar
    if $game_switches[SHOW_KARMA_SWITCH]
      @sprites["karmabar"].bitmap = Bitmap.new("Graphics/Pictures/HUD/karmabar.png")
      @sprites["karmaindicator"].bitmap = Bitmap.new("Graphics/Pictures/HUD/karmaindicator.png")
      bounds = [8 + @sprites["karmabar"].x, 116 + @sprites["karmabar"].x]
      karma = ((pbGet(33) + MAXIMUM_KARMA) * 54.0) / MAXIMUM_KARMA
      new_x = bounds[0] + karma - 15
      @sprites["karmaindicator"].x = new_x
    end
  end

  def clearWaypoint
    @sprites["waypoint"].bitmap.dispose
  end

  def updateWaypoint
    clearWaypoint
    if $Trainer.activeQuests.length > 0
      @sprites["waypoint"].bitmap = Bitmap.new(SCREEN_WIDTH, SCREEN_HEIGHT)
      pbSetSystemFont(@sprites["disguisebar"].bitmap)
      q = $Trainer.activeQuests[$Trainer.activeQuests.length - 1]
      objectivetexts = []
      maxwidth = 0
      y = 0
      # Find text with largest width first
      for i in 0...q.currentObjectives.length
        objectivemsg = PBQuests.getStageObjectiveDescription(q.id, q.currentStage, i + 1)
        objectivetext = objectivemsg
        currentcount = q.currentObjectives[i]
        objectivecount = PBQuests.getStageObjectiveCount(q.id, q.currentStage, i + 1)
        if objectivecount > 1
          objectivetext += " (#{currentcount} / #{objectivecount})"
        end
        objectivetexts.push(objectivetext)
        textRect = @sprites["waypoint"].bitmap.text_size(objectivetext)
        maxwidth = textRect.width if maxwidth == 0 || maxwidth < textRect.width
        y += textRect.height
      end
      # Draw background before drawing text
      @sprites["waypoint"].bitmap.fill_rect(0, 0, maxwidth + 2*WAYPOINT_PADDING, y + 2*WAYPOINT_PADDING, Color.new(48, 129, 238))
      y = 0
      for text in objectivetexts
        textRect = @sprites["waypoint"].bitmap.text_size(text)
        @sprites["waypoint"].bitmap.draw_text(WAYPOINT_PADDING, y, textRect.width + 2*WAYPOINT_PADDING, textRect.height + 2*WAYPOINT_PADDING, text)
        y += textRect.height
      end
    end
  end
end