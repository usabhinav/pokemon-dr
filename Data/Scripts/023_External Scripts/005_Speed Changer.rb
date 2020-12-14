# CHANGED: Script to change all event speeds from 4 to 3

=begin

for n in 1..999
  map_name = sprintf("Data/Map%03d.rxdata", n)
  next if !(File.open(map_name,"rb") { true } rescue false)
  map = load_data(map_name)
  events = map.events
  for i in map.events.keys.sort
    event = map.events[i]
    for page_index in 0...event.pages.length
      page = event.pages[page_index]
      if page.move_speed == 4
        page.move_speed = 3
      end
      list = page.list
      for index in 0...list.length
        command = list[index]
        params = list[index].parameters
        if command == 209 # Set Move Route
          for j in params[1].list
            if j.code == 29 && j.parameters[0] == 4
              j.parameters[0] = 3
            end
          end
        end
      end
    end
  end
  save_data(map, map_name)
end

=end

# Script to change trainer trigger to shorter function name

=begin

for n in 1..999
  map_name = sprintf("Data/Map%03d.rxdata", n)
  next if !(File.open(map_name,"rb") { true } rescue false)
  map = load_data(map_name)
  events = map.events
  for i in map.events.keys.sort
    event = map.events[i]
    for page_index in 0...event.pages.length
      page = event.pages[page_index]
      list = page.list
      for index in 0...list.length
        command = list[index]
        params = list[index].parameters
        if command.code == 111 && params[0] == 12 # Conditional Branch with Script
          if params[1][0...9] == "pbGet(32)"
            params[1] = "pbStartTrainerBattle?"
          end
        end
      end
    end
  end
  save_data(map, map_name)
end

=end