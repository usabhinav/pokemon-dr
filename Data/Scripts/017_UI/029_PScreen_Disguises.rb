# CHANGED: Script section to handle disguise screen
class PokemonDisguise_Scene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @frames = 0
    @highlightpos = 0
    @disguises = $Trainer.obtainedDisguises.clone
    @disguisepos = 0
    @sprites = {}
    # Background
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = Bitmap.new("Graphics/Pictures/Disguises/bg.png")
    # Arrow selector
    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,@viewport)
    @sprites["rightarrow"].x = 5
    @sprites["rightarrow"].y = 41
    @sprites["rightarrow"].z = 1
    @sprites["rightarrow"].play
    # Disguise List Highlight (Broken/Equipped) Overlay
    @sprites["highlight_overlay"] = Sprite.new(@viewport)
    @sprites["highlight_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["highlight_overlay"].z = 0
    # Disguise List Overlay
    @sprites["list_overlay"] = Sprite.new(@viewport)
    @sprites["list_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    pbSetSystemFont(@sprites["list_overlay"].bitmap)
    @sprites["list_overlay"].z = 2
    # Disguise Info Overlay
    @sprites["info_overlay"] = Sprite.new(@viewport)
    @sprites["info_overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    pbSetSystemFont(@sprites["info_overlay"].bitmap)
    @sprites["info_overlay"].z = 2
    # Draw two overlays above
    pbDrawOverlay(0)
    # Cursor up when not selected (needed to stay above highlight)
    @sprites["cursor_up_normal"] = Sprite.new(@viewport)
    @sprites["cursor_up_normal"].bitmap = Bitmap.new("Graphics/Pictures/Disguises/cursor_up_normal.png")
    @sprites["cursor_up_normal"].x = 168
    @sprites["cursor_up_normal"].y = 13
    @sprites["cursor_up_normal"].z = 3
    # Cursor up selected
    @sprites["cursor_up"] = Sprite.new(@viewport)
    @sprites["cursor_up"].bitmap = Bitmap.new("Graphics/Pictures/Disguises/cursor_up.png")
    @sprites["cursor_up"].x = 168
    @sprites["cursor_up"].y = 13
    @sprites["cursor_up"].z = 4
    @sprites["cursor_up"].visible = false
    # Cursor down selected
    @sprites["cursor_down"] = Sprite.new(@viewport)
    @sprites["cursor_down"].bitmap = Bitmap.new("Graphics/Pictures/Disguises/cursor_down.png")
    @sprites["cursor_down"].x = 168
    @sprites["cursor_down"].y = 277
    @sprites["cursor_down"].z = 4
    @sprites["cursor_down"].visible = false
  end
  
  def pbShowDisguises(mode)
    pbFadeInAndShow(@sprites)
    loop do
      Graphics.update
      Input.update
      @sprites["rightarrow"].update
      @frames -= 1 if @frames > 0
      if @frames <= 0
        @sprites["cursor_up"].visible = false
        @sprites["cursor_down"].visible = false
      end
      if Input.trigger?(Input::UP)
        @frames = 4
        @sprites["cursor_up"].visible = true
        @sprites["cursor_down"].visible = false
        if @highlightpos <= 0
          if @disguisepos > 0
            @disguisepos -= 1
            pbDrawOverlay(@disguisepos + @highlightpos)
          end
        else
          @highlightpos -= 1
          pbDrawOverlay(@disguisepos + @highlightpos)
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        @frames = 4
        @sprites["cursor_up"].visible = false
        @sprites["cursor_down"].visible = true
        if @disguisepos + @highlightpos < @disguises.length - 1
          if @highlightpos >= 6
            @disguisepos += 1
          else
            @highlightpos += 1
          end
          pbDrawOverlay(@disguisepos + @highlightpos)
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::C)
        sel = @disguises[@disguisepos + @highlightpos]
        if mode == 1 # Select disguise for repair
          if sel.stepcount >= sel.maxcount
            pbMessage(_INTL("The {1} is not broken!", sel.name))
          elsif pbConfirmMessage(_INTL("Repair the {1}?", sel.name))
            pbSet(5, sel)
            break
          end
        else
          if $Trainer.equippedDisguise == sel
            pbUnequipDisguise
          else
            pbEquipDisguise(sel.id)
          end
          pbDrawOverlay(@disguisepos + @highlightpos)
        end
      elsif Input.trigger?(Input::B)
        pbSet(5, 0) if mode == 1
        break
      end
    end
  end
  
  def pbDrawOverlay(index)
    pbDrawList
    pbDrawDisguiseInfo(@disguises[index])
  end
  
  def pbDrawDisguiseInfo(disguise)
    overlay = @sprites["info_overlay"].bitmap
    overlay.clear
    # Name
    textsize = overlay.text_size(disguise.name)
    overlay.font.color = Color.new(0, 0, 0)
    overlay.draw_text(232, 28, 132, 32, disguise.name)
    # Description
    text=PBDisguises.getDesc(disguise.id)
    basecolor = overlay.font.color
    normtext=getLineBrokenChunks(overlay, text, 252, nil, true)
    for i in normtext
      i[5] = basecolor
    end
    renderLineBrokenChunks(overlay, 232, 80, normtext, 6*32)
    lastwordindex = 0
    while lastwordindex < normtext.length
      if normtext[lastwordindex][2] > 5 * 32
        break
      end
      lastwordindex += 1
    end
    if lastwordindex < normtext.length
      newtext = ""
      for i in lastwordindex...normtext.length
        newtext += normtext[i][0]
      end
      newnormtext = getLineBrokenChunks(overlay, newtext, 196, nil, true)
      for i in newnormtext
        i[5] = basecolor
      end
      renderLineBrokenChunks(overlay, 232, 272, newnormtext, 2*32)
    end
    # OW Sprite, X-Bounds: 448 - 488, Y-Bounds: 312 - 368
    owbitmap = Bitmap.new("Graphics/Characters/trchar001_#{disguise.outfit_id}.png")
    if disguise.outfit_id == 0
      owbitmap = Bitmap.new("Graphics/Characters/trchar001.png")
    end
    ow_src_rect = Rect.new(0, 0, owbitmap.width.to_f / 4, owbitmap.height.to_f / 4)
    owx = 468 - owbitmap.width.to_f / 8
    owy = 340 - owbitmap.height.to_f / 8
    overlay.blt(owx, owy, owbitmap, ow_src_rect)
    # Usage Bar
    bar = Bitmap.new("Graphics/Pictures/Disguises/bar.png")
    bar_start_y = 0
    if disguise.stepcount < disguise.maxcount / 4
      bar_start_y = bar.height.to_f * 2 / 3
    elsif disguise.stepcount < disguise.maxcount / 2
      bar_start_y = bar.height.to_f / 3
    end
    barwidth = bar.width.to_f * disguise.stepcount / disguise.maxcount
    bar_src_rect = Rect.new(0, bar_start_y, barwidth, bar.height / 3)
    overlay.blt(24, 345, bar, bar_src_rect)
    # Step Count Remaining
    steptext = "#{disguise.stepcount} / #{disguise.maxcount}"
    overlay.draw_text(24, 345, 172, 32, steptext, 1)
  end
  
  def pbDrawList
    @sprites["rightarrow"].y = 41 + 32*@highlightpos
    @sprites["list_overlay"].bitmap.clear
    @sprites["highlight_overlay"].bitmap.clear
    @sprites["list_overlay"].bitmap.font.color = Color.new(0, 0, 0)
    i = @disguisepos
    while i < 7 + @disguisepos && i < @disguises.length
      y = 41 + (i - @disguisepos)*32
      @sprites["list_overlay"].bitmap.draw_text(44, y, 132, 32, @disguises[i].name)
      if @disguises[i].isBroken?
        brokenbitmap = Bitmap.new("Graphics/Pictures/Disguises/disguise_broken.png")
        brokenbitmap_src_rect = Rect.new(0, 0, brokenbitmap.width, brokenbitmap.height)
        @sprites["highlight_overlay"].bitmap.blt(40, y, brokenbitmap, brokenbitmap_src_rect)
      elsif $Trainer.equippedDisguise == @disguises[i]
        equippedbitmap = Bitmap.new("Graphics/Pictures/Disguises/disguise_equipped.png")
        equippedbitmap_src_rect = Rect.new(0, 0, equippedbitmap.width, equippedbitmap.height)
        @sprites["highlight_overlay"].bitmap.blt(40, y, equippedbitmap, equippedbitmap_src_rect)
      end
      i += 1
    end
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class PokemonDisguiseScreen
  def initialize(scene, mode = 0)
    @scene = scene
    # 0 is normal disguise selection, 1 is selection for repair
    @mode = mode
  end
  
  def pbStartScreen
    @scene.pbStartScene
    @scene.pbShowDisguises(@mode) # For mode 1, resulting disguise stored in Variable 5 (default value 0 if nothing chosen)
    $scene.spritesetGlobal.playersprite.update
    @scene.pbEndScene
  end
end