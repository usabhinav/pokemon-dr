# CHANGED: Class to hold Zyro and Zyree's HUD

class PokemonTemp
  attr_accessor :hud
end

class HUD
  WAYPOINT_PADDING = 4 # Padding around text in blue box

  attr_accessor :displayHUD # Toggles HUD display

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
    # HUD Display Toggle
    @displayHUD = true
  end

  def toggleDisplay
    @displayHUD = !@displayHUD
    if @displayHUD
      update
    else
      clear
    end
  end

  def update
    clear
    return if !@displayHUD
    if $PokemonGlobal.playerID == 0 # Zyro's HUD
      updateZyroHUD
    elsif $PokemonGlobal.playerID == 1 # Zyree's HUD
      updateZyreeHUD
    end
  end

  def clear
    clearDisguiseSteps
    clearKarmaBar
    clearWaypoint
  end

  def updateZyroHUD
    updateWaypoint
  end

  def updateZyreeHUD
    updateWaypoint
    updateDisguiseSteps
    updateKarmaBar
  end

  def clearDisguiseSteps
    @sprites["disguisebar"].bitmap.dispose
  end

  def updateDisguiseSteps
    return if $PokemonGlobal.playerID != 1 # Only works for Zyree's HUD
    clearDisguiseSteps
    return if !@displayHUD
    if $Trainer && $Trainer.equippedDisguise
      disguise = $Trainer.equippedDisguise
      framebitmap = Bitmap.new("Graphics/Pictures/HUD/frame.png")
      @sprites["disguisebar"].bitmap = framebitmap
      barbitmap = Bitmap.new("Graphics/Pictures/HUD/bar.png")
      # Green bar for >= 50% steps, yellow for >= 25%, red otherwise
      bar_start_y = 0
      if disguise.stepcount < disguise.maxcount / 4
        bar_start_y = barbitmap.height.to_f * 2 / 3
      elsif disguise.stepcount < disguise.maxcount / 2
        bar_start_y = barbitmap.height.to_f / 3
      end
      # Calculate how much of bar to show
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
    return if !@displayHUD
    if $game_switches[SHOW_KARMA_SWITCH]
      @sprites["karmabar"].bitmap = Bitmap.new("Graphics/Pictures/HUD/karmabar.png")
      @sprites["karmaindicator"].bitmap = Bitmap.new("Graphics/Pictures/HUD/karmaindicator.png")
      # Calculate where to place indicator above karma bar
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
    return if !@displayHUD
    if $Trainer.activeQuests.length > 0
      @sprites["waypoint"].bitmap = Bitmap.new(SCREEN_WIDTH, SCREEN_HEIGHT)
      pbSetSystemFont(@sprites["waypoint"].bitmap)
      @sprites["waypoint"].bitmap.font.size = 25
      q = $Trainer.activeQuests[$Trainer.activeQuests.length - 1]
      objectivetexts = []
      maxwidth = 0 # Width of background box
      maxheight = 0 # Height of background box
      # Find text with largest width first in order to calculate size of box
      for i in 0...q.currentObjectives.length
        # Construct objective message
        objectivemsg = PBQuests.getStageObjectiveDescription(q.id, q.currentStage, i + 1)
        objectivetext = objectivemsg
        currentcount = q.currentObjectives[i]
        objectivecount = PBQuests.getStageObjectiveCount(q.id, q.currentStage, i + 1)
        if objectivecount > 1
          objectivetext += " (#{currentcount} / #{objectivecount})"
        end
        objectivetexts.push(objectivetext)
        # Update width and height of background box
        textRect = @sprites["waypoint"].bitmap.text_size(objectivetext)
        maxwidth = textRect.width if maxwidth == 0 || maxwidth < textRect.width
        maxheight += textRect.height
      end
      # Draw blue background before drawing text
      @sprites["waypoint"].bitmap.fill_rect(0, 0, maxwidth + 2*WAYPOINT_PADDING, maxheight + 2*WAYPOINT_PADDING, Color.new(48, 129, 238))
      y = 0
      for i in 0...objectivetexts.length
        text = objectivetexts[i]
        # Color-code objectives if completed or optional
        if q.currentObjectives[i] >= PBQuests.getStageObjectiveCount(q.id, q.currentStage, i + 1)
          @sprites["waypoint"].bitmap.font.color = Color.new(159, 218, 64) # Green
        elsif PBQuests.getStageObjectiveOptional(q.id, q.currentStage, i + 1)
          @sprites["waypoint"].bitmap.font.color = Color.new(0, 255, 255) # Aqua
        else
          @sprites["waypoint"].bitmap.font.color = Color.new(255, 255, 255) # White
        end
        textRect = @sprites["waypoint"].bitmap.text_size(text)
        @sprites["waypoint"].bitmap.draw_text(WAYPOINT_PADDING, y, textRect.width + 2*WAYPOINT_PADDING, textRect.height + 2*WAYPOINT_PADDING, text)
        y += textRect.height
      end
    end
  end
end