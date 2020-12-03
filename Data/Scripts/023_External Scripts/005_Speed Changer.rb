# CHANGED: Script to change all event speeds from 3 to 4

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
      if page.move_speed == 3
        page.move_speed = 4
      end
      list = page.list
      for index in 0...list.length
        command = list[index]
        params = list[index].parameters
        if command == 209 # Set Move Route
          for j in params[1].list
            if j.code == 29 && j.parameters[0] == 3
              j.parameters[0] = 4
            end
          end
        end
      end
    end
  end
  save_data(map, map_name)
end

=end