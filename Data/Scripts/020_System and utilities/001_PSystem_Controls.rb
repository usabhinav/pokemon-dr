def pbSameThread(wnd)
  return false if wnd==0
  processid = [0].pack('l')
  getCurrentThreadId       = Win32API.new('kernel32','GetCurrentThreadId', '%w()','l')
  getWindowThreadProcessId = Win32API.new('user32','GetWindowThreadProcessId', '%w(l p)','l')
  threadid    = getCurrentThreadId.call
  wndthreadid = getWindowThreadProcessId.call(wnd,processid)
  return (wndthreadid==threadid)
end



module Input
  DOWN      = 2
  LEFT      = 4
  RIGHT     = 6
  UP        = 8
  TAB       = 9
  A         = 11
  B         = 12
  C         = 13
  X         = 14
  Y         = 15
  Z         = 16
  L         = 17
  R         = 18
  ENTER     = 19
  ESC       = 20
  SHIFT     = 21
  CTRL      = 22
  ALT       = 23
  BACKSPACE = 24
  DELETE    = 25
  HOME      = 26
  ENDKEY    = 27
  F5 = F    = 28
  ONLYF5    = 29
  F6        = 30
  F7        = 31
  F8        = 32
  F9        = 33
  LeftMouseKey  = 1
  RightMouseKey = 2
  # GetAsyncKeyState or GetKeyState will work here
  @GetKeyState         = Win32API.new("user32","GetAsyncKeyState","i","i")
  @GetForegroundWindow = Win32API.new("user32","GetForegroundWindow","","i")
  # All key states to check
  CheckKeyStates = [0x01,0x02,0x08,0x09,0x0D,0x10,0x11,0x12,0x1B,0x20,0x21,0x22,
                    0x23,0x24,0x25,0x26,0x27,0x28,0x2E,0x30,0x31,0x32,0x33,0x34,
                    0x35,0x36,0x37,0x38,0x39,0x41,0x42,0x43,0x44,0x45,0x46,0x47,
                    0x48,0x49,0x4A,0x4B,0x4C,0x4D,0x4E,0x4F,0x50,0x51,0x52,0x53,
                    0x54,0x55,0x56,0x57,0x58,0x59,0x5A,0x6A,0x6B,0x6D,0x6F,0x74,
                    0x75,0x76,0x77,0x78,0xBA,0xBB,0xBC,0xBD,0xBE,0xBF,0xDB,0xDC,
                    0xDD,0xDE]   # 74 in total

  # Returns whether a key is being pressed
  def self.getstate(key)
    return (@GetKeyState.call(key)&0x8000)>0
  end

  def self.updateKeyState(i)
    gfw = pbSameThread(@GetForegroundWindow.call())
    if !@stateUpdated[i]
      newstate = self.getstate(i) && gfw
      @keystate[i] = 0 if !@keystate[i]
      @triggerstate[i] = (newstate && @keystate[i]==0)
      @releasestate[i] = (!newstate && @keystate[i]>0)
      @keystate[i] = (newstate) ? @keystate[i]+1 : 0
      @stateUpdated[i] = true
    end
  end

  def self.update
    # $fullInputUpdate is true during keyboard text entry
    toCheck = ($fullInputUpdate) ? 0...256 : CheckKeyStates
    if @keystate
      for i in toCheck
        # just noting that the state should be updated
        # instead of thunking to Win32 256 times
        @stateUpdated[i] = false
        # If there is a repeat count, update anyway
        # (will normally apply only to a very few keys)
        updateKeyState(i) if !@keystate[i] || @keystate[i]>0
      end
    else
      @stateUpdated = []
      @keystate     = []
      @triggerstate = []
      @releasestate = []
      for i in toCheck
        @stateUpdated[i] = true
        @keystate[i]     = (self.getstate(i)) ? 1 : 0
        @triggerstate[i] = false
        @releasestate[i] = false
      end
    end
  end

  def self.buttonToKey(button)
    case button
    when Input::DOWN;      return [0x28]                # Down
    when Input::LEFT;      return [0x25]                # Left
    when Input::RIGHT;     return [0x27]                # Right
    when Input::UP;        return [0x26]                # Up
    when Input::TAB;       return [0x09]                # Tab
    when Input::A;         return [0x5A,0x57,0x59,0x10] # Z, W, Y, Shift
    when Input::B;         return [0x58,0x1B]           # X, ESC
    # CHANGED: Removed Space from Input::C
    when Input::C;         return [0x43,0x0D]           # C, ENTER, Space (0x20)
#    when Input::X;         return [0x41]                # A
#    when Input::Y;         return [0x53]                # S
#    when Input::Z;         return [0x44]                # D
    when Input::L;         return [0x41,0x51,0x21]      # A, Q, Page Up
    when Input::R;         return [0x53,0x22]           # S, Page Down
    when Input::ENTER;     return [0x0D]                # ENTER
    when Input::ESC;       return [0x1B]                # ESC
    when Input::SHIFT;     return [0x10]                # Shift
    when Input::CTRL;      return [0x11]                # Ctrl
    when Input::ALT;       return [0x12]                # Alt
    when Input::BACKSPACE; return [0x08]                # Backspace
    when Input::DELETE;    return [0x2E]                # Delete
    when Input::HOME;      return [0x24]                # Home
    when Input::ENDKEY;    return [0x23]                # End
    when Input::F5;        return [0x46,0x74,0x09]      # F, F5, Tab
    when Input::ONLYF5;    return [0x74]                # F5
    when Input::F6;        return [0x75]                # F6
    when Input::F7;        return [0x76]                # F7
    when Input::F8;        return [0x77]                # F8
    when Input::F9;        return [0x78]                # F9
    else; return []
    end
  end

  def self.dir4
    button      = 0
    repeatcount = 0
    return 0 if self.press?(Input::DOWN) && self.press?(Input::UP)
    return 0 if self.press?(Input::LEFT) && self.press?(Input::RIGHT)
    for b in [Input::DOWN,Input::LEFT,Input::RIGHT,Input::UP]
      rc = self.count(b)
      if rc>0 && (repeatcount==0 || rc<repeatcount)
        button      = b
        repeatcount = rc
      end
    end
    return button
  end

  def self.dir8
    buttons = []
    for b in [Input::DOWN,Input::LEFT,Input::RIGHT,Input::UP]
      rc = self.count(b)
      buttons.push([b,rc]) if rc>0
    end
    if buttons.length==0
      return 0
    elsif buttons.length==1
      return buttons[0][0]
    elsif buttons.length==2
      # since buttons sorted by button, no need to sort here
      return 0 if (buttons[0][0]==Input::DOWN && buttons[1][0]==Input::UP)
      return 0 if (buttons[0][0]==Input::LEFT && buttons[1][0]==Input::RIGHT)
    end
    buttons.sort! { |a,b| a[1]<=>b[1] }
    updown    = 0
    leftright = 0
    for b in buttons
      updown    = b[0] if updown==0 && (b[0]==Input::UP || b[0]==Input::DOWN)
      leftright = b[0] if leftright==0 && (b[0]==Input::LEFT || b[0]==Input::RIGHT)
    end
    if updown==Input::DOWN
      return 1 if leftright==Input::LEFT
      return 3 if leftright==Input::RIGHT
      return 2
    elsif updown==Input::UP
      return 7 if leftright==Input::LEFT
      return 9 if leftright==Input::RIGHT
      return 8
    else
      return 4 if leftright==Input::LEFT
      return 6 if leftright==Input::RIGHT
      return 0
    end
  end

  def self.count(button)
    for btn in self.buttonToKey(button)
      c = self.repeatcount(btn)
      return c if c>0
    end
    return 0
  end

  def self.release?(button)
    rc = 0
    for btn in self.buttonToKey(button)
      c = self.repeatcount(btn)
      return false if c>0
      rc += 1 if self.releaseex?(btn)
    end
    return rc>0
  end

  def self.trigger?(button)
    return self.buttonToKey(button).any? { |item| self.triggerex?(item) }
  end

  def self.repeat?(button)
    return self.buttonToKey(button).any? { |item| self.repeatex?(item) }
  end

  def self.press?(button)
    return self.count(button)>0
  end

  def self.triggerex?(key)
    return false if !@triggerstate
    updateKeyState(key)
    return @triggerstate[key]
  end

  def self.repeatex?(key)
    return false if !@keystate
    updateKeyState(key)
    return @keystate[key]==1 || (@keystate[key]>Graphics.frame_rate/2 && (@keystate[key]&1)==0)
  end

  def self.releaseex?(key)
    return false if !@releasestate
    updateKeyState(key)
    return @releasestate[key]
  end

  def self.repeatcount(key)
    return 0 if !@keystate
    updateKeyState(key)
    return @keystate[key]
  end

  def self.pressex?(key)
    return self.repeatcount(key)>0
  end
end



# Requires Win32API
module Mouse
  gsm             = Win32API.new('user32','GetSystemMetrics','i','i')
  @GetCursorPos   = Win32API.new('user32','GetCursorPos','p','i')
  @SetCapture     = Win32API.new('user32','SetCapture','p','i')
  @ReleaseCapture = Win32API.new('user32','ReleaseCapture','','i')
  module_function

  def getMouseGlobalPos
    pos = [0, 0].pack('ll')
    return (@GetCursorPos.call(pos)!=0) ? pos.unpack('ll') : [nil,nil]
  end

  def screen_to_client(x, y)
    return nil unless x and y
    screenToClient = Win32API.new('user32','ScreenToClient',%w(l p),'i')
    pos = [x, y].pack('ll')
    return pos.unpack('ll') if screenToClient.call(Win32API.pbFindRgssWindow,pos)!=0
    return nil
  end

  def setCapture
    @SetCapture.call(Win32API.pbFindRgssWindow)
  end

  def releaseCapture
    @ReleaseCapture.call
  end

  # Returns the position of the mouse relative to the game window.
  def getMousePos(catch_anywhere=false)
    resizeFactor = ($ResizeFactor) ? $ResizeFactor : 1
    x, y = screen_to_client(*getMouseGlobalPos)
    return nil unless x and y
    width, height = Win32API.client_size
    if catch_anywhere or (x>=0 and y>=0 and x<width and y<height)
      return (x/resizeFactor).to_i, (y/resizeFactor).to_i
    end
    return nil
  end

  def del
    return if @oldcursor==nil
    @SetClassLong.call(Win32API.pbFindRgssWindow,-12,@oldcursor)
    @oldcursor = nil
  end
end

# CHANGED: Set controls script
#===============================================================================
# * Set the Controls Screen - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It's make a "Set the controls"
# option screen allowing the player to map the actions to the keys in keyboard,
# customizing the controls.
#
#===============================================================================
#
# To this script works, put it between PSystem_Controls and PSystem_System.
#
# To this screen be displayed in the pause menu, in PScreen_PauseMenu script,
# before line
# 'commands[cmdDebug = commands.length]    = _INTL("Debug") if $DEBUG' add:
#
# cmdControls=-1
# commands[cmdControls=commands.length]=_INTL("Controls")
#
# Before line 'elsif cmdOption>=0 && command==cmdOption' add:
#
# elsif cmdControls>=0 && command==cmdControls
#   scene=PokemonControlsScene.new
#   screen=PokemonControls.new(scene)
#   pbFadeOutIn(99999) {
#     screen.pbStartScreen
#   }
#
# Using the last five lines you can start this scene in other places like at
# an event.
#
# Note that this script, by default, doesn't allows the player to redefine some
# commands like F8 (screenshot key), but if the player assign an action to
# this key, like the "Cancel" action, this key will do this action AND take
# screenshots when pressed. Remember that F12 will reset the game.
#
#===============================================================================

module Keys
  # Available keys
  CONTROLSLIST = {
    # Mouse buttons
    _INTL("Backspace") => 0x08,
    _INTL("Tab") => 0x09,
    _INTL("Clear") => 0x0C,
    _INTL("Enter") => 0x0D,
    _INTL("Shift") => 0x10,
    _INTL("Ctrl") => 0x11,
    _INTL("Alt") => 0x12,
    _INTL("Pause") => 0x13,
    _INTL("Caps Lock") => 0x14,
    # IME keys
    _INTL("Esc") => 0x1B,
    # More IME keys
    _INTL("Space") => 0x20,
    _INTL("Page Up") => 0x21,
    _INTL("Page Down") => 0x22,
    _INTL("End") => 0x23,
    _INTL("Home") => 0x24,
    _INTL("Left") => 0x25,
    _INTL("Up") => 0x26,
    _INTL("Right") => 0x27,
    _INTL("Down") => 0x28,
    _INTL("Select") => 0x29,
    _INTL("Print") => 0x2A,
    _INTL("Execute") => 0x2B,
    _INTL("Print Screen") => 0x2C,
    _INTL("Insert") => 0x2D,
    _INTL("Delete") => 0x2E,
    _INTL("Help") => 0x2F,
    _INTL("0") => 0x30,
    _INTL("1") => 0x31,
    _INTL("2") => 0x32,
    _INTL("3") => 0x33,
    _INTL("4") => 0x34,
    _INTL("5") => 0x35,
    _INTL("6") => 0x36,
    _INTL("7") => 0x37,
    _INTL("8") => 0x38,
    _INTL("9") => 0x39,
    _INTL("A") => 0x41,
    _INTL("B") => 0x42,
    _INTL("C") => 0x43,
    _INTL("D") => 0x44,
    _INTL("E") => 0x45,
    _INTL("F") => 0x46,
    _INTL("G") => 0x47,
    _INTL("H") => 0x48,
    _INTL("I") => 0x49,
    _INTL("J") => 0x4A,
    _INTL("K") => 0x4B,
    _INTL("L") => 0x4C,
    _INTL("M") => 0x4D,
    _INTL("N") => 0x4E,
    _INTL("O") => 0x4F,
    _INTL("P") => 0x50,
    _INTL("Q") => 0x51,
    _INTL("R") => 0x52,
    _INTL("S") => 0x53,
    _INTL("T") => 0x54,
    _INTL("U") => 0x55,
    _INTL("V") => 0x56,
    _INTL("W") => 0x57,
    _INTL("X") => 0x58,
    _INTL("Y") => 0x59,
    _INTL("Z") => 0x5A,
    # Windows keys
    _INTL("Numpad 0") => 0x60,
    _INTL("Numpad 1") => 0x61,
    _INTL("Numpad 2") => 0x62,
    _INTL("Numpad 3") => 0x63,
    _INTL("Numpad 4") => 0x64,
    _INTL("Numpad 5") => 0x65,
    _INTL("Numpad 6") => 0x66,
    _INTL("Numpad 7") => 0x67,
    _INTL("Numpad 8") => 0x68,
    _INTL("Numpad 9") => 0x69,
    _INTL("Multiply") => 0x6A,
    _INTL("Add") => 0x6B,
    _INTL("Separator") => 0x6C,
    _INTL("Subtract") => 0x6D,
    _INTL("Decimal") => 0x6E,
    _INTL("Divide") => 0x6F,
    _INTL("F1") => 0x70,
    _INTL("F2") => 0x71,
    _INTL("F3") => 0x72,
    _INTL("F4") => 0x73,
    _INTL("F5") => 0x74,
    _INTL("F6") => 0x75,
    _INTL("F7") => 0x76,
    _INTL("F8") => 0x77,
    _INTL("F9") => 0x78,
    _INTL("F10") => 0x79,
    _INTL("F11") => 0x7A,
    _INTL("F12") => 0x7B,
    _INTL("F13") => 0x7C,
    _INTL("F14") => 0x7D,
    _INTL("F15") => 0x7E,
    _INTL("F16") => 0x7F,
    _INTL("F17") => 0x80,
    _INTL("F18") => 0x81,
    _INTL("F19") => 0x82,
    _INTL("F20") => 0x83,
    _INTL("F21") => 0x84,
    _INTL("F22") => 0x85,
    _INTL("F23") => 0x86,
    _INTL("F24") => 0x87,
    _INTL("Num Lock") => 0x90,
    _INTL("Scroll Lock") => 0x91,
    # Multiple position Shift, Ctrl and Menu keys
    _INTL(";:") => 0xBA,
    _INTL("+") => 0xBB,
    _INTL(",") => 0xBC,
    _INTL("-") => 0xBD,
    _INTL(".") => 0xBE,
    _INTL("/?") => 0xBF,
    _INTL("`~") => 0xC0,
    _INTL("{") => 0xDB,
    _INTL("\|") => 0xDC,
    _INTL("}") => 0xDD,
    _INTL("'\"") => 0xDE,
    _INTL("AX") => 0xE1, # Japan only
    _INTL("\|") => 0xE2
    # Disc keys
  }

  # Here you can change the number of keys for each action and the
  # default values
  def self.defaultControls
    return [
      ControlConfig.new(_INTL("Down"),_INTL("Down")),
      ControlConfig.new(_INTL("Left"),_INTL("Left")),
      ControlConfig.new(_INTL("Right"),_INTL("Right")),
      ControlConfig.new(_INTL("Up"),_INTL("Up")),
      ControlConfig.new(_INTL("Action"),_INTL("C")),
      ControlConfig.new(_INTL("Action"),_INTL("Enter")),
      ControlConfig.new(_INTL("Action"),_INTL("Space")),
      ControlConfig.new(_INTL("Cancel"),_INTL("X")),
      ControlConfig.new(_INTL("Cancel"),_INTL("Esc")),
      ControlConfig.new(_INTL("Run/Sort"),_INTL("Z")),
      ControlConfig.new(_INTL("Scroll down"),_INTL("Page Down")),
      ControlConfig.new(_INTL("Scroll up"),_INTL("Page Up")),
      ControlConfig.new(_INTL("Registered"),_INTL("F")),
      ControlConfig.new(_INTL("Registered"),_INTL("F5"))
    ]
  end 

  def self.getKeyName(keyCode)
    ret  = CONTROLSLIST.index(keyCode)
    return ret ? ret : (keyCode==0 ? _INTL("None") : "?")
  end 

  def self.getKeyCode(keyName)
    ret  = CONTROLSLIST[keyName]
    raise "The button #{keyName} no longer exists! " if !ret
    return ret
  end 

  def self.detectKey
    loop do
      Graphics.update
      Input.update
      for keyCode in CONTROLSLIST.values
        return keyCode if Input.triggerex?(keyCode)
      end
    end
  end
end 

class ControlConfig
  attr_reader :controlAction
  attr_accessor :keyCode

  def initialize(controlAction,defaultKey)
    @controlAction = controlAction
    @keyCode = Keys.getKeyCode(defaultKey)
  end

  def keyName
    return Keys.getKeyName(@keyCode)
  end
end

module Input
  class << self
    alias :buttonToKeyOldFL :buttonToKey
    # Here I redefine this method with my controlAction.
    # Note that I don't declare action for all commands.
    def buttonToKey(button)
      $PokemonSystem = PokemonSystem.new if !$PokemonSystem
      case button
        when Input::DOWN
          return $PokemonSystem.getGameControlCodes(_INTL("Down"))
        when Input::LEFT
          return $PokemonSystem.getGameControlCodes(_INTL("Left"))
        when Input::RIGHT
          return $PokemonSystem.getGameControlCodes(_INTL("Right"))
        when Input::UP
          return $PokemonSystem.getGameControlCodes(_INTL("Up"))
        when Input::A # Z, W, Y, Shift
          return $PokemonSystem.getGameControlCodes(_INTL("Run/Sort"))
        when Input::B # X, ESC
          return $PokemonSystem.getGameControlCodes(_INTL("Cancel"))
        when Input::C # C, ENTER, Space
          return $PokemonSystem.getGameControlCodes(_INTL("Action"))
        when Input::L # A, Q, Page Up
          return $PokemonSystem.getGameControlCodes(_INTL("Scroll up"))
        when Input::R # S, Page Down
          return $PokemonSystem.getGameControlCodes(_INTL("Scroll down"))
#        when Input::SHIFT
#          return [0x10] # Shift
#        when Input::CTRL
#          return [0x11] # Ctrl
#        when Input::ALT
#          return [0x12] # Alt
        when Input::F5 # F, F5, Tab
          return $PokemonSystem.getGameControlCodes(_INTL("Registered"))
#        when Input::F6
#          return [0x75] # F6
#        when Input::F7
#          return [0x76] # F7
#        when Input::F8
#          return [0x77] # F8
#        when Input::F9
#          return [0x78] # F9
        else
          return buttonToKeyOldFL(button)
      end
    end
  end
end

class Window_PokemonControls < Window_DrawableCommand
  attr_reader :readingInput
  attr_reader :controls
  attr_reader :changed

  def initialize(controls,x,y,width,height)
    @controls=controls
    @nameBaseColor=Color.new(88,88,80)
    @nameShadowColor=Color.new(168,184,184)
    @selBaseColor=Color.new(24,112,216)
    @selShadowColor=Color.new(136,168,208)
    @readingInput=false
    @changed=false
    super(x,y,width,height)
  end

  def setNewInput(newInput)
    @readingInput = false
    return if @controls[@index].keyCode==newInput
    for control in @controls # Remove the same input for the same array
      control.keyCode = 0 if control.keyCode==newInput
    end
    @controls[@index].keyCode=newInput
    @changed = true
    refresh
  end

  def itemCount
    return @controls.length+2
  end

  def drawItem(index,count,rect)
    rect=drawCursor(index,rect)
    optionname = ""
    if index==(@controls.length+1)
      optionname = _INTL("Exit")
    elsif index==(@controls.length)
      optionname = _INTL("Default")
    else
      optionname = @controls[index].controlAction
    end
    optionwidth=(rect.width*9/20)
    pbDrawShadowText(self.contents,rect.x,rect.y,optionwidth,rect.height,
      optionname,@nameBaseColor,@nameShadowColor)
    self.contents.draw_text(rect.x,rect.y,optionwidth,rect.height,optionname)
    return if index>=@controls.length
    value=@controls[index].keyName
    xpos=optionwidth+rect.x
    pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
      @selBaseColor,@selShadowColor)
    self.contents.draw_text(xpos,rect.y,optionwidth,rect.height,value)
  end

  def update
    dorefresh=false
    oldindex=self.index
    super
    dorefresh=self.index!=oldindex
    if self.active && self.index<=@controls.length
      if Input.trigger?(Input::C)
        if self.index == @controls.length # Default
          @controls = Keys.defaultControls
          @changed = true
          dorefresh = true
        else
          @readingInput = true
        end
      end
    end
    refresh if dorefresh
  end
end

class PokemonControlsScene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["title"]=Window_UnformattedTextPokemon.newWithSize(
      _INTL("Controls"),0,0,Graphics.width,64,@viewport)
    @sprites["textbox"]=Kernel.pbCreateMessageWindow
    @sprites["textbox"].letterbyletter=false
    gameControls = []
    for control in $PokemonSystem.gameControls
      gameControls.push(control.clone)
    end
    @sprites["controlwindow"]=Window_PokemonControls.new(gameControls,0,
    @sprites["title"].height,Graphics.width,
    Graphics.height-@sprites["title"].height-@sprites["textbox"].height)
    @sprites["controlwindow"].viewport=@viewport
    @sprites["controlwindow"].visible=true
    @changed = false
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbMain
    pbActivateWindow(@sprites,"controlwindow"){
    loop do
      Graphics.update
      Input.update
      pbUpdate
      exit = false
      if @sprites["controlwindow"].readingInput
        @sprites["textbox"].text=_INTL("Press a new key.")
        @sprites["controlwindow"].setNewInput(Keys.detectKey)
        @sprites["textbox"].text=""
        @changed = true
      else
        if Input.trigger?(Input::B) || (Input.trigger?(Input::C) &&
          @sprites["controlwindow"].index==(
          @sprites["controlwindow"].itemCount-1))
          exit = true
          if(@sprites["controlwindow"].changed &&
              Kernel.pbConfirmMessage(_INTL("Save changes?")))
            @sprites["textbox"].text = "" # Visual effect
            newControls = @sprites["controlwindow"].controls
            emptyCommand = false
            for control in newControls
              emptyCommand = true if control.keyCode == 0
            end
            if emptyCommand
              @sprites["textbox"].text=_INTL("Fill all fields!")
              exit = false
            else
              $PokemonSystem.gameControls = newControls
            end
          end
        end
      end
      break if exit
    end
    }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    Kernel.pbDisposeMessageWindow(@sprites["textbox"])
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class PokemonControls
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMain
    @scene.pbEndScene
  end
end

class PokemonSystem
  attr_accessor :gameControls
  def gameControls
    @gameControls = Keys.defaultControls if !@gameControls
    return @gameControls
  end

  def getGameControlCodes(controlAction)
    ret = []
    for control in gameControls
      ret.push(control.keyCode) if control.controlAction == controlAction
    end
    return ret
  end
end