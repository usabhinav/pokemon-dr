# CHANGED: Methods for calling Pocket App
def pbCallPocketApp
  if $Trainer.metaID == 0
    pbMessage(_INTL("\\se[PC open]{1} booted up the Pocket App.",$Trainer.name))
  else
    pbMessage(_INTL("\\se[PC open]{1} accessed Lucario's storage.",$Trainer.name))
  end
  loop do
    commands = ["Pokemon Storage", "Item Storage", "Cancel"]
    command = pbMessage(_INTL("Which storage unit should be accessed?"),commands,commands.length)
    if command == 0
      pbPocketAppPokeStorage
    elsif command == 1
      pbPocketAppItemStorage
    else
      break
    end
  end
  pbSEPlay("PC close")
end

def pbPocketAppPokeStorage
  if $Trainer.money < POKE_STORAGE_FEE
    pbMessage(_INTL("You don't have enough money to use this feature!"))
  else
    loop do
      break if $Trainer.money < POKE_STORAGE_FEE
      command=pbShowCommandsWithHelp(nil,
         [_INTL("Withdraw Pokémon"),
         _INTL("Deposit Pokémon"),
         _INTL("See ya!")],
         [_INTL("Move Pokémon stored in Boxes to your party."),
         _INTL("Store Pokémon in your party in Boxes."),
         _INTL("Return to the previous menu.")],-1
      )
      if command == 0
        pbPocketAppWithdrawPoke
      elsif command == 1
        pbPocketAppDepositPoke
      else
        break
      end
    end
  end
end

def pbPocketAppItemStorage
  if $Trainer.money < ITEM_STORAGE_FEE
    pbMessage(_INTL("You don't have enough money to use this feature!"))
  else
    pbPCItemStorage
  end
end

def pbPocketAppDepositPoke
  if $Trainer.party.length <= 1 && !$game_switches[Z_TRANSFORM_SWITCH]
    pbMessage(_INTL("You only have one Pokemon left! Probably should keep it."))
  else
    scene=PokemonStorageScene.new
    screen=PokemonStorageScreen.new(scene,$PokemonStorage)
    screen.pbStartScreen(2)
  end
end

def pbPocketAppWithdrawPoke
  if $Trainer.party.length >= 6
    if pbConfirmMessage(_INTL("Your party is full! Do you want to deposit a Pokemon first?"))
      pbPocketAppDepositPoke
    end
  else
    scene=PokemonStorageScene.new
    screen=PokemonStorageScreen.new(scene,$PokemonStorage)
    screen.pbStartScreen(1)
  end
end